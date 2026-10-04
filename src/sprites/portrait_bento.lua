-- PORTRAIT — BENTO, busto de diálogo 96x96, origin='topleft'.
-- Mesma pessoa do npc_bento_s.lua: cabeça REDONDA e larga, cabelo
-- castanho acinzentado crespo 'h' sob a FAIXA DE PANO CLARA 'F'
-- horizontal na testa (âncora), rosto redondo, nariz largo 'ddd',
-- bigode fino em arco 'u', rugas 'd'. Massa redonda de camisa musgo
-- 'g' + colete vinho 'v'; avental cru QUADRADO 'a'/'A' (âncora) e a
-- toalha 'T'/'t' listrada caída no ombro esquerdo do sprite (âncora).
-- FRAMES = expressões (§4 do doc de personagens):
--   [1] neutro | [2] humor (alegria de acolhimento: olhos fecham em
--       arco, bochechas 'S' erguem, sorriso aberto 'dkkkd') |
--   [3] raiva (contrariedade contida: olhar apertado sob a faixa, boca
--       quieta 'dd' fina, cabeça desce 1px).

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
local function paint(s, col, t)
    s = L(s or '')
    return s:sub(1, col - 1) .. t .. s:sub(col + #t)
end
local function patch(base, repl)
    local t = {}
    for r, s in pairs(base) do t[r] = s end
    for r, s in pairs(repl) do t[r] = s end
    return t
end
local function vshift(map, dy, rmin, rmax)
    local t = {}
    for r, s in pairs(map) do
        if not (r >= rmin and r <= rmax) then t[r] = s end
    end
    for r, s in pairs(map) do
        if r >= rmin and r <= rmax then t[r + dy] = s end
    end
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
-- BUSTO NEUTRO — a cabeça mais larga e baixa do elenco
--------------------------------------------------------------------------------
local neutro = {
    -- cabelo crespo curto saindo por cima da faixa
    [9]  = row({38,'kkkkkkkkkkkkkkkkkkkk'}),
    [10] = row({34,'khhhhhhhhhhhhhhhhhhhhhhk'}),
    [11] = row({32,'khhhhhhhhhhhhhhhhhhhhhhhhhk'}),
    [12] = row({31,'khhhhhhhhhhhhhhhhhhhhhhhhhhk'}),
    [13] = row({31,'khhhhhhhhhhhhhhhhhhhhhhhhhhk'}),
    -- FAIXA DE PANO CLARA horizontal na testa (âncora)
    [14] = row({30,'kFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFk'}),
    [15] = row({30,'kFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFk'}),
    -- rosto redondo; rugas radiais 'd' nas têmporas
    [16] = row({30,'khsssssssssssssssssssssssssssshk'}),
    [17] = row({30,'khsssssssssssssssssssssssssssshk'}),
    [18] = row({30,'khssdssssssssssssssssssssdssshk'}),
    [19] = row({30,'khsssssssssssssssssssssssssssshk'}),
    [20] = row({30,'khsssssssssssssssssssssssssssshk'}),
    -- olhos pequenos 'ee'
    [21] = row({30,'khssssss'},{38,'ee'},{40,'ssssssssssss'},{52,'ee'},{54,'ssssss'},{60,'shk'}),
    [22] = row({30,'khssssss'},{38,'ee'},{40,'ssssssssssss'},{52,'ee'},{54,'ssssss'},{60,'shk'}),
    [23] = row({30,'khsssssssssssssssssssssssssssshk'}),
    -- nariz largo 'ddd'
    [24] = row({30,'khssssssssss'},{42,'ddd'},{45,'ssssssssssssss'},{59,'hk'}),
    [25] = row({30,'khssssssssss'},{42,'ddd'},{45,'ssssssssssssss'},{59,'hk'}),
    [26] = row({30,'khsssssssssssssssssssssssssssshk'}),
    -- bigode fino em arco 'u': pontas sobem, centro desce sobre a boca
    [27] = row({30,'khsssssssss'},{41,'uuu'},{44,'ssssss'},{50,'uuu'},{53,'ssssss'},{59,'hk'}),
    [28] = row({30,'khssssssssss'},{42,'uuuuuuuuuu'},{52,'sssssss'},{59,'hk'}),
    -- boca quieta 'dd' sob o bigode
    [29] = row({30,'khssssssssss'},{42,'sss'},{45,'dddd'},{49,'ssssssssss'},{59,'hk'}),
    [30] = row({30,'khsssssssssssssssssssssssssssshk'}),
    [31] = row({30,'khsssssssssssssssssssssssssssshk'}),
    [32] = row({31,'khssssssssssssssssssssssssssshk'}),
    [33] = row({31,'khssssssssssssssssssssssssssshk'}),
    -- queixo redondo, papada curta
    [34] = row({32,'khsssssssssssssssssssssssssshk'}),
    [35] = row({33,'khssssssssssssssssssssssshk'}),
    [36] = row({34,'khssssssssssssssssssssshk'}),
    [37] = row({35,'ksssssssssssssssssssssk'}),
    [38] = row({36,'kssdssssssssssssssdssk'}),
    [39] = row({38,'kssssssssssssssssssk'}),
    [40] = row({40,'kssssssssssssssk'}),
    -- pescoço curto afogado na massa
    [41] = row({40,'kssssssssssssssk'}),
    [42] = row({40,'kdssssssssssssdk'}),
    -- MASSA REDONDA: camisa musgo 'g' abre quase na largura toda
    [43] = row({24,'kggggggggggggggggggggggggggggggggggggggggggggggggggk'}),
    [44] = row({18,'kggggggggggggggggggggggggggggggggggggggggggggggggggggggggggk'}),
    [45] = row({15,'kgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggk'}),
    -- colete vinho 'v' aberto no peito sob o avental
    [46] = row({14,'kggggggg'},{22,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'},{75,'gggggggk'}),
    [47] = row({13,'kggggggg'},{21,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'},{77,'ggggggk'}),
}
for r = 48, 92 do
    neutro[r] = row({13,'kgggggg'},{20,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'},{76,'gggggggk'})
end
-- avental cru QUADRADO 'a' com borda 'A' cobrindo a barriga em bloco
for r = 54, 90 do
    neutro[r] = paint(neutro[r], 30, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
end
neutro[54] = paint(neutro[54], 30, 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
neutro[91] = paint(neutro[91], 30, 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
for r = 93, 96 do
    neutro[r] = row({13,'kkkkkkk'},{20,'kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk'},{76,'kkkkkkk'})
end
-- toalha 'T'/'t' listrada caída do ombro esquerdo do sprite (âncora)
for r = 45, 78 do
    local s = (r % 4 == 0) and 'ttt' or 'TTT'
    neutro[r] = paint(neutro[r], 16, s)
end
neutro[79] = paint(neutro[79], 16, 'kkk')

--------------------------------------------------------------------------------
-- EXPRESSÕES
--------------------------------------------------------------------------------
-- [2] humor (alegria de acolhimento): olhos fecham em arco feliz 'ddd',
-- bochechas 'S' erguem nas têmporas, bigode sobe 1px e a boca abre um
-- sorriso 'dkkkd'. Cabeça inclina 1px.
local humor = htilt(patch(neutro, {
    [20] = row({30,'khssssss'},{38,'ddd'},{41,'ssssssssssss'},{53,'ddd'},{56,'ssss'},{60,'shk'}),
    [21] = row({30,'khsssssssssssssssssssssssssssshk'}),
    [22] = row({30,'khssss'},{36,'SS'},{38,'ssssssssssssss'},{52,'SS'},{54,'ssssss'},{60,'shk'}),
    [27] = row({30,'khssssssss'},{40,'uuu'},{43,'ssssss'},{49,'uuu'},{52,'sssssss'},{59,'hk'}),
    [28] = row({30,'khssssssssss'},{42,'uuuuuuuuuu'},{52,'sssssss'},{59,'hk'}),
    [29] = row({30,'khssssssssss'},{42,'s'},{43,'dddddddd'},{51,'ssssssss'},{59,'hk'}),
    [30] = row({30,'khssssssssss'},{42,'ss'},{44,'dkkkkd'},{49,'ssssssssss'},{59,'hk'}),
}), 1, 9, 41)

-- [3] raiva (contrariedade contida): sombra 'hh' carrega sob a faixa,
-- pálpebra 'd' aperta o olhar, boca vira linha fina 'dd'. Cabeça desce
-- 1px — o corpo grande se aproxima sem levantar a voz.
local raiva = vshift(patch(neutro, {
    [18] = row({30,'khssdssssss'},{41,'hh'},{43,'ssssssss'},{51,'hh'},{53,'ssssdssshk'}),
    [21] = row({30,'khssssss'},{38,'dd'},{40,'ssssssssssss'},{52,'dd'},{54,'ssssss'},{60,'shk'}),
    [22] = row({30,'khssssss'},{38,'ee'},{40,'ssssssssssss'},{52,'ee'},{54,'ssssss'},{60,'shk'}),
    [29] = row({30,'khssssssssss'},{42,'sss'},{45,'dd'},{47,'ssssssssssss'},{59,'hk'}),
}), 1, 9, 41)

return {
    name = 'portrait_bento',
    w = W, h = H,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 3, h = 11},   -- oliva média
        S = {ramp = 'skin', step = 4, h = 12},   -- bochecha erguida
        d = {ramp = 'skin', step = 2, h = 10},   -- rugas/sombra
        e = {spec = 'ink', h = 12},
        h = {ramp = 'hair', step = 3, h = 11},   -- cabelo acinzentado
        F = {ramp = 'bone', step = 5, h = 12},   -- faixa de pano (âncora)
        u = {ramp = 'hair', step = 2, h = 11},   -- bigode fino
        g = {ramp = 'moss', step = 3, h = 6},    -- camisa verde musgo
        v = {ramp = 'clothWarm', step = 2, h = 6},-- colete vinho gasto
        a = {ramp = 'bone', step = 4, h = 7},    -- avental cru quadrado
        A = {ramp = 'bone', step = 3, h = 7},
        T = {ramp = 'plaster', step = 6, h = 7}, -- toalha listrada
        t = {ramp = 'plaster', step = 4, h = 7},
    },

    layers = {
        {name = 'busto', h = 4, albedo = {
            R(neutro),
            R(humor),
            R(raiva),
        }},
    },
}
