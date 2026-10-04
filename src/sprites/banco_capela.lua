-- BANCO_CAPELA — banco longo de capela, 64x96, origem nos pés.
-- Capela do Refúgio (nota vida-refugio-props §8): banco de tábuas com
-- desgaste ASSIMÉTRICO — brilho de uso na ponta direita do assento e do
-- encosto, onde todo mundo senta. 2 frames:
--   f1 = banco da nave: encosto em altura normal
--   f2 = banco do fundo junto à entrada: mais simples, encosto baixo —
--        lugar de quem não quer ser chamado
-- Relevo: encosto 8-9, assento 7-8, pés 4-5, chão 1.

local function grid(rows) return table.concat(rows, '\n') end
local function vazio()
    local r = {}
    for x = 1, 64 do r[x] = '.' end
    return r
end

local function monta(f)
    local g = {}
    for y = 1, 96 do g[y] = vazio() end
    local function set(x, y, ch)
        if x >= 1 and x <= 64 and y >= 1 and y <= 96 then g[y][x] = ch end
    end
    local function box(x0, y0, x1, y1, ch)
        for y = y0, y1 do for x = x0, x1 do set(x, y, ch) end end
    end

    -- ENCOSTO: postes laterais + ripa de cima + painel; f2 é baixo
    local topo = f == 1 and 30 or 46
    -- postes sobem do chão ao encosto
    for y = topo, 64 do
        box(10, y, 13, y, 'w'); box(50, y, 53, y, 'w')
    end
    box(9, topo, 54, topo + 1, 'W')          -- ripa de cima
    box(11, topo + 2, 52, topo + 3, 'w')     -- alma
    for x = 13, 50, 6 do                      -- sarrafos do encosto
        for y = topo + 2, topo + 12 do set(x, y, 'v') end
    end
    if f == 1 then
        -- ripa do meio + brilho de uso na ponta direita do topo
        box(11, topo + 9, 52, topo + 10, 'w')
        box(44, topo, 54, topo + 1, 'S')
        for x = 46, 52 do set(x, topo + 2, 'S') end
    else
        -- encosto baixo: uma ripa só, brilho menor
        box(46, topo, 54, topo + 1, 'S')
    end

    -- ASSENTO: trapézio, frente mais larga que o fundo
    box(14, 56, 52, 57, 's')
    box(11, 58, 55, 60, 's')
    box(9, 61, 57, 63, 's')
    box(8, 64, 58, 64, 'S')
    -- brilho de uso na ponta direita (onde a mão e a anca pesam)
    if f == 1 then box(48, 58, 55, 62, 'S') else box(46, 58, 55, 62, 'S') end
    -- frente do assento (avental) + contorno
    box(8, 65, 58, 67, 'F')
    for x = 10, 56, 7 do set(x, 66, 'v') end
    box(8, 68, 58, 68, 'k')

    -- SUPORTES: laterais chegam ao chão; central menor em f2
    for _, lx in ipairs { 10, 50 } do
        box(lx, 69, lx + 3, 90, 'l')
        set(lx, 90, 'k'); set(lx + 1, 91, 'k'); set(lx + 2, 90, 'k')
    end
    if f == 1 then
        box(29, 69, 32, 88, 'p')
        box(14, 76, 49, 77, 'l')             -- travessa
    else
        box(30, 69, 33, 86, 'p')
    end

    -- contato com o chão
    for _, x in ipairs { 9, 16, 24, 33, 42, 51, 56 } do
        set(x, 92, 'e'); set(x + 1, 93, 'e')
    end
    for _, x in ipairs { 20, 38, 47 } do set(x, 94, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'banco_capela',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        W = { ramp = 'wood', step = 6, h = 9 },  -- ripa de cima
        w = { ramp = 'wood', step = 4, h = 8 },  -- encosto/postes
        v = { ramp = 'wood', step = 3, h = 8 },  -- sarrafo/veio
        S = { ramp = 'wood', step = 6, h = 7 },  -- brilho de uso (polido)
        s = { ramp = 'wood', step = 4, h = 7 },  -- assento
        F = { ramp = 'wood', step = 3, h = 6 },  -- avental
        l = { ramp = 'wood', step = 4, h = 5 },  -- suportes laterais
        p = { ramp = 'wood', step = 2, h = 4 },  -- suporte central recuado
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'banco',
            h = 6,
            albedo = { grid(monta(1)), grid(monta(2)) },
        },
    },
}
