-- BANCO DE MADEIRA entalhada — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, "feitos juntos"):
-- banco de carpintaria doméstica — encosto baixo com entalhe corrido,
-- assento de tábuas, quatro pernas torneadas simples e avental.
-- O mais "acabado" dos três bancos: juntas retas, madeira cuidada.
-- Relevo: encosto 8-9, assento 5-6, pernas 3-4, chão 1-2.

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

local banco = {
    -- encosto: travessa alta com fio claro e entalhe corrido em V
    [28] = '...........kWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk',
    [29] = '...........kwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [30] = '...........kwvvvwvvvwvvvwvvvwvvvwvvvwvvvwvvvwk',
    [31] = '...........kwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [32] = '...........kwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    -- montantes do encosto descendo ao assento
    [33] = '...........kwwk................................kwwk',
    [34] = '...........kwwk................................kwwk',
    [35] = '...........kwwk................................kwwk',
    [36] = '...........kwwk................................kwwk',
    [37] = '...........kwwk................................kwwk',
    [38] = '...........kwwk................................kwwk',
    [39] = '...........kwwk................................kwwk',
    [40] = '...........kwwk................................kwwk',
    [41] = '...........kwwk................................kwwk',
    [42] = '...........kwwk................................kwwk',
    [43] = '...........kwwk................................kwwk',
    [44] = '...........kwwk................................kwwk',
    [45] = '...........kwwk................................kwwk',
    -- assento: tábuas com veios e fio de luz na borda frontal
    [46] = '.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',
    [47] = '.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
    [48] = '.......wwwwvwwwwwwwwwwvwwwwwwwwwwvwwwwwwwwwvwwwwwwww',
    [49] = '.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
    [50] = '.......wwvwwwwwwvwwwwwwwwwvwwwwwwwwwvwwwwwwwwvwwwwww',
    [51] = '.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
    [52] = '.......wwwwwwwwvwwwwwwvwwwwwwwvwwwwwwvwwwwwwwwwwvwwww',
    [53] = '.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
    -- borda frontal e avental com entalhe em arco
    [54] = '.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',
    [55] = '.......FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
    [56] = '.......FFFFFvvFFFFvvFFFvvFFFFvvFFFFvvFFFvvFFFFvvFFFFFFF',
    [57] = '.......FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
    [58] = '.......kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    -- pernas: frente 'l' claras, trás 'q' escuras e recuadas
    [59] = '..........kllk............kqqk..........kqqk...........kllk',
    [60] = '..........kllk............kqqk..........kqqk...........kllk',
    [61] = '..........kllk............kqqk..........kqqk...........kllk',
    [62] = '..........kllk............kqqk..........kqqk...........kllk',
    [63] = '..........kllk............kqqk..........kqqk...........kllk',
    [64] = '..........kllk............kqqk..........kqqk...........kllk',
    [65] = '..........kllk............kqqk..........kqqk...........kllk',
    [66] = '..........kllk............kqqk..........kqqk...........kllk',
    [67] = '..........kllk............kqqk..........kqqk...........kllk',
    [68] = '..........kllk............kqqk..........kqqk...........kllk',
    [69] = '..........kllk............kqqk..........kqqk...........kllk',
    [70] = '..........kllk............kqqk..........kqqk...........kllk',
    -- travessa entre as pernas da frente
    [71] = '..........klllllllllllllllllllllllllllllllllllllllllllk',
    [72] = '..........kllk.......................................kllk',
    [73] = '..........kllk...........kqqk..........kqqk..........kllk',
    [74] = '..........kllk...........kqqk..........kqqk..........kllk',
    [75] = '..........kllk...........kqqk..........kqqk..........kllk',
    [76] = '..........kllk...........kqqk..........kqqk..........kllk',
    [77] = '..........kllk...........kqqk..........kqqk..........kllk',
    [78] = '..........kllk...........kqqk..........kqqk..........kllk',
    [79] = '..........kllk...........kqqk..........kqqk..........kllk',
    [80] = '..........kllk...........kqqk..........kqqk..........kllk',
    [81] = '..........kllk...........kqqk..........kqqk..........kllk',
    [82] = '..........kllk...........kqqk..........kqqk..........kllk',
    [83] = '..........kllk.......................................kllk',
    [84] = '..........kllk.......................................kllk',
    [85] = '..........kllk.......................................kllk',
    [86] = '..........kllk.......................................kllk',
    -- pés torneados (bojo) e contato com o chão
    [87] = '.........kllllk.....................................kllllk',
    [88] = '.........kllllk.....e..............e........e......kllllk',
    [89] = '..........kllk.......e.....e...........e............kllk',
    [90] = '...........ee.........e.........e..........e........ee',
    [91] = '.........e......e.........e...........e.....e',
    [92] = '............e.....e.....e.....e....e.....e',
}

return {
    name = 'banco_madeira',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        -- encosto e assento
        W = {ramp = 'wood', step = 6, h = 9},
        w = {ramp = 'wood', step = 4, h = 8},
        v = {ramp = 'wood', step = 2, h = 8},
        F = {ramp = 'wood', step = 3, h = 6},
        -- pernas
        l = {ramp = 'wood', step = 4, h = 4},
        q = {ramp = 'wood', step = 2, h = 3},
        -- chão
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'banco', h = 5, albedo = R(banco)},
    },
}
