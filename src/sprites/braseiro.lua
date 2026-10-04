-- BRASEIRO de chão — prop de luz, 64x96, origem nos pés.
-- Amostra do formato DSL (Fase 0, docs/MEGAPLAN_VISUAL_HD.md §1-2).
-- Tripé de ferro com ferrugem, tigela de brasas e labaredas.
-- Prova do emissivo: chama ei=1 (estoura no bloom), brasas ei~0.7.
-- Relevo: chama/tigela altos (h 9-15), base do tripé baixa (h 3).
--
-- LOOP AMBIENTAL (frente micro-animações): f1..f4 = flicker de chama.
-- f1 = base; f2 inclina à direita e estica a língua; f3 o núcleo 'O'
-- incha (pulso) e solta 2 fagulhas fora da silhueta; f4 inclina à
-- esquerda. O corpo baixo da chama (linhas 19-38) é estável — a dança
-- mora nas línguas de cima. O leito de brasas (emissivo linhas 41-42)
-- troca os pontos quentes 'o' entre frames — pisca sem mudar o desenho.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

-- Linhas por segmentos: { [linha] = { {col, 'chars'}, ... } } -> grade
-- 64x96. Posição exata, sem contar pontos à mão.
local function F(map)
    local t = {}
    for r = 1, 96 do
        local segs = map[r]
        if segs then
            local s, col = '', 1
            for _, sg in ipairs(segs) do
                local x, txt = sg[1], sg[2]
                if x > col then s = s .. string.rep('.', x - col) end
                s = s .. txt
                col = math.max(col, x) + #txt
            end
            t[r] = L(s)
        else
            t[r] = E
        end
    end
    return table.concat(t, '\n')
end

-- Corpo baixo da chama — compartilhado pelos 4 frames (não mexe).
local FOGO_BASE = {
    [19] = {{23, 'fffffFFOOOOOfffffff'}},
    [20] = {{23, 'ffffFFOOOOOOffffffff'}},
    [21] = {{23, 'ffffFOOOOOOOfffffff'}},
    [22] = {{23, 'ffffOOOOOOOOffffffff'}},
    [23] = {{23, 'ffffOOOOOOOOffffffff'}},
    [24] = {{23, 'fffOOOOOOOOOfffffff'}},
    [25] = {{23, 'fffOOOOOOOOOfffffff'}},
    [26] = {{22, 'ffffOOOOOOOOOffffffff'}},
    [27] = {{22, 'ffffOOOOOOOOOffffffff'}},
    [28] = {{22, 'ffffOOOOOOOOOffffffff'}},
    [29] = {{22, 'ffFOOOOOOOOOOfffffff'}},
    [30] = {{22, 'ffFOOOOOOOOOOfffffff'}},
    [31] = {{22, 'ffFOOOOOOOOOOfffffff'}},
    [32] = {{22, 'ffFOOOOOOOOOOfffffff'}},
    [33] = {{21, 'ffffOOOOOOOOOOOfffffff'}},
    [34] = {{21, 'ffffOOOOOOOOOOOfffffff'}},
    [35] = {{21, 'ffffOOOOOOOOOOOfffffff'}},
    [36] = {{21, 'ffffOOOOOOOOOOOfffffff'}},
    [37] = {{22, 'fffOOOOOOOOOOfffffff'}},
    [38] = {{22, 'fffOOOOOOOOOOfffffff'}},
}

-- f1: chama original — língua central alta no col 33, labareda lateral
-- à esquerda (cols 24-26), fagulha colada à direita (cols 40-41, r18).
local TOP1 = {
    [6]  = {{33, 'f'}},
    [7]  = {{33, 'f'}},
    [8]  = {{32, 'fFf'}},
    [9]  = {{31, 'ffFFf'}},
    [10] = {{31, 'ffFFf'}},
    [11] = {{30, 'ffFOFff'}},
    [12] = {{30, 'ffFOFff'}},
    [13] = {{25, 'f'}, {28, 'fffFOFfff'}},
    [14] = {{24, 'fff'}, {28, 'fffFOOfff'}},
    [15] = {{24, 'fffffffFOOfff'}},
    [16] = {{24, 'ffFffFOOOFffff'}},
    [17] = {{23, 'ffffffFOOOFffff'}},
    [18] = {{23, 'fffffffOOOFfffff'}, {40, 'ff'}},
}

