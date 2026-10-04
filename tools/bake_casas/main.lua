-- Bake das fachadas multi-tile casa_* (frente CASAS F4/F5): dump de
-- albedo/normal/emissive em screenshots/casa_<nome>_*.png e prancha
-- única screenshots/casas_prancha.png (uma linha por sprite: albedo +
-- normal + emissive lado a lado, 2x).
-- Roda da raiz: lovec tools/bake_casas
--
-- Os defs são requeridos direto em src.sprites.<nome> — casa_* ainda
-- não entra no init.lua.
local function die(msg)
    local f = io.open('screenshots/bake_casas-erro.txt', 'w')
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

    local nomes = {
        'casa_fachada_a', 'casa_fachada_b', 'casa_pensao', 'casa_telhado',
    }
    local G = love.graphics
    local sheets = {}
    for _, nome in ipairs(nomes) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        if not okd then die('require ' .. nome .. ' falhou: ' .. tostring(def)) return end
        local okb, sheet = pcall(DSL.bake, def)
        if not okb then die('bake ' .. nome .. ' falhou: ' .. tostring(sheet)) return end
        DSL.dump(sheet, 'screenshots/casa_' .. nome)
        sheets[#sheets + 1] = sheet
        local emi = sheet.imageData.emissive
        local np = 0
        for py = 0, emi:getHeight() - 1 do
            for px = 0, emi:getWidth() - 1 do
                local _, _, _, a = emi:getPixel(px, py)
                if a > 0 then np = np + 1 end
            end
        end
        print(nome .. ': emissivo ' .. np .. 'px')
        -- zoom 4x do albedo sobre fundo escuro, para revisão visual
        local alb = to_drawable(sheet.albedo)
        if alb then
            local z = G.newCanvas(sheet.w * 4, sheet.h * 4)
            z:setFilter('nearest', 'nearest')
            G.setCanvas(z)
            G.clear(0.16, 0.16, 0.20, 1)
            G.setColor(1, 1, 1)
            G.draw(alb, 0, 0, 0, 4, 4)
            G.setCanvas()
            local f = assert(io.open(
                'screenshots/casa_' .. nome .. '_zoom.png', 'wb'))
            f:write(z:newImageData():encode('png'):getString())
            f:close()
        end
    end

    -- Prancha: por sprite uma linha albedo | normal | emissive a 2x.
    local escala, gap = 2, 10
    local largura, altura = gap, gap
    for _, s in ipairs(sheets) do
        largura = math.max(largura, s.w * escala * 3 + gap * 4)
        altura = altura + s.h * escala + gap
    end
    local canvas = G.newCanvas(largura, altura)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0, 0, 0, 0)
    G.setColor(1, 1, 1)
    local y = gap
    for _, s in ipairs(sheets) do
        local x = gap
        for _, ch in ipairs({ 'albedo', 'normal', 'emissive' }) do
            local img = to_drawable(s[ch])
            if img then
                local q = G.newQuad(0, 0, s.w, s.h,
                    img:getWidth(), img:getHeight())
                G.draw(img, q, x, y, 0, escala, escala)
            end
            x = x + s.w * escala + gap
        end
        y = y + s.h * escala + gap
    end
    G.setCanvas()
    local f = assert(io.open('screenshots/casas_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    print('bake ok: ' .. #sheets .. ' fachadas -> screenshots/casas_prancha.png')
    love.event.quit(0)
end
