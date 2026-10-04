-- VELAS agrupadas — prop de luz, 64x64, origem nos pés.
-- Capela do Refúgio (nota vida-refugio-props §8): grupo de velas de
-- cera de osso em prato baixo de ouro velho — alturas desencontradas,
-- pavios tortos, cera escorrida. Chamas ember PEQUENAS ei~0.5 agrupadas
-- no canal emissivo: bloom contido, não farol. O emissivo é derivado
-- dos pavios 'k' do albedo — cada pavio ganha núcleo 'F' e ponta 'f'.
-- Relevo: prato 4-5, velas 7-9, pavio 9, chama 12.
--
-- LOOP AMBIENTAL (frente micro-animações): f1..f3 = flicker miúdo.
-- Só o canal EMISSIVO anima (as chamas não existem no albedo):
-- f1 = base ei .55/.40; f2 acende (J/j, ei+.10) com pontas pendendo
-- ±1 px; f3 apaga (H/h, ei-.10), algumas pontas caem 1 px (chama mais
-- baixa). O grupo nunca mexe junto — cada vela tem seu próprio dx.

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

-- Emissivo derivado do albedo: onde há pavio 'k', núcleo no pavio e
-- ponta um pixel acima — chama nasce na mecha, nunca solta. `fase`
-- (1..3) escolhe o par de chars (brilho) e desloca as pontas:
--   f1 = F/f base; f2 = J/j (+.10 ei), pontas pendem; f3 = H/h (-.10),
--   uma a cada 4 velas perde a ponta (chama agacha 1 px).
local NUC = {'F', 'J', 'H'}
local PONTA = {'f', 'j', 'h'}

local function chamas(albedo, fase)
    local rows = {}
    for r in albedo:gmatch('([^\n]+)\n?') do rows[#rows + 1] = r end
    local g = {}
    for y = 1, #rows do
        local linha = {}
        for x = 1, 64 do linha[x] = '.' end
        g[y] = linha
    end
    local i = 0
    for y = 1, #rows do
        local r = rows[y]
        for x = 1, #r do
            if r:sub(x, x) == 'k' then
                i = i + 1
                g[y][x] = NUC[fase]
                -- ponta treme 1 px para os lados; no f3 cada 4ª vela
                -- fica sem ponta (chama baixa)
                local dx = fase == 1 and 0
                    or ((i * 5 + fase * 3) % 3) - 1
                local semPonta = fase == 3 and (i % 4 == 0)
                if not semPonta and y > 1 then
                    local tx = math.max(1, math.min(64, x + dx))
                    if g[y - 1][tx] == '.' then g[y - 1][tx] = PONTA[fase]
                    elseif g[y - 1][x] == '.' then
                        g[y - 1][x] = PONTA[fase]
                    end
                end
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
        -- chamas pequenas: núcleo e ponta, ei contido — f1 base,
        -- J/j aceso (+.10) e H/h apagado (-.10) para o loop f1..f3
        F = { ramp = 'ember', step = 6, h = 12, e = 'ember.6', ei = 0.55 },
        f = { ramp = 'ember', step = 4, h = 12, e = 'ember.4', ei = 0.4 },
        J = { ramp = 'ember', step = 6, h = 12, e = 'ember.6', ei = 0.65 },
        j = { ramp = 'ember', step = 4, h = 12, e = 'ember.4', ei = 0.5 },
        H = { ramp = 'ember', step = 6, h = 12, e = 'ember.6', ei = 0.45 },
        h = { ramp = 'ember', step = 4, h = 12, e = 'ember.4', ei = 0.3 },
        -- contato
        e = { ramp = 'earth', step = 3, h = 1 },
    },

    layers = {
        {
            -- f1..f3 = loop de flicker das chamas (ver cabeçalho); a
            -- cera/prato (albedo) é estável.
            name = 'grupo',
            h = 5,
            albedo = ALBEDO,
            emissive = {chamas(ALBEDO, 1), chamas(ALBEDO, 2),
                chamas(ALBEDO, 3)},
        },
    },
}
