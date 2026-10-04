package.path = package.path .. ';../../?.lua;../../?/init.lua'
require('src.game'); require('src.input'); require('src.campaign')
require('src.campaign_lore'); require('src.save'); require('src.sfx')
require('src.items')

-- Sequential suite runner: each module gets a progress marker so a hang or a
-- failure points at the culprit file instead of a silent window freeze.
-- Usage: lovec . [modulo ...]   (sem args = suite completa do --test)
local ORDER = {
    'tests.floor', 'tests.terrain', 'tests.enemies', 'tests.combat',
    'tests.dialogue', 'tests.shop', 'tests.explore3',
    'tests.explore_campaign', 'tests.refugio', 'tests.repro',
    'tests.battle', 'tests.pixel',
}

function love.load(args)
    io.stdout:setvbuf('no')
    local mods = {}
    for _, a in ipairs(args or {}) do
        mods[#mods + 1] = a:match('^tests%.') and a or ('tests.' .. a)
    end
    if #mods == 0 then mods = ORDER end

    local failed
    for _, m in ipairs(mods) do
        io.write('[probe] >>> ' .. m .. '\n')
        local ok, err = xpcall(function() require(m).run() end, debug.traceback)
        if ok then
            io.write('[probe] <<< ' .. m .. ' OK\n')
        else
            io.write('[probe] XXX ' .. m .. ' FAIL\n' .. tostring(err) .. '\n')
            failed = m
            break
        end
    end
    print(failed and ('[probe] FAILED AT ' .. failed) or '[probe] ALL OK')
    love.event.quit(failed and 1 or 0)
end
function love.draw() end

-- Sem tela azul de erro: qualquer erro fora do xpcall imprime e morre,
-- em vez de pendurar numa janela de erro esperando input.
function love.errorhandler(msg)
    io.stderr:write(debug.traceback(tostring(msg), 2) .. '\n')
    io.stderr:flush()
    os.exit(1)
end
