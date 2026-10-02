local anim8 = require('vendor.anim8')
local P = require('src.pixel_world').palette
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
local npcActions = {{'idle', 4, .34}}

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
    return rect, line, poly
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

local function traveler(data, ox, oy, direction, action, frame)
    local r, l, p = painter(data, ox, oy)
    local bob, leg, cape, lean, squat = pose(action, frame)
    local east, south, west, north = direction == 1, direction == 2, direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local cx, head = 16 + side * lean, 12 + bob + squat
    local hem = math.min(44, 40 + bob + cape)
    local skin, cloth = P.goldLight, P.jade
    local attacking = action == 'charge' or action == 'ready' or action == 'fire'
    local pull = action == 'charge' and frame or action == 'ready' and 3 or 0
    local armY = head + (attacking and 14 or 18)

    local function bow()
        if action == 'mine' then
            local swing = ({-5, 1, 4, 1})[frame]
            if side ~= 0 then
                l(cx + side * 4, head + 20, cx + side * 10, head + 9 + swing, P.goldDark)
                l(cx + side * 5, head + 20, cx + side * 11, head + 9 + swing, P.gold)
                l(cx + side * 6, head + 7 + swing, cx + side * 13, head + 11 + swing, P.stoneLight)
                l(cx + side * 6, head + 6 + swing, cx + side * 13, head + 10 + swing, P.white)
            else
                l(cx - 3, head + 19, cx + 6, head + 9 + swing, P.gold)
                l(cx + 1, head + 7 + swing, cx + 10, head + 10 + swing, P.white)
                l(cx + 1, head + 8 + swing, cx + 10, head + 11 + swing, P.stoneLight)
            end
        elseif side ~= 0 then
            local bx, by = cx + side * 10, head + 12
            l(bx - side * 2, by, bx + side, by + 3, P.goldLight)
            l(bx + side, by + 3, bx + side * 2, by + 8, P.gold)
            l(bx + side * 2, by + 8, bx + side, by + 14, P.gold)
            l(bx + side, by + 14, bx - side * 2, by + 17, P.goldDark)
            l(bx - side * 2, by, bx - side * (2 + pull), by + 8, P.stoneEdge)
            l(bx - side * (2 + pull), by + 8, bx - side * 2, by + 17, P.stoneEdge)
            if attacking then
                l(cx + side * (3 - pull), by + 8, cx + side * 14, by + 8, P.white)
                l(cx + side * 13, by + 7, cx + side * 15, by + 8, P.goldLight)
                l(cx + side * 13, by + 9, cx + side * 15, by + 8, P.goldLight)
            end
        else
            local by = north and head + 3 or head + 24
            l(cx - 8, by, cx - 5, by + 3, P.goldLight)
            l(cx - 5, by + 3, cx + 5, by + 3, P.gold)
            l(cx + 5, by + 3, cx + 8, by, P.goldDark)
            l(cx - 8, by, cx, by - pull, P.stoneEdge)
            l(cx, by - pull, cx + 8, by, P.stoneEdge)
            if attacking then
                local ay = north and -9 or 10
                l(cx, by - 3, cx, by + ay, P.white)
                l(cx - 2, by + ay - (north and -2 or 2), cx, by + ay, P.goldLight)
                l(cx + 2, by + ay - (north and -2 or 2), cx, by + ay, P.goldLight)
            end
        end
    end
    if north then bow() end
    r(cx - 5, head + 21, 3, math.max(1, 23 - head + math.min(2, leg)), P.stoneDark)
    r(cx + 3, head + 21, 3, math.max(1, 23 - head - math.min(2, leg)), P.ink)
    -- Cape is long and asymmetric; each direction changes its overlap and silhouette.
    if east then
        p({cx - 6, head + 12, cx + 2, head + 15, cx - 1, hem - 2, cx - 11 + cape, hem, cx - 8, head + 24}, P.ink)
        p({cx - 5, head + 13, cx, head + 17, cx - 3, hem - 3, cx - 9 + cape, hem - 1}, P.jadeDark)
        l(cx - 5, head + 16, cx - 8 + cape, hem - 3, P.jade)
    elseif west then
        p({cx - 2, head + 13, cx + 7, head + 13, cx + 10 - cape, hem - 2, cx + 4, hem, cx + 1, head + 24}, P.ink)
        p({cx + 1, head + 14, cx + 6, head + 15, cx + 8 - cape, hem - 3, cx + 3, hem - 1}, P.jadeDark)
        l(cx + 3, head + 18, cx + 4, hem - 3, P.jade)
    else
        p({cx - 7, head + 12, cx + 7, head + 13, cx + 9 + cape, hem - 4, cx + 2, hem, cx - 10, hem - 2}, P.ink)
        p({cx - 6, head + 13, cx + 6, head + 14, cx + 7 + cape, hem - 5, cx + 1, hem - 2, cx - 8, hem - 3}, P.jadeDark)
        p({cx - 6, head + 14, cx - 1, head + 15, cx - 3, hem - 3, cx - 8, hem - 3}, P.jade)
        l(cx - 6, head + 16, cx - 7, hem - 5, P.jadeLight)
    end
    if action == 'death' and frame >= 4 then
        p({5, 41, 11, 35, 20, 37, 26, 43, 11, 45}, P.jadeDark)
        r(10, 38, 8, 4, P.jade); r(12, 37, 6, 1, P.jadeLight)
        l(19, 42, 28, 43, P.gold); return
    end
    -- Boots and hem stay separate during compression and extension.
    r(cx - 6, 39 + math.min(2, leg), 4, 5 - squat / 2, P.ink)
    r(cx + 2, 39 - math.min(2, leg), 4, 5 - squat / 2, P.ink)
    r(cx - 6, 40 + math.min(2, leg), 3, 1, P.stoneLight)
    r(cx + 2, 40 - math.min(2, leg), 3, 1, P.stone)
    if not north then
        p({cx - 5, head + 14, cx + 5, head + 14, cx + 6, 38 + bob, cx - 6, 38 + bob}, P.ink)
        p({cx - 4, head + 15, cx + 4, head + 15, cx + 4, 36 + bob, cx - 5, 37 + bob}, cloth)
        r(cx + 2, head + 17, 3, 14 - squat, P.jadeDark)
        r(cx - 5, head + 24, 10, 2, P.goldDark); r(cx - 5, head + 24, 8, 1, P.gold)
        r(cx - 1, head + 24, 2, 2, P.goldLight)
    end
    if side ~= 0 then
        p({cx - 5, head + 2, cx - 2, head - 1, cx + 3, head, cx + 6, head + 5, cx + 5, head + 11, cx - 5, head + 13, cx - 7, head + 7}, P.ink)
        p({cx - 4, head + 2, cx, head, cx + 3, head + 2, cx + 5, head + 6, cx + 3, head + 10, cx - 5, head + 11}, cloth)
        p({cx - 4, head + 2, cx, head, cx + 2, head + 2, cx - 2, head + 4, cx - 5, head + 9}, P.jadeLight)
        local faceX = east and cx + 1 or cx - 6
        r(faceX, head + 6, 5, 6, P.ink); r(faceX + (east and 2 or 0), head + 7, 3, 3, P.goldDark)
        r(faceX + (east and 2 or 0), head + 7, 2, 1, skin)
        r(cx + side * 5 - 1, armY, 3, 3, skin)
        if attacking then l(cx - side * pull, armY + 1, cx + side * 8, armY + 1, P.jadeLight) end
    elseif south then
        p({cx - 6, head + 3, cx - 3, head, cx + 3, head, cx + 6, head + 3, cx + 7, head + 11, cx - 7, head + 12}, P.ink)
        p({cx - 5, head + 3, cx - 2, head + 1, cx + 2, head + 1, cx + 5, head + 4, cx + 5, head + 11, cx - 5, head + 11}, cloth)
        l(cx - 5, head + 3, cx - 2, head + 1, P.jadeLight); l(cx - 5, head + 4, cx - 5, head + 9, P.jadeLight)
        r(cx - 4, head + 6, 8, 5, P.ink); r(cx - 3, head + 7, 6, 1, skin)
        r(cx - 1, head + 8, 2, 2, P.goldDark)
        r(cx - 8, armY, 3, 3, skin); r(cx + 5, armY - (attacking and 2 or 0), 3, 3, P.gold)
    else
        p({cx - 6, head + 3, cx - 3, head, cx + 3, head, cx + 6, head + 3, cx + 6, head + 12, cx, head + 14, cx - 6, head + 12}, P.ink)
        p({cx - 5, head + 3, cx - 2, head + 1, cx + 2, head + 1, cx + 5, head + 4, cx + 4, head + 11, cx, head + 12, cx - 5, head + 10}, cloth)
        p({cx - 5, head + 3, cx - 2, head + 1, cx, head + 2, cx - 2, head + 9, cx - 5, head + 9}, P.jadeLight)
        l(cx + 2, head + 5, cx + 3, head + 10, P.jadeDark)
        r(cx - 8, head + (attacking and 7 or 20), 3, 3, P.gold)
        r(cx + 5, head + (attacking and 6 or 18), 3, 3, skin)
        r(cx - 1, head + 16, 2, 2, P.goldLight)
    end
    if not north then bow() end
    if action == 'guard' then
        if side ~= 0 then
            local sx = cx + side * 11
            l(sx, head + 11, sx + side * 3, head + 15, P.jadeLight)
            l(sx + side * 3, head + 15, sx + side * 3, head + 26, P.jadeLight)
            l(sx + side * 3, head + 26, sx, head + 30, P.jade)
            r(sx - 1, head + 19, 2, 3, P.white)
        else
            local sy = north and head + 1 or head + 31
            l(cx - 10, sy, cx - 6, sy + 3, P.jadeLight)
            l(cx - 6, sy + 3, cx + 6, sy + 3, P.jadeLight)
            l(cx + 6, sy + 3, cx + 10, sy, P.jade)
            r(cx - 1, sy + 2, 2, 2, P.white)
        end
    end
