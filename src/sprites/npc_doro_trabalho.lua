-- DORO — loop de TRABALHO: martelando na bancada (act 'hammer'),
-- idle SUL, 64x96, origem nos pés, 4f = ciclo contínuo.
-- Reusa as grades de npc_doro_s (require + toMap, sem duplicar arte):
-- cabeça baixa 2px sobre a peça; punhos soltos removidos — a mão esq.
-- segura a peça (camada 'trab', fixa) e o braço dir. martela (camada
-- 'arm', 4 posições: alto, descendo, golpe na peça, volta).

local src = require('src.sprites.npc_doro_s')

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
-- Escreve a string s na linha r a partir da coluna c.
local function put(map, r, c, s)
    local row = L(map[r] or '')
    map[r] = row:sub(1, c - 1) .. s .. row:sub(c + #s)
end
-- Apaga o retângulo cols c1..c2 das linhas r1..r2.
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
-- BODY: mesmo corpo do idle sul, curvado sobre a bancada. Cabeça
-- desce 2px (olhar na peça); os dois punhos soltos saem — os braços
-- novos vêm nas camadas de cima.
--------------------------------------------------------------------------------
local body = shift(toMap(src.layers[1].albedo[1]), 2, 9, 35)
blank(body, 58, 61, 15, 20)   -- punho esq. solto
blank(body, 58, 61, 49, 54)   -- punho dir. solto
blank(body, 62, 62, 15, 19)
blank(body, 62, 62, 47, 51)

local garb = src.layers[2].albedo[1]  -- avental+faixa, estático

--------------------------------------------------------------------------------
-- TRAB (fixo): antebraço esq. à frente do avental + punho segurando
-- a peça 'w'/'W' na altura da bancada.
--------------------------------------------------------------------------------
local trab = {}
put(trab, 55, 23, 'kllllk')
put(trab, 56, 23, 'kllllk')
put(trab, 57, 25, 'kllllk')
put(trab, 58, 27, 'kllk')
put(trab, 61, 35, 'kwwwwk')
put(trab, 62, 35, 'kWWWWk')
put(trab, 63, 35, 'kkkkkk')
put(trab, 58, 30, 'kssssk')
put(trab, 59, 30, 'kssssk')
put(trab, 60, 30, 'kssssk')
put(trab, 61, 30, 'kssssk')
put(trab, 62, 31, 'kkkk')

--------------------------------------------------------------------------------
-- ARM (4f): manga 'kllk' ligando ao ombro, punho 'ksmmsk' fechado no
-- cabo 'mm', cabeça do martelo 'kMMMMk'. O ciclo desce rápido e sobe
-- devagar: 43 -> 47 -> 59 (golpe) -> 45.
--------------------------------------------------------------------------------
local function arm(punhoR, cabecaR, caboTop, caboBot)
    local m = {}
    for r = punhoR - 3, punhoR - 1 do put(m, r, 44, 'kllk') end
    put(m, cabecaR, 41, 'kMMMMk')
    put(m, cabecaR + 1, 41, 'kMMMMk')
    for r = caboTop, caboBot do put(m, r, 43, 'mm') end
    put(m, punhoR, 41, 'ksmmsk')
    put(m, punhoR + 1, 41, 'kssssk')
    put(m, punhoR + 2, 42, 'kkkk')
    return m
end

local f1 = arm(51, 43, 45, 50)   -- martelo alto
local f2 = arm(55, 47, 49, 54)   -- descendo
local f3 = arm(49, 59, 52, 58)   -- golpe: cabeça embaixo, junto à peça
local f4 = arm(53, 45, 47, 52)   -- volta

local legend = {}
for ch, e in pairs(src.legend) do legend[ch] = e end
legend.m = {ramp = 'wood', step = 4, h = 7}   -- cabo do martelo
legend.M = {ramp = 'iron', step = 5, h = 9}   -- cabeça do martelo
legend.w = {ramp = 'wood', step = 3, h = 6}   -- peça na bancada
legend.W = {ramp = 'wood', step = 5, h = 7}

return {
    name = 'npc_doro_trabalho',
    w = 64, h = 96,
    origin = 'feet',
    legend = legend,
    layers = {
        {name = 'body', h = 4, albedo = {R(body), R(body), R(body), R(body)}},
        {name = 'garb', h = 6, albedo = {garb, garb, garb, garb}},
        {name = 'trab', h = 7, albedo = {R(trab), R(trab), R(trab), R(trab)}},
        {name = 'arm', h = 7, albedo = {R(f1), R(f2), R(f3), R(f4)}},
    },
}
