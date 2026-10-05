-- V02_MARCA_PARTIDA — resíduo violeta da partida, decal de chão 64x64
-- topleft. Símbolo AUTORAL, não salpico: meia-lua quebrada de marcas
-- 'v' + três traços centrais 'V' + chamuscado 'd' fraco no miolo.
-- Emissivo CONTIDO: violet.4/5 com ei 0.3/0.45 — resíduo que ainda
-- respira, sem virar neon. nada dispara bloom.
local K = require 'src.pixel_kit'

local g = K.new(64, 64)
local rng = K.rng('v02_marca_partida', 83)

local cx, cy, r = 32, 32, 18

-- chamuscado fraco sob o símbolo (apoio visual, não emite)
for y = 1, 64 do for x = 1, 64 do
    local d = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
    if d < r - 8 and rng.chance(.18) then K.pixel(g, x, y, 'd') end
end end

-- meia-lua quebrada: arco de ~200° feito de marcas de 2-3 px com
-- interrupções desenhadas — a marca é escrita, não splatter
local function marcaArco(a0, a1)
    local i = 0
    for deg = a0, a1, 4 do
        i = i + 1
        local rad = deg * math.pi / 180
        local rr = r + math.floor(1.6 * math.sin(deg * .4) + .5)
        local x = math.floor(cx + rr * math.cos(rad) + .5)
        local y = math.floor(cy + rr * math.sin(rad) + .5)
        -- traço: marcas de 2 px com uma falha a cada ~6 marcas
        if i % 6 ~= 0 then
            K.pixel(g, x, y, 'v')
            if i % 4 == 0 then K.pixel(g, x + 1, y, 'v') end
        end
    end
end
marcaArco(-30, 160)          -- arco principal aberto embaixo-direita
marcaArco(190, 235)          -- fragmento solto

-- traços centrais: três barras curtas que convergem (a "partida")
for i = 0, 5 do
    K.pixel(g, cx - 8 + i, cy + 2 + math.floor(i * .4), 'V')
end
for i = 0, 4 do
    K.pixel(g, cx + 8 - i, cy + 3 + math.floor(i * .3), 'V')
end
for i = 0, 4 do
    K.pixel(g, cx - 1, cy - 7 + i, 'V')
end
-- pó violeta residual: 4-6 grãos ao longo do arco (raro, contido)
for _ = 1, rng.int(4, 6) do
    local deg = rng.int(-40, 220)
    local rad = deg * math.pi / 180
    local x = math.floor(cx + (r - 3) * math.cos(rad) + .5)
    local y = math.floor(cy + (r - 3) * math.sin(rad) + .5)
    if x >= 2 and x <= 62 and y >= 2 and y <= 62 then
        K.pixel(g, x, y, 'v')
    end
end

local legend = {
    d = { ramp = 'earth', step = 1, h = 0 },              -- chamuscado
    v = { ramp = 'violet', step = 3, h = 0,
          e = 'violet.4', ei = .3 },                       -- resíduo
    V = { ramp = 'violet', step = 4, h = 0,
          e = 'violet.5', ei = .45 },                      -- traço ativo
}

return {
    name = 'marca_partida', w = 64, h = 64, origin = 'topleft',
    legend = legend,
    layers = { {
        name = 'marca',
        albedo = K.string(g),
        emissive = K.string((function()
            local e = K.new(64, 64)
            for y = 1, 64 do for x = 1, 64 do
                local c = K.get(g, x, y)
                if c == 'v' or c == 'V' then e.rows[y][x] = c end
            end end
            return e
        end)()),
    } },
}