end

local function sentinel(data, ox, oy, direction, action, frame)
    local r, l, p = painter(data, ox, oy)
    local bob, leg, cape, lean, squat = pose(action, frame)
    local side = direction == 1 and 1 or direction == 3 and -1 or 0
    local cx, top = 16 + side * lean, 13 + bob + squat
    if action == 'death' and frame >= 4 then
        p({4, 41, 10, 35, 23, 37, 28, 44, 8, 45}, P.stoneDark)
        r(9, 37, 12, 3, P.stoneLight); r(13, 39, 4, 2, P.jade); return
    end
    p({cx - 8, top + 10, cx + 7, top + 10, cx + 11 + cape, 40 + bob, cx - 11, 42 + bob}, P.ink)
    p({cx - 7, top + 12, cx + 6, top + 12, cx + 8 + cape, 38 + bob, cx - 9, 40 + bob}, P.jadeDark)
    l(cx - 7, top + 15, cx - 9, 38 + bob, P.jade)
    r(cx - 9, 39 + math.min(2, leg), 6, 5, P.ink); r(cx + 3, 39 - math.min(2, leg), 6, 5, P.ink)
    r(cx - 8, 39 + math.min(2, leg), 4, 2, P.stoneLight); r(cx + 4, 39 - math.min(2, leg), 4, 2, P.stone)
    p({cx - 10, top + 11, cx - 6, top + 8, cx + 6, top + 8, cx + 11, top + 12, cx + 8, top + 27 - squat, cx - 8, top + 27 - squat}, P.ink)
    p({cx - 9, top + 12, cx - 5, top + 9, cx + 5, top + 9, cx + 9, top + 13, cx + 6, top + 25 - squat, cx - 7, top + 25 - squat}, P.stone)
    p({cx - 9, top + 12, cx - 5, top + 9, cx - 1, top + 10, cx - 4, top + 23, cx - 7, top + 23}, P.stoneLight)
    r(cx - 8, top + 11, 5, 2, P.gold); r(cx + 4, top + 12, 5, 2, P.goldDark)
    l(cx - 6, top + 25 - squat, cx + 6, top + 25 - squat, P.gold)
    if direction == 4 then
        r(cx - 2, top + 14, 4, 7, P.goldDark); l(cx, top + 15, cx, top + 20, P.jade)
    else
        p({cx - 3, top + 15, cx, top + 12, cx + 3, top + 15, cx, top + 20}, P.goldDark)
        l(cx, top + 14, cx - 2, top + 16, P.jadeLight); l(cx - 2, top + 16, cx, top + 18, P.jade)
    end
    if side ~= 0 then
        p({cx - 6, top + 1, cx, top - 2, cx + 6, top + 2, cx + 7, top + 9, cx + 3, top + 13, cx - 6, top + 11}, P.ink)
        p({cx - 5, top + 2, cx, top - 1, cx + 5, top + 3, cx + 5, top + 9, cx + 2, top + 11, cx - 5, top + 9}, P.stoneLight)
        p({cx - 5, top + 2, cx, top - 1, cx + 2, top + 1, cx - 3, top + 5}, P.stoneEdge)
        local eye = side == 1 and cx + 3 or cx - 5
        r(eye, top + 5, 3, 4, P.ink); r(eye, top + 6, 3, 1, P.jadeLight)
        local fist = cx + side * (action == 'warn' and 9 or action == 'dash' and 10 or 7)
        r(fist - 2, top + 17, 5, 7, P.ink); r(fist - 2, top + 17, 4, 4, P.stoneLight)
        r(fist - 2, top + 17, 4, 1, P.goldLight)
    else
        p({cx - 7, top + 2, cx - 3, top - 1, cx + 3, top - 1, cx + 7, top + 2, cx + 6, top + 10, cx, top + 13, cx - 6, top + 10}, P.ink)
        p({cx - 6, top + 2, cx - 3, top, cx + 3, top, cx + 6, top + 3, cx + 5, top + 9, cx, top + 11, cx - 5, top + 9}, P.stoneLight)
        l(cx - 5, top + 1, cx + 2, top, P.stoneEdge)
        if direction == 2 then
            r(cx - 5, top + 5, 10, 3, P.ink); r(cx - 4, top + 6, 3, 1, P.jadeLight); r(cx + 1, top + 6, 3, 1, P.jade)
            r(cx - 1, top + 8, 2, 3, P.goldDark)
        else l(cx + 1, top + 3, cx + 2, top + 8, P.stoneDark) end
        r(cx - 12, top + 17, 5, 7, P.ink); r(cx + 7, top + 16, 5, 7, P.ink)
        r(cx - 12, top + 17, 4, 4, P.stoneLight); r(cx + 7, top + 16, 4, 4, P.stone)
        r(cx - 12, top + 17, 4, 1, P.goldLight); r(cx + 7, top + 16, 4, 1, P.gold)
    end
    if action == 'warn' then
        l(cx - 4, top - 3, cx, top - 6, P.goldLight); l(cx, top - 6, cx + 4, top - 3, P.gold)
    end
