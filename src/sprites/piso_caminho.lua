-- PISO_CAMINHO — faixa de caminho DIRECIONAL, tile 64x64, topleft.
-- v3: 9 frames = DIREÇÕES da rota (frameUse='direction'), NÃO
-- variantes nem animação. O renderer escolhe o frame pela geometria
-- do caminho na célula; curvas/T/pontas que faltam saem por
-- espelho/rotação do quad.
--
-- MAPA DE FRAMES (frameMap):
--   f1 = reta E-W    (bocas W e E)
--   f2 = reta N-S    (bocas N e S)
--   f3 = curva NE    (entra por N, sai por E)
--   f4 = curva SE    (entra por S, sai por E)
--   f5 = curva SW    (entra por S, sai por W)
--   f6 = curva NW    (entra por N, sai por W)
--   f7 = junção T    (bocas N+E+W, sem boca S — espelho vertical dá
--        S+E+W; rotações de 90° cobrem N+E+S e S+W+N)
--   f8 = cruzamento  (bocas N+E+S+W)
--   f9 = cap/ponta   (boca só em W: a faixa entra pela esquerda e
--        morre em ponta arredondada ~x=53 — espelhos/rotações
--        cobrem pontas E, N e S)
--
-- CONTINUIDADE: toda boca abre na faixa canônica [19,45] da aresta
-- (27 px, centro 32). O wobble das bordas e das linhas zera a ~5 px
-- de cada boca, então faixas adjacentes encaixam sem degrau: f1 sai
-- em x=64 exatamente onde o vizinho entra em x=1.
--
-- LEITURA: margem externa = piso_terra comum ('a' + manchas 'd' +
-- pedrinhas + tufos 'g'/'t' — musgo SÓ fora da faixa). Miolo 'b'
-- (barro claro pisado) com sulcos 'd'/'r' PARALELOS à direção de
-- viagem e pegadas raras. Borda ralhada ~2 px dos dois lados da
-- faixa: poeira clara 'c' + pedrinha 'p'/'q' em clusters + brecha
-- 'a' — linha orgânica, nunca reta.
-- h: pegada/sulco fundo 0, massa/borda 1, pedrinha 2.

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

