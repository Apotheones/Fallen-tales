-- LÁPIDE_A — estela reta de pedra fria, 64x96, origem nos pés.
-- Colina dos Sepultados (docs/DIRECAO_AMBIENTAL_HD.md §COLINA): a mais
-- antiga do conjunto — estela de topo reto com inscrição gasta em bone,
-- lascas nas quinas e musgo apagado subindo pela esquerda. Nenhum quente.
-- Relevo: capa do topo 6, face 5, laterais/fresta 4, musgo 3-4, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'lapide_a',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        -- pedra: capa clara, fio de luz, face, sombra lateral, fresta
        S = {ramp = 'stone', step = 5, h = 6},
        l = {ramp = 'stone', step = 4, h = 5},
        a = {ramp = 'stone', step = 3, h = 5},
        d = {ramp = 'stone', step = 2, h = 4},
        q = {ramp = 'stone', step = 1, h = 4},
        -- inscrição gasta em osso
        n = {ramp = 'bone', step = 4, h = 5},
        -- musgo apagado e chão
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
                E, E, E, E, E,                            -- 41-45
                -- capa do topo: filete claro sobre a borda
                L'...........................SSSSSSSSSS',       -- 46
                L'..........................SSSSSSSSSSSS',      -- 47
                L'.........................lSSSSSSSSSSSSd',     -- 48
                -- face: fio claro à esquerda, sombra à direita
                L'.........................laaaaaaaaaaaad',     -- 49
                L'.........................laaaaaaaaaaaad',     -- 50
                L'.........................laaaaaaaaaaaad',     -- 51
                L'.........................laaaqaaaaaaad',      -- 52
                L'.........................laaaaaaaaaaaad',     -- 53
                L'.........................laaaaaaaaaaaad',     -- 54
                -- inscrição: fileiras curtas de osso gasto
                L'.........................laaannnnnaaaad',     -- 55
                L'.........................laaaaaaaaaaaad',     -- 56
                L'.........................laaaaaaaaaaaad',     -- 57
                L'.........................laannnnnnaaaad',     -- 58
                L'.........................laaaaaaaaaaaad',     -- 59
                L'.........................laaaaaaaaaaaad',     -- 60
                L'.........................laaannnnaaaaad',     -- 61
                L'.........................laaaaaaaaaaaad',     -- 62
                L'.........................laaaaaaaaaaaad',     -- 63
                L'.........................laaannnnnaaaad',     -- 64
                L'.........................laaaaaaaaaaaad',     -- 65
                L'.........................laaaaaaaaaaaad',     -- 66
                L'.........................laaaannnaaaaad',     -- 67
                L'.........................laaaaaaaaaaaad',     -- 68
                L'.........................laaaaaaaaaaaad',     -- 69
                L'.........................laaannnnaaaaad',     -- 70
                L'.........................laaaaaaaaaaaad',     -- 71
                L'.........................laaaaaaaaaaaad',     -- 72
                L'.........................laaaaaaaaaaaad',     -- 73
                -- fresta diagonal gasta descendo pelo canto esquerdo
                L'.........................laqaaaaaaaaaad',     -- 74
                L'.........................laaqaaaaaaaaad',     -- 75
                L'.........................laaaqaaaaaaaad',     -- 76
                L'.........................laaaaaaaaaaaad',     -- 77
                L'.........................laaaaaaaaaaaad',     -- 78
                L'.........................laaaaaaaaaaaad',     -- 79
                -- musgo subindo pela quina esquerda, junção da base
                L'.........................gaaaaaaaaaaaad',     -- 80
                L'.........................gGaaaaaaaaaaad',     -- 81
                L'.........................ggGaaaaaaaaaad',     -- 82
                L'.........................gGgGaaaaaaaaad',     -- 83
                -- plinto afundando na terra
                L'........................ddaaaaaaaaaaaaadd',   -- 84
                L'........................ddddddddddddddddd',   -- 85
                L'.......................vvvvvvvvvvvvvvvvvvv',  -- 86
                L'....................eeeeeeeeeeeeeeeeeeeeee',  -- 87
                L'....................eee..eee....eee..eee',    -- 88
                L'..................e..eeG..ee..e..ee..e',      -- 89
                L'.................e..e..g..e....e..G..e',      -- 90
                L'.................e...e....e.g..e....e',       -- 91
                L'..................e...e..e....e..e',          -- 92
                L'....................e....e....e',             -- 93
                E, E, E,                                        -- 94-96
            },
        },
    },
}
