-- MESA_OFERENDA — mesinha baixa de oferendas, 64x96, origem nos pés.
-- Capela do Refúgio (nota vida-refugio-props §8): mesa baixa junto do
-- altar — pano de uso, moedas de ouro velho DISCRETAS, uma tigela de
-- água e uma vela única acesa fraca (ember ei~0.4). Relevo: tampo 7,
-- objetos 8-10, vela 10, chama 12, pernas 4, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

local ALBEDO = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E, E, E, E, E,                     -- 11-20
    E, E, E, E, E, E, E, E, E,                        -- 21-29
    -- vela única sobre a mesa
    L'.....................k',                          -- 30
    L'.....................Bb',                         -- 31
    L'.....................bb',                         -- 32
    L'.....................bb',                         -- 33
    L'.....................wb',                         -- 34
    -- tampo: pano à esquerda, madeira à direita, oferendas em cima
    L'...............WWWWWWWWWWWWWWWWWWWWWWWWWWWWW',    -- 35
    L'...............wwwwwwwwwwwwwwwwwwwwwwwwwwwww',    -- 36
    L'...............ccccccwwwwwwwwGGwwwwwwwwwwwww',    -- 37
    L'...............cCccccwwwwwwwGGGGwwwbbbbbbwww',    -- 38
    L'...............ccccccwwwwwwwwGGGwwbBddddBbww',    -- 39
    L'...............cCcccwwwwwwwwwGGwwwbBdddBbwww',    -- 40
    L'...............ccccdcwwwwwwwwGwwwwbbbbbbwww',     -- 41
    -- borda frontal: filete + face + contorno; pano cai junto
    L'...............WWWWWWWWWWWWWWWWWWWWWWWWWWWWW',    -- 42
    L'...............FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',   -- 43
    L'...............ddFFFFvFFFFvFFFFvFFFFvFFFFvFFF',   -- 44
    L'...............cdFFFFFFFFFFFFFFFFFFFFFFFFFFFF',   -- 45
    L'...............dc..............................', -- 46
    E,                                                -- 47
    -- pernas baixas + travessa
    L'................lll......................lll',    -- 48
    L'................lll...qq...............qq.lll',   -- 49
    L'................lll...qq...............qq.lll',   -- 50
    L'................lll...qq...............qq.lll',   -- 51
    L'................lll...qq...............qq.lll',   -- 52
    L'................lll...qq...............qq.lll',   -- 53
    L'................lll......................lll',    -- 54
    L'................lllllllllllllllllllllllllll',     -- 55
    L'................lll......................lll',    -- 56
    L'................lll......................lll',    -- 57
    L'................lll......................lll',    -- 58
    L'................lll......................lll',    -- 59
    L'................lll......................lll',    -- 60
    L'................lll......................lll',    -- 61
    L'................lll......................lll',    -- 62
    L'................lll......................lll',    -- 63
    L'................lll......................lll',    -- 64
    L'................lll......................lll',    -- 65
    L'................lll......................lll',    -- 66
    L'................lll......................lll',    -- 67
    L'................lll......................lll',    -- 68
    L'................lll......................lll',    -- 69
    L'................lll......................lll',    -- 70
    L'................lll......................lll',    -- 71
    L'................lll......................lll',    -- 72
    L'................lll......................lll',    -- 73
    L'................lll......................lll',    -- 74
    L'................lll......................lll',    -- 75
    L'................lll......................lll',    -- 76
    L'................lll......................lll',    -- 77
    L'................lll......................lll',    -- 78
    L'................lll......................lll',    -- 79
    L'................lll......................lll',    -- 80
    L'................lll......................lll',    -- 81
    L'................lll......................lll',    -- 82
    L'................lll......................lll',    -- 83
    L'................lll......................lll',    -- 84
    L'................lll......................lll',    -- 85
    L'................lll......................lll',    -- 86
    L'................lll......................lll',    -- 87
    L'................lll......................lll',    -- 88
    L'................lll......................lll',    -- 89
    L'................lll......................lll',    -- 90
    L'................lkk......................kkl',    -- 91
    -- contato
    L'................lkk.......e.............kkl',     -- 92
    L'.................e....e......e....e....e',        -- 93
    L'...................e.....e......e....e',          -- 94
    L'..................e......e....e.....e',           -- 95
    L'....................e.....e......e',              -- 96
}

-- Chama única, fraca: núcleo no pavio, ponta acima.
local EMISSIVO = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E, E, E,                           -- 11-18
    E, E, E, E, E, E, E, E, E, E,                     -- 19-28
    L'.....................f',                          -- 29 (ponta sobre o pavio)
    L'.....................o',                          -- 30 (núcleo no pavio)
    E, E, E, E, E, E, E, E, E, E,                     -- 31-40
    E, E, E, E, E, E, E, E, E, E,                     -- 41-50
    E, E, E, E, E, E, E, E, E, E,                     -- 51-60
    E, E, E, E, E, E, E, E, E, E,                     -- 61-70
    E, E, E, E, E, E, E, E, E, E,                     -- 71-80
    E, E, E, E, E, E, E, E, E, E,                     -- 81-90
    E, E, E, E, E, E,                                 -- 91-96
}

return {
    name = 'mesa_oferenda',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 9 },              -- pavio
        -- tampo e pernas
        W = { ramp = 'wood', step = 6, h = 8 },
        w = { ramp = 'wood', step = 4, h = 7 },
        F = { ramp = 'wood', step = 3, h = 6 },
        v = { ramp = 'wood', step = 2, h = 6 },
        l = { ramp = 'wood', step = 4, h = 4 },
        q = { ramp = 'wood', step = 2, h = 4 },
        -- pano de uso
        c = { ramp = 'bone', step = 4, h = 8 },
        C = { ramp = 'bone', step = 5, h = 8 },
        d = { ramp = 'bone', step = 3, h = 7 },
        -- moedas discretas de ouro velho
        G = { ramp = 'gold', step = 4, h = 8 },
        -- tigela de água: osso com fundo escuro
        b = { ramp = 'bone', step = 4, h = 9 },
        B = { ramp = 'bone', step = 5, h = 9 },
        -- vela e chama fraca
        f = { ramp = 'ember', step = 4, h = 12, e = 'ember.4', ei = 0.35 },
        o = { ramp = 'ember', step = 5, h = 12, e = 'ember.5', ei = 0.4 },
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'mesa',
            h = 6,
            albedo = ALBEDO,
            emissive = EMISSIVO,
        },
    },
}
