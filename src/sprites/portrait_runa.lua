-- PORTRAIT — RUNA, busto de diálogo 96x96, origin='topleft'.
-- Mesma pessoa do boss_runa_s.lua: pele bege rosada 's' com sardas 'd'
-- nas maçãs, face QUADRADA (mandíbula reta 'd'), olhos verde-
-- acinzentado 'y', nariz curto de ponte alta. Cabelo ruivo 'a'/'A' de
-- franja aparada irregular; a TRANÇA baixa cai no ombro esquerdo do
-- sprite sobre o MANTO TRIANGULAR 'm' de forro palha 'l' (âncoras).
-- Camisa carvão 'i' e proteção de couro 'L' aparecem no peito.
-- FRAMES = expressões (§9 do doc de personagens):
--   [1] neutro | [2] firmeza (determinação de vigia: sobrancelha reta
--       baixa, olhar fixo, boca firme 'dd') | [3] divida (a pergunta
--       antes da certeza: sobrancelha esquerda sobe, olhos medem à
--       direita, boca entreaberta 'dk', cabeça inclina -1px).

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
    -- cabelo ruivo 'a' com luz 'A'; franja aparada sem linha perfeita
    [10] = row({40,'kkkkkkkkkkkkkk'}),
    [11] = row({37,'kaaaaaaaaaaaaaak'}),
    [12] = row({35,'kaaaaaaaaaaaaaaaak'}),
    [13] = row({34,'kaaAaaaaaaaaAaAAak'}),
    [14] = row({33,'kaaaaaaaaaaaaaaaaaaak'}),
    -- franja irregular: dentes de cabelo sobre a testa
    [15] = row({33,'kaaas'},{37,'aass'},{41,'aasss'},{45,'aass'},{49,'aasss'},{53,'aaaaak'}),
    [16] = row({33,'kAassssssssssssssssssssssaak'}),
    [17] = row({33,'kAsssssssssssssssssssssssaak'}),
    [18] = row({33,'kasssssssssssssssssssssssak'}),
    [19] = row({33,'kasssssssssssssssssssssssak'}),
    [20] = row({33,'kasssssssssssssssssssssssak'}),
    [21] = row({33,'kasssssssssssssssssssssssak'}),
    [22] = row({33,'kasssssssssssssssssssssssak'}),
    -- sobrancelhas ruivas 'aa' retas sobre olhos 'yy'
    [23] = row({33,'kass'},{36,'ssss'},{40,'aaaa'},{44,'sssssss'},{51,'aaaa'},{55,'sss'},{58,'ak'}),
    [24] = row({33,'kasssssssssssssssssssssssak'}),
    [25] = row({33,'kassss'},{39,'yy'},{41,'sssssssssss'},{52,'yy'},{54,'ssss'},{58,'ak'}),
    [26] = row({33,'kassss'},{39,'yy'},{41,'sssssssssss'},{52,'yy'},{54,'ssss'},{58,'ak'}),
    [27] = row({33,'kasssssssssssssssssssssssak'}),
    -- sardas 'd' esparsas nas maçãs
    [28] = row({33,'kass'},{37,'d'},{38,'ss'},{40,'d'},{41,'sssssssssss'},{52,'d'},{53,'ss'},{55,'d'},{56,'ssak'}),
    [29] = row({33,'kass'},{37,'s'},{38,'d'},{39,'sss'},{42,'d'},{43,'sssssssss'},{52,'s'},{53,'d'},{54,'sss'},{57,'sak'}),
    -- nariz curto de ponte alta
    [30] = row({33,'kassssssssss'},{45,'d'},{46,'ssssssssssss'},{58,'ak'}),
    [31] = row({33,'kassssssssss'},{45,'dd'},{47,'sssssssssss'},{58,'ak'}),
    [32] = row({33,'kasssssssssssssssssssssssak'}),
    [33] = row({33,'kasssssssssssssssssssssssak'}),
    -- boca neutra 'dddd'
    [34] = row({33,'kasssssssss'},{44,'dddd'},{48,'ssssssssss'},{58,'ak'}),
    [35] = row({33,'kasssssssssssssssssssssssak'}),
    -- FACE QUADRADA: mandíbula reta 'd' em vez de afunilar cedo
    [36] = row({33,'kadsssssssssssssssssssssdaak'}),
    [37] = row({33,'kadsssssssssssssssssssssdaak'}),
    [38] = row({34,'kdsssssssssssssssssssssdk'}),
    [39] = row({34,'kdsssssssssssssssssssssdk'}),
    [40] = row({35,'kdsssssssssssssssssssdk'}),
    [41] = row({35,'ksssssssssssssssssssssk'}),
    [42] = row({36,'kssssssssssssssssssssk'}),
    [43] = row({37,'kssssssssssssssssssk'}),
    [44] = row({39,'kssssssssssssssk'}),
    -- pescoço + trança 'a' despontando atrás do ombro direito do sprite
    [45] = row({39,'kssssssssssssssk'},{62,'kaak'}),
    [46] = row({40,'kssssssssssssk'},{62,'kaak'}),
    [47] = row({40,'kdssssssssssdk'},{62,'kAAk'}),
    [48] = row({41,'kssssssssssk'},{62,'kaak'}),
    [49] = row({41,'kssssssssssk'},{62,'kaak'}),
    -- gola da camisa carvão 'i'
    [50] = row({40,'kiiiiiiiiiiiik'},{62,'kaak'}),
    [51] = row({39,'kiiiiiiiiiiiiiik'},{62,'kaak'}),
    -- MANTO TRIANGULAR 'm' largo nos ombros, fechando em ponta no
    -- esterno; 'M' luz, forro palha 'l' na borda do V
    [52] = row({26,'kmm'},{29,'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'},{67,'mmmk'},{62,'kaak'}),
    [53] = row({22,'kmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmk'},{62,'kaak'}),
    [54] = row({20,'kmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmk'},{62,'kAAk'}),
    [55] = row({18,'kmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmk'},{62,'kaak'}),
    [56] = row({18,'kmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmk'},{62,'kaak'}),
    -- couro 'L' do peito aparece no V do manto
    [57] = row({18,'kmmmmmmmmmmmmmmmmmm'},{37,'kllk'},{41,'LLLLLLLLLLLL'},{53,'kllk'},{57,'mmmmmmmmmmmmmmmmmmk'},{62,'kaak'}),
    [58] = row({18,'kmmmmmmmmmmmmmmmmmm'},{37,'kllk'},{41,'LLLLLLLLLLLL'},{53,'kllk'},{57,'mmmmmmmmmmmmmmmmmmk'},{62,'kaak'}),
    [59] = row({18,'kmmmmmmmmmmmmmmmmmm'},{37,'kllk'},{41,'LLLLLLLLLLLL'},{53,'kllk'},{57,'mmmmmmmmmmmmmmmmmmk'},{62,'kAAk'}),
    [60] = row({18,'kmmmmmmmmmmmmmmmmmmm'},{38,'kl'},{40,'LLLLLLLLLLLLLL'},{54,'lk'},{56,'mmmmmmmmmmmmmmmmmmmk'},{63,'kak'}),
    [61] = row({18,'kmmmmmmmmmmmmmmmmmmm'},{38,'kl'},{40,'LLLLLLLLLLLLLL'},{54,'lk'},{56,'mmmmmmmmmmmmmmmmmmmk'},{63,'kak'}),
    [62] = row({18,'kmmmmmmmmmmmmmmmmmmmm'},{39,'k'},{40,'LLLLLLLLLLLLLL'},{54,'k'},{55,'mmmmmmmmmmmmmmmmmmmmk'},{63,'kak'}),
    [63] = row({18,'kmmmmmmmmmmmmmmmmmmmm'},{39,'k'},{40,'LLLLLLLLLLLLLL'},{54,'k'},{55,'mmmmmmmmmmmmmmmmmmmmk'},{63,'kxk'}),
    [64] = row({18,'kmmmmmmmmmmmmmmmmmmmmmm'},{40,'kLLLLLLLLLLLLk'},{54,'mmmmmmmmmmmmmmmmmmmmmmmk'},{63,'kk'}),
    [65] = row({18,'kmmmmmmmmmmmmmmmmmmmmmm'},{40,'kLLLLLLLLLLLLk'},{54,'mmmmmmmmmmmmmmmmmmmmmmmk'}),
}
for r = 66, 95 do
    neutro[r] = row({18,'kmmmmmmmmmmmmmmmmmmmmmm'},{40,'kLLLLLLLLLLLLk'},{54,'mmmmmmmmmmmmmmmmmmmmmmmk'})
