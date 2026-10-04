-- GUARDIÃO DOS ECOS (foe_warden) — o porteiro que ainda cumpre a última
-- ordem, 64x96, origem nos pés. Build 'tower': o corpo É a porta — laje
-- de ombros simétrica, torso-laje com o SELO FRONTAL (placa 'h' em
-- moldura de ouro 'g' com cruz-sigilo 'x'), e da cintura para baixo um
-- bloco-porta com junta central que desce até a base-plinto. À direita,
-- o estandarte da ordem: haste de osso com pano violeta sigilado. À
-- esquerda, a mão aberta de comando.
-- Frames: [1,2] idle (respiração: torso desce 1px), [3] WARN = a mão sobe
-- em gesto de parada, o corpo assenta 1px sob a ordem e o selo 'X', o
-- sigilo do estandarte e os olhos acendem.
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
-- BODY: laje de ombros + torso-laje com o selo frontal + bloco-porta até
-- a base. O selo é o alvo da mecânica: 'x' apagado no idle.
--------------------------------------------------------------------------------
local body = {
    -- laje de ombros simétrica
    [24] = '..................kkkkkkkkkkkkkkkkkkkkkkkkkk',
    [25] = '.................kTTTTTTTTTTTTTTTTTTTTTTTTTTk',
    [26] = '................kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [27] = '................kTSSSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [28] = '................kTSSSSSSSSkSSSSSSSSSSkSSSSSSSSk',
    [29] = '................kTSSSSmSSSkSSSSSSSSSSkSSSmSSSSk',
    [30] = '................kTSSSSSSSSkSSSSSSSSSSkSSSSSSSSk',
    [31] = '................ksssssssssksssssssssskssssssssk',
    -- torso-laje
    [32] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [33] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [34] = '.................kTSSSSShSSSSSSSSSSSShSSSSSSk',
    [35] = '.................kTSSSSShSSSSSSSSSSSShSSSSSSk',
    [36] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSSk',
    [37] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSSk',
    -- SELO FRONTAL: moldura 'g', placa 'h', cruz-sigilo 'x'
    [38] = '.................kTSSSSkggggggggggggggkSSSSSk',
    [39] = '.................kTSSSSkghhhhhhhhhhhhgkSSSSSk',
    [40] = '.................kTSSSSkghhhhhxhhhhhhgkSSSSSk',
    [41] = '.................kTSSSSkghhhhhxhhhhhhgkSSSSSk',
    [42] = '.................kTSSSSkghhhhhxhhhhhhgkSSSSSk',
    [43] = '.................kTSSSSkghhhxxxxxhhhhgkSSSSSk',
    [44] = '.................kTSSSSkghhhhhxhhhhhhgkSSSSSk',
    [45] = '.................kTSSSSkghhhhhxhhhhhhgkSSSSSk',
    [46] = '.................kTSSSSkghhhhhxhhhhhhgkSSSSSk',
    [47] = '.................kTSSSSkghhhhhhhhhhhhgkSSSSSk',
    [48] = '.................kTSSSSkggggggggggggggkSSSSSk',
    [49] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSSk',
    [50] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSSk',
    [51] = '.................kTSSSSSSSSSkSSSSSSSSSSSSSk',
    [52] = '.................kTSSSSSSSSkSSSSSSSSSSSSSSk',
    [53] = '.................kTSSSSmSSSkSSSSSSSSSSmSSSk',
    [54] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSk',
    [55] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSk',
    -- cinta de ferrugem + fivela de ouro
    [56] = '.................krrrrrrrrrrrrrrrrrrrrrrrrk',
    [57] = '.................krrrrrrrrrrrrgGggrrrrrrrrk',
    [58] = '.................krrrrrrrrrrrrgGggrrrrrrrrk',
    [59] = '.................krrrrrrrrrrrrrrrrrrrrrrrrk',
    -- bloco-porta: junta central 'k' desce até a base
    [60] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [61] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [62] = '.................kSSSSmSSSSSSSSkSSSSSSSSmSSSk',
    [63] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [64] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [65] = '.................kSSSSSkSSSSSSSkSSSSSSSkSSSSk',
    [66] = '.................kSSSSSkSSSSSSSkSSSSSSSkSSSSk',
    [67] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [68] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [69] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [70] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [71] = '.................kSSSSmSSSSSSSSkSSSSSSSSmSSSk',
    [72] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [73] = '.................kSSSSSkSSSSSSSkSSSSSSSkSSSSk',
    [74] = '.................kSSSSSkSSSSSSSkSSSSSSSkSSSSk',
    [75] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [76] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [77] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [78] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [79] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [80] = '.................kSSSSmSSSSSSSSkSSSSSSSSmSSSk',
    [81] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [82] = '.................kSSSSSkSSSSSSSkSSSSSSSkSSSSk',
    [83] = '.................kSSSSSkSSSSSSSkSSSSSSSkSSSSk',
    [84] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [85] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [86] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    [87] = '.................kSSSSSSSSSSSSSkSSSSSSSSSSSSk',
    -- base-plinto alargada
    [88] = '................kssssssssssssssssssssssssssssk',
    [89] = '................kssssssssssssssssssssssssssssk',
    [90] = '...............kDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDk',
    [91] = '...............kDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDk',
    [92] = '...............kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
}

