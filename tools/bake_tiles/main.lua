-- Bake dos tiles/arquitetura DSL da Fase 1: require direto dos defs por
-- caminho (sem passar por src.sprites/init), dump de albedo/normal/emissive
-- em screenshots/tiles_<nome>_*.png e prancha única
-- screenshots/tiles_prancha.png (colunas = sprites, linhas = canais, 2x;
-- frames de tiles ficam lado a lado dentro da mesma célula).
-- Roda da raiz: lovec tools/bake_tiles
--
-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_tiles-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local ordem = {
    'piso_laje', 'piso_terra', 'piso_grama', 'piso_caminho',
    'parede_canto_e', 'parede_canto_d',
    'parede_janela', 'parede_porta',
    'pilar', 'marco',
}
local canais = { 'albedo', 'normal', 'emissive' }

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

local function canal(sheet, nome)
    if type(sheet) ~= 'table' then return nil end
    return to_drawable(sheet[nome]) or to_drawable(sheet[nome .. 'Data'])
end

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local G = love.graphics
    local sheets, caminhos = {}, {}
    for _, nome in ipairs(ordem) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        if not okd then die('require ' .. nome .. ' falhou: ' .. tostring(def)) return end
        local okb, sheet = pcall(DSL.bake, def)
        if not okb then die('bake ' .. nome .. ' falhou: ' .. tostring(sheet)) return end
        sheets[nome] = sheet
        local base = 'screenshots/tiles_' .. nome
        DSL.dump(sheet, base)
        caminhos[#caminhos + 1] = base
    end

    -- Prancha: coluna por sprite (largura = sheet inteira, frames lado a
    -- lado), linha por canal (albedo/normal/emissive), tudo a 2x.
    local escala, gap, rowh = 2, 8, 96
    local colw, x0 = {}, gap
    local totalw = gap
    for _, nome in ipairs(ordem) do
        local s = sheets[nome]
        colw[nome] = s.w * s.frames * escala
        totalw = totalw + colw[nome] + gap
    end
    local W = totalw
    local H = #canais * rowh * escala + (#canais + 1) * gap
    local canvas = G.newCanvas(W, H)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0.05, 0.05, 0.08, 1) -- fundo escuro opaco p/ ler silhueta/alpha
    G.setColor(1, 1, 1)
    local x = gap
    for _, nome in ipairs(ordem) do
        local sheet = sheets[nome]
        for c, canal_nome in ipairs(canais) do
            local img = canal(sheet, canal_nome)
            if img then
                G.draw(img, x, gap + (c - 1) * (rowh * escala + gap),
                    0, escala, escala)
            end
        end
        x = x + colw[nome] + gap
    end
    G.setCanvas()

    local f = assert(io.open('screenshots/tiles_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()
    caminhos[#caminhos + 1] = 'screenshots/tiles_prancha.png'

    print('bake ok: ' .. table.concat(caminhos, ', '))
    love.event.quit(0)
end
