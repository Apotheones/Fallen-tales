-- TOCHA de arena — braseiro de poste baixo, 64x96, origem nos pés.
-- Cena arena-novo: topeira de ferro aberta num mourão de madeira curto
-- (~40px) — mais baixa que o braseiro do refúgio, lê na moldura sem
-- dominar a grade. Cesta aberta com leito de brasa e chama ember alta
-- e viva: ei .8-1 no núcleo, fagulha solta em um frame só.
-- 4 frames = LOOP de chama (f4 emenda em f1): línguas sobem/descem,
-- base estável. Occluder médio.
-- Relevo: chama 12-14, aro/cesta 8-9, poste 5-7, chão 1.

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
    assert(x >= 1 and x <= W, 'coluna fora do sprite: ' .. x)
    assert(y >= 1 and y <= H, 'linha fora do sprite: ' .. y)
    g[y][x] = ch
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- Mapa esparso: { [linha] = { {col_ini, 'chars'}, ... } }
local function pinta_runs(g, map)
    for y, runs in pairs(map) do
        for _, r in ipairs(runs) do
            local s = r[2]
            for i = 1, #s do
                local c = s:sub(i, i)
                if c ~= '.' then set(g, r[1] + i - 1, y, c) end
            end
        end
    end
end

local function grade(map)
    local g = nova('.')
    pinta_runs(g, map)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

-- POSTE + CESTA -------------------------------------------------------
-- Mourão de madeira cols 27-32, cesta de ferro aberta cols 22-43,
-- leito de brasa procedural dentro da cesta, pé alargado e terra.
local function corpo()
    local g = nova('.')

    -- aro da cesta (filete claro por cima, corpo de ferro)
    pinta_runs(g, {
        [44] = { { 22, 'kIIIIIIIIIIIIIIIIIIIIk' } },
        [45] = { { 22, 'kiiiiiiiiiiiiiiiiiiiik' } },
    })
    -- paredes da cesta: bordas de ferro, interior é do leito (abaixo)
    for y = 46, 50 do
        set(g, 22, y, 'k'); set(g, 23, y, 'i')
        set(g, 42, y, 'i'); set(g, 43, y, 'k')
    end
    -- leito de brasa: miolo e/o/c procedural, barras 'i' a cada 5 px
    local faixa = {
        [46] = { 24, 41 }, [47] = { 24, 41 }, [48] = { 24, 41 },
        [49] = { 24, 41 }, [50] = { 24, 41 }, [51] = { 25, 40 },
        [52] = { 25, 40 }, [53] = { 26, 39 }, [54] = { 26, 39 },
        [55] = { 27, 38 }, [56] = { 27, 36 },
    }
    for y, fx in pairs(faixa) do
        for x = fx[1], fx[2] do
            if x == fx[1] then set(g, x, y, 'k')
            elseif (x - 24) % 5 == 2 and y < 55 then
                set(g, x, y, 'i') -- barra da cesta atravessando a brasa
            else
                local n = h2(x * 2, y * 3, 7)
                local ch
                if n < 18 then ch = 'c'       -- lume vivo
                elseif n < 52 then ch = 'o'   -- brasa alta
                elseif n < 88 then ch = 'e'   -- brasa apagando
                else ch = 'i' end             -- crosta de ferro frio
                if y < 48 and ch == 'i' then ch = 'e' end
                set(g, x, y, ch)
            end
        end
        set(g, fx[2] + 1, y, 'i')
        if y <= 53 then set(g, fx[2] + 2, y, 'k') end
    end
    -- fundo da cesta encontra o poste
    pinta_runs(g, {
        [56] = { { 27, 'kiiieeoiik' } },
        [57] = { { 28, 'kiiiiiik' } },
    })

    -- mourão de madeira: 'k' contorno, 'W' fio claro, 'w' corpo, 'v' sombra
    for y = 58, 88 do
        local linha = (y % 4 < 2) and 'kWwwvk' or 'kwwvvk'
        for i = 1, #linha do
            set(g, 27 + i - 1, y, linha:sub(i, i))
        end
        -- veios da madeira: fleck claro ou nó escuro
        local n = h2(y * 5, 3, 11)
        if n < 8 then set(g, 30, y, 'W')
        elseif n > 92 then set(g, 29, y, 'v') end
    end
    -- cintas de ferro: alta (segura a cesta) e baixa
    pinta_runs(g, {
        [61] = { { 25, 'kIIIIIIIIk' } },
        [62] = { { 25, 'kiiiiiiiik' } },
        [79] = { { 26, 'kIIIIIIk' } },
        [80] = { { 26, 'kiiiriik' } }, -- ferrugem na cinta baixa
    })
    -- pé alargado entrando na terra
    pinta_runs(g, {
        [89] = { { 26, 'kwwwwvvk' } },
        [90] = { { 25, 'kwwwwwwvvk' } },
        [91] = { { 25, 'kwvvvvvvvk' } },
        [92] = { { 26, 'kvvvvvvk' } },
        [93] = { { 27, 'kvvvvk' } },
        -- contato com o chão: terra e pedrisco
        [94] = { { 22, 'g' }, { 28, 'gd' }, { 36, 'g' }, { 41, 'dg' } },
        [95] = { { 24, 'd' }, { 33, 'g' }, { 39, 'g' } },
    })
    return g
