#!/usr/bin/env python3
"""Validate a hero/skin pack folder against data/hero_pack_spec.json."""

from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "data" / "hero_pack_spec.json"
PNG_SIG = b"\x89PNG\r\n\x1a\n"


def load_spec() -> dict[str, Any]:
    return json.loads(SPEC_PATH.read_text(encoding="utf-8"))


def _read_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        parsed = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return parsed if isinstance(parsed, dict) else {}


def png_size(path: Path) -> tuple[int, int] | None:
    try:
        with path.open("rb") as handle:
            if handle.read(8) != PNG_SIG:
                return None
            length, tag = struct.unpack(">I4s", handle.read(8))
            if tag != b"IHDR" or length < 8:
                return None
            data = handle.read(length)
            return struct.unpack(">II", data[:8])
    except OSError:
        return None


def png_rgba(path: Path) -> tuple[int, int, bytes] | None:
    try:
        with path.open("rb") as handle:
            if handle.read(8) != PNG_SIG:
                return None
            width = height = bit_depth = color_type = None
            idat = b""
            while True:
                header = handle.read(8)
                if len(header) < 8:
                    break
                length, tag = struct.unpack(">I4s", header)
                data = handle.read(length)
                handle.read(4)
                if tag == b"IHDR":
                    width, height, bit_depth, color_type, *_rest = struct.unpack(">IIBBBBB", data)
                elif tag == b"IDAT":
                    idat += data
                elif tag == b"IEND":
                    break
            if width is None or bit_depth != 8 or color_type not in (2, 6):
                return None
            raw = zlib.decompress(idat)
            channels = 4 if color_type == 6 else 3
            stride = width * channels
            pixels = bytearray()
            offset = 0
            for _y in range(height):
                offset += 1
                row = raw[offset : offset + stride]
                offset += stride
                if color_type == 6:
                    pixels.extend(row)
                else:
                    for x in range(width):
                        i = x * 3
                        pixels.extend(row[i : i + 3] + b"\xff")
            return width, height, bytes(pixels)
    except (OSError, zlib.error, struct.error, ValueError):
        return None


def list_pngs(folder: Path) -> list[Path]:
    if not folder.is_dir():
        return []
    return sorted(p for p in folder.iterdir() if p.suffix.lower() == ".png" and p.is_file())


def _slot_dir(root: Path, slot: str, view: str | None) -> Path:
    if view:
        return root / slot / view
    return root / slot


def _feet_ok(path: Path) -> bool:
    decoded = png_rgba(path)
    if decoded is None:
        return True
    width, height, pixels = decoded
    scan = max(1, height // 10)
    for y in range(height - scan, height):
        for x in range(width):
            if pixels[(y * width + x) * 4 + 3] > 8:
                return True
    return False


def validate_pack(pack_dir: str | Path) -> dict[str, Any]:
    root = Path(pack_dir)
    spec = load_spec()
    missing: list[str] = []
    slots_out: list[dict[str, Any]] = []
    meta = _read_json(root / "pack.json")
    pack_id = str(meta.get("id", root.name))
    base = str(meta.get("base", ""))
    templates: dict[str, Any] = spec["templates"]
    builtin_ids = set(spec.get("builtin_side_flip_ids", []))
    if base not in templates:
        if pack_id in templates:
            base = pack_id
        elif pack_id == "ember_assassin":
            base = "assassin"
        else:
            missing.append("pack.json.base")
            base = "ember_hero"
    view_mode = str(meta.get("view_mode", "side_flip" if pack_id in builtin_ids else "three"))
    if view_mode not in ("three", "side_flip"):
        missing.append("pack.json.view_mode")
        view_mode = "three"
    if view_mode == "side_flip" and pack_id not in builtin_ids:
        missing.append("view_mode: new packs must use three")
    kind = str(meta.get("kind", "skin"))
    if kind not in ("skin", "hero"):
        missing.append("pack.json.kind")
    if not meta.get("title") and pack_id not in builtin_ids:
        missing.append("pack.json.title")

    template = templates[base]
    required: list[str] = list(template["required"])
    optional: list[str] = list(template.get("optional", []))
    views: list[str] = list(spec["views"]) if view_mode == "three" else [""]

    for slot in required + optional:
        need = slot in required
        view_counts: dict[str, int] = {}
        sizes: set[tuple[int, int]] = set()
        slot_ok = True
        for view in views:
            folder = _slot_dir(root, slot, view or None)
            frames = list_pngs(folder)
            label = f"{slot}/{view}" if view else slot
            view_counts[view or "side"] = len(frames)
            if need and not frames:
                missing.append(f"missing {label}")
                slot_ok = False
                continue
            for frame in frames:
                size = png_size(frame)
                if size is None:
                    missing.append(f"unreadable {frame.name}")
                    slot_ok = False
                    continue
                sizes.add(size)
                if slot == "idle" and not _feet_ok(frame):
                    missing.append(f"feet {label}/{frame.name}")
                    slot_ok = False
            if len(sizes) > 1:
                missing.append(f"size {label}")
                slot_ok = False
        slots_out.append(
            {
                "slot": slot,
                "required": need,
                "ok": slot_ok if need else True,
                "frames": sum(view_counts.values()),
                "views": view_counts,
            }
        )

    portrait = root / "portrait.png"
    if not portrait.is_file():
        fallback_view = "side" if view_mode == "three" else ""
        idle_frames = list_pngs(_slot_dir(root, "idle", fallback_view or None))
        if not idle_frames:
            missing.append("portrait")

    complete = not missing
    return {
        "complete": complete,
        "id": pack_id,
        "kind": kind,
        "base": base,
        "title": str(meta.get("title", pack_id)),
        "view_mode": view_mode,
        "slots": slots_out,
        "missing": missing,
        "root": str(root),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate a hero/skin pack folder")
    parser.add_argument("pack_dir")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    report = validate_pack(args.pack_dir)
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        status = "COMPLETE" if report["complete"] else "INCOMPLETE"
        print(f"{report['id']} {report['view_mode']} {status}")
        for item in report["missing"]:
            print(f"  - {item}")
    return 0 if report["complete"] else 1


if __name__ == "__main__":
    sys.exit(main())
