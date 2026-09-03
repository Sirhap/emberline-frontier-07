# Close-up Planning

Read this reference when designing a close-up master or executing the full pipeline.

## Region translation model

Translate the selected world-map location through three layers:

1. **Identity:** biome, landmark, recognizable motifs, local story, and important neighboring regions.
2. **Topology:** entrances, exits, path connectivity, barriers, shoreline or cliff boundaries, and transition directions.
3. **Player-scale composition:** movement room, interaction space, encounter space, building clearance, camera framing, and occlusion.

Identity and topology should survive the translation. Exact overview-map distances generally should not: player-scale spacing is redesigned for legibility and play.

## Region brief template

Record only fields relevant to the scene:

```yaml
region_id: stable-machine-name
display_name: user-facing name
purpose: exploration | hub | shop | combat | transition | mixed
overview_anchor: where it sits on the world map
biome: dominant environment
landmarks:
  required: []
  optional: []
connections:
  - direction: north | east | south | west | interior | custom
    destination: neighboring region or interior
    form: road | gate | bridge | trail | door | shoreline
gameplay_spaces:
  walkable: []
  blocked: []
  interaction: []
  encounter: []
  quiet_space: []
separate_entities: []
foreground_occluders: []
provisional_decisions: []
```

Directions describe logical transition relationships, not necessarily strict screen coordinates when the game uses non-cardinal staging.

## Style-and-scale lock

Capture a single source of truth:

| Field | Decision |
|---|---|
| Projection | top-down, oblique top-down, side view, isometric, etc. |
| Camera | orthographic/perspective, fixed angle, framing rules |
| Yaw / axis alignment | screen-aligned, diagonal/isometric, or another measured orientation |
| Downward pitch | approximate angle plus visible-surface evidence |
| Surface ratio | ground versus facade/roof/side-wall visibility |
| Movement model | horizontal only, four-direction, eight-direction, free movement |
| Native scale | intended source-pixel resolution and display scale |
| Integer display scale | nearest-neighbor multiplier or non-pixel scaling rule |
| Character | native height, footprint, foot point |
| Movement unit | tile size or free-movement reference unit |
| Doors | clear opening relative to the character |
| Paths | minimum and typical walkable width |
| Buildings | small/medium/large footprint ranges |
| Pixel treatment | native pixel construction or painted treatment; filtering and antialiasing |
| Pixel clusters | intended coarse/fine cluster size and texture frequency |
| Outlines | color, width, and where outlines are omitted |
| Shade count | typical tones per material and use of gradients |
| Palette | saturation, contrast, biome accents |
| Lighting | direction, softness, shadow length, time of day |
| Density | clutter zones versus breathing room |

Do not select 32×32, 48×48, or another unit by habit. Infer scale from references or choose it based on character readability and expected camera zoom.

## Camera classification

Use visible evidence rather than style labels:

- **Screen-aligned high-angle top-down:** ground dominates; map axes align with the screen; building facades may face downward while the camera remains high overhead; movement commonly supports four or eight directions.
- **Isometric/diagonal:** map axes form diagonals or diamonds; multiple building side faces are prominent; horizontal yaw is typically rotated relative to the screen.
- **Frontal 2.5D:** facade dominates; ground depth is shallow; camera pitch is low to moderate even when a little roof is visible.
- **Side view/platformer:** navigation is primarily horizontal; ground reads as a baseline or platforms rather than a broad plane.

“Front-facing building” describes facade orientation, not camera elevation. “Landscape” or “横版” may describe the canvas and must not be treated as proof of side-view gameplay.

## Composition procedure

1. Mark the region boundary and logical exits from the overview.
2. Choose a player entry point and intended first read.
3. Place the primary landmark so the entrance is visible and reachable.
4. Draw the main traversal route, then secondary loops or dead ends.
5. Reserve open gameplay pockets before placing decoration.
6. Place blocking masses and ensure they explain the route visually.
7. Add interactive locations with approach space.
8. Add foreground occluders only where their layer behavior is understood.
9. Add props in clusters and leave intentional quiet areas.
10. Confirm that every exit can be implemented as a transition trigger.

## Image-generation brief

Build prompts from decisions rather than adjectives alone:

- **Source roles:** overview for identity/topology; close-up references for scale/camera/style; character for proportion only unless the character belongs in the output.
- **Scene:** selected region, landmark, biome, time, and intended gameplay.
- **Camera:** exact projection, fixed angle, framing, and absence of cinematic lens changes.
- **Geometry evidence:** yaw/axis alignment, approximate downward pitch, visible surfaces, ground ratio, and movement model.
- **Scale:** character-relative doors, paths, props, and open movement space.
- **Layout:** entrance, landmark, main route, exits, blocked boundaries, and foreground zones.
- **Surface:** pixel density, edges, palette, shadows, and texture frequency.
- **Native pixel rules:** source canvas or asset scale, integer upscale, nearest-neighbor filtering, outline width, shade count, and antialiasing prohibition when applicable.
- **Exclusions:** UI, watermark, stray text, unrequested characters, concept-art framing, impossible perspective, or baked interactive entities.

The prompt should describe a playable scene, not “zoom into this image.”

## World rollout

After the pilot region is approved:

1. Freeze the style-and-scale specification.
2. Build a shared catalog for terrain, vegetation, street furniture, signs, and common effects.
3. Give each region a small unique landmark set rather than regenerating everything.
4. Process regions in bounded batches and review consistency between batches.
5. Update the shared catalog when a genuinely reusable asset appears.
6. Maintain an exit table so neighboring scenes agree about where transitions lead.
