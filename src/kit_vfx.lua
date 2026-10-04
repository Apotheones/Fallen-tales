-- kit_vfx.lua — authoring de efeitos pixel (W6 do MEGAPLAN_KIT_PROCEDURAL_IA).
-- Gera DEFS DSL (src.sprite_dsl.bake) de trilhas, arcos, faíscas, poeira,
-- fragmentos, fumaça e ondas — a mesma linha de bake multi-canal dos
-- outros assets (albedo/normal/emissivo indexado, nearest).
--
-- Contrato com a arena (nota spec-arena-hd do Bigorna):
-- * efeito é SHEET de frames indexados por tempo — pausa/congelamento
--   do jogo congela o efeito de graça (o draw só avança o índice);
-- * o efeito nunca carrega regra: só forma + cor + tempo; telegraph
--   continua sendo desenhado por célula pelo renderer, fora daqui;
-- * emissivo alimenta o bloom do postfx (limiar BLOOM abaixo) — a API
--   permite declarar emissivo fraco (sem bloom) ou quente (com bloom).
--
-- Regras do projeto: Lua puro com tabelas, RNG próprio por asset
-- (K.rng — math/love.random intocados), grades 1-based via pixel_kit,
-- bake fora do draw. Isto é a camada de AUTHORING: a sequência completa
-- numa ação tática real vem com W4 (metadados de animação) + integração.

local K = require('src.pixel_kit')

local V = {}

-- Limiar do bright-pass do postfx (src/postfx.lua): emissivo efetivo
-- (cor * ei) acima dele floresce; abaixo, o pixel só lê quente.
V.BLOOM = 0.35

-- Direções canônicas de authoring (rad, +x leste, +y para BAIXO na
-- tela — convenção do mundo, igual aos defs de ator).
V.DIR = {
    e = 0, se = math.pi / 4, s = math.pi / 2, sw = 3 * math.pi / 4,
    w = math.pi, nw = -3 * math.pi / 4, n = -math.pi / 2, ne = -math.pi / 4,
}
function V.dir(d)
    if type(d) == 'number' then return d end
    assert(V.DIR[d] ~= nil, 'kit_vfx: direção desconhecida ' .. tostring(d))
    return V.DIR[d]
end

--------------------------------------------------------------------------------
-- Grade de efeito: pixel_kit, '.' = transparente. Helpers de acesso
-- seguro (fora do quadro é '.').
--------------------------------------------------------------------------------

local function nova(w, h)
    local g = K.new(w, h)
    for y = 1, h do for x = 1, w do g.rows[y][x] = '.' end end
    return g
end
V.grid = nova

local function put(g, x, y, ch)
    x, y = math.floor(x + .5), math.floor(y + .5)
    if x >= 1 and x <= g.w and y >= 1 and y <= g.h then
        g.rows[y][x] = ch
    end
end
V.put = put

local function get(g, x, y)
    if x < 1 or x > g.w or y < 1 or y > g.h then return '.' end
    return g.rows[y][x]
end

--------------------------------------------------------------------------------
-- Envelopes: t 0..1 -> 0..1. Forma do ciclo de vida do efeito
-- (expansão, varredura, ataque, dissipação).
--------------------------------------------------------------------------------

V.ease = {
    linear = function(t) return t end,
    out    = function(t) return 1 - (1 - t) ^ 2 end,
    out3   = function(t) return 1 - (1 - t) ^ 3 end,
    inq    = function(t) return t * t end,
    pulse  = function(t) return math.sin(math.min(1, math.max(0, t)) * math.pi) end,
}
function V.env(t, kind)
    local f = type(kind) == 'function' and kind or V.ease[kind or 'linear']
    assert(f, 'kit_vfx: env desconhecido ' .. tostring(kind))
    return f(math.min(1, math.max(0, t)))
end

-- Trapezóide de vida: sobe em `attack`, sustenta `hold`, cai em `out`.
-- t 0..1 -> 0..1 (intensidade). attack+hold+out somam <=1.
function V.life(t, a, h, o)
    if t < a then return a > 0 and t / a or 1 end
    if t < a + h then return 1 end
    return o > 0 and math.max(0, 1 - (t - a - h) / o) or 0
end

