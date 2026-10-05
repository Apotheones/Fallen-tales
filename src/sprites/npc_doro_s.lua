-- V09 NPC_DORO_S — upgrade C01-grade do idle SUL. Mesma geometria do
-- def anterior (punhos em cols 14-19/48-53, tronco 14-52) para o
-- trabalho de bancada (npc_doro_trabalho) continuar assentando.
-- Upgrade: sombra interna 'r' no lado longe do colete, manga com
-- pregas 'd', barba com núcleo G + flecks h + pontas, calça com
-- costura 'P' e afunilamento, bota com biqueira 'B' e sola 'o'.
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
    -- crânio raspado, restolho 'h' nas laterais e ninho no topo
    [9]  = '................................khhkhkkk',
    [10] = '...............................khshshsssssk',
    [11] = '..............................ksshssssshssssk',
    [12] = '..............................ksssssssssssssk',
    [13] = '..............................ksssssssssssssk',
    [14] = '..............................ksssssssssssssk',
    [15] = '..............................ksssssssssssssk',
    [16] = '..............................ksssssssssssssk',
    -- sobrancelha grisalha 'g' grossa sobre olhos miúdos 'ee'
    [17] = '..............................ksssggssssggsssk',
    [18] = '..............................kssseegssggeessk',
    [19] = '..............................kssssssssssssssk',
    -- nariz largo achatado com sombra nas asas
    [20] = '..............................ksssssnnnssssssk',
    [21] = '..............................ksssdndnndsssssk',
    [22] = '..............................kssssddddssssssk',
    -- barba prata curta desgrenhada: núcleo G, flecks h, pontas g
    [23] = '..............................ksggggggggggggsk',
    [24] = '..............................kgggGGGGGGGGgggk',
    [25] = '..............................kggGGgGGgGGgGGgk',
    [26] = '..............................kgggghggghgggggk',
    [27] = '..............................kggGGgghghgGgggk',
    [28] = '..............................kgggghggghggggk',
    [29] = '..............................kgggggggggggk',
    [30] = '...............................kgggghgggk',
    [31] = '................................ksssssk',
    [32] = '................................ksssssk',
    [33] = '................................ksssssk',
    [34] = '................................ksssssk',
    [35] = '.................................kssssk',
    [36] = '.................................kssssk',
    [37] = '.................................kssssk',
    -- ombros largos: linho 'l' nas bordas c/ prega 'd' na dobra do
    -- braço; colete 'v' com faixa de sombra 'r' no lado direito
    [38] = '.........................kllllllllllllllllllllk',
    [39] = '.......................klllllllllllllllllllllllk',
    [40] = '......................kllllllllllllllllllllllllk',
    [41] = '....................kllllllllllllllllllllllllllk',
    [42] = '..................klllllvvvvvvvvvvvvvvvvvvvrvllllk',
    [43] = '..................klllvvvvvvvvvvvvvvvvvvvvrrvlllk',
    [44] = '..................klllvvvvvvvvvvvvvvvvvvvvrrvlllk',
    [45] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [46] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [47] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [48] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [49] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [50] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [51] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [52] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [53] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [54] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [55] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [56] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    [57] = '...................kllvvvvvvvvvvvvvvvvvvvrvvvllk',
    -- punhos grandes nas mesmas colunas do def anterior (trabalho!)
    [58] = '..............ksssskkllvvvvvvvvvvvvvvvvvvvrvvvllkkssssk',
    [59] = '..............ksdsskkllvvvvvvvvvvvvvvvvvvvrvvvllkkssdsk',
    [60] = '..............ksssskkpppppppppppppppppppppppppkksssssk',
    [61] = '..............ksssskkpppppppppppppppppppppppppkksssssk',
    [62] = '..............kkkkk.kpppppppppppppppppppppppppk.kkkkk',
    -- calça azul-carvão: costura 'P' na face interna das canelas
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
    -- botas largas: cano 'D', corpo 'b', biqueira 'B', sola 'o'
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

-- avental encerado curto na frente: borda viva 'A', meio 'a',
-- bainha com nós 'c' alternados, faixa diagonal 'F' por cima
local garb = {
    [43] = '..........................kAAAAAAAAAAAk',
    [44] = '..........................kAaaaaaaaaaaAk',
    [45] = '..........................kAaaaaaaaaaaaAk',
    [46] = '..........................kAaaaaaaaaaaaAk',
    [47] = '..........................kAaaaaaaaaaaaaAk',
    [48] = '..........................kAaaaaaaaaaaaaAk',
    [49] = '..........................kAaaaaaaaaaaaaaAk',
    [50] = '..........................kAaaaaaaaaaaaaaAk',
    [51] = '..........................kAaaaaaaaaaaaaaAk',
    [52] = '..........................kAaaaaaaaaaaaaaAk',
    [53] = '..........................kAaaaaaaaaaaaaaAk',
    [54] = '..........................kAaaaaaaaaaaaaaAk',
    [55] = '..........................kAaaaaaaaaaaaaaAk',
    [56] = '..........................kAaaaaaaaaaaaaaAk',
    [57] = '..........................kAaaaaaaaaaaaaaAk',
    [58] = '..........................kAaaaaaaaaaaaaaAk',
    [59] = '..........................kAaaaaaaaaaaaaaAk',
    [60] = '..........................kcacacacacacacack',
    [61] = '..........................kcacacacacacacack',
    [62] = '..........................kcccccccccccccck',
}

local strap = {
    [42] = '..............................kFFFk',
    [43] = '..............................kFFFk',
    [44] = '...............................kFFFk',
    [45] = '...............................kFFFk',
    [46] = '................................kFFFk',
    [47] = '................................kFFFk',
    [48] = '.................................kFFFk',
    [49] = '.................................kFFFk',
    [50] = '..................................kFFFk',
    [51] = '..................................kFFFk',
    [52] = '...................................kFFFk',
    [53] = '...................................kFFFk',
    [54] = '....................................kFFFk',
    [55] = '....................................kFFFk',
    [56] = '.....................................kFFFk',
    [57] = '.....................................kFFFk',
    [58] = '......................................kFFFk',
    [59] = '......................................kFFFk',
    [60] = '.......................................kFFFk',
    [61] = '........................................kFFk',
}

local garbAll = overlay(R(strap), R(garb))

local gesto = patch(shift(body, 1, 8, 37), {
    [59] = '..............kddsskkllvvvvvvvvvvvvvvvvvvvrvvvllkkssddk',
    [60] = '..............kddsskkpppppppppppppppppppppppppkkssddsk',
})
local respiroPisca = shift(patch(body, {
    [18] = '..............................ksssddgssgddsssk',
    [19] = '..............................ksssddgssgddsssk',
}), 1, 38, 60)

return {
    name = 'npc_doro_s', w = 64, h = 96, origin = 'feet',
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
