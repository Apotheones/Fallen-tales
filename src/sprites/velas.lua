-- VELAS agrupadas — prop de luz, 64x64, origem nos pés.
-- Capela do Refúgio (nota vida-refugio-props §8): grupo de velas de
-- cera de osso em prato baixo de ouro velho — alturas desencontradas,
-- pavios tortos, cera escorrida. Chamas ember PEQUENAS ei~0.5 agrupadas
-- no canal emissivo: bloom contido, não farol. O emissivo é derivado
-- dos pavios 'k' do albedo — cada pavio ganha núcleo 'F' e ponta 'f'.
-- Relevo: prato 4-5, velas 7-9, pavio 9, chama 12.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

local ALBEDO = grid {
    E, E, E, E, E, E, E, E, E, E,                     --  1-10
    E, E, E, E, E,                                    -- 11-15
    -- a mais alta, esquerda do miolo
    L'..............................k',                 -- 16
    L'.............................BBb',                -- 17
    L'.............................bbb',                -- 18
    L'..............................k...k',             -- 19
    L'.............................bbb.BBb',            -- 20
    L'............................wbbb.bbb',            -- 21
    L'.............................bbb.bbb.k',          -- 22
    L'.........................k...bwbb.BBb',           -- 23
    L'........................BBb..bbb.bbb',            -- 24
    L'........................bbb..bbb.bwbb',           -- 25
    L'........................bbb..bbb.bbb.k',          -- 26
    L'......................k.wbb..bbb.bBBb',           -- 27
    L'.....................BBb.bbb..bbb.bbb',           -- 28
    L'.....................bbb.bbb..bbb.bbb',           -- 29
    L'....................k.bbb.bwb..bwbb.bwb',         -- 30
    L'..................BBBb.bbb.bbb..bbb.bbb',         -- 31
    L'..................bbbb.bbb.bbb..bbb.bbb',         -- 32
    L'..................bwbk.bbb.bbb..bbb.bwb',         -- 33
    L'..................bbb.BBb.bbb..bbb.bbb',          -- 34
    L'..................bbb.bbb.bbb..bwb.bwb',          -- 35
    L'................k.bbb.bbb.bbb..bbb.bbb',          -- 36
    L'...............BBBb.bwb.bbb..BBBb.bbb',           -- 37
    L'...............bbbb.bbb.bwb..bbbb.bwb',           -- 38
    L'...............bwbb.bbb.bbb..bwbb.bbb',           -- 39
    L'...............bbb.bbb.bbb..bbb.bbb',             -- 40
    L'...............bwb.bbb.bbb..bbb.bbb',             -- 41
    L'...............bbb.bbb.bbb..bbb.bbb',             -- 42
    L'...............bbb.bbb.bbb..bbb.bwb',             -- 43
    L'...............bbb.bbb.bwb..bbb.bbb',             -- 44
    L'...............wbb.bwb.bbb..bwb.wbb',             -- 45
    L'...............bbb.bbb.bbb..bbb.bbb',             -- 46
    L'...............bbb.bbb.bbb..bbb.bbb',             -- 47
    L'...............bwb.bwb.bwb..bwb.bwb',             -- 48
    L'...............bbb.bbb.bbb..bbb.bbb',             -- 49
    E,                                                -- 50
    -- prato: borda, corpo, pé
    L'.............GGGGGGGGGGGGGGGGGGGGGGGGGGGG',       -- 51
    L'............gggggggggggggggggggggggggggggg',      -- 52
    L'............gggwggwggggwgggggwgggggwggwggg',      -- 53
    L'.............gggggggggggggggggggggggggggg',       -- 54
    L'..............dddddddddddddddddddddddddd',        -- 55
    L'.................dddddddddddddddddddd',           -- 56
    E, E, E, E, E,                                    -- 57-61
    -- contato
    L'..................e....e......e....e',            -- 62
    L'.................e......e.....e.....e',           -- 63
    E,                                                -- 64
}

-- Emissivo derivado do albedo: onde há pavio 'k', núcleo 'F' no pavio
-- e ponta 'f' um pixel acima — chama nasce na mecha, nunca solta.
local function chamas(albedo)
    local rows = {}
    for r in albedo:gmatch('([^\n]+)\n?') do rows[#rows + 1] = r end
    local g = {}
    for y = 1, #rows do
        local linha = {}
        for x = 1, 64 do linha[x] = '.' end
        g[y] = linha
    end
    for y = 1, #rows do
        local r = rows[y]
        for x = 1, #r do
            if r:sub(x, x) == 'k' then
                g[y][x] = 'F'
                if y > 1 and g[y - 1][x] == '.' then g[y - 1][x] = 'f' end
            end
        end
    end
    local out = {}
    for y = 1, #g do out[y] = table.concat(g[y]) end
    return table.concat(out, '\n')
end

return {
    name = 'velas',
    w = 64, h = 64,
    origin = 'feet',

    legend = {
        k = { spec = 'ink', h = 9 },              -- pavio
        -- prato baixo de ouro velho
        G = { ramp = 'gold', step = 4, h = 5 },
        g = { ramp = 'gold', step = 3, h = 4 },
        d = { ramp = 'gold', step = 1, h = 3 },
        -- velas de osso: corpo, fio iluminado, cera escorrida
        b = { ramp = 'bone', step = 4, h = 8 },
        B = { ramp = 'bone', step = 5, h = 9 },
        w = { ramp = 'bone', step = 3, h = 7 },
        -- chamas pequenas: núcleo e ponta, ei contido
        F = { ramp = 'ember', step = 6, h = 12, e = 'ember.6', ei = 0.55 },
        f = { ramp = 'ember', step = 4, h = 12, e = 'ember.4', ei = 0.4 },
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            name = 'grupo',
            h = 5,
            albedo = ALBEDO,
            emissive = chamas(ALBEDO),
        },
    },
}
