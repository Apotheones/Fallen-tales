-- V09 NPC_DORO_N — Doro de costas (norte), 64x96 feet, 4f.
-- De costas: crânio raspado com barba prata contornando a nuca
-- (orelha a orelha), pescoço largo, colete com costura 'r' nas
-- costas, avental 'a' atrás das coxas até os joelhos, faixa 'F'
-- continua na diagonal de trás. Mesma geometria do _s.
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

local body = {
    -- nuca raspada: restolho 'h' espesso em cima, pele na nuca,
    -- filete de barba prata 'g' contornando as laterais do maxilar
    [9]  = '................................khhkhkhkk',
    [10] = '...............................khhhhshhsssk',
    [11] = '..............................khhhhhhssssssk',
    [12] = '..............................khhhhssssssssk',
    [13] = '..............................khshhssssssssk',
    [14] = '..............................ksshhssssssssk',
    [15] = '..............................kssssssssssssk',
    [16] = '..............................kssssssssssssk',
    [17] = '..............................kssssssssssssk',
    [18] = '..............................ksdssssssssdsk',
    [19] = '..............................kssssssssssssk',
    [20] = '..............................kssssssssssssk',
    [21] = '..............................kssssssssssssk',
    [22] = '..............................kgssssssssssgk',
    [23] = '..............................kggsddssssgggk',
    [24] = '..............................kggggggggggggk',
    [25] = '..............................kggGGgggGGgggk',
    [26] = '..............................kgggghhhhggggk',
    [27] = '..............................kgggghhhhggggk',
    [28] = '..............................kgggggggggggk',
    [29] = '...............................kggggggggk',
    [30] = '...............................kggggggk',
    [31] = '................................ksssssk',
    [32] = '................................ksssssk',
    [33] = '................................ksssssk',
    [34] = '................................ksssssk',
    [35] = '.................................kssssk',
    [36] = '.................................kssssk',
    [37] = '.................................kssssk',
    -- ombros: mesmas colunas do _s; colete 'v' com costura 'r'
    -- central das costas + 'v' ao redor
    [38] = '.........................kllllllllllllllllllllk',
    [39] = '.......................klllllllllllllllllllllllk',
    [40] = '......................kllllllllllllllllllllllllk',
    [41] = '....................kllllllllllllllllllllllllllk',
    [42] = '..................klllllvvvvvvvvvvvvvvvvvvvvlllllk',
    [43] = '..................klllvvvvvvvvvvrrvvvvvvvvvvlllk',
    [44] = '..................klllvvvvvvvvvvrrvvvvvvvvvvlllk',
    [45] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [46] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [47] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [48] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [49] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [50] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [51] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [52] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [53] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [54] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [55] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [56] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [57] = '...................kllvvvvvvvvvvrrvvvvvvvvvvvllk',
    [58] = '..............ksssskkllvvvvvvvvvrrvvvvvvvvvvvllkkssssk',
    [59] = '..............ksdsskkllvvvvvvvvvrrvvvvvvvvvvvllkkssdsk',
    [60] = '..............ksssskkpppppppppppppppppppppppppkksssssk',
    [61] = '..............ksssskkpppppppppppppppppppppppppkksssssk',
    [62] = '..............kkkkk.kpppppppppppppppppppppppppk.kkkkk',
    [63] = '.......................kppppppppk...kppppppppk',
    [64] = '.......................kppppppppk...kppppppppk',
    [65] = '.......................kppppppppk...kppppppppk',
    [66] = '.......................kppppppPpk...kppppppppk',
    [67] = '.......................kppppppPpk...kppppppppk',
    [68] = '.......................kppppppPpk...kppppppppk',
    [69] = '.......................kppppppPpk...kppppppppk',
    [70] = '.......................kppppppPpk...kppppppppk',
    [71] = '.......................kppppppPpk...kppppppppk',
    [72] = '.......................kppppppPpk...kppppppppk',
    [73] = '.......................kppppppPpk...kppppppppk',
    [74] = '.......................kpppppPppk...kppppppPpk',
    [75] = '.......................kpppppPppk...kppppppPpk',
    [76] = '.......................kpppppPppk...kppppppPpk',
    [77] = '........................kpppppPpk...kpppppPpk',
    [78] = '........................kpppppPpk...kpppppPpk',
    [79] = '........................kpppppPpk...kpppppPpk',
    [80] = '........................kpppppPpk...kpppppPpk',
    [81] = '........................kpppppPpk...kpppppPpk',
    [82] = '........................kpppppPpk...kpppppPpk',
    [83] = '........................kpppppPk...kpppppPk',
    [84] = '........................kDDDDDkk...kDDDDDkk',
    [85] = '........................kDDDDbk....kDDDDbk',
    [86] = '........................kbbbbbbk...kbbbbbbk',
    [87] = '........................kbbbbbbk...kbbbbbbk',
    [88] = '........................kbbbbbbk...kbbbbbbk',
    [89] = '........................kbbbbbbbk..kbbbbbbbk',
    [90] = '........................kbbbbbbbk..kbbbbbbbk',
    [91] = '........................kbbbbbBbk..kbbbbBbbk',
    [92] = '........................kbbbbbBbk..kbbbbBbbk',
    [93] = '........................kooooobk...koooooobk',
    [94] = '........................kkkkkkkk...kkkkkkkkk',
}

