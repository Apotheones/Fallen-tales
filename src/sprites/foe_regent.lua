-- A REGENTE DE ÂMBAR (foe_regent) — a convocadora-mor dos sepultados,
-- 64x96, origem nos pés. Build 'regal': coroa de ouro velho em três
-- pontas sobre máscara de osso, gola alta de trono-ambulante em 'v'
-- com pontas 'g' ladeando a cabeça, manto de gala — ombros largos com
-- galão 'g', peitoril de pedra emoldurado, saia-sino com barra de ouro.
-- Fragmentos de âmbar 'a' orbitam a parte alta do corpo.
-- Frames: [1,2] idle (respiração + deriva dos fragmentos), [3] WARN =
-- convocação: as palmas sobem abertas, a órbita se alarga e os âmbares
-- acendem 'A' — o ritual que coloca ecos nascentes na arena.
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
-- BODY: pés pequenos sob a saia — quase escondidos, ela se move como um
-- trono que anda.
--------------------------------------------------------------------------------
local body = {
    [85] = '...........................kssk....kssk',
    [86] = '...........................kssk....kssk',
    [87] = '..........................ksssk....ksssk',
    [88] = '..........................ksssk....ksssk',
    [89] = '.........................kssssk....kssssk',
    [90] = '.........................ksssssk..ksssssk',
    [91] = '.........................ksbsssk..ksbsssk',
    [92] = '.........................kkkkkkk..kkkkkkk',
}

--------------------------------------------------------------------------------
-- COLLAR: gola-trono alta — duas asas de pano 'v' com pontas 'g'
-- subindo ao lado da cabeça. Fica atrás da coroa e à frente do manto.
--------------------------------------------------------------------------------
local collar = {
    [18] = '.........................kgk..........kgk',
    [19] = '.........................kvgk........kgvk',
    [20] = '........................kvvvgk......kgvvvk',
    [21] = '........................kvvvvk......kvvvvk',
    [22] = '........................kvvvvk......kvvvvk',
    [23] = '........................kvvvvvk....kvvvvvk',
    [24] = '........................kvvvvvvk..kvvvvvvk',
    [25] = '........................kvvvvvvkkvvvvvvvk',
    [26] = '........................kvvvvvvvvvvvvvvvk',
    [27] = '........................kvvvvvvvvvvvvvvvk',
    [28] = '.........................kvvvvvvvvvvvvvk',
    [29] = '.........................kvvvvvvvvvvvvvk',
    [30] = '.........................kvvvvvvvvvvvvk',
    [31] = '.........................kuvvvvvvvvvvvk',
    [32] = '..........................kuvvvvvvvvvk',
    [33] = '..........................kuvvvvvvvk',
}

--------------------------------------------------------------------------------
-- HEAD: coroa 'g' de três pontas sobre máscara de osso 'b' — olhos 'e'
-- danger (ela é a que dá as últimas ordens).
--------------------------------------------------------------------------------
local head = {
    -- pontas da coroa
    [15] = '..............................g...g...g',
    [16] = '.............................kgk.kgk.kgk',
    [17] = '.............................kgk.kgk.kgk',
    -- banda da coroa
    [18] = '.............................kgggggggggk',
    -- máscara de osso
    [19] = '.............................kbbbbbbbbbk',
    [20] = '.............................kbbbbbbbbbk',
    -- olhos 'e' apagados
    [21] = '.............................kbeebbeebk',
    [22] = '.............................kbbbbbbbbbk',
    [23] = '.............................kbbbbbbbbbk',
    [24] = '..............................kbbbbbbbk',
    [25] = '..............................kbbkbkbbk',
    [26] = '...............................kbbbbbk',
    [27] = '...............................kkkkkkk',
}

local headWarn = {
    -- coroa ergue inteira, olhos 'E'
    [15] = '..............................g...g...g',
    [16] = '.............................kgk.kgk.kgk',
    [17] = '.............................kgk.kgk.kgk',
    [18] = '.............................kgggggggggk',
    [19] = '.............................kbbbbbbbbbk',
    [20] = '.............................kbbbbbbbbbk',
    [21] = '.............................kbEEbbEEbk',
    [22] = '.............................kbbbbbbbbbk',
    [23] = '.............................kbbbbbbbbbk',
    [24] = '..............................kbbbbbbbk',
    [25] = '..............................kbbkbkbbk',
    [26] = '...............................kbbbbbk',
    [27] = '...............................kkkkkkk',
}

