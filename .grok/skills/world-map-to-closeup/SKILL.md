---
name: world-map-to-closeup
description: Turn an overview or world map plus visual references into playable 2D close-up regions, reusable raster assets, and an engine-ready assembly plan. Use for requests to enter, enlarge, rebuild, split, or implement a map region at player scale; in this Emberline repo also use for dungeon rooms, shop halls, home hub, battlefield tiles, and Soul Knight close-up maps. Do not use for ordinary image enlargement or unrelated environment art. Use when the user runs /world-map-to-closeup.
---

# World Map to Close-up

Convert a world-map location into a real player-scale game scene. Treat the overview map as a source of identity, landmarks, biome, and connectivity—not as pixels to crop and enlarge.

## Select the operating mode

Infer the narrowest mode that fulfills the request:

- **Plan only:** explain or design the workflow without generating images. Respect requests such as “先不用生成图片”.
- **Close-up master:** design and, when requested, generate one playable close-up concept for a selected region.
- **Asset production:** extract, reconstruct, or generate reusable tiles, buildings, props, foreground pieces, and entities from an approved master.
- **Engine delivery:** organize assets and specify or implement the scene in the user’s engine.
- **Full pipeline:** carry a region from overview analysis through close-up master, asset production, and engine delivery.
- **World rollout:** after one pilot region establishes the visual standard, reuse shared assets and process the remaining regions in bounded batches.

Do not generate imagery when the user only asks for a plan. Do not start a world rollout before a pilot region or equivalent style-and-scale standard exists, unless the user explicitly accepts provisional art direction.

## Establish the source contract

Use all supplied images according to their role:

- **Overview map:** region identity, landmark selection, biome, relative location, and exits to neighboring regions.
- **Close-up references:** camera, scene scale, density, readability, walkable-space treatment, and visual quality.
- **Character reference:** player footprint, doorway clearance, collision scale, and visual proportion.
- **Approved close-up master:** authoritative source for the region’s asset list and composition.

If a necessary image is unavailable, ask the user to attach it again. If only character scale is missing, a provisional scale may be proposed, but label it as provisional. Ask only when the missing choice would materially change the result—typically the target region, intended camera, or engine version.

When the current request is in this Emberline Frontier / 余烬防线 repo (rooms, battlefield, shop halls, home hub, tiles, or dungeon close-ups), read [references/emberline-profile.md](references/emberline-profile.md). Treat that file as the project override. Do not apply Internet World camera or pixel rules here.

When the current request concerns the user's Internet World / 互联网大陆 project, including Doge convenience store, read [references/internet-world-profile.md](references/internet-world-profile.md). Treat that file as a project-specific override, not a universal close-up-map rule.

## Execute the workflow

### 1. Write a region brief

Before prompting an image model, identify:

- selected region and its gameplay purpose;
- landmarks that make it recognizable;
- paths, entrances, exits, and their directions;
- walkable, blocked, interactive, and foreground-occlusion areas;
- elements that should remain separate because they move, animate, collide, change, or receive interaction;
- environmental story and density without making the route unreadable.

For a close-up master or full pipeline, read [references/closeup-planning.md](references/closeup-planning.md).

### 2. Lock style and scale

Record a compact style-and-scale specification before bulk work: projection/camera, pixel or painted treatment, native asset resolution, character height, tile or movement unit, doorway width, path width, outline, palette, light direction, shadow treatment, and density.

Derive these values from the references when possible. Do not impose a universal tile size. If exact values cannot be inferred, present a coherent provisional set and keep every output consistent with it.

Classify the camera from observable geometry before writing a generation prompt: projection, horizontal rotation/yaw, downward pitch, screen-axis alignment, visible building surfaces, ground-to-building ratio, and permitted movement directions. Do not infer camera type from ambiguous words such as “front”, “horizontal”, “2.5D”, or “横版” alone. Separate a building facade facing the viewer from a low, frontal camera; separate a landscape canvas from side-scrolling gameplay.

For pixel art, distinguish native low-resolution construction from a high-resolution painting with a pixel filter. Lock native canvas or asset scale, integer display multiplier, filtering, pixel-cluster size, outline width, shade count, and antialiasing policy.

### 3. Produce the close-up master

Design a new playable composition that preserves the region’s identity and connections. A valid close-up is not a crop, upscale, or merely a larger building pasted onto the overview.

The master must provide:

- a readable player-scale walkable plane;
- entrances and exits that can support transitions;
- landmark buildings with usable doors and surrounding clearance;
- deliberate empty space for movement, combat, NPCs, and interactions;
- consistent fixed camera and scale;
- clear foreground/background separation;
- no UI, watermark, unwanted characters, or baked-in interactive entities.

When generating or editing raster imagery, use the image generation/editing capability with the overview and close-up references assigned to their correct roles. Inspect available reference images before editing them.

If the required projection, yaw, or pitch differs fundamentally from an earlier result, regenerate the composition from scratch instead of asking an edit to preserve geometry built for the wrong camera.

### 4. Validate before multiplying work

Read [references/quality-gates.md](references/quality-gates.md) and test the master. Reject it if it still reads as a world map, lacks a navigable plane, changes the region identity, breaks exit topology, or uses inconsistent camera/scale.

For a visually ambiguous full pipeline, show the first master and request a decision before costly bulk asset production. If the user explicitly authorizes automatic completion, continue in bounded batches after the master passes the quality gate and clearly record any inferred decisions.

### 5. Build reusable assets

Read [references/asset-production.md](references/asset-production.md). Classify each requested asset as:

- **Extract:** pixels exist clearly enough to isolate from the source.
- **Reconstruct:** the item exists but is too small, occluded, or fused with the scene, so a new clean asset must be rebuilt to match.
- **Generate:** the item is new and created from the locked style specification.

Never describe reconstruction or regeneration as pixel-identical extraction. Interactive NPCs, pets, doors, signs, effects, pickups, and replaceable props must not be permanently baked into the base map.

Create an asset manifest with source class, dimensions, pivot/foot point, collision intent, layer, variants, animation status, and file path. Reuse shared assets instead of regenerating near-duplicates for every region.

### 6. Deliver for the engine

If Godot is the target, read [references/godot-delivery.md](references/godot-delivery.md). Confirm or inspect the Godot version before relying on version-specific node names or APIs. Separate ground, structures, props, entities, collisions/navigation, foreground occluders, effects, and scene exits. In this repo, also follow the Emberline delivery paths in [references/emberline-profile.md](references/emberline-profile.md) instead of creating a parallel `regions/` tree.

The engine result—not the concept painting—is the final playable map. Preserve source files and editable layers; include import settings, pivots, collision intent, and a placement manifest or scene implementation as requested.

## Non-negotiable invariants

- Preserve region identity and high-level path connectivity while adapting local spacing for gameplay.
- Keep camera, scale, palette, outline, lighting, and pixel density consistent across a region set.
- Favor modular assets over a single flattened background whenever elements require interaction, animation, occlusion, replacement, or reuse.
- Use literal extraction only when source pixels support it; state limitations instead of promising impossible identity.
- Keep signs and text separate when localization or later editing is plausible.
- Do not invent hidden sides of a source building without marking them as reconstructed design.
- Diagnose a failed generation before retrying. After two targeted repairs that still miss the same fundamental direction, stop blind retries and ask the user to choose between concrete alternatives.

## Completion report

At handoff, summarize:

- region and operating mode completed;
- locked style/scale choices;
- retained landmarks and exit mapping;
- generated deliverables and asset manifest location;
- extraction versus reconstruction decisions;
- remaining provisional choices or blockers;
- the next region only when a larger rollout was requested.
