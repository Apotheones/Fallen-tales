-- V11 NPC_AUREL_S — Aurel primeiro guardião (C08), idle SUL, 64x96
-- feet, 4f. Upgrade C01-grade na MESMA geometria do def anterior
-- (punhos cols 19-24/47-52 linhas 57-62 — npc_aurel_trabalho assenta).
-- Âncoras: gola alta estreita 'z' | túnica dividida vertical 't' |
-- cabelo claro grisalho varrido 'g'. Pele dourada 's', rosto longo,
-- orelhas grandes 'ss', nariz levemente assimétrico, barba raspada.
-- Sobrecasaco azul-carvão 'c' ombros estreitos, manga folgada, punho
-- de couro 'r', faixa de trabalho horizontal 'f' na cintura, bota
-- fina de sola reforçada 'o'. f3 = olha o Marco (cabeça +1 para
-- cima), f4 = pisca.
local function L(s)
    assert(#s <= 64, 'linha > 64')
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
local function patch(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do t[r] = s end
    return t
end

local body = {
    -- cabelo grisalho varrido para trás: testa alta, filetes 'g/G'
    [8]  = '............................kggggkk',
    [9]  = '...........................kgggggggk',
    [10] = '..........................kgggggggggk',
    [11] = '..........................kggGggggggk',
    [12] = '..........................kgggggggggk',
    [13] = '..........................kgsssssssgk',
    [14] = '..........................kgsssssssgk',
    [15] = '..........................ksssssssssk',
    [16] = '..........................ksssssssssk',
    -- orelhas grandes saltando dos lados
    [17] = '......................ksskksssssssskkssk',
    [18] = '......................ksskkseeesseekkssk',
    [19] = '......................ksskksssssssskkssk',
    [20] = '.......................kk.kssssssssk.kk',
    [21] = '..........................ksssnssssk',
    [22] = '..........................ksssdnsssk',
    [23] = '..........................kssssssssk',
    [24] = '..........................ksssddsssk',
    [25] = '..........................kssssssssk',
    [26] = '..........................kssssssssk',
    [27] = '...........................kssssssk',
    [28] = '...........................kssssssk',
    [29] = '............................kssssk',
    -- gola alta estreita subindo o pescoço (âncora)
    [30] = '............................kzzzzk',
    [31] = '............................kzzzzk',
    [32] = '............................kzzzzk',
    [33] = '............................kzzzzk',
    [34] = '...........................kzzttzzk',
    [35] = '...........................kzzttzzk',
    -- ombros estreitos: sobrecasaco 'c', túnica pérola 't' no peito
    [36] = '.........................kcccccccccccccccck',
    [37] = '........................kcccccccccccccccccck',
    [38] = '.........................kcccttttttttttccck',
    [39] = '.........................kcccttttttttttccck',
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
    -- punhos de couro 'r' enrolados na borda da manga
    [54] = '...................krrk..kcccttttttttttccck..krrk',
    [55] = '...................krrk..kcccttttttttttccck..krrk',
    [56] = '...................krrk..kcccttttttttttccck..krrk',
    -- mãos finas com dedos compridos 's' soltos nas laterais
    [57] = '...................kssk..kcccttttttttttccck..kssk',
    [58] = '...................kssk..kcccttttttttttccck..kssk',
    [59] = '...................kssk..kcccttttttttttccck..kssk',
    [60] = '...................ksssk..kcccttttttttttccck..ksssk',
    [61] = '...................ksssk..kcccttttttttttccck..kkkk',
    [62] = '...................ksssk..kcccttttttttttccck',
    [63] = '...................kkkk...kttttttttttttttttk',
    [64] = '.........................kttttttttttttttttk',
    [65] = '.........................kttttttttttttttttk',
    [66] = '.........................kttttttttttttttttk',
    [67] = '.........................kttttttttttttttttk',
    [68] = '.........................kttttttttttttttttk',
    [69] = '.........................kttttttttttttttttk',
    [70] = '.........................kttttttttttttttttk',
    [71] = '.........................kttttttttttttttttk',
    -- fenda frontal da túnica (âncora): abre até abaixo do joelho
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
    -- botas finas, sola reforçada 'o'
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

-- faixa horizontal de trabalho 'f' na cintura (âncora do ato de
-- manutenção: o pano escapa da faixa no trabalho)
local band = {
    [54] = '............................kfffffffffffk',
    [55] = '............................kfffffffffffk',
}
local garb = R(band)

-- f3: olha para cima — cabeça sobe 1px (queixo sai da gola)
local gesto = patch(shift(body, -1, 8, 34), {
    [33] = '............................kssssk',
    [34] = '............................kzzzzk',
})
-- f4: pisca
local respiroPisca = shift(patch(body, {
    [18] = '......................ksskksssddsskkssk',
}), 1, 30, 62)

return {
    name = 'npc_aurel_s', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 3, h = 11 },   -- pele dourada
        d = { ramp = 'skin', step = 1, h = 10 },
        e = { spec = 'ink', h = 12 },
        n = { ramp = 'skin', step = 2, h = 11 },
        g = { ramp = 'hair', step = 4, h = 11 },   -- grisalho varrido
        G = { ramp = 'hair', step = 3, h = 12 },
        z = { ramp = 'plaster', step = 5, h = 7 }, -- gola alta pérola
        t = { ramp = 'plaster', step = 3, h = 5 }, -- túnica pérola
        c = { ramp = 'iron', step = 3, h = 6 },    -- sobrecasaco carvão
        r = { ramp = 'earth', step = 3, h = 7 },   -- punho de couro
        f = { ramp = 'earth', step = 4, h = 5 },   -- faixa de trabalho
        p = { ramp = 'iron', step = 4, h = 4 },    -- calça
        b = { ramp = 'earth', step = 2, h = 2 },   -- bota
        o = { ramp = 'earth', step = 4, h = 2 },   -- sola reforçada
        B = { ramp = 'earth', step = 4, h = 3 },
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body), R(shift(body, 1, 30, 62)), R(gesto), R(respiroPisca),
        } },
        { name = 'band', h = 6, albedo = { garb, garb, garb, garb } },
    },
}
