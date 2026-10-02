local Render = require('src.render')
local Actors = require('src.pixel_actors')
local Pixel = {}

function Pixel.run()
    local checks = 0
    local function check(value, message) checks = checks + 1; assert(value, message) end
    local room = {w = 31, h = 23}
    for _, size in ipairs({{900, 680, 2}, {1120, 800, 2}, {1920, 1080, 2}}) do
        local width, height, scale = unpack(size)
        local v = Render.layout(width, height, room, 496, 368)
        check(v.scale == scale and v.w % 1 == 0 and v.h % 1 == 0, 'Integer pixel viewport at ' .. width)
        check(v.x % 1 == 0 and v.y % 1 == 0 and v.left % 1 == 0 and v.top % 1 == 0,
            'Viewport and camera origins stay on pixels')
        check(v.x >= 0 and v.y >= 0 and v.x + v.w * scale <= width and v.y + v.h * scale <= height,
            'Canvas fits the available window')
        check(math.abs(496 - v.left - v.w / 2) <= 1 and math.abs(368 - v.top - v.h / 2) <= 1,
            'Camera immediately centers the feet')
        local near = Render.layout(width, height, room, 16, 16)
        local far = Render.layout(width, height, room, room.w * 32 - 16, room.h * 32 - 16)
        check(near.left == 0 and near.top == 0 and far.left == room.w * 32 - far.w
            and far.top == room.h * 32 - far.h, 'Camera stops at all room edges')
        local tiny = {w = 3, h = 2}
        local a, b = Render.layout(width, height, tiny, 16, 16), Render.layout(width, height, tiny, 80, 48)
        check(a.left == b.left and a.top == b.top and a.left == math.floor((96 - a.w) / 2)
            and a.top == math.floor((64 - a.h) / 2), 'Small rooms remain centered without inverted limits')
    end
    local fullMap = Render.layout(1120,800,room,496,368,216)
    check(fullMap.y>=216 and fullMap.y+fullMap.h*fullMap.scale<=720, 'Viewport reserves space for the largest minimap without covering hazards')
    local actor = {grid = {x = 4, y = 3}, motion = {fromX = 3, fromY = 3, duration = .16, remaining = .08}}
    local x, y, hop = Render.visualPosition(actor)
    check(x == 96 and y == 80 and math.abs(hop - 7) < .0001, 'Motion is converted to 32-pixel art cells')
    check(actor.grid.x == 4 and actor.motion.remaining == .08, 'Conversion preserves committed movement and timer')
    actor.motion.remaining = 0
    x, y, hop = Render.visualPosition(actor)
    check(x == 112 and y == 80 and hop == 0, 'Landing uses the exact feet origin')
    check(Actors.selfCheck(), 'Actor animation checks')
    check(require('src.pixel_world').selfCheck(), 'World pixel coordinates and isolation checks')
    local Font = require('src.pixel_font')
    local font = Font.new()
    for _, ch in ipairs({'A','Á','À','Â','Ã','É','Ê','Í','Ó','Ô','Õ','Ú','Ü','Ç',
        'a','á','à','â','ã','é','ê','í','ó','ô','õ','ú','ü','ç','–','—','·','?'}) do
        check(font:hasGlyphs(ch), 'Bitmap font lacks glyph ' .. ch)
    end
    local minFilter, magFilter = font:getFilter()
    check(minFilter == 'nearest' and magFilter == 'nearest', 'Bitmap font has no smoothing')
    check(font:getHeight() == 11 and Font.new(2):getHeight() == 22 and Font.new(6):getHeight() == 66,
        'Scaled pixel fonts keep integer glyph height')
    check(font:getWidth('ECO') * 2 == Font.new(2):getWidth('ECO'), 'Scaled font doubles glyph widths')
    check(Font.clean('ok — ça' .. string.char(0xE2, 0x88, 0x86)) == 'ok — ça?',
        'Unknown glyphs fold to ? without crashing')
    for _, group in ipairs({require('src.lore').lines, require('src.lore').options}) do
        local function walk(node)
            for _, v in pairs(node) do
                if type(v) == 'string' then check(Font.clean(v) == v, 'Lore string needs a missing glyph: ' .. v)
                elseif type(v) == 'table' then walk(v) end
            end
        end
        walk(group)
    end
    local Lore = require('src.lore')
    for _, list in ipairs({Lore.cards, Lore.inscriptions}) do
        for _, entry in pairs(list) do
            for _, s in ipairs(entry.lines or {}) do
                check(Font.clean(s) == s, 'Card/inscription needs a missing glyph: ' .. s)
            end
            if entry.title then check(Font.clean(entry.title) == entry.title, 'Missing glyph in ' .. entry.title) end
        end
    end
    for _, intro in pairs(Lore.bossIntros) do
        check(Font.clean(intro[1]) == intro[1] and Font.clean(intro[2]) == intro[2], 'Missing glyph in boss intro')
    end
    local Rooms = require('src.rooms')
    for _, theme in ipairs(Rooms.floorThemes) do
        check(Font.clean(theme.title) == theme.title, 'Missing glyph in region ' .. theme.title)
    end
    for id, arch in pairs(Rooms.archetypes) do
        for _, s in ipairs(arch.names) do
            check(Font.clean(s) == s, 'Missing glyph in room name ' .. s)
        end
        check(Font.clean(arch.tactic) == arch.tactic, 'Missing glyph in tactic ' .. id)
    end
    check(Font.clean(Lore.seal.title) == Lore.seal.title, 'Missing glyph in seal title')
    for _, s in ipairs(Lore.seal.lines) do
        check(Font.clean(s) == s, 'Missing glyph in seal line ' .. s)
    end
    for _, option in ipairs(Lore.sealOptions({gold = 9, pickaxes = 9})) do
        check(Font.clean(option.label) == option.label, 'Missing glyph in seal option ' .. option.label)
    end
    for _, upg in ipairs(require('src.progression').catalog) do
        check(Font.clean(upg.title .. upg.description) == upg.title .. upg.description,
            'Missing glyph in upgrade text ' .. upg.id)
    end
    check(Font.clean('MAPA DO ANDAR  PICARETAS +4  PROVISÃO +4 VIDA')
        == 'MAPA DO ANDAR  PICARETAS +4  PROVISÃO +4 VIDA', 'Missing glyph in shop labels')
    local enemy = {grid = {x = 12, y = 5}, enemy = {state = 'warn', timer = .5, warningDuration = 1}}
    local view = setmetatable({view = {w = 320, h = 180, left = 0, top = 0}}, Render)
    local game = {entities = function() return {enemy} end}
    local rectangle, count = love.graphics.rectangle, 0
    love.graphics.push('all')
    love.graphics.rectangle = function() count = count + 1 end
    local ok, err = xpcall(function()
        view:edgeThreats(game)
        check(count > 0 and enemy.enemy.timer == .5 and enemy.grid.x == 12 and enemy.grid.y == 5,
            'Offscreen active threats get a pixel indicator without mutating simulation')
        enemy.enemy.state, count = 'seek', 0
        view:edgeThreats(game)
        check(count == 0 and enemy.enemy.timer == .5 and enemy.grid.x == 12 and enemy.grid.y == 5,
            'Offscreen inactive enemies are not exposed by indicators')
    end, debug.traceback)
    love.graphics.rectangle = rectangle
    love.graphics.pop()
    assert(ok, err)
    print(string.format('%d PIXEL CAMERA AND ANIMATION ASSERTIONS PASSED', checks))
    return checks
