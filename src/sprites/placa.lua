-- PLACA de aviso — prop de chão, 64x96, origem nos pés.
-- Placa de estrada do Refúgio: poste de madeira + tábua pregada um
-- pouco inclinada, inscrição estilizada em traços claros (a placa de
-- rotas do Marco, sem ser portal). Grama e terra na base.
-- Relevo: tábua 7-8 com pregos 9, poste 5-6, base no chão 1-3.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'placa',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        -- tábua: fio claro, corpo, veios, borda inferior
        W = {ramp = 'wood', step = 6, h = 8},
        p = {ramp = 'wood', step = 4, h = 7},
        v = {ramp = 'wood', step = 3, h = 7},
        V = {ramp = 'wood', step = 2, h = 7},
        -- inscrição estilizada e pregos
        b = {ramp = 'bone', step = 5, h = 8},
        i = {ramp = 'iron', step = 5, h = 9},
        -- poste
        w = {ramp = 'wood', step = 4, h = 6},
        q = {ramp = 'wood', step = 2, h = 5},
        -- chão
        g = {ramp = 'moss', step = 4, h = 3},
        G = {ramp = 'moss', step = 2, h = 2},
        e = {ramp = 'earth', step = 4, h = 1},
    },

    layers = {
        {   -- POSTE: estaca atrás da tábua, descendo até a base de terra
            name = 'poste',
            h = 5,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E,               -- 21-29
                L'.............................wW',          -- 30
                L'.............................wW',          -- 31
                L'.............................ww',          -- 32
                L'.............................ww',          -- 33
                L'.............................ww',          -- 34
                L'.............................ww',          -- 35
                L'.............................ww',          -- 36
                L'.............................ww',          -- 37
                L'.............................ww',          -- 38
                L'.............................ww',          -- 39
                L'.............................ww',          -- 40
                L'.............................ww',          -- 41
                L'.............................ww',          -- 42
                L'.............................ww',          -- 43
                L'.............................ww',          -- 44
                L'.............................ww',          -- 45
                L'.............................ww',          -- 46
                L'.............................ww',          -- 47
                L'.............................ww',          -- 48
                L'.............................wwq',         -- 49
                L'.............................wwq',         -- 50
                L'.............................wq',          -- 51
                L'.............................wq',          -- 52
                L'.............................ww',          -- 53
                L'.............................ww',          -- 54
                L'.............................ww',          -- 55
                L'.............................wwq',         -- 56
                L'.............................wq',          -- 57
                L'.............................ww',          -- 58
                L'.............................ww',          -- 59
                L'.............................ww',          -- 60
                L'.............................ww',          -- 61
                L'.............................wwq',         -- 62
                L'.............................wq',          -- 63
                L'.............................ww',          -- 64
                L'.............................ww',          -- 65
                L'.............................wq',          -- 66
                L'.............................ww',          -- 67
                L'.............................ww',          -- 68
                L'.............................ww',          -- 69
                L'.............................ww',          -- 70
                L'.............................wwq',         -- 71
                L'.............................wq',          -- 72
                L'.............................ww',          -- 73
                L'.............................ww',          -- 74
                L'.............................ww',          -- 75
                L'.............................ww',          -- 76
                L'.............................wq',          -- 77
                L'.............................ww',          -- 78
                L'.............................ww',          -- 79
                L'.............................wwq',         -- 80
                L'.............................wq',          -- 81
                L'.............................ww',          -- 82
                L'.............................ww',          -- 83
                L'.............................wq',          -- 84
                L'.............................ww',          -- 85
                L'.............................ww',          -- 86
                L'.............................wq',          -- 87
                L'.............................wq',          -- 88
                L'.............................wqq',         -- 89
                L'.............................wqq',         -- 90
                E, E, E, E, E, E,                          -- 91-96
            },
        },
        {   -- TÁBUA: retângulo inclinado (cisalhado ~1px a cada 4 linhas),
            -- fio claro em cima, veios, inscrição e pregos nos cantos
            name = 'tabua',
            h = 7,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E,                                        -- 31
                L'.............kWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk',-- 32
                L'.............kpppppppppppppppppppppppppppppppppppk',-- 33
                L'.............kipppvppppvpppppvppppvpppppppvpppppik',-- 34
                L'..............kpppppppppppppppppppppppppppppppppppk',-- 35
                L'..............kpppppppbbbbbpbbpppbbbppbbbbbpppk',-- 36
                L'..............kpppppppbpbbpbppbpbpppbpbppbpppk',-- 37
                L'..............kpppvpppbbbpbbbpbpbppbbbppbpppk',-- 38
                L'...............kppppppbppbpbppbpbppbpbppbpppk',-- 39
                L'...............kppppppbbbbpbppbpbbbpbbbppbppk',-- 40
                L'...............kppppppppppppppppppppppppppppppk',-- 41
                L'...............kppvppppppvpppppvppppvppppppvppk',-- 42
                L'...............kpppppbbpppbbbbbpbbbpppbbbbbpbpk',-- 43
                L'................kppppbppbpbppbpbppbppbppbppbbpk',-- 44
                L'................kppppbbbpppbbbbbpbbbppbbbbbpppk',-- 45
                L'................kppppbppbpbppbpbppbpbppbpbbbpk',-- 46
                L'................kppppppppppppppppppppppppppppppk',-- 47
                L'................kVppppppppppppppppppppppppppppVpk',-- 48
                L'................kVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVk',-- 49
                L'.................kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',-- 50
                E, E, E, E, E, E, E, E, E, E,            -- 51-60
                E, E, E, E, E, E, E, E, E, E,            -- 61-70
                E, E, E, E, E, E, E, E, E, E,            -- 71-80
                E, E, E, E, E, E, E, E, E, E,            -- 81-90
                E, E, E, E, E, E,                          -- 91-96
            },
        },
        {   -- BASE: monte de terra e capim prendendo o poste
            name = 'base',
            h = 2,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E, E, E, E, E, E, E, E, E, E,            -- 41-50
                E, E, E, E, E, E, E, E, E, E,            -- 51-60
                E, E, E, E, E, E, E, E, E, E,            -- 61-70
                E, E, E, E, E, E, E, E, E, E,            -- 71-80
                E, E, E, E, E, E, E,                     -- 81-87
                L'.........................g....e...g',      -- 88
                L'........................g.g..eee..g.g',    -- 89
                L'.......................g.G.geeeeeg.G.g',   -- 90
                L'......................g.gggeeeeeeg.gg.g',  -- 91
                L'.....................g.ggGgeeeeeeggGgg.g', -- 92
                L'....................eggggGgeeeeeeeggGggg', -- 93
                L'....................eegGGgeeeeeeeeeGGgee', -- 94
                L'.....................eeggeeeeeeeeeggee',   -- 95
                L'......................eeeeeeeeeeeeeee',    -- 96
            },
        },
    },
}
