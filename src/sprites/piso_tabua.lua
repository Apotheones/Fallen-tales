-- PISO_TABUA — tábuas de madeira envelhecida, tile 64x64, topleft.
-- Fase 2 INTERIORES (nota vida-refugio-props §7-11). 4 frames = 4
-- variantes por seed: tábuas horizontais com juntas de topo, topo de
-- tábua deslocado por fileira, nós e desgaste no caminho de passagem.
-- Valor baixo e contraste calmo — o piso recua (regions.hub.floor é a
-- referência de tom). h: junta 0, tábua 1, fio de desgaste 2.

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

local function carimbo(g, x, y, forma)
    for j = 1, #forma do
        local linha = forma[j]
        for i = 1, #linha do
            local c = linha:sub(i, i)
            if c ~= '.' then set(g, x + i - 1, y + j - 1, c) end
        end
    end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

-- Nó de tábua: anel escuro com miolo fundo.
local NOZ  = { '.nn.', 'nddn', '.nn.' }
local NOZ2 = { 'nn', 'nd' }
-- Veio curto dentro da tábua (tom irmão, não junta).
local VEIO = { 'vv' }
local VEIO2 = { '.vv' }

-- Tábuas horizontais: fileiras de 8 px, junta 'j' na linha de base de
-- cada fileira (y = 8, 16, ... 64 — a junta da borda inferior veda com
-- o topo da próxima tile). Topo de tábua (junta vertical) varia por
-- fileira: pontas nunca alinham duas fileiras seguidas.
local function tabua(spec)
    local g = nova('a')
    -- tom por fileira (1..8): default 'a', spec.tons sobrepõe
    for fi, ch in pairs(spec.tons or {}) do
        for y = (fi - 1) * 8 + 1, fi * 8 - 1 do
            for x = 1, W do g[y][x] = ch end
        end
    end
    -- juntas horizontais + topo de tábua por fileira
    for fi = 1, 8 do
        local yb = fi * 8
        for x = 1, W do set(g, x, yb, 'j') end
        local topo = spec.topos[fi] or {}
        for _, x in ipairs(topo) do
            for y = (fi - 1) * 8 + 1, fi * 8 - 1 do set(g, x, y, 'j') end
        end
    end
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    -- desgaste do caminho: fios claros na banda de passagem
    for _, d in ipairs(spec.desgaste) do
        local x, y, n = d[1], d[2], d[3]
        for i = 0, n - 1 do set(g, x + i, y, 's') end
    end
    return str(g)
end

local V1 = {
    tons = { [3] = 'l', [6] = 'v' },
    topos = {
        [1] = { 22, 50 }, [2] = { 10, 38 }, [3] = { 30, 58 },
        [4] = { 16, 44 }, [5] = { 6, 34, 60 }, [6] = { 26, 52 },
        [7] = { 14, 46 }, [8] = { 36, 62 },
    },
    carimbos = {
        { 44, 10, NOZ }, { 12, 42, NOZ }, { 50, 58, NOZ2 },
        { 8, 18, VEIO }, { 33, 26, VEIO2 }, { 24, 50, VEIO },
        { 55, 34, VEIO2 },
    },
    desgaste = {
        { 10, 27, 5 }, { 20, 28, 6 }, { 34, 26, 4 }, { 46, 29, 5 },
        { 14, 35, 4 }, { 30, 36, 6 }, { 44, 35, 4 },
    },
}

local V2 = {
    tons = { [2] = 'v', [5] = 'l' },
    topos = {
        [1] = { 14, 42 }, [2] = { 28, 56 }, [3] = { 8, 34, 62 },
        [4] = { 20, 48 }, [5] = { 12, 40 }, [6] = { 30, 54 },
        [7] = { 22, 50 }, [8] = { 16, 44 },
    },
    carimbos = {
        { 26, 2, NOZ2 }, { 52, 26, NOZ }, { 20, 50, NOZ },
        { 40, 12, VEIO2 }, { 10, 30, VEIO }, { 46, 44, VEIO2 },
    },
    desgaste = {
        { 8, 19, 4 }, { 18, 20, 6 }, { 32, 18, 5 }, { 48, 21, 4 },
        { 24, 43, 5 }, { 38, 44, 6 }, { 52, 42, 4 },
    },
}

local V3 = {
    tons = { [4] = 'l', [7] = 'v' },
    topos = {
        [1] = { 30, 54 }, [2] = { 18, 46 }, [3] = { 36, 60 },
        [4] = { 10, 26, 50 }, [5] = { 22, 58 }, [6] = { 14, 42 },
        [7] = { 34, 56 }, [8] = { 24, 48 },
    },
    carimbos = {
        { 46, 18, NOZ }, { 8, 34, NOZ2 }, { 30, 58, NOZ },
        { 20, 10, VEIO }, { 56, 42, VEIO2 }, { 14, 52, VEIO },
    },
    desgaste = {
        { 12, 29, 6 }, { 26, 30, 5 }, { 40, 28, 4 }, { 50, 31, 5 },
        { 10, 37, 4 }, { 28, 38, 5 }, { 44, 36, 6 },
    },
}

local V4 = {
    tons = { [1] = 'v', [5] = 'l' },
    topos = {
        [1] = { 18, 48 }, [2] = { 34, 58 }, [3] = { 12, 40 },
        [4] = { 26, 52 }, [5] = { 8, 36, 62 }, [6] = { 20, 46 },
        [7] = { 30, 54 }, [8] = { 14, 42 },
    },
    carimbos = {
        { 38, 10, NOZ2 }, { 14, 26, NOZ }, { 50, 50, NOZ },
        { 28, 20, VEIO2 }, { 8, 44, VEIO }, { 44, 36, VEIO },
        { 60, 60, VEIO2 },
    },
    desgaste = {
        { 14, 21, 5 }, { 30, 22, 6 }, { 46, 20, 4 },
        { 20, 45, 4 }, { 36, 46, 5 }, { 52, 44, 5 },
    },
}

return {
    name = 'piso_tabua',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        j = { ramp = 'wood', step = 2, h = 0 }, -- junta rebaixada
        a = { ramp = 'wood', step = 4, h = 1 }, -- tábua base
        l = { ramp = 'wood', step = 5, h = 1 }, -- tábua lavada pelo uso
        v = { ramp = 'wood', step = 3, h = 1 }, -- tábua escura / veio
        n = { ramp = 'wood', step = 2, h = 1 }, -- anel do nó
        d = { ramp = 'wood', step = 1, h = 1 }, -- miolo do nó
        s = { ramp = 'wood', step = 6, h = 2 }, -- fio de desgaste
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { tabua(V1), tabua(V2), tabua(V3), tabua(V4) },
        },
    },
}
