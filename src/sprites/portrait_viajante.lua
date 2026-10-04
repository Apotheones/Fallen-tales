-- PORTRAIT — O VIAJANTE, busto de diálogo 96x96, origin='topleft'.
-- Mesma pessoa do viajante.lua (idle SUL): cabelo preto ondulado amarrado
-- baixo, barba curta irregular de stubble, casaco earth.3 aberto à
-- frente sobre camisa de linho 'l' + colete moss 'v', remendo ocre 'm'
-- no ombro esquerdo do sprite e o pingente jade (único emissivo do
-- elenco, ei 0.8).
-- FRAMES = expressões (docs/PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md §1):
--   [1] neutro | [2] concentracao (boca entreaberta, sobrancelhas
--       convergindo, cabeça inclina 1px) | [3] humor (sobrancelha
--       esquerda sobe, sorriso só num canto, cabeça inclina -1px).
-- Expressão = sobrancelha + olho + boca + ângulo de cabeça: a massa de
-- cabelo, a barba e o torso são os mesmos nos três frames.

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
-- Segmento {coluna_inicial, conteúdo}; segmentos posteriores sobrescrevem.
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
-- Inclinação da cabeça: pivô no queixo (rbot), o topo desloca dx px.
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
-- BUSTO NEUTRO: coroa de cabelo, rosto limpo (olhos 'ee' separados),
-- nariz amplo 'dd', boca 'ddddd', stubble na mandíbula, pescoço, casaco
-- aberto com remendo 'm' à esquerda do sprite.
--------------------------------------------------------------------------------
local neutro = {
    -- coroa ondulada de cabelo preto
    [9]  = row({40,'kkkkkkkkkkkkkkkk'}),
    [10] = row({37,'khhhhhhhhhhhhhhhhhhhk'}),
    [11] = row({34,'khhhhhhhhhhhhhhhhhhhhhhk'}),
    [12] = row({33,'khhhhhHhhhhhhhhhhHhhhhhk'}),
    [13] = row({32,'khhhhhhhhhhhhhhhhhhhhhhhhk'}),
    [14] = row({32,'khhhhhhhhhhhhhhhhhhhhhhhhk'}),
    -- linha do cabelo irregular sobre a testa
    [15] = row({32,'khh'},{35,'sssssssssssssssssssssss'},{57,'shhk'}),
    [16] = row({32,'khh'},{35,'ssssssssssssssssssssssss'},{59,'hhk'}),
    [17] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [18] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [19] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [20] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [21] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [22] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [23] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    -- sobrancelhas retas 'uuuuu' (r24) sobre olhos 'ee' 2x2 (r26-27)
    [24] = row({32,'khh'},{35,'ssss'},{39,'uuuuu'},{44,'ssssssss'},{52,'uuuuu'},{57,'sss'},{60,'hhk'}),
    [25] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [26] = row({32,'khh'},{35,'sssss'},{40,'ee'},{42,'ssssssssssss'},{54,'ee'},{56,'ssss'},{60,'hhk'}),
    [27] = row({32,'khh'},{35,'sssss'},{40,'ee'},{42,'ssssssssssss'},{54,'ee'},{56,'ssss'},{60,'hhk'}),
    [28] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    [29] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    -- nariz amplo de ponta baixa 'dd'/'ddd'
    [30] = row({32,'khh'},{35,'sssssssssss'},{46,'dd'},{48,'ssssssssssss'},{60,'hhk'}),
    [31] = row({32,'khh'},{35,'sssssssssss'},{46,'dd'},{48,'ssssssssssss'},{60,'hhk'}),
    [32] = row({32,'khh'},{35,'ssssssssss'},{45,'ddd'},{48,'ssssssssssss'},{60,'hhk'}),
    [33] = row({32,'khh'},{35,'sssssssssssssssssssssssss'},{60,'hhk'}),
    -- boca neutra 'ddddd' sob o nariz, sobre a linha do stubble
    [34] = row({32,'khh'},{35,'ssssssss'},{43,'ddddd'},{48,'ssssssssssss'},{60,'hhk'}),
    [35] = row({32,'khh'},{35,'s'},{36,'h'},{37,'sssss'},{42,'h'},{43,'sssssss'},{50,'ss'},{52,'h'},{53,'sssss'},{58,'h'},{59,'s'},{60,'hhk'}),
    -- barba curta irregular: stubble 'h'/'d' subindo pela mandíbula
    [36] = row({32,'khh'},{35,'sh'},{37,'sshssssssssssssshs'},{55,'hs'},{57,'hs'},{59,'s'},{60,'hhk'}),
    [37] = row({32,'khh'},{35,'hh'},{37,'shssssssssssssssshs'},{56,'hh'},{58,'s'},{59,'s'},{60,'hhk'}),
    [38] = row({32,'khh'},{35,'hdh'},{38,'shssssssssssssshs'},{56,'hdh'},{59,'s'},{60,'hhk'}),
    [39] = row({32,'khh'},{35,'hdh'},{38,'ssshsssssssshsss'},{54,'hdh'},{57,'s'},{58,'s'},{59,'s'},{60,'hhk'}),
    [40] = row({32,'khh'},{35,'hddh'},{39,'ssshsssssshsss'},{53,'hddh'},{57,'s'},{58,'s'},{59,'s'},{60,'hhk'}),
    -- mandíbula e queixo afunilando para o pescoço
    [41] = row({32,'khh'},{35,'hdh'},{38,'ssssssssssssssss'},{54,'hdh'},{57,'shhk'}),
    [42] = row({33,'khh'},{36,'hdd'},{39,'ssssssssssss'},{51,'ddh'},{54,'hhk'}),
    [43] = row({34,'khh'},{37,'hd'},{39,'ssssssssss'},{49,'dh'},{51,'hhk'}),
    [44] = row({35,'kh'},{37,'hds'},{40,'ssssssss'},{48,'sdh'},{51,'hk'}),
    -- massa do rabo baixo na nuca flanqueia o pescoço
    [45] = row({36,'khh'},{39,'hdss'},{43,'ssss'},{47,'ssdh'},{51,'hhk'}),
    [46] = row({37,'khhh'},{41,'ksssssssk'},{50,'hhhk'}),
    [47] = row({38,'khh'},{41,'ksssssssk'},{50,'hhk'}),
    [48] = row({39,'khh'},{41,'kdsssssdk'},{50,'hhk'}),
    [49] = row({40,'kh'},{42,'kssssssk'},{50,'hhk'}),
    -- gola da camisa de linho cru; a massa da nuca morre nas laterais
    [50] = row({36,'kh'},{38,'klllllllllllllllllk'},{57,'hk'}),
    [51] = row({36,'khh'},{39,'kllllllllllllllllllk'},{59,'hhk'}),
    -- casaco earth.3 aberto à frente: painéis 'c', sombra 'x' na abertura
    [52] = row({30,'kcccck'},{36,'kxx'},{39,'lllllllllllllllll'},{56,'xxk'},{59,'kcccck'}),
    [53] = row({26,'kccccc'},{32,'kcck'},{36,'kxx'},{39,'lllllllllllllllll'},{56,'xk'},{58,'kccccck'}),
    [54] = row({23,'kmmmm'},{28,'cccccck'},{35,'kxv'},{38,'vvvvvvvvvvvvvvvvvv'},{56,'vxk'},{59,'cccccck'},{65,'k'}),
    [55] = row({21,'kmmmmm'},{27,'cccccck'},{34,'kxvvvvvvvvvvvvvvvvvvvvxk'},{58,'cccccck'},{64,'k'}),
    [56] = row({19,'kmmmmm'},{25,'ccccccck'},{33,'kvvvvvvvvvvvvvvvvvvvvvvk'},{57,'ccccccck'},{65,'k'}),
    [57] = row({18,'kmmmm'},{23,'ccccccck'},{31,'kvvvvvvvvvvvvvvvvvvvvvvvvk'},{55,'cccccccccck'},{65,'k'}),
    [58] = row({17,'kmmmk'},{22,'ccccccck'},{30,'kvvvvvvvvvvvvvvvvvvvvvvvvvk'},{55,'cccccccccck'},{65,'k'}),
    -- daqui para baixo só alarga o tronco: casaco envolve o colete
    [59] = row({16,'kcccccccccccccc'},{31,'kvvvvvvvvvvvvvvvvvvvvvvvvk'},{57,'cccccccccccccck'}),
    [60] = row({15,'kcccccccccccccccc'},{32,'kvvvvvvvvvvvvvvvvvvvvvvvvk'},{58,'cccccccccccccccck'}),
}
-- Completa o tronco até a base do busto (mesmo casaco, mesmo colete).
for r = 61, 94 do
    neutro[r] = row({15,'kcccccccccccccccc'},{32,'kvvvvvvvvvvvvvvvvvvvvvvvvk'},{58,'cccccccccccccccck'})
