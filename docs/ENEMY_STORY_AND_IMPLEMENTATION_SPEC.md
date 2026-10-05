# ARROWFALLEN — Enemy Story and Implementation Specification

Revision: 2026-10-04. This is an English design and implementation handoff, not an executable configuration or a change to game code. Existing `kind`, action, flag, context, and file identifiers remain unchanged. English character titles below are proposed display labels.

## Authority and status

Mechanics are grounded in `src/battle.lua`, `src/enemies.lua`, `src/systems.lua`, `src/environment.lua`, `src/battle_talks.lua`, and [COMBATE_MERGE.md](COMBATE_MERGE.md). The current combat alternates real-time action with frozen social pauses. Older turn-based documents are not authoritative for mechanics.

Narrative continuity follows [BASE_NARRATIVA.md](BASE_NARRATIVA.md), [GUIA_ESCRITA_DEVIN.md](GUIA_ESCRITA_DEVIN.md), campaign records, and `src/battle_barks.lua`; geography follows [PLANO_REFUGIO_ANDLAR.md](PLANO_REFUGIO_ANDLAR.md).

- **CURRENT:** observed executable behavior; not necessarily final balance.
- **PROPOSED:** expanded story, appearance, and dialogue. Never infer new mechanics from it.
- **FUTURE:** unimplemented encounters or rules. Resolve their listed blockers before implementation.

The sheets use documentation fields, not a request for a new schema, registry, manager, or boss framework. Story and appearance in existing-enemy sheets are PROPOSED; their behavior and listed live social actions are CURRENT.

## Narrative foundation

The Refuge offers warmth, shelter, and recognizable daily work, but its safety is marked by loss and concealed responsibility. Every adversary protects something specific: a crossing, a garden, a workplace, an account of the past, or control of movement. Peace should change that relationship, not merely switch off aggression.

The protagonist is an artisan associated with wood and instruments, returning toward Lia, who is alive outside. Preservation of the Refuge involved murder: Bento made the decision; Aurel executed it; Sabela tried to escape; Teca was excluded and opposed it. Doro arrived later and inadvertently broke a grave seal. Nilo inherits no guilt. Keep those responsibilities distinct.

Creature origins proposed here do not establish murdered residents, personal seals, replacement souls, or additional pact conditions. Human fear can explain wrongdoing without erasing agency. Boss victory grants only its authored consequences; it does not select an ending.

Preserve the established alternatives of permanent sacrifice and restitution, including the deaths linked to restitution. Residents must understand permanent consequences. Do not turn protection into immortality, ordinary visits into seals, or the original life into something replaceable. The hill and crypt belong to the Refuge's first realm; Andlar is the second realm, not every old map a new kingdom.

## Shared executable contract — CURRENT

### Units and player tools

- Grid positions and ranges: cells. Time: simulation seconds. Damage: HP. Fixed simulation step: `1/120`.
- Distance: Manhattan `abs(dx)+abs(dy)`, except sparing: Euclidean distance `<1.5`, including adjacent diagonals.
- Attacks: four cardinal directions; dominant-axis ties choose horizontal. Enumeration: `+x,-x,+y,-y`.
- WASD moves and turns; SPACE charges the bow for `0.72`, then release deals `3`; SHIFT uses a frontal shield with finite `1.6` stamina; E spares eligible adjacent actors. Mining affects terrain. No assumed melee, dodge, or unrestricted aiming.
- Player movement: `0.16` per cell; default spawned enemy movement: `0.24`. `move` and projectile intervals describe time per cell. `think` describes decision cadence, not movement speed or an extra delay on every warning.
- Player hit invulnerability: `0.36`. Campaign upgrades can affect HP and difficulty.

### Phase, commitment, and social rules

