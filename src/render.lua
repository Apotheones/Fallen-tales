local Camera = require('vendor.camera')
local Feedback = require('src.feedback')
local Rooms = require('src.rooms')
local Environment = require('src.environment')
local Render = {}; Render.__index = Render
local G = love.graphics
local pi = math.pi
local C = {
    ink = {.033, .046, .071}, panel = {.055, .075, .106}, line = {.19, .26, .31},
    text = {.90, .92, .89}, muted = {.51, .62, .66}, jade = {.34, .91, .81},
    gold = {.98, .76, .37}, red = {1, .36, .35}, violet = {.73, .66, 1}, white = {1, 1, 1}
}
local function color(c, alpha) G.setColor(c[1], c[2], c[3], alpha or c[4] or 1) end
local function text(font, value, x, y, c, limit, align)
    G.setFont(font); color(c or C.text)
    if limit then G.printf(value, x, y, limit, align or 'left') else G.print(value, x, y) end
end
local function panel(x, y, w, h, accent)
    color(C.ink, .93); G.rectangle('fill', x, y + 4, w, h, 7)
    color(C.panel, .96); G.rectangle('fill', x, y, w, h, 7)
    color(accent or C.line, .7); G.setLineWidth(1); G.rectangle('line', x + .5, y + .5, w - 1, h - 1, 7)
    color(accent or C.line, .25); G.line(x + 12, y + 1, x + w - 12, y + 1)
end
local function diamond(x, y, r, c, mode)
    color(c); G.polygon(mode or 'fill', x, y - r, x + r, y, x, y + r, x - r, y)
end
local function arrow(x, y, dx, dy, c, size)
    G.push(); G.translate(x, y); G.rotate(math.atan2(dy, dx)); color(c)
    G.setLineWidth(2); G.line(-size, -size, 0, 0, -size, size); G.pop()
end

-- This interpolation is a view over committed grid positions; it never changes collision.
function Render.visualPosition(entity)
    local p, m = entity.grid, entity.motion
    if m and m.remaining > 0 then
        local t = 1 - m.remaining / m.duration
        local ease = t * t * (3 - 2 * t)
        return ((m.fromX + (p.x - m.fromX) * ease) - .5) * 40,
            ((m.fromY + (p.y - m.fromY) * ease) - .5) * 40, math.sin(t * pi) * 9 - (m.falling and t^3 * 28 or 0)
    end
    return (p.x - .5) * 40, (p.y - .5) * 40, 0
end

function Render.secretHint(time, reducedMotion)
    local phase = time % 4
    if phase >= .30 then return 0 end
    return (reducedMotion and .08 or .12) * math.sin(phase / .30 * pi)^2
end

