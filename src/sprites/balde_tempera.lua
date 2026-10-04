-- BALDE_TEMPERA — balde de têmpera, prop 64x64, origem nos pés.
-- Quintal da forja (vida-refugio-props §5): água escurecida pelo
-- uso — sea profundo com reflexos miúdos, vapor sutil subindo.
-- Balde de aduelas com cintas de ferro. Relevo: água 6, corpo 7,
-- boca/cinta 8-9, vapor 10, chão 1.

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

local function balde()
    local g = nova('.')
    -- alça arriada: descansa na borda, torta p/ a esquerda
    set(g, 22, 31, 'i'); set(g, 23, 30, 'i'); set(g, 24, 30, 'i')
    set(g, 25, 31, 'i'); set(g, 26, 31, 'i')
    -- boca do balde: aro claro e a água escurecida dentro
    for y = 32, 38 do
        for x = 20, 44 do
            local dx = (x - 32) / 12
            local dy = (y - 35) / 3.5
            if dx * dx + dy * dy <= 1 then
                set(g, x, y, 'k')               -- sombra interna
            end
        end
    end
    for y = 33, 37 do
        for x = 22, 42 do
            local dx = (x - 32) / 10
            local dy = (y - 35) / 2.8
            if dx * dx + dy * dy <= 1 then
                local ch = 'z'
                if h2(x, y, 3) < 14 then ch = 'Z' end   -- reflexo miúdo
                set(g, x, y, ch)
            end
        end
    end
    -- aro do balde sobre a boca
    faixa(g, 20, 44, 31, 'I'); faixa(g, 19, 45, 32, 'i')
    set(g, 19, 33, 'i'); set(g, 45, 33, 'i')
    -- corpo: aduelas de madeira, afinando à base
    for y = 36, 56 do
        local afun = math.floor((y - 36) / 10)
        for x = 20 + afun, 44 - afun do
            local ch = 'u'
            if x <= 22 then ch = 'U'
            elseif x >= 42 then ch = 'v'
            elseif (x - 20) % 5 == 4 then ch = 'v'        -- junta da aduela
            elseif h2(x, y, 5) < 8 then ch = 'U' end
            set(g, x, y, ch)
        end
    end
    -- cintas de ferro
    faixa(g, 20, 44, 41, 'i'); faixa(g, 21, 43, 42, 'i')
    faixa(g, 21, 43, 51, 'i'); faixa(g, 22, 42, 52, 'i')
    -- fundo e sombra de contato
    faixa(g, 23, 41, 57, 'v'); faixa(g, 24, 40, 58, 'k')
    -- vapor sutil: três fios tortos
    set(g, 28, 29, 'p'); set(g, 29, 28, 'p'); set(g, 28, 26, 'p')
    set(g, 34, 30, 'p'); set(g, 35, 28, 'P'); set(g, 34, 27, 'p')
    set(g, 39, 29, 'p')
    -- chão: mancha úmida ao redor da base
    for y = 58, 63 do
        for x = 16, 48 do
            local dx = (x - 32) / 16
            local dy = (y - 60) / 3
            if dx * dx + dy * dy <= 1 then
                set(g, x, y, h2(x, y, 7) < 40 and 'e' or 'd')
            end
        end
    end
    set(g, 27, 59, 'd'); set(g, 36, 60, 'e')
    return str(g)
end

return {
    name = 'balde_tempera',
    w = 64, h = 64,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 6},              -- sombra interna/contato
        u = {ramp = 'wood', step = 4, h = 7},   -- aduela
        U = {ramp = 'wood', step = 6, h = 7},   -- aduela, luz
        v = {ramp = 'wood', step = 2, h = 7},   -- junta/sombra
        i = {ramp = 'iron', step = 3, h = 8},   -- cinta/alça
        I = {ramp = 'iron', step = 5, h = 9},   -- aro claro
        z = {ramp = 'sea', step = 2, h = 6},    -- água escurecida
        Z = {ramp = 'sea', step = 3, h = 6},    -- reflexo na água
        p = {ramp = 'plaster', step = 2, h = 10}, -- vapor
        P = {ramp = 'plaster', step = 3, h = 10},
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        { name = 'balde', h = 7, albedo = balde() },
    },
}
