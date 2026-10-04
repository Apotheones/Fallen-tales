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

-- f1 — POTE de barro à direita-trás: bojo redondo, gargalo, boca para cima
local pote = {
    [10] = '..............................................kkkkkkk',
    [11] = '.............................................kpppppppk',
    [12] = '.............................................kpkkkkkpk',
    [13] = '............................................kpppkkkpppk',
    [14] = '............................................kpppppppppk',
    [15] = '...........................................kpppppppppppk',
    [16] = '..........................................kpppPpppppPpppk',
    [17] = '.........................................kppppPpppppPppppk',
    [18] = '.........................................kpppppPppppPppppk',
    [19] = '........................................kppppppPpppPpppppk',
    [20] = '........................................kpppppppPpPppppppk',
    [21] = '........................................kppppppppPpppppppk',
    [22] = '........................................kppppppppppppppppk',
    [23] = '........................................kppppppppppppppppk',
    [24] = '.........................................kppppppppppppppk',
    [25] = '.........................................koppppppppppppok',
    [26] = '..........................................kooppppppppook',
    [27] = '...........................................kooooooooook',
    [28] = '............................................kkkkkkkkkk',
}

-- f2 — POTE inclinado: escorado para a direita, boca aberta no alto
local pote2 = {
    [12] = '.........................................................kkkkk',
    [13] = '........................................................kpkkkkpk',
    [14] = '.....................................................kpppkkkpppk',
    [15] = '....................................................kppppppppppk',
    [16] = '...................................................kppPppppPppk',
    [17] = '..................................................kpppPppppPpppk',
    [18] = '.................................................kppppPppppPpppk',
    [19] = '................................................kpppppPppppPpppk',
    [20] = '................................................kppppppPpppPpppk',
    [21] = '...............................................kpppppppPpppppppk',
    [22] = '...............................................kppppppppPppppppk',
    [23] = '..............................................kpppppppppppppppk',
    [24] = '..............................................kpppppppppppppppk',
    [25] = '...............................................kpppppppppppppk',
    [26] = '...............................................kopppppppppppok',
    [27] = '................................................kooppppppppook',
    [28] = '.................................................kooooooooook',
    [29] = '..................................................kkkkkkkkkk',
}

-- f3 — POTE dentro do balde: só o fundo/bojo invertido sai da boca
local pote3 = {
    [22] = '.............................kkkkkkk',
    [23] = '...........................kooooooooook',
    [24] = '..........................kopppppppppok',
    [25] = '.........................kppppppppppppk',
    [26] = '.........................kpppPppppppPppk',
    [27] = '........................kpppppPpppppPpppk',
    [28] = '........................kppppppPpppPpppppk',
    [29] = '........................kpppppppPpPppppppk',
    [30] = '........................kppppppppPpppppppk',
    [31] = '.........................kpppppppppppppk',
    [32] = '.........................kpppppppppppppk',
    [33] = '..........................kpppppppppppk',
    [34] = '..........................kpppppppppppk',
    [35] = '...........................kppppppppk',
}

-- f1 — BALDE de madeira à esquerda: arco da boca com água dentro,
-- aduelas verticais e duas cintas de ferro
local balde = {
    [16] = '....kwwwwwwwwwwwwwwk',
    [17] = '...kwwkkkkkkkkkkkwwk',
    [18] = '...kwkddddddddddkwk',
    [19] = '...kwkdsssssssdkwk',
    [20] = '...kwkdssSSsssdkwk',
    [21] = '...kwkdsssssssdkwk',
    [22] = '...kwkddddddddddkwk',
    [23] = '...kwwkkkkkkkkkkwwk',
    [24] = '...kuuuuiuuuuuiuuuuk',
    [25] = '...kuuuuiuuuuuiuuuuk',
    [26] = '...kiiiiiiiiiiiiiiik',
    [27] = '...kuuuuiuuuuuiuuuuk',
    [28] = '...kuuuuiuuuuuiuuuuk',
    [29] = '...kuuuuiuuuuuiuuuuk',
    [30] = '...kuuuuiuuuuuiuuuuk',
    [31] = '...kiiiiiiiiiiiiiiik',
    [32] = '...kuuuuiuuuuuiuuuuk',
    [33] = '...kuuuuiuuuuuiuuuuk',
    [34] = '....kuuuuiuuuuiuuuk',
    [35] = '....kuuuuiuuuuiuuuk',
    [36] = '....kuuuuiuuuuiuuuk',
    [37] = '.....kkkkkkkkkkkkk',
}

