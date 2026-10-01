function love.conf(t)
    t.identity = "arrowfallen"
    t.version = "11.5"
    t.window.title = "ARROWFALLEN • A Câmara dos Ecos"
    t.window.width, t.window.height = 1120, 800
    t.window.minwidth, t.window.minheight = 900, 680
    t.window.resizable = true
    t.window.vsync = 1
    t.modules.physics = false
end
