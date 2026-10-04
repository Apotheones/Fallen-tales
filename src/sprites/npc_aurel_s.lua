-- AUREL — Primeiro Zelador, idle SUL, 64x96, origem nos pés, 4f.
-- f1 repouso | f2 respiro | f3 GESTO: cabeça sobe 1px (olha o Marco
-- acima) + pano desdobra 1px | f4 respiro + piscar.
-- §8 do doc de personagens: 56-62a, 178cm, magro de tórax comprido.
-- Pele castanha dourada (skin.3), rosto longo, barba raspada; cabelo
-- GRISALHO puxado para trás com linha recuada (testa alta de pele) e
-- orelhas grandes à mostra. Retângulo vertical: sobrecasaca azul
-- carvão (sea.2) sobre túnica de linho cinza-pérola (plaster.4) que
-- desce abaixo dos joelhos ABERTA à frente (fenda 'kk' central);
-- gola alta estreita 'z' subindo pelo pescoço; faixa de trabalho
-- horizontal 'f' na cintura; punhos de couro 'r'. Na mão esquerda,
-- o pano 'p' quase sem cor com que limpa o marco.
-- Âncoras: gola alta estreita | túnica vertical fendida | cabelo
-- claro recuado.

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
local function patch(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do t[r] = s end
    return t
end

--------------------------------------------------------------------------------
-- BODY: cabeça alongada, gola alta, sobrecasaca+túnica fendida, botas
-- finas. Pano fica na camada 'trab' junto à faixa de cintura.
--------------------------------------------------------------------------------
local body = {
    -- cabelo grisalho puxado para trás; linha recuada = testa alta
    [8]  = '............................kkkkkk',
    [9]  = '...........................kggggggk',
    [10] = '..........................kggggggggk',
    [11] = '..........................kggGggggggk',
    [12] = '..........................kggggggggk',
    [13] = '..........................kgssssssgk',   -- têmporas grisalhas
    [14] = '..........................kgssssssgk',
    [15] = '..........................kssssssssk',
    [16] = '..........................kssssssssk',
    -- orelhas grandes à mostra ('kssk' saltando dos lados)
    [17] = '......................ksskksssssssskkssk',
    [18] = '......................ksskkseessseekkssk',
    [19] = '......................ksskksssssssskkssk',
    [20] = '.......................kk.kssssssssk.kk',
    [21] = '..........................ksssdssssk',   -- nariz reto
    [22] = '..........................ksssdssssk',
    [23] = '..........................kssssssssk',
    [24] = '..........................ksssddsssk',   -- boca, barba raspada
    [25] = '..........................kssssssssk',
    [26] = '..........................kssssssssk',
    [27] = '...........................kssssssk',
    [28] = '...........................kssssssk',
    [29] = '............................kssssk',
    -- gola alta estreita (âncora): sobe o pescoço como colarinho
    [30] = '............................kzzzzk',
    [31] = '............................kzzzzk',
    [32] = '............................kzzzzk',
    [33] = '............................kzzzzk',
    [34] = '...........................kzzttzzk',
    [35] = '...........................kzzttzzk',
    -- ombros estreitos de sobrecasaca azul carvão sobre túnica pérola
    [36] = '.........................kcccccccccccccccck',
    [37] = '........................kcccccccccccccccccck',
    [38] = '.........................kcccttttttttttccck',
    [39] = '.........................kcccttttttttttccck',
    -- mangas finas soltas dos lados; tronco comprido
    [40] = '...................kcck..kcccttttttttttccck..kcck',
    [41] = '...................kcck..kcccttttttttttccck..kcck',
    [42] = '...................kcck..kcccttttttttttccck..kcck',
    [43] = '...................kcck..kcccttttttttttccck..kcck',
    [44] = '...................kcck..kcccttttttttttccck..kcck',
    [45] = '...................kcck..kcccttttttttttccck..kcck',
    [46] = '...................kcck..kcccttttttttttccck..kcck',
    [47] = '...................kcck..kcccttttttttttccck..kcck',
    [48] = '...................kcck..kcccttttttttttccck..kcck',
    [49] = '...................kcck..kcccttttttttttccck..kcck',
    [50] = '...................kcck..kcccttttttttttccck..kcck',
    [51] = '...................kcck..kcccttttttttttccck..kcck',
    [52] = '...................kcck..kcccttttttttttccck..kcck',
    [53] = '...................kcck..kcccttttttttttccck..kcck',
    -- punhos de couro castanho
    [54] = '...................krrk..kcccttttttttttccck..krrk',
    [55] = '...................krrk..kcccttttttttttccck..krrk',
    [56] = '...................krrk..kcccttttttttttccck..krrk',
    [57] = '...................kssk..kcccttttttttttccck..kssk',
    [58] = '...................kssk..kcccttttttttttccck..kssk',
    [59] = '...................kssk..kcccttttttttttccck..kssk',
    [60] = '...................kppk..kcccttttttttttccck..kssk',
    [61] = '...................kppk..kcccttttttttttccck..kkkk',
    [62] = '...................kppk..kcccttttttttttccck',
    [63] = '...................kppk..kttttttttttttttttk',
    [64] = '...................kppk..kttttttttttttttttk',
    [65] = '...................kppk..kttttttttttttttttk',
    [66] = '....................kk...kttttttttttttttttk',
    [67] = '.........................kttttttttttttttttk',
    [68] = '.........................kttttttttttttttttk',
    [69] = '.........................kttttttttttttttttk',
    [70] = '.........................kttttttttttttttttk',
    [71] = '.........................kttttttttttttttttk',
    -- fenda frontal da túnica (âncora): fenda 'kk' até abaixo dos
    -- joelhos, botas finas aparecem por baixo
    [72] = '.........................ktttttttkktttttttk',
    [73] = '.........................ktttttttkktttttttk',
    [74] = '.........................ktttttttkktttttttk',
    [75] = '.........................ktttttttkktttttttk',
    [76] = '.........................ktttttttkktttttttk',
    [77] = '.........................ktttttttkktttttttk',
    [78] = '.........................ktttttttkktttttttk',
    [79] = '.........................ktttttttkktttttttk',
    [80] = '.........................ktttttttkktttttttk',
    [81] = '.........................ktttttttkktttttttk',
    -- canela e bota fina de sola reforçada
    [82] = '..........................kbbbk..kbbbk',
    [83] = '..........................kbbbk..kbbbk',
    [84] = '..........................kbbbk..kbbbk',
    [85] = '..........................kbbbk..kbbbk',
    [86] = '..........................kbbbk..kbbbk',
    [87] = '..........................kbbbk..kbbbk',
    [88] = '..........................kbbbk..kbbbk',
    [89] = '..........................kbbbk..kbbbk',
    [90] = '..........................kbbbbk.kbbbbk',
    [91] = '..........................kbbbbk.kbbbbk',
    [92] = '..........................kbbbbk.kbbbbk',
    [93] = '..........................koooook.koooook',
    [94] = '..........................kkkkkk.kkkkkk',
}

--------------------------------------------------------------------------------
-- TRAB: faixa de trabalho horizontal 'f' na cintura + pontas do pano
-- que escapam da mão (o corpo do pano já está no body p/ seguir o
-- punho; aqui só o reforço da faixa — âncora "faixa horizontal").
--------------------------------------------------------------------------------
local band = {
    [54] = '............................kffffffffffk',
    [55] = '............................kffffffffffk',
}

local garb = R(band)

-- f3: olha o Marco acima — cabeça sobe 1px (o queixo sai da gola; a
-- linha do pescoço é reposta no vão); pano desdobra 1px à direita.
local gesto = patch(shift(body, -1, 8, 29), {
    [29] = '............................kssssk',
    [62] = '...................kpppk..kttttttttttttttttk',
    [63] = '...................kpppk..kttttttttttttttttk',
    [64] = '...................kpppk..kttttttttttttttttk',
    [65] = '...................kpppk..kttttttttttttttttk',
    [66] = '....................kkk...kttttttttttttttttk',
})
-- f4: respiro com piscar — olhos 'ee' viram pálpebra 'dd'.
local respiroPisca = shift(patch(body, {
    [18] = '......................ksskksddsssddkkssk',
}), 1, 36, 56)

return {
    name = 'npc_aurel_s',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},  -- castanha dourada
        S = {ramp = 'skin', step = 4, h = 12},
        d = {ramp = 'skin', step = 2, h = 10},
        e = {spec = 'ink', h = 12},
        g = {ramp = 'iron', step = 5, h = 11},  -- cabelo grisalho
        G = {ramp = 'iron', step = 6, h = 12},
        z = {ramp = 'sea', step = 3, h = 9},    -- gola alta estreita
        c = {ramp = 'sea', step = 2, h = 7},    -- sobrecasaca azul carvão
        t = {ramp = 'plaster', step = 4, h = 6},-- túnica linho pérola
        f = {ramp = 'earth', step = 3, h = 8},  -- faixa de trabalho
        r = {ramp = 'earth', step = 2, h = 6},  -- punhos de couro
        p = {ramp = 'bone', step = 5, h = 7},   -- pano quase sem cor
        b = {ramp = 'earth', step = 2, h = 2},
        o = {ramp = 'earth', step = 4, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 36, 56)),
            R(gesto),
            R(respiroPisca),
        }},
        {name = 'trab', h = 8, albedo = {garb, garb, garb, garb}},
    },
}
