-- NILO — idle NORTE (de costas), 64x96, origem nos pés, 4f.
-- f1 repouso, f2 respiro, f3 gesto (dedo no instrumento, que nesta
-- vista pende à esquerda), f4 variante (mecha balança 1px).
-- Costas: massa de cabelo denso cobre a cabeça (a mecha alta segue
-- despontando do topo — âncora lê de costas também); colete 'v'
-- fecha o dorso com camisa 'y' nas bordas e capuz de bolso escondido
-- (o retângulo é frontal); calças com barra dobrada 'C'; corpo do
-- instrumento 'W' passa para a esquerda da tela (mesmo lado).

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
-- Variante por linhas: rows sobrescreve o mapa base.
local function patch(map, rows)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(rows) do t[r] = s end
    return t
end
-- Deslocamento horizontal por faixa de linhas (mecha que balança).
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
    [6]  = '..............................kk',
    [7]  = '.............................khhk',
    [8]  = '.............................khhk',
    [9]  = '............................khhhk',
    [10] = '..........................kkhhhhhhkk',
    [11] = '.........................khhhhhhhhhhk',
    [12] = '........................khhhhhhhhhhhhk',
    [13] = '........................khhhHhhhhHhhhk',
    [14] = '.......................khhhhhhhhhhhhhhk',
    [15] = '.......................khhhhhhhhhhhhhhk',
    [16] = '.......................khhhhhhhhhhhhhhk',
    [17] = '.......................khhhhhhhhhhhhhhk',
    [18] = '.......................khhhhhhhhhhhhhhk',
    [19] = '.......................khhhhhhhhhhhhhhk',
    [20] = '.......................khhhhhhhhhhhhhhk',
    [21] = '.......................khhhhhhhhhhhhhhk',
    [22] = '.......................khhhhhhhhhhhhhhk',
    [23] = '.......................khhhhhhhhhhhhhhk',
    [24] = '........................khhhhhhhhhhhhk',
    [25] = '.........................khhhhhhhhhhk',
    [26] = '..........................khhhhhhk',
    [27] = '..........................kssssk',
    [28] = '...........................kyyyyyk',
    [29] = '.........................kyyyyyyyyyyk',
    [30] = '........................kyyyyyyyyyyyyk',
    [31] = '........................kyvvvvvvvvvvvvyk',
    [32] = '.......................kyyvvvvvvvvvvvvyyk',
    [33] = '.......................kyvvvvvvvvvvvvvvyk',
    [34] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [35] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [36] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [37] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [38] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [39] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [40] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [41] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [42] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [43] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [44] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [45] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [46] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [47] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [48] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [49] = '..................kyyk.yvvvvvvvvvvvvvvy.kyyk',
    [50] = '..................kyyk.kyvvvvvvvvvvvvvyk.kyyk',
    [51] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [52] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [53] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [54] = '..................kyyk.kyyyyyyyyyyyyyyk.kyyk',
    [55] = '..................kssk.kyyyyyyyyyyyyyyk.kssk',
    [56] = '..................kssk.krrrrrrrrrrrrrrrk.kssk',
    [57] = '..................kssk.kpppppppppppppppk.kssk',
    [58] = '..................kssk.kpppppppppppppppk.kssk',
    [59] = '..................kwkk.kpppppppppppppppk.kkkk',
    [60] = '.................kWwk...kppppppk..kppppppk',
    [61] = '................kWWWWk..kppppppk..kppppppk',
    [62] = '................kWWxWWk.kppppppk..kppppppk',
    [63] = '................kWWWWk..kppppppk..kppppppk',
    [64] = '................kWWWWk..kppppppk..kppppppk',
    [65] = '.................kWWk...kppppppk..kppppppk',
    [66] = '..................kk....kppppppk..kppppppk',
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
    [81] = '.........................kpppppk...kpppppk',
    [82] = '.........................kCCCCCk...kCCCCCk',
    [83] = '.........................kCCCCCk...kCCCCCk',
    [84] = '.........................kCCCCCk...kCCCCCk',
    [85] = '.........................kbbbbbk...kbbbbbk',
    [86] = '.........................kbbbbbk...kbbbbbk',
    [87] = '.........................kbbbbbk...kbbbbbk',
    [88] = '.........................kbbbbbk...kbbbbbk',
    [89] = '.........................kbbbbbk...kbbbbbk',
    [90] = '.........................kbbbbbk...kbbbbbk',
    [91] = '.........................kbbbxxk...kbbbxxk',
    [92] = '.........................kbbbxxk...kbbbxxk',
    [93] = '.........................kooooook..kooooook',
    [94] = '.........................kkkkkkk..kkkkkkk',
}

--------------------------------------------------------------------------------
-- f3 — gesto: manga esquerda desce, punho pousa no instrumento e um
-- dedo 's' fica sobre a junção cabo/corpo (dedo no instrumento).
--------------------------------------------------------------------------------
local bodyGesto = patch(body, {
    [55] = '..................kyyk.kyyyyyyyyyyyyyyk.kssk',
    [56] = '..................kyyk.krrrrrrrrrrrrrrrk.kssk',
    [57] = '..................kyyk.kpppppppppppppppk.kssk',
    [58] = '..................kyyk.kpppppppppppppppk.kssk',
    [59] = '..................kssk.kpppppppppppppppk.kkkk',
    [60] = '.................kWsk...kppppppk..kppppppk',
})

--------------------------------------------------------------------------------
-- f4 — variante: a mecha alta balança 1px para o lado da peça.
--------------------------------------------------------------------------------
local bodyMecha = hshift(body, 1, 6, 9)

return {
    name = 'npc_nilo_n',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 5, h = 11},
        S = {ramp = 'skin', step = 6, h = 12},
        d = {ramp = 'skin', step = 4, h = 10},
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 2, h = 11},
        H = {ramp = 'hair', step = 4, h = 12},
        y = {ramp = 'gold', step = 5, h = 6},
        v = {ramp = 'sea', step = 3, h = 6},
        B = {ramp = 'bone', step = 5, h = 8},
        b = {ramp = 'earth', step = 2, h = 2},
        r = {ramp = 'earth', step = 2, h = 5},
        p = {ramp = 'earth', step = 3, h = 4},
        C = {ramp = 'earth', step = 5, h = 5},
        x = {ramp = 'hair', step = 1, h = 3},
        w = {ramp = 'wood', step = 4, h = 7},
        W = {ramp = 'wood', step = 5, h = 7},
        o = {ramp = 'earth', step = 4, h = 3},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 28, 54)),
            R(bodyGesto),
            R(bodyMecha),
        }},
    },
}
