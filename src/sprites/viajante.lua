-- O VIAJANTE — protagonista, idle SUL (de frente), 64x96, origem nos pés.
-- 2 frames: respiração sutil (ombros/tórax descem 1px, sem teleporte).
-- Âncoras (docs/PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md §1):
--   arco lateral alto | aba assimétrica do casaco | remendo claro no ombro.
-- Revisão pós-Mira:
--   * rosto limpo — olhos 'ee' separados por 6px de pele, nariz 'd' de 1px,
--     boca 'dd' em tom de pele, barba = stubble 'h' irregular só na mandíbula;
--   * arco com CURVA: duas hastes 'w' arqueadas (barriga a 7px da corda),
--     corda 't' reta de osso, punhadura clara 'WW' no meio, nock 'f';
--   * mão direita = punho fechado 'kssssk' junto à coxa; aljava no quadril
--     com boca, corpo afunilado e 3 flechas (pena 'f' + haste 'a');
--   * casaco clothWarm? não — casaco earth.3 (marrom frio) separado das
--     calças iron.2 (cinza-frio) por rampa+hue, com filete 'C' na bainha.
-- Relevo: cabeça 10-12, tronco 5-7, botas 2-3.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)

-- Grade esparsa: { [linha] = 'conteúdo' } -> string 64x96. '.' = vazio.
local function R(map)
    local t = {}
    for r = 1, 96 do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end

