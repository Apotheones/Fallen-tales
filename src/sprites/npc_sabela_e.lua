-- SABELA — idle LESTE (perfil olhando para a direita), 64x96, 4f.
-- f1 repouso | f2 respiro | f3 GESTO: olha o caderno na mão da frente
-- (cabeça inclina 1px baixo+frente, caderno sobe 1px) | f4 respiro +
-- piscar. _w = espelho.
-- npc_sabela_w = espelho via código.
-- Perfil: tranças 'h' na metade de trás da cabeça, fios brancos 'w'
-- só na linha frontal (direita); rosto angular com nariz estreito
-- saindo à frente; casaco 'c' em perfil com a abertura 'l' da camisa
-- na borda da frente; faixa 'r' na cintura; pasta plana 'Q' fina na
-- lateral de trás, caderno 'P' na mão da frente. Pernas longas:
-- longe 'P' atrás, perto 'p' na frente.

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
local function patch(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do t[r] = s end
    return t
end
-- Desloca o conteúdo das linhas [rmin..rmax] em dx colunas (linhas de
-- só-cabeça: o miolo todo anda junto).
local function hshift(map, dx, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then
            if dx > 0 then t[r] = ('.'):rep(dx) .. s:sub(1, #s - dx)
            else t[r] = s:sub(1 - dx) .. ('.'):rep(-dx) end
        else t[r] = s end
    end
    return t
end

local body = {
    [8]  = '.............................kkkkk',
    [9]  = '............................khhhhhk',
    [10] = '...........................khhhhhhhk',
    [11] = '..........................khhHhhhhhk',
    [12] = '..........................khhhhhhhwwk',   -- fios brancos na frente
    [13] = '..........................khhhhhhsssk',
    [14] = '..........................khhhhsssssk',
    [15] = '..........................khhhhsssssk',
    [16] = '..........................khhhhsssssk',
    [17] = '..........................khhhdsssssk',   -- orelha 'd'
    [18] = '..........................khhhhsssesk',   -- olho claro 'e'
    [19] = '..........................khhhhsssssk',
    [20] = '..........................khhhhsssssk',
    [21] = '..........................khhhhssssssk',  -- nariz sai à frente
    [22] = '..........................khhhhsssssdk',
    [23] = '..........................khhhhsssssk',
    [24] = '..........................khhhhssdssk',
    [25] = '..........................khhhhsssssk',
    [26] = '..........................khhhhssssk',
    [27] = '...........................khhsssk',
    [28] = '...........................khsssk',
    [29] = '............................ksssk',
    [30] = '...........................kllllk',
    [31] = '..........................kcccccccccccck',
    [32] = '..........................kcccccccccccck',
    [33] = '..........................kccccccllcccck',  -- abertura 'l' à frente
    [34] = '.....................kcck.kccccccllcccck.kcck',
    [35] = '.....................kcck.kccccccllcccck.kcck',
    [36] = '.....................kcck.kccccccllcccck.kcck',
    [37] = '.....................kcck.kccccccllcccck.kcck',
    [38] = '.....................kcck.kccccccllcccck.kcck',
    [39] = '.....................kcck.kccccccllcccck.kcck',
    [40] = '.....................kcck.kccccccllcccck.kcck',
    [41] = '.....................kcck.kccccccllcccck.kcck',
    [42] = '.....................kcck.kccccccllcccck.kcck',
    [43] = '.....................kcck.kccccccllcccck.kcck',
    [44] = '.....................kcck.kccccccllcccck.kcck',
    [45] = '.....................kcck.kccccccllcccck.kcck',
    [46] = '.....................kcck.kccccccllcccck.kcck',
    [47] = '.....................kcck.kccccccllcccck.kcck',
    [48] = '.....................kcck.kccccccllcccck.kcck',
    [49] = '.....................kcck.kccccccllcccck.kcck',
    [50] = '.....................kcck.kccccccllcccck.kcck',
    [51] = '.....................kcck.kccccccllcccck.kcck',
    [52] = '.....................kcck.kccccccllcccck.kcck',
    [53] = '.....................kcck.kccccccllcccck.kcck',
    [54] = '.....................kcck.kccccccllcccck.kcck',
    [55] = '.....................kcck.kccccccllcccck.kcck',
    [56] = '.....................kcck.kccccccllcccck.kcck',
    -- punho da frente engordado 1px p/ fora + dedo 's' sobre a borda do
    -- caderno (pele extra na linha do gesto — segura, não faixa solta)
    [57] = '.....................kddk.kccccccllcccck.ksssk',
    [58] = '.....................kddk.kccccccllcccck.ksssk',
    [59] = '.....................kddk.kccccccllcccck.kPsk',
    [60] = '.....................kddk.kccccccllcccck.kPPk',
    [61] = '.....................kkkk.kccccccllcccck.kPPk',
    [62] = '..........................kccccccllcccck.kPPk',
    [63] = '..........................kcccccccccccck..kkk',
    [64] = '..........................kIIIIkppppk',
    [65] = '..........................kIIIIkppppk',
    [66] = '..........................kIIIIkppppk',
    [67] = '..........................kIIIIkppppk',
    [68] = '..........................kIIIIkppppk',
    [69] = '..........................kIIIIkppppk',
    [70] = '..........................kIIIIkppppk',
    [71] = '..........................kIIIIkppppk',
    [72] = '..........................kIIIIkppppk',
    [73] = '..........................kIIIIkppppk',
    [74] = '..........................kIIIIkppppk',
    [75] = '..........................kIIIIkppppk',
    [76] = '..........................kIIIIkppppk',
    [77] = '..........................kIIIIkppppk',
    [78] = '..........................kIIIIkppppk',
    [79] = '..........................kIIIIkppppk',
    [80] = '..........................kIIIIkppppk',
    [81] = '..........................kIIIIkppppk',
    [82] = '..........................kIIIIkppppk',
    [83] = '..........................kIIIIkppppk',
    [84] = '..........................kIIIIkppppk',
    [85] = '..........................kIIIIkppppk',
    [86] = '..........................kIIIIkppppk',
    [87] = '..........................kDDbkbbbk',
    [88] = '..........................kDDbkbbbk',
    [89] = '..........................kDDbkbbbk',
    [90] = '..........................kDDbkbbbk',
    [91] = '..........................kDDbkbbbbk',
    [92] = '..........................kDDbkbbbbk',
    [93] = '..........................kookkoooook',
    [94] = '..........................kkkkkkkkkkk',
}

local gear = {
    [54] = '.............................krrrrrrk',
    [55] = '.............................krrrrrrk',
    -- pasta plana fina na lateral de trás (esquerda)
    [56] = '...................kQk',
    [57] = '...................kQk',
    [58] = '...................kQk',
    [59] = '...................kQk',
    [60] = '...................kQk',
    [61] = '...................kQk',
    [62] = '...................kQk',
    [63] = '...................kQk',
    [64] = '...................kQk',
    [65] = '...................kQk',
    [66] = '...................kQk',
    [67] = '...................kQk',
    [68] = '...................kQk',
    [69] = '...................kQk',
    [70] = '...................kQk',
    [71] = '...................kQk',
    [72] = '...................kQk',
    [73] = '...................kQk',
    [74] = '....................kk',
}

-- f3: olha o caderno — cabeça desce 1px e inclina 1px p/ a frente;
-- caderno 'kPPk' sobe 1px ao encontro do olhar.
local gesto = patch(hshift(shift(body, 1, 8, 29), 1, 8, 30), {
    [58] = '.....................kddk.kccccccllcccck.kPsk',
    [62] = '..........................kccccccllcccck.kssk',
})
-- f4: respiro com piscar — olho claro 'e' vira pálpebra 'd'.
local respiroPisca = shift(patch(body, {
    [18] = '..........................khhhhsssdsk',
}), 1, 31, 56)

return {
    name = 'npc_sabela_e',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 1, h = 11},
        S = {ramp = 'skin', step = 2, h = 12},
        d = {ramp = 'hair', step = 1, h = 10},
        e = {ramp = 'bone', step = 5, h = 12},
        h = {ramp = 'hair', step = 1, h = 11},
        H = {ramp = 'hair', step = 3, h = 12},
        w = {ramp = 'plaster', step = 6, h = 12},
        l = {ramp = 'bone', step = 4, h = 6},
        c = {ramp = 'sea', step = 3, h = 7},
        r = {ramp = 'earth', step = 3, h = 8},
        p = {ramp = 'iron', step = 4, h = 4},
        I = {ramp = 'iron', step = 3, h = 3},   -- perna de trás
        P = {ramp = 'bone', step = 6, h = 8},
        b = {ramp = 'earth', step = 2, h = 2},
        D = {ramp = 'earth', step = 1, h = 2},
        o = {ramp = 'earth', step = 4, h = 3},
        Q = {ramp = 'earth', step = 2, h = 7},
        q = {ramp = 'earth', step = 4, h = 7},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 56)),
            R(gesto),
            R(respiroPisca),
        }},
        {name = 'gear', h = 7, albedo = {
            R(gear),
            R(gear),
            R(gear),
            R(gear),
        }},
    },
}
