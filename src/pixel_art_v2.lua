-- Pixel art v2: tiles e tabuleiros assados em canvas (Melhorando-tiles-com-
-- código.md). Tudo procedural — nenhum asset externo. Cada célula leva a
-- pilha base + outline de 4 vizinhos + bevel + variação determinística +
-- dithering Bayer; o resultado é um único canvas por sala, desenhado uma
-- vez e reutilizado todo frame.
local Rooms = require('src.rooms')
local Pal = require('src.palettes')
local G = love.graphics
local PixelArt = {}

local function round(n) return math.floor(n + .5) end
local function px(x, y, w, h, c, a)
    G.setColor(c[1], c[2], c[3], a or 1)
    G.rectangle('fill', round(x), round(y), round(w), round(h))
end

-- Variação estável por célula: a mesma sala revisita o mesmo desgaste.
local function hash(seed, x, y)
    return ((seed or 0) * 17 + x * 37 + y * 101 + (x * y) * 7) % 97
end

-- Bayer 4x4: sombra simulada por pontos em vez de alpha (mantém o pixel duro).
local BAYER = {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}
local function dither(x, y, w, h, c, t)
    x, y, w, h = round(x), round(y), round(w), round(h)
    G.setColor(c[1], c[2], c[3], 1)
    for j = 0, h - 1 do for i = 0, w - 1 do
        if BAYER[(y + j) % 4 + 1][(x + i) % 4 + 1] / 16 < t then
            G.rectangle('fill', x + i, y + j, 1, 1)
        end
    end end
end
PixelArt.dither = dither

-- Elipse dithered: cada pixel dentro da elipse passa pelo limiar Bayer.
-- Serve para sombras de contato e brumas sem alpha suave.
local function ditherEllipse(cx, cy, rx, ry, c, t)
    cx, cy, rx, ry = round(cx), round(cy), round(rx), round(ry)
    if rx < 1 or ry < 1 then return end
    G.setColor(c[1], c[2], c[3], 1)
    for j = -ry, ry do for i = -rx, rx do
        if (i * i) / (rx * rx) + (j * j) / (ry * ry) <= 1
            and BAYER[((cy + j) % 4) + 1][((cx + i) % 4) + 1] / 16 < t then
            G.rectangle('fill', cx + i, cy + j, 1, 1)
        end
    end end
end
PixelArt.ditherEllipse = ditherEllipse

-- Halo radial dithered: densidade cai com a distância — luz de chama ou
-- bruma sem gradiente suave. `power` limita a densidade máxima no centro.
local function halo(x, y, rx, ry, c, power)
    x, y, rx, ry = round(x), round(y), round(rx), round(ry)
    if rx < 1 or ry < 1 then return end
    G.setColor(c[1], c[2], c[3], 1)
    for j = -ry, ry do for i = -rx, rx do
        local d = (i * i) / (rx * rx) + (j * j) / (ry * ry)
        if d <= 1
            and BAYER[((y + j) % 4) + 1][((x + i) % 4) + 1] / 16 < (1 - d) * (power or .5) then
            G.rectangle('fill', x + i, y + j, 1, 1)
        end
    end end
end
PixelArt.halo = halo

-- ── Poça de luz em rampa ─────────────────────────────────────────────
-- Núcleo claro → anel médio → borda dissolvendo em pontos. O caminho CPU
-- empilha três halos Bayer; o shader opcional (GPU) desenha a mesma rampa
-- com degraus suaves e cauda dispersa — sempre estático (reduced-motion
-- intacto) e sempre por texel do canvas (nearest, sem smooth). Sem shader
-- compilando, ou com ARROWFALLEN_NO_SHADER=1, cai nos três anéis de antes.
local glowTried, glowObj = false, nil
local function glowShader()
    if glowTried then return glowObj end
    glowTried = true
    if os.getenv('ARROWFALLEN_NO_SHADER') then return nil end
    local ok, sh = pcall(G.newShader, [[
        uniform vec2 glowCenter;
        uniform vec2 glowRadii;
        uniform vec4 glowTint;
        uniform vec4 glowCore;
        uniform float glowPower;
        float hash12(vec2 p) {
            return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
        }
        vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
            vec2 d = (sc - glowCenter) / max(glowRadii, vec2(1.0));
            float dist = dot(d, d);
            if (dist > 1.0) return vec4(0.0);
            float t = sqrt(dist);
            // Degraus da rampa (núcleo→anel→borda) com a cauda dissolvendo
            // em pontos por texel — mesma alma do dither Bayer do fallback.
            float ramp = 1.0 - t;
            float a = floor(ramp * 5.0 + 0.5) / 5.0;
            if (t > 0.62 && hash12(floor(sc)) > ramp * 3.2) return vec4(0.0);
            vec3 col = mix(glowTint.rgb, glowCore.rgb, smoothstep(0.6, 0.05, t));
            return vec4(col, a * glowPower) * color;
        }
    ]])
    if ok and sh then
        glowObj = sh
    else
        print('[pixel_art_v2] glow shader indisponível — fallback dither: '
            .. tostring(sh))
    end
    return glowObj
end

local function lightPool(cx, cy, rx, ry, tint, power, core)
    cx, cy = round(cx), round(cy)
    rx, ry = round(rx), round(ry)
    if rx < 1 or ry < 1 then return end
    core = core or (tint == Pal.ember and Pal.emberLight or Pal.white)
    power = power or .5
    local sh = glowShader()
    if sh then
        -- O shader opera em texel de CANVAS; o centro chega em mundo —
        -- converte pelo transform ativo (câmera/shake/scale).
        local sx, sy = G.transformPoint(cx, cy)
        local ex, ey = G.transformPoint(cx + rx, cy + ry)
        local srx, sry = math.max(1, math.abs(ex - sx)), math.max(1, math.abs(ey - sy))
        sh:send('glowCenter', {sx, sy})
        sh:send('glowRadii', {srx, sry})
        sh:send('glowTint', {tint[1], tint[2], tint[3], 1})
        sh:send('glowCore', {core[1], core[2], core[3], 1})
        sh:send('glowPower', power)
        G.setShader(sh)
        G.setColor(1, 1, 1, 1)
        G.rectangle('fill', cx - rx, cy - ry, rx * 2, ry * 2)
        G.setShader()
        return
    end
    halo(cx, cy, rx, ry, tint, power * .5)
    halo(cx, cy, math.max(1, round(rx * .62)), math.max(1, round(ry * .62)), tint, power)
    halo(cx, cy, math.max(1, round(rx * .28)), math.max(1, round(ry * .28)), core, power * .85)
end
PixelArt.lightPool = lightPool

-- Bevel: luz no alto à esquerda, sombra embaixo à direita.
local function bevel(x, y, w, h, light, dark, a)
    px(x, y, w, 1, light, a); px(x, y + 1, 1, h - 1, light, a * .7)
    px(x, y + h - 1, w, 1, dark, a); px(x + w - 1, y + 1, 1, h - 1, dark, a * .8)
end
PixelArt.bevel = bevel

