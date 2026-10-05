-- V03_C01_WALK_E — protagonista C01, walk LESTE 4 frames reais:
-- f1 CONTACT-FRENTE (perna clara à frente), f2 RECOIL (juntas, corpo
-- baixo +1), f3 PASSING (perna de trás passa, corpo alto -1),
-- f4 CONTACT-TRÁS (espelho do f1). Arco firme na mão à frente, aba
-- solta do casaco balança, cabelo rabicho oscila. 64x96 feet.
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

-- TRONCO/CABEÇA/ARMS: iguais ao idle_e (estabilidade), permutations só
-- nas pernas + micro-bob. Monta direto na grade.
local function tronco(g)
    local T = {
        [9]  = '..............................kkkkk',
        [10] = '.............................khhhhhhs',
        [11] = '............................khhhhhhss',
        [12] = '............................khhhhhsss',
        [13] = '............................khhhhssss',
        [14] = '...........................khhhsssss',
        [15] = '...........................khhsssseee',
        [16] = '...........................khhsssssss',
        [17] = '...........................khssssssss',
        [18] = '...........................khssssskks',
        [19] = '...........................khssssskks',
        [20] = '...........................khssssgggs',
        [21] = '...........................khsssggggs',
        [22] = '...........................khsggggggg',
        [23] = '...........................khsgggggg',
        [24] = '............................kgggggg',
        [25] = '............................kskggg',
        [26] = '.............................ss',
        [27] = '............................ksss',
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
        [38] = '...............................kvvvss',
        [39] = '..............................kkvvsss',
        [40] = '.............................kklvssss',
        [41] = '.............................klssssss',
        [42] = '.............................ksssssss',
        [43] = '.............................ksssssss',
        [44] = '............................kssssssss',
        [45] = '............................kssssss',
        [46] = '............................kSsssss',
        [47] = '.........................kss',
        [48] = '.........................kss',
        [49] = '.........................ks',
    }
    for y, ln in pairs(T) do
        for x = 1, #ln do
            local c = ln:sub(x, x)
            if c ~= '.' then g.rows[y][x] = c end
        end
    end
end

-- Perna articulada em 3px de largura: quadril -> joelho -> pé.
-- c = 'p' (perto, clara) ou 'P' (longe, sombra); 'K' = joelheira.
local function perna(g, hx, hy, kx, ky, fx, fy, c)
    -- coxa 3px
    for o = 0, 2 do
        K.line(g, hx + o, hy, kx + o, ky, c)
    end
    -- joelheira no ponto médio da canela
    for dx = 0, 1 do
        K.pixel(g, kx + dx, ky, 'K'); K.pixel(g, kx + dx, ky + 1, 'K')
    end
    -- canela 2px
    for o = 0, 1 do
        K.line(g, kx + o, ky + 2, fx + o, fy - 8, c)
    end
    -- tornozelo afunila 1px antes da bota
    K.line(g, fx + 1, fy - 8, fx + 1, fy - 5, c)
    -- bota baixa: bico à direita (anda p/ leste), sola 'o' rara
    K.rect(g, fx - 1, fy - 5, 5, 3, 'b')
    K.rect(g, fx - 1, fy - 2, 7, 2, 'b')
    K.rect(g, fx - 1, fy, 7, 1, 'd')
end

local function monta(seed, pose)
    local g = K.new(64, 96)
    tronco(g)
    -- quadril: o casaco cobre até ~y58
    K.rect(g, 26, 50, 9, 5, 'p')
    for _, lg in ipairs(pose) do
        perna(g, lg[1], lg[2], lg[3], lg[4], lg[5], lg[6], lg[7])
    end
    return g
end

-- poses: {hx,hy,kx,ky,fx,fy,perna}
local poses = {
    -- f1: perna clara estendida à frente
    { { 28, 54, 37, 66, 44, 89, 'p' }, { 27, 54, 27, 68, 26, 90, 'P' } },
    -- f2: juntas, corpo cai
    { { 29, 55, 33, 68, 36, 90, 'p' }, { 28, 55, 30, 69, 30, 90, 'P' } },
    -- f3: perna clara sob o corpo, trás levanta
    { { 30, 53, 33, 67, 33, 89, 'p' }, { 28, 53, 30, 67, 27, 91, 'P' } },
    -- f4: contacto oposto (clara atrás agora... não: sempre a mesma
    -- perna clara à frente — o ciclo troca qual vai adiante)
    { { 28, 54, 28, 66, 27, 89, 'p' }, { 27, 54, 36, 68, 43, 90, 'P' } },
}

local frames = {}
for i, pose in ipairs(poses) do
    local g = monta(900 + i, pose)
    frames[i] = K.string(g)
