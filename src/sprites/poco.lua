-- POÇO / CISTERNA — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/PLANO_REFUGIO_ANDLAR.md): o poço do povoado, em uso —
-- anel de pedra com borda clara no topo, boca escura, sarilho de madeira
-- com corda de fibra clara e balde pendurado sobre a abertura. Musgo nos
-- cantos da pedra, sem parecer novo demais.
-- Relevo: boca 9-11 (anel alto), sarilho 11-12, abertura afunda (h 3),
-- face frontal 8-9, base 6-7.
--
-- LOOP AMBIENTAL (frente micro-animações): f1..f4 — o fio de luz 'l'/'L'
-- na água do fundo desliza em pingue-pongue (f1=f3 neutro, f2=f4 iguais
-- por simetria: +0/+1/+2/+1). Anel, sarilho, balde e chão são estáticos;
-- a camada 'agua' é a única com frames.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

local W, H = 64, 96
local function nova(fill)
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = fill end
        g[y] = r
    end
    return g
end
local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end
local function lin(g, x, y, s)
    for i = 1, #s do set(g, x + i - 1, y, s:sub(i, i)) end
end
local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

-- Fio de luz na água lá no fundo do poço: fica nas linhas 65-67 da boca
-- ('a' abissal), livre do balde (cols 30-39, linhas 58-66). Desliza
-- ±2 px à esquerda do balde e rebate na parede direita — shimmer, não
-- correnteza.
local function agua(fase)
    local g = nova('.')
    local dx = ({0, 1, 2, 1})[fase]
    lin(g, 18 + dx, 65, 'll')        -- esquerda do balde
    lin(g, 20 + dx, 66, 'llLl')
    lin(g, 23 + dx, 67, 'lLll')
    lin(g, 41 - dx, 65, 'lL')        -- rebate na parede direita
    lin(g, 33 - dx, 67, 'lLl')       -- sob o balde, linha do fundo
    return str(g)
end

return {
    name = 'poco',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 5},
        a = {spec = 'abyss', h = 3},            -- boca escura
        -- anel de pedra: borda clara, topo, pedra alternada, sombra interna
        -- v2: peça lia escura demais — superfície do anel e face frontal
        -- sobem um degrau (s 4->5, t 5->6, S 6->7, b/B/m/d +1) e o fio
        -- claro da borda frontal fica com 2 px de altura.
        S = {ramp = 'stone', step = 7, h = 11},
        s = {ramp = 'stone', step = 5, h = 10},
        t = {ramp = 'stone', step = 6, h = 10},
        o = {ramp = 'stone', step = 2, h = 7},  -- parede interna em sombra
        -- face frontal: tijolos, juntas, base
        b = {ramp = 'stone', step = 5, h = 9},
        B = {ramp = 'stone', step = 6, h = 9},
        m = {ramp = 'stone', step = 3, h = 8},
        d = {ramp = 'stone', step = 4, h = 7},
        -- musgo
        g = {ramp = 'moss', step = 3, h = 9},
        G = {ramp = 'moss', step = 2, h = 7},
        -- sarilho e corda
        w = {ramp = 'wood', step = 4, h = 11},
        W = {ramp = 'wood', step = 6, h = 12},
        r = {ramp = 'bone', step = 4, h = 12},
        -- balde de madeira com cinta de ferro
        u = {ramp = 'wood', step = 4, h = 11},
        U = {ramp = 'wood', step = 6, h = 11},
        i = {ramp = 'iron', step = 3, h = 11},
        -- fio de luz na água do fundo (loop f1..f4): albedo claro de mar,
        -- brilho frio contido — brilha sem competir com braseiro/lampião
        l = {ramp = 'sea', step = 4, h = 2, e = 'sea.4', ei = 0.18},
        L = {ramp = 'sea', step = 6, h = 2, e = 'sea.6', ei = 0.25},
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
                -- superfície do anel: pedras claras com remendos
                L'.............tttttttSSSttttttSSSttttttSSStttttt', -- 48
                L'...........ttttttttttttttttttttttttttttttttttttt',-- 49
                L'..........tttsssttttssstttttsssttttsssttttsstttt',-- 50
                L'.........ttttsssttttssstttttsssttttsssttttssttttt',-- 51
                L'........sttttsssttttssstttttsssttttsssttttssttttts',-- 52
                L'........sstttsssttttssstttttsssttttsssttttssttttss',-- 53
                -- abertura: parede interna em sombra, depois o abismo
                L'........ssssssssssoooooooooooooooooooooooossssssssss',-- 54
                L'........sssssssssoooooooooooooooooooooooosssssssssss',-- 55
                L'........ssssssssoooooooooooooooooooooooossssssssssss',-- 56
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaaassssssssssss',-- 57
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaaassssssssssss',-- 58
                L'........sssssssaaaaaaaaaaaaaaaaaaaaaaaaassssssssssss',-- 59
                L'........sssssssaaaaaaaaaaaaaaaaaaaaaaaaasssssssssss',-- 60
                L'........sssssssaaaaaaaaaaaaaaaaaaaaaaaaasssssssssss',-- 61
                L'........sssssssaaaaaaaaaaaaaaaaaaaaaaaaasssssssssss',-- 62
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaaasssssssssss',-- 63
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaaasssssssssss',-- 64
                L'........ssssssssaaaaaaaaaaaaaaaaaaaaaaaasssssssssss',-- 65
                L'........sssssssssaaaaaaaaaaaaaaaaaaaaaasssssssssssss',-- 66
                L'........ssssssssssaaaaaaaaaaaaaaaaaaaassssssssssssss',-- 67
                -- borda da frente do anel (fio claro, 2 px de altura)
                L'........sssssssssssSSSSSSSSSSSSSSSSSSSssssssssssssss',-- 68
                L'........sssssssssssSSSSSSSSSSSSSSSSSSSsssssssssssss',-- 69
                L'.........ssssssssssstttttttttttttttttssssssssssssss',-- 70
                L'..........ssssssssssssssttttttttttssssssssssssssss',-- 71
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
                L'..............wwwwwwwwwwwrrrrrrrrrrrwwwwwwwwwww',-- 32
                L'..............wwwWWWWWWWWrrrrrrrrrWWWWWWWWWWwww',-- 33
                L'..............www...............rr...........www',-- 34
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
        {   -- ÁGUA: fio de luz no fundo da boca — f1..f4 = loop de
            -- shimmer (ver cabeçalho). Por cima do abismo 'a', atrás de
            -- nada: só pixels livres da parede e do balde.
            name = 'agua',
            h = 2,
            albedo = { agua(1), agua(2), agua(3), agua(4) },
            emissive = { agua(1), agua(2), agua(3), agua(4) },
        },
    },
}
