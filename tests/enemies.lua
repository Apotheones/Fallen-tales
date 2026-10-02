local Game = require("src.game")
local Rooms = require("src.rooms")
local Enemies = require("src.enemies")
local T = {}
local dt = 1 / 120
local checks = 0

local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function frame(g, events, dx, dy, guard)
    g:update(dt, {events = events or {}, dx = dx or 0, dy = dy or 0, guard = guard or false})
    g.events = {}
end
-- Level-ups queue echo offers that freeze the sim until chosen; drain them.
local function drainOffers(g)
    for _ = 1, 8 do
        if g.reward then g:chooseReward(1) end
        frame(g)
        if not g.reward and g.pendingOffer == 0 then return end
    end
end
local function advance(g, seconds)
    for _ = 1, math.ceil(seconds / dt) do frame(g) end
end
local function fixture()
    return require("tests.arena").reset(Game.new(42042, true))
end
local function spawn(g, x, y, kind)
    local e = g:spawnEnemy(x, y, kind)
    e.enemy.timer = 0
    g.world:emit("flush")
    frame(g)
    return e
end
local function hazards(g)
    local n = 0
    for _, e in ipairs(g:entities()) do if e.hazard then n = n + 1 end end
    return n
end
local function shots(g)
    local n = 0
    for _, e in ipairs(g:entities()) do if e.projectile then n = n + 1 end end
    return n
end
local function movePlayer(g, x, y)
    g.player.grid.x, g.player.grid.y = x, y
end

local function crawler()
    local g = fixture()
    local e = spawn(g, 5, 8, "crawler")
    check(e.enemy.state == "warn" and e.enemy.mode == "bite", "crawler adjacent bite did not warn")
    check(#e.enemy.cells == 1 and e.enemy.cells[1].x == 4 and e.enemy.cells[1].y == 8,
        "crawler bite did not mark the player cell")
    movePlayer(g, 4, 9)
    advance(g, .8)
    check(g.player.health.current == 10 and e.enemy.state == "exposed",
        "crawler bite hit a dodged cell or skipped exposure")
    check(g:damage(e, 2, 4, 9) and e.health.current == 1, "exposed crawler took no bonus damage")
    advance(g, 1.4)
    check(e.enemy.state ~= "exposed", "crawler stayed exposed forever")
    g = fixture()
    e = spawn(g, 5, 8, "crawler")
    advance(g, .8)
    check(g.player.health.current == 9, "crawler bite missed a player that stayed")
end

