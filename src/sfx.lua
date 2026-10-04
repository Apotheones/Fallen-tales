-- Mixer procedural do jogo: tudo é SoundData sintetizado em 22050 Hz/16bit/
-- mono, na mesma escola do tone() de src/feedback.lua — sem samples, sem
-- assets. Cues one-shot vivem em tags de categoria (ripple) e os loops de
-- ambiência são gerados sob demanda com emenda na borda. Substitui o stub
-- silencioso: os call sites já emitiam os ids.
local ripple = require('vendor.ripple')
local RATE = 22050
local Sfx = {
    time = 0, muted = false, paused = false, ducked = false, disabled = false,
    stats = {count = {}, last = {}},
    -- Volumes por canal (0..1) ajustáveis no menu de opções: master escala
    -- todos, 'music' é lido por src/music.lua e 'ambience' pelos loops de
    -- região — os demais multiplicam a tag ripple homônima.
    volumes = {master = 1, music = 1, ui = 1, world = 1, voice = 1,
        scene = 1, ambience = 1},
    -- Ordem de exibição e rótulos dos canais (o menu lê daqui).
    channels = {'master', 'music', 'ui', 'world', 'voice', 'scene', 'ambience'},
    CHANNEL_LABELS = {master = 'GERAL', music = 'MÚSICA', ui = 'MENU',
        world = 'EFEITOS', voice = 'VOZES', scene = 'CENA', ambience = 'AMBIENTE'},
}

-- Vozes dos monstros da arena (pitch do blip); pessoas moram em Lore.voices
-- (campaign_lore faz merge ao carregar — lido em runtime, nunca em cache).
local MONSTERS = {ranger = 1.15, dasher = .72, crawler = 1.45, husk = .6,
    sower = 1.05, watcher = .9, veteran = .55, breaker = .6, demolisher = .5,
    warden = .52, regent = .58}

-- Volume base de cada categoria (uma tag do ripple por categoria).
local CATEGORY = {ui = .55, world = .65, voice = .5, scene = .6}

