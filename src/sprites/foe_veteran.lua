-- SENTINELA VETERANA (foe_veteran) — a atiradora que sobreviveu,
-- 64x96, origem nos pés. Mesma família da foe_ranger (build 'scout'),
-- mas o corpo conta os invernos: capa pesada cobrindo o flanco inteiro,
-- postura mais baixa e fincada, capuz caído, e a falta — a máscara tem
-- UMA órbita só ('ee' jade, o outro lado é órbita fechada 'kk' com
-- costura de ferrugem). A besta virou arbaleste: coronha grossa, asas
-- largas e DOIS virotes 'gg' no trilho — ela dispara duas linhas.
-- Frames: [1,2] idle (respiração), [3] WARN = mira: arbaleste nivelada,
-- olho 'E' e os dois virotes acordam.
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
-- CAPE: manto pesado de veterana — massa fechada cobrindo o flanco
-- esquerdo do pescoço à canela, barra mastigada, e uma aba fina que
-- sobra no ombro direito. Camada de fundo.
--------------------------------------------------------------------------------
local cape = {
    [30] = '..................kkkkkk',
    [31] = '.................kuvvvvvk',
    [32] = '................kuvvvvvvvk',
    -- massa principal do manto + aba fina no ombro direito (mesma linha)
    [33] = '...............kuvvvvvvvvk..........kvk',
    [34] = '..............kuvvvvvvvvvvk.........kvvk',
    [35] = '..............kuvvvvvvvvvvvk........kvvk',
    [36] = '.............kuvvvvvvvvvvvvk........kvvk',
    [37] = '.............kuvvvvvvvvvvvvk........kvvk',
    [38] = '.............kuvvvvvvvvvvvvk........kvvk',
    [39] = '............kuvvvvvvvvvvvvvk........kvvk',
    [40] = '............kuvvvvvvvvvvvvvk........kvvk',
    [41] = '............kuvvvvvvvvvvvvvk........kvvk',
    [42] = '............kuvvvvvvvvvvvvvk........kvvk',
    [43] = '............kuvvvvvvvvvvvvk.........kvvk',
    [44] = '............kuvvvvvvvvvvvvk.........kvvk',
    [45] = '............kuvvvvvvvvvvvvk.........kvvk',
    [46] = '............kuvvvvvvvvvvvvk.........kvvk',
    [47] = '............kuvvvvvvvvvvvvk.........kvvk',
    [48] = '............kuvvvvvvvvvvvvk.........kvvk',
    [49] = '............kuvvvvvvvvvvvvk.........kvvk',
    [50] = '............kuvvvvvvvvvvvvk.........kvvk',
    [51] = '............kuvvvvvvvvvvvvk.........kvvk',
    [52] = '............kuvvvvvvvvvvvuk.........kvk',
    [53] = '............kuvvvvvvvvvvvuk.........kvk',
    [54] = '............kuvvvvvvvvvvvuk.........kk',
    [55] = '............kuvvvvvvvvvvuk',
    [56] = '............kuvvvvvvvvvvuk',
    [57] = '............kuvvvvvvvvvuk',
    [58] = '............kuvvvvvvvvvuk',
    [59] = '............kuvvvvvvvvuk',
    [60] = '............kuvvvvvvvvuk',
    [61] = '............kuvvvvvvvuk',
    [62] = '............kuvvvvvvvuk',
    [63] = '............kuvvvvvvuk',
    [64] = '............kuvvvvvvuk',
    [65] = '............kuvvvvvuk',
    [66] = '............kuvvvvvuk',
    [67] = '............kuvvvvuk',
    [68] = '............kuvvvvuk',
    [69] = '............kuvvVvvuk',
    [70] = '............kuvvvvuk',
    [71] = '............kuvvv.uk',
    [72] = '............kuvv..vk',
    [73] = '............kuvv..vk',
    [74] = '............kvv...vk',
    [75] = '............kvv...vk',
    [76] = '............kv....vk',
    [77] = '............kv...vvk',
    [78] = '............kuk..vk',
    [79] = '............kv...vk',
    [80] = '............kk...kk',
}

