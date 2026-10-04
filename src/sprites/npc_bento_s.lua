-- BENTO — cozinha da comunidade, idle SUL, 64x96, origem nos pés, 2f.
-- §4 do doc de personagens: 55-61a, 168cm, GORDO — massa arredondada,
-- a silhueta mais larga e baixa do elenco (ombros/barriga ~30px).
-- Pele oliva média (skin.3), rosto redondo, bigode fino em arco 'u'.
-- Cabelo castanho acinzentado curto e crespo sob FAIXA DE PANO CLARA
-- 'F' horizontal na testa (âncora). Camisa verde musgo 'g', colete
-- vinho gasto 'v' aberto no peito; avental cru QUADRADO 'a' (bone)
-- cobrindo a barriga em bloco reto; toalha 'T' caída verticalmente
-- sobre o ombro esquerdo; concha de cabo curto 'c' na mão direita.
-- Tamancos de couro 'b' com sola de madeira 'o'.
-- Âncoras: avental quadrado claro | faixa horizontal no cabelo |
-- toalha num ombro.

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
-- BODY: cabeça redonda sob faixa, massa ovoide camisa+colete, calças,
-- tamancos. Avental e toalha ficam na camada 'garb'.
--------------------------------------------------------------------------------
local body = {
    -- cabelo crespo curto + faixa de pano clara horizontal (âncora)
    [12] = '............................kkkkkk',
    [13] = '.........................kkhhhhhhkk',
    [14] = '........................khhhhhhhhhhk',
    [15] = '........................kFFFFFFFFFFk',
    [16] = '........................kFFFFFFFFFFk',
    -- rosto redondo, olhos pequenos, rugas nas têmporas
    [17] = '........................kssssssssssk',
    [18] = '........................kssssssssssk',
    [19] = '........................kssssssssssk',
    [20] = '........................kseessssseesk',
    [21] = '........................kssssssssssk',
    [22] = '........................ksssdddssssk',   -- nariz largo
    [23] = '........................ksssdddssssk',
    [24] = '........................kssssssssssk',
    [25] = '........................ksuuuuuuuusk',   -- bigode fino em arco
    [26] = '........................ksssddsssssk',
    [27] = '........................kssssssssssk',
    [28] = '.........................kssssssssk',
    [29] = '.........................kssssssssk',
    [30] = '..........................kssssssk',
    -- ombros baixos que abrem na barriga: camisa musgo + colete vinho
    [31] = '..........................kggggggggggk',
    [32] = '........................kggggggggggggk',
    [33] = '.......................kggggggggggggggk',
    [34] = '......................kggggggggggggggggk',
    [35] = '.....................kggggvvvvvvvvvvggggk',
    [36] = '....................kggggvvvvvvvvvvvvggggk',
    [37] = '...................kggggvvvvvvvvvvvvvvggggk',
    [38] = '..................kggggvvvvvvvvvvvvvvvggggk',
    [39] = '.................kggggvvvvvvvvvvvvvvvvvggggk',
    [40] = '................kggggvvvvvvvvvvvvvvvvvvggggk',
    -- barriga máxima ~30px: 'ggg' das bordas são as mangas/braços
    [41] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [42] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [43] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [44] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [45] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [46] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [47] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [48] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [49] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [50] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [51] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [52] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [53] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [54] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [55] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [56] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [57] = '...............kgggvvvvvvvvvvvvvvvvvvvvvvgggk',
    [58] = '.........ksssk..kgggvvvvvvvvvvvvvvvvvvvvvvgggk..ksssk',
    [59] = '.........ksssk..kgggvvvvvvvvvvvvvvvvvvvvvvgggk..ksssk',
    [60] = '.........ksssk..kgggvvvvvvvvvvvvvvvvvvvvvvgggk..ksssk',
    [61] = '.........ksssk...kggppppppppppppppppppppppggk...ksssk',
    [62] = '.........ksssk...kppppppppppppppppppppppppk....ksssk',
    [63] = '.........kkkk....kppppppppppppppppppppppppk....kcck',
    [64] = '.................kppppppppppppppppppppppppk.....kck',
    -- pernas firmes sob a massa
    [65] = '..................kppppppppppppppppppppppk.....kk',
    [66] = '....................kppppppk.....kppppppk',
    [67] = '....................kppppppk.....kppppppk',
    [68] = '....................kppppppk.....kppppppk',
    [69] = '....................kppppppk.....kppppppk',
    [70] = '....................kppppppk.....kppppppk',
    [71] = '....................kppppppk.....kppppppk',
    [72] = '....................kppppppk.....kppppppk',
    [73] = '....................kppppppk.....kppppppk',
    [74] = '....................kppppppk.....kppppppk',
    [75] = '....................kppppppk.....kppppppk',
    [76] = '....................kppppppk.....kppppppk',
    [77] = '....................kppppppk.....kppppppk',
    [78] = '....................kppppppk.....kppppppk',
    [79] = '....................kppppppk.....kppppppk',
    [80] = '....................kppppppk.....kppppppk',
    [81] = '....................kppppppk.....kppppppk',
    [82] = '....................kppppppk.....kppppppk',
    -- tamancos de couro fechado, sola de madeira baixa
    [83] = '...................kbbbbbbk.....kbbbbbbk',
    [84] = '...................kbbbbbbk.....kbbbbbbk',
    [85] = '...................kbbbbbbk.....kbbbbbbk',
    [86] = '...................kbbbbbbk.....kbbbbbbk',
    [87] = '...................kbbbbbbk.....kbbbbbbk',
    [88] = '...................kbbbbbbk.....kbbbbbbk',
    [89] = '...................kbbbbbbk.....kbbbbbbk',
    [90] = '...................kbbbbbbk.....kbbbbbbk',
    [91] = '..................kbbbbbbbbk...kbbbbbbbbk',
    [92] = '..................kbbbbbbbbk...kbbbbbbbbk',
    [93] = '..................kooooooook..kooooooook',
    [94] = '..................kkkkkkkkkk..kkkkkkkkkk',
}

