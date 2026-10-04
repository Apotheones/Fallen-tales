-- DORO — idle LESTE (perfil olhando para a direita), 64x96, 2f.
-- npc_doro_w = espelho via código.
-- Perfil: crânio raspado, nariz largo à direita, barba prata em massa
-- na frente do rosto/pescoço (âncora "cabeça clara" mantida); tronco
-- largo; avental 'a' na frente com faixa 'F' diagonal; braço grosso
-- 'l' pendurado à frente com punho grande; braço de trás em sombra.

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
    -- crânio raspado em perfil: face à direita
    [9]  = '..............................kkkkk',
    [10] = '.............................kssssssk',
    [11] = '............................kssssssssk',
    [12] = '............................ksssdsssssk',
    [13] = '............................ksssssssssk',
    [14] = '............................ksssssssssk',
    [15] = '............................kssssssssssk',
    [16] = '............................kssssssssssk',
    [17] = '............................ksssssgsssssk',
    [18] = '............................kssssseesssk',
    [19] = '............................kssssssssssk',
    [20] = '............................kssssssssssssk',
    [21] = '............................ksssssssssssdk',
    [22] = '............................kssssssssssk',
    -- barba prata toma a frente do maxilar e desce ao peito
    [23] = '............................kssssggggggk',
    [24] = '............................ksssgggggggk',
    [25] = '............................kssgggggggggk',
    [26] = '............................ksggggghggggk',
    [27] = '............................ksggggghggggk',
    [28] = '............................kgggggggggk',
    [29] = '.............................kggggggk',
    [30] = '.............................kgggggk',
    [31] = '.............................kssssk',
    [32] = '.............................kssssk',
    [33] = '.............................kssssk',
    [34] = '.............................kssssk',
    [35] = '.............................kssssk',
    [36] = '.............................kssssk',
    [37] = '.............................ksssk',
    -- tronco largo: linho nas bordas, colete no centro, manga da
    -- frente 'kllk' desce na borda direita até o punho
    [38] = '...........................kllllllllk',
    [39] = '.........................kllllllllllllk',
    [40] = '........................kllllllllllllllk',
    [41] = '........................klllvvvvvvvvvvvvllllk',
    [42] = '........................kllvvvvvvvvvvvvvllllk',
    [43] = '........................kllvvvvvvvvvvvvvllllk',
    [44] = '........................kllvvvvvvvvvvvvvllllk',
    [45] = '........................kllvvvvvvvvvvvvllk.kllk',
    [46] = '........................kllvvvvvvvvvvvvllk.kllk',
    [47] = '........................kllvvvvvvvvvvvvllk.kllk',
    [48] = '........................kllvvvvvvvvvvvvllk.kllk',
    [49] = '........................kllvvvvvvvvvvvvllk.kllk',
    [50] = '........................kllvvvvvvvvvvvvllk.kllk',
    [51] = '........................kllvvvvvvvvvvvvllk.kllk',
    [52] = '........................kllvvvvvvvvvvvvllk.kllk',
    [53] = '........................kllvvvvvvvvvvvvllk.kllk',
    [54] = '........................kllvvvvvvvvvvvvllk.kllk',
    [55] = '........................kllvvvvvvvvvvvvllk.kllk',
    [56] = '........................kllvvvvvvvvvvvvllk.kllk',
    [57] = '........................kllvvvvvvvvvvvvllk.kllk',
    -- punho grande à frente (pele 's'), de trás em sombra 'd'
    [58] = '.....................kddsk.kllvvvvvvvvvlllk.kssssk',
    [59] = '.....................kddsk.kllvvvvvvvvvlllk.kssssk',
    [60] = '.....................kdddk.kppppppppppppppk.kssssk',
    [61] = '.....................kdddk.kppppppppppppppk.kssssk',
    [62] = '.....................kkkk..kppppppppppppppk.kkkkk',
    -- pernas: longe 'P' atrás, perto 'p' na frente (mais grossas)
    [63] = '.........................kPPPPkppppppppk',
    [64] = '.........................kPPPPkppppppppk',
    [65] = '.........................kPPPPkppppppppk',
    [66] = '.........................kPPPPkppppppppk',
    [67] = '.........................kPPPPkppppppppk',
    [68] = '.........................kPPPPkppppppppk',
    [69] = '.........................kPPPPkppppppppk',
    [70] = '.........................kPPPPkppppppppk',
    [71] = '.........................kPPPPkppppppppk',
    [72] = '.........................kPPPPkppppppppk',
    [73] = '.........................kPPPPkppppppppk',
    [74] = '.........................kPPPPkppppppppk',
    [75] = '.........................kPPPPkppppppppk',
    [76] = '.........................kPPPPkppppppppk',
    [77] = '..........................kPPPkppppppk',
    [78] = '..........................kPPPkppppppk',
    [79] = '..........................kPPPkppppppk',
    [80] = '..........................kPPPkppppppk',
    [81] = '..........................kPPPkppppppk',
    [82] = '..........................kPPPkppppppk',
    [83] = '..........................kPPPkppppppk',
    [84] = '..........................kPPPkppppppk',
    -- botas: perto com ponta à direita
    [85] = '.........................kDDkbbbbbbbbk',
    [86] = '.........................kDDkbbbbbbbbk',
    [87] = '.........................kDDkbbbbbbbbk',
    [88] = '.........................kDDkbbbbbbbbk',
    [89] = '.........................kDDkbbbbbbbbk',
    [90] = '.........................kDDkbbbbbbbbbbbk',
    [91] = '.........................kDDkbbbbbbbbbbbk',
    [92] = '.........................kDDkbbbbbbbbbbbk',
    [93] = '.........................kookbbbbbbbbbBk',
    [94] = '.........................kkkkkkkkkkkkkkkkk',
}

