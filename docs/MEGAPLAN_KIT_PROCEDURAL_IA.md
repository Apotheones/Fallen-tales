# Arrowfallen — AI Procedural Art Kit: Implementation Specification

Date: 2026-10-04. Status: implementation plan, not a list of shipped features.

## 1. Mission

Build a Lua/LÖVE authoring toolkit that lets AI agents create, inspect, animate,
and refine exceptional pixel art for Arrowfallen through reproducible code.
Exploration and combat must receive equal visual and motion polish.

The primary workflow is:

**Brief → procedural Lua recipe → indexed pixels → multi-channel bake → visual
inspection → localized correction → comparison → in-game validation.**

The source of truth is authoring code. PNGs are generated review/build outputs.
Procedural authorship includes parameterized shapes, hand-authored pixel clusters,
and explicit pixel patches. Do not force every asset through generic geometry.

Success means cohesive, expressive art and satisfying motion inside the game.
A large API, passing geometry tests, or an attractive still image is insufficient.

Related documents:

- [Existing HD pipeline plan](MEGAPLAN_VISUAL_HD.md)
- [Visual direction](GUIA_VISUAL.md)
- [Current kit usage](PIXEL_KIT.md)

This specification adds authoring capabilities to the existing pipeline. It does
not authorize changing campaign mechanics, narrative, geography, or all assets
at once. Read relevant direction documents before changing an existing asset.

## 2. Mandatory constraints

1. Follow the repository's AGENTS.md and preserve unrelated local changes.
2. Target this repository and LÖVE 11.x; no multi-engine abstraction.
3. Use plain Lua modules and tables. No plugin framework, registries, factories,
   global event bus, generic node graph, or new textual drawing language.
4. Reuse SpriteDSL, palettes, hd_kit, anim8, lighting, render, and feedback.
5. Authoring grids use integer, 1-based coordinates. ImageData uses 0-based
   coordinates; keep conversion at a clearly defined bake boundary.
6. Preserve HD art scale: 64×64 tiles, approximately 64×96 actors, explicit
   exceptions. Keep logical simulation units separate from art pixels.
7. Indexed palette colors and nearest filtering; no automatic blur or smoothing.
8. Bake static art and animation frames outside draw. Rendering reads state and
   never decides gameplay rules. Preserve the fixed simulation timestep.
9. Simulated actors remain in Concord ECS. Bitmap authoring uses ordinary tables.
10. Owners call children; upward notifications use existing world/game events.
11. Save all test PNGs and screenshots under screenshots/ in the project root.
12. Every new helper must have a concrete consumer in its implementation milestone.

## 3. Verified starting point

Inspect current code before implementation; the repository may have evolved.

| Existing component | Reuse | Missing capability |
| --- | --- | --- |
| src/pixel_kit.lua | Grids, pixel/rect/line/ellipse/polygon, masks, outline, flip, blit, paint, inspection, DSL layer | Advanced curves, regions, material tools, poses, animation tooling |
| tools/pixel_kit/main.lua | Executable checks, lantern demo, 1x/enlarged/channel preview | Production review workbench |
| src/sprite_dsl.lua | Indexed layers/frames; albedo, height-derived normals, emissive; export | Authoring decisions and localized revision |
| src/palettes.lua | Existing material ramps and palette resolution | Authoring/remapping/review helpers |
| src/hd_kit.lua | Sheet loading, quads, anchors, variants | Consume compatible generated assets |
| src/sprites/ | Lua asset definitions | Approved examples at the target quality level |
| src/lighting.lua and src/render.lua | Actual lighting and composition | Contextual review fixtures |
| src/pixel_actors.lua | Existing actor presentation/animation | Evaluate reuse for pilot poses and frames |
| src/feedback.lua | Existing sound, particles, rings, shake | Coordinated presentation for the selected action |

The basic kit's checks and DSL bake/export passed in LÖVE during initial work.
Re-run them after changes. The lantern is a technical fixture, not an approved
example of final artistic quality.

SpriteDSL currently caches by definition identity and composes channels
independently. A modified recipe must produce a fresh definition or use an
explicitly implemented invalidation path. Do not silently change composition.

## 4. Deliverables and priorities

