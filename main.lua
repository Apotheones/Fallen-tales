local Game = require("src.game")
local Input = require("src.input")
local Campaign = require("src.campaign")
local Save = require("src.save")
local game, campaign, input, renderer
local mode = "campaign"
local screen, helpReturn, accumulator = "title", "title", 0
local timestep = 1 / 120
local pending = {}
local selectedMode = true
local testing, uiTesting, showcase, screenshotPath, scene, pose, reduced
local captureAfter, captureClock = 0, 0

local function clearControls()
    input:clear()
    if game then game:clearIntents() end
    if campaign then campaign:clearIntents() end
    pending, accumulator = {}, 0
end

local function startCampaign(fresh)
    if fresh then Save.clear() end
    local data = not fresh and Save.read() or nil
    campaign = data and Campaign.restore(data) or Campaign.new()
    mode, screen = "campaign", "campaign"
    clearControls()
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
    if renderer then renderer.helpPage, renderer.helpCard = "guide", 1 end
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
        if arg == "--reduced-motion" then reduced = true end
        if arg:match("^%-%-pose=") then pose = arg:sub(8) end
        if arg:match("^%-%-capture%-after=") then captureAfter = math.max(0, tonumber(arg:sub(17)) or 0) end
        if arg:match("^%-%-screenshot=") then screenshotPath = arg:sub(14) end
        if arg:match("^%-%-scene=") then scene, showcase = arg:sub(9), true end
        local width, height = arg:match("^%-%-size=(%d+)x(%d+)$")
        if width then love.window.setMode(tonumber(width), tonumber(height), {resizable = true, minwidth = 900, minheight = 680}) end
    end
    if testing then
        local ok, err = xpcall(function()
            require("tests.floor").run()
            require("tests.terrain").run()
            require("tests.enemies").run()
            require("tests.combat").run()
            require("tests.dialogue").run()
            require("tests.shop").run()
            require("tests.explore3").run()
            require("tests.explore_campaign").run()
            assert(require("src.render").selfCheck())
            require("tests.pixel").run()
            print("RENDER ISOLATION CHECKS PASSED")
        end, debug.traceback)
        print(ok and "ALL CHECKS PASSED" or err)
        local f = io.open(love.filesystem.getSource() .. "/test-results.txt", "w")
        if f then f:write(ok and "ALL CHECKS PASSED\n" or err); f:close() end
        love.event.quit(ok and 0 or 1)
        return
    end
    renderer = require("src.render").new()
    -- The arcade/three-floor session only exists for internal scenes and tests;
    -- the campaign is the real title flow.
    game = (showcase or uiTesting) and Game.new(42042, true) or nil
    if uiTesting then mode = "internal" end
    if showcase then
        mode = "internal"
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
    if scene == "colina" or scene == "hub" or scene == "colina-doro" or scene == "colina-batalha" then
        mode = "campaign"
        -- Scene captures must not overwrite the player's real save file.
        Save.file = 'scene_campaign_save.lua'
        Save.clear()
        campaign = Campaign.new()
        if scene == "hub" then campaign:travel("hub", "colina") end
        if scene == "colina-doro" then
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 7.5, 4
            campaign:interact()
        elseif scene == "colina-batalha" then
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 19
            campaign:startBattle('T01-01')
        else
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
        end
        screen = "campaign"
    end
    if mode ~= "internal" then goto endScenes end
    if scene == "map" or scene == "map-wide" or scene == "shop" or scene == "secret" or scene == "targets" then
        game = Game.new(42042, false)
        if scene == "map-wide" then
            for _, room in ipairs(game.rooms) do room.visited, room.discovered = true, true end
        elseif scene ~= "map" then
            game:enter(scene == "shop" and game.rooms.shopId or scene == "targets" and game.rooms.superSecretId or game.rooms.secretId)
            game.player.grid.x, game.player.grid.y = math.ceil(game.room.w / 2), math.ceil(game.room.h / 2)
            if scene == "shop" then
                for _, e in ipairs(game:entities()) do
                    if e.npc then game.player.grid.x, game.player.grid.y = e.grid.x, e.grid.y + 1 end
                end
            end
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
                require("src.enemies").helpers.warnCross(game, e, 1.15)
            end
        end
    elseif scene == "reward" then
        game = Game.new(42042, false)
        game.room.cleared = true
        require("src.progression").offer(game)
    elseif scene == "floor2" or scene == "floor3" then
        game = Game.new(42042, false)
        local depth = scene == "floor3" and 3 or 2
        while game.floorNumber < depth do game.state = "won"; game:nextFloor() end
    elseif scene == "seal" or scene == "sealopen" then
        game = Game.new(42042, false)
        game.gold = 9
        local leaf = game.rooms[game.rooms.sealedId]
        for _, room in ipairs(game.rooms) do
            for _, door in ipairs(room.doors) do
                if door.sealed and door.to == leaf.id then
                    game:enter(room.id)
                    local ax, ay = require("src.rooms").arrival(game.room, door.side)
                    game.player.grid.x, game.player.grid.y = ax, ay
                end
            end
        end
        if scene == "sealopen" then
            game:interact()
            while game.dialogue and game.dialogue.mode == "lines" do
                game.dialogue.reveal = math.huge
                game:advanceDialogue()
            end
        end
    elseif scene == "tactic" then
        game = Game.new(42042, false)
        game:enter(2); game:enter(1)
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
    elseif scene == "motion" then
        game.player.grid.x, game.player.grid.y = 7, 7
        game.player.weapon.state, game.player.weapon.charge, game.player.weapon.triggerHeld = "charging", 0, true
    elseif scene == "reference" then
        game.player.grid.x, game.player.grid.y = 12, 6
        game.player.weapon.state, game.player.weapon.charge = "ready", .72
    elseif scene == "help" then screen = "help"
    elseif scene == "cards" then
        for i, card in ipairs(require("src.lore").cards) do
            if i <= 6 then game.cards[card.id] = true end
        end
        renderer.helpPage, renderer.helpCard, screen = "cards", 2, "help"
    elseif scene == "inscription" then
        game = Game.new(42042, false)
        local mark = (game.room.inscriptions or {})[1]
        if mark then
            local Rooms = require("src.rooms")
            for _, d in ipairs({{0, 1}, {1, 0}, {0, -1}, {-1, 0}}) do
                local cell = Rooms.cell(game.room, mark.x + d[1], mark.y + d[2])
                if cell and cell.ground == "floor" and not cell.piece then
                    game.player.grid.x, game.player.grid.y = mark.x + d[1], mark.y + d[2]
                    break
                end
            end
        end
    elseif scene == "intro" then
        game = Game.new(42042, false)
        game:enter(game.rooms.bossId)
    elseif scene == "dead" then game.state = "dead"
    elseif scene == "won" then game.state = "won"
    elseif scene == "dialogue" or scene == "counter" then
        game = Game.new(42042, false)
        game:enter(game.rooms.shopId)
        game.gold = 14
        for _, e in ipairs(game:entities()) do
            if e.npc then
                game.player.grid.x, game.player.grid.y = e.grid.x, e.grid.y + 1
                game:interact()
                break
            end
        end
        if scene == "counter" and game.dialogue then
            while game.dialogue.mode == "lines" do
                game.dialogue.reveal = math.huge
                game:advanceDialogue()
            end
            game:chooseDialogue(1)
        end
    elseif scene == "paused" then screen = "paused" end
    ::endScenes::
    if reduced then renderer.reducedMotion = true end
    if showcase and pose then
        local actor, direction = pose:match('^(%a+)%-(%a+)$')
        local directions = {east = {1, 0}, south = {0, 1}, west = {-1, 0}, north = {0, -1}}
        local f = directions[direction or 'east'] or directions.east
        game.player.facing.dx, game.player.facing.dy = f[1], f[2]
        local p = game.player
        p.weapon.state, p.weapon.charge = 'empty', 0
        if actor == 'move' then
            p.motion.fromX, p.motion.fromY = p.grid.x - f[1], p.grid.y - f[2]
            p.motion.remaining = p.motion.duration / 2
        elseif actor == 'charge' then p.weapon.state, p.weapon.charge = 'charging', .36
        elseif actor == 'ready' then p.weapon.state, p.weapon.charge = 'ready', .72
        elseif actor == 'fire' then p.weapon.state, p.weapon.action = 'action', .1
        elseif actor == 'guard' then p.guard.active = true
        elseif actor == 'mine' then p.weapon.mineTimer, p.weapon.mineDx, p.weapon.mineDy = .04, f[1], f[2]
        elseif actor == 'hurt' then
            renderer.actors:update(0, game, screen, renderer.reducedMotion)
            p.health.current = 9
        elseif actor == 'death' then p.health.current, game.state = 0, 'dead' end
    end
    if uiTesting then
        local ok, err = xpcall(function()
            require("tests.ui").run(function() return game, screen, renderer end)
            require("tests.pixel").runUi(function() return game, screen, renderer end)
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
    captureClock = captureClock + dt
    local frame = input:update()
    if scene == "motion" then frame.dx, frame.dy = 1, 0 end
    for _, event in ipairs(frame.events) do pending[#pending + 1] = event end
    if mode == "campaign" then
        if screen == "campaign" and (not showcase or scene == "colina" or scene == "hub") then
            accumulator = accumulator + dt
            while accumulator >= timestep do
                campaign:update(timestep, {dx = frame.dx, dy = frame.dy})
                pending = {}
                accumulator = accumulator - timestep
                if campaign.dialogue then clearControls(); break end
            end
        else pending = {} end
        renderer:updateCampaign(dt, campaign, screen)
        return
    end
    if screen == "playing" and (not showcase or scene == "motion") then
        accumulator = accumulator + dt
        while accumulator >= timestep do
            game:update(timestep, {dx = frame.dx, dy = frame.dy, guard = frame.guard, events = pending})
            pending = {}
            accumulator = accumulator - timestep
            if game.reward or game.dialogue or game.state ~= "playing" then clearControls(); break end
        end
    else pending = {} end
    renderer:update(dt, game, screen)
end

function love.draw()
    if testing then return end
    if mode == "campaign" then renderer:drawCampaign(campaign, screen, Save.exists())
    else renderer:draw(game, screen) end
    if screenshotPath and captureClock >= captureAfter then
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
    if mode == "campaign" then
        if screen == "title" then
            if key == "return" then startCampaign(false)
            elseif key == "n" and Save.exists() then startCampaign(true)
            elseif key == "tab" then openHelp() end
            return
        end
        if screen == "help" then
            if key == "tab" or key == "escape" or key == "return" then screen = helpReturn; clearControls() end
            return
        end
        if campaign.dialogue then
            if key == "e" or key == "return" then campaign:advanceDialogue()
            elseif key == "escape" or key == "q" then campaign:closeDialogue()
            elseif key:match("^%d$") then campaign:chooseDialogue(tonumber(key)) end
            clearControls()
            return
        end
        if key == "escape" then
            if campaign.scene == "battle" then campaign:endBattle("return")
            else screen = screen == "paused" and "campaign" or "paused" end
            clearControls()
            return
        end
        if screen == "paused" then
            if key == "return" then screen = "campaign"; clearControls()
            elseif key == "tab" then openHelp()
            elseif key == "q" then campaign:checkpoint(); campaign = nil; screen = "title" end
            return
        end
        if key == "tab" then openHelp(); return end
        if key == "e" then campaign:interact(); return end
        input:pressed(key)
        return
    end
    if screen == "title" then
        if key == "return" then restart(true)
        elseif key == "n" then restart(false)
        elseif key == "tab" then openHelp() end
        return
    end
    if screen == "help" then
        if key == "tab" or key == "escape" or key == "return" then screen = helpReturn; clearControls()
        elseif key == "c" and renderer then
            renderer.helpPage = renderer.helpPage == "cards" and "guide" or "cards"
        elseif renderer and renderer.helpPage == "cards" then
            local delta = (key == "w" or key == "up") and -1 or (key == "s" or key == "down") and 1 or 0
            if delta ~= 0 then
                local total = #require("src.lore").cards
                renderer.helpCard = math.max(1, math.min(total, (renderer.helpCard or 1) + delta))
            end
        end
        return
    end
    if game.dialogue then
        if key == "e" or key == "return" then game:advanceDialogue()
        elseif key == "escape" or key == "q" then game:closeDialogue()
        elseif key:match("^%d$") then game:chooseDialogue(tonumber(key)) end
        clearControls()
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
        if key == "return" and game.state == "won" and not game.practice and not game.worldComplete then
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
    if not focused and (screen == "playing" or screen == "campaign") and not showcase and not testing then
        screen = "paused"; clearControls()
    end
end
