-- SERRAGEM — decalque de piso, 64x64, origem topleft.
-- Oficina do Refúgio (nota vida-refugio-props §10): mancha de serragem
-- que nunca se varre de uma vez — terra clara/palha com borda DIFUSA
-- desenhada (densidade cai em degraus irregulares, não em gradiente).
-- SEM colisão e SEM relevo: toda a legend fica em h=0, o normal sai
-- plano. 2 frames = 2 manchas por seed.

local W, H = 64, 64

local function nova()
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = '.' end
        g[y] = r
    end
    return g
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

-- Jitter determinístico por posição (nada de math.random: variação por
-- seed = frames diferentes, nunca por quadro).
local function hash(x, y, s)
    return (x * 7 + y * 13 + s * 29) % 17 / 17
end

-- Mancha: núcleo denso 's', meio 'e', orla esparsa 'f' e alguns grãos
-- escuros 'd' misturados. Elipse deformada por hash.
local function mancha(cx, cy, rx, ry, seed)
    local g = nova()
    for y = 1, H do
        for x = 1, W do
            local dx = (x - cx) / rx
            local dy = (y - cy) / ry
            local d = dx * dx + dy * dy
            local n = hash(x, y, seed)
            local lim = 0.62 + n * 0.55
            if d < lim then
                local ch
                if d < 0.18 then
                    ch = 's'
                elseif d < 0.45 then
                    ch = n < 0.75 and 's' or 'e'
                elseif d < 0.8 then
                    ch = n < 0.6 and 'e' or 'f'
                else
                    ch = n < 0.45 and 'f' or '.'
                end
                if ch ~= '.' and d > 0.1 and hash(y, x, seed) < 0.08 then
                    ch = 'd'    -- grão mais escuro/cavaco
                end
                g[y][x] = ch
            end
        end
    end
    -- aparas maiores fora da mancha: traços curtos soltos
    local aparas = {
        { cx - rx - 3, cy - 2, 3 }, { cx + rx + 1, cy + 4, 4 },
        { cx - rx - 2, cy + 6, 2 }, { cx + rx + 3, cy - 5, 2 },
        { cx + 4, cy + ry + 2, 3 }, { cx - 6, cy + ry + 1, 2 },
        { cx - 2, cy - ry - 2, 2 },
    }
    for i, a in ipairs(aparas) do
        for j = 0, a[3] - 1 do
            local x, y = a[1] + j, a[2]
            if x >= 1 and x <= W and y >= 1 and y <= H then
                g[y][x] = i % 3 == 0 and 'e' or 'f'
            end
        end
    end
    return str(g)
end

return {
    name = 'serragem',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        s = { ramp = 'earth', step = 6, h = 0 },  -- palha/serragem clara
        e = { ramp = 'earth', step = 5, h = 0 },  -- meio-tom
        f = { ramp = 'wood', step = 6, h = 0 },   -- apara de madeira
        d = { ramp = 'earth', step = 3, h = 0 },  -- grão escuro/cavaco
    },

    layers = {
        {
            name = 'decalque',
            h = 0,
            albedo = {
                mancha(30, 34, 20, 14, 1),
                mancha(34, 30, 16, 18, 7),
            },
        },
    },
}
