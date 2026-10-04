-- CAMA solteira — prop de chão, 64x96, origem nos pés.
-- Casa das camas do Refúgio (nota vida-refugio-props §9): estrado de
-- madeira, colchão de pano, manta quente dobrada no pé, travesseiro de
-- reboco. 3 frames = variantes por seed:
--   f1 = cama de adulto (comprida)
--   f2 = cama de criança (mais curta e estreita)
--   f3 = cama desfeita (lençol revolto, manta caída, travesseiro torto)
-- Relevo: cabeceira 9-10, colchão 7-8, manta 8, estrado 6, pés 4, chão 1.

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

    local x0, x1 = 16, 50          -- largura do colchão
    local pe = 74                  -- linha do pé da cama
    if f == 2 then x0, x1, pe = 22, 46, 64 end

    -- cabeceira: postes + painel de ripas
    box(x0 - 2, 18, x0 + 1, 30, 'w')
    box(x1 - 1, 18, x1 + 2, 30, 'w')
    box(x0 - 2, 16, x0 + 1, 17, 'W'); box(x1 - 1, 16, x1 + 2, 17, 'W')
    box(x0, 20, x1, 30, 'w')
    for x = x0 + 4, x1 - 4, 7 do
        for y = 21, 29 do set(x, y, 'v') end
    end
    box(x0 - 2, 31, x1 + 2, 33, 'F')

    -- colchão: superfície de pano com borda
    box(x0, 34, x1, pe, 'm')
    box(x0 - 2, 34, x0 - 1, pe, 'F')          -- lateral do estrado
    box(x1 + 1, 34, x1 + 2, pe, 'F')
    for y = 38, pe - 4, 6 do
        for x = x0 + 2, x1 - 2 do set(x, y, 'M') end
    end

    if f == 3 then
        -- DESFEITA: lençol revolto, travesseiro torto, manta caindo
        for _, p in ipairs {
            { x0 + 6, 40 }, { x0 + 14, 43 }, { x0 + 22, 39 },
            { x0 + 10, 47 }, { x0 + 20, 50 }, { x0 + 4, 52 },
        } do set(p[1], p[2], 'x'); set(p[1] + 1, p[2], 'x') end
        for y = 42, 56, 4 do
            for x = x0 + 3, x1 - 3 do
                if (x + y) % 5 < 2 then set(x, y, 'x') end
            end
        end
        -- travesseiro torto
        box(x0 + 2, 36, x0 + 14, 42, 'p')
        box(x0 + 3, 37, x0 + 13, 41, 'P')
        set(x0 + 14, 36, 'P'); set(x0 + 2, 42, 'd')
        -- manta meio caída pelo lado direito
        box(x0 + 18, 56, x1 + 4, 70, 'c')
        for y = 57, 69, 3 do for x = x0 + 19, x1 + 3 do set(x, y, 'C') end end
        box(x1 + 1, 70, x1 + 4, 78, 'c')
        for x = x0 + 20, x1 + 2, 4 do set(x, 68, 'D'); set(x, 69, 'D') end
    else
        -- travesseiro arrumado na cabeceira
        local px1 = f == 2 and x1 - 4 or x1 - 6
        box(x0 + 2, 35, px1, 41, 'p')
        box(x0 + 3, 36, px1 - 1, 40, 'P')
        set(x0 + 2, 41, 'd')
        -- manta dobrada no pé
        local m0 = pe - 14
        box(x0, m0, x1, pe, 'c')
        for y = m0 + 1, pe - 1, 3 do
            for x = x0 + 1, x1 - 1 do set(x, y, 'C') end
        end
        box(x0, m0, x1, m0 + 1, 'C')          -- dobra de cima
        box(x0, pe - 3, x1, pe, 'D')          -- barra dobrada
    end

    -- pé do estrado: ripa frontal + contorno
    box(x0 - 2, pe + 1, x1 + 2, pe + 3, 'F')
    for x = x0 - 1, x1 + 1, 6 do set(x, pe + 2, 'v') end
    box(x0 - 2, pe + 4, x1 + 2, pe + 4, 'k')

    -- pés da cama
    for _, lx in ipairs { x0 - 1, x1 - 1 } do
        box(lx, pe + 5, lx + 2, 90, 'l')
        set(lx, 90, 'k'); set(lx + 1, 91, 'k')
    end

    -- contato com o chão
    for _, x in ipairs { x0 - 3, x0 + 6, x0 + 16, x1 - 6, x1 + 3 } do
        set(x, 92, 'e'); set(x + 1, 93, 'e')
    end
    for _, x in ipairs { x0 + 2, x0 + 22, x1 - 2 } do set(x, 94, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'cama',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        -- estrado
        W = { ramp = 'wood', step = 6, h = 10 },
        w = { ramp = 'wood', step = 4, h = 9 },
        v = { ramp = 'wood', step = 3, h = 9 },
        F = { ramp = 'wood', step = 3, h = 6 },
        l = { ramp = 'wood', step = 4, h = 4 },
        -- colchão de pano jade neutro
        m = { ramp = 'cloth', step = 2, h = 7 },
        M = { ramp = 'cloth', step = 3, h = 7 },
        x = { ramp = 'cloth', step = 1, h = 6 },   -- lençol revolto
        -- travesseiro de reboco
        p = { ramp = 'plaster', step = 4, h = 8 },
        P = { ramp = 'plaster', step = 5, h = 8 },
        d = { ramp = 'plaster', step = 2, h = 7 },
        -- manta quente dobrada no pé
        c = { ramp = 'clothWarm', step = 3, h = 8 },
        C = { ramp = 'clothWarm', step = 4, h = 8 },
        D = { ramp = 'clothWarm', step = 2, h = 7 },
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'cama',
            h = 6,
            albedo = { grid(monta(1)), grid(monta(2)), grid(monta(3)) },
        },
    },
}
