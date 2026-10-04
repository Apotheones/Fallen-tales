-- MARCA_IMPRO — marca improvisada, prop 64x96, origem nos pés.
-- Adro/colina (vida-refugio-props §6 + DIRECAO §COLINA): a versão
-- barata do luto — estaca de madeira torta fincada no chão e um
-- retalho de pano preso sob uma pedra. Sem nome, sem placa:
-- alguém volta. Relevo: estaca 7-9, pedra 5-6, pano 2-3, chão 1-2.

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

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

local function marca()
    local g = nova('.')
    -- retalho de pano: debaixo da pedra, estende ondulado p/ a esquerda
    for x = 14, 34 do
        local onda = math.floor(math.sin((x - 14) * 0.5) * 1.5 + 0.5)
        for i = 0, 2 do
            local ch = 'c'
            if i == 0 and x % 4 == 0 then ch = 'C' end
            if x > 30 and i == 2 then ch = 'q' end   -- fica sob a pedra
            set(g, x, 82 + onda + i, ch)
        end
    end
    -- ponta desfiada do retalho
    set(g, 13, 83, 'q'); set(g, 12, 84, 'c'); set(g, 14, 86, 'q')
    -- pedra que prende o pano: bojo gasto, clara no topo-esq
    for y = 78, 88 do
        for x = 28, 42 do
            local dx = (x - 35) / 7.5
            local dy = (y - 83) / 5
            if dx * dx + dy * dy <= 1 then
                local ch = 'p'
                if x < 33 and y < 82 then ch = 'P'
                elseif x > 39 or y > 86 then ch = 's' end
                set(g, x, y, ch)
            end
        end
    end
    -- estaca torta: fincada torta, ponta talhada
    for y = 30, 88 do
        local t = (88 - y) / 58
        local cx = math.floor(34 + t * 7 + math.sin(y * 0.3) * 0.8 + 0.5)
        for i = 0, 2 do
            local ch = 'w'
            if i == 2 then ch = 'v'
            elseif h2(cx + i, y, 3) < 10 then ch = 'u' end
            set(g, cx + i, y, ch)
        end
    end
    -- ponta talhada: afunila e clareia
    faixa(g, 40, 42, 28, 'w'); set(g, 41, 26, 'W'); set(g, 41, 27, 'W')
    set(g, 42, 27, 'v'); set(g, 40, 29, 'v')
    -- nó de fibra prendendo um farelo do mesmo pano na estaca
    faixa(g, 37, 40, 44, 'r'); set(g, 38, 45, 'r')
    set(g, 37, 43, 'c'); set(g, 36, 44, 'c'); set(g, 36, 45, 'q')
    return str(g)
end

local function chao()
    local g = nova('.')
    for y = 86, 96 do
        for x = 10, 52 do
            if h2(x, y, 4) < 30 then
                set(g, x, y, h2(x, y, 8) < 45 and 'e' or 'd')
            end
        end
    end
    -- relva curta mantida: quem volta também corta o mato
    set(g, 24, 88, 'G'); set(g, 25, 87, 'g')
    set(g, 44, 90, 'G'); set(g, 46, 89, 'g')
    set(g, 18, 91, 'G'); set(g, 30, 94, 'e')
    -- uma flor miúda ao pé: o cuidado que não assina
    set(g, 22, 90, 'o'); set(g, 23, 91, 'g')
    return str(g)
end

return {
    name = 'marca_impro',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        w = {ramp = 'wood', step = 4, h = 8},   -- estaca
        W = {ramp = 'wood', step = 6, h = 9},   -- ponta talhada
        v = {ramp = 'wood', step = 2, h = 7},   -- sombra da estaca
        u = {ramp = 'wood', step = 3, h = 7},   -- veio
        r = {ramp = 'bone', step = 4, h = 8},   -- nó de fibra
        c = {ramp = 'clothWarm', step = 3, h = 3}, -- retalho
        C = {ramp = 'clothWarm', step = 4, h = 3}, -- dobra do retalho
        q = {ramp = 'clothWarm', step = 2, h = 2}, -- retalho, sombra
        p = {ramp = 'stone', step = 4, h = 5},  -- pedra
        P = {ramp = 'stone', step = 6, h = 6},  -- pedra, luz
        s = {ramp = 'stone', step = 3, h = 5},  -- pedra, sombra
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
        g = {ramp = 'moss', step = 3, h = 2},
        G = {ramp = 'moss', step = 2, h = 2},
        o = {ramp = 'gold', step = 6, h = 3},   -- flor miúda
    },

    layers = {
        { name = 'marca', h = 7, albedo = marca() },
        { name = 'chao',  h = 1, albedo = chao() },
    },
}
