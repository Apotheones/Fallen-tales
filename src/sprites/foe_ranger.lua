-- SENTINELA (foe_ranger) — eco atirador dos sepultados, 64x96, origem
-- nos pés. Build 'scout' das devotas legadas: talhe esguio, capuz baixo
-- de pano violeta sobre máscara de osso, peito de pedra à mostra pela
-- fenda frontal da túnica, besta de pedra e osso.
-- Idle: besta descansa na vertical no quadril direito, asas cruzando a
-- saia. WARN = levanta e mira: a coronha sobe à altura do peito
-- nivelada, asas abertas nas pontas, corda esticada, virote 'g' no
-- trilho — e o olho 'e'->'E' acende.
-- Frames: [1,2] idle (respiração), [3] warn (mira).
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
-- BODY: pernas finas de pedra sob a barra rasgada da túnica, pés de
-- osso em corte — a sentinel ficou tempo demais parada: pés viraram
-- pontas de pedra cravadas.
--------------------------------------------------------------------------------
local body = {
    [76] = '..........................kssk..kssk',
    [77] = '..........................kssk..kssk',
    [78] = '..........................kssk..kssk',
    [79] = '..........................kssk..kssk',
    [80] = '..........................kssk..kssk',
    [81] = '..........................kssk..kssk',
    [82] = '..........................kssk..kssk',
    [83] = '..........................kssk..kssk',
    [84] = '..........................kssk..kssk',
    [85] = '..........................kssk..kssk',
    [86] = '.........................ksssk..ksssk',
    [87] = '.........................ksssk..ksssk',
    [88] = '.........................ksssk..ksssk',
    [89] = '.........................kssbk..kbssk',
    [90] = '........................kssssk..kssssk',
    [91] = '........................kbbbsk..ksbbbk',
    [92] = '........................kbBbbk..kbbBbk',
    [93] = '........................kkkkkk..kkkkkk',
}

--------------------------------------------------------------------------------
-- ROBE: túnica violeta desbotada — capuz nos ombros, fenda frontal
-- mostrando o peito de pedra 'S'/'s', cinto de ferrugem 'r' com fivela
-- 'g', saia alargando até a barra rasgada em pontas 'v'/'u'.
--------------------------------------------------------------------------------
local robe = {
    -- ombros sob o capuz
    [27] = '..........................kvvvvvvvvk',
    [28] = '.........................kvvvvvvvvvvk',
    [29] = '........................kvvvvvvvvvvvvk',
    -- colarinho aberto: peito de pedra
    [30] = '........................kvvvkSSSSkvvvk',
    [31] = '.......................kvvvvkSSSSkvvvvk',
    [32] = '.......................kvvvvkSSSSkvvvvk',
    [33] = '.......................kvvvvkSSSSkvvvvk',
    [34] = '......................kvvvvvkSSSSkvvvvvk',
    [35] = '......................kvvvvkSSSSSSkvvvvk',
    [36] = '......................kvvvvkSSSSSSkvvvvk',
    [37] = '......................kvvvvkSSSSSSkvvvvk',
    [38] = '......................kvvvvkSSsSSSkvvvvk',
    [39] = '......................kvvvvkSSsSSSkvvvvk',
    [40] = '......................kvvvvvkSSSSkvvvvvk',
    [41] = '......................kvvvvvkSSSSkvvvvvk',
    [42] = '......................kvvvvvvkSSkvvvvvvk',
    [43] = '......................kvvvvvvkSSkvvvvvvk',
    [44] = '......................kvvvvvvvkSkvvvvvvk',
    [45] = '......................kvvvvvvvkSkvvvvvvk',
    [46] = '......................kvvvvvvvkkvvvvvvvk',
    [47] = '......................kvvvvvvvvvvvvvvvvk',
    [48] = '......................kvvvvvvvvvvvvvvvvk',
    [49] = '......................kvvvvvvvvvvvvvvvvk',
    [50] = '......................kvvvvvvvvvvvvvvvvk',
    [51] = '.....................kvvvvvvvvvvvvvvvvvvk',
    [52] = '.....................kvvvvvvvvvvvvvvvvvvk',
    [53] = '.....................kvvvvvvvvvvvvvvvvvvk',
    [54] = '.....................kvvvvvvvvvvvvvvvvvvk',
    -- cinto de ferrugem + fivela de ouro velho
    [55] = '.....................krrrrrrrrrrrrrrrrrk',
    [56] = '.....................krrrrrrrrrggrrrrrrk',
    [57] = '.....................krrrrrrrrrggrrrrrrk',
    [58] = '.....................krrrrrrrrrrrrrrrrrk',
    -- saia da túnica: alarga e desce
    [59] = '.....................kvvvvvvvvvvvvvvvvvvk',
    [60] = '.....................kvvvvvvvvvvvvvvvvvvk',
    [61] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [62] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [63] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [64] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [65] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [66] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [67] = '....................kvVvvvvvvvvvvvvvvvvvVvk',
    [68] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [69] = '....................kvvvvvvvvvvvvvvvvvvvvk',
    [70] = '....................kuvvvvvvvvvvvvvvvvvvvuk',
    [71] = '....................kuvvvvvvvvvvvvvvvvvvvuk',
    [72] = '....................kuvvvvvvvvvvvvvvvvvvvuk',
    [73] = '....................kuvvvvvvvvvvvvvvvvvvvuk',
    [74] = '....................kuvvvvvvvvuvvvvvvvvvvuk',
    -- barra rasgada: pontas irregulares de pano
    [75] = '....................kuvvuvvvvkuvvvvuvvvuk',
    [76] = '....................kuvv.uvvvk.uvvv.uvvuk',
    [77] = '....................kvvv..vvvk..vvv..vvuk',
    [78] = '....................kvvv..vvk...vvv..vvk',
    [79] = '....................kuvv..vvk...vvv..vuk',
    [80] = '....................kvv...vvk....vv..vvk',
    [81] = '....................kuk...vk.....vv..vuk',
    [82] = '....................kk....kk.....vk...kk',
    [83] = '...........................k......v',
    [84] = '..................................k',
}

