-- V01_TERRA — terra batida do pátio, re-autoria do zero (padrão-ouro).
-- Tile 64x64, origem topleft, 4 frames no contrato do renderer:
--   f1/f2 = campo quieto · f3 = beirada (rente a parede/sombra de
--   fachada) · f4 = trilha (zona de uso junto a rotas/exits).
-- Linguagem: massas de barro em dois tons (fria 'e' + núcleo 'd'),
-- lentes de desgaste 'b' alongadas no sentido do passo, lascas de
-- seixo DESENHADAS (luz+sombra+solo), torrões de 2px (nunca pixel
-- solto), trincas curtas. Tufos de grama só na beirada (f3).
-- Hue-shift real: fundo puxa earth.1-2 (frio), luz puxa earth.6-7
-- (barro seco morno). h: recuo 0, massa 1, seixo/tufo 2.
local K = require 'src.pixel_kit'

local W, H = 64, 64

-- Mancha orgânica: polígono de raio irregular — massa, nunca confete.
local function blob(g, cx, cy, rx, ry, c, rng, mask)
    local pts, n = {}, 9
    for i = 0, n - 1 do
        local a = i / n * math.pi * 2
        local j = 0.70 + rng.float() * 0.55
        pts[#pts + 1] = math.floor(cx + math.cos(a) * rx * j + 0.5)
        pts[#pts + 1] = math.floor(cy + math.sin(a) * ry * j + 0.5)
    end
    K.polygon(g, pts, c, mask)
end

-- Torrão de 2-3 px (dominó ou L) — o grão mínimo é par, nunca 1px.
local TORRAO = {
    K.parse('dd'), K.parse('dd\n.d'), K.parse('dd\nd.'),
    K.parse('d.\ndd'), K.parse('.d\ndd'),
}

-- Lasca de seixo: pedra com luz em cima-esquerda ('p'), lado 'q' e
-- solo de sombra 'r' embaixo — cluster desenhado, não pontilhado.
local SEIXO = {
    K.parse([[
.pp..pq.
pqpprpq.
.rr..r..]]),
    K.parse([[
..pq....
.ppqr.pq
pq.rrrpq
.r....r.]]),
    K.parse([[
.pp.
pqpq
r.rr
]]),
}

-- Trinca curta e viva: 4-7 px com uma quebra.
-- máscara de contexto p/ marcas: massa 'e'/'d' dilatada (trinca mora
-- junto à mancha, nunca solta no 'a')
local function ctxMassa(g)
    return K.mask_dilate(
        K.mask_or(K.sel_color(g, 'e'), K.sel_color(g, 'd')), 8, 2)
end

local function trinca(g, x, y, rng, mask)
    local dx = rng.pick({ 1, -1 })
    local n = rng.int(4, 7)
    local px, py = x, y
    for _ = 1, n do
        K.pixel(g, px, py, 'r', mask)
        px = px + dx
        if rng.chance(.3) then py = py + rng.pick({ -1, 1 }) end
    end
end

local function baseQuiet(g, rng)
    K.rect(g, 1, 1, W, H, 'a')
    -- massas frias: 3-5 lâminas largas com núcleo mais fundo deslocado
    local nm = rng.int(3, 5)
    for _ = 1, nm do
        local cx, cy = rng.int(6, W - 6), rng.int(6, H - 6)
        local rx, ry = rng.int(7, 14), rng.int(4, 8)
        blob(g, cx, cy, rx, ry, 'e', rng)
        blob(g, cx + rng.int(-3, 3), cy + rng.int(-2, 2),
            math.floor(rx * .45), math.floor(ry * .45), 'd', rng)
        -- mordidas de base na borda da mancha: quebra o contorno mole
        blob(g, cx + rng.int(-rx, rx), cy + rng.int(-ry, ry),
            3, 2, 'a', rng)
    end
    -- lente de desgaste (o passo): 1-2 bandas moles claras
    local nl = rng.int(1, 2)
    for _ = 1, nl do
        blob(g, rng.int(14, W - 14), rng.int(12, H - 10),
            rng.int(12, 22), rng.int(4, 6), 'b', rng)
    end
end

-- Poeira de grão: touceira miúda DESENHADA (3-5 px de 'c'/'b'), 2-3
-- grupos dentro da máscara — nunca corrente de grãos na borda.
local GRAO = {
    K.parse([[
.c.
cbc
.c.]]),
    K.parse([[
cc.
bcb
.cc]]),
    K.parse([[
.cc
bc.
cc.]]),
}
local function grao(g, rng, mask)
    local spots = {}
    for y = 1, H do for x = 1, W do
        if K.get(mask, x, y) ~= '.' then spots[#spots + 1] = { x, y } end
    end end
    if #spots == 0 then return end
    for _ = 1, rng.int(2, 3) do
        local p = spots[rng.int(1, #spots)]
        K.stamp(g, rng.pick(GRAO), p[1], p[2], 'topleft', mask)
    end
end

local function pedrinhas(g, rng, mask)
    for _ = 1, rng.int(1, 2) do
        K.stamp(g, rng.pick(SEIXO), rng.int(4, W - 10), rng.int(4, H - 6),
            'topleft', mask)
    end
end

local function torroes(g, rng, mask)
    for _ = 1, rng.int(5, 8) do
        K.stamp(g, rng.pick(TORRAO), rng.int(2, W - 3), rng.int(2, H - 3),
            'topleft', mask)
    end
end

-- f1/f2 — campo quieto: textura por massa, miolo respira
local function quieto(seed)
    local rng = K.rng('v01_terra', seed)
    local g = K.new(W, H)
    baseQuiet(g, rng)
    -- relevo interno das massas: covinhas 'r' + fio 'b' raro dentro de e/d
    local cm = ctxMassa(g)
    for _ = 1, rng.int(2, 3) do
        local px, py = rng.int(6, W - 6), rng.int(6, H - 6)
        if K.get(cm, px, py) ~= '.' then
            K.pixel(g, px, py, 'r', cm)
            K.pixel(g, px + 1, py, 'r', cm)
        end
    end
    trinca(g, rng.int(8, W - 12), rng.int(8, H - 12), rng, cm)
    if rng.chance(.6) then
        trinca(g, rng.int(8, W - 12), rng.int(8, H - 12), rng, cm) end
    pedrinhas(g, rng)
    torroes(g, rng)
    -- grão claro salpicado perto das lentes de desgaste
    grao(g, rng, K.sel_color(g, 'b'))
    return g
end

-- f3 — beirada: a borda norte do tile encosta numa parede — massa fria
-- colada na cota, fio de tufos e seixo escorrido junto ao rodapé.
local TUFINHO = {
    K.parse('t.t\ngtg\n.gg'), K.parse('.t.\ngtg\ngg.'),
    K.parse('tt.\nggg'), K.parse('.tt\nggg'),
}
local function beirada(seed)
    local rng = K.rng('v01_terra', seed)
    local g = K.new(W, H)
    baseQuiet(g, rng)
    -- faixa de sombra/umidade junto ao topo (encosta da massa vertical)
    local faixa = K.sel_rect(g, 1, 1, W, 14)
    for x = 1, W do
        local prof = 5 + math.floor(4 * math.sin(x * .35)
            + rng.float() * 4)
        for y = 1, math.min(14, prof) do
            if K.get(g, x, y) == 'a' or K.get(g, x, y) == 'b' then
                K.pixel(g, x, y, 'e', faixa)
            end
        end
    end
    for _ = 1, 2 do
        blob(g, rng.int(8, W - 8), rng.int(3, 8),
            rng.int(8, 13), rng.int(3, 5), 'd', rng, faixa)
    end
    -- fio de tufos e seixo escorrido na faixa
    for _ = 1, rng.int(3, 4) do
        K.stamp(g, rng.pick(TUFINHO), rng.int(2, W - 5), rng.int(1, 9),
            'topleft', faixa)
    end
    K.stamp(g, rng.pick(SEIXO), rng.int(4, W - 10), rng.int(8, 13),
        'topleft', faixa)
    trinca(g, rng.int(10, W - 14), rng.int(10, 16), rng, ctxMassa(g))
    torroes(g, rng)
    grao(g, rng, K.sel_color(g, 'b'))
    return g
end

-- f4 — trilha: lente de desgaste contínua atravessando E-W com fio de
-- poeira clara no miolo e torrões/seixos empurrados para as margens.
local function trilha(seed)
    local rng = K.rng('v01_terra', seed)
    local g = K.new(W, H)
    K.rect(g, 1, 1, W, H, 'a')
    local band = K.new(W, H)
    local y0, y1 = rng.int(22, 27), rng.int(40, 45)
    for x = 1, W do
        local t = y0 + math.floor(2.5 * math.sin(x * .16 + seed)
            + rng.float() * 2 + 0.5)
        local b = y1 + math.floor(2.5 * math.sin(x * .14 + seed * 2)
            + rng.float() * 2 + 0.5)
        for y = t, b do
            band.rows[y][x] = 'x'
            K.pixel(g, x, y, 'b')
        end
        -- fio de borda ralo: barro claro pisado caindo fora da trilha
        if rng.chance(.5) then K.pixel(g, x, t - 1, 'c') end
        if rng.chance(.5) then K.pixel(g, x, b + 1, 'c') end
    end
    -- rodadas gêmeas: dois fios fundos em CORRIDAS quebradas de 3-8px
    -- (não fileira pontilhada — a roda arrasta, não pica)
    for _, off in ipairs({ -6, 7 }) do
        local corrida = 0
        for x = 4, W - 4 do
            local y = math.floor((y0 + y1) / 2 + off
                + math.sin(x * .2) * 2 + .5)
            if corrida <= 0 and rng.chance(.18) then
                corrida = rng.int(3, 8)
            end
            if corrida > 0 then
                K.pixel(g, x, y, 'd', band)
                if corrida > 2 then K.pixel(g, x, y + 1, 'd', band) end
                corrida = corrida - 1
            end
        end
    end
    -- massas frias nas margens; seixo e torrão fora da trilha
    local margem = K.mask_not(band)
    for _ = 1, 3 do
        local cy = rng.chance(.5) and rng.int(4, 14) or rng.int(50, 60)
        blob(g, rng.int(8, W - 8), cy, rng.int(8, 13), rng.int(4, 7),
            'e', rng, margem)
    end
    pedrinhas(g, rng, margem)
    torroes(g, rng, margem)
    grao(g, rng, band)
    return g
end

local legend = {
    a = { ramp = 'earth', step = 4, h = 1 }, -- massa de barro
    e = { ramp = 'earth', step = 3, h = 1 }, -- massa fria/úmida
    d = { ramp = 'earth', step = 2, h = 1 }, -- núcleo pisado fundo
    r = { ramp = 'earth', step = 1, h = 0 }, -- trinca/depressão
    b = { ramp = 'earth', step = 5, h = 1 }, -- desgaste claro
    c = { ramp = 'earth', step = 7, h = 1 }, -- pó de barro seco
    p = { ramp = 'bone',  step = 3, h = 2 }, -- seixo claro, luz
    q = { ramp = 'bone',  step = 1, h = 2 }, -- seixo, sombra
    g = { ramp = 'moss',  step = 2, h = 1 }, -- tufo, base (beirada)
    t = { ramp = 'moss',  step = 4, h = 2 }, -- lâmina do tufo
}

return {
    name = 'piso_terra', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'piso',
        albedo = { K.string(quieto(11)), K.string(quieto(23)),
                   K.string(beirada(31)), K.string(trilha(43)) },
    } },
}
