-- SABELA — registra/protege, idle SUL, 64x96, origem nos pés, 4f.
-- f1 repouso | f2 respiro | f3 GESTO: olha o caderno (cabeça inclina
-- 1px baixo+esq, caderno sobe 1px) | f4 respiro + piscar.
-- §6 do doc de personagens: 47-53a, 176cm, ALTA de ombros estreitos
-- e pernas longas — a silhueta mais vertical e fina do elenco. Pele
-- negra de tom profundo (skin.1; sombras em hair.1, olhos em osso
-- claro p/ contraste). Rosto angular, tranças curtas puxadas para
-- trás com FIOS BRANCOS na linha frontal 'w'; cicatriz pequena no
-- queixo 'd'. Casaco azul de petróleo (sea.3) ABERTO EM DOIS PAINÉIS
-- sobre camisa de lã cru 'l' (a faixa clara central é a abertura);
-- calças cinza 'p', faixa castanha 'r', botas de cano médio.
-- Mão esquerda: caderno 'P'; sob o braço direito: pasta plana 'Q'.
-- Âncoras: altura e pernas longas | painéis separados do casaco |
-- pasta plana lateral.

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
-- Desloca o conteúdo das linhas [rmin..rmax] em dx colunas (linhas de
-- só-cabeça: o miolo todo anda junto).
local function hshift(map, dx, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then
            if dx > 0 then t[r] = ('.'):rep(dx) .. s:sub(1, #s - dx)
            else t[r] = s:sub(1 - dx) .. ('.'):rep(-dx) end
        else t[r] = s end
    end
    return t
end

--------------------------------------------------------------------------------
-- BODY: tranças, rosto angular, casaco em dois painéis, calças
-- longas. Caderno/pasta/faixa ficam na camada 'gear'.
--------------------------------------------------------------------------------
local body = {
    -- tranças curtas puxadas para trás: massa 'h' com textura 'H'
    [8]  = '............................kkkkkk',
    [9]  = '...........................khhhhhhk',
    [10] = '..........................khhhhhhhhk',
    [11] = '..........................khhHhHhhhk',
    [12] = '..........................khwwwwwhhk',   -- fios brancos, linha frontal
    [13] = '..........................kssssssssk',
    [14] = '..........................kssssssssk',
    [15] = '..........................kssssssssk',
    [16] = '..........................kssssssssk',
    [17] = '..........................kseesssseek',  -- olhos claros (contraste)
    [18] = '..........................kssssssssk',
    [19] = '..........................ksssdssssk',   -- nariz estreito
    [20] = '..........................ksssdssssk',
    [21] = '..........................kssssssssk',
    [22] = '..........................ksssddsssk',   -- lábio inferior cheio
    [23] = '..........................kssssssssk',
    [24] = '..........................kssssssdsk',   -- cicatriz no queixo
    [25] = '..........................kssssssssk',
    [26] = '...........................kssssssk',
    [27] = '...........................kssssssk',
    [28] = '............................kssssk',
    [29] = '............................kssssk',
    [30] = '...........................kllllllk',    -- gola da camisa cru
    -- casaco petróleo aberto: painéis 'c' dos lados, camisa 'l' no meio
    [31] = '........................kcccccllllllccccck',
    [32] = '........................kcccccllllllccccck',
    [33] = '........................kcccccllllllccccck',
    [34] = '..................kcck..kcccccllllllccccck..kcck',
    [35] = '..................kcck..kcccccllllllccccck..kcck',
    [36] = '..................kcck..kcccccllllllccccck..kcck',
    [37] = '..................kcck..kcccccllllllccccck..kcck',
    [38] = '..................kcck..kcccccllllllccccck..kcck',
    [39] = '..................kcck..kcccccllllllccccck..kcck',
    [40] = '..................kcck..kcccccllllllccccck..kcck',
    [41] = '..................kcck..kcccccllllllccccck..kcck',
    [42] = '..................kcck..kcccccllllllccccck..kcck',
    [43] = '..................kcck..kcccccllllllccccck..kcck',
    [44] = '..................kcck..kcccccllllllccccck..kcck',
    [45] = '..................kcck..kcccccllllllccccck..kcck',
    [46] = '..................kcck..kcccccllllllccccck..kcck',
    [47] = '..................kcck..kcccccllllllccccck..kcck',
    [48] = '..................kcck..kcccccllllllccccck..kcck',
    [49] = '..................kcck..kcccccllllllccccck..kcck',
    [50] = '..................kcck..kcccccllllllccccck..kcck',
    [51] = '..................kcck..kcccccllllllccccck..kcck',
    [52] = '..................kcck..kcccccllllllccccck..kcck',
    [53] = '..................kcck..kcccccllllllccccck..kcck',
    [54] = '..................kcck..kcccccllllllccccck..kcck',
    [55] = '..................kcck..kcccccllllllccccck..kcck',
    [56] = '..................kcck..kcccccllllllccccck..kcck',
    -- punho esq. engordado 1px p/ fora (pele extra na linha do gesto:
    -- segura o caderno, não uma faixa solta)
    [57] = '.................ksssk..kcccccllllllccccck..kssk',
    [58] = '.................ksssk..kcccccllllllccccck..kssk',
    [59] = '........................kcccccllllllccccck..kssk',
    [60] = '........................kcccccllllllccccck..kssk',
    [61] = '........................kcccccllllllccccck..kssk',
    [62] = '........................kcccccllllllccccck..kkkk',
    [63] = '........................kcccccccccccccccck',
    -- pernas longas e secas em cinza
    [64] = '..........................kppppk.kppppk',
    [65] = '..........................kppppk.kppppk',
    [66] = '..........................kppppk.kppppk',
    [67] = '..........................kppppk.kppppk',
    [68] = '..........................kppppk.kppppk',
    [69] = '..........................kppppk.kppppk',
    [70] = '..........................kppppk.kppppk',
    [71] = '..........................kppppk.kppppk',
    [72] = '..........................kppppk.kppppk',
    [73] = '..........................kppppk.kppppk',
    [74] = '..........................kppppk.kppppk',
    [75] = '..........................kppppk.kppppk',
    [76] = '..........................kppppk.kppppk',
    [77] = '..........................kppppk.kppppk',
    [78] = '..........................kppppk.kppppk',
    [79] = '..........................kppppk.kppppk',
    [80] = '..........................kppppk.kppppk',
    [81] = '..........................kppppk.kppppk',
    [82] = '..........................kppppk.kppppk',
    [83] = '..........................kppppk.kppppk',
    [84] = '..........................kppppk.kppppk',
    [85] = '..........................kppppk.kppppk',
    [86] = '..........................kppppk.kppppk',
    -- botas leves de cano médio
    [87] = '..........................kbbbk.kbbbk',
    [88] = '..........................kbbbk.kbbbk',
    [89] = '..........................kbbbk.kbbbk',
    [90] = '..........................kbbbk.kbbbk',
    [91] = '..........................kbbbk.kbbbk',
    [92] = '..........................kbbbk.kbbbk',
    [93] = '..........................kooook.kooook',
    [94] = '..........................kkkkk.kkkkk',
}

--------------------------------------------------------------------------------
-- GEAR: faixa castanha 'r' na cintura; caderno 'P' na mão esquerda;
-- pasta plana 'Q' sob o braço direito, despontando na lateral.
--------------------------------------------------------------------------------
local gear = {
    [54] = '........................krrrrrrrrrrrrrrrrk',
    [55] = '........................krrrrrrrrrrrrrrrrk',
    [57] = '.................................................kQQk',
    [58] = '.................................................kQQk',
    [59] = '.................kPssPk.........................kQqk',
    [60] = '.................kPppPk.........................kQqk',
    [61] = '.................kPPPPk.........................kQqk',
    [62] = '.................kPPPPk.........................kQqk',
    [63] = '.................kPPPPk.........................kQqk',
    [64] = '.................kPPPPk.........................kQqk',
    [65] = '..................kkkk..........................kQqk',
    [66] = '.................................................kQqk',
    [67] = '.................................................kQqk',
    [68] = '.................................................kQqk',
    [69] = '.................................................kQqk',
    [70] = '.................................................kQqk',
    [71] = '.................................................kQqk',
    [72] = '.................................................kQqk',
    [73] = '.................................................kQqk',
    [74] = '..................................................kQk',
}

-- f3: olha o caderno — cabeça desce 1px e inclina 1px p/ a esquerda
-- (lado do caderno); o caderno sobe 1px ao encontro do olhar.
local gesto = hshift(shift(body, 1, 8, 29), -1, 8, 30)
local gearGesto = patch(gear, {
    [58] = '.................kPssPk.........................kQQk',
    [59] = '.................kPppPk.........................kQqk',
    [60] = '.................kPPPPk.........................kQqk',
    [61] = '.................kPPPPk.........................kQqk',
    [62] = '.................kPPPPk.........................kQqk',
    [63] = '.................kPPPPk.........................kQqk',
    [64] = '..................kkkk..........................kQqk',
    [65] = '.................................................kQqk',
})
-- f4: respiro com piscar — olhos claros 'ee' viram pálpebra 'dd'.
local respiroPisca = shift(patch(body, {
    [17] = '..........................ksddsssddsk',
}), 1, 31, 56)

return {
    name = 'npc_sabela_s',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 1, h = 11},  -- pele negra profunda
        S = {ramp = 'skin', step = 2, h = 12},
        d = {ramp = 'hair', step = 1, h = 10},  -- sombra do rosto
        e = {ramp = 'bone', step = 5, h = 12},  -- olhos claros p/ ler
        h = {ramp = 'hair', step = 1, h = 11},
        H = {ramp = 'hair', step = 3, h = 12},
        w = {ramp = 'plaster', step = 6, h = 12}, -- fios brancos
        l = {ramp = 'bone', step = 4, h = 6},   -- camisa de lã cru
        c = {ramp = 'sea', step = 3, h = 7},    -- casaco azul petróleo
        r = {ramp = 'earth', step = 3, h = 8},  -- faixa castanha
        p = {ramp = 'iron', step = 4, h = 4},   -- calças cinza
        b = {ramp = 'earth', step = 2, h = 2},
        o = {ramp = 'earth', step = 4, h = 3},
        P = {ramp = 'bone', step = 6, h = 8},   -- caderno claro
        Q = {ramp = 'earth', step = 2, h = 7},  -- pasta plana
        q = {ramp = 'earth', step = 4, h = 7},
    },

    layers = {
        {name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 31, 56)),
            R(gesto),
            R(respiroPisca),
        }},
        {name = 'gear', h = 7, albedo = {
            R(gear),
            R(gear),
            R(gearGesto),
            R(gear),
        }},
    },
}