-- f2: ponta sobe 1 px e pende à direita; labareda esquerda alarga e
-- desce mais cedo; corpo direito engorda 1 px em r12/r17.
local TOP2 = {
    [5]  = {{34, 'f'}},
    [6]  = {{34, 'f'}},
    [7]  = {{33, 'ff'}},
    [8]  = {{32, 'fFFf'}},
    [9]  = {{31, 'ffFFf'}},
    [10] = {{31, 'ffFFf'}},
    [11] = {{30, 'ffFOFff'}},
    [12] = {{30, 'fFFOFff'}},
    [13] = {{24, 'f'}, {28, 'fffFOFfff'}},
    [14] = {{23, 'ffff'}, {28, 'fffFOOfff'}},
    [15] = {{24, 'fffffffFOOfff'}},
    [16] = {{24, 'ffFffFOOOFffff'}},
    [17] = {{23, 'ffffffFOOOFfffff'}},
    [18] = {{23, 'fffffffOOOFfffff'}},
}

-- f3: agacha (ponta 1 px mais baixa), o núcleo 'O' incha para a boca da
-- língua (r12-r15) e solta 2 fagulhas fora da silhueta (20,9) e (45,12).
local TOP3 = {
    [7]  = {{33, 'f'}},
    [8]  = {{32, 'fFf'}},
    [9]  = {{20, 'f'}, {31, 'ffFFf'}},
    [10] = {{31, 'ffFFF'}},
    [11] = {{30, 'ffFOOFf'}},
    [12] = {{30, 'fFOOOFf'}, {45, 'f'}},
    [13] = {{24, 'ff'}, {28, 'fFOOOFfff'}},
    [14] = {{24, 'fff'}, {28, 'ffOOOOfff'}},
    [15] = {{24, 'ffffffFOOOfff'}},
    [16] = {{24, 'ffFffOOOOFffff'}},
    [17] = {{23, 'ffffffOOOOFffff'}},
    [18] = {{23, 'fffffffOOOFfffff'}, {40, 'ff'}},
}

-- f4: pende à esquerda — ponta migra p/ cols 30-32, esquerda engorda,
-- labareda lateral volta a subir e uma fagulha solta à direita (40,18).
local TOP4 = {
    [6]  = {{32, 'f'}},
    [7]  = {{31, 'ff'}},
    [8]  = {{30, 'fFff'}},
    [9]  = {{30, 'fFFff'}},
    [10] = {{31, 'ffFFf'}},
    [11] = {{30, 'ffFOFff'}},
    [12] = {{29, 'ffFOFfff'}},
    [13] = {{25, 'f'}, {28, 'ffFOFffff'}},
    [14] = {{24, 'fff'}, {28, 'fffFOOfff'}},
    [15] = {{24, 'fffffffFOOfff'}},
    [16] = {{24, 'fffFfFOOOFffff'}},
    [17] = {{23, 'fffffFOOOFfffff'}},
    [18] = {{22, 'ffffffffOOOFffff'}, {40, 'f'}},
}

local function chama(top)
    local t = {}
    for r, segs in pairs(FOGO_BASE) do t[r] = segs end
    for r, segs in pairs(top) do t[r] = segs end
    return F(t)
end

-- Emissivo = mesma chama + leito de brasas (linhas 41-42, cols 23-45).
-- Os pontos quentes 'o' trocam de lugar por frame — piscam sem pular.
local function chamaEmi(top, b41, b42)
    local t = {}
    for r, segs in pairs(FOGO_BASE) do t[r] = segs end
    for r, segs in pairs(top) do t[r] = segs end
    t[41] = {{23, b41}}
    t[42] = {{23, b42}}
    return F(t)
end

