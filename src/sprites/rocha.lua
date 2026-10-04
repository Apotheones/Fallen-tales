-- ROCHA de afloramento — prop de chão, 64x96, origem nos pés.
-- Encosta do Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §4, relevo =
-- leitura de material): pedra grande da encosta, faces quebradas em
-- planos — topo claro onde o sol bate, face média, sombra fria à
-- direita — com musgo tomando a crista e caindo em dedos pelas fendas.
-- Relevo: crista/musgo 10-11, faces 8-9, sombra 7, base 4-6, chão 1-2.

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

local rocha = {
    -- crista: musgo tomando o topo
    [30] = '..........................gggggggggg',
    [31] = '........................ggggggyggggggg',
    [32] = '.......................ggggygggggggggggg',
    [33] = '......................gggggggggggyggggggg',
    [34] = '.....................ggggggGggggggggggggg',
    [35] = '....................ggggggggGggggggggggggg',
    [36] = '....................gggGggggggggggGggggggg',
    [37] = '...................gggggggggggggggggGggggg',
    [38] = '..................ggGggggggggggggggggggggg',
    [39] = '..................gggggggGggggggggggggggGgg',
    -- dedos de musgo caindo sobre a face clara
    [40] = '.................gggggggggggggggggggggggggg',
    [41] = '.................gGSgggggggggggGgggggggggGg',
    [42] = '.................SSSgggggggggggggggggggggSg',
    [43] = '................SSSSSgggggggggggggggggSSSS',
    [44] = '................SSSSSSggggggggggggggSSSSSSS',
    [45] = '...............SSSSSSSSgggggggggggSSSSSSSSS',
    -- faces: 'S' clara alto-esquerda, 's' média, 'o' sombra direita
    [46] = '...............SSSSSSSSSggggggggSSSSSSSSoo',
    [47] = '..............SSSSSSSSSSSgggggSSSSSSSSSoooo',
    [48] = '..............SSSSSSSSSSSSgggSSSSSSSSSSooooo',
    [49] = '.............SSSSSSSSSSSSSSSSSSSSSSSSSooooooo',
    [50] = '.............SSSSSSSSSSSSSSSSSSSSSSSSSoooooooo',
    [51] = '............SSSSSSSSSSSSSSSSsSSSSSSSSSSoooooooo',
    [52] = '............SSSSSSSSSSSSSSSsssSSSSSSSSooooooooo',
    [53] = '...........SSSSSSSSSSSSSSSsssssSSSSSSoooooooooo',
    [54] = '...........SSSSSSSSSSSSSSsssssssSSSSSoooooooooo',
    [55] = '..........SSSSSSSSSSSSSSssssssssSSSSSooooooooooo',
    [56] = '..........SSSSSSSSSSSSSssssssssssSSSSSooooooooooo',
    [57] = '..........SSSSSSSSSSSSsssssssssssssSSSSooooooooo',
    [58] = '.........SSSSSSSSSSSSSsssssssssssssssSSSooooooooo',
    [59] = '.........SSSSSSSSSSSSsssssssssssssssssSSoooooooooo',
    [60] = '.........SSSSSSSSSSSssssssssssssssssssoooooooooooo',
    [61] = '........SSSSSSSSSSSssskssssssssssssssssooooooooooo',
    [62] = '........SSSSSSSSSSsssskssssssssssssssssoooooooooooo',
    [63] = '........SSSSSSSSSSsssskkssssssssssssssooooooooooooo',
    [64] = '.......SSSSSSSSSSssssskssssssssssssssssooooooooooooo',
    [65] = '.......SSSSSSSSSsssssssksssssssssssssssddooooooooooo',
    [66] = '.......SSSSSSSSSssssssskssssssssssssssdddooooooooooo',
    [67] = '......SSSSSSSSSSssssssskssssssssssssdddddooooooooooo',
    [68] = '......SSSSSSSSssssssssskssssssssssssdddddoooooooooooo',
    [69] = '......SSSSSSSSssssssssskssssssssssddddddoooooooooooo',
    [70] = '.....SSSSSSSSSssssssssssssssssssssdddddddoooooooooooo',
    [71] = '.....SSSSSSSSsssssssssssssssssssssdddddddooooooooooooo',
    [72] = '.....SSSSSSSssssssssssssssssssssdddddddddooooooooooooo',
    [73] = '....SSSSSSSSssssssssssssssssssssdddddddddoooooooooooooo',
    [74] = '....SSSSSSSssssssssssssssssssssddddddddddooooooooooooo',
    [75] = '....SSSSSSsssssssssssssssssssssddddddddddoooooooooooooo',
    [76] = '....SSSSSsssssssssssssssssssssdddddddddddddooooooooooo',
    [77] = '...SSSSSSssssssssssssssssssssddddddddddddddooooooooooo',
    [78] = '...SSSSSssssssssssssssssssssdddddddddddddddooooooooooo',
    [79] = '...SSSSsssssssssssssssssssssddddddddddddddddoooooooooo',
    -- base: sombra de contato e rodapé
    [80] = '...SSSssssssssssssssssssssdddddddddddddddddoooooooooo',
    [81] = '...SSssssssssssssssssssssddddddddddddddddddooooooooo',
    [82] = '...Sssssssssssssssssssssdddddddddddddddddddddoooooo',
    [83] = '...sssssssssssssssssssssddddddddddddddddddddddooo',
    [84] = '...ssssssssssssssssssssdddddddddddddddddddddddoo',
    [85] = '....ssssssssssssssssssddddddddddddddddddddddd',
    [86] = '....sssssssssssssssssdddddddddddddddddddddd',
    [87] = '.....ssssssssssssssdddddddddddddddddddddd',
    [88] = '.....sssssssssssssddddddddddddddddddddd',
    [89] = '......ssssssssssdddddddddddddddddddd',
    [90] = '.......ssssssssdddddddddddddddddd',
    [91] = '........sssssdddddddddddddddd',
    [92] = '.........sssddddddddddddd',
}

local chao = {
    -- terra, fragmentos e tufo de relva ao redor da rocha
    [86] = '...........................................................oe',
    [87] = '.e............................e.........................e',
    [88] = '..e....o........e......e.............e..........e..e',
    [89] = 'e...e.....e..........e......o..e..........e.......e',
    [90] = '.e....e......g..e.......e........e.....e......e',
    [91] = '....e....e..g.g.....e.......e.....g..e....e..e',
    [92] = 'e......e..gGgg.e......e.....e.....e.g.g......e',
    [93] = '..e...e...gggge..e......e....e.....gGg.e...e',
    [94] = '.e....e....ege.....e....e.....e....ge.....e',
    [95] = '....e.....e....e.....e.....e....e.....e',
    [96] = '.e.....e.....e....e.....e.....e....e.',
}

return {
    name = 'rocha',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        -- musgo da crista
        g = {ramp = 'moss', step = 4, h = 11},
        G = {ramp = 'moss', step = 2, h = 11},
        y = {ramp = 'moss', step = 5, h = 11},
        -- faces da pedra: clara, média, sombra fria, fundo
        S = {ramp = 'stone', step = 6, h = 10},
        s = {ramp = 'stone', step = 4, h = 9},
        o = {ramp = 'stone', step = 2, h = 8},
        d = {ramp = 'stone', step = 1, h = 6},
        k = {spec = 'ink', h = 7},
        -- chão
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'rocha', h = 8, albedo = R(rocha)},
        {name = 'chao', h = 1, albedo = R(chao)},
    },
}
