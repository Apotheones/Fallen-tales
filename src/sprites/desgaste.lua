-- V02_DESGASTE — zona de espera pisada (W03 wake courtyard), overlay de
-- chão 64x64 topleft. Mancha de terra compactada: miolo 'b'/'c' claro
-- pisado, orla 'e'/'d' fria, marcas de pé ralas 'r' e sulco de arrasto.
-- Desenhado por massas — sem salpico. 3 frames = desgastes por seed.
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

local function desgaste(seed)
    local rng = K.rng('v02_desgaste', seed)
    local g = K.new(W, H)
    local cx, cy = rng.int(24, 40), rng.int(24, 40)
    -- orla fria larga + miolo compactado
    blob(g, cx, cy, 22, 15, 'e', rng)
    blob(g, cx + rng.int(-3, 3), cy + rng.int(-2, 2), 17, 11, 'b', rng)
    blob(g, cx + rng.int(-2, 2), cy, 10, 6, 'c', rng)
    -- núcleo frio residual (terra batida à sombra)
    blob(g, cx - rng.int(2, 6), cy + rng.int(1, 4), 7, 4, 'd', rng)
    -- marcas de pé: meias-luas curtas ~3px, espaçadas — poucas
    local solo = K.sel_cover(g)
    for _ = 1, rng.int(5, 8) do
        local px, py = rng.int(8, W - 8), rng.int(8, H - 8)
        if K.get(solo, px, py) ~= '.' then
            K.pixel(g, px, py, 'r', solo)
            K.pixel(g, px + 1, py + rng.pick({ 0, 1 }), 'r', solo)
        end
    end
    -- um arrasto de travessa/roda
    if rng.chance(.7) then
        local y = cy + rng.int(-8, 8)
        K.line(g, cx - 14, y, cx + 14, y + rng.int(-2, 2), 'r')
    end
    return g
end

local legend = {
    e = { ramp = 'earth', step = 3, h = 1 }, -- orla fria
    b = { ramp = 'earth', step = 5, h = 1 }, -- compactado claro
    c = { ramp = 'earth', step = 6, h = 1 }, -- pó do miolo
    d = { ramp = 'earth', step = 2, h = 0 }, -- núcleo à sombra
    r = { ramp = 'earth', step = 1, h = 0 }, -- marca de pé/arrasto
}

return {
    name = 'desgaste', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'mancha',
        albedo = { K.string(desgaste(601)), K.string(desgaste(607)),
                   K.string(desgaste(613)) },
    } },
}
