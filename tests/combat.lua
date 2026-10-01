local Game = require("src.game")
local Rooms = require("src.rooms")
local T = {}
local dt = 1 / 120
local directions = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
local checks = 0

local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function frame(g, events, dx, dy, guard)
    g:update(dt, {events = events or {}, dx = dx or 0, dy = dy or 0, guard = guard or false})
    g.events = {}
end
local function advance(g, seconds, guard)
    for _ = 1, math.ceil(seconds / dt) do frame(g, nil, nil, nil, guard) end
end
local function fixture(weapon)
    return require("tests.arena").reset(Game.new(42042, true, weapon))
end
local function target(g, x, y, hp, kind)
    local e = g:actor(x, y, "enemy", hp or 20):give("enemy", kind or "dasher")
    e.enemy.timer, e.enemy.frontalArmor = 1000, false
    frame(g)
    return e
end
local function shots(g)
    local n = 0
    for _, e in ipairs(g:entities()) do if e.projectile then n = n + 1 end end
    return n
end
local function ready(g)
    frame(g, {{kind = "charge"}})
    advance(g, Game.weapons[g.player.weapon.name].chargeTime / Game.weapons[g.player.weapon.name].chargeSpeed)
end
local function fire(g)
    frame(g, {{kind = "fire"}})
    advance(g, .5)
end

