-- PISO_TERRA — terra batida, tile 64x64, origem topleft. 4 frames =
-- variantes de seed. Massa contínua de barro com manchas orgânicas
-- (carimbos desenhados, não ruído), pedrinhas em clusters com sombra
-- própria e uma mancha de desgaste mais clara. h: vale escuro 0,
-- massa 1, pedrinha 2.

local W, H = 64, 64

local function nova(fill)
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = fill end
        g[y] = r
    end
    return g
end

local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end

local function carimbo(g, x, y, forma)
    for j = 1, #forma do
        local linha = forma[j]
        for i = 1, #linha do
            local c = linha:sub(i, i)
            if c ~= '.' then set(g, x + i - 1, y + j - 1, c) end
        end
    end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

-- Manchas escuras de barro pisado (irregulares, desenhadas).
local MANCHA_A = {
    '.dd...',
    'ddddd.',
    'ddddd.',
    '.ddd..',
    '..d...',
}
local MANCHA_B = {
    '..ddd..',
    '.ddddd.',
    'dddddd.',
    'dddd...',
    '.ddd...',
    '..d....',
}
local MANCHA_C = {
    'dd..',
    'ddd.',
    '.ddd',
    '..dd',
}
local MANCHA_D = {
    '...dd..',
    '..dddd.',
    '.ddddd.',
    'dddddd.',
    '.dddd..',
}
-- Mancha de desgaste: faixa clara onde o pé sempre passa.
local DESGASTE_A = {
    '...bbbbb....',
    '..bbbbbbb...',
    '.bbbbbbbbb..',
    'bbbbbbbbbb..',
    '.bbbbbbbbb..',
    '..bbbbbbb...',
    '...bbbbb....',
}
local DESGASTE_B = {
    '..bbbbb...',
    '.bbbbbbb..',
    'bbbbbbbbb.',
    'bbbbbbbb..',
    '.bbbbbbb..',
    '..bbbbb...',
}
-- Pedrinhas: cluster claro com sombra embaixo (desenhado, nunca solto).
local PEDRA_A = {
    '.pp.',
    'pppd',
    '.dd.',
}
local PEDRA_B = {
    'pp.',
    'ppd',
    '.d.',
}
local PEDRA_C = {
    '.p..',
    'ppp.',
    'd.d.',
}
local PEDRA_D = {
    'ppp.',
    '.ppd',
    '..d.',
}
local PEDRA_E = { -- par de pedrinhas
    'p..p',
    'd..d',
}
-- Vale fundo: depressão de um-dois pixels, só onde a mancha escurece.
local VALE = { 'r' }
local VALE2 = { 'rr' }

local function terra(spec)
    local g = nova('a')
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

local V1 = {
    carimbos = {
        { 8, 10, MANCHA_B }, { 40, 7, MANCHA_C }, { 52, 26, MANCHA_D },
        { 14, 34, MANCHA_A }, { 44, 44, MANCHA_C }, { 24, 52, MANCHA_A },
        { 22, 14, DESGASTE_A },
        { 30, 30, PEDRA_A }, { 56, 12, PEDRA_B }, { 5, 47, PEDRA_C },
        { 48, 33, PEDRA_D }, { 35, 55, PEDRA_E }, { 14, 22, PEDRA_B },
        { 18, 16, VALE }, { 53, 31, VALE2 }, { 46, 47, VALE },
        { 60, 55, PEDRA_C }, { 2, 30, PEDRA_D },
    },
}

local V2 = {
    carimbos = {
        { 44, 12, MANCHA_B }, { 10, 44, MANCHA_B }, { 55, 48, MANCHA_C },
        { 20, 8, MANCHA_A }, { 33, 33, MANCHA_D }, { 5, 24, MANCHA_C },
        { 12, 24, DESGASTE_B }, { 38, 40, DESGASTE_B },
        { 50, 30, PEDRA_A }, { 25, 18, PEDRA_C }, { 58, 8, PEDRA_D },
        { 8, 56, PEDRA_B }, { 42, 58, PEDRA_E }, { 28, 44, PEDRA_D },
        { 47, 17, VALE }, { 13, 48, VALE2 }, { 36, 37, VALE },
        { 60, 20, PEDRA_B }, { 18, 60, PEDRA_C },
    },
}

local V3 = {
    carimbos = {
        { 6, 8, MANCHA_C }, { 34, 14, MANCHA_D }, { 52, 40, MANCHA_B },
        { 16, 50, MANCHA_D }, { 46, 6, MANCHA_A }, { 8, 30, MANCHA_A },
        { 28, 26, DESGASTE_A },
        { 40, 50, PEDRA_A }, { 12, 16, PEDRA_B }, { 55, 22, PEDRA_C },
        { 24, 42, PEDRA_D }, { 4, 58, PEDRA_E }, { 58, 56, PEDRA_B },
        { 9, 13, VALE }, { 37, 18, VALE2 }, { 54, 44, VALE },
        { 44, 30, PEDRA_C }, { 30, 60, PEDRA_D },
    },
}

local V4 = {
    carimbos = {
        { 28, 10, MANCHA_B }, { 50, 28, MANCHA_A }, { 12, 22, MANCHA_D },
        { 40, 46, MANCHA_A }, { 8, 52, MANCHA_C }, { 58, 10, MANCHA_C },
        { 34, 32, DESGASTE_B }, { 6, 36, DESGASTE_B },
        { 18, 34, PEDRA_A }, { 46, 18, PEDRA_C }, { 26, 56, PEDRA_B },
        { 56, 44, PEDRA_D }, { 36, 6, PEDRA_E }, { 4, 14, PEDRA_B },
        { 31, 14, VALE }, { 14, 26, VALE2 }, { 42, 50, VALE },
        { 60, 60, PEDRA_C }, { 48, 58, PEDRA_D },
    },
}

return {
    name = 'piso_terra',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        a = { ramp = 'earth', step = 4, h = 1 }, -- massa de barro
        b = { ramp = 'earth', step = 5, h = 1 }, -- desgaste claro
        d = { ramp = 'earth', step = 2, h = 1 }, -- mancha pisada escura
        r = { ramp = 'earth', step = 1, h = 0 }, -- vale fundo
        p = { ramp = 'earth', step = 6, h = 2 }, -- pedrinha
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { terra(V1), terra(V2), terra(V3), terra(V4) },
        },
    },
}
