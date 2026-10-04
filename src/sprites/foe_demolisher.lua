-- O DEMOLIDOR DA CÂMARA (foe_demolisher) — o que se quebrou tentando
-- libertar os ecos na marra, 64x96, origem nos pés. Build 'ruin': maior
-- que o breaker e ASIMÉTRICO — a laje esquerda segue inteira, o lado
-- direito está esfacelado: borda com dentes, lascas e um braço-toco.
-- O tronco carrega trincas 'k' do próprio esforço, que acordam fracas no
-- warn. A arma é arquitetura arrancada: um trecho de coluna canelada
-- 'S'/'h' que descansa sobre a laje dos ombros.
-- Frames: [1,2] idle (respiração), [3] WARN = içada: a coluna sobe na
-- horizontal sobre a cabeça como um aríete, o braço bom dobra para
-- segurá-la, as trincas acendem 'e' e os olhos escancaram 'E'.
--
--   0123456789 123456789 123456789 123456789 123456789 123456789 1234
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

--------------------------------------------------------------------------------
-- BODY: laje de ombros com o lado direito esfacelado, tronco-cortina
-- rachado por trincas 'k' em zigue-zague, faixa de ferrugem, duas
-- pernas-coluna — a direita tem a canela partida e lascada.
--------------------------------------------------------------------------------
local body = {
    -- laje: esquerda inteira, direita em dentes e faltas
    [22] = '............kkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    [23] = '...........kTTTTTTTTTTTTTTTTTTTTTTTTTTTTk',
    [24] = '..........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [25] = '.........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [26] = '.........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSk.kSk',
    [27] = '........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSk..kSSk',
    [28] = '........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSk....kSk',
    [29] = '........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    -- tronco rachado: a trinca desce em zigue-zague
    [30] = '........kTSSSSShSSSSSSSSSSSSkSSSSSSSSSSk',
    [31] = '........kTSSSSShSSSSSSSSSSkSSSSSSSSSSSk',
    [32] = '........kTSSSSSSSSSSSSSSkSSSSSSSSSSSSSk',
    [33] = '........kTSSSSSSSSSSSSkSSSSSSSSkSSSSSSk',
    [34] = '........kTSSSSmSSSSSSkSSSSSSSkSSSSSSmSk',
    [35] = '........kTSSSSSmSSSSkSSSSSSSSkSSSSSmSSSk',
    [36] = '........kTSSSSSSSSSSkSSSSSkSSSSSSSSSSSSk',
    [37] = '........kTSSSSSSSSkSSSSSSkSSSSSSSSSSSSk',
    [38] = '.........kTSSSSSSkSSSSSSkSSSSSSSSSSSSk',
    [39] = '.........kTSSSSSkSSSSSSkSSSSSSSSSSSSk',
    [40] = '.........kTSSSSSSkSSSSSkSSSSSSSSSSSSk',
    [41] = '.........kSSSSSSSkSSSSkSSSSSSSSSSSSk',
    [42] = '.........kSSSSSSSSkSSSSkSSSSSSSSSSSk',
    [43] = '.........kSSSSSSSSSkSkSSSSSSSSSSSSk',
    [44] = '.........kSSSSSSSSSSSkSSSSSSSSSSSSk',
    [45] = '.........kSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [46] = '..........kSSSSSSSSSSSkSSSSSSSSSSSSk',
    [47] = '..........kSSSSSSSSSSSSkSSSSSSSSSSSk',
    [48] = '..........kSSSSSSSSSSSSkSSSSSSSSSSk',
    [49] = '..........kSSSSSSSSSSSSSSSSSSSSSSSSk',
    [50] = '..........kSSSSSSSSSSSSSSSSSSSSSSSSk',
    [51] = '...........kSSSSSSSSSSSSSSSSSSSSSSk',
    [52] = '...........kSSSSSSSSSSSSSSSSSSSSSSk',
    [53] = '...........kSSSSSSSSSSSSSSSSSSSSSk',
    [54] = '...........kSSSSSSSSSSSSSSSSSSSSSk',
    [55] = '...........kSSSSSSSSSSSSSSSSSSSSSk',
    -- faixa de ferrugem na cintura
    [56] = '...........krrrrrrrrrrrrrrrrrrrrrrk',
    [57] = '...........krrrrrrrrrrrgGggrrrrrrrrk',
    [58] = '...........krrrrrrrrrrrgGggrrrrrrrrk',
    [59] = '...........krrrrrrrrrrrrrrrrrrrrrrk',
    -- quadris
    [60] = '............kSSSSSSSSSSSSSSSSSSSSSk',
    [61] = '............kSSSSSSSSSSSSSSSSSSSSSk',
    [62] = '............kSSSSSSSSSSSSSSSSSSSSSk',
    -- pernas-coluna: a direita tem a canela partida
    [63] = '............kSSSSSSSSk..kSSSSSSSSk',
    [64] = '............kSSSSSSSSk..kSSSSSSSSk',
    [65] = '............kSSSSSSSSk..kSSSSSSSSk',
    [66] = '............kSSSSSSSSk..kSSSkSSSSk',
    [67] = '............kSSSSSSSSk..kSSkSSSSk',
    [68] = '............kSSSSSSSSk..kSSk.SSSk',
    [69] = '............kSSSSSSSSk..kSSk..kSk',
    [70] = '............kSSSSSSSSk..kSSk..kSSk',
    [71] = '............kSSSSSSSSk..kSSk..kSSk',
    [72] = '............kSSSSSSSSk..kSSk..kSSk',
    [73] = '............kSSSSSSSSk..kSSk..kSSk',
    [74] = '............kSSSSSSSSk..kSSk..kSSk',
    [75] = '............kSSSSSSSSk..kSSk..kSSk',
    [76] = '............kSSSSSSSSk..kSSk..kSSk',
    [77] = '............kSSSSSSSSk..kSSk..kSSk',
    [78] = '............kSSSSSSSSk..kSSk..kSSk',
    [79] = '............kSSSSSSSSk..kSSk..kSSk',
    [80] = '............kSSSSSSSSk..kSSk..kSSk',
    [81] = '............kSSSSSSSSk..kSSk..kSSk',
    [82] = '............kSSSSSSSSk..kSSk..kSSk',
    [83] = '............kSSSSSSSSk..kSSk..kSSk',
    [84] = '............kSSSSSSSSk..kSSk..kSSk',
    -- pés de bloco
    [85] = '...........kSSSSSSSSSSk..kSSSkkSSSk',
    [86] = '...........kSSSSSSSSSSk..kSSSSSSSk',
    [87] = '...........kSSSSSSSSSSk..kSSSSSSSSk',
    [88] = '..........kSSSSSSSSSSSk..kSSSSSSSSk',
    [89] = '..........ksssssssssssk..kssssssssk',
    [90] = '..........ksssssssssssk..kssssssssk',
    [91] = '..........kkkkkkkkkkkkk..kkkkkkkkkkk',
}

