local Concord = require("src.components")
local Rooms = require("src.rooms")
local Systems = require("src.systems")
local Progression = require("src.progression")
local Boss = require("src.boss")
local Environment = require("src.environment")
local Game = {}; Game.__index = Game

Game.weapons = {
    bow = {label = "ARCO", damage = 3, chargeTime = .72, chargeSpeed = 1, interval = .035, color = {.96, .73, .32}}
}

function Game.new(seed, practice, floorNumber)
    floorNumber = type(floorNumber) == "number" and floorNumber or 1
    local self = setmetatable({seed = seed, practice = practice, floorNumber = floorNumber,
        rooms = Rooms.generate(seed, practice, floorNumber), gold = 0,
        events = {}, time = 0, state = "playing", kills = 0, roomId = 1, damageBonus = 0,
        reward = false, message = "", messageTime = 0, pickaxes = Environment.constants.pickaxes}, Game)
    self.floorNumber = self.rooms.floorNumber
    Progression.start(self)
    self:enter(1)
    return self
end

function Game:weaponStats()
    local stats = {}
    for key, value in pairs(self.weapons.bow) do stats[key] = value end
    stats.damage = stats.damage + self.damageBonus
    if self.upgrades.bowPierce then stats.damage = math.max(1, stats.damage - 1) end
    if self.upgrades.bowQuick then stats.chargeSpeed = stats.chargeSpeed * 1.35 end
    return stats
end

