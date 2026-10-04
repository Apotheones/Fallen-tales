-- CASA_FACHADA_B — fachada de rua variante, 2 células, 128x96,
-- origem topleft. Porta ao centro com escadinha, duas janelas no
-- térreo (a da direita acesa — lamparina, ei~0.3), remendo de muro
-- novo na lateral esquerda (trabalho reconhecível: cal expremida e
-- pedra nova) e varal pequeno pendurado sob a janela acesa — roupa =
-- gente (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO).

local Lib = require('src.sprites.casa_lib')

local albedo, emissive = Lib.fachada {
    w = 128,
    roofH = 16, curso = 5, telha = 8,
    stringY = 50, baseH = 6,
    posts = { 46, 82 },
    postsLo = { 46, 82 },
    stains = {
        { 60, 22, 7, 4, 'P' }, { 30, 38, 6, 4 }, { 100, 40, 8, 4 },
        { 76, 74, 6, 3 }, { 118, 60, 5, 4 },
    },
    up = {
        { 22, 25, 14, 18, 'shut' },
        { 94, 25, 14, 18, 'shut' },
    },
    lo = {
        { 18, 67, 16, 17, 'open' },
        { 98, 67, 16, 17, 'lit' },
    },
    door = { 54, 64, 20, 89, steps = true },
    -- remendo na lateral: peça nova clara costurada no reboco velho
    remendo = { 4, 58, 10, 26 },
    -- varal sob a janela acesa: ganchos, corda em catenária, três peças
    varal = { 96, 87, 24 },
}

return {
    name = 'casa_fachada_b',
    w = 128, h = 96,
    origin = 'topleft',
    legend = Lib.legend(0.3),
    layers = {
        { name = 'fachada', h = 6, albedo = albedo, emissive = emissive },
    },
}