local function ranger()
    local g = fixture()
    local e = spawn(g, 12, 8, "ranger")
    check(e.enemy.state == "warn" and e.enemy.mode == "shot", "ranger did not warn a line shot")
    local warned = {}
    for _, c in ipairs(e.enemy.cells) do warned[#warned + 1] = Rooms.key(c.x, c.y) end
    movePlayer(g, 6, 10)
    advance(g, .4)
    check(#e.enemy.cells == #warned, "ranger line tracked the player after warning")
    while e.enemy.state == "warn" do frame(g) end
    check(shots(g) > 0, "ranger warning resolved without a shot")
    local guard = 0
    while e.enemy.state ~= "retreat" and guard < 400 do frame(g); guard = guard + 1 end
    check(e.enemy.state == "retreat", "ranger fired but never retreated")
    guard = 0
    while e.enemy.state == "retreat" and guard < 600 do frame(g); guard = guard + 1 end
    check(e.grid.x > 12 and e.grid.x <= 14, "ranger retreat moved the wrong distance")
    check(e.enemy.retreatSteps == 0 or e.enemy.state ~= "retreat", "ranger retreat never ends")
end

local function sower()
    local g = fixture()
    local e = spawn(g, 8, 8, "sower")
    check(e.enemy.state == "warn" and e.enemy.mode == "mark", "sower did not warn a mark")
    local announced = {}
    for _, c in ipairs(e.enemy.cells) do announced[Rooms.key(c.x, c.y)] = true end
    check(#e.enemy.cells >= 2 and announced[Rooms.key(4, 8)], "sower mark ignored the player cell")
    movePlayer(g, 4, 10)
    while e.enemy.state == "warn" do frame(g) end
    local mark
    for _, entity in ipairs(g:entities()) do if entity.hazard then mark = entity end end
    check(mark, "sower warning dropped no hazard")
    for _, c in ipairs(mark.hazard.cells) do
        check(announced[Rooms.key(c.x, c.y)], "hazard detonated outside announced cells")
    end
    for _ = 1, math.ceil(1.2 / dt) do
        frame(g)
        check(hazards(g) <= 1, "sower kept more than one active mark")
    end
    check(hazards(g) == 0, "mark never detonated")
    check(g.player.health.current == 10, "mark blast hit a player outside the mark")
    g = fixture()
    spawn(g, 8, 8, "sower")
    while hazards(g) == 0 do frame(g) end
    advance(g, 1.0)
    check(g.player.health.current == 8, "mark blast did not punish standing still")
end

local function watcher()
    local g = fixture()
    local e = spawn(g, 10, 8, "watcher")
    check(e.enemy.state == "warn" and e.enemy.mode == "cross", "watcher did not warn a cross")
    local axes = {x = false, y = false}
    for _, c in ipairs(e.enemy.cells) do
        if c.x == 10 then axes.x = true end
        if c.y == 8 then axes.y = true end
    end
    check(axes.x and axes.y, "watcher cross missed a cardinal axis")
    movePlayer(g, 6, 10)
    advance(g, .5)
    check(e.grid.x == 10 and e.grid.y == 8, "watcher moved during its own warning")
    while e.enemy.state == "warn" do frame(g) end
    check(shots(g) == 4, "watcher cross fired the wrong number of bolts")
    advance(g, 1.5)
    check(g.player.health.current == 10, "watcher cross hit an off-axis player")
end

local function breaker()
    local g = fixture()
    Rooms.cell(g.room, 7, 8).piece = "wall"
    local e = spawn(g, 10, 8, "breaker")
    check(e.enemy.state == "warn", "breaker did not warn a charge")
    local impact
    for _, c in ipairs(e.enemy.cells) do if c.x == 7 and c.y == 8 and c.impact then impact = true end end
    check(impact, "breaker warning omitted the wall it will smash")
    movePlayer(g, 4, 10)
    advance(g, 2.5)
    check(Rooms.cell(g.room, 7, 8).piece == nil and e.grid.x <= 6,
        "breaker charge did not break through the wall")
    g = fixture()
    local pillar = Rooms.cell(g.room, 7, 8)
    pillar.piece, pillar.state = "pillar", "idle"
    e = spawn(g, 10, 8, "breaker")
    local fall
    for _, c in ipairs(e.enemy.cells) do if c.x == 7 and c.y == 8 then fall = c.fall end end
    check(fall and #fall > 0, "breaker warning omitted the pillar fall path")
    movePlayer(g, 4, 10)
    advance(g, 1.2)
    check(pillar.state == "falling" or pillar.state == "fallen" or pillar.piece == "fallen",
        "breaker charge did not topple the pillar")
end

local function veteran()
    local g = fixture()
    local e = spawn(g, 12, 8, "veteran")
    check(e.enemy.state == "warn" and e.enemy.mode == "dual", "veteran did not warn two shots")
    local first, second
    for _, c in ipairs(e.enemy.cells) do
        if c.shot == 1 then first = c end
        if c.shot == 2 then second = c end
    end
    check(first and second, "veteran warning did not commit both directions")
    check(first.dx ~= second.dx or first.dy ~= second.dy, "veteran shots share a direction")
    movePlayer(g, 6, 10)
    advance(g, .4)
    local still = 0
    for _, c in ipairs(e.enemy.cells) do if c.shot == 2 then still = still + 1 end end
    check(still > 0, "veteran second shot tracked the player after warning")
    while e.enemy.state == "warn" do frame(g) end
    check(shots(g) >= 1, "veteran first shot never fired")
    check(e.enemy.state == "volley", "veteran skipped the second committed shot")
    advance(g, .3)
    check(e.enemy.state == "recover", "veteran never entered its longer recovery")
end

local function bosses()
    check(Enemies.warden.boss and Enemies.demolisher.boss and Enemies.regent.boss,
        "boss flags missing from the catalog")
    local g = fixture()
    local pillar = Rooms.cell(g.room, 7, 8)
    pillar.piece, pillar.state = "pillar", "idle"
    local e = spawn(g, 11, 8, "demolisher")
    check(e.enemy.state == "warn" and e.enemy.mode == "dash", "demolisher did not announce a charge")
    local fall
    for _, c in ipairs(e.enemy.cells) do if c.x == 7 and c.y == 8 then fall = c.fall end end
    check(fall and #fall > 0, "demolisher warning omitted the pillar fall")
    movePlayer(g, 4, 10)
    advance(g, 1.4)
    check(pillar.state == "falling" or pillar.piece ~= "pillar", "demolisher charge left the pillar standing")
    g = fixture()
    e = g:spawnEnemy(12, 8, "regent")
    e.enemy.nextMode, e.enemy.timer = "summon", 0
    g.world:emit("flush")
    frame(g)
    check(e.enemy.state == "warn" and e.enemy.mode == "summon" and #e.enemy.cells == 1,
        "regent summon did not announce the echo cell")
    while e.enemy.state == "warn" do frame(g) end
    local husk
    for _, entity in ipairs(g:entities()) do if entity.enemy and entity.enemy.kind == "husk" then husk = entity end end
    check(husk and husk.enemy.summoned and husk.enemy.state == "dormant", "regent summon spawned no echo")
    local recovery = e.enemy.timer
    g:damage(husk, 99, husk.grid.x - 1, husk.grid.y)
    check(math.abs(e.enemy.timer - recovery - .9) < .00001,
        "destroying the echo did not extend the regent recovery")
    g = fixture()
    e = g:spawnEnemy(12, 8, "regent")
    g:spawnEnemy(6, 4, "husk", true); g:spawnEnemy(6, 12, "husk", true)
    g.world:emit("flush")
    e.enemy.nextMode, e.enemy.timer = "summon", 0
    frame(g)
    check(e.enemy.state ~= "warn" and e.enemy.nextMode ~= "summon", "regent summoned past the two-echo cap")
    g = fixture()
    g:spawnEnemy(6, 4, "husk", true)
    g.world:emit("flush")
    advance(g, 4)
    local crawler
    for _, entity in ipairs(g:entities()) do if entity.enemy and entity.enemy.kind == "crawler" then crawler = entity end end
    check(crawler and crawler.enemy.summoned, "uninterrupted echo never hatched a crawler")
end

local function regentRegressions()
    local g = fixture()
    local e = g:spawnEnemy(12, 8, "regent")
    e.enemy.nextMode, e.enemy.timer = "summon", 0
    g.world:emit("flush")
    frame(g)
    local cell = e.enemy.cells[1]
    check(cell and e.enemy.mode == "summon", "blocked summon fixture did not warn")
    movePlayer(g, cell.x, cell.y)
    while e.enemy.state == "warn" do frame(g) end
    local echoes = 0
    for _, entity in ipairs(g:entities()) do
        if entity.enemy and entity.enemy.kind == "husk" then echoes = echoes + 1 end
    end
    check(echoes == 0 and e.enemy.state == "recover", "blocked summon moved to an unannounced cell")

    g = fixture()
    e = g:spawnEnemy(12, 8, "regent")
    e.enemy.phase2, e.enemy.nextMode, e.enemy.timer = true, "mark", 0
    g.world:emit("flush")
    frame(g)
    local seen = {}
    for _, c in ipairs(e.enemy.cells) do
        local key = Rooms.key(c.x, c.y)
        check(not seen[key], "regent cross contains a duplicate cell")
        seen[key] = true
    end
    check(#e.enemy.cells == 5, "regent cross lost a marked cell")
    while e.enemy.state == "warn" do frame(g) end
    movePlayer(g, 4, 10)
    local victim = g:spawnEnemy(4, 8, "ranger")
    victim.enemy.timer = 99
    g.world:emit("flush")
    advance(g, .75)
    check(victim.health.current == 3, "regent cross did not deal exactly two damage at its center")

    g = fixture()
    e = g:spawnEnemy(12, 8, "regent")
    e.enemy.state = "warn"
    local husk = g:spawnEnemy(11, 8, "husk", true)
    g.world:emit("flush")
    g:damage(husk, 99, 10, 8)
    check(e.enemy.staggered, "echo destroyed during warning lost its pending stagger")
    Enemies.helpers.toRecover(g, e)
    check(math.abs(e.enemy.timer - 1.8) < .00001 and not e.enemy.staggered,
        "pending stagger did not extend the next recovery exactly once")

    for _, fatal in ipairs({false, true}) do
        g = fixture()
        e = g:spawnEnemy(12, 8, "regent")
        e.enemy.state, e.enemy.timer = "recover", .5
        local husk = g:spawnEnemy(11, 8, "husk", true)
        g.world:emit("flush")
        if fatal then g:killFatal(husk, "crushed") else g:damage(husk, 99, 10, 8) end
        check(math.abs(e.enemy.timer - 1.4) < .00001 and not e.enemy.staggered,
            "destroying an echo did not extend the current recovery")
        advance(g, .6)
        check(e.enemy.state == "recover", "regent resumed attacking before its extended recovery ended")
        advance(g, .85)
        check(e.enemy.state == "seek" and not e.enemy.staggered,
            "echo stagger leaked into the next attack cycle")
    end
end

local function composition()
    for seed = 1, 40 do
        for floorNumber = 1, 3 do
            local rooms = Rooms.generate(seed, false, floorNumber)
            local boss = rooms[rooms.bossId]
            local expected = floorNumber == 1 and "warden" or floorNumber == 2 and "demolisher" or "regent"
            check(boss.enemies[1] and boss.enemies[1].kind == expected and boss.bossKind == expected,
                "floor " .. floorNumber .. " boss is not " .. expected)
            local elites = 0
            local allowed = {crawler = true, ranger = true, dasher = true}
            if floorNumber >= 2 then allowed.sower, allowed.watcher = true, true end
            for _, room in ipairs(rooms) do
                if room.elite then elites = elites + 1 end
                if room.kind == "start" or room.kind == "combat" then
                    check(#room.enemies >= 1 and #room.enemies <= 4, "encounter size outside budget")
                    local roles = {}
                    for _, enemy in ipairs(room.enemies) do
                        if room.elite then
                            check(Enemies[enemy.kind].elite or enemy.kind == "crawler",
                                "elite lair holds a common other than crawler")
                        else
                            check(allowed[enemy.kind], "floor " .. floorNumber .. " spawned " .. enemy.kind)
                            roles[({crawler = "melee", dasher = "melee", ranger = "line",
                                sower = "mark", watcher = "cross"})[enemy.kind]] = true
                        end
                        check(Rooms.floor(room, enemy.x, enemy.y), "enemy spawned outside safe floor")
                    end
                    if not room.elite and #room.enemies > 1 then
                        local n = 0
                        for _ in pairs(roles) do n = n + 1 end
                        check(n <= (floorNumber >= 3 and 3 or 2), "encounter exceeded the role budget")
                    end
                end
            end
            check(elites == (floorNumber >= 2 and 1 or 0), "elite side-room marking diverged")
        end
    end
    check(Rooms.generate(7, false, 3)[Rooms.generate(7, false, 3).bossId].enemies[1].kind == "regent",
        "floor three boss is not the regent")
end

local function worldEnd()
    local g = Game.new(7, false, 3)
    g:enter(g.rooms.bossId)
    check(g.room.bossKind == "regent", "floor three boss room did not host the regent")
    if g.dialogue then g:closeDialogue() end
    for _, entity in ipairs(g:entities()) do
        if entity.enemy then g:killFatal(entity, "crushed") end
    end
    frame(g)
    drainOffers(g)
    check(g.room.cleared and not g.reward, "boss room did not clear")
    local door
    for _, candidate in ipairs(g.room.doors) do if candidate.finish then door = candidate end end
    check(door, "boss room lost its exit portal")
    g.player.grid.x, g.player.grid.y = door.x, door.y
    frame(g)
    check(g.state == "won" and g.worldComplete, "floor three victory did not end the world")
    check(not g:nextFloor(), "the world generated a fourth floor")
    local early = Game.new(7, false, 1)
    early:enter(early.rooms.bossId)
    if early.dialogue then early:closeDialogue() end
    for _, entity in ipairs(early:entities()) do
        if entity.enemy then early:killFatal(entity, "crushed") end
    end
    frame(early)
    drainOffers(early)
    check(early.room.cleared, "floor one boss room did not clear")
    for _, candidate in ipairs(early.room.doors) do
        if candidate.finish then early.player.grid.x, early.player.grid.y = candidate.x, candidate.y end
    end
    frame(early)
    check(early.state == "won" and not early.worldComplete, "floor one victory ended the world")
end

function T.run()
    crawler(); ranger(); sower(); watcher(); breaker(); veteran(); bosses(); regentRegressions(); composition(); worldEnd()
    print(string.format("%d ENEMY ASSERTIONS PASSED", checks))
    return checks
end
return T
