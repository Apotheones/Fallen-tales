local Rooms = require("src.rooms")
local Ui = {}

function Ui.run(getState)
    local checks, held, originalKeyboard = 0, {}, love.keyboard.isDown
    local function check(value, message)
        checks = checks + 1
        assert(value, message)
    end
    local function down(key)
        held[key] = true; love.keypressed(key, key, false)
    end
    local function up(key)
        held[key] = nil; love.keyreleased(key)
    end
    local function press(key, repeated)
        if repeated then love.keypressed(key, key, true) else down(key); up(key) end
    end
    local function advance(seconds)
        for _ = 1, math.ceil(seconds * 120) do love.update(1 / 120) end
    end
    local function expectScreen(expected)
        local _, screen = getState()
        check(screen == expected, "expected screen " .. expected .. ", got " .. tostring(screen))
        love.draw()
    end
    local keys = {["1:0"] = "d", ["-1:0"] = "a", ["0:1"] = "s", ["0:-1"] = "w"}
    local function arena(game)
        require("tests.arena").reset(game)
        local p = game.player.grid
        local wall = {x = p.x + 1, y = p.y, ground = "floor", piece = "wall", hits = 0}
        game.room.tiles[Rooms.key(wall.x, wall.y)] = wall
        return wall
    end
    local function terrainCallbacks()
        for _, weapon in ipairs({"bow"}) do
            press("escape"); press("q"); press("return")
            local game = getState()
            local wall, x = arena(game), game.player.grid.x
            held.d = true; love.keypressed("d", "d", false); advance(2)
            love.keypressed("d", "d", true); advance(.2)
            check(wall.hits == 1 and game.pickaxes == 20, weapon .. " held/repeated WASD mined more than once")
            held.d = nil; love.keyreleased("d")
            press("d"); advance(.2)
            check(wall.hits == 2 and game.pickaxes == 20, weapon .. " second callback spent tool")
            held.d = true; love.keypressed("d", "d", false); advance(.5)
            check(not wall.piece and game.pickaxes == 19 and game.player.grid.x == x,
                weapon .. " third callback duplicated cost or advanced held key")
            held.d = nil; love.keyreleased("d"); advance(.02)
            press("d"); advance(.2)
            check(game.player.grid.x == x + 1, weapon .. " fresh callback could not enter opening")
            wall = arena(game)
            down("space"); advance(.02)
            check(game.player.weapon.state == "charging", "could not prepare mining cancellation")
            press("d"); advance(.2)
            check(wall.hits == 1 and game.player.weapon.state == "empty" and game.player.weapon.charge == 0,
                "mining failed to cancel pending weapon charge")
            up("space"); advance(.02)
            held.lshift = true; press("d"); advance(.25)
            check(wall.hits == 1 and game.player.guard.active, "mining ran with active guard")
            held.lshift = nil; love.keyreleased("lshift"); advance(.02)
            down("space"); advance(1); up("space"); advance(.04)
            check(game.player.weapon.state == "action", "could not prepare action recovery intention")
            press("d"); press("d"); press("d"); advance(.5)
            check(wall.hits == 2, "weapon recovery accumulated more than one pending mining intention")
            -- A pending edge is discarded by each screen/focus transition.
            for _, screen in ipairs({"pause", "help", "focus"}) do
                press("d")
                if screen == "pause" then press("escape"); press("return")
                elseif screen == "help" then press("tab"); press("tab")
                else love.focus(false); love.focus(true); press("return") end
                advance(.3)
                check(wall.hits == 2 and game.pickaxes == 19, screen .. " leaked a pending mining callback")
            end
            game.pickaxes = 0
            press("d"); advance(.2)
            check(wall.hits == 2 and game.pickaxes == 0, "zero tools callback progressed or went negative")
        end
    end
    local function realTerrainSequence()
        press("escape"); press("q"); press("1"); press("return")
        local game = getState()
        local simulated, report = require("tests.combat").replay("bow", game.seed, 120, true, true)
        local cursor, last = 1, math.floor(report.seconds * 120 + .5)
        for tick = 1, last do
            local command = report.trace[cursor]
            if command and command.step == tick then
                for _, event in ipairs(command.events) do
                    if event.kind == "step" then press(keys[Rooms.key(event.dx, event.dy)])
                    elseif event.kind == "face" then
                        -- A face event alone means the bot turned; a real press only turns too.
                        local stepped = false
                        for _, other in ipairs(command.events) do
                            if other.kind == "step" and other.dx == event.dx and other.dy == event.dy then
                                stepped = true; break
                            end
                        end
                        if not stepped then press(keys[Rooms.key(event.dx, event.dy)]) end
                    elseif event.kind == "charge" then down("space")
                    elseif event.kind == "fire" then up("space") end
                end
                cursor = cursor + 1
            end
            love.update(1 / 120)
        end
        check(simulated.room.cleared and game.room.cleared and game.state == "playing"
            and game.kills == simulated.kills and game.player.health.current == simulated.player.health.current,
            "real combat callbacks did not clear practice and leave exploration active")
        up("space"); advance(.18)
        local function faceDirection(dx, dy)
            local f = game.player.facing
            if f.dx ~= dx or f.dy ~= dy then press(keys[Rooms.key(dx, dy)]); advance(.03) end
        end
        local function walk(x, y)
            local p = game.player.grid
            local path = Rooms.path(game.room, p.x, p.y, function(nx, ny) return nx == x and ny == y end,
                function(nx, ny) return not game:walkable(nx, ny, game.player) end)
            check(path, "real callback sequence has no safe route to " .. x .. "," .. y)
            for _, c in ipairs(path) do
                local dx, dy = c.x - p.x, c.y - p.y
                faceDirection(dx, dy)
                press(keys[Rooms.key(dx, dy)]); advance(.18)
                check(p.x == c.x and p.y == c.y, "real callback sequence failed cardinal step")
            end
        end
        local wall
        for y = 4, 7 do
            local t = Rooms.cell(game.room, 5, y)
            if t.piece == "wall" then wall = t; break end
        end
        check(wall, "reference room has no remaining mineable divider")
        walk(wall.x - 1, wall.y)
        local before = game.pickaxes
        faceDirection(1, 0)
        for _ = 1, 3 - wall.hits do press("d"); advance(.18) end
        check(not wall.piece and game.pickaxes == before - 1, "real callback sequence did not mine reference wall")
        local pillar = Rooms.cell(game.room, 8, 4)
        check(pillar.piece == "pillar", "reference pillar was lost before the interaction sequence")
        walk(7, 4)
        before = game.pickaxes
        faceDirection(1, 0)
        for _ = 1, 3 - pillar.hits do press("d"); advance(.18) end
        check(pillar.state == "falling" and game.pickaxes == before - 1, "real callbacks failed to announce pillar")
        advance(.7)
        walk(8, 4)
        faceDirection(1, 0)
        for _ = 1, 3 do press("d"); advance(.18) end
        check(not Rooms.cell(game.room, 9, 4).piece and Rooms.cell(game.room, 10, 4).piece == "fallen",
            "real callbacks did not open one fallen segment")
        walk(10, 8)
        faceDirection(1, 0)
        press("d"); advance(.02)
        check(game.player.motion.falling and game.state == "playing", "real callback did not commit hole landing")
        advance(.2)
        check(game.state == "dead", "real callback terrain sequence did not end in fatal hole")
        love.draw()
        press("q"); press("1"); press("return")
        game = getState()
        check(game.pickaxes == 20 and Rooms.cell(game.room, 8, 4).piece == "pillar",
            "new practice did not restore tools/terrain after real sequence")
    end
    local function terrainRenderRates()
        for _, fps in ipairs({30, 60, 144}) do
            press("escape"); press("r")
            local game = getState()
            local wall, x = arena(game), game.player.grid.x
            local function elapsed(seconds)
                for _ = 1, math.ceil(seconds * fps) do love.update(1 / fps) end
            end
            for hit = 1, 3 do
                held.d = true; love.keypressed("d", "d", false); elapsed(.5)
                check(wall.hits == (hit == 3 and 0 or hit) and (hit ~= 3 or not wall.piece)
                    and game.pickaxes == (hit == 3 and 19 or 20) and game.player.grid.x == x,
                    "mining callback changed at " .. fps .. " FPS")
                held.d = nil; love.keyreleased("d"); elapsed(.02)
            end
            local hole = Rooms.cell(game.room, x + 1, game.player.grid.y)
            hole.ground = "hole"
            press("d"); elapsed(.3)
            check(game.state == "dead" and game.pickaxes == 19, "fatal landing changed at " .. fps .. " FPS")
            press("r")
        end
    end
    love.keyboard.isDown = function(key) return held[key] or false end
    local ok, err = xpcall(function()
        expectScreen("title")
        local game, _, renderer = getState()
        local motionOption, audioOption = renderer.reducedMotion, renderer.muted
        press("f2"); press("m")
        check(renderer.reducedMotion ~= motionOption and renderer.muted ~= audioOption, "F2/M did not toggle")
        press("f2"); press("m")
        check(renderer.reducedMotion == motionOption and renderer.muted == audioOption, "F2/M did not restore")
        press("1"); press("2"); press("3"); game = getState()
        check(game.player.weapon.name == "bow", "title controls equipped removed weapon")
        press("return", true); expectScreen("title")
        press("tab"); expectScreen("help")
        check(renderer.helpPage == "guide" and renderer.helpCard == 1, "help did not open on the guide page")
        press("c"); love.draw()
        check(renderer.helpPage == "cards", "C did not switch the guide to the cards page")
        local totalCards = #require("src.lore").cards
        press("w"); press("up")
        check(renderer.helpCard == 1, "W/UP scrolled above the first card")
        press("s"); press("down")
        check(renderer.helpCard == 3, "S/DOWN did not walk the card list")
        for _ = 1, totalCards + 2 do press("s") end
        check(renderer.helpCard == totalCards, "card selection passed the last catalog entry")
        press("c")
        check(renderer.helpPage == "guide", "C did not toggle back to the guide page")
        press("c")
        game.cards = {carta_cartografo_i = true}
        love.draw()
        check(renderer.helpPage == "cards" and game.cards.carta_cartografo_i,
            "page with a collected card failed to render")
        game.cards = {}
        press("escape"); expectScreen("title")
        press("tab"); expectScreen("help")
        check(renderer.helpPage == "guide" and renderer.helpCard == 1, "reopened help kept the cards page")
        press("tab"); expectScreen("title")
        press("return"); expectScreen("playing"); game = getState()
        local seed = game.seed
        check(game.practice and game.player.weapon.name == "bow", "ENTER did not start bow practice")
        press("d"); love.update(.001)
        check(game.player.grid.x == 3, "movement ran before simulation step")
        love.update(.0085)
        check(game.player.grid.x == 4 and game.player.grid.y == 6, "released callback tap lost")
        press("w"); advance(.02)
        check(game.player.grid.y == 6 and game.player.facing.dy == -1, "new-direction tap moved instead of turning")
        press("w"); advance(.4)
        check(game.player.grid.y == 5 and game.player.facing.dy == -1, "faced-direction callback did not step")
        arena(game)
        press("i"); press("1"); press("2"); press("3"); advance(.02)
        check(game.player.weapon.name == "bow" and game.player.weapon.state == "empty", "removed keys affected combat")
        down("space"); advance(.3); up("space"); advance(.8)
        check(game.player.weapon.state == "empty" and game.player.weapon.charge == 0, "early release kept or fired charge")
        down("space"); advance(2)
        check(game.player.weapon.state == "ready", "held ready SPACE fired automatically")
        love.keypressed("space", "space", true); love.keypressed("space", "space", false); advance(.1)
        check(game.player.weapon.state == "ready", "repeat/duplicate callback changed ready charge")
        up("space"); advance(.02)
        check(game.player.weapon.state == "action" and game.player.weapon.charge == 0, "ready release did not fire once")
        down("space"); advance(.3); up("space"); advance(.02)
        check(game.player.weapon.state == "empty", "charge during recovery queued another attack")
        love.keyreleased("space"); advance(.2)
        check(game.player.weapon.state == "empty", "duplicate release fired")
        down("space"); advance(1); down("lshift"); advance(.02)
        check(game.player.guard.active and game.player.weapon.state == "empty", "raising guard did not cancel gesture")
        up("lshift"); up("space"); advance(.2)
        check(game.player.weapon.state == "empty", "release after guard cancellation fired")
        for _, transition in ipairs({"pause", "help", "focus"}) do
            down("space"); advance(1)
            check(game.player.weapon.state == "ready", "fresh charge did not recover after cancel")
            local time, x, y = game.time, game.player.grid.x, game.player.grid.y
            if transition == "pause" then press("escape"); expectScreen("paused")
            elseif transition == "help" then press("tab"); expectScreen("help")
            else love.focus(false); expectScreen("paused"); love.focus(true) end
            up("space"); press("a"); advance(.3)
            check(game.time == time and game.player.weapon.state == "empty", transition .. " failed to freeze/cancel")
            if transition == "help" then press("tab") else press("return") end
            advance(.2)
            check(game.player.grid.x == x and game.player.grid.y == y and game.player.weapon.state == "empty",
                transition .. " leaked pending movement or release")
        end
        press("escape"); expectScreen("paused")
        local time, x, y = game.time, game.player.grid.x, game.player.grid.y
        game:effect("land", x, y); advance(.01)
        local landing = renderer.feedback.landings[Rooms.key(x, y)]
        check(landing and landing.depth > 0, "landing did not animate floor")
        advance(.5)
        check(math.abs(landing.depth) < .001 and game.time == time, "landing presentation advanced simulation")
        press("r"); expectScreen("playing"); game = getState()
        check(game.seed == seed and game.player.weapon.name == "bow" and game.pickaxes == 20
            and game.time == 0 and game.player.health.current == 10, "retry did not reset same seed")
        for _, ending in ipairs({"dead", "won"}) do
            game.state = ending; love.draw(); press("1"); press("2"); press("3")
            check(game.player.weapon.name == "bow", "ending equipped removed weapon")
            press("q"); expectScreen("title"); press("return"); game = getState()
            check(game.practice and game.player.weapon.name == "bow", "ending restart lost bow")
        end
        game.state = "dead"; local sameSeed = game.seed; press("r"); game = getState()
        check(game.seed == sameSeed and game.state == "playing", "death retry changed seed")
        game.state = "won"; press("n"); game = getState()
        check(not game.practice and game.rooms.regularCount >= 7 and game.floorNumber == 1
            and game.player.weapon.name == "bow", "N did not start first generated floor")
        -- Park away from doors/NPCs/marks: a sealed leaf may border the start room.
        local far
        for y = 2, game.room.h - 1 do for x = 2, game.room.w - 1 do
            if Rooms.floor(game.room, x, y) then
                local near = false
                for _, door in ipairs(game.room.doors) do
                    if math.abs(door.x - x) + math.abs(door.y - y) <= 1 then near = true end
                end
                for _, e in ipairs(game:entities()) do
                    if e.npc and math.abs(e.grid.x - x) + math.abs(e.grid.y - y) <= 1 then near = true end
                end
                for _, mark in ipairs(game.room.inscriptions or {}) do
                    if math.abs(mark.x - x) + math.abs(mark.y - y) <= 1 then near = true end
                end
                if not near then far = {x = x, y = y} end
            end
            if far then break end
        end if far then break end end
        game.player.grid.x, game.player.grid.y = far.x, far.y
        local gold = game.gold
        press("e"); advance(.02)
        check(game.gold == gold and not game.dialogue and not game.mapReveal,
            "E far from a character changed the run")
        game:enter(game.rooms.shopId)
        game.gold = 10
        local merchant
        for _, e in ipairs(game:entities()) do if e.npc then merchant = e end end
        check(merchant and merchant.npc.id == "merchant", "shop merchant missing")
        game.player.grid.x, game.player.grid.y = merchant.grid.x, merchant.grid.y + 1
        local known = {}
        for _, room in ipairs(game.rooms) do known[room.id] = game:mapVisible(room) end
        down("space"); advance(1)
        check(game.player.weapon.state == "ready", "could not prepare a charge beside the merchant")
        press("e"); advance(.02)
        check(game.dialogue and game.player.weapon.state == "empty",
            "E beside the merchant did not open dialogue and cancel the charge")
        check(game.gold == 10 and not game.mapReveal, "talking spent gold or revealed the map")
        press("escape"); up("space"); advance(.02)
        check(not game.dialogue and game.player.weapon.state == "empty",
            "ESC did not close the dialogue cleanly")
        for _, room in ipairs(game.rooms) do
            check(game:mapVisible(room) == known[room.id], "dialogue changed minimap discovery")
        end
        advance(.3)
        -- Reward indices still work while weapon-selection indices do nothing.
        game:enter(game.rooms.treasureId); love.draw()
        check(#game.rewardChoices == 3, "reward lost three choices")
        press("2"); advance(.02)
        check(not game.reward and game.room.rewardTaken and game.player.weapon.name == "bow", "reward index did not choose card")
        game.player.health.current, game.gold, game.pickaxes, game.upgrades.bowQuick = 7, 11, 13, true
        down("space"); advance(1); game.state = "won"
        press("return"); advance(.02); game = getState()
        check(game.floorNumber == 2 and game.state == "playing" and game.player.health.current == 7
            and game.gold == 11 and game.pickaxes == 13 and game.upgrades.bowQuick
            and not game:mapVisible(game.rooms[game.rooms.secretId]), "ENTER did not preserve run state on descent")
        up("space"); advance(.2)
        check(game.player.weapon.state == "empty", "descent accepted stale SPACE release")
        local screenTime = game.time; love.draw(); love.draw()
        check(game.time == screenTime, "draw advanced combat time")
        terrainCallbacks()
        realTerrainSequence()
        terrainRenderRates()
        -- Charge/hold/release and early cancel use the same fixed-step result at each render rate.
        for _, fps in ipairs({30, 60, 144}) do
            press("escape"); press("r"); game = getState(); arena(game)
            local function elapsed(seconds)
                for _ = 1, math.ceil(seconds * fps) do love.update(1 / fps) end
            end
            down("space"); elapsed(.2); up("space"); elapsed(1)
            check(game.player.weapon.state == "empty", "early release changed at " .. fps .. " FPS")
            down("space"); elapsed(1.5)
            check(game.player.weapon.state == "ready", "held readiness changed at " .. fps .. " FPS")
            up("space"); elapsed(.04)
            check(game.player.weapon.state == "action" and game.player.weapon.charge == 0, "release changed at " .. fps .. " FPS")
            elapsed(.5); love.keyreleased("space"); elapsed(.3)
            check(game.player.weapon.state == "empty", "release repeated at " .. fps .. " FPS")
        end
        press("escape"); press("q"); expectScreen("title")
        if renderer.reducedMotion ~= motionOption then press("f2") end
        if renderer.muted ~= audioOption then press("m") end
        print(string.format("%d NATIVE UI CALLBACK ASSERTIONS PASSED", checks))
    end, debug.traceback)
    love.keyboard.isDown = originalKeyboard
    assert(ok, err)
    return checks
end

return Ui
