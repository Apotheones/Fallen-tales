-- COVA — marca de sepultura rasa, 64x96, origem topleft.
-- Colina dos Sepultados (docs/DIRECAO_AMBIENTAL_HD.md §COLINA): retângulo
-- mole de terra remexida (earth escuro) com fileira de pedrinhas em
-- volta — a geometria do monte é o que diz "aqui tem alguém". 2 frames:
-- f1 terra assentada; f2 terra afofada (mais clara) com flor de osso —
-- "alguém volta para cuidar". h: pedrinha 2, monte 1-2, chão 0-1.

local W, H = 64, 96

local function nova()
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = '.' end
        g[y] = r
    end
    return g
end

local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end

local function get(g, x, y)
    if x >= 1 and x <= W and y >= 1 and y <= H then return g[y][x] end
    return '.'
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function hash(x, y) return (x * 31 + y * 17) % 13 end

-- Monte de sepultura: cápsula vertical de terra remexida — torrões
-- escuros por baixo, torrões claros no topo, pedrinhas na crista da
-- borda. flor = acrescenta o cuidado (haste + botão de osso).
local function cova(flor)
    local g = nova()
    local cx, cy, rx, ry = 32, 60, 16, 22
    for y = 1, H do
        for x = 1, W do
            local dx, dy = (x - cx) / rx, (y - cy) / ry
            local d = dx * dx + dy * dy
            local hz = hash(x, y)
            if d <= 1 then
                -- torrões: manchas de valor dentro do monte
                local ch = 'e'
                if hz <= 2 then ch = 'v' end
                if dy < -0.2 and hz >= 10 then ch = 'u' end
                if dy >= 0.3 and hz >= 11 then ch = 'v' end
                set(g, x, y, ch)
            elseif d <= 1.3 and d > 1.0 then
                -- fileira de pedrinhas na crista da borda
                if hz <= 5 then
                    set(g, x, y, (hz % 3 == 0) and 'p' or 'q')
                end
            end
        end
    end
    -- capim apagado raro dentro do monte velho
    for y = 1, H do
        for x = 1, W do
            if get(g, x, y) == 'e' and hash(x + 5, y * 3) == 0
                    and get(g, x, y - 1) == '.' then
                set(g, x, y - 1, 'g')
            end
        end
    end
    if flor then
        -- terra afofada: clareia o miolo do monte
        for y = 1, H do
            for x = 1, W do
                if get(g, x, y) == 'e' and hash(x, y) >= 6 then
                    set(g, x, y, 'u')
                end
            end
        end
        -- flor pequena na cabeceira do monte
        set(g, 32, 44, 't')
        set(g, 32, 45, 't')
        set(g, 33, 45, 't')
        set(g, 32, 43, 'f')
        set(g, 31, 42, 'f')
        set(g, 33, 42, 'f')
        set(g, 32, 41, 'f')
        set(g, 31, 43, 'F')
        set(g, 33, 43, 'F')
    end
    return str(g)
end

return {
    name = 'cova',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        e = {ramp = 'earth', step = 3, h = 1}, -- terra remexida
        v = {ramp = 'earth', step = 2, h = 1}, -- torrão em sombra
        u = {ramp = 'earth', step = 4, h = 2}, -- torrão claro / afofada
        p = {ramp = 'stone', step = 4, h = 2}, -- pedrinha clara
        q = {ramp = 'stone', step = 2, h = 2}, -- pedrinha em sombra
        g = {ramp = 'moss', step = 2, h = 1},  -- capim apagado
        t = {ramp = 'moss', step = 3, h = 2},  -- haste da flor
        f = {ramp = 'bone', step = 5, h = 3},  -- pétala de osso
        F = {ramp = 'bone', step = 4, h = 3},  -- pétala em sombra
    },

    layers = {
        {
            name = 'cova',
            h = 1,
            albedo = { cova(false), cova(true) },
        },
    },
}