--------------------------------------------------------------------------------
-- ARMS: braço bom (esquerdo) pendendo até o punho-bloco plantado no
-- chão; braço direito é um TOCO serrilhado — quebrou junto com a laje.
--------------------------------------------------------------------------------
local arms = {
    -- braço esquerdo: sai da laje e desce reto; toco direito serrilhado
    -- pendurado na laje quebrada (mesma linha)
    [30] = '....kkkk......................................kkk',
    [31] = '...kSSSSk...................................kSSSk',
    [32] = '...kSSSSk...................................kSSSk',
    [33] = '..kSSSSSk..................................kSSSSk',
    [34] = '..kSSSSSk..................................kSSSSk',
    [35] = '..kSSSSSk..................................kSSSSk',
    [36] = '..kSSSSSk...................................kSSSk',
    [37] = '..kSSSSSk...................................kSSSk',
    [38] = '..kSSSSSk...................................kSSSk',
    [39] = '..kSSSSSk...................................kSSSk',
    -- ponta esfacelada do toco
    [40] = '..kSSSSSk...................................kSkSk',
    [41] = '..kSSSSSk...................................kSk.k',
    [42] = '..kSSSSSk....................................k.k',
    [43] = '..kSSSSSk',
    [44] = '..kSSSSSk',
    [45] = '..kSSSSSk',
    [46] = '..kSSSSSk',
    [47] = '..kSSSSSk',
    [48] = '..kSSSSSk',
    [49] = '..kSSSSSk',
    [50] = '..kSSSSSk',
    [51] = '..kSSSSSk',
    [52] = '..kSSSSSk',
    [53] = '..kSSSSSk',
    [54] = '..kSSSSSk',
    [55] = '..kSSSSSk',
    [56] = '..kSSSSSk',
    [57] = '..kSSSSSk',
    [58] = '..kSSSSSk',
    [59] = '..kSSSSSk',
    [60] = '..kSSSSSk',
    [61] = '..kSSSSSk',
    [62] = '..kSSSSSk',
    [63] = '..kSSSSSk',
    [64] = '..kSSSSSk',
    [65] = '..kSSSSSk',
    [66] = '..kSSSSSk',
    [67] = '..kSSSSSk',
    [68] = '..kSSSSSk',
    [69] = '..kSSSSSk',
    [70] = '..kSSSSSk',
    -- punho-bloco plantado
    [71] = '.kSSSSSSk',
    [72] = '.kSSSSSSk',
    [73] = '.kSSSSSSk',
    [74] = '.kSSSSSSk',
    [75] = '.kSSSSSSk',
    [76] = '.kSSSSSSk',
    [77] = '.kSSSSSSk',
    [78] = '.kSSSSSSk',
    [79] = '.kSSSSSSk',
    [80] = '.kSSSSSSk',
    [81] = '.kSSSSSSk',
    [82] = '.kSSSSSSk',
    [83] = '.kSkSSSSk',
    [84] = '.kSkSSSSk',
    [85] = '.kSkSSSSk',
    [86] = '.kSkSSSSk',
    [87] = '.kSkSSSSk',
    [88] = '.kSkSSSSk',
    [89] = '.kSkSSSSk',
    [90] = '.kkkkkkkk',
}

