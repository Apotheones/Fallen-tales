local PixelWorld = require('src.pixel_world')
local PixelArt = require('src.pixel_art_v2')
local PixelScene = require('src.pixel_scene')
local Pal = require('src.palettes')
local PixelActors = require('src.pixel_actors')
local PixelFont = require('src.pixel_font')
local Feedback = require('src.feedback')
local Rooms = require('src.rooms')
local Props = require('src.props')
local HDWorld = require('src.hd_world')
local HDKit = require('src.hd_kit')
local Environment = require('src.environment')
local Enemies = require('src.enemies')
local Progression = require('src.progression')
local Lore = require('src.lore')
local LoreC = require('src.campaign_lore')
local utf8 = require('utf8')
-- Call site do Tímpano: src/sfx.lua resolve a voz do falante (pitch real).
-- Enquanto o módulo não entrega, stub silencioso com a tabela da Lore.
local Sfx = (function()
    local ok, m = pcall(require, 'src.sfx')
    if ok and m and m.voice then return m end
    return {voice = function(v) return (Lore.voices or {})[v] or 1 end}
end)()
local Items = require('src.items')
local Render = {}; Render.__index = Render
-- Resolução HD (MEGAPLAN_VISUAL_HD §3.1): célula artística 64px, frame de
-- ator 64×96 com âncora nos pés, zoom preferido 1× nativo. A grade lógica
-- da simulação não muda — a conversão é só de apresentação. O legado ainda
-- desenha a CELL=32; cenas no pipeline novo passam opts.cell=CELL_HD.
Render.CELL = 32
Render.CELL_HD = 64
Render.ACTOR_W = 64
Render.ACTOR_H = 96
-- Larguras de janela suportadas: 900 (mínimo), 1120 (default), 1920.
Render.WINDOW_WIDTHS = {900, 1120, 1920}
local G = love.graphics
local pi = math.pi
-- Acentos de UI alinhados à rampa mais clara da paleta do mundo: o ouro da
-- interface é o ouro-luz do mundo, o jade é o jade-luz — nada inventa uma
-- cor que o cenário não conhece.
local C = {
    ink = {.033, .046, .071}, panel = {.055, .075, .106}, line = {.19, .26, .31},
    text = {.90, .92, .89}, muted = {.51, .62, .66}, jade = Pal.jade.light,
    gold = Pal.gold.light, red = Pal.danger, violet = {.690, .529, .878}, white = {1, 1, 1},
    blue = {.35, .62, 1}
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
        -- A battle step in flight interpolates toward the reserved cell; the
        -- logical grid still reads the origin until the hop lands.
        local gx, gy = p.x, p.y
        if entity.step then gx, gy = entity.step.x, entity.step.y end
        local t = 1 - m.remaining / m.duration
        local ease = t * t * (3 - 2 * t)
        return ((m.fromX + (gx - m.fromX) * ease) - .5) * 32,
            ((m.fromY + (gy - m.fromY) * ease) - .5) * 32, math.sin(t * pi) * 7 - (m.falling and t^3 * 22 or 0)
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
-- `topPanel` reserva faixa de tela acima do canvas (em unidades de mundo)
-- para painéis presos à vista, como o palco do inimigo da arena.
-- `opts` (Fase 0 HD): {cell = 64, scale = 1} — célula artística e zoom
-- preferido do pipeline novo; omitido, o comportamento legado (32px, 2×)
-- permanece bit a bit igual.
function Render.layout(width, height, room, feetX, feetY, header, topPanel, opts)
    header = header or 112
    local cell = opts and opts.cell or 32
    local scale = math.max(1, math.min(opts and opts.scale or 2,
        math.floor(width / 256), math.floor(height / 192)))
    header = header + (topPanel or 0) * scale
    local w, h = math.max(1, math.floor((width - 24) / scale)), math.max(1, math.floor((height - header - 80) / scale))
    local rw, rh = room.w * cell, room.h * cell
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
    if d.revealIndex ~= d.index then
        d.revealIndex, d.reveal, d.voiceChars, d.voiceN = d.index, 0, 0, 0
    end
    local line = d.lines[d.index]
    local target = utf8.len(line) or #line
    d.reveal = self.reducedMotion and target or math.min(target, (d.reveal or 0) + dt * 55)
    local shown = math.floor(math.min(d.reveal, target))
    local unheard = shown - (d.voiceChars or 0)
    if unheard > 0 then
        -- Voz via src/sfx (Tímpano); fadiga reduzida: um blip a cada
        -- segundo char não-espaço, vol .22, jitter de pitch preservado.
        local pitch = Sfx.voice(d.voice)
        if unheard > 4 or self.reducedMotion then
            self.feedback:play('voice', pitch, .22)
        else
            for i = d.voiceChars + 1, shown do
                local a, b = utf8.offset(line, i), utf8.offset(line, i + 1)
                local ch = a and line:sub(a, (b or #line + 1) - 1) or ''
                if not ch:match('^%s$') then
                    d.voiceN = (d.voiceN or 0) + 1
                    if d.voiceN % 2 == 0 then
                        self.feedback:play('voice', pitch * (0.92 + love.math.random() * .16), .22)
                    end
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
function Render:wall(room, tile, pal) PixelWorld.wall(self, room, tile, pal) end

function Render:walls(game)
    for y = 1, game.room.h do for x = 1, game.room.w do
        local tile = Rooms.cell(game.room, x, y)
        if tile and tile.piece and tile.piece ~= 'portal' then self:wall(game.room, tile) end
    end end
end
-- Forward: o chevron mora na seção de overlays de turno (mais abaixo), mas
-- as formas novas do warningCell (prensa) já o consomem.
local chevron
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
    elseif kind == 'hammer' then
        -- Queda de martelo (Janda): a célula de impacto carrega o golpe —
        -- cabeça do martelo descendo, cabo e três marcas de choque abrindo
        -- em leque para baixo. Forma de peso, nunca chevron de lane.
        color(tint)
        G.rectangle('fill', x + 9, y + 5, 14, 7)
        G.rectangle('fill', x + 14, y + 12, 4, 7)
        color(C.ink, .6); G.rectangle('fill', x + 9, y + 10, 14, 1)
        for i = 0, 2 do
            pixelLine(x + 6 + i * 8, y + 26, x + 9 + i * 8, y + 22)
            pixelLine(x + 9 + i * 8, y + 22, x + 12 + i * 8, y + 26)
        end
    elseif kind == 'push' then
        -- Deslize da vara (Rute): a célula-destino lê o caixote que chega —
        -- quadrado miúdo, riscos de arrasto contra o rumo e a ponta do
        -- empurrão à frente. Controle posicional, não ferida.
        color(tint)
        G.rectangle('fill', x + 12 - dx * 2, y + 12 - dy * 2, 8, 8)
        color(C.ink, .5); G.rectangle('fill', x + 12 - dx * 2, y + 12 - dy * 2, 8, 1)
        for i = 0, 2 do
            local lx = x + 16 - dx * (9 + i * 3) - dy * 5
            local ly = y + 16 - dy * (9 + i * 3) + dx * 5
            pixelLine(lx, ly, lx + dy * 10, ly - dx * 10)
        end
        arrow(x + 16 + dx * 8, y + 16 + dy * 8, dx, dy, tint, 4)
    elseif kind == 'jet' then
        -- Jato do canal (Ivo): a banda inteira é o golpe — ondas paralelas
        -- correndo ao longo da faixa, sem ponta nem direção: perigo de área.
        color(tint)
        for j = -1, 1, 2 do
            for i = 0, 3 do
                if dx ~= 0 then
                    local ox, yy = x + 4 + i * 7, y + 16 + j * 6
                    pixelLine(ox, yy + 1, ox + 3, yy - 1)
                    pixelLine(ox + 3, yy - 1, ox + 7, yy + 1)
                else
                    local xx, oy = x + 16 + j * 6, y + 4 + i * 7
                    pixelLine(xx + 1, oy, xx - 1, oy + 3)
                    pixelLine(xx - 1, oy + 3, xx + 1, oy + 7)
                end
            end
        end
    elseif kind == 'shove' then
        -- Prensa do bastão (Beltran): a mesma lane da investida, mas com
        -- chevrons DUPLOS marchando juntos — o deslize forçado lê-se
        -- diferente do golpe direto.
        chevron(x + 16 + dx * 3, y + 16 + dy * 3, dx, dy, tint)
        chevron(x + 16 - dx * 4, y + 16 - dy * 4, dx, dy, C.text)
    else
        if kind == 'shot' then pixelLine(x + 16 - dx * 12, y + 16 - dy * 12, x + 16 + dx * 12, y + 16 + dy * 12) end
        arrow(x + 16 + dx * 4, y + 16 + dy * 4, dx, dy, tint, 5)
    end
end

-- Tinta do aviso por modo (COMBATE_MERGE §12): forma primeiro, cor depois —
-- promessas à distância e controle leem ouro, ameaças corporais vermelho,
-- a queda do martelo brasa de queda e o jato do canal o azul frio da água.
local warnTint = {shot = C.gold, dual = C.gold, mark = C.gold, summon = C.gold,
    push = C.gold, hammer = Pal.ember, jet = Pal.sky.star}
-- A forma da célula vem do modo armado: cada warn dos chefes lê diferente
-- de shot/dash. 'hammer' põe o impacto no pilar e a faixa na direção da
-- queda (a.fallDx/fallDy); 'push' marca só a célula-destino com o rumo do
-- deslize; 'jet' pinta a banda inteira com ondas no eixo; 'shove' repete
-- a lane da investida com chevrons duplos.
local function warnCellSpec(a, e, cell, i)
    local m = a.mode
    if m == 'hammer' then
        if i == 1 then return a.dx or 0, a.dy or 0, 'hammer' end
        return a.fallDx or 0, a.fallDy or 0, 'fall'
    end
    if m == 'push' then return a.pushDx or 0, a.pushDy or 0, 'push' end
    if m == 'jet' then
        return a.jetRow and 1 or 0, a.jetRow and 0 or 1, 'jet'
    end
    if m == 'shove' then return a.dx or 0, a.dy or 0, 'shove' end
    -- Célula pode carregar a própria direção (tiro duplo da veterana); a
    -- cruz deriva a direção pela posição relativa à unidade.
    local dx = cell.dx or (m == 'cross' and (cell.x == e.grid.x and 0
        or cell.x > e.grid.x and 1 or -1)) or a.dx or 0
    local dy = cell.dy or (m == 'cross' and (cell.y == e.grid.y and 0
        or cell.y > e.grid.y and 1 or -1)) or a.dy or 0
    local kind = (m == 'shot' or m == 'dual') and 'shot'
        or (m == 'mark' or m == 'summon') and 'blast' or 'dash'
    return dx, dy, kind
end

-- §6 — a saída da fuga: célula acesa na borda oposta lê um portal de jade
-- aberto para fora do tabuleiro — véu de luz que respira, vão escuro com
-- batentes claros, névoa derramando além do meio-fio e a seta do rumo.
local function fleeExitMark(cell, edge, frame, pulse)
    local x, y = (cell.x - 1) * 32, (cell.y - 1) * 32
    local dx, dy = 0, 0
    if edge == 'east' then dx = 1 elseif edge == 'west' then dx = -1
    elseif edge == 'south' then dy = 1 elseif edge == 'north' then dy = -1 end
    if dx == 0 and dy == 0 and frame then
        -- Sem borda nomeada: a face do tabuleiro mais próxima dita o rumo.
        local dl = x + 16 - frame.x
        local dr = frame.x + frame.w - (x + 16)
        local dt = y + 16 - frame.y
        local db = frame.y + frame.h - (y + 16)
        local m = math.min(dl, dr, dt, db)
        if m == dr then dx = 1 elseif m == dl then dx = -1
        elseif m == db then dy = 1 else dy = -1 end
    end
    -- Luz que escorre para fora da borda do tabuleiro.
    if dx ~= 0 then
        PixelArt.dither(dx > 0 and x + 30 or x - 8, y + 4, 10, 24, Pal.jade.light, .32)
    elseif dy ~= 0 then
        PixelArt.dither(x + 4, dy > 0 and y + 30 or y - 8, 24, 10, Pal.jade.light, .32)
    end
    color(Pal.jade.light, .18 + pulse); G.rectangle('fill', x, y, 32, 32)
    PixelArt.dither(x + 2, y + 2, 28, 28, Pal.jade.base, .3)
    -- Vão da saída: batentes claros e umbra — o miolo escuro é a travessia.
    color(Pal.ink, .92); G.rectangle('fill', x + 10, y + 9, 12, 21)
    color(Pal.jade.light)
    G.rectangle('fill', x + 9, y + 7, 14, 3)
    G.rectangle('fill', x + 8, y + 9, 3, 21)
    G.rectangle('fill', x + 21, y + 9, 3, 21)
    color(Pal.white, .9); G.rectangle('fill', x + 9, y + 7, 14, 1)
    color(Pal.jade.base); G.rectangle('fill', x + 12, y + 30, 8, 2)
    -- A seta aponta além do vão — o rumo é dado, a rota é dela.
    arrow(x + 16 + dx * 19, y + 16 + dy * 19, dx, dy, Pal.jade.light, 5)
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
            local tint = warnTint[a.mode] or C.red
            for i, cell in ipairs(a.cells) do
                if a.state ~= 'dash' or i >= (a.dashIndex or 1) then
                    local dx, dy, kind = warnCellSpec(a, e, cell, i)
                    warningCell(cell, tint, dx, dy, progress, overlay, kind)
                    for _, f in ipairs(cell.fall or {}) do
                        warningCell(f, C.jade, a.dx or 0, a.dy or 0, progress, overlay, 'fall')
                    end
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

function Render:actor(e, game)
    local x, y, jump = Render.visualPosition(e)
    -- Despedida do poupado: a unidade sai do grid — desliza para a borda
    -- e esmaece durante ~1.4s, depois deixa de existir na cena.
    local spareFade
    if e.spared then
        if not e.spareT or e.spareT >= 1.4 then return end
        x = x + e.spareT * 40
        y = y - e.spareT * 10
        spareFade = math.max(0, 1 - e.spareT / 1.4)
    end
    -- Battle-only presentation offsets: an attack lunge pushes the sprite a
    -- few pixels along its facing, and a hit shakes the victim. Never read by
    -- the rules — the logical grid is untouched.
    if not self.reducedMotion then
        if e.lunge and e.lunge.remaining > 0 then
            local t = 1 - e.lunge.remaining / e.lunge.duration
            local push = math.sin(t * pi) * 9
            x, y = x + e.lunge.dx * push, y + e.lunge.dy * push
        end
        if e.shake and e.shake.remaining > 0 then
            local t = e.shake.remaining / e.shake.duration
            x = x + math.sin((e.shake.duration - e.shake.remaining) * 95) * 3 * t
        end
    end
    x, y = math.floor(x + .5), math.floor(y + .5)
    if self.reducedMotion then jump = 0 end
    if spareFade then G.setColor(1, 1, 1, spareFade) end
    if PixelWorld.object(self, e, game, x, y) then
        G.setColor(1, 1, 1); return
    end
    if self.actors and self.actors:draw(self, e, game, x, y, jump) then
        G.setColor(1, 1, 1); return
    end
    if spareFade then G.setColor(1, 1, 1) end
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
        -- Etiqueta flutuante: placa de tinta com filete na cor do aviso e
        -- ponta voltada ao alvo — nunca texto solto sobre a cena.
        local font = self.worldFonts.tiny
        local width = font:getWidth(p.text)
        local a = p.alpha or 1
        local tx, ty = round(p.x * .8), round(p.y * .8)
        local bx, bw = round(tx - width / 2 - 5), width + 10
        color(C.ink, .88 * a); G.rectangle('fill', bx, ty - 4, bw, 13)
        G.setColor(p.color[1], p.color[2], p.color[3], .85 * a)
        G.rectangle('fill', bx, ty - 4, bw, 1); G.rectangle('fill', bx, ty + 8, bw, 1)
        G.rectangle('fill', bx, ty - 4, 1, 13); G.rectangle('fill', bx + bw - 1, ty - 4, 1, 13)
        G.rectangle('fill', round(tx - 1), ty + 9, 2, 2)
        text(font, p.text, round(tx - width / 2), ty - 1, {p.color[1], p.color[2], p.color[3], a})
    end
    -- Flechas em voo: vulto com cauda luminosa e ponta clara, à altura do
    -- torso. Reduced motion congela o vulto a meio caminho em vez de varrer.
    for _, b in ipairs(self.feedback.bolts or {}) do
        local k = self.reducedMotion and .5 or 1 - b.life / b.max
        local x1, y1 = b.x1 * .8, b.y1 * .8 - 14
        local x2, y2 = b.x2 * .8, b.y2 * .8 - 14
        local hx, hy = x1 + (x2 - x1) * k, y1 + (y2 - y1) * k
        local dx, dy = x2 - x1, y2 - y1
        local len = math.max(1, math.sqrt(dx * dx + dy * dy))
        dx, dy = dx / len, dy / len
        -- Cauda dithered que se dissolve: o vulto deixa rastro de brasa.
        if dx ~= 0 then
            PixelArt.dither(round(hx - dx * 26), round(hy - 1), 17, 3, b.color, .3)
            PixelArt.dither(round(hx - dx * 13), round(hy), 8, 1, b.color, .55)
        else
            PixelArt.dither(round(hx - 1), round(hy - dy * 26), 3, 17, b.color, .3)
            PixelArt.dither(round(hx), round(hy - dy * 13), 1, 8, b.color, .55)
        end
        -- Corpo do virote e ponta incandescente.
        color(b.color, .85)
        pixelLine(round(hx - dx * 8), round(hy - dy * 8), round(hx), round(hy))
        arrow(round(hx + dx * 4), round(hy + dy * 4), dx, dy, C.text, 3)
        color(Pal.white)
        pixelLine(round(hx + dx * 1), round(hy + dy * 1), round(hx + dx * 3), round(hy + dy * 3))
        color(Pal.emberLight or Pal.gold.light)
        G.rectangle('fill', round(hx), round(hy), 1, 1)
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
    local still = self.reducedMotion
    for i = 1, 5 do color(C.jade, .013); G.circle('fill', 0, 0, 175 - i * 17) end
    -- Respiração do selo: o halo jade alarga e aperta devagar.
    local breath = still and 0 or math.sin(self.time * .9) * 4
    color(C.line, .7); G.setLineWidth(1)
    G.circle('line', 0, 0, 132 + breath); G.circle('line', 0, 0, 139 + breath)
    -- Runas do aro giram devagar e acendem em onda — cada marca pulsa na
    -- própria fase, o ouro sempre lidera o compasso.
    for i = 0, 23 do
        local a = i * pi / 12 + self.time * .012
        local pulse = still and .5 or .5 + .5 * math.sin(self.time * 1.7 + i * .8)
        local major = i % 3 == 0
        color(major and C.gold or C.line, (major and .55 or .3) + .45 * pulse)
        local inner, outer = 137, (major and 148 or 143) + (still and 0 or pulse * 2)
        G.line(math.cos(a) * inner, math.sin(a) * inner, math.cos(a) * outer, math.sin(a) * outer)
    end
    local jadeGlow = still and .35 or .3 + .15 * math.sin(self.time * .9 + 1)
    color(C.jade, .07); G.polygon('fill', 0, -103, 95, 2, 0, 103, -95, 2)
    color(C.jade, .25 + jadeGlow * .5); G.polygon('line', 0, -103, 95, 2, 0, 103, -95, 2)
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

-- Quadro do objeto real: clip em coordenadas de tela, nenhuma mutação.
local function propPicture(prop, x, y, size, pal, time, calm)
    panel(x, y, size, size, C.jade)
    G.push('all')
    local sx, sy = G.transformPoint(x + 4, y + 4)
    local ex, ey = G.transformPoint(x + size - 4, y + size - 4)
    G.intersectScissor(sx, sy, ex - sx, ey - sy)
    local pw, ph = (prop.w or 1) * 32, (prop.h or 1) * 32
    local monument = prop.kind == 'marco'
    local scale = monument and 1 or math.max(1, math.floor((size - 8) / math.max(pw, ph)))
    G.translate(round(x + size / 2), round(y + size / 2)); G.scale(scale)
    -- O Marco tem 220px de haste: close-up dos nomes, sem esmagar pixels.
    Props.draw(prop, -pw / 2, monument and 64 or -ph / 2, pw, ph, pal, time, calm)
    G.pop()
end

function Render:dialogue(game, w, h)
    local d = game.dialogue
    -- Speakers with an actor sheet get an Undertale-style portrait: the head
    -- crop animates while the line is still typing and rests when done.
    local sheet = d.voice and self.actors.sheets['npc_' .. d.voice]
    -- Retrato emocional por node.expr (mapa Pena); kinds sem linha de
    -- emoções assada caem no corte neutro de sempre.
    local emo = d.node and d.node.expr or 'neutral'
    local face = sheet and (sheet.portraits
        and (sheet.portraits[emo] or sheet.portraits.neutral) or sheet.portrait)
    local picture = not face and d.mode ~= 'shop' and d.preview
    local visual = face or picture
    local width = math.min(760, w - 120)
    local rows = d.mode == 'options' and #d.node.options
        or d.mode == 'shop' and #d.shop or 1
    local boxH = math.max(visual and 224 or 176, (visual and 118 or 88) + rows * 30)
    if d.mode == 'lines' then
        local _, wrapped = self.fonts.body:getWrap(d.lines[d.index] or '', width - (visual and 180 or 52))
        boxH = math.max(boxH, 100 + #wrapped * self.fonts.body:getHeight())
    end
    local x, y = (w - width) / 2, h - boxH - 42
    panel(x, y, width, boxH, C.gold)
    text(self.fonts.medium, d.title or ' ', x + 26, y + 20, C.gold)
    color(C.line); G.setLineWidth(1); G.line(x + 26, y + 52, x + width - 26, y + 52)
    -- Imagem contextual: node.icon (opcional, anexado no interact do
    -- hotspot) pinta o objeto/lugar citado no canto do box — 'casaco'
    -- mostra o casaco, 'marco' mostra o Marco, 'cova' a lápide. Fica na
    -- margem do título: o layout do texto não muda.
    if d.node and d.node.icon and not picture and d.mode ~= 'shop' then
        local ipal = game.room and PixelScene.palette(game.room)
            or Pal.regions.default
        local ix, iy = round(x + width - 50), round(y + 14)
        color(C.ink, .92); G.rectangle('fill', ix - 3, iy - 3, 34, 34)
        border(ix - 3, iy - 3, 34, 34, C.gold, .55)
        Props.icon(d.node.icon, ix, iy, 2, ipal)
    end
    local tx, tw = x + 26, width - 52
    if picture then
        propPicture(picture, x + 26, y + 62, 112, PixelScene.palette(game.room), self.time, self.reducedMotion)
        tx, tw = x + 154, width - 180
    end
    if face then
        panel(x + 26, y + 62, 88, 88, C.jade)
        -- Fase 5: no caminho HD o retrato vem do sprite DSL 64×96 (busto)
        -- quando a voz tem def assada — senão cai no crop legado.
        local hdPort
        if self.hdEnabled then
            -- Retrato dedicado 'portrait_<voz>' (96x96, frame = expressão:
            -- 1 neutro, 2 ternura, 3 raiva contida) — busto DSL é o
            -- fallback quando a voz não tem retrato assado.
            local pDsl = d.voice and HDKit.bakeViaDSL('portrait_' .. d.voice)
            if pDsl then
                local exprFrame = ({kind = 2, soft = 2, happy = 2,
                    stern = 3, raiva = 3, angry = 3})[emo] or 1
                local qs = HDKit.quads(pDsl)
                local fq = qs[math.min(exprFrame, #qs)]
                -- O quad é 96×96 e o painel 88: recorta o miolo do busto
                -- (8px de cada lado) sem perder a escala inteira.
                local qx, qy = fq:getViewport()
                hdPort = {image = pDsl.albedo,
                    quad = G.newQuad(qx + 8, qy + 8, 80, 80,
                        pDsl.albedo:getDimensions())}
            else
                local dslName = d.voice == 'viajante' and 'viajante'
                    or d.voice and ('npc_' .. d.voice .. '_s')
                local dsl = dslName and HDKit.bakeViaDSL(dslName)
                if dsl then
                    hdPort = {image = dsl.albedo,
                        quad = G.newQuad(0, 2, dsl.w, 80,
                            dsl.albedo:getDimensions())}
                end
            end
        end
        if hdPort then
            color(C.white)
            G.draw(hdPort.image, hdPort.quad, x + 30, y + 66)
            tx, tw = x + 126, width - 152
        else
        local sub
        if sheet.portraits then
            -- Retrato emocional: célula própria, parada (a emoção não respira
            -- com o typewriter — muda por node).
            sub = G.newQuad(face[1], face[2], face[3], face[4],
                sheet.image:getDimensions())
        else
            local frames = sheet.animations.idle[2].frames
            local revealing = d.mode == 'lines'
                and (d.reveal or 0) < (utf8.len(d.lines[d.index]) or #d.lines[d.index])
            local quad = frames[revealing and math.floor(self.time * 10) % #frames + 1 or 1]
            local sx, sy = quad:getViewport()
            sub = G.newQuad(sx + face[1], sy + face[2], face[3], face[4],
                sheet.image:getDimensions())
        end
        -- Escala inteira: nearest exige texels uniformes — a fração anterior
        -- (~4.4x) produzia pixels irregulares no retrato.
        local fs = math.max(1, math.floor(math.min(80 / face[3], 80 / face[4])))
        color(C.white)
        G.draw(sheet.image, sub,
            x + 30 + math.floor((80 - face[3] * fs) / 2),
            y + 66 + math.floor((80 - face[4] * fs) / 2), 0, fs, fs)
        tx, tw = x + 126, width - 152
        end
    end
    if d.mode == 'shop' then
        text(self.fonts.small, 'OURO: ' .. game.gold, x + width - 140, y + 20, C.gold)
        for i, item in ipairs(d.shop) do
            text(self.fonts.body, i .. '   ' .. item.label .. '   ·   '
                .. (item.sold and 'VENDIDO' or item.price .. ' OURO'),
                tx, y + 58 + (i - 1) * 30, item.sold and C.muted or C.text, tw)
        end
        text(self.fonts.small, 'Número compra   ·   E voltar   ·   ESC fechar', x + 26, y + boxH - 26, C.muted)
    elseif d.mode == 'options' then
        for i, option in ipairs(d.node.options) do
            text(self.fonts.body, i .. '   ' .. option.label, tx, y + 58 + (i - 1) * 30, C.text, tw)
        end
        text(self.fonts.small, 'Número escolhe   ·   ESC fechar', x + 26, y + boxH - 26, C.muted)
    else
        local line = d.lines[d.index]
        local len = utf8.len(line) or #line
        local shown = math.floor(math.min(len, d.reveal or len))
        local boundary = utf8.offset(line, shown + 1) or (#line + 1)
        text(self.fonts.body, line:sub(1, boundary - 1), tx, y + 60, C.text, tw)
        text(self.fonts.small, shown < len and 'E >' or 'E >>', x + width - 70, y + boxH - 26, C.muted)
    end
end

-- Campaign presentation: same canvas/camera pipeline, authored maps instead of
-- generated rooms, continuous feet positions instead of hop interpolation.
local titleFacade = {state = 'menu', room = {}, events = {},
    entities = function() return {} end, player = {grid = {x = 0, y = 0}}}

-- Com o palco preso à faixa de tela, a câmera da arena só precisa de uma
-- garantia: nunca rolar além do topo dos sprites da fileira mais alta.
local function battleClampTop(battle, v)
    local topRow = math.huge
    for _, tile in pairs(battle.room.tiles) do
        if tile.ground == 'floor' and not tile.protected then
            topRow = math.min(topRow, tile.y)
        end
    end
    if topRow ~= math.huge then
        local headTop = (topRow - .5) * 32 - 50
        -- Viés para o alto: a borda inferior da arena já vive sob o painel
        -- de comandos — rende mais faixa de céu para o horizonte assado.
        v.top = math.max(-30, math.min(v.top, math.max(0, headTop)) - 18)
    end
end

local function refugePanorama(width, height, map)
    local scale = math.min((width - 24) / (map.w * 32), (height - 156) / (map.h * 32))
    return {scale = scale, w = map.w * 32, h = map.h * 32, left = 0, top = 0,
        x = math.floor((width - map.w * 32 * scale) / 2), y = 76}
end

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
    -- O banner acompanha a sala exibida: a arena também anuncia o próprio nome.
    local shownRoom = campaign.scene == 'battle' and campaign.battle and campaign.battle.room
        or campaign.room
    if self.room ~= shownRoom then self.room, self.roomTime = shownRoom, 2.5 end
    if screen == 'campaign' then self.roomTime = math.max(0, (self.roomTime or 0) - dt) end
    self:updateDialogueReveal(dt, campaign.dialogue)
    local battle = campaign.scene == 'battle' and campaign.battle or nil
    local map = battle and battle.room or campaign.room
    -- A câmera segue a unidade da arena durante a batalha, e a faixa do
    -- palco fica reservada acima do canvas.
    local anchor = battle and battle.player or campaign.player
    local x, y = Render.visualPosition(anchor)
    local v = Render.layout(G.getWidth(), G.getHeight(), map, x, y, 76,
        battle and Render.battleStageH + 4 or 0)
    if battle then battleClampTop(battle, v) end
    -- Revelação curta no mirante. Depois volta à escala normal e segue os pés.
    if not battle and map.id == 'hub' and map.outdoor and (campaign.panoramaTime or 0) > 0 then
        v = refugePanorama(G.getWidth(), G.getHeight(), map)
    end
    self.view = v
end

-- Faixa de horizonte no topo do mapa. Nenhuma das quatro regiões novas
-- abre a parede norte para o exterior (plantas internas, casca de muros em
-- volta) — a vista só se aplica à colina, que já nasceu ao relento e
-- reaproveita o vocabulário do palco/boardVoidHill: bandas de céu, lua
-- baixa, crista com lápides. Desenhada sobre o canvas assado, antes dos
-- portais, substituindo a linha de muro norte pela linha do horizonte.
local function vista(map)
    if map.id ~= 'colina' then return end
    local L, R = -64, map.w * 32 + 64
    local y0, y1 = 0, 34
    color(Pal.sky.mid); G.rectangle('fill', L, y0, R - L, 10)
    color(Pal.sky.low); G.rectangle('fill', L, y0 + 10, R - L, 10)
    color(Pal.sky.horizon); G.rectangle('fill', L, y0 + 20, R - L, y1 - y0 - 20)
    PixelArt.dither(L, y0 + 8, R - L, 3, Pal.sky.low, .3)
    PixelArt.dither(L, y0 + 18, R - L, 3, Pal.sky.horizon, .3)
    -- Estrelas fixas e a lua baixa à esquerda — mesma mão do palco.
    for i = 0, 14 do
        local sx = L + (i * 197) % (R - L)
        local sy = y0 + 2 + (i * 53) % 16
        color(Pal.sky.star, .45 + (i % 3) * .15); G.rectangle('fill', sx, sy, 1, 1)
    end
    local mx, my = L + math.floor((R - L) * .18), y0 + 12
    PixelArt.ditherEllipse(mx, my, 14, 11, Pal.moon.halo, .3)
    for j = -6, 6 do
        local half = math.floor(math.sqrt(math.max(0, 36 - j * j)))
        color(Pal.moon.disc); G.rectangle('fill', mx - half, my + j, math.max(1, half * 2), 1)
        local sh = math.floor(math.sqrt(math.max(0, 9 - (j + 3) * (j + 3))))
        if half > 2 and sh > 0 then
            color(Pal.moon.shade); G.rectangle('fill', mx + half - sh - 3, my + j, sh, 1)
        end
    end
    -- Crista recorta o pé da faixa: longe primeiro, perto por cima, e
    -- lápides miúdas de silhueta — o vale que a colina olha.
    for x = L, R, 4 do
        local rh = 3 + (x * 7) % 5
        color(Pal.ridge.far); G.rectangle('fill', x, y1 - rh - 4, 4, rh + 4)
    end
    for x = L, R, 7 do
        local rh = 2 + (x * 11) % 4
        color(Pal.ridge.near); G.rectangle('fill', x, y1 - rh, 7, rh)
    end
    for i = 0, 6 do
        local gx = L + 40 + (i * 211) % (R - L - 80)
        color(Pal.ridge.near); G.rectangle('fill', gx, y1 - 9, 3, 6)
        color(Pal.ridge.lit, .7); G.rectangle('fill', gx, y1 - 9, 3, 1)
    end
end

-- Vida ambiente em VOLUME (não 3 pixels soltos): colunas de fumaça nas
-- bocas de fogo, poeira/incenso/vaga-lumes por realm, fagulhas com
-- densidade proporcional à fonte e névoa larga no vale/panorama. Tudo
-- determinístico — cada partícula tem órbita e fase derivadas do índice.
-- Reduced-motion congela tudo num frame fixo (t=0): fumaça vira névoa
-- estática, poeira vira ponto parado — nunca desaparece. Desenhada na
-- camada ambiente, abaixo do feedback de gameplay, sem canvas por frame.
local function ambientVolume(self, map, pal)
    local t = self.reducedMotion and 0 or self.time
    local mw, mh = map.w * 32, map.h * 32
    local style = map.realm == 'refugio' and (map.outdoor and 'dust' or 'incense')
        or 'jade'
    local moteTint = style == 'jade' and Pal.jade.light
        or style == 'incense' and Pal.emberLight or Pal.gold.light
    -- Poeira/incenso/vaga-lume: volume dobrado e grumos de 2 px — o ar se
    -- vê em massa, não em confete.
    local motes = style == 'dust' and 16 or 18
    for i = 1, motes do
        local bx = (i * 137.3) % mw
        local by = (i * 89.7) % mh
        local x = bx + math.sin(t * .31 + i * 2.7) * (style == 'incense' and 5 or 10)
        local y = by + math.sin(t * .43 + i * 1.9) * (style == 'dust' and 5 or 8)
            - (style == 'dust' and 0
                or (t * (style == 'incense' and .5 or .9) + i * 7)
                    % (style == 'incense' and 12 or 10))
        local a = (style == 'incense' and .07 or .10)
            + .16 * (math.sin(t * .9 + i * 2.1) * .5 + .5)
        color(moteTint, a)
        G.rectangle('fill', round(x), round(y), i % 5 == 0 and 2 or 1, 1)
        if i % 4 == 0 then
            color(moteTint, a * .45); G.rectangle('fill', round(x) - 1, round(y), 1, 1)
        end
    end
    -- Fumaça + fagulha por fonte: a coluna sobe da chaminé/boca e engrossa
    -- com a altitude; a forja tosse muito, o braseiro fumega, a vela não
    -- fuma (vol=0 não entra na tabela de âncoras).
    local smokeTint = map.outdoor
        and (map.realm == 'refugio' and Pal.refuge.plasterLight or Pal.moon.shade)
        or pal.wall.mortar
    for _, prop in ipairs(map.props or {}) do
        local sx, sy, vol = Props.smokeAnchor(prop)
        if sx then
            local n = math.max(4, math.floor(vol * 8))
            local rise = 30 + vol * 18
            for i = 1, n do
                local yy = (t * (6 + vol * 2) + i * 13) % rise
                local spread = 2 + yy * .13
                local x = sx + math.sin(t * .6 + i * 2.3) * spread
                local y = sy - yy
                local a = .38 * (1 - yy / rise) * math.min(1, vol)
                local s = yy > rise * .5 and 3 or 2
                color(smokeTint, a)
                G.rectangle('fill', round(x), round(y), s, s)
                if i % 3 == 0 then
                    color(smokeTint, a * .5)
                    G.rectangle('fill', round(x) + s, round(y) - 1, 1, 1)
                end
            end
        end
        -- Fagulhas orbitam a fonte de luz: brasa que sobe e apaga —
        -- densidade proporcional ao raio da âncora (forja muita, vela pouca).
        local lx, ly, ltint, lr = Props.lightAnchor(prop)
        if lx then
            local sparks = math.max(2, math.floor((lr or 8) / 4))
            for i = 1, sparks do
                local ph = t * 1.6 + i * 2.1 + (prop.x or 0)
                local x = lx + math.sin(ph * .9 + i) * (4 + i * 2)
                local y = ly - ((t * 9 + i * 11 + (prop.y or 0) * 7) % 14)
                local a = .2 + .3 * (math.sin(ph) * .5 + .5)
                color(ltint, a)
                G.rectangle('fill', round(x), round(y), 1, 1)
            end
        end
    end
    -- Névoa de vale: bandas largas à deriva sobre o refúgio aberto e véu
    -- rasteiro sob a linha do horizonte da colina — camada de ar, não ruído.
    if map.realm == 'refugio' and map.outdoor then
        local haze = Pal.refuge.haze
        for i = 0, 3 do
            local fx = ((t * (3 + i) + i * 310) % (mw + 280)) - 140
            local fy = mh * (.5 + i * .14) + math.sin(t * .2 + i) * 3
            local bw = 190 + i * 30
            color(haze, .045)
            G.rectangle('fill', round(fx), round(fy), bw, 5 + i)
            PixelArt.dither(round(fx), round(fy - 3), bw, 3, haze, .10)
            PixelArt.dither(round(fx), round(fy + 5 + i), bw, 3, haze, .07)
        end
    elseif map.id == 'colina' then
        for i = 0, 1 do
            local fx = ((t * 4 + i * 260) % (mw + 200)) - 100
            PixelArt.dither(round(fx), 33 + i * 5, 140, 4, Pal.moon.halo, .15)
        end
        color(Pal.moon.halo, .05); G.rectangle('fill', 0, 30, mw, 5)
    end
end

-- Atmosfera por região: vinheta de canto no tom profundo local (2-3
-- passes translúcidos) + poça de luz dithered nas âncoras de fogo/vela.
-- Alpha baixo — é clima por cima da cena, nunca filtro.
local atmoTone = {
    oficinas = {deep = PixelWorld.palette.goldDeep, accent = Pal.ember},
    mercado = {deep = PixelWorld.palette.goldDark, accent = Pal.regions.mercado.wood.base},
    reservatorio = {deep = PixelWorld.palette.jadeDeep, accent = Pal.sky.mid},
    saloes = {deep = PixelWorld.palette.violetDark, accent = PixelWorld.palette.rust},
    hub = {deep = PixelWorld.palette.goldDeep, accent = Pal.gold.light},
    colina = {deep = PixelWorld.palette.violetDeep, accent = Pal.violet},
}
local function atmoOverlay(self, map)
    local v = self.view
    if not v then return end
    local tone = atmoTone[map.id]
        or {deep = PixelWorld.palette.stoneDeep, accent = Pal.stone.base}
    -- Vinheta presa ao rect estrito do mapa (0..w*32): nada pinta a margem
    -- de void — sem clampa, o canto lê como adesivo sobre preto.
    local x0 = math.max(v.left, 0)
    local y0 = math.max(v.top, 0)
    local x1 = math.min(v.left + v.w, map.w * 32)
    local y1 = math.min(v.top + v.h, map.h * 32)
    if x1 <= x0 or y1 <= y0 then return end
    local vw, vh = x1 - x0, y1 - y0
    color(tone.deep, .10); G.rectangle('fill', x0, y0, vw, 12)
    color(tone.deep, .07); G.rectangle('fill', x0, y0, 20, vh)
    color(tone.deep, .07); G.rectangle('fill', x1 - 20, y1 - 36, 20, 36)
    -- Fio do acento local no topo; cantos fecham em halo dithered —
    -- densidade máxima no canto decaindo a zero, sombra esfumaçada sem
    -- aresta retangular. O halo só sai se houver tile sob a zona densa:
    -- canto sobre bolsão de void interno fica sem mancha nenhuma.
    color(tone.accent, .06); G.rectangle('fill', x0, y0, vw, 6)
    local function contentAt(x, y)
        return map.tiles[(math.floor(x / 32) + 1) .. ':' .. (math.floor(y / 32) + 1)] ~= nil
    end
    if contentAt(x0 + 12, y0 + 12) then PixelArt.halo(x0, y0, 30, 22, tone.deep, .28) end
    if contentAt(x1 - 12, y0 + 12) then PixelArt.halo(x1, y0, 30, 22, tone.deep, .28) end
    if contentAt(x0 + 12, y1 - 12) then PixelArt.halo(x0, y1, 26, 20, tone.deep, .24) end
    if contentAt(x1 - 12, y1 - 12) then PixelArt.halo(x1, y1, 26, 20, tone.deep, .24) end
    -- Foco quente: poça de luz em rampa nas âncoras que já devolvem fogo —
    -- núcleo claro, anel médio e borda dissolvendo (lightPool; shader leve
    -- opcional, fallback dithered idêntico em espírito).
    local P = PixelWorld.palette
    for _, prop in ipairs(map.props or {}) do
        local lx, ly, ltint = Props.lightAnchor(prop)
        if lx and (ltint == P.ember or ltint == P.emberLight) then
            local fl = self.reducedMotion and 1
                or .8 + .2 * math.sin(self.time * 5.3 + (prop.x or 0))
            PixelArt.lightPool(lx, ly + 4, 26, 12, ltint, .14 * fl,
                ltint == P.ember and P.emberLight or P.white)
        end
    end
end

function Render:worldCampaign(campaign)
    local map = campaign.room
    -- Camada estática assada por sala: piso orgânico, alvenaria contínua,
    -- contorno e sombras de contato. Reassada quando a sala troca ou quando
    -- alguém marca o mapa como sujo (prop sólido mudou de estado — a sombra
    -- assada precisa refletir a grade erguida / o corpo recolhido).
    local stale = PixelScene.isDirty(map)
    if self.sceneMap ~= map or stale then
        self.sceneMap, self.sceneCanvas = map, PixelScene.bake(map, map.uid)
    end
    color(C.white); G.draw(self.sceneCanvas, -64, -64)
    vista(map)
    local doorTags = {}
    for i, door in ipairs(map.doors or {}) do
        if not door.hidden or door.revealed then
            PixelWorld.portal(self, campaign, door)
            -- Nome do destino sobre o lintel: o portal anuncia para onde
            -- leva e, fechado, diz que está fechado — a topologia do hub
            -- lê-se sem abrir mapa. O letreiro entra na lista e desenha
            -- DEPOIS dos atores — nunca coberto por quem pisa a faixa.
            if door.label then
                local tag = PixelFont.clean(door.label)
                local open = campaign:canLeave(door)
                if not open then tag = tag .. ' · FECHADA' end
                -- Casa encostada ao norte da porta: o letreiro não flutua
                -- sobre a fachada longa — vira placa fixa pregada na madeira.
                local sign
                for _, prop in ipairs(map.props or {}) do
                    local pw, ph = prop.w or 1, prop.h or 1
                    if prop.solid and door.x >= prop.x and door.x < prop.x + pw
                        and door.y - 1 >= prop.y and door.y - 1 < prop.y + ph then
                        sign = true; break
                    end
                end
                doorTags[#doorTags + 1] = {
                    tag = tag,
                    tint = open and (door.finish and Pal.gold.light or Pal.jade.base)
                        or Pal.gold.dark,
                    x = (door.x - .5) * 32,
                    -- Placa alta sobre o batente — o letreiro não deita
                    -- sobre a pedra da porta; na fachada a placa sobe mais
                    -- 4px para assentar na madeira como aviso pregado.
                    y = (door.y - 1) * 32 - 20 - (i % 3) * 9 - (sign and 4 or 0),
                    sign = sign,
                }
            end
        end
    end
    -- Sombras lançadas: objeto alto (casa, marco, pilastra) deita sombra de
    -- viés na direção OPOSTA à fonte de luz mais próxima — luz do leste,
    -- sombra pro oeste. Com várias fontes, a mais próxima vence; sem fonte
    -- no raio, fica a sombra de contato assada de sempre. Pintada no piso,
    -- sob props e atores, na mesma densidade dithered da cena.
    local lightAnchors = {}
    for _, prop in ipairs(map.props or {}) do
        local lx, ly, _, lr = Props.lightAnchor(prop)
        -- Raio de influência bem maior que a poça: a sombra alcança o
        -- vizinho próximo, não só a borda do brilho.
        if lx then lightAnchors[#lightAnchors + 1] = {x = lx, y = ly, r = (lr or 12) * 8} end
    end
    if #lightAnchors > 0 then
        local Pw = PixelWorld.palette
        for _, prop in ipairs(map.props or {}) do
            local sx, sy, sw, sh = Props.shadowCaster(prop)
            if sx then
                local best, bd2
                for _, a in ipairs(lightAnchors) do
                    local dx, dy = sx - a.x, sy - a.y
                    local d2 = dx * dx + dy * dy
                    if d2 < a.r * a.r and (not bd2 or d2 < bd2) then best, bd2 = a, d2 end
                end
                if best then
                    local dist = math.max(8, math.sqrt(bd2))
                    local dx, dy = (sx - best.x) / dist, (sy - best.y) / dist
                    -- Alongada pela altura, achatada no eixo Y (vista de
                    -- cima inclinada); mais definida quanto mais perto.
                    local near = 1 - dist / best.r
                    local len = math.min(sh * .55, 26 + sh * .25)
                    for k = 1, 3 do
                        local f = k / 3
                        PixelArt.ditherEllipse(
                            sx + dx * len * f, sy + dy * len * f * .45,
                            sw * (.32 + .18 * f), 2.5 + f * 2,
                            Pw.ink, (.12 + .14 * near) * (1 - f * .4))
                    end
                end
            end
        end
    end
    local pal = PixelScene.palette(map)
    local layers = {}
    for _, tile in pairs(map.tiles) do
        -- 'wall' e 'fallen' estão assados no canvas; pilares continuam
        -- dinâmicos por terem estado visual próprio.
        if tile.piece and tile.piece ~= 'portal' and tile.piece ~= 'wall' then
            layers[#layers + 1] = {tile = tile, depth = tile.y * 32, x = tile.x * 32}
        end
    end
    for _, prop in ipairs(map.props) do
        -- Props-chão (escadaria transitável) já estão assados no canvas do
        -- piso: fora da fila de depth, senão pintam por cima de quem sobe.
        if prop.state ~= 'taken' and not Props.bakesToGround(prop) then
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
        if layer.tile then self:wall(map, layer.tile, pal)
        elseif layer.prop then
            Props.draw(layer.prop, (layer.prop.x - 1) * 32, (layer.prop.y - 1) * 32,
                (layer.prop.w or 1) * 32, (layer.prop.h or 1) * 32, pal,
                self.time, self.reducedMotion)
        else self:actor(layer.entity, campaign) end
    end
    -- Camada ambiente de cenário (fumaça, poeira, brasa, névoa): fica
    -- ABAIXO do gameplay — efeitos de flecha/impacto sempre leem por cima.
    ambientVolume(self, map, pal)
    self:effects()
    atmoOverlay(self, map)
    -- Letreiros de portal por cima de tudo da cena (atores, efeitos, motes):
    -- o nome do destino não pode ser tampado por quem passa na faixa. No
    -- panorama (escala < 1) a fonte miúda vira traço ciano ilegível — os
    -- letreiros ficam só na leitura jogável.
    if self.view and (self.view.scale or 1) < 1 then doorTags = {} end
    local font = self.worldFonts.tiny
    for _, t in ipairs(doorTags) do
        local tw = font:getWidth(t.tag)
        local tx = math.floor(t.x - tw / 2)
        if t.sign then
            -- Placa fixa na fachada: tábua pregada com tinta quente, não a
            -- bolha flutuante — a placa é parte da casa, não um popup.
            color(C.ink, .9); G.rectangle('fill', tx - 4, t.y - 2, tw + 8, 11)
            color(pal.wood.dark); G.rectangle('fill', tx - 3, t.y - 1, tw + 6, 9)
            color(pal.wood.base); G.rectangle('fill', tx - 3, t.y - 1, tw + 6, 1)
            color(pal.wood.light); G.rectangle('fill', tx - 3, t.y + 8, tw + 6, 1)
            color(C.ink); G.rectangle('fill', tx - 2, t.y, 1, 1)
            G.rectangle('fill', tx + tw + 2, t.y, 1, 1)
            text(font, t.tag, tx, t.y + 1, Pal.emberLight)
        else
            color(C.ink, .8); G.rectangle('fill', tx - 3, t.y - 1, tw + 6, 9)
            color(t.tint, .8); G.rectangle('fill', tx - 3, t.y - 2, tw + 6, 1)
            text(font, t.tag, tx, t.y, t.tint)
        end
    end
    if campaign.state == 'playing' and not campaign.dialogue and campaign.scene == 'explore' then
        -- O prompt promete o que interact() entrega — mesmo seletor
        -- (facing + proximidade), mesmo vencedor.
        local target = campaign:interactTarget()
        if target and (target.kind == 'npc' or target.kind == 'talker') then
            local npc = target.obj
            interactPrompt(self.worldFonts.tiny, (npc.grid.x - .5) * 32, (npc.grid.y - .5) * 32, 'E · FALAR')
        elseif target then
            local spot = target.obj
            interactPrompt(self.worldFonts.tiny, (spot.x - .5) * 32, (spot.y - .5) * 32, 'E · ' .. spot.label)
        end
    end
end

-- Turn overlays speak the Fractured But Whole vocabulary: blue = movement
-- range anchored where the turn began, gold = confirmed-aim preview, red =
-- telegraphed enemy intents carrying their resolution order. Every overlay
-- reads as inlay engraved in the stone — subtle fill, inset border and
-- strong corner brackets — never a flat editor fill. Previews never depend
-- on color alone (BATALHA_ACT_MERCY §9). Os helpers cellMark/cellLane/
-- cellStripe morreram com os ramos de turno ('aim'/'pillar'/menu legado) —
-- a marcação viva é warningCell + warnCellSpec.

-- Chevron apontando a direção do telegraph: três marcas repetidas numa cela
-- leem como uma via de impacto, não como hachura de aviso.
function chevron(x, y, dx, dy, c)
    color(c)
    for i = 0, 1 do
        local ox, oy = x - dx * i * 5, y - dy * i * 5
        pixelLine(ox - dy * 4 - dx * 4, oy - dx * 4 - dy * 4, ox, oy)
        pixelLine(ox, oy, ox + dy * 4 - dx * 4, oy + dx * 4 - dy * 4)
    end
end

-- Espinho plantado: triângulo sólido de base larga — farpa de solo, nunca
-- chevron nem seta. `tip` acende a ponta (âmbar armado) quando passado.
local function thornTip(cx, y, h, c, alpha, tip)
    color(c, alpha or 1)
    for j = 0, h - 1 do
        local w = math.floor(j * 3.2 / h)
        G.rectangle('fill', cx - w, y - h + j, w * 2 + 1, 1)
    end
    color(tip or c, alpha or 1); G.rectangle('fill', cx, y - h, 1, 1)
end

-- Os kinds de glifo sobrevivem ao modelo de turnos: o enemyReadout emite o
-- mesmo vocabulário (chevron/retícula/cruz/farpa) para o estado real-time.

-- Caixote de arena (RUTE): caixa de madeira com cantoneiras de pedra —
-- empurrável, mais baixo que o pilar, lê-se carga e não monumento.
local function boardCrate(tile)
    local x, y = (tile.x - .5) * 32, (tile.y - .5) * 32
    local Rw = Pal.regions.default.wood
    PixelArt.ditherEllipse(x, y + 10, 14, 5, Pal.ink, .7)
    color(Pal.ink); G.rectangle('fill', x - 12, y - 8, 24, 18)
    color(Rw.base); G.rectangle('fill', x - 11, y - 7, 22, 16)
    color(Rw.light); G.rectangle('fill', x - 11, y - 7, 22, 3)
    color(Rw.dark); G.rectangle('fill', x - 11, y + 5, 22, 2)
    -- Tábuas verticais e caixilho X na face.
    color(Rw.dark); G.rectangle('fill', x - 4, y - 7, 1, 16); G.rectangle('fill', x + 3, y - 7, 1, 16)
    pixelLine(x - 11, y - 7, x + 11, y + 9); pixelLine(x + 11, y - 7, x - 11, y + 9)
    color(Pal.stone.dark)
    G.rectangle('fill', x - 12, y - 8, 4, 4); G.rectangle('fill', x + 8, y - 8, 4, 4)
    G.rectangle('fill', x - 12, y + 6, 4, 4); G.rectangle('fill', x + 8, y + 6, 4, 4)
    color(Pal.stone.light); G.rectangle('fill', x - 12, y - 8, 4, 1); G.rectangle('fill', x + 8, y - 8, 4, 1)
end

-- Pip de intenção em miniatura: o mesmo vocabulário dos marcadores de
-- campo (chevron/retícula/pegada/losango) num selo de 7x7 — usado sobre
-- as unidades, na fila de turnos e no cartão de inspeção.
local function intentGlyph(kind, x, y, tint)
    if kind == 'dash' then
        chevron(x + 6, y + 3, 1, 0, tint)
    elseif kind == 'shoot' then
        color(tint)
        pixelLine(x, y + 3, x + 2, y + 3); pixelLine(x + 4, y + 3, x + 6, y + 3)
        pixelLine(x + 3, y, x + 3, y + 1); pixelLine(x + 3, y + 5, x + 3, y + 6)
        G.rectangle('fill', x + 3, y + 3, 1, 1)
    elseif kind == 'move' then
        color(tint)
        G.rectangle('fill', x + 1, y + 1, 2, 3); G.rectangle('fill', x + 4, y + 3, 2, 3)
    elseif kind == 'shove' then
        -- Empurrão do bastão: mão palma-abaerta deslocando — leitura de
        -- empurrar, não de ferir.
        color(tint)
        pixelLine(x + 1, y + 3, x + 3, y + 3); pixelLine(x + 4, y + 1, x + 5, y + 3)
        pixelLine(x + 4, y + 5, x + 5, y + 3); G.rectangle('fill', x + 5, y + 3, 2, 1)
    elseif kind == 'hammer' then
        -- Martelo: cabeça + cabo — a queda do pilar em glifo.
        color(tint)
        G.rectangle('fill', x + 1, y + 1, 5, 3)
        G.rectangle('fill', x + 4, y + 4, 1, 3)
    elseif kind == 'push' then
        -- Caixote deslizando: quadrado + traços de movimento atrás.
        color(tint)
        G.rectangle('fill', x + 3, y + 2, 4, 4)
        G.rectangle('fill', x, y + 3, 2, 1); G.rectangle('fill', x, y + 5, 1, 1)
    elseif kind == 'jet' then
        -- Jato: três ondas — a banda do canal corre toda.
        color(tint)
        pixelLine(x, y + 1, x + 2, y + 3); pixelLine(x + 2, y + 3, x + 4, y + 1)
        pixelLine(x + 4, y + 1, x + 6, y + 3)
        G.rectangle('fill', x, y + 5, 7, 1)
    elseif kind == 'sow' then
        -- Espinho: farpa triangular cravada no solo — planta, não atinge.
        color(tint)
        pixelLine(x + 1, y + 5, x + 3, y + 1); pixelLine(x + 3, y + 1, x + 5, y + 5)
        G.rectangle('fill', x + 2, y + 4, 3, 2); G.rectangle('fill', x, y + 6, 7, 1)
    elseif kind == 'ritual' then
        -- Cruz do rito: braços curtos + miolo marcado.
        color(tint)
        pixelLine(x + 3, y, x + 3, y + 6); pixelLine(x, y + 3, x + 6, y + 3)
    elseif kind == 'burst' then
        -- Blast armado: X + núcleo claro — a cruz já rezada.
        color(tint)
        pixelLine(x, y, x + 6, y + 6); pixelLine(x + 6, y, x, y + 6)
        G.rectangle('fill', x + 3, y + 3, 1, 1)
    elseif kind == 'demolish' then
        -- Demolição: chevron atravessando a laje partida à frente.
        chevron(x + 3, y + 3, 1, 0, tint)
        color(tint); G.rectangle('fill', x + 5, y + 1, 2, 5)
        color(C.ink, .6); G.rectangle('fill', x + 5, y + 3, 2, 1)
    else
        diamond(x + 3, y + 3, 2, tint)
    end
end

-- Ícone de slot em 10x10: forma antes de cor — cada ação tem um glifo
-- próprio legível a 20px de ficha.
local function slotIcon(id, x, y, dim)
    local g = dim and C.muted or C.gold
    if id == 'bow' then
        color(g); pixelLine(x, y + 9, x + 8, y + 1)
        pixelLine(x + 5, y, x + 8, y + 1); pixelLine(x + 9, y + 4, x + 8, y + 1)
        color(dim and C.muted or Pal.jade.base)
        pixelLine(x - 1, y + 7, x + 1, y + 10); pixelLine(x + 1, y + 10, x + 3, y + 9)
    elseif id == 'act' then
        -- Balão de fala com três pontos — conversar sem gastar turno.
        color(dim and C.muted or C.jade)
        G.rectangle('fill', x, y, 9, 6); G.rectangle('fill', x + 2, y + 6, 2, 2)
        color(dim and C.muted or C.white)
        G.rectangle('fill', x + 1, y + 2, 1, 1); G.rectangle('fill', x + 4, y + 2, 1, 1)
        G.rectangle('fill', x + 7, y + 2, 1, 1)
    elseif id == 'mercy' then
        -- Mão aberta de osso com o coração de jade na palma — aceitar a
        -- retirada lê-se à primeira vista, sem decoração fina.
        local PW = PixelWorld.palette
        color(dim and C.muted or PW.bone)
        G.rectangle('fill', x + 3, y + 4, 5, 6)              -- palma
        G.rectangle('fill', x + 1, y + 5, 2, 3)              -- polegar
        G.rectangle('fill', x + 3, y + 1, 1, 3); G.rectangle('fill', x + 5, y, 1, 4)
        G.rectangle('fill', x + 7, y + 1, 1, 3)              -- dedos
        color(dim and C.muted or Pal.jade.base)
        G.rectangle('fill', x + 4, y + 5, 3, 2); G.rectangle('fill', x + 5, y + 7, 1, 1)
    elseif id == 'tool' then
        -- Picareta de perfil: cabeça curva em ferro + talo de madeira.
        color(dim and C.muted or Pal.stone.light)
        pixelLine(x + 1, y + 1, x + 8, y + 1); pixelLine(x + 1, y + 1, x - 1, y + 4)
        pixelLine(x + 8, y + 1, x + 10, y + 4)
        color(dim and C.muted or Pal.gold.dark)
        pixelLine(x + 5, y + 1, x + 4, y + 9); pixelLine(x + 4, y + 9, x + 3, y + 9)
    elseif id == 'use' then
        -- Bolsa de itens com laço — consome do inventário.
        color(dim and C.muted or Pal.gold.dark)
        G.rectangle('fill', x + 2, y + 3, 6, 7); G.rectangle('fill', x + 1, y + 5, 8, 5)
        color(dim and C.muted or Pal.gold.base)
        G.rectangle('fill', x + 3, y + 1, 4, 2); G.rectangle('fill', x + 4, y + 3, 2, 1)
        color(dim and C.muted or C.white)
        G.rectangle('fill', x + 4, y + 6, 1, 2)
    elseif id == 'guard' then
        color(dim and C.muted or C.blue)
        pixelLine(x, y, x + 9, y); pixelLine(x, y, x, y + 5); pixelLine(x + 9, y, x + 9, y + 5)
        pixelLine(x, y + 5, x + 4, y + 9); pixelLine(x + 9, y + 5, x + 4, y + 9)
        color(dim and C.muted or Pal.jade.base); G.rectangle('fill', x + 4, y + 2, 1, 4)
    elseif id == 'pillar' then
        color(dim and C.muted or Pal.stone.light)
        G.rectangle('fill', x + 1, y, 6, 2); G.rectangle('fill', x + 2, y + 2, 4, 6)
        G.rectangle('fill', x, y + 8, 10, 2)
        color(g); pixelLine(x + 8, y + 3, x + 10, y + 6)
    elseif id == 'heal' then
        color(dim and C.muted or Pal.jade.base)
        G.rectangle('fill', x + 3, y, 3, 2); G.rectangle('fill', x + 1, y + 2, 7, 7)
        color(dim and C.muted or C.white)
        G.rectangle('fill', x + 4, y + 3, 1, 5); G.rectangle('fill', x + 2, y + 5, 5, 1)
    elseif id == 'wait' then
        color(g)
        pixelLine(x + 1, y, x + 8, y); pixelLine(x + 1, y + 9, x + 8, y + 9)
        pixelLine(x + 1, y, x + 4, y + 4); pixelLine(x + 8, y, x + 5, y + 4)
        pixelLine(x + 4, y + 5, x + 1, y + 9); pixelLine(x + 5, y + 5, x + 8, y + 9)
        G.rectangle('fill', x + 4, y + 6, 1, 2)
    elseif id == 'flee' then
        color(dim and C.muted or Pal.stone.light)
        G.rectangle('fill', x, y, 5, 9); G.rectangle('fill', x + 1, y + 1, 3, 7)
        color(dim and C.muted or C.jade)
        pixelLine(x + 6, y + 4, x + 10, y + 4)
        pixelLine(x + 8, y + 2, x + 10, y + 4); pixelLine(x + 8, y + 6, x + 10, y + 4)
    end
end

-- Papel de cada kind para o cartão de inspeção: um lembrete tático, não
-- lore — o que muda na decisão desta rodada.
local inspectNotes = {
    dasher = 'FRENTE ABSORVE A FLECHA.',
    breaker = 'SAIA DA ROTA ANUNCIADA.',
    demolisher = 'ESMAGA O QUE ESBARRA.',
    warden = 'GUARDA O EIXO DA ARENA.',
    ranger = 'DISPARA EM LINHA.',
    veteran = 'TIRO EM LINHA CONSTANTE.',
    sower = 'SEMEIA INTENÇÕES.',
    watcher = 'VIGIA DE LONGO ALCANCE.',
    regent = 'COMANDA O RITO.',
    crawler = 'INVESTE EM LINHA.',
    husk = 'FRÁGIL, MAS VINGATIVO.',
}

-- Small soul-heart menu cursor, in the Undertale spirit.
local function heart(x, y, u)
    color(C.red)
    for ry, row in ipairs({'XX.XX', 'XXXXX', '.XXX.', '..X..'}) do
        for rx = 1, #row do
            if row:sub(rx, rx) == 'X' then
                G.rectangle('fill', x + (rx - 1) * u, y + (ry - 1) * u, u, u)
            end
        end
    end
end

-- A cena de batalha é desenhada do zero — o renderer da sala de exploração
-- não é reaproveitado. Layout em três faixas: palco do inimigo estilo
-- Undertale em cima (sprite grande, nome, vida, intenção anunciada), o
-- tabuleiro largo estilo Fractured But Whole no meio (grade assada em canvas
-- + moldura de pedra) e a barra de comandos no HUD.
-- Leitura real-time da unidade (COMBATE_MERGE): o aviso mora no componente
-- enemy — state 'warn' carrega a promessa em a.cells e o modo do golpe em
-- a.mode ('shot'/'dash'/'cross'/'bite'/'mark'/'dual'/'summon' + os autorais
-- dos chefes 'hammer'/'push'/'jet'/'shove'). Glifo,
-- rótulo e tinta derivam da promessa armada, nunca de um turno.
local warnGlyph = {shot = 'shoot', dual = 'shoot', dash = 'dash',
    cross = 'ritual', bite = 'dash', mark = 'sow', summon = 'burst',
    hammer = 'hammer', push = 'push', jet = 'jet', shove = 'shove'}
local warnLabels = {shot = 'DISPARO EM LINHA', dual = 'DISPARO DUPLO',
    dash = 'INVESTIDA', cross = 'SARAIVADA EM CRUZ', bite = 'BOTE',
    mark = 'MARCA ESPINHO', summon = 'INVOCAÇÃO',
    hammer = 'QUEDA DO MARTELO', push = 'VARA NO CAIXOTE',
    jet = 'JATO DO CANAL', shove = 'PRENSA DO BASTÃO'}
local function enemyReadout(e)
    local a = e and e.enemy or nil
    if not a then return 'hold', 'AGUARDA', C.muted end
    if a.state == 'warn' then
        local kind = warnGlyph[a.mode] or 'hold'
        -- Disparo, marca, invocação e o deslize da vara leem ouro; o jato
        -- lê azul de canal e a queda do martelo, brasa — a tabela mora em
        -- warnTint para o chão e o palco concordarem.
        local tint = warnTint[a.mode] or C.red
        if a.mode == 'dash' then
            -- A investida que atravessa cobertura (célula com impact) lê
            -- brasa de queda, igual ao demolish do modelo antigo.
            for _, cell in ipairs(a.cells) do
                if cell.impact then kind, tint = 'demolish', Pal.ember break end
            end
        end
        return kind, warnLabels[a.mode] or 'PREPARA GOLPE', tint
    end
    if a.state == 'dash' or a.state == 'volley' then
        return 'dash', 'RESOLVE O GOLPE', C.red
    end
    -- 'wait' é o respiro do fecho de fase: a unidade segurou o passo e a
    -- arena abre a vaga — lê-se jade como quem baixou a guarda.
    if a.state == 'wait' then return 'hold', 'RESPIRA', C.jade end
    if a.state == 'retreat' then return 'move', 'RECUA', C.muted end
    if a.state == 'dormant' then return 'hold', 'DORME', C.muted end
    if a.state == 'calmed' then return 'hold', 'ACALMADO', C.jade end
    if a.state == 'exposed' then return 'hold', 'EXPOSTO', C.gold end
    if a.state == 'recover' then return 'hold', 'RECUPERA', C.muted end
    return 'hold', 'ESPREITA', C.muted
end

-- Pilar do tabuleiro na mesma linguagem de PixelWorld.wall: base assentada,
-- fuste com faces distintas, capitel, filete de ouro e runa. Os pips acesos
-- continuam contando os golpes até o desabamento.
local function boardPillar(tile)
    local x, y = (tile.x - .5) * 32, (tile.y - .5) * 32
    local st = Pal.stone
    -- Sombra de contato dithered e base assentada.
    PixelArt.ditherEllipse(x, y + 11, 15, 6, Pal.ink, .75)
    PixelArt.ditherEllipse(x, y + 11, 10, 4, Pal.ink, .9)
    color(st.dark); G.rectangle('fill', x - 11, y + 6, 22, 6)
    color(st.base); G.rectangle('fill', x - 10, y + 4, 20, 4)
    color(st.light); G.rectangle('fill', x - 10, y + 4, 19, 1)
    color(Pal.gold.dark); G.rectangle('fill', x - 9, y + 3, 16, 1)
    -- Fuste: contorno de tinta, face média, luz à esquerda, sombra e veio.
    color(Pal.ink); G.rectangle('fill', x - 8, y - 19, 16, 24)
    color(st.base); G.rectangle('fill', x - 7, y - 18, 14, 22)
    color(st.light); G.rectangle('fill', x - 6, y - 17, 3, 20)
    color(st.dark); G.rectangle('fill', x + 4, y - 17, 3, 21)
    color(st.dark); G.rectangle('fill', x - 1, y - 14, 2, 18)
    -- Capitel e filete de ouro, como no pilar da exploração.
    color(st.dark); G.rectangle('fill', x - 9, y - 20, 18, 5)
    color(st.base); G.rectangle('fill', x - 10, y - 24, 20, 5)
    color(st.light); G.rectangle('fill', x - 8, y - 26, 16, 2)
    color(st.edge); G.rectangle('fill', x - 8, y - 25, 14, 1)
    color(Pal.gold.base); G.rectangle('fill', x - 8, y - 21, 16, 1)
    color(Pal.gold.light); G.rectangle('fill', x - 8, y - 20, 2, 2)
    color(Pal.gold.dark); G.rectangle('fill', x - 8, y + 4, 16, 2)
    color(Pal.gold.base); G.rectangle('fill', x - 7, y + 4, 12, 1)
    -- Runa central pequena, mesma mão das paredes cerimoniais.
    color(Pal.gold.base, .8)
    pixelLine(x, y - 10, x + 2, y - 8); pixelLine(x + 2, y - 8, x, y - 6)
    pixelLine(x, y - 6, x - 2, y - 8); pixelLine(x - 2, y - 8, x, y - 10)
    -- Pips acesos = golpes que ainda faltam para o pilar desabar.
    for i = 1, tile.hits or 0 do
        color(Pal.gold.light); G.rectangle('fill', x - 7 + (i - 1) * 7, y + 8, 4, 3)
    end
end

-- O palco é desenhado em espaço de vista (unidades de canvas ancoradas na
-- faixa reservada acima do canvas): nunca sai da tela com a rolagem da
-- câmera. Altura compacta para o sprite caber em escala inteira.
Render.battleStageH = 68
-- Fundo estático do palco do inimigo: moldura de pedra, recorte do mundo
-- da região e divisórias. Assa uma vez por batalha — só retrato, vida e
-- intenção redesenham por frame.
local function stageBg(battle, pw, h)
    -- Painel de pedra do palco: corpo em tinta, face em pedra escura, filete
    -- duplo (pedra clara fora, ouro velho dentro) e cantos entalhados.
    local px0, cx = 0, 172
    color(Pal.abyss, .97); G.rectangle('fill', px0 - 2, 4, pw + 4, h - 4)
    color(Pal.stone.dark); G.rectangle('fill', px0 - 1, 3, pw + 2, h - 6)
    color(Pal.ink, .96); G.rectangle('fill', px0, 4, pw, h - 8)
    border(px0, 4, pw, h - 8, Pal.stone.base, .9)
    border(px0 + 2, 6, pw - 4, h - 12, Pal.gold.dark, .65)
    for _, c in ipairs({{px0 + 2, 6}, {px0 + pw - 5, 6}, {px0 + 2, h - 11}, {px0 + pw - 5, h - 11}}) do
        color(Pal.gold.base); G.rectangle('fill', c[1], c[2], 3, 3)
        color(Pal.gold.light); G.rectangle('fill', c[1], c[2], 1, 1)
    end
    -- A janela central do palco é um recorte do mundo onde a batalha
    -- começou: colina → noite com lua e crista; refúgio → parede quente
    -- com lampião. A criatura não aparece num cartaz, está de pé no lugar.
    local vx0, vw = cx - 32, 64
    local vh = h - 16
    local region = battle.snapshot and battle.snapshot.region or 'colina'
    if region == 'hub' then
        local Rw = Pal.regions.hub
        color(Rw.wall.faceDark); G.rectangle('fill', vx0, 8, vw, math.floor(vh * .72))
        color(Rw.wall.mortar); G.rectangle('fill', vx0, 8, vw, 2)
        for i = 0, 2 do
            color(Rw.wall.face, .8); G.rectangle('fill', vx0 + 8 + i * 24, 8, 1, math.floor(vh * .72))
        end
        -- Lampião à esquerda: a mesma fonte quente do pátio.
        PixelArt.ditherEllipse(cx - 20, 20, 13, 11, Pal.ember, .3)
        color(Pal.emberLight); G.rectangle('fill', cx - 22, 16, 3, 5)
        color(Pal.ember, .7); G.rectangle('fill', cx - 24, 14, 7, 2)
        local vgy = 8 + math.floor(vh * .72)
        color(Rw.floor.base); G.rectangle('fill', vx0, vgy, vw, 8 + vh - (vgy - 8))
        color(Rw.floor.shadow); G.rectangle('fill', vx0, vgy, vw, 1)
    elseif region == 'oficinas' then
        -- Parede de ferro enegrecido + fornalha acesa à direita: brasa,
        -- bancada de trabalho em primeiro plano.
        local Rw = Pal.regions.oficinas
        color(Rw.wall.faceDark); G.rectangle('fill', vx0, 8, vw, math.floor(vh * .72))
        color(Rw.wall.mortar); G.rectangle('fill', vx0, 8, vw, 2)
        for i = 0, 2 do
            color(Rw.wall.face, .8); G.rectangle('fill', vx0 + 10 + i * 24, 8, 1, math.floor(vh * .72))
        end
        -- Boca de fornalha terrena: retângulo largo emoldurado de tijolo,
        -- chama baixa e longa — nunca o disco pontual de uma vela.
        color(Rw.wall.brick); G.rectangle('fill', cx + 12, 14, 22, 14)
        color(Rw.wall.cap); G.rectangle('fill', cx + 12, 14, 22, 1)
        color(Pal.ink); G.rectangle('fill', cx + 15, 17, 16, 9)
        color(Rw.petal); G.rectangle('fill', cx + 16, 18, 14, 7)
        color(Pal.ember); G.rectangle('fill', cx + 17, 20, 12, 5)
        color(Pal.emberLight); G.rectangle('fill', cx + 19, 21, 8, 3)
        color(Pal.white); G.rectangle('fill', cx + 21, 22, 4, 2)
        PixelArt.dither(cx + 14, 15, 18, 3, Pal.ember, .25)
        local vgy = 8 + math.floor(vh * .72)
        color(Rw.wood.dark); G.rectangle('fill', vx0 + 6, vgy - 10, 30, 3)
        color(Rw.wood.base); G.rectangle('fill', vx0 + 6, vgy - 10, 30, 1)
        color(Rw.wood.dark); G.rectangle('fill', vx0 + 9, vgy - 7, 2, 7)
        G.rectangle('fill', vx0 + 31, vgy - 7, 2, 7)
        color(Rw.floor.base); G.rectangle('fill', vx0, vgy, vw, 8 + vh - (vgy - 8))
        color(Rw.floor.shadow); G.rectangle('fill', vx0, vgy, vw, 1)
    elseif region == 'mercado' then
        -- Toldo remendado a riscas no topo da janela + banca à esquerda:
        -- ocre quente sob luz aberta.
        local Rw = Pal.regions.mercado
        color(Rw.wall.face); G.rectangle('fill', vx0, 8, vw, math.floor(vh * .72))
        color(Rw.wall.faceDark); G.rectangle('fill', vx0, 8 + math.floor(vh * .72) - 4, vw, 4)
        for i = 0, 7 do
            color(i % 2 == 0 and Rw.cloth.base or Rw.petal)
            G.rectangle('fill', vx0 + i * 8, 8, 8, 10)
            color(Pal.ink, .3); G.rectangle('fill', vx0 + i * 8, 8, 8, 1)
        end
        for i = 0, 7 do
            color(i % 2 == 0 and Rw.cloth.light or Rw.cloth.base)
            G.rectangle('fill', vx0 + i * 8, 17 + (i % 2), 8, 2)
        end
        local vgy = 8 + math.floor(vh * .72)
        color(Rw.wood.base); G.rectangle('fill', vx0 + 4, vgy - 14, 26, 14)
        color(Rw.wood.light); G.rectangle('fill', vx0 + 4, vgy - 14, 26, 2)
        color(Rw.wood.dark); G.rectangle('fill', vx0 + 4, vgy - 8, 26, 1)
        color(Rw.cloth.dark); G.rectangle('fill', vx0 + 7, vgy - 17, 8, 3)
        color(Rw.floor.base); G.rectangle('fill', vx0, vgy, vw, 8 + vh - (vgy - 8))
        color(Rw.floor.shadow); G.rectangle('fill', vx0, vgy, vw, 1)
    elseif region == 'reservatorio' then
        -- Canal de água parada + régua de nível na parede de calcário:
        -- faixa úmida com musgo na junção.
        local Rw = Pal.regions.reservatorio
        color(Rw.wall.brick); G.rectangle('fill', vx0, 8, vw, math.floor(vh * .58))
        color(Rw.wall.cap); G.rectangle('fill', vx0, 8, vw, 2)
        color(Rw.moss); G.rectangle('fill', vx0, 8 + math.floor(vh * .58) - 3, vw, 3)
        -- Régua de nível: poste com marcas — enche/esvazia se lê na parede.
        color(Rw.wood.light); G.rectangle('fill', vx0 + 8, 10, 2, math.floor(vh * .55))
        for i = 0, 5 do
            color(Rw.wall.cap); G.rectangle('fill', vx0 + 8, 12 + i * 7, 5, 1)
        end
        local wy = 8 + math.floor(vh * .58)
        color(Rw.cloth.dark); G.rectangle('fill', vx0, wy, vw, 8 + vh - (wy - 8))
        color(Rw.cloth.base); G.rectangle('fill', vx0, wy, vw, 2)
        color(Rw.cloth.light, .6); G.rectangle('fill', vx0 + 4, wy + 5, 18, 1)
        G.rectangle('fill', vx0 + 36, wy + 9, 14, 1)
        -- Comporta à direita: venezianas de ferragem.
        for i = 0, 3 do
            color(Rw.wood.base); G.rectangle('fill', vx0 + vw - 14, wy - 8 + i * 5, 10, 3)
        end
    elseif region == 'saloes' then
        -- Cortinas de teatro abertas nos cantos + vela acesa: pedra vinho,
        -- madeira de palco sob a criatura.
        local Rw = Pal.regions.saloes
        color(Rw.wall.faceDark); G.rectangle('fill', vx0, 8, vw, math.floor(vh * .72))
        color(Rw.wall.cap); G.rectangle('fill', vx0, 8, vw, 2)
        for i = 0, 5 do
            local sx = vx0 + i * 5
            color(i % 2 == 0 and Rw.cloth.base or Rw.cloth.dark)
            G.rectangle('fill', sx, 8, 5, math.floor(vh * .5) + (i % 2) * 4)
        end
        for i = 0, 5 do
            local sx = vx0 + vw - 30 + i * 5
            color(i % 2 == 0 and Rw.cloth.dark or Rw.cloth.base)
            G.rectangle('fill', sx, 8, 5, math.floor(vh * .5) + (i % 2) * 4)
        end
        -- Candelabro pontual: haste fina, chama miúda e quente — lê-se
        -- pequeno, nunca como a boca de uma fornalha.
        color(Rw.petal); G.rectangle('fill', cx + 22, 20, 1, 12)
        color(Rw.petal); G.rectangle('fill', cx + 19, 31, 7, 2)
        color(Pal.emberLight); G.rectangle('fill', cx + 22, 16, 2, 4)
        color(Pal.white); G.rectangle('fill', cx + 22, 18, 1, 2)
        PixelArt.ditherEllipse(cx + 22, 20, 7, 7, Pal.ember, .3)
        local vgy = 8 + math.floor(vh * .72)
        color(Rw.floor.base); G.rectangle('fill', vx0, vgy, vw, 8 + vh - (vgy - 8))
        color(Rw.floor.dark); G.rectangle('fill', vx0, vgy, vw, 1)
        for i = 1, 6 do
            color(Rw.floor.dark, .6); G.rectangle('fill', vx0 + i * 10, vgy, 1, 8 + vh - (vgy - 8))
        end
    else
    color(Pal.sky.mid); G.rectangle('fill', vx0, 8, vw, math.floor(vh * .42))
    color(Pal.sky.low); G.rectangle('fill', vx0, 8 + math.floor(vh * .42), vw, math.floor(vh * .30))
    color(Pal.sky.horizon); G.rectangle('fill', vx0, 8 + math.floor(vh * .72), vw, 8)
    PixelArt.dither(vx0, 8 + math.floor(vh * .42) - 2, vw, 3, Pal.sky.low, .3)
    PixelArt.dither(vx0, 8 + math.floor(vh * .72) - 2, vw, 3, Pal.sky.horizon, .3)
    -- Crista da colina com lápides miúdas e a lua baixa à esquerda — o
    -- mesmo enquadramento do palco lá embaixo.
    local vgy = 8 + math.floor(vh * .72) + 6
    color(Pal.ridge.near); G.rectangle('fill', vx0, vgy, vw, 8 + vh - (vgy - 8))
    color(Pal.ridge.far); G.rectangle('fill', vx0, vgy - 3, vw, 3)
    color(Pal.ridge.lit, .8); G.rectangle('fill', vx0, vgy - 3, vw, 1)
    for i = 0, 3 do
        local gx = vx0 + 6 + i * 16
        color(Pal.ridge.near); G.rectangle('fill', gx, vgy - 8, 3, 6)
        color(Pal.ridge.lit, .7); G.rectangle('fill', gx, vgy - 8, 3, 1)
    end
    PixelArt.ditherEllipse(cx - 18, 19, 12, 10, Pal.moon.halo, .3)
    for j = -6, 6 do
        local half = math.floor(math.sqrt(math.max(0, 36 - j * j)))
        color(Pal.moon.disc); G.rectangle('fill', cx - 18 - half, 18 + j, math.max(1, half * 2), 1)
        local sh = math.floor(math.sqrt(math.max(0, 9 - (j + 3) * (j + 3))))
        if half > 2 and sh > 0 then
            color(Pal.moon.shade)
            G.rectangle('fill', cx - 18 + half - sh - 3, 18 + j, sh, 1)
        end
    end
    -- Faixa de palco sob a criatura: a terra da crista continua.
    color(Pal.earth.base); G.rectangle('fill', vx0, vgy + 6, vw, 8 + vh - (vgy - 8) - 6)
    PixelArt.dither(vx0, vgy + 4, vw, 3, Pal.earth.mound, .3)
    end
    -- Divisórias verticais entalhadas separam nome / retrato / intenção.
    color(Pal.stone.dark); G.rectangle('fill', cx - 34, 8, 1, h - 16)
    G.rectangle('fill', cx + 33, 8, 1, h - 16)
    color(Pal.gold.dark, .6); G.rectangle('fill', cx - 33, 8, 1, h - 16)
    G.rectangle('fill', cx + 34, 8, 1, h - 16)
    -- Estrado do retrato: poça fria + plataforma de pedra.
    PixelArt.ditherEllipse(cx, h - 9, 17, 5, Pal.sky.low, .30)
    color(Pal.stone.dark); G.ellipse('fill', cx, h - 8, 15, 4)
    color(Pal.stone.base); G.ellipse('fill', cx, h - 9, 12, 3)
end

local function enemyStage(self, battle, cx)
    local h = Render.battleStageH
    local px0, pw = math.floor(cx) - 172, 344
    -- O fundo assa uma vez por batalha e por região — o retrato respira por
    -- cima de um lugar fixo, não de um cartaz repintado por frame.
    if not battle.stageCanvas then
        local c = G.newCanvas(pw + 8, h + 6, {dpiscale = 1})
        c:setFilter('nearest', 'nearest')
        local prev = G.getCanvas()
        G.push('all'); G.setCanvas(c); G.clear(0, 0, 0, 0)
        G.origin(); G.translate(4, 3)
        stageBg(battle, pw, h)
        G.pop(); G.setCanvas(prev)
        battle.stageCanvas = c
    end
    color(C.white); G.draw(battle.stageCanvas, px0 - 4, -3)
    -- Acentos vivos sobre o fundo assado: a fornalha respira e a vela treme
    -- — luz rasa por frame, nunca repinta o cenário do palco.
    local stgRegion = battle.snapshot and battle.snapshot.region or 'colina'
    if not self.reducedMotion then
        if stgRegion == 'saloes' then
            local fl = .5 + .5 * math.sin(self.time * 9.1)
            color(Pal.emberLight, .55 + .45 * fl)
            G.rectangle('fill', px0 + 193, 14 + (fl > .7 and 0 or 1), 2, 4)
            PixelArt.ditherEllipse(px0 + 194, 19, 9, 7, Pal.ember, .08 + .08 * fl)
        elseif stgRegion == 'oficinas' then
            local fl = .5 + .5 * math.sin(self.time * 3.7)
            color(Pal.emberLight, .3 + .4 * fl)
            G.rectangle('fill', px0 + 191, 21, 8, 3)
            PixelArt.ditherEllipse(px0 + 195, 24, 15, 8, Pal.ember, .07 + .07 * fl)
        end
    end
    cx = math.floor(cx)
    -- O palco é o destaque sob a lente: durante a inspeção mostra a
    -- unidade consultada; fora dela, a primeira ameaça viva da fila.
    local e = battle.inspect and battle.inspect > 1 and battle.enemies[battle.inspect - 1]
        or battle:liveEnemies()[1]
    -- Sem ameaça viva a lente fica vazia: nada de retrato de quem já
    -- partiu poupado ou caiu — a fila já conta essa história.
    local inspecting = battle.mode == 'inspect' and battle.inspect and battle.inspect > 1
    if not e or (not inspecting and (e.health.current <= 0 or e.spared)) then return end
    -- Zona esquerda: nome da criatura sobre barra de vida segmentada com
    -- terminais entalhados — cada ponto de vida é um elo de pedra.
    text(self.worldFonts.tiny, e.name or 'INIMIGO', px0 + 12, 10, C.gold)
    local hpw = 100
    local segs = e.health.max
    local segW = math.max(3, math.floor(hpw / math.max(1, segs)) - 1)
    for i = 1, segs do
        local sx = px0 + 12 + (i - 1) * (segW + 1)
        color(Pal.stone.dark); G.rectangle('fill', sx, 24, segW, 5)
        color(Pal.ink); G.rectangle('fill', sx, 29, segW, 1)
        if i <= math.max(0, e.health.current) then
            color(e.health.current <= 2 and C.red or Pal.danger)
            G.rectangle('fill', sx, 24, segW, 4)
            color(C.white, .4); G.rectangle('fill', sx, 24, segW, 1)
        end
    end
    color(Pal.gold.dark); G.rectangle('fill', px0 + 10, 23, 1, 7)
    G.rectangle('fill', px0 + 12 + segs * (segW + 1), 23, 1, 7)
    if e.health.current <= 0 then
        text(self.worldFonts.tiny, 'DERRUBADA', cx - 40, 34, C.muted, 80, 'center')
        return
    end
    -- Zona direita: glifo do estado real-time sobre rótulo — 'warn' lê o
    -- modo armado, os demais estados leem a postura. Forma antes da cor.
    local kind, label, gc = enemyReadout(e)
    local gx, gy = px0 + pw - 62, 22
    color(Pal.stone.dark); G.rectangle('fill', gx - 11, gy - 10, 21, 15)
    border(gx - 11, gy - 10, 21, 15, gc, .8)
    if kind == 'dash' then
        chevron(gx + 2, gy - 2, 1, 0, gc)
    elseif kind == 'demolish' then
        -- A investida que come cobertura: chevron + a laje que atravessa.
        chevron(gx - 1, gy - 2, 1, 0, gc)
        color(gc); G.rectangle('fill', gx + 4, gy - 6, 3, 9)
    elseif kind == 'shoot' then
        color(gc)
        pixelLine(gx - 6, gy - 2, gx - 3, gy - 2); pixelLine(gx + 3, gy - 2, gx + 6, gy - 2)
        pixelLine(gx, gy - 7, gx, gy - 5); pixelLine(gx, gy + 1, gx, gy + 3)
        G.rectangle('fill', gx, gy - 3, 1, 1)
    elseif kind == 'move' then
        color(gc); G.rectangle('fill', gx - 4, gy - 4, 3, 4); G.rectangle('fill', gx + 1, gy - 2, 3, 4)
    elseif kind == 'sow' then
        -- Pontas de espinho sobre a linha de solo — a banda plantada.
        thornTip(gx - 4, gy + 4, 6, gc)
        thornTip(gx + 4, gy + 5, 5, gc)
        color(gc, .45); G.rectangle('fill', gx - 8, gy + 4, 16, 1)
    elseif kind == 'ritual' then
        -- Cruz rezada: anel + braços — o rito ainda não estourou.
        color(gc)
        G.ellipse('line', gx, gy - 2, 7, 7)
        pixelLine(gx - 7, gy - 2, gx + 7, gy - 2); pixelLine(gx, gy - 9, gx, gy + 5)
    elseif kind == 'burst' then
        -- Explosão anunciada: X de blast + núcleo claro.
        color(gc)
        pixelLine(gx - 6, gy - 8, gx + 6, gy + 4); pixelLine(gx + 6, gy - 8, gx - 6, gy + 4)
        color(Pal.emberLight); G.rectangle('fill', gx - 1, gy - 3, 2, 2)
    elseif kind == 'hammer' or kind == 'push' or kind == 'jet' or kind == 'shove' then
        -- Warns autorais dos chefes: o glifo de pip (7x7) dobra de tamanho
        -- no palco — mesma forma do chão, lida de longe.
        G.push(); G.translate(gx - 7, gy - 9); G.scale(2)
        intentGlyph(kind, 0, 0, gc)
        G.pop()
    else
        diamond(gx, gy - 2, 3, gc)
    end
    text(self.worldFonts.tiny, label, px0 + pw - 152, 42, gc, 140, 'right')
    -- Retrato vivo sobre o estrado assado no fundo. Quando a ficha do
    -- inimigo tem linha de emoção assada, o palco troca o corpo inteiro
    -- pelo close-up do estado (mapa do Pena via Barks.exprFor).
    -- Casulo dormindo troca o corpo: enquanto o estado é 'dormant', o
    -- palco lê o fardo fechado, não a mortalha acordada.
    local warns = e.enemy.state == 'warn' or e.enemy.state == 'dash'
        or e.enemy.state == 'volley'
    local sheetKind = (e.enemy.kind == 'husk' and e.enemy.state == 'dormant')
        and 'huskCocoon' or e.enemy.kind
    local sheet = self.actors.sheets[sheetKind]
        or self.actors.sheets['npc_' .. e.enemy.kind] or self.actors.sheets.dasher
    local Barks = require('src.battle_barks')
    local situation = e.spared and 'spared' or (warns and 'announce' or 'act')
    local emo = Barks.exprFor(e.enemy.kind, situation)
    if sheet.portraits and sheet.portraits[emo] then
        local pc = sheet.portraits[emo]
        local q = G.newQuad(pc[1] - 10, pc[2] - 7, 40, 48, sheet.image:getDimensions())
        color(C.white); G.draw(sheet.image, q, cx, h - 9, 0, 1, 1, 20, 44)
        return
    end
    local dir = e.facing.dx > 0 and 1 or e.facing.dy > 0 and 2 or e.facing.dx < 0 and 3 or 4
    local action = e.enemy.state == 'warn' and 'warn' or 'idle'
    local anim = sheet.animations[action] and sheet.animations[action][dir]
        or sheet.animations.idle[2]
    local t = self.reducedMotion and 0 or self.time % anim.totalDuration
    local acc, q = 0, anim.frames[1]
    for i, f in ipairs(anim.frames) do
        if t < acc + anim.durations[i] then q = f break end
        acc = acc + anim.durations[i]
    end
    local _, _, fw, fh = q:getViewport()
    color(C.white)
    G.draw(sheet.image, q, cx, h - 9, 0, 1, 1, fw / 2, fh)
end

-- Ponte para o render HD (Fase 4): hd_world desenha telegrafos e
-- marcadores da arena com os MESMOS helpers do legado — a leitura tática
-- é idêntica, só escala por 2 (célula 32→64). Tabela viva: funções são
-- referências, não cópias.
Render.BattleDraw = {
    warningCell = warningCell, warnCellSpec = warnCellSpec,
    warnTint = warnTint, intentGlyph = intentGlyph,
    enemyReadout = enemyReadout, fleeExitMark = fleeExitMark,
    chevron = chevron, thornTip = thornTip, diamond = diamond,
    arrow = arrow, border = border, color = color, text = text,
    round = round, pixelLine = pixelLine,
    boardPillar = boardPillar, boardCrate = boardCrate,
}

function Render:battleScene(campaign)
    local battle = campaign.battle
    local room = battle.room
    -- O tabuleiro assa uma vez; um pilar que desaba revela o piso embaixo.
    -- A região de origem viaja no snapshot: o vazio da arena é do lugar
    -- onde a batalha começou, não um cenário genérico.
    if not battle.floorCanvas then
        battle.floorCanvas = PixelArt.bakeFloor(room, campaign.seed, 'board',
            battle.snapshot and battle.snapshot.region)
    end
    color(C.white); G.draw(battle.floorCanvas, -64, -64)

    -- Moldura do tabuleiro: faixa de pedra com cantos dourados marca a área
    -- tática — o resto da sala fica como palco sobre o vazio.
    if not battle.frame then
        local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
        for _, tile in pairs(room.tiles) do
            if tile.ground == 'floor' and not tile.protected then
                x1, y1 = math.min(x1, tile.x), math.min(y1, tile.y)
                x2, y2 = math.max(x2, tile.x), math.max(y2, tile.y)
            end
        end
        battle.frame = {x = (x1 - 1) * 32, y = (y1 - 1) * 32,
            w = (x2 - x1 + 1) * 32, h = (y2 - y1 + 1) * 32}
    end
    local f = battle.frame
    -- Meio-fio de pedra com peso: face de topo clara (o luar vem de cima-
    -- esquerda), face externa em sombra, cantos como blocos trabalhados e
    -- embutidos de jade e ouro ao longo dos lados.
    local st = Pal.stone
    color(st.dark); G.rectangle('fill', f.x - 8, f.y - 8, f.w + 16, f.h + 16)
    color(st.base); G.rectangle('fill', f.x - 7, f.y - 7, f.w + 14, f.h + 14)
    -- Face de topo: luz de 2px no alto e à esquerda, borda fina de luz dura.
    color(st.light); G.rectangle('fill', f.x - 7, f.y - 7, f.w + 14, 2)
    G.rectangle('fill', f.x - 7, f.y - 7, 2, f.h + 14)
    color(st.edge); G.rectangle('fill', f.x - 7, f.y - 7, f.w + 14, 1)
    G.rectangle('fill', f.x - 7, f.y - 7, 1, f.h + 14)
    -- Face interna: o lábio interno projeta sombra sobre a primeira laje.
    color(Pal.ink, .55); G.rectangle('fill', f.x - 1, f.y - 1, f.w + 2, 2)
    G.rectangle('fill', f.x - 1, f.y - 1, 2, f.h + 2)
    color(st.dark); G.rectangle('fill', f.x + f.w - 1, f.y + 6, 7, f.h + 1)
    G.rectangle('fill', f.x - 7, f.y + f.h + 5, f.w + 14, 2)
    color(Pal.ink, .6); G.rectangle('fill', f.x - 8, f.y + f.h + 7, f.w + 16, 1)
    G.rectangle('fill', f.x + f.w + 7, f.y - 8, 1, f.h + 16)
    -- Embutidos de jade espaçados no topo do meio-fio, marcas de ouro nos
    -- terços dos lados curtos — ornamento medido, não filete contínuo.
    for i = 0, math.floor(f.w / 64) - 1 do
        local ix = f.x + 24 + i * 64
        color(Pal.jade.dark); G.rectangle('fill', ix, f.y - 5, 8, 2)
        color(Pal.jade.base, .7); G.rectangle('fill', ix + 1, f.y - 5, 6, 1)
        color(Pal.jade.dark); G.rectangle('fill', ix, f.y + f.h + 4, 8, 2)
    end
    for _, sy in ipairs({f.y + math.floor(f.h / 3), f.y + math.floor(f.h * 2 / 3)}) do
        color(Pal.gold.dark); G.rectangle('fill', f.x - 5, sy, 2, 8)
        G.rectangle('fill', f.x + f.w + 3, sy, 2, 8)
    end
    -- Cantos como blocos trabalhados: capitel quadrado com bevel e pip de
    -- ouro gravado — peso de balaustrada, não de linha de debug.
    for _, c in ipairs({{f.x - 10, f.y - 10}, {f.x + f.w + 2, f.y - 10},
            {f.x - 10, f.y + f.h + 2}, {f.x + f.w + 2, f.y + f.h + 2}}) do
        color(Pal.ink); G.rectangle('fill', c[1] - 1, c[2] - 1, 11, 11)
        color(st.base); G.rectangle('fill', c[1], c[2], 9, 9)
        color(st.light); G.rectangle('fill', c[1], c[2], 9, 1); G.rectangle('fill', c[1], c[2], 1, 9)
        color(st.dark); G.rectangle('fill', c[1], c[2] + 8, 9, 1); G.rectangle('fill', c[1] + 8, c[2], 1, 9)
        color(Pal.gold.base); G.rectangle('fill', c[1] + 3, c[2] + 3, 3, 3)
        color(Pal.gold.light); G.rectangle('fill', c[1] + 3, c[2] + 3, 1, 1)
    end
    -- Braseiros de flanco sobre o meio-fio: taça de pedra, carvão e chama
    -- em três tons; a chama tremula salvo com movimento reduzido. As poças
    -- de luz quente já estão assadas no piso (boardDressing).
    local flick = self.reducedMotion and 0 or math.floor(self.time * 9) % 2
    for _, s in ipairs({-1, 1}) do
        local bx = s == -1 and f.x - 9 or f.x + f.w + 9
        local by = f.y + f.h / 2
        PixelArt.ditherEllipse(bx, by + 6, 9, 4, Pal.ink, .6)
        color(st.dark); G.rectangle('fill', bx - 4, by - 1, 9, 7)
        color(st.base); G.rectangle('fill', bx - 3, by - 2, 7, 5)
        color(st.light); G.rectangle('fill', bx - 3, by - 2, 7, 1)
        color(Pal.ink); G.rectangle('fill', bx - 2, by - 3, 5, 2)
        local fy = by - 5 - flick
        color(Pal.ember); G.rectangle('fill', bx - 2, fy, 5, 3)
        color(Pal.emberLight); G.rectangle('fill', bx - 1, fy - 2, 3, 3)
        color(Pal.white, .9); G.rectangle('fill', bx, fy - 3 - flick, 1, 2)
        color(Pal.ember, .6); G.rectangle('fill', bx + 2, fy - 4 + flick, 1, 1)
        -- Fagulha subindo e brilho morno sobre a taça — fogo, não pictograma.
        PixelArt.dither(bx - 3, fy - 8, 7, 4, Pal.ember, .16)
        if not self.reducedMotion then
            local sy = fy - 7 - (self.time * 14 + s * 5) % 6
            color(Pal.emberLight, .7); G.rectangle('fill', bx + (s + flick - 1), sy, 1, 1)
        end
    end

    -- O palco do inimigo não vive mais neste espaço de mundo: fica na faixa
    -- de tela reservada acima do canvas (ver drawCampaign).

    -- Pulso compartilhado dos overlays: ameaças e alcance respiram juntos.
    local pulse = self.reducedMotion and 0 or math.sin(self.time * 5) * .05

    -- Sobreposição de modo: a lente social dos modos de pausa — os ramos
    -- 'aim'/'pillar' e as prévias de slot (bow/guard/pillar/heal) morreram
    -- com o modelo de turnos: menuItems nunca os produz e os stubs
    -- ray/pillarFall/adjacentPillar já não existem em battle.lua.
    if battle.mode == 'act' or battle.mode == 'actlist' or battle.mode == 'mercy' then
        -- Lente de alvo dos modos sociais: coroas de canto em ouro
        -- (AGIR) ou jade (POUPAR) sobre a unidade sob o cursor.
        local list = battle.mode == 'mercy' and battle:spareable() or battle:liveEnemies()
        local idx = battle.mode == 'mercy' and battle.mercyIndex or battle.actTarget
        local u = list and list[math.max(1, math.min(#list, idx or 1))]
        if u then
            local tint = battle.mode == 'mercy' and C.jade or C.gold
            local cx0, cy0 = (u.grid.x - 1) * 32, (u.grid.y - 1) * 32
            -- Anel real sobre o sprite: véu da cor + moldura de 2px +
            -- cantos grossos — visível mesmo em cena cheia de frisos.
            color(tint, .18 + pulse * .1)
            G.rectangle('fill', cx0, cy0, 32, 32)
            color(tint)
            G.rectangle('fill', cx0 - 1, cy0 - 1, 10, 2); G.rectangle('fill', cx0 - 1, cy0 - 1, 2, 10)
            G.rectangle('fill', cx0 + 23, cy0 - 1, 10, 2); G.rectangle('fill', cx0 + 31, cy0 - 1, 2, 10)
            G.rectangle('fill', cx0 - 1, cy0 + 31, 10, 2); G.rectangle('fill', cx0 - 1, cy0 + 23, 2, 10)
            G.rectangle('fill', cx0 + 23, cy0 + 31, 10, 2); G.rectangle('fill', cx0 + 31, cy0 + 23, 2, 10)
            color(tint, .55)
            G.rectangle('fill', cx0 + 10, cy0 - 1, 12, 1); G.rectangle('fill', cx0 + 10, cy0 + 32, 12, 1)
            G.rectangle('fill', cx0 - 1, cy0 + 10, 1, 12); G.rectangle('fill', cx0 + 32, cy0 + 10, 1, 12)
        end
    end
    -- Marcas armadas (semeador/regente): entidades hazard do mundo — uma
    -- faixa com fusível que explode, lida com o mesmo blast dourado do
    -- protótipo. battle.hazards é stub vazio do modelo de turnos.
    for _, e in ipairs(battle:entities()) do
        if e.hazard then
            local prog = 1 - e.hazard.timer / (e.hazard.duration or 1)
            for _, cell in ipairs(e.hazard.cells) do
                warningCell(cell, C.gold, 0, 0, prog, false, 'blast')
            end
        end
    end
    -- Telegrafos real-time (COMBATE_MERGE): o aviso mora no componente
    -- enemy — 'warn' segura a promessa em a.cells com o modo em a.mode;
    -- 'dash'/'volley' resolvem o que já foi anunciado (a prévia nunca
    -- mente). warningCell é a mesma leitura do protótipo: véu que enche
    -- com o progresso + filete + glifo direcional.
    for _, e in ipairs(battle.enemies) do
        local a = e.enemy
        if e.health.current > 0 and a
            and (a.state == 'warn' or a.state == 'dash' or a.state == 'volley') then
            local progress = a.state ~= 'warn' and 1
                or 1 - a.timer / (a.warningDuration or 1)
            local tint = warnTint[a.mode] or C.red
            for i, cell in ipairs(a.cells) do
                if a.state ~= 'dash' or i >= (a.dashIndex or 1) then
                    -- A forma vem do modo armado (warnCellSpec): martelo,
                    -- vara, jato e prensa não leem como shot/dash.
                    local dx, dy, kind = warnCellSpec(a, e, cell, i)
                    warningCell(cell, tint, dx, dy, progress, false, kind)
                    -- Pilar que a investida promete derrubar: queda em jade.
                    for _, fc in ipairs(cell.fall or {}) do
                        warningCell(fc, C.jade, a.dx or 0, a.dy or 0, progress, false, 'fall')
                    end
                end
            end
            -- A vara da Rute promete o caixote de origem também: contorno
            -- discreto + ponta do rumo sobre a peça que vai deslizar.
            if a.state == 'warn' and a.mode == 'push' and a.crateX then
                local cx0, cy0 = (a.crateX - 1) * 32, (a.crateY - 1) * 32
                border(cx0 + 2, cy0 + 2, 28, 28, tint, .5 + progress * .4)
                arrow(cx0 + 16 + (a.pushDx or 0) * 9, cy0 + 16 + (a.pushDy or 0) * 9,
                    a.pushDx or 0, a.pushDy or 0, tint, 3)
            end
            -- A prensa do Beltran fecha o corredor: batente grosso na
            -- última célula anunciada — o deslize para ali.
            if a.state == 'warn' and a.mode == 'shove' and a.cells[1] then
                local lastc = a.cells[#a.cells]
                local lx, ly = (lastc.x - 1) * 32, (lastc.y - 1) * 32
                color(tint)
                if (a.dx or 0) ~= 0 then
                    G.rectangle('fill', lx + (a.dx > 0 and 25 or 4), ly + 6, 3, 20)
                else
                    G.rectangle('fill', lx + 6, ly + (a.dy > 0 and 25 or 4), 20, 3)
                end
            end
            -- Ficha do aviso junto à unidade: o glifo do modo armado — a
            -- ameaça acompanha quem a prometeu, não só o chão debaixo dela.
            local gkind, _, gtint = enemyReadout(e)
            local ux, uy = Render.visualPosition(e)
            local ox, oy = (e.grid.x - .5) * 32 + 20, (e.grid.y - .5) * 32 - 6
            diamond(ox, oy, 7, C.ink)
            diamond(ox, oy, 7, gtint, 'line')
            intentGlyph(gkind, ox - 3, oy - 3, gtint)
            intentGlyph(gkind, ux - 19, uy - 53, gtint)
        end
    end
    -- Marcadores sob os pés: o estado real vira glifo — chevron na
    -- investida, retícula no disparo, cruz na saraivada, farpa na marca;
    -- jade no acalmado, ouro no exposto, tinta apagada nos demais.
    for _, e in ipairs(battle.enemies) do
        if e.health.current > 0 and e.enemy then
            local gx, gy = (e.grid.x - .5) * 32, (e.grid.y - .5) * 32 + 13
            local a = e.enemy
            local kind, _, tint = enemyReadout(e)
            if kind == 'dash' or kind == 'demolish' then
                chevron(gx + (a.dx or 0) * 3, gy + (a.dy or 0) * 3,
                    a.dx or 0, a.dy or 0, tint)
            elseif kind == 'shoot' then
                color(tint)
                pixelLine(gx - 5, gy, gx - 2, gy); pixelLine(gx + 2, gy, gx + 5, gy)
                pixelLine(gx, gy - 5, gx, gy - 2); pixelLine(gx, gy + 2, gx, gy + 5)
                G.rectangle('fill', gx, gy, 1, 1)
            elseif kind == 'move' then
                color(tint)
                G.rectangle('fill', gx - 3, gy - 2, 2, 3); G.rectangle('fill', gx + 1, gy, 2, 3)
            elseif kind == 'sow' then
                -- Farpa miúda: a marca do semeador é de espinho, não de golpe.
                thornTip(gx, gy + 3, 4, tint)
            elseif kind == 'ritual' or kind == 'burst' then
                -- Cruz da saraivada ou X da invocação — mesma leitura do
                -- telegrafo de chão, em miniatura.
                color(tint)
                if kind == 'burst' then
                    pixelLine(gx - 3, gy - 3, gx + 3, gy + 3)
                    pixelLine(gx + 3, gy - 3, gx - 3, gy + 3)
                else
                    pixelLine(gx - 3, gy, gx + 3, gy); pixelLine(gx, gy - 3, gx, gy + 3)
                end
            elseif kind == 'hammer' or kind == 'push' or kind == 'jet'
                or kind == 'shove' then
                -- Warns autorais dos chefes sob os pés: o mesmo pip de 7x7
                -- do selo — forma consistente em todas as leituras.
                intentGlyph(kind, gx - 3, gy - 3, tint)
            else
                diamond(gx, gy, 3, tint)
            end
        end
    end
    -- §6 — travessia da fuga: a saída acesa na borda oposta lê um portal
    -- de jade aberto para fora do meio-fio. Cobre o contrato da arena
    -- (battle.exitCell + flee.edge) e unidades com rota própria
    -- (enemy.state 'flee' + exitCell, se a máquina um dia a produzir).
    do
        local exits = {}
        if battle.fleeing and battle.exitCell then
            exits[#exits + 1] = {cell = battle.exitCell,
                edge = battle.flee and battle.flee.edge}
        end
        for _, e in ipairs(battle.enemies) do
            local a = e.enemy
            if a and a.state == 'flee' and a.exitCell then
                exits[#exits + 1] = {cell = a.exitCell, edge = a.exitEdge}
            end
        end
        for _, ex in ipairs(exits) do
            fleeExitMark(ex.cell, ex.edge, f, pulse)
        end
    end
    local pgm = (battle.player.grid.x - .5) * 32
    local pgmy = (battle.player.grid.y - .5) * 32 + 13
    diamond(pgm, pgmy, 5, C.ink)
    diamond(pgm, pgmy, 4, C.jade)
    diamond(pgm, pgmy - 1, 1, C.white)
    -- Arraste do empurrão (Beltran): riscas de deslize atrás da jogadora
    -- enquanto o slide corre + poeira no fim — leitura de deslocamento
    -- forçado, não de passo livre.
    do
        local pa = battle.player
        if pa.shoveT and pa.shoveT > 0 and (pa.shoveDx or pa.shoveDy) then
            local ux, uy = Render.visualPosition(pa)
            local a = math.min(.85, pa.shoveT * 2)
            local dx, dy = pa.shoveDx or 0, pa.shoveDy or 0
            for j = -1, 1 do
                local len = 8 + (j + 1) * 3
                local aa = a * (1 - (j + 1) * .2)
                color(Pal.stone.light, aa)
                if dx ~= 0 then
                    local bx = ux - dx
                    local yy = math.floor(uy + 6 + j * 3)
                    pixelLine(math.floor(bx - len), yy, math.floor(bx - 3), yy)
                else
                    local by = uy - dy
                    local xx = math.floor(ux - 8 + j * 4)
                    pixelLine(xx, math.floor(by - len), xx, math.floor(by - 3))
                end
            end
            PixelArt.ditherEllipse(ux - dx * 6, uy - dy * 6 + 7, 8, 3, Pal.stone.light, a * .4)
        end
    end
    -- Profundidade: peças e atores juntos, ordenados pela base.
    local layers = {}
    for _, tile in pairs(room.tiles) do
        if tile.piece == 'pillar' or tile.piece == 'crate' then
            layers[#layers + 1] = {piece = tile, depth = tile.y * 32}
        end
    end
    for _, e in ipairs(battle.enemies) do
        local x, y = Render.visualPosition(e)
        layers[#layers + 1] = {entity = e, depth = y, x = x}
    end
    -- Projéteis são entidades do mundo Concord (flecha do arco, bolts dos
    -- inimigos) — fora da lista canônica, entram pela varredura do mundo.
    for _, e in ipairs(battle:entities()) do
        if e.projectile then
            local x, y = Render.visualPosition(e)
            layers[#layers + 1] = {entity = e, depth = y, x = x}
        end
    end
    local px2, py2 = Render.visualPosition(battle.player)
    layers[#layers + 1] = {entity = battle.player, depth = py2, x = px2}
    table.sort(layers, function(a, b)
        if a.depth ~= b.depth then return a.depth < b.depth end
        return (a.x or 0) < (b.x or 0)
    end)
    for _, layer in ipairs(layers) do
        if layer.piece then
            if layer.piece.piece == 'crate' then boardCrate(layer.piece)
            else boardPillar(layer.piece) end
        elseif layer.entity.projectile then self:projectile(layer.entity)
        else self:actor(layer.entity, campaign) end
    end
    self.actors:drawDeaths(self, campaign)
    self:effects()
    -- Brasas à deriva sobre a arena: densas perto do medalhão, esparsas na
    -- borda — a luz cerimonial vem do centro.
    if not self.reducedMotion then
        for i = 1, 14 do
            local bx = f.x + ((i * 53) % f.w)
            local by = f.y + ((i * 37) % f.h)
            local mx = bx + math.sin(self.time * .7 + i * 1.9) * 6
            local my = by + math.sin(self.time * .5 + i * 2.3) * 4 - (self.time * 2.2 + i * 9) % 16
            local dc = math.sqrt((bx - (f.x + f.w / 2)) ^ 2 + (by - (f.y + f.h / 2)) ^ 2)
            local a = math.max(0, .34 - dc / (f.w * .55)) * (math.sin(self.time * 1.1 + i * 1.3) * .5 + .5)
            if a > .03 then
                color(i % 3 == 0 and Pal.gold.light or Pal.jade.light, a)
                G.rectangle('fill', round(mx), round(my), i % 4 == 0 and 2 or 1, 1)
            end
        end
    end
    -- Balões de fala dos barks: placa de osso com ponta voltada à unidade.
    -- verbal=false não fala — a mesma placa, só que vazada de tinta com o
    -- gesto entre parênteses (Pena já escreve ( ... ) nos dados).
    for _, e in ipairs(battle.enemies) do
        if e.barkText and e.health.current > 0
            and (not e.spared or (e.spareT and e.spareT < 1.4)) then
            local font = self.worldFonts.tiny
            local tw = font:getWidth(e.barkText)
            local bw = math.min(88, tw + 10)
            -- Altura por wrap real da fonte — gestos longos quebram e não
            -- podem derramar pela borda da placa.
            local _, wrapped = font:getWrap(e.barkText, bw - 10)
            local lines = math.max(1, #wrapped)
            local bh = 8 + lines * 6
            local ux, uy = Render.visualPosition(e)
            if e.spareT then ux = ux + e.spareT * 40 end
            local bx = math.max(f.x + 4, math.min(f.x + f.w - bw - 4, round(ux - bw / 2)))
            -- Sobe quando a unidade já carrega o pip de intenção junto ao
            -- HP — o balão nunca empilha no '>>' nem sai pelo teto do canvas.
            local warned = e.enemy and (e.enemy.state == 'warn'
                or e.enemy.state == 'dash' or e.enemy.state == 'volley')
            local by = math.max(f.y + 4, round(uy - (warned and 66 or 62) - (lines - 1) * 6))
            local a = e.barkT and math.min(1, e.barkT / .4) or 1
            local PW = PixelWorld.palette
            if e.barkVerbal == false then
                -- Gesto: moldura solta, sem placa preenchida.
                border(bx, by, bw, bh, PW.bone, .9 * a)
                color(PW.bone, .9 * a)
                G.rectangle('fill', bx + 3, by + bh, 3, 1); G.rectangle('fill', bx + 5, by + bh + 1, 2, 1)
                text(font, e.barkText, bx + 5, by + 3, PW.bone, bw - 10)
            else
                color(C.ink, .92 * a); G.rectangle('fill', bx, by, bw, bh)
                border(bx, by, bw, bh, PW.boneDark, .9 * a)
                color(C.ink, .92 * a); G.rectangle('fill', bx + 5, by + bh, 3, 2)
                color(PW.boneDark, .9 * a); G.rectangle('fill', bx + 5, by + bh, 3, 1)
                text(font, e.barkText, bx + 5, by + 3, C.text, bw - 10)
            end
        end
    end
    -- Marcadores suspensos sobre os corpos (depois dos atores, nunca sob
    -- o sprite): trégua aceita lê 'zzz' azulado subindo devagar; quem está
    -- em fuga — a jogadora na travessia ou unidade com enemy.state 'flee'
    -- — carrega o selo da saída sobre a cabeça.
    for _, e in ipairs(battle.enemies) do
        local a = e.enemy
        if a and e.health.current > 0 and not e.spared then
            if a.state == 'calmed' then
                local ux, uy = Render.visualPosition(e)
                local bob = self.reducedMotion and 0
                    or math.sin(self.time * 2.1 + e.grid.x * 1.7) * 2
                local zx, zy = round(ux + 10), round(uy - 52 + bob)
                color(Pal.sky.star, .55)
                pixelLine(zx + 5, zy - 6, zx + 8, zy - 6)
                pixelLine(zx + 8, zy - 6, zx + 5, zy - 3)
                pixelLine(zx + 5, zy - 3, zx + 8, zy - 3)
                color(Pal.sky.star, .9)
                pixelLine(zx, zy, zx + 4, zy); pixelLine(zx + 4, zy, zx, zy + 4)
                pixelLine(zx, zy + 4, zx + 4, zy + 4)
            end
            if a.state == 'flee' then
                local ux, uy = Render.visualPosition(e)
                local bob = self.reducedMotion and 0 or math.sin(self.time * 6) * 1.5
                slotIcon('flee', round(ux - 5), round(uy - 58 + bob))
            end
        end
    end
    if battle.fleeing then
        local ux, uy = Render.visualPosition(battle.player)
        local bob = self.reducedMotion and 0 or math.sin(self.time * 6) * 1.5
        local ix, iy = round(ux - 7), round(uy - 60 + bob)
        color(C.ink, .85); G.rectangle('fill', ix - 2, iy - 2, 16, 14)
        border(ix - 2, iy - 2, 16, 14, Pal.jade.light, .9)
        slotIcon('flee', ix, iy)
    end
    -- Inspeção (modo 'inspect'): só a lente na célula aqui no canvas — o
    -- cartão de leitura mora no gutter, desenhado pelo campaignHud.
    if battle.mode == 'inspect' then
        local units = {battle.player}
        for _, e in ipairs(battle.enemies) do units[#units + 1] = e end
        local u = units[math.max(1, math.min(#units, battle.inspect or 1))]
        if u then
            local cx0, cy0 = (u.grid.x - 1) * 32, (u.grid.y - 1) * 32
            color(C.jade, .9)
            G.rectangle('fill', cx0, cy0, 9, 1); G.rectangle('fill', cx0, cy0, 1, 9)
            G.rectangle('fill', cx0 + 23, cy0, 9, 1); G.rectangle('fill', cx0 + 31, cy0, 1, 9)
            G.rectangle('fill', cx0, cy0 + 31, 9, 1); G.rectangle('fill', cx0, cy0 + 23, 1, 9)
            G.rectangle('fill', cx0 + 23, cy0 + 31, 9, 1); G.rectangle('fill', cx0 + 31, cy0 + 23, 1, 9)
            diamond(cx0 + 16, cy0 + 16, 15, C.jade, 'line')
        end
    end
    -- Vinheta da arena: as bordas afundam em tinta dithered — a leitura
    -- converge para o tabuleiro. Assada por tamanho de vista: desenhar
    -- milhares de rects por frame era desperdício, o conteúdo é estático.
    G.push(); G.origin()
    local vw, vh = self.view.w, self.view.h
    local vkey = vw .. 'x' .. vh
    if self.vignetteKey ~= vkey then
        self.vignetteKey = vkey
        if self.vignetteCanvas then self.vignetteCanvas:release() end
        local c = G.newCanvas(vw, vh, {dpiscale = 1})
        c:setFilter('nearest', 'nearest')
        local prev = G.getCanvas()
        G.push(); G.setCanvas(c); G.clear(0, 0, 0, 0)
        local vd = PixelArt.dither
        vd(0, 0, vw, 6, Pal.ink, .6); vd(0, 6, vw, 5, Pal.ink, .32); vd(0, 11, vw, 5, Pal.ink, .15)
        vd(0, vh - 6, vw, 6, Pal.ink, .6); vd(0, vh - 11, vw, 5, Pal.ink, .32); vd(0, vh - 16, vw, 5, Pal.ink, .15)
        vd(0, 0, 6, vh, Pal.ink, .55); vd(6, 0, 5, vh, Pal.ink, .28); vd(11, 0, 5, vh, Pal.ink, .13)
        vd(vw - 6, 0, 6, vh, Pal.ink, .55); vd(vw - 11, 0, 5, vh, Pal.ink, .28); vd(vw - 16, 0, 5, vh, Pal.ink, .13)
        -- Cantos: quartos de poça de tinta fecham a moldura da vista.
        PixelArt.ditherEllipse(0, 0, 58, 44, Pal.ink, .6)
        PixelArt.ditherEllipse(vw, 0, 58, 44, Pal.ink, .6)
        PixelArt.ditherEllipse(0, vh, 58, 44, Pal.ink, .6)
        PixelArt.ditherEllipse(vw, vh, 58, 44, Pal.ink, .6)
        G.pop(); G.setCanvas(prev)
        self.vignetteCanvas = c
    end
    color(Pal.white); G.draw(self.vignetteCanvas, 0, 0)
    G.pop()
    -- Tick de direção: uma pequena ponta de flecha aponta para onde o
    -- jogador olha — glifo, não losango abstrato.
    local p = battle.player
    local f3 = p.facing
    arrow((p.grid.x - .5) * 32 + f3.dx * 16, (p.grid.y - .5) * 32 + f3.dy * 16, f3.dx, f3.dy, C.white, 4)
end

function Render:campaignHud(campaign, w, h)
    G.push(); G.scale(2)
    local hw, hh = math.floor(w / 2), math.floor(h / 2)
    -- Painel de pedra: corpo de tinta, face escura, filete externo na cor do
    -- acento, filete interno de ouro velho e cantos entalhados — material de
    -- interface igual ao da arena.
    local function box(x, y, bw, bh, accent)
        color(C.ink, .97); G.rectangle('fill', x, y + 2, bw, bh - 2)
        color(C.panel, .95); G.rectangle('fill', x, y, bw, bh - 2)
        border(x, y, bw, bh - 2, accent or C.line)
        color(Pal.stone.light, .35); G.rectangle('fill', x + 1, y + 1, bw - 2, 1)
        border(x + 3, y + 3, bw - 6, bh - 8, Pal.gold.dark, .5)
        color(C.gold, .7)
        G.rectangle('fill', x + 2, y + 2, 2, 2); G.rectangle('fill', x + bw - 4, y + 2, 2, 2)
        G.rectangle('fill', x + 2, y + bh - 6, 2, 2); G.rectangle('fill', x + bw - 4, y + bh - 6, 2, 2)
    end
    -- Placa do lugar: faixa entalhada com pontas cortadas em V nos lados —
    -- lê-se como bandeira pendurada, não caixa de ferramenta.
    local function plaque(x, y, bw, bh)
        color(C.ink, .97); G.rectangle('fill', x, y, bw, bh)
        color(C.panel, .95); G.rectangle('fill', x, y, bw, bh)
        border(x, y, bw, bh, C.line)
        color(Pal.stone.light, .35); G.rectangle('fill', x + 1, y + 1, bw - 2, 1)
        border(x + 3, y + 3, bw - 6, bh - 6, Pal.gold.dark, .5)
        color(C.gold, .7)
        for _, c in ipairs({{x + 2, y + 2}, {x + bw - 4, y + 2}, {x + 2, y + bh - 4}, {x + bw - 4, y + bh - 4}}) do
            G.rectangle('fill', c[1], c[2], 2, 2)
        end
    end
    -- Objetivo vigente (Pena): LoreC.objective(campaign) — consome se
    -- existir, uma linha sob a placa de lugar; 'stub' vazio some.
    local obj = LoreC.objective and LoreC.objective(campaign) or ''
    obj = obj ~= '' and PixelFont.clean(obj) or nil
    local objLines = 0
    if obj then local _, lns = self.hudFont:getWrap(obj, 132); objLines = #lns end
    plaque(8, 8, 150, 32 + objLines * 9)
    text(self.hudFont, campaign.room.name, 16, 11, C.jade)
    text(self.hudFont, campaign.scene == 'battle' and 'ENCONTRO' or 'EXPLORAÇÃO', 16, 25, C.muted)
    if obj then text(self.hudFont, obj, 16, 36, C.gold, 132) end
    -- Filetes laterais da placa: marcas de pendurador.
    color(Pal.gold.dark); G.rectangle('fill', 4, 14, 3, 1); G.rectangle('fill', 159, 14, 3, 1)
    G.rectangle('fill', 4, 30, 3, 1); G.rectangle('fill', 159, 30, 3, 1)
    -- Placa do lugar: surge na entrada, respira e sai — nunca abrupta.
    if (self.roomTime or 0) > 0 and self.room and self.room.name then
        local a = math.min(1, (2.5 - self.roomTime) / .3, self.roomTime / .9)
        if a > 0 then
            local label = PixelFont.clean(self.room.name)
            local width = self.hudFont:getWidth(label)
            local bx, by = math.floor(hw / 2 - width / 2 - 14), 46
            color(C.ink, .85 * a); G.rectangle('fill', bx, by, width + 28, 18)
            border(bx, by, width + 28, 18, C.gold, .8 * a)
            color(C.gold, .9 * a)
            G.rectangle('fill', bx + 3, by + 3, 2, 2); G.rectangle('fill', bx + width + 23, by + 13, 2, 2)
            text(self.hudFont, label, bx + 14, by + 5, {C.jade[1], C.jade[2], C.jade[3], a})
        end
    end
    if campaign.messageTime > 0 then
        text(self.hudFont, campaign.message, 12, hh - 66, C.text, hw - 24, 'center')
    end
    if campaign.scene == 'battle' and campaign.battle then
        local b = campaign.battle
        -- LAYOUT EM GUTTERS: nada cobre o tabuleiro — slots na coluna
        -- esquerda, fila de turnos na direita, estado na placa superior e
        -- o rodapé virou uma única linha fina de informação.
        local v = self.view
        local f = b.frame or {x = 0, y = 0, w = 0, h = 0}
        local boardL = math.floor((v.x + (f.x - v.left) * v.scale) / 2)
        local boardR = math.floor((v.x + (f.x + f.w - v.left) * v.scale) / 2)
        local boardT = math.floor((v.y + (f.y - v.top) * v.scale) / 2)
        local boardB = math.floor((v.y + (f.y + f.h - v.top) * v.scale) / 2)
        local boardM = math.floor((boardT + boardB) / 2)
        -- PLACA DE ESTADO no canto superior direito: a fase física real da
        -- arena (AÇÃO em jogo, VAGA na pausa social, FIM no desfecho), VIDA
        -- em elos de pedra e CURAS — junto do palco, nunca no rodapé.
        box(hw - 118, 8, 110, 34, C.gold)
        text(self.hudFont, 'ARENA', hw - 112, 12, C.text)
        local phaseLabel = b.phase == 'action' and 'AÇÃO'
            or b.phase == 'done' and 'FIM' or 'VAGA'
        local phaseTint = b.phase == 'action' and C.gold
            or b.phase == 'done' and C.muted or C.jade
        text(self.hudFont, phaseLabel, hw - 112, 12, phaseTint, 102, 'right')
        local hp = b.player.health
        for i = 1, hp.max do
            color(i <= hp.current and Pal.danger or Pal.stone.dark)
            G.rectangle('fill', hw - 112 + (i - 1) * 7, 22, 5, 5)
        end
        text(self.hudFont, 'CURAS ' .. b.items.cura, hw - 112, 32, C.muted)
        -- MEDIDORES DO CORPO no gutter esquerdo: energia da guarda (sempre
        -- — é o fôlego real da arena) e carga do arco (só enquanto o tiro
        -- arma). O slot de ações do turno morreu com o modelo antigo.
        do
            local g2, wpn = b.player.guard, b.player.weapon
            local meters = {{
                icon = 'guard',
                frac = g2.max > 0 and math.min(1, g2.energy / g2.max) or 0,
                tint = g2.exhausted and C.muted
                    or g2.active and Pal.jade.light or C.jade,
                dim = g2.exhausted,
            }}
            if wpn.state == 'charging' or wpn.state == 'ready' then
                local ct = b:weaponStats().chargeTime or 1
                meters[#meters + 1] = {
                    icon = 'bow',
                    frac = wpn.state == 'ready' and 1
                        or math.min(1, wpn.charge / math.max(ct, .001)),
                    tint = wpn.state == 'ready' and Pal.gold.light or C.gold,
                }
            end
            local mw = 34
            local mx = math.max(6, boardL - mw - 8)
            local my0 = boardM - math.floor((#meters * 16 - 6) / 2)
            for i, m in ipairs(meters) do
                local my = my0 + (i - 1) * 16
                color(C.ink, .85); G.rectangle('fill', mx - 1, my + 1, mw + 2, 14)
                color(Pal.stone.dark); G.rectangle('fill', mx - 1, my - 1, mw + 2, 14)
                color(C.panel, .95); G.rectangle('fill', mx, my, mw, 12)
                slotIcon(m.icon, mx + 1, my + 1, m.dim)
                color(C.ink, .92); G.rectangle('fill', mx + 13, my + 4, mw - 15, 4)
                color(m.tint, m.dim and .45 or 1)
                G.rectangle('fill', mx + 13, my + 4,
                    math.floor((mw - 15) * m.frac + .5), 4)
                color(Pal.stone.light, .5)
                G.rectangle('fill', mx + 13, my + 4, mw - 15, 1)
                if m.icon == 'bow' and wpn.state == 'ready' then
                    border(mx - 1, my - 1, mw + 2, 14, C.gold, .8)
                end
            end
        end
        -- FICHAS DE ELENCO vertical no gutter direito: a Transeunte no topo
        -- (moldura jade), inimigos numerados abaixo na ordem canônica da
        -- arena — o índice que a inspeção e os alvos sociais consultam.
        -- Morto esmaece e leva risco diagonal; o foco da inspeção e quem
        -- baixou a guarda (mercy) acendem a moldura em ouro. Acima de 9
        -- fichas a fila quebra numa segunda coluna à esquerda.
        local qchips = {}
        qchips[1] = {u = b.player, order = 0}
        for i, e in ipairs(b.enemies) do qchips[#qchips + 1] = {u = e, order = i} end
        local cw, cgap = 18, 4
        local qx = math.min(hw - cw - 6, boardR + 16)
        for i, c in ipairs(qchips) do
            local col = math.floor((i - 1) / 9)
            local row = (i - 1) % 9
            local sx = qx - col * (cw + cgap)
            local qy = boardT + 6 + row * (cw + cgap)
            local dead = c.u.health.current <= 0
            local focused = b.mode == 'inspect' and b.inspect == i
            color(C.ink, .85); G.rectangle('fill', sx - 1, qy + 1, cw + 2, cw + 2)
            color(Pal.stone.dark); G.rectangle('fill', sx - 1, qy - 1, cw + 2, cw + 2)
            local frameC = (focused or c.u.mercy) and C.gold
                or c.order == 0 and C.jade or Pal.stone.base
            color(frameC, dead and .5 or 1); G.rectangle('fill', sx, qy, cw, cw)
            color(C.ink, .92); G.rectangle('fill', sx + 1, qy + 1, cw - 2, cw - 2)
            local kind = c.u.player and 'player' or c.u.enemy and c.u.enemy.kind
            -- O casulo dormente lê fardo na ficha, igual ao corpo na arena.
            if kind == 'husk' and c.u.enemy
                and c.u.enemy.state == 'dormant' then kind = 'huskCocoon' end
            local sheet = kind and (self.actors.sheets[kind]
                or self.actors.sheets['npc_' .. kind])
            if sheet and sheet.portrait then
                local quad = sheet.animations.idle[2].frames[1]
                local sxq, syq = quad:getViewport()
                local pc = sheet.portrait
                local sub = G.newQuad(sxq + pc[1], syq + pc[2], pc[3], pc[4],
                    sheet.image:getDimensions())
                color(dead and C.line or C.white)
                G.draw(sheet.image, sub,
                    sx + math.floor((cw - pc[3]) / 2),
                    qy + math.floor((cw - pc[4]) / 2))
            end
            if dead then
                color(C.red); pixelLine(sx + 2, qy + cw - 3, sx + cw - 3, qy + 2)
            end
            if c.order > 0 then
                text(self.hudFont, tostring(c.order), sx + cw - 5, qy + cw - 7,
                    dead and C.muted or C.gold)
            end
        end
        -- CARTÃO DE INSPEÇÃO no gutter oposto à unidade: a lente fica na
        -- célula (canvas), o cartão respira no vazio ao lado do tabuleiro
        -- com um traço jade ligando os dois.
        if b.mode == 'inspect' then
            local units = {b.player}
            for _, e in ipairs(b.enemies) do units[#units + 1] = e end
            local u = units[math.max(1, math.min(#units, b.inspect or 1))]
            if u then
                local uhX = math.floor((v.x + ((u.grid.x - .5) * 32 - v.left) * v.scale) / 2)
                local uhY = math.floor((v.y + ((u.grid.y - .5) * 32 - v.top) * v.scale) / 2)
                local cw2, ch2 = 96, 58
                local right = uhX < (boardL + boardR) / 2
                local px0 = right and math.min(hw - cw2 - 8, boardR + 34)
                    or math.max(8, boardL - 34 - cw2)
                local py0 = math.max(boardT - 20, math.min(boardB + 10, uhY - 26))
                -- Traço ligando o cartão à aresta do tabuleiro.
                color(C.jade, .6)
                pixelLine(right and boardR + 10 or boardL - 12, py0 + 26,
                    right and px0 or px0 + cw2, py0 + 26)
                color(C.ink, .94); G.rectangle('fill', px0, py0, cw2, ch2)
                color(Pal.stone.dark); G.rectangle('fill', px0 - 1, py0 - 1, cw2 + 2, ch2 + 2)
                border(px0, py0, cw2, ch2, Pal.stone.base, .9)
                color(Pal.gold.dark); G.rectangle('fill', px0 + 2, py0 + 2, 2, 2)
                G.rectangle('fill', px0 + cw2 - 4, py0 + 2, 2, 2)
                local name = u.player and 'TRANSEUNTE' or (u.name or 'INIMIGO')
                text(self.hudFont, name, px0 + 7, py0 + 5, C.gold)
                text(self.hudFont, u.player and 'ARQUEIRA ERRANTE'
                    or ((u.enemy and u.enemy.kind or '?') .. ' · ' .. (u.role.plan or '')),
                    px0 + 7, py0 + 16, C.muted)
                local hc = u.health
                text(self.hudFont, 'VIDA ' .. hc.current .. '/' .. hc.max,
                    px0 + 7, py0 + 27, hc.current <= 2 and C.red or C.text)
                if u.player then
                    text(self.hudFont, 'A jornada é tua — posicione-se.', px0 + 7, py0 + 40, C.muted)
                else
                    local kind, label, ic = enemyReadout(u)
                    intentGlyph(kind, px0 + 7, py0 + 38, ic)
                    text(self.hudFont, label, px0 + 18, py0 + 39, ic)
                    text(self.hudFont, inspectNotes[u.enemy and u.enemy.kind] or '',
                        px0 + 7, py0 + 50, C.muted)
                end
            end
        end
        -- CARTÃO DE POSTURA (pausa real, COMBATE_MERGE §3): os itens do
        -- menu raiz no gutter esquerdo — pedra, cursor '>' no foco e o
        -- desc do item sob a lista, mesma mão do cartão de atos.
        if b.mode == 'menu' then
            local items = b:menuItems()
            local focus = items[b.menuIndex or 1]
            local cw3 = 118
            local descLines = 0
            if focus and focus.desc then
                local _, wrapped = self.worldFonts.tiny:getWrap(focus.desc, cw3 - 14)
                descLines = #wrapped
            end
            local ch3 = 22 + #items * 11 + (descLines > 0 and descLines * 8 + 10 or 0)
            local px0 = math.max(8, boardL - 34 - cw3)
            local py0 = math.max(50, math.min(boardB - ch3, boardT - 20))
            box(px0, py0, cw3, ch3, C.gold)
            text(self.hudFont, 'POSTURA', px0 + 7, py0 + 5, C.gold, cw3 - 14)
            for i, it in ipairs(items) do
                local sel = i == (b.menuIndex or 1)
                text(self.hudFont, (sel and '> ' or '  ') .. it.label,
                    px0 + 7, py0 + 5 + i * 11,
                    it.disabled and C.muted or sel and C.text or C.muted)
            end
            if focus and focus.desc then
                text(self.worldFonts.tiny, focus.desc, px0 + 7,
                    py0 + 11 + (#items + 1) * 11, C.muted, cw3 - 14)
            end
        end
        -- CARTÃO DE USAR (modo 'use' da pausa): os consumíveis da bolsa
        -- com a contagem real — o submenu existe desde o modelo antigo,
        -- agora com a lista visível.
        if b.mode == 'use' then
            local items = b:useItems()
            local focus = items[b.useIndex or 1]
            local cw3 = 118
            local descLines = 0
            if focus and focus.desc then
                local _, wrapped = self.worldFonts.tiny:getWrap(focus.desc, cw3 - 14)
                descLines = #wrapped
            end
            local ch3 = 22 + #items * 11 + (descLines > 0 and descLines * 8 + 10 or 0)
            local px0 = math.max(8, boardL - 34 - cw3)
            local py0 = math.max(50, math.min(boardB - ch3, boardT - 20))
            box(px0, py0, cw3, ch3, C.jade)
            text(self.hudFont, 'USAR', px0 + 7, py0 + 5, C.jade, cw3 - 14)
            for i, it in ipairs(items) do
                local sel = i == (b.useIndex or 1)
                text(self.hudFont, (sel and '> ' or '  ') .. it.label
                    .. ' x' .. (it.qty or 0), px0 + 7, py0 + 5 + i * 11,
                    sel and C.text or C.muted)
            end
            if focus and focus.desc then
                text(self.worldFonts.tiny, focus.desc, px0 + 7,
                    py0 + 11 + (#items + 1) * 11, C.muted, cw3 - 14)
            end
        end
        -- CARTÃO DE ATOS (modo 'actlist'): a lista social do alvo no
        -- gutter esquerdo — pedra, filete dourado no cursor, motivo dos
        -- itens recusados.
        if b.mode == 'actlist' then
            local target = b:liveEnemies()[b.actTarget or 1]
            local acts = target and b:actItems(target) or {}
            if target and #acts > 0 then
                -- Altura pelo wrap REAL da fonte — a moldura fecha depois
                -- da última linha do desc, nunca antes.
                local focus = acts[b.actIndex or 1]
                local cw3 = 128
                local descLines = 0
                if focus and focus.desc then
                    local _, wrapped = self.worldFonts.tiny:getWrap(focus.desc, cw3 - 14)
                    descLines = #wrapped
                end
                local ch3 = 22 + #acts * 11 + (descLines > 0 and descLines * 8 + 10 or 0)
                local px0 = math.max(8, boardL - 34 - cw3)
                local py0 = math.max(50, math.min(boardB - ch3, boardT - 20))
                box(px0, py0, cw3, ch3, C.gold)
                text(self.hudFont, 'AGIR — ' .. (target.name or 'ALVO'),
                    px0 + 7, py0 + 5, C.gold, cw3 - 14)
                for i, it in ipairs(acts) do
                    local sel = i == (b.actIndex or 1)
                    text(self.hudFont, (sel and '> ' or '  ') .. it.label,
                        px0 + 7, py0 + 5 + i * 11,
                        it.disabled and C.muted or sel and C.text or C.muted)
                end
                if focus and focus.desc then
                    text(self.worldFonts.tiny, focus.desc, px0 + 7,
                        py0 + 11 + (#acts + 1) * 11, C.muted, cw3 - 14)
                end
            end
        end
        -- RODAPÉ-LINHA: faixa fina de uma linha — detalhe da ação em foco
        -- ou o que aconteceu no turno. Nada mais disputa a arena.
        local fy = hh - 14
        color(C.ink, .92); G.rectangle('fill', 0, fy, hw, 12)
        color(Pal.stone.dark); G.rectangle('fill', 0, fy, hw, 1)
        color(Pal.gold.dark, .5); G.rectangle('fill', 0, fy + 1, hw, 1)
        local line, lc = nil, C.muted
        -- Os modos sociais vêm primeiro: podem abrir em cima de qualquer
        -- fase física (a pausa do passo 2 congela, mas o menu lê igual).
        if b.mode == 'menu' then
            local items = b:menuItems()
            local it = items[b.menuIndex]
            line = (it.disabled or it.desc) .. '   ·   A/D OU 1-'
                .. #items .. ' · ENTER CONFIRMA · ESC VOLTA'
            lc = C.text
        elseif b.mode == 'act' then
            line = 'WASD ESCOLHE O ALVO · ENTER ABRE OS ATOS · ESC VOLTA'
            lc = C.gold
        elseif b.mode == 'actlist' then
            line = 'WASD NAVEGA OS ATOS · ENTER ATUA · ESC VOLTA'
            lc = C.gold
        elseif b.mode == 'mercy' then
            line = 'WASD ESCOLHE QUEM PARTE · ENTER POUPA · ESC VOLTA'
            lc = C.jade
        elseif b.mode == 'use' then
            line = 'WASD ESCOLHE O ITEM · ENTER USA · ESC VOLTA'
            lc = C.jade
        elseif b.mode == 'inspect' then
            line = 'WASD NAVEGA ENTRE UNIDADES · I/ESC FECHA — consulta sem custo'
            lc = C.jade
        elseif b.phase == 'done' then
            -- Desfecho: a saída real é o endBattle da campanha — a linha
            -- só aparece se um quadro ainda enxergar a arena fechada.
            line = 'O confronto se encerrou.'
        elseif b.phase ~= 'action' then
            -- Vaga: pausa social (passo 2) ou fase congelada de captura —
            -- a simulação está parada e a linha diz isso sem fingir turno.
            line = #b.log > 0 and b.log[#b.log]
                or 'A luta respira — aproveita a vaga.'
            lc = C.jade
        else
            line = #b.log > 0 and b.log[#b.log]
                or 'WASD MOVE · ESPAÇO CARREGA O ARCO · SHIFT GUARDA · E POUPA'
            lc = #b.log > 0 and C.muted or C.text
        end
        text(self.hudFont, line, 20, fy + 3, lc)
    else
        text(self.hudFont, 'WASD ANDAR · E INTERAGIR · ESC PAUSA', 8, hh - 8, C.muted, hw - 16, 'center')
    end
    G.pop()
end

function Render:campaignTitle(hasSave, w, h, menu)
    color(C.ink, .85); G.rectangle('fill', 0, 0, w, h)
    local left = math.max(58, (w - 1120) / 2)
    local top = h / 2 - 243
    text(self.fonts.small, 'A CIDADE QUE TE GUARDOU.', left + 4, top, C.jade)
    text(self.fonts.title, 'ARROW', left, top + 25, C.text)
    text(self.fonts.title, 'FALLEN', left, top + 85, C.gold)
    color(C.gold); G.rectangle('fill', left + 4, top + 173, 59, 2)
    text(self.fonts.body, 'Você saiu da própria sepultura.', left + 4, top + 193, C.muted)
    text(self.fonts.body, 'A cidade que o enterrou ainda está de pé.', left + 4, top + 219, C.muted)
    menu = menu or {idx = 1, mode = 'root'}
    if menu.mode == 'confirm' then
        -- Confirmação explícita: nova campanha com save existente nunca
        -- apaga num toque — pede ENTER de novo.
        local py = top + 264
        panel(left, py, 490, 112, C.red)
        text(self.fonts.body, 'NOVA CAMPANHA APAGA O SAVE GRAVADO.', left + 22, py + 16, C.red)
        text(self.fonts.small, 'ENTER  confirma e recomeça do zero', left + 22, py + 52, C.text)
        text(self.fonts.small, 'ESC  volta ao menu — nada é tocado', left + 22, py + 74, C.muted)
    elseif menu.mode == 'options' then
        -- Linhas dinâmicas do mixer do Tímpano: MUDO + volumes por canal
        -- (barra proporcional + %), MOVIMENTO REDUZIDO no fim. O menu manda
        -- menu.rows — a tela nunca adivinha quantas opções existem.
        local rows = menu.rows or {}
        local py = top + 264
        panel(left, py, 490, 58 + #rows * 32 + 22, C.jade)
        text(self.fonts.small, 'OPÇÕES', left + 22, py + 12, C.jade)
        for i, row in ipairs(rows) do
            local ry = py + 42 + (i - 1) * 32
            local sel = menu.idx == i
            if sel then
                color(C.jade, .13); G.rectangle('fill', left + 12, ry - 3, 466, 28, 4)
                text(self.fonts.small, '>', left + 18, ry + 4, C.jade)
            end
            text(self.fonts.body, PixelFont.clean(row.label), left + 34, ry,
                sel and C.text or C.muted)
            if row.kind == 'volume' then
                local level = tonumber((row.value or '0'):match('%d+')) or 0
                color(C.line); G.rectangle('fill', left + 290, ry + 8, 120, 7)
                color(sel and C.jade or C.muted)
                G.rectangle('fill', left + 290, ry + 8, math.floor(120 * level / 100), 7)
                text(self.fonts.small, row.value, left + 424, ry + 4,
                    sel and C.text or C.muted)
            else
                text(self.fonts.small, row.value, left + 424, ry + 4,
                    row.value == 'LIGADO' and C.jade or C.muted)
            end
        end
        text(self.fonts.small, 'W/S escolhe · A/D volume · ENTER alterna · ESC volta',
            left + 22, py + 42 + #rows * 32 + 6, C.muted)
    else
        -- Lista navegável: CONTINUAR honesto (cinza morto sem save),
        -- cursor entalhado no item — clareza antes de tamanho.
        local items = {
            {label = 'CONTINUAR', desc = 'Volta à campanha de onde parou',
                enabled = hasSave, accent = C.jade},
            {label = 'NOVA CAMPANHA', desc = hasSave and 'Pedirá confirmação — o save não some num toque'
                or 'A Cidade Que Me Enterrou', enabled = true, accent = C.gold},
            {label = 'OPÇÕES', desc = 'Som e movimento', enabled = true, accent = C.jade},
            {label = 'SAIR', desc = 'Fecha o jogo', enabled = true, accent = C.muted},
        }
        for i, item in ipairs(items) do
            local ry = top + 264 + (i - 1) * 62
            -- Desabilitado nunca acende foco (a navegação já o pula);
            -- texto, descrição e borda ficam em pedra-morta.
            local sel = menu.idx == i and item.enabled
            local accent = item.enabled and item.accent or C.muted
            panel(left, ry, 490, 54, sel and accent or C.line)
            if sel then
                color(accent, .13); G.rectangle('fill', left + 4, ry + 4, 482, 46, 4)
                color(accent); G.rectangle('fill', left + 10, ry + 16, 2, 20)
            end
            text(self.fonts.body, item.label, left + 26, ry + 8,
                item.enabled and C.text or C.muted)
            text(self.fonts.small, item.desc or '', left + 26, ry + 30, C.muted)
            if sel then text(self.fonts.small, '>', left + 468, ry + 20, accent) end
        end
    end
    text(self.fonts.small, 'TAB  Como jogar', left + 4, top + 540, C.text)
    self:emblem(w - math.max(230, (w - 1000) / 2), h / 2 - 7, math.min(1.20, w / 1050))
    for i, line in ipairs({'A TERRA ALÉM DA COVA.', 'NOME A NOME.', 'A CIDADE QUE ME ENTERROU.'}) do
        text(self.fonts.small, line, w - 382, h / 2 + 185 + (i - 1) * 16, C.muted, 305, 'center')
    end
    text(self.fonts.tiny, 'W/S escolhe · ENTER confirma', 40, h - 36, C.muted, w - 80, 'center')
end

-- Abertura da campanha: quadros compostos dos sprites/paletas existentes +
-- legenda do Pena (LoreC.introCutscene / LoreC.cutscenes). screen 'opening' no fluxo do
-- campaign — não repete no Continuar (flag introSeen).
local introPanels = {
    -- Dentro do caixão: quase tudo tinta — uma fresta de terra acima.
    caixao = function(self, x, y, w, h)
        color(Pal.abyss); G.rectangle('fill', x, y, w, h)
        color(Pal.ridge.far); G.rectangle('fill', x + 30, y + 24, w - 60, 14)
        color(Pal.sky.low); G.rectangle('fill', x + 30, y + 26, w - 60, 4)
        PixelArt.dither(x + 34, y + 30, w - 68, 8, Pal.sky.mid, .3)
        color(Pal.ink); G.rectangle('fill', x, y, w, 18)
        color(Pal.stone.dark); G.rectangle('fill', x, y + 16, w, 2)
    end,
    -- A marca da casa: símbolo pregado na pedra — flecha tombada da casa.
    marca = function(self, x, y, w, h)
        local Rw = Pal.regions.colina
        color(Rw.wall.face); G.rectangle('fill', x, y, w, h)
        for i = 0, math.floor(w / 30) do
            color(Rw.wall.faceDark, .8); G.rectangle('fill', x + i * 30 + (i % 2) * 8, y + h - 1, 20, 1)
        end
        local cx, cy = x + w / 2, y + h / 2
        -- A flecha tombada da casa, grande o bastante para ler na moldura.
        color(Pal.ink); G.rectangle('fill', cx - 46, cy - 56, 92, 112)
        color(Pal.gold.dark); G.rectangle('fill', cx - 9, cy - 50, 18, 100)
        color(Pal.gold.base); G.rectangle('fill', cx - 4, cy - 50, 8, 100)
        color(Pal.gold.dark)
        G.polygon('fill', cx - 38, cy - 24, cx, cy - 62, cx + 38, cy - 24)
        color(Pal.gold.base)
        G.polygon('fill', cx - 26, cy - 28, cx, cy - 54, cx + 26, cy - 28)
        color(Pal.jade.base, .6); G.rectangle('fill', cx - 4, cy + 44, 8, 12)
    end,
    -- A cova aberta de cima: borda de terra e o vão escuro com a laje ao lado.
    cova = function(self, x, y, w, h)
        local Rw = Pal.regions.colina
        color(Rw.floor.shadow); G.rectangle('fill', x, y, w, h)
        color(Rw.floor.dark); G.rectangle('fill', x, y + h - 20, w, 20)
        local cx = x + w / 2 - 40
        color(Pal.ink); G.rectangle('fill', cx - 46, y + h - 74, 92, 36)
        color(Pal.ridge.far); G.rectangle('fill', cx - 46, y + h - 74, 92, 3)
        color(Rw.wall.brick); G.rectangle('fill', cx - 48, y + h - 40, 96, 4)
        color(Rw.wall.face); G.rectangle('fill', cx + 60, y + h - 70, 50, 16)
        color(Rw.wall.cap); G.rectangle('fill', cx + 60, y + h - 70, 50, 2)
        PixelArt.ditherEllipse(cx, y + h - 56, 44, 14, Pal.ember, .2)
    end,
    -- A grade: ferro descendo para o refúgio — lume quente do outro lado.
    grade = function(self, x, y, w, h)
        local Rw = Pal.regions.hub
        color(Pal.ink); G.rectangle('fill', x, y, w, h)
        PixelArt.ditherEllipse(x + w / 2, y + h - 40, 120, 50, Pal.ember, .35)
        color(Rw.wall.faceDark); G.rectangle('fill', x, y + h - 30, w, 30)
        color(Rw.wall.cap); G.rectangle('fill', x, y + h - 30, w, 1)
        for i = 0, math.floor(w / 24) - 1 do
            color(Pal.stone.dark); G.rectangle('fill', x + 10 + i * 24, y + 30, 6, h - 60)
            color(Pal.stone.light); G.rectangle('fill', x + 10 + i * 24, y + 30, 1, h - 60)
        end
        color(Pal.stone.dark); G.rectangle('fill', x, y + 26, w, 6)
        color(Pal.ember, .7); G.rectangle('fill', x + w / 2 - 30, y + h - 58, 60, 2)
    end,
    -- A tampa: pedra pesada vista de lado, luz de brasa escapando da frincha.
    tampa = function(self, x, y, w, h)
        local Rw = Pal.regions.colina
        color(Pal.abyss); G.rectangle('fill', x, y, w, h)
        color(Rw.floor.shadow); G.rectangle('fill', x, y + h - 24, w, 24)
        -- A laje de corpo inteiro, vista de perfil e levemente entreaberta:
        -- a frincha de brasa é o único brilho do quadro.
        local cx = x + w / 2
        PixelArt.ditherEllipse(cx, y + h - 52, 90, 40, Pal.ember, .25)
        color(Pal.ink); G.rectangle('fill', cx - 96, y + h - 62, 192, 24)
        color(Rw.wall.face); G.rectangle('fill', cx - 94, y + h - 60, 188, 20)
        color(Rw.wall.cap); G.rectangle('fill', cx - 94, y + h - 60, 188, 2)
        color(Rw.wall.mortar); G.rectangle('fill', cx - 94, y + h - 48, 188, 1)
        color(Pal.ember); G.rectangle('fill', cx - 80, y + h - 38, 160, 3)
        color(Pal.emberLight); G.rectangle('fill', cx - 40, y + h - 38, 80, 2)
        PixelArt.dither(cx - 30, y + h - 50, 60, 8, Pal.ember, .4)
        for i = 0, 4 do
            color(Pal.emberLight, .5)
            G.rectangle('fill', cx - 36 + i * 18, y + h - 66 - (i % 2) * 6, 1, 1)
        end
    end,
    -- A colina: lua baixa + crista de lápides, o enquadramento do palco.
    colina = function(self, x, y, w, h)
        color(Pal.sky.mid); G.rectangle('fill', x, y, w, h)
        color(Pal.sky.low); G.rectangle('fill', x, y + math.floor(h * .55), w, h)
        PixelArt.ditherEllipse(x + w * .3, y + 34, 26, 22, Pal.moon.halo, .35)
        color(Pal.moon.disc); G.circle('fill', x + w * .3, y + 34, 14)
        -- A cidade embaixo da crista: massa escura com janelas acesas —
        -- o lugar onde a arqueira dormiu sete anos.
        local gy = y + h - 26
        local cy = gy - 8
        color(Pal.ridge.far); G.rectangle('fill', x, cy, w, gy - cy + 26)
        for i = 0, 9 do
            local bx = x + 10 + i * math.floor(w / 10)
            local bh = 10 + ((i * 37) % 14)
            color(Pal.ridge.near); G.rectangle('fill', bx, cy + 8 - bh + 8, 9, bh)
            if i % 3 == 1 then
                color(Pal.ember, .85); G.rectangle('fill', bx + 3, cy + 8 - bh + 11, 2, 2)
            end
        end
        -- Crista frontal: lápides legíveis — laje, cruz e obelisco no
        -- mesmo recorte do cemitério de batalha.
        color(Pal.ridge.near); G.rectangle('fill', x, gy, w, 26)
        color(Pal.ridge.lit, .8); G.rectangle('fill', x, gy - 1, w, 1)
        for i = 0, 8 do
            local gx = x + 14 + i * math.floor(w / 9)
            local kind = i % 3
            color(Pal.ridge.lit)
            if kind == 0 then          -- laje alta
                G.rectangle('fill', gx, gy - 13, 5, 13)
                color(Pal.ridge.far); G.rectangle('fill', gx + 4, gy - 13, 1, 13)
            elseif kind == 1 then      -- cruz
                G.rectangle('fill', gx + 1, gy - 12, 3, 12)
                G.rectangle('fill', gx - 1, gy - 9, 7, 2)
            else                       -- obelisco
                G.polygon('fill', gx, gy, gx + 2, gy - 14, gx + 4, gy)
                G.rectangle('fill', gx - 1, gy - 3, 6, 3)
            end
        end
    end,
    -- O viajante: a arqueira de pé, de costas para a cidade, silhueta jade.
    viajante = function(self, x, y, w, h)
        local Rw = Pal.regions.colina
        color(Rw.floor.shadow); G.rectangle('fill', x, y, w, h)
        color(Pal.ridge.far); G.rectangle('fill', x, y + h - 20, w, 20)
        local sheet = self.actors.sheets.player
        if sheet then
            color(C.white)
            sheet.animations.idle[4]:draw(sheet.image, x + w / 2, y + h - 24, 0, 3, 3, 20, 44)
        end
        PixelArt.ditherEllipse(x + w / 2, y + h - 21, 20, 5, Pal.ink, .6)
    end,
    -- O refúgio: parede quente + lampião — a casa funerária que acolhe.
    refugio = function(self, x, y, w, h)
        local Rw = Pal.regions.hub
        color(Rw.wall.face); G.rectangle('fill', x, y, w, h)
        for i = 0, math.floor(w / 26) do
            color(Rw.wall.faceDark, .8); G.rectangle('fill', x + i * 26, y, 1, h)
        end
        local lx = x + w / 2
        PixelArt.ditherEllipse(lx, y + h / 2, 34, 28, Pal.ember, .4)
        color(Pal.gold.dark); G.rectangle('fill', lx - 3, y + h / 2 - 12, 7, 12)
        color(Pal.emberLight); G.rectangle('fill', lx - 2, y + h / 2 - 9, 5, 8)
        color(Pal.white); G.rectangle('fill', lx - 1, y + h / 2 - 7, 2, 4)
        color(Rw.floor.base); G.rectangle('fill', x, y + h - 18, w, 18)
        color(Rw.floor.shadow); G.rectangle('fill', x, y + h - 18, w, 1)
    end,
    -- As portas: três portais na parede — a cidade que se abre por dentro.
    portas = function(self, x, y, w, h)
        local Rw = Pal.regions.hub
        color(Rw.wall.faceDark); G.rectangle('fill', x, y, w, h)
        color(Rw.floor.base); G.rectangle('fill', x, y + h - 14, w, 14)
        for i = 1, 3 do
            local dx = x + math.floor(w * (i - .5) / 3)
            color(Pal.ink); G.rectangle('fill', dx - 10, y + h - 46, 20, 32)
            color(Rw.wall.brick); G.rectangle('fill', dx - 12, y + h - 48, 24, 2)
            color(Pal.jade.base, .3); G.rectangle('fill', dx - 7, y + h - 42, 14, 26)
            color(Pal.jade.light); G.rectangle('fill', dx - 1, y + h - 42, 2, 26)
        end
    end,
}

function Render:opening(frame, w, h)
    color(C.ink); G.rectangle('fill', 0, 0, w, h)
    local pw, ph = math.min(560, w - 120), 200
    local x, y = math.floor(w / 2 - pw / 2), math.floor(h / 2 - ph / 2 - 30)
    panel(x - 6, y - 6, pw + 12, ph + 12, C.gold)
    local painter = introPanels[frame.art or 'colina']
    if painter then painter(self, x, y, pw, ph) end
    -- Fade de entrada curto entre quadros — reduced-motion corta para 1.
    local a = self.reducedMotion and 0 or math.max(0, 1 - (self.openingT or 1) / .3)
    if a > 0 then color(C.ink, a); G.rectangle('fill', x - 6, y - 6, pw + 12, ph + 12) end
    -- Moldura do quadro + a legenda sob ele, avanço na mão da jogadora.
    local caption = frame.text or (frame.lines and table.concat(frame.lines, ' ')) or ''
    text(self.fonts.small, PixelFont.clean(caption), 40, y + ph + 26,
        C.text, w - 80, 'center')
    text(self.fonts.tiny, 'ENTER/E avança · ESC pula', 40, h - 40, C.muted, w - 80, 'center')
end

function Render:campaignPause(w, h, campaign)
    color(C.ink, .82); G.rectangle('fill', 0, 0, w, h)
    local x, y = w / 2 - 246, h / 2 - 206
    panel(x, y, 492, 412, C.jade)
    text(self.fonts.small, 'A CIDADE ESPERA.', x + 28, y + 29, C.jade)
    text(self.fonts.large, 'Pausa.', x + 28, y + 61, C.text)
    self:button('ESC', 'Continuar', 'Volte exatamente onde parou', x + 26, y + 123, 440, C.jade)
    self:button('B', 'Bolsa', 'Itens conquistados — equipar, usar, ler', x + 26, y + 203, 440, C.gold)
    self:button('TAB', 'Guia da viagem', 'Controles e o que a campanha guarda', x + 26, y + 273, 440, C.jade)
    local obj = campaign and LoreC.objective and LoreC.objective(campaign) or ''
    if obj ~= '' then
        text(self.fonts.small, PixelFont.clean(obj), x + 28, y + 338, C.jade, 440)
    end
    text(self.fonts.body, 'Q  Salvar e voltar ao título', x + 28, y + 365, C.text)
    text(self.fonts.small, 'O progresso é gravado a cada passagem e cada decisão.', x + 28, y + 390, C.muted)
end

-- A bolsa fora da arena: lista real de campaign.data.items com quantidades,
-- equipado marcado por slot, detalhe com descrição e efeito. Estados vazios
-- e ações honestas — equipável equipa/desequipa, consumível consome,
-- chave só se lê.
local function itemPicture(id, x, y, size, pal)
    G.push('all')
    local sx, sy = G.transformPoint(x, y)
    local ex, ey = G.transformPoint(x + size, y + size)
    G.intersectScissor(sx, sy, ex - sx, ey - sy)
    local command = ({arco = 'bow', picareta = 'tool', provisao = 'use'})[id]
    if command then
        local scale = math.max(1, math.floor(size / 12))
        G.translate(round(x + size / 2 - 5 * scale), round(y + size / 2 - 5 * scale))
        G.scale(scale); slotIcon(command, 0, 0, false)
    elseif id == 'fivela' then
        local scale = math.max(1, math.floor(size / 16))
        G.translate(round(x + size / 2 - 8 * scale), round(y + size / 2 - 8 * scale)); G.scale(scale)
        color(Pal.gold.dark); G.rectangle('fill', 2, 5, 12, 7)
        color(Pal.gold.light); G.rectangle('fill', 2, 4, 12, 6)
        color(C.ink); G.rectangle('fill', 4, 6, 8, 2)
        color(Pal.gold.light); G.rectangle('fill', 8, 5, 1, 5)
    else
        local icon = id == 'esquemaCanal' and 'mapa' or 'livro'
        local scale = math.max(1, math.floor(size / 16))
        Props.icon(icon, round(x + (size - 16 * scale) / 2),
            round(y + (size - 16 * scale) / 2), scale, pal)
    end
    G.pop()
end

function Render:campaignBag(w, h, campaign, bag)
    color(C.ink, .82); G.rectangle('fill', 0, 0, w, h)
    local width, x, y = 760, (w - 760) / 2, h / 2 - 260
    panel(x, y, width, 500, C.gold)
    text(self.fonts.small, 'O QUE SOBROU CONTIGO', x + 28, y + 24, C.gold)
    text(self.fonts.large, 'Bolsa.', x + 28, y + 50, C.text)
    -- Lista ordenada por categoria — Items.list é a fonte única (o input
    -- da bolsa indexa sobre a mesma ordem).
    local list = Items.list(campaign.data.items)
    local eq = campaign.data.equipped or {}
    if #list == 0 then
        text(self.fonts.body, 'BOLSA VAZIA', x + 28, y + 120, C.muted)
        text(self.fonts.small, 'O que você recolher na cidade entra aqui.',
            x + 28, y + 150, C.muted)
        text(self.fonts.small, 'ESC voltar', x + 28, y + 462, C.muted)
        return
    end
    bag.idx = math.max(1, math.min(bag.idx or 1, #list))
    for i, it in ipairs(list) do
        local ry = y + 100 + (i - 1) * 40
        local sel = i == bag.idx
        local isEq = eq[it.def.slot] == it.id
        panel(x + 20, ry, 330, 34, sel and C.jade or C.line)
        if isEq then
            color(C.jade); G.rectangle('fill', x + 26, ry + 13, 6, 6)
        end
        itemPicture(it.id, x + 40, ry + 8, 16, PixelScene.palette(campaign.room))
        text(self.fonts.body, PixelFont.clean(it.def.label), x + 64, ry + 9,
            sel and C.text or C.muted)
        if it.def.stack and it.qty > 1 then
            text(self.fonts.small, 'x' .. it.qty, x + 330, ry + 10, C.gold)
        end
        if it.def.cat == 'equipavel' then
            text(self.fonts.small, it.def.slot == 'arma' and 'ARMA' or 'FERRAMENTA',
                x + 266, ry + 10, isEq and C.jade or C.muted)
        end
    end
    -- Cartão do item: nome, categoria, descrição, efeito, comparação honesta.
    local it = list[bag.idx]
    local dx = x + 370
    panel(dx, y + 100, width - 400, 340, C.jade)
    text(self.fonts.body, PixelFont.clean(it.def.label), dx + 16, y + 116, C.gold)
    text(self.fonts.small, it.def.cat:upper(), dx + 16, y + 140, C.jade)
    panel(dx + 16, y + 164, 112, 112, C.gold)
    itemPicture(it.id, dx + 24, y + 172, 96, PixelScene.palette(campaign.room))
    text(self.fonts.small, PixelFont.clean(it.def.desc or ''), dx + 16, y + 292,
        C.text, width - 430)
    local fy = y + 350
    if it.def.battle and it.def.battle.heal then
        text(self.fonts.small, 'EFEITO: +' .. it.def.battle.heal
            .. ' DE VIDA — ARENA E ESTRADA', dx + 16, fy, C.jade); fy = fy + 22
    end
    if it.def.cat == 'equipavel' then
        local holder = eq[it.def.slot]
        local cur = holder and Items.def(holder)
        text(self.fonts.small, holder == it.id
                and ('NA MÃO: ' .. PixelFont.clean(it.def.label))
                or ('NA MÃO HOJE: ' .. (cur and PixelFont.clean(cur.label) or 'NADA')),
            dx + 16, fy, C.muted)
    end
    -- Ações honestas por categoria.
    local ay = y + 400
    if it.def.cat == 'equipavel' then
        local isEq = eq[it.def.slot] == it.id
        if campaign.scene == 'battle' then
            text(self.fonts.small, 'TROCAR SÓ FORA DE LUTA', x + 28, ay, C.muted)
            text(self.fonts.small, 'W/S muda  ·  ESC volta', x + 28, ay + 22, C.muted)
        else
            text(self.fonts.small, isEq and 'E DESEQUIPAR  ·  W/S muda  ·  ESC volta'
                or 'E EQUIPAR  ·  W/S muda  ·  ESC volta', x + 28, ay, C.jade)
        end
    elseif it.def.cat == 'consumivel' then
        text(self.fonts.small, 'U USAR  ·  W/S muda  ·  ESC volta',
            x + 28, ay, C.jade)
    else
        text(self.fonts.small, 'ITEM-CHAVE — NÃO SE GASTA, NÃO SE JOGA FORA',
            x + 28, ay, C.muted)
        text(self.fonts.small, 'W/S muda  ·  ESC volta', x + 28, ay + 22, C.muted)
    end
end

function Render:campaignHelp(w, h, campaign)
    color(C.ink, .94); G.rectangle('fill', 0, 0, w, h)
    local width, x, y = 920, (w - 920) / 2, h / 2 - 280
    panel(x, y, width, 560, C.jade)
    text(self.fonts.small, 'GUIA DA CAMPANHA', x + 32, y + 24, C.jade)
    text(self.fonts.large, 'A Cidade Que Me Enterrou', x + 32, y + 50, C.text)
    local rows = {
        {'WASD', 'Andar livre', 'O mundo é contínuo: atravesse a colina e o refúgio a pé.'},
        {'E', 'Interagir', 'Fale com moradores, leia marcas, pegue o que era seu.'},
        campaign and campaign:flag('refugioNovo')
            and {'CAMINHOS', 'A praça e a pedra', 'Caminhe entre casas e cripta. O Marco dos Nomes liga Refúgio e Andlar.'}
            or {'PASSAGENS', 'As portas do fundo', 'No refúgio legado, a casa das passagens liga os destinos da campanha anterior.'},
        {'ENCONTROS', 'Criaturas visíveis viram duelos', 'O combate acontece numa arena própria, por turnos — intenções se anunciam antes de agir.'},
        {'NA ARENA', 'ESPAÇO ações · I inspecionar', 'A/D ou 1-8 escolhem o comando; WASD mira o golpe; poupador, fuga e a bolsa vivem no mesmo menu.'},
        {'BOLSA', 'Itens conquistados', 'Equipamento e consumíveis da campanha; alguns abrem ações no duelo.'},
        {'MORTE', 'Você volta para a cova', 'Nada se desfaz: mapas, decisões e itens permanecem.'},
        {'SAVE', 'Automático', 'Cada travessia e cada decisão grave grava a campanha em disco.'},
    }
    for i, row in ipairs(rows) do
        local ry = y + 96 + (i - 1) * 60
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
        local battle = campaign.scene == 'battle' and campaign.battle or nil
        local map = battle and battle.room or campaign.room
        local actor = battle and battle.player or campaign.player
        local feetX, feetY = Render.visualPosition(actor)
        -- Render HD (Fase 2+4): exploração e arena via G-buffer;
        -- flag renderer.hdEnabled.
        local hd = self.hdEnabled
        local v = hd
            and Render.layout(w, h, map, feetX * 2, feetY * 2, 76,
                battle and Render.battleStageH + 4 or 0,
                {cell = Render.CELL_HD, scale = 1})
            or Render.layout(w, h, map, feetX, feetY, 76,
                battle and Render.battleStageH + 4 or 0)
        if battle then battleClampTop(battle, v) end
        if not hd and not battle and map.id == 'hub' and map.outdoor and (campaign.panoramaTime or 0) > 0 then
            v = refugePanorama(w, h, map)
        end
        self.view = v
        if not self.canvas or self.canvas:getWidth() ~= v.w or self.canvas:getHeight() ~= v.h then
            if self.canvas then self.canvas:release() end
            self.canvas = G.newCanvas(v.w, v.h, {dpiscale = 1})
            self.canvas:setFilter('nearest', 'nearest')
        end
        -- Mesma leitura de impacto do arcade: trauma vira tremor na câmera e
        -- dano próprio lava a tela de vermelho por um instante.
        local trauma = self.reducedMotion and 0 or self.feedback.trauma^2
        local shakeX = round(math.sin(self.time * 51) * trauma * 4)
        local shakeY = round(math.sin(self.time * 67) * trauma * 3)
        G.push('all')
        G.setCanvas(self.canvas); G.clear(C.ink); G.setLineStyle('rough')
        G.translate(-v.left + shakeX, -v.top + shakeY)
        if campaign.scene == 'battle' and not hd then
            self:battleScene(campaign)
        elseif hd then
            local ok, err
            if battle then
                ok, err = pcall(HDWorld.drawBattle, self, campaign, v, map,
                    battle, {shakeX, shakeY})
            else
                ok, err = pcall(HDWorld.draw, self, campaign, v, map,
                    {shakeX, shakeY})
            end
            if not ok then
                self.hdEnabled = false
                love.filesystem.write('hd_error.txt',
                    debug.traceback(tostring(err)))
                print('[hd_world] falhou, caindo no render legado: '
                    .. tostring(err))
                G.setCanvas(self.canvas); G.setShader()
                G.setBlendMode('alpha'); G.setColor(1, 1, 1, 1)
                G.origin(); G.translate(-v.left + shakeX, -v.top + shakeY)
                if battle then self:battleScene(campaign)
                else self:worldCampaign(campaign) end
            end
        else self:worldCampaign(campaign) end
        G.pop()
        color(C.white); G.draw(self.canvas, v.x, v.y, 0, v.scale, v.scale)
        if battle then
            -- Palco do inimigo: desenhado fora do translate da câmera, na
            -- faixa reservada acima do canvas — sempre visível por inteiro.
            G.push('all')
            G.translate(v.x, v.y - (Render.battleStageH + 4) * v.scale)
            G.scale(v.scale)
            enemyStage(self, battle, math.floor(v.w / 2))
            G.pop()
        end
        if self.feedback.flash > 0 and not self.reducedMotion then
            color(C.red, self.feedback.flash * .8); G.rectangle('fill', 0, 0, w, h)
        end
        self:campaignHud(campaign, w, h)
        -- Cortina de entrada de sala/encontro, acima de tudo da cena.
        if (self.feedback.fade or 0) > 0 then
            color(C.ink, math.min(1, self.feedback.fade)); G.rectangle('fill', 0, 0, w, h)
        end
    end
    local scale = math.min(w / 1120, h / 720)
    G.scale(scale); w, h = w / scale, h / scale
    if screen == 'title' then self:campaignTitle(hasSave, w, h, self.titleMenu)
    elseif screen == 'opening' then self:opening(self.openingFrame or {}, w, h)
    elseif screen == 'help' then self:campaignHelp(w, h, campaign)
    elseif screen == 'bolsa' then self:campaignBag(w, h, campaign, self.bagState or {idx = 1})
    elseif screen == 'paused' then self:campaignPause(w, h, campaign) end
    if campaign and campaign.dialogue and screen ~= 'title'
        and screen ~= 'opening' then self:dialogue(campaign, w, h) end
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
    if (self.feedback.fade or 0) > 0 then
        color(C.ink, math.min(1, self.feedback.fade)); G.rectangle('fill', 0, 0, w, h)
    end
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
