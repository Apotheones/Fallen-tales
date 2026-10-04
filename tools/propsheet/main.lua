-- Prancha de props: cada painter do lote em célula 32x32, escala 4x, com
-- rótulo. Roda da raiz: lovec tools/propsheet -> screenshots/prancha-props.png
local Props, Palettes, Font

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/propsheet-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

-- (id, kind, x, y) — x/y alimentam as variações por célula (pertencesCama).
local itens = {
    {'banco', 'banco'}, {'bancoVelho', 'banco'}, {'bancoSerra', 'banco'},
    {'bancoPedra', 'banco'},
    {'lapide', 'lapide'}, {'lapideGasta', 'lapide'}, {'marcaImpro', 'flores'},
    {'poco', 'cisterna'},
    {'cama', 'cama'}, {'divisoria', 'divisoria'},
    {'pertencesCama1', 'pertences'}, {'pertencesCama2', 'pertences'},
    {'pertencesCama3', 'pertences'},
    {'quadro', 'placa'}, {'brinquedo', 'caixas'},
    {'serragem', 'caixas'}, {'divisoriaAberta', 'divisoria'},
    {'prateleira', 'caixas'}, {'varanda', 'banco'},
    {'caixao', 'caixao'}, {'bau', 'bau'}, {'mesa', 'mesa'},
    {'fogao', 'fogao'}, {'altar', 'altar'}, {'carteiras', 'carteiras'},
    {'caixas', 'caixas'}, {'flores', 'flores'},
    {'ferramentas', 'ferramentas'}, {'bancada', 'bancada'},
    {'pano', 'pano'},
}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'
    -- Stub leve de pixel_world: props.lua só precisa de palette + pixelLine
    -- e o módulo real puxa o ECS inteiro.
    local G = love.graphics
    local function round(n) return math.floor(n + .5) end
    package.preload['src.pixel_world'] = function()
        return {
            palette = {
                ink = {.027, .043, .067}, abyss = {.016, .024, .043},
                floorDark = {.075, .114, .149}, floor = {.090, .133, .169},
                floorLight = {.106, .149, .184}, joint = {.059, .090, .122},
                stoneDark = {.090, .133, .176}, stone = {.169, .235, .286},
                stoneLight = {.282, .361, .396}, stoneEdge = {.365, .455, .475},
                jadeDark = {.055, .235, .220}, jade = {.235, .635, .529},
                jadeLight = {.529, .886, .702}, goldDark = {.314, .235, .129},
                gold = {.643, .490, .251}, goldLight = {.847, .702, .392},
                white = {.898, .941, .847}, danger = {.941, .388, .302},
                rust = {.435, .204, .153}, violet = {.482, .318, .702},
                violetDark = {.278, .192, .412}, violetLight = {.690, .529, .878},
                jadeDeep = {.039, .141, .157}, jadeMid = {.133, .412, .376},
                violetDeep = {.169, .118, .286}, violetMid = {.376, .255, .545},
                goldDeep = {.192, .141, .067}, ember = {.976, .573, .216},
                emberLight = {1, .816, .494}, stoneDeep = {.055, .082, .114},
                bone = {.812, .749, .592}, boneDark = {.557, .478, .345},
            },
            pixelLine = function(x, y, tx, ty, c, alpha)
                x, y, tx, ty = round(x), round(y), round(tx), round(ty)
                local dx, dy = math.abs(tx - x), -math.abs(ty - y)
                local sx, sy = x < tx and 1 or -1, y < ty and 1 or -1
                local err = dx + dy
                while true do
                    G.setColor(c[1], c[2], c[3], alpha or 1)
                    G.rectangle('fill', x, y, 1, 1)
                    if x == tx and y == ty then break end
                    local twice = err * 2
                    if twice >= dy then err = err + dy; x = x + sx end
                    if twice <= dx then err = err + dx; y = y + sy end
                end
            end,
        }
    end
    Props = require('src.props')
    Palettes = require('src.palettes')
    Font = require('src.pixel_font').new(1)

    local G = love.graphics
    local cell, cols = 32, 7
    local scale = 4
    local rows = math.ceil(#itens / cols)
    local canvas = G.newCanvas(cols * cell + 8, rows * (cell + 7) + 8)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(Palettes.refuge.path)
    G.setFont(Font)
    for i, item in ipairs(itens) do
        local cx = 4 + ((i - 1) % cols) * cell
        local cy = 4 + math.floor((i - 1) / cols) * (cell + 7)
        -- piso neutro da célula
        G.setColor(Palettes.refuge.grassDark)
        G.rectangle('fill', cx, cy, cell, cell)
        Props.draw(
            {id = item[1], kind = item[2], x = item[3] or 3, y = item[4] or 3},
            cx, cy, cell, cell, Palettes.regions.hub, 1.3, false)
        G.setColor(Palettes.ink)
        G.print(item[1], cx, cy + cell + 1)
    end
    G.setCanvas()
    local big = G.newCanvas(canvas:getWidth() * scale, canvas:getHeight() * scale)
    big:setFilter('nearest', 'nearest')
    G.setCanvas(big)
    G.setColor(1, 1, 1)
    G.draw(canvas, 0, 0, 0, scale, scale)
    G.setCanvas()
    local f = assert(io.open('screenshots/prancha-props.png', 'wb'))
    f:write(big:newImageData():encode('png'):getString())
    f:close()
    print('prancha: screenshots/prancha-props.png')
    love.event.quit(0)
end
