-- Bake dos retratos DSL (src/sprites/portrait_*.lua, 96x96, frames =
-- expressões). Dump de albedo/normal/emissive por retrato em
-- screenshots/portrait_<id>_{albedo,normal,emissive}.png e prancha
-- única screenshots/portraits_prancha.png (linha = personagem, colunas
-- = expressões, a 2x).
-- Roda da raiz: lovec tools/bake_portraits

local function die(msg)
    local f = io.open('screenshots/bake_portraits-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local function to_drawable(v)
    if type(v) ~= 'userdata' then return nil end
    local ok, is = pcall(function()
        return v:typeOf('Image') or v:typeOf('Canvas')
    end)
    if ok and is then return v end
    local ok2, isd = pcall(function() return v:typeOf('ImageData') end)
    if ok2 and isd then return love.graphics.newImage(v) end
    return nil
end

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local IDS = { 'viajante', 'doro', 'aurel', 'sabela', 'bento', 'runa' }

    local G = love.graphics
    local sheets = {}
    for _, id in ipairs(IDS) do
        local okd, def = pcall(require, 'src.sprites.portrait_' .. id)
        if not okd then die('require portrait_' .. id .. ' falhou: ' .. tostring(def)) return end
        local okb, sheet = pcall(DSL.bake, def)
        if not okb then die('bake portrait_' .. id .. ' falhou: ' .. tostring(okb)) return end
        sheets[id] = sheet
        DSL.dump(sheet, 'screenshots/portrait_' .. id)
    end

    -- Prancha: linha por personagem, uma coluna por expressão (albedo 2x).
    local escala, gap, labelW = 2, 8, 88
    local ncols = 3
    local largura = labelW + ncols * (96 * escala + gap) + gap
    local altura = gap + #IDS * (96 * escala + gap)
    local canvas = G.newCanvas(largura, altura)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(.09, .09, .12, 1) -- fundo escuro: o alpha do busto lê melhor
    G.setColor(1, 1, 1)
    local font = G.newFont(16)
    local y = gap
    for _, id in ipairs(IDS) do
        local sheet = sheets[id]
        G.setColor(.6, .6, .65)
        G.print(id, font, gap, y + 96 * escala / 2 - 8)
        G.setColor(1, 1, 1)
        local alb = to_drawable(sheet.albedo)
        for f = 1, sheet.frames do
            local q = G.newQuad((f - 1) * sheet.w, 0, sheet.w, sheet.h,
                alb:getWidth(), alb:getHeight())
            G.draw(alb, q, labelW + (f - 1) * (sheet.w * escala + gap), y,
                0, escala, escala)
        end
        y = y + sheet.h * escala + gap
    end
    G.setCanvas()
    local f = assert(io.open('screenshots/portraits_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    print('bake ok: ' .. #IDS .. ' retratos -> portraits_prancha.png')
    love.event.quit(0)
end