end

-- Amâncio: another hooded traveler, stockier, a merchant pack on his back.
local function merchant(data, ox, oy, direction, action, frame)
    local r, l, p = painter(data, ox, oy)
    local east, south, west = direction == 1, direction == 2, direction == 3
    local side = east and 1 or west and -1 or 0
    local bob = ({0, -1, 0, 0})[frame]
    r(11, 42 + bob, 4, 3, P.ink); r(19, 42 + bob, 4, 3, P.ink)
    if direction == 4 then
        p({9, 14, 23, 14, 25, 39, 7, 39}, P.goldDark)
        r(10, 17 + bob, 12, 3, P.gold)
        r(12, 36 + bob, 8, 2, P.rust)
        p({11, 6, 21, 6, 23, 15, 9, 15}, P.rust)
    else
        local bx = 16 - side * 9
        p({bx - 4, 16, bx + 4, 16, bx + 5, 33, bx - 5, 33}, P.goldDark)
        r(bx - 3, 19 + bob, 7, 2, P.gold)
        p({11 - side, 19, 21 - side, 19, 24 - side, 43, 8 - side, 43}, P.rust)
        r(9 - side, 34 + bob, 13, 1, P.goldDark)
        p({10, 7, 22, 7, 24, 18, 8, 18}, P.goldDark)
        if south then
            r(13, 11, 7, 5, P.ink)
            r(14, 13, 2, 1, P.goldLight); r(18, 13, 2, 1, P.goldLight)
            r(14, 25, 4, 4, P.gold); r(15, 26, 2, 2, P.goldLight)
        else
            r(13 + side * 4, 11, 5, 5, P.ink)
            r(15 + side * 5, 13, 2, 1, P.goldLight)
            r(11 + side * 3, 20, 2, 12, P.goldDark)
        end
    end
