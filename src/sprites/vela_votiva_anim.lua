-- VELA_VOTIVA_ANIM — vela baixa ACESA, 64x64, origem topleft.
-- Def paralela de vela_votiva.lua: lá os 2 frames são ESTADOS por flag
-- (f1 acesa / f2 apagada) e não podem virar loop — aqui f1..f3 são o
-- loop ambiental da chama acesa: f1 = base (igual ao estado aceso),
-- f2 pende à direita, f3 pende à esquerda. Cera, prato e chão são
-- estáticos; só os 4 pixels de chama (linhas 38-41, cols 30-34) dançam.
-- ei ~0.5 mantido: preciosa, não farol (mesma régua do def original).

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

-- Corpo da vela: cera + prato + chão (estático, igual em todos os
-- frames). A chama entra por linha nas linhas 38-41.
local function corpo(topo)
    return grid {
        E, E, E, E, E, E, E, E, E, E,        --  1-10
        E, E, E, E, E, E, E, E, E, E,        -- 11-20
        E, E, E, E, E, E, E, E, E, E,        -- 21-30
        E, E, E, E, E, E, E,                 -- 31-37
        topo[1], topo[2], topo[3], topo[4],  -- 38-41: a chama
        L'..............................k',        -- 42: pavio
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
    }
end

-- Emissivo: só a chama emite (mesmo desenho do albedo nas linhas 38-41).
local function brilho(topo)
    return grid {
        E, E, E, E, E, E, E, E, E, E,        --  1-10
        E, E, E, E, E, E, E, E, E, E,        -- 11-20
        E, E, E, E, E, E, E, E, E, E,        -- 21-30
        E, E, E, E, E, E, E,                 -- 31-37
        topo[1], topo[2], topo[3], topo[4],  -- 38-41
        E, E, E, E, E, E, E, E, E,           -- 42-50
        E, E, E, E, E, E, E, E,              -- 51-58
        E, E, E, E, E, E,                    -- 59-64
    }
end

-- f1 base / f2 pende à direita / f3 pende à esquerda — ponta oscila
-- 1 px e o corpo 'fFf' desliza 1 px dentro da mesma altura.
local TOPOS = {
    {
        L'...............................f',
        L'..............................fFf',
        L'..............................fFf',
        L'...............................f',
    },
    {
        L'................................f',
        L'...............................fFf',
        L'..............................fFf',
        L'...............................f',
    },
    {
        L'..............................f',
        L'.............................fFf',
        L'..............................fFf',
        L'...............................f',
    },
}

return {
    name = 'vela_votiva_anim',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        -- chama: núcleo claro, corpo de brasa — único emissor de verdade
        f = {ramp = 'ember', step = 5, h = 6, e = 'ember.6', ei = 0.5},
        F = {ramp = 'ember', step = 6, h = 6, e = 'ember.7', ei = 0.6},
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
            -- f1..f3 = loop da chama acesa (ver cabeçalho)
            name = 'vela',
            h = 4,
            albedo = {corpo(TOPOS[1]), corpo(TOPOS[2]), corpo(TOPOS[3])},
            emissive = {brilho(TOPOS[1]), brilho(TOPOS[2]),
                brilho(TOPOS[3])},
        },
    },
}
