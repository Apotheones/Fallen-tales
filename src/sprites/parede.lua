-- V01_PAREDE — face de arrimo do pátio (muro de contenção entre cotas),
-- re-autoria do zero. Tile 64x96, topleft, 4 frames = variantes por seed
-- com ENCAIXE LATERAL garantido: colunas 1-16 e 49-64 fixas por paridade
-- de fiada em todos os frames; o miolo 17-48 é o que varia.
-- Desenho: capa de pedra lavrada em capstones grandes (juntas fixas em
-- x=14/34/52), lip 'l' em sombra, face de alvenaria corrida — fiadas de
-- alturas alternadas, juntas de argamassa fria 'm', pedras claras 'a',
-- pedra orgulhosa 'B' (h=8), trincas 'k' e musgo 'g' perto da base.
-- Sol do SO: rim 'C'/'n' quente; sombra funda 'd' no rodapé.
-- h: capa 15, lip 13, pedra 7, orgulhosa 8, junta 6, trinca 5, base 4.
local K = require 'src.pixel_kit'

local W, H = 64, 96

local function blob(g, cx, cy, rx, ry, c, rng, mask)
    local pts, n = {}, 7
    for i = 0, n - 1 do
        local a = i / n * math.pi * 2
        local j = 0.72 + rng.float() * 0.5
        pts[#pts + 1] = math.floor(cx + math.cos(a) * rx * j + 0.5)
        pts[#pts + 1] = math.floor(cy + math.sin(a) * ry * j + 0.5)
    end
    K.polygon(g, pts, c, mask)
end

-- Bordas fixas por paridade de fiada (16 cols cada lado):
--   A: junta nas colunas 16 e 64  ·  B: junta nas 9 e 57
local EA = 'bbbbbbbbbbbbbbbm'
local EB = 'bbbbbbbbmbbbbbbb'

-- Miolo de fiada (32 cols, globais 17-48): pedra 'b' com juntas 'm'
-- nas posições dadas; 'a' marca acento; 'k' trinca/lasca.
local function fiada(juntas, acentos)
    local t = {}
    for i = 1, 32 do t[i] = 'b' end
    for _, p in ipairs(juntas) do t[p] = 'm' end
    for _, a in ipairs(acentos or {}) do
        for i = a[1], a[2] do
            if t[i] == 'b' then t[i] = 'a' end
        end
    end
    return table.concat(t)
end

local function faceParede(g, rng, motif)
    -- fiadas de 6 linhas + junta corrida; paridade alterna o deslocamento
    local y = 35
    local fiadas = { 6, 7, 6, 7, 6, 7, 6 }   -- ritmo irregular das fiadas
    for f, alt in ipairs(fiadas) do
        local eb = (f % 2 == 0) and EB or EA
        -- juntas e acentos calculados UMA vez por fiada — a pedra ocupa a
        -- fiada inteira; variar por linha virava serragem de pontos.
        local jts = {}
        local x = rng.int(3, 7)
        while x < 30 do
            jts[#jts + 1] = x
            x = x + rng.int(9, 14)
        end
        local acc = {}
        if rng.chance(.25) then
            local ax = rng.int(2, 26)
            acc[#acc + 1] = { ax, ax + rng.int(4, 7) }
        end
        local mid = fiada(jts, acc)
        for r = 0, alt - 1 do
            local yy = y + r
            if yy > 83 then break end
            K.patch(g, { rows = {
                { x = 1, y = yy, text = eb },
                { x = 17, y = yy, text = mid },
                { x = 49, y = yy, text = eb },
            } })
        end
        -- pedra orgulhosa (1 por fiada, ~metade das fiadas): bloco
        -- conformado DEPOIS das fileiras — corpo 'B' na fiada toda,
        -- assento 'k' na última linha da fiada. Posição ancora na
        -- fiada, não flutua.
        if rng.chance(.5) then
            local bx = rng.int(18, 44)
            local bw = rng.int(4, 7)
            for rr = 0, alt - 2 do
                for dx = 0, bw do
                    if K.get(g, bx + dx, y + rr) == 'b' then
                        K.pixel(g, bx + dx, y + rr, 'B')
                    end
                end
            end
            for dx = 0, bw do
                if K.get(g, bx + dx, y + alt - 1) == 'b' then
                    K.pixel(g, bx + dx, y + alt - 1, 'k')
                end
            end
        end
        -- junta corrida (morta) entre fiadas
        if y + alt <= 83 then K.rect(g, 1, y + alt, W, 1, 'm') end
        y = y + alt + 1
    end
    -- base: pedrão de assentamento 'd' com juntas fixas
    for yy = 84, 96 do
        K.patch(g, { rows = { { x = 1, y = yy,
            text = 'ddddddmddddddddddddmddddddddddmddddddddddddddmddddddddddddd' } } })
    end
    -- trinca autorada: UMA linha fina e direcional (ou nenhuma), com
    -- lasca só nas pontas — nunca campo de pontos.
    if motif == 'trinca' then
        local tx = rng.int(20, 44)
        local ty = rng.int(36, 48)
        local dir = rng.pick({ -1, 1 })
        local px = tx
        for i = 0, rng.int(9, 15) do
            K.pixel(g, px, ty + i, 'k')
            if i % 3 == 2 then px = px + dir end
        end
        K.pixel(g, tx - dir, ty - 1, 'k')
        K.pixel(g, tx, ty - 1, 'k')
    end
    -- musgo subindo da base + nas juntas baixas
    for _ = 1, rng.int(2, 4) do
        blob(g, rng.int(4, W - 4), rng.int(76, 90),
            rng.int(3, 7), rng.int(1, 3), 'g', rng)
    end
end

local function capa(g, rng)
    K.rect(g, 1, 1, W, 2, 'C')          -- rim norte (quente)
    K.rect(g, 1, 3, W, 27, 'c')         -- campo do topo
    K.rect(g, 1, 30, W, 1, 'C')         -- rim sul
    K.rect(g, 1, 31, W, 4, 'l')         -- lip frontal em sombra
    -- capstones: juntas fixas p/ encaixe lateral; tom por pedaço
    local tons = { 'c', 'v', 'n', 'c' }
    local jx = { 14, 34, 52 }
    local x0 = 2
    for i = 1, 4 do
        local x1 = (jx[i] or (W - 1)) - 1
        local rr = K.rng('capa' .. i, 7 + i)
        if tons[i] ~= 'c' or rr.chance(.5) then
            K.rect(g, x0, 3, x1 - x0 + 1, 27, tons[i])
        end
        -- desgaste: manchas moles 'w' no topo de alguns capstones
        if rr.chance(.6) then
            blob(g, rng.int(x0 + 4, x1 - 4), rng.int(10, 22),
                rng.int(4, 7), rng.int(3, 6), 'w', rng)
        end
        x0 = jx[i] and (jx[i] + 1) or x1 + 2
    end
    for _, j in ipairs(jx) do K.rect(g, j, 3, 1, 27, 'm') end
    -- musgo nos nós das juntas e beira norte
    for _ = 1, rng.int(1, 2) do
        blob(g, rng.pick({ rng.int(3, 8), rng.int(W - 9, W - 3) }),
            rng.int(4, 10), rng.int(2, 5), rng.int(1, 2), 'g', rng)
    end
    if rng.chance(.5) then
        blob(g, rng.pick(jx) + rng.int(-1, 1), rng.int(6, 24),
            rng.int(2, 4), rng.int(2, 5), 'g', rng)
    end
end

-- Motif por variante — as 4 faces não podem carimbar a mesma marca:
-- f1 limpa · f2 trinca · f3 remendo de fiada miúda · f4 pedra caída.
local function parede(seed, motif)
    local rng = K.rng('v01_parede', seed)
    local g = K.new(W, H)
    capa(g, rng)
    faceParede(g, rng, motif)
    if motif == 'remendo' then
        K.rect(g, 20, 56, 18, 12, 'a')
        for r = 58, 66, 2 do K.rect(g, 20, r, 18, 1, 'm') end
        for cx = 24, 34, 5 do K.line(g, cx, 56, cx, 67, 'm') end
    elseif motif == 'falta' then
        local fx, fy = rng.int(22, 40), rng.int(50, 62)
        K.rect(g, fx, fy, 8, 5, 'd')
        K.rect(g, fx - 1, fy - 1, 10, 1, 'm')
        K.rect(g, fx - 1, fy + 5, 10, 1, 'm')
        K.pixel(g, fx - 1, fy, 'm'); K.pixel(g, fx - 1, fy + 4, 'm')
        K.pixel(g, fx + 8, fy, 'm'); K.pixel(g, fx + 8, fy + 4, 'm')
    end
    return K.string(g)
end

local legend = {
    C = { ramp = 'stone', step = 7, h = 15 }, -- rim da capa (luz)
    c = { ramp = 'stone', step = 5, h = 15 }, -- topo da capa
    v = { ramp = 'stone', step = 4, h = 15 }, -- capstone frio
    n = { ramp = 'stone', step = 6, h = 15 }, -- capstone claro
    w = { ramp = 'stone', step = 3, h = 15 }, -- desgaste no topo
    l = { ramp = 'stone', step = 3, h = 13 }, -- lip frontal
    b = { ramp = 'stone', step = 4, h = 7 },  -- pedra da face
    a = { ramp = 'stone', step = 5, h = 7 },  -- pedra clara
    B = { ramp = 'stone', step = 6, h = 8 },  -- pedra orgulhosa
    m = { ramp = 'stone', step = 2, h = 6 },  -- argamassa
    d = { ramp = 'stone', step = 1, h = 4 },  -- base em sombra
    k = { spec = 'ink', h = 5 },              -- trinca
    g = { ramp = 'moss',  step = 2, h = 6 },  -- musgo
}

return {
    name = 'parede', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'parede',
        albedo = { parede(501, 'limpa'), parede(509, 'trinca'),
                   parede(521, 'remendo'), parede(523, 'falta') },
    } },
}
