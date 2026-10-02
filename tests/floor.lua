local Rooms = require("src.rooms")
local Game = require("src.game")
local Environment = require("src.environment")
local Enemies = require("src.enemies")
local T = {}
local sides = {east = {1, 0}, west = {-1, 0}, north = {0, -1}, south = {0, 1}}
local opposite = {east = "west", west = "east", north = "south", south = "north"}

-- Normal graph navigation for the combat replay; secret connections are optional.
function T.route(rooms, from, target)
    local queue, head, seen = {{id = from}}, 1, {[from] = true}
    while head <= #queue do
        local node = queue[head]; head = head + 1
        if node.id == target then
            local route = {}
            while node.parent do table.insert(route, 1, node.door); node = node.parent end
            return route
        end
        for _, door in ipairs(rooms[node.id].doors) do
            if door.to and not door.hidden and not seen[door.to] then
                seen[door.to] = true
                queue[#queue + 1] = {id = door.to, door = door, parent = node}
            end
        end
    end
end

local function signature(rooms)
    local fields = {tostring(rooms.floorNumber), tostring(rooms.regularCount)}
    for _, room in ipairs(rooms) do
        fields[#fields + 1] = table.concat({room.id, room.kind, room.mapX, room.mapY, room.distance,
            room.w, room.h, room.spawn.x, room.spawn.y}, ":")
        for _, door in ipairs(room.doors) do
            fields[#fields + 1] = table.concat({door.side, door.to or "finish", door.arrival or "", door.x, door.y,
                tostring(door.hidden), tostring(door.secretTo)}, ":")
        end
        for y = 1, room.h do for x = 1, room.w do
            local tile = Rooms.cell(room, x, y)
            fields[#fields + 1] = table.concat({tile.ground, tile.piece or "", tostring(tile.protected)}, ":")
        end end
        for _, e in ipairs(room.enemies) do fields[#fields + 1] = table.concat({e.kind, e.x, e.y}, ":") end
    end
    return table.concat(fields, "|")
end

function T.run()
    local checks = 0
    local function check(value, message)
        checks = checks + 1; assert(value, message)
    end
    local function adjacent(a, b) return math.abs(a.mapX - b.mapX) + math.abs(a.mapY - b.mapY) == 1 end
    local seenArchetypes, doorOffsets = {[1] = {}, [2] = {}, [3] = {}}, {}
    for seed = 1, 128 do
        local previousCount
        for floorNumber = 1, 4 do
            local rooms = Rooms.generate(seed, false, floorNumber)
            local n = rooms.regularCount
            check(rooms.floorNumber == floorNumber and #rooms == n + 2, "floor metadata/count diverged")
            check(n == math.floor(5 + floorNumber * 2.6) or n == math.floor(5 + floorNumber * 2.6) + 1,
                "floor does not scale by 2/3 regular rooms")
            if previousCount then check(n - previousCount >= 2 and n - previousCount <= 3, "same seed changed floor growth") end
            previousCount = n
            check(signature(rooms) == signature(Rooms.generate(seed, false, floorNumber)), "generation is not deterministic")
            check(rooms[1].kind == "start" and rooms[1].mapX == 0 and rooms[1].mapY == 0 and rooms[1].distance == 0,
                "start is not the graph origin")
            local occupied, kinds, edges, maxDistance = {}, {}, 0, 0
            local leaves = 0
            for _, room in ipairs(rooms) do
                local key = Rooms.key(room.mapX, room.mapY)
                check(not occupied[key], "map coordinates overlap")
                occupied[key] = room
                kinds[room.kind] = (kinds[room.kind] or 0) + 1
                check(Rooms.floor(room, room.spawn.x, room.spawn.y), "room spawn is not safe")
                if room.archetype then
                    seenArchetypes[math.min(floorNumber, 3)][room.archetype] = true
                    local fits = false
                    for _, s in ipairs(Rooms.archetypes[room.archetype].sizes) do
                        if s[1] == room.w and s[2] == room.h then fits = true break end
                    end
                    check(fits, "archetype room escaped its size catalog")
                else
                    check(room.w == (room.kind == "boss" and 15 or 13) and room.h == 9,
                        "special room is not compact")
                end
                if room.doorSlots then
                    for side, slot in pairs(room.doorSlots) do
                        local vertical = side == "east" or side == "west"
                        local along = vertical and slot.y or slot.x
                        local center = math.ceil((vertical and room.h or room.w) / 2)
                        doorOffsets[along - center] = true
                    end
                end
                local degree = 0
                for _, door in ipairs(room.doors) do
                    check(sides[door.side] and (door.x == 1 or door.x == room.w or door.y == 1 or door.y == room.h),
                        "door is not a cardinal perimeter opening")
                    if door.to then
                        local other, reverse = rooms[door.to]
                        check(other and adjacent(room, other), "door does not match adjacent map cell")
                        local d = sides[door.side]
                        check(other.mapX == room.mapX + d[1] and other.mapY == room.mapY + d[2], "door side contradicts map")
                        for _, candidate in ipairs(other.doors) do
                            if candidate.to == room.id and candidate.side == opposite[door.side] then reverse = candidate; break end
                        end
                        check(reverse and door.arrival == reverse.side and reverse.arrival == door.side, "door has no reciprocal arrival")
                        local ax, ay = Rooms.arrival(other, door.arrival)
                        check(Rooms.floor(other, ax, ay), "arrival is unsafe")
                        if door.hidden then
                            local tile = Rooms.cell(room, door.x, door.y)
                            check(reverse.hidden and tile.piece == "wall" and not tile.protected and tile.secretDoor == door,
                                "secret entrance is not a paired mineable wall")
                            check(door.secretTo == rooms.secretId or door.secretTo == rooms.superSecretId,
                                "hidden door lost secret identity")
                        else
                            degree = degree + 1; edges = edges + 1
                            check(Rooms.floor(room, door.x, door.y), "normal portal is blocked")
                        end
                    else
                        check(door.finish and room.id == rooms.bossId, "finish is outside boss room")
                    end
                    if not door.hidden then
                        check(Rooms.path(room, room.spawn.x, room.spawn.y, function(x, y) return x == door.x and y == door.y end),
                            "normal exit requires mining")
                    end
                end
                local mask = Rooms.reachable(room)
                check(mask[Rooms.key(room.spawn.x, room.spawn.y)], "spawn is sealed off without tools")
                for _, door in ipairs(room.doors) do
                    if not door.hidden then
                        check(mask[Rooms.key(door.x, door.y)], "exit sits outside the no-tool ring")
                        local onSide = door.x == 1 or door.x == room.w
                        check((onSide and door.y >= 3 and door.y <= room.h - 2)
                            or (not onSide and door.x >= 3 and door.x <= room.w - 2), "door hugs a corner")
                    end
                end
                for _, e in ipairs(room.enemies) do
                    check(mask[Rooms.key(e.x, e.y)], string.format(
                        "enemy in sealed pocket: seed %d floor %d room %d %s/%s at %d,%d",
                        seed, floorNumber, room.id, room.kind, tostring(room.archetype), e.x, e.y))
                end
                for _, c in ipairs(room.crystals) do
                    check(mask[Rooms.key(c.x, c.y)], "crystal spawned in a sealed pocket")
                end
                if room.id <= n then
                    local route = T.route(rooms, 1, room.id)
                    check(route and #route == room.distance, "regular room distance/reachability diverged")
                    maxDistance = math.max(maxDistance, room.distance)
                    if degree == 1 and room.id ~= 1 then leaves = leaves + 1 end
                    if room.kind == "boss" or room.kind == "shop" or room.kind == "treasure" or room.kind == "refuge" then
                        check(degree == 1, "special regular room is not a dead end")
                    end
                    for _, other in ipairs(rooms) do
                        if other.id <= n and other.id > room.id and adjacent(room, other) then
                            local connected = false
                            for _, door in ipairs(room.doors) do if door.to == other.id and not door.hidden then connected = true end end
                            check(connected, "adjacent regular cells have no normal connection")
                        end
                    end
                end
                if room.kind == "secret" then
                    local elite = room.enemies[1]
                    check(not room.cleared and room.challenge == "combat" and #room.enemies >= 1 and #room.crystals == 0
                        and elite and Enemies[elite.kind] and Enemies[elite.kind].elite,
                        "secret elite lair is missing")
                elseif room.kind == "supersecret" then
                    check(not room.cleared and room.challenge == "targets" and #room.enemies == 0 and #room.targets == 3,
                        "supersecret target challenge is missing")
                elseif room.kind ~= "start" and room.kind ~= "combat" and room.kind ~= "boss" then
                    check(room.cleared and #room.enemies == 0 and #room.crystals == 0, "quiet room contains ordinary combat")
                end
            end
            check(edges == 2 * (n - 1), "regular graph is not a tree")
            check(kinds.start == 1 and kinds.boss == 1 and kinds.shop == 1 and kinds.treasure == 1
                and kinds.secret == 1 and kinds.supersecret == 1, "floor special counts changed")
            check(rooms[rooms.bossId].distance == maxDistance and rooms[rooms.bossId].kind == "boss", "boss is not farthest dead end")
            check(rooms[rooms.shopId].kind == "shop" and rooms[rooms.treasureId].kind == "treasure", "special IDs disagree with kinds")
            check(rooms.sealedId == rooms.treasureId or rooms.sealedId == rooms.refugeId,
                "seal escaped the special leaves")
            local sealEnds = 0
            for _, room in ipairs(rooms) do
                for _, door in ipairs(room.doors) do
                    if door.sealed then
                        sealEnds = sealEnds + 1
                        check(not door.hidden and door.sealCost == 3 and not door.unsealed
                            and (room.id == rooms.sealedId or door.to == rooms.sealedId),
                            "seal record is malformed or on the wrong link")
                    end
                end
            end
            check(sealEnds == 2, "seal did not mark both door endpoints")
            check((leaves >= 4 and rooms.refugeId and kinds.refuge == 1)
                or (leaves == 3 and not rooms.refugeId and not kinds.refuge), "refuge does not match fourth leaf")
            local secret, super = rooms[rooms.secretId], rooms[rooms.superSecretId]
            check(secret.kind == "secret" and super.kind == "supersecret" and not adjacent(secret, super), "secrets overlap or touch")
            for _, room in ipairs({secret, super}) do
                local neighbours = 0
                for i = 1, n do if adjacent(room, rooms[i]) then neighbours = neighbours + 1 end end
                check(neighbours >= 2 and #room.doors == neighbours and not adjacent(room, rooms[rooms.bossId]),
                    "secret lacks multiple regular neighbours or touches boss")
            end
        end
    end
    for floorNumber, theme in pairs(Rooms.floorThemes) do
        for _, id in ipairs(theme.pool) do
            check(seenArchetypes[floorNumber][id], "archetype never rolled on floor " .. floorNumber .. ": " .. id)
        end
    end
    local offsetCount = 0
    for _ in pairs(doorOffsets) do offsetCount = offsetCount + 1 end
    check(offsetCount >= 3, "door slots never left the center")
    for _, invalid in ipairs({0, -1, .5, "bow", math.huge, -math.huge}) do
        check(Rooms.generate(42, false, invalid).floorNumber == 1, "invalid floor was not normalized")
    end
    check(Rooms.generate(42, false, 0 / 0).floorNumber == 1, "NaN floor was not normalized")
    local practiceRooms = Rooms.generate(42, true, 4)
    check(#practiceRooms == 1 and practiceRooms[1].w == 17 and practiceRooms[1].h == 11, "practice is not one compact room")

    local function frame(g) g:update(1 / 120, {dx = 0, dy = 0, guard = false, events = {}}) end
    local g = Game.new(42042, false)
    check(g.gold == 0 and g.floorNumber == 1, "run initial economy/floor changed")
    check(not g:nextFloor(), "unfinished floor descended")
    local combatId
    for _, room in ipairs(g.rooms) do if room.kind == "combat" then combatId = room.id; break end end
    check(combatId, "generated floor has no combat room")
    g:enter(combatId)
    for _, entity in ipairs(g:entities()) do if entity.enemy then g:killFatal(entity, "crushed") end end
    frame(g)
    check(g.gold == 2 and g.room.goldTaken and g.room.cleared, "combat clear did not grant two gold once")
    if g.reward then g:chooseReward(1) end
    g:enter(1); g:enter(combatId); frame(g)
    check(g.gold == 2 and g:enemyCount() == 0 and not g.reward, "revisit farmed combat gold/reward")

    g:enter(g.rooms.treasureId)
    check(g.reward and #g.rewardChoices == 3 and g:enemyCount() == 0, "treasure did not offer one reward without combat")
    check(g:chooseReward(1), "treasure reward could not be selected")
    local treasureGold = g.gold
    g:enter(1); g:enter(g.rooms.treasureId); frame(g)
    check(not g.reward and g.gold == treasureGold and g.room.rewardTaken, "treasure revisit farmed a reward")

    if g.rooms.refugeId then
        g.player.health.current = 5; g:enter(g.rooms.refugeId)
        check(g.player.health.current == 9, "refuge did not heal four")
        g.player.health.current = 5; g:enter(1); g:enter(g.rooms.refugeId)
        check(g.player.health.current == 5, "refuge revisit farmed healing")
    end
    g = Game.new(42042, false)
    local secret = g.rooms[g.rooms.secretId]
    check(not g:mapVisible(secret), "normal discovery revealed secret")
    local neighbours = {[1] = true}
    for _, door in ipairs(g.room.doors) do if door.to and not door.hidden then neighbours[door.to] = true end end
    for i = 1, g.rooms.regularCount do
        check((g:mapVisible(g.rooms[i]) or false) == (neighbours[i] or false), "initial discovery leaked or omitted a normal neighbour")
    end
    g:enter(g.rooms.shopId)
    check(g.room.cleared and g:enemyCount() == 0 and not g.reward and g.gold == 0,
        "quiet shop granted combat or loot")
    local merchant
    for _, e in ipairs(g:entities()) do if e.npc then merchant = e end end
    check(merchant and merchant.npc.id == "merchant" and not g.mapReveal and not g.blueMap,
        "shop lost its merchant or leaked map machinery")
    for _, room in ipairs(g.rooms) do
        check((g:mapVisible(room) or false) == (room.visited or room.discovered or false), "minimap shows unexplored room")
    end

    g = Game.new(42042, false)
    secret = g.rooms[g.rooms.secretId]
    local entrance = secret.doors[1]
    g:enter(entrance.to)
    local door
    for _, candidate in ipairs(g.room.doors) do if candidate.to == secret.id then door = candidate; break end end
    check(door and door.hidden and not door.revealed, "secret entrance missing")
    g.player.grid.x, g.player.grid.y = Rooms.arrival(g.room, door.side)
    local d = sides[door.side]
    for hit = 1, 3 do
        check(Environment.mine(g, door.x, door.y, d[1], d[2]), "secret wall rejected cardinal hit")
        check(g.pickaxes == (hit == 3 and 19 or 20), "secret wall mining cost is not one completion")
    end
    check(door.revealed and entrance.revealed and g:mapVisible(secret), "secret mining did not reveal reciprocal connection/map")
    check(Rooms.cell(g.room, door.x, door.y).piece == "portal"
        and Rooms.cell(secret, entrance.x, entrance.y).piece == "portal", "revealed secret walls did not become portals")
    for i = 2, #secret.doors do check(not secret.doors[i].revealed, "mining opened unrelated secret entrances") end
    local gold = g.gold
    g:enter(secret.id, door.arrival)
    check(g.gold == gold and not g.reward and not g.room.cleared and g:enemyCount() == #secret.enemies,
        "entering secret granted loot before challenge")
    for _, exit in ipairs(g.room.doors) do
        check(exit.revealed and g:canLeave(exit) and Rooms.cell(g.room, exit.x, exit.y).piece == "portal",
            "inside secret did not open free exits")
    end
    g.pickaxes = 0
    local exit = g.room.doors[1]
    g.player.grid.x, g.player.grid.y = Rooms.arrival(g.room, exit.side)
    check(g:walkable(exit.x, exit.y, g.player), "uncleared optional secret trapped zero-tool player")
    g:enter(exit.to, exit.arrival); g:enter(secret.id)
    check(g.gold == gold and not g.reward, "unfinished secret revisit granted loot")
    for _, entity in ipairs(g:entities()) do if entity.enemy then g:killFatal(entity, "crushed") end end
    frame(g)
    check(g.gold == gold + 4 and g.reward and #g.rewardChoices == 3 and g.room.lootTaken and g.room.cleared,
        "secret combat completion did not grant four gold and one reward")
    check(g:chooseReward(1), "secret reward could not be selected")
    while g.pendingOffer > 0 do
        frame(g)
        check(g.reward and #g.rewardChoices == 3, "queued level-up offer did not fire after the challenge")
        check(g:chooseReward(1), "queued level-up offer could not be selected")
    end
    g:enter(1); g:enter(secret.id); frame(g)
    check(g.gold == gold + 4 and not g.reward and g:enemyCount() == 0, "completed secret revisit farmed loot")

    g.player.health.current = 5; gold = g.gold
    g:enter(g.rooms.superSecretId)
    check(g.gold == gold and g.player.health.current == 5 and not g.reward and g:targetCount() == 3,
        "supersecret granted reward on entry or omitted targets")
    local hp = g.player.health.current
    for _ = 1, 120 do frame(g) end
    check(g.player.health.current == hp and g:targetCount() == 3, "targets attacked player or completed without shots")
    local first
    for _, entity in ipairs(g:entities()) do if entity.target then first = entity; break end end
    check(first and not g:damage(first, 99, first.grid.x, first.grid.y, "blast") and g:targetCount() == 3,
        "non-arrow damage solved a target")
    check(g:damage(first, 3, first.grid.x - 1, first.grid.y, "bow") and g:targetCount() == 2,
        "player bow could not solve target")
    local remembered = first.target.data
    check(remembered.hit, "solved target was not persisted in room data")
    g:enter(1); g:enter(g.rooms.superSecretId)
    check(g:targetCount() == 2 and remembered.hit and g.gold == gold and not g.reward,
        "partial target challenge reset or rewarded on revisit")
    local remaining
    for _, entity in ipairs(g:entities()) do if entity.target then remaining = entity; break end end
    check(remaining, "remaining target did not respawn")
    g:killFatal(remaining, "crushed"); frame(g)
    check(g:targetCount() == 2 and not g.reward, "crushing target completed bow-only challenge")
    g:enter(1); g:enter(g.rooms.superSecretId)
    -- Real player projectiles finish the remaining targets, with no direct target damage call.
    local targets = {}
    for _, entity in ipairs(g:entities()) do if entity.target then targets[#targets + 1] = entity end end
    for _, target in ipairs(targets) do
        g.player.grid.x, g.player.grid.y = target.grid.x - 1, target.grid.y
        g:shoot(g.player, 1, 0, 3, .035, nil, "bow")
        for _ = 1, 12 do frame(g) end
    end
    check(g:targetCount() == 0 and g.room.cleared and g.gold == gold + 6 and g.player.health.current == 7
        and g.reward and #g.rewardChoices == 3, "target completion did not grant six gold, healing and one reward")
    check(g:chooseReward(1), "supersecret reward could not be selected")
    g.player.health.current = 5; g:enter(1); g:enter(g.rooms.superSecretId); frame(g)
    check(g.gold == gold + 6 and g.player.health.current == 5 and not g.reward and g:targetCount() == 0,
        "completed target challenge farmed loot/healing")

    local oldRooms = g.rooms
    g.player.health.current, g.pickaxes, g.gold = 7, 12, 17
    g.upgrades.bowQuick, g.damageBonus = true, 2
    g.state = "won"
    check(g:nextFloor() and g.floorNumber == 2 and g.rooms ~= oldRooms and g.state == "playing" and g.roomId == 1,
        "won floor did not descend into a fresh generated floor")
    check(g.player.health.current == 7 and g.pickaxes == 12 and g.gold == 17 and g.upgrades.bowQuick
        and g.damageBonus == 2 and g.player.weapon.name == "bow", "descent lost run inventory/build/health")
    check(not g.rooms[g.rooms.secretId].lootTaken and not g:mapVisible(g.rooms[g.rooms.secretId]),
        "descent retained completed challenge/discovery")
    g.upgrades.bowPierce, g.upgrades.bowQuick, g.upgrades.guardPulse = true, true, true
    local Progression = require("src.progression")
    local choices = Progression.offer(g)
    check(#choices == 3 and choices[1] ~= choices[2] and choices[1] ~= choices[3] and choices[2] ~= choices[3],
        "later floors lost three distinct usable choices")
    local toolChoice
    for i, choice in ipairs(choices) do if choice.id == "pickaxes" then toolChoice = i end end
    local tools = g.pickaxes
    check(toolChoice and g:chooseReward(toolChoice) and g.pickaxes == tools + 3, "tool reward did not replenish three pickaxes")
    local practice = Game.new(42042, true); practice.state = "won"
    check(not practice:nextFloor() and practice.floorNumber == 1, "practice descended into an expedition")

    -- Sealed door: the violet gate blocks traversal until paid or forced; both
    -- door records open together and the passage then works like any other.
    local function findSeal(game)
        local leaf = game.rooms[game.rooms.sealedId]
        for _, room in ipairs(game.rooms) do
            for _, door in ipairs(room.doors) do
                if door.sealed and door.to == leaf.id then return room, door end
            end
        end
    end
    local function sealDialogue(game)
        while game.dialogue and game.dialogue.mode == "lines" do
            game.dialogue.reveal = math.huge; game:advanceDialogue()
        end
        return game.dialogue and game.dialogue.mode == "options"
    end
    g = Game.new(7, false)
    local host, door = findSeal(g)
    check(host and door, "sealed entry missing on floor 1")
    g:enter(host.id); g.room.cleared, g.room.inscriptions = true, {}
    check(not g:canLeave(door), "sealed portal allowed traversal")
    g.player.grid.x, g.player.grid.y = Rooms.arrival(g.room, door.side)
    g.gold = 5
    check(g:interact() and g.dialogue, "sealed portal ignored E")
    check(sealDialogue(g), "seal never offered choices")
    check(g:chooseDialogue(1) and g.gold == 2 and door.unsealed, "gold did not open the seal")
    local twin
    for _, candidate in ipairs(g.rooms[g.rooms.sealedId].doors) do
        if candidate.to == host.id and candidate.side == door.arrival then twin = candidate end
    end
    check(twin and twin.unsealed, "seal opened only one side")
    check(g:canLeave(door), "unsealed door stayed locked")
    g.player.grid.x, g.player.grid.y, g.player.motion.remaining = door.x, door.y, 0
    frame(g)
    check(g.roomId == g.rooms.sealedId, "open seal did not lead anywhere")

    g = Game.new(7, false)
    host, door = findSeal(g)
    g:enter(host.id); g.room.cleared, g.room.inscriptions = true, {}
    g.gold, g.pickaxes = 0, 20
    g.player.grid.x, g.player.grid.y = Rooms.arrival(g.room, door.side)
    g:interact()
    check(sealDialogue(g), "forced seal skipped the choices")
    check(g:chooseDialogue(1) and g.pickaxes == 19 and door.unsealed, "pickaxe did not force the seal")

    g = Game.new(7, false)
    host, door = findSeal(g)
    g:enter(host.id); g.room.cleared, g.room.inscriptions = true, {}
    g.gold, g.pickaxes = 0, 0
    g.player.grid.x, g.player.grid.y = Rooms.arrival(g.room, door.side)
    g:interact()
    check(sealDialogue(g) and #g.dialogue.node.options == 1, "empty-handed seal still offered a payment")
    check(g:chooseDialogue(1) and not g.dialogue and not door.unsealed, "SAIR broke the seal")
    print(string.format("%d FLOOR ASSERTIONS PASSED", checks))
    return checks
end

return T
