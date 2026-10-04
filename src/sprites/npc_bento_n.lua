-- BENTO — idle NORTE (de costas), 64x96, origem nos pés, 2f.
-- Costas: faixa 'F' continua em volta da cabeça (âncora horizontal
-- lida de qualquer ângulo), cabelo crespo abaixo dela; colete 'v'
-- fecha o dorso redondo com camisa 'g' nas bordas; o avental 'a'
-- vira painel traseiro mais estreito com tiras 'A' amarradas na
-- cintura; toalha 'T' e concha 'c' passam para a direita da tela
-- (mesmo lado do corpo).

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
    -- faixa de pano vista por trás; cabelo crespo cobre a nuca
    [12] = '............................kkkkkk',
    [13] = '.........................kkhhhhhhkk',
    [14] = '........................khhhhhhhhhhk',
    [15] = '........................kFFFFFFFFFFk',
    [16] = '........................kFFFFFFFFFFk',
    [17] = '........................khhhhhhhhhhk',
    [18] = '........................khhHhhhhhHhk',
    [19] = '........................khhhhhhhhhhk',
    [20] = '........................khhhhhhhhhhk',
    [21] = '........................khhhhhhhhhhk',
    [22] = '........................khhhhhhhhhhk',
    [23] = '.........................khhhhhhhhk',
    [24] = '.........................khhhhhhhhk',
    [25] = '..........................khhhhhhk',
    [26] = '..........................khhhhhhk',
    [27] = '...........................khhhhk',
    [28] = '...........................kssssk',
    [29] = '..........................kssssssk',
    [30] = '..........................kssssssk',
    [31] = '..........................kggggggggggk',
    [32] = '........................kggggggggggggk',
    [33] = '.......................kggggggggggggggk',
    [34] = '......................kggggggggggggggggk',
    [35] = '.....................kggggvvvvvvvvvvggggk',
    [36] = '....................kggggvvvvvvvvvvvvggggk',
    [37] = '...................kggggvvvvvvvvvvvvvvggggk',
    [38] = '..................kggggvvvvvvvvvvvvvvvggggk',
    [39] = '.................kggggvvvvvvvvvvvvvvvvvggggk',
    [40] = '................kggggvvvvvvvvvvvvvvvvvvggggk',
    [41] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [42] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [43] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [44] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [45] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [46] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [47] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [48] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [49] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [50] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [51] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [52] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [53] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [54] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [55] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [56] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [57] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [58] = '.........ksssk..kgggvvvvvvvvvvvvvvvvvvvvvvgggk..ksssk',
    [59] = '.........ksssk..kgggvvvvvvvvvvvvvvvvvvvvvvgggk..ksssk',
    [60] = '.........kcck...kgggvvvvvvvvvvvvvvvvvvvvvvgggk..ksssk',
    [61] = '.........kcck....kggppppppppppppppppppppppggk...ksssk',
    [62] = '..........kck....kppppppppppppppppppppppppk....ksssk',
    [63] = '..........kkk....kppppppppppppppppppppppppk....kkkkk',
    [64] = '..................kppppppppppppppppppppppppk',
    [65] = '..................kppppppppppppppppppppppk',
    [66] = '....................kppppppk.....kppppppk',
    [67] = '....................kppppppk.....kppppppk',
    [68] = '....................kppppppk.....kppppppk',
    [69] = '....................kppppppk.....kppppppk',
    [70] = '....................kppppppk.....kppppppk',
    [71] = '....................kppppppk.....kppppppk',
    [72] = '....................kppppppk.....kppppppk',
    [73] = '....................kppppppk.....kppppppk',
    [74] = '....................kppppppk.....kppppppk',
    [75] = '....................kppppppk.....kppppppk',
    [76] = '....................kppppppk.....kppppppk',
    [77] = '....................kppppppk.....kppppppk',
    [78] = '....................kppppppk.....kppppppk',
    [79] = '....................kppppppk.....kppppppk',
    [80] = '....................kppppppk.....kppppppk',
    [81] = '....................kppppppk.....kppppppk',
    [82] = '....................kppppppk.....kppppppk',
    [83] = '...................kbbbbbbk.....kbbbbbbk',
    [84] = '...................kbbbbbbk.....kbbbbbbk',
    [85] = '...................kbbbbbbk.....kbbbbbbk',
    [86] = '...................kbbbbbbk.....kbbbbbbk',
    [87] = '...................kbbbbbbk.....kbbbbbbk',
    [88] = '...................kbbbbbbk.....kbbbbbbk',
    [89] = '...................kbbbbbbk.....kbbbbbbk',
    [90] = '...................kbbbbbbk.....kbbbbbbk',
    [91] = '..................kbbbbbbbbk...kbbbbbbbbk',
    [92] = '..................kbbbbbbbbk...kbbbbbbbbk',
    [93] = '..................kooooooook..kooooooook',
    [94] = '..................kkkkkkkkkk..kkkkkkkkkk',
}