-- Receitas dos cues: camadas {f=Hz, d=s, mode, v=ganho, delay=s} mixadas
-- aditivamente. gap = intervalo mínimo entre plays; max = teto de plays na
-- janela de .3 s; vol = ganho do cue inteiro.
local CUES = {
    ui_move = {cat = 'ui', gap = .04, vol = .5,
        layers = {{f = 880, d = .045, mode = 'plucked', v = .7}}},
    ui_confirm = {cat = 'ui',
        layers = {{f = 520, d = .13, mode = 'rise', v = .6},
            {f = 1040, d = .09, mode = 'bell', v = .35, delay = .05}}},
    ui_cancel = {cat = 'ui',
        layers = {{f = 420, d = .11, mode = 'fall', v = .6}}},
    ui_deny = {cat = 'ui', gap = .12,
        layers = {{f = 150, d = .07, mode = 'metal', v = .7},
            {f = 130, d = .09, mode = 'metal', v = .7, delay = .09}}},
    ui_toggle = {cat = 'ui',
        layers = {{f = 640, d = .07, mode = 'plucked', v = .55}}},
    ui_pause = {cat = 'ui',
        layers = {{f = 300, d = .10, mode = 'fall', v = .5}}},
    ui_resume = {cat = 'ui',
        layers = {{f = 300, d = .10, mode = 'rise', v = .5}}},
    help_open = {cat = 'ui',
        layers = {{f = 500, d = .07, mode = 'bow', v = .4},
            {f = 760, d = .1, mode = 'plucked', v = .4, delay = .04}}},
    shop_buy = {cat = 'ui',
        layers = {{f = 880, d = .12, mode = 'bell', v = .4},
            {f = 1174, d = .1, mode = 'bell', v = .3, delay = .07}}},
    dlg_open = {cat = 'voice',
        layers = {{f = 440, d = .09, mode = 'plucked', v = .5},
            {f = 660, d = .12, mode = 'plucked', v = .5, delay = .07}}},
    dlg_advance = {cat = 'voice', gap = .06,
        layers = {{f = 520, d = .045, mode = 'plucked', v = .35}}},
    dlg_options = {cat = 'voice',
        layers = {{f = 580, d = .06, mode = 'plucked', v = .4},
            {f = 780, d = .08, mode = 'plucked', v = .35, delay = .05}}},
    dlg_choice = {cat = 'voice',
        layers = {{f = 660, d = .08, mode = 'plucked', v = .5}}},
    dlg_close = {cat = 'voice',
        layers = {{f = 520, d = .10, mode = 'fall', v = .4}}},
    npc_greet = {cat = 'voice',
        layers = {{f = 600, d = .12, mode = 'plucked', v = .5}}},
    bark = {cat = 'voice', gap = .05,
        layers = {{f = 640, d = .09, mode = 'plucked', v = .5},
            {f = 420, d = .06, mode = 'plucked', v = .3, delay = .05}}},
    gesture = {cat = 'voice',
        layers = {{f = 300, d = .09, mode = 'bow', v = .35}}},
    emote_warm = {cat = 'scene',
        layers = {{f = 660, d = .4, mode = 'bell', v = .35},
            {f = 990, d = .5, mode = 'bell', v = .25, delay = .18}}},
    emote_soft = {cat = 'scene',
        layers = {{f = 392, d = .3, mode = 'plucked', v = .35},
            {f = 523, d = .45, mode = 'plucked', v = .3, delay = .2}}},
    emote_tense = {cat = 'scene',
        layers = {{f = 160, d = .35, mode = 'rise', v = .45},
            {f = 75, d = .4, mode = 'rumble', v = .3}}},
    emote_dark = {cat = 'scene',
        layers = {{f = 220, d = .6, mode = 'bell', v = .4},
            {f = 68, d = .6, mode = 'rumble', v = .35, delay = .1}}},
    portal_open = {cat = 'world',
        layers = {{f = 110, d = .5, mode = 'rumble', v = .5},
            {f = 880, d = .5, mode = 'bell', v = .4, delay = .12},
            {f = 1320, d = .4, mode = 'bell', v = .3, delay = .3}}},
    portal_travel = {cat = 'world',
        layers = {{f = 180, d = .55, mode = 'whoosh', v = .6},
            {f = 90, d = .4, mode = 'rumble', v = .4},
            {f = 990, d = .35, mode = 'bell', v = .25, delay = .35}}},
    region_arrive = {cat = 'world',
        layers = {{f = 784, d = .3, mode = 'bell', v = .3},
            {f = 1175, d = .35, mode = 'bell', v = .22, delay = .14}}},
    encounter_start = {cat = 'world',
        layers = {{f = 160, d = .3, mode = 'rise', v = .55},
            {f = 140, d = .15, mode = 'impact', v = .5}}},
    boss_intro = {cat = 'world',
        layers = {{f = 70, d = .6, mode = 'rumble', v = .6},
            {f = 220, d = .5, mode = 'fall', v = .45, delay = .1},
            {f = 1100, d = .4, mode = 'metal', v = .2, delay = .25}}},
    battle_won = {cat = 'world',
        layers = {{f = 440, d = .7, mode = 'reward', v = .6}}},
    battle_negotiated = {cat = 'world',
        layers = {{f = 523, d = .18, mode = 'bell', v = .4},
            {f = 659, d = .2, mode = 'bell', v = .4, delay = .16},
            {f = 784, d = .3, mode = 'bell', v = .35, delay = .32}}},
    battle_flee = {cat = 'world',
        layers = {{f = 400, d = .2, mode = 'fall', v = .5}}},
    battle_warn = {cat = 'world', gap = .2,
        layers = {{f = 185, d = .2, mode = 'rise', v = .4}}},
    cutscene_open = {cat = 'scene',
        layers = {{f = 140, d = .3, mode = 'whoosh', v = .3},
            {f = 660, d = .35, mode = 'bell', v = .3, delay = .1}}},
    cutscene_advance = {cat = 'scene',
        layers = {{f = 600, d = .06, mode = 'bow', v = .35}}},
    cutscene_skip = {cat = 'scene',
        layers = {{f = 500, d = .14, mode = 'fall', v = .4}}},
    death_return = {cat = 'scene',
        layers = {{f = 196, d = .8, mode = 'bell', v = .4},
            {f = 98, d = .9, mode = 'rumble', v = .3, delay = .15}}},
    step = {cat = 'world', gap = .13, vol = .9,
        layers = {{f = 95, d = .05, mode = 'thud', v = .35}}},
    -- Perigo próximo: batida dupla grave espaçada (lub-dub) — avisa que um
    -- encontro vivo está a poucos tiles antes do contato abrir a arena.
    danger_near = {cat = 'world', gap = 1.4, vol = .8,
        layers = {{f = 75, d = .09, mode = 'thud', v = .5},
            {f = 65, d = .1, mode = 'thud', v = .45, delay = .16}}},
}

-- Síntese ---------------------------------------------------------------

