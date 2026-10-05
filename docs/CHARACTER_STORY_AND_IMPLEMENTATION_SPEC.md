# ARROWFALLEN — Character Story and Implementation Specification

Revision: 2026-10-04. Scope: 26 named/core human characters and existing unnamed supporting roles. Atmosphere: welcoming, marked by losses and secrets. English design documentation does not rename game IDs or change localization. This document changes no code, sprites, dialogue, or pact states.

## Authority and record contract

Continuity follows [BASE_NARRATIVA.md](BASE_NARRATIVA.md), [GUIA_ESCRITA_DEVIN.md](GUIA_ESCRITA_DEVIN.md), [PLANO_CAMPANHA.md](PLANO_CAMPANHA.md), and [CENAS_REVELACAO_E_FINAIS.md](CENAS_REVELACAO_E_FINAIS.md). Current placement and realm travel follow [PLANO_REFUGIO_ANDLAR.md](PLANO_REFUGIO_ANDLAR.md). Combat behavior follows [ENEMY_STORY_AND_IMPLEMENTATION_SPEC.md](ENEMY_STORY_AND_IMPLEMENTATION_SPEC.md) and current executable source, not older turn-based campaign descriptions. Places follow [WORLD_STORY_AND_IMPLEMENTATION_SPEC.md](WORLD_STORY_AND_IMPLEMENTATION_SPEC.md).

**ESTABLISHED:** coordinated role, responsibility, knowledge, and relationship. This does not prove that every proposed scene is implemented. **PROPOSED:** all ages, heights, body designs, clothing, pigments, acting details, and sample lines. Seven years remains a revisable working chronology. Designs do not establish new illnesses, traumatic histories, family ties, crimes, or magic.

Record labels `C01..C26` are documentation references, not runtime keys. Find actual NPC/entity IDs in source before implementation; preserve spelling and accents where data requires them. Reuse existing dialogue, quest, and actor systems rather than translating these headings into a generic schema.

Each sheet contains: continuity/knowledge, personal story, proposed body/face, clothing/materials, hands/props, acting/voice, three small-sprite anchors, and implementation boundaries. Portrait details belong to portraits; do not require every facial feature to be drawn into a tiny sprite.

## Shared presentation and narrative rules

- Everyone here is human. Distinct anatomy and proportions do not create species or moral categories. No face, skin color, body size, or scar identifies guilt.
- Height in centimeters guides concept art and relative proportions; protagonist reference is `1.00`. Do not increase map scale or collision sizes automatically. Exact sprite dimensions, pivots, animation timing, palette values, and asset paths require the actual art pipeline.
- Preserve three silhouette/value anchors per character at native game scale. Color families are proposals; functional interaction and danger colors take precedence.
- Tools belong to activities. A shovel, basket, clipboard, or instrument need not appear in every pose. Unresolved weapon suggestions never override implemented combat.
- Separate public observation from production-only knowledge. Actors cannot discuss facts they have not received. Remember early confessions; do not rediscover known facts after an arbitrary map milestone.
- A gesture can show tension without becoming a forced interaction or new state machine. Use existing presentation events, not a new behavior framework.
- Binding is not inferred from clothing, birthplace appearance, proximity, or visiting the hub. Working outside does not remove an existing seal. Residence changes require actual informed decisions.
- Confession is not forgiveness. Physical defeat is not automatically death. Changed clothes are not absolution. No monstrous transformation can replace human responsibility.
- The voluntary-sacrifice account was internal; accident and departure were different external falsifications. Do not give every uninformed character the same knowledge.

## C01 — Protagonist: Unfinished Work

**Continuity / knowledge:** Name remains open. Wood/instrument artisan, traveler for work, accustomed to a bow. Remembers pursuit and death, initially not every responsible person or the crime's full purpose. Wants his own life and Lia back; tends to accept too much work. His stolen life sustains the pact; manifestation is not full restitution.

**Story:** His coat returns familiarity before explanation: he traces a repair without looking. Practical skill gives him agency again. Helping the town can be chosen without consenting retrospectively to murder.

**Body / face:** Apparent age 30–34; 173 cm; lean, strong forearms, slightly forward shoulders. Warm brown skin; broad nose with slightly lowered tip; asymmetric smile; dark brown heavy-lidded eyes. Black wavy nape-length hair tied low; irregular short beard; one eyebrow rises farther.

**Clothes / hands / props:** Mid-thigh cool-brown coat, one walking flap fastened, pale ochre shoulder patch; raw linen shirt, faded green wool vest, charcoal reinforced trousers. Long fingers, short nails, tool calluses and localized wood traces. Low brown boots, one repaired sole; small tool pouch, practical quiver, lateral bow. Lia's one-handed coat fastening remains the existing commission; no extra magical amulet.

**Acting / voice:** Tests ground before weight transfer; reaches to help before remembering to ask. Concentration, brief crooked humor, upright anger, interrupted longing, hands allowed to rest in affection. Sample: "I can repair this. I just don't want to decide alone again."

**Sprite anchors:** Tall lateral bow; asymmetric coat flap; pale shoulder patch.

**Implementation boundary:** Human manifestation, no skeleton/flame cosmology. Restitution can change step weight/contact only through the authored ending presentation, not an assumed new physics rule.

## C02 — Lia: A Life That Continued

**Continuity / knowledge:** Loved the protagonist; works in construction and repair. Practical, impatient, affectionate, independent. Did not consent to the rite or a later sacrifice. Remains outside and alive. No in-person or live-transmission appearance in the documented maps 1–9; these legacy labels do not define current realm count. Recent verified news belongs to its authored later discovery.

**Story:** She tests a board with two fingers and insists the defect be acknowledged. Waiting did not stop her working or making decisions. Reunion begins with recognition rather than an automatic embrace.

**Body / face:** Present age 39–43; 164 cm; compact, strong legs/shoulders. Reddish-brown skin, broad face, high cheekbones, short chin, small front-tooth gap. Hazel eyes, thick brows, very dark brown jaw-length hair, localized gray temples, partly secured by cloth.