--------------------------------------------------------------------------------
-- HEAD: cabeça formal pequena — elmo-mitra de pedra com faixa de diadema
-- 'g', olhos 'e' violeta em fenda dupla.
--------------------------------------------------------------------------------
local head = {
    [14] = '.............................kkkkkkkk',
    [15] = '............................kSSSSSSSSk',
    [16] = '............................kSSSSSSSSk',
    -- faixa de diadema
    [17] = '............................kggggggggk',
    [18] = '............................kSSSSSSSSk',
    [19] = '............................kSbSSSSbSk',
    -- olhos 'e' apagados
    [20] = '............................kSSeSSeSSk',
    [21] = '............................kSSSSSSSSk',
    [22] = '.............................kSSSSSSk',
    [23] = '..............................kkkkkk',
}

local headWarn = {
    -- cabeça desce 1px com o assentar do corpo, olhos 'E'
    [15] = '.............................kkkkkkkk',
    [16] = '............................kSSSSSSSSk',
    [17] = '............................kSSSSSSSSk',
    [18] = '............................kggggggggk',
    [19] = '............................kSSSSSSSSk',
    [20] = '............................kSbSSSSbSk',
    [21] = '............................kSEESSEESk',
    [22] = '............................kSSSSSSSSk',
    [23] = '.............................kSSSSSSk',
    [24] = '..............................kkkkkk',
}

--------------------------------------------------------------------------------
-- HAND: mão aberta de comando no flanco esquerdo. IDLE: palma de frente
-- à altura do quadril; WARN: sobe ao peito em gesto de parada.
--------------------------------------------------------------------------------
local hand = {
    [51] = '..........kkkkkkk',
    -- dedos separados
    [52] = '..........kbkbkbkbk',
    [53] = '..........kbbbbbbbk',
    [54] = '..........kbbbbbbbk',
    [55] = '..........kbbbbbbbk',
    [56] = '..........kbbbbbbbk',
    -- pulso e antebraço de pedra até a laje
    [57] = '...........kbbkkssk',
    [58] = '..............ksssk',
    [59] = '..............ksssk',
    [60] = '...............kk',
}

local handWarn = {
    -- palma erguida à altura do selo: o gesto de parada
    [36] = '..........kkkkkkk',
    [37] = '..........kbkbkbkbk',
    [38] = '..........kbbbbbbbk',
    [39] = '..........kbbbbbbbk',
    [40] = '..........kbbbbbbbk',
    [41] = '..........kbbbbbbbk',
    [42] = '...........kbbk',
    -- antebraço descendo em diagonal até a laje
    [43] = '............kssk',
    [44] = '.............kssk',
    [45] = '.............kssk',
    [46] = '..............kssk',
    [47] = '..............kssk',
    [48] = '...............kk',
}

