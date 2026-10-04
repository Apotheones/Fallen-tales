-- RASTEJANTE (foe_crawler) — eco quadrúpede dos sepultados, 64x96,
-- origem nos pés. Canvas alto de propósito: o corpo ocupa só o terço
-- inferior — a criatura é ACHATADA (casco baixo, patas abertas) e o ar
-- acima dela é o que separa rastejante de bruto. Não usei 64x64 para
-- manter o frame comum da família e dar teto ao WARN (o dorso arqueia
-- para cima antes do bote).
-- Leitura: domo de placas de pedra com fendas e musgo, tira de pano
-- violeta pendurada sob a saia ventral, crânio baixo com dois olhos de
-- brasa pequenos, garras de osso nas patas dianteiras.
-- Frames: [1,2] idle (respiração: casco sobe/desce 1px), [3] WARN =
-- agacha para saltar: casco desce 3px, cabeça projeta à frente, garras
-- se abrem, olhos acendem (ei .4 -> 1).
--
--   0123456789 123456789 123456789 123456789 123456789 123456789 1234
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

--------------------------------------------------------------------------------
-- LEGS: traseiras externas escuras 's', dianteiras grossas com garra de
-- osso 'b'/'B'. Coxa sai da lateral do casco, joelho para fora, canela
-- desce, garra larga plantada.
--------------------------------------------------------------------------------
local legs = {
    -- traseiras saem da lateral do casco e VARREM PARA BAIXO até a
    -- garra 'B' no chão (antes subiam como antenas — erro de leitura)
    [60] = '...........kk.....................................kk',
    [61] = '.........kssk......................................kssk',
    [62] = '........kssssk....................................kssssk',
    [63] = '........kssssk....................................kssssk',
    [64] = '.......kssk........................................kssk',
    [65] = '.......kssk........................................kssk',
    [66] = '......kssk..........................................kssk',
    [67] = '......kssk..........................................kssk',
    [68] = '......kssk..........................................kssk',
    [69] = '.....kssk............................................kssk',
    [70] = '.....kssk............................................kssk',
    [71] = '.....kssk............................................kssk',
    [72] = '.....kssk............................................kssk',
    [73] = '.....kssk............................................kssk',
    [74] = '.....kssk.....kk..............................kk.....kssk',
    [75] = '.....kssk....kSSk............................kSSk....kssk',
    [76] = '.....kssk..kSSSSk............................kSSSSk..kssk',
    [77] = '.....kssk..kSSSSk............................kSSSSk..kssk',
    [78] = '.....kssk.kSSSSk..............................kSSSSk.kssk',
    [79] = '.....kssk..kSSk..................................kSSk..kssk',
    [80] = '.....kssk..kSSk..................................kSSk..kssk',
    [81] = '.....kssk..kSSk..................................kSSk..kssk',
    [82] = '.....kssk.kSSk....................................kSSk.kssk',
    -- garras traseiras de osso tocando o chão
    [83] = '....kbbk..kSSk....................................kSSk..kbbk',
    [84] = '....kbbk..kSSk....................................kSSk..kbbk',
    [85] = '....kBkBk.kSSSSk................................kSSSSk.kBkBk',
    [86] = '....kkkkk.kSSSSk................................kSSSSk.kkkkk',
    -- patas dianteiras: pé de bloco + garras de osso abertas
    [87] = '...........kSSSSk................................kSSSSk',
    [88] = '...........kSSSSk................................kSSSSk',
    [89] = '...........kSSSSk................................kSSSSk',
    [90] = '..........kSSbSSk...............................kSSbSSk',
    [91] = '..........kSbbSSk...............................kSSbbSk',
    [92] = '.........kbbbbbbk.................................kbbbbbbk',
    [93] = '.........kBbbBbk.................................kBbbBbk',
    [94] = '.........kkkkkkkk................................kkkkkkkk',
}

-- WARN não mexe nas patas: o agachamento lê no casco que desce 3px e na
-- cabeça que avança — patas firmes = animal carregado.

