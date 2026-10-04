-- OFERENDA — oferenda sem nome, tile 64x64, origem topleft.
-- Adro da capela (vida-refugio-props §6): "luto sem placa" — um
-- pacote de pano amarrado, uma flor deitada e uma pedra lisa, deixados
-- no chão ao pé da capela. 2 frames = estados por flag:
-- f1 presente / f2 levado (a pedra fica; resta a marca escura e uma
-- pétala). h: chão 1, flor 3, pano/pedra 4-5.

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

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- fardo de pano com cinta de fibra cruzada e nó
local PACOTE = {
    '..ccccc...',
    '.cCCCccC..',
    'ccrrrrrcc.',
    '.cCCrCCc..',
    '..ccrcc...',
    '...cRrc...',
    '....r.....',
}
-- flor deitada: corola + haste
local FLOR = {
    'og....',
    'gg....',
    '.oo...',
    '.o....',
}
-- pedra lisa, clara no topo-esquerdo
local PEDRA = {
    '.ppp..',
    'pPPpp.',
    'ppppp.',
    '.qqq..',
}
-- o que fica quando levam: a mancha onde o pano estava
local MANCHA = {
    '.dddd...',
    'dddddd..',
    '.ddddd..',
    '..ddd...',
}

local function oferenda(presente)
    local g = nova('e')
    -- chão do adro: terra com musgo ralo e torrões
    for y = 1, H do
        for x = 1, W do
            local n = h2(x, y, 3)
            if n < 3 then g[y][x] = 'd'
            elseif n < 6 then g[y][x] = 'G'
            elseif n == 9 then g[y][x] = 'g' end
        end
    end
    if presente then
        carimbo(g, 22, 28, PACOTE)
        carimbo(g, 18, 32, FLOR)
        carimbo(g, 38, 30, PEDRA)
        set(g, 21, 36, 'o') -- pétala solta
    else
        carimbo(g, 22, 29, MANCHA)
        carimbo(g, 38, 30, PEDRA)
        set(g, 20, 34, 'o') -- a pétala que ninguém juntou
        set(g, 19, 35, 'g')
    end
    return str(g)
end

return {
    name = 'oferenda',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        e = {ramp = 'earth', step = 4, h = 1}, -- chão do adro
        d = {ramp = 'earth', step = 3, h = 1}, -- mancha/torrão
        g = {ramp = 'moss', step = 3, h = 2},  -- haste/musgo
        G = {ramp = 'moss', step = 2, h = 2},  -- musgo ralo
        c = {ramp = 'cloth', step = 3, h = 4}, -- pano do fardo
        C = {ramp = 'cloth', step = 4, h = 5}, -- dobra clara
        r = {ramp = 'bone', step = 4, h = 5},  -- cinta de fibra
        R = {ramp = 'bone', step = 5, h = 5},  -- nó da cinta
        p = {ramp = 'stone', step = 4, h = 4}, -- pedra lisa
        P = {ramp = 'stone', step = 6, h = 5}, -- topo da pedra
        q = {ramp = 'stone', step = 3, h = 3}, -- sombra da pedra
        o = {ramp = 'gold', step = 6, h = 3},  -- flor/pétala de ouro
    },

    layers = {
        {
            name = 'oferenda',
            h = 1,
            albedo = { oferenda(true), oferenda(false) },
        },
    },
}
