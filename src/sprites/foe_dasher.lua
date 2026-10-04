-- BRUTO (foe_dasher) — eco de carga dos sepultados, 64x96, origem nos
-- pés. Herda o build 'bull' das sentinelas legadas: tronco em V, cabeça
-- afundada de carneiro, chifres de carga com virola de ferrugem.
-- Assimetria de função: o ombro DIREITO do sprite é o ombro de impacto —
-- mais alto, maior, com placa-laje; a cabeça baixa fica atrás dele.
-- Fragmento de capa violeta sobra no ombro de trás (esquerdo).
-- Frames: [1,2] idle (respiração: ombros sobem/descem 1px), [3] WARN =
-- pré-carga: perna de trás estica, ombro e cabeça mergulham, olho acende.
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
-- BODY: pernas-coluna, tronco em V, braços de peso. Perna esquerda do
-- sprite é a perna de TRÁS (mais escura 's'), direita é a de apoio.
--------------------------------------------------------------------------------
local body = {
    -- tronco em V: ombros largos, cintura curta
    [30] = '...................kkkkkkkkkkkkkk',
    [31] = '..................kSSSSSSSSSSSSSSk',
    [32] = '.................kSSSSSSSSSSSSSSSSk',
    [33] = '................kTSSSSSSSSSSSSSSSSSSk',
    [34] = '................kTSSSSSSSSSSSSSSSSSSk',
    [35] = '...............kTSSSSSSSSSSSSSSSSSSSSk',
    [36] = '...............kTSSSShSSSSSSSSSSSSSSSSk',
    [37] = '...............kTSSSShSSSSSSSSSSSSSSSSk',
    [38] = '..............kTSSSSShSSSSSSSSSSSSSSSSsk',
    [39] = '..............kTSSSSSSSSSSSkSSSSSSSSSSsk',
    [40] = '..............kTSSSSSSSSSSkSSSSSSSSSSSsk',
    [41] = '..............kTSSSmSSSSSSkSSSSSSSSSSSsk',
    [42] = '..............kTSSSSmSSSSkSSSSSSSSSSSssk',
    [43] = '...............kTSSSSmSSSkSSSSSSSSSSSssk',
    [44] = '...............kTSSSSSSSSkSSSSSSSSSSssk',
    [45] = '...............kTSSSSSSSSkSSSSSSSSSSssk',
    [46] = '................kSSSSSSSSSSSSSSSSSSSssk',
    [47] = '................kSSSSSSSSSSSSSSSSSSSssk',
    [48] = '................kSSSSSSSSSSSSSSSSSSssk',
    -- cinto de ferrugem com placa de ouro
    [49] = '................krrrrrrrrrrrrrrrrrrrk',
    [50] = '................krrrrrrrrrgggrrrrrrrk',
    [51] = '................krrrrrrrrrgggrrrrrrrk',
    [52] = '.................krrrrrrrrggrrrrrrk',
    -- quadris e pernas: esquerda 's' (atrás), direita 'S' (apoio)
    [53] = '.................kssssssk..kSSSSSSk',
    [54] = '.................kssssssk..kSSSSSSk',
    [55] = '................ksssssssk..kSSSSSSSk',
    [56] = '................ksssssssk..kSSSSSSSk',
    [57] = '................ksssssssk...kSSSSSSk',
    [58] = '................ksssssssk...kSSSSSSk',
    [59] = '................kssssssk....kSSSSSSk',
    [60] = '................kssssssk....kSSSSSSk',
    [61] = '................kssssssk....kSSSSSSk',
    [62] = '................kssssssk....kSSSSSSk',
    [63] = '................kssssssk....kSSSSSSk',
    [64] = '................kssssssk....kSSSSSSk',
    [65] = '................kssssssk....kSSSSSSk',
    [66] = '................kssssssk....kSSSSSSk',
    [67] = '................kssssssk....kSSSSSSk',
    [68] = '................kssssssk....kSSSSSSk',
    [69] = '................kssssssk....kSSSSSSk',
    [70] = '................kssssssk....kSSSSSSk',
    [71] = '................kssssssk....kSSSSSSk',
    [72] = '................kssssssk....kSSSSSSk',
    [73] = '................kssssssk....kSSSSSSk',
    [74] = '................kssssssk....kSSSSSSk',
    [75] = '................kssssssk....kSSSSSSk',
    [76] = '................kssssssk....kSSSSSSk',
    [77] = '................kssssssk....kSSSSSSk',
    [78] = '................kssssssk....kSSSSSSk',
    [79] = '................kssssssk....kSSSSSSk',
    [80] = '................kssssssk....kSSSSSSk',
    [81] = '................kssssssk....kSSSSSSk',
    [82] = '................kssssssk....kSSSSSSk',
    [83] = '................kssssssk....kSSSSSSk',
    -- pés de bloco: esquerdo recuado (de trás), direito plantado à frente
    [84] = '................kssssssk....kSSSSSSk',
    [85] = '...............ksssssssk...kSSSSSSSSk',
    [86] = '...............kssssssssk..kSSSSSSSSk',
    [87] = '...............kssssssssk..kSSSSSSSSk',
    [88] = '...............kDDssssssk..kSSSSSSTSk',
    [89] = '...............kssssssssk..kSSSSSSSSk',
    [90] = '...............kbbbbssbbk..kbbSSSSbbk',
    [91] = '...............kbbbbbbbk...kbbbbbbbbk',
    [92] = '................kkkkkkkk....kkkkkkkkk',
}