end

-- Brilho do leito: mesmas marcas e/o/c do albedo, reemite por baixo da
-- chama (o canal emissivo é independente — brilha mesmo onde a língua cobre).
local BED = {
    [46] = { 24, 41 }, [47] = { 24, 41 }, [48] = { 24, 41 },
    [49] = { 24, 41 }, [50] = { 24, 41 }, [51] = { 25, 40 },
    [52] = { 25, 40 }, [53] = { 26, 39 }, [54] = { 26, 39 },
    [55] = { 27, 38 }, [56] = { 27, 36 },
}

local function brasa_emi()
    local g = nova('.')
    for y, fx in pairs(BED) do
        for x = fx[1], fx[2] do
            if (x - 24) % 5 == 2 and y < 55 then
                -- barra de ferro sobre a brasa: pontos quentes 'o' raros
                if h2(x, y, 13) < 25 then set(g, x, y, 'o') end
            else
                local n = h2(x * 2, y * 3, 7)
                if n < 18 then set(g, x, y, 'c')
                elseif n < 52 then set(g, x, y, 'o')
                elseif n < 88 then set(g, x, y, 'e') end
            end
        end
    end
    return g
end

-- CHAMA ---------------------------------------------------------------
-- Base compartilhada (linhas 38-46): nasce dentro do aro da cesta e
-- não muda entre frames — o flicker mora nas línguas de cima.
local BASE = {
    [38] = { { 27, 'ffOOOOFF' } },
    [39] = { { 26, 'ffOOOOOOff' } },
    [40] = { { 25, 'fFOOOOOOFf' } },
    [41] = { { 25, 'ffOOOOOOff' } },
    [42] = { { 26, 'fOOOOOOF' } },
    [43] = { { 26, 'fOOOOOOF' } },
    [44] = { { 27, 'fOOOOOf' } },
    [45] = { { 27, 'fOOOOOf' } },
    [46] = { { 28, 'fOOOf' } },
}

-- f1: língua-mãe alta ao centro, pendendo levemente à direita
local F1 = {
    [10] = { { 33, 'F' } },
    [11] = { { 32, 'fOF' } },
    [12] = { { 31, 'ffOFf' } },
    [13] = { { 30, 'ffFOFf' } },
    [14] = { { 29, 'ffFOOFf' } },
    [15] = { { 28, 'ffFOOOf' }, { 36, 'f' } },
    [16] = { { 27, 'ffFOOFff' } },
    [17] = { { 26, 'ffFOOOFF' } },
    [18] = { { 26, 'fFFOOOOFf' } },
    [19] = { { 25, 'ffFOOOOOff' } },
    [20] = { { 25, 'ffFOOOOOOF' }, { 37, 'f' } },
    [21] = { { 24, 'ffFOOOOOOFF' } },
    [22] = { { 24, 'ffFOOOOOOFf' } },
    [23] = { { 25, 'fFOOOOOOOOF' } },
    [24] = { { 24, 'ffOOOOOOOOOf' } },
    [25] = { { 25, 'fFOOOOOOOOf' } },
    [26] = { { 24, 'ffOOOOOOOOOf' } },
    [27] = { { 25, 'fFOOOOOOOF' } },
    [28] = { { 24, 'ffOOOOOOOOf' } },
    [29] = { { 25, 'ffOOOOOOf' } },
    [30] = { { 25, 'fFOOOOOOF' } },
    [31] = { { 26, 'ffOOOOOOf' } },
    [32] = { { 26, 'fFOOOOOF' } },
    [33] = { { 27, 'ffOOOOOf' } },
    [34] = { { 27, 'fFOOOOF' } },
    [35] = { { 28, 'ffOOOOf' } },
    [36] = { { 28, 'fFOOOF' } },
    [37] = { { 29, 'ffOOf' } },
}