--------------------------------------------------------------------------------
-- HEAD: capuz baixo tombado para a frente; abertura com máscara de osso
-- 'b'/'B', olho 'e' em fenda (emissivo no canal), queixo recolhido.
--------------------------------------------------------------------------------
local head = {
    [11] = '............................kkkkkk',
    [12] = '...........................kuuuuuuk',
    [13] = '..........................kuvvvvvvvk',
    [14] = '.........................kuvvvvvvvvvk',
    [15] = '.........................kuvvvvvvvvvk',
    [16] = '........................kuvvvvvvvvvvvk',
    [17] = '........................kuvvvvvvvvvvvk',
    [18] = '........................kuvvkkkkkkkvvk',
    [19] = '........................kuvkbbbbbbbbkvk',
    [20] = '........................kuvkbbbbbbbbkvk',
    -- fenda do olho: 'e' apagado (dois pontos na máscara de osso)
    [21] = '........................kuvkbeebbeebkvk',
    [22] = '........................kuvkbbbbbbbbkvk',
    [23] = '.........................kvkbbbbbbkvk',
    [24] = '.........................kvkkbbbbkkvk',
    [25] = '.........................kvvvkbbkvvvk',
    [26] = '..........................kvvvkkvvvk',
    [27] = '..........................kvvvvvvvvk',
    [28] = '...........................kvvvvvvk',
    [29] = '...........................kvvvvvvk',
    [30] = '............................kuvvvuk',
    [31] = '............................kuvvvuk',
    -- pontas do capuz nas costas dos ombros
    [32] = '.............................kuuk',
    [33] = '.............................kvvk',
    [34] = '.............................kvk',
}

local headWarn = {
    -- capuz mergulha: a máscara some na sombra da aba e só o olho lê
    [13] = '............................kkkkkk',
    [14] = '...........................kuuuuuuk',
    [15] = '..........................kuvvvvvvvk',
    [16] = '.........................kuvvvvvvvvvk',
    [17] = '.........................kuvvvvvvvvvk',
    [18] = '........................kuvvvvvvvvvvvk',
    [19] = '........................kuvvvvvvvvvvvk',
    [20] = '........................kuvvkkkkkkkvvk',
    [21] = '........................kuvkbbbbbbbbkvk',
    [22] = '........................kuvkbbbbbbbbkvk',
    -- fenda escancarada 'E' sob a sombra da aba
    [23] = '........................kuvkbEEbbEEbkvk',
    [24] = '........................kuvkbbbbbbbbkvk',
    [25] = '.........................kvkbbbbbbkvk',
    [26] = '.........................kvkkbbbbkkvk',
    [27] = '.........................kvvvkbbkvvvk',
    [28] = '..........................kvvvkkvvvk',
    [29] = '..........................kvvvvvvvvk',
    [30] = '...........................kvvvvvvk',
    [31] = '...........................kvvvvvvk',
    [32] = '............................kuvvvuk',
    [33] = '............................kuvvvuk',
    [34] = '.............................kuuk',
    [35] = '.............................kvvk',
    [36] = '.............................kvk',
}

