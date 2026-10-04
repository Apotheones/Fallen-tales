-- PAREDE_CANTO_D — quina de parede oblíqua à direita, tile 64x96.
-- Espelho horizontal de parede_canto_e: mesmo relevo e legend, grades
-- invertidas linha a linha (todos os caracteres são de um byte).

local base = require('src.sprites.parede_canto_e')

local function espelha(src)
    local out = {}
    for linha in src:gmatch('([^\n]+)') do
        out[#out + 1] = linha:reverse()
    end
    return table.concat(out, '\n')
end

local layers = {}
for i, l in ipairs(base.layers) do
    layers[i] = {
        name = l.name,
        h = l.h,
        albedo = espelha(l.albedo),
    }
end

return {
    name = 'parede_canto_d',
    w = base.w, h = base.h,
    origin = 'topleft',
    legend = base.legend,
    layers = layers,
}