-- Célula do tabuleiro de batalha: lajes em blocos 2×2 com tom próprio por
-- bloco, juntas rasas dentro do bloco e profundas entre blocos — a grade de
-- jogo continua legível, mas como pedra assentada, não papel quadriculado.
-- O luar entra de cima-esquerda: bevels claros no alto e sombra fria nas
-- bordas externas. `ctx` traz os limites da arena para a cerimonial.
local function boardCell(x, y, n, ctx)
    local X, Y = (x - 1) * 32, (y - 1) * 32
    local bx, by = math.floor((x - 1) / 2), math.floor((y - 1) / 2)
    local bn = hash(ctx and ctx.seed or 0, bx * 3 + 5, by * 7 + 2)
    -- Tom da laje por BLOCO, com células individuais fugindo do bloco: é a
    -- fuga que quebra a leitura de manta uniforme — uma laje deslocada ou
    -- gasta aqui e ali basta.
    local slab = (bx + by) % 2 == 0
    local base = slab and Pal.board.base or Pal.board.dark
    if bn > 80 then base = Pal.board.light
    elseif bn < 11 then base = Pal.board.seam end
    if n % 13 == 5 then base = Pal.board.dark
    elseif n % 17 == 10 then base = Pal.board.light end
    if n % 31 == 7 then base = Pal.board.worn end  -- laje lavada pelo luar
    px(X, Y, 32, 32, base)
    -- Laje desgastada: manchas frias dithered em duas densidades — o piso
    -- varia por célula, não só por bloco.
    if bn % 7 == 3 then dither(X + 4, Y + 4, 24, 22, Pal.board.dark, .22) end
    if n % 9 == 2 then dither(X + 3, Y + 5, 26, 20, Pal.board.seam, .18) end
    if n % 11 == 7 then dither(X + 5, Y + 3, 22, 22, Pal.board.worn, .16) end
    -- Bruma de luz cerimonial: o centro da arena é mais claro; a borda
    -- afunda em desgaste escuro, com cantos lascados mostrando a sombra.
    if ctx then
        local dx, dy = x - ctx.cx, y - ctx.cy
        local d = math.sqrt(dx * dx + dy * dy) / ctx.r
        if d < .9 then dither(X + 1, Y + 1, 30, 30, Pal.board.light, (1 - d / .9) * .3) end
        -- Luar de cima-ESQUERDA: a rampa de valor cruza linhas e colunas —
        -- as lajes altas e esquerdas lavam, as baixas e direitas afundam.
        local rowT = (y - ctx.y0) / math.max(1, ctx.y1 - ctx.y0)
        local colT = (x - ctx.x0) / math.max(1, ctx.x1 - ctx.x0)
        local sun = 1 - (rowT * .6 + colT * .4)
        if sun > .55 then dither(X + 1, Y + 1, 30, 30, Pal.board.edge, (sun - .55) * .28) end
        if sun < .35 then dither(X + 1, Y + 1, 30, 30, Pal.ink, (.35 - sun) * .34) end
        local edge = x == ctx.x0 or x == ctx.x1 or y == ctx.y0 or y == ctx.y1
        if edge then
            dither(X, Y, 32, 32, Pal.ink, .18)
            px(X, Y + 30, 32, 2, Pal.board.seamDeep, .6)
            -- Bordas lascadas: as lajes do contorno perdem pedaços ao acaso
            -- estável — a plataforma é velha e comida pelo tempo.
            if n % 7 == 1 then
                px(X, Y + 24, 2, 6, Pal.board.seamDeep); px(X + 1, Y + 22, 1, 3, Pal.board.seamDeep)
            end
            if n % 9 == 4 then
                px(X + 26, Y, 6, 2, Pal.board.seamDeep); px(X + 29, Y + 2, 3, 1, Pal.board.seamDeep)
            end
        end
        if x == ctx.x0 then px(X, Y, 2, 32, Pal.ink, .55) end
        if x == ctx.x1 then px(X + 30, Y, 2, 32, Pal.ink, .55) end
        if y == ctx.y0 then px(X, Y, 32, 2, Pal.ink, .55) end
        if y == ctx.y1 then px(X, Y + 30, 32, 2, Pal.ink, .55) end
    end
    -- Juntas: cima/esquerda rasas, direita/baixo profundas. Entre blocos a
    -- junta engrossa com um segundo traço — placas grandes separam de lajes.
    -- A junta INTERNA do bloco é quebrada em lanços: pedra assentada, não
    -- papel quadriculado — a grade de jogo sobrevive pelos encontros.
    px(X, Y, 32, 1, Pal.board.seam)
    px(X, Y, 1, 32, Pal.board.seam)
    px(X, Y + 31, 32, 1, Pal.board.seamDeep)
    px(X + 31, Y, 1, 32, Pal.board.seamDeep)
    if x % 2 == 0 then
        -- junta interna vertical: segmentos com falha no meio
        px(X, Y + 3, 1, 10, Pal.board.seam); px(X, Y + 19, 1, 10, Pal.board.seam)
        px(X, Y + 12, 1, 2, Pal.board.seamDeep, .5)
    end
    if y % 2 == 0 then
        px(X + 3, Y, 10, 1, Pal.board.seam); px(X + 19, Y, 10, 1, Pal.board.seam)
        px(X + 14, Y, 2, 1, Pal.board.seamDeep, .5)
    end
    if x % 2 == 1 and x > 1 then px(X, Y + 1, 1, 30, Pal.board.seamDeep) end
    if y % 2 == 1 and y > 1 then px(X + 1, Y, 30, 1, Pal.board.seamDeep) end
    -- Embutido de jade em juntas escolhidas: pips nos encontros de bloco,
    -- espaçados e determinísticos — cerimonial, não aleatório.
    if bn % 11 == 4 then px(X + 1, Y + 1, 2, 2, Pal.jade.dark, .85) end
    if bn % 23 == 7 then
        px(X + 14, Y + 31, 4, 1, Pal.jade.dark, .8)
        px(X + 15, Y + 31, 2, 1, Pal.jade.base, .55)
    end
    -- Musgo de sepultura e capim morto: tufos frios escuros em cantos de
    -- junta e fios secos marrons nascendo das bordas — matéria orgânica
    -- sem sugerir colisão.
    if n % 17 == 6 then
        px(X + 1, Y + 27, 1, 3, Pal.jade.dark); px(X + 2, Y + 28, 2, 2, Pal.jade.dark)
        px(X + 1, Y + 28, 1, 1, Pal.jade.base, .6)
    end
    if n % 19 == 8 then
        px(X + 27, Y + 4, 1, 3, Pal.gold.dark); px(X + 28, Y + 5, 1, 2, Pal.gold.dark)
        px(X + 26, Y + 6, 2, 1, Pal.jade.dark)
    end
    -- Cascalho solto: grãos de pedra em duas cores perto das juntas.
    if n % 23 == 10 then
        px(X + 9, Y + 21, 2, 2, Pal.board.seam); px(X + 22, Y + 26, 1, 1, Pal.board.edge)
        px(X + 10, Y + 21, 1, 1, Pal.board.edge)
    end
    -- Bevel curto de topo-esquerda mantém o volume da laje ao luar.
    px(X + 1, Y + 1, 14, 1, Pal.board.edge, .3)
    px(X + 1, Y + 1, 1, 9, Pal.board.edge, .18)
    -- Desgaste: rachaduras com direção (todas cedem para baixo-direita, como
    -- se o peso do monumento rachasse o piso), lascas e manchas.
    if n % 11 == 2 then
        px(X + 6, Y + 5, 1, 7, Pal.board.seamDeep)
        px(X + 7, Y + 12, 1, 6, Pal.board.seamDeep)
        px(X + 8, Y + 18, 6, 1, Pal.board.seamDeep)
        px(X + 13, Y + 19, 1, 5, Pal.board.seamDeep)
        px(X + 7, Y + 12, 1, 1, Pal.ink)
    elseif n % 13 == 4 then
        px(X + 21, Y + 6, 1, 8, Pal.board.seamDeep)
        px(X + 16, Y + 14, 6, 1, Pal.board.seamDeep)
        px(X + 6, Y + 7, 3, 1, Pal.board.edge, .4)
        px(X + 22, Y + 24, 2, 1, Pal.board.light, .5)
    elseif n % 17 == 9 then
        dither(X + 18, Y + 19, 9, 7, Pal.board.seamDeep, .3)
    elseif n % 29 == 12 then
        -- Canto lascado: o encontro das juntas desaba em dois degraus.
        px(X, Y + 30, 3, 2, Pal.board.seamDeep)
        px(X + 1, Y + 29, 2, 1, Pal.board.seamDeep)
    elseif n % 37 == 15 then
        -- Fenda dupla atravessando a diagonal: duas linhas paralelas curtas.
        px(X + 4, Y + 10, 1, 6, Pal.board.seamDeep); px(X + 5, Y + 16, 1, 6, Pal.board.seamDeep)
        px(X + 6, Y + 12, 1, 4, Pal.board.seamDeep); px(X + 7, Y + 16, 1, 5, Pal.board.seamDeep)
        px(X + 5, Y + 16, 1, 1, Pal.ink)
    end
