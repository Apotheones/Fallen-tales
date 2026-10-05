-- V01_CAMINHO — calçada de pedra e terra do pátio, re-autoria do zero.
-- Tile 64x64, topleft, 9 frames direcionais (contrato do renderer):
-- frameMap = {'ew','ns','ne','se','sw','nw','t_nwe','cross','cap_w'}.
-- Linguagem: faixa de lajedo DENSO — pedras de 6-13px assentadas em
-- leito de barro 'e', orientadas pelo eixo da faixa (tangente nas
-- curvas). Bordas comem pedras pela metade; fio de pó 'c' na margem;
-- margem = terra comum com massas/seixos/tufos (nunca dentro da faixa).
-- Hue-shift: leito/junta frios (earth.1-3), quina da pedra quente
-- (stone.6) — sol baixo do SO pega na quina topo-esquerda.
-- h: junta 0, leito 1, pedra 2, quina 2.
local K = require 'src.pixel_kit'

local W, H = 64, 64

local function blob(g, cx, cy, rx, ry, c, rng, mask)
    local pts, n = {}, 8
    for i = 0, n - 1 do
        local a = i / n * math.pi * 2
        local j = 0.70 + rng.float() * 0.55
        pts[#pts + 1] = math.floor(cx + math.cos(a) * rx * j + 0.5)
        pts[#pts + 1] = math.floor(cy + math.sin(a) * ry * j + 0.5)
    end
    K.polygon(g, pts, c, mask)
end

-- Pedra assentada: corpo 's', quina iluminada topo-esquerda 'S',
-- assento 'k' base-direita, cantos cortados. w/h são o ALONGAMENTO
-- (along = comprimento no sentido da viagem).
local function pedra(g, x, y, w, h, rng, mask, corpo)
    corpo = corpo or 's'
    for j = 0, h - 1 do for i = 0, w - 1 do
        local canto = (i == 0 or i == w - 1) and (j == 0 or j == h - 1)
        if not canto then K.pixel(g, x + i, y + j, corpo, mask) end
    end end
    for i = 1, w - 2 do if rng.chance(.8) then
        K.pixel(g, x + i, y, 'S', mask) end end
    for j = 1, h - 2 do if rng.chance(.7) then
        K.pixel(g, x, y + j, 'S', mask) end end
    for i = 1, w - 2 do if rng.chance(.7) then
        K.pixel(g, x + i, y + h - 1, 'k', mask) end end
    for j = 1, h - 2 do if rng.chance(.7) then
        K.pixel(g, x + w - 1, y + j, 'k', mask) end end
    if rng.chance(.35) then
        K.pixel(g, x + rng.int(2, math.max(2, w - 3)),
            y + rng.int(1, math.max(1, h - 3)), 'v', mask)
    end
end


-- Pedras dentro da faixa: grelha escalonada com jitter generoso,
-- qualquer célula cujo centro caia na máscara recebe pedra — densa o
-- bastante para cobrir arcos e cruzamentos. Alongamento segue o eixo.
local function lajedo(g, band, rng, eixo)
    local along = (eixo == 'v')
    local quadrado = (eixo == 'x')
    local pitchB = 7   -- passo entre fileiras
    local row = 0
    for b = -6, H + 6, pitchB do
        row = row + 1
        local shift = (row % 2 == 0) and rng.int(2, 6) or 0
        local a = shift + rng.int(-2, 0)
        while a < W + 6 do
            local w = quadrado and rng.int(6, 9)
                or (along and rng.int(5, 8) or rng.int(7, 12))
            local h = quadrado and rng.int(6, 9)
                or (along and rng.int(7, 12) or rng.int(5, 8))
            -- mistura de calibre: 1 em ~10 é lajão, 1 em ~7 é lasca miúda
            local tcal = rng.float()
            if tcal < .10 then
                w = w + rng.int(4, 6); h = h + rng.int(2, 4)
            elseif tcal < .24 then
                w = math.max(4, w - rng.int(3, 5))
                h = math.max(4, h - rng.int(2, 3))
            end
            local sa = a + rng.int(-1, 1)
            local sb = b + rng.int(-1, 1)
            local cx = along and (sb + math.floor(h / 2))
                or (sa + math.floor(w / 2))
            local cy = along and (sa + math.floor(w / 2))
                or (sb + math.floor(h / 2))
            if cx >= 1 and cx <= W and cy >= 1 and cy <= H
                and K.get(band, cx, cy) ~= '.' then
                local c = 's'
                local t = rng.float()
                if t < .14 then c = 'v' elseif t < .24 then c = 'w' end
                pedra(g, sa, sb, w, h, rng, band, c)
            end
            a = a + (along and h or w) + rng.int(2, 4)
        end
    end
end

local SEIXO = {
    K.parse([[
.pp..pq.
pqppupq.
.uu..u..]]),
    K.parse([[
..pq....
.ppqu.pq
pq.uuupq
.u....u.]]),
}
local TUFO = {
    K.parse('t.t\ngtg\ngg.'), K.parse('.t.\n.tt\nggg'),
    K.parse('tt\ngg'), K.parse('t.t\nuut'),
}
local function margem(g, band, rng)
    local fora = K.mask_not(band)
    for _ = 1, rng.int(2, 3) do
        blob(g, rng.int(6, W - 6), rng.int(6, H - 6),
            rng.int(6, 11), rng.int(4, 7), 'e', rng, fora)
    end
    for _ = 1, rng.int(1, 2) do
        K.stamp(g, rng.pick(SEIXO), rng.int(3, W - 10),
            rng.int(3, H - 6), 'topleft', fora)
    end
    -- tufos em moitas encostadas na borda da faixa (2-3 colados)
    for _ = 1, rng.int(1, 2) do
        local bx, by = rng.int(4, W - 6), rng.int(4, H - 6)
        for _ = 1, rng.int(2, 3) do
            K.stamp(g, rng.pick(TUFO),
                bx + rng.int(-3, 3), by + rng.int(-2, 3),
                'topleft', fora)
        end
    end
    -- fio de pó 'c' na borda: em corridas (trechos de 3-8 px com
    -- cobertura cheia alternando com trechos secos), nunca rendado
    local corrida = 0
    for y = 1, H do for x = 1, W do
        if K.get(band, x, y) == '.' then
            local toca = K.get(band, x - 1, y) ~= '.'
                or K.get(band, x + 1, y) ~= '.'
                or K.get(band, x, y - 1) ~= '.'
                or K.get(band, x, y + 1) ~= '.'
            if toca then
                if corrida <= 0 and rng.chance(.12) then
                    corrida = rng.int(3, 8)
                end
                if corrida > 0 then
                    K.pixel(g, x, y, 'c')
                    corrida = corrida - 1
                end
            end
        end
    end end
end

local function faixaBase(g, band, rng, eixo)
    K.rect(g, 1, 1, W, H, 'a')
    for y = 1, H do for x = 1, W do
        if band.rows[y][x] ~= '.' then g.rows[y][x] = 'e' end
    end end
    lajedo(g, band, rng, eixo)
    -- bolsos de terra na faixa: pedra que faltou, leito à mostra —
    -- o caminho é usado, não perfeito
    local dentro = K.mask_erode(band, 8, 2)
    for _ = 1, rng.int(1, 3) do
        blob(g, rng.int(6, W - 6), rng.int(6, H - 6),
            rng.int(3, 6), rng.int(2, 4), 'e', rng, dentro)
        if rng.chance(.5) then
            blob(g, rng.int(6, W - 6), rng.int(6, H - 6),
                2, 2, 'd', rng, dentro)
        end
    end
    margem(g, band, rng)
    return K.string(g)
end

-- Faixas ----------------------------------------------------------------

local function bandEW(rng)
    local band = K.new(W, H)
    local y0, y1 = rng.int(15, 19), rng.int(45, 49)
    for x = 1, W do
        local t = y0 + math.floor(3 * math.sin(x * .21 + rng.float() * 6)
            + rng.float() * 2.4)
        local b = y1 + math.floor(3 * math.sin(x * .17 + rng.float() * 6)
            + rng.float() * 2.4)
        for y = t, b do band.rows[y][x] = 'x' end
    end
    return band
end

local function bandNS(rng)
    local band = K.new(W, H)
    local x0, x1 = rng.int(15, 19), rng.int(45, 49)
    for y = 1, H do
        local l = x0 + math.floor(3 * math.sin(y * .19 + rng.float() * 6)
            + rng.float() * 2.4)
        local r = x1 + math.floor(3 * math.sin(y * .23 + rng.float() * 6)
            + rng.float() * 2.4)
        for x = l, r do band.rows[y][x] = 'x' end
    end
    return band
end

local function bandArco(rng, cx, cy, kx, ky)
    local band = K.new(W, H)
    local s1, s2 = rng.float() * 6, rng.float() * 6
    for y = 1, H do for x = 1, W do
        local dx, dy = (x - cx) * kx, (y - cy) * ky
        if dx >= 0 and dy >= 0 then
            local d = math.sqrt(dx * dx + dy * dy)
            local ang = math.atan2(dy, dx)
            local rin = 19 + 3 * math.sin(ang * 5 + s1)
            local rout = rin + 25 + 3 * math.sin(ang * 3 + s2)
            if d >= rin and d <= rout then band.rows[y][x] = 'x' end
        end
    end end
    return band
end

local function bandN(rng)
    local band = K.new(W, H)
    local x0, x1 = rng.int(27, 30), rng.int(37, 41)
    for y = 1, H do
        local l = x0 + math.floor(2 * math.sin(y * .3 + rng.float() * 5))
        local r = x1 + math.floor(2 * math.sin(y * .27 + rng.float() * 5))
        for x = l, r do band.rows[y][x] = 'x' end
    end
    return band
end

local function monta(band, seed, eixo)
    local g = K.new(W, H)
    return faixaBase(g, band, K.rng('v01_caminho', seed), eixo)
end

local f = {}
f[1] = function() return monta(bandEW(K.rng('b1', 7)), 311, 'h') end
f[2] = function() return monta(bandNS(K.rng('b2', 11)), 313, 'v') end
-- arcos: eixo misto — pedras quase quadradas (along nulo) leem nos dois
-- sentidos; a máscara da coroa já dá a curva.
f[3] = function() return monta(bandArco(K.rng('b3', 13), 65, 0, -1, 1), 317, 'x') end
f[4] = function() return monta(bandArco(K.rng('b4', 17), 65, 65, -1, -1), 331, 'x') end
f[5] = function() return monta(bandArco(K.rng('b5', 19), 0, 65, 1, -1), 337, 'x') end
f[6] = function() return monta(bandArco(K.rng('b6', 23), 0, 0, 1, 1), 347, 'x') end
f[7] = function()
    local r = K.rng('b7', 29)
    return monta(K.mask_or(bandEW(r), bandN(K.rng('b7b', 31))), 349, 'h')
end
f[8] = function()
    local r = K.rng('b8', 37)
    return monta(K.mask_or(bandEW(r), bandNS(K.rng('b8b', 41))), 353, 'h')
end
f[9] = function() -- ponta cega, boca só em W
    local r = K.rng('b9', 43)
    local band = bandEW(r)
    local cxE, cyE = 38, 32
    for y = 1, H do for x = 1, W do
        if x > cxE then band.rows[y][x] = '.' end
    end end
    for y = 1, H do for x = cxE, W do
        local dx, dy = x - cxE, y - cyE
        if dx * dx + dy * dy <= 15 * 15 then band.rows[y][x] = 'x' end
    end end
    return monta(band, 359, 'h')
end

local legend = {
    a = { ramp = 'earth', step = 4, h = 1 }, -- margem de barro
    e = { ramp = 'earth', step = 2, h = 1 }, -- massa fria / leito
    d = { ramp = 'earth', step = 1, h = 0 }, -- junta funda no leito
    c = { ramp = 'earth', step = 6, h = 1 }, -- pó na borda da faixa
    s = { ramp = 'stone', step = 4, h = 2 }, -- pedra da calçada
    S = { ramp = 'stone', step = 6, h = 2 }, -- quina iluminada
    k = { ramp = 'stone', step = 2, h = 1 }, -- assento da pedra
    v = { ramp = 'stone', step = 5, h = 2 }, -- pedra clara / desgaste
    w = { ramp = 'stone', step = 3, h = 2 }, -- pedra fria
    p = { ramp = 'bone',  step = 3, h = 2 }, -- seixo na margem, luz
    q = { ramp = 'bone',  step = 1, h = 2 }, -- seixo na margem, sombra
    u = { ramp = 'earth', step = 1, h = 0 }, -- solo sob o seixo
    g = { ramp = 'moss',  step = 2, h = 1 }, -- tufo, base
    t = { ramp = 'moss',  step = 4, h = 2 }, -- lâmina do tufo
}

return {
    name = 'piso_caminho', w = W, h = H, origin = 'topleft',
    frameUse = 'direction',
    frameMap = { 'ew', 'ns', 'ne', 'se', 'sw', 'nw',
        't_nwe', 'cross', 'cap_w' },
    legend = legend,
    -- papel caminho: contraste mínimo +0.08 vs piso ao redor
    valueBand = { vs = 'piso_terra', delta = .08 },
    layers = { {
        name = 'caminho',
        albedo = { f[1](), f[2](), f[3](), f[4](), f[5](),
                   f[6](), f[7](), f[8](), f[9]() },
    } },
}
