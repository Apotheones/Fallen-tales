-- PAREDE_JANELA — fachada oblíqua com janela, tile 64x96, origem
-- topleft. Cap idêntico a parede.lua; na face, abertura escura
-- (abyss, rebaixada) com ombreira 'T', peitoril 'S' projetado, jambas
-- 'J' e caixilho 'w' de madeira. Brilho quente FRACO dentro
-- (ember ei~0.35/0.2): casa viva à noite, não chamadela de farol.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end

-- Fiadas de parede.lua.
local A   = 'bbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local Aa  = 'bbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local B   = 'bbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbb'
local Ba  = 'bbbbbbbbmbbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbb'
local Db  = 'ddddddddmdddddddddddddddmdddddddddddddddmdddddddddddddddmddddddd'
local M   = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'

-- Abertura: jambas em 22-23 e 42-43, vão em 24-41 (caixilho vertical
-- em 32-33). Lintel/peitoril de 20 a 45.
local VAO = ('o'):rep(8) .. 'ww' .. ('o'):rep(8)     -- 18
local TRAV = ('w'):rep(18)                          -- caixilho horizontal
local function janela(side) return side:sub(1, 21) .. 'JJ' .. VAO .. 'JJ' .. side:sub(44) end
local function travessa(side) return side:sub(1, 21) .. 'JJ' .. TRAV .. 'JJ' .. side:sub(44) end
local function faixa(side, x1, n, ch)
    return side:sub(1, x1 - 1) .. (ch):rep(n) .. side:sub(x1 + n)
end

local rows = {}
-- Cap (1-34): igual a parede.lua.
rows[1] = ('C'):rep(64)
rows[2] = ('C'):rep(64)
for r = 3, 29 do
    local t = {}
    for x = 1, 64 do t[x] = 'c' end
    t[1], t[64] = 'C', 'C'
    if r == 10 or r == 11 then for x = 10, 14 do t[x] = 'v' end end
    if r == 21 then for x = 49, 56 do t[x] = 'g' end end
    if r == 22 or r == 23 then for x = 48, 56 do t[x] = 'g' end end
    if r == 24 then for x = 50, 56 do t[x] = 'g' end end
    if r == 25 then for x = 51, 55 do t[x] = 'g' end end
    rows[r] = table.concat(t)
end
rows[30] = ('C'):rep(64)
for r = 31, 34 do rows[r] = ('l'):rep(64) end

-- Face (35-96).
rows[35] = L(A); rows[36] = L(Aa); rows[37] = L(Aa)
rows[38] = L(A); rows[39] = L(A); rows[40] = L(A); rows[41] = L(A)
rows[42] = L(M)
-- Ombreira aparente: lintel de pedra mais claro, avança 2 px por lado.
rows[43] = L(faixa(B, 20, 26, 'T'))
rows[44] = L(faixa(B, 20, 26, 'T'))
rows[45] = L(faixa(B, 20, 26, 'T'))
-- Sombra sob o lintel já dentro do vão.
rows[46] = L(B:sub(1, 21) .. 'JJ' .. ('k'):rep(18) .. 'JJ' .. B:sub(44))
-- Vão com caixilho; mortar lateral atravessa atrás das jambas.
for r = 47, 52 do rows[r] = L(janela(r % 3 == 0 and Ba or B)) end
rows[53] = L(M:sub(1, 21) .. 'JJ' .. VAO .. 'JJ' .. M:sub(44))
for r = 54, 57 do rows[r] = L(janela(B)) end
rows[58] = L(travessa(B))
rows[59] = L(travessa(B))
for r = 60, 63 do rows[r] = L(janela(A)) end
rows[64] = L(M:sub(1, 21) .. 'JJ' .. VAO .. 'JJ' .. M:sub(44))
for r = 65, 71 do rows[r] = L(janela(r % 3 == 1 and Aa or A)) end
-- Peitoril: topo claro, corpo, sombra embaixo.
rows[72] = L(faixa(B, 20, 26, 'S'))
rows[73] = L(faixa(B, 20, 26, 's'))
rows[74] = L(faixa(B, 20, 26, 's'))
rows[75] = L(faixa(B, 20, 26, 'm'))
rows[76] = L(B); rows[77] = L(B); rows[78] = L(Ba)
rows[79] = L(Ba); rows[80] = L(B)
rows[81] = L(M)
for r = 82, 88 do rows[r] = L(r % 3 == 1 and Aa or A) end
rows[89] = L(M)
for r = 90, 95 do rows[r] = L(Db) end
rows[96] = L(M)

