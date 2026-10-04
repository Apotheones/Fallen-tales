-- Recorta uma região de um PNG e grava ampliada (nearest) em screenshots/.
-- Uso: lovec tools/crop <img> <x> <y> <w> <h> <zoom> <out>
-- Sem conf.lua: o LÖVE roda esta pasta como jogo próprio — <img> e <out>
-- precisam ser caminhos alcançáveis pelo filesystem do projeto.
function love.load(args)
    local img, x, y, w, h = args[1], tonumber(args[2]), tonumber(args[3]),
        tonumber(args[4]), tonumber(args[5])
    local zoom, out = tonumber(args[6]) or 3, args[7] or 'screenshots/crop.png'
    local data = love.image.newImageData(img)
    local crop = love.image.newImageData(w, h)
    crop:paste(data, 0, 0, x, y, w, h)
    local scaled = love.image.newImageData(w * zoom, h * zoom)
    for j = 0, h - 1 do for i = 0, w - 1 do
        local r, g, b, al = crop:getPixel(i, j)
        for sj = 0, zoom - 1 do for si = 0, zoom - 1 do
            scaled:setPixel(i * zoom + si, j * zoom + sj, r, g, b, al)
        end end
    end end
    local f = assert(io.open(out, 'wb'))
    f:write(scaled:encode('png'):getString()); f:close()
    love.event.quit(0)
end
function love.draw() end
