-- DORO — idle NORTE (de costas), 64x96, origem nos pés, 2f.
-- Costas: crânio raspado 's' com stubble 'd' e nuca; a barba prata
-- espreita só como linha 'g' sob a mandíbula (âncora preservada de
-- perfil/frente, não de costas). Colete castanho fechado atrás, avental
-- cobre o dorso abaixo do ombro e a faixa 'F' continua a diagonal por
-- cima do ombro direito (a mesma faixa da frente). Punhos nas laterais.

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
    -- crânio raspado por trás: pele com stubble 'd', nuca larga
    [9]  = '................................kkkkkkk',
    [10] = '...............................kssssssssk',
    [11] = '..............................kssssssssssk',
    [12] = '.............................kssssdsssssdsssk',
    [13] = '.............................kssssssssssssssk',
    [14] = '.............................kssssssssssssssk',
    [15] = '.............................kssssssssssssssk',
    [16] = '.............................kssssssssssssssk',
    [17] = '.............................kssssssssssssssk',
    [18] = '.............................kssssssssssssssk',
    [19] = '.............................kssssssssssssssk',
    [20] = '.............................kssdssssssssdssk',
    [21] = '.............................kssssssssssssssk',
    [22] = '.............................kssssssssssssssk',
    [23] = '.............................kssssssssssssssk',
    [24] = '.............................kssssssssssssssk',
    [25] = '.............................kssssssssssssssk',
    [26] = '.............................ksssdssssdsssk',
    [27] = '.............................kgggggggggggggk',
    [28] = '..............................kggggggggggk',
    [29] = '..............................kggggggggggk',
    [30] = '...............................kgggggggk',
    [31] = '................................ksssssk',
    [32] = '................................ksssssk',
    [33] = '................................ksssssk',
    [34] = '................................ksssssk',
    [35] = '.................................kssssk',
    [36] = '.................................kssssk',
    [37] = '.................................kssssk',
    -- dorso largo: linho nas bordas/mangas, colete fechado no centro
    [38] = '.........................kllllllllllllllllllllk',
    [39] = '.......................kllllllllllllllllllllllk',
    [40] = '......................kllllllllllllllllllllllllk',
    [41] = '....................kllllllllllllllllllllllllllk',
    [42] = '..................klllllvvvvvvvvvvvvvvvvvvvvllllk',
    [43] = '..................klllvvvvvvvvvvvvvvvvvvvvvlllk',
    [44] = '..................klllvvvvvvvvvvvvvvvvvvvvvlllk',
    [45] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [46] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [47] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [48] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [49] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [50] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [51] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [52] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [53] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [54] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [55] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [56] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [57] = '...................kllvvvvvvvvvvvvvvvvvvvvvllk',
    [58] = '..............ksssskkllvvvvvvvvvvvvvvvvvvvvvllkkssssk',
    [59] = '..............ksssskkllvvvvvvvvvvvvvvvvvvvvvllkkssssk',
    [60] = '..............ksssskkpppppppppppppppppppppppkkssssk',
    [61] = '..............ksssskkpppppppppppppppppppppppkkssssk',
    [62] = '..............kkkkk.kpppppppppppppppppppppppk.kkkkk',
    [63] = '.......................kppppppppk...kppppppppk',
    [64] = '.......................kppppppppk...kppppppppk',
    [65] = '.......................kppppppppk...kppppppppk',
    [66] = '.......................kppppppppk...kppppppppk',
    [67] = '.......................kppppppppk...kppppppppk',
    [68] = '.......................kppppppppk...kppppppppk',
    [69] = '.......................kppppppppk...kppppppppk',
    [70] = '.......................kppppppppk...kppppppppk',
    [71] = '.......................kppppppppk...kppppppppk',
    [72] = '.......................kppppppppk...kppppppppk',
    [73] = '.......................kppppppppk...kppppppppk',
    [74] = '.......................kppppppppk...kppppppppk',
    [75] = '.......................kppppppppk...kppppppppk',
    [76] = '.......................kppppppppk...kppppppppk',
    [77] = '........................kpppppppk...kppppppk',
    [78] = '........................kpppppppk...kppppppk',
    [79] = '........................kpppppppk...kppppppk',
    [80] = '........................kpppppppk...kppppppk',
    [81] = '........................kpppppppk...kppppppk',
    [82] = '........................kpppppppk...kppppppk',
    [83] = '........................kpppppppk...kppppppk',
    [84] = '........................kpppppppk...kppppppk',
    [85] = '........................kbbbbbbbbk...kbbbbbbbbk',
    [86] = '........................kbbbbbbbbk...kbbbbbbbbk',
    [87] = '........................kbbbbbbbbk...kbbbbbbbbk',
    [88] = '........................kbbbbbbbbk...kbbbbbbbbk',
    [89] = '........................kbbbbbbbbk...kbbbbbbbbk',
    [90] = '.......................kbbbbbbbbbbk.kbbbbbbbbbbk',
    [91] = '.......................kbbbbbbbbbbk.kbbbbbbbbbbk',
    [92] = '.......................kbbbbbbbbbbk.kbbbbbbbbbbk',
    [93] = '.......................kooooooooook.kooooooooook',
    [94] = '.......................kkkkkkkkkkk.kkkkkkkkkkk',
}

