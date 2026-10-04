local Rooms = require('src.rooms')
local Environment = require('src.environment')
local Pal = require('src.palettes')
local World = {}
local G = love.graphics
local P = {
    ink = {.027, .043, .067}, abyss = {.016, .024, .043},
    floorDark = {.075, .114, .149}, floor = {.090, .133, .169}, floorLight = {.106, .149, .184},
    joint = {.059, .090, .122}, stoneDark = {.090, .133, .176}, stone = {.169, .235, .286},
    stoneLight = {.282, .361, .396}, stoneEdge = {.365, .455, .475},
    jadeDark = {.055, .235, .220}, jade = {.235, .635, .529}, jadeLight = {.529, .886, .702},
    goldDark = {.314, .235, .129}, gold = {.643, .490, .251}, goldLight = {.847, .702, .392},
    white = {.898, .941, .847}, danger = {.941, .388, .302}, rust = {.435, .204, .153},
    violet = {.482, .318, .702}, violetDark = {.278, .192, .412}, violetLight = {.690, .529, .878},
    -- Tons de modelagem: sombras frias (hue-shift) e luzes quentes por material.
    jadeDeep = {.039, .141, .157}, jadeMid = {.133, .412, .376},
    violetDeep = {.169, .118, .286}, violetMid = {.376, .255, .545},
    goldDeep = {.192, .141, .067}, ember = {.976, .573, .216}, emberLight = {1, .816, .494},
    stoneDeep = {.055, .082, .114}, bone = {.812, .749, .592}, boneDark = {.557, .478, .345},
}
World.palette = P
local function round(n) return math.floor(n + .5) end
local function rect(x, y, w, h, c, alpha)
    G.setColor(c[1], c[2], c[3], alpha or 1)
    G.rectangle('fill', round(x), round(y), round(w), round(h))
end
-- Bresenham keeps diagonals on exactly the same grid as filled faces.
local function line(x, y, tx, ty, c, alpha)
    if not c then local r,g,b,a=G.getColor(); c,alpha={r,g,b},a end
    x, y, tx, ty = round(x), round(y), round(tx), round(ty)
    local dx, dy = math.abs(tx - x), -math.abs(ty - y)
    local sx, sy = x < tx and 1 or -1, y < ty and 1 or -1
    local err = dx + dy
    while true do
        rect(x, y, 1, 1, c, alpha)
        if x == tx and y == ty then break end
        local twice = err * 2
        if twice >= dy then err = err + dy; x = x + sx end
        if twice <= dx then err = err + dx; y = y + sy end
    end
end
World.pixelLine = line

function World.secretHint(time, reducedMotion)
    local phase = time % 4
    if phase >= .3 then return 0 end
    return (reducedMotion and .08 or .12) * math.sin(phase / .3 * math.pi)^2
end

local function outline(x, y, w, h, c, alpha)
    rect(x, y, w, 1, c, alpha); rect(x, y + h - 1, w, 1, c, alpha)
    rect(x, y + 1, 1, h - 2, c, alpha); rect(x + w - 1, y + 1, 1, h - 2, c, alpha)
end
local function rune(x, y, c, alpha)
    line(x, y - 3, x + 3, y, c, alpha); line(x + 3, y, x, y + 3, c, alpha)
    line(x, y + 3, x - 3, y, c, alpha); line(x - 3, y, x, y - 3, c, alpha)
    rect(x, y - 1, 1, 3, c, alpha)
end
local function arrow(x, y, dx, dy, c)
    line(x - dx * 4, y - dy * 4, x + dx * 4, y + dy * 4, c)
    line(x + dx * 4, y + dy * 4, x + dy * 3, y - dx * 3, c)
    line(x + dx * 4, y + dy * 4, x - dy * 3, y + dx * 3, c)
end
local function variant(seed, id, x, y)
    return ((seed or 0) % 997 + (id or 0) * 17 + x * 37 + y * 101) % 97