--------------------------------------------------------------------------------
-- BODY: pernas curtas e fincadas — postura mais baixa que a ranger.
--------------------------------------------------------------------------------
local body = {
    [80] = '.........................ksssk....ksssk',
    [81] = '.........................ksssk....ksssk',
    [82] = '.........................ksssk....ksssk',
    [83] = '.........................ksssk....ksssk',
    [84] = '.........................ksssk....ksssk',
    [85] = '.........................ksssk....ksssk',
    [86] = '........................kssssk....kssssk',
    [87] = '........................kssssk....kssssk',
    [88] = '........................ksssssk..ksssssk',
    [89] = '........................kssbssk..kssbssk',
    [90] = '........................kbbBbbk..kbbBbbk',
    [91] = '........................kkkkkkk..kkkkkkk',
}

--------------------------------------------------------------------------------
-- ROBE: túnica da mesma família — fenda frontal com peito de pedra 'S'
-- (uma trinca 'k' racha a placa), cinto de ferrugem com fivela 'g' dupla,
-- saia cheia até a barra rasgada.
--------------------------------------------------------------------------------
local robe = {
    [30] = '.........................kkkkkkkkkkkkk',
    [31] = '........................kuvvvvvvvvvvvvk',
    [32] = '........................kvvvvvvvvvvvvvvk',
    [33] = '.......................kvvvvvkSSSSSkvvvvk',
    [34] = '.......................kvvvvkSSSSSSkvvvvk',
    [35] = '.......................kvvvvkSSkSSSkvvvvk',
    [36] = '.......................kvvvvkSSSSSSkvvvvk',
    [37] = '.......................kvvvvkSShSSSkvvvvk',
    [38] = '.......................kvvvvvkSSSSkvvvvvk',
    [39] = '.......................kvvvvvkSSSSkvvvvvk',
    [40] = '.......................kvvvvvvkSSkvvvvvvk',
    [41] = '.......................kvvvvvvkSSkvvvvvvk',
    [42] = '.......................kvvvvvvvkSkvvvvvvk',
    [43] = '.......................kvvvvvvvvkkvvvvvvvk',
    [44] = '.......................kvvvvvvvvvvvvvvvvk',
    [45] = '.......................kvvvvvvvvvvvvvvvvk',
    [46] = '.......................kvvvvvvvvvvvvvvvvk',
    [47] = '.......................kvvvvvvvvvvvvvvvvk',
    [48] = '.......................kvvvvvvvvvvvvvvvvk',
    [49] = '.......................kvvvvvvvvvvvvvvvvk',
    [50] = '.......................kvvvvvvvvvvvvvvvvk',
    [51] = '.......................kvvvvvvvvvvvvvvvvk',
    [52] = '.......................kvvvvvvvvvvvvvvvvk',
    -- cinto de ferrugem + fivela dupla de ouro velho
    [53] = '.......................krrrrrrrrgggrrrrrrk',
    [54] = '.......................krrrrrrrrgggrrrrrrk',
    [55] = '.......................kvvvvvvvvvvvvvvvvvk',
    [56] = '.......................kvvvvvvvvvvvvvvvvvk',
    [57] = '.......................kvvvvvvvvvvvvvvvvvk',
    [58] = '.......................kvvvvvvvvvvvvvvvvvk',
    [59] = '.......................kvvvvvvvvvvvvvvvvvk',
    [60] = '.......................kvvvvvvvvvvvvvvvvvk',
    [61] = '.......................kvvvvvvvvvvvvvvvvvk',
    [62] = '.......................kvvvvvvvvvvvvvvvvvk',
    [63] = '.......................kvvvvvvvvvvvvvvvvvk',
    [64] = '.......................kvvvvvvvvvvvvvvvvvk',
    [65] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [66] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [67] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [68] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [69] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [70] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [71] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [72] = '......................kuvvvvvvvvvvvvvvvvvuk',
    [73] = '......................kuvvvvuvvvvvvuvvvvvuk',
    [74] = '......................kuvvuvvuvvvvuvvvuvvuk',
    -- barra rasgada
    [75] = '......................kuvvv.uvvvvv.uvvvvuk',
    [76] = '......................kuvv.vvuvvvv.vvuvvuk',
    [77] = '......................kvvv..vv.vvv..vvvvk',
    [78] = '......................kvv...vv..vv..vvvk',
    [79] = '......................kvk...v...v...vvk',
    [80] = '......................kv....v...v....vk',
    [81] = '......................kk....k...k....kk',
}