-- Adaptação do tone() de feedback.lua: mesma LCG, fase integrada e envelope
-- de ataque rápido + queda na cauda. Os modos novos ('bell', 'whoosh',
-- 'thud', 'hum') estendem a família sem sair da fórmula.
local function layer(buf, offset, n, f, d, mode, v)
    local noise, phase, lp = 113, 0, 0
    local ns = math.floor(d * RATE)
    local melody = mode == 'reward' and {1, 1.25, 1.5, 2}
        or mode == 'clear' and {1, 1.5, 2, 2.5}
    for i = 0, ns - 1 do
        local idx = offset + i
        if idx >= n then break end
        local t, p = i / RATE, i / ns
        local freq = f * (mode == 'fall' and (1 - .65 * p)
            or mode == 'rise' and (1 + p) or 1)
        local age = t
        if melody then
            local step = d / #melody
            freq = f * melody[math.min(#melody, math.floor(t / step) + 1)]
            age = t % step
        elseif mode == 'bow' then freq = f * (1 - .7 * p)
        elseif mode == 'rumble' then freq = f * (1 - .8 * p)
        elseif mode == 'thud' then freq = f * (1 - .5 * p) end
        phase = phase + freq * math.pi * 2 / RATE
        noise = (noise * 16807) % 2147483647
        local grain = (noise / 2147483647 - .5) * 2
        local wave = math.sin(phase) + .25 * math.sin(phase * 2)
        local envelope = math.min(1, age * 180) * (1 - p) ^ 2
        if mode == 'impact' or mode == 'rumble' then
            wave = wave * .65 + grain * math.exp(-t * (mode == 'rumble' and 9 or 35))
        elseif mode == 'metal' then
            wave = math.sin(phase) * .55 + math.sin(phase * 2.76) * math.exp(-t * 18) * .4
                + grain * math.exp(-t * 70) * .3
        elseif mode == 'bow' then
            wave = wave * math.exp(-t * 28) * .6 + grain * math.exp(-t * 40) * .8
        elseif mode == 'plucked' or melody then
            wave = (math.sin(phase) + .3 * math.sin(phase * 3) * math.exp(-age * 12))
                * math.exp(-age * 7)
        elseif mode == 'bell' then
            -- sino: parciais inarmônicos decaem mais rápido que o fundamental,
            -- cauda longa em exponencial
            wave = math.sin(phase) + .45 * math.sin(phase * 2.4) * math.exp(-t * 4.5)
                + .28 * math.sin(phase * 4.2) * math.exp(-t * 8)
            envelope = math.min(1, t * 260) * math.exp(-t * 3.4) * (1 - p) ^ 2
        elseif mode == 'whoosh' then
            -- rajada: ruído cuja banda abre devagar (ataque ~40%) e flutua
            lp = lp + (.03 + .55 * p) * (grain - lp)
            wave = (grain - lp) * .8 + lp * math.sin(phase * .25) * .9
            envelope = math.min(1, p / .4) * (1 - p) ^ 1.6
        elseif mode == 'thud' then
            -- baque: senoide caindo ~2:1 + grão seco curto
            wave = math.sin(phase) * .85 + grain * math.exp(-t * 110) * .4
        elseif mode == 'hum' then
            -- zumbido morno: fundamental grave + harmônico suave
            wave = math.sin(phase) + .3 * math.sin(phase * 2)
            envelope = math.min(1, p / .3) * (1 - p) ^ 2
        end
        -- Janela de saída por camada: os últimos ~15% caem em quadrático até
        -- zero — caudas longas (bell) não podem depender só do fade global.
        local out = math.min(1, (ns - i) / math.max(1, ns * .15))
        buf[idx] = buf[idx] + wave * envelope * v * out * out
    end
end

-- Mixa as camadas do cue, limita o pico em .28 e fecha a cauda com fade de
-- ~8 ms (mesmo teto do tone(), para os dois mixers conviverem sem clipping).
local function render(spec)
    local n = 1
    for _, l in ipairs(spec.layers) do
        n = math.max(n, math.floor(((l.delay or 0) + l.d) * RATE))
    end
    local buf = {}
    for i = 0, n - 1 do buf[i] = 0 end
    for _, l in ipairs(spec.layers) do
        layer(buf, math.floor((l.delay or 0) * RATE), n, l.f, l.d, l.mode, l.v or 1)
    end
    local peak = 0
    for i = 0, n - 1 do local a = math.abs(buf[i]); if a > peak then peak = a end end
    local gain = peak > .28 and .28 / peak or 1
    local data = love.sound.newSoundData(n, RATE, 16, 1)
    -- Fade cúbico na cauda do buffer mixado (~10 ms ou 8%): garante silêncio
    -- real no corte — janela linear curta deixava clique audível nos bells.
    local fade = math.max(220, math.floor(n * .08))
    for i = 0, n - 1 do
        local s = buf[i] * gain
        if i >= n - fade then s = s * ((n - 1 - i) / fade) ^ 3 end
        data:setSample(i, math.max(-1, math.min(1, s)))
    end
    return data
end

-- Ambiência ---------------------------------------------------------------

-- Geradores determinísticos: cada um devolve a tabela de amostras cruas de
-- len pontos (loop de 8 s + a margem da emenda). Semente própria por região
-- — a borda do loop só depende dela.
local function newNoise(seed)
    local n = seed
    return function()
        n = (n * 16807) % 2147483647
        return (n / 2147483647 - .5) * 2
    end
end

local function newRand(seed)
    local n = seed
    return function(a, b)
        n = (n * 16807) % 2147483647
        local u = n / 2147483647
        if not a then return u end
        return a + (b - a) * u
    end
end

-- baseFn(tt, g) gera o fundo amostra a amostra; events = {t, d, fn(dt, g)}
-- são transientes somados numa segunda passada. Pico limitado em .7 (o
-- volume efetivo do loop é .13, sobra headroom).
local function buildAmbience(len, baseFn, events)
    local grain = newNoise(911)
    local G = {}
    for i = 0, len - 1 do G[i] = baseFn(i / RATE, grain()) end
    for _, ev in ipairs(events or {}) do
        local i0 = math.floor(ev.t * RATE)
        local i1 = math.min(len - 1, i0 + math.floor(ev.d * RATE) - 1)
        for i = i0, i1 do
            G[i] = G[i] + ev.fn((i - i0) / RATE, grain())
        end
    end
    local peak = 0
    for i = 0, len - 1 do local a = math.abs(G[i]); if a > peak then peak = a end end
    local k = peak > .7 and .7 / peak or 1
    for i = 0, len - 1 do G[i] = G[i] * k end
    return G
end

local AMBIENT_BUILDERS = {}

AMBIENT_BUILDERS.colina = function(len)
    -- vento: ruído bem suavizado (média móvel) com swell lento de .08 Hz,
    -- assobios esparsos em banda alta e raros ticks secos de galho.
    local rand = newRand(6101)
    local events = {}
    local t = rand(.5, 1.5)
    while t < len / RATE - .5 do
        local dur, amp, lp2 = rand(.4, .9), rand(.10, .18), 0
        events[#events + 1] = {t = t, d = dur, fn = function(dt, g)
            lp2 = lp2 + .12 * (g - lp2)
            return (g - lp2) * math.sin(math.pi * dt / dur) * amp
        end}
        t = t + rand(1.8, 4.5)
    end
    t = rand(1, 3)
    while t < len / RATE - .3 do
        local amp = rand(.12, .22)
        events[#events + 1] = {t = t, d = .03, fn = function(dt, g)
            return g * math.exp(-dt * 130) * amp
        end}
        t = t + rand(3, 7)
    end
    local lp, band = 0, 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .012 * (g - lp)
        band = band + .06 * (g - band)
        local swell = .66 + .34 * math.sin(2 * math.pi * .08 * tt + 1.3)
        return lp * swell * 2.2 + (g - band) * .10
    end, events)
end

AMBIENT_BUILDERS.hub = function(len)
    -- lar: hum morno de 80 Hz + harmônico, estalos de fogo (impulsos com
    -- decaimento ~20 ms) e gotejamento leve.
    local rand = newRand(6202)
    local events = {}
    local t = rand(0, .3)
    while t < len / RATE - .1 do
        local amp = rand(.18, .4)
        events[#events + 1] = {t = t, d = .06, fn = function(dt, g)
            return g * math.exp(-dt * 50) * amp
        end}
        t = t + rand(.15, .75)
    end
    t = rand(1, 2)
    while t < len / RATE - .3 do
        local f0 = rand(950, 1300)
        events[#events + 1] = {t = t, d = .09, fn = function(dt)
            return math.sin(2 * math.pi * f0 * (dt - .27 * dt * dt / .09))
                * math.exp(-dt * 45) * .16
        end}
        t = t + rand(1.8, 4.2)
    end
    local lp = 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .03 * (g - lp)
        return .2 * math.sin(2 * math.pi * 80 * tt)
            + .07 * math.sin(2 * math.pi * 160 * tt + .5) + lp * .8
    end, events)