P0: necessary foundation. P1: advanced authorship. P2: motion and production.
P3: conditional extensions, implemented only after a demonstrated need.

| ID | Work package | Priority | Depends on |
| --- | --- | --- | --- |
| W0 | Contracts, baseline, reproducible runner | P0 | Existing kit |
| W1 | Rasterization, selections, regions, local corrections | P0/P1 | W0 |
| W2 | Palette, materials, multi-channel authorship | P1 | W1 |
| W3 | Review workbench and agent-facing reports | P0/P1 | W0; extend with W1/W2 |
| W4 | Actor parts, poses, anchors, animation | P1/P2 | W1, W2, static W3 |
| W5 | Tiles, architecture, living exploration pilot | P1/P2 | W1, W2, W3; animated parts use W4 |
| W6 | Pixel VFX and combat presentation pilot | P2 | W2, W3, W4 |
| W7 | Agent production workflow and controlled expansion | P2 | W5 and W6 accepted |

These are implementation boundaries, not required module names. Implement the
smallest coherent subset that proves each pilot; do not complete a catalog of
unused helpers before producing art.

## 5. W0 — Contract, runner, baseline

Deliver:

- Document current coordinates, transparency, clipping, mask behavior, palette,
  frame layout, origins, channel composition, and cache behavior.
- Define a small asset brief: role, region, dimensions, perspective, proportions,
  identity features, materials, named regions, anchors, states, timing, seed,
  allowed variation, and protected features.
- Provide a scriptable runner with predictable outputs and nonzero failure codes.
- Measure current bake time, sheet dimensions, retained memory where measurable,
  and render cost in a recorded scene/configuration.
- Use asset-local deterministic randomness; never consume gameplay RNG.
- Bound dimensions, frames, and variant counts in batch tooling.

Acceptance:

- Same recipe, parameters, and seed produce identical pixels and metadata.
- Existing kit checks and export still pass.
- Editing an asset cannot return stale cached artwork.
- Error output identifies authoring, bake, or rendering failure.

Lua recipes are trusted repository code. Do not claim the runner sandboxes
untrusted scripts.

## 6. W1 — Drawing and localized corrections

Deliver in concrete asset-driven increments:

- Quadratic/cubic pixel curves and open/closed paths.
- Controlled stroke width, predictable endpoints and joins.
- Concave polygons; holes and cutouts through masks.
- Flood fill with explicit connectivity and region bounds.
- Selection by color, coverage, rectangle, or connected component.
- Mask union, intersection, subtraction, bounded inversion, dilation, erosion.
- Named regions and preserved masks for later correction.
- Crop, offset, mirror, explicit pivots, small authored cluster stamps.
- Pixel/row/region patches applied at a defined recipe stage.
- Outer, inner, selective, lit-side, and shadow-side outlines.
- Review aids for contour step sequences, thickness changes, isolated pixels,
  connected color clusters, corners, and intentional gaps.

Acceptance:

- Integer-coordinate and boundary rules are documented and consistent.
- Test diagonal strokes, thin curves, clipping, degenerate input, masks, and
  composition using compact executable checks.
- An agent can alter one region of a real prop without changing protected areas.
- Export the original and candidate at identical framing for visual comparison.

Curve rasterization is not automatic artistic cleanup. Flag suspicious steps;
let the author preserve or correct them. Palette-based anti-aliasing is optional
and authored, never blanket smoothing.

## 7. W2 — Color, materials, lighting channels

Deliver:

- Existing ramp resolution and region-based ramp remapping.
- Swatches, color counts, redundant-color warnings, luminance/silhouette views.
- Configurable per-asset color budgets; no universal arbitrary color count.
- Editable lighting fields: planes, bands, quantized gradients, approximate
  volumes, and occlusion masks, followed by cluster-level correction.
- Material-aware texture placement: orientation, cluster size, density, contact,
  edge distance, protected quiet areas, and deterministic marks.
- Optional localized dithering, disabled by default.
- Height and emission authoring by region, channel previews, and validation.

Start with stone, iron, and cloth on real pilot assets. Add other materials when
an asset consumes them:

| Material | Authoring controls | Main review concern |
| --- | --- | --- |
| Stone | Planes, joints, chips, contact | Uniform speckling or inflated relief |
| Metal | Narrow highlights, faces, worn edges | Plastic appearance or excessive glow |
| Wood | Grain flow, cut surfaces, cracks | Directionless texture |
| Cloth | Tension, major folds, hems | Stripes unrelated to pose |
| Skin/face | Broad planes, eyes, expression | Detail destroying 1x readability |
| Hair | Masses and grouped strands | Scattered single-pixel strands |
| Foliage | Branches, leaf clusters, gaps | Confetti or solid undifferentiated masses |
| Glass | Frame, suggested transparency, reflections | Opaque body or unsupported highlights |
| Water | Flow, banks, reflections, cycles | Incoherent texture drift |
| Fire/smoke | Changing silhouette, core, dissipation | Mechanical loop hidden by bloom |

Acceptance:

- Palette validity and channel bounds are mechanically checked.
- Pilot materials remain distinguishable at 1x under actual game lighting.
- Review neutral light, region ambient light, and a moving local light source.
- Albedo shading does not strongly contradict dynamic light direction.
- Height changes describe form, not every color change.
- Emission coverage and normal orientation are explicitly reviewed.

Additional roughness channels, authored normals, and channel-erasure semantics
are P3. Extend SpriteDSL only after proving the current contract cannot express
an actual required asset, and document compatibility/migration.

## 8. W3 — Review workbench for humans and AI agents

Static review:

- Native 1x and integer zoom; checkerboard, neutral, and real game backgrounds.
- Grid, coordinates, origins, anchors, region masks, coverage boxes.
- Albedo, height, normals, emission, luminance, silhouette.
- Actual lighting preview with movable light sources.
- Side-by-side and toggle A/B comparison with identical camera/settings.
- Changed-pixel map, palette swatches, focused region crops.
- Tile repetition and multiple-instance previews where relevant.

Animated review, added alongside W4:

- Playback, pause, frame stepping, speed, loop, per-frame durations.
- Onion skin, anchor trajectories, contact markers.
- Main motion with effects disabled, then full presentation.
- Several instances to expose repeated phases and identical loops.
- Reproducible frame captures and a recorded/replayable sequence.

Agent interface:

- Scripts are the main control surface; routine work must not depend on UI clicks.
- Select asset, seed, frame/sequence, background, lighting, and review mode.
- Export predictable file paths and compact reports.
- Reports include frame, coordinates/region, reason, and technical severity.
- Use Lua tables/text initially; introduce JSON only for a concrete consumer.
- Keep art warnings separate from hard validation errors.

Acceptance:

- An agent can render, locate an issue, patch the region, and compare versions
  through the documented runner without editing the game's main dispatcher.
- Review images are available to the agent and all captures remain in screenshots/.
- A still capture is never reported as proof of animation timing or game feel.

## 9. W4 — Actor construction, poses, animation

Deliver:

- Proportion guides and named body/clothing/equipment parts.
- Concrete local pivots and anchors: feet, hands, head, tool, emission point.
- Stable identity colors and proportions across poses/directions.
- Direction-specific occlusion and equipment placement; do not assume mirroring
  correctly preserves handedness or asymmetric costume details.
- Key poses, variable frame exposure, named sequences, and frame durations.
- Preparation, contact, reaction, recovery, and return-to-rest markers.
- Secondary motion for cloth, hair, carried gear, and tools.
- Diagnostics for foot drift, silhouette jumps, missing parts, texture flicker,
  channel mismatch, and loop discontinuity.

Pilot actions: idle, walk, interaction, and one existing combat action. Use only
orientations the game actually consumes. Add charge, fire, defend, hit, defeat,
NPC work, and conversation gestures as real production needs arise.

A simple part rig may generate draft poses. Final frames require silhouette,
cluster, perspective, and occlusion correction. Bitmap rotation or interpolation
must not be presented as automatic finished animation. Prefer authored poses
when continuous scaling/rotation damages pixel structure.

Acceptance:

- One pilot actor retains identity and grounded feet through required directions.
- Playback is reviewed at actual speed; contacts and loop transitions are stable.
- Animation metadata has an existing or newly implemented concrete consumer.
- Presentation events never apply damage or decide gameplay rules in draw.
- Expressive smears/squash may trigger warnings but are not auto-corrected.