--------------------------------------------------------------------------------
-- HEAD: capuz pesado caído à frente — a veterana não levanta a cara.
-- Máscara de osso com UMA órbita viva 'e' (jade) e a outra fechada 'kk'
-- com costura de ferrugem 'r'. Warn = capuz mergulha 2px, olho 'E'.
--------------------------------------------------------------------------------
local head = {
    [15] = '.............................kkkkk',
    [16] = '............................kuuuuuk',
    [17] = '...........................kuvvvvvvk',
    [18] = '..........................kuvvvvvvvvk',
    [19] = '..........................kuvvvvvvvvk',
    [20] = '.........................kuvvvvvvvvvvk',
    [21] = '.........................kuvvkkkkkvvvk',
    [22] = '.........................kuvkbbbbbbkvk',
    -- órbita viva 'ee' à esquerda, órbita morta 'kk' à direita
    [23] = '.........................kuvkbeebkkbvk',
    -- costura de ferrugem sobre a órbita morta
    [24] = '.........................kuvkbbbbrbkvk',
    [25] = '.........................kuvvkbbbbkvvk',
    [26] = '..........................kvvvkbbkvvk',
    [27] = '..........................kvvvvkkvvvk',
    [28] = '...........................kvvvvvvvk',
    [29] = '...........................kvvvvvvk',
    [30] = '............................kuvvvk',
    [31] = '............................kuvvk',
    [32] = '.............................kvk',
}

local headWarn = {
    [17] = '.............................kkkkk',
    [18] = '............................kuuuuuk',
    [19] = '...........................kuvvvvvvk',
    [20] = '..........................kuvvvvvvvvk',
    [21] = '..........................kuvvvvvvvvk',
    [22] = '.........................kuvvvvvvvvvvk',
    [23] = '.........................kuvvkkkkkvvvk',
    [24] = '.........................kuvkbbbbbbkvk',
    -- olho escancarado 'EE' — a órbita morta continua morta
    [25] = '.........................kuvkbEEbkkbvk',
    [26] = '.........................kuvkbbbbrbkvk',
    [27] = '.........................kuvvkbbbbkvvk',
    [28] = '..........................kvvvkbbkvvk',
    [29] = '..........................kvvvvkkvvvk',
    [30] = '...........................kvvvvvvvk',
    [31] = '...........................kvvvvvvk',
    [32] = '............................kuvvvk',
    [33] = '............................kuvvk',
    [34] = '.............................kvk',
}

--------------------------------------------------------------------------------
-- GEAR: arbaleste — mais larga e pesada que a besta da ranger.
-- IDLE: na vertical no quadril direito, asas 'S' largas, coronha
-- grossa 'kbbbk', aljava 'D' com virotes 'g'/'a' no quadril esquerdo.
-- WARN: nivelada no peito, trilho TRIPLO com dois virotes 'gg' — ela
-- declara as duas linhas de tiro.
--------------------------------------------------------------------------------
local gear = {
    -- asas largas em V + corda 'B'
    [44] = '............................................kSk........kSk',
    [45] = '.............................................kSSk......kSSk',
    -- aljava do quadril esquerdo (virotes 'g'/'a' + estojo 'D') na
    -- mesma linha das asas e da coronha grossa 'kbbbk'
    [46] = '.....................g..g.................kSSk.B.kSSk',
    [47] = '.....................g..g..................kSSkBkSSk',
    [48] = '.....................a..a...................kSSSSSSk',
    [49] = '.....................a..a....................kbbbk',
    -- manga sai do robe e encontra a coronha (a arma não fica solta)
    [50] = '....................kDDDDk..............kvvvk.kbbbk',
    [51] = '....................kDDDDk...............kvvk.kbbbk',
    [52] = '....................kDDDDk................kvvkkbbbk',
    [53] = '....................kDDDDk....................kbbbk',
    [54] = '.....................kDDk.....................kbbbk',
    -- coronha grossa descendo ao quadril
    [55] = '.................................................kbbbk',
    [56] = '.................................................kbbbk',
    [57] = '.................................................kbbbk',
    -- mão na coronha
    [58] = '................................................kbbbk',
    [59] = '................................................kbbbk',
    [60] = '................................................kbbbk',
    [61] = '.................................................kbk',
    [62] = '.................................................kbk',
}

