-- PORTRAIT — DORO, busto de diálogo 96x96, origin='topleft'.
-- Mesma pessoa do npc_doro_s.lua: pele parda escura (skin.2), cabeça
-- raspada com stubble 'd', BARBA CURTA PRATA 'g'/'G' com flecks 'h'
-- (a "cabeça clara de barba" lê contra a pele escura), rosto
-- retangular, nariz achatado 'ddd'/'ddddd', olhos pequenos 'ee' sob
-- sobrancelhas grisalhas 'g'. Ombros largos de camisa linho 'l' +
-- colete 'v', avental de lona 'a' com FAIXA DIAGONAL 'F' (âncora).
-- FRAMES = expressões (§3 do doc de personagens):
--   [1] neutro | [2] ternura (sorriso que ergue bochechas sem mostrar
--       os dentes, olhos semicerrados, sobrancelhas sobem) |
--   [3] raiva contida (sobrancelhas fecham para dentro, olhar apertado,
--       boca uma linha na barba, cabeça baixa 1px).

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
-- Sobrepõe t a partir da coluna col dentro de uma linha já montada.
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

--------------------------------------------------------------------------------
-- BUSTO NEUTRO
--------------------------------------------------------------------------------
local neutro = {
    -- crânio raspado: contorno de pele com stubble 'd', sem franja
    [10] = row({40,'kkkkkkkkkkkkkkk'}),
    [11] = row({36,'ksssssssssssssssssssssk'}),
    [12] = row({34,'kssssdssssssssssssdssssk'}),
    [13] = row({33,'ksssssdssssssssssdssssssk'}),
    [14] = row({33,'kssssssssssssssssssssssssk'}),
    [15] = row({33,'kssdsssssssssssssssssdssk'}),
    [16] = row({33,'kssssssssssssssssssssssssk'}),
    [17] = row({33,'kssssssssssssssssssssssssk'}),
    [18] = row({33,'kssssssssssssssssssssssssk'}),
    [19] = row({33,'kssssssssssssssssssssssssk'}),
    [20] = row({33,'kssssssssssssssssssssssssk'}),
    [21] = row({33,'kssssssssssssssssssssssssk'}),
    [22] = row({33,'kssssssssssssssssssssssssk'}),
    [23] = row({33,'kssssssssssssssssssssssssk'}),
    -- sobrancelhas grisalhas 'gggg' retas sobre olhos pequenos 'ee'
    [24] = row({33,'kssss'},{38,'gggg'},{42,'ssssssssss'},{52,'gggg'},{56,'ssssss'},{62,'k'}),
    [25] = row({33,'kssssssssssssssssssssssssk'}),
    [26] = row({33,'kssssss'},{40,'ee'},{42,'ssssssssss'},{52,'ee'},{54,'ssssssss'},{62,'k'}),
    [27] = row({33,'kssssss'},{40,'ee'},{42,'ssssssssss'},{52,'ee'},{54,'ssssssss'},{62,'k'}),
    [28] = row({33,'kssssssssssssssssssssssssk'}),
    -- nariz largo achatado
    [29] = row({33,'kssssssssss'},{44,'ddd'},{47,'sssssssssssssss'},{62,'k'}),
    [30] = row({33,'kssssssssss'},{44,'ddd'},{47,'sssssssssssssss'},{62,'k'}),
    [31] = row({33,'ksssssssss'},{43,'ddddd'},{48,'ssssssssssssss'},{62,'k'}),
    [32] = row({33,'kssssssssssssssssssssssssk'}),
    [33] = row({33,'kssssssssssssssssssssssssk'}),
    -- costeletas de barba prata descem pelas laterais
    [34] = row({33,'kss'},{36,'gg'},{38,'ssssssssssssssssssss'},{58,'gg'},{60,'ssk'}),
    [35] = row({33,'kss'},{36,'ggg'},{39,'ssssssssssssssssss'},{57,'ggg'},{60,'ssk'}),
    [36] = row({33,'ksg'},{36,'gggg'},{40,'ssssssssssssssss'},{56,'gggg'},{60,'sk'}),
    -- boca neutra dentro da moldura da barba
    [37] = row({33,'kgg'},{36,'gggg'},{40,'sssss'},{45,'ddddd'},{50,'sssss'},{55,'gggg'},{59,'sk'}),
    [38] = row({33,'kgg'},{36,'gggggg'},{42,'sss'},{45,'dddd'},{49,'sss'},{52,'gggggg'},{58,'sk'}),
    -- massa da barba prata: núcleo 'G', flecks 'h'
    [39] = row({34,'kggggggggggggggggggggggggk'}),
    [40] = row({34,'kggggggggGGGGGGGGggggggggk'}),
    [41] = row({34,'kggggggggGGGGGGGGggggggggk'}),
    [42] = row({34,'kggghgggggGGGGGGgggghgggk'}),
    [43] = row({34,'kggggggggggggggggggggggggk'}),
    [44] = row({34,'kggghgggggggggggggghggggk'}),
    [45] = row({34,'kggggggggggggggggggggggggk'}),
    [46] = row({35,'kggggggggggggggggggggggk'}),
    [47] = row({36,'kggggggggggggggggggggk'}),
    [48] = row({37,'kggggggggggggggggggk'}),
    [49] = row({38,'kggggggggggggggk'}),
    -- pescoço curto e largo
    [50] = row({42,'kssssssssk'}),
    [51] = row({42,'kssssssssk'}),
    [52] = row({42,'kdssssssdk'}),
    -- OMBROS LARGOS (âncora): camisa linho, colete castanho
    [53] = row({22,'kllllllllllllllllllllllllllllllllllllllllllllllllllllllk'}),
    [54] = row({18,'klllllllllllllllllllllllllllllllllllllllllllllllllllllllllllk'}),
    [55] = row({16,'kllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllk'}),
    [56] = row({14,'kllllllllllllll'},{29,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'},{67,'lllllllllllllllk'}),
    [57] = row({12,'kllllllllllllll'},{27,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'},{67,'llllllllllllllllk'}),
}
-- Tronco: avental de lona encerada 'a' com bordas 'A' cobrindo o
-- colete; laterais de camisa/colete continuam visíveis.
for r = 58, 92 do
    neutro[r] = row({12,'klllllllllllll'},{26,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'},{70,'llllllllllllllk'})
end
for r = 62, 91 do
    neutro[r] = paint(neutro[r], 27, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
end
neutro[62] = paint(neutro[62], 27, 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
neutro[93] = row({13,'kkkkkkkkkkkkkk'},{27,'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'},{68,'kkkkkkkkkkkkkkk'})
for r = 94, 96 do
    neutro[r] = row({12,'kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk'})
end
-- FAIXA DIAGONAL 'F' (âncora): do ombro esquerdo do sprite ao quadril
-- direito, ~1 coluna por linha descendo.
for i = 0, 32 do
    local r = 55 + i
    local c = 24 + math.floor(i * 1.15)
    if neutro[r] then neutro[r] = paint(neutro[r], c, 'FFFF') end
end

--------------------------------------------------------------------------------
-- EXPRESSÕES
--------------------------------------------------------------------------------
-- [2] ternura: sobrancelhas sobem 1px, pálpebra 'd' semicerra os olhos,
-- bochechas 'S' erguem e a boca abre um sorriso largo na moldura da
-- barba (sem dentes). Cabeça inclina 1px — o gigante se abaixa.
local ternura = htilt(patch(neutro, {
    [23] = row({33,'kssss'},{38,'gggg'},{42,'ssssssssss'},{52,'gggg'},{56,'ssssss'},{62,'k'}),
    [24] = row({33,'kssssssssssssssssssssssssk'}),
    [26] = row({33,'kssssss'},{40,'dd'},{42,'ssssssssss'},{52,'dd'},{54,'ssssssss'},{62,'k'}),
    [28] = row({33,'kssss'},{38,'SS'},{40,'ssssssssssssssss'},{56,'SS'},{58,'ssss'},{62,'k'}),
    [37] = row({33,'kgg'},{36,'ggg'},{39,'ss'},{41,'ddddd'},{46,'GGG'},{49,'dddd'},{53,'ss'},{55,'gggg'},{59,'sk'}),
    [38] = row({33,'kgg'},{36,'ggggggg'},{43,'ss'},{45,'dddd'},{49,'ss'},{51,'ggggggg'},{58,'sk'}),
}), 1, 10, 49)

-- [3] raiva contida: sobrancelhas caem para dentro (ponta interna desce
-- 1px + vinco 'dd' entre elas), pálpebra aperta o olhar, boca vira uma
-- linha curta 'dddd' fechada na barba. Cabeça desce 1px — ombros à
-- frente, sem teatro.
local raiva = vshift(patch(neutro, {
    [23] = row({33,'kssssssssssssssssssssssssk'}),
    [24] = row({33,'kssss'},{38,'ggg'},{41,'sssss'},{46,'dd'},{48,'sssss'},{53,'ggg'},{56,'ssssss'},{62,'k'}),
    [25] = row({33,'ksssssss'},{41,'gg'},{43,'ssssssss'},{51,'gg'},{53,'sssssssss'},{62,'k'}),
    [26] = row({33,'kssssss'},{40,'dd'},{42,'ssssssssss'},{52,'dd'},{54,'ssssssss'},{62,'k'}),
    [27] = row({33,'kssssss'},{40,'ee'},{42,'ssssssssss'},{52,'ee'},{54,'ssssssss'},{62,'k'}),
    [37] = row({33,'kgg'},{36,'gggg'},{40,'sssss'},{45,'dddd'},{49,'ssssss'},{55,'gggg'},{59,'sk'}),
}), 1, 10, 49)

return {
    name = 'portrait_doro',
    w = W, h = H,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 2, h = 11},   -- pele parda escura
        S = {ramp = 'skin', step = 3, h = 12},   -- bochecha erguida
        d = {ramp = 'skin', step = 1, h = 10},   -- stubble/sombra/vinco
        e = {spec = 'ink', h = 12},              -- olho
        g = {ramp = 'plaster', step = 5, h = 11},-- barba prata (âncora)
        G = {ramp = 'plaster', step = 6, h = 12},
        h = {ramp = 'hair', step = 2, h = 11},   -- flecks pretos
        l = {ramp = 'plaster', step = 3, h = 6}, -- camisa linho cinza
        v = {ramp = 'earth', step = 3, h = 6},   -- colete castanho
        a = {ramp = 'clothWarm', step = 3, h = 6},-- avental de lona
        A = {ramp = 'clothWarm', step = 2, h = 6},
        F = {ramp = 'bone', step = 4, h = 8},    -- faixa diagonal
    },

    layers = {
        {name = 'busto', h = 4, albedo = {
            R(neutro),
            R(ternura),
            R(raiva),
        }},
    },
}
