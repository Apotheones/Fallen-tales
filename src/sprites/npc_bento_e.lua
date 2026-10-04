-- BENTO — idle LESTE (perfil olhando para a direita), 64x96, 2f.
-- npc_bento_w = espelho via código.
-- Perfil: a faixa 'F' corta a cabeça na horizontal (âncora segue
-- lendo); rosto redondo com nariz largo e bigode 'u' à frente; a
-- barriga projeta à direita e o avental 'a' veste a curva toda da
-- frente (âncora clara); toalha 'T' escorre pelas costas à esquerda;
-- concha 'c' na mão da frente. Perna longe 'P' atrás, perto 'p'.

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
local function overlay(ga, gb)
    local A, B, out = {}, {}, {}
    for l in ga:gmatch('[^\n]+') do A[#A + 1] = l end
    for l in gb:gmatch('[^\n]+') do B[#B + 1] = l end
    for i = 1, #A do
        local a, b, row = A[i], B[i] or '', {}
        for x = 1, 64 do
            local cb = b:sub(x, x)
            row[x] = (cb ~= '.' and cb ~= ' ' and cb ~= '') and cb
                or a:sub(x, x)
        end
        out[i] = table.concat(row)
    end
    return table.concat(out, '\n')
end

local body = {
    [12] = '.............................kkkkk',
    [13] = '..........................kkhhhhhkk',
    [14] = '.........................khhhhhhhhk',
    [15] = '.........................kFFFFFFFFk',
    [16] = '.........................kFFFFFFFFk',
    [17] = '.........................khhssssssk',
    [18] = '.........................khhssssssk',
    [19] = '.........................khsssssssk',
    [20] = '.........................khsssssesk',
    [21] = '.........................khssssssssk',   -- nariz largo
    [22] = '.........................khsssssddsk',
    [23] = '.........................khsssssssk',
    [24] = '.........................khsuuuussk',    -- bigode fino
    [25] = '.........................khsssddssk',
    [26] = '.........................khssssssssk',
    [27] = '..........................ksssssssk',
    [28] = '..........................kssssssk',
    [29] = '...........................kssssk',
    [30] = '............................ksssk',
    -- tronco: costas quase retas à esquerda, barriga projeta à dir.
    [31] = '...........................kgggggggk',
    [32] = '..........................kgggggggggk',
    [33] = '.........................kgggggggggggk',
    [34] = '........................kgggggggggggggk',
    [35] = '........................kgggvvvvvvvvgggk',
    [36] = '.......................kgggvvvvvvvvvvggk',
    [37] = '......................kgggvvvvvvvvvvvggk',
    [38] = '......................kggvvvvvvvvvvvvvgk',
    [39] = '.....................kggvvvvvvvvvvvvvvvggk',
    [40] = '.....................kgvvvvvvvvvvvvvvvvvgk',
    [41] = '....................kgvvvvvvvvvvvvvvvvvvvvgk',
    [42] = '....................kgvvvvvvvvvvvvvvvvvvvvgk',
    [43] = '....................kgvvvvvvvvvvvvvvvvvvvvgk',
    [44] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [45] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [46] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [47] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [48] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [49] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [50] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [51] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [52] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [53] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [54] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [55] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [56] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [57] = '.................kggk.gvvvvvvvvvvvvvvvvvvvgk.kggk',
    [58] = '.................kddk.gvvvvvvvvvvvvvvvvvvvgk.kssk',
    [59] = '.................kddk.kppppppppppppppppppppk.kssk',
    [60] = '.................kddk.kppppppppppppppppppppk.kcck',
    [61] = '.................kkkk.kppppppppppppppppppppk.kcck',
    [62] = '......................kppppppppppppppppppppk..kck',
    [63] = '......................kppppppppppppppppppppk...kk',
    [64] = '......................kPPPPkpppppppk',
    [65] = '......................kPPPPkpppppppk',
    [66] = '......................kPPPPkpppppppk',
    [67] = '......................kPPPPkpppppppk',
    [68] = '......................kPPPPkpppppppk',
    [69] = '......................kPPPPkpppppppk',
    [70] = '......................kPPPPkpppppppk',
    [71] = '......................kPPPPkpppppppk',
    [72] = '......................kPPPPkpppppppk',
    [73] = '......................kPPPPkpppppppk',
    [74] = '......................kPPPPkpppppppk',
    [75] = '......................kPPPPkpppppppk',
    [76] = '......................kPPPPkpppppppk',
    [77] = '......................kPPPPkpppppppk',
    [78] = '......................kPPPPkpppppppk',
    [79] = '......................kPPPPkpppppppk',
    [80] = '......................kPPPPkpppppppk',
    [81] = '......................kPPPPkpppppppk',
    [82] = '......................kPPPPkpppppppk',
    -- tamancos: longe 'D' atrás, perto 'b' com bico à direita
    [83] = '......................kDDkbbbbbbbk',
    [84] = '......................kDDkbbbbbbbk',
    [85] = '......................kDDkbbbbbbbk',
    [86] = '......................kDDkbbbbbbbk',
    [87] = '......................kDDkbbbbbbbk',
    [88] = '......................kDDkbbbbbbbk',
    [89] = '......................kDDkbbbbbbbk',
    [90] = '......................kDDkbbbbbbbbbbk',
    [91] = '......................kDDkbbbbbbbbbbk',
    [92] = '......................kDDkbbbbbbbbbbk',
    [93] = '......................kookooooooooook',
    [94] = '......................kkkkkkkkkkkkkkk',
}

-- avental veste toda a curva frontal da barriga + toalha pelas costas
local apron = {
    [42] = '...................................kAAAAAAAAk',
    [43] = '...................................kaaaaaaaak',
    [44] = '...................................kaaaaaaaak',
    [45] = '...................................kaaaaaaaak',
    [46] = '...................................kaaaaaaaak',
    [47] = '...................................kaaaaaaaak',
    [48] = '...................................kaaaaaaaak',
    [49] = '...................................kaaaaaaaak',
    [50] = '...................................kaaaaaaaak',
    [51] = '...................................kaaaaaaaak',
    [52] = '...................................kaaaaaaaak',
    [53] = '...................................kaaaaaaaak',
    [54] = '...................................kaaaaaaaak',
    [55] = '...................................kaaaaaaaak',
    [56] = '...................................kaaaaaaaak',
    [57] = '...................................kaaaaaaaak',
    [58] = '...................................kaaaaaaaak',
    [59] = '...................................kaaaaaaaak',
    [60] = '...................................kaaaaaaaak',
    [61] = '...................................kaaaaaaaak',
    [62] = '...................................kaaaaaaaak',
    [63] = '...................................kaaaaaaaak',
    [64] = '...................................kaaaaaaaak',
    [65] = '...................................kaaaaaaaak',
    [66] = '...................................kaaaaaaaak',
    [67] = '...................................kaaaaaaaak',
    [68] = '...................................kaaaaaaaak',
    [69] = '...................................kaaaaaaaak',
    [70] = '...................................kaaaaaaaak',
    [71] = '...................................kaaaaaaaak',
    [72] = '...................................kAAAAAAAAk',
}

local towel = {
    [33] = '..................kTTk',
    [34] = '.................kTTk',
    [35] = '.................kTtk',
    [36] = '................kTTk',
    [37] = '................kTTk',
    [38] = '................kTtk',
    [39] = '................kTTk',
    [40] = '................kTTk',
    [41] = '................kTtk',
    [42] = '................kTTk',
    [43] = '................kTTk',
    [44] = '................kTtk',
    [45] = '................kTTk',
    [46] = '................kTTk',
    [47] = '................kTtk',
    [48] = '................kTTk',
    [49] = '................kTTk',
    [50] = '................kTtk',
    [51] = '................kTTk',
    [52] = '................kTTk',
    [53] = '................kTtk',
    [54] = '................kTTk',
    [55] = '................kttk',
    [56] = '.................kk',
}

local garb = overlay(R(apron), R(towel))

return {
    name = 'npc_bento_e',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},
        S = {ramp = 'skin', step = 4, h = 12},
        d = {ramp = 'skin', step = 2, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 3, h = 11},
        F = {ramp = 'bone', step = 5, h = 12},
        u = {ramp = 'hair', step = 2, h = 11},
        g = {ramp = 'moss', step = 3, h = 6},
        G = {ramp = 'moss', step = 2, h = 6},
        v = {ramp = 'clothWarm', step = 2, h = 6},
        a = {ramp = 'bone', step = 4, h = 7},
        A = {ramp = 'bone', step = 3, h = 7},
        T = {ramp = 'plaster', step = 6, h = 7},
        t = {ramp = 'plaster', step = 4, h = 7},
        p = {ramp = 'earth', step = 3, h = 4},
        P = {ramp = 'earth', step = 2, h = 3},   -- perna de trás
        c = {ramp = 'wood', step = 5, h = 7},
        b = {ramp = 'wood', step = 3, h = 2},
        D = {ramp = 'earth', step = 1, h = 2},
        o = {ramp = 'wood', step = 5, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 57)),
        }},
        {name = 'garb', h = 7, albedo = {garb, garb}},
    },
}
