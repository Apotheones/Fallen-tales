-- MADEIRA_ENCOSTADA — tábuas e tronco contra a parede, prop 64x96.
-- Quintal da forja (vida-refugio-props §5): material de obra
-- encostado na diagonal — três tábuas e um tronco apoiados onde
-- couberam, pontas para cima, bases escorando no chão do quintal.
-- Relevo: pontas 9-10, corpo 7-8, bases 6, chão 1-2.

local W, H = 64, 96

local function nova(fill)
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = fill end
        g[y] = r
    end
    return g
end

local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end

local function faixa(g, x0, x1, y, ch)
    for x = x0, x1 do set(g, x, y, ch) end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- tábua na diagonal: centro vai de (xTopo,y0) a (xBase,y1)
local function tabua(g, xTopo, xBase, y0, y1, larg)
    for y = y0, y1 do
        local t = (y - y0) / (y1 - y0)
        local cx = math.floor(xTopo + (xBase - xTopo) * t + 0.5)
        for i = 0, larg - 1 do
            local ch = 'w'
            if i == 0 then ch = 'W'               -- borda da luz
            elseif i == larg - 1 then ch = 'v' end -- borda da sombra
            if h2(cx + i, y, 4) < 7 then ch = 'u' end
            set(g, cx + i, y, ch)
        end
    end
    -- corte da ponta de cima: mais claro
    local t = 0
    local cx = math.floor(xTopo + (xBase - xTopo) * t + 0.5)
    faixa(g, cx, cx + larg - 1, y0, 'U')
end

local function madeira()
    local g = nova('.')
    -- três tábuas apoiadas, inclinações levemente diferentes
    tabua(g, 30, 20, 20, 88, 4)
    tabua(g, 38, 28, 26, 88, 4)
    tabua(g, 45, 37, 32, 88, 3)
    -- um tronco mais grosso na frente, quase vertical
    for y = 40, 88 do
        local t = (y - 40) / 48
        local cx = math.floor(51 + (48 - 51) * t + 0.5)
        for i = 0, 4 do
            local ch = 'u'
            if i == 0 then ch = 'U'
            elseif i == 4 then ch = 'v' end
            set(g, cx + i, y, ch)
        end
    end
    -- corte do tronco: elipse clara com anel
    for y = 38, 41 do
        for x = 51, 55 do
            local dx = (x - 53) / 2.5
            local dy = (y - 39) / 1.5
            if dx * dx + dy * dy <= 1 then
                set(g, x, y, h2(x, y, 2) < 30 and 'u' or 'U')
            end
        end
    end
    set(g, 53, 39, 'w')
    -- bases apoiadas: calço e escorregamento
    faixa(g, 18, 22, 89, 'u'); faixa(g, 18, 23, 90, 'u')
    faixa(g, 26, 30, 89, 'u'); faixa(g, 35, 38, 89, 'u')
    faixa(g, 46, 54, 89, 'u'); faixa(g, 45, 55, 90, 'u')
    return str(g)
end

local function chao()
    local g = nova('.')
    for y = 88, 96 do
        for x = 12, 58 do
            if h2(x, y, 3) < 32 then
                set(g, x, y, h2(x, y, 6) < 45 and 'e' or 'd')
            end
        end
    end
    -- lascas e serragem debaixo das pontas
    set(g, 24, 91, 'U'); set(g, 25, 92, 'v')
    set(g, 40, 92, 'U'); set(g, 33, 93, 'd')
    set(g, 50, 92, 'e'); set(g, 17, 93, 'd')
    return str(g)
end

return {
    name = 'madeira_encostada',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        w = {ramp = 'wood', step = 4, h = 8},   -- tábua
        W = {ramp = 'wood', step = 6, h = 9},   -- borda da luz
        U = {ramp = 'wood', step = 5, h = 9},   -- corte/veio claro
        u = {ramp = 'wood', step = 3, h = 7},   -- tronco/calço
        v = {ramp = 'wood', step = 2, h = 7},   -- sombra
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        { name = 'madeira', h = 8, albedo = madeira() },
        { name = 'chao',    h = 1, albedo = chao() },
    },
}
