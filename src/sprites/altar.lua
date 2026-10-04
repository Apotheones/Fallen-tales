-- ALTAR contido — prop de chão, 96x96, origem nos pés.
-- Capela do Refúgio (nota vida-refugio-props §8): altar de pedra/reboco
-- que não domina a sala — bloco baixo, toalha de osso limpa correndo
-- pela frente, dois candelabros laterais apagados (a luz da capela mora
-- em velas.lua), relevo moderado: painel rebaixado com nicho em arco.
-- Relevo: laje 8, corpo 6-7, nicho rebaixado 5, candelabro 10, base 4.

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

    -- candelabros laterais (cols 18-22 e 74-78): haste de ouro velho,
    -- prato e vela de osso apagada com pavio
    for _, cx in ipairs { 18, 74 } do
        box(cx + 1, 14, cx + 3, 15, 'b')           -- vela
        set(cx + 2, 13, 'k')                     -- pavio
        box(cx, 16, cx + 4, 17, 'G')             -- prato
        box(cx + 1, 18, cx + 3, 30, 'g')         -- haste
        box(cx, 31, cx + 4, 33, 'G')             -- pé do candelabro
    end

    -- laje do topo: filete claro + corpo
    box(14, 34, 82, 36, 'S')
    box(14, 37, 82, 40, 's')

    -- corpo do altar (cols 16-80, rows 41-86)
    box(16, 41, 80, 86, 's')
    for y = 41, 86 do set(16, y, 'S'); set(17, y, 'S') end
    for x = 16, 80 do set(x, 63, 'v'); set(x, 75, 'v') end

    -- painel frontal rebaixado com nicho em arco (relevo moderado)
    box(30, 48, 66, 78, 'd')
    box(31, 49, 65, 77, 'r')
    -- arco do nicho: vão escuro contornado de reboco claro
    for x = 38, 58 do set(x, 71, 'p') end
    for x = 40, 56 do
        set(x, 70, 'p'); set(x, 72, 'p')
    end
    for y = 57, 69 do
        set(40, y, 'p'); set(56, y, 'p')
        for x = 41, 55 do set(x, y, 'o') end
    end
    for x = 41, 55 do set(x, 56, 'p'); set(x, 70, 'o') end
    for x = 42, 54 do set(x, 55, 'p') end
    for x = 44, 52 do set(x, 54, 'p') end
    for x = 46, 50 do set(x, 53, 'p') end
    -- dentro do nicho: tigelinha de oferenda simples
    box(46, 65, 50, 66, 'b'); box(47, 64, 49, 64, 'B')

    -- toalha de osso correndo pelo topo e caindo na frente
    box(38, 34, 58, 43, 'c')
    for y = 36, 42, 3 do for x = 39, 57 do set(x, y, 'C') end end
    -- queda frontal por cima do corpo (depois do painel? não — a toalha
    -- fica À FRENTE do painel: redesenha por cima do corpo, não do nicho)
    box(38, 44, 58, 62, 'c')
    for x = 39, 57, 5 do for y = 45, 60 do set(x, y, 'C') end end
    for x = 38, 58 do set(x, 61, 'D'); set(x, 62, 'D') end
    for x = 40, 56, 4 do set(x, 63, 'D') end

    -- rodapé e contato com o chão
    box(14, 87, 82, 91, 'v')
    for x = 14, 82 do set(x, 91, 'k') end
    for _, x in ipairs { 16, 24, 33, 45, 57, 68, 78 } do
        set(x, 92, 'e'); set(x + 1, 93, 'e')
    end
    for _, x in ipairs { 21, 39, 50, 62, 74 } do set(x, 94, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'altar',
    w = 96, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        -- pedra/reboco do altar
        S = { ramp = 'stone', step = 5, h = 8 },   -- laje/filete claro
        s = { ramp = 'stone', step = 4, h = 7 },   -- corpo
        v = { ramp = 'stone', step = 2, h = 5 },   -- junta/rodapé
        d = { ramp = 'stone', step = 2, h = 5 },   -- painel rebaixado
        r = { ramp = 'stone', step = 3, h = 5 },   -- fundo do painel
        p = { ramp = 'plaster', step = 4, h = 6 }, -- arco do nicho
        o = { spec = 'abyss', h = 4 },             -- vão do nicho
        -- toalha de osso
        c = { ramp = 'bone', step = 4, h = 8 },
        C = { ramp = 'bone', step = 5, h = 8 },
        D = { ramp = 'bone', step = 3, h = 7 },   -- barra da toalha
        -- candelabro de ouro velho + vela de osso apagada
        g = { ramp = 'gold', step = 3, h = 10 },
        G = { ramp = 'gold', step = 4, h = 10 },
        b = { ramp = 'bone', step = 4, h = 10 },
        B = { ramp = 'bone', step = 5, h = 10 },
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'altar',
            h = 6,
            albedo = grid(monta()),
        },
    },
}
