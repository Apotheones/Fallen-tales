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
            g:damage(occupant, def.damage or 2, p.x, p.y)
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
    resolve = function(H2, g, e)
        local a = e.enemy
        g:shoot(e, a.dx, a.dy, 2, .13, #a.cells, "bolt")
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
    elseif a.state == "seek" and a.timer == 0 and e.motion.remaining == 0 then
        if not def.engage(H, g, e, g.player.grid) then
            H.seekMove(g, e, def)
            a.timer = type(def.think) == "function" and def.think(e)
                or def.thinkFn and def.thinkFn(e) or def.think or .28
        end
    end
end

Enemies.helpers = H
return Enemies