## 10. W5 — Environment and exploration pilot

Deliver:

- Tile edge compatibility, 3×3-or-larger repetition preview, static variants.
- Controlled transitions between actual terrain types used by the pilot.
- Separate structural tiles from decorative marks and interaction readability.
- Consistent top/front planes and scale across doors, furniture, actors, facades.
- Concrete architecture parts required by the selected area.
- Visual object states: lit/unlit, open/closed, intact/used where gameplay exists.
- Local fire, smoke, water, cloth, and foliage cycles as needed.
- Distinct instance phases, material-appropriate amplitudes, authored pauses.
- Localized interaction response through existing events when available.

Acceptance:

- A small existing Refúgio area is reviewed in motion inside the actual game.
- Paths, player, and interaction targets remain clear.
- No accidental tile seams, distracting repeated marks, synchronized ambient
  loops, or unintended drift at object contact points.
- States and variants are distinguishable from animation frames in metadata.
- No campaign/geography changes are required to demonstrate the art.

## 11. W6 — Pixel VFX and combat presentation pilot

Deliver:

- Authored pixel trails, arcs, sparks, dust, fragments, smoke, and waves.
- Direction/material-specific shapes, palette, expansion, and dissipation.
- Adequate frame margins; emission reviewed with and without bloom.
- One complete response sequence on an existing tactical action.
- Clear differences between firing, hitting, blocking, and encounter resolution.
- Synchronize animation, sound, particles, reaction, and optional impact pause
  through current game/effect hooks.

Before selecting timing/intensity parameters, research mechanical precedents
for the chosen action. Record primary-source evidence or direct observations;
do not copy unrelated action-game values into the tactical campaign.

Acceptance:

- Telegraphs, direction, contact, and result stay readable.
- Presentation cannot duplicate damage, change turn order, or block input
  beyond the game's explicit existing action contract.
- Camera shake moves presentation only, never simulation/collision.
- Any adopted hit-stop restores safely and handles pause/cancel/scene changes.
- Reduced-motion and audio settings remain respected; essential information
  survives disabled shake and flashes.
- Review repeated and simultaneous events, not only one ideal impact.
- Defeat/accommodation visuals respect that winning need not mean killing.

## 12. W7 — Reproducible agent production workflow

Deliver:

- Concise authoring instructions with actual APIs, small working examples,
  known limitations, runner commands, and required review evidence.
- Recipe/brief conventions preserving seeds, parameters, and protected features.
- A small approved reference set with concrete reasons for approval.
- Controlled generation of a few candidates with named differences.
- Region-based revisions, comparison, rollback, and integration checks.
- Batch production only after exploration and combat pilots are accepted.

Acceptance:

- A fresh agent session can reproduce and revise an asset from the documentation.
- Existing approved decisions survive localized edits.
- Observations are distinguished from hypotheses in critiques.
- Agent reports explicitly separate shipped behavior, remaining work, and risks.

Creating/installing a reusable agent skill is a separate deliverable if requested.
Do not automatically add orchestration or spawn agents merely to use the kit.

## 13. Agent execution protocol

For every assigned work package:

1. Read AGENTS.md, this specification, relevant direction documents, and callers.
2. Inspect current implementation and local changes before selecting file scope.
3. State the smallest milestone, concrete pilot consumer, and acceptance evidence.
4. Implement using existing contracts; update documentation when behavior changes.
5. Leave one compact runnable check for meaningful new logic; add visual fixtures
   where correctness depends on pixels, lighting, animation, or composition.
6. Run relevant checks and render the pilot; inspect the output rather than only
   confirming files exist. Perform in-game playback where the milestone requires it.
7. Report changed files, observed results, limitations, and exact reproduction steps.

Suggested assignment prompt:

> Implement work package Wn from docs/MEGAPLAN_KIT_PROCEDURAL_IA.md. Follow
> AGENTS.md and preserve unrelated work. Inspect current code first. Select a
> concrete pilot consumer, implement the smallest complete milestone, and verify
> its acceptance criteria with executable checks and inspected visual evidence.
> Do not implement future packages or claim artistic approval from tests alone.
> Report changes, reproduction commands, evidence, and remaining limitations.

