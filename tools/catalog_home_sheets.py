#!/usr/bin/env python3
"""Slice every home furniture sheet into named cuts. Farm pack is indexed but not cut."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
HOME = ROOT / "assets/generated/home"
CATALOG = HOME / "catalog"

SHEETS = [
    {
        "id": "office",
        "file": "office-sheet.png",
        "use": "office meme furniture: neon, sofa, whiteboard, mascots",
        "cut": True,
    },
    {
        "id": "station",
        "file": "station-pack.png",
        "use": "coder desk, workbench, coffee station, plant",
        "cut": True,
    },
    {
        "id": "tech",
        "file": "tech-pack.png",
        "use": "empty desk, vending, lanterns, pets, lights, standee",
        "cut": True,
    },
    {
        "id": "furniture",
        "file": "furniture-pack.png",
        "use": "farm furniture — do not stamp in the home",
        "cut": False,
    },
    {
        "id": "internet-world",
        "file": "internet-world.png",
        "use": "互联网大陆 overview map — reference only, not the home floor",
        "cut": False,
    },
]

# Known large pieces. Applied after auto-segment if a component covers the box center.
NAMED = {
    "station": [
        {"name": "coder-desk", "center": (0.38, 0.55)},
        {"name": "workbench", "center": (0.78, 0.28)},
        {"name": "coffee", "center": (0.78, 0.68)},
        {"name": "plant", "center": (0.48, 0.18)},
    ],
    "tech": [
        {"name": "empty-desk", "center": (0.18, 0.16)},
        {"name": "cow-plush", "center": (0.42, 0.14)},
        {"name": "rubber-chicken", "center": (0.55, 0.14)},
        {"name": "workbench", "center": (0.82, 0.16)},
        {"name": "coder-desk", "center": (0.22, 0.42)},
        {"name": "coffee", "center": (0.48, 0.42)},
        {"name": "vending", "center": (0.68, 0.42)},
        {"name": "standee", "center": (0.88, 0.42)},
    ],
    "office": [
        {"name": "coder-desk", "center": (0.09, 0.62)},
        {"name": "gaming-chair", "center": (0.23, 0.57)},
        {"name": "whiteboard", "center": (0.32, 0.56)},
        {"name": "tv-set", "center": (0.44, 0.58)},
        {"name": "beanbag", "center": (0.56, 0.55)},
        {"name": "sofa-table", "center": (0.66, 0.58)},
        {"name": "water-cooler", "center": (0.80, 0.58)},
        {"name": "bookshelf", "center": (0.87, 0.58)},
        {"name": "snack-vending", "center": (0.94, 0.57)},
        {"name": "coder-desk-small", "center": (0.56, 0.08)},
    ],
}


def is_sheet_bg(r: int, g: int, b: int) -> bool:
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luma < 14.0 and max(r, g, b) < 24


def knockout_border(img: Image.Image) -> Image.Image:
    img = img.copy()
    pix = img.load()
    w, h = img.size
    seen = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        r, g, b, _a = pix[x, y]
        if seen[y][x] or not is_sheet_bg(r, g, b):
            return
        seen[y][x] = True
        q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)
    while q:
        x, y = q.popleft()
        pix[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                push(nx, ny)
    return img


def tight(img: Image.Image, pad: int = 1) -> Image.Image:
    pix = img.load()
    w, h = img.size
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if pix[x, y][3] > 18:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x < 0:
        return img
    min_x = max(0, min_x - pad)
    min_y = max(0, min_y - pad)
    max_x = min(w - 1, max_x + pad)
    max_y = min(h - 1, max_y + pad)
    return img.crop((min_x, min_y, max_x + 1, max_y + 1))


def components(img: Image.Image) -> list[tuple[int, int, int, int, int]]:
    pix = img.load()
    w, h = img.size
    seen = [[False] * w for _ in range(h)]
    comps: list[tuple[int, int, int, int, int]] = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or pix[x, y][3] <= 18:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            seen[y][x] = True
            minx = maxx = x
            miny = maxy = y
            n = 0
            while q:
                cx, cy = q.popleft()
                n += 1
                minx = min(minx, cx)
                maxx = max(maxx, cx)
                miny = min(miny, cy)
                maxy = max(maxy, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and pix[nx, ny][3] > 18:
                        seen[ny][nx] = True
                        q.append((nx, ny))
            bw = maxx - minx + 1
            bh = maxy - miny + 1
            if n >= 80 and bw >= 8 and bh >= 8:
                comps.append((minx, miny, bw, bh, n))
    comps.sort(key=lambda c: -c[4])
    return comps


def name_for(sheet_id: str, box: tuple[int, int, int, int], sheet_size: tuple[int, int]) -> str | None:
    x, y, bw, bh = box
    cx = (x + bw * 0.5) / float(sheet_size[0])
    cy = (y + bh * 0.5) / float(sheet_size[1])
    best = None
    best_d = 0.045
    for spec in NAMED.get(sheet_id, []):
        dx = cx - spec["center"][0]
        dy = cy - spec["center"][1]
        d = dx * dx + dy * dy
        if d < best_d:
            best_d = d
            best = spec["name"]
    return best


def contact_sheet(cuts: list[tuple[str, Image.Image]]) -> Image.Image:
    cell = 128
    cols = 10
    rows = max(1, (len(cuts) + cols - 1) // cols)
    out = Image.new("RGBA", (cols * cell, rows * cell), (12, 14, 20, 255))
    draw = ImageDraw.Draw(out)
    for i, (label, img) in enumerate(cuts):
        bw, bh = img.size
        scale = min((cell - 22) / max(1, bw), (cell - 22) / max(1, bh), 4.0)
        nw = max(1, int(bw * scale))
        nh = max(1, int(bh * scale))
        scaled = img.resize((nw, nh), Image.NEAREST)
        cx = (i % cols) * cell
        cy = (i // cols) * cell
        draw.rectangle([cx, cy, cx + cell - 1, cy + cell - 1], outline=(40, 44, 56, 255))
        draw.text((cx + 3, cy + 2), label[:18], fill=(255, 210, 80, 255))
        out.alpha_composite(scaled, (cx + (cell - nw) // 2, cy + 16 + (cell - 18 - nh) // 2))
    return out


def catalog_sheet(spec: dict) -> dict:
    src = HOME / spec["file"]
    info: dict = {
        "id": spec["id"],
        "file": spec["file"],
        "use": spec["use"],
        "exists": src.exists(),
        "cut": spec["cut"],
    }
    if not src.exists():
        return info
    raw = Image.open(src).convert("RGBA")
    info["size"] = list(raw.size)
    if not spec["cut"]:
        info["cuts"] = 0
        return info

    extrema = raw.getchannel("A").getextrema() if "A" in raw.getbands() else (255, 255)
    keyed = raw if extrema[0] == 0 and extrema[1] > 0 else knockout_border(raw)
    comps = components(keyed)
    dest = CATALOG / spec["id"]
    dest.mkdir(parents=True, exist_ok=True)
    used_names: set[str] = set()
    entries: list[dict] = []
    previews: list[tuple[str, Image.Image]] = []
    for i, (x, y, bw, bh, n) in enumerate(comps):
        crop = tight(keyed.crop((x, y, x + bw, y + bh)))
        named = name_for(spec["id"], (x, y, bw, bh), raw.size)
        if named and named in used_names:
            named = None
        if named:
            used_names.add(named)
            stem = named
        else:
            stem = f"{i:03d}_{bw}x{bh}"
        path = dest / f"{stem}.png"
        crop.save(path)
        entry = {
            "name": stem,
            "file": f"catalog/{spec['id']}/{stem}.png",
            "box": [x, y, bw, bh],
            "pixels": n,
            "size": list(crop.size),
        }
        entries.append(entry)
        previews.append((stem if named else f"{i:03d}", crop))
        print("CUT", spec["id"], stem, crop.size)

    (dest / "cuts.json").write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding="utf-8")
    contact_sheet(previews).save(CATALOG / f"contact-{spec['id']}.png")
    info["cuts"] = len(entries)
    info["named"] = sorted(used_names)
    return info


def main() -> None:
    CATALOG.mkdir(parents=True, exist_ok=True)
    index = {"sheets": [catalog_sheet(spec) for spec in SHEETS]}
    (CATALOG / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
    print("CATALOG", CATALOG)
    for sheet in index["sheets"]:
        print(sheet["id"], "cuts", sheet.get("cuts", 0), "named", sheet.get("named", []))


if __name__ == "__main__":
    main()