**Clothes / hands / props:** Washed-blue shirt, raw heavy vest, dark rust trousers, lateral apron freeing a knee; unevenly rolled sleeves and lime traces. Broad palms, thick fingers, prominent ring-finger joint. Reinforced ankle boots, short laces; folding rule and two useful pockets. No presumed wedding ring. Terracotta hair strip recurs in old memories without preserving every garment for years.

**Acting / voice:** Leans an ear before answering; contains interruptions imperfectly. Open joy, concrete concern, affection without obligatory smile; allows fatigue and unfinished work privately. Sample: "I heard you. Now let me finish my answer."

**Sprite anchors:** Short hair/terracotta strip; pale rolled sleeves; lateral apron.

**Implementation boundary:** Earlier version has less gray and different shirt, same face structure and checking gesture. Use only authorized memories and reunion; no new early contact or secret seal.

## C03 — Doro: Wood for the Living

**Continuity / knowledge:** Gravedigger/carpenter; arrived after the crime, already bound. Unknowingly broke the grave seal while repairing the funerary house. Learns the murder through information received, not prior participation. Initially works in the forge yard.

**Story:** Broad enough to fill a doorway, careful enough not to strike the frame. He checks a chair's leg before offering it. Wants a bench used by living people and companionship that buys no gratitude.

**Body / face:** 58–64; 181 cm; broad trunk, moderate belly, heavy arms. Dark brown skin, rectangular face, flattened nose tip, small nearly black eyes beneath gray brows. Irregularly shaved head, short silver/black beard; cheek-lifting smile.

**Clothes / hands / props:** Gray linen shirt, brown wool vest, blue-charcoal trousers, short wide waxed-canvas apron with diagonal reinforcement. Separate clean-cloth pocket. Large hands, enlarged joints, precise index finger; wide thick-soled boots. Flat carpenter pencil and wooden measure; shovel stays at work.

**Acting / voice:** Short steps, careful kneeling, support on thigh to rise; patient examination, dry humor, direct worry, quiet resolve. Private scene can show his own future project. Sample: "I made the chair. Sitting down is your choice."

**Sprite anchors:** Broad shoulders; light head/short beard; diagonal apron band.

**Implementation boundary:** No boss armor or sacrificial costume at the final grave. Help never requires preserving the pact. One authored presence, not simultaneous yard/hill/chapel copies.

## C04 — Bento: The Table He Wants to Preside Over

**Continuity / knowledge:** Community cook; voted and helped select the outsider, claiming nobody would search for him. Already bound. Confesses responsibility when asked directly. Genuine hospitality and criminal responsibility coexist.

**Story:** Remembers portions and late arrivals, but often pulls a chair before another person can choose it. His change concerns permission and shared decisions, not losing his ability to feed people.

**Body / face:** 55–61; 168 cm; fat, full belly/arms, firm legs. Medium olive skin, round face, wide nose, light brown eyes, deep radial wrinkles. Short curly gray-brown hair under pale band; thin arched mustache. Fatness never symbolizes greed.

**Clothes / hands / props:** Moss shirt, worn wine vest, square raw-cloth apron, clean repairs and small hem burns, vertical shoulder towel. Broad clean hands, ordinary old heat marks without invented incident. Closed leather clogs with low wooden sole; short ladle, folded cloth, stock key only while actually assigned to him.

**Acting / voice:** Leans to listen, indicates a place with open palm; warm joy, contained objection, searching for allies, quiet shame. Privately recounts portions. Sample: "I set a bowl aside. If you want it, it can stay there."

**Sprite anchors:** Pale square apron; horizontal hair band; shoulder towel.

**Implementation boundary:** After real accountability, change keys, table position, and offering gesture. Do not remove keys early, require tears, or make basic food conditional on forgiveness.

## C05 — Teca: The Right to Close a Curtain

**Continuity / knowledge:** Seamstress, excluded from the decision and opposed it; Aurel's sister in coordinated continuity. Already bound. Starts at the school; caring for beds does not imply permanent lodging placement.

**Story:** Checks fabric strength before promising a blanket or partition. Offers privacy without demanding explanation. Kinship neither makes her responsible for Aurel's act nor authorizes her to speak for others.

**Body / face:** 51–57; 158 cm; narrow torso, broad hips, upright flexible spine. Golden light-brown skin, long face, straight nose with subtle asymmetry, gray-brown eyes, low brows. Black/graying hair in low side knot.

**Clothes / hands / props:** Gray-blue wool dress, short clay overskirt, pale linen cuffs; shawl point secured at waist. Reused near-toned panels, regular stitches. Fine fingers, localized thread pigment/ordinary needle marks. Soft leather shoes, reinforced wool socks; sheathed scissors, thimble inside pocket, no needle in mouth while speaking.

**Acting / voice:** Raises chin when someone decides for her; economical walking, moves bench before asking passage. Calm attention, direct disapproval, eye-narrowing humor, fatigue without smile. Asks before touching/measuring. Sample: "I can adjust the sleeve. Would you like me to do it now?"

**Sprite anchors:** Low side knot; secured shawl point; long blue hem over clay skirt.

**Implementation boundary:** Reused uniforms lose insignia only through their actual quest; students never become soldiers. No priestess costume or compulsory loyalty.

## C06 — Sabela: Space Inside an Order

**Continuity / knowledge:** Protector and prospective school organizer; opposed murder, attempted escape assistance, failed. Already bound. Did not write the pursuit order or execute the rite.

**Story:** Counts exits and people before noticing dinner. Her hand pauses when someone supplies an unplanned answer. That pause can become listening rather than another order.

**Body / face:** 47–53; 176 cm; tall, narrow shoulders, long legs, lean muscle. Deep dark skin, angular face, narrow rounded-tip nose, deep dark eyes, full lower lip. Short backward braids, white hairline strands. Small proposed chin scar establishes no crime-related injury.

