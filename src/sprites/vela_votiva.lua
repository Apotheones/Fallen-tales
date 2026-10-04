-- VELA_VOTIVA — vela baixa ao pé da lápide, 64x64, origem topleft.
-- Colina dos Sepultados (docs/DIRECAO_AMBIENTAL_HD.md §COLINA): o ÚNICO
-- quente da região — cera de osso sobre prato de pedra, chama pequena de
-- brasa com ei ~0.5 (preciosa, não farol). 2 frames: acesa / apagada
-- (a apagada guarda só um resíduo morno no pavio, ei 0.12).
-- Relevo: chama 6, pavio 5, cera 4, prato 2, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'vela_votiva',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        -- chama: núcleo claro, corpo de brasa — único emissor de verdade
        f = {ramp = 'ember', step = 5, h = 6, e = 'ember.6', ei = 0.5},
        F = {ramp = 'ember', step = 6, h = 6, e = 'ember.7', ei = 0.6},
        r = {ramp = 'ember', step = 2, h = 5, e = 'ember.1', ei = 0.12},
        -- pavio e cera
        k = {spec = 'ink', h = 5},
        O = {ramp = 'bone', step = 5, h = 4},
        o = {ramp = 'bone', step = 4, h = 4},
        n = {ramp = 'bone', step = 2, h = 4},
        -- prato de pedra fria e chão
        a = {ramp = 'stone', step = 3, h = 2},
        q = {ramp = 'stone', step = 2, h = 2},
        e = {ramp = 'earth', step = 3, h = 1},
        v = {ramp = 'earth', step = 2, h = 1},
    },

    layers = {
        {
            name = 'vela',
            h = 4,
            albedo = {
                -- frame 1: acesa
                grid {
                    E, E, E, E, E, E, E, E, E, E,        --  1-10
                    E, E, E, E, E, E, E, E, E, E,        -- 11-20
                    E, E, E, E, E, E, E, E, E, E,        -- 21-30
                    E, E, E, E, E, E, E,                 -- 31-37
                    L'...............................f',       -- 38
                    L'..............................fFf',      -- 39
                    L'..............................fFf',      -- 40
                    L'...............................f',       -- 41
                    L'..............................k',        -- 42
                    L'..............................ooOOo',    -- 43
                    L'.............................oOOOOo',    -- 44
                    L'............................oOoooOon',   -- 45
                    L'............................oOooooon',   -- 46
                    L'............................oOooooon',   -- 47
                    L'............................oOoooOon',   -- 48
                    L'............................oOooooon',   -- 49
                    L'............................oOooooon',   -- 50
                    L'............................oOoooon',    -- 51
                    L'............................oooonn',     -- 52
                    L'...........................qqaaaaaaqq',  -- 53
                    L'..........................aaaaaaaaaaa',  -- 54
                    L'..........................vveeeeeeveee', -- 55
                    L'.........................eevveeeveeevve',-- 56
                    E, E, E, E, E, E, E, E,                    -- 57-64
                },
                -- frame 2: apagada — pavio exposto, sem chama
                grid {
                    E, E, E, E, E, E, E, E, E, E,        --  1-10
                    E, E, E, E, E, E, E, E, E, E,        -- 11-20
                    E, E, E, E, E, E, E, E, E, E,        -- 21-30
                    E, E, E, E, E, E, E, E, E, E,        -- 31-40
                    E,                                     -- 41
                    L'..............................k',        -- 42
                    L'..............................ooOOo',    -- 43
                    L'.............................oOOOOo',    -- 44
                    L'............................oOoooOon',   -- 45
                    L'............................oOoooon',    -- 46
                    L'............................oOooooon',   -- 47
                    L'............................oOoooOon',   -- 48
                    L'............................oOooooon',   -- 49
                    L'............................oOooooon',   -- 50
                    L'............................oOoooon',    -- 51
                    L'............................oooonn',     -- 52
                    L'...........................qqaaaaaaqq',  -- 53
                    L'..........................aaaaaaaaaaa',  -- 54
                    L'..........................vveeeeeeveee', -- 55
                    L'.........................eevveeeveeevve',-- 56
                    E, E, E, E, E, E, E, E,                    -- 57-64
                },
            },
            emissive = {
                -- chama do frame 1
                grid {
                    E, E, E, E, E, E, E, E, E, E,        --  1-10
                    E, E, E, E, E, E, E, E, E, E,        -- 11-20
                    E, E, E, E, E, E, E, E, E, E,        -- 21-30
                    E, E, E, E, E, E, E,                 -- 31-37
                    L'...............................f',       -- 38
                    L'..............................fFf',      -- 39
                    L'..............................fFf',      -- 40
                    L'...............................f',       -- 41
                    E, E, E, E, E, E, E, E,            -- 42-49
                    E, E, E, E, E, E, E, E,            -- 50-57
                    E, E, E, E, E, E, E,               -- 58-64
                },
                -- frame 2: resíduo morno no pavio (ei 0.12, apagada)
                grid {
                    E, E, E, E, E, E, E, E, E, E,        --  1-10
                    E, E, E, E, E, E, E, E, E, E,        -- 11-20
                    E, E, E, E, E, E, E, E, E, E,        -- 21-30
                    E, E, E, E, E, E, E, E, E, E,        -- 31-40
                    E,                                     -- 41
                    L'..............................r',        -- 42
                    E, E, E, E, E, E, E, E,            -- 43-50
                    E, E, E, E, E, E, E, E,            -- 51-58
                    E, E, E, E, E, E,                  -- 59-64
                },
            },
        },
    },
}
