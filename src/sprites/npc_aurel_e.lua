-- AUREL — idle LESTE (perfil olhando para a direita), 64x96, 2f.
-- npc_aurel_w = espelho via código.
-- Perfil: cabelo grisalho varrido para a nuca (metade de trás da
-- cabeça é 'g'), rosto longo à direita com nariz reto saindo 1px;
-- orelha grande 'd' no meio da massa. Gola 'z' sobe o pescoço; a
-- túnica 't' domina a frente, sobrecasaca 'c' cobre as costas;
-- braço da frente com punho de couro segura o pano 'p'; braço de
-- trás em sombra 'd'. Perna longe 'D' atrás, perto 'b' na frente.

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

local body = {
    [8]  = '.............................kkkkk',
    [9]  = '............................kgggggk',
    [10] = '...........................kgggggggk',
    [11] = '..........................kgggGgggggk',
    [12] = '..........................kgggggggggk',
    [13] = '..........................kgggggggsgk',
    [14] = '..........................kggggggssgk',
    [15] = '..........................kggggssssssk',
    [16] = '..........................kggggssssssk',
    [17] = '..........................kgggdssssssk',  -- orelha 'd'
    [18] = '..........................kgggsssssek',   -- olho à frente
    [19] = '..........................kgggsssssssk',
    [20] = '..........................kgggsssssssk',
    [21] = '..........................kgggssssssssk', -- nariz reto sai à dir.
    [22] = '..........................kgggsssssssdk',
    [23] = '..........................kgggsssssssk',
    [24] = '..........................kgggssssdssk',
    [25] = '..........................kgggsssssssk',
    [26] = '..........................kggggsssssk',
    [27] = '...........................kgggssssk',
    [28] = '...........................kgggsssk',
    [29] = '............................ksssk',
    [30] = '............................kzzk',
    [31] = '............................kzzk',
    [32] = '............................kzzk',
    [33] = '............................kzzk',
    [34] = '...........................kzzttk',
    [35] = '...........................kzzttk',
    -- tronco estreito: sobrecasaca nas costas (esq.), túnica à frente
    [36] = '...........................kcccccccccccck',
    [37] = '..........................kcccccccccccccck',
    [38] = '..........................kccccttttttttcck',
    [39] = '..........................kccccttttttttcck',
    [40] = '.....................kcck.kccccttttttttcck.kcck',
    [41] = '.....................kcck.kccccttttttttcck.kcck',
    [42] = '.....................kcck.kccccttttttttcck.kcck',
    [43] = '.....................kcck.kccccttttttttcck.kcck',
    [44] = '.....................kcck.kccccttttttttcck.kcck',
    [45] = '.....................kcck.kccccttttttttcck.kcck',
    [46] = '.....................kcck.kccccttttttttcck.kcck',
    [47] = '.....................kcck.kccccttttttttcck.kcck',
    [48] = '.....................kcck.kccccttttttttcck.kcck',
    [49] = '.....................kcck.kccccttttttttcck.kcck',
    [50] = '.....................kcck.kccccttttttttcck.kcck',
    [51] = '.....................kcck.kccccttttttttcck.kcck',
    [52] = '.....................kcck.kccccttttttttcck.kcck',
    [53] = '.....................kcck.kccccttttttttcck.kcck',
    [54] = '.....................krrk.kccccttttttttcck.krrk',
    [55] = '.....................krrk.kccccttttttttcck.krrk',
    [56] = '.....................krrk.kccccttttttttcck.krrk',
    [57] = '.....................kddk.kccccttttttttcck.kssk',
    [58] = '.....................kddk.kccccttttttttcck.kssk',
    [59] = '.....................kddk.kccccttttttttcck.kssk',
    [60] = '.....................kddk.kccccttttttttcck.kppk',
    [61] = '.....................kkkk.kccccttttttttcck.kppk',
    [62] = '..........................kccccttttttttcck.kppk',
    [63] = '..........................kttttttttttttk..kppk',
    [64] = '..........................kttttttttttttk..kppk',
    [65] = '..........................kttttttttttttk...kk',
    [66] = '..........................kttttttttttttk',
    [67] = '..........................kttttttttttttk',
    [68] = '..........................kttttttttttttk',
    [69] = '..........................kttttttttttttk',
    [70] = '..........................kttttttttttttk',
    [71] = '..........................kttttttttttttk',
    [72] = '..........................kttttttttttttk',
    [73] = '..........................kttttttttttttk',
    [74] = '..........................kttttttttttttk',
    [75] = '..........................kttttttttttttk',
    [76] = '..........................kttttttttttttk',
    [77] = '..........................kttttttttttttk',
    [78] = '..........................kttttttttttttk',
    [79] = '..........................kttttttttttttk',
    [80] = '..........................kttttttttttttk',
    [81] = '..........................kttttttttttttk',
    -- pernas: longe 'D' atrás, perto 'b' com ponta à direita
    [82] = '..........................kDDbkbbbk',
    [83] = '..........................kDDbkbbbk',
    [84] = '..........................kDDbkbbbk',
    [85] = '..........................kDDbkbbbk',
    [86] = '..........................kDDbkbbbk',
    [87] = '..........................kDDbkbbbk',
    [88] = '..........................kDDbkbbbk',
    [89] = '..........................kDDbkbbbk',
    [90] = '..........................kDDbkbbbbk',
    [91] = '..........................kDDbkbbbbk',
    [92] = '..........................kDDbkbbbbk',
    [93] = '..........................kookkoooook',
    [94] = '..........................kkkkkkkkkkk',
}

local band = {
    [54] = '.............................kffffffffk',
    [55] = '.............................kffffffffk',
}

return {
    name = 'npc_aurel_e',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},
        S = {ramp = 'skin', step = 4, h = 12},
        d = {ramp = 'skin', step = 2, h = 10},
        e = {spec = 'ink', h = 12},
        g = {ramp = 'iron', step = 5, h = 11},
        G = {ramp = 'iron', step = 6, h = 12},
        z = {ramp = 'sea', step = 3, h = 9},
        c = {ramp = 'sea', step = 2, h = 7},
        t = {ramp = 'plaster', step = 4, h = 6},
        u = {ramp = 'plaster', step = 3, h = 5},
        f = {ramp = 'earth', step = 3, h = 8},
        r = {ramp = 'earth', step = 2, h = 6},
        p = {ramp = 'bone', step = 5, h = 7},
        b = {ramp = 'earth', step = 2, h = 2},
        B = {ramp = 'earth', step = 4, h = 3},
        D = {ramp = 'earth', step = 1, h = 2},
        o = {ramp = 'earth', step = 4, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 36, 56)),
        }},
        {name = 'trab', h = 8, albedo = {
            R(band),
            R(band),
        }},
    },
}
