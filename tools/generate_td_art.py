#!/usr/bin/env python3
"""Generate missing pixel-art PNGs for the endless TD pass."""

from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets" / "generated"


def write_png(path: Path, width: int, height: int, pixels: list[tuple[int, int, int, int]]) -> None:
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(pixels[y * width + x])

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def canvas(width: int, height: int, fill: tuple[int, int, int, int] = (0, 0, 0, 0)) -> list[tuple[int, int, int, int]]:
    return [fill] * (width * height)


def plot(pixels: list[tuple[int, int, int, int]], width: int, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if 0 <= x < width and 0 <= y < (len(pixels) // width):
        pixels[y * width + x] = color


def fill_rect(pixels: list[tuple[int, int, int, int]], width: int, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int]) -> None:
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            plot(pixels, width, xx, yy, color)


def tower(path: Path, energy: tuple[int, int, int], accent: tuple[int, int, int], level: int, style: str = "pulse") -> None:
    w = h = 96
    px = canvas(w, h)
    metal = (42, 48, 58, 255)
    metal_hi = (78, 86, 98, 255)
    brass = (168, 122, 58, 255)
    e = (*energy, 255)
    a = (*accent, 255)
    fill_rect(px, w, 28, 70, 40, 14, metal)
    fill_rect(px, w, 26, 70, 44, 3, brass)
    fill_rect(px, w, 40, 58, 16, 14, metal_hi)
    fill_rect(px, w, 32, 36, 32, 24, metal)
    fill_rect(px, w, 36, 40, 24, 10, e)
    fill_rect(px, w, 44, 42, 8, 6, a)
    if style == "burst":
        fill_rect(px, w, 58, 38, 22 + level * 2, 6, metal_hi)
        fill_rect(px, w, 58, 50, 22 + level * 2, 6, metal_hi)
        fill_rect(px, w, 76 + level * 2, 38, 5, 6, a)
        fill_rect(px, w, 76 + level * 2, 50, 5, 6, a)
        fill_rect(px, w, 30, 74, 36, 6, (180, 70, 36, 255))
    elif style == "frost":
        fill_rect(px, w, 44, 14, 8, 24, a)
        fill_rect(px, w, 40, 18, 16, 6, e)
        fill_rect(px, w, 60, 40, 8, 20 + level * 2, metal_hi)
        fill_rect(px, w, 58, 36, 12, 5, a)
        fill_rect(px, w, 28, 74, 40, 4, (120, 200, 230, 255))
    else:
        barrel_w = 18 + level * 4
        fill_rect(px, w, 60, 44, barrel_w, 8, metal_hi)
        fill_rect(px, w, 60 + barrel_w - 4, 45, 4, 6, a)
    if level >= 2:
        fill_rect(px, w, 34, 30, 10, 8, e)
    if level >= 3:
        fill_rect(px, w, 52, 30, 10, 8, e)
        fill_rect(px, w, 24, 74, 48, 4, brass)
    write_png(path, w, h, px)


def blob(path: Path, w: int, h: int, color: tuple[int, int, int], core: tuple[int, int, int]) -> None:
    px = canvas(w, h)
    cx, cy = w // 2, h // 2
    for y in range(h):
        for x in range(w):
            d = ((x - cx) ** 2 / (cx * cx + 1) + (y - cy) ** 2 / (cy * cy + 1)) ** 0.5
            if d < 0.35:
                plot(px, w, x, y, (*core, 255))
            elif d < 0.7:
                plot(px, w, x, y, (*color, 255))
            elif d < 0.9:
                plot(px, w, x, y, (*color, 160))
    write_png(path, w, h, px)


def boss(path: Path) -> None:
    w = h = 96
    px = canvas(w, h)
    fill_rect(px, w, 22, 38, 52, 40, (48, 28, 36, 255))
    fill_rect(px, w, 18, 48, 12, 22, (72, 36, 40, 255))
    fill_rect(px, w, 66, 48, 12, 22, (72, 36, 40, 255))
    fill_rect(px, w, 30, 22, 36, 24, (86, 40, 48, 255))
    fill_rect(px, w, 36, 28, 8, 8, (255, 180, 70, 255))
    fill_rect(px, w, 52, 28, 8, 8, (255, 180, 70, 255))
    fill_rect(px, w, 40, 48, 16, 10, (255, 90, 70, 255))
    fill_rect(px, w, 28, 78, 14, 8, (32, 20, 24, 255))
    fill_rect(px, w, 54, 78, 14, 8, (32, 20, 24, 255))
    write_png(path, w, h, px)


def gun(path: Path, long_barrel: bool) -> None:
    w = h = 48
    px = canvas(w, h)
    fill_rect(px, w, 10, 24, 10, 12, (168, 122, 58, 255))
    fill_rect(px, w, 18, 20, 18 if long_barrel else 12, 8, (70, 78, 90, 255))
    fill_rect(px, w, 18 + (16 if long_barrel else 10), 22, 8 if long_barrel else 6, 4, (255, 200, 90, 255))
    if not long_barrel:
        fill_rect(px, w, 22, 28, 10, 6, (90, 70, 50, 255))
    write_png(path, w, h, px)


def hold_gun(path: Path, shotgun: bool) -> None:
    w, h = 96, 48
    px = canvas(w, h)
    fill_rect(px, w, 10, 22, 14, 18, (168, 122, 58, 255))
    fill_rect(px, w, 12, 24, 8, 8, (210, 168, 90, 255))
    if shotgun:
        fill_rect(px, w, 20, 16, 52, 14, (58, 64, 74, 255))
        fill_rect(px, w, 24, 18, 40, 6, (92, 100, 112, 255))
        fill_rect(px, w, 36, 28, 18, 8, (90, 70, 50, 255))
        fill_rect(px, w, 70, 18, 14, 8, (255, 170, 70, 255))
        fill_rect(px, w, 80, 20, 8, 4, (255, 230, 140, 255))
    else:
        fill_rect(px, w, 20, 16, 58, 10, (70, 78, 90, 255))
        fill_rect(px, w, 24, 14, 44, 4, (120, 130, 146, 255))
        fill_rect(px, w, 22, 24, 10, 6, (48, 54, 64, 255))
        fill_rect(px, w, 74, 18, 12, 6, (255, 200, 90, 255))
        fill_rect(px, w, 84, 19, 6, 4, (255, 240, 180, 255))
    write_png(path, w, h, px)


def dash_icon(path: Path) -> None:
    w = h = 48
    px = canvas(w, h)
    fill_rect(px, w, 8, 22, 20, 6, (90, 210, 255, 255))
    fill_rect(px, w, 24, 16, 16, 18, (154, 230, 255, 255))
    fill_rect(px, w, 34, 20, 8, 10, (255, 255, 255, 255))
    write_png(path, w, h, px)


def main() -> None:
    tower(ROOT / "towers" / "burst-lv1.png", (255, 120, 50), (255, 220, 90), 1, "burst")
    tower(ROOT / "towers" / "burst-lv2.png", (255, 90, 40), (255, 200, 70), 2, "burst")
    tower(ROOT / "towers" / "burst-lv3.png", (255, 60, 30), (255, 180, 50), 3, "burst")
    tower(ROOT / "towers" / "frost-lv1.png", (80, 210, 255), (200, 250, 255), 1, "frost")
    tower(ROOT / "towers" / "frost-lv2.png", (50, 180, 255), (180, 240, 255), 2, "frost")
    tower(ROOT / "towers" / "frost-lv3.png", (30, 150, 255), (160, 230, 255), 3, "frost")
    boss(ROOT / "enemies" / "boss.png")
    blob(ROOT / "fx" / "hero-bullet.png", 48, 24, (255, 200, 70), (255, 255, 220))
    blob(ROOT / "fx" / "hero-pellet.png", 24, 16, (255, 140, 60), (255, 230, 180))
    blob(ROOT / "fx" / "muzzle.png", 32, 32, (255, 220, 120), (255, 255, 255))
    gun(ROOT / "pickups" / "pistol.png", True)
    gun(ROOT / "pickups" / "shotgun.png", False)
    hold_gun(ROOT / "pickups" / "hold-pistol.png", False)
    hold_gun(ROOT / "pickups" / "hold-shotgun.png", True)
    dash_icon(ROOT / "pickups" / "dash.png")
    print("generated td art")


if __name__ == "__main__":
    main()
