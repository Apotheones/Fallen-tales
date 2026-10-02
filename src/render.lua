local PixelWorld = require('src.pixel_world')
local PixelActors = require('src.pixel_actors')
local PixelFont = require('src.pixel_font')
local Feedback = require('src.feedback')
local Rooms = require('src.rooms')
local Props = require('src.props')
local Environment = require('src.environment')
local Enemies = require('src.enemies')
local Progression = require('src.progression')
local Lore = require('src.lore')
local utf8 = require('utf8')
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
    value = PixelFont.clean(value)
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
local pixelLine = PixelWorld.pixelLine
local function arrow(x, y, dx, dy, c, size)
    color(c)
    pixelLine(x - dx * size - dy * size, y - dy * size + dx * size, x, y)
    pixelLine(x, y, x - dx * size + dy * size, y - dy * size - dx * size)
end
local function border(x, y, w, h, c, alpha)
    color(c, alpha)
    G.rectangle('fill', x, y, w, 1); G.rectangle('fill', x, y + h - 1, w, 1)
    G.rectangle('fill', x, y, 1, h); G.rectangle('fill', x + w - 1, y, 1, h)
end

-- This interpolation is a view over committed grid positions; it never changes collision.
function Render.visualPosition(entity)
    local p, m = entity.grid, entity.motion
    if m and m.remaining > 0 then
        local t = 1 - m.remaining / m.duration
        local ease = t * t * (3 - 2 * t)
        return ((m.fromX + (p.x - m.fromX) * ease) - .5) * 32,
            ((m.fromY + (p.y - m.fromY) * ease) - .5) * 32, math.sin(t * pi) * 7 - (m.falling and t^3 * 22 or 0)
    end
    return (p.x - .5) * 32, (p.y - .5) * 32, 0
end

Render.secretHint = PixelWorld.secretHint

function Render.selfCheck()
    local e = {grid = {x = 4, y = 3}, motion = {fromX = 3, fromY = 3, duration = .16, remaining = .08}}
    local x, y, jump = Render.visualPosition(e)
    assert(x == 96 and y == 80 and math.abs(jump - 7) < .0001, 'Hop interpolation is purely visual')
    assert(e.grid.x == 4 and e.grid.y == 3, 'Rendering must not move the logical grid position')
    e.motion.remaining = 0
    x, y, jump = Render.visualPosition(e)
    assert(x == 112 and y == 80 and jump == 0, 'Landing returns exactly to the committed grid center')
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
    local view = setmetatable({time = 0, fonts = {tiny = PixelFont.new(1)}}, Render)
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
    local mark = {x = 3, y = 2, id = 'entrance'}
    G.push('all')
    view.time = .15; view:wall(game.room, game.room.tiles['4:4'])
    view:inscription(mark)
    view:actor({grid = {x = 3, y = 3}, target = {data = {hit = false}}}, game)
    G.pop()
    assert(hidden.hidden and not hidden.revealed, 'Drawing a hidden brick never reveals its entrance')
    assert(mark.x == 3 and mark.y == 2 and not mark.read, 'Drawing an inscription never marks it as read')
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

local function round(n) return math.floor(n + .5) end

-- left/top are integer presentation offsets, never simulation coordinates.
function Render.layout(width, height, room, feetX, feetY, header)
    header = header or 112
    local scale = 2
    scale = math.max(1, math.min(scale, math.floor(width / 256), math.floor(height / 192)))
    local w, h = math.max(1, math.floor((width - 24) / scale)), math.max(1, math.floor((height - header - 80) / scale))
    local rw, rh = room.w * 32, room.h * 32
    local left = rw <= w and math.floor((rw - w) / 2) or math.max(0, math.min(rw - w, round(feetX - w / 2)))
    local top = rh <= h and math.floor((rh - h) / 2) or math.max(0, math.min(rh - h, round(feetY - h / 2)))
    return {scale = scale, w = w, h = h, x = math.floor((width - w * scale) / 2),
        y = header + math.floor((height - header - 80 - h * scale) / 2), left = left, top = top}
end

function Render.mapHeight(game)
    local minY,maxY=math.huge,-math.huge
    for _,room in ipairs(game.rooms) do
        if game:mapVisible(room) then minY,maxY=math.min(minY,room.mapY),math.max(maxY,room.mapY) end
    end
    return minY==math.huge and 43 or math.max(43,math.min(96,(maxY-minY+1)*12+27))
end

function Render.new()
    local self = setmetatable({feedback = Feedback.new(), actors = PixelActors.new(), time = 0,
        fonts = {}, muted = false, reducedMotion = false, roomTime = 0}, Render)
    -- One authored bitmap face at integer scales keeps every glyph crisp.
    for name, scale in pairs({tiny = 1, small = 1, body = 2, medium = 2, large = 3, title = 6}) do
        self.fonts[name] = PixelFont.new(scale)
    end
    local bitmap = self.fonts.tiny
    self.worldFonts, self.hudFont = {tiny = bitmap, body = bitmap}, bitmap
    return self
end

function Render:update(dt, game, screen)
    self.time = self.time + dt
    self.actors:update(dt, game, screen, self.reducedMotion)
    self.feedback.muted, self.feedback.reducedMotion = self.muted, self.reducedMotion
    self.feedback:update(dt, game, screen)
    if self.room ~= game.room then self.room, self.roomTime = game.room, 2.5 end
    if screen == 'playing' and not game.reward then self.roomTime = math.max(0, self.roomTime - dt) end
    if self.gold ~= game.gold or self.pickaxes ~= game.pickaxes or self.xp ~= game.xp or self.level ~= game.level then
        self.gold, self.pickaxes, self.xp, self.level = game.gold, game.pickaxes, game.xp, game.level
        self.resourceTime = 3
    else self.resourceTime = math.max(0, (self.resourceTime or 0) - dt) end
    self:updateDialogueReveal(dt, game.dialogue)
    local x, y = Render.visualPosition(game.player)
    self.view = Render.layout(G.getWidth(), G.getHeight(), game.room, x, y, math.max(112, Render.mapHeight(game)*2+24))
end