-- avental de costas: cai atrás das coxas até os joelhos; bainha 'c'
local garb = {
    [63] = '.......................kAaAAAAAAAAaAk',
    [64] = '.......................kAaAAAAAAAAaAk',
    [65] = '.......................kAaAAAAAAAAaAk',
    [66] = '.......................kAaAAAAAAAAaAk',
    [67] = '.......................kAaAAAAAAAAaAk',
    [68] = '.......................kAaAAAAAAAAaAk',
    [69] = '.......................kAaAAAAAAAAaAk',
    [70] = '.......................kAaAAAAAAAAaAk',
    [71] = '.......................kAaAAAAAAAAaAk',
    [72] = '.......................kAaAAAAAAAAaAk',
    [73] = '.......................kAaAAAAAAAAaAk',
    [74] = '.......................kAaAAAAAAAAaAk',
    [75] = '.......................kAaAAAAAAAAaAk',
    [76] = '.......................kcaAcacacacaAck',
    [77] = '.......................kccacacacacacck',
    [78] = '.......................kccccccccccccck',
}

-- faixa diagonal vista de costas: mesmo lado, continua a descer
local strap = {
    [42] = '........................................kFFFk',
    [43] = '........................................kFFFk',
    [44] = '.......................................kFFFk',
    [45] = '.......................................kFFFk',
    [46] = '......................................kFFFk',
    [47] = '......................................kFFFk',
    [48] = '.....................................kFFFk',
    [49] = '.....................................kFFFk',
    [50] = '....................................kFFFk',
    [51] = '....................................kFFFk',
    [52] = '...................................kFFFk',
    [53] = '...................................kFFFk',
    [54] = '..................................kFFFk',
    [55] = '..................................kFFFk',
    [56] = '.................................kFFFk',
    [57] = '.................................kFFFk',
    [58] = '................................kFFFk',
    [59] = '................................kFFFk',
    [60] = '...............................kFFFk',
    [61] = '...............................kFFk',
}

local garbAll = overlay(R(strap), R(garb))

local gesto = patch(shift(body, 1, 8, 37), {
    [59] = '..............kddsskkllvvvvvvvvvrrvvvvvvvvvvvllkkssddk',
    [60] = '..............kddsskkpppppppppppppppppppppppppkkssddsk',
})
local respiroPisca = shift(body, 1, 38, 60)

return {
    name = 'npc_doro_n', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 2, h = 11 },
        d = { ramp = 'skin', step = 1, h = 10 },
        e = { spec = 'ink', h = 12 },
        g = { ramp = 'plaster', step = 5, h = 11 },
        G = { ramp = 'plaster', step = 6, h = 12 },
        h = { ramp = 'hair', step = 2, h = 11 },
        n = { ramp = 'skin', step = 3, h = 11 },
        l = { ramp = 'plaster', step = 3, h = 6 },
        v = { ramp = 'earth', step = 4, h = 6 },
        r = { ramp = 'earth', step = 2, h = 5 },
        p = { ramp = 'iron', step = 3, h = 4 },
        P = { ramp = 'iron', step = 2, h = 3 },
        D = { ramp = 'earth', step = 1, h = 2 },
        b = { ramp = 'earth', step = 2, h = 2 },
        o = { ramp = 'earth', step = 5, h = 2 },
        B = { ramp = 'earth', step = 4, h = 3 },
        a = { ramp = 'clothWarm', step = 3, h = 6 },
        A = { ramp = 'clothWarm', step = 2, h = 6 },
        c = { ramp = 'clothWarm', step = 1, h = 5 },
        F = { ramp = 'bone', step = 4, h = 8 },
        w = { ramp = 'gold', step = 4, h = 7 },
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body), R(shift(body, 1, 38, 60)), R(gesto), R(respiroPisca),
        } },
        { name = 'garb', h = 7, albedo = { garbAll, garbAll, garbAll, garbAll } },
    },
}