-- WARN: perna de trás (esquerda) estica para trás e para fora — o pé
-- recua, a canela inclina; o apoio direito firma. Só as pernas mudam.
local bodyWarn = {
    [30] = '...................kkkkkkkkkkkkkk',
    [31] = '..................kSSSSSSSSSSSSSSk',
    [32] = '.................kSSSSSSSSSSSSSSSSk',
    [33] = '................kTSSSSSSSSSSSSSSSSSSk',
    [34] = '................kTSSSSSSSSSSSSSSSSSSk',
    [35] = '...............kTSSSSSSSSSSSSSSSSSSSSk',
    [36] = '...............kTSSSShSSSSSSSSSSSSSSSSk',
    [37] = '...............kTSSSShSSSSSSSSSSSSSSSSk',
    [38] = '..............kTSSSSShSSSSSSSSSSSSSSSSsk',
    [39] = '..............kTSSSSSSSSSSSkSSSSSSSSSSsk',
    [40] = '..............kTSSSSSSSSSSkSSSSSSSSSSSsk',
    [41] = '..............kTSSSmSSSSSSkSSSSSSSSSSSsk',
    [42] = '..............kTSSSSmSSSSkSSSSSSSSSSSssk',
    [43] = '...............kTSSSSmSSSkSSSSSSSSSSSssk',
    [44] = '...............kTSSSSSSSSkSSSSSSSSSSssk',
    [45] = '...............kTSSSSSSSSkSSSSSSSSSSssk',
    [46] = '................kSSSSSSSSSSSSSSSSSSSssk',
    [47] = '................kSSSSSSSSSSSSSSSSSSSssk',
    [48] = '................kSSSSSSSSSSSSSSSSSSssk',
    [49] = '................krrrrrrrrrrrrrrrrrrrk',
    [50] = '................krrrrrrrrrgggrrrrrrrk',
    [51] = '................krrrrrrrrrgggrrrrrrrk',
    [52] = '.................krrrrrrrrggrrrrrrk',
    [53] = '.................kssssssk..kSSSSSSk',
    [54] = '................ksssssssk..kSSSSSSSk',
    [55] = '................ksssssssk..kSSSSSSSk',
    [56] = '...............ksssssssk...kSSSSSSSk',
    [57] = '...............kssssssk....kSSSSSSSk',
    [58] = '...............kssssssk....kSSSSSSk',
    [59] = '..............kssssssk.....kSSSSSSk',
    [60] = '..............kssssssk.....kSSSSSSk',
    [61] = '.............kssssssk......kSSSSSSk',
    [62] = '.............kssssssk......kSSSSSSk',
    [63] = '............kssssssk.......kSSSSSSk',
    [64] = '............kssssssk.......kSSSSSSk',
    [65] = '............kssssssk.......kSSSSSSk',
    [66] = '...........kssssssk........kSSSSSSk',
    [67] = '...........kssssssk........kSSSSSSk',
    [68] = '...........kssssssk........kSSSSSSk',
    [69] = '..........kssssssk.........kSSSSSSk',
    [70] = '..........kssssssk.........kSSSSSSk',
    [71] = '..........kssssssk.........kSSSSSSk',
    [72] = '.........kssssssk..........kSSSSSSk',
    [73] = '.........kssssssk..........kSSSSSSk',
    [74] = '.........kssssssk..........kSSSSSSk',
    [75] = '........kssssssk...........kSSSSSSk',
    [76] = '........kssssssk...........kSSSSSSk',
    [77] = '........kssssssk...........kSSSSSSk',
    [78] = '........kssssssk...........kSSSSSSk',
    [79] = '.......kssssssk............kSSSSSSk',
    [80] = '.......kssssssk............kSSSSSSk',
    [81] = '.......kssssssk............kSSSSSSk',
    [82] = '......kssssssk.............kSSSSSSk',
    [83] = '......kssssssk.............kSSSSSSk',
    -- pé de trás arrasta para trás: só a ponta da garra toca o chão
    [84] = '......ksssssk..............kSSSSSSk',
    [85] = '.....ksssssk..............kSSSSSSSSk',
    [86] = '.....kssssk...............kSSSSSSSSk',
    [87] = '....kssssk................kSSSSSSSSk',
    [88] = '....ksssk.................kSSSSSSTSk',
    [89] = '....kssbk.................kSSSSSSSSk',
    [90] = '....kbbbk.................kbbSSSSbbk',
    [91] = '....kbbb k................kbbbbbbbbk',
    [92] = '.....kkkk..................kkkkkkkkk',
}

