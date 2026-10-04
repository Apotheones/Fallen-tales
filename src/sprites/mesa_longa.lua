-- MESA_LONGA comunitária — prop de chão, 96x96, origem nos pés.
-- Cozinha do Refúgio (nota vida-refugio-props §7): mesa de tábuas mais
-- larga que mesa.lua, posta para muitos. Borda esfregada mais clara na
-- direção de uso (filetes 'W' na frente e faixa gasta junto da borda),
-- toalha parcial cobrindo a terça esquerda e escorrendo pela borda,
-- duas tigelas e um jarro. Relevo: tampo 8-9, objetos 10-11, face 6,
-- pernas 4, chão 1.

local function grid(rows) return table.concat(rows, '\n') end
local function vazio()
    local r = {}
    for x = 1, 96 do r[x] = '.' end
    return r
end

local function monta()
    local g = {}
    for y = 1, 96 do g[y] = vazio() end
    local function set(x, y, ch)
        if x >= 1 and x <= 96 and y >= 1 and y <= 96 then g[y][x] = ch end
    end
    local function box(x0, y0, x1, y1, ch)
        for y = y0, y1 do for x = x0, x1 do set(x, y, ch) end end
    end

    -- fio de trás do tampo
    box(12, 34, 84, 35, 'W')
    -- superfície do tampo com veios
    box(12, 36, 84, 56, 'w')
    local veios = { 20, 33, 47, 55, 69, 80 }
    for _, x in ipairs(veios) do
        for y = 37, 55, 2 do set(x, y, 'v') end
    end
    -- faixa esfregada junto da borda frontal (o lado onde se serve)
    for x = 14, 82 do
        if x % 7 < 4 then set(x, 54, 's'); set(x, 55, 's') end
    end

    -- toalha parcial: terça esquerda, cobre o tampo e cai pela borda
    box(12, 36, 36, 56, 'c')
    for _, x in ipairs { 18, 27 } do
        for y = 38, 55, 2 do set(x, y, 'C') end
    end
    for y = 40, 54, 6 do for x = 13, 35 do set(x, y, 'd') end end

    -- jarro de reboco (cols 58-66)
    box(60, 40, 64, 42, 'o')
    box(59, 43, 65, 51, 'p'); box(58, 44, 66, 49, 'p')
    for y = 44, 49 do set(59, y, 'P') end
    box(61, 52, 63, 53, 'o')
    -- tigela fundo (cols 42-50)
    box(42, 46, 50, 47, 'B')
    box(43, 48, 49, 50, 'b'); set(44, 48, 'n'); set(45, 48, 'n')
    set(46, 49, 'n')
    -- tigela frente-direita (cols 72-80)
    box(72, 44, 80, 45, 'B')
    box(73, 46, 79, 48, 'b'); set(75, 46, 'n'); set(76, 46, 'n')
    -- migalhas
    for _, p in ipairs { { 52, 50 }, { 56, 54 }, { 68, 51 }, { 39, 52 } } do
        set(p[1], p[2], 's')
    end

    -- borda frontal: filete claro esfregado + face + contorno
    box(12, 57, 84, 57, 'W')
    -- desgaste no filete: trechos mais claros ainda onde a mão passa
    box(40, 57, 52, 57, 'u'); box(66, 57, 78, 57, 'u')
    box(12, 58, 84, 60, 'F')
    for x = 13, 83, 6 do set(x, 59, 'v') end
    box(12, 61, 84, 61, 'k')
    -- toalha caindo por cima da borda (depois da face)
    box(13, 58, 35, 62, 'd')
    for x = 14, 34, 4 do set(x, 59, 'c'); set(x, 61, 'c') end
    for x = 15, 33, 7 do set(x, 63, 'd') end

    -- pernas da frente + travessa; pernas de trás escuras e mais curtas
    for _, lx in ipairs { 15, 44, 76 } do
        box(lx, 62, lx + 3, 91, 'l')
        set(lx, 91, 'k'); set(lx + 1, 92, 'k'); set(lx + 2, 91, 'k')
    end
    box(19, 76, 75, 77, 'l')
    for _, qx in ipairs { 24, 66 } do
        box(qx, 62, qx + 2, 80, 'q')
    end
    -- contato com o chão
    for _, x in ipairs { 14, 20, 30, 43, 52, 63, 74, 80 } do
        set(x, 93, 'e'); set(x + 2, 94, 'e')
    end
    for _, x in ipairs { 26, 38, 57, 70, 84 } do set(x, 95, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'mesa_longa',
    w = 96, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        -- tampo: fio, base, veios, face frontal, faixa esfregada
        W = { ramp = 'wood', step = 6, h = 9 },
        u = { ramp = 'wood', step = 7, h = 9 },   -- filete esfregado (luz)
        w = { ramp = 'wood', step = 4, h = 8 },
        v = { ramp = 'wood', step = 3, h = 8 },
        s = { ramp = 'wood', step = 5, h = 8 },   -- tampo gasto/migalha
        F = { ramp = 'wood', step = 3, h = 6 },
        -- pernas
        l = { ramp = 'wood', step = 4, h = 4 },
        q = { ramp = 'wood', step = 2, h = 4 },
        -- toalha de pano quente parcial
        c = { ramp = 'clothWarm', step = 4, h = 9 },
        C = { ramp = 'clothWarm', step = 5, h = 9 },
        d = { ramp = 'clothWarm', step = 2, h = 8 },
        -- jarro de reboco
        p = { ramp = 'plaster', step = 4, h = 11 },
        P = { ramp = 'plaster', step = 5, h = 11 },
        o = { ramp = 'plaster', step = 2, h = 10 },
        -- tigelas de osso
        b = { ramp = 'bone', step = 4, h = 10 },
        B = { ramp = 'bone', step = 5, h = 10 },
        n = { ramp = 'bone', step = 2, h = 9 },   -- fundo da tigela
        -- contato com o chão
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'mesa',
            h = 6,
            albedo = grid(monta()),
        },
    },
}
