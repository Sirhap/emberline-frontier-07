#!/usr/bin/env python3
"""Rebuild assets/fonts/cjk-ui.ttf as a compact subset of Noto Sans CJK SC.

Scans *.gd / *.tscn (skip addons, docs, .git, .godot, dist) for every CJK,
CJK-punctuation, fullwidth, and common UI punctuation codepoint, plus a
basic Latin/digit/ASCII set for mixed HUD strings.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {"addons", "docs", ".git", ".godot", "dist", "__pycache__"}
SOURCE_EXTS = {".gd", ".tscn"}
SOURCE_CANDIDATES = [
    Path("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"),
    Path("/tmp/noto-sc/NotoSansSC-Regular.otf"),
    Path.home() / "Library/Fonts/NotoSansSC-Regular.otf",
    Path.home() / "Library/Fonts/NotoSansCJKsc-Regular.otf",
]
OUT_TTF = ROOT / "assets" / "fonts" / "cjk-ui.ttf"
IMPORT_PATH = ROOT / "assets" / "fonts" / "cjk-ui.ttf.import"
UNICODES_TXT = Path("/tmp/cjk-ui-unicodes.txt")
COMMON_HAN_TXT = ROOT / "tools" / "cjk-ui-common-han.txt"

# Printable ASCII for HUD numbers and English labels.
BASIC_LATIN = set(range(0x20, 0x7F))
# Cheap extras: mixed HUD strings + whole punctuation blocks (tiny vs CJK).
EXTRA_LATIN = set(range(0x00A0, 0x00C0)) | {
    0x00D7,
    0x00F7,
}
EXTRA_PUNCT_BLOCKS = (
    set(range(0x2000, 0x206F + 1))
    | set(range(0x3000, 0x303F + 1))
    | set(range(0xFE10, 0xFE1F + 1))
    | set(range(0xFE30, 0xFE4F + 1))
    | set(range(0xFE50, 0xFE6F + 1))
    | set(range(0xFF00, 0xFF60 + 1))
)


def is_source_cjk_or_punct(cp: int) -> bool:
    ranges = (
        (0x2000, 0x206F),  # general punctuation
        (0x2E80, 0x2EFF),  # CJK radicals supplement
        (0x2F00, 0x2FDF),  # Kangxi radicals
        (0x3000, 0x303F),  # CJK symbols and punctuation
        (0x3040, 0x30FF),  # hiragana + katakana
        (0x3100, 0x312F),  # bopomofo
        (0x3190, 0x319F),  # kanbun
        (0x31C0, 0x31EF),  # CJK strokes
        (0x3200, 0x32FF),  # enclosed CJK
        (0x3300, 0x33FF),  # CJK compatibility
        (0x3400, 0x4DBF),  # CJK ext A
        (0x4E00, 0x9FFF),  # CJK unified
        (0xF900, 0xFAFF),  # CJK compatibility ideographs
        (0xFE10, 0xFE1F),  # vertical forms
        (0xFE30, 0xFE4F),  # CJK compatibility forms
        (0xFE50, 0xFE6F),  # small form variants
        (0xFF00, 0xFFEF),  # halfwidth / fullwidth
    )
    return any(lo <= cp <= hi for lo, hi in ranges)


def iter_source_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        rel = Path(dirpath).relative_to(root)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        for name in filenames:
            if Path(name).suffix.lower() in SOURCE_EXTS:
                yield Path(dirpath) / name


def scan_codepoints() -> set[int]:
    found: set[int] = set()
    for path in iter_source_files(ROOT):
        text = path.read_text(encoding="utf-8")
        for ch in text:
            cp = ord(ch)
            if is_source_cjk_or_punct(cp):
                found.add(cp)
    return found


def common_han_codepoints() -> set[int]:
    if not COMMON_HAN_TXT.exists():
        return set()
    text = COMMON_HAN_TXT.read_text(encoding="utf-8")
    return {ord(ch) for ch in text if 0x4E00 <= ord(ch) <= 0x9FFF}


def pick_source() -> Path:
    for path in SOURCE_CANDIDATES:
        if path.exists():
            return path
    listed = "\n".join(f"  {p}" for p in SOURCE_CANDIDATES)
    raise SystemExit("missing CJK source face. Tried:\n" + listed)


def sc_face_index(ttc_path: Path) -> int:
    from fontTools.ttLib import TTCollection

    col = TTCollection(str(ttc_path))
    for i, font in enumerate(col.fonts):
        name = font["name"]
        family = name.getDebugName(1) or ""
        subfamily = name.getDebugName(2) or ""
        full = name.getDebugName(4) or ""
        label = f"{family} {subfamily} | {full}"
        print(f"  face {i}: {label}")
        blob = f"{family} {subfamily} {full}".lower()
        if "sc" in blob.split() or "simplified" in blob or blob.endswith(" sc") or " cjk sc" in blob or "heiti sc" in blob:
            if "regular" in blob or subfamily.lower() == "regular" or "light" in blob:
                return i
    # Debian NotoSansCJK-Regular.ttc order is JP, KR, SC, TC, HK.
    for i, font in enumerate(col.fonts):
        full = (font["name"].getDebugName(4) or "").lower()
        family = (font["name"].getDebugName(1) or "").lower()
        if "cjk sc" in full or "cjk sc" in family or family.endswith("sc") or "heiti sc" in full or "heiti sc" in family:
            return i
    # Language-specific TTCs (STHeiti) still work if we take the last SC-ish face.
    if col.fonts:
        print("warning: no labeled SC Regular face, using 0")
        return 0
    raise SystemExit("Could not find a Simplified Chinese face in the TTC")


def unicodes_arg(cps: set[int]) -> str:
    return ",".join(f"U+{cp:04X}" for cp in sorted(cps))


def compact_ranges(cps: list[int]) -> list[tuple[int, int]]:
    if not cps:
        return []
    ranges = []
    start = prev = cps[0]
    for cp in cps[1:]:
        if cp == prev + 1:
            prev = cp
            continue
        ranges.append((start, prev))
        start = prev = cp
    ranges.append((start, prev))
    return ranges


def godot_chars_literal(cps: list[int]) -> str:
    return ", ".join(str(cp) for cp in cps)


def main() -> int:
    sys.path.insert(0, str(Path(sys.executable).resolve()))
    scanned = scan_codepoints()
    common_han = common_han_codepoints()
    wanted = set(BASIC_LATIN) | set(EXTRA_LATIN) | set(EXTRA_PUNCT_BLOCKS) | scanned | common_han
    preload = set(BASIC_LATIN) | scanned
    print(f"scanned CJK/punct codepoints: {len(scanned)}")
    print(f"common Han extras:            {len(common_han)}")
    print(f"union for subset:             {len(wanted)}")
    print(f"preload (HUD) codepoints:     {len(preload)}")

    source = pick_source()
    print(f"source face: {source}")
    cmd = [
        pyftsubset_bin(),
        str(source),
        f"--unicodes-file={UNICODES_TXT}",
        f"--output-file={OUT_TTF}",
        "--name-IDs=*",
        "--name-legacy",
        "--name-languages=*",
        "--notdef-glyph",
        "--notdef-outline",
        "--recommended-glyphs",
        "--legacy-cmap",
        "--symbol-cmap",
        "--drop-tables+=DSIG",
        "--layout-features=*",
        "--ignore-missing-unicodes",
    ]
    if source.suffix.lower() == ".ttc":
        print("TTC faces:")
        face = sc_face_index(source)
        print(f"using font-number={face}")
        cmd.insert(2, f"--font-number={face}")

    UNICODES_TXT.write_text(unicodes_arg(wanted) + "\n", encoding="utf-8")
    print("running:", " ".join(cmd))
    subprocess.check_call(cmd)

    from fontTools.ttLib import TTFont

    font = TTFont(str(OUT_TTF))
    cmap = font.getBestCmap() or {}
    present = set(cmap.keys())
    missing = sorted(scanned - present)
    missing_all = sorted(wanted - present)
    size = OUT_TTF.stat().st_size
    print(f"wrote {OUT_TTF} ({size} bytes, {size / 1024:.1f} KiB)")
    print(f"cmap size: {len(present)}")
    print(f"scanned coverage: {len(scanned) - len(missing)}/{len(scanned)}")
    if missing:
        sample = " ".join(f"U+{cp:04X} {chr(cp)}" for cp in missing[:40])
        print("MISSING scanned:", sample)
        return 1
    if missing_all:
        sample = " ".join(f"U+{cp:04X}" for cp in missing_all[:40])
        print("MISSING extras (non-fatal):", sample)
    ranges = compact_ranges(sorted(wanted))
    print(f"unicode ranges: {len(ranges)}")
    # Write a sidecar the import updater can reuse.
    print("preload HUD codepoints:", " ".join(str(cp) for cp in sorted(preload)[:8]), "...")
    write_godot_import_preload(sorted(preload))
    return 0


def pyftsubset_bin() -> str:
    sibling = Path(sys.executable).parent / "pyftsubset"
    if sibling.exists():
        return str(sibling)
    return "pyftsubset"


def write_godot_import_preload(cps: list[int]) -> None:
    if not IMPORT_PATH.exists():
        print("skip import update: missing", IMPORT_PATH)
        return
    text = IMPORT_PATH.read_text(encoding="utf-8")
    key = '"chars": PackedInt32Array('
    start = text.find(key)
    if start < 0:
        print("skip import update: no PackedInt32Array chars")
        return
    inner_start = start + len(key)
    inner_end = text.find(")", inner_start)
    text = text[:inner_start] + ", ".join(str(cp) for cp in cps) + text[inner_end:]
    IMPORT_PATH.write_text(text, encoding="utf-8")
    print(f"updated {IMPORT_PATH.name} preload chars={len(cps)}")


if __name__ == "__main__":
    raise SystemExit(main())