--------------------------------------------------------------------------------
-- Dissipação: como o efeito sai de cena. Aplicada sobre a grade do
-- frame, depois das formas. Modos:
--   'thin'   — pixels somem por fração determinística (confete controlado)
--   'fade'   — chars descem uma cadeia (ex.: 'F'->'f'->'g'->'.')
--   'lift'   — o desenho inteiro sobe dy px pela fração
--   'sink'   — idem descendo
-- frac = fração já dissipada (0..1). Determinístico por (x,y,seed).
--------------------------------------------------------------------------------

local function dissolveHash(x, y, s)
    return ((x * 73856093 + y * 19349663 + (s or 0) * 83492791) % 65536) / 65536
end

function V.dissipate(g, frac, mode, opt)
    opt = opt or {}
    if frac <= 0 or mode == nil then return g end
    local w, h = g.w, g.h
    if mode == 'thin' then
        for y = 1, h do for x = 1, w do
            if g.rows[y][x] ~= '.'
                and dissolveHash(x, y, opt.seed) < frac then
                g.rows[y][x] = '.'
            end
        end end
    elseif mode == 'fade' then
        local map = opt.map or {}
        local down = {}
        -- cada char mapeado desce N passos na cadeia conforme a fração
        for ch, chain in pairs(map) do
            local n = #chain
            local k = math.min(n, math.floor(frac * (n + 1) + .0001))
            down[ch] = k >= n and '.' or chain[k + 1]
        end
        for y = 1, h do for x = 1, w do
            local c = g.rows[y][x]
            if down[c] then g.rows[y][x] = down[c] end
        end end
    elseif mode == 'lift' or mode == 'sink' then
        local dy = math.floor(frac * (opt.dist or 3) + .5)
            * (mode == 'lift' and -1 or 1)
        local n2 = nova(w, h)
        for y = 1, h do for x = 1, w do
            local c = g.rows[y][x]
            if c ~= '.' then
                local ty = y + dy
                if ty >= 1 and ty <= h then n2.rows[ty][x] = c end
            end
        end end
        return n2
    else
        error('kit_vfx: dissipate modo desconhecido ' .. tostring(mode))
    end
    return g
end

--------------------------------------------------------------------------------
-- Formas. Cada V.<forma>(spec) devolve function(f, N, g, rng) que pinta
-- o frame f (1..N) na grade g. rng = K.rng por asset (seed no spec).
-- Controles comuns: ch/ch2/edge = chars da legend; dir = direção base;
-- seed; e os campos geométricos de cada forma.
--------------------------------------------------------------------------------

-- TRILHA — vulto que percorre a->b; a cauda atrás da cabeça afunila e
-- quebra (dissipação 'thin' implícita ao longo do comprimento).
-- spec: from={x,y}, to={x,y}|dir+len, w=largura px, ch, tip=char ponta,
--       tail=0..1 fração de cauda visível, jitter=px lateral
function V.trail(s)
    local dir = s.dir and V.dir(s.dir) or nil
    local tx, ty = s.to and s.to[1] or (s.from[1] + math.cos(dir) * s.len),
        s.to and s.to[2] or (s.from[2] + math.sin(dir) * s.len)
    return function(f, N, g, rng)
        local t = V.env((f - .5) / N, s.ease or 'out')
        local hx = s.from[1] + (tx - s.from[1]) * t
        local hy = s.from[2] + (ty - s.from[2]) * t
        local tail = (s.tail or .45) * math.sqrt((tx - s.from[1]) ^ 2 + (ty - s.from[2]) ^ 2)
        local dx, dy = tx - s.from[1], ty - s.from[2]
        local L = math.max(1, math.sqrt(dx * dx + dy * dy))
        dx, dy = dx / L, dy / L
        local bx = math.max(s.from[1], hx - dx * tail)
        local by = math.max(s.from[2], hy - dy * tail)
        local seg = math.sqrt((hx - bx) ^ 2 + (hy - by) ^ 2)
        local w0 = s.w or 2
        for i = 0, math.ceil(seg) do
            local px, py = bx + dx * i, by + dy * i
            local frac = seg > 0 and i / seg or 0 -- 0=cauda, 1=cabeça
            local lw = math.max(1, w0 * (s.taper and (frac ^ s.taper) or frac))
            local jx = rng and rng.float() * 2 - 1 or 0
            local jy = rng and rng.float() * 2 - 1 or 0
            for q = -math.floor(lw / 2), math.floor(lw / 2) do
                put(g, px - dy * q + jx * (s.jitter or 0),
                    py + dx * q + jy * (s.jitter or 0),
                    i >= seg - 1 and (s.tip or s.ch) or s.ch)
            end
        end
    end
