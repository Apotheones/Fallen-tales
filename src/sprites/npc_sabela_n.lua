-- SABELA — idle NORTE (de costas), 64x96, origem nos pés, 4f.
-- f1 repouso | f2 respiro | f3 GESTO: olha o caderno (cabeça inclina
-- 1px baixo+dir, caderno sobe 1px) | f4 respiro + cabeça assenta.
-- Costas: tranças curtas puxadas para trás cobrem a cabeça inteira
-- (sem rosto); casaco petróleo 'c' fecha o dorso com a linha dos
-- dois painéis lendo na queda das costas; faixa 'r' na cintura;
-- pasta plana 'Q' e caderno 'P' trocam de lado (ficam na esquerda
-- da tela — mesmo lado do corpo). Pernas longas e botas iguais.

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
    -- tranças por trás: massa 'h' com textura 'H', sem pele à vista
    [8]  = '............................kkkkkk',
    [9]  = '...........................khhhhhhk',
    [10] = '..........................khhhhhhhhk',
    [11] = '..........................khhHhHhhhk',
    [12] = '..........................khhhhhhhhhk',
    [13] = '..........................khhhhhhhhhk',
    [14] = '..........................khhHhhhHhhk',
    [15] = '..........................khhhhhhhhhk',
    [16] = '..........................khhhhhhhhhk',
    [17] = '..........................khhhhhhhhhk',
    [18] = '..........................khhhhhhhhhk',
    [19] = '..........................khhhhhhhhhk',
    [20] = '..........................khhhhhhhhhk',
    [21] = '..........................khhhhhhhhhk',
    [22] = '..........................khhHhhhHhhk',
    [23] = '..........................khhhhhhhhhk',
    [24] = '..........................khhhhhhhhhk',
    [25] = '..........................khhhhhhhhk',
    [26] = '...........................khhhhhhk',
    [27] = '...........................khhhhhhk',
    [28] = '............................kssssk',
    [29] = '............................kssssk',
    [30] = '...........................kllllllk',
    [31] = '........................kcccccccccccccccck',
    [32] = '........................kcccccccccccccccck',
    [33] = '........................kcccccccccccccccck',
    [34] = '..................kcck..kcccccccccccccccck..kcck',
    [35] = '..................kcck..kcccccccccccccccck..kcck',
    [36] = '..................kcck..kcccccccccccccccck..kcck',
    [37] = '..................kcck..kcccccccccccccccck..kcck',
    [38] = '..................kcck..kcccccccccccccccck..kcck',
    [39] = '..................kcck..kcccccccccccccccck..kcck',
    [40] = '..................kcck..kcccccccccccccccck..kcck',
    [41] = '..................kcck..kcccccccccccccccck..kcck',
    [42] = '..................kcck..kcccccccccccccccck..kcck',
    [43] = '..................kcck..kcccccccccccccccck..kcck',
    [44] = '..................kcck..kcccccccccccccccck..kcck',
    [45] = '..................kcck..kcccccccccccccccck..kcck',
    [46] = '..................kcck..kcccccccccccccccck..kcck',
    [47] = '..................kcck..kcccccccccccccccck..kcck',
    [48] = '..................kcck..kcccccccccccccccck..kcck',
    [49] = '..................kcck..kcccccccccccccccck..kcck',
    [50] = '..................kcck..kcccccccccccccccck..kcck',
    [51] = '..................kcck..kcccccccccccccccck..kcck',
    [52] = '..................kcck..kcccccccccccccccck..kcck',
    [53] = '..................kcck..kcccccccccccccccck..kcck',
    [54] = '..................kcck..kcccccccccccccccck..kcck',
    [55] = '..................kcck..kcccccccccccccccck..kcck',
    [56] = '..................kcck..kcccccccccccccccck..kcck',
    -- punho dir. engordado 1px p/ dentro, por cima da borda do caderno
    -- (pele extra na linha do gesto — segura, não faixa solta)
    [57] = '..................kssk..kcccccccccccccccck.ksssk',
    [58] = '..................kssk..kcccccccccccccccck.ksssk',
    [59] = '........................kcccccccccccccccck..kssk',
    [60] = '........................kcccccccccccccccck..kssk',
    [61] = '........................kcccccccccccccccck..kssk',
    [62] = '........................kcccccccccccccccck..kkkk',
    [63] = '........................kcccccccccccccccck',
    [64] = '..........................kppppk.kppppk',
    [65] = '..........................kppppk.kppppk',
    [66] = '..........................kppppk.kppppk',
    [67] = '..........................kppppk.kppppk',
    [68] = '..........................kppppk.kppppk',
    [69] = '..........................kppppk.kppppk',
    [70] = '..........................kppppk.kppppk',
    [71] = '..........................kppppk.kppppk',
    [72] = '..........................kppppk.kppppk',
    [73] = '..........................kppppk.kppppk',
    [74] = '..........................kppppk.kppppk',
    [75] = '..........................kppppk.kppppk',
    [76] = '..........................kppppk.kppppk',
    [77] = '..........................kppppk.kppppk',
    [78] = '..........................kppppk.kppppk',
    [79] = '..........................kppppk.kppppk',
    [80] = '..........................kppppk.kppppk',
    [81] = '..........................kppppk.kppppk',
    [82] = '..........................kppppk.kppppk',
    [83] = '..........................kppppk.kppppk',
    [84] = '..........................kppppk.kppppk',
    [85] = '..........................kppppk.kppppk',
    [86] = '..........................kppppk.kppppk',
    [87] = '..........................kbbbk.kbbbk',
    [88] = '..........................kbbbk.kbbbk',
    [89] = '..........................kbbbk.kbbbk',
    [90] = '..........................kbbbk.kbbbk',
    [91] = '..........................kbbbk.kbbbk',
    [92] = '..........................kbbbk.kbbbk',
    [93] = '..........................kooook.kooook',
    [94] = '..........................kkkkk.kkkkk',
}

