-- Bake dos sprites de ATORES (Fase 1, MEGAPLAN_VISUAL_HD.md §5-Fase3):
-- cada def em src/sprites/{viajante*,npc_doro*}.lua gera dumps
-- screenshots/atores_<nome>_{albedo,normal,emissive}.png e uma prancha
-- única screenshots/atores_prancha.png — uma linha por def: albedo com
-- TODOS os frames lado a lado a 2x + coluna normal + coluna emissive
-- (ambas do frame 1).
-- Roda da raiz: lovec tools/bake_atores
--
-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/bake_atores-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local ordem = {
    'viajante', 'viajante_n', 'viajante_e', 'viajante_w',
    'viajante_walk_s', 'viajante_walk_n', 'viajante_walk_e', 'viajante_walk_w',
    'npc_doro_s', 'npc_doro_n', 'npc_doro_e', 'npc_doro_w',
}
local ESC, GAP = 2, 8

local function to_image(v)
    if type(v) ~= 'userdata' then return nil end
    local ok, is = pcall(function() return v:typeOf('Image') end)
    if ok and is then return v end
    local ok2, isd = pcall(function() return v:typeOf('ImageData') end)
    if ok2 and isd then return love.graphics.newImage(v) end
    return nil
end

-- Frame 1 de um canal do sheet como Image (crop via ImageData:paste).
local function frame1(sheet, canal)
    local src = sheet.imageData and sheet.imageData[canal]
    if not src then return nil end
    local id = love.image.newImageData(sheet.w, sheet.h)
    id:paste(src, 0, 0, 0, 0, sheet.w, sheet.h)
    local img = love.graphics.newImage(id)
    img:setFilter('nearest', 'nearest')
    return img
end

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'

    local ok, DSL = pcall(require, 'src.sprite_dsl')
    if not ok then die('require src.sprite_dsl falhou: ' .. tostring(DSL)) return end

    local G = love.graphics
    local sheets, faltando = {}, {}
    for _, nome in ipairs(ordem) do
        local okr, def = pcall(require, 'src.sprites.' .. nome)
        if not okr or type(def) ~= 'table' then
            faltando[#faltando + 1] = nome
        else
            local okb, sheet = pcall(DSL.bake, def)
            if not okb then die('bake ' .. nome .. ': ' .. tostring(sheet)) return end
            sheets[nome] = sheet
            DSL.dump(sheet, 'screenshots/atores_' .. nome)
        end
    end

    -- Prancha: linha por def = albedo(N frames, 2x) | normal f1 | emissive f1.
    local largura = 0
    for _, nome in ipairs(ordem) do
        local s = sheets[nome]
        if s then
            local w = (s.frames + 2) * s.w * ESC + 4 * GAP
            if w > largura then largura = w end
        end
    end
    local altura = GAP
    for _, nome in ipairs(ordem) do
        local s = sheets[nome]
        if s then altura = altura + s.h * ESC + GAP end
    end
    local canvas = G.newCanvas(largura, altura)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(0.08, 0.08, 0.10, 1)
    G.setColor(1, 1, 1)

    local y = GAP
    for _, nome in ipairs(ordem) do
        local s = sheets[nome]
        if s then
            local alb = to_image(s.albedo) or to_image(s.imageData and s.imageData.albedo)
            if alb then G.draw(alb, GAP, y, 0, ESC, ESC) end
            local x2 = GAP + s.frames * s.w * ESC + GAP
            for i, canal in ipairs({ 'normal', 'emissive' }) do
                local img = frame1(s, canal)
                if img then
                    G.draw(img, x2 + (i - 1) * (s.w * ESC + GAP), y,
                        0, ESC, ESC)
                end
            end
            y = y + s.h * ESC + GAP
        end
    end
    G.setCanvas()

    local f = assert(io.open('screenshots/atores_prancha.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()

    -- Zoom de revisão: frame 1 do albedo a 4x por def + strip do walk a 2x.
    local Z = 4
    for _, nome in ipairs(ordem) do
        local s = sheets[nome]
        if s then
            local alb = frame1(s, 'albedo')
            if alb then
                local zc = G.newCanvas(s.w * Z, s.h * Z)
                zc:setFilter('nearest', 'nearest')
                G.setCanvas(zc)
                G.clear(0.08, 0.08, 0.10, 1)
                G.setColor(1, 1, 1)
                G.draw(alb, 0, 0, 0, Z, Z)
                G.setCanvas()
                local zf = assert(io.open(
                    'screenshots/atores_' .. nome .. '_4x.png', 'wb'))
                zf:write(zc:newImageData():encode('png'):getString())
                zf:close()
            end
        end
    end

    print('bake ok; faltando: ' .. (#faltando > 0
        and table.concat(faltando, ', ') or 'nenhum'))
    love.event.quit(0)
end
