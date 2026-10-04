-- RACK_ERVAS — ervas secando, prop de chão, 64x96, origem nos pés.
-- Refúgio, terraço (vida-refugio-props §4): armação simples de
-- madeira com molhos pendurados por barbante — volumes pequenos,
-- verdes de horta e tanos de erva já seca. Trabalho ao redor da
-- contemplação. Relevo: barra 9-10, postes 8, molhos 7-8, chão 1-2.

local W, H = 64, 96

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

local function faixa(g, x0, x1, y, ch)
    for x = x0, x1 do set(g, x, y, ch) end
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

-- molho verde de horta: atado em cima, bojo no meio, ponta escura
local MOLHO = {
    'r....',
    'r....',
    'mg...',
    'gmg..',
    'gmGg.',
    'gmGGg',
    'gGGg.',
    'gGg..',
    '.G...',
}
-- molho já seco: mais curto, tan de terra
local MOLHO_SECO = {
    'r...',
    'r...',
    'Dd..',
    'dDd.',
    'dDDd',
    'ddD.',
    '.d..',
}
-- molho misto com florzinha presa
local MOLHO_FLOR = {
    'r....',
    'r....',
    'mg...',
    'gmf..',
    'gmGg.',
    'gGGg.',
    'gGg..',
    '.G...',
}

local function rack()
    local g = nova('.')
    -- postes: levemente abertos na base, veios escuros
    for y = 26, 88 do
        local abre = y > 78 and 1 or 0
        for i = 0, 2 do
            local ch = i == 2 and 'v' or 'w'
            if y % 11 == 5 then ch = 'u' end
            set(g, 12 + i - abre, y, ch)
            set(g, 49 + i + abre, y, ch)
        end
    end
    -- pés no chão
    faixa(g, 10, 16, 89, 'u'); faixa(g, 9, 17, 90, 'u')
    faixa(g, 48, 54, 89, 'u'); faixa(g, 47, 55, 90, 'u')
    -- barra do topo com fio claro
    faixa(g, 10, 54, 24, 'W')
    faixa(g, 10, 54, 25, 'w')
    faixa(g, 11, 53, 26, 'w')
    set(g, 10, 26, 'v'); set(g, 53, 26, 'v')
    -- molhos pendurados: alturas e portes diferentes
    carimbo(g, 19, 26, MOLHO)
    carimbo(g, 27, 26, MOLHO_SECO)
    carimbo(g, 34, 26, MOLHO)
    carimbo(g, 42, 26, MOLHO_FLOR)
    -- um molho quase no chão, mais comprido que os outros
    carimbo(g, 23, 26, { 'r', 'r', 'r', 'r', 'mg', 'gmg', 'gmGg',
        'gmGGg', 'gGGg', 'gGg', '.G.' })
    return str(g)
end

local function chao()
    local g = nova('.')
    -- terra sob a armação, folhas caídas e uma pedra
    for y = 89, 96 do
        for x = 8, 56 do
            if h2(x, y, 3) < 26 then set(g, x, y, h2(x, y, 7) < 40 and 'e' or 'd') end
        end
    end
    set(g, 20, 91, 'D'); set(g, 37, 92, 'D')     -- folha seca caída
    set(g, 44, 93, 'q'); set(g, 45, 93, 'q')
    set(g, 30, 94, 'e'); set(g, 50, 91, 'e')
    return str(g)
end

return {
    name = 'rack_ervas',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        w = {ramp = 'wood', step = 4, h = 8},   -- postes/barra
        W = {ramp = 'wood', step = 6, h = 10},  -- fio claro da barra
        v = {ramp = 'wood', step = 2, h = 8},   -- lado de sombra
        u = {ramp = 'wood', step = 3, h = 7},   -- pés
        r = {ramp = 'bone', step = 4, h = 9},   -- barbante
        m = {ramp = 'moss', step = 4, h = 8},   -- erva, luz
        g = {ramp = 'moss', step = 3, h = 8},   -- erva
        G = {ramp = 'moss', step = 2, h = 7},   -- erva, ponta/sombra
        d = {ramp = 'earth', step = 4, h = 8},  -- erva seca
        D = {ramp = 'earth', step = 5, h = 8},  -- erva seca, luz
        f = {ramp = 'gold', step = 6, h = 8},   -- florzinha presa
        q = {ramp = 'stone', step = 3, h = 2},  -- pedra no chão
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        { name = 'rack', h = 8, albedo = rack() },
        { name = 'chao', h = 1, albedo = chao() },
    },
}
