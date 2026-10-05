# ARROWFALLEN — World Story and Implementation Specification

Revision: 2026-10-04. Scope: the Refuge, its local places, and its relationship to Andlar. Atmosphere: welcoming, marked by losses and secrets. English documentation does not change game localization or existing Lua identifiers. No game code is changed by this document.

## Authority, fields, and scope

Use [PLANO_REFUGIO_ANDLAR.md](PLANO_REFUGIO_ANDLAR.md) for current spatial organization, [BASE_NARRATIVA.md](BASE_NARRATIVA.md) for the pact and responsibility, and [GUIA_ESCRITA_DEVIN.md](GUIA_ESCRITA_DEVIN.md) for narrative voice. This document supersedes the earlier descriptive Refuge draft. Consult [CHARACTER_STORY_AND_IMPLEMENTATION_SPEC.md](CHARACTER_STORY_AND_IMPLEMENTATION_SPEC.md) for people and [ENEMY_STORY_AND_IMPLEMENTATION_SPEC.md](ENEMY_STORY_AND_IMPLEMENTATION_SPEC.md) for combat.

**ESTABLISHED** means coordinated narrative continuity, not proof that every scene or asset is implemented. **PROPOSED** means architectural history, sensory detail, set dressing, gestures, and sample prose. **IMPLEMENTATION CONDITION** means a constraint on adapting those proposals, not a new flag or automatically authorized feature.

Place record labels `W01..W22` are documentation references, not runtime IDs. Map every adopted record to the existing location/scene identifiers after inspecting source. Do not create a parallel location registry. Exact coordinates, collision footprints, interaction radii, sound levels, sprite dimensions, and asset paths remain those of the actual scene or a separately authored asset specification; prose does not supply numeric values for them.

## Story foundation

### Established continuity

The Refuge is a sanctuary town and the first realm. Its hill, grave, crypt, square, houses, and local waterworks belong to one place. Andlar is another major region of the same world. Internal travel is on foot; the monumental **Marco** in the square carries illuminated realm names and provides travel between realms. Aurel is not a transport prerequisite. Distinguish the Marco from ordinary funerary markers.

The protagonist, a wood and instrument artisan, came for brief work and expected to return to Lia outside. He remembers pursuit and death. A working seven-year interval between murder and awakening remains revisable; do not invent historical dates or individual biographies that depend on its final approval.

The leaders selected an outsider to preserve the town through a stolen life. Bento participated in the decision; Aurel performed the rite and blocked escape; Sabela opposed it and attempted escape assistance; Teca was excluded and opposed it. Doro arrived afterward. Nilo was a child, not an accomplice. The disaster devastated other places while leaving habitable exterior regions. Protection did not grant immortality.

The community was told of a voluntary sacrifice. External records falsified an accident and a departure; these are distinct false accounts. Doro unknowingly broke the grave's sealing while repairing the funerary house. The protagonist returned as a manifestation whose life remains linked to protected people. Defeat returns him to the grave without erasing progress.

First departure requires recovering belongings and resolving the crypt gate, preparing workshop equipment, clearing the cistern exit, and explicitly completing the farewell at the Marco. Meeting every resident is not a requirement. Lia is alive outside; no live appearance, communication, or invented recent news belongs to this opening arc.

### Proposed history: hospitality before protection

Before it was the Refuge, the settlement grew around the hill's funerary complex. A chapel held wakes; lodging sheltered relatives; a kitchen fed people staying after burial; workshops maintained homes and cemetery fittings; storage held tools, cloth, and furniture people could not yet collect. No saintly founder or noble lineage is required. Hospitality emerged from repeated work.

After the catastrophe, temporary beds became homes. Partitions appeared between sleepers, storage yielded space to lessons, and spare ground became gardens. Materials recovered from ruins entered older walls. The town looks inhabited and repaired rather than designed in one campaign of construction.

During the proposed intervening years, inhabitants did sincerely useful work over a concealed crime. Bento fed people, Aurel maintained passages, Sabela protected and taught, Teca cared for privacy, and Doro repaired what he did not know had been purchased with murder. Those acts remain real; none repays the stolen life. The community is not a single moral category.

Discovery should rest on documents, witnesses, and direct answers. The environment provides human context, not a perfect confession engraved on a wall. Do not create a new public cult of the protagonist. Let the player experience shelter, competence, and everyday choice before asking for a final judgment. Accepting food or assistance is not forgiveness.

After actual disclosure and accountability, local actions can change: stock decisions become shared, voluntary-sacrifice wording is corrected, people request distance or company, and permanent welcome explains its consequences. Do not trigger those changes simply because a later map was completed.

