# Godot Delivery

Read this reference when the target is Godot. Inspect the project and confirm the Godot version before choosing version-specific node names, TileMap APIs, importer settings, or scripts.

## Suggested project organization

Adapt names to the existing project instead of creating a parallel convention without need. For Emberline Frontier in this repo, use the paths in [emberline-profile.md](emberline-profile.md) and do not create a `regions/` tree.

Suggested layout only when the project has no established map-asset convention:

```text
regions/<region_id>/
  source/
  concepts/
  art/
    terrain/
    structures/
    props/
    foreground/
    entities/
    effects/
  data/
    region_spec.*
    asset_manifest.*
    exits.*
  scenes/
  scripts/
```

Shared biome/world assets should live outside a single region folder and be referenced rather than duplicated.

## Scene responsibilities

Keep these responsibilities separable even if the project’s exact node structure differs:

| Responsibility | Content |
|---|---|
| Ground | terrain, paths, borders, decals |
| Structures | building bodies and static blockers |
| Props | reusable placed objects |
| Entities | NPCs, pets, enemies, pickups |
| Collision/navigation | movement blockers and navigation data |
| Foreground | player-covering canopies, roofs, arches |
| Effects | particles, animated water, lights |
| Exits | transition triggers plus destination/spawn IDs |

Do not rely on the painted concept as one collision surface. Build collision from gameplay intent.

## Import and rendering

- Use lossless import for pixel assets.
- Use the project’s established nearest/linear filtering policy; pixel art normally requires nearest filtering and integer-aware display scaling.
- Preserve native source resolution and apply intended scale consistently.
- Disable unwanted compression, mipmapping, or filtering that introduces halos or blurred pixels.
- Place Y-sorted entities by their foot/ground pivot rather than sprite center.
- Split foreground components when the player must pass behind them.
- Test camera zoom at target window resolutions for shimmer, seams, and half-pixel placement.

## Collision and navigation

- Give structures collision around their ground footprint, not automatically around the full visible roof.
- Keep doors/passages clear at the character collision width.
- Separate static collision, interaction triggers, scene exits, and damage zones.
- Generate or paint navigation only after collisions and passable routes are finalized.
- Validate narrow paths with the actual character collider and navigation agent settings.
- Ensure occluding artwork does not falsely imply a wall where movement is allowed.

## Scene transitions

Each exit should record:

```yaml
exit_id: stable ID in the current region
destination_region: target region ID
destination_spawn: target spawn ID
entry_direction: logical direction or door relationship
transition_style: walk | fade | door | custom
```

Neighboring regions must contain a reciprocal or intentionally one-way mapping. Spawn points should place the character outside the return trigger to prevent transition loops.

## Verification run

Test at minimum:

1. player spawn and camera framing;
2. every main route and doorway with the actual collider;
3. all exits and reciprocal destinations;
4. draw order while moving behind buildings, props, and foreground pieces;
5. interaction reach and prompt placement;
6. texture seams and filtering at target zoom;
7. navigation around corners and narrow gaps;
8. performance with representative entities and effects.

If implementation files are requested, run the project’s existing validation or headless test commands and preserve unrelated user changes. In this repo that is `godot --headless --path . --script tests/smoke_test.gd`, plus a player-view capture when rooms or tiles changed.
