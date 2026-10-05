-- JARDINEIRO — loop de TRABALHO: corcunda sobre o canteiro (idle SUL,
-- 64x96, origem nos pés, 4f = ciclo contínuo). Reusa as grades de
-- npc_jardineiro_s (require + toMap, sem duplicar arte): chapéu+cabeça
-- descem 2px, ombros 1px — corcunda de quem trabalha a terra. Os dois
-- antebraços soltos saem; braços e enxada entram na camada 'trab'
-- (4 posições: lâmina erguida, descendo, golpe no solo, arrancar mato)
-- e o tufo de mato na camada 'mato' (arrancado no f4).
-- Legend = a do _s + mato 'g'/'G'; 'r' (terra escura) faz os estilhaços.

local src = require('src.sprites.npc_jardineiro_s')

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
local function toMap(grid)
    local m = {}
    for l in grid:gmatch('[^\n]+') do m[#m + 1] = l end
    return m
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

--------------------------------------------------------------------------------
-- BODY: mesmo corpo do idle sul, curvado. Chapéu+cabeça +2, ombros +1.
-- Antebraços soltos apagados — os braços novos vêm na camada 'trab'.
--------------------------------------------------------------------------------
local function slice(map, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if r >= rmin and r <= rmax then t[r] = s end
    end
    return t
end

local orig = toMap(src.layers[1].albedo[1])
local body = {}
for r, s in pairs(orig) do body[r] = s end
-- cabeça+chapéu +2 (corcunda), depois ombros/torso +1 — ordem fixa,
-- sem faixas sobrepostas (determinístico).
for r, s in pairs(shift(slice(orig, 9, 30), 2)) do body[r] = s end
for r, s in pairs(shift(slice(orig, 31, 52), 1)) do body[r] = s end
blank(body, 53, 57, 18, 21)
blank(body, 58, 60, 18, 23)
blank(body, 61, 62, 18, 22)
blank(body, 53, 57, 41, 45)
blank(body, 58, 60, 41, 46)
blank(body, 61, 62, 41, 45)
-- laterais do tronco recuperam o fio de contorno
for r = 53, 59 do put(body, r, 18, 'k') end
for r = 53, 59 do put(body, r, 41, 'k') end

--------------------------------------------------------------------------------
-- TRAB: braços dos dois lados trabalhando juntos — mãos 's' no cabo
-- 'w', lâmina 'K'/'i'. O canteiro é o chão à frente das botas.
--------------------------------------------------------------------------------

-- f1: enxada erguida — cabo em diagonal subindo à direita, lâmina alta.
local trab1 = {
    [41] = '....................................................kKk',
    [42] = '...................................................kKKk',
    [43] = '..................................................kKKKk',
    [44] = '...................................................kiik',
    [45] = '..................................................kwkk',
    [47] = '.................................................kwk',
    [49] = '................................................kwk',
    [51] = '...............................................kwk',
    [53] = '..............................................kwk',
    [55] = '.............................................kwk',
    -- mãos no cabo, à frente do colete
    [56] = '.........................................kssk.kwk',
    [57] = '........................................ksssk.k',
    [58] = '........................................kssssk',
    [59] = '.........................................kssk',
    [60] = '.........................................kssk',
}

-- f2: descendo — cabo mais deitado, lâmina a meia altura.
local trab2 = {
    [56] = '.........................................kssk.kwk',
    [57] = '........................................ksssk.k',
    [58] = '........................................kssssk..kwk',
    [59] = '.........................................kssk....kwk',
    [60] = '.........................................kssk.....kwk',
    [62] = '.................................................kwk',
    [64] = '..................................................kwk',
    [66] = '...................................................kwk',
    -- lâmina descendo
    [68] = '...................................................kKKk',
    [69] = '...................................................kKKKk',
    [70] = '....................................................kiik',
    [71] = '....................................................kkk',
}

-- f3: GOLPE — lâmina crava no solo, mãos descem junto, terra salta 'r'.
local trab3 = {
    [60] = '.........................................kssk...kwk',
    [61] = '.........................................ksssk..kwk',
    [62] = '..........................................ksssk.kwk',
    [63] = '..........................................kssk.kwk',
    [64] = '..........................................ksskkwk',
    [66] = '................................................kwk',
    [68] = '.................................................kwk',
    [70] = '..................................................kwk',
    [72] = '...................................................kwk',
    [74] = '....................................................kwk',
    -- lâmina na terra + estilhaços 'r'
    [77] = '..................................................r..r',
    [78] = '....................................................kKKk',
    [79] = '................................................r..kKKKk',
    [80] = '...................................................kKKrKk',
    [81] = '..................................................r.kiiik.r',
    [82] = '...................................................rkkkk..r',
}

-- f4: arranca o mato — enxada fincada à direita, mão direita repousa
-- no cabo; braço esquerdo estica até o tufo 'g' já arrancado na mão.
local trab4 = {
    -- enxada em pé
    [52] = '..................................................kwk',
    [54] = '..................................................kwk',
    [56] = '..................................................kwk',
    [58] = '................................................ksskwk',
    [59] = '................................................ksskwk',
    [62] = '..................................................kwk',
    [64] = '..................................................kwk',
    [66] = '..................................................kwk',
    [68] = '..................................................kwk',
    [70] = '..................................................kwk',
    [72] = '..................................................kwk',
    [74] = '..................................................kwk',
    [76] = '..................................................kwk',
    [78] = '..................................................kwk',
    [80] = '..................................................kwk',
    [82] = '..................................................kwk',
    [84] = '..................................................kwk',
    [85] = '...............................................kkwk',
    [86] = '............................................kKKKkwk',
    [87] = '............................................kKKKKKkk',
    [88] = '............................................kiiiiik',
    [89] = '............................................kkkkkk',
    -- braço esquerdo esticado até o tufo arrancado (enxada na mesma linha)
    [60] = '..........................kssk..................kkwk',
    [62] = '.........................kssk',
    [64] = '.........................kssk',
    [66] = '........................kssk',
    [68] = '........................kssk',
    [70] = '.......................kssk',
    [72] = '.......................kssk',
    -- mão fechada no tufo levantado
    [74] = '......................ksssk',
    [75] = '......................kssgk',
    [76] = '......................kgggk',
    [77] = '.......................kggk',
    [78] = '........................kgk',
}

--------------------------------------------------------------------------------
-- MATO: tufos no canteiro. f1-3: tufo esquerdo no chão; f4: arrancado
-- (está na mão, na camada trab). Tufo direito fica sempre.
--------------------------------------------------------------------------------
local matoChao = {
    [83] = '....................g.G',
    [84] = '...................gGggG',
    [85] = '..................gggGgg',
    [86] = '...................gGgg..............................gG',
    [87] = '......................................................gGgG',
    [88] = '.......................................................gG',
}
local matoSoDireito = {
    [86] = '.......................................................gG',
    [87] = '......................................................gGgG',
    [88] = '.......................................................gG',
}

-- legend do _s + mato
local legend = {}
for ch, e in pairs(src.legend) do legend[ch] = e end
legend.g = {ramp = 'moss', step = 3, h = 2}
legend.G = {ramp = 'moss', step = 5, h = 3}

return {
    name = 'npc_jardineiro_trabalho',
    w = 64, h = 96,
    origin = 'feet',
    legend = legend,

    -- W4: contato = golpe da enxada no solo (f3); 'mato' segue o tufo.
    anchors = {
        pe = {32, 94},
        cabeca = {33, 24},
        ferramenta = {{47, 58}, {50, 62}, {51, 76}, {51, 60}},
        mato = {22, 76},
    },
    markers = { contact = {3} },
    sequences = { trabalho = {1, 4, loop = true} },
    frameDuration = {0.22, 0.16, 0.3, 0.32},

    layers = {
        {name = 'body', h = 4, albedo = R(body)},
        {name = 'mato', h = 2, albedo = {
            R(matoChao), R(matoChao), R(matoChao), R(matoSoDireito),
        }},
        {name = 'trab', h = 7, albedo = {
            R(trab1), R(trab2), R(trab3), R(trab4),
        }},
    },
}