end
neutro[95] = row({15,'kCCCCCCCCCCCCCCCC'},{32,'kvvvvvvvvvvvvvvvvvvvvvvvvk'},{58,'CCCCCCCCCCCCCCCCk'})
neutro[96] = row({15,'kkkkkkkkkkkkkkkkk'},{32,'kkkkkkkkkkkkkkkkkkkkkkkkkk'},{58,'kkkkkkkkkkkkkkkkk'})

--------------------------------------------------------------------------------
-- EXPRESSÕES
--------------------------------------------------------------------------------
-- [2] concentração: sobrancelhas convergem (ponta interna desce 1px),
-- pálpebra 'd' aperta o topo dos olhos, boca entreaberta 'ddkkdd',
-- cabeça inclina 1px para dentro da fala.
local concentracao = htilt(patch(neutro, {
    [24] = row({32,'khh'},{35,'ssss'},{39,'uuu'},{42,'ssssssssssss'},{54,'uuu'},{57,'sss'},{60,'hhk'}),
    [25] = row({32,'khh'},{35,'sssssss'},{42,'uu'},{44,'ssssssss'},{52,'uu'},{54,'ssssss'},{60,'hhk'}),
    [26] = row({32,'khh'},{35,'sssss'},{40,'dd'},{42,'ssssssssssss'},{54,'dd'},{56,'ssss'},{60,'hhk'}),
    [27] = row({32,'khh'},{35,'sssss'},{40,'ee'},{42,'ssssssssssss'},{54,'ee'},{56,'ssss'},{60,'hhk'}),
    [34] = row({32,'khh'},{35,'sssssss'},{42,'dddddd'},{48,'ssssssssssss'},{60,'hhk'}),
    [35] = row({32,'khh'},{35,'s'},{36,'h'},{37,'sssss'},{42,'ddkkdd'},{48,'ssssssssss'},{58,'h'},{59,'s'},{60,'hhk'}),
}), 1, 9, 48)