1. Opening dialogue freezes hostility and can resolve a conflict before action.
2. Active authored units receive grace `0.8 + zeroBasedSpawnIndex*0.15`; husks use their own timer.
3. Default principal quota: two resolved attacks. Override order: unit, encounter, catalog, global. A miss counts; a two-shot volley counts once. Summons are not principal quota actors.
4. Quota completion or `12` seconds requests closure. Seeking stalled for more than `4` seconds also releases the attack obligation.
5. Closure waits for warnings, dashes, volleys, projectiles, hazards, and falls to finish; never cancel a committed attack to open a menu.
6. A `0.4` beat leads into a social pause. Dialogue, pause, and focus loss freeze all simulation in the same tick.
7. Fleeing is an exit traversal with final attacks from remaining hostiles, not a random roll. Calmed and spared actors are exempt.

Use existing states: `seek`, `warn`, `dash`, `volley`, `recover`, `retreat`, `exposed`, `dormant`, `wait`, `calmed`. Resolution is a function, not another state. `wait` resumes hostility; `calmed` does not automatically resume.

At warning entry, snapshot direction and attack-specific data: cells, rays, prop, destination, or origin. Do not retarget within the warning. Terrain can shorten, never extend, a promised footprint. A new chained warning may acquire a new target.

Default persuasion threshold is two; human roles require three. Calming prevents idle hostility, but committed attacks finish. Sparing immediately removes actor and occupancy. A valid damaging hit breaks truce and resets persuasion; a blocked hit does not.

Nonlethal priority: explicit unit boolean, encounter boolean, context setting. Explicit `false` matters; being human is insufficient. Nonlethal fatal damage leaves one HP and removes the spared actor without a death effect.

### Damage and terrain

Frontal enemy armor blocks frontal arrows, including during recovery; flanks and rear remain vulnerable. Co-located area damage bypasses that frontal check. Damage during `exposed` gains one. `H.toRecover` adds `0.9` when staggered; do not introduce universal stagger on every hit.

Projectiles stop at walls, pieces, or the first live body. Allies intercept without projectile damage. Marks, jets, and falls can hit enemies. Environmental pillar impact warns `0.62`, falls up to five cells, uses fatal crushing, and checks grid position plus motion origin. Holes kill fatally. Janda's special fall is a separate damage-and-reposition rule, never fatal crushing by inheritance.

Authored effective HP: `u.hp or ROLES[kind].hp or def.hp or 5`; runtime spawn uses `def.hp`. Boss phase two triggers once at or below half effective maximum HP. Do not silently normalize encounter overrides.

| kind | Authored arena HP / catalog HP | think | recover | Distinct movement |
|---|---:|---:|---:|---|
| `crawler` | 4 / 4 | .24 | .6 | move .20 |
| `ranger` | 6 / 5 | .34 | .75 | retreat 2 |
| `dasher` | 6 / 6 | .28 | .85 | dash .065/cell |
| `sower` | 6 / 5 | .34 | 1.2 | default |
| `watcher` | 5 / 6 | .34 | .9 | move .34 |
| `breaker` | 10 / 10 | .28 | 1.0 | dash .075/cell |
| `veteran` | 8 / 8 | .34 | 1.3 | retreat 1 |
| `husk` | 3 / 3 | — | — | dormant |
| `warden` | 12 / 24 | .32 → .24 | .95 → .7 | dash .065/cell |
| `demolisher` | 8 / 30 | .30 | 1.1 → .8 | dash .075/cell |
| `regent` | 10 / 28 | .30 | .9 → .7 | default |
| `runa` | 10 / 10 | .35 | 1.0 | retreat 2 |
| `janda` | 14 / 14 | .30 | 1.0 | fallback dash |
| `rute` | 12 / 12 | .34 | .9 | inherited retreat 2 |
| `ivo` | 14 / 14 | .34 | .9 | inherited retreat 2 |
| `beltran` | 12 / 12 | .28 | .9 | shove .065/cell |

## Existing nonhuman enemy sheets

### E01 — Grounds Hound

**kind:** `crawler`. **Combat role:** adjacent pressure.

