-- V09 NPC_DORO_E — Doro carpinteiro/coveiro (C03) em perfil LESTE,
-- 64x96 feet, 4f: repouso / respiro / f3 olha a peça (cabeça +1,
-- punho fecha) / f4 pisca. Padrão C01: massas com sombra interna e
-- borda viva, não preenchimento chapado.
-- Âncoras: ombros LARGOS (22 col de tronco) | cabeça clara c/ barba
-- curta prata-ferro desgrenhada | faixa diagonal do avental 'F'.
-- Corpo: 181cm largo, barriga moderada, braços grossos com mãos
-- grandes (juntas 'd' marcadas); pele marrom escura.
-- Roupa: linho cinza 'l', colete lã 'v' com borda sombria 'r',
-- avental encerado curto 'a' c/ faixa diagonal 'F' e bainha com
-- nós 'c'; calça azul-carvão 'p'; botas largas sola grossa.
-- Detalhes: lápis 'n' acima da orelha (f3 aponta), metro de
-- madeira 'w' dobrado no bolso do avental.
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
local function overlayRows(ga, gb)
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

local body = {
    -- crânio raspado com restolho 'h' irregular; cara retangular,
    -- sobrancelha cinza 'g' grossa, olho miúdo 'e', nariz achatado 'n'
    [8]  = '..............................khhkhkk',
    [9]  = '.............................khhhhhksk',
    [10] = '............................khhkhhssssk',
    [11] = '............................khshssssssk',
    [12] = '............................khssssssssk',
    [13] = '............................khsssssssssk',
    [14] = '............................kssssgggssk',
    [15] = '............................ksssssggsssk',
    [16] = '............................kssssseessk',
    [17] = '............................kssssssssnsk',
    [18] = '............................ksssdssnnnsk',
    [19] = '............................ksssdsnnnnnk',
    [20] = '............................kssssddsssk',
    [21] = '............................ksssssddsdk',
    -- barba curta prata: massa 'G' com pontas 'g' desgrenhadas e fios
    -- escuros 'h' quebrando o bloco — desce do maxilar ao peito
    [22] = '............................ksssggggsk',
    [23] = '............................ksggggggggk',
    [24] = '............................kggGgggGggk',
    [25] = '...........................kggGgGgggggk',
    [26] = '...........................kgggGgggGgk',
    [27] = '...........................kgGgggggggk',
    [28] = '...........................kggggggggk',
    [29] = '............................kggggggk',
    [30] = '............................kgghggk',
    [31] = '.............................kssk',
    -- tronco largo: manga linho cinza nas bordas, colete 'v' no miolo
    -- com borda de sombra 'r' no lado longe; barriga leve a partir
    -- da linha 48 (o contorno abre 1 col a mais)
    [32] = '...........................klllllllllllk',
    [33] = '.........................klllllllllllllllk',
    [34] = '........................kllllllllllllllllk',
    [35] = '.......................kllllllllllllllllllk',
    [36] = '.......................klllvvvvvvvvvvvvlllllk',
    [37] = '.......................kllvvvvvvvvvvvvvvlllllk',
    [38] = '.......................kllvvvvvvvvvvvvvvlllllk',
    [39] = '......................klllvrvvvvvvvvvvvvvlllllk',
    [40] = '......................klllrvvvvvvvvvvvvvlllllk',
    [41] = '......................klllrvvvvvvvvvvvvvlllllk',
    [42] = '......................klllrvvvvvvvvvvvvvlllllk',
    [43] = '......................klllrvvvvvvvvvvvvvlllllk',
    [44] = '......................klllrvvvvvvvvvvvvvlllllk',
    [45] = '......................klllrvvvvvvvvvvvvvlllllk',
    [46] = '......................klllrvvvvvvvvvvvvvvlllllk',
    [47] = '......................klllrvvvvvvvvvvvvvvlllllk',
    [48] = '......................klllrvvvvvvvvvvvvvvvlllllk',
    [49] = '......................klllrvvvvvvvvvvvvvvvlllllk',
    [50] = '......................klllrvvvvvvvvvvvvvvvlllllk',
    [51] = '......................klllrvvvvvvvvvvvvvvvlllllk',
    [52] = '......................klllrvvvvvvvvvvvvvvvllllk',
    [53] = '......................klllrvvvvvvvvvvvvvvvlllk',
    -- braço da frente desce fora do avental; braço de trás 'd' sombra
    [54] = '.....................kdddk.rvvvvvvvvvvvvvlllk',
    [55] = '.....................kdddk.vvvvvvvvvvvvvklllk',
    [56] = '.....................kdddk.vvvvvvvvvvvvvklllk',
    [57] = '.....................kdddk.vvvvvvvvvvvvvklllk',
    -- mão grande à frente: dorso 's' largo com juntas 'd' fileira
    [58] = '.....................kdddk.vvvvvvvvvvvvksssssk',
    [59] = '.....................kdddk.vvvvvvvvvvvkssdsddsk',
    [60] = '......................kkk.vvvvvvvvvvvvkssddssk',
    [61] = '......................kkk.vvvvvvvvvvvvksssssk',
    [62] = '......................kkk.vvvvvvvvvvvvkkkkkk',
    -- calças azul-carvão: longe 'P', perto 'p' — canela afunilada
    [63] = '.........................kPPPPPkpppppppppk',
    [64] = '.........................kPPPPPkpppppppppk',
    [65] = '.........................kPPPPPkpppppppppk',
    [66] = '.........................kPPPPPkpppppppppk',
    [67] = '.........................kPPPPPkpppppppppk',
    [68] = '.........................kPPPPPkpppppppppk',
    [69] = '.........................kPPPPPkpppppppppk',
    [70] = '.........................kPPPPPkpppppppppk',
    [71] = '.........................kPPPPPkpppppppppk',
    [72] = '.........................kPPPPPkpppppppppk',
    [73] = '.........................kPPPPPkpppppppppk',
    [74] = '.........................kPPPPPkppppppppk',
    [75] = '.........................kPPPPk.ppppppppk',
    [76] = '.........................kPPPPk.ppppppppk',
    [77] = '.........................kPPPPk.ppppppppk',
    [78] = '.........................kPPPPk.ppppppppk',
    [79] = '.........................kPPPPk.pppppppk',
    [80] = '.........................kPPPPk.pppppppk',
    [81] = '.........................kPPPPk.pppppppk',
    [82] = '.........................kPPPPk.ppppppk',
    [83] = '.........................kPPPPk.ppppppk',
    -- botas largas com sola grossa 'o' e biqueira 'B'
    [84] = '.........................kDDDDk.bbbbbbbk',
    [85] = '.........................kDDDDk.bbbbbbbk',
    [86] = '.........................kDDDDk.bbbbbbbk',
    [87] = '.........................kDDDDk.bbbbbbbk',
    [88] = '.........................kDDDDk.bbbbbbbk',
    [89] = '.........................kDDDDk.bbbbbbbbk',
    [90] = '.........................kDDDDk.bbbbbbbbbk',
    [91] = '.........................kDDDDk.bbbbbbbbbk',
    [92] = '.........................kDDDDk.bbbbbbBbbk',
    [93] = '.........................koookkooobboooooBk',
    [94] = '.........................kkkkkkkkkkkkkkkkkkk',
}

