-- VARAL — prop de chão, 64x96, origem nos pés. 2 frames = arranjos por
-- seed (não é animação: cada arranjo é um estado/variação estável).
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, "roupa = gente"):
-- dois mourões de madeira com corda de fibra em catenária e peças
-- penduradas por pregos/prendedores — tamanhos e tensões diferentes:
-- a camisa jade larga, o pano quente dobrado, o lençol de reboco pesado
-- puxando a corda mais para baixo.
-- Relevo: corda/postes 7-8, roupas 6-7, chão 1-2.

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

-- mourões + corda em catenária (afunda ~9px no centro) + chão
local corda = {

    -- mourão esquerdo (cols 10-13) e direito (cols 50-53), topos com
    -- volta da corda 'R'
    [34] = '.........kWWk....................................kWWk',
    [35] = '.........kwwk....................................kwwk',
    [36] = '.........kRrk....................................krRk',
    [37] = '.........krRk....................................kRrk',
    [38] = '.........kwwkrr...............................rrkwwk',
    [39] = '.........kwwk..r.............................r.kwwk',
    [40] = '.........kwwk...r..........................rr..kwwk',
    [41] = '.........kwwk....rr........................r...kwwk',
    [42] = '.........kwvk......rr.....................rr...kwvk',
    [43] = '.........kwwk........rr..................rr....kwwk',
    [44] = '.........kwwk..........rr...............r......kwwk',
    [45] = '.........kwwk...........rrr...........rr.......kwwk',
    [46] = '.........kwwk..............rrrr...rrrr.........kwwk',
    [47] = '.........kwwk....................rrr...........kwwk',
    [48] = '.........kwwk....................................kwwk',
    [49] = '.........kwwk....................................kwwk',
    [50] = '.........kwvk....................................kwvk',
    [51] = '.........kwwk....................................kwwk',
    [52] = '.........kwwk....................................kwwk',
    [53] = '.........kwwk....................................kwwk',
    [54] = '.........kwvk....................................kwvk',
    [55] = '.........kwwk....................................kwwk',
    [56] = '.........kwwk....................................kwwk',
    [57] = '.........kwwk....................................kwwk',
    [58] = '.........kwvk....................................kwvk',
    [59] = '.........kwwk....................................kwwk',
    [60] = '.........kwwk....................................kwwk',
    [61] = '.........kwwk....................................kwwk',
    [62] = '.........kwvk....................................kwvk',
    [63] = '.........kwwk....................................kwwk',
    [64] = '.........kwwk....................................kwwk',
    [65] = '.........kwwk....................................kwwk',
    [66] = '.........kwvk....................................kwvk',
    [67] = '.........kwwk....................................kwwk',
    [68] = '.........kwwk....................................kwwk',
    [69] = '.........kwwk....................................kwwk',
    [70] = '.........kwvk....................................kwvk',
    [71] = '.........kwwk....................................kwwk',
    [72] = '.........kwwk....................................kwwk',
    [73] = '.........kwwk....................................kwwk',
    [74] = '.........kwvk....................................kwvk',
    [75] = '.........kwwk....................................kwwk',
    [76] = '.........kwwk....................................kwwk',
    [77] = '.........kwwk....................................kwwk',
    [78] = '.........kwvk....................................kwvk',
    [79] = '.........kwwk....................................kwwk',
    [80] = '.........kwwk....................................kwwk',
    [81] = '.........kwwk....................................kwwk',
    [82] = '.........kwvk....................................kwvk',
    [83] = '.........kwwk....................................kwwk',
    [84] = '.........kwwk....................................kwwk',
    [85] = '.........kwwk....................................kwwk',
    [86] = '.........kwwk....................................kwwk',
    [87] = '.........kwvk....................................kwvk',
    [88] = '.........kwwk....................................kwwk',
    -- base: terra e relva prendendo os mourões
    [89] = '........eeggk.......e.........e......e.......egge',
    [90] = '.......egegge..e.....e....e.....e......e..egegge',
    [91] = '......eegggge.e.....e...e.....e...e...e.ggggee',
    [92] = '......egGGge....e......e.....e....e...egGGge',
    [93] = '.......egge.....e....e.....e......e...egge',
    [94] = '........ee.......e.....e.....e........ee',
}

