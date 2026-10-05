-- V01_LAJE — pavimento de lajedo irregular da praça/mirante, re-autoria.
-- Tile 64x64, topleft, 4 frames = variantes (frameUse='variant').
-- Crazy paving: juntas 'j' sinuosas em polilinha 4-conectada fecham
-- lajes de 12-22 px; cada laje recebe tom próprio por flood fill; a
-- quina topo-esquerda de cada laje pega um filete claro 'L' e a base
-- direita assenta em 'k' — relevo de pedra assentada, não malha plana.
-- Juntas são terra compactada (barro entre pedras = praça gasta de
-- povoado), com musgo raro 'g' nos nós e lasca 'k' ocasional.
-- h: junta 0, laje 1, filete 2.
local K = require 'src.pixel_kit'

local W, H = 64, 64

-- Polilinha com elo de canto: nenhum vão diagonal, a junta veda o
-- flood fill 4-conectado das lajes.
local function traco4(g, pts, c, mask)
    for i = 1, #pts - 2, 2 do
        local x0, y0, x1, y1 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
        local dx, dy = math.abs(x1 - x0), math.abs(y1 - y0)
        local sx = x0 <= x1 and 1 or -1
        local sy = y0 <= y1 and 1 or -1
        local x, y, err = x0, y0, dx - dy
        K.pixel(g, x, y, c, mask)
        while x ~= x1 or y ~= y1 do
            local e2 = 2 * err
            local nx, ny = x, y
            if e2 > -dy then err = err - dy; nx = nx + sx end
            if e2 < dx then err = err + dx; ny = ny + sy end
            K.pixel(g, nx, y, c, mask)  -- elo: 4-conexo no cotovelo
            K.pixel(g, nx, ny, c, mask)
            x, y = nx, ny
        end
    end
end

