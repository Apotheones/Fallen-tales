-- RUNA (boss_runa_w) — perfil oeste = espelho do leste (mesmo helper de
-- viajante_w): inverte cada linha de grade em todos os canais de todas
-- as camadas; nome e metadados novos para não colidir com o cache por
-- identidade.

local src = require('src.sprites.boss_runa_e')

local function mirrorGrid(g)
    if type(g) == 'string' then
        return (g:gsub('[^\n]+', function(l) return l:reverse() end))
    end
    local t = {}
    for i, s in ipairs(g) do t[i] = mirrorGrid(s) end
    return t
end

local def = {
    name = 'boss_runa_w',
    w = src.w, h = src.h, origin = src.origin,
    legend = src.legend,
    layers = {},
}
for i, l in ipairs(src.layers) do
    local nl = {name = l.name, h = l.h}
    for _, ch in ipairs({ 'albedo', 'height', 'emissive' }) do
        if l[ch] then nl[ch] = mirrorGrid(l[ch]) end
    end
    def.layers[i] = nl
end

return def
