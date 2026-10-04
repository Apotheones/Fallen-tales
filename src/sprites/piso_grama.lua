-- PISO_GRAMA — gramado sálvia do Refúgio, tile 64x64, origem topleft.
-- 4 frames = variantes de seed. Massa de musgo/verde seco em manchas
-- grandes, touceiras verticais de lâminas claras (clusters 3-4 px com
-- sombra na base) e flor ocasional rara. h: sombra de touceira 0,
-- massa 1, lâmina 3.

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

-- Massas grandes: musgo fundo ('d'), touceira rasteira clara ('l'),
-- terra seca aparecendo ('e'). Bordas moles, 10-16 px.
local MASSA_D1 = {
    '...ddddd....',
    '..dddddddd..',
    '.dddddddddd.',
    'ddddddddddd.',
    '.ddddddddd..',
    '..ddddddd...',
}
local MASSA_D2 = {
    '..ddddd...',
    '.ddddddd..',
    'ddddddddd.',
    'dddddddd..',
    '.dddddd...',
    '..ddd.....',
}
local MASSA_L1 = {
    '...lllll....',
    '..lllllll...',
    '.lllllllll..',
    'lllllllll...',
    '.llllllll...',
    '..llllll....',
}
local MASSA_L2 = {
    '..lllll..',
    '.lllllll.',
    'llllllll.',
    'lllllll..',
    '.lllll...',
}
local MASSA_E1 = {
    '...eeee...',
    '..eeeeee..',
    '.eeeeeee..',
    'eeeeeee...',
    '.eeeee....',
}
local MASSA_E2 = {
    '..eee..',
    '.eeeee.',
    'eeeeee.',
    '.eeee..',
}

-- Touceiras: lâminas 't' (claras) e 'u' (médias) de pé numa sombra 'x'
-- curta — verticais de 3-4 px, desenhadas como moitas, não confete.
local TUFA = {
    't..t',
    'tu.t',
    'tutt',
    '.xx.',
}
local TUFB = {
    '.t.t.',
    'tuttt',
    'uttu.',
    'xx...',
}
local TUFC = { -- touceira alta e densa
    't.t.t',
    'ttutt',
    'tuttt',
    'xxxxx',
}
local TUFD = {
    't.t',
    'tut',
    'xux',
}
local TUFE = { -- moita dupla
    't...t.',
    'tt.tt.',
    'tuttu.',
    'xxxx..',
}
local TUFG = { -- broto jovem, 2 px
    'u.u',
    'xux',
}
-- Flor rara: corola clara 'f' com coração 'o' sobre haste.
local FLOR = {
    '.f.f.',
    'fof..',
    '.tt..',
    '.x...',
}
local FLOR2 = {
    'f.f',
    'fof',
    '.t.',
    '.x.',
}

local function grama(spec)
    local g = nova('a')
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

local V1 = {
    carimbos = {
        { 8, 10, MASSA_D1 }, { 42, 6, MASSA_L1 }, { 50, 30, MASSA_D2 },
        { 16, 42, MASSA_L2 }, { 34, 52, MASSA_D1 }, { 4, 50, MASSA_E1 },
        { 24, 24, MASSA_L2 }, { 46, 52, MASSA_E2 },
        { 14, 18, TUFA }, { 30, 12, TUFC }, { 56, 20, TUFB },
        { 44, 30, TUFD }, { 8, 34, TUFE }, { 26, 46, TUFA },
        { 52, 44, TUFC }, { 38, 58, TUFB }, { 14, 58, TUFD },
        { 60, 8, TUFA }, { 34, 34, TUFB }, { 20, 30, TUFG },
        { 58, 56, FLOR }, { 47, 16, TUFG },
    },
}

local V2 = {
    carimbos = {
        { 44, 12, MASSA_D2 }, { 6, 6, MASSA_L1 }, { 22, 34, MASSA_D1 },
        { 48, 44, MASSA_L1 }, { 14, 52, MASSA_D2 }, { 34, 6, MASSA_E1 },
        { 54, 30, MASSA_L2 }, { 4, 40, MASSA_E2 },
        { 28, 14, TUFA }, { 50, 8, TUFD }, { 12, 24, TUFC },
        { 38, 22, TUFB }, { 58, 50, TUFE }, { 30, 46, TUFD },
        { 44, 38, TUFA }, { 8, 56, TUFA }, { 60, 20, TUFC },
        { 20, 44, TUFB }, { 42, 56, TUFA }, { 16, 32, TUFB },
        { 52, 58, TUFG }, { 28, 28, TUFG },
    },
}

local V3 = {
    carimbos = {
        { 28, 8, MASSA_D1 }, { 6, 28, MASSA_L1 }, { 46, 22, MASSA_D2 },
        { 16, 46, MASSA_L2 }, { 54, 48, MASSA_D1 }, { 38, 42, MASSA_E1 },
        { 56, 8, MASSA_L2 }, { 24, 56, MASSA_E2 },
        { 14, 12, TUFD }, { 36, 4, TUFA }, { 54, 34, TUFC },
        { 20, 28, TUFE }, { 6, 44, TUFA }, { 44, 54, TUFC },
        { 30, 36, TUFB }, { 58, 20, TUFB }, { 12, 58, TUFD },
        { 48, 12, TUFA }, { 40, 28, TUFD }, { 8, 16, TUFG },
        { 26, 10, FLOR2 }, { 58, 58, TUFG },
    },
}

local V4 = {
    carimbos = {
        { 14, 6, MASSA_L1 }, { 46, 10, MASSA_D1 }, { 4, 42, MASSA_D2 },
        { 34, 32, MASSA_L1 }, { 52, 52, MASSA_E1 }, { 26, 54, MASSA_D1 },
        { 8, 22, MASSA_E2 }, { 56, 30, MASSA_L2 },
        { 42, 6, TUFC }, { 24, 16, TUFA }, { 56, 22, TUFE },
        { 8, 56, TUFD }, { 34, 44, TUFA }, { 48, 40, TUFD },
        { 18, 36, TUFC }, { 60, 8, TUFB }, { 28, 26, TUFB },
        { 44, 58, TUFE }, { 12, 12, TUFB }, { 36, 20, TUFA },
        { 52, 36, TUFG }, { 22, 50, TUFG },
    },
}

return {
    name = 'piso_grama',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        a = { ramp = 'moss', step = 3, h = 1 },  -- massa sálvia
        d = { ramp = 'moss', step = 2, h = 1 },  -- mancha de musgo fundo
        l = { ramp = 'moss', step = 4, h = 1 },  -- touceira rasteira clara
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
