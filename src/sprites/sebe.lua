-- V04_SEBE — sebe/moita esquecida da colina, 64x64 topleft, 3f
-- variants. Veredito da Mira: matar a borda serrilhada de speckle —
-- agora MASSAS de folha autoradas: 3-4 lóbulos sobrepostos, cada um
-- com coroa clara 'g'/'G' no topo e SOBRA HUE-SHIFTED 'u' (violet.2)
-- por baixo; galhos 'x' espiando nas junções; raiz 'd' apagada.
-- Leitura fria de crepúsculo: nenhum pixel quente.
local K = require 'src.pixel_kit'

local W, H = 64, 64

local function lobo(g, cx, cy, rx, ry, rng)
    local pts = {}
    for i = 0, 10 do
        local a = i / 11 * math.pi * 2
        local j = 0.78 + rng.float() * .4
        pts[#pts + 1] = math.floor(cx + math.cos(a) * rx * j + .5)
        pts[#pts + 1] = math.floor(cy + math.sin(a) * ry * j + .5)
    end
    K.polygon(g, pts, 'g')
    -- coroa: meia-lua 'G' no terço superior do lóbulo
    local topo = {}
    for i = 0, 5 do
        local a = math.pi + i / 5 * math.pi   -- semicírculo de cima
        topo[#topo + 1] = math.floor(cx + math.cos(a) * rx * .55 + .5)
        topo[#topo + 1] = math.floor(cy + math.sin(a) * ry * .5 + .5)
    end
    K.polygon(g, topo, 'G')
    -- sombra fria violeta sob o lóbulo (hue-shift, não cinza)
    -- fio violeta só na borda de baixo do lóbulo (hue-shift, não mancha)
    for i = 0, 6 do
        local a = i / 6 * math.pi
        local x = math.floor(cx + math.cos(a) * rx * .62 + .5)
        local y = math.floor(cy + math.sin(a) * ry * .58 + .5)
        K.pixel(g, x, y, 'u')
        if i % 2 == 0 then K.pixel(g, x, y + 1, 'u') end
    end
end

local function sebe(seed)
    local rng = K.rng('v04_sebe', seed)
    local g = K.new(W, H)
    -- raiz/sombra de contato
    local rp = {}
    local rpts = { 12, 53, 32, 50, 52, 53, 55, 57, 40, 61, 20, 60 }
    for i = 1, #rpts, 2 do
        rp[#rp + 1] = rpts[i] + rng.int(-2, 2)
        rp[#rp + 1] = rpts[i + 1] + rng.int(-1, 1)
    end
    K.polygon(g, rp, 'd')
    -- galhos estruturais antes das folhas
    K.line(g, 28, 56, 30, 30, 'x')
    K.line(g, 38, 56, 36, 34, 'x')
    K.line(g, 30, 56, 22, 38, 'x')
    -- 3-4 lóbulos de folha sobrepostos, deslocados organicamente
    lobo(g, 30, 30, 14, 11, rng)
    lobo(g, 42, 36, 12, 9, rng)
    lobo(g, 20, 38, 11, 9, rng)
    if rng.chance(.5) then lobo(g, 34, 22, 8, 7, rng) end
    -- folhas destacadas na beirada (clusters autorados, não speckle):
    -- carimbos de 2-3px de 'G' ao longo das bordas externas
    for _ = 1, rng.int(3, 5) do
        local x, y = rng.int(12, 52), rng.int(16, 44)
        if K.get(g, x, y) == '.' then
            K.pixel(g, x, y, 'G'); K.pixel(g, x + 1, y, 'g')
        end
    end
    return K.string(g)
end

local legend = {
    g = { ramp = 'moss', step = 3, h = 4 },    -- massa de folha
    G = { ramp = 'moss', step = 5, h = 5 },    -- coroa iluminada
    u = { ramp = 'violet', step = 2, h = 4 },  -- sombra fria (hue-shift)
    x = { ramp = 'wood', step = 2, h = 3 },    -- galho morto
    d = { ramp = 'earth', step = 1, h = 1 },   -- raiz/contato
}

return {
    name = 'sebe', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'sebe',
        albedo = { sebe(811), sebe(823), sebe(829) },
    } },
}
