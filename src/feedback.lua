local flux = require('vendor.flux')
local ripple = require('vendor.ripple')
local Environment = require('src.environment')
local Music = require('src.music')
local Feedback = {}; Feedback.__index = Feedback
local colors = {
    hit = {1, .76, .40}, death = {.98, .46, .34}, block = {.40, .94, .88},
    pulse = {.40, .94, .88}, ready = {1, .81, .39}, fire = {1, .81, .39},
    clear = {.40, .94, .88}, room = {.52, .60, 1}, bossPhase = {.73, .67, 1},
    prime = {1, .63, .22}, blast = {1, .63, .22}, armor = {.70, .80, .91}, stun = {.73, .67, 1},
    wallBreak = {.45, .56, .60}, pillarWarn = {.98, .76, .37}, pillarFall = {.65, .73, .76},
    mineHit = {.56, .66, .69}, mineEmpty = {1, .36, .35}, chargeCancel = {.73, .67, 1},
    markWarn = {1, .63, .22}, markBlast = {1, .55, .18}, summon = {.73, .67, 1},
    hatch = {1, .76, .40}, stagger = {.73, .67, 1}, disarm = {.65, .73, .76}, worldEnd = {1, .81, .39},
    talk = {.34, .91, .81}, sealBreak = {.55, .42, .82}
}