**Clothes / hands / props:** Raw wool shirt, short petroleum-blue coat with separate open panels, gray trousers, brown sash. Reinforced cuffs, repaired knees, no invented insignia. Broad short-nailed fingers with graphite/chalk; light mid-height boots. Flat notebook/folder, cord, pencil; no portable arsenal.

**Acting / voice:** Firm steps, whole-body turns, learns to lower organizing hand. Determination, compressed impatience, frank surprise, brief shame, restrained tenderness. Private activity: testing a school chair while still tired. Sample: "I was about to decide. You speak first."

**Sprite anchors:** Height/long legs; separated coat panels; flat lateral folder.

**Implementation boundary:** School props follow its progress. No penitent uniform, invented successful rescue, or reassigned guilt after disclosure.

## C07 — Nilo: An Ear Still Learning

**Continuity / knowledge:** Child at the time of murder; received the official account, never a witness/accomplice. Already bound. Wants instruments and music; enthusiasm is not infantilization.

**Story:** Listens against a wooden soundbox, tests again, and must learn to wait through the final silence before offering another idea. Wants competence and recognition, not responsibility for absolving adults.

**Body / face:** 17–19; 166 cm; long limbs, short trunk, narrow shoulders. Light copper skin, oval face, small nose, wide brown eyes. Dense dark-brown hair, short rear/long front with raised lock; no maturity-signaling artificial beard.

**Clothes / hands / props:** Muted yellow shirt, worn short blue vest, broad front pocket, brown trousers with adjusted cuffs. Good repairs beside one crooked self-made seam. Fine fingers with learning marks; flexible leather shoes/dark toes. Incomplete instrument and wood-scrap bag only contextually, no age-labeling toys.

**Acting / voice:** Still concentration alternates with quick motion; checks another person's reaction, holds answers when remembering to listen. Open smile, frustrated shoulders, proud anticipation, pain without inherited guilt. Sample: "That note came out right. The next one is still thinking."

**Sprite anchors:** Raised hair lock; pale rectangular pocket; narrow lateral instrument/bag.

**Implementation boundary:** Finished instrument changes prop/posture only at its quest milestone; he does not age seven years during play.

## C08 — Aurel: Care Across Another Person's Will

**Continuity / knowledge:** First Keeper, Teca's brother; knew/performed rite, killed, blocked escape after leaders' decision. Already bound. Admits his acts from direct questioning; can still oppose restitution afterward. Maintains funerary markers and has separate presence near the square's Marco; travel never depends on him.

**Story:** Patient maintenance and attention to residents coexist with coercion. He speaks as "we" while needing to own "I." Fear of losing people explains his motive, not innocence or possession.

**Body / face:** 56–62; 178 cm; lean, long chest, strong maintenance arms. Golden-brown skin coordinated with Teca, long face, subtly asymmetric straight nose, gray-brown eyes, clean-shaven. Graying nape-length swept-back hair, visible large ears.

**Clothes / hands / props:** Pearl-gray linen, blue-charcoal below-knee split overcoat/tunic, narrow high collar, horizontal work sash, brown leather cuffs. Washed, hem-worn, locally reinforced. Long jointed fingers, nail-edge oil; narrow reinforced-soled boots, cloth/adjustment tool/local maintenance keys. Existing rite objects gain no new powers.

**Acting / voice:** Raises palm to stop, slow unhesitating steps, repositions inside a passage. Patience, fatigue, brief affection toward Teca, stiff-necked anger, attention to those he fears losing. Changed-state sample: "I cared for this place. That gives me no right to choose for you."

**Sprite anchors:** Narrow high collar; vertical split tunic; swept light hair.

**Implementation boundary:** That line requires actual change, not mandatory initial acceptance. Final staging may secure the hem/expose working arms; preserve human face and agency. Never create a Marco key held by him.

## C09 — Runa: Ask Before Approaching

**Continuity / knowledge:** Hill watcher, already bound; believes received voluntary-sacrifice account, did not choose victim. Gate/lookout presence follows actual progress.

**Story:** Keeps fingers on the gate and watches approaching hands. Fear does not prevent visible doubt. Listening first changes distance and guard, not her moral color palette.

**Body / face:** 26–31; 170 cm; slender, strong legs. Pink-beige skin, sparse freckles, square face, gray-green eyes, short high-bridge nose. Red-brown short single braid, imperfect cropped fringe.

**Clothes / hands / props:** Charcoal shirt, brown leather protection, short dry-green triangular mantle with straw lining, pale gaiters. Repairs near gate friction. Long separated fingers, tall boots, contextual small key bunch. The current bow/ranged encounter takes precedence over the earlier unapproved short-spear art suggestion.

**Acting / voice:** Initially weight back; gaze returns when answered. Caution, disbelief, brief humor about Doro, embarrassment over false account, resolve to permit passage. Off-duty legs extend to relieve the shift. Sample: "I heard a different story. I didn't see it happen."

**Sprite anchors:** Short triangular mantle; low red braid; pale gaiters.

**Implementation boundary:** No prophecy or purity recognition. Preserve explicit nonlethality of her authored duel, not a global human rule.

## C10 — Janda: A Wall That Can Build Doors

**Continuity / knowledge:** Workshop master controls departures, tools, pay after evacuation loss. Exterior, unbound in this sheet; remains workshop-based. Does not know the murder or immediately recognize protagonist.

**Story:** Recognizes exhausted supports and stands as if her body could brace them. Genuine expertise does not justify retaining workers. Peace preserves her competence while limiting control.

**Body / face:** 49–56; 183 cm; very robust, wide back/hips. Deep bronze skin, square full-jawed face, wide nose, small brown eyes, nearly straight brows with resting central crease. Short black hair, white patch above left ear.

