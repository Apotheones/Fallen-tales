-- PAREDE_PAINEL_JANELA — variante de parede_painel com janela quadrada
-- pequena + peitoril, tile 64x96, topleft. Mesma estrutura de reboco e
-- sarrafos; a abertura (rows 18-45, cols 18-46) tem lintel, jambas e
-- caixilho de madeira, vão escuro rebaixado e peitoril projetado.
-- Brilho quente FRACO dentro (ember ei~0.3/0.15): casa viva, não farol.

local function grid(rows) return table.concat(rows, '\n') end

local SARRAFOS = { 9, 25, 41, 57 }
local MANCHAS = {
    { 48, 20, 8, 4, 'q' }, { 12, 56, 7, 4, 'q' },
    { 30, 62, 6, 3, 'q' }, { 52, 34, 4, 2, 'P' },
}
-- Janela: lintel rows 18-20, vão 21-42, peitoril 43-45, sombra 46.
local X1, X2 = 18, 46     -- lintel/peitoril avançam 2 px por lado
local J1, J2 = 20, 44     -- jambas
local V1, V2 = 23, 41     -- vão
local M1, M2 = 31, 32     -- caixilho vertical

local function monta()
    local g = {}
    for y = 1, 96 do
        local r = {}
        for x = 1, 64 do r[x] = 'p' end
        g[y] = r
    end
    for y = 1, 3 do for x = 1, 64 do g[y][x] = 'P' end end
    for _, m in ipairs(MANCHAS) do
        for y = m[2], m[2] + m[4] - 1 do
            for x = m[1], m[1] + m[3] - 1 do
                if x >= 1 and x <= 64 and y >= 1 and y <= 96 then
                    g[y][x] = m[5]
                end
            end
        end
    end
    for y = 4, 82 do
        for _, c in ipairs(SARRAFOS) do
            g[y][c] = 'w'; g[y][c + 1] = 'w'
            g[y][c + 2] = 'q'
        end
    end
    for y = 83, 86 do for x = 1, 64 do g[y][x] = 'd' end end
    for y = 87, 88 do for x = 1, 64 do g[y][x] = 'W' end end
    for y = 89, 94 do
        for x = 1, 64 do g[y][x] = 'v' end
        for _, c in ipairs(SARRAFOS) do g[y][c], g[y][c + 1] = 'V', 'V' end
    end
    for x = 1, 64 do g[95][x] = 'V'; g[96][x] = 'k' end

    -- JANELA: sobrepõe a parede (sarrafos do vão ficam atrás).
    for y = 18, 20 do for x = X1, X2 do g[y][x] = 'T' end end
    for y = 21, 42 do
        for x = J1, J2 do g[y][x] = 'J' end
        for x = V1, V2 do g[y][x] = 'o' end
        for x = M1, M2 do g[y][x] = 'm' end
    end
    -- sombra do lintel dentro do vão
    for x = V1, V2 do g[21][x] = 'k' end
    -- travessa do caixilho
    for x = J1, J2 do g[31][x] = 'J'; g[32][x] = 'J' end
    -- peitoril projetado + sombra embaixo
    for y = 43, 45 do for x = X1, X2 do g[y][x] = y == 43 and 'S' or 's' end end
    for x = X1, X2 do g[46][x] = 'd' end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

-- Emissivo: lamparina baixa dentro do cômodo, recortada pelo caixilho.
local function brilho()
    local g = {}
    for y = 1, 96 do
        local r = {}
        for x = 1, 64 do r[x] = '.' end
        g[y] = r
    end
    for y = 36, 41 do
        for x = V1, M1 - 1 do g[y][x] = y >= 39 and 'e' or 'O' end
        for x = M2 + 1, V2 do g[y][x] = y >= 39 and 'e' or 'O' end
    end
    g[34][26], g[34][27] = 'O', 'O'
    g[35][37], g[35][38] = 'O', 'O'
    -- uma luzinha mais alta, chama de vela no fundo
    g[25][36], g[26][36] = 'e', 'e'
    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'parede_painel_janela',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 4 },
        P = { ramp = 'plaster', step = 5, h = 6 },
        p = { ramp = 'plaster', step = 4, h = 6 },
        q = { ramp = 'plaster', step = 3, h = 6 },
        d = { ramp = 'plaster', step = 2, h = 5 },
        w = { ramp = 'wood', step = 4, h = 7 },
        W = { ramp = 'wood', step = 5, h = 8 },
        v = { ramp = 'wood', step = 2, h = 8 },
        V = { ramp = 'wood', step = 1, h = 8 },
        -- janela
        J = { ramp = 'wood', step = 4, h = 9 },   -- jamba/travessa
        T = { ramp = 'wood', step = 6, h = 10 },  -- lintel
        S = { ramp = 'wood', step = 6, h = 10 },  -- peitoril, topo
        s = { ramp = 'wood', step = 5, h = 10 },  -- peitoril, corpo
        m = { ramp = 'wood', step = 2, h = 4 },   -- caixilho do vão
        o = { spec = 'abyss', h = 3 },            -- vão escuro rebaixado
        -- brilho interno (só no canal emissivo)
        e = { ramp = 'ember', step = 4, h = 4, e = 'ember.4', ei = 0.3 },
        O = { ramp = 'ember', step = 3, h = 4, e = 'ember.3', ei = 0.15 },
    },

    layers = {
        {
            name = 'parede',
            h = 6,
            albedo = grid(monta()),
            emissive = grid(brilho()),
        },
    },
}
