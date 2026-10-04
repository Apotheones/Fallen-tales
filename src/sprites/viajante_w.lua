-- O VIAJANTE — idle OESTE = espelho do leste (helper de código).
-- Inverte cada linha de grade em todos os canais de todas as camadas;
-- nome e metadados novos para não colidir com o cache por identidade.

local src = require('src.sprites.viajante_e')

local function mirrorGrid(g)
    if type(g) == 'string' then
        return (g:gsub('[^\n]+', function(l) return l:reverse() end))
    end
    local t = {}
    for i, s in ipairs(g) do t[i] = mirrorGrid(s) end
    return t
end

local def = {
    name = 'viajante_w',
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

-- Metadados W4: markers/sequences/duração não mudam no espelho; âncoras e
-- regiões espelham x -> 65-x (célula x da grade 64 vira 65-x). Atenção:
-- handedness NÃO é verificada automaticamente — o espelho é correto aqui
-- porque a aljava fica no quadril de TRÁS (simetria preservada), mas
-- detalhes assimétricos exigem revisão manual a cada mudança.
def.markers = src.markers
def.sequences = src.sequences
def.frameDuration = src.frameDuration
if src.anchors then
    def.anchors = {}
    for k, a in pairs(src.anchors) do
        if type(a[1]) == 'number' then
            def.anchors[k] = {65 - a[1], a[2]}
        else
            local t = {}
            for i, p in ipairs(a) do t[i] = {65 - p[1], p[2]} end
            def.anchors[k] = t
        end
    end
end
if src.regions then
    def.regions = {}
    for k, r in pairs(src.regions) do
        def.regions[k] = {x = 66 - r.x - r.w, y = r.y, w = r.w, h = r.h}
    end
end
if src.masks then
    def.masks = {}
    for k, m in pairs(src.masks) do def.masks[k] = mirrorGrid(m) end
end

return def
