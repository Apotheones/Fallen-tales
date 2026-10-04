-- CANTEIRO_B — canteiro curvo, tile 64x64, origem topleft.
-- Refúgio, horta de várias mãos (vida-refugio-props §4): a mão solta —
-- borda irregular de pedra, fileiras que curvam com o terreno, mudas
-- misturadas com flores espontâneas. "Ninguém refaz o traço do outro":
-- o canteiro B nunca repete a geometria do A. 2 frames = variantes.
-- h: solo 1, pedra 3-5, muda/flor 3.

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
    y = math.floor(y + 0.5)
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
    local cx, cy = 32 + (seed % 2) * 2 - 1, 33 + (seed * 3) % 5 - 2
    -- borda irregular: raio ondulado, nunca fecha certinho
    local function raio(th)
        return 21 + 3.5 * math.sin(3 * th + seed * 1.3)
            + 2 * math.sin(5 * th + seed * 2.7)
    end
    for th = 0, math.pi * 2, 0.02 do
        local r = raio(th)
        set(g, cx + r * math.cos(th), cy + r * 0.78 * math.sin(th), 's')
        set(g, cx + (r - 1) * math.cos(th), cy + (r - 1) * 0.78 * math.sin(th), 's')
    end
    -- preenche o solo entre as bordas de cada linha
    for y = 1, H do
        local lo, hi
        for x = 1, W do
            if g[y][x] == 's' then
                lo = lo or x; hi = x
            end
        end
        if lo and hi > lo then
            for x = lo + 1, hi - 1 do
                if g[y][x] == '.' then g[y][x] = 'e' end
            end
        end
    end
    -- cap claro no topo de cada coluna de borda, sombra embaixo
    for x = 1, W do
        local topo, base
        for y = 1, H do
            if g[y][x] == 's' then
                topo = topo or y; base = y
            end
        end
        if topo then
            g[topo][x] = 'S'
            if base > topo then g[base][x] = 'm' end
        end
    end
    -- torrões no solo
    for y = 1, H do
        for x = 1, W do
            if g[y][x] == 'e' then
                local n = h2(x, y, seed)
                if n < 4 then g[y][x] = 'd'
                elseif n == 9 then g[y][x] = 't' end
            end
        end
    end
    -- fileiras curvas: arcos concêntricos à borda — a mão segue o traço
    -- que já existia, não a régua
    local aneis = seed == 1 and { 0.72, 0.45 } or { 0.78, 0.55, 0.32 }
    for ai, f in ipairs(aneis) do
        for th = 0.25, math.pi * 2 - 0.25, 0.045 do
            local r = raio(th) * f
            local x = math.floor(cx + r * math.cos(th) + 0.5)
            local y = math.floor(cy + r * 0.78 * math.sin(th) + 0.5)
            if g[y] and g[y][x] == 'e' then g[y][x] = 'd' end
        end
        -- mudas e flores misturadas ao longo do arco, com furos e
        -- voluntárias fora da linha
        local th = 0.4 + f
        while th < math.pi * 2 - 0.4 do
            local r = raio(th) * f - 1
            local x = math.floor(cx + r * math.cos(th) + 0.5)
            local y = math.floor(cy + r * 0.78 * math.sin(th) + 0.5)
            local n = h2(x, y, seed * 11 + ai)
            if g[y] and (g[y][x] == 'e' or g[y][x] == 'd' or g[y][x] == 't') then
                local ch
                if n < 52 then ch = 'g'
                elseif n < 70 then ch = 'l'
                elseif n < 78 then ch = 'G'
                elseif n < 87 then ch = 'f'   -- flor branca espontânea
                elseif n < 94 then ch = 'o'   -- flor de ouro
                else ch = 'i' end             -- flor violeta
                g[y][x] = ch
                -- muda par: duas folhas juntas leem melhor que pontos
                if n % 3 == 0 and g[y + 1] and g[y + 1][x] == 'd' then
                    g[y + 1][x] = 'G'
                end
                if n % 4 == 0 and g[y][x + 1]
                    and (g[y][x + 1] == 'e' or g[y][x + 1] == 'd') then
                    g[y][x + 1] = 'g'
                end
            end
            th = th + 0.12 + (n % 5) * 0.03
        end
    end
    -- pedras miúdas na borda, algumas fora de lugar
    for x = 1, W do
        for y = 1, H do
            if g[y][x] == 's' and h2(x, y, seed * 5) < 8 then
                g[y][x] = 'q'
            end
        end
    end
    return str(g)
end

return {
    name = 'canteiro_b',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        S = {ramp = 'stone', step = 6, h = 4}, -- cap iluminado
        s = {ramp = 'stone', step = 4, h = 4}, -- pedra da borda
        m = {ramp = 'stone', step = 3, h = 3}, -- base em sombra
        q = {ramp = 'stone', step = 3, h = 3}, -- pedra miúda
        e = {ramp = 'earth', step = 3, h = 1}, -- solo
        d = {ramp = 'earth', step = 2, h = 1}, -- sulco curvo
        t = {ramp = 'earth', step = 5, h = 1}, -- torrão seco
        g = {ramp = 'moss', step = 3, h = 3},  -- muda
        G = {ramp = 'moss', step = 2, h = 3},  -- muda, sombra
        l = {ramp = 'moss', step = 4, h = 3},  -- muda crescida
        f = {ramp = 'bone', step = 6, h = 3},  -- flor branca (lê white)
        o = {ramp = 'gold', step = 6, h = 3},  -- flor de ouro
        i = {ramp = 'violet', step = 6, h = 3},-- flor violeta
    },

    layers = {
        {
            name = 'canteiro',
            h = 1,
            albedo = { canteiro(1), canteiro(2) },
        },
    },
}
