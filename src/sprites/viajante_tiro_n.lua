-- O VIAJANTE — TIRO NORTE (disparo de costas), 64x96, origem nos pés,
-- 4 frames. Base: AK.compose(viajante_n,'albedo',1); arco vertical e punhos
-- antigos saem por seleção de cor+retângulo, casaco/correia reparados, poses
-- de tiro desenhadas por cima.
--   f1 PREP    : arco horizontal alto sobre os ombros (~y43-47), corda slack;
--                mão esquerda ainda na coxa.
--   f2 DRAW    : corda 't' puxada ao nock (34,40) atrás do pescoço; flecha
--                'a'/'f' curta apontando para cima (mirando o norte).
--   f3 CONTACT : corda reta entre as pontas, flecha saiu.
--   f4 RECOVER : conjunto +2px, mão da corda descendo ao ombro.
-- Metadados W4 (kit_w4/workbench): anchors, markers, sequences,
-- frameDuration, regions — âncoras sempre sobre pixel sólido do frame.

local K = require('src.pixel_kit')
local AK = require('src.actor_kit')
local base = require('src.sprites.viajante_n')

local idle = AK.compose(base, 'albedo', 1)

--------------------------------------------------------------------------------
-- helpers locais
--------------------------------------------------------------------------------
local function selCores(g, cores)
    local m
    for _, c in ipairs(cores) do
        local s = K.sel_color(g, c)
        m = m and K.mask_or(m, s) or s
    end
    return m
end

local function apaga(g, mask)
    K.paint(g, function() return '.' end, mask)
end

local function punho(g, x, y)
    K.patch(g, { rows = {
        { x = x, y = y,     text = 'kssssk' },
        { x = x, y = y + 1, text = 'kssssk' },
        { x = x, y = y + 2, text = 'kssssk' },
        { x = x, y = y + 3, text = 'kddsdk' },
        { x = x, y = y + 4, text = 'kkkkk' },
    } })
end

-- arco vertical do idle norte: cores w/W/t dentro do retângulo x43-54
local bowMask = K.mask_and(K.sel_rect(idle, 43, 4, 12, 80),
    selCores(idle, { 'w', 'W', 't' }))

--------------------------------------------------------------------------------
-- reparos: casaco onde a corda/punho saíram + correia 'r' refeita
--------------------------------------------------------------------------------
local function repairCostas(g)
    K.patch(g, { rows = {
        -- coluna da corda 't' sobre a borda do casaco (x44)
        { x = 44, y = 45, text = 'c' }, { x = 44, y = 46, text = 'c' },
        { x = 44, y = 47, text = 'c' }, { x = 44, y = 48, text = 'c' },
        { x = 44, y = 49, text = 'c' }, { x = 44, y = 50, text = 'c' },
        { x = 44, y = 51, text = 'c' },
        { x = 44, y = 52, text = 'C' }, { x = 44, y = 53, text = 'C' },
        { x = 44, y = 54, text = 'C' }, { x = 44, y = 55, text = 'C' },
        { x = 44, y = 56, text = 'C' },
        -- borda 'k' do casaco comida pelo punho antigo (x46)
        { x = 46, y = 49, text = 'k' }, { x = 46, y = 50, text = 'k' },
        { x = 46, y = 51, text = 'k' },
    } })
    -- correia 'r' diagonal: no mapa, fileira r ocupa x = r-10 .. r-8;
    -- repinta só o trecho que estava sob arco/punho (r52-60)
    for r = 52, 60 do
        for x = r - 10, r - 8 do K.pixel(g, x, r, 'r') end
    end
end

-- base comum: arco vertical + punho do grip fora; punho da coxa esquerda
-- sai só quando a mão da corda sobe (f2-4)
local function baseTiro(mantemPunhoEsq)
    local g = K.clone(idle)
    apaga(g, bowMask)
    K.rect(g, 46, 49, 8, 8, '.')             -- punho do grip antigo
    if not mantemPunhoEsq then
        K.rect(g, 17, 56, 7, 5, '.')         -- punho da coxa esquerda
        K.patch(g, { rows = {
            { x = 20, y = 56, text = 'kCCC' },  -- borda do casaco refeita
            { x = 21, y = 57, text = 'kcc' },
            { x = 21, y = 58, text = 'kcc' },
            { x = 21, y = 59, text = 'kcc' },
            { x = 21, y = 60, text = 'kcc' },
        } })
    end
    repairCostas(g)
    return g
end

