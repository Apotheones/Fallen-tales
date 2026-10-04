function love.conf(t)
    t.identity = "arrowfallen"
    t.version = "11.5"
    t.window.title = "ARROWFALLEN • A Câmara dos Ecos"
    t.window.width, t.window.height = 1120, 800
    t.window.minwidth, t.window.minheight = 900, 680
    t.window.resizable = true
    t.window.vsync = 1
    t.modules.physics = false
    -- Runner headless (tools/run_headless): LÖVE exige uma janela real para o
    -- GL funcionar, entao testes e capturas rodam com ela fora da tela, sem
    -- borda e sem vsync — nada aparece nem pisca no desktop do usuario.
    -- Dispara pela env ARROWFALLEN_HEADLESS (o runner a define) ou por
    -- qualquer flag nao-interativa; `arg` ja existe dentro de love.conf.
    local headless = os.getenv("ARROWFALLEN_HEADLESS") ~= nil
    for _, a in ipairs(arg or {}) do
        if a == "--headless" or a == "--test" or a == "--ui-test"
            or a == "--showcase" or a == "--menuopt"
            or a:match("^%-%-screenshot=") or a:match("^%-%-scene=")
            or a:match("^%-%-pose=") or a:match("^%-%-region=")
            or a:match("^%-%-oframe=") or a:match("^%-%-capture%-after=") then
            headless = true
        end
    end
    if headless then
        t.window.borderless = true
        t.window.x, t.window.y = -32000, -32000
        t.window.vsync = 0
    end
end
