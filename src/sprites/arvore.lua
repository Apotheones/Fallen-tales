-- ÁRVORE do Refúgio — prop de chão, 64x128, origem nos pés.
-- Árvore velha de povoado: tronco grosso com relevo de casca e galho
-- morto, raízes à mostra, copa em massas de musgo com remendos de folha
-- seca — luminosa em cima, sombreada e mais fria por baixo (a borda
-- inferior prepara a leitura da sombra projetada).
-- Relevo: a copa é o maior volume do kit — topo h 14-15, massa média
-- 11-13, borda inferior 8-9; tronco 8-10, raízes 4-6, chão 1-2.
-- v2: a copa era um domo único pendendo à direita (lia "cogumelo") e o
-- tronco de 4-5 px não sustentava o porte — agora a copa são massas
-- sobrepostas assimétricas com borda recortada e pingentes, e o tronco
-- engrossa de 7 para 13 px com raízes abrindo mais largo.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

local W, H = 64, 128

local function nova()
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = '.' end
        g[y] = r
    end
    return g
end

local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

-- Ruído determinístico barato para recortar bordas (estável por seed).
local function hash(x, y) return (x * 31 + y * 17) % 11 end

-- Massa de copa: elipse com luz própria — o topo esquerdo acende, a
-- banda inferior afunda, e o anel externo é recortado pelo hash para a
-- silhueta não ler como balão.
local function massa(g, cx, cy, rx, ry)
    for y = math.floor(cy - ry), math.ceil(cy + ry) do
        for x = math.floor(cx - rx), math.ceil(cx + rx) do
            local dx, dy = (x - cx) / rx, (y - cy) / ry
            local d = dx * dx + dy * dy
            if d <= 1 then
                local ch
                local borda = d > 0.78
                if borda and hash(x, y) < 3 then
                    ch = nil -- recorte da silhueta
                elseif dy < -0.45 then
                    ch = (hash(x, y) < 2) and 'l' or 'c'
                elseif dy < 0 then
                    ch = (hash(x, y) < 3) and 'c' or 'C'
                elseif dy < 0.45 then
                    ch = (hash(x, y) < 2) and 'D' or 'm'
                else
                    ch = 'M'
                end
                if ch and borda and dy >= 0.4 then ch = 'o' end -- lábio escuro
                if ch then set(g, x, y, ch) end
            end
        end
    end
end

-- Pingente: folhagem pendurada sob a copa, afunilando e escurecendo.
local function pingente(g, x0, y0, comp, larg)
    for j = 0, comp - 1 do
        local w = math.max(1, larg - math.floor(j / 3))
        for i = 0, w - 1 do
            local ch = (j > comp - 3) and 'o' or 'M'
            if hash(x0 + i, y0 + j) == 0 then ch = 'k' end
            set(g, x0 + i, y0 + j, ch)
        end
    end
end

-- Remendo de folha seca: elipse ruidosa de tom quente dentro da massa.
local function remendo(g, cx, cy, rx, ry, ch)
    for y = math.floor(cy - ry), math.ceil(cy + ry) do
        for x = math.floor(cx - rx), math.ceil(cx + rx) do
            local dx, dy = (x - cx) / rx, (y - cy) / ry
            if dx * dx + dy * dy <= 1 and hash(x, y) < 7 then
                set(g, x, y, ch)
            end
        end
    end
end

local function copa()
    local g = nova()
    -- massas sobrepostas assimétricas: crista alta à esquerda, lobo
    -- direito mais baixo, lobo pendente e massa baixa ligando ao tronco
    massa(g, 22, 13, 11, 9)   -- crista
    massa(g, 23, 26, 17, 14)  -- massa principal esquerda
    massa(g, 40, 28, 13, 12)  -- lobo direito
    massa(g, 51, 38, 7, 8)    -- lobo pendente direito
    massa(g, 12, 38, 8, 9)    -- lobo baixo esquerdo
    massa(g, 30, 42, 11, 9)   -- massa baixa central (liga ao tronco)
    -- pingentes sob a borda inferior
    pingente(g, 10, 44, 7, 4)
    pingente(g, 20, 50, 9, 5)
    pingente(g, 33, 50, 8, 4)
    pingente(g, 46, 46, 7, 3)
    pingente(g, 55, 44, 5, 2)
    -- folha seca: remendos quentes quebrando o verde por baixo
    remendo(g, 18, 36, 4, 3, 'D')
    remendo(g, 30, 40, 5, 3, 'd')
    remendo(g, 42, 44, 4, 3, 'D')
    remendo(g, 24, 46, 3, 2, 'D')
    remendo(g, 50, 42, 3, 2, 'D')
    return str(g)
