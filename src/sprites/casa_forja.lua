-- V02_CASA_FORJA — fachada da forja, 192x96 topleft, BAIXA E LARGA.
-- Um pavimento só: sanca alta (stringY=36) esmaga o de cima em faixa
-- decorativa; porta larga de oficina (30px) com verga grossa, sem
-- escadinha; janela única baixa; manchas de fuligem 'd' concentradas
-- perto da porta e da cumeeira; cunhais de pedra nos cantos.
local Lib = require('src.sprites.casa_lib')

local albedo, emissive = Lib.fachada {
    w = 192,
    roofH = 14, curso = 5, telha = 8,
    cachorros = true,
    stringY = 36, baseH = 7,
    posts = { 14, 176 }, postsLo = { 48, 96, 144 },
    stains = {
        { 60, 22, 12, 5, 'd' }, { 100, 20, 14, 6, 'd' },
        { 78, 44, 10, 5, 'd' }, { 30, 60, 8, 5, 'q' },
        { 150, 66, 9, 5, 'q' }, { 110, 74, 7, 4 },
    },
    up = {},
    lo = {
        { 28, 62, 16, 16, 'open' },
        { 150, 62, 16, 16, 'open' },
    },
    door = { 82, 56, 30, 89 },
}

return {
    name = 'casa_forja', w = 192, h = 96, origin = 'topleft',
    legend = Lib.legend(0.0),
    layers = { {
        name = 'fachada', h = 6, albedo = albedo, emissive = emissive },
    },
}