-- [3] humor: a sobrancelha esquerda sobe mais que a outra (âncora da
-- ficha: "uma sobrancelha sobe mais que a outra"), sorriso breve só no
-- canto direito da boca, cabeça inclina -1px.
local humor = htilt(patch(neutro, {
    [23] = row({32,'khh'},{35,'ssss'},{39,'uuuuu'},{44,'ssssssssssssssss'},{60,'hhk'}),
    [24] = row({32,'khh'},{35,'ssssssssssssssssss'},{53,'uuuuu'},{58,'ss'},{60,'hhk'}),
    [33] = row({32,'khh'},{35,'ssssssssssssss'},{49,'dd'},{51,'sssssssss'},{60,'hhk'}),
    [34] = row({32,'khh'},{35,'ssssssss'},{43,'dddddd'},{49,'sssssssssss'},{60,'hhk'}),
}), -1, 9, 48)

--------------------------------------------------------------------------------
-- GARB: cordão 'T' em V + pingente jade 'j' (emissivo ei 0.8) no peito.
--------------------------------------------------------------------------------
local pingente = {
    [51] = row({45,'T'},{51,'T'}),
    [52] = row({46,'T'},{50,'T'}),
    [53] = row({47,'T'},{49,'T'}),
    [54] = row({48,'T'}),
    [55] = row({46,'jjj'}),
    [56] = row({47,'j'}),
}
local emissivo = {
    [55] = row({46,'jjj'}),
    [56] = row({47,'j'}),
}

return {
    name = 'portrait_viajante',
    w = W, h = H,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 4},
        h = {ramp = 'hair', step = 1, h = 11},
        H = {ramp = 'hair', step = 4, h = 12},
        u = {ramp = 'hair', step = 2, h = 12},   -- sobrancelha
        s = {ramp = 'skin', step = 4, h = 11},
        S = {ramp = 'skin', step = 5, h = 12},
        d = {ramp = 'skin', step = 3, h = 10},
        e = {spec = 'ink', h = 12},              -- olho
        l = {ramp = 'plaster', step = 5, h = 6}, -- camisa de linho cru
        v = {ramp = 'moss', step = 3, h = 6},    -- colete de lã verde
        c = {ramp = 'earth', step = 3, h = 7},   -- casaco marrom frio
        x = {ramp = 'earth', step = 2, h = 6},
        C = {ramp = 'earth', step = 5, h = 7},   -- filete da bainha
        m = {ramp = 'gold', step = 5, h = 7},    -- remendo ocre (âncora)
        T = {ramp = 'earth', step = 2, h = 9},   -- cordão do pingente
        j = {spec = 'jade', h = 9, e = 'jadeLight', ei = 0.8},
    },

    layers = {
        {name = 'busto', h = 4, albedo = {
            R(neutro),
            R(concentracao),
            R(humor),
        }},
        {name = 'garb', h = 9,
            albedo = R(pingente),
            emissive = R(emissivo),
        },
    },
}
