-- PISO_TERRA — terra batida, tile 64x64, origem topleft. 4 frames =
-- variantes de seed. Massa contínua de barro em manchas grandes e moles,
-- pedrinhas em clusters desenhados (pedra clara + sombra, nunca
-- pontilhado) e mancha de desgaste mais clara onde o pé sempre passa.
-- h: depressão 0, massa 1, pedrinha 2.
-- v2: as manchas eram todas elipses médias — agora variam em tamanho e
-- elongação (manchão raro, veios alongados horizontais/verticais, manchas
-- pequenas), quebrando a repetitividade do tile lado a lado.

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

-- Massas grandes de barro pisado ('d'): manchas moles de 10-20 px,
-- o volume da superfície — não confete.
local MASSA_D1 = {
    '...ddddd.....',
    '..dddddddd...',
    '.dddddddddd..',
    'ddddddddddd..',
    'dddddddddd...',
    '.dddddddd....',
    '..dddddd.....',
}
local MASSA_D2 = {
    '..ddddd....',
    '.dddddddd..',
    'ddddddddd..',
    'ddddddddd..',
    '.ddddddd...',
    '..ddddd....',
}
local MASSA_D3 = {
    '...dddddd...',
    '..dddddddd..',
    '.ddddddddd..',
    '.dddddddd...',
    '..dddddd....',
}
-- v2 — Manchão raro (~1 por tile): lâmina larga de barro pisado.
local MASSA_G1 = {
    '.....dddddd........',
    '...ddddddddddd.....',
    '..dddddddddddddd...',
    '.ddddddddddddddddd.',
    'dddddddddddddddddd.',
    'dddddddddddddddd...',
    '.ddddddddddddddd...',
    '..dddddddddddd.....',
    '....dddddddd.......',
}
local MASSA_G2 = {
    '....ddddddd......',
    '..dddddddddddd...',
    '.dddddddddddddd..',
    'dddddddddddddd...',
    'dddddddddddddd...',
    '.dddddddddddddd..',
    '...dddddddddd....',
    '.....dddddd......',
}
-- v2 — Veios alongados: mancha esticada horizontal, borda irregular.
local MASSA_L1 = {
    '...dddddddddddd...',
    '.ddddddddddddddd..',
    'ddddddddddddddddd.',
    '.dddddddddddddd...',
    '...ddddddddd......',
}
local MASSA_L2 = {
    '.ddddddddddddd..',
    'ddddddddddddddd.',
    'dddddddddddddd..',
    '.dddddddddddd...',
    '...dddddddd.....',
}
-- v2 — Veio vertical estreito: erosionado onde a água desce.
local MASSA_V1 = {
    '.dd.',
    'ddd.',
    'ddd.',
    'dddd',
    '.ddd',
    '.ddd',
    '.ddd',
    '..dd',
    '..d.',
}
local MASSA_V2 = {
    '..dd..',
    '.dddd.',
    '.ddd..',
    '.ddd..',
    'dddd..',
    'ddd...',
    '.dd...',
}
-- v2 — Mancha pequena: lama escura pontuando entre as massas.
local MASSA_P1 = {
    '.ddd.',
    'ddddd',
    'ddd..',
    '.d...',
}
local MASSA_P2 = {
    'dd..',
    'ddd.',
    'dddd',
    '.dd.',
}
-- Mancha de desgaste: barro lavado pelo uso, borda mole.
local DESG_A = {
    '....bbbbbbb.....',
    '..bbbbbbbbbb....',
    '.bbbbbbbbbbbb...',
    'bbbbbbbbbbbbbb..',
    '.bbbbbbbbbbbb...',
    '..bbbbbbbbbb....',
    '....bbbbbbb.....',
}
local DESG_B = {
    '...bbbbbbb...',
    '..bbbbbbbbb..',
    '.bbbbbbbbbbb.',
    'bbbbbbbbbbbb.',
    '.bbbbbbbbb...',
    '...bbbbbb....',
}
-- Pedrinhas: cluster de pedra clara 'p' com lado de sombra 'q' e
-- apoio escuro 'u' no barro — desenhadas, com luz vindo de cima-esq.
local PEDRA_A = {
    '.pp..',
    'pqqp.',
    '.uu..',
}
local PEDRA_B = {
    '.p.pp',
    'ppqpp',
    'u.uu.',
}
local PEDRA_C = {
    'ppp..',
    'pqpp.',
    '.u.u.',
}
local PEDRA_D = { -- duas pedrinhas vizinhas
    '.pp..pp.',
    'ppq.pqp.',
    '.u...u..',
}
local PEDRA_E = {
    '.pp.',
    'pqp.',
    '.u..',
}
-- Depressões de 1-2 px, só dentro das massas escuras.
local VALE = { 'r' }
local VALE2 = { 'r', 'r' }
-- Brilho raro no desgaste: grão claro do barro seco.
local GRAO = { 'c' }
local GRAO2 = { 'c.c' }

