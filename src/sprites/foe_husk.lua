-- ECO NASCENTE (foe_husk) — a despedida que ainda não acabou de nascer,
-- 64x96, origem nos pés. Casulo de placas de pedra MEIO-formado: lado
-- esquerdo com casca completa e fenda central tímida; lado direito ainda
-- em borda instável — a casca termina em degraus abertos e lascas 's'/'D'
-- ficam suspensas onde a pedra não assentou. O núcleo 'n' (brasa baixa)
-- só existe onde se vê: filete da fenda + cunha aberta da borda direita —
-- assim albedo e emissivo podem usar o mesmo mapa sem vazar pela casca.
-- Frames: [1,2] idle (o brilho pulsa 1px), [3] WARN = eclosão: a fenda
-- abre, a cunha dilata e o interior acende 'N' (vulnerável).
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
-- CORE: núcleo informe de brasa 'n' — SÓ nas aberturas: filete irregular
-- da fenda (cols ~27-33) e a cunha que vaza pela borda instável (cols
-- ~34-46). Atrás da casca fechada não há núcleo desenhado.
--------------------------------------------------------------------------------
local core = {
    -- filete da fenda (cols 27-33, desce torto) + cunha aberta da borda
    [61] = '............................n.......nnnn',
    [62] = '...........................nn........nnnnn',
    [63] = '..........................nn.......nnnnnn',
    [64] = '..........................nn.......nnnnnnn',
    [65] = '...........................nn......nnnnnnnn',
    [66] = '............................nn....nnnnnnnnn',
    [67] = '.............................nn...nnnnnnnnnn',
    [68] = '..............................nn..nnnnnnnnn',
    [69] = '..............................nn.nnnnnnnnnn',
    [70] = '...............................nn.nnnnnnnnn',
    [71] = '................................nnnnnnnnnnn',
    [72] = '....................................nnnnnnnn',
    [73] = '.....................................nnnnnn',
    [74] = '......................................nnnn',
    [75] = '......................................nnn',
}

-- WARN: o núcleo dilata — a fenda segue os buracos abertos da cascaWarn
-- e a cunha empurra para fora da borda instável.
local coreWarn = {
    [58] = '................................n',
    [59] = '..............................nn',
    [60] = '..............................nnn......nn',
    [61] = '...........................nnnn.....nnnn',
    [62] = '...........................nnnn....nnnnnn',
    [63] = '..........................nnnn...nnnnnnn',
    [64] = '..........................nnnn..nnnnnnnn',
    [65] = '...........................nnnn..nnnnnnnnn',
    [66] = '............................nnnn.nnnnnnnnnnn',
    [67] = '.............................nnnn.nnnnnnnnnnnn',
    [68] = '..............................nnnn.nnnnnnnnnnnn',
    [69] = '...............................nnn.nnnnnnnnnnnn',
    [70] = '................................nnn.nnnnnnnnnnn',
    [71] = '................................nnnnnnnnnnnnnnn',
    [72] = '.................................nnnnnnnnnnnnn',
    [73] = '.................................nnnnnnnnnnnn',
    [74] = '..................................nnnnnnnnnn',
    [75] = '..................................nnnnnnnnn',
    [76] = '...................................nnnnnnn',
    [77] = '....................................nnnn',
}

-- Emissivo = mesmas posições do albedo trocando o char (garante que o
-- brilho nunca vaze por baixo de casca fechada).
local function emit(map, ch)
    local t = {}
    for r, s in pairs(map) do t[r] = (s:gsub('n', ch or 'n')) end
    return t
end

--------------------------------------------------------------------------------
-- SHELL: domo de placas — lado esquerdo inteiro ('T' loma, 'S' base,
-- 's' sombra, musgo 'm'), fenda central '.'/'k' estreita, lado direito
-- terminando em degraus ABERTOS (a casca não fechou). Base enterrada em
-- entulho 's'/'D'.
--------------------------------------------------------------------------------
local shell = {
    [54] = '..........................kkkk',
    [55] = '.........................kTTTTk',
    [56] = '........................kTSSSSSSk',
    [57] = '.......................kTSSSSSSSSk',
    [58] = '......................kTSSSSSSSSSSk',
    [59] = '.....................kTSSSShSSSSSSk',
    [60] = '....................kTSSSSShSSSSSSSSk',
    [61] = '...................kTSSSSSSk.SSSSSSk',
    [62] = '..................kTSSSSSSk..SSSSSSSk',
    [63] = '.................kTSSSSmSSk..SSSSSSk',
    [64] = '.................kTSSSSSmSk..SSSSSSk',
    [65] = '.................kTSSSSSSSk..SSSSSk',
    [66] = '.................kTSSSSSSSSk..SSSSk',
    [67] = '.................kTSSSSSSSSSk..SSSk',
    [68] = '.................kTSSSmSSSSSSk..Sk',
    [69] = '.................kTSSSSSSSSSSk..k',
    [70] = '.................kTSSSSSSSSSSSk.k',
    [71] = '.................kTSSSSSSSSSSSSkk',
    [72] = '.................kTSSSSSSSSSSSSSk',
    [73] = '.................kTSSSSSSSSSSSSSSk',
    [74] = '................kTSSSSSSSSSSSSSSSSk',
    [75] = '................kTSSSSSSSSSSSSSSSSSk',
    [76] = '................kTSSSSSSSSSSSSSSSSSSk',
    [77] = '................kTSSSSSSSSSSSSSSSSSSk',
    [78] = '................kTSSSSSSSSSSSSSSSSSSSk',
    -- costura ventral e base enterrada em entulho
    [79] = '................ksDsDsDsDsDsDsDsDsDsDsk',
    [80] = '...............kssssssssssssssssssssssk',
    [81] = '...............kssssssssssssssssssssssk',
    [82] = '...............kssssssssssssssssssssssk',
    [83] = '...............kssssssssssssssssssssssk',
    [84] = '..............ksssssssssssssssssssssssk',
    [85] = '..............ksssssssssssssssssssssssk',
    [86] = '..............ksssssssssssssssssssssssk',
    [87] = '.............kssssssssssssssssssssssssk',
    [88] = '.............kssssssssssssssssssssssssk',
    [89] = '.............kssssssssssssssssssssssssk',
    [90] = '............kDssssssssssssssssssssssssDk',
    [91] = '............kDssssssssssssssssssssssssDk',
    [92] = '............kkkkkkkkkkkkkkkkkkkkkkkkkkkk',
}

