-- FOGAO a lenha — prop de chão, 64x96, origem nos pés.
-- Cozinha do Refúgio (nota vida-refugio-props §7): corpo de pedra com
-- placa de ferro e duas bocas, chaminé de ferro subindo, boca do fogo
-- com BRASA EMISSIVA. 2 frames = estado por flag:
--   f1 = remendo cru: trinca escancarada na lateral, brasa fraca
--   f2 = remendado + aceso: chapa de ferro rebitada, brasa cheia
-- Relevo: chapa/topo 7-8, corpo 6, boca rebaixada 3, brasa 5, base 4.

local function grid(rows) return table.concat(rows, '\n') end
local function vazio()
    local r = {}
    for x = 1, 64 do r[x] = '.' end
    return r
end

-- Bocal redondo de ferro na placa do topo.
local function bocal(g, x0, y0)
    for x = x0, x0 + 7 do g[y0][x] = 'I' end
    for y = y0 + 1, y0 + 3 do
        g[y][x0], g[y][x0 + 7] = 'I', 'I'
        for x = x0 + 1, x0 + 6 do g[y][x] = 'k' end
    end
    for x = x0, x0 + 7 do g[y0 + 4][x] = 'I' end
end

local function monta(f)
    local g = {}
    for y = 1, 96 do g[y] = vazio() end
    local function set(x, y, ch)
        if x >= 1 and x <= 64 and y >= 1 and y <= 96 then g[y][x] = ch end
    end

    -- chaminé (cols 44-50) com chapéu e cintas
    for x = 42, 52 do set(x, 5, 'M'); set(x, 6, 'M') end
    for y = 7, 33 do
        for x = 44, 50 do set(x, y, 'i') end
        set(44, y, 'I')
    end
    for x = 44, 50 do set(x, 14, 't'); set(x, 22, 't'); set(x, 29, 't') end

    -- placa do topo (cols 12-54): filete claro + superfície com bocais
    for x = 12, 54 do set(x, 34, 'I'); set(x, 35, 'I') end
    for y = 36, 42 do for x = 14, 52 do set(x, y, 't') end end
    bocal(g, 17, 37); bocal(g, 37, 37)

    -- corpo de pedra (cols 14-52, rows 43-85): aresta clara à esquerda,
    -- juntas horizontais e verticais desencontradas
    for y = 43, 85 do
        for x = 14, 52 do set(x, y, 's') end
        set(14, y, 'S'); set(15, y, 'S')
    end
    for _, jy in ipairs { 52, 62, 72, 82 } do
        for x = 14, 52 do set(x, jy, 'v') end
    end
    for y = 43, 51 do set(30, y, 'v') end
    for y = 53, 61 do set(46, y, 'v') end
    for y = 73, 81 do set(48, y, 'v') end
    for y = 83, 85 do set(26, y, 'v') end

    -- boca do fogo (cols 20-42, rows 56-79): moldura de ferro, vão
    -- escuro, grades e leito de brasa
    for x = 22, 40 do set(x, 56, 'M'); set(x, 57, 'M') end
    for y = 58, 79 do
        set(20, y, 'M'); set(21, y, 'M')
        set(41, y, 'M'); set(42, y, 'M')
    end
    for y = 58, 78 do for x = 22, 40 do set(x, y, 'k') end end
    for y = 62, 77 do
        for _, x in ipairs { 26, 29, 33, 36 } do set(x, y, 'i') end
    end
    for x = 20, 42 do set(x, 79, 'M'); set(x, 80, 'M') end
    -- leito de brasa (albedo — o emissivo é canal à parte)
    if f == 1 then
        for y = 73, 77 do
            for x = 24, 39 do
                if (x + y) % 3 ~= 0 then set(x, y, 'e') end
            end
        end
        for x = 27, 35 do set(x, 76, 'o'); set(x, 77, 'o') end
    else
        for y = 69, 77 do
            for x = 23, 40 do
                if (x + y) % 4 ~= 0 then set(x, y, 'e') end
            end
        end
        for y = 73, 77 do for x = 25, 38 do set(x, y, 'o') end end
        for x = 28, 34 do set(x, 75, 'O'); set(x, 76, 'O'); set(x, 77, 'O') end
        -- brasa miúda subindo pelo vão
        set(25, 68, 'o'); set(37, 67, 'o'); set(31, 66, 'e')
    end

    -- lateral: trinca (f1) ou chapa rebitada (f2)
    if f == 1 then
        local path = { 48, 48, 49, 48, 47, 48, 49, 49, 48, 47, 48, 48,
                       49, 48, 47, 47, 48, 49, 48, 47, 48, 48, 49, 48, 47 }
        for i, x in ipairs(path) do
            set(x, 46 + i, 'k'); set(x + 1, 46 + i, 'k')
        end
        -- fiapos de pedra solta junto da trinca
        set(46, 50, 'v'); set(50, 55, 'v'); set(46, 62, 'v'); set(50, 68, 'v')
    else
        for y = 48, 74 do
            for x = 44, 51 do set(x, y, 'm') end
        end
        for _, p in ipairs {
            { 45, 50 }, { 50, 50 }, { 45, 61 }, { 50, 61 },
            { 45, 72 }, { 50, 72 },
        } do set(p[1], p[2], 'r') end
        for x = 44, 51 do set(x, 48, 'I'); set(x, 74, 'I') end
    end

    -- base/sapata e contato com o chão
    for y = 86, 91 do for x = 16, 50 do set(x, y, 'd') end end
    for x = 16, 50 do set(x, 91, 'v') end
    local espalha = { 14, 19, 23, 30, 36, 41, 47, 52 }
    for i, x in ipairs(espalha) do set(x, 92 + (i % 2), 'g') end
    for _, x in ipairs { 17, 25, 34, 44, 49 } do set(x, 94, 'g') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

