-- BRUTO DEMOLIDOR (foe_breaker) — o maior eco dos sepultados, 64x96,
-- origem nos pés. Muro de pedra: laje de ombros quase de ponta a ponta
-- do frame, cabeça pequena afundada entre elas, braços-marreta que
-- terminam em punho-bloco apoiado no chão, capa violeta esfarrapada
-- pendurada no ombro esquerdo, pernas-coluna curtas.
-- Frames: [1,2] idle (respiração), [3] WARN = levanta os dois braços
-- por cima da cabeça — a silhueta abre em arco e o olho acende.
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
-- BODY: laje de ombros + tronco-cortina com fendas de placa e musgo,
-- faixa de ferrugem na cintura, pernas-coluna, pés de bloco.
--------------------------------------------------------------------------------
local body = {
    -- laje de ombros: quase de ponta a ponta
    [22] = '............kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    [23] = '...........kTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTk',
    [24] = '..........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [25] = '.........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [26] = '.........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [27] = '........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [28] = '........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    -- tronco-cortina
    [29] = '........kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [30] = '........kTSSSSShSSSSSSSSSSSSSSSSSSSSSShSSSSSSSSSSk',
    [31] = '........kTSSSSShSSSSSSSSSSSSSSSSSSSSSShSSSSSSSSSSk',
    [32] = '........kTSSSSSSSSSSSkSSSSSSSSSSkSSSSSSSSSSSSSSSk',
    [33] = '........kTSSSSSSSSSSkSSSSSSSSSSSSkSSSSSSSSSSSSSSk',
    [34] = '........kTSSSSmSSSSSkSSSSSSSSSSSSkSSSSSmSSSSSSSSk',
    [35] = '........kTSSSSSmSSSSkSSSSSSSSSSSSSSkSSSSmSSSSSSSk',
    [36] = '........kTSSSSSSSSSSkSSSSSSSSSSSSSSkSSSSSSSSSSSk',
    [37] = '........kTSSSSSSSSSSkSSSSSSSSSSSSSSkSSSSSSSSSSSk',
    [38] = '........kTSSSSSSSSSSSkSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [39] = '.........kTSSSSSSSSSSkSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [40] = '.........kTSSSSSSSSSSkSSSSSSSSSSSSkSSSSSSSSSSSk',
    [41] = '.........kTSSSSSSSSSSkSSSSSSSSSSSSkSSSSSSSSSSSk',
    [42] = '.........kTSSSSSSSSSSSkSSSSSSSSSSkSSSSSSSSSSSSk',
    [43] = '.........kTSSSSSSSSSSSkSSSSSSSSSSkSSSSSSSSSSSSk',
    [44] = '.........kSSSSSSSSSSSSkSSSSSSSSSSkSSSSSSSSSSSSk',
    [45] = '.........kSSSSSSSSSSSSkSSSSSSSSSSkSSSSSSSSSSSSk',
    [46] = '..........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [47] = '..........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [48] = '..........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [49] = '..........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [50] = '..........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [51] = '...........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [52] = '...........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [53] = '...........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [54] = '...........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [55] = '...........kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    -- faixa de ferrugem na cintura
    [56] = '...........krrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrk',
    [57] = '...........krrrrrrrrrrrrrgGggrrrrrrrrrrrrrrk',
    [58] = '...........krrrrrrrrrrrrrgGggrrrrrrrrrrrrrrk',
    [59] = '...........krrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrk',
    -- quadris e pernas-coluna
    [60] = '............kSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [61] = '............kSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [62] = '............kSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [63] = '............kSSSSSSk...kSSSSk...kSSSSSSk',
    [64] = '............kSSSSSSk...kSSSSk...kSSSSSSk',
    [65] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [66] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [67] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [68] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [69] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [70] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [71] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [72] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [73] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [74] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [75] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [76] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [77] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [78] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [79] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [80] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [81] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [82] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [83] = '............kSSSSSk....kSSSSk....kSSSSSk',
    [84] = '............kSSSSSk....kSSSSk....kSSSSSk',
    -- pés de bloco
    [85] = '...........kSSSSSSk....kSSSSk....kSSSSSSk',
    [86] = '...........kSSSSSSk....kSSSSk....kSSSSSSk',
    [87] = '...........kSSSSSSk....kSSSSk....kSSSSSSk',
    [88] = '..........kSSSSSSSk....kSSSSk....kSSSSSSSk',
    [89] = '..........kSSSSSSSk....kSSSSk....kSSSSSSSk',
    [90] = '..........ksssssssk....kssssk....ksssssssk',
    [91] = '..........ksssssssk....kssssk....ksssssssk',
    [92] = '..........kkkkkkkkk....kkkkkk....kkkkkkkkk',
}