end
neutro[96] = row({18,'kkkkkkkkkkkkkkkkkkkkkkk'},{40,'kkkkkkkkkkkkkk'},{54,'kkkkkkkkkkkkkkkkkkkkkkk'})

--------------------------------------------------------------------------------
-- EXPRESSÕES
--------------------------------------------------------------------------------
-- [2] firmeza (determinação ao deixar passar): sobrancelhas retas
-- descem 1px, olhar 'yy' fixo, boca firme 'dddd', mandíbula set 'd'.
-- Cabeça reta — a vigia não balança.
local firmeza = patch(neutro, {
    [23] = row({33,'kasssssssssssssssssssssssak'}),
    [24] = row({33,'kass'},{36,'ssss'},{40,'aaaa'},{44,'sssssss'},{51,'aaaa'},{55,'sss'},{58,'ak'}),
    [34] = row({33,'kasssssssss'},{44,'ddddd'},{49,'sssssssss'},{58,'ak'}),
    [35] = row({33,'kasssssssss'},{44,'d'},{45,'sssssssssssss'},{58,'ak'}),
})

-- [3] dúvida ("eu ouvi outra história. Não vi acontecer."): sobrancelha
-- esquerda sobe 1px, olhos 'yy' medem 2px à direita, boca entreaberta
-- 'dk'. Cabeça inclina -1px.
local divida = htilt(patch(neutro, {
    [22] = row({33,'kass'},{36,'ssss'},{40,'aaaa'},{44,'ssssssssssssss'},{58,'ak'}),
    [23] = row({33,'kass'},{36,'sssssssssssssss'},{51,'aaaa'},{55,'sss'},{58,'ak'}),
    [25] = row({33,'kassss'},{39,'ss'},{41,'yy'},{43,'sssssssssss'},{54,'yy'},{56,'ss'},{58,'ak'}),
    [26] = row({33,'kassss'},{39,'ss'},{41,'yy'},{43,'sssssssssss'},{54,'yy'},{56,'ss'},{58,'ak'}),
    [34] = row({33,'kasssssssss'},{44,'ddd'},{47,'k'},{48,'ssssssssss'},{58,'ak'}),
}), -1, 10, 47)

return {
    name = 'portrait_runa',
    w = W, h = H,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 4},
        s = {ramp = 'skin', step = 4, h = 11},   -- bege rosada
        S = {ramp = 'skin', step = 5, h = 12},
        d = {ramp = 'skin', step = 3, h = 10},   -- sardas/mandíbula
        y = {ramp = 'moss', step = 3, h = 11},   -- olhos verde-acinzentado
        a = {ramp = 'rust', step = 4, h = 11},   -- cabelo/trança ruiva
        A = {ramp = 'rust', step = 5, h = 12},
        x = {ramp = 'earth', step = 2, h = 6},   -- tira de couro da trança
        m = {ramp = 'moss', step = 3, h = 7},    -- manto triangular (âncora)
        M = {ramp = 'moss', step = 4, h = 8},
        l = {ramp = 'bone', step = 4, h = 6},    -- forro palha
        i = {ramp = 'iron', step = 3, h = 6},    -- camisa carvão
        L = {ramp = 'wood', step = 4, h = 7},    -- proteção de couro
    },

    layers = {
        {name = 'busto', h = 4, albedo = {
            R(neutro),
            R(firmeza),
            R(divida),
        }},
    },
}
