-- V10 NPC_SABELA_N — Sabela de costas (norte), 64x96 feet, 4f.
-- De costas: tranças puxadas em massa 'h' com trilhas 'H', casaco
-- petróleo fechado nas costas (painel único 'c'), pasta 'Q' atrás do
-- quadril, sash 'B' na cintura, punhos 'C', joelho remendado.
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
    -- nuca: tranças puxadas numa massa compacta, pontas 'h' soltas
    [8]  = '............................khkhkk',
    [9]  = '...........................khhhhhhk',
    [10] = '..........................khhhhhhhhk',
    [11] = '..........................khhHhHhhhk',
    [12] = '..........................khhwwwwhhk',
    [13] = '..........................khhhhhhhhhkk',
    [14] = '..........................khhHhHhhHhhk',
    [15] = '..........................khhHhhHhHhhk',
    [16] = '..........................khhhhhhHhhhk',
    [17] = '..........................khhhhhhhhhhk',
    [18] = '..........................khhhhhhhhhhk',
    [19] = '..........................khhhhhhhhhhk',
    [20] = '..........................khhhhhchhhhk',
    [21] = '..........................khhhhhhhhhkk',
    [22] = '..........................khssssssshk',
    [23] = '..........................kssssssssk',
    [24] = '..........................kssssssssk',
    [25] = '..........................kssssssssk',
    [26] = '...........................kssssssk',
    [27] = '...........................kssssssk',
    [28] = '............................kssssk',
    [29] = '............................kssssk',
    [30] = '...........................kllllllk',
    -- casaco de costas: painel único 'c' cobrindo os ombros/costas
    -- com costura vertical central 'C'
    [31] = '........................kccccccccccccccck',
    [32] = '........................kccccccccccccccck',
    [33] = '........................kccccccCcccccccck',
    [34] = '..................kcck..kccccccCcccccccck..kcck',
    [35] = '..................kcck..kccccccCcccccccck..kcck',
    [36] = '..................kcck..kccccccCcccccccck..kcck',
    [37] = '..................kcck..kccccccCcccccccck..kcck',
    [38] = '..................kcck..kccccccCcccccccck..kcck',
    [39] = '..................kcck..kccccccCcccccccck..kcck',
    [40] = '..................kcck..kccccccCcccccccck..kcck',
    [41] = '..................kcck..kccccccCcccccccck..kcck',
    [42] = '..................kcck..kccccccCcccccccck..kcck',
    [43] = '..................kcck..kccccccCcccccccck..kcck',
    [44] = '..................kcck..kccccccCcccccccck..kcck',
    [45] = '..................kcck..kccccccCcccccccck..kcck',
    [46] = '..................kcck..kccccccCcccccccck..kcck',
    [47] = '..................kcck..kccccccCcccccccck..kcck',
    [48] = '..................kcck..kccccccCcccccccck..kcck',
    [49] = '..................kcck..kccccccCcccccccck..kcck',
    [50] = '..................kcck..kccccccCcccccccck..kcck',
    [51] = '..................kcck..kccccccCcccccccck..kcck',
    [52] = '..................kcck..kccccccCcccccccck..kcck',
    [53] = '..................kCCk..kccccccCcccccccck..kCCk',
    [54] = '..................kCCk..kccccccCcccccccck..kCCk',
    [55] = '..................kCCk..kccccccCcccccccck..kCCk',
    [56] = '..................kCCk..kccccccCcccccccck..kCCk',
    [57] = '.................ksssk..kccccccCcccccccck..kssk',
    [58] = '.................ksdsk..kccccccCcccccccck..ksdk',
    [59] = '........................kccccccCcccccccck..kssk',
    [60] = '........................kccccccCcccccccck..kssk',
    [61] = '........................kccccccCcccccccck..kssk',
    [62] = '........................kccccccCcccccccck..kkkk',
    [63] = '........................kcccBBBBBBBBBBcck',
    [64] = '..........................kppppk.kppppk',
    [65] = '..........................kppppk.kppppk',
    [66] = '..........................kppppk.kppppk',
    [67] = '..........................kppppk.kppppk',
    [68] = '..........................kppppk.kppppk',
    [69] = '..........................kppppk.kppppk',
    [70] = '..........................kppppk.kppppk',
    [71] = '..........................kppppk.kppppk',
    [72] = '..........................kppppk.kppppk',
    [73] = '..........................kppppk.kppPPk',
    [74] = '..........................kppppk.kpPPpk',
    [75] = '..........................kppppk.kpPPpk',
    [76] = '..........................kppppk.kppPPk',
    [77] = '..........................kppppk.kppppk',
    [78] = '..........................kppppk.kppppk',
    [79] = '..........................kppppk.kppppk',
    [80] = '..........................kppppk.kppppk',
    [81] = '..........................kppppk.kppppk',
    [82] = '..........................kppppk.kppppk',
    [83] = '..........................kppppk.kppppk',
    [84] = '..........................kppppk.kppppk',
    [85] = '..........................kppppk.kppppk',
    [86] = '..........................kooook.kooook',
    [87] = '..........................koooook.koooook',
    [88] = '..........................koooook.koooook',
    [89] = '..........................kooooook.kooooook',
    [90] = '..........................kooooookkooooook',
    [91] = '..........................koooooookkoooooook',
    [92] = '..........................kDDDDDDkkDDDDDDk',
    [93] = '..........................kDDDDDDkkDDDDDDk',
    [94] = '..........................kkkkkkkkkkkkkkkkk',
}