--------------------------------------------------------------------------------
-- ARMS: braços-marreta — ombro escondido sob a laje, antebraço de pedra
-- descendo pela lateral, punho-BLOCO plantado no chão.
--------------------------------------------------------------------------------
local arms = {
    [30] = '.....kkk............................................kkk',
    [31] = '....kSSSk..........................................kSSSk',
    [32] = '....kSSSk..........................................kSSSk',
    [33] = '....kSSSSk........................................kSSSSk',
    [34] = '....kSSSSk........................................kSSSSk',
    [35] = '....kSSSSk........................................kSSSSk',
    [36] = '...kSSSSk..........................................kSSSSk',
    [37] = '...kSSSSk..........................................kSSSSk',
    [38] = '...kSSSSk..........................................kSSSSk',
    [39] = '...kSSSSk..........................................kSSSSk',
    [40] = '...kSSSSk..........................................kSSSSk',
    [41] = '...kSSSSk..........................................kSSSSk',
    [42] = '...kSSSSk..........................................kSSSSk',
    [43] = '...kSSSSk..........................................kSSSSk',
    [44] = '...kSSSSk..........................................kSSSSk',
    [45] = '...kSSSSk..........................................kSSSSk',
    [46] = '...kSSSSk..........................................kSSSSk',
    [47] = '...kSSSSk..........................................kSSSSk',
    [48] = '...kSSSSk..........................................kSSSSk',
    [49] = '...kSSSSk..........................................kSSSSk',
    [50] = '...kSSSSk..........................................kSSSSk',
    [51] = '...kSSSSk..........................................kSSSSk',
    [52] = '...kSSSSk..........................................kSSSSk',
    [53] = '...kSSSSk..........................................kSSSSk',
    [54] = '...kSSSSk..........................................kSSSSk',
    [55] = '...kSSSSk..........................................kSSSSk',
    [56] = '...kSSSSk..........................................kSSSSk',
    [57] = '...kSSSSk..........................................kSSSSk',
    [58] = '...kSSSSk..........................................kSSSSk',
    [59] = '...kSSSSk..........................................kSSSSk',
    [60] = '...kSSSSk..........................................kSSSSk',
    [61] = '...kSSSSk..........................................kSSSSk',
    [62] = '...kSSSSk..........................................kSSSSk',
    [63] = '...kSSSSk..........................................kSSSSk',
    [64] = '...kSSSSk..........................................kSSSSk',
    [65] = '...kSSSSk..........................................kSSSSk',
    [66] = '...kSSSSk..........................................kSSSSk',
    [67] = '...kSSSSk..........................................kSSSSk',
    [68] = '...kSSSSk..........................................kSSSSk',
    [69] = '...kSSSSk..........................................kSSSSk',
    [70] = '...kSSSSk..........................................kSSSSk',
    -- punho-BLOCO no chão: dois blocos de pedra com junta
    [71] = '..kSSSSSSk........................................kSSSSSSk',
    [72] = '..kSSSSSSk........................................kSSSSSSk',
    [73] = '..kSSSSSSk........................................kSSSSSSk',
    [74] = '..kSSSSSSk........................................kSSSSSSk',
    [75] = '..kSSSSSSk........................................kSSSSSSk',
    [76] = '..kSSSSSSk........................................kSSSSSSk',
    [77] = '..kSSSSSSk........................................kSSSSSSk',
    [78] = '..kSSSSSSk........................................kSSSSSSk',
    [79] = '..kSSSSSSk........................................kSSSSSSk',
    [80] = '..kSSSSSSk........................................kSSSSSSk',
    [81] = '..kSSSSSSk........................................kSSSSSSk',
    [82] = '..kSSSSSSk........................................kSSSSSSk',
    [83] = '..kSkSSSSk........................................kSSSSkSk',
    [84] = '..kSkSSSSk........................................kSSSSkSk',
    [85] = '..kSkSSSSk........................................kSSSSkSk',
    [86] = '..kSkSSSSk........................................kSSSSkSk',
    [87] = '..kSkSSSSk........................................kSSSSkSk',
    [88] = '..kSkSSSSk........................................kSSSSkSk',
    [89] = '..kSkSSSSk........................................kSSSSkSk',
    [90] = '..kkkkkkkk........................................kkkkkkkk',
}

