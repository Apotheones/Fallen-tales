-- PISO_TERRA_BORDA — overlay de transição de terreno (W5), 64x64,
-- origem topleft. 8 frames = DIREÇÕES, não variantes nem animação:
-- frameUse='direction'. Ordem: 1=n, 2=e, 3=s, 4=w, 5=ne, 6=nw, 7=se,
-- 8=sw — o frame diz de ONDE vem a terra (vizinho n → banda no topo
-- da célula sobreposta). Alpha 0 fora da banda: desenha por cima do
-- tile-base (laje) — a terra orgânica invade a pedra trabalhada.
--
-- Linguagem igual ao piso_terra: massa 'a', mancha 'd', depressão 'r',
-- pedrinha 'p'/'q' com apoio 'u'. A fronteira é lobada por blocos de
-- 4 px (aglomerado autorado, não ruído) com 1-2 torrões soltos além
-- dela — erosão, não salpico.

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

-- Profundidade da banda por coluna: lobas de 4 px (bloco) + dente de
-- 1 px coluna a coluna — determinístico, sem consumir RNG de jogo.
local function prof(x, seed)
    local b = math.floor((x - 1) / 4)
    local lobe = ((b * 57 + seed * 31 + 13) % 100) / 100
    local dente = ((x * 29 + seed * 17 + 7) % 97) / 97
    return 8 + math.floor(lobe * 9 + dente * 2.4)
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

-- Canto interno: união das duas bandas ortogonais (a terra vem das
-- duas direções e fecha o canto da célula).
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

-- Acabamento da banda: manchas 'd' dentro da massa, fio 'u' de sombra
-- na linha da fronteira, torrões soltos 1-2 px além dela e pedrinhas
-- esparsas (clusters desenhados, luz de cima-esquerda).
local PEDRA = {
    { '.pp.', 'pqp.', '.u..' },
    { '.p.pp', 'ppqpp', 'u.uu.' },
    { 'ppp..', 'pqpp.', '.u.u.' },
}
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

local function acaba(g, seed)
    -- fio de sombra na fronteira + torrão além dela, por coluna/fila
    for y = 1, H do for x = 1, W do
        if get(g, x, y) == 'a' then
            local fora = get(g, x - 1, y) == '.' or get(g, x + 1, y) == '.'
                or get(g, x, y - 1) == '.' or get(g, x, y + 1) == '.'
            if fora then
                g[y][x] = 'u' -- beira da terra em sombra sobre a pedra
                -- torrão solto 1-2 px além da linha, esparso por hash
                for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                    local tx, ty = x + d[1], y + d[2]
                    if tx >= 1 and tx <= W and ty >= 1 and ty <= H
                        and get(g, tx, ty) == '.'
                        and ((tx * 41 + ty * 67 + seed * 11) % 100) < 22 then
                        g[ty][tx] = 'a'
                    end
                end
            end
        end
    end end
    -- manchas 'd' e desgaste 'b' dentro da massa (só onde já há terra)
    local MASKA = {
        '..ddd..',
        '.ddddd.',
        'ddddddd',
        '.dddd..',
    }
    local MASKB = {
        '.dddddd.',
        'dddddddd',
        '.ddddd..',
    }
    local spots = {}
    for i = 0, 3 do
        spots[#spots + 1] = { ((seed * 37 + i * 23) % 48) + 4,
            ((seed * 53 + i * 31) % 56) + 2 }
    end
    carimbo(g, spots[1][1], spots[1][2], MASKA, true)
    carimbo(g, spots[2][1], spots[2][2], MASKB, true)
    carimbo(g, spots[3][1], spots[3][2], PEDRA[1 + seed % 3], true)
    if seed % 2 == 0 then
        carimbo(g, spots[4][1], spots[4][2], PEDRA[1 + (seed + 1) % 3], true)
    end
    -- grão claro raro no desgaste
    for i = 1, 3 do
        local x = (seed * 71 + i * 19) % 60 + 2
        local y = (seed * 43 + i * 29) % 60 + 2
        if get(g, x, y) == 'd' then g[y][x] = 'c' end
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
        d = { ramp = 'earth', step = 3, h = 1 }, -- mancha pisada
        b = { ramp = 'earth', step = 5, h = 1 }, -- desgaste claro
        c = { ramp = 'earth', step = 6, h = 1 }, -- grão claro raro
        p = { ramp = 'stone', step = 5, h = 2 }, -- pedrinha, luz
        q = { ramp = 'stone', step = 3, h = 2 }, -- pedrinha, sombra
        u = { ramp = 'earth', step = 2, h = 1 }, -- fio da fronteira
    },

    layers = {
        { name = 'borda', h = 1, albedo = { N, E, S, O, NE, NW, SE, SW } },
    },
}
