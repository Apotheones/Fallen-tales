local Game = require("src.game")
local Input = require("src.input")
local game, input, renderer
local screen, helpReturn, accumulator = "title", "title", 0
local timestep = 1 / 120
local pending = {}
local selectedMode = true
local testing, uiTesting, showcase, screenshotPath, scene

local function clearControls()
    input:clear()
    if game then game:clearIntents() end
    pending, accumulator = {}, 0
end

local function restart(practice, seed)
    if practice == nil then practice = game and game.practice or selectedMode end
    selectedMode = practice
    game = Game.new(seed or love.math.random(100000, 999999), practice)
    clearControls()
    pending, accumulator, screen = {}, 0, "playing"
end

local function openHelp()
    helpReturn, screen = screen, "help"
    clearControls()
end

function love.load(args)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(false)
    input = Input.new()
    for _, arg in ipairs(args or {}) do
        if arg == "--test" then testing = true end
        if arg == "--ui-test" then uiTesting = true end
        if arg == "--showcase" then showcase = true end
        if arg:match("^%-%-screenshot=") then screenshotPath = arg:sub(14) end
        if arg:match("^%-%-scene=") then scene, showcase = arg:sub(9), true end
        local width, height = arg:match("^%-%-size=(%d+)x(%d+)$")
        if width then love.window.setMode(tonumber(width), tonumber(height), {resizable = true, minwidth = 900, minheight = 680}) end
    end
    if testing then
        local ok, err = xpcall(function()
            require("tests.floor").run()
            require("tests.terrain").run()
            require("tests.combat").run()
            assert(require("src.render").selfCheck())
            print("RENDER ISOLATION CHECKS PASSED")
        end, debug.traceback)
        print(ok and "ALL CHECKS PASSED" or err)
        local f = io.open(love.filesystem.getSource() .. "/test-results.txt", "w")
        if f then f:write(ok and "ALL CHECKS PASSED\n" or err); f:close() end
        love.event.quit(ok and 0 or 1)
        return
    end
    renderer = require("src.render").new()
    game = Game.new(42042, true)
    if showcase then
        screen = "playing"
        game.player.grid.x, game.player.grid.y = 7, 8
        game.player.weapon.state, game.player.weapon.charge = "ready", .72
        for _, e in ipairs(game:entities()) do
            if e.enemy and e.enemy.kind == "dasher" then
                e.grid.x, e.grid.y = 12, 8
                e.enemy.state, e.enemy.timer, e.enemy.warningDuration = "warn", .55, .85
                e.enemy.dx, e.enemy.dy = -1, 0
                e.enemy.cells = require("src.rooms").line(game.room, 12, 8, -1, 0, 4)
            end
        end
    end
    if scene == "map" or scene == "shop" or scene == "secret" or scene == "targets" then
        game = Game.new(42042, false)
        if scene ~= "map" then
            game:enter(scene == "shop" and game.rooms.shopId or scene == "targets" and game.rooms.superSecretId or game.rooms.secretId)
            game.player.grid.x, game.player.grid.y = math.ceil(game.room.w / 2), math.ceil(game.room.h / 2)
        end
    elseif scene == "boss" or scene == "phase" then
        game = Game.new(42042, false)
        game:enter(game.rooms.bossId)
        game.player.grid.x, game.player.grid.y = 5, 6
        for _, e in ipairs(game:entities()) do
            if e.enemy and e.enemy.kind == "warden" then
                if scene == "phase" then
                    e.health.current, e.enemy.phase2, e.enemy.frontalArmor = 10, true, false
                    game:notify("O Guardião rompeu o selo. Avisos mais rápidos: procure os espaços vazios!")
                end
                game.world:getSystem(require("src.boss")):warn(game, e, "cross", -1, 0)
            end
        end
    elseif scene == "reward" then
        game = Game.new(42042, false)
        game.room.cleared = true
        require("src.progression").offer(game)
    elseif scene == "blast" then
        for _, e in ipairs(game:entities()) do
            if e.resonator then require("src.environment").prime(game, e); break end
        end
    elseif scene == "terrain" or scene == "terrain-after" then
        local Environment = require("src.environment")
        game.player.grid.x, game.player.grid.y = 7, 4
        game.player.facing.dx, game.player.facing.dy = 1, 0
        Environment.impact(game, 8, 4, 1, 0)
        for _, e in ipairs(game:entities()) do
            if e.resonator and e.grid.x == 7 then Environment.prime(game, e) end
        end
        if scene == "terrain-after" then
            game.world:getSystem(Environment):update(.63)
            game.world:emit("flush")
            game.player.grid.x, game.player.grid.y = 13, 3
        end
    elseif scene == "help" then screen = "help"
    elseif scene == "dead" then game.state = "dead"
    elseif scene == "won" then game.state = "won"
    elseif scene == "paused" then screen = "paused" end
    if uiTesting then
        local ok, err = xpcall(function()
            require("tests.ui").run(function() return game, screen, renderer end)
        end, debug.traceback)
        print(ok and "ALL UI CHECKS PASSED" or err)
        local file = io.open(love.filesystem.getSource() .. "/ui-test-results.txt", "w")
        if file then file:write(ok and "ALL UI CHECKS PASSED\n" or err); file:close() end
        love.event.quit(ok and 0 or 1)
    end
