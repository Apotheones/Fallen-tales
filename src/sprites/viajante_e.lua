-- V03_C01_E — protagonista C01 "Trabalho Inacabado", idle LESTE (perfil
-- para a direita), 64x96, origem nos pés, 2 frames (respiro ±1px no
-- torso). Re-autoria pixel a pixel contra a ficha C01:
--   corpo: magro/ombros à frente, pele marrom quente, nariz largo de
--   ponta baixa, olho de pálpebra pesada, barba curta irregular,
--   cabelo ondulado na altura da nuca preso baixo (rabicho à esquerda).
--   roupa: casaco marrom-frio na altura da coxa, aba de caminhar
--   presa SÓ de um lado (assimetria), remendo ocre-claro no ombro,
--   colete de lã verde desbotada sobre camisa de linho cru, calça
--   carvão reforçada no joelho, bota baixa com sola remendada.
--   Âncoras: arco lateral alto, aba assimétrica, remendo claro do ombro.
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

--------------------------------------------------------------------------------
-- BODY: cabeça/pescoço/torso-base/pernas/botas (o casaco mora na layer
-- coat; arco+aljava+bolsa na layer gear)
--------------------------------------------------------------------------------
local body = {
    -- coroa do cabelo + testa
    [9]  = '..............................kkkkk',
    [10] = '.............................khhhhhhs',
    [11] = '............................khhhhhhss',
    [12] = '............................khhhhhsss',
    [13] = '............................khhhhssss',
    -- testa->olho pesado: pálpebra 'e' meio fechada
    [14] = '...........................khhhsssss',
    [15] = '...........................khhsssseee',
    [16] = '...........................khhsssssss',
    -- nariz largo de ponta baixa: saliência larga, desce 1px
    [17] = '...........................khssssssss',
    [18] = '...........................khssssskks',
    [19] = '...........................khssssskks',
    -- boca/barba curta irregular no maxilar
    [20] = '...........................khssssgggs',
    [21] = '...........................khsssggggs',
    [22] = '...........................khsggggggg',
    -- queixo + nuca (rabicho baixo caindo atrás à esquerda)
    [23] = '...........................khsgggggg',
    [24] = '............................kgggggg',
    [25] = '............................kskggg',
    -- pescoço curto e ombros levemente à frente (postura de testar o
    -- chão): a linha do pescoço pende 1px p/ a frente
    [26] = '.............................ss',
    [27] = '............................ksss',
    -- camisa de linho cru no peito, colete verde por cima
    [28] = '...........................klllss',
    [29] = '..........................kllllsss',
    [30] = '..........................klllvvsss',
    [31] = '.........................klllvvvvss',
    [32] = '.........................kllvvvvvvs',
    [33] = '.........................klvvvvvvvs',
    [34] = '.........................klvvvvvvv',
    [35] = '.........................kVvvvvvvv',
    [36] = '.........................kVvvvvvv',
    [37] = '.........................kVVvvvvv',
    -- braço da frente (direita, lado do arco): antebraço forte, manga
    -- de linho arregaçada irregular
    [38] = '...............................kvvvss',
    [39] = '..............................kkvvsss',
    [40] = '.............................kklvssss',
    [41] = '.............................klssssss',
    [42] = '.............................ksssssss',
    [43] = '.............................ksssssss',
    [44] = '............................kssssssss',
    -- punho/mão: dedos longos no punho do arco
    [45] = '............................kssssss',
    [46] = '............................kSsssss',
    -- braço de trás: quase escondido pela aba, antebraço à mostra
    [47] = '.........................kss',
    [48] = '.........................kss',
    [49] = '.........................ks',
    -- quadril: cinto + início das pernas (calça carvão)
    [50] = '.........................kppppppp',
    [51] = '.........................kpppppppp',
    [52] = '.........................kpppppppp',
    [53] = '.........................kpppppppp',
    -- perna da frente 'p' (clara) / de trás 'P' (sombra): joelho
    -- reforçado 'K' nas duas
    [54] = '.........................kPppppppp',
    [55] = '.........................kPppppppp',
    [56] = '.........................kPppppppp',
    [57] = '.........................kPpppKKpp',
    [58] = '.........................kPpppKKpp',
    [59] = '.........................kPppppppp',
    [60] = '.........................kPppppppp',
    [61] = '.........................kPpppppp',
    [62] = '.........................kPpppppp',
    [63] = '.........................kPpppppp',
    [64] = '.........................kPppppppp',
    [65] = '.........................kPppppppp',
    [66] = '.........................kPppppppp',
    [67] = '.........................kPppppppp',
    -- canela -> tornozelo afunila
    [68] = '.........................kPppppppp',
    [69] = '.........................kPpppppp',
    [70] = '.........................kPpppppp',
    [71] = '.........................kPppppp',
    [72] = '.........................kPppppp',
    [73] = '.........................kPppppp',
    [74] = '.........................kPppppp',
    [75] = '.........................kPppppp',
    [76] = '.........................kPppppp',
    -- botas baixas: cano curto, bico à direita, sola 'o' remendada na
    -- bota da frente (fio de couro claro solado de novo)
    [77] = '.........................kbbbbbbbb',
    [78] = '.........................kbbbbbbbb',
    [79] = '.........................kbbbbbbbbb',
    [80] = '.........................kbbbbbbbbb',
    [81] = '.........................kbbbbbbbbb',
    [82] = '.........................kbbbbbbbbb',
    [83] = '.........................kbbbbbbbbb',
    [84] = '.........................kbbbbbbbbb',
    [85] = '.........................kbbbbbbbbb',
    -- salto e sola: a da frente tem o remendo claro 'o'
    [86] = '.........................kbbobbbbbb',
    [87] = '.........................kbbbbbbbbb',
    [88] = '.........................kbbbbbbbbb',
    [89] = '.........................kbbbbbbbbbb',
    [90] = '.........................kbbbbbbbbbb',
    [91] = '.........................kbbbbbbbbbb',
    [92] = '.........................kbbbbbbbbbb',
    [93] = '.........................kbbbbbbbbb',
    [94] = '.........................kbbbbbbbbbb',
}

