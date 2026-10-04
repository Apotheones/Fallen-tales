-- ENTULHO — pilha de cascalho e oficina, tile 64x64, origem topleft.
-- Quintal da forja (vida-refugio-props §5): pedrinhas, limalha e
-- pedaços de metal sobre terra — pilha baixa, sem colisão sugerida,
-- densidade caindo do centro às bordas. O pedaço de laje quebrada e os
-- traços retos de metal quebram o orgânico do cascalho.
-- 3 frames = variantes de seed (arranjo da pilha e da laje).
-- h: terra 1, cascalho 2, miolo da pilha 3.

local W, H = 64, 64

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

local function carimbo(g, x, y, forma)
    for j = 1, #forma do
        local linha = forma[j]
        for i = 1, #linha do
            local c = linha:sub(i, i)
            if c ~= '.' then set(g, x + i - 1, y + j - 1, c) end
        end
    end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- pedaço de laje quebrada, com trinca 'k'
local LAGE = {
    '.pppP..',
    'pPkkppp',
    'pkkPpPp',
    'pppPpk.',
    '.qp....',
}
local LAGE_B = {
    '..ppP..',
    '.pkPpp.',
    'pPpPkP.',
    'qp.ppp.',
}

local function entulho(seed)
    local g = nova('e')
    -- pedrinhas e resíduo espalhados no tile inteiro
    for y = 1, H do
        for x = 1, W do
            local n = h2(x, y, seed)
            if n < 3 then g[y][x] = 'q'
            elseif n < 6 then g[y][x] = 'd' end
        end
    end
    -- pilha: densidade cai com a distância; miolo mais claro e metálico
    local cx = 30 + (seed * 7) % 9
    local cy = 36 + (seed * 5) % 7 - 3
    for y = 1, H do
        for x = 1, W do
            local dx = x - cx
            local dy = (y - cy) * 1.35
            local dist = math.sqrt(dx * dx + dy * dy)
            local n = h2(x * 3 + 1, y * 5 + 2, seed * 7)
            if n < 27 - dist * 1.2 then
                local m = h2(x * 7, y * 3, seed * 3)
                if dist < 7 then
                    g[y][x] = m < 40 and 'P' or m < 62 and 'I'
                        or m < 80 and 'p' or 'r'
                else
                    g[y][x] = m < 38 and 'p' or m < 58 and 'q'
                        or m < 72 and 'r' or m < 85 and 'i' or 'd'
                end
            end
        end
    end
    -- a laje partida: peça reconhecível no meio do resto
    carimbo(g, cx - 14 + (seed * 4) % 8, cy - 12 + (seed * 3) % 6,
        seed % 2 == 0 and LAGE_B or LAGE)
    -- limalhas: traços retos de metal, angulares contra o cascalho
    local lx = cx + 8 - seed * 3
    local ly = cy + 6 + seed
    for i = 0, 4 do set(g, lx + i, ly + (i % 2 == 0 and 0 or 1), i < 3 and 'i' or 'I') end
    for i = 0, 3 do set(g, cx - 6 + i, cy + 9, i == 1 and 'I' or 'i') end
    return str(g)
end

return {
    name = 'entulho',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        e = {ramp = 'earth', step = 3, h = 1}, -- terra do quintal
        d = {ramp = 'earth', step = 2, h = 0}, -- sombra entre cascalho
        p = {ramp = 'stone', step = 4, h = 2}, -- cascalho
        P = {ramp = 'stone', step = 5, h = 3}, -- pedra clara do miolo
        q = {ramp = 'stone', step = 3, h = 2}, -- cascalho em sombra
        i = {ramp = 'iron', step = 3, h = 2},  -- limalha/aparas
        I = {ramp = 'iron', step = 5, h = 3},  -- metal claro
        r = {ramp = 'rust', step = 3, h = 2},  -- ferrugem
        k = {spec = 'ink', h = 1},             -- trinca da laje
    },

    layers = {
        {
            name = 'entulho',
            h = 1,
            albedo = { entulho(1), entulho(2), entulho(3) },
        },
    },
}
