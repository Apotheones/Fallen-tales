-- TERRA_MANCHA — OVERLAY DECAL (não tile!), 128x128, origem topleft.
-- O canvas fica quase todo transparente ('.'): cada frame carrega UMA
-- mancha orgânica que o renderer deposita sobre o piso. É a textura
-- por mancha grande do veredito da Mira — o tile fica limpo e a marca
-- de uso atravessa células em vez de morrer dentro da grade.
--
-- 6 frames = TIPOS de mancha (frameUse='variant'), escolhidos por
-- contexto de cena, nunca por tempo:
--   f1/f2 = DESGASTE DE USO — lâmina larga de barro pisado, miolo
--           claro 'b'/'c' e franja ragged 'd'/'u'. Perto de porta,
--           bancada, beira de fogão.
--   f3    = CLUSTER DE SEIXO — 7-9 pedrinhas 'p'/'q' com apoio 'u'
--           dispersas numa faixa irregular ~100 px. Borda de muro
--           e de caminho.
--   f4    = TUFO/GRAMA — aglomerado de 5 tufos ('g' base + 't'
--           lâmina) com lâminas soltas na franja. Sombra de muro,
--           pé de fachada.
--   f5    = UMIDEZ/ESCURO — mancha funda 'd'/'r', centro quase
--           sólido desmanchando em franja. Sob muro e depósito.
--   f6    = FAIXA LONGA — desgaste de ponta a ponta (128 px),
--           ~30 px de largura irregular. Pedaço de caminho de uso
--           que atravessa células; chega nas arestas esq/dir.
--
-- Regras do decal: '.' domina (>70% vazio); bordas SEMPRE ragged —
-- fronteira polar lobada (senos 3/5/9) + micro-ruído por pixel dão
-- penínsulas de 2-6 px, e o anel externo cospe farelo esparsando;
-- h 0-1 só — o decalque recua, 'u'/'r' sentam em h=0 na beirada.
-- Manchas PODEM cair parcialmente fora do frame (set() clipa; f6
-- nasce e morre nas arestas) — a composição é do renderer.

local W, H = 128, 128
local FR = 6 -- profundidade da franja ragged, px

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

local atan2 = math.atan2 or function(y, x)
    if x > 0 then return math.atan(y / x)
    elseif x < 0 then return math.atan(y / x) + math.pi
    elseif y > 0 then return math.pi / 2
    elseif y < 0 then return -math.pi / 2 end
    return 0
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

--------------------------------------------------------------------------------
-- Campo orgânico: elipse lobada por 3 senos angulares (raio varia ±35%)
-- + micro-ruído por pixel. pinta(g,x,y,d) recebe d<0 dentro da massa,
-- 0..FR na franja, >FR no farelo — cada tipo decide o que cada zona vira.
--------------------------------------------------------------------------------
local function blob(g, cx, cy, rx, ry, rot, seed, pinta)
    local ph1 = hash2(1, seed, seed) * 6.2832
    local ph2 = hash2(2, seed, seed) * 6.2832
    local ph3 = hash2(3, seed, seed) * 6.2832
    local ca, sa = math.cos(rot), math.sin(rot)
    local rmin = math.min(rx, ry)
    local reach = math.ceil(math.max(rx, ry) * 1.4 + FR + 8)
    local x0 = math.max(1, math.floor(cx - reach))
    local x1 = math.min(W, math.ceil(cx + reach))
    local y0 = math.max(1, math.floor(cy - reach))
    local y1 = math.min(H, math.ceil(cy + reach))
    for y = y0, y1 do for x = x0, x1 do
        local ax, ay = x - cx, y - cy
        local dx = (ax * ca + ay * sa) / rx
        local dy = (-ax * sa + ay * ca) / ry
        local r = math.sqrt(dx * dx + dy * dy)
        local ang = atan2(dy, dx)
        local wob = math.sin(ang * 3 + ph1) * 0.17
                  + math.sin(ang * 5 + ph2) * 0.11
                  + math.sin(ang * 9 + ph3) * 0.07
        local d = (r - (1 + wob)) * rmin + (hash2(x, y, seed) - 0.5) * 2.6
        if d < FR + 6 then pinta(g, x, y, d) end
    end end
end

--------------------------------------------------------------------------------
-- Pintores por tipo de mancha
--------------------------------------------------------------------------------

-- Desgaste de uso: miolo de barro lavado 'b' com grão 'c' e remoinho
-- 'd' pisado; transição 'b'/'d' misturada; franja de torrões 'd'/'u';
-- farelo raro além dela.
local function pintaDesgaste(seed)
    return function(g, x, y, d)
        local h = hash2(x, y, seed)
        if d < -5 then
            if h < 0.09 then set(g, x, y, 'c')
            elseif h < 0.20 then set(g, x, y, 'd')
            else set(g, x, y, 'b') end
        elseif d < 0 then
            set(g, x, y, h < 0.55 and 'b' or 'd')
        elseif d < FR then
            if h < (FR - d) / FR * 0.7 then
                set(g, x, y, hash2(x, y, seed + 3) < 0.42 and 'u' or 'd')
            end
        elseif h < 0.06 then
            set(g, x, y, hash2(x, y, seed + 5) < 0.5 and 'd' or 'u')
        end
    end