end

-- Odete: a tall jade-robed keeper carrying a lit lantern.
local function keeper(data, ox, oy, direction, action, frame)
    local r, l, p = painter(data, ox, oy)
    local east, south, west = direction == 1, direction == 2, direction == 3
    local side = east and 1 or west and -1 or 0
    local bob = ({0, 0, -1, 0})[frame]
    r(12, 42 + bob, 3, 3, P.ink); r(19, 42 + bob, 3, 3, P.ink)
    p({13, 16, 20, 16, 23, 43, 10, 43}, P.jadeDark)
    r(10, 40 + bob, 13, 2, P.jade)
    p({12, 5, 20, 5, 22, 16, 10, 16}, P.jade)
    if direction ~= 4 then
        r(14, 10, 5, 4, P.ink)
        r(15 + side * 2, 11, 2, 1, P.jadeLight)
        if south then r(18, 11, 1, 1, P.jadeLight) end
        if south then l(14, 18, 16, 30, P.gold); l(19, 18, 17, 30, P.gold) end
    end
    local lx = south and 24 or 16 + side * 8
    l(16 + side * 4, 20, lx, 27, P.goldDark)
    r(lx - 2, 27, 5, 6, P.goldDark); r(lx - 1, 28, 3, 4, P.jade); r(lx, 29, 1, 2, P.jadeLight)