-- painel traseiro do avental + tiras 'A' amarradas na cintura
local apron = {
    [46] = '........................kAAAAAAAAAAAAk',
    [47] = '........................kaaaaaaaaaaaak',
    [48] = '........................kaaaaaaaaaaaak',
    [49] = '........................kaaaaaaaaaaaak',
    [50] = '........................kaaaaaaaaaaaak',
    [51] = '........................kaaaaaaaaaaaak',
    [52] = '........................kaaaaaaaaaaaak',
    [53] = '........................kaaaaaaaaaaaak',
    [54] = '........................kaaaaaaaaaaaak',
    [55] = '........................kaaaaaaaaaaaak',
    [56] = '........................kAAAAAAAAAAAAk',
    [57] = '............................kAAk',
    [58] = '........................kaaaaaaaaaaaak',
    [59] = '........................kaaaaaaaaaaaak',
    [60] = '........................kaaaaaaaaaaaak',
    [61] = '........................kaaaaaaaaaaaak',
    [62] = '........................kaaaaaaaaaaaak',
    [63] = '........................kaaaaaaaaaaaak',
    [64] = '........................kaaaaaaaaaaaak',
    [65] = '........................kaaaaaaaaaaaak',
    [66] = '........................kaaaaaaaaaaaak',
    [67] = '........................kaaaaaaaaaaaak',
    [68] = '........................kaaaaaaaaaaaak',
    [69] = '........................kaaaaaaaaaaaak',
    [70] = '........................kaaaaaaaaaaaak',
    [71] = '........................kaaaaaaaaaaaak',
    [72] = '........................kaaaaaaaaaaaak',
    [73] = '........................kAAAAAAAAAAAAk',
}

-- toalha agora na direita da tela (mesmo ombro do corpo)
local towel = {
    [32] = '............................................kTTk',
    [33] = '............................................kTTk',
    [34] = '............................................kTtk',
    [35] = '............................................kTTk',
    [36] = '............................................kTTk',
    [37] = '............................................kTtk',
    [38] = '............................................kTTk',
    [39] = '............................................kTTk',
    [40] = '............................................kTtk',
    [41] = '............................................kTTk',
    [42] = '............................................kTTk',
    [43] = '............................................kTtk',
    [44] = '............................................kTTk',
    [45] = '............................................kTTk',
    [46] = '............................................kTtk',
    [47] = '............................................kTTk',
    [48] = '............................................kTTk',
    [49] = '............................................kTtk',
    [50] = '............................................kTTk',
    [51] = '............................................kTTk',
    [52] = '............................................kTtk',
    [53] = '............................................kTTk',
    [54] = '............................................kTTk',
    [55] = '............................................kTtk',
    [56] = '............................................kTTk',
    [57] = '............................................kTTk',
    [58] = '............................................kTtk',
    [59] = '............................................kTTk',
    [60] = '............................................kttk',
    [61] = '.............................................kk',
}

local garb = overlay(R(apron), R(towel))

return {
    name = 'npc_bento_n',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},
        S = {ramp = 'skin', step = 4, h = 12},
        d = {ramp = 'skin', step = 2, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 3, h = 11},
        H = {ramp = 'hair', step = 4, h = 12},
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
        c = {ramp = 'wood', step = 5, h = 7},
        b = {ramp = 'wood', step = 3, h = 2},
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
