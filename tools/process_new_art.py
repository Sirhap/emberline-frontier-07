#!/usr/bin/env python3
"""Cut generated art, size it for Godot, and build walk / unarmed hero cycles."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GEN = ROOT / "assets" / "generated"
SRC = Path("/Users/sirhao/.cursor/projects/Volumes-other-IdeaProjects-sirhao-emberline-frontier-07/assets")
HERO_DIR = ROOT / "xsxb_frame_tuner" / "workspace" / "projects" / "emberline_frontier_07_final" / "assets" / "ember_hero"

WALK_POSES = (
    (0, 0.0, 1.00),
    (2, -5.0, 1.03),
    (3, -2.0, 1.05),
    (0, 0.0, 0.96),
    (2, 5.0, 1.03),
    (1, 2.0, 1.02),
)


def is_checker(r: int, g: int, b: int) -> bool:
    mx, mn = max(r, g, b), min(r, g, b)
    avg = (r + g + b) / 3.0
    return mx - mn <= 22 and 48 <= avg <= 230


def is_near_black(r: int, g: int, b: int, limit: int = 22) -> bool:
    return r <= limit and g <= limit and b <= limit


def flood_clear(image: Image.Image, edge_black: bool = True) -> Image.Image:
    src = image.convert("RGBA")
    width, height = src.size
    pixels = list(src.getdata())
    seen = [False] * (width * height)
    queue: list[int] = []

    def push(index: int) -> None:
        if 0 <= index < width * height and not seen[index]:
            seen[index] = True
            queue.append(index)

    for x in range(width):
        push(x)
        push((height - 1) * width + x)
    for y in range(height):
        push(y * width)
        push(y * width + width - 1)

    while queue:
        index = queue.pop()
        r, g, b, a = pixels[index]
        if a == 0:
            continue
        bg = is_checker(r, g, b) or (edge_black and is_near_black(r, g, b))
        if not bg:
            continue
        pixels[index] = (0, 0, 0, 0)
        x, y = index % width, index // width
        if x > 0:
            push(index - 1)
        if x + 1 < width:
            push(index + 1)
        if y > 0:
            push(index - width)
        if y + 1 < height:
            push(index + width)

    src.putdata(pixels)
    return src


def content_box(image: Image.Image, alpha_min: int = 18) -> tuple[int, int, int, int]:
    alpha = image.split()[-1]
    bbox = alpha.point(lambda p: 255 if p >= alpha_min else 0).getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    return bbox


def place(image: Image.Image, width: int, height: int, bottom_center: bool = True) -> Image.Image:
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    box = content_box(image)
    cropped = image.crop(box)
    if bottom_center:
        x = (width - cropped.width) // 2
        y = height - cropped.height - 4
    else:
        x = (width - cropped.width) // 2
        y = (height - cropped.height) // 2
    canvas.alpha_composite(cropped, (max(0, x), max(0, y)))
    return canvas


def fit(image: Image.Image, max_w: int, max_h: int) -> Image.Image:
    box = content_box(image)
    cropped = image.crop(box)
    scale = min(max_w / cropped.width, max_h / cropped.height)
    size = (max(1, int(cropped.width * scale)), max(1, int(cropped.height * scale)))
    return cropped.resize(size, Image.Resampling.LANCZOS)


def write_walk(stem: Image.Image, dest_stem: str) -> None:
    still = place(stem, 96, 96, True)
    still_path = GEN / "enemies" / f"{dest_stem}.png"
    still.save(still_path)
    print(f"wrote {still_path}")
    for index, (bob_y, angle, vscale) in enumerate(WALK_POSES):
        scaled_h = max(8, int(round(still.height * vscale)))
        body = still.resize((still.width, scaled_h), Image.Resampling.NEAREST)
        if abs(angle) > 0.01:
            body = body.rotate(angle, resample=Image.Resampling.NEAREST, expand=True)
        frame = Image.new("RGBA", still.size, (0, 0, 0, 0))
        frame.alpha_composite(body, ((still.width - body.width) // 2, still.height - body.height - bob_y))
        path = GEN / "enemies" / f"{dest_stem}-walk-{index}.png"
        frame.save(path)
        print(f"wrote {path}")


def write_cycle(source: Image.Image, dest_dir: Path, count: int, kind: str) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    for index in range(count):
        t = index / max(count - 1, 1)
        if kind == "idle":
            bob = int(round(math.sin(t * math.tau) * 3))
            angle = math.sin(t * math.tau) * 1.6
            vscale = 1.0 + math.sin(t * math.tau) * 0.018
        elif kind == "run":
            bob = int(round(abs(math.sin(t * math.tau * 2.0)) * 5))
            angle = math.sin(t * math.tau * 2.0) * 6.0
            vscale = 1.0 + math.sin(t * math.tau * 2.0) * 0.04
        else:
            lift = int(round(math.sin(t * math.pi) * 18))
            bob = -lift
            angle = math.sin(t * math.tau) * 2.5
            vscale = 1.0 + math.sin(t * math.pi) * 0.03
        scaled_h = max(16, int(round(source.height * vscale)))
        body = source.resize((source.width, scaled_h), Image.Resampling.NEAREST)
        if abs(angle) > 0.05:
            body = body.rotate(angle, resample=Image.Resampling.NEAREST, expand=True)
        frame = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        x = (256 - body.width) // 2
        y = 256 - body.height - 8 + bob
        frame.alpha_composite(body, (x, y))
        path = dest_dir / f"frame_{index + 1:04d}.png"
        frame.save(path)
    print(f"wrote {count} {kind} frames -> {dest_dir}")


def main() -> None:
    runner = flood_clear(Image.open(SRC / "ember-runner.png"))
    mage = flood_clear(Image.open(SRC / "ember-mage.png"))
    explode = flood_clear(Image.open(SRC / "core-explode.png"))
    hold = flood_clear(Image.open(SRC / "hold-sword.png"), edge_black=True)
    idle = flood_clear(Image.open(SRC / "hero-unarmed-idle.png"))
    run = flood_clear(Image.open(SRC / "hero-unarmed-run.png"))

    write_walk(fit(runner, 88, 88), "runner")
    write_walk(fit(mage, 88, 88), "mage")

    burst = place(fit(explode, 220, 220), 256, 256, False)
    burst_path = GEN / "fx" / "core-explode.png"
    burst.save(burst_path)
    print(f"wrote {burst_path}")

    sword = place(fit(hold, 88, 36), 96, 48, False)
    sword_path = GEN / "pickups" / "hold-sword.png"
    sword.save(sword_path)
    print(f"wrote {sword_path}")

    idle_body = place(fit(idle, 168, 188), 256, 256, True)
    run_body = place(fit(run, 188, 188), 256, 256, True)
    (GEN / "hero").mkdir(parents=True, exist_ok=True)
    idle_body.save(GEN / "hero" / "unarmed-idle.png")
    run_body.save(GEN / "hero" / "unarmed-run.png")

    write_cycle(idle_body, HERO_DIR / "idle", 16, "idle")
    write_cycle(run_body, HERO_DIR / "run", 31, "run")
    write_cycle(idle_body, HERO_DIR / "jump", 11, "jump")
    print("processed new art")


if __name__ == "__main__":
    main()
