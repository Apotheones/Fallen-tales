-- kit_workbench é CLI: janela existe só para o GL funcionar (canvas/shader/
-- fonte), então fica fora da tela como o runner headless do conf.lua raiz.
-- Exceção: --play (playback interativo) pede janela real e visível.
function love.conf(t)
    local play = false
    for _, a in ipairs(arg or {}) do
        if a == '--play' then play = true end
    end
    t.identity = 'kit_workbench'
    t.version = '11.5'
    t.window.title = 'kit_workbench — playback'
    t.window.width, t.window.height = play and 720 or 64, play and 480 or 64
    t.window.borderless = not play
    if not play then
        t.window.x, t.window.y = -32000, -32000
    end
    t.window.vsync = play and 1 or 0
    t.modules.physics = false
end
