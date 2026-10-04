-- BANCO DE SERRA — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO): o banco improvisado
-- — uma tábua rústica (ainda com casca numa borda e rachadura) apoiada
-- sobre dois tocos de tronco cortado, anéis à mostra nas faces de corte.
-- O mais cru dos três: medidas tortas, nada alinhado de propósito.
-- Relevo: tábua 5-6, tocos 4-5, anéis 5, chão 1-2.

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
    -- tábua: largura irregular, casca 'B' na borda frontal e rachadura
    [46] = '.....WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',
    [47] = '.....wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
    [48] = '....wwwwwvwwwwwwwwwvwwwwwwwwvwwwwwwwwwvwwwwwwvwwwwwwww',
    [49] = '....wwwwwwwwwwwwvwwwwwwwwwwwwwwwvwwwwwwwwwwwwwvwwwwwww',
    [50] = '....wwvwwwwwwwwwwwwwwwvwwwwwwkwwwwvwwwwwwvwwwwwwwwwww',
    [51] = '....wwwwwwwvwwwwvwwwwwwwwwwwkkwwwwwwvwwwwwwwwwwwwwwwww',
    [52] = '....wwwwwwwwwwwwwwvwwwwwwwwwkwwwwwwwwwvwwwwvwwwwwwwww',
    [53] = '....wwvwwwwvwwwwwwwwwwwwwwkkwwwvwwwwwwwwwwwwwvwwwwww',
    [54] = '....wwwwwwwwwwvwwwwvwwwwwkwwwwwwvwwwwwwwvwwwwwwwwwww',
    -- casca: tira escura irregular na borda frontal
    [55] = '....BqBBqBqBBqBBqBBqBBqBBqBBqBBqBBqBBqBBqBBqBBqBBqBB',
    [56] = '....qBqBqBBqBqBBqBqBBqBqBBqBqBBqBqBBqBqBBqBqBBqBqBBq',
    [57] = '.....kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    -- tocos: faces de corte com anéis 'n' concêntricos e casca 'b'
    [58] = '..........bbbbb..............................bbbbb',
    [59] = '.........bbwwwbb............................bbwwwbb',
    [60] = '........bbwwnwwbb..........................bbwwnwwbb',
    [61] = '........bwnnnnnwb..........................bwnnnnnwb',
    [62] = '.......bbwnnnnnnwbb........................bbwnnnnnnwbb',
    [63] = '.......bbwnnNnwnwbb........................bbwnnNnwnwbb',
    [64] = '.......bbwnnnnnnwbb........................bbwnnnnnnwbb',
    [65] = '........bwnnnnnwb..........................bwnnnnnwb',
    -- laterais dos tocos: casca em tiras verticais
    [66] = '.......bbbbbbbbbbbb........................bbbbbbbbbbbb',
    [67] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [68] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [69] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [70] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [71] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [72] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [73] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [74] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [75] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [76] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [77] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [78] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [79] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [80] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [81] = '.......bvbvbvbvbvbb........................bvbvbvbvbvbb',
    [82] = '.......bbbbbbbbbbbb........................bbbbbbbbbbbb',
    -- chão: terra e serragem sob os tocos
    [83] = '.......e.e...e..e.........e...e....e.....e....e',
    [84] = '......e..s..e....e...e......s...e....e..s..e',
    [85] = '....e...e.s...e....e....e....e..s..e...e',
    [86] = '.......e.....s...e....e....e.....e..s',
    [87] = '....e....e....e......e...e....e',
}

return {
    name = 'banco_serra',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        -- tábua: fio claro, corpo, veios; casca na borda frontal
        W = {ramp = 'wood', step = 6, h = 6},
        w = {ramp = 'wood', step = 4, h = 5},
        v = {ramp = 'wood', step = 2, h = 5},
        B = {ramp = 'wood', step = 1, h = 5},
        q = {ramp = 'wood', step = 3, h = 5},
        -- tocos: casca escura 'b', anéis claros 'n', cerne 'N'
        b = {ramp = 'wood', step = 2, h = 4},
        n = {ramp = 'wood', step = 5, h = 5},
        N = {ramp = 'wood', step = 6, h = 5},
        -- serragem e chão
        s = {ramp = 'wood', step = 6, h = 2},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'banco', h = 4, albedo = R(banco)},
    },
}
