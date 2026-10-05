-- SIT_CONTEMPLACAO — ator de banco, 64x96, origem nos pés, 3f.
-- O "banco de contemplação habitado": figura sentada de PERFIL para a
-- esquerda (o vale fica à esquerda do quadro), casaco areia comprido,
-- pernas estendidas à frente, braço apoiado no assento atrás do
-- quadril, cabeça erguida. Encaixa sobre banco_terraco (assento ~y44-55
-- do prop): o quadril senta na linha do assento, os pés pousam no chão
-- à frente. f1 repouso | f2 respiro (tronco+cabeça sobem 1px) |
-- f3 olha um pássaro (cabeça vira ~2px para cima/esquerda).
-- Relevo: casaco 6-7, pele 10-11, pernas/botas 3-4.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)
local function R(map)
    local t = {}
    for r = 1, 96 do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end
local function shift(map, dy, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then t[r + dy] = s
        else t[r] = s end
    end
    return t
end
local function patch(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do t[r] = s end
    return t
end

--------------------------------------------------------------------------------
-- FIGURA sentada, perfil esquerdo: cabeça erguida (olho 'e' à frente,
-- nariz na borda esquerda), cabelo ralo claro 'g' atrás, casaco areia
-- 'c' caindo reto do ombro ao assento, braço 's' repousa no assento
-- atrás, pernas 'p' estendidas à esquerda até as botas 'b' no chão.
--------------------------------------------------------------------------------
local corpo = {
    -- cabeça: perfil à esquerda, queixo erguido
    [16] = '............................kkkkkk',
    [17] = '...........................kggggggk',
    [18] = '..........................kggggggggk',
    [19] = '..........................kggggssggk',
    [20] = '..........................kgggsssssk',
    [21] = '.........................kggsssssesk',
    [22] = '.........................kggssssssssk',
    [23] = '.........................kgssssssssk',
    [24] = '.........................ksssssdssk',
    [25] = '.........................kssssssssk',
    [26] = '..........................kssssssk',
    [27] = '..........................ksssssk',
    [28] = '...........................kssssk',
    [29] = '...........................kssssk',
    -- pescoço/ombro: casaco sobe à nuca
    [30] = '...........................kssskk',
    [31] = '..........................kkcccck',
    [32] = '.........................kcccccccck',
    [33] = '........................kcccccccccck',
    [34] = '.......................kccccccccccck',
    [35] = '......................kcccccccccccck',
    [36] = '......................kccccccccccccck',
    [37] = '......................kccccccccccccck',
    [38] = '......................kcccccccccccccck',
    [39] = '......................kcccccccccccccck',
    -- braço cai para trás e repousa no assento
    [40] = '......................kcccccccccccckkck',
    [41] = '......................kccccccccccck..kck',
    [42] = '......................kcccccccccck...kck',
    [43] = '......................kcccccccccck...kck',
    [44] = '......................kcccccccccck...kck',
    [45] = '......................kcccccccccck...kck',
    [46] = '......................kcccccccccck...ksk',
    [47] = '......................kcccccccccck...ksk',
    [48] = '......................kcccccccccck...kssk',
    [49] = '......................kcccccccccck...kssk',
    [50] = '......................kcccccccccck....ksk',
    [51] = '......................kcccccccccck....ksk',
    -- mão espalmada no assento, atrás do quadril
    [52] = '......................kcccccccccck...ksssk',
    [53] = '......................kcccccccccck....kssk',
    [54] = '......................kcccccccccck.....kk',
    -- quadril sentado; casaco cobre a coxa
    [55] = '.....................kcccccccccccck',
    [56] = '....................kccccccccccccck',
    [57] = '....................kccccccccccckk',
    [58] = '...................kcccccccccck',
    [59] = '...................kcccccccck',
    -- coxa estendida à esquerda, canela desce à bota
    [60] = '..................kpppppkcck',
    [61] = '.................kpppppppk',
    [62] = '................kppppppppk',
    [63] = '...............kpppppppk',
    [64] = '...............kppppppk',
    [65] = '..............kppppppk',
    [66] = '..............kpppppk',
    [67] = '.............kpppppk',
    [68] = '.............kppppk',
    [69] = '.............kpppk',
    [70] = '............kpppk',
    [71] = '............kppk',
    [72] = '............kppk',
    [73] = '............kppk',
    [74] = '............kppk',
    [75] = '............kppk',
    [76] = '............kppk',
    [77] = '............kppk',
    [78] = '............kppk',
    [79] = '............kppk',
    [80] = '............kppk',
    [81] = '............kppk',
    [82] = '............kppk',
    [83] = '............kppk',
    [84] = '............kppk',
    [85] = '............kppk',
    -- bota apontando para o vale (esquerda)
    [86] = '...........kbbbk',
    [87] = '..........kbbbbk',
    [88] = '.........kbbbbbk',
    [89] = '.........kbbbbbk',
    [90] = '........kbbbbbbk',
    [91] = '........kbbbbbBk',
    [92] = '........kooooook',
    [93] = '........kkkkkkkk',
}

-- f2 respiro: tronco+cabeça sobem 1px (o assento e a mão ficam).
local respiro = shift(corpo, -1, 16, 51)

-- f3 olha o pássaro: a cabeça gira para cima/esquerda — o bloco da
-- cabeça sobe 1px além do respiro e inclina: a fileira do nariz avança
-- 1px à esquerda.
local cabecaPassaro = patch(shift(corpo, -1, 16, 51), {
    [15] = '...........................kkkkkk',
    [16] = '..........................kggggggk',
    [17] = '.........................kggggggggk',
    [18] = '.........................kggggssggk',
    [19] = '.........................kgggsssssk',
    [20] = '........................kggsssssesk',
    [21] = '........................kggssssssssk',
    [22] = '........................kgssssssssk',
    [23] = '........................ksssssdssk',
    [24] = '........................kssssssssk',
    [25] = '.........................kssssssk',
    [26] = '..........................ksssssk',
    [27] = '...........................kssssk',
    [28] = '...........................kssssk',
})

return {
    name = 'sit_contemplacao',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},  -- rosto/mão
        d = {ramp = 'skin', step = 2, h = 10},  -- sombra/boca
        e = {spec = 'ink', h = 12},             -- olho
        g = {ramp = 'plaster', step = 5, h = 11}, -- cabelo ralo claro
        c = {ramp = 'plaster', step = 3, h = 6}, -- casaco areia comprido
        p = {ramp = 'earth', step = 3, h = 4},  -- calças
        b = {ramp = 'earth', step = 2, h = 2},  -- bota
        B = {ramp = 'earth', step = 4, h = 3},
        o = {ramp = 'earth', step = 5, h = 2},  -- sola
    },

    -- W4: pe = sob a bota (contato com o chão); 'assento' = quadril no
    -- banco; 'cabeca' acompanha a nuca.
    anchors = {
        pe = {13, 93},
        assento = {30, 57},
        cabeca = {{28, 21}, {28, 20}, {26, 19}},
    },
    sequences = { idle = {1, 3, loop = true} },
    frameDuration = {0.9, 0.7, 1.4},

    layers = {
        {name = 'corpo', h = 5, albedo = {
            R(corpo), R(respiro), R(cabecaPassaro),
        }},
    },
}