**Story / motivation:** Descended from household hunting beasts, it guards familiar paths after losing the household that gave those paths meaning. It recognizes disturbed soil and food scents, not guilt. In `canteiro`, it can protect shoots; do not automatically invent young or a nest. After tension passes, it returns to examining the ground.

**Visual direction:** Low body, broad forelegs, short heavy jaw, earthy plates, and an expanding throat before the bite. Its posture must reveal the warning from above.

**Behavior:** Seek Manhattan adjacency → snapshot player cell → warn `.7` → bite that original cell for `1`, without moving into it. Hit: recover `.6`; miss: exposed `1.3`, then seek timer `.15`. Current player/resonator occupancy determines the bite result.

**Social:** Nonverbal, `negotiates=false`; `observar` exists. `distrair` is disabled proposed content. Refuse `intimidar`, `provocar`, `tregua`, `acalmar`.

**Acceptance:** Given a bite warning, when the player leaves, then the original cell is attacked and the miss exposes the hound; no retarget occurs.

### E02 — Forgotten Archer

**kind:** `ranger`. **Combat role:** line control.

**Story / motivation:** Guarding habits remain precise while the information supporting them has grown stale. It remembers a forbidden approach better than a visitor's face. A truce recognizes changed circumstances; it does not prove innocence or knowledge of the pact.

**Visual direction:** Repaired hood, exposed drawing arm, uneven bindings, carefully maintained bow. Hold a readable aim pose before firing.

**Behavior:** Seek visible alignment at `3..8`; engagement accepts any visible cardinal alignment without an extra eight-cell cap. Snapshot ray to cover/border → warn `1.05` → bolt `2`, interval `.13` → recover `.75` → retreat twice. Retreat starts at `.1`, uses `.26` step cadence, and returns to seeking with `.15` timer.

**Social:** `observar`, `acalmar`, `tregua`; intimidation refused. Code has a provoke fallback, but the current menu does not offer `provocar`.

**Acceptance:** Sideways movement avoids the locked ray. A visible aligned player beyond eight cells can trigger current firing behavior.

### E03 — Threshold Guard

**kind:** `dasher`. **Combat role:** frontal armor, short rush.

**Story / motivation:** Built to hold an opening, it protects the passage rather than an ideology. Provocation redirects its attention like a crude command. Its exposed clay flanks show the cost of turning away from its assigned front.

**Visual direction:** Broad stone face/chest, narrower clay sides, planted feet, forward lean. Vulnerable angles must be distinguishable.

**Behavior:** Seek adjacency or visible alignment within four → engage visible alignment within four → snapshot four-cell dash → warn `.85` → dash `.065/cell`, damage `2` → recover `.85`. Stops on hit or mineable impact; no through-dash. Armor remains during recovery.

**Social:** `provocar`, `tregua`. Provocation can force dominant cardinal aim without alignment and multiplies warning by `.8`.

**Acceptance:** Frontal arrows remain blocked during recovery. Movement after warning cannot rotate the rush.

### E04 — Bitter Gardener

**kind:** `sower`. **Combat role:** delayed area denial.

**Story / motivation:** It remembers care as preparing soil, but has lost the distinction between tending a bed and punishing its occupants. Peace restores attention to the ground rather than uncovering a secret conqueror.

**Visual direction:** Resin sack, crusted fingers, bent planting posture. The reaching hand announces the selected ground.

**Behavior:** Seek `3..7`; engage `2..7` without its own active mark → snapshot three floor cells centered on player, oriented along dominant source-target axis → warn `.8` → mark fuse `.85` → single explosion for `2`. Owner and allies can be hit. No persistent thorns or poison.

**Social:** `observar`, `acalmar`, `tregua`; refuse intimidation and provocation.

**Acceptance:** Leaving the footprint avoids the blast; the mark resolves once and can hurt its owner.

### E05 — Crossing Watcher

**kind:** `watcher`. **Combat role:** four-ray pressure.

