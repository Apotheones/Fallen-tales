-- ESPANTALHO da horta — prop de chão, 64x96, origem nos pés.
-- Refúgio, horta de várias mãos (vida-refugio-props §4): poste e
-- braço-terno de madeira, roupa velha remendada (clothWarm com
-- retalho de outro tecido — remendo reconhecível), cabeça de saco
-- com rosto de ponto e chapéu de palha torto. Simpático, não
-- macabro: quem olha sorri de volta.
-- Relevo: poste/roupa 6-8, cabeça 9-10, chapéu 11, chão 1-2.

local W, H = 64, 96

local function nova(fill)
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = fill end
        g[y] = r
    end
    return g
end

local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end

local function faixa(g, x0, x1, y, ch)
    for x = x0, x1 do set(g, x, y, ch) end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- camada 1: poste + braço-terno
local function poste()
    local g = nova('.')
    -- braço-terno: barra atravessando, fio claro em cima
    faixa(g, 13, 52, 38, 'W')
    faixa(g, 13, 52, 39, 'w')
    faixa(g, 13, 52, 40, 'w')
    set(g, 13, 39, 'u'); set(g, 14, 40, 'u')
    set(g, 51, 39, 'u'); set(g, 50, 40, 'u')
    -- ponta da barra à vista além das mangas
    set(g, 13, 38, 'u'); set(g, 52, 38, 'u')
    -- poste: desce até a cova, borda direita em sombra
    for y = 36, 90 do
        local x0 = 30 + (y > 60 and 1 or 0)
        set(g, x0, y, 'w'); set(g, x0 + 1, y, 'w'); set(g, x0 + 2, y, 'v')
        if y % 9 == 4 then set(g, x0 + 1, y, 'v') end -- veio da casca
    end
    -- alargamento na base
    faixa(g, 29, 35, 88, 'u'); faixa(g, 28, 36, 89, 'u')
    faixa(g, 28, 37, 90, 'u')
    return str(g)
end

-- camada 2: roupa velha — tronco em trapézio e mangas que pendem
local function roupa()
    local g = nova('.')
    -- mangas: tubos caídos das pontas do terno, afinando ao punho
    local mangas = {
        { 16, 25, 40, 46 }, -- x0, x1, y0, y1 (esq)
        { 42, 50, 40, 44 },
    }
    for _, m in ipairs(mangas) do
        for y = m[3], m[4] do faixa(g, m[1], m[2], y, 't') end
    end
    -- afinamento das mangas até o punho
    faixa(g, 17, 24, 47, 't'); faixa(g, 17, 23, 48, 't')
    faixa(g, 18, 23, 49, 't'); faixa(g, 18, 22, 50, 't')
    faixa(g, 18, 21, 51, 't'); faixa(g, 19, 21, 52, 't')
    faixa(g, 19, 20, 53, 't')
    faixa(g, 43, 49, 45, 't'); faixa(g, 43, 48, 46, 't')
    faixa(g, 44, 48, 47, 't'); faixa(g, 44, 47, 48, 't')
    faixa(g, 45, 47, 49, 't'); faixa(g, 45, 46, 50, 't')
    -- tronco: trapézio largando do terno à barra
    for y = 40, 62 do
        local folga = math.floor((y - 40) / 9)
        local x0, x1 = 26 - folga, 40 + folga
        for x = x0, x1 do
            local ch = 't'
            if x == x1 then ch = 'q' end            -- lado de sombra
            if h2(x, y, 2) < 6 then ch = 'T' end     -- trama gasta
            set(g, x, y, ch)
        end
    end
    -- remendos: cada um de um pano — trabalho reconhecível
    for y = 47, 49 do faixa(g, 29, 32, y, 'p') end      -- remendo escuro
    set(g, 30, 46, 'p'); set(g, 31, 46, 'p')
    for y = 54, 57 do faixa(g, 34, 37, y, 'c') end      -- retalho jade
    set(g, 35, 53, 'c'); set(g, 36, 53, 'c')
    set(g, 33, 55, 'p')                                -- ponto de prega
    for y = 58, 60 do faixa(g, 27, 29, y, 'p') end
    -- barra da roupa: bainha irregular, puída
    for x = 25, 43 do
        local fim = 62 + h2(x, 1, 4) % 3
        for y = 62, math.min(62 + (x % 3), fim) do set(g, x, y, 't') end
    end
    faixa(g, 26, 30, 63, 'q'); faixa(g, 36, 41, 63, 'q')
    set(g, 27, 64, 'q'); set(g, 39, 64, 't')
    -- nó no peito (o cachecol de quem vestiu)
    set(g, 31, 42, 'p'); set(g, 32, 42, 'p'); set(g, 31, 43, 'p')
    return str(g)
end