--------------------------------------------------------------------------------
-- GEAR: besta de pedra e osso.
-- IDLE: no quadril direito — coronha 'b' na vertical, arco em asa 'S'
-- cruzando a saia, corda 'B' (n tem 'B' osso claro), estojo de virotes
-- 'a' (haste) + 'g' (ponta) no quadril esquerdo.
-- WARN: coronha nivelada no peito mirando à direita, asas abertas na
-- ponta, corda esticada, virote 'g' no trilho. Mão 'b' no gatilho.
--------------------------------------------------------------------------------
local gear = {
    -- aljava de quadril esquerdo: virotes 'g'/'a' despontando, estojo 'D'
    [44] = '................g.g',
    [45] = '................g.g',
    [46] = '................a.a',
    [47] = '................a.a',
    [48] = '................a.a',
    [49] = '...............kDDDk',
    [50] = '...............kDDDk',
    [51] = '...............kDDDk',
    -- besta no quadril direito: asas 'S' em V cruzando a saia, corda 'B'
    -- das pontas ao corno, coronha 'b' na vertical com mão no cabo
    [52] = '...............kDDDk.............kSk................kSk',
    [53] = '................kDDk..............kSSk.............kSSk',
    [54] = '................kDDk...............kSSk.B........BkSSk',
    [55] = '....................................kSSkB.......BkSSk',
    [56] = '.....................................kSSkB.....BkSSk',
    [57] = '......................................kSSkB..BkSSk',
    [58] = '.......................................kSSSSSSSSk',
    [59] = '..........................................kbk',
    [60] = '..........................................kbk',
    [61] = '..........................................kbk',
    [62] = '..........................................kbk',
    [63] = '..........................................kbk',
    [64] = '..........................................kbk',
    [65] = '.........................................kbbk',
    [66] = '.........................................kbbk',
    [67] = '.........................................kbbk',
    [68] = '.........................................kbbk',
    [69] = '......................................kbbbk',
    [70] = '......................................kbbbbk',
    [71] = '......................................kbbbk',
    [72] = '.........................................kbbk',
    [73] = '.........................................kbbk',
    [74] = '..........................................kbk',
    [75] = '..........................................kbk',
}

-- WARN: arma nivelada — coronha horizontal no peito mirando à direita,
-- asas verticais na ponta, corda 'B' esticada ao nock, virote 'gg' no
-- trilho, mão no gatilho e mão firmando a ponta. Aljava segue.
local gearWarn = {
    -- asa superior varre para cima-direita, corda por dentro do V
    [32] = '......................................................kSk',
    [33] = '...................................................BkSSk',
    [34] = '..................................................BkSSk',
    [35] = '.................................................BkSSk',
    [36] = '................................................BkSSk',
    [37] = '...........................................gg...BkSSk',
    -- coronha 'b' nivelada no peito (2 fileiras)
    [38] = '..........................kbbbbbbbbbbbbbbbbbbkBkSSk',
    [39] = '..........................kbbbbbbbbbbbbbbbbbbkBkSSk',
    -- asa inferior varre para baixo-direita, corda por dentro
    [40] = '..............................................B.kSSk',
    [41] = '...............................kbb..............BkSSk',
    [42] = '..........................................kbbk..BkSSk',
    [43] = '...........................................kbbk..BkSSk',
    [44] = '....................................................BkSSk',
    [45] = '.....................................................BkSk',
    -- aljava segue no quadril
    [52] = '...............kDDDk',
    [53] = '................kDDk',
    [54] = '................kDDk',
}

return {
    name = 'foe_ranger',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 4},
        S = {ramp = 'stone', step = 4, h = 6},
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
        e = {ramp = 'gold', step = 5, h = 7, e = 'gold.6', ei = .45},
        E = {ramp = 'gold', step = 6, h = 7, e = 'gold.7', ei = 1},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body), R(body), R(body),
        }},
        {name = 'robe', h = 5, albedo = {
            R(robe),
            R(shift(robe, 1, 27, 58)),       -- respira: torso desce 1px
            R(robe),
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 11, 34)),
            R(headWarn),
        }, emissive = {
            R {
                [21] = '.............................ee..ee',
            },
            R {
                [22] = '.............................ee..ee',
            },
            R {
                [23] = '.............................EE..EE',
                -- virote no trilho cintila na mira
                [37] = '............................................gg',
            },
        }},
        {name = 'gear', h = 5, albedo = {
            R(gear), R(gear), R(gearWarn),
        }},
    },
}
