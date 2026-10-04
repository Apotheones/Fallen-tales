-- Bake dos INIMIGOS + CHEFE (Fase 3, elenco): require direto de cada def
-- em src/sprites/ (NÃO passa por init.lua), dump de albedo/normal/
-- emissive em screenshots/foe_<nome>_*.png e screenshots/boss_runa_*.png
-- e prancha única screenshots/foes_prancha.png (uma linha por def: os 3
-- frames de albedo a 4x + normal f1 + emissive f1 a 2x).
-- Roda da raiz: lovec tools/bake_foes

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_foes-erro.txt', 'w')
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

local DEFS = {
    'foe_crawler',
    'foe_dasher',
    'foe_ranger',
    'foe_sower',
    'foe_breaker',
    'boss_runa_s',
    'boss_runa_n',
    'boss_runa_e',
    'boss_runa_w',
}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local G = love.graphics
    local sheets = {}
    for _, nome in ipairs(DEFS) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        if not okd then die('require src.sprites.' .. nome ..
            ' falhou: ' .. tostring(def)) return end
        local okb, sheet = pcall(DSL.bake, def)
        if not okb then die('bake de ' .. nome ..
            ' falhou: ' .. tostring(sheet)) return end
        sheets[nome] = sheet
        DSL.dump(sheet, 'screenshots/' .. nome)
        -- zoom 4x do sheet de albedo inteiro p/ leitura visual
        local alb = to_drawable(sheet.albedo)
        if alb then
            local z = G.newCanvas(sheet.w * sheet.frames * 4,
                sheet.h * 4)
            z:setFilter('nearest', 'nearest')
            G.setCanvas(z); G.clear(0, 0, 0, 0); G.setColor(1, 1, 1)
            G.draw(alb, 0, 0, 0, 4, 4)
            G.setCanvas()
            local zf = assert(io.open('screenshots/zoom_' .. nome ..
                '.png', 'wb'))
            zf:write(z:newImageData():encode('png'):getString())
            zf:close()
        end
        -- zoom 4x do emissivo sobre fundo escuro p/ ler o glow por frame
        local emi = to_drawable(sheet.emissive)
        if emi then
            local z = G.newCanvas(sheet.w * sheet.frames * 4,
                sheet.h * 4)
            z:setFilter('nearest', 'nearest')
            G.setCanvas(z); G.clear(.06, .05, .09, 1); G.setColor(1, 1, 1)
            G.draw(emi, 0, 0, 0, 4, 4)
            G.setCanvas()
            local zf = assert(io.open('screenshots/zoom_' .. nome ..
                '_emi.png', 'wb'))
            zf:write(z:newImageData():encode('png'):getString())
            zf:close()
        end
    end

    -- Prancha: por def, uma linha com os frames de albedo a 4x + normal
    -- e emissive do frame 1 a 2x.
    local escala, escala2, gap = 4, 2, 8
    local largura, altura = gap, gap
    local rows = {}
    for _, nome in ipairs(DEFS) do
        local sheet = sheets[nome]
        local alb = to_drawable(sheet.albedo)
        local row, roww, rowh = {}, 0, 0
        if alb then
            for f = 1, sheet.frames do
                local q = G.newQuad((f - 1) * sheet.w, 0, sheet.w, sheet.h,
                    sheet.albedo:getWidth(), sheet.albedo:getHeight())
                row[#row + 1] = { alb, q, escala }
                roww, rowh = roww + sheet.w * escala + gap,
                    sheet.h * escala
            end
        end
        for _, c in ipairs({ 'normal', 'emissive' }) do
            local img = to_drawable(sheet[c])
            if img then
                local q = G.newQuad(0, 0, sheet.w, sheet.h,
                    img:getWidth(), img:getHeight())
                row[#row + 1] = { img, q, escala2 }
                roww, rowh = roww + sheet.w * escala2 + gap,
                    math.max(rowh, sheet.h * escala2)
            end
        end
        rows[#rows + 1] = { nome = nome, row = row, w = roww, h = rowh }
        largura = math.max(largura, roww + gap)
        altura = altura + rowh + gap
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
            G.draw(cell[1], cell[2], x, y + r.h - qh * cell[3],
                0, cell[3], cell[3])
            x = x + qw * cell[3] + gap
        end
        y = y + r.h + gap
    end
    G.setCanvas()
    local f = assert(io.open('screenshots/foes_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    print('bake_foes ok: ' .. #DEFS .. ' defs -> screenshots/foes_prancha.png')
    love.event.quit(0)
end
