-- POSTO DE VIGIA — prop de chão, 64x96, origem nos pés.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, posto do mirante):
-- armaiote de madeira — duas colunas e travessa — com o escudo da
-- ronda pendurado num pino e a lança encostada. Função, não ornamento:
-- é o lugar onde o vigia deixa o equipamento entre um turno e outro.
-- Relevo: travessa 13-14, escudo 10-12, colunas 8-9, lança 9, chão 1-2.

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

-- armaiote: travessa alta com fio de luz e mortais, colunas com
-- cintas de ferro na junção, pés na terra
local armaiote = {
    [20] = '...........WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk',
    [21] = '...........wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [22] = '...........wwwwvwwwwwwwwwwvwwwwwwwwwwvwwwwwwwwwwwk',
    [23] = '...........wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [24] = '...........kvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvk',
    -- junção: cinta de ferro abraçando coluna e travessa
    [25] = '...........kiiik................................kiik',
    [26] = '...........kiiik................................kiik',
    [27] = '...........kWwwk................................kWwwk',
    [28] = '...........kWwwk................................kWwwk',
    [29] = '...........kwwvk................................kwwvk',
    [30] = '...........kwwvk................................kwwvk',
    [31] = '...........kWwwk................................kWwwk',
    [32] = '...........kWwwk................................kWwwk',
    [33] = '...........kwwvk................................kwwvk',
    [34] = '...........kwwvk................................kwwvk',
    [35] = '...........kWwwk................................kWwwk',
    [36] = '...........kWwwk................................kWwwk',
    [37] = '...........kwwvk................................kwwvk',
    [38] = '...........kwwvk................................kwwvk',
    [39] = '...........kWwwk................................kWwwk',
    [40] = '...........kWwwk................................kWwwk',
    [41] = '...........kwwvk................................kwwvk',
    [42] = '...........kwwvk................................kwwvk',
    [43] = '...........kWwwk................................kWwwk',
    [44] = '...........kWwwk................................kWwwk',
    [45] = '...........kwwvk................................kwwvk',
    [46] = '...........kwwvk................................kwwvk',
    [47] = '...........kWwwk................................kWwwk',
    [48] = '...........kWwwk................................kWwwk',
    [49] = '...........kwwvk................................kwwvk',
    [50] = '...........kwwvk................................kwwvk',
    [51] = '...........kWwwk................................kWwwk',
    [52] = '...........kWwwk................................kWwwk',
    [53] = '...........kwwvk................................kwwvk',
    [54] = '...........kwwvk................................kwwvk',
    [55] = '...........kWwwk................................kWwwk',
    [56] = '...........kWwwk................................kWwwk',
    [57] = '...........kwwvk................................kwwvk',
    [58] = '...........kwwvk................................kwwvk',
    [59] = '...........kWwwk................................kWwwk',
    [60] = '...........kWwwk................................kWwwk',
    [61] = '...........kwwvk................................kwwvk',
    [62] = '...........kwwvk................................kwwvk',
    [63] = '...........kWwwk................................kWwwk',
    [64] = '...........kWwwk................................kWwwk',
    [65] = '...........kwwvk................................kwwvk',
    [66] = '...........kwwvk................................kwwvk',
    [67] = '...........kWwwk................................kWwwk',
    [68] = '...........kWwwk................................kWwwk',
    [69] = '...........kwwvk................................kwwvk',
    [70] = '...........kwwvk................................kwwvk',
    [71] = '...........kWwwk................................kWwwk',
    [72] = '...........kWwwk................................kWwwk',
    [73] = '...........kwwvk................................kwwvk',
    [74] = '...........kwwvk................................kwwvk',
    [75] = '...........kWwwk................................kWwwk',
    [76] = '...........kWwwk................................kWwwk',
    [77] = '...........kwwvk................................kwwvk',
    [78] = '...........kwwvk................................kwwvk',
    [79] = '...........kWwwk................................kWwwk',
    [80] = '...........kWwwk................................kWwwk',
    [81] = '...........kwwvk................................kwwvk',
    [82] = '...........kwwvk................................kwwvk',
    [83] = '...........kWwwk................................kWwwk',
    [84] = '...........kWwwk................................kWwwk',
    [85] = '...........kwwvk................................kwwvk',
    [86] = '...........kwwvk................................kwwvk',
    [87] = '...........kqvk..................................kqvk',
    [88] = '...........kqqk..................................kqqk',
    [89] = '..........egeek.....e......e....e.......e.....egeek',
    [90] = '.........egegge..e.....e....e.....e...e.....egegge',
    [91] = '........egggee....e.....e.....e....e.....egggee',
    [92] = '........eggee....e.....e....e......e.....eggee',
    [93] = '.........eee.....e.....e....e.....e.....eee',
}