-- f2: a língua-mãe quebra para a esquerda e sobe uma língua lateral
local F2 = {
    [13] = { { 30, 'f' } },
    [14] = { { 29, 'fOf' }, { 34, 'f' } },
    [15] = { { 28, 'fFOF' }, { 33, 'Ff' } },
    [16] = { { 27, 'ffFOFf' }, { 32, 'fOf' } },
    [17] = { { 26, 'ffFOOFf' }, { 33, 'f' } },
    [18] = { { 26, 'fFOOOFF' } },
    [19] = { { 25, 'ffOOOOFFf' } },
    [20] = { { 25, 'fFOOOOOOff' } },
    [21] = { { 24, 'ffOOOOOOOF' }, { 36, 'f' } },
    [22] = { { 24, 'fOOOOOOOOFF' } },
    [23] = { { 25, 'fOOOOOOOOOf' } },
    [24] = { { 24, 'ffOOOOOOOOOf' } },
    [25] = { { 25, 'fOOOOOOOOOf' } },
    [26] = { { 24, 'ffOOOOOOOOOf' } },
    [27] = { { 25, 'fOOOOOOOOF' } },
    [28] = { { 25, 'ffOOOOOOOf' } },
    [29] = { { 26, 'fOOOOOOf' } },
    [30] = { { 25, 'ffOOOOOf' } },
    [31] = { { 26, 'fOOOOOF' } },
    [32] = { { 26, 'ffOOOOOf' } },
    [33] = { { 27, 'fOOOOOf' } },
    [34] = { { 27, 'ffOOOOf' } },
    [35] = { { 28, 'fOOOOf' } },
    [36] = { { 28, 'ffOOOf' } },
    [37] = { { 29, 'fOOf' } },
}

-- f3: chama esguia e a FAGULHA solta à direita (único frame com ela)
local F3 = {
    [12] = { { 32, 'f' } },
    [13] = { { 31, 'fFf' }, { 40, 'F' } }, -- fagulha
    [14] = { { 30, 'ffOFf' }, { 41, 'f' } },
    [15] = { { 29, 'ffFOFf' } },
    [16] = { { 28, 'ffFOOFf' } },
    [17] = { { 27, 'ffFOOOFf' } },
    [18] = { { 26, 'ffFOOOFF' } },
    [19] = { { 26, 'fFOOOOOOf' } },
    [20] = { { 25, 'ffOOOOOOff' } },
    [21] = { { 24, 'ffOOOOOOOFf' } },
    [22] = { { 24, 'fOOOOOOOOFF' } },
    [23] = { { 25, 'fOOOOOOOOOf' } },
    [24] = { { 24, 'ffOOOOOOOOOf' } },
    [25] = { { 24, 'ffOOOOOOOOOf' } },
    [26] = { { 25, 'fOOOOOOOOOf' } },
    [27] = { { 25, 'ffOOOOOOOf' } },
    [28] = { { 26, 'fOOOOOOOf' } },
    [29] = { { 25, 'ffOOOOOOf' } },
    [30] = { { 26, 'fOOOOOOf' } },
    [31] = { { 26, 'ffOOOOOf' } },
    [32] = { { 27, 'fOOOOOf' } },
    [33] = { { 27, 'ffOOOOf' } },
    [34] = { { 28, 'fOOOF' } },
    [35] = { { 28, 'ffOOf' } },
    [36] = { { 29, 'fOOf' } },
    [37] = { { 29, 'ff' } },
}