end

-- Campaign residents: one standing figure, palette per person. Silhouettes
-- keep the 40×48 frame; direction changes face and hair like the traveler.
local function resident(data, ox, oy, direction, action, frame, pal)
    local r, l, p = painter(data, ox, oy)
    local east, south, west, north = direction == 1, direction == 2, direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local bob = ({0, -1, 0, 0})[frame]
    local cx, top = 16, 12 + bob
    r(cx - 6, 39, 5, 5, P.ink); r(cx + 1, 39, 5, 5, P.ink)
    p({cx - 7, top + 9, cx + 7, top + 9, cx + 9, 42, cx - 9, 42}, P.ink)
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 8, 41, cx - 8, 41}, pal.cloth)
    r(cx - 6, top + 10, 12, 1, pal.accent)
    if north then
        p({cx - 5, top + 1, cx + 5, top, cx + 6, top + 6, cx + 5, top + 12, cx - 5, top + 12, cx - 6, top + 6}, P.ink)
        p({cx - 4, top + 1, cx + 4, top + 1, cx + 5, top + 6, cx + 4, top + 11, cx - 4, top + 11, cx - 5, top + 6}, pal.hair)
        l(cx - 4, top + 2, cx + 4, top + 2, pal.accent)
    else
        p({cx - 5, top + 1, cx + 5, top, cx + 6, top + 4, cx + 5, top + 11, cx - 5, top + 11, cx - 6, top + 4}, P.ink)
        p({cx - 4, top + 1, cx + 4, top + 1, cx + 5, top + 4, cx + 4, top + 10, cx - 4, top + 10, cx - 5, top + 4}, pal.cloth)
        r(cx - 4, top + 1, 9, 3, pal.hair)
        local fx = cx + side * 2
        r(fx - 3, top + 4, 7, 5, pal.skin)
        if side ~= 0 then
            r(fx + (east and 1 or -3), top + 5, 2, 2, P.ink)
            r(cx + side * 6, top + 11, 3, 14, pal.cloth)
        else
            r(fx - 2, top + 5, 2, 2, P.ink); r(fx + 2, top + 5, 2, 2, P.ink)
            r(fx - 2, top + 5, 2, 1, pal.eye or P.jadeLight); r(fx + 2, top + 5, 2, 1, pal.eye or P.jadeLight)
            r(cx - 8, top + 12, 3, 12, pal.cloth); r(cx + 6, top + 12, 3, 12, pal.cloth)
            r(cx - 8, top + 22, 3, 3, pal.skin); r(cx + 6, top + 22, 3, 3, pal.skin)
        end
    end
end

local residents = {
    npc_doro = {cloth = P.stoneDark, hair = P.stoneLight, skin = P.goldLight, accent = P.gold},
    npc_runa = {cloth = P.violetDark, hair = P.ink, skin = P.goldLight, accent = P.jade},
    npc_bento = {cloth = P.rust, hair = P.ink, skin = P.goldLight, accent = P.goldDark},
    npc_teca = {cloth = P.goldDark, hair = P.gold, skin = P.goldLight, accent = P.stoneLight},
    npc_sabela = {cloth = P.jadeDark, hair = P.goldDark, skin = P.goldLight, accent = P.jadeLight},
    npc_nilo = {cloth = P.jade, hair = P.ink, skin = P.goldLight, accent = P.goldLight},
    npc_aurel = {cloth = P.ink, hair = P.stoneDark, skin = P.goldLight, accent = P.violet},
}

