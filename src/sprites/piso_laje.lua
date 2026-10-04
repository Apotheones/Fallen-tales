-- PISO_LAJE — lajes de pedra azul, tile 64x64, origem topleft.
-- Fase 1 TILES (docs/MEGAPLAN_VISUAL_HD.md §4-5). 4 frames = 4 variantes
-- de seed: cada uma redesenha placas e juntas, não embaralha ruído.
-- Placas irregulares DESENHADAS: juntas poligonais por traço 4-conectado,
-- tom de cada laje por flood fill, lascas em carimbo com filete claro.
-- Valor baixo e contraste calmo — o piso recua. h: junta 0, laje 1, fio
-- de desgaste 2.

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

-- Carimbo de lasca/mancha: '.' é transparente no desenho.
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

-- Lascas: entalhe escuro na laje + filete claro na aresta oposta.
local LASCA_A = { 'dd.', 'd.s' }
local LASCA_B = { '.dd', 'sd.' }
local LASCA_C = { 'sd', 'dd' }
-- Fio de desgaste: topo da laje lavado pela luz (h=2, bem raro).
local FIO = { 'sss' }
local FIO2 = { '.ss' }

local function laje(spec)
    local g = nova('a')
    for _, j in ipairs(spec.j) do traco(g, j, 'j') end
    for _, t in ipairs(spec.tons) do pinta(g, t[1], t[2], t[3]) end
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

-- Cada variante: j = polilinhas de junta, tons = sementes de flood fill
-- por laje ('a' base, 'l' clara, 'd' sombreada), carimbos = lascas/fios.
local V1 = {
    j = {
        { 1, 14, 12, 14, 21, 13, 31, 15, 45, 14, 63, 15 },
        { 1, 32, 14, 31, 25, 33, 39, 32, 51, 34, 63, 33 },
        { 1, 48, 11, 47, 25, 49, 38, 48, 51, 46, 63, 47 },
        { 23, 1, 23, 13 }, { 47, 1, 46, 14 },
        { 15, 14, 16, 31 }, { 37, 15, 36, 32 }, { 55, 15, 54, 33 },
        { 9, 32, 9, 47 }, { 30, 33, 30, 48 }, { 50, 34, 50, 46 },
        { 20, 49, 20, 63 }, { 41, 48, 40, 63 }, { 57, 47, 57, 63 },
    },
    tons = {
        { 12, 7, 'a' }, { 35, 7, 'l' }, { 56, 7, 'a' },
        { 7, 23, 'a' }, { 26, 23, 'd' }, { 45, 23, 'a' }, { 59, 23, 'a' },
        { 4, 40, 'a' }, { 19, 40, 'a' }, { 40, 40, 'l' }, { 57, 40, 'd' },
        { 10, 56, 'd' }, { 30, 56, 'a' }, { 49, 56, 'a' }, { 61, 56, 'a' },
    },
    carimbos = {
        { 18, 22, LASCA_A }, { 44, 54, LASCA_B }, { 33, 38, LASCA_C },
        { 27, 6, FIO }, { 51, 27, FIO2 }, { 6, 44, FIO2 },
    },
}

local V2 = {
    j = {
        { 1, 11, 16, 11, 28, 13, 42, 12, 55, 14, 63, 13 },
        { 1, 28, 13, 29, 26, 27, 40, 29, 52, 28, 63, 30 },
        { 1, 45, 15, 46, 27, 44, 41, 46, 54, 45, 63, 46 },
        { 1, 58, 20, 57, 36, 59, 50, 58, 63, 59 },
        { 30, 1, 30, 12 }, { 52, 1, 51, 13 },
        { 10, 11, 11, 28 }, { 44, 13, 43, 28 }, { 57, 14, 58, 29 },
        { 22, 29, 22, 45 }, { 47, 30, 46, 45 },
        { 12, 46, 13, 57 }, { 33, 46, 33, 58 }, { 50, 46, 49, 57 },
    },
    tons = {
        { 15, 6, 'a' }, { 40, 6, 'a' }, { 58, 6, 'd' },
        { 6, 20, 'a' }, { 27, 20, 'a' }, { 51, 20, 'l' }, { 61, 20, 'a' },
        { 11, 37, 'd' }, { 34, 37, 'a' }, { 55, 37, 'a' },
        { 7, 52, 'a' }, { 23, 52, 'a' }, { 41, 52, 'd' }, { 56, 52, 'a' },
        { 10, 61, 'a' }, { 28, 61, 'l' }, { 45, 61, 'a' }, { 58, 61, 'a' },
    },
    carimbos = {
        { 36, 18, LASCA_B }, { 16, 50, LASCA_C }, { 54, 52, LASCA_A },
        { 7, 24, FIO }, { 48, 37, FIO }, { 30, 61, FIO2 },
    },
}