-- WARN: arbaleste nivelada à altura do peito — trilho triplo 'b',
-- virotes 'gg' nas linhas de cima e de baixo, mão no gatilho.
local gearWarn = {
    -- asa superior varre para cima-direita
    [30] = '.....................................................kSk',
    [31] = '..................................................BkSSk',
    [32] = '.................................................BkSSk',
    [33] = '................................................BkSSk',
    [34] = '...............................................BkSSk',
    -- virote da linha de cima
    [35] = '........................................gg....BkSSk',
    -- coronha nivelada: três fileiras de trilho
    [36] = '.........................kbbbbbbbbbbbbbbbbbbkBkSSk',
    [37] = '.........................kbbbbbbbbbbbbbbbbbbkBkSSk',
    [38] = '.........................kbbbbbbbbbbbbbbbbbbkBkSSk',
    -- virote da linha de baixo + raiz da asa inferior
    [39] = '........................................gg.....kSSk',
    -- mão no gatilho sob o trilho
    [40] = '...................................kbbk........B.kSSk',
    [41] = '....................................kbbk........BkSSk',
    [42] = '.................................................BkSSk',
    [43] = '..................................................BkSSk',
    [44] = '...................................................BkSk',
    -- aljava segue no quadril
    [50] = '....................kDDDDk',
    [51] = '....................kDDDDk',
    [52] = '....................kDDDDk',
    [53] = '....................kDDDDk',
    [54] = '.....................kDDk',
}

return {
    name = 'foe_veteran',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 4},
        S = {ramp = 'stone', step = 4, h = 6},
        h = {ramp = 'stone', step = 5, h = 7},
        D = {ramp = 'stone', step = 2, h = 5},
        b = {ramp = 'bone', step = 4, h = 6},
        B = {ramp = 'bone', step = 5, h = 5},
        v = {ramp = 'violet', step = 3, h = 4},
        u = {ramp = 'violet', step = 2, h = 3},
        V = {ramp = 'violet', step = 4, h = 5},
        m = {ramp = 'moss', step = 2, h = 4},
        r = {ramp = 'rust', step = 3, h = 5},
        g = {ramp = 'gold', step = 5, h = 6},
        a = {ramp = 'wood', step = 4, h = 5},
        -- olho de veterana: jade, não ouro
        e = {ramp = 'cloth', step = 5, h = 7, e = 'jade.5', ei = .45},
        E = {ramp = 'cloth', step = 6, h = 7, e = 'jade.6', ei = 1},
    },

    layers = {
        {name = 'cape', h = 4, albedo = {
            R(cape),
            R(shift(cape, 1, 30, 80)),       -- respira junto
            R(cape),
        }},
        {name = 'body', h = 4, albedo = {
            R(body), R(body), R(body),
        }},
        {name = 'robe', h = 5, albedo = {
            R(robe),
            R(shift(robe, 1, 30, 81)),       -- respira
            R(robe),
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 15, 32)),
            R(headWarn),
        }, emissive = {
            R {
                [23] = '..............................ee',
            },
            R {
                [24] = '..............................ee',
            },
            R {
                [25] = '..............................EE',
                -- os dois virotes acordam na mira
                [35] = '........................................gg',
                [39] = '........................................gg',
            },
        }},
        {name = 'gear', h = 5, albedo = {
            R(gear), R(gear), R(gearWarn),
        }},
    },
}
