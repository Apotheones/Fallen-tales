-- PORTRAIT — SABELA, busto de diálogo 96x96, origin='topleft'.
-- Mesma pessoa do npc_sabela_s.lua: pele negra de tom profundo
-- (skin.1, sombras em hair.1 'd'), rosto ANGULAR que afunila num
-- queixo estreito, olhos claros 'e' (bone.5 — contraste da ficha),
-- nariz estreito 'd', lábio inferior cheio 'dd', cicatriz pequena no
-- queixo 'd'. Tranças curtas 'h' puxadas para trás com FIOS BRANCOS
-- 'w' na linha frontal. Casaco petróleo 'c' aberto em DOIS PAINÉIS
-- sobre camisa de lã cru 'l' (a faixa clara central é a abertura).
-- FRAMES = expressões (§6 do doc de personagens):
--   [1] neutro | [2] concentracao (olhar fixo: sobrancelhas baixas
--       retas, boca comprimida) | [3] divida (desvio breve do olhar:
--       olhos escapam à direita, sobrancelha esquerda sobe, cabeça
--       inclina -1px).

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
    -- tranças curtas puxadas para trás: massa 'h' com textura 'H'
    [9]  = row({40,'kkkkkkkkkkkkkkk'}),
    [10] = row({37,'khhhhhhhhhhhhhhhk'}),
    [11] = row({34,'khhhhhhhhhhhhhhhhhhk'}),
    [12] = row({33,'khhHhhHhhHhhhHhhhHhhk'}),
    [13] = row({32,'khhhhhhhhhhhhhhhhhhhhhhk'}),
    -- fios brancos 'w' na linha frontal (âncora do rosto)
    [14] = row({32,'khh'},{35,'whhwhhhwhhhwhhhhhhh'},{54,'hh'},{56,'hhk'}),
    [15] = row({32,'khh'},{35,'ssssssssssssssssssssss'},{57,'hhk'}),
    [16] = row({32,'khh'},{35,'ssssssssssssssssssssssss'},{59,'hhk'}),
    [17] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [18] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [19] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [20] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [21] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [22] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    -- sobrancelhas 'hhh' escuras sobre olhos CLAROS 'ee' (contraste)
    [23] = row({33,'khh'},{36,'ssss'},{40,'hhh'},{43,'ssssssss'},{51,'hhh'},{54,'sss'},{57,'hhk'}),
    [24] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [25] = row({33,'khh'},{36,'ssss'},{40,'ee'},{42,'sssssssss'},{51,'ee'},{53,'ssss'},{57,'hhk'}),
    [26] = row({33,'khh'},{36,'ssss'},{40,'ee'},{42,'sssssssss'},{51,'ee'},{53,'ssss'},{57,'hhk'}),
    [27] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [28] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    -- nariz estreito 'd' de ponte alta
    [29] = row({33,'khh'},{36,'ssssssssss'},{46,'d'},{47,'ssssssssss'},{57,'hhk'}),
    [30] = row({33,'khh'},{36,'ssssssssss'},{46,'dd'},{48,'sssssssss'},{57,'hhk'}),
    [31] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [32] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    -- lábio inferior cheio: linha 'dd' + lábio 'SSS' claro embaixo
    [33] = row({33,'khh'},{36,'ssssssss'},{44,'dddd'},{48,'sssssssss'},{57,'hhk'}),
    [34] = row({33,'khh'},{36,'sssssssss'},{45,'SSS'},{48,'sssssssss'},{57,'hhk'}),
    [35] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [36] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    -- mandíbula angular afunilando; cicatriz 'd' no queixo
    [37] = row({34,'khh'},{37,'dssssssssssssssssssd'},{57,'hhk'}),
    [38] = row({34,'khh'},{37,'ssssssssssssssssssss'},{57,'hk'}),
    [39] = row({35,'kh'},{37,'dsssssssssssssssssd'},{56,'hk'}),
    [40] = row({36,'kh'},{38,'ssssssssssssssss'},{54,'hk'}),
    [41] = row({37,'k'},{38,'sssssssSsssssss'},{53,'k'}),
    [42] = row({38,'k'},{39,'ssssssSssssss'},{52,'k'}),
    [43] = row({39,'k'},{40,'ssssssssss'},{50,'k'}),
    [44] = row({40,'k'},{41,'ssssssss'},{49,'k'}),
    -- pescoço longo; gola da camisa cru
    [45] = row({41,'k'},{42,'ssssss'},{48,'k'}),
    [46] = row({41,'k'},{42,'ssssss'},{48,'k'}),
    [47] = row({41,'k'},{42,'sdssds'},{48,'k'}),
    [48] = row({40,'kll'},{43,'llllll'},{49,'llk'}),
    [49] = row({39,'kllllllllllllk'}),
    -- casaco petróleo aberto em dois painéis 'c', camisa 'l' no meio
    [50] = row({30,'kcck'},{34,'kck'},{37,'kllllllllllllllllllllk'},{59,'kck'},{62,'kcck'}),
    [51] = row({27,'kcccck'},{33,'kcck'},{37,'kllllllllllllllllllllk'},{59,'kcck'},{63,'ccccck'}),
    [52] = row({24,'kcccccck'},{32,'kccck'},{36,'klllllllllllllllllllllk'},{59,'kccck'},{63,'cccccck'}),
}
for r = 53, 95 do
    neutro[r] = row({22,'kcccccccck'},{32,'kccck'},{36,'klllllllllllllllllllllk'},{59,'kccck'},{63,'cccccccck'})
