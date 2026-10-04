-- NILO — TRABALHO 'tinker' (ajustando a peça na bancada), SUL,
-- 64x96, origem nos pés, 4f. Deriva do idle npc_nilo_s: mesma
-- silhueta e âncoras, mas corcunda — cabeça baixa 2px sobre a
-- bancada — e as duas mãos trabalham na peça 'W' deitada à cintura
-- (camada gear, 2 posições de ajuste em f1/f3 e f2/f4). O tórax
-- pressiona 1px em f2/f4 = força do ajuste.

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
-- BODY: corpo do idle sul; cabeça+rosto baixam 2px (corcunda sobre a
-- bancada), mangas descem à cintura e o instrumento sai da lateral —
-- a peça agora está na frente, na camada gear.
--------------------------------------------------------------------------------
local base = {
    [6]  = '..............................kk',
    [7]  = '.............................khhk',
    [8]  = '.............................khhk',
    [9]  = '............................khhhk',
    [10] = '..........................kkhhhhhhkk',
    [11] = '.........................khhhhhhhhhhk',
    [12] = '........................khhhhhhhhhhhhk',
    [13] = '........................khhhHhhhhHhhhk',
    [14] = '.......................khhhhhhhhhhhhhhk',
    [15] = '.......................khhhhhhhhhhhhhhk',
    [16] = '.......................khhsssssssssshhk',
    [17] = '.......................khsssssssssssshk',
    [18] = '.......................khseessssseeshk',
    [19] = '.......................khsssssssssssshk',
    [20] = '........................kssssdssssssk',
    [21] = '........................ksssssssssssk',
    [22] = '........................ksssssddssssk',
    [23] = '........................khsssssssssshk',
    [24] = '.........................kssssssssssk',
    [25] = '.........................kssssssssk',
    [26] = '..........................kssssssk',
    [27] = '..........................kssssk',
    [28] = '...........................kyyyyyk',
    [29] = '.........................kyyyyyyyyyyk',
    [30] = '........................kyyyyyyyyyyyyk',
    [31] = '........................kyvvyyyyyyyyvvyk',
    [32] = '.......................kyyvvyyyyyyyyvvyyk',
    [33] = '.......................kyvvyyyyyyyyyyvvyk',
    [34] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [35] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [36] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [37] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [38] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [39] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [40] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [41] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [42] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [43] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [44] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [45] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [46] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [47] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [48] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [49] = '..................kyyk.yvvvyyyyyyyyvvvy.kyyk',
    [50] = '..................kyyk.kyvvvvvvvvvvvvyk.kyyk',
    [51] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [52] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [53] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [54] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    -- mangas descem à cintura; as mãos estão na peça (camada gear)
    [55] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [56] = '..................kyyk.krrrrrrrrrrrrrrrk.kyyk',
    [57] = '..................kyyk.kpppppppppppppppk.kyyk',
    [58] = '..................kyyk.kpppppppppppppppk.kyyk',
    [59] = '..................kkkk.kpppppppppppppppk.kkkk',
    [60] = '.........................kppppppk..kppppppk',
    [61] = '.........................kppppppk..kppppppk',
    [62] = '.........................kppppppk..kppppppk',
    [63] = '.........................kppppppk..kppppppk',
    [64] = '.........................kppppppk..kppppppk',
    [65] = '.........................kppppppk..kppppppk',
    [66] = '.........................kppppppk..kppppppk',
    [67] = '.........................kppppppk..kppppppk',
    [68] = '.........................kppppppk..kppppppk',
    [69] = '.........................kppppppk..kppppppk',
    [70] = '.........................kppppppk..kppppppk',
    [71] = '.........................kppppppk..kppppppk',
    [72] = '.........................kppppppk..kppppppk',
    [73] = '.........................kppppppk..kppppppk',
    [74] = '.........................kppppppk..kppppppk',
    [75] = '.........................kppppppk..kppppppk',
    [76] = '.........................kpppppk...kpppppk',
    [77] = '.........................kpppppk...kpppppk',
    [78] = '.........................kpppppk...kpppppk',
    [79] = '.........................kpppppk...kpppppk',
    [80] = '.........................kpppppk...kpppppk',
    [81] = '.........................kpppppk...kpppppk',
    [82] = '.........................kCCCCCk...kCCCCCk',
    [83] = '.........................kCCCCCk...kCCCCCk',
    [84] = '.........................kCCCCCk...kCCCCCk',
    [85] = '.........................kbbbbbk...kbbbbbk',
    [86] = '.........................kbbbbbk...kbbbbbk',
    [87] = '.........................kbbbbbk...kbbbbbk',
    [88] = '.........................kbbbbbk...kbbbbbk',
    [89] = '.........................kbbbbbk...kbbbbbk',
    [90] = '.........................kbbbbbk...kbbbbbk',
    [91] = '.........................kxxbbbk...kxxbbbk',
    [92] = '.........................kxxbbbk...kxxbbbk',
    [93] = '.........................kooooook..kooooook',
    [94] = '.........................kkkkkkk..kkkkkkk',
}

