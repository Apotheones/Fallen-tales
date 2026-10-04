-- BIGORNA sobre cepo — prop de chão, 64x96, origem nos pés.
-- Quintal da forja (vida-refugio-props §5): metal escuro de
-- ferramenta com borda de desgaste clara no topo, cepo de madeira
-- grossa. Cinza residual emissiva fraca (ei~0.3) na face — calor
-- preso, não fogo aceso (flag alta acende de verdade).
-- Relevo: face 14, bico 12, cintura 11, pé 10, cepo 6-8, chão 1.

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

-- camada de baixo: cepo de madeira grossa
local function cepo()
    local g = nova('.')
    -- tampa do cepo: elipse clara com anéis, quase toda sob a bigorna
    for y = 56, 61 do
        for x = 17, 48 do
            local dx = (x - 32) / 15
            local dy = (y - 58) / 3
            if dx * dx + dy * dy <= 1 then
                local ch = 'U'
                if h2(x, y, 2) < 25 then ch = 'w' end     -- anel de crescimento
                set(g, x, y, ch)
            end
        end
    end
    -- corpo: casca com veios verticais, lado direito em sombra
    for y = 59, 90 do
        local alarg = y > 84 and 1 or 0
        for x = 18 - alarg, 47 + alarg do
            local ch = 'w'
            if x >= 45 then ch = 'u'
            elseif (x + y) % 7 == 0 then ch = 'v'          -- veio da casca
            elseif h2(x, y, 4) < 8 then ch = 'U' end
            set(g, x, y, ch)
        end
    end
    -- raiz na base
    faixa(g, 16, 49, 91, 'u'); faixa(g, 15, 50, 92, 'u')
    return str(g)
end

-- camada de cima: a bigorna + cinza residual
local function bigorna()
    local g = nova('.')
    -- bico: cone horizontal apontando p/ a esquerda, face em cima
    set(g, 5, 33, 'n'); set(g, 6, 34, 'n')
    faixa(g, 7, 9, 33, 'I'); faixa(g, 7, 11, 34, 'n')
    faixa(g, 7, 12, 35, 'n'); faixa(g, 8, 14, 36, 'n')
    faixa(g, 9, 15, 37, 'i'); faixa(g, 9, 17, 38, 'i')
    faixa(g, 15, 20, 33, 'n'); faixa(g, 15, 20, 34, 'n')
    faixa(g, 15, 20, 35, 'n'); faixa(g, 15, 20, 36, 'n')
    faixa(g, 15, 20, 37, 'n')
    -- face: o topo da bigorna, borda de desgaste clara
    for y = 30, 39 do
        for x = 20, 50 do
            local ch = 'I'
            if y < 32 then ch = 'E'                        -- fio gasto
            elseif x < 22 and y < 36 then ch = 'E'          -- bordo esquerdo
            elseif x > 47 then ch = 'i'                     -- calcanhar, sombra
            elseif y > 37 then ch = 'i' end
            set(g, x, y, ch)
        end
    end
    -- degrau do calcanhar à direita
    faixa(g, 48, 53, 33, 'i'); faixa(g, 48, 54, 34, 'i')
    faixa(g, 48, 53, 35, 'i'); faixa(g, 48, 52, 36, 'i')
    -- cintura: afunila de verdade sob a face
    for y = 39, 48 do
        for x = 27, 41 do
            set(g, x, y, x > 38 and 'i' or 'n')
        end
    end
    -- pé: alarga de volta ao cepo
    for y = 48, 58 do
        for x = 22, 45 do
            local ch = 'n'
            if y < 50 then ch = 'I'
            elseif x > 42 then ch = 'i' end
            set(g, x, y, ch)
        end
    end
    -- cinza residual na face: pontos mornos apagando
    set(g, 30, 34, 'o'); set(g, 34, 33, 'e'); set(g, 37, 35, 'o')
    set(g, 33, 36, 'e'); set(g, 28, 35, 'e'); set(g, 40, 34, 'e')
    set(g, 36, 37, 'o')
    -- marca de martelo: trilha de desgaste na face
    for x = 24, 44 do
        if h2(x, 1, 3) < 30 then set(g, x, 33, 'E') end
    end
    return str(g)
end

-- emissivo: só a cinza residual, fraca (ei .3)
local function cinza_emissiva()
    local g = nova('.')
    set(g, 30, 34, 'o'); set(g, 34, 33, 'e'); set(g, 37, 35, 'o')
    set(g, 33, 36, 'e'); set(g, 28, 35, 'e'); set(g, 40, 34, 'e')
    set(g, 36, 37, 'o')
    return str(g)
end

local function chao()
    local g = nova('.')
    for y = 90, 96 do
        for x = 10, 56 do
            if h2(x, y, 5) < 28 then
                set(g, x, y, h2(x, y, 9) < 45 and 'a' or 'd')
            end
        end
    end
    -- resíduo de forja: limalha e escória junto ao cepo
    set(g, 20, 91, 'r'); set(g, 21, 92, 'r')
    set(g, 50, 91, 'i'); set(g, 52, 92, 'n')
    set(g, 14, 93, 'd'); set(g, 44, 93, 'r')
    return str(g)
end

return {
    name = 'bigorna',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 5},
        -- bigorna: ferro escuro, borda de desgaste clara
        i = {ramp = 'iron', step = 2, h = 11},  -- sombra/bico
        n = {ramp = 'iron', step = 3, h = 11},  -- corpo
        I = {ramp = 'iron', step = 4, h = 13},  -- face
        E = {ramp = 'iron', step = 6, h = 14},  -- fio de desgaste
        -- cinza residual: brasa apagando, emissivo fraco
        e = {ramp = 'ember', step = 2, h = 13, e = 'ember.3', ei = 0.3},
        o = {ramp = 'ember', step = 3, h = 13, e = 'ember.4', ei = 0.3},
        -- cepo de madeira grossa
        w = {ramp = 'wood', step = 4, h = 7},
        W = {ramp = 'wood', step = 6, h = 8},
        U = {ramp = 'wood', step = 5, h = 8},   -- tampa/veio claro
        v = {ramp = 'wood', step = 2, h = 7},
        u = {ramp = 'wood', step = 3, h = 6},
        -- chão do quintal
        a = {ramp = 'earth', step = 3, h = 1},
        d = {ramp = 'earth', step = 2, h = 1},
        r = {ramp = 'rust', step = 3, h = 1},   -- escória
    },

    layers = {
        { name = 'cepo',    h = 7,  albedo = cepo() },
        { name = 'bigorna', h = 11, albedo = bigorna(),
            emissive = cinza_emissiva() },
        { name = 'chao',    h = 1,  albedo = chao() },
    },
}