**Story / motivation:** Once a counter of arrivals, it now counts absences with the same patience. Its light is a working sign before it is a sacred object. Addressing that sign interrupts vigilance without creating another pact condition.

**Visual direction:** Lantern, four prominent coat seams, measured gait, lifted-light warning.

**Behavior:** Seek `1..4`; engage within eight Manhattan cells without alignment → snapshot four rays from self to cover/border → warn `.95` → four bolts, damage `2`, interval `.11` → recover `.9`. Older wording about a short cross does not override full rays.

**Social:** `vela` clears candle and sets `calmed=true`; no item consumed, no automatic mercy point. Calmed status permits sparing. `tregua` exists. Committed attacks still finish.

**Acceptance:** Using `vela` stops subsequent idle hostility while an existing cross completes.

### E06 — Roadbreaker

**kind:** `breaker`. **Combat role:** armored terrain destruction.

**Story / motivation:** A road-opening servant keeps clearing resistance after losing the distinction between obstruction and protected boundary. Service has become literal; those who once directed it can still bear responsibility.

**Visual direction:** Stone wedge front, abraded shoulders, dragging limbs, exposed rear joints. Lower the wedge before advancing.

**Behavior:** Elite, frontal armor. Seek adjacency or visible alignment within six; engage aligned within six through cover when a through-line exists → snapshot six-cell path → warn `.9` → dash `.075/cell`, damage `2` → recover `1`. Mineable walls break and allow continuation. Pillars trigger their environmental fall and stop the dash; holes/protected blockers also stop it.

**Social:** `provocar`, `tregua`.

**Acceptance:** Mineable walls and protected blockers differ. Pillar falls preserve environmental fatal-crush rules.

### E07 — Second-Shot Veteran

**kind:** `veteran`. **Combat role:** rehearsed escape interception.

**Story / motivation:** Practice made the archer skilled and inflexible. It remembers where frightened opponents step; the second shot repeats that lesson rather than observing anew. Peace gives it a reason to stop repeating the answer.

**Visual direction:** Worn archery equipment, asymmetrical stance, visible second-arrow preparation. Both directions must be readable initially.

**Behavior:** Seek visible alignment `3..8`, but no added firing cap → snapshot primary and perpendicular rays → warn `1.1` → first bolt `2`, interval `.13` → volley delay `.16` → stored second bolt → recover `1.3`, retreat once. Normal horizontal primary uses secondary `+y`; vertical uses `+x`. Forced unaligned provocation chooses perpendicular toward player. Entire volley counts once.

**Social:** `observar`, `provocar`, `tregua`.

**Acceptance:** Movement between shots cannot rotate the second ray; social closure waits for the volley.

### E08 — Unfinished Husk

**kind:** `husk`. **Combat role:** delayed transformation, no attack.

**Story / motivation:** Resin encloses a shape that never reached completion: an unfinished farewell, not a literal human infant or replacement soul.

**Visual direction:** Small amber shell, incomplete limbs beneath layers, gradual internal stirring. Distinguish it from the emerging crawler.

**Behavior:** Dormant `3.5` → replace in same cell with crawler, initial timer `.5`, preserving summoned flag. Surviving damage through `Battle:hurt` hatches early; lethal damage produces no child. Principal replacement stays counted; summoned replacement stays summoned.

**Social:** `embalar` resets dormancy to `3.5`; no automatic mercy or sparing. Normal negotiation refused.

**Acceptance:** Lethal damage spawns nothing. Repeated soothing resets rather than accumulates time.

### E09 — Mortuary Warden

**kind:** `warden`. **Combat role:** alternating cross/dash boss.

**Story / motivation:** A funerary keeper maintains order around the dead. Its authority belongs to a place and practice, not automatically to a resident's personal seal. Defeating it allows examination, not forgiveness of Aurel.

**Visual direction:** Layered funerary armor, forward mask, separate cross/rush poses. Make phase-two armor loss visible.

