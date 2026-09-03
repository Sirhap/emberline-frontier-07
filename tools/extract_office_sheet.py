#!/usr/bin/env python3
"""Slice office-sheet.png by alpha. Never recut layout-ref. Never overwrite the source PNG."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
HOME = ROOT / "assets/generated/home"
OFFICE = HOME / "office"
SHEET_PNG = HOME / "office-sheet.png"
PREVIEW_DIR = Path("/tmp/home-office-preview")
BOX_REF = (1024, 682)

# Room coords match layout-ref scaled to 1280x720. Never recut layout-ref.
PACK_BOTH = {
    "CoderDesk": {"file": "desk-coder.png", "x": 635.0, "y": 365.0, "h": 210.0},
}
PACK_NIGHT = {
    "Plant": {"file": "plant.png", "x": 325.0, "y": 105.0, "h": 72.0},
    "Fridge": {"file": "vending.png", "x": 815.0, "y": 115.0, "h": 140.0},
    "Coffee": {"file": "coffee.png", "x": 1125.0, "y": 385.0, "h": 118.0},
}
PACK_DAY = {
    "DayPlant": {"file": "plant-day.png", "x": 325.0, "y": 105.0, "h": 80.0},
    "Workbench": {"file": "workbench.png", "x": 1125.0, "y": 385.0, "h": 150.0},
}

# Manual boxes on the 1024x682 sheet. layer: night | day | both (default both).
CUTS = [
    {"name": "OvertimeSign", "file": "office/OvertimeSign.png", "box": (32, 520, 43, 62), "x": 108.0, "y": 110.0, "h": 96.0, "layer": "night"},
    {"name": "SlackScreen", "file": "office/SlackScreen.png", "box": (114, 521, 94, 52), "x": 228.0, "y": 92.0, "h": 70.0, "layer": "night"},
    {"name": "Plant", "file": "plant.png", "box": (530, 549, 50, 52), "x": 325.0, "y": 105.0, "h": 72.0, "pack": True, "layer": "night"},
    {"name": "Trash", "file": "office/Trash.png", "box": (302, 440, 40, 60), "x": 385.0, "y": 155.0, "h": 70.0},
    {"name": "Fridge", "file": "vending.png", "box": (453, 236, 57, 93), "x": 815.0, "y": 115.0, "h": 140.0, "pack": True, "layer": "night"},
    {"name": "Bookshelf", "file": "office/Bookshelf.png", "box": (858, 346, 56, 97), "x": 905.0, "y": 130.0, "h": 150.0},
    {"name": "Monument", "file": "office/Monument.png", "box": (294, 335, 72, 91), "x": 1015.0, "y": 78.0, "h": 148.0},
    {"name": "WaterCooler", "file": "office/WaterCooler.png", "box": (795, 344, 51, 110), "x": 1198.0, "y": 155.0, "h": 140.0},
    {"name": "Bestiary", "file": "office/Bestiary.png", "box": (244, 516, 46, 74), "x": 175.0, "y": 398.0, "h": 118.0},
    {"name": "Panda", "file": "office/Panda.png", "box": (118, 244, 64, 80), "x": 185.0, "y": 255.0, "h": 112.0, "flip": True, "layer": "night"},
    {"name": "Bull", "file": "office/Bull.png", "box": (18, 127, 64, 94), "x": 175.0, "y": 495.0, "h": 128.0, "layer": "night"},
    {"name": "Chicken", "file": "office/Chicken.png", "box": (709, 231, 65, 92), "x": 850.0, "y": 400.0, "h": 124.0, "flip": True, "layer": "night"},
    {"name": "CoffeeTable", "file": "office/CoffeeTable.png", "box": (563, 418, 148, 50), "x": 205.0, "y": 585.0, "h": 78.0},
    {"name": "Soda", "file": "office/Soda.png", "box": (514, 470, 26, 44), "x": 200.0, "y": 548.0, "h": 48.0},
    {"name": "PetBed", "file": "office/PetBed.png", "box": (536, 345, 81, 67), "x": 305.0, "y": 625.0, "h": 96.0},
    {"name": "Controller", "file": "office/Controller.png", "box": (574, 512, 38, 28), "x": 325.0, "y": 605.0, "h": 28.0},
    {"name": "BookStack", "file": "office/BookStack.png", "box": (371, 461, 37, 43), "x": 455.0, "y": 605.0, "h": 58.0},
    {"name": "Wrench", "file": "office/Wrench.png", "box": (690, 511, 31, 33), "x": 575.0, "y": 545.0, "h": 36.0},
    {"name": "FloorPlant", "file": "office/FloorPlant.png", "box": (530, 549, 50, 52), "x": 655.0, "y": 565.0, "h": 72.0, "layer": "night"},
    {"name": "BallBox", "file": "office/BallBox.png", "box": (707, 566, 38, 38), "x": 735.0, "y": 585.0, "h": 52.0},
    {"name": "Boxes", "file": "office/Boxes.png", "box": (829, 477, 71, 64), "x": 800.0, "y": 595.0, "h": 78.0},
    {"name": "WetFloor", "file": "office/WetFloor.png", "box": (959, 477, 43, 58), "x": 880.0, "y": 575.0, "h": 78.0},
    {"name": "Skateboard", "file": "office/Skateboard.png", "box": (568, 488, 72, 22), "x": 990.0, "y": 615.0, "h": 28.0},
    {"name": "Dumbbell", "file": "office/Dumbbell.png", "box": (887, 554, 52, 26), "x": 1055.0, "y": 555.0, "h": 28.0},
    {"name": "Vacuum", "file": "office/Vacuum.png", "box": (953, 558, 57, 40), "x": 1160.0, "y": 595.0, "h": 48.0},
    {"name": "Drone", "file": "office/Drone.png", "box": (862, 587, 72, 41), "x": 1095.0, "y": 650.0, "h": 42.0},
    {"name": "CodeSign", "file": "office/CodeSign.png", "box": (305, 524, 62, 51), "x": 108.0, "y": 110.0, "h": 78.0, "layer": "day"},
    {"name": "CodeWindow", "file": "office/CodeWindow.png", "box": (390, 521, 111, 64), "x": 228.0, "y": 92.0, "h": 86.0, "layer": "day"},
    {"name": "DayFridge", "file": "office/SnackVending.png", "box": (924, 330, 84, 109), "x": 815.0, "y": 115.0, "h": 140.0, "layer": "day"},
    {"name": "DayPanda", "file": "office/DayPanda.png", "box": (18, 239, 69, 89), "x": 185.0, "y": 255.0, "h": 112.0, "flip": True, "layer": "day"},
    {"name": "DayBull", "file": "office/DayBull.png", "box": (192, 130, 89, 90), "x": 175.0, "y": 495.0, "h": 128.0, "flip": True, "layer": "day"},
    {"name": "DayChicken", "file": "office/DayChicken.png", "box": (804, 236, 63, 88), "x": 850.0, "y": 400.0, "h": 124.0, "layer": "day"},
    {"name": "DayFloorPlant", "file": "office/DayFloorPlant.png", "box": (778, 480, 38, 35), "x": 655.0, "y": 565.0, "h": 52.0, "layer": "day"},
    {"name": "Pizza", "file": "office/Pizza.png", "box": (632, 556, 60, 56), "x": 500.0, "y": 520.0, "h": 68.0, "layer": "day"},
    {"name": "Doraemon", "file": "office/Doraemon.png", "box": (524, 150, 72, 62), "x": 360.0, "y": 500.0, "h": 72.0, "layer": "day"},
    {"name": "Chopper", "file": "office/Chopper.png", "box": (867, 139, 79, 76), "x": 440.0, "y": 220.0, "h": 88.0, "layer": "day"},
]


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


def scale_box(box: tuple[int, int, int, int], size: tuple[int, int]) -> tuple[int, int, int, int]:
    x, y, bw, bh = box
    sx = size[0] / float(BOX_REF[0])
    sy = size[1] / float(BOX_REF[1])
    nx = int(round(x * sx))
    ny = int(round(y * sy))
    nw = max(1, int(round(bw * sx)))
    nh = max(1, int(round(bh * sy)))
    return (nx, ny, nw, nh)


def sheet_has_alpha(img: Image.Image) -> bool:
    if "A" not in img.getbands():
        return False
    lo, hi = img.getchannel("A").getextrema()
    return lo == 0 and hi > 0


def drop_low_alpha(img: Image.Image, thresh: int = 40) -> Image.Image:
    img = img.copy()
    pix = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a < thresh:
                pix[x, y] = (0, 0, 0, 0)
    return img


def extract(sheet: Image.Image, box: tuple[int, int, int, int], *, keyed: bool) -> Image.Image:
    x, y, bw, bh = box
    crop = sheet.crop((x, y, x + bw, y + bh)).convert("RGBA")
    if keyed:
        return tight(drop_low_alpha(crop))
    return tight(knockout_border(crop))


def largest_alpha_sprite(img: Image.Image) -> Image.Image:
    pix = img.load()
    w, h = img.size
    seen = [[False] * w for _ in range(h)]
    best: tuple[int, int, int, int, int] | None = None
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
            if best is None or n > best[0]:
                best = (n, minx, miny, maxx - minx + 1, maxy - miny + 1)
    if best is None:
        return img
    _n, x, y, bw, bh = best
    return tight(img.crop((x, y, x + bw, y + bh)))


def extract_station_coder_desk() -> Image.Image:
    pack = Image.open(HOME / "station-pack.png").convert("RGBA")
    desk = largest_alpha_sprite(pack)
    dest = HOME / "desk-coder.png"
    desk.save(dest)
    print("STATION DESK", desk.size, "->", dest.relative_to(ROOT))
    return desk


def extract_station_coffee() -> Image.Image:
    pack = Image.open(HOME / "station-pack.png").convert("RGBA")
    region = pack.crop((1280, 430, 1560, 650))
    coffee = largest_alpha_sprite(region)
    dest = HOME / "coffee.png"
    coffee.save(dest)
    print("STATION COFFEE", coffee.size, "->", dest.relative_to(ROOT))
    return coffee


def extract_station_workbench() -> Image.Image:
    pack = Image.open(HOME / "station-pack.png").convert("RGBA")
    region = pack.crop((1260, 70, 1620, 300))
    bench = largest_alpha_sprite(region)
    dest = HOME / "workbench.png"
    bench.save(dest)
    print("STATION WORKBENCH", bench.size, "->", dest.relative_to(ROOT))
    return bench


def extract_station_day_plant() -> Image.Image:
    pack = Image.open(HOME / "station-pack.png").convert("RGBA")
    region = pack.crop((960, 90, 1060, 210))
    plant = largest_alpha_sprite(region)
    dest = HOME / "plant-day.png"
    plant.save(dest)
    print("STATION DAY PLANT", plant.size, "->", dest.relative_to(ROOT))
    return plant


def paste_centered(dst: Image.Image, src: Image.Image, cx: float, cy: float, target_h: float, *, flip: bool = False) -> None:
    if src.size[1] <= 0:
        return
    scale = target_h / float(src.size[1])
    nw = max(1, int(round(src.size[0] * scale)))
    nh = max(1, int(round(src.size[1] * scale)))
    scaled = src.resize((nw, nh), Image.NEAREST)
    if flip:
        scaled = scaled.transpose(Image.FLIP_LEFT_RIGHT)
    x = int(round(cx - nw / 2.0))
    y = int(round(cy - nh / 2.0))
    dst.alpha_composite(scaled, (x, y))


def main() -> None:
    HOME.mkdir(parents=True, exist_ok=True)
    OFFICE.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SHEET_PNG).convert("RGBA")
    keyed = sheet_has_alpha(sheet)
    print("SHEET", sheet.size, "alpha" if keyed else "knockout", SHEET_PNG)

    desk = extract_station_coder_desk()
    coffee = extract_station_coffee()
    workbench = extract_station_workbench()
    day_plant = extract_station_day_plant()
    pack_imgs = {
        "CoderDesk": desk,
        "Coffee": coffee,
        "Workbench": workbench,
        "DayPlant": day_plant,
    }

    extracted: dict[str, Image.Image] = {}
    manifest: list[dict] = []
    for cut in CUTS:
        img = extract(sheet, scale_box(cut["box"], sheet.size), keyed=keyed)
        dest = HOME / cut["file"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        img.save(dest)
        extracted[cut["name"]] = img
        print("CUT", cut["name"], img.size, "->", dest.relative_to(ROOT))
        if cut.get("pack"):
            pack_imgs[cut["name"]] = img
            continue
        entry = {
            "name": cut["name"],
            "file": cut["file"],
            "x": cut["x"],
            "y": cut["y"],
            "h": cut["h"],
            "layer": cut.get("layer", "both"),
        }
        if cut.get("flip"):
            entry["flip"] = True
        manifest.append(entry)

    (HOME / "office-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")
    print("MANIFEST", len(manifest))

    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    for floor_name, out_name, want in (
        ("floor-room.png", "home-night.png", "night"),
        ("floor-room-day.png", "home-day.png", "day"),
    ):
        floor = Image.open(HOME / floor_name).convert("RGBA")
        if floor.size != (1280, 720):
            floor = floor.resize((1280, 720), Image.NEAREST)
        packs = dict(PACK_BOTH)
        packs.update(PACK_NIGHT if want == "night" else PACK_DAY)
        for name, spec in packs.items():
            paste_centered(floor, pack_imgs[name], spec["x"], spec["y"], spec["h"])
        for cut in CUTS:
            if cut.get("pack"):
                continue
            layer = cut.get("layer", "both")
            if layer not in ("both", want):
                continue
            paste_centered(
                floor,
                extracted[cut["name"]],
                cut["x"],
                cut["y"],
                cut["h"],
                flip=bool(cut.get("flip")),
            )
        floor.save(PREVIEW_DIR / out_name)
        print("PREVIEW", PREVIEW_DIR / out_name)

    contact_w = 1024
    contact = Image.new("RGBA", (contact_w, 900), (8, 10, 16, 255))
    x = 8
    y = 8
    row_h = 0
    for cut in CUTS:
        img = extracted[cut["name"]]
        preview = img.copy()
        if preview.size[1] < 80:
            s = 80.0 / float(max(1, preview.size[1]))
            preview = preview.resize((max(1, int(preview.size[0] * s)), 80), Image.NEAREST)
        if x + preview.size[0] + 8 > contact_w:
            x = 8
            y += row_h + 18
            row_h = 0
        contact.alpha_composite(preview, (x, y))
        x += preview.size[0] + 8
        row_h = max(row_h, preview.size[1])
    contact.save(PREVIEW_DIR / "contact.png")
    print("CONTACT", PREVIEW_DIR / "contact.png")


if __name__ == "__main__":
    main()
