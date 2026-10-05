-- V11 NPC_AUREL_N — Aurel de costas (norte), 64x96 feet, 4f.
-- De costas: massa grisalha varrida sem testa alta, nuca 's', gola
-- alta 'z' vista como filete, costas do sobrecasaco 'c' fechadas,
-- túnica 't' com fenda traseira na barra, punhos 'r', faixa 'f'.
local function L(s)
    assert(#s <= 64, 'linha > 64')
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

local body = {
    -- nuca: massa de cabelo grisalho fechada, pontas soltas na nuca
    [8]  = '............................kgggkk',
    [9]  = '...........................kgggggggk',
    [10] = '..........................kgggggggggk',
    [11] = '..........................kggGgggggggk',
    [12] = '..........................kggggggggggk',
    [13] = '..........................kggggggggggk',
    [14] = '..........................kggggggggggk',
    [15] = '..........................kggggggggggk',
    [16] = '..........................kggggggggggk',
    [17] = '..........................kggggggggggk',
    [18] = '..........................kggggggggggk',
    [19] = '..........................kggggggggggk',
    [20] = '..........................kggggggggggk',
    [21] = '..........................kggggggggggk',
    [22] = '..........................kggggggggggk',
    [23] = '..........................kggggggggggk',
    [24] = '..........................kghggggggghk',
    [25] = '..........................ksssssssssk',
    [26] = '..........................kssssssssk',
    [27] = '...........................kssssssk',
    [28] = '...........................kssssssk',
    [29] = '............................kssssk',
    [30] = '............................kzzzzk',
    [31] = '............................kzzzzk',
    [32] = '............................kzzzzk',
    [33] = '............................kzzzzk',
    [34] = '...........................kzzzzzzk',
    [35] = '...........................kzzzzzzk',
    -- costas do sobrecasaco 'c' fechadas com costura central
    [36] = '.........................kcccccccccccccccck',
    [37] = '........................kcccccccccccccccccck',
    [38] = '.........................kcccccccccccccccccIk',
    [39] = '.........................kcccccccccccccccccIk',
    [40] = '...................kcck..kcccccccccccccccccIk..kcck',
    [41] = '...................kcck..kcccccccccccccccccIk..kcck',
    [42] = '...................kcck..kcccccccccccccccccIk..kcck',
    [43] = '...................kcck..kcccccccccccccccccIk..kcck',
    [44] = '...................kcck..kcccccccccccccccccIk..kcck',
    [45] = '...................kcck..kcccccccccccccccccIk..kcck',
    [46] = '...................kcck..kcccccccccccccccccIk..kcck',
    [47] = '...................kcck..kcccccccccccccccccIk..kcck',
    [48] = '...................kcck..kcccccccccccccccccIk..kcck',
    [49] = '...................kcck..kcccccccccccccccccIk..kcck',
    [50] = '...................kcck..kcccccccccccccccccIk..kcck',
    [51] = '...................kcck..kcccccccccccccccccIk..kcck',
    [52] = '...................kcck..kcccccccccccccccccIk..kcck',
    [53] = '...................kcck..kcccccccccccccccccIk..kcck',
    [54] = '...................krrk..kcccccccccccccccccIk..krrk',
    [55] = '...................krrk..kcccccccccccccccccIk..krrk',
    [56] = '...................krrk..kcccccccccccccccccIk..krrk',
    [57] = '...................kssk..kcccccccccccccccccIk..kssk',
    [58] = '...................kssk..kcccccccccccccccccIk..kssk',
    [59] = '...................kssk..kcccccccccccccccccIk..kssk',
    [60] = '...................ksssk..kcccccccccccccccccIk..ksssk',
    [61] = '...................ksssk..kcccccccccccccccccIk..kkkk',
    [62] = '...................ksssk..kcccccccccccccccccIk',
    [63] = '...................kkkk...ktttttttttttttttttk',
    [64] = '.........................ktttttttttttttttttk',
    [65] = '.........................ktttttttttttttttttk',
    [66] = '.........................ktttttttttttttttttk',
    [67] = '.........................ktttttttttttttttttk',
    [68] = '.........................ktttttttttttttttttk',
    [69] = '.........................ktttttttttttttttttk',
    [70] = '.........................ktttttttttttttttttk',
    [71] = '.........................ktttttttttttttttttk',
    -- fenda traseira da túnica: mesmo vão, costura 'I' continua
    [72] = '.........................ktttttttkktttttttk',
    [73] = '.........................ktttttttkktttttttk',
    [74] = '.........................ktttttttkktttttttk',
    [75] = '.........................ktttttttkktttttttk',
    [76] = '.........................ktttttttkktttttttk',
    [77] = '.........................ktttttttkktttttttk',
    [78] = '.........................ktttttttkktttttttk',
    [79] = '.........................ktttttttkktttttttk',
    [80] = '.........................ktttttttkktttttttk',
    [81] = '.........................ktttttttkktttttttk',
    [82] = '..........................kbbbk..kbbbk',
    [83] = '..........................kbbbk..kbbbk',
    [84] = '..........................kbbbk..kbbbk',
    [85] = '..........................kbbbk..kbbbk',
    [86] = '..........................kbbbk..kbbbk',
    [87] = '..........................kbbbk..kbbbk',
    [88] = '..........................kbbbk..kbbbk',
    [89] = '..........................kbbbk..kbbbk',
    [90] = '..........................kbbbbk.kbbbbk',
    [91] = '..........................kbbbbk.kbbbbk',
    [92] = '..........................kbbbbk.kbbbbk',
    [93] = '..........................koooook.koooook',
    [94] = '..........................kkkkkk.kkkkkk',
}

local band = {
    [54] = '............................kfffffffffffk',
    [55] = '............................kfffffffffffk',
}
local garb = R(band)

local gesto = patch(shift(body, -1, 8, 34), {
    [33] = '............................kssssk',
    [34] = '............................kzzzzk',
})
local respiroPisca = shift(body, 1, 30, 62)

return {
    name = 'npc_aurel_n', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 3, h = 11 },
        d = { ramp = 'skin', step = 1, h = 10 },
        e = { spec = 'ink', h = 12 },
        n = { ramp = 'skin', step = 2, h = 11 },
        g = { ramp = 'hair', step = 4, h = 11 },
        h = { ramp = 'hair', step = 1, h = 10 },
        G = { ramp = 'hair', step = 3, h = 12 },
        z = { ramp = 'plaster', step = 5, h = 7 },
        t = { ramp = 'plaster', step = 3, h = 5 },
        c = { ramp = 'iron', step = 3, h = 6 },
        I = { ramp = 'iron', step = 2, h = 5 },
        r = { ramp = 'earth', step = 3, h = 7 },
        f = { ramp = 'earth', step = 4, h = 5 },
        p = { ramp = 'iron', step = 4, h = 4 },
        b = { ramp = 'earth', step = 2, h = 2 },
        o = { ramp = 'earth', step = 4, h = 2 },
        B = { ramp = 'earth', step = 4, h = 3 },
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body), R(shift(body, 1, 30, 62)), R(gesto), R(respiroPisca),
        } },
        { name = 'band', h = 6, albedo = { garb, garb, garb, garb } },
    },
}
