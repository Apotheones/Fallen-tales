-- CASA_PENSAO — a fachada da pensão da slice (canto N da Praça dos
-- Nomes), 3 células, 192x96, origem topleft. Peça de fundo da
-- composição: beiral mais generoso com cachorros aparentes, três
-- janelas no pavimento superior (a do meio acesa — o quarto que ainda
-- vela, ei~0.4), porta com escadinha e duas janelas no térreo, e a
-- tabuleta de hospedaria pendurada sobre a porta: crescente + ponto,
-- a casa que acolhe de noite. Montantes de meio-madeira caem sobre
-- as emendas de célula — a fachada lê um prédio só.

local Lib = require('src.sprites.casa_lib')

local albedo, emissive = Lib.fachada {
    w = 192,
    roofH = 20, curso = 5, telha = 8,
    cachorros = true,
    stringY = 50, baseH = 6,
    -- montantes cobrindo as emendas (x=64/128) e fechando o ritmo
    posts = { 14, 63, 128, 176 },
    postsLo = { 63, 128 },
    stains = {
        { 50, 30, 9, 5 }, { 110, 24, 7, 4, 'P' }, { 160, 36, 8, 4 },
        { 36, 72, 6, 3 }, { 120, 78, 7, 4 }, { 170, 58, 5, 3, 'd' },
    },
    up = {
        { 28, 27, 16, 19, 'shut' },
        { 88, 27, 16, 19, 'lit' },
        { 148, 27, 16, 19, 'shut' },
    },
    lo = {
        { 28, 68, 18, 17, 'open' },
        { 146, 68, 18, 17, 'open' },
    },
    door = { 86, 66, 20, 89, steps = true },
    -- tabuleta de hospedaria sobre a porta, pendurada na sanca
    sign = { 96, 54 },
}

return {
    name = 'casa_pensao',
    w = 192, h = 96,
    origin = 'topleft',
    legend = Lib.legend(0.4),
    layers = {
        { name = 'fachada', h = 6, albedo = albedo, emissive = emissive },
    },
}