--------------------------------------------------------------------------------
-- COAT: casaco marrom-frio até a coxa; aba assimétrica — a aba da
-- frente (direita) fecha e amarra, a de trás cai aberta e oscila nos
-- frames. Remendo ocre-claro 'n' no ombro da frente.
--------------------------------------------------------------------------------
local coat = {
    -- ombros: casaco por cima do colete, remendo 'n' no ombro direito
    [34] = '..........................kkccccc',
    [35] = '.........................kkccnccc',
    [36] = '.........................kccnnncc',
    [37] = '.........................kccnnnccc',
    [38] = '.........................kcccnncccc',
    [39] = '.........................kccccnccccc',
    -- torso do casaco: aba da frente cobre o peito até o fecho 'F'
    [39] = '.........................kccccccccc',
    [40] = '.........................kccccccccc',
    [41] = '.........................kcccccccccc',
    [42] = '.........................kccccccccccc',
    [43] = '.........................kccccccccccF',
    [44] = '.........................kccccccccccF',
    -- aba de trás aberta: borda irregular caída (esquerda)
    [45] = '........................kccccccccccc',
    [46] = '........................kccccccccccc',
    [47] = '........................kcccccccccck',
    [48] = '.......................kcccccccccck',
    [49] = '.......................kccccccccck',
    -- saia do casaco até a coxa: barra irregular, fenda da frente
    [51] = '.......................kcccccccck',
    [52] = '......................kccccccck',
    [53] = '......................kccccccck',
    [54] = '......................kcccccck',
    [55] = '......................kcccccck',
    [56] = '......................kcccccCk',
    [57] = '......................kcccccCk',
    [58] = '......................kcccccCk',
    -- borda da barra em sombra 'x' + fenda
    [59] = '......................kccxxxCxk',
    [60] = '......................kccxxxCxk',
    [61] = '.......................kxxxCxk',
    [62] = '.......................kxxCxk',
    [63] = '........................kxxk',
    [64] = '........................kxxk',
}

-- GEAR: arco lateral ALTO (haste sobe além do ombro), aljava no
-- quadril de trás, bolsa de ferramenta à frente.
local gear = {
    -- arco lateral alto: haste quase vertical curvando p/ fora,
    -- do topo do ombro até a bota; corda 't' corre por dentro
}
-- haste: curva de 2px, x dobra à esquerda no meio (arco desenvergado)
for y = 12, 78 do
    local t = (y - 12) / 66
    local bx = math.floor(44 - math.sin(t * math.pi) * 4 + .5)
    local row = { [bx] = 'W', [bx + 1] = 'w' }
    -- corda: 2px dentro da curva
    row[bx + 2] = 't'
    gear[y] = row
