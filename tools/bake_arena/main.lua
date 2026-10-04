-- Bake dos sprites da arena-novo (require direto, fora do init.lua):
-- piso_arena e tocha. Dump de albedo/normal/emissive em
-- screenshots/arena_<nome>_*.png e prancha única
-- screenshots/arena_prancha.png (linha por sprite: frames de albedo a
-- 2x + normal f1 + emissive f1).
-- Roda da raiz: lovec tools/bake_arena

local function die(msg)
    local f = io.open('screenshots/bake_arena-erro.txt', 'w')
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

    local nomes = { 'piso_arena', 'tocha' }
    local defs = {}
    for _, nome in ipairs(nomes) do
        local okr, def = pcall(require, 'src.sprites.' .. nome)
        if not okr then die('require src.sprites.' .. nome ..
            ' falhou: ' .. tostring(def)) return end
        defs[nome] = def
    end

    local G = love.graphics
    local sheets = {}
    for _, nome in ipairs(nomes) do
        local okb, sheet = pcall(DSL.bake, defs[nome])
        if not okb then die('bake ' .. nome .. ' falhou: ' .. tostring(sheet)) return end
        sheets[nome] = sheet
        DSL.dump(sheet, 'screenshots/arena_' .. nome)
    end

    -- Prancha: por sprite, uma linha com os frames de albedo (máx 4) +
    -- normal e emissive do frame 1, tudo a 2x.
    local escala, gap = 2, 8
    local largura, altura = gap, gap
    local rows = {}
    for _, nome in ipairs(nomes) do
        local sheet = sheets[nome]
        local alb = to_drawable(sheet.albedo)
        local row, roww, rowh = {}, 0, 0
        if alb then
            local nf = math.min(sheet.frames, 4)
            for f = 1, nf do
                local q = G.newQuad((f - 1) * sheet.w, 0, sheet.w, sheet.h,
                    sheet.albedo:getWidth(), sheet.albedo:getHeight())
                row[#row + 1] = { alb, q }
                roww, rowh = roww + sheet.w * escala + gap, sheet.h * escala
            end
        end
        for _, c in ipairs({ 'normal', 'emissive' }) do
            local img = to_drawable(sheet[c])
            if img then
                local q = G.newQuad(0, 0, sheet.w, sheet.h,
                    img:getWidth(), img:getHeight())
                row[#row + 1] = { img, q }
                roww, rowh = roww + sheet.w * escala + gap,
                    math.max(rowh, sheet.h * escala)
            end
        end
        rows[#rows + 1] = { nome = nome, row = row, w = roww, h = rowh }
        largura = math.max(largura, roww + gap)
        altura = altura + rowh + gap
    end

    -- Zoom de revisão: cada frame de albedo a 4x, um PNG por sprite.
    local zoom = 4
    for _, nome in ipairs(nomes) do
        local sheet = sheets[nome]
        local cv = G.newCanvas(sheet.w * zoom * sheet.frames, sheet.h * zoom)
        cv:setFilter('nearest', 'nearest')
        G.setCanvas(cv)
        G.clear(0, 0, 0, 0)
        G.setColor(1, 1, 1)
        local alb = to_drawable(sheet.albedo)
        if alb then
            for f = 1, sheet.frames do
                local q = G.newQuad((f - 1) * sheet.w, 0, sheet.w, sheet.h,
                    alb:getWidth(), alb:getHeight())
                G.draw(alb, q, (f - 1) * sheet.w * zoom, 0, 0, zoom, zoom)
            end
        end
        G.setCanvas()
        local fz = assert(io.open('screenshots/arena_' .. nome ..
            '_zoom.png', 'wb'))
        fz:write(cv:newImageData():encode('png'):getString())
        fz:close()
    end

    local canvas = G.newCanvas(largura, altura)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0, 0, 0, 0)
    G.setColor(1, 1, 1)
    local y = gap
    for _, r in ipairs(rows) do
        local x = gap
        for _, cell in ipairs(r.row) do
            local _, _, qw, qh = cell[2]:getViewport()
            G.draw(cell[1], cell[2], x, y + r.h - qh * escala, 0, escala, escala)
            x = x + qw * escala + gap
        end
        y = y + r.h + gap
    end
    G.setCanvas()
    local f = assert(io.open('screenshots/arena_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    print('bake ok: ' .. #nomes .. ' sprites -> arena_prancha.png')
    love.event.quit(0)
end