end

-- Acabamento do tabuleiro além da célula: medalhão entalhado no centro,
-- cantos marcados e sombra de contorno logo fora da arena. Só roda no
-- estilo 'board' — as coordenadas já estão em pixels de sala.
local function boardDressing(room, seed, ctx)
    local cx, cy = ctx.cx * 32, ctx.cy * 32
    local bw, bh = (ctx.x1 - ctx.x0 + 1) * 32, (ctx.y1 - ctx.y0 + 1) * 32
    local bx0, by0 = (ctx.x0 - 1) * 32, (ctx.y0 - 1) * 32
    -- Medalhão cerimonial: disco afundado, anel de jade, raios entalhados e
    -- a flecha fincada ao centro — o motivo do jogo lê-se no chão da arena.
    local mr = math.floor(math.min(bw, bh) * .38)
    ditherEllipse(cx, cy, mr + 2, mr + 2, Pal.board.seamDeep, .5)
    for j = -mr - 2, mr + 2 do for i = -mr - 2, mr + 2 do
        local d = math.sqrt(i * i + j * j)
        if d > mr and d < mr + 2 then px(cx + i, cy + j, 1, 1, Pal.ink)
        elseif d > mr - 3 and d < mr - 1 then px(cx + i, cy + j, 1, 1, Pal.jade.dark)
        elseif d > mr - 6 and d < mr - 5 then px(cx + i, cy + j, 1, 1, Pal.board.seamDeep)
        elseif d > mr - 13 and d < mr - 12 then px(cx + i, cy + j, 1, 1, Pal.board.seamDeep)
        elseif d < mr - 14 then px(cx + i, cy + j, 1, 1, Pal.board.light, .28) end
    end end
    -- Raios entalhados a cada 30°, poupando a cruz cardeal onde o ouro fala.
    for k = 0, 11 do
        local a = k * math.pi / 6
        if k % 3 ~= 0 then
            local dx, dy = math.cos(a), math.sin(a)
            for t = 16, mr - 7 do
                px(cx + dx * t, cy + dy * t, 1, 1, Pal.board.seamDeep)
            end
        end
    end
    -- Eixo processional: filete de jade cruzando a arena nas 4 direções,
    -- interrompido pelo anel — o caminho leva ao medalhão.
    px(bx0 + 4, cy - 1, cx - mr - 6 - bx0, 2, Pal.jade.dark, .55)
    px(cx + mr + 6, cy - 1, bx0 + bw - 4 - cx - mr - 6, 2, Pal.jade.dark, .55)
    px(cx - 1, by0 + 4, 2, cy - mr - 6 - by0, Pal.jade.dark, .55)
    px(cx - 1, cy + mr + 6, 2, by0 + bh - 4 - cy - mr - 6, Pal.jade.dark, .55)
    -- Pips de ouro nos pontos cardeais do anel.
    for _, s in ipairs({-1, 1}) do
        px(cx + s * mr - 2, cy - 2, 4, 4, Pal.gold.base)
        px(cx - 2, cy + s * mr - 2, 4, 4, Pal.gold.base)
        px(cx + s * mr - 1, cy - 1, 2, 2, Pal.gold.light)
        px(cx - 1, cy + s * mr - 1, 2, 2, Pal.gold.light)
    end
    -- Sigilo central: a flecha fincada, ponta para baixo, em ouro velho.
    px(cx - 1, cy - 10, 2, 14, Pal.gold.base)
    px(cx - 1, cy - 10, 1, 14, Pal.gold.light)
    px(cx - 3, cy + 2, 6, 2, Pal.gold.base); px(cx - 2, cy + 4, 4, 2, Pal.gold.base)
    px(cx - 1, cy + 6, 2, 2, Pal.gold.dark)
    px(cx - 5, cy - 10, 4, 2, Pal.gold.dark); px(cx + 1, cy - 10, 4, 2, Pal.gold.dark)
    px(cx - 6, cy - 13, 3, 2, Pal.gold.dark); px(cx + 3, cy - 13, 3, 2, Pal.gold.dark)
    -- Moldura entalhada interna: filete duplo um passo dentro da borda, com
    -- cantos quebrados em L e pips de jade espaçados ao longo dos lados.
    px(bx0 + 5, by0 + 5, bw - 10, 1, Pal.board.seamDeep)
    px(bx0 + 5, by0 + bh - 6, bw - 10, 1, Pal.board.seamDeep)
    px(bx0 + 5, by0 + 5, 1, bh - 10, Pal.board.seamDeep)
    px(bx0 + bw - 6, by0 + 5, 1, bh - 10, Pal.board.seamDeep)
    px(bx0 + 6, by0 + 6, bw - 12, 1, Pal.board.edge, .25)
    for i = 0, math.floor(bw / 64) - 1 do
        px(bx0 + 20 + i * 64, by0 + 3, 3, 2, Pal.jade.dark)
        px(bx0 + bw - 23 - i * 64, by0 + bh - 5, 3, 2, Pal.jade.dark)
        px(bx0 + 20 + i * 64, by0 + 4, 1, 1, Pal.jade.base, .7)
    end
    -- Cantos entalhados: cantoneira de sombra + pip de ouro.
    for _, c in ipairs({{bx0 + 5, by0 + 5}, {bx0 + bw - 7, by0 + 5},
            {bx0 + 5, by0 + bh - 7}, {bx0 + bw - 7, by0 + bh - 7}}) do
        px(c[1], c[2], 5, 1, Pal.board.seamDeep); px(c[1], c[2], 1, 5, Pal.board.seamDeep)
        px(c[1] + 2, c[2] + 2, 2, 2, Pal.gold.dark)
        px(c[1] + 2, c[2] + 2, 1, 1, Pal.gold.light)
    end
    -- Fenda antiga atravessando a arena: uma linha diagonal quebrada que
    -- desce da borda alta-esquerda para o baixo-direito, alargando nos
    -- degraus — o piso conta sua própria queda.
    local fx0, fy0 = bx0 + math.floor(bw * .17), by0 + 6
    local fx1, fy1 = bx0 + math.floor(bw * .66), by0 + bh - 8
    local steps = math.floor((fy1 - fy0) / 3)
    for i = 0, steps do
        local jx = fx0 + math.floor((fx1 - fx0) * i / steps) + (hash(seed, i, 77) % 3)
        local jy = fy0 + i * 3
        px(jx, jy, 1, 4, Pal.board.seamDeep)
        if i % 5 == 2 then px(jx - 1, jy, 3, 1, Pal.board.seamDeep) end
        if i % 7 == 3 then px(jx, jy + 1, 1, 1, Pal.ink) end
    end
    -- Poças de luz quente assadas sob cada pilar e nos dois braseiros que a
    -- cena desenha nos flancos do meio-fio — a arena aquece nas margens.
    for _, t in pairs(room.tiles) do
        if t.piece == 'pillar' then
            local lx, ly = (t.x - .5) * 32, (t.y - .5) * 32
            halo(lx, ly + 15, 24, 10, Pal.ember, .16)
            halo(lx, ly + 13, 12, 5, Pal.emberLight, .14)
            halo(lx + 1, ly + 12, 5, 2, Pal.white, .06)
        end
    end
    halo(bx0 - 10, cy + 6, 26, 12, Pal.ember, .16)
    halo(bx0 - 10, cy + 4, 13, 6, Pal.emberLight, .13)
    halo(bx0 + bw + 10, cy + 6, 26, 12, Pal.ember, .16)
    halo(bx0 + bw + 10, cy + 4, 13, 6, Pal.emberLight, .13)
    -- Bruma baixa rolando sobre a borda da plataforma: o vale exala frio e
    -- a pedra do embasamento desaparece por dentro da névoa.
    dither(bx0 - 4, by0 + bh - 8, bw + 8, 6, Pal.sky.low, .12)
    dither(bx0 - 4, by0 + bh + 2, bw + 8, 4, Pal.sky.low, .20)
