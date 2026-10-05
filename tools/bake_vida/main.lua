-- Bake das cenas de vida (frente CENAS DE VIDA): cabra, jardineiro nas
-- 4 direções + loop de trabalho, varanda ocupada e a figura sentada do
-- banco de contemplação. Dump 'screenshots/vida_<nome>_{albedo,normal,
-- emissive}.png' e prancha 'screenshots/vida_prancha.png' (uma linha
-- por def: frames de albedo a 3x + normal f1 + emissive f1).
-- Roda da raiz: lovec tools/bake_vida
--
-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local ERRO = 'screenshots/bake_vida-erro.txt'
local function die(msg)
    local f = io.open(ERRO, 'w')
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
    os.remove(ERRO)  -- arquivo de erro é sempre desta execução

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local nomes = {
        'cabra',
        'npc_jardineiro_s', 'npc_jardineiro_n',
        'npc_jardineiro_e', 'npc_jardineiro_w',
        'npc_jardineiro_trabalho',
        'varanda_ocupada',
        'sit_contemplacao',
        -- referências de escala na mesma prancha
        'npc_doro_s', 'espantalho', 'banco_terraco',
    }

    -- Dump ASCII da luminância do albedo, um frame por vez — revisão
    -- por texto quando o PNG não pode ser aberto na hora.
    local RAMP = ' .:-=+*#%@'
    local function ascii(sheet, nome)
        local id = sheet.imageData.albedo
        local out = { ('=== %s (%dx%d, %df)'):format(nome, sheet.w,
            sheet.h, sheet.frames) }
        for f = 0, sheet.frames - 1 do
            out[#out + 1] = '-- f' .. (f + 1)
            for y = 0, sheet.h - 1 do
                local row = {}
                for x = 0, sheet.w - 1 do
                    local r, g, b, a = id:getPixel(f * sheet.w + x, y)
                    local lum = a * (r + g + b) / 3
                    row[#row + 1] = RAMP:sub(
                        math.min(#RAMP, math.floor(lum * (#RAMP - 1) + 1.5)),
                        math.min(#RAMP, math.floor(lum * (#RAMP - 1) + 1.5)))
                end
                out[#out + 1] = table.concat(row)
            end
        end
        local f = assert(io.open(
            'screenshots/vida_' .. nome .. '_ascii.txt', 'w'))
        f:write(table.concat(out, '\n'))
        f:close()
    end

    local G = love.graphics
    local sheets, validos, falhas = {}, {}, {}
    for _, nome in ipairs(nomes) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        if not okd then
            falhas[#falhas + 1] = 'require ' .. nome .. ': ' .. tostring(def)
        else
            local okb, sheet = pcall(DSL.bake, def)
            if not okb then
                falhas[#falhas + 1] = 'bake ' .. nome .. ': ' .. tostring(sheet)
            else
                sheets[nome] = sheet
                validos[#validos + 1] = nome
                local okp, err = pcall(DSL.dump, sheet,
                    'screenshots/vida_' .. nome)
                if not okp then
                    falhas[#falhas + 1] = 'dump ' .. nome .. ': '
                        .. tostring(err)
                end
                ascii(sheet, nome)
            end
        end
    end

    -- Prancha única: linha por def, frames de albedo + normal f1 +
    -- emissive f1, tudo a 3x (a cabra de 48px cabe junto das outras).
    local escala, gap = 3, 8
    local largura, altura = gap, gap
    local rows = {}
    for _, nome in ipairs(validos) do
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

    local f = assert(io.open('screenshots/vida_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    if #falhas > 0 then
        local fe = io.open(ERRO, 'w')
        if fe then
            fe:write(#falhas .. ' def(s) com falha — linha(s) ausente(s)'
                .. ' na prancha:\n')
            for _, m in ipairs(falhas) do fe:write(m .. '\n\n') end
            fe:close()
        end
    end

    print('bake vida ok: ' .. #validos .. ' defs'
        .. (#falhas > 0 and (' (' .. #falhas .. ' falhas, ver '
            .. ERRO .. ')') or ''))
    love.event.quit(0)
end
