local utf8 = require("utf8")
local Game = require("src.game")
local Rooms = require("src.rooms")
local Lore = require("src.lore")
local Dialogue = require("src.dialogue")
local Tests = {}

function Tests.run()
    local checks = 0
    local function check(v, m) checks = checks + 1; assert(v, m) end
    local function tick(g, t, events) g:update(t or .02, {dx = 0, dy = 0, guard = false, events = events or {}}) end
    local function npcAt(g)
        for _, e in ipairs(g:entities()) do if e.npc then return e end end
    end

    check(Dialogue.selfCheck(), "dialogue self-check failed")

    -- Merchant lives in the shop, keeper in the refuge, both on safe floor.
    local g = Game.new(42042, false)
    g:enter(g.rooms.shopId)
    local merchant = npcAt(g)
    check(merchant and merchant.npc.id == "merchant", "shop merchant not spawned")
    check(Rooms.cell(g.room, merchant.grid.x, merchant.grid.y).ground == "floor", "merchant not on floor")
    if g.rooms.refugeId then
        g:enter(g.rooms.refugeId)
        local keeper = npcAt(g)
        check(keeper and keeper.npc.id == "keeper", "refuge keeper not spawned")
        g:enter(g.rooms.shopId)
        merchant = npcAt(g)
    end

    -- NPC blocks its cell but cannot be hurt; arrows would stop on the same rule.
    g.player.grid.x, g.player.grid.y = merchant.grid.x, merchant.grid.y + 1
    check(not g:move(g.player, 0, -1), "player walked into the merchant")
    check(not g:damage(merchant, 99, merchant.grid.x, merchant.grid.y + 1) and merchant.health.current == 1,
        "merchant took damage")

    -- E beside the NPC opens the dialogue, cancels the gesture, freezes the sim.
    g.player.weapon.state, g.player.weapon.charge = "ready", .72
    check(g:interact() and g.dialogue, "interact did not open the dialogue")
    check(g.dialogue.voice == "merchant", "merchant dialogue lost its voice tag")
    check(g.player.weapon.state == "empty" and g.player.weapon.charge == 0,
        "dialogue did not cancel the gesture")
    check(merchant.facing.dy == 1, "merchant did not face the player")
    local frozen = g.time
    tick(g, .5); check(g.time == frozen, "simulation ran during the dialogue")
    check(not g:interact(), "second E re-opened the dialogue")

    -- Typewriter: first E completes the line, second advances.
    local d = g.dialogue
    check(d.mode == "lines" and d.lines == Lore.lines.merchant.first, "first meeting lost the intro")
    d.reveal = 0; Dialogue.advance(g)
    check(d.index == 1 and d.reveal == utf8.len(d.lines[1]), "E did not complete the line first")
    Dialogue.advance(g)
    check(d.index == 2 and d.reveal == 0, "line did not advance")
    while g.dialogue.mode == "lines" do g.dialogue.reveal = math.huge; Dialogue.advance(g) end
    check(g.dialogue.mode == "options", "exhausted lines did not open topics")
    check(not g:chooseDialogue(9) and g.dialogue, "invalid topic charged")
    check(g:chooseDialogue(1) and g.dialogue.mode == "shop", "COMPRAR did not open the counter")
    g:advanceDialogue()
    check(g.dialogue.mode == "options", "E at the counter did not return to topics")
    check(g:chooseDialogue(2) and g.dialogue.mode == "lines", "topic did not open")
    while g.dialogue.mode == "lines" do g.dialogue.reveal = math.huge; Dialogue.advance(g) end
    check(g:chooseDialogue(#g.dialogue.node.options) and not g.dialogue, "SAIR did not close")
    check(g.met.merchant == g.floorNumber, "merchant memory not recorded")

    -- Revisit on the same floor greets short; a new floor brings the new greeting.
    g:interact(); check(g.dialogue.lines == Lore.lines.merchant.again, "revisit repeated the intro")
    g:closeDialogue()
    g.state = "won"; g:nextFloor()
    check(g.floorNumber == 2, "floor did not advance")
    g:enter(g.rooms.shopId)
    merchant = npcAt(g)
    check(merchant and merchant.npc.id == "merchant", "merchant missing on the next floor")
    g.player.grid.x, g.player.grid.y = merchant.grid.x, merchant.grid.y + 1
    g:interact()
    check(g.dialogue and g.dialogue.lines == Lore.lines.merchant.floor[g.floorNumber],
        "new-floor greeting missing")
    g:closeDialogue()

    -- Interact events flow through the input queue like every other edge.
    g = Game.new(42042, false)
    g:enter(g.rooms.shopId)
    merchant = npcAt(g)
    g.player.grid.x, g.player.grid.y = merchant.grid.x, merchant.grid.y + 1
    tick(g, .02, {{kind = "interact"}})
    check(g.dialogue, "interact event did not reach the dialogue")
    tick(g, .02, {{kind = "interact"}})
    check(g.dialogue, "events ran while the dialogue was open")
    g:closeDialogue()
    g.player.grid.x, g.player.grid.y = 1, 1
    check(not g:interact() and not g.dialogue, "E far from a character did something")

    -- XP and levels: sources, the offer queue, and blocked screens.
    local Progression = require("src.progression")
    local xg = Game.new(42042, false)
    xg:enter(1)
    xg.room.cleared = true
    local function freeCell(g2)
        for y = 2, g2.room.h - 1 do for x = 2, g2.room.w - 1 do
            if Rooms.floor(g2.room, x, y) and not g2:occupant(x, y) then return x, y end
        end end
    end
    local function slay(g2, kind, summoned)
        local x, y = freeCell(g2)
        local e = g2:spawnEnemy(x, y, kind, summoned)
        g2:damage(e, 99, x, y + 1)
    end
    check(xg.xp == 0 and xg.level == 1, "new attempt did not start at zero XP")
    slay(xg, "crawler")
    check(xg.xp == 1 and xg.level == 1, "common enemy did not pay 1 XP")
    slay(xg, "breaker")
    check(xg.xp == 4 and xg.level == 2 and xg.pendingOffer == 1,
        "elite did not pay 3 XP nor cross the first level")
    tick(xg)
    check(xg.reward and xg.rewardChoices and #xg.rewardChoices == 3,
        "level offer did not open in the normal flow")
    slay(xg, "warden")
    check(xg.xp == 9 and xg.pendingOffer == 0, "boss did not pay 5 XP")
    slay(xg, "crawler")
    check(xg.xp == 10 and xg.level == 3 and xg.pendingOffer == 1,
        "level up during an open offer did not queue")
    check(xg.reward, "open offer vanished before the choice")
    xg:chooseReward(1)
    check(not xg.reward and xg.pendingOffer == 1, "choice did not release the queue")
    tick(xg)
    check(xg.reward and #xg.rewardChoices == 3, "pending offer did not fire on close")
    xg:chooseReward(1)
    check(not xg.reward and xg.pendingOffer == 0, "second offer did not resolve cleanly")

    local xp = xg.xp
    slay(xg, "crawler", true)
    check(xg.xp == xp, "summoned servant paid XP")

    xg.pendingOffer = 1
    Dialogue.open(xg, {title = "INSCRIÇÃO", lines = {"linha"}})
    tick(xg)
    check(xg.pendingOffer == 1 and not xg.reward, "offer fired during a dialogue")
    xg:closeDialogue()
    tick(xg)
    check(xg.reward, "pending offer did not open after the dialogue")
    xg:chooseReward(1)

    local cg = Game.new(42042, false)
    cg:enter(cg.rooms.secretId)
    for _, e in ipairs(cg:entities()) do
        if e.enemy then cg:damage(e, 99, e.grid.x, e.grid.y + 1) end
    end
    local before = cg.xp
    tick(cg)
    check(cg.room.cleared and cg.room.lootTaken, "secret challenge did not conclude")
    check(cg.xp == before + 2, "challenge did not pay 2 XP")

    local pg = Game.new(42042, true)
    for _, e in ipairs(pg:entities()) do
        if e.enemy then pg:damage(e, 99, e.grid.x, e.grid.y + 1) end
    end
    check(pg.xp == 0 and pg.level == 1 and pg.pendingOffer == 0, "practice paid XP")
    check(Progression.selfCheck(), "progression self-check failed")

    -- Boss intro: one dialogue per attempt per boss, freezing the sim until closed.
    local bg = Game.new(42042, false)
    bg:enter(bg.rooms.bossId)
    check(bg.room.final and bg.room.bossKind == "warden", "floor-1 arena lost its warden")
    check(bg.dialogue and bg.dialogue.title == Lore.bossIntros.warden[1],
        "boss intro did not open on first entry")
    check(bg.dialogue.voice == "boss", "boss intro lost its voice tag")
    check(bg.seenIntro.warden == true, "boss intro was not remembered")
    local bfrozen = bg.time
    tick(bg, .5); check(bg.time == bfrozen, "simulation ran during the boss intro")
    bg:closeDialogue()
    bg:enter(1); bg:enter(bg.rooms.bossId)
    check(not bg.dialogue, "boss intro repeated on re-entry")
    check(bg.seenIntro.warden == true, "intro memory lost between rooms")

    -- Card deck: shuffled queue of catalog ids, one draw per source, reset per attempt.
    local catalog = {}
    for _, card in ipairs(Lore.cards) do catalog[card.id] = card.title end
    local function cardCount(g2)
        local n = 0; for _ in pairs(g2.cards) do n = n + 1 end
        return n
    end
    local ng = Game.new(777, false)
    check(cardCount(ng) == 0 and #ng.cardQueue == #Lore.cards, "new attempt did not start with a full deck")
    local qseen = {}
    for _, id in ipairs(ng.cardQueue) do
        check(catalog[id] and not qseen[id], "card queue holds ids outside the catalog")
        qseen[id] = true
    end
    local drawn = ng:collectCard()
    check(drawn and catalog[drawn] and ng.cards[drawn] == true, "collectCard did not draw a catalog id")
    check(ng.message == "Carta encontrada: " .. catalog[drawn], "card title was not notified")
    check(#ng.cardQueue == #Lore.cards - 1, "collectCard did not consume the queue")

    -- Boss kill pays a card.
    local kb = Game.new(42042, false)
    kb:enter(kb.rooms.bossId); kb:closeDialogue()
    local boss
    for _, e in ipairs(kb:entities()) do if e.enemy and e.enemy.boss then boss = e end end
    check(boss, "boss entity missing in the arena")
    kb:damage(boss, 99, boss.grid.x, boss.grid.y + 1)
    check(cardCount(kb) == 1, "boss kill did not pay a card")

    -- Secret challenge pays a card on top of gold and XP.
    local cg2 = Game.new(42042, false)
    cg2:enter(cg2.rooms.secretId)
    for _, e in ipairs(cg2:entities()) do
        if e.enemy then cg2:damage(e, 99, e.grid.x, e.grid.y + 1) end
    end
    tick(cg2)
    check(cg2.room.lootTaken and cardCount(cg2) == 1, "secret challenge did not pay a card")

    -- Keeper pays a card on the first talk only.
    local rg = Game.new(42042, false)
    if rg.rooms.refugeId then
        rg:enter(rg.rooms.refugeId)
        local keeper = npcAt(rg)
        check(keeper, "keeper missing in the refuge")
        rg.player.grid.x, rg.player.grid.y = keeper.grid.x, keeper.grid.y + 1
        check(rg:interact() and rg.dialogue, "keeper did not open the dialogue")
        check(rg.dialogue.voice == "keeper", "keeper dialogue lost its voice tag")
        check(cardCount(rg) == 1, "first keeper talk did not pay a card")
        rg:closeDialogue()
        check(rg:interact() and rg.dialogue, "keeper did not reopen the dialogue")
        check(cardCount(rg) == 1, "second keeper talk paid a duplicate card")
        rg:closeDialogue()
    end

    -- Treasure room pays a card when it offers the echo, and never again.
    local tg2 = Game.new(42042, false)
    tg2:enter(tg2.rooms.treasureId)
    check(tg2.reward, "treasure did not offer an echo")
    check(cardCount(tg2) == 1, "treasure offer did not pay a card")
    tg2:chooseReward(1)
    tg2:enter(tg2.rooms.treasureId)
    check(not tg2.reward and cardCount(tg2) == 1, "treasure revisit paid twice")

    -- Inscriptions: E adjacent opens INSCRIÇÃO, card ids pay once, far E is inert.
    local ig = Game.new(42042, false)
    local entry = ig.room.inscriptions and ig.room.inscriptions[1]
    check(entry and entry.id == "entrance", "floor-1 start room lost its entrance inscription")
    check((Lore.inscriptionCard or {}).entrance == true,
        "entrance inscription should carry a card (Lore.inscriptionCard)")
    local px, py
    for _, d in ipairs({{0, 1}, {0, -1}, {1, 0}, {-1, 0}}) do
        local ax, ay = entry.x + d[1], entry.y + d[2]
        if Rooms.floor(ig.room, ax, ay) and not ig:occupant(ax, ay) then px, py = ax, ay; break end
    end
    check(px ~= nil, "no free cell beside the entrance inscription")
    ig.player.grid.x, ig.player.grid.y = px, py
    check(ig:interact() and ig.dialogue, "E beside the inscription did not open")
    check(ig.dialogue.voice == "inscription", "inscription dialogue lost its voice tag")
    check(ig.dialogue.title == "INSCRIÇÃO" and ig.dialogue.lines == Lore.inscriptions.entrance.lines,
        "inscription dialogue lost its lines")
    check(entry.read == true, "inscription read was not recorded")
    check(cardCount(ig) == 1, "card inscription did not pay on first read")
    ig:closeDialogue()
    check(ig:interact() and ig.dialogue, "inscription re-read did not reopen")
    check(cardCount(ig) == 1, "inscription re-read paid twice")
    ig:closeDialogue()
    ig.player.grid.x, ig.player.grid.y = 2, 2
    check(not ig:interact() and not ig.dialogue, "E far from the inscription did something")

    -- Floor 3: 'deep' lives in the boss arena or the secret room; every mark sits on floor.
    local fg = Game.new(42042, false, 3)
    local deepKind, sawEntrance
    for i = 1, fg.rooms.regularCount + 2 do
        local r = fg.rooms[i]
        if r then for _, ins in ipairs(r.inscriptions or {}) do
            check(Rooms.floor(r, ins.x, ins.y), "inscription is not on a floor cell")
            check(not (ins.x == r.spawn.x and ins.y == r.spawn.y), "inscription sits on the spawn")
            if ins.id == "deep" then deepKind = r.kind end
            if ins.id == "entrance" then sawEntrance = true end
        end end
    end
    check(deepKind == "boss" or deepKind == "secret", "floor-3 deep inscription is missing or misplaced")
    check(not sawEntrance, "entrance inscription leaked into floor 3")

    print(string.format("dialogue.lua: %d checks", checks))
end

return Tests