--------------------------------------------------------------------------------
-- ARMS: braços-pilar pendendo — esquerdo curto (atrás), direito longo
-- com punho-bloco apoiado. Camada própria para o punho cobrir o tronco.
--------------------------------------------------------------------------------
local arms = {
    -- o braço de impacto desce da laje do ombro (emenda em r36-38)
    [36] = '........................................kSSSSSSSk',
    [37] = '........................................kSSSSSSSk',
    [38] = '.........kk...............................kSSSSk',
    [39] = '........kssk...............................kSSSSk',
    [40] = '........kssk...............................kSSSSk',
    [41] = '.......kssssk..............................kSSSSk',
    [42] = '.......kssssk..............................kSSSSk',
    [43] = '.......kssssk..............................kSSSSk',
    [44] = '.......kssssk..............................kSSSSk',
    [45] = '.......kssssk..............................kSSSSk',
    [46] = '.......kssssk..............................kSSSSk',
    [47] = '.......kssssk..............................kSSSSk',
    [48] = '.......kssssk..............................kSSSSk',
    [49] = '.......kssssk..............................kSSSSk',
    [50] = '.......kssssk..............................kSSSSk',
    [51] = '.......kssssk..............................kSSSSk',
    [52] = '.......kssssk..............................kSSSSk',
    [53] = '.......kssssk..............................kSSSSk',
    [54] = '.......kssssk..............................kSSSSk',
    [55] = '.......kssssk..............................kSSSSk',
    [56] = '........ksssk..............................kSSSSk',
    [57] = '........ksssk..............................kSSSSk',
    [58] = '........ksssk..............................kSSSSk',
    [59] = '........ksssk..............................kSSSSk',
    [60] = '........ksssk..............................kSSSSk',
    [61] = '........ksssk..............................kSSSSk',
    [62] = '........ksssk..............................kSSSSk',
    [63] = '........ksssk..............................kSSSSk',
    [64] = '........ksssk..............................kSSSSk',
    [65] = '........ksssk..............................kSSSSk',
    [66] = '........kssk...............................kSSSSk',
    [67] = '........kssk...............................kSSSSk',
    [68] = '........kssk...............................kSSSSk',
    [69] = '........kssk...............................kSSSSk',
    [70] = '........kssk...............................kSSSSk',
    [71] = '........kssk...............................kSSSSk',
    [72] = '.......kssssk..............................kSSSSk',
    [73] = '.......kssssk..............................kSSSSk',
    -- punho-bloco: esquerdo fechado, direito com juntas
    [74] = '......kssssssk............................kSSSSSSk',
    [75] = '......kssssssk............................kSSSSSSk',
    [76] = '......kssssssk............................kSSSSSSk',
    [77] = '......kssssssk............................kSSSSSSk',
    [78] = '......kssssssk............................kSkSSSSk',
    [79] = '......kssssssk............................kSkSkSSk',
    [80] = '.......kkkkkk..............................kSkSkSk',
    [81] = '...........................................kSSSSSSk',
    [82] = '...........................................kSkSkSkk',
    [83] = '...........................................kkkkkkkk',
}