-- avental na frente + faixa diagonal descendo à direita
local apron = {
    [46] = '..............................kAAAAAAk',
    [47] = '..............................kaaaaaak',
    [48] = '..............................kaaaaaak',
    [49] = '..............................kaaaaaak',
    [50] = '..............................kaaaaaak',
    [51] = '..............................kaaaaaak',
    [52] = '..............................kaaaaaak',
    [53] = '..............................kaaaaaak',
    [54] = '..............................kaaaaaak',
    [55] = '..............................kaaaaaak',
    [56] = '..............................kaaaaaak',
    [57] = '..............................kaaaaaak',
    [58] = '..............................kaaaaaak',
    [59] = '..............................kaaaaaak',
    [60] = '..............................kaaaaaak',
    [61] = '..............................kaaaaaak',
    [62] = '..............................kaaaaaak',
    [63] = '..............................kaaaaaak',
    [64] = '..............................kaaaaaak',
    [65] = '..............................kaaaaaak',
    [66] = '..............................kaaaaaak',
    [67] = '..............................kaaaaaak',
    [68] = '..............................kaaaaaak',
    [69] = '..............................kaaaaaak',
    [70] = '..............................kaaaaaak',
    [71] = '..............................kAAAAAAk',
}

local strap = {
    [41] = '...............................FFF',
    [42] = '...............................FFF',
    [43] = '................................FFF',
    [44] = '................................FFF',
    [46] = '.................................FFF',
    [47] = '.................................FFF',
    [48] = '..................................FFF',
    [49] = '..................................FFF',
    [51] = '...................................FFF',
    [52] = '...................................FFF',
    [53] = '....................................FFF',
    [54] = '....................................FFF',
    [56] = '.....................................FFF',
    [57] = '.....................................FFF',
    [58] = '......................................FFF',
    [59] = '......................................FFF',
    [61] = '.......................................FFF',
    [62] = '.......................................FFF',
    [63] = '........................................FFF',
    [64] = '........................................FFF',
}

local garb = overlay(R(apron), R(strap))

return {
    name = 'npc_doro_e',
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
        D = {ramp = 'earth', step = 1, h = 2},
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
