-- TECA — costureira, idle SUL, 64x96, origem nos pés, 2f.
-- §5 do doc de personagens: 51-57a, 158cm — a mais baixa do elenco;
-- corpo estreito de quadris largos: TRIÂNGULO comprido (ombros ~14px,
-- barra ~28px). Pele castanha clara dourada (skin.4), rosto
-- comprido, sobrancelhas baixas. Cabelo preto grisalho 'h' com fios
-- 'G' preso em NÓ BAIXO LATERAL à esquerda (âncora). Vestido de lã
-- azul acinzentada 'w' descendo até os pés; sobressaia curta cor de
-- barro 'o' sobre os quadris (a barra azul comprida aparece por
-- baixo — âncora); ponta de XALE claro 'x' presa na cintura,
-- caindo em bico pela direita (âncora); punhos de linho claro 'l'.
-- Âncoras: nó lateral baixo | ponta de xale presa | barra azul
-- longa sobre saia barro.

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
-- BODY: cabeça com nó lateral, tronco e saia do vestido 'w' em
-- triângulo. Sobressaia e xale ficam na camada 'garb'.
--------------------------------------------------------------------------------
local body = {
    -- cabelo preto grisalho; nó baixo na lateral esquerda (âncora)
    [14] = '............................kkkkkk',
    [15] = '...........................khhhhhhk',
    [16] = '.........................khhhhhhhhhhk',
    [17] = '.........................khhGhhhhhGhk',
    [18] = '.........................khhhhhhhhhhk',
    [19] = '.........................khsssssssshk',
    -- o nó: massa de cabelo saltando junto à mandíbula esquerda
    [20] = '.....................khhkkhssssssshk',
    [21] = '....................khhhkksseesssseek',
    [22] = '....................khhGkssssssssssk',
    [23] = '....................khhhkssssdsssssk',
    [24] = '....................khhhksssddsssssk',
    [25] = '.....................khhkssssssssssk',
    [26] = '.....................khhk.kssssssssk',
    [27] = '......................kk..kssssssssk',
    [28] = '..........................kssssssk',
    [29] = '..........................kssssssk',
    [30] = '............................kssssk',
    -- ombros estreitos; vestido azul-cinza em tronco curto
    [31] = '...........................kwwwwwwk',
    [32] = '..........................kwwwwwwwwk',
    [33] = '.........................kwwwwwwwwwwk',
    [34] = '........................kwwwwwwwwwwwwk',
    [35] = '.......................kwwwwwwwwwwwwwwk',
    [36] = '.......................kwwwwwwwwwwwwwwk',
    -- braços finos de manga 'w', punhos de linho 'l', mãos 's'
    [37] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [38] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [39] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [40] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [41] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [42] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [43] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [44] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [45] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [46] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [47] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [48] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [49] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [50] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [51] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [52] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [53] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [54] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [55] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [56] = '..................kllk.kwwwwwwwwwwwwwwk.kllk',
    [57] = '..................kllk.kwwwwwwwwwwwwwwk.kllk',
    [58] = '..................kssk.kwwwwwwwwwwwwwwk.kssk',
    [59] = '..................kssk.kwwwwwwwwwwwwwwk.kssk',
    [60] = '..................kkkk.kwwwwwwwwwwwwwwk.kkkk',
    -- saia em triângulo: abre ~1px por lado a cada 4 linhas
    [61] = '.......................kwwwwwwwwwwwwwwk',
    [62] = '.......................kwwwwwwwwwwwwwwk',
    [63] = '.......................kwwwwwwwwwwwwwwk',
    [64] = '.......................kwwwwwwwwwwwwwwk',
    [65] = '......................kwwwwwwwwwwwwwwwwk',
    [66] = '......................kwwwwwwwwwwwwwwwwk',
    [67] = '......................kwwwwwwwwwwwwwwwwk',
    [68] = '......................kwwwwwwwwwwwwwwwwk',
    [69] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [70] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [71] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [72] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [73] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [74] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [75] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [76] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [77] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [78] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [79] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [80] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [81] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [82] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [83] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [84] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [85] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [86] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [87] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [88] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    -- barra do vestido + pontas dos sapatos macios
    [89] = '.................kWWWWWWWWWWWWWWWWWWWWWWWWk',
    [90] = '.................kkkkkkkkkkkkkkkkkkkkkkkkkk',
    [91] = '..........................kbbk.....kbbk',
    [92] = '..........................kbbk.....kbbk',
    [93] = '..........................kbbk.....kbbk',
    [94] = '..........................kkkk.....kkkk',
}