**Clothes / hands / props:** Heavy gray shirt with exposed forearms, earth trousers, dark wine sash, two-panel leather apron. Beam-carry shoulder padding, knee dust, strong angular repairs. Short thick hands, close nails, hanging work glove; wide reinforced-toe boots. Existing industrial hammer and short measuring board; no human chains as decoration.

**Acting / voice:** Firm separated feet, inspects defect before speaker, economical motion. Evaluation, objection, brief fear, reluctant respect, fatigue. Private rechecking of a route suggests worry without inventing a new loss. Changed-state sample: "I've seen the route. Now I want to hear from the people using it."

**Sprite anchors:** Very wide shoulders; divided apron; localized white hair patch, hammer contextual.

**Implementation boundary:** Combat pillar fall follows her special damage/reposition helper, not fatal environmental crushing. She keeps craft ability after losing command.

## C11 — Brina: A Small Signature, an Exact Judgment

**Continuity / knowledge:** Excellent artisan seeking authorship; knew Lia before catastrophe and recognizes the commission. No knowledge of murder or current Lia news. Initially exterior; chosen permanent residence may bind.

**Story:** Finds a defect before the buyer and is annoyed the defect exists. Wants a finished piece to be noticed without surrendering its authorship.

**Body / face:** 34–40; 155 cm; short trunk, muscular arms, solid legs. Cool dark skin, full cheeks, tapered chin, wide low-bridge nose, nearly black eyes/short lashes. Close hair sides with high flat top.

**Clothes / hands / props:** Charcoal shirt, gray wool divided skirt/trousers, short rust apron, small pale collar, burnt-yellow apron fastening. Minimal clean repairs, localized metal/oil wear. Precise short fingers, thumb pressure callus, polishing pigment; heavy flat shoes. File and measuring instrument in rigid pocket. Authorship engraving follows quest, no invented family crest.

**Acting / voice:** Inclined inspection neck, quick short steps, eyes turn first. Technical disapproval, contained satisfaction, dry smile, direct offense at erased authorship. Sample: "It works. Just not as well as I wanted."

**Sprite anchors:** High hair block; short rust apron; elbows set outward.

**Implementation boundary:** Hub arrival requires actual residence choice. A different bench does not make her Doro's anonymous assistant.

## C12 — Neco: Learning to Stop

**Continuity / knowledge:** Workshop worker, pay trapped in local credit, likes colleagues but wants another life. Cira's former colleague, not an invented romance. Did not know the couple or crime. Exterior; welcome/binding follows subquest.

**Story:** Reaches for loads without being asked and struggles to treat sitting as more than an interval. Freedom can include liking the people he leaves.

**Body / face:** 28–34; 185 cm; very lean, long neck, pronounced knees/elbows, repeated-work muscle. Medium-brown skin, narrow face, long nose, wide mouth, dark honey eyes. Straight black hair, close rear/side fringe, sparse short mustache, bare chin.

**Clothes / hands / props:** Sand shirt, gray-green high trousers, unequal pale suspenders, short brown vest, sleeves secured on forearms. Worn light fabric with heavy mismatched repairs. Long rough-palmed fingers, trimmed nails; loose boots double-tied at ankles. Work cord and simple bag; no shackles replacing debt explanation.

**Acting / voice:** Crosses arm when fearing another request; hesitation, full laughter, relief, shame at requesting his own time, jaw-forward objection. Private packing distinguishes his possessions. Sample: "I can help tomorrow. Today I said I was leaving."

**Sprite anchors:** Long neck; pale suspenders; dark side fringe.

**Implementation boundary:** Empty hands/relaxed posture can mark time off without new costume. Departure need not imply hatred or inherited guilt.

## C13 — Ema: The Shop's Own Name

**Continuity / knowledge:** Trader/cook; knows Brina and the couple's old first meeting, not rite or Lia's present. Wants independent shop identity. Initially exterior; permanent residence may bind.

**Story:** Moves a pot from an edge without losing her place in a negotiation. Naming the shop is an act of authorship, not a reward owned by a customer.

**Body / face:** 40–46; 160 cm; rounded, little waist definition, agile arms. Golden-brown skin, heart face, rounded nose, almond black eyes, more arched left brow. Curly black hair in two low rear rolls; small mouth, broad open smile.

**Clothes / hands / props:** Indigo blouse, short wide ochre skirt over trousers, sand side-fastened apron/blue pocket. Thick cotton/linen, darkened hem, small kitchen stains. Strong small hands, optional plain copper ring with no marital assumption. Wine leather shoes with repaired strap; hidden coin purse, order book. Crockery stays at counter.

**Acting / voice:** Moves around stall to meet customers at equal height. Calculation, irony, frank joy, disbelief, sustained indignation; privately rewrites potential names. Sample: "You buy the pot. I'll decide the shop's name afterward."

**Sprite anchors:** Two low hair rolls; lateral apron; ochre skirt block.

**Implementation boundary:** Chosen signs/props follow quest. An afternoon in the hub grants no seal; commerce does not grant ownership of her voice.

## C14 — Rute: The Label Before the Question

**Continuity / knowledge:** Market appraiser/adversary; cataloged missing goods and appropriated others' work. Not a participant in murder, exterior by default. Her conflict is possession, not cooking.

**Story:** Can find a stored object quickly; the harm begins when finding, appraising, and owning become the same verb. Change requires identifying the actual owner.

**Body / face:** 52–59; 172 cm; slender, narrow shoulders, long neck. Olive-beige skin, oval long-chin face, small aquiline nose, cool brown eyes; tight high graying brown bun, two mouth-side vertical lines. No permanent evil smile.

**Clothes / hands / props:** Narrow deep-green wool coat, small wine collar, gray dress, replaceable pale cuffs. Hidden hem repair, polished worn elbows, kept front. Fine fingers/inked thumb; narrow soft-black boots. Short pencil, label ribbons, flat case; small reading glasses optional portrait detail.

**Acting / voice:** Weighs a piece, presents the correct label side. Calm assessment, strategic courtesy, challenged indignation, doubt, embarrassment naming owner. Sample: "The receipt exists. I'll check it."

