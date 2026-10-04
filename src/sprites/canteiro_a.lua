-- CANTEIRO_A — canteiro alinhado, tile 64x64, origem topleft.
-- Refúgio, horta de várias mãos (vida-refugio-props §4): a mão
-- organizada — borda de pedra reta, fileiras de mudas no compasso.
-- 2 frames = variantes: f2 tem fileiras em outro estágio e um trecho
-- da borda refeito em tábua (remendo reconhecível, trabalho novo
-- sobre o velho). Margem transparente assenta sobre o piso.
-- h: solo 1, pedra 3-5, muda 3.

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

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

local function canteiro(seed)
    local g = nova('.')
    local x0, x1, y0, y1 = 8, 56, 12, 52
    -- anel de pedra: cap claro em cima, frente em sombra embaixo
    for x = x0, x1 do
        set(g, x, y0, 'S'); set(g, x, y0 + 1, 's')
        set(g, x, y1 - 1, 's'); set(g, x, y1, 'm')
    end
    for y = y0, y1 do
        set(g, x0, y, 's'); set(g, x0 + 1, y, 's')
        set(g, x1 - 1, y, 's'); set(g, x1, y, 's')
    end
    set(g, x0, y0, 'C'); set(g, x1, y0, 'C')
    set(g, x0, y1, 'm'); set(g, x1, y1, 'm')
    -- solo remexido
    for y = y0 + 2, y1 - 2 do
        for x = x0 + 2, x1 - 2 do
            local n = h2(x, y, seed)
            g[y][x] = n < 5 and 'd' or (n == 9 and 't' or 'e')
        end
    end
    -- fileiras retas: mesmos x, mesmo compasso — a mão organizada
    local linhas = seed == 1 and { 21, 31, 41 } or { 23, 33, 43 }
    for _, ry in ipairs(linhas) do
        for x = x0 + 3, x1 - 3 do set(g, x, ry + 3, 'd') end
        local x = 15
        while x <= x1 - 4 do
            -- muda que não vingou deixa falha na fileira
            local falta = h2(x, ry, seed * 7) < (seed == 1 and 8 or 16)
            if not falta then
                set(g, x, ry - 1, (x + ry) % 12 < 6 and 'm' or 'g')
                set(g, x, ry, 'g'); set(g, x + 1, ry, 'g')
                set(g, x, ry + 1, 'G'); set(g, x + 1, ry + 1, 'g')
                set(g, x, ry + 2, 'G')
            end
            x = x + 6
        end
    end
    if seed == 2 then
        -- remendo: trecho da borda de cima refeito em tábua
        for x = 18, 38 do
            set(g, x, y0, 'w'); set(g, x, y0 + 1, 'v')
        end
        set(g, 18, y0, 'W'); set(g, 38, y0, 'W')
        -- pedra solta do canto, caida para dentro
        set(g, x1 - 2, y1 - 2, 'q'); set(g, x1 - 3, y1 - 2, 'q')
        set(g, x1 - 2, y1 - 3, 'q')
    else
        -- musgo tomando o canto de sombra
        set(g, x0 + 2, y1 - 3, 'G'); set(g, x0 + 3, y1 - 2, 'G')
        set(g, x0 + 2, y1 - 2, 'g')
    end
    return str(g)
end

return {
    name = 'canteiro_a',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        C = {ramp = 'stone', step = 7, h = 5}, -- canto do cap
        S = {ramp = 'stone', step = 6, h = 4}, -- cap iluminado
        s = {ramp = 'stone', step = 4, h = 4}, -- pedra da borda
        m = {ramp = 'stone', step = 3, h = 3}, -- frente em sombra
        q = {ramp = 'stone', step = 3, h = 3}, -- pedra solta
        w = {ramp = 'wood', step = 5, h = 4},  -- tábua do remendo
        v = {ramp = 'wood', step = 3, h = 4},
        W = {ramp = 'wood', step = 6, h = 5},
        e = {ramp = 'earth', step = 3, h = 1}, -- solo
        d = {ramp = 'earth', step = 2, h = 1}, -- torrão/sulco raso
        t = {ramp = 'earth', step = 5, h = 1}, -- torrão seco
        g = {ramp = 'moss', step = 3, h = 3},  -- muda
        G = {ramp = 'moss', step = 2, h = 3},  -- muda, sombra
        m = {ramp = 'moss', step = 4, h = 3},  -- muda crescida
    },

    layers = {
        {
            name = 'canteiro',
            h = 1,
            albedo = { canteiro(1), canteiro(2) },
        },
    },
}