end

-- ARCO — lâmina varrendo dir+a0..dir+a1 em torno de `at`; frame f cobre
-- o setor já varrido (sweep 'out' = abre e morre, 'sweep' = percorre).
-- spec: at={x,y}, dir, a0,a1 (rad, offset do dir), r0,r1 (raio int/ext),
--       ch, edge=char da borda varrida
function V.arc(s)
    return function(f, N, g, rng)
        local t = V.env((f - .5) / N, s.ease or 'out')
        local dir = V.dir(s.dir or 'e')
        local A0 = dir + (s.a0 or -.9)
        local A1 = dir + (s.a1 or .9)
        -- sweep: 'grow' abre do início ao fim (lâmina nasce); 'sweep'
        -- (default) desloca uma janela de `span` rad ao longo do arco.
        local a0, a1
        if s.sweep == 'grow' then
            a0, a1 = A0, A0 + (A1 - A0) * t
        else
            local span = s.span or .5
            a1 = A0 + (A1 - A0) * t
            a0 = math.max(A0, a1 - span)
        end
        local r0, r1 = s.r0 or 6, s.r1 or 20
        local inten = V.life(f / (N + 1), .1, .55, .35)
        local steps = math.max(1, math.ceil(r1 * (a1 - a0)))
        for i = 0, steps do
            local a = a0 + (a1 - a0) * (i / steps)
            local edge = i == steps
            for r = r0, r1 do
                local fade = (r - r0) / math.max(1, r1 - r0)
                local ch = edge and (s.edge or s.ch)
                    or (fade > .6 and (s.ch2 or s.ch) or s.ch)
                if inten > 0 then
                    put(g, s.at[1] + math.cos(a) * r,
                        s.at[2] + math.sin(a) * r, ch)
                end
            end
        end
    end
end

-- FAÍSCAS — cone de partículas da origem; cada faísca tem comprimento,
-- ângulo (dentro do cone) e brilho próprios por seed. spec: at, dir,
-- cone (rad), n, len={min,max}, ch, hot (char cabeça), grav (px/frame²)
function V.sparks(s)
    local n = s.n or 12
    return function(f, N, g, rng)
        local t = (f - .5) / N
        local spd = s.speed or 26
        local dir = V.dir(s.dir or 'e')
        local cone = s.cone or .7
        for i = 1, n do
            local a = dir + (rng.float() * 2 - 1) * cone
            local v = spd * (.5 + rng.float())
            local len = (s.len and s.len[1] or 2)
                + rng.float() * ((s.len and s.len[2] or 6)
                    - (s.len and s.len[1] or 2))
            local born = rng.float() * .3 -- faíscas nascem em fases
            local lt = math.min(1, math.max(0, t - born) / .7)
            local d = v * lt * .6
            local px = s.at[1] + math.cos(a) * d
            local py = s.at[2] + math.sin(a) * d
                + (s.grav or 0) * lt * lt
            local L = len * (1 - lt * .6)
            for q = 0, math.ceil(L) do
                put(g, px - math.cos(a) * q, py - math.sin(a) * q,
                    q == 0 and (s.hot or s.ch) or s.ch)
            end
        end
    end
end

-- POEIRA — clusters baixos que rolam na direção do impacto e dissipam;
-- puffs ocasionais sobem. spec: at, dir, w (largura da zona), n,
-- drift (px extra na direção), rise (px de subida dos puffs), ch
function V.dust(s)
    local n = s.n or 9
    return function(f, N, g, rng)
        local t = (f - .5) / N
        local dir = V.dir(s.dir or 'e')
        local w = s.w or 14
        for i = 1, n do
            local u = rng.float() * 2 - 1
            local sp = (s.drift or 7) * (.4 + rng.float() * .8)
            local px = s.at[1] + math.cos(dir) * sp * t
                - math.sin(dir) * u * w * .5
            local py = s.at[2] + math.sin(dir) * sp * t
                + math.cos(dir) * u * w * .5
                - (s.rise or 0) * t * (rng.chance(.3) and 1 or .2)
            local sz = (i % 3 == 0) and 2 or 1
            for dy = 0, sz - 1 do for dx = 0, sz - 1 do
                put(g, px + dx, py + dy, s.ch)
            end end
        end
    end
