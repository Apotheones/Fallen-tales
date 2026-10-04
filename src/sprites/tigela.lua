-- TIGELA da soleira — peça pequena, 64x64, origem topleft.
-- Tradição "comida antes da pergunta" (nota vida-refugio-props §7): a
-- tigela cheia espera quem chega. 2 frames = estado:
--   f1 = oferecida: cheia, com fumacinha desenhada (albedo claro, sem
--        emissivo — vapor não queima)
--   f2 = recolhida: vazia, fundo escuro à vista
-- Relevo: borda 8, corpo 7, conteúdo 8, fumaça 6, base 5.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

local CHEIA = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E, E,                              -- 11-17
    -- fumacinha: poucos pixels claros subindo torto
    L'............................q',                   -- 18
    L'...........................q',                    -- 19
    L'.............................q',                  -- 20
    L'............................q..q',                -- 21
    L'...........................q',                    -- 22
    L'.............................q',                  -- 23
    E,                                                  -- 24
    -- comida transbordando a boca da tigela
    L'..........................nNNNn',                 -- 25
    L'.........................nNNNNNn',                -- 26
    L'........................nnNNNNNnn',               -- 27
    L'........................nNnNNnNNn',               -- 28
    -- borda da tigela
    L'......................bBBBBBBBBBBBb',             -- 29
    L'......................BbbbbbbbbbB',               -- 30
    -- bojo afinando para o pé
    L'.......................BbbbbbbbbbB',              -- 31
    L'........................BbbbbbbbB',               -- 32
    L'........................bbBbbbbBb',               -- 33
    L'.........................bbbbbbb',                -- 34
    L'..........................bbbbb',                 -- 35
    L'..........................ddddd',                 -- 36
    L'...........................ddd',                  -- 37
    E, E, E, E, E, E, E, E, E, E,                     -- 38-47
    E, E, E, E, E, E, E, E, E, E,                     -- 48-57
    E, E, E, E, E, E, E,                              -- 58-64
}

local VAZIA = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E, E, E, E, E,                     -- 11-20
    E, E, E, E, E, E, E, E,                           -- 21-28
    -- borda e fundo escuro à vista (tigela recolhida, vazia)
    L'......................bBBBBBBBBBBBb',             -- 29
    L'......................BddddddddB',                -- 30
    L'.......................BddddddddB',               -- 31
    L'........................BddddddB',                -- 32
    L'........................bbBdddBbb',               -- 33
    L'.........................bbbbbbb',                -- 34
    L'..........................bbbbb',                 -- 35
    L'..........................ddddd',                 -- 36
    L'...........................ddd',                  -- 37
    E, E, E, E, E, E, E, E, E, E,                     -- 38-47
    E, E, E, E, E, E, E, E, E, E,                     -- 48-57
    E, E, E, E, E, E, E,                              -- 58-64
}

return {
    name = 'tigela',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        -- tigela de osso
        b = { ramp = 'bone', step = 4, h = 7 },
        B = { ramp = 'bone', step = 5, h = 8 },
        d = { ramp = 'bone', step = 2, h = 5 },   -- pé e fundo vazio
        -- comida: massa quente de terra clara
        n = { ramp = 'earth', step = 5, h = 8 },
        N = { ramp = 'earth', step = 6, h = 8 },
        -- fumacinha (albedo pálido, sem emissivo)
        q = { ramp = 'plaster', step = 5, h = 6 },
    },

    layers = {
        {
            name = 'tigela',
            h = 7,
            albedo = { CHEIA, VAZIA },
        },
    },
}
