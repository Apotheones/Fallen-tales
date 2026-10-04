-- LÁPIDE_B — pedra tombada inclinada e gasta, 64x96, origem nos pés.
-- Colina dos Sepultados (docs/DIRECAO_AMBIENTAL_HD.md §COLINA): a mais
-- velha das três — pende para a esquerda, topo mastigado, inscrição
-- quase apagada, musgo escorrido pelo lado que pega a pouca luz.
-- Relevo: capa do topo 6, face 5, sombras/fresta 4, musgo 3-4, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'lapide_b',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        S = {ramp = 'stone', step = 5, h = 6}, -- capa gasta do topo
        l = {ramp = 'stone', step = 4, h = 5}, -- fio de luz
        a = {ramp = 'stone', step = 3, h = 5}, -- face
        d = {ramp = 'stone', step = 2, h = 4}, -- lateral em sombra
        q = {ramp = 'stone', step = 1, h = 4}, -- fresta/lasca
        n = {ramp = 'bone', step = 4, h = 5},  -- resto de inscrição
        g = {ramp = 'moss', step = 2, h = 4},
        G = {ramp = 'moss', step = 1, h = 3},
        e = {ramp = 'earth', step = 3, h = 1},
        v = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        {
            name = 'lapide',
            h = 5,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E, E, E, E,                                 -- 41-44
                -- topo mastigado, puxado para a esquerda
                L'......................SSqSSSSSS',             -- 45
                L'.....................lSSSSSSSSSSd',           -- 46
                -- face inclinada: desloca 1 px a cada ~6 linhas
                L'.....................laaaaaaaaaaad',          -- 47
                L'.....................laaaagggaaaad',          -- 48
                L'.....................laaaaGggaaaad',          -- 49
                L'.....................laaaagGgaaaad',          -- 50
                L'.....................laaaagggaaaad',          -- 51
                L'.....................laaaaaGgaaaad',          -- 52
                L'......................laaaaaaaaaaad',         -- 53
                L'......................laaaaaaaaaaad',         -- 54
                L'......................laaaaaaaaaaqd',         -- 55
                L'......................laaaaaaaqqaad',         -- 56
                L'......................laaaaaaaaaaqd',         -- 57
                L'......................laaaaaaaaaaad',         -- 58
                L'.......................laaaaaaaaaaad',        -- 59
                L'.......................laaaaaaaaaaad',        -- 60
                L'.......................laannnnaaaaaad',       -- 61
                L'.......................laaaaaaaaaaad',        -- 62
                L'.......................laannnaaaaaaad',       -- 63
                L'.......................laaaaaaaaaaad',        -- 64
                L'........................laaaaaaaaaaad',       -- 65
                L'........................laaaaqaaaaaad',       -- 66
                L'........................laaaaaqaaaaad',       -- 67
                L'........................laaaaaaqaaaad',       -- 68
                L'........................laaaaaaaqaaad',       -- 69
                L'........................laaaaaaaaaaad',       -- 70
                L'........................laaaaaaaaaaad',       -- 71
                L'.........................laaaaaaaaaaad',      -- 72
                L'.........................laaaaaaaaaaad',      -- 73
                L'.........................laaaaaaaaaaad',      -- 74
                -- musgo acumulado na base do lado baixo
                L'.........................lgGgaaaaaaaad',      -- 75
                L'.........................lggGgaaaaaaad',      -- 76
                L'.........................lgGgggaaaaaad',      -- 77
                L'.........................lgggGgaaaaaad',      -- 78
                L'.........................lggGgGgaaaaad',      -- 79
                L'.........................lggggGgaaaaad',      -- 80
                -- plinto afundado, desalinhado do corpo (cedeu junto)
                L'.......................ddaaaaaaaaaaaaadd',    -- 81
                L'.......................ddddddddddddddddd',    -- 82
                L'......................vvvvvvvvvvvvvvvvvv',    -- 83
                L'......................eeeeeeeeeeeeeeeeeeeeee',-- 84
                L'......................eee..eee....eee..eee',  -- 85
                L'....................e..eeG..ee..e..ee..e',    -- 86
                L'...................e..e..g..e....e..G..e',    -- 87
                L'...................e...e....e.g..e....e',     -- 88
                L'....................e...e..e....e..e',        -- 89
                L'......................e....e....e',           -- 90
                E, E, E, E, E, E,                               -- 91-96
            },
        },
    },
}
