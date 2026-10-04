-- LÁPIDE_C — cruz simples de pedra clara, 64x96, origem nos pés.
-- Colina dos Sepultados (docs/DIRECAO_AMBIENTAL_HD.md §COLINA): a mais
-- recente do conjunto — pedra mais clara, corte limpo, quase sem musgo.
-- Relevo: filete do topo 6, corpo 5, sombras/fresta 4, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'lapide_c',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        S = {ramp = 'stone', step = 6, h = 6}, -- filete claro do topo/braço
        l = {ramp = 'stone', step = 5, h = 5}, -- fio de luz esquerdo
        b = {ramp = 'stone', step = 4, h = 5}, -- corpo da cruz
        d = {ramp = 'stone', step = 2, h = 4}, -- lado/baixo em sombra
        q = {ramp = 'stone', step = 1, h = 4}, -- fenda
        g = {ramp = 'moss', step = 2, h = 4},
        G = {ramp = 'moss', step = 1, h = 3},
        e = {ramp = 'earth', step = 3, h = 1},
        v = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        {
            name = 'cruz',
            h = 5,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E,                                            -- 41
                -- haste: filete do topo, fio claro à esquerda
                L'............................SSSSSS',              -- 42
                L'...........................lbbbbbSd',             -- 43
                L'...........................lbbbbbbd',             -- 44
                L'...........................lbbbbbbd',             -- 45
                L'...........................lbbbbbbd',             -- 46
                L'...........................lbbbbbbd',             -- 47
                L'...........................lbbbbbbd',             -- 48
                L'...........................lbbbbbbd',             -- 49
                L'...........................lbbbbbbd',             -- 50
                L'...........................lbbbbbbd',             -- 51
                -- travessa: filete claro por cima, sombra por baixo
                L'..................SSSSSSSSSSSSSSSSSSSSSSSSS',     -- 52
                L'..................lbbbbbbbbbbbbbbbbbbbbbbbd',     -- 53
                L'..................lbbbbbbbbbbgbbbbbbbbbbbd',      -- 54
                L'..................lbbbbbbbbbbbbbbbbbbbbbbbd',     -- 55
                L'..................dddddddddlbbbbbbddddddddd',     -- 56
                L'..................dddddddddlbbbbbbddddddddd',     -- 57
                -- haste desce da travessa até a terra
                L'...........................lbbbbbbd',             -- 58
                L'...........................lbbbbbbd',             -- 59
                L'...........................lbbbbbbd',             -- 60
                L'...........................lbbbbbbd',             -- 61
                L'...........................lbbbbbbd',             -- 62
                L'...........................lbbbbbbd',             -- 63
                L'...........................lbbbbbbd',             -- 64
                L'...........................lbbbbbbd',             -- 65
                L'...........................lbbbbbbd',             -- 66
                L'...........................lbbbbbbd',             -- 67
                L'...........................lbbbbbqd',             -- 68
                L'...........................lbbbbqbd',             -- 69
                L'...........................lbbbbbbd',             -- 70
                L'...........................lbbbbbbd',             -- 71
                L'...........................lbbbbbbd',             -- 72
                L'...........................lbbbbbbd',             -- 73
                L'...........................lbbbbbbd',             -- 74
                L'...........................lbbbbbbd',             -- 75
                L'...........................lbbbbbbd',             -- 76
                L'...........................lbbgbbbd',             -- 77
                L'...........................lbgGbbbd',             -- 78
                L'...........................lbgGgbbd',             -- 79
                L'...........................lggGgbdd',             -- 80
                -- base afundando
                L'.........................ddbbbbbbbbbdd',          -- 81
                L'.........................ddddddddddddd',          -- 82
                L'........................vvvvvvvvvvvvvvvv',        -- 83
                L'........................eeeeeeeeeeeeeeeeeeee',    -- 84
                L'........................eee..eee....eee..eee',    -- 85
                L'......................e..eeG..ee..e..ee..e',      -- 86
                L'.....................e..e..g..e....e..G..e',      -- 87
                L'.....................e...e....e.g..e....e',       -- 88
                L'......................e...e..e....e..e',          -- 89
                L'........................e....e....e',             -- 90
                E, E, E, E, E, E,                                   -- 91-96
            },
        },
    },
}
