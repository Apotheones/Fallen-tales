local Concord = require("vendor.concord")
local Rooms = require("src.rooms")
local Environment = require("src.environment")
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
    for _, event in ipairs(input.events) do
        if event.kind == "face" then f.dx, f.dy = event.dx, event.dy
        elseif event.kind == "release" then m.blocked[Rooms.key(event.dx, event.dy)] = nil
        elseif event.kind == "step" and math.abs(event.dx) + math.abs(event.dy) == 1 and (event.dx == 0 or event.dy == 0) then
            m.blocked[Rooms.key(event.dx, event.dy)] = nil
            m.bufferDx, m.bufferDy, m.bufferTime = event.dx, event.dy, .18
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
    if not tapped and m.blocked[Rooms.key(mx, my)] then return end
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
local function cardinal(dx, dy)
    if math.abs(dx) >= math.abs(dy) then return dx >= 0 and 1 or -1, 0 end
    return 0, dy >= 0 and 1 or -1
end
local function aligned(a, b) return a.x == b.x or a.y == b.y end
local function visible(room, a, b)
    if not aligned(a, b) then return false end
    local dx, dy = cardinal(b.x - a.x, b.y - a.y)
    local cells = Rooms.line(room, a.x, a.y, dx, dy, math.abs(b.x - a.x) + math.abs(b.y - a.y))
    local last = cells[#cells]
    return last and last.x == b.x and last.y == b.y
end
function Systems.Enemy:update(dt)
    local g = game(self)
    if g.state ~= "playing" then return end
    for _, e in ipairs(self.enemies) do
        if e.health.current > 0 and not e.motion.falling and e.enemy.kind ~= "warden" then self:tick(g, e, dt) end
    end
end
function Systems.Enemy:tick(g, e, dt)
    local a, p, target = e.enemy, e.grid, g.player.grid
    a.timer = math.max(0, a.timer - dt)
    if a.state == "warn" and a.timer == 0 then
        if a.kind == "ranger" then
            g:shoot(e, a.dx, a.dy, 2, .13, #a.cells, "bolt")
            a.state, a.timer = "recover", .75
        else a.state, a.timer, a.dashIndex = "dash", 0, 0 end
    elseif a.state == "dash" and a.timer == 0 and e.motion.remaining == 0 then
        a.dashIndex = a.dashIndex + 1
        local cell = a.cells[a.dashIndex]
        if not cell then a.state, a.timer = "recover", .85; return end
        if cell.impact or Rooms.blocksAttack(g.room, cell.x, cell.y) then
            Environment.impact(g, cell.x, cell.y, a.dx, a.dy)
            a.state, a.timer = "recover", .85
            return
        end
        local occupant = g:occupant(cell.x, cell.y, e)
        if occupant then
            if occupant.player and occupant.grid.x == cell.x and occupant.grid.y == cell.y then
                g:damage(occupant, 2, p.x, p.y)
            elseif occupant.resonator then g:damage(occupant, 2, p.x, p.y)
            end
            a.state, a.timer = "recover", .85
        elseif not g:move(e, a.dx, a.dy, .065, true) then a.state, a.timer = "recover", .85
        else a.timer = .065 end
    elseif a.state == "recover" and a.timer == 0 then
        a.state, a.timer, a.cells = "seek", .12, {}
    elseif a.state == "seek" and a.timer == 0 and e.motion.remaining == 0 then
        local distance = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if visible(g.room, p, target) and (a.kind == "ranger" or distance <= 4) then
            a.dx, a.dy = cardinal(target.x - p.x, target.y - p.y)
            a.cells = a.kind == "ranger" and Rooms.line(g.room, p.x, p.y, a.dx, a.dy, math.max(g.room.w, g.room.h))
                or Environment.dashLine(g, p.x, p.y, a.dx, a.dy, 4)
            a.state, a.timer, a.warningDuration = "warn", a.kind == "ranger" and 1.05 or .85, a.kind == "ranger" and 1.05 or .85
            e.facing.dx, e.facing.dy = a.dx, a.dy
            g:effect("warn", p.x, p.y)
        else
            local path = Rooms.path(g.room, p.x, p.y, function(x, y)
                local d = math.abs(x - target.x) + math.abs(y - target.y)
                if a.kind == "ranger" then return d >= 3 and d <= 8 and visible(g.room, {x = x, y = y}, target) end
                return d == 1 or (d <= 4 and visible(g.room, {x = x, y = y}, target))
            end, function(x, y) return not g:walkable(x, y, e) end)
            if path and path[1] then
                local dx, dy = path[1].x - p.x, path[1].y - p.y
                e.facing.dx, e.facing.dy = dx, dy
                g:move(e, dx, dy)
            end
            a.timer = a.kind == "ranger" and .34 or .28
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