--------------------------------------------------------------------------------
-- GARB: avental cru QUADRADO 'a' com bordas 'A' (âncora) + toalha
-- 'T'/'t' listrada caindo do ombro esquerdo (âncora).
--------------------------------------------------------------------------------
local apron = {
    [40] = '......................kAAAAAAAAAAAAAAAAk',
    [41] = '......................kaaaaaaaaaaaaaaaak',
    [42] = '......................kaaaaaaaaaaaaaaaak',
    [43] = '......................kaaaaaaaaaaaaaaaak',
    [44] = '......................kaaaaaaaaaaaaaaaak',
    [45] = '......................kaaaaaaaaaaaaaaaak',
    [46] = '......................kaaaaaaaaaaaaaaaak',
    [47] = '......................kaaaaaaaaaaaaaaaak',
    [48] = '......................kaaaaaaaaaaaaaaaak',
    [49] = '......................kaaaaaaaaaaaaaaaak',
    [50] = '......................kaaaaaaaaaaaaaaaak',
    [51] = '......................kaaaaaaaaaaaaaaaak',
    [52] = '......................kaaaaaaaaaaaaaaaak',
    [53] = '......................kaaaaaaaaaaaaaaaak',
    [54] = '......................kaaaaaaaaaaaaaaaak',
    [55] = '......................kaaaaaaaaaaaaaaaak',
    [56] = '......................kaaaaaaaaaaaaaaaak',
    [57] = '......................kaaaaaaaaaaaaaaaak',
    [58] = '......................kaaaaaaaaaaaaaaaak',
    [59] = '......................kaaaaaaaaaaaaaaaak',
    [60] = '......................kaaaaaaaaaaaaaaaak',
    [61] = '......................kaaaaaaaaaaaaaaaak',
    [62] = '......................kaaaaaaaaaaaaaaaak',
    [63] = '......................kaaaaaaaaaaaaaaaak',
    [64] = '......................kaaaaaaaaaaaaaaaak',
    [65] = '......................kaaaaaaaaaaaaaaaak',
    [66] = '......................kaaaaaaaaaaaaaaaak',
    [67] = '......................kaaaaaaaaaaaaaaaak',
    [68] = '......................kaaaaaaaaaaaaaaaak',
    [69] = '......................kaaaaaaaaaaaaaaaak',
    [70] = '......................kaaaaaaaaaaaaaaaak',
    [71] = '......................kaaaaaaaaaaaaaaaak',
    [72] = '......................kaaaaaaaaaaaaaaaak',
    [73] = '......................kAAAAAAAAAAAAAAAAk',
}

local towel = {
    [32] = '..............kTTk',
    [33] = '..............kTTk',
    [34] = '..............kTtk',
    [35] = '..............kTTk',
    [36] = '..............kTTk',
    [37] = '..............kTtk',
    [38] = '..............kTTk',
    [39] = '..............kTTk',
    [40] = '..............kTtk',
    [41] = '..............kTTk',
    [42] = '..............kTTk',
    [43] = '..............kTtk',
    [44] = '..............kTTk',
    [45] = '..............kTTk',
    [46] = '..............kTtk',
    [47] = '..............kTTk',
    [48] = '..............kTTk',
    [49] = '..............kTtk',
    [50] = '..............kTTk',
    [51] = '..............kTTk',
    [52] = '..............kTtk',
    [53] = '..............kTTk',
    [54] = '..............kTTk',
    [55] = '..............kTtk',
    [56] = '..............kTTk',
    [57] = '..............kTTk',
    [58] = '..............kTtk',
    [59] = '..............kTTk',
    [60] = '..............kttk',
    [61] = '...............kk',
}

local garb = overlay(R(apron), R(towel))

return {
    name = 'npc_bento_s',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},  -- oliva média
        S = {ramp = 'skin', step = 4, h = 12},
        d = {ramp = 'skin', step = 2, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 3, h = 11},  -- castanho acinzentado
        F = {ramp = 'bone', step = 5, h = 12},  -- faixa de pano (âncora)
        u = {ramp = 'hair', step = 2, h = 11},  -- bigode fino
        g = {ramp = 'moss', step = 3, h = 6},   -- camisa verde musgo
        G = {ramp = 'moss', step = 2, h = 6},
        v = {ramp = 'clothWarm', step = 2, h = 6}, -- colete vinho gasto
        a = {ramp = 'bone', step = 4, h = 7},   -- avental cru quadrado
        A = {ramp = 'bone', step = 3, h = 7},
        T = {ramp = 'plaster', step = 6, h = 7}, -- toalha listrada
        t = {ramp = 'plaster', step = 4, h = 7},
        p = {ramp = 'earth', step = 3, h = 4},  -- calças
        c = {ramp = 'wood', step = 5, h = 7},   -- concha
        b = {ramp = 'wood', step = 3, h = 2},   -- tamancos
        o = {ramp = 'wood', step = 5, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 57)),
        }},
        {name = 'garb', h = 7, albedo = {garb, garb}},
    },
}
