#!/usr/bin/env python3
"""Build 6-frame walk cycles from the existing enemy stills."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets" / "generated" / "enemies"

# bob_y, rotate_deg, vertical_scale
POSES = (
    (0, 0.0, 1.00),
    (2, -5.0, 1.03),
    (3, -2.0, 1.05),
    (0, 0.0, 0.96),
    (2, 5.0, 1.03),
    (1, 2.0, 1.02),
)


def make_frame(source: Image.Image, bob_y: int, angle: float, vscale: float) -> Image.Image:
    width, height = source.size
    scaled_h = max(8, int(round(height * vscale)))
    body = source.resize((width, scaled_h), Image.Resampling.NEAREST)
    if abs(angle) > 0.01:
        body = body.rotate(angle, resample=Image.Resampling.NEAREST, expand=True)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    paste_x = (width - body.width) // 2
    paste_y = height - body.height - bob_y
    canvas.alpha_composite(body, (paste_x, paste_y))
    return canvas


def write_cycle(stem: str) -> None:
    source = Image.open(ROOT / f"{stem}.png").convert("RGBA")
    for index, pose in enumerate(POSES):
        frame = make_frame(source, *pose)
        frame.save(ROOT / f"{stem}-walk-{index}.png")
        print(f"wrote {stem}-walk-{index}.png")


def main() -> None:
    for stem in ("scout", "brute", "boss", "runner", "mage"):
        write_cycle(stem)


if __name__ == "__main__":
    main()
