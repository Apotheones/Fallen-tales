-- RECIPIENTES do poço — tile de chão, 64x64, origem topleft.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, "recipiente e
-- tigela"): balde, tigela e pote agrupados ao pé do poço, apoio gasto.
-- 3 frames = variantes por seed:
--   f1 = bocas viradas para cima — água partilhada: balde e tigela
--        guardam fundo d'água com reflexo claro
--   f2 = tombado/uso — alguém acabou de usar: balde deitado de lado
--        com resto d'água na boca e poça na terra, tigela virada para
--        baixo, pote inclinado
--   f3 = empilhado/guardado — pote dentro do balde, tigela virada por
--        cima da pilha, ordem apertada e seca
-- Relevo: pote 8-9, balde 6-7, tigela 4-5, água 3, terra 1-2.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)

local function R(map)
    local t = {}
    for r = 1, 64 do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end

-- terra batida do tile: massa calma com variação e pedrinhas
local function terra()
    local t = {}
    for y = 1, 64 do
        local row = {}
        for x = 1, 64 do
            local h = (x * 29 + y * 13) % 23
            local ch = 'e'
            if h == 0 then ch = 'E'
            elseif h == 1 then ch = 'x'
            elseif h == 2 then ch = 'o' end
            row[x] = ch
        end
        t[y] = table.concat(row)
    end
    return table.concat(t, '\n')
end

-- f1 — POTE de barro à direita-trás: bojo redondo, gargalo, boca para
-- cima. v3: engordado ~18% (bojo 17 col), gargalo e borda de base 2px.
local pote = {
    [9]  = '..............................................kkkkkkkk',
    [10] = '.............................................kppppppppk',
    [11] = '.............................................kpkkkkkkpk',
    [12] = '............................................kpppkkkkpppk',
    [13] = '............................................kpppppppppppk',
    [14] = '...........................................kppppppppppppk',
    [15] = '..........................................kpppPppppppPpppk',
    [16] = '.........................................kppppPppppppPppppk',
    [17] = '.........................................kpppppPpppppPppppk',
    [18] = '........................................kppppppPpppppPpppppk',
    [19] = '........................................kpppppppPppppPpppppk',
    [20] = '........................................kppppppppPpppPpppppk',
    [21] = '........................................kpppppppppPpPppppppk',
    [22] = '........................................kppppppppppPpppppppk',
    [23] = '........................................kppppppppppppppppppk',
    [24] = '........................................kppppppppppppppppppk',
    [25] = '.........................................kppppppppppppppppk',
    [26] = '.........................................kopppppppppppppok',
    [27] = '..........................................kooppppppppppook',
    [28] = '...........................................kooooooooooook',
    [29] = '............................................kkkkkkkkkkkk',
}

-- f2 — POTE inclinado: escorado para a direita, boca aberta no alto.
-- v3: bojo engordado, mesma leitura tombada.
local pote2 = {
    [11] = '......................................................kkkkkk',
    [12] = '.....................................................kpkkkkpk',
    [13] = '..................................................kpppkkkpppk',
    [14] = '.................................................kpppppppppppk',
    [15] = '................................................kppPppppppPppk',
    [16] = '...............................................kpppPppppppPpppk',
    [17] = '..............................................kppppPppppppPpppk',
    [18] = '.............................................kpppppPppppppPpppk',
    [19] = '............................................kppppppPppppppPpppk',
    [20] = '............................................kppppppPpppppPpppk',
    [21] = '...........................................kppppppppPpppppppppk',
    [22] = '...........................................kpppppppppPppppppppk',
    [23] = '..........................................kppppppppppppppppppk',
    [24] = '..........................................kpppppppppppppppppk',
    [25] = '...........................................kppppppppppppppppk',
    [26] = '...........................................kopppppppppppppok',
    [27] = '............................................koopppppppppook',
    [28] = '.............................................koooooooooook',
    [29] = '..............................................kkkkkkkkkkk',
}

-- f3 — POTE dentro do balde: só o fundo/bojo invertido sai da boca.
-- v3: bojo ~2 col mais largo; base da peça fecha com borda de 1 linha.
local pote3 = {
    [21] = '............................kkkkkkkkk',
    [22] = '..........................koooooooooook',
    [23] = '.........................kopppppppppppok',
    [24] = '........................kppppppppppppppk',
    [25] = '........................kpppPpppppppPpppk',
    [26] = '.......................kpppppPpppppppPpppk',
    [27] = '.......................kppppppPpppppPppppk',
    [28] = '.......................kpppppppPppppPppppk',
    [29] = '.......................kppppppppPpppPppppk',
    [30] = '........................kpppppppppppppppk',
    [31] = '........................kpppppppppppppppk',
    [32] = '.........................kpppppppppppppk',
    [33] = '.........................kpppppppppppppk',
    [34] = '..........................kpppppppppppk',
    [35] = '..........................kpppppppppppk',
    [36] = '...........................kkkkkkkkkk',
}

