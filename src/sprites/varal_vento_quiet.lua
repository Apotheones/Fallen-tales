-- VARAL_VENTO_QUIET — varal sem roupas (W5), 64x96, origem nos pés.
-- Estado de gameplay real: campaign.lua dá 'quiet' ao varalPensao antes
-- da água chegar (flag 'aguaRefugio' liga 'lit'). Deriva do def
-- varal_vento: mourões, corda e chão ficam; a camada de roupas some —
-- varal esperando a primeira lavada. Estático (1 frame): sem pano,
-- não há o que o vento leve.
-- frameUse='state': escolhido por prop.state, não por tempo nem seed.

local base = require('src.sprites.varal_vento')

return {
    name = 'varal_vento_quiet',
    w = base.w, h = base.h,
    origin = base.origin,
    frameUse = 'state',
    legend = base.legend,
    layers = { base.layers[1] }, -- corda/mourões/chão, sem as peças
}
