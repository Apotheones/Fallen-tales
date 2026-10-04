-- src/hd_world.lua — render HD da exploração (Fase 2): o mesmo mundo do
-- drawCampaign, mas composto pelo pipeline G-buffer (albedo/normal/
-- emissivo) + Lighting + PostFX, em células artísticas de 64px (2× a
-- grade de simulação de 32). Simulação é só leitura: map.tiles/props/
-- campaign:entities()/Props.lightAnchor/shadowCaster alimentam a arte.
--
-- Contrato com render.lua: chamado DENTRO do translate da câmera com a
-- vista (Render.layout {cell=64,scale=1}) e o canvas de vista bound.
-- Desenha o frame inteiro nesse canvas; HUD/diálogo seguem legados.

local G = love.graphics
local Kit = require('src.hd_kit')
local Lighting = require('src.lighting')
local PostFX = require('src.postfx')
local Props = require('src.props')

local CELL = 64
local HDWorld = {}

-- kind/id de prop -> def DSL do Traço (src/sprites/NOME). O que não casa
-- recebe stub genérico baixo — placeholder honesto até a DSL crescer.
local PROP_SPRITE = {
    marco = 'marco', braseiro = 'braseiro', poco = 'poco',
    cisterna = 'poco', pocoRua = 'poco', placa = 'placa',
    placaRotas = 'placa', banco = 'bancada', bancada = 'bancada',
    mesa = 'mesa', cadeira = 'cadeira', estante = 'estante',
    prateleira = 'estante', arvore = 'arvore', cercado = 'cercado',
}

local function dirSuffix(f)
    if not f then return 's' end
    if math.abs(f.dy or 0) >= math.abs(f.dx or 0) then
        return (f.dy or 1) < 0 and 'n' or 's'
    end
    return (f.dx or 1) > 0 and 'e' or 'w'
end

local function visualPos(ent)
    local R = package.loaded['src.render']
    if R and R.visualPosition then return R.visualPosition(ent) end
    local g = ent.grid or {x = 0, y = 0}
    return (g.x - .5) * 32, (g.y - .5) * 32
end

-- Stub de prop genérico: caixa baixa de madeira — placeholder honesto.
local function propStub(x, y)
    if y >= 62 and x >= 8 and x <= 55 then
        local edge = y >= 88 or x <= 10 or x >= 53
        local v = Kit.hash(x, y, 11) * .04
        return edge and {.13, .10, .08, 1} or {.28 + v, .21 + v, .14, 1},
            edge and 6 or 9
    end
    return nil
end

-- Stub de ator genérico: capuz/figura escura (inimigos, NPCs sem def).
local function actorStub(x, y)
    if y >= 88 and x >= 22 and x <= 42 then return {.12, .10, .09, 1}, 4 end
    if y >= 26 and y <= 92 then
        local w2 = 13 + (y - 26) * .16
        if math.abs(x - 31.5) <= w2 then
            local v = Kit.hash(x, y, 12) * .03
            return {.22 + v, .20 + v, .24 + v, 1}, 7
        end
    end
    if y >= 10 and y <= 30 then
        local dx, dy = (x - 31.5) / 13, (y - 20) / 11
        if dx * dx + dy * dy <= 1 then return {.30, .26, .24, 1}, 10 end
    end
    return nil
end

local function sheetsFor(self)
    local s = self._sheets
    if s then return s end
    s = {}
    local function put(key, sheet) s[key] = sheet; s[key .. '_q'] = Kit.quads(sheet) end
    put('laje', Kit.sheet('piso_laje', 64, 64, nil))
    put('terra', Kit.sheet('piso_terra', 64, 64, nil))
    put('grama', Kit.sheet('piso_grama', 64, 64, nil))
    put('caminho', Kit.sheet('piso_caminho', 64, 64, nil))
    put('parede', Kit.sheet('parede', 64, 96, nil))
    put('porta', Kit.sheet('parede_porta', 64, 96, nil))
    put('pilar', Kit.sheet('pilar', 64, 96, nil))
    put('propStub', Kit.stubSheet(64, 96, propStub))
    put('actorStub', Kit.stubSheet(64, 96, actorStub))
    for _, dir in ipairs({'s', 'n', 'e', 'w'}) do
        put('viajante_' .. dir, Kit.sheet(
            dir == 's' and 'viajante' or 'viajante_' .. dir, 64, 96, nil))
        put('walk_' .. dir, Kit.sheet('viajante_walk_' .. dir, 64, 96, nil))
        put('npc_' .. dir, Kit.sheet('npc_doro_' .. dir, 64, 96, actorStub))
    end
    s.propCache = {}
    self._sheets = s
    return s
end

local function propQuad(self, s, prop)
    local name = PROP_SPRITE[prop.id] or PROP_SPRITE[prop.kind]
    if not name then return s.propStub, s.propStub_q[1] end
    local c = s.propCache[name]
    if c == nil then
        c = Kit.bakeViaDSL(name) or false
        s.propCache[name] = c
    end
    if not c then return s.propStub, s.propStub_q[1] end
    return c, Kit.quads(c)[1]
