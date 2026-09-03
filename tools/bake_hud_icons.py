#!/usr/bin/env python3
"""Hard-edge HUD glyphs: dark outline, no white stroke, no opaque plate."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "assets" / "generated" / "ui"
HERO = ROOT / "assets" / "generated" / "hero"
PICKUPS = ROOT / "assets" / "generated" / "pickups"

OUT = (20, 22, 28, 255)
WHITE = (244, 247, 250, 255)
INK = (78, 86, 94, 255)


def blank(n: int) -> Image.Image:
    return Image.new("RGBA", (n, n), (0, 0, 0, 0))


def put(im: Image.Image, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def grow_outline(im: Image.Image, color: tuple[int, int, int, int] = OUT) -> None:
    w, h = im.size
    px = im.load()
    marks: list[tuple[int, int]] = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] != 0:
                continue
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0:
                    marks.append((x, y))
                    break
    for x, y in marks:
        px[x, y] = color


def choke_light_edge(im: Image.Image, lum_thresh: float = 135.0) -> None:
    w, h = im.size
    px = im.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 200:
                px[x, y] = (0, 0, 0, 0)
                continue
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            if lum < lum_thresh:
                continue
            edge = False
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] < 200:
                    edge = True
                    break
            if edge:
                px[x, y] = OUT


def center_opaque(im: Image.Image) -> Image.Image:
    box = im.getbbox()
    if box is None:
        return im
    cropped = im.crop(box)
    canvas = blank(im.width)
    ox = (im.width - cropped.width) // 2
    oy = (im.height - cropped.height) // 2
    canvas.paste(cropped, (ox, oy), cropped)
    return canvas


def scale_nn(im: Image.Image, factor: int) -> Image.Image:
    return im.resize((im.width * factor, im.height * factor), Image.NEAREST)


def stamp_rows(im: Image.Image, ox: int, oy: int, rows: list[str], palette: dict[str, tuple[int, int, int, int]]) -> None:
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in palette:
                put(im, ox + x, oy + y, palette[ch])


def draw_crosshair() -> Image.Image:
    im = blank(32)
    cx, cy, radius = 15, 15, 8
    x, y = 0, radius
    d = 1 - radius
    while x <= y:
        for px, py in (
            (cx + x, cy + y),
            (cx - x, cy + y),
            (cx + x, cy - y),
            (cx - x, cy - y),
            (cx + y, cy + x),
            (cx - y, cy + x),
            (cx + y, cy - x),
            (cx - y, cy - x),
        ):
            put(im, px, py, WHITE)
        x += 1
        if d < 0:
            d += 2 * x + 1
        else:
            y -= 1
            d += 2 * (x - y) + 1
    for t in range(1, 5):
        put(im, cx, cy - radius - t, WHITE)
        put(im, cx, cy + radius + t, WHITE)
        put(im, cx - radius - t, cy, WHITE)
        put(im, cx + radius + t, cy, WHITE)
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if abs(dx) + abs(dy) <= 1:
                put(im, cx + dx, cy + dy, WHITE)
    return im


def draw_daggers() -> Image.Image:
    im = blank(32)
    pal = {"#": WHITE}

    def dagger(ox: int, oy: int) -> None:
        stamp_rows(
            im,
            ox,
            oy,
            [
                "...............",
                ".##.###########",
                ".##############",
                ".##.###########",
            ],
            pal,
        )

    dagger(4, 8)
    dagger(4, 18)
    return im


def stamp_chevron_right(im: Image.Image, ox: int, oy: int, fill: tuple[int, int, int, int], thick: int = 3, h: int = 13) -> None:
    mid = h // 2
    for i in range(h):
        x0 = mid - abs(i - mid)
        for t in range(thick):
            put(im, ox + x0 + t, oy + i, fill)


def stamp_chevron_up(im: Image.Image, ox: int, oy: int, fill: tuple[int, int, int, int], thick: int = 3, w: int = 13) -> None:
    mid = w // 2
    for i in range(w):
        y0 = abs(i - mid)
        for t in range(thick):
            put(im, ox + i, oy + y0 + t, fill)


def draw_skill() -> Image.Image:
    im = blank(24)
    stamp_rows(
        im,
        5,
        2,
        [
            "......###.",
            ".....####.",
            "....####..",
            "...###....",
            "..########",
            ".....####.",
            "....####..",
            "...###....",
            "..####....",
            ".###......",
            ".##.......",
        ],
        {"#": WHITE},
    )
    return im


def draw_dash() -> Image.Image:
    im = blank(24)
    stamp_chevron_right(im, 2, 5, WHITE, 3, 13)
    stamp_chevron_right(im, 10, 5, WHITE, 3, 13)
    return im


def draw_jump() -> Image.Image:
    im = blank(24)
    stamp_chevron_up(im, 5, 1, WHITE, 3, 13)
    stamp_chevron_up(im, 5, 8, WHITE, 3, 13)
    return im


def draw_clone() -> Image.Image:
    im = blank(24)
    hood = [
        "...##...",
        "..####..",
        ".######.",
        ".######.",
        "########",
        "########",
        ".##..##.",
        "..#..#..",
    ]
    pal = {"#": WHITE}
    stamp_rows(im, 2, 6, hood, pal)
    stamp_rows(im, 9, 8, hood, pal)
    return im


def draw_talk() -> Image.Image:
    im = blank(24)
    for y in range(5, 16):
        for x in range(4, 20):
            if (x, y) in ((4, 5), (19, 5), (4, 15), (19, 15)):
                continue
            put(im, x, y, WHITE)
    put(im, 7, 16, WHITE)
    put(im, 8, 17, WHITE)
    put(im, 9, 16, WHITE)
    for x in (8, 12, 16):
        put(im, x, 9, INK)
        put(im, x + 1, 9, INK)
        put(im, x, 10, INK)
    return im


def fit_head(src: Path, box: tuple[int, int, int, int], out_size: int = 32) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    crop = im.crop(box)
    px = crop.load()
    w, h = crop.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 200:
                px[x, y] = (0, 0, 0, 0)
    choke_light_edge(crop)
    inner = out_size - 4
    scaled = crop.resize((inner, inner), Image.NEAREST)
    canvas = blank(out_size)
    ox = (out_size - inner) // 2
    canvas.paste(scaled, (ox, ox), scaled)
    choke_light_edge(canvas)
    grow_outline(canvas)
    return canvas


def save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    print("wrote", path.relative_to(ROOT), im.size)


def preview(im: Image.Image, name: str) -> None:
    bg = Image.new("RGBA", (im.width * 4, im.height * 4), (26, 31, 41, 255))
    bg.alpha_composite(scale_nn(im, 4))
    out = Path("/tmp/qa-icons") / name
    out.parent.mkdir(exist_ok=True)
    bg.save(out)


def stats(path: Path) -> str:
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    nw = wedge = part = plate = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if 0 < a < 250:
                part += 1
            if a >= 250 and r < 18 and g < 18 and b < 18 and (x, y) != (w // 2, h // 2):
                # dark outline is expected; plate = dark fill covering most of canvas
                pass
            if a >= 200 and min(r, g, b) >= 230:
                nw += 1
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                        wedge += 1
                        break
    cx, cy = w // 2, h // 2
    return f"{path.name:24} {w}x{h} purewhite={nw:3} wedge={wedge:3} part={part:3} center={px[cx, cy]}"


def main() -> None:
    sword = scale_nn(center_opaque(draw_crosshair()), 3)
    daggers = scale_nn(center_opaque(draw_daggers()), 3)
    skill = scale_nn(center_opaque(draw_skill()), 2)
    dash = scale_nn(center_opaque(draw_dash()), 2)
    jump = scale_nn(center_opaque(draw_jump()), 2)
    talk = scale_nn(center_opaque(draw_talk()), 2)
    knight = fit_head(HERO / "unarmed-idle.png", (84, 103, 172, 176))
    assassin = fit_head(HERO / "assassin.png", (150, 171, 246, 258))

    save(sword, UI / "attack.png")
    save(daggers, UI / "attack-daggers.png")
    save(skill, UI / "dash.png")
    save(skill, UI / "skill-clone.png")
    save(dash, PICKUPS / "dash.png")
    save(jump, UI / "action-jump-v2.png")
    save(talk, UI / "action-talk-v2.png")
    save(knight, UI / "portrait-knight.png")
    save(assassin, UI / "portrait-assassin.png")

    preview(sword, "attack-4x.png")
    preview(skill, "skill-4x.png")
    preview(dash, "dash-4x.png")
    preview(jump, "jump-4x.png")
    preview(talk, "talk-4x.png")
    preview(knight, "knight-4x.png")
    preview(assassin, "assassin-4x.png")

    for p in (
        UI / "attack.png",
        UI / "attack-daggers.png",
        UI / "dash.png",
        UI / "action-jump-v2.png",
        UI / "skill-clone.png",
        UI / "action-talk-v2.png",
        UI / "portrait-knight.png",
        UI / "portrait-assassin.png",
    ):
        print(stats(p))


if __name__ == "__main__":
    main()
