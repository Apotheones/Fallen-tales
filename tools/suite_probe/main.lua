-- tools/suite_probe — roda módulos de teste isolados sem a suíte inteira.
-- Uso: lovec tools/suite_probe tests.battle tests.pixel ...
-- Sai 0 se tudo passou, 1 no primeiro erro (com traceback).
package.path = package.path .. ';../../?.lua;../../?/init.lua'
require('src.game'); require('src.input'); require('src.campaign')
require('src.campaign_lore'); require('src.save'); require('src.sfx')
require('src.items')
local arg = arg or love.argv or {}
local mods = {}
for _, a in ipairs(arg) do
    if a:match('^tests%.') or a:match('^src%.') then mods[#mods + 1] = a end
end
if #mods == 0 then mods = {
    'tests.floor', 'tests.terrain', 'tests.enemies', 'tests.combat',
    'tests.dialogue', 'tests.shop', 'tests.explore3',
    'tests.explore_campaign', 'tests.refugio', 'tests.repro',
    'tests.battle', 'tests.pixel',
} end
function love.load()
    io.stdout:setvbuf('no')
    local ok, err = xpcall(function()
        for _, m in ipairs(mods) do
            io.stdout:write('[probe] ' .. m .. ' ...\n')
            local mod = require(m)
            if mod.run then mod.run()
            elseif mod.selfCheck then mod.selfCheck() end
            io.stdout:write('[probe] ' .. m .. ' OK\n')
        end
    end, debug.traceback)
    print(ok and '[probe] ALL OK' or err)
    love.event.quit(ok and 0 or 1)
end
function love.draw() end

-- Sem tela azul de erro: qualquer erro fora do xpcall imprime e morre,
-- em vez de pendurar numa janela de erro esperando input.
function love.errorhandler(msg)
    io.stderr:write(debug.traceback(tostring(msg), 2) .. '\n')
    io.stderr:flush()
    os.exit(1)
end