-- Desloca as linhas [rmin..rmax] do mapa em dy (respiração/bob).
local function shift(map, dy, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then t[r + dy] = s
        else t[r] = s end
    end
    return t
end

--------------------------------------------------------------------------------
-- BODY: cabelo, rosto limpo, pescoço, camisa+colete, cinto, calças, botas.
--------------------------------------------------------------------------------
local body = {
    -- cabelo preto ondulado, coroa
    [8]  = '.................................kkkk',
    [9]  = '................................khhhhhhk',
    [10] = '...............................khhhhhhhhk',
    [11] = '..............................khhhhhHhhhhk',
    [12] = '.............................khhhhhhhhhhhhk',
    [13] = '............................khhhhhhhhhhhhhhk',
    [14] = '............................khhhhhhhhhhhhhhk',
    -- rosto limpo: pele c29-42, olhos separados por 6px de pele
    [15] = '..........................khsssssssssssssshk',
    [16] = '..........................khsssssssssssssshk',
    [17] = '..........................khsssssssssssssshk',
    [18] = '..........................khsseesssssseesshk',
    [19] = '..........................khsseesssssseesshk',
    [20] = '.........................khhssssssssssssshhk',
    [21] = '.........................khhssssssdssssssshhk',
    [22] = '.........................khhssssssdssssssshhk',
    [23] = '.........................khhssssssssssssshhk',
    [24] = '.........................khhssssssddsssssshk',
    [25] = '.........................khdsssssssssssssdhk',
    -- barba curta irregular: stubble 'h' + sombra 'd' na mandíbula
    [26] = '.........................khhddsssssddsssddhhk',
    [27] = '.........................khhddshshssshshddhhk',
    [28] = '..........................khdhshhhhshshdhk',
    -- queixo + massa de cabelo amarrado baixo na nuca (laterais)
    [29] = '...........................khhkhhhhhhkhhk',
    [30] = '...........................khhkddhhddkhhk',
    [31] = '............................khhkddkhhk',
    [32] = '............................khhsssshhk',
    [33] = '............................khhsssshhk',
    [34] = '............................khdssssdhk',
    [35] = '.............................kssssk',
    [36] = '.............................kssssk',
    [37] = '.............................kssssk',
    -- ombros: camisa de linho cru
    [38] = '..........................kllllllllllllllk',
    [39] = '.........................klllllllllllllllllk',
    [40] = '........................klllllllllllllllllllk',
    [41] = '........................kllllllvvvvvvvllllllk',
    [42] = '........................kllllvvvvvvvvvvvllllk',
    [43] = '........................kllvvvvvvvvvvvvvvvllk',
    [44] = '........................kllvvvvvvvvvvvvvvvllk',
    [45] = '........................kllvvvvvvvvvvvvvvvllk',
    [46] = '........................kllvvvvvvvvvvvvvvvllk',
    [47] = '........................kllvvvvvvvvvvvvvvvllk',
    [48] = '........................kllvvvvvvvvvvvvvvvllk',
    [49] = '........................kllvvvvvvvvvvvvvvvllk',
    [50] = '........................kllvvvvvvvvvvvvvvvllk',
    [51] = '........................kllvvvvvvvvvvvvvvvllk',
    [52] = '........................kllvvvvvvvvvvvvvvvllk',
    [53] = '........................kllvvvvvvvvvvvvvvvllk',
    [54] = '........................kllvvvvvvvvvvvvvvvllk',
    [55] = '.........................klvvvvvvvvvvvvvvvlk',
    [56] = '.........................klvvvvvvvvvvvvvvvlk',
    -- cinto de terra + fivela; punho direito fechado junto à coxa
    [57] = '........................krrrrrrrrnnrrrrrrrrk.....kssssk',
    [58] = '........................krrrrrrrrnnrrrrrrrrk.....kssssk',
    [59] = '........................krrrrrrrrnnrrrrrrrrk.....kssssk',
    -- quadris e pernas em iron (cinza-frio): separam do casaco por rampa
    [60] = '.........................kpppppppppppppppppk....kssssk',
    [61] = '.........................kpppppppppppppppppk....kssssk',
    [62] = '.........................kpppppppppppppppppk....kssssk',
    [63] = '........................kpppppppk..kpppppppk....kkkkk',
    [64] = '........................kpppppppk..kpppppppk',
    [65] = '........................kpppppppk..kpppppppk',
    [66] = '........................kpppppppk..kpppppppk',
    [67] = '........................kpppppppk..kpppppppk',
    [68] = '........................kpppppppk..kpppppppk',
    [69] = '........................kpppppppk..kpppppppk',
    [70] = '........................kpKKKKKpk..kpKKKKKpk',
    [71] = '........................kpKKKKKpk..kpKKKKKpk',
    [72] = '........................kpKKKKKpk..kpKKKKKpk',
    [73] = '........................kpKKKKKpk..kpKKKKKpk',
    [74] = '........................kpKKKKKpk..kpKKKKKpk',
    [75] = '........................kpKKKKKpk..kpKKKKKpk',
    [76] = '.........................kppppppk..kppppppk',
    [77] = '.........................kppppppk..kppppppk',
    [78] = '.........................kppppppk..kppppppk',
    [79] = '.........................kppppppk..kppppppk',
    [80] = '.........................kppppppk..kppppppk',
    [81] = '.........................kppppppk..kppppppk',
    [82] = '..........................kpppppk..kpppppk',
    [83] = '..........................kpppppk..kpppppk',
    [84] = '..........................kpppppk..kpppppk',
    -- botas castanhas; sola esquerda remendada 'o', direita 'B'
    [85] = '.........................kbbbbbbbk..kbbbbbbbk',
    [86] = '.........................kbbbbbbbk..kbbbbbbbk',
    [87] = '.........................kbbbbbbbk..kbbbbbbbk',
    [88] = '.........................kbbbbbbbk..kbbbbbbbk',
    [89] = '.........................kbbbbbbbk..kbbbbbbbk',
    [90] = '........................kbbbbbbbbk..kbbbbbbbbk',
    [91] = '........................kbbbbbbbbk..kbbbbbbbbk',
    [92] = '........................kbbbbbbbbk..kbbbbbbbbk',
    [93] = '........................koooooooook..kBBBBBBBBk',
    [94] = '........................kkkkkkkkkk..kkkkkkkkkk',
}

--------------------------------------------------------------------------------
-- COAT: casaco marrom frio aberto à frente; aba esquerda comprida (até a
-- coxa), direita presa/curta; remendo ocre no ombro esquerdo do sprite;
-- filete 'C' na bainha; manga do braço do arco desce à empunhadura.
--------------------------------------------------------------------------------
local coat = {
    [37] = '.......................kcccccccccccccccccccccck',
    [38] = '......................kcccccccccccccccccccccccck',
    [39] = '......................kcmmmmcccccccccccccccccck',
    [40] = '.....................kccmmmmmcccccccccccccccccck',
    [41] = '.....................kccmmmmmmccccccccccccxcck',
    [42] = '.....................kccmmmmmmccccccccccccxcck',
    [43] = '.....................kcccmmmccccccccccccccxcck',
    [44] = '.....................kccccccccccnccccccccxcck',
    -- manga esquerda desce em diagonal à empunhadura (vão de 1px a
    -- separa do painel e lê braço); painéis abertos à frente
    [45] = '.................kccckkcccx..................xcccckcck',
    [46] = '.................kccckkcccx..................xcccckcck',
    [47] = '.............kccck.kccccx...............xcccckcck',
    [48] = '.............kccck.kccccx...............xcccckcck',
    [49] = '.............kccck.kccccx...............xcccckcck',
    [50] = '.............kccck.kccccx...............xcccckcck',
    [51] = '.............kccck.kccccx...............xcccckcck',
    [52] = '.............kccck.kccccx...............xcccckCCk',
    [53] = '.............kccck.kccccx...............xcccckCCk',
    [54] = '.............kCCCk..kccccx...............xcccckCCk',
    [55] = '.............kCCCk..kccccx...............xcccckCCk',
    [56] = '.............kCCCk..kccccx...............xcccckCCk',
    -- painéis: esquerdo comprido, direito preso com pin 'n'
    [57] = '....................kccccx...............xcccck',
    [58] = '....................kccccx...............xcccck',
    [59] = '....................kccccx...............xcccck',
    [60] = '....................kccccx...............xcccck',
    [61] = '....................kccccx...............xcccck',
    [62] = '....................kccccx...............xcccck',
    [63] = '....................kccccx...............xCCCCnk',
    [64] = '....................kccccx',
    [65] = '....................kccccx',
    [66] = '....................kccccx',
    [67] = '....................kccccx',
    [68] = '....................kccccx',
    [69] = '....................kccccx',
    [70] = '....................kccccx',
    [71] = '....................kccccx',
    [72] = '....................kccccx',
    [73] = '....................kccccx',
    [74] = '....................kccccx',
    [75] = '....................kccccx',
    [76] = '....................kccccx',
    [77] = '....................kCCCCx',
    [78] = '....................kxxxx',
}

--------------------------------------------------------------------------------
-- GEAR: mapa por peça, sobrepostos por overlay() (último vence por pixel).
--------------------------------------------------------------------------------
-- Sobrepõe duas grades assadas por R(): chars não-vazios de gb ganham.
local function overlay(ga, gb)
    local A, B, out = {}, {}, {}
    for l in ga:gmatch('[^\n]+') do A[#A + 1] = l end
    for l in gb:gmatch('[^\n]+') do B[#B + 1] = l end
    for i = 1, #A do
        local a, b, row = A[i], B[i] or '', {}
        for x = 1, 64 do
            local cb = b:sub(x, x)
            row[x] = (cb ~= '.' and cb ~= ' ' and cb ~= '') and cb
                or a:sub(x, x)
        end
        out[i] = table.concat(row)
    end
    return table.concat(out, '\n')
end

-- arco longo encordoado: hastes 'w' arqueadas, corda 't' reta de osso.
-- Barriga máxima a 7px da corda no meio; pontas voltam à corda (lê "D").
local bow = {
    [5]  = '.....................wt',
    [6]  = '.....................wt',
    [7]  = '....................wwt',
    [8]  = '....................wwt',
    [9]  = '....................wwt',
    [10] = '...................ww.t',
    [11] = '...................ww.t',
    [12] = '...................ww.t',
    [13] = '...................ww.t',
    [14] = '..................ww..t',
    [15] = '..................ww..t',
    [16] = '..................ww..t',
    [17] = '..................ww..t',
    [18] = '..................ww..t',
    [19] = '..................ww..t',
    [20] = '.................ww...t',
    [21] = '.................ww...t',
    [22] = '.................ww...t',
    [23] = '.................ww...t',
    [24] = '.................ww...t',
    [25] = '.................ww...t',
    [26] = '.................ww...t',
    [27] = '.................ww...t',
    [28] = '................ww....t',
    [29] = '................ww....t',
    [30] = '................ww....t',
    [31] = '................ww....t',
    [32] = '................ww....t',
    [33] = '................ww....t',
    [34] = '................ww....t',
    [35] = '................ww....t',
    [36] = '................ww....t',
    [37] = '................ww....t',
    [38] = '................ww....t',
    [39] = '...............ww.....t',
    [40] = '...............ww.....t',
    [41] = '...............ww.....t',
    [42] = '...............ww.....t',
    [43] = '...............ww.....t',
    [44] = '...............ww.....t',
    [45] = '...............ww.....t',
    [46] = '...............ww.....t',
    -- punhadura 'WW' (enrolado claro) no meio da haste
    [47] = '...............WW.....t',
    [48] = '...............WW.....t',
    [49] = '...............WW.....t',
    [50] = '...............WW.....t',
    [51] = '...............WW.....t',
    [52] = '...............WW.....t',
    [53] = '...............WW.....t',
    [54] = '...............WW.....t',
    -- acento jade amarrado sob a empunhadura (mesmo cordão do pingente)
    [55] = '...............WWj....t',
    [56] = '...............ww.....t',
    [57] = '...............ww.....t',
    [58] = '...............ww.....t',
    [59] = '...............ww.....t',
    [60] = '...............ww.....t',
    [61] = '...............ww.....t',
    [62] = '...............ww.....t',
    [63] = '................ww....t',
    [64] = '................ww....t',
    [65] = '................ww....t',
    [66] = '................ww....t',
    [67] = '................ww....t',
    [68] = '................ww....t',
    [69] = '................ww....t',
    [70] = '................ww....t',
    [71] = '.................ww...t',
    [72] = '.................ww...t',
    [73] = '.................ww...t',
    [74] = '.................ww...t',
    [75] = '.................ww...t',
    [76] = '..................ww..t',
    [77] = '..................ww..t',
    [78] = '..................ww..t',
    [79] = '...................ww.t',
    [80] = '...................ww.t',
    [81] = '....................wwt',
    [82] = '....................wwt',
}

-- punho esquerdo fechado sobre a empunhadura
local fist = {
    [50] = '..............kssssk',
    [51] = '..............kssssk',
    [52] = '..............kssssk',
    [53] = '..............kssssk',
    [54] = '..............kddsdk',
    [55] = '..............kkkkk',
}

-- pingente jade: cordão 'T' em V, pedra 'jjj'/'j' (emissivo ei 0.8)
local pendant = {
    [45] = '.................................T..T',
    [46] = '..................................T.T',
    [47] = '...................................T',
    [48] = '..................................jjj',
    [49] = '...................................j',
}

-- aljava de quadril à direita: estreita, couro escuro 'Q'/'q', boca
-- aberta com 3 flechas (pena 'f' clara + haste 'a' fina) saindo por cima
local quiver = {
    [52] = '......................................................f.f.f',
    [53] = '......................................................f.f.f',
    [54] = '......................................................a.a.a',
    [55] = '......................................................a.a.a',
    [56] = '......................................................a.a.a',
    [57] = '......................................................a.a.a',
    [58] = '......................................................a.a.a',
    [59] = '......................................................a.a.a',
    [60] = '......................................................kQQQQk',
    [61] = '......................................................kQqqQk',
    [62] = '......................................................kQqqQk',
    [63] = '......................................................kQqqQk',
    [64] = '......................................................kQqqQk',
    [65] = '......................................................kQqqQk',
    [66] = '......................................................kQqqQk',
    [67] = '......................................................kQqqQk',
    [68] = '......................................................kQqqQk',
    [69] = '......................................................kQqqQk',
    [70] = '......................................................kQqqQk',
    [71] = '......................................................kQqqQk',
    [72] = '......................................................kQqqQk',
    [73] = '.......................................................kQQk',
    [74] = '.......................................................kQQk',
    [75] = '.......................................................kQQk',
    [76] = '.......................................................kQQk',
    [77] = '........................................................kQk',
    [78] = '........................................................kQk',
}

local gear = overlay(R(bow), overlay(R(quiver),
    overlay(R(pendant), R(fist))))

return {
    name = 'viajante',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        h = {ramp = 'hair', step = 1, h = 11},
        H = {ramp = 'hair', step = 4, h = 12},
        s = {ramp = 'skin', step = 4, h = 11},
        S = {ramp = 'skin', step = 5, h = 12},
        d = {ramp = 'skin', step = 3, h = 10},
        e = {spec = 'ink', h = 12},
        l = {ramp = 'plaster', step = 5, h = 6},
        v = {ramp = 'moss', step = 3, h = 6},
        r = {ramp = 'earth', step = 2, h = 5},
        n = {ramp = 'gold', step = 5, h = 7},
        p = {ramp = 'iron', step = 2, h = 4},
        K = {ramp = 'iron', step = 3, h = 5},
        b = {ramp = 'earth', step = 2, h = 2},
        B = {ramp = 'earth', step = 4, h = 3},
        o = {ramp = 'earth', step = 5, h = 2},
        c = {ramp = 'earth', step = 3, h = 7},
        x = {ramp = 'earth', step = 2, h = 6},
        C = {ramp = 'earth', step = 5, h = 7},
        m = {ramp = 'gold', step = 5, h = 7},
        w = {ramp = 'wood', step = 3, h = 5},
        W = {ramp = 'wood', step = 5, h = 6},
        t = {ramp = 'bone', step = 4, h = 4},
        T = {ramp = 'earth', step = 2, h = 9},
        q = {ramp = 'earth', step = 4, h = 7},
        Q = {ramp = 'earth', step = 2, h = 7},
        a = {ramp = 'wood', step = 5, h = 7},
        f = {ramp = 'bone', step = 5, h = 7},
        j = {spec = 'jade', h = 9, e = 'jadeLight', ei = 0.8},
    },

    -- Metadados W4 (consumidos por tools/kit_w4 e tools/kit_workbench):
    -- âncoras 1-based por frame, marcadores de fase, sequências nomeadas
    -- e exposição por frame em segundos (0.5 = o t*2 do hd_world).
    anchors = {
        pe = {34, 94},                       -- contato dos pés no chão
        cabeca = {37, 20},                   -- face (pele, entre os olhos)
        ferramenta = {16, 51},               -- punhadura do arco 'WW'
        mao_r = {57, 58},                    -- punho direito junto à coxa
        emissao = {{35, 48}, {35, 49}},      -- pingente jade (desce no f2)
    },
    sequences = { idle = {1, 2, loop = true} },
    frameDuration = {0.5, 0.5},
    regions = {
        rosto = {x = 27, y = 15, w = 18, h = 20},
        arco = {x = 14, y = 14, w = 12, h = 69},
        punho_d = {x = 53, y = 57, w = 7, h = 6},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 38, 56)), -- expira: tórax desce 1px
        }},
        {name = 'coat', h = 7, albedo = {
            R(coat),
            R(shift(coat, 1, 37, 44)), -- ombros/caída do casaco acompanham
        }},
        {name = 'gear', h = 6, albedo = {
                gear,
                gear, -- arco/aljava firmes; só o pingente acompanha o tórax
            },
            emissive = {
                R {
                    [48] = '..................................jjj',
                    [49] = '...................................j',
                    [55] = '..................j',
                },
                R {
                    [49] = '..................................jjj',
                    [50] = '...................................j',
                    [55] = '..................j',
                },
            }},
    },
}
