-- Prancha standalone do lote Fibra (figurantes + inimigos): renderiza os
-- painters candidatos de tools/fibra/lote.lua numa matriz 3x igual à
-- prancha do jogo, sem tocar nos arquivos que o Traço escreve.
-- Uso (da raiz do projeto):
--   "C:\Program Files\LOVE\lovec.exe" tools/fibra figurantes
--   "C:\Program Files\LOVE\lovec.exe" tools/fibra inimigos
--   "C:\Program Files\LOVE\lovec.exe" tools/fibra (tudo)

local grupo = 'all'
for _, a in ipairs(arg or {}) do
    if a == 'figurantes' or a == 'inimigos' or a == 'refugio' then grupo = a end
end

dofile('tools/fibra/base.lua')
local lote = dofile('tools/fibra/lote.lua')

-- Despachante residente do lote: espelha resident() de pixel_actors.lua —
-- act 'sit' sai cedo p/ o sentado, bob por ofício, corpo por pal.body,
-- 'work' chama workArms depois do corpo.
local function residentDraw(data, ox, oy, direction, action, frame, pal)
    local r, l, p, d = painter(data, ox, oy)
    local east, south, west, north = direction == 1, direction == 2,
        direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local v = pal.body or 'plain'
    local cx = 16
    if action == 'work' and pal.act == 'sit' then
        lote.seatedResident(r, l, p, cx, direction, pal, frame)
        return
    end
    local bob = action == 'work' and workBob(pal.act, frame) or ({0, -1, 0, 0})[frame]
    local C = {r = r, l = l, p = p, d = d, cx = cx, side = side, south = south,
        north = north, east = east, west = west, pal = pal, act = action, fr = frame,
        skin = pal.skin or P.goldLight, skinHi = mixc(pal.skin or P.goldLight, .3, P.white),
        skinLo = mixc(pal.skin or P.goldLight, .35),
        hair = pal.hair or P.stoneDark, hairHi = mixc(pal.hair or P.stoneDark, .3, P.white),
        hairLo = mixc(pal.hair or P.stoneDark, .5),
        cloth = pal.cloth or P.stone, clothHi = mixc(pal.cloth or P.stone, .22, P.white),
        clothLo = mixc(pal.cloth or P.stone, .42),
        accent = pal.accent or P.gold, eye = pal.eye or P.jadeLight}
    local body = lote.bodies[v]
    C.top = lote.tops[v] + bob
    body(C)
    if action == 'work' then workArms(r, l, p, cx, C.top, side, south, pal, frame) end
end