### Coordination when multiple agents are explicitly assigned

- Set file ownership before concurrent edits; dependencies remain sequential.
- W1 owns core grid/mask contracts; W2 consumes stable W1 contracts.
- W3 workbench can proceed on existing interfaces; adapt only after contracts settle.
- W4/W5/W6 recipe work may proceed independently once dependencies are available.
- SpriteDSL/palette contract changes require one owner and consumer review.
- Integrate shared render/feedback files through one owner to avoid conflicting edits.
- Do not create new modules solely to partition work between agents.

## 14. Validation gates

Hard failures: invalid dimensions/channels/frames/colors, non-deterministic output,
load/bake failure, stale cache, invalid origin, out-of-bounds access, gameplay
regression, or duplicated simulation events.

Review warnings: isolated pixels, contour irregularity, color redundancy, excessive
texture, foot drift, temporal flicker, seams, clipping, exaggerated normals/emission.
Warnings are not automatic artistic defects.

Art review: silhouette, proportions, cluster rhythm, material readability,
perspective, expression, motion, timing, scene hierarchy, and character identity.
Use specific comparisons; never invent an automatic professional-quality score.

Close a milestone only after its executable and visual gates pass. Mark missing
runtime verification as unverified, not complete. Human artistic approval remains
separate from an agent's technical verification.

## 15. Production performance

- Measure before setting numeric bake/memory/render budgets; record machine,
  resolution, scene, and frame/variant counts for comparisons.
- Track variant growth: directions × poses × frames × channels.
- Reuse sheets/quads and avoid retaining unused authoring intermediates at runtime.
- Avoid rebaking per frame or visiting assets in an order that changes RNG output.
- Add incremental rebuilds, disk prebakes, atlases, or packing only when measured
  load time, texture limits, memory, or draw calls justify them.

## 16. Pilot selection and completion definition

Proposed pilots, to confirm against current assets/call sites:

- Viajante as the actor, preserving established identity/equipment.
- A real Refúgio lantern/braseiro for metal, flame, channels, and object states.
- One small existing Refúgio section for ground, vegetation/cloth, and light.
- One existing tactical combat action, selected after tracing its events.

Exploration and combat pilots carry equal acceptance weight. Do not declare the
kit successful after finishing only one.

The toolkit is production-ready when a fresh AI agent can build, inspect, revise,
and integrate a static prop, animated actor, environment set, and presentation
sequence with deterministic outputs and documented limits.

The artistic ambition is demonstrated when both pilots are compelling in actual
playback, coherent with Arrowfallen, and approved at native scale under real
lighting. Expand by approved asset groups, not a speculative whole-game rewrite.

## 17. Conditional scope and principal risks

| Risk | Required response |
| --- | --- |
| Generic procedural appearance | Authored silhouettes/clusters, protected identity, local patches |
| More detail reduces readability | Native-scale/context review and quiet areas |
| Lighting contradicts material | Review structural shading and normals under moving light |
| Cutout-puppet animation | Key poses and redraw, not only part rotation |
| Variation destroys identity | Restrict parameters and preserve equipment/proportions |
| Ambient movement becomes noise | Hierarchy, distinct phase, restrained amplitude, pauses |
| Effects hide tactical information | Review warnings/results with reduced effects |
| Framework work replaces art production | Require a consumer and visual proof for each helper |

P3 only: generic rigs, extra physical channels, external formats, automated
interpolation, or a full visual editor. Plugin systems remain out of scope;
automatic agent orchestration requires a separate explicit request.
Some may never be needed. Require a demonstrated production constraint before
proposing them; they are not prerequisites for the target quality.

## 18. Technical references

These support workflow/integration features, not claims of artistic quality.
Aseprite is a workflow reference, not a required dependency.

- [LÖVE ImageData](https://www.love2d.org/wiki/ImageData)
- [LÖVE per-pixel writes](https://love2d.org/wiki/ImageData%3AsetPixel)
- [Aseprite animation](https://www.aseprite.org/docs/animation)
- [Aseprite sequence tags](https://www.aseprite.org/docs/tags/)
- [Aseprite named slices](https://aseprite.com/docs/slices/)
- [Aseprite batch export](https://www.aseprite.org/docs/cli/)
