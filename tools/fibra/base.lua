-- Harness do lote Fibra — helpers copiados VERBATIM de src/pixel_actors.lua
-- (escopo local do módulo) como globais, para pré-visualizar os painters do
-- lote sem tocar no arquivo que o Traço escreve. Se o Traço mudar um helper,
-- atualizar a cópia aqui. Nada daqui é carregado pelo jogo.

P = {
    ink = {.027, .043, .067}, abyss = {.016, .024, .043},
    floorDark = {.075, .114, .149}, floor = {.090, .133, .169}, floorLight = {.106, .149, .184},
    joint = {.059, .090, .122}, stoneDark = {.090, .133, .176}, stone = {.169, .235, .286},
    stoneLight = {.282, .361, .396}, stoneEdge = {.365, .455, .475},
    jadeDark = {.055, .235, .220}, jade = {.235, .635, .529}, jadeLight = {.529, .886, .702},
    goldDark = {.314, .235, .129}, gold = {.643, .490, .251}, goldLight = {.847, .702, .392},
    white = {.898, .941, .847}, danger = {.941, .388, .302}, rust = {.435, .204, .153},
    violet = {.482, .318, .702}, violetDark = {.278, .192, .412}, violetLight = {.690, .529, .878},
    jadeDeep = {.039, .141, .157}, jadeMid = {.133, .412, .376},
    violetDeep = {.169, .118, .286}, violetMid = {.376, .255, .545},
    goldDeep = {.192, .141, .067}, ember = {.976, .573, .216}, emberLight = {1, .816, .494},
    stoneDeep = {.055, .082, .114}, bone = {.812, .749, .592}, boneDark = {.557, .478, .345},
}

frameW, frameH = 40, 48

BAYER = {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}

