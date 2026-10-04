-- CISTERNA_RUA — boca de cisterna da rua, prop 64x96, pés.
-- Refúgio (vida-refugio-props §1/§4): o poço secundário — menor que
-- poco.lua: anel de pedra baixo, tampa de tábua meio-aberta sobre a
-- boca, balde deixado ao lado. 2 frames = estado da água por flag:
-- f1 turvo (sea escuro + musgo) / f2 claro (sea claro + fio de luz).
-- Relevo: água 4-5, anel 6-8, tampa 10, balde 5-6, chão 1-2.

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

-- anel + face + tampa; a água fica por conta da camada seguinte
local function corpo(claro)
    local g = nova('.')
    -- borda de trás do anel
    faixa(g, 20, 44, 62, 'S')
    faixa(g, 18, 46, 63, 'S')
    -- face superior do anel: pedras em torno da boca
    for y = 64, 72 do
        for x = 16, 48 do
            local na_boca = x > 21 and x < 44 - math.max(0, (y - 70))
            if na_boca then
                set(g, x, y, 'o')                      -- parede interna
            else
                local ch = 's'
                if h2(x, y, 2) < 14 then ch = 't' end
                set(g, x, y, ch)
            end
        end
    end
    -- boca: afunda antes da água
    faixa(g, 22, 43, 73, 'o'); faixa(g, 23, 42, 74, 'a')
    faixa(g, 23, 41, 75, 'a'); faixa(g, 24, 40, 76, 'a')
    -- frente do anel: fiada baixa e sombra no fundo
    for y = 77, 86 do
        for x = 16, 48 do
            local ch = 's'
            if (y % 5 == 4 or (x + y) % 9 == 0) then ch = 'm' end
            if h2(x, y, 4) < 10 then ch = 't' end
            if y > 84 then ch = 'm' end
            set(g, x, y, ch)
        end
    end
    -- tampa meio-aberta: tábuas puxadas para o fundo-esquerda —
    -- a metade direita da boca segue aberta sobre a água
    for y = 54, 65 do
        for x = 12, 31 do
            local ch = 'w'
            if y == 54 then ch = 'W'
            elseif x == 31 then ch = 'v'
            elseif (x - 12) % 6 == 5 then ch = 'v'
            elseif h2(x, y, 6) < 8 then ch = 'U' end
            set(g, x, y, ch)
        end
    end
    -- a borda da tampa cala a esquerda; à direita a boca segue aberta
    set(g, 12, 55, 'v'); set(g, 12, 64, 'v')
    -- aldrava de ferro na tampa
    set(g, 24, 58, 'i'); set(g, 25, 57, 'i'); set(g, 26, 58, 'i')
    -- musgo no canto de sombra do anel
    set(g, 17, 78, 'g'); set(g, 18, 79, 'G'); set(g, 17, 80, 'G')
    set(g, 45, 81, 'G')
    return str(g)
end

-- água: f1 turva (verde-escura, parada) / f2 clara (sea + luz)
local function agua(claro)
    local g = nova('.')
    if claro then
        for y = 66, 76 do
            for x = 26, 43 do
                local dx = (x - 33) / 9
                local dy = (y - 71) / 5.5
                if dx * dx + dy * dy <= 1 then
                    local ch = 'A'
                    if h2(x, y, 8) < 16 then ch = 'L' end    -- fio de luz
                    set(g, x, y, ch)
                end
            end
        end
        faixa(g, 30, 38, 68, 'L')
    else
        for y = 66, 76 do
            for x = 26, 43 do
                local dx = (x - 33) / 9
                local dy = (y - 71) / 5.5
                if dx * dx + dy * dy <= 1 then
                    local ch = 'z'
                    if h2(x, y, 8) < 20 then ch = 'g' end    -- lodo/musgo
                    set(g, x, y, ch)
                end
            end
        end
        set(g, 33, 70, 'G'); set(g, 38, 71, 'g')
    end
    return str(g)
end

-- balde deixado ao lado + chão
local function chao(claro)
    local g = nova('.')
    -- balde de madeira com cinta, tombado de leve p/ a cisterna
    for y = 78, 90 do
        local afun = y > 86 and 1 or 0
        for x = 52 + afun, 60 - afun do
            local ch = 'u'
            if y == 78 then ch = 'k'                     -- boca escura
            elseif y == 79 or y == 88 then ch = 'i'      -- cintas
            elseif x <= 54 then ch = 'U'
            elseif x >= 59 then ch = 'v' end
            set(g, x, y, ch)
        end
    end
    -- terra ao redor com pegada de quem vem buscar água
    for y = 90, 96 do
        for x = 10, 58 do
            if h2(x, y, 5) < 30 then
                set(g, x, y, h2(x, y, 9) < 45 and 'e' or 'd')
            end
        end
    end
    if claro then
        -- respingo claro na saída do balde
        set(g, 49, 89, 'L'); set(g, 47, 91, 'A')
    else
        set(g, 49, 89, 'd'); set(g, 47, 91, 'e')
    end
    set(g, 20, 90, 'e'); set(g, 38, 91, 'd')
    return str(g)
end

return {
    name = 'cisterna_rua',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 5},              -- boca do balde
        a = {spec = 'abyss', h = 3},            -- fundo da boca
        S = {ramp = 'stone', step = 6, h = 8},  -- borda clara do anel
        s = {ramp = 'stone', step = 4, h = 7},  -- pedra do anel
        t = {ramp = 'stone', step = 5, h = 7},  -- pedra clara
        m = {ramp = 'stone', step = 2, h = 6},  -- junta/sombra
        o = {ramp = 'stone', step = 2, h = 6},  -- parede interna
        w = {ramp = 'wood', step = 4, h = 10},  -- tábua da tampa
        W = {ramp = 'wood', step = 6, h = 10},  -- fio claro da tampa
        U = {ramp = 'wood', step = 5, h = 10},  -- veio da tábua
        v = {ramp = 'wood', step = 2, h = 9},   -- junta/borda da tampa
        i = {ramp = 'iron', step = 4, h = 10},  -- aldrava/cinta
        u = {ramp = 'wood', step = 4, h = 6},   -- corpo do balde
        z = {ramp = 'sea', step = 2, h = 4},    -- água turva
        g = {ramp = 'moss', step = 3, h = 4},   -- lodo na água turva
        G = {ramp = 'moss', step = 2, h = 4},
        A = {ramp = 'sea', step = 4, h = 5},    -- água clara
        L = {ramp = 'sea', step = 6, h = 5},    -- fio de luz na água
        e = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        { name = 'corpo', h = 7, albedo = { corpo(false), corpo(true) } },
        { name = 'agua',  h = 4, albedo = { agua(false), agua(true) } },
        { name = 'chao',  h = 1, albedo = { chao(false), chao(true) } },
    },
}
