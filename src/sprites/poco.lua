-- POÇO / CISTERNA — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/PLANO_REFUGIO_ANDLAR.md): o poço do povoado, em uso —
-- anel de pedra com borda clara no topo, boca escura, sarilho de madeira
-- com corda de fibra clara e balde pendurado sobre a abertura. Musgo nos
-- cantos da pedra, sem parecer novo demais.
-- Relevo: boca 9-11 (anel alto), sarilho 11-12, abertura afunda (h 3),
-- face frontal 8-9, base 6-7.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'poco',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 5},
        a = {spec = 'abyss', h = 3},            -- boca escura
        -- anel de pedra: borda clara, topo, pedra alternada, sombra interna
        S = {ramp = 'stone', step = 6, h = 11},
        s = {ramp = 'stone', step = 4, h = 10},
        t = {ramp = 'stone', step = 5, h = 10},
        o = {ramp = 'stone', step = 2, h = 7},  -- parede interna em sombra
        -- face frontal: tijolos, juntas, base
        b = {ramp = 'stone', step = 4, h = 9},
        B = {ramp = 'stone', step = 5, h = 9},
        m = {ramp = 'stone', step = 2, h = 8},
        d = {ramp = 'stone', step = 3, h = 7},
        -- musgo
        g = {ramp = 'moss', step = 3, h = 9},
        G = {ramp = 'moss', step = 2, h = 7},
        -- sarilho e corda
        w = {ramp = 'wood', step = 4, h = 11},
        W = {ramp = 'wood', step = 6, h = 12},
        r = {ramp = 'bone', step = 4, h = 12},
        -- balde de madeira com cinta de ferro
        u = {ramp = 'wood', step = 3, h = 11},
        U = {ramp = 'wood', step = 5, h = 11},
        i = {ramp = 'iron', step = 3, h = 11},
        -- chão ao redor
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {   -- ANEL: boca do poço + face frontal de pedra até o chão
            name = 'anel',
            h = 9,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E, E, E, E, E,                           -- 41-45
                -- borda de trás do anel (fio claro)
                L'..................SSSSSSSSSSSSSSSSSSSSSSSSSSSS',   -- 46
                L'................SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS', -- 47
                -- superfície do anel: pedras alternadas
                L'.............ssttttssttttssttttssttttssttttsstss', -- 48
                L'...........ssttssttssttssttssttssttssttssttsstsss',-- 49
                L'..........stssttssttssttssttssttssttssttssttsstst',-- 50
                L'.........ssstttssttssttssttssttssttssttssttsstssss',-- 51
                L'........sssttssttssttssttssttssttssttssttsstttssss',-- 52
                L'........ssttssttssttssttssttssttssttssttssttsstsss',-- 53
                -- abertura: parede interna em sombra
                L'........ssssssssssssooooooooooooooooooooooossssssssssss',-- 54
                L'........ssssssssssooooooooooooooooooooooossssssssssss',-- 55
                L'........sssssssssoooooooooooooooooooooooosssssssssssss',-- 56
                L'........sssssssssoooooooooooooooooooooooosssssssssssss',-- 57
                L'........ssssssssoooooooooooooooooooooooosssssssssssss',-- 58
                L'........ssssssssoooooooooooooooooooooooosssssssssssss',-- 59
                L'........sssssssaaaaaaaaaaaaaaaaaaaaaaaasssssssssssss',-- 60
                L'........sssssssaaaaaaaaaaaaaaaaaaaaaaaasssssssssssss',-- 61
                L'........sssssssaaaaaaaaaaaaaaaaaaaaaaaassssssssssss',-- 62
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaassssssssssss',-- 63
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaassssssssssss',-- 64
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaasssssssssssss',-- 65
                L'........sssssssssaaaaaaaaaaaaaaaaaaaaasssssssssssss',-- 66
                L'........ssssssssssaaaaaaaaaaaaaaaaaaassssssssssssss',-- 67
                -- borda da frente do anel (fio claro)
                L'........ssssssssssstttttttttttttttttttsssssssssssssss',-- 68
                L'........sssssssssssssttttttttttttttttsssssssssssssss',-- 69
                L'.........ssssssssssssssttttttttttttssssssssssssssss',-- 70
                L'..........ssssssssssssssssttttttsssssssssssssssss',-- 71
                L'...........ssssssssssssssssssssssssssssssssssssss',-- 72
                -- face frontal: tijolos com juntas e musgo
                L'........kbbbbbbbbbbbbbBbbbbbbbbbbBbbbbbbbbbbbbbbbk',-- 73
                L'........kbbbbbbbbbbbbbBbbbbbbbbbbBbbbbbbbbbbbbbbbk',-- 74
                L'........kbbBbbbbbbbbbbbbbbbbbbbbbbbbbBbbbbbbbbbk',-- 75
                L'........kbbbbbbbbbbbbmbbbbbbbbbbbbbbbbbbbbbbbbbbk',-- 76
                L'........kbbbbbbbbbbbbbBbbbbggbbbbbbbbbbbbbbbbbbk',-- 77
                L'........kmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmk',-- 78
                L'........kbbbbBbbbbbbbbbbbbbBbbbbbbbbbbbbbbBbbbk',-- 79
                L'........kbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbk',-- 80
                L'........kbbbbbbbbbbggggbbbbbbbbbbbbmbbbbbbbbbbbk',-- 81
                L'........kbbbbbbbbbggggggbbbbbbbbbbbbbbbbbbbbbbbk',-- 82
                L'........kbBbbbbbbbbggggbbbbbbbbbbbbbbbbbbbbbbbbk',-- 83
                L'........kmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmk',-- 84
                L'........kdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdk',-- 85
                L'........kddddddddddddddddddddddddddddddddddddddk',-- 86
                L'........kddddddddddddddddddddddddddddddddddddddk',-- 87
                L'.........kddddddddddddddddddddddddddddddddddddk',-- 88
                L'.........kdddddddddddddddddddddddddddddddddddk',-- 89
                L'..........kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',-- 90
                -- pé no chão: junta, terra e musgo
                L'...........mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm',-- 91
                L'...........e..e.....e..e.....e..e.....e..e',-- 92
                L'............e..g...e..e..g...e..e..g...e',-- 93
                L'..........e..e..e..G..e..e..e..g..e..e',-- 94
                L'...........e....e....e..e....e...e',-- 95
                L'............e....e..e...e....e',-- 96
            },
        },
        {   -- SARILHO: postes laterais, eixo com corda enrolada, manivela,
            -- corda descendo e balde pendurado sobre a boca
            name = 'sarilho',
            h = 11,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E,                        -- 21-26
                -- chapéu dos postes
                L'...............W..............................W',-- 27
                L'..............www............................www',-- 28
                L'..............www............................www',-- 29
                -- eixo atravessa os postes e passa à direita (manivela)
                L'..............wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWwwwwwww',-- 30
                L'..............wwwwwwwwwwwwrrrrrrrrrwwwwwwwwwwwww',-- 31
                L'..............wwwwwwwwwwwrrrrrrrrrrrwwwwwwwwwww.w',-- 32
                L'..............wwwWWWWWWWWrrrrrrrrrWWWWWWWWWWwww.u',-- 33
                L'..............www...............rr...........www.u',-- 34
                L'..............www...............rr...........www',-- 35
                L'..............www...............rr...........www',-- 36
                L'..............www...............rr...........www',-- 37
                L'..............www...............rr...........www',-- 38
                L'..............www...............rr...........www',-- 39
                L'..............www...............rr...........www',-- 40
                L'..............www...............rr...........www',-- 41
                L'..............www...............rr...........www',-- 42
                L'..............www...............rr...........www',-- 43
                L'..............www...............rr...........www',-- 44
                L'..............www...............rr...........www',-- 45
                L'..............www...............rr...........www',-- 46
                L'...............w................rr............w',-- 47
                L'................................rr',-- 48
                L'................................rr',-- 49
                L'................................rr',-- 50
                L'................................rr',-- 51
                L'................................rr',-- 52
                L'................................rr',-- 53
                L'................................rr',-- 54
                L'................................rr',-- 55
                L'................................rr',-- 56
                L'................................rr',-- 57
                -- balde pendurado na corda, dentro da boca
                L'..............................UUUUUUUUU',-- 58
                L'..............................ukkkkkkku',-- 59
                L'..............................uUUUUUUUu',-- 60
                L'..............................uuuuuuuuu',-- 61
                L'..............................iiiiiiiii',-- 62
                L'..............................uuuuuuuuu',-- 63
                L'...............................uuuuuuu',-- 64
                L'...............................uuuuuuu',-- 65
                L'................................uuuuu',-- 66
                E, E, E, E, E, E, E, E, E, E,            -- 67-76
                E, E, E, E, E, E, E, E, E, E,            -- 77-86
                E, E, E, E, E, E, E, E, E, E,            -- 87-96
            },
        },
    },
}