## Shared environment contract

- Keep readable routes around thresholds, beds, stairs, and service work. Decoration never silently adds collision, pickups, hazards, or quest prerequisites.
- A place's sensory description informs art/audio direction. Smell is prose; it does not require a simulated smell system. Repeated ambient gestures use existing presentation patterns and do not determine gameplay rules.
- Separate public observation from production spoilers. A broken seal can be visible before its cause is understood; a prop never exposes a confession solely because its artist read this document.
- Initial state: workshop partly covered, water turbid, shelter under maintenance. Completed curtains, repaired installations, resident arrivals, and changed room uses require their actual milestones.
- Spawn each named actor once at the current authored location. Runa's gate/lookout placements are alternatives by progress, not duplicate NPCs.
- Basic shelter and services do not require sympathy, forgiveness, or acceptance of the pact.
- The old underground passage is collapsed. Do not turn it into a late-game shortcut.
- A visitor is not automatically a resident or pact beneficiary. Residence, welcome, and binding follow their authored decisions.

## Place sheets

All sensory details and architectural interpretations below are PROPOSED. Route, presence, and state constraints preserve established continuity. Essential existing quest objects remain governed by source; suggested decoration is optional.

### W01 — Hill and Open Grave

**Purpose:** Establish death as a specific loss and show continued care of the dead.

**Description:** Fresh-earth scent lingers among short grass and worn names. Recent graves carry improvised signs: a flower held by a stone, cloth weighted against the wind. The protagonist's removed slab reveals a pale edge sheltered for years. Cleanly cut soil and careful support show recent work without explaining the sealing.

**Visual/audio cues:** Uneven old markers, maintained paths, exposed slab rim, broken sealing mark; grass movement and restrained wind. Doro's work traces are localized, not an accusation against him.

**State/interaction:** Preserve the existing examination and return-to-grave behavior. The broken mark permits manifestation; its appearance does not introduce a second resurrection system.

**Acceptance:** Returning after defeat retains progress. Observation reveals disturbed masonry without falsely naming Doro as murderer.

### W02 — Crypt and Burial Chamber

**Purpose:** Make the protagonist recognize a space prepared to prevent his return.

**Description:** Damp stone, rust, stored cloth, and a low roof make footsteps return quickly. Clean recent repairs meet dark old masonry. A reachable broken mark sits near a chamber fitted to a body's dimensions. Recognition comes before explanation.

**Visual/audio cues:** Old versus repaired surfaces, low overhead mass, restrained reflected steps. Keep the exit legible amid darkness.

**State/interaction:** Use existing grave/chamber interactions. New inscriptions cannot reveal unreached pact facts.

**Acceptance:** Art preserves the walkable footprint and existing exits; no darkness-based movement rule is inferred.

### W03 — Wake Courtyard

**Purpose:** A pause between arrival of the body and burial.

**Description:** Moisture collects in stone joints. Worn standing areas and rougher edges suggest groups waiting while work continued. Space allows a person to step away from the wall without obstructing everyone else.

**Visual/audio cues:** Worn patches, spare seating if supported by layout, more open acoustics than the chamber.

**State/interaction:** Optional set dressing; no new funeral quest or compulsory gathering.

**Acceptance:** Added props leave actual passage and combat footprints clear.

### W04 — Funerary Store and Belongings

**Purpose:** Recover personal scale through the coat and its connection to Lia.

**Description:** An empty coffin occupies too much room; belongings look small beside it. The familiar coat carries a repair, worn fabric, and remembered weight. Someone should have arrived home wearing it.

**Visual/audio cues:** Large coffin against small personal objects; visible coat patch; cloth movement subordinate to quiet room tone.

**State/interaction:** Recover actual belongings through their existing rules. Acquisition removes or changes the corresponding world prop consistently. Do not add a magical keepsake.

**Acceptance:** Repeated entry cannot duplicate recovered items or imply the coat is still uncollected.

### W05 — Runa's Gate and Descent Hall

**Purpose:** A cautious human threshold rather than an arbitrary lock.

**Description:** Air crosses the gate before a body can. Rust gathers away from the used opening; touched iron is brighter. Runa looks first and asks next. Beyond, an inclined hall compresses footsteps; on the way out, light gradually lets a hand leave the wall.

**Visual/audio cues:** Used iron, narrow passage, gradual lighting transition; avoid decorative bars obscuring the actual opening.

**State/interaction:** Keep the authored gate resolution and Runa encounter. Her knowledge is the received voluntary-sacrifice account, not prophecy. Use current combat rules from the enemy specification.

