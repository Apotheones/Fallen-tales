-- FUMACA_CHAMINE — coluna de fumaça de chaminé, 64x96, origem topleft.
-- Refúgio (frente micro-animações): fios de fumaça subindo da boca de
-- uma chaminé (a peça pendura sobre a fachada/casa — a boca mora na base
-- do quadro, linhas 88-93). Sem alfa por pixel na DSL, a translucidez é
-- desenhada: corpo em 'plaster' claro, orlas e furos em 'sea' frio —
-- quanto mais alto, mais furado e frio o fio.
--
-- LOOP: f1..f4 — o fio ondula (centro desloca por seno + fase do quadro)
-- e três bojos 'puff' sobem 6 px por frame num ciclo de 24 px: o que sai
-- pelo topo reentra na base, então f4 -> f1 não tem salto. Relevo baixo
-- (h 1-3): fumaça é quase plano — não carrega volume de pedra.

local W, H = 64, 96

local function nova(fill)
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = fill end
        g[y] = r
    end
    return g
end

local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function hsh(x, y, s) return (x * 31 + y * 17 + s * 13) % 11 end

-- Bojo de fumaça: elipse ruidosa ~8x5, miolo 'p', bordas furadas 'c'.
local function puff(g, cx, cy, f)
    for dy = -2, 2 do
        local larg = 8 - math.abs(dy) * 2
        local deriva = math.floor(math.sin((cy + dy * 3 + f * 5) / 7) * 2)
        for i = 0, larg - 1 do
            local x = cx + deriva - math.floor(larg / 2) + i
            local n = hsh(x, cy + dy, f)
            if n < 8 then
                set(g, x, cy + dy, n < 5 and 'p' or 'c')
            end
        end
    end
end

local function frame(f)
    local g = nova('.')

    -- Boca da chaminé (base do quadro): nascimento denso e quente do
    -- fio — mesmo desenho em todos os frames (âncora do loop).
    for y = 88, 93 do
        for x = 30, 34 do
            local n = hsh(x, y, 0)
            local ch = 'p'
            if n < 2 then ch = 'k' elseif n > 7 then ch = 'P' end
            set(g, x, y, ch)
        end
    end

    -- Fio contínuo: sobe da boca (y 87) e dissolve perto do topo
    -- (y ~14). O centro serpenteia com o quadro; a largura cresce com a
    -- altura e a orla esfria/fura conforme sobe.
    for y = 14, 87 do
        local t = (88 - y) / 74                      -- 0 na boca, 1 no topo
        local cx = 32 + math.floor(
            math.sin((y + f * 7) / 9) * (1 + 3 * t) + 0.5)
        local larg = 2 + math.floor(t * 4 + 0.5)
        for i = 0, larg - 1 do
            local x = cx - math.floor(larg / 2) + i
            local n = hsh(x, y, f)
            local ch = 'p'
            if n < t * 6 then ch = 'c' end           -- orlas frias
            if i == math.floor(larg / 2) and n < 3 then ch = 'P' end
            if n == 10 and t > 0.4 then ch = nil end -- furos de dispersão
            if ch then set(g, x, y, ch) end
        end
    end

    -- Bojos que sobem 6 px por frame, espaçados 24 px — f4 envia o de
    -- cima para fora e o da base ocupa seu lugar: loop fechado.
    for _, y0 in ipairs({64, 40, 16}) do
        local y = y0 - (f - 1) * 6
        if y < 4 then y = y + 72 end
        puff(g, 32 + math.floor(math.sin((y + f * 7) / 9) * 2), y, f)
    end

    return str(g)
end

return {
    name = 'fumaca_chamine',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 2},               -- núcleo escuro no nascimento
        p = {ramp = 'plaster', step = 4, h = 2}, -- corpo do fio
        P = {ramp = 'plaster', step = 5, h = 2}, -- fio de luz na fumaça
        c = {ramp = 'sea', step = 4, h = 1},     -- orla fria / dissipação
    },

    layers = {
        {
            name = 'fumaca',
            h = 2,
            albedo = { frame(1), frame(2), frame(3), frame(4) },
        },
    },
}