local function blob(g, cx, cy, rx, ry, c, rng, mask)
    local pts, n = {}, 8
    for i = 0, n - 1 do
        local a = i / n * math.pi * 2
        local j = 0.72 + rng.float() * 0.5
        pts[#pts + 1] = math.floor(cx + math.cos(a) * rx * j + 0.5)
        pts[#pts + 1] = math.floor(cy + math.sin(a) * ry * j + 0.5)
    end
    K.polygon(g, pts, c, mask)
end

-- Linha sinuosa entre dois pontos: waypoints a cada ~10px com jitter.
local function sinuosa(x0, y0, x1, y1, amp, rng)
    local pts = { x0, y0 }
    local n = math.max(2, math.floor((math.abs(x1 - x0)
        + math.abs(y1 - y0)) / 10))
    for i = 1, n - 1 do
        local t = i / n
        pts[#pts + 1] = math.floor(x0 + (x1 - x0) * t
            + rng.int(-amp, amp) + .5)
        pts[#pts + 1] = math.floor(y0 + (y1 - y0) * t
            + rng.int(-amp, amp) + .5)
    end
    pts[#pts + 1] = x1; pts[#pts + 1] = y1
    return pts
end

local function laje(seed)
    local rng = K.rng('v01_laje', seed)
    local g = K.new(W, H)
    K.rect(g, 1, 1, W, H, 's')
    -- 3 juntas horizontais sinuosas atravessando o tile
    local rows = {}
    for _, y in ipairs({ 14 + rng.int(-2, 2), 31 + rng.int(-3, 3),
        47 + rng.int(-2, 3) }) do
        traco4(g, sinuosa(1, y, W, y, 3, rng), 'j')
        rows[#rows + 1] = y
    end
    -- juntas verticais curtas por faixa (desencontradas entre faixas)
    local faixas = { { 1, rows[1] }, { rows[1], rows[2] },
        { rows[2], rows[3] }, { rows[3], H } }
    for bi, faixa in ipairs(faixas) do
        local nv = rng.int(2, 3)
        for _ = 1, nv do
            local x = rng.int(10, W - 10)
            local y0 = math.max(1, faixa[1] + rng.int(-2, 0))
            local y1 = math.min(H, faixa[2] + rng.int(0, 2))
            traco4(g, sinuosa(x, y0, x + rng.int(-4, 4), y1, 2, rng), 'j')
        end
    end
    -- tom por laje: UM tom por componente 's' (laje), via sel_component —
    -- fill de 's' para 's' seria no-op e vazaria para a laje vizinha.
    local tons = { 's', 's', 'S', 'S', 'w', 'w', 'V' } -- sol gasta algumas, sombra outras
    local marcada = K.new(W, H)
    for y = 1, H do for x = 1, W do
        if K.get(g, x, y) == 's' and K.get(marcada, x, y) == '.' then
            local comp = K.sel_component(g, x, y)
            local tom = rng.pick(tons)
            for yy = 1, H do for xx = 1, W do
                if K.get(comp, xx, yy) ~= '.' then
                    marcada.rows[yy][xx] = 'x'
                    if tom ~= 's' then K.pixel(g, xx, yy, tom) end
                end
            end end
        end
    end end
    -- filete claro na quina topo-esquerda e assento escuro na base
    -- direita de cada laje — relevo de pedra assentada.
    local rr = K.rng('v01_laje_borda', seed)
    for y = 1, H do for x = 1, W do
        local ch = K.get(g, x, y)
        if ch == 's' or ch == 'S' or ch == 'w' then
            local n = K.get(g, x, y - 1)
            local o = K.get(g, x - 1, y)
            local s2 = K.get(g, x, y + 1)
            local l = K.get(g, x + 1, y)
            if (n == 'j' or o == 'j') and rr.chance(.55) then
                K.pixel(g, x, y, 'L')
            elseif (s2 == 'j' or l == 'j') and rr.chance(.45) then
                K.pixel(g, x, y, 'k')
            end
        end
    end end
    -- terra pisada nos nós das juntas + musgo raro
    for y = 2, H - 1 do for x = 2, W - 1 do
        if K.get(g, x, y) == 'j' then
            local cruz = (K.get(g, x - 1, y) == 'j' or K.get(g, x + 1, y) == 'j')
                and (K.get(g, x, y - 1) == 'j' or K.get(g, x, y + 1) == 'j')
            if cruz and rr.chance(.035) then
                blob(g, x, y, rng.int(2, 3), 2, 'g', rr)
            elseif cruz and rr.chance(.04) then
                K.pixel(g, x, y, 'e')
                K.pixel(g, x + 1, y, 'e')
            end
        end
    end end
    -- lasca de quina: canto de laje lascado (junta nos dois vizinhos
    -- externos) — cunha 'k' de 2-3 px na quina oposta à luz
    for _ = 1, rng.int(1, 2) do
        local x, y = rng.int(3, W - 3), rng.int(3, H - 3)
        local ehQuina = K.get(g, x, y) ~= 'j'
            and K.get(g, x, y + 1) == 'j' and K.get(g, x + 1, y) == 'j'
        if ehQuina then
            K.pixel(g, x, y, 'k')
            K.pixel(g, x - 1, y + 1, 'k')
            K.pixel(g, x, y + 1, 'k')
            if rng.chance(.5) then K.pixel(g, x + 1, y - 1, 'k') end
        end
    end
    return g
end

local legend = {
    s = { ramp = 'stone', step = 4, h = 1 }, -- laje, tom base
    S = { ramp = 'stone', step = 5, h = 1 }, -- laje clara
    w = { ramp = 'stone', step = 3, h = 1 }, -- laje fria/úmida
    L = { ramp = 'stone', step = 6, h = 2 }, -- filete da quina
    V = { ramp = 'stone', step = 6, h = 1 }, -- laje lavada de sol
    k = { ramp = 'stone', step = 2, h = 0 }, -- assento/lasca
    j = { ramp = 'earth', step = 2, h = 0 }, -- junta de terra
    e = { ramp = 'earth', step = 4, h = 0 }, -- barro acumulado no nó
    g = { ramp = 'moss',  step = 2, h = 0 }, -- musgo no nó
}

return {
    name = 'piso_laje', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'piso',
        albedo = { K.string(laje(201)), K.string(laje(211)),
                   K.string(laje(223)), K.string(laje(229)) },
    } },
}