return {
    name = 'braseiro',
    w = 64, h = 96,
    origin = 'feet',
    frameUse = 'anim', -- f1..f4 = loop ambiental, não variantes

    legend = {
        k = {spec = 'ink', h = 4},
        -- ferro da tigela (I = borda iluminada, h alto) e das pernas (L, baixo)
        i = {ramp = 'iron', step = 3, h = 8},
        I = {ramp = 'iron', step = 5, h = 10},
        L = {ramp = 'iron', step = 2, h = 3},
        -- ferrugem na tigela (r) e nas pernas (R)
        r = {ramp = 'rust', step = 3, h = 8},
        R = {ramp = 'rust', step = 2, h = 3},
        -- brasas na tigela: emissivo moderado
        e = {ramp = 'ember', step = 2, h = 9, e = 'ember.3', ei = 0.7},
        o = {ramp = 'ember', step = 4, h = 9, e = 'ember.5', ei = 0.7},
        -- labareda: f = borda, F = corpo, O = núcleo quente — ei 1, bloom forte
        f = {ramp = 'ember', step = 3, h = 13, e = 'ember.4', ei = 1},
        F = {ramp = 'ember', step = 5, h = 14, e = 'ember.6', ei = 1},
        O = {ramp = 'ember', step = 7, h = 15, e = 'ember.7', ei = 1},
    },

    layers = {
        {   -- BASE: tigela de ferro com brasas + tripé até os pés
            name = 'base',
            h = 3,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,
                E, E, E, E, E, E, E, E, E, E,
                E, E, E, E, E, E, E, E, E, E,
                E, E, E, E, E, E, E, E, E,
                -- borda da tigela (cols 14-50)
                L'.............kIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIk',
                L'.............kiiiiiiieeoeeeeeeoeeoeeeeoeeeiiiiiiik',
                L'.............kiiiiiiieeoeeeeeeoeeoeeeeoeeeiiiiiiik',
                L'.............kiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiik',
                -- bojo da tigela afinando para o colar (cols 16-48 -> 22-42)
                L'...............kiiiiiiiiiirriiiiiiirriiiiiiiik',
                L'...............kiiiiiiiiiirriiiiiiirriiiiiiiik',
                L'...............kiiiiiiiiiirriiiiiiirriiiiiiiik',
                L'...............kiiiiiiiiiirriiiiiiirriiiiiiiik',
                L'.................kiiiiiirriiiiiiiiiirriiiiik',
                L'.................kiiiiiirriiiiiiiiiirriiiiik',
                L'.................kiiiiiirriiiiiiiiiirriiiiik',
                L'.................kiiiiiirriiiiiiiiiirriiiiik',
                L'...................kiiiiirriiiiiiiiiiirriiiik',
                L'...................kiiiiirriiiiiiiiiiirriiiik',
                L'...................kiiiiirriiiiiiiiiiirriiiik',
                L'...................kiiiiirriiiiiiiiiiirriiiik',
                L'.....................kiiiriiiiiiiiirriik',
                L'.....................kiiiriiiiiiiiirriik',
                -- colar e nó do tripé
                L'...........................kiiiiriiiik',
                L'...........................kiiiiriiiik',
                L'...........................kiiiiriiiik',
                L'.........................kiiiiriiiiiiik',
                L'.........................kiiiiriiiiiiik',
                L'.........................kiiiiriiiiiiik',
                -- três pernas em splay até o chão
                L'...........................LL.LLLLL',
                L'..........................LL..LLL.LL',
                L'..........................LL..LLL.LL',
                L'.........................LR...LLL..LR',
                L'.........................LL...LLL..LL',
                L'........................LL....LLL...LL',
                L'........................LL....LLL...LL',
                L'.......................LL.....LLR....LL',
                L'.......................LL.....LLL....LL',
                L'......................LL......LLL.....LL',
                L'......................LR......LLL.....LR',
                L'.....................LL.......LLL......LL',
                L'.....................LL.......LLL......LL',
                L'....................LL........LLL.......LL',
                L'....................LL........LLR.......LL',
                L'....................LL........LLL.......LL',
                L'...................LL.........LLL........LL',
                L'...................LR.........LLL........LR',
                L'..................LL..........LLL.........LL',
                L'..................LL..........LLL.........LL',
                L'.................LL...........LLL..........LL',
                L'.................LL...........LLL..........LL',
                L'................LL............LLL...........LL',
                L'................LL............LLL...........LL',
                L'...............LR.............LLL............LR',
                L'...............LL.............LLL............LL',
                L'..............LL..............LLL.............LL',
                L'..............LL..............LLL.............LL',
                L'.............LL...............LLL..............LL',
                -- patas: apoio lateral e pé central
                L'............kLLk..............LLL.............kLLk',
                L'............kLLk..............LLL.............kLLk',
                L'.............................kLLLk',
                L'.............................kLLLk',
            },
        },
        {   -- FIRE: labareda sobre a tigela + emissivo da chama e das
            -- brasas. f1..f4 = loop de flicker (ver cabeçalho).
            name = 'fire',
            h = 14,
            albedo = {
                chama(TOP1),
                chama(TOP2),
                chama(TOP3),
                chama(TOP4),
            },
            emissive = {
                chamaEmi(TOP1,
                    'eeoeeeeeeoeeoeeeeoeee',
                    'eeoeeeeeeoeeoeeeeoeee'),
                chamaEmi(TOP2,
                    'eeeoeoeeeeeeoeeeoeoee',
                    'eeoeeeeeeoeeoeeeeoeee'),
                chamaEmi(TOP3,
                    'eeoeeeeeeoeeoeeeeoeee',
                    'eeeoeoeeeeeeoeeeoeoee'),
                chamaEmi(TOP4,
                    'eeeeeeoeeeoeeoeeoeeee',
                    'eeoeeeoeeoeeoeeeeeeoe'),
            },
        },
    },
}
