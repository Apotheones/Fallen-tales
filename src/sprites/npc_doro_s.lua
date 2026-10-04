-- DORO — coveiro e marceneiro, idle SUL, 64x96, origem nos pés, 2f.
-- §3 do doc de personagens: 58-64a, 181cm, tronco largo — retângulo
-- baixo nos ombros (~30px vs ~21 do Viajante). Pele parda escura
-- (skin.2); cabeça raspada com stubble 'd' e BARBA CURTA PRATA/PRETO
-- ('g' plaster claro com flecks 'h') — a "cabeça clara de barba" é
-- âncora: o terço inferior do rosto lê claro contra a pele escura.
-- Camisa linho cinza (plaster), colete castanho (earth), calças azul
-- carvão (iron.3), avental de lona encerada (clothWarm) com FAIXA
-- DIAGONAL reforçada (bone.4) — âncora nº3. Sem props nas mãos.
-- Âncoras: ombros largos | cabeça clara de barba | faixa diagonal.

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

--------------------------------------------------------------------------------
-- BODY: cabeça raspada + barba prata, pescoço, camisa+colete, calças,
-- botas largas, punhos grandes soltos.
--------------------------------------------------------------------------------
local body = {
    -- crânio raspado: pele com stubble 'd', sem franja
    [9]  = '................................kkkkkkk',
    [10] = '...............................kssssssssk',
    [11] = '..............................kssssssssssk',
    [12] = '.............................kssssdsssssdsssk',
    [13] = '.............................kssssssssssssssk',
    [14] = '.............................kssssssssssssssk',
    [15] = '.............................kssssssssssssssk',
    [16] = '.............................kssssssssssssssk',
    -- sobrancelhas grisalhas 'g' sobre olhos pequenos 'ee'
    [17] = '.............................ksssgssssssgsssk',
    [18] = '.............................ksseesssssseessk',
    [19] = '.............................kssssssssssssssk',
    -- nariz largo achatado 'ddd'
    [20] = '.............................ksssssdddssssssk',
    [21] = '.............................ksssssdddssssssk',
    [22] = '.............................kssssssssssssssk',
    -- barba curta prata 'g' com núcleo 'G' e flecks pretos 'h'
    [23] = '.............................ksggggggggggggsk',
    [24] = '.............................kgggggGGGGGGgggk',
    [25] = '.............................kggggggggggggggk',
    [26] = '.............................kgggghhggghhgggk',
    [27] = '.............................kgggghhggghhgggk',
    [28] = '..............................kggghggghgggk',
    [29] = '..............................kggggggggggk',
    [30] = '...............................kgggggggk',
    [31] = '................................ksssssk',
    [32] = '................................ksssssk',
    [33] = '................................ksssssk',
    [34] = '................................ksssssk',
    [35] = '.................................kssssk',
    [36] = '.................................kssssk',
    [37] = '.................................kssssk',
    -- OMBROS LARGOS (âncora): retângulo baixo, camisa linho + colete
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
    -- punhos grandes soltos nas laterais
    [58] = '..............ksssskkllvvvvvvvvvvvvvvvvvvvvvllkkssssk',
    [59] = '..............ksssskkllvvvvvvvvvvvvvvvvvvvvvllkkssssk',
    [60] = '..............ksssskkpppppppppppppppppppppppkkssssk',
    [61] = '..............ksssskkpppppppppppppppppppppppkkssssk',
    [62] = '..............kkkkk.kpppppppppppppppppppppppk.kkkkk',
    -- calças azul carvão
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
    -- botas largas de sola grossa
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

--------------------------------------------------------------------------------
-- GARB: avental de lona encerada 'a' com bordas 'A' + FAIXA DIAGONAL
-- 'F' (bone.4) do ombro esquerdo ao quadril direito — âncora.
--------------------------------------------------------------------------------
local apron = {
    [46] = '.........................kAAAAAAAAAAAAAAAAk',
    [47] = '.........................kaaaaaaaaaaaaaaaak',
    [48] = '.........................kaaaaaaaaaaaaaaaak',
    [49] = '.........................kaaaaaaaaaaaaaaaak',
    [50] = '.........................kaaaaaaaaaaaaaaaak',
    [51] = '.........................kaaaaaaaaaaaaaaaak',
    [52] = '.........................kaaaaaaaaaaaaaaaak',
    [53] = '.........................kaaaaaaaaaaaaaaaak',
    [54] = '.........................kaaaaaaaaaaaaaaaak',
    [55] = '.........................kaaaaaaaaaaaaaaaak',
    [56] = '.........................kaaaaaaaaaaaaaaaak',
    [57] = '.........................kaaaaaaaaaaaaaaaak',
    [58] = '.........................kaaaaaaaaaaaaaaaak',
    [59] = '.........................kaaaaaaaaaaaaaaaak',
    [60] = '.........................kaaaaaaaaaaaaaaaak',
    [61] = '.........................kaaaaaaaaaaaaaaaak',
    [62] = '.........................kaaaaaaaaaaaaaaaak',
    [63] = '.........................kaaaaaaaaaaaaaaaak',
    [64] = '.........................kaaaaaaaaaaaaaaaak',
    [65] = '.........................kaaaaaaaaaaaaaaaak',
    [66] = '.........................kaaaaaaaaaaaaaaaak',
    [67] = '.........................kaaaaaaaaaaaaaaaak',
    [68] = '.........................kaaaaaaaaaaaaaaaak',
    [69] = '.........................kaaaaaaaaaaaaaaaak',
    [70] = '.........................kaaaaaaaaaaaaaaaak',
    [71] = '.........................kAAAAAAAAAAAAAAAAk',
}

local strap = {
    [41] = '.......................FFF',
    [42] = '........................FFF',
    [44] = '.........................FFF',
    [45] = '..........................FFF',
    [46] = '...........................FFF',
    [47] = '............................FFF',
    [48] = '.............................FFF',
    [50] = '..............................FFF',
    [51] = '...............................FFF',
    [52] = '................................FFF',
    [53] = '.................................FFF',
    [54] = '..................................FFF',
    [56] = '...................................FFF',
    [57] = '....................................FFF',
    [58] = '.....................................FFF',
    [59] = '......................................FFF',
    [60] = '.......................................FFF',
    [62] = '........................................FFF',
    [63] = '.........................................FFF',
    [64] = '..........................................FFF',
    [65] = '...........................................FFF',
    [66] = '............................................FFF',
}

local garb = overlay(R(apron), R(strap))

return {
    name = 'npc_doro_s',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 2, h = 11},  -- pele parda escura
        S = {ramp = 'skin', step = 3, h = 12},
        d = {ramp = 'skin', step = 1, h = 10},  -- stubble/sombra
        e = {spec = 'ink', h = 12},
        g = {ramp = 'plaster', step = 5, h = 11}, -- barba prata (âncora clara)
        G = {ramp = 'plaster', step = 6, h = 12},
        h = {ramp = 'hair', step = 2, h = 11},  -- flecks pretos da barba
        l = {ramp = 'plaster', step = 3, h = 6}, -- camisa linho cinza
        v = {ramp = 'earth', step = 3, h = 6},  -- colete castanho
        p = {ramp = 'iron', step = 3, h = 4},   -- calças azul carvão
        P = {ramp = 'iron', step = 2, h = 3},
        b = {ramp = 'earth', step = 2, h = 2},
        B = {ramp = 'earth', step = 4, h = 3},
        o = {ramp = 'earth', step = 5, h = 2},
        a = {ramp = 'clothWarm', step = 3, h = 6}, -- lona encerada
        A = {ramp = 'clothWarm', step = 2, h = 6},
        F = {ramp = 'bone', step = 4, h = 8},   -- faixa diagonal (âncora)
        r = {ramp = 'earth', step = 2, h = 5},
        n = {ramp = 'gold', step = 5, h = 7},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 38, 56)),
        }},
        {name = 'garb', h = 6, albedo = {
            garb,
            garb,
        }},
    },
}
