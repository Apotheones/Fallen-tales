-- V08 NPC_RUNA_S — Runa vigia, idle SUL (de frente), 64x96 feet, 4f.
-- Âncoras: manto triangular + trança ruiva baixa (ombro dela =
-- direita da tela) + polainas claras. De frente: franja picada, sardas
-- nas duas bochechas, dedos longos na mão da esquerda (lado da grade)
-- erguida ao ombro; a outra mão descansa no cinto junto às chaves.
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
    -- franja picada: dentes 'a' irregulares sobre a testa
    [9]  = '...........................kaaaaaaaaak',
    [10] = '..........................kaaaaaaaaaaak',
    [11] = '..........................khaaaaahaaaak',
    [12] = '..........................khaahhaaaahk',
    [13] = '..........................khssssssssssk',
    [14] = '..........................ksssssssssssk',
    [15] = '..........................ksssssssssssk',
    [16] = '..........................ksdssdddssdsk',
    [17] = '..........................ksssssssssssk',
    [18] = '..........................ksseeseesesk',
    [19] = '..........................kssssnnnnsk',
    [20] = '..........................kssdssddsdsk',
    [21] = '..........................ksssssssssk',
    [22] = '..........................kssssssssk',
    [23] = '...........................kssssssk',
    -- trança ruiva BAIXA sobre o ombro dela (lado direito da tela)
    [24] = '...........................ksssssskak',
    [25] = '...........................ksssssk.aak',
    [26] = '...........................ksssssk.kAAk',
    [27] = '...........................ksssssk.kAAk',
    [28] = '............................ksssk.kAak',
    [29] = '............................ksssk.kAak',
    [30] = '............................ksssk..kaak',
    -- manto triangular simétrico: estreito no pescoço abrindo ao peito;
    -- forro palha 'l' na borda livre inferior
    [31] = '..........................kkmmmkkmmmkk',
    [32] = '.........................kmmmmlmmmmlmmk',
    [33] = '........................kmmmmmmmmmmmmmmlk',
    [34] = '.......................kmmmmmmmmmmmmmmmlmk',
    [35] = '......................kmmmmmmmmmmmmmmmmmlmk',
    [36] = '.....................kmmmlmmmmmmmmmmmmmmllk',
    [37] = '....................kmmmllmmmmmmmmmmmmmmllmk',
    [38] = '...................kmmmlllmmmmmmmmmmmmlllmmk',
    [39] = '...................kmmllllmmmmmmmmmmmllllmmk',
    -- mão direita da tela (esquerda dela): dedos 's' sobre a borda do
    -- manto à altura do peito — "dedos na grade"
    [40] = '..................ksskllllmmmmmmmmmmllllmk',
    [41] = '..................ksdsklllmmmmmmmmmlllkssk',
    [42] = '...................kkkllllmmmmmmmmlllk.kdsk',
    -- camisa carvão + proteção de couro sob o manto
    [43] = '......................kiiiiiiiiiiiiiik.kk',
    [44] = '......................kiiLLLLLLLLLLLiik',
    [45] = '......................kiiLLxLLLLxLLLiiik',
    [46] = '......................kiiLLLLLLLLLLiiik',
    [47] = '......................kiiLLxLLLLxLLiiik',
    [48] = '......................kiiLLLLLLLLLLiiik',
    [49] = '......................kiiLLLLLLLLLiiik',
    [50] = '......................kiiLLLLLLLLLiiik',
    -- braço esquerdo dela (dir da tela) desce ao cinto, mão no molho
    -- de chaves 'g'; antebraço esquerdo (esq da tela) recolhido sob manto
    [51] = '......................kiiLLLLLLLLiiik',
    [52] = '......................kiiLLLLLLLLiiiksssk',
    [53] = '......................kiiLLLLLLLiiik.sddk',
    [54] = '......................kiiLLLLLLLiiik.kdsksgk',
    [55] = '......................kiiLLLLLLLiiiikksssgGk',
    [56] = '......................kiiLLLLLLiiiiik.kkkgk',
    -- cinto + calças
    [57] = '......................kBBBBBBBBBBBBk',
    [58] = '......................kBBBBBBBBBBBkk',
    [59] = '......................kiiiiiiiikiiiiik',
    [60] = '......................kiiiiiiiikiiiiik',
    [61] = '......................kiiiiiiiikiiiiik',
    [62] = '......................kpppppppkpppppppk',
    [63] = '......................kpppppppkpppppppk',
    [64] = '......................kpppppppkpppppppk',
    [65] = '......................kpppppppkpppppppk',
    [66] = '......................kpppppppkpppppppk',
    [67] = '......................kpppppppkpppppppk',
    [68] = '......................kppppppk.kppppppk',
    [69] = '......................kppppppk.kppppppk',
    [70] = '......................kppppppk.kppppppk',
    [71] = '......................kppppppk.kppppppk',
    [72] = '......................kppppppk.kppppppk',
    [73] = '......................kppppppk.kppppppk',
    -- polainas claras com espirais 'o' — âncora de silhouette
    [74] = '......................kOOOOOOk.kOOOOOOk',
    [75] = '......................kOoooook.kOoooooOk',
    [76] = '......................kOOOOOOk.kOOOOOOk',
    [77] = '......................kOoooook.kOoooooOk',
    [78] = '......................kOOOOOOk.kOOOOOOk',
    [79] = '......................kOoooook.kOoooooOk',
    [80] = '......................kOOOOOOk.kOOOOOOk',
    [81] = '......................kOoooook.kOoooooOk',
    [82] = '......................kOOOOOOk.kOOOOOOk',
    -- botas altas
    [83] = '......................kDDDDDk.kDDDDDk',
    [84] = '......................kDDDDDk.kDDDDDk',
    [85] = '......................kbbbbbk.kbbbbbk',
    [86] = '......................kbbbbbk.kbbbbbk',
    [87] = '......................kbbbbbk.kbbbbbk',
    [88] = '......................kbbbbbk.kbbbbbk',
    [89] = '......................kbbbbbk.kbbbbbk',
    [90] = '......................kbbbbbbkkbbbbbbk',
    [91] = '......................kbbbbbbbkkbbbbbbbk',
    [92] = '......................kbbbbbbbkkbbbbbbbk',
    [93] = '......................kbbwbbbbkkbbbwbbbk',
    [94] = '......................kkkkkkkkkkkkkkkkkkk',
}

