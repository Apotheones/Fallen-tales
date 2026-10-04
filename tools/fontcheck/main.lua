-- Prancha de fontes: face clássica (Font.new) x face HD (Font.newHD),
-- desenhadas a 2x sobre fundo escuro com guia de baseline. Verifica acentos
-- PT-BR, minúsculas reais, descendentes e espaçamento.
-- Uso, da raiz do projeto: lovec tools/fontcheck -> screenshots/font_hd.png
local Font

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/font-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local INK = { .06, .08, .11 }
local TEXT = { .93, .94, .90 }
local LABEL = { .55, .65, .70 }
local GUIDE = { .35, .20, .25 }
local ACCENT = { .85, .66, .30 }

-- Linhas da prancha: mesmas strings nas duas famílias para comparar.
local function bloco(f, base) -- f=fonte, base=fileira do baseline em px
    return {
        { t = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', f = f, base = base },
        { t = 'abcdefghijklmnopqrstuvwxyz', f = f, base = base },
        { t = '0123456789', f = f, base = base },
        { t = '! ? . , : ; - / + = | ( ) $ · – — % > < \' " [ ] & “ ” ‘ ’', f = f, base = base },
        { t = 'Á À Â Ã É Ê Í Ó Ô Õ Ú Ü Ç', f = f, base = base },
        { t = 'á à â ã é ê í ó ô õ ú ü ç', f = f, base = base },
        { t = 'A neblina cai sobre o Refúgio — ç, ã, õ, ê, à', f = f, base = base },
        { t = '“Só falta você,” disse Andlar. "Coração" não é mágoa.', f = f, base = base },
    }
end

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    package.path = package.path .. ';./?.lua;./?/init.lua'
    Font = require('src.pixel_font')

    local S = tonumber(arg and arg[#arg]) or 2 -- escala da prancha (arg opcional)
    local old = Font.new(S)
    local new = Font.newHD(S)
    assert(Font.new(S, { hd = true }):getHeight() == new:getHeight(),
        'Font.new(scale,{hd=true}) deve devolver a face HD')

    local margem, gap, rotulo = 12, 8, 26
    local blocos = {
        { nome = 'FONTE.CLASSICA  (Font.new)', f = old, base = 9 * S },
        { nome = 'FONTE.HD  (Font.newHD)', f = new, base = 10 * S },
    }
    -- mede a prancha
    local w, h = 0, margem
    for _, b in ipairs(blocos) do
        h = h + rotulo
        for _, l in ipairs(bloco(b.f, b.base)) do
            local lw = l.f:getWidth(Font.clean(l.t))
            if lw > w then w = lw end
            h = h + l.f:getHeight() + gap
        end
        h = h + rotulo
    end
    w = w + margem * 2 + 30
    h = h + margem

    local G = love.graphics
    local canvas = G.newCanvas(w, h)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas)
    G.clear(INK[1], INK[2], INK[3], 1)

    local y = margem
    for _, b in ipairs(blocos) do
        G.setFont(old); G.setColor(ACCENT)
        G.print(b.nome, margem, y); y = y + rotulo
        for _, l in ipairs(bloco(b.f, b.base)) do
            G.setFont(l.f); G.setColor(TEXT)
            local lh = l.f:getHeight()
            -- guia de baseline (fileira 10 HD / 9 clássica) e de descendentes
            G.setColor(GUIDE); G.rectangle('fill', margem, y + l.base - 1, w - margem * 2, 1)
            G.setColor(TEXT); G.print(Font.clean(l.t), margem + 20, y)
            y = y + lh + gap
        end
        G.setFont(old); G.setColor(LABEL)
        y = y + rotulo
    end
    G.setCanvas()

    local nome = S == 2 and 'font_hd' or ('font_hd_' .. S .. 'x')
    local f = assert(io.open('screenshots/' .. nome .. '.png', 'wb'))
    f:write(canvas:newImageData():encode('png'):getString())
    f:close()
    print(string.format('fontcheck ok: %dx%d -> screenshots/font_hd.png', w, h))
    love.event.quit(0)
end
