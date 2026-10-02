local Concord = require("vendor.concord")

Concord.component("grid", function(c, x, y) c.x, c.y = x, y end)
Concord.component("motion", function(c, duration)
    c.duration, c.remaining = duration or .18, 0
    c.fromX, c.fromY = 0, 0
    c.bufferDx, c.bufferDy, c.bufferTime = 0, 0, 0
    c.falling, c.blocked = false, {}
end)
Concord.component("facing", function(c, dx, dy) c.dx, c.dy = dx or 1, dy or 0 end)
Concord.component("health", function(c, hp) c.current, c.max, c.immune = hp, hp, 0 end)
Concord.component("team", function(c, value) c.value = value end)
Concord.component("player")
Concord.component("target", function(c, data) c.data = data end)
Concord.component("enemy", function(c, kind)
    c.kind, c.state, c.timer, c.cells = kind, "seek", .9, {}
    c.dx, c.dy, c.dashIndex = 0, 0, 0
end)
Concord.component("weapon", function(c)
    c.name, c.state, c.charge, c.action = "bow", "empty", 0, 0
    c.triggerHeld = false
    c.mineTimer, c.mineDx, c.mineDy = 0, 0, 0
end)
Concord.component("guard", function(c)
    c.energy, c.max, c.active, c.exhausted, c.pulseCooldown = 1.6, 1.6, false, false, 0
end)
Concord.component("projectile", function(c, dx, dy, damage, interval, range, kind)
    c.dx, c.dy, c.damage, c.interval = dx, dy, damage, interval
    c.range, c.kind, c.clock, c.steps = range, kind, 0, 0
end)
Concord.component("npc", function(c, id) c.id = id end)
Concord.component("hazard", function(c, cells, fuse, damage, source)
    c.cells, c.timer, c.duration = cells, fuse, fuse
    c.damage, c.source = damage or 2, source
end)
return Concord
