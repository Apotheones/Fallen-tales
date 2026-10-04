-- PAREDE_PORTA — fachada oblíqua com porta, tile 64x96, origem topleft.
-- Cap de parede.lua; na face, folha de madeira em tábuas verticais com
-- travessas, jambas 'J' e lintel 'T' de pedra, degrau de limiar ao pé
-- e ferragem 'i' (dobradiças, argola e fechadura).

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end

local A   = 'bbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local Aa  = 'bbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local A1a = 'aaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local B   = 'bbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbb'
local Ba  = 'bbbbbbbbmbbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbb'
local Db  = 'ddddddddmdddddddddddddddmdddddddddddddddmdddddddddddddddmddddddd'
local M   = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'

-- Vão: jambas 21-22 e 43-44, folha em 23-42 (20 col). Lintel 19-46.
-- Tábuas verticais 'w' com junta rebaixada 'x' a cada 4 px.
local TABUA = 'wwx' .. ('wwwx'):rep(4) .. 'w'              -- 20
local function porta(side, folha)
    return side:sub(1, 20) .. 'JJ' .. folha .. 'JJ' .. side:sub(45)
end
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
    if r == 12 or r == 13 then for x = 34, 38 do t[x] = 'v' end end
    if r == 20 then for x = 12, 18 do t[x] = 'g' end end
    if r == 21 or r == 22 then for x = 11, 19 do t[x] = 'g' end end
    if r == 23 then for x = 13, 18 do t[x] = 'g' end end
    rows[r] = table.concat(t)
end
rows[30] = ('C'):rep(64)
for r = 31, 34 do rows[r] = ('l'):rep(64) end

-- Face (35-96).
rows[35] = L(A); rows[36] = L(Aa); rows[37] = L(Aa)
rows[38] = L(A); rows[39] = L(A); rows[40] = L(A); rows[41] = L(A)
rows[42] = L(M)
rows[43] = L(B); rows[44] = L(B); rows[45] = L(Ba)
rows[46] = L(Ba); rows[47] = L(B); rows[48] = L(B); rows[49] = L(B)
rows[50] = L(M)
-- Lintel de pedra sobre o vão, avançando 2 px por lado.
rows[51] = L(faixa(A, 19, 28, 'T'))
rows[52] = L(faixa(A, 19, 28, 'T'))
-- Sombra sob o lintel; as jambas nascem aqui e descem até o degrau.
rows[53] = L(porta(A, ('k'):rep(20)))
-- Folha da porta (54-91): tábuas, travessas em 58-59 e 86-87,
-- dobradiças de ferro na esquerda, argola e fechadura à direita.
for r = 54, 91 do
    local folha = TABUA
    if r == 58 or r == 59 or r == 86 or r == 87 then
        folha = ('B'):rep(20)                          -- travessa corrida
    end
    if r == 58 or r == 59 then
        folha = 'ii' .. folha:sub(3, 8) .. 'i' .. folha:sub(10) -- dobradiça alta
    end
    if r == 86 or r == 87 then
        folha = 'ii' .. folha:sub(3, 8) .. 'i' .. folha:sub(10) -- dobradiça baixa
    end
    if r == 75 then folha = folha:sub(1, 14) .. 'iIi' .. folha:sub(19) end
    if r == 76 then folha = folha:sub(1, 14) .. 'iII' .. folha:sub(19) end
    if r == 77 then folha = folha:sub(1, 14) .. 'iii' .. folha:sub(19) end
    rows[r] = L(porta(r % 4 == 2 and Ba or B, folha))
end
-- Frecha sob a folha e o degrau do limiar: topo claro, frente em sombra.
rows[92] = L(porta(B, ('k'):rep(20)))
rows[93] = L(faixa(B, 19, 28, 'S'))
rows[94] = L(faixa(Db, 19, 28, 's'))
rows[95] = L(faixa(Db, 19, 28, 'd'))
rows[96] = L(M)

return {
    name = 'parede_porta',
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
        -- portal de pedra
        J = { ramp = 'stone', step = 5, h = 9 },   -- jamba
        T = { ramp = 'stone', step = 6, h = 10 },  -- lintel
        S = { ramp = 'stone', step = 6, h = 7 },   -- degrau, topo
        s = { ramp = 'stone', step = 3, h = 5 },   -- degrau, frente
        -- folha de madeira
        w = { ramp = 'wood', step = 4, h = 8 },
        x = { ramp = 'wood', step = 2, h = 7 },    -- junta das tábuas
        B = { ramp = 'wood', step = 5, h = 9 },    -- travessa
        -- ferragem
        i = { ramp = 'iron', step = 4, h = 9 },
        I = { ramp = 'iron', step = 6, h = 9 },
    },

    layers = {
        {
            name = 'wall',
            h = 7,
            albedo = grid(rows),
        },
    },
}