-- f2 — BALDE deitado de lado: boca elíptica à esquerda com resto
-- d'água, aduelas na horizontal e cintas verticais; poça na terra
local balde2 = {
    [19] = '......kkkkkkkk',
    [20] = '....kkwwwwwwwwkk.kwwwwiwwwwwwwwiwwwwk',
    [21] = '...kwwddddddddwwkkwwwwiwwwwwwwwiwwwwk',
    [22] = '..kwdddddddddddwwkuuuuiuuuuuuuuiuuuuk',
    [23] = '.kwwdddddddddddwwkuuuuiuuuuuuuuiuuuuk',
    [24] = '.kwwdddddddddddwwkuuuuiuuuuuuuuiuuuuk',
    [25] = '.kwwddssSsssssdwwkuuuuiuuuuuuuuiuuuuk',
    [26] = '.kwwdssssssssssdwwkuuuuiuuuuuuuuiuuuuk',
    [27] = '...kwwssssssssswwkkuuuiuuuuuuuuiuuuuk',
    [28] = '....kksssssssskk.kuuuiuuuuuuuuiuuuuk',
    [29] = '......kkkkkkkk...kuuuiuuuuuuuuiuuuuk',
    [30] = '........kkkk.....kuuuiuuuuuuuuiuuuuk',
    [31] = '.................kkkkkkkkkkkkkkkkkkkk',
    -- poça derramada na terra, embaixo da boca
    [33] = '......xxsxxxxsxx',
    [34] = '.........xsxx',
}

-- f3 — BALDE em pé com o pote dentro: boca escura, aduelas e cintas
local balde3 = {
    [36] = '.................kwwkkkkkkkkkkkkkkkwwk',
    [37] = '.................kuuuuiuuuuuiuuuuuiuuuuk',
    [38] = '.................kuuuuiuuuuuiuuuuuiuuuuk',
    [39] = '.................kiiiiiiiiiiiiiiiiiiiiik',
    [40] = '.................kuuuuiuuuuuiuuuuuiuuuuk',
    [41] = '.................kuuuuiuuuuuiuuuuuiuuuuk',
    [42] = '.................kiiiiiiiiiiiiiiiiiiiiik',
    [43] = '.................kuuuuiuuuuuiuuuuuiuuuuk',
    [44] = '.................kuuuuiuuuuuiuuuuuiuuuuk',
    [45] = '..................kuuuuiuuuuiuuuuiuuuuk',
    [46] = '..................kuuuuiuuuuiuuuuiuuuuk',
    [47] = '...................kkkkkkkkkkkkkkkkkkk',
}

-- f1 — TIGELA de osso à frente-centro: rasa e larga, boca aberta com
-- fundo d'água
local tigela = {
    [40] = '........................kBBBBBBBBBBBBBBBBk',
    [41] = '......................kBBkkddddddddddddkkBBk',
    [42] = '.....................kBkdddssssssssssdddkBk',
    [43] = '.....................kBdddssSsSsssSsssddBk',
    [44] = '.....................kBdddssssssssssssddBk',
    [45] = '......................kBdddsssssssssdddBk',
    [46] = '.......................kBkdddddddddddkBk',
    [47] = '........................kbbbBBBBBBBbbbk',
    [48] = '.........................kbbbbbbbbbbbk',
    [49] = '..........................kkkkkkkkkkk',
}

-- f2 — TIGELA virada para baixo: domo fechado com a base para cima
local tigela2 = {
    [40] = '..............................kbbk',
    [41] = '...........................kkkkkkkkkkkk',
    [42] = '........................kBbbbbbbbbbbbbBk',
    [43] = '......................kBbbbbbbbbbbbbbbbbBk',
    [44] = '.....................kBBBbbbbbbbbbbbbbbbbBk',
    [45] = '....................kbbbbbbbbbbbbbbbbbbbbbbk',
    [46] = '....................kbbbbbbbbbbbbbbbbbbbbbbk',
    [47] = '.....................kkkkkkkkkkkkkkkkkkkkkk',
}

-- f3 — TIGELA virada em cima da pilha: domo pequeno de tampa
local tigela3 = {
    [17] = '............................kkkkkkkk',
    [18] = '..........................kBbbbbbbbbBk',
    [19] = '.........................kBbbbbbbbbbbBk',
    [20] = '.........................kbbbbbbbbbbbbk',
    [21] = '..........................kkkkkkkkkkkkkk',
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
