# Internet World Project Profile

Read this file only for the user's Internet World / 互联网大陆 project and its regions, including Doge convenience store. These decisions override generic examples in the main skill. Revise this profile when the user explicitly changes the project's visual standard.

## Reference priority

- The player-scale gameplay screenshot controls camera, scale, walkable-space composition, native pixel language, outlines, shading, and prop proportions.
- The overview world map controls region identity, landmark motifs, topology, Doge branding, architecture themes, and restrained Internet/meme elements.
- For close-up generation, weight the gameplay reference more strongly than the overview's detailed painterly rendering. A useful conceptual split is roughly 70% close-up camera/style and 30% overview identity, not a literal image blend.
- Ignore screenshot UI, HUD, minimap, buttons, captions, watermarks, characters, and biome elements that do not belong to the target region.

## Locked camera

Use a **screen-aligned orthographic high-angle top-down 2.5D game view**:

- 16:9 landscape display, but not a side-scrolling camera.
- Orthographic projection with negligible near/far scale change.
- Horizontal yaw approximately 0 degrees: world axes align with screen horizontal and vertical axes; no isometric/diamond rotation.
- Camera looks downward roughly 60–70 degrees from horizontal, equivalently about 20–30 degrees away from pure vertical top-down. This is an art-direction estimate, not a physical calibration.
- Buildings sit mainly toward the upper part of the frame. Their front facades run horizontally and face toward the lower part of the screen.
- Show the front facade plus a limited amount of top/roof surface. Side walls should be minimal rather than the prominent faces of an isometric building.
- A broad ground plane occupies most of the middle and lower frame. Characters can move in four or eight directions and approach entrances from below.
- “Front-facing” refers to the facade orientation; the camera remains high overhead.

Reject:

- diagonal/isometric 30–45 degree horizontal rotation;
- diamond-shaped ground grids;
- low-pitch frontal storefront elevation;
- side-scrolling platform view;
- cinematic perspective or world-map zoom-out.

## Locked pixel language

Use modern native low-resolution pixel art, not high-resolution illustration with a pixel filter:

- Provisional native scene canvas: 512×288 until an authoritative game viewport or character sheet replaces it.
- Preview/display may use a 3× or 4× integer nearest-neighbor upscale.
- Provisional character height: about 40–56 native pixels; provisional terrain unit: about 24–32 pixels. Recalculate from an authoritative character reference when supplied.
- Hard integer-aligned pixel edges; no antialiasing, subpixel blur, or smooth vector contours.
- Intentional pixel clusters with low-to-medium texture density; avoid one-pixel noise and high-resolution microdetail.
- Dark blue-gray or dark brown outlines, commonly 1–2 native pixels.
- Most materials use about 3–5 tonal steps; important buildings may use 4–6. Avoid continuous airbrushed gradients.
- Shadows are compact readable pixel shapes. Avoid soft PBR, realistic reflections, bloom-heavy rendering, and painterly light smearing.
- Buildings and props use slightly exaggerated, readable game proportions rather than realistic architectural rendering.

## Doge convenience-store master

- Place the store along the upper part of the frame with its front facade facing downward and aligned horizontally to the screen.
- Preserve Doge/Shiba identity, restrained 24H motif, striped awning, and the overview map's warm identity colors without copying the overview camera.
- Keep the entrance readable and reachable from the broad ground plane below.
- Reserve a large uncluttered gameplay area; keep left/right continuation and door approach clear.
- Props such as bench, lamp, vending machine, bin, bicycle rack, crates, and plants remain sparse, player-scaled, and separable.
- Do not bake in NPCs, pets, UI, labels, or interactive states.
- Sign text should remain minimal and separable for later localization/editing.

## Prompt camera clause

Include an explicit clause equivalent to:

> Screen-aligned orthographic high-angle top-down 2.5D game view; yaw 0°, camera looking down about 60–70° from horizontal; facade along the upper screen facing downward; broad four/eight-direction walkable ground; minimal side-wall visibility; no isometric rotation, frontal elevation, or side-scroller view.

## Prompt pixel clause

Include an explicit clause equivalent to:

> Native low-resolution pixel art on a provisional 512×288 logical canvas; crisp nearest-neighbor pixel clusters, integer-aligned hard edges, 1–2px dark outlines, limited 3–5 tone material ramps, no antialiasing, smooth gradients, PBR, or high-resolution painted texture.
