-- AUREL — idle NORTE (de costas), 64x96, origem nos pés, 4f.
-- f1 repouso | f2 respiro | f3 GESTO: cabeça sobe 1px (olha o Marco
-- acima) + pano desdobra 1px | f4 respiro + cabeça assenta.
-- Costas: cabelo grisalho puxado para trás cobre a nuca (âncora
-- "cabelo claro recuado" mantida: massa clara 'g' sem rosto); gola
-- 'z' vista por trás; sobrecasaca 'c' fecha o dorso inteiro; faixa
-- 'f' continua na cintura; túnica 't' desce com costura 'u' central;
-- pano 'p' agora pendurado na mão direita (lado direito da tela).

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
local function patch(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do t[r] = s end
    return t
end

local body = {
    [8]  = '............................kkkkkk',
    [9]  = '...........................kggggggk',
    [10] = '..........................kggggggggk',
    [11] = '..........................kggGggggggk',
    [12] = '..........................kggggggggk',
    [13] = '..........................kggggggggk',
    [14] = '..........................kggggggggk',
    [15] = '..........................kggggggggk',
    [16] = '..........................kggggggggk',
    [17] = '......................kggkkggggggggkkggk',
    [18] = '......................kggkkggggggggkkggk',
    [19] = '......................kggkkggggggggkkggk',
    [20] = '.......................kk.kggggggggk.kk',
    [21] = '..........................kggggggggk',
    [22] = '..........................kggggggggk',
    [23] = '..........................kggggggggk',
    [24] = '..........................kggggggggk',
    [25] = '..........................kggggggggk',
    [26] = '...........................kggggggk',
    [27] = '...........................kggggggk',
    [28] = '............................kggggk',
    [29] = '............................kssssk',
    [30] = '............................kzzzzk',
    [31] = '............................kzzzzk',
    [32] = '............................kzzzzk',
    [33] = '............................kzzzzk',
    [34] = '...........................kzzzzzzk',
    [35] = '...........................kzzzzzzk',
    [36] = '.........................kcccccccccccccccck',
    [37] = '........................kcccccccccccccccccck',
    [38] = '.........................kcccccccccccccccck',
    [39] = '.........................kcccccccccccccccck',
    [40] = '...................kcck..kcccccccccccccccck..kcck',
    [41] = '...................kcck..kcccccccccccccccck..kcck',
    [42] = '...................kcck..kcccccccccccccccck..kcck',
    [43] = '...................kcck..kcccccccccccccccck..kcck',
    [44] = '...................kcck..kcccccccccccccccck..kcck',
    [45] = '...................kcck..kcccccccccccccccck..kcck',
    [46] = '...................kcck..kcccccccccccccccck..kcck',
    [47] = '...................kcck..kcccccccccccccccck..kcck',
    [48] = '...................kcck..kcccccccccccccccck..kcck',
    [49] = '...................kcck..kcccccccccccccccck..kcck',
    [50] = '...................kcck..kcccccccccccccccck..kcck',
    [51] = '...................kcck..kcccccccccccccccck..kcck',
    [52] = '...................kcck..kcccccccccccccccck..kcck',
    [53] = '...................kcck..kcccccccccccccccck..kcck',
    [54] = '...................krrk..kcccccccccccccccck..krrk',
    [55] = '...................krrk..kcccccccccccccccck..krrk',
    [56] = '...................krrk..kcccccccccccccccck..krrk',
    [57] = '...................kssk..kcccccccccccccccck..kssk',
    [58] = '...................kssk..kcccccccccccccccck..kssk',
    [59] = '...................kssk..kcccccccccccccccck..kssk',
    [60] = '...................kssk..kcccccccccccccccck..kppk',
    [61] = '...................kkkk..kcccccccccccccccck..kppk',
    [62] = '.........................kcccccccccccccccck..kppk',
    [63] = '.........................kttttttttttttttttk..kppk',
    [64] = '.........................kttttttttttttttttk..kppk',
    [65] = '.........................kttttttttttttttttk..kppk',
    [66] = '.........................kttttttttttttttttk...kk',
    [67] = '.........................kttttttttttttttttk',
    [68] = '.........................kttttttttttttttttk',
    [69] = '.........................kttttttttttttttttk',
    [70] = '.........................kttttttttttttttttk',
    [71] = '.........................kttttttttttttttttk',
    -- costura central da túnica por trás
    [72] = '.........................ktttttttuutttttttk',
    [73] = '.........................ktttttttuutttttttk',
    [74] = '.........................ktttttttuutttttttk',
    [75] = '.........................ktttttttuutttttttk',
    [76] = '.........................ktttttttuutttttttk',
    [77] = '.........................ktttttttuutttttttk',
    [78] = '.........................ktttttttuutttttttk',
    [79] = '.........................ktttttttuutttttttk',
    [80] = '.........................ktttttttuutttttttk',
    [81] = '.........................ktttttttuutttttttk',
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

local band = {
    [54] = '............................kffffffffffk',
    [55] = '............................kffffffffffk',
}

-- f3: olha o Marco acima — cabeça sobe 1px (pescoço reposto no vão);
-- pano desdobra 1px à direita.
local gesto = patch(shift(body, -1, 8, 29), {
    [29] = '............................kssssk',
    [61] = '...................kkkk..kcccccccccccccccck..kpppk',
    [62] = '.........................kcccccccccccccccck..kpppk',
    [63] = '.........................kttttttttttttttttk..kpppk',
    [64] = '.........................kttttttttttttttttk..kpppk',
    [65] = '.........................kttttttttttttttttk..kpppk',
    [66] = '.........................kttttttttttttttttk...kkk',
})
-- f4: respiro com a cabeça assentando 1px a mais (sem olhos de costas).
local respiroAssenta = shift(shift(body, 1, 8, 28), 1, 36, 56)

return {
    name = 'npc_aurel_n',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},
        S = {ramp = 'skin', step = 4, h = 12},
        d = {ramp = 'skin', step = 2, h = 10},
        e = {spec = 'ink', h = 12},
        g = {ramp = 'iron', step = 5, h = 11},
        G = {ramp = 'iron', step = 6, h = 12},
        z = {ramp = 'sea', step = 3, h = 9},
        c = {ramp = 'sea', step = 2, h = 7},
        t = {ramp = 'plaster', step = 4, h = 6},
        u = {ramp = 'plaster', step = 3, h = 5},
        f = {ramp = 'earth', step = 3, h = 8},
        r = {ramp = 'earth', step = 2, h = 6},
        p = {ramp = 'bone', step = 5, h = 7},
        b = {ramp = 'earth', step = 2, h = 2},
        o = {ramp = 'earth', step = 4, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 36, 56)),
            R(gesto),
            R(respiroAssenta),
        }},
        {name = 'trab', h = 8, albedo = {
            R(band),
            R(band),
            R(band),
            R(band),
        }},
    },
}