function Game:notify(text) self.message, self.messageTime = text, 2.5 end
function Game:effect(kind, x, y, value)
    self.events[#self.events + 1] = {kind = kind, x = x, y = y, value = value}
end
function Game:actor(x, y, team, hp)
    return Concord.entity(self.world):give("grid", x, y):give("motion", team == "player" and .16 or .24)
        :give("facing", team == "player" and 1 or -1, 0):give("health", hp):give("team", team)
end

function Game:enter(id, arrival)
    local previous = self.player
    local hp = previous and previous.health.current or 10
    local energy = previous and previous.guard.energy or 1.6
    self.roomId, self.room, self.reward = id, self.rooms[id], false
    self.world = Concord.world():setResource("game", self)
    self.world:addSystems(Systems.Movement, Systems.Player, Systems.Enemy, Boss, Systems.Projectile, Environment, Systems.Damage)
    local x, y = self.room.spawn.x, self.room.spawn.y
    if arrival then x, y = Rooms.arrival(self.room, arrival) end
    self.player = self:actor(x, y, "player", 10):give("player"):give("weapon"):give("guard")
    self.player.health.current, self.player.guard.energy = hp, energy
    if arrival == "east" then self.player.facing.dx = -1
    elseif arrival == "north" then self.player.facing.dx, self.player.facing.dy = 0, 1
    elseif arrival == "south" then self.player.facing.dx, self.player.facing.dy = 0, -1 end
    if not self.room.cleared then
        for _, spawn in ipairs(self.room.enemies) do
            self:spawnEnemy(spawn.x, spawn.y, spawn.kind)
        end
        for _, target in ipairs(self.room.targets or {}) do
            if not target.hit then self:actor(target.x, target.y, "neutral", 1):give("target", target) end
        end
        if not self.room.refuge then
            for _, crystal in ipairs(self.room.crystals) do
                if Rooms.floor(self.room, crystal.x, crystal.y) then
                    self:actor(crystal.x, crystal.y, "neutral", 1):give("resonator")
                end
            end
        end
    end
    self.room.visited, self.room.discovered = true, true
    for _, door in ipairs(self.room.doors) do
        if door.to and (not door.hidden or door.revealed) then self.rooms[door.to].discovered = true end
    end
    self.world:emit("flush")
    if self.room.refuge and not self.room.healed then
        self.room.healed = true
        self.player.health.current = math.min(10, hp + 4)
        self:notify("Refúgio: +4 de vida. O caminho de volta está livre.")
    end
    if self.room.challenge then
        -- Finding the optional room costs a tool; returning or crossing it never does.
        for _, door in ipairs(self.room.doors) do
            if door.hidden and not door.revealed then self:openSecretDoor(door) end
        end
        if not self.room.cleared then
            self:notify(self.room.challenge == "targets" and "Desafio de pontaria: acerte os três alvos com o arco. Saída livre."
                or "Desafio secreto: vença os guardas para receber um eco. Saída livre.")
        elseif not self.room.rewardTaken then Progression.offer(self) end
    elseif self.room.kind == "treasure" and not self.room.rewardTaken then
        Progression.offer(self)
        self:notify("Tesouro: escolha um eco. Esta sala só recompensa uma vez.")
    elseif self.room.kind == "shop" then
        self:notify("Posto vazio. Os comerciantes ainda não chegaram.")
    end
    self:effect("room", x, y)
end

function Game:mapVisible(room)
    return room.visited == true or room.discovered == true
end

function Game:targetCount()
    local count = 0
    for _, target in ipairs(self.room.targets or {}) do if not target.hit then count = count + 1 end end
    return count
end

function Game:openSecretDoor(door)
    for _, endpoint in ipairs({self.room, self.rooms[door.to]}) do
        for _, link in ipairs(endpoint.doors) do
            if link == door or (endpoint.id == door.to and link.to == self.roomId and link.side == door.arrival) then
                link.revealed = true
                local cell = Rooms.cell(endpoint, link.x, link.y)
                cell.piece, cell.protected, cell.hits, cell.state = "portal", true, 0, "open"
                endpoint.revision = endpoint.revision + 1
            end
        end
    end
    self.rooms[door.secretTo].discovered = true
    self.rooms[door.to].discovered = true
    self:notify("Passagem secreta descoberta.")
end

function Game:canLeave(door)
    return (self.room.cleared or self.room.challenge ~= nil) and (not door.hidden or door.revealed == true)
end

function Game:nextFloor()
    if self.practice or self.state ~= "won" then return false end
    self.floorNumber = self.floorNumber + 1
    self.rooms = Rooms.generate(self.seed, false, self.floorNumber)
    self.events = {}
    self.state = "playing"
    self:enter(1)
    self:notify("Andar " .. self.floorNumber .. ": encontre o Guardião e a próxima saída.")
    return true
end

function Game:spawnEnemy(x, y, kind)
    local entity = self:actor(x, y, "enemy", kind == "warden" and 24 or (kind == "dasher" and 6 or 5)):give("enemy", kind)
    entity.enemy.frontalArmor = kind == "dasher" or kind == "warden"
    return entity
end
function Game:entities() return self.world:getEntities() end
function Game:enemyCount()
    local n = 0
    for _, e in ipairs(self:entities()) do if e.enemy and e.health.current > 0 then n = n + 1 end end
    return n
end
function Game:occupant(x, y, except)
    -- ponytail: linear scan is enough for these small rooms; use a tile index for hundreds of actors.
    for _, e in ipairs(self:entities()) do
        if e ~= except and e.health and e.health.current > 0 and
            ((e.grid.x == x and e.grid.y == y) or (e.motion.remaining > 0 and e.motion.fromX == x and e.motion.fromY == y)) then
            return e
        end
    end
end
function Game:walkable(x, y, entity, allowHole)
    if not (allowHole and Rooms.enterable(self.room, x, y) or Rooms.floor(self.room, x, y))
        or self:occupant(x, y, entity) then return false end
    for _, door in ipairs(self.room.doors) do
        if door.x == x and door.y == y then
            return entity == self.player and self:canLeave(door)
        end
    end
    return true
end

function Game:move(entity, dx, dy, duration, committed)
    if entity.health.current <= 0 or entity.motion.falling or math.abs(dx) + math.abs(dy) ~= 1 or (dx ~= 0 and dy ~= 0)
        or entity.motion.remaining > 0 then return false end
    local p, m = entity.grid, entity.motion
    if not self:walkable(p.x + dx, p.y + dy, entity, entity.player or committed) then return false end
    m.fromX, m.fromY = p.x, p.y
    m.duration = duration or (entity.player and .16 or .24)
    m.remaining = m.duration
    p.x, p.y = p.x + dx, p.y + dy
    m.falling = Rooms.cell(self.room, p.x, p.y).ground == "hole"
    self:effect("hop", p.x, p.y)
    return true
end

function Game:cancelCharge()
    local w = self.player.weapon
    w.triggerHeld = false
    if w.state == "charging" or w.state == "ready" then
        self:effect("chargeCancel", self.player.grid.x, self.player.grid.y)
        w.state, w.charge = "empty", 0
    end
end

function Game:clearIntents()
    local m = self.player.motion
    m.bufferTime, m.blocked = 0, {}
    self:cancelCharge()
    self.player.guard.active = false
end

function Game:killFatal(entity, cause)
    if entity.health.current <= 0 then return false end
    entity.health.current, entity.health.cause = 0, cause
    entity.motion.remaining, entity.motion.falling = 0, false
    if entity.player then
        self.deathCause, self.state, self.reward = cause, "dead", false
        self:clearIntents()
    else
        if entity.enemy then self.kills = self.kills + 1 end
        entity:destroy()
    end
    self:effect("death", entity.grid.x, entity.grid.y, cause)
    return true
end

function Game:shoot(entity, dx, dy, damage, interval, range, kind)
    local e = Concord.entity(self.world):give("grid", entity.grid.x, entity.grid.y)
        :give("team", entity.team.value):give("projectile", dx, dy, damage, interval, range, kind)
    self:effect("fire", e.grid.x, e.grid.y, kind)
    return e
end

function Game:damage(target, amount, sx, sy, attackKind)
    if self.state ~= "playing" or target.health.current <= 0 or target.motion.falling then return false end
    if target.target then
        if attackKind ~= "bow" then return false end
        target.target.data.hit, target.health.current = true, 0
        self:effect("hit", target.grid.x, target.grid.y, 1)
        target:destroy()
        self:notify("Pontaria: " .. (3 - self:targetCount()) .. "/3 alvos. Saída livre.")
        return true
    end
    if target.resonator then return Environment.prime(self, target) end
    local hp = target.health
    if target.enemy and target.enemy.frontalArmor then
        local f, p = target.facing, target.grid
        local front = (sx - p.x) * f.dx + (sy - p.y) * f.dy > 0
        local side = (sx - p.x) * f.dy - (sy - p.y) * f.dx
        if front and side == 0 then self:effect("armor", p.x, p.y); return false end
    end
    if target.guard and target.guard.active then
        local g, f, p = target.guard, target.facing, target.grid
        local front = (sx - p.x) * f.dx + (sy - p.y) * f.dy > 0
        local side = (sx - p.x) * f.dy - (sy - p.y) * f.dx
        if front and side == 0 then
            g.energy = math.max(0, g.energy - .3)
            self:effect("block", p.x, p.y)
            if g.pulseCooldown <= 0 then
                g.pulseCooldown = .8
                self:effect("pulse", p.x, p.y)
                for _, e in ipairs(self:entities()) do
                    if e.enemy and e.health.current > 0 and math.max(math.abs(e.grid.x - p.x), math.abs(e.grid.y - p.y)) <= 1 then
                        self:damage(e, self.upgrades.guardPulse and 3 or 2, p.x, p.y)
                    end
                end
            end
            if g.energy <= 0 then g.exhausted, g.active = true, false end
            return false
        end
    end
    if hp.immune > 0 then return false end
    hp.current = math.max(0, hp.current - amount)
    if target.player then hp.immune = .36 end
    self:effect("hit", target.grid.x, target.grid.y, amount)
    if hp.current == 0 then
        if target.player then self.state, self.deathCause = "dead", "combat"; self:clearIntents()
        else self.kills = self.kills + 1; self:effect("death", target.grid.x, target.grid.y); target:destroy() end
    end
    return true
end

function Game:chooseReward(choice)
    return Progression.choose(self, choice)
end

function Game:update(dt, input)
    if self.state ~= "playing" or self.reward then return end
    self.time = self.time + dt
    self.messageTime = math.max(0, self.messageTime - dt)
    self.input = input or {dx = 0, dy = 0, guard = false, events = {}}
    self.world:emit("update", dt)
    if self.state ~= "playing" or self.player.motion.falling then return end
    if not self.room.cleared and self:enemyCount() == 0 and self:targetCount() == 0 then
        self.room.cleared = true
        for _, e in ipairs(self:entities()) do
            if e.projectile and e.team.value == "enemy" then e:destroy() end
            if e.resonator and e.resonator.state == "primed" then
                e.resonator.state, e.health.current = "spent", 0
                self:effect("disarm", e.grid.x, e.grid.y)
                e:destroy()
            end
        end
        self:effect("clear", self.player.grid.x, self.player.grid.y)
        self.player.motion.bufferTime = 0
        self:cancelCharge()
        if self.practice then self:notify("Câmara livre: explore o cenário e atravesse a saída dourada para concluir.")
        elseif self.room.final then self:notify("O Guardião caiu. Atravesse o portal dourado para concluir o andar.")
        elseif self.room.challenge then
            if not self.room.lootTaken then
                self.room.lootTaken = true
                local amount = self.room.kind == "secret" and 4 or 6
                self.gold = self.gold + amount
                if self.room.kind == "supersecret" then
                    self.player.health.current = math.min(10, self.player.health.current + 2)
                end
                self:notify("Desafio concluído: +" .. amount .. " ouro e um eco.")
            end
            if not self.room.rewardTaken then Progression.offer(self) end
        elseif self.room.kind == "start" or self.room.kind == "combat" then Progression.offer(self) end
        if not self.practice and (self.room.kind == "start" or self.room.kind == "combat" or self.room.final)
            and not self.room.goldTaken then
            self.room.goldTaken = true
            self.gold = self.gold + 2
        end
    end
    if self.player.motion.remaining == 0 and not self.reward then
        local p = self.player.grid
        for _, door in ipairs(self.room.doors) do
            if p.x == door.x and p.y == door.y and self:canLeave(door) then
                if door.finish then self.state = "won" else self:enter(door.to, door.arrival) end
                break
            end
        end
    end
end
return Game
