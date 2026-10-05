-- JARDINEIRO — idle NORTE (de costas), 64x96, origem nos pés, 4f.
-- Mesma figura do _s: chapéu de palha cobre a cabeça; nuca em sombra
-- 'd' com fio de cabelo 'h' sob a aba; colete 'v' fecha o dorso, camisa
-- moss nas mangas; enxada na mão esquerda da tela (de costas, a mão
-- que segurava à direita no _s aparece à esquerda). f1 repouso |
-- f2 respiro | f3 olha o canteiro (chapéu+nuca descem 1px) |
-- f4 respiro + ajusta o chapéu (braço direito da tela sobe à aba).

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
local function put(map, r, c, s)
    local row = L(map[r] or '')
    map[r] = row:sub(1, c - 1) .. s .. row:sub(c + #s)
end
local function blank(map, r1, r2, c1, c2)
    for r = r1, r2 do
        local row = map[r]
        if row then
            row = L(row)
            map[r] = row:sub(1, c1 - 1) .. ('.'):rep(c2 - c1 + 1)
                .. row:sub(c2 + 1)
        end
    end
end

local body = {
    -- coroa e aba (vista de trás é a mesma massa de palha)
    [9]  = '.............................kkkkkkkkk',
    [10] = '............................kHHHHHHHHHk',
    [11] = '............................kHHHHHHHHHk',
    [12] = '............................kHHHHHHHHHk',
    [13] = '............................kDDDDDDDDDk',
    [14] = '......................kkkkkkkkkkkkkkkkkkkkk',
    [15] = '.....................kSSSSSSSSSSSSSSSSSSSSSk',
    [16] = '....................kSSSSSSSSSSSSSSSSSSSSSSSk',
    [17] = '.....................kDDDDDDDDDDDDDDDDDDDDk',
    -- nuca: cabelo curto escuro 'h' sobre pele em sombra 'd'
    [18] = '............................khhhhhhhhk',
    [19] = '............................khddddddhk',
    [20] = '............................kddddddddk',
    [21] = '............................kddddddddk',
    [22] = '............................kddddddddk',
    [23] = '............................kddddddddk',
    [24] = '.............................kddddddk',
    [25] = '..............................kddddk',
    [26] = '..............................kddddk',
    [27] = '..............................kssssk',
    [28] = '..............................kssssk',
    [29] = '..............................kssssk',
    [30] = '..............................kssssk',
    [31] = '.............................kksssskk',
    -- dorso: colete terra fechado cobre o centro, camisa moss nas bordas
    [32] = '..........................kkmmmmmmmmmmkk',
    [33] = '.........................kmmmmmmmmmmmmmmk',
    [34] = '.......................kkmmmmmmmmmmmmmmmmkk',
    [35] = '......................kmmmmmmmmmmmmmmmmmmmmk',
    [36] = '.....................kmmmmqmmmmmmmmmmqmmmmmk',
    [37] = '....................kmmmqvvvvvvvvvvvvvvqmmmk',
    [38] = '...................kmmmqvvvvvvvvvvvvvvvqmmmk',
    [39] = '..................kmmmqvvvvvvvvvvvvvvvvqmmmmk',
    [40] = '.................kmmmqvvvvvvvvvvvvvvvvvqmmmmmk',
    [41] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [42] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [43] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [44] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [45] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [46] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [47] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [48] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [49] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [50] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [51] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    [52] = '.................kmmqvvvvvvvvvvvvvvvvvvqmmmk',
    -- punhos arregaçados; punho esq. da tela segura o cabo da enxada
    [53] = '.................kqqqvvvvvvvvvvvvvvvvvvqkqqk',
    [54] = '.................ksskvvvvvvvvvvvvvvvvvvksssk',
    [55] = '.................ksskvvvvvvvvvvvvvvvvvvksssk',
    [56] = '.................ksskvvvvvvvvvvvvvvvvvvksssk',
    [57] = '.................ksskvvvvvvvvvvvvvvvvvvkssk',
    [58] = '.................kssskvvvvvvvvvvvvvvvvkssssk',
    [59] = '.................kssskvvvvvvvvvvvvvvvvkssssk',
    [60] = '.................kssskkppppppppppppppkssssk',
    [61] = '.................kkkk.kppppppppppppppk.kkkk',
    [62] = '.........................krrrrrrrrrrrrrrk',
    [63] = '.........................kpppppppk.kppppppk',
    [64] = '.........................kpppppppk.kppppppk',
    [65] = '.........................kpppppppk.kppppppk',
    [66] = '.........................kpppppppk.kppppppk',
    [67] = '.........................kpppppppk.kppppppk',
    [68] = '.........................kpppppppk.kppppppk',
    [69] = '.........................kpppppppk.kppppppk',
    [70] = '.........................kpppppppk.kppppppk',
    [71] = '.........................kpppppppk.kppppppk',
    [72] = '.........................kpppppppk.kppppppk',
    [73] = '.........................kpppppppk.kppppppk',
    [74] = '.........................kpppppppk.kppppppk',
    [75] = '.........................kpppppppk.kppppppk',
    [76] = '.........................kpppppppk.kppppppk',
    [77] = '.........................kpppppppk.kppppppk',
    [78] = '.........................kpppppppk.kppppppk',
    [79] = '.........................kpppppppk.kppppppk',
    [80] = '.........................kpppppppk.kppppppk',
    [81] = '.........................kpppppppk.kppppppk',
    [82] = '.........................kpppppppk.kppppppk',
    [83] = '.........................kpppppppk.kppppppk',
    [84] = '.........................kpppppppk.kppppppk',
    [85] = '.........................kpppppppk.kppppppk',
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

-- enxada na mão esquerda da tela (de costas), lâmina rente ao chão
local tool = {
    [46] = '...................kwk',
    [47] = '...................kwk',
    [48] = '...................kWk',
    [49] = '...................kwk',
    [50] = '...................kwk',
    [51] = '...................kwk',
    [52] = '...................kwk',
    [53] = '...................kwk',
    [54] = '...................kwk',
    [55] = '...................kwk',
    [56] = '...................kwk',
    [57] = '...................kwk',
    [58] = '...................kwk',
    [59] = '...................kwk',
    [60] = '...................kwk',
    [61] = '...................kwk',
    [62] = '...................kwk',
    [63] = '...................kwk',
    [64] = '...................kwk',
    [65] = '...................kwk',
    [66] = '...................kwk',
    [67] = '...................kwk',
    [68] = '...................kwk',
    [69] = '...................kwk',
    [70] = '...................kwk',
    [71] = '...................kwk',
    [72] = '...................kwk',
    [73] = '...................kwk',
    [74] = '...................kwk',
    [75] = '...................kwk',
    [76] = '...................kwk',
    [77] = '...................kwk',
    [78] = '...................kwk',
    [79] = '...................kwk',
    [80] = '...................kwk',
    [81] = '...................kwk',
    [82] = '...................kwk',
    [83] = '...................kwk',
    [84] = '...................kwk',
    [85] = '..................kkwk',
    [86] = '...............kKKKKkwk',
    [87] = '...............kKKKKKkk',
    [88] = '...............kiiiiik',
    [89] = '...............kkkkkk',
}

local gesto = shift(body, 1, 9, 30)

-- f4: respiro + braço direito da tela sobe à aba do chapéu.
local bracoChapeu = shift(body, 1, 32, 59)
for r = 18, 34 do put(bracoChapeu, r, 41, 'kssk') end
put(bracoChapeu, 33, 40, 'ksssk')
put(bracoChapeu, 34, 41, 'kssk')
put(bracoChapeu, 15, 40, 'kssk')
put(bracoChapeu, 16, 39, 'kssssk')
put(bracoChapeu, 17, 40, 'kssk')
for r = 35, 45 do put(bracoChapeu, r, 42, 'kmmk') end
for r = 46, 53 do put(bracoChapeu, r, 43, 'vvvk') end
blank(bracoChapeu, 54, 57, 41, 45)
blank(bracoChapeu, 58, 60, 41, 47)
blank(bracoChapeu, 61, 62, 40, 44)
-- lateral sem braço: colete 'v' com fio 'k' até onde o tronco segue
for r = 54, 57 do put(bracoChapeu, r, 42, 'vvvk') end
for r = 58, 59 do put(bracoChapeu, r, 40, 'vvvvvk') end
put(bracoChapeu, 60, 41, 'vvvvk')

local respiro = shift(body, 1, 32, 59)

return {
    name = 'npc_jardineiro_n',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},
        d = {ramp = 'skin', step = 2, h = 10},
        h = {ramp = 'hair', step = 3, h = 11},  -- cabelo curto na nuca
        H = {ramp = 'gold', step = 4, h = 12},
        S = {ramp = 'gold', step = 6, h = 12},
        D = {ramp = 'gold', step = 2, h = 11},
        m = {ramp = 'moss', step = 3, h = 6},
        q = {ramp = 'moss', step = 2, h = 5},
        v = {ramp = 'earth', step = 4, h = 6},
        r = {ramp = 'earth', step = 2, h = 5},
        p = {ramp = 'earth', step = 3, h = 4},
        b = {ramp = 'earth', step = 2, h = 2},
        o = {ramp = 'earth', step = 5, h = 2},
        w = {ramp = 'wood', step = 4, h = 7},
        W = {ramp = 'wood', step = 5, h = 7},
        K = {ramp = 'iron', step = 3, h = 6},
        i = {ramp = 'iron', step = 5, h = 6},
    },

    anchors = {
        pe = {32, 94},
        cabeca = {33, 20},
        ferramenta = {20, 56},
    },
    sequences = { idle = {1, 4, loop = true} },
    frameDuration = {0.4, 0.3, 0.5, 0.3},

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body), R(respiro), R(gesto), R(bracoChapeu),
        }},
        {name = 'tool', h = 7, albedo = {R(tool), R(tool), R(tool), R(tool)}},
    },
}
