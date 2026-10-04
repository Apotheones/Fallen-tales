-- LAMPIÃO de poste — fonte de luz da praça, 64x96, origem nos pés.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO): poste de madeira com
-- cintas de ferro, braço curvo de ferro no topo e lamparina de vidro
-- pendurada — caixa de ferro quase transparente com uma chama pequena
-- e estável (lampião não trema: flicker é só de fogo exposto).
-- Geometria: "poste que carrega fogo pequeno", não tocha — a chama mora
-- dentro da gaiola de vidro, ei~0.9 real no canal emissivo; o vidro só
-- aparece em filetes quentes de reflexo (ei baixo, sem bloom).
-- Relevo: lamparina 11-15 (o mais alto), braço/cap 9-10, poste 7-9,
-- base de pedra 2-4.
--
-- LOOP AMBIENTAL (frente micro-animações): f1..f4 = flicker de
-- lamparina. f1 = base; f2 pende à direita e o vidro direito ganha
-- reflexos 'g' extras; f3 estica (ponta sobe 1 px, base emagrece);
-- f4 pende à esquerda. Gaiola, braço e poste são estáticos — só os
-- chars de chama f/F/O e os reflexos 'g' mudam de frame.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)

-- Grade esparsa: { [linha] = 'conteúdo' } -> string 64x96.
local function R(map)
    local t = {}
    for r = 1, 96 do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end

local poste = {
    -- capitel de ferro no topo do mourão
    [34] = '..........................kIIIk',
    [35] = '..........................kiiik',
    -- mourão de madeira: fio claro 'W', corpo 'w', sombra 'v' à direita
    [36] = '..........................kWwwvk',
    [37] = '..........................kWwwvk',
    [38] = '..........................kwwvvk',
    [39] = '..........................kwwvvk',
    [40] = '..........................kWwwvk',
    [41] = '..........................kWwwvk',
    [42] = '..........................kwwvvk',
    [43] = '..........................kwwvvk',
    [44] = '..........................kWwwvk',
    [45] = '..........................kWwwvk',
    [46] = '..........................kwwvvk',
    [47] = '..........................kwwvvk',
    -- cinta de ferro alta (segura o braço por trás)
    [48] = '.........................kiiiiiik',
    [49] = '.........................kIIIIIIk',
    [50] = '..........................kWwwvk',
    [51] = '..........................kWwwvk',
    [52] = '..........................kwwvvk',
    [53] = '..........................kwwvvk',
    [54] = '..........................kWwwvk',
    [55] = '..........................kWwwvk',
    [56] = '..........................kwwvvk',
    [57] = '..........................kwwvvk',
    [58] = '..........................kWwwvk',
    [59] = '..........................kWwwvk',
    -- cinta de ferro baixa com ferrugem
    [60] = '.........................kiriiiik',
    [61] = '.........................kiiiirrk',
    [62] = '..........................kWwwvk',
    [63] = '..........................kWwwvk',
    [64] = '..........................kwwvvk',
    [65] = '..........................kwwvvk',
    [66] = '..........................kWwwvk',
    [67] = '..........................kWwwvk',
    [68] = '..........................kwwvvk',
    [69] = '..........................kwwvvk',
    [70] = '..........................kWwwvk',
    [71] = '..........................kWwwvk',
    [72] = '..........................kwwvvk',
    [73] = '..........................kwwvvk',
    [74] = '..........................kWwwvk',
    [75] = '..........................kWwwvk',
    [76] = '..........................kwwvvk',
    [77] = '..........................kwwvvk',
    [78] = '..........................kWwwvk',
    [79] = '..........................kWwwvk',
    [80] = '..........................kwwvvk',
    [81] = '..........................kwwvvk',
    [82] = '..........................kWwwvk',
    [83] = '..........................kWwwvk',
    [84] = '..........................kwwvvk',
    [85] = '..........................kwwvvk',
    -- pé do mourão entrando na base de pedra
    [86] = '..........................kwvvk',
    [87] = '.........................kSsssssk',
    [88] = '........................kSsssssssk',
    [89] = '.......................kssmsssssmssk',
    [90] = '......................ksssmsssssmssk',
    [91] = '.....................ksmssssssssssmssk',
    [92] = '.....................kmsssssssssssssmk',
    [93] = '......................kmmmmmmmmmmmmk',
}

