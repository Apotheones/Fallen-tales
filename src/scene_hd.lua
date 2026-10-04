-- Cena técnica da Fase 0 (MEGAPLAN_VISUAL_HD §5): a fundação de render HD
-- provada numa sala escura com braseiro e um ator parado. Não é arte final —
-- é evidência de pipeline: G-buffer triplo (albedo/normal/emissivo), luz
-- direcional per-pixel por normal map, sombras projetadas por occluder,
-- bloom só no emissivo, LUT por região e vignette — tudo em célula 64px,
-- ator 64×96 com âncora nos pés, escala inteira.
--
-- Costura DSL (contrato-fase0-hd): cada sheet é {albedo, normal, emissive,
-- w, h, frames, origin='feet'|'topleft'} com Images RGBA8 nearest. Quando
-- src/sprite_dsl + src/sprites/* do Traço existirem, eles assam; enquanto
-- isso o stub local abaixo produz sheets no MESMO contrato para destravar
-- a prova — o swap é por nome, sem mudar a cena.

local G = love.graphics
local Render = require('src.render')
local Lighting = require('src.lighting')
local PostFX = require('src.postfx')

local CELL = Render.CELL_HD
local Scene = {}; Scene.__index = Scene

-- ── Sheets via DSL do Traço, com stub no mesmo contrato ────────────────

local function bakeViaDSL(name)
    local okDsl, DSL = pcall(require, 'src.sprite_dsl')
    local okDef, def = pcall(require, 'src.sprites.' .. name)
    if not (okDsl and okDef and DSL and DSL.bake and def) then return nil end
    local ok, sheet = pcall(DSL.bake, def)
    return ok and sheet and sheet.albedo and sheet or nil
end

-- Stub: paint(lx, ly) -> albedo{r,g,b,a}|nil, altura 0..15, emissivo{r,g,b}|nil.
-- Normal derivado por diferenças centrais na convenção do contrato:
-- +X direita, +Y PARA CIMA na tela, +Z pra fora; alpha = cobertura.
local function stubSheet(w, h, paint)
    local alb = love.image.newImageData(w, h)
    local emi = love.image.newImageData(w, h)
    local hgt = {}
    for y = 0, h - 1 do for x = 0, w - 1 do
        local a, ht, e = paint(x, y)
        if a then alb:setPixel(x, y, a[1], a[2], a[3], a[4] or 1) end
        hgt[y * w + x] = ht or 0
        if e then emi:setPixel(x, y, e[1], e[2], e[3], 1) end
    end end
    local nrm = love.image.newImageData(w, h)
    local function hh(x, y)
        return hgt[math.max(0, math.min(h - 1, y)) * w + math.max(0, math.min(w - 1, x))] or 0
    end
    local strength = 2.2
    for y = 0, h - 1 do for x = 0, w - 1 do
        local gx = (hh(x + 1, y) - hh(x - 1, y)) / 15 * strength
        local gy = (hh(x, y + 1) - hh(x, y - 1)) / 15 * strength
        -- tela: +y desce; normal de relevo = (-gx, +gy_em_cima, 1)
        local nx, ny, nz = -gx, gy, 1
        local len = math.sqrt(nx * nx + ny * ny + nz * nz)
        local _, _, _, cov = alb:getPixel(x, y)
        nrm:setPixel(x, y, nx / len * .5 + .5, ny / len * .5 + .5, nz / len * .5 + .5,
            cov > 0 and 1 or 0)
    end end
    local function img(d) local i = G.newImage(d); i:setFilter('nearest', 'nearest'); return i end
    return {albedo = img(alb), normal = img(nrm), emissive = img(emi),
        w = w, h = h, frames = 1, origin = 'feet',
        imageData = {albedo = alb, normal = nrm, emissive = emi}}
end

local function sheet(name, w, h, paint)
    return bakeViaDSL(name) or stubSheet(w, h, paint)
end

-- ── Pinturas stub (desenho técnico, não arte final) ────────────────────

local function hash(x, y, s) return ((x * 73 + y * 151 + (s or 0) * 997) % 97) / 97 end

local function floorPaint(x, y)
    local jx, jy = x % 32, y % 32
    local joint = jx == 0 or jy == 0
    local v = hash(math.floor(x / 32), math.floor(y / 32)) * .03
    if joint then return {.075, .082, .105, 1}, 1 end
    return {.135 + v, .145 + v, .185 + v, 1}, 3
end

local function wallPaint(x, y)
    -- Face da parede: fiadas de tijolo de 16px com argamassa; topo mais claro.
    local top = y < 10
    local mortar = (y % 16) == 15 or ((x + math.floor(y / 16) * 16) % 32) == 31
    if top then return {.22, .23, .27, 1}, mortar and 11 or 13 end
    if mortar then return {.085, .09, .115, 1}, 9 end
    local v = hash(x, y) * .04
    return {.15 + v, .16 + v, .21 + v, 1}, 12
end

local function brazierPaint(x, y)
    -- Braseiro 64×96 âncora nos pés: pedestal, taça de ferro e chama emissiva.
    if y >= 86 and y <= 95 and x >= 18 and x <= 45 then       -- base/pés
        local leg = (x - 18) % 14 < 4
        if leg or y >= 92 then return {.13, .11, .10, 1}, 5 end
    end
    if y >= 58 and y <= 85 then                               -- taça
        local cx, w2 = 31.5, 24 - (85 - y) * .55
        if math.abs(x - cx) <= w2 then
            local rim = y <= 62
            local v = rim and .30 or .16 + hash(x, y) * .03
            return {v, v * .82, v * .68, 1}, rim and 11 or 9,
                rim and {.9, .35, .12} or nil                 -- borda em brasa fraca
        end
    end
    if y >= 30 and y <= 60 then                               -- chama
        local t = (60 - y) / 30
        local cx = 31.5 + math.sin(y * .5) * 2
        local w2 = 16 * (1 - t * .55) - t * 6
        if math.abs(x - cx) <= w2 then
            local core = math.abs(x - cx) < w2 * .45
            return core and {.98, .78, .32, 1} or {.95, .45, .12, 1}, 8,
                core and {1, .85, .45} or {1, .45, .10}
        end
    end
    return nil
end

local function actorPaint(x, y)
    -- Viajante encapuzado 64×96: botas, manto que alarga em direção aos pés,
    -- capuz com face em sombra e dois pontos de olho. Sem emissivo — a prova
    -- de bloom fica limpa só no fogo.
    if y >= 88 and x >= 24 and x <= 40 then return {.11, .09, .08, 1}, 4 end  -- botas
    if y >= 34 and y <= 92 then                                             -- manto
        local w2 = 12 + (y - 34) * .24
        if math.abs(x - 31.5) <= w2 then
            local fold = hash(math.floor(x / 4), math.floor(y / 6)) * .05
            return {.16 + fold, .17 + fold, .24 + fold, 1}, 7
        end
    end
    if y >= 10 and y <= 36 then                                             -- capuz
        local cx, cy = 31.5, 24
        local dx, dy = (x - cx) / 13, (y - cy) / 15
        if dx * dx + dy * dy <= 1 then
            local face = y >= 22 and y <= 30 and math.abs(x - cx) <= 7
            if face then
                if (x == 28 or x == 35) and y == 26 then return {.85, .62, .30, 1}, 10 end
                return {.045, .04, .055, 1}, 9
            end
            local v = hash(x, y) * .03
            return {.20 + v, .21 + v, .30 + v, 1}, y < 16 and 13 or 11
        end
    end
    return nil
end

local function pillarPaint(x, y)
    -- Coluna baixa 64×64: capitel, fuste canelado, base — occluder de prova.
    if y <= 10 and x >= 8 and x <= 55 then return {.24, .25, .30, 1}, 13 end
    if y >= 52 and x >= 6 and x <= 57 then return {.16, .17, .21, 1}, 10 end
    if y >= 10 and y <= 52 and x >= 14 and x <= 49 then
        local flute = math.sin(x * .55) * .02
        return {.15 + flute, .16 + flute, .21 + flute, 1}, 11 + math.sin(x * .55) * 2
    end
    return nil
end

-- ── Montagem ───────────────────────────────────────────────────────────

function Scene.new(opts)
    opts = opts or {}
    local self = setmetatable({
        renderer = opts.renderer, reducedMotion = opts.reducedMotion or false,
        t = 0, statClock = 0,
        room = {w = 14, h = 9},
        lighting = Lighting.new(64, 64), postfx = PostFX.new(),
    }, Scene)
    local W, H = self.room.w * CELL, self.room.h * CELL
    self.worldW, self.worldH = W, H
    -- Sheets no contrato DSL: nomes reais quando o Traço entregar src/sprites/*.
    self.sheets = {
        floor = sheet('piso', 64, 64, floorPaint),
        wall = sheet('parede', 64, 64, wallPaint),
        brazier = sheet('braseiro', 64, 96, brazierPaint),
        actor = sheet('viajante', 64, 96, actorPaint),
        pillar = sheet('pilar', 64, 64, pillarPaint),
    }
    self.quads = {}
    for k, s in pairs(self.sheets) do
        self.quads[k] = G.newQuad(0, 0, s.w, s.h, s.albedo:getDimensions())
    end
    -- Âncoras em px-mundo (origem nos pés para peças; topleft para tiles).
    self.brazierPos = {x = 4.5 * CELL, y = 5.4 * CELL}
    self.actorPos = {x = 6.9 * CELL, y = 5.8 * CELL}
    self.pillarPos = {x = 7 * CELL, y = 2.8 * CELL}
    self.firePos = {x = self.brazierPos.x, y = self.brazierPos.y - 46}
    self.postfx:setRegion('refugio')
    self.postfx:setVignette(.22)
    return self
end

function Scene:update(dt)
    self.t = self.t + dt
end

local function drawFeet(sheet, quad, channel, x, y)
    G.draw(sheet[channel], quad, math.floor(x - sheet.w / 2), math.floor(y - sheet.h + 1))
end

-- Peças dinâmicas em ordem de pintor (pés crescentes); parede norte e
-- colunas laterais são estáticas e ocupam a moldura da sala.
function Scene:assemble(v)
    local S, Q = self.sheets, self.quads
    local function world(fn)
        G.push('all'); G.translate(-v.left, -v.top); fn(); G.pop()
    end
    -- Parede do DSL é 64×96 (cap + face oblíqua): a fileira norte ancora a
    -- base na linha do piso (y = 2*CELL) e as laterais sobem em passos de
    -- célula, a base de cada tile na base da célula.
    local function channel(ch)
        G.clear(ch == 'albedo' and .03 or ch == 'normal' and .5 or 0,
            ch == 'albedo' and .035 or ch == 'normal' and .5 or 0,
            ch == 'albedo' and .05 or 1, 1)
        G.setColor(1, 1, 1, 1)
        world(function()
            for cy = 2, self.room.h - 1 do for cx = 0, self.room.w - 1 do
                G.draw(S.floor[ch], Q.floor, cx * CELL, cy * CELL)
            end end
            for cx = 0, self.room.w - 1 do
                G.draw(S.wall[ch], Q.wall, cx * CELL, 2 * CELL - S.wall.h)
            end
            for cy = 2, self.room.h - 1 do
                G.draw(S.wall[ch], Q.wall, 0, (cy + 1) * CELL - S.wall.h)
                G.draw(S.wall[ch], Q.wall, (self.room.w - 1) * CELL, (cy + 1) * CELL - S.wall.h)
            end
            drawFeet(S.pillar, Q.pillar, ch, self.pillarPos.x, self.pillarPos.y + 32)
            drawFeet(S.brazier, Q.brazier, ch, self.brazierPos.x, self.brazierPos.y)
            drawFeet(S.actor, Q.actor, ch, self.actorPos.x, self.actorPos.y)
        end)
    end
    G.setCanvas(self.bufAlbedo); channel('albedo')
    G.setCanvas(self.bufNormal); channel('normal')
    G.setCanvas(self.bufEmissive); G.clear(0, 0, 0, 1); G.setColor(1, 1, 1, 1)
    world(function()
        drawFeet(S.brazier, Q.brazier, 'emissive', self.brazierPos.x, self.brazierPos.y)
        drawFeet(S.actor, Q.actor, 'emissive', self.actorPos.x, self.actorPos.y)
    end)
    G.setCanvas()
end

function Scene:ensureBuffers(w, h)
    if self.bufW == w and self.bufH == h then return end
    self.bufW, self.bufH = w, h
    for k, buf in pairs({bufAlbedo = true, bufNormal = true, bufEmissive = true}) do
        if self[k] then self[k]:release() end
        self[k] = G.newCanvas(w, h, {dpiscale = 1})
        self[k]:setFilter('nearest', 'nearest')
    end
    self.lighting:resize(w, h)
    self.postfx:resize(w, h)
end

function Scene:draw()
    local w, h = G.getDimensions()
    local reduced = self.renderer and self.renderer.reducedMotion or self.reducedMotion
    local v = Render.layout(w, h, self.room, self.actorPos.x, self.actorPos.y,
        8, 0, {cell = CELL, scale = 1})
    self.view = v
    self:ensureBuffers(v.w, v.h)
    self:assemble(v)
    -- ARROWFALLEN_DUMP_GBUFFER=1: despeja os três canais da vista uma vez —
    -- evidência do G-buffer (albedo/normal/emissivo) para o relatório.
    if not self._dumped and os.getenv('ARROWFALLEN_DUMP_GBUFFER') then
        self._dumped = true
        for name, buf in pairs({albedo = self.bufAlbedo, normal = self.bufNormal,
            emissive = self.bufEmissive}) do
            -- encode vai p/ FileData; io.open é quem garante o path no cwd.
            local fd = buf:newImageData():encode('png')
            local f = assert(io.open('screenshots/prova-hd-gbuffer-'
                .. name .. '.png', 'wb'))
            f:write(fd:getString()); f:close()
        end
    end
    local L = self.lighting
    L:beginFrame()
    L:setAmbient({.10, .115, .17})
    -- Key quente do braseiro (pontual, com flicker) e fill frio vindo do
    -- alto-esquerda — a sombra do ator nasce coerente com as duas.
    L:addLight({x = self.firePos.x, y = self.firePos.y, z = 44,
        color = {1.0, .52, .20}, intensity = 3.4, radius = 430,
        flicker = {amp = .16, speed = 6.5, phase = 1.3}})
    L:addLight({x = -100, y = -220, z = 190,
        color = {.38, .48, .85}, intensity = 1.9, radius = 1400})
    -- Estresse do orçamento §3.3 (ARROWFALLEN_LIGHTS=N): enche o array de
    -- uniform até N fontes para medir o custo real do passe de luz/sombra.
    local want = tonumber(os.getenv('ARROWFALLEN_LIGHTS') or '0') or 0
    for i = L:lightCount() + 1, math.min(want, 8) do
        local ph = i * 2.1
        L:addLight({x = 100 + (i * 173) % (self.worldW - 200),
            y = 140 + (i * 251) % (self.worldH - 280), z = 50,
            color = {.5 + .4 * math.sin(ph), .4 + .3 * math.cos(ph * 1.3), .7},
            intensity = 1.1, radius = 300,
            flicker = {amp = .1, speed = 4 + i, phase = ph}})
    end
    L:addOccluder({x = 0, y = 0, w = self.worldW, h = 2 * CELL, height = 120})
    L:addOccluder({x = self.brazierPos.x - 20, y = self.brazierPos.y - 10,
        w = 40, h = 14, height = 62})
    L:addOccluder({x = self.actorPos.x - 15, y = self.actorPos.y - 7,
        w = 30, h = 12, height = 90})
    L:addOccluder({x = self.pillarPos.x - 22, y = self.pillarPos.y + 22,
        w = 44, h = 16, height = 64})
    L:update(self.t, reduced)
    local P = self.postfx
    P:beginScene()
    L:compose(self.bufAlbedo, self.bufNormal, self.bufEmissive, v.left, v.top)
    P:endScene()
    P:setEmissive(self.bufEmissive)
    G.clear(.033, .046, .071, 1)
    P:present(v.x, v.y, v.scale)
    -- Leitura técnica da cena: custo dos passes em overlay e no console.
    if self.renderer and self.renderer.hudFont then
        G.setFont(self.renderer.hudFont); G.setColor(.51, .62, .66, 1)
        G.print(string.format('PROVA-HD fase0  |  luz %.2fms  bloom %.2fms  luzes %d  sombras %d  %s',
            (L.stats and L.stats.lightPassMs) or 0, (P.stats and P.stats.bloomMs) or 0,
            (L.stats and L.stats.lights) or 0, (L.stats and L.stats.shadowQuads) or 0,
            (P.stats and P.stats.format) or '?'), 12, 10)
    end
    self.statClock = self.statClock + 1
    if self.statClock >= 60 then
        self.statClock = 0
        print(string.format('[prova-hd] light=%.3fms bloom=%.3fms lights=%d occluders=%d shadowQuads=%d fmt=%s',
            (L.stats and L.stats.lightPassMs) or 0, (P.stats and P.stats.bloomMs) or 0,
            (L.stats and L.stats.lights) or 0, (L.stats and L.stats.occluders) or 0,
            (L.stats and L.stats.shadowQuads) or 0, (P.stats and P.stats.format) or '?'))
    end
end

return Scene