**Sprite anchors:** High narrow bun; forward pale cuffs; narrow green coat.

**Implementation boundary:** Preserve receipt gates and physical crate attack. Loss of command does not mean rags or loss of appraisal skill.

## C15 — Mara: Beauty Need Not Feed Anyone

**Continuity / knowledge:** Tends plants, food, beauty; knew old couple visits, not rite details or current Lia news. Advocates participation/rest. Exterior initially; chosen residence may bind.

**Story:** Invites someone to sit without placing a tool on the bench. Plants can exist because she wants to see them grow; rest requires no productive excuse.

**Body / face:** 62–69; 152 cm; small strong frame, slightly inclined shoulders. Light-brown sun-marked skin, broad round-chin face, small green-brown eyes. Short wavy white hair, still-full dark brows; age is not only fragility.

**Clothes / hands / props:** Cream broad-sleeved blouse, faded-green skirt over short clay work trousers, blue apron/wide pocket; round field hat contextual. Damp worn hem, dry resting parts. Broad knotted hands, short nails with task-local soil. Low boots, trousers above shaft; shallow basket/small pruning tool. No flower crown or healing power.

**Acting / voice:** Slow rise, sure walking, sets bucket down before reply. Quiet pleasure, calm anger, brief irony, attentive sadness. Sample: "That one doesn't give us food. I wanted something beautiful here too."

**Sprite anchors:** Low white hair/round hat; broad cream sleeves; horizontal basket.

**Implementation boundary:** Garden growth follows quest; no costume flowering, nature priestess role, or murder wisdom.

## C16 — Ivo: A Noise He Cannot Hand Over

**Continuity / knowledge:** Reservoir operator monopolizes pumps/gates, sleeps nearby. Knows technical/recent occupation facts, not murder. Exterior/unbound by default; permanent welcome alone may change it.

**Story:** Stops a sentence to identify a sound. Real danger awareness makes accepting others' competence difficult. Delegation changes who is heard, not his technical ability.

**Body / face:** 44–51; 169 cm; broad trunk, short legs, strong arms. Reddish fair skin, pentagonal face, large cold-reddened nose tip, dark-blue eyes. Receding fine brown hair, fuller short chin beard, low wool cap.

**Clothes / hands / props:** Sand shirt, dark-green waxed coat with rigid hem/abdomen fold, lead-gray trousers, dry folded cuffs, neck cloth, localized oil. Flexible callused fingers/worn thumb, high waterproof leather boots. Small wrench, cloth, technical board; no modern dive suit or twenty carried tools.

**Acting / voice:** Raised listening shoulder, two taps before level check; auditory focus, impatience, contained alarm, exhaustion, respect for another's accurate work. Private listening toward pump establishes no diagnosis. Sample: "You heard the same click? Tell me where."

**Sprite anchors:** Low cap; rigid green hem; high boots.

**Implementation boundary:** Channel coordinates and combat gates remain authored. After delegation, put tool down and listen to a person; do not erase competence.

## C17 — Beltran: A Host Who Cannot Leave the Center

**Continuity / knowledge:** Organizes hospitality/performances in the Halls; adversary through concealed hazards and imposed roles. Knew couple's old stays and official departure account, not execution/current Lia. Exterior by default.

**Story:** Remembers names and preferred seats, then finds another function when someone refuses a program role. Hospitality becomes coercion when an empty chair seems a failure to repair.

**Body / face:** 58–65; 175 cm; broad belly, soft shoulders, thin legs. Olive-brown skin, long face, large curved nose, bright brown eyes/high brows. Curly gray rear hair, broad forehead, thick trimmed mustache; no clown caricature.

**Clothes / hands / props:** Cream shirt, wide-tailed knee-length burnt-wine coat, bell sleeve, old-gold sash, black trousers. Velvet only at worn collar/cuffs, repaired wool elsewhere, one mismatched button. Long soft-palmed hands, dull-buckle low-heeled shoes; folded program and pencil, stage props stay on stage.

**Acting / voice:** Advances to welcome, retreats with guest but ends central. Warmth, pride, smile-covering embarrassment, fear of losing place, sincere stopped attention. Sample: "You can watch without helping. I still have a chair."

**Sprite anchors:** Open sleeve; wide wine tails; pale horizontal sash.

**Implementation boundary:** Keep actual shove/gates. Removing coat for inspection work requires scene context, never a theatrical monster transformation or compulsory praise.

## C18 — Cira: A Sad Note Belongs Here Too

**Continuity / knowledge:** Artist, Neco's former workshop colleague; worked wood and began performing. Wants art without compulsory happiness. Not crime witness; exterior by default, resident/visitor by decision.

**Story:** Leaves a crooked note hanging to see who noticed. Recognition is a specific attentive response, not the loudest applause. Relationship with Neco remains collegial unless separately authored.

**Body / face:** 31–37; 171 cm; lean strong back, slightly uneven shoulders. Warm dark-brown skin, long firm-chin face, small brown eyes, broad nose tip. Short rear-wedge textured hair/low sides; optional eyebrow gap has no required trauma.

**Clothes / hands / props:** Muted-plum shirt, short black vest, pale-gray trousers, ordinary blue sash, close cuffs. Precise fingers, woodwork callus traces, soft square-toe repaired thin-soled shoes. Narrow string-box instrument is art proposal pending approved repertoire, not new item/mechanic; no permanent mask or generic bell-covered bard suit.

**Acting / voice:** Tests sound, lifts brow, near-still-mouth humor; attention, nervous irony, heard pleasure, direct irritation, unperformed sadness. Private repetition drops public joke. Sample: "Did you hear the music, or just wait for it to end?"

**Sprite anchors:** Short hair wedge; pale trousers; narrow diagonal instrument.

**Implementation boundary:** Instrument needs asset confirmation. Neither happiness nor performing recolors every garment.

