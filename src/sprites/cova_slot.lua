-- V06_COVA_SLOT — slot de sepultura marcada, decal de chão 64x64
-- topleft (sem occluder — deita sob os pés, encosta na lápide).
-- Diferencia da cova aberta do protagonista: este é o slot FECHADO/
-- assentado — rebordo de pedra pálida completo + terra cortada nas
-- bordas + interior escuro mas rasos. Lê sepultura deliberada.
local K = require 'src.pixel_kit'

local g = K.new(64, 64)
local rng = K.rng('v06_cova_slot', 149)

-- eixo vertical (a cova aponta p/ a lápide acima): slot ~18x36
-- rebordo de pedra pálida: moldura completa com juntas e lascas
local x0, y0, x1, y1 = 23, 14, 41, 50
-- moldura 'S' larga no topo (recebeu a laje / fica p/ a lápide)
K.rect(g, x0, y0, x1 - x0 + 1, 3, 'S')
-- laterais mais finas 's' com juntas 'k' espaçadas
for y = y0 + 3, y1 - 2 do
    K.pixel(g, x0, y, 's'); K.pixel(g, x1, y, 's')
    if y % 7 == 1 then K.pixel(g, x0, y, 'k'); K.pixel(g, x1, y, 'k') end
end
K.rect(g, x0, y1 - 1, x1 - x0 + 1, 2, 's')
-- lascas/branqueio no rebordo (a pedra que recebeu sol)
for _ = 1, 4 do
    local x = rng.int(x0 + 1, x1 - 1)
    K.pixel(g, x, y0 + rng.int(0, 1), 'w')
end
-- terra cortada: fila de terra viva entre rebordo e buraco — as
-- paredes da cova são terra seca 'e' com fio 'r' de corte
for y = y0 + 3, y1 - 2 do
    K.pixel(g, x0 + 1, y, 'e'); K.pixel(g, x0 + 2, y, 'e')
    K.pixel(g, x1 - 1, y, 'e'); K.pixel(g, x1 - 2, y, 'e')
    if y % 8 == 3 then K.pixel(g, x0 + 1, y, 'r') end
end
for x = x0 + 1, x1 - 1 do
    K.pixel(g, x, y0 + 3, 'e'); K.pixel(g, x, y1 - 2, 'e')
end
-- interior: escuro mas não abismo — fundo de terra 'D' com 'o' só
-- no miolo superior (onde a lápide faria sombra)
K.rect(g, x0 + 3, y0 + 4, x1 - x0 - 5, y1 - y0 - 7, 'D')
K.rect(g, x0 + 3, y0 + 4, x1 - x0 - 5, 10, 'o')
-- uns torrões caídos dentro
K.pixel(g, x0 + 5, y0 + 20, 'a'); K.pixel(g, x0 + 6, y0 + 21, 'e')
K.pixel(g, x1 - 6, y0 + 30, 'e')
-- degrau de terra onde a parede cedeu (canto inferior direito)
K.pixel(g, x1 - 3, y1 - 4, 'e'); K.pixel(g, x1 - 4, y1 - 3, 'a')

-- respingos de terra ao redor do slot (revolver antigo, assentado)
K.pixel(g, x0 - 2, y0 + 8, 'e'); K.pixel(g, x0 - 1, y0 + 9, 'a')
K.pixel(g, x1 + 1, y0 + 22, 'e'); K.pixel(g, x1 + 2, y0 + 23, 'e')
K.pixel(g, x0 - 1, y1 + 1, 'a'); K.pixel(g, x1 + 1, y1 + 2, 'e')
-- torrão descansando no rebordo (ninguém varreu)
K.stamp(g, K.parse([[ae
ee]]), x0 - 4, y0 + 16, 'topleft')

local legend = {
    o = { spec = 'abyss', h = 0 },            -- sombra interna superior
    D = { ramp = 'earth', step = 1, h = 0 },  -- fundo de terra
    e = { ramp = 'earth', step = 3, h = 1 },  -- terra cortada
    a = { ramp = 'earth', step = 4, h = 1 },  -- torrão claro
    r = { ramp = 'earth', step = 1, h = 0 },  -- corte da pá
    s = { ramp = 'stone', step = 3, h = 2 },  -- rebordo lateral
    S = { ramp = 'stone', step = 5, h = 3 },  -- rebordo pálido, topo
    w = { ramp = 'stone', step = 6, h = 3 },  -- lasca clara
    k = { spec = 'ink', h = 1 },              -- junta
}

return {
    name = 'cova_slot', w = 64, h = 64, origin = 'topleft',
    legend = legend,
    layers = { { name = 'slot', albedo = K.string(g) } },
}
