-- O VIAJANTE — INTERAÇÃO SUL (estende a mão a um objeto/alavanca), 64x96,
-- origem nos pés, 3 frames, sequência sem loop (vai e volta ao repouso).
-- Base: AK.compose(viajante,'albedo',1). Arco fica na mão esquerda (idle).
--   f1 REPouso : idle intacto.
--   f2 CONTACT : braço direito estendido à frente/baixo, palma 's' aberta;
--                aba do casaco balança +1px e pingente desloca +1px
--                (movimento secundário).
--   f3 RETURN  : volta ao repouso.
-- Metadados W4 (kit_w4/workbench): anchors, markers, sequences,
-- frameDuration, regions — âncoras sempre sobre pixel sólido do frame.

local K = require('src.pixel_kit')
local AK = require('src.actor_kit')
local base = require('src.sprites.viajante')

local idle = AK.compose(base, 'albedo', 1)

local function selCores(g, cores)
    local m
    for _, c in ipairs(cores) do
        local s = K.sel_color(g, c)
        m = m and K.mask_or(m, s) or s
    end
    return m
end

--------------------------------------------------------------------------------
-- f2: braço estendido + movimento secundário
--------------------------------------------------------------------------------
local function frame2()
    local g = K.clone(idle)

    -- punho da coxa sai (a mão vai à frente); haste da aljava reaparece
    K.rect(g, 48, 56, 7, 8, '.')
    K.patch(g, { pixels = {
        { 55, 57, 'a' }, { 55, 58, 'a' }, { 55, 59, 'a' },
        { 48, 56, 'C' }, { 49, 56, 'C' }, { 50, 56, 'k' },
        { 48, 63, 'k' },
    } })

    -- pingente (cordão 'T' + jade 'j') desloca +1px; peito 'v' reaparece
    local pendMask = K.mask_and(K.sel_rect(idle, 33, 44, 8, 7),
        selCores(idle, { 'T', 'j' }))
    AK.move(g, pendMask, 1, 0)
    K.patch(g, { pixels = {
        { 34, 45, 'v' }, { 35, 46, 'v' }, { 36, 47, 'v' },
        { 35, 48, 'v' }, { 36, 49, 'v' },
    } })

    -- aba direita do casaco balança +1px; calça 'p' reaparece na borda
    local flapMask = K.mask_and(K.sel_rect(idle, 41, 61, 9, 3),
        selCores(idle, { 'x', 'c', 'C', 'n' }))
    AK.move(g, flapMask, 1, 0)
    K.patch(g, { pixels = {
        { 42, 61, 'p' }, { 42, 62, 'p' }, { 42, 63, 'p' },
    } })

    -- braço estendido: manga 'c' do ombro direito à palma 's' aberta
    K.patch(g, { rows = {
        { x = 44, y = 48, text = 'ccccc' },
        { x = 45, y = 49, text = 'ccccc' },
        { x = 45, y = 50, text = 'ccccc' },
        { x = 46, y = 51, text = 'ccccc' },
        { x = 46, y = 52, text = 'ccccc' },
        { x = 47, y = 53, text = 'ccccc' },
        { x = 47, y = 54, text = 'ccccc' },
        { x = 48, y = 55, text = 'ccccc' },
        { x = 48, y = 56, text = 'ccccc' },
        { x = 49, y = 57, text = 'kccck' },
        { x = 50, y = 58, text = 'kssSSk' },
        { x = 50, y = 59, text = 'kssssk' },
        { x = 51, y = 60, text = 'ssssk' },
        { x = 51, y = 61, text = 'ssssk' },
        { x = 51, y = 62, text = 'kkkkk' },
    } })
    return g
end

local F = { K.clone(idle), frame2(), K.clone(idle) }

-- emissivo = jade 'j' onde houver albedo 'j' (acompanha o pingente no f2)
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
    name = 'viajante_interacao',
    w = 64, h = 96,
    origin = 'feet',
    legend = base.legend,
    layers = { AK.layer('interacao', F, { emissive = E }) },
}

local meta = AK.meta(def, {
    anchors = {
        pe = { 30, 94 },
        cabeca = { 36, 14 },
        mao_arco = { 17, 52 },
        mao_corda = { { 52, 58 }, { 53, 60 }, { 52, 58 } },
        ferramenta = { { 55, 58 }, { 55, 60 }, { 55, 58 } },
        emissao = { { 36, 48 }, { 37, 48 }, { 36, 48 } },
    },
    markers = { prep = { 1 }, contact = { 2 }, recover = { 3 }, ['return'] = { 3 } },
    sequences = { interacao = { 1, 3, loop = false } },
    frameDuration = { 0.14, 0.30, 0.14 },
    regions = {
        arco = { x = 14, y = 40, w = 11, h = 36 },
        aljava = { x = 54, y = 52, w = 7, h = 27 },
        rosto = { x = 27, y = 15, w = 17, h = 14 },
        braco = { x = 44, y = 46, w = 13, h = 17 },
    },
})
for k, v in pairs(meta) do def[k] = v end

return def
