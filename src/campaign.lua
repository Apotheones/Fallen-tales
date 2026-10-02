-- Campaign session for "A Cidade Que Me Enterrou". The campaign owns the
-- persistent state (flags, steps, people, per-region changes), the authored
-- map currently loaded, and the explore/battle scenes. It deliberately quacks
-- like Game where the presentation layer needs it — room, player, entities(),
-- dialogue, events — so the pixel renderer and dialogue box are reused.
local Region = require('src.region')
local Explore = require('src.explore')
local Dialogue = require('src.dialogue')
local LoreC = require('src.campaign_lore')
local Save = require('src.save')
local Battle = require('src.battle')
local Campaign = {}; Campaign.__index = Campaign

local function freshState()
    return {
        version = Save.VERSION,
        region = 'colina', x = nil, y = nil, arrival = 'sepultura',
        steps = {},          -- 'P01-E02' = true, in ficha notation
        flags = {},          -- casaco, metDoroFirst, gradeHow...
        regions = {},        -- [id] = {visited, props = {[id] = state}}
        people = {},         -- [id] = {met, location}
        encounters = {},     -- [id] = 'won' | 'negotiated'
        deaths = 0,
    }
end

local function makePlayer()
    return {
        player = true, grid = {x = 1, y = 1},
        facing = {dx = 0, dy = 1},
        motion = {remaining = 0, duration = .16, fromX = 1, fromY = 1},
        health = {current = 10, max = 10},
        weapon = {state = 'empty', charge = 0, action = 0, mineTimer = 0},
        guard = {active = false, energy = 1.6, max = 1.6},
        moving = false,
    }
end

local function makeNpc(def)
    return {
        npc = {id = def.id}, grid = {x = def.x, y = def.y},
        facing = {dx = def.dx or 0, dy = def.dy or 1},
        motion = {remaining = 0, duration = .16, fromX = def.x, fromY = def.y},
        health = {current = 1, max = 1},
        talkRange = def.talkRange or 1.7,
    }
end

function Campaign.new()
    local self = setmetatable({data = freshState(), state = 'playing', scene = 'explore',
        events = {}, message = '', messageTime = 0, roomTime = 0,
        gold = 0, pickaxes = 0, xp = 0, level = 1, reward = nil,
        time = 0}, Campaign)
    for id, info in pairs(LoreC.npcs) do
        self.data.people[id] = {location = info.home or 'hub'}
    end
    self.player = makePlayer()
    self:enter(self.data.region, self.data.arrival)
    self:checkpoint()
    if not self.data.flags.intro then
        self.data.flags.intro = true
        self:completeStep('P01-E01')
        Dialogue.open(self, LoreC.intro)
    end
    return self
end

function Campaign.restore(data)
    local self = setmetatable({data = data, state = 'playing', scene = 'explore',
        events = {}, message = '', messageTime = 0,
        gold = 0, pickaxes = 0, xp = 0, level = 1, reward = nil,
        time = 0}, Campaign)
    self.player = makePlayer()
    self:enter(data.region, nil, {x = data.x, y = data.y})
    return self
end

function Campaign:flag(name) return self.data.flags[name] == true end

function Campaign:checkpoint()
    self.data.region, self.data.arrival = self.map.id, nil
    self.data.x, self.data.y = self.player.grid.x, self.player.grid.y
    Save.write(self.data)
end

