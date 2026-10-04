-- Bake dos defs da frente MICRO-ANIMAÇÕES AMBIENTAIS: dump de
-- albedo/normal/emissive em screenshots/amb_<nome>_*.png e prancha
-- única screenshots/amb_prancha.png (uma linha por def: TODOS os frames
-- de albedo a 2x seguidos de TODOS os frames de emissive a 2x — ler o
-- loop é comparar os quadros lado a lado).
-- Roda da raiz: lovec tools/bake_amb

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_amb-erro.txt', 'w')
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

-- Defs tocados/novos nesta frente (o init.lua não foi alterado: os defs
-- novos entram por require direto).
local NOMES = {
    'braseiro', 'lampiao', 'arvore', 'varal_vento', 'poco', 'velas',
    'vela_votiva_anim', 'cisterna_rua', 'fumaca_chamine', 'marco',
}

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local G = love.graphics
    local sheets, caminhos = {}, {}
    for _, nome in ipairs(NOMES) do
        local okD, def = pcall(require, 'src.sprites.' .. nome)
        if not okD then die('require src.sprites.' .. nome
            .. ' falhou: ' .. tostring(def)) return end
        local okB, sheet = pcall(DSL.bake, def)
        if not okB then die('bake ' .. nome .. ' falhou: '
            .. tostring(sheet)) return end
        sheets[nome] = sheet
        DSL.dump(sheet, 'screenshots/amb_' .. nome)
        caminhos[#caminhos + 1] = 'amb_' .. nome
    end

    -- Prancha: por def, uma linha com todos os frames de albedo +
    -- todos os de emissive (o normal é derivado e polui a leitura do
    -- loop — fica fora), tudo a 2x.
    local escala, gap = 2, 8
    local largura, altura = gap, gap
    local rows = {}
    for _, nome in ipairs(NOMES) do
        local sheet = sheets[nome]
        local alb = to_drawable(sheet.albedo)
        local emi = to_drawable(sheet.emissive)
        local row, roww, rowh = {}, 0, 0
        for _, par in ipairs({{alb, 'a'}, {emi, 'e'}}) do
            local img = par[1]
            if img then
                for f = 1, sheet.frames do
                    local q = G.newQuad((f - 1) * sheet.w, 0,
                        sheet.w, sheet.h, img:getWidth(), img:getHeight())
                    row[#row + 1] = {img, q}
                    roww, rowh = roww + sheet.w * escala + gap,
                        sheet.h * escala
                end
            end
        end
        rows[#rows + 1] = {nome = nome, row = row, w = roww, h = rowh}
        largura = math.max(largura, roww + gap)
        altura = altura + rowh + gap
    end

    local canvas = G.newCanvas(largura, altura)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0.05, 0.05, 0.08, 1)
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
    local f = assert(io.open('screenshots/amb_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    print('bake_amb ok: ' .. #NOMES .. ' defs -> screenshots/amb_*')
    love.event.quit(0)
end
