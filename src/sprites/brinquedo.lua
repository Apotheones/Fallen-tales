-- BRINQUEDO perdido — peça pequena, 64x64, origem topleft.
-- Casa das camas do Refúgio (nota vida-refugio-props §9): cavalo de pau
-- caído no corredor — cabeça de madeira entalhada com crina de
-- vermelho-casca, rédea de pano e o pau estendido. Deitado, largado no
-- meio do caminho: alguém saiu correndo.
-- Relevo: cabeça 7-8, crina/rédea 8, pau 6, chão 1.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'brinquedo',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 7 },              -- olho/narinas
        w = { ramp = 'wood', step = 4, h = 7 },   -- cabeça/pau
        W = { ramp = 'wood', step = 6, h = 8 },   -- fio de luz no entalhe
        v = { ramp = 'wood', step = 3, h = 6 },
        r = { ramp = 'rust', step = 4, h = 8 },   -- crina vermelho-casca
        R = { ramp = 'rust', step = 3, h = 8 },   -- rédea
        c = { ramp = 'clothWarm', step = 3, h = 7 }, -- ponta da rédea
        e = { ramp = 'earth', step = 3, h = 1 },  -- contato
    },

    layers = {
        {
            name = 'brinquedo',
            h = 6,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,             --  1-10
                E, E, E, E, E, E, E, E, E, E,             -- 11-20
                E, E, E,                                   -- 21-23
                -- cabeça deitada, focinho para a esquerda
                L'.................rrrr',                   -- 24
                L'................rrrrrrr',                 -- 25
                L'..........wwwwwrrrrrrrr',                 -- 26
                L'.........wwWwwwwwwrrrrr',                 -- 27
                L'........wwWWwwwwwwwwrr',                  -- 28
                L'.......wwWkwwwwwwwwwww',                  -- 29 (olho)
                L'......wwwwwwwwwwwwwwww',                  -- 30
                L'......wwwwwwwwwwwwwwww',                  -- 31
                L'.....wkwwwwwwwwwwwwwww',                  -- 32 (narina)
                L'.....wwwwwwwwwwwwwwwww',                  -- 33
                L'......wwwwwwwwwwwwwww',                   -- 34
                L'.......wwwwwwwwwwwww',                    -- 35
                L'........wwwwwwwwwww',                     -- 36
                L'.........wwwwwwwww',                      -- 37
                -- rédea caída sobre o pescoço
                L'.........RRwwwwRR',                       -- 38
                L'..........RwwwwR....cc',                  -- 39
                L'..........wwwww.....cc',                  -- 40
                -- pau estendido para a direita, ponta engrossada
                L'..........wwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 41
                L'...........wwwwwwwwwwwwwwwwwwwwwwwwwwwwww', -- 42
                L'............wwwwwwwwwwwwwwwwwwwwwwwwwww', -- 43
                L'.............wwwwwwwvvvvvvvvvvvvvvvv',    -- 44
                -- sombra de contato sob a cabeça e o pau
                L'..........e..e....e....e....e....e',      -- 45
                L'.........e.....e....e....e....e....e',    -- 46
                E, E, E, E, E, E, E, E, E, E,             -- 47-56
                E, E, E, E, E, E, E, E,                   -- 57-64
            },
        },
    },
}