-- FRAME 1: camisa jade larga à esquerda, pano quente dobrado no meio,
-- pano pequeno de reboco à direita.
local roupas1 = {

    -- camisa jade sobre a corda (cols 18-28): pregos 'n' prendem no
    -- varal, mangas curtas caem dos lados
    [41] = '..................ncjjjjjjjjn',
    [42] = '................jccjjjjjjjjjjjc...........npppn',
    [43] = '................jccjjcjjjjcjjjc...........npppn',
    [44] = '................jc.jjcjjjjcjj.jnaaaaaaan..ppppp',
    [45] = '................jc.jjjjjjjjjjj.naaaaaaan..ppdpp',
    [46] = '.................c.jjjcjjjcjjj.aaaaaaaaa..ppppp',
    [47] = '.................c.jjjjjjjjjjj.aaaacaaaa..ppppp',
    [48] = '.................j.jjjjjjjcjjj.aaaaaaaaa..ppppp',
    [49] = '.................j.jjjcjjjjjjj.aaacaaaaa..ppdpp',
    [50] = '...................jjjjjjjjjjj.aaaaaaaaa..ppppp',
    [51] = '...................jjjcjjjjcjj.aaaaacaaa..ppppp',
    [52] = '...................jjjjjjjjjjj.aaaaaaaaa..ppppp',
    [53] = '...................jjjjcjjjjjj.aaacaaaa....ppp',
    [54] = '...................jjjjjjjjjjj.aaaaaaaaa...ppp',
    [55] = '...................jjjcjjjjcjj.aaccaaaaa',
    [56] = '...................jjjjjjjjjjj.aaaaaaa',
    [57] = '...................jjjjjjjjjjj.aaaaaa',
    [58] = '...................jjjjjjjjjjj',
    [59] = '...................jcjjjjjjcjj',
    [60] = '...................jjjjcjjjjj.j',
    [61] = '...................jjjjjjjjj',
    [62] = '....................jj.jj.jj',
}

-- FRAME 2: pano quente e camisa jade à esquerda, lençol de reboco
-- comprido à direita puxando a corda (barra mais baixa e irregular).
local roupas2 = {

    -- pano quente pequeno (cols 16-21)
    [40] = '...............naaaaan',
    [41] = '...............naaaaan',
    [42] = '...............aaaaaaa............nppppppppppp',
    [43] = '...............aaacaaa...njjjjn...npppppppppppp',
    [44] = '...............aaaaaaa...njjjjn...pppppppppppppp',
    [45] = '...............aacaaaa...jjjjjj...pppdpppppppdppp',
    [46] = '...............aaaaaaa...jjcjjj...ppppppppppppppp',
    [47] = '...............aaaacaa...jjjjjj...ppppdpppppppppp',
    [48] = '...............aaaaaaa...jjjjcj...pppppppppdppppp',
    [49] = '...............acaaaaa...jcjjjj...ppdpppppppppppp',
    [50] = '...............aaaaaaa...jjjjjj...ppppppppppdpppp',
    [51] = '................aaaaaa...jjjjjj...pppppdppppppppp',
    -- camisa jade (cols 25-31)
    [52] = '.........................jjcjjj...ppppppppppppppp',
    [53] = '.........................jjjjjj...ppdppppppppdppp',
    [54] = '.........................jjjjjj...ppppppdpppppppp',
    [55] = '.........................jjjcjj...ppppppppppppppp',
    [56] = '.........................jjjjjj...pppdppppppppppp',
    [57] = '..........................jjjj....ppppppppppdpppp',
    -- lençol de reboco pesado (cols 34-49): largo, barra irregular
    [58] = '..................................ppppppppppppppp',
    [59] = '..................................pppppdppppppppp',
    [60] = '..................................pppppppppppppp',
    [61] = '..................................ppdppppppppppp',
    [62] = '..................................ppppppppdppppp',
    [63] = '..................................pppppppppppppp',
    [64] = '..................................ppp.pppp.pppp',
    [65] = '...................................ppp.pp..ppp',
    [66] = '....................................pp..p..pp',
}

return {
    name = 'varal',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 5},
        -- mourões
        W = {ramp = 'wood', step = 5, h = 8},
        w = {ramp = 'wood', step = 4, h = 7},
        v = {ramp = 'wood', step = 2, h = 7},
        -- corda de fibra e volta no mourão
        r = {ramp = 'bone', step = 4, h = 8},
        R = {ramp = 'bone', step = 5, h = 8},
        -- prendedores
        n = {ramp = 'wood', step = 1, h = 8},
        -- roupas: jade, quente, reboco — 'c/d' dobras em sombra
        j = {ramp = 'cloth', step = 4, h = 6},
        c = {ramp = 'cloth', step = 2, h = 6},
        a = {ramp = 'clothWarm', step = 4, h = 6},
        p = {ramp = 'plaster', step = 4, h = 6},
        d = {ramp = 'plaster', step = 2, h = 6},
        -- chão
        g = {ramp = 'moss', step = 3, h = 2},
        G = {ramp = 'moss', step = 2, h = 2},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'corda', h = 7, albedo = R(corda)},
        {name = 'roupas', h = 6, albedo = {R(roupas1), R(roupas2)}},
    },
}