**Behavior:** Start `nextMode=cross`; alternate after recovery. Engage visible alignment; cross uses full rays, dash requires distance ≤4. Warn `1.15 → .95`; cross bolts `2`, interval `.11`; dash four cells, `.065/cell`, `2`. Recovery `.95 → .7`; think `.32 → .24`; seek delay `.18`. Phase two removes frontal armor.

**Social:** `observar`, `tregua`; `ordem` disabled proposal. Persuasion threshold two.

**Acceptance:** Cross comes first; alternation follows recovery. Half-HP transition removes armor once.

### E10 — Echo Demolisher

**kind:** `demolisher`. **Combat role:** long through-dash, conditional chain.

**Story / motivation:** It tries to free trapped echoes by breaking everything around them. Force is its sole answer to enclosure. This does not make it the source of the original crime or an alternative final antagonist.

**Visual direction:** Forward-weighted mass, impact fractures, worn striking surfaces. A chained rush needs fresh preparation.

**Behavior:** Boss, frontal armor. Engage aligned ≤7 → snapshot seven-cell through-dash → warn `1 → .85` → damage `2`, `.075/cell` → recover `1.1 → .8`; seek delay `.15`. Phase two may chain one additional valid dash after recovery when the previous attack dashed and was not already chained. New warning may acquire new aim; quota can prevent chaining. Preserve existing through-dash terrain limits.

**Social:** `observar`, `provocar`; `saida` disabled proposal. Refuse truce/intimidation. No complete general peaceful route currently exists.

**Acceptance:** No infinite chain; reacquisition only begins with the second warning.

### E11 — Farewell Regent

**kind:** `regent`. **Combat role:** shot/mark/summon rotation.

**Story / motivation:** Regent describes a musical function, not a new monarchy. It repeats a farewell that once needed other voices, arranging echoes into an unwilling company. Release concerns that performance, not a substitute soul.

**Visual direction:** Amber threads, conducting hands, uneven ceremonial silhouette, distinct preparations for each attack; no armor cues.

**Behavior:** Cycle `shot → mark → shot → summon`. Shot: visible alignment, warn `.9`, damage `2`, interval `.12`. Mark: distance `2..8`, three cells, warn `.8`, fuse `.85`; phase two uses five unique cross cells and fuse `.7`. Summon: warn `1.1`, adjacent free husk, maximum two living summons. Spot order: dominant direction, swapped-axis direction, then their negatives. No spot/full cap skips entry. Phase two multiplies warnings by `.8`; recovery `.9 → .7`; seek delay `.15`.

**Social:** `observar`, `despedida`, `tregua`; farewell adds one persuasion point, provocation refused.

**Acceptance:** Blocked summoning does not stall. Summons remain outside principal quotas. Phase-two cross has five unique cells.

## Existing human sheets

All have CURRENT mechanics; expanded appearance and scene interpretation are PROPOSED. Persuasion threshold is three. Preserve actual campaign roles and gates rather than treating the proposed English prose as new canon.

### H01 — Runa, Watch at the Gate

**kind:** `runa`. **Story:** Runa guards with incomplete information about a supposedly voluntary sacrifice. Evidence exposes the gap between protecting people and protecting an explanation; she did not choose the sacrifice.

**Appearance:** Practical watch clothing, repaired equipment, faded green/leather/pale cloth, disciplined bow posture. Lower the weapon before relaxing after agreement.

**Behavior:** Ranger family, warning `1.05`, damage `1`, recovery `1`, retreat two. Authored `C01-Q1` explicitly enables nonlethality in `duelo`, uses `runaConfronto`, a speaker, and half-HP/mercy beats.

**Social:** `guardar`, `inspecao`, `versao`, `tregua`; intimidation refused.

**Acceptance:** Fatal damage in this duel resolves nonlethally; its flag does not become a global human rule.

### H02 — Janda, Keeper of the Worksite

**kind:** `janda`. **Story:** Evacuation losses drive her control of workers and routes. The conflict concerns the cost of preventing another loss through control. Do not recast her as a secret assassin.

