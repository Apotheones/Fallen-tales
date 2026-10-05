-- V10 NPC_SABELA_E — Sabela em perfil LESTE, 64x96 feet, 4f.
-- Mesma linguagem do _s: pele escura, tranças puxadas atrás, casaco
-- petróleo aberto em painel frontal 'c' sobre camisa 'l', sash 'B',
-- pasta plana 'Q' atrás do quadril (perfil: pendurada atrás, na
-- lateral longe). f3 = olha a pasta/abaixa o olhar (cabeça +1).
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
    -- perfil: franja de trança 'h' à nuca, fios brancos 'w' na fronte,
    -- rosto angular, nariz estreito 'n', lábio cheio
    [8]  = '..............................khkhhk',
    [9]  = '.............................khhhhhhk',
    [10] = '............................khhHhhhk',
    [11] = '............................khhHhhhhhsk',
    [12] = '............................khhwwhhsssk',
    [13] = '............................khssssssssk',
    [14] = '............................khssssssssk',
    [15] = '............................khssssssssk',
    [16] = '............................khssssssssk',
    [17] = '............................khsssssseskk',
    [18] = '............................ksssssssnssk',
    [19] = '............................ksssssssnnnk',
    [20] = '............................ksssssssddsk',
    [21] = '............................kssssssddssk',
    [22] = '............................kssssssddsk',
    [23] = '............................ksssssssssk',
    [24] = '............................kssssssssk',
    [25] = '............................ksssssssk',
    [26] = '............................kssssssk',
    [27] = '............................ksssssk',
    [28] = '............................kssssk',
    [29] = '............................kssssk',
    [30] = '............................klllllk',
    -- casaco petróleo: painel da frente 'c' no lado dir, camisa 'l'
    -- aparece no recorte; braço de trás 'cc' sombreado
    [31] = '.........................kccckllllllk',
    [32] = '........................kcccccllllllllk',
    [33] = '.......................kcccccllllllllllk',
    [34] = '......................kcccccllllllllllllk',
    [35] = '......................kcccccllllllllllllk',
    [36] = '......................kcccccllllllllllllk',
    [37] = '......................kcccccllllllllllllk',
    [38] = '......................kcccccllllllllllllk',
    [39] = '......................kcccccllllllllllllk',
    [40] = '......................kcccccllllllllllllk',
    [41] = '......................kcccccllllllllllllk',
    [42] = '......................kcccccllllllllllllk',
    [43] = '......................kcccccllllllllllllk',
    [44] = '......................kcccccllllllllllllk',
    [45] = '......................kcccccllllllllllllk',
    [46] = '......................kcccccllllllllllllk',
    [47] = '......................kcccccllllllllllllk',
    [48] = '......................kcccccllllllllllllk',
    [49] = '......................kcccccllllllllllllk',
    [50] = '......................kcccccllllllllllllk',
    [51] = '......................kcccccllllllllllllk',
    [52] = '......................kcccccllllllllllllk',
    -- braço da frente desce fora do painel do casaco
    [53] = '.....................kcckcccccllllllllllllk',
    [54] = '.....................kCCkcccccllllllllllllk',
    [55] = '.....................kCCkcccccllllllllllllk',
    [56] = '.....................kCCkcccccllllllllllllk',
    -- punho grande à frente, braço de trás em sombra 'd'
    [57] = '...................kddkCCkcccccllllllllllk',
    [58] = '...................kddkCCkcccccllllllllllk.ksssk',
    [59] = '...................kddkkckcccccllllllllllk.kssdk',
    [60] = '....................kkk..kcccccllllllllllk.ksssk',
    [61] = '....................kkk..kcccccllllllllllk.kkkk',
    [62] = '....................kkk..kcccccllllllllllk',
    -- sash + pasta na camada gear
    [63] = '........................kcccBBBBBBBBBccck',
    [64] = '..........................kppppppppppk',
    [65] = '..........................kppppppppppk',
    [66] = '..........................kpppppPpppppk',
    [67] = '..........................kpppppPpppppk',
    [68] = '..........................kpppppPpppppk',
    [69] = '..........................kpppppppppppk',
    [70] = '..........................kpppppppppppk',
    [71] = '..........................kpppppppppppk',
    [72] = '..........................kpppppkpppppk',
    [73] = '..........................kppppk.kppppk',
    [74] = '..........................kppppk.kpPPpk',
    [75] = '..........................kppppk.kpPPpk',
    [76] = '..........................kppppk.kppPpk',
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
    [90] = '..........................kooooookkkooooook',
    [91] = '..........................koooooook.koooooook',
    [92] = '..........................kDDDDDDk.kDDDDDDk',
    [93] = '..........................kDDDDDDk.kDDDDDDk',
    [94] = '..........................kkkkkkkkkkkkkkkkkk',
}

-- pasta plana atrás do quadril (lado longe em perfil) + cinta 'B'
-- cruzando o ombro direito
local gear = {
    [36] = '................................kBBk',
    [37] = '...............................kBBk',
    [38] = '...............................kBBk',
    [39] = '..............................kBBk',
    [40] = '..............................kBBk',
    [41] = '.............................kBBk',
    [42] = '.............................kBBk',
    [43] = '............................kBBk',
    [44] = '............................kBBk',
    [45] = '...........................kBBk',
    [46] = '...........................kBBk',
    [47] = '..........................kBBk',
    [48] = '..........................kBBk',
    [49] = '.........................kBBk',
    [50] = '.........................kBBk',
    [51] = '........................kBBk',
    [52] = '........................kBBk',
    [53] = '.......................kBBk',
    [54] = '.......................kBBk',
    [55] = '......................kBBk',
    [56] = '......................kBBk',
    -- pasta atrás do quadril: pendurada na cinta, canto 'q' solto
    [57] = '.................kQQQk',
    [58] = '................kQQQQQk',
    [59] = '................kQQQQQk',
    [60] = '................kQQQqqk',
    [61] = '................kQQQqqk',
    [62] = '................kQQQQQk',
    [63] = '................kQQQQQk',
    [64] = '................kQQQQQk',
    [65] = '................kQkkkQk',
    [66] = '................kkkkkkk',
}

local gesto = patch(shift(body, 1, 8, 29), {
    [59] = '...................kddkkckcccccllllllllllk.kssddk',
    [60] = '....................kkk..kcccccllllllllllk.kssddk',
})
local respiroPisca = shift(patch(body, {
    [17] = '............................khsssssddskk',
}), 1, 30, 62)

return {
    name = 'npc_sabela_e', w = 64, h = 96, origin = 'feet',
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