end

AMBIENT_BUILDERS.mercado = function(len)
    -- murmúrio de feira: banda média modulada por LFO irregular, batidas de
    -- madeira e cliques metálicos esparsos.
    local rand = newRand(6303)
    local events = {}
    local t = rand(.2, 1)
    while t < len / RATE - .3 do
        if rand() < .65 then
            local f0 = rand(150, 210)
            events[#events + 1] = {t = t, d = .12, fn = function(dt, g)
                return (math.sin(2 * math.pi * f0 * dt) * math.exp(-dt * 26)
                    + g * math.exp(-dt * 140) * .5) * .3
            end}
        else
            local f0 = rand(1800, 3200)
            events[#events + 1] = {t = t, d = .05, fn = function(dt, g)
                return (math.sin(2 * math.pi * f0 * dt) * math.exp(-dt * 70)
                    + g * math.exp(-dt * 160)) * .18
            end}
        end
        t = t + rand(.7, 2.4)
    end
    local mid, slow = 0, 0
    return buildAmbience(len, function(tt, g)
        mid = mid + .25 * (g - mid)
        slow = slow + .02 * (g - slow)
        local lfo = .55 + .25 * math.sin(2 * math.pi * .11 * tt)
            + .2 * math.sin(2 * math.pi * .23 * tt + 2)
        return (mid - slow) * 1.6 * lfo + slow * .5
    end, events)
