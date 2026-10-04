-- VARAL_TERRACO — varal do terraço, prop 64x96, origem nos pés.
-- Refúgio, terraço (vida-refugio-props §4): diferente do varal da
-- rua — aqui pendem molhos de erva e um pano curto, não roupa de
-- corpo. Dois postes forçados, corda com barriga, peças em
-- comprimentos diferentes. Relevo: postes 8, corda/peças 8-9,
-- chão 1-2.

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

-- molho de erva pendurado pelo barbante
local MOLHO = {
    'mg...',
    'gmg..',
    'gmGg.',
    'gGGg.',
    'gGg..',
    '.G...',
}
local MOLHO_PQ = {
    'mg..',
    'gmg.',
    'gGg.',
    '.G..',
}

local function varal()
    local g = nova('.')
    -- postes: o esquerdo mais reto, o direito vergado pelo peso
    for y = 30, 90 do
        for i = 0, 2 do
            local ch = i == 2 and 'v' or 'w'
            if y % 10 == 6 then ch = 'u' end
            set(g, 11 + i, y, ch)
        end
    end
    for y = 34, 90 do
        local verga = y < 40 and 1 or 0
        for i = 0, 2 do
            set(g, 50 + i - verga, y, i == 2 and 'v' or 'w')
        end
    end
    -- forquilhas do topo
    set(g, 11, 29, 'W'); set(g, 12, 28, 'W'); set(g, 13, 29, 'w')
    set(g, 49, 32, 'W'); set(g, 50, 31, 'W'); set(g, 51, 32, 'w')
    -- pés
    faixa(g, 9, 16, 90, 'u'); faixa(g, 48, 55, 90, 'u')
    faixa(g, 10, 15, 91, 'u'); faixa(g, 49, 54, 91, 'u')
    -- corda com barriga: desce do poste esquerdo, sobe no direito
    for x = 14, 51 do
        local t = (x - 14) / 37
        local y = math.floor(30 + t * 3 + math.sin(t * math.pi) * 5 + 0.5)
        set(g, x, y, 'r')
    end
    -- pendurados na corda (y da corda + 1 pra baixo):
    -- molho esquerdo, longo
    carimbo(g, 19, 36, MOLHO)
    -- molho miúdo
    carimbo(g, 25, 38, MOLHO_PQ)
    -- pano curto no meio: dobra por cima da corda, cai torto
    for y = 37, 47 do
        for x = 31, 37 do
            local ch = 'p'
            if y == 37 then ch = 'P'                        -- dobra no varal
            elseif x == 37 then ch = 'r'
            elseif y > 45 and x > 34 then ch = 'P' end        -- bainha
            set(g, x, y, ch)
        end
    end
    set(g, 34, 48, 'p'); set(g, 35, 48, 'r')
    -- molho direito + trapos miúdo no fim
    carimbo(g, 43, 35, MOLHO)
    set(g, 48, 37, 'p'); set(g, 48, 38, 'r'); set(g, 49, 37, 'p')
    return str(g)
end

local function chao()
    local g = nova('.')
    for y = 90, 96 do
        for x = 6, 58 do
            if h2(x, y, 2) < 28 then
                set(g, x, y, h2(x, y, 4) < 45 and 'e' or 'd')
            end
        end
    end
    set(g, 20, 92, 'g'); set(g, 21, 93, 'G')   -- folha que caiu do molho
    set(g, 40, 93, 'G'); set(g, 12, 94, 'e')
    return str(g)
end

return {
    name = 'varal_terraco',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        w = {ramp = 'wood', step = 4, h = 8},   -- poste
        W = {ramp = 'wood', step = 6, h = 9},   -- forquilha clara
        v = {ramp = 'wood', step = 2, h = 8},   -- sombra
        u = {ramp = 'wood', step = 3, h = 7},   -- veio/pés
        r = {ramp = 'bone', step = 4, h = 9},   -- corda/barbante
        m = {ramp = 'moss', step = 4, h = 8},   -- erva, luz
        g = {ramp = 'moss', step = 3, h = 8},   -- erva
        G = {ramp = 'moss', step = 2, h = 7},   -- erva, ponta
        p = {ramp = 'bone', step = 4, h = 8},   -- pano curto
        P = {ramp = 'bone', step = 5, h = 8},   -- dobra/bainha clara
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        { name = 'varal', h = 8, albedo = varal() },
        { name = 'chao',  h = 1, albedo = chao() },
    },
}
