-- DORO — idle OESTE = espelho do leste (helper de código).

local src = require('src.sprites.npc_doro_e')

local function mirrorGrid(g)
    if type(g) == 'string' then
        return (g:gsub('[^\n]+', function(l) return l:reverse() end))
    end
    local t = {}
    for i, s in ipairs(g) do t[i] = mirrorGrid(s) end
    return t
end

local def = {
    name = 'npc_doro_w',
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
