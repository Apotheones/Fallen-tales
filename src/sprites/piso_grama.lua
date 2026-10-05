-- V01_GRAMA — relva sálvia do pátio, re-autoria do zero (padrão-ouro).
-- Tile 64x64, topleft, 4 frames = variantes de seed (frameUse='variant').
-- Direção: massas de musgo em dois tons (moleta 'd' funda, clareira 'l'
-- clara) e touceiras em CLUSTERS orgânicos — moitas agrupadas sobre
-- sombra própria 'x', não sementeiras uniformes. Terra 'e' aparece em
-- remendos raros; flor 'f'/'o' uma por tile no máximo. Hue-shift: sombra
-- moss.1-2 (teal frio), luz moss.5-6 (verde-dourado). h: sombra 0,
-- massa 1, lâmina 2.
local K = require 'src.pixel_kit'

local W, H = 64, 64

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

-- Touceiras autoradas: lâminas 't' (luz) e 'u' (meio) de pé na sombra
-- 'x' — lidas como moita, não como confete.
local TUFO = {
    K.parse([[
t..t.
tu.tt
tuttu
xxxxx]]),
    K.parse([[
.t.t.
tuttt
ttutu
xxxx.]]),
    K.parse([[
t.t.t
ttutt
tuttt
xxxxx]]),
    K.parse([[
t...t
tt.tt
tuttu
.xxx.]]),
    K.parse([[
u.u
tut
xxx]]),
    K.parse([[
t.t
utu
x.x]]),
    -- pendida p/ um lado (vento)
    K.parse([[
..tt.
.tut.
uttu.
xxxx.]]),
    -- cruzada baixa
    K.parse([[
t...t
.tut.
tuttt
xxxxx]]),
}

local FLOR = K.parse([[
f.f
fof
.t.
.x.]])

-- Um cluster de touceira: moleta de sombra 'x' + 2-5 tufos colados,
-- centro livre — o verde cresce em moita, não em grade.
local function moita(g, cx, cy, rng)
    -- saia de musgo 'd' sob a sombra 'x': a moita esfumaça na borda
    blob(g, cx, cy, rng.int(6, 8), rng.int(3, 5), 'd', rng)
    blob(g, cx, cy, rng.int(4, 6), rng.int(2, 3), 'x', rng)
    for _ = 1, rng.int(3, 5) do
        K.stamp(g, rng.pick(TUFO), cx + rng.int(-5, 4),
            cy + rng.int(-6, 3), 'topleft')
    end
    -- lâmina rala na saia da moita
    for _ = 1, rng.int(1, 3) do
        K.stamp(g, TUFO[rng.int(5, 6)], cx + rng.int(-9, 7),
            cy + rng.int(-7, 6), 'topleft')
    end
end

local function grama(seed)
    local rng = K.rng('v01_grama', seed)
    local g = K.new(W, H)
    K.rect(g, 1, 1, W, H, 'a')
    -- moletas fundas e clareiras: 3-4 + 2-3 massas moles
    for _ = 1, rng.int(3, 4) do
        blob(g, rng.int(6, W - 6), rng.int(6, H - 6),
            rng.int(8, 15), rng.int(5, 9), 'd', rng)
    end
    for _ = 1, rng.int(2, 3) do
        blob(g, rng.int(8, W - 8), rng.int(8, H - 8),
            rng.int(7, 13), rng.int(4, 8), 'l', rng)
    end
    -- remendo de terra raro (1 em ~2 tiles)
    if rng.chance(.5) then
        blob(g, rng.int(10, W - 10), rng.int(10, H - 10),
            rng.int(5, 9), rng.int(3, 6), 'e', rng)
    end
    -- clusters de touceira: 4-6 centros, moitas juntas
    for _ = 1, rng.int(4, 6) do
        moita(g, rng.int(8, W - 8), rng.int(8, H - 8), rng)
    end
    -- flor rara no miolo de uma moita qualquer
    if rng.chance(.4) then
        K.stamp(g, FLOR, rng.int(6, W - 9), rng.int(6, H - 10), 'topleft')
    end
    return g
end

local legend = {
    a = { ramp = 'moss', step = 3, h = 1 },  -- massa sálvia
    d = { ramp = 'moss', step = 2, h = 1 },  -- moleta funda
    l = { ramp = 'moss', step = 4, h = 1 },  -- clareira
    e = { ramp = 'earth', step = 4, h = 1 }, -- terra aparecendo
    x = { ramp = 'moss', step = 1, h = 0 },  -- sombra sob a moita
    u = { ramp = 'moss', step = 4, h = 2 },  -- lâmina média
    t = { ramp = 'moss', step = 5, h = 2 },  -- lâmina clara
    f = { spec = 'white', h = 2 },           -- pétala rara
    o = { ramp = 'gold', step = 6, h = 2 },  -- coração da flor
}

return {
    name = 'piso_grama', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    valueBand = { .35, .55 }, -- papel piso-iluminado (docs/PIXEL_KIT.md)
    layers = { {
        name = 'piso',
        albedo = { K.string(grama(101)), K.string(grama(103)),
                   K.string(grama(107)), K.string(grama(109)) },
    } },
}