end
neutro[96] = row({22,'kkkkkkkkkk'},{32,'kkkkk'},{36,'kkkkkkkkkkkkkkkkkkkkkkk'},{59,'kkkkk'},{63,'kkkkkkkkk'})

--------------------------------------------------------------------------------
-- EXPRESSÕES
--------------------------------------------------------------------------------
-- [2] concentração (determinação de olhar fixo): sobrancelhas descem
-- retas até colar nos olhos, boca comprime numa linha 'ddd'. Cabeça
-- reta — ela não desvia.
local concentracao = patch(neutro, {
    [23] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
    [24] = row({33,'khh'},{36,'ssss'},{40,'hhh'},{43,'ssssssss'},{51,'hhh'},{54,'sss'},{57,'hhk'}),
    [25] = row({33,'khh'},{36,'ssss'},{40,'ee'},{42,'sssssssss'},{51,'ee'},{53,'ssss'},{57,'hhk'}),
    [33] = row({33,'khh'},{36,'ssssssss'},{44,'ddd'},{47,'ssssssssss'},{57,'hhk'}),
    [34] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
})

-- [3] dúvida (vergonha por desvio breve do olhar): olhos 'ee' fogem 2px
-- à direita, sobrancelha esquerda sobe 1px, boca murcha 'dd'. Cabeça
-- inclina -1px.
local divida = htilt(patch(neutro, {
    [22] = row({33,'khh'},{36,'ssss'},{40,'hhh'},{43,'sssssssssssss'},{57,'hhk'}),
    [23] = row({33,'khh'},{36,'sssssssssssssss'},{51,'hhh'},{54,'sss'},{57,'hhk'}),
    [25] = row({33,'khh'},{36,'ssss'},{40,'ss'},{42,'ee'},{44,'sssssssss'},{53,'ee'},{55,'ss'},{57,'hhk'}),
    [26] = row({33,'khh'},{36,'ssss'},{40,'ss'},{42,'ee'},{44,'sssssssss'},{53,'ee'},{55,'ss'},{57,'hhk'}),
    [33] = row({33,'khh'},{36,'ssssssss'},{44,'dd'},{46,'sssssssssss'},{57,'hhk'}),
    [34] = row({33,'khh'},{36,'sssssssssssssssssssssss'},{57,'hhk'}),
}), -1, 9, 47)

return {
    name = 'portrait_sabela',
    w = W, h = H,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 1, h = 11},   -- pele negra profunda
        S = {ramp = 'skin', step = 2, h = 12},
        d = {ramp = 'hair', step = 1, h = 10},   -- sombra/cicatriz
        e = {ramp = 'bone', step = 5, h = 12},   -- olhos claros (âncora)
        h = {ramp = 'hair', step = 1, h = 11},   -- tranças/sobrancelha
        H = {ramp = 'hair', step = 3, h = 12},
        w = {ramp = 'plaster', step = 6, h = 12},-- fios brancos (âncora)
        l = {ramp = 'bone', step = 4, h = 6},    -- camisa de lã cru
        c = {ramp = 'sea', step = 2, h = 7},     -- casaco petróleo
        r = {ramp = 'earth', step = 3, h = 8},   -- faixa castanha
    },

    layers = {
        {name = 'busto', h = 4, albedo = {
            R(neutro),
            R(concentracao),
            R(divida),
        }},
    },
}