-- avental por trás: painel traseiro mais estreito + faixa 'F' que
-- desponta por cima do ombro direito (continuação da diagonal da frente)
local apron = {
    [47] = '..........................kAAAAAAAAAAAAAAk',
    [48] = '..........................kaaaaaaaaaaaaaak',
    [49] = '..........................kaaaaaaaaaaaaaak',
    [50] = '..........................kaaaaaaaaaaaaaak',
    [51] = '..........................kaaaaaaaaaaaaaak',
    [52] = '..........................kaaaaaaaaaaaaaak',
    [53] = '..........................kaaaaaaaaaaaaaak',
    [54] = '..........................kaaaaaaaaaaaaaak',
    [55] = '..........................kaaaaaaaaaaaaaak',
    [56] = '..........................kaaaaaaaaaaaaaak',
    [57] = '..........................kaaaaaaaaaaaaaak',
    [58] = '..........................kaaaaaaaaaaaaaak',
    [59] = '..........................kaaaaaaaaaaaaaak',
    [60] = '..........................kaaaaaaaaaaaaaak',
    [61] = '..........................kaaaaaaaaaaaaaak',
    [62] = '..........................kaaaaaaaaaaaaaak',
    [63] = '..........................kaaaaaaaaaaaaaak',
    [64] = '..........................kaaaaaaaaaaaaaak',
    [65] = '..........................kaaaaaaaaaaaaaak',
    [66] = '..........................kaaaaaaaaaaaaaak',
    [67] = '..........................kaaaaaaaaaaaaaak',
    [68] = '..........................kaaaaaaaaaaaaaak',
    [69] = '..........................kaaaaaaaaaaaaaak',
    [70] = '..........................kaaaaaaaaaaaaaak',
    [71] = '..........................kAAAAAAAAAAAAAAk',
}

local strap = {
    [39] = '........................................FFF',
    [40] = '.........................................FFF',
    [41] = '..........................................FFF',
    [42] = '...........................................FFF',
    [43] = '............................................FFF',
    [44] = '.............................................FFF',
    [45] = '..............................................FFF',
    [46] = '...............................................FFF',
    [47] = '................................................FFF',
}

local garb = overlay(R(apron), R(strap))

return {
    name = 'npc_doro_n',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 2, h = 11},
        S = {ramp = 'skin', step = 3, h = 12},
        d = {ramp = 'skin', step = 1, h = 10},
        e = {spec = 'ink', h = 12},
        g = {ramp = 'plaster', step = 5, h = 11},
        G = {ramp = 'plaster', step = 6, h = 12},
        h = {ramp = 'hair', step = 2, h = 11},
        l = {ramp = 'plaster', step = 3, h = 6},
        v = {ramp = 'earth', step = 3, h = 6},
        p = {ramp = 'iron', step = 3, h = 4},
        P = {ramp = 'iron', step = 2, h = 3},
        b = {ramp = 'earth', step = 2, h = 2},
        B = {ramp = 'earth', step = 4, h = 3},
        o = {ramp = 'earth', step = 5, h = 2},
        a = {ramp = 'clothWarm', step = 3, h = 6},
        A = {ramp = 'clothWarm', step = 2, h = 6},
        F = {ramp = 'bone', step = 4, h = 8},
        r = {ramp = 'earth', step = 2, h = 5},
        n = {ramp = 'gold', step = 5, h = 7},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 38, 56)),
        }},
        {name = 'garb', h = 6, albedo = {garb, garb}},
    },
}