--------------------------------------------------------------------------------
-- SHELL: domo de placas. Borda 'k', luz de loma 'T' (stone.6) à esquerda/
-- topo, base 'S' (stone.4), sombra 's' (stone.3) à direita, fundo 'D'.
-- Fendas de placa verticais com musgo 'm'. Saia ventral escalonada 's'.
-- Tira de pano violeta 'v'/'u'/'V' pendurada sob a saia.
--------------------------------------------------------------------------------
local shell = {
    -- espinhos do dorso (três pontas sobre a crista)
    [44] = '............................k....k....k',
    [45] = '...........................kTk..kTk..kTk',
    -- domo
    [46] = '..........................kTTTTTTTTTTk',
    [47] = '.........................kTSSSSSSSSSSk',
    [48] = '........................kTSSSSSSSSSSSSk',
    [49] = '.......................kTSSSSSSSSSSSSSSk',
    [50] = '......................kTSSSSSSSSSSSSSSSSk',
    [51] = '.....................kTSSSSSSSSSSSSSSSSSSk',
    [52] = '....................kTSSSSSSSSSSSSSSSSSSSSk',
    [53] = '...................kTSSSSSSSSSSSSSSSSSSSSSSk',
    [54] = '..................kTSSSSSSSSSSSSSSSSSSSSSSSSk',
    [55] = '.................kTSSSSSSSSSSSSSSSSSSSSSSSSSSk',
    [56] = '.................kTSSSShSSSSSSSSSSSShSSSSSSsk',
    [57] = '................kTSSSSShSSSSSSSSSSSSSShSSSSSSsk',
    [58] = '................kTSSSSSSSSSSSkSSSSkSSSSSSSSSSsk',
    [59] = '...............kTSSSSSSSSSSSkSSSSkSSSSSSSSSSssk',
    [60] = '...............kTSSSSSSSSSSkSSSSSSkSSSSSSSSsssk',
    [61] = '..............kTSSSSSSSSSSkSSSSSSSSkSSSSSSSsssk',
    [62] = '..............kTSSSSmSSSSSkSSSSSSSSkSSSSSmSSssk',
    [63] = '.............kTSSSSSmSSSSkSSSSSSSSSSkSSSSmSSSssk',
    [64] = '.............kSSSSSSmSSSSkSSSSSSSSSSkSSSSmSSSssk',
    -- saia ventral: fileira escura escalonada sob o domo
    [65] = '.............ksDsDsDsDsDsDsDsDsDsDsDsDsDsDsDsDssk',
    [66] = '..............ksssssssssssssssssssssssssssssssk',
    [67] = '...............kssssssssssssssssssssssssssssk',
    -- pano violeta pendurado: trapos com pontas irregulares
    [68] = '..................kuuvvvvvvvvvvvvvvvvvvvvvuuk',
    [69] = '..................kuvvVvvvvvvvvvvvvvvvvVvvuk',
    [70] = '..................kuvvvvvvvVvvvvvvVvvvvvvuk',
    [71] = '...................kuvvvvvvvvvvvvvvvvvvvvuk',
    [72] = '...................kuvVvvvvvvvvvvvvvvvVvvuk',
    [73] = '....................kuvvvvvvvvvvvvvvvvvvuk',
    [74] = '....................kuvvVvvvvvvvvvvvVvvuk',
    [75] = '.....................kuvvvvvvvvvvvvvvvuk',
    [76] = '.....................kuvvvvvvvvvvvvvuk',
    [77] = '......................kuvVvvvvvvvVvvuk',
    [78] = '......................kuvvvvvvvvvvvuk',
    [79] = '.......................kuvvvvvvvvuk',
    [80] = '.......................kuvvVvvVvvuk',
    [81] = '........................kuvvvvvvuk',
    [82] = '........................kuvv..vvuk',
    [83] = '.........................kvv..vvk',
    [84] = '.........................kuk..kuk',
    [85] = '..........................k....k',
}

