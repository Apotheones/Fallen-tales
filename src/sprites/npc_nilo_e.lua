-- NILO — idle LESTE (perfil olhando para a direita), 64x96, 4f.
-- f1 repouso, f2 respiro, f3 gesto (punho sobre o instrumento),
-- f4 variante (cabeça inclina 1px sobre a peça).
-- npc_nilo_w = espelho via código.
-- Perfil: massa de cabelo cobre metade de trás da cabeça e a mecha
-- alta desponta do topo-frontal (âncora); rosto oval com nariz
-- pequeno; colete 'v' em perfil com camisa 'y' na abertura da
-- frente; o bolso retangular 'B' lê na barriga; o instrumento 'W'
-- pendura na frente da mão direita. Perna longe 'P', perto 'p'.

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
-- Variante por linhas: rows sobrescreve o mapa base.
local function patch(map, rows)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(rows) do t[r] = s end
    return t
end
-- Deslocamento horizontal por faixa de linhas (cabeça que inclina).
local function hshift(map, dx, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if s and rmin and r >= rmin and r <= rmax then
            if dx > 0 then t[r] = (string.rep('.', dx) .. s):sub(1, 64)
            elseif dx < 0 then t[r] = s:sub(-dx + 1)
            else t[r] = s end
        else t[r] = s end
    end
    return t
end

local body = {
    [6]  = '................................kk',
    [7]  = '...............................khhk',
    [8]  = '...............................khhk',
    [9]  = '..............................khhhk',
    [10] = '...........................kkhhhhhhkk',
    [11] = '..........................khhhhhhhhhhk',
    [12] = '.........................khhhhhhhhhhhhk',
    [13] = '.........................khhhHhhhhHhhhk',
    [14] = '........................khhhhhhhhhhhhhhk',
    [15] = '........................khhhhhhhhhhhhhhk',
    [16] = '........................khhhhhssssssssk',
    [17] = '........................khhhhssssssssk',
    [18] = '........................khhhhssssssesk',
    [19] = '........................khhhhsssssssk',
    [20] = '........................khhhhssssssssk',  -- nariz pequeno
    [21] = '........................khhhhssssssdsk',
    [22] = '........................khhhhssssddsk',
    [23] = '........................khhhhsssssssk',
    [24] = '........................khhhhssssssk',
    [25] = '.........................khhsssssk',
    [26] = '.........................khhsssk',
    [27] = '..........................ksssk',
    [28] = '...........................kyyyyk',
    [29] = '..........................kyyyyyyyyk',
    [30] = '.........................kyyyyyyyyyyk',
    [31] = '.........................kvvyyyyyyyyvk',
    [32] = '........................kvvvyyyyyyyvvk',
    [33] = '........................kvvvyyyyyyyvvk',
    [34] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [35] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [36] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [37] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [38] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [39] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [40] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [41] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [42] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [43] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [44] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [45] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [46] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [47] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [48] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [49] = '.....................kyyk.kvvvyyyyyyyvvk.kyyk',
    [50] = '.....................kyyk.kvvvvyyyyyvvvk.kyyk',
    [51] = '.....................kyyk.kyyyyyyyyyyyyk.kyyk',
    [52] = '.....................kyyk.kyyyyyyyyyyyyk.kyyk',
    [53] = '.....................kyyk.kyyyyyyyyyyyyk.kyyk',
    [54] = '.....................kyyk.kyyyyyyyyyyyyk.kyyk',
    [55] = '.....................kddk.kyyyyyyyyyyyyk.kssk',
    [56] = '.....................kddk.krrrrrrrrrrrrk.kssk',
    [57] = '.....................kddk.kppppppppppppk.kssk',
    [58] = '.....................kddk.kppppppppppppk.kwk',
    [59] = '.....................kkkk.kppppppppppppk.kwk',
    [60] = '..........................kpppppppkpppppkkWWk',
    [61] = '..........................kpppppppkpppppkWWWWk',
    [62] = '..........................kPPPPPpkpppppkWWxWWk',
    [63] = '..........................kPPPPPpkpppppkWWWWk',
    [64] = '..........................kPPPPPpkpppppkWWWWk',
    [65] = '..........................kPPPPPpkpppppk.kWWk',
    [66] = '..........................kPPPPPpkpppppk..kk',
    [67] = '..........................kPPPPPpkpppppk',
    [68] = '..........................kPPPPPpkpppppk',
    [69] = '..........................kPPPPPpkpppppk',
    [70] = '..........................kPPPPPpkpppppk',
    [71] = '..........................kPPPPPpkpppppk',
    [72] = '..........................kPPPPPpkpppppk',
    [73] = '..........................kPPPPPpkpppppk',
    [74] = '..........................kPPPPPpkpppppk',
    [75] = '..........................kPPPPPpkpppppk',
    [76] = '..........................kPPPPPpkpppppk',
    [77] = '..........................kPPPPPpkpppppk',
    [78] = '..........................kPPPPPpkpppppk',
    [79] = '..........................kPPPPPpkpppppk',
    [80] = '..........................kPPPPPpkpppppk',
    [81] = '..........................kPPPPPpkpppppk',
    [82] = '..........................kCCCCCkCCCCCk',
    [83] = '..........................kCCCCCkCCCCCk',
    [84] = '..........................kCCCCCkCCCCCk',
    [85] = '..........................kDDDDkbbbbbk',
    [86] = '..........................kDDDDkbbbbbk',
    [87] = '..........................kDDDDkbbbbbk',
    [88] = '..........................kDDDDkbbbbbk',
    [89] = '..........................kDDDDkbbbbbk',
    [90] = '..........................kDDDDkbbbbbk',
    [91] = '..........................kDDDDkbbxxbk',
    [92] = '..........................kDDDDkbbxxbk',
    [93] = '..........................kooookoooook',
    [94] = '..........................kkkkkkkkkkk',
}

local gear = {
    -- bolso retangular claro na barriga (âncora, frente do colete)
    [50] = '............................kBBBBBBk',
    [51] = '............................kBbbbbBk',
    [52] = '............................kBbbbbBk',
    [53] = '............................kBbbbbBk',
    [54] = '............................kBbbbbBk',
    [55] = '............................kBBBBBBk',
}

--------------------------------------------------------------------------------
-- f3 — gesto: o punho da frente desliza para o instrumento pendurado,
-- manga desce cobrindo onde a mão pendia.
--------------------------------------------------------------------------------
local bodyGesto = patch(body, {
    [55] = '.....................kddk.kyyyyyyyyyyyyk.kyyk',
    [56] = '.....................kddk.krrrrrrrrrrrrk.kyyk',
    [57] = '.....................kddk.kppppppppppppk.kyyk',
    [58] = '.....................kddk.kppppppppppppk.kssk',
    [59] = '.....................kkkk.kppppppppppppk.kssk',
})

--------------------------------------------------------------------------------
-- f4 — variante: cabeça inclina 1px à frente, sobre a peça.
--------------------------------------------------------------------------------
local bodyMecha = hshift(body, 1, 6, 27)

return {
    name = 'npc_nilo_e',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 5, h = 11},
        S = {ramp = 'skin', step = 6, h = 12},
        d = {ramp = 'skin', step = 4, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 2, h = 11},
        H = {ramp = 'hair', step = 4, h = 12},
        y = {ramp = 'gold', step = 5, h = 6},
        v = {ramp = 'sea', step = 3, h = 6},
        B = {ramp = 'bone', step = 5, h = 8},
        b = {ramp = 'earth', step = 2, h = 2},
        r = {ramp = 'earth', step = 2, h = 5},
        p = {ramp = 'earth', step = 3, h = 4},
        P = {ramp = 'earth', step = 2, h = 3},   -- perna de trás
        C = {ramp = 'earth', step = 5, h = 5},
        x = {ramp = 'hair', step = 1, h = 3},
        w = {ramp = 'wood', step = 4, h = 7},
        W = {ramp = 'wood', step = 5, h = 7},
        D = {ramp = 'earth', step = 1, h = 2},
        o = {ramp = 'earth', step = 4, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 28, 54)),
            R(bodyGesto),
            R(bodyMecha),
        }},
        {name = 'gear', h = 8, albedo = {
            R(gear),
            R(gear),
            R(gear),
            R(gear),
        }},
    },
}
