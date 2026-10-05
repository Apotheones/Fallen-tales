-- V12 NPC_JARDINEIRO_S — figurante da horta, idle SUL, 64x96 feet,
-- 4f. Upgrade C01-grade na mesma geometria (chapéu cols 20-45,
-- punhos cols 18-23/41-46 linhas 53-62) — npc_jardineiro_trabalho
-- assenta.
-- Âncoras: chapéu de palha aba larga (trama 'w' quebrada na aba,
-- sombra 'D' por baixo, coroa 'H' com banda) | mangas arregaçadas
-- 'q' + antebraços de pele | enxada apoiada na mão dir. da tela.
-- Roupa: camisa moss 'm', colete terra 'v' com borda 'r', cinto 'r',
-- calças barro 'p' com vinco 'P', botas 'b' sola 'o'.
local function L(s)
    assert(#s <= 64, 'linha > 64')
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
local function patch(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do t[r] = s end
    return t
end

local body = {
    -- coroa da palha com trama: 'H' base, filete 'w' quebrado
    [9]  = '.............................kkkkkkkkk',
    [10] = '............................kHHHHHHHHHk',
    [11] = '............................kHHHwHHHwHk',
    [12] = '............................kHwHHHHHHHk',
    -- banda da palha: 'D' mais escura
    [13] = '............................kDDDDDDDDDk',
    -- aba larga: topo 'S', trama 'w' intercalada, sombra 'D' por baixo
    [14] = '......................kkkkkkkkkkkkkkkkkkkkk',
    [15] = '.....................kSSSwSSwSSSwSSSwSSSSk',
    [16] = '....................kSwSSSSwSSSSwSSwSSwSSk',
    [17] = '.....................kDDDDDDDDDDDDDDDDDDDDk',
    -- cabeça sob a aba: sombra das duas primeiras fileiras
    [18] = '............................kddddddddk',
    [19] = '............................kddssssddk',
    [20] = '............................kssssssssk',
    [21] = '............................kssssssssk',
    [22] = '............................ksseesseesk',
    [23] = '............................ksssssssssk',
    [24] = '............................ksssnnnsssk',
    [25] = '............................ksssssssssk',
    [26] = '.............................kssddssk',
    [27] = '.............................kssssssk',
    [28] = '..............................kssssk',
    [29] = '..............................kssssk',
    [30] = '..............................kssssk',
    -- pescoço + gola da camisa
    [31] = '.............................kksssskk',
    -- ombros de camisa moss com dobra 'q' nas costuras do ombro
    [32] = '..........................kkmmmmmmmmmmkk',
    [33] = '.........................kmmmmmmmmmmmmmmk',
    [34] = '.......................kkmmmmmmmmmmmmmmmmkk',
    [35] = '......................kmmmmqmmmmmmmmmmqmmmmk',
    [36] = '.....................kmmmmqmmmmmmmmmmqmmmmmk',
    [37] = '....................kmmmqvvvvmmmmmmvvvvqmmmk',
    [38] = '...................kmmmqvvvvvmmmmmmvvvvvqmmmk',
    [39] = '..................kmmmqvvvvrmmmmmmrvvvvvqmmmmk',
    [40] = '.................kmmmqvvvvvmmmmmmmmvvvvvqmmmmk',
    [41] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [42] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [43] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [44] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [45] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [46] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [47] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [48] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [49] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [50] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [51] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    [52] = '.................kmmqvvvvvmmmmmmmmvvvvvqmmmk',
    -- mangas arregaçadas: barra 'q' + antebraço de pele 's'
    [53] = '.................kqqqvvvvvmmmmmmmmvvvvvqkqqk',
    [54] = '.................ksskvvvvvmmmmmmmmvvvvvksssk',
    [55] = '.................ksskvvvvvmmmmmmmmvvvvvksssk',
    [56] = '.................ksskvvvvvmmmmmmmmvvvvvksssk',
    [57] = '.................ksskvvvvvmmmmmmmmvvvvvkssk',
    -- punhos: mão esq. (dir. tela) segura o cabo da enxada; mão dir.
    -- da tela = antebraço solto + dedos
    [58] = '.................kssskvvvvmmmmmmmmvvvvkssssk',
    [59] = '.................kssskvvvvmmmmmmmmvvvvkssssk',
    [60] = '.................kssskkppppppppppppppkssssk',
    [61] = '.................kkkk.kppppppppppppppk.kkkk',
    -- cinto 'r' + calças barro 'p' com vinco central 'P'
    [62] = '.........................krrrrrrrrrrrrrrk',
    [63] = '.........................kpppppppk.kppppppk',
    [64] = '.........................kpppppppk.kppppppk',
    [65] = '.........................kpppppppk.kppppppk',
    [66] = '.........................kpppppppk.kppppppk',
    [67] = '.........................kppppppPk.kppppppk',
    [68] = '.........................kppppppPk.kppppppk',
    [69] = '.........................kppppppPk.kppppppk',
    [70] = '.........................kppppppPk.kppppppk',
    [71] = '.........................kppppppPk.kppppppk',
    [72] = '.........................kppppppPk.kppppppk',
    [73] = '.........................kppppppPk.kppppppk',
    [74] = '.........................kppppppPk.kppppppk',
    [75] = '.........................kppppppPk.kppppppPk',
    [76] = '.........................kpppppPPk.kppppppPk',
    [77] = '.........................kpppppPPk.kppppppPk',
    [78] = '.........................kpppppPPk.kpppppPPk',
    [79] = '.........................kpppppPPk.kpppppPPk',
    [80] = '.........................kpppppPPk.kpppppPPk',
    [81] = '.........................kpppppPPk.kpppppPPk',
    [82] = '.........................kpppppPPk.kpppppPPk',
    [83] = '.........................kpppppPPk.kpppppPPk',
    [84] = '.........................kpppppPPk.kpppppPPk',
    [85] = '.........................kpppppPPk.kpppppPPk',
    [86] = '.........................kbbbbbbbk.kbbbbbbbk',
    [87] = '.........................kbbbbbbbk.kbbbbbbbk',
    [88] = '.........................kbbbbbbbk.kbbbbbbbk',
    [89] = '.........................kbbbbbbbk.kbbbbbbbk',
    [90] = '........................kbbbbbbbbbk.kbbbbbbbbk',
    [91] = '........................kbbbbbbbbbk.kbbbbbbbbk',
    [92] = '........................kbbbbbbbbbk.kbbbbbbbbk',
    [93] = '........................kooooooooook.kooooooook',
    [94] = '........................kkkkkkkkkkk.kkkkkkkkkk',
}

-- enxada apoiada na mão dir. da tela: cabo 'w' fio 'W', pá 'K'
local tool = {
    [46] = '............................................kxk',
    [47] = '............................................kxk',
    [48] = '............................................kWk',
    [49] = '............................................kxk',
    [50] = '............................................kxk',
    [51] = '............................................kxk',
    [52] = '............................................kxk',
    [53] = '............................................kxk',
    [54] = '............................................kxk',
    [55] = '............................................kxk',
    [56] = '............................................kxk',
    [57] = '............................................kxk',
    [58] = '............................................kxk',
    [59] = '............................................kxk',
    [60] = '............................................kxk',
    [61] = '............................................kxk',
    [62] = '............................................kxk',
    [63] = '............................................kxk',
    [64] = '............................................kxk',
    [65] = '............................................kxk',
    [66] = '............................................kxk',
    [67] = '............................................kxk',
    [68] = '............................................kxk',
    [69] = '............................................kxk',
    [70] = '............................................kxk',
    [71] = '............................................kxk',
    [72] = '............................................kxk',
    [73] = '............................................kxk',
    [74] = '............................................kxk',
    [75] = '............................................kxk',
    [76] = '............................................kxk',
    [77] = '............................................kxk',
    [78] = '............................................kxk',
    [79] = '............................................kxk',
    [80] = '............................................kxk',
    [81] = '............................................kxk',
    [82] = '............................................kxk',
    [83] = '............................................kxk',
    [84] = '............................................kxk',
    [85] = '......................................kkkkkkxk',
    [86] = '......................................kKKKKKwk',
    [87] = '......................................kKKKKKkk',
    [88] = '.......................................kiiiik',
}

local gesto = patch(shift(body, 1, 9, 30), {
    -- f3: olha o canteiro — chapéu+cabeça descem 1px
    [53] = '.................kqqqvvvvvmmmmmmmmvvvvvqkqqk',
})
local respiroPisca = shift(patch(body, {
    [22] = '............................kssddsddssk',
}), 1, 31, 62)

return {
    name = 'npc_jardineiro_s', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 3, h = 11 },
        d = { ramp = 'skin', step = 1, h = 10 },
        e = { spec = 'ink', h = 12 },
        n = { ramp = 'skin', step = 2, h = 11 },
        H = { ramp = 'bone', step = 3, h = 11 },   -- coroa da palha
        S = { ramp = 'bone', step = 4, h = 12 },   -- topo da aba
        D = { ramp = 'earth', step = 1, h = 10 },  -- sombra sob a aba
        w = { ramp = 'bone', step = 5, h = 12 },   -- trama da palha
        m = { ramp = 'moss', step = 3, h = 6 },    -- camisa verde-seca
        q = { ramp = 'moss', step = 1, h = 6 },    -- barra da manga
        v = { ramp = 'earth', step = 3, h = 6 },   -- colete terra
        r = { ramp = 'earth', step = 1, h = 5 },   -- borda colete/cinto
        p = { ramp = 'earth', step = 4, h = 4 },   -- calça barro
        P = { ramp = 'earth', step = 2, h = 3 },   -- vinco
        b = { ramp = 'earth', step = 2, h = 2 },
        o = { ramp = 'earth', step = 5, h = 2 },
        K = { ramp = 'iron', step = 3, h = 8 },    -- pá da enxada
        i = { ramp = 'iron', step = 1, h = 7 },    -- fio da pá
        B = { ramp = 'earth', step = 4, h = 3 },
        W = { ramp = 'wood', step = 5, h = 8 },    -- fio do cabo
        x = { ramp = 'wood', step = 4, h = 8 },    -- cabo da enxada
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body), R(shift(body, 1, 31, 62)), R(gesto), R(respiroPisca),
        } },
        { name = 'tool', h = 7, albedo = {
            R(tool), R(tool), R(tool), R(tool),
        } },
    },
}
