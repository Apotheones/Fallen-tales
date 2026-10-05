-- JARDINEIRO — idle LESTE (perfil olhando para a direita), 64x96, 4f.
-- npc_jardineiro_w = espelho via código. Mesma figura do _s: chapéu de
-- palha em perfil (aba comprida sobre o rosto), camisa moss, colete
-- terra na frente, enxada apoiada na mão da frente. f1 repouso |
-- f2 respiro | f3 olha o canteiro (chapéu+cabeça descem 1px) |
-- f4 respiro + ajusta o chapéu (braço da frente sobe à aba).

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
local function put(map, r, c, s)
    local row = L(map[r] or '')
    map[r] = row:sub(1, c - 1) .. s .. row:sub(c + #s)
end
local function blank(map, r1, r2, c1, c2)
    for r = r1, r2 do
        local row = map[r]
        if row then
            row = L(row)
            map[r] = row:sub(1, c1 - 1) .. ('.'):rep(c2 - c1 + 1)
                .. row:sub(c2 + 1)
        end
    end
end

local body = {
    -- coroa e aba em perfil: aba estica à frente (rosto à direita)
    [9]  = '..............................kkkkkkkkk',
    [10] = '.............................kHHHHHHHHHk',
    [11] = '.............................kHHHHHHHHHk',
    [12] = '.............................kHHHHHHHHHk',
    [13] = '.............................kDDDDDDDDDk',
    [14] = '........................kkkkkkkkkkkkkkkkkkkkk',
    [15] = '.......................kSSSSSSSSSSSSSSSSSSSSSk',
    [16] = '......................kSSSSSSSSSSSSSSSSSSSSSSSk',
    [17] = '.......................kDDDDDDDDDDDDDDDDDDDDDk',
    -- cabeça em perfil: cabelo atrás 'h', rosto à direita, nariz 1px
    [18] = '.............................khhddddddk',
    [19] = '.............................khhddsssdk',
    [20] = '.............................khssssssssk',
    [21] = '.............................khsssssessk',
    [22] = '.............................khssssssssk',
    [23] = '.............................khsssssssssk',
    [24] = '.............................khssssssdsk',
    [25] = '.............................khssssssssk',
    [26] = '.............................ksssssssk',
    [27] = '..............................ksssssk',
    [28] = '..............................ksssssk',
    [29] = '..............................ksssssk',
    [30] = '..............................ksssssk',
    [31] = '.............................kksssssk',
    -- tronco em perfil: camisa atrás, colete cobre a frente
    [32] = '...........................kkmmmmmmmkk',
    [33] = '..........................kmmmmmmmmmmmk',
    [34] = '.........................kmmmmmmmmmmmmmmk',
    [35] = '........................kmmmmmmmmmmmmmmmmk',
    [36] = '.......................kmmqmmmmmmmmmmmmmmmk',
    [37] = '......................kmmqmmmmmmmmmmmvvvvvmk',
    [38] = '.....................kmmqmmmmmmmmmmvvvvvvvk',
    [39] = '....................kmmqmmmmmmmmmmvvvvvvvvk',
    [40] = '...................kmmqmmmmmmmmmmvvvvvvvvvk',
    [41] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [42] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [43] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [44] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [45] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [46] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [47] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [48] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [49] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [50] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [51] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    [52] = '...................kmqmmmmmmmmmmvvvvvvvvvvk',
    -- braço de trás em sombra 'd'; braço da frente arregaçado segura
    -- o cabo (a camada tool passa por cima da mão)
    [53] = '..................kddkmmmmmmmmmmvvvvvvvvvkqqk',
    [54] = '..................kddkmmmmmmmmmmvvvvvvvvvkssk',
    [55] = '..................kddkmmmmmmmmmmvvvvvvvvvkssk',
    [56] = '..................kddkmmmmmmmmmmvvvvvvvvvkssk',
    [57] = '..................kddkmmmmmmmmmmvvvvvvvvvkssk',
    [58] = '..................kddkmmmmmmmmmmvvvvvvvvkssssk',
    [59] = '..................kddkkmmmmmmmmmmvvvvvvvkssssk',
    [60] = '..................kddk.kpppppppppppppppkssssk',
    [61] = '..................kkkk..kpppppppppppppppkkkk',
    [62] = '.........................krrrrrrrrrrrrrrk',
    [63] = '.........................kPPPkppppppppk',
    [64] = '.........................kPPPkppppppppk',
    [65] = '.........................kPPPkppppppppk',
    [66] = '.........................kPPPkppppppppk',
    [67] = '.........................kPPPkppppppppk',
    [68] = '.........................kPPPkppppppppk',
    [69] = '.........................kPPPkppppppppk',
    [70] = '.........................kPPPkppppppppk',
    [71] = '.........................kPPPkppppppppk',
    [72] = '.........................kPPPkppppppppk',
    [73] = '.........................kPPPkppppppppk',
    [74] = '.........................kPPPkppppppppk',
    [75] = '.........................kPPPkppppppppk',
    [76] = '.........................kPPPkppppppppk',
    [77] = '.........................kPPPkppppppppk',
    [78] = '.........................kPPPkppppppppk',
    [79] = '.........................kPPPkppppppppk',
    [80] = '.........................kPPPkppppppppk',
    [81] = '.........................kPPPkppppppppk',
    [82] = '.........................kPPPkppppppppk',
    [83] = '.........................kPPPkppppppppk',
    [84] = '.........................kPPPkppppppppk',
    [85] = '.........................kPPPkppppppppk',
    -- botas: ponta à direita (perto 'b' na frente, longe 'B' atrás)
    [86] = '.........................kBBBkbbbbbbbbk',
    [87] = '.........................kBBBkbbbbbbbbk',
    [88] = '.........................kBBBkbbbbbbbbbk',
    [89] = '.........................kBBBkbbbbbbbbbk',
    [90] = '.........................kBBBkbbbbbbbbbbk',
    [91] = '.........................kBBBkbbbbbbbbbbk',
    [92] = '.........................kBBBkbbbbbbbbbbk',
    [93] = '.........................kooookbbbbbbbBok',
    [94] = '.........................kkkkkkkkkkkkkkkkk',
}

-- enxada na mão da frente, lâmina rente ao chão apontando para a rua
local tool = {
    [46] = '............................................kwk',
    [47] = '............................................kwk',
    [48] = '............................................kWk',
    [49] = '............................................kwk',
    [50] = '............................................kwk',
    [51] = '............................................kwk',
    [52] = '............................................kwk',
    [53] = '............................................kwk',
    [54] = '............................................kwk',
    [55] = '............................................kwk',
    [56] = '............................................kwk',
    [57] = '............................................kwk',
    [58] = '............................................kwk',
    [59] = '............................................kwk',
    [60] = '............................................kwk',
    [61] = '............................................kwk',
    [62] = '............................................kwk',
    [63] = '............................................kwk',
    [64] = '............................................kwk',
    [65] = '............................................kwk',
    [66] = '............................................kwk',
    [67] = '............................................kwk',
    [68] = '............................................kwk',
    [69] = '............................................kwk',
    [70] = '............................................kwk',
    [71] = '............................................kwk',
    [72] = '............................................kwk',
    [73] = '............................................kwk',
    [74] = '............................................kwk',
    [75] = '............................................kwk',
    [76] = '............................................kwk',
    [77] = '............................................kwk',
    [78] = '............................................kwk',
    [79] = '............................................kwk',
    [80] = '............................................kwk',
    [81] = '............................................kwk',
    [82] = '............................................kwk',
    [83] = '............................................kwk',
    [84] = '............................................kwk',
    [85] = '...........................................kkwk',
    [86] = '........................................kKKKkwk',
    [87] = '........................................kKKKKKkk',
    [88] = '........................................kiiiiik',
    [89] = '........................................kkkkkk',
}

-- f3: olha o canteiro — chapéu+cabeça descem 1px.
local gesto = shift(body, 1, 9, 30)

-- f4: respiro + braço da frente dobra para cima até a aba do chapéu.
-- Antebraço 's' vertical à frente do peito, manga 'm' no ombro; o
-- antebraço pendurado sai e a frente do tronco segue em colete 'v'.
local bracoChapeu = shift(body, 1, 32, 59)
for r = 18, 38 do put(bracoChapeu, r, 45, 'kssk') end
put(bracoChapeu, 15, 45, 'kssk')
put(bracoChapeu, 16, 44, 'kssssk')
put(bracoChapeu, 17, 45, 'kssk')
for r = 39, 45 do put(bracoChapeu, r, 42, 'kmmk') end
for r = 46, 53 do put(bracoChapeu, r, 43, 'vvk') end
blank(bracoChapeu, 54, 57, 42, 45)
blank(bracoChapeu, 58, 60, 41, 46)
blank(bracoChapeu, 61, 62, 41, 45)
for r = 54, 57 do put(bracoChapeu, r, 42, 'vvk') end
for r = 58, 60 do put(bracoChapeu, r, 41, 'vvvvk') end

-- f2: respiro — tórax desce 1px.
local respiro = shift(body, 1, 32, 59)

return {
    name = 'npc_jardineiro_e',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},
        d = {ramp = 'skin', step = 2, h = 10},
        h = {ramp = 'hair', step = 3, h = 11},
        e = {spec = 'ink', h = 12},
        H = {ramp = 'gold', step = 4, h = 12},
        S = {ramp = 'gold', step = 6, h = 12},
        D = {ramp = 'gold', step = 2, h = 11},
        m = {ramp = 'moss', step = 3, h = 6},
        q = {ramp = 'moss', step = 2, h = 5},
        v = {ramp = 'earth', step = 4, h = 6},
        r = {ramp = 'earth', step = 2, h = 5},
        p = {ramp = 'earth', step = 3, h = 4},
        P = {ramp = 'earth', step = 2, h = 3},
        b = {ramp = 'earth', step = 2, h = 2},
        B = {ramp = 'earth', step = 4, h = 3},
        o = {ramp = 'earth', step = 5, h = 2},
        w = {ramp = 'wood', step = 4, h = 7},
        W = {ramp = 'wood', step = 5, h = 7},
        K = {ramp = 'iron', step = 3, h = 6},
        i = {ramp = 'iron', step = 5, h = 6},
    },

    anchors = {
        pe = {32, 94},
        cabeca = {36, 21},
        ferramenta = {45, 56},
    },
    sequences = { idle = {1, 4, loop = true} },
    frameDuration = {0.4, 0.3, 0.5, 0.3},

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body), R(respiro), R(gesto), R(bracoChapeu),
        }},
        {name = 'tool', h = 7, albedo = {R(tool), R(tool), R(tool), R(tool)}},
    },
}
