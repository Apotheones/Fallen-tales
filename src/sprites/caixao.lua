-- V05_CAIXAO_W2 — caixão vazio em 2 células, 128x96 origem feet.
-- Horizontal de verdade agora: corpo comprido a 3/4, tampa corrida
-- encostada atrás (entreaberta, espiando o vão), corda de içar no
-- lado perto. Ainda "ocupa espaço demais" (W04) — a sala do depósito
-- vive em volta dele.
local K = require 'src.pixel_kit'

local g = K.new(128, 96)
local rng = K.rng('v05_caixao_w2', 139)

-- sombra de contato
for x = 8, 118 do
    K.pixel(g, x, 90, 'd')
    if rng.chance(.5) then K.pixel(g, x, 91, 'd') end
end

-- TAMPA: encostada atrás do caixão, inclinada — paralelogramo alto
-- na faixa y~30-70, verso 'v' com tábuas 'x' verticais
K.polygon(g, { 60, 28, 108, 24, 108, 72, 60, 76 }, 'v')
for x = 64, 104, 8 do
    K.line(g, x, 29 + math.floor((x - 60) / 12), x, 75, 'x')
end
K.line(g, 60, 28, 108, 24, 'W')     -- filete de topo da tampa
K.line(g, 60, 28, 60, 76, 'w')
K.line(g, 108, 24, 108, 72, 'x')
-- tábua separada da tampa: junta de sombra na base
K.line(g, 60, 76, 108, 72, 'k')

-- CORPO do caixão: trapezoide horizontal — ombro largo à esquerda
-- (lado da cabeceira), afunila aos pés à direita
-- face frontal 'w', topo 'W', interior aberto à esquerda
K.polygon(g, { 10, 62, 66, 58, 100, 60, 104, 82, 12, 88 }, 'w')
-- interior aberto: a boca do caixão à esquerda/centro (tampa fora)
K.polygon(g, { 14, 64, 62, 60, 66, 74, 16, 80 }, 'o')
-- rebordo da boca: 'W' em cima (luz), 'x' embaixo (sombra interna)
K.line(g, 14, 64, 62, 60, 'W'); K.line(g, 14, 64, 16, 80, 'W')
K.line(g, 62, 60, 66, 74, 'x'); K.line(g, 16, 80, 66, 74, 'x')
-- borda externa do corpo
K.line(g, 10, 62, 66, 58, 'W'); K.line(g, 66, 58, 100, 60, 'W')
K.line(g, 10, 62, 12, 88, 'w')
K.line(g, 12, 88, 104, 82, 'x'); K.line(g, 104, 82, 100, 60, 'x')
-- tábuas da lateral direita: juntas curtas
for x = 70, 98, 6 do
    K.line(g, x, 62, x + 1, 82, 'x')
end
-- fundo interno: 'q' leitura de tábua no vão (não é abismo puro)
for y = 64, 78 do for x = 18, 62 do
    if K.get(g, x, y) == 'o' and rng.chance(.35) then
        K.pixel(g, x, y, 'q')
    end
end end
-- corda de içar no lado da frente: laço vertical + pontas
for y = 66, 86 do
    K.pixel(g, 44, y, 'f'); K.pixel(g, 45, y, 'f')
end
K.pixel(g, 43, 72, 'f'); K.pixel(g, 46, 72, 'f')
-- pregos na face
K.pixel(g, 14, 66, 'i'); K.pixel(g, 15, 66, 'i')
K.pixel(g, 96, 70, 'i'); K.pixel(g, 97, 70, 'i')

local legend = {
    d = { ramp = 'stone', step = 1, h = 1 },
    o = { spec = 'abyss', h = 3 },
    q = { ramp = 'wood', step = 1, h = 4 },
    w = { ramp = 'wood', step = 4, h = 7 },
    W = { ramp = 'wood', step = 6, h = 8 },
    x = { ramp = 'wood', step = 2, h = 6 },
    v = { ramp = 'wood', step = 3, h = 6 },
    f = { ramp = 'bone', step = 4, h = 8 },
    i = { ramp = 'iron', step = 3, h = 7 },
    k = { spec = 'ink', h = 4 },
}

return {
    name = 'caixao', w = 128, h = 96, origin = 'feet',
    legend = legend,
    layers = { { name = 'caixao', albedo = K.string(g) } },
}