## C19 — Dalva: A Room for the One Who Keeps Rooms

**Continuity / knowledge:** Laundry/lodging worker seeking her own door. Knew couple's old stays/habits, not current Lia news. Exterior/unbound initially; residence is a choice.

**Story:** Folds corners from habit but looks first toward the door she could close when someone promises better lodging. Common need does not make her endlessly available.

**Body / face:** 46–54; 162 cm; strong broad waist, short arms. Golden fair skin, square full-cheek face, small straight nose, green-brown eyes. Thick graying brown hair rolled high behind, not a perfect round bun; broad mouth/concentration lines.

**Clothes / hands / props:** Raw linen blouse, straight heavy-hem smoke-blue dress, washed-gray apron; one side more faded from laundry use, near-matching replaced cuffs. Firm palms, short fingers, worn cuticles. Closed light-brown shoes/thick socks; square hip basket, assigned-room keys. Personal key emphasis follows her chosen room.

**Acting / voice:** Sets down a load before receiving another. Routine calm, explicit fatigue, everyday humor, objection to intrusion, quiet satisfaction closing a door. Sample: "That room belongs to someone. Being out doesn't free the bed."

**Sprite anchors:** Rear hair volume; straight blue hem; close hip basket.

**Implementation boundary:** No displacement of an occupied bed. Private scene can use empty hands and small portrait key without complete costume replacement.

## C20 — Geraldo: The Order That Erased a Journey

**Continuity / knowledge:** Foundation official falsified circulation to record a fictitious departure. Covered up, did not execute murder. Already bound despite work outside. Admits his alteration when asked; Aurel's order never becomes Sabela's order.

**Story:** Straight clothing and a document held against his chest echo the desk. Protecting a record becomes withholding it when another hand reaches to read.

**Body / face:** 53–60; 166 cm; full trunk, short neck, thin arms relative to belly. Light-brown skin, round narrow-chin face, long straight nose, small brown eyes. Short center-parted gray-black hair, clean-shaven; dull oval reading glasses contextual.

**Clothes / hands / props:** Tobacco vest, straw shirt, straight-hem gray coat, dark trousers, pale horizontal collar. Writing-worn cuffs, little knee wear, replaced conserved parts. Fine ink-marked fingers/writing callus; dark repaired-soled shoes. Flat folder/cord; no invented medals or arcane corruption sign.

**Acting / voice:** Shoulders raised, papers before faces; administrative courtesy, hard-mouth irritation, fear, shame, attention upon delivering original. Sample: "The signature is mine. I can explain the order; I won't deny writing it."

**Sprite anchors:** Straight pale collar; front-held folder; low center-parted hair.

**Implementation boundary:** Not keeper of all pact truth. Combat is FUTURE with blockers in enemy specification; withholding-paper acting alone authorizes no attack.

## C21 — Joana: A Fastening and an End to the Day

**Continuity / knowledge:** Warehouse worker saw the couple's final old farewell; wants belongings and a finite shift. Exterior/unbound initially. No current news of Lia.

**Story:** Tests a clasp twice before trusting it. After the shift, reaches for the apron knot; what she does next need not become someone else's service.

**Body / face:** 37–44; 174 cm; athletic, long arms, narrow hips. Deep dark skin, rectangular face, wide nose, amber-brown eyes, thin upper/full lower lip. Textured short high ponytail, clear forehead.

**Clothes / hands / props:** Clay-red shirt, blue-gray trousers, short raw vest, narrow apron ending in two strips. Strap-worn shoulder, reinforced pockets, quickly undone knots. Long strong fingers, short nails, one glove only for loads; fitted short boots. Small baggage list, work rope, contextual key; not owner of all abandoned luggage.

**Acting / voice:** Broad stride, moves speaker/cargo out of circulation. Alert attention, amusement, time-taking impatience, brief remembered longing, completion satisfaction. Sample: "I remember the farewell. Hold this first—the bag is opening."

**Sprite anchors:** Short high ponytail; clay shirt; two apron strips.

**Implementation boundary:** Off-duty apron removal/personal bag follows scene; remembered farewell is not proof of Lia's present state.

## C22 — Silvério: Rank in the Queue

**Continuity / knowledge:** Dispatch supervisor facing real demand, favors former officeholders, wants indispensability. Already bound. Knows transport records, not entire rite or current Lia.

**Story:** Counts crates with a nail against the list. An old name makes him reach for a lower sheet. The queue has rules; the question is who he lets bypass them.

**Body / face:** 61–68; 182 cm; lean with small belly, long legs, bent tall arc. Fair olive skin, narrow hollow-cheek face, large round nose, dark-gray eyes. Sparse close white hair, short central white mustache, large ears/projected chin without caricature.

**Clothes / hands / props:** Long charcoal vest with stepped pockets, pale yellow-gray shirt, brown trousers; coat left at station. Fine wool, polished chest wear, darker reconstructed pockets. Long fingers/flattened counting thumbnail, broad comfortable dark shoes. Small board, cord, work pencil; no magical official seals.

**Acting / voice:** Shifts weight, interrupts by counting, moves quickly to prevent access. Fatigue, helpfulness, evasive glance, precedence anger, relief at shared work. Changed-state sample: "The queue has to apply to people I know as well."

**Sprite anchors:** Bent height; stepped pockets; held list (pencil mainly portrait).

**Implementation boundary:** Accountability changes list access/station position, not face. Future combat remains separate. He is not Janda's blanket prohibition on leaving.

## C23 — Rima: A Name Is Not Permission

**Continuity / knowledge:** Itinerant Necropolis curator, exterior/unbound. Restores identities, sometimes decides memory without consulting family. Knows documents, not original decision. Visiting is not residence.

**Story:** Stops transcribing to ask how a name was spoken. Curiosity pulls her closer; respect asks her to retreat before taking ownership of another person's memory.

