-- DIVISORIA de pano — prop de chão, 64x96, origem nos pés.
-- Casa das camas do Refúgio (nota vida-refugio-props §9): biombo de
-- madeira com pano esticado entre as camas — privacidade conquistada.
-- 2 frames = estado por flag:
--   f1 = fechada: pano esticado de ponta a ponta
--   f2 = aberta: pano preso ao poste esquerdo, passagem livre
-- Relevo: postes 8-9, travessa 8, pano 7, pés 4, chão 1.

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

    -- postes laterais com capitel
    box(10, 12, 13, 90, 'w')
    box(50, 12, 53, 90, 'w')
    box(9, 9, 14, 11, 'W')
    box(49, 9, 54, 11, 'W')
    -- travessa de cima
    box(14, 12, 49, 14, 'T')
    -- base em pé dos postes
    box(8, 86, 15, 90, 'l'); box(48, 86, 55, 90, 'l')
    for _, x in ipairs { 8, 13, 50, 55 } do set(x, 90, 'k') end

    if f == 1 then
        -- FECHADA: argolas na travessa + pano esticado com quedas
        for x = 16, 48, 4 do set(x, 15, 'r') end
        box(14, 16, 49, 72, 'c')
        -- dobras verticais claras e sombras alternadas
        for _, x in ipairs { 18, 26, 34, 42 } do
            for y = 17, 70 do set(x, y, 'C') end
        end
        for _, x in ipairs { 22, 30, 38, 46 } do
            for y = 17, 70 do set(x, y, 'd') end
        end
        -- barra de baixo com pontas soltas
        box(14, 71, 49, 72, 'd')
        for x = 16, 48, 8 do set(x, 73, 'd'); set(x + 1, 74, 'd') end
    else
        -- ABERTA: pano ajuntado no poste esquerdo + corda prendendo
        box(14, 16, 20, 64, 'c')
        for y = 17, 62 do set(16, y, 'C'); set(19, y, 'd') end
        for y = 18, 60, 3 do set(14, y, 'C') end
        -- prega no meio (onde a corda aperta)
        box(14, 38, 20, 42, 'd')
        box(13, 40, 21, 40, 'r')
        box(13, 41, 21, 41, 'r')
        set(21, 42, 'r'); set(22, 43, 'r')      -- ponta da corda caindo
        -- pontas do pano abaixo da prega
        for x = 15, 20, 3 do set(x, 64, 'd'); set(x + 1, 65, 'd') end
        -- a travessa nua fica à mostra: sombras das argolas vazias
        for x = 26, 48, 6 do set(x, 15, 'v') end
    end

    -- contato com o chão
    for _, x in ipairs { 7, 16, 26, 38, 48, 56 } do
        set(x, 92, 'e'); set(x + 1, 93, 'e')
    end
    for _, x in ipairs { 21, 33, 44 } do set(x, 94, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'divisoria',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        W = { ramp = 'wood', step = 6, h = 9 },  -- capitel
        w = { ramp = 'wood', step = 4, h = 8 },  -- postes
        T = { ramp = 'wood', step = 5, h = 8 },  -- travessa
        v = { ramp = 'wood', step = 3, h = 7 },  -- argola vazia
        l = { ramp = 'wood', step = 3, h = 4 },  -- pés dos postes
        r = { ramp = 'clothWarm', step = 3, h = 8 }, -- argolas/corda
        -- pano
        c = { ramp = 'cloth', step = 3, h = 7 },
        C = { ramp = 'cloth', step = 4, h = 7 },
        d = { ramp = 'cloth', step = 2, h = 6 },
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'divisoria',
            h = 6,
            albedo = { grid(monta(1)), grid(monta(2)) },
        },
    },
}