-- WARN: braços AO ALTO — dobrados por cima da cabeça, punhos-bloco lado
-- a lado no topo do frame, antebraços em arco descendo aos ombros.
local armsWarn = {
    -- punhos-bloco erguidos, lado a lado sobre a cabeça
    [6]  = '..................kkkkkkkkkkkk..kkkkkkkkkkkk',
    [7]  = '..................kSSSSSSSSSSk..kSSSSSSSSSSk',
    [8]  = '..................kSSSSSSSSSSk..kSSSSSSSSSSk',
    [9]  = '..................kSSSSSSSSSSk..kSSSSSSSSSSk',
    [10] = '..................kSSSSSSSSSSk..kSSSSSSSSSSk',
    [11] = '..................kSSSSSSSSSSk..kSSSSSSSSSSk',
    [12] = '..................kSkSSSSSSSk...kSSSSSSSkSk',
    [13] = '..................kSkSSSSSSSk...kSSSSSSSkSk',
    [14] = '..................kkkkkkkkkkk...kkkkkkkkkkk',
    -- antebraços em arco descendo aos ombros
    [15] = '..............kSSSk....................kSSSk',
    [16] = '.............kSSSSk..................kSSSSk',
    [17] = '............kSSSSSk..................kSSSSSk',
    [18] = '............kSSSSSk..................kSSSSSk',
    [19] = '...........kSSSSSk....................kSSSSSk',
    [20] = '...........kSSSSSk....................kSSSSSk',
    [21] = '..........kSSSSSk......................kSSSSSk',
    [22] = '..........kSSSSk........................kSSSSk',
    [23] = '..........kSSSSk........................kSSSSk',
    [24] = '.........kSSSSk..........................kSSSSk',
    [25] = '.........kSSSSk..........................kSSSSk',
    [26] = '.........kSSSk............................kSSSk',
    [27] = '.........kSSSk............................kSSSk',
    [28] = '.........kSSSk............................kSSSk',
    [29] = '.........kSSSk............................kSSSk',
}

--------------------------------------------------------------------------------
-- HEAD: cabeça pequena afundada na laje — elmo 'S'/'b', fenda de olho
-- 'e' danger, queixo rente ao peito.
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
    -- cabeça some ainda mais entre os ombros; olho escancarado
    [33] = '...........................kkkkkkkkkk',
    [34] = '..........................kSSSSSSSSSk',
    [35] = '..........................kSSSSSSSSSk',
    [36] = '..........................kSbSSSSSbSk',
    [37] = '.........................kSSbSSSSSbSSk',
    [38] = '.........................kSSSSSSSSSSSk',
    [39] = '.........................kSEESSSSEESSk',
    [40] = '.........................kSEESSSSEESSk',
    [41] = '.........................kSSSSSSSSSSSk',
    [42] = '.........................kSSSSSSSSSSk',
    [43] = '..........................kSSSSSSSSk',
    [44] = '..........................kbSSSSSSbk',
    [45] = '...........................kkkkkkkkk',
}

