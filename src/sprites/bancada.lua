-- BANCADA de oficina — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/PLANO_REFUGIO_ANDLAR.md): bancada em uso e em manutenção —
-- tampo de madeira com serrote, martelo e metro dobrável; metade direita
-- coberta por lona que escorre sobre a borda frontal. Cavaletes embaixo,
-- serragem no chão e duas tábuas cortadas encostadas.
-- Relevo: ferramentas e lona sobem acima do tampo (h 10-12), tampo h 8-9,
-- cavaletes h 4-5, serragem h 1-2.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'bancada',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        -- tampo: base, fio iluminado, veios, face frontal
        w = {ramp = 'wood', step = 4, h = 9},
        W = {ramp = 'wood', step = 6, h = 10},
        v = {ramp = 'wood', step = 3, h = 8},
        F = {ramp = 'wood', step = 3, h = 7},
        -- cavaletes e tábuas encostadas
        l = {ramp = 'wood', step = 4, h = 5},
        u = {ramp = 'wood', step = 5, h = 5},
        -- serrote: lombada clara, lâmina, dentes; cabo escuro com furo
        i = {ramp = 'iron', step = 6, h = 12},
        t = {ramp = 'iron', step = 4, h = 11},
        T = {ramp = 'iron', step = 2, h = 11},
        H = {ramp = 'wood', step = 2, h = 11},
        -- martelo: cabeça de ferro com ferrugem, cabo de madeira
        m = {ramp = 'iron', step = 5, h = 12},
        M = {ramp = 'iron', step = 3, h = 12},
        r = {ramp = 'rust', step = 4, h = 12},
        -- metro dobrável de osso/madeira clara com traços escuros
        R = {ramp = 'bone', step = 5, h = 11},
        n = {ramp = 'bone', step = 2, h = 11},
        -- lona quente cobrindo a metade direita
        c = {ramp = 'clothWarm', step = 4, h = 10},
        C = {ramp = 'clothWarm', step = 5, h = 10},
        d = {ramp = 'clothWarm', step = 2, h = 9},
        -- serragem no chão
        s = {ramp = 'wood', step = 6, h = 2},
        e = {ramp = 'earth', step = 4, h = 1},
    },

    layers = {
        {   -- BANCO: tampo com ferramentas, face frontal, cavalete
            -- esquerdo e serragem no chão (linhas 1..96)
            name = 'banco',
            h = 5,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E,                  -- 21-28
                -- fio de trás do tampo
                L'.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW', -- 29
                L'.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW', -- 30
                -- superfície do tampo (31-45): tábuas + ferramentas
                L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 31
                L'.......wwwwwvwwwwwwwwwwwiiiiiiiiiiiiiiiiiiiwwmmmmwwwwww', -- 32
                L'.......wwwwwwwwwwwwwwwtttttttttttttttttttmmmMMmwwwwwwww', -- 33
                L'.......wwwwvwwwwwwwwtttttttttttttttttttttrmMMMMwwwwwwww', -- 34
                L'.......wwwwwwwwwwwwwtttttttttttttttttttttrMMMMMwwwwwwww', -- 35
                L'.......wwwwwwwwwwwwTTtTtTtTtTtTtTtTtTtTtTTMMMMMwwwwwwww', -- 36
                L'.......wwwwHHHHwwwwwwwwwwwwwwwwwwwwwwwwwwwMMMwwwwwwwwww', -- 37
                L'.......wwwwHkHHwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 38
                L'.......wwwwHkkHwwwwwwwwRRnnwwwwwwwwwwwwwwHHwwwwwwwwwwww', -- 39
                L'.......wwwwHHHHwwwwwwwRRRRnwwwwwwwwwwwwwHHwwwwwwwwwwwww', -- 40
                L'.......wwvwwwwwwwwwwwRRnnRRwwwwwwwwwwwwwHHwwwwwwwwwwwww', -- 41
                L'.......wwwwwwwwwwwwwRRRRnnwwwwwwwwwwwwHHwwwwwwwwwwwwwww', -- 42
                L'.......wwwwwwwwwwwwwRRRnnwwwwwwwwwwwwwHHHwwwwwwwwwwwwww', -- 43
                L'.......wwvwwwwwwwwwwnnnnnwwwwwwwwwwwwHHHHwwwwwwwwwwwwww', -- 44
                L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 45
                -- borda frontal: filete claro + face + contorno de baixo
                L'.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW', -- 46
                L'.......FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', -- 47
                L'.......FFvFFFFvFFFFFFvFFFFvFFFFvFFFFFFvFFFFvFFFvFFFFvFFFF', -- 48
                L'.......FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', -- 49
                L'.......kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk', -- 50
                E,                                            -- 51
                -- cavalete esquerdo (pernas do A) descendo até o chão
                L'...........lll...ll',                            -- 52
                L'...........lll...lll',                           -- 53
                L'...........lll....lll',                          -- 54
                L'..........lll.....lll',                          -- 55
                L'..........lll.....lll',                          -- 56
                L'..........lll......lll',                         -- 57
                L'..........lll......lll',                         -- 58
                L'.........lll.......lll',                         -- 59
                L'.........lll........lll',                        -- 60
                L'.........lll........lll',                        -- 61
                L'.........lll.........lll',                       -- 62
                L'........lll..........lll',                       -- 63
                L'........lll..........lll',                       -- 64
                L'........lll...........lll',                      -- 65
                L'........lll...........lll',                      -- 66
                L'........lll............lll',                     -- 67
                L'........lll.............lll',                    -- 68
                L'.......lll..............lll',                    -- 69
                L'.......lll..............lll',                    -- 70
                -- travessa horizontal do cavalete
                L'.......llllllllllllllllllllll',                  -- 71
                L'.......lll..............lll',                    -- 72
                L'......lll...............lll',                    -- 73
                L'......lll................lll',                   -- 74
                L'......lll................lll',                   -- 75
                L'......lll.................lll',                  -- 76
                L'.....lll..................lll',                  -- 77
                L'.....lll..................lll',                  -- 78
                L'.....lll...................lll',                 -- 79
                L'....lll....................lll',                 -- 80
                L'....lll....................lll',                 -- 81
                L'...lll......................lll',                -- 82
                L'...lll......................lll',                -- 83
                -- serragem e aparas sob a bancada até o pé do sprite
                L'..........e....s......e....ss',                  -- 84
                L'.....e...ss..sss.e.....s.ssss.....e',            -- 85
                L'....sss.ssssssssss..e..sssss.....ss',            -- 86
                L'..e.ssssssssssssssssssssssss.e...s',             -- 87
                L'....sssssssssssssssssssssssssss..e',             -- 88
                L'......essssssssssssssssssssssse',                -- 89
                L'.........ssssss..s..ssssss',                     -- 90
                L'..........sss......sss',                         -- 91
                L'............ss...ss',                            -- 92
                L'.............s....s',                            -- 93
                E, E, E,                                      -- 94-96
            },
        },
        {   -- CAVALETE DIREITO + tábuas encostadas (a lona, desenhada
            -- depois, cobre a borda do tampo acima dele)
            name = 'direito',
            h = 5,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E, E, E, E, E, E, E, E, E, E,            -- 41-50
                E,                                            -- 51
                L'............................................lll...ll',  -- 52
                L'............................................lll...lll', -- 53
                L'............................................lll....lll',-- 54
                L'...........................................lll.....lll',-- 55
                L'...........................................lll.....lll',-- 56
                L'...........................................lll......lll',-- 57
                L'...........................................lll......lll.uu',-- 58
                L'..........................................lll.......lll.uu',-- 59
                L'..........................................lll........lll.uu',-- 60
                L'..........................................lll........lll.uuu',-- 61
                L'..........................................lll.........lll.uuu',-- 62
                L'.........................................lll..........lll.uuu',-- 63
                L'.........................................lll..........lll.uuu',-- 64
                L'.........................................lll...........lll.uuu',-- 65
                L'.........................................lll...........lll.uuu',-- 66
                L'.........................................lll............lll.uu',-- 67
                L'.........................................lll.............lll.uu',-- 68
                L'........................................lll..............lll.uu',-- 69
                L'........................................lll..............lll.uu',-- 70
                L'........................................llllllllllllllllllll.uu',-- 71
                L'........................................lll..............lll.uu',-- 72
                L'.......................................lll...............lll.uu',-- 73
                L'.......................................lll................ll.uu',-- 74
                L'.......................................lll................ll.uu',-- 75
                L'.......................................lll.................l.uu',-- 76
                L'......................................lll..................l.uu',-- 77
                L'......................................lll..................l.uu',-- 78
                L'......................................lll...................luu',-- 79
                L'.....................................lll....................luu',-- 80
                L'.....................................lll....................luu',-- 81
                L'....................................lll......................uu',-- 82
                L'....................................lll......................uu',-- 83
                E, E, E, E, E, E, E, E, E, E,            -- 84-93
                E, E, E,                                      -- 94-96
            },
        },
        {   -- LONA: pano quente cobrindo a metade direita do tampo e
            -- escorrendo pela borda frontal com bainha escalopada
            name = 'lona',
            h = 10,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E,                  -- 21-28
                L'...............................................CCCCCCCCCCC',-- 29
                L'...............................................CCCCCCCCCCC',-- 30
                L'..............................................cccccccccccccc',-- 31
                L'..............................................cccccccccccccc',-- 32
                L'..............................................cccccccccccccc',-- 33
                L'..............................................cccdccccdcccccc',-- 34
                L'..............................................ccccccccccccccc',-- 35
                L'..............................................cdccccccccdcccc',-- 36
                L'..............................................ccccccccccccccc',-- 37
                L'..............................................ccccdccccccccc',-- 38
                L'..............................................cccccccccccccc',-- 39
                L'..............................................cdccccccdccccc',-- 40
                L'..............................................cccccccccccccc',-- 41
                L'..............................................ccccccdcccccc',-- 42
                L'..............................................cdccccccccccc',-- 43
                L'..............................................cccccdcccccc',-- 44
                L'..............................................dddddddddddd',-- 45
                -- parte que escorre sobre a borda (sombra + dobras)
                L'..............................................dccdccdccdc',-- 46
                L'..............................................ddddddddddd',-- 47
                L'..............................................dccdccdccdc',-- 48
                L'..............................................dddcdddcddd',-- 49
                L'..............................................dccdccdccdc',-- 50
                L'..............................................dddcdddcd',-- 51
                L'..............................................dccdc.cc',-- 52
                L'..............................................ddd.d.d',-- 53
                L'..............................................dk.kd.',-- 54
                E, E, E, E, E, E, E, E, E, E,            -- 55-64
                E, E, E, E, E, E, E, E, E, E,            -- 65-74
                E, E, E, E, E, E, E, E, E, E,            -- 75-84
                E, E, E, E, E, E, E, E, E, E,            -- 85-94
                E, E,                                         -- 95-96
            },
        },
    },
}