-- camada 3: cabeça de saco, chapéu torto e palha saindo
local function cabeca()
    local g = nova('.')
    -- saco: levemente tombado p/ a direita
    local saco = {
        '.....bbbb....',
        '...bBBbbbb...',
        '..bBBbbbbbb..',
        '..bBbbbbbbb..',
        '..bbkbbbkbb..',
        '..bbbbbbbbb..',
        '..bbbkkbkbb..',
        '..bbbbkkbb...',
        '..bbbbbbbb...',
        '...bbbbbb....',
        '...rrrrrr....',
        '..f.rrrr.f...',
    }
    for j, linha in ipairs(saco) do
        for i = 1, #linha do
            local c = linha:sub(i, i)
            if c ~= '.' then set(g, 26 + i - 1, 23 + j - 1, c) end
        end
    end
    -- chapéu de palha: coroa alta, aba larga tombada p/ a direita
    local chapeu = {
        '.....HHH.......',
        '....HHHHH......',
        '....HHHHHH.....',
        '...HHHHHHH.....',
        '...HHHHHHH.....',
        '...DDDDDDD.....',
        '..HDDDDDDDH....',
        '.SSSSSSSSSSSS..',
        'SSSSSSSSSSSSSSS',
        '..SSSSSSSSSSSSS',
    }
    for j, linha in ipairs(chapeu) do
        for i = 1, #linha do
            local c = linha:sub(i, i)
            if c ~= '.' then set(g, 24 + i - 1, 12 + j - 1, c) end
        end
    end
    -- palha saindo: punhos, pescoço, aba do chapéu, bolso
    set(g, 19, 54, 'f'); set(g, 20, 54, 'f'); set(g, 21, 55, 'f')
    set(g, 45, 51, 'f'); set(g, 46, 51, 'f'); set(g, 44, 52, 'f')
    set(g, 26, 36, 'f'); set(g, 39, 36, 'f')
    set(g, 23, 22, 'f'); set(g, 24, 23, 'f')
    set(g, 36, 58, 'f')
    return str(g)
end

-- camada 4: cova e mato na base
local function chao()
    local g = nova('.')
    for y = 86, 96 do
        for x = 24, 44 do
            local dx = x - 33
            if math.abs(dx) < (y - 84) * 1.5 then
                local n = h2(x, y, 6)
                set(g, x, y, n < 20 and 'd' or 'e')
            end
        end
    end
    faixa(g, 27, 38, 91, 'e'); faixa(g, 29, 37, 92, 'e')
    -- tufos de capim tomando a cova
    set(g, 25, 88, 'g'); set(g, 24, 89, 'G'); set(g, 26, 89, 'g')
    set(g, 40, 89, 'g'); set(g, 41, 90, 'G')
    set(g, 30, 93, 'G'); set(g, 36, 92, 'g')
    set(g, 22, 92, 'G'); set(g, 44, 91, 'e')
    return str(g)
end

return {
    name = 'espantalho',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = {spec = 'ink', h = 9},              -- rosto de ponto
        b = {ramp = 'bone', step = 4, h = 9},   -- saco da cabeça
        B = {ramp = 'bone', step = 6, h = 10},  -- luz no saco
        r = {ramp = 'bone', step = 3, h = 10},  -- corda do pescoço
        f = {ramp = 'gold', step = 6, h = 8},   -- palha clara
        H = {ramp = 'gold', step = 4, h = 11},  -- coroa do chapéu
        S = {ramp = 'gold', step = 6, h = 11},  -- aba iluminada
        D = {ramp = 'gold', step = 2, h = 11},  -- banda do chapéu
        t = {ramp = 'clothWarm', step = 3, h = 7}, -- roupa velha
        T = {ramp = 'clothWarm', step = 4, h = 7}, -- trama gasta
        q = {ramp = 'clothWarm', step = 2, h = 6}, -- lado de sombra
        p = {ramp = 'clothWarm', step = 1, h = 7}, -- remendo escuro
        c = {ramp = 'cloth', step = 3, h = 7},  -- retalho jade
        w = {ramp = 'wood', step = 4, h = 7},   -- poste/terno
        W = {ramp = 'wood', step = 6, h = 8},   -- fio claro
        v = {ramp = 'wood', step = 2, h = 7},   -- sombra do poste
        u = {ramp = 'wood', step = 3, h = 7},
        e = {ramp = 'earth', step = 3, h = 1},  -- cova
        d = {ramp = 'earth', step = 2, h = 1},  -- terra revirada
        g = {ramp = 'moss', step = 3, h = 2},
        G = {ramp = 'moss', step = 2, h = 2},
    },

    layers = {
        { name = 'poste',  h = 7, albedo = poste() },
        { name = 'roupa',  h = 7, albedo = roupa() },
        { name = 'cabeca', h = 9, albedo = cabeca() },
        { name = 'chao',   h = 1, albedo = chao() },
    },
}