local function inputCallbacks()
    local held, original = {}, love.keyboard.isDown
    love.keyboard.isDown = function(key) return held[key] or false end
    local ok, err = xpcall(function()
        local input = require("src.input").new()
        held.d, held.w = true, true
        input:pressed("d"); input:pressed("w"); input:pressed("w")
        local command = input:update()
        check(command.dx == 0 and command.dy == -1 and #command.events == 4,
            "held directions generated diagonal, duplicate edge or wrong priority")
        check(command.events[1].kind == "face" and command.events[2].kind == "step"
            and command.events[3].dy == -1 and command.events[4].kind == "step", "direction callback order changed")
        held.w = false; input:released("w")
        command = input:update()
        check(command.dx == 1 and command.dy == 0, "release did not fall back to held direction")
        held.a = true; input:pressed("a")
        check(input:update().dx == -1, "opposing directions ignored newest press")
        held.lshift = true
        check(input:update().guard, "held shift did not raise shield")
        input:pressed("i"); input:pressed("1"); input:pressed("2"); input:pressed("3")
        check(#input:update().events == 0, "removed controls still generated gameplay events")
        input:pressed("space"); input:pressed("space")
        command = input:update()
        check(#command.events == 1 and command.events[1].kind == "charge", "SPACE press did not begin one charge")
        check(#input:update().events == 0, "held SPACE generated automatic action")
        input:released("space"); input:released("space")
        command = input:update()
        check(#command.events == 1 and command.events[1].kind == "fire", "SPACE release did not produce one fire edge")
        input:pressed("space"); input:clear(); input:released("space")
        command = input:update()
        check(command.dx == 0 and command.dy == 0 and #command.events == 0,
            "clear retained movement/charge or accepted a stale release")
        input:pressed("space"); input:released("space")
        command = input:update()
        check(#command.events == 2 and command.events[1].kind == "charge" and command.events[2].kind == "fire",
            "fresh SPACE gesture did not recover after clear")
    end, debug.traceback)
    love.keyboard.isDown = original
    assert(ok, err)
end

local function movement()
    local g, x, y = fixture("bow"), 4, 8
    local p = g.player
    check(Rooms.tile == 40, "tiles must be 40 units")
    check(not g:move(p, 1, 1), "diagonal movement accepted")
    check(not g:move(p, .5, .5), "fractional diagonal movement accepted")
    check(not g:move(p, 0, 0), "zero movement accepted")
    g.room.tiles[Rooms.key(x + 1, y)].piece = "wall"
    check(not g:move(p, 1, 0), "player crossed a wall")
    g.room.tiles[Rooms.key(x + 1, y)].piece = nil
    check(g:move(p, 1, 0), "cardinal movement refused")
    check(p.grid.x == x + 1 and p.grid.y == y, "logical destination depends on animation")
    check(not g:walkable(x, y), "hop origin is not reserved")
    check(not g:walkable(x + 1, y), "hop destination is not reserved")
    check(not g:move(p, 1, 0), "actor moved twice during one hop")
    advance(g, .18)
    check(g:walkable(x, y), "origin remains reserved after landing")
    local enemy = target(g, x + 2, y)
    check(not g:move(enemy, -1, 0), "enemy overlapped player")
    g.room.tiles[Rooms.key(x + 3, y)].piece = "wall"
    check(not g:move(enemy, 1, 0), "enemy crossed a wall")
    check(not g:move(enemy, 1, 1), "enemy moved diagonally")
    frame(g, {{kind = "face", dx = 0, dy = -1}})
    check(p.facing.dx == 0 and p.facing.dy == -1, "last direction did not update facing")
    local tapped = fixture("bow")
    frame(tapped, {{kind = "face", dx = 1, dy = 0}, {kind = "step", dx = 1, dy = 0}})
    advance(tapped, .5)
    check(tapped.player.grid.x == 5 and tapped.player.grid.y == 8, "released movement tap was dropped or repeated")
    check(g:move(p, 0, 1), "could not begin hop for queued input check")
    advance(g, .06)
    frame(g, {{kind = "face", dx = 1, dy = 0}, {kind = "step", dx = 1, dy = 0}})
    check(p.grid.x == 5 and p.grid.y == 9, "queued tap changed logical destination before landing")
    advance(g, .5)
    check(p.grid.x == 6 and p.grid.y == 9 and p.motion.remaining == 0, "movement buffer did not consume exactly one tap after landing")
end

local function weapons()
    check(next(Game.weapons) == "bow" and next(Game.weapons, "bow") == nil, "weapon catalog contains more than bow")
    local g = fixture("removed")
    check(g.player.weapon.name == "bow", "legacy argument equipped removed weapon")
    local e = target(g, 12, 8)
    frame(g, {{kind = "fire"}})
    check(shots(g) == 0 and e.health.current == 20, "unprepared release fired")
    frame(g, {{kind = "charge"}}); advance(g, .3)
    frame(g, {{kind = "fire"}}); advance(g, 1)
    check(g.player.weapon.state == "empty" and g.player.weapon.charge == 0 and e.health.current == 20,
        "early release retained charge or buffered fire")
    ready(g); advance(g, 2)
    check(g.player.weapon.state == "ready" and shots(g) == 0 and e.health.current == 20,
        "holding ready charge fired automatically")
    frame(g, {{kind = "fire"}})
    check(g.player.weapon.state == "action" and g.player.weapon.charge == 0, "ready release did not consume charge")
    frame(g, {{kind = "charge"}, {kind = "fire"}}); advance(g, .5)
    check(e.health.current == 17 and g.player.weapon.state == "empty", "recovery accepted another charge/fire")
    frame(g, {{kind = "fire"}}); advance(g, .5)
    check(e.health.current == 17 and shots(g) == 0, "duplicate release fired another shot")
    ready(g); frame(g, nil, nil, nil, true); advance(g, .1)
    check(g.player.weapon.state == "empty" and g.player.weapon.charge == 0, "guard did not cancel charge")
    frame(g, {{kind = "fire"}}); advance(g, .3)
    check(e.health.current == 17, "release after guard cancellation fired")
    frame(g, {{kind = "weapon", name = "removed"}})
    check(g.player.weapon.name == "bow", "internal event equipped removed weapon")
    local wall = fixture()
    e = target(wall, 6, 8); wall.room.tiles[Rooms.key(5, 8)].piece = "wall"
    ready(wall); fire(wall)
    check(e.health.current == 20, "bow attacked through wall")
    local empty = fixture()
    ready(empty); fire(empty); advance(empty, 1)
    check(shots(empty) == 0, "unlimited bow projectile did not leave map")
end

local function telegraphs()
    for _, kind in ipairs({"dasher", "ranger"}) do
        local g = fixture("bow")
        local e = target(g, kind == "dasher" and 8 or 12, 8, 20, kind)
        e.enemy.timer = 0
        frame(g)
        local warning = e.enemy
        check(warning.state == "warn", kind .. " attacked without warning")
        check(warning.timer >= .7, kind .. " warning too short to dodge")
        local dx, dy, cells = warning.dx, warning.dy, {}
        for _, c in ipairs(warning.cells) do cells[#cells + 1] = Rooms.key(c.x, c.y) end
        frame(g, {{kind = "face", dx = 0, dy = 1}}, 0, 1)
        advance(g, .25)
        check(warning.dx == dx and warning.dy == dy, kind .. " warning followed player direction")
        check(#warning.cells == #cells, kind .. " warning changed length")
        for i, c in ipairs(warning.cells) do check(Rooms.key(c.x, c.y) == cells[i], kind .. " warning followed player position") end
        advance(g, 1.5)
        check(g.player.health.current == 10, kind .. " hit player outside telegraphed cells")
    end
    for _, kind in ipairs({"dasher", "warden"}) do
        local g = fixture("bow")
        local e = target(g, 5, 8, 24, kind)
        e.enemy.state, e.enemy.timer, e.enemy.dx, e.enemy.dy, e.enemy.cells = "dash", 0, -1, 0, {{x = 4, y = 8}}
        frame(g, {{kind = "face", dx = 0, dy = 1}}, 0, 1)
        check(g.player.grid.y == 9 and g.player.health.current == 10, kind .. " damaged visual hop origin after logical dodge")
    end
end

local function shield()
    local g = fixture("bow")
    local near = target(g, 5, 8)
    local diagonal = target(g, 5, 9)
    local far = target(g, 6, 8)
    frame(g, nil, nil, nil, true)
    check(not g:damage(g.player, 2, 5, 8), "frontal guard did not block")
    check(g.player.health.current == 10, "frontal block damaged player")
    check(near.health.current == 18 and diagonal.health.current == 18 and far.health.current == 20, "shield pulse has incorrect area")
    check(g.player.guard.energy < g.player.guard.max, "shield block spent no energy")
    check(g:damage(g.player, 2, 4, 9), "shield blocked side attack")
    advance(g, .4, true)
    check(g:damage(g.player, 2, 3, 8), "shield blocked rear attack")
    advance(g, 2, true)
    check(not g.player.guard.active and g.player.guard.exhausted, "held shield never exhausted")
    advance(g, 1)
    check(not g.player.guard.exhausted and g.player.guard.energy > .5, "released shield did not recover")
end

local function upgradesAndEnvironment()
    local g = fixture()
    g.upgrades.bowPierce, g.upgrades.bowQuick = true, true
    local a, b = target(g, 8, 8), target(g, 10, 8)
    ready(g); fire(g)
    check(a.health.current == 18 and b.health.current == 18, "piercing bow lost its damage tradeoff")
    check(g:weaponStats("bow").chargeSpeed > Game.weapons.bow.chargeSpeed, "quick bow has no charge benefit")
    g = fixture()
    local crystal = g:actor(6, 8, "neutral", 1):give("resonator")
    a = target(g, 7, 8)
    ready(g); frame(g, {{kind = "fire"}}); advance(g, .12)
    check(crystal.resonator.state == "primed" and a.health.current == 20, "resonator exploded without fuse")
    frame(g, nil, -1, 0); advance(g, .65)
    check(a.health.current == 17 and crystal.health.current == 0 and g.player.health.current == 10,
        "resonator blast failed or hit escaped player")
    local reward = Game.new(42042, false)
    crystal = reward:actor(5, 8, "neutral", 1):give("resonator")
    reward.world:emit("flush"); reward:damage(crystal, 3, 4, 8)
    for _, entity in ipairs(reward:entities()) do if entity.enemy then entity:destroy() end end
    frame(reward)
    check(reward.reward and crystal.resonator.state == "spent", "clear left live blast behind reward")
    local time, health = reward.time, reward.player.health.current
    advance(reward, 1)
    check(reward.time == time and reward.player.health.current == health, "reward did not freeze simulation")
    local allowed = {bowPierce = true, bowQuick = true, guardPulse = true, damage = true, heal = true, pickaxes = true}
    for _, card in ipairs(reward.rewardChoices) do check(allowed[card.id], "reward contains removed weapon effect") end
    check(not reward:chooseReward(0) and reward.reward, "invalid choice consumed reward")
    check(reward:chooseReward(1) and not reward.reward, "valid choice did not resume room")
    advance(reward, 1)
    check(reward.player.health.current == health, "disarmed room blasted player after reward")
end

local function boss()
    local g = fixture("bow")
    local e = target(g, 8, 8, 24, "warden")
    e.enemy.timer = 0; frame(g)
    check(e.enemy.state == "warn" and e.enemy.mode == "cross" and e.enemy.timer >= 1.1, "boss cross warning is missing")
    local saved = {}
    for _, cell in ipairs(e.enemy.cells) do saved[#saved + 1] = Rooms.key(cell.x, cell.y) end
    frame(g, {{kind = "face", dx = 0, dy = 1}}, 0, 1)
    advance(g, .2)
    for i, cell in ipairs(e.enemy.cells) do check(Rooms.key(cell.x, cell.y) == saved[i], "boss cross warning moved after player") end
    while e.enemy.state == "warn" do frame(g) end
    check(shots(g) == 4, "boss cross did not create exactly four cardinal projectiles")
    advance(g, .8)
    check(g.player.health.current == 10, "boss cross hit escaped player")
    g = fixture("bow"); e = target(g, 8, 8, 24, "warden")
    e.enemy.timer, e.enemy.nextMode = 0, "dash"; frame(g)
    check(e.enemy.mode == "dash" and #e.enemy.cells <= 4, "boss dash exceeded four blocks")
    local dx, dy = e.enemy.dx, e.enemy.dy
    frame(g, {{kind = "face", dx = 0, dy = 1}}, 0, 1)
    advance(g, .3)
    check(e.enemy.dx == dx and e.enemy.dy == dy, "boss dash aimed during warning")
    advance(g, 1.3)
    check(g.player.health.current == 10, "boss dash hit escaped player")
    g = fixture("bow"); e = target(g, 8, 8, 24, "warden")
    e.health.current, e.enemy.timer = 12, 0; frame(g)
    check(e.enemy.phase2 and math.abs(e.enemy.warningDuration - .95) < .001, "boss second phase timing is wrong")
    local armored = target(g, 10, 10)
    armored.enemy.frontalArmor = true
    check(not g:damage(armored, 3, 9, 10) and armored.health.current == 20, "front armor allowed stationary fire")
    check(g:damage(armored, 3, 10, 9) and armored.health.current == 17, "front armor blocked flank attack")
end

local function generation()
    for seed = 1, 100 do
        local rooms = Rooms.generate(seed, false)
        check(rooms.regularCount >= 7 and #rooms == rooms.regularCount + 2, "floor missing regular/secret rooms")
        for _, room in ipairs(rooms) do
            local s = room.spawn
            check(Rooms.floor(room, s.x, s.y), "spawn is inside wall")
            for _, enemy in ipairs(room.enemies) do
                check(enemy.x ~= s.x or enemy.y ~= s.y, "enemy spawned on player")
                check(Rooms.path(room, s.x, s.y, function(x, y) return x == enemy.x and y == enemy.y end), string.format("enemy is unreachable: seed %d room %d %s at %d,%d", seed, room.id, enemy.kind, enemy.x, enemy.y))
            end
            for _, door in ipairs(room.doors) do
                check(door.hidden or Rooms.floor(room, door.x, door.y), "normal door is blocked by wall")
                check(door.x == 1 or door.x == room.w or door.y == 1 or door.y == room.h, "door is not in perimeter")
                if not door.hidden then
                    check(Rooms.path(room, s.x, s.y, function(x, y) return x == door.x and y == door.y end), "door is unreachable")
                end
                if not door.finish then
                    local other, reverse = rooms[door.to], false
                    for _, link in ipairs(other.doors) do
                        if link.to == room.id and link.side == door.arrival then reverse = true end
                    end
                    check(reverse, "door link is not reciprocal")
                    local x, y = Rooms.arrival(other, door.arrival)
                    check(Rooms.floor(other, x, y), "arrival is blocked")
                    for _, enemy in ipairs(other.enemies) do check(x ~= enemy.x or y ~= enemy.y, "arrival overlaps enemy") end
                end
            end
            local occupied = {}
            for _, offset in ipairs({{-3, -2}, {3, 2}}) do
                local x, y = math.ceil(room.w / 2) + offset[1], math.ceil(room.h / 2) + offset[2]
                if Rooms.floor(room, x, y) then occupied[Rooms.key(x, y)] = true end
            end
            for _, door in ipairs(room.doors) do
                if not door.hidden then
                    check(Rooms.path(room, s.x, s.y, function(x, y) return x == door.x and y == door.y end,
                        function(x, y) return occupied[Rooms.key(x, y)] end), "resonators blocked door navigation")
                end
            end
        end
    end
    local g = Game.new(18, false, "removed")
    g.room.cleared, g.room.rewardTaken = true, true
    g.player.health.current, g.player.guard.energy = 7, .9
    g.damageBonus = 2
    g:enter(2, "west")
    g:enter(1, "east")
    g:update(0)
    check(g.room.cleared and g:enemyCount() == 0, "cleared room respawned enemies")
    check(g.player.health.current == 7 and g.player.weapon.name == "bow" and g.damageBonus == 2, "transition lost run state")
    if g.rooms.refugeId then
        g:enter(g.rooms.refugeId)
        check(g.player.health.current == 10, "refuge did not heal on first visit")
        g.player.health.current = 7
        g:enter(1); g:enter(g.rooms.refugeId)
        check(g.player.health.current == 7, "refuge could be farmed for unlimited healing")
    end
end

local function lineTarget(g, x, y, enemy, range)
    local a = enemy.grid
    if x ~= a.x and y ~= a.y then return false end
    local distance = math.abs(a.x - x) + math.abs(a.y - y)
    if distance == 0 or distance > range then return false end
    if enemy.enemy.frontalArmor and not enemy.enemy.phase2 then
        local f = enemy.facing
        local front = (x - a.x) * f.dx + (y - a.y) * f.dy
        local side = (x - a.x) * f.dy - (y - a.y) * f.dx
        if front > 0 and side == 0 then return false end
    end
    local dx, dy = a.x == x and 0 or (a.x > x and 1 or -1), a.y == y and 0 or (a.y > y and 1 or -1)
    local line = Rooms.line(g.room, x, y, dx, dy, distance)
    local last = line[#line]
    return last and last.x == a.x and last.y == a.y
end

-- A deterministic player using only cardinal movement, face, charge and fire.
-- Its trace is replayable: no damage, timers or positions are altered by the bot.
function T.replay(weapon, seed, maxSeconds, practice, stopCleared, noTools)
    weapon = "bow"
    local g = Game.new(seed or 42042, practice ~= false, weapon)
    if noTools then g.pickaxes = 0 end
    g:update(0)
    local trace, dodges, fires = {}, 0, 0
    for step = 1, math.ceil((maxSeconds or 90) / dt) do
        if g.state ~= "playing" or (stopCleared and g.room.cleared) then break end
        if g.reward then
            local choice = 1
            if noTools and g.rewardChoices[choice].id == "pickaxes" then choice = 2 end
            g:chooseReward(choice)
        end
        local p, danger, urgent, enemies = g.player.grid, {}, {}, {}
        for _, e in ipairs(g:entities()) do
            if e.enemy and e.health.current > 0 then
                enemies[#enemies + 1] = e
                if e.enemy.state == "warn" or e.enemy.state == "dash" then
                    for _, c in ipairs(e.enemy.cells) do
                        local key = Rooms.key(c.x, c.y)
                        danger[key] = true
                        if e.enemy.state == "dash" or e.enemy.timer < .4 then urgent[key] = true end
                    end
                end
            elseif e.projectile and e.team.value == "enemy" then
                for n = 0, 3 do
                    local x, y = e.grid.x + e.projectile.dx * n, e.grid.y + e.projectile.dy * n
                    danger[Rooms.key(x, y)], urgent[Rooms.key(x, y)] = true, true
                end
            elseif e.resonator and e.resonator.state == "primed" then
                for _, cell in ipairs(e.resonator.cells) do danger[Rooms.key(cell.x, cell.y)], urgent[Rooms.key(cell.x, cell.y)] = true, true end
            end
        end
        table.sort(enemies, function(a, b)
            return math.abs(a.grid.x - p.x) + math.abs(a.grid.y - p.y) < math.abs(b.grid.x - p.x) + math.abs(b.grid.y - p.y)
        end)
        local range = math.max(g.room.w, g.room.h)
        local victim
        for _, e in ipairs(enemies) do if lineTarget(g, p.x, p.y, e, range) then victim = e; break end end
        local events, mx, my = {}, 0, 0
        local w = g.player.weapon
        if victim and w.state == "ready" then
            local a = victim.grid
            local dx, dy = a.x == p.x and 0 or (a.x > p.x and 1 or -1), a.y == p.y and 0 or (a.y > p.y and 1 or -1)
            events[#events + 1] = {kind = "face", dx = dx, dy = dy}
            events[#events + 1] = {kind = "step", dx = dx, dy = dy}
            events[#events + 1] = {kind = "fire"}
            fires = fires + 1
        elseif w.state == "empty" then events[#events + 1] = {kind = "charge"} end
        if g.player.motion.remaining == 0 and (urgent[Rooms.key(p.x, p.y)] or not victim) then
            local nextDoor
            if #enemies == 0 and not g.practice then
                local desired = g.rooms.refugeId and not g.rooms[g.rooms.refugeId].visited and g.rooms.refugeId or g.rooms.bossId
                nextDoor = require("tests.floor").route(g.rooms, g.roomId, desired)[1]
            end
            local path = Rooms.path(g.room, p.x, p.y, function(x, y)
                if danger[Rooms.key(x, y)] then return false end
                for _, e in ipairs(enemies) do if lineTarget(g, x, y, e, range) then return true end end
                if #enemies == 0 then
                    for _, door in ipairs(g.room.doors) do
                        if (door == nextDoor or door.finish) and x == door.x and y == door.y then return true end
                    end
                end
                return false
            end, function(x, y) return danger[Rooms.key(x, y)] or not g:walkable(x, y, g.player) end)
            local nextCell = path and path[1]
            if not nextCell then
                for _, d in ipairs(directions) do
                    local x, y = p.x + d[1], p.y + d[2]
                    if Rooms.floor(g.room, x, y) and g:walkable(x, y, g.player) and not danger[Rooms.key(x, y)] then nextCell = {x = x, y = y}; break end
                end
            end
            if nextCell then
                mx, my = nextCell.x - p.x, nextCell.y - p.y
                if danger[Rooms.key(p.x, p.y)] then dodges = dodges + 1 end
                -- Movement keys determine facing. Do not move and aim elsewhere simultaneously.
                events = {{kind = "face", dx = mx, dy = my}, {kind = "step", dx = mx, dy = my}}
                if w.state == "empty" then events[#events + 1] = {kind = "charge"} end
            end
        end
        if #events > 0 or mx ~= 0 or my ~= 0 then trace[#trace + 1] = {step = step, events = events, dx = mx, dy = my} end
        frame(g, events, mx, my)
    end
    return g, {trace = trace, dodges = dodges, fires = fires, seconds = g.time}
end

local function stationaryAttack(weapon)
    local g = Game.new(42042, true, weapon)
    g:update(0)
    for _ = 1, math.ceil(60 / dt) do
        if g.state ~= "playing" then break end
        local p, events = g.player.grid, {}
        local w = g.player.weapon
        for _, e in ipairs(g:entities()) do
            if e.enemy and e.health.current > 0 and lineTarget(g, p.x, p.y, e, 30) then
                events[#events + 1] = {kind = "face", dx = e.grid.x == p.x and 0 or e.grid.x > p.x and 1 or -1,
                    dy = e.grid.y == p.y and 0 or e.grid.y > p.y and 1 or -1}
                if w.state == "ready" then events[#events + 1] = {kind = "fire"} end
                break
            end
        end
        if w.state == "empty" then events[#events + 1] = {kind = "charge"} end
        frame(g, events)
    end
    return g
end

local function replayAtRenderRate(weapon, report, fps)
    local copy, cursor, tick, accumulator = Game.new(42042, true, weapon), 1, 0, 0
    copy:update(0)
    local lastTick = math.floor(report.seconds / dt + .5) + 1
    while tick < lastTick do
        accumulator = accumulator + 1 / fps
        while accumulator >= dt and tick < lastTick do
            tick = tick + 1
            local command = report.trace[cursor]
            if command and command.step == tick then
                frame(copy, command.events, command.dx, command.dy); cursor = cursor + 1
            else frame(copy) end
            accumulator = accumulator - dt
        end
    end
    return copy
end

local function playability()
    for _, weapon in ipairs({"bow"}) do
        local g, report = T.replay(weapon)
        print(string.format("REPLAY %s: %s, %.2fs, HP %d, %d dodges, %d commands", weapon, g.state, report.seconds,
            g.player.health.current, report.dodges, #report.trace))
        check(g.state == "won", weapon .. " bot could not win first room")
        check(report.dodges > 0, weapon .. " replay did not demonstrate a telegraph response")
        for _, fps in ipairs({30, 60, 144}) do
            local copy = replayAtRenderRate(weapon, report, fps)
            check(copy.state == g.state and copy.kills == g.kills and copy.player.health.current == g.player.health.current
                and math.abs(copy.time - g.time) < dt * .5, weapon .. " fixed-step replay changed at " .. fps .. " rendering FPS")
        end
    end
    for _, guard in ipairs({false, true}) do
        local g = Game.new(42042, true, "bow")
        advance(g, 60, guard)
        check(g.state == "dead", "stationary player survived" .. (guard and " using shield" or ""))
    end
    local stationaryWins = {}
    for _, weapon in ipairs({"bow"}) do
        local g = stationaryAttack(weapon)
        print("STATIONARY ATTACK " .. weapon .. ": " .. g.state)
        if g.room.cleared then stationaryWins[#stationaryWins + 1] = weapon end
    end
    check(#stationaryWins == 0, "stationary player won by aiming and firing " .. table.concat(stationaryWins, ", "))
end

function T.run()
    inputCallbacks(); movement(); weapons(); telegraphs(); shield(); upgradesAndEnvironment(); boss(); playability(); generation()
    check(require("src.progression").selfCheck(), "progression self-check failed")
    for _, weapon in ipairs({"bow"}) do
        local g, report = T.replay(weapon, 42042, 240, false, nil, true)
        print(string.format("RUN %s: %s, %.2fs, HP %d, %d kills", weapon, g.state, report.seconds, g.player.health.current, g.kills))
        check(g.state == "won", weapon .. " could not complete run")
        check(g.pickaxes == 0, "zero-tool floor completion acquired or required pickaxes")
        check((not g.rooms.refugeId or g.rooms[g.rooms.refugeId].visited) and g.rooms[g.rooms.bossId].cleared,
            "floor replay skipped refuge or boss")
    end
    print(string.format("%d ASSERTIONS PASSED", checks))
    return checks
end
return T
