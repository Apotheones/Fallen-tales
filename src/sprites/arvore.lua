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
--
-- LOOP AMBIENTAL (frente micro-animações): f1..f3 = copa no vento.
-- f1 = base; f2/f3 deslocam cada massa de folha 1-2 px em fases
-- diferentes (ONDA) e os pingentes pendulam — tronco, raízes e chão são
-- estáticos (a camada 'copa' é a única com frames).

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

-- Deslocamento {dx,dy} por massa nas fases 2-3 do loop de vento (fase 1
-- = repouso). Cada lobo recebe uma fase própria — a copa respira por
-- partes em vez de deslizar como um bloco. Deltas f3->f1 <= 1-2 px.
local ONDA = {
    [2] = { {1, -1}, {0, -1}, {1, 0}, {1, 1}, {-1, 0}, {0, 1} },
    [3] = { {-1, 0}, {1, 0}, {0, 1}, {-1, 0}, {0, -1}, {-1, 0} },
}
-- Pêndulo extra dos pingentes (somam ao deslocamento da massa-mãe).
local PENDE = { [2] = {1, 1, 1, 1, 1}, [3] = {-1, -1, 0, 0, -1} }

local function copa(fase)
    local g = nova()
    local o = ONDA[fase] or {}
    local p = PENDE[fase] or {}
    local function d(i)
        local v = o[i]
        return v and v[1] or 0, v and v[2] or 0
    end
    -- massas sobrepostas assimétricas: crista alta à esquerda, lobo
    -- direito mais baixo, lobo pendente e massa baixa ligando ao tronco
    local x1, y1 = d(1); massa(g, 22 + x1, 13 + y1, 11, 9)   -- crista
    local x2, y2 = d(2); massa(g, 23 + x2, 26 + y2, 17, 14)  -- principal esq.
    local x3, y3 = d(3); massa(g, 40 + x3, 28 + y3, 13, 12)  -- lobo direito
    local x4, y4 = d(4); massa(g, 51 + x4, 38 + y4, 7, 8)    -- pendente dir.
    local x5, y5 = d(5); massa(g, 12 + x5, 38 + y5, 8, 9)    -- baixo esq.
    local x6, y6 = d(6); massa(g, 30 + x6, 42 + y6, 11, 9)   -- baixa central
    -- pingentes sob a borda inferior: acompanham a massa-mãe + pêndulo
    pingente(g, 10 + x5 + (p[1] or 0), 44 + y5, 7, 4)
    pingente(g, 20 + x6 + (p[2] or 0), 50 + y6, 9, 5)
    pingente(g, 33 + x6 + (p[3] or 0), 50 + y6, 8, 4)
    pingente(g, 46 + x4 + (p[4] or 0), 46 + y4, 7, 3)
    pingente(g, 55 + x4 + (p[5] or 0), 44 + y4, 5, 2)
    -- folha seca: remendos quentes quebrando o verde por baixo —
    -- seguem a massa onde moram (principal/baixa-central/lobo direito)
    remendo(g, 18 + x2, 36 + y2, 4, 3, 'D')
    remendo(g, 30 + x6, 40 + y6, 5, 3, 'd')
    remendo(g, 42 + x3, 44 + y3, 4, 3, 'D')
    remendo(g, 24 + x6, 46 + y6, 3, 2, 'D')
    remendo(g, 50 + x4, 42 + y4, 3, 2, 'D')
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
            -- f1..f3 = loop de vento (ver cabeçalho).
            name = 'copa',
            h = 11,
            albedo = {copa(1), copa(2), copa(3)},
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
