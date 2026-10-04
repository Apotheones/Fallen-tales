-- BAU de viagem — prop de chão, 64x96, origem nos pés.
-- Casa das camas do Refúgio (nota vida-refugio-props §9): baú de madeira
-- com cantoneiras de ferro, cintas passando por cima da tampa levemente
-- arqueada e fechadura na frente. Coisa de quem chegou com tudo que tem.
-- Relevo: tampa 9-11, corpo 7-8, ferro 9-10, fechadura 10, pés 4, chão 1.

local function grid(rows) return table.concat(rows, '\n') end
local function vazio()
    local r = {}
    for x = 1, 64 do r[x] = '.' end
    return r
end

local function monta()
    local g = {}
    for y = 1, 96 do g[y] = vazio() end
    local function set(x, y, ch)
        if x >= 1 and x <= 64 and y >= 1 and y <= 96 then g[y][x] = ch end
    end
    local function box(x0, y0, x1, y1, ch)
        for y = y0, y1 do for x = x0, x1 do set(x, y, ch) end end
    end

    local X0, X1 = 10, 54   -- largura do baú

    -- tampa arqueada leve: recua 2 px por lado a cada degrau de 2 linhas
    box(X0 + 8, 36, X1 - 8, 37, 'W')
    box(X0 + 4, 38, X1 - 4, 39, 'W')
    box(X0 + 2, 40, X1 - 2, 41, 'w')
    box(X0, 42, X1, 43, 'w')
    -- cintas de ferro passando por cima da tampa
    for _, x in ipairs { X0 + 10, X1 - 12 } do
        for y = 36, 43 do
            set(x, y, 'i'); set(x + 1, y, 'i')
        end
        set(x, 36, 'I'); set(x + 1, 36, 'I')
    end
    -- junção tampa/corpo: filete claro + linha de sombra
    box(X0, 44, X1, 44, 'I')
    box(X0, 45, X1, 45, 'k')

    -- corpo: tábuas verticais
    box(X0, 46, X1, 68, 'F')
    for x = X0 + 2, X1 - 1, 5 do
        for y = 46, 68 do set(x, y, 'v') end
    end
    -- continuação das cintas na frente
    for _, x in ipairs { X0 + 10, X1 - 12 } do
        for y = 46, 68 do set(x, y, 'i'); set(x + 1, y, 'i') end
    end
    -- fechadura na frente (centro)
    box(28, 52, 36, 58, 'm')
    box(29, 53, 35, 57, 'G')
    set(31, 54, 'k'); set(32, 54, 'k')
    box(30, 55, 34, 56, 'g')
    set(32, 55, 'k'); set(32, 56, 'k')
    -- cantoneiras: cantos do corpo em ferro
    for _, x in ipairs { X0, X1 - 2 } do
        box(x, 46, x + 2, 49, 'I')
        box(x, 66, x + 2, 68, 'I')
    end
    -- faixa de cantoneira na base do corpo
    box(X0, 69, X1, 69, 'I')
    box(X0, 70, X1, 70, 'k')

    -- pés baixos
    box(X0 + 2, 71, X0 + 5, 88, 'l')
    box(X1 - 5, 71, X1 - 2, 88, 'l')
    for _, x in ipairs { X0 + 2, X0 + 5, X1 - 5, X1 - 2 } do
        set(x, 89, 'k')
    end

    -- contato com o chão
    for _, x in ipairs { 9, 16, 25, 34, 44, 52 } do
        set(x, 91, 'e'); set(x + 1, 92, 'e')
    end
    for _, x in ipairs { 13, 29, 40, 48 } do set(x, 93, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'bau',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        -- madeira do baú
        W = { ramp = 'wood', step = 6, h = 11 }, -- topo iluminado da tampa
        w = { ramp = 'wood', step = 4, h = 9 },
        v = { ramp = 'wood', step = 3, h = 8 },
        F = { ramp = 'wood', step = 3, h = 7 },  -- frente do corpo
        -- ferro: cintas, cantoneiras, moldura da fechadura
        i = { ramp = 'iron', step = 3, h = 9 },
        I = { ramp = 'iron', step = 5, h = 10 },
        m = { ramp = 'iron', step = 4, h = 10 },
        -- fechadura de ouro velho
        G = { ramp = 'gold', step = 4, h = 10 },
        g = { ramp = 'gold', step = 3, h = 10 },
        -- pés e contato
        l = { ramp = 'wood', step = 2, h = 4 },
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'bau',
            h = 7,
            albedo = grid(monta()),
        },
    },
}