-- Emissivo: só o leito de brasa. f1 fraco/pobre, f2 cheio e com núcleo.
local function brasas(f)
    local g = {}
    for y = 1, 96 do g[y] = vazio() end
    local function set(x, y, ch)
        if x >= 1 and x <= 64 and y >= 1 and y <= 96 then g[y][x] = ch end
    end
    if f == 1 then
        for y = 73, 77 do
            for x = 24, 39 do
                if (x + y) % 3 ~= 0 then set(x, y, 'e') end
            end
        end
        for x = 27, 35 do set(x, 76, 'o'); set(x, 77, 'o') end
    else
        for y = 69, 77 do
            for x = 23, 40 do
                if (x + y) % 4 ~= 0 then set(x, y, 'e') end
            end
        end
        for y = 73, 77 do for x = 25, 38 do set(x, y, 'o') end end
        for x = 28, 34 do set(x, 75, 'O'); set(x, 76, 'O'); set(x, 77, 'O') end
        set(25, 68, 'o'); set(37, 67, 'o')
    end
    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'fogao',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 3 },               -- vão/trinca/furo de bocal
        M = { ramp = 'iron', step = 5, h = 8 },    -- moldura/chapéu
        I = { ramp = 'iron', step = 5, h = 8 },    -- filete claro de ferro
        i = { ramp = 'iron', step = 3, h = 7 },    -- chaminé/grades
        t = { ramp = 'iron', step = 2, h = 7 },    -- placa do topo/cintas
        m = { ramp = 'iron', step = 2, h = 7 },    -- chapa do remendo
        r = { ramp = 'iron', step = 6, h = 8 },    -- rebites
        s = { ramp = 'stone', step = 3, h = 6 },   -- corpo de pedra
        S = { ramp = 'stone', step = 4, h = 6 },   -- aresta iluminada
        v = { ramp = 'stone', step = 2, h = 5 },   -- juntas
        d = { ramp = 'stone', step = 2, h = 4 },   -- sapata
        e = { ramp = 'ember', step = 2, h = 5, e = 'ember.3', ei = 0.55 },
        o = { ramp = 'ember', step = 4, h = 5, e = 'ember.5', ei = 0.75 },
        O = { ramp = 'ember', step = 6, h = 5, e = 'ember.6', ei = 0.9 },
        g = { ramp = 'earth', step = 3, h = 1 },   -- contato com o chão
    },

    layers = {
        {
            name = 'fogao',
            h = 6,
            albedo = { grid(monta(1)), grid(monta(2)) },
            emissive = { grid(brasas(1)), grid(brasas(2)) },
        },
    },
}
