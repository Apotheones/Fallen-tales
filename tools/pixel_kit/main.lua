-- Rodar da raiz: lovec tools/pixel_kit --screenshot=screenshots/pixel-kit.png
local K, sheet, capture, testOnly

local function check()
    local g = K.new(7, 7)
    K.rect(g, 3, 3, 3, 3, 'a')
    local mask = K.clone(g)
    K.rect(g, -2, -2, 12, 12, 'b', mask)
    assert(K.inspect(g).pixels == 9 and K.get(g,3,3) == 'b')
    K.outline(g, 'o')
    assert(K.inspect(g).pixels == 21 and K.get(g,2,2) == '.')
    assert(K.get(mask,2,3) == '.' and K.get(mask,3,3) == 'a')
    local line = K.new(7,7)
    K.line(line,1,1,7,7,'l'); K.line(line,7,1,1,7,'l')
    assert(K.inspect(line).pixels == 13)
    local shape = K.new(7,7)
    K.polygon(shape,{2,2,6,2,6,6,2,6},'p')
    assert(K.inspect(shape).pixels == 25)
    local ellipse = K.new(7,7)
    K.ellipse(ellipse,2,2,4,4,'e')
    assert(K.inspect(ellipse).pixels == 12)
    assert(K.string(K.flip(K.flip(ellipse,true,true),true,true)) == K.string(ellipse))
    local point = K.new(7,7)
    K.pixel(point,2,3,'a')
    assert(K.get(K.flip(point,true,false),6,3) == 'a')
    K.blit(point,point,1,0)
    assert(K.inspect(point).pixels == 2 and K.get(point,4,3) == '.')
    K.paint(point,function() return 'z' end)
    local report = K.inspect(point,{a='stone.3'})
    assert(#report.unknown == 2 and #report.isolated == 0)
    K.pixel(point,7,7,'z')
    assert(#K.inspect(point).isolated == 1)
    assert(not pcall(K.pixel,point,1.5,1,'a'))
    assert(not pcall(K.pixel,point,1,1,'ab'))
    assert(not pcall(K.layer,'bad',point,K.new(2,2)))
    assert(not pcall(K.new,0,2))
    assert(not pcall(K.line,point,0/0,1,2,2,'a'))
end

function love.load(args)
    package.path = package.path .. ';./?.lua;./?/init.lua'
    for _, arg in ipairs(args) do
        capture = arg:match('^%-%-screenshot=(.+)$') or capture
        if arg == '--test' then testOnly = true end
    end
    K = require('src.pixel_kit')
    check()
    local body, flame = K.new(48,64), K.new(48,64)
    K.rect(body,22,9,5,4,'m')
    K.line(body,24,3,24,9,'m')
    K.polygon(body,{16,17,32,17,35,23,13,23},'m')
    K.rect(body,15,24,3,22,'m'); K.rect(body,31,24,3,22,'m')
    K.rect(body,18,44,13,4,'m')
    K.polygon(body,{13,49,35,49,32,54,16,54},'m')
    K.rect(body,21,54,7,4,'m'); K.ellipse(body,14,58,21,4,'m')
    K.paint(body,function(x,y)
        if x <= 18 or y == 17 or y == 49 or y == 58 then return 'h' end
        if x >= 30 then return 's' end
        return 'm'
    end)
    K.outline(body,'o')
    K.polygon(flame,{24,26,29,35,27,42,22,43,20,37,23,32},'f')
    local flameMask = K.clone(flame)
    K.ellipse(flame,23,35,4,8,'g',flameMask)
    local height, emission = K.new(48,64), K.clone(flame)
    K.rect(height,1,1,48,64,'5',body)
    K.rect(height,1,1,48,64,'a',flameMask)
    K.blit(body,flame,0,0)
    local legend = {o='iron.1',s='iron.2',m='iron.3',h='iron.5',
        f={ramp='ember',step=4,ei=.6},g={ramp='ember',step=6,ei=1}}
    assert(#K.inspect(body,legend).unknown == 0)
    local DSL = require('src.sprite_dsl')
    sheet = DSL.bake({name='pixel_kit_lantern',w=48,h=64,origin='feet',legend=legend,
        layers={K.layer('lantern',body,height,emission)}})
    assert(sheet.w == 48 and sheet.h == 64 and sheet.frames == 1)
    local _,_,_,alpha = sheet.imageData.albedo:getPixel(0,0)
    assert(alpha == 0)
    local _,_,_,emit = sheet.imageData.emissive:getPixel(23,37)
    assert(emit > 0)
    DSL.dump(sheet,'screenshots/pixel-kit-lantern')
    love.window.setMode(760,560)
    love.graphics.setBackgroundColor(.055,.065,.09)
    print('pixel_kit: checks passed; DSL bake/export passed')
    if testOnly and not capture then love.event.quit(0) end
end

function love.draw()
    if not sheet then return end
    love.graphics.setColor(1,1,1)
    love.graphics.print('Arrowfallen / Pixel Kit',24,20)
    love.graphics.print('1x                       6x                       normal                 emissive',24,62)
    local function panel(image,x,y,scale)
        for py=0,63 do for px=0,47 do
            local v = (math.floor(px/4)+math.floor(py/4))%2 == 0 and .13 or .17
            love.graphics.setColor(v,v,v)
            love.graphics.rectangle('fill',x+px*scale,y+py*scale,scale,scale)
        end end
        love.graphics.setColor(1,1,1)
        love.graphics.draw(image,x,y,0,scale,scale)
    end
    panel(sheet.albedo,24,94,1)
    panel(sheet.albedo,116,94,6)
    panel(sheet.normal,440,94,3)
    panel(sheet.emissive,610,94,2)
    love.graphics.print('Paleta indexada / silhueta / mascara / relevo / emissao',24,510)
    if capture then
        local path = capture
        assert(path:match('^screenshots/[%w_%-]+%.png$'), 'screenshot deve ficar em screenshots/')
        capture = nil
        love.graphics.captureScreenshot(function(data)
            local f = assert(io.open(path,'wb'))
            f:write(data:encode('png'):getString()); f:close()
            love.event.quit(0)
        end)
    end
end

function love.keypressed(key) if key == 'escape' then love.event.quit() end end

function love.errorhandler(message)
    local f = io.open('screenshots/pixel-kit-error.txt','w')
    if f then f:write(tostring(message),'\n',debug.traceback()); f:close() end
    print(message)
    return function() return 1 end
end
