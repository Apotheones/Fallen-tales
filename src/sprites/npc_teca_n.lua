-- TECA — idle NORTE (de costas), 64x96, origem nos pés, 4f.
-- f1 repouso, f2 respiro, f3 gesto (aponta explicando), f4 variante
-- (cabeça inclina 1px na direção do gesto).
-- Costas: cabelo preto grisalho cobre a cabeça; o nó baixo lateral
-- passa para a direita da tela (mesmo lado do corpo); vestido 'w'
-- fecha o dorso em triângulo; sobressaia 'o' por trás; o xale 'x'
-- cobre os ombros e sua ponta aparece na cintura à esquerda.

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
-- Variante por linhas: rows sobrescreve o mapa base.
local function patch(map, rows)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(rows) do t[r] = s end
    return t
end
-- Deslocamento horizontal por faixa de linhas (cabeça que inclina).
local function hshift(map, dx, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if s and rmin and r >= rmin and r <= rmax then
            if dx > 0 then t[r] = (string.rep('.', dx) .. s):sub(1, 64)
            elseif dx < 0 then t[r] = s:sub(-dx + 1)
            else t[r] = s end
        else t[r] = s end
    end
    return t
end

local body = {
    [14] = '............................kkkkkk',
    [15] = '...........................khhhhhhk',
    [16] = '.........................khhhhhhhhhhk',
    [17] = '.........................khhGhhhhhGhk',
    [18] = '.........................khhhhhhhhhhk',
    [19] = '.........................khhhhhhhhhhk',
    -- o nó agora à direita da tela
    [20] = '.........................khhhhhhhhhhkkhhhk',
    [21] = '.........................khhhhhhhhhhkhhhhk',
    [22] = '.........................khhhhhhhhhhkhhGhk',
    [23] = '.........................khhhhhhhhhhkhhhhk',
    [24] = '.........................khhhhhhhhhhkkhhk',
    [25] = '.........................khhhhhhhhhhk.khhk',
    [26] = '..........................khhhhhhhhk..khhk',
    [27] = '..........................khhhhhhhhk...kk',
    [28] = '..........................kssssssk',
    [29] = '..........................kssssssk',
    [30] = '............................kssssk',
    [31] = '...........................kwwwwwwk',
    [32] = '..........................kwwwwwwwwk',
    [33] = '.........................kwwwwwwwwwwk',
    [34] = '........................kwwwwwwwwwwwwk',
    [35] = '.......................kwwwwwwwwwwwwwwk',
    [36] = '.......................kwwwwwwwwwwwwwwk',
    [37] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [38] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [39] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [40] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [41] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [42] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [43] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [44] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [45] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [46] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [47] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [48] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [49] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [50] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [51] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [52] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [53] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [54] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [55] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwk',
    [56] = '..................kllk.kwwwwwwwwwwwwwwk.kllk',
    [57] = '..................kllk.kwwwwwwwwwwwwwwk.kllk',
    [58] = '..................kssk.kwwwwwwwwwwwwwwk.kssk',
    [59] = '..................kssk.kwwwwwwwwwwwwwwk.kssk',
    [60] = '..................kkkk.kwwwwwwwwwwwwwwk.kkkk',
    [61] = '.......................kwwwwwwwwwwwwwwk',
    [62] = '.......................kwwwwwwwwwwwwwwk',
    [63] = '.......................kwwwwwwwwwwwwwwk',
    [64] = '.......................kwwwwwwwwwwwwwwk',
    [65] = '......................kwwwwwwwwwwwwwwwwk',
    [66] = '......................kwwwwwwwwwwwwwwwwk',
    [67] = '......................kwwwwwwwwwwwwwwwwk',
    [68] = '......................kwwwwwwwwwwwwwwwwk',
    [69] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [70] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [71] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [72] = '.....................kwwwwwwwwwwwwwwwwwwk',
    [73] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [74] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [75] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [76] = '....................kwwwwwwwwwwwwwwwwwwwwk',
    [77] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [78] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [79] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [80] = '...................kwwwwwwwwwwwwwwwwwwwwwwk',
    [81] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [82] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [83] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [84] = '..................kwwwwwwwwwwwwwwwwwwwwwwwwk',
    [85] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [86] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [87] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [88] = '.................kwwwwwwwwwwwwwwwwwwwwwwwwwwk',
    [89] = '.................kWWWWWWWWWWWWWWWWWWWWWWWWk',
    [90] = '.................kkkkkkkkkkkkkkkkkkkkkkkkkk',
    [91] = '..........................kbbk.....kbbk',
    [92] = '..........................kbbk.....kbbk',
    [93] = '..........................kbbk.....kbbk',
    [94] = '..........................kkkk.....kkkk',
}

local overskirt = {
    [52] = '.......................koooooooooooooooook',
    [53] = '.......................koooooooooooooooook',
    [54] = '.......................koooooooooooooooook',
    [55] = '.......................koooooooooooooooook',
    [56] = '.......................koooooooooooooooook',
    [57] = '.......................koooooooooooooooook',
    [58] = '.......................koooooooooooooooook',
    [59] = '......................kooooooooooooooooook',
    [60] = '......................kooooooooooooooooook',
    [61] = '......................kooooooooooooooooook',
    [62] = '......................kooooooooooooooooook',
    [63] = '......................kooooooooooooooooook',
    [64] = '......................kooooooooooooooooook',
    [65] = '.....................kooooooooooooooooooook',
    [66] = '.....................kooooooooooooooooooook',
    [67] = '.....................kooooooooooooooooooook',
    [68] = '.....................kooooooooooooooooooook',
    [69] = '.....................kooooooooooooooooooook',
    [70] = '.....................kooooooooooooooooooook',
    [71] = '.....................kooooooooooooooooooook',
    [72] = '.....................kOOOOOOOOOOOOOOOOOOOOk',
}

local xale = {
    [33] = '.........................kxxxxxxxxxxxxk',
    [34] = '........................kxxxxxxxxxxxxxxk',
    [35] = '........................kxxxxxxxxxxxxxxk',
    [36] = '.......................kxxxkwwwwwwkxxxk',
    [37] = '.......................kxxkwwwwwwwwkxxk',
    [38] = '.......................kxxkwwwwwwwwkxxk',
    [39] = '........................kxkwwwwwwwwkxk',
    -- ponta do xale na cintura, agora à esquerda
    [50] = '....................kxxk',
    [51] = '....................kxxk',
    [52] = '....................kxxk',
    [53] = '....................kxxk',
    [54] = '....................kxxk',
    [55] = '.....................kxk',
    [56] = '.....................kxk',
    [57] = '......................kk',
}

local garb = overlay(R(overskirt), R(xale))

--------------------------------------------------------------------------------
-- f3 — gesto: aponta explicando, mesmo braço dobrado da frente sul
-- (de costas o antebraço sai na horizontal à direita).
--------------------------------------------------------------------------------
local bodyGesto = patch(body, {
    [48] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwwwwsk',
    [49] = '..................kwwk.kwwwwwwwwwwwwwwk.kwwwwwsk',
    [50] = '..................kwwk.kwwwwwwwwwwwwwwk.kkkkkkkk',
    [51] = '..................kwwk.kwwwwwwwwwwwwwwk',
    [52] = '..................kwwk.kwwwwwwwwwwwwwwk',
    [53] = '..................kwwk.kwwwwwwwwwwwwwwk',
    [54] = '..................kwwk.kwwwwwwwwwwwwwwk',
    [55] = '..................kwwk.kwwwwwwwwwwwwwwk',
    [56] = '..................kllk.kwwwwwwwwwwwwwwk',
    [57] = '..................kllk.kwwwwwwwwwwwwwwk',
    [58] = '..................kssk.kwwwwwwwwwwwwwwk',
    [59] = '..................kssk.kwwwwwwwwwwwwwwk',
    [60] = '..................kkkk.kwwwwwwwwwwwwwwk',
})

--------------------------------------------------------------------------------
-- f4 — variante: cabeça (massa de cabelo + nó) inclina 1px à direita.
--------------------------------------------------------------------------------
local bodyOlha = hshift(body, 1, 14, 27)

return {
    name = 'npc_teca_n',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 4, h = 11},
        S = {ramp = 'skin', step = 5, h = 12},
        d = {ramp = 'skin', step = 3, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 2, h = 11},
        G = {ramp = 'iron', step = 5, h = 12},
        w = {ramp = 'sea', step = 3, h = 5},
        W = {ramp = 'sea', step = 2, h = 4},
        l = {ramp = 'plaster', step = 5, h = 6},
        o = {ramp = 'clothWarm', step = 3, h = 6},
        O = {ramp = 'clothWarm', step = 2, h = 6},
        x = {ramp = 'plaster', step = 5, h = 7},
        b = {ramp = 'earth', step = 2, h = 2},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 55)),
            R(bodyGesto),
            R(bodyOlha),
        }},
        {name = 'garb', h = 6, albedo = {garb, garb, garb, garb}},
    },
}
