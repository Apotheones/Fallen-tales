-- QUADRO de parede — prop pendurado, 64x64, origem topleft (pendura na
-- parede). Capela/cozinha do Refúgio (nota vida-refugio-props §7-8):
-- moldura de madeira simples segurando uma cena pequena — faixas
-- horizontais que sugerem a paisagem do vale: céu de mar lavanda, crista
-- distante, faixa de água, margem de terra. Um sol/lua de ouro velho.
-- Relevo: moldura 8, cena 6 (rebaixada atrás da moldura), sol 6.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'quadro',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 8 },              -- prego/pendurador
        -- moldura
        W = { ramp = 'wood', step = 6, h = 8 },
        w = { ramp = 'wood', step = 4, h = 8 },
        v = { ramp = 'wood', step = 2, h = 8 },
        -- cena do vale em faixas
        u = { ramp = 'sea', step = 6, h = 6 },    -- céu claro
        U = { ramp = 'sea', step = 7, h = 6 },    -- fio de luz no céu
        y = { ramp = 'gold', step = 6, h = 6 },   -- sol/lua de ouro velho
        r = { ramp = 'sea', step = 2, h = 6 },    -- crista distante
        R = { ramp = 'sea', step = 3, h = 6 },    -- luz na crista
        s = { ramp = 'sea', step = 3, h = 6 },    -- água
        S = { ramp = 'sea', step = 4, h = 6 },    -- espelho d'água
        e = { ramp = 'earth', step = 4, h = 6 },  -- margem
        t = { ramp = 'earth', step = 5, h = 6 },  -- caminho na margem
    },

    layers = {
        {
            name = 'quadro',
            h = 8,
            albedo = grid {
                E, E, E, E, E,                              -- 1-5
                L'...............................k',            -- 6 (prego)
                L'..............................www',           -- 7 (arame)
                -- moldura: topo
                L'............WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 8
                L'............Wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',-- 9
                L'............WwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwW',-- 10
                -- céu
                L'............WwuUUUuuuuuuuuuuuuuuuuuuuuuuuuuuuuuvwW',-- 11
                L'............WwuuuuuuuuuuuuuuuuuuuyyyyuuuuuuuuuuvwW',-- 12
                L'............WwuuuuuuuuuuuuuuuuuuyyyyyyuuuuuuuuuvwW',-- 13
                L'............WwuuUUuuuuuuuuuuuuuyyyyyyuuuuuuuuuuvwW',-- 14
                L'............WwuuuuuuuuUUUuuuuuuuyyyyuuuuuuuUUuuvwW',-- 15
                L'............WwuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuvwW',-- 16
                L'............WwuuUUuuuuuuuuuuUUuuuuuuuuuuuuuuuuuvwW',-- 17
                -- crista distante
                L'............WwuuuuuurrrRrruuuuuuuurrrrruuuuuuuuvwW',-- 18
                L'............WwuurrrrrRRRRrrrrruuRRRRRRrrrrruuuuvwW',-- 19
                L'............WwrrRRRRRRRRRRRRRRrrRRRRRRRRRRRRrrrvwW',-- 20
                -- água
                L'............WwsssssssssSSssssssssssssSSssssssssvwW',-- 21
                L'............WwssSSssssssssssSSsssssssssssssSSssvwW',-- 22
                L'............WwssssssssssssssssssssssssssssssssssvwW',-- 23
                L'............WwssssssSSssssssssssSSsssssssssssssvwW',-- 24
                L'............WwssssssssssssssssssssssssSSsssssssvwW',-- 25
                L'............WwssSSssssssssSSsssssssssssssssSSssvwW',-- 26
                -- margem
                L'............WweeeeeeeeteeeeeeeeeeeeeteeeeeeeeeevwW',-- 27
                L'............WweeeeeetttteeeeeeeeeetttteeeeeeeevwW',-- 28
                L'............WweeeetttteeeeeeeeeeetttteeeeeeeeevwW',-- 29
                -- moldura: base em sombra
                L'............WwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwW',-- 30
                L'............Wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',-- 31
                L'............WvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvW',-- 32
                E, E, E, E, E, E, E, E, E, E,             -- 33-42
                E, E, E, E, E, E, E, E, E, E,             -- 43-52
                E, E, E, E, E, E, E, E, E, E,             -- 53-62
                E, E,                                          -- 63-64
            },
        },
    },
}
