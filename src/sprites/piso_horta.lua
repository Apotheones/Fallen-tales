-- PISO_HORTA — terra arada da horta, tile 64x64, origem topleft.
-- Refúgio, horta de várias mãos (vida-refugio-props §4): sulcos quase
-- paralelos com curva mole e juntas irregulares — o traço de quem ara
-- oscila, falha num trecho e retoma fora de fase, nunca listrado de
-- régua. Brotos esparsos nas cristas (moss) e trechos de rega escura
-- (earth.2 úmido). 4 frames = variantes de seed: posição dos sulcos,
-- densidade dos brotos e lugar da mancha de rega mudam.
-- h: fundo de sulco 0, massa/rega 1, crista/torrão/broto 2.

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
    x = math.floor(x + 0.5)
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

-- hash determinístico: variantes estáveis sem tocar math.random
local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- oscilação lenta do sulco: duas senoides baixas, amplitude ~2px
local function wob(x, k, seed)
    return math.floor(1.3 * math.sin(x * 0.31 + seed * 2.1 + k * 0.9)
        + 0.8 * math.sin(x * 0.11 + k * 1.7 + seed * 0.7) + 0.5)
end

-- brotos sentados na crista: última linha do carimbo alinha com 'b'
local BROTOS = {
    { 'g.' },
    { '.g' },
    { 'g.g' },
    { 'gm.', 'gGg' },
    { 'm.m', '.g.' },
    { 'gmg', 'G.G' },
}

-- mancha de rega: barro escuro e mole, borda irregular
local REGA = {
    '...rrrr....',
    '..rrrrrrr..',
    '.rrrrrrrrr.',
    'rrrrrrrrrr.',
    '.rrrrrrrr..',
    '..rrrrrr...',
    '....rrrr...',
}

local function horta(seed)
    local g = nova('a')
    -- sulcos: 5 bandas quase paralelas; centro e fase mudam por seed
    for k = 0, 4 do
        local cy = 9 + k * 11 + ((seed * 3 + k * 5) % 5) - 2
        for x = 1, W do
            local y = cy + wob(x, k, seed)
            -- junta irregular: o traço falha e retoma fora de fase
            local falha = math.sin(x * 0.43 + k * 2.7 + seed * 1.3) > 0.94
            if not falha then
                set(g, x, y - 1, 'b')
                set(g, x, y, 'd')
                set(g, x, y + 1, 'r')
                if (x + k * 2) % 9 < 5 then set(g, x, y + 2, 'd') end
            end
        end
    end
    -- torrões de terra revirada entre os sulcos (esparsos, 1-2px)
    for y = 2, H - 1 do
        for x = 2, W - 1 do
            local n = h2(x, y, seed)
            if n < 2 then set(g, x, y, 'd')
            elseif n == 4 then set(g, x, y, 't') end
        end
    end
    -- brotos sobre as cristas: espaçamento e porte variam por seed
    for k = 0, 4 do
        local cy = 9 + k * 11 + ((seed * 3 + k * 5) % 5) - 2
        local passo = 15 - seed * 2
        local x = 4 + (seed * 5 + k * 9) % passo
        while x < W - 4 do
            local y = cy + wob(x, k, seed) - 1
            local qual = 1 + (x + k * 3 + seed * 2) % (#BROTOS - 2)
            if seed >= 3 then
                -- canteiro mais velho: vale os brotos cheios também
                qual = 1 + (x + k) % #BROTOS
            end
            carimbo(g, x, y - #BROTOS[qual] + 1, BROTOS[qual])
            x = x + passo + h2(x, k, seed) % 6
        end
    end
    -- rega: mancha escura por cima do que encontrar
    carimbo(g, 8 + (seed * 17) % 40, 6 + (seed * 23) % 42, REGA)
    return str(g)
end

return {
    name = 'piso_horta',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        a = {ramp = 'earth', step = 4, h = 1}, -- massa do canteiro
        d = {ramp = 'earth', step = 3, h = 1}, -- encosta / torrão
        r = {ramp = 'earth', step = 2, h = 0}, -- fundo de sulco, rega
        b = {ramp = 'earth', step = 5, h = 2}, -- crista iluminada
        t = {ramp = 'earth', step = 6, h = 2}, -- torrão seco claro
        g = {ramp = 'moss', step = 3, h = 2},  -- broto
        G = {ramp = 'moss', step = 2, h = 2},  -- broto, sombra
        m = {ramp = 'moss', step = 4, h = 2},  -- broto crescido
    },

    layers = {
        {
            name = 'horta',
            h = 1,
            albedo = { horta(1), horta(2), horta(3), horta(4) },
        },
    },
}