local function tone(frequency, duration, mode)
    local rate = 22050
    local data = love.sound.newSoundData(math.floor(duration * rate), rate, 16, 1)
    local noise, phase = 113, 0
    local melody = mode == 'reward' and {1, 1.25, 1.5, 2} or mode == 'clear' and {1, 1.5, 2, 2.5}
    for i = 0, data:getSampleCount() - 1 do
        local t, p = i / rate, i / data:getSampleCount()
        local f = frequency * (mode == 'fall' and (1 - .65 * p) or mode == 'rise' and (1 + p) or 1)
        local age = t
        if melody then
            local step = duration / #melody
            f = frequency * melody[math.min(#melody, math.floor(t / step) + 1)]
            age = t % step
        elseif mode == 'bow' then f = frequency * (1 - .7 * p)
        elseif mode == 'rumble' then f = frequency * (1 - .8 * p) end
        phase = phase + f * math.pi * 2 / rate
        noise = (noise * 16807) % 2147483647
        local grain = (noise / 2147483647 - .5) * 2
        local wave = math.sin(phase) + .25 * math.sin(phase * 2)
        if mode == 'impact' or mode == 'rumble' then
            wave = wave * .65 + grain * math.exp(-t * (mode == 'rumble' and 9 or 35))
        elseif mode == 'metal' then
            wave = math.sin(phase) * .55 + math.sin(phase * 2.76) * math.exp(-t * 18) * .4
                + grain * math.exp(-t * 70) * .3
        elseif mode == 'bow' then
            wave = wave * math.exp(-t * 28) * .6 + grain * math.exp(-t * 40) * .8
        elseif mode == 'plucked' or melody then
            wave = (math.sin(phase) + .3 * math.sin(phase * 3) * math.exp(-age * 12)) * math.exp(-age * 7)
        end
        local envelope = math.min(1, age * 180) * (1 - p)^2
        data:setSample(i, math.max(-1, math.min(1, wave * envelope * .28)))
    end
    return love.audio.newSource(data, 'static'), data
end

function Feedback.new()
    local self = setmetatable({particles = {}, rings = {}, popups = {}, landings = {},
        bolts = {}, tweens = flux.group(), time = 0, trauma = 0, flash = 0, banner = 0,
        fade = 0, muted = false, reducedMotion = false, sounds = {}}, Feedback)
    -- Original, synthesized sounds: no samples or assets from the reference project.
    local specs = {hit = {155, .15, 'impact'}, death = {88, .3, 'fall'},
        block = {670, .23, 'metal'}, pulse = {240, .30, 'rise'}, ready = {880, .18, 'rise'},
        fire = {330, .16, 'bow'}, clear = {330, .8, 'clear'},
        warn = {185, .20, 'rise'}, land = {90, .06, 'fall'},
        armor = {780, .16, 'metal'}, blast = {68, .65, 'rumble'}, prime = {420, .27, 'rise'},
        stun = {550, .2, 'fall'}, reward = {440, .65, 'reward'},
        wallBreak = {115, .30, 'rumble'}, pillarWarn = {310, .24, 'fall'}, pillarFall = {62, .50, 'rumble'},
        mineHit = {340, .12, 'metal'}, mineEmpty = {110, .12, 'fall'}, chargeCancel = {260, .09, 'fall'},
        talk = {620, .14, 'plucked'}, voice = {700, .05, 'plucked'}}
    self.tag = ripple.newTag(); self.tag.volume = .65
    for name, s in pairs(specs) do
        local source = tone(s[1], s[2], s[3])
        self.sounds[name] = ripple.newSound(source, {tags = {self.tag}})
    end
    self.music = Music.new()
    return self
end

function Feedback:play(name, pitch, volume)
    if self.muted then return end
    local sound = self.sounds[name]
    if not sound then return end
    sound:play({pitch = pitch or 1, volume = volume or .7})
end

function Feedback:burst(x, y, count, color, power, material)
    if self.reducedMotion then count = math.ceil(count * .4) end
    for i = 1, count do
        local angle = love.math.random() * math.pi * 2
        local speed = (35 + love.math.random() * 110) * (power or 1)
        self.particles[#self.particles + 1] = {x = x, y = y, vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 15, life = .25 + love.math.random() * .4,
            max = .65, size = 1.4 + love.math.random() * 2.6, color = color, material = material,
            born = self.time}
    end
end

function Feedback:ring(x, y, color, radius, duration)
    self.rings[#self.rings + 1] = {x = x, y = y, radius = radius, color = color, life = duration, max = duration,
        born = self.time}
end

function Feedback:consume(event, game)
    local kind, x, y = event.kind, (event.x - .5) * 40, (event.y - .5) * 40
    local color = colors[kind] or {.50, .63, .70}
    if kind == 'ui' then
        self:play('talk', event.value or 1, .35)
    elseif kind == 'land' then
        local key = event.x .. ':' .. event.y
        local tile = self.landings[key] or {depth = 0}; self.landings[key] = tile
        tile.depth, tile.born = self.reducedMotion and 0 or 4, self.time
        self.tweens:to(tile, .27, {depth = 0}):ease('backout')
        if event.x == game.player.grid.x and event.y == game.player.grid.y then self:play('land', 1 + (event.x % 3) * .1, .2) end
    elseif kind == 'hit' then
        self:burst(x, y - 8, 11, color); self:ring(x, y, color, 22, .19)
        self.trauma = math.min(1, self.trauma + .28)
        local popup = {x = x, y = y - 22, alpha = 1, size = 1.25, text = tostring(event.value), color = color,
            born = self.time}
        self.popups[#self.popups + 1] = popup
        self.tweens:to(popup, .5, {y = y - 52, alpha = 0, size = 1}):ease('quadout')
        if event.x == game.player.grid.x and event.y == game.player.grid.y then self.flash = .15 end
        self:play(kind)
    elseif kind == 'death' then
        color = event.value == 'hole' and {.54, .46, .75} or event.value == 'crushed' and colors.pillarFall or color
        self:burst(x, y - 8, 22, color, 1.3); self:ring(x, y, color, 42, .34)
        if not self.reducedMotion then self.trauma = math.min(1, self.trauma + .23) end
        self:play(event.value == 'crushed' and 'pillarFall' or kind, event.value == 'hole' and .65 or 1)
    elseif kind == 'block' then
        self:burst(x, y, 15, color); self:ring(x, y, color, 32, .25); self:play(kind)
    elseif kind == 'armor' then
        self:burst(x, y - 6, 9, color, .65, 'metal'); self:play(kind, 1, .45)
        local popup = {x = x, y = y - 25, alpha = 1, size = .7, text = 'FLANQUEIE', color = color, born = self.time}
        self.popups[#self.popups + 1] = popup
        self.tweens:to(popup, .7, {y = y - 48, alpha = 0}):ease('quadout')
    elseif kind == 'prime' then
        self:ring(x, y, color, 30, .27); self:burst(x, y, 8, color, .6, 'crystal'); self:play(kind)
    elseif kind == 'mineHit' or kind == 'mineEmpty' then
        local label = kind == 'mineHit' and (event.hits or event.value) .. '/' .. Environment.constants.hits or 'SEM PICARETAS'
        local popup = {x = x, y = y - 23, alpha = 1,
            size = kind == 'mineHit' and .7 or .65, text = label, color = color, born = self.time}
        self.popups[#self.popups + 1] = popup
        self.tweens:to(popup, .5, {y = y - 40, alpha = 0}):ease('quadout')
        if kind == 'mineHit' then
            self:burst(x, y - 5, 5, color, .35, 'stone'); self:ring(x, y, color, 15, .12)
        end
        self:play(kind, kind == 'mineHit' and 1 + (event.value or 0) * .08 or 1, .4)
    elseif kind == 'chargeCancel' then
        self:ring(x, y, color, 19, .13); self:play(kind, 1, .25)
    elseif kind == 'wallBreak' then
        self:burst(x, y, 12, color, self.reducedMotion and .15 or .85, 'stone')
        self:ring(x, y, color, 28, .26); self:play(kind, 1, .55)
        if not self.reducedMotion then self.trauma = math.min(1, self.trauma + .15) end
    elseif kind == 'pillarWarn' then
        self:ring(x, y, color, 25, .32); self:play(kind, 1, .45)
    elseif kind == 'pillarFall' then
        self:burst(x, y, 12, color, self.reducedMotion and .15 or .85, 'stone')
        for _, cell in ipairs(event.value or {}) do
            local cx, cy = (cell.x - .5) * 40, (cell.y - .5) * 40
            self:ring(cx, cy, color, 21, .3)
            self:burst(cx, cy, 5, color, self.reducedMotion and .15 or .7, 'stone')
        end
        self:play(kind, 1, .65)
        if not self.reducedMotion then self.trauma = math.min(1, self.trauma + .25) end
    elseif kind == 'blast' then
        self:burst(x, y, 35, color, 1.7, 'crystal'); self:ring(x, y, color, 90, .48)
        for _, cell in ipairs(event.value or {}) do self:ring((cell.x - .5) * 40, (cell.y - .5) * 40, color, 19, .3) end
        self.trauma = math.min(1, self.trauma + .55); self:play(kind)
    elseif kind == 'stun' then self:burst(x, y - 12, 8, color, .4); self:play(kind)
    elseif kind == 'reward' then self:burst(x, y, 28, color, 1.5); self:play(kind)
    elseif kind == 'pulse' then
        self:burst(x, y, 24, color, 1.5); self:ring(x, y, color, 65, .38)
        self.trauma = math.min(1, self.trauma + .2); self:play(kind)
    elseif kind == 'clear' then
        self:burst(x, y, 32, color, 1.7); self:ring(x, y, color, 140, .9)
        self.banner = 1; self.tweens:to(self, 2.4, {banner = 0}):ease('quadin'); self:play(kind)
    elseif kind == 'bossPhase' then
        self:burst(x, y, 42, color, 1.6); self:ring(x, y, color, 95, .65)
        self.trauma = math.min(1, self.trauma + .5); self:play('clear', .6, .55)
    elseif kind == 'ready' then
        self:burst(x, y - 15, 7, color, .45); self:ring(x, y, color, 25, .28); self:play(kind, 1, .4)
    elseif kind == 'fire' then self:burst(x, y - 8, 4, color, .6); self:play(kind, 1, .4)
    elseif kind == 'shot' then
        -- Flecha em voo: a trajetória é anotada em células e o renderer a
        -- desenha como vulto — dourado nosso, rubro quando vem do inimigo.
        local v = event.value or {}
        if v.from and v.to and self.bolts then
            self.bolts[#self.bolts + 1] = {
                x1 = (v.from.x - .5) * 40, y1 = (v.from.y - .5) * 40,
                x2 = (v.to.x - .5) * 40, y2 = (v.to.y - .5) * 40,
                life = .16, max = .16, born = self.time,
                color = v.enemy and colors.death or colors.fire}
            -- O disparo inimigo soa mais grave e discreto que o nosso arco.
            self:play('fire', v.enemy and .6 or 1, v.enemy and .3 or .4)
        end
    elseif kind == 'warn' then self:play(kind, 1, .3)
    elseif kind == 'markWarn' then
        self:ring(x, y, color, 26, .3); self:play('prime', .8, .45)
    elseif kind == 'markBlast' then
        self:burst(x, y, 22, color, 1.4); self:ring(x, y, color, 62, .4)
        for _, cell in ipairs(event.value or {}) do self:ring((cell.x - .5) * 40, (cell.y - .5) * 40, color, 17, .25) end
        if not self.reducedMotion then self.trauma = math.min(1, self.trauma + .3) end
        self:play('blast', 1.3, .6)
    elseif kind == 'summon' then
        self:ring(x, y, color, 34, .5); self:burst(x, y - 8, 10, color, .7); self:play('prime', .6, .55)
        local popup = {x = x, y = y - 26, alpha = 1, size = .7, text = 'INVOCAÇÃO', color = color, born = self.time}
        self.popups[#self.popups + 1] = popup
        self.tweens:to(popup, .7, {y = y - 48, alpha = 0}):ease('quadout')
    elseif kind == 'hatch' then
        self:burst(x, y - 6, 14, color, .9); self:ring(x, y, color, 30, .3); self:play('land', .5, .6)
    elseif kind == 'stagger' then
        self:burst(x, y - 10, 16, color, .8); self:ring(x, y, color, 44, .4); self:play('stun', 1, .7)
        local popup = {x = x, y = y - 28, alpha = 1, size = .75, text = 'INTERROMPIDO', color = color, born = self.time}
        self.popups[#self.popups + 1] = popup
        self.tweens:to(popup, .8, {y = y - 52, alpha = 0}):ease('quadout')
    elseif kind == 'disarm' then self:ring(x, y, color, 18, .2); self:play('chargeCancel', 1.2, .2)
    -- event.sfx = o call site já tocou o cue no Sfx (Tímpano): o feedback
    -- mantém só o visual. Sem a marca, o arcade segue usando estes plays.
    elseif kind == 'talk' then self:ring(x, y - 12, color, 16, .22)
        if not event.sfx then self:play('talk', 1, .4) end
    elseif kind == 'sealBreak' then
        self:burst(x, y, 16, color, 1); self:ring(x, y, color, 34, .34)
        if not event.sfx then
            self:play('prime', .7, .5); self:play('wallBreak', 1.15, .3)
        end
    elseif kind == 'worldEnd' then
        self:burst(x, y, 48, color, 1.9); self:ring(x, y, color, 170, 1.1)
        self.banner = 1; self.tweens:to(self, 3, {banner = 0}):ease('quadin')
        self:play('reward', 1, .8); self:play('clear', .7, .6)
    elseif kind == 'room' then
        -- A transição apaga só o que nasceu antes deste update: efeitos do
        -- mesmo frame (o floreio do golpe final, por exemplo) sobrevivem.
        local function fresh(list)
            local kept = {}
            for _, e in ipairs(list or {}) do
                if e.born and e.born >= self.time then kept[#kept + 1] = e end
            end
            return kept
        end
        self.particles, self.rings = fresh(self.particles), fresh(self.rings)
        self.popups, self.bolts = fresh(self.popups), fresh(self.bolts)
        for key, tile in pairs(self.landings or {}) do
            if not (tile.born and tile.born >= self.time) then self.landings[key] = nil end
        end
        -- Cortina de transição: cada sala (e a arena) se revela do escuro.
        if self.tweens then
            if self.fadeTween then self.fadeTween:stop() end
            self.fade = 1
            self.fadeTween = self.tweens:to(self, self.reducedMotion and .25 or .45, {fade = 0}):ease('quadout')
        end
    end
end

function Feedback.selfCheck()
    assert(Music.selfCheck())
    for _, mode in ipairs({'impact', 'fall', 'rise', 'metal', 'rumble', 'bow', 'plucked', 'reward', 'clear'}) do
        local source, data = tone(330, .8, mode)
        assert(math.abs(source:getDuration() - .8) < .001, 'Synthesized sound duration: ' .. mode)
        local peak, tail = 0, 0
        for i = 0, data:getSampleCount() - 1 do
            local sample = math.abs(data:getSample(i))
            assert(sample < 1, 'Synthesized audio must not clip: ' .. mode)
            peak = math.max(peak, sample)
            if i >= data:getSampleCount() - 100 then tail = math.max(tail, sample) end
        end
        assert(peak > .01 and tail < .001, 'Synthesized sound must be audible and fade out: ' .. mode)
        source:release(); data:release()
    end
    local cells = {{x = 6, y = 4}, {x = 7, y = 4}}
    for _, reduced in ipairs({false, true}) do
        local feedback = setmetatable({particles = {}, rings = {}, popups = {}, tweens = flux.group(),
            muted = true, reducedMotion = reduced, trauma = 0, time = 0}, Feedback)
        feedback:consume({kind = 'wallBreak', x = 4, y = 4}, {})
        feedback:consume({kind = 'pillarWarn', x = 5, y = 4, value = cells}, {})
        feedback:consume({kind = 'pillarFall', x = 5, y = 4, value = cells}, {})
        assert(#feedback.particles == (reduced and 14 or 34), 'Terrain particles respect reduced motion')
        assert(feedback.particles[1].material == 'stone', 'Terrain impacts emit stone fragments')
        assert(#feedback.rings == 4 and (not reduced or feedback.trauma == 0), 'Terrain feedback preserves readable warnings without reduced-motion shake')
        assert(#cells == 2 and cells[1].x == 6 and cells[2].x == 7, 'Feedback must not change frozen terrain cells')
        feedback:consume({kind = 'mineHit', x = 4, y = 4, value = 1}, {})
        feedback:consume({kind = 'mineHit', x = 4, y = 4, value = 2}, {})
        feedback:consume({kind = 'mineEmpty', x = 4, y = 4}, {})
        assert(feedback.popups[1].text == '1/3' and feedback.popups[2].text == '2/3' and
            feedback.popups[3].text == 'SEM PICARETAS', 'Muted and reduced motion preserve mining feedback')
    end
    return true
end

function Feedback:update(dt, game, screen)
    self.time = self.time + dt
    self.tag.volume = self.muted and 0 or .65
    self.tweens:update(dt)
    self.trauma, self.flash = math.max(0, self.trauma - dt * 1.5), math.max(0, self.flash - dt)
    for _, event in ipairs(game.events or {}) do self:consume(event, game) end
    game.events = {}
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]; p.life = p.life - dt
        p.x, p.y, p.vy = p.x + p.vx * dt, p.y + p.vy * dt, p.vy + dt * 70
        if p.life <= 0 then table.remove(self.particles, i) end
    end
    for i = #self.rings, 1, -1 do
        local p = self.rings[i]; p.life = p.life - dt
        if p.life <= 0 then table.remove(self.rings, i) end
    end
    for i = #self.popups, 1, -1 do if self.popups[i].alpha <= 0 then table.remove(self.popups, i) end end
    if self.bolts then
        for i = #self.bolts, 1, -1 do
            local b = self.bolts[i]; b.life = b.life - dt
            if b.life <= 0 then table.remove(self.bolts, i) end
        end
    end
    self.music:update(dt, game, screen, self.muted)
    for _, sound in pairs(self.sounds) do sound:update(dt) end
end

return Feedback
