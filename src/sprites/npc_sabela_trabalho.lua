-- SABELA — loop de TRABALHO: escrevendo de pé no caderno (act
-- 'write'), idle SUL, 64x96, origem nos pés, 4f = ciclo contínuo.
-- Reusa as grades de npc_sabela_s: cabeça baixa 2px sobre o caderno,
-- que sobe à altura do peito; a mão dir. sai do lado e vai escrever —
-- punho+lápis 'i' tremem entre 2 posições (f1/f3 vs f2/f4).

local src = require('src.sprites.npc_sabela_s')

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)
local function R(map)
    local t = {}
    for r = 1, 96 do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end
local function toMap(grid)
    local m = {}
    for l in grid:gmatch('[^\n]+') do m[#m + 1] = l end
    return m
end
local function shift(map, dy, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if rmin and r >= rmin and r <= rmax then t[r + dy] = s
        else t[r] = s end
    end
    return t
end
local function patch(map, edits)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    for r, s in pairs(edits) do t[r] = s end
    return t
end
local function put(map, r, c, s)
    local row = L(map[r] or '')
    map[r] = row:sub(1, c - 1) .. s .. row:sub(c + #s)
end
local function blank(map, r1, r2, c1, c2)
    for r = r1, r2 do
        local row = map[r]
        if row then
            row = L(row)
            map[r] = row:sub(1, c1 - 1) .. ('.'):rep(c2 - c1 + 1)
                .. row:sub(c2 + 1)
        end
    end
end

--------------------------------------------------------------------------------
-- BODY: cabeça baixa 2px sobre o caderno; a mão dir. solta sai (vai
-- escrever na camada gear). A esq. fica — segura o caderno por trás.
--------------------------------------------------------------------------------
local body = shift(toMap(src.layers[1].albedo[1]), 2, 8, 28)
blank(body, 57, 62, 48, 53)   -- punho dir. solto

--------------------------------------------------------------------------------
-- GEAR: caderno sobe à altura do peito; dedos esq. sobre a borda;
-- antebraço dir. cruza à frente do casaco até a página. Pasta 'Q'
-- fica no lugar. Punho que escreve + lápis: 2 posições (tremor).
--------------------------------------------------------------------------------
local gear = patch(toMap(src.layers[2].albedo[1]), {
    [54] = '.................kPPPPk',
    [55] = '.................kPppPk',
    [56] = '.................kPPPPk',
    [57] = '.................kPPPPk.........................kQQk',
    [58] = '.................kPPPPk.........................kQQk',
    [59] = '..................kkkk..........................kQqk',
    [60] = '.................................................kQqk',
    [61] = '.................................................kQqk',
    [62] = '.................................................kQqk',
    [63] = '.................................................kQqk',
    [64] = '.................................................kQqk',
    [65] = '.................................................kQqk',
})
put(gear, 53, 18, 'ksssk')   -- dedos esq. sobre a borda do caderno
-- antebraço dir. cruza à frente do casaco — faixa dupla (2px) para ler
-- como braço a 1x, não como filete único
put(gear, 53, 40, 'kcccck')
put(gear, 54, 34, 'kcccccccccck')
put(gear, 55, 28, 'kcccccccccck')
put(gear, 56, 28, 'kcccck')

local function copia(map)
    local t = {}
    for r, s in pairs(map) do t[r] = s end
    return t
end
local function maoA()
    local m = copia(gear)
    put(m, 54, 23, 'kssk')     -- punho sobre a borda direita da página
    put(m, 55, 23, 'kssk')
    put(m, 56, 22, 'i')        -- ponta do lápis tocando a página
    return m
end
local function maoB()
    local m = copia(gear)
    put(m, 55, 24, 'kssk')     -- 1px p/ baixo+direita: tremor de escrita
    put(m, 56, 24, 'kssk')
    put(m, 57, 23, 'i')
    return m
end

local legend = {}
for ch, e in pairs(src.legend) do legend[ch] = e end
legend.i = {ramp = 'earth', step = 5, h = 8}  -- lápis/grafite

return {
    name = 'npc_sabela_trabalho',
    w = 64, h = 96,
    origin = 'feet',
    legend = legend,
    layers = {
        {name = 'body', h = 4, albedo = {R(body), R(body), R(body), R(body)}},
        {name = 'gear', h = 7, albedo = {R(maoA()), R(maoB()), R(maoA()), R(maoB())}},
    },
}