-- WARN: braço de trás recolhe junto ao corpo (encolhe e fica 's'),
-- braço da frente planta o punho-bloco no chão — mola carregada. O
-- braço sobe contínuo até r40 e enfia sob a borda da laje (que no warn
-- desce até r39): sem isso a emenda deixava um vão de ~7 linhas.
local armsWarn = {
    [40] = '.............................................kSSSSk',
    [41] = '.............................................kSSSSk',
    [42] = '.............................................kSSSSk',
    [43] = '.............................................kSSSSk',
    [44] = '.........kssk................................kSSSSk',
    [45] = '.........kssk................................kSSSSk',
    [46] = '.........kssk................................kSSSSk',
    [47] = '.........kssk................................kSSSSk',
    [48] = '.........kssk................................kSSSSk',
    [49] = '.........kssk................................kSSSSk',
    [50] = '.........kssk................................kSSSSk',
    [51] = '.........kssk................................kSSSSk',
    [52] = '.........kssk................................kSSSSk',
    [53] = '.........kssk................................kSSSSk',
    [54] = '.........kssk................................kSSSSk',
    [55] = '.........kssk................................kSSSSk',
    [56] = '.........kssk................................kSSSSk',
    [57] = '.........kssk................................kSSSSk',
    [58] = '.........kssk................................kSSSSk',
    [59] = '.........kssk................................kSSSSk',
    [60] = '.........kssk................................kSSSSk',
    [61] = '.........kssk................................kSSSSk',
    [62] = '.........kssk................................kSSSSk',
    [63] = '........kssssk...............................kSSSSk',
    [64] = '........kssssk...............................kSSSSk',
    [65] = '........kssssk...............................kSSSSk',
    [66] = '........kkkkkk...............................kSSSSk',
    [67] = '.............................................kSSSSk',
    [68] = '............................................kSSSSSSk',
    [69] = '............................................kSSSSSSk',
    [70] = '............................................kSSSSSSk',
    [71] = '............................................kSSSSSSk',
    [72] = '............................................kSSSSSSk',
    [73] = '............................................kSSSSSSk',
    [74] = '............................................kSSSSSSk',
    [75] = '............................................kSSSSSSk',
    [76] = '............................................kSSSSSSk',
    [77] = '............................................kSSSSSSk',
    [78] = '...........................................kSSSSSSSSk',
    [79] = '...........................................kSSSSSSSSk',
    [80] = '...........................................kSSSSSSSSk',
    [81] = '...........................................kSkSkSkSSk',
    [82] = '...........................................kSkSkSkSSk',
    [83] = '...........................................kkkkkkkkkk',
}

