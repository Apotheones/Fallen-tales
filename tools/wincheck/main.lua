function love.load()
    io.stdout:setvbuf('no')
    local G = love.graphics
    local c = G.newCanvas(64, 64)
    G.setCanvas(c); G.clear(1, 0, 0, 1); G.setCanvas()
    print('[wincheck] canvas px=' .. tostring(c:newImageData():getPixel(0, 0)))
    local ok, err = pcall(G.newShader, 'vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc){ return c; }')
    print('[wincheck] shader=' .. tostring(ok) .. ' ' .. tostring(err))
    print('[wincheck] visible=' .. tostring(love.window.isVisible()) ..
        ' pos=' .. tostring(select(1, love.window.getPosition())) .. ',' ..
        tostring(select(2, love.window.getPosition())) ..
        ' minimized=' .. tostring(love.window.isMinimized()))
    print('[wincheck] headless_env=' .. tostring(os.getenv('ARROWFALLEN_HEADLESS')))
    love.event.quit(0)
end
function love.draw()
    love.graphics.print('offscreen')
end