**Acceptance:** Gate state survives re-entry; Runa is not simultaneously spawned at the lookout.

### W06 — Stairway

**Purpose:** Transition from the burial complex to inhabited shelter.

**Description:** Centers of steps are worn while edges retain sharpness. Light reaches the hands before the wider view. Wood smoke, an indistinct voice, and a utensil against a pot announce life ahead. There is room to pause without forcing someone back.

**Visual/audio cues:** Central wear, edges, progressive warmth, kitchen sound entering gradually.

**State/interaction:** Local route on foot; no portal, fatigue, or climbing subsystem implied.

**Acceptance:** The actual transition remains readable and connected to the existing map.

### W07 — Lookout, Watch Post, and Brazier

**Purpose:** First understanding of the town as a lived place inside a damaged landscape.

**Description:** Smooth parapet patches mark resting hands. Porches nearly meet neighboring roofs; washing reveals hidden yards. The Marco rises among paths returning to the square. Near the watch post, settled ash and used supports show that watching includes waiting and warming hands, not only searching for enemies.

**Visual/audio cues:** Town vista, hands-worn parapet, modest brazier, near domestic sound and distant landscape wind.

**State/interaction:** Runa appears only according to current placement. Vista narration must not require meeting every resident.

**Acceptance:** The view does not falsely show later repairs or arrivals. Brazier decoration introduces no damage unless source already defines it.

### W08 — Square and Marco

**Purpose:** Shared circulation, ordinary company, and realm departure.

**Description:** Daily routes polish pale stone; unused corners gather soil. Mismatched benches share shade. The monumental stone bears names while bowls, cloth, and tools keep passing around it. The square belongs to daily life before ceremony.

**Visual/audio cues:** Central engraved stone, readable illuminated travel names, heterogeneous benches, converging paths. Keep functional travel indications distinct from decorative inscriptions.

**State/interaction:** Marco travel is independent of Aurel. ANDLAR becomes available only after the actual opening milestones and explicit farewell. Do not invent new menu IDs or additional destinations.

**Acceptance:** Moving/removing Aurel does not disable authorized travel. Incomplete farewell cannot be bypassed by inspecting all residents.

### W09 — Chapel Forecourt

**Purpose:** Breathing space between chapel quiet and square conversation.

**Description:** Group wear surrounds a narrow kept-clear passage. Garden soil interrupts the scent of wax and household smoke. A person leaving the chapel can pause without joining the nearest discussion.

**Visual/audio cues:** Open threshold, uneven wear, gradual interior/exterior ambience.

**State/interaction:** Optional resting scene; no automatic dialogue trigger on every crossing.

**Acceptance:** The doorway and intended passage remain clear.

### W10 — Chapel Garden

**Purpose:** Show that survival still includes beauty.

**Description:** Plants occupy spare ground and have been moved to follow the light. A flower leans into a route that people avoid crushing even when carrying weight. Someone prepares a bed knowing it will not flower that day.

**Visual/audio cues:** Small varied beds, wall shadow, modest bloom, soil and leaf textures.

**State/interaction:** Proposed flowers are not healing pickups or pact symbols. Growth changes require authored states, not a new calendar system.

**Acceptance:** Decoration cannot create an item economy or alter existing crop progression.

### W11 — Chapel

**Purpose:** Shelter for grief, silence, rain, or simple rest.

**Description:** The door sticks on damp days. Benches shine unevenly from use; old wax meets clean cloth. The altar leaves room for a person near the entrance who does not want to be called forward. A board creaks, a passerby moves outside, a bird lands on the roof.

**Visual/audio cues:** Used wood, modest altar, accessible rear seating; sparse ambient interruptions rather than uninterrupted ominous music.

**State/interaction:** Doro's presence requires an authored scene. Resting there does not require religious participation or imply knowledge of the crime.

**Acceptance:** Visiting alone does not grant a seal or expose production spoilers.

### W12 — Bento's Kitchen

**Purpose:** Genuine food and comfort beside the cook's real responsibility.

**Description:** Scrubbing lightens the table edge without removing cuts and burns. Food reaches the nose before the pot is visible. Mismatched bowls include one kept because it fits someone's hands. Bento remembers portions; difficult questions may make him straighten a bowl already in place.

**Visual/audio cues:** Hand-height wear, practical shelves, cooking sounds, utensils belonging to the work surface.

**State/interaction:** Food is not purchased with forgiveness. Bento answers direct questions with his actual responsibility. Stock keys/control change only when accountability transfers them.

