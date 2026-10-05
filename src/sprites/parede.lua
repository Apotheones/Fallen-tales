-- PAREDE OBLÍQUA — tile 64x96, origem no canto superior esquerdo.
-- Amostra do formato DSL (Fase 0, docs/MEGAPLAN_VISUAL_HD.md §1-2).
-- Topo (cap) em pedra clara com borda iluminada e mancha de musgo;
-- face frontal com tijolos em running bond e juntas de mortar.
-- Relevo: cap h=15 (topo), bevel/lip h=13, tijolo h=7, mortar h=6
-- (rebaixado), base h=4 — o normal modela topo contra frente.
--
-- v3 — 4 FRAMES = VARIANTES POR SEED (frameUse='variant', mesma
-- convenção dos tiles de piso). Mesma oblíqua cap+face e mesma
-- silhueta/occluder em todas: cap de 34 linhas (layout idêntico a
-- parede_janela/parede_canto/parede_porta), fiadas de 7 tijolos
-- separadas por junta 'm' contínua nas MESMAS linhas. O que muda por
-- variante: posição das juntas verticais de cada fiada (running bond
-- deslocado), tijolos claros 'a', trincas/lascas 'k' e as manchas de
-- desgaste 'v' e musgo 'g' no topo do cap.
--
-- ENCAIXE LATERAL GARANTIDO: nas linhas de tijolo, as colunas 1-16 e
-- 49-64 são fixas por tipo de fiada (EA/EB) em TODAS as variantes —
-- o miolo (17-48) é o único trecho que varia. Qualquer par de
-- vizinhas casa: fiada A termina em junta na col 64 (m|b contínuo),
-- fiada B deixa meio-tijolo de 15px cruzando a borda.
local rep = string.rep
local function grid(rows) return table.concat(rows, '\n') end

-- Miolo de fiada (32 colunas, globais 17-48) com juntas 'm' nos
-- deslocamentos dados; o resto é tijolo 'b'.
local function J(...)
    local t = {}
    for i = 1, 32 do t[i] = 'b' end
    for _, p in ipairs { ... } do t[p] = 'm' end
    return table.concat(t)
end
-- Tijolo claro 'a' no trecho x..x+n-1 do miolo (jamais cruza junta).
local function acc(s, x, n)
    return s:sub(1, x - 1) .. rep('a', n) .. s:sub(x + n)
end
-- Trinca/lasca 'k' de n px dentro do tijolo.
local function chip(s, x, n)
    return s:sub(1, x - 1) .. rep('k', n) .. s:sub(x + n)
end

-- Bordas fixas por tipo de fiada (16 colunas cada):
--   A: junta na col 16 (esq) e 64 (dir) — alinhada
--   B: junta na col 9 (esq) e 57 (dir) — deslocada meia peça
local EA = 'bbbbbbbbbbbbbbbm'
local EB = 'bbbbbbbbmbbbbbbb'
local M  = rep('m', 64)
local DB = 'ddddddddmdddddddddddddddmdddddddddddddddmdddddddddddddddmddddddd'

-- Cap (linhas 1-34): mesmo desenho da família parede_*; só o interior
-- da laje (desgaste 'v', musgo 'g', lasca 'k') muda por variante —
-- contorno 'C'/'c', bevel e lip 'l' são estruturais e não se movem.
local function capRows(v)
    local rows = {}
    rows[1] = rep('C', 64)
    rows[2] = rep('C', 64)
    for r = 3, 29 do
        local t = {}
        for x = 1, 64 do t[x] = 'c' end
        t[1], t[64] = 'C', 'C'
        for _, p in ipairs(v.mancha) do              -- {r1,r2,x1,x2}
            if r >= p[1] and r <= p[2] then
                for x = p[3], p[4] do t[x] = 'v' end
            end
        end
        for _, p in ipairs(v.musgo) do               -- {r1,r2,x1,x2}
            if r >= p[1] and r <= p[2] then
                for x = p[3], p[4] do t[x] = 'g' end
            end
        end
        for _, p in ipairs(v.lasca) do               -- {r,x1,x2}
            if r == p[1] then
                for x = p[2], p[3] do t[x] = 'k' end
            end
        end
        rows[r] = table.concat(t)
    end
    rows[30] = rep('C', 64)
    for r = 31, 34 do rows[r] = rep('l', 64) end
    return rows
end