**Body / face:** 35–42; 167 cm; medium frame, firm hips, round shoulders. Reddish-brown skin, oval face, wide low-bridge nose, large black eyes, naturally fine brows, broad listening mouth. Shoulder-length wavy black hair partly under short-ended pale-gray scarf.

**Clothes / hands / props:** Slate-blue coat, cream shirt, cool-green trousers, flat reinforced pockets, stone-contact dust. Very broad flat document bag. Medium graphite-tipped fingers, cloth gloves task-only; soft strap-fastened boots. Notebook, pencil, paper wrapping for copies; no decorative bones or unsolicited dossiers on living people.

**Acting / voice:** Presents page to interviewee, leans ear; curiosity, documentary satisfaction, doubt, boundary-crossing shame, authorship resolve. Privately strikes an unsupported interpretation without deleting evidence. Sample: "I can write it down. Do you want others to read it?"

**Sprite anchors:** Short pale scarf; broad flat bag; soft blue coat.

**Implementation boundary:** Traveler luggage remains in hub visits; no prophecy, automatic publication right, or visual seal.

## C24 — Edras: Preserve the Paper, Hide the Hand

**Continuity / knowledge:** Former clerk wrote accidental death knowing it was murder. Already bound even at Necropolis. Admits authorship on direct initial questioning. Different deception from Geraldo's fictitious departure.

**Story:** Genuine paper conservation makes hearing about his false words harder, not less necessary. Change means opening records and correcting authorship, not destroying the archive.

**Body / face:** 67–74; 177 cm; very thin, low shoulders, relatively large hands. Warm gray-beige skin, long face, narrow high nose, light-brown drooping-lid eyes. Straight white nape hair/thin crown, close silver beard; aged, not corpse-like.

**Clothes / hands / props:** Gray linen shirt, faded-brown calf-length coat/wide sleeves, narrow cream sash, carefully darned hem, loose collar, right cuff folded when writing. Long prominent-joint fingers/old side ink; soft leather repaired-smooth shoes. Writing case/document cloth; contextual reading glasses do not replace silhouette distinction.

**Acting / voice:** Lifts page corner with nail; withdraws hand before requested delivery. Careful concentration, pressed-lip unease, shame, quiet challenge, difficult frankness. Sample: "It wasn't an accident. I was the one who put that word there."

**Sprite anchors:** White nape-length hair; wide sleeves; very low brown hem.

**Implementation boundary:** Confession opens hand/drawer, not youth or absolution. No combat implementation implied by a guarded document; future sheet governs that work.

## C25 — Lena: Safety Must Answer to Someone

**Continuity / knowledge:** Frontier station supervisor, exterior/unbound. Worked with Lia recently; gives verifiable information before negotiation. Safety has become operational monopoly.

**Story:** Checks a latch with a foot nearby and watches another person's hand even during disagreement. Real risk does not justify deciding for the whole team.

**Body / face:** 38–45; 179 cm; athletic, similar hip/shoulder width, strong jaw. Dark-brown skin, broad-forehead triangular face, short wide nose, black eyes/straight upper lids. Compact high textured bun, subtle front gray; distinct from Rute's narrow tight bun.

**Clothes / hands / props:** Sand shirt, fitted short dark-blue coat, gray-ochre trousers, rust neck cloth, reinforced knees, secured sleeves, localized lime. Broad strong-grip hands, gloves stored in conversation; mid-height gripping boots. Contextual technical tool and inspection sheet. Authority alone does not invent a weapon.

**Acting / voice:** Quick walk, open-hand danger indication. Dry attention, irritation, immediate care, demonstrated doubt, trust in competent work. Private rechecking becomes seeking another verifier. Sample: "She worked here. I'll show you the record. We can discuss the latch afterward."

**Sprite anchors:** Firm height; compact high bun; short blue coat.

**Implementation boundary:** Agreement opens circulation/shared position while keeping caution. Lia news never becomes a combat prize; future station weapon remains unresolved.

## C26 — Calo: Leave the Measurement and the Name

**Continuity / knowledge:** Visiting maintenance technician, unbound, sleeps where work ends. Knows parts, not prior murder; learns pact from an appropriate source. Wants completed work and credited authorship.

**Story:** Measures discarded wood twice before signing. Tools leave a crookedly altered coat cleanly. Confidence with a solution turns less fluent when requesting recognition.

**Body / face:** 29–36; 157 cm; compact, short neck, solid forearms. Light olive skin, round small-chin face, long fine-tip nose, honey-brown eyes. Short untidy wavy brown hair with forehead lock; short jaw-outline beard.

**Clothes / hands / props:** Pale-gray shirt, short off-center gray-green jacket, muted-brown trousers; firm cloth, useful-width repairs, hand-set hem. Low lateral oval bag; thick short fingers, index graphite, thumb checks clearance. Low soft-soled boots. Rule, pencil, task tool; rolled luggage stays at rest, not every pose.

**Acting / voice:** Works close, abruptly raises face when called. Focus, pride, practical humor, denied-credit irritation, joy at correct citation. Private check of signature, not autographing everything. Sample: "The piece is ready. Put my name on the plan too."

**Sprite anchors:** Compact short stature; short diagonal fastening; lateral oval bag.

**Implementation boundary:** Visitor remains unbound. Existing stable plan continues its function when he leaves. No aphoristic pact wisdom derived from technical work.

## Existing supporting roles — proposed differentiation

These roles exist in `src/campaign_lore.lua`. Do not invent names, relationships, biographies, additional residents, or new appearances in scenes from this table. Supporting actors require their real authored placements; binding needs separately established residence/welcome.