**Acceptance:** Friendly service does not set forgiveness or confession flags implicitly; keys match current ownership.

### W13 — Lodging / House of Beds

**Purpose:** Shared shelter with individual privacy.

**Description:** Drying cloth and old wood fill a common room of mismatched beds. Narrow passages remain clear because people must walk them in darkness. A folded garment or object by a pillow marks a life expecting tomorrow.

**Visual/audio cues:** Varied beds, repaired textiles, restrained personal objects. Lodging and house of beds are aliases for one place, not duplicate facilities.

**State/interaction:** Start with actual incomplete shelter state; partitions and complete curtains require their milestones. Do not empty an occupied bed to accommodate a new arrival.

**Acceptance:** Rest and basic shelter do not require moral agreement. Room occupants match residence decisions.

### W14 — Laundry Nook

**Purpose:** Modest privacy achieved through ordinary work.

**Description:** Wind lifts one washed piece and leaves another heavy. Between shared rooms and street, conversation lasts the length of a task. Someone may ask another to wait and obtain a small private interval.

**Visual/audio cues:** Uneven cloth motion, rope placement, shelter-to-street threshold. Preserve working routes beneath cloth.

**State/interaction:** Presence follows actual schedules/quests. Do not permanently assign Teca or Dalva here merely because their occupations fit.

**Acceptance:** Ambient animation does not block input or become mandatory conversation.

### W15 — Workshop and Bench

**Purpose:** Restore the protagonist's practical competence; support Nilo's learning.

**Description:** Fresh wood, oil, and persistent dust fill a bench partly covered by repairs. Tools are familiar by weight before their history returns. Nilo tests a sound, laughs at an attempt, and resumes the same piece. Death has not converted craft into a heroic destiny.

**Visual/audio cues:** Partly covered initial bench, localized dust, distinct functional tools; short task sounds rather than constant hammering.

**State/interaction:** Equipment preparation remains an actual opening prerequisite. Bench improvements and finished instruments follow their quests; no new crafting framework is requested.

**Acceptance:** Visual readiness follows the actual preparation state; Nilo appears only when his scene permits.

### W16 — Forge Alley and Gravel Yard

**Purpose:** Doro's practical welcome and work for living people.

**Description:** One wall retains warmth, another damp shade. Gravel answers with dry steps. Leaning timber shares room with metal pieces and darkened water. Doro finishes a risky gesture before answering; his humor notices a stubborn board rather than humiliating its maker.

**Visual/audio cues:** Gravel, charcoal residue, stored materials, safe work clearance. His shovel stays at its job instead of every conversation.

**State/interaction:** Doro begins in this yard. Additional hill/chapel appearances need scene conditions. He learns the murder when told; work traces do not give him prior knowledge.

**Acceptance:** One Doro entity appears at the proper authored position; no new criminal role is inferred.

### W17 — Storehouse and School

**Purpose:** Storage becoming education through negotiated shared space.

**Description:** Old boxes occupy shade while light enters cleared teaching space. Reused materials reveal competing uses. Teca notices seating and privacy; Sabela measures the route she wants clear. Lessons grow from materials, conversations, and returning hands.

**Visual/audio cues:** Boxes versus cleared areas, improvised teaching furniture, unfinished cloth partitions. Avoid depicting the completed school before its milestones.

**State/interaction:** Teca starts here; Sabela follows campaign placement. Learning and reused uniforms do not turn students into soldiers.

**Acceptance:** Layout and costume updates match school progression; no compulsory oath or new curriculum mechanic appears.

### W18 — Well and Cistern

**Purpose:** Make repair useful in daily effort, not merely a status badge.

**Description:** The well exposes work continuing underground. Turbid water darkens containers; pulling has worn the bucket support in one direction. Clearing the outlet changes the sound before anyone announces success. People still complain about the weight, but less work is wasted.

**Visual/audio cues:** Initial turbidity, used support, underground flow, later water presentation tied to actual repair.

**State/interaction:** Well and cistern belong to one local service. Preserve clearing the outlet as an opening prerequisite. No collapsed tunnel shortcut or new water simulation.

**Acceptance:** Clean presentation cannot precede repair; re-entry preserves outlet progress.

### W19 — Porches

**Purpose:** Low-demand company and visible personal absence.

**Description:** A repaired chair waits beneath one eave; wet clothing dries under another. Interior sound reaches the street without exposing an entire conversation. An empty chair gains meaning only after the player knows its usual occupant.

**Visual/audio cues:** Small sheltered seating, limited views, restrained domestic movement.