end

-- FRAGMENTOS — cacos balísticos: cada caco sai com velocidade/ângulo
-- próprios, cai em parábola, tamanho 1-3px. spec: at, n, speed={a,b},
-- grav (px/frame² ~.4), size={a,b}, ch, ch2 (lado de sombra), dir bias
function V.fragments(s)
    local n = s.n or 7
    return function(f, N, g, rng)
        local t = (f - .5) / N
        local grav = s.grav or .35
        local dir = V.dir(s.dir or 'e')
        for i = 1, n do
            local a = dir + (rng.float() - .5) * 2.4 -- leque ±~69°
            local v = ((s.speed and s.speed[1] or 8)
                + rng.float() * ((s.speed and s.speed[2] or 16)
                    - (s.speed and s.speed[1] or 8)))
            local px = s.at[1] + math.cos(a) * v * t
            local py = s.at[2] + math.sin(a) * v * t + grav * t * t * 22
            local sz = (s.size and s.size[1] or 1)
                + math.floor(rng.float()
                    * ((s.size and s.size[2] or 2)
                        - (s.size and s.size[1] or 1) + 1)) - 1
            local tumble = rng.chance(.5)
            for dy = 0, sz - 1 do for dx = 0, sz - 1 do
                if sz <= 1 or tumble or (dx + dy) % 2 == 0 then
                    put(g, px + dx, py + dy,
                        dy == sz - 1 and (s.ch2 or s.ch) or s.ch)
                end
            end end
        end
    end
end

-- FUMAÇA — coluna de puffs que sobem, engordam e esgarçam. Cada puff
-- nasce com fase própria (sem loop sincronizado). spec: at, n, rise,
-- grow (raio final), w (boca), ch, ch2 (núcleo), seed
function V.smoke(s)
    local n = s.n or 5
    return function(f, N, g, rng)
        local t = (f - .5) / N
        local rise = s.rise or 14
        local grow = s.grow or 4
        local w = s.w or 6
        for i = 1, n do
            local ph = (i - 1) / n -- puffs desfasados
            local lt = math.min(1, math.max(0, t - ph * .4) / .8)
            local px = s.at[1] + (rng.float() * 2 - 1) * w * .5
                + math.sin(lt * 3 + i) * 2
            local py = s.at[2] - rise * lt + rng.float() * 2
            local r = 1 + grow * lt
            local rr = r * r
            for dy = -math.ceil(r), math.ceil(r) do
                for dx = -math.ceil(r), math.ceil(r) do
                    local d2 = dx * dx + dy * dy
                    if d2 <= rr and d2 >= rr * .35 then -- anel ralo
                        put(g, px + dx, py + dy,
                            d2 < rr * .55 and (s.ch2 or s.ch) or s.ch)
                    end
                end
            end
        end
    end
end

-- ONDA — anel de choque expandindo da origem; borda engrossa e quebra
-- no fim. squash<1 achata (onda de solo). spec: at, r0,r1, width,
-- squash, ch, seed
function V.wave(s)
    return function(f, N, g, rng)
        local t = V.env((f - .5) / N, s.ease or 'out')
        local r = (s.r0 or 3) + ((s.r1 or 22) - (s.r0 or 3)) * t
        local wid = s.width or 2
        local sq = s.squash or 1
        local breakup = math.max(0, t - .55) / .45 -- quebra na saída
        local steps = math.ceil(r * 6.3)
        for i = 0, steps do
            local a = (i / steps) * math.pi * 2
            for q = 0, wid - 1 do
                local rr = r - q
                local x = s.at[1] + math.cos(a) * rr
                local y = s.at[2] + math.sin(a) * rr * sq
                if breakup <= 0
                    or dissolveHash(math.floor(x), math.floor(y),
                        (s.seed or 0)) > breakup then
                    put(g, x, y, q == 0 and (s.edge or s.ch) or s.ch)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Materiais de efeito: legend + chars padrão por família. O autor
