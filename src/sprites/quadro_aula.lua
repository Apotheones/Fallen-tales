-- QUADRO_AULA — lousa pequena de parede, 64x64, origem topleft.
-- Escola do Refúgio (nota vida-refugio-props §11): moldura de madeira
-- segurando uma lousa de tinta com traços de osso — exercício de mão
-- pequena: fileiras de marcas, círculos treinados, um zigue e um sol
-- no canto. Bandeja de giz embaixo.
-- Relevo: moldura 8, lousa 6 (rebaixada), traços 6, bandeja 7.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'quadro_aula',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 8 },              -- prego
        -- moldura e bandeja
        W = { ramp = 'wood', step = 6, h = 8 },
        w = { ramp = 'wood', step = 4, h = 8 },
        v = { ramp = 'wood', step = 2, h = 8 },
        T = { ramp = 'wood', step = 5, h = 7 },   -- bandeja de giz
        -- lousa e traços
        o = { spec = 'abyss', h = 6 },            -- superfície de tinta
        x = { ramp = 'bone', step = 5, h = 6 },   -- giz
        X = { ramp = 'bone', step = 6, h = 6 },   -- giz novo na bandeja
        g = { ramp = 'bone', step = 3, h = 6 },   -- apagado fraco
    },

    layers = {
        {
            name = 'lousa',
            h = 7,
            albedo = grid {
                E, E, E, E, E,                              -- 1-5
                L'...............................k',            -- 6 (prego)
                E,                                            -- 7
                -- moldura: topo
                L'........WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 8
                L'........Wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',-- 9
                L'........WwooooooooooooooooooooooooooooooooooooooowW',-- 10
                -- lousa: fileira de marcas treinadas
                L'........Wwooxx.xxxx.xxxxxx.xx.xxxxx.xxxx.xxx.xxoowW',-- 11
                L'........Wwooxx.xxxx.xxxxxx.xx.xxxxx.xxxx.xxx.xxoowW',-- 12
                L'........WwooooooooooooooooooooooooooooooooooooooowW',-- 13
                L'........Wwooxxxx.xxxx.xxxxx.xxx.xxxxx.xxxx.xxxxoowW',-- 14
                L'........WwooooooooooooooooooooooooooooooooooooooowW',-- 15
                -- círculos treinados
                L'........Wwooo.xxx...xxx...xxx...xxx...xxx.ooo.oowW',-- 16
                L'........Wwoo.x...x.x...x.x...x.x...x.x...x.oo.oowW',-- 17
                L'........Wwoo.x...x.x...x.x...x.x...x.x...x.oo.oowW',-- 18
                L'........Wwooo.xxx...xxx...xxx...xxx...xxx.ooo.oowW',-- 19
                L'........WwooooooooooooooooooooooooooooooooooooooowW',-- 20
                -- zigue e rabisco livre
                L'........Wwoox..x..x..x..x..x..x..x..x..x..x..oowW',-- 21
                L'........Wwoo.x..x..x..x..x..x..x..x..x..x..xoowW',-- 22
                L'........WwooxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxoowW',-- 23
                L'........WwoooooooooooooooooooooooooooggooooooowW',-- 24
                L'........WwoooogggooooooooggooooooooogggooooooowW',-- 25
                -- solzinho no canto + linha torta
                L'........Wwoooooooooooooooooooooooooooooxx.oooowW',-- 26
                L'........WwoooooooooooooooooooooooxxxxoxxxoxxoowW',-- 27
                L'........Wwoooooooooooooooooooooox..xoxxxoxxxoowW',-- 28
                L'........WwooooooooooooooooooooooxxxxoxxxoxxoowW',-- 29
                L'........WwooooooooooooooooooooooooooxxoooooooowW',-- 30
                L'........WwoooooooooooooooooooooooooooooooooooooowW',-- 31
                -- moldura: base + bandeja de giz com pedaços
                L'........WwvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvwW',-- 32
                L'........Wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',-- 33
                L'........WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',-- 34
                L'..........TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT',  -- 35
                L'..........TvXXvXvvvvvXvvvvvvXvvvXvvvvvvvvvvXvvvv',  -- 36
                L'..........TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT',  -- 37
                L'............vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv',  -- 38
                E, E, E, E, E, E, E, E, E, E,             -- 39-48
                E, E, E, E, E, E, E, E, E, E,             -- 49-58
                E, E, E, E, E, E,                           -- 59-64
            },
        },
    },
}
