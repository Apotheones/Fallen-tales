-- PISO_GRAMA — gramado sálvia do Refúgio, tile 64x64, origem topleft.
-- 4 frames = variantes de seed. Massa de musgo/verde seco em manchas
-- desenhadas + touceiras verticais (clusters de 2-4 px com sombra na
-- base) + flor ocasional rara. h: vale 0, massa 1, touceira 3.

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

-- Manchas de massa: musgo fundo ('d'), touceira clara ('l'), terra seca
-- aparecendo ('e') — desenhadas em clusters, nunca pontilhado.
local MANCHA_D1 = {
    '.ddd..',
    'ddddd.',
    'ddddd.',
    '.ddd..',
    '..d...',
}
local MANCHA_D2 = {
    '..dd...',
    '.dddd.',
    'ddddd..',
    'dddd...',
    '.dd....',
}
local MANCHA_L1 = {
    '.ll..',
    'llll.',
    'llll.',
    '.lll.',
}
local MANCHA_L2 = {
    '..lll..',
    '.lllll.',
    'llllll.',
    '.llll..',
}
local MANCHA_E1 = {
    '.ee..',
    'eeee.',
    'eee..',
    '.e...',
}
local MANCHA_E2 = {
    '..ee.',
    '.eeee',
    'eee..',
    'ee...',
}

-- Touceiras: lâminas claras ('t') e médias ('u') de pé na sombra ('x').
local TUFA = {
    't.t',
    'ttt',
    'xux',
}
local TUFB = {
    '.t.',
    'tut',
    'xux',
}
local TUFC = { -- touceira alta, 4 px de lâmina
    't..t',
    'tutt',
    '.tu.',
    '.xx.',
}
local TUFD = {
    'u.u',
    'tut',
    'xxx',
}
local TUFE = { -- par de touceiras encostadas
    't...t',
    'tt.tu',
    'xuxux',
}

-- Flor rara: corola clara ('f') com coração quente ('o') sobre haste.
local FLOR = {
    '.f.',
    'fof',
    '.t.',
    '.x.',
}
local FLOR2 = {
    'f.f',
    '.o.',
    '.t.',
}

local function grama(spec)
    local g = nova('a')
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

local V1 = {
    carimbos = {
        { 10, 12, MANCHA_D1 }, { 42, 8, MANCHA_L2 }, { 52, 30, MANCHA_D2 },
        { 18, 40, MANCHA_L1 }, { 36, 50, MANCHA_D1 }, { 5, 52, MANCHA_E1 },
        { 24, 22, MANCHA_L1 }, { 48, 54, MANCHA_E2 },
        { 15, 18, TUFA }, { 30, 10, TUFC }, { 56, 18, TUFB },
        { 44, 28, TUFD }, { 8, 34, TUFE }, { 26, 44, TUFA },
        { 52, 44, TUFC }, { 38, 58, TUFB }, { 14, 58, TUFD },
        { 60, 8, TUFA }, { 33, 32, TUFB }, { 58, 58, FLOR },
    },
}

local V2 = {
    carimbos = {
        { 44, 14, MANCHA_D2 }, { 8, 8, MANCHA_L1 }, { 24, 36, MANCHA_D1 },
        { 50, 46, MANCHA_L2 }, { 16, 54, MANCHA_D2 }, { 34, 8, MANCHA_E1 },
        { 55, 32, MANCHA_L1 }, { 6, 40, MANCHA_E2 },
        { 28, 16, TUFA }, { 50, 8, TUFD }, { 12, 26, TUFC },
        { 38, 24, TUFB }, { 58, 52, TUFE }, { 30, 48, TUFD },
        { 44, 40, TUFA }, { 8, 58, TUFA }, { 60, 20, TUFC },
        { 20, 46, TUFB }, { 42, 58, TUFA }, { 16, 34, TUFB },
    },
}

local V3 = {
    carimbos = {
        { 30, 10, MANCHA_D1 }, { 8, 30, MANCHA_L2 }, { 46, 24, MANCHA_D2 },
        { 18, 48, MANCHA_L1 }, { 56, 50, MANCHA_D1 }, { 40, 44, MANCHA_E1 },
        { 58, 10, MANCHA_L1 }, { 26, 58, MANCHA_E2 },
        { 14, 14, TUFD }, { 36, 6, TUFA }, { 54, 36, TUFC },
        { 22, 30, TUFE }, { 6, 46, TUFA }, { 44, 56, TUFC },
        { 32, 38, TUFB }, { 58, 22, TUFB }, { 12, 58, TUFD },
        { 50, 12, TUFA }, { 26, 12, FLOR2 }, { 40, 30, TUFD },
    },
}

local V4 = {
    carimbos = {
        { 16, 8, MANCHA_L2 }, { 48, 12, MANCHA_D1 }, { 6, 44, MANCHA_D2 },
        { 36, 34, MANCHA_L1 }, { 54, 54, MANCHA_E1 }, { 28, 56, MANCHA_D1 },
        { 10, 24, MANCHA_E2 }, { 58, 32, MANCHA_L1 },
        { 42, 8, TUFC }, { 24, 18, TUFA }, { 56, 24, TUFE },
        { 8, 56, TUFD }, { 34, 46, TUFA }, { 48, 42, TUFD },
        { 18, 36, TUFC }, { 60, 8, TUFB }, { 28, 28, TUFB },
        { 44, 58, TUFE }, { 12, 12, TUFB }, { 36, 22, TUFA },
    },
}

return {
    name = 'piso_grama',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        a = { ramp = 'moss', step = 3, h = 1 },  -- massa sálvia
        d = { ramp = 'moss', step = 2, h = 1 },  -- mancha de musgo fundo
        l = { ramp = 'moss', step = 4, h = 1 },  -- touceira clara rasteira
        e = { ramp = 'earth', step = 4, h = 1 }, -- terra seca aparecendo
        x = { ramp = 'moss', step = 1, h = 0 },  -- sombra na base da touceira
        u = { ramp = 'moss', step = 4, h = 3 },  -- lâmina média
        t = { ramp = 'moss', step = 5, h = 3 },  -- lâmina clara
        f = { spec = 'white', h = 3 },           -- pétala rara
        o = { ramp = 'gold', step = 6, h = 3 },  -- coração da flor
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { grama(V1), grama(V2), grama(V3), grama(V4) },
        },
    },
}
