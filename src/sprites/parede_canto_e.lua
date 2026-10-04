-- PAREDE_CANTO_E — quina de parede oblíqua, tile 64x96, origem topleft.
-- Fase 1 ARQ (docs/MEGAPLAN_VISUAL_HD.md §4-5): estende a linguagem de
-- parede.lua. A parede vira à esquerda: o cap dobra no canto (miter
-- diagonal com plano de retorno mais escuro e aresta iluminada), a face
-- continua em fiadas; a aresta vertical (quina) leva filete claro 'R'
-- e a face de retorno cai em sombra ('q'/'N'), separada por linha ink.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end

-- Fiadas da face frontal: mesmas de parede.lua, recortadas a partir da
-- coluna 21 (a quina ocupa 18-20; a face frontal vai de 21 a 64).
local A   = 'bbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local Aa  = 'bbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local A1a = 'aaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local B   = 'bbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbb'
local Ba  = 'bbbbbbbbmbbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbb'
local CK1 = 'bbbbbbbbbbbbbbbmbbbbkkbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local CK2 = 'bbbbbbbbbbbbbbbmbbbbbkkbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local Db  = 'ddddddddmdddddddddddddddmdddddddddddddddmdddddddddddddddmddddddd'
local M   = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'

-- Face de retorno (17 colunas, em sombra): fiadas mais fechadas p/
-- sugerir o plano que recua.
local SB_A = 'N' .. ('q'):rep(8) .. 'N' .. ('q'):rep(7)              -- 17
local SB_B = ('q'):rep(4) .. 'N' .. ('q'):rep(7) .. 'N' .. ('q'):rep(4)
local SM   = ('N'):rep(17)
local SD   = ('z'):rep(17)

local function frow(front, side) return side .. 'k' .. 'RR' .. L(front):sub(21) end

local rows = {}

-- Cap (linhas 1-29): topo como parede.lua, mas a dobra diagonal corta
-- do canto da quina (x~20, linha 30) até a borda de trás. Esquerda do
-- miter = plano de retorno ('v'), aresta = 'C'.
rows[1] = ('C'):rep(64)
rows[2] = ('C'):rep(64)
for r = 3, 29 do
    local xm = math.floor(20 - (30 - r) * 0.5 + 0.5)
    local t = {}
    for x = 1, 64 do t[x] = 'c' end
    -- desgaste e musgo herdados de parede.lua (só na porção frontal)
    if r == 10 or r == 11 then for x = 10, 14 do t[x] = 'v' end end
    if r == 21 then for x = 49, 56 do t[x] = 'g' end end
    if r == 22 or r == 23 then for x = 48, 56 do t[x] = 'g' end end
    if r == 24 then for x = 50, 56 do t[x] = 'g' end end
    if r == 25 then for x = 51, 55 do t[x] = 'g' end end
    for x = 1, 64 do
        if x < xm then t[x] = 'v' end
        if x == xm or x == xm + 1 then t[x] = 'C' end
    end
    t[64] = 'C'
    rows[r] = table.concat(t)
end
-- Bevel + lip: a quina desce pela borda do cap e o lado de retorno
-- escurece.
rows[30] = ('n'):rep(17) .. 'k' .. 'RR' .. ('C'):rep(44)
for r = 31, 34 do
    rows[r] = ('n'):rep(17) .. 'k' .. 'RR' .. ('l'):rep(44)
end

-- Face (35-96): mesmo ritmo de fiadas da parede; lado esquerdo em
-- sombra, filete 'R' na quina, costura ink entre os planos.
local seq = {
    { A, SB_A }, { Aa, SB_A }, { Aa, SB_A }, { A, SB_A },
    { A, SB_A }, { A, SB_A }, { A, SB_A }, { M, SM },
    { B, SB_B }, { B, SB_B }, { Ba, SB_B }, { Ba, SB_B },
    { B, SB_B }, { B, SB_B }, { M, SM },
    { A, SB_A }, { A, SB_A }, { CK1, SB_A }, { CK2, SB_A },
    { A, SB_A }, { A, SB_A }, { A, SB_A }, { M, SM },
    { B, SB_B }, { B, SB_B }, { Ba, SB_B }, { Ba, SB_B },
    { B, SB_B }, { B, SB_B }, { B, SB_B }, { M, SM },
    { A1a, SB_A }, { A1a, SB_A }, { A, SB_A }, { A, SB_A },
    { A, SB_A }, { A, SB_A }, { A, SB_A }, { M, SM },
    { B, SB_B }, { B, SB_B }, { B, SB_B }, { B, SB_B },
    { B, SB_B }, { B, SB_B }, { B, SB_B }, { M, SM },
    { A, SB_A }, { A, SB_A }, { A, SB_A }, { A, SB_A },
    { A, SB_A }, { A, SB_A }, { A, SB_A }, { M, SM },
    { Db, SD }, { Db, SD }, { Db, SD }, { Db, SD },
    { Db, SD }, { Db, SD }, { M, SM },
}
assert(#seq == 62, 'face da quina deve ter 62 linhas')
for i, par in ipairs(seq) do rows[34 + i] = frow(par[1], par[2]) end

return {
    name = 'parede_canto_e',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 6 },            -- costura da quina / trinca
        -- cap
        c = { ramp = 'stone', step = 6, h = 15 },
        C = { ramp = 'stone', step = 7, h = 15 },
        v = { ramp = 'stone', step = 5, h = 15 }, -- plano de retorno / desgaste
        l = { ramp = 'stone', step = 3, h = 13 }, -- lip frontal
        n = { ramp = 'stone', step = 2, h = 12 }, -- lip do lado de retorno
        g = { ramp = 'moss', step = 3, h = 15 },
        -- quina
        R = { ramp = 'stone', step = 7, h = 9 },  -- filete claro da aresta
        -- face de retorno (sombra)
        q = { ramp = 'stone', step = 3, h = 7 },
        N = { ramp = 'stone', step = 1, h = 6 },
        z = { ramp = 'stone', step = 2, h = 4 },
        -- face frontal (parede.lua)
        b = { ramp = 'stone', step = 4, h = 7 },
        a = { ramp = 'stone', step = 5, h = 7 },
        m = { ramp = 'stone', step = 2, h = 6 },
        d = { ramp = 'stone', step = 1, h = 4 },
    },

    layers = {
        {
            name = 'wall',
            h = 7,
            albedo = grid(rows),
        },
    },
}