end
local function hole(room, tile, px, py)
    rect(px, py, 32, 32, P.abyss)
    local function exposed(x, y)
        local n = Rooms.cell(room, x, y)
        return not n or n.ground ~= 'hole'
    end
    if exposed(tile.x, tile.y - 1) then
        rect(px, py, 32, 3, P.stone); rect(px + 2, py + 3, 28, 5, P.stoneDark)
        rect(px + 3, py + 1, 8, 1, P.stoneEdge); rect(px + 18, py + 1, 11, 1, P.stoneEdge)
        rect(px + 11, py + 2, 5, 4, P.floorDark); rect(px + 16, py + 3, 3, 2, P.abyss)
        rect(px + 4, py + 8, 7, 2, P.ink); rect(px + 21, py + 6, 5, 3, P.ink)
    end
    if exposed(tile.x, tile.y + 1) then
        rect(px, py + 29, 32, 3, P.stone); rect(px + 3, py + 29, 9, 1, P.stoneEdge)
        rect(px + 20, py + 28, 7, 2, P.stoneLight); rect(px + 12, py + 29, 4, 2, P.abyss)
    end
    if exposed(tile.x - 1, tile.y) then
        rect(px, py + 3, 3, 26, P.stoneLight); rect(px + 3, py + 7, 3, 20, P.stoneDark)
        rect(px + 1, py + 4, 1, 10, P.stoneEdge); rect(px + 2, py + 18, 3, 4, P.abyss)
    end
    if exposed(tile.x + 1, tile.y) then
        rect(px + 29, py + 3, 3, 26, P.stone); rect(px + 27, py + 6, 2, 20, P.ink)
        rect(px + 29, py + 12, 2, 5, P.abyss)
    end
end
local function portal(renderer, game, door)
    local x, y = (door.x - 1) * 32, (door.y - 1) * 32
    local open = game:canLeave(door)
    if door.localPath then
        local pal = Pal.regions[game.room.id] or Pal.regions.default
        rect(x + 1, y + 24, 30, 7, pal.wall.face)
        rect(x + 1, y + 24, 30, 2, pal.wall.rim)
        if not open then
            rect(x + 3, y + 2, 3, 23, pal.wood.dark)
            rect(x + 25, y + 2, 3, 23, pal.wood.dark)
            rect(x + 3, y + 11, 25, 4, pal.wood.base)
        end
        return
    end
    local sealed = door.sealed and not door.unsealed
    local c = open and (door.finish and P.goldLight or P.jade) or sealed and P.violet or P.rust
    rect(x + 1, y + 2, 30, 30, P.ink)
    rect(x + 2, y - 7, 6, 34, P.stoneDark); rect(x + 24, y - 7, 6, 34, P.stoneDark)
    rect(x + 1, y - 10, 30, 6, P.stone)
    rect(x + 1, y - 10, 30, 1, P.stoneEdge); rect(x + 2, y - 8, 28, 1, P.goldDark)
    rect(x + 2, y - 4, 2, 29, P.stoneLight); rect(x + 24, y - 4, 2, 29, P.stoneLight)
    rect(x, y + 25, 9, 5, P.stone); rect(x + 23, y + 25, 9, 5, P.stone)
    rect(x + 1, y + 25, 7, 1, P.stoneEdge); rect(x + 24, y + 25, 7, 1, P.stoneEdge)
    rune(x + 16, y - 7, open and P.gold or sealed and P.violetLight or P.rust)
    rect(x + 9, y + 27, 14, 3, P.stone); rect(x + 10, y + 27, 12, 1, c)
    if open then
        local alpha = renderer.reducedMotion and .18 or (math.floor(renderer.time / .8) % 2 == 0 and .17 or .23)
        rect(x + 9, y - 3, 14, 29, c, alpha)
        rect(x + 9, y, 1, 23, c, .5); rect(x + 22, y, 1, 23, c, .3)
        local dx = door.side == 'east' and 1 or door.side == 'west' and -1 or 0
        local dy = door.side == 'south' and 1 or door.side == 'north' and -1 or 0
        arrow(x + 16, y + 17, dx, dy, door.finish and P.goldLight or P.jadeLight)
        rect(x + 5, y + 3, 1, 3, P.gold); rect(x + 27, y + 3, 1, 3, P.gold)
    else
        for offset = 0, 2 do rect(x + 11 + offset * 4, y - 2, 2, 26, sealed and P.violetDark or P.goldDark) end
        if sealed then
            rune(x + 16, y + 13, P.violetLight, .9)
            rect(x + 10, y + 2, 12, 1, P.violet, .6); rect(x + 10, y + 24, 12, 1, P.violet, .6)
        else
            rect(x + 9, y + 7, 14, 2, P.rust); rect(x + 9, y + 19, 14, 2, P.rust)
            rect(x + 14, y + 9, 5, 6, P.ink); rect(x + 15, y + 10, 3, 3, P.danger)
        end
    end
