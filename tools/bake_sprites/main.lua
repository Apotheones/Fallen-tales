-- Bake dos sprites DSL: para cada def em src.sprites, gera os dumps de
-- albedo/normal/emissive em screenshots/sprite_<nome>_*.png e uma prancha
-- única screenshots/sprites_prancha.png (linha por sprite, 2x).
-- Roda da raiz: lovec tools/bake_sprites

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_sprites-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local ordem = {'viajante', 'braseiro', 'parede'}
local canais = {'albedo', 'normal', 'emissive'}

-- Aceita ImageData, Image ou Canvas: cobre o que o sheet devolver.
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

    -- Se o DSL ainda não existe, reporta e sai (não é bug da ferramenta).
    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end
    local ok2, sprites = pcall(require, 'src.sprites')
    if not ok2 then die('require src.sprites falhou: ' .. tostring(sprites)) return end

    local G = love.graphics
    local sheets, caminhos = {}, {}
    for _, nome in ipairs(ordem) do
        local def = sprites[nome]
        if not def then die('sprite ausente em src.sprites: ' .. nome) return end
        local sheet = DSL.bake(def)
        sheets[nome] = sheet
        local base = 'screenshots/sprite_' .. nome
        DSL.dump(sheet, base)
        caminhos[#caminhos + 1] = base
    end

    -- Prancha: uma linha por sprite, colunas albedo|normal|emissive a 2x.
    local escala, pw, ph, gap = 2, 64, 96, 8
    local canvas = G.newCanvas(3 * pw * escala + 4 * gap,
        #ordem * ph * escala + (#ordem + 1) * gap)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0, 0, 0, 0)
    G.setColor(1, 1, 1)
    for i, nome in ipairs(ordem) do
        local sheet = sheets[nome]
        local y = gap + (i - 1) * (ph * escala + gap)
        for c, canal_nome in ipairs(canais) do
            local img = canal(sheet, canal_nome)
            if img then
                G.draw(img, gap + (c - 1) * (pw * escala + gap), y,
                    0, escala, escala)
            end
        end
    end
    G.setCanvas()

    local f = assert(io.open('screenshots/sprites_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()
    caminhos[#caminhos + 1] = 'screenshots/sprites_prancha.png'

    print('bake ok: ' .. table.concat(caminhos, ', '))
    love.event.quit(0)
end
