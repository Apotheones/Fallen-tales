-- O VIAJANTE — TIRO SUL (disparo de frente), 64x96, origem nos pés, 4 frames.
-- Gerado do idle real: AK.compose(viajante,'albedo',1) vira a base; cada
-- frame apaga o arco vertical/punhos antigos por seleção de cor+retângulo,
-- repara o casaco por baixo e desenha a pose de tiro.
--   f1 PREP    : arco erguido ao centro (mesma haste, +6x via AK.move);
--                mão da corda ainda na coxa.
--   f2 DRAW    : arco horizontal no peito (duas qcurve 'w', barriga p/ baixo
--                = p/ a câmera), corda 't' puxada ao nock (33,45) junto ao
--                rosto; flecha 'a'/'f' foreshortened (2-4px + ponta).
--   f3 CONTACT : corda reta entre as pontas, flecha saiu.
--   f4 RECOVER : conjunto do arco +2px, mão da corda voltando ao peito.
-- Metadados W4 (kit_w4/workbench): anchors, markers, sequences,
-- frameDuration, regions — âncoras sempre sobre pixel sólido do frame.

local K = require('src.pixel_kit')
local AK = require('src.actor_kit')
local base = require('src.sprites.viajante')

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

-- punho fechado 'kssssk/kddsdk/kkkkk' (mesma forma do sprite base)
local function punho(g, x, y)
    K.patch(g, { rows = {
        { x = x, y = y,     text = 'kssssk' },
        { x = x, y = y + 1, text = 'kssssk' },
        { x = x, y = y + 2, text = 'kssssk' },
        { x = x, y = y + 3, text = 'kddsdk' },
        { x = x, y = y + 4, text = 'kkkkk' },
    } })
end

-- máscara do arco vertical do idle: só cores w/W/t dentro do retângulo
local bowMask = K.mask_and(K.sel_rect(idle, 13, 4, 12, 80),
    selCores(idle, { 'w', 'W', 't' }))

--------------------------------------------------------------------------------
-- reparo do casaco onde arco/punho saíram (idêntico ao mapa original)
--------------------------------------------------------------------------------
local function repairCasaco(g)
    K.patch(g, { rows = {
        -- coluna da corda 't' sobre o casaco (x23) e borda x23
        { x = 23, y = 39, text = 'k' },
        { x = 23, y = 40, text = 'c' }, { x = 23, y = 41, text = 'c' },
        { x = 23, y = 42, text = 'c' }, { x = 23, y = 43, text = 'c' },
        { x = 23, y = 44, text = 'c' },
        { x = 23, y = 45, text = 'k' }, { x = 23, y = 46, text = 'k' },
        -- manga esquerda 'kccck' + painel frontal 'kccccx' refeitos
        { x = 14, y = 47, text = 'kccck.kccccx' },
        { x = 14, y = 48, text = 'kccck.kccccx' },
        { x = 14, y = 49, text = 'kccck.kccccx' },
        { x = 14, y = 50, text = 'kccck.kccccx' },
        { x = 14, y = 51, text = 'kccck.kccccx' },
        { x = 14, y = 52, text = 'kccck.kccccx' },
        { x = 14, y = 53, text = 'kccck.kccccx' },
        { x = 14, y = 54, text = 'kCCCk..kccccx' },
        { x = 14, y = 55, text = 'kCCCk..kccccx' },
        { x = 14, y = 56, text = 'kCCCk..kccccx' },
        { x = 21, y = 57, text = 'kccccx' },
        { x = 21, y = 58, text = 'kccccx' },
        { x = 21, y = 59, text = 'kccccx' },
        { x = 21, y = 60, text = 'kccccx' },
        { x = 21, y = 61, text = 'kccccx' },
        { x = 21, y = 62, text = 'kccccx' },
        { x = 21, y = 63, text = 'kccccx' },
        { x = 21, y = 64, text = 'kccccx' },
        { x = 21, y = 65, text = 'kccccx' },
        { x = 21, y = 66, text = 'kccccx' },
        { x = 21, y = 67, text = 'kccccx' },
        { x = 21, y = 68, text = 'kccccx' },
        { x = 21, y = 69, text = 'kccccx' },
        { x = 21, y = 70, text = 'kccccx' },
        { x = 21, y = 71, text = 'kccccx' },
        { x = 21, y = 72, text = 'kccccx' },
        { x = 21, y = 73, text = 'kccccx' },
        { x = 21, y = 74, text = 'kccccx' },
        { x = 21, y = 75, text = 'kccccx' },
        { x = 21, y = 76, text = 'kccccx' },
        { x = 21, y = 77, text = 'kCCCCx' },
        { x = 21, y = 78, text = 'kxxxx' },
    } })
end

-- base comum f2-4: arco e punhos antigos fora, casaco e aljava reparados
local function baseTiro()
    local g = K.clone(idle)
    apaga(g, bowMask)                        -- arco vertical fora
    K.rect(g, 14, 49, 8, 8, '.')             -- punho do grip antigo
    K.rect(g, 48, 56, 7, 8, '.')             -- punho da coxa (mão subiu)
    K.patch(g, { pixels = {
        { 55, 57, 'a' }, { 55, 58, 'a' }, { 55, 59, 'a' }, -- haste aljava
        { 48, 56, 'C' }, { 49, 56, 'C' }, { 50, 56, 'k' }, -- barra casaco
        { 48, 63, 'k' },
    } })
    repairCasaco(g)
    return g
