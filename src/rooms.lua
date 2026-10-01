local Rooms = {tile = 40}
local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

function Rooms.key(x, y) return x .. ":" .. y end
function Rooms.inside(room, x, y) return x >= 1 and y >= 1 and x <= room.w and y <= room.h end
function Rooms.cell(room, x, y) return room.tiles[Rooms.key(x, y)] end
function Rooms.enterable(room, x, y)
    local cell = Rooms.cell(room, x, y)
    return cell ~= nil and (cell.piece == nil or cell.piece == "portal")
end
function Rooms.floor(room, x, y)
    local cell = Rooms.cell(room, x, y)
    return Rooms.enterable(room, x, y) and cell.ground == "floor"
end
function Rooms.blocksAttack(room, x, y) return not Rooms.enterable(room, x, y) end

-- Generation validation and voluntary combat navigation share safe cardinal paths.
function Rooms.path(room, sx, sy, goal, blocked)
    if not Rooms.floor(room, sx, sy) then return end
    local queue, head = {{x = sx, y = sy}}, 1
    local seen = {[Rooms.key(sx, sy)] = true}
    while head <= #queue do
        local node = queue[head]; head = head + 1
        if goal(node.x, node.y) then
            local path = {}
            while node.parent do table.insert(path, 1, node); node = node.parent end
            return path
        end
        for _, d in ipairs(directions) do
            local x, y = node.x + d[1], node.y + d[2]
            local key = Rooms.key(x, y)
            if not seen[key] and Rooms.floor(room, x, y) and (not blocked or not blocked(x, y)) then
                seen[key] = true
                queue[#queue + 1] = {x = x, y = y, parent = node}
            end
        end
    end
end

function Rooms.line(room, x, y, dx, dy, length)
    local cells = {}
    for _ = 1, length do
        x, y = x + dx, y + dy
        if Rooms.blocksAttack(room, x, y) then break end
        cells[#cells + 1] = {x = x, y = y}
    end
    return cells
end

local names = {"CÂMARA DAS CORRENTES", "GALERIA DAS FENDAS", "PÁTIO DA RESSONÂNCIA"}
local specialNames = {boss = "SANTUÁRIO DOS ECOS", refuge = "REFÚGIO", shop = "LOJA DO VIAJANTE",
    treasure = "SALA DO TESOURO", secret = "SALA SECRETA", supersecret = "RECANTO SUPERSECRETO"}
local sides = {"east", "west", "south", "north"}
local opposite = {east = "west", west = "east", south = "north", north = "south"}
local layouts = {
    {
        walls = {{1, 0}, {1, 1}, {2, 1}},
        pillar = {-2, -1}, hole = {2, -2}, crystals = {{-1, 1}, {3, -2}},
        tactic = "Três toques abrem paredes; derrube o pilar e use o desvio.",
    },
    {
        walls = {{-2, -2}, {-2, -1}, {3, 0}, {3, 1}},
        pillar = {0, 1}, hole = {1, -1}, crystals = {{-3, 1}, {2, -2}},
        tactic = "Abra atalhos ou preserve cobertura. Buracos interrompem investidas.",
    },
    {
        walls = {{1, -2}, {2, -2}, {-3, -1}, {-3, 0}},
        pillar = {-2, 1}, hole = {3, -1}, crystals = {{0, -1}, {3, 0}},
        tactic = "Cristais e dashes quebram peças sem gastar suas picaretas.",
    },
}

local function piece(room, x, y, kind, protected)
    local cell = Rooms.cell(room, x, y)
    cell.piece, cell.protected, cell.hits = kind, protected == true, 0
    if kind == "pillar" then cell.state = "idle" end
    return cell
end

local function doorway(room, side)
    local x, y = math.ceil(room.w / 2), math.ceil(room.h / 2)
    if side == "east" then x = room.w elseif side == "west" then x = 1
    elseif side == "north" then y = 1 else y = room.h end
    return x, y
end

local function practiceLayout(room)
    room.name = "CÂMARA DE PRÁTICA"
    -- The chamber opens onto a loop: mining the east wall is a shortcut, never a toll.
    for y = 3, 8 do piece(room, 5, y, "wall") end
    piece(room, 8, 4, "pillar")
    Rooms.cell(room, 11, 8).ground = "hole"
    room.enemies = {{x = 10, y = 6, kind = "dasher"}, {x = 13, y = 4, kind = "ranger"}}
    room.crystals = {{x = 4, y = 8}, {x = 14, y = 7}}
    room.tactic = "Parede a leste: 3 toques. Pilar ao norte: 5 blocos. Buraco ao sul: desvie. Saia pelo portal."
end

local function portal(room, x, y, door)
    local cell = piece(room, x, y, door.hidden and "wall" or "portal", not door.hidden)
    if door.hidden then cell.secretDoor = door end
    room.doors[#room.doors + 1] = door
end

local function neighbours(map, x, y)
    local count = 0
    for _, d in ipairs(directions) do if map[Rooms.key(x + d[1], y + d[2])] then count = count + 1 end end
    return count
end

local function grow(rng, count, forced)
    local start = {id = 1, mapX = 0, mapY = 0, distance = 0, degree = 0, kind = "start"}
    local nodes, map, head = {start}, {[Rooms.key(0, 0)] = start}, 1
    while head <= #nodes and #nodes < count do
        local parent = nodes[head]; head = head + 1
        for _, d in ipairs(directions) do
            local x, y = parent.mapX + d[1], parent.mapY + d[2]
            local key = Rooms.key(x, y)
            if #nodes < count and not map[key] and neighbours(map, x, y) == 1 and
                (forced or rng:random() < .5) then
                local node = {id = #nodes + 1, mapX = x, mapY = y, distance = parent.distance + 1,
                    degree = 1, kind = "combat"}
                nodes[#nodes + 1], map[key] = node, node
                parent.degree = parent.degree + 1
            end
        end
    end
    return nodes, map
end

local function assignKinds(nodes)
    local ends = {}
    for i = 2, #nodes do if nodes[i].degree == 1 then ends[#ends + 1] = nodes[i] end end
    table.sort(ends, function(a, b)
        if a.distance ~= b.distance then return a.distance > b.distance end
        return a.id < b.id
    end)
    if #ends < 3 or ends[1].distance < 2 then return end
    ends[1].kind, ends[2].kind, ends[3].kind = "boss", "treasure", "shop"
    if ends[4] then ends[4].kind = "refuge" end
    return ends[1]
end

local function secretSites(nodes, map, boss)
    local candidates, seen = {}, {}
    for _, node in ipairs(nodes) do for _, d in ipairs(directions) do
        local x, y = node.mapX + d[1], node.mapY + d[2]
        local key = Rooms.key(x, y)
        if not map[key] and not seen[key] then
            seen[key] = true
            local count = neighbours(map, x, y)
            if count >= 2 and math.abs(x - boss.mapX) + math.abs(y - boss.mapY) > 1 then
                candidates[#candidates + 1] = {mapX = x, mapY = y, degree = count}
            end
        end
    end end
    table.sort(candidates, function(a, b)
        if a.degree ~= b.degree then return a.degree > b.degree end
        if a.mapY ~= b.mapY then return a.mapY < b.mapY end
        return a.mapX < b.mapX
    end)
    for i, first in ipairs(candidates) do for j = i + 1, #candidates do
        local second = candidates[j]
        if math.abs(first.mapX - second.mapX) + math.abs(first.mapY - second.mapY) > 1 then
            return first, second
        end
    end end
end

local function floorplan(rng, count)
    local nodes, map, first, second
    -- ponytail: after 100 retries, forced BFS uses four arms; increase retries if large floors need more variety.
    for attempt = 1, 101 do
        nodes, map = grow(rng, count, attempt == 101)
        if #nodes == count then
            local boss = assignKinds(nodes)
            if boss then first, second = secretSites(nodes, map, boss) end
            if first then break end
        end
    end
    assert(first and second, "Floor has no valid secret-room sites")
    for index, node in ipairs({first, second}) do
        node.id, node.kind, node.distance = #nodes + 1, index == 1 and "secret" or "supersecret", math.huge
        for _, d in ipairs(directions) do
            local adjacent = map[Rooms.key(node.mapX + d[1], node.mapY + d[2])]
            if adjacent then node.distance = math.min(node.distance, adjacent.distance + 1) end
        end
        nodes[#nodes + 1], map[Rooms.key(node.mapX, node.mapY)] = node, node
    end
    return nodes, map
end

function Rooms.generate(seed, practice, floorNumber)
    local rng, rooms = love.math.newRandomGenerator(seed), {}
    if type(floorNumber) ~= "number" or floorNumber < 1 or floorNumber >= math.huge or
        floorNumber % 1 ~= 0 then floorNumber = 1 end
    local count = practice and 1 or math.floor(5 + floorNumber * 2.6) + rng:random(0, 1)
    local nodes, map
    if practice then nodes = {{id = 1, kind = "start", mapX = 0, mapY = 0, distance = 0}}
    else nodes, map = floorplan(rng, count) end
    rooms.floorNumber, rooms.regularCount = floorNumber, count
    for i, node in ipairs(nodes) do
        local combat = node.kind == "start" or node.kind == "combat"
        local challenge = node.kind == "secret" and "combat" or node.kind == "supersecret" and "targets" or nil
        local room = {id = i, name = specialNames[node.kind] or names[(i - 1) % #names + 1],
            kind = node.kind, mapX = node.mapX, mapY = node.mapY, distance = node.distance,
            w = practice and 17 or node.kind == "boss" and 15 or 13,
            h = practice and 11 or 9, tiles = {}, doors = {}, crystals = {}, challenge = challenge,
            revision = 0, cleared = not combat and node.kind ~= "boss" and not challenge,
            refuge = node.kind == "refuge", final = node.kind == "boss", visited = false}
        for y = 1, room.h do for x = 1, room.w do
            local boundary = x == 1 or y == 1 or x == room.w or y == room.h
            local passage = not boundary and (x == 2 or y == 2 or x == room.w - 1 or y == room.h - 1)
            room.tiles[Rooms.key(x, y)] = {x = x, y = y, ground = "floor", hits = 0,
                piece = boundary and "wall" or nil, protected = boundary or passage, passage = passage}
        end end
        local cx, cy = math.ceil(room.w / 2), math.ceil(room.h / 2)
        local layout = not practice and combat and layouts[(i - 1) % #layouts + 1] or nil
        if layout then
            for _, offset in ipairs(layout.walls) do piece(room, cx + offset[1], cy + offset[2], "wall") end
            piece(room, cx + layout.pillar[1], cy + layout.pillar[2], "pillar")
            Rooms.cell(room, cx + layout.hole[1], cy + layout.hole[2]).ground = "hole"
            room.tactic = layout.tactic
        end
        if combat then
            for _, offset in ipairs(layout and layout.crystals or {}) do
                room.crystals[#room.crystals + 1] = {x = cx + offset[1], y = cy + offset[2]}
            end
        end
        room.spawn = {x = 3, y = cy}
        Rooms.cell(room, room.spawn.x, room.spawn.y).passage = true
        Rooms.cell(room, room.spawn.x, room.spawn.y).protected = true
        room.enemies = combat and {
            {x = room.w - 3, y = room.h - 2, kind = "dasher"}, {x = room.w - 2, y = 3, kind = "ranger"}}
            or {}
        if room.final then
            room.enemies = {{x = cx, y = cy, kind = "warden"}}
        elseif i >= 3 and combat then
            room.enemies[#room.enemies + 1] = {x = 4, y = room.h - 2, kind = "dasher"}
        elseif challenge == "combat" then
            room.enemies = {{x = 10, y = 5, kind = "dasher"}, {x = 7, y = 3, kind = "ranger"}}
        elseif challenge == "targets" then
            room.targets = {{x = 5, y = 3}, {x = 9, y = 4}, {x = 7, y = 7}}
        end
        if practice then practiceLayout(room) end
        rooms[i] = room
        if node.kind == "boss" then rooms.bossId = i
        elseif node.kind == "refuge" then rooms.refugeId = i
        elseif node.kind == "shop" then rooms.shopId = i
        elseif node.kind == "treasure" then rooms.treasureId = i
        elseif node.kind == "secret" then rooms.secretId = i
        elseif node.kind == "supersecret" then rooms.superSecretId = i end
    end
    if practice then
        local room = rooms[1]
        local x, y = doorway(room, "east")
        portal(room, x, y, {x = x, y = y, side = "east", finish = true})
    else
        for _, node in ipairs(nodes) do for index, d in ipairs(directions) do
            local adjacent = map[Rooms.key(node.mapX + d[1], node.mapY + d[2])]
            if adjacent and adjacent.id > node.id then
                local side, other = sides[index], opposite[sides[index]]
                local secret = adjacent.kind == "secret" or adjacent.kind == "supersecret"
                local hidden, secretId = secret and true or nil, secret and adjacent.id or nil
                local room, destination = rooms[node.id], rooms[adjacent.id]
                local x, y = doorway(room, side)
                portal(room, x, y, {x = x, y = y, to = adjacent.id, side = side, arrival = other,
                    hidden = hidden, secretTo = secretId})
                x, y = doorway(destination, other)
                portal(destination, x, y, {x = x, y = y, to = node.id, side = other, arrival = side,
                    hidden = hidden, secretTo = secretId})
            end
        end end
        local boss = rooms[rooms.bossId]
        for index, d in ipairs(directions) do
            if not map[Rooms.key(boss.mapX + d[1], boss.mapY + d[2])] then
                local side = sides[index]
                local x, y = doorway(boss, side)
                portal(boss, x, y, {x = x, y = y, side = side, finish = true})
                break
            end
        end
    end
    return rooms
end

function Rooms.arrival(room, side)
    local x, y = doorway(room, side)
    if side == "east" then x = x - 1 elseif side == "west" then x = x + 1
    elseif side == "north" then y = y + 1 else y = y - 1 end
    return x, y
end
return Rooms