end

-- A arena é uma plataforma cerimonial no topo de uma colina de sepultados,
-- à noite. O fundo assado constrói o lugar em camadas: céu em bandas de
-- gradiente frio com lua baixa e estrelas, crista distante de morros,
-- silhuetas próximas (a flecha gigante fincada, lápides, árvore morta,
-- colunata arruinada) com bases afundadas em bruma, e terra de sepultura
-- cercando a plataforma — nada de vazio negro. Tudo assado antes das
-- células — o tabuleiro cobre o que invadir a arena.
local function boardVoidHill(room, seed, ctx, canonical)
    local bw, bh = (ctx.x1 - ctx.x0 + 1) * 32, (ctx.y1 - ctx.y0 + 1) * 32
    local cx, cy = ctx.cx * 32, ctx.cy * 32
    local x0p, y0p = (ctx.x0 - 1) * 32, (ctx.y0 - 1) * 32
    local x1p, y1p = ctx.x1 * 32, ctx.y1 * 32
    local L, T = -64, -64
    local R = room.w * 32 + 64
    local B = room.h * 32 + 64
    local horizon = y0p - 4
    -- Céu em bandas com emendas dithered — degradação fria e duramente
    -- pixelada, não um gradiente suave.
    local bands = {
        {T, Pal.sky.zenith}, {T + 30, Pal.sky.high}, {T + 66, Pal.sky.mid},
        {T + 104, Pal.sky.low}, {horizon - 14, Pal.sky.horizon},
    }
    for i, band in ipairs(bands) do
        local y0 = band[1]
        local y1 = bands[i + 1] and bands[i + 1][1] or horizon + 4
        px(L, y0, R - L, y1 - y0, band[2])
        if i > 1 then dither(L, y0 - 4, R - L, 4, band[2], .4) end
    end
    -- Estrelas: pontos frios esparsos, alguns duplos; nunca na lua.
    local mx, my, mr = x0p + bw * .17, horizon - 30, 15
    for i = 1, 34 do
        local sx = L + (hash(seed, i, 11) % math.floor(R - L - 4)) + 2
        local sy = T + 6 + (hash(seed, i, 29) % math.floor(horizon - T - 24))
        if math.abs(sx - mx) > mr + 8 or math.abs(sy - my) > mr + 6 then
            local bright = hash(seed, i, 47) % 4 == 0
            px(sx, sy, bright and 2 or 1, 1, Pal.sky.star, bright and .85 or .5)
        end
    end
    -- Lua baixa atrás da crista: disco com sombra no quarto inferior-direito
    -- e halo dithered — a fonte do rim light frio da cena inteira.
    halo(mx, my, mr * 2 + 10, mr * 2 + 2, Pal.moon.halo, .22)
    halo(mx, my, mr + 10, mr + 8, Pal.moon.halo, .30)
    for j = -mr, mr do
        local half = math.floor(math.sqrt(mr * mr - j * j))
        px(mx - half, my + j, half * 2, 1, Pal.moon.disc)
    end
    -- Sombra de quarto embaixo-direita: um segundo disco deslocado, podado
    -- pelo contorno da lua — gibosa, não roída.
    for j = -mr, mr do
        local half = math.floor(math.sqrt(mr * mr - j * j))
        local sh2 = (mr - 4) * (mr - 4) - (j - 4) * (j - 4)
        if sh2 > 0 then
            local shalf = math.floor(math.sqrt(sh2))
            local s0 = math.max(mx - half, mx + 5 - shalf)
            local s1 = math.min(mx + half, mx + 5 + shalf)
            if s1 > s0 then px(s0, my + j, s1 - s0, 1, Pal.moon.shade) end
        end
    end
    -- Mares e brilho: manchas baixas e o filo claro do topo-esquerda.
    px(mx - 6, my - 3, 4, 2, Pal.moon.shade); px(mx - 2, my + 6, 5, 2, Pal.moon.shade)
    px(mx + 3, my - 6, 4, 2, Pal.moon.shade, .8)
    px(mx - 9, my - 8, 8, 1, Pal.white, .65); px(mx - 11, my - 5, 3, 1, Pal.white, .5)
    px(mx - 12, my - 3, 2, 2, Pal.white, .4)
    -- Véus de nuvem fina: faixas dithered alongadas quebram o gradiente e
    -- uma delas cruza a base da lua — profundidade atmosférica barata.
    for i, cld in ipairs({{T + 38, 210, .30}, {T + 62, 280, .20}, {my - 1, 240, .16}}) do
        local cy0, cw_, dens = cld[1], cld[2], cld[3]
        local cx0 = L + (hash(seed, i, 53) % math.floor(R - L - cw_))
        dither(cx0, cy0, cw_, 3, Pal.sky.zenith, dens)
        dither(cx0 + 18, cy0 + 3, cw_ - 36, 2, Pal.sky.zenith, dens * .55)
    end
    -- Crista distante: morros ondulados suaves (senos determinísticos),
    -- claros o bastante para separar da crista próxima.
    for i = 0, math.floor((R - L) / 4) - 1 do
        local rx = L + i * 4
        local rh = 12 + 7 * math.sin(i * .16 + .7) + 5 * math.sin(i * .043 + 2)
        px(rx, horizon - math.floor(rh), 4, math.floor(rh) + 10, Pal.ridge.far)
    end
    -- Crista própria da colina: linha baixa e quebrada onde as lápides e a
    -- flecha se apoiam; o vale afunda logo abaixo do horizonte.
    for i = 0, math.floor((R - L) / 4) - 1 do
        local rx = L + i * 4
        local rh = 3 + 2 * math.sin(i * .31) + (hash(seed, i, 3) % 3)
        px(rx, horizon - math.floor(rh), 4, math.floor(rh) + 4, Pal.ridge.near)
    end
    local silh = Pal.ridge.near
    local lit = Pal.ridge.lit
    local function ridgeH(rx)
        local i = math.floor((rx - L) / 4)
        return 3 + 2 * math.sin(i * .31) + (hash(seed, i, 3) % 3)
    end
    -- Motivos canônicos só existem na COLINA: a flecha gigante, o cemitério
    -- e a árvore morta são a assinatura do lugar. Fora dela, ruínas sóbrias.
    if canonical then
    -- A FLECHA GIGANTE: o monumento. Caira do céu e cravou-se na colina —
    -- a haste sobe tombada para a esquerda até fora do quadro, e as empenas
    -- partidas pendem só para a direita, no sentido da queda: nada de cruz
    -- simétrica — uma flecha gasta, não um mastro nem um catavento.
    local ax = x0p + bw * .33
    local abase = horizon - ridgeH(ax) + 2
    local atop = abase - 74
    local function shaftX(j) return ax + math.floor((j - abase) * 17 / (abase - atop)) end
    for j = atop, abase do
        local sx = shaftX(j)
        local w = j > abase - 12 and 7 or 6
        px(sx, j, w, 1, silh)
        px(sx - 1, j, 1, 1, lit, .9)
    end
    -- Empenas partidas: dois leques de lâminas de pena pendendo para trás-
    -- baixo em degraus, e uma sobra curta no lado oposto — nada de cruz
    -- simétrica: a flecha está gasta, não é um mastro nem um catavento.
    local vtop = horizon - 46
    local v1 = shaftX(vtop)
    for i = 0, 5 do
        px(v1 + 4 + i * 2, vtop + 2 + i * 3, 9 - i, 2, silh)
    end
    px(v1 + 4, vtop + 2, 1, 10, lit, .8); px(v1 + 14, vtop + 17, 3, 1, silh)
    local v2 = shaftX(vtop + 20)
    for i = 0, 4 do
        px(v2 + 4 + i * 2, vtop + 20 + i * 3, 8 - i, 2, silh)
    end
    px(v2 + 4, vtop + 20, 1, 9, lit, .7)
    -- Sobra curta no lado oposto e o laço que prendia a empena.
    local v3 = shaftX(vtop + 34)
    px(v3 - 7, vtop + 34, 7, 2, silh); px(v3 - 8, vtop + 36, 5, 2, silh)
    px(v3 - 7, vtop + 34, 1, 2, lit, .55)
    px(v3 - 1, vtop + 33, 5, 1, Pal.jade.dark, .85)
    -- Colar onde a ponta some na terra: a base alarga e o solo racha em
    -- estrela ao redor — a queda ainda está escrita no morro.
    local bx = shaftX(abase)
    px(bx - 6, abase - 3, 12, 4, silh); px(bx - 8, abase - 1, 15, 3, silh)
    px(bx - 6, abase - 3, 2, 2, lit, .6)
    px(bx - 14, abase + 1, 9, 1, silh, .7); px(bx + 7, abase + 1, 12, 1, silh, .7)
    px(bx - 10, abase + 2, 5, 1, Pal.ink); px(bx + 4, abase + 3, 7, 1, Pal.ink)
    ditherEllipse(bx + 1, abase + 3, 17, 4, Pal.ink, .55)
    -- Lápides e marcos na crista próxima: cada uma assenta na linha local do
    -- morro — cruz, laje inclinada, obelisco quebrado, par de pedras.
    local graves = {
        {ax - 96, 'cross'}, {ax - 58, 'slab'}, {ax - 30, 'cross'},
        {x0p + bw * .52, 'obelisk'}, {x0p + bw * .58, 'slab'},
        {x0p + bw * .78, 'cross'}, {x0p + bw * .87, 'slab'},
        {x0p - 18, 'slab'}, {x1p + 14, 'cross'},
    }
    for _, g in ipairs(graves) do
        local gx, kind = g[1], g[2]
        local gy = horizon - ridgeH(gx)
        if kind == 'cross' then
            px(gx, gy - 9, 3, 10, silh); px(gx - 2, gy - 7, 7, 2, silh)
            px(gx, gy - 9, 1, 6, lit, .7)
        elseif kind == 'slab' then
            px(gx, gy - 8, 5, 9, silh); px(gx, gy - 8, 5, 1, lit, .75)
            px(gx + 5, gy - 5, 2, 6, silh, .7)
        else
            px(gx, gy - 13, 4, 14, silh); px(gx, gy - 13, 4, 1, lit, .7)
            px(gx + 4, gy - 10, 2, 3, silh, .6)
        end
        ditherEllipse(gx + 2, gy + 1, 7, 2, Pal.ink, .4)
    end
    -- Árvore morta à esquerda: tronco torto de dois lances, galhos secos
    -- quebrando para cima — todo o peso aponta contra o luar.
    local tx = x0p - 34
    local ty = horizon - ridgeH(tx)
    px(tx, ty - 24, 3, 25, silh); px(tx - 1, ty - 30, 3, 8, silh)
    px(tx - 1, ty - 30, 1, 20, lit, .7)
    px(tx - 8, ty - 25, 7, 2, silh); px(tx - 10, ty - 29, 2, 5, silh)
    px(tx + 3, ty - 20, 7, 2, silh); px(tx + 9, ty - 24, 2, 5, silh)
    px(tx - 5, ty - 17, 5, 1, silh)
    else
        -- Ruínas genéricas: duas colunas quebradas onde a flecha estaria e
        -- cascalho largo — o lugar é antigo, mas não é a colina.
        local rx = x0p + bw * .33
        local ry = horizon - ridgeH(rx)
        px(rx, ry - 22, 6, 24, silh); px(rx - 1, ry - 22, 8, 2, silh)
        px(rx - 1, ry - 22, 2, 1, lit, .7)
        px(rx + 20, ry - 10, 5, 12, silh); px(rx + 19, ry - 12, 7, 2, silh)
        px(rx + 20, ry - 12, 1, 1, lit, .6)
        ditherEllipse(rx + 3, ry + 2, 10, 3, Pal.ink, .45)
    end
    -- Pórtico arruinado atrás da arena: dois pilares altos com arquitrave
    -- tombado — a entrada cerimonial da colina emoldura o tabuleiro.
    for _, g in ipairs({{x0p - 14, 40}, {x1p + 6, 34}}) do
        local gx, gh = g[1], g[2]
        local gy = horizon - ridgeH(gx)
        px(gx, gy - gh, 7, gh + 2, silh)
        px(gx, gy - gh, 7, 1, lit, .8); px(gx - 1, gy - gh, 1, gh, lit, .5)
        px(gx - 2, gy - gh, 11, 3, silh); px(gx - 2, gy - gh, 3, 1, lit, .7)
    end
    px(x0p - 10, horizon - ridgeH(x0p) - 38, 62, 3, silh, .85)
    px(x0p + 50, horizon - ridgeH(x0p) - 36, 8, 5, silh, .8)
    -- Colunata arruinada à direita: três colunas de alturas quebradas e um
    -- arquitrave tombado — ecos da arena a céu aberto.
    for i, col in ipairs({{x1p + 14, 26}, {x1p + 26, 16}, {x1p + 38, 30}}) do
        local cwx, ch = col[1], col[2]
        local cyv = horizon - ridgeH(cwx)
        px(cwx, cyv - ch, 5, ch + 2, silh)
        px(cwx - 1, cyv - ch, 7, 2, silh); px(cwx - 1, cyv - ch, 2, 1, lit, .7)
        px(cwx + (i == 2 and -2 or 4), cyv - ch - 4, 3, 4, silh)
    end
    -- Terra de sepultura: encosta escura cercando a plataforma, com ondula-
    -- ções dithered, pedras soltas e fileiras de túmulos miúdos nos flancos.
    px(L, horizon + 4, R - L, B - horizon - 4, Pal.earth.base)
    for i = 0, math.floor((R - L) / 16) - 1 do
        local ex = L + i * 16 + (hash(seed, i, 17) % 8)
        local ey = horizon + 6 + (hash(seed, i, 23) % math.floor(B - horizon - 60))
        ditherEllipse(ex + 8, ey, 14, 4, Pal.earth.mound, .5)
        if hash(seed, i, 31) % 3 == 0 then px(ex + 3, ey - 3, 4, 4, Pal.earth.rim) end
    end
    -- Fileiras de sepulturas simples nas encostas laterais: marcadores
    -- miúdos enfileirados seguindo o declive — a colina é um cemitério.
    if canonical then for i = 0, 7 do
        for _, s in ipairs({-1, 1}) do
            local gx = cx + s * (bw / 2 + 26) + s * i * 14
            local gy = horizon + 10 + i * 9 + (hash(seed, i, s) % 5)
            px(gx, gy - 4, 3, 5, Pal.earth.mound)
            px(gx, gy - 4, 3, 1, Pal.earth.rim)
        end
    end end
    -- Parapeito arruinado dos flancos da plataforma: fragmentos baixos de
    -- muro com rim light no topo, interrompidos — a arena era murada.
    for i = 0, 2 do
        local wy = y0p + 26 + i * 34
        px(x0p - 20, wy - 5, 12, 6, Pal.ridge.near)
        px(x0p - 20, wy - 5, 12, 1, Pal.ridge.lit)
        px(x0p - 21, wy - 6, 3, 2, Pal.ridge.near)
        px(x1p + 8, wy - 5, 12, 6, Pal.ridge.near)
        px(x1p + 8, wy - 5, 12, 1, Pal.ridge.lit)
        px(x1p + 18, wy - 6, 3, 2, Pal.ridge.near)
        ditherEllipse(x0p - 14, wy + 1, 9, 3, Pal.ink, .45)
        ditherEllipse(x1p + 14, wy + 1, 9, 3, Pal.ink, .45)
    end
    -- Túmulos de perto nos flancos: lápides maiores e mais escuras que as
    -- da crista, descendo a encosta — primeiro plano contra a luz da arena.
    if canonical then
    local nearGraves = {
        {x0p - 34, y0p + 14, 'slab'}, {x0p - 44, y0p + 46, 'cross'},
        {x0p - 30, y0p + 84, 'slab'}, {x0p - 48, y0p + 116, 'obelisk'},
        {x1p + 30, y0p + 20, 'cross'}, {x1p + 44, y0p + 56, 'slab'},
        {x1p + 28, y0p + 96, 'slab'}, {x1p + 46, y0p + 128, 'cross'},
    }
    for _, g in ipairs(nearGraves) do
        local gx, gy, kind = g[1], g[2], g[3]
        if kind == 'cross' then
            px(gx, gy - 13, 5, 14, silh); px(gx - 4, gy - 10, 13, 3, silh)
            px(gx, gy - 13, 1, 9, lit, .7)
        elseif kind == 'obelisk' then
            px(gx, gy - 17, 6, 18, silh); px(gx + 1, gy - 20, 4, 4, silh)
            px(gx, gy - 17, 1, 12, lit, .7)
        else
            px(gx, gy - 11, 8, 12, silh); px(gx, gy - 11, 8, 1, lit, .75)
            px(gx + 7, gy - 8, 2, 8, silh, .7)
        end
        ditherEllipse(gx + 3, gy + 2, 9, 3, Pal.ink, .55)
    end
    end
    -- Capim morto e pedras soltas na encosta: fios secos verticais e grãos
    -- de pedra — a terra é lida como chão, não como vazio.
    for i = 0, math.floor((R - L) / 11) - 1 do
        local ex = L + i * 11 + (hash(seed, i, 41) % 6)
        local ey = horizon + 8 + (hash(seed, i, 59) % math.floor(B - horizon - 46))
        -- fora do pé da plataforma: capim não nasce dentro da saia de pedra
        local inX = ex > x0p - 12 and ex < x1p + 12
        local inY = ey > y0p - 12 and ey < y1p + 26
        if not (inX and inY) then
            if hash(seed, i, 61) % 2 == 0 then
                px(ex, ey - 3, 1, 3, Pal.earth.rim); px(ex + 2, ey - 2, 1, 2, Pal.earth.rim)
                px(ex + 1, ey - 4, 1, 1, Pal.ridge.lit, .8)
            else
                px(ex, ey - 1, 3, 2, Pal.earth.mound); px(ex, ey - 2, 1, 1, Pal.earth.rim)
            end
        end
    end
    -- Saia da plataforma: a arena assenta sobre um rodapé de pedra escura
    -- com face frontal talhada — a moldura dinâmica coroa esse embasamento.
    -- A face frontal é a parede do embasamento: banda de pedra caindo em
    -- sombra, juntas verticais marcadas e lábio inferior dissolvendo no vale.
    px(x0p - 9, y0p - 9, bw + 18, bh + 18, Pal.board.seamDeep)
    px(x0p - 9, y0p - 9, bw + 18, 1, Pal.stone.dark)
    px(x0p - 9, y1p + 8, bw + 18, 9, Pal.stone.dark)
    px(x0p - 9, y1p + 8, bw + 18, 1, Pal.stone.base, .7)
    px(x0p - 9, y1p + 15, bw + 18, 2, Pal.ink)
    for i = 0, math.floor(bw / 32) do
        px(x0p - 8 + i * 32, y1p + 9, 1, 6, Pal.ink, .55)
    end
    dither(x0p - 9, y1p + 12, bw + 18, 4, Pal.ink, .28)
    -- Lápides do primeiro plano abaixo do tabuleiro: mais escuras que a
    -- crista, recortadas contra a luz da arena.
    if canonical then
    for _, g in ipairs({{x0p + bw * .10, y1p + 26, 'slab'}, {x0p + bw * .24, y1p + 34, 'cross'},
            {x0p + bw * .80, y1p + 30, 'slab'}, {x0p + bw * .93, y1p + 40, 'cross'}}) do
        local gx, gy, kind = g[1], g[2], g[3]
        if kind == 'cross' then
            px(gx, gy - 10, 4, 11, silh); px(gx - 3, gy - 8, 10, 3, silh)
            px(gx, gy - 10, 1, 7, lit, .6)
        else
            px(gx, gy - 9, 7, 10, silh); px(gx, gy - 9, 7, 1, lit, .65)
            px(gx + 6, gy - 6, 2, 7, silh, .7)
        end
        ditherEllipse(gx + 3, gy + 1, 8, 3, Pal.ink, .5)
    end
    end
    -- Degraus processionais sob o centro: três lajes descendo até o vale.
    for s = 0, 2 do
        local sw = 56 - s * 12
        px(cx - sw / 2, y1p + 14 + s * 7, sw, 5, Pal.earth.mound)
        px(cx - sw / 2, y1p + 14 + s * 7, sw, 1, Pal.ridge.lit, .5)
        px(cx - sw / 2, y1p + 18 + s * 7, sw, 1, Pal.ink)
    end
    -- Bruma em camadas: véus dithered por faixa de profundidade — atrás das
    -- silhuetas, entre crista e plataforma, e no vale do primeiro plano.
    dither(L, horizon - 6, R - L, 6, Pal.sky.low, .30)
    dither(L, horizon + 4, R - L, 8, Pal.ridge.far, .22)
    dither(L, y1p + 8, R - L, 10, Pal.earth.mound, .30)
    dither(x0p - 40, y1p + 22, bw + 80, 8, Pal.sky.low, .12)
    dither(L, B - 26, R - L, 12, Pal.ink, .4)
    -- A plataforma afunda na terra: sombra de contato larga sob a saia.
    ditherEllipse(cx, cy, bw / 2 + 22, bh / 2 + 18, Pal.ink, .4)
    ditherEllipse(cx, cy, bw / 2 + 10, bh / 2 + 8, Pal.ink, .65)
