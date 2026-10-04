-- PILAR — coluna livre, 64x96, origem topleft, fundo transparente.
-- Base (plinto + toro), fuste com filetes verticais e leve êntase,
-- capitel com equino e ábaco. Luz lateral: fio 'L' na aresta esquerda,
-- 'z' na direita; o normal modela o volume cilíndrico de perfil.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)
local function lin(x, s) return string.rep('.', x - 1) .. s end

-- Fuste: filete claro, 4 caneluras 'm', sombra 'z' na direita.
local FUSTE_A = 'L' .. ('b'):rep(4) .. 'm' .. ('b'):rep(4) .. 'm' ..
                ('b'):rep(4) .. 'm' .. ('b'):rep(2) .. 'z'          -- 19
local FUSTE_B = 'L' .. ('b'):rep(5) .. 'm' .. ('b'):rep(4) .. 'm' ..
                ('b'):rep(4) .. 'm' .. ('b'):rep(3) .. 'z'          -- 21
-- Capitel/base usam gradiente simples de luz lateral.
local function corpo(n_luz, n_base, n_sombra)
    return ('L'):rep(n_luz) .. ('a'):rep(n_base) .. ('m'):rep(n_sombra)
end

local rows = {}
for r = 1, 96 do rows[r] = E end

-- Capitel: ábaco (10-13), equino (14-16), anel de pescoço (17-18).
rows[10] = L(lin(17, 'k' .. ('C'):rep(29) .. 'k'))
rows[11] = L(lin(17, 'k' .. corpo(2, 23, 4) .. 'k'))
rows[12] = L(lin(17, 'k' .. corpo(2, 23, 4) .. 'k'))
rows[13] = L(lin(17, 'k' .. ('m'):rep(29) .. 'k'))
rows[14] = L(lin(19, 'k' .. corpo(1, 21, 3) .. 'k'))
rows[15] = L(lin(20, 'k' .. corpo(1, 19, 3) .. 'k'))
rows[16] = L(lin(21, 'k' .. corpo(1, 17, 3) .. 'k'))
rows[17] = L(lin(22, 'k' .. ('m'):rep(19) .. 'k'))
rows[18] = L(lin(22, 'k' .. ('m'):rep(19) .. 'k'))

-- Fuste: estreito em cima, êntase de +2 col no terço médio.
for r = 19, 30 do rows[r] = L(lin(22, 'k' .. FUSTE_A .. 'k')) end
for r = 31, 78 do rows[r] = L(lin(21, 'k' .. FUSTE_B .. 'k')) end
for r = 79, 81 do rows[r] = L(lin(22, 'k' .. FUSTE_A .. 'k')) end

-- Trinca fina descendo pelo fuste (manutenção, não ruína).
rows[44] = L(lin(21, 'k' .. FUSTE_B:sub(1, 10) .. 'k' .. FUSTE_B:sub(12) .. 'k'))
rows[45] = L(lin(21, 'k' .. FUSTE_B:sub(1, 11) .. 'k' .. FUSTE_B:sub(13) .. 'k'))
rows[46] = L(lin(21, 'k' .. FUSTE_B:sub(1, 11) .. 'k' .. FUSTE_B:sub(13) .. 'k'))

-- Base: anel, toro, degrau e plinto.
rows[82] = L(lin(22, 'k' .. ('m'):rep(19) .. 'k'))
rows[83] = L(lin(20, 'k' .. 'L' .. ('s'):rep(17) .. ('m'):rep(4) .. 'k'))
rows[84] = L(lin(19, 'k' .. 'L' .. ('b'):rep(19) .. ('m'):rep(4) .. 'k'))
rows[85] = L(lin(19, 'k' .. ('m'):rep(23) .. 'k'))
rows[86] = L(lin(17, 'k' .. 'L' .. ('b'):rep(24) .. ('m'):rep(4) .. 'k'))
rows[87] = L(lin(17, 'k' .. 'L' .. ('b'):rep(24) .. ('m'):rep(4) .. 'k'))
rows[88] = L(lin(17, 'k' .. ('m'):rep(29) .. 'k'))
rows[89] = L(lin(15, 'k' .. ('L'):rep(2) .. ('b'):rep(26) .. ('m'):rep(4) .. 'z' .. 'k'))
for r = 90, 94 do
    rows[r] = L(lin(15, 'k' .. ('L'):rep(2) .. ('b'):rep(26) .. ('m'):rep(4) .. 'z' .. 'k'))
end
rows[95] = L(lin(15, 'k' .. ('d'):rep(33) .. 'k'))
rows[96] = L(lin(15, 'k' .. ('d'):rep(33) .. 'k'))

-- Musgo no pé esquerdo do plinto.
rows[90] = L(lin(15, 'k' .. 'g' .. 'L' .. ('b'):rep(26) .. ('m'):rep(4) .. 'z' .. 'k'))
rows[91] = L(lin(15, 'k' .. 'gg' .. 'L' .. ('b'):rep(25) .. ('m'):rep(4) .. 'z' .. 'k'))
rows[92] = L(lin(15, 'k' .. 'gg' .. ('b'):rep(26) .. ('m'):rep(4) .. 'z' .. 'k'))

return {
    name = 'pilar',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 5 },            -- contorno da silhueta / trinca
        C = { ramp = 'stone', step = 7, h = 14 }, -- topo do ábaco
        L = { ramp = 'stone', step = 6, h = 12 }, -- fio de luz na aresta
        a = { ramp = 'stone', step = 5, h = 11 }, -- face iluminada
        b = { ramp = 'stone', step = 4, h = 10 }, -- face média
        m = { ramp = 'stone', step = 3, h = 9 },  -- canelura / sombra média
        z = { ramp = 'stone', step = 2, h = 9 },  -- aresta em sombra
        s = { ramp = 'stone', step = 5, h = 10 }, -- toro da base
        d = { ramp = 'stone', step = 1, h = 6 },  -- sola do plinto
        g = { ramp = 'moss', step = 3, h = 9 },
    },

    layers = {
        {
            name = 'coluna',
            h = 10,
            albedo = grid(rows),
        },
    },
}