--------------------------------------------------------------------------------
-- conjunto do tiro horizontal alto: manga direita ao grip, membros 'w',
-- punho do arco, acento jade, corda (puxada ao nock ou reta), flecha p/ cima,
-- punho da corda + manga esquerda. dy desloca o conjunto; df = punho da
-- corda; mg = fileiras da manga esquerda (acompanha df).
--------------------------------------------------------------------------------
local function corpoTiro(g, dy, drawn, df, mg)
    -- manga direita (braço do arco) do ombro direito à empunhadura
    K.patch(g, { rows = {
        { x = 38, y = 44 + dy, text = 'ccccccc' },
        { x = 37, y = 45 + dy, text = 'ccccccc' },
        { x = 37, y = 46 + dy, text = 'cccccc' },
        { x = 37, y = 47 + dy, text = 'ccccc' },
    } })
    -- membros 'w' (barriga p/ baixo = p/ o arqueiro)
    K.qcurve(g, 34, 47 + dy, 29, 50 + dy, 26, 44 + dy, 'w')
    K.qcurve(g, 36, 47 + dy, 42, 50 + dy, 44, 44 + dy, 'w')
    K.patch(g, { pixels = { { 31, 47 + dy, 'W' }, { 38, 47 + dy, 'W' } } })
    punho(g, 32, 45 + dy)                    -- mão do arco no grip
    K.pixel(g, 34, 50 + dy, 'j')             -- acento jade sob o grip
    if drawn then
        K.line(g, 26, 44 + dy, 34, 40 + dy, 't')
        K.line(g, 44, 44 + dy, 34, 40 + dy, 't')
        -- flecha curta para cima: haste 'a' + ponta 'f'
        K.patch(g, { pixels = {
            { 34, 37 + dy, 'a' }, { 34, 36 + dy, 'a' },
            { 34, 35 + dy, 'f' },
        } })
    else
        K.line(g, 26, 44 + dy, 44, 44 + dy, 't')
    end
    if df then
        punho(g, df[1], df[2])               -- mão da corda no nock
        K.patch(g, { rows = mg })            -- manga esquerda subindo
    end
end

--------------------------------------------------------------------------------
-- frames
--------------------------------------------------------------------------------
local function frame1()
    local g = baseTiro(true)                 -- punho da coxa fica (prep)
    corpoTiro(g, 0, false, nil, nil)         -- arco alto, corda slack
    return g
end

local function frame2()
    local g = baseTiro(false)
    corpoTiro(g, 0, true, { 32, 39 }, {
        { x = 26, y = 42, text = 'cccccc' },
        { x = 25, y = 43, text = 'cccccc' },
        { x = 24, y = 44, text = 'cccccc' },
    })
    return g
end

local function frame3()
    local g = baseTiro(false)
    corpoTiro(g, 0, false, { 32, 39 }, {
        { x = 26, y = 42, text = 'cccccc' },
        { x = 25, y = 43, text = 'cccccc' },
        { x = 24, y = 44, text = 'cccccc' },
    })
    return g
end

local function frame4()
    local g = baseTiro(false)
    corpoTiro(g, 2, false, { 35, 41 }, {
        { x = 29, y = 43, text = 'cccccc' },
        { x = 28, y = 44, text = 'cccccc' },
        { x = 27, y = 45, text = 'cccccc' },
    })
    return g
end

local F = { frame1(), frame2(), frame3(), frame4() }

-- emissivo = jade 'j' onde houver albedo 'j'
local function emissivo(g)
    local e = K.new(g.w, g.h)
    for y = 1, g.h do for x = 1, g.w do
        if g.rows[y][x] == 'j' then e.rows[y][x] = 'j' end
    end end
    return e
end
local E = {}
for i, g in ipairs(F) do E[i] = emissivo(g) end

local def = {
    name = 'viajante_tiro_n',
    w = 64, h = 96,
    origin = 'feet',
    legend = base.legend,
    layers = { AK.layer('tiro', F, { emissive = E }) },
}

local meta = AK.meta(def, {
    anchors = {
        pe = { 30, 94 },
        cabeca = { 36, 14 },
        mao_arco = { { 34, 47 }, { 34, 47 }, { 34, 47 }, { 34, 49 } },
        mao_corda = { { 20, 58 }, { 34, 41 }, { 34, 41 }, { 37, 43 } },
        ferramenta = { { 26, 44 }, { 34, 35 }, { 26, 44 }, { 26, 46 } },
        emissao = { { 34, 50 }, { 34, 50 }, { 34, 50 }, { 34, 52 } },
    },
    markers = { prep = { 1 }, contact = { 3 }, recover = { 4 }, ['return'] = { 4 } },
    sequences = { tiro = { 1, 4, loop = false } },
    frameDuration = { 0.16, 0.18, 0.07, 0.20 },
    regions = {
        arco = { x = 25, y = 38, w = 20, h = 14 },
        aljava = { x = 26, y = 37, w = 7, h = 34 },
        cabeca_reg = { x = 29, y = 8, w = 16, h = 27 },
        braco = { x = 17, y = 40, w = 22, h = 20 },
    },
})
for k, v in pairs(meta) do def[k] = v end

return def