--------------------------------------------------------------------------------
-- CAPE: capa violeta esfarrapada no ombro esquerdo — tiras desiguais.
--------------------------------------------------------------------------------
local cape = {
    [24] = '.........kuuk',
    [25] = '........kuvvvk',
    [26] = '........kuvvvvk',
    [27] = '........kuvvvvvk',
    [28] = '.......kuvvvvvvk',
    [29] = '.......kuvvvvvvvk',
    [30] = '.......kuvVvvvvvk',
    [31] = '.......kuvvvvvvvk',
    [32] = '........kuvvvvvvk',
    [33] = '........kuvvvVvvk',
    [34] = '........kuvvvvvvvk',
    [35] = '........kuvvvvvvvk',
    [36] = '.........kuvvvvvvk',
    [37] = '.........kuvvvvvvk',
    [38] = '.........kuvVvvvvvk',
    [39] = '.........kuvvvvvvvk',
    [40] = '.........kuvvvvvvvk',
    [41] = '..........kuvvvvvvk',
    [42] = '..........kuvvvvvvk',
    [43] = '..........kuvvvvvvk',
    [44] = '..........kuvvvvvk',
    [45] = '..........kuvvvvvk',
    [46] = '..........kuvvvvvk',
    [47] = '..........kuvvvvk',
    [48] = '..........kuvvvvk',
    [49] = '..........kuvvvvk',
    -- pontas esfarrapadas: tiras separadas
    [50] = '..........kuvv.vvk',
    [51] = '..........kuvv.vvk',
    [52] = '..........kuvv..vk',
    [53] = '..........kuvv..vk',
    [54] = '..........kuvv..vk',
    [55] = '..........kvv..vvk',
    [56] = '..........kvv..vvk',
    [57] = '..........kvv..vk',
    [58] = '..........kvk..vk',
    [59] = '..........kvk..vk',
    [60] = '..........kvk..vvk',
    [61] = '..........kuk..vvk',
    [62] = '..........kuk...vk',
    [63] = '..........kvk...vk',
    [64] = '..........kvk...vk',
    [65] = '..........kk....vk',
    [66] = '.................vk',
    [67] = '.................vk',
    [68] = '.................kk',
}

return {
    name = 'foe_breaker',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 4},
        S = {ramp = 'stone', step = 4, h = 6},
        h = {ramp = 'stone', step = 5, h = 7},
        T = {ramp = 'stone', step = 6, h = 8},
        b = {ramp = 'bone', step = 4, h = 5},
        v = {ramp = 'violet', step = 3, h = 4},
        u = {ramp = 'violet', step = 2, h = 3},
        V = {ramp = 'violet', step = 4, h = 5},
        m = {ramp = 'moss', step = 2, h = 4},
        r = {ramp = 'rust', step = 3, h = 5},
        g = {ramp = 'gold', step = 5, h = 6},
        G = {ramp = 'gold', step = 6, h = 7},
        e = {spec = 'danger', h = 7, e = 'danger', ei = .45},
        E = {spec = 'danger', h = 7, e = 'danger', ei = 1},
    },

    layers = {
        {name = 'cape', h = 4, albedo = {
            R(cape),
            R(shift(cape, 1, 24, 68)),
            R(shift(cape, -1, 24, 68)),      -- balanço ao erguer os braços
        }},
        {name = 'body', h = 5, albedo = {
            R(body),
            R(shift(body, 1, 22, 59)),       -- respira
            R(shift(body, 2, 22, 59)),       -- afunda sob a carga
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
                [39] = '...........................EE....EE',
                [40] = '...........................EE....EE',
            },
        }},
    },
}
