-- Probe: traverse every room on floor 3 (and the path there), talk to NPCs,
-- buy from the counter, and tick the simulation to surface runtime faults.
local Game = require("src.game")
local Shop = require("src.shop")
local Rooms = require("src.rooms")
local Render = require("src.render")
local Tests = {}

function Tests.run()
    local checks = 0
    local function check(v, m) checks = checks + 1; assert(v, m) end
    local function tick(g, t, events)
        g:update(t or 1 / 60, {dx = 0, dy = 0, guard = false, events = events or {}})
    end
    local renderer = Render.new()
    local function draw(g)
        renderer:update(1 / 60, g, "playing")
        renderer:draw(g, "playing")
    end

    for _, seed in ipairs({42042, 7, 123456}) do
        local g = Game.new(seed, false)
        while g.floorNumber < 3 do
            g.state = "won"; g:nextFloor()
        end
        check(g.floorNumber == 3, "seed " .. seed .. " nao chegou ao andar 3")

        for _, room in ipairs(g.rooms) do
            g:enter(room.id)
            for i = 1, 90 do tick(g) end
            draw(g)
            check(g.player ~= nil, "sala " .. tostring(room.id) .. " perdeu o jogador")
        end

        -- Talk and trade on floor 3 specifically.
        g:enter(g.rooms.shopId)
        local merchant
        for _, e in ipairs(g:entities()) do if e.npc then merchant = e end end
        check(merchant and merchant.npc.id == "merchant", "sem comerciante no andar 3")
        g.player.grid.x, g.player.grid.y = merchant.grid.x, merchant.grid.y + 1
        g.gold = 99
        check(g:interact() and g.dialogue, "dialogo do andar 3 nao abriu")
        draw(g) -- typewriter mid-line
        while g.dialogue.mode == "lines" do
            g.dialogue.reveal = math.huge; g:advanceDialogue()
        end
        draw(g) -- full options menu
        check(g:chooseDialogue(1) and g.dialogue.mode == "shop", "balcao do andar 3 nao abriu")
        draw(g) -- counter view
        check(g:chooseDialogue(1) and g.mapReveal, "mapa do andar 3 nao revelou")
        draw(g) -- minimap fully revealed for the floor
        g:closeDialogue()

        if g.rooms.refugeId then
            g:enter(g.rooms.refugeId)
            local keeper
            for _, e in ipairs(g:entities()) do if e.npc then keeper = e end end
            check(keeper and keeper.npc.id == "keeper", "sem zeladora no refugio do andar 3")
            g.player.grid.x, g.player.grid.y = keeper.grid.x, keeper.grid.y + 1
            check(g:interact() and g.dialogue, "zeladora do andar 3 nao falou")
            g:closeDialogue()
        end

        -- Wander: press interact everywhere while walking combat rooms.
        for _, room in ipairs(g.rooms) do
            g:enter(room.id)
            for i = 1, 30 do tick(g, 1 / 60, {{kind = "interact"}}) end
            for i = 1, 30 do tick(g) end
        end

        -- Real door traversal: stand on each passable door and let update cross it.
        -- A sealed door on the start room is opened through its own dialogue.
        g:enter(1)
        g.gold = 99
        for i = 1, #g.room.doors do
            local door = g.room.doors[i]
            if door.to and not door.hidden then
                g.room.cleared = true
                if door.sealed and not door.unsealed then
                    g.player.grid.x, g.player.grid.y = Rooms.arrival(g.room, door.side)
                    check(g:interact() and g.dialogue, "porta selada ignorou E")
                    while g.dialogue.mode == "lines" do
                        g.dialogue.reveal = math.huge; g:advanceDialogue()
                    end
                    check(g:chooseDialogue(1) and door.unsealed, "selo do andar 3 nao abriu")
                end
                g.player.grid.x, g.player.grid.y = door.x, door.y
                g.player.motion.remaining = 0
                tick(g)
                check(g.room.id == door.to, "porta nao atravessou")
                g:enter(1)
            end
        end

        -- Finish the world on floor 3: clear the boss room, take the exit.
        g:enter(g.rooms.bossId)
        if g.dialogue then g:closeDialogue() end
        for _, e in ipairs(g:entities()) do
            if e.enemy then e.health.current = 1; g:damage(e, 99, e.grid.x, e.grid.y) end
        end
        for i = 1, 30 do
            if g.reward then g:chooseReward(1) end
            tick(g)
        end
        local exit
        for _, door in ipairs(g.room.doors) do if door.finish then exit = door end end
        if exit and g.room.cleared then
            g.player.grid.x, g.player.grid.y = exit.x, exit.y
            g.player.motion.remaining = 0
            tick(g)
            check(g.state == "won" and g.worldComplete, "fim do mundo no andar 3 falhou")
            check(not g:nextFloor(), "andar 4 nao deveria existir")
        end
    end

    print(string.format("explore3.lua: %d checks", checks))
end

return Tests
