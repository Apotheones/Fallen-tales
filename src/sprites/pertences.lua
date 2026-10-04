-- PERTENCES junto do travesseiro — peça pequena, 64x64, topleft.
-- Casa das camas do Refúgio (nota vida-refugio-props §9): o objeto que
-- diz "alguém mora aqui" sem NPC. 4 frames = desenhos por seed:
--   f1 = boneca de pano         f2 = livro + óculos
--   f3 = ferramenta limpa enrolada em pano   f4 = escova + espelho
-- Relevo: tudo miúdo, 6-8.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

local BONECA = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E,                                 -- 11-16
    -- cabeça de trapos com cabelo costurado
    L'...........................hhhhh',                -- 17
    L'..........................hHHHHHh',               -- 18
    L'..........................hhhhhhh',               -- 19
    L'..........................hsk skh',               -- 20
    L'..........................hsssssh',               -- 21
    L'...........................hsssh',                -- 22
    L'............................sss',                 -- 23
    -- corpo de pano jade com bracinhos abertos
    L'.........................ccc.s.ccc',              -- 24
    L'........................cccccccccc',              -- 25
    L'........................cccCcccccc',              -- 26
    L'.........................ccccccc',                -- 27
    L'.........................ccCccc',                 -- 28
    L'.........................ccccccc',                -- 29
    -- saia e perninhas
    L'........................ccccccccc',               -- 30
    L'........................ccCcccCcc',               -- 31
    L'.........................ss...ss',                -- 32
    L'.........................ss...ss',                -- 33
    E, E, E, E, E, E, E, E, E, E,                     -- 34-43
    E, E, E, E, E, E, E, E, E, E,                     -- 44-53
    E, E, E, E, E, E, E, E, E, E,                     -- 54-63
    E,                                                -- 64
}

local LIVRO = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E, E, E, E,                        -- 11-19
    -- óculos pousados em cima do livro
    L'.......................oo.....oo',                -- 20
    L'......................o..o...o..o',               -- 21
    L'......................o..o.o.o..o',               -- 22
    L'.......................oo.....oo',                -- 23
    E,                                                -- 24
    -- livro fechado de capa de pano quente, lombada gasta
    L'..................ddttttttttttttttt',             -- 25
    L'.................dbbtttttttttttttttt',            -- 26
    L'.................bbbtttttttttttttttd',            -- 27
    L'.................bbbtttttttttttttttt',            -- 28
    L'.................bbbtttttttttttttttd',            -- 29
    L'.................dbbtttttttttttttttt',            -- 30
    L'..................ddttttttttttttttt',             -- 31
    -- borda das páginas
    L'....................ddddddddddddddd',             -- 32
    L'.....................ddddddddddddd',              -- 33
    E, E, E, E, E, E, E, E, E, E,                     -- 34-43
    E, E, E, E, E, E, E, E, E, E,                     -- 44-53
    E, E, E, E, E, E, E, E, E, E,                     -- 54-63
    E,                                                -- 64
}

local FERRAMENTA = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E,                                 -- 11-16
    -- ponta da ferramenta limpa saindo do rolo
    L'...................................ii',           -- 17
    L'..................................iIIi',          -- 18
    L'.................................iIIi',           -- 19
    -- rolo de pano amarrado em diagonal
    L'................................ccCCC',           -- 20
    L'..............................ccCCCcc',           -- 21
    L'............................ccCCCcccc',           -- 22
    L'..........................ccCCCccccc',            -- 23
    L'.........................cCCCcccccc',             -- 24
    L'.......................ccCCCcccccc',              -- 25
    L'......................cCCCccccccc',               -- 26
    L'....................ccCCCcccccc',                 -- 27
    L'..................rrrCCCcccccc',                  -- 28 (corda)
    L'.................rrrCccccccc',                    -- 29
    L'...................rccccccccc',                   -- 30
    L'..................ccccccccc',                     -- 31
    L'.................ccccccc',                        -- 32
    E, E, E, E, E, E, E, E, E, E,                     -- 33-42
    E, E, E, E, E, E, E, E, E, E,                     -- 43-52
    E, E, E, E, E, E, E, E, E, E,                     -- 53-62
    E, E,                                             -- 63-64
}

local ESCOVA = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E, E,                                 -- 11-16
    -- espelho de mão: aro de ouro velho, face d'água
    L'..................GGGGGGG',                       -- 17
    L'.................GGmmmmmmmGG',                    -- 18
    L'.................GmmmmMmmmmmG',                   -- 19
    L'.................GmmmMmmmmmmG',                   -- 20
    L'.................GmmmmmmMmmmG',                   -- 21
    L'.................GmmmmmmmmmMG',                   -- 22
    L'.................GGmmmmmmmGG',                    -- 23
    L'..................GGGGGGGGG',                     -- 24
    L'....................GGGGG',                       -- 25
    L'.....................ggg',                        -- 26
    L'.....................ggg',                        -- 27
    -- escova ao lado: cerdas de osso, cabo de madeira
    L'.....................gg....bbbbb',                -- 28
    L'....................gg....BBBBBBB',               -- 29
    L'.........................bbbbbbbbb',              -- 30
    L'........................wwwwwwwwwwwww',           -- 31
    L'........................wwwwwwwwwwww',            -- 32
    E, E, E, E, E, E, E, E, E, E,                     -- 33-42
    E, E, E, E, E, E, E, E, E, E,                     -- 43-52
    E, E, E, E, E, E, E, E, E, E,                     -- 53-62
    E, E,                                             -- 63-64
}

return {
    name = 'pertences',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 6 },
        -- boneca: cabelo, pele de pano, vestido jade
        h = { ramp = 'hair', step = 4, h = 7 },
        H = { ramp = 'hair', step = 5, h = 7 },
        s = { ramp = 'skin', step = 3, h = 7 },
        c = { ramp = 'cloth', step = 3, h = 7 },
        C = { ramp = 'cloth', step = 4, h = 7 },
        -- livro: capa de pano quente, lombada/páginas de osso
        t = { ramp = 'clothWarm', step = 3, h = 7 },
        b = { ramp = 'bone', step = 4, h = 7 },
        d = { ramp = 'bone', step = 3, h = 6 },
        -- óculos de ferro fino
        o = { ramp = 'iron', step = 5, h = 8 },
        -- ferramenta limpa enrolada em pano quente
        i = { ramp = 'iron', step = 4, h = 8 },
        I = { ramp = 'iron', step = 6, h = 8 },
        r = { ramp = 'clothWarm', step = 2, h = 7 },
        -- espelho: aro de ouro velho, face d'água, cabo
        G = { ramp = 'gold', step = 4, h = 8 },
        g = { ramp = 'gold', step = 3, h = 7 },
        m = { ramp = 'sea', step = 4, h = 6 },
        M = { ramp = 'sea', step = 6, h = 6 },
        -- escova
        w = { ramp = 'wood', step = 4, h = 7 },
        B = { ramp = 'bone', step = 5, h = 7 },
    },

    layers = {
        {
            name = 'pertence',
            h = 7,
            albedo = { BONECA, LIVRO, FERRAMENTA, ESCOVA },
        },
    },
}
