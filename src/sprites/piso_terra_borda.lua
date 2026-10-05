-- PISO_TERRA_BORDA — overlay de transição de terreno (W5), 64x64,
-- origem topleft. 8 frames = DIREÇÕES, não variantes nem animação:
-- frameUse='direction'.
--
-- CONTRATO DE CONSUMO (src/hd_world.lua, canal de chão):
--   dirs por offset {0,-1},{1,0},{0,1},{-1,0} => d1..d4 = n,e,s,w.
--   O overlay `trans_terra` desenha SOBRE a célula receptora (laje):
--   o vizinho terra invade a aresta dela, nunca o contrário.
--     f1 = vizinho N  -> banda de terra entrando pelo TOPO da célula
--     f2 = vizinho E  -> banda entrando pela DIREITA
--     f3 = vizinho S  -> banda entrando pela BASE
--     f4 = vizinho W  -> banda entrando pela ESQUERDA
--   Cantos internos (tabela {{1,2,5},{4,1,6},{2,3,7},{3,4,8}}):
--     f5 = n+e (canto NE), f6 = w+n (NW), f7 = e+s (SE), f8 = s+w (SW)
--   Quando o par combina, SÓ o frame de canto desenha — ele precisa
--   cobrir as duas arestas e o canto sem buraco.
--
-- Linguagem igual ao piso_terra: massa 'a', mancha 'd', desgaste 'b'.
-- A fronteira é lobada por blocos de 4 px + dente de 1 px (penínsulas
-- de 2-6 px), com farelo de torrões esparsando sobre a laje, musgo
-- seco 'm' na emenda e falha de pedra 's' pontual. h 0-1: decalque,
-- a terra recua — o fio 'u' e o musgo sentam em h=0 na beirada.
-- A aresta externa do tile fica massa cheia: a terra continua sem
-- emenda dentro do vizinho terra (fio 'u' só na face invasora).

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

local function get(g, x, y)
    return (g[y] and g[y][x]) or '.'
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function hash2(x, y, seed)
    return ((x * 41 + y * 67 + seed * 11) % 100) / 100
end

-- Profundidade da banda por posição na aresta: base 6 + lobo de 4 px
-- (0-5) + dente coluna a coluna (0-1) => 6..12 px, penínsulas de 2-6.
local function prof(x, seed)
    local b = math.floor((x - 1) / 4)
    local lobe = ((b * 57 + seed * 31 + 13) % 100) / 100
    local dente = ((x * 29 + seed * 17 + 7) % 97) / 97
    return 6 + math.floor(lobe * 6 + dente * 1.9)
end

-- Banda ao longo da aresta `dir`: 'n' enche de cima p/ baixo até prof.
local function banda(dir, seed)
    local g = nova('.')
    for x = 1, W do
        local p = prof(x, seed)
        for y = 1, p do
            if dir == 'n' then set(g, x, y, 'a')
            elseif dir == 's' then set(g, x, H - y + 1, 'a')
            elseif dir == 'w' then set(g, y, x, 'a')
            elseif dir == 'e' then set(g, W - y + 1, x, 'a') end
        end
    end
    return g
end

-- Canto interno: união das duas bandas ortogonais — o canto fica
-- coberto pelas duas, sem buraco (só o frame de canto desenha).
local function canto(d1, d2, seed)
    local g = nova('.')
    for x = 1, W do
        local p = prof(x, seed)
        for y = 1, p do
            if d1 == 'n' then set(g, x, y, 'a') else set(g, x, H - y + 1, 'a') end
            if d2 == 'w' then set(g, y, x, 'a') else set(g, W - y + 1, x, 'a') end
        end
    end
    return g
end

local function carimbo(g, x, y, forma, mask)
    for j = 1, #forma do
        for i = 1, #forma[j] do
            local c = forma[j]:sub(i, i)
            if c ~= '.' and (not mask or get(g, x + i - 1, y + j - 1) ~= '.') then
                set(g, x + i - 1, y + j - 1, c)
            end
        end
    end
end

-- Acabamento da banda, por passes determinísticos:
-- 1) fio 'u' só na fronteira invasora (vizinho vazio DENTRO do tile;
--    a aresta externa continua 'a' — emenda invisível com o vizinho).
-- 2) musgo seco 'm': raro, sobre o fio e na laje encostada na beira.
-- 3) farelo: torrões 'a'/'d' de 1 px além da beira (anéis 18% + 6%).
-- 4) manchas 'd'/'b' e falha 's' escolhidas SOBRE pixels de terra —
--    carimbo com máscara nunca erra a banda.
local MASKA = {
    '..ddd..',
    '.ddddd.',
    'ddddddd',
    '.dddd..',
}
local MASKB = {
    '.bbbbbb.',
    'bbbbbbbb',
    '.bbbbb..',
}
local FALHA = {
    { 'ss.', '.s.' },
    { '.ss', 'ss.' },
    { 's' },
}

