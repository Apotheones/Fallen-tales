-- VARANDA OCUPADA — prop composto de fachada, 64x96, origem TOPLEFT
-- (pendura na parede; quem posiciona ancora pelo canto). Varanda de
-- madeira com grade simples + cadeira virada para a rua ocupada por uma
-- FIGURA de costas — cabeça e ombros sobre o encosto, casaco areia,
-- cabelo ralo claro. A cadeira virada pra rua: lugar de ficar sem
-- falar. 2 frames de vida: f1 sentada quieta | f2 inclina a cabeça
-- olhando a rua (cabeça pende 1px p/ a direita + 1px p/ baixo).
-- Sem emissivo — varanda não é lâmpada. Relevo: grade 8-9, cadeira 7,
-- figura 8-9, platibanda/fachada 5-6, ménsulas 4.

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

--------------------------------------------------------------------------------
-- FIGURA (camada de trás): cadeira 'u' + pessoa de costas — nuca de
-- cabelo ralo 'g' sobre pele 's', casaco areia 'c' cobrindo os ombros,
-- mão esquerda no braço da cadeira. Cabeça pende no f2.
--------------------------------------------------------------------------------
local function figura(cabecaMap)
    local g = nova('.')
    -- cadeira: encosto de ripas, braços, pernas curtas até o piso
    faixa(g, 25, 41, 38, 'u'); faixa(g, 25, 41, 39, 'v')
    for _, x in ipairs({ 26, 33, 40 }) do
        for y = 40, 56 do set(g, x, y, 'u'); set(g, x + 1, y, 'v') end
    end
    -- braços da cadeira
    faixa(g, 23, 25, 48, 'u'); faixa(g, 41, 43, 48, 'u')
    set(g, 24, 49, 'v'); set(g, 42, 49, 'v')
    set(g, 24, 50, 'v'); set(g, 42, 50, 'v')
    -- pernas até o piso da varanda
    for y = 51, 60 do
        set(g, 25, y, 'u'); set(g, 26, y, 'v')
        set(g, 40, y, 'u'); set(g, 41, y, 'v')
    end
    -- figura: ombros sobem além do encosto (de costas para a rua,
    -- ombros para a fachada — lemos a nuca e o casaco)
    for y = 40, 55 do
        local folga = (y < 44) and (44 - y) or 0
        local x0, x1 = 26 + folga, 40 - folga
        for x = x0, x1 do
            local ch = 'c'
            if x == x0 then ch = 'k' end
            if x == x1 then ch = 'k' end
            if y == 55 then ch = 'C' end -- barra do casaco
            set(g, x, y, ch)
        end
    end
    -- mão esquerda da figura apoiada no braço da cadeira
    set(g, 24, 47, 's'); set(g, 25, 47, 's'); set(g, 24, 48, 's')
    -- cabeça (mapa variável por frame)
    for _, row in ipairs(cabecaMap) do
        local y, x0, s = row[1], row[2], row[3]
        for i = 1, #s do set(g, x0 + i - 1, y, s:sub(i, i)) end
    end
    return str(g)
end

-- cabeça ereta: nuca 'g' (cabelo ralo claro), orelha 's', gola 'C'
local cabecaEreta = {
    { 27, 30, '.kkkkk.' },
    { 28, 29, 'kggggggk' },
    { 29, 29, 'kggggggk' },
    { 30, 29, 'kghggghk' },
    { 31, 29, 'kggggggk' },
    { 32, 29, 'kgggkggk' },
    { 33, 29, 'kgsgggsk' },  -- orelhas de pele nas bordas
    { 34, 30, 'kgggggk' },
    { 35, 30, '.kggggk.' },
    { 36, 31, '.ksssk..' }, -- nuca/pescoço
    { 37, 30, 'kksssskk' },
    { 38, 30, 'kCCCCC Ck' },
}
-- cabeça inclinada: tudo +1 col e +1 linha, topo pende à direita
local cabecaInclinada = {
    { 28, 31, '.kkkkk.' },
    { 29, 30, 'kggggggk' },
    { 30, 30, 'kghggghk' },
    { 31, 30, 'kggggggk' },
    { 32, 30, 'kgggkggk' },
    { 33, 30, 'kgggggsk' },
    { 34, 31, 'kgggggk' },
    { 35, 31, '.kggggk.' },
    { 36, 32, '.ksssk..' },
    { 37, 31, 'kksssskk' },
    { 38, 30, 'kCCCCC Ck' },
}

