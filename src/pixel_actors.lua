local anim8 = require('vendor.anim8')
local P = require('src.pixel_world').palette
local Pal = require('src.palettes')
local PixelArt = require('src.pixel_art_v2')
local mineDuration = require('src.environment').constants.mineRecovery
local recoverDuration = require('src.enemies').dasher.recover
local Actors = {}; Actors.__index = Actors
local G = love.graphics
-- The body uses 32 pixels; four pixels on either side preserve extended weapons.
local frameW, frameH, originX, originY = 40, 48, 20, 44
local playerActions = {
    {'idle', 4, .23}, {'move', 6, .16 / 6}, {'charge', 3, .12}, {'ready', 2, .18},
    {'fire', 3, .2 / 3}, {'guard', 3, .15}, {'mine', 4, mineDuration / 4},
    {'hurt', 3, .06, 'pauseAtEnd'}, {'death', 5, .09, 'pauseAtEnd'}
}
local enemyActions = {
    {'idle', 4, .24}, {'move', 6, .04}, {'warn', 4, .12}, {'dash', 2, .04},
    {'recover', 3, .13}, {'hurt', 3, .06, 'pauseAtEnd'}, {'death', 5, .09, 'pauseAtEnd'}
}
-- 'work': a linha de ofício dos figurantes — Actors.state cede
-- 'idle'→'work' quando o npc traz `act` do def (sit/watch/hammer/...).
local npcActions = {{'idle', 4, .34}, {'work', 4, .34}}

-- Bayer 4x4 para transições dithered dentro dos sprites — a sombra não é
-- chapada, dissolve-se em pontos contra a luz.
local BAYER = {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}

-- All rasterization happens once. Integer rows keep diagonals crisp as well as edges.
local function painter(data, offsetX, offsetY)
    local function pixel(x, y, c)
        x, y = math.floor(x) + 4, math.floor(y)
        if x >= 0 and x < frameW and y >= 0 and y < frameH then
            data:setPixel(offsetX + x, offsetY + y, c[1], c[2], c[3], 1)
        end
    end
    local function rect(x, y, w, h, c)
        for py = y, y + h - 1 do for px = x, x + w - 1 do pixel(px, py, c) end end
    end
    local function line(x1, y1, x2, y2, c)
        local dx, dy = math.abs(x2 - x1), -math.abs(y2 - y1)
        local sx, sy = x1 < x2 and 1 or -1, y1 < y2 and 1 or -1
        local err = dx + dy
        while true do
            pixel(x1, y1, c)
            if x1 == x2 and y1 == y2 then break end
            local twice = err * 2
            if twice >= dy then err, x1 = err + dy, x1 + sx end
            if twice <= dx then err, y1 = err + dx, y1 + sy end
        end
    end
    local function poly(points, c)
        for y = 0, frameH - 1 do
            local cuts = {}
            for i = 1, #points, 2 do
                local j = i + 2 > #points and 1 or i + 2
                local x1, y1, x2, y2 = points[i], points[i + 1], points[j], points[j + 1]
                if y1 <= y and y2 > y or y2 <= y and y1 > y then
                    cuts[#cuts + 1] = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
                end
            end
            table.sort(cuts)
            for i = 1, #cuts - 1, 2 do
                for x = math.ceil(cuts[i]), math.ceil(cuts[i + 1]) - 1 do pixel(x, y, c) end
            end
        end
    end
    -- Faixa dithered dentro do sprite: transição de tom sem banda chapada.
    local function dith(x, y, w, h, c, t)
        for j = 0, h - 1 do for i = 0, w - 1 do
            if BAYER[(math.floor(y) + j) % 4 + 1][(math.floor(x) + i) % 4 + 1] / 16 < t then
                pixel(x + i, y + j, c)
            end
        end end
    end
    return rect, line, poly, dith
end

local function pose(action, frame)
    local bob, leg, cape, lean, squat = 0, 0, 0, 0, 0
    if action == 'idle' or action == 'ready' or action == 'guard' then
        bob, cape = frame % 3 == 0 and -1 or 0, frame % 2
    elseif action == 'move' then
        bob = ({1, -1, -2, -2, -1, 1})[frame]
        leg, cape, squat = ({0, 2, 3, -3, -2, 0})[frame], ({0, -1, -2, -2, 1, 1})[frame], frame == 1 and 2 or 0
    elseif action == 'charge' then lean, cape, squat = frame - 1, frame == 3 and -1 or 0, 1
    elseif action == 'fire' then lean, cape = ({-2, 1, 0})[frame], ({-2, -1, 0})[frame]
    elseif action == 'mine' then lean, squat, cape = ({-1, 2, 2, 0})[frame], ({1, 2, 1, 0})[frame], ({-1, -2, 0, 1})[frame]
    elseif action == 'hurt' then lean, squat, cape = ({-2, -1, 0})[frame], ({2, 1, 0})[frame], ({2, 1, 0})[frame]
    elseif action == 'death' then bob, squat, cape = (frame - 1) * 4, (frame - 1) * 2, frame - 1
    elseif action == 'warn' then squat, lean, cape = 1 + math.floor(frame / 2), frame - 1, -frame
    elseif action == 'dash' then bob, lean, leg, cape = -1, 3, frame == 1 and 3 or -3, -3
    elseif action == 'recover' then squat, lean = 3 - frame, 2 - frame end
    return bob, leg, cape, lean, squat
end

--====================================================================--
-- ITER8 — "procissão funerária": redesenho integral do elenco.
-- Gramática nova: cabeça ~30% da figura (zona de rosto 12-14px), corpo
-- articulado em ombros/tronco/quadril, massa própria por kind — nunca
-- o mesmo cone com adereço. Rosto aberto de osso em quase todos;
-- máscara/elmo legível onde a identidade pede. Direções de verdade:
-- sul mostra a cara, perfil mostra nariz/olho lateral, norte mostra
-- dorso/equipamento. Contrato intacto: frame 40x48, origem (20,44).
--====================================================================--

-- Rosto grande do retrato (>=15px de lado): definida após mixc — a
-- anatomia de diálogo (poço+íris+pálpebra, sobrancelha em arco, nariz
-- com dorso e base, boca de 3-4px por emoção) vive lá embaixo; aqui só
-- o encaminhamento por tamanho.
local facePortrait

-- Rosto de osso compartilhado: cavidade de tinta, pele em dois tons
-- (sombra embaixo, testa lavada pelo luar), olhos com iris por facção,
-- sobrancelha/boca por expressão. `expr`: stern/kind/worn/nil.
-- `skin`/`skinHi` opcionais trocam a base de osso por outra pele — a
-- mesma gramática de emoção serve ao rosto castanho do Viajante.
-- Cada emoção aciona >=2 canais visíveis a 1x: sobrancelha + boca + olho +
-- tom da face (pálida no medo, quente na raiva) — diferença lê no retrato
-- real, não no zoom. Faces grandes (retrato) sobem para facePortrait —
-- `opts` leva {skinLo, hair, lip, bare, shape} quando a ficha pede.
local function faceDraw(r, l, x, y, w, h, eye, expr, skin, skinHi, opts)
    if w >= 15 and h >= 18 then
        return facePortrait(r, l, x, y, w, h, {
            skin = skin or P.boneDark, skinHi = skinHi or P.bone,
            skinLo = opts and opts.skinLo,
            hair = opts and opts.hair or P.ink,
            eye = eye, lip = opts and opts.lip,
            bare = opts and opts.bare, shape = opts and opts.shape}, expr)
    end
    local face = expr == 'fear' and P.bone            -- pálido de susto
        or expr == 'anger' and P.rust               -- corado de fúria
        or skin or P.boneDark
    r(x, y, w, h, P.ink)
    r(x + 1, y + 1, w - 2, h - 1, face)
    r(x + 1, y + 1, w - 2, 1, expr == 'fear' and P.white or skinHi or P.bone)
    local eL, eR = x + 1, x + w - 3
    local mx = x + math.floor(w / 2)
    r(eL, y + 3, 2, 2, P.ink); r(eR, y + 3, 2, 2, P.ink)
    -- Íris: os estados com olhar próprio (fear/awe escancaram, shame desce)
    -- desenham a deles; o resto ganha o poço padrão da facção.
    if expr ~= 'fear' and expr ~= 'awe' and expr ~= 'shame' then
        r(eL, y + 3, 1, 1, eye); r(eR, y + 3, 1, 1, eye)
    end
    if expr == 'fear' or expr == 'awe' then
        -- Poço maior + íris miúda dentro: olho escancarado lê à distância.
        r(eL - 1, y + 1, 4, 4, P.bone); r(eR - 1, y + 1, 4, 4, P.bone)
        r(eL, y + 2, 2, 2, eye); r(eR, y + 2, 2, 2, eye)
    end
    if expr == 'anger' then
        -- Sobrancelha em V fechando por dentro + dentes de grade.
        l(eL - 1, y + 1, eL + 1, y + 4, P.ink); l(eR + 2, y + 1, eR, y + 4, P.ink)
        r(x + 1, y + h - 3, w - 2, 2, P.ink)
        for i = 0, 2 do r(x + 2 + i * math.floor(w / 3), y + h - 3, 1, 1, P.bone) end
        return
    end
    if expr == 'stern' then
        l(eL - 1, y + 2, eL + 2, y + 2, P.ink); l(eR - 1, y + 2, eR + 2, y + 2, P.ink)
        r(x + 1, y + h - 2, w - 2, 1, P.ink)
        return
    end
    if expr == 'joy' then
        -- Pálpebra em arco pra cima + sorriso aberto com dente.
        r(eL, y + 2, 2, 1, P.ink); r(eR, y + 2, 2, 1, P.ink)
        r(eL - 1, y + 3, 1, 1, P.ink); r(eR + 2, y + 3, 1, 1, P.ink)
        r(x + 1, y + h - 4, w - 2, 2, P.ink)
        r(x + 2, y + h - 3, w - 4, 1, P.bone)
        return
    end
    if expr == 'sad' then
        -- Sobrancelha subindo por dentro + cantos da boca caídos.
        l(eL - 1, y + 3, eL + 1, y + 1, P.ink); l(eR + 2, y + 3, eR, y + 1, P.ink)
        r(mx - 1, y + h - 3, 2, 1, P.ink)
        l(x + 1, y + h - 3, x + 1, y + h - 2, P.ink)
        l(x + w - 2, y + h - 3, x + w - 2, y + h - 2, P.ink)
        return
    end
    if expr == 'soft' then
        -- Meia-pálpebra + boca pequena aberta — guarda baixada.
        r(eL, y + 2, 2, 1, P.ink); r(eR, y + 2, 2, 1, P.ink)
        r(mx - 1, y + h - 3, 2, 1, P.bone)
        return
    end
    if expr == 'shame' then
        -- Íris no canto inferior + boca apertada — o olhar foge.
        r(eL, y + 4, 1, 1, eye); r(eR, y + 4, 1, 1, eye)
        r(x + 2, y + h - 2, w - 4, 1, P.ink)
        return
    end
    if expr == 'awe' then
        r(mx - 1, y + h - 3, 2, 2, P.ink)
        return
    end
    if expr == 'fear' then
        r(mx - 1, y + h - 3, 2, 2, P.ink)
        return
    end
    if expr == 'kind' then
        r(eL, y + 5, 1, 1, P.bone); r(eR + 1, y + 5, 1, 1, P.bone)
    elseif expr == 'worn' then
        l(eL, y + 5, eL, y + 6, P.ink)
    end
    r(mx, y + h - 2, 1, 1, P.ink)  -- sombra da boca
end

-- Viajante: o artesão-arqueiro (PERSONAGENS §1). Trapézio estreito de
-- casaco marrom frio até metade da coxa, aba ASSIMÉTRICA com um lado
-- preso para caminhar, remendo OCRE no ombro e arco alto numa lateral.
-- Rosto aberto SEM capuz: pele castanha quente, cabelo preto ondulado
-- amarrado baixo na nuca, barba curta irregular; a sobrancelha direita
-- sobe mais que a esquerda quando desconfia. Âncoras a 40px: arco
-- lateral alto, aba assimétrica, remendo claro no ombro.
local function traveler(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local bob, leg, cape, lean, squat = pose(action, frame)
    local east, south, west, north = direction == 1, direction == 2, direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local cx = 16 + side * lean
    local head = 2 + bob + squat                    -- topo do crânio
    local skin, skinDark = P.gold, P.rust           -- castanha de tom quente
    local hair = P.ink                              -- cabelo e barba pretos
    local coat, coatDeep, coatEdge = P.goldDark, P.goldDeep, P.gold
    local vest, vestEdge = P.jadeDark, P.jadeMid    -- lã verde desbotado
    local shirt, pants = P.bone, P.stoneDeep        -- linho cru, carvão
    local patch = P.goldLight                       -- remendo ocre
    local attacking = action == 'charge' or action == 'ready' or action == 'fire'
    local pull = action == 'charge' and frame or action == 'ready' and 3 or 0
    local armY = head + (attacking and 18 or 22)
    -- Aba assimétrica: um lado preso para caminhar (âncora 2) — a fenda
    -- da bainha mexe com o cape do passo como o manto mexia.
    local hemLong = math.min(36, 33 + bob + cape)
    local hemShort = 30 + bob

    -- Calças carvão + botas castanhas de cano baixo; passo aberto no walk.
    local stL = leg > 0 and math.min(2, leg) or 0
    local stR = leg < 0 and math.min(2, -leg) or 0
    r(cx - 6 + stL, 33 + stL, 4, 8 - stL, P.ink)
    r(cx + 2 - stR, 33 + stR, 4, 8 - stR, P.ink)
    r(cx - 5 + stL, 34 + stL, 3, 6 - stL, pants)
    r(cx + 3 - stR, 34 + stR, 3, 6 - stR, pants)
    r(cx - 7 + stL, 39 + stL, 6, 4, P.ink); r(cx + 1 - stR, 39 + stR, 6, 4, P.ink)
    r(cx - 6 + stL, 39 + stL, 4, 3, P.goldDeep); r(cx + 2 - stR, 39 + stR, 4, 3, P.goldDeep)
    r(cx - 6 + stL, 39 + stL, 4, 1, P.goldDark); r(cx + 2 - stR, 39 + stR, 4, 1, P.goldDark)
    if action == 'death' and frame >= 4 then
        -- Caído de lado: casaco aberto no chão, remendo virado para cima.
        p({4, 41, 10, 34, 20, 37, 27, 43, 10, 45}, P.goldDeep)
        r(9, 38, 9, 4, coat); r(11, 37, 5, 1, coatEdge)
        r(14, 39, 3, 2, patch)
        r(5, 35, 4, 3, hair)
        l(19, 42, 29, 43, P.gold); return
    end

    -- CASACO marrom frio: trapézio estreito até metade da coxa.
    if south then
        -- De frente: aba direita presa (perna à vista), esquerda solta.
        p({cx - 6, head + 13, cx + 6, head + 13, cx + 7, hemShort, cx + 1, hemShort,
            cx, hemLong, cx - 8, hemLong}, P.ink)
        p({cx - 5, head + 14, cx + 5, head + 14, cx + 6, hemShort - 1, cx + 1, hemShort - 1,
            cx, hemLong - 1, cx - 7, hemLong - 1}, coat)
        p({cx + 3, head + 14, cx + 5, head + 14, cx + 6, hemShort - 1, cx + 4, hemShort - 1}, coatDeep)
        l(cx - 5, head + 15, cx - 7, hemLong - 2, coatEdge)
        d(cx - 4, head + 16, 2, 10, coatDeep, .3)
        -- Prega da aba presa + prendedor na cintura.
        l(cx + 1, hemShort - 1, cx + 3, head + 24, coatDeep)
        r(cx + 2, head + 23, 2, 2, coatEdge)
        -- Peito: colete de lã verde desbotado, V de linho cru e o fecho
        -- feito para abrir com uma mão.
        p({cx - 3, head + 15, cx + 3, head + 15, cx + 2, head + 25, cx - 2, head + 25}, vest)
        p({cx - 2, head + 15, cx + 2, head + 15, cx, head + 20}, shirt)
        r(cx - 1, head + 20, 2, 1, P.goldLight)
        l(cx - 2, head + 25, cx + 2, head + 25, vestEdge)
        -- Bolsa de ferramentas pequena no quadril do lado solto.
        r(cx - 7, hemLong - 8, 4, 4, P.ink)
        r(cx - 6, hemLong - 7, 2, 2, P.goldDeep)
        -- Remendo ocre no ombro dela (âncora 3), longe do arco.
        r(cx - 8, head + 13, 3, 4, patch)
        r(cx - 8, head + 13, 3, 1, P.gold); r(cx - 8, head + 16, 3, 1, P.gold)
        -- Mangas caídas + mãos de pele.
        r(cx - 9, armY - 2, 3, 6, P.ink); r(cx - 8, armY - 1, 2, 4, coat)
        r(cx - 9, armY + 4, 3, 2, skin)
        r(cx + 7, armY - (attacking and 2 or 0), 3, 6, P.ink)
        r(cx + 8, armY + 1 - (attacking and 2 or 0), 2, 4, coat)
        r(cx + 7, armY + 4 - (attacking and 2 or 0), 3, 2, skin)
    elseif side ~= 0 then
        -- Perfil: a aba de trás sobe presa (perna livre atrás), a da
        -- frente desce solta — a fenda da bainha lê-se de lado.
        local pts, fill
        if east then
            pts = {cx - 5, head + 13, cx + 5, head + 13, cx + 6, hemLong, cx - 1, hemLong,
                cx - 3, hemShort, cx - 7, hemShort}
            fill = {cx - 4, head + 14, cx + 4, head + 14, cx + 5, hemLong - 1, cx - 1, hemLong - 1,
                cx - 2, hemShort - 1, cx - 6, hemShort - 1}
        else
            pts = {cx + 5, head + 13, cx - 5, head + 13, cx - 6, hemLong, cx + 1, hemLong,
                cx + 3, hemShort, cx + 7, hemShort}
            fill = {cx + 4, head + 14, cx - 4, head + 14, cx - 5, hemLong - 1, cx + 1, hemLong - 1,
                cx + 2, hemShort - 1, cx + 6, hemShort - 1}
        end
        p(pts, P.ink); p(fill, coat)
        -- Sombra no dorso + prega da aba presa + prendedor na cintura.
        l(cx - side * 4, head + 15, cx - side * 5, hemShort - 3, coatDeep)
        l(cx - side * 2, hemShort - 1, cx - side * 3, head + 25, coatDeep)
        r(cx - side * 3 - 1, head + 24, 2, 2, coatEdge)
        -- Peito: filete de colete e camisa na borda frontal + o fecho.
        r(cx + side * 3 - (west and 1 or 0), head + 15, 2, 9, vest)
        r(cx + side * 4 - (west and 1 or 0), head + 15, 1, 3, shirt)
        r(cx + side * 3 - 1, head + 19, 2, 1, P.goldLight)
        -- Bolsa de ferramentas na cintura de trás.
        local tx = east and cx - 7 or cx + 4
        r(tx, hemLong - 7, 3, 4, P.ink); r(tx, hemLong - 6, 2, 2, P.goldDeep)
        -- Remendo ocre no ombro: a oeste é o ombro encarado, a leste
        -- espreita sobre o dorso — a âncora lê nos dois perfis.
        local px = west and cx - 6 or cx - 2
        r(px, head + 12, 4, 4, patch); r(px, head + 12, 4, 1, P.gold)
        -- Braço da frente segura a haste do arco; o de trás some na aba.
        l(cx + side * 4, armY - 1, cx + side * 8, armY + 1, coat)
        r(cx + side * 7 - 1, armY, 3, 3, skin)
        r(cx - side * 5 - (west and 1 or 0), armY, 2, 5, coatDeep)
    else
        -- Costas: casaco fechado com a mesma fenda de bainha, alça da
        -- aljava em diagonal e empenas de osso acima do ombro.
        p({cx - 6, head + 13, cx + 6, head + 13, cx + 7, hemShort, cx + 1, hemShort,
            cx, hemLong, cx - 8, hemLong}, P.ink)
        p({cx - 5, head + 14, cx + 5, head + 14, cx + 6, hemShort - 1, cx + 1, hemShort - 1,
            cx, hemLong - 1, cx - 7, hemLong - 1}, coat)
        p({cx + 2, head + 14, cx + 5, head + 14, cx + 6, hemShort - 1, cx + 4, hemShort - 1}, coatDeep)
        l(cx + 1, hemShort - 1, cx + 3, head + 24, coatDeep)
        r(cx + 2, head + 23, 2, 2, coatEdge)
        d(cx - 4, head + 16, 2, 10, coatDeep, .3)
        -- Aljava funcional: alça cruzando o dorso + empenas de osso.
        l(cx - 5, head + 14, cx + 4, head + 26, P.goldDeep)
        r(cx - 9, head + 14, 4, 11, P.ink)
        r(cx - 8, head + 15, 2, 9, P.goldDark)
        l(cx - 8, head + 13, cx - 9, head + 10, shirt)
        l(cx - 7, head + 14, cx - 7, head + 10, shirt)
        -- Remendo: de costas o ombro dela troca de lado na tela.
        r(cx + 5, head + 13, 3, 4, patch); r(cx + 5, head + 13, 3, 1, P.gold)
        r(cx - 8, armY - 2, 3, 5, P.ink); r(cx - 7, armY - 1, 2, 3, coatDeep)
        r(cx + 6, armY - 2, 3, 5, P.ink); r(cx + 7, armY - 1, 2, 3, coatDeep)
    end

    -- ARCO ALTO numa lateral (âncora 1): haste recurva passa do ombro e
    -- lê-se em todas as direções; no ataque a corda cede com o pull.
    if side ~= 0 then
        local bx, by = cx + side * 12, head + 2
        l(bx - side * 4, by, bx + side, by + 7, P.goldLight)
        l(bx + side, by + 7, bx + side * 4, by + 13, P.gold)
        l(bx + side * 4, by + 13, bx + side, by + 21, P.gold)
        l(bx + side, by + 21, bx - side * 4, by + 26, P.goldDark)
        l(bx - side * 4, by, bx - side * (4 + pull), by + 13, P.bone)
        l(bx - side * (4 + pull), by + 13, bx - side * 4, by + 26, P.bone)
        r(bx - side, by + 12, 3, 3, P.goldDeep)
        if attacking then
            l(cx + side * (4 - pull), by + 13, cx + side * 17, by + 13, P.white)
            l(cx + side * 15, by + 12, cx + side * 18, by + 13, P.ember)
            l(cx + side * 15, by + 14, cx + side * 18, by + 13, P.ember)
            l(cx - side * pull, armY + 1, cx + side * 9, armY + 1, P.goldLight)
        end
    elseif south then
        -- Frente: arco em pé ao lado do corpo, haste passa da cabeça.
        local bx = cx + 10
        l(bx - 2, head - 1, bx + 1, head + 6, P.goldLight)
        l(bx + 1, head + 6, bx + 3, head + 16, P.gold)
        l(bx + 3, head + 16, bx + 1, head + 28, P.gold)
        l(bx + 1, head + 28, bx - 3, head + 33, P.goldDark)
        l(bx - 2, head - 1, bx - 3, head + 17, P.bone)
        l(bx - 3, head + 17, bx - 2, head + 33, P.bone)
        if attacking then
            l(bx - 3, head + 16, bx - 3, head + 18, P.white)
            l(bx - 5, head + 16, bx + 14, head + 16, P.white)
            r(bx + 10, head + 15, 2, 2, P.ember)
        end
        l(cx + 8, armY, bx - 1, armY + 2, coat)
        r(bx - 1, armY + 2, 3, 3, skin)
    else
        -- Costas: o arco fica na mão direita baixa, haste na vertical.
        local bx = cx + 9
        l(bx - 2, head + 3, bx + 2, head + 10, P.goldLight)
        l(bx + 2, head + 10, bx + 4, head + 22, P.gold)
        l(bx + 4, head + 22, bx + 1, head + 32, P.goldDark)
        l(bx - 2, head + 3, bx - 3, head + 20, P.bone)
    end

    if action == 'mine' then
        -- Picareta a dois tempos em vez do arco: braço armado do lado.
        local swing = ({-6, 1, 5, 1})[frame]
        if side ~= 0 then
            l(cx + side * 5, head + 26, cx + side * 13, head + 10 + swing, P.goldDark)
            l(cx + side * 6, head + 26, cx + side * 14, head + 10 + swing, P.gold)
            l(cx + side * 8, head + 7 + swing, cx + side * 17, head + 12 + swing, P.stoneLight)
            l(cx + side * 8, head + 6 + swing, cx + side * 17, head + 11 + swing, P.white)
        else
            l(cx - 4, head + 25, cx + 8, head + 11 + swing, P.gold)
            l(cx + 1, head + 8 + swing, cx + 12, head + 12 + swing, P.white)
        end
    end

    -- CABEÇA sem capuz: cabelo preto ondulado amarrado baixo na nuca,
    -- barba curta irregular — o rosto dele é a marca, nunca o pano.
    if north then
        -- De costas: o cabelo cobre a cabeça; o rabo baixo na nuca com a
        -- tira de couro é a marca dele por trás.
        r(cx - 5, head + 2, 10, 12, P.ink)
        r(cx - 4, head + 3, 8, 10, hair)
        l(cx - 4, head + 4, cx + 3, head + 4, P.stoneDeep)
        l(cx - 4, head + 8, cx + 3, head + 8, P.stoneDeep)
        r(cx - 1, head + 13, 3, 2, hair)
        r(cx, head + 13, 1, 1, P.goldDark)
    elseif side ~= 0 then
        -- Perfil: nariz amplo de ponta baixa à frente, olho único, barba
        -- no queixo frontal; nuca cheia com o rabo saindo atrás.
        r(cx - 5, head + 2, 10, 12, P.ink)
        local fx = east and cx or cx - 4
        r(fx, head + 4, 4, 9, skin)
        r(fx, head + 4, 4, 1, P.goldLight)
        r(east and cx + 4 or cx - 5, head + 8, 1, 2, skin)
        r(east and cx + 4 or cx - 5, head + 9, 1, 1, skinDark)
        r(east and cx + 2 or cx - 3, head + 7, 2, 2, P.ink)
        r(east and cx + 2 or cx - 3, head + 6, 2, 1, P.ink)
        r(east and cx + 1 or cx - 4, head + 10, 3, 3, hair)
        r(east and cx + 3 or cx - 4, head + 9, 1, 2, hair)
        r(cx - 4, head + 1, 8, 4, hair)
        r(east and cx - 5 or cx + 1, head + 4, 4, 8, hair)
        r(east and cx - 7 or cx + 4, head + 9, 2, 5, hair)
        r(east and cx - 7 or cx + 4, head + 12, 2, 1, P.goldDark)
        r(cx - 1, head + 13, 3, 2, skinDark)
    else
        -- Sul: rosto aberto — testa lavada, olhos castanhos escuros,
        -- nariz amplo de ponta baixa, barba curta irregular fechando o
        -- queixo; a sobrancelha direita sobe mais que a esquerda.
        r(cx - 5, head + 2, 10, 12, P.ink)
        r(cx - 4, head + 3, 8, 10, skin)
        r(cx - 4, head + 4, 8, 1, P.goldLight)
        r(cx - 5, head + 1, 10, 3, hair)
        r(cx - 5, head + 4, 1, 5, hair); r(cx + 4, head + 4, 1, 5, hair)
        r(cx - 2, head + 4, 2, 1, hair); r(cx + 1, head + 4, 1, 1, hair)
        r(cx - 3, head + 7, 2, 2, P.ink); r(cx + 1, head + 7, 2, 2, P.ink)
        r(cx - 3, head + 6, 2, 1, P.ink)
        r(cx + 1, head + 5, 3, 1, P.ink)
        r(cx, head + 8, 1, 2, skinDark); r(cx - 1, head + 9, 3, 1, skinDark)
        r(cx - 4, head + 10, 2, 3, hair); r(cx + 3, head + 9, 1, 4, hair)
        r(cx - 3, head + 11, 6, 2, hair)
        r(cx - 1, head + 11, 3, 1, skinDark)
        r(cx - 2, head + 13, 4, 1, skinDark)
    end
    if action == 'guard' then
        -- Broquel de madeira e ferro: losango com borda clara e núcleo.
        if side ~= 0 then
            local sx = cx + side * 13
            l(sx, head + 12, sx + side * 4, head + 17, P.stoneEdge)
            l(sx + side * 4, head + 17, sx + side * 4, head + 29, P.stoneLight)
            l(sx + side * 4, head + 29, sx, head + 34, P.goldDark)
            l(sx, head + 12, sx - side, head + 23, P.stoneDeep)
            r(sx - 1, head + 20, 2, 4, P.bone)
        else
            local sy = north and head + 1 or head + 34
            l(cx - 11, sy, cx - 7, sy + 4, P.stoneLight)
            l(cx - 7, sy + 4, cx + 7, sy + 4, P.stoneLight)
            l(cx + 7, sy + 4, cx + 11, sy, P.goldDark)
            r(cx - 1, sy + 2, 2, 2, P.bone)
        end
    end
end

-- Brutos de pedra: quatro corpos realmente diferentes sob o mesmo
-- contrato — dasher corre apoiado nos punhos (cunha quadrúpede), breaker
-- é um tronco em V sobre pernas abertas, demolisher carrega um braço
-- descomunal que pende ao chão, warden é torre estreita de mitra e
-- escudo. `sk` escolhe rampa e a variante de corpo.
local function sentinel(data, ox, oy, direction, action, frame, sk)
    sk = sk or {}
    local cape = sk.cape or P.jadeDark
    local capeLine = sk.capeLine or P.jade
    local shell = sk.shell or P.stoneLight
    local shellHi = sk.shellHi or P.stoneEdge
    local shellDeep = sk.shellDeep or P.stoneDeep
    local body = sk.body or P.stone
    local bodyDark = sk.bodyDark or P.stoneDark
    local trim = sk.trim or P.gold
    local trimDark = sk.trimDark or P.goldDark
    local trimLight = sk.trimLight or P.goldLight
    local eye = sk.eye or P.ember
    local eyeLow = sk.eyeLow or P.jade
    local r, l, p, d = painter(data, ox, oy)
    local bob, leg, capeSway, lean, squat = pose(action, frame)
    local side = direction == 1 and 1 or direction == 3 and -1 or 0
    local south, north = direction == 2, direction == 4
    local cx = 16 + side * lean
    local war = action == 'warn'
    if action == 'death' and frame >= 4 then
        p({3, 41, 9, 34, 23, 36, 29, 44, 7, 45}, bodyDark)
        r(8, 36, 13, 4, shell); r(8, 36, 13, 1, shellHi)
        r(12, 39, 5, 2, capeLine)
        l(15, 37, 18, 39, P.ink)                              -- trinca na queda
        return
    end
    local v = sk.build or 'brute'

    if v == 'brute' then
        local top = 14 + bob + squat
        r(cx - 8, 36 + math.min(2, leg), 5, 8, P.ink)
        r(cx - 8, 37 + math.min(2, leg), 3, 6, bodyDark)
        r(cx + 4, 35 - math.min(2, leg), 5, 9, P.ink)
        r(cx + 4, 36 - math.min(2, leg), 3, 7, body)
        r(cx + 4, 36 - math.min(2, leg), 3, 1, shellHi)
        -- Braços-pilar até o chão: antebraço largo + punho de bloco,
        -- juntas de dedo no apoio.
        r(cx - 13, top + 16, 6, 22, P.ink); r(cx + 8, top + 16, 6, 22, P.ink)
        r(cx - 12, top + 17, 4, 19, shell); r(cx + 9, top + 17, 4, 19, bodyDark)
        l(cx - 12, top + 18, cx - 12, top + 30, shellHi)      -- rim do braço
        r(cx - 13, top + 34, 6, 6, P.ink); r(cx + 8, top + 34, 6, 6, P.ink)
        r(cx - 12, top + 35, 4, 4, bodyDark); r(cx + 9, top + 35, 4, 4, bodyDark)
        l(cx - 12, top + 37, cx - 9, top + 37, P.ink)         -- juntas do punho
        l(cx + 9, top + 37, cx + 12, top + 37, P.ink)
        -- Tronco tombado: ombros altos atrás, barriga baixa à frente.
        p({cx - 11, top + 6, cx + 9, top + 9, cx + 12, top + 18,
            cx + 10, top + 26, cx - 9, top + 26, cx - 12, top + 12}, P.ink)
        p({cx - 10, top + 7, cx + 8, top + 10, cx + 11, top + 18,
            cx + 9, top + 25, cx - 8, top + 25, cx - 11, top + 12}, body)
        p({cx - 10, top + 7, cx - 2, top + 8, cx - 6, top + 22,
            cx - 10, top + 18}, shell)
        p({cx + 6, top + 11, cx + 10, top + 18, cx + 8, top + 24,
            cx + 4, top + 24}, shellDeep)
        l(cx - 10, top + 7, cx - 2, top + 8, shellHi)
        l(cx - 10, top + 12, cx - 8, top + 20, shellHi)       -- rim esquerdo
        d(cx + 4, top + 12, 3, 12, shellDeep, .4)
        -- Junções de placa + musgo nas fendas (pedra que dormiu fora).
        l(cx - 2, top + 10, cx, top + 20, P.ink)
        r(cx - 1, top + 14, 1, 1, P.jadeDark); r(cx + 3, top + 17, 1, 1, P.jadeDark)
        l(cx - 6, top + 15, cx - 4, top + 21, shellDeep)      -- trinca
        -- Cabeça de elmo baixa e à frente — fenda de olho + queixo.
        p({cx - 6, top + 4, cx - 1, top, cx + 5, top + 4, cx + 6, top + 11,
            cx - 4, top + 12}, P.ink)
        p({cx - 5, top + 5, cx - 1, top + 1, cx + 4, top + 5, cx + 5, top + 10,
            cx - 4, top + 11}, shell)
        l(cx - 5, top + 5, cx - 1, top + 1, shellHi)
        if south then
            r(cx - 4, top + 6, 9, 3, P.ink)
            r(cx - 4, top + 7, 3, 2, eye); r(cx + 1, top + 7, 3, 2, eyeLow)
            r(cx - 4, top + 7, 1, 1, P.white); r(cx + 1, top + 7, 1, 1, P.white)
            r(cx - 4, top + 10, 7, 2, bodyDark)
            l(cx - 3, top + 11, cx + 2, top + 11, P.ink)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 2 or cx - 6
            r(ex, top + 5, 3, 5, P.ink); r(ex, top + 6, 3, 3, eye)
            r(ex, top + 6, 1, 1, P.white)
            r(side == 1 and cx + 4 or cx - 5, top + 9, 2, 3, bodyDark)
        else
            l(cx - 3, top + 5, cx + 3, top + 5, bodyDark)
            l(cx - 2, top + 7, cx + 2, top + 8, shellDeep)    -- suture do elmo
        end
        l(cx - 8, top + 5, cx + 4, top + 5, trimDark)
        if war then
            r(cx - 1, top - 2, 3, 2, trimLight)
            l(cx - 3, top - 1, cx + 4, top - 1, trimLight)
        end
    elseif v == 'bull' then
        local top = 7 + bob + squat
        r(cx - 13 - math.min(2, leg), 34 + math.min(2, leg), 6, 10, P.ink)
        r(cx - 12 - math.min(2, leg), 35 + math.min(2, leg), 4, 8, body)
        r(cx + 7 + math.min(2, leg), 34 - math.min(2, leg), 6, 10, P.ink)
        r(cx + 8 + math.min(2, leg), 35 - math.min(2, leg), 4, 8, bodyDark)
        l(cx - 12 - math.min(2, leg), 35 + math.min(2, leg), cx - 12 -
            math.min(2, leg), 41, shellHi)
        p({cx - 6, 32, cx + 6, 32, cx + 8, 26, cx - 8, 26}, P.ink)
        p({cx - 5, 32, cx + 5, 32, cx + 7, 27, cx - 7, 27}, bodyDark)
        p({cx - 13, top + 4, cx + 13, top + 4, cx + 11, top + 22, cx + 6, 28,
            cx - 6, 28, cx - 11, top + 22}, P.ink)
        p({cx - 12, top + 5, cx + 12, top + 5, cx + 10, top + 21, cx + 5, 27,
            cx - 5, 27, cx - 10, top + 21}, body)
        p({cx - 12, top + 5, cx - 4, top + 5, cx - 7, top + 20,
            cx - 10, top + 20}, shell)
        p({cx + 6, top + 5, cx + 12, top + 5, cx + 10, top + 21,
            cx + 7, top + 21}, shellDeep)
        l(cx - 12, top + 5, cx - 4, top + 5, shellHi)
        l(cx - 10, top + 9, cx - 8, top + 18, shellHi)
        d(cx + 6, top + 8, 4, 12, shellDeep, .35)
        -- Fenda central do peito + laje pectoral + musgo na axila.
        l(cx - 1, top + 8, cx - 2, top + 19, P.ink)
        r(cx - 4, top + 6, 8, 3, shell)
        r(cx - 4, top + 6, 8, 1, shellHi)
        r(cx + 2, top + 16, 1, 1, P.jadeDark); r(cx + 4, top + 19, 1, 1, P.jadeDark)
        r(cx - 7, 24, 14, 3, trimDark); r(cx - 7, 24, 11, 1, trim)
        r(cx - 7, 24, 2, 3, trim)                             -- fivela do peitoral
        -- Braços de peso pendendo ao longo do V + juntas.
        r(cx - 15, top + 10, 5, 16, P.ink); r(cx + 10, top + 10, 5, 16, P.ink)
        r(cx - 14, top + 11, 3, 13, bodyDark); r(cx + 11, top + 11, 3, 13, bodyDark)
        l(cx - 14, top + 18, cx - 12, top + 18, P.ink)
        l(cx + 11, top + 18, cx + 13, top + 18, P.ink)
        r(cx - 14, top + 23, 3, 2, body)                      -- nós do punho
        r(cx + 11, top + 23, 3, 2, body)
        -- Cabeça afundada no V: elmo baixo, fenda de olhos, queixo.
        p({cx - 6, top + 3, cx - 3, top, cx + 3, top, cx + 6, top + 3,
            cx + 5, top + 10, cx - 5, top + 10}, P.ink)
        p({cx - 5, top + 3, cx - 3, top + 1, cx + 3, top + 1, cx + 5, top + 4,
            cx + 4, top + 9, cx - 4, top + 9}, shell)
        l(cx - 5, top + 3, cx - 3, top + 1, shellHi)
        if south then
            r(cx - 4, top + 4, 8, 3, P.ink)
            r(cx - 4, top + 5, 3, 2, eye); r(cx + 1, top + 5, 3, 2, eyeLow)
            r(cx - 4, top + 5, 1, 1, P.white); r(cx + 1, top + 5, 1, 1, P.white)
            r(cx - 4, top + 8, 8, 2, bodyDark)
            l(cx - 3, top + 9, cx + 3, top + 9, P.ink)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 5
            r(ex, top + 4, 3, 4, P.ink); r(ex, top + 5, 3, 2, eye)
            r(ex, top + 5, 1, 1, P.white)
        else l(cx, top + 3, cx + 1, top + 8, bodyDark) end
        -- Chifres longos de carga — dentro do frame, com serra na base.
        local hx = 12
        l(cx - 7, top + 1, cx - hx, top - 4, P.ink)
        l(cx + 7, top + 1, cx + hx, top - 4, P.ink)
        l(cx - 7, top + 1, cx - hx + 1, top - 3, trimLight)
        l(cx + 7, top + 1, cx + hx - 1, top - 3, trimLight)
        l(cx - hx + 1, top - 3, cx - hx + 3, top - 6, trim)
        l(cx + hx - 1, top - 3, cx + hx - 3, top - 6, trim)
        r(cx - 8, top + 1, 2, 2, trimDark); r(cx + 6, top + 1, 2, 2, trimDark)
        if war then l(cx - 4, top - 1, cx + 4, top - 1, trimLight) end
    elseif v == 'ruin' then
        local top = 8 + bob + squat
        r(cx - 9, 37 + math.min(2, leg), 6, 7, P.ink)
        r(cx + 3, 36 - math.min(2, leg), 6, 8, P.ink)
        r(cx - 8, 38 + math.min(2, leg), 4, 5, body)
        r(cx + 4, 37 - math.min(2, leg), 4, 6, bodyDark)
        -- Braço descomunal: ombro-laje + antebraço + punho no chão.
        p({cx - 16, top + 2, cx - 7, top + 2, cx - 9, 40, cx - 14, 40}, P.ink)
        p({cx - 15, top + 3, cx - 8, top + 3, cx - 9, 39, cx - 13, 39}, shell)
        p({cx - 15, top + 3, cx - 12, top + 3, cx - 13, 39, cx - 14, 39}, shellDeep)
        l(cx - 15, top + 4, cx - 10, top + 4, shellHi)
        l(cx - 12, top + 8, cx - 10, 30, P.ink)               -- fenda do braço
        r(cx - 12, top + 12, 1, 1, P.jadeDark); r(cx - 11, top + 20, 1, 1, P.jadeDark)
        r(cx - 15, 38, 6, 6, P.ink); r(cx - 14, 39, 4, 4, bodyDark)
        l(cx - 14, 41, cx - 11, 41, P.ink)                    -- nós dos dedos
        r(cx - 17, top - 2, 9, 6, P.ink); r(cx - 16, top - 1, 7, 4, shell)
        r(cx - 16, top - 1, 7, 1, shellHi)
        -- Tronco inclinado à esquerda sob a carga.
        p({cx - 8, top + 6, cx + 8, top + 4, cx + 10, 34, cx - 7, 36}, P.ink)
        p({cx - 7, top + 7, cx + 7, top + 5, cx + 9, 33, cx - 6, 35}, body)
        p({cx - 7, top + 7, cx - 1, top + 6, cx - 3, 34, cx - 6, 34}, shell)
        p({cx + 4, top + 5, cx + 7, top + 5, cx + 9, 33, cx + 6, 33}, shellDeep)
        l(cx - 7, top + 7, cx - 1, top + 6, shellHi)
        l(cx + 1, top + 9, cx + 2, top + 26, P.ink)           -- trinca do flanco
        r(cx + 4, top + 12, 1, 1, P.jadeDark)
        r(cx - 6, 30, 14, 3, trimDark); r(cx - 6, 30, 11, 1, trim)
        r(cx + 8, top + 8, 5, 14, P.ink); r(cx + 9, top + 9, 3, 12, bodyDark)
        l(cx + 9, top + 14, cx + 11, top + 14, P.ink)
        p({cx - 5, top + 2, cx - 2, top - 1, cx + 5, top + 2, cx + 6, top + 9,
            cx - 4, top + 11}, P.ink)
        p({cx - 4, top + 3, cx - 2, top, cx + 4, top + 3, cx + 5, top + 8,
            cx - 3, top + 10}, shell)
        l(cx - 4, top + 3, cx - 2, top, shellHi)
        if south then
            r(cx - 3, top + 5, 8, 3, P.ink)
            r(cx - 3, top + 6, 3, 2, eye); r(cx + 1, top + 6, 3, 2, eyeLow)
            r(cx - 3, top + 6, 1, 1, P.white)
            r(cx - 3, top + 9, 7, 2, bodyDark)
            l(cx - 2, top + 10, cx + 3, top + 10, P.ink)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 4
            r(ex, top + 5, 3, 4, P.ink); r(ex, top + 6, 3, 2, eye)
            r(ex, top + 6, 1, 1, P.white)
        else l(cx, top + 3, cx + 1, top + 8, bodyDark) end
        if war then
            r(cx - 1, top - 2, 3, 2, trimLight)
            l(cx - 3, top - 1, cx + 4, top - 1, trimLight)
        end
    else
        -- WARDEN (tower): coluna cerimonial — mesma torre + veios de
        -- selo descendo a face do escudo e degraus na mitra.
        local top = 8 + bob + squat
        r(cx - 6, 39 + math.min(2, leg), 6, 5, P.ink)
        r(cx + 1, 39 - math.min(2, leg), 6, 5, P.ink)
        r(cx - 5, 40 + math.min(2, leg), 4, 2, body)
        r(cx + 2, 40 - math.min(2, leg), 4, 2, bodyDark)
        p({cx - 8, top + 10, cx + 8, top + 10, cx + 9, 39, cx - 9, 39}, P.ink)
        p({cx - 7, top + 11, cx + 7, top + 11, cx + 8, 38, cx - 8, 38}, body)
        p({cx - 7, top + 11, cx - 2, top + 11, cx - 4, 38, cx - 8, 38}, shell)
        p({cx + 4, top + 11, cx + 7, top + 11, cx + 8, 38, cx + 5, 38}, shellDeep)
        l(cx - 7, top + 11, cx - 8, 37, shellHi)
        -- Placas da coluna: dois filetes horizontais + emenda central.
        l(cx - 6, top + 18, cx + 6, top + 18, P.ink)
        l(cx - 6, top + 26, cx + 6, top + 26, bodyDark)
        l(cx - 1, top + 14, cx - 2, top + 32, shellDeep)
        r(cx + 3, top + 20, 1, 1, P.jadeDark)
        r(cx - 8, 36, 16, 2, bodyDark); l(cx - 7, 36, cx + 7, 36, trim)
        r(cx - 7, top + 9, 14, 2, trimDark); r(cx - 7, top + 9, 11, 1, trim)
        if north then
            l(cx, top + 12, cx, 34, trimDark)
            l(cx - 3, top + 16, cx - 3, 30, trimDark)
        else
            p({cx - 2, top + 15, cx + 2, top + 15, cx + 3, top + 24,
                cx - 3, top + 24}, trimDark)
            p({cx - 1, top + 16, cx + 1, top + 16, cx + 2, top + 23,
                cx - 2, top + 23}, trim)
        end
        p({cx - 6, top + 2, cx - 2, top - 1, cx + 3, top - 1, cx + 6, top + 3,
            cx + 5, top + 9, cx - 5, top + 9}, P.ink)
        p({cx - 5, top + 2, cx - 2, top, cx + 3, top, cx + 5, top + 3,
            cx + 4, top + 8, cx - 4, top + 8}, shell)
        l(cx - 5, top + 2, cx - 2, top, shellHi)
        if south then
            r(cx - 4, top + 4, 8, 3, P.ink)
            r(cx - 3, top + 5, 2, 2, eye); r(cx + 1, top + 5, 2, 2, eyeLow)
            r(cx - 3, top + 5, 1, 1, P.white); r(cx + 1, top + 5, 1, 1, P.white)
            r(cx - 3, top + 8, 6, 2, bodyDark)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 4
            r(ex, top + 4, 3, 4, P.ink); r(ex, top + 5, 3, 2, eye)
            r(ex, top + 5, 1, 1, P.white)
        else l(cx, top + 2, cx + 1, top + 7, bodyDark) end
        p({cx - 5, top - 1, cx - 2, top - 8, cx + 2, top - 8, cx + 5, top - 1},
            P.ink)
        p({cx - 4, top - 1, cx - 2, top - 7, cx + 2, top - 7, cx + 4, top - 1},
            trimDark)
        p({cx - 4, top - 1, cx - 2, top - 7, cx, top - 7, cx - 2, top - 1}, trim)
        r(cx, top - 8, 1, 1, trimLight)
        l(cx - 3, top - 4, cx + 3, top - 4, P.ink)              -- degrau da mitra
        if south then
            r(cx + 7, top + 12, 4, 18, P.ink); r(cx + 8, top + 13, 2, 16, shell)
            r(cx + 8, top + 13, 2, 2, trimLight)
            l(cx + 8, top + 26, cx + 9, top + 26, trim)
            l(cx + 9, top + 15, cx + 9, top + 27, shellDeep)  -- veio do selo
        elseif side ~= 0 then
            r(cx + side * 9 - 1, top + 12, 4, 18, P.ink)
            r(cx + side * 9, top + 13, 2, 16, shell)
            r(cx + side * 9, top + 13, 2, 2, trimLight)
            l(cx + side * 9 + (side == 1 and 0 or -1), top + 15,
                cx + side * 9 + (side == 1 and 0 or -1), top + 27, shellDeep)
        end
        if war then l(cx - 4, top - 1, cx + 4, top - 1, trimLight) end
    end
    if v ~= 'brute' then
        l(cx - 8, 37, cx - 9, 41, cape); l(cx + 8, 37, cx + 9, 41, capeLine)
    end
    -- Fuligem de guerra nas juntas: trincas estáveis no dorso e sombra
    -- de solda entre placas.
    l(cx - 2, 32, cx - 4, 36, shellDeep)
    l(cx + 3, 35, cx + 5, 39, P.ink)
    r(cx - 1, 30, 1, 2, P.ink)
    l(cx - 3, 38, cx + 3, 38, P.ink)
end

-- Devotos encapuzados: cinco corpos realmente diferentes — scout
-- diagonal (ranger), bloco de veterano, carregador baixo (sower),
-- agulha espectral flutuante (watcher), presença larga de coroa e gesto
-- (regent). `cfg.build` escolhe o corpo; rampa/olhos/expressão por skin.
local function zealot(data, ox, oy, direction, action, frame, cfg)
    local r, l, p, d = painter(data, ox, oy)
    local bob, leg, cape, lean, squat = pose(action, frame)
    local east, south, west, north = direction == 1, direction == 2,
        direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local aim = action == 'warn' or action == 'dash'
    local robe, robeDark, robeLight = cfg.robe, cfg.robeDark, cfg.robeLight
    local robeDeep = cfg.robeDeep or P.violetDeep
    local hood = cfg.hood or robe
    local trim = cfg.trim or P.gold
    local trimDark = cfg.trimDark or P.goldDark
    local trimLight = cfg.trimLight or P.goldLight
    local eye = cfg.eye or P.goldLight
    local skin = cfg.skin or P.bone
    local cx = 16 + side * lean
    local build = cfg.build or 'block'
    if action == 'death' and frame >= 4 then
        p({5, 41, 11, 34, 22, 38, 27, 44, 8, 45}, robeDark)
        r(10, 38, 9, 3, robe); r(14, 37, 4, 1, trim)
        l(9, 40, 13, 42, P.ink); return
    end
    local stL = leg > 0 and math.min(3, leg) or 0
    local stR = leg < 0 and math.min(3, -leg) or 0

    if build == 'scout' then
        -- RANGER: talhe oblíquo — pernas finas abertas, torso curto,
        -- capuz baixo, besta atravessando o corpo na diagonal.
        local top = 7 + bob + squat
        r(cx - 5 - stL, 34 + stL, 3, 10 - stL, P.ink)
        r(cx - 4 - stL, 34 + stL, 2, 8 - stL, robeDark)
        r(cx + 3 + stR, 36 + stR, 3, 8 - stR, P.ink)
        r(cx + 3 + stR, 36 + stR, 2, 6 - stR, robeDeep)
        r(cx - 6 - stL, 40 + stL, 5, 3, P.ink); r(cx + 3 + stR, 41 + stR, 5, 3, P.ink)
        r(cx - 6 - stL, 40 + stL, 2, 1, robeDark)             -- biqueira
        -- Faixa de canela (caneleira de pano) + joelho marcado.
        r(cx - 4 - stL, 37 + stL, 2, 1, trimDark)
        r(cx + 3 + stR, 38 + stR, 2, 1, trimDark)
        -- Torso curto tombado + manto curto aberto nas laterais.
        p({cx - 5, top + 12, cx + 7, top + 10, cx + 8, 34, cx - 6, 35}, P.ink)
        p({cx - 4, top + 13, cx + 6, top + 11, cx + 7, 33, cx - 5, 34}, robe)
        p({cx + 3, top + 11, cx + 6, top + 11, cx + 7, 33, cx + 4, 33}, robeDeep)
        l(cx - 4, top + 13, cx - 5, 33, robeLight)
        l(cx - 3, top + 14, cx - 4, 30, robeLight)            -- vinco do manto
        r(cx - 5, top + 24, 11, 2, trimDark); r(cx - 5, top + 24, 8, 1, trim)
        r(cx + 3, top + 24, 2, 2, trim)                       -- fivela
        -- Peitilho de couro com talabarte: duas faixas cruzadas.
        l(cx - 3, top + 14, cx + 4, top + 24, trimDark)
        l(cx - 2, top + 14, cx + 5, top + 24, P.goldDeep)
        -- Besta de caça (âncora): coronha curta nivelada na frente do
        -- peito, arco em asa na ponta e corda esticada — lê o ofício
        -- sem sair do frame.
        local fs = side ~= 0 and side or 1
        if side ~= 0 or north then
            -- De lado/costas a besta vai nivelada ao peito apontando
            -- para a frente; a mão da corda trava no gatilho.
            local bx, by = cx + fs * 4, top + 15
            l(cx - fs * 2, by + 3, bx + fs * 6, by, trimDark) -- coronha
            l(cx - fs * 2, by + 3, bx + fs * 4, by + 1, trim)
            l(bx + fs * 5, by - 4, bx + fs * 6, by, trim)     -- asa de cima
            l(bx + fs * 5, by + 5, bx + fs * 6, by, trim)     -- asa de baixo
            l(bx + fs * 5, by - 4, bx + fs * 2, by, P.bone)   -- corda
            l(bx + fs * 5, by + 5, bx + fs * 2, by, P.bone)
            r(cx - fs * 1, by + 2, 2, 3, skin)                -- mão no gatilho
            r(cx - fs * 3, by + 3, 2, 8, robeDark)            -- braço sob a coronha
        else
            -- De frente a besta descansa no quadril: coronha curta na
            -- vertical, asa e corda cruzando a saia.
            local bx = cx + 8
            l(bx, top + 18, bx, top + 30, trimDark)
            l(bx - 4, top + 17, bx, top + 19, trim)
            l(bx + 4, top + 17, bx, top + 19, trim)
            l(bx - 4, top + 17, bx, top + 26, P.bone)
            l(bx + 4, top + 17, bx, top + 26, P.bone)
            r(cx + 5, top + 20, 3, 8, robeDark)               -- braço na coronha
            r(cx + 5, top + 27, 3, 2, skin)
        end
        if north then
            -- Aljava abaixo do capuz: fletchas de osso no dorso.
            r(cx - 10, top + 8, 4, 10, P.ink)
            r(cx - 9, top + 9, 2, 8, trimDark)
            l(cx - 10, top + 4, cx - 9, top + 9, P.bone)
            l(cx - 8, top + 3, cx - 8, top + 8, P.bone)
            l(cx - 10, top + 4, cx - 9, top + 3, P.white)
        end
        -- Cabeça: capuz baixo inclinado, rosto aberto.
        if north then
            p({cx - 5, top + 3, cx - 2, top - 1, cx + 4, top - 1, cx + 7,
                top + 4, cx + 6, top + 12, cx - 4, top + 13}, P.ink)
            p({cx - 4, top + 3, cx - 2, top, cx + 4, top, cx + 6, top + 4,
                cx + 5, top + 11, cx - 3, top + 12}, hood)
            p({cx - 4, top + 3, cx - 2, top, cx, top + 1, cx - 2, top + 8,
                cx - 3, top + 11}, robeLight)
            l(cx - 2, top + 6, cx - 3, top + 10, robeDeep)    -- vinco do capuz
        elseif side ~= 0 then
            p({cx - 5, top + 3, cx - 2, top - 1, cx + side * 3 + 2, top,
                cx + side * 6 + 1, top + 6, cx + side * 3, top + 11,
                cx - 5, top + 12}, P.ink)
            p({cx - 4, top + 3, cx - 2, top, cx + side * 3 + 1, top + 1,
                cx + side * 5, top + 6, cx + side * 2, top + 10,
                cx - 4, top + 11}, hood)
            l(cx - 3, top + 4, cx - 4, top + 9, robeLight)
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 5, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 6, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 7, 1, 2, eye)
            r(fx + (side == 1 and 1 or 0), top + 6, 3, 1, P.bone) -- testa
        else
            p({cx - 5, top + 3, cx - 2, top - 1, cx + 4, top - 1, cx + 7,
                top + 4, cx + 6, top + 12, cx - 4, top + 13}, P.ink)
            p({cx - 4, top + 3, cx - 2, top, cx + 4, top, cx + 6, top + 4,
                cx + 5, top + 11, cx - 3, top + 12}, hood)
            p({cx + 2, top, cx + 5, top + 3, cx + 5, top + 10, cx + 2,
                top + 11}, robeDeep)
            l(cx - 3, top + 4, cx - 4, top + 10, robeLight)
            faceDraw(r, l, cx - 3, top + 4, 7, 7, eye, cfg.expr)
        end
        if aim then
            local ax = cx + (side ~= 0 and side or 1) * 9
            l(ax, top + 4, ax + (side ~= 0 and side or 1) * 3, top + 12, trim)
            l(ax + (side ~= 0 and side or 1) * 3, top + 12, ax, top + 22, trim)
            r(ax - 1, top + 21, 2, 2, P.ink)                  -- coronha
        end
    elseif build == 'loader' then
        -- SOWER: barril baixo de pano + cesto de vime fundido à barra —
        -- trama do cesto lê em crosshatch, sementes na borda.
        local top = 12 + bob + squat
        r(cx - 6 - stL, 38 + stL, 4, 6 - stL, P.ink)
        r(cx + 3 + stR, 38 + stR, 4, 6 - stR, P.ink)
        r(cx - 5 - stL, 38 + stL, 3, 4 - stL, robeDark)
        r(cx + 3 + stR, 38 + stR, 3, 4 - stR, robeDeep)
        p({cx - 9, top + 8, cx + 9, top + 8, cx + 11, 39, cx - 11, 39}, P.ink)
        p({cx - 8, top + 9, cx + 8, top + 9, cx + 10, 38, cx - 10, 38}, robe)
        p({cx - 8, top + 9, cx - 3, top + 9, cx - 6, 38, cx - 10, 38}, robeLight)
        p({cx + 4, top + 9, cx + 8, top + 9, cx + 10, 38, cx + 6, 38}, robeDeep)
        l(cx - 7, top + 12, cx - 8, 34, robeLight)            -- prega do pano
        r(cx - 9, 36, 18, 2, robeDark)
        r(cx - 4, top + 20, 9, 1, trimDark); r(cx, top + 20, 2, 1, trim)
        -- Suspensório do cesto cruzando o peito.
        l(cx - 4, top + 10, cx + 5, top + 24, trimDark)
        -- Cesto na frente-abaixo: crosshatch de vime + borda enrolada +
        -- grãos dourados derramando.
        local bs = side ~= 0 and side or (south and 1 or -1)
        local kx = cx + bs * 11
        p({kx - 5, 27, kx + 5, 27, kx + 7, 33, kx + 6, 42, kx - 6, 42,
            kx - 7, 33}, P.ink)
        p({kx - 4, 28, kx + 4, 28, kx + 6, 33, kx + 5, 41, kx - 5, 41,
            kx - 6, 33}, P.rust)
        p({kx - 3, 29, kx + 1, 29, kx + 3, 33, kx - 1, 33, kx - 5, 31}, P.goldDark)
        -- Trama do vime: diagonais cruzadas sobre o fundo.
        l(kx - 4, 30, kx + 4, 38, P.goldDeep); l(kx - 2, 28, kx + 5, 35, P.goldDeep)
        l(kx + 4, 30, kx - 4, 38, P.goldDeep); l(kx + 5, 33, kx - 1, 40, P.goldDeep)
        l(kx - 5, 33, kx + 5, 33, P.ink); l(kx - 5, 37, kx + 5, 37, P.ink)
        l(kx - 4, 28, kx + bs * -6, top + 14, P.goldDark)     -- alça ao ombro
        r(kx + 1, 25, 2, 2, P.goldLight); r(kx - 2, 26, 1, 1, P.goldLight)
        r(kx + 3, 24, 1, 1, P.gold)                           -- grão solto
        -- Cabeça baixa sob capuz amplo.
        p({cx - 7, top + 4, cx - 3, top - 1, cx + 4, top - 1, cx + 8, top + 5,
            cx + 6, top + 12, cx - 6, top + 12}, P.ink)
        p({cx - 6, top + 4, cx - 3, top, cx + 4, top, cx + 7, top + 5,
            cx + 5, top + 11, cx - 5, top + 11}, hood)
        p({cx - 6, top + 4, cx - 3, top, cx - 1, top + 1, cx - 3, top + 8,
            cx - 5, top + 11}, robeLight)
        l(cx + 2, top + 1, cx + 5, top + 6, robeDeep)         -- sombra do aro
        if north then
            p({cx - 6, top + 4, cx - 3, top, cx + 4, top, cx + 7, top + 5,
                cx + 5, top + 11, cx - 5, top + 11}, hood)
            l(cx - 4, top + 2, cx + 2, top + 2, robeDeep)
        elseif side ~= 0 then
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 5, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 6, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 7, 1, 2, eye)
            r(fx + (side == 1 and 1 or 0), top + 9, 3, 1, P.bone) -- sorriso
        else
            faceDraw(r, l, cx - 3, top + 4, 7, 7, eye, cfg.expr)
        end
        if aim then r(cx + 7, top + 14, 3, 6, robeDark)
            r(cx + 7, top + 14, 3, 1, trim)
            r(cx + 8, top + 19, 1, 2, P.goldLight)            -- punhado de grão
        end
    elseif build == 'needle' then
        -- WATCHER: agulha espectral — coluna que afunila, barra
        -- desfiada em tiras, sombra de voo dithered no chão.
        local top = 6 + bob + squat
        p({cx - 6, top + 12, cx + 5, top + 12, cx + 7, 30, cx + 2, 43,
            cx - 4, 43, cx - 8, 30}, P.ink)
        p({cx - 5, top + 13, cx + 4, top + 13, cx + 6, 30, cx + 1, 42,
            cx - 3, 42, cx - 7, 30}, robe)
        p({cx - 5, top + 13, cx - 1, top + 13, cx - 4, 40, cx - 6, 30}, robeLight)
        p({cx + 1, top + 13, cx + 4, top + 13, cx + 6, 30, cx + 2, 40}, robeDeep)
        l(cx - 1, top + 16, cx - 2, 40, robeDark)
        -- Tiras da barra: dois fiapos pendendo do ponto de flutuação.
        l(cx - 5, 36, cx - 6 + cape, 42, robeDark)
        l(cx + 4, 34, cx + 5 + cape, 40, robeDeep)
        r(cx - 2, 41, 3, 1, robeDark)
        -- Sombra de voo: o corpo não toca — lê-se pelo buraco de luz.
        d(cx - 5, 44, 10, 2, P.ink, .35)
        -- Capuz-agulha: pico alto, costura do vértice, orifício estreito.
        p({cx - 5, top + 5, cx - 1, top - 1, cx + 1, top - 6, cx + 4, top - 1,
            cx + 6, top + 6, cx + 4, top + 13, cx - 4, top + 13}, P.ink)
        p({cx - 4, top + 5, cx - 1, top, cx + 1, top - 5, cx + 3, top,
            cx + 5, top + 6, cx + 3, top + 12, cx - 3, top + 12}, hood)
        l(cx - 4, top + 5, cx - 1, top, robeLight)
        l(cx + 1, top - 4, cx + 2, top + 3, robeDeep)          -- costura do pico
        if north then
            p({cx - 4, top + 5, cx - 1, top, cx + 1, top - 5, cx + 3, top,
                cx + 5, top + 6, cx + 3, top + 12, cx - 3, top + 12}, hood)
            l(cx, top - 1, cx + 1, top + 8, robeDeep)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 4
            r(ex, top + 5, 4, 5, P.ink); r(ex + (side == 1 and 1 or 0),
                top + 6, 3, 3, eye)
            r(ex + (side == 1 and 1 or 0), top + 6, 1, 1, P.ink)
        else
            local wide = aim and 1 or 0
            r(cx - 3, top + 6, 7, 5 + wide, P.ink)
            r(cx - 2, top + 7, 5, 3 + wide, eye)
            r(cx, top + 7, 1, 3 + wide, P.ink)
            r(cx - 1, top + 7, 1, 1, P.white)
            r(cx - 2, top + 8, 1, 1, P.white)                  -- brilho duplo
        end
        if aim then l(cx - 3, top + 1, cx + 4, top + 1, eye) end
    elseif build == 'regal' then
        -- REGENT: manto de patamares + coroa de três dentes + mão de
        -- comando com anel — o mais largo do elenco.
        local top = 6 + bob + squat
        r(cx - 7 - stL, 38 + stL, 5, 6 - stL, P.ink)
        r(cx + 4 + stR, 38 + stR, 5, 6 - stR, P.ink)
        r(cx - 6 - stL, 38 + stL, 3, 4 - stL, robeDark)
        r(cx + 5 + stR, 38 + stR, 3, 4 - stL, robeDeep)
        p({cx - 13, top + 10, cx + 13, top + 10, cx + 14, 39, cx - 14, 39},
            P.ink)
        p({cx - 12, top + 11, cx + 12, top + 11, cx + 13, 38, cx - 13, 38}, robe)
        p({cx - 12, top + 11, cx - 5, top + 11, cx - 9, 38, cx - 13, 38}, robeLight)
        p({cx + 6, top + 11, cx + 12, top + 11, cx + 13, 38, cx + 8, 38}, robeDeep)
        l(cx - 12, top + 11, cx + 12, top + 11, trim)
        l(cx - 8, top + 16, cx - 10, 37, robeDark)
        l(cx + 2, top + 15, cx + 3, 36, robeDark)
        -- Segundo patamar: degrau do manto com filete próprio.
        p({cx - 10, top + 20, cx + 10, top + 20, cx + 11, 34, cx - 11, 34}, P.ink)
        p({cx - 9, top + 21, cx + 9, top + 21, cx + 10, 33, cx - 10, 33}, robeDark)
        l(cx - 9, top + 21, cx + 9, top + 21, robeDeep)
        r(cx - 12, 36, 24, 2, robeDark)
        l(cx - 12, 36, cx + 12, 36, trimDark)
        -- Estola cerimonial descendo o peito em dois filetes.
        if not north then
            p({cx - 4, top + 11, cx - 1, top + 11, cx - 2, 35, cx - 5, 35}, trim)
            p({cx + 1, top + 11, cx + 4, top + 11, cx + 5, 35, cx + 2, 35}, trimDark)
            r(cx - 4, 33, 3, 2, trimDark); r(cx + 2, 33, 3, 2, trim)
        end
        -- Mão aberta em gesto de comando + ANEL na falange.
        local gs = side ~= 0 and side or (south and 1 or -1)
        local gx = cx + gs * 14
        r(gx - 1, top + 14, 3, 8, robeDark)
        l(gx, top + 15, gx, top + 20, robeDeep)                -- vinco da manga
        r(gx - 2, top + (aim and 8 or 12), 4, 4, skin)
        l(gx - 1, top + (aim and 8 or 12), gx - 2, top + (aim and 5 or 10), P.bone)
        l(gx + 1, top + (aim and 8 or 12), gx + 2, top + (aim and 6 or 10), P.bone)
        r(gx, top + (aim and 10 or 14), 1, 1, trimLight)       -- anel
        p({cx - 6, top + 3, cx - 2, top - 1, cx + 3, top - 1, cx + 7, top + 4,
            cx + 5, top + 12, cx - 5, top + 12}, P.ink)
        p({cx - 5, top + 3, cx - 2, top, cx + 3, top, cx + 6, top + 4,
            cx + 4, top + 11, cx - 4, top + 11}, hood)
        l(cx - 4, top + 4, cx - 5, top + 10, robeLight)
        if north then
            p({cx - 5, top + 3, cx - 2, top, cx + 3, top, cx + 6, top + 4,
                cx + 4, top + 11, cx - 4, top + 11}, hood)
            l(cx - 3, top + 2, cx + 3, top + 2, robeDeep)
        elseif side ~= 0 then
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 4, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 5, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 6, 1, 2, eye)
        else
            faceDraw(r, l, cx - 3, top + 3, 7, 7, eye, cfg.expr)
        end
        -- Coroa: três dentes sobre o capuz, pedra central.
        for _, dx in ipairs({-4, 0, 4}) do
            l(cx + dx, top - 1, cx + dx, top - 4, trim)
            r(cx + dx - 1, top - 5, 2, 2, trimDark)
        end
        l(cx - 4, top - 1, cx + 4, top - 1, trimDark)
        r(cx, top - 3, 1, 1, eye)
        if aim then r(gx - 1, top + (aim and 6 or 10), 1, 1, eye) end
    else
        -- VETERAN (block): coluna larga — costuras de campanha, atadura
        -- de joelho, aljava atrás do ombro e arco erguido com corda.
        local top = 7 + bob + squat
        r(cx - 6 - stL, 37 + stL, 4, 7 - stL, P.ink)
        r(cx + 3 + stR, 37 + stR, 4, 7 - stR, P.ink)
        r(cx - 5 - stL, 37 + stL, 3, 5 - stL, robeDark)
        r(cx + 3 + stR, 37 + stR, 3, 5 - stL, robeDeep)
        r(cx - 5 - stL, 39 + stL, 3, 1, trimDark)              -- atadura
        r(cx + 3 + stR, 39 + stR, 3, 1, trimDark)
        p({cx - 10, top + 8, cx + 10, top + 8, cx + 10, 38, cx - 10, 38}, P.ink)
        p({cx - 9, top + 9, cx + 9, top + 9, cx + 9, 37, cx - 9, 37}, robe)
        p({cx - 9, top + 9, cx - 3, top + 9, cx - 6, 37, cx - 9, 37}, robeLight)
        p({cx + 5, top + 9, cx + 9, top + 9, cx + 9, 37, cx + 6, 37}, robeDeep)
        l(cx - 8, top + 12, cx - 9, 33, robeLight)             -- vinco do ombro
        r(cx - 9, 35, 18, 2, robeDark)
        -- Costuras de reparo da campanha + remendo de pano cru.
        l(cx - 4, top + 16, cx - 2, top + 26, robeDeep)
        r(cx + 2, top + 14, 3, 3, P.boneDark); r(cx + 2, top + 14, 3, 1, P.bone)
        r(cx - 8, top + 22, 16, 2, trimDark); r(cx - 8, top + 22, 12, 1, trim)
        r(cx + 6, top + 22, 2, 2, trim)                        -- fivela
        -- Bandoleira na diagonal + cartucheira de virotes.
        l(cx - 7, top + 10, cx + 6, top + 32, trimDark)
        r(cx + 3, top + 26, 4, 4, P.ink); r(cx + 4, top + 27, 2, 2, P.bone)
        -- Aljava atrás do ombro esquerdo + arco vertical à direita.
        if not north then
            r(cx - 11, top + 6, 4, 12, P.ink); r(cx - 10, top + 7, 2, 10, trimDark)
            l(cx - 12, top + 2, cx - 11, top + 7, P.bone)
            l(cx - 10, top + 1, cx - 10, top + 6, P.bone)
            l(cx - 12, top + 2, cx - 11, top + 1, P.white)
            l(cx - 10, top + 1, cx - 9, top, P.white)
            l(cx - 9, top + 8, cx - 9, top + 12, P.bone)       -- empunhadura
        else
            r(cx - 11, top + 6, 4, 12, P.ink); r(cx - 10, top + 7, 2, 10, trimDark)
            l(cx - 12, top + 2, cx - 11, top + 7, P.bone)
        end
        local bx = cx + 11
        l(bx - 1, top - 1, bx + 1, top + 8, trimDark)
        l(bx + 1, top + 8, bx + 2, top + 22, trim)
        l(bx + 2, top + 22, bx, top + 34, trimDark)
        l(bx - 1, top - 1, bx - 2, top + 16, P.bone)
        l(bx - 2, top + 16, bx - 1, top + 34, P.bone)          -- corda inteira
        r(bx - 1, top + 20, 3, 2, skin)
        r(bx - 1, top + 19, 3, 1, P.bone)                      -- dedos da corda
        -- Cabeça: capuz quadrado, rosto aberto gasto, cicatriz de ficha.
        p({cx - 6, top + 3, cx - 2, top - 1, cx + 3, top - 1, cx + 6, top + 3,
            cx + 5, top + 12, cx - 5, top + 12}, P.ink)
        p({cx - 5, top + 3, cx - 2, top, cx + 3, top, cx + 5, top + 4,
            cx + 4, top + 11, cx - 4, top + 11}, hood)
        p({cx + 2, top, cx + 5, top + 4, cx + 4, top + 10, cx + 2, top + 10},
            robeDeep)
        l(cx - 4, top + 4, cx - 5, top + 10, robeLight)
        if north then
            l(cx - 3, top + 2, cx + 2, top + 2, robeDeep)
            l(cx - 1, top + 4, cx - 2, top + 9, robeDeep)
        elseif side ~= 0 then
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 4, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 5, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 6, 1, 2, eye)
            l(fx + (side == 1 and 1 or 0), top + 5, fx + (side == 1 and 3 or -1),
                top + 7, P.ink)                                -- cicatriz
        else
            faceDraw(r, l, cx - 3, top + 3, 7, 7, eye, cfg.expr)
            l(cx + 2, top + 4, cx + 3, top + 6, P.ink)         -- cicatriz
        end
    end
    -- Trama do hábito: urdume escuro no pano e sombra de barra sobre
    -- as pernas.
    if build ~= 'wisp' and action ~= 'death' then
        l(cx - 5, 37, cx + 5, 37, robeDeep)
        l(cx - 4, 39, cx + 4, 39, P.ink)
    end
end

-- Rastejante: massa horizontal baixa de seis patas, cabeça projetada à
-- frente com mandíbulas e olhos de brasa — corpo de criatura, não robe.
local function crawler(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local bob, leg, cape, lean, squat = pose(action, frame)
    local east, south, west, north = direction == 1, direction == 2,
        direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local cx, top = 16 + side * lean, 19 + bob + squat
    if action == 'death' and frame >= 3 then
        -- Casco tombado de lado: ventre claro à mostra, patas curvadas
        -- para cima — a derrota do inseto lê na barriga exposta.
        p({cx - 12, 41, cx - 8, 34, cx + 8, 34, cx + 12, 41}, P.ink)
        p({cx - 11, 40, cx - 7, 35, cx + 7, 35, cx + 11, 40}, P.jadeDeep)
        p({cx - 10, 39, cx - 6, 35, cx - 1, 35, cx - 4, 39}, P.jadeDark)
        l(cx - 8, 37, cx + 6, 37, P.jadeMid)                    -- filete ventral
        r(cx - 8, 38, 3, 1, P.jade); r(cx + 4, 37, 4, 1, P.jade)
        for _, s in ipairs({-1, 1}) do for i = 0, 2 do
            l(cx + s * (5 + i * 4), 34, cx + s * (6 + i * 4), 30 - i, P.ink)
        end end
        return
    end
    -- Seis patas de três segmentos: coxa subindo do casco, tíbia caindo,
    -- tarso fino com garra de pedra. Passo alterna os trípodes.
    for _, s in ipairs({-1, 1}) do
        local lift = (s == -1) == (leg >= 0) and math.min(2, math.abs(leg)) or 0
        for i, dx in ipairs({6, 10, 14}) do
            local liftI = math.floor(lift + (i - 1) * .5)
            local kneeX = cx + s * (dx - 1)
            l(cx + s * (dx - 5), top + 8, kneeX, top + 6 - liftI, P.ink)
            l(kneeX, top + 6 - liftI, cx + s * dx, top + 15 - liftI, P.ink)
            l(cx + s * dx, top + 15 - liftI, cx + s * dx + s, top + 20 - liftI,
                P.ink)
            r(cx + s * dx + (s == 1 and 0 or -1), top + 19 - liftI, 2, 1,
                P.stoneDark)
        end
    end
    -- Sombra de corrida sob o casco: o bicho flutua baixo, não cola.
    d(cx - 10, top + 17, 20, 3, P.jadeDeep, .5)
    -- Abdômen segmentado atrás: três gomos menores + cerco na ponta —
    -- de norte é o que se vê primeiro.
    local rear = -side
    if north then rear = 0 end
    p({cx + rear * 8 - 3, top + 4, cx + rear * 13 - 1, top + 7,
        cx + rear * 13, top + 12, cx + rear * 7, top + 13}, P.ink)
    p({cx + rear * 8 - 2, top + 5, cx + rear * 12 - 1, top + 8,
        cx + rear * 12, top + 11, cx + rear * 7, top + 12}, P.jadeDark)
    l(cx + rear * 9, top + 6, cx + rear * 9, top + 12, P.jadeDeep)
    l(cx + rear * 11, top + 7, cx + rear * 11, top + 12, P.jadeDeep)
    if north then
        r(cx - 2, top + 1, 4, 3, P.ink); r(cx - 1, top + 2, 2, 1, P.jadeMid)
    end
    -- Carapaça: domo de três placas — luz de loma à esquerda, saia
    -- ventral em escama, fendas de placa no lombo.
    p({cx - 13, top + 9, cx - 8, top + 2, cx + 7, top + 2, cx + 13, top + 8,
        cx + 12, top + 16, cx - 12, top + 16}, P.ink)
    p({cx - 12, top + 9, cx - 7, top + 3, cx + 7, top + 3, cx + 12, top + 8,
        cx + 11, top + 15, cx - 11, top + 15}, P.jadeDark)
    p({cx - 11, top + 9, cx - 7, top + 4, cx - 2, top + 4, cx - 5, top + 13,
        cx - 11, top + 13}, P.jadeMid)
    p({cx - 6, top + 3, cx - 2, top + 3, cx - 3, top + 13, cx - 6, top + 13},
        P.jade)
    p({cx + 5, top + 4, cx + 10, top + 8, cx + 10, top + 14, cx + 4, top + 14},
        P.jadeDeep)
    l(cx - 10, top + 9, cx - 7, top + 4, P.jadeLight)
    l(cx - 6, top + 3, cx - 2, top + 3, P.jadeLight)            -- reborde do lombo
    l(cx - 1, top + 3, cx - 2, top + 14, P.ink)                 -- fenda de placa
    l(cx + 5, top + 3, cx + 4, top + 14, P.ink)
    d(cx - 4, top + 5, 4, 8, P.jadeMid, .35)
    d(cx - 10, top + 11, 21, 4, P.jadeDeep, .4)
    l(cx - 11, top + 14, cx + 11, top + 14, P.stoneDeep)        -- saia ventral
    -- Escamas da saia: três dentes baixos sob a linha ventral.
    r(cx - 8, top + 15, 2, 1, P.jadeMid); r(cx - 1, top + 15, 2, 1, P.jadeMid)
    r(cx + 6, top + 15, 2, 1, P.jadeMid)
    -- Espinhos da crista: três pontas de casco no dorso.
    l(cx - 6, top + 3, cx - 6, top, P.jadeLight); l(cx, top + 3, cx, top, P.jadeLight)
    l(cx + 6, top + 3, cx + 6, top, P.jadeLight)
    -- Trincas de casco trabalhado.
    l(cx - 8, top + 6, cx - 6, top + 11, P.ink)
    l(cx + 2, top + 5, cx + 3, top + 10, P.jadeMid)
    l(cx - 2, top + 7, cx - 3, top + 11, P.jadeDeep)
    -- Cabeça: projetada para a direção encarada — mandíbula de dois
    -- segmentos, cluster de três olhos de brasa, palpos curtos.
    local hx = side ~= 0 and cx + side * 13 or cx
    local hy = north and top + 1 or south and top + 14 or top + 8
    if not north then
        p({hx - 4, hy - 4, hx + 3, hy - 4, hx + 5 + side, hy, hx + 3, hy + 6,
            hx - 4, hy + 6, hx - 5 + side, hy}, P.ink)
        p({hx - 3, hy - 3, hx + 2, hy - 3, hx + 4 + side, hy, hx + 2, hy + 5,
            hx - 3, hy + 5, hx - 4 + side, hy}, P.jadeDark)
        l(hx - 3, hy - 3, hx + 1, hy - 3, P.jadeMid)            -- testa lavada
        -- Palpos curtos à frente do focinho.
        l(hx + side * 4, hy - 2, hx + side * 6, hy - 4, P.ink)
        l(hx + side * 5, hy + 1, hx + side * 7, hy, P.ink)
        -- Mandíbula articulada: articulação + ponta afastada.
        l(hx + side * 3, hy + 5, hx + side * 5, hy + 7, P.ink)
        l(hx + side * 5, hy + 7, hx + side * 7, hy + 6, P.stoneDark)
        l(hx - 1 + side * 3, hy + 5, hx - 2 + side * 4, hy + 7, P.ink)
        local eyH = action == 'warn' and 3 or action == 'hurt' and 1 or 2
        r(hx - 2 + side * 2, hy - 2, 2, eyH, P.ember)
        r(hx + 1 + side * 2, hy - 2, 1, eyH, P.ember)
        r(hx - 2 + side * 2, hy - 2, 1, 1, P.emberLight)
        r(hx + 1 + side * 2, hy - 2, 1, 1, P.emberLight)
        r(hx - 1 + side * 1, hy + 1, 1, 1, P.ember)             -- terceiro olho
        if action == 'hurt' then
            l(hx - 2 + side * 2, hy - 3, hx + 1 + side * 2, hy - 3, P.ink)
        end
        if action == 'warn' then
            l(hx - 1 + side * 4, hy + 4, hx + side * 7, hy + 8, P.white)
        end
    else
        -- De costas a cabeça some sob o casco — ficam os cercos.
        r(cx - 5, top, 10, 4, P.ink); r(cx - 4, top + 1, 8, 2, P.jadeDark)
        r(cx - 4, top, 2, 1, P.jade); r(cx + 2, top, 2, 1, P.jade)
    end
    if action == 'warn' then r(cx - 3, top + 1, 6, 2, P.danger) end
end

-- Eco nascente: mortalha flutuante que nunca toca o chão. O capuz tombado
-- segue a direção — de frente o rosto oco é escancarado, de perfil vira
-- uma janela lateral no pano, de costas o pano fecha sem cara.
local function husk(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local drift = frame % 2 == 0 and -1 or 0
    local side = direction == 1 and 1 or direction == 3 and -1 or 0
    local south, north = direction == 2, direction == 4
    local cx = 16
    if action == 'death' and frame >= 3 then
        -- A mortalha esvazia no chão: pano aberto, trapos espalhados.
        p({cx - 10, 40, cx - 6, 35, cx + 6, 35, cx + 10, 40}, P.ink)
        p({cx - 9, 40, cx - 5, 36, cx + 5, 36, cx + 9, 40}, P.goldDark)
        p({cx - 4, 39, cx + 3, 37, cx + 7, 41, cx - 6, 41}, P.rust)
        l(cx - 7, 38, cx - 2, 40, P.goldDeep)
        l(cx + 1, 37, cx + 5, 41, P.ink)
        r(cx - 1, 36, 3, 2, P.jade); return
    end
    local top = 8 + drift
    local hem = 38 + drift
    -- Três painéis de pano: esquerdo lavado pela lua, direito em
    -- ferrugem funda — as fendas de tinta entre eles dão a camada.
    p({cx - 5, top + 13, cx + 5, top + 13, cx + 7, 24, cx + 4, hem,
        cx - 4, hem, cx - 7, 24}, P.ink)
    p({cx - 4, top + 14, cx + 4, top + 14, cx + 6, 24, cx + 3, hem - 1,
        cx - 3, hem - 1, cx - 6, 24}, P.goldDark)
    p({cx - 4, top + 14, cx, top + 14, cx - 2, 25, cx - 4, hem - 1,
        cx - 6, 24}, P.gold)
    p({cx + 1, top + 14, cx + 4, top + 14, cx + 5, 25, cx + 3, hem - 1,
        cx + 1, hem - 1}, P.rust)
    -- Fendas entre painéis: o pano é feito de tiras costuradas.
    l(cx - 1, top + 15, cx - 2, hem - 4, P.ink)
    l(cx + 2, top + 16, cx + 2, hem - 6, P.goldDeep)
    l(cx - 4, top + 18, cx - 5, hem - 5, P.goldDeep)
    -- Trama da mortalha + prega central.
    d(cx - 4, 26, 8, 10, P.goldDeep, .25)
    l(cx - 3, 24, cx - 4, hem - 2, P.goldDeep)
    -- Barra desfiada: tiras individuais tombando contra o encarado.
    local sway = -side * 2 - drift
    l(cx - 4, hem - 2, cx - 6 + sway, hem + 2, P.ink)
    l(cx - 1, hem - 1, cx - 1 + sway, hem + 3, P.ink)
    l(cx + 3, hem - 2, cx + 5 + sway, hem + 2, P.ink)
    l(cx - 4, hem - 2, cx - 5 + sway, hem + 1, P.goldDark)
    l(cx - 1, hem - 1, cx - 1 + sway, hem + 2, P.gold)
    l(cx + 3, hem - 2, cx + 4 + sway, hem + 1, P.rust)
    l(cx + 1, hem - 3, cx + 2 + sway, hem, P.goldDeep)
    -- Capuz pontudo tombado na direção encarada, com vinco de dobra.
    local tip = side * 4
    p({cx - 5, top + 9, cx - 2, top - 1, cx + 3 + tip, top - 5,
        cx + 6 + tip, top + 4, cx + 5, top + 13, cx - 4, top + 13}, P.ink)
    p({cx - 4, top + 9, cx - 2, top + 1, cx + 3 + tip, top - 4,
        cx + 5 + tip, top + 4, cx + 4, top + 12, cx - 3, top + 12}, P.goldDark)
    p({cx - 4, top + 9, cx - 2, top + 1, cx + 1 + tip, top - 3, cx + 1,
        top + 12}, P.gold)
    l(cx - 2, top + 2, cx + 2 + tip, top + 5, P.goldDeep)       -- vinco do capuz
    if north then
        l(cx - 3, top + 4, cx + 3, top + 4, P.goldDeep)
        l(cx - 2, top + 8, cx + 2, top + 8, P.goldDeep)
        d(cx - 3, top + 3, 6, 8, P.ink, .25)
        l(cx, top + 5, cx - 1, top + 11, P.rust)                -- prega traseira
    elseif side ~= 0 then
        local jx = side == 1 and cx + 1 or cx - 5
        r(jx, top + 5, 5, 6, P.ink)
        r(jx + 1, top + 6, 3, 4, P.goldDeep)
        r(jx + (side == 1 and 2 or 0), top + 6, 1, 2, P.emberLight)
        r(jx + (side == 1 and 2 or 0), top + 9, 2, 1, P.goldDeep)
        r(jx + 1, top + 6, 3, 1, P.rust)                        -- aro da janela
    else
        r(cx - 2, top + 6, 4, 6, P.ink)
        local tall = action == 'warn' and 3 or action == 'hurt' and 1 or 2
        r(cx - 2, top + 7, 1, tall, P.emberLight)
        r(cx + 1, top + 7, 1, tall, P.ember)
        if action == 'hurt' then
            r(cx - 1, top + 10, 2, 2, P.goldDeep)
        else
            r(cx - 1, top + 10, 2, 1, P.goldDeep)
        end
    end
    -- Faixa de pano voando atrás + fiapo desfeito pendurado.
    l(cx - 5, top + 15, cx - 9 + sway, top + 19, P.ink)
    l(cx - 5, top + 15, cx - 8 + sway, top + 18, P.goldDark)
    l(cx + 5, top + 17, cx + 7 + sway, top + 22, P.rust)
    if frame % 4 == 3 then
        l(cx - 1, top + 16, cx - 2, 25, P.emberLight)
        l(cx + 2, top + 18, cx + 1, 28, P.ember)
        r(cx + 3, 23, 1, 1, P.goldLight)
    end
    if action == 'warn' then
        l(cx - 3 + tip, top - 5, cx + 3 + tip, top - 5, P.emberLight)
        r(cx - 1 + tip, top - 7, 2, 1, P.white)
    end
end

-- Casulo do eco nascente (batalha: e.hatch > 0): a mortalha enrolada em
-- fardo — corpo contornado e FECHADO, sem janela de rosto. Laços de pano
-- cruzam o ventre e um núcleo âmbar pulsa por dentro: dorme, e o brilho é
-- a contagem da eclosão. A troca de sheet acontece em sheetOf — o painter
-- não conhece a entidade.
local function huskCocoon(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local cx = 16
    if action == 'death' and frame >= 3 then
        p({cx - 10, 40, cx - 6, 35, cx + 6, 35, cx + 10, 40}, P.ink)
        p({cx - 9, 40, cx - 5, 36, cx + 5, 36, cx + 9, 40}, P.goldDark)
        l(cx - 6, 38, cx + 5, 37, P.rust)
        l(cx - 2, 39, cx + 2, 36, P.goldDeep)
        return
    end
    local bob = action == 'move' and (({1, -1, -2, -2, -1, 1})[frame] or 0)
        or (frame % 3 == 0 and -1 or 0)
    local top = 9 + bob
    p({cx - 2, top, cx + 2, top, cx + 5, top + 5, cx + 6, 22,
        cx + 4, 37, cx - 4, 37, cx - 6, 22, cx - 5, top + 5}, P.ink)
    p({cx - 1, top + 1, cx + 1, top + 1, cx + 4, top + 5, cx + 5, 22,
        cx + 3, 36, cx - 3, 36, cx - 5, 22, cx - 4, top + 5}, P.goldDark)
    p({cx - 1, top + 1, cx, top + 1, cx - 3, top + 5, cx - 4, 22,
        cx - 2, 35, cx - 4, 35, cx - 6, 22, cx - 4, top + 5}, P.gold)
    p({cx + 1, top + 2, cx + 3, top + 5, cx + 4, 22, cx + 2, 35, cx + 1, 35},
        P.rust)
    -- Costuras verticais do enrolado: o fardo é pano em volta de algo.
    l(cx - 3, top + 6, cx - 4, 30, P.goldDeep)
    l(cx + 3, top + 7, cx + 3, 32, P.goldDeep)
    d(cx - 4, top + 8, 4, 20, P.goldDeep, .2)
    -- Núcleo âmbar sob os laços: pulsa devagar — a eclosão dormindo.
    local glow = action == 'warn' and .8 or frame % 2 == 0 and .65 or .35
    d(cx - 2, 20, 5, 4, P.ember, glow * .5)
    r(cx - 1, 21, 3, 2, P.ember)
    r(cx, 21, 1, 1, glow > .5 and P.white or P.emberLight)
    -- Laços de pano: três faixas cruzando o ventre + nó lateral; a
    -- luz vaza nas bordas da faixa do meio.
    l(cx - 5, top + 9, cx + 5, top + 9, P.ink)
    l(cx - 4, top + 10, cx + 4, top + 10, P.rust)
    l(cx - 6, 26, cx + 6, 26, P.ink)
    l(cx - 5, 27, cx + 5, 27, P.rust)
    l(cx - 5, 27, cx - 4, 27, P.emberLight)
    l(cx - 5, 32, cx + 5, 32, P.ink)
    l(cx - 4, 33, cx + 4, 33, P.rust)
    r(cx + 5, 25, 2, 2, P.goldDark)
    r(cx + 5, 26, 2, 1, P.gold)                               -- nó lateral
    if action == 'hurt' then
        l(cx - 2, 14, cx + 2, 18, P.emberLight)
        l(cx - 3, 15, cx - 1, 17, P.ember)
    end
end

-- Skins do bruto e dos devotos — mesma geometria, identidade pela rampa.
local sentinelSkins = {
    dasher = {build = 'brute'},
    breaker = {cape = P.violetDark, capeLine = P.violet, shell = P.stone,
        shellHi = P.stoneLight, body = P.stoneDark, bodyDark = P.stoneDark,
        trim = P.rust, trimDark = P.stoneDark, trimLight = P.gold,
        eye = P.danger, eyeLow = P.rust, build = 'bull'},
    demolisher = {cape = P.violetDark, capeLine = P.stoneDark, shell = P.stoneDark,
        shellHi = P.stone, body = P.stone, bodyDark = P.ink,
        trim = P.goldDark, trimDark = P.ink, trimLight = P.gold,
        eye = P.danger, eyeLow = P.rust, build = 'ruin'},
    warden = {cape = P.violetDark, capeLine = P.violet, shell = P.stoneLight,
        shellHi = P.stoneEdge, body = P.stone, bodyDark = P.stoneDark,
        trim = P.gold, trimDark = P.goldDark, trimLight = P.goldLight,
        eye = P.violetLight, eyeLow = P.violet, build = 'tower'},
}

local zealotSkins = {
    ranger = {robe = P.violetDark, robeLight = P.violet, robeDark = P.stoneDark,
        robeDeep = P.violetDeep, hood = P.violetDark, eye = P.goldLight,
        trim = P.gold, trimDark = P.goldDark, build = 'scout',
        skin = P.bone, expr = 'stern'},
    veteran = {robe = P.violet, robeLight = P.violetLight, robeDark = P.violetDark,
        robeDeep = P.violetDeep, hood = P.violetDark, eye = P.jadeLight,
        trim = P.jade, trimDark = P.jadeDark, build = 'block',
        skin = P.bone, expr = 'worn'},
    sower = {robe = P.goldDark, robeLight = P.gold, robeDark = P.rust,
        robeDeep = P.goldDeep, hood = P.rust, eye = P.emberLight,
        trim = P.goldLight, trimDark = P.goldDark, build = 'loader',
        skin = P.bone, expr = 'kind'},
    watcher = {robe = P.violetDark, robeLight = P.violet, robeDark = P.stoneDark,
        robeDeep = P.violetDeep, hood = P.violetDark, eye = P.violetLight,
        trim = P.violet, trimDark = P.violetDark, build = 'needle'},
    regent = {robe = P.rust, robeLight = P.goldDark, robeDark = P.ink,
        robeDeep = P.goldDeep, hood = P.goldDark, eye = P.danger,
        trim = P.goldLight, trimDark = P.gold, build = 'regal',
        skin = P.bone, expr = 'stern'},
}

-- Amâncio, o mercador: barriga redonda e pernas curtas — o corpo é uma
-- esfera sentada de pano quente — fardo assimétrico nas costas, cara
-- aberta de olhos miúdos e barba cerrada. Nunca um robe genérico.
local function merchant(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local east, south, west = direction == 1, direction == 2, direction == 3
    local side = east and 1 or west and -1 or 0
    local bob = ({0, -1, 0, 0})[frame]
    local cx = 16
    local top = 9 + bob                      -- barriga alta, pernas curtas
    -- Perninhas de mesa: pés pequenos mal saem da barriga.
    r(cx - 5, 41 + bob, 4, 3, P.ink); r(cx + 2, 41 + bob, 4, 3, P.ink)
    if direction == 4 then
        -- Costas: a torre de carga domina — fardo grande em cima, trouxa
        -- embaixo, correias de ouro cruzando.
        p({cx - 6, top + 4, cx + 7, top + 4, cx + 9, 40, cx - 9, 40}, P.ink)
        p({cx - 5, top + 5, cx + 6, top + 5, cx + 8, 39, cx - 8, 39}, P.goldDark)
        r(cx - 4, top + 8, 9, 3, P.gold)
        l(cx - 5, top + 10, cx + 4, 38, P.rust)
        p({cx - 7, top - 6, cx + 4, top - 6, cx + 6, top + 4, cx - 9, top + 4}, P.ink)
        p({cx - 6, top - 5, cx + 3, top - 5, cx + 5, top + 3, cx - 8, top + 3}, P.rust)
        l(cx - 6, top - 5, cx - 8, top + 3, P.gold)
        r(cx - 4, top - 8, 4, 3, P.goldDark); r(cx - 3, top - 7, 2, 1, P.goldLight)
    else
        -- Barriga esférica: contorno de tinta largo, pano quente, cinto
        -- de ouro apertado — o mercador é a esfera da procissão.
        p({cx - 8, top + 8, cx + 8, top + 8, cx + 10, 40 + bob, cx - 10, 40 + bob}, P.ink)
        p({cx - 7, top + 9, cx + 7, top + 9, cx + 9, 39 + bob, cx - 9, 39 + bob}, P.rust)
        p({cx - 7, top + 9, cx - 2, top + 9, cx - 4, 39 + bob, cx - 8, 39 + bob}, P.goldDark)
        r(cx - 8, top + 20, 16, 3, P.goldDark); r(cx - 1, top + 20, 3, 3, P.goldLight)
        -- Fardo tombado para trás e trouxa no ombro — eixo quebrado.
        p({cx - 9 + side * 2, top - 2, cx - 1 + side * 2, top - 2, cx + side * 2, top + 8,
            cx - 10 + side * 2, top + 8}, P.ink)
        p({cx - 8 + side * 2, top - 1, cx - 2 + side * 2, top - 1, cx - 1 + side * 2, top + 7,
            cx - 9 + side * 2, top + 7}, P.rust)
        r(cx - 8 + side * 2, top - 1, 4, 1, P.gold)
        -- Trama do pano quente + sombra de barra sobre as perninhas.
        d(cx - 6, top + 24, 13, 12, P.goldDeep, .15)
        l(cx - 7, 38 + bob, cx + 7, 38 + bob, P.goldDeep)
        if south then
            r(cx + 6, top + 10, 5, 5, P.ink); r(cx + 7, top + 11, 3, 3, P.goldDark)
            l(cx + 4, top + 9, cx + 8, top + 12, P.goldDark)
        end
        -- Cabeça: capuz-cabeção aberto — rosto redondo de osso, olhos
        -- miúdos de ouro, barba na borda da cavidade.
        p({cx - 6, top - 4, cx - 3, top - 8, cx + 3, top - 8, cx + 6, top - 3, cx + 5, top + 6,
            cx - 5, top + 6}, P.ink)
        p({cx - 5, top - 3, cx - 3, top - 7, cx + 3, top - 7, cx + 5, top - 2, cx + 4, top + 5,
            cx - 4, top + 5}, P.goldDark)
        if south then
            faceDraw(r, l, cx - 3, top - 2, 6, 6, P.goldLight, 'kind')
            r(cx - 2, top + 4, 5, 2, P.rust)   -- barba
        else
            r(cx + side * 2 - 1, top - 1, 4, 5, P.boneDark)
            r(cx + side * 2, top - 1, 3, 1, P.bone)
            r(cx + side * 2 + (side == 1 and 1 or -1), top + 1, 1, 1, P.goldLight)
        end
    end
end

-- Odete, a guardiã: anciã ARQUEADA — a coluna tombada à frente sobre o
-- bastão-lanterna que a apoia. Silhueta: corcova + bengala com lampião
-- pendente. O rosto pálido espreita debaixo do capuz baixo.
local function keeper(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local east, south, west = direction == 1, direction == 2, direction == 3
    local side = east and 1 or west and -1 or 0
    local bob = ({0, 0, -1, 0})[frame]
    local cx = 16
    local top = 10 + bob
    -- Pés curtos sob a veste.
    r(cx - 4, 41 + bob, 3, 3, P.ink); r(cx + 2, 41 + bob, 3, 3, P.ink)
    -- Veste comprida tombada para a frente: a coluna curva — ombros
    -- à frente do quadril, corcova no dorso.
    p({cx - 5, top + 10, cx + 6, top + 9, cx + 8, 43, cx - 7, 43}, P.ink)
    p({cx - 4, top + 11, cx + 5, top + 10, cx + 7, 42, cx - 6, 42}, P.jadeDark)
    p({cx - 4, top + 11, cx, top + 10, cx - 1, 42, cx - 5, 42}, P.jade)
    l(cx + 3, top + 12, cx + 5, 40, P.jadeDeep)
    d(cx - 4, top + 18, 8, 18, P.jadeDeep, .2)
    l(cx - 5, 39 + bob, cx + 5, 39 + bob, P.jadeDeep)
    r(cx - 6, 40 + bob, 13, 2, P.jade)
    -- Corcova atrás: massa do capote tombando à frente.
    if direction ~= 4 then
        p({cx - 6, top + 4, cx - 3, top, cx + 2, top - 1, cx + 6, top + 3, cx + 5, top + 10,
            cx - 5, top + 11}, P.ink)
        p({cx - 5, top + 5, cx - 2, top + 1, cx + 2, top, cx + 5, top + 4, cx + 4, top + 10,
            cx - 4, top + 10}, P.jadeDark)
        if south then
            faceDraw(r, l, cx - 2, top + 2, 6, 6, P.jadeLight, 'kind')
        else
            r(cx + side * 2 - 2, top + 3, 4, 5, P.boneDark)
            r(cx + side * 2 - 2, top + 3, 3, 1, P.bone)
            r(cx + side * 3 - 1, top + 5, 1, 1, P.jadeLight)
        end
    else
        -- De costas: capote fechado, corcova arredondada visível.
        p({cx - 6, top + 4, cx - 3, top, cx + 2, top - 1, cx + 6, top + 3, cx + 5, top + 10,
            cx - 5, top + 11}, P.ink)
        p({cx - 5, top + 5, cx - 3, top + 1, cx + 2, top, cx + 5, top + 4, cx + 4, top + 10,
            cx - 4, top + 10}, P.jadeDark)
        l(cx - 4, top + 6, cx + 3, top + 5, P.jade)
    end
    -- Bastão-lanterna: apoio à frente, gancho pendente com lampião.
    local lx = south and cx + 11 or cx + side * 10
    l(cx + side * 4, top + 16, lx, top + 2, P.goldDark)
    l(cx + side * 4, top + 16, cx + side * 5, top + 18, P.bone)
    l(lx, top + 2, lx - (south and 5 or side * 4), top + 2, P.goldDark)
    local hx = lx - (south and 5 or side * 4)
    l(hx, top + 2, hx, top + 7, P.goldDark)
    r(hx - 2, top + 7, 5, 6, P.goldDark); r(hx - 1, top + 8, 3, 4, P.jade)
    r(hx, top + 9, 1, 2, P.jadeLight)
end

-- Ofício dos figurantes: bob de tarefa por act — martelo cai pesado no
-- impacto, criança quica atrás da bola, ofício de mão embala a cadência.
local function workBob(act, frame)
    if act == 'hammer' or act == 'chop' then return frame > 2 and 1 or 0 end
    if act == 'play' then return ({0, -2, 0, -1})[frame] end
    if act == 'wash' or act == 'stir' or act == 'fill' then return frame % 2 end
    return ({0, -1, 0, 0})[frame]
end

--====================================================================--
-- ITER9 — "MAIS PIXEL": a régua do Viajante desce para todo o elenco.
-- Pessoa vestida = peça em rampa (base+light+dark+filete), textura
-- assada (trama, vinco, brilho de couro), sombra de FORMA (lado claro
-- e escuro, degrau sob o queixo, barra sobre a canela) e rosto de
-- ficha (nariz, sobrancelha, boca, cabelo com direção). Helpers aqui;
-- corpos por `pal.body` abaixo — nenhum pano em bloco único.
--====================================================================--

-- Mistura ancorada na paleta: a luz e a sombra de cada peça derivam do
-- tom-base do morador — rampa por material sem inventar cor solta.
local function mixc(c, t, to)
    local o = to or P.ink
    return {c[1] + (o[1] - c[1]) * t, c[2] + (o[2] - c[2]) * t,
        c[3] + (o[3] - c[3]) * t}
end

-- Bloco vestido numa chamada: tom de base + filete de luz no topo +
-- sombra de barra — a peça ganha rampa sem repetir três retângulos.
local function shade(r, x, y, w, h, tone, shadow, edge)
    r(x, y, w, h, tone)
    if edge and h > 1 then r(x, y, w, 1, edge) end
    if shadow and h > 2 then r(x, y + h - 1, w, 1, shadow) end
end

-- Rosto frontal de ficha: testa lavada, poços de olho com íris,
-- sobrancelha, dorso e base de nariz, boca — os adornos ficam por fora
-- do rosto, nunca por cima dos traços.
local function faceNpc(r, l, x, y, w, h, skin, skinHi, skinLo, eye)
    r(x, y, w, h, skin)
    r(x, y, w, 1, skinHi)
    r(x, y + h - 1, w, 1, skinLo)
    local eL, eR = x + 1, x + w - 3
    local mx = x + math.floor(w / 2)
    r(eL, y + 2, 2, 1, P.ink); r(eR, y + 2, 2, 1, P.ink)
    r(eL, y + 3, 2, 2, P.ink); r(eR, y + 3, 2, 2, P.ink)
    r(eL, y + 3, 1, 1, eye); r(eR, y + 3, 1, 1, eye)
    r(mx, y + 4, 1, 2, skinLo); r(mx - 1, y + 5, 3, 1, skinLo)
    r(mx - 1, y + h - 2, 3, 1, skinLo)
end

-- Perfil de ficha: olho e sobrancelha encarados, nariz saliente na
-- borda, boca curta — a nuca fica para o cabelo de cada body.
local function faceNpcSide(r, l, x, y, w, h, s, skin, skinHi, skinLo, eye)
    r(x, y, w, h, skin)
    r(x, y, w, 1, skinHi)
    r(x, y + h - 1, w, 1, skinLo)
    local ex = s == 1 and x + w - 3 or x + 1
    r(ex, y + 2, 2, 1, P.ink); r(ex, y + 3, 2, 2, P.ink)
    r(ex, y + 3, 1, 1, eye)
    r(s == 1 and x + w - 1 or x, y + 4, 1, 2, skinLo)
    r(s == 1 and x + w - 2 or x + 1, y + 5, 1, 1, skinLo)
    r(s == 1 and x + w - 3 or x + 2, y + h - 2, 2, 1, skinLo)
end

-- Rosto de retrato (>=15px): a cabeça deixa de ser 'placa + 2 pixels' —
-- silhueta com queixo afunilado, linha do cabelo irregular, dois olhos
-- com poço+íris+pálpebra (1px de sombra sobre a íris), sobrancelha em
-- arco, nariz com dorso+base+sombra lateral e boca de 3-4px por emoção.
-- Cada estado dobra sobrancelha + olho + boca + tom de pele — lê
-- diferente a 1x. Pensada para ~16x25; C = {skin, skinHi, skinLo, hair,
-- eye, lip, bare}.
facePortrait = function(r, l, x, y, w, h, C, expr)
    local skin = C.skin or P.boneDark
    if expr == 'fear' then skin = mixc(skin, .32, P.white)
    elseif expr == 'anger' then skin = mixc(skin, .3, P.rust) end
    local skinHi = C.skinHi or mixc(skin, .3, P.white)
    local skinLo = C.skinLo or mixc(skin, .35)
    local deep = mixc(skinLo, .5)
    local hair = C.hair or P.ink
    local eye = C.eye or P.jadeLight
    local lip = C.lip or mixc(skin, .5, P.rust)
    local mx = x + math.floor(w / 2)
    local exL, exR = x + 3, x + w - 6     -- poços de 3px simétricos
    local browY, eyeY = y + 6, y + 9      -- 1px de pele entre arco e pálpebra
    local mY = y + h - 7
    -- OSSATURA por ficha: a silhueta do crânio muda antes de pele e
    -- cabelo — faixas {linha_inicial, inset} do topo ao queixo.
    -- 'round' guarda a massa nas maçãs com queixo curto; 'angular'
    -- afunila cedo num queixo pontudo; 'long' emagrece o rosto
    -- inteiro sob testa alta; 'rect' é o bloco largo de queixo
    -- quase reto; 'square' traz testa mais estreita que a mandíbula
    -- cheia; 'oval' segue o molde de repouso (PERSONAGENS por ficha).
    local shape = C.shape or 'oval'
    local bands
    if shape == 'round' then
        bands = {{0, 1}, {2, 0}, {h - 4, 0}, {h - 2, 1}, {h - 1, 3}}
    elseif shape == 'angular' then
        bands = {{0, 1}, {h - 7, 1}, {h - 5, 2}, {h - 3, 4}, {h - 1, 5}}
    elseif shape == 'long' then
        bands = {{0, 1}, {h - 6, 2}, {h - 4, 3}, {h - 2, 4}}
    elseif shape == 'rect' then
        bands = {{0, 0}, {h - 4, 1}, {h - 1, 2}}
    elseif shape == 'square' then
        bands = {{0, 1}, {3, 0}, {h - 3, 0}, {h - 1, 2}}
    else
        bands = {{0, 0}, {h - 5, 1}, {h - 3, 2}, {h - 1, 3}}
    end
    for i, b in ipairs(bands) do
        local y0, ins = y + b[1], b[2]
        local y1 = bands[i + 1] and y + bands[i + 1][1] or y + h
        r(x + ins, y0, w - ins * 2, y1 - y0, P.ink)
        r(x + ins + 1, y0, w - ins * 2 - 2, y1 - y0, skin)
    end
    -- Luz do alto à esquerda: testa lavada, lateral direita em sombra.
    r(x + 1, y + 3, w - 2, 2, skinHi)
    r(x + w - 2, y + 5, 1, h - 12, skinLo)
    -- Marca de ossatura: maçãs iluminadas no 'round', canto do
    -- maxilar sombreado em 'square'/'rect' — o formato lê-se sem
    -- contar a borda da silhueta.
    if shape == 'round' then
        r(x + 2, eyeY + 4, 2, 1, skinHi); r(x + w - 4, eyeY + 4, 2, 1, skinHi)
    elseif shape == 'square' or shape == 'rect' then
        r(x + 1, y + h - 6, 2, 1, skinLo); r(x + w - 3, y + h - 6, 2, 1, skinLo)
    end
    if not C.bare then
        -- Linha do cabelo irregular descendo na testa; o rosto 'long'
        -- recua a linha — a testa alta faz parte da ossatura.
        r(x + 1, y + 1, w - 2, 1, hair)
        if shape == 'long' then
            r(x + 1, y + 2, 2, 1, hair); r(x + w - 3, y + 2, 2, 1, hair)
        else
            r(x + 1, y + 2, 3, 1, hair); r(x + 5, y + 2, 4, 1, hair)
            r(x + 10, y + 2, w - 11, 1, hair)
        end
    end
    -- Olhos: poço de tinta + íris da ficha + pálpebra. O medo abre a
    -- cavidade escura com pálpebra tensa e íris miúda; o espanto é
    -- olho INTEIRO — esclera clara cercando a íris pequena. Alegria/
    -- calma/fechamento caem a pálpebra; a vergonha desvia a íris.
    if expr == 'fear' then
        r(exL - 1, eyeY - 1, 4, 3, P.ink); r(exR, eyeY - 1, 4, 3, P.ink)
        r(exL + 1, eyeY, 1, 2, eye); r(exR + 1, eyeY, 1, 2, eye)
    elseif expr == 'awe' then
        r(exL - 1, eyeY - 1, 4, 3, P.white); r(exR, eyeY - 1, 4, 3, P.white)
        r(exL, eyeY, 2, 1, eye); r(exR + 1, eyeY, 2, 1, eye)
    else
        r(exL, eyeY - 1, 3, 1, skinLo); r(exR, eyeY - 1, 3, 1, skinLo)
        r(exL, eyeY, 3, 2, P.ink); r(exR, eyeY, 3, 2, P.ink)
        local ix = expr == 'shame' and 2 or 1
        r(exL + ix, eyeY, 1, 2, eye); r(exR + ix, eyeY, 1, 2, eye)
        if expr == 'joy' or expr == 'soft' or expr == 'kind'
            or expr == 'stern' or expr == 'sad' or expr == 'worn' then
            -- Pálpebra caída cobre a metade de cima do poço.
            r(exL, eyeY - 1, 3, 1, skinLo); r(exL, eyeY, 3, 1, skinLo)
            r(exR, eyeY - 1, 3, 1, skinLo); r(exR, eyeY, 3, 1, skinLo)
        end
    end
    if expr == 'anger' then
        -- Pálpebra em viés caindo para dentro: estreita o poço.
        r(exL + 2, eyeY - 1, 1, 2, skinLo); r(exR, eyeY - 1, 1, 2, skinLo)
    end
    if expr == 'sad' or expr == 'worn' then
        -- Sombra sob o olho: o cansaço lê-se embaixo, não dentro.
        r(exL, eyeY + 2, 3, 1, skinLo); r(exR, eyeY + 2, 3, 1, skinLo)
    end
    -- Sobrancelha na cor do cabelo — arco de repouso, cada emoção dobra.
    if expr == 'anger' then
        l(exL - 1, browY - 1, exL + 2, browY + 1, hair)
        l(exR + 3, browY - 1, exR, browY + 1, hair)
    elseif expr == 'stern' then
        l(exL - 1, browY, exL + 2, browY + 1, hair)
        l(exR + 3, browY, exR, browY + 1, hair)
    elseif expr == 'sad' or expr == 'worn' then
        l(exL - 1, browY + 1, exL + 2, browY - 1, hair)
        l(exR + 3, browY + 1, exR, browY - 1, hair)
    elseif expr == 'fear' then
        r(exL - 1, browY - 1, 5, 1, hair); r(exR - 1, browY - 1, 5, 1, hair)
    elseif expr == 'awe' then
        -- Assombro: arco alto COMPLETO — sobrancelha ergue 2px no
        -- cume e desce nos cantos, flutuando sobre o olho inteiro.
        r(exL, browY - 3, 3, 1, hair); r(exR, browY - 3, 3, 1, hair)
        r(exL - 1, browY - 2, 1, 2, hair); r(exL + 3, browY - 2, 1, 2, hair)
        r(exR - 1, browY - 2, 1, 2, hair); r(exR + 3, browY - 2, 1, 2, hair)
    elseif expr == 'shame' then
        r(exL, browY + 1, 3, 1, hair); r(exR, browY + 1, 3, 1, hair)
    elseif expr == 'joy' or expr == 'soft' or expr == 'kind' then
        r(exL - 1, browY, 1, 1, hair); r(exL, browY - 1, 3, 1, hair)
        r(exL + 3, browY, 1, 1, hair)
        r(exR - 1, browY, 1, 1, hair); r(exR, browY - 1, 3, 1, hair)
        r(exR + 3, browY, 1, 1, hair)
    else
        r(exL - 1, browY + 1, 1, 1, hair); r(exL, browY, 3, 1, hair)
        r(exL + 3, browY + 1, 1, 1, hair)
        r(exR - 1, browY + 1, 1, 1, hair); r(exR, browY, 3, 1, hair)
        r(exR + 3, browY + 1, 1, 1, hair)
    end
    -- Nariz: cume à luz, dorso em sombra, asas laterais e narinas na base.
    r(mx - 1, eyeY + 1, 1, 3, skinHi)
    r(mx, eyeY + 1, 1, 4, skinLo)
    r(mx - 2, eyeY + 4, 1, 2, skinLo); r(mx + 1, eyeY + 4, 1, 2, skinLo)
    r(mx - 2, eyeY + 5, 1, 1, deep); r(mx + 1, eyeY + 5, 1, 1, deep)
    r(mx - 1, eyeY + 5, 2, 1, skinLo)
    -- Boca: 3-4px por emoção — nunca a linha única de antes.
    if expr == 'joy' then
        -- Sorriso aberto em arco: cantos sobem, fileira de dente.
        r(mx - 4, mY - 1, 1, 1, lip); r(mx + 3, mY - 1, 1, 1, lip)
        r(mx - 3, mY, 7, 3, P.ink); r(mx - 2, mY, 5, 1, P.bone)
    elseif expr == 'sad' then
        -- Cantos caídos: o arco inverte sob a linha de repouso.
        r(mx - 2, mY, 5, 1, lip)
        r(mx - 3, mY + 1, 1, 1, lip); r(mx + 3, mY + 1, 1, 1, lip)
    elseif expr == 'stern' then
        r(mx - 3, mY, 7, 1, P.ink)
    elseif expr == 'soft' or expr == 'kind' then
        -- Boca leve: cantos sobem um pixel, linha curta e clara.
        r(mx - 3, mY - 1, 1, 1, lip); r(mx + 3, mY - 1, 1, 1, lip)
        r(mx - 2, mY, 5, 1, lip)
    elseif expr == 'fear' then
        r(mx - 1, mY, 3, 2, P.ink)
    elseif expr == 'anger' then
        -- Linha apertada + dente rangendo + bochecha em brasa.
        r(mx - 3, mY, 7, 1, P.ink)
        r(mx - 1, mY - 1, 1, 1, P.bone); r(mx + 1, mY - 1, 1, 1, P.bone)
        local blush = mixc(skin, .5, P.ember)
        r(exL, mY - 4, 2, 1, blush); r(exR + 1, mY - 4, 2, 1, blush)
    elseif expr == 'shame' then
        -- Boca miúda apertada — some junto com o olhar.
        r(mx, mY, 3, 1, lip)
    elseif expr == 'awe' then
        -- 'o' definido: abertura redonda alta com lábio nos cantos —
        -- assombro, não o espasmo achatado do medo.
        r(mx - 1, mY - 2, 3, 4, P.ink)
        r(mx - 2, mY - 1, 1, 2, lip); r(mx + 2, mY - 1, 1, 2, lip)
    elseif expr == 'worn' then
        r(mx - 2, mY, 5, 1, deep); r(mx - 2, mY + 1, 5, 1, skinLo)
    else
        -- Repouso: linha de lábio com canto sombreado.
        r(mx - 2, mY, 5, 1, lip)
        r(mx - 3, mY - 1, 1, 1, skinLo); r(mx + 3, mY - 1, 1, 1, skinLo)
    end
    -- Sombra sob a boca + fundo do queixo em degrau.
    r(mx - 2, mY + 3, 4, 1, skinLo)
    r(x + 4, y + h - 2, w - 8, 1, skinLo)
end

-- Rosto residente na cavidade de tinta da moldura (capuz, véu, gola):
-- mesma casa do faceDraw + anatomia de ficha — nariz com dorso e base,
-- sobrancelha na cor do cabelo, boca — na pele do morador em rampa.
local function faceRes(r, l, x, y, w, h, C, expr)
    if w >= 15 and h >= 18 then
        return facePortrait(r, l, x, y, w, h, C, expr)
    end
    r(x, y, w, h, P.ink)
    r(x + 1, y + 1, w - 2, h - 1, C.skin)
    r(x + 1, y + 1, w - 2, 1, C.skinHi)
    r(x + 1, y + h - 1, w - 2, 1, C.skinLo)
    local eL, eR = x + 1, x + w - 3
    local mx = x + math.floor(w / 2)
    r(eL, y + 2, 2, 1, C.hair); r(eR, y + 2, 2, 1, C.hair)
    r(eL, y + 3, 2, 2, P.ink); r(eR, y + 3, 2, 2, P.ink)
    r(eL, y + 3, 1, 1, C.eye); r(eR, y + 3, 1, 1, C.eye)
    r(mx, y + 4, 1, 1, C.skinLo); r(mx - 1, y + h - 2, 3, 1, C.skinLo)
    if expr == 'stern' then
        l(eL - 1, y + 1, eL + 2, y + 1, P.ink); l(eR - 1, y + 1, eR + 2, y + 1, P.ink)
        r(mx - 1, y + h - 2, 3, 1, P.ink)
    elseif expr == 'kind' then
        r(eL, y + 5, 1, 1, C.skinHi); r(eR + 1, y + 5, 1, 1, C.skinHi)
    elseif expr == 'worn' then
        l(eL, y + 5, eL, y + 6, P.ink)
    end
end

-- Canela + sapato sob a barra: coluna da calça com vinco de costura,
-- polaina por fora quando pedida e bota de ponteira iluminada — a peça
-- de cima deixa a sombra da barra sobre elas.
local function npcFeet(r, cx, y0, pants, boots, wrap, hemShadow)
    r(cx - 5, y0, 4, 44 - y0, P.ink); r(cx + 2, y0, 4, 44 - y0, P.ink)
    r(cx - 4, y0, 3, 41 - y0, pants); r(cx + 3, y0, 3, 41 - y0, pants)
    if hemShadow then r(cx - 4, y0, 3, 1, hemShadow); r(cx + 3, y0, 3, 1, hemShadow) end
    if wrap then for wy = y0 + 2, 38, 2 do
        r(cx - 4, wy, 3, 1, wrap); r(cx + 3, wy, 3, 1, wrap)
    end end
    r(cx - 5, 41, 5, 3, P.ink); r(cx + 1, 41, 5, 3, P.ink)
    r(cx - 4, 41, 3, 2, boots); r(cx + 2, 41, 3, 2, boots)
    r(cx - 4, 41, 1, 1, mixc(boots, .45, P.white)); r(cx + 2, 41, 1, 1, mixc(boots, .45, P.white))
end

-- Tronco vestido compartilhado: trapézio com rampa (luz à esquerda,
-- sombra à direita), trama pontilhada da lã, barra sombreada e cinto
-- com fivela opcional — o esqueleto vestido dos corpos de ofício.
local function garmentNpc(C, halfW, hemY, opt)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    p({cx - halfW, top + 10, cx + halfW, top + 10,
        cx + halfW + 1, hemY, cx - halfW - 1, hemY}, P.ink)
    p({cx - halfW + 1, top + 11, cx + halfW - 1, top + 11,
        cx + halfW, hemY - 1, cx - halfW, hemY - 1}, C.cloth)
    p({cx - halfW + 1, top + 11, cx - halfW + 3, top + 11,
        cx - halfW + 3, hemY - 1, cx - halfW, hemY - 1}, C.clothHi)
    p({cx + halfW - 3, top + 11, cx + halfW - 1, top + 11,
        cx + halfW, hemY - 1, cx + halfW - 2, hemY - 1}, C.clothLo)
    d(cx - halfW + 3, top + 15, halfW * 2 - 6, hemY - top - 19, C.clothLo, .15)
    r(cx - halfW, hemY - 2, halfW * 2, 1, C.clothLo)
    if opt and opt.belt then
        r(cx - halfW + 1, hemY - 5, halfW * 2 - 2, 2, opt.belt)
        r(cx - 1, hemY - 5, 2, 2, opt.buckle or P.goldLight)
    end
end

-- Dois braços descidos: manga da peça com vinco de cotovelo + mão de
-- pele — usado quando o corpo não está no gesto de ofício.
local function armsIdle(C, y0, len)
    local r, cx, side, south = C.r, C.cx, C.side, C.south
    len = len or 11
    if side == 0 then
        r(cx - 10, y0, 3, len, P.ink); r(cx - 9, y0 + 1, 2, len - 3, C.cloth)
        r(cx - 9, y0 + len - 3, 2, 3, C.skin)
        r(cx + 7, y0, 3, len, P.ink); r(cx + 8, y0 + 1, 2, len - 3, C.clothLo)
        r(cx + 8, y0 + len - 3, 2, 3, C.skin)
    else
        local fx = cx + side * 6
        r(fx - 1, y0, 3, len, P.ink); r(fx, y0 + 1, 1, len - 3, C.cloth)
        r(fx, y0 + len - 3, 1, 3, C.skin)
        r(cx - side * 7, y0 + 1, 2, len - 2, C.clothLo)
        r(cx - side * 7, y0 + len - 2, 2, 2, C.skin)
    end
end

-- Gesto de ofício nos braços (act 'work'): substitui o bloco de braços de
-- repouso — a ferramenta e o movimento dizem o que o figurante faz.
local function workArms(r, l, p, cx, top, side, south, pal, frame)
    local act = pal.act or 'work'
    local skin = pal.skin or P.goldLight
    -- Atos de posto sem gesto próprio vestem o congênere mais próximo:
    -- encher água é a lavadeira na cisterna, ajudar é carregar junto.
    if act == 'fill' then act = 'wash' elseif act == 'help' then act = 'carry' end
    if act == 'hammer' or act == 'chop' then
        -- Golpe: o braço ergue nos dois primeiros quadros e cai no impacto.
        local sx = south and cx + 8 or cx + side * 7
        local hy = frame <= 2 and top - 1 or top + 13
        l(cx + side * 4, top + 13, sx, hy, skin)
        if act == 'hammer' then
            r(sx - 2, hy - 4, 5, 4, P.stoneDark); r(sx - 2, hy - 4, 5, 1, P.stoneLight)
        else
            r(sx - 1, hy - 2, 4, 6, P.ink); r(sx, hy - 1, 2, 4, P.stoneLight)
        end
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'watch' then
        -- Pala da mão na testa medindo o vale; o outro braço repousa.
        local sx = south and cx + 6 or cx + side * 5
        l(cx + side * 4, top + 13, sx, top + 3, skin)
        r(sx - 1, top + 1, 4, 3, skin)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'carry' then
        -- Fardo no ombro de trás: a trouxa tombada quebra o topo do corpo.
        local bx = cx - side * 3
        r(bx - 3, top - 2, 9, 7, P.ink)
        r(bx - 2, top - 1, 7, 5, pal.hair)
        r(bx - 2, top - 1, 7, 1, pal.accent)
        l(cx - side * 4, top + 11, bx + 1, top + 1, pal.cloth)
        r(cx + side * 6 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'wash' then
        -- Peça torcida entre as duas mãos à frente, pano pingando ao quadril.
        r(cx - 4, top + 14, 9, 5, P.ink)
        r(cx - 3, top + 15, 7, 3, pal.cloth)
        r(cx - 2, top + 15, 2, 2, P.white)
        r(cx + 1, top + 16, 3, 1, P.jadeLight)
        l(cx - 6, top + 11, cx - 4, top + 15, pal.cloth)
        l(cx + 6, top + 11, cx + 4, top + 15, pal.cloth)
    elseif act == 'play' then
        -- Bola quicando na frente — a criança corre atrás dela.
        local bx = cx + (frame % 2 == 0 and 9 or -8)
        local by = 35 - (frame % 3) * 4
        r(bx - 1, by, 4, 4, P.ink); r(bx, by + 1, 2, 2, pal.accent)
        r(cx + side * 6 - 1, top + 11, 3, 9, pal.cloth)
        l(cx - side * 5, top + 12, cx - side * 8, top + 6, skin)
    elseif act == 'stir' then
        -- Colher de pau girando no tacho: a mão descreve um círculo curto.
        local a = frame / 4 * 6.283
        local hx = cx + math.floor(math.cos(a) * 4 + .5)
        local hy = top + 15 + math.floor(math.sin(a) * 2 + .5)
        l(cx + side * 4, top + 13, hx, hy, skin)
        l(hx, hy, hx + 1, hy + 8, P.goldDark)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'teach' then
        -- Vara apontando o quadro à frente — o braço ergue a lição.
        local sx = south and cx + 9 or cx + side * 8
        l(cx + side * 4, top + 14, sx, top + 6, skin)
        l(sx, top + 6, sx + (south and 4 or side * 4), top - 5, P.bone)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'write' then
        -- Sabela: punho escrevendo — a mão desliza sobre a folha aberta
        -- à frente, pena inclinada; o outro braço segura o caderno.
        local px = south and cx - 3 or (side == 1 and cx + 5 or cx - 8)
        r(px, top + 20, 8, 5, P.ink)
        r(px + 1, top + 21, 6, 3, P.bone)
        local hx = px + 3 + (frame % 2 == 0 and 2 or 0)
        l(cx + (south and 2 or side * 3), top + 12, hx, top + 19, pal.cloth)
        r(hx - 1, top + 18, 3, 3, skin)
        l(hx + 1, top + 20, hx + 3, top + 16, P.ink)
        r(cx - (south and -4 or side * 7) - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'tinker' then
        -- Nilo: mãos pequenas na peça — as duas mãos sobem e descem
        -- alternadas ajustando a caixinha de madeira à frente do peito.
        local py = top + 16 + frame % 2
        r(cx - 3, py, 7, 5, P.ink)
        r(cx - 2, py + 1, 5, 3, P.goldDark)
        r(cx - 1, py + 1, 2, 2, P.gold); r(cx + 2, py + 2, 1, 1, P.ember)
        l(cx - 4, top + 12, cx - 4, py + 1, pal.cloth)
        r(cx - 6, py + (frame % 2), 3, 3, skin)
        l(cx + 4, top + 12, cx + 4, py + 1, pal.cloth)
        r(cx + 3, py + 1 - (frame % 2), 3, 3, skin)
    elseif act == 'tend' then
        -- Aurel: palma aberta sobre a pedra/muda — a mão desce e pousa;
        -- o outro braço recolhido respeita o que ele cuida.
        local drop = frame % 2 == 0 and 1 or 0
        local hx = south and cx + 6 or cx + side * 6
        l(cx + side * 4 - (south and 2 or 0), top + 12, hx, top + 17, pal.cloth)
        r(hx - 2, top + 16 + drop, 5, 3, skin)
        r(hx - 1, top + 16 + drop, 1, 1, P.bone)
        r(hx - 3, top + 22, 7, 5, P.ink)
        r(hx - 2, top + 23, 5, 3, P.stone)
        l(hx - 1, top + 23, hx - 2, top + 20, P.jadeDark)
        l(hx + 1, top + 23, hx + 2, top + 20, P.jade)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'inspect' then
        -- Brina: peça girada perto dos olhos — cotovelo fora, lima na
        -- outra mão baixa; a peça sobe e desce num quadro.
        local hx = south and cx + 5 or cx + side * 5
        l(cx + side * 5, top + 12, hx, top + 5, pal.skin)
        r(hx - 1, top + 3, 3, 3, pal.skin)
        r(hx - 1, top + 1 + (frame % 2), 3, 2, P.stoneLight)
        r(hx, top + 1 + (frame % 2), 1, 1, P.gold)
        l(cx - side * 5, top + 13, cx - side * 8, top + 20, pal.cloth)
        r(cx - side * 8 - 1, top + 20, 3, 2, pal.skin)
        l(cx - side * 8, top + 19, cx - side * 10, top + 23, P.stoneEdge)
    elseif act == 'serve' then
        -- Ema: pote recolhido da beirada — as duas mãos sob a borda.
        local py = top + 15 + (frame % 2)
        r(cx - 4, py, 9, 6, P.ink)
        r(cx - 3, py + 1, 7, 4, P.rust)
        r(cx - 3, py + 1, 7, 1, mixc(P.rust, .35, P.white))
        r(cx - 1, py - 1, 3, 1, P.ink)
        l(cx - 6, top + 12, cx - 4, py + 2, pal.cloth)
        r(cx - 5, py + 1, 2, 2, pal.skin)
        l(cx + 6, top + 12, cx + 4, py + 2, pal.cloth)
        r(cx + 3, py + 1, 2, 2, pal.skin)
    elseif act == 'tag' then
        -- Rute: etiqueta apresentada no lado certo — braço estende a
        -- cartela clara, lápis curto na mão recolhida.
        local hx = south and cx + 8 or cx + side * 8
        l(cx + side * 4, top + 13, hx, top + 10, pal.cloth)
        r(hx - 1, top + 8, 3, 3, pal.skin)
        r(hx + 1, top + 6, 4, 4, P.bone); r(hx + 1, top + 6, 4, 1, P.ink)
        l(cx - side * 5, top + 12, cx - side * 7, top + 20, pal.cloth)
        r(cx - side * 7 - 1, top + 20, 2, 2, pal.skin)
        l(cx - side * 7, top + 20, cx - side * 9, top + 16, P.gold)
    elseif act == 'weed' then
        -- Mara: mão baixa escolhendo a folha — a outra segura o cesto.
        local hx = south and cx + 7 or cx + side * 6
        local hy = top + 24 + (frame % 2)
        l(cx + side * 5, top + 14, hx, hy, pal.cloth)
        r(hx - 1, hy, 3, 2, pal.skin)
        l(hx + 1, hy, hx + 2, hy - 3, P.jade)
        l(hx + 2, hy - 3, hx + 4, hy - 4, P.jadeLight)
        local bx = cx - side * 8 - 3
        r(bx, top + 20, 7, 5, P.ink); r(bx + 1, top + 21, 5, 3, P.goldDark)
        r(bx + 1, top + 21, 5, 1, P.gold)
        l(cx - side * 4, top + 13, bx + 3, top + 21, pal.cloth)
    elseif act == 'tap' then
        -- Ivo: duas batidas de chave na peça — punho desce no impacto.
        local hx = south and cx + 7 or cx + side * 6
        local hy = frame <= 2 and top + 9 or top + 12
        l(cx + side * 4, top + 13, hx, hy, pal.cloth)
        r(hx - 1, hy - 1, 3, 3, pal.skin)
        l(hx + 1, hy, hx + 4, hy - 3, P.stoneEdge)
        r(hx + 3, hy - 5, 3, 3, P.ink); r(hx + 4, hy - 4, 1, 1, P.stoneEdge)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'host' then
        -- Beltran: braço varrendo a sala — manga-sino no fim do gesto.
        local hx = south and cx + 10 or cx + side * 9
        l(cx + side * 5, top + 13, hx, top + 8 + (frame % 2), pal.cloth)
        r(hx - 1, top + 5, 5, 5, pal.cloth)
        r(hx - 1, top + 5, 5, 1, mixc(pal.cloth, .3, P.white))
        r(hx, top + 3 + (frame % 2), 3, 3, pal.skin)
        local bx = cx - side * 7
        l(cx - side * 5, top + 13, bx, top + 15, pal.cloth)
        r(bx - 2, top + 14, 4, 6, P.ink); r(bx - 1, top + 15, 2, 4, P.bone)
    elseif act == 'strum' then
        -- Cira: caixa de cordas na diagonal — mão direita dedilha.
        local bx = south and cx - 6 or cx - side * 5
        local nx = south and cx + 6 or bx + side * 8 + 6
        p({bx - 2, top + 22, bx + 4, top + 20, bx + 6, top + 27, bx, top + 29}, P.ink)
        p({bx - 1, top + 23, bx + 3, top + 21, bx + 5, top + 26, bx + 1, top + 28}, P.goldDark)
        l(bx + 3, top + 22, nx, top + 10, P.goldDeep)
        r(nx - 1, top + 8, 3, 3, P.goldDeep)
        l(cx + side * 5, top + 12, bx + 2, top + 22 + (frame % 2), pal.skin)
        l(cx - side * 4, top + 12, nx, top + 10, pal.skin)
    else
        r(cx + side * 6, top + 11, 3, 14, pal.cloth)
    end
end

--====================================================================--
-- Núcleo do Refúgio — um corpo por pessoa, âncoras das fichas §3-9.
--====================================================================--

-- DORO §3 (wright): retângulo de ombros largos — camisa de linho cinza,
-- colete castanho de lã, avental de lona encerada com faixa diagonal
-- reforçada; cabeça raspada irregular e barba curta de prata e preto.
local function bodyWright(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local vest, vestLo = P.goldDeep, mixc(P.goldDeep, .5)
    local apron, apronLo, apronHi = P.goldDark, P.goldDeep, P.gold
    local pants, beard, beardLo = P.stoneDeep, C.hair, C.hairLo
    npcFeet(r, cx, 34, pants, P.goldDeep, nil, P.ink)
    -- Dorso largo: camisa nos ombros, colete de lã aberto sobre ela.
    p({cx - 9, top + 10, cx + 9, top + 10, cx + 8, 35, cx - 8, 35}, P.ink)
    p({cx - 8, top + 11, cx + 8, top + 11, cx + 7, 34, cx - 7, 34}, shirt)
    p({cx - 8, top + 11, cx - 5, top + 11, cx - 5, 34, cx - 7, 34}, shirtHi)
    p({cx + 4, top + 11, cx + 8, top + 11, cx + 7, 34, cx + 5, 34}, shirtLo)
    p({cx - 6, top + 12, cx - 2, top + 13, cx - 3, 26, cx - 6, 26}, vest)
    p({cx + 6, top + 12, cx + 2, top + 13, cx + 3, 26, cx + 6, 26}, vestLo)
    if not north then
        r(cx - 1, top + 12, 3, 1, P.ink)
        -- Avental de lona encerada: peito ao joelho, trama e barra gasta.
        p({cx - 6, top + 17, cx + 6, top + 17, cx + 7, 36, cx - 7, 36}, P.ink)
        p({cx - 5, top + 18, cx + 5, top + 18, cx + 6, 35, cx - 6, 35}, apron)
        d(cx - 4, top + 20, 8, 12, apronLo, .18)
        r(cx - 5, 34, 11, 1, apronLo)
        -- Faixa diagonal reforçada (âncora): ombro direito ao quadril.
        l(cx + 5, top + 18, cx - 4, 34, P.goldDeep)
        l(cx + 5, top + 17, cx - 4, 33, apronHi)
        r(cx - 5, 33, 2, 2, P.goldDeep)
        -- Bolso do pano limpo + lápis de carpinteiro achatado.
        r(cx + 3, top + 25, 3, 3, P.bone); r(cx + 3, top + 25, 3, 1, P.boneDark)
        r(cx - 6, top + 21, 1, 3, P.ember)
    else
        -- Costas: colete fechado, alça do avental cruzando o dorso.
        p({cx - 6, top + 12, cx + 6, top + 12, cx + 6, 26, cx - 6, 26}, vest)
        p({cx - 6, top + 12, cx - 3, top + 12, cx - 4, 26, cx - 6, 26}, vestLo)
        l(cx - 5, top + 13, cx + 4, 32, P.goldDeep)
        p({cx - 6, top + 27, cx + 6, top + 27, cx + 7, 36, cx - 7, 36}, P.ink)
        p({cx - 5, top + 28, cx + 5, top + 28, cx + 6, 35, cx - 6, 35}, apron)
        d(cx - 4, top + 29, 8, 5, apronLo, .18)
    end
    if C.act ~= 'work' then armsIdle(C, top + 13, 13) end
    -- Cabeça raspada + barba prata e preto fechando o queixo.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, skin)
        d(cx - 4, top + 1, 8, 6, skinLo, .25)
        r(cx - 5, top + 8, 1, 3, beard); r(cx + 4, top + 8, 1, 3, beard)
        r(cx - 2, top + 12, 5, 1, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        d(cx - 4, top + 1, 8, 3, skinLo, .2)
        r(fx + (side == 1 and 3 or -2), top + 8, 1, 4, beard)
        r(fx + (side == 1 and 1 or -3), top + 11, 3, 1, beard)
        r(cx - side * 5, top + 2, 2, 8, skin)
        d(cx - side * 5 - 1, top + 2, 3, 4, skinLo, .2)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        d(cx - 4, top + 1, 8, 3, skinLo, .2)
        -- Sobrancelhas grisalhas grossas + barba curta de prata e preto.
        r(cx - 3, top + 4, 2, 1, beard); r(cx + 2, top + 4, 2, 1, beard)
        r(cx - 4, top + 7, 1, 5, beard); r(cx + 4, top + 7, 1, 5, beard)
        r(cx - 3, top + 9, 2, 1, P.ink); r(cx + 2, top + 9, 2, 1, P.ink)
        r(cx - 3, top + 10, 6, 2, beard)
        r(cx - 1, top + 10, 2, 1, P.ink); r(cx - 2, top + 12, 4, 1, beardLo)
    end
end

-- RUNA §9 (sentry): esguia — camisa carvão e couro castanho sob manto
-- triangular curto de verde seco com forro palha, polainas claras e
-- trança ruiva única caindo baixa de um lado.
local function bodySentry(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cape, capeHi, capeLo = C.cloth, C.clothHi, C.clothLo
    local leather, leatherLo = P.goldDark, P.goldDeep
    local hair, hairLo = C.hair, C.hairLo
    -- Polainas claras (âncora): canela embrulhada sobre bota alta.
    npcFeet(r, cx, 33, P.bone, P.goldDeep, P.boneDark, P.ink)
    -- Peito de couro castanho sob o manto.
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 7, 34, cx - 7, 34}, P.ink)
    p({cx - 5, top + 12, cx + 5, top + 12, cx + 6, 33, cx - 6, 33}, P.stoneDeep)
    p({cx - 4, top + 13, cx + 4, top + 13, cx + 5, 32, cx - 5, 32}, leather)
    l(cx - 4, top + 14, cx + 3, top + 14, mixc(leather, .35, P.white))
    r(cx - 4, top + 21, 9, 2, leatherLo); r(cx - 4, top + 21, 6, 1, P.gold)
    -- Manto triangular curto (âncora): ombros abrindo até a cintura,
    -- ponta tombada para um lado, forro palha na borda.
    if north then
        p({cx - 8, top + 10, cx + 8, top + 10, cx + 5, top + 28, cx - 5, top + 28}, P.ink)
        p({cx - 7, top + 11, cx + 7, top + 11, cx + 4, top + 27, cx - 4, top + 27}, cape)
        p({cx - 7, top + 11, cx - 3, top + 11, cx - 2, top + 27, cx - 4, top + 27}, capeHi)
        l(cx - 4, top + 26, cx + 4, top + 26, P.boneDark)
    else
        p({cx - 8, top + 10, cx + 8, top + 10, cx + 7, top + 25, cx - 7, top + 25}, P.ink)
        p({cx - 7, top + 11, cx + 7, top + 11, cx + 6, top + 24, cx - 6, top + 24}, cape)
        p({cx - 7, top + 11, cx - 3, top + 11, cx - 2, top + 24, cx - 6, top + 24}, capeHi)
        p({cx + 4, top + 11, cx + 7, top + 11, cx + 6, top + 24, cx + 4, top + 24}, capeLo)
        l(cx - 6, top + 23, cx + 6, top + 23, P.boneDark)
        d(cx - 5, top + 13, 10, 8, capeLo, .15)
        -- Ponta do manto presa mais abaixo num lado (bico do triângulo).
        local tip = south and -1 or -side
        p({cx + tip * 5 - 1, top + 24, cx + tip * 3, top + 24, cx + tip * 6, top + 30}, cape)
        l(cx + tip * 5, top + 29, cx + tip * 3, top + 25, capeLo)
    end
    if C.act ~= 'work' then
        if south or side == 0 then
            -- Mãos compridas livres sob a borda do manto.
            r(cx - 8, top + 24, 2, 3, skin); r(cx + 6, top + 24, 2, 3, skin)
        else
            r(cx + side * 6 - 1, top + 20, 3, 7, P.stoneDeep)
            r(cx + side * 6 - 1, top + 26, 3, 2, skin)
        end
    end
    -- Cabeça: franja aparada sem linha perfeita + trança ruiva lateral.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        d(cx - 3, top + 2, 6, 9, hairLo, .25)
        -- A trança sobe de um lado e desce pelas costas em mecha única.
        r(cx - 1, top + 4, 3, 10, hair)
        l(cx, top + 5, cx, top + 13, hairLo); l(cx + 1, top + 5, cx + 1, top + 13, hairLo)
        r(cx - 1, top + 14, 3, 1, P.gold)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 4, hair)
        -- Trança atrás, caindo da nuca.
        local bx = cx - side * 5
        r(bx - 1, top + 4, 3, 10, hair); l(bx, top + 5, bx, top + 12, hairLo)
        r(bx - 1, top + 13, 3, 1, P.gold)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 4, top + 3, 2, 1, hair); r(cx + 1, top + 3, 1, 1, hair); r(cx + 3, top + 3, 2, 1, hair)
        r(cx - 5, top + 3, 1, 5, hair); r(cx + 4, top + 3, 1, 4, hair)
        -- Sardas esparsas nas maçãs.
        r(cx - 2, top + 7, 1, 1, skinLo); r(cx + 3, top + 8, 1, 1, skinLo)
        r(cx, top + 8, 1, 1, skinLo)
        -- Trança única baixa à sua direita.
        r(cx + 5, top + 4, 3, 10, hair)
        l(cx + 6, top + 5, cx + 6, top + 12, hairLo)
        r(cx + 5, top + 13, 3, 1, P.gold)
    end
end

-- BENTO §4 (stout): massa arredondada — camisa verde musgo e colete
-- vinho gasto sob avental cru quadrado de barra queimada; faixa de pano
-- clara no cabelo crespo e toalha caindo vertical de um ombro.
local function bodyStout(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local hair = C.hair
    npcFeet(r, cx, 37, P.goldDeep, P.ink, nil, P.ink)
    -- Barriga arredondada: camisa musgo + painéis de colete vinho.
    p({cx - 9, top + 11, cx + 9, top + 11, cx + 11, 39, cx - 11, 39}, P.ink)
    p({cx - 8, top + 12, cx + 8, top + 12, cx + 10, 38, cx - 10, 38}, shirt)
    p({cx - 8, top + 12, cx - 4, top + 12, cx - 6, 38, cx - 10, 38}, shirtHi)
    p({cx + 5, top + 12, cx + 8, top + 12, cx + 10, 38, cx + 7, 38}, shirtLo)
    if not north then
        p({cx - 8, top + 12, cx - 4, top + 13, cx - 5, 30, cx - 8, 31}, P.rust)
        p({cx + 8, top + 12, cx + 4, top + 13, cx + 5, 30, cx + 8, 31}, P.rust)
        l(cx - 8, top + 13, cx - 5, 30, mixc(P.rust, .35, P.white))
        -- Avental cru quadrado (âncora): alças ao pescoço, barra com
        -- queimaduras pequenas e remendo limpo.
        p({cx - 6, top + 15, cx + 6, top + 15, cx + 8, 38, cx - 8, 38}, P.ink)
        p({cx - 5, top + 16, cx + 5, top + 16, cx + 7, 37, cx - 7, 37}, P.bone)
        d(cx - 4, top + 18, 9, 15, P.boneDark, .12)
        l(cx - 4, top + 16, cx - 4, top + 12, P.boneDark)
        l(cx + 4, top + 16, cx + 4, top + 12, P.boneDark)
        r(cx - 5, 36, 11, 1, P.boneDark)
        r(cx - 3, 35, 1, 1, P.goldDeep); r(cx + 2, 34, 2, 1, P.goldDeep); r(cx + 5, 35, 1, 1, P.goldDeep)
        r(cx + 2, top + 24, 3, 3, P.boneDark); r(cx + 2, top + 24, 3, 1, P.bone)
        -- Toalha dobrada caindo vertical do ombro direito (âncora).
        r(cx + 6, top + 10, 4, 15, P.ink); r(cx + 7, top + 11, 2, 13, P.bone)
        r(cx + 7, top + 15, 2, 1, P.jadeDark); r(cx + 7, top + 18, 2, 1, P.jadeDark)
    else
        -- Costas: colete vinho inteiro + nó da faixa + toalha na lateral.
        p({cx - 8, top + 12, cx + 8, top + 12, cx + 9, 30, cx - 9, 30}, P.rust)
        p({cx - 8, top + 12, cx - 4, top + 12, cx - 5, 30, cx - 9, 30}, mixc(P.rust, .3, P.white))
        r(cx - 7, top + 26, 15, 2, mixc(P.rust, .5))
        r(cx + 7, top + 10, 3, 13, P.ink); r(cx + 8, top + 11, 1, 11, P.bone)
        p({cx - 6, top + 28, cx + 6, top + 28, cx + 8, 38, cx - 8, 38}, P.boneDark)
    end
    if C.act ~= 'work' then
        -- Mangas amplas arregaçadas + mãos largas.
        r(cx - 11, top + 13, 3, 9, P.ink); r(cx - 10, top + 14, 2, 6, shirt)
        r(cx - 10, top + 20, 2, 3, skin)
        r(cx + 10, top + 25, 3, 6, skin)   -- mão livre sob a toalha
    end
    -- Cabeça redonda: cabelo crespo fugindo da faixa de pano clara.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        r(cx - 5, top + 3, 10, 2, P.bone); r(cx + 4, top + 4, 2, 2, P.bone)
        d(cx - 4, top + 6, 8, 5, mixc(hair, .5), .3)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 2, hair); r(cx - 5, top + 1, 2, 3, hair)
        r(cx - 5, top + 3, 10, 2, P.bone)
        r(cx - side * 5, top + 3, 2, 2, P.bone)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 2, hair); r(cx - 5, top + 1, 2, 3, hair); r(cx + 4, top + 1, 2, 2, hair)
        r(cx - 5, top + 3, 10, 2, P.bone)         -- faixa (âncora)
        r(cx + 5, top + 3, 2, 2, P.bone); r(cx + 5, top + 4, 1, 1, P.boneDark)
        -- Rugas radiais + bigode fino em arco sobre a boca.
        r(cx - 3, top + 6, 1, 1, skinLo); r(cx + 4, top + 6, 1, 1, skinLo)
        r(cx - 2, top + 9, 4, 1, C.hairLo)
    end
end

-- TECA §5 (drape): triângulo comprido — vestido de lã azul acinzentada
-- sobre sobressaia cor de barro, xale com a ponta presa na cintura,
-- punhos de linho claro e nó lateral baixo no cabelo grisalho.
local function bodyDrape(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local dress, dressHi, dressLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 40, P.boneDark, P.goldDeep, nil, P.ink)
    -- Vestido em triângulo: ombros estreitos abrindo até a barra.
    p({cx - 5, top + 10, cx + 5, top + 10, cx + 9, 41, cx - 9, 41}, P.ink)
    p({cx - 4, top + 11, cx + 4, top + 11, cx + 8, 40, cx - 8, 40}, dress)
    p({cx - 4, top + 11, cx - 1, top + 11, cx - 4, 40, cx - 8, 40}, dressHi)
    p({cx + 2, top + 11, cx + 4, top + 11, cx + 8, 40, cx + 5, 40}, dressLo)
    l(cx - 1, top + 14, cx - 3, 39, dressLo); l(cx + 1, top + 14, cx + 3, 39, dressLo)
    d(cx - 3, top + 13, 6, 10, dressLo, .12)
    -- Sobressaia cor de barro (âncora): faixa mais curta por cima.
    p({cx - 6, 32, cx + 6, 32, cx + 8, 40, cx - 8, 40}, P.ink)
    p({cx - 5, 33, cx + 5, 33, cx + 7, 39, cx - 7, 39}, C.accent)
    l(cx - 5, 33, cx - 7, 39, mixc(C.accent, .35, P.white))
    l(cx - 5, 39, cx + 5, 39, mixc(C.accent, .45))
    if not north then
        -- Xale sobre os ombros com a ponta presa na cintura (âncora).
        p({cx - 5, top + 10, cx + 5, top + 10, cx + 6, top + 19, cx - 6, top + 19}, P.ink)
        p({cx - 4, top + 11, cx + 4, top + 11, cx + 5, top + 18, cx - 5, top + 18}, P.boneDark)
        p({cx - 4, top + 11, cx - 1, top + 11, cx - 2, top + 18, cx - 5, top + 18}, P.bone)
        l(cx - 5, top + 18, cx + 5, top + 18, P.bone)
        l(cx + 4, top + 11, cx + 2, top + 18, mixc(P.boneDark, .5))
        r(cx + 3, top + 17, 3, 3, P.bone)         -- nó da ponta presa
        r(cx + 4, top + 18, 1, 1, P.boneDark)
    else
        -- Costas: xale fechando os ombros + sobressaia contínua.
        p({cx - 5, top + 10, cx + 5, top + 10, cx + 6, top + 21, cx - 6, top + 21}, P.boneDark)
        p({cx - 4, top + 11, cx + 4, top + 11, cx + 5, top + 20, cx - 5, top + 20}, P.boneDark)
        l(cx - 3, top + 12, cx + 3, top + 12, P.bone)
        r(cx - 1, top + 19, 3, 2, P.bone)         -- nó nas costas
    end
    if C.act ~= 'work' then
        -- Punhos de linho claro: manga escura terminando em punho cru.
        r(cx - 8, top + 13, 3, 10, P.ink); r(cx - 7, top + 14, 2, 7, dress)
        r(cx - 7, top + 21, 2, 2, P.bone); r(cx - 7, top + 23, 2, 2, skin)
        r(cx + 5, top + 13, 3, 10, P.ink); r(cx + 6, top + 14, 2, 7, dressLo)
        r(cx + 6, top + 21, 2, 2, P.bone); r(cx + 6, top + 23, 2, 2, skin)
    end
    -- Cabeça pequena: cabelo preto grisalho + nó lateral baixo.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 8, hairLo, .3)
        r(cx + 5, top + 6, 3, 3, hair); r(cx + 5, top + 7, 1, 1, C.accent)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 6, hair)
        -- O nó fica do lado de trás no perfil.
        r(cx - side * 5 - (side == 1 and 1 or 0), top + 6, 3, 3, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 6, hair)
        r(cx - 4, top + 3, 3, 1, hair); r(cx + 2, top + 3, 2, 1, hair)
        -- Nó lateral baixo à esquerda (âncora) + fio solto.
        r(cx - 7, top + 6, 3, 3, hair); r(cx - 7, top + 7, 1, 1, C.accent)
        l(cx - 5, top + 9, cx - 6, top + 12, hair)
    end
end

-- SABELA §6 (dean): linha vertical alta — camisa de lã cru sob casaco
-- azul de petróleo aberto em dois painéis, faixa castanha, calças cinza
-- e pasta achatada na lateral; tranças curtas puxadas, fios brancos.
local function bodyDean(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 29, P.stone, P.goldDeep, nil, P.ink)
    -- Faixa castanha na cintura com fivela antiga.
    r(cx - 5, 27, 11, 2, P.goldDeep); r(cx, 27, 2, 2, P.gold)
    -- Camisa de lã cru sob o casaco.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 7, 28, cx - 7, 28}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, 27, cx - 6, 27}, P.bone)
    -- Casaco aberto em dois painéis (âncora): os lados caem retos.
    p({cx - 6, top + 10, cx - 1, top + 12, cx - 3, 27, cx - 6, 27}, coat)
    p({cx + 6, top + 10, cx + 1, top + 12, cx + 3, 27, cx + 6, 27}, coatLo)
    l(cx - 6, top + 11, cx - 3, 26, coatHi)
    l(cx - 3, 27, cx - 6, 27, coatLo)
    -- Gola do casaco + vinco do joelho remendado na calça.
    l(cx - 5, top + 10, cx - 1, top + 12, coatLo); l(cx + 5, top + 10, cx + 1, top + 12, coatLo)
    r(cx - 4, 34, 3, 2, mixc(P.stone, .4)); r(cx - 4, 34, 3, 1, P.stone)
    if not north then
        -- Pasta achatada na lateral esquerda (âncora) sob o braço.
        r(cx - 10, top + 14, 4, 11, P.ink); r(cx - 9, top + 15, 2, 9, P.goldDeep)
        r(cx - 9, top + 18, 2, 2, P.gold); l(cx - 7, top + 15, cx - 4, top + 12, P.goldDeep)
        -- Braço direito livre: manga do casaco + mão de pele.
        r(cx + 7, top + 13, 3, 10, P.ink); r(cx + 8, top + 14, 2, 7, coat)
        r(cx + 8, top + 21, 2, 3, skin)
    else
        -- Costas: casaco inteiro com a alça da pasta na diagonal.
        p({cx - 6, top + 10, cx + 6, top + 10, cx + 6, 27, cx - 6, 27}, coat)
        p({cx - 6, top + 10, cx - 2, top + 10, cx - 3, 27, cx - 6, 27}, coatHi)
        l(cx + 4, top + 11, cx - 4, top + 24, P.goldDeep)
        r(cx - 5, top + 23, 11, 1, coatLo)
    end
    if C.act == 'work' then
        -- O braço da pasta segura a lateral; o outro escreve (workArms).
    elseif side ~= 0 then
        r(cx + side * 7 - 1, top + 14, 3, 9, coat)
        r(cx + side * 7 - 1, top + 22, 3, 2, skin)
    end
    -- Cabeça angular: tranças curtas puxadas, fios brancos na linha.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        l(cx - 2, top + 2, cx - 2, top + 10, hairLo)
        l(cx, top + 2, cx, top + 10, hairLo); l(cx + 2, top + 2, cx + 2, top + 10, hairLo)
        r(cx - 2, top + 11, 5, 1, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 3, 4, hair)
        l(cx - 2, top + 1, cx + 3, top + 3, hairLo)
        r(cx - side * 5, top + 4, 2, 6, hair)      -- trança ao alto atrás
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        l(cx - 3, top + 1, cx + 3, top + 2, hairLo)
        l(cx - 2, top + 1, cx - 1, top + 3, hairLo); l(cx + 1, top + 1, cx + 2, top + 3, hairLo)
        -- Fios brancos na linha frontal.
        r(cx - 3, top + 3, 1, 1, P.stoneEdge); r(cx - 1, top + 3, 1, 1, P.stoneEdge); r(cx + 3, top + 3, 1, 1, P.stoneEdge)
        -- Cicatriz pequena no queixo + lábio inferior cheio.
        r(cx + 2, top + 11, 1, 1, skinHi); r(cx - 1, top + 9, 3, 1, mixc(skin, .3, P.white))
    end
end

-- NILO §7 (youth): aprendiz — tronco curto, camisa amarela apagada sob
-- colete azul gasto com bolso frontal largo, calças marrom de barra
-- dobrada; cabelo denso com a mecha voltada para cima, olhos abertos.
local function bodyYouth(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local vest, vestLo = C.accent, mixc(C.accent, .45)
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 32, P.goldDeep, P.goldDark, nil, P.ink)
    r(cx - 4, 38, 3, 1, P.gold); r(cx + 3, 38, 3, 1, P.gold)   -- dobra da barra
    -- Tronco curto: camisa amarela + painéis do colete azul.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 7, 33, cx - 7, 33}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, 32, cx - 6, 32}, shirt)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 32, cx - 6, 32}, shirtHi)
    if not north then
        p({cx - 5, top + 11, cx - 1, top + 12, cx - 2, 31, cx - 5, 31}, vest)
        p({cx + 5, top + 11, cx + 1, top + 12, cx + 2, 31, cx + 5, 31}, vestLo)
        l(cx - 5, top + 12, cx - 2, 30, mixc(vest, .35, P.white))
        -- Bolso frontal retangular claro (âncora) + costura torta dele.
        r(cx - 3, top + 21, 7, 6, P.ink); r(cx - 2, top + 22, 5, 4, P.bone)
        r(cx - 2, top + 22, 5, 1, P.boneDark)
        r(cx - 1, top + 24, 1, 1, P.goldDeep); r(cx + 1, top + 25, 1, 1, P.goldDeep)
        -- Bolsa de retalhos de madeira na lateral.
        r(cx + 7, top + 20, 4, 9, P.ink); r(cx + 8, top + 21, 2, 7, P.goldDark)
        r(cx + 8, top + 21, 1, 2, P.gold); l(cx + 6, top + 13, cx + 8, top + 21, P.goldDeep)
    else
        p({cx - 5, top + 11, cx + 5, top + 11, cx + 5, 31, cx - 5, 31}, vest)
        p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 31, cx - 5, 31}, mixc(vest, .3, P.white))
        l(cx - 4, top + 12, cx + 4, top + 26, mixc(vest, .5))
    end
    if C.act ~= 'work' then armsIdle(C, top + 13, 11) end
    -- Cabeça de cabelo denso: curto atrás, longo na frente, mecha em pé.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 7, hairLo, .3)
        r(cx - 1, top - 2, 2, 3, hair)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 3, 7, hair)
        -- Mecha voltada para cima na testa (âncora).
        r(cx + side * 2 - 1, top - 2, 3, 3, hair); r(cx + side * 2, top - 3, 1, 1, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 6, hair)
        r(cx - 4, top + 3, 3, 1, hair); r(cx + 3, top + 3, 2, 1, hair)
        -- Mecha voltada para cima, torta para um lado (âncora).
        r(cx + 1, top - 2, 3, 3, hair); r(cx + 2, top - 3, 1, 1, hair)
        -- Olhos castanhos muito abertos: íris maior no poço.
        r(cx - 3, top + 5, 2, 1, eye); r(cx + 2, top + 5, 2, 1, eye)
    end
end

-- AUREL §8 (vigil): retângulo vertical — túnica de linho cinza pérola
-- sob sobrecasaca azul carvão fendida abaixo dos joelhos, gola alta
-- estreita, faixa de trabalho e punhos de couro; grisalho penteado.
local function bodyVigil(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    -- Botas finas sob a barra da túnica.
    r(cx - 5, 40, 4, 4, P.ink); r(cx + 2, 40, 4, 4, P.ink)
    r(cx - 4, 41, 3, 2, P.goldDeep); r(cx + 3, 41, 3, 2, P.goldDeep)
    r(cx - 4, 41, 1, 1, P.gold)
    -- Sobrecasaca fendida (âncora): painéis até abaixo do joelho.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 7, 40, cx - 7, 40}, P.ink)
    if north then
        p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, 39, cx - 6, 39}, coat)
        p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 39, cx - 6, 39}, coatHi)
        l(cx - 1, top + 22, cx - 2, 38, coatLo)
    else
        p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, 39, cx - 6, 39}, coat)
        p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 39, cx - 6, 39}, coatHi)
        p({cx + 3, top + 11, cx + 5, top + 11, cx + 6, 39, cx + 4, 39}, coatLo)
        -- Fenda da frente abrindo da cintura: túnica pérola por dentro.
        p({cx - 1, top + 22, cx + 1, top + 22, cx + 2, 39, cx - 2, 39}, P.ink)
        r(cx - 1, top + 23, 2, 16, P.boneDark); r(cx - 1, top + 23, 1, 15, P.bone)
        -- Faixa horizontal de trabalho na cintura.
        r(cx - 5, top + 19, 11, 2, P.bone); r(cx - 5, top + 20, 11, 1, P.boneDark)
        r(cx - 5, top + 19, 3, 1, P.goldDark)
        d(cx - 4, top + 13, 9, 6, coatLo, .2)
    end
    -- Gola alta estreita (âncora): colarinho em pé atrás do queixo.
    r(cx - 4, top + 8, 9, 4, P.ink); r(cx - 3, top + 9, 7, 3, coat)
    r(cx - 3, top + 9, 7, 1, coatHi)
    if C.act ~= 'work' then
        -- Punhos de couro castanho nos braços recolhidos.
        r(cx - 8, top + 13, 3, 10, P.ink); r(cx - 7, top + 14, 2, 6, coat)
        r(cx - 7, top + 20, 2, 2, P.goldDeep); r(cx - 7, top + 22, 2, 2, skin)
        r(cx + 5, top + 13, 3, 10, P.ink); r(cx + 6, top + 14, 2, 6, coatLo)
        r(cx + 6, top + 20, 2, 2, P.goldDeep); r(cx + 6, top + 22, 2, 2, skin)
    end
    -- Cabeça longa: grisalho penteado para trás, linha recuada, orelhas.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        l(cx - 3, top + 2, cx + 3, top + 2, hairLo); l(cx - 3, top + 5, cx + 3, top + 5, hairLo)
        d(cx - 3, top + 7, 6, 4, hairLo, .3)
        r(cx - 6, top + 5, 1, 3, skin); r(cx + 5, top + 5, 1, 3, skin)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 3, 8, hair)
        l(cx - 3, top + 1, cx + 4, top + 2, hairLo)
        r(cx - side * 6, top + 5, 1, 3, skin)     -- orelha grande de fora
        r(cx - side * 6, top + 6, 1, 1, skinLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 2, hair); r(cx - 5, top + 1, 2, 6, hair); r(cx + 4, top + 1, 2, 6, hair)
        l(cx - 4, top + 1, cx + 4, top + 1, hairLo)
        r(cx - 3, top + 2, 2, 1, skin)            -- linha recuada
        r(cx + 1, top + 2, 1, 1, skin)
        -- Orelhas grandes salientes.
        r(cx - 6, top + 5, 1, 3, skin); r(cx + 5, top + 5, 1, 3, skin)
        r(cx - 6, top + 6, 1, 1, skinLo); r(cx + 5, top + 6, 1, 1, skinLo)
    end
end

--====================================================================--
-- Elenco das regiões — um corpo por pessoa, âncoras das fichas §10-18.
-- Mesma régua do núcleo: rampa por material, textura assada, sombra de
-- forma, rosto de ficha e gesto de ofício próprio.
--====================================================================--

-- JANDA §10 (forge): trapézio largo invertido — camisa cinza grossa sem
-- manga sobre antebraços nus, avental de couro em dois painéis, faixa
-- vinho e ombro acolchoado da viga; faixa branca no cabelo e martelo.
local function bodyForge(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    local leather, leatherHi, leatherLo = P.goldDark, P.gold, P.goldDeep
    npcFeet(r, cx, 36, P.goldDark, P.ink, nil, P.ink)
    -- Botas largas de ponteira reforçada + pó de obra nos joelhos.
    r(cx - 5, 41, 5, 1, leatherLo); r(cx + 1, 41, 5, 1, leatherLo)
    r(cx - 3, 37, 1, 1, P.boneDark); r(cx + 3, 36, 1, 1, P.boneDark)
    -- Dorso larguíssimo (âncora): camisa de malha grossa sem manga.
    p({cx - 10, top + 10, cx + 10, top + 10, cx + 9, 36, cx - 9, 36}, P.ink)
    p({cx - 9, top + 11, cx + 9, top + 11, cx + 8, 35, cx - 8, 35}, shirt)
    p({cx - 9, top + 11, cx - 6, top + 11, cx - 5, 35, cx - 8, 35}, shirtHi)
    p({cx + 5, top + 11, cx + 9, top + 11, cx + 8, 35, cx + 6, 35}, shirtLo)
    d(cx - 6, top + 13, 12, 20, shirtLo, .18)
    -- Ombro acolchoado da viga (esquerdo): matelassê em filetes.
    r(cx - 12, top + 8, 4, 5, P.ink); r(cx - 11, top + 9, 3, 4, C.accent)
    l(cx - 11, top + 10, cx - 9, top + 10, P.boneDark)
    l(cx - 11, top + 12, cx - 9, top + 12, P.boneDark)
    if north then
        -- Costas: alças do avental cruzando o dorso + nó da faixa.
        l(cx - 5, top + 11, cx + 4, top + 20, leatherLo)
        l(cx + 5, top + 11, cx - 4, top + 20, leatherLo)
        r(cx - 5, top + 21, 11, 2, P.rust); r(cx - 1, top + 21, 2, 1, P.boneDark)
        p({cx - 6, top + 24, cx + 6, top + 24, cx + 7, 37, cx - 7, 37}, P.ink)
        p({cx - 5, top + 25, cx + 5, top + 25, cx + 6, 36, cx - 6, 36}, leather)
        d(cx - 4, top + 26, 8, 9, leatherLo, .2)
    else
        -- Faixa vinho na cintura + avental de couro em DOIS painéis
        -- (âncora): filete de brilho na borda externa, barra gasta.
        r(cx - 8, top + 20, 17, 2, P.rust); r(cx - 1, top + 20, 2, 2, P.gold)
        p({cx - 8, top + 22, cx - 1, top + 22, cx - 2, 38, cx - 8, 38}, P.ink)
        p({cx - 7, top + 23, cx - 1, top + 23, cx - 2, 37, cx - 7, 37}, leather)
        l(cx - 7, top + 24, cx - 6, 36, leatherHi)
        p({cx + 8, top + 22, cx + 1, top + 22, cx + 2, 38, cx + 8, 38}, P.ink)
        p({cx + 7, top + 23, cx + 1, top + 23, cx + 2, 37, cx + 7, 37}, leather)
        l(cx + 2, top + 24, cx + 3, 36, leatherLo)
        r(cx - 7, 37, 5, 1, leatherLo); r(cx + 3, 37, 5, 1, leatherLo)
    end
    if C.act ~= 'work' then
        -- Antebraços nus: a manga corta no ombro e a mão grossa fica
        -- livre; o martelo industrial encosta no chão à sua frente.
        r(cx - 12, top + 13, 3, 4, shirt); r(cx + 9, top + 13, 3, 4, shirtLo)
        l(cx - 11, top + 15, cx - 11, top + 23, skin)
        r(cx - 11, top + 22, 2, 3, skin)
        l(cx + 10, top + 15, cx + 10, top + 23, skin)
        r(cx + 9, top + 22, 2, 3, skin)
        local sx = south and cx + 12 or cx + side * 11
        l(sx, top + 4, sx, 41, P.goldDeep)
        r(sx - 3, 37, 7, 4, P.stoneDark); r(sx - 3, 37, 7, 1, P.stoneLight)
    end
    -- Cabeça quadrada: cabelo preto curto, faixa branca sobre a orelha
    -- esquerda (âncora) e a dobra vertical entre as sobrancelhas.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        d(cx - 3, top + 2, 6, 8, hairLo, .25)
        r(cx + 4, top + 4, 2, 2, P.white)
        r(cx - 2, top + 12, 5, 1, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 3, 5, hair)
        r(cx - side * 5, top + 3, 2, 2, P.white)
        r(fx + (side == 1 and -3 or 2), top + 11, 3, 2, skin)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 3, 6, hair)
        r(cx + 4, top + 1, 2, 6, hair)
        r(cx + 4, top + 4, 2, 2, P.white)          -- faixa branca (âncora)
        r(cx, top + 5, 1, 2, P.ink)                -- dobra entre sobrancelhas
        l(cx - 3, top + 5, cx - 2, top + 5, hairLo)
        l(cx + 1, top + 5, cx + 3, top + 5, hairLo)
        r(cx - 4, top + 9, 1, 3, skin); r(cx + 4, top + 9, 1, 3, skin)
    end
end

-- BRINA §11 (smith): retângulo compacto de cotovelos abertos — camisa
-- carvão de manga estreita, avental ferrugem curto com trama e fecho
-- de pano amarelo; bloco alto de cabelo crespo achatado no topo.
local function bodySmith(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo, hairHi = C.hair, C.hairLo, C.hairHi
    local apron, apronHi, apronLo = P.rust, mixc(P.rust, .3, P.white), mixc(P.rust, .45)
    npcFeet(r, cx, 37, P.stone, P.ink, nil, P.ink)   -- saia-calça de lã cinza
    -- Tronco curto firme: camisa carvão até o quadril.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 7, 36, cx - 7, 36}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, 35, cx - 6, 35}, shirt)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 35, cx - 6, 35}, shirtHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 6, 35, cx + 4, 35}, shirtLo)
    d(cx - 4, top + 13, 8, 20, shirtLo, .15)
    r(cx - 2, top + 10, 5, 2, P.bone)    -- gola clara pequena
    if north then
        l(cx - 4, top + 13, cx + 4, top + 26, apronLo)
        p({cx - 5, top + 27, cx + 5, top + 27, cx + 6, 36, cx - 6, 36}, apron)
        r(cx - 5, 35, 11, 1, apronLo)
    else
        -- Avental ferrugem acima dos joelhos (âncora): trama cruzada
        -- assada + fecho de pano amarelo queimado.
        p({cx - 5, top + 15, cx + 5, top + 15, cx + 6, 33, cx - 6, 33}, P.ink)
        p({cx - 4, top + 16, cx + 4, top + 16, cx + 5, 32, cx - 5, 32}, apron)
        d(cx - 3, top + 18, 8, 12, apronLo, .2)
        l(cx - 4, top + 16, cx - 4, top + 12, apronLo)
        l(cx + 4, top + 16, cx + 4, top + 12, apronLo)
        r(cx - 4, 31, 9, 1, apronLo)
        r(cx - 1, top + 15, 3, 2, P.gold); r(cx + 1, top + 16, 1, 3, P.goldDark)
        -- Bolso rígido com a lima e o instrumento de medida.
        r(cx - 7, top + 22, 2, 6, P.ink); r(cx - 7, top + 22, 1, 4, P.stoneEdge)
        r(cx + 6, top + 23, 2, 5, P.stoneDeep); r(cx + 6, top + 23, 1, 1, P.gold)
    end
    if C.act ~= 'work' then
        -- Cotovelos afastados (âncora): antebraços apontando para fora,
        -- mãos quase na cintura — postura de quem avalia a peça.
        l(cx - 6, top + 12, cx - 10, top + 18, shirt)
        l(cx - 10, top + 18, cx - 6, top + 22, skin)
        r(cx - 6, top + 21, 3, 2, skin)
        l(cx + 6, top + 12, cx + 10, top + 18, shirtLo)
        l(cx + 10, top + 18, cx + 6, top + 22, skin)
        r(cx + 4, top + 21, 3, 2, skin)
    end
    -- Cabeça de bloco alto: cabelo crespo rente nas laterais e massa
    -- achatada no topo (âncora) sobre a testa larga aberta.
    r(cx - 5, top - 3, 10, 16, P.ink)
    if north then
        r(cx - 4, top - 2, 8, 5, hair); r(cx - 4, top - 2, 8, 1, hairHi)
        r(cx - 5, top + 3, 2, 9, hair); r(cx + 4, top + 3, 2, 9, hair)
        d(cx - 3, top + 4, 6, 7, hairLo, .3)
        r(cx - 2, top + 12, 5, 1, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top - 3, 9, 5, hair); r(cx - 4, top - 3, 9, 1, hairHi)
        r(cx - 5, top + 1, 2, 6, hair); r(cx + 4, top + 1, 2, 5, hair)
        r(fx + (side == 1 and 1 or -2), top + 7, 2, 1, skinHi)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top - 3, 9, 4, hair); r(cx - 4, top - 3, 9, 1, hairHi)
        r(cx - 5, top, 2, 7, hair); r(cx + 4, top, 2, 6, hair)
        -- Maçãs cheias + queixo afilado + nariz de ponte baixa.
        r(cx - 3, top + 7, 2, 1, skinHi); r(cx + 2, top + 7, 2, 1, skinHi)
        r(cx - 1, top + 8, 3, 1, skinLo)
        l(cx - 3, top + 5, cx - 1, top + 5, hairLo)
        l(cx + 1, top + 5, cx + 3, top + 5, hairLo)
    end
end

-- NECO §12 (hauler): linha alta e magra — camisa areia rente onde
-- trabalha, suspensórios claros desiguais, colete curto marrom,
-- pescoço comprido, franja lateral e bigode ralo.
local function bodyHauler(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    local vest, vestLo = P.goldDeep, mixc(P.goldDeep, .35)
    npcFeet(r, cx, 33, P.jadeMid, P.goldDeep, P.boneDark, P.ink)
    -- Tronco estreito e comprido: a camisa areia desce rente.
    p({cx - 5, top + 14, cx + 5, top + 14, cx + 6, 34, cx - 6, 34}, P.ink)
    p({cx - 4, top + 15, cx + 4, top + 15, cx + 5, 33, cx - 5, 33}, shirt)
    p({cx - 4, top + 15, cx - 1, top + 15, cx - 2, 33, cx - 5, 33}, shirtHi)
    p({cx + 2, top + 15, cx + 4, top + 15, cx + 5, 33, cx + 3, 33}, shirtLo)
    d(cx - 3, top + 17, 7, 14, shirtLo, .15)
    if north then
        -- Costas: colete baixo + suspensórios paralelos.
        p({cx - 4, top + 15, cx + 4, top + 15, cx + 4, 26, cx - 4, 26}, vest)
        l(cx - 4, top + 15, cx - 2, top + 15, mixc(vest, .3, P.white))
        l(cx - 3, top + 15, cx - 3, 33, P.white)
        l(cx + 3, top + 15, cx + 3, 33, P.white)
        r(cx - 4, top + 26, 9, 1, vestLo)
    else
        -- Colete curto marrom aberto sobre o peito.
        p({cx - 5, top + 14, cx - 2, top + 16, cx - 3, 26, cx - 5, 26}, vest)
        p({cx + 5, top + 14, cx + 2, top + 16, cx + 3, 26, cx + 5, 26}, vestLo)
        l(cx - 5, top + 15, cx - 3, 25, mixc(vest, .3, P.white))
        -- Suspensórios claros DESIGUAIS (âncora): um sobe reto, o outro
        -- desce torto por cima do colete.
        l(cx - 4, top + 13, cx - 4, 33, P.white)
        l(cx + 3, top + 14, cx + 4, 32, P.white)
        r(cx - 4, top + 20, 1, 2, P.boneDark); r(cx + 4, top + 19, 1, 2, P.boneDark)
        -- Reforço pesado que não combina: remendo no joelho.
        r(cx + 3, 31, 3, 3, vest); r(cx + 3, 31, 3, 1, P.goldDark)
    end
    -- Pescoço comprido (âncora): coluna de pele entre o queixo e a gola.
    r(cx - 1, top + 12, 3, 3, skin); r(cx - 1, top + 12, 3, 1, skinLo)
    if C.act ~= 'work' then
        -- Braço cruzado no peito ouvindo o pedido; o outro pendura
        -- com o cordel de trabalho na mão.
        r(cx - 4, top + 20, 9, 3, shirt)
        r(cx - 4, top + 20, 9, 1, shirtHi)
        r(cx + 3, top + 21, 3, 2, skin)
        if side ~= 0 then
            l(cx + side * 5, top + 14, cx + side * 6, top + 26, shirtLo)
            r(cx + side * 6 - 1, top + 25, 3, 3, skin)
        else
            l(cx + 6, top + 14, cx + 7, top + 27, shirtLo)
            r(cx + 6, top + 26, 3, 3, skin)
            l(cx + 8, top + 28, cx + 9, top + 33, P.goldDark)
        end
    end
    -- Cabeça estreita: corte rente atrás, franja caindo numa lateral
    -- (âncora), nariz longo e bigode curto ralo.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair); r(cx - 4, top + 9, 8, 2, hairLo)
        r(cx - 2, top + 12, 5, 1, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 3, 5, hair)
        r(fx + (side == 1 and -4 or 2), top + 2, 3, 5, hair)
        r(fx, top + 9, 3, 1, hairLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 3, 5, hair)
        r(cx + 1, top + 3, 4, 3, hair)         -- franja lateral (âncora)
        r(cx - 1, top + 9, 4, 1, hairLo)       -- bigode ralo
        r(cx, top + 6, 1, 2, skinLo)           -- nariz longo
    end
end

-- EMA §13 (vendor): corpo arredondado de banca — blusa índigo, saia
-- ocre ampla sobre calças, avental areia preso de lado com bolso azul;
-- dois rolos baixos de cabelo atrás das orelhas.
local function bodyVendor(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 38, P.stoneDeep, P.rust, nil, P.ink)   -- sapatos vinho
    r(cx + 3, 41, 1, 1, P.bone)                -- reparo na tira do sapato
    -- Saia ocre ampla (âncora) sobre as calças: barra escurecida do
    -- lado do forno.
    p({cx - 7, top + 22, cx + 7, top + 22, cx + 9, 38, cx - 9, 38}, P.ink)
    p({cx - 6, top + 23, cx + 6, top + 23, cx + 8, 37, cx - 8, 37}, P.gold)
    p({cx - 6, top + 23, cx - 2, top + 23, cx - 5, 37, cx - 8, 37}, P.goldLight)
    p({cx + 4, top + 23, cx + 6, top + 23, cx + 8, 37, cx + 5, 37}, P.goldDark)
    r(cx - 8, 36, 16, 1, P.goldDeep)
    d(cx - 5, top + 25, 11, 10, P.goldDark, .15)
    -- Blusa índigo arredondada até o quadril.
    p({cx - 7, top + 10, cx + 7, top + 10, cx + 8, top + 24, cx - 8, top + 24}, P.ink)
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 7, top + 23, cx - 7, top + 23}, shirt)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, top + 23, cx - 7, top + 23}, shirtHi)
    d(cx - 4, top + 13, 9, 8, shirtLo, .18)
    if not north then
        -- Avental areia preso DE LADO (âncora): painel atravessado,
        -- nó no quadril direito e bolso azul largo.
        p({cx - 6, top + 15, cx + 5, top + 15, cx + 7, 34, cx - 5, 34}, P.ink)
        p({cx - 5, top + 16, cx + 4, top + 16, cx + 6, 33, cx - 4, 33}, P.bone)
        d(cx - 4, top + 18, 8, 13, P.boneDark, .12)
        l(cx - 5, top + 16, cx - 4, 33, P.white)
        r(cx + 5, top + 17, 3, 3, P.bone); r(cx + 5, top + 18, 3, 1, P.boneDark)
        l(cx + 6, top + 20, cx + 8, top + 24, P.boneDark)
        r(cx - 4, top + 24, 4, 5, P.jadeDeep)
        r(cx - 4, top + 24, 4, 1, P.stoneLight)
        r(cx + 2, 31, 1, 1, P.goldDark); r(cx - 1, 33, 1, 1, P.goldDeep)
    else
        l(cx - 4, top + 13, cx + 4, top + 24, P.boneDark)
        r(cx - 5, top + 15, 11, 2, P.bone)
    end
    if C.act ~= 'work' then
        -- Mão pequena no quadril + caderno de pedidos na outra.
        l(cx - 6, top + 12, cx - 9, top + 18, shirt)
        r(cx - 9, top + 18, 3, 2, skin)
        r(cx + 7, top + 13, 3, 8, P.ink); r(cx + 8, top + 14, 2, 6, shirtLo)
        r(cx + 8, top + 19, 2, 2, skin)
        r(cx + 10, top + 20, 4, 5, P.ink); r(cx + 11, top + 21, 2, 3, P.bone)
    end
    -- Cabeça em coração: dois rolos baixos posteriores (âncora) e a
    -- sobrancelha esquerda mais arqueada.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        r(cx - 6, top + 5, 3, 3, hair); r(cx + 4, top + 5, 3, 3, hair)
        r(cx - 5, top + 5, 1, 1, hairLo); r(cx + 5, top + 6, 1, 1, hairLo)
        r(cx - 2, top + 12, 5, 1, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 5, hair)
        r(cx - side * 5 - 1, top + 5, 3, 3, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 2, 5, hair)
        r(cx + 4, top + 1, 2, 5, hair)
        r(cx - 6, top + 5, 3, 3, hair); r(cx + 4, top + 5, 3, 3, hair)
        r(cx - 5, top + 6, 1, 1, hairLo); r(cx + 5, top + 6, 1, 1, hairLo)
        r(cx - 3, top + 4, 2, 1, skin); r(cx - 3, top + 3, 2, 1, hair)
        r(cx - 1, top + 9, 4, 1, skinLo)
    end
end

-- RUTE §14 (assessor): linha vertical estreita — casaco verde profundo
-- de lã sobre vestido cinza, gola vinho, punhos de linho claros
-- avançados e coque alto apertado; etiqueta na mão, lápis na outra.
local function bodyAssessor(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 40, P.stone, P.ink, nil, P.ink)   -- vestido + botas finas
    -- Casaco estreito (âncora): coluna reta de lã até o tornozelo.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 6, 40, cx - 6, 40}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 5, 39, cx - 5, 39}, coat)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 39, cx - 5, 39}, coatHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 5, 39, cx + 4, 39}, coatLo)
    d(cx - 4, top + 13, 8, 24, coatLo, .15)
    if north then
        r(cx - 5, top + 11, 10, 28, coat)
        r(cx - 5, top + 11, 10, 2, coatHi)
        l(cx - 3, top + 14, cx - 4, 38, coatLo)
        r(cx - 2, top + 10, 5, 2, P.rust)
        -- Bainha remendada por dentro: filete claro só na borda.
        r(cx - 4, 39, 8, 1, P.stone)
    else
        -- Fenda da frente: vestido cinza por dentro, gola vinho miúda,
        -- três botões da frente mantida impecável.
        p({cx - 1, top + 14, cx + 1, top + 14, cx + 2, 39, cx - 2, 39}, P.stone)
        l(cx - 1, top + 15, cx - 2, 38, P.stoneDark)
        r(cx - 2, top + 10, 5, 2, P.rust)
        r(cx - 2, top + 10, 5, 1, mixc(P.rust, .3, P.white))
        l(cx - 2, top + 12, cx - 1, top + 18, coatLo)
        l(cx + 2, top + 12, cx + 1, top + 18, coatLo)
        r(cx, top + 20, 1, 1, P.gold); r(cx, top + 25, 1, 1, P.gold)
        r(cx, top + 30, 1, 1, P.gold)
    end
    -- Cotovelos brilhando de desgaste nas mangas do casaco.
    r(cx - 7, top + 17, 1, 1, coatHi); r(cx + 7, top + 17, 1, 1, coatHi)
    if C.act ~= 'work' then
        -- Punhos claros avançados (âncora): linho cru terminando a
        -- manga; a esquerda ergue a etiqueta, a direita tem o lápis.
        r(cx - 8, top + 13, 3, 8, P.ink); r(cx - 7, top + 14, 2, 5, coat)
        r(cx - 7, top + 19, 2, 2, P.bone); r(cx - 7, top + 21, 2, 2, skin)
        r(cx + 5, top + 13, 3, 8, P.ink); r(cx + 6, top + 14, 2, 5, coatLo)
        r(cx + 6, top + 19, 2, 2, P.bone); r(cx + 6, top + 21, 2, 2, skin)
        r(cx - 10, top + 18, 4, 3, P.bone); r(cx - 10, top + 18, 4, 1, P.ink)
        l(cx + 8, top + 20, cx + 10, top + 17, P.gold)
    end
    -- Cabeça oval de queixo longo: coque alto apertado (âncora), cabelo
    -- puxado limpando a testa, duas linhas junto da boca.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair); r(cx - 1, top - 3, 3, 3, hair)
        l(cx - 3, top + 2, cx + 3, top + 4, hairLo)
        l(cx - 4, top + 4, cx + 4, top + 6, hairLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 1, top - 3, 3, 3, hair)
        l(cx - 3, top + 1, cx + 4, top + 2, hairLo)
        r(fx + (side == 1 and 3 or -3), top + 8, 1, 2, skinLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 2, hair); r(cx - 1, top - 3, 3, 3, hair)
        l(cx - 4, top + 1, cx + 4, top + 2, hairLo)
        r(cx + 4, top + 1, 1, 4, hair); r(cx - 5, top + 1, 1, 4, hair)
        r(cx - 2, top + 9, 1, 1, skinLo); r(cx + 2, top + 9, 1, 1, skinLo)
    end
end

-- MARA §15 (planter): volume baixo e forte — blusa creme de mangas
-- largas, saia verde apagada sobre calças de barro, avental azul de
-- bolso largo; cabelo branco curto e cesto horizontal no braço.
local function bodyPlanter(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo, hairHi = C.hair, C.hairLo, C.hairHi
    npcFeet(r, cx, 40, P.rust, P.goldDeep, nil, P.ink)   -- calças de barro
    -- Saia verde apagada sobre as calças — barra úmida mais escura.
    p({cx - 6, top + 20, cx + 6, top + 20, cx + 8, 39, cx - 8, 39}, P.ink)
    p({cx - 5, top + 21, cx + 5, top + 21, cx + 7, 38, cx - 7, 38}, P.jadeDark)
    p({cx - 5, top + 21, cx - 1, top + 21, cx - 4, 38, cx - 7, 38}, P.jadeMid)
    d(cx - 4, top + 23, 9, 13, P.jadeDeep, .18)
    l(cx - 7, 37, cx + 7, 37, P.jadeDeep)
    -- Blusa creme arredondada.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 7, top + 23, cx - 7, top + 23}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, top + 22, cx - 6, top + 22}, shirt)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, top + 22, cx - 6, top + 22}, shirtHi)
    if not north then
        -- Avental de pano azul com o bolso largo de carregar mudas.
        p({cx - 5, top + 15, cx + 5, top + 15, cx + 6, 30, cx - 6, 30}, P.ink)
        p({cx - 4, top + 16, cx + 4, top + 16, cx + 5, 29, cx - 5, 29}, P.stone)
        d(cx - 3, top + 17, 7, 10, P.stoneDark, .15)
        r(cx - 3, top + 20, 5, 4, P.stoneDark); r(cx - 3, top + 20, 5, 1, P.stoneLight)
        r(cx - 1, top + 22, 1, 1, P.jade); r(cx + 1, top + 21, 1, 1, P.jade)
    else
        l(cx - 4, top + 12, cx + 4, top + 22, P.stoneDark)
    end
    if C.act ~= 'work' then
        -- Mangas largas creme (âncora) + cesto raso horizontal no braço
        -- (âncora): boca larga com mudas assomando.
        r(cx - 9, top + 12, 4, 9, P.ink); r(cx - 8, top + 13, 3, 7, shirt)
        r(cx - 8, top + 18, 3, 2, shirtHi); r(cx - 8, top + 20, 2, 2, skin)
        r(cx + 6, top + 12, 4, 9, P.ink); r(cx + 7, top + 13, 3, 7, shirtHi)
        local bx = south and cx + 5 or (north and cx + 6 or cx + side * 6)
        r(bx, top + 18, 8, 5, P.ink); r(bx + 1, top + 19, 6, 3, P.goldDark)
        r(bx + 1, top + 19, 6, 1, P.gold)
        l(bx + 2, top + 19, bx + 1, top + 16, P.jade)
        l(bx + 4, top + 19, bx + 5, top + 15, P.jadeLight)
        r(bx + 7, top + 20, 2, 2, skin)
    end
    -- Cabeça baixa: cabelo branco curto ondulado (âncora), sobrancelhas
    -- escuras ainda cheias e rugas profundas de sol.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        r(cx - 4, top + 3, 2, 1, hairHi); r(cx + 1, top + 5, 2, 1, hairHi)
        r(cx - 3, top + 7, 2, 1, hairHi)
        d(cx - 3, top + 4, 6, 7, P.boneDark, .2)
        r(cx - 2, top + 12, 5, 1, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 4, hair); r(cx - 5, top + 3, 3, 6, hair)
        r(cx + 4, top + 3, 2, 5, hair)
        r(cx - 4, top + 4, 2, 1, hairHi); r(cx + 3, top + 5, 1, 1, hairHi)
        l(fx - 2, top + 5, fx - 1, top + 5, P.ink)   -- sobrancelha escura
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 3, 6, hair)
        r(cx + 4, top + 2, 2, 5, hair)
        r(cx - 4, top + 3, 2, 1, hairHi); r(cx + 3, top + 4, 1, 1, hairHi)
        l(cx - 3, top + 5, cx - 1, top + 5, P.ink)   -- sobrancelhas escuras
        l(cx + 1, top + 5, cx + 3, top + 5, P.ink)
        r(cx - 3, top + 7, 1, 1, skinLo); r(cx + 3, top + 8, 1, 1, skinLo)
    end
end

-- IVO §16 (engineer): tronco largo de pernas curtas — camisa areia sob
-- casaco encerado verde escuro de barra rígida, calças chumbo, botas
-- altas, faixa no pescoço e gorro baixo de lã; um ombro escuta.
local function bodyEngineer(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    local gorro = C.accent
    npcFeet(r, cx, 38, P.stoneDeep, P.ink, nil, P.ink)
    -- Botas altas (âncora): cano impermeabilizado até abaixo do joelho.
    r(cx - 5, 34, 4, 8, P.ink); r(cx - 4, 34, 3, 7, P.goldDeep)
    r(cx + 2, 34, 4, 8, P.ink); r(cx + 3, 34, 3, 7, P.goldDeep)
    l(cx - 4, 34, cx - 4, 40, P.goldDark)
    -- Casaco encerado: ombro direito um ponto acima — ele escuta o
    -- metal mesmo parado (âncora: barra rígida no fim).
    p({cx - 8, top + 10, cx + 8, top + 9, cx + 9, 38, cx - 9, 38}, P.ink)
    p({cx - 7, top + 11, cx + 7, top + 10, cx + 8, 37, cx - 8, 37}, coat)
    p({cx - 7, top + 11, cx - 4, top + 11, cx - 5, 37, cx - 8, 37}, coatHi)
    p({cx + 4, top + 10, cx + 7, top + 10, cx + 8, 37, cx + 5, 37}, coatLo)
    d(cx - 5, top + 13, 10, 22, coatLo, .15)
    r(cx - 8, 36, 16, 2, mixc(coat, .3)); r(cx - 8, 36, 16, 1, coatHi)
    l(cx - 4, top + 24, cx + 3, top + 24, coatLo)   -- dobra dura da barriga
    r(cx + 3, top + 28, 2, 1, P.ink); r(cx - 5, top + 31, 1, 2, P.ink)
    r(cx - 4, top + 9, 9, 2, P.boneDark); r(cx - 4, top + 9, 9, 1, P.bone)
    if north then
        l(cx - 4, top + 12, cx + 4, top + 26, coatLo)
        r(cx - 6, top + 20, 13, 1, mixc(coat, .3, P.white))
    end
    if C.act ~= 'work' then
        -- Punhos secos dobrados + mãos gastas de volante.
        r(cx - 9, top + 13, 3, 10, P.ink); r(cx - 8, top + 14, 2, 7, coat)
        r(cx - 8, top + 21, 2, 1, P.boneDark); r(cx - 8, top + 22, 2, 2, skin)
        r(cx + 6, top + 13, 3, 10, P.ink); r(cx + 7, top + 14, 2, 7, coatLo)
        r(cx + 7, top + 21, 2, 1, P.boneDark); r(cx + 7, top + 22, 2, 2, skin)
    end
    -- Cabeça de gorro baixo (âncora): lã puxada à testa, barba curta
    -- abundante no queixo e nariz de ponta vermelha do frio.
    r(cx - 5, top - 1, 10, 14, P.ink)
    if north then
        r(cx - 4, top, 8, 4, gorro); r(cx - 4, top + 3, 8, 1, mixc(gorro, .35))
        r(cx - 4, top + 4, 8, 8, skin)
        d(cx - 4, top + 4, 8, 4, skinLo, .2)
        r(cx - 3, top + 9, 6, 3, C.pal.beard or hair)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top - 1, 9, 4, gorro); r(cx - 4, top + 2, 9, 1, mixc(gorro, .35))
        r(fx + (side == 1 and 1 or -2), top + 7, 1, 1, P.rust)
        r(fx + (side == 1 and -1 or -2), top + 10, 4, 2, C.pal.beard or hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top - 1, 9, 4, gorro); r(cx - 4, top + 2, 9, 1, mixc(gorro, .35))
        r(cx - 5, top + 1, 2, 4, gorro); r(cx + 4, top + 1, 2, 4, gorro)
        local beard = C.pal.beard or hair
        r(cx - 4, top + 8, 1, 3, beard); r(cx + 4, top + 8, 1, 3, beard)
        r(cx - 2, top + 10, 5, 2, beard); r(cx - 2, top + 10, 2, 1, hairLo)
        r(cx, top + 7, 1, 1, P.rust)                -- nariz vermelho
    end
end

-- BELTRAN §17 (host): corpo largo no ventre — camisa creme, casaca
-- vinho queimado de abas amplas até o joelho, faixa de ouro velho e
-- manga em sino; testa ampla, bigode grosso e sobrancelhas altas.
local function bodyHost(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 40, P.ink, P.goldDeep, nil, P.ink)   -- calças negras
    r(cx - 4, 42, 1, 1, P.goldDark); r(cx + 3, 42, 1, 1, P.goldDark)
    -- Casaca: ombros macios abrindo no ventre; abas amplas (âncora)
    -- separam abaixo da faixa e deixam as pernas finas à vista.
    p({cx - 8, top + 10, cx + 8, top + 10, cx + 10, top + 26, cx - 10, top + 26}, P.ink)
    p({cx - 7, top + 11, cx + 7, top + 11, cx + 9, top + 25, cx - 9, top + 25}, coat)
    p({cx - 7, top + 11, cx - 4, top + 11, cx - 6, top + 25, cx - 9, top + 25}, coatHi)
    p({cx + 5, top + 11, cx + 7, top + 11, cx + 9, top + 25, cx + 6, top + 25}, coatLo)
    d(cx - 5, top + 13, 11, 11, coatLo, .15)
    p({cx - 9, top + 25, cx - 3, top + 25, cx - 5, 39, cx - 10, 39}, P.ink)
    p({cx - 8, top + 26, cx - 3, top + 26, cx - 5, 38, cx - 9, 38}, coat)
    p({cx + 9, top + 25, cx + 3, top + 25, cx + 5, 39, cx + 10, 39}, P.ink)
    p({cx + 8, top + 26, cx + 3, top + 26, cx + 5, 38, cx + 9, 38}, coatLo)
    if north then
        p({cx - 8, top + 26, cx + 8, top + 26, cx + 9, 38, cx - 9, 38}, coat)
        l(cx - 6, top + 27, cx + 6, top + 27, coatHi)
        r(cx - 3, top + 24, 6, 3, C.accent)
    else
        -- Camisa creme no peito + faixa de ouro velho (âncora) + um
        -- botão diferente que ele mantém; veludo só na gola.
        p({cx - 3, top + 11, cx + 3, top + 11, cx + 4, top + 24, cx - 4, top + 24}, P.bone)
        l(cx - 3, top + 12, cx - 4, top + 20, P.boneDark)
        r(cx - 8, top + 22, 17, 2, C.accent); r(cx - 8, top + 22, 17, 1, P.goldLight)
        r(cx - 1, top + 22, 2, 2, P.goldLight)
        r(cx + 1, top + 14, 1, 1, P.jade)
        r(cx - 3, top + 10, 7, 1, mixc(coat, .4, P.white))
    end
    if C.act ~= 'work' then
        -- Braço aberto de boas-vindas com a manga em sino (âncora) +
        -- programa dobrado na mão recolhida.
        local gx = south and cx + 11 or cx + side * 10
        local ax = south and 7 or side * 7
        l(cx + ax, top + 13, gx, top + 9, coat)
        r(gx - 1, top + 5, 5, 5, coat); r(gx - 1, top + 5, 5, 1, coatHi)
        r(gx, top + 3, 3, 3, skin); r(gx + 1, top + 2, 1, 1, skin)
        local bx = south and cx - 8 or cx - side * 8
        r(bx - 1, top + 14, 3, 8, coat)
        r(bx, top + 20, 4, 5, P.ink); r(bx + 1, top + 21, 2, 3, P.bone)
    end
    -- Cabeça comprida: testa ampla, grisalho crespo só atrás, bigode
    -- grosso aparado e sobrancelhas altas.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        d(cx - 3, top + 2, 6, 8, hairLo, .3)
        r(cx - 5, top + 3, 1, 6, hair); r(cx + 5, top + 3, 1, 6, hair)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 2, hair)
        r(cx - side * 5, top + 2, 2, 8, hair)
        r(fx + (side == 1 and 0 or -3), top + 8, 3, 2, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 2, hair); r(cx - 5, top + 1, 2, 7, hair)
        r(cx + 4, top + 1, 2, 7, hair)
        l(cx - 3, top + 4, cx - 1, top + 4, hairLo)
        l(cx + 1, top + 4, cx + 3, top + 4, hairLo)
        r(cx - 2, top + 8, 5, 2, hair); r(cx - 2, top + 8, 5, 1, hairLo)
    end
end

-- CIRA §18 (musician): linha inclinada — camisa ameixa apagada, colete
-- preto curto aberto, calças cinza claras, faixa azul; ombro nu do
-- casaco retirado e cunha curta de cabelo na nuca.
local function bodyMusician(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local shirt, shirtHi, shirtLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 37, P.stoneLight, P.goldDark, nil, P.ink)  -- calças claras
    r(cx - 4, 41, 3, 1, P.boneDark)             -- sola fina reparada
    -- Tronco magro de ombros desnivelados: camisa ameixa.
    p({cx - 6, top + 10, cx + 6, top + 9, cx + 7, 34, cx - 7, 34}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 10, cx + 6, 33, cx - 6, 33}, shirt)
    p({cx - 5, top + 11, cx - 2, top + 10, cx - 3, 33, cx - 6, 33}, shirtHi)
    d(cx - 4, top + 13, 9, 18, shirtLo, .15)
    -- Faixa azul de tecido comum na cintura.
    r(cx - 6, top + 22, 13, 2, C.accent)
    r(cx - 6, top + 22, 13, 1, mixc(C.accent, .3, P.white))
    if not north then
        -- Colete preto curto aberto + ombro nu do casaco retirado.
        p({cx - 6, top + 10, cx - 2, top + 11, cx - 3, top + 22, cx - 6, top + 22}, P.stoneDeep)
        p({cx + 6, top + 9, cx + 2, top + 11, cx + 3, top + 22, cx + 6, top + 22}, mixc(P.stoneDeep, .4))
        r(cx - 4, top + 9, 3, 3, skin); r(cx - 4, top + 9, 3, 1, skinHi)
        r(cx - 4, top + 12, 2, 1, skinLo)
    else
        p({cx - 5, top + 10, cx + 5, top + 9, cx + 5, top + 22, cx - 5, top + 22}, P.stoneDeep)
        l(cx - 4, top + 11, cx - 4, top + 21, P.stone)
        r(cx - 5, top + 22, 11, 2, C.accent)
    end
    if C.act ~= 'work' then
        -- Caixa de cordas estreita na diagonal (âncora): corpo no
        -- quadril, braço subindo ao ombro, mão parando a corda.
        local bx = south and cx - 6 or cx - side * 5
        local nx = south and cx + 6 or bx + side * 8 + 6
        p({bx - 2, top + 22, bx + 4, top + 20, bx + 6, top + 27, bx, top + 29}, P.ink)
        p({bx - 1, top + 23, bx + 3, top + 21, bx + 5, top + 26, bx + 1, top + 28}, P.goldDark)
        l(bx + 3, top + 22, nx, top + 10, P.goldDeep)
        r(nx - 1, top + 8, 3, 3, P.goldDeep)
        l(cx + side * 5, top + 12, bx + 2, top + 23, shirt)
        r(bx, top + 22, 3, 3, skin)
        l(cx - side * 5, top + 12, nx, top + 11, skin)
    end
    -- Cabeça alongada: cunha de cabelo na nuca (âncora), laterais
    -- baixas e a pequena falha numa sobrancelha.
    r(cx - 5, top, 10, 13, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        r(cx - 2, top + 6, 4, 6, hair); l(cx - 4, top + 4, cx - 2, top + 12, hairLo)
        r(cx + 3, top + 4, 2, 5, hairLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 10, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        p({cx - side * 3, top + 2, cx - side * 6, top + 2, cx - side * 5, top + 12, cx - side * 3, top + 12}, hair)
        l(fx + (side == 1 and -2 or 1), top + 5, fx + (side == 1 and -1 or 2), top + 5, skin)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 10, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 2, 8, hair); r(cx + 4, top + 2, 2, 6, hair)
        r(cx - 3, top + 4, 2, 1, hair); r(cx + 1, top + 4, 2, 1, hair)
        r(cx + 1, top + 4, 1, 1, skin)          -- falha na sobrancelha
    end
end

-- Peças de roupa por corpo de ofício: cada uma desenha SOBRE o tronco
-- do garmentNpc — são as âncoras das fichas secundárias (avental
-- dividido, suspensórios, xale, punhos, faixa, gola).
local legacyOverlay = {
    foreman = function(C)
        -- Avental de couro em dois painéis + ombro acolchoado da carga.
        local r, l, p, cx, top = C.r, C.l, C.p, C.cx, C.top
        if not C.north then
            p({cx - 7, top + 14, cx - 1, top + 14, cx - 3, 38, cx - 7, 38}, P.goldDeep)
            p({cx + 7, top + 14, cx + 1, top + 14, cx + 3, 38, cx + 7, 38}, P.goldDeep)
            l(cx - 7, top + 15, cx - 4, 37, P.gold)
            l(cx - 1, top + 15, cx + 1, top + 15, P.ink)
        else
            p({cx - 7, top + 14, cx + 7, top + 14, cx + 6, 38, cx - 6, 38}, P.goldDeep)
            l(cx - 5, top + 15, cx + 4, 37, P.goldDark)
        end
        r(cx - 9, top + 10, 3, 3, C.accent)     -- acolchoamento do ombro
    end,
    artisan = function(C)
        -- Avental ferrugem curto acima dos joelhos com fecho de pano.
        local r, l, p, cx, top = C.r, C.l, C.p, C.cx, C.top
        if not C.north then
            p({cx - 5, top + 15, cx + 5, top + 15, cx + 6, 32, cx - 6, 32}, P.ink)
            p({cx - 4, top + 16, cx + 4, top + 16, cx + 5, 31, cx - 5, 31}, C.accent)
            C.d(cx - 3, top + 18, 7, 11, mixc(C.accent, .4), .2)
            r(cx - 4, 30, 9, 1, mixc(C.accent, .45))
            r(cx - 1, top + 15, 2, 2, P.gold)     -- fecho de pano amarelo
        else
            l(cx - 4, top + 13, cx + 4, top + 26, mixc(C.accent, .4))
        end
    end,
    drifter = function(C)
        -- Suspensórios de tiras claras desiguais sobre a camisa areia.
        local r, l, cx, top = C.r, C.l, C.cx, C.top
        if not C.north then
            l(cx - 4, top + 11, cx - 3, 38, C.accent)
            l(cx + 3, top + 11, cx + 4, 37, C.accent)
            r(cx - 4, top + 20, 1, 2, P.goldDark); r(cx + 4, top + 18, 1, 2, P.goldDark)
        else
            l(cx - 4, top + 11, cx - 4, 36, C.accent); l(cx + 4, top + 11, cx + 4, 36, C.accent)
            r(cx - 4, top + 22, 9, 1, C.accent)
        end
    end,
    appraiser = function(C)
        -- Punhos de linho claros avançando + lapela da gola miúda.
        local r, l, cx, top = C.r, C.l, C.cx, C.top
        r(cx - 6, top + 10, 4, 2, C.accent); r(cx + 3, top + 10, 4, 2, C.accent)
        if C.act ~= 'work' then
            r(cx - 8, top + 20, 3, 3, P.bone); r(cx + 6, top + 20, 3, 3, P.bone)
            r(cx - 8, top + 21, 1, 1, P.boneDark); r(cx + 6, top + 21, 1, 1, P.boneDark)
        end
    end,
    trader = function(C)
        -- Saia ampla curta sobre calças + avental preso de lado.
        local r, l, p, cx, top = C.r, C.l, C.p, C.cx, C.top
        p({cx - 8, top + 24, cx + 8, top + 24, cx + 9, 38, cx - 9, 38}, P.ink)
        p({cx - 7, top + 25, cx + 7, top + 25, cx + 8, 37, cx - 8, 37}, C.accent)
        C.d(cx - 6, top + 26, 13, 9, mixc(C.accent, .4), .18)
        if not C.north then
            p({cx + 3, top + 15, cx + 7, top + 15, cx + 8, 30, cx + 4, 30}, P.ink)
            p({cx + 4, top + 16, cx + 6, top + 16, cx + 7, 29, cx + 5, 29}, P.boneDark)
            r(cx + 5, top + 17, 2, 1, P.bone)
        end
    end,
    gardener = function(C)
        -- Mangas creme largas + barra úmida da saia de trabalho.
        local r, l, cx, top = C.r, C.l, C.cx, C.top
        if C.act ~= 'work' then
            r(cx - 9, top + 13, 3, 8, P.ink); r(cx - 8, top + 14, 2, 5, P.bone)
            r(cx - 8, top + 19, 2, 3, C.skin)
            r(cx + 6, top + 13, 3, 8, P.ink); r(cx + 7, top + 14, 2, 5, P.bone)
            r(cx + 7, top + 19, 2, 3, C.skin)
        end
        l(cx - 6, 40, cx + 6, 40, mixc(C.cloth, .4))
    end,
    operator = function(C)
        -- Casacão encerado de barra rígida + manchas de óleo localizadas.
        local r, l, cx, top = C.r, C.l, C.cx, C.top
        r(cx - 7, 37, 15, 3, mixc(C.cloth, .35))
        r(cx - 7, 37, 15, 1, mixc(C.cloth, .3, P.white))
        r(cx - 4, top + 22, 2, 3, P.ink); r(cx + 3, top + 27, 2, 2, P.ink)
        -- Faixa de tecido no pescoço.
        r(cx - 5, top + 10, 11, 2, C.accent)
    end,
    maestro = function(C)
        -- Faixa de ouro velho na cintura + abas amplas da casaca.
        local r, l, p, cx, top = C.r, C.l, C.p, C.cx, C.top
        r(cx - 7, top + 20, 15, 2, C.accent); r(cx - 7, top + 20, 15, 1, mixc(C.accent, .35, P.white))
        r(cx - 1, top + 20, 2, 2, P.goldLight)
        if not C.north then
            l(cx - 6, top + 22, cx - 8, 40, C.clothLo)
            l(cx + 6, top + 22, cx + 8, 40, C.clothLo)
        end
    end,
    artist = function(C)
        -- Colete curto escuro aberto sobre a camisa + faixa na cintura.
        local r, l, p, cx, top = C.r, C.l, C.p, C.cx, C.top
        if not C.north then
            p({cx - 6, top + 11, cx - 2, top + 12, cx - 3, 26, cx - 6, 26}, P.ink)
            p({cx + 6, top + 11, cx + 2, top + 12, cx + 3, 26, cx + 6, 26}, P.ink)
            r(cx - 7, 26, 15, 2, C.accent)
        else
            p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, 26, cx - 6, 26}, P.ink)
            r(cx - 6, top + 11, 12, 2, C.clothLo)
        end
    end,
}

-- Corpos compartilhados dos figurantes e das regiões: mesma anatomia-
-- vestido, adornos de ficha por body — o porte muda, a régua não.
local function bodyLegacy(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local v = C.pal.body or 'plain'
    local hunch = C.hunch
    -- Capa curta opcional (pal.cape): manto dos guardas e viajantes.
    if C.pal.cape and not C.south then
        p({cx - 8, top + 10, cx + 8, top + 10, cx + 7, 34, cx - 7, 34}, P.ink)
        p({cx - 7, top + 11, cx + 7, top + 11, cx + 6, 33, cx - 6, 33}, C.pal.cape)
    elseif C.pal.cape then
        r(cx - 9, top + 11, 2, 18, C.pal.cape); r(cx + 8, top + 11, 2, 18, mixc(C.pal.cape, .4))
    end
    npcFeet(r, cx, v == 'stoop' and 38 or v == 'child' and 40 or 39,
        C.pal.pants or P.stoneDeep, C.pal.boots or P.goldDeep, nil, P.ink)
    garmentNpc(C, v == 'child' and 5 or 7 + (C.wide or 0) - (C.narrow or 0) + hunch,
        42, {belt = v ~= 'child' and C.accent or nil})
    if v == 'child' then
        -- Dobra larga da barra das calças de herança grande demais.
        r(cx - 4, 39, 3, 1, C.accent); r(cx + 3, 39, 3, 1, C.accent)
    end
    if v == 'stoop' then r(cx - 8, top + 12, 2, 8, C.cloth) end
    if v == 'bun' then
        p({cx - 5, top + 16, cx + 6, top + 16, cx + 7, 40, cx - 6, 40}, P.boneDark)
        l(cx - 5, top + 17, cx + 6, top + 17, C.accent)
        d(cx - 4, top + 19, 9, 18, mixc(P.boneDark, .4), .15)
    end
    if legacyOverlay[v] then legacyOverlay[v](C) end
end

-- Moradores do Refúgio e das regiões: pessoas vestidas, não recolors.
-- `pal.body` escolhe a anatomia: o núcleo tem corpo próprio por ficha
-- (wright/sentry/stout/drape/dean/youth/vigil) e as regiões também
-- (forge/smith/hauler/vendor/assessor/planter/engineer/host/musician);
-- os figurantes usam os corpos de ofício com adorno próprio (stoop/
-- long/bun/bald/cowl/hood/veil/foreman/artisan/drifter/appraiser/
-- trader/operator/gardener/maestro/artist).
--====================================================================--
-- LOTE FIBRA - corpos canonicos dos figurantes (doc "Elenco
-- secundario" + fichas de regiao) e adornos de retrato por body.
-- Integrado de tools/fibra/lote.lua; "fair" = feirante (vendor ja
-- era o corpo da Ema).
--====================================================================--

-- ANCIÃO: baixo, magro, pele escura, cabelo branco ralo; casaco areia
-- até o joelho e bengala comum. Âncoras: casaco longo, bengala, cabeça
-- clara. Corcova leve — o tronco tombado na direção encarada.
local function bodyElder(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair = C.hair
    local lean = south and 1 or side                        -- corcova p/ frente
    -- Pernas magras sob a barra longa do casaco.
    npcFeet(r, cx, 37, P.stoneDark, P.goldDeep, nil, P.ink)
    -- Casaco areia até o joelho: ombros à frente do quadril (corcova),
    -- fenda frontal com V escuro da abertura.
    p({cx - 6 + lean, top + 10, cx + 6 + lean, top + 10, cx + 7, 37,
        cx - 7, 37}, P.ink)
    p({cx - 5 + lean, top + 11, cx + 5 + lean, top + 11, cx + 6, 36,
        cx - 6, 36}, coat)
    p({cx - 5 + lean, top + 11, cx - 2 + lean, top + 11, cx - 3, 36,
        cx - 6, 36}, coatHi)
    p({cx + 3 + lean, top + 11, cx + 5 + lean, top + 11, cx + 6, 36,
        cx + 4, 36}, coatLo)
    d(cx - 4 + lean, top + 14, 8, 18, coatLo, .15)
    r(cx - 6, 35, 12, 1, coatLo)                              -- barra gasta
    if not north then
        -- Abertura frontal: filete escuro + botões puídos; gola fechada.
        l(cx + lean, top + 12, cx, 30, coatLo)
        r(cx - 1, top + 14, 1, 1, C.accent); r(cx - 1, top + 19, 1, 1, C.accent)
        r(cx - 1, top + 24, 1, 1, C.accent)
        r(cx - 3 + lean, top + 10, 6, 2, coatLo)              -- gola alta
    else
        l(cx - 1, top + 13, cx - 1, 34, coatLo)               -- costa da cauda
    end
    if C.act ~= 'work' then
        -- Braço livre descido; o outro segura a bengala.
        r(cx - 8 + lean, top + 13, 3, 10, P.ink)
        r(cx - 7 + lean, top + 14, 2, 7, coat)
        r(cx - 7 + lean, top + 21, 2, 2, skin)
    end
    -- Bengala comum (âncora): haste escura + mão de pele no topo.
    local sx = south and cx + 9 or cx + side * 8
    l(cx + (south and 4 or side * 4), top + 13, sx, top + 15, skin)
    l(sx, top + 11, sx, 42, P.goldDeep)
    r(sx - 1, top + 10, 3, 2, P.goldDark)                     -- pomo
    r(sx - 1, 41, 2, 1, P.ink)                                -- ponteira
    -- Cabeça: pele escura, cabelo branco RALO (filetes, não capacete),
    -- rosto atento e gasto — "cabeça clara" lê-se pela nuca/parte alta.
    r(cx - 5 + lean, top, 10, 12, P.ink)
    if north then
        r(cx - 4 + lean, top + 1, 8, 10, skin)
        r(cx - 4 + lean, top + 1, 8, 4, hair)                 -- alto branco
        r(cx - 4 + lean, top + 5, 2, 4, hair)                 -- tira rala
        r(cx + 2 + lean, top + 5, 1, 3, hair)
        l(cx - 4 + lean, top + 9, cx + 3 + lean, top + 9, skinLo)
    elseif side ~= 0 then
        local fx = cx + lean + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4 + lean, top, 8, 3, hair)                     -- topo ralo
        r(cx - side * 5 + lean, top + 2, 2, 6, hair)          -- nuca branca
        r(fx + (side == 1 and 3 or -4), top + 5, 1, 1, hair)  -- fio na têmpora
    else
        faceNpc(r, l, cx - 4 + lean, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        -- Cabelo branco ralo: aro alto e têmporas, testa de pele aberta.
        r(cx - 4 + lean, top, 8, 2, hair)
        r(cx - 5 + lean, top + 2, 1, 6, hair); r(cx + 4 + lean, top + 2, 1, 6, hair)
        r(cx - 3 + lean, top + 2, 2, 1, hair); r(cx + 2 + lean, top + 2, 1, 1, hair)
        -- Pálpebras pesadas + sulco de expressão serena.
        r(cx - 3 + lean, top + 5, 2, 1, skinLo); r(cx + 2 + lean, top + 5, 1, 1, skinLo)
        r(cx - 1 + lean, top + 10, 3, 1, skinLo)
    end
end

-- ANCIÃO SENTADO (act 'sit'): anatomia própria — pernas dobradas à
-- frente, casaco areia cobrindo os joelhos, bengala escorada na lateral.
-- Nunca capuz de pano: a cabeça é de pele escura com cabelo branco ralo.
local function seatedElder(r, l, p, cx, direction, pal, frame)
    local east, south, west, north = direction == 1, direction == 2,
        direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local top = 19 + ({0, -1, 0, 0})[frame]
    local skin = pal.skin or P.goldLight
    local skinHi = mixc(skin, .3, P.white)
    local skinLo = mixc(skin, .35)
    local coat = pal.cloth or P.boneDark
    local coatLo = mixc(coat, .42)
    local hair = pal.hair or P.bone
    -- Pernas dobradas adiante (joelho + canela baixa) + massa do casaco.
    r(cx - 4, 38, 12, 4, P.ink); r(cx - 3, 39, 10, 2, P.stoneDark)
    r(cx + 4, 40, 4, 3, P.ink); r(cx + 4, 41, 3, 2, P.goldDeep)
    p({cx - 7, top + 10, cx + 7, top + 9, cx + 9, 38, cx - 8, 38}, P.ink)
    p({cx - 6, top + 11, cx + 6, top + 10, cx + 8, 37, cx - 7, 37}, coat)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, 37, cx - 7, 37},
        mixc(coat, .25, P.white))
    r(cx - 6, top + 11, 12, 1, pal.accent or P.goldDark)      -- gola/faixa
    l(cx, top + 13, cx + 1, 34, coatLo)
    -- Mão livre apoiada no joelho.
    r(cx + 5, 33, 3, 3, skin)
    -- Cabeça de pele com cabelo branco ralo por cima e nas laterais.
    p({cx - 5, top, cx + 5, top - 1, cx + 6, top + 4, cx + 5, top + 12,
        cx - 5, top + 12, cx - 6, top + 4}, P.ink)
    local fx = cx + side * 2
    if north then
        r(cx - 4, top + 1, 9, 11, skin)
        r(cx - 4, top, 9, 4, hair); r(cx - 4, top + 4, 2, 5, hair)
        r(cx + 3, top + 4, 1, 3, hair)
    elseif south then
        faceNpc(r, l, fx - 3, top + 3, 7, 8, skin, skinHi, skinLo,
            pal.eye or P.jadeLight)
        r(cx - 4, top, 8, 2, hair)
        r(cx - 5, top + 1, 1, 5, hair); r(cx + 4, top + 1, 1, 5, hair)
        r(fx - 2, top + 7, 1, 1, skinLo); r(fx + 2, top + 7, 1, 1, skinLo)
    else
        faceNpcSide(r, l, fx - 3, top + 3, 7, 8, side, skin, skinHi,
            skinLo, pal.eye or P.jadeLight)
        r(cx - 4, top, 8, 3, hair); r(cx - side * 5, top + 1, 2, 5, hair)
    end
    -- Bengala escorada na lateral do banco.
    local sx = south and cx + 10 or cx + side * 9
    l(sx, top + 8, sx - (south and 2 or side), 42, P.goldDeep)
    r(sx - 1, top + 7, 3, 2, P.goldDark)
end

-- LAVADEIRA: robusta, pele cobre, cabelo num rolo preso atrás; manga
-- dobrada (antebraço de pele), saia azul, avental claro. Âncoras:
-- mangas claras/dobradas, rolo de cabelo, tecido horizontal.
local function bodyWash(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    local apron, apronHi, apronLo = C.accent, mixc(C.accent, .3, P.white),
        mixc(C.accent, .4)
    -- Saia azul larga até a canela sobre calça de trabalho.
    npcFeet(r, cx, 38, P.stoneDeep, P.goldDeep, nil, P.ink)
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 9, 39, cx - 9, 39}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 8, 38, cx - 8, 38}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 5, 38, cx - 8, 38}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 8, 38, cx + 6, 38}, clothLo)
    d(cx - 4, top + 15, 9, 20, clothLo, .15)
    r(cx - 8, 37, 16, 1, clothLo)                             -- barra úmida
    -- Avental claro (âncora): painel frontal estreito com alça na cintura.
    if not north then
        p({cx - 4, top + 17, cx + 4, top + 17, cx + 6, 35, cx - 6, 35}, P.ink)
        p({cx - 3, top + 18, cx + 3, top + 18, cx + 5, 34, cx - 5, 34}, apron)
        d(cx - 2, top + 20, 5, 12, apronLo, .12)
        l(cx - 4, top + 17, cx + 4, top + 17, apronLo)
        r(cx - 5, top + 16, 10, 1, apronLo)                   -- alça de cintura
        r(cx + 3, 33, 2, 2, apronLo)                          -- mancha de uso
    else
        l(cx - 4, top + 16, cx + 4, top + 16, apronLo)        -- laço nas costas
        r(cx - 1, top + 15, 3, 2, apron)
    end
    if C.act ~= 'work' then
        -- Manga dobrada (âncora): meia-manga do pano + dobra clara +
        -- antebraço de pele à mostra — braços de quem trabalha na água.
        r(cx - 9, top + 12, 3, 7, P.ink); r(cx - 8, top + 13, 2, 4, cloth)
        r(cx - 8, top + 17, 2, 2, apronHi)                    -- dobra dobrada
        r(cx - 8, top + 19, 2, 4, skin); r(cx - 8, top + 23, 2, 2, skin)
        r(cx + 6, top + 12, 3, 7, P.ink); r(cx + 7, top + 13, 2, 4, clothLo)
        r(cx + 7, top + 17, 2, 2, apronHi)
        r(cx + 7, top + 19, 2, 4, skin); r(cx + 7, top + 23, 2, 2, skin)
    end
    -- Cabeça: cabelo preso num ROLO atrás (âncora) — massa baixa na nuca,
    -- fios puxados da testa; de costas o rolo é a marca.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 6, hairLo, .3)
        r(cx - 2, top + 8, 5, 4, hair); r(cx - 1, top + 9, 3, 2, hairLo)
        r(cx - 1, top + 12, 3, 1, skinLo)                     -- nuca
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 4, top + 3, 1, 1, hair)
        r(cx + 3, top + 3, 1, 1, hair)
        -- O rolo espreita atrás da mandíbula.
        r(cx - side * 5 - (side == 1 and 1 or 0), top + 7, 3, 4, hair)
        r(cx - side * 5 - (side == 1 and 1 or 0), top + 8, 1, 2, hairLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 5, hair); r(cx + 4, top + 2, 1, 4, hair)
        -- Bochechas de quem ri dobrando pano + força no rosto.
        r(cx - 3, top + 7, 1, 1, skinLo); r(cx + 3, top + 7, 1, 1, skinLo)
    end
end

-- CARREGADOR: mediano, peito largo, pele clara oliva, barba negra curta;
-- proteção de lona num ombro. Âncoras: ombro quadrado, barba escura,
-- alça larga.
local function bodyPorter(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    local pad, padHi, padLo = P.goldDark, P.gold, P.goldDeep   -- lona do ombro
    npcFeet(r, cx, 34, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Peito largo (âncora): tronco quadrado de camisa puída.
    p({cx - 8, top + 10, cx + 8, top + 10, cx + 8, 35, cx - 8, 35}, P.ink)
    p({cx - 7, top + 11, cx + 7, top + 11, cx + 7, 34, cx - 7, 34}, cloth)
    p({cx - 7, top + 11, cx - 3, top + 11, cx - 4, 34, cx - 7, 34}, clothHi)
    p({cx + 4, top + 11, cx + 7, top + 11, cx + 7, 34, cx + 5, 34}, clothLo)
    d(cx - 5, top + 15, 10, 16, clothLo, .15)
    r(cx - 7, 32, 14, 2, clothLo)                             -- barra cintura
    if north then
        -- Alça larga cruzando o dorso + canto do fardo por cima.
        l(cx + 4, top + 11, cx - 4, 30, P.goldDeep)
        l(cx + 4, top + 12, cx - 4, 31, pad)
    else
        -- Alça larga diagonal (âncora): do ombro da lona ao quadril.
        l(cx - 5, top + 11, cx + 5, 33, P.goldDeep)
        l(cx - 5, top + 12, cx + 5, 34, pad)
        r(cx + 3, 28, 3, 2, P.goldDeep)                       -- fivela
    end
    -- Proteção de lona no ombro esquerdo (âncora): bloco quadrado que
    -- quebra a linha do ombro — a marca do carregador.
    p({cx - 10, top + 8, cx - 5, top + 7, cx - 4, top + 13, cx - 9, top + 15},
        P.ink)
    p({cx - 9, top + 9, cx - 5, top + 8, cx - 4, top + 12, cx - 8, top + 14},
        pad)
    l(cx - 9, top + 9, cx - 6, top + 8, padHi)
    l(cx - 8, top + 10, cx - 5, top + 12, padLo)
    if C.act ~= 'work' then
        -- Braços de carga: manga curta + antebraço de pele grosso.
        r(cx + 7, top + 12, 3, 8, P.ink); r(cx + 8, top + 13, 2, 4, clothLo)
        r(cx + 8, top + 17, 2, 4, skin); r(cx + 8, top + 21, 2, 2, skin)
        r(cx - 8, top + 15, 3, 8, skin)                       -- braço da lona
    end
    -- Cabeça: cabelo escuro curto + barba negra curta fechando o queixo.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 8, hairLo, .3)
        r(cx - 4, top + 9, 8, 2, skin)                        -- nuca de pele
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 4, hair)
        r(cx + 4, top + 2, 1, 3, hair)
        -- Barba curta no perfil: maxilar escuro à frente.
        r(fx + (side == 1 and 2 or -4), top + 8, 2, 3, hair)
        r(fx + (side == 1 and 1 or -3), top + 10, 3, 1, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hair); r(cx + 2, top + 3, 1, 1, hair)
        -- Barba negra curta (âncora): laterais do maxilar + queixo.
        r(cx - 4, top + 8, 1, 3, hair); r(cx + 4, top + 8, 1, 3, hair)
        r(cx - 3, top + 10, 6, 1, hair)
        r(cx - 1, top + 10, 2, 1, skinLo)                     -- boca na barba
    end
end

-- LENHADOR: alto, corpo forte, pele marrom, cabelo crespo curto; casaco
-- cinza reto e calças escuras. Âncoras: altura, faixa clara no punho,
-- casaco reto; machado contextual.
local function bodyLogger(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 33, P.stoneDeep, P.ink, nil, P.ink)        -- calças escuras
    -- Casaco cinza RETO (âncora): lados paralelos, barra firme na coxa.
    p({cx - 8, top + 10, cx + 8, top + 10, cx + 8, 36, cx - 8, 36}, P.ink)
    p({cx - 7, top + 11, cx + 7, top + 11, cx + 7, 35, cx - 7, 35}, coat)
    p({cx - 7, top + 11, cx - 3, top + 11, cx - 4, 35, cx - 7, 35}, coatHi)
    p({cx + 4, top + 11, cx + 7, top + 11, cx + 7, 35, cx + 5, 35}, coatLo)
    d(cx - 5, top + 14, 10, 18, coatLo, .15)
    if not north then
        -- Abertura frontal + cinto de trabalho com ponta pendente.
        l(cx, top + 12, cx, 30, coatLo)
        r(cx - 6, top + 22, 13, 2, P.goldDeep)
        r(cx + 1, top + 22, 2, 2, P.gold)
        r(cx + 2, top + 24, 1, 3, P.goldDeep)                 -- ponta do cinto
    else
        l(cx - 1, top + 12, cx - 1, 33, coatLo)
        r(cx - 6, top + 22, 13, 2, coatLo)
    end
    if C.act ~= 'work' then
        -- Braço da faixa: manga cinza até o cotovelo + FAIXA CLARA no
        -- punho (âncora) + mão. O outro braço segura o machado.
        r(cx - 10, top + 12, 3, 10, P.ink); r(cx - 9, top + 13, 2, 6, coat)
        r(cx - 9, top + 19, 2, 2, C.accent)                   -- faixa clara
        r(cx - 9, top + 21, 2, 3, skin)
        r(cx + 7, top + 12, 3, 10, P.ink); r(cx + 8, top + 13, 2, 6, coatLo)
        r(cx + 8, top + 19, 2, 2, C.accent)
        r(cx + 8, top + 21, 2, 3, skin)
        -- Machado contextual: cabo apoiado no ombro, lâmina para trás.
        local ax = south and cx + 11 or cx + side * 11
        l(cx + side * 4, top + 12, ax, top + 8, skin)
        l(ax, top - 3, ax, top + 9, P.goldDark)
        r(ax - 2, top - 4, 5, 4, P.stoneDark); r(ax - 2, top - 4, 5, 1, P.stoneLight)
        r(ax - 2, top - 1, 1, 1, P.stoneLight)
    end
    -- Cabeça: cabelo crespo curto — casquete texturizado, linha de
    -- plantio baixa; rosto largo e firme.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 4, top + 1, 8, 5, hairLo, .35)                 -- textura crespa
        r(cx - 4, top + 9, 8, 2, skin)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 2, 5, hair)
        r(cx + 4, top + 1, 1, 4, hair)
        r(cx - 4, top + 3, 1, 1, hairLo); r(cx + 2, top + 2, 1, 1, hairLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 4, hair)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hairLo); r(cx + 2, top + 3, 1, 1, hairLo)
        r(cx - 1, top + 3, 1, 1, hairLo)                      -- textura crespa
    end
end

-- CRIANÇA DO REFÚGIO: 7-10 anos, baixa, pele parda, cabelo encaracolado
-- curto; blusa ocre e calças azuis de dobra larga. Âncoras: cabeça
-- arredondada, dobra de calça, blusa ocre.
local function bodyKid(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    -- Calças azuis de DOBRA LARGA (âncora): herança grande demais — o
    -- punho dobrado lê no tornozelo.
    npcFeet(r, cx, 36, C.pal.pants or P.stone, P.goldDeep, nil, P.ink)
    r(cx - 4, 38, 3, 2, C.accent); r(cx + 3, 38, 3, 2, C.accent)
    r(cx - 4, 38, 3, 1, mixc(C.accent, .3, P.white))
    r(cx + 3, 38, 3, 1, mixc(C.accent, .3, P.white))
    -- Blusa ocre (âncora): túnica curta e fofa, gola simples.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 7, 36, cx - 7, 36}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, 35, cx - 6, 35}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 35, cx - 6, 35}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 6, 35, cx + 4, 35}, clothLo)
    r(cx - 5, 34, 11, 1, clothLo)                             -- barra da blusa
    if not north then
        r(cx - 2, top + 10, 5, 2, clothLo)                    -- gola
        r(cx - 1, top + 12, 1, 1, C.accent)                   -- botão
    end
    if C.act ~= 'work' then
        -- Manguinhas curtas + braços de pele — criança de correr.
        r(cx - 8, top + 12, 3, 6, P.ink); r(cx - 7, top + 13, 2, 3, cloth)
        r(cx - 7, top + 16, 2, 4, skin)
        r(cx + 5, top + 12, 3, 6, P.ink); r(cx + 6, top + 13, 2, 3, clothLo)
        r(cx + 6, top + 16, 2, 4, skin)
    end
    -- Cabeça ARREDONDADA (âncora) grande pro corpo + cachos curtos
    -- escapando nas bordas — a silhueta é quase um círculo sobre o
    -- pescocinho de pele que separa cabeça da blusa.
    r(cx - 3, top + 12, 6, 2, skin)                           -- pescoço
    p({cx - 5, top + 2, cx - 4, top, cx + 4, top - 1, cx + 5, top + 2,
        cx + 5, top + 10, cx + 4, top + 12, cx - 4, top + 12, cx - 5, top + 10},
        P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        d(cx - 4, top + 1, 8, 9, hairLo, .4)                  -- caracol cerrado
        r(cx - 5, top + 4, 1, 3, hair); r(cx + 5, top + 3, 1, 3, hair)
        r(cx - 3, top, 2, 1, hair); r(cx + 2, top, 1, 1, hair)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 3, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        d(cx - 4, top, 8, 3, hairLo, .35)
        r(cx - side * 5, top + 2, 2, 6, hair)                 -- cachos atrás
        r(cx - 5, top + 1, 1, 2, hair); r(cx + 4, top + 1, 1, 2, hair)
        r(cx - side * 5 - 1, top + 5, 1, 2, hair)
    else
        faceNpc(r, l, cx - 4, top + 3, 8, 9, skin, skinHi, skinLo, eye)
        -- Encaracolado curto: massa no topo + pontas enroladas nas
        -- têmporas — nunca capacete liso.
        r(cx - 4, top, 8, 3, hair)
        d(cx - 4, top, 8, 3, hairLo, .35)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 5, top + 1, 1, 4, hair)
        r(cx - 6, top + 4, 1, 2, hair); r(cx + 5, top + 4, 1, 2, hair)
        r(cx - 3, top + 3, 1, 1, hair); r(cx + 2, top + 3, 1, 1, hair)
        -- Olhos grandes demais para o rosto + covinha de sorriso.
        r(cx - 3, top + 6, 2, 1, eye); r(cx + 2, top + 6, 2, 1, eye)
        r(cx - 3, top + 10, 1, 1, skinLo); r(cx + 3, top + 10, 1, 1, skinLo)
    end
end

--====================================================================--
-- FIGURANTES DE REGIÃO — fichas breves do doc, densidade de núcleo.
--====================================================================--

-- TRABALHADORA DAS OFICINAS (traba): alta, magra, cabelo liso trançado;
-- camisa barro e avental curto claro. Âncoras: trança baixa, camisa
-- barro, avental curto.
local function bodyBraid(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 33, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Figura alta e magra: camisa barro justa até o quadril.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 6, 35, cx - 6, 35}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 5, 34, cx - 5, 34}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 34, cx - 5, 34}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 5, 34, cx + 4, 34}, clothLo)
    d(cx - 3, top + 14, 6, 17, clothLo, .15)
    if not north then
        -- Avental curto claro (âncora): só até meio da coxa, alça V.
        p({cx - 4, top + 16, cx + 4, top + 16, cx + 5, 31, cx - 5, 31}, P.ink)
        p({cx - 3, top + 17, cx + 3, top + 17, cx + 4, 30, cx - 4, 30}, P.bone)
        l(cx - 3, top + 17, cx - 1, top + 11, P.boneDark)
        l(cx + 3, top + 17, cx + 1, top + 11, P.boneDark)
        d(cx - 2, top + 19, 4, 9, P.boneDark, .12)
        r(cx - 4, 29, 8, 1, P.boneDark)                       -- barra puída
        r(cx + 2, top + 22, 2, 3, P.boneDark)                 -- bolso
        r(cx + 2, top + 22, 2, 1, P.bone)
    else
        l(cx - 3, top + 16, cx + 3, top + 16, P.boneDark)     -- laço
    end
    if C.act ~= 'work' then
        r(cx - 8, top + 12, 3, 10, P.ink); r(cx - 7, top + 13, 2, 6, cloth)
        r(cx - 7, top + 19, 2, 3, skin)
        r(cx + 5, top + 12, 3, 10, P.ink); r(cx + 6, top + 13, 2, 6, clothLo)
        r(cx + 6, top + 19, 2, 3, skin)
    end
    -- Cabeça: cabelo liso puxado + TRANÇA BAIXA (âncora) caindo pelas
    -- costas/ombro — escama de três tons, ponta atada.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        -- A trança desce inteira pelas costas: elos alternados.
        for i = 0, 4 do
            r(cx - 1, top + 8 + i * 4, 3, 3, i % 2 == 0 and hair or hairLo)
        end
        r(cx - 1, top + 28, 3, 1, C.accent)                   -- atadura
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 5, hair)
        r(cx + 4, top + 2, 1, 4, hair)
        -- Trança atrás descendo junto à nuca.
        local bx = cx - side * 5
        for i = 0, 3 do
            r(bx - 1, top + 5 + i * 4, 3, 3, i % 2 == 0 and hair or hairLo)
        end
        r(bx - 1, top + 20, 3, 1, C.accent)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 5, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hair); r(cx + 1, top + 3, 2, 1, hair)
        -- Ponta da trança passando sobre o ombro direito.
        r(cx + 5, top + 9, 3, 8, hair); r(cx + 5, top + 9, 1, 7, hairLo)
        r(cx + 5, top + 16, 3, 1, C.accent)
    end
end

-- TRABALHADOR DAS OFICINAS (trabb): baixo, robusto, cabeça raspada;
-- colete verde e mangas escuras. Âncoras: cabeça lisa, colete quadrado,
-- altura baixa.
local function bodyStocky(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local vest, vestHi, vestLo = C.accent, mixc(C.accent, .25, P.white),
        mixc(C.accent, .45)
    local sleeve = C.cloth                                   -- mangas escuras
    npcFeet(r, cx, 36, C.pal.pants or P.stoneDeep, P.ink, nil, P.ink)
    -- Tronco quadrado baixo: mangas escuras nos ombros + COLETE VERDE
    -- quadrado (âncora) aberto na frente.
    p({cx - 9, top + 10, cx + 9, top + 10, cx + 9, 36, cx - 9, 36}, P.ink)
    p({cx - 8, top + 11, cx + 8, top + 11, cx + 8, 35, cx - 8, 35}, sleeve)
    p({cx - 8, top + 11, cx - 5, top + 11, cx - 6, 35, cx - 8, 35},
        mixc(sleeve, .25, P.white))
    if not north then
        p({cx - 6, top + 11, cx - 1, top + 13, cx - 2, 33, cx - 6, 33}, vest)
        p({cx + 6, top + 11, cx + 1, top + 13, cx + 2, 33, cx + 6, 33}, vestLo)
        l(cx - 6, top + 12, cx - 2, 32, vestHi)
        r(cx - 1, top + 13, 3, 14, P.bone)                    -- peito da camisa
        d(cx - 1, top + 14, 3, 12, P.boneDark, .15)
        r(cx - 6, 31, 12, 2, vestLo)                          -- barra do colete
        r(cx - 2, top + 21, 4, 1, P.goldDeep)                 -- cinto
    else
        p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, 33, cx - 6, 33}, vest)
        p({cx - 6, top + 11, cx - 2, top + 11, cx - 3, 33, cx - 6, 33}, vestHi)
        r(cx - 6, 31, 12, 2, vestLo)
    end
    if C.act ~= 'work' then
        -- Mangas escuras arregaçadas + antebraços de pele de quem forja.
        r(cx - 11, top + 12, 3, 9, P.ink); r(cx - 10, top + 13, 2, 5, sleeve)
        r(cx - 10, top + 18, 2, 1, mixc(sleeve, .35, P.white))
        r(cx - 10, top + 19, 2, 3, skin)
        r(cx + 8, top + 12, 3, 9, P.ink); r(cx + 9, top + 13, 2, 5, sleeve)
        r(cx + 9, top + 19, 2, 3, skin)
    end
    -- CABEÇA RASPADA (âncora): crânio de pele em rampa, brilho de lã
    -- recém-passada, sombra de barba por fazer na base.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, skin)
        r(cx - 4, top + 1, 8, 2, skinHi)
        d(cx - 4, top + 4, 8, 5, skinLo, .2)
        r(cx - 4, top + 9, 8, 2, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - side * 5, top + 2, 2, 7, skin)
        r(cx - 4, top, 8, 1, skinHi)                          -- brilho do couro
        r(cx - side * 5, top + 8, 2, 2, skinLo)               -- sombra de barba
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top + 2, 8, 1, skinHi)                      -- brilho
        r(cx - 4, top + 8, 8, 1, skinLo)                      -- sombra de barba
        r(cx - 2, top + 9, 4, 1, skinLo)
    end
end

-- GUARDA DA FEIRA (guarda): alto, manto curto sobre túnica simples;
-- o par descrito no doc divide a mesma função — esta leitura serve ao
-- integrador como base dos dois corpos. Âncoras: altura, manto curto,
-- postura de posto.
local function bodyWatch(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local cape, capeHi, capeLo = C.pal.cape or P.stoneDark,
        mixc(C.pal.cape or P.stoneDark, .3, P.white),
        mixc(C.pal.cape or P.stoneDark, .45)
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 32, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Túnica de posto: reta, cinto com placa, barra sobre a canela.
    p({cx - 7, top + 10, cx + 7, top + 10, cx + 7, 34, cx - 7, 34}, P.ink)
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, 33, cx - 6, 33}, cloth)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, 33, cx - 6, 33}, clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, 33, cx + 4, 33}, clothLo)
    r(cx - 6, top + 24, 12, 2, P.goldDeep); r(cx - 1, top + 24, 2, 2, P.gold)
    -- Manto curto (âncora): capa de meio-braço caída do ombro de trás,
    -- borda com filete — abre o peito da túnica.
    if north then
        p({cx - 8, top + 9, cx + 8, top + 9, cx + 7, top + 24,
            cx - 7, top + 24}, P.ink)
        p({cx - 7, top + 10, cx + 7, top + 10, cx + 6, top + 23,
            cx - 6, top + 23}, cape)
        p({cx - 7, top + 10, cx - 4, top + 10, cx - 3, top + 23,
            cx - 6, top + 23}, capeHi)
        l(cx - 6, top + 22, cx + 6, top + 22, capeLo)
    else
        local back = -side                                   -- lado de trás
        p({cx + back * 3 - 5, top + 9, cx + back * 6 + 1, top + 10,
            cx + back * 7, top + 26, cx + back * 2 - 2, top + 25}, P.ink)
        p({cx + back * 3 - 4, top + 10, cx + back * 6, top + 11,
            cx + back * 6, top + 25, cx + back * 2 - 1, top + 24}, cape)
        l(cx + back * 3 - 4, top + 10, cx + back * 6 - 1, top + 11, capeHi)
        d(cx + back * 2 - 1, top + 13, 5, 10, capeLo, .2)
        -- Fecho do manto no ombro.
        r(cx + back * 3 - 1, top + 10, 3, 3, C.accent)
        r(cx + back * 3, top + 11, 1, 1, P.goldLight)
    end
    if C.act ~= 'work' then
        -- Braço da frente caído; mão aberta de posto (não de arma).
        r(cx - 9, top + 13, 3, 10, P.ink); r(cx - 8, top + 14, 2, 6, cloth)
        r(cx - 8, top + 20, 2, 3, skin)
        if south or side == 0 then
            r(cx + 6, top + 13, 3, 10, P.ink); r(cx + 7, top + 14, 2, 6, clothLo)
            r(cx + 7, top + 20, 2, 3, skin)
        end
    end
    -- Cabeça: cabelo curto de serviço, queixo firme — guarda, não
    -- soldado de guerra.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 7, hairLo, .25)
        r(cx - 4, top + 9, 8, 2, skin)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 2, 4, hair)
        r(cx + 4, top + 1, 1, 3, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 10, 6, 1, skinLo)                     -- linha séria
    end
end

-- FEIRANTE: corpo médio, cabelo branco crespo preso com pano; gola azul,
-- saia-calça cinza e bolsa estreita. Âncoras: pano na cabeça, gola azul,
-- bolsa estreita.
local function bodyFair(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo                    -- branco crespo
    local wrap, wrapHi = C.pal.headWrap or P.bone,
        mixc(C.pal.headWrap or P.bone, .3, P.white)
    npcFeet(r, cx, 35, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Saia-calça cinza (âncora): barra ampla dividida ao meio.
    p({cx - 7, top + 20, cx + 7, top + 20, cx + 9, 39, cx - 9, 39}, P.ink)
    p({cx - 6, top + 21, cx + 6, top + 21, cx + 8, 38, cx - 8, 38}, P.stoneDark)
    p({cx - 6, top + 21, cx - 3, top + 21, cx - 5, 38, cx - 8, 38}, P.stone)
    l(cx, top + 22, cx, 37, P.ink)                            -- fenda da saia
    r(cx - 8, 37, 16, 1, P.ink)
    -- Blusa de manga ampla + GOLA AZUL (âncora) marcando o pescoço.
    p({cx - 7, top + 10, cx + 7, top + 10, cx + 7, top + 22, cx - 7, top + 22},
        P.ink)
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, top + 21, cx - 6, top + 21},
        cloth)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, top + 21, cx - 6, top + 21},
        clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, top + 21, cx + 4, top + 21},
        clothLo)
    d(cx - 4, top + 14, 8, 6, clothLo, .15)
    if not north then
        p({cx - 2, top + 10, cx + 2, top + 10, cx + 3, top + 13,
            cx - 3, top + 13}, C.accent)                      -- gola azul V
        r(cx - 3, top + 12, 6, 1, mixc(C.accent, .4))
        -- Bolsa estreita (âncora) pendurada no quadril direito.
        l(cx + 4, top + 13, cx + 7, top + 24, P.goldDeep)
        r(cx + 6, top + 24, 4, 7, P.ink); r(cx + 7, top + 25, 2, 5, P.goldDark)
        r(cx + 7, top + 25, 2, 1, P.gold)
    else
        l(cx - 3, top + 12, cx + 3, top + 12, C.accent)
        r(cx - 1, top + 11, 2, 2, C.accent)                   -- nó da gola
    end
    if C.act ~= 'work' then
        r(cx - 9, top + 13, 3, 9, P.ink); r(cx - 8, top + 14, 2, 5, cloth)
        r(cx - 8, top + 19, 2, 3, skin)
        r(cx + 6, top + 13, 3, 9, P.ink); r(cx + 7, top + 14, 2, 5, clothLo)
        r(cx + 7, top + 19, 2, 3, skin)
    end
    -- Cabeça: PANO enrolado (âncora) prendendo cabelo branco crespo —
    -- caracóis escapam sob a faixa.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top, 8, 5, wrap); r(cx - 4, top, 8, 1, wrapHi)
        r(cx - 3, top + 5, 6, 6, hair)                        -- massa crespa
        d(cx - 3, top + 5, 6, 5, hairLo, .3)
        r(cx + 3, top + 2, 3, 2, wrap)                        -- nó do pano
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 3, 7, 8, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 4, wrap); r(cx - 4, top, 8, 1, wrapHi)
        r(cx - side * 5, top + 2, 2, 5, hair)                 -- crespo atrás
        r(cx - side * 5, top + 3, 1, 1, hairLo)
        r(fx + (side == 1 and -4 or 3), top + 4, 1, 1, hair)  -- fio na testa
    else
        faceNpc(r, l, cx - 4, top + 3, 8, 8, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 4, wrap); r(cx - 4, top, 8, 1, wrapHi)
        r(cx - 5, top + 1, 1, 4, wrap)
        r(cx - 4, top + 4, 2, 1, hair); r(cx + 3, top + 4, 1, 1, hair)
        r(cx - 5, top + 4, 1, 2, hair); r(cx + 4, top + 3, 1, 2, hair)
        r(cx + 4, top, 2, 2, wrap)                            -- ponta do nó
    end
end

-- VOZ DO CANAL (voz): o doc diz que a voz não precisa de corpo — se a
-- sheet continuar sendo usada como presença (eco do canal), a leitura é
-- de capuz fundo e rosto em sombra, sem fantasma. Prioridade baixa.
local function bodyVoice(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    npcFeet(r, cx, 38, P.stoneDeep, P.ink, nil, P.ink)
    -- Túnica do canal: ombros caídos, pano pesado e sem brilho.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 8, 38, cx - 8, 38}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 7, 37, cx - 7, 37}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 4, 37, cx - 7, 37}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 7, 37, cx + 5, 37}, clothLo)
    d(cx - 4, top + 14, 8, 20, clothLo, .2)
    l(cx - 6, 36, cx + 6, 36, P.ink)
    -- Capuz baixo tombado — rosto quase inteiro em sombra.
    p({cx - 5, top + 4, cx - 2, top, cx + 3, top, cx + 6, top + 4,
        cx + 5, top + 12, cx - 4, top + 12}, P.ink)
    p({cx - 4, top + 4, cx - 2, top + 1, cx + 3, top + 1, cx + 5, top + 5,
        cx + 4, top + 11, cx - 3, top + 11}, cloth)
    l(cx - 4, top + 4, cx - 2, top + 1, clothHi)
    if north then
        l(cx - 2, top + 3, cx + 2, top + 3, clothLo)
        l(cx - 1, top + 6, cx + 1, top + 9, clothLo)
    elseif side ~= 0 then
        r(cx + side * 1, top + 5, 4, 5, P.ink)
        r(cx + side * 2, top + 6, 2, 3, skinLo)
        r(cx + side * 2 + (side == 1 and 1 or 0), top + 7, 1, 1, eye)
    else
        -- Fenda de rosto: só o necessário para ler pessoa dentro.
        r(cx - 3, top + 5, 6, 6, P.ink)
        r(cx - 2, top + 6, 4, 4, skinLo)
        r(cx - 2, top + 7, 1, 1, eye); r(cx + 1, top + 7, 1, 1, eye)
        r(cx - 1, top + 9, 2, 1, P.ink)
    end
    if C.act ~= 'work' then
        r(cx - 8, top + 13, 3, 11, P.ink); r(cx - 7, top + 14, 2, 8, clothLo)
        r(cx + 5, top + 13, 3, 11, P.ink); r(cx + 6, top + 14, 2, 8, clothLo)
    end
end

-- EQUIPE DE MANUTENÇÃO (equipe): base comum de punho preso e botas
-- impermeabilizadas — não é "outro Ivo". Âncoras: punho atado, bota
-- alta de cano, cinto de ferramenta.
local function bodyCrew(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    -- Botas impermeabilizadas (âncora): cano alto cobrindo a canela.
    npcFeet(r, cx, 34, P.stoneDeep, P.ink, nil, P.ink)
    r(cx - 5, 36, 4, 5, P.ink); r(cx + 2, 36, 4, 5, P.ink)
    r(cx - 4, 36, 3, 5, P.goldDeep); r(cx + 3, 36, 3, 5, P.goldDeep)
    r(cx - 4, 36, 3, 1, P.goldDark); r(cx + 3, 36, 3, 1, P.goldDark)
    r(cx - 4, 38, 3, 1, P.goldDark); r(cx + 3, 38, 3, 1, P.goldDark)
    -- Roupa de serviço: camisa resistente, peito coberto por peitilho.
    p({cx - 7, top + 10, cx + 7, top + 10, cx + 7, 35, cx - 7, 35}, P.ink)
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, 34, cx - 6, 34}, cloth)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, 34, cx - 6, 34}, clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, 34, cx + 4, 34}, clothLo)
    if not north then
        p({cx - 4, top + 13, cx + 4, top + 13, cx + 5, 30, cx - 5, 30}, P.ink)
        p({cx - 3, top + 14, cx + 3, top + 14, cx + 4, 29, cx - 4, 29},
            C.accent)
        d(cx - 2, top + 16, 5, 10, mixc(C.accent, .4), .15)
        l(cx - 4, top + 14, cx - 4, 28, mixc(C.accent, .3, P.white))
    else
        l(cx - 4, top + 14, cx + 4, top + 14, C.accent)       -- tira do peitilho
    end
    -- Cinto de ferramenta: laço + presilha pendente.
    r(cx - 6, 31, 12, 2, P.goldDeep); r(cx + 4, 32, 2, 3, P.stoneDark)
    if C.act ~= 'work' then
        -- Punho atado (âncora): faixa de pano amarrada no antebraço.
        r(cx - 9, top + 12, 3, 10, P.ink); r(cx - 8, top + 13, 2, 6, cloth)
        r(cx - 8, top + 18, 2, 2, P.bone)                     -- faixa
        r(cx - 8, top + 20, 2, 3, skin)
        r(cx + 6, top + 12, 3, 10, P.ink); r(cx + 7, top + 13, 2, 6, clothLo)
        r(cx + 7, top + 18, 2, 2, P.bone)
        r(cx + 7, top + 20, 2, 3, skin)
    end
    -- Cabeça: lenço de serviço curto (não gorro do Ivo) + rosto comum.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top, 8, 4, C.accent)
        r(cx - 4, top + 4, 8, 7, hair)
        d(cx - 3, top + 5, 6, 5, hairLo, .25)
        r(cx + 3, top + 1, 2, 2, C.accent)                    -- nó do lenço
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, C.accent); r(cx - 4, top + 3, 8, 1, hair)
        r(cx - side * 5, top + 1, 2, 3, C.accent)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, C.accent); r(cx - 4, top + 2, 8, 1,
            mixc(C.accent, .3, P.white))
        r(cx + 4, top + 1, 2, 2, C.accent)                    -- nó lateral
        r(cx - 4, top + 3, 1, 2, hair); r(cx + 4, top + 3, 1, 2, hair)
    end
end

-- AJUDANTE DOS SALÕES (ajudante): médio, esguio, cabelo longo preso;
-- camisa creme e faixa de tecido vinho curta. Âncoras: rabo baixo,
-- faixa curta, manga creme.
local function bodyUsher(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local sash, sashLo = C.accent, mixc(C.accent, .4)
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 32, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Tronco esguio de camisa creme + FAIXA VINHO curta na cintura.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 6, 33, cx - 6, 33}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 5, 32, cx - 5, 32}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 32, cx - 5, 32}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 5, 32, cx + 4, 32}, clothLo)
    d(cx - 3, top + 14, 6, 15, clothLo, .12)
    if not north then
        l(cx - 3, top + 11, cx, top + 14, clothLo)            -- abertura da camisa
        -- Faixa curta (âncora): dois dedos de pano vinho + ponta solta.
        r(cx - 5, top + 22, 11, 2, sash); r(cx - 5, top + 22, 8, 1,
            mixc(sash, .3, P.white))
        r(cx + 3, top + 24, 2, 4, sash); r(cx + 3, top + 27, 2, 1, sashLo)
    else
        r(cx - 5, top + 22, 11, 2, sashLo)
        r(cx - 2, top + 21, 4, 3, sash)                       -- nó nas costas
    end
    if C.act ~= 'work' then
        -- Manga creme ampla no ombro, afinando no punho (âncora).
        r(cx - 8, top + 12, 4, 9, P.ink); r(cx - 7, top + 13, 2, 6, cloth)
        r(cx - 7, top + 19, 2, 1, clothLo)
        r(cx - 7, top + 20, 2, 3, skin)
        r(cx + 4, top + 12, 4, 9, P.ink); r(cx + 5, top + 13, 2, 6, clothLo)
        r(cx + 5, top + 20, 2, 3, skin)
    end
    -- Cabeça: cabelo longo preso em RABO BAIXO (âncora) atrás da nuca.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 6, hairLo, .25)
        r(cx - 1, top + 9, 3, 9, hair)                        -- rabo desce
        r(cx - 1, top + 9, 3, 1, C.accent)                    -- atadura
        r(cx - 1, top + 17, 3, 1, hairLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 5, hair)
        r(cx + 4, top + 2, 1, 3, hair)
        -- Rabo baixo atrás da nuca.
        local bx = cx - side * 5
        r(bx - 1, top + 6, 3, 8, hair); r(bx - 1, top + 6, 3, 1, C.accent)
        r(bx, top + 7, 1, 6, hairLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 6, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hair); r(cx + 2, top + 3, 1, 1, hair)
        -- O rabo espreita sobre o ombro esquerdo.
        r(cx - 6, top + 8, 2, 7, hair); r(cx - 6, top + 8, 1, 6, hairLo)
    end
end

-- PLATEIA (plateia): corpo comum de assistência — ombros relaxados,
-- roupa simples em valor fora do palco, mãos juntas no colo da pose.
-- Âncoras: postura relaxada, pano simples, nada de palco.
local function bodyCrowd(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 35, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Túnica simples relaxada: ombros em níveis levemente diferentes.
    p({cx - 7, top + 11, cx + 7, top + 10, cx + 7, 35, cx - 7, 35}, P.ink)
    p({cx - 6, top + 12, cx + 6, top + 11, cx + 6, 34, cx - 6, 34}, cloth)
    p({cx - 6, top + 12, cx - 3, top + 12, cx - 4, 34, cx - 6, 34}, clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, 34, cx + 4, 34}, clothLo)
    d(cx - 4, top + 14, 9, 17, clothLo, .15)
    r(cx - 6, 33, 12, 1, clothLo)
    if not north then
        -- Xale de ombro atravessado + mãos juntas no colo.
        l(cx - 6, top + 11, cx + 5, top + 20, C.accent)
        r(cx - 1, top + 24, 4, 3, skin)
        l(cx - 4, top + 15, cx - 1, top + 24, clothLo)
        l(cx + 4, top + 15, cx + 2, top + 24, clothLo)
    else
        l(cx - 4, top + 13, cx + 4, top + 13, clothLo)
    end
    if C.act ~= 'work' and (north or side ~= 0) then
        r(cx + side * 6 - 1, top + 13, 3, 9, P.ink)
        r(cx + side * 6, top + 14, 2, 6, clothLo)
    end
    -- Cabeça comum: cabelo curto despenteio leve, expressão de espera.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 7, hairLo, .25)
        r(cx - 4, top + 9, 8, 2, skin)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 2, 5, hair)
        r(cx - 5, top + 6, 1, 2, hairLo)                      -- fio solto
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 5, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 2, top + 3, 1, 1, hairLo); r(cx + 3, top + 3, 1, 1, hair)
        -- Bocejo contido: boca pequena, olho sonolento.
        r(cx, top + 9, 1, 1, skinLo)
    end
end

local function emoteAdorno(r, l, p, cx, v, pal, cloth, hair, accent,
    skin, skinHi)
    if v == 'elder' then
        -- Ancião: cabelo branco ralo alto e nas têmporas, testa nua.
        r(cx - 8, 3, 16, 3, hair); r(cx - 8, 3, 16, 1,
            mixc(hair, .3, P.white))
        r(cx - 9, 5, 2, 5, hair); r(cx + 8, 5, 2, 5, hair)
        r(cx - 6, 6, 3, 1, hair); r(cx + 3, 6, 3, 1, hair)
        r(cx - 12, 34, 24, 3, cloth)                          -- gola areia
        return true
    elseif v == 'washer' then
        -- Lavadeira: cabelo puxado + rolo baixo na nuca à direita;
        -- alça do avental claro cruzando o busto.
        r(cx - 8, 4, 16, 4, hair)
        r(cx - 9, 6, 2, 7, hair); r(cx + 8, 6, 2, 6, hair)
        r(cx + 8, 14, 4, 6, hair); r(cx + 9, 15, 2, 4, mixc(hair, .4))
        l(cx + 10, 35, cx - 3, 46, pal.accent or P.bone)      -- alça do avental
        return true
    elseif v == 'porter' then
        -- Carregador: cabelo escuro curto, ombreira de lona no busto.
        r(cx - 8, 3, 16, 4, hair); r(cx - 9, 5, 3, 6, hair)
        r(cx + 8, 5, 2, 5, hair)
        r(cx - 13, 34, 5, 13, P.goldDark)                     -- lona do ombro
        l(cx - 13, 35, cx - 9, 35, P.gold)
        l(cx - 8, 36, cx + 8, 46, P.goldDeep)                 -- alça larga
        return true
    elseif v == 'logger' then
        -- Lenhador: crespo curto cerrado + faixa clara de punho
        -- despontando na borda do busto.
        r(cx - 8, 3, 16, 5, hair)
        r(cx - 9, 6, 3, 7, hair); r(cx + 8, 6, 3, 7, hair)
        r(cx - 9, 8, 2, 2, mixc(hair, .35)); r(cx + 6, 4, 2, 1,
            mixc(hair, .35))
        r(cx + 10, 40, 4, 2, pal.accent or P.bone)            -- faixa no punho
        return true
    elseif v == 'kid' then
        -- Criança: massa de cachos grandes + fios enrolados nas têmporas.
        r(cx - 8, 3, 16, 5, hair)
        r(cx - 10, 5, 3, 7, hair); r(cx + 8, 5, 3, 7, hair)
        r(cx - 11, 9, 2, 3, hair); r(cx + 10, 8, 2, 3, hair)
        r(cx - 4, 2, 2, 1, mixc(hair, .4)); r(cx + 3, 1, 2, 2, hair)
        return true
    elseif v == 'braid' then
        -- Traba: cabelo liso puxado + trança baixa escamada tombando
        -- para a direita.
        r(cx - 8, 3, 16, 5, hair); r(cx - 9, 7, 2, 9, hair)
        r(cx + 8, 8, 4, 20, hair)
        r(cx + 8, 12, 4, 3, mixc(hair, .4)); r(cx + 8, 18, 4, 3,
            mixc(hair, .4))
        r(cx + 8, 28, 4, 2, accent)                           -- atadura
        return true
    elseif v == 'stocky' then
        -- Trabb: crânio raspado (bare) + sombra de barba na base +
        -- faixa de suor na testa.
        r(cx - 8, 6, 16, 1, accent)
        return true
    elseif v == 'watch' then
        -- Guarda: cabelo curto de serviço + colarinho do manto subindo.
        r(cx - 8, 3, 16, 4, hair)
        r(cx - 9, 5, 2, 6, hair); r(cx + 8, 5, 2, 6, hair)
        r(cx - 11, 30, 3, 10, pal.cape or P.stoneDark)
        r(cx + 9, 30, 3, 10, pal.cape or P.stoneDark)
        r(cx - 11, 30, 3, 1, mixc(pal.cape or P.stoneDark, .3, P.white))
        return true
    elseif v == 'fair' then
        -- Feirante: o pano na cabeça sai pelo overlay headWrap — aqui
        -- ficam os caracóis brancos escapando sob a faixa + gola azul.
        r(cx - 9, 7, 3, 6, hair); r(cx + 7, 7, 3, 6, hair)
        r(cx - 10, 10, 2, 3, hair); r(cx + 9, 10, 2, 3, hair)
        r(cx - 10, 34, 20, 3, accent)                         -- gola azul
        return true
    elseif v == 'voice' then
        -- Voz do canal: capuz fundo — o rosto mora dentro da sombra.
        r(cx - 11, 3, 22, 4, cloth)
        r(cx - 11, 4, 3, 30, cloth); r(cx + 9, 4, 3, 30, cloth)
        r(cx - 8, 4, 16, 3, cloth)
        return true
    elseif v == 'crew' then
        -- Equipe: lenço de serviço na testa + nó lateral + cabelo sob.
        r(cx - 8, 4, 16, 3, accent); r(cx - 8, 3, 16, 1,
            mixc(accent, .3, P.white))
        r(cx + 7, 2, 3, 3, accent)                            -- nó
        r(cx - 8, 7, 16, 2, hair)
        r(cx - 9, 8, 2, 6, hair); r(cx + 8, 8, 2, 5, hair)
        return true
    elseif v == 'usher' then
        -- Ajudante: cabelo longo preso + rabo baixo sobre o ombro
        -- esquerdo + ponta da faixa vinho na borda do busto.
        r(cx - 8, 3, 16, 5, hair); r(cx - 9, 7, 2, 10, hair)
        r(cx + 8, 7, 2, 7, hair)
        r(cx - 11, 16, 4, 12, hair); r(cx - 11, 16, 4, 1, accent)
        r(cx + 10, 34, 4, 8, accent)                          -- ponta da faixa
        return true
    elseif v == 'crowd' then
        -- Plateia: cabelo comum despenteio + xale curto no colo.
        r(cx - 8, 3, 16, 5, hair)
        r(cx - 9, 5, 2, 6, hair); r(cx + 8, 5, 2, 5, hair)
        r(cx - 3, 2, 2, 1, hair); r(cx + 5, 1, 1, 2, hair)
        r(cx - 12, 33, 24, 3, accent)
        return true
    end
    return false
end


local coreBodies = {
    wright = bodyWright, sentry = bodySentry, stout = bodyStout,
    drape = bodyDrape, dean = bodyDean, youth = bodyYouth, vigil = bodyVigil,
    forge = bodyForge, smith = bodySmith, hauler = bodyHauler,
    vendor = bodyVendor, assessor = bodyAssessor, planter = bodyPlanter,
    engineer = bodyEngineer, host = bodyHost, musician = bodyMusician,
    elder = bodyElder, washer = bodyWash, porter = bodyPorter,
    logger = bodyLogger, kid = bodyKid, braid = bodyBraid,
    stocky = bodyStocky, watch = bodyWatch, fair = bodyFair,
    voice = bodyVoice, crew = bodyCrew, usher = bodyUsher,
    crowd = bodyCrowd}
local coreTops = {wright = 9, sentry = 8, stout = 11, drape = 9,
    dean = 5, youth = 10, vigil = 5,
    forge = 4, smith = 11, hauler = 4, vendor = 10, assessor = 6,
    planter = 12, engineer = 8, host = 6, musician = 7,
    elder = 13, washer = 10, porter = 11, logger = 6, kid = 17,
    braid = 8, stocky = 13, watch = 7, fair = 10, voice = 10,
    crew = 10, usher = 10, crowd = 11}

local function resident(data, ox, oy, direction, action, frame, pal)
    local r, l, p, d = painter(data, ox, oy)
    local east, south, west, north = direction == 1, direction == 2, direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local v = pal.body or 'plain'
    local cx = 16
    -- 'work' com act 'sit' tem anatomia própria: o figurante sentado não
    -- compartilha o esqueleto de pé — sai cedo com o desenho de banco.
    if action == 'work' and pal.act == 'sit' then
        seatedElder(r, l, p, cx, direction, pal, frame)
        return
    end
    local bob = action == 'work' and workBob(pal.act, frame) or ({0, -1, 0, 0})[frame]
    -- Contexto de desenho: rampas derivadas da paleta do morador — pele,
    -- cabelo e pano leem cada um em três tons.
    local C = {r = r, l = l, p = p, d = d, cx = cx, side = side, south = south,
        north = north, east = east, west = west, pal = pal, act = action, fr = frame,
        skin = pal.skin or P.goldLight, skinHi = mixc(pal.skin or P.goldLight, .3, P.white),
        skinLo = mixc(pal.skin or P.goldLight, .35),
        hair = pal.hair or P.stoneDark, hairHi = mixc(pal.hair or P.stoneDark, .3, P.white),
        hairLo = mixc(pal.hair or P.stoneDark, .5),
        cloth = pal.cloth or P.stone, clothHi = mixc(pal.cloth or P.stone, .22, P.white),
        clothLo = mixc(pal.cloth or P.stone, .42),
        accent = pal.accent or P.gold, eye = pal.eye or P.jadeLight}
    local core = coreBodies[v]
    if core then
        C.top = coreTops[v] + bob
        core(C)
        if action == 'work' then workArms(r, l, p, cx, C.top, side, south, pal, frame) end
        return
    end
    -- Corpos de ofício: altura e largura variam de verdade.
    local top = (v == 'stoop' and 14 or v == 'veil' and 13 or v == 'long' and 6
        or v == 'cowl' and 8 or v == 'operator' and 4 or v == 'appraiser' and 6
        or v == 'maestro' and 8 or v == 'drifter' and 9 or v == 'trader' and 10
        or v == 'foreman' and 11 or v == 'gardener' and 11 or v == 'artist' and 11
        or v == 'artisan' and 13 or v == 'child' and 17 or 11) + bob
    C.top = top
    local hunch = (v == 'stoop' or v == 'drifter') and 2 or 0
    local wide = (v == 'bald' and 3 or v == 'bun' and 2 or v == 'foreman' and 3
        or v == 'trader' and 3 or v == 'maestro' and 2 or 0)
    local narrow = (v == 'appraiser' and 2 or (v == 'hood' or v == 'cowl' or v == 'drifter'
        or v == 'operator' or v == 'artisan') and 1 or 0)
    C.hunch, C.wide, C.narrow = hunch, wide, narrow
    bodyLegacy(C)
    if north then
        p({cx - 5, top + 1, cx + 5, top, cx + 6, top + 6, cx + 5, top + 13, cx - 5, top + 13, cx - 6, top + 6}, P.ink)
        if v == 'hood' or v == 'veil' or v == 'cowl' then
            p({cx - 4, top + 1, cx + 4, top + 1, cx + 5, top + 6, cx + 4, top + 13, cx - 4, top + 13, cx - 5, top + 6}, pal.cloth)
            l(cx - 3, top + 2, cx + 3, top + 2, pal.accent)
            if v == 'veil' then r(cx - 4, top + 7, 8, 14, pal.cloth) end
        elseif v == 'bald' then
            p({cx - 4, top + 1, cx + 4, top + 1, cx + 5, top + 6, cx + 4, top + 12, cx - 4, top + 12, cx - 5, top + 6}, pal.skin)
            r(cx - 4, top + 9, 9, 2, pal.accent)
        else
            p({cx - 4, top + 1, cx + 4, top + 1, cx + 5, top + 6, cx + 4, top + 12, cx - 4, top + 12, cx - 5, top + 6}, pal.hair)
            if v == 'long' then r(cx - 4, top + 6, 9, 12, pal.hair); l(cx - 3, top + 6, cx - 3, top + 16, pal.accent) end
            if v == 'bun' then r(cx - 1, top - 2, 3, 3, pal.hair); r(cx, top - 3, 1, 1, pal.accent) end
            l(cx - 4, top + 2, cx + 4, top + 2, pal.accent)
        end
    else
        -- Cabeça aberta: cavidade de tinta, rosto com olhos e boca.
        p({cx - 5, top, cx + 5, top - 1, cx + 6, top + 4, cx + 5, top + 12, cx - 5, top + 12, cx - 6, top + 4}, P.ink)
        p({cx - 4, top + 1, cx + 4, top, cx + 5, top + 4, cx + 4, top + 11, cx - 4, top + 11, cx - 5, top + 4}, pal.cloth)
        local fx = cx + side * 2
        if v == 'veil' then
            -- Doro: anciã baixa — véu largo caindo até a barra em moldura
            -- longa do rosto; a silhueta é um sino, não um retângulo.
            r(cx - 4, top, 9, 3, pal.cloth)
            p({cx - 5, top + 2, cx + 5, top + 2, cx + 8, 40, cx - 9, 40}, P.ink)
            p({cx - 4, top + 3, cx + 4, top + 3, cx + 6, 39, cx - 7, 39}, pal.cloth)
            faceRes(r, l, fx - 3, top + 3, 7, 7, C, 'kind')
            l(cx - 6, 38, cx + 6, 38, pal.accent)
        elseif v == 'hood' then
            local hoodTone = pal.cloth
            r(cx - 4, top, 9, 3, hoodTone)
            r(cx - 5, top + 2, 2, 6, hoodTone); r(cx + 4, top + 2, 2, 5, hoodTone)
            p({cx - 2, top - 2, cx + 2, top - 2, cx + 4, top + 1, cx - 4, top + 1}, hoodTone)
            faceRes(r, l, fx - 3, top + 3, 7, 7, C, 'worn')
        elseif v == 'cowl' then
            -- Aurel: capuz dobre de ponta alta e corpo estreito — dois
            -- pontos de acento na sombra, mãos postas.
            p({cx - 4, top - 2, cx + 1, top - 6, cx + 4, top - 1, cx + 5, top + 4, cx - 4, top + 4}, P.ink)
            p({cx - 3, top - 1, cx + 1, top - 5, cx + 3, top, cx + 4, top + 3, cx - 3, top + 3}, pal.cloth)
            r(cx - 4, top + 2, 9, 2, P.ink)
            r(cx - 5, top + 4, 2, 9, P.ink); r(cx + 4, top + 4, 2, 9, P.ink)
            r(fx - 3, top + 4, 7, 7, P.ink)
            r(fx - 1, top + 6, 2, 1, pal.accent); r(fx + 2, top + 6, 2, 1, pal.accent)
        elseif v == 'foreman' then
            -- Janda: cabelo curto escuro + faixa de pano na linha +
            -- laço branco preso acima da orelha, mandíbula larga.
            r(cx - 4, top, 9, 4, C.hair); r(cx - 5, top + 2, 2, 4, C.hair)
            r(cx + 4, top + 2, 1, 3, C.hair)
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'stern')
            r(cx - 4, top + 1, 9, 1, pal.accent)
            r(cx - 5, top + 4, 2, 2, P.bone)
            r(fx - 3, top + 10, 7, 1, C.skinLo)
        elseif v == 'artisan' then
            -- Brina: bloco ALTO de cabelo crespo achatado no topo e
            -- rente nas laterais — testa larga aberta por baixo.
            r(cx - 4, top - 3, 9, 7, C.hair)
            r(cx - 4, top - 3, 9, 1, C.hairHi)
            r(cx - 5, top - 1, 2, 5, C.hair); r(cx + 4, top - 1, 2, 5, C.hair)
            faceRes(r, l, fx - 3, top + 5, 7, 7, C, 'kind')
            r(fx - 3, top + 9, 1, 1, C.skinLo); r(fx + 4, top + 9, 1, 1, C.skinLo)
        elseif v == 'drifter' then
            -- Neco: pescoço comprido + franja lateral escura sobre a
            -- testa + bigode ralo + enrolado de cama no ombro de trás.
            r(cx - 4, top, 9, 3, C.hair); r(cx - 5, top + 1, 2, 5, C.hair)
            r(fx - 4, top + 2, 3, 4, C.hair)         -- franja lateral
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'worn')
            r(fx - 2, top + 9, 5, 1, C.hairLo)     -- bigode ralo
            r(cx - 2, top + 11, 5, 3, C.skin)      -- pescoço comprido
            r(cx - 2, top - 5, 9, 4, P.ink); r(cx - 1, top - 4, 7, 3, pal.accent)
            l(cx - 1, top - 4, cx + 6, top - 4, pal.accent)
        elseif v == 'appraiser' then
            -- Rute: coque alto apertado + óculos-filete com armação +
            -- posta ereta de cabeça recuada.
            r(cx - 4, top, 9, 3, C.hair)
            r(cx - 1, top - 3, 3, 3, C.hair); r(cx - 1, top - 3, 3, 1, C.hairLo)
            r(cx - 5, top + 2, 2, 5, C.hair); r(cx + 4, top + 2, 2, 5, C.hair)
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'stern')
            l(fx - 3, top + 6, fx + 4, top + 6, pal.accent)
            r(fx - 3, top + 6, 1, 1, P.ink); r(fx + 4, top + 6, 1, 1, P.ink)
        elseif v == 'trader' then
            -- Ema: dois rolos baixos atrás das orelhas + sobrancelha
            -- arqueada — o cabelo puxado que faz vinte anos de banca.
            r(cx - 4, top, 9, 3, C.hair)
            r(cx - 6, top + 4, 2, 3, C.hair); r(cx + 5, top + 4, 2, 3, C.hair)
            r(cx - 6, top + 4, 2, 1, C.hairLo); r(cx + 5, top + 4, 2, 1, C.hairLo)
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'kind')
            l(fx - 2, top + 5, fx - 1, top + 5, C.skinHi)
            l(fx + 3, top + 5, fx + 4, top + 5, C.skinHi)
        elseif v == 'operator' then
            -- Ivo: gorro baixo de lã escura puxado à testa + pálpebras
            -- estreitas de quem enxerga nível no escuro.
            r(cx - 4, top - 1, 9, 4, C.hair)
            r(cx - 4, top + 2, 9, 1, C.hairLo)
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'worn')
            r(fx - 2, top + 6, 2, 1, C.skinLo); r(fx + 3, top + 6, 2, 1, C.skinLo)
        elseif v == 'gardener' then
            -- Mara: chapéu de abas largas de aba tombada + cabelo branco
            -- fino + olhos apertados de ler a terra.
            r(cx - 6, top + 1, 13, 1, P.ink)
            p({cx - 4, top - 2, cx + 4, top - 2, cx + 6, top + 1, cx - 6, top + 1}, pal.accent)
            l(cx - 5, top, cx + 5, top, mixc(pal.accent, .3, P.white))
            r(cx - 4, top + 2, 9, 3, C.hair); r(cx - 5, top + 3, 2, 5, C.hair)
            faceRes(r, l, fx - 3, top + 5, 7, 7, C, 'kind')
            r(fx - 2, top + 7, 2, 1, C.skinLo); r(fx + 3, top + 7, 2, 1, C.skinLo)
        elseif v == 'maestro' then
            -- Beltran: cabelo grisalho crespo penteado para trás +
            -- bigode grosso castanho + gola levantada do anfitrião.
            r(cx - 4, top, 9, 3, C.hair)
            r(cx - 5, top + 2, 2, 5, C.hair); r(cx + 4, top + 2, 2, 5, C.hair)
            l(cx - 3, top + 1, cx + 3, top + 1, C.hairLo)
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'kind')
            r(fx - 2, top + 9, 5, 1, P.goldDeep)
            r(cx - 4, top + 11, 9, 3, pal.accent)
            r(cx - 5, top + 8, 2, 4, pal.accent); r(cx + 4, top + 8, 2, 4, pal.accent)
        elseif v == 'artist' then
            -- Cira: cunha de cabelo na nuca (lados baixos, massa atrás)
            -- + faixa azul na testa como marca de trabalho.
            r(cx - 4, top, 9, 3, C.hair)
            p({cx - 5, top + 1, cx - 1, top + 1, cx - 4, top + 10, cx - 6, top + 10}, C.hair)
            r(cx - 4, top + 1, 9, 1, pal.accent)
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'kind')
        elseif v == 'child' then
            -- Criança: cabeça redonda + cachos curtos escapando +
            -- olhos grandes demais para o rosto.
            r(cx - 4, top, 9, 4, C.hair)
            r(cx - 5, top + 1, 2, 3, C.hair); r(cx + 4, top + 1, 2, 3, C.hair)
            r(cx - 4, top + 3, 2, 1, C.hair); r(cx + 3, top + 3, 2, 1, C.hair)
            faceRes(r, l, fx - 3, top + 4, 7, 7, C, 'joy')
            r(fx - 2, top + 6, 2, 1, C.eye); r(fx + 3, top + 6, 2, 1, C.eye)
        elseif v == 'bald' then
            -- Crânio de pele em rampa + faixa de trabalho: rosto de
            -- ficha — sobrancelha, poços, nariz e boca.
            r(fx - 3, top + 2, 7, 7, C.skin)
            r(fx - 3, top + 2, 7, 1, C.skinHi)
            r(fx - 3, top + 8, 7, 1, C.skinLo)
            r(fx - 3, top + 1, 7, 1, pal.accent)
            r(fx - 2, top + 4, 2, 1, C.hair); r(fx + 2, top + 4, 2, 1, C.hair)
            r(fx - 2, top + 5, 2, 2, P.ink); r(fx + 2, top + 5, 2, 2, P.ink)
            r(fx - 2, top + 5, 1, 1, C.eye); r(fx + 2, top + 5, 1, 1, C.eye)
            r(fx, top + 6, 1, 1, C.skinLo); r(fx - 1, top + 8, 3, 1, C.skinLo)
        else
            r(cx - 4, top, 9, 3, pal.hair)
            if v == 'long' then
                r(cx - 5, top + 3, 2, 12, pal.hair); r(cx + 4, top + 3, 2, 10, pal.hair)
            elseif v == 'bun' then
                r(cx - 1, top - 3, 3, 3, pal.hair); r(cx, top - 4, 1, 1, pal.accent)
            elseif v == 'stoop' then
                r(cx - 4, top - 1, 9, 2, pal.accent); r(cx - 4, top, 3, 1, pal.accent)
            end
            faceRes(r, l, fx - 3, top + 3, 7, 7, C,
                v == 'bun' and 'kind' or v == 'stoop' and 'worn' or nil)
        end
        -- Adornos de ficha opcionais: barba por fora do rosto e pano
        -- enrolado na cabeça — nunca cobrem os traços.
        if pal.beard and v ~= 'cowl' then
            if south or side == 0 then
                r(fx - 4, top + 8, 2, 4, pal.beard); r(fx + 4, top + 8, 2, 4, pal.beard)
                r(fx - 2, top + 10, 6, 2, pal.beard)
            else
                r(fx + (side == 1 and 3 or -4), top + 8, 2, 4, pal.beard)
                r(fx + (side == 1 and 0 or -3), top + 11, 3, 1, pal.beard)
            end
        end
        if pal.headWrap then
            r(cx - 4, top - 1, 9, 4, pal.headWrap)
            r(cx - 5, top + 1, 2, 4, pal.headWrap)
            r(cx + (south and 5 or -side * 5), top + 2, 2, 3, pal.headWrap)
        end
        -- Braços e ofício. 'work' substitui o bloco inteiro: o gesto do
        -- act (martelo, pala, trouxa, colher) é o braço, não um adereço.
        if action == 'work' then
            workArms(r, l, p, cx, top, side, south, pal, frame)
        elseif v == 'stoop' then
            -- Bento: bengala à frente sustentando a corcova.
            local sx = south and cx + 9 or cx + side * 8
            l(cx + side * 4, top + 12, sx, 41, P.goldDark)
            l(sx, 41, sx + 2, 41, P.goldDark)
            r(cx + side * 4 - 1, top + 11, 3, 4, pal.skin)
        elseif v == 'long' then
            -- Teca: fuso da tecelã erguido na mão.
            local sx = south and cx + 9 or cx + side * 8
            l(cx + side * 4, top + 14, sx, top - 4, P.stoneLight)
            r(sx - 1, top - 6, 3, 3, pal.accent)
            r(cx + side * 4 - 1, top + 13, 3, 3, pal.skin)
        elseif v == 'bun' then
            -- Sabela: trouxa de pano ao peito.
            r(cx - 3, top + 18, 7, 6, P.ink); r(cx - 2, top + 19, 5, 4, pal.hair)
            l(cx - 5, top + 12, cx - 1, top + 19, pal.cloth)
            l(cx + 6, top + 12, cx + 2, top + 19, pal.cloth)
        elseif v == 'bald' then
            -- Nilo: martelo de pedreiro no ombro, mão no quadril.
            local sx = south and cx - 10 or cx - side * 9
            l(cx - side * 6, top + 8, sx, top + 2, P.goldDark)
            r(sx - 2, top - 1, 4, 4, P.stoneDark); r(sx - 2, top - 1, 4, 1, P.stoneLight)
            r(cx + side * 6, top + 12, 3, 3, pal.skin)
        elseif v == 'cowl' then
            -- Aurel: mãos postas à frente.
            r(cx - 2, top + 16, 5, 3, pal.skin)
            l(cx - 2, top + 16, cx + 3, top + 16, pal.accent)
        elseif v == 'hood' then
            -- Runa: alforje de pedra na alça transversal.
            l(cx - 4, top + 10, cx + 6, top + 24, P.goldDark)
            r(cx + 3, top + 22, 5, 5, P.ink); r(cx + 4, top + 23, 3, 3, pal.accent)
        elseif v == 'foreman' then
            -- Janda: martelo de trabalho apoiado no chão — cabeça de pedra
            -- baixa, punho segurado na altura da cintura.
            local sx = south and cx + 10 or cx + side * 9
            l(cx + side * 5, top + 14, sx, top + 24, pal.skin)
            l(sx, top + 6, sx, 41, P.goldDark)
            r(sx - 3, 36, 7, 5, P.stoneDark); r(sx - 3, 36, 7, 1, P.stoneLight)
        elseif v == 'artisan' then
            -- Brina: cesto de linhas no antebraço — bolas de fio à vista.
            local sx = south and cx - 10 or cx - side * 9
            l(cx - side * 4, top + 15, sx, top + 22, pal.skin)
            r(sx - 3, top + 20, 7, 7, P.goldDark)
            r(sx - 2, top + 19, 2, 2, P.jadeLight); r(sx + 1, top + 19, 2, 2, P.violet)
            r(sx - 2, top + 22, 5, 3, P.gold)
        elseif v == 'drifter' then
            -- Neco: cajado de caminhada seguro com as duas mãos à frente.
            local sx = south and cx + 9 or cx + side * 8
            l(cx + side * 4, top + 13, sx, top + 20, pal.skin)
            l(sx, top + 2, sx, 41, P.goldDeep)
            l(sx, top + 2, sx + 2, top, P.goldDeep)
        elseif v == 'appraiser' then
            -- Rute: vara de medida com marcações — o ofício lê-se de pé.
            local sx = south and cx + 10 or cx + side * 9
            l(cx + side * 4, top + 14, sx, top + 24, pal.skin)
            l(sx, top - 4, sx, 41, P.bone)
            for i = 0, 4 do r(sx - 1, top + i * 7, 2, 1, P.ink) end
        elseif v == 'trader' then
            -- Ema: xale abraçado com as duas mãos + bolsa de moedas no
            -- quadril — fechada sobre si mesma como boa negociante.
            r(cx - 4, top + 16, 9, 3, pal.accent)
            p({cx - 7, top + 8, cx + 7, top + 8, cx + 4, top + 22, cx - 6, top + 22}, pal.cloth)
            r(cx - 6, top + 16, 5, 5, P.ink); r(cx - 5, top + 17, 3, 3, pal.accent)
        elseif v == 'operator' then
            -- Ivo: haste comprida de nível apoiada no ombro — quase passa
            -- do quadro; casacão até os joelhos.
            local sx = south and cx + 10 or cx + side * 9
            l(cx + side * 5, top + 12, sx, top + 10, pal.skin)
            l(sx, top - 1, sx - 2, 41, P.stone)
            l(sx, top - 1, sx + 2, top - 3, P.stoneLight)
            r(sx - 3, top - 3, 5, 3, P.ink)
        elseif v == 'gardener' then
            -- Mara: cesto de mudas no braço — folhas brotando da borda.
            local sx = south and cx - 10 or cx - side * 9
            l(cx - side * 4, top + 15, sx, top + 23, pal.skin)
            r(sx - 3, top + 21, 7, 6, P.goldDark)
            l(sx - 2, top + 21, sx - 3, top + 17, P.jade)
            l(sx, top + 21, sx, top + 16, P.jadeLight)
            l(sx + 2, top + 21, sx + 3, top + 18, P.jade)
        elseif v == 'maestro' then
            -- Beltran: mão aberta em gesto de boas-vindas — o anfitrião
            -- se lê pelo braço estendido, não por adereço.
            local gx = south and cx + 10 or cx + side * 10
            l(cx + side * 5, top + 13, gx, top + 10, pal.cloth)
            r(gx - 1, top + 7, 3, 4, pal.skin)
            l(gx - 1, top + 7, gx + 2, top + 7, pal.skin)
            r(cx - side * 5 - 1, top + 14, 3, 3, pal.cloth)
        elseif v == 'artist' then
            -- Cira: paleta de tinta e pincel — dois objetos pequenos que
            -- só ela carrega.
            local sx = south and cx - 9 or cx - side * 8
            r(sx - 3, top + 18, 6, 4, P.goldDark)
            r(sx - 2, top + 19, 1, 1, P.jade); r(sx, top + 19, 1, 1, P.violet)
            r(sx + 1, top + 20, 1, 1, P.ember)
            l(cx + side * 4, top + 15, cx + side * 8, top + 11, P.goldDeep)
            l(cx + side * 8, top + 11, cx + side * 9, top + 9, P.white)
        else
            r(cx + side * 6, top + 11, 3, 14, pal.cloth)
        end
        if side == 0 and action ~= 'work' and v ~= 'bun' and v ~= 'cowl' and v ~= 'hood' then
            r(cx - 8, top + 12, 3, 12, pal.cloth)
        end
    end
end

local residents = {
    -- Núcleo do Refúgio (fichas §3-9): corpo próprio por pessoa.
    -- `shape` registra a OSSATURA da ficha (PERSONAGENS §): a silhueta
    -- do crânio no retrato — 'rect' retangular, 'square' quadrado de
    -- maxilar cheio, 'round' redondo, 'long' comprido/estreito,
    -- 'angular' de queixo pontudo, 'oval' o molde de repouso.
    npc_doro = {cloth = P.stone, hair = P.stoneEdge, skin = P.rust,
        accent = P.gold, body = 'wright', eye = P.stoneLight, act = 'hammer',
        shape = 'rect'},
    npc_runa = {cloth = P.jadeDark, hair = P.rust, skin = P.bone,
        accent = P.bone, body = 'sentry', eye = P.jade, act = 'watch',
        shape = 'square'},
    npc_bento = {cloth = P.jadeDark, hair = P.boneDark, skin = P.gold,
        accent = P.bone, body = 'stout', eye = P.goldDark, act = 'stir',
        shape = 'round'},
    npc_teca = {cloth = P.stone, hair = P.stoneDark, skin = P.goldLight,
        accent = P.rust, body = 'drape', eye = P.stone, act = 'teach',
        shape = 'long'},
    npc_sabela = {cloth = P.jadeDeep, hair = P.ink, skin = P.rust,
        accent = P.goldDark, body = 'dean', eye = P.stoneLight, act = 'write',
        shape = 'angular'},
    npc_nilo = {cloth = P.gold, hair = P.goldDeep, skin = P.goldLight,
        accent = P.stone, body = 'youth', eye = P.goldDark, act = 'tinker',
        shape = 'oval'},
    npc_aurel = {cloth = P.stoneDeep, hair = P.stoneLight, skin = P.gold,
        accent = P.bone, body = 'vigil', eye = P.stone, act = 'tend',
        shape = 'long'},
    -- Regiões (fichas §10-18): corpo próprio por pessoa, paleta e gesto
    -- de ofício da ficha — Janda forja, Brina inspeciona, Neco carrega,
    -- Rute etiqueta, Ema serve, Ivo ausculta, Mara capina, Beltran
    -- recebe, Cira dedilha.
    npc_janda = {cloth = P.stone, hair = P.ink, skin = P.rust,
        accent = P.bone, body = 'forge', eye = P.goldLight, act = 'hammer',
        shape = 'square'},
    npc_brina = {cloth = P.stoneDeep, hair = P.ink, skin = P.goldDark,
        accent = P.rust, body = 'smith', eye = P.goldLight, act = 'inspect',
        shape = 'angular'},
    npc_neco = {cloth = P.bone, hair = P.ink, skin = P.gold,
        accent = P.boneDark, body = 'hauler', eye = P.goldLight, act = 'carry',
        shape = 'long'},
    npc_rute = {cloth = P.jadeDeep, hair = P.stoneLight, skin = P.bone,
        accent = P.gold, body = 'assessor', eye = P.stoneEdge, act = 'tag',
        shape = 'oval'},
    npc_ema = {cloth = P.violetDark, hair = P.ink, skin = P.gold,
        accent = P.bone, body = 'vendor', eye = P.stoneLight, act = 'serve',
        shape = 'angular'},
    npc_ivo = {cloth = P.jadeDeep, hair = P.stoneDark, skin = P.bone,
        accent = P.stoneDark, body = 'engineer', eye = P.jade, act = 'tap',
        beard = P.goldDark, shape = 'rect'},
    npc_mara = {cloth = P.bone, hair = P.bone, skin = P.goldLight,
        accent = P.stone, body = 'planter', eye = P.jadeDark, act = 'weed',
        shape = 'round'},
    npc_beltran = {cloth = P.rust, hair = P.stoneLight, skin = P.gold,
        accent = P.gold, body = 'host', eye = P.goldLight, act = 'host',
        stache = P.stoneLight, shape = 'long'},
    npc_cira = {cloth = P.violetDark, hair = P.ink, skin = P.goldDark,
        accent = P.jade, body = 'musician', eye = P.goldLight, act = 'strum',
        shape = 'long'},
    -- Figurantes dos mundos (fichas 02-05): corpos reaproveitados com
    -- massa e paleta próprias — rosto aberto como todo o elenco.
    npc_traba = {cloth = P.rust, hair = P.goldDark, skin = P.goldLight,
        accent = P.bone, body = 'braid', eye = P.jadeLight, shape = 'long'},
    npc_trabb = {cloth = P.stoneDark, hair = P.ink, skin = P.gold,
        accent = P.jadeDark, body = 'stocky', eye = P.jadeLight,
        pants = P.stone, shape = 'rect'},
    npc_guarda = {cloth = P.stone, hair = P.stoneDark, skin = P.goldLight,
        accent = P.gold, body = 'watch', eye = P.jadeLight,
        cape = P.stoneDark, shape = 'square'},
    npc_feirante = {cloth = P.goldDark, hair = P.bone, skin = P.gold,
        accent = P.jade, body = 'fair', eye = P.jadeLight,
        headWrap = P.boneDark, shape = 'round'},
    npc_voz = {cloth = P.stoneDeep, hair = P.ink, skin = P.goldDark,
        accent = P.stone, body = 'voice', eye = P.jadeLight, shape = 'long'},
    npc_equipe = {cloth = P.stoneDeep, hair = P.stoneDark, skin = P.gold,
        accent = P.jade, body = 'crew', eye = P.jadeLight, shape = 'rect'},
    npc_ajudante = {cloth = P.bone, hair = P.goldDark, skin = P.goldLight,
        accent = P.rust, body = 'usher', eye = P.jadeLight, shape = 'long'},
    npc_plateia = {cloth = P.stoneDark, hair = P.boneDark, skin = P.gold,
        accent = P.violet, body = 'crowd', eye = P.jadeLight, shape = 'round'},
    -- Figurantes do povoado (vida do lugar, Morada): chegam por marco real —
    -- corpos reaproveitados com paleta quieta de aldeia.
    npc_anciao = {cloth = P.boneDark, hair = P.bone, skin = P.rust,
        accent = P.goldDark, body = 'elder', eye = P.jadeLight, act = 'sit',
        shape = 'long'},
    npc_lavadeira = {cloth = P.stone, hair = P.ink, skin = P.gold,
        accent = P.bone, body = 'washer', eye = P.jadeLight, act = 'wash',
        shape = 'round'},
    npc_carregador = {cloth = P.rust, hair = P.ink, skin = P.bone,
        accent = P.goldDeep, body = 'porter', eye = P.jadeLight,
        act = 'carry', beard = P.ink, shape = 'rect'},
    npc_lenhador = {cloth = P.stone, hair = P.ink, skin = P.goldDark,
        accent = P.bone, body = 'logger', eye = P.jadeLight, act = 'chop',
        pants = P.stoneDeep, shape = 'square'},
    npc_crianca = {cloth = P.gold, hair = P.ink, skin = P.rust,
        accent = P.jade, body = 'kid', eye = P.jadeLight, act = 'play',
        pants = P.stone, shape = 'round'},
}

-- Quatro emoções assadas numa linha extra da sheet: cada família entrega
-- `emote(d, ox, oy, expr)` desenhando só a cabeça grande na célula 40x48.
-- sheet.portraits[emoção] vira o corte que diálogo/palco consomem —
-- neutro, alegria, medo e raiva como estados visíveis, não recolor.
-- Vocabulário do Pena: 9 estados em duas linhas de retrato no fim da sheet.
local emotionOrder = {'neutral', 'joy', 'sad', 'stern', 'soft',
    'fear', 'anger', 'shame', 'awe'}

-- Pintores de retrato emocional por família: só a cabeça grande na célula
-- 40x48 — mesma gramática do corpo (capuz, elmo, mortalha), rosto aberto.
local function travelerEmote(d, ox, oy, expr)
    local r, l, p = painter(d, ox, oy)
    local cx = 20
    -- O mesmo rosto do sprite em grande, SEM capuz: busto do casaco
    -- marrom frio com o remendo ocre, massa de cabelo preto ondulado
    -- por cima e nas laterais, rabo baixo na nuca espreitando um lado
    -- e barba curta abraçando a mandíbula por baixo — a boca fica livre.
    r(cx - 4, 28, 8, 7, P.ink); r(cx - 3, 28, 6, 6, P.gold)
    p({cx - 13, 47, cx - 9, 36, cx + 9, 36, cx + 13, 47}, P.ink)
    p({cx - 12, 47, cx - 8, 37, cx + 8, 37, cx + 12, 47}, P.goldDark)
    r(cx - 12, 38, 4, 4, P.goldLight); r(cx - 12, 38, 4, 1, P.gold)
    -- Cabelo: massa por cima, costeletas nas laterais e o rabo baixo.
    r(cx - 9, 2, 18, 5, P.ink)
    r(cx - 10, 6, 2, 16, P.ink); r(cx + 9, 6, 2, 14, P.ink)
    r(cx - 13, 16, 3, 9, P.ink); r(cx - 13, 24, 3, 1, P.goldDark)
    faceDraw(r, l, cx - 8, 7, 16, 25, P.goldDark,
        expr == 'neutral' and 'worn' or expr, P.gold, P.goldLight,
        {skinLo = P.rust, hair = P.ink, lip = mixc(P.gold, .45, P.rust)})
    if expr == 'stern' then
        -- A sobrancelha que sobe mais: a direita um pixel acima —
        -- a desconfiança dele lê-se no retrato.
        r(cx + 3, 13, 3, 1, P.ink)
    end
    -- Barba curta irregular: costeletas na mandíbula + queixo baixo.
    r(cx - 9, 23, 3, 10, P.ink); r(cx + 7, 23, 3, 10, P.ink)
    r(cx - 6, 32, 12, 2, P.ink); r(cx - 4, 34, 8, 2, P.ink)
    r(cx - 6, 30, 2, 2, P.ink); r(cx + 5, 30, 2, 2, P.ink)
    -- Colarinho de linho cru sobre o colete, abaixo do queixo.
    r(cx - 5, 35, 10, 2, P.bone); r(cx - 3, 37, 6, 3, P.jadeDark)
end
local function sentinelEmote(sk)
    return function(d, ox, oy, expr)
        local r, l = painter(d, ox, oy)
        local cx = 20
        local eye = sk.eye or P.ember
        -- Elmo de pedra lendo a emoção pela fenda: a sobrancelha de ferro
        -- fecha na raiva, arregala no medo, abre na alegria.
        r(cx - 11, 9, 22, 27, P.ink)
        r(cx - 10, 10, 20, 25, sk.shell or P.stoneDark)
        r(cx - 10, 10, 20, 3, P.stoneLight)
        r(cx - 8, 13, 16, 17, P.ink)
        faceDraw(r, l, cx - 7, 14, 14, 16, eye, expr)
        r(cx - 5, 33, 10, 3, P.stoneEdge)  -- queixo de pedra
    end
end
local function crawlerEmote(d, ox, oy, expr)
    local r, l = painter(d, ox, oy)
    local cx, cy = 20, 24
    r(cx - 13, cy - 10, 26, 20, P.jadeDeep)
    r(cx - 13, cy - 10, 26, 3, P.jadeDark)
    for i = 0, 2 do
        r(cx - 8 + i * 7, cy - 4 + (i % 2), 2, 2, P.ink)
        r(cx - 8 + i * 7, cy - 4 + (i % 2), 1, 1, P.ember)
    end
    -- Mandíbulas separam na raiva/abrem no medo, cerram na alegria.
    local gap = expr == 'anger' and 4 or expr == 'fear' and 5 or 2
    l(cx - 6, cy + 4, cx - 10, cy + 4 + gap, P.bone)
    l(cx + 6, cy + 4, cx + 10, cy + 4 + gap, P.bone)
    r(cx - 2, cy + 3, 4, 1, P.ink)
end
local function huskEmote(d, ox, oy, expr)
    local r, l = painter(d, ox, oy)
    local cx = 20
    r(cx - 10, 7, 20, 32, P.violetDark)
    r(cx - 10, 7, 20, 3, P.violet)
    r(cx - 8, 12, 16, 18, P.ink)
    -- Rosto oco na mortalha — dois poços de luz leem a emoção.
    local tall = expr == 'fear' and 5 or 3
    r(cx - 5, 16, 3, tall, P.bone); r(cx + 2, 16, 3, tall, P.bone)
    if expr == 'anger' then
        l(cx - 6, 14, cx - 3, 17, P.ink); l(cx + 6, 14, cx + 3, 17, P.ink)
    elseif expr == 'joy' then
        r(cx - 5, 15, 3, 1, P.bone); r(cx + 2, 15, 3, 1, P.bone)
        r(cx - 3, 25, 6, 1, P.boneDark)
    end
    r(cx - 2, 25, 4, 2, P.ink)
end
-- Devotos: o capuz do cfg aberto emoldura o rosto de osso — aro e
-- laterais ficam, o centro nunca tampa. Watcher é a exceção estreita:
-- a janela da agulha é o rosto, mas fala pela mesma faceDraw. 'neutral'
-- veste a expressão de repouso do cfg.
local function zealotEmote(cfg)
    return function(d, ox, oy, expr)
        local r, l, p = painter(d, ox, oy)
        local cx = 20
        local hood = cfg.hood or cfg.robe or P.violetDark
        local deep = cfg.robeDeep or P.violetDeep
        local light = cfg.robeLight or cfg.robe or P.violet
        local trim = cfg.trim or P.gold
        local eye = cfg.eye or P.goldLight
        local e = expr == 'neutral' and cfg.expr or expr
        if cfg.build == 'needle' then
            -- Agulha: pico alto fora, rosto só na fenda estreita do capuz.
            p({cx - 7, 12, cx - 2, 5, cx + 1, 1, cx + 5, 5, cx + 8, 12,
                cx + 7, 38, cx - 7, 38}, P.ink)
            p({cx - 6, 12, cx - 2, 6, cx + 1, 2, cx + 4, 6, cx + 7, 13,
                cx + 6, 37, cx - 6, 37}, hood)
            l(cx - 6, 12, cx - 2, 6, light)
            r(cx - 4, 12, 8, 20, P.ink)
            faceDraw(r, l, cx - 4, 14, 8, 16, eye, e)
        else
            -- Aro de capuz aberto: testa e laterais emolduram, centro livre.
            r(cx - 11, 7, 22, 30, P.ink)
            r(cx - 10, 8, 20, 28, hood)
            r(cx - 10, 8, 20, 4, light)
            r(cx + 6, 8, 4, 28, deep)
            r(cx - 8, 12, 16, 22, P.ink)
            faceDraw(r, l, cx - 7, 13, 14, 18, eye, e)
            r(cx - 9, 34, 18, 2, cfg.robeDark or P.stoneDark)
            if cfg.build == 'regal' then
                -- Três dentes da coroa sobre o aro do capuz.
                for _, dx in ipairs({-6, 0, 6}) do
                    l(cx + dx, 6, cx + dx, 3, trim)
                    r(cx + dx - 1, 2, 2, 2, cfg.trimDark or P.goldDark)
                end
                l(cx - 6, 6, cx + 6, 6, cfg.trimDark or P.goldDark)
            elseif cfg.build == 'scout' then
                -- Borda tombada de viés — o capuz do ranger inclina.
                l(cx - 10, 11, cx + 10, 8, light)
            elseif cfg.build == 'loader' then
                -- Alça do cesto cruzando a borda baixa do capuz.
                l(cx - 10, 30, cx + 10, 26, trim)
            elseif cfg.build == 'block' then
                -- Aljava atrás do ombro espreita na borda do retrato.
                r(cx - 14, 16, 3, 12, P.ink)
                r(cx - 13, 17, 1, 10, cfg.trimDark or P.goldDark)
            end
        end
    end
end
-- Moradores: o retrato agora é BUSTO — pescoço e ombros do pano por
-- baixo, face 16x25 enchendo o corte, e o adorno do body moldura por
-- fora do rosto (topo <=6, laterais fora de x12-27): trança da Runa,
-- nó da Teca, bloco da Brina — nada cobre os olhos. 'neutral' veste o
-- repouso do body (pal.rest vence a tabela).
local function residentEmote(pal)
    local v = pal.body or 'plain'
    local rests = {veil = 'kind', hood = 'worn', stoop = 'worn', bun = 'kind',
        cowl = 'worn', foreman = 'stern', artisan = 'kind', drifter = 'worn',
        appraiser = 'stern', trader = 'kind', operator = 'worn',
        gardener = 'kind', maestro = 'kind', artist = 'kind', bald = 'kind',
        wright = 'worn', sentry = 'stern', stout = 'kind', drape = 'soft',
        dean = 'stern', youth = 'joy', vigil = 'worn', child = 'joy',
        long = 'kind',
        forge = 'stern', smith = 'stern', hauler = 'worn', vendor = 'kind',
        assessor = 'stern', planter = 'kind', engineer = 'worn',
        host = 'kind', musician = 'soft',
        elder = 'worn', washer = 'kind', porter = 'worn', logger = 'stern', kid = 'joy', braid = 'kind', stocky = 'kind',
        watch = 'stern', fair = 'kind', voice = 'worn', crew = 'worn', usher = 'soft', crowd = 'kind'}
    return function(d, ox, oy, expr)
        local r, l, p = painter(d, ox, oy)
        local cx = 20
        local cloth, hair = pal.cloth or P.stone, pal.hair or P.stoneDark
        local accent = pal.accent or P.gold
        local skin = pal.skin or P.goldLight
        local skinHi = mixc(skin, .3, P.white)
        local skinLo = mixc(skin, .35)
        local clothHi = mixc(cloth, .25, P.white)
        -- Busto: pescoço de pele + ombros do pano — a cabeça cobre a
        -- raiz do pescoço e o colarinho sobe por trás do queixo.
        r(cx - 4, 28, 8, 8, P.ink); r(cx - 3, 28, 6, 7, skin)
        r(cx - 3, 33, 6, 1, skinLo)
        p({cx - 14, 47, cx - 9, 34, cx + 9, 34, cx + 14, 47}, P.ink)
        p({cx - 13, 47, cx - 8, 35, cx + 8, 35, cx + 13, 47}, cloth)
        l(cx - 8, 35, cx - 12, 45, clothHi)
        -- Adorno do body: moldura em volta do rosto — topo baixo,
        -- laterais fora da face; tudo antes da faceDraw, que cobre o
        -- que sobrar e garante olhos livres.
        if v == 'wright' then
            -- Doro: cabeça RASPADA a navalha — couro claro lendo pele
            -- no topo, raspadura irregular de 1-2px nas laterais e
            -- têmpora já grisalha. A barba prata-e-preto fecha a
            -- mandíbula DEPOIS do rosto.
            r(cx - 7, 3, 14, 4, skin); r(cx - 7, 3, 14, 2, skinHi)
            r(cx - 8, 5, 16, 2, skin)
            r(cx - 10, 6, 3, 16, skin); r(cx + 8, 6, 3, 16, skin)
            -- Raspadura: restos de fio que a navalha não pegou.
            r(cx - 9, 10, 1, 2, skinLo); r(cx - 10, 15, 1, 1, skinLo)
            r(cx + 9, 11, 1, 2, skinLo); r(cx + 10, 16, 1, 1, skinLo)
            r(cx - 2, 4, 2, 1, skinLo)
            -- Grisalha descendo da têmpora ao lado do rosto.
            r(cx - 10, 18, 1, 4, P.stoneLight); r(cx + 9, 18, 1, 4, P.stoneLight)
            l(cx + 9, 35, cx - 4, 46, accent)
        elseif v == 'sentry' then
            -- Runa: franja ruiva + trança caindo do lado + gola do manto.
            r(cx - 8, 3, 16, 5, hair); r(cx - 9, 7, 2, 9, hair)
            r(cx + 8, 8, 4, 24, hair); l(cx + 9, 9, cx + 9, 30, P.ink)
            r(cx + 8, 31, 4, 2, accent)
            r(cx - 12, 35, 24, 2, accent)
        elseif v == 'stout' then
            -- Bento: cabelo crespo fugindo da faixa + toalha na borda.
            r(cx - 8, 4, 16, 4, hair)
            r(cx - 10, 6, 3, 9, hair); r(cx + 8, 6, 3, 9, hair)
            r(cx - 9, 5, 18, 2, accent)
            r(cx + 10, 12, 3, 22, P.bone); r(cx + 10, 20, 3, 1, cloth)
        elseif v == 'drape' then
            -- Teca: cabelo grisalho + nó lateral baixo + gola do xale.
            r(cx - 8, 3, 16, 5, hair); r(cx - 10, 7, 3, 11, hair)
            r(cx - 11, 16, 5, 5, hair); r(cx - 11, 18, 1, 1, accent)
            r(cx - 12, 34, 24, 3, P.boneDark); l(cx - 12, 34, cx + 12, 34, P.bone)
        elseif v == 'dean' then
            -- Sabela: tranças puxadas com fios brancos + gola do casaco.
            r(cx - 8, 3, 16, 5, hair)
            r(cx - 10, 7, 2, 9, hair); r(cx + 8, 7, 2, 9, hair)
            l(cx - 6, 4, cx + 6, 5, P.ink)
            r(cx - 6, 6, 2, 1, P.stoneEdge); r(cx - 1, 6, 2, 1, P.stoneEdge)
            r(cx + 5, 6, 2, 1, P.stoneEdge)
            r(cx - 12, 35, 24, 3, cloth); l(cx - 10, 36, cx - 4, 42, clothHi)
        elseif v == 'youth' then
            -- Nilo: cabelo denso + mecha torta para cima.
            r(cx - 8, 4, 16, 5, hair)
            r(cx - 10, 8, 3, 9, hair); r(cx + 8, 8, 2, 7, hair)
            r(cx + 2, 0, 4, 6, hair); r(cx + 5, 2, 2, 3, hair)
        elseif v == 'vigil' then
            -- Aurel: grisalho penteado + linha recuada + orelhas + gola.
            r(cx - 7, 3, 14, 3, hair)
            r(cx - 9, 4, 2, 11, hair); r(cx + 8, 4, 2, 11, hair)
            r(cx - 4, 4, 3, 2, skin); r(cx + 2, 4, 3, 2, skin)
            r(cx - 11, 13, 2, 5, skin); r(cx + 10, 13, 2, 5, skin)
            r(cx - 10, 34, 20, 4, cloth); r(cx - 8, 34, 16, 2, clothHi)
            r(cx - 8, 37, 16, 2, accent)
        elseif v == 'veil' then
            -- Faixas laterais de véu caindo além do queixo.
            r(cx - 11, 3, 22, 5, cloth)
            r(cx - 11, 6, 4, 32, cloth); r(cx + 8, 6, 4, 32, cloth)
            r(cx - 11, 37, 22, 1, accent)
        elseif v == 'hood' or v == 'drifter' then
            -- Aro de capuz aberto; drifter soma o enrolado no topo.
            r(cx - 11, 3, 22, 4, cloth)
            r(cx - 11, 4, 3, 28, cloth); r(cx + 9, 4, 3, 28, cloth)
            if v == 'drifter' then
                r(cx - 5, 0, 13, 4, P.ink); r(cx - 4, 1, 11, 3, accent)
            end
        elseif v == 'cowl' then
            -- Capuz dobre de ponta alta — aro alto, rosto livre.
            p({cx - 10, 12, cx - 3, 4, cx + 2, 0, cx + 7, 4, cx + 11, 12,
                cx + 10, 38, cx - 10, 38}, P.ink)
            p({cx - 9, 12, cx - 3, 5, cx + 2, 1, cx + 6, 6, cx + 10, 13,
                cx + 9, 37, cx - 9, 37}, cloth)
        elseif v == 'stoop' then
            -- Faixa de ancião sobre o cabelo ralo.
            r(cx - 8, 3, 16, 3, hair); r(cx - 9, 5, 2, 4, hair)
            r(cx - 8, 6, 16, 1, accent)
        elseif v == 'long' or v == 'appraiser' then
            -- Cabelo comprido / pala alta descendo dos dois lados.
            r(cx - 8, 3, 16, 5, hair)
            r(cx - 10, 8, 3, v == 'long' and 24 or 18, hair)
            r(cx + 8, 8, 3, v == 'long' and 20 or 18, hair)
            if v == 'long' then
                l(cx - 10, 8, cx - 10, 30, accent)
            else
                r(cx - 1, 1, 4, 3, hair); r(cx, 0, 1, 1, accent)
            end
        elseif v == 'bun' then
            -- Coque alto com grampo de acento.
            r(cx - 8, 4, 16, 4, hair); r(cx - 2, 1, 5, 4, hair)
            r(cx, 0, 1, 1, accent)
        elseif v == 'trader' then
            -- Coque baixo + xale subindo até o queixo.
            r(cx - 8, 4, 16, 4, hair); r(cx - 1, 1, 4, 3, hair)
            r(cx - 12, 33, 24, 4, cloth); r(cx - 12, 33, 24, 1, accent)
        elseif v == 'bald' then
            -- Crânio de pele + faixa de trabalho na testa.
            r(cx - 8, 3, 16, 4, skin); r(cx - 8, 3, 16, 1, skinHi)
            r(cx - 8, 6, 16, 1, accent)
        elseif v == 'foreman' then
            -- Faixa de operária prendendo o cabelo.
            r(cx - 8, 3, 16, 3, hair); r(cx - 8, 5, 16, 2, accent)
        elseif v == 'artisan' then
            -- Brina: bloco de cabelo + trança tombada para a direita,
            -- fora do rosto.
            r(cx - 8, 3, 16, 5, hair); r(cx - 9, 7, 2, 9, hair)
            r(cx + 8, 8, 4, 20, hair); r(cx + 8, 27, 4, 3, accent)
        elseif v == 'operator' then
            -- Boné de serviço com pala de tinta.
            r(cx - 9, 3, 18, 4, accent); r(cx - 9, 6, 18, 1, P.ink)
        elseif v == 'gardener' then
            -- Chapéu de abas largas — o contorno único da jardineira.
            p({cx - 7, 0, cx + 7, 0, cx + 10, 6, cx - 10, 6}, accent)
            r(cx - 11, 6, 22, 1, P.ink)
            r(cx - 9, 7, 2, 6, hair); r(cx + 8, 7, 2, 6, hair)
        elseif v == 'maestro' then
            -- Gola levantada emoldurando o queixo, cabelo penteado.
            r(cx - 8, 3, 16, 5, hair); l(cx - 7, 4, cx + 7, 6, mixc(hair, .5))
            r(cx - 10, 27, 3, 11, accent); r(cx + 8, 27, 3, 11, accent)
            r(cx - 10, 36, 20, 3, accent)
        elseif v == 'artist' then
            -- Boina assimétrica tombada sobre a testa.
            r(cx - 8, 5, 16, 3, hair); r(cx - 9, 8, 2, 7, hair)
            p({cx - 8, 4, cx + 3, 0, cx + 9, 4, cx + 7, 7, cx - 8, 7}, accent)
        elseif v == 'forge' then
            -- Janda: cabelo preto curto + faixa branca da orelha.
            r(cx - 8, 3, 16, 4, hair)
            r(cx - 10, 6, 3, 12, hair); r(cx + 8, 6, 3, 12, hair)
            r(cx + 8, 10, 3, 3, P.white)
            r(cx - 13, 42, 26, 2, P.rust)
        elseif v == 'smith' then
            -- Brina: bloco alto achatado, laterais rentes.
            r(cx - 8, 0, 16, 6, hair); r(cx - 8, 0, 16, 1, mixc(hair, .3, P.white))
            r(cx - 10, 6, 3, 8, hair); r(cx + 8, 6, 3, 8, hair)
        elseif v == 'hauler' then
            -- Neco: corte rente + franja lateral sobre a testa.
            r(cx - 8, 3, 16, 4, hair); r(cx - 10, 6, 3, 9, hair)
            r(cx + 5, 6, 5, 12, hair); r(cx + 5, 16, 2, 1, P.ink)
        elseif v == 'vendor' then
            -- Ema: cabelo preso + dois rolos baixos atrás das orelhas.
            r(cx - 8, 3, 16, 4, hair)
            r(cx - 10, 6, 3, 9, hair); r(cx + 8, 6, 3, 9, hair)
            r(cx - 12, 15, 4, 4, hair); r(cx + 9, 15, 4, 4, hair)
            r(cx - 11, 16, 1, 1, P.ink); r(cx + 10, 16, 1, 1, P.ink)
            r(cx - 13, 42, 26, 2, P.bone)
        elseif v == 'assessor' then
            -- Rute: coque alto apertado + puxado liso nas laterais.
            r(cx - 8, 3, 16, 4, hair); l(cx - 8, 4, cx + 8, 5, mixc(hair, .5))
            r(cx - 2, 0, 5, 4, hair); r(cx - 2, 0, 5, 1, mixc(hair, .5))
            r(cx - 10, 7, 2, 10, hair); r(cx + 8, 7, 2, 10, hair)
        elseif v == 'planter' then
            -- Mara: cabelo branco curto ondulado em volta do rosto.
            r(cx - 8, 4, 16, 4, hair)
            r(cx - 10, 7, 3, 12, hair); r(cx + 8, 7, 3, 11, hair)
            r(cx - 10, 9, 1, 1, P.white); r(cx + 9, 11, 1, 1, P.white)
            r(cx - 9, 18, 2, 1, P.white)
        elseif v == 'engineer' then
            -- Ivo: gorro de lã baixo; a barba entra via pal.beard.
            r(cx - 9, 2, 18, 6, accent); r(cx - 9, 7, 18, 1, P.ink)
            r(cx - 10, 8, 2, 8, accent); r(cx + 9, 8, 2, 8, accent)
        elseif v == 'host' then
            -- Beltran: testa ampla, grisalho atrás, gola da casaca.
            r(cx - 8, 3, 16, 3, hair)
            r(cx - 11, 6, 3, 16, hair); r(cx + 8, 6, 3, 16, hair)
            r(cx - 13, 40, 26, 3, cloth); r(cx - 13, 40, 26, 1, clothHi)
        elseif v == 'musician' then
            -- Cira: laterais baixas + cunha espreitando atrás.
            r(cx - 8, 3, 16, 4, hair)
            r(cx - 10, 6, 2, 9, hair); r(cx + 8, 6, 2, 8, hair)
            r(cx - 12, 7, 3, 18, hair); r(cx - 12, 24, 2, 3, hair)
            r(cx - 13, 42, 26, 2, accent)
        elseif emoteAdorno(r, l, p, cx, v, pal, cloth, hair, accent,
                skin, skinHi) then
            -- Adorno do lote fibra por body novo — aplicado acima.
        else
            r(cx - 8, 3, 16, 5, hair)
            if v == 'child' then
                -- Cachos curtos escapando pelas laterais.
                r(cx - 9, 5, 2, 4, hair); r(cx + 8, 5, 2, 4, hair)
            end
        end
        faceDraw(r, l, cx - 8, 7, 16, 25, pal.eye or P.jadeLight,
            expr == 'neutral' and (pal.rest or rests[v]) or expr,
            skin, skinHi, {skinLo = skinLo, hair = hair,
            shape = pal.shape,
            bare = v == 'wright' or v == 'bald' or v == 'stocky'})
        -- Sobreposições que ABRAÇAM a mandíbula — sempre depois do
        -- rosto, nunca sobre a boca.
        if v == 'wright' then
            -- Barba de PRATA E PRETO: costeletas grisalhas subindo às
            -- têmporas + massa de mandíbula em prata com fios de tinta
            -- — a mistura lê a 1x, ele é o mais velho do núcleo.
            r(cx - 11, 22, 3, 16, P.stone); r(cx + 9, 22, 3, 16, P.stone)
            r(cx - 11, 22, 3, 3, P.stoneLight); r(cx + 9, 22, 3, 3, P.stoneLight)
            r(cx - 9, 30, 18, 9, P.stone)
            r(cx - 9, 30, 18, 1, P.stoneLight); r(cx - 7, 31, 5, 1, P.stoneLight)
            r(cx + 5, 31, 4, 1, P.stoneLight)
            -- Fios pretos da mistura: falhas de tinta dentro da prata.
            r(cx - 8, 33, 2, 5, P.ink); r(cx - 4, 34, 1, 4, P.ink)
            r(cx + 2, 33, 2, 5, P.ink); r(cx + 6, 34, 1, 4, P.ink)
            r(cx - 11, 30, 1, 5, P.ink); r(cx + 10, 28, 1, 6, P.ink)
        end
        if pal.beard then
            -- Barba da ficha: costeletas na borda da mandíbula + queixo.
            r(cx - 9, 24, 3, 9, pal.beard); r(cx + 7, 24, 3, 9, pal.beard)
            r(cx - 5, 33, 10, 3, pal.beard)
        end
        if pal.stache then
            -- Bigode da ficha (Beltran): barra grossa sobre o lábio,
            -- filete claro no cume — nunca cobre a boca.
            r(cx - 5, 24, 11, 2, pal.stache)
            r(cx - 4, 24, 9, 1, mixc(pal.stache, .3, P.white))
        end
        if pal.chin then r(cx - 5, 33, 10, 2, pal.chin) end
        if pal.headWrap then
            r(cx - 9, 3, 18, 4, pal.headWrap); r(cx - 10, 5, 3, 6, pal.headWrap)
        end
        if v == 'appraiser' then
            -- Óculos-filete da Rute: aros finos sobre os olhos.
            r(cx - 7, 15, 5, 1, accent); r(cx + 3, 15, 5, 1, accent)
            r(cx - 10, 15, 3, 1, accent); r(cx + 8, 15, 3, 1, accent)
        end
    end
end
-- Fixos da mesma família: Amâncio lê o capuz-cabeção dourado como 'hood'
-- com barba de ferrugem; Odete o capote baixo de jade.
local merchantEmote = residentEmote{body = 'hood', cloth = P.goldDark,
    hair = P.rust, skin = P.bone, eye = P.goldLight, accent = P.gold,
    rest = 'kind', chin = P.rust}
local keeperEmote = residentEmote{body = 'hood', cloth = P.jadeDark,
    hair = P.stoneDark, skin = P.bone, eye = P.jadeLight, accent = P.jade,
    rest = 'kind'}

local function sheet(actions, draw, emote)
    local h = frameH * #actions * 4
    local data = love.image.newImageData(frameW * 6, emote and h + frameH * 2 or h)
    local animations = {}
    local grid = anim8.newGrid(frameW, frameH, data:getWidth(), data:getHeight())
    for row, action in ipairs(actions) do
        animations[action[1]] = {}
        for direction = 1, 4 do
            local y = (row - 1) * 4 + direction
            for frame = 1, action[2] do draw(data, (frame - 1) * frameW, (y - 1) * frameH, direction, action[1], frame) end
            animations[action[1]][direction] = anim8.newAnimation(grid('1-' .. action[2], y), action[3], action[4])
        end
    end
    local portraits
    if emote then
        portraits = {}
        for i, emo in ipairs(emotionOrder) do
            local row = i <= 5 and 0 or 1
            local col = row == 0 and i - 1 or i - 6
            emote(data, col * frameW, h + row * frameH, emo)
            portraits[emo] = {col * frameW + 10, h + row * frameH + 7, 20, 26}
        end
    end
    local image = G.newImage(data); image:setFilter('nearest', 'nearest'); data:release()
    return {image = image, animations = animations, portraits = portraits}
end

local sharedSheets
function Actors.new()
    if not sharedSheets then
        sharedSheets = {player = sheet(playerActions, traveler, travelerEmote),
            -- Dasher: o bruto corcunda — cabeça afundada entre os ombros,
            -- leitura de touro à distância, separado do quebrador chifrado.
            dasher = sheet(enemyActions, function(d, ox, oy, dir, act, fr)
                sentinel(d, ox, oy, dir, act, fr, {})
            end, sentinelEmote({})),
            npc_merchant = sheet(npcActions, merchant, merchantEmote),
            npc_keeper = sheet(npcActions, keeper, keeperEmote)}
        -- Todo o elenco tem sheet própria: brutos reutilizam o sentinel com
        -- skins e os devotos o zealot paramétrico; kinds novos caem no
        -- fallback em Actors:draw.
        for kind, sk in pairs(sentinelSkins) do
            sharedSheets[kind] = sheet(enemyActions, function(d, ox, oy, dir, act, fr)
                sentinel(d, ox, oy, dir, act, fr, sk)
            end, sentinelEmote(sk))
        end
        for kind, cfg in pairs(zealotSkins) do
            sharedSheets[kind] = sheet(enemyActions, function(d, ox, oy, dir, act, fr)
                zealot(d, ox, oy, dir, act, fr, cfg)
            end, zealotEmote(cfg))
        end
        -- Crawler e husk ficam sem linha de retrato: o gesto é a 'face'
        -- (decisão do Pena — fera e mortalha não humanizam em close-up).
        sharedSheets.crawler = sheet(enemyActions, crawler)
        sharedSheets.husk = sheet(enemyActions, husk)
        -- Casulo: variante de corpo do husk enquanto e.hatch conta na
        -- batalha por turnos — sheetOf faz a troca, o kind segue 'husk'.
        sharedSheets.huskCocoon = sheet(enemyActions, huskCocoon)
        for kind, pal in pairs(residents) do
            sharedSheets[kind] = sheet(npcActions, function(data, ox, oy, dir, act, fr)
                resident(data, ox, oy, dir, act, fr, pal)
            end, residentEmote(pal))
        end
        -- Head crop inside the 40x48 frame, south-facing idle — the dialogue
        -- box draws this region as the speaker's portrait. The battle queue
        -- and the inspect card read the same source.
        sharedSheets.npc_merchant.portrait = {12, 1, 13, 13}
        sharedSheets.npc_keeper.portrait = {12, 8, 14, 13}
        sharedSheets.player.portrait = {12, 3, 14, 13}
        sharedSheets.dasher.portrait = {13, 17, 15, 11}
        sharedSheets.crawler.portrait = {13, 29, 13, 11}
        sharedSheets.husk.portrait = {12, 5, 13, 14}
        sharedSheets.huskCocoon.portrait = {10, 11, 13, 18}
        -- Retrato por corpo — a cabeça mudou de altura por arquétipo.
        local sentinelPortraits = {
            dasher = {13, 17, 15, 11}, breaker = {12, 6, 16, 12},
            demolisher = {12, 10, 15, 12}, warden = {12, 0, 16, 15},
        }
        for kind in pairs(sentinelSkins) do sharedSheets[kind].portrait = sentinelPortraits[kind] or sentinelPortraits.dasher end
        local zealotPortraits = {
            ranger = {13, 9, 14, 12}, sower = {12, 13, 15, 12},
            watcher = {13, 8, 14, 10}, veteran = {12, 8, 15, 13},
            regent = {12, 3, 16, 14},
        }
        for kind in pairs(zealotSkins) do sharedSheets[kind].portrait = zealotPortraits[kind] or zealotPortraits.veteran end
        for kind, pal in pairs(residents) do
            local cropTop = {stoop = 14, veil = 13, artisan = 11, long = 6,
                appraiser = 6, cowl = 8, maestro = 8, drifter = 9, trader = 10,
                operator = 4, child = 17, wright = 9, sentry = 8, stout = 11,
                drape = 9, dean = 5, youth = 10, vigil = 5,
                forge = 3, smith = 7, hauler = 3, vendor = 9, assessor = 2,
                planter = 11, engineer = 6, host = 5, musician = 6,
                elder = 13, washer = 10, porter = 11, logger = 6,
                kid = 17, braid = 8, stocky = 13, watch = 7,
                fair = 10, voice = 10, crew = 10, usher = 10,
                crowd = 11}
            local cy = cropTop[pal.body] or 11
            sharedSheets[kind].portrait = {12, cy - 1, 14, 13}
        end
    end
    return setmetatable({sheets = sharedSheets, states = {}, deaths = {}}, Actors)
end

-- Sheet do ator; inimigos sem desenho próprio caem no devoto da sentinela
-- em vez do fallback vetorial.
local function sheetOf(self, entity)
    local kind = entity.player and 'player'
        or entity.npc and 'npc_' .. entity.npc.id
        or entity.enemy and entity.enemy.kind
    -- Casulo da batalha por turnos: enquanto e.hatch conta, o corpo é o
    -- fardo fechado; na eclosão o kind vira 'crawler' e a sheet volta.
    if kind == 'husk' and (entity.hatch or 0) > 0 then kind = 'huskCocoon' end
    -- Chefes de arena vestem a sheet do homônimo NPC quando o papel bate
    -- (janda/rute/ivo/beltran) — o look deles é o papel, não a família.
    local found = kind and (self.sheets[kind] or self.sheets['npc_' .. kind])
    if not found and entity.enemy then
        kind, found = 'ranger', self.sheets.ranger
    end
    -- O posto decide o gesto: quando entity.act difere do act assado na
    -- sheet-base do kind, assa (e cacheia) uma variante com o gesto do
    -- posto — trocar de posto troca o gesto sem recriar o elenco.
    if found and entity.npc and entity.act and residents[kind] then
        local pal = residents[kind]
        if pal.act ~= entity.act then
            local key = kind .. '@' .. entity.act
            local variant = self.sheets[key]
            if not variant then
                local alt = {}
                for k, v in pairs(pal) do alt[k] = v end
                alt.act = entity.act
                variant = sheet(npcActions, function(data, ox, oy, dir, act, fr)
                    resident(data, ox, oy, dir, act, fr, alt)
                end, residentEmote(alt))
                variant.portrait = found.portrait
                self.sheets[key] = variant
            end
            found = variant
        end
    end
    return found, kind
end

function Actors.direction(entity)
    local f = entity.facing or {dx = 1, dy = 0}
    local w = entity.weapon
    if w and w.mineTimer > 0 then f = {dx = w.mineDx, dy = w.mineDy} end
    return f.dx > 0 and 1 or f.dy > 0 and 2 or f.dx < 0 and 3 or 4
end

function Actors.state(entity, record)
    -- Figurante com ofício (def.act) veste a linha 'work' — o povoado
    -- trabalha no posto em vez de ficar parado em idle. O act da entidade
    -- manda; sem ele, o act da paleta do kind é o ofício-padrão.
    if entity.npc then
        local pal = entity.npc.id and residents['npc_' .. entity.npc.id]
        local act = entity.act or pal and pal.act
        return act and 'work' or 'idle'
    end
    if entity.health and entity.health.current <= 0 then return 'death' end
    if record and (record.hurtRemaining or 0) > 0 then return 'hurt' end
    local m = entity.motion
    if entity.player then
        local w = entity.weapon
        if w.mineTimer > 0 then return 'mine', 1 - w.mineTimer / mineDuration end
        if w.state == 'action' then return 'fire', 1 - w.action / .2 end
        if entity.guard.active then return 'guard' end
        if w.state == 'charging' then return 'charge', w.charge end
        if w.state == 'ready' then return 'ready' end
    else
        local a = entity.enemy
        if a.state == 'warn' or a.state == 'volley' then
            return 'warn', 1 - a.timer / (a.warningDuration or 1)
        end
        if a.state == 'dash' then return 'dash' end
        if a.state == 'recover' then return 'recover', 1 - a.timer / recoverDuration end
        if a.state == 'stunned' or a.state == 'exposed' then return 'recover' end
        -- Batalha por turnos: a intenção anunciada vira a pose de telegraph;
        -- a investida anunciada ganha a pose 'dash' enquanto o corpo voa.
        local i = entity.intent
        if i and (i.kind == 'shoot' or i.kind == 'dash') then
            if i.kind == 'dash' and m and m.remaining > 0 then return 'dash' end
            return 'warn'
        end
    end
    if m and m.remaining > 0 then return 'move', 1 - m.remaining / m.duration end
    -- Campaign exploration moves continuously; `moving` plays the walk cycle
    -- without an interpolated grid hop.
    if entity.moving then return 'move' end
    return 'idle'
end

function Actors:update(dt, game, screen, reducedMotion)
    self.reducedMotion = reducedMotion
    -- A room transition creates fresh entities; discard the old visual clocks with them.
    if self.room ~= game.room then self.room, self.states, self.deaths = game.room, {}, {} end
    local frozen = screen ~= 'playing' or game.reward or game.dialogue or game.state == 'won'
    local seen = {}
    for _, entity in ipairs(game:entities()) do
        local sheetEntry, kind = sheetOf(self, entity)
        if sheetEntry then
            seen[entity] = true
            local record = self.states[entity]
            if not record then
                record = {hp = entity.health.current, hurtRemaining = 0}; self.states[entity] = record
            end
            if not frozen and game.state == 'playing' then
                if entity.health.current < record.hp then record.hurtRemaining = .18 end
                record.hurtRemaining = math.max(0, record.hurtRemaining - dt)
            end
            record.hp = entity.health.current
            local state, progress = Actors.state(entity, record)
            local direction = Actors.direction(entity)
            if record.animation and (frozen or game.state ~= 'playing' and state ~= 'death') then
                state, direction = record.state, record.direction
            end
            if record.state ~= state or record.direction ~= direction then
                -- Sheets de figurante (npc_*) não assam estados de combate:
                -- chefes humanos vestem a sheet do homônimo em arena
                -- (sheetOf) — sem a linha, o corpo segue em repouso sob o
                -- telegrafo do chão em vez de quebrar o jogo.
                local base = (sheetEntry.animations[state]
                    or sheetEntry.animations.idle)[direction]
                -- A caminhada livre da exploração pede cadência mais calma
                -- que o salto de célula: mesmos quadros, outro relógio.
                if state == 'move' and entity.moving then
                    record.animation = anim8.newAnimation(base.frames, .115)
                else
                    record.animation = base:clone()
                end
                record.state, record.direction = state, direction
            end
            if not frozen and (game.state == 'playing' or state == 'death') then
                if state == 'charge' then
                    local stats = game:weaponStats()
                    progress = entity.weapon.charge / stats.chargeTime
                end
                if progress then
                    local animation = record.animation
                    local target = math.max(0, math.min(.999999, progress)) * animation.totalDuration
                    animation:update(target - animation.timer)
                elseif not reducedMotion or state ~= 'idle' and state ~= 'ready' and state ~= 'guard' then
                    record.animation:update(dt)
                end
            end
        end
    end
    -- ECS removes killed enemies immediately; retain only their short visual exit.
    for entity, record in pairs(self.states) do
        if not seen[entity] then
            if entity.enemy and entity.health.current <= 0 then
                local sheetEntry = sheetOf(self, entity)
                if sheetEntry and sheetEntry.animations.death then
                    self.deaths[#self.deaths + 1] = {x = (entity.grid.x - .5) * 32, y = (entity.grid.y - .5) * 32,
                        animation = sheetEntry.animations.death[record.direction]:clone(),
                        image = sheetEntry.image}
                end
            end
            self.states[entity] = nil
        end
    end
    if not frozen and game.state == 'playing' then
        for i = #self.deaths, 1, -1 do
            local ghost = self.deaths[i]; ghost.animation:update(dt)
            if ghost.animation.status == 'paused' then table.remove(self.deaths, i) end
        end
    end
end

local function tint(c, alpha) G.setColor(c[1], c[2], c[3], alpha or 1) end
function Actors:draw(renderer, entity, game, x, y, jump)
    local sheetEntry, kind = sheetOf(self, entity)
    if not sheetEntry then return false end
    local record = self.states[entity]
    local state, progress = Actors.state(entity, record)
    local animation = record and record.animation
        or (sheetEntry.animations[state] or sheetEntry.animations.idle)[Actors.direction(entity)]
    x, y = math.floor(x + .5), math.floor(y + .5)
    jump = renderer.reducedMotion and 0 or math.floor((jump or 0) + .5)
    -- Sombra de contato dithered em duas densidades: poça ampla e núcleo
    -- denso sob os pés — o ator assenta no chão, não flutua sobre ele.
    PixelArt.ditherEllipse(x + 2, y + 3, math.max(8, 14 - jump * .3), 5, P.ink, .45)
    PixelArt.ditherEllipse(x + 1, y + 2, math.max(5, 9 - jump * .2), 3, P.ink, .8)
    -- Trégua aceita ('calmed'): a silhueta esfria para o azul estrelado de
    -- repouso — o 'zzz' suspenso é do renderer; aqui o corpo arrefece.
    local calmed = entity.enemy and entity.enemy.state == 'calmed'
    if calmed then G.setColor(Pal.sky.star) else G.setColor(1, 1, 1, 1) end
    animation:draw(sheetEntry.image, x, y - jump, 0, 1, 1, originX, originY)
    G.setColor(1, 1, 1, 1)
    if entity.player then
        local w = entity.weapon
        if w.state == 'charging' or w.state == 'ready' then
            local ratio = w.state == 'ready' and 1 or w.charge / game:weaponStats().chargeTime
            tint(P.ink); G.rectangle('fill', x - 11, y - jump - 52, 22, 4)
            tint(P.gold); G.rectangle('fill', x - 10, y - jump - 51, math.floor(20 * ratio), 2)
            if w.state == 'ready' then
                tint(P.goldLight); G.rectangle('fill', x - 1, y - jump - 56, 2, 2)
                G.rectangle('fill', x - 3, y - jump - 54, 6, 1)
            end
        end
    elseif entity.enemy then
        tint(P.ink); G.rectangle('fill', x - 10, y - jump - 47, 20, 3)
        tint(P.danger); G.rectangle('fill', x - 9, y - jump - 46, math.floor(18 * entity.health.current / entity.health.max), 1)
        if entity.enemy.state == 'warn' then
            tint(P.goldLight); G.rectangle('fill', x - 1, y - jump - 53, 2, 3); G.rectangle('fill', x - 1, y - jump - 49, 2, 1)
        end
    end
    return true
end

function Actors:drawDeaths(renderer, game)
    for _, ghost in ipairs(self.deaths) do
        PixelArt.ditherEllipse(ghost.x, ghost.y + 2, 11, 4, P.ink, .5)
        G.setColor(1, 1, 1, 1)
        ghost.animation:draw(ghost.image, ghost.x, ghost.y, 0, 1, 1, originX, originY)
    end
end

function Actors.selfCheck()
    local view = Actors.new()
    local first = {player = true, facing = {dx = 1, dy = 0}, motion = {remaining = 0, duration = .16},
        health = {current = 10, max = 10}, weapon = {state = 'empty', charge = 0, action = 0, mineTimer = 0}, guard = {active = false}}
    local second = {grid = {x = 6, y = 5}, enemy = {kind = 'dasher', state = 'seek'}, facing = {dx = 0, dy = 1},
        motion = {remaining = 0, duration = .24}, health = {current = 6, max = 6}}
    local entities = {first, second}
    local game = {room = {}, state = 'playing', entities = function() return entities end,
        weaponStats = function() return {chargeTime = .72} end}
    view:update(.1, game, 'playing', false)
    local a, b = view.states[first].animation, view.states[second].animation
    assert(a ~= b and a.timer == .1 and b.timer == .1, 'Each actor owns an independent anim8 clock')
    view:update(.1, game, 'paused', false); assert(a.timer == .1 and b.timer == .1, 'Pause freezes actor clocks')
    view:update(.1, game, 'help', false); assert(a.timer == .1, 'Guide freezes actor clocks')
    first.weapon.state, first.weapon.charge = 'charging', .36
    view:update(.01, game, 'playing', true)
    assert(view.states[first].state == 'charge' and view.states[first].animation.position == 2, 'Charge follows simulation progress')
    local chargeAnimation = view.states[first].animation
    view:update(.01, game, 'playing', true)
    assert(view.states[first].animation == chargeAnimation and first.weapon.charge == .36, 'State persists and rendering never advances charge')
    first.weapon.mineTimer, first.weapon.mineDx, first.weapon.mineDy = mineDuration / 2, 0, -1
    view:update(.01, game, 'playing', false)
    assert(view.states[first].state == 'mine' and view.states[first].direction == 4, 'Mining pose follows its committed strike direction')
    first.weapon.mineTimer = 0
    for _, f in ipairs({{1, 0}, {0, 1}, {-1, 0}, {0, -1}}) do
        first.facing.dx, first.facing.dy = f[1], f[2]
        view:update(.01, game, 'playing', false)
        assert(view.states[first].direction == Actors.direction(first), 'Directions own distinct frame rows')
    end
    first.health.current, game.state = 0, 'dead'
    view:update(.6, game, 'playing', false)
    assert(view.states[first].state == 'death' and view.states[first].animation.status == 'paused', 'Death settles once without simulation callbacks')
    assert(first.motion.remaining == 0 and first.health.current == 0 and second.enemy.state == 'seek', 'Actor presentation never mutates gameplay')
    game.state, second.health.current, entities = 'playing', 0, {first}
    view:update(.01, game, 'playing', false)
    assert(#view.deaths == 1 and not view.states[second] and view.deaths[1].animation.timer == .01,
        'Removed enemies retain only an independent visual death')
    local ghost = view.deaths[1]
    view:update(.1, game, 'paused', false)
    assert(ghost.animation.timer == .01 and ghost.x == 176 and ghost.y == 144, 'Death exits freeze during pause at committed feet')
    view:update(.5, game, 'playing', false)
    assert(#view.deaths == 0 and second.health.current == 0 and second.motion.remaining == 0 and #entities == 1,
        'Death exit expires without reviving an entity or mutating simulation')
    assert(Actors.new().sheets == view.sheets, 'Generated sheets are reused between renderer instances')
    return true
end

return Actors
