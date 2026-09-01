#!/usr/bin/env python3
"""Process SK hub NPC stills + generate pedestal / conveyor / pad / gold-rail art."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets" / "generated"
STILLS = Path("/opt/cursor/artifacts/assets")
OUT_NPC = ART / "npc"
TARGET_H = 96
TARGET_W = 78


def is_bg(r: int, g: int, b: int) -> bool:
    return r >= 230 and g >= 230 and b >= 230 and abs(r - g) < 20 and abs(g - b) < 20


def extract_sprite(src: Path) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            r, g, b, _a = px[x, y]
            if is_bg(r, g, b):
                q.append((x, y))
                visited[y][x] = True
    for y in range(h):
        for x in (0, w - 1):
            if visited[y][x]:
                continue
            r, g, b, _a = px[x, y]
            if is_bg(r, g, b):
                q.append((x, y))
                visited[y][x] = True
    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                r, g, b, _a = px[nx, ny]
                if is_bg(r, g, b):
                    visited[ny][nx] = True
                    q.append((nx, ny))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    for y in range(h):
        for x in range(w):
            if not visited[y][x]:
                opx[x, y] = px[x, y]
    bbox = out.getbbox()
    if bbox is None:
        raise RuntimeError(f"empty extract {src}")
    out = out.crop(bbox)
    pad = 4
    padded = Image.new("RGBA", (out.width + pad * 2, out.height + pad * 2), (0, 0, 0, 0))
    padded.paste(out, (pad, pad), out)
    scale = TARGET_H / padded.height
    nw = max(24, int(round(padded.width * scale)))
    resized = padded.resize((nw, TARGET_H), Image.Resampling.LANCZOS)
    small = resized.resize((max(20, nw // 3), max(24, TARGET_H // 3)), Image.Resampling.BOX)
    pixel = small.resize((nw, TARGET_H), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (TARGET_W, TARGET_H), (0, 0, 0, 0))
    if nw > TARGET_W:
        pixel = pixel.crop(((nw - TARGET_W) // 2, 0, (nw - TARGET_W) // 2 + TARGET_W, TARGET_H))
        canvas.paste(pixel, (0, 0), pixel)
    else:
        canvas.paste(pixel, ((TARGET_W - nw) // 2, 0), pixel)
    return canvas


def idle_frames(base: Image.Image) -> list[Image.Image]:
    frames = []
    for dy in (0, -1, 0, 1):
        fr = Image.new("RGBA", base.size, (0, 0, 0, 0))
        fr.paste(base, (0, dy), base)
        frames.append(fr)
    return frames


def restock_frames(base: Image.Image) -> list[Image.Image]:
    frames = []
    for ox, oy in ((0, 0), (1, -1), (2, -2), (1, -1), (0, 0), (-1, 1)):
        fr = Image.new("RGBA", base.size, (0, 0, 0, 0))
        fr.paste(base, (ox, oy), base)
        frames.append(fr)
    return frames


def save_npc(name: str, still: Path) -> None:
    sprite = extract_sprite(still)
    folder = OUT_NPC / name
    (folder / "idle").mkdir(parents=True, exist_ok=True)
    (folder / "restock").mkdir(parents=True, exist_ok=True)
    sprite.save(OUT_NPC / f"{name}.png")
    for i, fr in enumerate(idle_frames(sprite)):
        fr.save(folder / "idle" / f"frame_{i:02d}.png")
    for i, fr in enumerate(restock_frames(sprite)):
        fr.save(folder / "restock" / f"frame_{i:02d}.png")
    print(f"NPC {name}: {sprite.size}")


def gold_pedestal(path: Path) -> None:
    w, h = 48, 28
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((4, 14, 43, 26), fill=(58, 48, 36, 255))
    d.rectangle((6, 16, 41, 24), fill=(92, 74, 48, 255))
    gold = (212, 168, 72, 255)
    gold_hi = (246, 214, 120, 255)
    gold_lo = (148, 108, 40, 255)
    d.rectangle((8, 8, 39, 18), fill=gold_lo)
    d.rectangle((10, 9, 37, 16), fill=gold)
    d.rectangle((12, 10, 35, 12), fill=gold_hi)
    d.rectangle((14, 4, 33, 10), fill=(36, 32, 28, 255))
    d.rectangle((15, 5, 32, 8), fill=(54, 48, 42, 255))
    for x, y in ((9, 9), (36, 9), (9, 15), (36, 15)):
        d.point((x, y), fill=gold_hi)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print(f"pedestal {path}")


def conveyor_pad(path: Path, phase: str = "closed") -> None:
    """Top-down metal pad. 52x36 drawing on a 56x40 canvas. phase: closed / open / spit."""
    w, h = 56, 40
    ox, oy = 2, 2
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    metal = (72, 78, 88, 255)
    metal_hi = (118, 126, 138, 255)
    metal_lo = (42, 46, 54, 255)
    gold = (212, 168, 72, 255)
    gold_hi = (246, 214, 120, 255)
    gold_lo = (148, 108, 40, 255)
    d.rectangle((2 + ox, 6 + oy, 49 + ox, 33 + oy), fill=metal_lo)
    d.rectangle((4 + ox, 8 + oy, 47 + ox, 30 + oy), fill=metal)
    parted = phase in ("open", "spit")
    for x in range(8, 46, 6):
        dx = (-2 if x < 25 else 2) if parted else 0
        d.rectangle((x + ox + dx, 10 + oy, x + 2 + ox + dx, 28 + oy), fill=metal_lo)
        d.point((x + 1 + ox + dx, 14 + oy), fill=metal_hi)
    if parted:
        d.rectangle((23 + ox, 12 + oy, 28 + ox, 26 + oy), fill=(36, 32, 28, 255))
        d.rectangle((24 + ox, 14 + oy, 27 + ox, 24 + oy), fill=gold)
        d.rectangle((25 + ox, 16 + oy, 26 + ox, 22 + oy), fill=gold_hi)
        if phase == "spit":
            d.point((25 + ox, 8 + oy), fill=gold_hi)
            d.point((27 + ox, 7 + oy), fill=gold)
    else:
        d.rectangle((10 + ox, 18 + oy, 41 + ox, 20 + oy), fill=gold_lo)
        d.rectangle((11 + ox, 18 + oy, 40 + ox, 19 + oy), fill=gold_hi)
    d.rectangle((2 + ox, 6 + oy, 49 + ox, 9 + oy), fill=gold_lo)
    d.rectangle((3 + ox, 7 + oy, 48 + ox, 8 + oy), fill=gold_hi)
    d.rectangle((2 + ox, 30 + oy, 49 + ox, 33 + oy), fill=gold_lo)
    d.rectangle((3 + ox, 31 + oy, 48 + ox, 32 + oy), fill=gold)
    d.rectangle((2 + ox, 6 + oy, 5 + ox, 33 + oy), fill=gold_lo)
    d.rectangle((3 + ox, 8 + oy, 4 + ox, 31 + oy), fill=gold)
    d.rectangle((46 + ox, 6 + oy, 49 + ox, 33 + oy), fill=gold_lo)
    d.rectangle((47 + ox, 8 + oy, 48 + ox, 31 + oy), fill=gold_hi)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print(f"conveyor {phase} {path}")


def weapon_pad(path: Path) -> None:
    w, h = 64, 56
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    outline = (18, 20, 24, 255)
    metal_lo = (48, 52, 60, 255)
    metal = (86, 92, 104, 255)
    metal_hi = (150, 158, 170, 255)
    d.rectangle((4, 6, 59, 51), fill=outline)
    d.rectangle((6, 8, 57, 49), fill=metal_lo)
    d.rectangle((10, 12, 53, 45), fill=metal)
    d.rectangle((10, 12, 53, 14), fill=metal_hi)
    d.rectangle((10, 12, 12, 45), fill=metal_hi)
    d.rectangle((28, 6, 36, 9), fill=outline)
    d.rectangle((28, 48, 36, 51), fill=outline)
    d.rectangle((4, 24, 7, 32), fill=outline)
    d.rectangle((56, 24, 59, 32), fill=outline)
    bolt = (220, 224, 230, 255)
    for x, y in ((8, 10), (54, 10), (8, 46), (54, 46)):
        d.rectangle((x, y, x + 2, y + 2), fill=bolt)
    g = (48, 210, 90, 255)
    g2 = (24, 140, 60, 255)
    d.polygon([(32, 16), (44, 30), (36, 30), (36, 40), (28, 40), (28, 30), (20, 30)], fill=g)
    d.polygon([(32, 18), (40, 28), (34, 28), (34, 38), (30, 38), (30, 28), (24, 28)], fill=g2)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print(f"weapon-pad {path}")


def gold_rail_tile(path: Path) -> None:
    w, h = 64, 12
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 2, 63, 10), fill=(120, 88, 32, 255))
    d.rectangle((0, 3, 63, 5), fill=(236, 200, 96, 255))
    d.rectangle((0, 5, 63, 7), fill=(196, 152, 56, 255))
    d.rectangle((0, 7, 63, 9), fill=(148, 108, 36, 255))
    for x in range(8, 64, 16):
        d.point((x, 5), fill=(255, 230, 140, 255))
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print(f"gold-rail {path}")


def main() -> None:
    mapping = {
        "mechanic": STILLS / "npc-mechanic-still.png",
        "officer": STILLS / "npc-officer-still.png",
        "mentor": STILLS / "npc-mentor-still.png",
        "merchant": STILLS / "npc-merchant-sk-still.png",
    }
    for name, still in mapping.items():
        if not still.exists():
            print(f"skip missing still {still}")
            continue
        save_npc(name, still)
    mentor_png = OUT_NPC / "mentor.png"
    if mentor_png.exists():
        # Keep trainer.png pointing at mentor still for any legacy loaders.
        Image.open(mentor_png).save(OUT_NPC / "trainer.png")
    gold_pedestal(ART / "ui" / "shop-pedestal.png")
    conveyor_pad(ART / "ui" / "home-conveyor.png", "closed")
    conveyor_pad(ART / "ui" / "home-conveyor-open.png", "open")
    conveyor_pad(ART / "ui" / "home-conveyor-spit.png", "spit")
    weapon_pad(ART / "towers" / "weapon-pad.png")
    gold_rail_tile(ART / "fx" / "gold-rail.png")
    print("HUB_VISUALS_OK")


if __name__ == "__main__":
    main()
