-- V02_TAMPA — laje deslocada (tampa de cisterna/jazigo no pátio),
-- 64x64 topleft, overlay de chão: a pedra pesada correu para o lado e
-- a boca escura ficou à mostra. Leitura: vão escuro à esquerda com
-- borda 'k' e fundo 'o', tampa 'S'/'s' com espessura à vista encostada
-- à direita, trilha de arraste 'r' na terra ligando os dois.
local K = require 'src.pixel_kit'

local g = K.new(64, 64)

-- terra de apoio (o decal mora sobre o piso; desenha só a peça)
local rng = K.rng('v02_tampa', 71)

-- vão aberto: boca irregular de ~18x24
local boca = {
    { 10, 18 }, { 24, 15 }, { 28, 22 }, { 26, 38 },
    { 18, 44 }, { 8, 40 }, { 6, 28 },
}
local bpts = {}
for _, p in ipairs(boca) do bpts[#bpts + 1] = p[1]; bpts[#bpts + 1] = p[2] end
K.polygon(g, bpts, 'o')
-- borda da boca: filete de pedra cortada 'k' e borda iluminada 'S'
local bm = K.mask_erode(K.sel_color(g, 'o'), 4, 1)
local aro = K.mask_sub(K.sel_color(g, 'o'), bm)
for y = 1, 64 do for x = 1, 64 do
    if K.get(aro, x, y) ~= '.' then
        K.pixel(g, x, y, (y < 26 or x < 12) and 'S' or 'k')
    end
end end
-- fundo: nem tudo é buraco negro — fundo de pedra 'd' no vão
for y = 1, 64 do for x = 1, 64 do
    if K.get(bm, x, y) ~= '.' and rng.chance(.5) then
        K.pixel(g, x, y, 'd')
    end
end end

-- trilha de arraste: linhas de atrito da pedra no barro
for i = 0, 2 do
    local y = 20 + i * 7
    K.line(g, 24 + i, y + rng.int(-1, 1), 44, y + rng.int(-2, 1), 'r')
end
for _ = 1, 3 do
    K.pixel(g, rng.int(28, 40), rng.int(18, 38), 'r')
end

-- a tampa: laje de ~26x22 escorada, deslocada p/ direita, topo 'S',
-- espessura 's' na frente, quina iluminada 'L'
K.polygon(g, { 40, 14, 62, 18, 60, 44, 38, 40 }, 'S')
-- espessura da laje (face sul vê a tábua de lado)
K.polygon(g, { 38, 40, 60, 44, 60, 47, 38, 43 }, 's')
K.polygon(g, { 60, 44, 62, 18, 62, 21, 60, 47 }, 's')
-- filete de quina iluminada (sol SO)
for i = 0, 20 do K.pixel(g, 40 + i, 14 + math.floor(i * .18), 'L') end
K.line(g, 40, 14, 38, 40, 'L')
-- desgaste e musgo na face da tampa
for _ = 1, 2 do
    local bx, by = rng.int(44, 56), rng.int(20, 34)
    K.pixel(g, bx, by, 'v'); K.pixel(g, bx + 1, by, 'v')
    K.pixel(g, bx, by + 1, 'v')
end
K.pixel(g, 56, 40, 'g'); K.pixel(g, 57, 40, 'g'); K.pixel(g, 56, 41, 'g')
-- apoio: sombra de contato sob a aresta da tampa
K.line(g, 38, 44, 60, 48, 'r')

local legend = {
    o = { spec = 'abyss', h = 0 },           -- vão aberto
    d = { ramp = 'stone', step = 1, h = 0 }, -- fundo do vão
    k = { spec = 'ink', h = 1 },             -- borda cortada, sombra
    r = { ramp = 'earth', step = 1, h = 0 }, -- atrito/arraste
    s = { ramp = 'stone', step = 3, h = 2 }, -- espessura da laje
    S = { ramp = 'stone', step = 5, h = 2 }, -- face da tampa
    L = { ramp = 'stone', step = 7, h = 2 }, -- quina iluminada
    v = { ramp = 'stone', step = 4, h = 2 }, -- desgaste
    g = { ramp = 'moss',  step = 2, h = 1 }, -- musgo
}

return {
    name = 'tampa', w = 64, h = 64, origin = 'topleft',
    legend = legend,
    layers = { { name = 'tampa', albedo = K.string(g) } },
}
