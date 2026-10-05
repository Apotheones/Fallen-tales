-- mapshot — janela mínima fora da tela: o tool é CLI, o GL só precisa
-- existir (canvas/fonte). Mesmo padrão do kit_workbench.
function love.conf(t)
    t.identity = 'mapshot'
    t.version = '11.5'
    t.window.title = 'mapshot'
    t.window.width, t.window.height = 64, 64
    t.window.borderless = true
    t.window.x, t.window.y = -32000, -32000
    t.window.vsync = 0
    t.modules.physics = false
end
