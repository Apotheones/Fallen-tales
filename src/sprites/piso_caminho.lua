-- PISO_CAMINHO — caminho claro desgastado, tile 64x64, origem topleft.
-- 4 frames = variantes de seed. Terra clara pisada com faixa central de
-- desgaste, bordas orgânicas invadidas por mato/terra escura nas
-- laterais, pegadas em pares e sulcos sutis de carroça. h: pegada 0,
-- massa 1, pedrinha 2.
-- v2: os sulcos corriam o tile inteiro de ponta a ponta e liam "listrado"
-- — agora são segmentos longos e irregulares com vãos, retomando
-- deslocados e puxando diagonal curta aqui e ali.

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

local function traco(g, pts, ch)
    for i = 1, #pts - 2, 2 do
        local x0, y0, x1, y1 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
        local dx, dy = math.abs(x1 - x0), math.abs(y1 - y0)
        local sx = x0 <= x1 and 1 or -1
        local sy = y0 <= y1 and 1 or -1
        local x, y, err = x0, y0, dx - dy
        set(g, x, y, ch)
        while x ~= x1 or y ~= y1 do
            local e2 = 2 * err
            local nx, ny = x, y
            if e2 > -dy then err = err - dy; nx = nx + sx end
            if e2 < dx then err = err + dx; ny = ny + sy end
            set(g, nx, y, ch)
            set(g, nx, ny, ch)
            x, y = nx, ny
        end
    end
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

-- Bordas orgânicas: terra escura ('d') avançando com grama ('g') na
-- ponta — o caminho não é uma faixa geométrica, é um hábito.
local BORDA_E1 = { -- invasão vinda da esquerda
    'dd....',
    'dddg..',
    'gddg..',
    'ddg...',
    'dd....',
    'd.....',
}
local BORDA_E2 = {
    'd.....',
    'dd....',
    'gddg..',
    'ddd...',
    'dd....',
    'd.....',
}
local BORDA_D1 = { -- invasão vinda da direita
    '...ddd',
    '..gddd',
    '..gddg',
    '...gdd',
    '....dd',
    '.....d',
}
local BORDA_D2 = {
    '.....d',
    '....dd',
    '..gddg',
    '...ddd',
    '....dd',
    '.....d',
}
-- Desgaste central: barro claro lavado pelo uso.
local GASTO_A = {
    '...bbbbb....',
    '..bbbbbbb...',
    '.bbbbbbbbb..',
    'bbbbbbbbbb..',
    '.bbbbbbbbb..',
    '..bbbbbbb...',
}
local GASTO_B = {
    '..bbbb..',
    '.bbbbbb.',
    'bbbbbbb.',
    '.bbbbbb.',
    '..bbbb..',
}
-- Pegada: par de solas em zigue-zague descendo a trilha.
local PEGADA = {
    'e.....',
    'e.....',
    '....e.',
    '....e.',
    'e.....',
    'e.....',
    '....e.',
    '....e.',
}
local PEGADA2 = {
    '...e..',
    '...e..',
    'e.....',
    'e.....',
    '...e..',
    '...e..',
    'e.....',
    'e.....',
}
local PEDRA_A = {
    '.pp.',
    'pppd',
    '.dd.',
}
local PEDRA_B = {
    'pp',
    'pd',
}
local MATO = { -- tufo de grama invadindo a borda
    '.g.',
    'gug',
    'd.d',
}

local function caminho(spec)
    local g = nova('a')
    for _, s in ipairs(spec.sulcos) do traco(g, s, 'd') end
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

local V1 = {
    sulcos = {
        { 24, 2, 23, 9, 25, 15, 24, 20 },        -- sulco esq, trecho 1
        { 26, 27, 24, 33, 25, 39 },              -- retoma deslocado
        { 23, 47, 25, 53, 24, 59 },              -- trecho 3
        { 40, 4, 42, 10, 40, 15 },               -- sulco dir, trecho 1
        { 41, 23, 39, 30, 41, 36, 40, 41 },      -- retoma com cotovelo
        { 42, 49, 40, 55, 42, 61 },              -- trecho 3
        { 30, 20, 34, 24 },                      -- escoriação diagonal curta
        { 48, 42, 52, 46 },                      -- diagonal curta
    },
    carimbos = {
        { 1, 6, BORDA_E1 }, { 58, 18, BORDA_D1 }, { 1, 42, BORDA_E2 },
        { 57, 50, BORDA_D2 }, { 1, 24, MATO }, { 60, 36, MATO },
        { 26, 4, GASTO_A }, { 24, 46, GASTO_B },
        { 30, 18, PEGADA }, { 28, 34, PEGADA2 },
        { 50, 8, PEDRA_A }, { 12, 34, PEDRA_B }, { 46, 58, PEDRA_B },
    },
}

