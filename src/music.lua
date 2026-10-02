local Music = {}; Music.__index = Music
local tracks = {'chamber_of_echoes', 'warden', 'demolisher', 'regent', 'breaker', 'veteran',
    'challenge_combat', 'challenge_targets'}

function Music.theme(game, screen)
    if screen == 'title' or game.state ~= 'playing' or game.room.cleared then return tracks[1] end
    local elite
    for _, e in ipairs(game:entities()) do
        if e.enemy and e.health.current > 0 then
            if e.enemy.boss then return e.enemy.kind end
            if e.enemy.elite then elite = e.enemy.kind end
        end
    end
    if elite then return elite end
    if game.room.challenge then return 'challenge_' .. game.room.challenge end
    return tracks[1]
end

function Music.new()
    local self = setmetatable({sources = {}, levels = {}}, Music)
    for _, name in ipairs(tracks) do
        local source = love.audio.newSource('assets/audio/' .. name .. '.wav', 'stream')
        source:setLooping(true); source:setVolume(0)
        self.sources[name], self.levels[name] = source, 0
    end
    return self
end

function Music:update(dt, game, screen, muted)
    local theme = Music.theme(game, screen)
    if theme ~= self.current then self.sources[theme]:play(); self.current = theme end
    local volume = (screen == 'title' or screen == 'paused' or screen == 'help' or game.state ~= 'playing') and .16 or .32
    for name, source in pairs(self.sources) do
        local target, level = name == theme and 1 or 0, self.levels[name]
        local step = dt / 1.25
        level = level < target and math.min(target, level + step) or math.max(target, level - step)
        self.levels[name] = level
        source:setVolume(muted and 0 or level * volume)
        if level == 0 and name ~= theme then source:pause() end
    end
end

function Music.selfCheck()
    local Game = require('src.game')
    local music = Music.new()
    for _, source in pairs(music.sources) do assert(source:isLooping() and source:getDuration() > 45) end
    for floor = 1, 3 do
        local g = Game.new(42042, false, floor)
        g:enter(g.rooms.bossId)
        assert(Music.theme(g, 'playing') == g.room.bossKind, 'Each real boss selects its own score')
        assert(Music.theme(g, 'title') == tracks[1], 'Menu overrides the encounter')
        g.room.cleared = true
        assert(Music.theme(g, 'playing') == tracks[1], 'Cleared bosses return to exploration')
        g:enter(g.rooms.superSecretId)
        assert(Music.theme(g, 'playing') == 'challenge_targets', 'Real target challenge selects its score')
        g:enter(g.rooms.secretId)
        local expected
        for _, e in ipairs(g:entities()) do if e.enemy and e.enemy.elite then expected = e.enemy.kind end end
        assert(expected and Music.theme(g, 'playing') == expected, 'Elite lair uses its actual elite kind')
    end
    local actors = {{enemy = {kind = 'dasher'}, health = {current = 6}}}
    local g = {state = 'playing', room = {}, entities = function() return actors end}
    assert(Music.theme(g, 'playing') == tracks[1], 'Common brute is not an elite')
    for _, name in ipairs({'breaker', 'veteran'}) do
        actors[1].enemy = {kind = name, elite = true}
        assert(Music.theme(g, 'playing') == name)
    end
    actors[1].health.current, g.room.challenge = 0, 'combat'
    assert(Music.theme(g, 'playing') == 'challenge_combat', 'Remaining challenge resumes after elite death')
    g.state = 'dead'; assert(Music.theme(g, 'playing') == tracks[1])
    g.state, g.room.challenge = 'playing', nil
    music:update(1.25, g, 'playing', false)
    actors[1].health.current = 8
    music:update(.625, g, 'playing', false)
    assert(music.levels.veteran == .5 and music.levels[tracks[1]] == .5, 'Crossfade overlaps both tracks')
    music:update(.625, g, 'playing', true)
    for _, source in pairs(music.sources) do assert(source:getVolume() == 0, 'Mute includes all streams') end
    assert(not music.sources[tracks[1]]:isPlaying(), 'Old track pauses after fading')
    music:update(.1, g, 'paused', false)
    assert(math.abs(music.sources.veteran:getVolume() - .16) < .001, 'Paused music is quieter')
    for _, source in pairs(music.sources) do source:stop(); source:release() end
    return true
end

return Music
