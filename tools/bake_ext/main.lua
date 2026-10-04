-- Bake dos sprites DSL da frente PRAÇA/RUAS/MIRANTE (Fase 2): para cada
-- def em src.sprites.<nome> (require por caminho direto — defs novas não
-- entram em init.lua), dump de albedo/normal/emissive em
-- screenshots/ext_<nome>_*.png e prancha única
-- screenshots/ext_prancha.png — linha por sprite: frames de albedo +
-- normal f1 + emissive f1, tudo a 2x.
-- Roda da raiz: lovec tools/bake_ext
--
-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_ext-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local ordem = {
    'lampiao', 'banco_madeira', 'banco_pedra', 'banco_serra',
    'varal', 'toldo', 'recipientes', 'cartaz', 'parapeito',
    'posto_vigia', 'remendo_muro', 'rocha',
}

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

    local G = love.graphics
    local sheets = {}
    for _, nome in ipairs(ordem) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        if not okd then die('require src.sprites.' .. nome ..
            ' falhou: ' .. tostring(def)) return end
        local okb, sheet = pcall(DSL.bake, def)
        if not okb then die('bake ' .. nome .. ' falhou: ' .. tostring(sheet)) return end
        sheets[nome] = sheet
        DSL.dump(sheet, 'screenshots/ext_' .. nome)
    end

    -- Prancha: por sprite, uma linha com os frames de albedo (máx 4) +
    -- normal e emissive do frame 1, tudo a 2x.
    local escala, gap = 2, 8
    local largura, altura = gap, gap
    local rows = {}
    for _, nome in ipairs(ordem) do
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

    local canvas = G.newCanvas(largura, altura)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0.09, 0.09, 0.11, 1) -- fundo escuro neutro p/ ler emissivo
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

    local f = assert(io.open('screenshots/ext_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    -- Prancha de inspeção: albedo a 4x sobre fundo escuro, linha por
    -- sprite (com os frames lado a lado) — para julgar leitura de perto.
    local z = 4
    local zl, zh = gap, gap
    for _, nome in ipairs(ordem) do
        local sheet = sheets[nome]
        zl = zl + sheet.w * math.min(sheet.frames, 4) * z + gap
        zh = zh + sheet.h * z + 4
    end
    local zc = G.newCanvas(zl, zh)
    zc:setFilter('nearest', 'nearest')
    G.setCanvas(zc)
    G.clear(0.16, 0.15, 0.17, 1)
    G.setColor(1, 1, 1)
    local zy = gap
    for _, nome in ipairs(ordem) do
        local sheet = sheets[nome]
        local img = to_drawable(sheet.albedo)
        if img then
            for fr = 1, math.min(sheet.frames, 4) do
                local q = G.newQuad((fr - 1) * sheet.w, 0, sheet.w, sheet.h,
                    img:getWidth(), img:getHeight())
                G.draw(img, q, gap + (fr - 1) * sheet.w * z, zy, 0, z, z)
            end
        end
        zy = zy + sheet.h * z + 4
    end
    G.setCanvas()
    local zf = assert(io.open('screenshots/ext_zoom.png', 'wb'))
    zf:write(zc:newImageData():encode('png'):getString())
    zf:close()

    print('bake ext ok: ' .. #ordem .. ' sprites -> ext_prancha.png')
    love.event.quit(0)
end
