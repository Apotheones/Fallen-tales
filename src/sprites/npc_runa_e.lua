-- V08 NPC_RUNA_E — Runa vigia da grade (C09), idle LESTE perfil,
-- 64x96 origem feet, 4f: repouso/respiro+vigia/punhos na grade/pisca.
-- Âncoras do spec: manto triangular curto verde-seco c/ forro palha |
-- trança ruiva BAIXA caída à frente (lado esquerdo -> colada nas
-- costas em perfil) | polainas claras. Postura: peso na perna de trás,
-- mão da frente erguida na altura do poste (dedos na grade), dedos
-- longos separados. Sardas 'd' no rosto; sem arco em vista (o duelo
-- usa o def de encontro próprio — aqui é a presença de vigia).
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
    -- franja picada irregular (pontas 'a' ao longo da linha) + couro
    -- cabeludo escuro; rosto quadrado, nariz curto alto à direita
    [9]  = '..............................kaaaak',
    [10] = '.............................kaaaaahak',
    [11] = '............................kaaahhaaaak',
    [12] = '............................khaahhaaaaak',
    [13] = '............................khsssssssssk',
    [14] = '............................kssssssssssk',
    [15] = '............................ksssdssssssk',
    [16] = '............................ksdsssdssssk',
    [17] = '............................kssssssseskk',
    [18] = '............................kssssssssnnk',
    [19] = '............................kssdssssssdk',
    [20] = '............................ksssssssssdk',
    [21] = '............................kssssssddsk',
    [22] = '............................ksssssssssk',
    [23] = '.............................ksssssk',
    -- trança ruiva baixa escorre às costas (esquerda), pendurada baixa
    [24] = '...........................kaksssssk',
    [25] = '..........................kaaksssssk',
    [26] = '..........................kAAkssssk',
    [27] = '..........................kAakssssk',
    [28] = '..........................kaaiksssk',
    [29] = '..........................kAiikssk',
    [30] = '..........................kaiksssk',
    -- manto triangular: estreito no pescoço, abrindo aos ombros/peito;
    -- borda 'm' forro palha 'l' na margem interna e na borda livre
    [31] = '..........................kkkmmmkkkkk',
    [32] = '.........................kmmmmlmmmmlmk',
    [33] = '........................kmmmmmmmmmmmmmk',
    [34] = '.......................kmmmmmmmmmmmmmmmk',
    [35] = '......................kmmmmmmmmmmmmmmmmmk',
    [36] = '.....................kmmmlllllllllllllmmk',
    [37] = '....................kmmmlllllllllllllllmmmk',
    [38] = '...................kmmmllllllllllllllllmmmmk',
    -- a mão da frente SOBE sob o manto — punho e dedos sobre a borda
    [39] = '..................kmmmllllllllllllllllmk.sk',
    [40] = '..................kmmmllllllllllllllmkl.sksk',
    [41] = '..................kmmlllllllllllllmk..ksksk',
    -- camisa carvão + proteção de couro sob o manto
    [42] = '..................kiiiiiiiiiiiiiiilk...kssk',
    [43] = '.................kiiiiLLLLLLLLLLLLiiik...kkk',
    [44] = '.................kiiiLLLLxLLLLxLLLiiiik',
    [45] = '.................kiiiLLLLxLLLLxLLLiiiik',
    [46] = '.................kiiiLLLLLLLLLLLLLiiiik',
    [47] = '.................kiiiLLLxLLLLxLLLiiiik',
    [48] = '.................kiiiLLLLLLLLLLLLiiiik',
    [49] = '.................kiiiLLLLLLLLLLLiiiik',
    [50] = '.................kiiiLLLLLLLLLLLiiiik',
    [51] = '.................kiiiLLLLLLLLLLiiiik',
    -- braço de trás pendurado sombreado 'd'
    [52] = '...................kdskLLLLLLLLLLiiiik',
    [53] = '...................kdskLLLLLLLLLiiiik',
    [54] = '...................kddkLLLLLLLLLiiiik',
    [55] = '...................kddkkLLLLLLLLiiik',
    [56] = '....................kkkkLLLLLLLiiiik',
    -- cinto + molho de chaves 'g' pendurado à frente
    [57] = '.....................kBBBBBBBBBBBBk',
    [58] = '.....................kBBBgBBBBBBBk',
    [59] = '.....................kiiiiGGkiiiiik',
    [60] = '.....................kiiiiiGkiiiiik',
    -- pernas fortes: perto 'p' à frente, longe 'P' atrás
    [61] = '.....................kiiiiiiiikiiiik',
    [62] = '.....................kPPPPkppppppppk',
    [63] = '.....................kPPPPkppppppppk',
    [64] = '.....................kPPPPkppppppppk',
    [65] = '.....................kPPPPkppppppppk',
    [66] = '.....................kPPPPkppppppppk',
    [67] = '.....................kPPPPkppppppppk',
    [68] = '.....................kPPPPkppppppppk',
    [69] = '.....................kPPPPkppppppppk',
    [70] = '.....................kPPPPkppppppppk',
    [71] = '.....................kPPPPkppppppppk',
    [72] = '.....................kPPPPkppppppppk',
    [73] = '.....................kPPPPkppppppppk',
    -- polainas claras enroladas: bandas 'P->O' com filete escuro
    [74] = '.........................kOOOkOOOOOOOk',
    [75] = '.........................kOoOkOooooooOk',
    [76] = '.........................kOOOkOOOOOOOk',
    [77] = '.........................kOoOkOooooooOk',
    [78] = '.........................kOOOkOOOOOOOk',
    [79] = '.........................kOoOkOooooooOk',
    [80] = '.........................kOOOkOOOOOOOk',
    [81] = '.........................kOoOkOooooooOk',
    [82] = '.........................kOOOkOOOOOOOk',
    -- botas altas com vira escura
    [83] = '.........................kDDkbbbbbbbbk',
    [84] = '.........................kDDkbbbbbbbbk',
    [85] = '.........................kDDkbbbbbbbbk',
    [86] = '.........................kDDkbbbbbbbbk',
    [87] = '.........................kDDkbbbbbbbbk',
    [88] = '.........................kDDkbbbbbbbbk',
    [89] = '.........................kDDkbbbbbbbbk',
    [90] = '.........................kDDkbbbbbbbbbbk',
    [91] = '.........................kDDkbbbbbbbbbbbk',
    [92] = '.........................kDDkbbbbbbbbbbbk',
    [93] = '.........................kookbbbbbbbbbwk',
    [94] = '.........................kkkkkkkkkkkkkkkkk',
}

