-- O VIAJANTE — TIRO LESTE (ação de combate: disparo de arco), 64x96,
-- origin='feet', 4 frames, sequência 'tiro' sem loop (é a ação inteira).
--
-- Rascunho autorado: cada frame nasce do frame 1 do idle_e composto
-- (AK.compose) e é corrigido com move/line/patch. Adaptação da receita:
-- a MÃO DA FRENTE fica na empunhadura em todos os frames (o arco nunca
-- flutua solto — lê melhor em 64px); quem faz o ciclo é a MÃO DE TRÁS:
--   f1 prep    — punho de trás sobe à boca da aljava e apanha a flecha
--                (um tubo 'f/a' a menos na aljava); arco ainda vertical.
--   f2 draw    — corda em 'V' até o nock (36,50), flecha encastelada em
--                y50 apoiada no punho da empunhadura; pontas do arco
--                flexionadas ~2px para trás (arco carregado).
--   f3 contact — corda reta de volta; flecha saindo à frente do arco
--                (y49, ponta em x56); mão da corda largou e veio ao peito.
--   f4 recover — arco+punho da empunhadura descem 2px; mão de trás já no
--                quadril; perto do repouso.
--
-- Emissivo: pingente + acento jade do arco são estáticos nos 4 frames
-- (o acento fica sob o punho em todas as poses — o pixel emissivo sempre
-- tem albedo por baixo). viajante_tiro_w espelha este arquivo.

local K = require('src.pixel_kit')
local AK = require('src.actor_kit')
local IDLE = require('src.sprites.viajante_e')

local base = AK.compose(IDLE, 'albedo', 1)
local emi0 = AK.compose(IDLE, 'emissive', 1)

local function cl() return K.clone(base) end

-- repõe a borda do casaco onde o punho de trás (x20-24, y57-61) saiu
local COAT_FIX = { rows = {
    { x = 22, y = 57, text = 'kcc' },
    { x = 22, y = 58, text = 'kcc' },
    { x = 22, y = 59, text = 'kcc' },
    { x = 22, y = 60, text = 'kcc' },
    { x = 22, y = 61, text = 'kcc' },
} }

--------------------------------------------------------------------------------
-- f1 PREP: punho de trás vai à boca da aljava; uma flecha sai do tubo.
--------------------------------------------------------------------------------
local f1 = cl()
AK.move(f1, K.sel_rect(f1, 20, 57, 5, 5), 1, -6)
K.patch(f1, COAT_FIX)
-- tubo da esquerda esvaziado (as partes visíveis fora do punho)
K.patch(f1, { pixels = {
    { 22, 50, '.' }, { 22, 56, '.' }, { 22, 57, '.' },
} })

--------------------------------------------------------------------------------
-- f2 DRAW: corda puxada em 'V', flecha encastelada, pontas flexionadas.
--------------------------------------------------------------------------------
local f2 = cl()
-- corda reta do idle sai; as linhas novas vão das pontas ao nock
for y = 5, 82 do
    if K.get(f2, 46, y) == 't' then K.pixel(f2, 46, y, '.') end
end
-- punho de trás saiu do quadril; repõe o casaco
K.rect(f2, 20, 57, 5, 5, '.')
K.patch(f2, COAT_FIX)
-- pontas do arco flexionam para trás (máscara por cor: só 'w')
local wcol = K.sel_color(f2, 'w')
AK.move(f2, K.mask_and(K.sel_rect(f2, 45, 5, 10, 10), wcol), -2, 0)
AK.move(f2, K.mask_and(K.sel_rect(f2, 45, 15, 10, 8), wcol), -1, 0)
AK.move(f2, K.mask_and(K.sel_rect(f2, 45, 65, 10, 9), wcol), -1, 0)
AK.move(f2, K.mask_and(K.sel_rect(f2, 45, 74, 10, 9), wcol), -2, 0)
-- corda em 'V' até o nock (vai por baixo do punho da corda)
K.line(f2, 45, 6, 36, 50, 't')
K.line(f2, 45, 81, 36, 50, 't')
-- flecha: haste do punho ao além do arco; pena atrás, ponta à frente
K.line(f2, 34, 50, 55, 50, 'a')
K.pixel(f2, 56, 50, 'f')
K.patch(f2, { pixels = { { 33, 49, 'f' }, { 33, 50, 'f' }, { 33, 51, 'f' } } })
-- punho da corda fechado no nock (cobre o vértice da corda)
K.patch(f2, { rows = {
    { x = 34, y = 50, text = 'kssk' },
    { x = 34, y = 51, text = 'kssk' },
    { x = 34, y = 52, text = 'ksdk' },
    { x = 34, y = 53, text = 'kk' },
} })
-- punho da empunhadura por cima da haste: a flecha apoia na mão do arco
K.patch(f2, { rows = { { x = 49, y = 50, text = 'kssssk' } } })

--------------------------------------------------------------------------------
-- f3 CONTACT: corda reta de volta; flecha já saiu do arco.
--------------------------------------------------------------------------------
local f3 = cl()
K.rect(f3, 20, 57, 5, 5, '.')
K.patch(f3, COAT_FIX)
-- flecha a 1px acima do punho da empunhadura, ponta fora do arco
K.line(f3, 47, 49, 55, 49, 'a')
K.pixel(f3, 56, 49, 'f')
K.patch(f3, { pixels = { { 47, 48, 'f' }, { 47, 50, 'f' } } })
-- mão da corda recolhida ao peito (pós-soltura)
K.patch(f3, { rows = {
    { x = 30, y = 48, text = 'ksk' },
    { x = 30, y = 49, text = 'ksk' },
    { x = 31, y = 50, text = 'kk' },
} })

--------------------------------------------------------------------------------
-- f4 RECOVER: arco + punho da empunhadura descem 2px; quase repouso.
--------------------------------------------------------------------------------
local f4 = cl()
AK.move(f4, K.sel_rect(f4, 45, 4, 12, 82), 0, 2)

--------------------------------------------------------------------------------
-- def
--------------------------------------------------------------------------------
local lay = AK.layer('tiro', { f1, f2, f3, f4 })
lay.emissive = K.string(emi0) -- string única replica nos 4 frames

return {
    name = 'viajante_tiro_e',
    w = 64, h = 96,
    origin = 'feet',
    legend = IDLE.legend,
    layers = { lay },

    anchors = {
        pe = { 30, 94 },
        mao_arco = { { 51, 52 }, { 51, 52 }, { 51, 52 }, { 51, 54 } },
        mao_corda = { { 23, 53 }, { 35, 51 }, { 31, 49 }, { 22, 58 } },
        cabeca = { 36, 21 },
        ferramenta = { { 47, 6 }, { 56, 50 }, { 56, 49 }, { 47, 7 } },
        emissao = { 36, 48 },
    },
    markers = { prep = { 1 }, contact = { 3 }, recover = { 4 }, ['return'] = { 4 } },
    sequences = { tiro = { 1, 4, loop = false } },
    frameDuration = { 0.16, 0.18, 0.07, 0.20 },
    regions = {
        aljava = { x = 20, y = 49, w = 8, h = 31 },
        arco = { x = 44, y = 4, w = 12, h = 82 },
        rosto = { x = 28, y = 9, w = 13, h = 22 },
    },
}
