-- V03_C01_S — protagonista C01, idle SUL (frente), 64x96, origem feet,
-- 2 frames (respiro ±1 torso). Âncoras C01 no frontal: arco lateral
-- alto à direita do corpo, aba do casaco assimétrica fechada de um
-- lado, remendo ocre no ombro. Olhos de pálpebra pesada 'e' 'e',
-- barba curta irregular, cabelo preso baixo some atrás da nuca.
local K = require 'src.pixel_kit'

local function L(s)
    assert(#s <= 64, 'linha > 64')
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

local body = {
    -- coroa de cabelo
    [9]  = '.............................kkkkkk',
    [10] = '............................khhhhhhk',
    [11] = '...........................khhhhhhhhk',
    [12] = '...........................khhhhhhhhk',
    -- testa + pálpebras pesadas: fios 'e' baixos
    [13] = '...........................khhssssssk',
    [14] = '...........................khssssssssk',
    [15] = '...........................khssesssesk',
    [16] = '...........................khssssssssk',
    -- nariz largo de ponta baixa: coluna central 's' mais larga
    [17] = '...........................khssssssssk',
    [18] = '...........................khsssssddsk',
    [19] = '...........................khssssddssk',
    -- boca sob a sombra do nariz, barba curta nas mandíbulas
    [20] = '...........................khssggggssk',
    [21] = '...........................khsgggggggk',
    [22] = '...........................kksgggggggk',
    [23] = '............................ksggggggk',
    -- queixo + nuca (rabicho baixo espiando atrás)
    [24] = '............................ksssssk',
    [25] = '...........................khkkssk',
    [26] = '...........................khhk',
    -- pescoço + colarinho de linho cru aberto em V
    [27] = '............................kssk',
    [28] = '...........................kllllllk',
    [29] = '..........................kllssslllk',
    -- colete verde desbotado por cima da camisa
    [30] = '..........................klllvvvlk',
    [31] = '.........................klllvvvvvlk',
    [32] = '.........................kllvvvvvvvlk',
    [33] = '.........................klvvvvvvvvk',
    [34] = '.........................klvvvvvvvvk',
    [35] = '.........................kVvvvvvvvvk',
    [36] = '.........................kVvvvvvvvvk',
    [37] = '.........................kVVvvvvvvk',
    -- braços: antebraços fortes à vista, mangas arregaçadas,
    -- mão direita (esquerda da tela) cai solta, mão esquerda
    -- (direita) segura o arco
    [38] = '........................ksskvvvvvvkssk',
    [39] = '........................ksskvvvvvvkssk',
    [40] = '........................kssskvvvvksssk',
    [41] = '.........................kssskvvksssk',
    [42] = '.........................kssskkkssssk',
    [43] = '.........................ksssk.kssssk',
    [44] = '.........................ksssk..ksssk',
    [45] = '.........................kssk...ksssk',
    -- mãos: dedos longos — a direita em volta do arco
    [46] = '.........................kssk....kssk',
    [47] = '.........................ksk.....kssk',
    -- quadril + cinto
    [48] = '.........................kppppppppk',
    [49] = '.........................kppppppppk',
    [50] = '.........................kppppppppk',
    -- pernas: duas colunas carvão, joelho reforçado 'K'
    [51] = '.........................kpppKKpppk',
    [52] = '.........................kpppKKpppk',
    [53] = '.........................kppppppppk',
    [54] = '.........................kppppppppk',
    [55] = '.........................kppppkpppk',
    [56] = '.........................kppppkpppk',
    [57] = '.........................kppppkpppk',
    [58] = '.........................kpppk.kpppk',
    [59] = '.........................kpppk.kpppk',
    [60] = '.........................kpppk.kpppk',
    [61] = '.........................kpppk.kpppk',
    [62] = '.........................kpppk.kpppk',
    [63] = '.........................kpppk.kpppk',
    -- afunila abaixo do joelho
    [64] = '.........................kpppk.kpppk',
    [65] = '.........................kpppk.kpppk',
    [66] = '.........................kpppk.kpppk',
    [67] = '.........................kpppk.kpppk',
    [68] = '.........................kpppk.kpppk',
    [69] = '.........................kpppk.kpppk',
    [70] = '.........................kpppk.kpppk',
    [71] = '.........................kpppk.kpppk',
    [72] = '.........................kpppk.kpppk',
    [73] = '.........................kpppk.kpppk',
    [74] = '.........................kpppk.kpppk',
    [75] = '.........................kpppk.kpppk',
    [76] = '.........................kpppk.kpppk',
    [77] = '.........................kpppk.kpppk',
    -- tornozelo aperta na bota
    [78] = '.........................kpppk.kpppk',
    [79] = '.........................kbbbk.kbbbk',
    [80] = '.........................kbbbk.kbbbk',
    [81] = '.........................kbbbbk.kbbbbk',
    [82] = '.........................kbbbbk.kbbbbk',
    [83] = '.........................kbbbbk.kbbbbk',
    [84] = '.........................kbbbbk.kbbbbk',
    [85] = '.........................kbbbbk.kbbbbk',
    [86] = '.........................kbbbbk.kbbbbk',
    -- sola remendada 'o' na bota esquerda dele (direita da tela)
    [87] = '.........................kbbbbk.kbobbbk',
    [88] = '.........................kbbbbk.kbbbbk',
    [89] = '.........................kbbbbk.kbbbbk',
    [90] = '.........................kbbbbk.kbbbbk',
    [91] = '.........................kbbbbk.kbbbbk',
    [92] = '.........................kbbbbk.kbbbbk',
    [93] = '.........................kbbbk.kbbbk',
    [94] = '.........................kbbbk.kbbbk',
}

-- COAT (frontal): casaco aberto, colarinho/arrematação nos ombros,
-- aba fechada à ESQUERDA da tela (fastened 'F'), aba da direita solta
-- aberta sobre a perna. Remendo 'n' no ombro direito dele = esquerda
-- da tela... C01: remendo no ombro ESQUERDO do sprite? espelho do E:
-- no perfil o remendo fica no ombro da frente (direita). No frontal
-- mantemos no lado direito da tela p/ consistência.
local coat = {
    [30] = '........................kcckvvvkcck',
    [31] = '.......................kccckvvkccck',
    [32] = '......................kcccckvkcccck',
    -- remendo ocre no ombro direito da tela
    [33] = '......................kccccknnkcccck',
    [34] = '......................kccccnnnkcccck',
    [35] = '......................kccccknnkcccck',
    [36] = '......................kccccc.kccccc',
    [37] = '......................kccccc.kccccc',
    -- aba esquerda fecha (varre o centro), direita aberta mostra
    -- o colete/perna por dentro
    [38] = '......................kccccc...kccc',
    [39] = '......................kcccccF..kccc',
    [40] = '......................kcccccF..kccc',
    [41] = '......................kccccc....kcc',
    [42] = '......................kccccc....kcc',
    [43] = '......................kccccc....kcc',
    [44] = '......................kccccc.....kc',
    [45] = '......................kccccc.....kc',
    [46] = '......................kccccc......k',
    [47] = '......................kccccc',
    [48] = '......................kccccc',
    -- saia até a coxa: esquerda segue fechada, direita aberta cai
    [49] = '......................kcccck',
    [50] = '......................kcccck',
    [51] = '......................kcccck',
    [52] = '......................kcccck',
    [53] = '......................kccxck',
    [54] = '......................kccxck',
    [55] = '......................kccxck',
    [56] = '......................kccxck',
    [57] = '......................kccxck',
    [58] = '......................kccxxk',
    [59] = '......................kcxxxk',
    [60] = '......................kxxxk',
}

-- GEAR (frontal): arco à DIREITA da tela quase vertical, mão fecha
-- na empunhadura; aljava espiando ATRÁS do ombro esquerdo.
local gear = {}
for y = 12, 78 do
    local t = (y - 12) / 66
    local bx = math.floor(48 - math.sin(t * math.pi) * 3 + .5)
    gear[y] = { [bx] = 'W', [bx + 1] = 'w', [bx + 2] = 't' }
end
gear[11] = { [48] = 'W', [49] = 'w' }
gear[79] = { [48] = 'W', [49] = 'w' }
gear[80] = { [49] = 't' }
-- empunhadura + mão esquerda (direita da tela) ponteando do braço
for y = 42, 46 do
    local bx = math.floor(48 - math.sin((y - 12) / 66 * math.pi) * 3 + .5)
    gear[y][bx - 1] = 'w'
    if y >= 43 and y <= 45 then
        for x = 38, bx - 2 do gear[y][x] = 's' end
    end
end
gear[43][39] = 'S'
-- aljava: boca e flechas acima do ombro esquerdo, corpo some atrás
gear[26] = { [25] = 'a', [26] = 'a', [28] = 'f', [29] = 'f' }
gear[27] = { [24] = 'a', [25] = 'f', [26] = 'f', [27] = 'a' }
for y = 28, 44 do
    gear[y] = gear[y] or {}
    gear[y][24] = 'q'; gear[y][25] = 'Q'; gear[y][26] = 'q'
end
-- bolsa de ferramenta no quadril direito dele (esquerda da tela)
gear[48][26] = 'm'; gear[48][27] = 'm'
gear[49] = gear[49] or {}
gear[49][26] = 'm'; gear[49][27] = 'm'; gear[49][28] = 'm'
gear[50] = gear[50] or {}
gear[50][26] = 'm'; gear[50][27] = 'm'

local gearS = {}
for y, row in pairs(gear) do
    local xs = {}
    for x = 1, 64 do xs[x] = row[x] or '.' end
    gearS[y] = table.concat(xs)
end
gear = gearS

local function shiftDown(map, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then t[r + 1] = s
        else t[r] = s end
    end
    return t
end
local body2 = shiftDown(body, 27, 48)
local coat2 = shiftDown(coat, 30, 48)

local legend = {
    k = { spec = 'ink', h = 4 },
    h = { ramp = 'hair', step = 2, h = 11 },
    g = { ramp = 'hair', step = 3, h = 10 },
    s = { ramp = 'skin', step = 4, h = 11 },
    S = { ramp = 'skin', step = 5, h = 12 },
    d = { ramp = 'skin', step = 3, h = 10 },
    e = { spec = 'ink', h = 12 },
    l = { ramp = 'bone', step = 5, h = 6 },
    v = { ramp = 'moss', step = 4, h = 6 },
    V = { ramp = 'moss', step = 3, h = 6 },
    c = { ramp = 'earth', step = 4, h = 7 },
    x = { ramp = 'earth', step = 2, h = 6 },
    n = { ramp = 'gold', step = 4, h = 8 },
    F = { ramp = 'gold', step = 5, h = 8 },
    p = { ramp = 'iron', step = 2, h = 4 },
    K = { ramp = 'iron', step = 3, h = 5 },
    b = { ramp = 'earth', step = 3, h = 3 },
    o = { ramp = 'earth', step = 5, h = 3 },
    w = { ramp = 'wood', step = 3, h = 5 },
    W = { ramp = 'wood', step = 5, h = 6 },
    t = { ramp = 'bone', step = 4, h = 4 },
    q = { ramp = 'earth', step = 4, h = 7 },
    Q = { ramp = 'earth', step = 2, h = 7 },
    a = { ramp = 'wood', step = 5, h = 7 },
    f = { ramp = 'bone', step = 5, h = 7 },
    m = { ramp = 'earth', step = 4, h = 7 },
}

return {
    name = 'viajante', w = 64, h = 96, origin = 'feet',
    legend = legend,
    anchors = {
        pe = { 32, 94 },
        cabeca = { 33, 15 },
        ferramenta = { 47, 44 },
        mao_arco = { 44, 44 },
        remendo_ombro = { 42, 34 },
    },
    sequences = { idle = { 1, 2, loop = true } },
    frameDuration = { 0.5, 0.5 },
    regions = {
        rosto = { x = 26, y = 9, w = 14, h = 18 },
        arco = { x = 40, y = 8, w = 14, h = 73 },
        aljava = { x = 24, y = 26, w = 6, h = 19 },
    },
    layers = {
        { name = 'body', h = 4, albedo = { R(body), R(body2) } },
        { name = 'coat', h = 7, albedo = { R(coat), R(coat2) } },
        { name = 'gear', h = 6, albedo = { R(gear), R(gear) } },
    },
}