local lamp = {
    -- braço de ferro saindo do capitel e curvando à direita;
    -- contraforte diagonal de volta ao mourão
    [34] = '.............................iiiiiiiiiiiiiiiii',
    [35] = '.............................IIIIIIIIIIIIIIIIIt',
    [36] = '.............................................tt',
    [37] = '..............................................tt',
    [38] = '...............................i..............t',
    [39] = '................................i.............t',
    [40] = '.................................i............t',
    -- argola + alça da lamparina pendurada na ponta do braço
    [41] = '.............................................tt',
    [42] = '...........................................ttttttt',
    [43] = '.........................................ttt...ttt',
    [44] = '........................................tt.......tt',
    [45] = '.......................................t.........t',
    -- capela de ferro (chaminé) mais larga que a caixa
    [46] = '.....................................IIIIIIIIIII',
    [47] = '....................................kiiiiiiiiiiik',
    [48] = '....................................kiiiitiiiiiik',
    -- caixa de vidro: filetes de ferro, interior vazio, chama no
    -- centro e reflexos quentes 'g'/'G' no vidro
    [49] = '....................................ktg.......gtk',
    [50] = '....................................kt.........tk',
    [51] = '....................................kt....f....tk',
    [52] = '....................................kt...fFf...tk',
    [53] = '....................................ktg.fFOFf.gtk',
    [54] = '....................................kt..fFOFf..tk',
    [55] = '....................................kt...fOFf..tk',
    [56] = '....................................kt...fFf..gtk',
    [57] = '....................................ktg...f....tk',
    [58] = '....................................kt.........tk',
    [59] = '....................................kt.........tk',
    [60] = '....................................kiiiiiiiiiiik',
    -- base da lamparina e ponta
    [61] = '.....................................kittttttik',
    [62] = '......................................kittittik',
    [63] = '........................................kt.tk',
    [64] = '.........................................ktk',
}

-- LOOP de flicker: quatro mapas derivados de `lamp` — só as linhas do
-- interior da gaiola (r50-r57) mudam; a moldura 'kt...tk' segue firme.
local function copia(t)
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end
local P = '....................................' -- prefixo até a col 37

local lamp2 = copia(lamp)   -- pende à direita + reflexos no vidro dir
lamp2[50] = P .. 'kt........gtk'
lamp2[51] = P .. 'kt.....f...tk'
lamp2[52] = P .. 'kt....fFf..tk'
lamp2[54] = P .. 'kt...fFOFf.tk'
lamp2[55] = P .. 'kt....fOFf.tk'
lamp2[56] = P .. 'kt....fFf.gtk'

local lamp3 = copia(lamp)   -- estica: ponta sobe 1 px, base emagrece
lamp3[50] = P .. 'kt....f....tk'
lamp3[57] = P .. 'ktg........tk'

local lamp4 = copia(lamp)   -- pende à esquerda
lamp4[51] = P .. 'kt...f.....tk'
lamp4[52] = P .. 'kt..fFf....tk'
lamp4[53] = P .. 'ktgfFOFf..gtk'
lamp4[54] = P .. 'kt.fFOFf...tk'
lamp4[55] = P .. 'kt..fOFf...tk'
lamp4[56] = P .. 'kt..fFf...gtk'

-- Emissivo derivado do albedo do frame: onde há chama (f/F/O) ou
-- reflexo de vidro (g) o pixel emite — alinhado, sem drift por frame.
local function emisDe(map)
    local out = {}
    for r = 1, 96 do
        local src = map[r]
        if src then
            local chars = {}
            for x = 1, #src do
                local c = src:sub(x, x)
                chars[x] = (c == 'f' or c == 'F' or c == 'O'
                    or c == 'g') and c or '.'
            end
            out[r] = L(table.concat(chars))
        else
            out[r] = E
        end
    end
    return table.concat(out, '\n')
end

return {
    name = 'lampiao',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 6},
        -- mourão de madeira e cintas
        w = {ramp = 'wood', step = 4, h = 8},
        W = {ramp = 'wood', step = 6, h = 9},
        v = {ramp = 'wood', step = 2, h = 7},
        -- ferro: corpo, fio claro, contorno escuro, ferrugem
        i = {ramp = 'iron', step = 3, h = 9},
        I = {ramp = 'iron', step = 5, h = 10},
        t = {ramp = 'iron', step = 1, h = 9},
        r = {ramp = 'rust', step = 3, h = 8},
        -- vidro da lamparina: poucos pixels quentes, reflexo sem bloom
        g = {ramp = 'ember', step = 5, h = 11, e = 'ember.4', ei = 0.3},
        -- chama pequena e estável: ei~0.9, núcleo 'O' estoura
        f = {ramp = 'ember', step = 3, h = 13, e = 'ember.4', ei = 0.9},
        F = {ramp = 'ember', step = 5, h = 14, e = 'ember.6', ei = 0.9},
        O = {ramp = 'ember', step = 6, h = 15, e = 'ember.7', ei = 0.9},
        -- base de pedra e chão
        s = {ramp = 'stone', step = 4, h = 4},
        S = {ramp = 'stone', step = 5, h = 5},
        m = {ramp = 'stone', step = 2, h = 3},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {name = 'poste', h = 7, albedo = R(poste)},
        {   -- f1..f4 = loop de flicker da lamparina (ver cabeçalho)
            name = 'lamp', h = 10,
            albedo = {R(lamp), R(lamp2), R(lamp3), R(lamp4)},
            emissive = {emisDe(lamp), emisDe(lamp2),
                emisDe(lamp3), emisDe(lamp4)},
        },
    },
}
