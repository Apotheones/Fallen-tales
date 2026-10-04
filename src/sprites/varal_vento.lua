-- VARAL_VENTO — varal em vento, prop de chão, 64x96, origem nos pés.
-- Def paralela de varal.lua: lá os 2 frames são VARIANTES por seed
-- (arranjos de peças) e não podem virar loop — aqui f1..f4 são o loop
-- ambiental das peças tremendo no vento, sobre o arranjo do f1 (camisa
-- jade à esquerda, pano quente no meio, pano de reboco à direita).
-- f1 = calmo; f2 brisa à direita; f3 rajada (hem sobe mais 1 px); f4
-- acalma. Mourões, corda, chão e os prendedores 'n' são fixos — cada
-- peça cisalha pela profundidade abaixo da linha de pinos (o pano
-- pendula preso, não voa).
-- Relevo: corda/postes 7-8, roupas 6-7, chão 1-2 (mesma régua do varal).

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)

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
local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function R(map)
    local t = {}
    for r = 1, 96 do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end

-- mourões + corda em catenária + chão — idêntico ao varal (andaime fixo)
local corda = {
    -- mourão esquerdo (cols 10-13) e direito (cols 50-53), topos com
    -- volta da corda 'R'
    [34] = '.........kWWk....................................kWWk',
    [35] = '.........kwwk....................................kwwk',
    [36] = '.........kRrk....................................krRk',
    [37] = '.........krRk....................................kRrk',
    [38] = '.........kwwkrr...............................rrkwwk',
    [39] = '.........kwwk..r.............................r.kwwk',
    [40] = '.........kwwk...r..........................rr..kwwk',
    [41] = '.........kwwk....rr........................r...kwwk',
    [42] = '.........kwvk......rr.....................rr...kwvk',
    [43] = '.........kwwk........rr..................rr....kwwk',
    [44] = '.........kwwk..........rr...............r......kwwk',
    [45] = '.........kwwk...........rrr...........rr.......kwwk',
    [46] = '.........kwwk..............rrrr...rrrr.........kwwk',
    [47] = '.........kwwk....................rrr...........kwwk',
    [48] = '.........kwwk....................................kwwk',
    [49] = '.........kwwk....................................kwwk',
    [50] = '.........kwvk....................................kwvk',
    [51] = '.........kwwk....................................kwwk',
    [52] = '.........kwwk....................................kwwk',
    [53] = '.........kwwk....................................kwwk',
    [54] = '.........kwvk....................................kwvk',
    [55] = '.........kwwk....................................kwwk',
    [56] = '.........kwwk....................................kwwk',
    [57] = '.........kwwk....................................kwwk',
    [58] = '.........kwvk....................................kwvk',
    [59] = '.........kwwk....................................kwwk',
    [60] = '.........kwwk....................................kwwk',
    [61] = '.........kwwk....................................kwwk',
    [62] = '.........kwvk....................................kwvk',
    [63] = '.........kwwk....................................kwwk',
    [64] = '.........kwwk....................................kwwk',
    [65] = '.........kwwk....................................kwwk',
    [66] = '.........kwvk....................................kwvk',
    [67] = '.........kwwk....................................kwwk',
    [68] = '.........kwwk....................................kwwk',
    [69] = '.........kwwk....................................kwwk',
    [70] = '.........kwvk....................................kwvk',
    [71] = '.........kwwk....................................kwwk',
    [72] = '.........kwwk....................................kwwk',
    [73] = '.........kwwk....................................kwwk',
    [74] = '.........kwvk....................................kwvk',
    [75] = '.........kwwk....................................kwwk',
    [76] = '.........kwwk....................................kwwk',
    [77] = '.........kwwk....................................kwwk',
    [78] = '.........kwvk....................................kwvk',
    [79] = '.........kwwk....................................kwwk',
    [80] = '.........kwwk....................................kwwk',
    [81] = '.........kwwk....................................kwwk',
    [82] = '.........kwvk....................................kwvk',
    [83] = '.........kwwk....................................kwwk',
    [84] = '.........kwwk....................................kwwk',
    [85] = '.........kwwk....................................kwwk',
    [86] = '.........kwwk....................................kwwk',
    [87] = '.........kwvk....................................kwvk',
    [88] = '.........kwwk....................................kwwk',
    -- base: terra e relva prendendo os mourões
    [89] = '........eeggk.......e.........e......e.......egge',
    [90] = '.......egegge..e.....e....e.....e......e..egegge',
    [91] = '......eegggge.e.....e...e.....e...e...e.ggggee',
    [92] = '......egGGge....e......e.....e....e...egGGge',
    [93] = '.......egge.....e....e.....e......e...egge',
    [94] = '........ee.......e.....e.....e........ee',
}

