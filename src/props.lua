-- Authored props for campaign regions. Every prop is pixel-painted in code,
-- one function per kind, anchored at the prop's top-left cell (32 px each).
local P = require('src.pixel_world').palette
local pixelLine = require('src.pixel_world').pixelLine
local Props = {}
local G = love.graphics

local function rect(x, y, w, h, c, alpha)
    G.setColor(c[1], c[2], c[3], alpha or 1)
    G.rectangle('fill', math.floor(x + .5), math.floor(y + .5), math.floor(w + .5), math.floor(h + .5))
end

-- Each entry draws inside the 32×32 square of a single cell; larger props
-- repeat their painter per covered cell.
local draw = {}

draw.sepultura = function(px, py)
    rect(px + 2, py + 4, 28, 24, P.ink)
    rect(px + 3, py + 5, 26, 22, P.abyss)
    rect(px + 4, py + 6, 24, 2, P.stoneDark)
    rect(px + 4, py + 24, 24, 2, P.stoneDark)
    pixelLine(px + 6, py + 12, px + 14, py + 20, P.stoneDark)
    pixelLine(px + 14, py + 12, px + 22, py + 20, P.stoneDark)
    rect(px + 1, py + 2, 30, 3, P.stone)
    rect(px + 1, py + 2, 30, 1, P.stoneEdge)
end

draw.tampa = function(px, py)
    rect(px + 4, py + 18, 24, 9, P.stoneDark)
    rect(px + 5, py + 19, 22, 7, P.stone)
    pixelLine(px + 9, py + 19, px + 14, py + 25, P.ink)
    pixelLine(px + 14, py + 19, px + 19, py + 25, P.ink)
end

draw.banco = function(px, py)
    rect(px + 3, py + 16, 26, 5, P.goldDark)
    rect(px + 3, py + 15, 26, 2, P.gold)
    rect(px + 5, py + 21, 3, 7, P.ink)
    rect(px + 24, py + 21, 3, 7, P.ink)
end

draw.pano = function(px, py)
    rect(px + 4, py + 4, 24, 26, P.jadeDark, .85)
    rect(px + 4, py + 4, 24, 3, P.jade)
    for i = 0, 3 do rect(px + 6 + i * 6, py + 8, 2, 20, P.ink, .5) end
    rect(px + 4, py + 28, 24, 1, P.jadeLight)
end

draw.bau = function(px, py, prop)
    local open = prop and prop.state == 'done'
    rect(px + 4, py + 12, 24, 15, P.goldDark)
    rect(px + 5, py + 13, 22, 12, P.rust)
    if open then
        rect(px + 4, py + 6, 24, 5, P.goldDark)
        rect(px + 6, py + 13, 20, 4, P.ink)
    else
        rect(px + 4, py + 10, 24, 4, P.gold)
        rect(px + 14, py + 13, 4, 5, P.goldLight)
    end
end

draw.grade = function(px, py, prop)
    if prop and prop.state == 'open' then
        for i = 0, 4 do rect(px + 4 + i * 5, py + 1, 2, 7, P.stoneDark) end
        rect(px + 3, py + 8, 26, 2, P.stone)
        return
    end
    rect(px + 2, py + 2, 28, 3, P.stoneDark)
    rect(px + 2, py + 27, 28, 3, P.stoneDark)
    for i = 0, 4 do
        local x = px + 4 + i * 5
        rect(x, py + 2, 2, 28, P.stone)
        rect(x, py + 2, 1, 28, P.stoneLight)
    end
    rect(px + 2, py + 14, 28, 2, P.goldDark)
end

draw.flores = function(px, py)
    for _, f in ipairs({{8, 20}, {14, 22}, {20, 19}, {24, 23}}) do
        rect(px + f[1], py + f[2], 2, 2, P.jadeLight)
        rect(px + f[1] - 1, py + f[2] + 1, 4, 2, P.jadeDark)
    end
end

draw.altar = function(px, py)
    rect(px + 5, py + 10, 22, 18, P.stoneDark)
    rect(px + 5, py + 10, 22, 3, P.stone)
    rect(px + 8, py + 4, 3, 8, P.goldDark)
    rect(px + 21, py + 4, 3, 8, P.goldDark)
    rect(px + 8, py + 3, 3, 2, P.goldLight)
    rect(px + 21, py + 3, 3, 2, P.goldLight)
end

draw.fogao = function(px, py)
    rect(px + 4, py + 8, 24, 20, P.stoneDark)
    rect(px + 6, py + 12, 20, 8, P.ink)
    rect(px + 9, py + 14, 14, 4, P.rust)
    rect(px + 11, py + 15, 4, 2, P.goldLight)
    rect(px + 18, py + 15, 4, 2, P.gold)
end

draw.mesa = function(px, py)
    rect(px + 2, py + 10, 28, 5, P.goldDark)
    rect(px + 2, py + 10, 28, 2, P.gold)
    rect(px + 4, py + 15, 3, 12, P.ink)
    rect(px + 25, py + 15, 3, 12, P.ink)
end

draw.cama = function(px, py)
    rect(px + 3, py + 6, 26, 21, P.goldDark)
    rect(px + 4, py + 7, 24, 19, P.jadeDark)
    rect(px + 4, py + 7, 24, 6, P.stone)
    rect(px + 4, py + 14, 24, 12, P.jade)
end

draw.cisterna = function(px, py)
    rect(px + 1, py + 1, 30, 30, P.stoneDark)
    rect(px + 3, py + 3, 26, 26, P.abyss)
    rect(px + 3, py + 3, 26, 2, P.jadeDark)
    pixelLine(px + 8, py + 12, px + 16, py + 10, P.jadeDark)
    pixelLine(px + 14, py + 20, px + 22, py + 18, P.jadeDark)
end

draw.bancada = function(px, py)
    rect(px + 2, py + 8, 28, 8, P.goldDark)
    rect(px + 2, py + 8, 28, 2, P.gold)
    rect(px + 4, py + 16, 3, 12, P.ink)
    rect(px + 25, py + 16, 3, 12, P.ink)
    pixelLine(px + 8, py + 4, px + 13, py + 8, P.stoneLight)
    pixelLine(px + 18, py + 3, px + 15, py + 8, P.stone)
end

draw.ferramentas = function(px, py)
    rect(px + 6, py + 6, 20, 20, P.stoneDark)
    pixelLine(px + 9, py + 10, px + 15, py + 18, P.gold)
    pixelLine(px + 15, py + 10, px + 9, py + 18, P.stoneLight)
    rect(px + 18, py + 9, 4, 12, P.rust)
end

draw.carteiras = function(px, py)
    rect(px + 4, py + 12, 10, 8, P.goldDark)
    rect(px + 18, py + 12, 10, 8, P.goldDark)
    rect(px + 5, py + 20, 3, 8, P.ink)
    rect(px + 24, py + 20, 3, 8, P.ink)
end

draw.caixas = function(px, py)
    rect(px + 4, py + 14, 12, 14, P.goldDark)
    rect(px + 5, py + 15, 10, 12, P.rust)
    rect(px + 16, py + 8, 12, 20, P.stoneDark)
    rect(px + 17, py + 9, 10, 18, P.stone)
end

function Props.draw(prop, px, py)
    if prop.state == 'taken' then return end
    local painter = draw[prop.kind]
    if painter then painter(px, py, prop) end
end

function Props.selfCheck()
    for kind in pairs(draw) do assert(type(draw[kind]) == 'function', 'prop painter: ' .. kind) end
    return true
end

return Props