| Existing role | Proposed body, clothing, and anchors | Acting boundary |
|---|---|---|
| Refuge elder | 75–85, short/thin, dark skin, sparse white hair; knee-length sand coat, ordinary cane | Sits sideways leaving room; attentive, not an oracle |
| Washerwoman | 35–50, robust, copper skin, rear hair roll; folded pale sleeves, blue skirt, pale apron; horizontal cloth | Finishes hanging before reply; may refuse another load |
| Carrier | 25–40, medium height/broad chest, fair olive skin, short black beard; canvas shoulder pad/wide strap | Sets load down to talk; has rest as well as work |
| Woodcutter | 40–60, tall/strong, brown skin, short textured hair; straight gray coat, pale wrist band | Checks/puts tool away; axe appears only in work context |
| Refuge child | 7–10, short, brown skin, short curls; ochre shirt, blue wide-cuffed trousers | Runs, stops to inspect a specific task; no inherited guilt/revelation |
| Workshop woman | 30–45, tall/thin, low straight-hair braid; clay shirt, short pale apron | May want to stay without endorsing coercion |
| Workshop man | 40–55, short/robust, shaved head; square green vest/dark sleeves | May want to leave without hating colleagues |
| Market guards | Two distinct adults: tall short cloak versus short wide vest; distinct skin/hair | Shared function, separate bodies; announce conflict without brutality caricature |
| Trader | 50–65, medium frame, white textured hair under cloth; blue collar, gray divided skirt, narrow bag | Checks quality/price; not automatically guilty of Rute's appropriation |
| Maintenance crew | Varied heights/arm proportions, secured cuffs, waterproof boots, shared team accents | Consult/divide loads; no copies of Ivo |
| Channel voice | Currently text-only; no physical design required | A future body needs separate identity decision; no automatic ghost |
| Halls assistant | 20–35, medium/slim, low tied long hair; cream shirt, short wine cloth sash | Can disagree with host; knows staging |
| Audience | Mixed ages/proportions and simple value-separated clothes; at least one empty-handed seated person | Talk, yawn, listen; no synchronized smiles |

## Cross-character art checks

- Doro/Bento: broad patient rectangle versus rounded moving apron; offered support versus prematurely pulled chair. Hospitality does not equal shared responsibility.
- Teca/Dalva: side knot and diagonal shawl versus rear hair and straight hem/hip basket. Touch/privacy boundaries differ from workload/room boundaries.
- Sabela/Janda/Lena: long legs/flat folder versus wide trapezoid/hammer versus short coat/high compact bun. Protective competence has different control problems.
- Brina/Calo: short rust apron/high hair block versus diagonal jacket/oval bag. Both want authorship, not interchangeable artisan portraits.
- Rute/Geraldo/Silvério/Edras: labels appropriate, departure records conceal, queues privilege, death records falsify. Use narrow cuffs, closed folder block, stepped pockets, and long wide sleeves respectively.
- Nilo/Cira: demonstration-seeking apprentice versus attention-testing performer. Cira is not made his mother; enthusiasm is not childishness.
- Protagonist/Lia: reflexively taking work versus demanding a complete answer. Intimacy appears in the coat fastening, a checked board, and accepted touch rather than matching costumes.

## State adaptation and ending boundaries

Keep separate questions: what the actor knows, what they admit, what responsibility they accept, where they are, and whether they are bound. These are authoring concerns to map onto existing state, not instructions to create five new subsystems.

Bento loses stock authority/keys only when accountability actually transfers it. Aurel may admit murder before the final encounter and still oppose restitution. Doro and uninformed residents cannot learn again what a previous scene already disclosed. Visitors without seals do not die alongside the bound simply because they share the frame. The individual ending's reunion with Lia is real; art cannot erase its cost. Physical boss victory selects no ending or death automatically.

Amâncio, Odete, Guardião dos Ecos, Demolidor da Câmara, and Regente de Âmbar belong to legacy arcade `src/lore.lua`. They are excluded from this human cast to avoid importing its earlier cosmology. Reusing art is a separate asset decision; importing their histories requires a separate narrative proposal.

## Production and coding-agent handoff

**Narrative stage:** Adopt requested story/voice material while preserving knowledge, agency, gates, and existing responsibilities. Sample lines are proposals, not new flags or automatic triggers.

**Asset stage:** Choose the requested record's appearance as one coherent design. Resolve native sprite/portrait sizes, palette, pivots, animation set, prop variants, and asset names from the current pipeline. Detailed age/height proposals do not create new chronology. Ordinary wear/calluses do not require invented trauma.

**Integration stage:** Use existing actor, dialogue, event, and scene structures. Match authored presence and progression. Combat integration consults the enemy specification; do not treat clothing, posture, or an unconfirmed prop as an attack.

Copyable agent prompt:

> Read AGENTS.md, CHARACTER_STORY_AND_IMPLEMENTATION_SPEC.md, the relevant campaign/scene source, and referenced continuity documents. Identify the requested character's real ID, established role, current knowledge, pact/residence status, placement conditions, and authorized production stage. Preserve three sprite anchors and the proposed material/body distinctions when making assets. Map narrative updates to existing dialogue beats and flags; never infer guilt, consent, magic, binding, romance, or attacks from appearance. Use current combat source and enemy specification for hostile encounters. Keep production spoilers out of initial descriptions. Verify initial and relevant progressed/returned states, including unique placement and props whose ownership changes. Report changes, verification, and unresolved asset or narrative decisions.

## Acceptance cases

- Given an initial encounter, then dialogue reveals only knowledge the actor actually holds, while direct questions receive established admissions rather than artificial suspense.
- Given an adopted character design, then its three anchors remain distinct at native scale; portrait details do not require larger map cells.
- Given a moved or visiting NPC, then only its authored current presence exists and visiting alone never grants a seal.
- Given changed ownership, instrument completion, or room assignment, then props follow the actual milestone on re-entry/load.
- Given a human opponent, then appearance never overrides current attack, item gates, or explicit lethal/nonlethal policy.
- Given a confession, then clothes/posture can change without automatically granting forgiveness, competence loss, or ending selection.
- Given Lia-related information, then old memories remain distinct from current verified news, and Lena provides her news before bargaining.

Documentation rewriting alone does not verify the executable game. For asset or scene implementation, run appropriate checks and save captures only to `screenshots/`.
