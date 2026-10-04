-- MESA comunitária — prop de chão, 64x96, origem nos pés.
-- Mesa de tábuas do Refúgio, posta para o convívio: jarro de reboco,
-- pão cortado e tigela sobre o tampo; quatro pernas, avental sob a
-- borda e migalhas. Uso doméstico, sem riqueza.
-- Relevo: tampo 8, objetos 9-11, face 6, pernas 4, chão 1-2.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'mesa',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        -- tampo: fio, base, veios, face frontal
        W = {ramp = 'wood', step = 6, h = 9},
        w = {ramp = 'wood', step = 4, h = 8},
        v = {ramp = 'wood', step = 3, h = 8},
        F = {ramp = 'wood', step = 3, h = 6},
        -- pernas e avental
        l = {ramp = 'wood', step = 4, h = 4},
        q = {ramp = 'wood', step = 2, h = 4},
        -- jarro de reboco
        p = {ramp = 'plaster', step = 4, h = 11},
        P = {ramp = 'plaster', step = 5, h = 11},
        o = {ramp = 'plaster', step = 2, h = 10},
        -- pão de terra clara com côdea
        n = {ramp = 'earth', step = 5, h = 10},
        N = {ramp = 'earth', step = 6, h = 11},
        -- tigela de osso
        b = {ramp = 'bone', step = 4, h = 10},
        B = {ramp = 'bone', step = 5, h = 10},
        d = {ramp = 'bone', step = 1, h = 9},
        -- migalhas e chão
        s = {ramp = 'bone', step = 3, h = 9},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {   -- MESA: tampo com objetos, face, avental e pernas
            name = 'mesa',
            h = 6,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E,                           -- 31-35
                -- fio de trás do tampo
                L'.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 36
                L'.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 37
                -- superfície do tampo (38-53): jarro, pão, tigela
                L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',-- 38
                L'.......wwwwwvwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',-- 39
                L'.......wwwwppppwwwwwwwwwwwwwwwwwwwwwwwwwwwBBBBBwwwwww',-- 40
                L'.......wwwwwkkpwwwwwwwwwwwwwwwwwwwwwwwwwBbbbbbBwwwww',-- 41
                L'.......wwwwPppPwwwwwwwwwwwwwwwwwwwwwwwwwBddddbBwwwww',-- 42
                L'.......wwwPppppwwwwwwwwwNNNNNwwwwwwwwwwBbbbbbBwwwww',-- 43
                L'.......wwPpppppPwwwwwwwNnnnnnNwwwwwwwwwBbbbbbBwwwww',-- 44
                L'.......wPppppppPwwwwwwNnnnvnnnNwwwwwwwwwBbbbBwwwwww',-- 45
                L'.......wPppppppPwwwwvNnnnnnnnnNwwwwwwwwwbBBbwwwwwww',-- 46
                L'.......wPpppopPwwwwwwwnnnnnnnnnwwwwwwwwwwwbwwwwwwww',-- 47
                L'.......wwPppopwwwwwwvwnnnnnnnnnwwwwwwwwwwwwwwwwwwww',-- 48
                L'.......wwvpppPvwwwwwwwnnnnvnnnnwwwwwwwwwwwwwwwwwwww',-- 49
                L'.......wwwvppvwwwwwwwwwnnnnnnnwwwwwswwswwwwwwwwwwww',-- 50
                L'.......wwwwvwwwwwwwwwwwwNNNNNwwswwwwwwswwwwwwwwwwww',-- 51
                L'.......wwwwwwwwvwwwwwwwwwwwwwvwwwwwwwwwwwwwwwwwwwww',-- 52
                L'.......wwwwvwwwwwwwwwwwwvwwwwwwwwwwwwswwwwwwwwwwwww',-- 53
                -- borda frontal: filete claro + face + contorno
                L'.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 54
                L'.......FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',-- 55
                L'.......FFvFFFvFFFFvFFFFvFFFvFFFFvFFFFFvFFFvFFFFvFFFFF',-- 56
                L'.......FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',-- 57
                L'.......kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',-- 58
                -- avental sob o tampo + pernas de trás (escuras, mais
                -- estreitas e recuadas) junto das da frente
                L'.............qqqqqqqqqqqqqqqqqqqqqqqqqqqqq',         -- 59
                L'.............qqqqqqqqqqqqqqqqqqqqqqqqqqqqq',         -- 60
                L'..........llll...qq.........................qq.....llll',-- 61
                L'..........llll...qq.........................qq.....llll',-- 62
                L'..........llll...qq.........................qq.....llll',-- 63
                L'..........llll...qq.........................qq.....llll',-- 64
                L'..........llll...qq.........................qq.....llll',-- 65
                L'..........llll...qq.........................qq.....llll',-- 66
                L'..........llll...qq.........................qq.....llll',-- 67
                L'..........llll...qq.........................qq.....llll',-- 68
                L'..........llll...qq.........................qq.....llll',-- 69
                L'..........llll...qq.........................qq.....llll',-- 70
                L'..........llll.....................................llll',-- 71
                L'..........llll.....................................llll',-- 72
                L'..........llll.....................................llll',-- 73
                -- travessa entre as pernas da frente
                L'..........llllllllllllllllllllllllllllllllllllllllllll',-- 74
                L'..........llll.....................................llll',-- 75
                L'..........llll.....................................llll',-- 76
                L'..........llll.....................................llll',-- 77
                L'..........llll.....................................llll',-- 78
                L'..........llll.....................................llll',-- 79
                L'..........llll.....................................llll',-- 80
                L'..........llll.....................................llll',-- 81
                L'..........llll.....................................llll',-- 82
                L'..........llll.....................................llll',-- 83
                L'..........llll.....................................llll',-- 84
                L'..........llll.....................................llll',-- 85
                L'..........llll.....................................llll',-- 86
                L'..........llll.....................................llll',-- 87
                L'..........llll.....................................llll',-- 88
                L'..........llll.....................................llll',-- 89
                L'..........lkkl.....................................lkkl',-- 90
                -- pés e contato com o chão
                L'..........lkkl............e....................lkkl',-- 91
                L'...........ee......e....e....e.......ee',            -- 92
                L'.............e....e......e....e....e',               -- 93
                L'..........e....e......e.....e.....e',                -- 94
                L'..............e.....e.....e....e',                   -- 95
                L'.............e......e......e',                       -- 96
            },
        },
    },
}
