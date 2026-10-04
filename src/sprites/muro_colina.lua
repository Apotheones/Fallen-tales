-- MURO_COLINA — mureta/parapeito da Colina dos Sepultados, 64x64,
-- origem topleft. Variante fria: pedra em degraus baixos de valor, capa
-- com sombra violeta por baixo ('j' = junta violeta), musgo apagado na
-- base. 2 frames: trecho reto / canto (o muro desce para o fundo).
-- h: capa 6, face 4-5, junta 3, base/terra 1.

local W, H = 64, 64

local function nova()
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = '.' end
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

local function hash(x, y) return (x * 31 + y * 17) % 11 end

-- Faixa de mureta horizontal: capa clara, sombra violeta sob a capa,
-- face de tijolos com juntas, musgo e terra na base. (x0..x1, ytop).
local function faixa_h(g, x0, x1, ytop, ybase)
    for x = x0, x1 do
        set(g, x, ytop, 'l')
        set(g, x, ytop + 1, 'l')
        set(g, x, ytop + 2, 'j') -- sombra violeta sob a capa
        for y = ytop + 3, ybase do
            local ch = 'a'
            if (y - ytop) % 6 == 3 then ch = 'q' end -- junta horizontal
            if hash(x, y) == 0 then ch = 'd' end     -- tijolo sombreado
            if hash(x + 4, y) == 5 then ch = 'b' end -- tijolo claro
            set(g, x, y, ch)
        end
        -- juntas verticais desencontradas
        for y = ytop + 3, ybase do
            if (y - ytop) % 6 ~= 3
                    and (x + math.floor((y - ytop) / 6) * 5) % 11 == 0 then
                set(g, x, y, 'q')
            end
        end
        -- base: musgo apagado e terra
        if hash(x, ybase + 1) < 6 then set(g, x, ybase + 1, 'G') end
        if hash(x, ybase + 2) < 5 then set(g, x, ybase + 2, 'g') end
        if hash(x, ybase + 3) < 4 then set(g, x, ybase + 3, 'e') end
    end
end

-- Faixa vertical (o canto que desce para o fundo do quadro): capa na
-- aresta de cima e fio claro na quina esquerda.
local function faixa_v(g, x0, x1, ytop, ybase)
    for y = ytop, ybase do
        for x = x0, x1 do
            local ch = 'a'
            if x == x0 then ch = 'l' end           -- quina clara
            if x == x1 then ch = 'd' end           -- lateral sombra
            if (x - x0) % 6 == 3 then ch = 'q' end -- junta vertical
            if hash(x, y) == 0 then ch = 'd' end
            if hash(x + 4, y) == 5 then ch = 'b' end
            set(g, x, y, ch)
        end
    end
    -- topo da faixa vertical: tampa de pedra
    for x = x0, x1 do set(g, x, ytop, 'l'); set(g, x, ytop + 1, 'l') end
    -- base
    for x = x0, x1 do
        if hash(x, ybase + 1) < 6 then set(g, x, ybase + 1, 'G') end
        if hash(x, ybase + 2) < 4 then set(g, x, ybase + 2, 'e') end
    end
end

local function reto()
    local g = nova()
    faixa_h(g, 8, 56, 24, 46)
    return str(g)
end

local function canto()
    local g = nova()
    -- braço horizontal até a quina
    faixa_h(g, 8, 40, 24, 46)
    -- pé do canto: o muro vira e desce para o fundo, um pouco mais largo
    faixa_v(g, 40, 52, 24, 58)
    return str(g)
end

return {
    name = 'muro_colina',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        l = {ramp = 'stone', step = 4, h = 6}, -- capa da mureta
        b = {ramp = 'stone', step = 3, h = 5}, -- tijolo claro
        a = {ramp = 'stone', step = 2, h = 4}, -- face fria
        d = {ramp = 'stone', step = 1, h = 4}, -- tijolo em sombra
        j = {ramp = 'violet', step = 2, h = 5},-- sombra violeta sob a capa
        q = {ramp = 'violet', step = 1, h = 3},-- junta violeta funda
        g = {ramp = 'moss', step = 2, h = 2},  -- musgo na base
        G = {ramp = 'moss', step = 1, h = 2},  -- musgo fundo
        e = {ramp = 'earth', step = 2, h = 1}, -- terra
    },

    layers = {
        {
            name = 'muro',
            h = 4,
            albedo = { reto(), canto() },
        },
    },
}
