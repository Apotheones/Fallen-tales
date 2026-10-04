-- CERCADO de jardim — tile 64x64, origem no canto superior esquerdo.
-- Refúgio: cerca de horta em uso — mourões de madeira clara com duas
-- travessas, levemente torta (manual, nada simétrico), capim na base.
-- 2 frames = 2 variantes de tortura/vegetação, não animação.
-- Relevo baixo: mourões 6-7, travessas 5, capim 2-3.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'cercado',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 4},
        -- mourões: topo claro, corpo, lado em sombra
        P = {ramp = 'wood', step = 6, h = 7},
        p = {ramp = 'wood', step = 4, h = 6},
        q = {ramp = 'wood', step = 3, h = 6},
        -- travessas de madeira clara
        W = {ramp = 'wood', step = 6, h = 5},
        w = {ramp = 'wood', step = 5, h = 5},
        v = {ramp = 'wood', step = 3, h = 5},
        -- capim na base
        g = {ramp = 'moss', step = 4, h = 3},
        G = {ramp = 'moss', step = 2, h = 2},
        e = {ramp = 'earth', step = 3, h = 1},
    },

    layers = {
        {   -- TRAVESSAS: duas tábuas atrás dos mourões, descendo à direita
            name = 'travessas',
            h = 5,
            albedo = {
                grid { -- frame 1
                    E, E, E, E, E, E, E, E, E, E,    --  1-10
                    E, E, E, E, E, E, E, E,          -- 11-18
                    L'.......WWWWWWWWWWWWWWWWWWWWWWWWWW',         -- 19
                    L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwWWWWWWWWWWWWWWWWWW', -- 20
                    L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 21
                    L'.......vwwwwvwwwwwwwwvwwvwwwwvwwwvwwwwvwwwwwwvvwww', -- 22
                    L'................................WWWWWWWWWWWWWWWWWWW',-- 23
                    L'................................wwwwwwwwwwwwwwwwwww',-- 24
                    L'................................vvvwwvwwwwwwvwwwv',-- 25
                    E, E, E, E, E, E, E, E, E, E,    -- 26-35
                    E, E, E,                          -- 36-38
                    L'.......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',  -- 39
                    L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwWWWWWWWWWW', -- 40
                    L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 41
                    L'.......vwwvwwwwwwwwvwwvwwwwvwwwvwwwwvwwvwwwwvww', -- 42
                    L'...........................................wwwwwwwwwwwww',-- 43
                    L'...........................................vwwwwvwwwwwv',-- 44
                    E, E, E, E, E, E, E, E, E, E,    -- 45-54
                    E, E, E, E, E, E, E, E, E, E,    -- 55-64
                },
                grid { -- frame 2: mesmas travessas, caimento diferente
                    E, E, E, E, E, E, E, E, E, E,    --  1-10
                    E, E, E, E, E, E, E, E,          -- 11-18
                    L'.......WWWWWWWWWWWWWWWWWW',                 -- 19
                    L'.......wwwwwwwwwwwwwwwwwwWWWWWWWWWWWWWWWWWWWW', -- 20
                    L'.......wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 21
                    L'.......vwwvwwwwvwwvwwwwvwwwvwwvwwwvwwvwwvv', -- 22
                    L'............................wwwwwwwwwwwwwwwww',-- 23
                    L'............................vwwvwwwvvvwwvww',-- 24
                    E, E, E, E, E, E, E, E, E, E,    -- 25-34
                    E, E, E, E, E,                    -- 35-39
                    L'..........WWWWWWWWWWWWWWWWWWWWWWWWW',      -- 40
                    L'..........wwwwwwwwwwwwwwwwwwwwwwwwwWWWWWWWWWWWWW', -- 41
                    L'..........wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 42
                    L'..........vvwwwwvwwvwwwwvwwvwwwvwwvwwvwwvwwv', -- 43
                    L'.............................................wwwwwwwwwwwww',-- 44
                    L'.............................................vvwwwwvwwww',-- 45
                    E, E, E, E, E, E, E, E, E, E,    -- 46-55
                    E, E, E, E, E, E, E, E, E,       -- 56-64
                },
            },
        },
        {   -- MOURÕES: três estacas por cima das travessas, cada uma torta
            -- do seu jeito; topo claro, lateral direita em sombra
            name = 'mouroes',
            h = 6,
            albedo = {
                grid { -- frame 1
                    E, E, E, E, E, E, E, E, E, E,    --  1-10
                    E, E,                               -- 11-12
                    L'..........PP........................PP',       -- 13
                    L'..........Ppq.......................Ppq',      -- 14
                    L'..........ppq.......................ppq',      -- 15
                    L'..........ppq............PP.........ppq',      -- 16
                    L'..........ppq............Ppq........ppq',      -- 17
                    L'..........ppq............ppq........ppq',      -- 18
                    L'..........ppq............ppq........ppq',      -- 19
                    L'..........ppq............ppq........ppq',      -- 20
                    L'..........ppq............ppq........ppq',      -- 21
                    L'..........ppq............ppq........ppq',      -- 22
                    L'..........ppq............ppq........ppq',      -- 23
                    L'..........ppq............ppq........ppq',      -- 24
                    L'..........ppq............ppq........ppq',      -- 25
                    L'..........ppq............ppq........ppq',      -- 26
                    L'..........ppq............ppq........ppq',      -- 27
                    L'..........ppq.............ppq.......ppq',      -- 28
                    L'..........ppq.............ppq.......ppq',      -- 29
                    L'..........ppq.............ppq.......ppq',      -- 30
                    L'..........ppq.............ppq.......ppq',      -- 31
                    L'..........ppq.............ppq.......ppq',      -- 32
                    L'..........ppq.............ppq........ppq',     -- 33
                    L'..........ppq.............ppq........ppq',     -- 34
                    L'..........ppq.............ppq........ppq',     -- 35
                    L'..........ppq.............ppq........ppq',     -- 36
                    L'..........ppq.............ppq........ppq',     -- 37
                    L'..........ppq.............ppq........ppq',     -- 38
                    L'..........ppq.............ppq........ppq',     -- 39
                    L'..........ppq.............ppq........ppq',     -- 40
                    L'..........ppq.............ppq........ppq',     -- 41
                    L'..........ppq.............ppq........ppq',     -- 42
                    L'..........ppq.............ppq........ppq',     -- 43
                    L'..........ppq..............ppq.......ppq',     -- 44
                    L'..........ppq..............ppq.......ppq',     -- 45
                    L'..........ppq..............ppq.......ppq',     -- 46
                    L'..........ppq..............ppq.......ppq',     -- 47
                    L'..........ppq..............ppq........ppq',    -- 48
                    L'..........ppq..............ppq........ppq',    -- 49
                    L'...........pq...............pq........pq',     -- 50
                    L'...........q................q.........q',      -- 51
                    E, E, E, E, E, E, E, E, E, E, E, E, E, -- 52-64
                },
                grid { -- frame 2: mourões em alturas/posições diferentes
                    E, E, E, E, E, E, E, E, E, E,    --  1-10
                    E, E, E,                          -- 11-13
                    L'............PP................................PP',   -- 14
                    L'............Ppq...............................Ppq',  -- 15
                    L'............ppq......PP.......................ppq',  -- 16
                    L'............ppq......Ppq......................ppq',  -- 17
                    L'............ppq......ppq......................ppq',  -- 18
                    L'............ppq......ppq......................ppq',  -- 19
                    L'............ppq......ppq......................ppq',  -- 20
                    L'............ppq......ppq......................ppq',  -- 21
                    L'............ppq.......ppq.....................ppq',  -- 22
                    L'............ppq.......ppq.....................ppq',  -- 23
                    L'............ppq.......ppq.....................ppq',  -- 24
                    L'............ppq.......ppq.....................ppq',  -- 25
                    L'............ppq.......ppq.....................ppq',  -- 26
                    L'............ppq.......ppq.....................ppq',  -- 27
                    L'............ppq.......ppq.....................ppq',  -- 28
                    L'............ppq.......ppq.....................ppq',  -- 29
                    L'............ppq........ppq....................ppq',  -- 30
                    L'............ppq........ppq....................ppq',  -- 31
                    L'............ppq........ppq....................ppq',  -- 32
                    L'............ppq........ppq....................ppq',  -- 33
                    L'............ppq........ppq....................ppq',  -- 34
                    L'............ppq........ppq....................ppq',  -- 35
                    L'............ppq........ppq....................ppq',  -- 36
                    L'............ppq........ppq....................ppq',  -- 37
                    L'............ppq........ppq....................ppq',  -- 38
                    L'............ppq........ppq....................ppq',  -- 39
                    L'............ppq........ppq....................ppq',  -- 40
                    L'............ppq........ppq....................ppq',  -- 41
                    L'............ppq........ppq....................ppq',  -- 42
                    L'............ppq........ppq....................ppq',  -- 43
                    L'............ppq........ppq....................ppq',  -- 44
                    L'............ppq.........ppq...................ppq',  -- 45
                    L'............ppq.........ppq...................ppq',  -- 46
                    L'............ppq.........ppq...................ppq',  -- 47
                    L'............ppq.........ppq...................ppq',  -- 48
                    L'............ppq.........ppq...................ppq',  -- 49
                    L'.............pq..........pq....................pq',  -- 50
                    L'.............q...........q....................q',   -- 51
                    E, E, E, E, E, E, E, E, E, E, E, E, E, -- 52-64
                },
            },
        },
        {   -- CAPIM: tufo na base dos mourões + mato solto entre eles
            name = 'capim',
            h = 3,
            albedo = {
                grid { -- frame 1
                    E, E, E, E, E, E, E, E, E, E,    --  1-10
                    E, E, E, E, E, E, E, E, E, E,    -- 11-20
                    E, E, E, E, E, E, E, E, E, E,    -- 21-30
                    E, E, E, E, E, E, E, E, E, E,    -- 31-40
                    E, E, E, E, E, E, E,             -- 41-47
                    L'..........g..............g.........g',      -- 48
                    L'.........g.g....g.......g.g.......g.g',     -- 49
                    L'........g.G.g..g.g.....g.G.g.....g.G.g..g', -- 50
                    L'........G.gg.gG.G.g...g.gg.g....g.gg.gG.g', -- 51
                    L'........gggGgggGgg.g..GggGgg....GggGggGg',  -- 52
                    L'........eGgggggggg.gggggGgg..e.gggGgggG',   -- 53
                    L'........egGGgGggggegGgggGg...egGgGgggg',    -- 54
                    L'........eeggGGggeeeggGGge....eggGGgge',     -- 55
                    L'..........eeGGee...eeeGee......eeGee',      -- 56
                    L'............ee......eee.........e',         -- 57
                    E, E, E, E, E, E, E,                 -- 58-64
                },
                grid { -- frame 2
                    E, E, E, E, E, E, E, E, E, E,    --  1-10
                    E, E, E, E, E, E, E, E, E, E,    -- 11-20
                    E, E, E, E, E, E, E, E, E, E,    -- 21-30
                    E, E, E, E, E, E, E, E, E, E,    -- 31-40
                    E, E, E, E, E, E, E, E,          -- 41-48
                    L'............g...........g...........g',     -- 49
                    L'...........g.g.....g...g.g.........g.g..g', -- 50
                    L'..........g.G.g...g.g.g.G.g.......g.G.gg',  -- 51
                    L'..........G.gg.g.G.G.g.gg.g......g.gg.g',   -- 52
                    L'..........gggGg.ggGgg.GggGgg.....GggGgg',   -- 53
                    L'.........egGggggegggGgggggGg...e.gggGgg',   -- 54
                    L'.........eggGgGgegGgggGggg....egGggGg',     -- 55
                    L'..........eegGGeeegGgGgge.....eggGGg',      -- 56
                    L'............eGee...eGGee.......eGee',       -- 57
                    E, E, E, E, E, E, E,                 -- 58-64
                },
            },
        },
    },
}
