-- CADEIRA simples — prop de chão, 64x96, origem nos pés.
-- Cadeira de madeira do Refúgio em 3/4: encosto com duas travessas,
-- assento em trapézio (frente mais larga que o fundo), quatro pernas
-- com trave lateral. Madeira de uso, sem ornamento.
-- Relevo: encosto 8-9, assento 7-8, pernas 4-5, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'cadeira',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 4},
        -- encosto: topo claro, ripas, laterais em sombra
        W = {ramp = 'wood', step = 6, h = 9},
        w = {ramp = 'wood', step = 4, h = 8},
        q = {ramp = 'wood', step = 2, h = 8},
        -- assento: tampa e frente
        s = {ramp = 'wood', step = 4, h = 8},
        S = {ramp = 'wood', step = 6, h = 8},
        F = {ramp = 'wood', step = 3, h = 6},
        -- pernas e trave
        l = {ramp = 'wood', step = 4, h = 5},
        p = {ramp = 'wood', step = 2, h = 4},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {   -- CADEIRA inteira em uma camada: encosto atrás, assento,
            -- avental e pernas até o chão
            name = 'cadeira',
            h = 6,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E,                              -- 31-34
                -- encosto: postes + ripa de cima
                L'.....................WWWWWWWWWWWWWWWWWW', -- 35
                L'.....................wqqqqqqqqqqqqqqqqq', -- 36
                L'.....................wwq.............ww', -- 37
                L'.....................wwq.............wq', -- 38
                L'.....................wwq.............ww', -- 39
                L'.....................wwq.............ww', -- 40
                L'.....................wwq.............ww', -- 41
                L'.....................wwq.............ww', -- 42
                -- ripa do meio do encosto
                L'.....................wwwwwwwwwwwwwwwwww', -- 43
                L'.....................wwwwwwwwwwwwwwwwww', -- 44
                L'.....................wwq.............ww', -- 45
                L'.....................wwq.............ww', -- 46
                L'.....................wwq.............ww', -- 47
                L'.....................wwq.............ww', -- 48
                L'.....................wwq.............ww', -- 49
                L'.....................wwq.............ww', -- 50
                L'.....................wwq.............ww', -- 51
                L'.....................wwq.............ww', -- 52
                L'.....................wwq.............ww', -- 53
                L'.....................wwq.............ww', -- 54
                L'.....................wwq.............ww', -- 55
                L'.....................wwq.............ww', -- 56
                L'.....................wwq.............ww', -- 57
                -- assento em trapézio (mais largo na frente)
                L'.....................wSSSSSSSSSSSSSSSSw', -- 58
                L'...................wsssssssssssssssssssss', -- 59
                L'..................wssssssssssssssssssssss', -- 60
                L'.................wssssssssssssssssssssssss', -- 61
                L'................wsssssssssssssssssssssssss', -- 62
                L'................wsssssssssssssssssssssssss', -- 63
                L'................wssssssssssssssssssssssssk', -- 64
                -- frente do assento (avental)
                L'................FFFFFFFFFFFFFFFFFFFFFFFFFk', -- 65
                L'................FFFFFFFFFFFFFFFFFFFFFFFFFk', -- 66
                L'................FFFFFFFFFFFFFFFFFFFFFFFFFk', -- 67
                L'................kkkkkkkkkkkkkkkkkkkkkkkkkk', -- 68
                E,                                            -- 69
                -- pernas: duas de trás (escuras, entre as da frente) +
                -- duas da frente nos cantos do assento; trave lateral
                L'....................pp...............pp',       -- 70
                L'....................pp...............pp',       -- 71
                L'................lll.pp...............pp.lll',   -- 72
                L'................lll.pp...............pp.lll',   -- 73
                L'................lll.pp...............pp.lll',   -- 74
                L'................lll.pp...............pp.lll',   -- 75
                L'................lll.pp...............pp.lll',   -- 76
                L'................lllllll.............llllll',    -- 77
                L'................lll.................lll',       -- 78
                L'................lll.................lll',       -- 79
                L'................lll.................lll',       -- 80
                L'................lll.................lll',       -- 81
                L'................lll.................lll',       -- 82
                L'................lll.................lll',       -- 83
                L'................lll.................lll',       -- 84
                L'................lll.................lll',       -- 85
                L'................lll.................lll',       -- 86
                L'................lll.................lll',       -- 87
                L'................lll.................lll',       -- 88
                L'................lll.................lll',       -- 89
                L'................lll.................lll',       -- 90
                L'................lll.................lll',       -- 91
                L'................lkk.................kkl',       -- 92
                -- contato com o chão
                L'................lkk........e........kkl',       -- 93
                L'.................e.....e........e....e',        -- 94
                L'...................e.....e.....e',              -- 95
                L'................e......e......e....e',          -- 96
            },
        },
    },
}