local function acaba(g, seed)
    -- Passo 1: fronteira invasora.
    local rim, fora = {}, {}
    for y = 1, H do for x = 1, W do
        if g[y][x] == 'a' then
            local borda = false
            for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                local tx, ty = x + d[1], y + d[2]
                -- Fora do tile NÃO conta: a aresta externa é continuação
                -- da terra do vizinho, não fronteira invasora.
                if tx >= 1 and tx <= W and ty >= 1 and ty <= H
                    and g[ty][tx] == '.' then
                    borda = true
                    fora[#fora + 1] = { tx, ty }
                end
            end
            if borda then rim[#rim + 1] = { x, y } end
        end
    end end

    -- Passo 2: beirada em tons de sujeira — o fio 'u' domina mas não
    -- vira linha uniforme: 'd' amassa partes, 'm' esverdeia raro e a
    -- ponta de uma península às vezes fica massa cheia. Antes do
    -- farelo para os torrões não cobrirem o musgo.
    for _, p in ipairs(rim) do
        local h = hash2(p[1], p[2], seed + 3)
        if h < 0.07 then g[p[2]][p[1]] = 'm'
        elseif h < 0.32 then g[p[2]][p[1]] = 'd'
        elseif h < 0.38 then g[p[2]][p[1]] = 'a'
        else g[p[2]][p[1]] = 'u' end
    end
    for _, c in ipairs(fora) do
        local x, y = c[1], c[2]
        if get(g, x, y) == '.' and hash2(x, y, seed + 5) < 0.08 then
            g[y][x] = 'm'
        end
    end

    -- Passo 3: farelo — anel 1 de torrões colado na beira, anel 2
    -- esparsando mais um passo na laje (erosão, não salpico).
    local anel2 = {}
    for _, c in ipairs(fora) do
        local x, y = c[1], c[2]
        if get(g, x, y) == '.' then
            local h = hash2(x, y, seed)
            if h < 0.18 then
                g[y][x] = h < 0.05 and 'd' or 'a'
                anel2[#anel2 + 1] = { x, y }
            end
        end
    end
    for _, c in ipairs(anel2) do
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local tx, ty = c[1] + d[1], c[2] + d[2]
            if get(g, tx, ty) == '.' and hash2(tx, ty, seed + 7) < 0.10 then
                g[ty][tx] = 'a'
            end
        end
    end

    -- Passo 4: manchas e falhas dentro da massa — alvos escolhidos
    -- sobre pixels de terra reais, nunca às cegas.
    local terra_px = {}
    for y = 1, H do for x = 1, W do
        if g[y][x] ~= '.' then terra_px[#terra_px + 1] = { x, y } end
    end end
    local n = #terra_px
    if n > 0 then
        local function alvo(i)
            local p = terra_px[1 + ((seed * 37 + i * 53) % n)]
            return p[1], p[2]
        end
        local x, y = alvo(1)
        carimbo(g, math.max(1, x - 3), math.max(1, y - 2), MASKA, true)
        x, y = alvo(2)
        carimbo(g, math.max(1, x - 3), math.max(1, y - 1), MASKB, true)
        -- falhas de pedra aflorando no barro (1-3 px, stone.3)
        for i = 3, 5 do
            x, y = alvo(i)
            if hash2(x, y, seed + i) < 0.55 then
                carimbo(g, x, y, FALHA[1 + (seed + i) % #FALHA], true)
            end
        end
    end
    return str(g)
end

local N  = acaba(banda('n', 5), 5)
local E  = acaba(banda('e', 9), 9)
local S  = acaba(banda('s', 13), 13)
local O  = acaba(banda('w', 17), 17)
local NE = acaba(canto('n', 'e', 23), 23)
local NW = acaba(canto('n', 'w', 29), 29)
local SE = acaba(canto('s', 'e', 37), 37)
local SW = acaba(canto('s', 'w', 41), 41)

return {
    name = 'piso_terra_borda',
    w = 64, h = 64,
    origin = 'topleft',
    -- frames escolhidos por direção do vizinho, não por tempo nem seed
    frameUse = 'direction',
    edgeOrder = { 'n', 'e', 's', 'w', 'ne', 'nw', 'se', 'sw' },

    legend = {
        a = { ramp = 'earth', step = 4, h = 1 }, -- massa de barro
        d = { ramp = 'earth', step = 3, h = 1 }, -- mancha pisada / torrão
        b = { ramp = 'earth', step = 5, h = 1 }, -- desgaste claro
        u = { ramp = 'earth', step = 2, h = 0 }, -- fio da beirada (recua)
        m = { ramp = 'moss',  step = 2, h = 0 }, -- musgo seco na emenda
        s = { ramp = 'stone', step = 3, h = 1 }, -- falha de pedra pontual
    },

    layers = {
        { name = 'borda', h = 1, albedo = { N, E, S, O, NE, NW, SE, SW } },
    },
}