**Appearance:** Dust-ground apron, reinforced hands, familiar hammer, weight from practiced labor rather than oversized armor.

**Behavior:** Choose standing nonfalling pillar within four of self, closest to player, ties `y,x` → snapshot pillar and fall cells along pillar-player axis → warn `1 → .8` → special fall damage `2` plus reposition, potentially hitting herself. Destroyed pillar means miss, not retarget. Fallback normal four-cell dash, warning `.85`. Only hammer warning shortens in phase two; recovery `1`.

**Social:** `inspecao`, `trabalhadores`, `tregua`; `suspender` disabled proposal.

**Acceptance:** Removing the selected pillar cannot select another. Her fall never inherits environmental fatal crushing.

### H03 — Rute, Custodian of the Accounts

**kind:** `rute`. **Story:** Authority depends on what becomes recorded and publicly inspectable. Receipts and books carry the confrontation; defending an account does not authorize destroying evidence.

**Appearance:** Layered working clothes, ink-worn fingers, close-held ledger, habit of straightening objects. Crate movement is physical.

**Behavior:** First eligible crate aligned with player at crate-player distance `1..4`, destination valid/free-or-player → snapshot destination → warn `.9 → .75` → push crate one cell. Occupying player moves one further cell only if free. Blocked: neither moves, no damage. Missing crate: miss. Fallback ranger warning `1.05`, damage `2`; recovery `.9`.

**Social:** `recibo` requires `reciboEma`; `registros` addresses public books. Preserve source menu and gates.

**Acceptance:** Blocked pushes cause no invented crushing. Receipt gate remains mandatory.

### H04 — Ivo, Operator of the Channels

**kind:** `ivo`. **Story:** Technical knowledge gives him control and awareness of consequences. The dispute concerns access, diversion, and accountability; knowledge proves neither innocence nor inevitability.

**Appearance:** Maintenance clothing, mineral/water stains, real operating tool, gesture toward selected channel. Do not invent spellcasting.

**Behavior:** Defaults: row `7`, columns `4,10`, encounter-overridable. Prefer occupied rows in declared order, then columns → snapshot floor band → warn `1 → .8` → area damage `2` to health-bearing units except Ivo. Can bypass frontal guard/armor and kill allies. Fallback ranger warning `1.05`, damage `2`; recovery `.9`.

**Social:** `desvio`, `conjunto` require `esquemaCanal`.

**Acceptance:** Movement cannot relocate the warned band; allies in it remain eligible targets.

### H05 — Beltran, Public Enforcer

**kind:** `beltran`. **Story:** His authority is performed before others. Challenge the difference between a useful function and a public display of control; a peaceful route must not require flattery.

**Appearance:** Maintained public clothing over practical protection, squared stance, hands poised to shove. Telegraph displacement rather than a blade strike.

**Behavior:** Visible alignment ≤4 → warn `.9 → .75` → shove dash `.065/cell`. Frontal player guard costs `.3` stamina. Otherwise push up to two free cells, stopping at first blocker. Zero free cells: damage `1`; one/two: no shove damage. Successful push moves Beltran one cell toward old player position with `.1` move duration. Recovery `.9`. Catalog damage `2` is not actual shove damage.

**Social:** `rota`, `funcao` require `laudo`; `plateia` is not compulsory praise. Human status does not guarantee nonlethality.

**Acceptance:** One-cell push is harmless; fully blocked push deals exactly one.

## Future sheets — NOT IMPLEMENTED

Numbers are proposed starting targets. The blockers below must be resolved in an authored encounter specification; an implementation agent must not invent equipment, consequences, or missing conditions.

### F01 — Geraldo, Author of the Departure

**Proposed kind:** `geraldo`. **Story:** He fabricated a departure account, replacing a person's experience with an official explanation. Keep this distinct from Sabela's actions and Edras's false accident.

**Appearance:** Restrained official clothing, worn cuffs, arranged papers, barriers placed between himself and a questioner.