end

--------------------------------------------------------------------------------
-- conjunto do tiro horizontal: manga do arco, membros 'w', punho do grip,
-- corda (puxada ou reta), flecha, mão da corda + manga direita.
-- dy desloca o conjunto (recover). df = {x,y} do punho da corda.
--------------------------------------------------------------------------------
local function corpoTiro(g, dy, drawn, df)
    -- manga esquerda (braço do arco) do ombro à empunhadura
    K.patch(g, { rows = {
        { x = 25, y = 49 + dy, text = 'kccccck' },
        { x = 25, y = 50 + dy, text = 'kccccck' },
        { x = 26, y = 51 + dy, text = 'kcccck' },
        { x = 26, y = 52 + dy, text = 'kccck' },
    } })
    -- membros do arco: duas qcurve 'w' com barriga p/ baixo (p/ a câmera)
    K.qcurve(g, 32, 54 + dy, 27, 56 + dy, 24, 47 + dy, 'w')
    K.qcurve(g, 35, 54 + dy, 40, 56 + dy, 43, 47 + dy, 'w')
    -- enrolado claro do grip flanqueando o punho
    K.patch(g, { pixels = { { 30, 52 + dy, 'W' }, { 37, 52 + dy, 'W' } } })
    punho(g, 31, 50 + dy)                    -- mão do arco no grip
    if drawn then
        -- corda 't' puxada ao nock junto ao rosto/peito
        K.line(g, 24, 47 + dy, 33, 45 + dy, 't')
        K.line(g, 43, 47 + dy, 33, 45 + dy, 't')
        -- flecha foreshortened: nock no punho + haste 'a' + ponta 'f'
        K.patch(g, { pixels = {
            { 33, 46 + dy, 'f' }, { 33, 47 + dy, 'a' },
            { 33, 48 + dy, 'a' }, { 33, 49 + dy, 'f' },
        } })
    else
        -- corda reta entre as pontas (pós-disparo / slack)
        K.line(g, 24, 47 + dy, 43, 47 + dy, 't')
    end
    if df then
        punho(g, df[1], df[2])               -- mão da corda
        -- manga direita (braço da corda) do ombro ao punho
        K.patch(g, { rows = {
            { x = df[1] + 5, y = df[2] + 2, text = 'ccccccccc' },
            { x = df[1] + 6, y = df[2] + 3, text = 'cccccccc' },
            { x = df[1] + 7, y = df[2] + 4, text = 'cccccccc' },
            { x = df[1] + 5, y = df[2] + 5, text = 'xxxxxxxxx' },
        } })
    end
end

--------------------------------------------------------------------------------
-- frames
--------------------------------------------------------------------------------
local function frame1()
    local g = K.clone(idle)
    AK.move(g, bowMask, 6, 0)                -- arco erguido ao centro
    K.rect(g, 14, 49, 8, 8, '.')             -- punho antigo fora
    repairCasaco(g)
    punho(g, 19, 50)                         -- punho no grip (WW em x22-23)
    K.pixel(g, 19, 52, 'c')                  -- emenda manga->punho
    return g
end

local function frame2()
    local g = baseTiro()
    corpoTiro(g, 0, true, { 31, 42 })        -- draw: corda ao rosto
    return g
end

local function frame3()
    local g = baseTiro()
    corpoTiro(g, 0, false, { 31, 42 })       -- contact: corda solta
    return g
end

local function frame4()
    local g = baseTiro()
    corpoTiro(g, 2, false, { 35, 45 })       -- recover: arco baixando
    return g
end

local F = { frame1(), frame2(), frame3(), frame4() }

-- emissivo = jade 'j' onde houver albedo 'j' (nunca flutua)
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
    name = 'viajante_tiro_s',
    w = 64, h = 96,
    origin = 'feet',
    legend = base.legend,
    layers = { AK.layer('tiro', F, { emissive = E }) },
}

local meta = AK.meta(def, {
    anchors = {
        pe = { 30, 94 },
        cabeca = { 36, 14 },
        mao_arco = { { 21, 52 }, { 33, 51 }, { 33, 51 }, { 33, 53 } },
        mao_corda = { { 52, 58 }, { 33, 44 }, { 33, 44 }, { 36, 46 } },
        ferramenta = { { 28, 5 }, { 24, 47 }, { 24, 47 }, { 24, 49 } },
        emissao = { { 36, 48 }, { 36, 48 }, { 36, 48 }, { 36, 48 } },
    },
    markers = { prep = { 1 }, contact = { 3 }, recover = { 4 }, ['return'] = { 4 } },
    sequences = { tiro = { 1, 4, loop = false } },
    frameDuration = { 0.16, 0.18, 0.07, 0.20 },
    regions = {
        arco = { x = 24, y = 44, w = 20, h = 13 },
        aljava = { x = 54, y = 52, w = 7, h = 27 },
        rosto = { x = 27, y = 15, w = 17, h = 14 },
        braco_corda = { x = 44, y = 44, w = 12, h = 20 },
    },
})
for k, v in pairs(meta) do def[k] = v end

return def
