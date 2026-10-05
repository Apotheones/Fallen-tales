-- V03_C01_WALK_S — protagonista C01, walk SUL 4 frames (caminha de
-- frente p/ o observador). Fases por perna: plant (pé cheio no chão),
-- lift (calcanhar sobe, só bico toca), swing (joelho alto, pé no ar).
-- Tronco/cabeça = idle_s estável; casaco balança a saia; arco rígido
-- na mão esquerda (direita da tela). 64x96 feet.
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

local function tronco(g)
    local T = {
        [9]  = '.............................kkkkkk',
        [10] = '............................khhhhhhk',
        [11] = '...........................khhhhhhhhk',
        [12] = '...........................khhhhhhhhk',
        [13] = '...........................khhhhhhhhk',
        [14] = '...........................khhhhhhhhk',
        [15] = '...........................khhhhhhhhk',
        [16] = '...........................khhhhhhhhk',
        [17] = '...........................khhhhhhhhk',
        [18] = '............................khhhhhk',
        [19] = '............................khhhhhk',
        [20] = '.............................khhhk',
        [21] = '.............................khhk',
        [22] = '.............................khk',
        [23] = '.............................khk',
        [24] = '.............................ssk',
        [25] = '............................ksssk',
        [26] = '...........................ksssssk',
        [27] = '..........................ksssssssk',
        [28] = '..........................kssssssssk',
        [29] = '.........................klltvvvlk',
        [30] = '........................klltvvvvlk',
        [31] = '........................kltvvvvvvk',
        [32] = '.......................kltvvvvvvvk',
        [33] = '.......................ktvvvvvvvvk',
        [34] = '.......................ktVvvvvvvvk',
        [35] = '......................ktVVvvvvvvvk',
        [36] = '......................ktVVvvvvvvvk',
        [37] = '......................kttVvvvvvvk',
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
        [48] = '......................kppppppppk',
        [49] = '......................kppppppppk',
        [50] = '......................kppppppppk',
    }
    for y, ln in pairs(T) do
        for x = 1, #ln do
            local c = ln:sub(x, x)
            if c ~= '.' then g.rows[y][x] = c end
        end
    end
end

-- perna frontal: coluna de 3px, joelheira 'K', bota no pé
local function pernaS(g, cx, fase)
    local peTop = 87
    if fase == 'lift' then peTop = 89 end
    if fase == 'swing' then peTop = 84 end
    for y = 51, 57 do
        K.pixel(g, cx - 1, y, 'p'); K.pixel(g, cx, y, 'p')
        K.pixel(g, cx + 1, y, 'p')
    end
    -- joelheira
    K.rect(g, cx - 1, 58, 3, 2, 'K')
    -- canela até o tornozelo
    for y = 60, peTop - 8 do
        K.pixel(g, cx - 1, y, 'p'); K.pixel(g, cx, y, 'p')
        K.pixel(g, cx + 1, y, 'p')
    end
    for y = peTop - 8, peTop - 5 do
        K.pixel(g, cx, y, 'p'); K.pixel(g, cx + 1, y, 'p')
    end
    -- bota: plant=chão cheio, lift=só o bico (calcanhar 'd' sobe),
    -- swing=pé no ar um passo adiante
    if fase == 'plant' then
        K.rect(g, cx - 2, peTop - 5, 5, 8, 'b')
        K.rect(g, cx - 2, peTop + 3, 6, 1, 'd')
    elseif fase == 'lift' then
        K.rect(g, cx - 2, peTop - 5, 5, 5, 'b')
        K.rect(g, cx + 1, peTop, 4, 3, 'b')
        K.rect(g, cx + 1, peTop + 3, 4, 1, 'd')
    else
        K.rect(g, cx - 2, peTop - 5, 5, 6, 'b')
        K.rect(g, cx - 1, peTop + 1, 5, 1, 'd')
    end
end

local function monta(fl, fr, bobY)
    local g = K.new(64, 96)
    tronco(g)
    pernaS(g, 28, fl)   -- perna esquerda do corpo (esq. da tela)
    pernaS(g, 35, fr)   -- perna direita do corpo (dir. da tela)
    if bobY ~= 0 then
        -- desloca conteúdo inteiro bobY
        local rows = {}
        for y = 1, 96 do rows[y] = {} end
        for y = 1, 96 do for x = 1, 64 do
            rows[y][x] = K.get(g, x, y - bobY)
        end end
        for y = 1, 96 do for x = 1, 64 do
            g.rows[y][x] = rows[y][x]
        end end
    end
    return K.string(g)
end

-- f1: esquerda plantada, direita levanta
-- f2: juntas baixas (+1)
-- f3: direita plantada, esquerda no ar
-- f4: juntas altas
local frames = {
    monta('plant', 'lift', 0),
    monta('plant', 'plant', 1),
    monta('lift', 'plant', 0),
    monta('swing', 'plant', -1),
}

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

local function swing(map, dy, dx)
    local t = {}
    for r, s in pairs(map) do
        if r >= 48 and r <= 60 then
            local s2 = s
            if dx and dx ~= 0 then
                s2 = dx > 0 and (string.rep('.', dx) .. s) or s:sub(-dx + 1)
            end
            t[r + dy] = s2
        else t[r] = s end
    end
    return t
end
local coatF = {
    swing(coat, 0, 1), swing(coat, 1, 0), swing(coat, 0, -1), coat,
}

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
        for x = 38, bx - 2 do gear[y][x] = 's' end
    end
end
gear[43][40] = 'S'
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

local function bobM(map, dy)
    local t = {}
    for r, s in pairs(map) do t[r + dy] = s end
    return t
end
local gearF = { gearS, bobM(gearS, 1), gearS, bobM(gearS, -1) }

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
    name = 'viajante_walk_n', w = 64, h = 96, origin = 'feet',
    legend = legend,
    anchors = {
        pe = { 32, 94 },
        cabeca = { 33, 15 },
        ferramenta = { 47, 44 },
        mao_arco = { 44, 44 },
    },
    sequences = { walk = { 1, 2, 3, 4, loop = true } },
    frameDuration = { 0.09, 0.09, 0.09, 0.09 },
    regions = {
        rosto = { x = 26, y = 9, w = 14, h = 15 },
        arco = { x = 40, y = 8, w = 14, h = 73 },
    },
    layers = {
        { name = 'body', h = 4,
          albedo = { frames[1], frames[2], frames[3], frames[4] } },
        { name = 'coat', h = 7,
          albedo = { R(coatF[1]), R(coatF[2]), R(coatF[3]), R(coatF[4]) } },
        { name = 'gear', h = 6,
          albedo = { R(gearF[1]), R(gearF[2]), R(gearF[3]), R(gearF[4]) } },
    },
}
