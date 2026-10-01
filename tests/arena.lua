local Rooms = require("src.rooms")
local Arena = {}

-- Rule fixtures own their size; generated compact rooms remain untouched in replays.
function Arena.reset(game)
    for _, entity in ipairs(game:entities()) do if not entity.player then entity:destroy() end end
    local room = game.room
    room.w, room.h, room.tiles, room.doors, room.enemies, room.crystals = 19, 15, {}, {}, {}, {}
    room.spawn, room.cleared = {x = 4, y = 8}, true
    for y = 1, room.h do for x = 1, room.w do
        local boundary = x == 1 or y == 1 or x == room.w or y == room.h
        room.tiles[Rooms.key(x, y)] = {x = x, y = y, ground = "floor", hits = 0,
            piece = boundary and "wall" or nil, protected = boundary}
    end end
    local p, m, w = game.player.grid, game.player.motion, game.player.weapon
    p.x, p.y, m.remaining, m.falling, m.bufferTime, m.blocked = 4, 8, 0, false, 0, {}
    w.state, w.charge, w.action, w.mineTimer, w.triggerHeld = "empty", 0, 0, 0, false
    game.reward, game.player.guard.active = false, false
    game.world:emit("flush")
    return game
end

return Arena
