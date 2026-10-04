-- Bake dos sprites de INTERIORES do Refúgio (Fase 2, nota vida-refugio-props
-- §7-11): require direto de cada def (não passa por src/sprites/init.lua),
-- dump de albedo/normal/emissive em screenshots/int_<nome>_*.png e prancha
-- única screenshots/int_prancha.png (linha por sprite: frames de albedo a
-- 2x + normal f1 + emissive f1).
-- Roda da raiz: lovec tools/bake_int
--
-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_int-erro.txt', 'w')
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

-- Lista explícita: a frente INTERIORES não entra no init.lua dos demais.
local NOMES = {
    'piso_tabua', 'parede_painel', 'parede_painel_janela',
    'fogao', 'mesa_longa', 'prateleira', 'tigela',
    'altar', 'banco_capela', 'velas', 'mesa_oferenda', 'quadro',
    'cama', 'divisoria', 'pertences', 'bau', 'brinquedo',
    'rack_ferramentas', 'peca_inacabada', 'serragem',
    'carteiras', 'caixas_antigas', 'quadro_aula',
}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local sprites = {}
    for _, nome in ipairs(NOMES) do
        local okr, def = pcall(require, 'src.sprites.' .. nome)
        if not okr then
            die('require src.sprites.' .. nome .. ' falhou: ' .. tostring(def))
            return
        end
        sprites[nome] = def
    end

    local G = love.graphics
    local sheets = {}
    for _, nome in ipairs(NOMES) do
        local okb, sheet = pcall(DSL.bake, sprites[nome])
        if not okb then
            die('bake de ' .. nome .. ' falhou: ' .. tostring(sheet))
            return
        end
        sheets[nome] = sheet
        local okd, err = pcall(DSL.dump, sheet, 'screenshots/int_' .. nome)
        if not okd then
            die('dump de ' .. nome .. ' falhou: ' .. tostring(err))
            return
        end
    end

    -- Prancha: por sprite, uma linha com os frames de albedo (máx 4) +
    -- normal e emissive do frame 1, tudo a 2x.
    local escala, gap = 2, 8
    local largura, altura = gap, gap
    local rows = {}
    for _, nome in ipairs(NOMES) do
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

    local f = assert(io.open('screenshots/int_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    print('bake_int ok: ' .. #NOMES .. ' sprites -> int_prancha.png')
    love.event.quit(0)
end
