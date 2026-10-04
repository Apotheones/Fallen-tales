local Concord = require("src.components")
local Rooms = require("src.rooms")
local Environment = require("src.environment")
local Enemies = {}
local H = {}
local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

function H.cardinal(dx, dy)
    if math.abs(dx) >= math.abs(dy) then return dx >= 0 and 1 or -1, 0 end
    return 0, dy >= 0 and 1 or -1
end
function H.aligned(a, b) return a.x == b.x or a.y == b.y end
function H.visibleD(room, a, b)
    if a.x ~= b.x and a.y ~= b.y then return false end
    local dx = b.x == a.x and 0 or (b.x > a.x and 1 or -1)
    local dy = b.y == a.y and 0 or (b.y > a.y and 1 or -1)
    if dx == 0 and dy == 0 then return false end
    local cells = Rooms.line(room, a.x, a.y, dx, dy, math.abs(b.x - a.x) + math.abs(b.y - a.y))
    local last = cells[#cells]
    return last and last.x == b.x and last.y == b.y, dx, dy
end
function H.visible(room, a, b) return (H.visibleD(room, a, b)) end
local function mineable(cell)
    return cell and not cell.protected and (cell.piece == "wall" or cell.piece == "pillar" or cell.piece == "fallen")
end

local function announce(g, e, mode, dx, dy, duration)
    local a, p = e.enemy, e.grid
    a.mode, a.dx, a.dy = mode, dx or 0, dy or 0
    a.warningDuration = duration
    a.state, a.timer = "warn", duration
    if dx then e.facing.dx, e.facing.dy = dx, dy end
    g:effect("warn", p.x, p.y)
end
function H.warnLine(g, e, dx, dy, duration)
    local a, p = e.enemy, e.grid
    a.cells = Rooms.line(g.room, p.x, p.y, dx, dy, math.max(g.room.w, g.room.h))
    announce(g, e, "shot", dx, dy, duration)
end
function H.warnDash(g, e, dx, dy, length, duration, through)
    local a, p = e.enemy, e.grid
    if through then a.cells = H.throughLine(g, p.x, p.y, dx, dy, length)
    else a.cells = Environment.dashLine(g, p.x, p.y, dx, dy, length) end
    announce(g, e, "dash", dx, dy, duration)
end
function H.warnCross(g, e, duration)
    local a, p = e.enemy, e.grid
    a.cells, a.ranges = {}, {}
    for i, d in ipairs(directions) do
        local cells = Rooms.line(g.room, p.x, p.y, d[1], d[2], math.max(g.room.w, g.room.h))
        a.ranges[i] = #cells
        for _, cell in ipairs(cells) do a.cells[#a.cells + 1] = cell end
    end
    announce(g, e, "cross", nil, nil, duration)
end

-- Dash lines for breakers keep going through mineable pieces: every announced
-- cell is the promise, including which pillars will topple and where.
function H.throughLine(g, x, y, dx, dy, length)
    local cells = {}
    for _ = 1, length do
        x, y = x + dx, y + dy
        local cell = Rooms.cell(g.room, x, y)
        if not cell then break end
        if Rooms.blocksAttack(g.room, x, y) then
            if not mineable(cell) then break end
            local entry = {x = x, y = y, impact = true}
            if cell.piece == "pillar" then entry.fall = Environment.fallCells(g.room, x, y, dx, dy) end
            cells[#cells + 1] = entry
            if cell.piece == "pillar" then break end
        else
            cells[#cells + 1] = {x = x, y = y, hole = cell.ground == "hole"}
            if cell.ground == "hole" then break end
        end
    end
    return cells
end

function H.toRecover(g, e)
    local a, def = e.enemy, Enemies[e.enemy.kind]
    local recover = type(def.recover) == "function" and def.recover(e) or def.recover or .8
    if a.staggered then
        a.staggered = nil
        recover = recover + .9
        g:effect("stagger", e.grid.x, e.grid.y)
    end
    a.state, a.timer, a.cells = "recover", recover, {}
    if def.onRecover then def.onRecover(g, e) end
end

local function dangerSet(g)
    local set = {}
    for _, tile in pairs(g.room.tiles) do
        if tile.state == "falling" then
            set[Rooms.key(tile.x, tile.y)] = true
            for _, c in ipairs(tile.cells or {}) do set[Rooms.key(c.x, c.y)] = true end
        end
    end
    for _, e in ipairs(g:entities()) do
        if e.hazard then
            for _, c in ipairs(e.hazard.cells) do set[Rooms.key(c.x, c.y)] = true end
        end
    end
    return set
end

function H.seekMove(g, e, def)
    local a, p, target = e.enemy, e.grid, g.player.grid
    local danger = dangerSet(g)
    local path = Rooms.path(g.room, p.x, p.y, function(x, y)
        return def.seekGoal(g, e, x, y, target)
    end, function(x, y) return not g:walkable(x, y, e) or danger[Rooms.key(x, y)] end)
    if path and path[1] then
        local dx, dy = path[1].x - p.x, path[1].y - p.y
        e.facing.dx, e.facing.dy = dx, dy
        g:move(e, dx, dy, def.move)
    end
end

function H.dashStep(g, e, def)
    local a, p = e.enemy, e.grid
    a.dashIndex = a.dashIndex + 1
    local cell = a.cells[a.dashIndex]
    if not cell then return H.toRecover(g, e) end
    if cell.impact or Rooms.blocksAttack(g.room, cell.x, cell.y) then
        Environment.impact(g, cell.x, cell.y, a.dx, a.dy)
        -- Breakers smash through pieces that open instantly; a falling pillar still stops them.
        if not (def.dashThrough and Rooms.enterable(g.room, cell.x, cell.y)) then
            return H.toRecover(g, e)
        end
    end
    local occupant = g:occupant(cell.x, cell.y, e)
    if occupant then
        if occupant.player and occupant.grid.x == cell.x and occupant.grid.y == cell.y then
            -- def.dashHit (Beltran): a batida da investida é do def — quem
            -- não declara cai no dano padrão da família, sem mudar nada.
            if not (def.dashHit and def.dashHit(g, e, occupant, a.dx, a.dy)) then
                g:damage(occupant, def.damage or 2, p.x, p.y)
            end
        elseif occupant.resonator then g:damage(occupant, def.damage or 2, p.x, p.y) end
        return H.toRecover(g, e)
    end
    if not g:move(e, a.dx, a.dy, def.dashStep or .065, true) then return H.toRecover(g, e) end
    a.timer = def.dashStep or .065
end

function H.retreatStep(g, e, def)
    local a, p, target = e.enemy, e.grid, g.player.grid
    local current = math.abs(p.x - target.x) + math.abs(p.y - target.y)
    local best, bestDistance
    for _, d in ipairs(directions) do
        local x, y = p.x + d[1], p.y + d[2]
        if g:walkable(x, y, e) then
            local distance = math.abs(x - target.x) + math.abs(y - target.y)
            if not bestDistance or distance > bestDistance then
                best, bestDistance = d, distance
            end
        end
    end
    if best and bestDistance > current and (a.retreatSteps or 0) > 0 then
        a.retreatSteps = a.retreatSteps - 1
        e.facing.dx, e.facing.dy = H.cardinal(target.x - p.x, target.y - p.y)
        g:move(e, best[1], best[2])
        a.timer = .26
    else a.state, a.timer = "seek", .15 end
end

-- A mark strip is a three-cell line centered on the player, cut at pieces and holes.
local function markCells(g, target, dx, dy)
    local cells = {}
    for i = -1, 1 do
        local x, y = target.x + dx * i, target.y + dy * i
        if Rooms.floor(g.room, x, y) then cells[#cells + 1] = {x = x, y = y} end
    end
    return cells
end
local function dropMark(g, e, cells, fuse)
    local center = cells[math.ceil(#cells / 2)] or e.grid
    Concord.entity(g.world):give("grid", center.x, center.y):give("hazard", cells, fuse or .85, 2, e)
    g:effect("markWarn", center.x, center.y)
end
local function hasMark(g, e)
    for _, entity in ipairs(g:entities()) do
        if entity.hazard and entity.hazard.source == e then return true end
    end
    return false
end
local function servants(g)
    local n = 0
    for _, entity in ipairs(g:entities()) do
        if entity.enemy and entity.enemy.summoned and entity.health.current > 0 then n = n + 1 end
    end
    return n
end
local function summonSpot(g, e, target)
    local p = e.grid
    local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
    local options = {{dx, dy}, {dy, dx}, {-dy, -dx}, {-dx, -dy}}
    for _, d in ipairs(options) do
        local x, y = p.x + d[1], p.y + d[2]
        if d[1] ~= 0 or d[2] ~= 0 then
            if Rooms.floor(g.room, x, y) and not g:occupant(x, y, e) then return {x = x, y = y} end
        end
    end
end

local function retreating(def, steps)
    return function(H2, g, e)
        local a = e.enemy
        a.state, a.timer, a.retreatSteps = "retreat", .1, steps
        return true
    end
end
local function lineSeek(minimum, maximum)
    return function(g, e, x, y, target)
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        return d >= (minimum or 1) and d <= maximum and H.visible(g.room, {x = x, y = y}, target)
    end
end
-- Through-dashers engage on alignment alone: smashing a blocker is the point,
-- so the promised line may stop at a pillar and still be worth charging.
local function dashEngage(range, duration, through)
    return function(H2, g, e, target)
        local p = e.grid
        local d = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if not H.aligned(p, target) or d > range then return false end
        local dx = target.x == p.x and 0 or (target.x > p.x and 1 or -1)
        local dy = target.y == p.y and 0 or (target.y > p.y and 1 or -1)
        if dx == 0 and dy == 0 then return false end
        if not through then
            local visible = H.visibleD(g.room, p, target)
            if not visible then return false end
        elseif #H.throughLine(g, p.x, p.y, dx, dy, range) == 0 then
            return false
        end
        H.warnDash(g, e, dx, dy, range, duration, through)
        return true
    end
end
local function dashResolve(H2, g, e)
    local a = e.enemy
    a.state, a.timer, a.dashIndex = "dash", 0, 0
    a.dashed = true
end

Enemies.crawler = {
    hp = 4, move = .20, think = .24, recover = .6, damage = 1,
    label = "RASTEJANTE",
    -- Sem provokedEngage (COMBATE_MERGE §5.1): corpo a corpo não tem golpe
    -- honesto fora do adjacente — o provocado avança e o primeiro gatilho
    -- real (a mordida) sai com o warn encurtado.
    seekGoal = function(g, e, x, y, target)
        return math.abs(x - target.x) + math.abs(y - target.y) == 1
    end,
    engage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        if math.abs(p.x - target.x) + math.abs(p.y - target.y) ~= 1 then return false end
        local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
        a.cells = {{x = target.x, y = target.y}}
        announce(g, e, "bite", dx, dy, .7)
        return true
    end,
    resolve = function(H2, g, e)
        local a, p = e.enemy, e.grid
        local cell, hit = a.cells[1], false
        if cell then
            local occupant = g:occupant(cell.x, cell.y, e)
            if occupant and (occupant.player or occupant.resonator)
                and occupant.grid.x == cell.x and occupant.grid.y == cell.y then
                g:damage(occupant, 1, p.x, p.y)
                hit = true
            end
        end
        g:effect(hit and "bite" or "whiff", p.x, p.y)
        if hit then H.toRecover(g, e) else a.state, a.timer = "exposed", 1.3 end
    end,
}

Enemies.ranger = {
    hp = 5, think = .34, recover = .75, damage = 2,
    label = "SENTINELA",
    seekGoal = lineSeek(3, 8),
    engage = function(H2, g, e, target)
        local p = e.grid
        local visible, dx, dy = H.visibleD(g.room, p, target)
        if not visible then return false end
        H.warnLine(g, e, dx, dy, 1.05)
        return true
    end,
    -- Provocado (COMBATE_MERGE §5.1): atira na direção cardeal da jogadora
    -- mesmo desalinhado — Rooms.line corta a prévia na parede e o virote
    -- para no mesmo lugar; whiff honesto, nunca milagre.
    provokedEngage = function(H2, g, e, target)
        local p = e.grid
        local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
        H.warnLine(g, e, dx, dy, 1.05)
        return true
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        -- O virote cobra o dano do def — a Runa (família emprestada) bate
        -- 1, vigia jovem que mede; quem não declara cai no 2 da família.
        g:shoot(e, a.dx, a.dy, Enemies[e.enemy.kind].damage or 2,
            .13, #a.cells, "bolt")
        H.toRecover(g, e)
    end,
    afterRecover = retreating(nil, 2),
}

Enemies.dasher = {
    hp = 6, armor = true, think = .28, recover = .85, damage = 2,
    label = "BRUTO",
    seekGoal = function(g, e, x, y, target)
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        return d == 1 or (d <= 4 and H.visible(g.room, {x = x, y = y}, target))
    end,
    engage = dashEngage(4, .85),
    -- Provocado: a investida sai no eixo dominante da jogadora mesmo
    -- desalinhada — a linha prometida para na peça como qualquer dash.
    provokedEngage = function(H2, g, e, target)
        local p = e.grid
        local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
        H.warnDash(g, e, dx, dy, 4, .85)
        return true
    end,
    resolve = dashResolve,
}

Enemies.sower = {
    hp = 5, think = .34, recover = 1.2, damage = 2,
    label = "SEMEADOR DE ÂMBAR",
    seekGoal = function(g, e, x, y, target)
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        return d >= 3 and d <= 7
    end,
    engage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local d = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if d < 2 or d > 7 or hasMark(g, e) then return false end
        local dx, dy = H.cardinal(p.x - target.x, p.y - target.y)
        a.cells = markCells(g, target, dx, dy)
        if #a.cells == 0 then return false end
        a.mode, a.dx, a.dy = "mark", dx, dy
        a.warningDuration = .8
        a.state, a.timer = "warn", .8
        g:effect("warn", p.x, p.y)
        return true
    end,
    -- Provocado: a marca cai na jogadora a qualquer distância — o alcance
    -- ideal cede, a marca já armada continua segurando o gatilho.
    provokedEngage = function(H2, g, e, target)
        local a = e.enemy
        if hasMark(g, e) then return false end
        local dx, dy = H.cardinal(e.grid.x - target.x, e.grid.y - target.y)
        a.cells = markCells(g, target, dx, dy)
        if #a.cells == 0 then return false end
        a.mode, a.dx, a.dy = "mark", dx, dy
        a.warningDuration = .8
        a.state, a.timer = "warn", .8
        g:effect("warn", e.grid.x, e.grid.y)
        return true
    end,
    resolve = function(H2, g, e)
        dropMark(g, e, e.enemy.cells, .85)
        H.toRecover(g, e)
    end,
}

Enemies.watcher = {
    hp = 6, move = .34, think = .34, recover = .9, damage = 2,
    label = "VIGIA DOS ECOS",
    seekGoal = function(g, e, x, y, target)
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        return d <= 4 and d >= 1
    end,
    engage = function(H2, g, e, target)
        local p = e.grid
        local d = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if d > 8 then return false end
        H.warnCross(g, e, .95)
        return true
    end,
    -- Provocado: a cruz já é independente de linha — dispara a qualquer
    -- distância (sem alcance ideal a ignorar).
    provokedEngage = function(H2, g, e)
        H.warnCross(g, e, .95)
        return true
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        for i, d in ipairs(directions) do
            if a.ranges[i] > 0 then g:shoot(e, d[1], d[2], 2, .11, a.ranges[i], "bolt") end
        end
        H.toRecover(g, e)
    end,
}

Enemies.breaker = {
    hp = 10, elite = true, armor = true, think = .28, recover = 1.0, damage = 2,
    dashThrough = true, dashStep = .075,
    label = "BRUTO DEMOLIDOR",
    seekGoal = function(g, e, x, y, target)
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        return d == 1 or (d <= 6 and H.visible(g.room, {x = x, y = y}, target))
    end,
    engage = dashEngage(6, .9, true),
    -- Provocado: a investida atravessa peça no eixo dominante da jogadora.
    provokedEngage = function(H2, g, e, target)
        local p = e.grid
        local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
        if #H.throughLine(g, p.x, p.y, dx, dy, 6) == 0 then return false end
        H.warnDash(g, e, dx, dy, 6, .9, true)
        return true
    end,
    resolve = dashResolve,
}

Enemies.veteran = {
    hp = 8, elite = true, think = .34, recover = 1.3, damage = 2,
    label = "SENTINELA VETERANA",
    seekGoal = lineSeek(3, 8),
    engage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local visible, dx, dy = H.visibleD(g.room, p, target)
        if not visible then return false end
        local dx2, dy2 = 0, 0
        if dx ~= 0 then dy2 = target.y ~= p.y and (target.y > p.y and 1 or -1) or 1
        else dx2 = target.x ~= p.x and (target.x > p.x and 1 or -1) or 1 end
        local range = math.max(g.room.w, g.room.h)
        a.shots = {{dx = dx, dy = dy}, {dx = dx2, dy = dy2}}
        a.cells = {}
        for i, shot in ipairs(a.shots) do
            shot.cells = Rooms.line(g.room, p.x, p.y, shot.dx, shot.dy, range)
            for _, cell in ipairs(shot.cells) do
                a.cells[#a.cells + 1] = {x = cell.x, y = cell.y, dx = shot.dx, dy = shot.dy, shot = i}
            end
        end
        announce(g, e, "dual", dx, dy, 1.1)
        return true
    end,
    -- Provocado: as duas linhas saem sem linha de visão — a cardeal da
    -- jogadora e a perpendicular que aponta para ela.
    provokedEngage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
        local dx2, dy2 = 0, 0
        if dx ~= 0 then dy2 = target.y ~= p.y and (target.y > p.y and 1 or -1) or 1
        else dx2 = target.x ~= p.x and (target.x > p.x and 1 or -1) or 1 end
        local range = math.max(g.room.w, g.room.h)
        a.shots = {{dx = dx, dy = dy}, {dx = dx2, dy = dy2}}
        a.cells = {}
        for i, shot in ipairs(a.shots) do
            shot.cells = Rooms.line(g.room, p.x, p.y, shot.dx, shot.dy, range)
            for _, cell in ipairs(shot.cells) do
                a.cells[#a.cells + 1] = {x = cell.x, y = cell.y, dx = shot.dx, dy = shot.dy, shot = i}
            end
        end
        announce(g, e, "dual", dx, dy, 1.1)
        return true
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        local shot = a.shots[1]
        g:shoot(e, shot.dx, shot.dy, 2, .13, #shot.cells, "bolt")
        a.state, a.timer = "volley", .16
    end,
    volley = function(H2, g, e)
        local a = e.enemy
        local shot = a.shots[2]
        g:shoot(e, shot.dx, shot.dy, 2, .13, #shot.cells, "bolt")
        a.shots = nil
        H.toRecover(g, e)
    end,
    afterRecover = retreating(nil, 1),
}

Enemies.husk = {
    hp = 3, dormant = true, hatch = "crawler", hatchTime = 3.5,
    label = "ECO NASCENTE",
    hatchFn = function(H2, g, e)
        local a, p = e.enemy, e.grid
        local baby = g:spawnEnemy(p.x, p.y, a.hatch or "crawler")
        baby.enemy.summoned = a.summoned
        baby.enemy.timer = .5
        g:effect("hatch", p.x, p.y)
        e:destroy()
    end,
}

local function bossPhase(g, e, text)
    local a = e.enemy
    if not a.phase2 and e.health.current <= e.health.max * .5 then
        a.phase2 = true
        g:notify(text)
        g:effect("bossPhase", e.grid.x, e.grid.y)
        -- MERGE §7: cruzar o limiar também arma o beat declarado
        -- ({when='bossPhase', node=...}) quando a superfície é a arena —
        -- no protótipo g.evalBeats não existe e nada muda.
        if g.evalBeats then g:evalBeats('bossPhase', e) end
        return true
    end
    return false
end

Enemies.warden = {
    hp = 24, boss = true, armor = true, think = .32, seekDelay = .18, damage = 2,
    label = "GUARDIÃO DOS ECOS",
    hint = "SELO FRONTAL · ataque pelos flancos",
    hint2 = "SELO PARTIDO · saia da cruz",
    pre = function(g, e)
        if bossPhase(g, e, "O Guardião rompeu o selo. Avisos mais rápidos: procure os espaços vazios!") then
            e.enemy.frontalArmor = false
        end
    end,
    engage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local mode = a.nextMode or "cross"
        local visible, dx, dy = H.visibleD(g.room, p, target)
        local d = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if not (visible and (mode == "cross" or d <= 4)) then return false end
        local duration = a.phase2 and .95 or 1.15
        if mode == "cross" then H.warnCross(g, e, duration)
        else H.warnDash(g, e, dx, dy, 4, duration) end
        a.mode = mode
        return true
    end,
    -- Provocado: a cruz é a saída honesta do selo — sai de qualquer posição.
    provokedEngage = function(H2, g, e)
        H.warnCross(g, e, e.enemy.phase2 and .95 or 1.15)
        return true
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        if a.mode == "cross" then
            for i, d in ipairs(directions) do
                if a.ranges[i] > 0 then g:shoot(e, d[1], d[2], 2, .11, a.ranges[i], "bolt") end
            end
            H.toRecover(g, e)
        else dashResolve(H2, g, e) end
    end,
    recover = function(e) return e.enemy.phase2 and .7 or .95 end,
    thinkFn = function(e) return e.enemy.phase2 and .24 or .32 end,
    onRecover = function(g, e)
        local a = e.enemy
        a.nextMode = a.mode == "cross" and "dash" or "cross"
    end,
    seekGoal = function(g, e, x, y, target)
        local a = e.enemy
        local mode = a.nextMode or "cross"
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        return (mode == "cross" or d <= 4) and H.visible(g.room, {x = x, y = y}, target)
    end,
}

Enemies.demolisher = {
    hp = 30, boss = true, armor = true, think = .3, seekDelay = .15, damage = 2,
    dashThrough = true, dashStep = .075,
    label = "O DEMOLIDOR DA CÂMARA",
    hint = "Atraia a investida para derrubar os pilares",
    hint2 = "FÚRIA · duas investidas seguidas",
    pre = function(g, e)
        bossPhase(g, e, "O Demolidor enfureceu: duas investidas seguidas!")
    end,
    engage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local d = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if not H.aligned(p, target) or d > 7 then return false end
        local dx = target.x == p.x and 0 or (target.x > p.x and 1 or -1)
        local dy = target.y == p.y and 0 or (target.y > p.y and 1 or -1)
        if dx == 0 and dy == 0 then return false end
        if #H.throughLine(g, p.x, p.y, dx, dy, 7) == 0 then return false end
        H.warnDash(g, e, dx, dy, 7, a.phase2 and .85 or 1.0, true)
        return true
    end,
    -- Provocado: a investida atravessa peça no eixo dominante da jogadora.
    provokedEngage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
        if #H.throughLine(g, p.x, p.y, dx, dy, 7) == 0 then return false end
        H.warnDash(g, e, dx, dy, 7, a.phase2 and .85 or 1.0, true)
        return true
    end,
    resolve = dashResolve,
    recover = function(e) return e.enemy.phase2 and .8 or 1.1 end,
    afterRecover = function(H2, g, e)
        local a = e.enemy
        if a.phase2 and a.dashed and not a.chained then
            a.chained = true
            if Enemies.demolisher.engage(H2, g, e, g.player.grid) then return true end
        end
        a.dashed, a.chained = false, false
        return false
    end,
    seekGoal = function(g, e, x, y, target)
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        return d <= 7 and d >= 1 and H.visible(g.room, {x = x, y = y}, target)
    end,
}

Enemies.regent = {
    hp = 28, boss = true, think = .3, seekDelay = .15, damage = 2,
    label = "A REGENTE DE ÂMBAR",
    modes = {"shot", "mark", "shot", "summon"},
    hint = "Tiros e marcas · destrua os ecos nascentes",
    hint2 = "FÚRIA · marcas em cruz",
    pre = function(g, e)
        bossPhase(g, e, "A Regente acelera o ritual: marcas em cruz!")
    end,
    engage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local mode = a.nextMode or "shot"
        local d = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        local slow = a.phase2 and .8 or 1
        if mode == "shot" then
            local visible, dx, dy = H.visibleD(g.room, p, target)
            if not visible then return false end
            H.warnLine(g, e, dx, dy, .9 * slow)
        elseif mode == "mark" then
            if d < 2 or d > 8 then return false end
            local dx, dy = H.cardinal(p.x - target.x, p.y - target.y)
            a.cells = markCells(g, target, dx, dy)
            if a.phase2 then
                local extra = markCells(g, target, dy, dx)
                for _, cell in ipairs(extra) do
                    if cell.x ~= target.x or cell.y ~= target.y then
                        a.cells[#a.cells + 1] = cell
                    end
                end
            end
            if #a.cells == 0 then return false end
            a.mode, a.dx, a.dy = "mark", dx, dy
            a.warningDuration = .8 * slow
            a.state, a.timer = "warn", a.warningDuration
            g:effect("warn", p.x, p.y)
        else
            if servants(g) >= 2 then
                a.cycle = (a.cycle or 0) + 1
                a.nextMode = Enemies.regent.modes[(a.cycle % #Enemies.regent.modes) + 1]
                return false
            end
            local cell = summonSpot(g, e, target)
            if not cell then
                a.cycle = (a.cycle or 0) + 1
                a.nextMode = Enemies.regent.modes[(a.cycle % #Enemies.regent.modes) + 1]
                return false
            end
            a.cells = {cell}
            a.mode, a.dx, a.dy = "summon", 0, 0
            a.warningDuration = 1.1 * slow
            a.state, a.timer = "warn", a.warningDuration
            g:effect("summon", cell.x, cell.y)
        end
        a.mode = mode == "summon" and "summon" or a.mode
        return true
    end,
    -- Provocada: o tiro sai na cardeal da jogadora sem linha de visão — o
    -- ritual acelera, a linha prometida corta na parede como sempre.
    provokedEngage = function(H2, g, e, target)
        local a, p = e.enemy, e.grid
        local dx, dy = H.cardinal(target.x - p.x, target.y - p.y)
        H.warnLine(g, e, dx, dy, .9 * (a.phase2 and .8 or 1))
        return true
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        if a.mode == "shot" then
            g:shoot(e, a.dx, a.dy, 2, .12, #a.cells, "bolt")
        elseif a.mode == "mark" then
            dropMark(g, e, a.cells, a.phase2 and .7 or .85)
        else
            local cell = a.cells[1]
            if cell and Rooms.floor(g.room, cell.x, cell.y) and not g:occupant(cell.x, cell.y, e) then
                local baby = g:spawnEnemy(cell.x, cell.y, "husk")
                baby.enemy.summoned = true
            end
        end
        H.toRecover(g, e)
    end,
    recover = function(e) return e.enemy.phase2 and .7 or .9 end,
    onRecover = function(g, e)
        local a = e.enemy
        a.cycle = (a.cycle or 0) + 1
        a.nextMode = Enemies.regent.modes[(a.cycle % #Enemies.regent.modes) + 1]
    end,
    seekGoal = function(g, e, x, y, target)
        local a = e.enemy
        local mode = a.nextMode or "shot"
        local d = math.abs(x - target.x) + math.abs(y - target.y)
        if mode == "shot" then
            return d >= 3 and d <= 8 and H.visible(g.room, {x = x, y = y}, target)
        end
        return d <= 6 and d >= 2
    end,
}

-- ── Chefes humanos da campanha (COMBATE_MERGE §8 / BATALHA_ACT_MERCY §12) ──
-- Os kinds do ato social ganham defs próprios: a mecânica autoral avalia
-- ANTES do engajar da família, que segue de fallback quando o gatilho não
-- dispara — o chefe nunca fica sem plano. Metatable na família herda
-- seekGoal/think/recover/provokedEngage; `boss`/`hp`/`armor` são campos
-- explícitos porque a armadura frontal é do role da campanha, não da
-- família emprestada. No protótipo esses kinds nunca nascem — `g.say` tem
-- fallback para `notify` e `g.crates`/`g.channels`/`g.pillarDamage` leem a
-- superfície da arena ou caem nos defaults do def.

local function tell(g, text)
    if g.say then g:say(text) elseif g.notify then g:notify(text) end
end

-- Deslocamento honesto: a célula segura definida é flanco, flanco, à
-- frente, atrás — ordem fixa, sem RNG. Zera a motion para o corpo não
-- derrapar para a célula antiga depois do empurrão.
local function shoveToFree(g, entity, dx, dy)
    local p = entity.grid
    for _, d in ipairs({{dy, dx}, {-dy, -dx}, {dx, dy}, {-dx, -dy}}) do
        if d[1] ~= 0 or d[2] ~= 0 then
            local nx, ny = p.x + d[1], p.y + d[2]
            if Rooms.floor(g.room, nx, ny) and not g:occupant(nx, ny, entity) then
                p.x, p.y = nx, ny
                local m = entity.motion
                if m then m.fromX, m.fromY, m.remaining, m.falling = nx, ny, 0, false end
                g:effect("hop", nx, ny)
                return true
            end
        end
    end
    return false
end

-- A queda do martelo é a versão de arena da queda de pilar (o legado de
-- turno, não a esmagada fatal do ambiente): dano + reposição em TODA
-- unidade na banda — inclusive a jogadora, inclusive a própria Janda. O
-- recheque só pode ENCURTAR a banda prometida (mesma regra do fall do
-- Environment): a prévia nunca cresce depois do anúncio.
local function topplePillar(g, px, py, dx, dy, cells, damage)
    local pillar = Rooms.cell(g.room, px, py)
    pillar.piece, pillar.state, pillar.hits = nil, "fallen", 0
    local landed = {}
    for _, c in ipairs(cells) do
        if c.x ~= px or c.y ~= py then
            local tile = Rooms.cell(g.room, c.x, c.y)
            if not tile or tile.piece or tile.passage or tile.ground == "hole" then break end
            local unit = g:occupant(c.x, c.y, nil)
            if unit and unit.health and unit.health.current > 0 then
                -- A laje é queda de arena (hazard): fonte co-local ao alvo —
                -- nem escudo frontal nem armadura de face seguram pedra que
                -- cai (mesmo contrato do jato do Ivo e da marca do semeador).
                g:damage(unit, damage, unit.grid.x, unit.grid.y)
                if unit.health.current > 0 then shoveToFree(g, unit, dx, dy) end
                -- a unidade interrompe a laje — não nasce pedra embaixo dela
            else
                tile.piece, tile.state, tile.hits = "fallen", "idle", 0
                tile.dx, tile.dy = dx, dy
                landed[#landed + 1] = {x = c.x, y = c.y}
            end
        end
    end
    g.room.revision = (g.room.revision or 0) + 1
    g:effect("pillarFall", px, py, landed)
end

local function slideCrate(g, crate, nx, ny)
    crate.piece, crate.crate, crate.hits = nil, nil, 0
    local dest = Rooms.cell(g.room, nx, ny)
    dest.piece, dest.crate, dest.hits = "crate", true, 0
    g.room.revision = (g.room.revision or 0) + 1
    -- A lista do encontro guarda as células na ordem do def — a referência
    -- acompanha o caixote que deslizou.
    for i, c in ipairs(g.crates or {}) do
        if c == crate then g.crates[i] = dest break end
    end
    g:effect("cratePush", nx, ny)
end

local function bandCells(g, axis, n)
    local cells = {}
    if axis == "row" then
        for x = 1, g.room.w do
            if Rooms.floor(g.room, x, n) then cells[#cells + 1] = {x = x, y = n} end
        end
    else
        for y = 1, g.room.h do
            if Rooms.floor(g.room, n, y) then cells[#cells + 1] = {x = n, y = y} end
        end
    end
    return cells
end

-- RUNA — a vigia da grade (família sentinel): chefe leve do primeiro ato
-- (C01-Q1). Nenhum gatilho autoral: a identidade dela é a conversa e a
-- rendição — o def puro da família anuncia avanços com o virote de linha e
-- nunca traz golpe de morte instantânea. O `nonLethal` do encontro
-- (unidade > def > ctx, §5.3) é o que transforma a queda em rendição.
Enemies.runa = {
    hp = 10, boss = true, armor = false, think = .35, damage = 1,
    recover = 1.0, label = "RUNA",
}
setmetatable(Enemies.runa, {__index = Enemies.ranger})

-- JANDA — o martelo (família brute): se há pilar em pé a <=4 manhattan
-- dela, escolhe o mais próximo da JOGADORA — a cobertura que vale —
-- desempate por varredura (y,x). O warn marca a célula do pilar + a faixa
-- de queda no eixo dominante pilar→jogadora; o resolve derruba nessa
-- direção anunciada com dano pillarDamage + reposição. Whiff honesto:
-- pilar já caído entre anúncio e golpe → "golpeia o vazio".
Enemies.janda = {
    hp = 14, boss = true, armor = false, think = .3, recover = 1.0,
    damage = 2, label = "JANDA", hammerReach = 4,
    pre = function(g, e)
        bossPhase(g, e, "Janda aperta o martelo — os avisos ficam mais curtos!")
    end,
    engage = function(H2, g, e, target)
        local p = e.grid
        local best, bd
        for y = 1, g.room.h do
            for x = 1, g.room.w do
                local c = Rooms.cell(g.room, x, y)
                if c and c.piece == "pillar" and c.state ~= "falling"
                    and math.abs(x - p.x) + math.abs(y - p.y) <= 4 then
                    local d = math.abs(x - target.x) + math.abs(y - target.y)
                    if not bd or d < bd then best, bd = c, d end
                end
            end
        end
        if best then
            local a = e.enemy
            local fdx, fdy = H.cardinal(target.x - best.x, target.y - best.y)
            a.cells = {{x = best.x, y = best.y}}
            for _, c in ipairs(Environment.fallCells(g.room, best.x, best.y, fdx, fdy)) do
                a.cells[#a.cells + 1] = {x = c.x, y = c.y}
            end
            a.fallDx, a.fallDy = fdx, fdy
            local dx, dy = H.cardinal(best.x - p.x, best.y - p.y)
            announce(g, e, "hammer", dx, dy, a.phase2 and .8 or 1.0)
            return true
        end
        return Enemies.dasher.engage(H2, g, e, target)
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        if a.mode ~= "hammer" then return Enemies.dasher.resolve(H2, g, e) end
        local cell = a.cells and a.cells[1]
        local pillar = cell and Rooms.cell(g.room, cell.x, cell.y)
        if not pillar or pillar.piece ~= "pillar" or pillar.state == "falling" then
            g:effect("whiff", e.grid.x, e.grid.y)
            tell(g, "Janda golpeia o vazio — o pilar já caiu.")
            return H.toRecover(g, e)
        end
        topplePillar(g, cell.x, cell.y, a.fallDx or 0, a.fallDy or 1,
            a.cells, g.pillarDamage or 2)
        return H.toRecover(g, e)
    end,
}
setmetatable(Enemies.janda, {__index = Enemies.dasher})

-- RUTE — a vara (família sentinel): a primeira crate na ordem do def
-- alinhada com a jogadora a <=4, cujo destino (uma célula adiante, na
-- direção da jogadora) seja livre ou a célula dela. O warn marca a
-- célula-destino; o resolve desliza o caixote — e se a jogadora ocupa o
-- destino, ela cede mais uma célula se livre (senão "a vara empurra, você
-- não cede" e o caixote fica). Controle posicional, sem dano.
Enemies.rute = {
    hp = 12, boss = true, armor = false, think = .34, recover = .9,
    damage = 2, label = "RUTE", pushReach = 4,
    pre = function(g, e)
        bossPhase(g, e, "Rute mede a vara — os avisos ficam mais curtos!")
    end,
    engage = function(H2, g, e, target)
        local p = e.grid
        for i, crate in ipairs(g.crates or {}) do
            if crate.piece == "crate"
                and (crate.x == target.x or crate.y == target.y) then
                local dist = math.abs(crate.x - target.x) + math.abs(crate.y - target.y)
                if dist >= 1 and dist <= (Enemies.rute.pushReach or 4) then
                    local dx = crate.x == target.x and 0
                        or (target.x > crate.x and 1 or -1)
                    local dy = crate.y == target.y and 0
                        or (target.y > crate.y and 1 or -1)
                    local nx, ny = crate.x + dx, crate.y + dy
                    local playerThere = target.x == nx and target.y == ny
                    if playerThere or (Rooms.floor(g.room, nx, ny)
                        and not g:occupant(nx, ny, nil)) then
                        local a = e.enemy
                        a.cells = {{x = nx, y = ny}}
                        a.crateX, a.crateY, a.crateIdx = crate.x, crate.y, i
                        a.pushDx, a.pushDy = dx, dy
                        local fdx, fdy = H.cardinal(crate.x - p.x, crate.y - p.y)
                        announce(g, e, "push", fdx, fdy, a.phase2 and .75 or .9)
                        return true
                    end
                end
            end
        end
        return Enemies.ranger.engage(H2, g, e, target)
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        if a.mode ~= "push" then return Enemies.ranger.resolve(H2, g, e) end
        local crate = a.crateX and Rooms.cell(g.room, a.crateX, a.crateY)
        if not crate or crate.piece ~= "crate" then
            g:effect("whiff", e.grid.x, e.grid.y)
            tell(g, "A vara procura o caixote — ele já não está lá.")
            return H.toRecover(g, e)
        end
        local dx, dy = a.pushDx or 0, a.pushDy or 0
        local nx, ny = crate.x + dx, crate.y + dy
        local occ = g:occupant(nx, ny, nil)
        if occ and occ.player and occ.grid.x == nx and occ.grid.y == ny then
            local bx, by = nx + dx, ny + dy
            if Rooms.floor(g.room, bx, by) and not g:occupant(bx, by, occ) then
                occ.grid.x, occ.grid.y = bx, by
                local m = occ.motion
                m.fromX, m.fromY, m.remaining, m.falling = bx, by, 0, false
                occ.shoveT, occ.shoveDx, occ.shoveDy = .4, dx, dy
                slideCrate(g, crate, nx, ny)
                g:effect("hop", bx, by)
                tell(g, "A vara empurra — você cede um passo.")
            else
                g:effect("block", nx, ny)
                tell(g, "A vara empurra — você não cede.")
            end
        elseif not occ and Rooms.floor(g.room, nx, ny) then
            slideCrate(g, crate, nx, ny)
        else
            g:effect("whiff", e.grid.x, e.grid.y)
            tell(g, "O caixote não cede.")
        end
        return H.toRecover(g, e)
    end,
}
setmetatable(Enemies.rute, {__index = Enemies.ranger})

-- IVO — o jato (família sentinel): a jogadora numa banda de canais
-- (`g.channels` do encontro ou o default do def — rows primeiro,
-- determinístico) arma o aviso em TODA célula floor da banda; o resolve
-- cobra `g.arrowDamage` de toda unidade na faixa, exceto o próprio Ivo —
-- ele controla as válvulas. Hazard de área: a origem é co-local ao alvo,
-- então nem o escudo frontal nem a armadura de face se aplicam; i-frames
-- e o fluxo de morte/rendição seguem normais. Pode matar.
Enemies.ivo = {
    hp = 14, boss = true, armor = false, think = .34, recover = .9,
    damage = 2, label = "IVO",
    channels = {rows = {7}, cols = {4, 10}},
    pre = function(g, e)
        bossPhase(g, e, "Ivo abre as válvulas de vez — os avisos ficam mais curtos!")
    end,
    engage = function(H2, g, e, target)
        local a = e.enemy
        local bands = g.channels or Enemies.ivo.channels
        for _, r in ipairs(bands.rows or {}) do
            if target.y == r then
                a.cells = bandCells(g, "row", r)
                if #a.cells > 0 then
                    a.jetRow, a.jetCol = r, nil
                    announce(g, e, "jet", nil, nil, a.phase2 and .8 or 1.0)
                    return true
                end
            end
        end
        for _, c in ipairs(bands.cols or {}) do
            if target.x == c then
                a.cells = bandCells(g, "col", c)
                if #a.cells > 0 then
                    a.jetRow, a.jetCol = nil, c
                    announce(g, e, "jet", nil, nil, a.phase2 and .8 or 1.0)
                    return true
                end
            end
        end
        return Enemies.ranger.engage(H2, g, e, target)
    end,
    resolve = function(H2, g, e)
        local a = e.enemy
        if a.mode ~= "jet" then return Enemies.ranger.resolve(H2, g, e) end
        local dmg = g.arrowDamage or 2
        for _, unit in ipairs(g:entities()) do
            local p2 = unit.grid
            if unit ~= e and unit.health and unit.health.current > 0 and p2
                and ((a.jetRow and p2.y == a.jetRow)
                    or (a.jetCol and p2.x == a.jetCol)) then
                g:damage(unit, dmg, p2.x, p2.y, "jet")
            end
        end
        g:effect("jet", e.grid.x, e.grid.y)
        return H.toRecover(g, e)
    end,
}
setmetatable(Enemies.ivo, {__index = Enemies.ranger})

-- BELTRAN — a cortina e o bastão (família brute): o gatilho é o da
-- investida do bruto (alinhado + dist <=4 + linha clara), mas a batida
-- empurra em vez de ferir — `dashHit` no dashStep: escudo frontal
-- bloqueia o empurrão inteiro ("BLOQUEADO pelo escudo"); senão a jogadora
-- desliza até 2 células na direção do dash, parando no primeiro não-free;
-- zero células livres → 1 de dano, a prensa. Beltran termina onde ela
-- estava.
Enemies.beltran = {
    hp = 12, boss = true, armor = false, think = .28, recover = .9,
    damage = 2, label = "BELTRAN", shoveReach = 4,
    pre = function(g, e)
        bossPhase(g, e, "Beltran fecha a cortina — os avisos ficam mais curtos!")
    end,
    engage = function(H2, g, e, target)
        local p = e.grid
        local d = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if not H.aligned(p, target) or d > (Enemies.beltran.shoveReach or 4) then
            return false
        end
        local dx = target.x == p.x and 0 or (target.x > p.x and 1 or -1)
        local dy = target.y == p.y and 0 or (target.y > p.y and 1 or -1)
        if dx == 0 and dy == 0 then return false end
        if not (H.visibleD(g.room, p, target)) then return false end
        H.warnDash(g, e, dx, dy, Enemies.beltran.shoveReach or 4,
            e.enemy.phase2 and .75 or .9)
        e.enemy.mode = "shove"     -- o selo é do bastão; a lane é a mesma
        return true
    end,
    resolve = dashResolve,
    dashHit = function(g, e, target, dx, dy)
        local gd, f, pp, ep = target.guard, target.facing, target.grid, e.grid
        if gd and gd.active then
            local front = (ep.x - pp.x) * f.dx + (ep.y - pp.y) * f.dy > 0
            local side = (ep.x - pp.x) * f.dy - (ep.y - pp.y) * f.dx
            if front and side == 0 then
                gd.energy = math.max(0, gd.energy - .3)
                g:effect("block", pp.x, pp.y)
                tell(g, "BLOQUEADO pelo escudo.")
                return true
            end
        end
        local moved = 0
        for _ = 1, 2 do
            local nx, ny = pp.x + dx, pp.y + dy
            if not Rooms.floor(g.room, nx, ny) or g:occupant(nx, ny, target) then
                break
            end
            pp.x, pp.y = nx, ny
            moved = moved + 1
        end
        if moved == 0 then
            g:damage(target, 1, ep.x, ep.y, "shove")
            tell(g, "Prensa contra a cortina.")
            return true
        end
        local m = target.motion
        m.fromX, m.fromY, m.remaining, m.falling = pp.x, pp.y, 0, false
        target.shoveT, target.shoveDx, target.shoveDy = .4, dx, dy
        g:effect("shove", pp.x, pp.y)
        -- O bastão ocupa a célula que a jogadora deixou.
        g:move(e, dx, dy, .1, true)
        return true
    end,
}
setmetatable(Enemies.beltran, {__index = Enemies.dasher})

function Enemies.step(g, e, dt)
    local a, def = e.enemy, Enemies[e.enemy.kind]
    if not def then return end
    if def.pre then def.pre(g, e) end
    a.timer = math.max(0, a.timer - dt)
    if a.state == "dormant" and a.timer == 0 then
        if def.hatchFn then def.hatchFn(H, g, e) end
    elseif a.state == "warn" and a.timer == 0 then
        def.resolve(H, g, e)
    elseif a.state == "dash" and a.timer == 0 and e.motion.remaining == 0 then
        H.dashStep(g, e, def)
    elseif a.state == "volley" and a.timer == 0 then
        def.volley(H, g, e)
    elseif a.state == "exposed" and a.timer == 0 then
        a.state, a.timer = "seek", .15
    elseif a.state == "recover" and a.timer == 0 then
        if not (def.afterRecover and def.afterRecover(H, g, e)) then
            a.state, a.timer, a.cells = "seek", def.seekDelay or .12, {}
        end
    elseif a.state == "retreat" and a.timer == 0 and e.motion.remaining == 0 then
        H.retreatStep(g, e, def)
    elseif a.state == "calmed" then
        -- Trégua aceita (COMBATE_MERGE §5.1): não busca, não engaja, não
        -- resolve — o corpo parado respira. A máquina nunca sai daqui por
        -- conta própria: quem repõe 'seek' é a porta da arena (Battle:hurt,
        -- o golpe que trai a conversa).
    elseif a.state == "wait" then
        -- Respiro do fechamento de fase (COMBATE_MERGE §2.1): quem cumpriu a
        -- cota segura aqui enquanto a pausa acontece — não engaja, não anda.
        -- `e.resting` cai na retomada (ou nunca chegou) e a caça recomeça;
        -- o timer já decaiu pelo débito do topo, então o despertar é barato.
        if not e.resting then a.state, a.timer = "seek", def.seekDelay or .12 end
    elseif a.state == "seek" and a.timer == 0 and e.motion.remaining == 0 then
        local engaged = def.engage(H, g, e, g.player.grid)
        -- Provocado (COMBATE_MERGE §5.1): o próximo engajar ignora o
        -- alinhamento/alcance ideal — sem gatilho natural, o def tem a saída
        -- honesta (tiro na cardeal, cruz, marca, investida no eixo dominante);
        -- sem saída (corpo a corpo distante), a unidade avança e a isca segue
        -- armada até o primeiro warn de verdade. O warn do provocado sai
        -- ×provokeWarnFactor e a isca se consome no anúncio.
        -- Volley de despedida (§6): `e.volleyPending` armado pela fuga —
        -- mesma porta forçada do provocado, sem fator: o aviso sai no
        -- tempo normal. A flag NÃO se consome no anúncio — quita no
        -- resolve (a arena lê a transição warn→resolvido) para que a
        -- despedida prometida sempre feche, whiff incluso.
        if not engaged and (e.provoked or e.volleyPending) and def.provokedEngage then
            engaged = def.provokedEngage(H, g, e, g.player.grid)
        end
        if engaged and e.provoked and a.state == "warn" then
            local factor = g.provokeWarnFactor or .8
            a.timer, a.warningDuration = a.timer * factor, a.timer * factor
            e.provoked = nil
        end
        if not engaged then
            H.seekMove(g, e, def)
            a.timer = type(def.think) == "function" and def.think(e)
                or def.thinkFn and def.thinkFn(e) or def.think or .28
        end
    end
end

Enemies.helpers = H
return Enemies