**Proposed behavior:** HP `12`, no armor, recovery `1.1`. Close an authored physical divider after `1.2` warning; occupied closure deals `1` and repositions one cell. Select in authored order only while a player-to-desk path remains. Protect essential records. A simple line-shot fallback requires defined physical equipment; no telekinetic papers.

**Social resolution:** Correct or publish the fabricated departure, with admission distinct from inspection access.

**Blockers:** Divider cells and lifecycle; displacement destination/blocked handling; fallback equipment; evidence gate; explicit nonlethal policy.

**Acceptance target:** No total isolation from interaction routes; evidence survives combat.

### F02 — Silvério, Controller of Dispatch

**Proposed kind:** `silverio`. **Story:** He determines movement and supply priority. Dispatch records reveal the costs of his choices; waiting refugees are never hostiles or ammunition.

**Appearance:** Cargo equipment with supervisory privileges; gestures toward an actual loading mechanism.

**Proposed behavior:** HP `14`, recovery `1.1`. Select an authored empty cargo platform nearest player within six, ties `y,x` → snapshot two-cell footprint → warn `1.2` → one area hit of `2`. Nonblocking debris, maximum one active cargo hazard. Ranged fallback requires physical equipment.

**Social resolution:** Publish dispatch priorities and make them contestable.

**Blockers:** Platform origins/footprints; exact impact timing; eligibility; fallback; gates; nonlethal policy.

**Acceptance target:** Only empty cargo drops; footprint never follows player movement.

### F03 — Edras, Writer of the False Accident

**Proposed kind:** `edras`. **Story:** He knowingly recorded a death as accidental. His peaceful resolution requires accepting authorship of that deception, distinct from Geraldo's false departure.

**Appearance:** Ink-stained sleeves, guarded posture, bound records, attention to who has read a page.

**Proposed behavior:** HP `10`, recovery `1.2`. Physically push an authored small bookshelf using Rute's one-cell pattern; warning `1`, damage zero. No magical seals or destroyed records. Extra offensive devices remain unresolved, not implied.

**Social resolution:** Release the record with its authorship and deliberate falsification exposed.

**Blockers:** Shelf size/occupancy compatible with push rules; engagement; no-valid-push behavior; evidence gate; nonlethal policy.

**Acceptance target:** Failed pushes neither damage nor teleport; documents remain recoverable.

### F04 — Lena, Keeper of the Station

**Proposed kind:** `lena`. **Story:** Exclusive operational knowledge sustains her authority. Give the information about Lia before conflict; victory cannot gate knowledge that Lia is alive.

**Appearance:** Practical station clothing, real operating tool, practiced gestures to equipment.

**Proposed behavior:** HP `14`, recovery `1`. Alternate an authored physical line device with Beltran-style push, reach three, warning `1`. Without a defined device, scope delivery to push behavior rather than inventing projectile origins.

**Social resolution:** Share safe station operation without creating a replacement monopoly.

**Blockers:** Device origin/range/damage; projectile versus area effect; line-warning timing; exact inherited push parameters; gates; nonlethal policy.

**Acceptance target:** Lia information precedes battle; device effects originate from authored visible machinery.

### F05 — Aurel, the Hand That Carried It Out

**Proposed kind:** `aurel`. **Story:** He executed the decision preserving the Refuge through murder. Attachment, fear, and responsibility coexist. Understanding him does not absolve him; agreement must not demand another sacrifice. He is neither possessed nor a monster replacing human agency.

**Appearance:** Recognizable person, accumulated wear, controlled motion, equipment from actual work. Final weapon/tool is unresolved.

**Proposed behavior:** HP `20`, no armor. Target cycle: line → three-cell blocking dash → line. Warning `1.1`, damage `2`, recovery `1.1 → .9`; phase two does not shorten warnings. First production slice: one attack and a claim-and-response pause.

**Social resolution:** Establish responsibility and open access to the existing ending decision. Combat victory selects no ending.

