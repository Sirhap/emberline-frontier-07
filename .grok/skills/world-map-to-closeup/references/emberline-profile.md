# Emberline Frontier Project Profile

Read this file for 余烬防线：前线 07 / Emberline Frontier in this repo. These decisions override generic examples in the main skill and override `internet-world-profile.md`. Numbers and room geometry come from `scripts/main.gd`, `scripts/shop_pen.gd`, and `scripts/home_room.gd`. Revise this profile only when those sources change.

This game is already a player-scale dungeon, not an overview-map product. A “close-up” here is a playable room (combat, shop, corridor, home hub) that matches the existing Soul Knight dungeon look. Do not invent a world map, a second campaign map, or a new tileset language.

## Reference priority

1. Live battlefield / room screenshots and `tools/capture_*.gd` frames.
2. `assets/generated/grid-battlefield-v6.png` as the brick atlas.
3. User-supplied Soul Knight screenshots as visual spec, not as floor textures.
4. Character sprites (`ember_hero`, `assassin`) for footprint and jump leftover (`JUMP_HEIGHT = 32`).

Ignore HUD, virtual sticks, developer overlay, captions, and watermarks.

## Locked camera and scale

- Engine: Godot 4.7 Compatibility. Viewport **1280×720**.
- Camera: screen-aligned orthographic follow-cam. World axes match the screen. Not isometric, not side-scroller, not cinematic.
- Combat zoom is near 1.0 inside `COMBAT_ROOM`; road zoom uses `CAMERA_ROAD_ZOOM = 2.05`. Clamp to `FLOOR_BOUNDS`.
- Movement: eight-direction WASD / stick. Hero collider `HERO_BODY_RADIUS = 16`. NPC `NPC_BODY_RADIUS = 20`.
- Placement cell: `CELL_SIZE = 48`.
- Painted brick: atlas 64×64 on `grid-battlefield-v6` (1536×1024), scaled with `TILE_W = 1280/1536*64`, `TILE_H = 720/1024*64`. Grout phase is `(FLOOR_GRID_OX, FLOOR_GRID_OY)`, not `(0, 0)`. Combat-band paint period is ~67 atlas px.
- Filtering: nearest-neighbor. No mipmaps, no linear blur on tiles or sprites.

Reject: isometric diamonds, frontal storefront elevation, side-scrolling platforms, world-map zoom-out, `draw_rect` color blocks, cyan debug frames, gray slab corridors, and pasting a whole reference screenshot as a floor.

## Locked visual language

Rooms must look like the same dungeon as the battlefield:

- Floor: wrap / blit bricks from `grid-battlefield-v6.png`. Do not invent a second ground material for shop rooms.
- Walls: gold-edged stone (`wall-h` / `wall-v`).
- Doors: holes in the wall with gold railing openings; floor tiles continue through the mouth. No extra hallway stub between combat and north/south rooms.
- Portals: nested in wall holes. Inactive = sealed stone. Interior of an open hole is void, not floor brick.
- Home hub is a separate visual: `assets/generated/home/floor-room.png` (+ day variant). Furniture from `office-sheet.png` slices plus `station-pack` desk/coffee, placed to match `layout-ref`. Never recut layout-ref, never farm shelves/statues/sofas, never stamp the whole layout-ref as the floor.

Interactive NPCs, shop shelves, towers, pads, pickups, and HUD stay as separate nodes. Do not bake them into the floor.

## Current rooms (do not invent new maps)

| Region | Source | Purpose |
|---|---|---|
| `combat` | `COMBAT_ROOM` in `main.gd` | Core, pads, conveyor rewards, fight |
| `top_room` | `TOP_ROOM` | Mechanic + merchant |
| `bottom_room` | `BOTTOM_ROOM` | Summoner + officer + trainer |
| `east_road` / portal mouths | `ROAD_EAST`, spawn holes | Spawn portals, not extra biomes |
| `home_hub` | `HomeHub` + `HomeRoom` | Character select, codex, start run |

Topology that must survive: north shop ↔ combat ↔ south shop through gold-rail mouths; east expansion and portal holes; core west `HOME_HALL` remains walkable. Do not close the whole map path.

Frozen: no new weapon IDs, no extra campaign maps, no sealing the whole path, no combat hero swap on the production path.

## Engine delivery in this repo

Do not create a parallel `regions/` tree. Use existing paths:

```text
assets/generated/grid-battlefield-v6.png
assets/generated/fx/          # walls, door/mouth frames, gold rails
assets/generated/home/        # hub floor + office furniture
scripts/main.gd               # room rects, camera, placement
scripts/shop_pen.gd           # brick blit, walls, mouths
scripts/home_room.gd          # hub assembly
tools/capture_*.gd            # player-view proof
tests/smoke_test.gd
```

Import: lossless, nearest, no extra compression. Pivot sprites at the foot. Keep jump leftover in character canvases.

## Verification

Functional pass is not visual pass.

1. `godot --headless --path . --script tests/smoke_test.gd`
2. Capture a player-view frame of the changed room (`godot --path .` or the matching `tools/capture_*.gd`).
3. Ask: can this frame sit next to the battlefield bricks and a Soul Knight screenshot without looking like a debug layer?

If no, keep iterating. Coordinate-correct walkable rooms that look like panels have not shipped.

## Prompt camera clause

> Screen-aligned orthographic top-down Soul Knight dungeon room; yaw 0°; 1280×720; gold-edged stone walls; floor tiled from the same battlefield bricks; door is a hole in the wall with gold-rail opening; eight-direction walk; no isometric rotation, no side-scroller, no world-map crop.

## Prompt pixel clause

> Native pixel dungeon tiles matching `grid-battlefield-v6`; nearest-neighbor; integer-aligned grout; no antialiasing, no painted-filter pixels, no HUD, no baked NPCs or shop icons.