end

local function entityQuad(self, s, ent, t)
    if ent.enemy then return s.actorStub, s.actorStub_q[1] end
    local dir = dirSuffix(ent.facing)
    if ent.player then
        local moving = ent.motion and (ent.motion.remaining or 0) > 0
        local key = moving and s['walk_' .. dir] and 'walk_' .. dir
            or 'viajante_' .. dir
        local sh, qs = s[key], s[key .. '_q']
        local n = #qs
        local f = moving and (1 + math.floor(t * 9) % n)
            or (n > 1 and 1 + math.floor(t * 2) % n or 1)
        return sh, qs[math.min(f, n)]
    end
    local sh, qs = s['npc_' .. dir], s['npc_' .. dir .. '_q']
    if sh.stub then return s.actorStub, s.actorStub_q[1] end
    local n = #qs
    local f = n > 1 and 1 + math.floor(t * 2 + (ent.grid and ent.grid.x or 0)) % n or 1
    return sh, qs[math.min(f, n)]
end

local function ensureBuffers(self, w, h)
    local hd = self.hd
    if hd and hd.w == w and hd.h == h then return end
    hd = hd or {}
    self.hd = hd
    hd.w, hd.h = w, h
    for _, k in ipairs({'bufA', 'bufN', 'bufE'}) do
        if hd[k] then hd[k]:release() end
        hd[k] = G.newCanvas(w, h, {dpiscale = 1})
        hd[k]:setFilter('nearest', 'nearest')
    end
    hd.lighting = hd.lighting or Lighting.new(w, h)
    -- Mapa real tem ~100 occluders: 1.25× mantém borda macia dentro do
    -- orçamento de frame (as cenas técnicas ficam no adaptativo default).
    hd.lighting.lightScale = 1.25
    hd.lighting._lsFixed = true
    hd.lighting:resize(w, h)
    hd.postfx = hd.postfx or PostFX.new()
    hd.postfx:resize(w, h)
end

-- Chão: laje na praça do Refúgio com manchas de terra agrupadas (~3
-- células) — hash por célula lia como xadrez; hash por bloco agrupa.
local function floorKind(map, x, y)
    if map.id == 'hub' then
        return Kit.hash(math.floor(x / 3), math.floor(y / 3), 21) < .30
            and 'terra' or 'laje'
    end
    return 'terra'
end