end

World.portal = portal
function World.floor(renderer, game)
    local room = game.room
    rect(-64, -64, room.w * 32 + 128, room.h * 32 + 128, P.ink)
    for y = 1, room.h do for x = 1, room.w do
        local tile = Rooms.cell(room, x, y)
        if tile then
            local px, py = (x - 1) * 32, (y - 1) * 32
            if tile.ground == 'hole' then hole(room, tile, px, py)
            else
                local landing = renderer.feedback and renderer.feedback.landings and renderer.feedback.landings[Rooms.key(x, y)]
                if landing and not renderer.reducedMotion then py = py + round(landing.depth * .8) end
                local n = variant(game.seed, room.uid or room.id, x, y)
                rect(px, py, 32, 32, P.joint)
                rect(px + 1, py + 1, 30, 30, n < 18 and P.floorDark or n > 80 and P.floorLight or P.floor)
                rect(px + 2, py + 1, 27, 1, P.stone, .25)
                rect(px + 1, py + 2, 1, 27, P.stone, .16)
                rect(px + 2, py + 30, 29, 1, P.ink, .3)
                -- Wear is deliberately sparse; every variation is stable on revisits.
                if n == 0 or n == 11 or tile.state == 'broken' or tile.state == 'fallen' then
                    line(px + 19, py + 1, px + 16, py + 6, P.joint)
                    line(px + 16, py + 6, px + 20, py + 11, P.joint)
                    rect(px + 14, py + 8, 2, 1, P.stone, .45)
                elseif n == 24 then
                    rect(px + 23, py + 25, 3, 1, P.stone, .3); rect(px + 26, py + 23, 1, 1, P.stone, .3)
                end
                if tile.state == 'broken' or tile.state == 'fallen' then
                    rect(px + 6, py + 20, 4, 2, P.stoneDark); rect(px + 21, py + 23, 5, 3, P.stoneDark)
                    rect(px + 7, py + 20, 2, 1, P.stone); rect(px + 22, py + 23, 3, 1, P.stone)
                end
                if tile.passage and not tile.piece then
                    line(px + 4, py + 8, px + 4, py + 4, P.jadeDark, .45)
                    line(px + 4, py + 4, px + 8, py + 4, P.jadeDark, .45)
                end
            end
        end
    end end
    if room.spawn then
        local sx, sy = (room.spawn.x - .5) * 32, (room.spawn.y - .5) * 32
        local c = room.refuge and P.jadeDark or P.goldDark
        outline(sx - 10, sy - 7, 21, 15, c, .42); rune(sx, sy, c, .7)
        rect(sx - 13, sy, 3, 1, c, .5); rect(sx + 11, sy, 3, 1, c, .5)
    end
    for _, door in ipairs(room.doors or {}) do
        if not door.hidden or door.revealed then portal(renderer, game, door) end
    end
end

