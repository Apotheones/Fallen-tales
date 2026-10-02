-- Turn-based battle arena for the campaign (docs/COMBATE_PROPOSTA.md).
-- Stage 1 scope is the plumbing only: entering an encounter snapshots the
-- exploration point, loads a separate grid arena and ESC returns. Intentions,
-- actions and the Sentinela arrive in stage 2.
local Region = require('src.region')
local Battle = {}; Battle.__index = Battle

local arenaDef = {
    id = 'arena', uid = 90, name = 'ARENA', w = 13, h = 11,
    spawn = {x = 6, y = 8},
    carve = {{x = 3, y = 3, w = 7, h = 6}},
    pillars = {{x = 4, y = 4}, {x = 8, y = 4}},
}

function Battle.new(campaign, encounterId, kind)
    local self = setmetatable({}, Battle)
    self.encounterId = encounterId
    self.snapshot = {region = campaign.map.id,
        x = campaign.player.grid.x, y = campaign.player.grid.y}
    self.room = Region.build(arenaDef)
    self.player = {player = true,
        grid = {x = self.room.spawn.x, y = self.room.spawn.y},
        facing = {dx = 0, dy = -1}, moving = false,
        motion = {remaining = 0, duration = .16, fromX = self.room.spawn.x, fromY = self.room.spawn.y},
        health = {current = 10, max = 10},
        weapon = {state = 'empty', charge = 0, action = 0, mineTimer = 0},
        guard = {active = false}}
    self.enemies = {{
        enemy = {id = encounterId, kind = kind or 'dasher', state = 'idle', timer = 0},
        grid = {x = 6, y = 4}, facing = {dx = 0, dy = 1},
        motion = {remaining = 0, duration = .16, fromX = 6, fromY = 4},
        health = {current = 3, max = 3},
    }}
    return self
end

function Battle:update(dt, campaign, input) end

return Battle