function HDWorld.draw(renderer, campaign, v, map, shake)
    shake = shake or {0, 0}
    ensureBuffers(renderer, v.w, v.h)
    local hd = renderer.hd
    local s = sheetsFor(renderer)
    local t = renderer.time or 0
    local region = map.id or 'neutro'
    local prevCanvas = G.getCanvas()

    -- Camada por profundidade: tiles com peça (muro/pilar/portal), props e
    -- entidades, mesma ordem de pintor do render legado.
    local pieces = {}
    for _, tile in pairs(map.tiles or {}) do
        if tile.piece then
            pieces[#pieces + 1] = {kind = 'tile', t2 = tile,
                depth = tile.y * CELL, sx = tile.x}
        end
    end
    for _, prop in ipairs(map.props or {}) do
        if prop.state ~= 'taken' and not Props.bakesToGround(prop) then
            pieces[#pieces + 1] = {kind = 'prop', p = prop,
                depth = (prop.y + (prop.h or 1) - 1) * CELL, sx = prop.x}
        end
    end
    for _, ent in ipairs(campaign:entities()) do
        local fx, fy = visualPos(ent)
        pieces[#pieces + 1] = {kind = 'ent', e = ent,
            depth = fy * 2, sx = fx, fx = fx * 2, fy = fy * 2}
    end
    table.sort(pieces, function(a, b)
        return a.depth < b.depth or (a.depth == b.depth and a.sx < b.sx)
    end)

    local CLEAR = {
        albedo = {.045, .055, .075, 1},
        normal = {.5, .5, 1, 1},
        emissive = {0, 0, 0, 0},
    }
    local function channel(ch)
        local buf = ch == 'albedo' and hd.bufA or ch == 'normal' and hd.bufN
            or hd.bufE
        G.setCanvas(buf); G.clear(unpack(CLEAR[ch])); G.setColor(1, 1, 1, 1)
        for _, tile in pairs(map.tiles or {}) do
            if tile.ground ~= 'hole' then
                local kind = floorKind(map, tile.x, tile.y)
                local sh = s[kind]
                G.draw(sh[ch], s[kind .. '_q'][Kit.variant(sh, tile.x, tile.y)],
                    (tile.x - 1) * CELL, (tile.y - 1) * CELL)
            end
        end
        for _, p in ipairs(pieces) do
            if p.kind == 'tile' then
                local tile = p.t2
                local key = tile.piece == 'pillar' and 'pilar'
                    or tile.piece == 'portal' and 'porta' or 'parede'
                local sh = s[key]
                G.draw(sh[ch], s[key .. '_q'][1], (tile.x - 1) * CELL,
                    (tile.y - 1) * CELL - (sh.h - CELL))
            elseif p.kind == 'prop' then
                local sh, q = propQuad(renderer, s, p.p)
                local prop = p.p
                Kit.drawFeet(sh, q, ch,
                    (prop.x - 1) * CELL + (prop.w or 1) * CELL / 2,
                    (prop.y + (prop.h or 1) - 1) * CELL)
            else
                local sh, q = entityQuad(renderer, s, p.e, t)
                Kit.drawFeet(sh, q, ch, p.fx, p.fy)
            end
        end
    end
    channel('albedo'); channel('normal'); channel('emissive')
    G.setCanvas(prevCanvas)

    -- Luzes: ambiente da região + sol (outdoor) + âncoras de fogo dos props.
    local L = hd.lighting
    L:beginFrame()
    if map.outdoor then
        L:setAmbient(Kit.ambient(region))
        L:addLight({x = -640, y = map.h * CELL + 560, z = 460,
            color = {1.0, .76, .44}, intensity = 6.5, radius = 8600})
    else
        -- Interior sem dominante: o ambiente É a luz — frio-neutro legível
        -- (escuro legível != preto, Calina), os pools de brasa aquecem.
        L:setAmbient({.34, .33, .38})
    end
    for _, prop in ipairs(map.props or {}) do
        local ax, ay, tint, r = Props.lightAnchor(prop)
        if ax then
            L:addLight({x = ax * 2, y = ay * 2, z = 92,
                color = tint and {tint[1], tint[2], tint[3]} or {1.0, .58, .24},
                intensity = 1.6, radius = math.max((r or 14) * 2, 140),
                flicker = {amp = .12, speed = 6, phase = prop.x * 1.7}})
        end
    end
    -- Occluders: muros (merge em fileiras), pilares, props com altura, gente.
    local wallRuns = {}
    for _, tile in pairs(map.tiles or {}) do
        if tile.piece == 'wall' or tile.piece == 'portal' then
            wallRuns[#wallRuns + 1] = tile
        end
    end
    table.sort(wallRuns, function(a, b)
        return a.y < b.y or (a.y == b.y and a.x < b.x) end)
    local run = nil
    for _, tile in ipairs(wallRuns) do
        local px, py = (tile.x - 1) * CELL, (tile.y - 1) * CELL
        if run and py == run.y and px == run.x + run.w then
            run.w = run.w + CELL
        else
            if run then
                L:addOccluder({x = run.x, y = run.y - 20, w = run.w,
                    h = 60, height = 192})
            end
            run = {x = px, y = py, w = CELL}
        end
    end
    if run then
        L:addOccluder({x = run.x, y = run.y - 20, w = run.w,
            h = 60, height = 192})
    end
    for _, tile in pairs(map.tiles or {}) do
        if tile.piece == 'pillar' then
            L:addOccluder({x = (tile.x - 1) * CELL + 16,
                y = (tile.y - 1) * CELL + 44, w = 32, h = 16, height = 150})
        end
    end
    for _, prop in ipairs(map.props or {}) do
        local cx, cy, w2, hgt = Props.shadowCaster(prop)
        if cx then
            L:addOccluder({x = (prop.x - 1) * CELL, y = cy * 2 - 8,
                w = (prop.w or 1) * CELL, h = 16, height = hgt * 2})
        end
    end
    for _, p in ipairs(pieces) do
        if p.kind == 'ent' then
            L:addOccluder({x = p.fx - 15, y = p.fy - 7, w = 30, h = 12,
                height = 90})
        end
    end
    L:update(t, renderer.reducedMotion)

    local P = hd.postfx
    P:setRegion(region)
    P:setVignette(.16)
    P:beginScene()
    L:compose(hd.bufA, hd.bufN, hd.bufE, v.left - (shake[1] or 0),
        v.top - (shake[2] or 0))
    P:endScene()
    P:setEmissive(hd.bufE)
    -- O translate da câmera segue ativo: present desenha em px de canvas.
    G.push('all'); G.origin()
    G.setCanvas(prevCanvas)
    P:present(0, 0, 1)
    G.pop()
    -- Mesma leitura de custo das cenas técnicas: passe de luz + bloom.
    hd.statsClock = (hd.statsClock or 0) + 1
    if hd.statsClock >= 90 then
        hd.statsClock = 0
        print(string.format('[hd_world] light=%.3fms bloom=%.3fms lights=%d occluders=%d shadowQuads=%d fmt=%s',
            (L.stats and L.stats.lightPassMs) or 0,
            (P.stats and P.stats.bloomMs) or 0,
            (L.stats and L.stats.lights) or 0,
            (L.stats and L.stats.occluders) or 0,
            (L.stats and L.stats.shadowQuads) or 0,
            (P.stats and P.stats.format) or '?'))
    end
end

return HDWorld
