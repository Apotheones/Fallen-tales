-- V03_C01_N — protagonista C01, idle NORTE (costas), 64x96, feet, 2f.
-- De costas lêem: massa de cabelo ondulado + rabicho baixo 'hhk',
-- aljava em DIAGONAL nas costas com a tira cruzando o peito 't',
-- remendo do ombro visto de trás, aba assimétrica do casaco,
-- arco lateral alto à direita (mesmo lado do perfil).
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
    -- coroa + nuca: tudo cabelo, orelha nenhuma
    [9]  = '.............................kkkkkk',
    [10] = '............................khhhhhhk',
    [11] = '...........................khhhhhhhhk',
    [12] = '...........................khhhhhhhhk',
    [13] = '...........................khhhhhhhhk',
    [14] = '...........................khhhhhhhhk',
    [15] = '...........................khhhhhhhhk',
    [16] = '...........................khhhhhhhhk',
    [17] = '...........................khhhhhhhhk',
    -- nuca: o cabelo termina e o rabicho baixo desce no centro
    [18] = '............................khhhhhk',
    [19] = '............................khhhhhk',
    [20] = '.............................khhhk',
    [21] = '.............................khhk',
    [22] = '.............................khk',
    [23] = '.............................khk',
    -- pescoço + colarinho
    [24] = '.............................ssk',
    [25] = '............................ksssk',
    -- ombros à frente (de costas, a linha dos ombros é mais baixa)
    [26] = '...........................ksssssk',
    [27] = '..........................ksssssssk',
    [28] = '..........................kssssssssk',
    -- camisa/colete de costas: quase tudo colete + tira da aljava 't'
    [29] = '.........................klltvvvlk',
    [30] = '........................klltvvvvlk',
    [31] = '........................kltvvvvvvk',
    [32] = '.......................kltvvvvvvvk',
    [33] = '.......................ktvvvvvvvvk',
    [34] = '.......................ktVvvvvvvvk',
    [35] = '......................ktVVvvvvvvvk',
    [36] = '......................ktVVvvvvvvvk',
    [37] = '......................kttVvvvvvvk',
    -- braços pendendo (antebraços à mostra)
    [38] = '......................ktsskvvvvvkssk',
    [39] = '......................ktsskvvvvksssk',
    [40] = '......................kssskvvvksssk',
    [41] = '......................kssskvvkssssk',
    [42] = '......................kssskkkssssk',
    [43] = '......................ksssk.kssssk',
    [44] = '......................ksssk..ksssk',
    [45] = '......................kssk...ksssk',
    [46] = '......................kssk....kssk',
    [47] = '......................ksk.....kssk',
    -- quadril
    [48] = '......................kppppppppk',
    [49] = '......................kppppppppk',
    [50] = '......................kppppppppk',
    -- pernas
    [51] = '......................kpppKKpppk',
    [52] = '......................kpppKKpppk',
    [53] = '......................kppppppppk',
    [54] = '......................kppppppppk',
    [55] = '......................kppppkpppk',
    [56] = '......................kppppkpppk',
    [57] = '......................kppppkpppk',
    [58] = '......................kpppk.kpppk',
    [59] = '......................kpppk.kpppk',
    [60] = '......................kpppk.kpppk',
    [61] = '......................kpppk.kpppk',
    [62] = '......................kpppk.kpppk',
    [63] = '......................kpppk.kpppk',
    [64] = '......................kpppk.kpppk',
    [65] = '......................kpppk.kpppk',
    [66] = '......................kpppk.kpppk',
    [67] = '......................kpppk.kpppk',
    [68] = '......................kpppk.kpppk',
    [69] = '......................kpppk.kpppk',
    [70] = '......................kpppk.kpppk',
    [71] = '......................kpppk.kpppk',
    [72] = '......................kpppk.kpppk',
    [73] = '......................kpppk.kpppk',
    [74] = '......................kpppk.kpppk',
    [75] = '......................kpppk.kpppk',
    [76] = '......................kpppk.kpppk',
    [77] = '......................kpppk.kpppk',
    [78] = '......................kpppk.kpppk',
    [79] = '......................kbbbk.kbbbk',
    [80] = '......................kbbbk.kbbbk',
    [81] = '......................kbbbbk.kbbbbk',
    [82] = '......................kbbbbk.kbbbbk',
    [83] = '......................kbbbbk.kbbbbk',
    [84] = '......................kbbbbk.kbbbbk',
    [85] = '......................kbbbbk.kbbbbk',
    [86] = '......................kbbbbk.kbbbbk',
    [87] = '......................kbbbbk.kbobbbk',
    [88] = '......................kbbbbk.kbbbbk',
    [89] = '......................kbbbbk.kbbbbk',
    [90] = '......................kbbbbk.kbbbbk',
    [91] = '......................kbbbbk.kbbbbk',
    [92] = '......................kbbbbk.kbbbbk',
    [93] = '......................kbbbk.kbbbk',
    [94] = '......................kbbbk.kbbbk',
}

