-- Bake dos NPCs da Fase 3 (elenco): npc_{aurel,sabela,bento,teca,nilo}
-- nas quatro direções + viajante/npc_doro como referência de escala.
-- Dump 'screenshots/npc_<nome>_<dir>_{albedo,normal,emissive}.png' e
-- prancha 'screenshots/npc_prancha.png' (uma linha por def: frames de
-- albedo a 2x + normal f1 + emissive f1).
-- Roda da raiz: lovec tools/bake_npc

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_npc-erro.txt', 'w')
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

    -- ordem da prancha: referência primeiro, depois os cinco NPCs.
    local nomes = {
        'viajante', 'viajante_n', 'viajante_e',
        'npc_doro_s', 'npc_doro_n', 'npc_doro_e',
    }
    for _, n in ipairs({ 'aurel', 'sabela', 'bento', 'teca', 'nilo' }) do
        for _, d in ipairs({ 's', 'n', 'e', 'w' }) do
            nomes[#nomes + 1] = 'npc_' .. n .. '_' .. d
        end
    end

    local G = love.graphics
    local sheets = {}
    for _, nome in ipairs(nomes) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        if not okd then
            die('require ' .. nome .. ' falhou: ' .. tostring(def))
            return
        end
        local okb, sheet = pcall(DSL.bake, def)
        if not okb then
            die('bake ' .. nome .. ' falhou: ' .. tostring(sheet))
            return
        end
        sheets[nome] = sheet
        if nome:match('^npc_') then
            local okp, err = pcall(DSL.dump, sheet,
                'screenshots/' .. nome)
            if not okp then
                die('dump ' .. nome .. ': ' .. tostring(err))
                return
            end
        end
    end

    -- Prancha única: linha por def, frames de albedo + normal f1 +
    -- emissive f1, tudo a 2x.
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
                roww, rowh = roww + sheet.w * escala + gap,
                    sheet.h * escala
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
            G.draw(cell[1], cell[2], x, y + r.h - qh * escala, 0,
                escala, escala)
            x = x + qw * escala + gap
        end
        y = y + r.h + gap
    end
    G.setCanvas()

    local f = assert(io.open('screenshots/npc_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    print('bake npc ok: ' .. #nomes .. ' defs')
    love.event.quit(0)
end
