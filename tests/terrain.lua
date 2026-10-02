local Game = require("src.game")
local Rooms = require("src.rooms")
local Environment = require("src.environment")
local T = {}

function T.run()
    local checks, dt = 0, 1 / 120
    local directions = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
    local function check(value, message)
        checks = checks + 1
        assert(value, message)
    end
    local function frame(g, events, dx, dy, guard)
        g:update(dt, {events = events or {}, dx = dx or 0, dy = dy or 0, guard = guard or false})
    end
    local function advance(g, seconds)
        for _ = 1, math.ceil(seconds / dt) do frame(g) end
    end
    local function fixture(weapon)
        return require("tests.arena").reset(Game.new(42042, false, weapon))
    end
    local function tile(g, x, y, piece, ground, protected)
        local t = {x = x, y = y, ground = ground or "floor", piece = piece, hits = 0,
            state = "idle", protected = protected}
        g.room.tiles[Rooms.key(x, y)] = t
        return t
    end
    local function target(g, x, y, kind)
        local e = g:spawnEnemy(x, y, kind or "ranger")
        e.enemy.timer, e.enemy.frontalArmor = 1000, false
        g.world:emit("flush")
        return e
    end
    local function mine(g, x, y, dx, dy)
        local result = Environment.mine(g, x, y, dx, dy)
        advance(g, Environment.constants.mineRecovery + dt)
        return result
    end
    local function contains(cells, x, y)
        for _, c in ipairs(cells) do if c.x == x and c.y == y then return true end end
        return false
    end
    local function stamp(cells)
        local keys = {}
        for _, c in ipairs(cells) do keys[#keys + 1] = Rooms.key(c.x, c.y) end
        return table.concat(keys, ",")
    end
    check(Rooms.tile == 40 and Environment.constants.pickaxes == 20 and Environment.constants.hits == 3
        and Environment.constants.fallLength == 5, "named terrain constants changed")

    -- Bow primes a crystal; cover freezes its damage area.
    for _, weapon in ipairs({"bow"}) do
        local run = fixture(weapon)
        local cover = tile(run, 7, 8, "wall")
        local crystal = run:actor(6, 8, "neutral", 1):give("resonator")
        local behind = target(run, 8, 8)
        frame(run, {{kind = "charge"}})
        advance(run, Game.weapons[weapon].chargeTime / Game.weapons[weapon].chargeSpeed)
        frame(run, {{kind = "fire"}}); advance(run, .1)
        check(crystal.resonator.state == "primed" and contains(crystal.resonator.walls, 7, 8),
            weapon .. " could not prime crystal or advertise wall impact")
        check(not contains(crystal.resonator.cells, 8, 8), "blast preview passed cover")
        check(run:move(run.player, 0, 1), "could not leave blast warning")
        advance(run, .7)
        check(not cover.piece and behind.health.current == 5 and run.pickaxes == 20,
            "blast expanded damage or spent player tools")
    end

    local blastRun = fixture()
    tile(blastRun, 7, 8, "wall")
    tile(blastRun, 6, 7, nil, "hole")
    local crystal = blastRun:actor(6, 8, "neutral", 1):give("resonator")
    local behind = target(blastRun, 8, 8)
    Environment.prime(blastRun, crystal)
    check(not contains(crystal.resonator.cells, 6, 7) and not contains(crystal.resonator.cells, 6, 6),
        "ground blast crossed hole")
    Environment.breakWall(blastRun, 7, 8)
    advance(blastRun, .7)
    check(behind.health.current == 5 and blastRun.pickaxes == 20, "removed wall expanded frozen blast")

    for _, weapon in ipairs({"bow"}) do
        local g = fixture(weapon)
        local wall = tile(g, 5, 8, "wall")
        check(g.pickaxes == 20, "run did not start with 20 pickaxes")
        check(not Environment.mine(g, 5, 8, 1, 1) and not Environment.mine(g, 6, 8, 1, 0),
            "mining accepted diagonal or distant piece")
        check(mine(g, 5, 8, 1, 0) and wall.hits == 1 and g.pickaxes == 20, weapon .. " first hit spent a tool")
        check(mine(g, 5, 8, 1, 0) and wall.hits == 2 and g.pickaxes == 20, weapon .. " second hit spent a tool")
        local revision = g.room.revision
        check(mine(g, 5, 8, 1, 0) and not Rooms.cell(g.room, 5, 8).piece and g.pickaxes == 19,
            weapon .. " third hit did not open only one piece")
        check(g.player.grid.x == 4 and g.room.revision > revision, "break moved player or failed to invalidate geometry")
        check(Rooms.floor(g.room, 5, 8) and not mine(g, 5, 8, 1, 0) and g.pickaxes == 19,
            "empty ground received a mining hit")
    end

    local g = fixture()
    local wall = tile(g, 5, 8, "wall")
    frame(g, {{kind = "step", dx = 1, dy = 0}}, 1, 0)
    for _ = 1, 360 do frame(g, nil, 1, 0) end
    check(wall.hits == 1 and g.pickaxes == 20, "held direction repeated mining")
    frame(g, {{kind = "step", dx = 1, dy = 0}})
    advance(g, .2)
    frame(g, {{kind = "step", dx = 1, dy = 0}}, 1, 0)
    for _ = 1, 120 do frame(g, nil, 1, 0) end
    check(not wall.piece and g.pickaxes == 19 and g.player.grid.x == 4, "break auto-advanced while key stayed held")
    frame(g)
    frame(g, {{kind = "step", dx = 1, dy = 0}}, 1, 0)
    advance(g, .2)
    check(g.player.grid.x == 5, "new press did not enter mined opening")

    g = fixture()
    wall = tile(g, 5, 8, "wall")
    g.pickaxes = 0
    check(not mine(g, 5, 8, 1, 0) and wall.hits == 0 and g.pickaxes == 0, "zero tools advanced mining")
    local protected = tile(g, 4, 7, "wall", "floor", true)
    check(not Environment.impact(g, 4, 7, 0, -1) and protected.piece == "wall", "protected frame broke")
    g.pickaxes = 20
    check(not mine(g, 4, 7, 0, -1), "protected frame consumed a hit")
    local e = target(g, 6, 8)
    check(not g:move(e, -1, 0) and wall.hits == 0 and g.pickaxes == 20, "enemy movement mined player stock")

    -- A hole is enterable and transparent to attacks, but never a safe path.
    g = fixture()
    tile(g, 5, 8, nil, "hole")
    check(not Rooms.floor(g.room, 5, 8) and Rooms.enterable(g.room, 5, 8) and not Rooms.blocksAttack(g.room, 5, 8),
        "hole was treated as a wall or safe ground")
    check(contains(Rooms.line(g.room, 4, 8, 1, 0, 3), 7, 8), "attack line stopped at hole")
    local path = Rooms.path(g.room, 4, 8, function(x, y) return x == 6 and y == 8 end)
    check(path and not contains(path, 5, 8), "safe navigation used hole")
    tile(g, 5, 8, "wall", "hole")
    for _ = 1, 3 do mine(g, 5, 8, 1, 0) end
    check(Rooms.cell(g.room, 5, 8).ground == "hole" and not Rooms.cell(g.room, 5, 8).piece,
        "breaking a piece replaced ground underneath")
    e = target(g, 7, 8)
    g:shoot(g.player, 1, 0, 3, .035, nil, "bow"); advance(g, .2)
    check(e.health.current == 2, "projectile could not cross hole")
    g.player.health.immune, g.player.guard.active = 99, true
    check(g:move(g.player, 1, 0) and g.player.motion.falling, "hole did not commit fatal landing")
    check(not g:move(g.player, 0, 1), "committed falling actor escaped")
    frame(g, {{kind = "fire"}, {kind = "charge"}, {kind = "step", dx = 0, dy = 1}}, 0, 1, true)
    check(g.state == "playing" and g.player.health.current == 10, "hole killed before landing time")
    advance(g, .2)
    check(g.state == "dead" and g.player.health.current == 0 and not g.reward, "fatal landing lost priority or respected damage immunity")

    -- Losing the final enemy while a player falls cannot grant a clear/reward.
    g = fixture()
    tile(g, 5, 8, nil, "hole")
    g.room.cleared = false
    check(g:move(g.player, 1, 0), "could not begin priority landing")
    frame(g)
    check(not g.room.cleared and not g.reward and g.state == "playing", "room cleared before fatal landing")
    advance(g, .2)
    check(g.state == "dead" and not g.reward and not g.room.cleared, "reward/clear took priority over hole death")

    for _, kind in ipairs({"dasher", "warden"}) do
        g = fixture()
        tile(g, 6, 8, nil, "hole")
        e = target(g, 5, 8, kind)
        local a = e.enemy
        a.state, a.mode, a.timer, a.dx, a.dy, a.dashIndex = "dash", "dash", 0, 1, 0, 0
        a.cells = Environment.dashLine(g, 5, 8, 1, 0, 4)
        advance(g, .2)
        check(e.health.current == 0 and g.player.health.current == 10, kind .. " committed dash could not fall into hole")

        g = fixture()
        wall = tile(g, 7, 8, "wall")
        e = target(g, 5, 8, kind); a = e.enemy
        a.state, a.mode, a.timer, a.dx, a.dy, a.dashIndex = "dash", "dash", 0, 1, 0, 0
        a.cells = Environment.dashLine(g, 5, 8, 1, 0, 4)
        check(#a.cells == 2 and a.cells[2].impact, kind .. " warning omitted wall impact")
        advance(g, .2)
        check(not wall.piece and e.grid.x == 6 and a.state == "recover" and g.pickaxes == 20,
            kind .. " did not stop after free terrain impact")
        g = fixture()
        tile(g, 7, 8, "wall")
        e = target(g, 5, 8, kind); a = e.enemy
        a.state, a.mode, a.timer, a.dx, a.dy, a.dashIndex = "dash", "dash", 0, 1, 0, 0
        a.cells = Environment.dashLine(g, 5, 8, 1, 0, 4)
        Environment.breakWall(g, 7, 8)
        advance(g, .2)
        check(e.grid.x == 6, kind .. " dash extended after announced wall broke")
    end

    g = fixture()
    tile(g, 7, 8, "wall")
    e = target(g, 5, 8)
    e.enemy.state, e.enemy.timer, e.enemy.dx, e.enemy.dy = "warn", 0, 1, 0
    e.enemy.cells = Rooms.line(g.room, 5, 8, 1, 0, 20)
    Environment.breakWall(g, 7, 8)
    g.player.grid.x = 8
    advance(g, .5)
    check(g.player.health.current == 10, "ranger exceeded frozen shot length after opening")

    for _, d in ipairs(directions) do
        g = fixture()
        local p = tile(g, 9, 8, "pillar")
        g.player.grid.x, g.player.grid.y = 9 - d[1], 8 - d[2]
        for _ = 1, 3 do mine(g, 9, 8, d[1], d[2]) end
        check(p.state == "falling" and p.dx == d[1] and p.dy == d[2] and #p.cells == 5 and g.pickaxes == 19,
            "pillar failed a cardinal side or five-cell preview")
        local announced = stamp(p.cells)
        check(not Environment.impact(g, 9, 8, -d[1], -d[2]) and stamp(p.cells) == announced,
            "pending fall redirected or changed preview")
        advance(g, .7)
        check(not Rooms.cell(g.room, 9, 8).piece, "pillar base did not open")
        for _, c in ipairs(p.cells) do
            check(Rooms.cell(g.room, c.x, c.y).piece == "fallen", "announced segment did not create cover")
        end
        local c = p.cells[1]
        g.player.grid.x, g.player.grid.y = 9, 8
        for _ = 1, 3 do mine(g, c.x, c.y, d[1], d[2]) end
        check(not Rooms.cell(g.room, c.x, c.y).piece and g.pickaxes == 18, "fallen segment did not use same three-hit cost")
        check(Rooms.cell(g.room, p.cells[2].x, p.cells[2].y).piece == "fallen", "segment break removed entire fallen pillar")
    end

    g = fixture()
    local pillar = tile(g, 9, 8, "pillar")
    g.player.grid.x, g.player.grid.y = 8, 8
    mine(g, 9, 8, 1, 0)
    g.player.grid.x, g.player.grid.y = 9, 7
    mine(g, 9, 8, 0, 1)
    g.player.grid.x, g.player.grid.y = 10, 8
    mine(g, 9, 8, -1, 0)
    check(pillar.hits == 3 and pillar.dx == -1 and pillar.dy == 0, "mixed-side hits reset progress or ignored third side")

    for _, obstacle in ipairs({"wall", "portal", "hole"}) do
        g = fixture()
        pillar = tile(g, 8, 8, "pillar")
        local piece = obstacle ~= "hole" and obstacle or nil
        tile(g, 11, 8, piece, obstacle == "hole" and "hole" or "floor", obstacle == "portal")
        local cells = Environment.fallCells(g.room, 8, 8, 1, 0)
        check(contains(cells, 10, 8) and not contains(cells, 12, 8), "fall preview passed terminal " .. obstacle)
        Environment.impact(g, 8, 8, 1, 0)
        local announced = stamp(pillar.cells)
        if obstacle == "wall" then Environment.breakWall(g, 11, 8) end
        advance(g, .7)
        check(stamp(pillar.cells) == announced and not Rooms.cell(g.room, 12, 8).piece,
            "removed obstruction extended frozen fall")
        if obstacle == "hole" then
            check(Rooms.cell(g.room, 11, 8).ground == "hole" and not Rooms.cell(g.room, 11, 8).piece,
                "fallen pillar built a bridge over hole")
        end
    end

    for _, occupied in ipairs({"player", "enemy", "hop"}) do
        g = fixture()
        pillar = tile(g, 8, 8, "pillar")
        local victim = occupied == "enemy" and target(g, 9, 8) or g.player
        if occupied ~= "enemy" then victim.grid.x, victim.grid.y = 9, 8 end
        victim.health.immune = 99
        if victim.guard then victim.guard.active = true end
        Environment.impact(g, 8, 8, 1, 0)
        if occupied == "hop" then
            advance(g, .53)
            check(g:move(victim, 0, 1, .24), "could not reserve fatal hop origin")
        end
        advance(g, .7)
        check(victim.health.current == 0 and Rooms.cell(g.room, 9, 8).piece == "fallen",
            "fall safely shattered or left live actor in cover: " .. occupied)
    end

    local function concurrent(reverse)
        local run = fixture()
        local first = tile(run, 8, 8, "pillar")
        local second = tile(run, 10, 10, "pillar")
        if reverse then Environment.impact(run, 10, 10, 0, -1); Environment.impact(run, 8, 8, 1, 0)
        else Environment.impact(run, 8, 8, 1, 0); Environment.impact(run, 10, 10, 0, -1) end
        local announced = {}
        for _, p in ipairs({first, second}) do for _, c in ipairs(p.cells) do announced[Rooms.key(c.x, c.y)] = true end end
        advance(run, .7)
        local result = {}
        for y = 2, run.room.h - 1 do for x = 2, run.room.w - 1 do
            local key, t = Rooms.key(x, y), Rooms.cell(run.room, x, y)
            if t.piece == "fallen" then
                check(announced[key], "concurrent fall exceeded frozen warning")
                result[#result + 1] = key
            end
        end end
        check(not first.piece and not second.piece, "concurrent fall left base solid")
        return table.concat(result, ",")
    end
    check(concurrent(false) == concurrent(true), "fall order depends on impact insertion")

    g = fixture()
    pillar = tile(g, 8, 8, "pillar")
    local passage = Rooms.cell(g.room, 11, 8)
    passage.passage, passage.protected = true, true
    check(#Environment.fallCells(g.room, 8, 8, 1, 0) == 2, "preview crossed mandatory passage")
    Environment.impact(g, 8, 8, 1, 0); advance(g, .7)
    check(Rooms.floor(g.room, 11, 8) and not Rooms.cell(g.room, 12, 8).piece,
        "fall obstructed mandatory passage or crossed it")

    g = fixture()
    for y = 2, g.room.h - 1 do tile(g, 6, y, "wall") end
    check(not contains(Rooms.line(g.room, 4, 8, 1, 0, 4), 8, 8), "wall failed to block attack line")
    g.player.grid.x = 5
    for _ = 1, 3 do mine(g, 6, 8, 1, 0) end
    check(contains(Rooms.line(g.room, 4, 8, 1, 0, 4), 8, 8), "opening did not immediately update attack line")

    g = fixture()
    wall = tile(g, 5, 8, "wall")
    mine(g, 5, 8, 1, 0)
    local savedRoom = g.room
    g:enter(2); g:enter(1)
    check(g.room == savedRoom and Rooms.cell(g.room, 5, 8).hits == 1 and g.pickaxes == 20,
        "revisit lost partial hits or restored stock")
    mine(g, 5, 8, 1, 0); mine(g, 5, 8, 1, 0)
    local restart = Game.new(42042, false, "bow")
    check(g.pickaxes == 19 and restart.pickaxes == 20 and restart.room ~= savedRoom, "new run did not restore terrain/tool state")

    -- No-tool routes are a layout guarantee, including combinations of pillar sides.
    for seed = 1, 100 do
        for _, room in ipairs(Rooms.generate(seed, false)) do
            local pillars = {}
            for _, t in pairs(room.tiles) do if t.piece == "pillar" then pillars[#pillars + 1] = t end end
            local function routes(copy)
                local starts = {copy.spawn}
                for _, door in ipairs(copy.doors) do
                    local ax, ay = Rooms.arrival(copy, door.side)
                    check(Rooms.floor(copy, ax, ay), "arrival lies in fallen corridor")
                    starts[#starts + 1] = {x = ax, y = ay}
                end
                for _, source in ipairs(starts) do
                    check(Rooms.floor(copy, source.x, source.y), "mandatory spawn/arrival is unsafe")
                    for _, door in ipairs(copy.doors) do
                        if not door.hidden then
                            check(Rooms.path(copy, source.x, source.y, function(x, y) return x == door.x and y == door.y end),
                                "zero-tool arrival-to-exit route blocked: seed " .. seed .. " room " .. room.id)
                        end
                    end
                    for _, actors in ipairs({copy.enemies, copy.targets or {}}) do
                        for _, actor in ipairs(actors) do
                            local cell = Rooms.cell(copy, actor.x, actor.y)
                            if cell.piece ~= "fallen" and cell.ground ~= "hole" then
                                check(Rooms.path(copy, source.x, source.y, function(x, y) return x == actor.x and y == actor.y end),
                                    "fall isolated a surviving actor: seed " .. seed .. " room " .. room.id)
                            end
                        end
                    end
                end
                for _, cell in pairs(copy.tiles) do
                    if cell.passage then check(Rooms.floor(copy, cell.x, cell.y), "fallen pillar covered mandatory passage") end
                end
                for _, c in ipairs(copy.crystals) do check(Rooms.floor(room, c.x, c.y), "crystal generated inside cover/hole") end
            end
            routes(room)
            for mask = 0, 4 ^ #pillars - 1 do
                local copy = {w = room.w, h = room.h, tiles = {}, doors = room.doors, spawn = room.spawn,
                    enemies = room.enemies, crystals = room.crystals, targets = room.targets,
                    doorSlots = room.doorSlots}
                for key, t in pairs(room.tiles) do local c = {}; for k, v in pairs(t) do c[k] = v end; copy.tiles[key] = c end
                local choice = mask
                for _, p in ipairs(pillars) do
                    local d = directions[choice % 4 + 1]; choice = math.floor(choice / 4)
                    local cells = Environment.fallCells(copy, p.x, p.y, d[1], d[2])
                    copy.tiles[Rooms.key(p.x, p.y)].piece = nil
                    for _, c in ipairs(cells) do
                        local t = Rooms.cell(copy, c.x, c.y)
                        if t.ground == "hole" or t.piece or t.passage then break end
                        t.piece = "fallen"
                    end
                end
                routes(copy)
            end
        end
    end
    print(string.format("%d TERRAIN ASSERTIONS PASSED", checks))
    return checks
end

return T
