-- Vespa: repro de movimento p/ bug da luz piscando.
-- Anda no hub real, captura frames POR TICK no fim da caminhada e mede:
--   (a) diff temporal com camera parada (flicker puro);
--   (b) diff ALINHADO pela translacao da camera (residuo = popping de
--       sombra/luz que a geometria nao explica — o suspeito do relato).
local Campaign = require('src.campaign')
local Save = require('src.save')
local Render = require('src.render')
local E = {}
local IDLE = {dx = 0, dy = 0, guard = false, events = {}}
local WALK = {dx = 0, dy = 1, guard = false, events = {}} -- sul

local function diffAligned(A, B, dx, dy, w, h)
    -- compara A(x,y) com B(x+dx,y+dy); conta diffs por regiao
    local x0, x1 = math.max(0, -dx), math.min(w, w - dx)
    local y0, y1 = math.max(0, -dy), math.min(h, h - dy)
    local band, inner, tot = 0, 0, 0
    local bx0, by0 = x0 + 24, y0 + 24
    local bx1, by1 = x1 - 24, y1 - 24
    for y = y0, y1 - 1 do
        for x = x0, x1 - 1 do
            local r1, g1, b1 = A:getPixel(x, y)
            local r2, g2, b2 = B:getPixel(x + dx, y + dy)
            if math.abs(r1 - r2) > .05 or math.abs(g1 - g2) > .05
                or math.abs(b1 - b2) > .05 then
                tot = tot + 1
                if x < bx0 or x >= bx1 or y < by0 or y >= by1 then
                    band = band + 1
                else inner = inner + 1 end
            end
        end
    end
    return tot, band, inner
end

function E.run()
    Save.file = 'test_campaign_save.lua'; Save.clear()
    local c = Campaign.new()
    while c.dialogue do c.dialogue.reveal = math.huge; c:advanceDialogue() end
    c:travel('hub', 'colina')
    local r = Render.new(); r.hdEnabled = true -- igual ao main.lua (ARROWFALLEN_HD~=0)
    local w, h = love.graphics.getDimensions()
    local function drain()
        while c.dialogue do
            c.dialogue.reveal = math.huge; c:advanceDialogue()
            if c.dialogue and c.dialogue.mode == 'options' then
                c:chooseDialogue(#c.dialogue.node.options)
            end
        end
    end
    local function tick(inp)
        c:update(1 / 120, inp); drain()
        r:updateCampaign(1 / 120, c, 'playing')
    end
    for _ = 1, 700 do tick(IDLE) end
    do -- priming draw: hd.lighting so existe depois do primeiro drawCampaign
        local cap = love.graphics.newCanvas(w, h)
        love.graphics.setCanvas(cap)
        r:drawCampaign(c, 'playing', false)
        love.graphics.setCanvas(); cap:release()
        if os.getenv('MOV_LM') and r.hd and r.hd.lighting then
            r.hd.lighting._dbgLightmapOnly = 1
            print('[ev-mov] lightmap-only ON')
        end
    end
    print(('[ev-mov] spawn %.1f,%.1f'):format(c.player.grid.x, c.player.grid.y))
    local frames, cams = {}, {}
    local function snap(tag)
        local cap = love.graphics.newCanvas(w, h)
        love.graphics.setCanvas(cap)
        r:drawCampaign(c, 'playing', false)
        love.graphics.setCanvas()
        frames[tag] = cap:newImageData()
        cams[tag] = {l = r.view.left, t = r.view.top, s = r.view.scale}
        cap:release()
    end
    -- camera parada (ainda pisando no lugar? nao — primeiro frames idle)
    tick(IDLE); snap('idle1'); tick(IDLE); snap('idle2')
    -- caminhada: 8 ticks com captura por tick
    local seq = {}
    for i = 1, 10 do
        for _ = 1, 4 do tick(WALK) end
        snap('w' .. i); seq[i] = 'w' .. i
    end
    local t, b, i = diffAligned(frames.idle1, frames.idle2, 0, 0, w, h)
    print(('[ev-mov] idle-vs-idle: total=%d band=%d inner=%d'):format(t, b, i))
    for k = 2, #seq do
        local a, btag = cams[seq[k - 1]], cams[seq[k]]
        local dx = math.floor((btag.l - a.l) * btag.s + .5)
        local dy = math.floor((btag.t - a.t) * btag.s + .5)
        -- varre ±2px em torno do delta teorico: o minimo revela o alinhamento real
        local best
        for ddy = dy - 2, dy + 2 do
            t, b, i = diffAligned(frames[seq[k - 1]], frames[seq[k]], dx, ddy, w, h)
            print(('[ev-mov] %s->%s cam %+d dy=%+d: total=%d band=%d inner=%d')
                :format(seq[k - 1], seq[k], dx, ddy, t, b, i))
            if not best or t < best[1] then best = {t, ddy, b, i} end
        end
        print(('[ev-mov] %s->%s BEST dy=%+d total=%d (band %d inner %d)')
            :format(seq[k - 1], seq[k], best[2], best[1], best[3], best[4]))
    end
    -- dump visual: w5 e w6 + mapa de diff alinhado (vermelho = mudou >5%)
    if os.getenv('MOV_LM') then
        for _, t2 in ipairs({'w5', 'w6'}) do
            local f = assert(io.open('../../screenshots/lm-' .. t2 .. '.png', 'wb'))
            f:write(frames[t2]:encode('png'):getString()); f:close()
        end
        local a, btag = cams.w5, cams.w6
        local dy = math.floor((btag.t - a.t) * btag.s + .5) + 1 -- best sweep = +7
        local dimg = love.image.newImageData(w, h)
        for y = 0, h - 1 - dy do for x = 0, w - 1 do
            local r1, g1, b1 = frames.w5:getPixel(x, y)
            local r2, g2, b2 = frames.w6:getPixel(x, y + dy)
            if math.abs(r1 - r2) > .05 or math.abs(g1 - g2) > .05
                or math.abs(b1 - b2) > .05 then
                dimg:setPixel(x, y, 1, 0, 0, 1)
            end
        end end
        local f = assert(io.open('../../screenshots/lm-diff-w5w6.png', 'wb'))
        f:write(dimg:encode('png'):getString()); f:close()
        print('[ev-mov] dump lm-w5/lm-w6/lm-diff-w5w6.png')
    end
    print('[ev-mov] ok')
end
return E