local V3 = {
    j = {
        { 1, 16, 10, 15, 22, 17, 34, 15, 48, 17, 63, 16 },
        { 1, 35, 12, 34, 24, 36, 37, 35, 49, 37, 63, 36 },
        { 1, 52, 14, 53, 28, 51, 42, 53, 55, 52, 63, 53 },
        { 18, 1, 17, 15 }, { 41, 1, 42, 15 },
        { 8, 16, 8, 34 }, { 28, 17, 29, 35 }, { 51, 17, 50, 36 },
        { 18, 36, 18, 52 }, { 38, 36, 39, 52 }, { 56, 37, 55, 52 },
        { 10, 53, 11, 63 }, { 30, 52, 30, 63 }, { 47, 53, 48, 63 },
    },
    tons = {
        { 9, 8, 'a' }, { 30, 8, 'd' }, { 53, 8, 'a' },
        { 4, 25, 'a' }, { 18, 25, 'a' }, { 40, 25, 'a' }, { 57, 25, 'l' },
        { 9, 44, 'a' }, { 28, 44, 'd' }, { 48, 44, 'a' }, { 60, 44, 'a' },
        { 6, 58, 'a' }, { 21, 58, 'a' }, { 39, 58, 'a' }, { 56, 58, 'd' },
    },
    carimbos = {
        { 24, 24, LASCA_C }, { 58, 42, LASCA_A }, { 12, 58, LASCA_B },
        { 46, 8, FIO }, { 33, 45, FIO2 }, { 59, 26, FIO2 },
    },
}

local V4 = {
    j = {
        { 1, 9, 14, 10, 27, 8, 40, 10, 54, 9, 63, 10 },
        { 1, 25, 15, 26, 29, 24, 43, 26, 56, 25, 63, 26 },
        { 1, 40, 12, 41, 26, 39, 40, 41, 53, 40, 63, 41 },
        { 1, 55, 16, 54, 30, 56, 44, 55, 57, 56, 63, 55 },
        { 20, 1, 21, 9 }, { 45, 1, 44, 9 },
        { 12, 10, 13, 25 }, { 34, 10, 33, 25 }, { 55, 10, 54, 25 },
        { 8, 26, 8, 40 }, { 27, 26, 28, 40 }, { 46, 26, 45, 40 }, { 60, 26, 60, 40 },
        { 18, 41, 19, 54 }, { 36, 41, 35, 55 }, { 52, 41, 53, 55 },
    },
    tons = {
        { 10, 5, 'd' }, { 32, 5, 'a' }, { 55, 5, 'a' },
        { 6, 17, 'a' }, { 24, 17, 'a' }, { 44, 17, 'a' }, { 59, 17, 'd' },
        { 4, 33, 'a' }, { 18, 33, 'l' }, { 37, 33, 'a' }, { 53, 33, 'a' }, { 62, 33, 'a' },
        { 9, 48, 'a' }, { 28, 48, 'a' }, { 44, 48, 'd' }, { 58, 48, 'a' },
        { 8, 60, 'a' }, { 27, 60, 'a' }, { 44, 60, 'a' }, { 58, 60, 'l' },
    },
    carimbos = {
        { 47, 18, LASCA_A }, { 22, 32, LASCA_B }, { 6, 48, LASCA_C },
        { 14, 60, FIO }, { 38, 33, FIO2 }, { 59, 5, FIO },
    },
}

return {
    name = 'piso_laje',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        j = { ramp = 'stone', step = 1, h = 0 }, -- junta rebaixada
        a = { ramp = 'stone', step = 3, h = 1 }, -- laje base
        l = { ramp = 'stone', step = 4, h = 1 }, -- laje clara
        d = { ramp = 'stone', step = 2, h = 1 }, -- laje sombreada / lasca
        s = { ramp = 'stone', step = 5, h = 2 }, -- fio de desgaste
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { laje(V1), laje(V2), laje(V3), laje(V4) },
        },
    },
}
