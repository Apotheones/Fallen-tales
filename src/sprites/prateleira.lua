-- PRATELEIRA de parede — prop pendurado, 64x64, origem topleft
-- (pendura na parede: não tem pé nem contato de chão).
-- Cozinha do Refúgio (nota vida-refugio-props §7): duas tábuas com
-- mãos-francesas e recipientes DESENCONTRADOS — potes e jarras de
-- tamanhos e rampas diferentes, nunca um conjunto. Relevo: tábua 8-9,
-- recipientes 9-11, mão-francesa 7.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'prateleira',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 7 },
        -- tábuas e mãos-francesas
        T = { ramp = 'wood', step = 5, h = 9 },
        t = { ramp = 'wood', step = 4, h = 8 },
        m = { ramp = 'wood', step = 2, h = 7 },
        -- recipientes desencontrados: reboco, barro, osso, pano
        p = { ramp = 'plaster', step = 4, h = 10 },
        P = { ramp = 'plaster', step = 5, h = 10 },
        o = { ramp = 'plaster', step = 2, h = 9 },
        e = { ramp = 'earth', step = 4, h = 10 },
        n = { ramp = 'earth', step = 2, h = 9 },
        b = { ramp = 'bone', step = 4, h = 10 },
        B = { ramp = 'bone', step = 5, h = 10 },
        c = { ramp = 'clothWarm', step = 3, h = 10 },
        C = { ramp = 'clothWarm', step = 4, h = 10 },
    },

    layers = {
        {   -- TÁBUAS: duas prateleiras com mãos-francesas por baixo
            name = 'tabuas',
            h = 8,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,             --  1-10
                E, E, E, E, E, E, E, E,                   -- 11-18
                -- prateleira de cima
                L'........TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT', -- 19
                L'........tttttttttttttttttttttttttttttttttttttttttttt', -- 20
                L'........tttttttttttttttttttttttttttttttttttttttttttt', -- 21
                -- mãos-francesas
                L'...........mm.................................mm',   -- 22
                L'...........mmm...............................mmm',   -- 23
                L'............mmm.............................mmm',    -- 24
                L'............mm...............................mm',    -- 25
                L'.............m.................................m',   -- 26
                E, E, E, E, E, E, E, E, E, E,             -- 27-36
                E, E, E, E, E, E, E, E,                   -- 37-44
                -- prateleira de baixo
                L'........TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT', -- 45
                L'........tttttttttttttttttttttttttttttttttttttttttttt', -- 46
                L'........tttttttttttttttttttttttttttttttttttttttttttt', -- 47
                L'...........mm.................................mm',   -- 48
                L'...........mmm...............................mmm',   -- 49
                L'............mmm.............................mmm',    -- 50
                L'............mm...............................mm',    -- 51
                L'.............m.................................m',   -- 52
                E, E, E, E, E, E, E, E, E, E,             -- 53-62
                E, E,                                          -- 63-64
            },
        },
        {   -- RECIPIENTES: em cima de cada tábua, nunca um conjunto
            name = 'recipientes',
            h = 10,
            albedo = grid {
                E, E,                                         -- 1-2
                -- jarro alto de barro na prateleira de cima
                L'..........................eee',                 -- 3
                L'..........................ene',                 -- 4
                L'.........................eeeee',                -- 5
                L'.........................eeeee',                -- 6
                L'........................eeeeeee',               -- 7
                L'........................eeeneee',               -- 8
                L'........................eeeeeee',               -- 9
                -- pote de reboco baixo + boquinha
                L'..........ppp...........eeeneee',               -- 10
                L'.........ppppp..........eeeeee....cc',          -- 11
                L'.........poppp..........eeeee....cCCCc',        -- 12
                L'........ppppppp..........eee.....cCcc',         -- 13
                L'........pPpppPp..................cCCCc',        -- 14
                L'........ppppppp.....bbbb..........ccc',         -- 15
                L'........pppppp.....bBbbBb....bb.....c',         -- 16
                L'.........ppppp.....bbbbbb....bBBb',             -- 17
                L'.........ppppp......bbbb....bbbbb',             -- 18
                E, E, E,                                          -- 19-21 (tábua)
                E, E, E, E, E,                                    -- 22-26
                E, E, E, E, E, E, E, E, E, E,             -- 27-36
                -- prateleira de baixo: pilha de tijelas, pote alto
                -- de reboco, lata de pano, jarra tombada
                L'...........eee..........ppppp',                 -- 37
                L'..........eeeee...bbb...ppppPpp....cccc',       -- 38
                L'..........eneee..bbBbb.ppPpppPp...cCccCc',      -- 39
                L'..........eeeee..bbbbb.ppPpppPp..cCccccC',      -- 40
                L'...........eee...bbb..ppPpppPp...cCcCcc',       -- 41
                L'............b........ppPpppp....cCcCcc',        -- 42
                L'...........bbb........pppppp....cCccC',         -- 43
                L'..........bBbBb......pppppp.....cccc',          -- 44
                E, E, E,                                          -- 45-47 (tábua)
                E, E, E, E, E,                                    -- 48-52
                E, E, E, E, E, E, E, E, E, E,             -- 53-62
                E, E,                                          -- 63-64
            },
        },
    },
}