-- escudo pendurado no pino da travessa: correia 'r', aro de ferro 'i',
-- face de tábuas 'u' com juntas 'v' e umbo 'o'
local escudo = {
    [25] = '.............................r',
    [26] = '.............................r',
    [27] = '............................r.r',
    [28] = '............................rrr',
    [29] = '...........................iiiii',
    [30] = '.........................iiiiiiiii',
    [31] = '.......................iiiUUUUUUiii',
    [32] = '......................iiUUuUUuUUuUii',
    [33] = '.....................iiUUuUUuUUuUUUii',
    [34] = '....................iiUUUuUUuUUuUUUUii',
    [35] = '....................iUUUUuUUuUUuUUUUUi',
    [36] = '...................iiUUUUuUUuUUuUUUUUii',
    [37] = '...................iUUUUUuUUuUUuUUUUUUi',
    [38] = '...................iUvUUUuUUuUUuUUUvUUi',
    [39] = '...................iUUUUUuUUuUUuUUUUUUi',
    [40] = '...................iUUUUUuUUuUUuUUUUUUi',
    [41] = '...................iUUUUUuUUoUUuUUUUUUi',
    [42] = '...................iUvUUUuUoooUuUUUvUUi',
    [43] = '...................iUUUUUuUooioUuUUUUUi',
    [44] = '...................iUUUUUuUoiooUuUUUUUi',
    [45] = '...................iUvUUUuUoooUuUUUvUUi',
    [46] = '...................iUUUUUuUUoUUuUUUUUUi',
    [47] = '...................iUUUUUuUUuUUuUUUUUUi',
    [48] = '...................iUUUUUuUUuUUuUUUUUUi',
    [49] = '...................iiUUUUuUUuUUuUUUUUii',
    [50] = '....................iUUUUuUUuUUuUUUUUi',
    [51] = '....................iiUUUuUUuUUuUUUii',
    [52] = '.....................iiUUuUUuUUuUUii',
    [53] = '......................iiUUuUUuUUii',
    [54] = '........................iiUUUUUii',
    [55] = '..........................iiiii',
}

-- lança encostada na coluna direita: haste fina em diagonal,
-- ponta folha de ferro, contra-peso na base
local function lanca()
    local t = {}
    for r = 1, 96 do
        local row = {}
        for x = 1, 64 do row[x] = '.' end
        t[r] = row
    end
    -- ponta folha (rows 16-21) em cima da haste
    t[16][45] = 't'; t[17][44] = 't'; t[17][45] = 't'; t[17][46] = 't'
    t[18][44] = 't'; t[18][45] = 'T'; t[18][46] = 't'
    t[19][44] = 't'; t[19][45] = 't'; t[19][46] = 't'
    t[20][45] = 't'; t[21][45] = 'a'
    -- haste: diagonal de (45,22) a (54,90)
    for r = 22, 90 do
        local x = 45 + math.floor((r - 22) * 9 / 68 + 0.5)
        t[r][x] = 'a'
        if r % 9 == 4 then t[r][x - 1] = 'a' end -- engrossa em nós
    end
    -- contra-peso de ferro na base
    t[91][54] = 'i'; t[91][55] = 'i'
    t[92][53] = 'i'; t[92][54] = 'i'; t[92][55] = 'i'
    local out = {}
    for r = 1, 96 do out[r] = table.concat(t[r]) end
    return table.concat(out, '\n')
end

return {
    name = 'posto_vigia',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 6},
        -- armaiote
        W = {ramp = 'wood', step = 5, h = 9},
        w = {ramp = 'wood', step = 4, h = 8},
        v = {ramp = 'wood', step = 2, h = 8},
        q = {ramp = 'wood', step = 2, h = 4},
        i = {ramp = 'iron', step = 3, h = 10},
        -- escudo: correia, aro, tábuas, juntas, umbo
        r = {ramp = 'earth', step = 2, h = 11},
        U = {ramp = 'wood', step = 4, h = 11},
        u = {ramp = 'wood', step = 3, h = 11},
        o = {ramp = 'iron', step = 5, h = 12},
        -- lança: haste e ponta folha
        a = {ramp = 'wood', step = 3, h = 9},
        t = {ramp = 'iron', step = 4, h = 14},
        T = {ramp = 'iron', step = 6, h = 14},
        -- chão
        g = {ramp = 'moss', step = 3, h = 2},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'armaiote', h = 8, albedo = R(armaiote)},
        {name = 'escudo', h = 11, albedo = R(escudo)},
        {name = 'lanca', h = 9, albedo = lanca()},
    },
}