-- f1 — BALDE de madeira à esquerda: arco da boca com água dentro,
-- aduelas verticais e duas cintas de ferro. v3: corpo engordado ~17%
-- e cintas 'i' com 2px de altura.
local balde = {
    [14] = '....kwwwwwwwwwwwwwwwwwk',
    [15] = '...kwwkkkkkkkkkkkkkkwwk',
    [16] = '...kwkddddddddddddddkwk',
    [17] = '...kwkdssssssssssssdkwk',
    [18] = '...kwkdssSSSSsssssdkwk',
    [19] = '...kwkdssssssssssssdkwk',
    [20] = '...kwkddddddddddddddkwk',
    [21] = '...kwwkkkkkkkkkkkkkkwwk',
    [22] = '...kuuuuuiuuuuuuiuuuuuk',
    [23] = '...kuuuuuiuuuuuuiuuuuuk',
    [24] = '...kiiiiiiiiiiiiiiiiiik',
    [25] = '...kiiiiiiiiiiiiiiiiiik',
    [26] = '...kuuuuuiuuuuuuiuuuuuk',
    [27] = '...kuuuuuiuuuuuuiuuuuuk',
    [28] = '...kuuuuuiuuuuuuiuuuuuk',
    [29] = '...kuuuuuiuuuuuuiuuuuuk',
    [30] = '...kiiiiiiiiiiiiiiiiiik',
    [31] = '...kiiiiiiiiiiiiiiiiiik',
    [32] = '...kuuuuuiuuuuuuiuuuuuk',
    [33] = '...kuuuuuiuuuuuuiuuuuuk',
    [34] = '....kuuuuuiuuuuuiuuuuk',
    [35] = '....kuuuuuiuuuuuiuuuuk',
    [36] = '....kuuuuuiuuuuuiuuuuk',
    [37] = '....kuuuuuiuuuuuiuuuuk',
    [38] = '.....kkkkkkkkkkkkkkk',
}

-- f2 — BALDE deitado de lado: boca elíptica à esquerda com resto
-- d'água, aduelas na horizontal e cintas verticais; poça na terra.
-- v3: corpo 22 col (+10%), cintas 'ii' de 2px, borda 'k' contínua
-- entre a boca e o corpo.
local balde2 = {
    [18] = '......kkkkkkkkkk',
    [19] = '....kkwwwwwwwwwwkk.kwwwwiiwwwwwwwwiiwwwwk',
    [20] = '...kwwddddddddddwwkkwwwwiiwwwwwwwwiiwwwwk',
    [21] = '..kwdddddddddddddwwkuuuuiiuuuuuuuuiiuuuuk',
    [22] = '.kwwdddddddddddddwwkuuuuiiuuuuuuuuiiuuuuk',
    [23] = '.kwwdddddddddddddwwkuuuuiiuuuuuuuuiiuuuuk',
    [24] = '.kwwddsssSSsssssdwwkuuuuiiuuuuuuuuiiuuuuk',
    [25] = '.kwwdssssssssssdwwkuuuuiiuuuuuuuuiiuuuuk',
    [26] = '...kwwsssssssssswwkuuuuiiuuuuuuuuiiuuuuk',
    [27] = '.....kkwwwwwwwwwwk.kuuuuiiuuuuuuuuiiuuuuk',
    [28] = '.......kkkkkkkk.....kuuuuiiuuuuuuuuiiuuuuk',
    [29] = '..........kkkk.....kuuuuiiuuuuuuuuiiuuuuk',
    [30] = '...................kkkkkkkkkkkkkkkkkkkkkk',
    -- poça derramada na terra, embaixo da boca
    [32] = '......xxsxxxxsxx',
    [33] = '.........xsxxx',
}

