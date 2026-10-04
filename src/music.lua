-- Sem ciclo: sfx só exige vendor.ripple (topo) e src.lore (lazy, em voice).
local Sfx = require('src.sfx')
local Music = {}; Music.__index = Music
local tracks = {'chamber_of_echoes', 'warden', 'demolisher', 'regent', 'breaker', 'veteran',
    'challenge_combat', 'challenge_targets'}
local TRACK_SET = {}
for _, name in ipairs(tracks) do TRACK_SET[name] = true end
-- Chefes humanos da campanha (role.boss na arena) emprestam o tema do chefe
-- mecânico da mesma família: martelo→demolisher, empurrão→warden, jato→regent.
local BOSS_THEME = {janda = 'demolisher', rute = 'warden', ivo = 'regent', beltran = 'breaker'}

-- Kind devolvido pelo tema pode não ter wav próprio (arquétipos novos como
-- sower/husk/watcher ainda não têm trilha): boss desconhecido cai no tema de
-- elite mais pesado, elite desconhecido no elite genérico — nunca em nil.
local function bossTrack(kind) return TRACK_SET[kind] and kind or 'veteran' end
local function eliteTrack(kind) return TRACK_SET[kind] and kind or 'breaker' end

function Music.theme(game, screen)
    if screen == 'title' or screen == 'opening' or game.state ~= 'playing' then
        return tracks[1]
    end
    -- Campanha em batalha: a arena carrega os kinds nos roles; chefe vivo
    -- puxa seu tema, encontro comum vai para a faixa de desafio. Este branch
    -- precisa vir antes do `cleared`: Region.load marca cleared=true em todo
    -- mapa de campanha, então aqui o early return nunca pode pegar a arena.
    -- O Game de arcade não tem .scene/.battle e cai direto no fluxo antigo.
    if game.scene == 'battle' and game.battle then
        for _, e in ipairs(game.battle.enemies or {}) do
            if e.role and e.role.boss and e.health.current > 0 then
                return BOSS_THEME[e.enemy.kind] or 'warden'
            end
        end
        return 'challenge_combat'
    end
    if game.room.cleared then return tracks[1] end
    local elite
    for _, e in ipairs(game:entities()) do
        if e.enemy and e.health.current > 0 then
            if e.enemy.boss then return bossTrack(e.enemy.kind) end
            if e.enemy.elite then elite = e.enemy.kind end
        end
    end
    if elite then return eliteTrack(elite) end
    if game.room.challenge then
        local challenge = 'challenge_' .. game.room.challenge
        return TRACK_SET[challenge] and challenge or 'challenge_combat'
    end
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
    local volume = (screen == 'title' or screen == 'opening' or screen == 'paused'
        or screen == 'help' or game.state ~= 'playing') and .16 or .32
    for name, source in pairs(self.sources) do
        local target, level = name == theme and 1 or 0, self.levels[name]
        local step = dt / 1.25
        level = level < target and math.min(target, level + step) or math.max(target, level - step)
        self.levels[name] = level
        -- Canais lidos a cada frame: o menu de opções mexe sem reiniciar.
        source:setVolume(muted and 0 or level * volume
            * Sfx.getVolume('music') * Sfx.getVolume('master'))
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
    -- Arquétipos sem trilha própria caem no genérico do papel — nunca em nil.
    actors[1].enemy, actors[1].health.current, g.room.challenge = {kind = 'sower', elite = true}, 8, nil
    assert(Music.theme(g, 'playing') == 'breaker', 'Elite sem wav usa o elite genérico')
    actors[1].enemy = {kind = 'husk', boss = true}
    assert(Music.theme(g, 'playing') == 'veteran', 'Chefe sem wav usa o elite pesado')
    g.room.challenge = 'riddle'
    actors[1].enemy = {kind = 'dasher'}
    assert(Music.theme(g, 'playing') == 'challenge_combat', 'Desafio desconhecido usa o combate')
    -- Restaura o stub para o fluxo de crossfade abaixo (elite veteran, morta).
    actors[1].enemy, actors[1].health.current, g.room.challenge = {kind = 'veteran', elite = true}, 0, nil
    g.state = 'dead'; assert(Music.theme(g, 'playing') == tracks[1])
    -- Batalha de campanha: chefe humano (role.boss) escolhe o tema da
    -- família; arena sem chefe toca a faixa de desafio. room.cleared=true
    -- reproduz o formato real de Region.load (regiões nascem cleared).
    local cg = {state = 'playing', room = {cleared = true, campaignRegion = true}, scene = 'battle',
        battle = {enemies = {
            {enemy = {kind = 'janda'}, role = {boss = 'hammer'}, health = {current = 14}}}},
        entities = function() return {} end}
    assert(Music.theme(cg, 'playing') == 'demolisher', 'Boss da campanha puxa o tema da família')
    cg.battle.enemies[1].role.boss = nil
    assert(Music.theme(cg, 'playing') == 'challenge_combat', 'Arena sem chefe toca o desafio')
    assert(Music.theme(cg, 'opening') == tracks[1], 'Abertura fica na faixa do título')
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