-- f4: recolhe simétrica e baixa — emenda de volta no f1 sem salto
local F4 = {
    [11] = { { 33, 'f' } },
    [12] = { { 32, 'fOF' } },
    [13] = { { 31, 'ffOFf' } },
    [14] = { { 30, 'ffFOFf' } },
    [15] = { { 29, 'ffFOOFf' } },
    [16] = { { 28, 'ffFOOOFf' } },
    [17] = { { 27, 'ffFOOOFFf' } },
    [18] = { { 26, 'ffFOOOOOOf' } },
    [19] = { { 26, 'fFOOOOOFFf' } },
    [20] = { { 25, 'ffOOOOOOOff' } },
    [21] = { { 25, 'fOOOOOOOOFF' } },
    [22] = { { 24, 'ffOOOOOOOOFFf' } },
    [23] = { { 25, 'fOOOOOOOOOff' } },
    [24] = { { 24, 'ffOOOOOOOOOf' } },
    [25] = { { 25, 'fOOOOOOOOOf' } },
    [26] = { { 24, 'ffOOOOOOOOf' } },
    [27] = { { 25, 'ffOOOOOOFF' } },
    [28] = { { 25, 'fOOOOOOOf' } },
    [29] = { { 26, 'fOOOOOOf' } },
    [30] = { { 26, 'ffOOOOOf' } },
    [31] = { { 27, 'fOOOOOF' } },
    [32] = { { 27, 'ffOOOOf' } },
    [33] = { { 28, 'fOOOOf' } },
    [34] = { { 28, 'ffOOOf' } },
    [35] = { { 29, 'fOOF' } },
    [36] = { { 29, 'fOOf' } },
    [37] = { { 29, 'ff' } },
}

local FRAMES = { F1, F2, F3, F4 }

local function chama_albedo(map)
    local g = nova('.')
    pinta_runs(g, BASE)
    pinta_runs(g, map)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local function chama_emi(map, bed)
    pinta_runs(bed, BASE)
    pinta_runs(bed, map)
    local t = {}
    for y = 1, H do t[y] = table.concat(bed[y]) end
    return table.concat(t, '\n')
end

local albedo, emissive = {}, {}
for i = 1, 4 do
    albedo[i] = chama_albedo(FRAMES[i])
    emissive[i] = chama_emi(FRAMES[i], brasa_emi())
end

local g = corpo()
local t = {}
for y = 1, H do t[y] = table.concat(g[y]) end
local CORPO = table.concat(t, '\n')

return {
    name = 'tocha',
    w = 64, h = 96,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 6 },
        -- mourão de madeira
        w = { ramp = 'wood', step = 4, h = 6 },
        W = { ramp = 'wood', step = 6, h = 7 },
        v = { ramp = 'wood', step = 2, h = 5 },
        -- ferro da cesta e das cintas
        i = { ramp = 'iron', step = 3, h = 8 },
        I = { ramp = 'iron', step = 5, h = 9 },
        r = { ramp = 'rust', step = 3, h = 7 },
        -- leito de brasa: ei alto, é o coração da tocha
        e = { ramp = 'ember', step = 2, h = 8, e = 'ember.3', ei = 0.8 },
        o = { ramp = 'ember', step = 4, h = 8, e = 'ember.5', ei = 0.9 },
        c = { ramp = 'ember', step = 5, h = 9, e = 'ember.6', ei = 1 },
        -- chama: f = borda, F = corpo, O = núcleo quente
        f = { ramp = 'ember', step = 3, h = 12, e = 'ember.4', ei = 0.85 },
        F = { ramp = 'ember', step = 5, h = 13, e = 'ember.6', ei = 0.95 },
        O = { ramp = 'ember', step = 7, h = 14, e = 'ember.7', ei = 1 },
        -- contato com o chão
        g = { ramp = 'earth', step = 3, h = 1 },
        d = { ramp = 'earth', step = 2, h = 1 },
    },

    layers = {
        { name = 'corpo', h = 6, albedo = CORPO },
        { name = 'fogo', h = 12, albedo = albedo, emissive = emissive },
    },
}