function painter(data, offsetX, offsetY)
    local function pixel(x, y, c)
        x, y = math.floor(x + offsetX + .5), math.floor(y + offsetY + .5)
        if x >= 0 and x < data:getWidth() and y >= 0 and y < data:getHeight() then
            data:setPixel(x, y, c[1], c[2], c[3], 1)
        end
    end
    local function rect(x, y, w, h, c)
        for i = 0, w - 1 do for j = 0, h - 1 do pixel(x + i, y + j, c) end end
    end
    local function line(x1, y1, x2, y2, c)
        x1, y1, x2, y2 = math.floor(x1 + .5), math.floor(y1 + .5),
            math.floor(x2 + .5), math.floor(y2 + .5)
        local dx, dy = math.abs(x2 - x1), -math.abs(y2 - y1)
        local sx, sy = x1 < x2 and 1 or -1, y1 < y2 and 1 or -1
        local err = dx + dy
        local guard = 0
        while true do
            pixel(x1, y1, c)
            if x1 == x2 and y1 == y2 then break end
            guard = guard + 1
            if guard > 500 then
                io.write('LINE GUARD: ', x1, ',', y1, ' -> ', x2, ',', y2, '\n')
                break
            end
            local twice = err * 2
            if twice >= dy then err = err + dy; x1 = x1 + sx end
            if twice <= dx then err = err + dx; y1 = y1 + sy end
        end
    end
    local function poly(points, c)
        local minY, maxY = math.huge, -math.huge
        for i = 2, #points, 2 do
            minY = math.min(minY, points[i]); maxY = math.max(maxY, points[i])
        end
        for y = math.floor(minY), math.ceil(maxY) do
            local nodes = {}
            local j = #points - 1
            for i = 1, #points, 2 do
                local xi, yi, xj, yj = points[i], points[i + 1], points[j], points[j + 1]
                if (yi < y and yj >= y) or (yj < y and yi >= y) then
                    nodes[#nodes + 1] = xi + (y - yi) / (yj - yi) * (xj - xi)
                end
                j = i
            end
            table.sort(nodes)
            for i = 1, #nodes - 1, 2 do
                for x = math.floor(nodes[i]), math.ceil(nodes[i + 1]) - 1 do
                    pixel(x, y, c)
                end
            end
        end
    end
    local function dith(x, y, w, h, c, t)
        for j = 0, h - 1 do for i = 0, w - 1 do
            if BAYER[(math.floor(y) + j) % 4 + 1][(math.floor(x) + i) % 4 + 1] / 16 < t then
                pixel(x + i, y + j, c)
            end
        end end
    end
    return rect, line, poly, dith
end

function pose(action, frame)
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

function faceDraw(r, l, x, y, w, h, eye, expr, skin, skinHi)
    local face = expr == 'fear' and P.bone
        or expr == 'anger' and P.rust
        or skin or P.boneDark
    r(x, y, w, h, P.ink)
    r(x + 1, y + 1, w - 2, h - 1, face)
    r(x + 1, y + 1, w - 2, 1, expr == 'fear' and P.white or skinHi or P.bone)
    local eL, eR = x + 1, x + w - 3
    local mx = x + math.floor(w / 2)
    r(eL, y + 3, 2, 2, P.ink); r(eR, y + 3, 2, 2, P.ink)
    if expr ~= 'fear' and expr ~= 'awe' and expr ~= 'shame' then
        r(eL, y + 3, 1, 1, eye); r(eR, y + 3, 1, 1, eye)
    end
    if expr == 'fear' or expr == 'awe' then
        r(eL - 1, y + 1, 4, 4, P.bone); r(eR - 1, y + 1, 4, 4, P.bone)
        r(eL, y + 2, 2, 2, eye); r(eR, y + 2, 2, 2, eye)
    end
    if expr == 'anger' then
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
        r(eL, y + 2, 2, 1, P.ink); r(eR, y + 2, 2, 1, P.ink)
        r(eL - 1, y + 3, 1, 1, P.ink); r(eR + 2, y + 3, 1, 1, P.ink)
        r(x + 1, y + h - 4, w - 2, 2, P.ink)
        r(x + 2, y + h - 3, w - 4, 1, P.bone)
        return
    end
    if expr == 'sad' then
        l(eL - 1, y + 3, eL + 1, y + 1, P.ink); l(eR + 2, y + 3, eR, y + 1, P.ink)
        r(mx - 1, y + h - 3, 2, 1, P.ink)
        l(x + 1, y + h - 3, x + 1, y + h - 2, P.ink)
        l(x + w - 2, y + h - 3, x + w - 2, y + h - 2, P.ink)
        return
    end
    if expr == 'soft' then
        r(eL, y + 2, 2, 1, P.ink); r(eR, y + 2, 2, 1, P.ink)
        r(mx - 1, y + h - 3, 2, 1, P.bone)
        return
    end
    if expr == 'shame' then
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
    r(mx, y + h - 2, 1, 1, P.ink)
end

function mixc(c, t, to)
    local o = to or P.ink
    return {c[1] + (o[1] - c[1]) * t, c[2] + (o[2] - c[2]) * t,
        c[3] + (o[3] - c[3]) * t}
end

function shade(r, x, y, w, h, tone, shadow, edge)
    r(x, y, w, h, tone)
    if edge and h > 1 then r(x, y, w, 1, edge) end
    if shadow and h > 2 then r(x, y + h - 1, w, 1, shadow) end
end

function faceNpc(r, l, x, y, w, h, skin, skinHi, skinLo, eye)
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

function faceNpcSide(r, l, x, y, w, h, s, skin, skinHi, skinLo, eye)
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
    local exL, exR = x + 3, x + w - 6
    local browY, eyeY = y + 6, y + 9
    local mY = y + h - 7
    local bands = {{0, 0}, {h - 5, 1}, {h - 3, 2}, {h - 1, 3}}
    for i, b in ipairs(bands) do
        local y0, ins = y + b[1], b[2]
        local y1 = bands[i + 1] and y + bands[i + 1][1] or y + h
        r(x + ins, y0, w - ins * 2, y1 - y0, P.ink)
        r(x + ins + 1, y0, w - ins * 2 - 2, y1 - y0, skin)
    end
    r(x + 1, y + 3, w - 2, 2, skinHi)
    r(x + w - 2, y + 5, 1, h - 12, skinLo)
    if not C.bare then
        r(x + 1, y + 1, w - 2, 1, hair)
        r(x + 1, y + 2, 3, 1, hair); r(x + 5, y + 2, 4, 1, hair)
        r(x + 10, y + 2, w - 11, 1, hair)
    end
    if expr == 'fear' or expr == 'awe' then
        r(exL - 1, eyeY - 1, 4, 3, P.ink); r(exR, eyeY - 1, 4, 3, P.ink)
        if expr == 'fear' then
            r(exL + 1, eyeY, 1, 2, eye); r(exR + 1, eyeY, 1, 2, eye)
        else
            r(exL + 1, eyeY, 2, 2, eye); r(exR + 1, eyeY, 2, 2, eye)
        end
    else
        r(exL, eyeY - 1, 3, 1, skinLo); r(exR, eyeY - 1, 3, 1, skinLo)
        r(exL, eyeY, 3, 2, P.ink); r(exR, eyeY, 3, 2, P.ink)
        local ix = expr == 'shame' and 2 or 1
        r(exL + ix, eyeY, 1, 2, eye); r(exR + ix, eyeY, 1, 2, eye)
        if expr == 'joy' or expr == 'soft' or expr == 'kind'
            or expr == 'stern' or expr == 'sad' or expr == 'worn' then
            r(exL, eyeY - 1, 3, 1, skinLo); r(exL, eyeY, 3, 1, skinLo)
            r(exR, eyeY - 1, 3, 1, skinLo); r(exR, eyeY, 3, 1, skinLo)
        end
    end
    if expr == 'anger' then
        r(exL + 2, eyeY - 1, 1, 2, skinLo); r(exR, eyeY - 1, 1, 2, skinLo)
    end
    if expr == 'sad' or expr == 'worn' then
        r(exL, eyeY + 2, 3, 1, skinLo); r(exR, eyeY + 2, 3, 1, skinLo)
    end
    if expr == 'anger' then
        l(exL - 1, browY - 1, exL + 2, browY + 1, hair)
        l(exR + 3, browY - 1, exR, browY + 1, hair)
    elseif expr == 'stern' then
        l(exL - 1, browY, exL + 2, browY + 1, hair)
        l(exR + 3, browY, exR, browY + 1, hair)
    elseif expr == 'sad' or expr == 'worn' then
        l(exL - 1, browY + 1, exL + 2, browY - 1, hair)
        l(exR + 3, browY + 1, exR, browY - 1, hair)
    elseif expr == 'fear' or expr == 'awe' then
        r(exL - 1, browY - 1, 5, 1, hair); r(exR - 1, browY - 1, 5, 1, hair)
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
    r(mx - 1, eyeY + 1, 1, 3, skinHi)
    r(mx, eyeY + 1, 1, 4, skinLo)
    r(mx - 2, eyeY + 4, 1, 2, skinLo); r(mx + 1, eyeY + 4, 1, 2, skinLo)
    r(mx - 2, eyeY + 5, 1, 1, deep); r(mx + 1, eyeY + 5, 1, 1, deep)
    r(mx - 1, eyeY + 5, 2, 1, skinLo)
    if expr == 'joy' then
        r(mx - 4, mY - 1, 1, 1, lip); r(mx + 3, mY - 1, 1, 1, lip)
        r(mx - 3, mY, 7, 3, P.ink); r(mx - 2, mY, 5, 1, P.bone)
    elseif expr == 'sad' then
        r(mx - 2, mY, 5, 1, lip)
        r(mx - 3, mY + 1, 1, 1, lip); r(mx + 3, mY + 1, 1, 1, lip)
    elseif expr == 'stern' then
        r(mx - 3, mY, 7, 1, P.ink)
    elseif expr == 'soft' or expr == 'kind' then
        r(mx - 3, mY - 1, 1, 1, lip); r(mx + 3, mY - 1, 1, 1, lip)
        r(mx - 2, mY, 5, 1, lip)
    elseif expr == 'fear' then
        r(mx - 1, mY, 3, 2, P.ink)
    elseif expr == 'anger' then
        r(mx - 3, mY, 7, 1, P.ink)
        r(mx - 1, mY - 1, 1, 1, P.bone); r(mx + 1, mY - 1, 1, 1, P.bone)
        local blush = mixc(skin, .5, P.ember)
        r(exL, mY - 4, 2, 1, blush); r(exR + 1, mY - 4, 2, 1, blush)
    elseif expr == 'shame' then
        r(mx, mY, 3, 1, lip)
    elseif expr == 'awe' then
        r(mx - 1, mY - 1, 3, 3, P.ink)
    elseif expr == 'worn' then
        r(mx - 2, mY, 5, 1, deep); r(mx - 2, mY + 1, 5, 1, skinLo)
    else
        r(mx - 2, mY, 5, 1, lip)
        r(mx - 3, mY - 1, 1, 1, skinLo); r(mx + 3, mY - 1, 1, 1, skinLo)
    end
    r(mx - 2, mY + 3, 4, 1, skinLo)
    r(x + 4, y + h - 2, w - 8, 1, skinLo)
end

function faceRes(r, l, x, y, w, h, C, expr)
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

function npcFeet(r, cx, y0, pants, boots, wrap, hemShadow)
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

function garmentNpc(C, halfW, hemY, opt)
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

function armsIdle(C, y0, len)
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

function workBob(act, frame)
    if act == 'hammer' or act == 'chop' then return frame > 2 and 1 or 0 end
    if act == 'play' then return ({0, -2, 0, -1})[frame] end
    if act == 'wash' or act == 'stir' or act == 'fill' then return frame % 2 end
    return ({0, -1, 0, 0})[frame]
end

function workArms(r, l, p, cx, top, side, south, pal, frame)
    local act = pal.act or 'work'
    local skin = pal.skin or P.goldLight
    if act == 'fill' then act = 'wash' elseif act == 'help' then act = 'carry' end
    if act == 'hammer' or act == 'chop' then
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
        local sx = south and cx + 6 or cx + side * 5
        l(cx + side * 4, top + 13, sx, top + 3, skin)
        r(sx - 1, top + 1, 4, 3, skin)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'carry' then
        local bx = cx - side * 3
        r(bx - 3, top - 2, 9, 7, P.ink)
        r(bx - 2, top - 1, 7, 5, pal.hair)
        r(bx - 2, top - 1, 7, 1, pal.accent)
        l(cx - side * 4, top + 11, bx + 1, top + 1, pal.cloth)
        r(cx + side * 6 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'wash' then
        r(cx - 4, top + 14, 9, 5, P.ink)
        r(cx - 3, top + 15, 7, 3, pal.cloth)
        r(cx - 2, top + 15, 2, 2, P.white)
        r(cx + 1, top + 16, 3, 1, P.jadeLight)
        l(cx - 6, top + 11, cx - 4, top + 15, pal.cloth)
        l(cx + 6, top + 11, cx + 4, top + 15, pal.cloth)
    elseif act == 'play' then
        local bx = cx + (frame % 2 == 0 and 9 or -8)
        local by = 35 - (frame % 3) * 4
        r(bx - 1, by, 4, 4, P.ink); r(bx, by + 1, 2, 2, pal.accent)
        r(cx + side * 6 - 1, top + 11, 3, 9, pal.cloth)
        l(cx - side * 5, top + 12, cx - side * 8, top + 6, skin)
    elseif act == 'stir' then
        local a = frame / 4 * 6.283
        local hx = cx + math.floor(math.cos(a) * 4 + .5)
        local hy = top + 15 + math.floor(math.sin(a) * 2 + .5)
        l(cx + side * 4, top + 13, hx, hy, skin)
        l(hx, hy, hx + 1, hy + 8, P.goldDark)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'teach' then
        local sx = south and cx + 9 or cx + side * 8
        l(cx + side * 4, top + 14, sx, top + 6, skin)
        l(sx, top + 6, sx + (south and 4 or side * 4), top - 5, P.bone)
        r(cx - side * 7 - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'write' then
        local px = south and cx - 3 or (side == 1 and cx + 5 or cx - 8)
        r(px, top + 20, 8, 5, P.ink)
        r(px + 1, top + 21, 6, 3, P.bone)
        local hx = px + 3 + (frame % 2 == 0 and 2 or 0)
        l(cx + (south and 2 or side * 3), top + 12, hx, top + 19, pal.cloth)
        r(hx - 1, top + 18, 3, 3, skin)
        l(hx + 1, top + 20, hx + 3, top + 16, P.ink)
        r(cx - (south and -4 or side * 7) - 1, top + 12, 3, 11, pal.cloth)
    elseif act == 'tinker' then
        local py = top + 16 + frame % 2
        r(cx - 3, py, 7, 5, P.ink)
        r(cx - 2, py + 1, 5, 3, P.goldDark)
        r(cx - 1, py + 1, 2, 2, P.gold); r(cx + 2, py + 2, 1, 1, P.ember)
        l(cx - 4, top + 12, cx - 4, py + 1, pal.cloth)
        r(cx - 6, py + (frame % 2), 3, 3, skin)
        l(cx + 4, top + 12, cx + 4, py + 1, pal.cloth)
        r(cx + 3, py + 1 - (frame % 2), 3, 3, skin)
    elseif act == 'tend' then
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
    else
        r(cx + side * 6, top + 11, 3, 14, pal.cloth)
    end
end
