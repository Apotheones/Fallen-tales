-- SEMEADOR DE ÂMBAR (foe_sower) — eco conjurador dos sepultados, 64x96,
-- origem nos pés. Postura ritual: robe-barril de pano violeta desbotado
-- com bordas de ouro velho, peito de pedra à mostra, capuz funil sobre
-- máscara de osso. As palmas 'b' ficam abertas para cima sustentando
-- fragmentos de âmbar 'a'/'A' suspensos — brilho baixo de brasa no idle
-- (ei ~.4), os fragmentos SOBEM e ACENDEM no warn (ei .9).
-- Frames: [1,2] idle (respiração), [3] WARN = convocação.
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
-- BODY: pernas curtas de pedra sob a barra, pés de bloco.
--------------------------------------------------------------------------------
local body = {
    [76] = '...........................kssk..kssk',
    [77] = '...........................kssk..kssk',
    [78] = '...........................kssk..kssk',
    [79] = '...........................kssk..kssk',
    [80] = '...........................kssk..kssk',
    [81] = '..........................ksssk..ksssk',
    [82] = '..........................ksssk..ksssk',
    [83] = '..........................ksssk..ksssk',
    [84] = '..........................ksssk..ksssk',
    [85] = '..........................ksssk..ksssk',
    [86] = '..........................ksssk..ksssk',
    [87] = '.........................kssssk..kssssk',
    [88] = '.........................kssssk..kssssk',
    [89] = '.........................kssssk..kssssk',
    [90] = '........................kssssssk.kssssssk',
    [91] = '........................kssssssk.kssssssk',
    [92] = '........................kkkkkkkk.kkkkkkkk',
}

--------------------------------------------------------------------------------
-- ROBE: barril de pano — ombros redondos, fenda frontal com peito de
-- pedra 'S' e filete de ouro 'g', bordas da manga e barra com galão
-- 'g'/'G', pano 'v'/'u', pontas rasgadas na barra.
--------------------------------------------------------------------------------
local robe = {
    -- ombros redondos do barril
    [30] = '........................kkkkkkkkkkkkkkkk',
    [31] = '......................kvvvvvvvvvvvvvvvvvvk',
    [32] = '.....................kvvvvvvvvvvvvvvvvvvvk',
    [33] = '....................kvvvvvvvvvvvvvvvvvvvvvk',
    [34] = '....................kvvvvvvvvvvvvvvvvvvvvvk',
    -- fenda frontal: peito de pedra + filetes de ouro
    [35] = '...................kvvvvvvgkSSSSgkvvvvvvvk',
    [36] = '...................kvvvvvvgkSSSSgkvvvvvvvk',
    [37] = '...................kvvvvvgkSSSSSSgvvvvvvvk',
    [38] = '...................kvvvvvgkSSSSSSgvvvvvvvk',
    [39] = '...................kvvvvvgkSSSSSSgvvvvvvvk',
    [40] = '...................kvvvvvgkSSsSSSgvvvvvvvk',
    [41] = '...................kvvvvvgkSSsSSSgvvvvvvvk',
    [42] = '...................kvvvvvgkSSSSSSgvvvvvvvk',
    [43] = '...................kvvvvvgkSSSSSSgvvvvvvvk',
    [44] = '...................kvvvvvvgkSSSSgvvvvvvvvk',
    [45] = '...................kvvvvvvgkSSSSgvvvvvvvvk',
    [46] = '...................kvvvvvvvgkSSgvvvvvvvvvk',
    [47] = '...................kvvvvvvvgkSSgvvvvvvvvvk',
    [48] = '...................kvvvvvvvvgkkvvvvvvvvvvk',
    -- barril continua
    [49] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [50] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [51] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [52] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [53] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [54] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [55] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [56] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [57] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [58] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    -- galão de ouro na altura do joelho
    [59] = '...................kgggggggggggggggggggggk',
    [60] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [61] = '...................kvvvvvvvvvvvvvvvvvvvvvk',
    [62] = '..................kvvvvvvvvvvvvvvvvvvvvvvvk',
    [63] = '..................kvvvvvvvvvvvvvvvvvvvvvvvk',
    [64] = '..................kvvvvvvvvvvvvvvvvvvvvvvvk',
    [65] = '..................kuvvvvvvvvvvvvvvvvvvvvvuk',
    [66] = '..................kuvvvvvvvvvvvvvvvvvvvvvuk',
    [67] = '..................kuvvvvvvvvvvvvvvvvvvvvvuk',
    [68] = '..................kuvvvvvvvvvvvvvvvvvvvvvuk',
    [69] = '..................kuvvvvvvvvvvvvvvvvvvvvvuk',
    [70] = '..................kuvvvvvvuvvvvvvvvuvvvvvuk',
    [71] = '..................kuvvvvvvuvvvvvvvvuvvvvvuk',
    [72] = '..................kuvvvvvuvvvvvvvvvuvvvvvuk',
    -- barra rasgada
    [73] = '..................kuvvuvvuvvvkvvvuvvuvvuk',
    [74] = '..................kuvv.vvuvvvkvvvuvv.vvuk',
    [75] = '..................kuvv.vv.uvvkvvv.uv.vvuk',
    [76] = '..................kvv..vv.uvvkvvv.uv..vvk',
    [77] = '..................kuv..vv..vvkvv..vv..vuk',
    [78] = '..................kvv..vv..vv.vv..vv..vvk',
    [79] = '..................kuk..vv...v..v...vv..vuk',
    [80] = '..................kv...vv...v..v...vv...vk',
    [81] = '..................ku...vv.......v...vv...uk',
    [82] = '..................kk...kk.......kk...kk...kk',
}