-- Emissivo: luz morna baixa dentro da casa, recortada pelo caixilho
-- (vão x24-41; 'w' em 32-33 apaga o brilho). Nada acima do peitoril —
-- é lamparina, não incêndio.
local egrid = {}
local function eseg(y, x, s)
    local row = egrid[y] or {}
    for i = 1, #s do row[x + i - 1] = s:sub(i, i) end
    egrid[y] = row
end
-- brilho difuso fraco subindo do fundo do vão
eseg(61, 27, 'OOO'); eseg(61, 35, 'OOO')
eseg(63, 26, 'OOOOO'); eseg(63, 34, 'OOOOO')
eseg(65, 25, 'OOOOOO'); eseg(65, 34, 'OOOOOOO')
eseg(66, 25, 'OeeeeO'); eseg(66, 34, 'OeeeeeO')
eseg(67, 25, 'OeeeeeO'); eseg(67, 34, 'OeeeeeeO')
eseg(68, 25, 'Oeeeeee'); eseg(68, 34, 'OeeeeeeO')
eseg(69, 25, 'eeeeeee'); eseg(69, 34, 'eeeeeeee')
eseg(70, 26, 'eeeeeee'); eseg(70, 34, 'eeeeeee')
eseg(71, 27, 'eeeee'); eseg(71, 35, 'eeeee')
-- uma luzinha mais alta, como chama de vela no fundo
eseg(55, 27, 'O'); eseg(56, 27, 'O'); eseg(56, 36, 'O')
local erows = {}
for r = 1, 96 do
    local t = {}
    for x = 1, 64 do t[x] = (egrid[r] and egrid[r][x]) or '.' end
    erows[r] = table.concat(t)
end

return {
    name = 'parede_janela',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 6 },
        -- cap (parede.lua)
        c = { ramp = 'stone', step = 6, h = 15 },
        C = { ramp = 'stone', step = 7, h = 15 },
        v = { ramp = 'stone', step = 5, h = 15 },
        l = { ramp = 'stone', step = 3, h = 13 },
        g = { ramp = 'moss', step = 3, h = 15 },
        -- face
        b = { ramp = 'stone', step = 4, h = 7 },
        a = { ramp = 'stone', step = 5, h = 7 },
        m = { ramp = 'stone', step = 2, h = 6 },
        d = { ramp = 'stone', step = 1, h = 4 },
        -- janela
        J = { ramp = 'stone', step = 5, h = 9 },   -- jamba
        T = { ramp = 'stone', step = 6, h = 10 },  -- lintel
        S = { ramp = 'stone', step = 6, h = 10 },  -- peitoril, topo
        s = { ramp = 'stone', step = 5, h = 10 },  -- peitoril, corpo
        o = { spec = 'abyss', h = 3 },             -- vão escuro rebaixado
        w = { ramp = 'wood', step = 2, h = 4 },    -- caixilho de madeira
        -- brilho interno (só no canal emissivo)
        e = { ramp = 'ember', step = 4, h = 4, e = 'ember.4', ei = 0.35 },
        O = { ramp = 'ember', step = 3, h = 4, e = 'ember.3', ei = 0.2 },
    },

    layers = {
        {
            name = 'wall',
            h = 7,
            albedo = grid(rows),
            emissive = grid(erows),
        },
    },
}
