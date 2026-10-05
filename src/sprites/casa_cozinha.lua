-- V02_CASA_COZINHA — fachada da cozinha, 128x96 topleft. Casa de
-- trabalho morna: janela do térreo ACESA (lamparina de cozinha,
-- ei~0.45 — o fogo que guarda gente), panelaço e fumaça sugeridos por
-- manchas de fuligem junto à janela, varal de ervas sob a janela do
-- topo (corda + maços pendurados), porta simples à esquerda.
local Lib = require('src.sprites.casa_lib')

local albedo, emissive = Lib.fachada {
    w = 128,
    roofH = 16, curso = 5, telha = 8,
    stringY = 50, baseH = 6,
    posts = { 14, 62, 110 }, postsLo = { 62 },
    stains = {
        { 70, 40, 8, 5, 'd' }, { 78, 34, 6, 4, 'd' },   -- fuligem subindo
        { 30, 30, 7, 4, 'P' }, { 100, 56, 6, 4 },
        { 20, 74, 6, 3 }, { 116, 76, 5, 3 },
    },
    up = {
        { 24, 24, 15, 18, 'shut' },
        { 92, 24, 15, 18, 'open' },
    },
    lo = {
        { 84, 66, 18, 18, 'lit' },
    },
    door = { 20, 64, 20, 89, steps = true },
    varal = { 88, 42, 26, pecas = {
        { 91, 3, 8, 'g', 'q' }, { 99, 4, 7, 'g', 'q' },
        { 108, 3, 6, 'a', 'q' } } },
}

return {
    name = 'casa_cozinha', w = 128, h = 96, origin = 'topleft',
    legend = Lib.legend(0.45),
    layers = { {
        name = 'fachada', h = 6, albedo = albedo, emissive = emissive },
    },
}
