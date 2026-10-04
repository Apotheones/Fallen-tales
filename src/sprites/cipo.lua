-- CIPÓ — raízes e vinhas descendo sobre pedra, 64x64, origem topleft.
-- Colina dos Sepultados (docs/DIRECAO_AMBIENTAL_HD.md §COLINA): o cipó
-- é a colina reclamando a obra — cordas de terra escura ('v','V') caem
-- sobre o bloco frio, com folhas raras de musgo apagado. 2 frames =
-- variantes de traçado. h: pedra 3-4, cipó 5 (passa por cima), folha 6.

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

-- Bloco de pedra: caixote frio com capa clara e face em degraus baixos.
local function bloco(g, x0, y0, w, h)
    for y = y0, y0 + h - 1 do
        for x = x0, x0 + w - 1 do
            local ch = 'a'
            if y == y0 then ch = 'l' end            -- capa clara
            if y == y0 + 1 then ch = 'b' end        -- filete sob a capa
            if x == x0 + w - 1 then ch = 'd' end    -- lateral em sombra
            if hash(x, y) == 0 then ch = 'd' end    -- lasca na face
            set(g, x, y, ch)
        end
    end
end

-- Corda de cipó: desce de (x0,1) serpenteando pelo hash até y1 ou
-- encontrar o fundo; folhas 'g' raras nas costas da corda.
local function corda(g, x0, y1)
    local x = x0
    for y = 2, y1 do
        x = x + ((hash(x, y) % 3) - 1) -- serpenteia -1..1
        set(g, x, y, (hash(x, y + 2) < 4) and 'v' or 'V')
        if hash(x + 3, y) == 0 then set(g, x + 1, y, 'g') end
        if hash(x - 2, y) == 1 then set(g, x - 1, y, 'g') end
    end
    return x
end

-- Ponta da corda: engrossa ao chegar na pedra/chão e enrola.
local function ponta(g, x, y)
    set(g, x, y, 'v')
    set(g, x - 1, y, 'v')
    set(g, x, y + 1, 'V')
    set(g, x + 1, y + 1, 'v')
end

local function cipo(var)
    local g = nova()
    -- bloco de pedra: caído na base, já tomado pelo chão
    if var == 1 then
        bloco(g, 10, 34, 26, 20)
        local x1 = corda(g, 16, 60)  ; ponta(g, x1, 60)
        local x2 = corda(g, 24, 52)  ; ponta(g, x2, 52)
        local x3 = corda(g, 33, 44)  ; ponta(g, x3, 44)
        local x4 = corda(g, 42, 58)  ; ponta(g, x4, 58)
        local x5 = corda(g, 51, 40)  ; ponta(g, x5, 40)
        -- terra onde o cipó encontra o chão
        for x = 8, 56 do
            if hash(x, 61) < 5 then set(g, x, 61, 'e') end
            if hash(x, 62) < 4 then set(g, x, 62, 'e') end
        end
    else
        bloco(g, 30, 30, 24, 22)
        local x1 = corda(g, 14, 56)  ; ponta(g, x1, 56)
        local x2 = corda(g, 28, 46)  ; ponta(g, x2, 46)
        local x3 = corda(g, 38, 38)  ; ponta(g, x3, 38)
        local x4 = corda(g, 47, 50)  ; ponta(g, x4, 50)
        -- terra onde o cipó encontra o chão
        for x = 12, 58 do
            if hash(x, 61) < 5 then set(g, x, 61, 'e') end
            if hash(x, 62) < 4 then set(g, x, 62, 'e') end
        end
    end
    return str(g)
end

return {
    name = 'cipo',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        l = {ramp = 'stone', step = 6, h = 4}, -- capa do bloco
        b = {ramp = 'stone', step = 5, h = 4}, -- filete sob a capa
        a = {ramp = 'stone', step = 4, h = 3}, -- face fria
        d = {ramp = 'stone', step = 2, h = 3}, -- sombra / lasca
        v = {ramp = 'earth', step = 2, h = 5}, -- cipó escuro
        V = {ramp = 'earth', step = 3, h = 5}, -- cipó, lado da luz
        g = {ramp = 'moss', step = 2, h = 6},  -- folha rara
        e = {ramp = 'earth', step = 2, h = 1}, -- terra na junção
    },

    layers = {
        {
            name = 'cipo',
            h = 3,
            albedo = { cipo(1), cipo(2) },
        },
    },
}