--------------------------------------------------------------------------------
-- ROBE: manto de gala — ombros largos com galão 'g' nas bordas, peitoril
-- de pedra 'S' emoldurado em ouro, saia-sino descendo até a barra de
-- ouro 'g' e a orla vazada.
--------------------------------------------------------------------------------
local robe = {
    [34] = '........................kkkkkkkkkkkkkkkk',
    [35] = '.......................kvvvvvvvvvvvvvvvvk',
    [36] = '......................kvvvvvvvvvvvvvvvvvvk',
    -- galões de ouro nos ombros
    [37] = '......................kvggvvvvvvvvvvvggvk',
    [38] = '......................kvgvvvvvvvvvvvvvgvk',
    -- peitoril de pedra emoldurado
    [39] = '......................kvvvggggggggggggvvvk',
    [40] = '......................kvvvgSSSSSSSSSSgvvvk',
    [41] = '.......................kvvgSSSSSSSSSSgvvk',
    [42] = '.......................kvvgSShSSSShSSgvvk',
    [43] = '.......................kvvgSSSSSSSSSSgvvk',
    [44] = '.......................kvvgSSSSSSSSSSgvvk',
    [45] = '.......................kvvggSSSSSSSSggvvk',
    [46] = '.......................kvvvgSSSSSSSSgvvvk',
    [47] = '.......................kvvvvgSSSSSSgvvvvk',
    [48] = '.......................kvvvvggSSSSggvvvvk',
    [49] = '.......................kvvvvvgSSSSgvvvvvk',
    [50] = '.......................kvvvvvvggggvvvvvvk',
    -- corpo da saia
    [51] = '.......................kvvvvvvvvvvvvvvvvk',
    [52] = '.......................kvvvvvvvvvvvvvvvvk',
    [53] = '.......................kvvvvvvvvvvvvvvvvk',
    [54] = '.......................kvvvvvvvvvvvvvvvvk',
    [55] = '.......................kvvvvvvvvvvvvvvvvk',
    [56] = '.......................kvvvvvvvvvvvvvvvvk',
    [57] = '.......................kvvvvvvvvvvvvvvvvk',
    [58] = '.......................kvvvvvvvvvvvvvvvvk',
    -- faixa de ouro na altura do joelho
    [59] = '.......................kgggggggggggggggggk',
    [60] = '.......................kvvvvvvvvvvvvvvvvk',
    [61] = '.......................kvvvvvvvvvvvvvvvvk',
    [62] = '......................kvvvvvvvvvvvvvvvvvvk',
    [63] = '......................kvvvvvvvvvvvvvvvvvvk',
    [64] = '......................kvvvvvvvvvvvvvvvvvvk',
    [65] = '......................kuvvvvvvvvvvvvvvvvuk',
    [66] = '......................kuvvvvvvvvvvvvvvvvuk',
    [67] = '.....................kuvvvvvvvvvvvvvvvvvvuk',
    [68] = '.....................kuvvvvvvvvvvvvvvvvvvuk',
    [69] = '.....................kuvvvvvvvvvvvvvvvvvvuk',
    [70] = '.....................kuvvvvvvvvvvvvvvvvvvuk',
    [71] = '.....................kuvvvvuvvvvvvvvuvvvvuk',
    [72] = '.....................kuvvvvuvvvvvvvvuvvvvuk',
    [73] = '.....................kuvvvvvvvvvvvvvvvvvvuk',
    -- barra de ouro cerimonial
    [74] = '.....................kggggggggggggggggggggk',
    [75] = '.....................kuvvvvvvvvvvvvvvvvvvuk',
    [76] = '.....................kuvvvvvvvvvvvvvvvvvvuk',
    [77] = '.....................kuvvvvuvvvvvvvvuvvvvuk',
    -- orla vazada
    [78] = '.....................kuvvuvvvuvvvvvuvvuvvuk',
    [79] = '.....................kuvvv.uvvvvvvv.uvvvvuk',
    [80] = '.....................kuvv.vv.uvvvv.vv.vvuk',
    [81] = '.....................kvv..vv..vvv..vv..vvk',
    [82] = '.....................kvv..vv...v...vv..vvk',
    [83] = '.....................kv...v....v....v...vk',
    [84] = '.....................kk...k....k....k...kk',
}

--------------------------------------------------------------------------------
-- ARMS: mangas de gala pendendo com punho 'g'. WARN: palmas sobem
-- abertas para a convocação — a mesma língua dos braços do sower.
--------------------------------------------------------------------------------
local arms = {
    [38] = '....................kvvk..................kvvk',
    [39] = '....................kvvk..................kvvk',
    [40] = '....................kvvk..................kvvk',
    [41] = '....................kvvk..................kvvk',
    [42] = '....................kvvk..................kvvk',
    [43] = '....................kvvk..................kvvk',
    [44] = '....................kvvk..................kvvk',
    [45] = '....................kvvk..................kvvk',
    [46] = '....................kvvk..................kvvk',
    [47] = '....................kvvk..................kvvk',
    [48] = '....................kvvk..................kvvk',
    [49] = '....................kvvk..................kvvk',
    [50] = '....................kvvk..................kvvk',
    [51] = '....................kvvk..................kvvk',
    [52] = '....................kvvk..................kvvk',
    [53] = '....................kvvk..................kvvk',
    [54] = '....................kvvk..................kvvk',
    [55] = '....................kgk....................kgk',
    [56] = '....................kgk....................kgk',
    [57] = '.....................kk....................kk',
}

