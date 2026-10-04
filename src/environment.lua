local Concord = require("vendor.concord")
local Rooms = require("src.rooms")
local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
Concord.component("resonator", function(c)
    c.state, c.timer, c.cells, c.walls = "idle", 0, {}, {}
end)
local Environment = Concord.system({crystals = {"resonator", "grid", "health"}, hazards = {"hazard", "grid"}})
Environment.constants = {pickaxes = 20, hits = 3, fallLength = 5, mineRecovery = .16, warning = .62, crushFatal = true}

local function cardinal(dx, dy) return math.abs(dx) + math.abs(dy) == 1 and (dx == 0 or dy == 0) end
local function changed(room) room.revision = (room.revision or 0) + 1 end
local function mineable(cell)
    return cell and not cell.protected and (cell.piece == "wall" or cell.piece == "pillar" or cell.piece == "fallen")
end

function Environment.fallCells(room, x, y, dx, dy)
    local cells = {}
    if not cardinal(dx, dy) then return cells end
    for _ = 1, Environment.constants.fallLength do
        x, y = x + dx, y + dy
        local cell = Rooms.cell(room, x, y)
        if not cell or cell.piece or cell.passage then break end
        cells[#cells + 1] = {x = x, y = y, hole = cell.ground == "hole"}
        if cell.ground == "hole" then break end
    end
    return cells
end

function Environment.dashLine(game, x, y, dx, dy, length)
    local cells = {}
    for _ = 1, length do
        x, y = x + dx, y + dy
        local cell = Rooms.cell(game.room, x, y)
        if not cell then break end
        if Rooms.blocksAttack(game.room, x, y) then
            if mineable(cell) then cells[#cells + 1] = {x = x, y = y, impact = true} end
            break
        end
        cells[#cells + 1] = {x = x, y = y, hole = cell.ground == "hole"}
        if cell.ground == "hole" then break end
    end
    return cells
end

function Environment.breakWall(game, x, y)
    local cell = Rooms.cell(game.room, x, y)
    if not mineable(cell) or cell.piece == "pillar" then return false end
    cell.piece, cell.state, cell.hits = nil, "broken", 0
    changed(game.room)
    if cell.secretDoor then game:openSecretDoor(cell.secretDoor) end
    game:effect("wallBreak", x, y)
    return true
end

function Environment.impact(game, x, y, dx, dy)
    local cell = Rooms.cell(game.room, x, y)
    if not mineable(cell) then return false end
    if cell.piece ~= "pillar" then return Environment.breakWall(game, x, y) end
    if cell.state == "falling" or not cardinal(dx, dy) then return false end
    cell.state, cell.timer, cell.duration = "falling", Environment.constants.warning, Environment.constants.warning
    cell.deadline = (game.time or 0) + cell.duration
    cell.dx, cell.dy = dx, dy
    cell.cells = Environment.fallCells(game.room, x, y, dx, dy)
    changed(game.room)
    game:effect("pillarWarn", x, y, cell.cells)
    return true
end

function Environment.mine(game, x, y, dx, dy)
    local player, cell = game.player, Rooms.cell(game.room, x, y)
    if not cardinal(dx, dy) or not player or player.health.current <= 0 or
        player.grid.x + dx ~= x or player.grid.y + dy ~= y or
        not mineable(cell) or cell.state == "falling" then return false end
    if (game.pickaxes or 0) <= 0 then
        game:effect("mineEmpty", x, y)
        game:notify("Sem picaretas")
        return false
    end
    cell.hits = (cell.hits or 0) + 1
    changed(game.room)
    game:effect("mineHit", x, y, cell.hits)
    if cell.hits == Environment.constants.hits then
        game.pickaxes = game.pickaxes - 1
        Environment.impact(game, x, y, dx, dy)
    end
    return true
end

local function fall(game, pillar)
    local room = game.room
    pillar.piece, pillar.state, pillar.hits = nil, "fallen", 0
    local landed = {}
    -- Rechecking can shorten this frozen warning, but cannot extend its footprint.
    for _, announced in ipairs(pillar.cells) do
        local cell = Rooms.cell(room, announced.x, announced.y)
        if not cell or cell.piece or cell.passage or cell.ground == "hole" then break end
        local occupied = false
        for _, entity in ipairs(game:entities()) do
            local p, m = entity.grid, entity.motion
            if entity.health and entity.health.current > 0 and m and
                ((p.x == cell.x and p.y == cell.y) or
                (m.remaining > 0 and m.fromX == cell.x and m.fromY == cell.y)) then
                if Environment.constants.crushFatal then game:killFatal(entity, "crushed") else occupied = true end
            end
        end
        if not occupied then
            cell.piece, cell.state, cell.hits = "fallen", "idle", 0
            cell.dx, cell.dy = pillar.dx, pillar.dy
            landed[#landed + 1] = {x = cell.x, y = cell.y}
        end
    end
    changed(room)
    game:effect("pillarFall", pillar.x, pillar.y, landed)
end

local function blastArea(room, x, y, frozenCells, frozenWalls)
    local cells, walls, allowed, boundary = {}, {}, nil, nil
    if frozenCells then
        allowed, boundary = {}, {}
        for _, cell in ipairs(frozenCells) do allowed[Rooms.key(cell.x, cell.y)] = true end
        for _, cell in ipairs(frozenWalls) do boundary[Rooms.key(cell.x, cell.y)] = true end
    end
    local queue, seen, head = {{x = x, y = y, distance = 0}}, {[Rooms.key(x, y)] = true}, 1
    while head <= #queue do
        local node = queue[head]; head = head + 1
        if Rooms.floor(room, node.x, node.y) then
            cells[#cells + 1] = {x = node.x, y = node.y}
            if node.distance < 2 then
                for _, d in ipairs(directions) do
                    local nx, ny = node.x + d[1], node.y + d[2]
                    local key, cell = Rooms.key(nx, ny), Rooms.cell(room, nx, ny)
                    if not seen[key] and cell and (not allowed or allowed[key] or boundary[key]) then
                        seen[key] = true
                        if mineable(cell) then
                            walls[#walls + 1] = {x = nx, y = ny, dx = d[1], dy = d[2]}
                        elseif Rooms.floor(room, nx, ny) and (not boundary or not boundary[key]) then
                            queue[#queue + 1] = {x = nx, y = ny, distance = node.distance + 1}
                        end
                    end
                end
            end
        end
    end
    return cells, walls
end

function Environment.prime(game, entity)
    local r, p = entity.resonator, entity.grid
    if r.state ~= "idle" then return false end
    r.state, r.timer = "primed", Environment.constants.warning
    r.cells, r.walls = blastArea(game.room, p.x, p.y)
    game:effect("prime", p.x, p.y)
    return true
end

function Environment:update(dt)
    local game, falls = self:getWorld():getResource("game"), {}
    for _, cell in pairs(game.room.tiles) do
        if cell.piece == "pillar" and cell.state == "falling" then
            cell.timer = math.max(0, cell.timer - dt)
            if cell.timer == 0 then falls[#falls + 1] = cell end
        end
    end
    table.sort(falls, function(a, b)
        if a.deadline ~= b.deadline then return a.deadline < b.deadline end
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)
    for _, cell in ipairs(falls) do fall(game, cell) end
    for _, entity in ipairs(self.hazards) do
        local z, p = entity.hazard, entity.grid
        z.timer = math.max(0, z.timer - dt)
        if z.timer == 0 then
            game:effect("markBlast", p.x, p.y, z.cells)
            for _, cell in ipairs(z.cells) do
                for _, target in ipairs(game:entities()) do
                    if target ~= entity and target.health and target.health.current > 0
                        and target.grid.x == cell.x and target.grid.y == cell.y then
                        -- Hazard de área não usa escudo nem armadura de face:
                        -- a fonte é a própria célula atingida (mesmo contrato
                        -- do jato do Ivo — sem direção para bloquear).
                        game:damage(target, z.damage, cell.x, cell.y)
                    end
                end
            end
            entity:destroy()
        end
    end
    for _, entity in ipairs(self.crystals) do
        local r, p = entity.resonator, entity.grid
        if r.state == "primed" and entity.health.current > 0 then
            r.timer = math.max(0, r.timer - dt)
            if r.timer == 0 then
                local cells, walls = blastArea(game.room, p.x, p.y, r.cells, r.walls)
                r.state, entity.health.current = "spent", 0
                game:effect("blast", p.x, p.y, cells)
                for _, cell in ipairs(cells) do
                    for _, target in ipairs(game:entities()) do
                        if target ~= entity and target.health and target.health.current > 0 and
                            target.grid.x == cell.x and target.grid.y == cell.y then
                            -- Mesma regra do hazard de área: explosão não tem
                            -- direção — a fonte é a célula do próprio alvo.
                            game:damage(target, 3, cell.x, cell.y)
                        end
                    end
                end
                for _, cell in ipairs(walls) do Environment.impact(game, cell.x, cell.y, cell.dx, cell.dy) end
                entity:destroy()
            end
        end
    end
end
return Environment