end

-- O REFÚGIO: a arena montada no pátio interior da casa funerária — sem
-- céu. Parede de reboco quente com nichos em ogiva, lampiões acesos
-- lançando poças de luz e tábuas de madeira sob a plataforma. O luar frio
-- dá lugar ao calor fechado de casa acordada — o vazio é o lugar onde a
-- batalha começou.
local function boardVoidRefuge(room, seed, ctx)
    local bw, bh = (ctx.x1 - ctx.x0 + 1) * 32, (ctx.y1 - ctx.y0 + 1) * 32
    local cx, cy = ctx.cx * 32, ctx.cy * 32
    local x0p, y0p = (ctx.x0 - 1) * 32, (ctx.y0 - 1) * 32
    local x1p, y1p = ctx.x1 * 32, ctx.y1 * 32
    local L, T = -64, -64
    local R = room.w * 32 + 64
    local B = room.h * 32 + 64
    local wline = y0p - 6                       -- rodapé: parede/piso
    local R_ = Pal.regions.hub
    local wall, wood, fl = R_.wall, R_.wood, R_.floor
    -- Parede de reboco: face morna, viga corrida de madeira no alto,
    -- juntas de painel verticais e rodapé escuro.
    px(L, T, R - L, wline - T, wall.face)
    px(L, T, R - L, 6, wood.dark)
    px(L, T + 6, R - L, 2, wall.mortar)
    for i = 0, math.floor((R - L) / 26) do
        px(L + i * 26, T + 8, 1, wline - T - 14, wall.faceDark, .8)
    end
    px(L, wline - 6, R - L, 6, wall.faceDark)
    px(L, wline - 7, R - L, 1, wall.rim, .6)
    -- Nichos em ogiva: três arcos cegos na parede sobre pedestal — a
    -- arquitetura da funerária emoldura a arena por trás.
    for _, ax in ipairs({x0p + bw * .14, x0p + bw * .5, x0p + bw * .82}) do
        local aw, ah = 26, 36
        local ay = wline - 12 - ah
        px(ax - aw / 2 - 3, ay - 3, aw + 6, ah + 6, wall.brick)
        px(ax - aw / 2 - 3, ay - 3, aw + 6, 1, wall.rim, .8)
        px(ax - aw / 2 - 3, ay - 3, 1, ah + 6, wall.brickAlt)
        for j = 0, ah - 1 do
            local inset = j < 12 and math.floor((12 - j) / 2.4) or 0
            px(ax - aw / 2 + inset, ay + j, aw - inset * 2, 1, wall.mortar)
        end
        -- Pedestal sob o nicho e objeto votivo dentro — o nicho é janela
        -- de memória, não buraco.
        px(ax - aw / 2 - 3, ay + ah + 2, aw + 6, 5, wall.faceDark)
        px(ax - aw / 2 - 3, ay + ah + 2, aw + 6, 1, wall.rim, .6)
        px(ax - 3, ay + ah - 10, 6, 10, wall.faceDark)
        px(ax - 3, ay + ah - 10, 6, 1, wall.rim, .5)
        px(ax - 1, ay + ah - 12, 2, 2, Pal.ember, .9)
        px(ax, ay + ah - 11, 1, 1, Pal.emberLight)
        dither(ax - aw / 2 + 3, ay + ah - 12, aw - 6, 8, wall.faceDark, .4)
    end
    -- Lampiões de parede nos flancos: corpo âmbar sob a luz que escorre
    -- pela parede — são as fontes de luz do pátio.
    for _, lx in ipairs({x0p - 30, x1p + 26}) do
        local ly = wline - 30
        px(lx - 1, ly - 6, 3, 3, Pal.ink); px(lx, ly - 8, 1, 2, Pal.gold.dark)
        px(lx - 2, ly - 4, 5, 6, Pal.gold.dark)
        px(lx - 1, ly - 3, 3, 4, Pal.emberLight)
        px(lx, ly - 2, 1, 2, Pal.white)
        halo(lx, ly - 1, 18, 13, Pal.ember, .5)
        halo(lx, ly - 1, 8, 6, Pal.emberLight, .5)
        dither(lx - 8, ly + 6, 17, 20, Pal.ember, .10)
    end
    -- Piso de tábuas do pátio: fileiras quentes com juntas cegas — a arena
    -- é o tapete de pedra montado sobre elas.
    for i = 0, math.floor((B - wline) / 6) - 1 do
        local fy = wline + i * 6
        px(L, fy, R - L, 6, i % 2 == 0 and fl.base or fl.dark)
        px(L, fy, R - L, 1, fl.shadow)
        local off = i % 2 == 0 and 0 or 24
        for j = 0, math.floor((R - L) / 48) - 1 do
            px(L + off + j * 48 + 12, fy, 1, 6, fl.shadow)
        end
    end
    -- A plataforma de pedra assenta no pátio: poças dos lampiões no piso,
    -- saia talhada igual (a arena é sempre o mesmo monumento cerimonial).
    dither(x0p - 44, wline + 2, 26, 22, Pal.ember, .10)
    dither(x1p + 18, wline + 2, 26, 22, Pal.ember, .10)
    px(x0p - 9, y0p - 9, bw + 18, bh + 18, Pal.board.seamDeep)
    px(x0p - 9, y0p - 9, bw + 18, 1, Pal.stone.dark)
    px(x0p - 9, y1p + 8, bw + 18, 9, Pal.stone.dark)
    px(x0p - 9, y1p + 8, bw + 18, 1, Pal.stone.base, .7)
    px(x0p - 9, y1p + 15, bw + 18, 2, Pal.ink)
    for i = 0, math.floor(bw / 32) do
        px(x0p - 8 + i * 32, y1p + 9, 1, 6, Pal.ink, .55)
    end
    dither(x0p - 9, y1p + 12, bw + 18, 4, Pal.ink, .28)
    ditherEllipse(cx, cy, bw / 2 + 22, bh / 2 + 18, Pal.ink, .4)
    ditherEllipse(cx, cy, bw / 2 + 10, bh / 2 + 8, Pal.ink, .65)
    -- Penumbra de interior: as bordas da sala fecham — vinheta de parede.
    dither(L, T, 26, B - T, Pal.ink, .30)
    dither(R - 26, T, 26, B - T, Pal.ink, .30)
    dither(L, T, R - L, 16, Pal.ink, .38)