local armsWarn = {
    -- palmas abertas para cima à altura dos ombros, dedos separados
    [36] = '...............kbbbkb....................kbbbkb',
    [37] = '...............kb.b.bk..................kb.b.bk',
    [38] = '...............kbbbbbk..................kbbbbbk',
    [39] = '................kkkkk....................kkkkk',
    -- mangas descendo até o manto
    [40] = '................kvvk......................kvvk',
    [41] = '.................kvvk....................kvvk',
    [42] = '.................kvvk....................kvvk',
    [43] = '..................kvvk..................kvvk',
    [44] = '..................kvvk..................kvvk',
    [45] = '...................kvvk................kvvk',
    [46] = '....................kk..................kk',
}

--------------------------------------------------------------------------------
-- SHARDS: fragmentos de âmbar 'a' em órbita — anel ao redor da coroa e
-- dos ombros. WARN: a órbita alarga, os fragmentos viram 'A' e dois
-- descem à frente — o eco sendo colocado.
--------------------------------------------------------------------------------
local shards = {
    [12] = '................................kak',
    [18] = '.................kak.........................kak',
    [26] = '............kak....................................kak',
    [34] = '..............kak.................................kak',
    [42] = '..................kak.....................kak',
}

local shardsWarn = {
    [8]  = '................................kAk',
    [14] = '..................kAk.........................kAk',
    [22] = '...........kAk.....................................kAk',
    [30] = '.........kAk...........................................kAk',
    [38] = '...............kAk...............................kAk',
    -- dois fragmentos descem à frente das palmas: a semente do eco
    [46] = '..........................kAk.......kAk',
    [50] = '...........................kAk.....kAk',
}

return {
    name = 'foe_regent',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 4},
        S = {ramp = 'stone', step = 4, h = 6},
        h = {ramp = 'stone', step = 5, h = 7},
        b = {ramp = 'bone', step = 4, h = 5},
        v = {ramp = 'violet', step = 3, h = 4},
        u = {ramp = 'violet', step = 2, h = 3},
        V = {ramp = 'violet', step = 4, h = 5},
        r = {ramp = 'rust', step = 3, h = 5},
        g = {ramp = 'gold', step = 5, h = 6},
        G = {ramp = 'gold', step = 6, h = 7},
        a = {ramp = 'gold', step = 5, h = 8, e = 'ember.5', ei = .45},
        A = {ramp = 'gold', step = 6, h = 9, e = 'ember.6', ei = 1},
        e = {spec = 'danger', h = 7, e = 'danger', ei = .45},
        E = {spec = 'danger', h = 7, e = 'danger', ei = 1},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body), R(body), R(body),
        }},
        {name = 'collar', h = 4, albedo = {
            R(collar),
            R(shift(collar, 1, 18, 33)),
            R(shift(collar, -1, 18, 33)),    -- a gola se arqueia no chamado
        }},
        {name = 'robe', h = 5, albedo = {
            R(robe),
            R(shift(robe, 1, 34, 78)),
            R(robe),
        }},
        {name = 'arms', h = 6, albedo = {
            R(arms), R(arms), R(armsWarn),
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 15, 27)),
            R(headWarn),
        }, emissive = {
            R {
                [21] = '...............................ee..ee',
            },
            R {
                [22] = '...............................ee..ee',
            },
            R {
                [21] = '...............................EE..EE',
            },
        }},
        {name = 'shards', h = 8, albedo = {
            R(shards),
            R(shift(shards, 1, 8, 42)),      -- deriva da órbita
            R(shardsWarn),
        }, emissive = {
            R {
                [12] = '.................................a',
                [18] = '..................a...........................a',
                [26] = '.............a......................................a',
                [34] = '...............a...................................a',
                [42] = '...................a.......................a',
            },
            R {
                [13] = '.................................a',
                [19] = '..................a...........................a',
                [27] = '.............a......................................a',
                [35] = '...............a...................................a',
                [43] = '...................a.......................a',
            },
            R {
                [8]  = '.................................A',
                [14] = '...................A...........................A',
                [22] = '............A.......................................A',
                [30] = '..........A.............................................A',
                [38] = '................A.................................A',
                [46] = '...........................A.........A',
                [50] = '............................A.......A',
            },
        }},
    },
}