-- corcunda: cabeça desce 2px sobre a peça
local body = shift(base, 2, 6, 27)

--------------------------------------------------------------------------------
-- GEAR: a peça 'W' deitada na bancada à altura da cintura + as mãos
-- em 2 posições de ajuste. O bolso 'B' continua no colete.
--------------------------------------------------------------------------------
local bolso = {
    [50] = '...........................kBBBBBBBBBBk',
    [51] = '...........................kBbbbbbbbbBk',
    [52] = '...........................kBbbbbbbbbBk',
    [53] = '...........................kBbbbbbbbbBk',
    [54] = '...........................kBbbbbbbbbBk',
    [55] = '...........................kBBBBBBBBBBk',
}

local peca = {
    -- corpo do instrumento deitado sobre o colo/bancada
    [57] = '............................kWWWWWWWk',
    [58] = '............................kWWxWWWWk',
    [59] = '............................kWWWWWWWk',
    [60] = '.............................kkkkkkk',
}

-- posição A: mão esquerda firma a peça por cima, direita ajusta embaixo
-- ('kyyk' = antebraço contínuo da manga ao punho)
local maosA = {
    [55] = '.........................kssk',
    [56] = '.....................kyykkssk',
    [58] = '..................................ksskkyyk',
    [59] = '..................................kssk',
}
-- posição B: direita segura o topo, esquerda desce ajustando
local maosB = {
    [55] = '...................................ksskkyyk',
    [56] = '...................................kssk',
    [58] = '.....................kyykkssk',
    [59] = '.........................kssk',
}

local gearA = overlay(R(bolso), overlay(R(peca), R(maosA)))
local gearB = overlay(R(bolso), overlay(R(peca), R(maosB)))

return {
    name = 'npc_nilo_trabalho',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 5, h = 11},
        S = {ramp = 'skin', step = 6, h = 12},
        d = {ramp = 'skin', step = 4, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 2, h = 11},
        H = {ramp = 'hair', step = 4, h = 12},
        y = {ramp = 'gold', step = 5, h = 6},
        v = {ramp = 'sea', step = 3, h = 6},
        B = {ramp = 'bone', step = 5, h = 8},
        b = {ramp = 'earth', step = 2, h = 2},
        r = {ramp = 'earth', step = 2, h = 5},
        p = {ramp = 'earth', step = 3, h = 4},
        C = {ramp = 'earth', step = 5, h = 5},
        x = {ramp = 'hair', step = 1, h = 3},
        w = {ramp = 'wood', step = 4, h = 7},
        W = {ramp = 'wood', step = 5, h = 7},
        o = {ramp = 'earth', step = 4, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 30, 60)), -- pressiona o ajuste
            R(body),
            R(shift(body, 1, 30, 60)),
        }},
        {name = 'gear', h = 7, albedo = {
            gearA,
            gearB,
            gearA,
            gearB,
        }},
    },
}
