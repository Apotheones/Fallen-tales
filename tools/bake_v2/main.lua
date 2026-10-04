-- Bake dos defs tocados na iteração v2 + kit COLINA (Fase 2): require
-- direto por caminho (sem passar por src.sprites/init), dump de
-- albedo/normal/emissive em screenshots/v2_<nome>_*.png e prancha única
-- screenshots/v2_prancha.png — colunas = sprites, linhas = albedo|
-- normal|emissive, escala 2x, sprites alinhados pelo pé. Prancha de
-- inspeção a 4x sobre fundo frio escuro em screenshots/v2_zoom.png.
-- Roda da raiz: lovec tools/bake_v2
--
-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_v2-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local ordem = {
    -- iterações v2
    'piso_terra', 'piso_caminho', 'piso_laje',
    'arvore', 'bancada', 'poco',
    -- kit COLINA
    'piso_colina',
    'lapide_a', 'lapide_b', 'lapide_c',
    'vela_votiva', 'cova', 'cipo', 'muro_colina',
}
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

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local G = love.graphics
    local sheets, caminhos = {}, {}
    local maxh = 0
    for _, nome in ipairs(ordem) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        if not okd then die('require ' .. nome .. ' falhou: ' .. tostring(def)) return end
        local okb, sheet = pcall(DSL.bake, def)
        if not okb then die('bake ' .. nome .. ' falhou: ' .. tostring(sheet)) return end
        sheets[nome] = sheet
        if sheet.h > maxh then maxh = sheet.h end
        local base = 'screenshots/v2_' .. nome
        DSL.dump(sheet, base)
        caminhos[#caminhos + 1] = base
    end

    -- Prancha: coluna por sprite (largura do sheet, frames incluídos),
    -- linha por canal, 2x, pés alinhados.
    local escala, gap = 2, 8
    local cellh = maxh * escala
    local larg = gap
    for _, nome in ipairs(ordem) do
        larg = larg + sheets[nome].w * sheets[nome].frames * escala + gap
    end
    local canvas = G.newCanvas(larg, #canais * (cellh + gap) + gap)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0.05, 0.05, 0.08, 1) -- fundo frio escuro p/ ler silhueta
    G.setColor(1, 1, 1)
    local x = gap
    for _, nome in ipairs(ordem) do
        local sheet = sheets[nome]
        for c, canal_nome in ipairs(canais) do
            local img = canal(sheet, canal_nome)
            if img then
                local y = gap + (c - 1) * (cellh + gap)
                    + (cellh - sheet.h * escala) -- alinha pelo pé
                G.draw(img, x, y, 0, escala, escala)
            end
        end
        x = x + sheet.w * sheet.frames * escala + gap
    end
    G.setCanvas()

    local f = assert(io.open('screenshots/v2_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()
    caminhos[#caminhos + 1] = 'screenshots/v2_prancha.png'

    -- Prancha de inspeção: albedo a 4x sobre fundo frio, pés alinhados —
    -- para julgar leitura de perto (a colina não tem luz quente).
    local z = 4
    local zh = maxh * z
    local zl = gap
    for _, nome in ipairs(ordem) do
        zl = zl + sheets[nome].w * sheets[nome].frames * z + gap
    end
    local zc = G.newCanvas(zl, zh + 2 * gap)
    zc:setFilter('nearest', 'nearest')
    G.setCanvas(zc)
    G.clear(0.10, 0.09, 0.14, 1) -- ardósia violeta escura
    G.setColor(1, 1, 1)
    local zx = gap
    for _, nome in ipairs(ordem) do
        local sheet = sheets[nome]
        local img = canal(sheet, 'albedo')
        if img then
            G.draw(img, zx, gap + zh - sheet.h * z, 0, z, z)
        end
        zx = zx + sheet.w * sheet.frames * z + gap
    end
    G.setCanvas()
    local zf = assert(io.open('screenshots/v2_zoom.png', 'wb'))
    zf:write(zc:newImageData():encode('png'):getString())
    zf:close()
    caminhos[#caminhos + 1] = 'screenshots/v2_zoom.png'

    print('bake v2 ok: ' .. table.concat(caminhos, ', '))
    love.event.quit(0)
end