--------------------------------------------------------------------------------
-- ARMS: mangas largas saindo do barril, antebraços de osso, palmas
-- ABERTAS para cima sustentando os fragmentos (camada acima do robe).
--------------------------------------------------------------------------------
local arms = {
    -- mangas largas saem da lateral do barril e descem para as palmas;
    -- antebraço 'b' + palma aberta para cima com dedos separados
    [39] = '................kvvvk......................kvvvk',
    [40] = '...............kvvvk........................kvvvk',
    [41] = '..............kvvvk..........................kvvvk',
    [42] = '.............kvvvk............................kvvvk',
    [43] = '............kvvk................................kvvk',
    [44] = '...........kvvk..................................kvvk',
    [45] = '..........kvvk....................................kvvk',
    [46] = '.........kvuk......................................kuvk',
    [47] = '.........kvk........................................kvk',
    [48] = '.........kbbk......................................kbbk',
    [49] = '.........kbbk......................................kbbk',
    -- palmas abertas para cima: dedos 'b' separados
    [50] = '........kbbbkb....................................kbbbkb',
    [51] = '........kb.b.bk..................................kb.b.bk',
    [52] = '........kbbbbbk..................................kbbbbbk',
    [53] = '........kkkkkk....................................kkkkkk',
}

-- WARN: braços erguidos — mangas sobem em diagonal, palmas abertas à
-- altura do peito, dedos escancarados.
local armsWarn = {
    [30] = '.................kkk........................kkk',
    [31] = '...............kvvvk........................kvvvk',
    [32] = '.............kvvvk............................kvvvk',
    [33] = '...........kvvvk................................kvvvk',
    [34] = '..........kvvvk..................................kvvvk',
    [35] = '.........kvvk......................................kvvk',
    [36] = '........kvvk........................................kvvk',
    [37] = '.......kvuk..........................................kuvk',
    [38] = '.......kvk............................................kvk',
    [39] = '.......kbbk..........................................kbbk',
    -- palmas abertas altas (dedos separados)
    [40] = '......kbbbkb........................................kbbbkb',
    [41] = '......kb.b.bk......................................kb.b.bk',
    [42] = '......kbbbbbk......................................kbbbbbk',
    [43] = '......kkkkkk........................................kkkkkk',
}

--------------------------------------------------------------------------------
-- HEAD: capuz-funil alto sobre máscara de osso; olhos 'e' em fenda
-- horizontal dupla (ember apagado).
--------------------------------------------------------------------------------
local head = {
    [12] = '.............................kkkk',
    [13] = '............................kuuuuk',
    [14] = '...........................kuvvvvvk',
    [15] = '..........................kuvvvvvvvk',
    [16] = '..........................kuvvvvvvvk',
    [17] = '.........................kuvvvvvvvvvk',
    [18] = '.........................kuvvvvvvvvvk',
    [19] = '.........................kuvvkkkkvvvk',
    [20] = '.........................kuvkbbbbkvuk',
    [21] = '.........................kuvkbbbbkvuk',
    [22] = '.........................kuvkbebebvuk',
    [23] = '.........................kuvkbebebvuk',
    [24] = '.........................kuvkbbbbkvuk',
    [25] = '.........................kuvvkbbkvuk',
    [26] = '.........................kvvvvkkvvvk',
    [27] = '..........................kvvvvvvvk',
    [28] = '..........................kvvvvvvvk',
    [29] = '...........................kvvvvvk',
}

