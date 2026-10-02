local Concord = require("vendor.concord")
local Enemies = require("src.enemies")
local Boss = Concord.system({wardens = {"enemy", "grid", "motion", "health"}})

function Boss:update(dt)
    local g = self:getWorld():getResource("game")
    if g.state ~= "playing" then return end
    for _, entity in ipairs(self.wardens) do
        local def = Enemies[entity.enemy.kind]
        if def and def.boss and entity.health.current > 0 and not entity.motion.falling then
            Enemies.step(g, entity, dt)
        end
    end
end

return Boss
