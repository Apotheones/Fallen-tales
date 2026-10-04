-- CARTEIRAS escolares — prop de chão, 96x96, origem nos pés.
-- Escola/depósito do Refúgio (nota vida-refugio-props §11): duas
-- carteiras reaproveitadas e DESENCONTRADAS — a da esquerda maior,
-- com tampo inclinado e tinteiro; a da direita menor, mais baixa e
-- simples, com livro em cima. A frente arrumada; atrás, o depósito.
-- Relevo: tampo 8-9, corpo 6, tinteiro/livro 9-10, pernas 4, chão 1.

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

    -- ===== CARTEIRA A (esquerda, maior) ==============================
    -- tampo inclinado: fundo alto (row 34) descendo até a frente (row 48)
    box(8, 34, 46, 36, 'W')
    box(8, 37, 46, 39, 'w')
    box(9, 40, 47, 42, 'w')
    box(10, 43, 48, 45, 'w')
    box(11, 46, 49, 48, 'w')
    for x = 14, 44, 9 do
        for y = 38, 46, 3 do set(x, y, 'v') end
    end
    -- filete da frente + face do corpo (guarda-lápis embaixo)
    box(11, 49, 49, 49, 'W')
    box(11, 50, 49, 61, 'F')
    for x = 13, 47, 6 do set(x, 53, 'v'); set(x, 57, 'v') end
    box(11, 62, 49, 62, 'k')
    -- tinteiro no canto do tampo
    box(13, 35, 16, 37, 'k')
    box(13, 38, 16, 39, 'i')
    set(14, 36, 'o'); set(15, 36, 'o')
    -- pernas: frente e fundo
    for _, lx in ipairs { 12, 44 } do
        box(lx, 63, lx + 3, 90, 'l')
        set(lx, 90, 'k'); set(lx + 1, 91, 'k')
    end
    box(20, 63, 22, 78, 'q'); box(36, 63, 38, 78, 'q')
    box(16, 74, 43, 75, 'l')

    -- ===== CARTEIRA B (direita, menor e mais baixa) ==================
    -- tampo inclinado menor
    box(56, 42, 84, 44, 'W')
    box(56, 45, 84, 47, 'w')
    box(57, 48, 85, 50, 'w')
    box(58, 51, 86, 53, 'w')
    for x = 62, 82, 7 do set(x, 49, 'v') end
    -- livro esquecido no tampo
    box(70, 39, 79, 40, 't')
    box(70, 41, 79, 42, 'b')
    set(74, 40, 'd')
    -- filete + corpo menor
    box(58, 54, 86, 54, 'W')
    box(58, 55, 86, 63, 'F')
    for x = 60, 84, 8 do set(x, 58, 'v') end
    box(58, 64, 86, 64, 'k')
    -- pernas mais grossas e curtas
    for _, lx in ipairs { 59, 81 } do
        box(lx, 65, lx + 3, 89, 'l')
        set(lx, 89, 'k'); set(lx + 1, 90, 'k')
    end
    box(63, 72, 82, 73, 'l')

    -- contato com o chão
    for _, x in ipairs { 10, 20, 32, 45, 57, 68, 79, 88 } do
        set(x, 92, 'e'); set(x + 1, 93, 'e')
    end
    for _, x in ipairs { 16, 38, 50, 62, 74, 84 } do set(x, 94, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'carteiras',
    w = 96, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        -- tampos e corpos
        W = { ramp = 'wood', step = 6, h = 9 },
        w = { ramp = 'wood', step = 4, h = 8 },
        v = { ramp = 'wood', step = 3, h = 8 },
        F = { ramp = 'wood', step = 3, h = 6 },
        l = { ramp = 'wood', step = 4, h = 4 },
        q = { ramp = 'wood', step = 2, h = 4 },
        -- tinteiro: ferro com tinta
        i = { ramp = 'iron', step = 3, h = 10 },
        o = { spec = 'abyss', h = 10 },
        -- livro em cima da carteira B
        t = { ramp = 'clothWarm', step = 3, h = 10 },
        b = { ramp = 'bone', step = 4, h = 10 },
        d = { ramp = 'bone', step = 3, h = 10 },
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'carteiras',
            h = 6,
            albedo = grid(monta()),
        },
    },
}