-- f3: a vigia olha mais — cabeça não sobe, mas o punho da grade fecha
-- (dedos 's' -> nós sobrepostos 'dd' no ponto de contato).
local gesto = patch(shift(body, 1, 9, 36), {
    [40] = '..................kmmmllllllllllllllmkl.sddk',
    [41] = '..................kmmlllllllllllllmk..kddsk',
})

-- f4: respiro (ombros/tórax +1) + piscar 'ee'->'dd'
local respiroPisca = shift(patch(body, {
    [17] = '............................kssssssddskk',
}), 1, 37, 60)

return {
    name = 'npc_runa_e', w = 64, h = 96, origin = 'feet',
    legend = {
        k = { spec = 'ink', h = 4 },
        s = { ramp = 'skin', step = 3, h = 11 },   -- bege rosado
        d = { ramp = 'skin', step = 1, h = 10 },   -- sarda / sombra
        n = { ramp = 'skin', step = 2, h = 11 },   -- nariz
        e = { spec = 'ink', h = 12 },              -- olho
        a = { ramp = 'rust', step = 4, h = 11 },   -- trança/franja ruiva
        A = { ramp = 'rust', step = 3, h = 11 },
        h = { ramp = 'hair', step = 1, h = 11 },
        i = { ramp = 'iron', step = 3, h = 6 },    -- camisa carvão
        L = { ramp = 'earth', step = 2, h = 7 },   -- proteção couro
        x = { ramp = 'earth', step = 1, h = 6 },   -- correias
        m = { ramp = 'moss', step = 4, h = 7 },    -- manto verde-seco
        l = { ramp = 'bone', step = 5, h = 8 },    -- forro palha
        B = { ramp = 'earth', step = 1, h = 5 },   -- cinto
        g = { ramp = 'gold', step = 5, h = 6 },    -- molho de chaves
        G = { ramp = 'gold', step = 4, h = 6 },
        p = { ramp = 'iron', step = 3, h = 4 },    -- calça perto
        P = { ramp = 'iron', step = 2, h = 3 },    -- calça longe
        O = { ramp = 'bone', step = 4, h = 5 },    -- polaina clara
        o = { ramp = 'bone', step = 3, h = 4 },
        D = { ramp = 'earth', step = 1, h = 2 },
        b = { ramp = 'earth', step = 2, h = 2 },
        w = { ramp = 'earth', step = 4, h = 3 },   -- vira da bota
    },
    layers = {
        { name = 'body', h = 4, albedo = {
            R(body),
            R(shift(body, 1, 37, 56)),
            R(gesto),
            R(respiroPisca),
        } },
    },
}
