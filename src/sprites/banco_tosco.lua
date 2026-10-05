-- V02_BANCO_TOSCO — banco de espera rústico do adro/pátio (W03 spare
-- seating), 64x96 origem feet. Dois pés de pedra bruta 'b'/'s' +
-- tábua corrida 'W'/'w' com ponta gasta; nada de marcenaria fina —
-- é o banco que alguém arrastou para perto do portão. Sombra de
-- contato 'd' sob os pés; musgo na pedra norte.
local K = require 'src.pixel_kit'

local g = K.new(64, 96)
local rng = K.rng('v02_banco_tosco', 97)

-- sombra de contato (chão)
for x = 14, 54 do
    K.pixel(g, x, 88, 'd')
    if x > 16 and x < 52 and rng.chance(.7) then K.pixel(g, x, 89, 'd') end
end

-- pés de pedra: blocos baixos 10x14, topo claro, base em sombra
local function pe(x0)
    K.rect(g, x0, 66, 12, 14, 's')
    K.rect(g, x0, 66, 12, 2, 'S')
    K.rect(g, x0, 78, 12, 2, 'd')
    K.rect(g, x0 + 10, 66, 2, 14, 'k')
    -- junta mediana da pedra
    for y = 68, 77 do if y % 5 == 3 then K.pixel(g, x0 + rng.int(2, 8), y, 'm') end end
    if rng.chance(.6) then
        K.pixel(g, x0 + rng.int(1, 4), 67, 'g')
        K.pixel(g, x0 + rng.int(1, 4), 68, 'g')
    end
end
pe(16); pe(42)

-- tábua: tábua grossa 'w' com verso 'v' embaixo, topo 'W', ponta
-- direita comida (desgaste de uso) e um nó desenhado
K.rect(g, 10, 58, 48, 6, 'w')          -- corpo
K.rect(g, 10, 58, 48, 1, 'W')          -- filete iluminado do topo
K.rect(g, 10, 59, 48, 1, 'W')
K.rect(g, 10, 64, 48, 2, 'v')          -- verso em sombra
-- junta da tábua (duas tábuas coladas)
for x = 12, 56 do
    if x % 13 == 5 then K.pixel(g, x, 60, 'x'); K.pixel(g, x, 61, 'x') end
end
-- ponta gasta à direita: come o canto
for i = 0, 3 do
    for dx = 0, i do
        K.pixel(g, 57 - dx, 58 + i, '.')
    end
end
for i = 0, 2 do K.pixel(g, 57 - i, 65 - i, '.') end
-- nó
K.pixel(g, 30, 60, 'x'); K.pixel(g, 31, 60, 'x'); K.pixel(g, 30, 61, 'x')
K.pixel(g, 31, 61, 'x'); K.pixel(g, 31, 59, 'x')
-- vergalhão de apoio sob a tábua (sombra dos pés no verso)
K.rect(g, 16, 66, 12, 1, 'k')
K.rect(g, 42, 66, 12, 1, 'k')

local legend = {
    k = { spec = 'ink', h = 4 },
    d = { ramp = 'stone', step = 1, h = 2 },  -- sombra/base pedra
    s = { ramp = 'stone', step = 3, h = 6 },  -- pé de pedra
    S = { ramp = 'stone', step = 5, h = 7 },  -- topo do pé
    m = { ramp = 'stone', step = 2, h = 5 },  -- junta
    W = { ramp = 'wood', step = 6, h = 9 },   -- topo da tábua, luz
    w = { ramp = 'wood', step = 4, h = 8 },   -- tábua
    v = { ramp = 'wood', step = 2, h = 7 },   -- verso da tábua
    x = { ramp = 'wood', step = 3, h = 8 },   -- junta/nó
    g = { ramp = 'moss', step = 2, h = 6 },   -- musgo na pedra
}

return {
    name = 'banco_tosco', w = 64, h = 96, origin = 'feet',
    legend = legend,
    layers = { { name = 'banco', albedo = K.string(g) } },
}