-- sobrescreve qualquer campo. e=/ei= segue o contrato do DSL; ei alto
-- (efetivo > BLOOM) floresce, baixo fica quente sem florescer.
--------------------------------------------------------------------------------

V.MAT = {
    faisca = {
        legend = {
            s = { ramp = 'ember', step = 4 },
            S = { ramp = 'ember', step = 6, e = 'ember.7', ei = .9 },
            w = { ramp = 'white', step = 1, e = 'white.1', ei = 1 },
        },
        ch = 's', hot = 'S',
    },
    poeira = {
        legend = {
            d = { ramp = 'earth', step = 3 },
            D = { ramp = 'earth', step = 4 },
        },
        ch = 'D',
    },
    fragmento = {
        legend = {
            q = { ramp = 'stone', step = 5 },
            Q = { ramp = 'stone', step = 3 },
        },
        ch = 'q', ch2 = 'Q',
    },
    fumaca = {
        legend = {
            m = { ramp = 'plaster', step = 2 },
            M = { ramp = 'plaster', step = 3 },
        },
        ch = 'm', ch2 = 'M',
    },
    onda = {
        legend = {
            o = { ramp = 'jade', step = 3, e = 'jade.3', ei = .5 },
            O = { ramp = 'jade', step = 5, e = 'jade.5', ei = .7 },
        },
        ch = 'o', edge = 'O',
    },
    trilha = {
        legend = {
            t = { ramp = 'jade', step = 4, e = 'jade.4', ei = .45 },
            T = { ramp = 'jade', step = 6, e = 'jade.6', ei = .8 },
        },
        ch = 't', tip = 'T',
    },
    arco = {
        legend = {
            a = { ramp = 'bone', step = 4 },
            A = { ramp = 'white', step = 1, e = 'white.1', ei = .55 },
            b = { ramp = 'bone', step = 2 },
        },
        ch = 'a', ch2 = 'b', edge = 'A',
    },
}

--------------------------------------------------------------------------------
-- Montagem: spec -> def DSL. spec = {
--   name, w, h, frames=N, margin=px (default 1), seed, legend,
--   anchor={x,y} origem do efeito dentro do frame (default: centro),
--   emit = true|false|function(f,N,ge,rng),
--   kind/dir = metadados de intenção (vão em def.vfx p/ o consumidor),
--   frame = function(f, N, ctx) — pinta ctx.albedo; ctx.rng é o
--   K.rng semeado por asset (determinismo independente de ordem).
-- }
--------------------------------------------------------------------------------

