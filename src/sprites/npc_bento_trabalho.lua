-- BENTO — TRABALHO 'stir' (mexendo a panela), SUL, 64x96, origem nos
-- pés, 4f. Deriva do idle npc_bento_s: mesma silhueta e âncoras,
-- mas a cabeça baixa 1px sobre a panela, os braços dobram para a
-- frente e a concha descreve um círculo simplificado em 2 posições
-- (f1/f3 posição A, f2/f4 posição B). O tórax desce 1px em f2/f4 =
-- o empurrão do mexer. Vapor 'q' sobe da panela, abaixo do quadro.

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
local function patch(map, rows)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(rows) do t[r] = s end
    return t
end

--------------------------------------------------------------------------------
-- BODY: o mesmo corpo do idle sul, com cabeça 1px mais baixa sobre a
-- panela e mãos recolhidas (o trabalho acontece na camada 'act').
--------------------------------------------------------------------------------
local base = {
    [12] = '............................kkkkkk',
    [13] = '.........................kkhhhhhhkk',
    [14] = '........................khhhhhhhhhhk',
    [15] = '........................kFFFFFFFFFFk',
    [16] = '........................kFFFFFFFFFFk',
    [17] = '........................kssssssssssk',
    [18] = '........................kssssssssssk',
    [19] = '........................kssssssssssk',
    [20] = '........................kseessssseesk',
    [21] = '........................kssssssssssk',
    [22] = '........................ksssdddssssk',
    [23] = '........................ksssdddssssk',
    [24] = '........................kssssssssssk',
    [25] = '........................ksuuuuuuuusk',
    [26] = '........................ksssddsssssk',
    [27] = '........................kssssssssssk',
    [28] = '.........................kssssssssk',
    [29] = '.........................kssssssssk',
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
    -- cotovelos dobram para dentro: as mãos saem do quadro para a panela
    [58] = '...........kggk.kgggvvvvvvvvvvvvvvvvvvvvvvgggk.kggk',
    [59] = '...........kggk.kgggvvvvvvvvvvvvvvvvvvvvvvgggk.kggk',
    [60] = '...........kggk.kgggvvvvvvvvvvvvvvvvvvvvvvgggk.kggk',
    [61] = '...........kkkk..kggppppppppppppppppppppppggk..kkkk',
    [62] = '.................kppppppppppppppppppppppppk',
    [63] = '.................kppppppppppppppppppppppppk',
    [64] = '.................kppppppppppppppppppppppppk',
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

-- cabeça 1px mais baixa: corcunda sobre a panela
local body = shift(base, 1, 12, 30)

--------------------------------------------------------------------------------
-- GARB: avental quadrado + toalha no ombro, iguais ao idle (estáticos
-- por baixo das mãos da camada 'act').
--------------------------------------------------------------------------------
local apron = {
    [40] = '......................kAAAAAAAAAAAAAAAAk',
    [41] = '......................kaaaaaaaaaaaaaaaak',
    [42] = '......................kaaaaaaaaaaaaaaaak',
    [43] = '......................kaaaaaaaaaaaaaaaak',
    [44] = '......................kaaaaaaaaaaaaaaaak',
    [45] = '......................kaaaaaaaaaaaaaaaak',
    [46] = '......................kaaaaaaaaaaaaaaaak',
    [47] = '......................kaaaaaaaaaaaaaaaak',
    [48] = '......................kaaaaaaaaaaaaaaaak',
    [49] = '......................kaaaaaaaaaaaaaaaak',
    [50] = '......................kaaaaaaaaaaaaaaaak',
    [51] = '......................kaaaaaaaaaaaaaaaak',
    [52] = '......................kaaaaaaaaaaaaaaaak',
    [53] = '......................kaaaaaaaaaaaaaaaak',
    [54] = '......................kaaaaaaaaaaaaaaaak',
    [55] = '......................kaaaaaaaaaaaaaaaak',
    [56] = '......................kaaaaaaaaaaaaaaaak',
    [57] = '......................kaaaaaaaaaaaaaaaak',
    [58] = '......................kaaaaaaaaaaaaaaaak',
    [59] = '......................kaaaaaaaaaaaaaaaak',
    [60] = '......................kaaaaaaaaaaaaaaaak',
    [61] = '......................kaaaaaaaaaaaaaaaak',
    [62] = '......................kaaaaaaaaaaaaaaaak',
    [63] = '......................kaaaaaaaaaaaaaaaak',
    [64] = '......................kaaaaaaaaaaaaaaaak',
    [65] = '......................kaaaaaaaaaaaaaaaak',
    [66] = '......................kaaaaaaaaaaaaaaaak',
    [67] = '......................kaaaaaaaaaaaaaaaak',
    [68] = '......................kaaaaaaaaaaaaaaaak',
    [69] = '......................kaaaaaaaaaaaaaaaak',
    [70] = '......................kaaaaaaaaaaaaaaaak',
    [71] = '......................kaaaaaaaaaaaaaaaak',
    [72] = '......................kaaaaaaaaaaaaaaaak',
    [73] = '......................kAAAAAAAAAAAAAAAAk',
}

local towel = {
    [32] = '..............kTTk',
    [33] = '..............kTTk',
    [34] = '..............kTtk',
    [35] = '..............kTTk',
    [36] = '..............kTTk',
    [37] = '..............kTtk',
    [38] = '..............kTTk',
    [39] = '..............kTTk',
    [40] = '..............kTtk',
    [41] = '..............kTTk',
    [42] = '..............kTTk',
    [43] = '..............kTtk',
    [44] = '..............kTTk',
    [45] = '..............kTTk',
    [46] = '..............kTtk',
    [47] = '..............kTTk',
    [48] = '..............kTTk',
    [49] = '..............kTtk',
    [50] = '..............kTTk',
    [51] = '..............kTTk',
    [52] = '..............kTtk',
    [53] = '..............kTTk',
    [54] = '..............kTTk',
    [55] = '..............kTtk',
    [56] = '..............kTTk',
    [57] = '..............kTTk',
    [58] = '..............kTtk',
    [59] = '..............kTTk',
    [60] = '..............kttk',
    [61] = '...............kk',
}

local garb = overlay(R(apron), R(towel))

--------------------------------------------------------------------------------
-- ACT: o mexer em si — mão esquerda firme segurando a panela (fora do
-- quadro), direita descreve o círculo com a concha em 2 posições:
-- A = concha mergulhando à esquerda, B = à direita. Vapor 'q' sobe.
--------------------------------------------------------------------------------
local actA = {
    -- mão esquerda firme na borda da panela; concha mergulha à esquerda
    [51] = '............................kssk',
    [52] = '............................kssk',
    [53] = '.............................kck',
    [54] = '............................kcck',
    [55] = '........................kssk.kcck',
    [56] = '........................kssk',
    -- vapor subindo da panela
    [45] = '..............................q',
    [47] = '............................q',
}
local actB = {
    -- concha varre para a direita (segunda metade do círculo)
    [51] = '...................................kssk',
    [52] = '...................................kssk',
    [53] = '....................................kck',
    [54] = '....................................kcck',
    [55] = '........................kssk.....kcck',
    [56] = '........................kssk',
    [44] = '.................................q',
    [46] = '..............................q',
}

return {
    name = 'npc_bento_trabalho',
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
        c = {ramp = 'wood', step = 5, h = 7},
        q = {ramp = 'plaster', step = 6, h = 8},  -- vapor da panela
        b = {ramp = 'wood', step = 3, h = 2},
        o = {ramp = 'wood', step = 5, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 60)), -- empurrão do mexer: tórax desce
            R(body),
            R(shift(body, 1, 31, 60)),
        }},
        {name = 'garb', h = 7, albedo = {garb, garb, garb, garb}},
        {name = 'act', h = 8, albedo = {
            R(actA),
            R(actB),
            R(actA),
            R(actB),
        }},
    },
}
