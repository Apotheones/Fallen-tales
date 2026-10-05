-- PISO_TERRA — terra batida, tile 64x64, origem topleft. 4 frames =
-- variantes de seed. Massa contínua de barro em manchas grandes e moles,
-- pedrinhas em clusters desenhados (pedra clara + sombra, nunca
-- pontilhado) e mancha de desgaste mais clara onde o pé sempre passa.
-- h: depressão 0, massa 1, pedrinha 2.
-- v2: as manchas eram todas elipses médias — agora variam em tamanho e
-- elongação (manchão raro, veios alongados horizontais/verticais, manchas
-- pequenas), quebrando a repetitividade do tile lado a lado.
-- v3: contraste de DENSIDADE — cada variante concentra as marcas num
-- rastro de uso (desgaste + farelo + pedrinhas se amontoando por uma
-- trilha desenhada) e deixa zonas grandes quase limpas. Em luz plena
-- o speckle uniforme lia como chão liso; a trilha devolve textura.

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
-- v3 — Farelo de rastro: pontos miúdos de desgaste ('b') ou de barro
-- pisado ('d') marcando a borda da trilha — textura entre o desgaste
-- cheio e a massa limpa.
local FARELO_B1 = {
    '.bb.',
    'bb..',
    '.b..',
}
local FARELO_B2 = {
    'bb..',
    '.bbb',
    '..b.',
}
local FARELO_D1 = {
    '.d.',
    'dd.',
    '.d.',
}
local FARELO_D2 = {
    'd..',
    'ddd',
    '..d',
}
-- Tufo de grama: pequena massa escura com lâminas subindo — nasce em
-- beirada de muro/sombra, nunca no meio do caminho.
local TUFO_A = {
    't.t.',
    'tgtg',
    'gggg',
}
local TUFO_B = {
    '.t.t',
    'gtgt',
    'ggg.',
}

local function terra(spec)
    local g = nova('a')
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

local V1 = {
    -- v7 (regra da Mira): tile = BASE quase limpa; a textura mora no
    -- overlay terra_mancha que atravessa 2+ celulas. Celula sem contorno.
    carimbos = {
        { 18, 30, MASSA_P1 }, { 46, 14, MASSA_P2 },
        { 34, 44, PEDRA_E },
        { 26, 12, GRAO },
    },
}

local V2 = {
    -- Quieta, outra poeira.
    carimbos = {
        { 40, 26, MASSA_P1 },
        { 10, 48, PEDRA_E }, { 52, 50, MASSA_P2 },
        { 22, 34, VALE },
    },
}

local V3 = {
    -- Quieta — mancha solta e uma pedrinha, miolo amplo limpo.
    carimbos = {
        { 24, 24, MASSA_D1 },
        { 48, 40, PEDRA_A },
        { 36, 52, GRAO },
    },
}

local V4 = {
    -- Meia-uso suave (uso contextual ainda pode chamar este frame).
    carimbos = {
        { 26, 26, MASSA_G2 }, { 24, 30, DESG_B },
        { 30, 34, PEDRA_B }, { 24, 2, MASSA_L1 },
        { 28, 30, VALE },
        { 26, 28, GRAO },
    },
}

return {
    name = 'piso_terra',
    w = 64, h = 64,
    origin = 'topleft',
    frameUse = 'variant', -- 4 frames = variantes por seed, nunca animação

    legend = {
        -- v4 (padrão-ouro): contraste aberto — manchas 1 passo mais
        -- fundas e desgaste/grão mais claros; o campo lia plano em luz.
        a = { ramp = 'earth', step = 4, h = 1 }, -- massa de barro
        d = { ramp = 'earth', step = 2, h = 1 }, -- mancha pisada funda
        r = { ramp = 'earth', step = 1, h = 0 }, -- depressão funda
        b = { ramp = 'earth', step = 6, h = 1 }, -- desgaste claro
        c = { ramp = 'earth', step = 7, h = 1 }, -- grão claro raro
        p = { ramp = 'stone', step = 5, h = 2 }, -- pedrinha, luz
        q = { ramp = 'stone', step = 3, h = 2 }, -- pedrinha, lado de sombra
        u = { ramp = 'earth', step = 2, h = 1 }, -- sombra sob a pedrinha
        g = { ramp = 'moss',  step = 2, h = 1 }, -- tufo de grama, base
        t = { ramp = 'moss',  step = 4, h = 2 }, -- lâmina do tufo
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { terra(V1), terra(V2), terra(V3), terra(V4) },
        },
    },
}