-- WARN: o braço bom dobra para cima segurando a coluna; o toco direito
-- também levanta — mesmo quebrado ele ainda empurra.
local armsWarn = {
    -- braço esquerdo em arco até a face inferior da verga + toco direito
    -- erguido (mesma linha a partir da fileira 18)
    [10] = '........kSSSSk',
    [11] = '.......kSSSSk',
    [12] = '.......kSSSSk',
    [13] = '.......kSSSSk',
    [14] = '......kSSSSk',
    [15] = '......kSSSSk',
    [16] = '......kSSSSk',
    [17] = '......kSSSSk',
    [18] = '......kSSSSk..............................kSSk',
    [19] = '.....kSSSSSk..............................kSSk',
    [20] = '.....kSSSSSk.............................kSSSk',
    [21] = '.....kSSSSSk.............................kSSSk',
    [22] = '.....kSSSSSk............................kSSSk',
    [23] = '.....kSSSSSk............................kSSSk',
    [24] = '.....kSSSSSk............................kSSSk',
    [25] = '.....kSSSSSk............................kSSSk',
    [26] = '.....kSSSSSk............................kSSk',
    [27] = '.....kSSSSSk............................kSkk',
    [28] = '.....kSSSSSk.............................kk',
    [29] = '.....kSSSSSk',
}

--------------------------------------------------------------------------------
-- BEAM: trecho de coluna canelada — IDLE descansa sobre a laje dos
-- ombros em travessa; WARN sobe na horizontal como aríete.
--------------------------------------------------------------------------------
local beam = {
    -- pontas quebradas em dentes acima/abaixo do fuste
    [18] = '..kk..kk......................................kk..kk',
    [19] = '..kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    [20] = '..kShSShSShSShSShSShSShSShSShSShSShSShSShSSk',
    [21] = '..kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    [22] = '..k..kkk....................................k..kkk',
}

local beamWarn = {
    [6]  = '.....kk..kk............................kk..kk',
    [7]  = '.....kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    [8]  = '.....kShSShSShSShSShSShSShSShSShSShSShSShSk',
    [9]  = '.....kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    [10] = '.....k..kkk............................k..kkk',
}

--------------------------------------------------------------------------------
-- HEAD: cabeça pequena afundada entre a laje — elmo 'S'/'b', fenda de
-- olho 'e' danger, queixo rente ao peito. WARN afunda mais.
--------------------------------------------------------------------------------
local head = {
    [29] = '...........................kkkkkkkkkk',
    [30] = '..........................kSSSSSSSSSk',
    [31] = '..........................kSSSSSSSSSk',
    [32] = '..........................kSbSSSSSbSk',
    [33] = '.........................kSSbSSSSSbSSk',
    [34] = '.........................kSSSSSSSSSSSk',
    [35] = '.........................kSeESSSSeESSk',
    [36] = '.........................kSeESSSSeESSk',
    [37] = '.........................kSSSSSSSSSSSk',
    [38] = '.........................kSSSSSSSSSSk',
    [39] = '..........................kSSSSSSSSk',
    [40] = '..........................kbSSSSSSbk',
    [41] = '...........................kkkkkkkkk',
}

