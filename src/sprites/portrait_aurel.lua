-- PORTRAIT — AUREL, busto de diálogo 96x96, origin='topleft'.
-- Mesma pessoa do npc_aurel_s.lua: rosto LONGO e estreito, testa alta
-- (linha do cabelo grisalho 'g' recuada), orelhas grandes à mostra,
-- barba raspada 'd', nariz reto 'd'. Gola alta estreita 'z' subindo
-- pelo pescoço (âncora), sobrecasaca azul carvão 'c' sobre túnica de
-- linho pérola 't' aberta à frente.
-- FRAMES = expressões (§8 do doc de personagens):
--   [1] neutro | [2] ternura (afeto breve: testa relaxa, pálpebras
--       baixam, sorriso mínimo) | [3] concentracao (paciência de exame:
--       sobrancelha reta baixa, olhar fixo, cabeça inclina -1px).

local W, H = 96, 96
local E = string.rep('.', W)
local function L(s)
    assert(#s <= W, 'linha de sprite > 96 colunas')
    return s .. string.rep('.', W - #s)
end
local function R(map)
    local t = {}
    for r = 1, H do
        local s = map[r]
        t[r] = s and L(s) or E
    end
    return table.concat(t, '\n')
end
local function row(...)
    local t = {}
    for i = 1, W do t[i] = '.' end
    for _, p in ipairs({...}) do
        local col, s = p[1], p[2]
        for i = 1, #s do
            local x = col + i - 1
            if x >= 1 and x <= W then t[x] = s:sub(i, i) end
        end
    end
    return table.concat(t)
end
local function patch(base, repl)
    local t = {}
    for r, s in pairs(base) do t[r] = s end
    for r, s in pairs(repl) do t[r] = s end
    return t
end
local function hshift(s, dx)
    s = L(s)
    local last = s:match('^.*[^%.]')
    if not last then return s end
    local a, b = s:find('[^%.]'), #last
    local run = s:sub(a, b)
    local na = math.max(1, math.min(W - #run + 1, a + dx))
    return string.rep('.', na - 1) .. run .. string.rep('.', W - na + 1 - #run)
end
local function htilt(map, dx, rtop, rbot)
    local t = {}
    for r, s in pairs(map) do
        if s and r >= rtop and r <= rbot then
            local f = (rbot - r) / math.max(1, rbot - rtop)
            t[r] = hshift(s, math.floor(dx * f + 0.5))
        else t[r] = s end
    end
    return t
end

--------------------------------------------------------------------------------
-- BUSTO NEUTRO
--------------------------------------------------------------------------------
local neutro = {
    -- cabelo grisalho puxado para trás; linha recuada = testa alta
    [8]  = row({40,'kkkkkkkkkkkkkk'}),
    [9]  = row({37,'kgggggggggggggggk'}),
    [10] = row({35,'kggggggggggggggggggk'}),
    [11] = row({34,'kggGggggggggggggggggk'}),
    [12] = row({34,'kggggggggggggggggggggk'}),
    [13] = row({34,'kggggggggggggggggggggk'}),
    -- têmporas grisalhas finas; a testa de pele é o traço
    [14] = row({34,'kg'},{36,'ssssssssssssssssssss'},{56,'gk'}),
    [15] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [16] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [17] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [18] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [19] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [20] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [21] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [22] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [23] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [24] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    -- sobrancelhas grisalhas finas 'ggg' sobre olhos 'ee'
    [25] = row({35,'k'},{36,'ssss'},{40,'ggg'},{43,'ssssssss'},{51,'ggg'},{54,'ssssss'},{60,'k'}),
    [26] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    -- orelhas grandes saltam dos lados da cabeça
    [27] = row({31,'kssk'},{35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'},{61,'kssk'}),
    [28] = row({31,'kssk'},{35,'k'},{36,'ssss'},{40,'ee'},{42,'sssssssss'},{51,'ee'},{53,'sssssss'},{60,'k'},{61,'kssk'}),
    [29] = row({31,'kssk'},{35,'k'},{36,'ssss'},{40,'ee'},{42,'sssssssss'},{51,'ee'},{53,'sssssss'},{60,'k'},{61,'kssk'}),
    [30] = row({31,'kssk'},{35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'},{61,'kssk'}),
    [31] = row({32,'kkk'},{35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'},{61,'kkk'}),
    [32] = row({35,'k'},{36,'ssssssssss'},{46,'d'},{47,'sssssssssssss'},{60,'k'}),
    -- nariz reto comprido 'd'
    [33] = row({35,'k'},{36,'ssssssssss'},{46,'d'},{47,'sssssssssssss'},{60,'k'}),
    [34] = row({35,'k'},{36,'ssssssssss'},{46,'dd'},{48,'ssssssssssss'},{60,'k'}),
    [35] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [36] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    -- boca pequena 'dddd', barba raspada 'd' nas laterais do queixo
    [37] = row({35,'k'},{36,'ssssssss'},{44,'dddd'},{48,'ssssssssssss'},{60,'k'}),
    [38] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [39] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [40] = row({36,'k'},{37,'sdssssssssssssssssssssds'},{59,'k'}),
    [41] = row({36,'k'},{37,'sdssssssssssssssssssssds'},{59,'k'}),
    [42] = row({37,'k'},{38,'sdssssssssssssssssssds'},{58,'k'}),
    [43] = row({37,'k'},{38,'ssdssssssssssssssdss'},{58,'k'}),
    [44] = row({38,'k'},{39,'ssdssssssssssssdss'},{57,'k'}),
    [45] = row({39,'k'},{40,'ssssssssssssssss'},{56,'k'}),
    [46] = row({40,'k'},{41,'ssssssssssssss'},{55,'k'}),
    [47] = row({41,'k'},{42,'ssssssssssss'},{54,'k'}),
    -- gola alta estreita 'z' sobe pelo pescoço (âncora)
    [48] = row({42,'kzzzzzzzzk'}),
    [49] = row({42,'kzzzzzzzzk'}),
    [50] = row({42,'kzzzzzzzzk'}),
    [51] = row({41,'kzzzzzzzzzk'}),
    [52] = row({41,'kzzttttttzzk'}),
    [53] = row({40,'kzzzttttttzzzk'}),
    -- sobrecasaca azul carvão estreita sobre túnica pérola aberta
    [54] = row({34,'kccccc'},{40,'kzztttttttttzzk'},{55,'ccccck'}),
    [55] = row({30,'kccccc'},{36,'kcck'},{40,'kttttttttttttk'},{54,'kcck'},{58,'ccccck'}),
    [56] = row({26,'kccccccc'},{34,'kcck'},{39,'ktttttttttttttttk'},{56,'kcck'},{60,'cccccck'}),
    [57] = row({23,'kcccccccc'},{32,'kcck'},{38,'ktttttttttttttttttk'},{57,'kcck'},{61,'cccccccck'}),
}
for r = 58, 95 do
    neutro[r] = row({22,'kccccccccc'},{32,'kcck'},{38,'kttttttttttttttttttk'},{58,'kcck'},{62,'ccccccccck'})
end
neutro[96] = row({22,'kkkkkkkkkk'},{32,'kkkk'},{38,'kkkkkkkkkkkkkkkkkkkk'},{58,'kkkk'},{62,'kkkkkkkkkk'})

--------------------------------------------------------------------------------
-- EXPRESSÕES
--------------------------------------------------------------------------------
-- [2] ternura (afeto breve ao ver Teca): testa relaxa — sobrancelhas
-- sobem 1px e suavizam, pálpebra 'd' semicerra, sorriso mínimo de
-- cantos erguidos. Cabeça inclina 1px.
local ternura = htilt(patch(neutro, {
    [24] = row({35,'k'},{36,'ssss'},{40,'ggg'},{43,'ssssssss'},{51,'ggg'},{54,'ssssss'},{60,'k'}),
    [25] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [28] = row({31,'kssk'},{35,'k'},{36,'ssss'},{40,'dd'},{42,'sssssssss'},{51,'dd'},{53,'sssssss'},{60,'k'},{61,'kssk'}),
    [37] = row({35,'k'},{36,'sssssss'},{43,'dddddd'},{49,'sssssssssss'},{60,'k'}),
    [36] = row({35,'k'},{36,'ssssssss'},{44,'d'},{45,'sss'},{48,'d'},{49,'sssssssssss'},{60,'k'}),
}), 1, 8, 47)

-- [3] concentração (exame paciente): sobrancelhas descem retas até a
-- linha dos olhos, olhar fixo, boca uma linha tensa 'ddd'. Cabeça
-- inclina -1px.
local concentracao = htilt(patch(neutro, {
    [25] = row({35,'k'},{36,'ssssssssssssssssssssssss'},{60,'k'}),
    [26] = row({35,'k'},{36,'ssss'},{40,'ggggg'},{45,'sssssss'},{52,'ggggg'},{57,'sss'},{60,'k'}),
    [27] = row({31,'kssk'},{35,'k'},{36,'ssss'},{40,'dd'},{42,'sssssssss'},{51,'dd'},{53,'sssssss'},{60,'k'},{61,'kssk'}),
    [37] = row({35,'k'},{36,'ssssssss'},{44,'ddd'},{47,'sssssssssssss'},{60,'k'}),
}), -1, 8, 47)

return {
    name = 'portrait_aurel',
    w = W, h = H,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},  -- castanha dourada
        S = {ramp = 'skin', step = 4, h = 12},
        d = {ramp = 'skin', step = 2, h = 10},  -- barba raspada/sombra
        e = {spec = 'ink', h = 12},
        g = {ramp = 'iron', step = 5, h = 11},  -- cabelo/sombrancelha grisalho
        G = {ramp = 'iron', step = 6, h = 12},
        z = {ramp = 'sea', step = 4, h = 9},    -- gola alta (âncora)
        c = {ramp = 'sea', step = 2, h = 7},    -- sobrecasaca azul carvão
        t = {ramp = 'plaster', step = 4, h = 6},-- túnica pérola
    },

    layers = {
        {name = 'busto', h = 4, albedo = {
            R(neutro),
            R(ternura),
            R(concentracao),
        }},
    },
}
