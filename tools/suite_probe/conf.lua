function love.conf(t)
    t.identity = "arrowfallen-probe"
    t.window.width, t.window.height = 1120, 800
    -- Probe nunca aparece na tela do usuario: janela real (GL precisa dela)
    -- mas posicionada fora da area visivel e sem borda.
    t.window.borderless = true
    t.window.x, t.window.y = -32000, -32000
    t.window.vsync = 0
end
