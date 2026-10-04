-- MURETA_ADRO — mureta baixa de pedra, tile 64x64, origem topleft.
-- Adro da capela (vida-refugio-props §6): mureta de delimitação baixa,
-- cap claro com filete de uso — o trecho polido onde a mão sempre
-- passa ao entrar. Musgo na base do lado de sombra.
-- 2 frames: f1 reto (atravessa o tile) / f2 canto (desce pelo tile).
-- h: base 3, face 5-6, cap 8, filete 9.

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

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- fiada da face: junta horizontal a cada 5 linhas, juntas verticais
-- deslocadas por banda, pedra clara esparsa
local function tijolo(x, y, y0)
    local banda = math.floor((y - y0) / 5)
    if (y - y0) % 5 == 3 then return 'm' end
    if (x + banda * 4) % 7 == 0 then return 'm' end
    if h2(x, y, 5) < 10 then return 'a' end
    return 'b'
end

-- faixa horizontal: cap de 3 linhas + face + base de sombra
local function faixa_h(g, x0, x1, y0, seed)
    for x = x0, x1 do
        set(g, x, y0, 'C')
        set(g, x, y0 + 1, 'S'); set(g, x, y0 + 2, 's')
        for y = y0 + 3, y0 + 12 do set(g, x, y, tijolo(x, y, y0 + 3)) end
        set(g, x, y0 + 13, 'd'); set(g, x, y0 + 14, 'd')
    end
    -- filete de uso: trecho do cap polido pela mão
    local f0 = x0 + 14 + (seed % 3) * 4
    for x = f0, f0 + 18 do
        if h2(x, seed, 7) < 80 then
            set(g, x, y0 + 1, 'l'); set(g, x, y0 + 2, 'l')
        end
    end
    -- musgo rente à base
    for x = x0 + 2, x1 - 2 do
        if h2(x, y0, seed) < 22 then
            set(g, x, y0 + 15, 'G'); set(g, x + 1, y0 + 14, 'g')
        end
    end
end

-- faixa vertical (o canto desce): cap à esquerda (luz do SO), face,
-- sombra à direita — a mureta girando para dentro do adro
local function faixa_v(g, y0, y1, x0, seed)
    for y = y0, y1 do
        set(g, x0, y, 'C'); set(g, x0 + 1, y, 'S'); set(g, x0 + 2, y, 's')
        for x = x0 + 3, x0 + 7 do
            set(g, x, y, tijolo(y, x, x0 + 3))
        end
        set(g, x0 + 8, y, 'd')
    end
    -- musgo na face de sombra
    for y = y0 + 4, y1 do
        if h2(y, x0, seed) < 20 then set(g, x0 + 9, y, 'G') end
    end
end

local function reto()
    local g = nova('.')
    faixa_h(g, 0, 63, 24, 1)
    -- fim de linha: pedra de fecho à esquerda, um pouco maior
    for y = 22, 42 do
        for x = 0, 3 do
            set(g, x, y, y < 25 and 'S' or (h2(x, y, 3) < 15 and 'a' or 'b'))
        end
    end
    return str(g)
end

local function canto()
    local g = nova('.')
    faixa_h(g, 0, 40, 24, 2)
    faixa_v(g, 26, 63, 36, 2)
    -- o canto: bloco de esquina mais alto e gasto
    for y = 22, 42 do
        for x = 34, 44 do
            if x < 41 or y < 27 then
                set(g, x, y, (y < 25 and 'C') or (y < 27 and 'S')
                    or (h2(x, y, 4) < 12 and 'a' or 'b'))
            end
        end
    end
    -- filete de uso contorna o canto
    for x = 30, 40 do set(g, x, 26, 'l') end
    for y = 28, 38 do set(g, 37, y, 'l') end
    return str(g)
end

return {
    name = 'mureta_adro',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        C = {ramp = 'stone', step = 7, h = 8}, -- fio claro do cap
        S = {ramp = 'stone', step = 6, h = 8}, -- cap
        s = {ramp = 'stone', step = 5, h = 8}, -- cap, degrau abaixo
        l = {ramp = 'stone', step = 8, h = 9}, -- filete de uso polido
        b = {ramp = 'stone', step = 4, h = 6}, -- pedra da face
        a = {ramp = 'stone', step = 5, h = 6}, -- pedra clara alternada
        m = {ramp = 'stone', step = 2, h = 5}, -- junta
        d = {ramp = 'stone', step = 1, h = 3}, -- base em sombra
        g = {ramp = 'moss', step = 3, h = 3},  -- musgo
        G = {ramp = 'moss', step = 2, h = 2},  -- musgo, sombra
    },

    layers = {
        {
            name = 'mureta',
            h = 6,
            albedo = { reto(), canto() },
        },
    },
}