--------------------------------------------------------------------------------
-- HEAD: crânio baixo à frente do pano — testa de pedra com rebordos de
-- osso 'b', dois olhos 'e' pequenos (emissivo no canal próprio), focinho
-- estreito, mandíbula com presas 'B'.
--------------------------------------------------------------------------------
local head = {
    [68] = '...........................kkkkkkkkk',
    [69] = '..........................kSSSSSSSSk',
    [70] = '.........................kSSSSSSSSSSk',
    [71] = '.........................kSbSSSSSSbSk',
    [72] = '........................kSSbSSSSSSbSSk',
    [73] = '........................kSSSSSSSSSSSSk',
    [74] = '........................kSSeeSSSSeeSSk',
    [75] = '........................kSSeeSSSSeeSSk',
    [76] = '.........................kSSSSSSSSSSk',
    [77] = '.........................kSSSSSSSSSSk',
    [78] = '..........................kSSSSSSSSk',
    [79] = '..........................kSbSSSSbSk',
    [80] = '..........................kbbSSSSbbk',
    [81] = '...........................kBSSSSBk',
    [82] = '...........................kBkSSkBk',
    [83] = '............................kkkkkk',
}

-- WARN: crânio desce 4px e avança — olhos 'E' (o albedo do olho aberto é
-- o mesmo degrau; o canal emissivo é que acende), mandíbula aberta.
local headWarn = {
    [71] = '...........................kkkkkkkkk',
    [72] = '..........................kSSSSSSSSk',
    [73] = '.........................kSSSSSSSSSSk',
    [74] = '.........................kSbSSSSSSbSk',
    [75] = '........................kSSbSSSSSSbSSk',
    [76] = '........................kSSSSSSSSSSSSk',
    [77] = '........................kSSEESSSSEESSk',
    [78] = '........................kSSEESSSSEESSk',
    [79] = '.........................kSSSSSSSSSSk',
    [80] = '.........................kSSSSSSSSSSk',
    [81] = '..........................kSSSSSSSSk',
    [82] = '..........................kbbSSSSbbk',
    [83] = '..........................kBkkkkkkBk',
    [84] = '..........................kB.SSSS.Bk',
    [85] = '...........................kSSSSSSk',
    [86] = '............................kkkkkk',
}

return {
    name = 'foe_crawler',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 5},
        S = {ramp = 'stone', step = 4, h = 6},
        h = {ramp = 'stone', step = 5, h = 7},
        T = {ramp = 'stone', step = 6, h = 8},
        D = {ramp = 'stone', step = 2, h = 4},
        b = {ramp = 'bone', step = 4, h = 5},
        B = {ramp = 'bone', step = 5, h = 6},
        v = {ramp = 'violet', step = 3, h = 4},
        u = {ramp = 'violet', step = 2, h = 3},
        V = {ramp = 'violet', step = 4, h = 5},
        m = {ramp = 'moss', step = 2, h = 4},
        e = {ramp = 'ember', step = 4, h = 7, e = 'ember.5', ei = .4},
        E = {ramp = 'ember', step = 5, h = 7, e = 'ember.6', ei = 1},
    },

    layers = {
        {name = 'legs', h = 4, albedo = {
            R(legs), R(legs), R(legs),
        }},
        {name = 'shell', h = 6, albedo = {
            R(shell),
            R(shift(shell, 1, 46, 67)),      -- expira: casco desce 1px
            R(shift(shell, 3, 44, 67)),      -- WARN: agacha
        }},
        {name = 'head', h = 7, albedo = {
            R(head),
            R(shift(head, 1, 68, 83)),       -- cabeça acompanha a descida
            R(headWarn),
        }, emissive = {
            R {
                [74] = '...........................ee....ee',
                [75] = '...........................ee....ee',
            },
            R {
                [75] = '...........................ee....ee',
                [76] = '...........................ee....ee',
            },
            R {
                [77] = '...........................EE....EE',
                [78] = '...........................EE....EE',
                -- juntas das patas dianteiras acendem no bote
                [85] = '...........e..................e',
                [88] = '.........e......................e',
            },
        }},
    },
}