-- Wobble por nós (determinístico): 0 nas pontas do domínio + rampa de
-- ~14 u — TODA boca chega na aresta na faixa canônica [19,45].
local function wobline(u, u0, u1, seed, amp)
    local knots = { u0 }
    local vals = { 0 }
    for i = 1, 4 do
        knots[#knots + 1] = u0 + (u1 - u0) * (0.16 + 0.17 * i)
        vals[#vals + 1] = math.floor(
            (hash2(i * 17, seed * 3 + i, seed) * 2 - 1) * amp + 0.5)
    end
    knots[#knots + 1] = u1
    vals[#vals + 1] = 0
    local v = 0
    for i = 1, #knots - 1 do
        if u >= knots[i] and u <= knots[i + 1] then
            local t = (u - knots[i]) / (knots[i + 1] - knots[i])
            v = vals[i] + (vals[i + 1] - vals[i]) * t
            break
        end
    end
    local t1 = math.min(1, math.max(0, (u - u0 - 5) / 9))
    local t2 = math.min(1, math.max(0, (u1 - 5 - u) / 9))
    return v * math.min(t1, t2)
end

--------------------------------------------------------------------------------
-- Geometria das faixas (máscaras booleanas + arrays de borda p/ sulcos)
--------------------------------------------------------------------------------

-- Reta E-W: por coluna, linhas top[x]..bot[x]. Bocas W e E em [19,45].
local function bandEW(seed)
    local band, top, bot = nova(false), {}, {}
    for x = 1, W do
        top[x] = math.floor(19.5 + wobline(x, 1, W, seed, 3))
        bot[x] = math.floor(45.5 + wobline(x, 1, W, seed + 31, 3))
        for y = top[x], bot[x] do band[y][x] = true end
    end
    return band, top, bot
end

-- Reta N-S: por linha, colunas left[y]..right[y]. Bocas N e S.
local function bandNS(seed)
    local band, left, right = nova(false), {}, {}
    for y = 1, H do
        left[y] = math.floor(19.5 + wobline(y, 1, H, seed, 3))
        right[y] = math.floor(45.5 + wobline(y, 1, H, seed + 31, 3))
        for x = left[y], right[y] do band[y][x] = true end
    end
    return band, left, right
end

-- Braço que nasce em N e desce até y1 (junção T). Boca N canônica.
local function armN(seed, y1)
    local band, left, right = nova(false), {}, {}
    for y = 1, y1 do
        left[y] = math.floor(19.5 + wobline(y, 1, H, seed + 50, 3))
        right[y] = math.floor(45.5 + wobline(y, 1, H, seed + 81, 3))
        for x = left[y], right[y] do band[y][x] = true end
    end
    return band, left, right
end

-- Curva de 90°: quarto de anel centrado logo fora do canto (cx,cy).
-- kx,ky orientam o quadrante; ponto do anel = (cx + kx·r·cosφ,
-- cy + ky·r·sinφ) com φ∈[0,90]. Raios [19.1,46.3] foram ajustados
-- para a boca abrir EXATAMENTE em [19,45] nas duas arestas.
local function bandCurva(cx, cy, kx, ky, seed)
    local band = nova(false)
    for y = 1, H do for x = 1, W do
        local dx, dy = x - cx, y - cy
        local ux, uy = dx * kx, dy * ky      -- >0 dentro do quadrante
        if ux > 0 and uy > 0 then
            local r = math.sqrt(dx * dx + dy * dy)
            local phi = atan2(uy, ux) * 180 / math.pi
            local r1 = 19.1 + wobline(phi, 0, 90, seed, 3)
            local r2 = 46.3 + wobline(phi, 0, 90, seed + 31, 3)
            if r >= r1 and r <= r2 then band[y][x] = true end
        end
    end end
    return band
end

-- Ponta cega: reta E-W que afunila em arco (quarto de elipse) e morre
-- ~x=53. Boca só em W.
local function bandCapW(seed)
    local band, top, bot = nova(false), {}, {}
    local X0, X1 = 38, 53
    for x = 1, W do
        local w1 = wobline(x, 1, W, seed, 3)
        local w2 = wobline(x, 1, W, seed + 31, 3)
        if x <= X0 then
            top[x] = math.floor(19.5 + w1)
            bot[x] = math.floor(45.5 + w2)
        elseif x <= X1 then
            local t = (x - X0) / (X1 - X0)
            local mid = (19.5 + w1 + 45.5 + w2) * 0.5
            local hh = ((45.5 + w2) - (19.5 + w1)) * 0.5
                * math.sqrt(math.max(0, 1 - t * t))
                * (0.85 + hash2(x, 7, seed) * 0.3) -- ponta ralhada
            top[x] = math.floor(mid - hh + 0.5)
            bot[x] = math.floor(mid + hh - 0.5)
        else
            top[x], bot[x] = 33, 31 -- vazio
        end
        for y = top[x], bot[x] do band[y][x] = true end
    end
    return band, top, bot
end

local function union(a, b)
    local u = nova(false)
    for y = 1, H do for x = 1, W do
        u[y][x] = a[y][x] or b[y][x]
    end end
    return u
end

--------------------------------------------------------------------------------
-- Anéis morfológicos: distância da borda p/ miolo, linha e sulcos
--------------------------------------------------------------------------------
local function aneis(band)
    local r1, r2, r3, deep = nova(false), nova(false), nova(false), nova(false)
    local function at(t, x, y) return t[y] and t[y][x] end
    for y = 1, H do for x = 1, W do
        if band[y][x] then
            if not (at(band, x - 1, y) and at(band, x + 1, y)
                and at(band, x, y - 1) and at(band, x, y + 1)) then
                r1[y][x] = true
            end
        end
    end end
    for y = 1, H do for x = 1, W do
        if band[y][x] and not r1[y][x]
            and (at(r1, x - 1, y) or at(r1, x + 1, y)
                or at(r1, x, y - 1) or at(r1, x, y + 1)) then
            r2[y][x] = true
        end
    end end
    for y = 1, H do for x = 1, W do
        if band[y][x] and not r1[y][x] and not r2[y][x] then
            if at(r2, x - 1, y) or at(r2, x + 1, y)
                or at(r2, x, y - 1) or at(r2, x, y + 1) then
                r3[y][x] = true
            else
                deep[y][x] = true
            end
        end
    end end
    return r1, r2, r3, deep
end

--------------------------------------------------------------------------------
-- Carimbos da margem (mesma linguagem do piso_terra)
--------------------------------------------------------------------------------
local MASSA_D2 = {
    '..ddddd....',
    '.dddddddd..',
    'ddddddddd..',
    'ddddddddd..',
    '.ddddddd...',
    '..ddddd....',
}
local MASSA_D3 = {
    '...dddddd...',
    '..dddddddd..',
    '.ddddddddd..',
    '.dddddddd...',
    '..dddddd....',
}
local MASSA_P1 = {
    '.ddd.',
    'ddddd',
    'ddd..',
    '.d...',
}
local MASSA_P2 = {
    'dd..',
    'ddd.',
    'dddd',
    '.dd.',
}
local MASSA_L2 = {
    '.ddddddddddddd..',
    'ddddddddddddddd.',
    'dddddddddddddd..',
    '.dddddddddddd...',
    '...dddddddd.....',
}
local MASSA_G2 = {
    '....ddddddd......',
    '..dddddddddddd...',
    '.dddddddddddddd..',
    'dddddddddddddd...',
    'dddddddddddddd...',
    '.dddddddddddddd..',
    '...dddddddddd....',
    '.....dddddd......',
}
local DESG_B = {
    '...bbbbbbb...',
    '..bbbbbbbbb..',
    '.bbbbbbbbbbb.',
    'bbbbbbbbbbbb.',
    '.bbbbbbbbb...',
    '...bbbbbb....',
}
local PEDRA_A = {
    '.pp..',
    'pqqp.',
    '.uu..',
}
local PEDRA_B = {
    '.p.pp',
    'ppqpp',
    'u.uu.',
}
local PEDRA_E = {
    '.pp.',
    'pqp.',
    '.u..',
}
local TUFO_A = {
    't.t.',
    'tgtg',
    'gggg',
}
local TUFO_B = {
    '.t.t',
    'gtgt',
    'ggg.',
}

-- Carimbo que só escreve na MARGEM (nunca pisa na faixa — garante o
-- "musgo só na margem externa" por construção, não por sorte).
local function carimboOut(g, band, x, y, forma)
    for j = 1, #forma do
        for i = 1, #forma[j] do
            local c = forma[j]:sub(i, i)
            local tx, ty = x + i - 1, y + j - 1
            if c ~= '.' and tx >= 1 and tx <= W and ty >= 1 and ty <= H
                and not band[ty][tx] then
                g[ty][tx] = c
            end
        end
    end
end

-- Margem de terra comum: manchas, manchão raro, pedrinhas, desgaste
-- e tufos — quantidade escala com a área livre de cada frame.
local function margem(g, band, seed)
    local outs = {}
    for y = 1, H do for x = 1, W do
        if not band[y][x] then outs[#outs + 1] = { x, y } end
    end end
    local n = #outs
    local function alvo(i, fw, fh, salt)
        local p = outs[1 + math.floor(hash2(i * 11 + salt, seed + i, seed) * n)]
        return p[1] - math.floor(fw / 2), p[2] - math.floor(fh / 2)
    end
    local MANCHAS = { MASSA_D2, MASSA_D3, MASSA_P1, MASSA_L2, MASSA_P2 }
    for i = 1, 2 + math.floor(n / 450) do
        local f = MANCHAS[1 + math.floor(hash2(i * 3, seed + 5, i) * #MANCHAS)]
        local ox, oy = alvo(i, #f[1], #f, 0)
        carimboOut(g, band, ox, oy, f)
    end
    if hash2(4, seed, 7) < 0.6 then -- manchão raro, típico das curvas
        local ox, oy = alvo(99, #MASSA_G2[1], #MASSA_G2, 5)
        carimboOut(g, band, ox, oy, MASSA_G2)
    end
    local PEDRAS = { PEDRA_A, PEDRA_B, PEDRA_E }
    for i = 1, 2 + math.floor(n / 1100) do
        local f = PEDRAS[1 + math.floor(hash2(i * 5, seed + 9, i) * #PEDRAS)]
        local ox, oy = alvo(i, #f[1], #f, 20)
        carimboOut(g, band, ox, oy, f)
    end
    for i = 1, 1 + math.floor(n / 1400) do
        local ox, oy = alvo(i, #DESG_B[1], #DESG_B, 40)
        carimboOut(g, band, ox, oy, DESG_B)
    end
    local TUFOS = { TUFO_A, TUFO_B }
    for i = 1, 2 + math.floor(n / 800) do
        local f = TUFOS[1 + math.floor(hash2(i * 7, seed + 13, i) * #TUFOS)]
        local ox, oy = alvo(i, #f[1], #f, 60)
        carimboOut(g, band, ox, oy, f)
    end
    -- salpico miúdo de torrões/desgaste na terra comum
    for y = 1, H do for x = 1, W do
        if not band[y][x] then
            local h = hash2(x, y, seed + 80)
            if h < 0.012 then g[y][x] = 'd'
            elseif h < 0.020 then g[y][x] = 'b' end
        end
    end end
end

--------------------------------------------------------------------------------
-- Miolo + borda ralhada
--------------------------------------------------------------------------------
local function mioloEBorda(g, band, r1, r2, r3, seed)
    for y = 1, H do for x = 1, W do
        if band[y][x] then
            -- linha de borda ~2 px ralhada: anel 1 sempre, anel 2 em
            -- 62%, anel 3 raro — espessura 1-3 px irregular.
            local edge = r1[y][x]
                or (r2[y][x] and hash2(x, y, seed + 40) < 0.62)
                or (r3[y][x] and hash2(x, y, seed + 42) < 0.12)
            if edge then
                local h = hash2(x, y, seed + 60)
                local cl = hash2(math.floor((x - 1) / 3),
                    math.floor((y - 1) / 3), seed + 70)
                if h < 0.07 then g[y][x] = 'a'       -- brecha de terra
                elseif cl < 0.14 then g[y][x] = 'p'  -- pedrinha na linha
                elseif cl < 0.22 then g[y][x] = 'q'
                else g[y][x] = 'c' end               -- poeira clara
            else
                local h = hash2(x, y, seed + 55)
                if h < 0.045 then g[y][x] = 'a'      -- terra invade miolo
                elseif h < 0.075 then g[y][x] = 'd'  -- mancha no pisado
                elseif h > 0.985 then g[y][x] = 'c'  -- grão claro raro
                else g[y][x] = 'b' end
            end
        end
    end end
end

--------------------------------------------------------------------------------
-- Sulcos (paralelos à viagem) e pegadas — só escrevem em `deep`
--------------------------------------------------------------------------------
local function sulcoH(g, deep, top, bot, off, seg, seed)
    for x = seg[1], seg[2] do
        local y = math.floor((top[x] + bot[x]) * 0.5 + off + 0.5)
        if deep[y] and deep[y][x] then
            local h = hash2(x, y, seed + 90)
            g[y][x] = h < 0.10 and 'r' or 'd'
            if h < 0.30 and deep[y + 1] and deep[y + 1][x] then
                g[y + 1][x] = 'd'
            end
        end
    end
end

local function sulcoV(g, deep, left, right, off, seg, seed)
    for y = seg[1], seg[2] do
        if left[y] then
            local x = math.floor((left[y] + right[y]) * 0.5 + off + 0.5)
            if deep[y] and deep[y][x] then
                local h = hash2(x, y, seed + 90)
                g[y][x] = h < 0.10 and 'r' or 'd'
                if h < 0.30 and deep[y][x + 1] then
                    g[y][x + 1] = 'd'
                end
            end
        end
    end
end

local function sulcoArc(g, deep, cx, cy, kx, ky, roff, seg, seed)
    for deg = seg[1], seg[2], 0.8 do
        local phi = deg * math.pi / 180
        local r = 32.7 + roff
        local x = math.floor(cx + kx * r * math.cos(phi) + 0.5)
        local y = math.floor(cy + ky * r * math.sin(phi) + 0.5)
        if deep[y] and deep[y][x] then
            local h = hash2(x, y, seed + 90)
            g[y][x] = h < 0.10 and 'r' or 'd'
            if h < 0.30 then
                local r2 = r + 1.4
                local x2 = math.floor(cx + kx * r2 * math.cos(phi) + 0.5)
                local y2 = math.floor(cy + ky * r2 * math.sin(phi) + 0.5)
                if deep[y2] and deep[y2][x2] then g[y2][x2] = 'd' end
            end
        end
    end
end

local function pegadaH(g, deep, top, bot, x0, x1)
    local i = 0
    for x = x0, x1, 5 do
        i = i + 1
        local y = math.floor((top[x] + bot[x]) * 0.5
            + (i % 2 == 0 and 3 or -3) + 0.5)
        if deep[y] and deep[y][x] then
            g[y][x] = 'r'
            if deep[y + 1] and deep[y + 1][x] then g[y + 1][x] = 'r' end
        end
    end
end

local function pegadaV(g, deep, left, right, y0, y1)
    local i = 0
    for y = y0, y1, 5 do
        if left[y] then
            i = i + 1
            local x = math.floor((left[y] + right[y]) * 0.5
                + (i % 2 == 0 and 3 or -3) + 0.5)
            if deep[y] and deep[y][x] then
                g[y][x] = 'r'
                if deep[y][x + 1] then g[y][x + 1] = 'r' end
            end
        end
    end
end

local function pegadaArc(g, deep, cx, cy, kx, ky, d0, d1)
    local i = 0
    for deg = d0, d1, 7 do
        i = i + 1
        local phi = deg * math.pi / 180
        local r = 32.7 + (i % 2 == 0 and 3 or -3)
        local x = math.floor(cx + kx * r * math.cos(phi) + 0.5)
        local y = math.floor(cy + ky * r * math.sin(phi) + 0.5)
        if deep[y] and deep[y][x] then
            g[y][x] = 'r'
            local r2 = r + 1.4
            local x2 = math.floor(cx + kx * r2 * math.cos(phi) + 0.5)
            local y2 = math.floor(cy + ky * r2 * math.sin(phi) + 0.5)
            if deep[y2] and deep[y2][x2] then g[y2][x2] = 'r' end
        end
    end
end

--------------------------------------------------------------------------------
-- Montagem: margem -> miolo+borda -> sulcos/pegadas (clipados em deep)
--------------------------------------------------------------------------------
local function monta(band, seed, deco)
    local g = nova('a')
    margem(g, band, seed)
    local r1, r2, r3, deep = aneis(band)
    mioloEBorda(g, band, r1, r2, r3, seed)
    if deco then deco(g, deep) end
    return str(g)
end

-- f1 — reta E-W
local function f1()
    local seed = 101
    local band, top, bot = bandEW(seed)
    return monta(band, seed, function(g, deep)
        sulcoH(g, deep, top, bot, -6, { 4, 26 }, seed)
        sulcoH(g, deep, top, bot, -6, { 33, 49 }, seed + 1)
        sulcoH(g, deep, top, bot, -6, { 55, 61 }, seed + 2)
        sulcoH(g, deep, top, bot, 6, { 8, 23 }, seed + 3)
        sulcoH(g, deep, top, bot, 6, { 31, 44 }, seed + 4)
        sulcoH(g, deep, top, bot, 6, { 51, 60 }, seed + 5)
        for i = 0, 6 do -- escoriação diagonal curta
            local x, y = 26 + i, 35 + math.floor(i * 0.6)
            if deep[y] and deep[y][x] then g[y][x] = 'd' end
        end
        pegadaH(g, deep, top, bot, 12, 36)
        pegadaH(g, deep, top, bot, 44, 58)
    end)
end

-- f2 — reta N-S
local function f2()
    local seed = 103
    local band, left, right = bandNS(seed)
    return monta(band, seed, function(g, deep)
        sulcoV(g, deep, left, right, -6, { 5, 24 }, seed)
        sulcoV(g, deep, left, right, -6, { 31, 50 }, seed + 1)
        sulcoV(g, deep, left, right, -6, { 55, 61 }, seed + 2)
        sulcoV(g, deep, left, right, 6, { 7, 22 }, seed + 3)
        sulcoV(g, deep, left, right, 6, { 30, 46 }, seed + 4)
        sulcoV(g, deep, left, right, 6, { 52, 60 }, seed + 5)
        for i = 0, 6 do -- escoriação diagonal curta
            local x, y = 38 + math.floor(i * 0.6), 24 + i
            if deep[y] and deep[y][x] then g[y][x] = 'd' end
        end
        pegadaV(g, deep, left, right, 10, 34)
        pegadaV(g, deep, left, right, 42, 60)
    end)
end

-- f3..f6 — curvas: anel centrado fora do canto da curva.
local function curva(seed, cx, cy, kx, ky)
    local band = bandCurva(cx, cy, kx, ky, seed)
    return monta(band, seed, function(g, deep)
        sulcoArc(g, deep, cx, cy, kx, ky, -6, { 16, 36 }, seed)
        sulcoArc(g, deep, cx, cy, kx, ky, -6, { 46, 62 }, seed + 1)
        sulcoArc(g, deep, cx, cy, kx, ky, 6, { 20, 42 }, seed + 2)
        sulcoArc(g, deep, cx, cy, kx, ky, 6, { 52, 78 }, seed + 3)
        pegadaArc(g, deep, cx, cy, kx, ky, 26, 48)
        pegadaArc(g, deep, cx, cy, kx, ky, 60, 78)
    end)
end

-- f7 — T com bocas N+E+W (sem S)
local function f7()
    local seed = 131
    local ew, top, bot = bandEW(seed)
    local arm, left, right = armN(seed, 40)
    return monta(union(ew, arm), seed, function(g, deep)
        sulcoH(g, deep, top, bot, -6, { 4, 24 }, seed)
        sulcoH(g, deep, top, bot, -6, { 40, 60 }, seed + 1)
        sulcoH(g, deep, top, bot, 6, { 8, 22 }, seed + 2)
        sulcoH(g, deep, top, bot, 6, { 42, 58 }, seed + 3)
        sulcoV(g, deep, left, right, -5, { 4, 24 }, seed + 4)
        sulcoV(g, deep, left, right, 5, { 8, 26 }, seed + 5)
        pegadaH(g, deep, top, bot, 6, 20)
        pegadaH(g, deep, top, bot, 46, 60)
        pegadaV(g, deep, left, right, 4, 24)
    end)
end

-- f8 — cruzamento (bocas N+E+S+W)
local function f8()
    local seed = 137
    local ew, top, bot = bandEW(seed)
    local ns, left, right = bandNS(seed + 11)
    return monta(union(ew, ns), seed, function(g, deep)
        sulcoH(g, deep, top, bot, -6, { 4, 26 }, seed)
        sulcoH(g, deep, top, bot, -6, { 40, 61 }, seed + 1)
        sulcoH(g, deep, top, bot, 6, { 8, 24 }, seed + 2)
        sulcoH(g, deep, top, bot, 6, { 42, 60 }, seed + 3)
        sulcoV(g, deep, left, right, -6, { 4, 26 }, seed + 4)
        sulcoV(g, deep, left, right, -6, { 40, 60 }, seed + 5)
        sulcoV(g, deep, left, right, 6, { 8, 24 }, seed + 6)
        sulcoV(g, deep, left, right, 6, { 42, 58 }, seed + 7)
        pegadaH(g, deep, top, bot, 8, 22)
        pegadaV(g, deep, left, right, 8, 22)
    end)
end

-- f9 — ponta cega com boca só em W
local function f9()
    local seed = 139
    local band, top, bot = bandCapW(seed)
    return monta(band, seed, function(g, deep)
        sulcoH(g, deep, top, bot, -6, { 4, 30 }, seed)
        sulcoH(g, deep, top, bot, -6, { 34, 42 }, seed + 1)
        sulcoH(g, deep, top, bot, 6, { 8, 28 }, seed + 2)
        sulcoH(g, deep, top, bot, 6, { 32, 40 }, seed + 3)
        pegadaH(g, deep, top, bot, 10, 32)
    end)
end

return {
    name = 'piso_caminho',
    w = 64, h = 64,
    origin = 'topleft',
    frameUse = 'direction', -- 9 frames = direções da rota, ver header
    -- mapa de frames p/ o renderer (curvas e bocas faltantes por
    -- espelho/rotação do quad):
    frameMap = { 'ew', 'ns', 'ne', 'se', 'sw', 'nw',
        't_nwe', 'cross', 'cap_w' },

    legend = {
        -- margem = mesmos chars/passos do piso_terra (transição suave)
        a = { ramp = 'earth', step = 4, h = 1 }, -- massa de barro
        d = { ramp = 'earth', step = 2, h = 1 }, -- mancha funda / sulco
        r = { ramp = 'earth', step = 1, h = 0 }, -- pegada / sulco fundo
        b = { ramp = 'earth', step = 6, h = 1 }, -- miolo desgastado
        c = { ramp = 'earth', step = 7, h = 1 }, -- poeira clara da borda
        u = { ramp = 'earth', step = 2, h = 1 }, -- sombra sob pedrinha
        p = { ramp = 'stone', step = 5, h = 2 }, -- pedrinha, luz
        q = { ramp = 'stone', step = 3, h = 2 }, -- pedrinha, sombra
        g = { ramp = 'moss',  step = 2, h = 1 }, -- tufo, SÓ margem
        t = { ramp = 'moss',  step = 4, h = 2 }, -- lâmina, SÓ margem
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = {
                f1(), f2(),
                curva(107, 65, -0.5, -1, 1),   -- f3 NE (entra N, sai E)
                curva(109, 65, 64.5, -1, -1),  -- f4 SE (entra S, sai E)
                curva(113, -0.5, 64.5, 1, -1), -- f5 SW (entra S, sai W)
                curva(127, -0.5, -0.5, 1, 1),  -- f6 NW (entra N, sai W)
                f7(), f8(), f9(),
            },
        },
    },
}
