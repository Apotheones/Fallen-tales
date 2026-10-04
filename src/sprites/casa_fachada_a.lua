-- CASA_FACHADA_A — fachada de rua, 2 células, 128x96, origem topleft.
-- Frente CASAS F4/F5: uma casa = def única; a grade nasce para os 128px
-- e nada reinicia em x=64 (o montante central de meio-madeira faz de
-- estrutura e cobre a emenda). Beiral simples de ardósia, pavimento
-- superior com duas venezianas fechadas, térreo com porta à esquerda
-- e janela à direita, cunhais nas pontas e base de pedra.

local Lib = require('src.sprites.casa_lib')

local albedo = Lib.fachada {
    w = 128,
    roofH = 16, curso = 5, telha = 8,
    stringY = 50, baseH = 6,
    -- montantes do pavimento superior: o do meio cai em cima da emenda
    posts = { 14, 62, 110 },
    stains = {
        { 30, 34, 8, 5 }, { 70, 21, 6, 4, 'P' }, { 100, 56, 7, 4 },
        { 42, 70, 6, 3 }, { 8, 79, 5, 3, 'd' }, { 116, 33, 6, 4 },
    },
    up = {
        { 20, 24, 16, 20, 'shut' },
        { 90, 24, 16, 20, 'shut' },
    },
    lo = {
        { 88, 66, 18, 18, 'open' },
    },
    door = { 16, 62, 20, 90 },
}

return {
    name = 'casa_fachada_a',
    w = 128, h = 96,
    origin = 'topleft',
    legend = Lib.legend(),
    layers = {
        { name = 'fachada', h = 6, albedo = albedo },
    },
}
