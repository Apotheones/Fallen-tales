-- JARDINEIRO — figurante da horta, idle SUL, 64x96, origem nos pés, 4f.
-- Liberdade orientada (PERSONAGENS §secundários): "usado, quente,
-- trabalho" — não é a Mara nem ninguém nomeado. Silhueta neutra de
-- trabalho: chapéu de palha de aba larga (âncora), camisa de mangas
-- arregaçadas (moss), colete de pano terra, calças de barro, botas.
-- Enxada apoiada na mão direita da tela. f1 repouso | f2 respiro (tórax
-- desce 1) | f3 GESTO: olha o canteiro — chapéu+cabeça descem 1px |
-- f4 respiro + ajusta o chapéu (braço esq. da tela sobe à aba).
-- Distinto dos nomeados: sem faixa, sem barba clara, sem roupagem de
-- ofício — só palha, verde seco e terra.
-- Relevo: pele 10-12, palha 11-12, roupa 5-6, enxada 7-8, botas 2-3.

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
-- Escreve a string s na linha r a partir da coluna c.
local function put(map, r, c, s)
    local row = L(map[r] or '')
    map[r] = row:sub(1, c - 1) .. s .. row:sub(c + #s)
end
-- Apaga o retângulo cols c1..c2 das linhas r1..r2.
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

--------------------------------------------------------------------------------
-- BODY: chapéu de palha (coroa 'H', banda 'D', aba 'S' com fio 'D'),
-- cabeça em meia-sombra sob a aba, camisa moss com colete terra 'v',
-- mangas arregaçadas — antebraços de pele —, calças 'p', botas 'b'.
--------------------------------------------------------------------------------
local body = {
    -- coroa da palha
    [9]  = '.............................kkkkkkkkk',
    [10] = '............................kHHHHHHHHHk',
    [11] = '............................kHHHHHHHHHk',
    [12] = '............................kHHHHHHHHHk',
    [13] = '............................kDDDDDDDDDk',
    -- aba larga: fio claro 'S' em cima, sombra 'D' por baixo
    [14] = '......................kkkkkkkkkkkkkkkkkkkkk',
    [15] = '.....................kSSSSSSSSSSSSSSSSSSSSSk',
    [16] = '....................kSSSSSSSSSSSSSSSSSSSSSSSk',
    [17] = '.....................kDDDDDDDDDDDDDDDDDDDDk',
    -- cabeça: sombra da aba nas duas primeiras fileiras
    [18] = '............................kddddddddk',
    [19] = '............................kddssssddk',
    [20] = '............................kssssssssk',
    [21] = '............................kssssssssk',
    [22] = '............................ksseesseesk',
    [23] = '............................kssssssssk',
    [24] = '............................kssssdsssk',
    [25] = '............................kssssssssk',
    [26] = '.............................kssddssk',
    [27] = '.............................kssssssk',
    [28] = '..............................kssssk',
    [29] = '..............................kssssk',
    [30] = '..............................kssssk',
    [31] = '.............................kksssskk',
    -- ombros de camisa moss (~24px), colete terra aberto no peito
    [32] = '..........................kkmmmmmmmmmmkk',
    [33] = '.........................kmmmmmmmmmmmmmmk',
    [34] = '.......................kkmmmmmmmmmmmmmmmmkk',
    [35] = '......................kmmmmmmmmmmmmmmmmmmmmk',
    [36] = '.....................kmmmmqmmmmmmmmmmqmmmmmk',
    [37] = '....................kmmmqvvvvmmmmmmvvvvqmmmk',
    [38] = '...................kmmmqvvvvvmmmmmmvvvvvqmmmk',
    [39] = '..................kmmmqvvvvvmmmmmmvvvvvqmmmmk',
    [40] = '.................kmmmqvvvvvmmmmmmvvvvvqmmmmmk',
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
    -- punhos arregaçados: barra da manga 'q' + antebraço de pele
    [53] = '.................kqqqvvvvvmmmmmmmmvvvvvqkqqk',
    [54] = '.................ksskvvvvvmmmmmmmmvvvvvksssk',
    [55] = '.................ksskvvvvvmmmmmmmmvvvvvksssk',
    [56] = '.................ksskvvvvvmmmmmmmmvvvvvksssk',
    [57] = '.................ksskvvvvvmmmmmmmmvvvvvkssk',
    [58] = '.................kssskvvvvmmmmmmmmvvvvkssssk',
    [59] = '.................kssskvvvvmmmmmmmmvvvvkssssk',
    [60] = '.................kssskkppppppppppppppkssssk',
    [61] = '.................kkkk.kppppppppppppppk.kkkk',
    -- cinto + calças de barro
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
    -- botas de trabalho, sola clara gasta
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

--------------------------------------------------------------------------------
-- TOOL: enxada apoiada — cabo 'w' com fio 'W' passando pelo punho
-- direito, lâmina 'K' rente ao chão com fio 'i'.
--------------------------------------------------------------------------------
local tool = {
    [46] = '............................................kwk',
    [47] = '............................................kwk',
    [48] = '............................................kWk',
    [49] = '............................................kwk',
    [50] = '............................................kwk',
    [51] = '............................................kwk',
    [52] = '............................................kwk',
    [53] = '............................................kwk',
    [54] = '............................................kwk',
    [55] = '............................................kwk',
    [56] = '............................................kwk',
    [57] = '............................................kwk',
    [58] = '............................................kwk',
    [59] = '............................................kwk',
    [60] = '............................................kwk',
    [61] = '............................................kwk',
    [62] = '............................................kwk',
    [63] = '............................................kwk',
    [64] = '............................................kwk',
    [65] = '............................................kwk',
    [66] = '............................................kwk',
    [67] = '............................................kwk',
    [68] = '............................................kwk',
    [69] = '............................................kwk',
    [70] = '............................................kwk',
    [71] = '............................................kwk',
    [72] = '............................................kwk',
    [73] = '............................................kwk',
    [74] = '............................................kwk',
    [75] = '............................................kwk',
    [76] = '............................................kwk',
    [77] = '............................................kwk',
    [78] = '............................................kwk',
    [79] = '............................................kwk',
    [80] = '............................................kwk',
    [81] = '............................................kwk',
    [82] = '............................................kwk',
    [83] = '............................................kwk',
    [84] = '............................................kwk',
    -- lâmina: soquete no cabo, pá horizontal à esquerda
    [85] = '......................................kkkkkkwk',
    [86] = '......................................kKKKKKwk',
    [87] = '......................................kKKKKKkk',
    [88] = '.......................................kiiiik',
    [89] = '.......................................kkkkk',
}

-- f3: olha o canteiro — chapéu+cabeça+pescoço descem 1px.
local gesto = shift(body, 1, 9, 30)

-- f4: respiro (tórax +1) + ajusta o chapéu: o braço esquerdo da tela
-- dobra para cima — antebraço 's' vertical até a mão na borda da aba,
-- manga 'm' no ombro, e o antebraço pendurado sai (a lateral vira
-- colete 'v').
local bracoChapeu = shift(body, 1, 32, 59)
-- antebraço subindo à esquerda da cabeça
for r = 18, 34 do put(bracoChapeu, r, 21, 'kssk') end
put(bracoChapeu, 33, 21, 'ksssk')
put(bracoChapeu, 34, 21, 'kssk')
-- mão na aba do chapéu
put(bracoChapeu, 15, 22, 'kssk')
put(bracoChapeu, 16, 21, 'kssssk')
put(bracoChapeu, 17, 22, 'kssk')
-- manga dobrada no ombro
for r = 35, 45 do put(bracoChapeu, r, 20, 'kmmk') end
-- lateral do tronco sem braço: vira colete
for r = 46, 53 do put(bracoChapeu, r, 18, 'kvvv') end
-- apaga o antebraço/punho pendurado (já deslocado +1 pelo respiro) e
-- devolve o fio de contorno 'k' à lateral do tronco
blank(bracoChapeu, 54, 57, 18, 21)
blank(bracoChapeu, 58, 60, 18, 23)
blank(bracoChapeu, 61, 62, 18, 22)
-- lateral sem braço: colete 'v' com fio 'k' até onde o tronco segue
for r = 54, 57 do put(bracoChapeu, r, 18, 'kvvv') end
for r = 58, 59 do put(bracoChapeu, r, 18, 'kvvvvv') end
put(bracoChapeu, 60, 18, 'kvvvv')

-- f2: respiro — tórax desce 1px.
local respiro = shift(body, 1, 32, 59)

return {
    name = 'npc_jardineiro_s',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},  -- pele de sol
        d = {ramp = 'skin', step = 2, h = 10},  -- sombra da aba/pálpebra
        e = {spec = 'ink', h = 12},
        H = {ramp = 'gold', step = 4, h = 12},  -- coroa de palha
        S = {ramp = 'gold', step = 6, h = 12},  -- aba iluminada
        D = {ramp = 'gold', step = 2, h = 11},  -- banda/fio de sombra
        m = {ramp = 'moss', step = 3, h = 6},   -- camisa de trabalho
        q = {ramp = 'moss', step = 2, h = 5},   -- manga/sombra
        v = {ramp = 'earth', step = 4, h = 6},  -- colete de pano terra
        r = {ramp = 'earth', step = 2, h = 5},  -- cinto
        p = {ramp = 'earth', step = 3, h = 4},  -- calças de barro
        b = {ramp = 'earth', step = 2, h = 2},  -- botas
        o = {ramp = 'earth', step = 5, h = 2},  -- sola gasta
        w = {ramp = 'wood', step = 4, h = 7},   -- cabo da enxada
        W = {ramp = 'wood', step = 5, h = 7},
        K = {ramp = 'iron', step = 3, h = 6},   -- lâmina
        i = {ramp = 'iron', step = 5, h = 6},   -- fio
    },

    -- W4: pe sob o centro; 'ferramenta' = punhadura da enxada.
    anchors = {
        pe = {32, 94},
        cabeca = {33, 22},
        ferramenta = {45, 56},
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
