local Concord = require("vendor.concord")
local Rooms = require("src.rooms")
local Environment = require("src.environment")
local Boss = Concord.system({wardens = {"enemy", "grid", "motion", "health"}})
local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

local function aligned(room, from, target)
    if from.x ~= target.x and from.y ~= target.y then return false end
    local dx = target.x == from.x and 0 or (target.x > from.x and 1 or -1)
    local dy = target.y == from.y and 0 or (target.y > from.y and 1 or -1)
    if dx == 0 and dy == 0 then return false end
    local cells = Rooms.line(room, from.x, from.y, dx, dy,
        math.abs(target.x - from.x) + math.abs(target.y - from.y))
    local last = cells[#cells]
    return last and last.x == target.x and last.y == target.y, dx, dy
end

function Boss:update(dt)
    local g = self:getWorld():getResource("game")
    if g.state ~= "playing" then return end
    for _, entity in ipairs(self.wardens) do
        if entity.enemy.kind == "warden" and entity.health.current > 0 and not entity.motion.falling then self:tick(g, entity, dt) end
    end
end

function Boss:warn(g, e, mode, dx, dy)
    local a, p = e.enemy, e.grid
    a.mode, a.dx, a.dy, a.cells, a.ranges = mode, dx, dy, {}, {}
    if mode == "cross" then
        for i, d in ipairs(directions) do
            local cells = Rooms.line(g.room, p.x, p.y, d[1], d[2], math.max(g.room.w, g.room.h))
            a.ranges[i] = #cells
            for _, cell in ipairs(cells) do
                a.cells[#a.cells + 1] = cell
            end
        end
    else a.cells = Environment.dashLine(g, p.x, p.y, dx, dy, 4) end
    a.warningDuration = a.phase2 and .95 or 1.15
    a.state, a.timer = "warn", a.warningDuration
    e.facing.dx, e.facing.dy = dx, dy
    g:effect("warn", p.x, p.y)
end

function Boss:recover(a)
    a.state, a.timer, a.cells = "recover", a.phase2 and .7 or .95, {}
    a.nextMode = a.mode == "cross" and "dash" or "cross"
end

function Boss:tick(g, e, dt)
    local a, p, target = e.enemy, e.grid, g.player.grid
    if not a.phase2 and e.health.current <= e.health.max * .5 then
        a.phase2 = true
        a.frontalArmor = false
        g:notify("O Guardião rompeu o selo. Avisos mais rápidos: procure os espaços vazios!")
        g:effect("bossPhase", p.x, p.y)
    end
    a.timer = math.max(0, a.timer - dt)
    if a.state == "warn" and a.timer == 0 then
        if a.mode == "cross" then
            for i, d in ipairs(directions) do
                if a.ranges[i] > 0 then g:shoot(e, d[1], d[2], 2, .11, a.ranges[i], "bolt") end
            end
            self:recover(a)
        else a.state, a.timer, a.dashIndex = "dash", 0, 0 end
    elseif a.state == "dash" and a.timer == 0 and e.motion.remaining == 0 then
        a.dashIndex = a.dashIndex + 1
        local cell = a.cells[a.dashIndex]
        if not cell then self:recover(a); return end
        if cell.impact or Rooms.blocksAttack(g.room, cell.x, cell.y) then
            Environment.impact(g, cell.x, cell.y, a.dx, a.dy)
            self:recover(a)
            return
        end
        local occupant = g:occupant(cell.x, cell.y, e)
        if occupant then
            if occupant.player and occupant.grid.x == cell.x and occupant.grid.y == cell.y then g:damage(occupant, 2, p.x, p.y)
            elseif occupant.resonator then g:damage(occupant, 2, p.x, p.y) end
            self:recover(a)
        elseif not g:move(e, a.dx, a.dy, .075, true) then self:recover(a)
        else a.timer = .075 end
    elseif a.state == "recover" and a.timer == 0 then
        a.state, a.timer, a.cells = "seek", .18, {}
    elseif a.state == "seek" and a.timer == 0 and e.motion.remaining == 0 then
        local mode = a.nextMode or "cross"
        local visible, dx, dy = aligned(g.room, p, target)
        local distance = math.abs(p.x - target.x) + math.abs(p.y - target.y)
        if visible and (mode == "cross" or distance <= 4) then self:warn(g, e, mode, dx, dy)
        else
            local path = Rooms.path(g.room, p.x, p.y, function(x, y)
                local distanceToPlayer = math.abs(x - target.x) + math.abs(y - target.y)
                return (mode == "cross" or distanceToPlayer <= 4) and aligned(g.room, {x = x, y = y}, target)
            end, function(x, y) return not g:walkable(x, y, e) end)
            if path and path[1] then
                local mx, my = path[1].x - p.x, path[1].y - p.y
                e.facing.dx, e.facing.dy = mx, my
                g:move(e, mx, my, .24)
            end
            a.timer = a.phase2 and .24 or .32
        end
    end
end

return Boss
