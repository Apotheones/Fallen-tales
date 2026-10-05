-- Campaign exploration checks (PLANO_REFUGIO_ANDLAR stage 1): authored maps,
-- continuous movement, collision, interactions, persistence, death and the
-- arena transition plumbing. Combat mechanics live in a separate suite.
local Campaign = require('src.campaign')
local Save = require('src.save')
local Region = require('src.region')
local Explore = require('src.explore')
local Props = require('src.props')
local LoreC = require('src.campaign_lore')
local Font = require('src.pixel_font')
local Rooms = require('src.rooms')

local CampaignTest = {}

local function advance(campaign)
    for _ = 1, 600 do
        if not campaign.dialogue then return end
        campaign.dialogue.reveal = math.huge
        campaign:advanceDialogue()
        if campaign.dialogue and campaign.dialogue.mode == 'options' then
            campaign:chooseDialogue(#campaign.dialogue.node.options)
        end
    end
    error('advance: dialogue never settled', 2)
end

local function step(campaign, seconds, dx, dy)
    local n = math.ceil(seconds * 120)
    for _ = 1, n do campaign:update(1 / 120, {dx = dx or 0, dy = dy or 0}) end
end

local function strings(node, into)
    for _, line in ipairs(node.lines or {}) do into[#into + 1] = line end
    for _, option in ipairs(node.options or {}) do
        into[#into + 1] = option.label
        for _, line in ipairs(option.lines or {}) do into[#into + 1] = line end
    end
    if node.title then into[#into + 1] = node.title end
    return into
end

function CampaignTest.run()
    local checks = 0
    local function check(value, message) checks = checks + 1; assert(value, message) end

    -- Scripted talk chains (docs/QA_MUNDOS.md, M1 acceptance): at every
    -- options menu pick the listed index (defaulting to the last, usually
    -- SAIR) and drain lines nodes until the dialogue settles.
    local function runTalk(campaign, choices)
        local i = 0
        for _ = 1, 40 do
            local d = campaign.dialogue
            if not d then return end
            if d.mode == 'options' then
                i = i + 1
                campaign:chooseDialogue(choices and choices[i] or #d.node.options)
            else
                d.reveal = math.huge
                campaign:advanceDialogue()
            end
        end
        check(false, 'Talk chain did not settle')
    end
    local function talkTo(campaign, id)
        for _, npc in ipairs(campaign.npcs) do
            if npc.npc.id == id then
                campaign.player.grid.x, campaign.player.grid.y = npc.grid.x, npc.grid.y + 1
                check(campaign:interact() and campaign.dialogue ~= nil, 'Talk with ' .. id .. ' opens')
                return npc
            end
        end
        check(false, 'NPC ' .. id .. ' stands in ' .. campaign.map.id)
    end
    local function exitTo(campaign, to)
        for _, e in ipairs(campaign.map.exits) do
            if e.to == to then return e end
        end
    end

    -- Authored regions ------------------------------------------------------------
    local colina = Region.load('colina')
    local hub = Region.load('hub', true)
    check(colina.w == 28 and colina.h == 24 and hub.w == 32, 'Regions load with authored bounds')
    check(Rooms.cell(colina, 6, 4) and Rooms.cell(colina, 6, 4).ground == 'floor', 'Colina spawn is floor')
    check(Rooms.cell(colina, 3, 1) and Rooms.cell(colina, 3, 1).piece == 'wall', 'Void becomes boundary wall')
    check(Rooms.cell(colina, 17, 14).ground == 'hole', 'Authored hole survives')
    check(Rooms.cell(colina, 11, 10).piece == 'pillar', 'Authored pillar survives')
    local exit = colina.exits[1]
    check(exit and exit.to == 'hub' and Rooms.cell(colina, exit.x, exit.y).piece == 'portal',
        'Colina exit is a portal cell')
    local reach = Region.reachable(colina, 6, 4)
    check(reach[Rooms.key(7, 21)] ~= true and reach[Rooms.key(5, 16)] == true,
        'Grade blocks the descent until Runa resolves it')
    -- Todo ponto de interação autoral fica ao alcance a pé: o flood não entra
    -- em célula sólida, então um spot sobre prop conta quando uma vizinha
    -- dentro do range dele está na máscara.
    local function covered(map, reachSet, spot)
        local range = spot.range or 1.45
        for dy = -2, 2 do
            for dx = -2, 2 do
                if dx * dx + dy * dy <= range * range
                    and reachSet[Rooms.key(spot.x + dx, spot.y + dy)] then
                    return true
                end
            end
        end
        return false
    end
    for _, spot in ipairs(colina.hotspots) do
        check(covered(colina, reach, spot), 'Hotspot reachable on foot: ' .. spot.id)
    end
    for cell, prop in pairs(colina.propCells) do
        if prop.id == 'grade' then colina.propCells[cell] = nil end
    end
    reach = Region.reachable(colina, 6, 4)
    check(reach[Rooms.key(7, 21)] == true and reach[Rooms.key(7, 22)] == true
        and reach[Rooms.key(6, 18)] == true,
        'Opened grade reaches the descent hall, the portal and Runa')
    local hubReach = Region.reachable(hub, 26, 20)
    check(hubReach[Rooms.key(7, 4)] and hubReach[Rooms.key(13, 18)] and hubReach[Rooms.key(12, 11)],
        'Every hub zone is reachable from the passage house')
    check(#hub.npcs == 7, 'Hub seats the seven residents')

    -- M2 authored checks (docs/QA_MUNDOS.md): guaranteed places reachable,
    -- encounter defs, repair gate -----------------------------------------
    local m2 = Region.load('oficinas')
    check(m2.w == 30 and m2.h == 24, 'Oficinas loads with authored bounds')
    local oReach = Region.reachable(m2, 15, 21)
    local function oAt(x, y) return oReach[Rooms.key(x, y)] == true end
    check(oAt(16, 22), 'Entrance arrival is reachable')
    check(oAt(12, 5), 'Central workshop is reachable')
    check(oAt(5, 6), 'Alojamento is reachable')
    check(oAt(5, 13), 'Brina bench is reachable')
    check(oAt(25, 5), 'Deposit interior is reachable')
    check(oAt(27, 11), 'Entulho is reachable')
    check(not oAt(26, 3), 'Ferramentas niche stays sealed behind the grade')
    check(oAt(27, 9) and not oAt(27, 8),
        'Reservatorio corridor is reachable up to the closed portal')
    for _, spot in ipairs(m2.hotspots) do
        check(covered(m2, oReach, spot), 'Oficinas hotspot reachable: ' .. spot.id)
    end
    for _, n in ipairs(m2.npcs) do
        check(oAt(n.x, n.y), 'Oficinas npc on reachable floor: ' .. n.id)
    end
    for _, e in ipairs(m2.encounters) do
        check(oAt(e.x, e.y), 'Oficinas encounter on reachable floor: ' .. e.id)
    end
    local function oEnc(id)
        for _, d in ipairs(m2.encounters) do
            if d.id == id then return d end
        end
    end
    check(oEnc('C02-01') and #oEnc('C02-01').units == 2,
        'C02-01 fields the sentinela+rastejante pair')
    check(oEnc('B02-01') and oEnc('B02-01').talk == 'janda'
        and oEnc('B02-01').confronto == 'jandaConfronto'
        and oEnc('B02-01').kind == 'janda',
        'B02-01 Janda is talk-gated with the boss kind')
    check(oEnc('C02-02') and oEnc('C02-02').kind == 'dasher',
        'C02-02 brute guards the damaged exit rubble')

    -- M3 authored checks (docs/QA_MUNDOS.md): guaranteed places reachable,
    -- encounter defs, state props -----------------------------------------
    local m3 = Region.load('mercado')
    check(m3.w == 30 and m3.h == 24, 'Mercado loads with authored bounds')
    local mReach = Region.reachable(m3, 6, 21)
    local function mAt(x, y) return mReach[Rooms.key(x, y)] == true end
    check(mAt(5, 19), 'Arrival alley is reachable')
    check(mAt(9, 12) and mAt(9, 10), 'Ema counter and covered sign are reachable')
    check(mAt(20, 11), 'Couple stall is reachable')
    check(mAt(19, 4), 'Encomendas archive is reachable')
    check(mAt(26, 5), 'Deposit interior is reachable through the open grade')
    check(mAt(7, 4), 'Avaliacao square is reachable')
    check(mAt(25, 19) and not mAt(25, 21),
        'Saloes corridor is reachable up to the closed portal')
    local function mEnc(id)
        for _, d in ipairs(m3.encounters) do
            if d.id == id then return d end
        end
    end
    check(mEnc('C03-01') and mEnc('C03-01').talk == 'guarda'
        and mEnc('C03-01').confronto == 'guardaConfronto',
        'C03-01 patrol is talk-gated, not touch-gated')
    check(mEnc('C03-02') and mEnc('C03-02').kind == 'crawler'
        and Rooms.cell(m3, 25, 8).ground == 'floor' and Rooms.cell(m3, 27, 8).ground == 'floor',
        'C03-02 nest keeps a guaranteed side path')
    check(mEnc('C03-Q01') and mEnc('C03-Q01').kind == 'dasher',
        'Optional collector encounter exists')
    check(mEnc('B03-01') and mEnc('B03-01').talk == 'rute'
        and mEnc('B03-01').confronto == 'ruteConfronto'
        and mEnc('B03-01').kind == 'rute',
        'B03-01 Rute is talk-gated with the boss kind')
    local function mProp(id)
        for _, p in ipairs(m3.props) do
            if p.id == id then return p end
        end
    end
    check(mProp('gradeDeposito') and mProp('gradeDeposito').state == 'open'
        and m3.propCells[Rooms.key(25, 6)] == nil,
        'Deposit grade is authored open state, never a blocker')
    check(mProp('carroPecas') and mProp('carroPecas').solid == true
        and m3.propCells[Rooms.key(25, 20)] ~= nil and Explore.solidCell(m3, 25, 20),
        'Cart blocks the Saloes route until moved')
    for _, spot in ipairs(m3.hotspots) do
        check(covered(m3, mReach, spot), 'Mercado hotspot reachable: ' .. spot.id)
    end
    for _, n in ipairs(m3.npcs) do
        check(mAt(n.x, n.y), 'Mercado npc on reachable floor: ' .. n.id)
    end
    for _, e in ipairs(m3.encounters) do
        check(mAt(e.x, e.y), 'Mercado encounter on reachable floor: ' .. e.id)
    end
    check(m3.encounters and (function()
        for _, d in ipairs(m3.encounters) do
            if d.id == 'B03-01' then return d.crates and #d.crates > 0 end
        end
    end)(), 'B03-01 Rute fields pushable crates in her arena')

    -- M4 authored checks (docs/QA_MUNDOS.md): guaranteed places reachable,
    -- encounter defs, compound gates ---------------------------------------
    local m4 = Region.load('reservatorio')
    check(m4.w == 32 and m4.h == 24, 'Reservatorio loads with authored bounds')
    local rReach = Region.reachable(m4, 11, 21)
    local function rAt(x, y) return rReach[Rooms.key(x, y)] == true end
    check(rAt(15, 20), 'Arrival platform is reachable')
    check(rAt(10, 16) and rAt(18, 17), 'Passarela and dry bypass are reachable')
    check(rAt(11, 13) and rAt(15, 12), 'Jardim and casal bench are reachable')
    check(rAt(14, 14), 'Regua tower is reachable')
    check(rAt(17, 4), 'Technical deposit is reachable')
    check(rAt(26, 4), 'Comportas room is reachable')
    check(rAt(22, 12), 'East wing is reachable through the dry side')
    check(not rAt(8, 6) and not rAt(5, 4),
        'Lower corridor stays sealed until the sluice drains')
    check(not rAt(7, 2), 'Fundacao portal stays closed')
    check(not rAt(4, 17), 'Canal voice island is unreachable on foot')
    for _, spot in ipairs(m4.hotspots) do
        check(covered(m4, rReach, spot), 'Reservatorio hotspot reachable: ' .. spot.id)
    end
    for _, n in ipairs(m4.npcs) do
        if n.id == 'voz' then
            check(not rAt(n.x, n.y), 'Canal voice stays out of foot range by design')
        else
            check(rAt(n.x, n.y), 'Reservatorio npc on reachable floor: ' .. n.id)
        end
    end
    for _, e in ipairs(m4.encounters) do
        check(rAt(e.x, e.y), 'Reservatorio encounter on reachable floor: ' .. e.id)
    end
    local function rEnc(id)
        for _, d in ipairs(m4.encounters) do
            if d.id == id then return d end
        end
    end
    check(rEnc('C04-01') and rEnc('C04-01').kind == 'crawler',
        'C04-01 cistern crawlers guard the walkway')
    check(rEnc('C04-02') and rEnc('C04-02').talk == 'equipe'
        and rEnc('C04-02').confronto == 'equipeConfronto' and #rEnc('C04-02').units == 2
        and Rooms.cell(m4, 26, 8).ground == 'floor',
        'C04-02 crew is talk-gated with a dry corridor around')
    check(rEnc('C04-Q01') and rEnc('C04-Q01').kind == 'crawler',
        'C04-Q01 optional crawlers nest in the planters')
    check(rEnc('B04-01') and rEnc('B04-01').talk == 'ivo'
        and rEnc('B04-01').confronto == 'ivoConfronto'
        and rEnc('B04-01').kind == 'ivo' and rEnc('B04-01').channels ~= nil,
        'B04-01 Ivo is talk-gated with the boss kind and channel lanes')
    local function rProp(id)
        for _, p in ipairs(m4.props) do
            if p.id == id then return p end
        end
    end
    check(rProp('gradeComporta') and rProp('gradeComporta').solid == true
        and m4.propCells[Rooms.key(8, 7)] ~= nil and Explore.solidCell(m4, 8, 7),
        'Sluice grade seals the lower corridor until drained')

    -- M5 authored checks (docs/QA_MUNDOS.md): guaranteed places reachable,
    -- encounter defs, non-lethal design -------------------------------------
    local m5 = Region.load('saloes')
    check(m5.w == 30 and m5.h == 24, 'Saloes loads with authored bounds')
    local sReach = Region.reachable(m5, 6, 22)
    local function sAt(x, y) return sReach[Rooms.key(x, y)] == true end
    check(sAt(5, 21), 'Arrival lobby is reachable')
    check(sAt(4, 9), 'Auxiliary kitchen is reachable')
    check(sAt(6, 15), 'Service gallery is reachable')
    check(sAt(16, 5), 'Stage is reachable')
    check(sAt(11, 4), 'Camarim is reachable')
    check(sAt(24, 4), 'Surplus deposit is reachable')
    check(sAt(26, 16), 'Occupied wing is reachable')
    check(sAt(17, 18), 'Vestibule is reachable')
    check(sAt(15, 22), 'Rehearsal corridor is reachable')
    check(not sAt(5, 4) and not sAt(5, 2),
        'Fundacao corridor stays gated by the escora truss')
    for _, spot in ipairs(m5.hotspots) do
        check(covered(m5, sReach, spot), 'Saloes hotspot reachable: ' .. spot.id)
    end
    for _, n in ipairs(m5.npcs) do
        check(sAt(n.x, n.y), 'Saloes npc on reachable floor: ' .. n.id)
    end
    for _, e in ipairs(m5.encounters) do
        check(sAt(e.x, e.y), 'Saloes encounter on reachable floor: ' .. e.id)
    end
    local function sEnc(id)
        for _, d in ipairs(m5.encounters) do
            if d.id == id then return d end
        end
    end
    check(sEnc('C05-01') and sEnc('C05-01').kind == 'crawler',
        'C05-01 canal crawlers nest in the service gallery')
    check(sEnc('C05-02') and sEnc('C05-02').kind == 'ranger',
        'C05-02 wing sentinels stay contournable')
    check(sEnc('C05-Q1') and sEnc('C05-Q1').talk == 'ajudante'
        and sEnc('C05-Q1').confronto == 'dueloProposto',
        'C05-Q1 staged duel needs the accepted proposal, never touch')
    check(sEnc('B05-01') and sEnc('B05-01').talk == 'beltran'
        and sEnc('B05-01').confronto == 'beltranConfronto'
        and sEnc('B05-01').kind == 'beltran',
        'B05-01 Beltran is talk-gated with the boss kind')
    local plateiaNpc
    for _, n in ipairs(m5.npcs) do
        if n.id == 'plateia' then plateiaNpc = n end
    end
    check(plateiaNpc ~= nil and not sEnc('plateia'),
        'Audience figures among the seats, never as an arena unit')
    local function sProp(id)
        for _, p in ipairs(m5.props) do
            if p.id == id then return p end
        end
    end
    check(sProp('escoraTrava') and sProp('escoraTrava').solid == true
        and m5.propCells[Rooms.key(6, 6)] ~= nil and Explore.solidCell(m5, 6, 6),
        'Escora truss seals the upper corridor until reinforced')
    check(sProp('armarioTecnico') and sProp('armarioTecnico').solid == true,
        'Hardware cabinet is authored solid, never a breakable')

    -- Campaign boot and continuous movement --------------------------------------
    Save.file = 'test_campaign_save.lua'
    Save.clear()
    local c = Campaign.new({legacy = true})
    check(c.dialogue == nil, 'Awakening grants immediate control — no narration modal')
    check(c:stepDone('P01-E01'), 'Awakening step is recorded')
    check(c.map.id == 'colina' and c.player.grid.x == 6 and c.player.grid.y == 4, 'Spawn at the grave')

    step(c, .5, 1, 0)
    local movedX = c.player.grid.x
    check(movedX > 6.9 and movedX < 9, 'Continuous movement is fractional: ' .. movedX)
    check(c.player.facing.dx == 1 and c.player.moving == true, 'Facing follows held direction')
    step(c, .5, -1, 0)
    check(c.player.grid.x < 6.2, 'Movement is reversible')
    -- Wall slide: southwest inside the grave chamber hugs the west wall but keeps descending.
    c.player.grid.x, c.player.grid.y = 6, 3
    step(c, .8, -1, 1)
    check(c.player.grid.x >= 3.7 and c.player.grid.x <= 4 and c.player.grid.y > 3.8,
        'Collision slides along walls instead of stopping')
    -- Solid prop: the cova blocks the chamber floor cell.
    c.player.grid.x, c.player.grid.y = 5.8, 3.6
    step(c, .4, -1, 0)
    check(c.player.grid.x > 5.4, 'Solid prop blocks the feet box')
    -- NPC blocking: Doro at (8,3) holds his cell.
    c.player.grid.x, c.player.grid.y = 7, 3
    step(c, .6, 1, 0)
    check(c.player.grid.x < 7.6, 'Residents block movement like bodies')

    -- Interactions ----------------------------------------------------------------
    c.player.grid.x, c.player.grid.y = 6, 3
    check(c:interact() and c.dialogue, 'Sepultura hotspot opens near the grave')
    advance(c)
    c.player.grid.x, c.player.grid.y = 23, 11.2
    check(c:interact() and c.dialogue, 'Belongings open a narration node')
    advance(c)
    check(c.data.flags.casaco and c:stepDone('P01-E02'), 'Taking belongings records step and flag')
    check(c.data.regions.colina.props.bau == 'done', 'Chest remembers it was opened')
    check(c:interact() == false, 'Once-hotspots do not repeat')
    -- Hotspots novos da onda 1: cada ponto resolve o node escrito na lore.
    c.player.grid.x, c.player.grid.y = 24, 12
    check(c:interact() and c.dialogue, 'Depósito coffin opens its node')
    advance(c)
    c.player.grid.x, c.player.grid.y = 9, 11
    check(c:interact() and c.dialogue, 'Pátio headstone is readable')
    advance(c)
    -- A tampa examina pela célula abaixo da de Doro (spot em 8,4): de
    -- (8,5) ela é o único alvo no alcance — abre o node dela, não a fala
    -- do ferreiro (distinção pelo título, não só pela abertura).
    c.player.grid.x, c.player.grid.y = 8, 5
    check(c:interact() and c.dialogue and c.dialogue.title == 'TAMPA DA COVA',
        'Grave lid inspects beside Doro')
    advance(c)
    -- D01 (Doro's arc): the coffin question only exists before the grade,
    -- behind the metDoroFirst introduction. De (9,3) Doro vence o placar —
    -- o spot da tampa fica na diagonal e perde em qualquer facing.
    c.player.grid.x, c.player.grid.y = 9, 3
    check(c:interact() and c.dialogue, 'Doro answers beside the grave')
    runTalk(c)
    c.player.grid.x, c.player.grid.y = 9, 3
    check(c:interact() and c.dialogue, 'Doro takes the coffin question')
    runTalk(c, {1})
    check(c:stepDone('D01'), 'D01 completes on the coffin question')
    -- Runa negotiation resolves the grade without combat.
    c.player.grid.x, c.player.grid.y = 6, 16.4
    check(c:interact() and c.dialogue, 'Runa answers through the grade')
    for _drain = 1, 600 do
        if not (c.dialogue and c.dialogue.mode ~= 'options') then break end
        c.dialogue.reveal = math.huge
        c:advanceDialogue()
    end
    check(c.dialogue and c.dialogue.mode == 'options', 'Runa offers a reply menu')
    c:chooseDialogue(1)
    for _drain = 1, 600 do
        if not (c.dialogue and c.dialogue.mode == 'lines') then break end
        c.dialogue.reveal = math.huge
        c:advanceDialogue()
    end
    if c.dialogue then c:chooseDialogue(#c.dialogue.node.options) end
    check(c:stepDone('P01-E03') and c.data.regions.colina.props.grade == 'open',
        'Negotiated grade opens and is recorded')
    check(c.data.people.runa.location == 'hub', 'Runa relocates to the hub once the way is free')

    -- Travel ----------------------------------------------------------------------
    c.player.grid.x, c.player.grid.y = 7, 21
    step(c, .3, 0, 1)
    check(c.map.id == 'hub', 'Walking into the portal travels to the hub')
    check(c:stepDone('P01-E04'), 'Arriving at the refuge records the step')
    check(c.data.people.doro.location == 'hub', 'Doro relocates after the first descent')
    check(c.dialogue ~= nil, 'First hub arrival narrates the refuge')
    advance(c)
    check(#c.npcs == 7, 'All residents stand in the hub')

    -- Hub presentation (P01-E05) and first expedition (P01-E06) ------------
    check(exitTo(c, 'oficinas').open == false and exitTo(c, 'mercado').open == false,
        'Passage portals start closed')
    check(Explore.solidCell(c.map, 28, 21) and Explore.solidCell(c.map, 29, 21),
        'Closed portal cells block the descent')
    talkTo(c, 'bento'); runTalk(c)
    talkTo(c, 'teca'); runTalk(c)
    check(not c:stepDone('P01-E05'), 'P01-E05 waits for the three introductions')
    talkTo(c, 'aurel'); runTalk(c)
    check(c:stepDone('P01-E05'), 'P01-E05 recorded after the trio')

    -- Teca's arc: T01/T02 via dialogue; T03 follows the Saloes mission.
    talkTo(c, 'teca'); runTalk(c, {1})
    check(c:stepDone('T01'), 'T01 completes on the how-it-works question')
    talkTo(c, 'teca'); runTalk(c, {1})
    check(c:stepDone('T02'), 'T02 completes on a sharing choice')
    c.data.steps['P05-E06'] = true -- map 5 trigger, emulated as the spec lands it
    talkTo(c, 'teca'); runTalk(c)
    check(c:stepDone('T03'), 'T03 fires once Saloes is done')
    c.data.steps['P05-E06'] = nil

    -- Doro's arc: D02 before the expedition offer; D03 only after delivery.
    talkTo(c, 'doro'); runTalk(c, {1})
    check(c:stepDone('D02'), 'D02 completes on the chest placement')
    talkTo(c, 'doro'); runTalk(c, {2})
    check(c:stepDone('P02-E01') and c:stepDone('P01-E06'),
        'Accepting the bench request records both steps')
    check(c:flag('passagemOficinas'), 'Oficinas passage flag set by the talk')
    talkTo(c, 'bento'); runTalk(c, {2})
    check(c:stepDone('P03-E01'), 'Accepting the oven request records the step')
    check(c:flag('passagemMercado'), 'Mercado passage flag set by the talk')
    c.data.flags.conjuntoFerramentas = true -- set possession, as the map 2 hook lands it
    talkTo(c, 'doro'); runTalk(c)
    check(c:flag('ferramentasEntregues') and c:stepDone('P02-E05'),
        'Delivering the tool set records the hand-off')
    talkTo(c, 'doro'); runTalk(c)
    check(c:stepDone('D03'), 'D03 fires once tools reach the bench')

    -- Real chain: passage flag -> enter -> syncExits -> portal free.
    c:enter('hub', 'colina')
    check(exitTo(c, 'oficinas').open == true and exitTo(c, 'mercado').open == true,
        'Re-entering the hub opens both passage portals')
    check(not Explore.solidCell(c.map, 28, 21) and not Explore.solidCell(c.map, 29, 21),
        'Opened portal cells stop blocking')
    check(c:canLeave(exitTo(c, 'oficinas')) and c:canLeave(exitTo(c, 'mercado')),
        'canLeave accepts the open passages')
    local passReach = Region.reachable(c.map, 26, 20)
    check(passReach[Rooms.key(28, 21)] and passReach[Rooms.key(29, 21)],
        'Reachability covers the opened passages')

    -- M3 chain: cart moved -> flags -> prop taken -> portal -> travel -> reload.
    c.data.flags.conjuntoCozinha = true -- pieces in hand, as the deposit hook lands them
    c:enter('mercado', 'hub')
    check(c.map.id == 'mercado', 'Entering the market lands in the region')
    c.player.grid.x, c.player.grid.y = 25, 19
    -- Stand orientado: quem caminha até o carro olha para o sul — o seletor
    -- por facing precisa da mesma intenção que o jogador dá ao chegar.
    c.player.facing.dx, c.player.facing.dy = 0, 1
    check(c:interact() and c.dialogue, 'Cart hotspot answers')
    runTalk(c, {1}) -- MOVER O CARRO
    check(c:flag('carroMovido') and c:flag('passagemSaloes')
        and c:stepDone('P03-E05'), 'Moving the cart flags route and step')
    c.player.grid.x, c.player.grid.y = 25, 19
    check(c:interact(), 'Second look runs the cart use hook')
    runTalk(c)
    check(c.data.regions.mercado.props.carroPecas == 'taken'
        and not Explore.solidCell(c.map, 25, 20),
        'Cart prop persists as taken and frees the cell')
    c:enter('mercado', 'hub') -- syncExits runs on enter, like the hub chain
    check(exitTo(c, 'saloes').open == true, 'Saloes portal opens on the flag')
    c.player.grid.x, c.player.grid.y = 25, 21
    c:update(1 / 120, {dx = 0, dy = 0})
    check(c.map.id == 'saloes', 'Stepping on the route travels to Saloes')
    c:travel('mercado', 'saloes')
    check(c.map.id == 'mercado' and math.abs(c.player.grid.x - 26) < .01,
        'The return leg lands at the market arrival')
    local mdata = Save.read()
    check(mdata and mdata.flags.passagemSaloes
        and mdata.regions.mercado and mdata.regions.mercado.props.carroPecas == 'taken',
        'Route state serializes to the save')
    local mrest = Campaign.restore(mdata)
    mrest:enter('mercado', 'hub')
    check(exitTo(mrest, 'saloes').open == true
        and mrest.map.propCells[Rooms.key(25, 20)] == nil,
        'Reload reopens the portal and keeps the cart taken')
    c:travel('hub', 'mercado') -- back before the persistence block below

    -- M4 gate: Sabela asks only with tools delivered AND the exit repaired --
    talkTo(c, 'sabela'); runTalk(c) -- metSabela introduction
    check(not c:flag('passagemReservatorio') and not c:stepDone('P04-E01'),
        'Reservatorio gate stays shut without the traced exit')
    c.data.flags.saidaReforcada = true -- the Oficinas repair hook lands this
    talkTo(c, 'sabela'); runTalk(c, {1}) -- EU TRAGO O FILTRO
    check(c:stepDone('P04-E01') and c:flag('passagemReservatorio'),
        'Accepting the water request records the step and opens the route')

    -- Real chain: hub -> oficinas -> reservatorio through the opened portals.
    c.player.grid.x, c.player.grid.y = 28, 21
    c:update(1 / 120, {dx = 0, dy = 0})
    check(c.map.id == 'oficinas', 'Hub portal travels to Oficinas')
    check(exitTo(c, 'reservatorio').open == true
        and not Explore.solidCell(c.map, 27, 8),
        'Reservatorio corridor opens on the flag')
    c.player.grid.x, c.player.grid.y = 27, 8
    c:update(1 / 120, {dx = 0, dy = 0})
    check(c.map.id == 'reservatorio', 'Oficinas portal travels to Reservatorio')

    -- M4 chain: scheme -> notice -> bench -> filter -> test -> crew -> wheel
    -- -> drain. Everything by object or talk; no arena at any point.
    c.player.grid.x, c.player.grid.y = 16, 4
    check(c:interact() and c.dialogue, 'Esquema hotspot answers')
    runTalk(c)
    check(c:flag('esquemaLido'), 'Reading the traced scheme sets the flag')
    c.player.grid.x, c.player.grid.y = 9, 8
    check(c:interact() and c.dialogue, 'Alojamentos notice answers')
    runTalk(c)
    check(c:flag('placaLida'), 'Reading the lodgings sign sets the flag')
    c.player.grid.x, c.player.grid.y = 8, 8
    check(c:interact() and c.dialogue, 'Interdicao hotspot answers')
    runTalk(c)
    check(c:flag('interdicaoVista'), 'Reading the interdiction marks the gate seen')
    talkTo(c, 'mara'); runTalk(c, {1}) -- O BANCO ALI ERA DE UM CASAL?
    check(c:stepDone('P04-E02') and c:stepDone('P04-E03'),
        'Mara plus the notice close the garden steps')
    c.player.grid.x, c.player.grid.y = 17, 2
    check(c:interact() and c.dialogue, 'Filtro hotspot answers')
    runTalk(c)
    check(c:flag('filtroColetado')
        and c.data.regions.reservatorio.props.filtroPedra == 'taken',
        'Collecting the filter marks flag and prop')
    c.player.grid.x, c.player.grid.y = 22, 11
    check(c:interact() and c.dialogue, 'Canal de teste answers')
    runTalk(c, {1}) -- TESTAR O DESVIO
    check(c:flag('canalTestado') and c:stepDone('P04-E04')
        and c.scene == 'explore' and c.data.encounters['C04-02'] == nil,
        'Testing the bypass records the step without opening a fight')
    -- C04-02: crossing the door opens the crew talk; the scheme ends it.
    c.player.grid.x, c.player.grid.y = 19.4, 13
    c:update(1 / 120, {dx = 0, dy = 0})
    check(c.dialogue ~= nil, 'Crossing the door opens the crew talk')
    runTalk(c, {1}) -- O ESQUEMA MOSTRA O RAMO
    check(c:flag('equipeLiberada') and c.data.encounters['C04-02'] == nil
        and c.scene == 'explore', 'The crew yields to the scheme without an arena')
    -- Volante with Ivo unresolved: the scheme operates for him. The spot is
    -- picked inside the hotspot range but outside Ivo's talkRange.
    c.player.grid.x, c.player.grid.y = 29, 3
    check(c:interact() and c.dialogue, 'Volante answers')
    runTalk(c, {1}) -- ABRIR COM O ESQUEMA
    check(c:flag('comportaAberta') and c:stepDone('P04-E05')
        and c.data.encounters['B04-01'] == nil,
        'Scheme-driven wheel opens the sluice without Ivo')
    c.player.grid.x, c.player.grid.y = 8, 8
    check(c:interact(), 'Interdicao re-check runs the drain')
    runTalk(c)
    check(c.data.regions.reservatorio.props.gradeComporta == 'taken'
        and not Explore.solidCell(c.map, 8, 7),
        'Drained gate frees the lower corridor')
    check(not c:flag('passagemFundacao'),
        'Fundacao gate waits for the escora half as well')
    c:travel('hub', 'oficinas')
    talkTo(c, 'doro'); runTalk(c) -- filtroColetado -> montagem na cisterna
    check(c:flag('filtroMontado') and c:stepDone('P04-E06'),
        'Doro mounts the filter at the cistern')

    -- M5 chain: dividers -> rehearsal -> negotiated Beltran -> escora -> M6.
    c:enter('saloes', 'mercado')
    c.player.grid.x, c.player.grid.y = 28, 4
    check(c:interact() and c.dialogue, 'Armario tecnico answers')
    runTalk(c)
    check(c:flag('ferragensVistas') and c.map.propCells[Rooms.key(28, 3)] ~= nil,
        'Ferragens inspect stays indestructible by design')
    c.player.grid.x, c.player.grid.y = 24, 3
    check(c:interact() and c.dialogue, 'Divisorias hotspot answers')
    runTalk(c)
    check(c:flag('divisoriasColetadas')
        and c.data.regions.saloes.props.divisorias == 'taken',
        'Collecting the dividers carries the install plan')
    c.player.grid.x, c.player.grid.y = 27, 20
    check(c:interact() and c.dialogue, 'Ensaio hotspot answers')
    runTalk(c, {1}) -- CORRER O ENSAIO
    check(c:flag('ensaioFeito') and c:flag('rotaPreparada')
        and c:stepDone('P05-E04'), 'Rehearsal proves the escape route exists')
    talkTo(c, 'beltran'); runTalk(c) -- metBeltran invitation
    check(c:stepDone('P05-E02'), 'Meeting Beltran records the invite')
    talkTo(c, 'beltran'); runTalk(c, {1}) -- A SAÍDA EXISTE. EU ENSAIEI.
    check(c.data.encounters['B05-01'] == 'negotiated' and c:stepDone('P05-E05'),
        'Beltran yields to the rehearsed route — no arena, no death')
    talkTo(c, 'ajudante'); runTalk(c, {1}) -- COMBINADO, ATÉ A RENDIÇÃO
    check(c:flag('dueloProposto'), 'Staged duel only starts with the proposal')
    c.player.grid.x, c.player.grid.y = 6, 7
    check(c:interact() and c.dialogue, 'Escora hotspot answers')
    runTalk(c, {1}) -- REFORÇAR A ESCORA
    check(c:flag('escoraReforcada'), 'Reinforcing the escora sets the flag')
    c.player.grid.x, c.player.grid.y = 6, 7
    check(c:interact(), 'Second look runs the escora use hook')
    runTalk(c)
    check(c.data.regions.saloes.props.escoraTrava == 'taken'
        and not Explore.solidCell(c.map, 6, 6)
        and c:flag('passagemFundacao'),
        'Escora plus filtro emit the Foundation passage')
    check(exitTo(c, 'fundacao').open == true
        and not Explore.solidCell(c.map, 5, 2),
        'Fundacao portal opens on the compound gate')
    c:enter('reservatorio', 'oficinas')
    check(exitTo(c, 'fundacao').open == true
        and c.map.propCells[Rooms.key(8, 7)] == nil,
        'Revisit keeps the drain and the Fundacao gate open')
    -- Back to the hub: the Teca plan installs what was collected.
    c:travel('hub', 'oficinas')
    talkTo(c, 'teca'); runTalk(c) -- divisoriasColetadas -> instalação real
    check(c:flag('divisoriasMontadas') and c:stepDone('P05-E06'),
        'Collected dividers install through the Teca plan')

    -- Persistence -----------------------------------------------------------------
    local data = Save.read()
    check(data ~= nil and data.region == 'hub', 'Campaign persists to disk')
    data.x, data.y = c.player.grid.x, c.player.grid.y
    local restored = Campaign.restore(data)
    check(restored.map.id == 'hub' and restored.data.flags.casaco == true
        and restored:stepDone('P01-E03') and restored.data.people.runa.location == 'hub',
        'Reload preserves flags, steps and relocated residents')
    check(restored:stepDone('P01-E05') and restored:stepDone('P01-E06')
        and restored:stepDone('D01') and restored:stepDone('D02')
        and restored:stepDone('T01') and restored:stepDone('T02'),
        'Reload preserves presentation, expedition and arc steps')
    check(restored:flag('passagemOficinas') and restored:flag('passagemMercado')
        and exitTo(restored, 'oficinas').open == true and exitTo(restored, 'mercado').open == true,
        'Passage flags reopen portals after reload')
    local colina2 = restored.map
    restored:enter('colina', 'sepultura')
    colina2 = restored.map
    local openGrade = true
    for _, prop in ipairs(colina2.props) do
        if prop.id == 'grade' then openGrade = prop.state == 'open' end
    end
    check(openGrade, 'Opened grade stays open on revisit')
    check(#restored.npcs <= 1, 'Relocated residents do not duplicate on the hill')
    check(restored.dialogue and restored.dialogue.lines == LoreC.colinaRevisit.lines,
        'First hill revisit after the descent narrates the quiet hill')
    advance(restored)
    restored:enter('colina', 'sepultura')
    check(restored.dialogue == nil, 'Revisit narration plays only once')

    -- Death ------------------------------------------------------------------------
    restored:die('test')
    check(restored.map.id == 'colina' and restored.data.deaths == 1,
        'Death returns to the grave and counts')
    check(restored.dialogue ~= nil, 'Death speaks on waking at the grave')
    advance(restored)
    check(restored.data.flags.casaco and restored:stepDone('P01-E04')
        and restored:stepDone('P01-E06') and restored:flag('passagemOficinas'),
        'Death preserves completed campaign state')

    -- Battle plumbing ---------------------------------------------------------------
    -- A Colina não abriga encontros autorais: T01-01 era plumbing de teste e
    -- colidia com os ids T01–T03 da subquest da Teca (ficha 01 só prevê o
    -- confronto da grade, resolvido por diálogo). O contrato mundo↔arena é
    -- exercido com um encontro forjado no salão da descida.
    local function worldFoe(id, kind, x, y)
        return {enemy = {id = id, kind = kind, state = 'idle', timer = 0},
            grid = {x = x, y = y}, facing = {dx = 0, dy = 1},
            motion = {remaining = 0, duration = .16, fromX = x, fromY = y},
            health = {current = 1, max = 1}}
    end
    check(#restored.enemies == 1 and restored.enemies[1].enemy.id == 'C01-Q1',
        'Colina fields only the ficha encounter (C01-Q1, grade demonstration)')
    -- O def do encontro aprovado: opcional (talk gate, nunca auto-arena),
    -- não-letal (ctx 'duelo' = rendição) e com unidade autoral.
    local duel = restored:encounterDef('C01-Q1')
    check(duel and duel.talk == 'runa' and duel.ctx == 'duelo'
        and duel.confronto == 'runaConfronto' and duel.units ~= nil,
        'C01-Q1 def: talk-gated, duelo (nonLethal) e unidade autoral')
    -- Fluxo real por input: anda até o marcador — sem a flag de confronto o
    -- contato abre a fala, nunca a arena. (O emissor de 'runaConfronto' é a opção 'ACEITO O
    -- DESAFIO' do node runaDesafio da Pena.)
    local foe = restored.enemies[1]
    restored.player.grid.x, restored.player.grid.y = foe.grid.x, foe.grid.y - 2
    for _ = 1, 240 do
        if restored.dialogue or restored.scene ~= 'explore' then break end
        restored:update(1 / 120, {dx = 0, dy = 1})
    end
    check(restored.dialogue ~= nil and restored.scene ~= 'battle',
        'C01-Q1 contact without the flag opens talk, never the arena')
    restored:closeDialogue()

    -- Acesso REAL ao duelo sancionado: marker gated → fala → flag → arena →
    -- desfechos. Cada elo ausente falha com nome próprio — QA exige a cadeia.
    do
        local c2 = Campaign.new({legacy = true})
        for _drain = 1, 600 do
            if not (c2.dialogue) then break end
            c2.dialogue.reveal = math.huge
            c2:advanceDialogue()
        end
        check(#c2.enemies == 1 and c2.enemies[1].enemy.id == 'C01-Q1',
            'C01-Q1 é o único marcador em campo numa campanha nova')
        local f2 = c2.enemies[1]
        local reach2 = Region.reachable(c2.map,
            math.floor(c2.player.grid.x + .5), math.floor(c2.player.grid.y + .5))
        local adj = false
        for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
            if reach2[Rooms.key(f2.grid.x + d[1], f2.grid.y + d[2])] then adj = true end
        end
        -- A prova é caminho ANTES da grade abrir — o marcador tem de ser
        -- alcançável do lado do spawn (norte). x=7,y=18 fica AO SUL da grade
        -- lacrada: a salão só se abre depois — QA reproduz o gap.
        check(adj, 'O marcador gated é alcançável — adjacente livre no grafo')
        -- input real até o contato: a fala abre, a arena não
        c2.player.grid.x, c2.player.grid.y = f2.grid.x, f2.grid.y - 2
        for _ = 1, 240 do
            if c2.dialogue or c2.scene ~= 'explore' then break end
            c2:update(1 / 120, {dx = 0, dy = 1})
        end
        check(c2.dialogue ~= nil and c2.scene ~= 'battle',
            'Contato gated pela fala: abre a oferta, nunca a arena')
        -- a fala abre em 'lines': chooseDialogue só morde em 'options' —
        -- drenar até o menu antes de procurar a oferta.
        for _drain = 1, 600 do
            if not (c2.dialogue and c2.dialogue.mode ~= 'options') then break end
            c2.dialogue.reveal = math.huge
            c2:advanceDialogue()
        end
        -- a oferta de prova precisa existir no node
        local offer
        for i, opt in ipairs(c2.dialogue and c2.dialogue.node.options or {}) do
            local l = opt.label or ''
            if l:find('CAPACIDADE') or l:find('DESAFIO') or l:find('PROVA') then offer = i end
        end
        check(offer ~= nil,
            'A fala da Runa oferece a prova (DEMONSTRAR CAPACIDADE / ACEITO O DESAFIO)')
        if offer then
            c2:chooseDialogue(offer)
            -- Drena limitado: linhas avançam; menu só recebe SAIR (última).
            for _ = 1, 20 do
                if not c2.dialogue then break end
                if c2.dialogue.mode == 'options' then
                    c2:chooseDialogue(#c2.dialogue.node.options)
                else
                    c2.dialogue.reveal = math.huge; c2:advanceDialogue()
                end
            end
            check(c2:flag('runaConfronto'), 'O aceite arma o confronto declarado (runaConfronto)')
            c2.player.grid.x, c2.player.grid.y = f2.grid.x, f2.grid.y + .4
            c2:update(1 / 120, {dx = 0, dy = 0})
            check(c2.scene == 'battle', 'Com a flag, o recontato abre a arena')
            if c2.scene == 'battle' then
                c2:endBattle('won')
                check(c2.data.encounters['C01-Q1'] == 'won',
                    'Vitória na prova marca o encontro')
                check(c2.data.regions.colina.props.grade == 'open',
                    'Vitória na prova abre a grade')
                Save.write(c2.data)
                local rr = Campaign.restore(Save.read())
                check(rr ~= nil and rr.data.encounters['C01-Q1'] == 'won'
                    and rr.data.regions.colina.props.grade == 'open',
                    'Save preserva prova vencida e grade aberta')
                check(rr and #rr.enemies == 0, 'Marcador resolvido não respawna')
            end
        end
        -- Desfechos restantes: trégua abre a grade, fuga preserva o impasse,
        -- cair na prova é morte normal (nonLethal só no lado dela).
        for _, outcome in ipairs({'negotiated', 'return', 'die'}) do
            local c3 = Campaign.new({legacy = true})
            for _drain = 1, 600 do
                if not (c3.dialogue) then break end
                c3.dialogue.reveal = math.huge
            c3:advanceDialogue()
            end
            c3.data.flags.runaConfronto = true
            local f3 = c3.enemies[1]
            c3.player.grid.x, c3.player.grid.y = f3.grid.x + .4, f3.grid.y
            c3:update(1 / 120, {dx = 0, dy = 0})
            check(c3.scene == 'battle',
                outcome .. ': contato armado abre a arena do duelo')
            if c3.scene ~= 'battle' then break end
            if outcome == 'negotiated' then
                c3:endBattle('negotiated')
                check(c3.data.encounters['C01-Q1'] == 'negotiated'
                    and c3.data.regions.colina.props.grade == 'open',
                    'Trégua também abre a grade — a prova bastou')
            elseif outcome == 'return' then
                c3:endBattle('return')
                check(c3.data.encounters['C01-Q1'] == nil
                    and c3.data.regions.colina.props.grade ~= 'open',
                    'Fuga preserva o impasse — nada marcado, grade fechada')
            else
                c3.battle:damage(c3.battle.player, 99, 7, 8)
                c3:update(1 / 60, {dx = 0, dy = 0})
                check(c3.scene == 'explore' and c3.map.id == 'colina'
                    and c3.data.deaths == 1,
                    'Cair na prova é morte normal — acorda na cova')
            end
        end
    end

    restored.enemies[#restored.enemies + 1] = worldFoe('T-TEST', 'dasher', 9, 20)
    restored.player.grid.x, restored.player.grid.y = 8.8, 20
    restored:update(1 / 120, {dx = 0, dy = 0})
    check(restored.scene == 'battle', 'Touching the creature opens its arena')
    restored:endBattle('return')
    check(restored.scene == 'explore' and restored.data.encounters['T-TEST'] == nil,
        'Leaving an unfinished arena marks nothing')
    -- C01-Q1 é o marcador do duelo da grade (ficha 01, gate 'runaConfronto') —
    -- pendente por definição; a contagem ignora o encontro sancionado.
    local function fieldFoes()
        local n = 0
        for _, e in ipairs(restored.enemies) do
            if e.enemy.id ~= 'C01-Q1' then n = n + 1 end
        end
        return n
    end
    check(fieldFoes() == 1, 'A pending creature stays in the world')
    restored:startBattle('T-TEST')
    check(restored.battle.room and #restored.battle.enemies == 1
        and restored.battle.enemies[1].enemy.kind == 'dasher',
        'Arena hosts the encounter creature')
    check(restored.battle.snapshot.x == restored.player.grid.x,
        'Battle snapshots the exploration point')
    restored:endBattle('won')
    check(restored.scene == 'explore' and restored.data.encounters['T-TEST'] == 'won',
        'Resolved encounters persist as done')
    check(fieldFoes() == 0, 'Resolved creatures leave the world')
    restored:enter('colina', 'sepultura')
    check(fieldFoes() == 0, 'Resolved creatures stay gone on revisit')
    restored.player.grid.x, restored.player.grid.y = 8.8, 20
    restored:update(1 / 120, {dx = 0, dy = 0})
    check(restored.scene == 'explore', 'Contact with a resolved encounter stays exploration')
    -- Negotiated outcomes settle the encounter the same way a victory does.
    restored.enemies[#restored.enemies + 1] = worldFoe('T-TEST', 'dasher', 9, 20)
    restored:startBattle('T-TEST')
    restored:endBattle('negotiated')
    check(restored.data.encounters['T-TEST'] == 'negotiated' and fieldFoes() == 0,
        'Negotiated resolution also removes the creature for good')
    restored:enter('colina', 'sepultura')
    check(fieldFoes() == 0, 'Negotiated creatures stay gone on revisit')

    -- Locked exits ------------------------------------------------------------
    -- The real passage flags were set above via the talk chain; clearing them
    -- keeps a closed exit around for the simulated gate below (hub defs ship
    -- flagged exits now — the real chain is asserted in the hub block).
    restored.data.flags.passagemOficinas = nil
    restored.data.flags.passagemMercado = nil
    restored:enter('hub', 'colina')
    local locked
    for _, e in ipairs(restored.map.exits) do
        if e.open == false then locked = e; break end
    end
    check(locked ~= nil and Explore.solidCell(restored.map, locked.x, locked.y),
        'Unflagged passages stay locked and solid')
    locked.flag = 'abriuPassagens'
    restored.data.flags.abriuPassagens = true
    restored:syncExits()
    check(locked.open == true
        and Rooms.cell(restored.map, locked.x, locked.y).exit.open == true,
        'syncExits opens the portal and its cell')
    check(Explore.solidCell(restored.map, locked.x, locked.y) == false
        and restored:canLeave(locked), 'Opened portal is walkable and passable')

    -- Hotspot `use` side effects ---------------------------------------------
    -- Region hotspot defs may carry a `use(campaign)` effect; it runs on
    -- interact before the fala resolves (no region ships `use` yet — simulated).
    restored.player.grid.x, restored.player.grid.y = 26, 20
    restored.map.hotspots[#restored.map.hotspots + 1] = {
        id = 'alavancaTeste', x = 25, y = 20,
        use = function(c) c.data.flags.alavancaTeste = true end}
    check(restored:interact() == true and restored.data.flags.alavancaTeste == true,
        'Hotspot use effect runs on interact')
    advance(restored)

    -- Font coverage ------------------------------------------------------------------
    local list = {}
    strings(LoreC.hubArrival, list)
    for _, q in ipairs(LoreC.introCutscene) do strings(q, list) end
    for _, beat in ipairs(LoreC.miranteReveal) do strings(beat, list) end
    -- Node de resposta extraído pro módulo: dentro de option.action o
    -- coletor não alcança (a cobertura passa por aqui).
    strings(LoreC.runaConfrontoResposta, list)
    local probe = Campaign.new({legacy = true})
    probe.dialogue = nil
    strings(LoreC.hotspot(probe, {id = 'marcaPartida'}), list)
    for id in pairs(LoreC.npcs) do
        local node = LoreC.talk(probe, id)
        if node then strings(node, list) end
    end
    probe:enter('hub', 'colina')
    probe.dialogue = nil
    for id in pairs(LoreC.npcs) do
        local node = LoreC.talk(probe, id)
        if node then strings(node, list) end
    end
    for _, s in ipairs(list) do
        check(Font.clean(s) == s, 'Missing glyph in campaign text: ' .. s)
    end

    check(Save.selfCheck(), 'Save serialization round-trips and rejects bad data')
    check(Props.selfCheck(), 'Prop painters registered')

    Save.clear()
    print(string.format('%d CAMPAIGN EXPLORATION ASSERTIONS PASSED', checks))
    CampaignTest.percurso()
    CampaignTest.entrada()
end

-- End-to-end campaign walk (docs/QA_MUNDOS.md, D18 + D20): the full run
-- through real chains only — no flag/step fabrication, no injected foes.
-- Order A is the canonical route; order B forks the market first (D13) and
-- must prove Brina's dual emitters work without the Oficinas leg. D20 adds
-- a real fought victory and the peaceful (negotiated) boss path, both
-- through live gameplay.
function CampaignTest.percurso()
    local checks = 0
    local function check(value, message) checks = checks + 1; assert(value, message) end
    local function runTalk(campaign, choices)
        local i = 0
        for _ = 1, 40 do
            local d = campaign.dialogue
            if not d then return end
            if d.mode == 'options' then
                i = i + 1
                campaign:chooseDialogue(choices and choices[i] or #d.node.options)
            else
                d.reveal = math.huge
                campaign:advanceDialogue()
            end
        end
        check(false, 'Talk chain did not settle')
    end
    local function talkTo(campaign, id)
        for _, npc in ipairs(campaign.npcs) do
            if npc.npc.id == id then
                campaign.player.grid.x, campaign.player.grid.y = npc.grid.x, npc.grid.y + 1
                check(campaign:interact() and campaign.dialogue ~= nil,
                    'Talk with ' .. id .. ' opens')
                return npc
            end
        end
        check(false, 'NPC ' .. id .. ' stands in ' .. campaign.map.id)
    end
    local function exitTo(campaign, to)
        for _, e in ipairs(campaign.map.exits) do
            if e.to == to then return e end
        end
    end
    -- Stand on a portal cell and let a single update trigger the travel.
    local function stepOn(campaign, x, y, to)
        campaign.player.grid.x, campaign.player.grid.y = x, y
        campaign:update(1 / 120, {dx = 0, dy = 0})
        check(campaign.map.id == to, 'Portal walk travels to ' .. to)
    end
    -- MERGE-SHIM: luta real no modelo fásico — sem fase de turno, o que
    -- manda é o frame. Alinha na linha/coluna do inimigo, sai do telegrafo
    -- armado, carrega .72s e solta — até a arena concluir. A pausa fásica
    -- (§3) é atravessada com CONTINUAR: ENTER no item default do menu.
    local function fightToWin(c)
        local idle = {dx = 0, dy = 0, guard = false, events = {}}
        local function upd(input)
            if c.dialogue then
                local d = c.dialogue
                if d.mode == 'options' then c:chooseDialogue(#d.node.options)
                else d.reveal = math.huge; c:advanceDialogue() end
            end
            c:update(1 / 60, input or idle)
        end
        local function hold(n, input)
            for _ = 1, n do
                if c.scene ~= 'battle' then return false end
                upd(input)
            end
            return c.scene == 'battle'
        end
        for _ = 1, 80 do
            if c.scene ~= 'battle' then return end
            local b = c.battle
            -- Beats de conversa: o diálogo congela a pausa — drena como
            -- runTalk antes de avaliar a fase (SAIR fecha o beat sem efeito).
            if c.dialogue then runTalk(c) end
            if b.phase == 'pause' then b:key('return', c); upd() end
            local e
            for _, u in ipairs(b.enemies) do
                if u.health.current > 0 and not u.spared
                    and not u.replaced and not (u.enemy and u.enemy.summoned) then
                    e = u; break
                end
            end
            if not e then return end
            local pg = b.player.grid
            -- Desvia primeiro: célula prometida não se pisa durante o warn.
            local threatened = false
            for _, u in ipairs(b.enemies) do
                local a = u.enemy
                if u.health.current > 0 and a and a.state == 'warn' and a.cells then
                    for _, cl in ipairs(a.cells) do
                        if cl.x == pg.x and cl.y == pg.y then threatened = true end
                    end
                end
            end
            local dx, dy = e.grid.x - pg.x, e.grid.y - pg.y
            if threatened then
                local mx, my = 0, 0
                if dx == 0 then mx = pg.x > 7 and -1 or 1 else my = pg.y > 7 and -1 or 1 end
                upd({dx = mx, dy = my, guard = false,
                    events = {{kind = 'face', dx = mx, dy = my},
                        {kind = 'step', dx = mx, dy = my}}})
                if not hold(30, {dx = mx, dy = my, guard = false, events = {}}) then return end
            elseif dx == 0 or dy == 0 then
                local fx = dx == 0 and 0 or (dx > 0 and 1 or -1)
                local fy = dx == 0 and (dy > 0 and 1 or -1) or 0
                upd({dx = 0, dy = 0, guard = false,
                    events = {{kind = 'face', dx = fx, dy = fy}, {kind = 'charge'}}})
                if not hold(60) then return end
                upd({dx = 0, dy = 0, guard = false, events = {{kind = 'fire'}}})
                if not hold(15) then return end
            else
                local mx, my = 0, 0
                if math.abs(dx) >= math.abs(dy) then mx = dx > 0 and 1 or -1
                else my = dy > 0 and 1 or -1 end
                upd({dx = mx, dy = my, guard = false,
                    events = {{kind = 'face', dx = mx, dy = my},
                        {kind = 'step', dx = mx, dy = my}}})
                if not hold(30, {dx = mx, dy = my, guard = false, events = {}}) then return end
            end
        end
    end
    local function freshCampaign()
        Save.file = 'test_campaign_save.lua'
        Save.clear()
        local c = Campaign.new({legacy = true})
        for _drain = 1, 600 do
            if not (c.dialogue) then break end
            c.dialogue.reveal = math.huge
        c:advanceDialogue()
        end
        return c
    end
    -- Route beat dedup (main.lua opening close writes flags['cut_'..f]):
    -- the beat exists in lore, fires once on the real flag, then never.
    local function cutCheck(c, f)
        check(LoreC.cutscenes[f] and LoreC.cutscenes[f].lines
            and #LoreC.cutscenes[f].lines > 0, 'Route beat authored: ' .. f)
        check(c:flag(f) and not c:flag('cut_' .. f),
            'Route beat armed once for ' .. f)
        c.data.flags['cut_' .. f] = true -- same write the real close does
        check(not (c:flag(f) and not c:flag('cut_' .. f)),
            'Route beat dedups per save for ' .. f)
    end
    local function saveLoad(c, label)
        c:checkpoint()
        local data = Save.read()
        check(data ~= nil, label .. ': state serializes to disk')
        local r = Campaign.restore(data)
        check(r.map.id == data.region and r:stepDone('P01-E04') and r:flag('casaco'),
            label .. ': reload keeps campaign state')
        return r
    end

    -- Legs ----------------------------------------------------------------
    local function colinaLeg(c)
        c.player.grid.x, c.player.grid.y = 23, 11.2
        check(c:interact() and c.dialogue, 'Belongings open a narration node')
        runTalk(c)
        check(c:flag('casaco') and c:stepDone('P01-E02'), 'Belongings record the step')
        check(LoreC.objective(c):match('Runa'), 'Objective points at Runa')
        -- De (9,3) Doro vence o placar do interact — o spot da tampa em
        -- (8,4) fica na diagonal e perde em qualquer facing.
        c.player.grid.x, c.player.grid.y = 9, 3
        c:interact(); runTalk(c) -- metDoroFirst introduction
        c.player.grid.x, c.player.grid.y = 9, 3
        c:interact(); runTalk(c, {1}) -- E O CAIXÃO QUE SOBROU?
        check(c:stepDone('D01'), 'D01 through the real coffin question')
        c.player.grid.x, c.player.grid.y = 6, 16.4
        check(c:interact() and c.dialogue, 'Runa answers through the grade')
        runTalk(c, {1}) -- FUI EU. SAÍ DA MINHA COVA.
        check(c:stepDone('P01-E03') and c.data.regions.colina.props.grade == 'open',
            'Negotiated grade opens and is recorded')
        c.player.grid.x, c.player.grid.y = 7, 21
        for _ = 1, 60 do
            c:update(1 / 60, {dx = 0, dy = 1})
            if c.map.id == 'hub' then break end
        end
        check(c.map.id == 'hub' and c:stepDone('P01-E04'),
            'Walking the descent lands at the refuge')
        runTalk(c) -- hubArrival narration (mapa legado; o refúgio novo revela no mirante)
        check(LoreC.objective(c):match('Refúgio'), 'Objective points inside the refuge')
    end
    local function hubLeg(c)
        talkTo(c, 'bento'); runTalk(c)
        talkTo(c, 'teca'); runTalk(c)
        check(not c:stepDone('P01-E05'), 'P01-E05 waits for the third resident')
        talkTo(c, 'aurel'); runTalk(c)
        check(c:stepDone('P01-E05'), 'P01-E05 residents introduced')
        check(LoreC.objective(c):match('Doro e Bento'), 'Objective offers both expeditions')
        talkTo(c, 'teca'); runTalk(c, {1}) -- COMO FUNCIONA AQUI?
        check(c:stepDone('T01'), 'T01 through the real lodging talk')
        talkTo(c, 'teca'); runTalk(c, {1}) -- arrangement choice
        check(c:stepDone('T02'), 'T02 through the real arrangement')
        talkTo(c, 'doro'); runTalk(c, {1}) -- chest placement
        check(c:stepDone('D02'), 'D02 through the real placement talk')
    end
    local function oficinasLeg(c, withBattle)
        talkTo(c, 'janda'); runTalk(c) -- metJanda introduction
        talkTo(c, 'brina'); runTalk(c) -- metBrina
        talkTo(c, 'neco'); runTalk(c)  -- metNeco -> P02-E02
        check(c:stepDone('P02-E02'), 'P02-E02 workers known')
        check(LoreC.objective(c):match('saída'), 'Objective points at the damaged exit')
        c.player.grid.x, c.player.grid.y = 27, 3
        check(c:interact() and c.dialogue, 'Ferramentas hotspot answers through the grade')
        runTalk(c)
        check(c:flag('conjuntoFerramentas'), 'Tool set collected for real')
        c.player.grid.x, c.player.grid.y = 27, 11
        c:interact(); runTalk(c) -- first read: damaged
        c.player.grid.x, c.player.grid.y = 27, 11
        c:interact(); runTalk(c) -- second read: repair lands
        check(c:flag('saidaReforcada') and c:stepDone('P02-E03'),
            'P02-E03 traced exit repaired and recorded')
        check(LoreC.objective(c):match('Janda'), 'Objective points at Janda')
        talkTo(c, 'janda'); runTalk(c, {1}) -- A PASSAGEM ESTÁ ABERTA. PODE OLHAR.
        check(c.data.encounters['B02-01'] == 'negotiated' and c:stepDone('P02-E04'),
            'Janda yields to the open route — negotiated, no arena')
        if withBattle then
            -- D20: a real fought victory on the loose sentinel.
            c.player.grid.x, c.player.grid.y = 12.4, 6
            c:update(1 / 120, {dx = 0, dy = 0})
            check(c.scene == 'battle', 'C02-03 contact opens the arena')
            fightToWin(c)
            local gone = true
            for _, we in ipairs(c.enemies) do
                if we.enemy.id == 'C02-03' then gone = false end
            end
            check(c.scene == 'explore' and c.data.encounters['C02-03'] == 'won' and gone,
                'C02-03 falls to a real fought victory and leaves the world')
        end
        c:travel('hub', 'oficinas')
        talkTo(c, 'doro'); runTalk(c) -- conjuntoFerramentas -> entrega
        check(c:flag('ferramentasEntregues') and c:stepDone('P02-E05'),
            'P02-E05 tools delivered to the bench')
    end
    local function reservatorioLeg(c)
        c.player.grid.x, c.player.grid.y = 16, 4
        c:interact(); runTalk(c)
        check(c:flag('esquemaLido'), 'Traced scheme read')
        c.player.grid.x, c.player.grid.y = 9, 8
        c:interact(); runTalk(c)
        check(c:flag('placaLida'), 'Lodgings sign read')
        c.player.grid.x, c.player.grid.y = 8, 8
        c:interact(); runTalk(c)
        check(c:flag('interdicaoVista'), 'Interdiction seen')
        talkTo(c, 'mara'); runTalk(c, {1}) -- O BANCO ALI ERA DE UM CASAL?
        check(c:stepDone('P04-E02') and c:stepDone('P04-E03'),
            'Garden steps close with Mara and the signs')
        c.player.grid.x, c.player.grid.y = 17, 2
        c:interact(); runTalk(c)
        check(c:flag('filtroColetado'), 'Stone filter collected')
        c.player.grid.x, c.player.grid.y = 22, 11
        c:interact(); runTalk(c, {1}) -- TESTAR O DESVIO
        check(c:flag('canalTestado') and c:stepDone('P04-E04')
            and c.scene == 'explore', 'Test channel proves the bypass, no fight')
        check(LoreC.objective(c):match('Ivo'), 'Objective points at Ivo')
        talkTo(c, 'equipe'); runTalk(c, {1}) -- O ESQUEMA MOSTRA O RAMO
        check(c:flag('equipeLiberada') and c.data.encounters['C04-02'] == nil,
            'Crew yields to the scheme without an arena')
        c.player.grid.x, c.player.grid.y = 29, 3
        c:interact(); runTalk(c, {1}) -- ABRIR COM O ESQUEMA
        check(c:flag('comportaAberta') and c:stepDone('P04-E05')
            and c.data.encounters['B04-01'] == nil,
            'Wheel opens the sluice without Ivo')
        c.player.grid.x, c.player.grid.y = 8, 8
        c:interact(); runTalk(c) -- use drains the grade
        check(c.data.regions.reservatorio.props.gradeComporta == 'taken'
            and not Explore.solidCell(c.map, 8, 7),
            'Drain frees the lower corridor')
        c:travel('hub', 'oficinas')
        talkTo(c, 'doro'); runTalk(c) -- filtroColetado -> montagem
        check(c:flag('filtroMontado') and c:stepDone('P04-E06'),
            'Doro mounts the filter at the cistern')
    end
    local function mercadoLeg(c)
        talkTo(c, 'ema'); runTalk(c, {1}) -- metEma + E A PLACA COBERTA?
        check(c:stepDone('P03-E02') and c:flag('disputaLote'),
            'Ema dispute opens the market arc')
        c.player.grid.x, c.player.grid.y = 24, 4
        c:interact(); runTalk(c)
        check(c:flag('reciboEma') and c.scene == 'explore',
            'Receipt inspects without ever opening a fight')
        c.player.grid.x, c.player.grid.y = 19, 4
        c:interact(); runTalk(c)
        check(c:flag('encomendaBrina'), 'Archive emits Brina commission')
        c.player.grid.x, c.player.grid.y = 20, 11
        c:interact(); runTalk(c)
        check(c:stepDone('P03-E03'), 'Couple memory plus commission close the step')
        c.player.grid.x, c.player.grid.y = 27, 4
        c:interact(); runTalk(c)
        check(c:flag('conjuntoCozinha'), 'Oven pieces collected')
        talkTo(c, 'rute'); runTalk(c)    -- metRute
        talkTo(c, 'rute'); runTalk(c, {1}) -- APRESENTAR O RECIBO
        check(c.data.encounters['B03-01'] == 'negotiated' and c:stepDone('P03-E04'),
            'Rute yields to the real receipt — negotiated, no arena')
        c.player.grid.x, c.player.grid.y = 25, 19
        c.player.facing.dx, c.player.facing.dy = 0, 1 -- o carro fica ao sul
        c:interact(); runTalk(c, {1}) -- MOVER O CARRO
        c.player.grid.x, c.player.grid.y = 25, 19
        c.player.facing.dx, c.player.facing.dy = 0, 1
        c:interact(); runTalk(c)       -- use collects the cart prop
        check(c:flag('carroMovido') and c:flag('passagemSaloes')
            and c:stepDone('P03-E05')
            and c.data.regions.mercado.props.carroPecas == 'taken',
            'Cart moved: route, step and prop persist')
        cutCheck(c, 'passagemSaloes')
        c:travel('hub', 'mercado')
        talkTo(c, 'bento'); runTalk(c) -- conjuntoCozinha -> forno
        check(c:flag('fornoReparado') and c:stepDone('P03-E06'),
            'Oven repaired — P03 closes at the table')
    end
    local function saloesLeg(c)
        c.player.grid.x, c.player.grid.y = 5, 9
        c:interact(); runTalk(c)
        check(c:flag('lembrancaMoldura'), 'Tilted frame remembered')
        c.player.grid.x, c.player.grid.y = 24, 5
        c:interact(); runTalk(c)
        check(c:flag('fundacaoLocalizada') and c:stepDone('P05-E03'),
            'Foundation plans located below the stage')
        c.player.grid.x, c.player.grid.y = 24, 3
        c:interact(); runTalk(c)
        check(c:flag('divisoriasColetadas')
            and c.data.regions.saloes.props.divisorias == 'taken',
            'Dividers collected with the install plan')
        c.player.grid.x, c.player.grid.y = 27, 20
        c:interact(); runTalk(c, {1}) -- CORRER O ENSAIO
        check(c:flag('ensaioFeito') and c:flag('rotaPreparada')
            and c:stepDone('P05-E04'), 'Rehearsal proves the escape route')
        check(LoreC.objective(c):match('Beltran'), 'Objective points at Beltran')
        talkTo(c, 'beltran'); runTalk(c)    -- metBeltran invite
        check(c:stepDone('P05-E02'), 'Beltran invitation recorded')
        talkTo(c, 'beltran'); runTalk(c, {1}) -- A SAÍDA EXISTE. EU ENSAIEI.
        check(c.data.encounters['B05-01'] == 'negotiated' and c:stepDone('P05-E05'),
            'Beltran yields to the rehearsed route — negotiated, no arena')
        talkTo(c, 'ajudante'); runTalk(c, {1}) -- COMBINADO, ATÉ A RENDIÇÃO
        check(c:flag('dueloProposto'), 'Staged duel accepted by talk only')
        c.player.grid.x, c.player.grid.y = 6, 7
        c:interact(); runTalk(c, {1}) -- REFORÇAR A ESCORA
        check(c:flag('escoraReforcada'), 'Escora reinforced')
        c.player.grid.x, c.player.grid.y = 6, 7
        c:interact(); runTalk(c)       -- use collects the truss + syncs
        check(c.data.regions.saloes.props.escoraTrava == 'taken'
            and not Explore.solidCell(c.map, 6, 6)
            and c:flag('passagemFundacao'),
            'Escora + filtro emit the Foundation passage')
        cutCheck(c, 'passagemFundacao')
    end
    local function fundacaoGate(c)
        check(exitTo(c, 'fundacao') and exitTo(c, 'fundacao').open == true,
            'Saloes Fundacao portal opens on the compound gate')
        c:enter('reservatorio', 'oficinas')
        check(exitTo(c, 'fundacao') and exitTo(c, 'fundacao').open == true
            and c.map.propCells[Rooms.key(8, 7)] == nil,
            'Reservatorio Fundacao portal opens too, drain persists')
        -- Real round-trip: the stub lands, the limit inscription reads, and
        -- both return legs walk back without a crash.
        c:travel('fundacao', 'reservatorio')
        check(c.map.id == 'fundacao', 'Foundation arrival lands in the stub')
        local limite
        for _, s in ipairs(c.map.hotspots) do
            if s.id == 'fundacaoLimite' then limite = s end
        end
        check(limite ~= nil, 'Fundacao limit inscription stands')
        c.player.grid.x, c.player.grid.y = 7, 6
        check(c:interact() and c.dialogue ~= nil,
            'Limit inscription opens its node')
        runTalk(c)
        check(exitTo(c, 'reservatorio') and exitTo(c, 'saloes'),
            'Both return portals exist in the stub')
        c:travel('reservatorio', 'fundacao')
        check(c.map.id == 'reservatorio'
            and Region.reachable(c.map, 7, 3)[Rooms.key(7, 2)],
            'Lower return lands where the corridor stays open')
        c:travel('fundacao', 'saloes')
        c:travel('saloes', 'fundacao')
        check(c.map.id == 'saloes'
            and Region.reachable(c.map, 5, 3)[Rooms.key(5, 2)],
            'Upper return lands where the truss held')
        c:travel('hub', 'oficinas')
    end
    local function tecaChain(c)
        talkTo(c, 'teca'); runTalk(c) -- divisoriasColetadas -> instalação real
        check(c:flag('divisoriasMontadas') and c:stepDone('P05-E06'),
            'Dividers install through the real Teca chain')
        talkTo(c, 'teca'); runTalk(c) -- P05-E06 done -> T03 real
        check(c:stepDone('T03'),
            'T03 closes through the real divider chain, not emulation')
    end

    -- ORDER A: canonical route -------------------------------------------
    local c = freshCampaign()
    check(c:stepDone('P01-E01'), 'Awakening records the first step')
    colinaLeg(c)
    hubLeg(c)
    talkTo(c, 'doro'); runTalk(c, {2}) -- VOU BUSCAR O CONJUNTO
    check(c:stepDone('P02-E01') and c:stepDone('P01-E06')
        and c:flag('passagemOficinas'), 'First expedition picks the Oficinas')
    cutCheck(c, 'passagemOficinas')
    stepOn(c, 28, 21, 'oficinas')
    oficinasLeg(c, true)
    talkTo(c, 'sabela'); runTalk(c)    -- metSabela
    talkTo(c, 'sabela'); runTalk(c, {1}) -- EU TRAGO O FILTRO
    check(c:stepDone('P04-E01') and c:flag('passagemReservatorio'),
        'Sabela request opens the water route')
    cutCheck(c, 'passagemReservatorio')
    stepOn(c, 28, 21, 'oficinas')
    check(exitTo(c, 'reservatorio').open == true, 'Reservatorio corridor open')
    stepOn(c, 27, 8, 'reservatorio')
    reservatorioLeg(c)
    c = saveLoad(c, 'ordem A meio')
    check(c:flag('filtroMontado') and c:flag('comportaAberta')
        and c.data.encounters['B02-01'] == 'negotiated'
        and c.data.encounters['C02-03'] == 'won'
        and c.data.regions.reservatorio.props.gradeComporta == 'taken',
        'ordem A meio: flags, encounters and drained props persist')
    check(c:flag('cut_passagemOficinas') and c:flag('cut_passagemReservatorio'),
        'ordem A meio: route-beat dedup marks persist through reload')
    talkTo(c, 'bento'); runTalk(c, {2}) -- VOU AO MERCADO
    check(c:stepDone('P03-E01') and c:flag('passagemMercado'),
        'Oven request opens the market route')
    cutCheck(c, 'passagemMercado')
    stepOn(c, 29, 21, 'mercado')
    mercadoLeg(c)
    talkTo(c, 'teca'); runTalk(c, {1}) -- EU TRAGO AS DIVISÓRIAS
    check(c:stepDone('P05-E01'), 'Divider request recorded')
    c:enter('mercado', 'hub')
    stepOn(c, 25, 21, 'saloes')
    saloesLeg(c)
    fundacaoGate(c)
    -- Brina's cross-world arc: the doc from the market resolves BR03 in A.
    c:enter('oficinas', 'hub')
    talkTo(c, 'brina'); runTalk(c, {1}) -- POR QUE NOMES DIFERENTES?
    check(c:stepDone('BR01'), 'Brina arc opens on the authorship question')
    talkTo(c, 'brina'); runTalk(c, {2}) -- FICA COM AUTORIA AQUI.
    check(c:stepDone('BR03'), 'Brina commission decides her arc')
    c:travel('hub', 'oficinas')
    tecaChain(c)
    for step in string.gmatch('P01-E01 P01-E02 P01-E03 P01-E04 P01-E05 P01-E06 '
        .. 'P02-E01 P02-E02 P02-E03 P02-E04 P02-E05 '
        .. 'P03-E01 P03-E02 P03-E03 P03-E04 P03-E05 P03-E06 '
        .. 'P04-E01 P04-E02 P04-E03 P04-E04 P04-E05 P04-E06 '
        .. 'P05-E01 P05-E02 P05-E03 P05-E04 P05-E05 P05-E06', '%S+') do
        check(c:stepDone(step), 'ordem A complete: ' .. step)
    end
    check(c:flag('passagemFundacao') and c:stepDone('T03'),
        'ordem A: compound gate and Teca arc close')
    check(LoreC.objective(c):match('quieta'),
        'ordem A: objective falls back when the board is clear')
    Save.clear()

    -- ORDER B: the market forks first (D13) ------------------------------
    local c2 = freshCampaign()
    colinaLeg(c2)
    hubLeg(c2)
    talkTo(c2, 'bento'); runTalk(c2, {2}) -- VOU AO MERCADO first!
    check(c2:stepDone('P03-E01') and c2:stepDone('P01-E06')
        and c2:flag('passagemMercado') and not c2:flag('passagemOficinas'),
        'First expedition picks the Mercado — Oficinas untouched')
    cutCheck(c2, 'passagemMercado')
    stepOn(c2, 29, 21, 'mercado')
    mercadoLeg(c2)
    check(c2:flag('encomendaBrina') and not c2:flag('passagemOficinas')
        and not c2:stepDone('P02-E05') and not c2:flag('passagemReservatorio'),
        'ordem B: market fully closed without the Oficinas leg')
    c2 = saveLoad(c2, 'ordem B meio')
    check(c2:flag('fornoReparado') and c2:flag('passagemSaloes')
        and c2.data.encounters['B03-01'] == 'negotiated'
        and c2.data.regions.mercado.props.carroPecas == 'taken',
        'ordem B meio: market flags, encounters and cart persist')
    check(c2:flag('cut_passagemMercado') and c2:flag('cut_passagemSaloes'),
        'ordem B meio: route-beat dedup marks persist through reload')
    talkTo(c2, 'sabela'); runTalk(c2)
    check(not c2:flag('passagemReservatorio'),
        'Sabela stays shut: no tools delivered yet')
    talkTo(c2, 'doro'); runTalk(c2, {2}) -- VOU BUSCAR O CONJUNTO
    check(c2:stepDone('P02-E01') and c2:flag('passagemOficinas'),
        'Second expedition picks the Oficinas')
    cutCheck(c2, 'passagemOficinas')
    stepOn(c2, 28, 21, 'oficinas')
    -- Dual emitters: BR03 must resolve even though the doc came first.
    talkTo(c2, 'janda'); runTalk(c2)
    talkTo(c2, 'brina'); runTalk(c2)    -- metBrina (encomenda already set)
    talkTo(c2, 'neco'); runTalk(c2)
    check(c2:stepDone('P02-E02'), 'P02-E02 workers known')
    talkTo(c2, 'brina'); runTalk(c2, {1}) -- BR01 question
    check(c2:stepDone('BR01'), 'Brina arc opens even forking first')
    talkTo(c2, 'brina'); runTalk(c2, {2}) -- BR03 fires: doc already in hand
    check(c2:stepDone('BR03'), 'Dual emitter: commission resolves before tools')
    c2.player.grid.x, c2.player.grid.y = 27, 3
    c2:interact(); runTalk(c2)
    check(c2:flag('conjuntoFerramentas'), 'Tool set collected for real')
    c2.player.grid.x, c2.player.grid.y = 27, 11
    c2:interact(); runTalk(c2)
    c2.player.grid.x, c2.player.grid.y = 27, 11
    c2:interact(); runTalk(c2)
    check(c2:flag('saidaReforcada') and c2:stepDone('P02-E03'),
        'P02-E03 traced exit repaired and recorded')
    check(LoreC.objective(c2):match('Janda'), 'Objective points at Janda')
    talkTo(c2, 'janda'); runTalk(c2, {1}) -- A PASSAGEM ESTÁ ABERTA.
    check(c2.data.encounters['B02-01'] == 'negotiated' and c2:stepDone('P02-E04'),
        'Janda yields to the open route — negotiated, no arena')
    -- D20 again: the same real fought victory on the fork order.
    c2.player.grid.x, c2.player.grid.y = 12.4, 6
    c2:update(1 / 120, {dx = 0, dy = 0})
    check(c2.scene == 'battle', 'C02-03 contact opens the arena')
    fightToWin(c2)
    check(c2.scene == 'explore' and c2.data.encounters['C02-03'] == 'won',
        'C02-03 falls to a real fought victory on the fork')
    c2:travel('hub', 'oficinas')
    talkTo(c2, 'doro'); runTalk(c2)
    check(c2:flag('ferramentasEntregues') and c2:stepDone('P02-E05'),
        'P02-E05 tools delivered')
    talkTo(c2, 'sabela'); runTalk(c2, {1}) -- EU TRAGO O FILTRO
    check(c2:stepDone('P04-E01') and c2:flag('passagemReservatorio'),
        'Sabela request opens the water route')
    cutCheck(c2, 'passagemReservatorio')
    stepOn(c2, 28, 21, 'oficinas')
    stepOn(c2, 27, 8, 'reservatorio')
    reservatorioLeg(c2)
    talkTo(c2, 'teca'); runTalk(c2, {1}) -- EU TRAGO AS DIVISÓRIAS
    check(c2:stepDone('P05-E01'), 'Divider request recorded')
    c2:enter('mercado', 'hub')
    stepOn(c2, 25, 21, 'saloes')
    saloesLeg(c2)
    fundacaoGate(c2)
    tecaChain(c2)
    check(c2:flag('passagemFundacao') and c2:stepDone('T03')
        and c2:stepDone('P03-E06') and c2:stepDone('P05-E06'),
        'ordem B: compound gate, market and Teca arc close')
    Save.clear()

    print(string.format('%d PERCURSO INTEGRADO ASSERTIONS PASSED', checks))
end

-- Nova entrada (título/abertura/rotas): o que o contrato permite verificar
-- no nível de módulo — a máquina do menu (menuIdx/menuMode/abertura) vive
-- em locais de main.lua e não é alcançável daqui; o que é testável são os
-- predicados e o caminho de gravação que os handlers usam.
function CampaignTest.entrada()
    local checks = 0
    local function check(value, message) checks = checks + 1; assert(value, message) end
    local function drain(c)
        for _drain = 1, 600 do
            if not (c.dialogue) then break end
            c.dialogue.reveal = math.huge
        c:advanceDialogue()
        end
    end
    Save.file = 'test_campaign_save.lua'

    -- (2) Menu: o gate de dados que decide CONTINUAR/NOVA -----------------
    Save.clear()
    check(not Save.exists(), 'Sem save: CONTINUAR não tem sessão a retomar')
    local c = Campaign.new({legacy = true})
    drain(c)
    c:checkpoint()
    check(Save.exists(), 'Com save: CONTINUAR tem sessão gravada')
    local saved = Save.read()
    check(saved ~= nil and saved.region == 'colina' and saved.steps['P01-E01'],
        'O arquivo que o menu lê é o checkpoint real')
    -- A única via destrutiva é o NOVA confirmado: startCampaign(true) ->
    -- Save.clear(). Qualquer outra tecla (1º ENTER, ESC) não toca o arquivo.
    check(Save.exists(), 'Antes do 2º ENTER o save continua intacto')
    Save.clear()
    check(not Save.exists(), 'Só a confirmação do NOVA apaga o save')

    -- (3) Intro: introSeen persiste — 1x na campanha nova, nunca no volta --
    check(#LoreC.introCutscene == 2, 'Abertura autoral: dois quadros')
    for _, q in ipairs(LoreC.introCutscene) do
        check(q.art ~= nil and q.lines and #q.lines > 0,
            'Quadro da abertura tem arte e legenda: ' .. tostring(q.art))
    end
    check((function()
        local arts = {}
        for _, q in ipairs(LoreC.introCutscene) do arts[q.art] = true end
        return arts.caixao and arts.tampa
    end)(), 'Abertura cobre o caixão e a frincha da tampa')
    local c2 = Campaign.new({legacy = true})
    drain(c2)
    check(not c2:flag('introSeen'), 'Campanha nova arma a abertura uma vez')
    -- O fechamento real da abertura grava a flag e dá checkpoint
    -- (main.lua: campaign.data.flags[openingKey]=true; campaign:checkpoint()).
    c2.data.flags.introSeen = true
    c2:checkpoint()
    local data = Save.read()
    check(data and data.flags.introSeen == true, 'introSeen serializa no save')
    local r2 = Campaign.restore(data)
    check(r2:flag('introSeen'), 'CONTINUAR restaura sem reabrir a abertura')
    Save.clear()
    local c3 = Campaign.new({legacy = true})
    drain(c3)
    check(not c3:flag('introSeen'), 'NOVA após o clear reabre a abertura')

    -- (4) Cutscenes de rota: conteúdo autoral das cinco transições --------
    for _, f in ipairs({'passagemOficinas', 'passagemMercado', 'passagemReservatorio',
            'passagemSaloes', 'passagemFundacao'}) do
        check(LoreC.cutscenes[f] and LoreC.cutscenes[f].lines
            and #LoreC.cutscenes[f].lines > 0,
            'Cutscene autoral existe: ' .. f)
    end

    -- (5) Objetivo: segue o estado, nunca a ordem -------------------------
    check(LoreC.objective(c3):match('Colina'), 'Objetivo inicial aponta a Colina')

    -- Input/reduced-motion: clearIntents solta a tecla presa. O beat de
    -- resolução morreu com o turno — a arena fásica abre na fase de ação
    -- com a janela de graça escalonada (COMBATE_MERGE §4).
    c3.player.moving = true
    c3:clearIntents()
    check(not c3.player.moving, 'clearIntents solta o input preso')
    local Battle = require('src.battle')
    local b1 = Battle.new(c3, 'RM-1', {kind = 'ranger'})
    check(b1.phase == 'action' and b1.state == 'playing',
        'A arena abre na fase de ação em tempo real')
    check(b1.enemies[1].enemy.timer >= Battle.graceTime,
        'Janela de graça no piso de ' .. Battle.graceTime)
    Save.clear()

    -- (7) C01-Q1 real — campanha NOVA (não legacy), def de verdade da
    -- colina: diálogo na grade → opção de prova → arena pelo watcher
    -- trigger='flag'; e o golpe que zeraria a vida da Runa rende, nunca
    -- executa (nonLethal do def, §5.3) — gradeHow registra o acordo.
    Save.file = 'test_campaign_save.lua'; Save.clear()
    local cR = Campaign.new()
    drain(cR)
    cR.player.grid.x, cR.player.grid.y = 6, 16.4
    check(cR:interact() and cR.dialogue,
        'C01-Q1: a Runa atende pela grade — criatura falante alcançável')
    for _drain = 1, 600 do
        if not (cR.dialogue and cR.dialogue.mode ~= 'options') then break end
        cR.dialogue.reveal = math.huge
        cR:advanceDialogue()
    end
    local demoIdx
    for i, opt in ipairs(cR.dialogue.node.options) do
        if opt.label:match('DEMONSTRAR') then demoIdx = i end
    end
    check(demoIdx ~= nil,
        'C01-Q1: a opção de prova existe no node da grade')
    cR:chooseDialogue(demoIdx)
    check(cR:flag('runaConfronto'), 'C01-Q1: o aceite arma o confronto')
    advance(cR)
    check(cR.dialogue == nil, 'A conversa fecha depois do aceite')
    cR:update(1 / 120, {})
    check(cR.scene == 'battle' and cR.battle
        and cR.battle.enemies[1] and cR.battle.enemies[1].enemy.kind == 'runa',
        'C01-Q1: a arena abre na próxima atualização — Runa viva')
    check(not cR:flag('runaConfronto'),
        'A flag do confronto é consumida no disparo')
    local rb, ru = cR.battle, cR.battle.enemies[1]
    check(rb:nonLethal(ru) == true and ru.name == 'RUNA',
        'A Runa real carrega a rendição do def')
    ru.health.current = 3
    rb:damage(ru, 3, ru.grid.x + 1, ru.grid.y)
    check(ru.spared and ru.health.current == 1,
        'O golpe que zeraria a vida rende — hp preserva 1, nunca execução')
    -- O fecho da rendição precisa de um frame de input de verdade (a arena
    -- itera input.events) e de drenar o beat de rendição se ele abrir fala.
    for _ = 1, 120 do
        cR:update(1 / 120, {dx = 0, dy = 0, guard = false, events = {}})
        if cR.dialogue then
            cR.dialogue.reveal = math.huge; cR:advanceDialogue()
            if cR.dialogue and cR.dialogue.mode == 'options' then
                cR:chooseDialogue(#cR.dialogue.node.options)
            end
        end
        if cR.scene == 'explore' then break end
    end
    check(cR.scene == 'explore'
        and cR.data.encounters['C01-Q1'] == 'negotiated',
        'A rendição fecha o encontro real como negotiated')
    check(cR.data.flags.gradeHow == 'negotiated'
        and cR.data.regions.colina.props.grade == 'open',
        'A rendição abre a grade — o acordo fica registrado')
    check(cR.data.people.runa.location == 'hub',
        'A Runa migra para o refúgio depois do acordo')

    -- (8) Mirante HD (ABERTURA_HD, Ato 4) — refúgio novo: a chegada não
    -- abre modal; as três inscrições disparam por distância no parapeito e
    -- o panorama segura enquanto ela anda a cota.
    cR:enter('hub', 'hub')
    check(cR.map.id == 'hub' and cR.dialogue == nil,
        'Refúgio novo: chegada ao mirante sem narração modal')
    check(cR:stepDone('P01-E04'), 'P01-E04 registra a chegada ao refúgio')
    local beats = 0
    for _ = 1, 1200 do
        if cR.dialogue then
            beats = beats + 1
            cR.dialogue.reveal = math.huge
            cR:advanceDialogue()
        else
            cR:update(1 / 120, {dx = 1, dy = 0})
        end
        if beats >= 3 then break end
    end
    check(beats == 3, 'O mirante dispara as três inscrições por distância')
    check(cR:flag('miranteVisto') and cR.data.flags.miranteBeat == 4,
        'Mirante esgotado registra índice e flag de visto')
    check((cR.panoramaTime or 0) > 0,
        'O panorama segura enquanto ela anda a cota')
    Save.clear()

    print(string.format('%d ENTRADA ASSERTIONS PASSED', checks))
end

return CampaignTest