local function terra(spec)
    local g = nova('a')
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

local V1 = {
    carimbos = {
        { 36, 10, MASSA_G1 },   -- manchão raro
        { 4, 40, MASSA_L1 },    -- veio horizontal
        { 52, 44, MASSA_V1 },   -- veio vertical
        { 8, 6, MASSA_P1 }, { 28, 30, MASSA_P2 },
        { 14, 20, DESG_A },
        { 48, 8, PEDRA_B }, { 52, 12, PEDRA_E }, { 8, 32, PEDRA_C },
        { 36, 56, PEDRA_D }, { 40, 59, PEDRA_E },
        { 12, 12, VALE }, { 46, 32, VALE }, { 48, 36, VALE2 },
        { 30, 22, GRAO }, { 34, 26, GRAO2 },
    },
}

local V2 = {
    carimbos = {
        { 34, 30, MASSA_G2 },   -- manchão raro
        { 40, 4, MASSA_L2 },    -- veio horizontal no topo
        { 8, 22, MASSA_V2 },    -- veio vertical na esquerda
        { 20, 54, MASSA_D2 }, { 54, 50, MASSA_P1 },
        { 10, 8, DESG_B }, { 44, 26, DESG_B },
        { 20, 18, PEDRA_A }, { 23, 21, PEDRA_E }, { 56, 14, PEDRA_C },
        { 30, 52, PEDRA_B }, { 34, 55, PEDRA_E }, { 8, 58, PEDRA_D },
        { 40, 12, VALE2 }, { 14, 40, VALE }, { 52, 46, VALE },
        { 14, 12, GRAO }, { 48, 30, GRAO2 },
    },
}

local V3 = {
    carimbos = {
        { 6, 34, MASSA_G2 },    -- manchão raro embaixo-esq
        { 30, 6, MASSA_L1 },    -- veio horizontal no topo
        { 54, 12, MASSA_V1 },   -- veio vertical na direita
        { 14, 10, MASSA_D3 }, { 40, 54, MASSA_P2 },
        { 20, 26, DESG_A },
        { 6, 24, PEDRA_D }, { 50, 22, PEDRA_A }, { 54, 25, PEDRA_E },
        { 56, 44, PEDRA_B }, { 14, 58, PEDRA_C },
        { 12, 14, VALE }, { 46, 8, VALE2 }, { 34, 48, VALE },
        { 26, 32, GRAO2 }, { 32, 36, GRAO },
    },
}

local V4 = {
    carimbos = {
        { 32, 34, MASSA_G1 },   -- manchão raro embaixo-dir
        { 24, 4, MASSA_L2 },    -- veio horizontal no topo
        { 6, 30, MASSA_V2 },    -- veio vertical na esquerda
        { 44, 14, MASSA_D2 }, { 54, 52, MASSA_P1 },
        { 36, 20, DESG_B }, { 6, 52, DESG_B },
        { 50, 12, PEDRA_B }, { 54, 15, PEDRA_E }, { 14, 34, PEDRA_A },
        { 28, 54, PEDRA_D }, { 32, 57, PEDRA_E }, { 58, 50, PEDRA_C },
        { 32, 8, VALE }, { 10, 26, VALE2 }, { 46, 44, VALE },
        { 40, 24, GRAO }, { 12, 54, GRAO2 },
    },
}

return {
    name = 'piso_terra',
    w = 64, h = 64,
    origin = 'topleft',
    frameUse = 'variant', -- 4 frames = variantes por seed, nunca animação

    legend = {
        a = { ramp = 'earth', step = 4, h = 1 }, -- massa de barro
        d = { ramp = 'earth', step = 3, h = 1 }, -- mancha pisada
        r = { ramp = 'earth', step = 2, h = 0 }, -- depressão funda
        b = { ramp = 'earth', step = 5, h = 1 }, -- desgaste claro
        c = { ramp = 'earth', step = 6, h = 1 }, -- grão claro raro
        p = { ramp = 'stone', step = 5, h = 2 }, -- pedrinha, luz
        q = { ramp = 'stone', step = 3, h = 2 }, -- pedrinha, lado de sombra
        u = { ramp = 'earth', step = 2, h = 1 }, -- sombra sob a pedrinha
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { terra(V1), terra(V2), terra(V3), terra(V4) },
        },
    },
}
