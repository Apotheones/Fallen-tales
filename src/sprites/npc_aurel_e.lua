-- V11 NPC_AUREL_E — Aurel em perfil LESTE, 64x96 feet, 4f.
-- Perfil: cabelo grisalho varrido para trás com nuca exposta 'g',
-- rosto comprido, orelha grande 'ss' à mostra, gola alta 'z',
-- túnica pérola 't' com fenda frontal, sobrecasaco 'c' estreito,
-- punho de couro 'r', dedos compridos na mão pendurada.
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
    -- perfil à direita: massa de cabelo varrido p/ trás, testa alta,
    -- orelha saliente 's' na lateral esquerda da cabeça
    [8]  = '.............................kggggk',
    [9]  = '............................kgggggggk',
    [10] = '...........................kgggggggggk',
    [11] = '...........................kggggggggggk',
    [12] = '..........................kgggggggggggk',
    [13] = '..........................kgssggggggggk',
    [14] = '..........................kgssggggggggk',
    [15] = '..........................kssgsssssssssk',
    [16] = '..........................kssgsssssssssk',
    [17] = '.........................kssgsssssssssssk',
    [18] = '.........................ksdgssssssessk',
    [19] = '.........................kssgssssssssssk',
    [20] = '.........................kssssssssssnsk',
    [21] = '.........................kssssssssnsnsk',
    [22] = '.........................ksssssssddsssk',
    [23] = '.........................kssssssddsssk',
    [24] = '.........................ksssssssssssk',
    [25] = '.........................kssssssssssk',
    [26] = '..........................kssssssssk',
    [27] = '..........................kssssssk',
    [28] = '..........................ksssssk',
    [29] = '..........................kssssk',
    -- gola alta sobe o pescoço todo de perfil
    [30] = '..........................kzzzzk',
    [31] = '..........................kzzzzk',
    [32] = '..........................kzzzzk',
    [33] = '..........................kzzzzk',
    [34] = '..........................kzzttzzk',
    [35] = '..........................kzzttzzk',
    -- tronco: sobrecasaco estreito 'c' na borda externa (frente E =
    -- direita), túnica 't' no centro; braço traseiro 'dd' sombreado
    [36] = '.........................kcccccccccccck',
    [37] = '........................kcccccccccccccck',
    [38] = '.......................kccccttttttttttttcck',
    [39] = '.......................kccccttttttttttttcck',
    [40] = '..................kcck.kccccttttttttttttcck.kcck',
    [41] = '..................kcck.kccccttttttttttttcck.kcck',
    [42] = '..................kcck.kccccttttttttttttcck.kcck',
    [43] = '..................kcck.kccccttttttttttttcck.kcck',
    [44] = '..................kcck.kccccttttttttttttcck.kcck',
    [45] = '..................kcck.kccccttttttttttttcck.kcck',
    [46] = '..................kcck.kccccttttttttttttcck.kcck',
    [47] = '..................kcck.kccccttttttttttttcck.kcck',
    [48] = '..................kcck.kccccttttttttttttcck.kcck',
    [49] = '..................kcck.kccccttttttttttttcck.kcck',
    [50] = '..................kcck.kccccttttttttttttcck.kcck',
    [51] = '..................kcck.kccccttttttttttttcck.kcck',
    [52] = '..................kcck.kccccttttttttttttcck.kcck',
    [53] = '..................kcck.kccccttttttttttttcck.kcck',
    [54] = '..................krrk.kccccttttttttttttcck.krrk',
    [55] = '..................krrk.kccccttttttttttttcck.krrk',
    [56] = '..................krrk.kccccttttttttttttcck.krrk',
    -- mãos finas: dedos compridos 's' soltos
    [57] = '..................ksskkkccccttttttttttttcck.kssk',
    [58] = '..................kssk.kccccttttttttttttcck.kssk',
    [59] = '..................kssk.kccccttttttttttttcck.kssk',
    [60] = '..................kssskkccccttttttttttttcck.ksssk',
    [61] = '..................kssskkcctttttttttttttttk.kkkk',
    [62] = '...................kkk..kttttttttttttttttk',
    -- túnica continua abaixo do casaco até a fenda
    [63] = '.........................ktttttttttttttttk',
    [64] = '.........................ktttttttttttttttk',
    [65] = '.........................ktttttttttttttttk',
    [66] = '.........................ktttttttttttttttk',
    [67] = '.........................ktttttttttttttttk',
    [68] = '.........................ktttttttttttttttk',
    [69] = '.........................ktttttttttttttttk',
    [70] = '.........................ktttttttttttttttk',
    [71] = '.........................ktttttttttttttttk',
    -- fenda frontal (âncora): o vão 'kk' divide a barra
    [72] = '.........................ktttttttkkttttttk',
    [73] = '.........................ktttttttkkttttttk',
    [74] = '.........................ktttttttkkttttttk',
    [75] = '.........................ktttttttkkttttttk',
    [76] = '.........................ktttttttkkttttttk',
    [77] = '.........................ktttttttkkttttttk',
    [78] = '.........................ktttttttkkttttttk',
    [79] = '.........................ktttttttkkttttttk',
    [80] = '.........................ktttttttkkttttttk',
    [81] = '.........................ktttttttkkttttttk',
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
    [33] = '..........................kssssk',
    [34] = '..........................kzzzzk',
})
local respiroPisca = shift(patch(body, {
    [18] = '.........................ksdgsssssddssk',
}), 1, 30, 62)

return {
    name = 'npc_aurel_e', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 3, h = 11 },
        d = { ramp = 'skin', step = 1, h = 10 },
        e = { spec = 'ink', h = 12 },
        n = { ramp = 'skin', step = 2, h = 11 },
        g = { ramp = 'hair', step = 4, h = 11 },
        G = { ramp = 'hair', step = 3, h = 12 },
        z = { ramp = 'plaster', step = 5, h = 7 },
        t = { ramp = 'plaster', step = 3, h = 5 },
        c = { ramp = 'iron', step = 3, h = 6 },
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
