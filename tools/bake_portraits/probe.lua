-- sonda rápida: conta pixels com alpha>0 no emissivo do retrato
package.path = package.path .. ';./?.lua;./?/init.lua'
local DSL = require('src.sprite_dsl')
local def = require('src.sprites.portrait_viajante')
local sheet = DSL.bake(def)
local id = sheet.imageData.emissive
local hits = 0
for y = 0, id:getHeight() - 1 do
    for x = 0, id:getWidth() - 1 do
        local r, g, b, a = id:getPixel(x, y)
        if a > 0 then hits = hits + 1; print(('emissive (%d,%d) = %.2f %.2f %.2f'):format(x, y, r, g, b)) end
    end
end
print('total', hits)