--------------------------------------------------------------------------------
-- BANNER: estandarte da ordem à direita — haste de osso 'b' plantada no
-- chão, verga transversal, pano violeta 'v'/'u' com cruz-sigilo 'x' e
-- barra mastigada. Manga 'v' + mão 'b' seguram a haste.
--------------------------------------------------------------------------------
local banner = {
    -- remate da haste
    [6]  = '..................................................kgk',
    [7]  = '..................................................kgk',
    [8]  = '..................................................kbk',
    [9]  = '..................................................kbk',
    -- verga transversal
    [10] = '.............................................kbbbbbbbbbbbk',
    -- pano pendurado na verga, à direita da haste
    [11] = '..................................................kbk.kvvvvk',
    [12] = '..................................................kbk.kvvvvvk',
    [13] = '..................................................kbk.kvvvvvk',
    [14] = '..................................................kbk.kvvxvvk',
    [15] = '..................................................kbk.kvxxxvk',
    [16] = '..................................................kbk.kvvxvvk',
    [17] = '..................................................kbk.kvvvvvk',
    [18] = '..................................................kbk.kvvvvk',
    [19] = '..................................................kbk.kvuvvk',
    [20] = '..................................................kbk.kvv.vk',
    [21] = '..................................................kbk.kv..vk',
    [22] = '..................................................kbk.k...k',
    -- haste continua
    [23] = '..................................................kbk',
    [24] = '..................................................kbk',
    [25] = '..................................................kbk',
    [26] = '..................................................kbk',
    [27] = '..................................................kbk',
    [28] = '..................................................kbk',
    [29] = '..................................................kbk',
    [30] = '..................................................kbk',
    [31] = '..................................................kbk',
    [32] = '..................................................kbk',
    [33] = '..................................................kbk',
    [34] = '..................................................kbk',
    [35] = '..................................................kbk',
    [36] = '..................................................kbk',
    [37] = '..................................................kbk',
    [38] = '..................................................kbk',
    [39] = '..................................................kbk',
    [40] = '..................................................kbk',
    [41] = '..................................................kbk',
    [42] = '..................................................kbk',
    [43] = '..................................................kbk',
    [44] = '..................................................kbk',
    [45] = '..................................................kbk',
    [46] = '..................................................kbk',
    [47] = '..................................................kbk',
    -- manga sai da laje e a mão fecha na haste
    [48] = '............................................kvvk..kbk',
    [49] = '.............................................kvvk.kbk',
    [50] = '..............................................kbbkkbk',
    [51] = '..............................................kbbkkbk',
    [52] = '...............................................kkkkbk',
    -- haste desce até a ponta cravada no chão
    [53] = '..................................................kbk',
    [54] = '..................................................kbk',
    [55] = '..................................................kbk',
    [56] = '..................................................kbk',
    [57] = '..................................................kbk',
    [58] = '..................................................kbk',
    [59] = '..................................................kbk',
    [60] = '..................................................kbk',
    [61] = '..................................................kbk',
    [62] = '..................................................kbk',
    [63] = '..................................................kbk',
    [64] = '..................................................kbk',
    [65] = '..................................................kbk',
    [66] = '..................................................kbk',
    [67] = '..................................................kbk',
    [68] = '..................................................kbk',
    [69] = '..................................................kbk',
    [70] = '..................................................kbk',
    [71] = '..................................................kbk',
    [72] = '..................................................kbk',
    [73] = '..................................................kbk',
    [74] = '..................................................kbk',
    [75] = '..................................................kbk',
    [76] = '..................................................kbk',
    [77] = '..................................................kbk',
    [78] = '..................................................kbk',
    [79] = '..................................................kbk',
    [80] = '..................................................kbk',
    [81] = '..................................................kbk',
    [82] = '..................................................kbk',
    [83] = '..................................................kbk',
    [84] = '..................................................kbk',
    [85] = '..................................................kbk',
    [86] = '..................................................kbk',
    [87] = '..................................................kbk',
    [88] = '..................................................kkk',
    [89] = '..................................................kkk',
}

return {
    name = 'foe_warden',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 4},
        S = {ramp = 'stone', step = 4, h = 6},
        h = {ramp = 'stone', step = 5, h = 7},
        T = {ramp = 'stone', step = 6, h = 8},
        D = {ramp = 'stone', step = 2, h = 4},
        b = {ramp = 'bone', step = 4, h = 5},
        v = {ramp = 'violet', step = 3, h = 4},
        u = {ramp = 'violet', step = 2, h = 3},
        m = {ramp = 'moss', step = 2, h = 4},
        r = {ramp = 'rust', step = 3, h = 5},
        g = {ramp = 'gold', step = 5, h = 6},
        G = {ramp = 'gold', step = 6, h = 7},
        x = {ramp = 'violet', step = 4, h = 7, e = 'violet.5', ei = .5},
        X = {ramp = 'violet', step = 5, h = 7, e = 'violet.6', ei = 1},
        e = {ramp = 'violet', step = 5, h = 7, e = 'violet.5', ei = .45},
        E = {ramp = 'violet', step = 6, h = 7, e = 'violet.6', ei = 1},
    },

    layers = {
        {name = 'body', h = 5, albedo = {
            R(body),
            R(shift(body, 1, 24, 87)),       -- respira
            R(shift(body, 1, 24, 87)),       -- WARN: assenta sob a ordem
        }},
        {name = 'banner', h = 5, albedo = {
            R(banner), R(banner), R(banner),
        }},
        {name = 'hand', h = 6, albedo = {
            R(hand), R(hand), R(handWarn),
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 14, 23)),
            R(headWarn),
        }, emissive = {
            R {
                -- olhos + selo + sigilo do estandarte, apagados
                [20] = '...............................e..e',
                [40] = '..............................x',
                [41] = '..............................x',
                [42] = '..............................x',
                [43] = '............................xxxxx',
                [44] = '..............................x',
                [45] = '..............................x',
                [46] = '..............................x',
                [14] = '.........................................................x',
                [15] = '.......................................................xxx',
                [16] = '.........................................................x',
            },
            R {
                [21] = '...............................e..e',
                [41] = '..............................x',
                [42] = '..............................x',
                [43] = '..............................x',
                [44] = '............................xxxxx',
                [45] = '..............................x',
                [46] = '..............................x',
                [47] = '..............................x',
                [14] = '.........................................................x',
                [15] = '.......................................................xxx',
                [16] = '.........................................................x',
            },
            R {
                -- tudo aceso: o selo declara a cruz
                [21] = '..............................EE..EE',
                [41] = '..............................X',
                [42] = '..............................X',
                [43] = '..............................X',
                [44] = '............................XXXXX',
                [45] = '..............................X',
                [46] = '..............................X',
                [47] = '..............................X',
                [14] = '.........................................................X',
                [15] = '.......................................................XXX',
                [16] = '.........................................................X',
            },
        }},
    },
}
