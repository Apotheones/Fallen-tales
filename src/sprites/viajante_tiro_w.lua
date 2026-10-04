-- O VIAJANTE — TIRO OESTE = espelho do tiro leste (K.flip por frame em
-- todos os canais). O viajante olha para a esquerda: o arco passa a ficar
-- à ESQUERDA da tela (à frente do corpo) e a aljava cai em x~38-45 —
-- quadril de TRÁS para quem olha oeste (direita da tela = costas).
--
-- Verificado manualmente em screenshots/w4-viajante_tiro_w_albedo.png:
-- - aljava+flechas no quadril de trás (lado direito da tela) ✓
-- - correia 'rr' sobre o casaco, pingente jade no peito ✓
-- - arco à frente à esquerda; corda em 'V' no f2 atinge o nock ✓
-- - flecha f3 sai pela esquerda (direção do olhar) ✓
-- Não precisou de correção com stamp/patch: não há detalhe assimétrico
-- que o espelho inverta errado — punhos, aljava e pingente ficam todos
-- no lado correto quando mirrados junto com o corpo.
--
-- Âncoras/regiões espelhadas com x' = 65 - x (grade 64 de largura);
-- markers/sequences/frameDuration não mudam.

local K = require('src.pixel_kit')
local AK = require('src.actor_kit')
local E = require('src.sprites.viajante_tiro_e')

local albs = AK.frames(E, 'albedo')
local emis = AK.frames(E, 'emissive')

local lay = AK.layer('tiro', {
    K.flip(albs[1], true), K.flip(albs[2], true),
    K.flip(albs[3], true), K.flip(albs[4], true),
}, { emissive = {
    K.flip(emis[1], true), K.flip(emis[2], true),
    K.flip(emis[3], true), K.flip(emis[4], true),
} })

return {
    name = 'viajante_tiro_w',
    w = 64, h = 96,
    origin = 'feet',
    legend = E.legend,
    layers = { lay },

    anchors = {
        pe = { 35, 94 },
        mao_arco = { { 14, 52 }, { 14, 52 }, { 14, 52 }, { 14, 54 } },
        mao_corda = { { 42, 53 }, { 30, 51 }, { 34, 49 }, { 43, 58 } },
        cabeca = { 29, 21 },
        ferramenta = { { 18, 6 }, { 9, 50 }, { 9, 49 }, { 18, 7 } },
        emissao = { 29, 48 },
    },
    markers = { prep = { 1 }, contact = { 3 }, recover = { 4 }, ['return'] = { 4 } },
    sequences = { tiro = { 1, 4, loop = false } },
    frameDuration = { 0.16, 0.18, 0.07, 0.20 },
    regions = {
        aljava = { x = 38, y = 49, w = 8, h = 31 },
        arco = { x = 10, y = 4, w = 12, h = 82 },
        rosto = { x = 25, y = 9, w = 13, h = 22 },
    },
}