-- Typewriter reveal + voice blips; shared by arcade and campaign dialogue.
function Render:updateDialogueReveal(dt, d)
    if not (d and d.mode == 'lines') then return end
    if d.revealIndex ~= d.index then d.revealIndex, d.reveal, d.voiceChars = d.index, 0, 0 end
    local line = d.lines[d.index]
    local target = utf8.len(line) or #line
    d.reveal = self.reducedMotion and target or math.min(target, (d.reveal or 0) + dt * 55)
    local shown = math.floor(math.min(d.reveal, target))
    local unheard = shown - (d.voiceChars or 0)
    if unheard > 0 then
        local pitch = (Lore.voices or {})[d.voice] or 1
        if unheard > 4 or self.reducedMotion then
            self.feedback:play('voice', pitch, .3)
        else
            for i = d.voiceChars + 1, shown do
                local a, b = utf8.offset(line, i), utf8.offset(line, i + 1)
                local ch = a and line:sub(a, (b or #line + 1) - 1) or ''
                if not ch:match('^%s$') then
                    self.feedback:play('voice', pitch * (0.92 + love.math.random() * .16), .3)
                end
            end
        end
        d.voiceChars = shown
    end
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

function Render:floor(game) PixelWorld.floor(self, game) end
function Render:wall(room, tile) PixelWorld.wall(self, room, tile) end

function Render:walls(game)
    for y = 1, game.room.h do for x = 1, game.room.w do
        local tile = Rooms.cell(game.room, x, y)
        if tile and tile.piece and tile.piece ~= 'portal' then self:wall(game.room, tile) end
    end end
end
local function warningCell(cell, tint, dx, dy, progress, overlay, kind)
    local x, y = (cell.x - 1) * 32, (cell.y - 1) * 32
    progress = math.max(0, math.min(1, progress or 0))
    if not overlay then color(tint, .12 + progress * .18); G.rectangle('fill', x, y, 32, 32) end
    border(x + 1, y + 1, 30, 30, tint, .8)
    color(tint); G.rectangle('fill', x + 3, y + 28, math.floor(26 * progress + .5), 2)
    if kind == 'blast' then
        pixelLine(x + 8, y + 8, x + 23, y + 23); pixelLine(x + 23, y + 8, x + 8, y + 23)
        border(x + 12, y + 12, 8, 8, tint)
    elseif kind == 'fall' then
        for i=0,2 do pixelLine(x + 4 + i * 9, y + 24, x + 10 + i * 9, y + 18) end
        arrow(x + 16 + dx * 4, y + 12 + dy * 4, dx, dy, C.text, 4)
    else
        if kind == 'shot' then pixelLine(x + 16 - dx * 12, y + 16 - dy * 12, x + 16 + dx * 12, y + 16 + dy * 12) end
        arrow(x + 16 + dx * 4, y + 16 + dy * 4, dx, dy, tint, 5)
    end
end

function Render:fallWarning(tile, cells, preview)
    local progress = preview and 0 or 1 - tile.timer / tile.duration
    for _, cell in ipairs(cells) do
        warningCell(cell, cell.hole and C.red or preview and C.jade or C.gold, tile.dx, tile.dy, progress, preview, 'fall')
    end
    if not preview then
        local x, y = (tile.x - .5) * 32, (tile.y - .5) * 32
        color(C.ink); G.rectangle('fill', x - 12, y - 52, 24, 12)
        color(C.gold); G.rectangle('fill', x - 11, y - 51, math.floor(22 * progress), 2)
        arrow(x + tile.dx * 2, y - 45 + tile.dy * 2, tile.dx, tile.dy, C.gold, 3)
    end
end

function Render:terrainWarnings(game)
    for _, tile in pairs(game.room.tiles) do
        if tile.state == 'falling' then self:fallWarning(tile, tile.cells, false) end
    end
    local p, facing = game.player.grid, game.player.facing
    local tile = Rooms.cell(game.room, p.x + facing.dx, p.y + facing.dy)
    if tile and tile.piece == 'pillar' and tile.state ~= 'falling' and game.state == 'playing' then
        self:fallWarning({x = tile.x, y = tile.y, dx = facing.dx, dy = facing.dy},
            Environment.fallCells(game.room, tile.x, tile.y, facing.dx, facing.dy), true)
    end
    for _, e in ipairs(game:entities()) do
        if e.enemy and (e.enemy.state == 'warn' or e.enemy.state == 'dash') then
            for _, cell in ipairs(e.enemy.cells) do
                if cell.impact then
                    local x, y = (cell.x - 1) * 32, (cell.y - 1) * 32
                    border(x + 2, y - 9, 28, 36, C.red)
                    arrow(x + 16, y + 5, e.enemy.dx, e.enemy.dy, C.text, 4)
                end
            end
        end
        if e.resonator and e.resonator.state == 'primed' then
            for _, cell in ipairs(e.resonator.walls or {}) do
                local x, y = (cell.x - 1) * 32, (cell.y - 1) * 32
                border(x + 2, y - 9, 28, 36, C.gold)
                color(C.gold); pixelLine(x + 18, y - 6, x + 13, y + 3); pixelLine(x + 13, y + 3, x + 20, y + 10)
            end
        end
    end
end

function Render:telegraphs(game, overlay)
    for _, e in ipairs(game:entities()) do
        if e.resonator and e.resonator.state == 'primed' then
            for _, cell in ipairs(e.resonator.cells) do
                warningCell(cell, C.gold, 0, 0, 1 - e.resonator.timer / Environment.constants.warning, overlay, 'blast')
            end
        end
        if e.hazard then
            for _, cell in ipairs(e.hazard.cells) do
                warningCell(cell, C.gold, 0, 0, 1 - e.hazard.timer / e.hazard.duration, overlay, 'blast')
            end
        end
        local a = e.enemy
        if a and (a.state == 'warn' or a.state == 'dash' or a.state == 'volley') then
            local progress = a.state ~= 'warn' and 1 or 1 - a.timer / (a.warningDuration or 1)
            local tint = (a.mode == 'shot' or a.mode == 'dual' or a.mode == 'mark' or a.mode == 'summon') and C.gold or C.red
            for i, cell in ipairs(a.cells) do
                if a.state ~= 'dash' or i >= (a.dashIndex or 1) then
                    local dx = cell.dx or (a.mode == 'cross' and (cell.x == e.grid.x and 0 or cell.x > e.grid.x and 1 or -1)) or a.dx
                    local dy = cell.dy or (a.mode == 'cross' and (cell.y == e.grid.y and 0 or cell.y > e.grid.y and 1 or -1)) or a.dy
                    local kind = (a.mode == 'shot' or a.mode == 'dual') and 'shot' or (a.mode == 'mark' or a.mode == 'summon') and 'blast' or 'dash'
                    warningCell(cell, tint, dx, dy, progress, overlay, kind)
                    for _, f in ipairs(cell.fall or {}) do warningCell(f, C.jade, a.dx, a.dy, progress, overlay, 'fall') end
                end
            end
        end
    end
end

function Render:edgeThreats(game)
    local v = self.view
    for _, e in ipairs(game:entities()) do
        local a = e.enemy
        if a and (a.state == 'warn' or a.state == 'dash' or a.state == 'volley') then
            local x, y = Render.visualPosition(e)
            local sx, sy = x - v.left, y - v.top
            if sx < 0 or sy < 0 or sx >= v.w or sy >= v.h then
                local cx, cy = v.w / 2, v.h / 2
                local dx, dy = sx - cx, sy - cy
                local t = math.min((cx - 10) / math.max(1, math.abs(dx)), (cy - 10) / math.max(1, math.abs(dy)))
                local ix, iy = round(cx + dx * t), round(cy + dy * t)
                color(C.ink); G.rectangle('fill', ix - 6, iy - 6, 13, 13)
                border(ix - 6, iy - 6, 13, 13, C.red)
                if math.abs(dx) > math.abs(dy) then arrow(ix + (dx > 0 and 2 or -2), iy, dx > 0 and 1 or -1, 0, C.gold, 3)
                else arrow(ix, iy + (dy > 0 and 2 or -2), 0, dy > 0 and 1 or -1, C.gold, 3) end
                local progress = a.state == 'warn' and 1 - a.timer / (a.warningDuration or 1) or 1
                color(C.gold); G.rectangle('fill', ix - 5, iy + 8, round(11 * progress), 1)
            end
        end
    end
end

-- Each kind owns a silhouette; elites and bosses are shapes, not recolors.
local sprites = {}
sprites.warden = function(self, e, a, facing, recover)
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
end
sprites.dasher = function(self, e, a, facing, recover)
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
end
sprites.ranger = function(self, e, a, facing, recover)
    color({.35, .25, .40}); G.polygon('fill', -8, -10, 9, -10, 15, 12, 0, 17, -14, 12)
    color(recover and C.muted or C.gold); G.polygon('fill', -10, -6, -5, -13, 5, -13, 10, -6, 7, 4, -7, 4)
    color(C.ink); G.ellipse('fill', facing.dx * 2, -5 + facing.dy * 2, 6, 5)
    diamond(facing.dx * 3, -6 + facing.dy * 3, 3, C.gold)
    color(C.gold, .5); G.line(-7, 4, -10, 11, 0, 14, 10, 11, 7, 4)
    G.push(); G.rotate(math.atan2(facing.dy, facing.dx))
    color(C.muted); G.line(15, -11, 15, 13); diamond(15, -13, 6, C.gold)
    color(C.ink); G.circle('fill', 15, -13, 3); diamond(15, -13, 1.5, C.gold); G.pop()
end
sprites.crawler = function(self, e, a, facing, recover)
    local low = a.state == 'exposed' and 3 or 0
    color({.22, .34, .30}); G.ellipse('fill', 0, 4 + low, 15, 8)
    color({.13, .24, .22}); G.ellipse('fill', -3, 1 + low, 11, 6)
    for side = -1, 1, 2 do
        color({.30, .44, .38}); G.setLineWidth(2)
        G.line(side * 8, 0 + low, side * 15, 6); G.line(side * 5, 6, side * 13, 11)
    end
    color({.36, .52, .44}); G.circle('fill', facing.dx * 9, -2 + facing.dy * 5 + low, 6)
    color(C.ink); G.circle('fill', facing.dx * 11 + facing.dy * 2, -3 + facing.dy * 6 + facing.dx * 0 + low, 2)
    G.circle('fill', facing.dx * 11 - facing.dy * 2, -1 + facing.dy * 6 + low, 2)
    color(C.red); G.line(facing.dx * 13 - facing.dy * 3, 2 + facing.dy * 8 + low,
        facing.dx * 16 - facing.dy * 5, 5 + facing.dy * 9 + low)
    G.line(facing.dx * 13 + facing.dy * 3, 2 + facing.dy * 8 + low,
        facing.dx * 16 + facing.dy * 5, 5 + facing.dy * 9 + low)
end
sprites.sower = function(self, e, a, facing, recover)
    color({.36, .26, .14}); G.polygon('fill', -9, -11, 9, -11, 14, 13, 0, 17, -14, 13)
    color({.55, .38, .16}); G.polygon('fill', -8, -8, -3, -14, 6, -13, 10, -7, 6, 3, -6, 3)
    color(C.ink); G.ellipse('fill', facing.dx * 2, -6 + facing.dy * 2, 5, 4)
    local pulse = a.state == 'warn' and (1 - a.timer / (a.warningDuration or 1)) or 0
    diamond(facing.dx * 14, -14 + facing.dy * 6, 4 + pulse * 2, C.gold)
    diamond(facing.dx * 14, -14 + facing.dy * 6, 2 + pulse, {1, .88, .59, .8})
    color(C.gold, .4); G.setLineWidth(1); G.line(-6, 4, -9, 11); G.line(6, 4, 9, 11)
end
sprites.watcher = function(self, e, a, facing, recover)
    color({.20, .16, .32}); G.polygon('fill', -9, 12, -7, -14, 0, -20, 7, -14, 9, 12)
    color({.30, .26, .44}); G.polygon('fill', -6, 10, -5, -11, 0, -16, 5, -11, 6, 10)
    local open = a.state == 'warn' and 1 or .45
    color(C.violet); G.ellipse('fill', 0, -6, 7, 4 * open + 1)
    color(C.ink); G.circle('fill', facing.dx * 2, -6 + facing.dy * 2, 2.5)
    color(C.white, .8); G.circle('fill', facing.dx * 2 - .5, -7 + facing.dy * 2, 1)
    for i = 0, 3 do
        local ang = i * pi / 2 + pi / 4
        diamond(math.cos(ang) * 10, -6 + math.sin(ang) * 8, 1.5, C.violet)
    end
    color(C.violet, .4); G.setLineWidth(1); G.line(-9, 12, 9, 12)
end
sprites.husk = function(self, e, a, facing, recover)
    local total = a.hatchTime or 3.5
    local pulse = math.sin(self.time * 6) * 1.5
    color({.30, .22, .12}); G.ellipse('fill', 0, 0, 11 + pulse * .4, 14 + pulse * .4)
    color({.62, .42, .16}); G.ellipse('line', 0, 0, 11, 14)
    color(C.gold); G.setLineWidth(1.5)
    G.arc('line', 'open', 0, 0, 17, -pi / 2, -pi / 2 + math.max(.02, 1 - a.timer / total) * 2 * pi)
    color(C.gold, .5); G.line(-5, -8, -2, 2); G.line(4, -10, 6, -3)
end
sprites.breaker = function(self, e, a, facing, recover)
    sprites.dasher(self, e, a, facing, recover)
    color({.24, .18, .14}); G.polygon('fill', -14, -14, 14, -14, 16, -8, -16, -8)
    color(C.gold); G.setLineWidth(1.5)
    G.line(-10, -13, -4, -9); G.line(9, -13, 3, -9)
    diamond(0, -18, 3, C.red, 'line')
end
sprites.veteran = function(self, e, a, facing, recover)
    sprites.ranger(self, e, a, facing, recover)
    color(C.violet); G.polygon('fill', -10, -6, -5, -13, -1, -11, -6, -3)
    G.push(); G.rotate(math.atan2(facing.dy, facing.dx))
    color(C.violet); G.line(-15, -11, -15, 13); diamond(-15, -13, 5, C.violet)
    G.pop()
end
sprites.demolisher = function(self, e, a, facing, recover)
    color(a.phase2 and {.32, .14, .10} or {.22, .18, .16})
    G.polygon('fill', -15, -13, 15, -13, 19, 14, 0, 20, -19, 14)
    color({.34, .27, .22}); G.polygon('fill', -13, -15, -6, -24, 6, -24, 13, -15, 9, -3, -9, -3)
    color({.42, .34, .26}); G.rectangle('fill', -18, -6, 6, 14, 1); G.rectangle('fill', 12, -6, 6, 14, 1)
    color(C.ink); G.rectangle('fill', -8, -14, 16, 5, 1)
    color(a.phase2 and C.red or C.gold); G.rectangle('fill', -6 + facing.dx * 2, -13 + facing.dy * 2, 12, 2)
    color(C.gold, .55); G.setLineWidth(1)
    G.line(-11, 0, -5, 6); G.line(11, 0, 5, 6); G.line(-3, -22, 0, -27); G.line(3, -22, 0, -27)
end
sprites.regent = function(self, e, a, facing, recover)
    color(a.phase2 and {.40, .20, .10} or {.30, .22, .14})
    G.polygon('fill', -11, -12, 11, -12, 16, 14, 0, 19, -16, 14)
    color({.48, .34, .16}); G.polygon('fill', -9, -9, -4, -17, 4, -17, 9, -9, 6, 2, -6, 2)
    color(C.gold); G.polygon('fill', -10, -15, -12, -26, -6, -21, 0, -28, 6, -21, 12, -26, 10, -15)
    color(C.ink); G.ellipse('fill', facing.dx * 2, -8 + facing.dy * 2, 6, 4)
    for i = 0, 2 do
        local ang = self.time * 1.4 + i * (pi * 2 / 3)
        diamond(math.cos(ang) * 15, -4 + math.sin(ang) * 11, 3, C.gold)
    end
    diamond(facing.dx * 13, -10 + facing.dy * 5, 2, {1, .88, .59, .7})
end

function Render:actor(e, game)
    local x, y, jump = Render.visualPosition(e)
    x, y = math.floor(x + .5), math.floor(y + .5)
    if self.reducedMotion then jump = 0 end
    if PixelWorld.object(self, e, game, x, y) then return end
    if self.actors and self.actors:draw(self, e, game, x, y, jump) then return end
    -- Existing cast remains rasterized on the same surface until stage 4.
    if not e.enemy then return end
    color(C.ink, .65); G.rectangle('fill', x - 9, y - 2, 18, 5)
    local facing = e.facing
    G.push(); G.translate(x, math.floor(y - jump + .5)); G.scale(.8)
        local a = e.enemy
        local recover = a.state == 'recover'
        (sprites[a.kind] or sprites.ranger)(self, e, a, facing, recover)
        if a.frontalArmor then
            G.push(); G.rotate(math.atan2(facing.dy, facing.dx))
            color({.19, .23, .29}); G.polygon('fill', 13, -13, 19, -8, 21, 0, 19, 8, 13, 13, 9, 8, 9, -8)
            color(C.muted); G.setLineWidth(2); G.line(13, -13, 19, -8, 21, 0, 19, 8, 13, 13)
            color(C.gold); G.line(13, -5, 16, -3, 17, 0, 16, 3, 13, 5)
            G.pop()
        end
        local hp = e.health
        local barTints = {ranger = C.gold, sower = C.gold, watcher = C.violet,
            veteran = C.violet, warden = C.violet, regent = C.gold}
        color(C.ink); G.rectangle('fill', -14, -25, 28, 4, 1)
        color(barTints[a.kind] or C.red); G.rectangle('fill', -13, -24, 26 * hp.current / hp.max, 2, 1)
        if a.state == 'stunned' or a.state == 'exposed' then
            diamond(-6, -35, 2, C.violet); diamond(5, -33, 2, C.violet)
        elseif a.state == 'warn' then
            text(self.fonts.small, '!', -4, -43, C.white)
        elseif a.state == 'volley' or (a.mode == 'summon' and a.state ~= 'idle') then
            diamond(0, -37, 3, C.gold)
        elseif recover then
            color(C.muted, .65); G.circle('line', -4, -33, 1); G.circle('line', 1, -33, 1); G.circle('line', 6, -33, 1)
        end
    G.pop()
end

function Render:projectile(e)
    local p, a = e.grid, e.projectile
    local progress = math.min(1, a.clock / a.interval)
    local x, y = round((p.x - .5 + a.dx * progress) * 32), round((p.y - .5 + a.dy * progress) * 32)
    local tint = a.kind == 'bolt' and C.red or C.gold
    color(tint, .35); pixelLine(x - a.dx * 20, y - a.dy * 20, x - a.dx * 7, y - a.dy * 7)
    color(tint); pixelLine(x - a.dx * 11, y - a.dy * 11, x + a.dx * 7, y + a.dy * 7)
    arrow(x + a.dx * 9, y + a.dy * 9, a.dx, a.dy, C.text, 3)
end

function Render:effects()
    -- Feedback stores legacy world units; convert its presentation only.
    for _, p in ipairs(self.feedback.rings) do
        local life = p.life / p.max
        local r = round(p.radius * .8 * (1 - life * life))
        border(round(p.x * .8) - r, round(p.y * .8) - r, r * 2 + 1, r * 2 + 1, p.color, life * .7)
    end
    for _, p in ipairs(self.feedback.particles) do
        local life = math.min(1, p.life / .3)
        color(p.color, life)
        local x, y, size = round(p.x * .8), round(p.y * .8), math.max(1, round(p.size * life * .8))
        if p.material == 'metal' then
            pixelLine(x, y, x - (p.vx > 0 and 3 or -3), y - (p.vy > 0 and 1 or -1))
        elseif p.material == 'crystal' then
            pixelLine(x - size, y, x, y - size); pixelLine(x, y - size, x + size, y)
            pixelLine(x + size, y, x, y + size); pixelLine(x, y + size, x - size, y)
        else
            G.rectangle('fill', x, y, size + (p.material == 'stone' and 1 or 0), size)
            if p.material == 'stone' then color(C.muted, life * .5); G.rectangle('fill', x, y, size, 1) end
        end
    end
    for _, p in ipairs(self.feedback.popups) do
        local font = self.worldFonts.tiny
        local width = font:getWidth(p.text)
        text(font, p.text, round(p.x * .8 - width / 2), round(p.y * .8), p.color)
    end
end

-- A flat engraved slab on the floor, never readable as a mineable piece.
function Render:inscription(mark)
    if not mark.x or not mark.y then return end
    local P = PixelWorld.palette
    local px, py = (mark.x - 1) * 32, (mark.y - 1) * 32
    color(P.ink, .55); G.rectangle('fill', px + 8, py + 11, 19, 14)
    color(P.stoneDark); G.rectangle('fill', px + 7, py + 9, 18, 14)
    color(P.stone); G.rectangle('fill', px + 8, py + 10, 16, 11)
    color(P.stoneLight); G.rectangle('fill', px + 8, py + 10, 16, 1)
    color(P.ink, .45); G.rectangle('fill', px + 8, py + 20, 16, 1)
    -- Angular rune over carved text strokes; already-read slabs lose their jade.
    local tint = mark.read and P.jadeDark or P.jade
    pixelLine(px + 11, py + 15, px + 15, py + 12, tint)
    pixelLine(px + 15, py + 12, px + 20, py + 15, tint)
    pixelLine(px + 15, py + 12, px + 15, py + 17, tint)
    color(P.joint)
    G.rectangle('fill', px + 11, py + 19, 4, 1); G.rectangle('fill', px + 17, py + 19, 4, 1)
    local glow = Render.secretHint(self.time, self.reducedMotion)
    if glow > 0 then
        pixelLine(px + 11, py + 15, px + 15, py + 12, P.jadeLight, glow * 2)
        pixelLine(px + 15, py + 12, px + 20, py + 15, P.jadeLight, glow * 2)
        color(P.white, glow); G.rectangle('fill', px + 15, py + 11, 1, 1)
    end
end

local function interactPrompt(font, x, y, label)
    local fw = font:getWidth(label)
    local bx = round(x - fw / 2 - 3)
    color(C.ink, .9); G.rectangle('fill', bx, y - 54, fw + 6, 11)
    border(bx, y - 54, fw + 6, 11, C.gold)
    text(font, label, bx + 3, y - 52, C.gold)
end

function Render:world(game)
    self:floor(game)
    for _, mark in ipairs(game.room.inscriptions or {}) do self:inscription(mark) end
    self:telegraphs(game)
    local layers = {}
    for _, tile in pairs(game.room.tiles) do
        if tile.piece and tile.piece ~= 'portal' then
            layers[#layers + 1] = {tile = tile, depth = tile.y * 32, x = tile.x * 32}
        end
    end
    for _, e in ipairs(game:entities()) do
        if e.projectile or e.player or e.health and e.health.current > 0 then
            local x, y = Render.visualPosition(e)
            layers[#layers + 1] = {entity = e, depth = y, x = x}
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
    if self.actors then self.actors:drawDeaths(self, game) end
    self:effects()
    self:telegraphs(game, true)
    self:terrainWarnings(game)
    if game.state == 'playing' and not game.dialogue and not game.reward then
        local p = game.player.grid
        local npcNear = false
        for _, e in ipairs(game:entities()) do
            if e.npc and math.abs(e.grid.x - p.x) + math.abs(e.grid.y - p.y) == 1 then
                npcNear = true
                interactPrompt(self.worldFonts.tiny, (e.grid.x - .5) * 32, (e.grid.y - .5) * 32, 'E · FALAR')
            end
        end
        if not npcNear then
            local prompted = false
            for _, mark in ipairs(game.room.inscriptions or {}) do
                if mark.x and mark.y and math.abs(mark.x - p.x) + math.abs(mark.y - p.y) == 1 then
                    interactPrompt(self.worldFonts.tiny, (mark.x - .5) * 32, (mark.y - .5) * 32, 'E · LER')
                    prompted = true
                    break
                end
            end
            if not prompted then
                for _, door in ipairs(game.room.doors or {}) do
                    if door.sealed and not door.unsealed
                        and math.abs(door.x - p.x) + math.abs(door.y - p.y) == 1 then
                        interactPrompt(self.worldFonts.tiny, (door.x - .5) * 32, (door.y - .5) * 32, 'E · SELO')
                        break
                    end
                end
            end
        end
    end
end

function Render:minimap(game, x, y, width, height)
    local visible, minX, maxX, minY, maxY = {}, math.huge, -math.huge, math.huge, -math.huge
    for _, room in ipairs(game.rooms) do
        if game:mapVisible(room) then
            visible[#visible+1] = room
            minX, maxX = math.min(minX, room.mapX), math.max(maxX, room.mapX)
            minY, maxY = math.min(minY, room.mapY), math.max(maxY, room.mapY)
        end
    end
    if #visible == 0 then return end
    local step = math.max(1, math.floor(math.min(12, (width-8)/(maxX-minX+1), (height-8)/(maxY-minY+1))))
    local ox, oy = round(x+width/2-(minX+maxX)*step/2), round(y+height/2-(minY+maxY)*step/2)
    for _, room in ipairs(visible) do
        for _, door in ipairs(room.doors) do
            local other = game.rooms[door.to]
            if other and room.id < other.id and game:mapVisible(other) and (not door.hidden or door.revealed) then
                color(C.line); pixelLine(ox+room.mapX*step,oy+room.mapY*step,ox+other.mapX*step,oy+other.mapY*step)
            end
        end
    end
    local icons = {treasure='T',shop='$',refuge='+',secret='?',supersecret='?'}
    local rw, rh = math.max(2,step-3), math.max(2,step-4)
    for _, room in ipairs(visible) do
        local rx, ry = ox+room.mapX*step, oy+room.mapY*step
        local current = game.roomId == room.id
        local tint = current and C.jade or room.visited and C.gold or C.muted
        if not room.visited and (room.kind=='secret' or room.kind=='supersecret') then tint=C.violet end
        local lx, ly = rx-math.floor(rw/2), ry-math.floor(rh/2)
        color(C.ink); G.rectangle('fill',lx,ly,rw,rh)
        if current then color(tint); G.rectangle('fill',lx,ly,rw,rh) else border(lx,ly,rw,rh,tint) end
        local icon = room.kind=='boss' and room.visited and 'B' or icons[room.kind]
        if icon and step>=10 then text(self.fonts.tiny,icon,rx-3,ry-5,current and C.ink or tint)
        elseif icon then color(tint); G.rectangle('fill',rx,ry,1,1) end
    end
end
function Render:hud(game, width, height)
    local e, f = game.player, self.hudFont
    local hp, guard = e.health, e.guard
    G.push(); G.scale(2)
    local w, h = math.floor(width / 2), math.floor(height / 2)
    local function box(x, y, bw, bh, accent)
        color(C.ink, .97); G.rectangle('fill', x, y, bw, bh)
        border(x, y, bw, bh, accent or C.line)
        color(C.gold, .7); G.rectangle('fill', x + 2, y + 2, 2, 2)
    end
    box(8, 8, 154, 39)
    text(f, 'VIDA', 14, 10, C.muted)
    text(f, math.ceil(hp.current) .. '/' .. hp.max, 104, 10, hp.current <= 3 and C.red or C.text, 50, 'right')
    for i=1,hp.max do
        local x, y = 15 + (i-1)*14, 23
        local tint = i <= hp.current and (hp.current <= 3 and C.red or C.jade) or C.line
        color(tint); G.rectangle('fill', x, y, 9, 5); G.rectangle('fill', x+2, y-1, 5, 7)
        if i<=hp.current then color(C.text, .4); G.rectangle('fill', x+1, y, 3, 1) end
    end
    text(f, 'ESCUDO', 14, 33, guard.exhausted and C.red or C.muted)
    color(C.line); G.rectangle('fill', 60, 37, 95, 4)
    color(guard.exhausted and C.red or C.jade); G.rectangle('fill', 60, 37, round(95 * guard.energy / guard.max), 4)
    if (self.resourceTime or 0) > 0 or game.pickaxes == 0 then
        text(f, 'PICARETAS ' .. game.pickaxes .. '  OURO ' .. game.gold ..
            '  NV ' .. game.level .. ' · XP ' .. game.xp .. '/' .. (Progression.xpLimit(game) or 'MAX'), 14, 47, C.gold)
    end
    local mapHeight = Render.mapHeight(game)
    box(w-110, 8, 102, mapHeight)
    text(f, game.practice and 'CÂMARA' or 'MAPA / ANDAR ' .. game.floorNumber, w-104, 10, C.muted)
    local oldFont = self.fonts.tiny
    self.fonts.tiny = f
    self:minimap(game, w-106, 22, 94, mapHeight-19)
    self.fonts.tiny = oldFont
    if (self.roomTime or 0) > 0 then
        text(f, game.room.name, 167, 10, C.gold, w-284, 'center')
    end
    local message = game.messageTime > 0 and game.message or self.feedback.banner > .1 and 'SALA DOMINADA' or nil
    if message and not game.reward then
        local _, lines = f:getWrap(message, w-24)
        text(f, message, 12, h-18-#lines*f:getHeight(), C.text, w-24, 'center')
    end
    text(f, 'WASD MOVER / MINERAR · SPACE ARCO · SHIFT ESCUDO · TAB GUIA · ESC PAUSA', 8, h-14, C.muted, w-16, 'center')
    for _, boss in ipairs(game:entities()) do
        if boss.enemy and boss.enemy.boss and boss.health.current > 0 then
            local label = (Enemies[boss.enemy.kind] or {}).label or 'CHEFE'
            text(f, label, 170, 26, C.violet, w-288, 'center')
            color(C.line); G.rectangle('fill', 172, 40, w-292, 3)
            color(C.violet); G.rectangle('fill', 172, 40, round((w-292)*boss.health.current/boss.health.max), 3)
        end
    end
    G.pop()
end

function Render:button(key, label, desc, x, y, width, accent)
    panel(x, y, width, 66, accent)
    color(accent, .14); G.rectangle('fill', x + 12, y + 14, 52, 37, 4)
    text(self.fonts.small, key, x + 12, y + 23, accent, 52, 'center')
    text(self.fonts.body, label, x + 79, y + 13, C.text)
    text(self.fonts.small, desc, x + 79, y + 38, C.muted)
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

function Render:help(game, w, h)
    color(C.ink, .94); G.rectangle('fill', 0, 0, w, h)
    local width, x, y = 920, (w - 920) / 2, h / 2 - 311
    if self.helpPage == 'cards' then
        panel(x, y, width, 622, C.gold)
        self:helpCards(game, x, y, width)
        return
    end
    panel(x, y, width, 622, C.jade)
    text(self.fonts.small, 'GUIA DO VIAJANTE', x + 32, y + 24, C.jade)
    text(self.fonts.small, 'C  CARTAS', x + width - 152, y + 24, C.muted, 120, 'right')
    text(self.fonts.large, 'Leia o tabuleiro. Faça o próximo passo.', x + 32, y + 50, C.text)
    local stats = game:weaponStats()
    text(self.fonts.tiny, 'OURO ' .. game.gold .. '   /   PICARETAS ' .. game.pickaxes ..
        '   /   NV ' .. game.level .. ' · XP ' .. game.xp .. '/' .. (Progression.xpLimit(game) or 'MAX') ..
        '   /   ARCO ' .. stats.damage .. ' DANO   /   CARGA ' .. string.format('%.2fs', stats.chargeTime / stats.chargeSpeed), x + 32, y + 84, C.gold)
    local rows = {
        {'WASD', 'Toque para virar; segure ou repita para andar', 'A direção encarada também mira o arco e o escudo e dá pancada na peça à frente.'},
        {'PICARETAS', 'Três hits abrem uma peça', 'Hits 1 e 2 ficam marcados. O terceiro gasta uma picareta, sem avançar.'},
        {'PILARES', 'Escolha o lado da última pancada', 'O preview muda com seu lado; o terceiro hit trava cinco blocos de queda.'},
        {'BURACOS', 'O salto para o vazio é fatal', 'Não é possível voltar durante a queda. O aviso de pilar também pode matar.'},
        {'SPACE', 'Segure para carregar o arco', game.upgrades.bowQuick and 'CORDA VIVA: carga 35% mais rápida. Solte SPACE quando pronta.' or 'Quando aparecer SOLTE SPACE, solte para disparar uma vez na direção da mira.'},
        {'SOLTAR', 'Escolha o momento do tiro', game.upgrades.bowPierce and 'AGULHA DO SOL: atravessa inimigos, custa -1 dano. Soltar cedo cancela.' or 'Soltar cedo cancela; manter SPACE pressionado quando pronto não dispara.'},
        {'SHIFT', 'Segure para defender de frente', game.upgrades.guardPulse and 'MARÉ DE FERRO: +1 dano no pulso frontal. Guarda cancela a carga.' or 'O bloqueio solta uma onda. Levantar escudo cancela a carga. Evite os flancos.'},
        {'1 / 2 / 3', 'Escolha uma relíquia na recompensa', 'O arco permanece equipado; números escolhem apenas cartas de recompensa.'},
        {'! / >>>', 'O aviso é uma promessa', 'Saia da investida, do tiro e da queda. Ataque o bruto pelos flancos.'},
        {'CENÁRIO', 'Abra passagem e linha de tiro', 'O cenário está sempre visível. Cristais e dash rompem peças; tiros param nelas.'},
        {'SEGREDOS', 'Combate ou três alvos com o arco', 'Brilho sutil marca entradas. Desafios dão relíquias; a saída fica sempre livre.'},
        {'NÍVEL', 'XP da tentativa: inimigos 1, elites 3, chefes 5, desafios 2',
            'Cada nível oferece um eco; se outra tela estiver aberta, a oferta espera.'},
    }
    for i, row in ipairs(rows) do
        local ry = y + 98 + (i - 1) * 38
        color(C.line, .5); G.line(x + 32, ry + 36, x + width - 32, ry + 36)
        text(self.fonts.small, row[1], x + 32, ry + 6, i == 9 and C.gold or C.jade, 120, 'center')
        text(self.fonts.body, row[2], x + 174, ry, C.text)
        text(self.fonts.small, row[3], x + 174, ry + 24, C.muted)
    end
    text(self.fonts.small, '7–8 salas iniciais + 2 segredos; cada andar acrescenta 2–3 salas. Vença o chefe para descer.', x + 32, y + 556, C.gold)
    text(self.fonts.small, 'TAB / ESC voltar    ·    C cartas    ·    F2 reduzir movimento    ·    M áudio    ·    F11 tela cheia', x + 32, y + 589, C.text)
end

-- Collected cards are legible; the rest stay as '???' in catalog order.
function Render:helpCards(game, x, y, width)
    local cards = Lore.cards or {}
    local owned = game.cards or {}
    local found = 0
    for _, card in ipairs(cards) do if owned[card.id] then found = found + 1 end end
    text(self.fonts.small, 'CARTAS DO VIAJANTE', x + 32, y + 24, C.jade)
    text(self.fonts.small, 'C  GUIA', x + width - 152, y + 24, C.muted, 120, 'right')
    text(self.fonts.large, 'CARTAS ' .. found .. '/' .. #cards, x + 32, y + 50, C.text)
    text(self.fonts.tiny, 'Bilhetes da primeira expedição e dos sacerdotes de jade, espalhados pelas Ruínas.',
        x + 32, y + 84, C.gold)
    local total = #cards
    local sel = math.max(1, math.min(self.helpCard or 1, math.max(total, 1)))
    self.helpCard = sel
    local listX, listY, listW, rowH = x + 32, y + 106, 358, 25
    local viewRows = math.floor((y + 578 - listY) / rowH)
    local scroll = math.max(0, math.min(sel - viewRows, total - viewRows))
    for row = 1, math.min(viewRows, total) do
        local i = row + scroll
        local card = cards[i]
        local has = owned[card.id] == true
        local ry = listY + (row - 1) * rowH
        if i == sel then
            color(C.jade, .13); G.rectangle('fill', listX - 8, ry - 2, listW + 16, rowH - 2, 3)
            border(listX - 8, ry - 2, listW + 16, rowH - 2, C.jade, .8)
        end
        text(self.fonts.small, string.format('%02d', i), listX, ry + 5, i == sel and C.gold or C.muted)
        text(self.fonts.small, has and card.title or '???', listX + 34, ry + 5, has and C.text or C.muted)
        if has then diamond(listX + listW - 6, ry + 11, 3, i == sel and C.gold or C.jade) end
    end
    if scroll > 0 then text(self.fonts.small, '^', listX + listW + 4, listY - 4, C.muted) end
    if scroll + viewRows < total then
        text(self.fonts.small, 'v', listX + listW + 4, listY + viewRows * rowH - 14, C.muted)
    end
    local px, py, pw, ph = x + 428, y + 100, width - 460, 478
    panel(px, py, pw, ph, C.gold)
    local card = cards[sel]
    local has = card and owned[card.id] == true
    text(self.fonts.small, 'REGISTRO ' .. string.format('%02d', sel) .. ' / ' .. total, px + 20, py + 18, C.gold)
    diamond(px + pw - 30, py + 27, 8, has and C.jade or C.line, 'line')
    diamond(px + pw - 30, py + 27, 3, has and C.jade or C.line)
    if has then
        text(self.fonts.medium, card.title, px + 20, py + 44, C.text, pw - 70)
        local cy = py + 92
        for _, line in ipairs(card.lines or {}) do
            local _, wrapped = self.fonts.body:getWrap(line, pw - 40)
            text(self.fonts.body, line, px + 20, cy, C.muted, pw - 40)
            cy = cy + math.max(1, #wrapped) * (self.fonts.body:getHeight() + 4) + 8
        end
    else
        text(self.fonts.medium, '???', px + 20, py + 44, C.line)
        text(self.fonts.body, 'Esta carta ainda não foi encontrada.\nInscrições, segredos e encontros nas Ruínas guardam os bilhetes da primeira expedição.',
            px + 20, py + 92, C.muted, pw - 40)
    end
    text(self.fonts.small, 'W/S ou SETAS escolher    ·    C guia    ·    TAB / ESC voltar', x + 32, y + 589, C.text)
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
    local worldDone = won and game.worldComplete
    local c = won and C.gold or C.red
    color(C.ink, .86); G.rectangle('fill', 0, 0, w, h)
    local x, y = w / 2 - 270, h / 2 - 210
    panel(x, y, 540, 420, c)
    diamond(w / 2, y + 54, 13, c, 'line'); diamond(w / 2, y + 54, 5, c)
    text(self.fonts.small, worldDone and 'AS RUÍNAS SILENCIAM.' or won and 'O TABULEIRO É SEU.' or 'A QUEDA DEIXA MARCAS.', x + 28, y + 89, c, 484, 'center')
    text(self.fonts.large, worldDone and 'Mundo dominado.' or won and (game.practice and 'Câmara dominada.' or 'Andar ' .. game.floorNumber .. ' dominado.') or 'Um novo passo. Outra chance.', x + 28, y + 118, C.text, 484, 'center')
    local lesson = game.deathCause == 'hole' and 'O salto para o buraco não tem volta. Escolha um piso seguro.' or
        game.deathCause == 'crushed' and 'O pilar esmaga quem fica no corredor. Saia durante o aviso.' or
        'Saia da linha durante o aviso. Ataque na recuperação.'
    local body = worldDone and 'A Regente caiu e os ecos descansam. As Ruínas dos Ecos são suas.' or
        won and 'Use o arco e o cenário para inventar outra maneira de vencer.' or lesson
    text(self.fonts.body, body, x + 35, y + 176, C.muted, 470, 'center')
    text(self.fonts.small, game.kills .. ' inimigos vencidos    ·    ' .. math.floor(game.time) .. 's de combate', x + 28, y + 222, c, 484, 'center')
    if worldDone then
        text(self.fonts.small, 'N  Nova expedição    ·    R  Recomeçar    ·    ENTER  Menu', x + 30, y + 372, C.text, 480, 'center')
    elseif won and not game.practice then
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

function Render:dialogue(game, w, h)
    local d = game.dialogue
    local width = math.min(700, w - 120)
    local rows = d.mode == 'options' and #d.node.options
        or d.mode == 'shop' and #d.shop or 1
    local boxH, x = math.max(176, 88 + rows * 30), (w - width) / 2
    local y = h - boxH - 42
    panel(x, y, width, boxH, C.gold)
    text(self.fonts.small, d.title, x + 26, y + 20, C.gold)
    color(C.line); G.setLineWidth(1); G.line(x + 26, y + 42, x + width - 26, y + 42)
    if d.mode == 'shop' then
        text(self.fonts.small, 'OURO: ' .. game.gold, x + width - 140, y + 20, C.gold)
        for i, item in ipairs(d.shop) do
            text(self.fonts.body, i .. '   ' .. item.label .. '   ·   '
                .. (item.sold and 'VENDIDO' or item.price .. ' OURO'),
                x + 26, y + 58 + (i - 1) * 30, item.sold and C.muted or C.text)
        end
        text(self.fonts.small, 'Número compra   ·   E voltar   ·   ESC fechar', x + 26, y + boxH - 26, C.muted)
    elseif d.mode == 'options' then
        for i, option in ipairs(d.node.options) do
            text(self.fonts.body, i .. '   ' .. option.label, x + 26, y + 58 + (i - 1) * 30, C.text)
        end
        text(self.fonts.small, 'Número escolhe   ·   ESC fechar', x + 26, y + boxH - 26, C.muted)
    else
        local line = d.lines[d.index]
        local len = utf8.len(line) or #line
        local shown = math.floor(math.min(len, d.reveal or len))
        local boundary = utf8.offset(line, shown + 1) or (#line + 1)
        text(self.fonts.body, line:sub(1, boundary - 1), x + 26, y + 60, C.text, width - 52)
        text(self.fonts.small, shown < len and 'E >' or 'E >>', x + width - 70, y + boxH - 26, C.muted)
    end
end

-- Campaign presentation: same canvas/camera pipeline, authored maps instead of
-- generated rooms, continuous feet positions instead of hop interpolation.
local titleFacade = {state = 'menu', room = {}, events = {},
    entities = function() return {} end, player = {grid = {x = 0, y = 0}}}

function Render:updateCampaign(dt, campaign, screen)
    self.time = self.time + dt
    if not campaign then
        self.feedback.muted, self.feedback.reducedMotion = self.muted, self.reducedMotion
        self.feedback:update(dt, titleFacade, screen)
        return
    end
    self.actors:update(dt, campaign, screen == 'campaign' and 'playing' or screen, self.reducedMotion)
    self.feedback.muted, self.feedback.reducedMotion = self.muted, self.reducedMotion
    self.feedback:update(dt, campaign, screen)
    if self.room ~= campaign.room then self.room, self.roomTime = campaign.room, 2.5 end
    if screen == 'campaign' then self.roomTime = math.max(0, (self.roomTime or 0) - dt) end
    self:updateDialogueReveal(dt, campaign.dialogue)
    local map = campaign.scene == 'battle' and campaign.battle.room or campaign.room
    local x, y = Render.visualPosition(campaign.player)
    self.view = Render.layout(G.getWidth(), G.getHeight(), map, x, y, 76)
end

function Render:worldCampaign(campaign)
    local map = campaign.room
    self:floor(campaign)
    local layers = {}
    for _, tile in pairs(map.tiles) do
        if tile.piece and tile.piece ~= 'portal' then
            layers[#layers + 1] = {tile = tile, depth = tile.y * 32, x = tile.x * 32}
        end
    end
    for _, prop in ipairs(map.props) do
        if prop.state ~= 'taken' then
            layers[#layers + 1] = {prop = prop, depth = (prop.y + (prop.h or 1) - 1) * 32, x = prop.x * 32}
        end
    end
    for _, e in ipairs(campaign:entities()) do
        local x, y = Render.visualPosition(e)
        layers[#layers + 1] = {entity = e, depth = y, x = x}
    end
    table.sort(layers, function(a, b)
        if a.depth ~= b.depth then return a.depth < b.depth end
        return (a.x or 0) < (b.x or 0)
    end)
    for _, layer in ipairs(layers) do
        if layer.tile then self:wall(map, layer.tile)
        elseif layer.prop then
            for dy = 0, (layer.prop.h or 1) - 1 do
                for dx = 0, (layer.prop.w or 1) - 1 do
                    Props.draw(layer.prop, (layer.prop.x + dx - 1) * 32, (layer.prop.y + dy - 1) * 32)
                end
            end
        else self:actor(layer.entity, campaign) end
    end
    self:effects()
    if campaign.state == 'playing' and not campaign.dialogue and campaign.scene == 'explore' then
        local npc = campaign:nearNpc()
        if npc then
            interactPrompt(self.worldFonts.tiny, (npc.grid.x - .5) * 32, (npc.grid.y - .5) * 32, 'E · FALAR')
        else
            local spot = campaign:nearHotspot()
            if spot then
                interactPrompt(self.worldFonts.tiny, (spot.x - .5) * 32, (spot.y - .5) * 32, 'E · ' .. spot.label)
            end
        end
    end
end

function Render:worldArena(campaign)
    local battle = campaign.battle
    self:floor({room = battle.room, seed = campaign.seed})
    for _, tile in pairs(battle.room.tiles) do
        if tile.piece and tile.piece ~= 'portal' then self:wall(battle.room, tile) end
    end
    for _, e in ipairs(battle.enemies or {}) do self:actor(e, campaign) end
    self:actor(battle.player, campaign)
    local x, y = Render.visualPosition(battle.player)
    text(self.worldFonts.body, 'ARENA EM CONSTRUÇÃO', x - self.worldFonts.body:getWidth('ARENA EM CONSTRUÇÃO') / 2,
        (battle.room.h) * 32 - 24, C.gold)
end

function Render:campaignHud(campaign, w, h)
    G.push(); G.scale(2)
    local hw = math.floor(w / 2)
    local function box(x, y, bw, bh, accent)
        color(C.ink, .97); G.rectangle('fill', x, y, bw, bh)
        border(x, y, bw, bh, accent or C.line)
        color(C.gold, .7); G.rectangle('fill', x + 2, y + 2, 2, 2)
    end
    box(8, 8, 150, 30)
    text(self.hudFont, campaign.room.name, 14, 11, C.jade)
    text(self.hudFont, campaign.scene == 'battle' and 'ENCONTRO' or 'EXPLORAÇÃO', 14, 25, C.muted)
    if campaign.messageTime > 0 then
        text(self.hudFont, campaign.message, 12, hw - 16, C.text, hw - 24, 'center')
    end
    text(self.hudFont, 'WASD ANDAR · E INTERAGIR · ESC PAUSA', 8, hw - 4, C.muted, hw - 16, 'center')
    G.pop()
end

function Render:campaignTitle(hasSave, w, h)
    color(C.ink, .85); G.rectangle('fill', 0, 0, w, h)
    local left = math.max(58, (w - 1120) / 2)
    local top = h / 2 - 243
    text(self.fonts.small, 'A CIDADE QUE TE GUARDOU.', left + 4, top, C.jade)
    text(self.fonts.title, 'ARROW', left, top + 25, C.text)
    text(self.fonts.title, 'FALLEN', left, top + 85, C.gold)
    color(C.gold); G.rectangle('fill', left + 4, top + 173, 59, 2)
    text(self.fonts.body, 'Você saiu da própria sepultura.', left + 4, top + 193, C.muted)
    text(self.fonts.body, 'A cidade que o enterrou ainda está de pé.', left + 4, top + 219, C.muted)
    if hasSave then
        self:button('ENTER', 'Continuar', 'Volte à campanha de onde parou', left, top + 264, 490, C.jade)
        self:button('N', 'Nova campanha', 'Recomeça do zero — apaga o save', left, top + 342, 490, C.gold)
    else
        self:button('ENTER', 'Nova campanha', 'A Cidade Que Me Enterrou', left, top + 264, 490, C.jade)
    end
    text(self.fonts.small, 'TAB  Como jogar', left + 4, top + 433, C.text)
    self:emblem(w - math.max(230, (w - 1000) / 2), h / 2 - 7, math.min(1.20, w / 1050))
    for i, line in ipairs({'DEZ REGIÕES.', 'DOIS FINAIS.', 'A CIDADE QUE ME ENTERROU.'}) do
        text(self.fonts.small, line, w - 382, h / 2 + 185 + (i - 1) * 16, C.muted, 305, 'center')
    end
    text(self.fonts.tiny, 'WASD andar    /    E interagir    /    ESC pausar', 40, h - 36, C.muted, w - 80, 'center')
end

function Render:campaignPause(w, h)
    color(C.ink, .82); G.rectangle('fill', 0, 0, w, h)
    local x, y = w / 2 - 246, h / 2 - 206
    panel(x, y, 492, 412, C.jade)
    text(self.fonts.small, 'A CIDADE ESPERA.', x + 28, y + 29, C.jade)
    text(self.fonts.large, 'Pausa.', x + 28, y + 61, C.text)
    self:button('ESC', 'Continuar', 'Volte exatamente onde parou', x + 26, y + 123, 440, C.jade)
    self:button('TAB', 'Guia da viagem', 'Controles e o que a campanha guarda', x + 26, y + 203, 440, C.gold)
    text(self.fonts.body, 'Q  Salvar e voltar ao título', x + 28, y + 295, C.text)
    text(self.fonts.small, 'O progresso é gravado a cada passagem e cada decisão.', x + 28, y + 338, C.muted)
end

function Render:campaignHelp(w, h)
    color(C.ink, .94); G.rectangle('fill', 0, 0, w, h)
    local width, x, y = 920, (w - 920) / 2, h / 2 - 280
    panel(x, y, width, 560, C.jade)
    text(self.fonts.small, 'GUIA DA CAMPANHA', x + 32, y + 24, C.jade)
    text(self.fonts.large, 'A Cidade Que Me Enterrou', x + 32, y + 50, C.text)
    local rows = {
        {'WASD', 'Andar livre', 'O mundo é contínuo: atravesse a colina e o refúgio a pé.'},
        {'E', 'Interagir', 'Fale com moradores, leia marcas, pegue o que era seu.'},
        {'PASSAGENS', 'As portas do fundo', 'No refúgio, a casa das passagens liga as dez regiões.'},
        {'ENCONTROS', 'Criaturas visíveis viram duelos', 'O combate acontece numa arena própria, por turnos — em construção nesta etapa.'},
        {'MORTE', 'Você volta para a cova', 'Nada se desfaz: mapas, decisões e itens permanecem.'},
        {'SAVE', 'Automático', 'Cada travessia e cada decisão grave grava a campanha em disco.'},
    }
    for i, row in ipairs(rows) do
        local ry = y + 96 + (i - 1) * 64
        color(C.line, .5); G.line(x + 32, ry + 52, x + width - 32, ry + 52)
        text(self.fonts.small, row[1], x + 32, ry + 6, i == 4 and C.gold or C.jade, 150, 'center')
        text(self.fonts.body, row[2], x + 200, ry, C.text)
        text(self.fonts.small, row[3], x + 200, ry + 30, C.muted)
    end
    text(self.fonts.small, 'TAB / ESC voltar    ·    F2 reduzir movimento    ·    M áudio', x + 32, y + 522, C.text)
end

function Render:drawCampaign(campaign, screen, hasSave)
    G.push('all')
    G.clear(C.ink)
    local w, h = G.getDimensions()
    if campaign and screen ~= 'title' then
        local map = campaign.scene == 'battle' and campaign.battle.room or campaign.room
        local actor = campaign.scene == 'battle' and campaign.battle.player or campaign.player
        local feetX, feetY = Render.visualPosition(actor)
        local v = Render.layout(w, h, map, feetX, feetY, 76)
        self.view = v
        if not self.canvas or self.canvas:getWidth() ~= v.w or self.canvas:getHeight() ~= v.h then
            if self.canvas then self.canvas:release() end
            self.canvas = G.newCanvas(v.w, v.h, {dpiscale = 1})
            self.canvas:setFilter('nearest', 'nearest')
        end
        G.push('all')
        G.setCanvas(self.canvas); G.clear(C.ink); G.setLineStyle('rough')
        G.translate(-v.left, -v.top)
        if campaign.scene == 'battle' then self:worldArena(campaign)
        else self:worldCampaign(campaign) end
        G.pop()
        color(C.white); G.draw(self.canvas, v.x, v.y, 0, v.scale, v.scale)
        self:campaignHud(campaign, w, h)
    end
    local scale = math.min(w / 1120, h / 720)
    G.scale(scale); w, h = w / scale, h / scale
    if screen == 'title' then self:campaignTitle(hasSave, w, h)
    elseif screen == 'help' then self:campaignHelp(w, h)
    elseif screen == 'paused' then self:campaignPause(w, h) end
    if campaign and campaign.dialogue and screen ~= 'title' then self:dialogue(campaign, w, h) end
    G.pop()
end

function Render:draw(game, screen)
    G.push('all')
    G.clear(C.ink)
    local w, h = G.getDimensions()
    local feetX, feetY = Render.visualPosition(game.player)
    local v = Render.layout(w, h, game.room, feetX, feetY, math.max(112,Render.mapHeight(game)*2+24))
    self.view = v
    if not self.canvas or self.canvas:getWidth() ~= v.w or self.canvas:getHeight() ~= v.h then
        if self.canvas then self.canvas:release() end
        self.canvas = G.newCanvas(v.w, v.h, {dpiscale = 1})
        self.canvas:setFilter('nearest', 'nearest')
    end
    local trauma = self.reducedMotion and 0 or self.feedback.trauma^2
    local shakeX, shakeY = round(math.sin(self.time * 51) * trauma * 4), round(math.sin(self.time * 67) * trauma * 3)
    G.push('all')
    G.setCanvas(self.canvas); G.clear(C.ink); G.setLineStyle('rough')
    G.translate(-v.left + shakeX, -v.top + shakeY)
    self:world(game)
    G.pop()
    color(C.white); G.draw(self.canvas, v.x, v.y, 0, v.scale, v.scale)
    if self.feedback.flash > 0 and not self.reducedMotion then color(C.red, self.feedback.flash * .8); G.rectangle('fill', 0, 0, w, h) end
    if screen ~= 'title' and screen ~= 'help' then
        self:hud(game, w, h)
        G.push('all'); G.translate(v.x,v.y); G.scale(v.scale); self:edgeThreats(game); G.pop()
    end
    local scale = math.min(w / 1120, h / 720)
    G.scale(scale); w, h = w / scale, h / scale
    if screen == 'title' then self:title(game, w, h)
    elseif screen == 'help' then self:help(game, w, h)
    elseif screen == 'paused' then self:pause(w, h)
    elseif game.state == 'dead' or game.state == 'won' then self:ending(game, w, h)
    elseif game.reward then self:reward(game, w, h) end
    if game.dialogue and screen ~= 'title' then self:dialogue(game, w, h) end
    G.pop()
end

return Render
