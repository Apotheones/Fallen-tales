-- V05_SEPULTURA — a cova aberta do protagonista (colina 5,3), 64x96
-- origem feet. O buraco, não a pedra: retângulo funerário aberto no
-- chão, rebordo de laje pálida (onde a tampa saía) no topo direito,
-- terra revolvida 'e'/'a' amontoada nos dois lados, fundo 'o' com
-- piso de barro úmido 'D'. É um objeto de chão — a escavação desce
-- do plano do piso.
local K = require 'src.pixel_kit'

local g = K.new(64, 96)
local rng = K.rng('v05_sepultura', 131)

-- montículo de terra revolvida: massa orgânica à esquerda/em volta
local function blob(cx, cy, rx, ry, c, mask)
    local pts = {}
    for i = 0, 8 do
        local a = i / 9 * math.pi * 2
        local j = 0.7 + rng.float() * .5
        pts[#pts + 1] = math.floor(cx + math.cos(a) * rx * j + .5)
        pts[#pts + 1] = math.floor(cy + math.sin(a) * ry * j + .5)
    end
    K.polygon(g, pts, c, mask)
end

-- a cova: retângulo ~16x40 encostado à direita, aberto
K.rect(g, 34, 41, 16, 38, 'o')
-- fundo: barro úmido escuro no terço inferior, gradiente manual
for y = 41, 78 do
    for x = 34, 49 do
        if rng.chance(.15) and y > 62 then K.pixel(g, x, y, 'D') end
    end
end
-- parede interna da cova: sombra 'D' na borda N (fundo), filete 'k'
-- na borda S (sombra da borda próxima)
for x = 34, 49 do K.pixel(g, x, 41, 'k'); K.pixel(g, x, 78, 'k') end
for y = 41, 78 do K.pixel(g, 34, y, 'k'); K.pixel(g, 49, y, 'k') end

-- rebordo de pedra pálida: a moldura onde a tampa assentava — LARGO
-- e o elemento mais claro do prop (a laje recém-saída deixou a pedra
-- branqueada). 'w' = lasca clara SOBRE o rebordo, 'S' = corpo.
K.rect(g, 30, 33, 24, 6, 'S')           -- lip de cima: 6px largos
K.rect(g, 30, 33, 24, 2, 'w')           -- filete superior branqueado
for x = 30, 53 do
    if rng.chance(.3) then K.pixel(g, x, 35 + rng.int(0, 2), 'w') end
end
-- borda direita: também larga (a laje correu para lá)
for y = 33, 82 do
    K.pixel(g, 52, y, 'S'); K.pixel(g, 53, y, 'S')
    if rng.chance(.2) then K.pixel(g, 52, y, 'w') end
end
-- esquerda/fundo: mesma moldura clara, 2px 'S' + 'w' nas quinas
for y = 36, 82 do
    K.pixel(g, 31, y, 'S'); K.pixel(g, 32, y, 's')
    K.pixel(g, 30, y, 'S')
    if y % 6 == 1 then K.pixel(g, 31, y, 'w') end
end
for x = 30, 53 do
    K.pixel(g, x, 82, 'S'); K.pixel(g, x, 83, 's')
    if x % 8 == 3 then K.pixel(g, x, 82, 'w') end
end
-- cantos da moldura: junta escura nos vértices
K.pixel(g, 30, 33, 'k'); K.pixel(g, 53, 33, 'k')
K.pixel(g, 30, 83, 'k'); K.pixel(g, 53, 83, 'k')

-- terra revolvida: montículo à esquerda do buraco + respingos
blob(22, 50, 12, 10, 'e')
blob(24, 44, 9, 7, 'a')
blob(20, 62, 8, 8, 'e')
blob(18, 70, 6, 5, 'D')
-- torrões grandes autorados sobre o montículo
K.stamp(g, K.parse([[ee
ea]]), 16, 44, 'topleft')
K.stamp(g, K.parse([[ae
ee]]), 28, 56, 'topleft')
-- pás/espinho de terra voando sobre a borda da cova (revolver
-- recente): 2-3 torrões soltos na borda
K.pixel(g, 33, 42, 'a'); K.pixel(g, 34, 41, 'e')
K.pixel(g, 47, 45, 'e'); K.pixel(g, 48, 44, 'a')
K.pixel(g, 36, 78, 'e'); K.pixel(g, 37, 78, 'a')
-- marcas de pá: três riscos curtos 'r' na terra do montículo
K.line(g, 16, 52, 24, 54, 'r')
K.line(g, 18, 60, 26, 62, 'r')
K.line(g, 14, 48, 20, 50, 'r')
-- pé direito da cova: degrau de terra onde a terra cedeu para dentro
K.rect(g, 30, 68, 3, 8, 'e')
K.pixel(g, 30, 67, 'a')

-- contato/sombra geral embaixo (a massa de terra toca o chão)
for x = 12, 52 do if rng.chance(.7) then K.pixel(g, x, 90, 'd') end end

local legend = {
    o = { spec = 'abyss', h = 0 },            -- vão da cova
    D = { ramp = 'earth', step = 1, h = 0 },  -- fundo/barro úmido
    e = { ramp = 'earth', step = 3, h = 1 },  -- terra revolvida
    a = { ramp = 'earth', step = 4, h = 1 },  -- torrão claro
    r = { ramp = 'earth', step = 1, h = 0 },  -- marca de pá
    s = { ramp = 'stone', step = 3, h = 2 },  -- rebordo, face
    S = { ramp = 'stone', step = 5, h = 3 },  -- rebordo pálido, luz
    w = { ramp = 'stone', step = 6, h = 3 },  -- lasca clara na borda
    k = { spec = 'ink', h = 1 },              -- junta/corte escuro
    d = { ramp = 'stone', step = 1, h = 1 },  -- contato
}

return {
    name = 'sepultura', w = 64, h = 96, origin = 'feet',
    legend = legend,
    layers = { { name = 'cova', albedo = K.string(g) } },
}
