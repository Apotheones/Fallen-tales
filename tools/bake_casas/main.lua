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

    ---------------- RUA_PREVIEW ----------------
    -- Rua de teste: piso_laje de fundo; fachada_a + fachada_b + pensao
    -- coladas lado a lado (emenda = cunhal duplo de divisa); casa_telhado
    -- cobrindo as duas primeiras. O beiral do telhado (verso 'R' nas
    -- linhas 54-56 da grade) alinha com a linha de beiral das fachadas
    -- (face começa em roofH=16): dy = 16 - 56 = -40. A borda de sombra
    -- que se desfaz cai então sobre o reboco real — é a validação que a
    -- frente anterior deixou aberta.
    local okp, pisoDef = pcall(require, 'src.sprites.piso_laje')
    if not okp then die('require piso_laje falhou: ' .. tostring(pisoDef)) return end
    local okpb, piso = pcall(DSL.bake, pisoDef)
    if not okpb then die('bake piso_laje falhou: ' .. tostring(piso)) return end

    local byName = {}
    for i, nome in ipairs(nomes) do byName[nome] = sheets[i] end
    local function drawSheet(s, x, y)
        local img = to_drawable(s.albedo)
        if not img then return end
        local q = G.newQuad(0, 0, s.w, s.h,
            img:getWidth(), img:getHeight())
        G.draw(img, q, x, y)
    end

    local RUA_W = 128 + 128 + 192
    local RUA_H = 96 + 56                     -- fachadas + faixa de rua
    local rua = G.newCanvas(RUA_W, RUA_H)
    rua:setFilter('nearest', 'nearest')
    G.setCanvas(rua)
    G.clear(0, 0, 0, 0)
    G.setColor(1, 1, 1)
    for yy = 0, RUA_H - 1, piso.h do
        for xx = 0, RUA_W - 1, piso.w do
            drawSheet(piso, xx, yy)
        end
    end
    local fila = {
        { s = byName.casa_fachada_a, x = 0 },
        { s = byName.casa_fachada_b, x = 128 },
        { s = byName.casa_pensao,    x = 256 },
    }
    for _, p in ipairs(fila) do drawSheet(p.s, p.x, 0) end
    -- telhado corrido sobre a e b: verga de borda cai na divisa a|b
    local tel = byName.casa_telhado
    for _, tx in ipairs({ 0, 128 }) do drawSheet(tel, tx, -40) end
    -- emissivo das janelas acesas por cima, como o lighting comporia
    G.setBlendMode('add')
    for _, p in ipairs(fila) do
        local emi = to_drawable(p.s.emissive)
        if emi then
            local q = G.newQuad(0, 0, p.s.w, p.s.h,
                emi:getWidth(), emi:getHeight())
            G.draw(emi, q, p.x, 0)
        end
    end
    G.setBlendMode('alpha')
    G.setCanvas()
    local zx = G.newCanvas(RUA_W * 2, RUA_H * 2)
    zx:setFilter('nearest', 'nearest')
    G.setCanvas(zx)
    G.clear(0, 0, 0, 0)
    G.setColor(1, 1, 1)
    G.draw(rua, 0, 0, 0, 2, 2)
    G.setCanvas()
    local fr = assert(io.open('screenshots/casas_rua.png', 'wb'))
    fr:write(zx:newImageData():encode('png'):getString())
    fr:close()

    -- Recortes 4x para inspeção: emenda entre prédios e linha de beiral
    -- com a sombra que se desfaz sobre o reboco.
    local function recorte(cx, cy, cw, ch, z, path)
        local c = G.newCanvas(cw * z, ch * z)
        c:setFilter('nearest', 'nearest')
        G.setCanvas(c)
        G.clear(0, 0, 0, 0)
        G.setColor(1, 1, 1)
        local q = G.newQuad(cx, cy, cw, ch, rua:getWidth(), rua:getHeight())
        G.draw(rua, q, 0, 0, 0, z, z)
        G.setCanvas()
        local fc = assert(io.open(path, 'wb'))
        fc:write(c:newImageData():encode('png'):getString())
        fc:close()
    end
    recorte(88, 0, 80, 96, 4, 'screenshots/casas_rua_emenda.png')
    recorte(216, 0, 100, 42, 4, 'screenshots/casas_rua_beiral.png')

    print('bake ok: ' .. #sheets .. ' fachadas -> screenshots/casas_prancha.png')
    print('rua_preview -> screenshots/casas_rua.png (' ..
        RUA_W .. 'x' .. RUA_H .. ' @2x)')
    love.event.quit(0)
end
