-- FLORES_ADRO — touceiras de flor sobre o caminho, tile 64x64, topleft.
-- Adro da capela (vida-refugio-props §6): a pausa — flores que crescem
-- para a lateral e pendem sobre o caminho de terra, não em canteiro.
-- Manchas de grama na borda, miolo de caminho limpo no centro.
-- 2 frames = variantes: f1 inclina para a direita, f2 para a esquerda.
-- h: caminho 0-1, grama 2, touceira 3, flor 4.

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

-- carimbo com curinga de flor: 'X' vira a cor da flor escolhida
local function tufa(g, x, y, forma, flor)
    for j = 1, #forma do
        local linha = forma[j]
        for i = 1, #linha do
            local c = linha:sub(i, i)
            if c == 'X' then set(g, x + i - 1, y + j - 1, flor)
            elseif c ~= '.' then set(g, x + i - 1, y + j - 1, c) end
        end
    end
end

-- touceira inclinada p/ direita: a flor vai na ponta, sobre o caminho
local TUF_D = {
    '........XX..',
    '.......ggg..',
    '......gggX..',
    '.....gggg...',
    '....gGggg...',
    '...gGGgg....',
    '..gGGGgg....',
    '.gGGGGg.....',
    'GGGGGG......',
}
-- mesma touceira inclinada p/ esquerda
local TUF_E = {
    '..XX........',
    '..ggg.......',
    '..Xggg......',
    '...gggg.....',
    '...gggGg....',
    '....ggGGg...',
    '....ggGGGg..',
    '.....gGGGGg.',
    '......GGGGGG',
}
local TUF_PQ = {
    '...XX..',
    '..ggg..',
    '.gGgg..',
    'GGGg...',
}

local function flores(seed)
    local g = nova('e')
    -- grama da borda: manchas moles no topo e laterais, caminho limpo
    for y = 1, H do
        for x = 1, W do
            local campo = math.sin(x * 0.21 + seed) + math.sin(y * 0.24 + seed * 2)
            local borda = y < 30 or x < 14 or x > 52
            if borda and campo > 0.5 then
                g[y][x] = campo > 1.3 and 'g' or 'G'
            elseif not borda and h2(x, y, seed) < 4 then
                g[y][x] = 'd'
            end
        end
    end
    -- touceiras na divisa grama/caminho, deitando para o lado aberto
    if seed == 1 then
        tufa(g, 10, 14, TUF_D, 'f')
        tufa(g, 30, 10, TUF_D, 'o')
        tufa(g, 46, 18, TUF_D, 'i')
        tufa(g, 22, 30, TUF_PQ, 'f')
        tufa(g, 54, 34, TUF_PQ, 'o')
    else
        tufa(g, 14, 12, TUF_E, 'o')
        tufa(g, 34, 16, TUF_E, 'f')
        tufa(g, 50, 10, TUF_E, 'i')
        tufa(g, 24, 28, TUF_PQ, 'o')
        tufa(g, 8, 36, TUF_PQ, 'f')
    end
    -- flores soltas e pétalas caídas no caminho
    local soltas = seed == 1
        and { {26, 26, 'f'}, {42, 40, 'o'}, {18, 44, 'i'}, {52, 28, 'f'} }
        or  { {30, 24, 'o'}, {44, 38, 'f'}, {14, 30, 'i'}, {36, 46, 'f'} }
    for _, s in ipairs(soltas) do set(g, s[1], s[2], s[3]) end
    return str(g)
end

return {
    name = 'flores_adro',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        e = {ramp = 'earth', step = 4, h = 1}, -- caminho
        d = {ramp = 'earth', step = 3, h = 0}, -- desgaste do caminho
        g = {ramp = 'moss', step = 3, h = 3},  -- touceira
        G = {ramp = 'moss', step = 2, h = 2},  -- grama/touceira, sombra
        f = {ramp = 'bone', step = 6, h = 4},  -- flor branca
        o = {ramp = 'gold', step = 6, h = 4},  -- flor de ouro
        i = {ramp = 'violet', step = 6, h = 4},-- flor violeta
    },

    layers = {
        {
            name = 'flores',
            h = 1,
            albedo = { flores(1), flores(2) },
        },
    },
}
