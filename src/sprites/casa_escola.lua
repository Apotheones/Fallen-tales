-- V02_CASA_ESCOLA — fachada da escola do terraço, 128x96 topleft.
-- Fachada mais asseada que as casas: reboco com menos mancha, duas
-- janelas do térreo ABERTAS (luz do dia entrando na aula), venezianas
-- do pavimento superior abertas de verdade ('open'), porta larga com
-- escadinha — lugar de entrar e sair a toda hora. Remendo pequeno na
-- base esquerda (escola é mantida, não velha).
local Lib = require('src.sprites.casa_lib')

local albedo, emissive = Lib.fachada {
    w = 128,
    roofH = 16, curso = 5, telha = 8,
    stringY = 50, baseH = 6,
    posts = { 14, 62, 110 }, postsLo = { 62 },
    stains = {
        { 36, 32, 6, 3 }, { 96, 40, 6, 4, 'P' }, { 60, 78, 6, 3 },
    },
    up = {
        { 24, 24, 15, 18, 'open' },
        { 90, 24, 15, 18, 'open' },
    },
    lo = {
        { 20, 66, 16, 17, 'open' },
        { 92, 66, 16, 17, 'lit' },
    },
    door = { 54, 62, 22, 89, steps = true },
    remendo = { 4, 78, 8, 10 },
}

return {
    name = 'casa_escola', w = 128, h = 96, origin = 'topleft',
    legend = Lib.legend(0.35),
    layers = { {
        name = 'fachada', h = 6, albedo = albedo, emissive = emissive },
    },
}
