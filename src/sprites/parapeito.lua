-- V01_PARAPEITO — mureta/parapeito de pedra do mirante e do adro,
-- re-autoria do zero. Tile 64x64, topleft, 2 frames: f1 trecho são,
-- f2 trecho gasto (capa lascada + remendo na face). Refúgio: a capa é
-- LISA de uso — as faixas 'u' são o polido das mãos que se debruçam;
-- capstones desenhados com junta, líquen 'g' nas quinas norte, face em
-- fiadas com juntas desencontradas. Sol do SO: quina oeste 'B' clara.
-- h: capa 9-10, polido 9, face 7, junta 6, musgo 6, base 4.
local K = require 'src.pixel_kit'

local W, H = 64, 64

local function blob(g, cx, cy, rx, ry, c, rng, mask)
    local pts, n = {}, 7
    for i = 0, n - 1 do
        local a = i / n * math.pi * 2
        local j = 0.72 + rng.float() * 0.5
        pts[#pts + 1] = math.floor(cx + math.cos(a) * rx * j + 0.5)
        pts[#pts + 1] = math.floor(cy + math.sin(a) * ry * j + 0.5)
    end
    K.polygon(g, pts, c, mask)
end

-- Capa (linhas 6-15): topo com capstones grandes, polido de uso 'u',
-- quina 'C' e líquen nas pontas.
local function capa(g, rng, gasto)
    K.rect(g, 1, 6, W, 1, 'C')                  -- fio da quina norte
    K.rect(g, 1, 7, W, 8, 'c')                  -- laje do topo
    K.rect(g, 1, 15, W, 1, 'C')                 -- quina sul (lip)
    K.rect(g, 1, 16, W, 1, 'C')
    -- juntas dos capstones: 3 pedraços de ~21px
    for _, jx in ipairs({ 21, 43 }) do
        K.line(g, jx, 7, jx + rng.int(-1, 1), 14, 'm')
    end
    -- polido de uso: duas faixas moles onde as mãos apoiam
    local nfaix = gasto and 3 or 2
    for _ = 1, nfaix do
        blob(g, rng.int(12, W - 12), rng.int(9, 13),
            rng.int(7, 12), 2, 'u', rng)
    end
    if gasto then
        blob(g, rng.int(16, W - 16), 11, rng.int(9, 13), 3, 'u', rng)
        -- falha na quina norte: pedaço da capa caiu
        local cx = rng.int(30, 44)
        for x = cx, cx + 4 do
            K.pixel(g, x, 6, 'd')
            if x < cx + 4 then K.pixel(g, x, 7, 'd') end
        end
        K.pixel(g, cx + 1, 8, 'd'); K.pixel(g, cx + 2, 8, 'd')
    end
    -- filete de luz na quina oeste (sol do SO)
    for y = 7, 14 do
        if rng.chance(.7) then K.pixel(g, 1, y, 'S')
            if rng.chance(.4) then K.pixel(g, 2, y, 'S') end end
    end
    -- líquen: moitas pequenas nas quinas e juntas
    for _ = 1, rng.int(1, 2) do
        blob(g, rng.pick({ rng.int(4, 10), rng.int(W - 10, W - 4) }),
            rng.int(8, 13), rng.int(2, 4), 1, 'g', rng)
    end
end

-- Face (linhas 17-40): 4 fiadas de 5px com junta corrida 'm' e juntas
-- verticais desencontradas; base (41-44) em sombra 'd'.
local function face(g, rng, gasto)
    local y = 17
    for fiada = 0, 4 do
        -- fiada de 4-5 linhas de pedra + 1 linha de junta
        local alt = (fiada == 4) and 4 or 5
        for r = 0, alt - 1 do
            local yy = y + r
            K.rect(g, 1, yy, W, 1, 'b')
        end
        -- juntas verticais desta fiada (desencontradas por paridade)
        local base = (fiada % 2 == 0) and 8 or 14
        while base < W - 6 do
            for r = 0, alt - 1 do
                K.pixel(g, base, y + r, 'm')
            end
            base = base + rng.int(13, 19)
        end
        -- pedra clara rara 'a' e quina de luz 'B' no topo da fiada
        for _ = 1, rng.int(1, 2) do
            local ax = rng.int(4, W - 12)
            for dx = 0, rng.int(4, 9) do
                for r = 1, alt - 1 do
                    if K.get(g, ax + dx, y + r) == 'b' then
                        K.pixel(g, ax + dx, y + r, 'a')
                    end
                end
            end
        end
        if rng.chance(.6) then
            local bx = rng.int(4, W - 8)
            for dx = 0, rng.int(5, 8) do
                if K.get(g, bx + dx, y) == 'b' then
                    K.pixel(g, bx + dx, y, 'B')
                end
            end
        end
        K.rect(g, 1, y + alt, W, 1, 'm')
        y = y + alt + 1
    end
    -- remendo (só no trecho gasto): um pano de pedras miúdas na face —
    -- "trabalho reconhecível", fiada mais apertada e tom um degrau acima
    if gasto then
        K.rect(g, 38, 24, 16, 8, 'a')
        for r = 26, 30, 2 do K.rect(g, 38, r, 16, 1, 'm') end
        for cx = 40, 52, 5 do K.line(g, cx, 25, cx, 30, 'm') end
        -- trinca descendo da capa até a terceira fiada
        local tx = 46
        for yy = 17, 32 do
            K.pixel(g, tx, yy, 'k')
            if rng.chance(.35) then tx = tx + rng.pick({ -1, 1 }) end
        end
    end
    -- base em sombra + musgo no rodapé
    K.rect(g, 1, 41, W, 4, 'd')
    for _ = 1, rng.int(2, 3) do
        blob(g, rng.int(4, W - 4), 40, rng.int(3, 6), 1, 'g', rng)
    end
end

local function trecho(seed, gasto)
    local rng = K.rng('v01_parapeito', seed)
    local g = K.new(W, H)
    capa(g, rng, gasto)
    face(g, rng, gasto)
    return K.string(g)
end

local legend = {
    C = { ramp = 'stone', step = 6, h = 10 }, -- quina da capa
    c = { ramp = 'stone', step = 4, h = 10 }, -- topo da capa
    u = { ramp = 'stone', step = 6, h = 9 },  -- polido das mãos
    S = { ramp = 'stone', step = 7, h = 10 }, -- filete sol oeste
    b = { ramp = 'stone', step = 4, h = 7 },  -- pedra da face
    a = { ramp = 'stone', step = 5, h = 7 },  -- pedra clara/remendo
    B = { ramp = 'stone', step = 6, h = 7 },  -- topo da fiada, luz
    m = { ramp = 'stone', step = 2, h = 6 },  -- junta
    d = { ramp = 'stone', step = 1, h = 4 },  -- base/falha em sombra
    k = { spec = 'ink', h = 5 },              -- trinca
    g = { ramp = 'moss',  step = 2, h = 6 },  -- líquen/musgo
}

return {
    name = 'parapeito', w = W, h = H, origin = 'topleft',
    frameUse = 'variant',
    legend = legend,
    layers = { {
        name = 'parapeito', h = 7,
        albedo = { trecho(401, false), trecho(409, true) },
    } },
}
