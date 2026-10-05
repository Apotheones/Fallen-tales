-- CABRA do terraço — ator pequeno, 48x64, origem nos pés, 4f.
-- ESCALA: menor que humano — metade do palco (48x64 contra 64x96 dos
-- npc_*). A cabra do terraço da Botica vive de "cabeça baixa procurando":
-- perfil para a esquerda, focinho rente ao chão farejando um tufo de
-- mato. Simpática, não mascote-cartoon: pelagem bone suja de terra,
-- chifres curtos virados para trás, focinho escuro, pernas finas.
-- f1 repouso (focinho no chão, cauda caída) | f2 focinho sobe 1px +
-- cauda sobe | f3 orelha levanta (flick) | f4 focinho sobe 1px + cauda
-- do outro lado. Loop de vida: farejar, não passear.
-- Relevo: dorso/cabeça 7-9, pernas 3-4, cascos 2, mato/chão 1-2.

local W, H = 48, 64

local function L(s)
    assert(#s <= W, 'linha de sprite > 48 colunas')
    return s .. string.rep('.', W - #s)
end
local E = string.rep('.', W)
local function R(map)
    local t = {}
    for r = 1, H do
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
-- Mescla por caractere: o pixel do patch só entra onde não é '.'/' '.
-- Diferente de patch() (linha inteira), preserva o resto da linha.
local function carimbo(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do
        local base = L(t[r] or '')
        local ed = L(s)
        local row = {}
        for x = 1, W do
            local c = ed:sub(x, x)
            row[x] = (c ~= '.' and c ~= ' ') and c or base:sub(x, x)
        end
        t[r] = table.concat(row)
    end
    return t
end

--------------------------------------------------------------------------------
-- CORPO: dorso nivelado, barriga suja 'e', jarrete nas traseiras, quatro
-- pernas finas (longe 'p' em sombra), cascos 'd'. A cauda entra por patch.
--------------------------------------------------------------------------------
local corpo = {
    [32] = '.....................kkkkkkkkkkkkkkkkkk',
    [33] = '..................kkkbbbbbbbbbbbbbbbbkk',
    [34] = '................kkbbbbBbbbbbbbbbbbbbbbbkk',
    [35] = '...............kbbbbbbbbbbbbbbbbbbbbbbbk',
    [36] = '..............kbbbbbbbbbbbbbbbbbbbbbbbbbk',
    [37] = '............kbbbbbbbbbbbbbbbbbbbbbbbbbbbkk',
    [38] = '..........kkbbbbbbbbbbbbbbbbbbbbbbbbbbbbbk',
    [39] = '.........kbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbk',
    [40] = '........kbbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbk',
    [41] = '.......kbbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbbk',
    [42] = '......kbbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbkpk',
    [43] = '.....kbbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbbkppk',
    [44] = '....kbbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbkpppk',
    [45] = '...kbbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbkppppk',
    [46] = '...kbbkbbbbbbbbbbbbbbbbbbbbbbbbbbbkpppppk',
    [47] = '...kbbkeeeeeeeeeeeeeeeeeeeeeeeeeeekpppppk',
    -- barriga suja + início das pernas
    [48] = '...kbbkeeeeeeeeeeeeeeeeeeeeeeeek.kppppk',
    [49] = '...kbbk.kbk...............kbk.kbk.kpppk',
    [50] = '...kbbk.kbk...............kbk.kbk.kppk',
    [51] = '...kbbk.kbk...............kbk.kpk.kppk',
    [52] = '...kbbk.kbk...............kbk.kpk.kppk',
    [53] = '....kbk.kbk...............kbk.kpk.kpk',
    [54] = '....kbk.kbk...............kbk.kpk.kpk',
    [55] = '....kbk.kbk...............kbk.kpk.kpk',
    [56] = '....kbk.kbk...............kbk.kpk.kpk',
    [57] = '....kbk.kbk...............kbk.kpk.kpk',
    [58] = '....kbk.kbk...............kbk.kpk.kpk',
    [59] = '....kbk.kbk...............kbk.kpk.kpk',
    -- cascos
    [60] = '....kdk.kdk...............kdk.kdk.kdk',
    [61] = '....kdk.kdk...............kdk.kdk.kdk',
    [62] = '....kkk.kkk...............kkk.kkk.kkk',
}

-- cauda caída (f1/f3): pendula junto ao jarrete direito
local raboBaixo = {
    [38] = '.........................................kkk',
    [39] = '.........................................kttk',
    [40] = '..........................................kttk',
    [41] = '..........................................kttk',
    [42] = '...........................................kttk',
    [43] = '...........................................ktk',
    [44] = '...........................................kkk',
}
-- cauda em pé para a esquerda (f2)
local raboA = {
    [32] = '........................................kkk',
    [33] = '.......................................kttk',
    [34] = '.......................................kttk',
    [35] = '.......................................kttk',
    [36] = '........................................kttk',
    [37] = '........................................kkk',
}
-- cauda em pé para a direita (f4)
local raboB = {
    [32] = '..........................................kkk',
    [33] = '.........................................kttk',
    [34] = '........................................ktttk',
    [35] = '........................................kttk',
    [36] = '.......................................kttk',
    [37] = '.......................................kkk',
}

--------------------------------------------------------------------------------
-- CABEÇA: pescoço desce do peito ao focinho; crânio cols 7-16, focinho
-- escuro 'f' rente ao chão, chifres curtos 'o' para trás, barbicha 'f'.
--------------------------------------------------------------------------------
local cabeca = {
    -- chifres curtos: apontam para trás-cima (cabeça baixa)
    [43] = '.............o.o',
    [44] = '............kook',
    [45] = '...........kbbbk',
    [46] = '..........kbbbbk',
    [47] = '.........kbbbbbbk',
    [48] = '........kbbbbbbbk...k',
    [49] = '.......kbbbbbibbk..kbk',
    [50] = '......kbbbbbbbbbk..kbbk',
    [51] = '.....kbbbbbbbbbbk...kbk',
    [52] = '....kbbbbbbbbbbk....k',
    [53] = '....kbbbbbbbbbk',
    [54] = '...kbbbbbfffk',
    [55] = '..kbbbffffffk',
    [56] = '..kbbffffffk',
    [57] = '..kfffkffk',
    [58] = '..kfffk',
    -- barbicha
    [59] = '....kf',
}

-- orelha caída (base) vs orelha que levanta (f3) — patch só na orelha
local orelhaBaixa = {
    [48] = '...................kbbk',
    [49] = '...................kbbbk',
    [50] = '....................kbk',
}
local orelhaAlta = {
    [45] = '..................kbbk',
    [46] = '.................kbbbk',
    [47] = '.................kbbk',
    [48] = '.................kk',
}

--------------------------------------------------------------------------------
-- CHÃO: tufo de mato no focinho + terra mexida sob os cascos.
--------------------------------------------------------------------------------
local chao = {
    [59] = '..g',
    [60] = '.gGg...........e.....e....e........e',
    [61] = '..gGg....e......e.......e.....e',
    [62] = '.ege.....e........e......e....e',
    [63] = '..ee.........................',
}

local corpo1 = carimbo(corpo, raboBaixo)
local corpo2 = carimbo(corpo, raboA)
local corpo4 = carimbo(corpo, raboB)

local cabecaBaixa = carimbo(cabeca, orelhaBaixa)
local cabecaAlta = carimbo(patch(cabeca, {
    -- apaga a orelha caída antes de desenhar a alta
    [48] = '......................',
    [49] = '......................',
    [50] = '......................',
}), orelhaAlta)

-- f1 repouso | f2 focinho+1px, cauda A | f3 orelha levanta | f4 focinho
-- +1px, cauda B. O pescoço acompanha a cabeça inteira (camada própria).
return {
    name = 'cabra',
    w = 48, h = 64,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        b = {ramp = 'bone', step = 4, h = 7},   -- pelagem
        B = {ramp = 'bone', step = 5, h = 8},   -- luz do dorso
        e = {ramp = 'earth', step = 3, h = 6},  -- barriga suja de terra
        p = {ramp = 'bone', step = 2, h = 3},   -- pernas/jarrete longe
        t = {ramp = 'bone', step = 5, h = 6},   -- cauda clara
        d = {ramp = 'earth', step = 2, h = 2},  -- cascos
        f = {ramp = 'hair', step = 2, h = 6},   -- focinho/barbicha escuros
        o = {ramp = 'bone', step = 2, h = 8},   -- chifres curtos
        i = {spec = 'ink', h = 8},              -- olho
        g = {ramp = 'moss', step = 3, h = 2},   -- mato farejado
        G = {ramp = 'moss', step = 4, h = 2},
    },

    -- W4: pe = entre os cascos dianteiros; 'focinho' marca o ponto de
    -- contato do farejo (f1/f3 no chão) — markers.contact = onde cheira.
    anchors = {
        pe = {24, 62},
        focinho = {{5, 58}, {5, 57}, {5, 58}, {5, 57}},
        cauda = {42, 38},
    },
    markers = { contact = {1, 3} },
    sequences = { idle = {1, 4, loop = true} },
    frameDuration = {0.28, 0.22, 0.28, 0.22},

    layers = {
        {name = 'corpo', h = 6, albedo = {
            R(corpo1), R(corpo2), R(corpo1), R(corpo4),
        }},
        {name = 'cabeca', h = 7, albedo = {
            R(cabecaBaixa),
            R(shift(cabecaBaixa, -1, 43, 59)),
            R(cabecaAlta),
            R(shift(cabecaBaixa, -1, 43, 59)),
        }},
        {name = 'chao', h = 1, albedo = {R(chao), R(chao), R(chao), R(chao)}},
    },
}