local gesto = patch(shift(body, 1, 9, 36), {
    -- f3: dedos na borda do manto apertam — bloco 'sdd' maior
    [41] = '..................kddsklllmmmmmmmmmlllkssk',
    [42] = '...................kskkllllmmmmmmmmlllk.kdsk',
})

local respiroPisca = shift(patch(body, {
    [18] = '..........................kssddsddssek',
}), 1, 37, 60)

return {
    name = 'npc_runa_s', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 3, h = 11 },
        d = { ramp = 'skin', step = 1, h = 10 },
        n = { ramp = 'skin', step = 2, h = 11 },
        e = { spec = 'ink', h = 12 },
        a = { ramp = 'rust', step = 4, h = 11 },
        A = { ramp = 'rust', step = 3, h = 11 },
        h = { ramp = 'hair', step = 1, h = 11 },
        i = { ramp = 'iron', step = 3, h = 6 },
        L = { ramp = 'earth', step = 2, h = 7 },
        x = { ramp = 'earth', step = 1, h = 6 },
        m = { ramp = 'moss', step = 4, h = 7 },
        l = { ramp = 'bone', step = 5, h = 8 },
        B = { ramp = 'earth', step = 1, h = 5 },
        g = { ramp = 'gold', step = 5, h = 6 },
        G = { ramp = 'gold', step = 4, h = 6 },
        p = { ramp = 'iron', step = 3, h = 4 },
        O = { ramp = 'bone', step = 4, h = 5 },
        o = { ramp = 'bone', step = 3, h = 4 },
        D = { ramp = 'earth', step = 1, h = 2 },
        b = { ramp = 'earth', step = 2, h = 2 },
        w = { ramp = 'earth', step = 4, h = 3 },
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 37, 56)),
            R(gesto),
            R(respiroPisca),
        } },
    },
}
