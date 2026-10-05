-- GRADE_OPEN — estado 'open' do portão de Runa (W05). O quadro aberto
-- mora como f2 dentro de grade.lua; este def só reexpõe esse frame —
-- mesma fonte, sem desenho duplicado.
local base = require('src.sprites.grade')
local layer = base.layers[1]
return {
    name = 'grade_open', w = base.w, h = base.h, origin = base.origin,
    legend = base.legend,
    layers = { {
        name = layer.name, h = layer.h,
        albedo = { layer.albedo[2] },
        emissive = layer.emissive and { layer.emissive[2] } or nil,
    } },
}