-- camada do avental: peito curto + faixa diagonal 'F' descendo à
-- direita + metro 'w' dobrado saindo do bolso lateral
local garb = {
    -- peito do avental na borda direita do tronco
    [46] = '..............................kAAk',
    [47] = '..............................kAAAAk',
    [48] = '.............................kAAAAAAk',
    [49] = '.............................kAaAAAAk',
    [50] = '.............................kAaAAAAAk',
    [51] = '.............................kAaAAAAAk',
    [52] = '............................kAaAAAAAAk',
    [53] = '............................kAaAAAAAAk',
    [54] = '...........................kAaAAAAAAAk',
    [55] = '...........................kAaAAAAAAAk',
    [56] = '...........................kAaAAAAAAAk',
    [57] = '..........................kAaAAAAAAAAk',
    [58] = '..........................kAaAAAAAAAAk',
    [59] = '..........................kAaAAAAAAk',
    [60] = '..........................kcaAAAAAAk',
    [61] = '..........................kccAAAAAAk',
    [62] = '..........................kcccccck',
}

local strap = {
    [36] = '...............................kkk',
    [37] = '...............................kFFk',
    [38] = '................................kFFk',
    [39] = '................................kFFk',
    [40] = '.................................kFFk',
    [41] = '.................................kFFk',
    [42] = '..................................kFFk',
    [43] = '..................................kFFk',
    [44] = '...................................kFFk',
    [45] = '...................................kFFk',
    [46] = '....................................kFFk',
    [47] = '....................................kFFk',
    [48] = '.....................................kFFk',
    [49] = '.....................................kFFk',
    [50] = '......................................kFFk',
    [51] = '......................................kFFk',
    [52] = '.......................................kFFk',
    [53] = '........................................kFFk',
    [54] = '........................................kFFk',
    [55] = '.........................................kFFkwk',
    [56] = '.........................................kFFkwk',
    [57] = '..........................................kFFkwwk',
    [58] = '..........................................kFFkkwk',
    [59] = '..........................................kFFkkkk',
}

local garbAll = overlayRows(R(strap), R(garb))

local gesto = patch(shift(body, 1, 8, 34), {
    [11] = '............................knhssssssssk',
    [58] = '.....................kdddk.vvvvvvvvvvvkssddssk',
    [59] = '.....................kdddk.vvvvvvvvvvvkssddssk',
    [60] = '......................kkk.vvvvvvvvvvvvksssssk',
})

local respiroPisca = shift(patch(body, {
    [16] = '............................ksssssddssk',
    [17] = '............................kssssssddnsk',
}), 1, 35, 60)

return {
    name = 'npc_doro_e', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 2, h = 11 },
        S = { ramp = 'skin', step = 3, h = 12 },
        d = { ramp = 'skin', step = 1, h = 10 },
        e = { spec = 'ink', h = 12 },
        g = { ramp = 'plaster', step = 5, h = 11 },
        G = { ramp = 'plaster', step = 6, h = 12 },
        h = { ramp = 'hair', step = 2, h = 11 },
        n = { ramp = 'gold', step = 3, h = 12 },
        l = { ramp = 'plaster', step = 3, h = 6 },
        v = { ramp = 'earth', step = 4, h = 6 },
        r = { ramp = 'earth', step = 2, h = 5 },
        p = { ramp = 'iron', step = 3, h = 4 },
        P = { ramp = 'iron', step = 2, h = 3 },
        D = { ramp = 'earth', step = 1, h = 2 },
        b = { ramp = 'earth', step = 2, h = 2 },
        o = { ramp = 'earth', step = 5, h = 2 },
        a = { ramp = 'clothWarm', step = 3, h = 6 },
        A = { ramp = 'clothWarm', step = 2, h = 6 },
        c = { ramp = 'clothWarm', step = 1, h = 5 },
        F = { ramp = 'bone', step = 4, h = 8 },
        w = { ramp = 'gold', step = 4, h = 7 },
        B = { ramp = 'earth', step = 4, h = 3 },   -- biqueira
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body), R(shift(body, 1, 35, 60)), R(gesto), R(respiroPisca),
        } },
        { name = 'garb', h = 7, albedo = { garbAll, garbAll, garbAll, garbAll } },
    },
}