--------------------------------------------------------------------------------
-- VARANDA (camada da frente): grade de balaústres + corrimão, piso de
-- tábuas com fachada, ménsulas embaixo. A figura fica atrás da grade.
--------------------------------------------------------------------------------
local function varanda()
    local g = nova('.')
    -- corrimão: topo claro, face em madeira
    faixa(g, 8, 56, 40, 'W'); faixa(g, 8, 56, 41, 'w')
    faixa(g, 8, 56, 42, 'w'); faixa(g, 8, 56, 43, 'v')
    -- balaústres: ritmo simples, 2px de pau a cada 7
    for x = 11, 54, 7 do
        for y = 44, 58 do
            set(g, x, y, 'w'); set(g, x + 1, y, 'v')
        end
    end
    -- travessa baixa
    faixa(g, 9, 55, 58, 'w'); faixa(g, 9, 55, 59, 'v')
    -- pilares das pontas com capitel simples
    for y = 37, 71 do
        for x = 8, 10 do
            set(g, x, y, y < 40 and 'W' or (x == 10 and 'v' or 'w'))
        end
        for x = 54, 56 do
            set(g, x, y, y < 40 and 'W' or (x == 56 and 'v' or 'w'))
        end
    end
    -- piso/parapeito frontal: tábuas com juntas e borda de sombra
    for y = 60, 69 do
        for x = 6, 58 do
            local ch = 'w'
            if y == 60 then ch = 'W'
            elseif y > 66 then ch = 'v'
            elseif x % 8 == 2 then ch = 'u'       -- junta da tábua
            elseif h2(x, y, 3) < 8 then ch = 'U'  -- veio claro
            end
            set(g, x, y, ch)
        end
    end
    faixa(g, 6, 58, 70, 'k')
    -- ménsulas: mão francesa sob o piso
    for _, bx in ipairs({ 12, 31, 50 }) do
        set(g, bx, 71, 'u'); set(g, bx + 1, 71, 'u')
        set(g, bx, 72, 'u'); set(g, bx + 1, 72, 'u'); set(g, bx + 2, 72, 'v')
        set(g, bx, 73, 'v'); set(g, bx + 1, 73, 'v'); set(g, bx + 2, 73, 'v')
        set(g, bx + 3, 73, 'v')
        set(g, bx + 1, 74, 'v'); set(g, bx + 2, 74, 'v'); set(g, bx + 3, 74, 'v')
        set(g, bx + 4, 74, 'v')
        set(g, bx + 2, 75, 'v'); set(g, bx + 3, 75, 'v'); set(g, bx + 4, 75, 'v')
        set(g, bx + 3, 76, 'v'); set(g, bx + 4, 76, 'v')
        set(g, bx + 4, 77, 'v')
    end
    return str(g)
end

return {
    name = 'varanda_ocupada',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 5},
        w = {ramp = 'wood', step = 4, h = 8},   -- grade/corrimão
        W = {ramp = 'wood', step = 6, h = 9},   -- fio claro gasto
        v = {ramp = 'wood', step = 2, h = 7},   -- sombra da madeira
        u = {ramp = 'wood', step = 3, h = 7},   -- cadeira/balaústre
        U = {ramp = 'wood', step = 5, h = 8},   -- veio
        c = {ramp = 'plaster', step = 3, h = 8}, -- casaco areia
        C = {ramp = 'plaster', step = 2, h = 8}, -- gola/barra em sombra
        s = {ramp = 'skin', step = 2, h = 9},    -- nuca/orelha/mão
        g = {ramp = 'plaster', step = 5, h = 9}, -- cabelo ralo claro
        h = {ramp = 'hair', step = 3, h = 9},    -- restos escuros no cabelo
    },

    -- prop composto: ancora pelo topleft; 'cabeca' marca a nuca da
    -- figura p/ debug/inspeção. Sem markers (não há contato transitório).
    anchors = {
        pe = {32, 96},
        cabeca = {{33, 33}, {34, 34}},
    },
    sequences = { idle = {1, 2, loop = true} },
    frameDuration = {2.6, 0.9},

    layers = {
        {name = 'figura', h = 8, albedo = {
            figura(cabecaEreta), figura(cabecaInclinada),
        }},
        {name = 'varanda', h = 7, albedo = varanda()},
    },
}
