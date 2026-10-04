-- PILHA_LENHA — lenha empilhada, prop 64x96, origem nos pés.
-- Quintal da forja (vida-refugio-props §5): toras com cortes claros
-- à mostra — a face serrada de quem abastece o fogo. Empilhado de
-- quem repõe, não de quem cataloga: 2 frames = arranjos por seed
-- (pirâmide 4-3-2 / pilha menor com tora encostada).
-- Relevo: pilha 7-9, chão 1-2.

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

local function faixa(g, x0, x1, y, ch)
    for x = x0, x1 do set(g, x, y, ch) end
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

-- tora vista de frente: anel de casca, face serrada clara, miolo
local TORA = {
    '..vvvvv..',
    '.vUUUUUv.',
    'vUuuuuuUv',
    'vUuuwuuUv',
    'vUuuuuuUv',
    'vUuuuuuUv',
    '.vUUUUUv.',
    '..vvvvv..',
}
-- tora menor/mais escura (fim de tora, sombra)
local TORA_S = {
    '.vvvvv.',
    'vUUUUUv',
    'vUuuuUv',
    'vUuuuUv',
    'vUUUUUv',
    '.vvvvv.',
}

local function frame1()
    local g = nova('.')
    -- pirâmide honesta: 4 embaixo, 3 no meio, 2 no topo
    carimbo(g, 6, 66, TORA); carimbo(g, 17, 66, TORA)
    carimbo(g, 28, 66, TORA); carimbo(g, 39, 66, TORA)
    carimbo(g, 11, 57, TORA); carimbo(g, 22, 57, TORA)
    carimbo(g, 33, 57, TORA)
    carimbo(g, 17, 48, TORA); carimbo(g, 28, 48, TORA)
    -- tora miúda fechando o topo
    carimbo(g, 23, 41, TORA_S)
    -- fundo entre as toras
    for y = 58, 73 do
        for x = 6, 47 do
            if g[y][x] == '.' and h2(x, y, 3) < 18 then
                set(g, x, y, 'k')
            end
        end
    end
    -- tora tombada na frente, fora da pilha
    carimbo(g, 48, 78, TORA_S)
    carimbo(g, 50, 86, TORA_S)
    return str(g)
end

local function frame2()
    local g = nova('.')
    -- pilha menor: 3 embaixo, 2 no meio, tora encostada na lateral
    carimbo(g, 8, 66, TORA); carimbo(g, 19, 66, TORA)
    carimbo(g, 30, 66, TORA)
    carimbo(g, 13, 57, TORA); carimbo(g, 24, 57, TORA)
    carimbo(g, 19, 48, TORA_S)
    for y = 58, 73 do
        for x = 8, 38 do
            if g[y][x] == '.' and h2(x, y, 5) < 18 then
                set(g, x, y, 'k')
            end
        end
    end
    -- a encostada: diagonal contra a pilha
    for i = 0, 18 do
        local x = 43 + math.floor(i * 0.5)
        local y = 62 + i
        faixa(g, x, x + 3, y, i % 4 == 0 and 'U' or 'w')
        set(g, x + 4, y, 'v')
    end
    -- corte da encostada em cima
    faixa(g, 43, 47, 61, 'U'); set(g, 44, 60, 'U'); set(g, 45, 59, 'W')
    return str(g)
end

local function chao(seed)
    local g = nova('.')
    for y = 76, 96 do
        for x = 4, 60 do
            if h2(x, y, seed) < 30 then
                set(g, x, y, h2(x, y, seed * 3) < 45 and 'e' or 'd')
            end
        end
    end
    -- aparas e lascas de quem rachou lenha ali
    set(g, 10 + seed * 5, 84, 'U'); set(g, 14 + seed * 5, 85, 'v')
    set(g, 40, 88, 'U'); set(g, 52, 90, 'v')
    set(g, 24, 90, 'd'); set(g, 34, 92, 'e')
    return str(g)
end

return {
    name = 'pilha_lenha',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 5},              -- fundo entre toras
        v = {ramp = 'wood', step = 2, h = 7},   -- casca
        u = {ramp = 'wood', step = 3, h = 7},
        w = {ramp = 'wood', step = 4, h = 8},   -- corpo
        U = {ramp = 'wood', step = 6, h = 9},   -- face serrada clara
        W = {ramp = 'wood', step = 7, h = 9},   -- luz no corte
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        { name = 'pilha', h = 8, albedo = { frame1(), frame2() } },
        { name = 'chao',  h = 1, albedo = { chao(1), chao(2) } },
    },
}