end

-- frame 2 cai 1px (recoil): desloca tudo +1 em y
local function bob(str, dy)
    local rows = {}
    for l in str:gmatch('[^\n]+') do rows[#rows + 1] = l end
    local out = {}
    for r = 1, 96 do out[r] = E end
    for r = 1, 96 - dy do out[r + dy] = rows[r] end
    return table.concat(out, '\n')
end
frames[2] = bob(frames[2], 1)
frames[3] = bob(frames[3], -0)

local coat = {
    [34] = '..........................kkccccc',
    [35] = '.........................kkccnccc',
    [36] = '.........................kccnnncc',
    [37] = '.........................kccnnnccc',
    [38] = '.........................kcccnncccc',
    [39] = '.........................kccccnccccc',
    [40] = '.........................kcccccccccc',
    [41] = '.........................kccccccccccc',
    [42] = '.........................kccccccccccF',
    [43] = '.........................kccccccccccF',
    [44] = '........................kcccccccccccc',
    [45] = '........................kcccccccccccc',
    [46] = '........................kcccccccccck',
    [47] = '.......................kcccccccccck',
    [48] = '.......................kccccccccck',
    [49] = '.......................kcccccccck',
    [50] = '.......................kcccccccck',
    [51] = '......................kccccccck',
    [52] = '......................kccccccck',
    [53] = '......................kcccccck',
    [54] = '......................kcccccck',
    [55] = '......................kcccccCk',
    [56] = '......................kcccccCk',
    [57] = '......................kccxxxCxk',
    [58] = '......................kccxxxCxk',
    [59] = '.......................kxxxCxk',
    [60] = '........................kxxk',
}

local function swing(map, dy)
    local t = {}
    for r, s in pairs(map) do
        if r >= 44 and r <= 60 then t[r + dy] = s else t[r] = s end
    end
    return t
end
local coatF = { coat, swing(coat, 1), coat, swing(coat, -0) }

-- arco firme na mão (mesmo do idle, sobe/desce 1px com o corpo)
local gear = {}
for y = 12, 78 do
    local t = (y - 12) / 66
    local bx = math.floor(44 - math.sin(t * math.pi) * 4 + .5)
    gear[y] = { [bx] = 'W', [bx + 1] = 'w', [bx + 2] = 't' }
end
gear[11] = { [44] = 'W', [45] = 'w' }
gear[10] = { [45] = 't' }
gear[79] = { [44] = 'W', [45] = 'w' }
gear[80] = { [45] = 't' }
for y = 42, 46 do
    local bx = math.floor(44 - math.sin((y - 12) / 66 * math.pi) * 4 + .5)
    gear[y][bx - 1] = 'w'; gear[y][bx + 2] = 'w'
    if y >= 43 and y <= 45 then
        for x = 37, bx - 1 do gear[y][x] = 's' end
    end
end
gear[43][38] = 'S'; gear[44][39] = 'S'
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
local gearS = {}
for y, row in pairs(gear) do
    local xs = {}
    for x = 1, 64 do xs[x] = row[x] or '.' end
    gearS[y] = table.concat(xs)
end

local function bobGear(map, dy)
    local t = {}
    for r, s in pairs(map) do t[r + dy] = s end
    return t
end
local gearF = { gearS, bobGear(gearS, 1), gearS, gearS }

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
    C = { ramp = 'earth', step = 5, h = 7 },
    x = { ramp = 'earth', step = 2, h = 6 },
    n = { ramp = 'gold', step = 4, h = 8 },
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
    name = 'viajante_walk_e', w = 64, h = 96, origin = 'feet',
    legend = legend,
    anchors = {
        pe = { 33, 94 },
        cabeca = { 37, 15 },
        ferramenta = { 43, 44 },
        mao_arco = { 43, 44 },
    },
    sequences = { walk = { 1, 2, 3, 4, loop = true } },
    frameDuration = { 0.09, 0.09, 0.09, 0.09 },
    regions = {
        rosto = { x = 26, y = 9, w = 20, h = 18 },
        arco = { x = 4, y = 8, w = 52, h = 73 },
        aljava = { x = 16, y = 46, w = 9, h = 27 },
    },
    layers = {
        { name = 'body', h = 4, albedo = { frames[1], frames[2], frames[3], frames[4] } },
        { name = 'coat', h = 7,
          albedo = { R(coatF[1]), R(coatF[2]), R(coatF[3]), R(coatF[4]) } },
        { name = 'gear', h = 6,
          albedo = { R(gearF[1]), R(gearF[2]), R(gearF[3]), R(gearF[4]) } },
    },
}
