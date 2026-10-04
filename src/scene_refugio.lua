-- src/scene_refugio.lua — Fase 1: UMA sala real do Refúgio no pipeline HD.
-- O canto norte da Praça dos Nomes ao fim de tarde (direção da Calina,
-- DIRECAO_AMBIENTAL): fachada sul da pensão fechando o quadro, Marco dos
-- Nomes com runa jade emissiva, braseiro aceso, caminho de terra, viajante
-- e Aurel. Sol baixo do SO (esquerda-baixo da tela) projeta sombras longas
-- para cima-direita; preenchimento frio azul-violeta.
--
-- Sheets via src/hd_kit: defs do Traço (src/sprites/*) quando existem,
-- stubs no mesmo contrato enquanto o tileset sai — troca é por nome.

local G = love.graphics
local Render = require('src.render')
local Lighting = require('src.lighting')
local PostFX = require('src.postfx')
local Kit = require('src.hd_kit')

local CELL = Render.CELL_HD
local Scene = {}; Scene.__index = Scene

-- ── Pinturas stub (só até os defs do Traço chegarem) ───────────────────

local function terraPaint(x, y)
    -- Variação por MANCHA (não por texel): ruído por pixel vira confete sob
    -- luz forte; a praça precisa de superfície tranquila que recua.
    local v = Kit.hash(x, y) * .008
    local lump = Kit.hash(math.floor(x / 11), math.floor(y / 9), 3)
    return {.20 + v + lump * .035, .165 + v, .125 + v * .8, 1}, 2 + lump * 1.5
end

local function lajePaint(x, y)
    -- Lajotas de 32 com junta rebaixada; variação de tom por lajota quebra
    -- a leitura de grade que a Calina apontou na prova.
    local jx, jy = x % 32, y % 32
    local joint = jx < 1 or jy < 1
    local v = Kit.hash(math.floor(x / 32), math.floor(y / 32), 1) * .05
    if joint then return {.16, .165, .19, 1}, 1.5 end
    return {.19 + v, .195 + v, .235 + v, 1}, 3
end

local function gramaPaint(x, y)
    local base = terraPaint(x, y)
    local tuft = Kit.hash(math.floor(x / 5), math.floor(y / 4), 5)
    if tuft > .62 and (x % 5) < 2 and (y % 4) < 3 then
        return {.14, .22 + tuft * .08, .11, 1}, 5
    end
    return {.15 + base[1] * .3, .19 + base[2] * .3, .10, 1}, 3
end

local function caminhoPaint(x, y)
    -- Terra pisada: mais clara e lisa que a praça, bordas irregulares.
    local v = Kit.hash(x, y, 2) * .03
    return {.24 + v, .20 + v, .145 + v * .8, 1}, 2
end

local function marcoPaint(x, y)
    -- Estela de pedra com coluna de runas: UMA acesa em jade, o resto
    -- gravado apagado (Calina). Base larga, corpo estreito, topo chanfrado.
    if y >= 84 and x >= 10 and x <= 53 then return {.16, .17, .20, 1}, 6 end  -- base
    if y >= 8 and x >= 18 and x <= 45 then
        local runeCol = x >= 29 and x <= 34 and (y % 14) < 9
        local lit = runeCol and y >= 30 and y <= 44
        local carved = runeCol and not lit
        if lit then return {.20, .55, .45, 1}, 10, {.10, .85, .62} end
        if carved then return {.10, .11, .13, 1}, 9 end
        local edge = x <= 20 or x >= 43 or y <= 10
        local v = Kit.hash(x, y, 4) * .03
        return edge and {.09, .095, .115, 1} or {.155 + v, .165 + v, .20 + v, 1},
            edge and 8 or 10
    end
    return nil
end

local function mesaPaint(x, y)
    -- Mesa de praça: tampo largo em cima, pés embaixo.
    if y >= 48 and y <= 58 and x >= 8 and x <= 55 then
        local edge = y >= 56
        return {edge and .16 or .26, edge and .12 or .19, .12, 1}, 10
    end
    if y > 58 and y <= 92 and ((x >= 14 and x <= 19) or (x >= 44 and x <= 49)) then
        return {.15, .11, .08, 1}, 6
    end
    return nil
end

local function cadeiraPaint(x, y)
    if y >= 46 and y <= 56 and x >= 20 and x <= 42 then return {.22, .16, .11, 1}, 8 end
    if y >= 20 and y <= 46 and x >= 22 and x <= 28 then return {.19, .14, .10, 1}, 9 end
    if y > 56 and y <= 92 and ((x >= 20 and x <= 25) or (x >= 37 and x <= 42)) then
        return {.14, .10, .07, 1}, 5
    end
    return nil
end

local function aurelPaint(x, y)
    -- Aurel (o Doro): ombros largos, barba prata, avental com faixa diagonal.
    if y >= 88 and x >= 22 and x <= 42 then return {.12, .10, .09, 1}, 4 end
    if y >= 30 and y <= 92 then                                     -- avental/tronco
        local w2 = 15 + (y - 30) * .18
        if math.abs(x - 31.5) <= w2 then
            local sash = math.abs((x - 20) - (y - 30) * .55) < 3     -- faixa diagonal
            if sash then return {.34, .30, .24, 1}, 8 end
            local v = Kit.hash(x, y, 6) * .03
            return {.42 + v, .40 + v, .34 + v, 1}, 7
        end
    end
    if y >= 8 and y <= 32 then                                      -- cabeça+barba
        local cx, cy = 31.5, 20
        local dx, dy = (x - cx) / 14, (y - cy) / 13
        if dx * dx + dy * dy <= 1 then
            if y >= 24 then                                         -- barba prata
                local v = Kit.hash(x, y, 7) * .04
                return {.72 + v, .74 + v, .72 + v, 1}, 9
            end
            if y >= 16 and y <= 20 and math.abs(x - cx) <= 6 then return {.5, .38, .28, 1}, 10 end
            local v = Kit.hash(x, y, 8) * .03
            return {.55 + v, .42 + v, .32 + v, 1}, 10
        end
    end
    return nil
end

local function janelaPaint(lit)
    return function(x, y)
        -- Parede com caixilho: reboco claro, base de pedra; a acesa emite.
        if y < 10 then return {.24, .23, .26, 1}, 13 end
        local wx0, wy0, wx1, wy1 = 20, 34, 44, 62
        if x >= wx0 and x <= wx1 and y >= wy0 and y <= wy1 then
            local frame = x - wx0 < 2 or wx1 - x < 2 or y - wy0 < 2 or wy1 - y < 2
                or math.abs(x - 32) < 1 or math.abs(y - 48) < 1
            if frame then return {.10, .09, .10, 1}, 8 end
            if lit then return {.55, .36, .16, 1}, 7, {1, .55, .20} end
            return {.06, .07, .10, 1}, 7
        end
        local mortar = (y % 16) == 15
        if y >= 74 then return mortar and {.10, .10, .12, 1} or {.15, .16, .20, 1}, 9 end
        local v = Kit.hash(x, y, 9) * .03
        return {.42 + v, .40 + v, .34 + v, 1}, mortar and 8 or 10   -- reboco
    end
end

local function cantoPaint(x, y)
    -- Face cega da quina: mesma parede em meio-tom — prova do oblíquo.
    if y < 10 then return {.18, .18, .21, 1}, 13 end
    local mortar = (y % 16) == 15 or ((x + math.floor(y / 16) * 16) % 32) == 31
    if mortar then return {.065, .07, .09, 1}, 9 end
    local v = Kit.hash(x, y, 10) * .03
    return {.11 + v, .12 + v, .16 + v, 1}, 11
end

-- ── Layout da praça ────────────────────────────────────────────────────

-- Faixas de piso por célula: fachada nas fileiras 0-1, calçada de laje em
-- 2-3, praça de terra daí pra baixo; caminho entra inf-esquerdo e dobra.
local PATH = {{0, 9}, {1, 9}, {2, 9}, {3, 8}, {4, 8}, {5, 8}, {6, 8}, {7, 8},
    {8, 8}, {9, 8}, {10, 9}, {11, 9}, {12, 9}, {13, 10}, {14, 10}}
local function groundKind(cx, cy, w, h)
    for _, c in ipairs(PATH) do if c[1] == cx and c[2] == cy then return 'caminho' end end
    if cy <= 3 then return 'laje' end
    if cx >= w - 2 or cy >= h - 1 or (cx <= 1 and cy >= 7) then return 'grama' end
    return 'terra'
end

function Scene.new(opts)
    opts = opts or {}
    local self = setmetatable({
        renderer = opts.renderer, reducedMotion = opts.reducedMotion or false,
        t = 0, statClock = 0,
        room = {w = 18, h = 12},
        lighting = Lighting.new(64, 64), postfx = PostFX.new(),
    }, Scene)
    local W, H = self.room.w * CELL, self.room.h * CELL
    self.worldW, self.worldH = W, H
    local S = {}
    S.terra = Kit.sheet('piso_terra', 64, 64, terraPaint)
    S.laje = Kit.sheet('piso_laje', 64, 64, lajePaint)
    S.grama = Kit.sheet('piso_grama', 64, 64, gramaPaint)
    S.caminho = Kit.sheet('piso_caminho', 64, 64, caminhoPaint)
    S.wall = Kit.sheet('parede', 64, 96, nil) or Kit.stubSheet(64, 96, cantoPaint)
    S.janela = Kit.sheet('parede_janela', 64, 96, janelaPaint(true))
    S.janelaDark = Kit.bakeViaDSL('parede_janela')
        and S.janela or Kit.stubSheet(64, 96, janelaPaint(false))
    S.canto = Kit.sheet('parede_canto_d', 64, 96, cantoPaint)
    S.marco = Kit.sheet('marco', 64, 96, marcoPaint)
    S.brazier = Kit.sheet('braseiro', 64, 96, nil)
    S.actor = Kit.sheet('viajante', 64, 96, nil)
    S.aurel = Kit.sheet('npc_doro_s', 64, 96, aurelPaint)
    S.mesa = Kit.sheet('mesa', 64, 96, mesaPaint)
    S.cadeira = Kit.sheet('cadeira', 64, 96, cadeiraPaint)
    -- Conjunto da Botica (vida-refugio-props §1): poço da rua + placa de
    -- rotas — peças baixas e quentes; só o marco é alto e emissivo.
    S.poco = Kit.sheet('poco', 64, 96, mesaPaint)
    S.lampiao = Kit.sheet('lampiao', 64, 96, mesaPaint)
    S.placa = Kit.sheet('placa', 64, 96, cadeiraPaint)
    S.bancada = Kit.sheet('bancada', 64, 96, mesaPaint)
    self.sheets = S
    self.quads = {}
    for k, s in pairs(S) do self.quads[k] = Kit.quads(s) end
    -- Âncoras (pés, px-mundo) e a composição da Calina.
    self.marcoPos = {x = 6 * CELL, y = 4.2 * CELL}
    self.lampiaoPos = {x = 7.6 * CELL, y = 4.6 * CELL}
    self.brazierPos = {x = 8.2 * CELL, y = 4.4 * CELL}
    self.aurelPos = {x = 6.9 * CELL, y = 4.7 * CELL}
    self.actorPos = {x = 9 * CELL, y = 7.4 * CELL}
    self.mesaPos = {x = 14.4 * CELL, y = 9.5 * CELL}
    self.cadeiraPos = {x = 13.8 * CELL, y = 10 * CELL}
    self.firePos = {x = self.brazierPos.x, y = self.brazierPos.y - 46}
    self.sunPos = {x = -640, y = H + 560, z = 460}
    self.windowPos = {x = 10 * CELL + 32, y = 1.9 * CELL}
    self.postfx:setRegion(os.getenv('ARROWFALLEN_REGION') or 'refugio')
    self.postfx:setVignette(.16)
    -- Debug: cena composta crua, sem bloom/LUT/vignette. Envs içadas no
    -- ctor (M5): os.getenv por frame é syscall por chamada.
    if os.getenv('ARROWFALLEN_NO_POSTFX') then self.postfx.enabled = false end
    self._dumpG = os.getenv('ARROWFALLEN_DUMP_GBUFFER') ~= nil
    self._showLM = os.getenv('ARROWFALLEN_SHOW_LIGHTMAP') ~= nil
    self._probe = os.getenv('ARROWFALLEN_PROBE_LIGHT') ~= nil
    self._wantLights = tonumber(os.getenv('ARROWFALLEN_LIGHTS') or '0') or 0
    -- Ordem de pintor por y dos pés.
    self.pieces = {
        {key = 'marco', pos = self.marcoPos, occ = {x = -20, y = -10, w = 40, h = 14, height = 150}},
        {key = 'brazier', pos = self.brazierPos, occ = {x = -20, y = -10, w = 40, h = 14, height = 62}},
        {key = 'lampiao', pos = self.lampiaoPos, occ = {x = -10, y = -8, w = 20, h = 12, height = 120}},
        {key = 'aurel', pos = self.aurelPos, occ = {x = -15, y = -7, w = 30, h = 12, height = 88}},
        {key = 'actor', pos = self.actorPos, occ = {x = -15, y = -7, w = 30, h = 12, height = 90}},
        {key = 'bancada', pos = {x = 4.4 * CELL, y = 4.9 * CELL},
            occ = {x = -24, y = -10, w = 48, h = 14, height = 46}, frame = 1},
        {key = 'bancada', pos = {x = 15.4 * CELL, y = 8.6 * CELL},
            occ = {x = -24, y = -10, w = 48, h = 14, height = 46}, frame = 2},
        {key = 'poco', pos = {x = 12.6 * CELL, y = 6.4 * CELL},
            occ = {x = -22, y = -12, w = 44, h = 18, height = 55}},
        {key = 'placa', pos = {x = 2.2 * CELL, y = 8.3 * CELL},
            occ = {x = -10, y = -6, w = 20, h = 10, height = 75}},
        {key = 'mesa', pos = self.mesaPos, occ = {x = -24, y = -14, w = 48, h = 18, height = 48}},
        {key = 'cadeira', pos = self.cadeiraPos, occ = {x = -13, y = -8, w = 26, h = 12, height = 40}},
    }
    table.sort(self.pieces, function(a, b) return a.pos.y < b.pos.y end)
    return self
end

function Scene:update(dt)
    self.t = self.t + dt
end

-- Desenha um tile de piso (variante por célula) e a fachada de dois pavtos.
function Scene:assemble(v)
    local S, Q = self.sheets, self.quads
    local function world(fn)
        G.push('all'); G.translate(-v.left, -v.top); fn(); G.pop()
    end
    local CLEAR = {
        albedo = {.045, .055, .075, 1},   -- escuridão além da fachada
        normal = {.5, .5, 1, 1},          -- plano, neutro (contrato DSL)
        emissive = {0, 0, 0, 0},          -- PRETO: emissivo só onde a arte emite
    }
    local function channel(ch)
        G.clear(unpack(CLEAR[ch]))
        G.setColor(1, 1, 1, 1)
        world(function()
            -- piso por célula
            for cy = 2, self.room.h - 1 do for cx = 0, self.room.w - 1 do
                local kind = groundKind(cx, cy, self.room.w, self.room.h)
                local s = S[kind == 'caminho' and 'caminho' or kind]
                local q = Q[kind == 'caminho' and 'caminho' or kind][Kit.variant(s, cx, cy)]
                G.draw(s[ch], q, cx * CELL, cy * CELL)
            end end
            -- fachada: dois pavimentos de parede; UMA janela acesa (cx=10,
            -- Calina) — as demais usam o mesmo albedo e nada no emissivo.
            for cx = 0, self.room.w - 1 do
                local loK = cx == 17 and 'canto' or (cx == 10 and 'janela'
                    or cx == 4 and 'janelaDark' or 'wall')
                local hiK = cx == 17 and 'canto'
                    or (cx == 12 and 'janelaDark' or 'wall')
                local lo = (ch == 'emissive' and loK == 'janelaDark')
                    and S.wall or S[loK]
                local hi = (ch == 'emissive' and hiK == 'janelaDark')
                    and S.wall or S[hiK]
                G.draw(lo[ch], Q[loK][1], cx * CELL, 2 * CELL - lo.h)
                G.draw(hi[ch], Q[hiK][1], cx * CELL, CELL - hi.h)
            end
            -- peças em ordem de pintor; frame fixo para variantes de prop,
            -- idle animado para atores
            for _, p in ipairs(self.pieces) do
                local s = S[p.key]
                local f = p.frame or math.min(#Q[p.key], self:animFrame(p.key))
                Kit.drawFeet(s, Q[p.key][math.min(f, #Q[p.key])],
                    ch, p.pos.x, p.pos.y)
            end
            -- motes/pólen só dentro do feixe do sol (Calina): pontos quentes
            -- à deriva no terço iluminado, congelados em reduced-motion.
            if ch == 'albedo' then
                local t = self._reduced and 0 or self.t
                for i = 1, 14 do
                    local bx = (i * 137.3 + t * (2 + i * .4)) % (self.worldW * .55)
                    local by = (i * 89.7 + math.sin(t * .5 + i) * 6) % (self.worldH * .5)
                    G.setColor(1, .85, .55, .10 + .08 * math.sin(t + i * 2.1))
                    G.rectangle('fill', math.floor(bx + self.worldW * .08),
                        math.floor(by + self.worldH * .42), 2, 1)
                end
            end
        end)
    end
    G.setCanvas(self.bufAlbedo); channel('albedo')
    G.setCanvas(self.bufNormal); channel('normal')
    G.setCanvas(self.bufEmissive); channel('emissive')
    G.setCanvas()
end

-- Idle a ~2fps quando o sheet tem 2+ quadros de animação; tiles ficam em 1.
function Scene:animFrame(key)
    local n = self.sheets[key].frames or 1
    if key ~= 'actor' and key ~= 'aurel' then return 1 end
    return 1 + math.floor(self.t * 2) % n
end

function Scene:ensureBuffers(w, h)
    if self.bufW == w and self.bufH == h then return end
    self.bufW, self.bufH = w, h
    for _, k in ipairs({'bufAlbedo', 'bufNormal', 'bufEmissive'}) do
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
    self._reduced = reduced
    local v = Render.layout(w, h, self.room, self.actorPos.x, self.actorPos.y,
        8, 0, {cell = CELL, scale = 1})
    self.view = v
    self:ensureBuffers(v.w, v.h)
    self:assemble(v)
    if not self._dumped and self._dumpG then
        self._dumped = true
        for name, buf in pairs({albedo = self.bufAlbedo, normal = self.bufNormal,
            emissive = self.bufEmissive}) do
            local fd = buf:newImageData():encode('png')
            local f = assert(io.open('screenshots/refugio-hd-gbuffer-'
                .. name .. '.png', 'wb'))
            f:write(fd:getString()); f:close()
        end
    end
    local L = self.lighting
    L:beginFrame()
    -- Sol baixo do SO: âmbar dominante, quase direcional; sombras longas NE.
    L:setAmbient(Kit.ambient('refugio'))
    L:addLight({x = self.sunPos.x, y = self.sunPos.y, z = self.sunPos.z,
        color = {1.0, .76, .44}, intensity = 6.5, radius = 8600})
    -- Lampião/braseiro: eixo do calor humano, raio ~4 células, flicker leve.
    L:addLight({x = self.firePos.x, y = self.firePos.y, z = 46,
        color = {1.0, .55, .22}, intensity = 1.7, radius = 260,
        flicker = {amp = .06, speed = 4, phase = 2.1}})
    -- Janela acesa: terceiro ponto quente, pequeno e alto na fachada.
    L:addLight({x = self.windowPos.x, y = self.windowPos.y, z = 70,
        color = {1.0, .72, .38}, intensity = .9, radius = 190})
    -- Jade do marco: emissivo já floresce no bloom; este é só o ar em volta.
    L:addLight({x = self.marcoPos.x, y = self.marcoPos.y - 56, z = 40,
        color = {.25, .85, .70}, intensity = .65, radius = 175})
    -- Lampião real (Traço): lamparina ember alta no poste, pool ~3 células.
    L:addLight({x = self.lampiaoPos.x, y = self.lampiaoPos.y - 70, z = 80,
        color = {1.0, .62, .28}, intensity = 1.1, radius = 210,
        flicker = {amp = .05, speed = 3.5, phase = 4.4}})
    local want = self._wantLights
    for i = L:lightCount() + 1, math.min(want, 8) do
        local ph = i * 2.1
        L:addLight({x = 100 + (i * 173) % (self.worldW - 200),
            y = 200 + (i * 251) % (self.worldH - 320), z = 50,
            color = {.5 + .4 * math.sin(ph), .4 + .3 * math.cos(ph * 1.3), .7},
            intensity = 1.1, radius = 300,
            flicker = {amp = .1, speed = 4 + i, phase = ph}})
    end
    -- Occluders: fachada (sombra própria do beiral), marco, fogo, gente, mesa.
    L:addOccluder({x = 0, y = 0, w = self.worldW, h = 2 * CELL - 8, height = 170})
    for _, p in ipairs(self.pieces) do
        local o = p.occ
        L:addOccluder({x = p.pos.x + o.x, y = p.pos.y + o.y,
            w = o.w, h = o.h, height = o.height})
    end
    L:update(self.t, reduced)
    local P = self.postfx
    P:beginScene()
    L:compose(self.bufAlbedo, self.bufNormal, self.bufEmissive, v.left, v.top)
    P:endScene()
    -- Debug: mostra o lightmap cru na tela (ARROWFALLEN_SHOW_LIGHTMAP=1).
    if self._showLM then
        G.clear(0, 0, 0, 1); G.setColor(1, 1, 1, 1)
        G.draw(L.lightmap, 8, 8, 0, .5, .5)
        return
    end
    if self._probe and not self._probed then
        self._probed = true
        local id = L.lightmap:newImageData()
        for _, p in ipairs{{.25, .7}, {.5, .5}, {.8, .8}, {.5, .25}} do
            local r, g, b = id:getPixel(math.floor(p[1] * L.lw),
                math.floor(p[2] * L.lh))
            print(string.format('[probe] light(%.2f,%.2f) = %.3f %.3f %.3f',
                p[1], p[2], r, g, b))
        end
        local idA = self.bufAlbedo:newImageData()
        local idS = P.scene:newImageData()
        for _, p in ipairs{{.25, .7}, {.5, .5}, {.8, .8}, {.5, .25}} do
            local x, y = math.floor(p[1] * idA:getWidth()),
                math.floor(p[2] * idA:getHeight())
            local ar, ag, ab = idA:getPixel(x, y)
            local sr, sg, sb = idS:getPixel(x, y)
            print(string.format(
                '[probe] uv(%.2f,%.2f) albedo=%.3f %.3f %.3f  scene=%.3f %.3f %.3f',
                p[1], p[2], ar, ag, ab, sr, sg, sb))
        end
    end
    P:setEmissive(self.bufEmissive)
    G.clear(.016, .024, .043, 1)
    P:present(v.x, v.y, v.scale)
    if self.renderer and self.renderer.hudFont then
        G.setFont(self.renderer.hudFont); G.setColor(.51, .62, .66, 1)
        G.print(string.format('REFUGIO-HD praça dos nomes  |  luz %.2fms  bloom %.2fms  luzes %d  sombras %d  %s',
            (L.stats and L.stats.lightPassMs) or 0, (P.stats and P.stats.bloomMs) or 0,
            (L.stats and L.stats.lights) or 0, (L.stats and L.stats.shadowQuads) or 0,
            (P.stats and P.stats.format) or '?'), 12, 10)
    end
    self.statClock = self.statClock + 1
    if self.statClock >= 60 then
        self.statClock = 0
        print(string.format('[refugio-hd] light=%.3fms bloom=%.3fms lights=%d occluders=%d shadowQuads=%d fmt=%s',
            (L.stats and L.stats.lightPassMs) or 0, (P.stats and P.stats.bloomMs) or 0,
            (L.stats and L.stats.lights) or 0, (L.stats and L.stats.occluders) or 0,
            (L.stats and L.stats.shadowQuads) or 0, (P.stats and P.stats.format) or '?'))
    end
end

return Scene
