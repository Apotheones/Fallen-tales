-- PORTAO_ADRO — portão baixo entre mourões, tile 64x64, topleft.
-- Adro da capela (vida-refugio-props §6): entrada contida — dois
-- mourões de pedra e um portão baixo de tábuas com travessa em
-- escora, dobradiças de ferro. Mais baixo que a mureta: quem entra
-- abaixa a mão e a voz. h: chão 1, portão 6-7, mourão 8-10.

local W, H = 64, 64

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

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

local function portao()
    local g = nova('.')
    -- mourões de pedra: cap claro, face em fiadas miúdas, base
    for _, px in ipairs({ 5, 51 }) do
        for y = 16, 56 do
            for x = px, px + 8 do
                local ch
                if y < 18 then ch = 'C'
                elseif y < 21 then ch = 'S'
                elseif y > 53 then ch = 'd'
                else
                    ch = ((y % 6 == 3 or (x + math.floor(y / 6) * 3) % 8 == 0) and 'm')
                        or (h2(x, y, 2) < 10 and 'a' or 's')
                end
                set(g, x, y, ch)
            end
        end
        -- musgo no tornozelo do mourão
        set(g, px + 1, 57, 'G'); set(g, px + 2, 56, 'g')
        set(g, px + 6, 57, 'G')
    end
    -- portão: tábuas verticais de topo irregular + travessa e escora
    for x = 16, 48 do
        local topo = 30 + ((x * 7) % 4)
        for y = topo, 52 do
            local ch = 'w'
            if (x - 16) % 6 == 5 then ch = 'v' end        -- junta da tábua
            if y == topo then ch = 'W' end               -- fio de luz
            set(g, x, y, ch)
        end
    end
    -- travessas por cima das tábuas
    for x = 17, 47 do
        set(g, x, 36, 'u'); set(g, x, 37, 'v')
        set(g, x, 47, 'u'); set(g, x, 48, 'v')
    end
    -- escora diagonal: da travessa de baixo-esquerda à de cima-direita
    for i = 0, 30 do
        local x = 17 + i
        local y = math.floor(47 - i * 0.35 + 0.5)
        set(g, x, y, 'u'); set(g, x, y - 1, 'v')
    end
    -- dobradiças no mourão esquerdo e argola da mão
    set(g, 15, 36, 'i'); set(g, 15, 37, 'i')
    set(g, 15, 47, 'i'); set(g, 15, 48, 'i')
    set(g, 44, 41, 'I'); set(g, 44, 42, 'i')
    -- chão: caminho que passa pelo portão
    for x = 14, 50 do
        set(g, x, 55, 'e'); set(g, x, 56, 'e')
        if h2(x, 7, 1) < 30 then set(g, x, 54, 'E') end
    end
    set(g, 30, 54, 'e'); set(g, 33, 54, 'e')
    return str(g)
end

return {
    name = 'portao_adro',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        C = {ramp = 'stone', step = 7, h = 10}, -- cap do mourão
        S = {ramp = 'stone', step = 6, h = 10},
        s = {ramp = 'stone', step = 4, h = 8},  -- pedra do mourão
        a = {ramp = 'stone', step = 5, h = 8},  -- pedra clara
        m = {ramp = 'stone', step = 2, h = 7},  -- junta
        d = {ramp = 'stone', step = 3, h = 6},  -- base do mourão
        w = {ramp = 'wood', step = 4, h = 7},   -- tábua do portão
        W = {ramp = 'wood', step = 6, h = 7},   -- topo da tábua
        v = {ramp = 'wood', step = 2, h = 7},   -- junta/sombra
        u = {ramp = 'wood', step = 3, h = 8},   -- travessa/escora
        i = {ramp = 'iron', step = 3, h = 8},   -- dobradiça
        I = {ramp = 'iron', step = 5, h = 8},   -- argola
        g = {ramp = 'moss', step = 3, h = 3},
        G = {ramp = 'moss', step = 2, h = 2},
        e = {ramp = 'earth', step = 4, h = 1},  -- caminho
        E = {ramp = 'earth', step = 3, h = 0},  -- desgaste do caminho
    },

    layers = {
        {
            name = 'portao',
            h = 7,
            albedo = portao(),
        },
    },
}
