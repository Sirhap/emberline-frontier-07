# Asset Production

Read this reference when extracting, reconstructing, or generating reusable scene assets.

## Choose the truthful production class

### Extract

Use when the source contains sufficient clean pixels and the requested deliverable is literal isolation. Preserve the visible asset; remove only the surrounding background. Check halos, lost outlines, semitransparent shadow edges, and missing pixels.

### Reconstruct

Use when the source item is small, occluded, overlapped, perspective-fused, or lacks hidden sides needed for independent placement. Match the approved master’s design and clearly identify the result as reconstructed.

### Generate

Use for new variations or missing scene components. Generate against the locked style-and-scale specification and compare the result to approved anchor assets.

Do not use generative inpainting when the user requires literal pixel preservation and clean source pixels are available.

## Layer and asset taxonomy

- **Ground:** base terrain, transitions, paths, borders, decals, damage/variation tiles.
- **Structures:** building body, roof/overhang, doors, windows, signs, attached equipment.
- **Props:** vegetation, lights, benches, bins, crates, terminals, fences, vending machines.
- **Foreground:** tree canopies, roof edges, banners, archways, and other player-covering pieces.
- **Entities:** NPCs, pets, enemies, pickups, vehicles, moving machines.
- **Effects:** smoke, lights, particles, water animation, interaction highlights.
- **Collision helpers:** optional invisible polygons or metadata, never painted into the visual.

Split an item when parts require different draw order, state, animation, collision, or interaction. Avoid fragmentation that creates no gameplay or reuse benefit.

## Production order

1. Create or verify ground materials and terrain transitions.
2. Produce the primary landmark structure in logical layers.
3. Produce path-defining blockers and foreground occluders.
4. Produce interactive props and doors.
5. Produce common decorative props and variations.
6. Produce entities and effects separately.
7. Add rare decals only after the navigation space remains readable.

Use small batches containing related assets. Compare each batch against the same style anchors before moving on.

## Raster requirements

- Transparent assets use true alpha and contain no checkerboard, matte rectangle, or unrelated ground patch.
- Preserve intentional contact shadows separately when they need independent placement; otherwise document that the shadow is baked.
- Keep a consistent native pixel scale. Do not mix high-resolution antialiased art with hard pixel assets without an explicit downsampling pass.
- Use integer-aligned crop bounds and consistent padding when the art is pixel-based.
- Define the pivot or foot point. Buildings commonly use a ground-contact anchor; entities use the point where their feet meet the ground.
- Keep sufficient canvas padding for effects and animations, but avoid arbitrary oversized empty margins.
- For seamless terrain, verify all intended neighbor edges, not only a single repeated tile.
- Keep editable source/layers when reconstruction or compositing was required.

## Asset manifest

Maintain one row or object per asset with at least:

```yaml
asset_id: region_or_shared/category/name/variant
file: relative/path.png
source_class: extract | reconstruct | generate
source_reference: source image and visible location, when applicable
native_size_px: [width, height]
pivot_px: [x, y]
layer: ground | structure | prop | foreground | entity | effect
collision: none | rectangle | polygon | custom
interaction: none | door | talk | pickup | trigger | custom
animation: none or clip/frame description
shadow: baked | separate | none
shared_scope: region | biome | world
notes: limitations or placement rules
```

## Consistency checks

Compare new assets to approved anchors for:

- pixels per character height;
- outline thickness and color;
- highlight and shadow ramps;
- light direction and shadow length;
- camera-visible top/front/side proportions;
- saturation and local contrast;
- prop density and detail frequency.

If an asset only looks correct at a different zoom, it is not consistent.