local function sheet(actions, draw)
    local data = love.image.newImageData(frameW * 6, frameH * #actions * 4)
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
    local image = G.newImage(data); image:setFilter('nearest', 'nearest'); data:release()
    return {image = image, animations = animations}
end

local sharedSheets
function Actors.new()
    if not sharedSheets then
        sharedSheets = {player = sheet(playerActions, traveler), dasher = sheet(enemyActions, sentinel),
            npc_merchant = sheet(npcActions, merchant), npc_keeper = sheet(npcActions, keeper)}
        for kind, pal in pairs(residents) do
            sharedSheets[kind] = sheet(npcActions, function(data, ox, oy, dir, act, fr)
                resident(data, ox, oy, dir, act, fr, pal)
            end)
        end
    end
    return setmetatable({sheets = sharedSheets, states = {}, deaths = {}}, Actors)
end

function Actors.direction(entity)
    local f = entity.facing or {dx = 1, dy = 0}
    local w = entity.weapon
    if w and w.mineTimer > 0 then f = {dx = w.mineDx, dy = w.mineDy} end
    return f.dx > 0 and 1 or f.dy > 0 and 2 or f.dx < 0 and 3 or 4
end

function Actors.state(entity, record)
    if entity.npc then return 'idle' end
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
        if a.state == 'warn' then return 'warn', 1 - a.timer / (a.warningDuration or a.timer) end
        if a.state == 'dash' then return 'dash' end
        if a.state == 'recover' then return 'recover', 1 - a.timer / recoverDuration end
        if a.state == 'stunned' or a.state == 'exposed' then return 'recover' end
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
        local kind = entity.player and 'player' or entity.enemy and entity.enemy.kind
            or entity.npc and 'npc_' .. entity.npc.id
        if self.sheets[kind] then
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
                record.animation = self.sheets[kind].animations[state][direction]:clone()
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
            if entity.enemy and entity.enemy.kind == 'dasher' and entity.health.current <= 0 then
                self.deaths[#self.deaths + 1] = {x = (entity.grid.x - .5) * 32, y = (entity.grid.y - .5) * 32,
                    animation = self.sheets.dasher.animations.death[record.direction]:clone()}
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
    local kind = entity.player and 'player' or entity.enemy and entity.enemy.kind
        or entity.npc and 'npc_' .. entity.npc.id
    if not self.sheets[kind] then return false end
    local record = self.states[entity]
    local state, progress = Actors.state(entity, record)
    local animation = record and record.animation or self.sheets[kind].animations[state][Actors.direction(entity)]
    x, y = math.floor(x + .5), math.floor(y + .5)
    jump = renderer.reducedMotion and 0 or math.floor((jump or 0) + .5)
    tint(P.ink, .7); G.rectangle('fill', x - 9, y - 1, 18, 3); G.rectangle('fill', x - 6, y - 2, 12, 5)
    G.setColor(1, 1, 1, 1)
    animation:draw(self.sheets[kind].image, x, y - jump, 0, 1, 1, originX, originY)
    if entity.player then
        local w = entity.weapon
        if w.state == 'charging' or w.state == 'ready' then
            local ratio = w.state == 'ready' and 1 or w.charge / game:weaponStats().chargeTime
            tint(P.ink); G.rectangle('fill', x - 11, y - jump - 49, 22, 4)
            tint(P.gold); G.rectangle('fill', x - 10, y - jump - 48, math.floor(20 * ratio), 2)
            if w.state == 'ready' then
                tint(P.goldLight); G.rectangle('fill', x - 1, y - jump - 53, 2, 2)
                G.rectangle('fill', x - 3, y - jump - 51, 6, 1)
            end
        end
    elseif entity.enemy then
        tint(P.ink); G.rectangle('fill', x - 10, y - jump - 40, 20, 3)
        tint(P.danger); G.rectangle('fill', x - 9, y - jump - 39, math.floor(18 * entity.health.current / entity.health.max), 1)
        if entity.enemy.state == 'warn' then
            tint(P.goldLight); G.rectangle('fill', x - 1, y - jump - 46, 2, 3); G.rectangle('fill', x - 1, y - jump - 42, 2, 1)
        end
    end
    return true
end

function Actors:drawDeaths(renderer, game)
    for _, ghost in ipairs(self.deaths) do
        tint(P.ink, .7); G.rectangle('fill', ghost.x - 9, ghost.y - 1, 18, 3)
        G.setColor(1, 1, 1, 1)
        ghost.animation:draw(self.sheets.dasher.image, ghost.x, ghost.y, 0, 1, 1, originX, originY)
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
