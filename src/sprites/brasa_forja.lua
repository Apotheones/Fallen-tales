-- BRASA_FORJA — forja/braseiro de trabalho, prop 64x96, pés.
-- Quintal da forja (vida-refugio-props §5): A fonte do quintal —
-- leito de brasa aberto num forno de pedra baixo, emissivo FORTE
-- (ei .8-1) no leito, labaredas miúdas e fumacinha cinza de poucos
-- pixels (plaster, sem emissivo). Relevo: parede 10-11, leito 8-9,
-- labareda 11, fumaça 12, chão 1.

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

-- forno baixo: laterais que sobem, boca aberta com o leito
local function forno()
    local g = nova('.')
    -- corpo frontal de pedra
    for y = 62, 88 do
        for x = 10, 54 do
            local ch = 's'
            if (y % 6 == 5 or (x + math.floor(y / 6) * 4) % 9 == 0) then ch = 'm'
            elseif h2(x, y, 2) < 10 then ch = 't' end
            if y > 85 then ch = 'm' end
            set(g, x, y, ch)
        end
    end
    -- borda do topo do corpo
    faixa(g, 10, 54, 61, 'S'); faixa(g, 10, 54, 62, 't')
    -- muretas laterais do leito: sobem dos cantos
    for y = 48, 62 do
        for x = 10, 17 do
            set(g, x, y, y < 50 and 'S' or (h2(x, y, 3) < 12 and 't' or 's'))
        end
        for x = 47, 54 do
            set(g, x, y, y < 50 and 'S' or (h2(x, y, 3) < 12 and 't' or 's'))
        end
    end
    -- fundo da boca: parede de trás baixa, já tomada pela brasa
    for y = 52, 62 do
        for x = 18, 46 do
            set(g, x, y, h2(x, y, 4) < 20 and 'q' or 'm')
        end
    end
    -- junta de calor: pedra escurecida rente ao leito
    for x = 18, 46 do
        if h2(x, 9, 5) < 40 then set(g, x, 63, 'q') end
    end
    return str(g)
end

-- leito de brasa + labaredas miúdas (albedo; emissivo à parte)
local function leito()
    local g = nova('.')
    -- cama de brasa no vão: crosta escura furada de lume
    for y = 50, 63 do
        for x = 18, 46 do
            local n = h2(x * 2, y * 3, 7)
            local ch
            if n < 34 then ch = 'O'        -- lume vivo
            elseif n < 62 then ch = 'o'    -- brasa alta
            elseif n < 84 then ch = 'e'    -- brasa apagando
            else ch = 'q' end              -- crosta fria
            if y < 52 and n >= 34 then ch = 'e' end  -- topo mais calmo
            set(g, x, y, ch)
        end
    end
    -- labaredas miúdas nascendo do leito
    set(g, 26, 47, 'F'); set(g, 27, 46, 'f'); set(g, 25, 48, 'f')
    set(g, 36, 45, 'F'); set(g, 37, 44, 'f'); set(g, 35, 46, 'F')
    set(g, 38, 45, 'f')
    set(g, 30, 49, 'f'); set(g, 42, 48, 'f')
    return str(g)
end

-- emissivo: tudo que é brasa/labareda, ei .8-1
local function lume()
    local g = nova('.')
    for y = 50, 63 do
        for x = 18, 46 do
            local n = h2(x * 2, y * 3, 7)
            if n < 34 then set(g, x, y, 'O')
            elseif n < 62 then set(g, x, y, 'o')
            elseif n < 84 then set(g, x, y, 'e') end
        end
    end
    set(g, 26, 47, 'F'); set(g, 27, 46, 'f'); set(g, 25, 48, 'f')
    set(g, 36, 45, 'F'); set(g, 37, 44, 'f'); set(g, 35, 46, 'F')
    set(g, 38, 45, 'f')
    set(g, 30, 49, 'f'); set(g, 42, 48, 'f')
    return str(g)
end

-- fumacinha: poucos pixels de plaster subindo torto p/ a direita
local function fumaca()
    local g = nova('.')
    set(g, 37, 40, 'P'); set(g, 38, 39, 'p')
    set(g, 39, 36, 'p'); set(g, 41, 34, 'P')
    set(g, 40, 31, 'p'); set(g, 42, 29, 'p')
    set(g, 43, 26, 'P')
    return str(g)
end

local function chao()
    local g = nova('.')
    for y = 89, 96 do
        for x = 8, 58 do
            if h2(x, y, 3) < 30 then
                set(g, x, y, h2(x, y, 7) < 45 and 'a' or 'd')
            end
        end
    end
    -- cinza e escória ao redor do forno
    set(g, 14, 90, 'z'); set(g, 15, 91, 'z'); set(g, 47, 90, 'z')
    set(g, 30, 92, 'r'); set(g, 33, 91, 'r')
    set(g, 24, 93, 'a'); set(g, 52, 92, 'd')
    return str(g)
end

return {
    name = 'brasa_forja',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        -- pedra do forno
        S = {ramp = 'stone', step = 6, h = 11},
        s = {ramp = 'stone', step = 4, h = 10},
        t = {ramp = 'stone', step = 5, h = 10},
        m = {ramp = 'stone', step = 2, h = 9},
        q = {ramp = 'iron', step = 1, h = 8},   -- crosta fria/pedra queimada
        -- brasa: emissivo FORTE — a fonte do quintal
        e = {ramp = 'ember', step = 2, h = 8, e = 'ember.3', ei = 0.8},
        o = {ramp = 'ember', step = 4, h = 9, e = 'ember.5', ei = 0.9},
        O = {ramp = 'ember', step = 6, h = 9, e = 'ember.6', ei = 1},
        -- labaredas miúdas
        f = {ramp = 'ember', step = 4, h = 11, e = 'ember.5', ei = 1},
        F = {ramp = 'ember', step = 6, h = 11, e = 'ember.7', ei = 1},
        -- fumacinha: plaster frio, SEM emissivo
        p = {ramp = 'plaster', step = 2, h = 12},
        P = {ramp = 'plaster', step = 3, h = 12},
        -- chão: cinza, escória, terra queimada
        a = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
        z = {ramp = 'iron', step = 2, h = 1},   -- cinza assentada
        r = {ramp = 'rust', step = 2, h = 1},   -- escória
    },

    layers = {
        { name = 'forno',   h = 10, albedo = forno() },
        { name = 'leito',   h = 8,  albedo = leito(),
            emissive = lume() },
        { name = 'fumaca',  h = 12, albedo = fumaca() },
        { name = 'chao',    h = 1,  albedo = chao() },
    },
}
