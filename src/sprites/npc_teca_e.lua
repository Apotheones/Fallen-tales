-- TECA — idle LESTE (perfil olhando para a direita), 64x96, 2f.
-- npc_teca_w = espelho via código.
-- Perfil: cabelo 'h' na metade de trás com o nó baixo espremido
-- atrás da nuca (à esquerda); rosto comprido à direita, nariz de
-- dorso reto; xale 'x' no ombro com ponta caindo na frente da
-- cintura; vestido 'w' em triângulo de perfil; sobressaia 'o' sobre
-- o quadril. Sem braço separado lendo — mangas finas na frente.

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
    [14] = '.............................kkkkk',
    [15] = '...........................khhhhhhk',
    [16] = '..........................khhhhhhhhk',
    [17] = '..........................khhGhhhhhhk',
    [18] = '..........................khhhhhhhhhk',
    [19] = '..........................khhhssssssk',
    -- nó baixo espremido atrás da nuca (esq.)
    [20] = '......................khhk.hhssssssk',
    [21] = '.....................khhhkhssssssesk',
    [22] = '.....................khhGkhssssssssk',
    [23] = '.....................khhhkhsssdssssk',
    [24] = '......................khhkhsssddsssk',
    [25] = '.......................kkhssssssssk',
    [26] = '..........................kssssssssk',
    [27] = '..........................kssssssk',
    [28] = '...........................kssssk',
    [29] = '............................ksssk',
    -- tronco estreito; saia alarga do quadril à barra
    [30] = '...........................kwwwwk',
    [31] = '..........................kwwwwwwk',
    [32] = '.........................kwwwwwwwwk',
    [33] = '........................kwwwwwwwwwk',
    [34] = '........................kwwwwwwwwwwk',
    [35] = '.......................kwwwwwwwwwwwk',
    [36] = '.......................kwwwwwwwwwwwk',
    [37] = '.......................kwwwwwwwwwwwk',
    [38] = '.......................kwwwwwwwwwwwk',
    [39] = '.......................kwwwwwwwwwwwk',
    [40] = '.......................kwwwwwwwwwwwk',
    [41] = '.......................kwwwwwwwwwwwk',
    [42] = '.......................kwwwwwwwwwwwk',
    [43] = '.......................kwwwwwwwwwwwk',
    [44] = '.......................kwwwwwwwwwwwk',
    [45] = '.......................kwwwwwwwwwwwk',
    [46] = '.......................kwwwwwwwwwwwk',
    [47] = '.......................kwwwwwwwwwwwk',
    [48] = '.......................kwwwwwwwwwwwk',
    [49] = '.......................kwwwwwwwwwwwk',
    [50] = '.......................kwwwwwwwwwwwk',
    [51] = '.......................kwwwwwwwwwwwk',
    [52] = '.......................kwwwwwwwwwwwk',
    [53] = '.......................kwwwwwwwwwwwk',
    [54] = '.......................kwwwwwwwwwwwk',
    [55] = '.......................kwwwwwwwwwwwk',
    [56] = '.......................kllwwwwwwwwwwk',   -- punho de linho à frente
    [57] = '.......................kllwwwwwwwwwwwk',
    [58] = '.......................ksskwwwwwwwwwwk',
    [59] = '.......................ksskwwwwwwwwwwwk',
    [60] = '.......................kkkkwwwwwwwwwwwk',
    [61] = '........................kwwwwwwwwwwwwk',
    [62] = '........................kwwwwwwwwwwwwk',
    [63] = '........................kwwwwwwwwwwwwk',
    [64] = '........................kwwwwwwwwwwwwk',
    [65] = '.......................kwwwwwwwwwwwwwwk',
    [66] = '.......................kwwwwwwwwwwwwwwk',
    [67] = '.......................kwwwwwwwwwwwwwwk',
    [68] = '.......................kwwwwwwwwwwwwwwk',
    [69] = '......................kwwwwwwwwwwwwwwwwk',
    [70] = '......................kwwwwwwwwwwwwwwwwk',
    [71] = '......................kwwwwwwwwwwwwwwwwk',
    [72] = '......................kwwwwwwwwwwwwwwwwk',
    [73] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [74] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [75] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [76] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [77] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [78] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [79] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [80] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [81] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [82] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [83] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [84] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [85] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [86] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [87] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [88] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [89] = '..................kWWWWWWWWWWWWWWWWWWWWWWk',
    [90] = '..................kkkkkkkkkkkkkkkkkkkkkkkkk',
    [91] = '...........................kbbkkbbk',
    [92] = '...........................kbbkkbbk',
    [93] = '...........................kbbkkbbk',
    [94] = '...........................kkkkkkkk',
}

local overskirt = {
    [52] = '.......................koooooooooooook',
    [53] = '.......................koooooooooooook',
    [54] = '.......................koooooooooooook',
    [55] = '.......................koooooooooooook',
    [56] = '........................koooooooooooook',
    [57] = '........................koooooooooooook',
    [58] = '........................koooooooooooook',
    [59] = '........................koooooooooooook',
    [60] = '........................koooooooooooook',
    [61] = '........................kooooooooooooook',
    [62] = '........................kooooooooooooook',
    [63] = '........................kooooooooooooook',
    [64] = '........................kooooooooooooook',
    [65] = '.......................koooooooooooooook',
    [66] = '.......................koooooooooooooook',
    [67] = '.......................koooooooooooooook',
    [68] = '.......................koooooooooooooook',
    [69] = '......................kooooooooooooooook',
    [70] = '......................kooooooooooooooook',
    [71] = '......................kooooooooooooooook',
    [72] = '......................kOOOOOOOOOOOOOOOk',
}

local xale = {
    [33] = '........................kxxxxxxxxxk',
    [34] = '.......................kxxxxxxxxxxxk',
    [35] = '.......................kxxxkwwwwxxxk',
    [36] = '.......................kxxkwwwwwwxxk',
    [37] = '.......................kxxkwwwwwwxxk',
    [38] = '........................kxkwwwwwwkxk',
    -- ponta presa na cintura, na frente (direita)
    [50] = '....................................kxxk',
    [51] = '....................................kxxk',
    [52] = '....................................kxxk',
    [53] = '....................................kxxk',
    [54] = '....................................kxxk',
    [55] = '.....................................kxk',
    [56] = '.....................................kxk',
    [57] = '......................................kk',
}

local garb = overlay(R(overskirt), R(xale))

return {
    name = 'npc_teca_e',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 4, h = 11},
        S = {ramp = 'skin', step = 5, h = 12},
        d = {ramp = 'skin', step = 3, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 2, h = 11},
        G = {ramp = 'iron', step = 5, h = 12},
        w = {ramp = 'sea', step = 3, h = 5},
        W = {ramp = 'sea', step = 2, h = 4},
        l = {ramp = 'plaster', step = 5, h = 6},
        o = {ramp = 'clothWarm', step = 3, h = 6},
        O = {ramp = 'clothWarm', step = 2, h = 6},
        x = {ramp = 'plaster', step = 5, h = 7},
        b = {ramp = 'earth', step = 2, h = 2},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 55)),
        }},
        {name = 'garb', h = 6, albedo = {garb, garb}},
    },
}
