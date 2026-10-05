-- V05_PANO — tecido funerário do velório, 64x96 origem feet, 2 frames
-- (frameUse='variant'): f1 = pendurado (drapejado numa corda/margem,
--   dobras fundas, faixa violeta de luto na barra), f2 = fardo
--   guardado (rolo amarrado no chão do depósito, pontas de corda).
-- Tecido cru 'j' (cloth.4) com sombra 'J' (cloth.2) nas cavas e faixa
-- de luto 'u'/'U' (violet.3/4) — o violeta é costura, não brilho.
local K = require 'src.pixel_kit'

local function f1()  -- pendurado
    local g = K.new(64, 96)
    -- corda suporte: linha fina no alto + ganchos
    K.line(g, 14, 20, 50, 20, 'f')
    K.pixel(g, 13, 20, 'i'); K.pixel(g, 51, 20, 'i')
    -- pano: retângulo drapeado ~36x52 pendurado, dobras verticais
    for y = 21, 72 do
        for x = 15, 49 do
            -- dobras: colunas alternam tom — cava mais funda a cada 5
            local ch = 'j'
            local fx = (x - 15) % 9
            if fx == 4 or fx == 5 then ch = 'J' end
            if fx == 0 then ch = 'c' end     -- vinco alto claro
            if y > 70 then ch = 'J' end      -- barra em sombra
            K.pixel(g, x, y, ch)
        end
    end
    -- faixa de luto: banda violeta dupla ~10px acima da barra
    for y = 60, 62 do
        for x = 15, 49 do
            local fx = (x - 15) % 9
            K.pixel(g, x, y, (fx == 4 or fx == 5) and 'U' or 'u')
        end
    end
    -- barra: borda comida (o pano é velho) + canto dobrado
    for x = 15, 49 do
        if (x % 6) < 4 then K.pixel(g, x, 72, 'J') else K.pixel(g, x, 72, '.') end
    end
    K.rect(g, 44, 71, 5, 2, 'c')   -- canto dobrado pro lado
    -- dobras dobram sobre a corda no topo
    K.rect(g, 15, 21, 35, 2, 'c')
    for x = 15, 49, 9 do K.pixel(g, x, 23, 'k') end  -- sombra do vinco
    return g
end

local function f2()  -- fardo guardado
    local g = K.new(64, 96)
    -- rolo de pano no chão: massa baixa, espiral de dobras, corda
    K.rect(g, 18, 74, 30, 12, 'j')          -- corpo do fardo
    K.rect(g, 18, 74, 30, 2, 'c')           -- topo iluminado
    K.rect(g, 18, 84, 30, 2, 'J')           -- base sombra
    -- espiral de dobras: linhas verticais curvadas sugerindo rolo
    for x = 20, 46, 4 do
        for y = 75, 84 do
            if (x + y) % 5 < 2 then K.pixel(g, x, y, 'J') end
        end
    end
    -- ponta solta de pano saindo do rolo à direita
    K.polygon(g, { 48, 78, 56, 82, 52, 87, 47, 84 }, 'c')
    K.line(g, 48, 78, 47, 84, 'J')
    -- corda amarrando o rolo (2 laços + nó)
    for y = 72, 87 do K.pixel(g, 30, y, 'f'); K.pixel(g, 40, y, 'f') end
    K.pixel(g, 30, 76, 'i'); K.pixel(g, 40, 76, 'i')
    -- faixa de luto ainda visível dobrada por dentro
    K.rect(g, 19, 76, 4, 1, 'u')
    -- sombra de contato
    for x = 16, 52 do K.pixel(g, x, 88, 'd') end
    return g
end

local legend = {
    j = { ramp = 'cloth', step = 4, h = 6 },   -- tecido cru
    J = { ramp = 'cloth', step = 2, h = 6 },   -- cava das dobras
    c = { ramp = 'cloth', step = 5, h = 7 },   -- vinco alto / topo
    u = { ramp = 'violet', step = 3, h = 6 },  -- faixa de luto
    U = { ramp = 'violet', step = 4, h = 6 },  -- faixa, luz
    f = { ramp = 'bone', step = 4, h = 7 },    -- corda
    i = { ramp = 'iron', step = 3, h = 7 },    -- gancho/nó
    d = { ramp = 'stone', step = 1, h = 1 },   -- contato
    k = { spec = 'ink', h = 6 },               -- sombra de vinco
}

return {
    name = 'pano', w = 64, h = 96, origin = 'feet',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'pano',
        albedo = { K.string(f1()), K.string(f2()) },
    } },
}
