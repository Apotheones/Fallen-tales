-- PARAPEITO do mirante — peça de parede, 64x64, origem topleft.
-- 2 frames = trechos por seed: (1) trecho reto, (2) trecho gasto —
-- mais liso onde as mãos apoiam e uma falha na quina da capa.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, "parapeito com
-- vista"): pedra baixa com a capa LISA de uso — o filete claro no
-- topo não é ornamento, é o lugar onde todo mundo se debruça.
-- Relevo: capa 9-11, uso liso 10, face 6-8, base 4.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)

local function R(map, h)
    local t = {}
    for r = 1, h do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end

-- FRAME 1 — trecho reto: capa com faixa gasta 'u' por apoio de mãos,
-- filete claro da quina, face em blocos com juntas desencontradas
local f1 = {
    [6] = 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
    [7] = 'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
    [8] = 'CccccccccccccuuuuuuuuuucccccccccccccccccccuuuuuuuucccccccccccC',
    [9] = 'CcccccccccccuuuuuuuuuuucccccccccccccccccuuuuuuuuuuccccccccccC',
    [10] = 'CccccccccccuuuuuuuuuuuuccccccccccccccccuuuuuuuuuuucccccccccC',
    [11] = 'CccccccccccuuuuuuuuuuuuccccccccccccccccuuuuuuuuuuucccccccccC',
    [12] = 'CcccccccccccuuuuuuuuuuucccccccccccccccccuuuuuuuuuucccccccccC',
    [13] = 'CccccccccccccuuuuuuuuuucccccccccccccccccccuuuuuuuucccccccccC',
    [14] = 'CccccccccccccccuuuuuucccccccccccccccccccccccUUcccccccccccccC',
    [15] = 'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
    -- quina iluminada e face da frente
    [16] = 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
    [17] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbbb',
    [18] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbbb',
    [19] = 'bbbBbbbbbbmbbbbbbbBbbbbbbbbmbbbbbbbbbbbbbbmbbbbbBbbbbbbbbbbbbb',
    [20] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbbb',
    [21] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbbb',
    [22] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm',
    [23] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbb',
    [24] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbb',
    [25] = 'bbbbbbmbbbbbBbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbBbbbbmbbbbbbbbbbb',
    [26] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbb',
    [27] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbb',
    [28] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm',
    [29] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbb',
    [30] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbb',
    [31] = 'bbbbbbbbbbbbmbbbbbbBbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbBbbbbbbbbb',
    [32] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbb',
    [33] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbb',
    [34] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm',
    [35] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [36] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [37] = 'bbbbbbmbbbbbbbBbbbbbmbbbbbbbbbbbbbbbbmbbbbbbBbbbbmbbbbbbbbbb',
    [38] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [39] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [40] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm',
    [41] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    [42] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    [43] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    [44] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
}

-- FRAME 2 — trecho gasto: a faixa de uso é mais larga e contínua, a
-- quina perde um pedaço (falha 'd' na capa) e uma trinca desce na face
local f2 = {
    [6] = 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
    [7] = 'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
    [8] = 'CcccccccccuuuuuuuuuuuuuuuuuucccccccccccccuuuuuuuuuuuuuuuuccC',
    [9] = 'CccccccccuuuuuuuuuuuuuuuuuuuucccccccccuuuuuuuuuuuuuuuuuuuccC',
    [10] = 'CcccccccuuuuuuuuuuuuuuuuuuuuuccccccccuuuuuuuuuuuuuuuuuuuuucC',
    [11] = 'CcccccccuuuuuuuuuuuuuuuuuuuuuccccccccuuuuuuuuuuuuuuuuuuuuucC',
    [12] = 'CccccccccuuuuuuuuuuuuuuuuuuuuccccccccuuuuuuuuuuuuuuuuuuucccC',
    [13] = 'CcccccccccuuuuuuuuuuuuuuuuucccccccccccuuuuuuuuuuuuuuuuccccC',
    [14] = 'CccccccccccuuuuuuuuUUuuuuccccccccccccccuuuuuuuuUUuucccccccC',
    [15] = 'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
    [16] = 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCddCCCCCCCCCCCCCCCCCCCCCCCCCC',
    [17] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbddddmbbbbbbbbbbbbbbbbbb',
    [18] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbdbbdmbbbbbbbbbbbbbbbbbb',
    [19] = 'bbbBbbbbbbmbbbbbbbBbbbbbbbbmbbbbbbbbdbbbdmbbbBbbbbbbbbbbbbbb',
    [20] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbdkbbbbbbbbbbbbbbbbb',
    [21] = 'bbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbkbbbbbbbbbbbbbbbbb',
    [22] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmkmmmmmmmmmmmmmmm',
    [23] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbkbmbbbbbbbbbbbb',
    [24] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbkmbbbbbbbbbbbbb',
    [25] = 'bbbbbbmbbbbbBbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbkmbbbbbbbbbbbbb',
    [26] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbkkmbbbbbbbbbbbb',
    [27] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbkmbbbbbbbbbbbb',
    [28] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmkmmmmmmmmmmmm',
    [29] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbkbbbbbbbbbb',
    [30] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbkbbbbbbbbbb',
    [31] = 'bbbbbbbbbbbbmbbbbbbBbbbbbbbbmbbbbbbbbbbbbbmbbbbbkbBbbbbbbbbb',
    [32] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbkbbbbbbbbb',
    [33] = 'bbbbbbbbbbbbmbbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbkbbbbbbbbb',
    [34] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm',
    [35] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [36] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [37] = 'bbbbbbmbbbbbbbBbbbbbmbbbbbbbbbbbbbbbbmbbbbbbBbbbbmbbbbbbbbbb',
    [38] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [39] = 'bbbbbbmbbbbbbbbbbbbbmbbbbbbbbbbbbbbbbmbbbbbbbbbbbbbmbbbbbbbbbb',
    [40] = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm',
    [41] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    [42] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    [43] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    [44] = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
}

return {
    name = 'parapeito',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        -- capa: topo, uso liso onde as mãos apoiam, quina clara
        C = {ramp = 'stone', step = 6, h = 11},
        c = {ramp = 'stone', step = 4, h = 10},
        u = {ramp = 'stone', step = 6, h = 9},
        U = {ramp = 'stone', step = 7, h = 9},
        -- face: blocos, bloco claro, junta, base e falha/trinca
        b = {ramp = 'stone', step = 4, h = 7},
        B = {ramp = 'stone', step = 5, h = 7},
        m = {ramp = 'stone', step = 2, h = 6},
        d = {ramp = 'stone', step = 2, h = 4},
        k = {spec = 'ink', h = 5},
    },

    layers = {
        {name = 'parapeito', h = 7, albedo = {R(f1, 64), R(f2, 64)}},
    },
}
