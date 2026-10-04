local Campaign = require('src.campaign')
local Region = require('src.region')
local Rooms = require('src.rooms')
local Explore = require('src.explore')
local Refugio = require('src.refugio')
local Save = require('src.save')
local Tests = {}

local function finish(c)
    while c.dialogue do
        c.dialogue.reveal = math.huge
        c:advanceDialogue()
        if c.dialogue and c.dialogue.mode == 'options' then return end
    end
end

function Tests.run()
    -- LOS só para paredes: props sólidos e barras não vedam o próprio alvo.
    local sight = setmetatable({player = {grid = {x = 1, y = 1}, facing = {dx = 1, dy = 0}},
        npcs = {}, enemies = {}, map = {tiles = {}, hotspots = {
            {id = 'alvo', x = 3, y = 1, range = 2.4}}, propCells = {}}}, Campaign)
    sight.map.tiles[Rooms.key(2, 1)] = {piece = 'wall'}
    assert(not sight:interactTarget(), 'An intervening opaque wall blocks inspection')
    sight.map.tiles[Rooms.key(2, 1)].piece = nil
    sight.map.propCells[Rooms.key(2, 1)] = {kind = 'grade', solid = true}
    assert(sight:interactTarget(), 'Closed bars permit conversation across them')
    sight.map.hotspots[1].x = 2
    sight.map.propCells[Rooms.key(2, 1)] = {kind = 'mesa', solid = true}
    assert(sight:interactTarget(), 'The inspected solid prop does not block its own interaction')
    sight.map.tiles[Rooms.key(2, 1)].piece = 'wall'
    assert(sight:interactTarget(), 'A sign mounted on the target wall remains readable')
    sight.map.hotspots[1].x = 3
    assert(not sight:interactTarget(), 'A wall before the sign still blocks inspection')
    sight.map.hotspots = {}
    sight.npcs = {{grid = {x = 2, y = 1}, talkRange = 2.4}}
    assert(not sight:interactTarget(), 'The target-wall exception does not apply to NPCs')
    local map = Region.load('hub')
    assert(map.w == 54 and map.h == 40 and map.outdoor and map.realm == 'refugio')
    local reached = Region.reachable(map, map.spawn.x, map.spawn.y)
    for _, id in ipairs({'hub', 'capela', 'cozinha', 'pensao', 'oficina', 'escola', 'andlar'}) do
        local room = Region.load(id)
        local reach = Region.reachable(room, room.spawn.x, room.spawn.y)
        for _, exit in ipairs(room.exits) do
            assert(reach[Rooms.key(exit.x, exit.y)], id .. ': unreachable exit to ' .. exit.to)
            assert(exit.localPath, id .. ': local door must be a walking path')
        end
        for _, npc in ipairs(room.npcs) do
            assert(reach[Rooms.key(npc.x, npc.y)], id .. ': unreachable resident ' .. npc.id)
        end
        for _, spot in ipairs(room.hotspots) do
            local covered = false
            for dy = -2, 2 do for dx = -2, 2 do
                if dx * dx + dy * dy <= (spot.range or 1.45) ^ 2
                    and reach[Rooms.key(spot.x + dx, spot.y + dy)] then covered = true end
            end end
            assert(covered, id .. ': unreachable interaction ' .. spot.id)
        end
    end
    for _, point in pairs(map.arrivals) do assert(reached[Rooms.key(point.x, point.y)], 'Hub arrival must remain walkable') end
    Save.file = 'test_refugio_save.lua'
    local c = Campaign.new()
    assert(c:flag('refugioNovo') and c.data.people.bento.location == 'cozinha' and c.data.people.teca.location == 'escola' and c.data.people.nilo.location == 'oficina')
    assert(c.data.people.anciao.location == 'hub' and c.data.people.crianca.location == 'hub', 'figurantes são residentes de base no T0')
    c:travel('hub', 'colina'); c:closeDialogue()
    assert(c.player.grid.x == 7 and c.player.grid.y == 5 and c.panoramaTime == 5, 'Arrival reveals city from mirante')
    assert(c:travel('andlar', 'hub') == false and c.map.id == 'hub', 'Travel gate must reject premature Andlar access')
    for _, exit in ipairs(c.map.exits) do assert(exit.to ~= 'oficinas' and exit.to ~= 'mercado', 'Legacy districts must not become new Refugio doors') end
    Refugio.hotspot(c, {id = 'aguaRefugio'})
    assert(not c:flag('aguaRefugio'), 'Water repair needs equipment preparation')
    Refugio.hotspot(c, {id = 'preparoRefugio'})
    assert(not c:flag('preparoRefugio'), 'Equipment needs recovered belongings')
    c.data.flags.casaco = true
    c:completeStep('P01-E03')
    c:travel('cozinha', 'hub'); c:travel('hub', 'cozinha')  -- reenter p/ relocations
    assert(c.data.people.anciao.location == 'hub', 'ancião permanece no hub')
    assert(c.data.people.doro.location == 'capela', 'doro assume a capela depois da grade')
    for _, id in ipairs({'capela', 'cozinha', 'pensao', 'oficina', 'escola'}) do
        c:travel(id, 'hub')
        assert(Explore.free(c, c.player.grid.x, c.player.grid.y), id .. ': free arrival')
        local exit = c.map.exits[1]
        c.player.grid.x, c.player.grid.y = exit.x, exit.y
        Explore.move(c, 0, 0, 0)
        assert(c.map.id == 'hub' and Explore.free(c, c.player.grid.x, c.player.grid.y), id .. ': walking exit returns to free doorstep')
    end
    c:travel('oficina', 'hub')
    c.player.grid.x, c.player.grid.y = 4, 4
    assert(c:interact() and c:flag('preparoRefugio'), 'Workshop interaction prepares equipment')
    finish(c); c:closeDialogue()
    c:travel('hub', 'oficina')
    c.player.grid.x, c.player.grid.y = 26, 23
    assert(c:interact() and c:flag('aguaRefugio'), 'Cistern interaction repairs local water')
    finish(c); c:closeDialogue()
    assert(Refugio.ready(c) and not c:flag('refugioConcluido'), 'Repairs do not silently complete departure')
    c.player.grid.x, c.player.grid.y = 20, 19
    assert(c:interact(), 'Marco can be approached and read')
    local stone
    for _, prop in ipairs(c.map.props) do if prop.id == 'marco' then stone = prop end end
    assert(c.dialogue.preview and c.dialogue.preview ~= stone
        and c.dialogue.preview.state == stone.state, 'Inspection shows a separate snapshot of the real state')
    local state = stone.state
    c.dialogue.preview.state = 'preview-only'
    assert(stone.state == state, 'Preview changes never mutate the world or save')
    c.dialogue.preview.state = state
    finish(c)
    assert(c.dialogue and c.dialogue.mode == 'options')
    c:chooseDialogue(2)
    assert(not c:flag('refugioConcluido'), 'Staying must not approve the departure')
    c:interact(); finish(c); c:chooseDialogue(1)
    assert(c:flag('refugioConcluido') and c:stepDone('REFUGIO-FIM'))
    c:travel('cozinha', 'hub'); c:travel('hub', 'cozinha')  -- reenter p/ relocations
    assert(c.data.people.lenhador.location == 'hub', 'lenhador permanece no hub')
    assert(c.data.people.lavadeira.location == 'hub', 'lavadeira permanece no hub')
    assert(c.data.people.carregador.location == 'hub', 'carregador permanece no hub')
    assert(c.data.people.crianca.location == 'hub', 'criança permanece no hub')
    c.player.grid.x, c.player.grid.y = 20, 19
    assert(not c:flag('ferramentasEntregues') and not c:flag('fornoReparado'), 'Legacy quests are not gate requirements')
    c:interact(); finish(c); c:chooseDialogue(1)
    assert(c.map.id == 'andlar' and Explore.free(c, c.player.grid.x, c.player.grid.y), 'Marco arrives in Andlar on free floor')
    local restored = Campaign.restore(Save.read())
    assert(restored.map.id == 'andlar' and restored:flag('refugioConcluido'), 'Andlar save preserves unlock and position')
    restored.player.grid.x, restored.player.grid.y = 8, 8
    assert(restored:interact(), 'Return stone interaction is reachable')
    finish(restored); restored:chooseDialogue(1)
    assert(restored.map.id == 'hub' and restored.player.grid.x == 21 and restored.player.grid.y == 20, 'Andlar returns under the same Marco')
    restored:checkpoint()
    local data = Save.read(); data.x, data.y = 7, 13
    local corrected = Campaign.restore(data)
    assert(Explore.free(corrected, corrected.player.grid.x, corrected.player.grid.y), 'Blocked save coordinates safely fall back')
    Save.clear()
    print('REFUGIO: geography, interiors, gated departure, Andlar roundtrip and save checks passed')
end

return Tests