end

-- Real input/update/draw integration; reuse the existing safe arena and callbacks.
function Pixel.runUi(getState)
    local checks, held = 0, {}
    local oldKeyboard = love.keyboard.isDown
    local oldWidth, oldHeight, oldFlags = love.window.getMode()
    local _, _, originalRenderer = getState()
    local oldMuted, oldReduced = originalRenderer.muted, originalRenderer.reducedMotion
    local function check(value, message) checks = checks + 1; assert(value, message) end
    local function press(key) love.keypressed(key, key, false); love.keyreleased(key) end
    local function advance(seconds)
        for _ = 1, math.ceil(seconds * 120) do love.update(1 / 120) end
    end
    local function animation(renderer, actor)
        local record = assert(renderer.actors.states[actor], 'Actor must have its own animation state')
        return record.animation, record
    end
    local function stamp(game)
        local p, m, w, g, h = game.player.grid, game.player.motion, game.player.weapon, game.player.guard, game.player.health
        local values = {game.time, game.state, p.x, p.y, m.remaining, m.duration, tostring(m.falling),
            w.state, w.charge, w.action, w.mineTimer, tostring(w.triggerHeld), h.current, h.immune,
            g.energy, tostring(g.active), game.pickaxes, game.gold, game.kills}
        for _, room in ipairs(game.rooms) do
            values[#values + 1] = tostring(room.visited) .. ':' .. tostring(room.discovered)
        end
        local keys = {}; for key in pairs(game.room.tiles) do keys[#keys + 1] = key end; table.sort(keys)
        for _, key in ipairs(keys) do
            local tile = game.room.tiles[key]
            values[#values + 1] = key .. ':' .. tostring(tile.ground) .. ':' .. tostring(tile.piece)
                .. ':' .. tostring(tile.hits) .. ':' .. tostring(tile.timer)
            for _, cell in ipairs(tile.cells or {}) do values[#values + 1] = cell.x .. ':' .. cell.y end
        end
        for _, e in ipairs(game:entities()) do
            local a = e.enemy or e.hazard or e.resonator
            if a then
                values[#values + 1] = tostring(a.state) .. ':' .. tostring(a.timer)
                for _, cell in ipairs(a.cells or {}) do values[#values + 1] = cell.x .. ':' .. cell.y end
            end
        end
        return table.concat(values, '|')
    end
    love.keyboard.isDown = function(key) return held[key] or false end
    local ok, err = xpcall(function()
        local _, screen = getState()
        if screen ~= 'title' then press('escape'); press('q') end
        press('return')
        local game, _, renderer = getState()
        require('tests.arena').reset(game)
        renderer.muted = true
        advance(.02); love.draw()
        local function frameHash()
            return love.data.hash('sha256', renderer.canvas:newImageData():getString())
        end
        local before = frameHash()
        for _ = 1, 6 do
            press('d')
            for _ = 1, 20 do
                love.update(1 / 120); love.draw()
                local v = renderer.view
                local x, y = Render.visualPosition(game.player)
                local wanted = Render.layout(love.graphics.getWidth(), love.graphics.getHeight(), game.room, x, y)
                check(v.left == wanted.left and v.top == wanted.top, 'Moving camera follows feet with no lag or hop offset')
                check(v.left % 1 == 0 and v.top % 1 == 0, 'Motion never introduces fractional camera pixels')
            end
        end
        check(game.player.grid.x == 10 and frameHash() ~= before, 'Native movement changes the rendered world')
        held.space = true; love.keypressed('space', 'space', false); advance(.35)
        check(game.player.weapon.state == 'charging', 'Animation does not finish charge ahead of simulation')
        local a, record = animation(renderer, game.player)
        check(record.state == 'charge', 'Charge pose follows weapon state')
        advance(.6)
        check(game.player.weapon.state == 'ready', 'Holding charge stays ready')
        a = animation(renderer, game.player)
        local pausedTimer = a.timer
        press('escape'); advance(.3); love.draw()
        check(animation(renderer, game.player) == a and a.timer == pausedTimer, 'Pause freezes actor animation')
        held.space = nil; love.keyreleased('space'); press('return'); advance(.04)
        check(game.player.weapon.state == 'empty', 'Resume does not fire an old release')
        a = animation(renderer, game.player); pausedTimer = a.timer
        press('tab'); advance(.3); love.draw()
        check(animation(renderer, game.player) == a and a.timer == pausedTimer, 'Guide freezes actor animation')
        press('tab'); advance(.02)
        a = animation(renderer, game.player); pausedTimer = a.timer
        game.reward = true; advance(.3); love.draw()
        check(animation(renderer, game.player) == a and a.timer == pausedTimer, 'Reward freezes actor animation')
        game.reward = false
        for _, size in ipairs({{900, 680}, {1120, 800}, {1920, 1080}}) do
            love.window.setMode(size[1], size[2], {resizable = true, minwidth = 900, minheight = 680})
            for _, reduced in ipairs({false, true}) do
                renderer.reducedMotion = reduced; advance(.02)
                local state = stamp(game)
                renderer.feedback.trauma = .9
                love.draw(); love.draw()
                check(stamp(game) == state, 'Rendering/shake/reduced motion preserve simulation and discovery')
                local minFilter, magFilter = renderer.canvas:getFilter()
                local v = renderer.view
                check(minFilter == 'nearest' and magFilter == 'nearest', 'Canvas has no smoothing')
                check(renderer.canvas:getWidth() == v.w and renderer.canvas:getHeight() == v.h,
                    'Resize recreates the internal canvas to integer dimensions')
            end
        end
        local time = game.time
        game:killFatal(game.player, 'combat'); advance(.02)
        local death = animation(renderer, game.player)
        local drawActor, deadDrawn = renderer.actor, false
        renderer.actor = function(self, e, g)
            if e == game.player then deadDrawn = true end
            return drawActor(self, e, g)
        end
        love.draw(); renderer.actor = drawActor
        check(deadDrawn, 'Dead player remains visible for the death animation')
        advance(death.totalDuration + .1)
        check(death.status == 'paused' and game.time == time, 'Death animation ends once without advancing combat')
        print(string.format('%d NATIVE PIXEL MOTION AND RESIZE ASSERTIONS PASSED', checks))
    end, debug.traceback)
    love.keyboard.isDown = oldKeyboard
    love.window.setMode(oldWidth, oldHeight, oldFlags)
    originalRenderer.muted, originalRenderer.reducedMotion = oldMuted, oldReduced
    assert(ok, err)
    return checks
end

return Pixel
