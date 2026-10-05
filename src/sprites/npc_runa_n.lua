-- V08 NPC_RUNA_N — Runa de costas (norte), 64x96 feet, 4f.
-- De costas: franja some; trança ruiva baixa cai central sobre o
-- manto triangular (forro palha só acena na barra); polainas +
-- botas iguais. f3 vira o rosto 1px (vigia mesmo de costas).
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
    -- cabelo curto visto de trás: massa 'a' com franja picada na nuca
    [9]  = '...........................kaaaaaaaaak',
    [10] = '..........................kaaaaaaaaaaak',
    [11] = '..........................kaaaaaaaaaaak',
    [12] = '..........................kaaaaaaaaaaak',
    [13] = '..........................kaaaaaaaaaaak',
    [14] = '..........................kaahaaaaaaak',
    [15] = '..........................kaahahaaaahak',
    [16] = '..........................kaaahhaaahahk',
    [17] = '..........................kaaahhhhhahak',
    [18] = '..........................kaaaahhaahhak',
    [19] = '..........................kaaaahhhhhaak',
    [20] = '..........................khaahhhhhhaak',
    [21] = '..........................khaaahhhhahak',
    [22] = '..........................ksssssksssssk',  -- nuca raspada
    [23] = '...........................ksssssssk',
    -- trança baixa central sobre o manto (por trás ela cai no meio)
    [24] = '...........................ksssssk',
    [25] = '...........................ksssssk',
    [26] = '...........................kssAAsssk',
    [27] = '...........................ksAAaAsssk',
    [28] = '............................kAAaAak',
    [29] = '............................kAAaAAk',
    [30] = '.............................kAAaAk',
    -- manto triangular de costas: maior, forro só na barra livre
    [31] = '..........................kkmmAmmmkk',
    [32] = '.........................kmmmAAmmmmk',
    [33] = '........................kmmmmmAAmmmmmk',
    [34] = '.......................kmmmmmmAAmmmmmmmk',
    [35] = '......................kmmmmmmmAAmmmmmmmk',
    [36] = '.....................kmmmmmmmmaAmmmmmmmk',
    [37] = '....................kmmmmmmmmmmkmmmmmmmmmk',
    [38] = '...................kmmmmmmmmmmmmmmmmmmmmmk',
    [39] = '...................kmmmmmmmmmmmmmmmmmmmmmmk',
    [40] = '..................kmmmmmmmmmmmmmmmmmmmmmmmk',
    [41] = '..................kmmllllllllllllllllllmmk',
    [42] = '..................kmllllllllllllllllllllmk',
    -- sob o manto: camisa + proteção de couro
    [43] = '..................kiiiiiiiiiiiiiiiiiik',
    [44] = '..................kiiiLLLLLLLLLLLiiiik',
    [45] = '..................kiiiLLxLLLLLxLiiiik',
    [46] = '..................kiiiLLLLLLLLLLLiiiik',
    [47] = '..................kiiiLLxLLLLLxLiiiik',
    [48] = '..................kiiiLLLLLLLLLLiiiik',
    [49] = '..................kiiiLLLLLLLLLiiiik',
    -- braços caem aos lados sob a borda do manto
    [50] = '.................kddkLLLLLLLLLiiikddk',
    [51] = '.................kddkiLLLLLLLLiiikddk',
    [52] = '.................kddkiLLLLLLLiiiikdk',
    [53] = '..................kkkiLLLLLLLiiikssk',
    [54] = '....................kkiLLLLLLiiikkssk',
    [55] = '....................kkiLLLLLLiiiksggk', -- mão + chaves atrás do cinto
    [56] = '....................kkLLLLLLLiiikssgk',
    [57] = '.....................kBBBBBBBBBBkkgk',
    [58] = '.....................kBBBBBBBBBBkk',
    [59] = '.....................kiiiiiiiikiiiiik',
    [60] = '.....................kiiiiiiiikiiiiik',
    [61] = '.....................kiiiiiiiikiiiiik',
    [62] = '.....................kpppppppkpppppppk',
    [63] = '.....................kpppppppkpppppppk',
    [64] = '.....................kpppppppkpppppppk',
    [65] = '.....................kpppppppkpppppppk',
    [66] = '.....................kpppppppkpppppppk',
    [67] = '.....................kpppppppkpppppppk',
    [68] = '.....................kppppppk.kppppppk',
    [69] = '.....................kppppppk.kppppppk',
    [70] = '.....................kppppppk.kppppppk',
    [71] = '.....................kppppppk.kppppppk',
    [72] = '.....................kppppppk.kppppppk',
    [73] = '.....................kppppppk.kppppppk',
    -- polainas de trás: laço espiral 'o' na banda
    [74] = '.....................kOOOOOOk.kOOOOOOk',
    [75] = '.....................kOoooook.kOoooooOk',
    [76] = '.....................kOOOOOOk.kOOOOOOk',
    [77] = '.....................kOoooook.kOoooooOk',
    [78] = '.....................kOOOOOOk.kOOOOOOk',
    [79] = '.....................kOoooook.kOoooooOk',
    [80] = '.....................kOOOOOOk.kOOOOOOk',
    [81] = '.....................kOoooook.kOoooooOk',
    [82] = '.....................kOOOOOOk.kOOOOOOk',
    [83] = '.....................kDDDDDk.kDDDDDk',
    [84] = '.....................kDDDDDk.kDDDDDk',
    [85] = '.....................kbbbbbk.kbbbbbk',
    [86] = '.....................kbbbbbk.kbbbbbk',
    [87] = '.....................kbbbbbk.kbbbbbk',
    [88] = '.....................kbbbbbk.kbbbbbk',
    [89] = '.....................kbbbbbk.kbbbbbk',
    [90] = '.....................kbbbbbbk.kbbbbbbk',
    [91] = '.....................kbbbbbbkkbbbbbbk',
    [92] = '.....................kbbbbbbkkbbbbbbk',
    [93] = '.....................kbbwbbbkkbbbwbbbk',
    [94] = '.....................kkkkkkkkkkkkkkkkkk',
}

-- f3: vigia mesmo de costas — vira o rosto 1px (perfil 's' aparece
-- na borda direita da cabeça)
local gesto = shift(patch(body, {
    [14] = '..........................kaahaaaaaaask',
    [15] = '..........................kaahahaaaassk',
    [16] = '..........................kaaahhaaaassk',
    [17] = '..........................kaaahhhahsssk',
    [18] = '..........................kaaaahhaahsek',
    [19] = '..........................kaaaahhhhsdnk',
}), 1, 26, 56)

local respiroPisca = shift(body, 1, 37, 60)

return {
    name = 'npc_runa_n', w = 64, h = 96, origin = 'feet',
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
