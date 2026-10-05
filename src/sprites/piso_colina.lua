-- PISO_COLINA — lajes funerárias da Colina dos Sepultados, tile 64x64,
-- origem topleft. Variante fria do piso de laje (docs/
-- DIRECAO_AMBIENTAL_HD.md §COLINA, "o peso contido"): pedra em degraus
-- baixos de valor, juntas em violeta-sombra, musgo jade apagado
-- encostado nas bordas e junções. Nenhum quente — o piso recua sob o
-- luar. h: junta 0, laje 1, filete de lasca 2.

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

-- Traço por waypoints com elo de canto: nenhum vão diagonal, então a
-- junta veda o flood fill 4-conectado das lajes.
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
            set(g, nx, y, ch) -- elo: mantém a linha 4-conectada no cotovelo
            set(g, nx, ny, ch)
            x, y = nx, ny
        end
    end
end

-- Flood fill: pinta a laje que contém (x,y) com o tom ch; 'j' é fronteira.
local function pinta(g, x, y, ch)
    local alvo = g[y][x]
    if alvo == 'j' or alvo == ch then return end
    local stack = { { x, y } }
    while #stack > 0 do
        local p = table.remove(stack)
        local px, py = p[1], p[2]
        if px >= 1 and px <= W and py >= 1 and py <= H and g[py][px] == alvo then
            g[py][px] = ch
            stack[#stack + 1] = { px + 1, py }
            stack[#stack + 1] = { px - 1, py }
            stack[#stack + 1] = { px, py + 1 }
            stack[#stack + 1] = { px, py - 1 }
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

-- Lascas discretas: cunha escura + filete claro apagado (nada de luz
-- dura na colina — 'S' fica em stone.5, não em 6).
local LASCA_A = {
    'ddd.',
    'dd..',
    'd.S.',
    '.SS.',
}
local LASCA_B = {
    '.ddd',
    '..dd',
    '.Sd.',
    '.SS.',
}
local LASCA_C = {
    'Sdd.',
    'ddd.',
    'dd..',
    'd...',
}
-- Musgo apagado: tufos baixos encostados em junta/borda — o verde da
-- colina é memória, não vida.
local MUSGO_A = {
    '.gg..',
    'gGgg.',
    '.gGg.',
    '..g..',
}
local MUSGO_B = {
    'g..g.',
    'Ggg.G',
    '.gGg.',
    'gg...',
}
local MUSGO_C = {
    '.gG.',
    'gGgg',
    'gg.G',
    '.g..',
}

local function laje(spec)
    local g = nova('a')
    for _, j in ipairs(spec.j) do traco(g, j, 'j') end
    for _, t in ipairs(spec.tons) do pinta(g, t[1], t[2], t[3]) end
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

-- Cada variante: j = polilinhas de junta, tons = sementes de flood fill
-- por laje ('a' base, 'l' clara, 'd' sombreada), carimbos = lascas/musgo.
-- Lajes mais retangulares que o piso azul: pedra de cobertura de cova.
local V1 = {
    j = {
        { 1, 16, 14, 16, 28, 15, 44, 17, 63, 16 },
        { 1, 36, 15, 35, 30, 37, 46, 36, 63, 37 },
        { 1, 52, 16, 52, 31, 53, 48, 51, 63, 52 },
        { 22, 1, 22, 15 }, { 46, 1, 45, 16 },
        { 12, 17, 12, 35 }, { 33, 17, 33, 36 }, { 52, 18, 52, 36 },
        { 8, 37, 8, 52 }, { 26, 37, 26, 52 }, { 44, 37, 44, 51 },
        { 17, 53, 17, 63 }, { 38, 52, 38, 63 }, { 55, 52, 55, 63 },
    },
    tons = {
        { 10, 8, 'a' }, { 34, 8, 'd' }, { 55, 8, 'a' },
        { 6, 26, 'd' }, { 22, 26, 'a' }, { 42, 26, 'a' }, { 58, 26, 'a' },
        { 4, 44, 'a' }, { 17, 44, 'a' }, { 35, 44, 'd' }, { 54, 44, 'a' },
        { 8, 58, 'a' }, { 27, 58, 'd' }, { 46, 58, 'a' }, { 60, 58, 'a' },
    },
    carimbos = {
        { 25, 24, LASCA_A }, { 48, 44, LASCA_B },
        { 2, 16, MUSGO_A }, { 50, 34, MUSGO_B }, { 12, 50, MUSGO_C },
        { 58, 60, MUSGO_A }, { 30, 2, MUSGO_C },
    },
}

local V2 = {
    j = {
        { 1, 13, 15, 14, 30, 12, 47, 14, 63, 13 },
        { 1, 33, 13, 34, 28, 32, 45, 34, 63, 33 },
        { 1, 50, 14, 51, 29, 49, 47, 51, 63, 50 },
        { 20, 1, 20, 13 }, { 44, 1, 44, 13 },
        { 10, 14, 10, 33 }, { 31, 15, 31, 33 }, { 50, 15, 50, 33 },
        { 6, 34, 6, 50 }, { 24, 34, 24, 50 }, { 42, 35, 42, 50 },
        { 15, 51, 15, 63 }, { 36, 51, 36, 63 }, { 53, 51, 53, 63 },
    },
    tons = {
        { 8, 6, 'a' }, { 32, 6, 'a' }, { 54, 6, 'a' },
        { 5, 23, 'a' }, { 20, 23, 'd' }, { 40, 23, 'a' }, { 57, 23, 'd' },
        { 3, 42, 'd' }, { 15, 42, 'a' }, { 33, 42, 'a' }, { 52, 42, 'a' },
        { 7, 57, 'a' }, { 25, 57, 'a' }, { 44, 57, 'd' }, { 59, 57, 'a' },
    },
    carimbos = {
        { 38, 40, LASCA_C }, { 14, 20, LASCA_B },
        { 26, 12, MUSGO_B }, { 2, 34, MUSGO_C }, { 44, 32, MUSGO_A },
        { 10, 52, MUSGO_A }, { 56, 48, MUSGO_C },
    },
}

local V3 = {
    j = {
        { 1, 18, 13, 17, 27, 19, 43, 17, 63, 18 },
        { 1, 38, 14, 39, 29, 37, 46, 39, 63, 38 },
        { 1, 55, 15, 54, 32, 56, 49, 54, 63, 55 },
        { 24, 1, 24, 17 }, { 48, 1, 47, 17 },
        { 14, 18, 14, 38 }, { 35, 18, 35, 38 }, { 54, 19, 54, 37 },
        { 10, 39, 10, 54 }, { 28, 39, 28, 55 }, { 46, 40, 46, 54 },
        { 19, 56, 19, 63 }, { 40, 56, 40, 63 }, { 57, 55, 57, 63 },
    },
    tons = {
        { 12, 9, 'd' }, { 36, 9, 'a' }, { 56, 9, 'a' },
        { 7, 28, 'a' }, { 24, 28, 'a' }, { 44, 28, 'd' }, { 59, 28, 'a' },
        { 5, 46, 'a' }, { 19, 46, 'd' }, { 37, 46, 'a' }, { 55, 46, 'a' },
        { 9, 59, 'a' }, { 29, 59, 'a' }, { 48, 59, 'a' }, { 61, 59, 'd' },
    },
    carimbos = {
        { 20, 45, LASCA_A }, { 55, 8, LASCA_C },
        { 34, 18, MUSGO_C }, { 56, 38, MUSGO_A }, { 4, 54, MUSGO_B },
        { 26, 56, MUSGO_A }, { 48, 2, MUSGO_B },
    },
}

local V4 = {
    j = {
        { 1, 14, 16, 15, 31, 13, 48, 15, 63, 14 },
        { 1, 35, 16, 34, 31, 36, 48, 34, 63, 35 },
        { 1, 53, 15, 54, 30, 52, 47, 54, 63, 53 },
        { 21, 1, 21, 14 }, { 45, 1, 44, 14 },
        { 11, 15, 11, 34 }, { 34, 15, 34, 35 }, { 53, 16, 53, 34 },
        { 7, 35, 7, 53 }, { 25, 36, 25, 52 }, { 43, 35, 43, 53 },
        { 16, 54, 16, 63 }, { 37, 54, 37, 63 }, { 56, 54, 56, 63 },
    },
    tons = {
        { 10, 7, 'a' }, { 33, 7, 'a' }, { 55, 7, 'd' },
        { 5, 24, 'd' }, { 22, 24, 'a' }, { 43, 24, 'a' }, { 58, 24, 'a' },
        { 3, 44, 'a' }, { 16, 44, 'a' }, { 34, 44, 'a' }, { 54, 44, 'd' },
        { 8, 58, 'd' }, { 26, 58, 'a' }, { 46, 58, 'a' }, { 60, 58, 'a' },
    },
    carimbos = {
        { 42, 20, LASCA_B }, { 18, 42, LASCA_A },
        { 4, 14, MUSGO_B }, { 52, 34, MUSGO_C }, { 24, 36, MUSGO_A },
        { 60, 2, MUSGO_C }, { 36, 56, MUSGO_B },
    },
}

return {
    name = 'piso_colina',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        j = { ramp = 'violet', step = 2, h = 0 }, -- junta em violeta-sombra
        a = { ramp = 'stone', step = 3, h = 1 },  -- laje base fria
        l = { ramp = 'stone', step = 4, h = 1 },  -- laje clara
        d = { ramp = 'stone', step = 2, h = 1 },  -- laje sombreada / lasca
        S = { ramp = 'stone', step = 5, h = 2 },  -- filete de lasca apagado
        g = { ramp = 'moss', step = 2, h = 1 },   -- musgo apagado
        G = { ramp = 'moss', step = 1, h = 0 },   -- musgo fundo na junta
    },

    -- papel piso-iluminado (docs/PIXEL_KIT.md); a colina escurece pelo
    -- grading regional, a faixa mede o albedo antes dela
    valueBand = { .35, .55 },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { laje(V1), laje(V2), laje(V3), laje(V4) },
        },
    },
}
