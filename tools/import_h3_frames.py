#!/usr/bin/env python3
"""Key H3 green-screen frames and write game-ready sprite cycles."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "tools" / "h3-out" / "frames"
HERO = ROOT / "xsxb_frame_tuner" / "workspace" / "projects" / "emberline_frontier_07_final" / "assets" / "ember_hero"
ENEMY = ROOT / "assets" / "generated" / "enemies"


def key_green(image: Image.Image) -> Image.Image:
    src = image.convert("RGBA")
    width, height = src.size
    pixels = list(src.getdata())
    out: list[tuple[int, int, int, int]] = []
    for r, g, b, a in pixels:
        if g >= 120 and g >= r + 28 and g >= b + 28:
            out.append((0, 0, 0, 0))
        else:
            spill = max(0, g - max(r, b))
            if spill > 18:
                g = max(0, g - spill)
            out.append((r, g, b, a))
    cleaned = list(out)
    for index, (r, g, b, a) in enumerate(out):
        if a == 0:
            continue
        x, y = index % width, index // width
        neighbors = 0
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and out[ny * width + nx][3] == 0:
                neighbors += 1
        if neighbors >= 2 and g > r + 12:
            cleaned[index] = (0, 0, 0, 0)
    src.putdata(cleaned)
    return src


def content_box(image: Image.Image, pad: int = 4) -> tuple[int, int, int, int]:
    alpha = image.split()[-1]
    box = alpha.point(lambda p: 255 if p >= 20 else 0).getbbox()
    if box is None:
        return (0, 0, image.width, image.height)
    x0, y0, x1, y1 = box
    return (
        max(0, x0 - pad),
        max(0, y0 - pad),
        min(image.width, x1 + pad),
        min(image.height, y1 + pad),
    )


def place(image: Image.Image, width: int, height: int, max_h: int) -> Image.Image:
    cropped = image.crop(content_box(image))
    scale = min(max_h / cropped.height, (width - 8) / cropped.width)
    size = (max(1, int(cropped.width * scale)), max(1, int(cropped.height * scale)))
    body = cropped.resize(size, Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    x = (width - body.width) // 2
    y = height - body.height - 6
    canvas.alpha_composite(body, (x, y))
    return canvas


def sample(paths: list[Path], count: int) -> list[Path]:
    if count >= len(paths):
        return paths
    if count == 1:
        return [paths[0]]
    return [paths[round(i * (len(paths) - 1) / (count - 1))] for i in range(count)]


def write_hero(name: str, dest: Path, count: int, max_h: int) -> None:
    frames = sorted((SRC / name).glob("f_*.png"))
    dest.mkdir(parents=True, exist_ok=True)
    for index, path in enumerate(sample(frames, count), start=1):
        keyed = key_green(Image.open(path))
        placed = place(keyed, 256, 256, max_h)
        placed.save(dest / f"frame_{index:04d}.png")
    print(f"wrote {count} {name} -> {dest}")


def write_enemy(name: str, stem: str, max_h: int) -> None:
    frames = sorted((SRC / name).glob("f_*.png"))
    chosen = sample(frames, 6)
    stills: list[Image.Image] = []
    for index, path in enumerate(chosen):
        keyed = key_green(Image.open(path))
        placed = place(keyed, 96, 96, max_h)
        stills.append(placed)
        placed.save(ENEMY / f"{stem}-walk-{index}.png")
    stills[0].save(ENEMY / f"{stem}.png")
    print(f"wrote {stem} still + 6 walk frames")


def main() -> None:
    write_hero("hero-idle", HERO / "idle", 16, 150)
    write_hero("hero-run", HERO / "run", 31, 158)
    write_hero("hero-idle", HERO / "jump", 11, 150)
    write_enemy("runner", "runner", 72)
    write_enemy("mage", "mage", 78)
    preview = place(key_green(Image.open(SRC / "hero-idle" / "f_001.png")), 256, 256, 150)
    preview_path = ROOT / "assets" / "generated" / "hero" / "unarmed-idle.png"
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(preview_path)
    print("imported H3 frames")


if __name__ == "__main__":
    main()
