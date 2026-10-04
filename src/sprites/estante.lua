-- ESTANTE baixa — prop de chão, 64x96, origem nos pés.
-- Prateleira de trabalho do Refúgio encostada na parede: caixa de
-- madeira com duas prateleiras, livros gastos em pé e deitados na
-- cavidade de cima (uma lombada jade discreta), potes de reboco e
-- barro na de baixo. Miolo escuro atrás das peças.
-- Relevo: moldura 10-11, miolo 7, prateleiras 9, miúdos 8-10, chão 1.
-- Emissivo: filete jade na lombada (ei 0.35, quase nada).

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'estante',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 6},
        -- moldura: topo claro, corpo, miolo escuro, base
        W = {ramp = 'wood', step = 6, h = 11},
        w = {ramp = 'wood', step = 4, h = 10},
        v = {ramp = 'wood', step = 3, h = 10},
        d = {ramp = 'wood', step = 1, h = 7},
        V = {ramp = 'wood', step = 2, h = 8},
        -- prateleiras
        T = {ramp = 'wood', step = 5, h = 9},
        t = {ramp = 'wood', step = 4, h = 9},
        -- livros: lombadas gastas + um jade discreto
        b = {ramp = 'bone', step = 4, h = 9},
        B = {ramp = 'bone', step = 5, h = 9},
        r = {ramp = 'earth', step = 4, h = 9},
        c = {ramp = 'clothWarm', step = 3, h = 9},
        j = {ramp = 'jade', step = 4, h = 9, e = 'jadeLight', ei = 0.35},
        -- potes: reboco claro e barro
        p = {ramp = 'plaster', step = 4, h = 10},
        P = {ramp = 'plaster', step = 5, h = 10},
        o = {ramp = 'plaster', step = 2, h = 9},
        e = {ramp = 'earth', step = 4, h = 10},
        n = {ramp = 'earth', step = 2, h = 9},
        -- chão
        g = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {   -- MÓVEL: moldura com miolo escuro, duas prateleiras e base
            name = 'movel',
            h = 9,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E,                              -- 21-24
                -- topo da estante
                L'........WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 25
                L'........WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 26
                L'........wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',-- 27
                -- laterais + miolo escuro da cavidade de cima
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 28
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 29
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 30
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 31
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 32
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 33
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 34
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 35
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 36
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 37
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 38
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 39
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 40
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 41
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 42
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 43
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 44
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 45
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 46
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 47
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 48
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 49
                -- primeira prateleira
                L'........wvvTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTvvw',-- 50
                L'........wvvtttttttttttttttttttttttttttttttttttttttttttvvw',-- 51
                L'........wvvkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkvvw',-- 52
                -- cavidade de baixo
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 53
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 54
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 55
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 56
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 57
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 58
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 59
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 60
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 61
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 62
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 63
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 64
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 65
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 66
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 67
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 68
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 69
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 70
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 71
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 72
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 73
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 74
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 75
                L'........wvvddddddddddddddddddddddddddddddddddddddddddvvw',-- 76
                -- segunda prateleira / fundo da caixa
                L'........wvvTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTvvw',-- 77
                L'........wvvtttttttttttttttttttttttttttttttttttttttttttvvw',-- 78
                -- rodapé
                L'........wvvVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVw',-- 79
                L'........wvvVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVw',-- 80
                L'........wwkwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwkww',-- 81
                L'........wwkk......................................kkww',-- 82
                L'........wwk........................................kww',-- 83
                L'........wwk........................................kww',-- 84
                L'........wwk........................................kww',-- 85
                L'........wwk........................................kww',-- 86
                L'........wwk........................................kww',-- 87
                L'........wwk........................................kww',-- 88
                L'........wwkk......................................kkww',-- 89
                L'........wkwk......................................wkwk',-- 90
                E, E, E, E, E, E,                          -- 91-96
            },
        },
        {   -- MIÚDOS: livros e potes dentro das cavidades (por cima do
            -- fundo escuro, nunca da moldura)
            name = 'miudos',
            h = 9,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E,                           -- 31-35
                -- livros em pé na cavidade de cima (lombadas variadas)
                L'...........bb',                             -- 36
                L'...........bb.pp',                          -- 37
                L'...........bb.pp...cc',                     -- 38
                L'...........bbbpp..cccb',                    -- 39
                L'...........bbbppddcccbb....rr',             -- 40
                L'...........bbbpppjcccbb....rr..BB',         -- 41
                L'...........bbbpppjcccbbb...rr..BB',         -- 42
                L'...........bbbpppjcccbbb..rrr..BB',         -- 43
                L'...........bbbppjjcccbbb..rrr..BB',         -- 44
                L'...........bbbppjjcccbbb..rrr..BBB',        -- 45
                L'...........bbbppjjcccbbb..rrr..BBB',        -- 46
                L'...........bbbppjjcccbbb..rrr..BBB',        -- 47
                -- livro caído + pilha deitada à direita
                L'...........bbbppjjcccbbb..rrr..BBBBrr',     -- 48
                L'...........bbbppjjcccbbbd.rrr..BBBBcc',     -- 49
                E, E, E, E, E, E, E, E,                   -- 50-57
                -- cavidade de baixo: potes de reboco e barro
                L'...............ppp.........eee',            -- 58
                L'..............ppppp..bbb..eeeee',           -- 59
                L'..............pkpp..bbbbb.eneen',           -- 60
                L'.............pppppP.bbkbb.ennne',           -- 61
                L'............PppppppP.bbbbb.ennee',          -- 62
                L'............pppppppp.bbbbb.ennee',          -- 63
                L'............pppopppp.bbbbn.ennee',          -- 64
                L'............ppoppppp.bbbbn.enne',           -- 65
                L'............ppoppppp.bbnbb.nee',            -- 66
                L'.............ppppppp.bbbbb.nee',            -- 67
                L'.............ppppppp.bbbbb.nee',            -- 68
                L'..............pppppP..bbb..nee',            -- 69
                L'..............opppo...bb...ne',             -- 70
                E, E, E, E, E, E, E, E, E, E,            -- 71-80
                E, E, E, E, E, E, E, E, E, E,            -- 81-90
                E, E, E, E, E, E,                          -- 91-96
            },
            -- brilho discreto só na lombada jade
            emissive = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E,                                         -- 41
                L'...................j',                     -- 42
                L'...................j',                     -- 43
                L'...................jj',                    -- 44
                L'...................jj',                    -- 45
                L'...................jj',                    -- 46
                L'...................jj',                    -- 47
                L'...................jj',                    -- 48
                L'...................jj',                    -- 49
                E, E, E, E, E, E, E, E, E, E,            -- 50-59
                E, E, E, E, E, E, E, E, E, E,            -- 60-69
                E, E, E, E, E, E, E, E, E, E,            -- 70-79
                E, E, E, E, E, E, E, E, E, E,            -- 80-89
                E, E, E, E, E, E, E,                     -- 90-96
            },
        },
    },
}