--------------------------------------------------------------------------------
-- PAULDRONS: laje do ombro de impacto (direita, alta e larga) + ombro de
-- trás menor com retalho de capa violeta.
--------------------------------------------------------------------------------
local pauldron = {
    [22] = '...................................kkkkkkkkkkkkkkk',
    [23] = '..................................kTTTTTTTTTTTTTTTk',
    [24] = '.................................kTSSSSSSSSSSSSSSSSk',
    [25] = '................................kTSSSSSSSSSSSSSSSSSSk',
    [26] = '...............................kTSSSSSSSSSSSSSSSSSSSSk',
    [27] = '...............................kTSSSShSSSSSSSSSSSSSSSk',
    [28] = '..............................kTSSSSShSSSSSSSSSSSSSSSSk',
    [29] = '..............................kTSSSSSSSSSSSSSSSSSSSSSSk',
    [30] = '..............................kTSSSSSSSSSSkSSSSSSSSSSsk',
    [31] = '..............................kTSSSSSSSSSkSSSSSSSSSSSSsk',
    [32] = '.............................kTSSSSSSSSSSkSSSSSSSSSSSSsk',
    [33] = '.............................kTSSSSmSSSSSkSSSSSSmSSSSSsk',
    [34] = '.............................kSSSSSSSSSSkSSSSSSSSSSSSssk',
    [35] = '.............................kssssssssssksssssssssssssk',
    -- virola de ouro na borda da laje
    [36] = '.............................kggggggggggkgggggggggggggk',
    -- ombro de trás (esquerdo): menor, encoberto
    [27] = '..............kkkkkkkkk',
    [28] = '.............kTTTTTTTTk',
    [29] = '............kTSSSSSSSSk',
    [30] = '............kTSSSSSSSSk',
    [31] = '...........kTSSSSSSSSSSk',
    [32] = '...........kTSSSSSSSSSSk',
    [33] = '...........ksssssssssssk',
}

-- WARN: laje do ombro mergulha 3px com o corpo (aplicada via shift no
-- layers), sem mapa próprio.

--------------------------------------------------------------------------------
-- HEAD: crânio de carneiro baixo, enfiado entre os ombros — testa 'b'
-- projetada à frente, fenda de olho 'e' (danger), queixo curto. Chifres
-- 'B' com virola 'r' na base: esquerdo varre para cima-esquerda,
-- direito é a ponta de carga — varre para cima-direita, mais longo.
--------------------------------------------------------------------------------
local head = {
    -- chifre esquerdo (atrás): ponta sobe para fora
    [17] = '...............kB',
    [18] = '..............kBBk',
    [19] = '.............kBBk',
    [20] = '............kBBk',
    [21] = '...........kBBBk',
    [22] = '..........kBBBk',
    [23] = '.........kBBBk',
    [24] = '........kBBBrk',
    [25] = '.......kBBBrk',
    -- chifre direito (carga): mais longo, cruza o topo do ombro
    [15] = '..................................................kB',
    [16] = '.................................................kBBk',
    [17] = '................................................kBBk',
    [18] = '...............................................kBBk',
    [19] = '..............................................kBBBk',
    [20] = '.............................................kBBBk',
    [21] = '............................................kBBBk',
    [22] = '...........................................kBBBk',
    [23] = '..........................................kBBBrk',
    [24] = '.........................................kBBBrk',
    -- crânio baixo entre os ombros
    [25] = '...........................kkkkkkkkkkk',
    [26] = '..........................kSSSSSSSSSSSk',
    [27] = '.........................kSSSSSSSSSSSSSk',
    [28] = '.........................kSbSSSSSSSSbSSk',
    [29] = '........................kSSbSSSSSSSSbSSSk',
    [30] = '........................kSSSSSSSSSSSSSSSk',
    [31] = '........................kSSSSSSSSSSSSSSSk',
    -- fenda de olho: 'e' apagado no idle
    [32] = '........................kSSeESSSSSSeESSk',
    [33] = '........................kSSeESSSSSSeESSk',
    [34] = '.........................kSSSSSSSSSSSSk',
    [35] = '.........................kSSSSSSSSSSSSk',
    -- focinho/queixo de carneiro descendo
    [36] = '..........................kSbSSSSSSbSk',
    [37] = '..........................kSbSSSSSSbSk',
    [38] = '...........................kSSSSSSSSk',
    [39] = '...........................kbSSSSSSbk',
    [40] = '............................kSSSSSSk',
    [41] = '............................kkkkkkkk',
}