-- faixa 'r' na cintura; pasta 'Q' e caderno 'P' agora à esquerda
local gear = {
    [54] = '........................krrrrrrrrrrrrrrrrk',
    [55] = '........................krrrrrrrrrrrrrrrrk',
    [57] = '...........kQQk',
    [58] = '...........kQQk',
    [59] = '...........kQqk..........................kPPssk',
    [60] = '...........kQqk..........................kPppPk',
    [61] = '...........kQqk..........................kPPPPk',
    [62] = '...........kQqk..........................kPPPPk',
    [63] = '...........kQqk..........................kPPPPk',
    [64] = '...........kQqk..........................kPPPPk',
    [65] = '...........kQqk...........................kkkk',
    [66] = '...........kQqk',
    [67] = '...........kQqk',
    [68] = '...........kQqk',
    [69] = '...........kQqk',
    [70] = '...........kQqk',
    [71] = '...........kQqk',
    [72] = '...........kQqk',
    [73] = '...........kQqk',
    [74] = '............kQk',
}

-- f3: olha o caderno — cabeça desce 1px e inclina 1px p/ a direita
-- (lado do caderno de costas); o caderno sobe 1px.
local gesto = hshift(shift(body, 1, 8, 29), 1, 8, 30)
local gearGesto = patch(gear, {
    [58] = '...........kQQk..........................kPPssk',
    [59] = '...........kQqk..........................kPppPk',
    [60] = '...........kQqk..........................kPPPPk',
    [61] = '...........kQqk..........................kPPPPk',
    [62] = '...........kQqk..........................kPPPPk',
    [63] = '...........kQqk..........................kPPPPk',
    [64] = '...........kQqk...........................kkkk',
    [65] = '...........kQqk',
})
-- f4: respiro com a cabeça assentando 1px a mais (sem olhos de costas).
local respiroAssenta = shift(shift(body, 1, 8, 29), 1, 31, 56)

return {
    name = 'npc_sabela_n',
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
        b = {ramp = 'earth', step = 2, h = 2},
        o = {ramp = 'earth', step = 4, h = 3},
        P = {ramp = 'bone', step = 6, h = 8},
        Q = {ramp = 'earth', step = 2, h = 7},
        q = {ramp = 'earth', step = 4, h = 7},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 56)),
            R(gesto),
            R(respiroAssenta),
        }},
        {name = 'gear', h = 7, albedo = {
            R(gear),
            R(gear),
            R(gearGesto),
            R(gear),
        }},
    },
}
