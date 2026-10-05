-- GRADE — portão de ferro de Runa (W05), 128x96 origem feet (prop
-- w=2). Duas folhas em ombreiras de pedra; f1 FECHADO (trinco cruzado,
-- ferro tocado brilha na aresta de uso), f2 ABERTO (folha direita
-- escancarada em perspectiva + vão escuro atrás). Ferrugem 'r'
-- acumula nas partes paradas; 'L' = ferro claro onde a mão passa.
local K = require 'src.pixel_kit'

local function monta(aberto)
    local g = K.new(128, 96)
    local rng = K.rng('grade', aberto and 137 or 131)

    -- sombra de contato
    for x = 10, 118 do
        K.pixel(g, x, 90, 'd'); if rng.chance(.6) then K.pixel(g, x, 91, 'd') end
    end

    -- ombreiras de pedra + verga corrida
    for y = 18, 88 do
        for x = 10, 15 do
            K.pixel(g, x, y, (y % 7 < 4) and 's' or 'b')
        end
        for x = 112, 117 do
            K.pixel(g, x, y, (y % 7 < 4) and 's' or 'b')
        end
    end
    for y = 18, 88 do
        K.pixel(g, 10, y, 'm'); K.pixel(g, 117, y, 'm')
    end
    K.rect(g, 8, 12, 112, 5, 'S')
    K.rect(g, 8, 17, 112, 2, 's')
    K.pixel(g, 14, 14, 'g'); K.pixel(g, 108, 15, 'g'); K.pixel(g, 109, 15, 'g')

    local function barra(x, ferrugem)
        for y = 22, 86 do K.pixel(g, x, y, 'i') end
        K.pixel(g, x, 21, 'i'); K.pixel(g, x, 20, 'i')
        if ferrugem then
            for y = 66, 86 do
                if rng.chance(.4) then K.pixel(g, x, y, 'r') end
            end
            if rng.chance(.4) then K.pixel(g, x, rng.int(24, 50), 'r') end
        end
    end

    -- FOLHA ESQUERDA: barras de 4px de passo, travessas, batente no
    -- montante central x62-64
    for bx = 20, 60, 5 do barra(bx, true) end
    for y = 40, 41 do for x = 17, 63 do K.pixel(g, x, y, 'I') end end
    for y = 68, 69 do for x = 17, 63 do K.pixel(g, x, y, 'I') end end
    for y = 20, 88 do K.pixel(g, 17, y, 'i'); K.pixel(g, 63, y, 'i') end
    K.rect(g, 15, 40, 3, 3, 'i'); K.rect(g, 15, 68, 3, 3, 'i')

    if aberto then
        -- vão escuro atrás da folha direita escancarada
        K.rect(g, 65, 20, 50, 68, 'o')
        for y = 20, 88 do K.pixel(g, 65, y, 'k'); K.pixel(g, 111, y, 'k') end
        -- folha direita em perspectiva: barras comprimidas a ~2px,
        -- borda de abertura brilhante (ferro usado)
        for _, bx in ipairs({ 70, 74, 78, 82 }) do
            for y = 24, 84 do K.pixel(g, bx, y, 'i') end
            K.pixel(g, bx, 22, 'i'); K.pixel(g, bx, 23, 'i')
        end
        for y = 44, 45 do for x = 69, 84 do K.pixel(g, x, y, 'I') end end
        for y = 70, 71 do for x = 69, 84 do K.pixel(g, x, y, 'I') end end
        for y = 24, 84 do
            if rng.chance(.7) then K.pixel(g, 68, y, 'L') end
        end
        for y = 60, 72 do K.pixel(g, 68, y, 'L') end   -- altura da mão
        -- dobradiças no batente do meio
        K.rect(g, 63, 44, 3, 3, 'i'); K.rect(g, 63, 70, 3, 3, 'i')
        -- trinco pendurado aberto na borda
        K.rect(g, 66, 64, 4, 2, 'i')
        K.pixel(g, 70, 66, 'L')
    else
        -- FECHADO: folha direita cobre o vão, batente comum no meio
        for bx = 68, 110, 5 do barra(bx, true) end
        for y = 40, 41 do for x = 64, 113 do K.pixel(g, x, y, 'I') end end
        for y = 68, 69 do for x = 64, 113 do K.pixel(g, x, y, 'I') end end
        for y = 20, 88 do K.pixel(g, 110, y, 'i') end
        -- trinco de ferro cruzando as duas folhas na altura da mão:
        -- a parte tocada brilha 'L', o resto 'i' com ferrugem nas
        -- pontas paradas
        K.rect(g, 60, 62, 16, 4, 'i')
        for x = 62, 70 do K.pixel(g, x, 62, 'L') end
        K.pixel(g, 71, 63, 'L'); K.pixel(g, 72, 64, 'L')
        -- aresta de uso na junção das folhas (a folha direita é a
        -- que abre — a mão empurra ali)
        for y = 56, 74 do K.pixel(g, 64, y, 'L') end
    end
    return K.string(g)
end

local legend = {
    k = { spec = 'ink', h = 5 },
    o = { spec = 'abyss', h = 2 },
    d = { ramp = 'stone', step = 1, h = 2 },
    s = { ramp = 'stone', step = 3, h = 9 },
    b = { ramp = 'stone', step = 4, h = 9 },
    S = { ramp = 'stone', step = 5, h = 10 },
    m = { ramp = 'stone', step = 2, h = 8 },
    i = { ramp = 'iron', step = 4, h = 8 },
    I = { ramp = 'iron', step = 3, h = 7 },
    L = { ramp = 'iron', step = 6, h = 8 },
    r = { ramp = 'rust', step = 3, h = 7 },
    g = { ramp = 'moss', step = 2, h = 9 },
}

return {
    name = 'grade', w = 128, h = 96, origin = 'feet',
    legend = legend,
    layers = { {
        name = 'grade',
        albedo = { monta(false), monta(true) },   -- f1 fechado, f2 aberto
    } },
}