end

AMBIENT_BUILDERS.oficinas = function(len)
    -- hum de máquina ~52 Hz + harmônico, ticks metálicos esparsos e sopro
    -- de ar em swell lento.
    local rand = newRand(6404)
    local events = {}
    local t = rand(.3, 1)
    while t < len / RATE - .3 do
        local f0, amp = rand(1400, 2600), rand(.15, .3)
        events[#events + 1] = {t = t, d = .05, fn = function(dt, g)
            return (math.sin(2 * math.pi * f0 * dt) * math.exp(-dt * 55)
                + g * math.exp(-dt * 120) * .6) * amp
        end}
        t = t + rand(.6, 2.2)
    end
    local lp, air = 0, 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .02 * (g - lp)
        air = air + .08 * (g - air)
        local breath = .5 + .5 * math.sin(2 * math.pi * .06 * tt + .8)
        return .21 * math.sin(2 * math.pi * 52 * tt)
            + .07 * math.sin(2 * math.pi * 104 * tt)
            + lp * .9 + (g - air) * .10 * breath
    end, events)
end

AMBIENT_BUILDERS.reservatorio = function(len)
    -- pingos na água: pings de sino (900-1600 Hz) com dois ecos curtos,
    -- espaçados ao acaso entre .3 e 1.2 s, sobre ruído aquático grave.
    local rand = newRand(6505)
    local events = {}
    local t = rand(0, .4)
    while t < len / RATE - 1 do
        local f0, amp = rand(900, 1600), rand(.22, .34)
        local function ping(dt, g)
            return (math.sin(2 * math.pi * f0 * dt)
                + .4 * math.sin(2 * math.pi * f0 * 2.76 * dt) * math.exp(-dt * 8))
                * math.exp(-dt * 5.5) * g
        end
        events[#events + 1] = {t = t, d = .5, fn = function(dt) return ping(dt, amp) end}
        events[#events + 1] = {t = t + .18, d = .4, fn = function(dt) return ping(dt, amp * .45) end}
        events[#events + 1] = {t = t + .36, d = .3, fn = function(dt) return ping(dt, amp * .2) end}
        t = t + rand(.3, 1.2)
    end
    local lp = 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .015 * (g - lp)
        return lp * 1.3 + .05 * math.sin(2 * math.pi * 70 * tt)
    end, events)
end

AMBIENT_BUILDERS.saloes = function(len)
    -- ar de salão vazio: ruído aéreo suave e um motivo esparso de caixinha
    -- de música (3-4 notas menores, decaimento longo, eco simples).
    local rand = newRand(6606)
    local scale = {660, 784, 880, 990, 1174.7}
    local events = {}
    local t = rand(.5, 1.5)
    while t < len / RATE - 2.5 do
        local tt = t
        for _ = 1, 3 + (rand() < .5 and 1 or 0) do
            local f0 = scale[math.floor(rand(1, #scale + .999))]
            local amp = rand(.16, .26)
            local function note(dt, g)
                return (math.sin(2 * math.pi * f0 * dt)
                    + .3 * math.sin(2 * math.pi * f0 * 3 * dt) * math.exp(-dt * 5))
                    * math.exp(-dt * 2.2) * g
            end
            events[#events + 1] = {t = tt, d = 1.4, fn = function(dt) return note(dt, amp) end}
            events[#events + 1] = {t = tt + .32, d = 1, fn = function(dt) return note(dt, amp * .35) end}
            tt = tt + rand(.4, .7)
        end
        t = tt + rand(1.5, 3)
    end
    local lp = 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .05 * (g - lp)
        return (g - lp) * .16 + lp * .35
    end, events)
end

AMBIENT_BUILDERS.fundacao = function(len)
    -- alicerce: drone de 45+90 Hz, swell de rumble e pingos raros.
    local rand = newRand(6707)
    local events = {}
    local t = rand(1, 3)
    while t < len / RATE - .3 do
        local f0 = rand(800, 1400)
        events[#events + 1] = {t = t, d = .1, fn = function(dt)
            return math.sin(2 * math.pi * f0 * (dt - .3 * dt * dt / .1))
                * math.exp(-dt * 40) * .14
        end}
        t = t + rand(3, 6.5)
    end
    local lp = 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .006 * (g - lp)
        local swell = .6 + .4 * math.sin(2 * math.pi * .05 * tt + .4)
        return .24 * math.sin(2 * math.pi * 45 * tt)
            + .15 * math.sin(2 * math.pi * 90 * tt + 1) + lp * swell * 2.4
    end, events)
end

AMBIENT_BUILDERS.refugio = function(len)
    -- interior de lar: hum morno de 65 Hz + harmônico, estalos de lareira
    -- densos e macios (impulsos com decaimento ~16 ms) e rangido de madeira
    -- ocasional. Tom seco e abafado, mais baixo que o hub — é casa, não praça.
    local rand = newRand(6808)
    local events = {}
    local t = rand(0, .3)
    while t < len / RATE - .1 do
        local amp = rand(.10, .22)
        events[#events + 1] = {t = t, d = .05, fn = function(dt, g)
            return g * math.exp(-dt * 60) * amp
        end}
        t = t + rand(.2, .9)
    end
    t = rand(2, 5)
    while t < len / RATE - .5 do
        local f0, drop = rand(175, 190), rand(35, 50)
        local dur = rand(.25, .35)
        events[#events + 1] = {t = t, d = dur, fn = function(dt)
            -- rangido: senoide escorregando ~180→140 Hz com janela senoidal
            return math.sin(2 * math.pi * (f0 * dt - drop * dt * dt / (2 * dur)))
                * math.sin(math.pi * dt / dur) * .12
        end}
        t = t + rand(4, 8)
    end
    local lp, air = 0, 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .02 * (g - lp)
        air = air + .07 * (g - air)
        local breath = .5 + .5 * math.sin(2 * math.pi * .05 * tt + 2.1)
        return .16 * math.sin(2 * math.pi * 65 * tt)
            + .05 * math.sin(2 * math.pi * 130 * tt + .4)
            + lp * .55 + (g - air) * .05 * breath
    end, events)
end

AMBIENT_BUILDERS.andlar = function(len)
    -- a cidade morta: vento oco (ruído suavizado fundo, swell ~.05 Hz e
    -- quase sem banda alta), drone dissonante fraco (55 + 58 Hz batendo)
    -- e ecos metálicos distantes de cauda longa. Mais vazio que a colina.
    local rand = newRand(6909)
    local events = {}
    local t = rand(.5, 2)
    while t < len / RATE - 2 do
        local f0, amp = rand(250, 450), rand(.10, .16)
        local function ping(dt, g)
            return (math.sin(2 * math.pi * f0 * dt)
                + .35 * math.sin(2 * math.pi * f0 * 2.76 * dt) * math.exp(-dt * 6))
                * math.exp(-dt * 3.2) * g
        end
        events[#events + 1] = {t = t, d = 1, fn = function(dt) return ping(dt, amp) end}
        events[#events + 1] = {t = t + .45, d = .9, fn = function(dt) return ping(dt, amp * .4) end}
        events[#events + 1] = {t = t + .9, d = .7, fn = function(dt) return ping(dt, amp * .16) end}
        t = t + rand(2.5, 6)
    end
    local lp, band = 0, 0
    return buildAmbience(len, function(tt, g)
        lp = lp + .008 * (g - lp)
        band = band + .05 * (g - band)
        local swell = .62 + .38 * math.sin(2 * math.pi * .05 * tt + .9)
        return lp * swell * 2
            + .09 * math.sin(2 * math.pi * 55 * tt)
            + .08 * math.sin(2 * math.pi * 58 * tt + 1.2)
            + (g - band) * .05
    end, events)
end

-- Loop seamless: gera N+K amostras e cruza a margem de volta na cabeça —
-- out[i] = lerp(G[N+i], G[i], i/K) para i < K. Um micro-ajuste na cauda
-- fecha exatamente na amostra de borda, sem clique no wrap.
local AMBIENT_SECONDS, SEAM = 8, 1100
local function ambienceData(id)
    local builder = AMBIENT_BUILDERS[id] or AMBIENT_BUILDERS.colina
    local N = AMBIENT_SECONDS * RATE
    local G = builder(N + SEAM)
    local data = love.sound.newSoundData(N, RATE, 16, 1)
    for i = 0, N - 1 do
        local s = G[i]
        if i < SEAM then
            local w = i / SEAM
            s = G[N + i] * (1 - w) + G[i] * w
        end
        data:setSample(i, math.max(-1, math.min(1, s)))
    end
    local TAIL = 64
    for i = N - TAIL, N - 1 do
        local w = (i - (N - TAIL)) / TAIL
        data:setSample(i, data:getSample(i) * (1 - w) + G[N] * w)
    end
    return data
end

-- Estado interno -----------------------------------------------------------

local tags, sounds, playLog
local ambCache = {}
local ambience = {id = nil, source = nil, level = 0, out = {}}

-- Inicialização lazy: primeiro play/update/selfCheck materializa as tags e
-- os SoundData. Se a máquina de áudio falhar, o mixer desliga sem quebrar.
local function ensureInit()
    if sounds or Sfx.disabled then return end
    local ok = pcall(function()
        tags = {}
        for cat, vol in pairs(CATEGORY) do
            tags[cat] = ripple.newTag(); tags[cat].volume = vol
        end
        sounds, playLog = {}, {}
        for id, spec in pairs(CUES) do
            sounds[id] = ripple.newSound(love.audio.newSource(render(spec), 'static'),
                {tags = {tags[spec.cat]}})
        end
    end)
    if not ok then Sfx.disabled = true end
end

-- API ----------------------------------------------------------------------

function Sfx.play(id, opts)
    if Sfx.disabled or Sfx.muted then return end
    ensureInit()
    if Sfx.disabled then return end
    local spec = CUES[id]
    if not spec then return end
    local now = Sfx.time
    -- Throttle por cue: gap mínimo entre plays efetivos...
    if now - (Sfx.stats.last[id] or -math.huge) < (spec.gap or .04) then return end
    -- ...e teto de plays da mesma cue numa janela de .3 s.
    local log = playLog[id]
    if not log then log = {}; playLog[id] = log end
    local live = 0
    for _, t0 in ipairs(log) do if now - t0 < .3 then live = live + 1 end end
    if live >= (spec.max or 4) then return end
    log[#log + 1] = now
    if #log > 8 then table.remove(log, 1) end
    sounds[id]:play({pitch = opts and opts.pitch or 1,
        volume = (opts and opts.volume or 1) * (spec.vol or 1)})
    Sfx.stats.count[id] = (Sfx.stats.count[id] or 0) + 1
    Sfx.stats.last[id] = now
end

function Sfx.setMuted(b) Sfx.muted = b and true or false end
function Sfx.setPaused(b) Sfx.paused = b and true or false end
function Sfx.setDucked(b) Sfx.ducked = b and true or false end

-- Ajuste fino por canal: clampado em 0..1, canal desconhecido é no-op.
function Sfx.setVolume(channel, level)
    if Sfx.volumes[channel] == nil then return end
    Sfx.volumes[channel] = math.max(0, math.min(1, tonumber(level) or 0))
end

function Sfx.getVolume(channel) return Sfx.volumes[channel] end

function Sfx.voice(id)
    local Lore = require('src.lore')
    if Lore.voices and Lore.voices[id] then return Lore.voices[id] end
    return MONSTERS[id] or 1
end

-- Para todos os sons da categoria (pular cutscene corta só os canais dela).
function Sfx.stopCategory(cat)
    if tags and tags[cat] then tags[cat]:stop() end
end

-- Resolve o builder efetivo da ambiência: o id do mapa vence quando tem
-- builder próprio; sem ele tenta o realm (capela → refugio); sem os dois
-- cai na colina. nil devolve nil — setAmbience(nil) é fade out, não clima.
local function resolveAmbience(id, realm)
    if not id then return nil end
    return AMBIENT_BUILDERS[id] and id
        or (realm and AMBIENT_BUILDERS[realm] and realm)
        or 'colina'
end
Sfx.resolveAmbience = resolveAmbience

-- Crossfade ~1.5 s para o loop da região; nil faz fade out. Loops são
-- gerados sob demanda e cacheados pelo id resolvido (mapa → realm → colina).
function Sfx.setAmbience(id, realm)
    id = resolveAmbience(id, realm)
    if id == ambience.id then return end
    if ambience.source then
        ambience.out[#ambience.out + 1] = {source = ambience.source, level = ambience.level}
        ambience.source = nil
    end
    if not id then ambience.id = nil; return end
    ensureInit()
    if Sfx.disabled then return end
    local data = ambCache[id]
    if not data then
        local ok, d = pcall(ambienceData, id)
        if not ok then return end
        data, ambCache[id] = d, d
    end
    local ok, source = pcall(love.audio.newSource, data, 'static')
    if not ok then return end
    source:setLooping(true); source:setVolume(0); source:play()
    -- O id só vira "ativo" com o loop realmente no ar: falha de geração ou
    -- de device deixa nil e a próxima chamada com o mesmo id tenta de novo.
    ambience.id, ambience.source, ambience.level = id, source, 0
end

function Sfx.update(dt)
    Sfx.time = Sfx.time + dt
    ensureInit()
    if Sfx.disabled then return end
    for cat, tag in pairs(tags) do
        tag.volume = Sfx.muted and 0
            or CATEGORY[cat] * Sfx.volumes[cat] * Sfx.volumes.master
    end
    for _, sound in pairs(sounds) do sound:update(dt) end
    -- Ambiência: .13 base × canais, abaixa na pausa e ducked em combate,
    -- zera no mute.
    local target = .13 * Sfx.volumes.ambience * Sfx.volumes.master
        * (Sfx.paused and .35 or 1) * (Sfx.ducked and .5 or 1)
        * (Sfx.muted and 0 or 1)
    if ambience.source then
        ambience.level = math.min(1, ambience.level + dt / 1.5)
        ambience.source:setVolume(ambience.level * target)
    end
    for i = #ambience.out, 1, -1 do
        local old = ambience.out[i]
        old.level = old.level - dt / 1.5
        if old.level <= 0 then
            old.source:stop(); old.source:release()
            table.remove(ambience.out, i)
        else
            old.source:setVolume(old.level * target)
        end
    end
end

-- QA: renderiza todos os cues e ambiências, confere throttle e mute.
-- Run in LÖVE: require('src.sfx').selfCheck()
function Sfx.selfCheck()
    ensureInit()
    for id, spec in pairs(CUES) do
        local data = render(spec)
        local n = data:getSampleCount()
        assert(data:getDuration() > 0 and n > 0, 'Cue sem duração: ' .. id)
        local peak, tail = 0, 0
        for i = 0, n - 1 do
            local s = math.abs(data:getSample(i))
            if s > peak then peak = s end
            if i >= n - 100 and s > tail then tail = s end
        end
        assert(peak > .01 and peak <= .99, 'Pico do cue fora da faixa: ' .. id)
        assert(tail < .001, 'Cue sem fade de cauda: ' .. id)
        data:release()
    end
    for id in pairs(AMBIENT_BUILDERS) do
        local data = ambienceData(id)
        local n = data:getSampleCount()
        assert(data:getDuration() > 0, 'Ambiência sem duração: ' .. id)
        local peak = 0
        for i = 0, n - 1 do
            local s = math.abs(data:getSample(i))
            if s > peak then peak = s end
        end
        assert(peak > .01 and peak <= .99, 'Pico da ambiência fora da faixa: ' .. id)
        -- Emenda do loop: a borda não pode clicar.
        assert(math.abs(data:getSample(n - 1) - data:getSample(0)) < .08,
            'Loop de ambiência descontínuo: ' .. id)
        data:release()
    end
    -- Resolução mapa → realm → colina: interior sem builder próprio herda
    -- o realm; id conhecido vence o realm; desconhecido cai na colina;
    -- nil desliga (fade out).
    assert(resolveAmbience('capela', 'refugio') == 'refugio',
        'capela tinha que resolver na ambiência do refúgio')
    assert(resolveAmbience('andlar', 'andlar') == 'andlar',
        'andlar tinha que resolver na ambiência de andlar')
    assert(resolveAmbience('colina', 'refugio') == 'colina',
        'id com builder próprio vence o realm')
    assert(resolveAmbience('x', nil) == 'colina',
        'id desconhecido sem realm cai na colina')
    assert(resolveAmbience(nil) == nil, 'sem id a ambiência desliga')
    -- Volumes por canal: todo canal listado tem rótulo e nível; roundtrip,
    -- clamp nas duas pontas, canal desconhecido devolve nil e um canal
    -- zerado não contamina os vizinhos.
    for _, ch in ipairs(Sfx.channels) do
        assert(Sfx.CHANNEL_LABELS[ch] and Sfx.volumes[ch] ~= nil,
            'Canal sem rótulo ou nível: ' .. ch)
    end
    Sfx.setVolume('ui', .7)
    assert(Sfx.getVolume('ui') == .7, 'set/getVolume não fecharam roundtrip')
    Sfx.setVolume('ui', 9)
    assert(Sfx.getVolume('ui') == 1, 'setVolume tem que clampar em 1')
    Sfx.setVolume('ui', -2)
    assert(Sfx.getVolume('ui') == 0, 'setVolume tem que clampar em 0')
    assert(Sfx.getVolume('canal_que_nao_existe') == nil,
        'Canal desconhecido tem que devolver nil')
    Sfx.setVolume('canal_que_nao_existe', .5)   -- no-op, não pode quebrar
    Sfx.setVolume('ui', 1); Sfx.setVolume('world', 0)
    assert(Sfx.getVolume('world') == 0 and Sfx.getVolume('ui') == 1,
        'Volume de um canal não pode contaminar outro')
    Sfx.setVolume('world', 1)
    if not Sfx.disabled then
        local wasMuted = Sfx.muted
        Sfx.time = Sfx.time + 1   -- passa o gap de eventuais plays anteriores
        playLog.ui_move = {}
        local before = Sfx.stats.count.ui_move or 0
        Sfx.play('ui_move'); Sfx.play('ui_move')
        assert(Sfx.stats.count.ui_move == before + 1, 'Gap mínimo por cue não segurou')
        Sfx.setMuted(true)
        Sfx.play('ui_move')
        assert(Sfx.stats.count.ui_move == before + 1, 'Mudo não pode contar play')
        Sfx.setMuted(wasMuted)
    end
    Sfx.setAmbience(nil)   -- não deixa loop residual ligado após o check
    return true
end

return Sfx