-- Face (linhas 35-96 = 62 linhas): 6 fiadas de 7 + fiada rasa de 5 +
-- base 'd' de 6 + dupla junta de fechamento. Linhas de mortar M caem
-- SEMPRE nas mesmas linhas (42,50,58,66,74,82,88,95,96) — curso
-- contínuo que atravessa as variantes sem degrau.
local function faceRows(bandas)
    local rows = {}
    local y = 35
    for _, band in ipairs(bandas) do
        local e = band.tipo == 'A' and EA or EB
        for _, s in ipairs(band.mids) do
            rows[y] = e .. s .. e
            y = y + 1
        end
        rows[y] = M
        y = y + 1
    end
    for _ = 1, 6 do rows[y] = DB; y = y + 1 end
    rows[y] = M
    rows[y + 1] = M
    return rows
end

local function monta(v)
    local rows = capRows(v)
    local face = faceRows(v.bandas)
    for i = 35, 96 do rows[i] = face[i] end
    assert(#rows == 96, 'parede deve ter 96 linhas')
    for i = 1, 96 do assert(#rows[i] == 64, 'linha ' .. i .. ' ragged') end
    return grid(rows)
end

--------------------------------------------------------------------------------
-- V1 — o desenho original: running bond canônico (juntas a cada 15px),
-- acentos 'a' herdados, trinca na terceira fiada.
--------------------------------------------------------------------------------
local A1, B1 = J(16, 32), J(9, 25)
local V1 = {
    mancha = { { 10, 11, 10, 14 } },
    musgo  = { { 21, 21, 49, 56 }, { 22, 23, 48, 56 },
               { 24, 24, 50, 56 }, { 25, 25, 51, 55 } },
    lasca  = {},
    bandas = {
        { tipo = 'A', mids = { A1, acc(A1, 1, 15), acc(A1, 1, 15),
                               A1, A1, A1, A1 } },
        { tipo = 'B', mids = { B1, B1, acc(B1, 10, 15), acc(B1, 10, 15),
                               B1, B1, B1 } },
        { tipo = 'A', mids = { A1, A1, chip(A1, 5, 2), chip(A1, 6, 2),
                               A1, A1, A1 } },
        { tipo = 'B', mids = { B1, B1, acc(B1, 10, 15), acc(B1, 10, 15),
                               B1, B1, B1 } },
        { tipo = 'A', mids = { acc(A1, 17, 15), acc(A1, 17, 15),
                               A1, A1, A1, A1, A1 } },
        { tipo = 'B', mids = { B1, B1, B1, B1, B1, B1, B1 } },
        { tipo = 'A', mids = { A1, A1, A1, A1, A1 } },
    },
}

--------------------------------------------------------------------------------
-- V2 — juntas corridas para a esquerda nas fiadas A (11-15px de peça),
-- fiadas B deslocadas meio passo; musgo migra para o canto esquerdo do
-- cap e a trinca desce para a quinta fiada.
--------------------------------------------------------------------------------
local A2a, A2b, A2c = J(10, 26), J(12, 28), J(14, 30)
local B2a, B2b      = J(11, 27), J(7, 22)
local V2 = {
    mancha = { { 8, 9, 40, 45 } },
    musgo  = { { 20, 20, 8, 13 }, { 21, 22, 7, 14 }, { 23, 23, 8, 13 } },
    lasca  = { { 6, 30, 31 } },
    bandas = {
        { tipo = 'A', mids = { A2a, A2a, acc(A2a, 11, 15), acc(A2a, 11, 15),
                               A2a, A2a, A2a } },
        { tipo = 'B', mids = { B2a, acc(B2a, 12, 15), acc(B2a, 12, 15),
                               B2a, B2a, B2a, B2a } },
        { tipo = 'A', mids = { A2b, A2b, A2b, chip(A2b, 18, 2),
                               chip(A2b, 19, 2), A2b, A2b } },
        { tipo = 'B', mids = { B2b, B2b, B2b, B2b, B2b, B2b, B2b } },
        { tipo = 'A', mids = { acc(A2a, 1, 9), acc(A2a, 1, 9),
                               A2a, A2a, A2a, A2a, chip(A2a, 24, 1) } },
        { tipo = 'B', mids = { B2a, B2a, acc(B2a, 1, 10), B2a,
                               B2a, B2a, B2a } },
        { tipo = 'A', mids = { A2c, A2c, A2c, A2c, A2c } },
    },
}

--------------------------------------------------------------------------------
-- V3 — juntas corridas para a direita; na quinta fiada uma junta
-- extra só vive na metade de cima do curso (bond quebrado/remendado);
-- musgo concentrado no centro do cap com lasca na borda direita.
--------------------------------------------------------------------------------
local A3a, A3b, A3c = J(14, 30), J(12, 27), J(14, 22, 30)
local B3a           = J(6, 21)
local V3 = {
    mancha = { { 12, 13, 26, 31 } },
    musgo  = { { 22, 22, 33, 38 }, { 23, 24, 32, 39 }, { 25, 25, 34, 37 } },
    lasca  = { { 18, 52, 54 } },
    bandas = {
        { tipo = 'A', mids = { A3a, A3a, A3a, A3a,
                               chip(A3a, 8, 2), chip(A3a, 9, 2), A3a } },
        { tipo = 'B', mids = { B3a, B3a, B3a, B3a, B3a, B3a, B3a } },
        { tipo = 'A', mids = { acc(A3b, 1, 11), acc(A3b, 1, 11),
                               A3b, A3b, A3b, A3b, A3b } },
        { tipo = 'B', mids = { B3a, B3a, acc(B3a, 22, 11), acc(B3a, 22, 11),
                               B3a, B3a, B3a } },
        { tipo = 'A', mids = { A3c, A3c, A3c, A3c, A3a, A3a, A3a } },
        { tipo = 'B', mids = { B3a, B3a, B3a, B3a, B3a, B3a, B3a } },
        { tipo = 'A', mids = { A3a, A3a, A3a, A3a, A3a } },
    },
}

--------------------------------------------------------------------------------
-- V4 — bond mais irregular: fiada do meio com junta tripla (duas
-- peças curtas remendadas), sexta fiada B com junta dupla (mortar
-- alargado de 2px), musgo em dois pontos separados do cap.
--------------------------------------------------------------------------------
local A4a, A4b      = J(18, 32), J(10, 18, 27)
local B4a, B4b      = J(14, 30), J(4, 20, 21)
local V4 = {
    mancha = { { 9, 10, 52, 57 } },
    musgo  = { { 21, 21, 18, 21 }, { 22, 22, 17, 22 },
               { 24, 25, 55, 58 } },
    lasca  = { { 15, 8, 9 } },
    bandas = {
        { tipo = 'A', mids = { A4a, A4a, A4a, A4a, A4a, A4a, A4a } },
        { tipo = 'B', mids = { B4a, B4a, B4a, B4a, B4a,
                               chip(B4a, 16, 1), B4a } },
        { tipo = 'A', mids = { A4b, A4b, acc(A4b, 11, 7), acc(A4b, 11, 7),
                               A4b, A4b, A4b } },
        { tipo = 'B', mids = { B4a, B4a, B4a, acc(B4a, 1, 13),
                               acc(B4a, 1, 13), B4a, B4a } },
        { tipo = 'A', mids = { A4a, acc(A4a, 19, 13), acc(A4a, 19, 13),
                               A4a, A4a, A4a, A4a } },
        { tipo = 'B', mids = { B4b, B4b, B4b, B4b, B4b, B4b, B4b } },
        { tipo = 'A', mids = { A4a, A4a, A4a, A4a, chip(A4a, 25, 2) } },
    },
}

return {
    name = 'parede',
    w = 64, h = 96,
    origin = 'topleft',
    frameUse = 'variant', -- 4 frames = variantes por seed, nunca animação

    legend = {
        k = {spec = 'ink', h = 6},             -- trinca / lasca
        -- cap: topo iluminado, borda clara, variação e musgo
        c = {ramp = 'stone', step = 6, h = 15},
        C = {ramp = 'stone', step = 7, h = 15},
        v = {ramp = 'stone', step = 5, h = 15},
        l = {ramp = 'stone', step = 3, h = 13}, -- lip frontal do cap
        g = {ramp = 'moss', step = 3, h = 15},
        -- face: tijolo, tijolo claro alternado, mortar rebaixado, base
        b = {ramp = 'stone', step = 4, h = 7},
        a = {ramp = 'stone', step = 5, h = 7},
        m = {ramp = 'stone', step = 2, h = 6},
        d = {ramp = 'stone', step = 1, h = 4},
    },

    layers = {
        {
            name = 'wall',
            h = 7,
            albedo = { monta(V1), monta(V2), monta(V3), monta(V4) },
        },
    },
}