--------------------------------------------------------------------------------
-- SHARDS: fragmentos de âmbar suspensos acima das palmas e um maior no
-- peito. Albedo 'a' (gold.5); emissivo no canal próprio (ei .4).
--------------------------------------------------------------------------------
local shards = {
    -- pares de fragmentos sobre as palmas abertas (esq. cols 10-14,
    -- dir. cols 50-55) + um fragmento maior sobre o peito
    [33] = '..........kak',
    [34] = '..................................................kak',
    [35] = '...........kak...................................kak',
    [36] = '...........kak',
    [37] = '.................................................kak',
    [38] = '.........kak........................................kak',
    -- fragmento central sobre o peito
    [41] = '...............................kaak',
    [42] = '...............................kaak',
    [43] = '................................kak',
}

local shardsWarn = {
    -- os fragmentos SOBEM: nuvem acima da cabeça e das palmas erguidas
    [20] = '..................kak.............kak',
    [22] = '...............kak...................kak',
    [24] = '.................kak...............kak',
    [26] = '....................kak.........kak',
    [28] = '.......................kaaaaak',
    [29] = '......................kAAAAAAAk',
    [30] = '.......................kaaaaak',
    -- pó de âmbar caindo sobre as palmas
    [34] = '......kak..............................................kak',
    [36] = '........kak..........................................kak',
}

return {
    name = 'foe_sower',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 4},
        S = {ramp = 'stone', step = 4, h = 6},
        b = {ramp = 'bone', step = 4, h = 6},
        v = {ramp = 'violet', step = 3, h = 4},
        u = {ramp = 'violet', step = 2, h = 3},
        g = {ramp = 'gold', step = 4, h = 6},
        a = {ramp = 'gold', step = 5, h = 8, e = 'ember.5', ei = .4},
        A = {ramp = 'gold', step = 6, h = 9, e = 'ember.6', ei = .9},
        e = {ramp = 'ember', step = 4, h = 7, e = 'ember.5', ei = .45},
        E = {ramp = 'ember', step = 5, h = 7, e = 'ember.6', ei = 1},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body), R(body), R(body),
        }},
        {name = 'robe', h = 5, albedo = {
            R(robe),
            R(shift(robe, 1, 30, 60)),       -- respira
            R(robe),
        }},
        {name = 'arms', h = 6, albedo = {
            R(arms), R(arms), R(armsWarn),
        }},
        {name = 'shards', h = 8, albedo = {
            R(shards),
            R(shift(shards, -1, 33, 43)),    -- deriva lenta dos fragmentos
            R(shardsWarn),
        }, emissive = {
            R {
                [33] = '...........a',
                [34] = '...................................................a',
                [35] = '............a...................................a',
                [36] = '............a',
                [37] = '..................................................a',
                [38] = '..........a........................................a',
                [41] = '................................aa',
                [42] = '................................aa',
                [43] = '.................................a',
            },
            R {
                [32] = '...........a',
                [33] = '...................................................a',
                [34] = '............a...................................a',
                [35] = '............a',
                [36] = '..................................................a',
                [37] = '..........a........................................a',
                [40] = '................................aa',
                [41] = '................................aa',
                [42] = '.................................a',
            },
            R {
                [20] = '...................A..........................A',
                [22] = '................A..............................A',
                [24] = '..................A..........................A',
                [26] = '.....................A...................A',
                [28] = '........................AAAAA',
                [29] = '.......................AAAAAAA',
                [30] = '........................AAAAA',
                [34] = '.......A...............................................A',
                [36] = '.........A...........................................A',
            },
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 12, 29)),
            R(head),
        }, emissive = {
            R {
                [22] = '..............................e.e',
                [23] = '..............................e.e',
            },
            R {
                [23] = '..............................e.e',
                [24] = '..............................e.e',
            },
            R {
                [22] = '..............................E.E',
                [23] = '..............................E.E',
            },
        }},
    },
}