end

-- Umidade: centro quase sólido 'd' com veios 'r' fundos; a densidade
-- cai por anel até a franja 'd'/'u' e o farelo pingando 'r'.
local function pintaUmidade(seed)
    return function(g, x, y, d)
        local h = hash2(x, y, seed)
        if d < -8 then
            set(g, x, y, h < 0.34 and 'r' or 'd')
        elseif d < -2 then
            set(g, x, y, h < 0.16 and 'r' or 'd')
        elseif d < 0 then
            set(g, x, y, h < 0.75 and 'd' or 'u')
        elseif d < FR then
            if h < (FR - d) / FR * 0.65 then
                local h2 = hash2(x, y, seed + 3)
                set(g, x, y, h2 < 0.12 and 'r' or (h2 < 0.5 and 'u' or 'd'))
            end
        elseif h < 0.05 then
            set(g, x, y, hash2(x, y, seed + 5) < 0.4 and 'r' or 'd')
        end
    end
end

--------------------------------------------------------------------------------
-- Carimbos de seixo e tufo (mesma linguagem do piso_terra: luz de
-- cima-esquerda — 'p' em cima/esquerda, 'q' no lado de sombra,
-- 'u' de apoio por baixo)
--------------------------------------------------------------------------------
local SEIXO = {
    { '.pp.', 'pqp.', '.u..' },
    { '.pp.', 'pqqp', '.uu.' },
    { 'pp.', 'pqp', '.u.' },
    { '.p.', 'pqp', '.u.' },
    { 'ppp.', 'ppqp', '.uu.' },
    { '.pp.pp.', 'pqppq.', '.u.u..' }, -- par colado
}

local TUFO = {
    { '..t..t.', '.tgt.t.', 'tgggtgt', 'gggggg.', '.gggg..' },
    { '.t.t..', 'tgtgt.', 'ggggg.', '.ggg..' },
    { 't..t.', 'tgtgt', 'ggtgg', '.ggg.' },
    { '..t...', '.t.t.t', 'tgtgtg', 'gggggg', '.gggg.' },
    { 't.t', 'gtg', 'ggg' },
}

--------------------------------------------------------------------------------
-- Frames
--------------------------------------------------------------------------------

-- f1 — desgaste largo horizontal (~96x44 nominal, lobos o esticam):
-- o rastro na frente da porta.
local function f1()
    local g = nova('.')
    blob(g, 64, 63, 48, 22, 0.12, 11, pintaDesgaste(11))
    return str(g)
end

-- f2 — desgaste diagonal (~92x42 nominal): o pisado em frente à bancada.
local function f2()
    local g = nova('.')
    blob(g, 66, 62, 46, 21, -0.45, 23, pintaDesgaste(23))
    return str(g)
end

