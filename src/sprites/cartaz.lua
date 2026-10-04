-- CARTAZ de avisos — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, motivo "nomes e
-- avisos"): quadro de tábuas em duas pernas com folha de papel presa
-- por quatro tachas — escrita estilizada em fileiras e o selo violeta
-- pequeno da casa no canto da folha.
-- Relevo: quadro 7-8, papel 9, selo 10, pernas 4, chão 1-2.

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

local quadro = {
    -- moldura do quadro: filete claro no topo, tábuas horizontais
    [24] = '............kWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk',
    [25] = '............kwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [26] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [27] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [28] = '............kwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwk',
    [29] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [30] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [31] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [32] = '............kwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwk',
    [33] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [34] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [35] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [36] = '............kwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwk',
    [37] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [38] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [39] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [40] = '............kwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwk',
    [41] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [42] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [43] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [44] = '............kwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwk',
    [45] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [46] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [47] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [48] = '............kwpppppppppppppppppppppppppppppppppppppwk',
    [49] = '............kVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVk',
    [50] = '.............kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    -- pernas do quadro
    [51] = '...............kllk........................kllk',
    [52] = '...............kllk........................kllk',
    [53] = '...............kllk........................kllk',
    [54] = '...............kllk........................kllk',
    [55] = '...............kllk........................kllk',
    [56] = '...............kllk........................kllk',
    [57] = '...............kllk........................kllk',
    [58] = '...............kllk........................kllk',
    [59] = '...............kllk........................kllk',
    [60] = '...............kllk........................kllk',
    [61] = '...............kllk........................kllk',
    [62] = '...............kllk........................kllk',
    [63] = '...............kllk........................kllk',
    [64] = '...............kllk........................kllk',
    [65] = '...............kllk........................kllk',
    [66] = '...............kllk........................kllk',
    [67] = '...............kllk........................kllk',
    [68] = '...............kllk........................kllk',
    [69] = '...............kllk........................kllk',
    [70] = '...............kllk........................kllk',
    [71] = '...............kllk........................kllk',
    [72] = '...............kllk........................kllk',
    [73] = '...............kllk........................kllk',
    [74] = '...............kllk........................kllk',
    [75] = '...............kllk........................kllk',
    [76] = '...............kllk........................kllk',
    [77] = '...............kllk........................kllk',
    [78] = '...............kllk........................kllk',
    [79] = '...............kllk........................kllk',
    [80] = '...............kllk........................kllk',
    [81] = '...............kllk........................kllk',
    [82] = '...............kllk........................kllk',
    [83] = '...............kllk........................kllk',
    [84] = '...............kllk........................kllk',
    [85] = '...............kllk........................kllk',
    [86] = '...............kllk........................kllk',
    [87] = '...............kllk........................kllk',
    [88] = '...............kllk........................kllk',
    [89] = '...............kllk........................kllk',
    [90] = '..............elkle......e........e........elkle',
    [91] = '.............e.e..e....e.....e..........e.e..e',
    [92] = '..............e......e....e......e...e...e',
    [93] = '........e....e....e.....e.....e.....e',
    [94] = '............e.....e......e....e',
}

-- folha de papel pregada no quadro: quatro tachas 'i', linhas de
-- escrita 'b' e o selo violeta 'V'/'z' no canto inferior direito
local papel = {
    [28] = '...................iPPPPPPPPPPPPPPPPPPPPi',
    [29] = '...................PPPPPPPPPPPPPPPPPPPPPP',
    [30] = '...................PPbbbbbbPPbbbbPPbbbbbP',
    [31] = '...................PPbbbbbbPPbbbbPPbbbbbP',
    [32] = '...................PPPPPPPPPPPPPPPPPPPPPP',
    [33] = '...................PPbbbbbPPbbbbbbPPbbbbP',
    [34] = '...................PPbbbbbPPbbbbbbPPbbbbP',
    [35] = '...................PPPPPPPPPPPPPPPPPPPPPP',
    [36] = '...................PPbbbbPPbbbPPbbbbbbPPP',
    [37] = '...................PPbbbbPPbbbPPbbbbbbPPP',
    [38] = '...................PPPPPPPPPPPPPPPPPPPPPP',
    [39] = '...................PPbbbbbPPbbbbbPPbbbPPP',
    [40] = '...................PPbbbbbPPbbbbbPPbbbPPP',
    [41] = '...................PPPPPPPPPPPPPPPPPPPPPP',
    [42] = '...................PPbbbbbbPPbbPPbbbbbPPP',
    [43] = '...................PPbbbbbbPPbbPPbbbbbPPP',
    [44] = '...................PPPPPPPPPPPPPPPPPPZZPPP',
    [45] = '...................PPPPPPPPPPPPPPPPZzzZPP',
    [46] = '...................iPPPPPPPPPPPPPPPZzzZPP',
    [47] = '...................PPPPPPPPPPPPPPPPPZZPPP',
    [48] = '...................PPPPPPPPPPPPPPPPPPzPPP',
}

return {
    name = 'cartaz',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 5},
        -- quadro: fio, tábuas, juntas, borda inferior, pernas
        W = {ramp = 'wood', step = 6, h = 8},
        w = {ramp = 'wood', step = 4, h = 7},
        p = {ramp = 'wood', step = 3, h = 7},
        v = {ramp = 'wood', step = 2, h = 7},
        V = {ramp = 'wood', step = 2, h = 6},
        l = {ramp = 'wood', step = 4, h = 4},
        -- papel e escrita
        P = {ramp = 'bone', step = 5, h = 9},
        b = {ramp = 'bone', step = 2, h = 9},
        i = {ramp = 'iron', step = 5, h = 10},
        -- selo violeta da casa (V = cera, z = fita)
        Z = {ramp = 'violet', step = 5, h = 10},
        z = {ramp = 'violet', step = 3, h = 10},
        -- chão
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'quadro', h = 6, albedo = R(quadro)},
        {name = 'papel', h = 9, albedo = R(papel)},
    },
}