end

function love.update(dt)
    if testing then return end
    dt = math.min(dt, .1)
    local frame = input:update()
    for _, event in ipairs(frame.events) do pending[#pending + 1] = event end
    if screen == "playing" and not showcase then
        accumulator = accumulator + dt
        while accumulator >= timestep do
            game:update(timestep, {dx = frame.dx, dy = frame.dy, guard = frame.guard, events = pending})
            pending = {}
            accumulator = accumulator - timestep
            if game.reward or game.state ~= "playing" then clearControls(); break end
        end
    else pending = {} end
    renderer:update(dt, game)
end

function love.draw()
    if testing then return end
    renderer:draw(game, screen)
    if screenshotPath then
        local path = screenshotPath; screenshotPath = nil
        love.graphics.captureScreenshot(function(data)
            local bytes = data:encode("png")
            local file = assert(io.open(path, "wb")); file:write(bytes:getString()); file:close()
            love.event.quit()
        end)
    end
end

function love.keypressed(key, _, repeated)
    if testing or repeated then return end
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen()); return end
    if key == "f2" and renderer then renderer.reducedMotion = not renderer.reducedMotion; return end
    if key == "m" and renderer then renderer.muted = not renderer.muted; return end
    if screen == "title" then
        if key == "return" then restart(true)
        elseif key == "n" then restart(false)
        elseif key == "tab" then openHelp() end
        return
    end
    if screen == "help" then
        if key == "tab" or key == "escape" or key == "return" then screen = helpReturn; clearControls() end
        return
    end
    if key == "escape" then
        screen = screen == "paused" and "playing" or "paused"
        clearControls()
        return
    end
    if screen == "paused" then
        if key == "return" then screen = "playing"; clearControls()
        elseif key == "tab" then openHelp()
        elseif key == "q" then screen = "title"
        elseif key == "r" then restart(nil, game.seed) end
        return
    end
    if key == "tab" then openHelp(); return end
    if game.state ~= "playing" then
        if key == "return" and game.state == "won" and not game.practice then
            game:nextFloor(); clearControls()
        elseif key == "r" then restart(nil, game.seed)
        elseif key == "n" then restart(false)
        elseif key == "return" or key == "q" then screen = "title"
        end
        return
    end
    if game.reward and (key == "1" or key == "2" or key == "3") then
        game:chooseReward(tonumber(key)); clearControls(); return
    end
    if game.reward then return end
    input:pressed(key)
end

function love.keyreleased(key) if input then input:released(key) end end
function love.focus(focused)
    if not focused and screen == "playing" and not showcase and not testing then
        screen = "paused"; clearControls()
    end
end
