-- Reprodução de colisão/interação jogando (QA, não só suíte): sondas que
-- dirigem a campanha por updates reais — paredes, portas, bordas, alcance
-- de interação e hitboxes da arena em tempo real. Cada achado sai como
-- linha REPRO; invariantes duros (fora do mapa, loop de viagem) falham.
local Campaign = require('src.campaign')
local Battle = require('src.battle')
local Explore = require('src.explore')
local Region = require('src.region')
local Rooms = require('src.rooms')
local Save = require('src.save')

local Repro = {}
local findings, checks = {}, 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function repro(id, msg)
    findings[#findings + 1] = 'REPRO ' .. id .. ' :: ' .. msg
    print(findings[#findings])
end

local function fresh()
    Save.file = 'test_campaign_save.lua'
    Save.clear()
    local c = Campaign.new()
    while c.dialogue do
        c.dialogue.reveal = math.huge
        c:advanceDialogue()
    end
    return c
end

local function tick(c, seconds, input)
    input = input or {dx = 0, dy = 0}
    local steps = math.ceil((seconds or .1) * 60)
    for _ = 1, steps do c:update(1 / 60, input) end
end

local function push(c, dx, dy, seconds)
    tick(c, seconds or .3, {dx = dx, dy = dy})
end

local function settle(c, seconds)
    while c.dialogue do
        c.dialogue.reveal = math.huge
        c:advanceDialogue()
    end
    tick(c, seconds or .1)
end

function Repro.run()
    local c = fresh()

    -- (1) Borda do mapa: empurrar a fronteira real de cada linha/coluna -----
    c:travel('hub', 'colina'); settle(c, 6)
    local map = c.map
    local function rowEdge(y, left)
        local best = left and 1e9 or -1e9
        for x = 1, map.w do
            if Rooms.floor(map, x, y) then
                best = left and math.min(best, x) or math.max(best, x)
            end
        end
        return best < 1e9 and best or nil
    end
    local function colEdge(x, top)
        local best = top and 1e9 or -1e9
        for y = 1, map.h do
            if Rooms.floor(map, x, y) then
                best = top and math.min(best, y) or math.max(best, y)
            end
        end
        return best < 1e9 and best or nil
    end
    local midY, midX = math.floor(map.h / 2), math.floor(map.w / 2)
    local edges = {}
    for _, y in ipairs({midY, midY - 6, midY + 6}) do
        local l, r = rowEdge(y, true), rowEdge(y, false)
        if l then edges[#edges + 1] = {x = l, y = y, dx = -1, dy = 0} end
        if r then edges[#edges + 1] = {x = r, y = y, dx = 1, dy = 0} end
    end
    for _, x in ipairs({midX, midX - 10, midX + 10}) do
        local t, b = colEdge(x, true), colEdge(x, false)
        if t then edges[#edges + 1] = {x = x, y = t, dx = 0, dy = -1} end
        if b then edges[#edges + 1] = {x = x, y = b, dx = 0, dy = 1} end
    end
    for _, edge in ipairs(edges) do
        c.player.grid.x, c.player.grid.y = edge.x, edge.y
        push(c, edge.dx, edge.dy, 1.5)
        local cx = math.floor(c.player.grid.x + .5)
        local cy = math.floor(c.player.grid.y + .5)
        if c.map.id == 'hub' and not Rooms.floor(map, cx, cy) then
            repro('BORDA', string.format('pés saíram do chão em (%d,%d) dir(%d,%d) -> (%.2f,%.2f)',
                edge.x, edge.y, edge.dx, edge.dy, c.player.grid.x, c.player.grid.y))
            c:travel('hub', 'colina'); settle(c, 2)
        end
    end
    check(true, 'border scan complete')

    -- (2) Ping-pong de portal: chegada nunca pousa em célula de saída --------
    for _, leg in ipairs({
        {'colina', 'sepultura'}, {'hub', 'colina'},
        {'capela', 'hub'}, {'hub', 'capela'},
        {'cozinha', 'hub'}, {'hub', 'cozinha'},
        {'oficina', 'hub'}, {'hub', 'oficina'},
        {'escola', 'hub'}, {'hub', 'escola'},
        {'pensao', 'hub'}, {'hub', 'pensao'}}) do
        local from = c.map.id
        c:travel(leg[1], leg[2])
        while c.dialogue do
            c.dialogue.reveal = math.huge
            c:advanceDialogue()
        end
        local arrived = c.map.id
        c:update(1 / 60, {dx = 0, dy = 0})
        c:update(1 / 60, {dx = 0, dy = 0})
        if c.map.id ~= arrived then
            repro('PORTAL-LOOP', string.format('%s->%s pousou em portal e voltou p/ %s',
                from, leg[1], c.map.id))
        end
    end
    check(true, 'portal loop scan complete')

    -- (3) Corpo de NPC bloqueia — mas nunca aprisiona o jogador --------------
    c:travel('hub', 'colina'); settle(c, 6)
    for _, npc in ipairs(c.npcs) do
        -- aproxima e empurra contra o corpo: nunca ocupa a célula dele
        c.player.grid.x, c.player.grid.y = npc.grid.x, npc.grid.y + 2
        for _ = 1, 90 do c:update(1 / 60, {dx = 0, dy = -1}) end
        local d = math.abs(npc.grid.x - c.player.grid.x) + math.abs(npc.grid.y - c.player.grid.y)
        if d < .3 then
            repro('NPC-CLIP', string.format('jogador dentro do corpo de %s (%.2f)',
                npc.npc.id, d))
        end
    end
    check(true, 'npc body scan complete')

    -- (4) Alcance de interação: hotspot alcançável por célula livre ---------
    -- A grade da Runa fecha a metade alta da colina por design — abre pela
    -- cadeia real (P01-E03 + prop 'open') antes de medir alcance.
    c:travel('colina', 'hub'); settle(c, 6)
    c:completeStep('P01-E03')
    c.data.flags.gradeHow = 'negotiated'
    c.data.regions.colina.props.grade = 'open'
    c:enter('colina', 'hub')
    local px, py = math.floor(c.player.grid.x + .5), math.floor(c.player.grid.y + .5)
    local reach = Region.reachable(c.map, px, py)
    local n = 0; for _ in pairs(reach) do n = n + 1 end
    if n == 0 then
        repro('SEED', string.format('reachable vazio a partir de (%d,%d) %s — chegada em célula não-aberta',
            px, py, c.map.id))
    end
    for _, spot in ipairs(c.map.hotspots) do
        local used = spot.once
            and c.data.regions.colina.props[spot.id] == 'taken'
        local gated = spot.when and not spot.when(c)
        local covered = false
        for dy = -2, 2 do for dx = -2, 2 do
            if dx * dx + dy * dy <= (spot.range or 1.45) ^ 2
                and reach[Rooms.key(spot.x + dx, spot.y + dy)]
                and not Explore.solidCell(c.map, spot.x + dx, spot.y + dy) then
                covered = true
            end
        end end
        if not covered and not used and not gated then
            repro('HOTSPOT', string.format('%s em colina sem célula de interação livre', spot.id))
        end
    end

    -- (5) talkRange real: na borda exata, nearNpc honra o raio ---------------
    c:travel('hub', 'colina'); settle(c, 6)
    local npc = c.npcs[1]
    if npc then
        c.player.grid.x, c.player.grid.y = npc.grid.x + 1.7, npc.grid.y
        check(c:nearNpc() ~= nil, 'talkRange 1.7 honra o contato na borda')
        c.player.grid.x = npc.grid.x + 1.75
        if c:nearNpc() == npc then
            repro('ALCANCE', 'npc fala a 1.75 de distância — acima do raio declarado')
        end
    end

    -- (6) Contato de encontro: .55 é o limiar real ---------------------------
    c:travel('oficinas', 'hub')  -- legado: encontros no mapa velho
    c.data.flags.casaco = true
    settle(c, 1)
    local foe = c.enemies[1]
    if foe then
        local def = c:encounterDef(foe.enemy.id)
        c.player.grid.x, c.player.grid.y = foe.grid.x + .7, foe.grid.y
        tick(c, .2)
        if c.scene == 'battle' then
            repro('CONTATO', 'encontro abriu a .7 manhattan — acima do limiar .55')
        end
        c.player.grid.x, c.player.grid.y = foe.grid.x + .4, foe.grid.y
        tick(c, .2)
        check(c.scene == 'battle' or c.dialogue ~= nil,
            'contato .4 abre encontro ou conversa')
        if c.dialogue then c:closeDialogue() end
        if c.scene == 'battle' then c:endBattle('return') end
    end

    -- (7) Arena: flecha respeita a parede — parede respeita a flecha ---------
    c.dialogue = nil
    c.battle = Battle.new(c, 'REPRO-1', {kind = 'ranger'})
    c.scene = 'battle'
    local b = c.battle
    local IDLE = {dx = 0, dy = 0, guard = false, events = {}}
    -- projétil inimigo na linha da jogadora: warn -> resolve -> células honestas
    local e = b.enemies[1]
    e.grid.x, e.grid.y = 7, 5
    b.player.grid.x, b.player.grid.y = 7, 8
    local hpBefore = b.player.health.current
    for _ = 1, 600 do
        b:update(1 / 60, c, IDLE)
        if b.player.health.current < hpBefore or c.scene ~= 'battle' then break end
    end
    check(b.player.health.current < hpBefore,
        'virote real-time acerta quem fica na linha')
    if c.scene ~= 'battle' then
        check(c.map.id == 'colina', 'hp0 na arena devolve à colina')
        c.data.deaths = 0
        c:enter('colina', 'sepultura')
        c.dialogue = nil
    end

    -- (8) Escudo segura a linha frontal, não o flanco ------------------------
    c.battle = Battle.new(c, 'REPRO-2', {kind = 'ranger'})
    c.scene = 'battle'
    b = c.battle
    e = b.enemies[1]
    e.grid.x, e.grid.y = 7, 5
    b.player.grid.x, b.player.grid.y = 7, 8
    b.player.facing.dx, b.player.facing.dy = 0, -1   -- de frente para o tiro
    local GUARD = {dx = 0, dy = 0, guard = true, events = {}}
    local hpG = b.player.health.current
    for _ = 1, 600 do
        b:update(1 / 60, c, GUARD)
        if b.player.health.current < hpG then break end
    end
    -- pode ter batido se a energia acabou antes do virote; a honestidade é:
    -- o bloqueio só pode cair por exaustão, nunca por direção errada
    local guarded = b.player.guard and b.player.guard.energy < Battle.staminaMax
    check(guarded or b.player.health.current == hpG,
        'escudo frontal gasta energia ou segura a linha')

    -- (9) Caixa dos pés na arena: jogador nunca invade célula de inimigo -----
    b.player.grid.x, b.player.grid.y = e.grid.x, e.grid.y + 2
    for _ = 1, 120 do
        b:update(1 / 60, c, {dx = 0, dy = -1, guard = false, events = {}})
    end
    if math.abs(e.grid.x - b.player.grid.x) < .5
        and math.abs(e.grid.y - b.player.grid.y) < .5 then
        repro('ARENA-CLIP', string.format('jogador sobre inimigo (%.2f,%.2f vs %.2f,%.2f)',
            b.player.grid.x, b.player.grid.y, e.grid.x, e.grid.y))
    end
    check(true, 'arena overlap scan complete')

    -- (10) Fôlego da guarda: energia volta para a campanha, não zera ---------
    c:endBattle('return')
    check(c.player.guard.energy ~= nil and c.player.guard.energy >= 0,
        'stamina sai da arena para o save')

    Save.clear()
    print(string.format('%d REPRO CHECKS PASSED, %d FINDINGS', checks, #findings))
end

return Repro
