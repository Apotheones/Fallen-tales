-- PAREDE_PAINEL — parede interior de painéis verticais, tile 64x96,
-- topleft. Reboco claro com sarrafos verticais de madeira (wallStyle
-- 'panel' do hub): filete claro no topo, manchas de reboco, meio-degrau
-- de sombra acima do rodapé escuro. Sem aberturas — a variante com
-- janela é parede_painel_janela.lua.
-- Relevo: reboco 6, sarrafo 7 (légère saliência), sombra de base 5,
-- rodapé 8.

local function L(s) return s .. ('.'):rep(64 - #s) end
local function grid(rows) return table.concat(rows, '\n') end

-- Sarrafos verticais: centros 9, 25, 41, 57 (painéis de ~16 px).
local SARRAFOS = { 9, 25, 41, 57 }
-- Manchas de reboco desenhadas (x, y, w, h, char).
local MANCHAS = {
    { 30, 18, 9, 4, 'q' }, { 12, 40, 7, 5, 'q' },
    { 46, 58, 8, 4, 'q' }, { 18, 66, 6, 3, 'q' },
    { 36, 30, 5, 3, 'P' }, { 54, 22, 4, 2, 'P' },
}

local function monta()
    local g = {}
    for y = 1, 96 do
        local r = {}
        for x = 1, 64 do r[x] = 'p' end
        g[y] = r
    end
    -- filete claro no topo (luz descendo do forro)
    for y = 1, 3 do for x = 1, 64 do g[y][x] = 'P' end end
    -- manchas de reboco
    for _, m in ipairs(MANCHAS) do
        for y = m[2], m[2] + m[4] - 1 do
            for x = m[1], m[1] + m[3] - 1 do
                if x >= 1 and x <= 64 and y >= 1 and y <= 96 then
                    g[y][x] = m[5]
                end
            end
        end
    end
    -- sarrafos: 2 px de madeira + 1 px de sombra de reboco à direita
    for y = 4, 82 do
        for _, c in ipairs(SARRAFOS) do
            g[y][c] = 'w'; g[y][c + 1] = 'w'
            g[y][c + 2] = 'q'
        end
    end
    -- meio-degrau de sombra na base (reboco escurecido pelo rodapé)
    for y = 83, 86 do for x = 1, 64 do g[y][x] = 'd' end end
    -- rodapé: filete claro de topo, corpo escuro, fio de contato
    for y = 87, 88 do for x = 1, 64 do g[y][x] = 'W' end end
    for y = 89, 94 do
        for x = 1, 64 do g[y][x] = 'v' end
        for _, c in ipairs(SARRAFOS) do g[y][c], g[y][c + 1] = 'V', 'V' end
    end
    for x = 1, 64 do g[95][x] = 'V'; g[96][x] = 'k' end

    local rows = {}
    for y = 1, 96 do rows[y] = table.concat(g[y]) end
    return rows
end

return {
    name = 'parede_painel',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 4 },              -- fio de contato do rodapé
        P = { ramp = 'plaster', step = 5, h = 6 },-- filete de topo / luz
        p = { ramp = 'plaster', step = 4, h = 6 },-- reboco base
        q = { ramp = 'plaster', step = 3, h = 6 },-- mancha/sombra de sarrafo
        d = { ramp = 'plaster', step = 2, h = 5 },-- meio-degrau na base
        w = { ramp = 'wood', step = 4, h = 7 },   -- sarrafo vertical
        W = { ramp = 'wood', step = 5, h = 8 },   -- filete do rodapé
        v = { ramp = 'wood', step = 2, h = 8 },   -- rodapé escuro
        V = { ramp = 'wood', step = 1, h = 8 },   -- emenda do rodapé
    },

    layers = {
        {
            name = 'parede',
            h = 6,
            albedo = grid(monta()),
        },
    },
}