end

-- Interior genérico de região nova: mesma moldura do refúgio (parede com
-- rodapé, saia da plataforma, penumbra), mas parede/piso na paleta da
-- região e um motivo de ofício por lugar — oficinas=fornalha acesa,
-- mercado=toldo remendado, reservatório=canal e régua, salões=cortinas.
local function boardVoidInterior(room, seed, ctx, region)
    local R_ = Pal.regions[region] or Pal.regions.default
    local wall, wood, fl = R_.wall, R_.wood, R_.floor
    local bw, bh = (ctx.x1 - ctx.x0 + 1) * 32, (ctx.y1 - ctx.y0 + 1) * 32
    local cx, cy = ctx.cx * 32, ctx.cy * 32
    local x0p, y0p = (ctx.x0 - 1) * 32, (ctx.y0 - 1) * 32
    local x1p, y1p = ctx.x1 * 32, ctx.y1 * 32
    local L, T = -64, -64
    local R = room.w * 32 + 64
    local B = room.h * 32 + 64
    local wline = y0p - 6
    -- Parede da região com juntas verticais e rodapé.
    px(L, T, R - L, wline - T, wall.face)
    px(L, T, R - L, 4, wall.mortar)
    for i = 0, math.floor((R - L) / 30) do
        px(L + i * 30, T + 6, 1, wline - T - 12, wall.faceDark, .8)
    end
    px(L, wline - 6, R - L, 6, wall.faceDark)
    px(L, wline - 7, R - L, 1, wall.rim, .6)
    if region == 'oficinas' then
        -- Fornalha acesa num flanco: boca terrena com brasa — calor sujo
        -- de trabalho vazando na parede enegrecida.
        local fx = x0p - 42
        px(fx - 10, wline - 34, 34, 34, wall.brick)
        px(fx - 8, wline - 32, 30, 2, wall.rim, .7)
        px(fx - 4, wline - 22, 22, 16, Pal.ink)
        px(fx - 2, wline - 20, 18, 12, R_.petal)
        px(fx, wline - 18, 14, 8, Pal.ember)
        px(fx + 3, wline - 16, 8, 5, Pal.emberLight)
        px(fx + 5, wline - 15, 4, 3, Pal.white)
        halo(fx + 7, wline - 14, 22, 15, Pal.ember, .4)
        dither(fx - 8, wline - 34, 30, 8, Pal.ember, .12)
        -- Escoras de metal: diagonais finas marcando a parede.
        for _, bx in ipairs({x0p + bw * .3, x0p + bw * .7}) do
            for j = 0, wline - T - 30 do
                px(math.floor(bx + j * .18), T + 8 + j, 2, 1, wall.faceDark, .7)
            end
        end
    elseif region == 'mercado' then
        -- Toldo remendado pendurado na parede: riscas ocre/ferrugem que
        -- sombreiam o topo da arena.
        for i = 0, math.floor((R - L) / 16) do
            px(L + i * 16, T + 4, 16, 14, i % 2 == 0 and R_.cloth.base or R_.petal)
            px(L + i * 16, T + 4, 16, 1, Pal.ink, .35)
        end
        for i = 0, math.floor((R - L) / 16) do
            px(L + i * 16, T + 17 + (i % 2) * 2, 16, 2,
                i % 2 == 0 and R_.cloth.light or R_.cloth.dark)
        end
        -- Bancas baixas nas laterais.
        for _, bx in ipairs({x0p - 34, x1p + 12}) do
            px(bx, wline - 16, 24, 14, wood.dark)
            px(bx, wline - 16, 24, 2, wood.light)
            px(bx + 3, wline - 20, 8, 4, R_.cloth.dark)
        end
    elseif region == 'reservatorio' then
        -- Canal de água parada cortando o fundo + régua de nível na
        -- parede + musgo na junção.
        local wy = wline - 20
        px(L, wy, R - L, wline - wy, R_.cloth.dark)
        px(L, wy, R - L, 2, R_.cloth.base)
        for i = 0, 6 do
            px(L + 14 + i * 52, wy + 6 + (i % 2) * 4, 16, 1, R_.cloth.light, .5)
        end
        px(L, wy - 2, R - L, 2, R_.moss)
        px(x0p - 30, T + 8, 2, wline - T - 30, R_.wood.light)
        for i = 0, 6 do px(x0p - 30, T + 12 + i * 9, 6, 1, wall.cap) end
        -- Comporta no flanco direito: lâminas de ferragem empilhadas.
        for i = 0, 4 do px(x1p + 18, wy - 6 + i * 5, 12, 3, R_.wood.base) end
    elseif region == 'saloes' then
        -- Cortinas pesadas nas pontas da parede + velas rasantes: teatro
        -- escuro de pedra vinho.
        for i = 0, 8 do
            px(L + i * 8, T + 4, 8, wline - T - 10 - (i % 3) * 5,
                i % 2 == 0 and R_.cloth.base or R_.cloth.dark)
        end
        for i = 0, 8 do
            px(R - 72 + i * 8, T + 4, 8, wline - T - 10 - ((i + 1) % 3) * 5,
                i % 2 == 0 and R_.cloth.dark or R_.cloth.base)
        end
        for _, cxl in ipairs({x0p + bw * .3, x0p + bw * .7}) do
            px(cxl - 1, wline - 10, 2, 8, R_.wood.base)
            px(cxl - 1, wline - 12, 2, 2, Pal.emberLight)
            halo(cxl, wline - 12, 10, 8, Pal.ember, .35)
        end
    end
    -- Piso da região: fileiras com juntas — mesma leitura do pátio.
    for i = 0, math.floor((B - wline) / 6) - 1 do
        local fy = wline + i * 6
        px(L, fy, R - L, 6, i % 2 == 0 and fl.base or fl.dark)
        px(L, fy, R - L, 1, fl.shadow)
        local off = i % 2 == 0 and 0 or 24
        for j = 0, math.floor((R - L) / 48) - 1 do
            px(L + off + j * 48 + 12, fy, 1, 6, fl.shadow)
        end
    end
    -- Saia da plataforma e penumbra idênticas — a arena é o mesmo
    -- monumento cerimonial montado onde a batalha começou.
    px(x0p - 9, y0p - 9, bw + 18, bh + 18, Pal.board.seamDeep)
    px(x0p - 9, y0p - 9, bw + 18, 1, Pal.stone.dark)
    px(x0p - 9, y1p + 8, bw + 18, 9, Pal.stone.dark)
    px(x0p - 9, y1p + 8, bw + 18, 1, Pal.stone.base, .7)
    px(x0p - 9, y1p + 15, bw + 18, 2, Pal.ink)
    for i = 0, math.floor(bw / 32) do
        px(x0p - 8 + i * 32, y1p + 9, 1, 6, Pal.ink, .55)
    end
    dither(x0p - 9, y1p + 12, bw + 18, 4, Pal.ink, .28)
    ditherEllipse(cx, cy, bw / 2 + 22, bh / 2 + 18, Pal.ink, .4)
    ditherEllipse(cx, cy, bw / 2 + 10, bh / 2 + 8, Pal.ink, .65)
    dither(L, T, 26, B - T, Pal.ink, .30)
    dither(R - 26, T, 26, B - T, Pal.ink, .30)
    dither(L, T, R - L, 16, Pal.ink, .38)