function V.sheet(spec)
    assert(type(spec.name) == 'string', 'kit_vfx: sheet sem name')
    assert(spec.w and spec.h, 'kit_vfx: sheet sem w/h')
    local N = spec.frames or 1
    -- emit: nil/false=sem emissivo; true=espelha albedo (cada char emite
    -- .e/.ei da legend, ou a cor de albedo ei=1); {only={chars}} só os
    -- chars listados emitem (núcleo quente, periferia opaca);
    -- function(f,N,ge) pinta grade emissiva própria.
    local only = nil
    if type(spec.emit) == 'table' and spec.emit.only then
        only = {}
        for _, c in ipairs(spec.emit.only) do only[c] = true end
    end
    local mirror = spec.emit == true or only ~= nil
    local albedo, emis = {}, (mirror or type(spec.emit) == 'function')
        and {} or nil
    local rng = K.rng('fx:' .. spec.name, spec.seed or 0)
    for f = 1, N do
        local ga = nova(spec.w, spec.h)
        spec.frame(f, N, { albedo = ga, rng = rng,
            w = spec.w, h = spec.h })
        albedo[f] = K.string(ga)
        if mirror then
            if only then
                local ge = nova(spec.w, spec.h)
                for y = 1, ga.h do for x = 1, ga.w do
                    if only[ga.rows[y][x]] then ge.rows[y][x] = ga.rows[y][x] end
                end end
                emis[f] = K.string(ge)
            else
                emis[f] = K.string(ga)
            end
        elseif type(spec.emit) == 'function' then
            local ge = nova(spec.w, spec.h)
            spec.emit(f, N, ge, rng)
            emis[f] = K.string(ge)
        end
    end
    return {
        name = spec.name, w = spec.w, h = spec.h,
        origin = 'topleft',
        frameUse = 'anim',
        -- anchor = ponto de origem do efeito DENTRO do frame (onde o
        -- consumidor posiciona a célula/âncora do impacto); spec.vfx
        -- carrega campos extras (fps, tags do consumidor).
        vfx = (function()
            local v = {}
            for k, x in pairs(spec.vfx or {}) do v[k] = x end
            v.anchor = spec.anchor or v.anchor
                or { math.floor(spec.w / 2), math.floor(spec.h / 2) }
            v.margin = spec.margin or v.margin or 1
            v.seed = spec.seed or v.seed or 0
            v.kind = spec.kind or v.kind
            v.dir = spec.dir or v.dir
            return v
        end)(),
        legend = spec.legend,
        layers = {
            { name = 'fx', h = 0,
                albedo = (#albedo == 1 and albedo[1] or albedo),
                emissive = emis and (#emis == 1 and emis[1] or emis) or nil },
        },
    }
end

--------------------------------------------------------------------------------
-- Revisão do def (antes do bake): margem de frames, emissivo/bloom,
-- cobertura por frame. Devolve lista de warnings + fatos.
--------------------------------------------------------------------------------

function V.check(def, resolve)
    local out = {}
    local vfx = def.vfx or {}
    local margin = vfx.margin or 0
    local lay = def.layers[1]
    local albs = type(lay.albedo) == 'table' and lay.albedo or { lay.albedo }
    local ems = lay.emissive
        and (type(lay.emissive) == 'table' and lay.emissive
            or { lay.emissive })
    -- Emissivo efetivo por char (cor * ei) -> flag de bloom por frame
    local function eiOf(ch)
        local e = def.legend[ch]
        if not e then return 0, 'missing' end
        return e.ei or 1
    end
    local bloomFrames, maxEi = {}, 0
    for f = 1, #albs do
        local g = K.parse(albs[f])
        -- margem: nenhum pixel na faixa externa de `margin` px
        for y = 1, g.h do for x = 1, g.w do
            if g.rows[y][x] ~= '.'
                and (x <= margin or y <= margin
                    or x > g.w - margin or y > g.h - margin) then
                out[#out + 1] = ('WARN frame %d: pixel (%d,%d) dentro da '
                    .. 'margem %dpx'):format(f, x, y, margin)
            end
        end end
        if ems and ems[f] then
            local ge = K.parse(ems[f])
            local bloom = false
            for y = 1, ge.h do for x = 1, ge.w do
                local c = ge.rows[y][x]
                if c ~= '.' then
                    local ei, miss = eiOf(c)
                    if miss then
                        out[#out + 1] = ('ERROR frame %d: char emissivo '
                            .. "'%s' ausente na legend"):format(f, c)
                    end
                    -- ei>0 e cor emitida >0: ei alto é proxy do bloom
                    if ei >= .55 then bloom = true end
                    maxEi = math.max(maxEi, ei)
                end
            end end
            bloomFrames[f] = bloom
        end
    end
    if ems then
        out[#out + 1] = ('INFO bloom: %s (ei max %.2f, limiar %.2f)')
            :format((function()
                local n = 0
                for _, b in pairs(bloomFrames) do n = n + 1 end
                return n == 0 and 'nenhum frame floresce'
                    or n .. '/' .. #albs .. ' frames florescem'
            end)(), maxEi, V.BLOOM)
    else
        out[#out + 1] = 'INFO emissivo: ausente (efeito opaco, sem bloom)'
    end
    -- cobertura: frames totalmente vazios são suspeitos
    for f = 1, #albs do
        local g = K.parse(albs[f])
        local n = 0
        for y = 1, g.h do for x = 1, g.w do
            if g.rows[y][x] ~= '.' then n = n + 1 end
        end end
        if n == 0 then
            out[#out + 1] = ('WARN frame %d vazio'):format(f)
        end
    end
    return out
end

return V