local function damage(tile, px, py)
    local hits = tile.hits or 0
    if hits == 0 then return end
    local segments = {{18, -7, 14, 1}, {14, 1, 19, 6}, {19, 6, 15, 17}}
    if hits >= 2 then
        segments[#segments + 1] = {14, 1, 7, 5}; segments[#segments + 1] = {19, 6, 25, 12}
    end
    for _, s in ipairs(segments) do
        line(px + s[1] + 1, py + s[2], px + s[3] + 1, py + s[4], P.stoneLight)
        line(px + s[1], py + s[2], px + s[3], py + s[4], P.ink)
    end
    rect(px + 10, py + 24, 13, 5, P.ink)
    for i = 1, 3 do rect(px + 11 + (i - 1) * 4, py + 25, 3, 3, i <= hits and P.goldLight or P.stoneDark) end
end

function World.wall(renderer, room, tile, pal)
    local x, y, piece = tile.x, tile.y, tile.piece
    local px, py = (x - 1) * 32, (y - 1) * 32
    if piece == 'pillar' then
        -- Pilares seguem a família de pedra da região quando informada.
        local st = pal and pal.wall or nil
        local sDark = st and st.faceDark or P.stoneDark
        local sMid = st and st.brick or P.stone
        local sLight = st and st.cap or P.stoneLight
        local sEdge = st and st.rim or P.stoneEdge
        local lean = tile.state == 'falling' and not renderer.reducedMotion and round((1 - tile.timer / tile.duration) * 5) or 0
        local cx, cy = px + 16 + (tile.dx or 0) * lean, py + (tile.dy or 0) * lean
        rect(px + 4, py + 24, 26, 8, P.ink, .8)
        rect(px + 4, py + 23, 24, 6, sDark); rect(px + 5, py + 21, 22, 4, sMid)
        rect(px + 5, py + 21, 21, 1, sLight); rect(px + 7, py + 20, 18, 1, P.goldDark)
        rect(cx - 8, cy - 23, 16, 45, P.ink)
        rect(cx - 7, cy - 22, 14, 43, sMid); rect(cx - 6, cy - 21, 3, 41, sLight)
        rect(cx + 4, cy - 21, 3, 42, sDark); rect(cx - 1, cy - 18, 2, 37, sDark)
        rect(cx - 9, cy - 24, 18, 5, sDark); rect(cx - 10, cy - 28, 20, 5, sMid)
        rect(cx - 8, cy - 30, 16, 2, sLight); rect(cx - 8, cy - 29, 14, 1, sEdge)
        rect(cx - 8, cy - 25, 16, 1, P.gold); rect(cx - 8, cy - 24, 2, 2, P.goldLight)
        rect(cx - 8, cy + 13, 16, 3, P.goldDark); rect(cx - 7, cy + 13, 12, 1, P.gold)
        rune(cx, cy - 7, P.gold, .75); rect(cx, cy - 7, 1, 1, P.jade, .8)
        damage(tile, cx - 16, cy)
    else
        local fallen = piece == 'fallen'
        local hidden = tile.secretDoor and tile.secretDoor.hidden and not tile.secretDoor.revealed
        local structural = tile.protected or hidden
        local function joins(nx, ny)
            local n = Rooms.cell(room, nx, ny)
            return n and n.piece == piece and (not fallen or (n.dx == tile.dx and n.dy == tile.dy))
        end
        local north, south, west, east = joins(x, y - 1), joins(x, y + 1), joins(x - 1, y), joins(x + 1, y)
        local left, right = px + (west and 0 or 1), px + 32 - (east and 0 or 1)
        local top, face = py - (fallen and 2 or 11), py + (fallen and 21 or 15)
        rect(left + 2, py + 27, right - left, 6, P.ink, .8)
        rect(left, face, right - left, 31 - (face - py), P.stoneDark)
        rect(left, top, right - left, face - top, structural and P.stone or P.stoneLight)
        if not north then rect(left, top, right - left, 2, P.stoneEdge) end
        if not west then rect(left, top + 2, 1, face - top - 2, P.stoneLight) end
        if not east then rect(right - 1, top + 2, 1, face - top - 2, P.ink, .8) end
        rect(left, face - 2, right - left, 2, P.stone)
        rect(left + 1, face, right - left - 2, 1, P.stoneLight)
        if not south then rect(left, py + 30, right - left, 1, P.ink) end
        if fallen then
            local horizontal = (tile.dx or 0) ~= 0
            if horizontal then
                rect(left, py + 8, right - left, 3, P.goldDark); rect(left, py + 8, right - left, 1, P.gold)
                rect(left + 2, py + 1, right - left - 4, 1, P.stoneEdge)
            else
                rect(px + 14, top + 2, 3, face - top - 3, P.goldDark)
                rect(px + 14, top + 2, 1, face - top - 3, P.gold)
            end
            line(px + 7, py + 2, px + 4, py + 7, P.ink); line(px + 25, py + 14, px + 28, py + 18, P.ink)
        elseif structural then
            rect(left + 1, face + 6, right - left - 2, 1, P.ink, .5)
            rect(px + 15, face + 1, 1, 5, P.ink, .5)
            if (x + y) % 3 == 0 then rune(px + 16, py + 2, P.stoneLight, .8) end
            if not north then rect(left + 3, top + 3, right - left - 6, 1, P.goldDark, .7) end
        else
            rect(left + 1, face + 5, right - left - 2, 1, P.ink, .4)
            rect(px + 5, py - 6, 2, 2, P.goldDark); rect(px + 25, py - 6, 2, 2, P.goldDark)
            rect(px + 6, py - 6, 1, 1, P.gold); rect(px + 25, py - 6, 1, 1, P.gold)
            line(px + 10, py + 1, px + 15, py + 4, P.stone, .7)
        end
        if hidden then
            local phase = renderer.time % 4
            if phase < .3 then
                local alpha = World.secretHint(renderer.time, renderer.reducedMotion)
                rect(px + 10, py - 5, 11, 1, P.white, alpha); rect(px + 15, py - 8, 1, 7, P.white, alpha)
            end
        end
        damage(tile, px, py)
    end
end

function World.object(renderer, entity, game, x, y)
    if not entity.resonator and not entity.target then return false end
    x, y = round(x), round(y)
    rect(x - 10, y - 1, 22, 5, P.ink, .8); rect(x - 7, y - 3, 15, 7, P.ink, .8)
    if entity.target then
        rect(x - 2, y - 22, 4, 21, P.goldDark); rect(x - 1, y - 20, 1, 17, P.gold)
        line(x, y - 4, x - 9, y, P.goldDark); line(x, y - 4, x + 9, y, P.goldDark)
        rect(x - 8, y - 28, 16, 19, P.gold); rect(x - 10, y - 25, 20, 13, P.gold)
        rect(x - 7, y - 27, 14, 17, P.white); rect(x - 9, y - 24, 18, 11, P.white)
        rect(x - 5, y - 25, 10, 13, P.rust); rect(x - 7, y - 22, 14, 7, P.rust)
        rect(x - 3, y - 23, 6, 9, P.white); rect(x - 5, y - 20, 10, 3, P.white)
        rect(x - 1, y - 21, 2, 5, P.danger); rect(x - 2, y - 20, 4, 3, P.danger)
        rect(x - 7, y - 27, 6, 1, P.goldLight)
        return true
    end
    local primed = entity.resonator.state == 'primed'
    local lift = not renderer.reducedMotion and math.floor(renderer.time / .8) % 2 or 0
    local top = y - 30 - lift
    rect(x - 11, y - 3, 22, 5, P.stoneDark); rect(x - 8, y - 6, 16, 4, P.stone)
    rect(x - 9, y - 5, 18, 1, P.stoneLight); rect(x - 8, y, 16, 1, P.goldDark)
    -- Facets are horizontal scanlines, including their short gold socket.
    for row = 0, 24 do
        local width = row < 13 and math.max(1, math.floor(row * .6)) or math.max(3, 8 - math.floor((row - 13) * .4))
        rect(x - width, top + row, width, 1, primed and P.gold or P.jade)
        rect(x, top + row, width + 1, 1, primed and P.rust or P.jadeDark)
    end
    line(x, top, x + 7, top + 12, primed and P.goldLight or P.jadeLight)
    line(x - 1, top + 2, x - 5, top + 12, primed and P.white or P.jadeLight)
    line(x - 5, top + 12, x - 2, top + 23, primed and P.goldLight or P.jade)
    rect(x - 2, top + 12, 4, 2, primed and P.white or P.jadeLight)
    rect(x - 6, y - 6, 12, 2, P.goldDark); rect(x - 5, y - 6, 10, 1, P.gold)
    if primed then
        local progress = math.max(0, math.min(1, 1 - entity.resonator.timer / Environment.constants.warning))
        rect(x - 8, top - 8, 17, 3, P.ink); rect(x - 7, top - 7, math.floor(15 * progress), 1, P.goldLight)
        rect(x - 1, top - 15, 2, 4, P.white); rect(x - 1, top - 10, 2, 1, P.white)
    end
    return true
end

function World.selfCheck()
    assert(variant(932, 1, 7, 4) == variant(932, 1, 7, 4), 'Floor wear is stable')
    assert(variant(932, 1, 7, 4) ~= variant(933, 1, 7, 4), 'Seed changes floor wear')
    local draw, count = G.rectangle, 0
    G.rectangle = function(mode, x, y, w, h)
        assert(mode == 'fill' and x % 1 == 0 and y % 1 == 0 and w % 1 == 0 and h % 1 == 0,
            'World art consists only of integer pixels')
        count = count + 1
    end
    local pillar = {x = 2, y = 2, piece = 'pillar', state = 'falling', hits = 2,
        timer = .31, duration = .62, dx = 1, dy = 0, cells = {{x = 3, y = 2}}}
    local hidden = {hidden = true, revealed = false}
    local room = {id = 1, w = 3, h = 3, tiles = {},
        doors = {{x = 3, y = 2, side = 'east'}, {x = 1, y = 3, side = 'south', hidden = true}},
        spawn = {x = 1, y = 1}}
    for y = 1, 3 do for x = 1, 3 do room.tiles[Rooms.key(x, y)] = {x = x, y = y, ground = 'floor'} end end
    local brick = room.tiles['3:3']; brick.piece, brick.secretDoor = 'wall', hidden
    room.tiles['2:2'] = pillar; room.tiles['3:1'].ground = 'hole'
    local crystal = {resonator = {state = 'primed', timer = .31, cells = {{x = 2, y = 1}}}}
    local ok, err = pcall(function()
        for _, reduced in ipairs({false, true}) do
            local renderer = {time = .15, reducedMotion = reduced, feedback = {landings = {['1:2'] = {depth = 2.3}}}}
            local game = {room = room, seed = 932, canLeave = function() return reduced end}
            World.floor(renderer, game); World.wall(renderer, room, pillar); World.wall(renderer, room, brick)
            World.wall(renderer, room, {x = 1, y = 3, piece = 'fallen', dx = 1, dy = 0})
            assert(World.object(renderer, crystal, game, 48.3, 47.7))
            assert(World.object(renderer, {target = {}}, game, 48, 48))
            assert(not World.object(renderer, {player = {}}, game, 48, 48))
        end
    end)
    G.rectangle = draw
    assert(ok, err)
    assert(count > 0 and pillar.timer == .31 and #pillar.cells == 1 and brick.piece == 'wall')
    assert(hidden.hidden and not hidden.revealed and crystal.resonator.timer == .31 and #crystal.resonator.cells == 1,
        'World rendering never changes simulation or discoveries')
    return true
end

return World