end

-- O vazio da arena é do lugar onde a batalha começou: 'colina' = a colina
-- de sepultados com seus motivos canônicos, 'hub' = o pátio do Refúgio,
-- as regiões novas = interior próprio por região, o resto = ruínas
-- genéricas sóbrias (colina sem a assinatura).
local function boardVoid(room, seed, ctx)
    local region = ctx.region or 'colina'
    if region == 'hub' then return boardVoidRefuge(room, seed, ctx) end
    if Pal.regions[region] and region ~= 'colina' and region ~= 'default' then
        return boardVoidInterior(room, seed, ctx, region)
    end
    return boardVoidHill(room, seed, ctx, region == 'colina')
end

-- Célula de exploração: superfície quieta (o piso recua), sem grade explícita.
local function floorCell(x, y, n)
    local tone = n < 18 and Pal.floor.dark or n > 80 and Pal.floor.light or Pal.floor.base
    px((x - 1) * 32, (y - 1) * 32, 32, 32, Pal.floor.seam)
    px((x - 1) * 32 + 1, (y - 1) * 32 + 1, 30, 30, tone)
    px((x - 1) * 32 + 2, (y - 1) * 32 + 1, 27, 1, Pal.floor.edge, .25)
    px((x - 1) * 32 + 1, (y - 1) * 32 + 2, 1, 27, Pal.floor.edge, .16)
    px((x - 1) * 32 + 2, (y - 1) * 32 + 30, 29, 1, Pal.ink, .3)
    if n % 11 == 0 then
        dither((x - 1) * 32 + 16, (y - 1) * 32 + 18, 9, 7, Pal.floor.seam, .35)
    end
