-- V07_TRANS_LAJE — overlay de transição LAJE->vizinho, 64x64 topleft,
-- 8 frames = DIREÇÕES (frameUse='direction'), mesmo contrato do
-- piso_terra_borda: f1-4 = arestas N/E/S/W (a laje invade a aresta da
-- célula receptora), f5-8 = cantos NE/NW/SE/SW. Linguagem: banda de
-- laje cedendo — meia-pedras 'S' na orla, cascalho 's' caindo para o
-- vizinho, junta 'j' na emenda. Nunca dispersão uniforme.
local K = require 'src.pixel_kit'

local W, H = 64, 64

-- banda de laje invadindo a célula a partir da aresta 'edge'
-- ('n' topo / 's' base / 'e' dir / 'w' esq), com orla lobada +
-- meia-pedras + cascalho decaindo para dentro
local function aresta(g, edge, rng)
    local function proj(x, y)  -- coordenada na aresta
        if edge == 'n' then return x, y end
        if edge == 's' then return x, H - y + 1 end
        if edge == 'e' then return W - y + 1, x end
        return y, x            -- 'w'
    end
    -- orla: profundidade ~16-26px ondulando
    -- dentes em trechos de 5-9px com passo variável — irregular,
    -- nunca serra-de-dente-uniforme
    local x = 1
    while x <= W do
        local span = rng.int(5, 9)
        local baseDep = 20 + math.floor(4 * math.sin(x * .22 + edge:byte())
            + rng.float() * 6 - 3)
        for xx = x, math.min(W, x + span - 1) do
            local dep = baseDep + rng.int(-1, 1)
            for d = 1, dep do
                local px, py = proj(xx, d)
                K.pixel(g, px, py, 'S')
            end
            local px, py = proj(xx, dep + 1)
            if rng.chance(.6) then K.pixel(g, px, py, 's') end
            if rng.chance(.3) then
                local p2x, p2y = proj(xx, dep + 2)
                K.pixel(g, p2x, p2y, 's')
            end
            if rng.chance(.2) then
                local p3x, p3y = proj(xx, dep + 3)
                K.pixel(g, p3x, p3y, 'j')
            end
        end
        x = x + span
    end
    -- meia-pedras: blocos de 2-3px pendurados na orla
    for _ = 1, rng.int(3, 5) do
        local x = rng.int(4, W - 4)
        local dep = 20 + math.floor(4 * math.sin(x * .22 + edge:byte()))
        local px, py = proj(x, dep + 2 + rng.int(0, 3))
        K.pixel(g, px, py, 'S'); K.pixel(g, px + 1, py, 'S')
        local px2, py2 = proj(x + 1, dep + 3)
        K.pixel(g, px2, py2, 's')
    end
end

local function tile(seed, edges)
    local rng = K.rng('v07_trans_laje', seed)
    local g = K.new(W, H)
    for _, e in ipairs(edges) do aresta(g, e, rng) end
    -- canto: a junção dos lados preenche o vértice
    if #edges == 2 then
        local cx, cy
        if edges[1] == 'n' and edges[2] == 'e' then cx, cy = 56, 4
        elseif edges[1] == 'w' and edges[2] == 'n' then cx, cy = 4, 4
        elseif edges[1] == 'e' and edges[2] == 's' then cx, cy = 56, 56
        else cx, cy = 4, 56 end
        local pts = { cx - 6, cy, cx + 12, cy - 2, cx + 14, cy + 8,
                      cx - 2, cy + 10 }
        K.polygon(g, pts, 'S')
    end
    return K.string(g)
end

local legend = {
    S = { ramp = 'stone', step = 5, h = 1 },  -- laje pálida invadindo
    s = { ramp = 'stone', step = 3, h = 1 },  -- cascalho
    j = { ramp = 'earth', step = 2, h = 0 },  -- junta na emenda
}

-- ordem do consumo: f1 N, f2 E, f3 S, f4 W, f5 NE, f6 NW, f7 SE, f8 SW
local N  = tile(901, { 'n' })
local Ee = tile(907, { 'e' })
local S  = tile(911, { 's' })
local O  = tile(919, { 'w' })
local NE = tile(929, { 'n', 'e' })
local NW = tile(937, { 'w', 'n' })
local SE = tile(941, { 'e', 's' })
local SW = tile(947, { 's', 'w' })

return {
    name = 'trans_laje', w = W, h = H, origin = 'topleft',
    frameUse = 'direction',
    frameMap = { 'n', 'e', 's', 'w', 'ne', 'nw', 'se', 'sw' },
    legend = legend,
    layers = { {
        name = 'trans', h = 1,
        albedo = { N, Ee, S, O, NE, NW, SE, SW },
    } },
}