-- COAT de costas: cobre os ombros, aba fechada à esquerda cai
-- comprida, direita solta aberta; remendo 'n' no ombro direito da
-- tela (mesmo ombro do frontal/perfil = ombro ESQUERDO do corpo).
local coat = {
    [26] = '.......................kccccccck',
    [27] = '......................kccccccnnnck',
    [28] = '......................kccccccnncck',
    [29] = '......................kcccccnnncccck',
    [30] = '......................kcccccccccccck',
    [31] = '......................kcccccccccccck',
    [32] = '......................kcccccccccccck',
    [33] = '......................kcccccccccccck',
    [34] = '......................kcccccccccccck',
    [35] = '......................kcccccccccccck',
    [36] = '......................kcccccccccccck',
    [37] = '......................kcccccccccccck',
    -- cintura: aba fechada continua à esquerda, direita abre a fenda
    [38] = '......................kcccccck.kcck',
    [39] = '......................kcccccck..kck',
    [40] = '......................kcccccck..kck',
    [41] = '......................kcccccck...kk',
    [42] = '......................kcccccck',
    [43] = '......................kcccccck',
    [44] = '......................kcccccck',
    [45] = '......................kcccccck',
    [46] = '......................kcccccck',
    [47] = '......................kcccccck',
    [48] = '......................kcccccck',
    [49] = '......................kccxcck',
    [50] = '......................kccxcck',
    [51] = '......................kccxcck',
    [52] = '......................kccxcck',
    [53] = '......................kccxcck',
    [54] = '......................kccxcck',
    [55] = '......................kccxxck',
    [56] = '......................kcxxxck',
    [57] = '......................kxxxxk',
}

-- GEAR de costas: arco à direita (consistência com E/S), aljava em
-- diagonal larga subindo do quadril esquerdo ao ombro direito,
-- flechas sobre o ombro esquerdo.
local gear = {}
for y = 12, 78 do
    local t = (y - 12) / 66
    local bx = math.floor(48 - math.sin(t * math.pi) * 3 + .5)
    gear[y] = { [bx] = 'W', [bx + 1] = 'w', [bx + 2] = 't' }
end
gear[11] = { [48] = 'W', [49] = 'w' }
gear[79] = { [48] = 'W', [49] = 'w' }
gear[80] = { [49] = 't' }
for y = 42, 46 do
    local bx = math.floor(48 - math.sin((y - 12) / 66 * math.pi) * 3 + .5)
    gear[y][bx - 1] = 'w'
    if y >= 43 and y <= 45 then
        for x = 39, bx - 2 do gear[y][x] = 's' end
    end
end
gear[43][40] = 'S'
-- aljava diagonal: do quadril esquerdo (baixo) ao ombro direito
-- (alto) — por baixo do casaco só a tira 't' aparece; o corpo 'q'
-- fica visível abaixo da saia do casaco, à esquerda
gear[25] = { [30] = 'f', [31] = 'a', [32] = 'f' }
gear[26] = { [29] = 'a', [30] = 'f', [31] = 'a', [32] = 'f', [33] = 'a' }
for y = 58, 74 do
    gear[y] = gear[y] or {}
    gear[y][24] = 'q'; gear[y][25] = 'Q'; gear[y][26] = 'q'
end
for y = 56, 58 do
    gear[y] = gear[y] or {}
    gear[y][25] = 'q'; gear[y][26] = 'q'
end

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
local coat2 = shiftDown(coat, 26, 48)

local legend = {
    k = { spec = 'ink', h = 4 },
    h = { ramp = 'hair', step = 2, h = 11 },
    s = { ramp = 'skin', step = 4, h = 11 },
    S = { ramp = 'skin', step = 5, h = 12 },
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
    name = 'viajante_n', w = 64, h = 96, origin = 'feet',
    legend = legend,
    anchors = {
        pe = { 32, 94 },
        cabeca = { 33, 15 },
        ferramenta = { 47, 44 },
        mao_arco = { 44, 44 },
        remendo_ombro = { 41, 29 },
    },
    sequences = { idle = { 1, 2, loop = true } },
    frameDuration = { 0.5, 0.5 },
    regions = {
        rosto = { x = 26, y = 9, w = 14, h = 15 },
        arco = { x = 40, y = 8, w = 14, h = 73 },
        aljava = { x = 24, y = 25, w = 10, h = 50 },
    },
    layers = {
        { name = 'body', h = 4, albedo = { R(body), R(body2) } },
        { name = 'coat', h = 7, albedo = { R(coat), R(coat2) } },
        { name = 'gear', h = 6, albedo = { R(gear), R(gear) } },
    },
}