end
-- pontas do arco (nocks)
gear[11] = { [44] = 'W', [45] = 'w' }
gear[10] = { [45] = 't' }
gear[79] = { [44] = 'W', [45] = 'w' }
gear[80] = { [45] = 't' }
-- empunhadura: espessura extra na altura da mão (y 42-46) + dedos
-- 's' ponteando do antebraço até a haste (a mão FECHA no arco)
for y = 42, 46 do
    local bx = math.floor(44 - math.sin((y - 12) / 66 * math.pi) * 4 + .5)
    gear[y][bx - 1] = 'w'; gear[y][bx + 2] = 'w'
    if y >= 43 and y <= 45 then
        for x = 37, bx - 1 do gear[y][x] = 's' end
    end
end
gear[43][38] = 'S'
gear[44][39] = 'S'
-- aljava no quadril de trás: corpo 'q', boca 'Q', flechas 'a'/'f'
local aljava = {
    [46] = '..................aaff',
    [47] = '..................afff',
}
for y = 48, 64 do aljava[y] = '.................kQqqqk' end
for y = 66, 72, 2 do aljava[y] = '..................kQqk' end
for y, ln in pairs(aljava) do
    gear[y] = gear[y] or {}
    for i = 1, #ln do
        local c = ln:sub(i, i)
        if c ~= '.' then gear[y][i] = c end
    end
end
-- bolsa de ferramenta no quadril da frente
local bolsa = {
    [46] = '...............................kmm',
    [47] = '..............................kmmmm',
    [48] = '..............................kmmmm',
    [49] = '...............................kmm',
}
for y, ln in pairs(bolsa) do
    gear[y] = gear[y] or {}
    for i = 1, #ln do
        local c = ln:sub(i, i)
        if c ~= '.' then gear[y][i] = c end
    end
end
-- materializa gear em tabela de strings
local gearS = {}
for y, row in pairs(gear) do
    local xs = {}
    for x = 1, 64 do xs[x] = row[x] or '.' end
    gearS[y] = table.concat(xs)
end
gear = gearS


local function overlay(ga, gb)
    local A, B, out = {}, {}, {}
    for l in ga:gmatch('[^\n]+') do A[#A + 1] = l end
    for l in gb:gmatch('[^\n]+') do B[#B + 1] = l end
    for i = 1, #A do
        local a, b, row = A[i], B[i] or '', {}
        for x = 1, 64 do
            local cb = b:sub(x, x)
            row[x] = (cb ~= '.' and cb ~= ' ' and cb ~= '') and cb
                or a:sub(x, x)
        end
        out[i] = table.concat(row)
    end
    return table.concat(out, '\n')
end

local function shiftDown(map, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then t[r + 1] = s
        else t[r] = s end
    end
    return t
end

local body2 = shiftDown(body, 26, 50)
local coat2 = shiftDown(coat, 34, 50)

local legend = {
    k = { spec = 'ink', h = 4 },
    h = { ramp = 'hair', step = 2, h = 11 },
    g = { ramp = 'hair', step = 3, h = 10 },
    s = { ramp = 'skin', step = 4, h = 11 },
    S = { ramp = 'skin', step = 5, h = 12 },
    d = { ramp = 'skin', step = 3, h = 10 },
    e = { spec = 'ink', h = 12 },
    l = { ramp = 'bone', step = 5, h = 6 },
    v = { ramp = 'moss', step = 3, h = 6 },
    V = { ramp = 'moss', step = 2, h = 6 },
    c = { ramp = 'earth', step = 4, h = 7 },
    C = { ramp = 'earth', step = 5, h = 7 },
    x = { ramp = 'earth', step = 2, h = 6 },
    n = { ramp = 'bone', step = 5, h = 8 },
    F = { ramp = 'gold', step = 5, h = 8 },
    p = { ramp = 'iron', step = 2, h = 4 },
    P = { ramp = 'iron', step = 1, h = 3 },
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
    name = 'viajante_e', w = 64, h = 96, origin = 'feet',
    legend = legend,
    anchors = {
        pe = { 33, 94 },
        cabeca = { 37, 15 },
        ferramenta = { 43, 44 },
        mao_arco = { 43, 44 },
        remendo_ombro = { 30, 36 },
    },
    sequences = { idle = { 1, 2, loop = true } },
    frameDuration = { 0.5, 0.5 },
    regions = {
        rosto = { x = 26, y = 9, w = 20, h = 18 },
        arco = { x = 4, y = 8, w = 52, h = 73 },
        aljava = { x = 16, y = 46, w = 9, h = 27 },
    },
    layers = {
        { name = 'body', h = 4, albedo = { R(body), R(body2) } },
        { name = 'coat', h = 7, albedo = { R(coat), R(coat2) } },
        { name = 'gear', h = 6, albedo = { R(gear), R(gear) } },
    },
}