function Render.selfCheck()
    local e = {grid = {x = 4, y = 3}, motion = {fromX = 3, fromY = 3, duration = .16, remaining = .08}}
    local x, y, jump = Render.visualPosition(e)
    assert(x == 120 and y == 100 and math.abs(jump - 9) < .0001, 'Hop interpolation is purely visual')
    assert(e.grid.x == 4 and e.grid.y == 3, 'Rendering must not move the logical grid position')
    e.motion.remaining = 0
    x, y, jump = Render.visualPosition(e)
    assert(x == 140 and y == 100 and jump == 0, 'Landing returns exactly to the committed grid center')
    local pillar = {x = 5, y = 4, piece = 'pillar', ground = 'floor', hits = 3, state = 'falling', timer = .31, duration = .62,
        dx = 1, dy = 0, cells = {{x = 6, y = 4}, {x = 7, y = 4}}}
    local crystal = {resonator = {state = 'primed', cells = {{x = 3, y = 4}}, walls = {{x = 4, y = 4}}}}
    local game = {room = {w = 9, h = 7, tiles = {
        ['4:4'] = {x = 4, y = 4, ground = 'floor', piece = 'wall', hits = 2}, ['5:4'] = pillar,
        ['8:4'] = {x = 8, y = 4, ground = 'floor', piece = 'fallen', hits = 0, dx = 1, dy = 0}}},
        player = {grid = {x = 3, y = 4}, facing = {dx = 1, dy = 0}}, entities = function() return {crystal} end}
    for cy = 1, game.room.h do for cx = 1, game.room.w do
        local key = Rooms.key(cx, cy)
        game.room.tiles[key] = game.room.tiles[key] or {x = cx, y = cy, ground = 'floor', hits = 0}
    end end
    local view = setmetatable({time = 0, fonts = {tiny = G.newFont(11)}}, Render)
    local draws, drawWall = {}, view.wall
    view.wall = function(self, room, tile)
        draws[Rooms.key(tile.x, tile.y)] = true
        drawWall(self, room, tile)
    end
    G.push('all')
    for _, reduced in ipairs({false, true}) do
        view.reducedMotion = reduced; view:walls(game); view:terrainWarnings(game)
    end
    G.pop()
    assert(draws['4:4'] and draws['5:4'] and draws['8:4'], 'Every map piece is drawn, including pieces behind another wall')
    assert(pillar.timer == .31 and #pillar.cells == 2 and pillar.cells[2].x == 7, 'Drawing must preserve frozen fall preview and timer')
    assert(#crystal.resonator.cells == 1 and #crystal.resonator.walls == 1 and game.room.tiles['4:4'].piece == 'wall', 'Drawing must preserve blast preview and walls')
    assert(math.abs(Render.secretHint(.15) - .12) < .0001 and math.abs(Render.secretHint(4.15) - .12) < .0001,
        'Hidden brick hint repeats every four seconds')
    assert(Render.secretHint(.31) == 0 and Render.secretHint(3.99) == 0 and Render.secretHint(.15, true) < .12,
        'Hidden brick hint is brief and remains subtle with reduced motion')
    local hidden = {hidden = true, revealed = false}
    game.room.tiles['4:4'].secretDoor = hidden
    G.push('all')
    view.time = .15; view:wall(game.room, game.room.tiles['4:4'])
    view:actor({grid = {x = 3, y = 3}, target = {data = {hit = false}}}, game)
    G.pop()
    assert(hidden.hidden and not hidden.revealed, 'Drawing a hidden brick never reveals its entrance')
    local map = {roomId = 1, mapVisible = require('src.game').mapVisible, rooms = {
        {id = 1, kind = 'start', mapX = -2, mapY = 1, visited = true, doors = {{to = 2}}},
        {id = 2, kind = 'treasure', mapX = -1, mapY = 1, discovered = true, doors = {{to = 1}, {to = 3, hidden = true}}},
        {id = 3, kind = 'secret', mapX = -1, mapY = 2, doors = {{to = 2, hidden = true}}},
        {id = 4, kind = 'boss', mapX = 0, mapY = 1, discovered = true, doors = {{to = 2}}}}}
    G.push('all')
    view:minimap(map, 0, 0, 134, 91)
    G.pop()
    assert(map.rooms[1].mapX == -2 and not map.rooms[3].discovered and not map.rooms[4].visited,
        'Drawing the dynamic map never discovers secrets or the boss')
    assert(Feedback.selfCheck())
    return true
end

function Render.new()
    local self = setmetatable({camera = Camera(0, 0, 1), feedback = Feedback.new(), time = 0,
        fonts = {}, muted = false, reducedMotion = false}, Render)
    for name, size in pairs({tiny = 11, small = 13, body = 16, medium = 21, large = 30, title = 66}) do
        self.fonts[name] = G.newFont(size)
        self.fonts[name]:setFilter('linear', 'linear')
    end
    return self
end

function Render:update(dt, game)
    self.time = self.time + dt
    self.feedback.muted, self.feedback.reducedMotion = self.muted, self.reducedMotion
    self.feedback:update(dt, game)
    local uiScale = math.min(G.getWidth() / 1120, G.getHeight() / 720)
    local top, bottom = 224 * uiScale, 116 * uiScale
    local room = game.room
    local zoom = math.min(1.25, (G.getWidth() - 64 * uiScale) / (room.w * 40 + 20),
        (G.getHeight() - top - bottom) / (room.h * 40 + 40))
    self.camera:lookAt(room.w * 20, room.h * 20 - 8 - (top - bottom) / (2 * zoom))
    self.camera:zoomTo(zoom)
end

function Render:weapon(name, x, y, size, tint)
    G.push(); G.translate(x, y); G.scale(size or 1)
    local c = tint or C.gold
    color(c); G.setLineWidth(2)
    if name == 'pickaxe' then
        color(C.muted); G.setLineWidth(3); G.line(-12, 8, 10, -7)
        color(C.gold); G.setLineWidth(4); G.line(3, -13, 12, -7, 15, 3)
        color(C.white, .65); G.setLineWidth(1); G.line(3, -14, 12, -8, 16, 3)
    else
        G.arc('line', 'open', -4, 0, 15, -1.13, 1.13, 20)
        color(C.text, .75); G.line(2, -13.5, 2, 13.5)
        color(c); G.line(-12, 0, 17, 0); G.polygon('fill', 18, 0, 12, -3, 12, 3)
        G.line(-9, -3, -6, 0, -9, 3)
    end
    G.pop()
end

function Render:floor(game)
    local room, t = game.room, self.time
    local mood = room.refuge and {-.01, .025, .008} or room.final and {.035, -.005, .028} or room.id == 3 and {.025, .003, -.013} or {0, 0, 0}
    color({.027, .038, .054}); G.rectangle('fill', -90, -90, room.w * 40 + 180, room.h * 40 + 180)
    for y = 1, room.h do for x = 1, room.w do
        local px, py = (x - 1) * 40, (y - 1) * 40
        local tile = Rooms.cell(room, x, y)
        if tile and tile.ground == 'hole' then
            color({.009, .007, .019}); G.rectangle('fill', px, py, 40, 40)
            local function rim(nx, ny, x1, y1, x2, y2)
                local neighbor = Rooms.cell(room, nx, ny)
                if not neighbor or neighbor.ground ~= 'hole' then
                    color({.36, .43, .48}); G.setLineWidth(3); G.line(x1, y1, x2, y2)
                    color({.14, .15, .23}); G.setLineWidth(2); G.line(x1, y1 + 5, x2, y2 + 5)
                end
            end
            rim(x, y - 1, px + 1, py + 2, px + 39, py + 2)
            rim(x, y + 1, px + 1, py + 37, px + 39, py + 37)
            rim(x - 1, y, px + 2, py + 2, px + 2, py + 37)
            rim(x + 1, y, px + 37, py + 2, px + 37, py + 37)
            color({.23, .21, .34}, .3); G.setLineWidth(1)
            G.line(px + 10, py + 12, px + 17, py + 16); G.line(px + 28, py + 23, px + 32, py + 27)
        elseif tile then
            local sink = self.feedback.landings[x .. ':' .. y]
            py = py + (sink and sink.depth or 0)
            color({.038, .058, .077}); G.rectangle('fill', px + 1, py + 5, 38, 35, 2)
            local even = (x + y) % 2 == 0
            color(even and {.116 + mood[1], .165 + mood[2], .188 + mood[3]} or {.085 + mood[1], .126 + mood[2], .15 + mood[3]})
            G.rectangle('fill', px + 2, py + 2, 36, 33, 2)
            color(even and {.18, .24, .25} or {.145, .205, .23}, .85)
            G.line(px + 4, py + 3, px + 35, py + 3)
            color(C.ink, .7); G.line(px + 3, py + 34, px + 36, py + 34)
            color(C.muted, .15); G.points(px + 5, py + 6, px + 34, py + 6)
            if (x * 7 + y * 13) % 23 == 0 then
                color(C.muted, .13); G.line(px + 13, py + 18, px + 17, py + 14, px + 19, py + 19)
            end
            if tile.passage then
                color(C.jade, .20); G.setLineWidth(1)
                G.line(px + 5, py + 11, px + 5, py + 5, px + 11, py + 5)
                G.line(px + 29, py + 29, px + 35, py + 29, px + 35, py + 23)
            end
        end
    end end
    -- A quiet entrance sigil anchors the room without disguising the board cells.
    local sx, sy = (room.spawn.x - .5) * 40, (room.spawn.y - .5) * 40
    color(room.refuge and C.jade or C.gold, .15); G.setLineWidth(1)
    G.circle('line', sx, sy, 15); G.circle('line', sx, sy, 11)
    for i = 0, 3 do local a = i * pi / 2; G.line(sx + math.cos(a) * 9, sy + math.sin(a) * 9, sx + math.cos(a) * 17, sy + math.sin(a) * 17) end
    if room.refuge or room.final then
        local cx, cy = math.floor(room.w / 2) * 40 + 20, math.floor(room.h / 2) * 40 + 20
        color(room.refuge and C.jade or C.violet, .15); G.setLineWidth(1)
        G.circle('line', cx, cy, 59); G.circle('line', cx, cy, 65)
        for i = 0, 7 do
            local a = i * pi / 4
            diamond(cx + math.cos(a) * 62, cy + math.sin(a) * 62, 2, room.refuge and {.34, .91, .81, .18} or {.73, .66, 1, .18})
        end
    end
    for _, door in ipairs(room.doors) do if not door.hidden or door.revealed then
        local dx, dy = (door.x - .5) * 40, (door.y - .5) * 40
        local open = game:canLeave(door)
        local c = open and (door.finish and C.gold or C.jade) or C.red
        color(c, .12 + (open and math.sin(t * 3) * .035 or 0)); G.rectangle('fill', dx - 19, dy - 19, 38, 38)
        color(c, .75); G.setLineWidth(2); G.rectangle('line', dx - 16, dy - 16, 32, 32, 2)
        if open then
            local vx = door.side == 'east' and 1 or door.side == 'west' and -1 or 0
            local vy = door.side == 'south' and 1 or door.side == 'north' and -1 or 0
            arrow(dx + vx * 5, dy + vy * 5, vx, vy, c, 6)
        else
            color(c, .6); G.rectangle('fill', dx - 3, dy - 10, 6, 20)
            for i = -1, 1 do G.line(dx - 14, dy + i * 10, dx + 14, dy + i * 10) end
        end
    end end
end

function Render:wall(room, tile)
    local x, y, piece = tile.x, tile.y, tile.piece
    local px, py = (x - 1) * 40, (y - 1) * 40
    if piece == 'pillar' then
        local lean = tile.state == 'falling' and not self.reducedMotion and
            (1 - tile.timer / tile.duration) * 7 or 0
        local cx, cy = px + 20 + (tile.dx or 0) * lean, py + 4 + (tile.dy or 0) * lean
        color(C.ink, .8); G.ellipse('fill', px + 21, py + 32, 17, 8)
        color({.21, .25, .28}); G.rectangle('fill', px + 5, py + 25, 30, 12, 3)
        color({.28, .32, .34}); G.rectangle('fill', cx - 10, cy - 22, 20, 48, 2)
        color(C.muted, .5); G.rectangle('fill', cx - 8, cy - 20, 3, 43, 1)
        color({.35, .39, .40}); G.ellipse('fill', cx, cy - 22, 13, 5)
        color(C.gold, .85); G.setLineWidth(1.5); G.ellipse('line', cx, cy - 22, 11, 4)
        for side = -1, 1, 2 do
            color(C.gold, .55); G.line(cx + side * 9, cy - 5, px + 20 + side * 14, py + 30)
            for link = 0, 2 do G.circle('line', cx + side * (10 + link * 2), cy + 5 + link * 7, 2) end
        end
    else
        local fallen = piece == 'fallen'
        local hidden = tile.secretDoor and tile.secretDoor.hidden and not tile.secretDoor.revealed
        local structural = tile.protected or hidden
        local function joins(nx, ny)
            local neighbor = Rooms.cell(room, nx, ny)
            return neighbor and neighbor.piece == piece and
                (not fallen or (neighbor.dx == tile.dx and neighbor.dy == tile.dy))
        end
        local north, south, west, east = joins(x, y - 1), joins(x, y + 1), joins(x - 1, y), joins(x + 1, y)
        local left, right = px + (west and 0 or 2), px + 40 - (east and 0 or 2)
        local top, face = py - (fallen and 3 or 14), py + (fallen and 25 or 21)
        color(C.ink, .8); G.rectangle('fill', left + 3, py + 33, right - left, 9)
        color(fallen and {.16, .20, .23} or {.12, .16, .19})
        G.rectangle('fill', left, face, right - left, py + 39 - face)
        color(structural and {.20, .25, .29} or fallen and {.26, .31, .33} or {.24, .25, .24})
        G.rectangle('fill', left, top, right - left, face - top)
        G.setLineWidth(2); color(structural and C.muted or fallen and {.44, .49, .48} or {.40, .37, .29}, .75)
        if not north then G.line(left + 1, top + 1, right - 1, top + 1) end
        if not west then G.line(left + 1, top + 2, left + 1, face) end
        if not east then G.line(right - 1, top + 2, right - 1, face) end
        if not south then color(C.ink, .8); G.line(left, py + 38, right, py + 38) end
        color(C.ink, .22); G.setLineWidth(1)
        G.line(px + 9, py + 3, px + 18, py + 6, px + 16, py + 10)
        if structural then
            diamond(px + 20, py + 5, 3, C.muted, 'line')
        elseif fallen then
            color(C.gold, .4)
            if tile.dx ~= 0 then G.line(left + 2, py + 13, right - 2, py + 13)
            else G.line(px + 20, top + 2, px + 20, py + 23) end
        end
    end
    if tile.secretDoor and tile.secretDoor.hidden and not tile.secretDoor.revealed then
        color(C.white, Render.secretHint(self.time, self.reducedMotion)); G.setLineWidth(1)
        G.line(px + 13, py - 6, px + 26, py - 6)
        G.line(px + 20, py - 10, px + 20, py - 2)
    end
    local hits = tile.hits or 0
    if hits > 0 then
        G.setLineWidth(3); color(C.ink)
        G.line(px + 22, py - 8, px + 16, py + 2, px + 23, py + 8, px + 17, py + 22)
        G.setLineWidth(1); color(C.gold, .8)
        G.line(px + 22, py - 8, px + 16, py + 2, px + 23, py + 8, px + 17, py + 22)
        if hits >= 2 then
            G.setLineWidth(2); G.line(px + 16, py + 2, px + 7, py + 6)
            G.line(px + 23, py + 8, px + 32, py + 15)
        end
        color(C.ink, .94); G.rectangle('fill', px + 9, py + 24, 23, 14, 2)
        text(self.fonts.tiny, hits .. '/' .. Environment.constants.hits, px + 9, py + 25, C.gold, 23, 'center')
    end
end

function Render:walls(game)
    for y = 1, game.room.h do for x = 1, game.room.w do
        local tile = Rooms.cell(game.room, x, y)
        if tile and tile.piece and tile.piece ~= 'portal' then self:wall(game.room, tile) end
    end end
end
function Render:fallWarning(tile, cells, preview)
    local tint = preview and C.jade or C.gold
    for _, cell in ipairs(cells) do
        local x, y = (cell.x - 1) * 40, (cell.y - 1) * 40
        color(cell.hole and C.red or tint, preview and .08 or .18)
        G.rectangle('fill', x + 2, y + 2, 36, 36, 2)
        color(cell.hole and C.red or tint, preview and .5 or .95); G.setLineWidth(preview and 1 or 2)
        G.rectangle('line', x + 3, y + 3, 34, 34, 2)
        arrow(x + 20 + tile.dx * 3, y + 20 + tile.dy * 3, tile.dx, tile.dy, cell.hole and C.red or tint, 6)
        if not preview then
            color(C.white, .45); G.setLineWidth(1)
            G.line(x + 7, y + 30, x + 17, y + 20); G.line(x + 24, y + 17, x + 33, y + 8)
        end
    end
    local x, y = (tile.x - .5) * 40, (tile.y - .5) * 40
    color(C.ink, .9); G.rectangle('fill', x - 36, y - 48, 72, 19, 3)
    text(self.fonts.tiny, (preview and 'QUEDA: ' or 'ESMAGA: ') .. #cells, x - 36, y - 46, tint, 72, 'center')
    arrow(x + tile.dx * 15, y + tile.dy * 15, tile.dx, tile.dy, tint, 5)
    if not preview then
        local progress = math.max(0, math.min(1, 1 - tile.timer / tile.duration))
        color(C.gold); G.setLineWidth(2)
        G.arc('line', 'open', x, y, 22, -pi / 2, -pi / 2 + math.max(.01, progress) * pi * 2)
        G.rectangle('fill', x - 26, y - 31, 52 * progress, 2)
    end
end

function Render:terrainWarnings(game)
    -- Pending hazards use the simulation's frozen cells; only the idle adjacent preview is recomputed.
    for _, tile in pairs(game.room.tiles) do
        if tile.state == 'falling' then self:fallWarning(tile, tile.cells, false) end
    end
    local p, facing = game.player.grid, game.player.facing
    local tile = Rooms.cell(game.room, p.x + facing.dx, p.y + facing.dy)
    if tile and tile.piece == 'pillar' and tile.state ~= 'falling' and game.state == 'playing' then
        local preview = {x = tile.x, y = tile.y, dx = facing.dx, dy = facing.dy}
        self:fallWarning(preview, Environment.fallCells(game.room, tile.x, tile.y, facing.dx, facing.dy), true)
    end
    for _, e in ipairs(game:entities()) do
        if e.enemy and (e.enemy.state == 'warn' or e.enemy.state == 'dash') then
            for _, cell in ipairs(e.enemy.cells) do
                if cell.impact then
                    local x, y = (cell.x - 1) * 40, (cell.y - 1) * 40
                    color(C.red, .85); G.setLineWidth(2); G.rectangle('line', x + 3, y - 9, 34, 37, 3)
                    arrow(x + 20, y + 8, e.enemy.dx, e.enemy.dy, C.white, 5)
                end
            end
        end
        if e.resonator and e.resonator.state == 'primed' then
            for _, cell in ipairs(e.resonator.walls or {}) do
                local x, y = (cell.x - 1) * 40, (cell.y - 1) * 40
                color(C.gold, .20); G.rectangle('fill', x + 2, y - 9, 36, 36, 3)
                color(C.gold); G.setLineWidth(2); G.rectangle('line', x + 2, y - 9, 36, 36, 3)
                color(C.white, .85); G.line(x + 22, y - 7, x + 16, y + 3, x + 23, y + 9, x + 17, y + 23)
            end
        end
    end
end

function Render:telegraphs(game)
    for _, e in ipairs(game:entities()) do
        if e.resonator and e.resonator.state == 'primed' then
            for _, cell in ipairs(e.resonator.cells) do
                local x, y = (cell.x - 1) * 40, (cell.y - 1) * 40
                color(C.gold, .2 + (self.reducedMotion and 0 or .06 * math.sin(self.time * 18)))
                G.rectangle('fill', x + 3, y + 3, 34, 34, 2)
                color(C.gold, .7); G.setLineWidth(1); G.rectangle('line', x + 4, y + 4, 32, 32, 2)
                G.line(x + 8, y + 29, x + 29, y + 8); G.line(x + 8, y + 18, x + 18, y + 8)
            end
        end
        if e.enemy and (e.enemy.state == 'warn' or e.enemy.state == 'dash') then
            local a = e.enemy
            local progress = a.state == 'dash' and 1 or 1 - a.timer / (a.warningDuration or 1)
            local tint = a.kind == 'ranger' and C.gold or a.kind == 'warden' and C.violet or C.red
            for i, cell in ipairs(a.cells) do
                if a.state ~= 'dash' or i >= (a.dashIndex or 1) then
                    local x, y = (cell.x - 1) * 40, (cell.y - 1) * 40
                    local dx = a.mode == 'cross' and (cell.x == e.grid.x and 0 or cell.x > e.grid.x and 1 or -1) or a.dx
                    local dy = a.mode == 'cross' and (cell.y == e.grid.y and 0 or cell.y > e.grid.y and 1 or -1) or a.dy
                    if a.kind == 'ranger' then
                        color(tint, .24 + progress * .32); G.setLineWidth(2)
                        G.line(x + 20 - dx * 18, y + 20 - dy * 18, x + 20 + dx * 18, y + 20 + dy * 18)
                    else
                        color(tint, .13 + progress * .19); G.rectangle('fill', x + 3, y + 3, 34, 34, 2)
                        color(tint, .55 + progress * .4); G.setLineWidth(1.5)
                        G.rectangle('line', x + 4, y + 4, 32, 32, 2)
                        color(tint, .25); G.line(x + 8, y + 28, x + 28, y + 8)
                    end
                    arrow(x + 20 + dx * 3, y + 20 + dy * 3, dx, dy, tint, 5)
                end
            end
            local x, y = (e.grid.x - .5) * 40, (e.grid.y - .5) * 40
            color(tint, .7); G.setLineWidth(2)
            G.arc('line', 'open', x, y, 23, -pi / 2, -pi / 2 + math.max(.02, progress) * 2 * pi)
        end
    end
end
function Render:actor(e, game)
    local x, y, jump = Render.visualPosition(e)
    if self.reducedMotion then jump = 0 end
    color(C.ink, .65); G.ellipse('fill', x, y + 8, 13 - math.max(0, jump) * .2, 7 - math.max(0, jump) * .08)
    local facing = e.facing
    local mining = e.player and (e.weapon.mineTimer or 0) > 0
    local mineProgress = mining and 1 - e.weapon.mineTimer / Environment.constants.mineRecovery or 0
    local nudge = mining and not self.reducedMotion and math.sin(mineProgress * pi) * 5 or 0
    G.push(); G.translate(x + (mining and e.weapon.mineDx or 0) * nudge, y - jump + (mining and e.weapon.mineDy or 0) * nudge)
    if e.motion and e.motion.falling and not self.reducedMotion then
        G.scale(math.max(.3, 1 - (1 - e.motion.remaining / e.motion.duration) * .6))
    end
    local immune = e.health and e.health.immune > 0
    local blink = immune and math.floor(self.time * 22) % 2 == 0
    if e.target then
        color({.32, .26, .20}); G.rectangle('fill', -3, -5, 6, 20, 1)
        G.setLineWidth(2); G.line(-11, 14, 0, 9, 11, 14)
        color(C.gold); G.circle('fill', 0, -9, 16)
        color(C.text); G.circle('fill', 0, -9, 13)
        color(C.red); G.circle('fill', 0, -9, 10)
        color(C.text); G.circle('fill', 0, -9, 6)
        color(C.red); G.circle('fill', 0, -9, 3)
    elseif e.resonator then
        local primed = e.resonator.state == 'primed'
        local pulse = primed and math.sin(self.time * 22) * 2 or math.sin(self.time * 3) * .5
        color(C.ink); G.ellipse('fill', 0, 6, 13, 7)
        color({.27, .23, .20}); G.polygon('fill', -13, 5, -9, -1, 8, -1, 13, 5, 5, 10, -5, 10)
        color({.80, .36, .13}); G.polygon('fill', 0, -22 - pulse, 9, -8, 5, 5, -5, 5, -9, -8)
        color(C.gold); G.polygon('fill', 0, -22 - pulse, 1, -7, -5, 5, -9, -8)
        color({1, .88, .59}); G.polygon('fill', 0, -22 - pulse, 9, -8, 1, -7)
        color(C.white, .55); G.line(-3, -16, -6, -7)
        if primed then
            color(C.gold); G.setLineWidth(2)
            G.arc('line', 'open', 0, 0, 21, -pi / 2, -pi / 2 + math.max(.01, 1 - e.resonator.timer / .62) * pi * 2)
            text(self.fonts.tiny, '!', -3, -38, C.gold)
        end
    elseif e.player then
        local w = e.weapon; local weaponColor = game.weapons.bow.color
        if w.state == 'ready' then
            color(weaponColor, .30 + .12 * math.sin(self.time * 7)); G.setLineWidth(1.5)
            G.circle('line', 0, 0, 21); diamond(-16, -18, 3, weaponColor); diamond(16, -18, 3, weaponColor)
        elseif w.state == 'charging' then
            color(weaponColor, .85); G.setLineWidth(2)
            G.arc('line', 'open', 0, 0, 21, -pi / 2, -pi / 2 + math.max(.01, w.charge / game.weapons.bow.chargeTime) * pi * 2)
        end
        color(blink and C.white or {.07, .28, .28}); G.polygon('fill', -8, -8, 8, -8, 12, 13, 0, 17, -12, 13)
        color(C.jade, .8); G.polygon('fill', -9, -5, -4, -8, -5, 10, -9, 12)
        color({.18, .52, .47}); G.polygon('fill', 5, -7, 10, -4, 9, 10, 5, 9)
        color(C.ink); G.rectangle('fill', -7, 9, 5, 5, 1); G.rectangle('fill', 3, 9, 5, 5, 1)
        color(C.gold); G.rectangle('fill', -7, 4, 14, 2); diamond(0, 5, 2, C.gold)
        color(blink and C.white or {.24, .65, .59}); G.circle('fill', 0, -7, 10)
        color(C.ink); G.ellipse('fill', facing.dx * 2, -7 + facing.dy * 2, 7, 5)
        color(C.gold); G.rectangle('fill', -3 + facing.dx * 3, -8 + facing.dy * 2, 3, 2)
        G.rectangle('fill', 2 + facing.dx * 3, -8 + facing.dy * 2, 3, 2)
        color(C.jade); G.polygon('fill', -8, -2, -15, 1, -18, 9 + math.sin(self.time * 5) * 2, -10, 5)
        G.push(); G.rotate(math.atan2(mining and w.mineDy or facing.dy, mining and w.mineDx or facing.dx))
        if mining then
            G.push(); G.translate(14, 4); G.rotate(-.8 + mineProgress * 1.5)
            self:weapon('pickaxe', 0, 0, .8, C.gold); G.pop()
        else self:weapon('bow', w.state == 'action' and 19 or 12, 5, .60, weaponColor) end
        if e.guard.active then
            color(C.jade, .17); G.arc('fill', 'pie', 0, 0, 27, -.8, .8)
            color(C.jade); G.setLineWidth(3); G.arc('line', 'open', 0, 0, 24, -.8, .8)
            color(C.white, .65); G.setLineWidth(1); G.arc('line', 'open', 0, 0, 27, -.65, .65)
        end
        G.pop()
    else
        local a = e.enemy
        local recover = a.state == 'recover'
        if a.kind == 'warden' then
            color(a.phase2 and {.30, .12, .35} or {.18, .20, .28})
            G.polygon('fill', -13, -12, 13, -12, 17, 13, 0, 19, -17, 13)
            color(a.phase2 and C.red or C.violet)
            G.polygon('fill', -14, -7, -20, -10, -19, 4, -9, 5)
            G.polygon('fill', 14, -7, 20, -10, 19, 4, 9, 5)
            color({.36, .36, .46}); G.polygon('fill', -10, -15, 0, -22, 10, -15, 8, 1, 0, 5, -8, 1)
            color(C.gold); G.polygon('fill', -11, -13, -13, -25, -6, -21, 0, -29, 6, -21, 13, -25, 11, -13)
            color(C.ink); G.rectangle('fill', -7, -12, 14, 5, 1)
            color(a.phase2 and C.red or C.violet); G.rectangle('fill', -5 + facing.dx, -11 + facing.dy, 10, 2)
            diamond(0, 10, 4, a.phase2 and C.red or C.violet)
            if a.phase2 then color(C.red, .35); G.circle('line', 0, -8, 25 + math.sin(self.time * 4) * 2) end
        elseif a.kind == 'dasher' then
            color({.43, .13, .16}); G.polygon('fill', -11, -9, 10, -9, 13, 10, -11, 13)
            color(recover and C.muted or C.red); G.polygon('fill', -11, -4, -15, -7, -11, 5, -6, 4)
            G.polygon('fill', 10, -4, 15, -7, 12, 5, 6, 4)
            color({.65, .25, .23}); G.polygon('fill', -9, -10, -5, -16, 5, -16, 10, -9, 7, 2, -6, 2)
            color(C.gold); G.polygon('fill', -8, -11, -13, -17, -10, -7); G.polygon('fill', 8, -11, 13, -17, 10, -7)
            color(C.ink); G.rectangle('fill', -7 + facing.dx, -9 + facing.dy, 14, 4, 1)
            color(C.red); G.rectangle('fill', -5 + facing.dx * 2, -8 + facing.dy * 2, 10, 1.5)
            color(C.ink); G.rectangle('fill', -8, 10, 5, 5); G.rectangle('fill', 4, 10, 5, 5)
            G.push(); G.rotate(math.atan2(facing.dy, facing.dx)); color(C.muted)
            G.line(3, 11, 19, 11); color(C.red); G.polygon('fill', 20, 4, 26, 10, 19, 18, 15, 14); G.pop()
        else
            color({.35, .25, .40}); G.polygon('fill', -8, -10, 9, -10, 15, 12, 0, 17, -14, 12)
            color(recover and C.muted or C.gold); G.polygon('fill', -10, -6, -5, -13, 5, -13, 10, -6, 7, 4, -7, 4)
            color(C.ink); G.ellipse('fill', facing.dx * 2, -5 + facing.dy * 2, 6, 5)
            diamond(facing.dx * 3, -6 + facing.dy * 3, 3, C.gold)
            color(C.gold, .5); G.line(-7, 4, -10, 11, 0, 14, 10, 11, 7, 4)
            G.push(); G.rotate(math.atan2(facing.dy, facing.dx))
            color(C.muted); G.line(15, -11, 15, 13); diamond(15, -13, 6, C.gold)
            color(C.ink); G.circle('fill', 15, -13, 3); diamond(15, -13, 1.5, C.gold); G.pop()
        end
        if a.frontalArmor then
            G.push(); G.rotate(math.atan2(facing.dy, facing.dx))
            color({.19, .23, .29}); G.polygon('fill', 13, -13, 19, -8, 21, 0, 19, 8, 13, 13, 9, 8, 9, -8)
            color(C.muted); G.setLineWidth(2); G.line(13, -13, 19, -8, 21, 0, 19, 8, 13, 13)
            color(C.gold); G.line(13, -5, 16, -3, 17, 0, 16, 3, 13, 5)
            G.pop()
        end
        local hp = e.health
        color(C.ink); G.rectangle('fill', -14, -25, 28, 4, 1)
        color(a.kind == 'ranger' and C.gold or C.red); G.rectangle('fill', -13, -24, 26 * hp.current / hp.max, 2, 1)
        if a.state == 'stunned' then
            diamond(-6, -35, 2, C.violet); diamond(5, -33, 2, C.violet)
        elseif a.state == 'warn' then
            text(self.fonts.small, '!', -4, -43, C.white)
        elseif recover then
            color(C.muted, .65); G.circle('line', -4, -33, 1); G.circle('line', 1, -33, 1); G.circle('line', 6, -33, 1)
        end
    end
    G.pop()
end

function Render:projectile(e)
    local p, s = e.grid, e.projectile
    -- Projectile interpolation is visual; the grid remains the damage authority.
    local progress = math.min(1, s.clock / s.interval)
    local x, y = (p.x - .5 + s.dx * progress) * 40, (p.y - .5 + s.dy * progress) * 40
    G.push(); G.translate(x, y); G.rotate(math.atan2(s.dy, s.dx))
    local c = s.kind == 'bolt' and C.red or C.gold
    color(c, .28); G.setLineWidth(3); G.line(-25, 0, -7, 0)
    if s.kind == 'bolt' then
        diamond(0, 0, 5, c); color(C.white); G.line(-5, 0, 5, 0)
    else
        color(c); G.setLineWidth(1.5); G.line(-15, 0, 10, 0)
        G.polygon('fill', 13, 0, 6, -3, 6, 3); G.line(-12, -3, -8, 0, -12, 3)
    end
    G.pop()
end

function Render:effects()
    for _, p in ipairs(self.feedback.rings) do
        local life = p.life / p.max
        color(p.color, life * .8); G.setLineWidth(1 + life * 2)
        G.circle('line', p.x, p.y, p.radius * (1 - life * life))
    end
    for _, p in ipairs(self.feedback.particles) do
        local life = math.min(1, p.life / .3)
        color(p.color, life); G.rectangle('fill', p.x, p.y, p.size * life, p.size * life)
    end
    for _, p in ipairs(self.feedback.popups) do
        G.push(); G.translate(p.x, p.y); G.scale(p.size)
        G.setFont(self.fonts.medium); color(C.ink, p.alpha)
        G.printf(p.text, -90 + 1, 1, 180, 'center'); color(p.color, p.alpha)
        G.printf(p.text, -90, 0, 180, 'center'); G.pop()
    end
end

function Render:world(game)
    self:floor(game); self:telegraphs(game)
    local layers = {}
    for _, tile in pairs(game.room.tiles) do
        if tile.piece and tile.piece ~= 'portal' then
            layers[#layers + 1] = {tile = tile, depth = tile.y * 40, x = tile.x * 40}
        end
    end
    for _, e in ipairs(game:entities()) do
        if e.projectile or e.health and e.health.current > 0 then
            local x, y = Render.visualPosition(e)
            layers[#layers + 1] = {entity = e, depth = y + (e.projectile and 4 or 17), x = x}
        end
    end
    table.sort(layers, function(a, b)
        if a.depth ~= b.depth then return a.depth < b.depth end
        if a.x ~= b.x then return a.x < b.x end
        return a.tile == nil and b.tile ~= nil
    end)
    for _, layer in ipairs(layers) do
        if layer.tile then self:wall(game.room, layer.tile)
        elseif layer.entity.projectile then self:projectile(layer.entity)
        else self:actor(layer.entity, game) end
    end
    self:terrainWarnings(game)
    self:effects()
end

function Render:minimap(game, x, y, width, height)
    local visible, minX, maxX, minY, maxY = {}, math.huge, -math.huge, math.huge, -math.huge
    for _, room in ipairs(game.rooms) do
        if game:mapVisible(room) then
            visible[#visible + 1] = room
            minX, maxX = math.min(minX, room.mapX), math.max(maxX, room.mapX)
            minY, maxY = math.min(minY, room.mapY), math.max(maxY, room.mapY)
        end
    end
    if #visible == 0 then return end
    local step = math.min(25, (width - 14) / (maxX - minX + 1), (height - 12) / (maxY - minY + 1))
    local ox, oy = x + width / 2 - (minX + maxX) * step / 2, y + height / 2 - (minY + maxY) * step / 2
    G.setLineWidth(1.5)
    for _, room in ipairs(visible) do
        for _, door in ipairs(room.doors) do
            local other = game.rooms[door.to]
            if other and room.id < other.id and game:mapVisible(other) and (not door.hidden or door.revealed) then
                color(C.line); G.line(ox + room.mapX * step, oy + room.mapY * step, ox + other.mapX * step, oy + other.mapY * step)
            end
        end
    end
    local icons = {treasure = 'T', shop = '$', refuge = '+', secret = '?', supersecret = '?'}
    local rw, rh = step * .78, step * .65
    for _, room in ipairs(visible) do
        local rx, ry = ox + room.mapX * step, oy + room.mapY * step
        local current = game.roomId == room.id
        local tint = current and C.jade or room.visited and C.gold or room.discovered and C.muted or {.35, .43, .47}
        if not room.visited and (room.kind == 'secret' or room.kind == 'supersecret') then tint = C.violet end
        color(C.ink); G.rectangle('fill', rx - rw / 2, ry - rh / 2, rw, rh, 1)
        color(tint); G.rectangle(current and 'fill' or 'line', rx - rw / 2, ry - rh / 2, rw, rh, 1)
        local icon = room.kind == 'boss' and room.visited and 'B' or icons[room.kind]
        if icon then
            G.push(); G.translate(rx, ry); G.scale(math.min(1, rh / 13))
            text(self.fonts.tiny, icon, -10, -7, current and C.ink or tint, 20, 'center'); G.pop()
        end
    end
end
function Render:hud(game, w, h)
    local f, e = self.fonts, game.player
    local hp, guard, weapon = e.health, e.guard, e.weapon
    panel(22, 20, 276, 136)
    text(f.tiny, 'O VIAJANTE', 38, 30, C.muted)
    text(f.small, math.ceil(hp.current) .. ' / ' .. hp.max, 211, 28, hp.current <= 3 and C.red or C.text, 66, 'right')
    for i = 1, hp.max do
        local alive = i <= hp.current
        local c = alive and (hp.current <= 3 and C.red or C.jade) or C.line
        color(c); G.rectangle('fill', 38 + (i - 1) * 23, 51, 19, 13, 2)
        if alive then color(C.white, .25); G.rectangle('fill', 40 + (i - 1) * 23, 52, 15, 2) end
    end
    text(f.tiny, 'ESCUDO', 38, 77, guard.exhausted and C.red or C.muted)
    color(C.line); G.rectangle('fill', 103, 81, 121, 4, 2)
    color(guard.exhausted and C.red or C.jade); G.rectangle('fill', 103, 81, 121 * guard.energy / guard.max, 4, 2)
    text(f.tiny, 'SHIFT', 234, 77, guard.active and C.jade or C.text)
    text(f.small, 'PICARETAS  ' .. game.pickaxes, 38, 98, game.pickaxes == 0 and C.red or C.gold)
    text(f.tiny, '3 toques / peça', 173, 101, C.muted)
    text(f.small, 'OURO  ' .. game.gold, 38, 122, C.gold)
    local relics = {}
    for _, choice in ipairs(require('src.progression').catalog) do
        if game.upgrades[choice.id] then relics[#relics + 1] = choice end
    end
    if #relics > 0 then
        text(f.tiny, 'RELÍQUIAS', 29, 169, C.muted)
        for i, relic in ipairs(relics) do
            diamond(33, 193 + (i - 1) * 19, 2, relic.color)
            text(f.tiny, relic.title, 43, 187 + (i - 1) * 19, relic.color)
        end
    end
    panel(310, 20, w - 532, 112)
    text(f.tiny, game.practice and 'SALA DE COMBATE' or 'ANDAR ' .. game.floorNumber, 326, 27, C.muted)
    text(f.medium, game.room.name, 326, 45, C.text)
    local status = game.room.challenge == 'targets' and 'ALVOS  ' .. (3 - game:targetCount()) .. ' / 3 · saída livre' or
        game.room.challenge == 'combat' and 'Desafio opcional · ' .. game:enemyCount() .. ' inimigos · saída livre' or
        game:enemyCount() > 0 and game:enemyCount() .. ' inimigos · leia o aviso e saia da linha' or
        'Sala tranquila · explore e saia pelo portal'
    text(f.small, status, 326, 75, game:enemyCount() > 0 and C.muted or C.jade, w - 566)
    local tactic = game.room.challenge == 'targets' and 'Acerte os 3 alvos com o arco. Saída sempre livre.' or game.room.tactic
    if tactic then text(f.tiny, tactic, 326, 98, C.gold, w - 566) end
    panel(w - 206, 20, 184, game.practice and 91 or 194)
    if game.practice then
        text(f.tiny, 'EXPERIMENTE', w - 190, 31, C.muted)
        text(f.body, '3 toques', w - 190, 49, C.gold)
        text(f.tiny, '1 picareta por peça', w - 190, 79, C.muted, 154)
    else
        text(f.tiny, 'MAPA · ANDAR ' .. game.floorNumber, w - 190, 29, C.muted)
        self:minimap(game, w - 194, 49, 160, 116)
        text(f.tiny, '$ loja · T tesouro', w - 194, 176, C.muted, 160, 'center')
        text(f.tiny, '+ refúgio · ? segredo', w - 194, 195, C.muted, 160, 'center')
    end
    local d = game:weaponStats()
    local cw, x, y = 360, w / 2 - 180, h - 111
    panel(x, y, cw, 82, d.color)
    self:weapon('bow', x + 36, y + 25, .8, d.color)
    text(f.small, d.label, x + 69, y + 10, C.text)
    text(f.tiny, d.damage .. ' dano / linha livre', x + 69, y + 32, C.muted)
    local mining = (weapon.mineTimer or 0) > 0
    local label = mining and 'MINERANDO' or weapon.state == 'ready' and 'SOLTE SPACE' or
        weapon.state == 'charging' and 'CARREGANDO' or weapon.state == 'action' and 'EM AÇÃO' or 'SEGURE SPACE'
    local ratio = weapon.state == 'charging' and weapon.charge / d.chargeTime or weapon.state == 'ready' and 1 or 0
    text(f.small, label, x + 12, y + 53, d.color)
    color(C.line); G.rectangle('fill', x + 12, y + 73, cw - 24, 3, 1)
    color(d.color); G.rectangle('fill', x + 12, y + 73, (cw - 24) * ratio, 3, 1)
    text(f.tiny, 'WASD mover / minerar    SPACE segurar e soltar    SHIFT escudo    TAB guia    ESC pausa', 20, h - 21, C.muted, w - 40, 'center')
    if game.messageTime > 0 then
        local width = math.min(w - 80, f.small:getWidth(game.message) + 42)
        local messageY = game.room.final and game:enemyCount() > 0 and 182 or 122
        panel((w - width) / 2, messageY, width, 37, C.jade)
        text(f.small, game.message, (w - width) / 2 + 15, messageY + 9, C.text, width - 30, 'center')
    elseif self.feedback.banner > .1 and not game.reward and game.state == 'playing' then
        text(f.medium, 'SALA DOMINADA', w / 2 - 160, 128, C.jade, 320, 'center')
    end
    for _, boss in ipairs(game:entities()) do
        if boss.enemy and boss.enemy.kind == 'warden' and boss.health.current > 0 then
            local bx = w / 2 - 180
            text(f.small, 'GUARDIÃO DOS ECOS', bx, 118, boss.enemy.phase2 and C.red or C.violet, 360, 'center')
            color(C.ink); G.rectangle('fill', bx, 141, 360, 9, 2)
            color(boss.enemy.phase2 and C.red or C.violet); G.rectangle('fill', bx + 1, 142, 358 * boss.health.current / boss.health.max, 7, 2)
            text(f.tiny, boss.enemy.phase2 and 'SELO PARTIDO · saia da cruz' or 'SELO FRONTAL · ataque pelos flancos', bx, 157, C.muted, 360, 'center')
        end
    end
    if hp.current <= 3 and game.state == 'playing' then
        color(C.red, .14 + math.sin(self.time * 4) * .035); G.setLineWidth(3); G.rectangle('line', 3, 3, w - 6, h - 6)
    end
end

function Render:button(key, label, desc, x, y, width, accent)
    panel(x, y, width, 66, accent)
    color(accent, .14); G.rectangle('fill', x + 12, y + 14, 52, 37, 4)
    text(self.fonts.small, key, x + 12, y + 23, accent, 52, 'center')
    text(self.fonts.body, label, x + 79, y + 13, C.text)
    text(self.fonts.small, desc, x + 79, y + 36, C.muted)
end

function Render:emblem(x, y, size)
    G.push(); G.translate(x, y); G.scale(size)
    for i = 1, 5 do color(C.jade, .013); G.circle('fill', 0, 0, 175 - i * 17) end
    color(C.line, .7); G.setLineWidth(1); G.circle('line', 0, 0, 132); G.circle('line', 0, 0, 139)
    for i = 0, 23 do
        local a = i * pi / 12 + self.time * .012
        color(i % 3 == 0 and C.gold or C.line, .75)
        G.line(math.cos(a) * 137, math.sin(a) * 137, math.cos(a) * (i % 3 == 0 and 148 or 143), math.sin(a) * (i % 3 == 0 and 148 or 143))
    end
    color(C.jade, .07); G.polygon('fill', 0, -103, 95, 2, 0, 103, -95, 2)
    color(C.jade, .4); G.polygon('line', 0, -103, 95, 2, 0, 103, -95, 2)
    G.push(); G.rotate(-pi / 2); self:weapon('bow', 0, 0, 4.5); G.pop()
    diamond(0, 99, 5, C.gold); diamond(0, -104, 4, C.jade)
    G.pop()
end

function Render:title(game, w, h)
    color(C.ink, .85); G.rectangle('fill', 0, 0, w, h)
    local left = math.max(58, (w - 1120) / 2)
    local top = h / 2 - 243
    text(self.fonts.small, 'UM PASSO MUDA TUDO.', left + 4, top, C.jade)
    text(self.fonts.title, 'ARROW', left, top + 25, C.text)
    text(self.fonts.title, 'FALLEN', left, top + 85, C.gold)
    color(C.gold); G.rectangle('fill', left + 4, top + 173, 59, 2)
    text(self.fonts.body, 'Domine o ritmo. Quebre a linha.\nTransforme cada bloco numa oportunidade.', left + 4, top + 193, C.muted)
    self:button('ENTER', 'A câmara dos ecos', 'Arco, paredes, pilares e buracos', left, top + 264, 490, C.jade)
    self:button('N', 'Descer à queda', '7–8 salas iniciais + 2 segredos', left, top + 342, 490, C.gold)
    text(self.fonts.small, 'TAB  Como jogar', left + 4, top + 433, C.text)
    self:emblem(w - math.max(230, (w - 1000) / 2), h / 2 - 7, math.min(1.20, w / 1050))
    text(self.fonts.small, 'SEM MIRA AUTOMÁTICA.\nSEM TURNOS.\nSÓ A SUA PRÓXIMA DECISÃO.', w - 382, h / 2 + 185, C.muted, 305, 'center')
    text(self.fonts.tiny, 'WASD mover e minerar    /    SPACE segurar e soltar    /    SHIFT defender', 40, h - 36, C.muted, w - 80, 'center')
    text(self.fonts.small, 'Arco · segure SPACE, solte quando pronto', left + 4, top + 463, C.gold)
end

function Render:help(w, h)
    color(C.ink, .94); G.rectangle('fill', 0, 0, w, h)
    local width, x, y = 920, (w - 920) / 2, h / 2 - 311
    panel(x, y, width, 622, C.jade)
    text(self.fonts.small, 'GUIA DO VIAJANTE', x + 32, y + 24, C.jade)
    text(self.fonts.large, 'Leia o tabuleiro. Faça o próximo passo.', x + 32, y + 50, C.text)
    local rows = {
        {'WASD', 'Mova, mire ou dê uma pancada adjacente', 'A última direção aponta o arco e o escudo; mineração exige novos toques.'},
        {'PICARETAS', 'Três hits abrem uma peça', 'Hits 1 e 2 ficam marcados. O terceiro gasta uma picareta, sem avançar.'},
        {'PILARES', 'Escolha o lado da última pancada', 'O preview muda com seu lado; o terceiro hit trava cinco blocos de queda.'},
        {'BURACOS', 'O salto para o vazio é fatal', 'Não é possível voltar durante a queda. O aviso de pilar também pode matar.'},
        {'SPACE', 'Segure para carregar o arco', 'Quando aparecer SOLTE SPACE, solte para disparar uma vez na direção da mira.'},
        {'SOLTAR', 'Escolha o momento do tiro', 'Soltar cedo cancela; manter SPACE pressionado quando pronto não dispara.'},
        {'SHIFT', 'Segure para defender de frente', 'O bloqueio solta uma onda. Levantar escudo cancela a carga. Evite os flancos.'},
        {'1 / 2 / 3', 'Escolha uma relíquia na recompensa', 'O arco permanece equipado; números escolhem apenas cartas de recompensa.'},
        {'! / >>>', 'O aviso é uma promessa', 'Saia da investida, do tiro e da queda. Ataque o bruto pelos flancos.'},
        {'CENÁRIO', 'Abra passagem e linha de tiro', 'O cenário está sempre visível. Cristais e dash rompem peças; tiros param nelas.'},
        {'SEGREDOS', 'Combate ou três alvos com o arco', 'Brilho sutil marca entradas. Desafios dão relíquias; a saída fica sempre livre.'},
    }
    for i, row in ipairs(rows) do
        local ry = y + 103 + (i - 1) * 40
        color(C.line, .5); G.line(x + 32, ry + 38, x + width - 32, ry + 38)
        text(self.fonts.small, row[1], x + 32, ry + 6, i == 9 and C.gold or C.jade, 120, 'center')
        text(self.fonts.body, row[2], x + 174, ry, C.text)
        text(self.fonts.small, row[3], x + 174, ry + 21, C.muted)
    end
    text(self.fonts.small, '7–8 salas iniciais + 2 segredos; cada andar acrescenta 2–3 salas. Vença o chefe para descer.', x + 32, y + 556, C.gold)
    text(self.fonts.small, 'TAB / ESC voltar    ·    F2 reduzir movimento    ·    M áudio    ·    F11 tela cheia', x + 32, y + 589, C.text)
end

function Render:pause(w, h)
    color(C.ink, .82); G.rectangle('fill', 0, 0, w, h)
    local x, y = w / 2 - 246, h / 2 - 206
    panel(x, y, 492, 412, C.jade)
    text(self.fonts.small, 'RESPIRE. O TEMPO ESPERA.', x + 28, y + 29, C.jade)
    text(self.fonts.large, 'A queda pode esperar.', x + 28, y + 61, C.text)
    self:button('ESC', 'Continuar', 'Volte exatamente onde parou', x + 26, y + 123, 440, C.jade)
    self:button('TAB', 'Consultar o guia', 'Arco, mineração, avisos e defesa', x + 26, y + 203, 440, C.gold)
    text(self.fonts.body, 'R  Recomeçar    ·    Q  Menu', x + 28, y + 295, C.text)
    text(self.fonts.small, 'M áudio: ' .. (self.muted and 'desligado' or 'ligado'), x + 28, y + 338, C.muted)
    text(self.fonts.small, 'F2 movimento: ' .. (self.reducedMotion and 'reduzido' or 'completo'), x + 28, y + 364, C.muted)
end

function Render:ending(game, w, h)
    local won = game.state == 'won'
    local c = won and C.gold or C.red
    color(C.ink, .86); G.rectangle('fill', 0, 0, w, h)
    local x, y = w / 2 - 270, h / 2 - 210
    panel(x, y, 540, 420, c)
    diamond(w / 2, y + 54, 13, c, 'line'); diamond(w / 2, y + 54, 5, c)
    text(self.fonts.small, won and 'O TABULEIRO É SEU.' or 'A QUEDA DEIXA MARCAS.', x + 28, y + 89, c, 484, 'center')
    text(self.fonts.large, won and (game.practice and 'Câmara dominada.' or 'Andar ' .. game.floorNumber .. ' dominado.') or 'Um novo passo. Outra chance.', x + 28, y + 118, C.text, 484, 'center')
    local lesson = game.deathCause == 'hole' and 'O salto para o buraco não tem volta. Escolha um piso seguro.' or
        game.deathCause == 'crushed' and 'O pilar esmaga quem fica no corredor. Saia durante o aviso.' or
        'Saia da linha durante o aviso. Ataque na recuperação.'
    text(self.fonts.body, won and 'Use o arco e o cenário para inventar outra maneira de vencer.' or lesson, x + 35, y + 176, C.muted, 470, 'center')
    text(self.fonts.small, game.kills .. ' inimigos vencidos    ·    ' .. math.floor(game.time) .. 's de combate', x + 28, y + 222, c, 484, 'center')
    if won and not game.practice then
        self:button('ENTER', 'Próximo andar', 'Preserve seu arco, relíquias e ouro', x + 30, y + 269, 480, c)
        text(self.fonts.small, 'R  Recomeçar    ·    N  Nova expedição    ·    Q  Menu', x + 30, y + 372, C.text, 480, 'center')
    else
        self:button('R', 'Mais uma tentativa', 'A mesma jornada, uma nova solução', x + 30, y + 269, 480, c)
        text(self.fonts.small, 'N  Nova expedição    ·    ENTER  Menu', x + 30, y + 372, C.text, 480, 'center')
    end
end

function Render:reward(game, w, h)
    color(C.ink, .80); G.rectangle('fill', 0, 0, w, h)
    local x, y, width = w / 2 - 435, h / 2 - 210, 870
    panel(x, y, width, 420, C.gold)
    text(self.fonts.small, 'A CÂMARA LHE OFERECE UM PRESENTE', x + 28, y + 24, C.gold, width - 56, 'center')
    text(self.fonts.large, 'Qual será seu próximo poder?', x + 28, y + 55, C.text, width - 56, 'center')
    text(self.fonts.small, 'Construa sua própria maneira de lutar. Escolha uma relíquia.', x + 28, y + 105, C.muted, width - 56, 'center')
    for i, choice in ipairs(game.rewardChoices or {}) do
        local cx, cy, cw = x + 24 + (i - 1) * 282, y + 144, 258
        panel(cx, cy, cw, 218, choice.color)
        diamond(cx + cw / 2, cy + 36, 13, choice.color, 'line'); diamond(cx + cw / 2, cy + 36, 5, choice.color)
        text(self.fonts.body, choice.title, cx + 12, cy + 66, C.text, cw - 24, 'center')
        text(self.fonts.small, choice.description, cx + 18, cy + 98, C.muted, cw - 36, 'center')
        color(choice.color, .13); G.rectangle('fill', cx + 20, cy + 176, cw - 40, 28, 3)
        text(self.fonts.small, tostring(i) .. '  ESCOLHER', cx + 20, cy + 182, choice.color, cw - 40, 'center')
    end
    text(self.fonts.tiny, 'Depois da escolha, explore o andar e siga pelos portais abertos. Seu arco permanece equipado.', x + 28, y + 387, C.muted, width - 56, 'center')
end

function Render:draw(game, screen)
    G.push('all')
    G.clear(C.ink)
    local w, h = G.getDimensions()
    local trauma = self.reducedMotion and 0 or self.feedback.trauma^2
    local baseX, baseY = self.camera:position()
    self.camera:lookAt(baseX + math.sin(self.time * 51) * trauma * 6, baseY + math.sin(self.time * 67) * trauma * 4)
    self.camera:attach(); self:world(game); self.camera:detach()
    self.camera:lookAt(baseX, baseY)
    if self.feedback.flash > 0 and not self.reducedMotion then color(C.red, self.feedback.flash * .8); G.rectangle('fill', 0, 0, w, h) end
    local scale = math.min(w / 1120, h / 720)
    G.scale(scale)
    w, h = w / scale, h / scale
    if screen == 'title' then self:title(game, w, h)
    elseif screen == 'help' then self:help(w, h)
    else
        self:hud(game, w, h)
        if screen == 'paused' then self:pause(w, h)
        elseif game.state == 'dead' or game.state == 'won' then self:ending(game, w, h)
        elseif game.reward then self:reward(game, w, h) end
    end
    G.pop()
end

return Render