**Blockers:** Physical weapon; line range/collision; dash meaning/stopping; evidence sequence; explicit lethal/nonlethal consequences. Do not fill gaps with a new ritual or substitute soul.

**Acceptance target:** Preserve Bento's decision, Aurel's execution, and distinct resident roles; victory does not choose sacrifice/restitution.

## Encounter writing and production

Proposed pairings: crawler/ranger for baiting plus line avoidance; sower/dasher for delayed ground danger plus committed rush; watcher/veteran for stored multidirectional rays. These are composition suggestions, not authorization to alter campaign spawns. Check warning overlap and social pacing before HP tuning.

Write hostility around an object or duty. Distinguish refusal, hesitation, and acceptance; information can be revealed without a persuasion point. Keep sample dialogue separate from triggers and flags.

| Speaker | Proposed English dialogue |
|---|---|
| Runa | "Then tell me whose words I have been guarding." |
| Janda | "You call it control. I remember what happened without it." |
| Rute | "Show me the receipt, and let everyone see it." |
| Ivo | "The drawing shows what I can divert. It also shows who pays for it." |
| Beltran | "Read the report aloud. I will answer it." |
| Aurel | "Fear explains why I obeyed. It does not undo my hand." |

These are proposed writing samples, not implemented localization or automatic flag triggers.

**P1 — Narrative/presentation:** Adapt story and appearance to current encounters; preserve mechanics, IDs, gates, endings. English documentation does not authorize changing game localization.

**P2 — Balance:** Change explicitly selected constants only. Keep catalog and authored HP separate. Recheck warning commitment, closure, terrain, and nonlethal precedence.

**P3 — Future encounters:** Resolve blockers, then deliver one encounter using existing modules/helpers. Follow AGENTS.md: local Lua modules, Concord actors, fixed-step simulation, owners calling children, upward world/game presentation events. No speculative architecture.

## Copyable coding-agent prompt

> Read AGENTS.md, ENEMY_STORY_AND_IMPLEMENTATION_SPEC.md, COMBATE_MERGE.md, and the relevant current modules. Select the requested record and production stage. Identify its exact kind, current behavior, proposed additions, and unresolved blockers before editing. Preserve IDs, encounter overrides, item gates, and narrative responsibilities. Never convert descriptive lore into a combat rule. Implement only the authorized scope with existing Lua/Concord patterns and helpers. Snapshot targeting at warning entry; preserve fixed-step simulation and quiet-arena social closure. Do not add melee, dodge, retargeting, projectile friendly fire, automatic human nonlethality, new pact conditions, or automatic ending selection. Verify the record's acceptance cases and affected shared invariants. Report changes, verification, and remaining blockers.

## Shared acceptance checklist

- Given a committed attack, when the player moves or closure is requested, then targeting stays stored and resolution precedes the social pause.
- Given dialogue/pause/focus loss, when a simulation tick would advance, then actors, projectiles, hazards, and falls freeze together.
- Given a calmed actor without subsequent damaging hit, then it does not automatically resume seeking; temporary `wait` has its own transition.
- Given explicit unit nonlethality including `false`, then it overrides encounter/context values.
- Given a summoned actor, then attacks/death do not acquire principal quota responsibility; a principal husk replacement stays principal.
- Given a destroyed selected prop or protected blocker, then existing miss/terrain rules apply without selecting replacement targets.
- Given victory over a human, then evidence, responsibility, and ending choice remain separately authored consequences.

Run checks appropriate to actual implementation changes. Save test captures only in `screenshots/` using the root-run screenshot option. This documentation rewrite does not verify the executable game.

Mechanical reference: Furi's developers discuss learning readable attacks with a small toolset in [Try Again](https://www.thegamebakers.com/try-again/). Use that principle for response clarity, not as permission to import dodge, parry, melee, theme, or visuals. Arrowfallen's bow, shield, terrain, and social pauses define the mechanics.