local headWarn = {
    -- chifres baixam junto com o crânio (mergulho da carga)
    [20] = '...............kB',
    [21] = '..............kBBk',
    [22] = '.............kBBk',
    [23] = '............kBBk',
    [24] = '...........kBBBk',
    [25] = '..........kBBBk',
    [26] = '.........kBBBk',
    [27] = '........kBBBrk',
    [28] = '.......kBBBrk',
    [18] = '..................................................kB',
    [19] = '.................................................kBBk',
    [20] = '................................................kBBk',
    [21] = '...............................................kBBk',
    [22] = '..............................................kBBBk',
    [23] = '.............................................kBBBk',
    [24] = '............................................kBBBk',
    [25] = '...........................................kBBBk',
    [26] = '..........................................kBBBrk',
    [27] = '.........................................kBBBrk',
    [28] = '...........................kkkkkkkkkkk',
    [29] = '..........................kSSSSSSSSSSSk',
    [30] = '.........................kSSSSSSSSSSSSSk',
    [31] = '.........................kSbSSSSSSSSbSSk',
    [32] = '........................kSSbSSSSSSSSbSSSk',
    [33] = '........................kSSSSSSSSSSSSSSSk',
    [34] = '........................kSSSSSSSSSSSSSSSk',
    -- fenda de olho ESCANCARADA 'E' (danger cheio)
    [35] = '........................kSSEESSSSSSEESSk',
    [36] = '........................kSSEESSSSSSEESSk',
    [37] = '.........................kSSSSSSSSSSSSk',
    [38] = '.........................kSSSSSSSSSSSSk',
    [39] = '..........................kSbSSSSSSbSk',
    [40] = '..........................kSbSSSSSSbSk',
    [41] = '...........................kSSSSSSSSk',
    [42] = '...........................kbSSSSSSbk',
    [43] = '............................kSSSSSSk',
    [44] = '............................kkkkkkkk',
}

--------------------------------------------------------------------------------
-- CAPE: retalho violeta preso no ombro de trás — pontas irregulares.
--------------------------------------------------------------------------------
local cape = {
    [30] = '.........kuuk',
    [31] = '........kuvvk',
    [32] = '........kuvvvk',
    [33] = '........kuvvvvk',
    [34] = '........kuvvvvvk',
    [35] = '........kuvvvvvk',
    [36] = '........kuvVvvvvk',
    [37] = '........kuvvvvvvk',
    [38] = '.........kuvvvvvk',
    [39] = '.........kuvVvvvk',
    [40] = '.........kuvvvvvk',
    [41] = '.........kuvvvvk',
    [42] = '..........kuvvvk',
    [43] = '..........kuvvvk',
    [44] = '..........kuvvk',
    [45] = '..........kuvk',
    [46] = '..........kvuk',
    [47] = '..........kvvk',
    [48] = '..........kvuk',
    [49] = '...........kvk',
    [50] = '...........kuk',
    [51] = '...........kvk',
    [52] = '............kk',
}

return {
    name = 'foe_dasher',
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
        B = {ramp = 'bone', step = 5, h = 7},
        v = {ramp = 'violet', step = 3, h = 4},
        u = {ramp = 'violet', step = 2, h = 3},
        V = {ramp = 'violet', step = 4, h = 5},
        m = {ramp = 'moss', step = 2, h = 4},
        r = {ramp = 'rust', step = 3, h = 5},
        g = {ramp = 'gold', step = 4, h = 6},
        e = {spec = 'danger', h = 7, e = 'danger', ei = .45},
        E = {spec = 'danger', h = 7, e = 'danger', ei = 1},
    },

    layers = {
        {name = 'cape', h = 4, albedo = {
            R(cape),
            R(shift(cape, 1, 30, 52)),
            R(shift(cape, 3, 30, 52)),
        }},
        {name = 'body', h = 5, albedo = {
            R(body),
            R(shift(body, 1, 30, 52)),       -- respira: tronco desce 1px
            R(bodyWarn),
        }},
        {name = 'arms', h = 5, albedo = {
            R(arms),
            R(arms),
            R(armsWarn),
        }},
        {name = 'pauldron', h = 7, albedo = {
            R(pauldron),
            R(shift(pauldron, 1, 22, 36)),
            R(shift(pauldron, 3, 22, 36)),   -- ombro de impacto mergulha
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 15, 41)),
            R(headWarn),
        }, emissive = {
            R {
                [32] = '............................ee......ee',
                [33] = '............................ee......ee',
            },
            R {
                [33] = '............................ee......ee',
                [34] = '............................ee......ee',
            },
            R {
                [35] = '............................EE......EE',
                [36] = '............................EE......EE',
                -- virolas dos chifres acordam na carga
                [27] = '.........r...........................r',
            },
        }},
    },
}
