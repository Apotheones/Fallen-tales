-- FARDOS — cargas do depósito sob a rampa, prop 64x96, pés.
-- Refúgio, terraço (vida-refugio-props §4): carga esperando dono —
-- fardo de pano amarrado com cinta de fibra e caixa de tábua.
-- 2 frames = variantes de seed: f1 caixa+fardo, f2 dois fardos e a
-- caixa apertada atrás. Relevo: caixa 7-8, fardo 8-9, cinta 10,
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

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- caixa de tábua: moldura escura, tábuas verticais, cantos reforçados
local function caixa(g, x0, x1, y0, y1)
    for y = y0, y1 do
        for x = x0, x1 do
            local ch = 'w'
            if y == y0 then ch = 'W'                       -- fio do topo
            elseif x == x0 or x == x1 then ch = 'u'        -- cantos
            elseif y == y1 then ch = 'u'
            elseif (x - x0) % 5 == 4 then ch = 'v'         -- junta da tábua
            elseif h2(x, y, 3) < 8 then ch = 'U' end        -- veio claro
            set(g, x, y, ch)
        end
    end
    set(g, x0, y0, 'u'); set(g, x1, y0, 'u')
    -- pregos dos cantos
    set(g, x0 + 1, y0 + 1, 'i'); set(g, x1 - 1, y0 + 1, 'i')
    set(g, x0 + 1, y1 - 1, 'i'); set(g, x1 - 1, y1 - 1, 'i')
end

-- fardo de pano: bojo arredondado, dobra clara em cima, cinta cruzada
local function fardo(g, x0, x1, y0, y1)
    local cx = math.floor((x0 + x1) / 2)
    local cy = math.floor((y0 + y1) / 2)
    for y = y0, y1 do
        for x = x0, x1 do
            local canto = (x - x0 < 2 or x1 - x < 2)
                and (y - y0 < 2 or y1 - y < 2)
            if not canto then
                local ch = 'c'
                if y - y0 < 2 then ch = 'C'                    -- dobra clara
                elseif y1 - y < 2 then ch = 'q'                -- sombra
                elseif h2(x, y, 5) < 10 then ch = 'C' end       -- vinco
                set(g, x, y, ch)
            end
        end
    end
    -- cinta: vertical e horizontal cruzando no nó
    for y = y0, y1 do set(g, cx, y, 'r') end
    for x = x0 + 1, x1 - 1 do set(g, x, cy, 'r') end
    set(g, cx, cy, 'R')
    set(g, cx - 1, cy, 'R')                                    -- nó folgado
end

local function frame1()
    local g = nova('.')
    caixa(g, 10, 30, 56, 90)
    fardo(g, 32, 58, 62, 90)
    -- carga pequena em cima do fardo: trouxa miúda
    for y = 54, 62 do
        for x = 40, 52 do
            if not ((x < 42 or x > 50) and (y < 56 or y > 60)) then
                set(g, x, y, y < 57 and 'C' or 'c')
            end
        end
    end
    for y = 55, 62 do set(g, 46, y, 'r') end
    return str(g)
end

local function frame2()
    local g = nova('.')
    -- fardo grande à esquerda, caixa apertada atrás à direita
    caixa(g, 44, 62, 62, 90)
    fardo(g, 8, 44, 60, 90)
    -- segundo fardo em cima, tombado p/ a esquerda
    for y = 48, 60 do
        for x = 14, 40 do
            if not ((x < 16 or x > 38) and (y < 50 or y > 58)) then
                set(g, x, y, y < 51 and 'C' or 'c')
            end
        end
    end
    for y = 48, 60 do set(g, 26, y, 'r') end
    for x = 15, 39 do set(g, x, 55, 'r') end
    set(g, 26, 55, 'R')
    return str(g)
end

local function chao(seed)
    local g = nova('.')
    for y = 90, 96 do
        for x = 6, 60 do
            if h2(x, y, seed) < 30 then
                set(g, x, y, h2(x, y, seed * 3) < 40 and 'e' or 'd')
            end
        end
    end
    -- palha solta de quem arrastou a carga
    set(g, 33 + seed * 6, 91, 'f'); set(g, 35 + seed * 6, 92, 'f')
    set(g, 8, 93, 'e')
    return str(g)
end

return {
    name = 'fardos',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        w = {ramp = 'wood', step = 4, h = 7},   -- tábua da caixa
        W = {ramp = 'wood', step = 6, h = 8},   -- fio do topo
        U = {ramp = 'wood', step = 5, h = 7},   -- veio claro
        v = {ramp = 'wood', step = 2, h = 7},   -- junta
        u = {ramp = 'wood', step = 3, h = 7},   -- canto/moldura
        i = {ramp = 'iron', step = 3, h = 7},   -- prego
        c = {ramp = 'cloth', step = 3, h = 8},  -- pano do fardo
        C = {ramp = 'cloth', step = 4, h = 9},  -- dobra clara
        q = {ramp = 'cloth', step = 2, h = 7},  -- base em sombra
        r = {ramp = 'bone', step = 4, h = 10},  -- cinta de fibra
        R = {ramp = 'bone', step = 5, h = 10},  -- nó
        f = {ramp = 'gold', step = 5, h = 2},   -- palha solta
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        { name = 'carga', h = 7, albedo = { frame1(), frame2() } },
        { name = 'chao',  h = 1, albedo = { chao(1), chao(2) } },
    },
}