local grupos = {
    refugio = {'npc_anciao', 'npc_lavadeira', 'npc_carregador',
        'npc_lenhador', 'npc_crianca'},
    figurantes = {'npc_anciao', 'npc_lavadeira', 'npc_carregador',
        'npc_lenhador', 'npc_crianca', 'npc_traba', 'npc_trabb',
        'npc_guarda', 'npc_feirante', 'npc_voz', 'npc_equipe',
        'npc_ajudante', 'npc_plateia'},
    inimigos = {'dasher', 'breaker', 'demolisher', 'warden', 'ranger',
        'sower', 'watcher', 'veteran', 'regent', 'crawler', 'husk',
        'huskCocoon'},
}
local kinds = {}
if grupos[grupo] then kinds = grupos[grupo]
else
    for _, g in ipairs({'refugio', 'figurantes', 'inimigos'}) do
        for _, k in ipairs(grupos[g]) do kinds[#kinds + 1] = k end
    end
end

local function painterOf(kind)
    if kind:sub(1, 4) == 'npc_' then
        local pal = lote.residents[kind]
        return pal and function(d, ox, oy, dir, act, fr)
            residentDraw(d, ox, oy, dir, act, fr, pal)
        end
    end
    local sk = lote.sentinelSkins and lote.sentinelSkins[kind]
    if sk then return function(d, ox, oy, dir, act, fr)
        lote.sentinel(d, ox, oy, dir, act, fr, sk)
    end end
    local cfg = lote.zealotSkins and lote.zealotSkins[kind]
    if cfg then return function(d, ox, oy, dir, act, fr)
        lote.zealot(d, ox, oy, dir, act, fr, cfg)
    end end
    return lote.enemies[kind]
end

local scale, rowH, labelW, colW = 3, 176, 132, 40 * 3 + 8
-- colunas: 4 idle dirs + work/warn f1 + work/warn f3 + move f1 + retrato
local canvas = love.graphics.newCanvas(labelW + 7 * colW + 120,
    #kinds * rowH + 30)
canvas:setFilter('nearest', 'nearest')

function love.load()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(.804, .835, .855)   -- Pal.moon.disc
    for i, kind in ipairs(kinds) do
        local paint = painterOf(kind)
        local y, feetY = 16 + (i - 1) * rowH, 16 + (i - 1) * rowH + 150
        love.graphics.setColor(P.ink)
        love.graphics.print(kind:gsub('^npc_', ''):upper(), 10, y + 62)
        if paint then
            local cols = {{'idle', 1, 1}, {'idle', 1, 2}, {'idle', 1, 3},
                {'idle', 1, 4}, {'work', 1, 2}, {'work', 3, 2},
                {'warn', 1, 2}}
            for ci, spec in ipairs(cols) do
                io.write(kind, ' ', spec[1], '/', ci, '\n'); io.flush()
                local act, fr, dir = spec[1], spec[2], spec[3]
                if kind:sub(1, 4) ~= 'npc_' and act == 'work' then
                    act = 'warn'  -- inimigos não têm linha 'work'
                end
                local data = love.image.newImageData(frameW, frameH)
                paint(data, 0, 0, dir, act, fr)
                local img = love.graphics.newImage(data)
                img:setFilter('nearest', 'nearest')
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(img, labelW + (ci - 1) * colW + 62,
                    feetY, 0, scale, scale, 20, 44)
            end
            -- Retrato (só figurantes): busto + adorno + faceDraw,
            -- réplica do residentEmote.
            if kind:sub(1, 4) == 'npc_' then
                local pal = lote.residents[kind]
                local data = love.image.newImageData(frameW, frameH)
                local r, l, p = painter(data, 0, 0)
                local cx = 20
                local cloth, hair = pal.cloth or P.stone,
                    pal.hair or P.stoneDark
                local accent = pal.accent or P.gold
                local skin = pal.skin or P.goldLight
                local skinHi = mixc(skin, .3, P.white)
                local skinLo = mixc(skin, .35)
                local clothHi = mixc(cloth, .25, P.white)
                r(cx - 4, 28, 8, 8, P.ink); r(cx - 3, 28, 6, 7, skin)
                r(cx - 3, 33, 6, 1, skinLo)
                p({cx - 14, 47, cx - 9, 34, cx + 9, 34, cx + 14, 47}, P.ink)
                p({cx - 13, 47, cx - 8, 35, cx + 8, 35, cx + 13, 47}, cloth)
                l(cx - 8, 35, cx - 12, 45, clothHi)
                if not lote.emoteAdorno(r, l, p, cx, pal.body, pal, cloth,
                    hair, accent, skin, skinHi) then
                    r(cx - 8, 3, 16, 5, hair)
                end
                faceDraw(r, l, cx - 8, 7, 16, 25, pal.eye or P.jadeLight,
                    pal.rest or 'neutral', skin, skinHi,
                    {skinLo = skinLo, hair = hair,
                        bare = pal.body == 'stocky'})
                if pal.beard then
                    r(cx - 9, 24, 3, 9, pal.beard)
                    r(cx + 7, 24, 3, 9, pal.beard)
                    r(cx - 5, 33, 10, 3, pal.beard)
                end
                if pal.headWrap then
                    r(cx - 9, 3, 18, 4, pal.headWrap)
                    r(cx - 10, 5, 3, 6, pal.headWrap)
                end
                local img = love.graphics.newImage(data)
                img:setFilter('nearest', 'nearest')
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(img, labelW + 7 * colW + 30, feetY,
                    0, scale, scale, 20, 44)
            end
        end
    end
    love.graphics.setCanvas()
    local path = 'screenshots/fibra-' .. grupo .. '.png'
    local f = assert(io.open(path, 'wb'))
    f:write(canvas:newImageData():encode('png'):getString()); f:close()
    print('fibra prancha: ' .. path)
    love.event.quit(0)
end

function love.draw() end
