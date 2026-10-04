-- BRASEIRO_QUIET — braseiro apagado (W5), 64x96, origem nos pés.
-- Estado de gameplay real: campaign.lua dá 'quiet' ao braseiroMirante
-- antes do rito (stepDone('P01-E03') liga 'lit'). Deriva do def
-- braseiro: mesmo tripé de ferro, mas o leito de brasas 'e'/'o' vira
-- cinza morta 'a' (bone.2 — cinza-violeta fria) e a camada de chama
-- some. Sem emissivo: a luz do mirante apaga junto com a brasa.
-- frameUse='state': escolhido por prop.state, não por tempo nem seed.

local base = require('src.sprites.braseiro')

-- Brasas apagadas: e/o da tigela viram cinza; o resto (ferro, ferrugem,
-- contorno) fica intacto. Os chars e/o só existem no leito de brasas.
local albedo = base.layers[1].albedo:gsub('[eo]', 'a')

local legend = {}
for ch, e in pairs(base.legend) do legend[ch] = e end
legend.a = { ramp = 'bone', step = 2, h = 7 } -- cinza morta de brasa

return {
    name = 'braseiro_quiet',
    w = base.w, h = base.h,
    origin = base.origin,
    frameUse = 'state',
    legend = legend,
    layers = {
        { name = 'base', h = 3, albedo = albedo },
    },
}