-- f3 — cluster de seixo: pedrinhas dispersas numa faixa sinuosa
-- ~100 px de comprimento, com farelo de torrão entre elas.
local function f3()
    local g = nova('.')
    local seed = 37
    local ph = hash2(1, seed, seed) * 6.2832
    local ph2 = hash2(2, seed, seed) * 6.2832
    local function eixoY(x)
        return 64 + math.sin(x * 0.045 + ph) * 11
                  + math.sin(x * 0.12 + ph2) * 6
    end
    local n = 7 + math.floor(hash2(9, seed, seed) * 3) -- 7-9 pedrinhas
    for i = 1, n do
        local x = 14 + (i - 0.5) * (100 / n)
                  + (hash2(i, seed, 3) - 0.5) * 14
        local y = eixoY(x) + (hash2(i, seed, 5) - 0.5) * 26
        local f = SEIXO[1 + math.floor(hash2(i, seed, 7) * #SEIXO)]
        carimbo(g, math.floor(x), math.floor(y), f)
        if hash2(i, seed, 11) < 0.45 then -- torrão ao pé da pedra
            set(g, math.floor(x + hash2(i, 1, seed) * 8 - 4),
                   math.floor(y + 4 + hash2(i, 2, seed) * 4), 'u')
        end
        if hash2(i, seed, 13) < 0.3 then -- grão escuro solto
            set(g, math.floor(x - 3 + hash2(i, 3, seed) * 6),
                   math.floor(y - 3), 'd')
        end
    end
    for i = 1, 7 do -- pedrinhas miúdas fora do cluster principal
        local x = math.floor(16 + hash2(i, seed, 17) * 96)
        local y = math.floor(eixoY(x) + (hash2(i, seed, 19) - 0.5) * 30)
        if get(g, x, y) == '.' then set(g, x, y, 'u') end
        if hash2(i, seed, 21) < 0.4 and get(g, x, y + 1) == '.' then
            set(g, x, y + 1, 'd')
        end
    end
    return str(g)
end

-- f4 — aglomerado de tufos (~80 px): musgo de beirada, lâminas 't'
-- subindo da base 'g', com lâminas soltas e terra revolvida na franja.
local function f4()
    local g = nova('.')
    local seed = 53
    local cx, cy, rx, ry = 64, 64, 40, 28
    local postos = 0
    for i = 1, 12 do
        if postos >= 5 then break end
        local x = cx + (hash2(i, seed, 1) - 0.5) * (rx * 2.1)
        local y = cy + (hash2(i, seed, 2) - 0.5) * (ry * 2.1)
        local dx, dy = (x - cx) / rx, (y - cy) / ry
        if dx * dx + dy * dy < 0.85 then
            local f = TUFO[1 + math.floor(hash2(i, seed, 3) * #TUFO)]
            carimbo(g, math.floor(x - #f[1] / 2), math.floor(y - #f / 2), f)
            postos = postos + 1
        end
    end
    for i = 1, 14 do -- lâminas soltas na franja do aglomerado
        local ang = hash2(i, seed, 7) * 6.2832
        local rr = 0.75 + hash2(i, seed, 9) * 0.5
        local x = math.floor(cx + math.cos(ang) * rx * rr)
        local y = math.floor(cy + math.sin(ang) * ry * rr)
        if get(g, x, y) == '.' then
            set(g, x, y, hash2(i, seed, 11) < 0.5 and 't' or 'g')
        end
        if hash2(i, seed, 13) < 0.35 and get(g, x + 1, y) == '.' then
            set(g, x + 1, y, 'g')
        end
    end
    for i = 1, 8 do -- terra revolvida sob o tufo
        local x = math.floor(cx + (hash2(i, seed, 15) - 0.5) * 80)
        local y = math.floor(cy + (hash2(i, seed, 16) - 0.5) * 54)
        if get(g, x, y) == '.' then set(g, x, y, 'u') end
    end
    return str(g)
end

-- f5 — umidade: mancha funda ~76 px nominal, centro denso sumindo
-- em franja.
local function f5()
    local g = nova('.')
    blob(g, 62, 66, 38, 26, 0.2, 67, pintaUmidade(67))
    return str(g)
end

-- f6 — faixa longa de desgaste: atravessa o frame inteiro (bocas nas
-- arestas esq/dir), ~20-34 px de largura por lobos de 4 px + dente.
local function f6()
    local g = nova('.')
    local seed = 71
    local pinta = pintaDesgaste(seed)
    local ph1 = hash2(1, seed, seed) * 6.2832
    local ph2 = hash2(2, seed, seed) * 6.2832
    for x = 1, W do
        local yc = 64 + math.sin(x * 0.05 + ph1) * 8
                      + math.sin(x * 0.14 + ph2) * 4
        local b = math.floor((x - 1) / 4)
        local lobe = ((b * 57 + seed * 31 + 13) % 100) / 100
        local dente = ((x * 29 + seed * 17 + 7) % 97) / 97
        local hw = 10 + math.floor(lobe * 6 + dente * 2)
        local y0 = math.max(1, math.floor(yc - hw - FR - 6))
        local y1 = math.min(H, math.ceil(yc + hw + FR + 6))
        for y = y0, y1 do
            local d = math.abs(y - yc) - hw
                      + (hash2(x, y, seed) - 0.5) * 2.6
            pinta(g, x, y, d)
        end
    end
    return str(g)
end

return {
    name = 'terra_mancha',
    w = 128, h = 128,
    origin = 'topleft',
    -- 6 frames = tipos de mancha escolhidos por contexto de cena;
    -- não é animação nem variante de seed
    frameUse = 'variant',

    legend = {
        b = { ramp = 'earth', step = 6, h = 1 }, -- desgaste claro (miolo)
        c = { ramp = 'earth', step = 7, h = 1 }, -- grão de barro seco
        d = { ramp = 'earth', step = 2, h = 1 }, -- barro pisado / torrão
        r = { ramp = 'earth', step = 1, h = 0 }, -- veio fundo de umidade
        u = { ramp = 'earth', step = 2, h = 0 }, -- apoio/fio — recua
        p = { ramp = 'stone', step = 5, h = 1 }, -- seixo, luz
        q = { ramp = 'stone', step = 3, h = 1 }, -- seixo, lado de sombra
        g = { ramp = 'moss',  step = 2, h = 1 }, -- base do tufo
        t = { ramp = 'moss',  step = 4, h = 1 }, -- lâmina do tufo
    },

    layers = {
        {
            name = 'mancha',
            h = 0, -- decalque: a base recua, só a mancha marca h=1
            albedo = { f1(), f2(), f3(), f4(), f5(), f6() },
        },
    },
}