-- WARN: a fenda abre de vez e a borda direita escancara — a casca está
-- prestes a ceder. Mesma silhueta externa, buracos maiores.
local shellWarn = {
    [54] = '..........................kkkk',
    [55] = '.........................kTTTTk',
    [56] = '........................kTSSSSSSk',
    [57] = '.......................kTSSSSSSSSk',
    [58] = '......................kTSSSSSSS.SSk',
    [59] = '.....................kTSSSShSS.SSSSk',
    [60] = '....................kTSSSSShSS.SSSSSSk',
    [61] = '...................kTSSSSSSk...SSSSSk',
    [62] = '..................kTSSSSSSk...SSSSSSk',
    [63] = '.................kTSSSSmSSk...SSSSSk',
    [64] = '.................kTSSSSSmSk...SSSSSk',
    [65] = '.................kTSSSSSSSk...SSSSk',
    [66] = '.................kTSSSSSSSSk...SSSk',
    [67] = '.................kTSSSSSSSSSk...SSk',
    [68] = '.................kTSSSmSSSSSSk...k',
    [69] = '.................kTSSSSSSSSSSk..k',
    [70] = '.................kTSSSSSSSSSSSk.k',
    [71] = '.................kTSSSSSSSSSSSSkk',
    [72] = '.................kTSSSSSSSSSSSSSk',
    [73] = '.................kTSSSSSSSSSSSSSSk',
    [74] = '................kTSSSSSSSSSSSSSSSSk',
    [75] = '................kTSSSSSSSSSSSSSSSSSk',
    [76] = '................kTSSSSSSSSSSSSSSSSSSk',
    [77] = '................kTSSSSSSSSSSSSSSSSSSk',
    [78] = '................kTSSSSSSSSSSSSSSSSSSSk',
    [79] = '................ksDsDsDsDsDsDsDsDsDsDsk',
    [80] = '...............kssssssssssssssssssssssk',
    [81] = '...............kssssssssssssssssssssssk',
    [82] = '...............kssssssssssssssssssssssk',
    [83] = '...............kssssssssssssssssssssssk',
    [84] = '..............ksssssssssssssssssssssssk',
    [85] = '..............ksssssssssssssssssssssssk',
    [86] = '..............ksssssssssssssssssssssssk',
    [87] = '.............kssssssssssssssssssssssssk',
    [88] = '.............kssssssssssssssssssssssssk',
    [89] = '.............kssssssssssssssssssssssssk',
    [90] = '............kDssssssssssssssssssssssssDk',
    [91] = '............kDssssssssssssssssssssssssDk',
    [92] = '............kkkkkkkkkkkkkkkkkkkkkkkkkkkk',
}

--------------------------------------------------------------------------------
-- CHIPS: lascas suspensas junto à borda instável — a pedra que ainda não
-- assentou. WARN sobem 2px (a eclosão as solta).
--------------------------------------------------------------------------------
local chips = {
    [57] = '............................................kSSk',
    [62] = '.............................................ksk',
    [67] = '..............................................kDk',
    [72] = '..............................................kssk',
    [76] = '...............................................k',
}

return {
    name = 'foe_husk',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 3},
        s = {ramp = 'stone', step = 3, h = 5},
        S = {ramp = 'stone', step = 4, h = 6},
        h = {ramp = 'stone', step = 5, h = 7},
        T = {ramp = 'stone', step = 6, h = 8},
        D = {ramp = 'stone', step = 2, h = 4},
        m = {ramp = 'moss', step = 2, h = 4},
        n = {ramp = 'ember', step = 3, h = 4, e = 'ember.4', ei = .35},
        N = {ramp = 'ember', step = 5, h = 5, e = 'ember.6', ei = .95},
    },

    layers = {
        {name = 'core', h = 3, albedo = {
            R(core),
            R(shift(core, 1, 58, 77)),       -- pulsa
            R(coreWarn),
        }, emissive = {
            -- mesmas posições do albedo: só brilha onde está à mostra
            R(emit(core)),
            R(shift(emit(core), 1, 58, 77)),
            R(emit(coreWarn, 'N')),
        }},
        {name = 'shell', h = 6, albedo = {
            R(shell), R(shell), R(shellWarn),
        }},
        {name = 'chips', h = 5, albedo = {
            R(chips), R(chips), R(shift(chips, -2, 57, 73)),
        }},
    },
}