end

local STYLES = {board = boardCell, floor = floorCell}

-- Assa o piso inteiro de uma sala num canvas: desenho uma vez, leitura sempre.
-- Peças (pilares, paredes) são desenhadas por cima como antes — o canvas só
-- carrega o terreno, então um pilar que desaba revela o piso assado.
function PixelArt.bakeFloor(room, seed, style, region)
    local w, h = room.w * 32 + 128, room.h * 32 + 128
    local canvas = G.newCanvas(w, h, {dpiscale = 1})
    canvas:setFilter('nearest', 'nearest')
    local prev = G.getCanvas()      -- o bake pode rodar dentro do canvas da cena
    G.setCanvas(canvas)
    G.clear(style == 'board' and Pal.abyss[1] or Pal.ink[1],
        style == 'board' and Pal.abyss[2] or Pal.ink[2],
        style == 'board' and Pal.abyss[3] or Pal.ink[3], 1)
    -- O bake herda o translate da cena se chamado dentro dela; zera a
    -- transformação para o canvas assar exatamente em coordenadas de sala.
    -- push() ANTES de origin(): o estado de câmera precisa ser salvo antes
    -- de zerado, senão o pop() restaura a identidade e o frame da cena
    -- desenha deslocado.
    G.push(); G.origin(); G.translate(64, 64)
    local cell = STYLES[style or 'floor'] or floorCell
    -- Limites da arena para o acabamento cerimonial e a luz radial.
    local ctx
    if style == 'board' then
        local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
        for _, t in pairs(room.tiles) do
            if t.ground == 'floor' and not t.protected then
                x0, y0 = math.min(x0, t.x), math.min(y0, t.y)
                x1, y1 = math.max(x1, t.x), math.max(y1, t.y)
            end
        end
        ctx = {x0 = x0, y0 = y0, x1 = x1, y1 = y1, cx = (x0 + x1) / 2,
            cy = (y0 + y1) / 2, r = math.max(2, math.min(x1 - x0, y1 - y0) / 2),
            seed = seed, region = region}
        boardVoid(room, seed, ctx)
    end
    for ty = 1, room.h do for tx = 1, room.w do
        local tile = Rooms.cell(room, tx, ty)
        -- A casca de parede tem ground 'floor' mas não é piso jogável: pular
        -- 'wall' deixa o tabuleiro flutuando sobre o vazio; pilares continuam
        -- pintados porque desabam e revelam o piso embaixo.
        if tile and tile.ground == 'floor' and tile.piece ~= 'wall' then
            cell(tx, ty, hash(seed, tx, ty), ctx)
        end
    end end
    if ctx then boardDressing(room, seed, ctx) end
    G.pop()
    G.setCanvas(prev)
    return canvas
end

function PixelArt.selfCheck()
    assert(hash(1, 3, 4) == hash(1, 3, 4), 'Tile variation is stable')
    assert(hash(1, 3, 4) ~= hash(2, 3, 4), 'Seed changes tile variation')
    return true
end

return PixelArt