end

return {
    name = 'arvore',
    w = 64, h = 128,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 7},
        -- copa: luz no topo, massa média, sombra fria embaixo
        l = {ramp = 'moss', step = 6, h = 15},
        c = {ramp = 'moss', step = 5, h = 14},
        C = {ramp = 'moss', step = 4, h = 13},
        m = {ramp = 'moss', step = 3, h = 11},
        M = {ramp = 'moss', step = 2, h = 9},
        o = {ramp = 'moss', step = 1, h = 8},
        -- folha seca: remendos quentes quebrando o verde
        d = {ramp = 'earth', step = 6, h = 11},
        D = {ramp = 'earth', step = 4, h = 10},
        -- tronco: casca, veios escuros, fio de luz, nó
        w = {ramp = 'wood', step = 4, h = 9},
        v = {ramp = 'wood', step = 2, h = 8},
        W = {ramp = 'wood', step = 6, h = 10},
        -- raízes e chão
        u = {ramp = 'wood', step = 3, h = 5},
        U = {ramp = 'wood', step = 5, h = 6},
        g = {ramp = 'moss', step = 4, h = 3},
        G = {ramp = 'moss', step = 2, h = 2},
        e = {ramp = 'earth', step = 4, h = 1},
        f = {ramp = 'earth', step = 6, h = 2}, -- folha caída
    },

    layers = {
        {   -- TRONCO + RAÍZES: atrás da copa; casca com veios verticais,
            -- nó seco, alargamento de base e raízes saindo do chão.
            -- v2: tronco engrossado (7 -> 13 px no flare) e raízes mais
            -- largas e grossas para sustentar a copa nova.
            name = 'tronco',
            h = 8,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E, E, E, E, E, E, E, E, E, E,            -- 41-50
                E, E, E, E, E,                            -- 51-55
                L'.........................wwvWvww',          -- 56
                L'........................wwvvWvww',          -- 57
                L'........................wwvvWWvw',          -- 58
                L'........................wvvvWvvw',          -- 59
                L'........................wvvvwvvw',          -- 60
                L'........................wvvvWvvw',          -- 61
                L'.......................wwvvvWvvw',          -- 62
                L'.......................wvvvvWvvw',          -- 63
                L'.......................wvvwvvvvw',          -- 64
                L'.......................wvvwvvvvw',          -- 65
                L'.......................wvvwWvvvw',          -- 66
                L'.......................wvvwWvvvw',          -- 67
                L'.......................wvvwwvvvw',          -- 68
                L'.......................wvvwvvvvw',          -- 69
                L'.......................wvvwvvvvw',          -- 70
                L'.......................wvvwvvvvw',          -- 71
                L'.......................wvvwvvvvw',          -- 72
                L'.......................wvvwvvvww',          -- 73
                L'.......................wvvwvvvww',          -- 74
                L'.......................wvvwvvvww',          -- 75
                L'.......................wvvwvvvww',          -- 76
                L'.......................wvvwvvvww',          -- 77
                L'.......................wvvwvvvww',          -- 78
                L'.......................wvvwvvvww',          -- 79
                L'.......................wvvwvvvww',          -- 80
                L'.......................wvvwvvvww',          -- 81
                L'.......................wvvwvvvww',          -- 82
                L'.......................wvvwvvvww',          -- 83
                L'.......................wvvwvvvww',          -- 84
                L'.......................wvvwvvvww',          -- 85
                L'.......................wvvwvvvww',          -- 86
                L'.......................wvvwvvvww',          -- 87
                L'.......................wvkwvvvww',          -- 88
                L'.......................wvkkwvvww',          -- 89
                L'.......................wvkkvvvww',          -- 90
                L'.......................wvkkwvvww',          -- 91
                L'.......................wvkwvvvww',          -- 92
                L'......................wwvvwvvvwww',         -- 93
                L'......................wvvvwvvvwww',         -- 94
                L'......................wvvvwvvvvww',         -- 95
                L'......................wvvwwvWvvww',         -- 96
                L'......................wvvwvvWvvww',         -- 97
                L'......................wvvwvvvvvww',         -- 98
                L'......................wvvwvvvvvww',         -- 99
                L'......................wvvwvvvvvww',         -- 100
                L'......................wvvwvvvvvvw',         -- 101
                L'......................wvvwvvvvvvw',         -- 102
                L'......................wvvwvvvvvvw',         -- 103
                L'......................wvvwvvvvvvww',        -- 104
                L'.....................wwvvwvvvvvwww',        -- 105
                L'.....................wvvvwvvvvvwww',        -- 106
                L'.....................wvvvwvvvvvvww',        -- 107
                L'.....................wvvwvvvvvvvww',        -- 108
                L'.....................wvvwvvvvvvvww',        -- 109
                L'.....................wvvwvvvvvvvwww',       -- 110
                L'.....................wvvwvvvvvvvwww',       -- 111
                L'.....................wvvwvvvvvvvwww',       -- 112
                L'.....................wvvwvvvvvvvwwww',      -- 113
                L'.....................wvvwvvvvvvvwwww',      -- 114
                -- raízes alargando a base: braços grossos saindo do chão
                L'....................uUvvvvvvvvvvUu',        -- 115
                L'..................uUuvvvvvvvvvvvvUuu',      -- 116
                L'.................uuUuuvvvvvvvvvvvvuUuu',    -- 117
                L'................uuUu.uuvvvvvvvvvvuu.uUuu',  -- 118
                L'...............uuu...uuvvvvvvvvvuu....uuu', -- 119
                L'.............uuu.....uuvvvvvvvuu......uuu', -- 120
                L'............uu.......uuvvvvvuu........uuu', -- 121
                L'...........uu........uuvvvuu..........uuu', -- 122
                L'..........uu..........uvvu............uuu', -- 123
                L'.........uu............uu..............uu', -- 124
                E, E, E, E,                                 -- 125-128
            },
        },
        {   -- COPA: massas de folhagem sobrepostas e assimétricas, geradas
            -- por elipse com luz própria — cada lobo tem seu topo claro e
            -- sua banda inferior escura; silhueta recortada por hash.
            name = 'copa',
            h = 11,
            albedo = copa(),
        },
        {   -- CHÃO: folhas caídas, tufo de capim e terra ao redor das
            -- raízes (camada por cima para o mato cobrir a ponta delas)
            name = 'chao',
            h = 2,
            albedo = grid {
                E, E, E, E, E, E, E, E, E, E,            --  1-10
                E, E, E, E, E, E, E, E, E, E,            -- 11-20
                E, E, E, E, E, E, E, E, E, E,            -- 21-30
                E, E, E, E, E, E, E, E, E, E,            -- 31-40
                E, E, E, E, E, E, E, E, E, E,            -- 41-50
                E, E, E, E, E, E, E, E, E, E,            -- 51-60
                E, E, E, E, E, E, E, E, E, E,            -- 61-70
                E, E, E, E, E, E, E, E, E, E,            -- 71-80
                E, E, E, E, E, E, E, E, E, E,            -- 81-90
                E, E, E, E, E, E, E, E, E, E,            -- 91-100
                E, E, E, E, E, E, E, E, E, E,            -- 101-110
                E, E, E, E, E, E,                        -- 111-116
                L'...........f...............f...........f',-- 117
                L'........g......f.....f........f.....g',-- 118
                L'.......g.g...e....f......e..f....g.g..f',-- 119
                L'......g.G.g..e...f....e......f.g.G.g',-- 120
                L'.....g.gg.g.e....e......f...e..g.gg.g.f',-- 121
                L'....g.ggGgg.e.f.....e..f....e.ggGgg.g',-- 122
                L'...g.gggGggg.e....f....e....e.gggGggg.g',-- 123
                L'...eggggGgggge...e.....e...eggggGgggge',-- 124
                L'..eeggGGgGggee..e..f...e..eeggGGgGggee',-- 125
                L'....eeggGggee...e.....e...eeeggGggee',-- 126
                L'.....eeGGee....e......e....eeGGee',-- 127
                L'.......eee......e.....e......eee',-- 128
            },
        },
    },
}
