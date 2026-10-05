-- V10 NPC_SABELA_S — Sabela protetora/organizadora (C06), idle SUL,
-- 64x96 feet, 4f. Upgrade C01-grade mantendo a geometria do def
-- anterior (tronco cols 18-50, punhos cols 17-20/48-52 linhas 57-62)
-- para npc_sabela_trabalho continuar assentando.
-- Âncoras: alta/pernas longas (76% do corpo) | casaco petróleo em
-- painéis abertos 'c' | pasta plana lateral 'Q'. Pele escura profunda
-- 's'/'d', tranças puxadas para trás com fios brancos na linha frontal
-- 'w', lábio cheio, cicatriz no queixo. Reforços de punho 'c' mais
-- escuros, joelhos remendados 'P', sash marrom 'B' na cintura.
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
    -- tranças puxadas para trás: massa 'h' com filetes 'H', fileira
    -- frontal com fios brancos 'w' no topo da fronte
    [8]  = '............................khkhk',
    [9]  = '...........................khhhhhhk',
    [10] = '..........................khhhhhhhhk',
    [11] = '..........................khhHhHhhhk',
    [12] = '..........................khwwwwwhhk',
    [13] = '..........................kssssssssk',
    [14] = '..........................kssssssssk',
    [15] = '..........................kssssssssk',
    [16] = '..........................kssssssssk',
    [17] = '..........................ksseesseesk',
    [18] = '..........................ksssssssssk',
    [19] = '..........................ksssdsssssk',
    [20] = '..........................ksssnssssk',
    [21] = '..........................ksssssssssk',
    [22] = '..........................ksssdddsssk',
    [23] = '..........................ksssssssssk',
    [24] = '..........................kssssdsssk',
    [25] = '..........................kssssssssk',
    [26] = '...........................kssssssk',
    [27] = '...........................kssssssk',
    [28] = '............................kssssk',
    [29] = '............................kssssk',
    -- camisa cru 'l' com gola; casaco petróleo 'c' abre em dois painéis
    [30] = '...........................kllllllk',
    [31] = '........................kcccccllllllccccck',
    [32] = '........................kcccccllllllccccck',
    [33] = '........................kcccccllllllccccck',
    [34] = '..................kcck..kcccccllllllccccck..kcck',
    [35] = '..................kcck..kcccccllllllccccck..kcck',
    [36] = '..................kcck..kcccccllllllccccck..kcck',
    [37] = '..................kcck..kcccccllllllccccck..kcck',
    [38] = '..................kcck..kcccccllllllccccck..kcck',
    [39] = '..................kcck..kcccccllllllccccck..kcck',
    [40] = '..................kcck..kcccccllllllccccck..kcck',
    [41] = '..................kcck..kcccccllllllccccck..kcck',
    [42] = '..................kcck..kcccccllllllccccck..kcck',
    [43] = '..................kcck..kcccccllllllccccck..kcck',
    [44] = '..................kcck..kcccccllllllccccck..kcck',
    [45] = '..................kcck..kcccccllllllccccck..kcck',
    [46] = '..................kcck..kcccccllllllccccck..kcck',
    [47] = '..................kcck..kcccccllllllccccck..kcck',
    [48] = '..................kcck..kcccccllllllccccck..kcck',
    [49] = '..................kcck..kcccccllllllccccck..kcck',
    [50] = '..................kcck..kcccccllllllccccck..kcck',
    [51] = '..................kcck..kcccccllllllccccck..kcck',
    [52] = '..................kcck..kcccccllllllccccck..kcck',
    -- punhos reforçados 'C' (faixa mais escura no punho do casaco)
    [53] = '..................kCCk..kcccccllllllccccck..kCCk',
    [54] = '..................kCCk..kcccccllllllccccck..kCCk',
    [55] = '..................kCCk..kcccccllllllccccck..kCCk',
    [56] = '..................kCCk..kcccccllllllccccck..kCCk',
    -- punhos soltos: esq. engordado na linha do gesto, dir. na lateral
    [57] = '.................ksssk..kcccccllllllccccck..kssk',
    [58] = '.................ksdsk..kcccccllllllccccck..ksdk',
    [59] = '........................kcccccllllllccccck..kssk',
    [60] = '........................kcccccllllllccccck..kssk',
    [61] = '........................kcccccllllllccccck..kssk',
    [62] = '........................kcccccllllllccccck..kkkk',
    -- sash marrom 'B' na cintura, por baixo do casaco aberto
    [63] = '........................kcccBBBBBBBBBBcck',
    -- pernas longas e secas: cinza 'p' com remendo 'P' no joelho dir.
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
    -- botas de meia-altura leves 'o', sola 'D'
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

-- pasta plana lateral + faixa de segurar 'B' na camada gear
local gear = {
    -- cinta da pasta cruzando o ombro esquerdo
    [38] = '............................kBBk',
    [39] = '............................kBBk',
    [40] = '.............................kBBk',
    [41] = '.............................kBBk',
    [42] = '..............................kBBk',
    [43] = '..............................kBBk',
    [44] = '...............................kBBk',
    [45] = '...............................kBBk',
    [46] = '................................kBBk',
    [47] = '................................kBBk',
    [48] = '.................................kBBk',
    [49] = '.................................kBBk',
    [50] = '..................................kBBk',
    [51] = '..................................kBBk',
    [52] = '...................................kBBk',
    [53] = '....................................kBBk',
    [54] = '....................................kBBk',
    [55] = '.....................................kBBk',
    [56] = '......................................kBBk',
    [57] = '........................................kBBk',
    -- pasta plana pendurada no quadril direito (face 'Q', canto 'q')
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
    [68] = '.........................................kkkkkk',
}

local gesto = patch(shift(body, 1, 8, 29), {
    -- f3: a mão da pasta aperta na lateral — dedos 'd' marcam
    [58] = '.................ksdsk..kcccccllllllccccck..ksddk',
    [59] = '........................kcccccllllllccccck..kddk',
})
local respiroPisca = shift(patch(body, {
    [17] = '..........................kssddsddssk',
}), 1, 30, 62)

return {
    name = 'npc_sabela_s', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 2, h = 11 },   -- pele escura profunda
        d = { ramp = 'skin', step = 1, h = 10 },   -- sombra/cicatriz/lábio
        e = { spec = 'ink', h = 12 },
        n = { ramp = 'skin', step = 2, h = 11 },   -- nariz
        h = { ramp = 'hair', step = 1, h = 11 },   -- tranças escuras
        H = { ramp = 'hair', step = 2, h = 11 },
        w = { ramp = 'plaster', step = 6, h = 11 },-- fios brancos na fronte
        l = { ramp = 'plaster', step = 4, h = 6 }, -- camisa cru
        c = { ramp = 'sea', step = 2, h = 6 },     -- casaco petróleo
        C = { ramp = 'sea', step = 1, h = 5 },     -- reforço de punho
        p = { ramp = 'iron', step = 4, h = 4 },    -- calça cinza
        P = { ramp = 'iron', step = 2, h = 3 },    -- remendo de joelho
        B = { ramp = 'earth', step = 2, h = 5 },   -- sash + cinta da pasta
        Q = { ramp = 'earth', step = 4, h = 6 },   -- pasta plana
        q = { ramp = 'earth', step = 1, h = 5 },
        o = { ramp = 'earth', step = 4, h = 2 },   -- bota clara
        D = { ramp = 'earth', step = 1, h = 2 },
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body), R(shift(body, 1, 30, 62)), R(gesto), R(respiroPisca),
        } },
        { name = 'gear', h = 7, albedo = { R(gear), R(gear), R(gear), R(gear) } },
    },
}
