#!/usr/bin/env python3
"""Key chroma and fit harvested frames onto a transparent canvas with feet on the bottom edge."""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from PIL import Image


def is_chroma(r: int, g: int, b: int, a: int) -> bool:
    if a < 8:
        return True
    # magenta / hot pink
    if r > 180 and b > 180 and g < 90:
        return True
    # greenscreen
    if g > 90 and g > r + 25 and g > b + 25:
        return True
    return False


def rgba(im: Image.Image) -> Image.Image:
    return im.convert("RGBA") if im.mode != "RGBA" else im


def keyed(im: Image.Image) -> Image.Image:
    src = rgba(im)
    px = src.load()
    w, h = src.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dest = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_chroma(r, g, b, a):
                continue
            dest[x, y] = (r, g, b, 255)
    return out


def opaque_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 8:
                if x < minx:
                    minx = x
                if y < miny:
                    miny = y
                if x > maxx:
                    maxx = x
                if y > maxy:
                    maxy = y
    if maxx < 0:
        return None
    return minx, miny, maxx, maxy


def fit_feet(
    im: Image.Image,
    canvas: int,
    body_h: int,
) -> Image.Image:
    box = opaque_bbox(im)
    if box is None:
        return Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    x0, y0, x1, y1 = box
    crop = im.crop((x0, y0, x1 + 1, y1 + 1))
    cw, ch = crop.size
    if ch <= 0:
        return Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    scale = body_h / float(ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    if nw > canvas - 4:
        scale = (canvas - 4) / float(cw)
        nw = max(1, int(round(cw * scale)))
        nh = max(1, int(round(ch * scale)))
    resized = crop.resize((nw, nh), Image.Resampling.NEAREST)
    sheet = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    x = (canvas - nw) // 2
    y = canvas - nh
    sheet.paste(resized, (x, y), resized)
    return sheet


def list_frames(folder: Path) -> list[Path]:
    frames = sorted(folder.glob("*.png")) + sorted(folder.glob("*.jpg")) + sorted(folder.glob("*.jpeg"))
    return [p for p in frames if p.is_file()]


def pick_indices(n: int, want: int) -> list[int]:
    if n <= want:
        return list(range(n))
    if want == 1:
        return [0]
    return [round(i * (n - 1) / (want - 1)) for i in range(want)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", required=True)
    parser.add_argument("--dst", required=True)
    parser.add_argument("--canvas", type=int, required=True)
    parser.add_argument("--body", type=int, required=True)
    parser.add_argument("--count", type=int, default=0)
    parser.add_argument("--prefix", default="frame_")
    args = parser.parse_args()
    src = Path(args.src)
    dst = Path(args.dst)
    dst.mkdir(parents=True, exist_ok=True)
    frames = list_frames(src)
    if not frames:
        raise SystemExit(f"no frames in {src}")
    want = args.count if args.count > 0 else len(frames)
    chosen = [frames[i] for i in pick_indices(len(frames), want)]
    for old in dst.glob("frame_*.png"):
        old.unlink()
    for i, path in enumerate(chosen, start=1):
        im = keyed(Image.open(path))
        out = fit_feet(im, args.canvas, args.body)
        dest = dst / f"{args.prefix}{i:04d}.png"
        out.save(dest)
        print(dest, out.size)
    print(f"packed {len(chosen)} -> {dst}")


if __name__ == "__main__":
    main()