-- f3 — BALDE em pé com o pote dentro: boca escura, aduelas e cintas.
-- v3: corpo 24 col (+14%), cintas 'i' com 2px de altura.
local balde3 = {
    [35] = '................kwwkkkkkkkkkkkkkkkkkwwk',
    [36] = '................kuuuuuiiuuuuuuiiuuuuuuk',
    [37] = '................kuuuuuiiuuuuuuiiuuuuuuk',
    [38] = '................kiiiiiiiiiiiiiiiiiiiiiik',
    [39] = '................kiiiiiiiiiiiiiiiiiiiiiik',
    [40] = '................kuuuuuiiuuuuuuiiuuuuuuk',
    [41] = '................kuuuuuiiuuuuuuiiuuuuuuk',
    [42] = '................kiiiiiiiiiiiiiiiiiiiiiik',
    [43] = '................kiiiiiiiiiiiiiiiiiiiiiik',
    [44] = '................kuuuuuiiuuuuuuiiuuuuuuk',
    [45] = '................kuuuuuiiuuuuuuiiuuuuuuk',
    [46] = '.................kuuuuiiuuuuuiiuuuuuk',
    [47] = '.................kuuuuiiuuuuuiiuuuuuk',
    [48] = '..................kkkkkkkkkkkkkkkkkkkk',
}

-- f1 — TIGELA de osso à frente-centro: rasa e larga, boca aberta com
-- fundo d'água. v3: boca 30 col (+20%), parede 'B' de 2px nas bordas.
local tigela = {
    [39] = '.......................kBBBBBBBBBBBBBBBBBBk',
    [40] = '.....................kBBkkddddddddddddddkkBBk',
    [41] = '....................kBkkdddssssssssssssdddkkBk',
    [42] = '....................kBdddssSsSssssSssssdddBk',
    [43] = '....................kBdddssssssssssssssdddBk',
    [44] = '.....................kBdddsssssssssssdddBk',
    [45] = '......................kBkdddddddddddddkBk',
    [46] = '.......................kbbbBBBBBBBBBbbbk',
    [47] = '........................kbbbbbbbbbbbbbk',
    [48] = '.........................kkkkkkkkkkkkk',
}

-- f2 — TIGELA virada para baixo: domo fechado com a base para cima.
-- v3: domo ~4 col mais largo, filete de borda 'k' reforçado.
local tigela2 = {
    [40] = '.............................kbbbk',
    [41] = '..........................kkkkkkkkkkkkkk',
    [42] = '.......................kBbbbbbbbbbbbbbbBk',
    [43] = '.....................kBbbbbbbbbbbbbbbbbbbBk',
    [44] = '...................kBBBbbbbbbbbbbbbbbbbbbBBBk',
    [45] = '..................kbbbbbbbbbbbbbbbbbbbbbbbbk',
    [46] = '..................kbbbbbbbbbbbbbbbbbbbbbbbbk',
    [47] = '...................kkkkkkkkkkkkkkkkkkkkkkkkk',
}

-- f3 — TIGELA virada em cima da pilha: domo pequeno de tampa.
-- v3: ~2 col mais larga, mesma leitura de tampa.
local tigela3 = {
    [16] = '...........................kkkkkkkkkk',
    [17] = '.........................kBbbbbbbbbbbBk',
    [18] = '........................kBbbbbbbbbbbbbBk',
    [19] = '........................kbbbbbbbbbbbbbbk',
    [20] = '.........................kkkkkkkkkkkkkkkk',
}

return {
    name = 'recipientes',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 3},
        -- terra do tile
        e = {ramp = 'earth', step = 3, h = 1},
        E = {ramp = 'earth', step = 4, h = 1},
        x = {ramp = 'earth', step = 2, h = 1},
        o = {ramp = 'stone', step = 2, h = 2},
        -- balde: aduelas, cintas de ferro, água
        w = {ramp = 'wood', step = 5, h = 7},
        u = {ramp = 'wood', step = 4, h = 6},
        i = {ramp = 'iron', step = 3, h = 7},
        -- tigela de osso
        B = {ramp = 'bone', step = 5, h = 5},
        b = {ramp = 'bone', step = 4, h = 4},
        d = {ramp = 'bone', step = 2, h = 4},
        -- pote de barro (reboco) com sombra de base
        p = {ramp = 'plaster', step = 4, h = 8},
        P = {ramp = 'plaster', step = 5, h = 9},
        -- água parada e reflexo
        s = {ramp = 'sea', step = 3, h = 3},
        S = {ramp = 'sea', step = 5, h = 3},
    },

    layers = {
        {name = 'terra', h = 1, albedo = terra()},
        {name = 'pote', h = 8, albedo = {R(pote), R(pote2), R(pote3)}},
        {name = 'balde', h = 6, albedo = {R(balde), R(balde2), R(balde3)}},
        {name = 'tigela', h = 4, albedo = {R(tigela), R(tigela2), R(tigela3)}},
    },
}
