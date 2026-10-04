-- BANCO_TERRACO — banco de contemplação, prop 64x96, pés.
-- Refúgio, terraço (vida-refugio-props §4): tábua de madeira sobre
-- pés de pedra, voltado "para fora" — visto por trás, o encosto
-- baixo fica entre a gente e o vale. Quem senta olha o mar, não a
-- rua. Relevo: encosto 9-12, assento 9-10, pés 5-7, chão 1.

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

-- camada de trás: assento + pés de pedra (o que fica "além")
local function assento()
    local g = nova('.')
    -- tábua: face de cima clara, veios, borda frontal escura
    for y = 44, 55 do
        for x = 14, 52 do
            local ch = 'w'
            if y < 46 then ch = 'W'
            elseif y > 52 then ch = 'v'
            elseif h2(x, y, 2) < 12 then ch = 'U' end      -- veio claro
            set(g, x, y, ch)
        end
    end
    -- pontas da tábua gastas
    set(g, 14, 44, 'u'); set(g, 15, 44, 'w'); set(g, 51, 44, 'w')
    set(g, 52, 44, 'u'); set(g, 52, 45, 'v')
    -- pés de pedra sob a tábua
    for _, px in ipairs({ 20, 40 }) do
        for y = 55, 88 do
            for x = px, px + 6 do
                local ch = 's'
                if x == px + 6 then ch = 'm'
                elseif y > 84 then ch = 'm'
                elseif h2(x, y, 4) < 10 then ch = 'a' end
                set(g, x, y, ch)
            end
        end
        set(g, px, 55, 'a'); set(g, px + 5, 55, 'a')       -- cap sob a tábua
    end
    return str(g)
end

-- camada da frente: encosto baixo entre quem olha e o assento
local function encosto()
    local g = nova('.')
    -- montantes do encosto sobem dos pés até a régua
    for _, px in ipairs({ 18, 45 }) do
        for y = 58, 88 do
            for x = px, px + 3 do
                set(g, x, y, x == px + 3 and 'v' or 'u')
            end
        end
    end
    -- régua do encosto: baixa, larga, fio claro gasto no topo
    for y = 58, 66 do
        for x = 16, 50 do
            local ch = 'w'
            if y == 58 then ch = 'W'
            elseif y == 59 and h2(x, y, 6) < 35 then ch = 'W' -- topo polido
            elseif y > 63 then ch = 'v'
            elseif h2(x, y, 8) < 10 then ch = 'U' end
            set(g, x, y, ch)
        end
    end
    set(g, 16, 58, 'u'); set(g, 50, 58, 'u')
    -- apoio dos pés por baixo da régua
    faixa(g, 20, 24, 90, 'm'); faixa(g, 42, 46, 90, 'm')
    return str(g)
end

local function chao()
    local g = nova('.')
    for y = 88, 96 do
        for x = 12, 54 do
            if h2(x, y, 5) < 30 then
                set(g, x, y, h2(x, y, 9) < 45 and 'e' or 'd')
            end
        end
    end
    -- grama rala no lugar de olhar o vale
    set(g, 16, 91, 'G'); set(g, 17, 90, 'g')
    set(g, 50, 92, 'G'); set(g, 49, 91, 'g')
    set(g, 30, 93, 'e')
    return str(g)
end

return {
    name = 'banco_terraco',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        w = {ramp = 'wood', step = 4, h = 10},  -- tábua/encosto
        W = {ramp = 'wood', step = 6, h = 12},  -- fio claro gasto
        U = {ramp = 'wood', step = 5, h = 10},  -- veio claro
        v = {ramp = 'wood', step = 2, h = 9},   -- borda de sombra
        u = {ramp = 'wood', step = 3, h = 7},   -- montante/ponta
        s = {ramp = 'stone', step = 4, h = 6},  -- pé de pedra
        a = {ramp = 'stone', step = 5, h = 7},  -- pedra clara
        m = {ramp = 'stone', step = 3, h = 5},  -- sombra da pedra
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
        g = {ramp = 'moss', step = 3, h = 2},
        G = {ramp = 'moss', step = 2, h = 1},
    },

    layers = {
        { name = 'assento', h = 9,  albedo = assento() },
        { name = 'encosto', h = 10, albedo = encosto() },
        { name = 'chao',    h = 1,  albedo = chao() },
    },
}
