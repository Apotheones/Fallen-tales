-- Campaign exploration checks (MEGAPLAN_CAMPANHA stage 1): authored maps,
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
    while campaign.dialogue do
        campaign.dialogue.reveal = math.huge
        campaign:advanceDialogue()
        if campaign.dialogue and campaign.dialogue.mode == 'options' then
            campaign:chooseDialogue(#campaign.dialogue.node.options)
        end
    end
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

    -- Authored regions ------------------------------------------------------------
    local colina = Region.load('colina')
    local hub = Region.load('hub')
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
    for cell, prop in pairs(colina.propCells) do
        if prop.id == 'grade' then colina.propCells[cell] = nil end
    end
    reach = Region.reachable(colina, 6, 4)
    check(reach[Rooms.key(7, 21)] == true, 'Opened grade reaches the descent hall')
    local hubReach = Region.reachable(hub, 26, 20)
    check(hubReach[Rooms.key(7, 4)] and hubReach[Rooms.key(13, 18)] and hubReach[Rooms.key(12, 11)],
        'Every hub zone is reachable from the passage house')
    check(#hub.npcs == 7, 'Hub seats the seven residents')

    -- Campaign boot and continuous movement --------------------------------------
    Save.file = 'test_campaign_save.lua'
    Save.clear()
    local c = Campaign.new()
    check(c.dialogue and c.dialogue.lines == LoreC.intro.lines, 'Awakening opens with the intro narration')
    advance(c)
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
    -- Runa negotiation resolves the grade without combat.
    c.player.grid.x, c.player.grid.y = 6, 16.4
    check(c:interact() and c.dialogue, 'Runa answers through the grade')
    while c.dialogue and c.dialogue.mode ~= 'options' do
        c.dialogue.reveal = math.huge; c:advanceDialogue()
    end
    check(c.dialogue and c.dialogue.mode == 'options', 'Runa offers a reply menu')
    c:chooseDialogue(1)
    while c.dialogue and c.dialogue.mode == 'lines' do
        c.dialogue.reveal = math.huge; c:advanceDialogue()
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

    -- Persistence -----------------------------------------------------------------
    local data = Save.read()
    check(data ~= nil and data.region == 'hub', 'Campaign persists to disk')
    data.x, data.y = c.player.grid.x, c.player.grid.y
    local restored = Campaign.restore(data)
    check(restored.map.id == 'hub' and restored.data.flags.casaco == true
        and restored:stepDone('P01-E03') and restored.data.people.runa.location == 'hub',
        'Reload preserves flags, steps and relocated residents')
    local colina2 = restored.map
    restored:enter('colina', 'sepultura')
    colina2 = restored.map
    local openGrade = true
    for _, prop in ipairs(colina2.props) do
        if prop.id == 'grade' then openGrade = prop.state == 'open' end
    end
    check(openGrade, 'Opened grade stays open on revisit')
    check(#restored.npcs <= 1, 'Relocated residents do not duplicate on the hill')

    -- Death ------------------------------------------------------------------------
    restored:die('test')
    check(restored.map.id == 'colina' and restored.data.deaths == 1,
        'Death returns to the grave and counts')
    check(restored.data.flags.casaco and restored:stepDone('P01-E04'),
        'Death preserves completed campaign state')

    -- Battle plumbing ---------------------------------------------------------------
    check(#restored.enemies == 1 and restored.enemies[1].enemy.kind == 'dasher',
        'Unresolved encounters stand in the world')
    restored.player.grid.x, restored.player.grid.y = 8.8, 20
    restored:update(1 / 120, {dx = 0, dy = 0})
    check(restored.scene == 'battle', 'Touching the creature opens its arena')
    restored:endBattle('return')
    check(restored.scene == 'explore' and restored.data.encounters['T01-01'] == nil,
        'Leaving an unfinished arena marks nothing')
    restored:startBattle('T01-01')
    check(restored.battle.room and #restored.battle.enemies == 1
        and restored.battle.enemies[1].enemy.kind == 'dasher',
        'Arena hosts the encounter creature')
    check(restored.battle.snapshot.x == 8.8, 'Battle snapshots the exploration point')
    restored:endBattle('won')
    check(restored.scene == 'explore' and restored.data.encounters['T01-01'] == 'won',
        'Resolved encounters persist as done')
    check(#restored.enemies == 0, 'Resolved creatures leave the world')
    restored:enter('colina', 'sepultura')
    check(#restored.enemies == 0, 'Resolved creatures stay gone on revisit')

    -- Font coverage ------------------------------------------------------------------
    local list = {}
    strings(LoreC.intro, list); strings(LoreC.hubArrival, list)
    local probe = Campaign.new()
    probe.dialogue = nil
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
end

return CampaignTest