**State/interaction:** Optional company and rest; empty homes are not filled by substitute NPCs to hide absence.

**Acceptance:** Silence remains possible. Furniture never reveals a resident's death before authored knowledge.

### W20 — Community Garden

**Purpose:** Shared food, different hands, and care without ownership claims.

**Description:** One bed is straight, another curves around terrain. Tender leaves stand beside cut stems. A disappointing root starts a joke; a spared seedling carries someone's small hope. Harvest reaches the common kitchen without making the ground one worker's property.

**Visual/audio cues:** Varied bed geometry, wet soil, small cleaned tools, milestone-dependent growth.

**State/interaction:** Community ownership; never assign exclusively to Bento. Mara and others appear only after their actual decisions/scenes.

**Acceptance:** Garden growth and resident arrivals use real quest states, not automatic scenic progression.

### W21 — Lower Terrace

**Purpose:** Distance enough to recognize desire before returning to company.

**Description:** Wind reaches past fewer roofs. Drying herbs release scent when brushed; a goat interrupts someone's long thought. Beyond the edge lies the distant landscape and the levels separating shelter from its surroundings. The protagonist may think of Lia; another person may simply need quiet.

**Visual/audio cues:** Open vista, quieter domestic sound, herb bundles. Goat presence is optional scenery pending an actual asset/scene decision.

**State/interaction:** No mandatory Lia vision, new animal AI, or additional travel destination. Quiet does not imply a prophecy.

**Acceptance:** The terrace does not introduce live contact with Lia or a route outside existing geography.

### W22 — Streets, Alleys, and Service Ramp

**Purpose:** Make circulation tell the settlement's material history.

**Description:** Routes bend around older walls, height changes, and difficult entrances. Both sides return to the square. Work sounds exchange at corners. Narrow alleys require small agreements; the service ramp offers a patient climb for loads that cannot use steps easily.

**Visual/audio cues:** Moist and sun-dried floor contrasts, load wear, route-specific work ambience, clear slope cues.

**State/interaction:** Preserve current topology and local transitions. Do not invent map dimensions or teleports from descriptive proximity.

**Acceptance:** Every adopted decorative object respects authored walkability; the Marco remains realm travel's dedicated location.

## Proposed traditions

Offer food before asking for a history; accepting creates no debt. Keep passages clear for people carrying weight. Allow repairs to retain different makers' finishes. Respect silence on porches and in the chapel. Show these customs through a few gestures rather than making every NPC explain them. They introduce no religion, quest condition, consent flag, or entitlement to another person's labor.

## Proposed arrival prose

> Wood smoke reached you before the houses did.
>
> You climbed the last steps with one hand on the stone. Below the lookout, someone shook a cloth from a window. Someone else collected a bowl beside a door. A pot rang twice. Paths descended between roofs and met in the square, where a stone covered in names rose above the benches.
>
> Walls had been patched. Clothes were drying. A narrow bed of earth had been planted beside a house. The wind carried a voice calling someone to eat.
>
> You searched those sounds for Lia before remembering that she had never lived here.
>
> Then you saw the path back to the hill. From the square, your grave was close.

Adapt into short scene beats with viewing time; do not paste a wall of prose into a single dialogue box. The player can recognize the coat and remember Lia without obtaining news of her present life.

## Coding-agent handoff

> Read AGENTS.md, this document, PLANO_REFUGIO_ANDLAR.md, BASE_NARRATIVA.md, and the current scene/campaign source. Identify the requested place record, its actual location ID, existing progression conditions, and whether the requested detail is established or proposed. Implement only the requested narrative/presentation scope using existing scene and event patterns. Preserve walkability, local geography, quest prerequisites, inventory uniqueness, actor placement, and Marco travel independence. Reuse real flags; do not manufacture a new progression framework, residence state, pact rule, or interaction from descriptive prose. Separate player-visible text from production spoilers. Check both initial and relevant progressed states. Report changes, verified conditions, and any asset or exact-layout decisions still missing.

## Verification targets

- Given initial progress, then water, bench, school, and lodging visuals show their unfinished states.
- Given an adopted improvement, then its real milestone controls it on re-entry and loaded saves.
- Given a relocated actor, then only the current authored presence exists.
- Given missing farewell or another actual opening prerequisite, then ANDLAR remains unavailable; Aurel's presence is never added as another requirement.
- Given a visitor or helpful act, then no residence, forgiveness, or pact binding is silently granted.
- Given a public description, then its claims match the observer's actual knowledge.

This document specifies adaptation checks; no executable tests were run by rewriting it. Test screenshots belong only in the project's `screenshots/` directory.
