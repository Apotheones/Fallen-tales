-- PECA_INACABADA — instrumento do Nilo, 64x96, origem nos pés.
-- Oficina do Refúgio (nota vida-refugio-props §10): corpo de
-- instrumento de corda inacabado — madeira clara recém-lavada, sem
-- boca ainda (só o traço marcado), grampos segurando o tampo colado —
-- deitado sobre um cavalete baixo. Feita às pressas, retomada.
-- Relevo: corpo 9-10, grampos 11, cavalete 5, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'peca_inacabada',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 4 },
        -- madeira clara recém-lavada do corpo
        w = { ramp = 'wood', step = 6, h = 10 },
        W = { ramp = 'wood', step = 7, h = 10 },
        v = { ramp = 'wood', step = 5, h = 9 },
        s = { ramp = 'wood', step = 4, h = 9 },   -- junção central do tampo
        -- braço/tojo por afinar
        b = { ramp = 'wood', step = 4, h = 9 },
        -- grampos de ferro segurando o tampo
        i = { ramp = 'iron', step = 4, h = 11 },
        I = { ramp = 'iron', step = 6, h = 11 },
        -- cavalete baixo
        l = { ramp = 'wood', step = 4, h = 5 },
        t = { ramp = 'wood', step = 5, h = 6 },
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {   -- CORPO do instrumento deitado no cavalete + grampos
            name = 'peca',
            h = 8,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,             --  1-10
                E, E, E, E, E, E, E, E,                   -- 11-18
                -- braço/tojo apontando para cima-direita
                L'................................bbbb',      -- 19
                L'...............................bbbbb',      -- 20
                L'..............................bbbbb',       -- 21
                L'.............................bbbbb',        -- 22
                L'............................bbbbb',         -- 23
                L'............................bbbb',          -- 24
                -- boca superior (ombro) do corpo
                L'..........................iwwwwww',         -- 25 (grampo)
                L'......................wwwwwwwwwwww',        -- 26
                L'....................wwwwWwwwwwwwwwww',      -- 27
                L'...................wwwwWWwswwwwwwwwwww',    -- 28
                L'..................wwwwWWsswwwwwwwwwwww',    -- 29
                L'.................wwwwWWssswwwwwwwwwwwww',   -- 30
                -- cintura
                L'..................wwwwWssswwwwwwwwwwww',    -- 31
                L'...................wwwwsssswwwwwwwwwww',    -- 32
                L'....................wwwssssswwwwwwwwww',    -- 33
                L'...................iwwwssssswwwwwwwwwwi',   -- 34 (grampos)
                L'....................wwwwsssswwwwwwwwww',    -- 35
                -- traço da boca marcada a lápis (ainda não cortada)
                L'..................wwwwwssswwvvvvwwwwww',    -- 36
                L'.................wwwwwssswwvwwwwvwwwww',    -- 37
                L'.................wwwwssswwvwwwwwwvwwww',    -- 38
                L'.................wwwwssswwvvvvvvwwwwww',    -- 39
                L'.................wwwwsssswwwwwwwwwwwww',    -- 40
                -- boca inferior (corpão)
                L'................wwwwwwsssswwwwwwwwwwwww',   -- 41
                L'...............wwwwwWwssswwwwwwwwwwwwwww',  -- 42
                L'..............wwwwwWWwssswwwwwwwwwwwwwwwi', -- 43 (grampo)
                L'.............wwwwwWWwwsswwwwwwwwwwwwwwww',  -- 44
                L'.............wwwwWWwwwswwwwwwwwwwwwwwwww',  -- 45
                L'............wwwwwWwwwwwswwwwwwwwwwwwwww',   -- 46
                L'............wwwwWwwwwwwwswwwwwwwwwwwww',    -- 47
                L'...........iwwwwwwwwwwwwwswwwwwwwwwww',     -- 48 (grampo)
                L'............wwwwwwwwwwwwwsswwwwwwww',       -- 49
                L'.............wwwwwwwwwwwwssswwwwww',        -- 50
                L'..............wwwwwwwwwwwissswwwwi',        -- 51 (grampos)
                L'...............wwwwwwwwwwwsswww',           -- 52
                L'................wwwwwwwwwwsss',             -- 53
                E, E, E, E,                                   -- 54-57
                -- CAVALETE baixo: barra + pernas em A
                L'...........tttttttttttttttttttttttttttt',   -- 58
                L'...........lll..................lll',       -- 59
                L'...........lll..................lll',       -- 60
                L'..........lll....................lll',      -- 61
                L'..........lll....................lll',      -- 62
                L'..........lll....................lll',      -- 63
                L'.........lll......................lll',     -- 64
                L'.........lll......................lll',     -- 65
                L'.........lll......................lll',     -- 66
                L'........lll........................lll',    -- 67
                L'........lll........................lll',    -- 68
                L'........llllllllllllllllllllllllllllll',    -- 69
                L'.......lll..........................lll',   -- 70
                L'.......lll..........................lll',   -- 71
                L'......lll............................lll',  -- 72
                L'......lll............................lll',  -- 73
                L'......lll............................lll',  -- 74
                L'.....lll..............................lll', -- 75
                L'.....lll..............................lll', -- 76
                L'.....lll..............................lll', -- 77
                L'....lll................................lll',-- 78
                L'....lll................................lll',-- 79
                L'....lll................................lll',-- 80
                L'....lll................................lll',-- 81
                L'....llk................................kll',-- 82
                -- contato
                L'....llk....e........e.........e........kll',-- 83
                L'.....e.......e........e....e......e',       -- 84
                L'........e......e....e......e.....e',        -- 85
                L'..........e......e......e.....e',           -- 86
                E, E, E, E, E, E, E, E, E, E,             -- 87-96
            },
        },
    },
}