local headWarn = {
    [32] = '...........................kkkkkkkkkk',
    [33] = '..........................kSSSSSSSSSk',
    [34] = '..........................kSSSSSSSSSk',
    [35] = '..........................kSbSSSSSbSk',
    [36] = '.........................kSSbSSSSSbSSk',
    [37] = '.........................kSSSSSSSSSSSk',
    [38] = '.........................kSEESSSSEESSk',
    [39] = '.........................kSEESSSSEESSk',
    [40] = '.........................kSSSSSSSSSSSk',
    [41] = '.........................kSSSSSSSSSSk',
    [42] = '..........................kSSSSSSSSk',
    [43] = '..........................kbSSSSSSbk',
    [44] = '...........................kkkkkkkkk',
}

--------------------------------------------------------------------------------
-- CAPE: farrapos escuros pendurados no ombro esfacelado — pano que já
-- foi violeta e virou pó de pedra ('u'/'D').
--------------------------------------------------------------------------------
local cape = {
    [27] = '................................................kuk',
    [28] = '...............................................kuuk',
    [29] = '..............................................kuuuk',
    [30] = '.............................................kuuuuk',
    [31] = '.............................................kDuuuk',
    [32] = '............................................kuDuuuk',
    [33] = '............................................kuuuuuk',
    [34] = '...........................................kuuuDuuk',
    [35] = '...........................................kDuuuuuk',
    [36] = '..........................................kuuuuuuk',
    [37] = '..........................................kuuDuuuk',
    [38] = '.........................................kuuuuuuk',
    [39] = '.........................................kDuuuuk',
    [40] = '.........................................kuuuuuk',
    [41] = '........................................kuuDuuk',
    [42] = '........................................kuuuuk',
    [43] = '........................................kDuuk',
    [44] = '.......................................kuuuk',
    [45] = '.......................................kuuk',
    [46] = '.......................................kuk',
    [47] = '.......................................kuk',
    [48] = '......................................kuk',
    [49] = '......................................kuk',
    [50] = '......................................kuk',
    [51] = '......................................kDk',
    [52] = '......................................kk',
}

return {
    name = 'foe_demolisher',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 5},
        S = {ramp = 'stone', step = 4, h = 6},
        h = {ramp = 'stone', step = 5, h = 7},
        T = {ramp = 'stone', step = 6, h = 8},
        D = {ramp = 'stone', step = 2, h = 4},
        b = {ramp = 'bone', step = 4, h = 5},
        u = {ramp = 'violet', step = 2, h = 3},
        v = {ramp = 'violet', step = 3, h = 4},
        m = {ramp = 'moss', step = 2, h = 4},
        r = {ramp = 'rust', step = 3, h = 5},
        g = {ramp = 'gold', step = 4, h = 6},
        G = {ramp = 'gold', step = 5, h = 7},
        e = {spec = 'danger', h = 7, e = 'danger', ei = .35},
        E = {spec = 'danger', h = 7, e = 'danger', ei = 1},
    },

    layers = {
        {name = 'cape', h = 4, albedo = {
            R(cape),
            R(shift(cape, 1, 27, 52)),
            R(shift(cape, -2, 27, 52)),      -- balança com a içada
        }},
        {name = 'body', h = 5, albedo = {
            R(body),
            R(shift(body, 1, 22, 62)),       -- respira
            R(shift(body, 2, 22, 62)),       -- afunda sob a carga
        }},
        {name = 'beam', h = 7, albedo = {
            R(beam), R(beam), R(beamWarn),
        }},
        {name = 'arms', h = 6, albedo = {
            R(arms), R(arms), R(armsWarn),
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 29, 41)),
            R(headWarn),
        }, emissive = {
            R {
                [35] = '...........................ee....ee',
                [36] = '...........................ee....ee',
            },
            R {
                [36] = '...........................ee....ee',
                [37] = '...........................ee....ee',
            },
            R {
                [38] = '...........................EE....EE',
                [39] = '...........................EE....EE',
                -- as trincas do corpo acordam com o esforço (corpo afunda
                -- +2 no warn: marcas acompanham a trinca descida)
                [35] = '....................................e',
                [38] = '.....................................e',
                [41] = '...................................e',
                [44] = '................................e',
                [48] = '.................................e',
            },
        }},
    },
}
