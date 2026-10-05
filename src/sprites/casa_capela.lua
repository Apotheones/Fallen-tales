-- V02_CASA_CAPELA — fachada da capela com FRONTÃO, 128x96 topleft.
-- Frontão de reboco triangular furando a linha do telhado: bordas de
-- pedra 'S' nas águas, óculo cego 'o' no tímpano e cruz de pedra 'S'
-- no ápice. Base = fachada de um pavimento apertado (a capela é baixa
-- e estreita), porta alta com escadinha, duas venezianas fechadas,
-- manchas de idade nas pontas. Sem varal nem placa — não é casa.
local Lib = require('src.sprites.casa_lib')
local K = require 'src.pixel_kit'

local albedo, emissive = Lib.fachada {
    w = 128,
    roofH = 20, curso = 5, telha = 8,
    stringY = 44, baseH = 6,
    posts = { 14, 110 },
    stains = {
        { 8, 56, 7, 6, 'd' }, { 112, 50, 8, 5, 'q' },
        { 30, 76, 6, 3 }, { 96, 72, 7, 4 },
    },
    up = {
        { 22, 52, 14, 16, 'shut' },
        { 92, 52, 14, 16, 'shut' },
    },
    lo = {},
    door = { 54, 60, 20, 89, steps = true },
}

local g = K.parse(albedo)

-- Frontão: triângulo centrado, ápice y=2, base y=19 (afoga o telhado
-- atrás). Reboco 'p' dentro, verga de pedra 'S' nas duas águas.
local cx = 64
for y = 2, 19 do
    local meia = math.floor((y - 2) / 17 * 24 + .5)
    for x = cx - meia, cx + meia do
        K.pixel(g, x, y, 'p')
    end
end
-- águas do frontão em pedra
local function desce(cx0, sgn)
    for y = 2, 19 do
        local meia = math.floor((y - 2) / 17 * 24 + .5)
        local x = cx0 + sgn * meia
        K.pixel(g, x, y, 'S')
        K.pixel(g, x + sgn, y, 'S')
    end
end
desce(cx, -1); desce(cx, 1)
K.rect(g, cx - 25, 19, 51, 2, 'S')       -- cornija do frontão
K.rect(g, cx - 25, 21, 51, 1, 's')
-- óculo cego: aro 'S' + boca 'o'
K.rect(g, cx - 3, 8, 7, 1, 'S'); K.rect(g, cx - 3, 13, 7, 1, 'S')
K.rect(g, cx - 4, 9, 1, 4, 'S'); K.rect(g, cx + 4, 9, 1, 4, 'S')
K.rect(g, cx - 3, 9, 7, 4, 'o')
K.pixel(g, cx - 1, 10, 'd'); K.pixel(g, cx, 10, 'd')
-- cruz do ápice
K.rect(g, cx, 1, 1, 1, 'S')
K.pixel(g, cx, 0 + 0, 'S')
K.rect(g, cx - 2, 1, 1, 1, 'S')
for yy = -0, 3 do K.pixel(g, cx, yy, 'S') end
for xx = cx - 2, cx + 2 do K.pixel(g, xx, 1, 'S') end

local legend = Lib.legend(0.0)

return {
    name = 'casa_capela', w = 128, h = 96, origin = 'topleft',
    legend = legend,
    layers = { {
        name = 'fachada', h = 6,
        albedo = K.string(g), emissive = emissive,
    } },
}