local V2 = {
    sulcos = {
        { 20, 3, 22, 11, 21, 17 },
        { 22, 25, 20, 31, 22, 38 },
        { 21, 48, 22, 55, 21, 61 },
        { 44, 2, 43, 9, 45, 15 },
        { 43, 22, 45, 29, 44, 35 },
        { 45, 43, 43, 50, 45, 57, 44, 62 },
        { 14, 34, 18, 38 },                      -- diagonal curta
        { 34, 8, 38, 12 },                       -- diagonal curta
    },
    carimbos = {
        { 56, 8, BORDA_D2 }, { 1, 30, BORDA_E1 }, { 58, 44, BORDA_D1 },
        { 1, 56, BORDA_E2 }, { 1, 12, MATO }, { 61, 28, MATO },
        { 28, 24, GASTO_A }, { 34, 54, GASTO_B },
        { 32, 6, PEGADA2 }, { 30, 38, PEGADA },
        { 10, 18, PEDRA_B }, { 52, 34, PEDRA_A }, { 14, 50, PEDRA_B },
    },
}

local V3 = {
    sulcos = {
        { 28, 2, 27, 8, 29, 14, 28, 19 },
        { 27, 27, 29, 33, 27, 38 },
        { 29, 46, 28, 53, 29, 60 },
        { 36, 4, 37, 10, 35, 15 },
        { 37, 24, 35, 31, 37, 36 },
        { 35, 44, 37, 51, 36, 58 },
        { 42, 30, 46, 34 },                      -- diagonal curta
        { 22, 52, 26, 56 },                      -- diagonal curta
    },
    carimbos = {
        { 1, 16, BORDA_E2 }, { 57, 6, BORDA_D1 }, { 59, 38, BORDA_D2 },
        { 1, 52, BORDA_E1 }, { 61, 54, MATO }, { 1, 38, MATO },
        { 30, 30, GASTO_B }, { 22, 8, GASTO_B },
        { 30, 50, PEGADA }, { 32, 16, PEGADA2 },
        { 48, 22, PEDRA_A }, { 8, 8, PEDRA_B }, { 54, 58, PEDRA_B },
    },
}

local V4 = {
    sulcos = {
        { 18, 3, 19, 10, 17, 16 },
        { 19, 24, 17, 30, 18, 36 },
        { 18, 44, 19, 51, 17, 58 },
        { 46, 2, 45, 9, 47, 14 },
        { 45, 22, 47, 28, 46, 34 },
        { 46, 42, 45, 49, 46, 56 },
        { 36, 12, 40, 16 },                      -- diagonal curta
        { 28, 40, 32, 44 },                      -- diagonal curta
    },
    carimbos = {
        { 58, 12, BORDA_D2 }, { 1, 8, BORDA_E1 }, { 1, 34, BORDA_E2 },
        { 56, 56, BORDA_D1 }, { 60, 44, MATO }, { 2, 20, MATO },
        { 24, 18, GASTO_A }, { 36, 44, GASTO_B },
        { 26, 34, PEGADA }, { 30, 4, PEGADA2 }, { 34, 54, PEGADA },
        { 44, 30, PEDRA_B }, { 10, 48, PEDRA_A }, { 56, 4, PEDRA_B },
    },
}

return {
    name = 'piso_caminho',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        a = { ramp = 'earth', step = 5, h = 1 }, -- barro claro pisado
        b = { ramp = 'earth', step = 6, h = 1 }, -- desgaste lavado
        d = { ramp = 'earth', step = 3, h = 1 }, -- borda escura / sulco
        e = { ramp = 'earth', step = 2, h = 0 }, -- pegada / sulco fundo
        g = { ramp = 'moss', step = 3, h = 1 },  -- grama invadindo
        u = { ramp = 'moss', step = 4, h = 2 },  -- lâmina do tufo de borda
        p = { ramp = 'stone', step = 4, h = 2 }, -- pedrinha do caminho
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { caminho(V1), caminho(V2), caminho(V3), caminho(V4) },
        },
    },
}