-- Peças penduradas: lista de {linha, col0, 'chars'} — col0 é a coluna
-- do primeiro caractere; '.' dentro da string é furo/dobra. `pin` é a
-- linha dos prendedores: profundidade 0, nunca desloca.
local CAMISA = { pin = 41, rigidez = 1.0, rows = {
    {41, 19, 'ncjjjjjjjjn'},
    {42, 17, 'jccjjjjjjjjjjjc'},
    {43, 17, 'jccjjcjjjjcjjjc'},
    {44, 17, 'jc.jjcjjjjcjj.j'},
    {45, 17, 'jc.jjjjjjjjjjj.j'},
    {46, 18, 'c.jjjcjjjcjjj'},
    {47, 18, 'c.jjjjjjjjjjj'},
    {48, 18, 'j.jjjjjjjcjjj'},
    {49, 18, 'j.jjjcjjjjjjj'},
    {50, 20, 'jjjjjjjjjjj'},
    {51, 20, 'jjjcjjjjcjj'},
    {52, 20, 'jjjjjjjjjjj'},
    {53, 20, 'jjjjcjjjjjj'},
    {54, 20, 'jjjjjjjjjjj'},
    {55, 20, 'jjjcjjjjcjj'},
    {56, 20, 'jjjjjjjjjjj'},
    {57, 20, 'jjjjjjjjjjj'},
    {58, 20, 'jjjjjjjjjjj'},
    {59, 20, 'jcjjjjjjcjj'},
    {60, 20, 'jjjjcjjjjj.j'},
    {61, 20, 'jjjjjjjjj'},
    {62, 21, 'jj.jj.jj'},
}}

local PANO = { pin = 44, rigidez = 0.7, rows = {   -- pano quente dobrado
    {44, 32, 'naaaaaaan'},
    {45, 32, 'naaaaaaan'},
    {46, 32, 'aaaaaaaaa'},
    {47, 32, 'aaaacaaaa'},
    {48, 32, 'aaaaaaaaa'},
    {49, 32, 'aaacaaaaa'},
    {50, 32, 'aaaaaaaaa'},
    {51, 32, 'aaaaacaaa'},
    {52, 32, 'aaaaaaaaa'},
    {53, 32, 'aaacaaaa'},
    {54, 32, 'aaaaaaaaa'},
    {55, 32, 'aaccaaaaa'},
    {56, 32, 'aaaaaaa'},
    {57, 32, 'aaaaaa'},
}}

local REBOCO = { pin = 42, rigidez = 0.5, rows = {  -- pano de reboco
    {42, 43, 'npppn'},
    {43, 43, 'npppn'},
    {44, 43, 'ppppp'},
    {45, 43, 'ppdpp'},
    {46, 43, 'ppppp'},
    {47, 43, 'ppppp'},
    {48, 43, 'ppppp'},
    {49, 43, 'ppdpp'},
    {50, 43, 'ppppp'},
    {51, 43, 'ppppp'},
    {52, 43, 'ppppp'},
    {53, 44, 'ppp'},
    {54, 44, 'ppp'},
}}

-- Cisalhamento pelo vento: dx = profundidade * forca * rigidez; na
-- rajada (f3) a barra sobe mais 1 px. Peças mais pesadas (reboco)
-- deslocam menos — penduradas, não voando.
local function roupas(fase)
    local forca = ({0, 0.09, 0.18, 0.05})[fase]
    local g = nova('.')
    for _, peca in ipairs({CAMISA, PANO, REBOCO}) do
        for _, ln in ipairs(peca.rows) do
            local y, x0, s = ln[1], ln[2], ln[3]
            local prof = math.max(0, y - peca.pin)
            local dx = math.floor(prof * forca * peca.rigidez + 0.5)
            -- a barra enrola um pouco mais nas pontas na rajada
            if fase == 3 and prof > 8 then dx = dx + 1 end
            for i = 1, #s do
                local c = s:sub(i, i)
                if c ~= '.' then set(g, x0 + dx + i - 1, y, c) end
            end
        end
    end
    return str(g)
end

return {
    name = 'varal_vento',
    w = 64, h = 96,
    origin = 'feet',
    frameUse = 'anim', -- f1..f4 = loop de vento, não variantes

    legend = {
        k = {spec = 'ink', h = 5},
        -- mourões
        W = {ramp = 'wood', step = 5, h = 8},
        w = {ramp = 'wood', step = 4, h = 7},
        v = {ramp = 'wood', step = 2, h = 7},
        -- corda de fibra e volta no mourão
        r = {ramp = 'bone', step = 4, h = 8},
        R = {ramp = 'bone', step = 5, h = 8},
        -- prendedores
        n = {ramp = 'wood', step = 1, h = 8},
        -- roupas: jade, quente, reboco — 'c/d' dobras em sombra
        j = {ramp = 'cloth', step = 4, h = 6},
        c = {ramp = 'cloth', step = 2, h = 6},
        a = {ramp = 'clothWarm', step = 4, h = 6},
        p = {ramp = 'plaster', step = 4, h = 6},
        d = {ramp = 'plaster', step = 2, h = 6},
        -- chão
        g = {ramp = 'moss', step = 3, h = 2},
        G = {ramp = 'moss', step = 2, h = 2},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'corda', h = 7, albedo = R(corda)},
        {   -- f1..f4 = loop de vento (ver cabeçalho)
            name = 'roupas', h = 6,
            albedo = {roupas(1), roupas(2), roupas(3), roupas(4)},
        },
    },
}
