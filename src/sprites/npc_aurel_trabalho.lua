-- AUREL — loop de TRABALHO: cuidando do Marco, esfregando com o pano
-- (act 'tend'), idle SUL, 64x96, origem nos pés, 4f = ciclo contínuo.
-- Reusa as grades de npc_aurel_s: cabeça baixa 2px sobre o trabalho;
-- a mão esq. com o pano sai do lado e sobe — esfrega em círculo na
-- frente do corpo (4 posições: alto-esq, alto-dir, baixo, meio-esq).

local src = require('src.sprites.npc_aurel_s')

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
-- BODY: cabeça baixa 2px sobre o trabalho; a mão esq. com o pano
-- pendurado sai do lado (sobe esfregando, na camada 'mao').
--------------------------------------------------------------------------------
local body = shift(toMap(src.layers[1].albedo[1]), 2, 8, 27)
blank(body, 57, 66, 19, 24)   -- mão esq. + pano pendurados

local band = src.layers[2].albedo[1]  -- faixa de cintura, estática

--------------------------------------------------------------------------------
-- MAO (4f): antebraço esq. 'kcck' estendido à frente + punho 'kssk'
-- pressionando o pano aberto 'kpppk' — esfrega em círculo, voltando
-- ao ponto inicial (f4 -> f1).
--------------------------------------------------------------------------------
local function mao(panoR, panoC, punhoR, punhoC)
    local m = {}
    for r = 48, 52 do put(m, r, 27, 'kcck') end  -- antebraço do ombro
    for r = 53, 56 do put(m, r, 31, 'kcck') end  --   até a zona de esfrega
    for r = panoR, panoR + 4 do put(m, r, panoC, 'kpppk') end
    put(m, punhoR, punhoC, 'kssk')
    put(m, punhoR + 1, punhoC, 'kssk')
    return m
end

local f1 = mao(50, 32, 48, 33)   -- pano alto, à esquerda
local f2 = mao(52, 34, 50, 35)   -- desliza à direita
local f3 = mao(54, 32, 52, 33)   -- desce
local f4 = mao(52, 30, 50, 31)   -- volta pela esquerda

return {
    name = 'npc_aurel_trabalho',
    w = 64, h = 96,
    origin = 'feet',
    legend = src.legend,
    layers = {
        {name = 'body', h = 4, albedo = {R(body), R(body), R(body), R(body)}},
        {name = 'trab', h = 8, albedo = {band, band, band, band}},
        {name = 'mao', h = 7, albedo = {R(f1), R(f2), R(f3), R(f4)}},
    },
}