-- pasta de costas: atrás do quadril direito; cinta 'B' por cima
local gear = {
    [38] = '.............................kBBk',
    [39] = '.............................kBBk',
    [40] = '..............................kBBk',
    [41] = '..............................kBBk',
    [42] = '...............................kBBk',
    [43] = '...............................kBBk',
    [44] = '................................kBBk',
    [45] = '................................kBBk',
    [46] = '.................................kBBk',
    [47] = '.................................kBBk',
    [48] = '..................................kBBk',
    [49] = '..................................kBBk',
    [50] = '...................................kBBk',
    [51] = '...................................kBBk',
    [52] = '....................................kBBk',
    [53] = '.....................................kBBk',
    [54] = '.....................................kBBk',
    [55] = '......................................kBBk',
    [56] = '.......................................kBBk',
    [57] = '.........................................kQQQk',
    [58] = '.........................................kQQQQk',
    [59] = '.........................................kQQQQk',
    [60] = '.........................................kQQQQk',
    [61] = '.........................................kQQQqk',
    [62] = '.........................................kQQQqk',
    [63] = '.........................................kQqqqk',
    [64] = '.........................................kQQQQk',
    [65] = '.........................................kQQQQk',
    [66] = '.........................................kQkkQk',
    [67] = '.........................................kQkkQk',
    [68] = '..................................................kkkkkk',
}

local gesto = patch(shift(body, 1, 8, 29), {
    [58] = '.................ksdsk..kccccccCcccccccck..ksddk',
    [59] = '........................kccccccCcccccccck..kddk',
})
local respiroPisca = shift(body, 1, 30, 62)

return {
    name = 'npc_sabela_n', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 2, h = 11 },
        d = { ramp = 'skin', step = 1, h = 10 },
        e = { spec = 'ink', h = 12 },
        n = { ramp = 'skin', step = 3, h = 11 },
        h = { ramp = 'hair', step = 1, h = 11 },
        H = { ramp = 'hair', step = 2, h = 11 },
        w = { ramp = 'plaster', step = 6, h = 11 },
        l = { ramp = 'plaster', step = 4, h = 6 },
        c = { ramp = 'sea', step = 2, h = 6 },
        C = { ramp = 'sea', step = 1, h = 5 },
        p = { ramp = 'iron', step = 4, h = 4 },
        P = { ramp = 'iron', step = 2, h = 3 },
        B = { ramp = 'earth', step = 2, h = 5 },
        Q = { ramp = 'earth', step = 4, h = 6 },
        q = { ramp = 'earth', step = 1, h = 5 },
        o = { ramp = 'earth', step = 4, h = 2 },
        D = { ramp = 'earth', step = 1, h = 2 },
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body), R(shift(body, 1, 30, 62)), R(gesto), R(respiroPisca),
        } },
        { name = 'gear', h = 7, albedo = { R(gear), R(gear), R(gear), R(gear) } },
    },
}
