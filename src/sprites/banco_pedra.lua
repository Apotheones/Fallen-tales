-- BANCO DE PEDRA — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, "chegaram depois"):
-- o banco mais antigo/pesado — laje única de pedra sobre dois pés de
-- alvenaria. Sem encosto, silhueta baixa e monolítica; topo gasto e
-- claro onde gerações sentaram, musgo nas juntas dos pés.
-- Relevo: laje 6-8, pés 4-5, musgo 5-6, chão 1-2.

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
    -- laje: fio de trás, superfície gasta (mancha clara 'u' de uso),
    -- filete claro da borda frontal e face espessa com rodapé escuro
    [46] = '..........SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS',
    [47] = '..........tttttttttttttttttttttttttttttttttttttttttt',
    [48] = '.........tttttttttuuuuuuttttttttttttttuuuutttttttttt',
    [49] = '.........tttttttuuuuuuuuutttttttttttuuuuuutttttttttt',
    [50] = '........tttttttuuuuuuuuuuttttttttttuuuuuuutttttttttt',
    [51] = '........ttsttttuuuuuuuuuutttsttttttuuuuuuttttttstttt',
    [52] = '........tttttttuuuuuuuuutttttttttttuuuuutttttttttttt',
    [53] = '........tttttttttuuuuuuttttttgttttttuuuttttttttttttt',
    [54] = '........tsttttttttuuutttttttggttttttttttttsttttttttt',
    [55] = '........ttttttttttttttttttttgggttttttttttttttttttttt',
    [56] = '........SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS',
    [57] = '........bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    [58] = '........bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    [59] = '........bbbbbkbbbbbbbbbbbbbbbbbbbbbbbbbbkbbbbbbbbbbb',
    [60] = '........bbbbbbkbbbbbbbbbbbbbbbbbbbbbbbkbbbbbbbbbbbbb',
    [61] = '........dddddddddddddddddddddddddddddddddddddddddddd',
    [62] = '........dddddddddddddddddddddddddddddddddddddddddddd',
    -- pés de alvenaria: dois blocos com juntas 'm' e musgo 'g/G'
    [63] = '...........kbbbbbbbk....................kbbbbbbbk',
    [64] = '...........kbbbbBbbk....................kbbbBbbbk',
    [65] = '...........kbbbbbbbk....................kbbbbbbbk',
    [66] = '...........kmmmmmmmk....................kmmmmmmmk',
    [67] = '...........kbbbBbbbk....................kbbBbbbbk',
    [68] = '...........kbbbbbbbk....................kbbbbbbbk',
    [69] = '...........kbbbbbbbk....................kbbbbbgbk',
    [70] = '...........kmmmmmmmk....................kmmmmgmmk',
    [71] = '...........kbbbbbggk....................kbbbggbbk',
    [72] = '...........kbbbbgggk....................kbbgggbbk',
    [73] = '...........kbBbbgggk....................kbBgggbbk',
    [74] = '...........kmmmmmmmk....................kmmmmmmmk',
    [75] = '...........kbbbbbbbk....................kbbbbbbbk',
    [76] = '...........kbBbbbbbk....................kbbBbbbbk',
    [77] = '...........kbbbbbbbk....................kbbbbbbbk',
    [78] = '...........kmmmmmmmk....................kmmmmmmmk',
    [79] = '...........kbbbbbbbk....................kbbbbbbbk',
    [80] = '...........kbbbbBbbk....................kbbbbBbbk',
    [81] = '...........kbbbbbbbk....................kbbbbbbbk',
    [82] = '...........kdddddddk....................kdddddddk',
    [83] = '...........kdddddddk....................kdddddddk',
    -- base: junta de sombra e chão
    [84] = '...........mmmmmmmmm....................mmmmmmmmm',
    [85] = '..........e..e....e......e.....e......e..e.....e',
    [86] = '.........e.....g..e...e.....e.....e...g....e',
    [87] = '...........e..e....e.....e....e.....e...e',
    [88] = '......e......e....e.....e.....e......e',
}

return {
    name = 'banco_pedra',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        -- laje: fio claro, topo, mancha de uso (gasto e liso), face, base
        S = {ramp = 'stone', step = 6, h = 8},
        t = {ramp = 'stone', step = 4, h = 7},
        s = {ramp = 'stone', step = 3, h = 7},
        u = {ramp = 'stone', step = 6, h = 7},
        b = {ramp = 'stone', step = 4, h = 6},
        B = {ramp = 'stone', step = 5, h = 6},
        m = {ramp = 'stone', step = 2, h = 5},
        d = {ramp = 'stone', step = 2, h = 4},
        -- musgo e chão
        g = {ramp = 'moss', step = 3, h = 6},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'banco', h = 5, albedo = R(banco)},
    },
}
