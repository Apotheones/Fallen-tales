-- NILO — aprendiz de instrumentos na oficina, idle SUL, 64x96,
-- origem nos pés, 2f. §7 do doc de personagens: 17-19a, 166cm,
-- membros longos para tronco curto, ombros ainda estreitos. Pele
-- cobre clara (skin.5), rosto oval, olhos muito abertos. CABEÇA
-- VOLUMOSA de cabelo castanho escuro denso 'h', curto atrás e mais
-- longo na frente, com MECHA voltada para cima despontando do topo
-- (âncora). Camisa amarela apagada 'y', colete curto azul gasto 'v'
-- com BOLSO FRONTAL retangular claro 'B' na barriga (âncora);
-- calças marrom 'p' com barra dobrada clara 'C'; sapatos de couro
-- 'b' de pontas escuras. Na mão direita, um instrumento inacabado
-- 'w' de corpo estreito, pendurado na lateral (âncora).
-- Âncoras: mecha alta | bolso claro retangular | instrumento
-- estreito lateral.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)
local function R(map)
    local t = {}
    for r = 1, 96 do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end
local function shift(map, dy, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then t[r + dy] = s
        else t[r] = s end
    end
    return t
end

--------------------------------------------------------------------------------
-- BODY: mecha alta, cabelo volumoso, rosto oval, camisa+colete,
-- calças, sapatos. Bolso e instrumento na camada 'gear'.
--------------------------------------------------------------------------------
local body = {
    -- mecha alta: fio virado para cima saindo do topo (âncora)
    [6]  = '..............................kk',
    [7]  = '.............................khhk',
    [8]  = '.............................khhk',
    [9]  = '............................khhhk',
    -- massa de cabelo denso, mais longo na frente
    [10] = '..........................kkhhhhhhkk',
    [11] = '.........................khhhhhhhhhhk',
    [12] = '........................khhhhhhhhhhhhk',
    [13] = '........................khhhHhhhhHhhhk',
    [14] = '.......................khhhhhhhhhhhhhhk',
    [15] = '.......................khhhhhhhhhhhhhhk',
    [16] = '.......................khhsssssssssshhk',
    [17] = '.......................khsssssssssssshk',
    [18] = '.......................khseessssseeshk',
    [19] = '.......................khsssssssssssshk',
    [20] = '........................kssssdssssssk',
    [21] = '........................ksssssssssssk',
    [22] = '........................ksssssddssssk',
    [23] = '........................khsssssssssshk',
    [24] = '.........................kssssssssssk',
    [25] = '.........................kssssssssk',
    [26] = '..........................kssssssk',
    [27] = '..........................kssssk',
    -- ombros finos; camisa 'y' com colete curto 'v' aberto à frente
    [28] = '...........................kyyyyyk',
    [29] = '.........................kyyyyyyyyyyk',
    [30] = '........................kyyyyyyyyyyyyk',
    [31] = '........................kyvvyyyyyyyyvvyk',
    [32] = '.......................kyyvvyyyyyyyyvvyyk',
    [33] = '.......................kyvvyyyyyyyyyyvvyk',
    [34] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [35] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [36] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [37] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [38] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [39] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [40] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [41] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [42] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [43] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [44] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [45] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [46] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [47] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [48] = '..................kyyk.yvvyyyyyyyyyyvvy.kyyk',
    [49] = '..................kyyk.yvvvyyyyyyyyvvvy.kyyk',
    -- colete curto: fecha acima da cintura; camisa e cinto seguem
    [50] = '..................kyyk.kyvvvvvvvvvvvvyk.kyyk',
    [51] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [52] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [53] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [54] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [55] = '..................kssk.kyyyyyyyyyyyyyyk.kssk',
    [56] = '..................kssk.krrrrrrrrrrrrrrrk.kssk',
    [57] = '..................kssk.kpppppppppppppppk.kssk',
    [58] = '..................kssk.kpppppppppppppppk.kssk',
    [59] = '..................kkkk.kpppppppppppppppk.kkwk',
    [60] = '.........................kppppppk..kppppppkkwk',
    [61] = '.........................kppppppk..kppppppkwWk',
    [62] = '.........................kppppppk..kppppppkWWk',
    [63] = '.........................kppppppk..kppppppkWWk',
    [64] = '.........................kppppppk..kppppppkWwk',
    [65] = '.........................kppppppk..kppppppkwwk',
    [66] = '.........................kppppppk..kppppppk.kk',
    [67] = '.........................kppppppk..kppppppk',
    [68] = '.........................kppppppk..kppppppk',
    [69] = '.........................kppppppk..kppppppk',
    [70] = '.........................kppppppk..kppppppk',
    [71] = '.........................kppppppk..kppppppk',
    [72] = '.........................kppppppk..kppppppk',
    [73] = '.........................kppppppk..kppppppk',
    [74] = '.........................kppppppk..kppppppk',
    [75] = '.........................kppppppk..kppppppk',
    [76] = '.........................kpppppk...kpppppk',
    [77] = '.........................kpppppk...kpppppk',
    [78] = '.........................kpppppk...kpppppk',
    [79] = '.........................kpppppk...kpppppk',
    [80] = '.........................kpppppk...kpppppk',
    -- barra dobrada clara das calças (âncora de reparo próprio)
    [81] = '.........................kpppppk...kpppppk',
    [82] = '.........................kCCCCCk...kCCCCCk',
    [83] = '.........................kCCCCCk...kCCCCCk',
    [84] = '.........................kCCCCCk...kCCCCCk',
    -- sapatos de couro flexível, pontas escuras 'x'
    [85] = '.........................kbbbbbk...kbbbbbk',
    [86] = '.........................kbbbbbk...kbbbbbk',
    [87] = '.........................kbbbbbk...kbbbbbk',
    [88] = '.........................kbbbbbk...kbbbbbk',
    [89] = '.........................kbbbbbk...kbbbbbk',
    [90] = '.........................kbbbbbk...kbbbbbk',
    [91] = '.........................kxxbbbk...kxxbbbk',
    [92] = '.........................kxxbbbk...kxxbbbk',
    [93] = '.........................kooooook..kooooook',
    [94] = '.........................kkkkkkk..kkkkkkk',
}

--------------------------------------------------------------------------------
-- GEAR: bolso frontal retangular claro 'B' (âncora) no colete +
-- corpo do instrumento 'W' que continua do cabo 'w' do body.
--------------------------------------------------------------------------------
local gear = {
    [50] = '...........................kBBBBBBBBBBk',
    [51] = '...........................kBbbbbbbbbBk',
    [52] = '...........................kBbbbbbbbbBk',
    [53] = '...........................kBbbbbbbbbBk',
    [54] = '...........................kBbbbbbbbbBk',
    [55] = '...........................kBBBBBBBBBBk',
    -- corpo arredondado do instrumento inacabado
    [60] = '...........................................kkWWk',
    [61] = '..........................................kWWWWk',
    [62] = '..........................................kWWxWWk',
    [63] = '..........................................kWWWWk',
    [64] = '..........................................kWWWWk',
    [65] = '...........................................kWWk',
    [66] = '............................................kkk',
}

return {
    name = 'npc_nilo_s',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 5, h = 11},  -- cobre clara
        S = {ramp = 'skin', step = 6, h = 12},
        d = {ramp = 'skin', step = 4, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 2, h = 11},  -- castanho escuro denso
        H = {ramp = 'hair', step = 4, h = 12},
        y = {ramp = 'gold', step = 5, h = 6},   -- camisa amarela apagada
        v = {ramp = 'sea', step = 3, h = 6},    -- colete azul gasto
        B = {ramp = 'bone', step = 5, h = 8},   -- bolso retangular claro
        b = {ramp = 'earth', step = 2, h = 2},  -- sapatos / dentro bolso
        r = {ramp = 'earth', step = 2, h = 5},  -- cinto
        p = {ramp = 'earth', step = 3, h = 4},  -- calças marrom
        C = {ramp = 'earth', step = 5, h = 5},  -- barra dobrada clara
        x = {ramp = 'hair', step = 1, h = 3},   -- pontas escuras / boca do instrumento
        w = {ramp = 'wood', step = 4, h = 7},   -- cabo do instrumento
        W = {ramp = 'wood', step = 5, h = 7},   -- corpo do instrumento
        o = {ramp = 'earth', step = 4, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 28, 54)),
        }},
        {name = 'gear', h = 7, albedo = {
            R(gear),
            R(gear),
        }},
    },
}