--------------------------------------------------------------------------------
-- GARB: sobressaia cor de barro 'o' sobre os quadris + xale 'x'
-- cobrindo os ombros e com ponta presa na cintura à direita.
--------------------------------------------------------------------------------
local overskirt = {
    [52] = '.......................koooooooooooooooook',
    [53] = '.......................koooooooooooooooook',
    [54] = '.......................koooooooooooooooook',
    [55] = '.......................koooooooooooooooook',
    [56] = '.......................koooooooooooooooook',
    [57] = '.......................koooooooooooooooook',
    [58] = '.......................koooooooooooooooook',
    [59] = '......................kooooooooooooooooook',
    [60] = '......................kooooooooooooooooook',
    [61] = '......................kooooooooooooooooook',
    [62] = '......................kooooooooooooooooook',
    [63] = '......................kooooooooooooooooook',
    [64] = '......................kooooooooooooooooook',
    [65] = '.....................kooooooooooooooooooook',
    [66] = '.....................kooooooooooooooooooook',
    [67] = '.....................kooooooooooooooooooook',
    [68] = '.....................kooooooooooooooooooook',
    [69] = '.....................kooooooooooooooooooook',
    [70] = '.....................kooooooooooooooooooook',
    [71] = '.....................kooooooooooooooooooook',
    [72] = '.....................kOOOOOOOOOOOOOOOOOOOOk',
}

local xale = {
    -- faixa clara sobre os ombros, abrindo em V no peito
    [33] = '.........................kxxxxxxxxxxxxk',
    [34] = '........................kxxxxxxxxxxxxxxk',
    [35] = '........................kxxxxxxxxxxxxxxk',
    [36] = '.......................kxxxkwwwwwwkxxxk',
    [37] = '.......................kxxkwwwwwwwwkxxk',
    [38] = '.......................kxxkwwwwwwwwkxxk',
    [39] = '........................kxkwwwwwwwwkxk',
    -- ponta presa na cintura, caindo em bico à direita (âncora)
    [50] = '........................................kxxk',
    [51] = '........................................kxxk',
    [52] = '........................................kxxk',
    [53] = '........................................kxxk',
    [54] = '........................................kxxk',
    [55] = '.........................................kxk',
    [56] = '.........................................kxk',
    [57] = '..........................................kk',
}

local garb = overlay(R(overskirt), R(xale))

return {
    name = 'npc_teca_s',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 4, h = 11},  -- castanha clara dourada
        S = {ramp = 'skin', step = 5, h = 12},
        d = {ramp = 'skin', step = 3, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 2, h = 11},  -- preto grisalho
        G = {ramp = 'iron', step = 5, h = 12},  -- fios grisalhos
        w = {ramp = 'sea', step = 3, h = 5},    -- lã azul acinzentada
        W = {ramp = 'sea', step = 2, h = 4},    -- barra em sombra
        l = {ramp = 'plaster', step = 5, h = 6},-- punhos de linho
        o = {ramp = 'clothWarm', step = 3, h = 6}, -- sobressaia barro
        O = {ramp = 'clothWarm', step = 2, h = 6},
        x = {ramp = 'plaster', step = 5, h = 7}, -- xale claro
        b = {ramp = 'earth', step = 2, h = 2},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 55)),
        }},
        {name = 'garb', h = 6, albedo = {garb, garb}},
    },
}