-- Loads the authored map and folds the persistent region state over it:
-- consumed props disappear, opened passages lose their solidity, npcs appear
-- only where their saved location says they are.
function Campaign:enter(id, arrival, exact)
    local map = Region.load(id)
    local saved = self.data.regions[id] or {visited = false, props = {}}
    self.data.regions[id] = saved
    saved.visited = true
    for propId, propState in pairs(saved.props or {}) do
        for _, prop in ipairs(map.props) do
            if prop.id == propId then prop.state = propState end
        end
    end
    for cell, prop in pairs(map.propCells) do
        if prop.state == 'open' or prop.state == 'taken' then map.propCells[cell] = nil end
    end
    self.map, self.room = map, map
    -- Doro relocates after the first descent; if the runa negotiation is done
    -- she moves to the passage house as well. Relocation runs before the npc
    -- spawn loop so the residents are already standing inside on arrival.
    if id == 'hub' and not self:stepDone('P01-E04') then
        self.data.people.doro = self.data.people.doro or {}
        self.data.people.doro.location = 'hub'
        if self:stepDone('P01-E03') then
            self.data.people.runa = self.data.people.runa or {}
            self.data.people.runa.location = 'hub'
        end
    end
    self.npcs = {}
    for _, def in ipairs(map.npcs) do
        local person = self.data.people[def.id]
        if person and person.location == id then
            self.npcs[#self.npcs + 1] = makeNpc(def)
        end
    end
    self.enemies = {}
    for _, def in ipairs(map.encounters) do
        if not self.data.encounters[def.id] then
            self.enemies[#self.enemies + 1] = {
                enemy = {id = def.id, kind = def.kind, state = 'idle', timer = 0},
                grid = {x = def.x, y = def.y}, facing = {dx = 0, dy = 1},
                motion = {remaining = 0, duration = .16, fromX = def.x, fromY = def.y},
                health = {current = 1, max = 1},
            }
        end
    end
    local point = map.arrivals[arrival or ''] or map.spawn
    if exact then
        self.player.grid.x, self.player.grid.y = exact.x, exact.y
    else
        self.player.grid.x, self.player.grid.y = point.x, point.y
        self.player.facing.dx, self.player.facing.dy = point.dx or 0, point.dy or 1
    end
    self.scene, self.battle, self.dialogue = 'explore', nil, nil
    self.roomName = map.name
    self.roomTime = 3
    self:effect('room', self.player.grid.x, self.player.grid.y)
    if id == 'hub' and not self:stepDone('P01-E04') then
        self:completeStep('P01-E04')
        Dialogue.open(self, LoreC.hubArrival)
    end
end

function Campaign:stepDone(step) return self.data.steps[step] == true end

function Campaign:completeStep(step)
    if self.data.steps[step] then return end
    self.data.steps[step] = true
    self:checkpoint()
end

-- Prop states: 'open' and 'taken' stop blocking; 'done' keeps the body but
-- draws the used version. States persist in state.regions[id].props.
function Campaign:setProp(id, value)
    local saved = self.data.regions[self.map.id]
    saved.props = saved.props or {}
    saved.props[id] = value
    for _, prop in ipairs(self.map.props) do
        if prop.id == id then prop.state = value end
    end
    if value == 'open' or value == 'taken' then
        for cell, prop in pairs(self.map.propCells) do
            if prop.id == id then self.map.propCells[cell] = nil end
        end
    end
    self:checkpoint()
end

function Campaign:openGrade(how)
    self.data.flags.gradeHow = how
    self:setProp('grade', 'open')
    self:completeStep('P01-E03')
    self.data.people.runa.location = 'hub'
    self:notify('A grade sobe. O caminho para o refúgio está livre.')
end

function Campaign:travel(to, arrival)
    self:enter(to, arrival)
    self:checkpoint()
end

function Campaign:die(cause)
    self.data.deaths = (self.data.deaths or 0) + 1
    self:enter('colina', 'sepultura')
    self:notify('Você acorda de novo na cova. Nada foi desfeito.')
    self:checkpoint()
end

function Campaign:effect(kind, x, y, value)
    self.events[#self.events + 1] = {kind = kind, x = x, y = y, value = value}
end

function Campaign:notify(text, duration)
    self.message, self.messageTime = text, duration or 2.8
end

function Campaign:entities()
    if self.scene == 'battle' and self.battle then
        local list = {self.battle.player}
        for _, e in ipairs(self.battle.enemies or {}) do list[#list + 1] = e end
        return list
    end
    local list = {self.player}
    for _, npc in ipairs(self.npcs) do list[#list + 1] = npc end
    for _, e in ipairs(self.enemies or {}) do list[#list + 1] = e end
    return list
end

function Campaign:canLeave(door) return door.open ~= false end
function Campaign:weaponStats() return {chargeTime = .72, damage = 3} end
function Campaign:clearIntents() self.player.moving = false end
function Campaign:advanceDialogue() Dialogue.advance(self) end
function Campaign:closeDialogue() Dialogue.close(self) end
function Campaign:chooseDialogue(index) return Dialogue.choose(self, index) end

function Campaign:nearNpc()
    local p = self.player.grid
    local best, bestDist = nil, math.huge
    for _, npc in ipairs(self.npcs) do
        local d = math.abs(npc.grid.x - p.x) + math.abs(npc.grid.y - p.y)
        if d < bestDist then best, bestDist = npc, d end
    end
    if best and bestDist <= (best.talkRange or 1.7) then return best end
end

function Campaign:nearHotspot()
    local p = self.player.grid
    local best, bestDist = nil, math.huge
    for _, spot in ipairs(self.map.hotspots) do
        local used = spot.once and self.data.regions[self.map.id].props[spot.id] == 'taken'
        local ok = not used and (not spot.when or spot.when(self))
        if ok then
            local dist = math.sqrt((spot.x - p.x) ^ 2 + (spot.y - p.y) ^ 2)
            if dist <= (spot.range or 1.45) and dist < bestDist then
                best, bestDist = spot, dist
            end
        end
    end
    return best
end

function Campaign:interact()
    if self.dialogue or self.scene ~= 'explore' then return false end
    local npc = self:nearNpc()
    if npc then
        npc.facing.dx = self.player.grid.x > npc.grid.x and 1
            or self.player.grid.x < npc.grid.x and -1 or 0
        npc.facing.dy = npc.facing.dx == 0 and (self.player.grid.y > npc.grid.y and 1 or -1) or 0
        local node = LoreC.talk(self, npc.npc.id)
        if node then
            self.player.moving = false
            Dialogue.open(self, node)
            self:effect('talk', npc.grid.x, npc.grid.y)
            self:checkpoint()
            return true
        end
    end
    local spot = self:nearHotspot()
    if spot then
        self.player.moving = false
        local node = LoreC.hotspot(self, spot)
        if node then
            Dialogue.open(self, node)
            if spot.once then
                self.data.regions[self.map.id].props[spot.id] = 'taken'
            end
            self:effect('talk', spot.x, spot.y)
            self:checkpoint()
            return true
        end
    end
    return false
end

function Campaign:startBattle(encounterId)
    local kind
    for _, e in ipairs(self.enemies) do
        if e.enemy.id == encounterId then kind = e.enemy.kind; break end
    end
    self.battle = Battle.new(self, encounterId, kind)
    self.scene = 'battle'
end

function Campaign:endBattle(result)
    local encounter = self.battle.encounterId
    self.scene, self.battle = 'explore', nil
    if result == 'won' or result == 'negotiated' then
        self.data.encounters[encounter] = result
        for i, e in ipairs(self.enemies) do
            if e.enemy.id == encounter then table.remove(self.enemies, i); break end
        end
        self:checkpoint()
    end
    self.player.moving = false
end

function Campaign:update(dt, input)
    if self.scene == 'battle' then
        self.battle:update(dt, self, input)
        return
    end
    if self.dialogue then return end
    self.time = self.time + dt
    self.messageTime = math.max(0, self.messageTime - dt)
    self.roomTime = math.max(0, self.roomTime - dt)
    Explore.move(self, dt, input.dx or 0, input.dy or 0)
    -- Visible encounters: touching the creature in the world opens its arena.
    if self.scene == 'explore' then
        local p = self.player.grid
        for _, e in ipairs(self.enemies) do
            if math.abs(e.grid.x - p.x) < .55 and math.abs(e.grid.y - p.y) < .55 then
                self:startBattle(e.enemy.id)
                break
            end
        end
    end
end

return Campaign
