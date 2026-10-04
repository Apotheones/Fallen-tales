-- CAIXAS_ANTIGAS — pilha do depósito, 64x96, origem nos pés.
-- Escola/depósito do Refúgio (nota vida-refugio-props §11): caixas de
-- madeira e fardos de tecido amarrado empilhados na metade escura da
-- sala — estado "guardado" do cômodo. 3 frames = arranjos por seed:
--   f1 = duas caixas empilhadas + fardo de pano jade em cima
--   f2 = caixas lado a lado + fardo alto de pano quente, pano caído
--   f3 = revistado: caixa tombada de lado com pano saindo da boca,
--        fardo solto ao lado — metade do depósito revirada
-- Relevo: caixas 6-8, fardos 8-9, cordas 9, chão 1.

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
    -- caixa de tábuas: corpo, filete do topo, sarrafos verticais, face
    local function caixa(x0, y0, x1, y1)
        box(x0, y0, x1, y0 + 1, 'W')
        box(x0, y0 + 2, x1, y1 - 3, 'w')
        for x = x0 + 3, x1 - 2, 6 do
            for y = y0 + 3, y1 - 4 do set(x, y, 'v') end
        end
        box(x0, y1 - 2, x1, y1 - 1, 'F')
        box(x0, y1, x1, y1, 'k')
    end
    -- fardo de tecido: domo com pregas e corda cruzada
    local function fardo(x0, y0, x1, y1, c, C)
        box(x0 + 2, y0, x1 - 2, y0 + 1, C)
        box(x0, y0 + 2, x1, y0 + 3, c)
        box(x0 - 1, y0 + 4, x1 + 1, y1 - 2, c)
        for x = x0 + 3, x1 - 2, 5 do
            for y = y0 + 4, y1 - 3 do set(x, y, C) end
        end
        -- corda em cruz
        for y = y0 + 2, y1 - 2 do set(x0 + 4, y, 'r'); set(x1 - 4, y, 'r') end
        for x = x0, x1 do set(x, y0 + 6, 'r') end
        set(x0 + 4, y0 + 5, 'R'); set(x0 + 5, y0 + 6, 'R')  -- nó
        box(x0 - 1, y1 - 1, x1 + 1, y1, 'D')
    end
    -- caixa tombada de lado: sarrafos horizontais, boca aberta no
    -- canto direito-alto com pano escapando para fora
    local function caixa_lado(x0, y0, x1, y1)
        box(x0, y0 + 2, x1 - 2, y1 - 3, 'w')          -- corpo
        box(x0, y0, x0 + 1, y1 - 3, 'W')            -- filete do fundo (esq.)
        box(x0, y1 - 2, x1, y1, 'k')                -- base sombreada
        for y = y0 + 4, y1 - 6, 6 do
            box(x0 + 2, y, x1 - 4, y, 'v')          -- sarrafos horizontais
        end
        -- boca aberta: ombreira escura no topo-direito
        box(x1 - 3, y0, x1, y0 + 3, 'k')
        box(x1 - 8, y0 + 1, x1 - 4, y0 + 2, 'k')
        -- pano saindo da boca
        box(x1 - 9, y0 - 2, x1 - 2, y0 + 1, 'c')
        for y = y0 - 1, y0 + 1, 2 do
            for x = x1 - 8, x1 - 3 do set(x, y, 'C') end
        end
        box(x1 - 6, y0 + 2, x1 - 3, y0 + 7, 'D')    -- ponta pendurada
    end
    -- fardo solto: uma corda só, sem nó, aba de pano aberta na base
    local function fardo_solto(x0, y0, x1, y1, c, C)
        box(x0 + 2, y0, x1 - 2, y0 + 1, C)
        box(x0, y0 + 2, x1, y0 + 3, c)
        box(x0 - 1, y0 + 4, x1 + 1, y1 - 3, c)
        for x = x0 + 3, x1 - 2, 5 do
            for y = y0 + 4, y1 - 4 do set(x, y, C) end
        end
        for y = y0 + 2, y1 - 3 do set(x0 + 4, y, 'r') end -- corda frouxa
        box(x0 - 1, y1 - 2, x1 + 1, y1, 'D')
        box(x0 - 3, y1 - 7, x0, y1 - 1, 'D')             -- aba solta à esq.
        set(x0 - 3, y1 - 8, c)
        set(x0 - 2, y1 - 8, C)
    end

    if f == 1 then
        -- pilha: caixão de baixo + caixa menor + fardo jade no topo
        caixa(8, 62, 56, 90)
        caixa(14, 40, 50, 61)
        fardo(18, 22, 44, 39, 'c', 'C')
    elseif f == 2 then
        -- lado a lado + fardo alto de pano quente à direita
        caixa(6, 58, 34, 90)
        caixa(36, 66, 58, 90)
        fardo(38, 34, 54, 65, 't', 'T')
        -- pano solto caído por cima da caixa esquerda
        box(10, 48, 26, 58, 'c')
        for y = 50, 56, 3 do for x = 11, 25 do set(x, y, 'C') end end
        for x = 10, 26 do set(x, 57, 'D'); set(x, 58, 'D') end
        for x = 12, 24, 5 do set(x, 59, 'D') end
    else
        -- revistado: caixa tombada com pano saindo, fardo solto ao lado
        caixa_lado(4, 64, 42, 90)
        fardo_solto(46, 62, 60, 88, 't', 'T')
        -- retalho de pano caído no chão entre os dois
        box(34, 86, 45, 89, 'D')
        for x = 36, 44, 4 do set(x, 85, 'c') end
    end

    -- contato com o chão
    for _, x in ipairs { 8, 16, 27, 36, 45, 54 } do
        set(x, 92, 'e'); set(x + 1, 93, 'e')
    end
    for _, x in ipairs { 13, 22, 31, 41, 50 } do set(x, 94, 'e') end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'caixas_antigas',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        -- caixas de madeira
        W = { ramp = 'wood', step = 6, h = 8 },
        w = { ramp = 'wood', step = 4, h = 7 },
        v = { ramp = 'wood', step = 3, h = 7 },
        F = { ramp = 'wood', step = 3, h = 6 },
        -- fardos: pano jade e pano quente, cordas e nó
        c = { ramp = 'cloth', step = 3, h = 8 },
        C = { ramp = 'cloth', step = 4, h = 9 },
        t = { ramp = 'clothWarm', step = 3, h = 8 },
        T = { ramp = 'clothWarm', step = 4, h = 9 },
        D = { ramp = 'cloth', step = 2, h = 7 },  -- barra/pano caído
        r = { ramp = 'clothWarm', step = 2, h = 9 }, -- corda
        R = { ramp = 'clothWarm', step = 4, h = 9 }, -- nó
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'pilha',
            h = 6,
            albedo = { grid(monta(1)), grid(monta(2)), grid(monta(3)) },
        },
    },
}
