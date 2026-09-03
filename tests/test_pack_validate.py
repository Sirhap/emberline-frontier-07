#!/usr/bin/env python3
"""Validator for programmable hero/skin packs."""

from __future__ import annotations

import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

KNIGHT_DIR = (
    ROOT
    / "xsxb_frame_tuner"
    / "workspace"
    / "projects"
    / "emberline_frontier_07_final"
    / "assets"
    / "ember_hero"
)
ASSASSIN_DIR = (
    ROOT
    / "xsxb_frame_tuner"
    / "workspace"
    / "projects"
    / "emberline_enemies"
    / "assets"
    / "ember_assassin"
)


def _crc(data: bytes) -> int:
    return zlib.crc32(data) & 0xFFFFFFFF


def write_rgba_png(path: Path, width: int, height: int, pixels: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = b""
    stride = width * 4
    for y in range(height):
        raw += b"\x00" + pixels[y * stride : (y + 1) * stride]
    compressed = zlib.compress(raw, 9)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)

    def chunk(tag: bytes, payload: bytes) -> bytes:
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", _crc(tag + payload))

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")
    )


def opaque_bottom_png(path: Path, width: int = 8, height: int = 8) -> None:
    pixels = bytearray(width * height * 4)
    for x in range(width):
        i = ((height - 1) * width + x) * 4
        pixels[i : i + 4] = b"\xff\x00\x00\xff"
    write_rgba_png(path, width, height, bytes(pixels))


def write_pack_json(root: Path, **fields) -> None:
    root.mkdir(parents=True, exist_ok=True)
    payload = {
        "kind": "skin",
        "id": "fixture",
        "title": "夹具",
        "base": "ember_hero",
        "view_mode": "three",
    }
    payload.update(fields)
    (root / "pack.json").write_text(json.dumps(payload), encoding="utf-8")


class PackValidateTests(unittest.TestCase):
    def test_builtin_knight_is_complete_side_flip(self) -> None:
        from pack_validate import validate_pack

        report = validate_pack(KNIGHT_DIR)
        self.assertTrue(report["complete"], report)
        self.assertEqual(report["view_mode"], "side_flip")
        self.assertEqual(report["missing"], [])

    def test_builtin_assassin_is_complete_side_flip(self) -> None:
        from pack_validate import validate_pack

        report = validate_pack(ASSASSIN_DIR)
        self.assertTrue(report["complete"], report)
        self.assertEqual(report["view_mode"], "side_flip")
        self.assertEqual(report["missing"], [])

    def test_new_pack_missing_back_is_incomplete(self) -> None:
        from pack_validate import validate_pack

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "pack"
            write_pack_json(root)
            for slot in ("idle", "run", "jump", "attack", "dash", "down"):
                for view in ("front", "side"):
                    opaque_bottom_png(root / slot / view / "frame_0001.png")
            report = validate_pack(root)
            self.assertFalse(report["complete"])
            missing = " ".join(report["missing"])
            self.assertIn("idle/back", missing)

    def test_new_three_view_pack_complete(self) -> None:
        from pack_validate import validate_pack

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "pack"
            write_pack_json(root, id="knight_gold", title="金甲")
            for slot in ("idle", "run", "jump", "attack", "dash", "down"):
                for view in ("front", "side", "back"):
                    opaque_bottom_png(root / slot / view / "00.png")
            report = validate_pack(root)
            self.assertTrue(report["complete"], report)
            self.assertEqual(report["view_mode"], "three")

    def test_new_pack_cannot_use_side_flip(self) -> None:
        from pack_validate import validate_pack

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "pack"
            write_pack_json(root, id="knight_gold", view_mode="side_flip")
            for slot in ("idle", "run", "jump", "attack", "dash", "down"):
                opaque_bottom_png(root / slot / "00.png")
            report = validate_pack(root)
            self.assertFalse(report["complete"])
            self.assertTrue(any("view_mode" in item for item in report["missing"]))

    def test_size_mismatch_fails(self) -> None:
        from pack_validate import validate_pack

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "pack"
            write_pack_json(root, id="knight_gold")
            for slot in ("idle", "run", "jump", "attack", "dash", "down"):
                for view in ("front", "side", "back"):
                    opaque_bottom_png(root / slot / view / "00.png", 8, 8)
            write_rgba_png(root / "idle" / "front" / "01.png", 4, 4, b"\xff\x00\x00\xff" * 16)
            report = validate_pack(root)
            self.assertFalse(report["complete"])
            self.assertTrue(any("size" in item for item in report["missing"]))


if __name__ == "__main__":
    unittest.main()
