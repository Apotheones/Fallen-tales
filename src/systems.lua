local Concord = require("vendor.concord")
local Rooms = require("src.rooms")
local Environment = require("src.environment")
local Enemies = require("src.enemies")
local Systems = {}
local function game(system) return system:getWorld():getResource("game") end

Systems.Movement = Concord.system({actors = {"grid", "motion", "health"}})
function Systems.Movement:flush() end
function Systems.Movement:update(dt)
    local g = game(self)
    for _, e in ipairs(self.actors) do
        e.health.immune = math.max(0, e.health.immune - dt)
        e.motion.bufferTime = math.max(0, e.motion.bufferTime - dt)
        if e.motion.remaining > 0 then
            e.motion.remaining = math.max(0, e.motion.remaining - dt)
            if e.motion.remaining == 0 then
                if e.motion.falling then g:killFatal(e, "hole")
                else g:effect("land", e.grid.x, e.grid.y) end
            end
        end
    end
end

Systems.Player = Concord.system({players = {"player", "weapon", "guard", "grid"}})
function Systems.Player:update(dt)
    local g = game(self)
    local e, input = g.player, g.input
    local w, guard, f = e.weapon, e.guard, e.facing
    if g.state ~= "playing" or e.motion.falling then g:clearIntents(); return end
    local m = e.motion
    w.mineTimer = math.max(0, w.mineTimer - dt)
    if w.state == "action" then
        w.action = math.max(0, w.action - dt)
        if w.action == 0 then w.state = "empty" end
    end
    guard.pulseCooldown = math.max(0, guard.pulseCooldown - dt)
    if not input.guard then
        guard.energy = math.min(guard.max, guard.energy + dt * .65)
        if guard.energy >= .5 then guard.exhausted = false end
    end
    guard.active = input.guard and not guard.exhausted and guard.energy > 0 and w.state ~= "action" and w.mineTimer == 0
    if guard.active then
        g:cancelCharge()
        guard.energy = math.max(0, guard.energy - dt)
        if guard.energy == 0 then guard.active, guard.exhausted = false, true end
    end
    -- One press only turns; a press in the faced direction walks. A turned direction
    -- stays locked briefly, so a quick tap aims without stepping while keeping the
    -- key held starts walking after a short delay.
    local wasX, wasY = f.dx, f.dy
    for _, event in ipairs(input.events) do
        if event.kind == "face" then
            wasX, wasY = f.dx, f.dy
            f.dx, f.dy = event.dx, event.dy
        elseif event.kind == "release" then m.blocked[Rooms.key(event.dx, event.dy)] = nil
        elseif event.kind == "interact" then g:interact()
        elseif event.kind == "step" and math.abs(event.dx) + math.abs(event.dy) == 1 and (event.dx == 0 or event.dy == 0) then
            local key = Rooms.key(event.dx, event.dy)
            if wasX == event.dx and wasY == event.dy then
                m.blocked[key] = nil
                m.bufferDx, m.bufferDy, m.bufferTime = event.dx, event.dy, .18
            else m.blocked[key] = g.time + .10 end
        elseif event.kind == "charge" and w.state == "empty" and not guard.active and w.mineTimer == 0 then
            w.state, w.charge, w.triggerHeld = "charging", 0, true
        elseif event.kind == "fire" then
            if w.triggerHeld and w.state == "ready" and not guard.active and w.mineTimer == 0 then
                w.triggerHeld = false
                self:fire(g, e)
            else g:cancelCharge() end
        end
    end
    if w.state == "charging" then
        local definition = g:weaponStats()
        w.charge = math.min(definition.chargeTime, w.charge + dt * definition.chargeSpeed)
        if w.charge >= definition.chargeTime then
            w.state = "ready"; g:effect("ready", e.grid.x, e.grid.y)
        end
    end
    local mx, my = input.dx, input.dy
    local tapped = m.bufferTime > 0
    if tapped then mx, my = m.bufferDx, m.bufferDy end
    local lock = not tapped and m.blocked[Rooms.key(mx, my)]
    if lock == true or type(lock) == "number" and lock > g.time then return end
    if not g.reward and m.remaining == 0 and w.mineTimer == 0 and math.abs(mx) + math.abs(my) == 1 then
        local x, y = e.grid.x + mx, e.grid.y + my
        if Rooms.blocksAttack(g.room, x, y) then
            -- Holding movement never mines, even when the next simulation tick is free.
            if not tapped or guard.active or w.state == "action" then return end
            m.bufferTime, m.blocked[Rooms.key(mx, my)] = 0, true
            if Environment.mine(g, x, y, mx, my) then
                g:cancelCharge()
                w.mineTimer, w.mineDx, w.mineDy = Environment.constants.mineRecovery, mx, my
            end
        else
            g:move(e, mx, my)
            m.bufferTime = 0
        end
    end
end

function Systems.Player:fire(g, e)
    local w, f, p = e.weapon, e.facing, e.grid
    if g.state ~= "playing" or e.motion.falling or w.mineTimer > 0 then return end
    local d = g:weaponStats()
    w.state, w.charge, w.action = "action", 0, .2
    g:shoot(e, f.dx, f.dy, d.damage, d.interval, nil, "bow")
end

Systems.Enemy = Concord.system({enemies = {"enemy", "grid", "motion", "health"}})
function Systems.Enemy:update(dt)
    local g = game(self)
    if g.state ~= "playing" then return end
    for _, e in ipairs(self.enemies) do
        local def = Enemies[e.enemy.kind]
        if def and not def.boss and e.health.current > 0 and not e.motion.falling then
            Enemies.step(g, e, dt)
        end
    end
end
Systems.Projectile = Concord.system({shots = {"projectile", "grid", "team"}})
function Systems.Projectile:update(dt)
    local g = game(self)
    if g.state ~= "playing" then return end
    for _, e in ipairs(self.shots) do
        local s, p = e.projectile, e.grid
        s.clock = s.clock + dt
        while s.clock >= s.interval do
            s.clock, s.steps = s.clock - s.interval, s.steps + 1
            p.x, p.y = p.x + s.dx, p.y + s.dy
            if Rooms.blocksAttack(g.room, p.x, p.y) then e:destroy(); break end
            local hit = false
            for _, target in ipairs(g:entities()) do
                if target.health and target.team.value ~= e.team.value and target.health.current > 0
                    and target.grid.x == p.x and target.grid.y == p.y then
                    g:damage(target, s.damage, p.x - s.dx, p.y - s.dy, e.team.value == "player" and s.kind or nil)
                    hit = true; break
                end
            end
            local piercing = s.kind == "bow" and e.team.value == "player" and g.upgrades.bowPierce
            if (hit and not piercing) or (s.range and s.steps >= s.range) then e:destroy(); break end
        end
    end
end

Systems.Damage = Concord.system({dead = {"health"}})
function Systems.Damage:update()
    local g = game(self)
    if g.player.health.current == 0 then g.state = "dead" end
end
return Systems
