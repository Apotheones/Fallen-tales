-- Confere o mini-formato de sprite multi-canal (src/sprite_dsl.lua):
-- roda selfCheck com resolve stub e despeja um mini-bake em screenshots/.
-- Uso, da raiz do projeto: lovec tools/dslcheck
local DSL

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/dslcheck-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

function love.load()
    package.path = package.path .. ';./?.lua;./?/init.lua'
    DSL = require('src.sprite_dsl')
    assert(DSL.selfCheck(), 'selfCheck falhou')

    -- Mini-bake: laje com bossa central e brasa no meio.
    local def = {
        name = 'dslcheck_mini',
        legend = {
            s = { ramp = 'stone', step = 3 },
            f = { ramp = 'ember', step = 5, ei = 1 },
        },
        layers = { {
            name = 'laje',
            albedo = [[
                ssssssss
                ssssssss
                ssssssss
                sssfssss
                ssssssss
                ssssssss]],
            height = [[
                ........
                .3333...
                .3773...
                .3773...
                .3333...
                ........]],
            emissive = [[
                ........
                ........
                ........
                ...f....
                ........
                ........]],
        } },
    }
    local stub = function(spec)
        local ramp = spec:match('^(%w+)%.') or spec
        return ({ stone = { .35, .42, .5 }, ember = { 1, .5, .2 } })[ramp]
    end
    local sheet = DSL.bake(def, { resolve = stub })
    local paths = DSL.dump(sheet, 'screenshots/dslcheck-mini')
    print(string.format('dslcheck ok: %dx%d frames=%d origin=%s -> %s',
        sheet.w, sheet.h, sheet.frames, sheet.origin, paths.albedo))
    love.event.quit(0)
end

function love.draw() end
