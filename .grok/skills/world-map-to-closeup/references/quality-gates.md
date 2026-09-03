# Quality Gates

Read this reference before accepting a close-up master and again before engine handoff.

## Gate 0 — The camera matches

Compare the output to the camera reference using observable geometry:

- projection type matches;
- horizontal yaw and screen-axis alignment match;
- downward pitch produces the same balance of ground, facade, roof, and side-wall visibility;
- building fronts face the intended screen direction without changing the camera category;
- the visible walkable plane supports the intended movement model;
- landscape framing has not been mistaken for side-view gameplay.

Reject a result when it is isometric instead of screen-aligned top-down, frontal elevation instead of high-angle top-down, or side view instead of four/eight-direction play. A fundamental projection/yaw/pitch mismatch requires a new composition, not a small preservation edit.

## Gate A — It is genuinely a close-up

Pass only when:

- the scene reads at player scale rather than world-map scale;
- doors, paths, props, and open space have believable character-relative proportions;
- the player has a clear walkable plane and multiple usable positions;
- the landmark has an approach area rather than filling the frame like an illustration;
- the camera is suitable for gameplay and not a cinematic perspective shot.

Automatic reject examples: simple crop/upscale, tiny world-map buildings, diorama with no route, illustration dominated by façade, or inconsistent perspective across objects.

## Gate B — It remains the same region

Check that required landmarks, biome cues, iconic shapes/colors, and logical exits survive. Local spacing may change for gameplay, but a path that connects east on the overview must not silently become an unrelated dead end.

Record every intentional topology change and why it improves play.

## Gate C — It is playable

- Main route is visually readable.
- Door and path clearance fits the character/collider.
- Open space supports the intended exploration, interaction, or combat.
- Blocking edges are visually explained.
- Interactive objects have approach room.
- Foreground occlusion is separable and will not hide critical navigation for too long.
- Decoration does not create false entrances or collision ambiguity.

## Gate D — It is producible

- Ground, structures, props, foreground, and entities can be separated.
- Repeated materials can become tiles or reusable patches.
- Interactive and animated elements are not irreversibly baked into the base.
- Hidden or occluded parts that require reconstruction are identified.
- Text/signage that may change is separable.
- Asset count is reasonable because shared elements are reused.

## Gate E — It is visually consistent

Compare against references and approved anchors:

- projection and camera angle;
- character-relative scale;
- native pixel density and edge treatment;
- outline thickness;
- palette, contrast, and saturation;
- lighting direction and shadow language;
- top/front/side visibility of structures;
- environmental detail density.

## Gate F — Engine handoff

- Each asset has a file, layer, pivot, and collision/interaction intent.
- Transparent assets have clean edges.
- Terrain transitions are checked for seams.
- Foreground draw-order behavior is defined.
- Exit IDs map to destinations and safe spawn points.
- The actual character can traverse main routes and doorways.
- Import/render settings preserve the intended look.

## Repair protocol

Do not retry with a vaguer or longer prompt. Identify the failed gate and make a targeted change:

| Failure | Targeted repair |
|---|---|
| Still looks like overview map | increase character-relative scale, reduce visible territory, redesign the walkable plane |
| Building is large but scene is not playable | add approach space, routes, lateral movement, interactions, and exits |
| Wrong identity | restore required landmark silhouette, biome motifs, and overview-map connections |
| Wrong camera category | regenerate from scratch with projection, yaw, pitch, axis alignment, visible surfaces, and movement model explicitly locked |
| Minor perspective drift | preserve the category and correct only the measured pitch or framing difference |
| Clutter blocks reading | preserve route/interaction zones and relocate decoration into clusters |
| Cannot split assets | regenerate/recompose with explicit layers and separate interactive elements |

After two targeted repairs fail on the same fundamental direction, show the best result plus the unresolved difference and ask the user to choose among concrete alternatives before spending more generations.
