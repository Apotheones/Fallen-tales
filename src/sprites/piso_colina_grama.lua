-- V04_COLINA_GRAMA — chão úmido da Colina dos Sepultados, 64x64
-- topleft, 4f variants. Re-autoria contra o veredito da Mira: nada de
-- salpico — massas frias de terra compactada entre tufos mortos.
-- Paleta fria: musgo jade apagado (moss.1-2), terra escura (earth.1-2),
-- agulheta morta 'd' em feixes curtos AUTORAIS, lâmina rala 'c' fria
-- de luar. Tufos rarefeitos — a colina é descampada, não jardim.
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

-- feixe de agulheta morta: 3-4 lâminas curtas tombadas, desenhadas
local AGULHA = {
    K.parse([[
d.d
ddd
.dd]]),
    K.parse([[
dd.
ddd
d.d]]),
}

local function tile(seed)
    local rng = K.rng('v04_colina_grama', seed)
    local g = K.new(W, H)
    K.rect(g, 1, 1, W, H, 'e')
    -- massas frias: musgo apagado + barro à mostra, orgânicas
    blob(g, rng.int(12, 50), rng.int(12, 50), rng.int(12, 18),
        rng.int(8, 12), 'm', rng)
    blob(g, rng.int(10, 54), rng.int(10, 54), rng.int(8, 14),
        rng.int(6, 10), 'd', rng)
    blob(g, rng.int(14, 50), rng.int(14, 50), rng.int(6, 10),
        rng.int(4, 7), 'a', rng)
    -- clareira de luar: faixa 'c' rala, fria
    if rng.chance(.5) then
        blob(g, rng.int(16, 48), rng.int(14, 46), rng.int(8, 12),
            rng.int(3, 5), 'c', rng)
    end
    -- tufos mortos rarefeitos: 2-4/tile, feixes desenhados
    for _ = 1, rng.int(2, 4) do
        K.stamp(g, rng.pick(AGULHA), rng.int(4, W - 8),
            rng.int(4, H - 8), 'topleft')
    end
    -- fio de musgo jade encostado nas bordas das massas
    local bm = K.mask_erode(K.sel_cover(g), 8, 1)
    for _ = 1, rng.int(2, 3) do
        local x, y = rng.int(4, W - 4), rng.int(4, H - 4)
        if K.get(bm, x, y) == '.' then
            K.pixel(g, x, y, 'g'); K.pixel(g, x + 1, y, 'g')
        end
    end
    return K.string(g)
end

local legend = {
    e = { ramp = 'earth', step = 2, h = 0 },  -- barro úmido
    a = { ramp = 'earth', step = 3, h = 0 },  -- barro claro
    m = { ramp = 'moss', step = 2, h = 1 },   -- musgo apagado
    d = { ramp = 'earth', step = 1, h = 0 },  -- agulheta morta
    c = { ramp = 'stone', step = 4, h = 1 },  -- clareira de luar
    g = { ramp = 'moss', step = 3, h = 1 },   -- musgo jade vivo
}

return {
    name = 'piso_colina_grama', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'chao',
        albedo = { tile(701), tile(709), tile(713), tile(719) },
    } },
}
