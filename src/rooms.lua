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

-- Flood from every walkable passage cell (the protected ring + spawn): the set
-- of floor cells a visitor reaches with zero tools. Spawns, crystals and marks
-- are filtered by it so nothing is born inside a pocket sealed by the build.
function Rooms.reachable(room)
    local seen, queue, head = {}, {}, 1
    for _, cell in pairs(room.tiles) do
        if cell.passage and cell.ground == "floor" and not cell.piece then
            local key = Rooms.key(cell.x, cell.y)
            if not seen[key] then seen[key] = true; queue[#queue + 1] = cell end
        end
    end
    while head <= #queue do
        local node = queue[head]; head = head + 1
        for _, d in ipairs(directions) do
            local x, y = node.x + d[1], node.y + d[2]
            local key = Rooms.key(x, y)
            if not seen[key] and Rooms.floor(room, x, y) then
                seen[key] = true
                queue[#queue + 1] = {x = x, y = y}
            end
        end
    end
    return seen
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

local specialNames = {boss = "SANTUÁRIO DOS ECOS", refuge = "REFÚGIO", shop = "LOJA DO VIAJANTE",
    treasure = "SALA DO TESOURO", secret = "SALA SECRETA", supersecret = "RECANTO SUPERSECRETO"}
local sides = {"east", "west", "south", "north"}
local opposite = {east = "west", west = "east", south = "north", north = "south"}

-- Each floor is a region with its own interior pool: ordered galleries, then
-- the priests' crypts, then the drowned sanctum where amber took over.
local floorThemes = {
    [1] = {title = "GALERIAS DA SUPERFÍCIE", pool = {"open", "gallery", "gates", "partition", "ruins"}},
    [2] = {title = "CRIPTAS DOS SACERDOTES", pool = {"partition", "alley", "cross", "crypt", "ruins"}},
    [3] = {title = "SANTUÁRIO AFUNDADO", pool = {"amber", "fissures", "sanctum", "gallery", "ruins"}},
}
local function themeFor(floorNumber)
    return floorThemes[math.min(math.max(floorNumber, 1), #floorThemes)]
end

-- Hybrid interiors: an authored shape grammar per archetype, with counts and
-- positions rolled per room from the seed. `tactic` is shown once per room.
local archetypes = {
    open = {weight = 2, sizes = {{13, 9}, {15, 9}},
        names = {"SAGUÃO DAS CORRENTES", "VESTÍBULO DA MARÉ", "PÁTIO DA RESSONÂNCIA"},
        tactic = "Sala aberta: a mobilidade decide. Cristais punem quem foge em linha reta.",
        spec = {
            {kind = "pillar", shape = "spread", count = {0, 1}, sep = 4},
            {kind = "hole", shape = "scatter", count = {0, 1}},
            {kind = "crystal", count = {1, 2}},
        }},
    gallery = {weight = 2, sizes = {{13, 9}, {15, 9}},
        names = {"COLUNATA DOS JURAMENTOS", "GALERIA DOS VOTOS", "NAVE DOS ECOS"},
        tactic = "Pilares tombam para longe do golpe: mire a queda e crie cobertura.",
        spec = {
            {kind = "pillar", shape = "row", count = {2, 3}, sep = 3},
            {kind = "wall", shape = "cluster", count = {0, 1}, size = {1, 2}},
            {kind = "crystal", count = {1, 2}},
        }},
    gates = {weight = 2, sizes = {{13, 9}},
        names = {"SALÃO DOS POSTIGOS", "TRANCA DE JADE", "VESTÍBULO DAS TRANCAS"},
        tactic = "Pares de pilares são portões e armas: derrube um sobre o inimigo.",
        spec = {
            {kind = "pillar", shape = "pairs", count = {1, 2}, sep = 3},
            {kind = "crystal", count = {0, 2}},
        }},
    partition = {weight = 2, sizes = {{13, 9}, {13, 11}},
        names = {"REFEITÓRIO PARTIDO", "CÂMARA DIVIDIDA", "DORMITÓRIO RACHADO"},
        tactic = "A divisória corta flechas e investidas; contornar pelo anel é grátis.",
        spec = {
            {kind = "wall", shape = "line", span = "full", gaps = {1, 2}},
            {kind = "pillar", shape = "spread", count = {0, 1}},
            {kind = "crystal", count = {1, 2}},
        }},
    ruins = {weight = 3, sizes = {{13, 9}, {15, 9}, {13, 11}},
        names = {"RUÍNA IRREGULAR", "GALERIA DESABADA", "SALÃO TOMBADO"},
        tactic = "Cobertura dispersa: cada vão é um flanco, cada rachadura uma história.",
        spec = {
            {kind = "wall", shape = "cluster", count = {2, 4}, size = {1, 3}},
            {kind = "pillar", shape = "spread", count = {0, 1}},
            {kind = "hole", shape = "scatter", count = {0, 1}},
            {kind = "scar", count = {2, 4}},
            {kind = "crystal", count = {1, 2}},
        }},
    alley = {weight = 2, sizes = {{13, 9}, {15, 9}},
        names = {"CORREDOR FUNERÁRIO", "BECO DA RESSONÂNCIA", "PASSAGEM DOS VELADOS"},
        tactic = "Parede longa funila o combate; contornar é grátis, atravessar custa picareta.",
        spec = {
            {kind = "wall", shape = "line", axis = "h", span = {5, 8}, gaps = {1, 1}},
            {kind = "wall", shape = "cluster", count = {0, 1}, size = {1, 2}},
            {kind = "crystal", count = {1, 2}},
        }},
    cross = {weight = 2, sizes = {{13, 9}, {13, 11}},
        names = {"CAPELA RACHADA", "CRUZ PARTIDA", "ALTAR QUEBRADO"},
        tactic = "Paredes curtas quebram linhas de tiro; flanqueie pelo anel externo.",
        spec = {
            {kind = "wall", shape = "cross", arms = {2, 3}},
            {kind = "pillar", shape = "spread", count = {0, 1}},
            {kind = "crystal", count = {1, 2}},
        }},
    crypt = {weight = 2, sizes = {{13, 9}, {13, 11}},
        names = {"CRIPTA DOS SACERDOTES", "OSSUÁRIO", "TÚMULO RACHADO"},
        tactic = "A cripta aperta: os blocos viram cobertura e o buraco termina investidas.",
        spec = {
            {kind = "wall", shape = "cluster", count = {3, 5}, size = {1, 2}},
            {kind = "hole", shape = "scatter", count = {1, 2}},
            {kind = "scar", count = {1, 3}},
            {kind = "crystal", count = {1, 2}},
        }},
    amber = {weight = 2, sizes = {{13, 9}, {15, 9}},
        names = {"JARDIM RESINOSO", "CAMPO DE ÂMBAR", "POMAR SELADO"},
        tactic = "Âmbar armado explode em dois passos; provoque a reação em cadeia.",
        spec = {
            {kind = "crystal", count = {3, 5}},
            {kind = "wall", shape = "cluster", count = {0, 2}, size = {1, 2}},
            {kind = "scar", count = {2, 4}},
        }},
    fissures = {weight = 2, sizes = {{13, 9}, {13, 11}},
        names = {"ABISMO RACHADO", "PÁTIO DAS FENDAS", "SOLO PARTIDO"},
        tactic = "Buracos param investidas e pilares. Flechas passam por cima do vazio.",
        spec = {
            {kind = "hole", shape = "band", count = {2, 4}},
            {kind = "pillar", shape = "spread", count = {0, 1}},
            {kind = "scar", count = {1, 2}},
            {kind = "crystal", count = {1, 2}},
        }},
    sanctum = {weight = 1, sizes = {{15, 9}, {13, 11}},
        names = {"TRONO VAZIO", "SANTUÁRIO DO ECO", "CÂMARA DO CORO"},
        tactic = "O anel de pilares esconde o centro; cada queda reabre ou fecha a arena.",
        spec = {
            {kind = "pillar", shape = "ring", count = {2, 3}},
            {kind = "crystal", count = {2, 3}},
            {kind = "scar", count = {1, 3}},
        }},
}
Rooms.archetypes, Rooms.floorThemes = archetypes, floorThemes

local function piece(room, x, y, kind, protected)
    local cell = Rooms.cell(room, x, y)
    cell.piece, cell.protected, cell.hits = kind, protected == true, 0
    if kind == "pillar" then cell.state = "idle" end
    return cell
end

local function doorway(room, side)
    local slot = room.doorSlots and room.doorSlots[side]
    if slot then return slot.x, slot.y end
    local x, y = math.ceil(room.w / 2), math.ceil(room.h / 2)
    if side == "east" then x = room.w elseif side == "west" then x = 1
    elseif side == "north" then y = 1 else y = room.h end
    return x, y
end

-- Interior placement never touches the boundary frame, the protected passage
-- ring or the spawn approach; that keeps every no-tool route safe by design.
local function buildable(room, x, y)
    local cell = Rooms.cell(room, x, y)
    return cell ~= nil and cell.ground == "floor" and cell.piece == nil
        and not cell.passage and not cell.protected
        and x >= 3 and y >= 3 and x <= room.w - 2 and y <= room.h - 2
        and not (room.spawn and math.abs(x - room.spawn.x) + math.abs(y - room.spawn.y) <= 1)
end
local function putPiece(room, x, y, kind)
    if not buildable(room, x, y) then return nil end
    return piece(room, x, y, kind, false)
end
local function putHole(room, x, y)
    if not buildable(room, x, y) then return nil end
    Rooms.cell(room, x, y).ground = "hole"
    return true
end
local function putScar(room, x, y)
    local cell = Rooms.cell(room, x, y)
    if cell and cell.ground == "floor" and not cell.piece
        and x >= 3 and y >= 3 and x <= room.w - 2 and y <= room.h - 2 then
        cell.state = "broken"
        return true
    end
end

local function roll(rng, range, fallback)
    return range and rng:random(range[1], range[2]) or (fallback or 0)
end

local function specLine(room, rng, d)
    local cx, cy = math.ceil(room.w / 2), math.ceil(room.h / 2)
    local axis = d.axis or (rng:random(2) == 1 and "h" or "v")
    local at = roll(rng, d.at, 0)
    local full = axis == "h" and room.w - 4 or room.h - 4
    local len = d.span == "full" and full or math.min(full, roll(rng, d.span, full))
    local cells = {}
    for i = 0, len - 1 do
        cells[#cells + 1] = axis == "h" and {cx - math.floor(len / 2) + i, cy + at}
            or {cx + at, cy - math.floor(len / 2) + i}
    end
    local gapAt, placed, guard = {}, 0, 0
    while placed < math.max(1, roll(rng, d.gaps, 1)) and guard < 80 do
        guard = guard + 1
        local i = rng:random(1, #cells)
        if not gapAt[i] then gapAt[i] = true; placed = placed + 1 end
    end
    for i, c in ipairs(cells) do
        if not gapAt[i] then putPiece(room, c[1], c[2], "wall") end
    end
end

local function specCluster(room, rng, d)
    local n, maxSize, guard = roll(rng, d.count), d.size and d.size[2] or 3, 0
    while n > 0 and guard < 90 do
        guard = guard + 1
        local x, y = rng:random(3, room.w - 2), rng:random(3, room.h - 2)
        if putPiece(room, x, y, "wall") then
            n = n - 1
            for _ = 1, rng:random(0, maxSize - 1) do
                local dir = directions[rng:random(4)]
                putPiece(room, x + dir[1], y + dir[2], "wall")
            end
        end
    end
end

local function specCross(room, rng, d)
    local cx, cy, arm = math.ceil(room.w / 2), math.ceil(room.h / 2), roll(rng, d.arms, 2)
    for _, dir in ipairs(directions) do
        for i = 1, arm do putPiece(room, cx + dir[1] * i, cy + dir[2] * i, "wall") end
    end
end

local function specSpread(room, rng, d)
    local n, placed, tries = roll(rng, d.count), {}, 0
    while #placed < n and tries < 140 do
        tries = tries + 1
        local x, y = rng:random(3, room.w - 2), rng:random(3, room.h - 2)
        local ok = true
        for _, p in ipairs(placed) do
            if math.abs(x - p.x) + math.abs(y - p.y) < (d.sep or 2) then ok = false break end
        end
        if ok and putPiece(room, x, y, d.kind or "pillar") then placed[#placed + 1] = {x = x, y = y} end
    end
end

local function specRow(room, rng, d)
    local cx, cy = math.ceil(room.w / 2), math.ceil(room.h / 2)
    local n, sep = roll(rng, d.count), d.sep or 2
    local axis = d.axis or (rng:random(2) == 1 and "h" or "v")
    local off = roll(rng, d.at, 0)
    for i = 1, n do
        local along = (i - 1 - (n - 1) / 2) * sep
        local x = axis == "h" and math.floor(cx + along + .5) or cx + off
        local y = axis == "h" and cy + off or math.floor(cy + along + .5)
        putPiece(room, x, y, "pillar")
    end
end

local function specPairs(room, rng, d)
    local cx, cy = math.ceil(room.w / 2), math.ceil(room.h / 2)
    local n, spacing = roll(rng, d.count), d.sep or 3
    for i = 1, n do
        local x = math.floor(cx + (i - (n + 1) / 2) * spacing + .5)
        putPiece(room, x, cy - 1, "pillar")
        putPiece(room, x, cy + 1, "pillar")
    end
end

local function specRing(room, rng, d)
    local cx, cy, r = math.ceil(room.w / 2), math.ceil(room.h / 2), d.radius or 2
    local spots = {{cx - r, cy}, {cx + r, cy}, {cx, cy - r}, {cx, cy + r},
        {cx - r, cy - r}, {cx + r, cy - r}, {cx - r, cy + r}, {cx + r, cy + r}}
    for i = #spots, 2, -1 do local j = rng:random(i); spots[i], spots[j] = spots[j], spots[i] end
    for i = 1, math.min(roll(rng, d.count), #spots) do
        putPiece(room, spots[i][1], spots[i][2], "pillar")
    end
end

local function specBand(room, rng, d)
    local cx, cy = math.ceil(room.w / 2), math.ceil(room.h / 2)
    local n = roll(rng, d.count)
    local axis = d.axis or (rng:random(2) == 1 and "h" or "v")
    local at = roll(rng, d.at, rng:random(-1, 1))
    for i = 1, n do
        local along = i - math.floor((n + 1) / 2)
        putHole(room, axis == "h" and cx + along or cx + at, axis == "h" and cy + at or cy + along)
    end
end

local function specScatterHoles(room, rng, d)
    local n, tries = roll(rng, d.count), 0
    while n > 0 and tries < 140 do
        tries = tries + 1
        if putHole(room, rng:random(3, room.w - 2), rng:random(3, room.h - 2)) then n = n - 1 end
    end
end

local function specScars(room, rng, d)
    local n, tries = roll(rng, d.count), 0
    while n > 0 and tries < 140 do
        tries = tries + 1
        if putScar(room, rng:random(3, room.w - 2), rng:random(3, room.h - 2)) then n = n - 1 end
    end
end

local function specCrystals(room, rng, d, reachable)
    local n, tries = roll(rng, d.count), 0
    while n > 0 and tries < 140 do
        tries = tries + 1
        local x, y = rng:random(3, room.w - 2), rng:random(3, room.h - 2)
        if buildable(room, x, y) and reachable[Rooms.key(x, y)] then
            local clear = true
            for _, c in ipairs(room.crystals) do
                if math.abs(x - c.x) + math.abs(y - c.y) < 3 then clear = false break end
            end
            if clear then room.crystals[#room.crystals + 1] = {x = x, y = y}; n = n - 1 end
        end
    end
end

local builders = {line = specLine, cluster = specCluster, cross = specCross,
    spread = specSpread, row = specRow, pairs = specPairs, ring = specRing}
local function buildInterior(room, rng, spec)
    -- Crystals go last so their reachability is judged against the finished build.
    local crystals = {}
    for _, d in ipairs(spec) do
        if d.kind == "crystal" then crystals[#crystals + 1] = d
        elseif d.kind == "wall" or d.kind == "pillar" then (builders[d.shape] or specSpread)(room, rng, d)
        elseif d.kind == "hole" then (d.shape == "band" and specBand or specScatterHoles)(room, rng, d)
        elseif d.kind == "scar" then specScars(room, rng, d)
        end
    end
    if #crystals > 0 then
        local reachable = Rooms.reachable(room)
        for _, d in ipairs(crystals) do specCrystals(room, rng, d, reachable) end
    end
end

local roleOf = {crawler = "melee", dasher = "melee", ranger = "line", sower = "mark", watcher = "cross"}
local rosters = {
    [1] = {"crawler", "ranger", "dasher"},
    [2] = {"crawler", "ranger", "dasher", "sower", "watcher"},
}
local eliteByFloor = {[1] = "veteran", [2] = "breaker"}
local bossKinds = {[1] = "warden", [2] = "demolisher"}
local function bossKind(floorNumber) return bossKinds[floorNumber] or "regent" end

local function doorSpots(room, node, map)
    local spots, finish = {}, false
    for i, d in ipairs(directions) do
        if map[Rooms.key(node.mapX + d[1], node.mapY + d[2])]
            or (node.kind == "boss" and not finish) then
            finish = finish or node.kind == "boss"
            local side = sides[i]
            local x, y = doorway(room, side)
            spots[#spots + 1] = {x = x, y = y}
            local ax, ay = Rooms.arrival(room, side)
            spots[#spots + 1] = {x = ax, y = ay}
        end
    end
    return spots
end

-- Open cells away from every entrance, preferring long firing lines for shooters.
local function spawnCells(room, spots, rng, count, reachable)
    local candidates = {}
    for y = 3, room.h - 2 do for x = 3, room.w - 2 do
        local cell = Rooms.cell(room, x, y)
        if cell.ground == "floor" and not cell.piece and not cell.passage
            and (not reachable or reachable[Rooms.key(x, y)]) then
            local clear = math.abs(x - room.spawn.x) + math.abs(y - room.spawn.y) >= 4
            if clear then for _, s in ipairs(spots) do
                if math.abs(x - s.x) + math.abs(y - s.y) < 3 then clear = false; break end
            end end
            if clear then
                local score = 0
                for _, d in ipairs(directions) do
                    score = math.max(score, #Rooms.line(room, x, y, d[1], d[2], math.max(room.w, room.h)))
                end
                candidates[#candidates + 1] = {x = x, y = y, score = score + rng:random() * 4}
            end
        end
    end end
    table.sort(candidates, function(a, b) return a.score > b.score end)
    local picked = {}
    for _, c in ipairs(candidates) do
        local free = true
        for _, p in ipairs(picked) do
            if math.abs(c.x - p.x) + math.abs(c.y - p.y) < 2 then free = false; break end
        end
        if free then picked[#picked + 1] = c end
        if #picked >= count then break end
    end
    return picked
end

-- Inscriptions are non-solid floor marks read with E; they can never block a
-- path, so placement only avoids furniture, actors and entrance approach cells.
local function inscriptionSpot(room, node, map, seed, floorNumber, reachable)
    local used = {[Rooms.key(room.spawn.x, room.spawn.y)] = true}
    for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
        used[Rooms.key(room.spawn.x + d[1], room.spawn.y + d[2])] = true
    end
    for _, s in ipairs(doorSpots(room, node, map)) do used[Rooms.key(s.x, s.y)] = true end
    for _, list in ipairs({room.enemies, room.crystals, room.targets, room.npcs}) do
        for _, e in ipairs(list or {}) do used[Rooms.key(e.x, e.y)] = true end
    end
    local candidates = {}
    for y = 3, room.h - 2 do for x = 3, room.w - 2 do
        local cell = Rooms.cell(room, x, y)
        if cell and cell.ground == "floor" and not cell.piece and not cell.passage
            and (not reachable or reachable[Rooms.key(x, y)])
            and not used[Rooms.key(x, y)] then
            candidates[#candidates + 1] = {x = x, y = y}
        end
    end end
    if #candidates == 0 then return nil end
    local irng = love.math.newRandomGenerator(seed * 733 + floorNumber * 577 + node.id * 29)
    return candidates[irng:random(#candidates)]
end

local function pickKinds(pool, n, maxRoles, rng)
    local kinds, used = {}, {}
    for i = 1, n do
        local roles = 0
        for _ in pairs(used) do roles = roles + 1 end
        local options, fresh = {}, {}
        for _, k in ipairs(pool) do
            if used[roleOf[k]] or roles < maxRoles then
                options[#options + 1] = k
                if not used[roleOf[k]] then fresh[#fresh + 1] = k end
            end
        end
        local choice = #fresh > 0 and fresh or (#options > 0 and options or pool)
        kinds[i] = choice[rng:random(#choice)]
        used[roleOf[kinds[i]]] = true
    end
    return kinds
end

local function compose(room, node, map, seed, floorNumber)
    local rng = love.math.newRandomGenerator(seed * 1009 + floorNumber * 9176 + node.id * 37)
    local spots = doorSpots(room, node, map)
    local kinds
    if node.elite then
        local kind = eliteByFloor[math.min(math.max(floorNumber, 1), 2)]
        if floorNumber >= 3 then kind = eliteByFloor[rng:random(#eliteByFloor)] end
        kinds = {kind}
        if floorNumber >= 3 and #spawnCells(room, spots, rng, 2) >= 2 then
            kinds[2] = "crawler"
        end
    elseif node.distance == 0 then
        kinds = {"crawler"}
    else
        local n, maxRoles
        if node.distance <= 1 then n, maxRoles = 1, 1
        elseif node.distance <= 3 then n, maxRoles = 2, 2
        else
            n = 2 + rng:random(0, 1) + (floorNumber >= 3 and rng:random(0, 1) or 0)
            maxRoles = floorNumber >= 3 and 3 or 2
        end
        kinds = pickKinds(rosters[math.min(math.max(floorNumber, 1), 2)], math.min(n, 4), maxRoles, rng)
    end
    local cells = spawnCells(room, spots, rng, #kinds, Rooms.reachable(room))
    local enemies = {}
    for i, cell in ipairs(cells) do
        if kinds[i] then enemies[#enemies + 1] = {x = cell.x, y = cell.y, kind = kinds[i]} end
    end
    if #enemies == 0 and cells[1] then
        enemies[1] = {x = cells[1].x, y = cells[1].y, kind = kinds[1] or "crawler"}
    end
    return enemies
end

local function eliteLair(room, node, map, seed, floorNumber)
    local rng = love.math.newRandomGenerator(seed * 7919 + floorNumber * 131 + node.id)
    local kind = eliteByFloor[math.min(math.max(floorNumber, 1), 2)]
    if floorNumber >= 3 then kind = eliteByFloor[rng:random(#eliteByFloor)] end
    local cells = spawnCells(room, doorSpots(room, node, map), rng, 1, Rooms.reachable(room))
    local cell = cells[1] or {x = math.ceil(room.w / 2), y = math.ceil(room.h / 2)}
    return {{x = cell.x, y = cell.y, kind = kind}}
end

local function eliteNode(nodes)
    local best, bestScore
    for _, node in ipairs(nodes) do
        if node.kind == "combat" then
            local score = node.distance * 2 + (node.degree == 1 and 1 or 0)
            if not bestScore or score > bestScore then best, bestScore = node, score end
        end
    end
    return best
end

-- Seeded arena variants per boss: few cover pieces, holes away from entrances.
local bossArenas = {
    warden = {
        {},
        {pillars = {{5, 3}, {11, 7}}},
        {pillars = {{4, 5}, {12, 5}}, walls = {{8, 3}, {8, 7}}},
    },
    demolisher = {
        {pillars = {{5, 3}, {11, 3}, {5, 7}, {11, 7}}, holes = {{6, 4}, {10, 6}}},
        {pillars = {{4, 5}, {12, 5}, {8, 3}}, holes = {{5, 6}, {11, 4}}},
        {pillars = {{5, 4}, {11, 4}, {8, 6}}, holes = {{6, 3}, {10, 7}}},
    },
    regent = {
        {pillars = {{5, 3}, {11, 7}}, walls = {{8, 3}, {8, 7}}},
        {pillars = {{5, 6}, {11, 4}}, walls = {{8, 4}, {8, 6}}},
        {pillars = {{8, 3}, {8, 7}}, walls = {{5, 5}, {11, 5}}},
    },
}
local function bossArena(room, kind, rng)
    local set = bossArenas[kind]
    if not set then return end
    local arena = set[rng:random(#set)]
    for _, p in ipairs(arena.pillars or {}) do putPiece(room, p[1], p[2], "pillar") end
    for _, p in ipairs(arena.walls or {}) do putPiece(room, p[1], p[2], "wall") end
    for _, p in ipairs(arena.holes or {}) do putHole(room, p[1], p[2]) end
end

-- Target racks for the supersecret trial: every mark must be visible along a
-- cardinal line from the ring, so authored sets avoid interior furniture.
local targetSets = {
    {{x = 5, y = 3}, {x = 9, y = 4}, {x = 7, y = 7}},
    {{x = 4, y = 6}, {x = 10, y = 4}, {x = 7, y = 3}},
    {{x = 4, y = 4}, {x = 8, y = 7}, {x = 10, y = 5}},
}

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

-- Fallen pillars can wall off an actor inside a pocket: generation must promise
-- the same guarantee the terrain suite simulates, so unsafe pillars are dropped
-- here instead of in the test. Mirrors that simulation cell-for-cell.
local function comboIsolates(room, pillars, mask, actors)
    local fallen, downed = {}, {}
    local choice = mask
    for _, p in ipairs(pillars) do
        local d = directions[choice % 4 + 1]; choice = math.floor(choice / 4)
        downed[Rooms.key(p.x, p.y)] = true
        local x, y = p.x, p.y
        for _ = 1, 5 do
            x, y = x + d[1], y + d[2]
            local cell = Rooms.cell(room, x, y)
            if not cell or cell.passage then break end
            local key = Rooms.key(x, y)
            if fallen[key] or (cell.piece and not downed[key]) or cell.ground == "hole" then break end
            fallen[key] = true
        end
    end
    local queue, head, seen = {}, 1, {}
    for _, cell in pairs(room.tiles) do
        local key = Rooms.key(cell.x, cell.y)
        if cell.passage and cell.ground == "floor" and not cell.piece and not seen[key] then
            seen[key] = true; queue[#queue + 1] = cell
        end
    end
    while head <= #queue do
        local node = queue[head]; head = head + 1
        for _, d in ipairs(directions) do
            local x, y = node.x + d[1], node.y + d[2]
            local key = Rooms.key(x, y)
            local cell = Rooms.cell(room, x, y)
            if not seen[key] and not fallen[key] and cell and cell.ground == "floor"
                and (cell.piece == nil or cell.piece == "portal" or downed[key]) then
                seen[key] = true; queue[#queue + 1] = {x = x, y = y}
            end
        end
    end
    for _, a in ipairs(actors) do
        local key = Rooms.key(a.x, a.y)
        local cell = Rooms.cell(room, a.x, a.y)
        if not fallen[key] and cell and cell.ground ~= "hole" and not seen[key] then return true end
    end
    return false
end

local function pruneUnsafePillars(room)
    local actors = {}
    for _, list in ipairs({room.enemies, room.targets}) do
        for _, a in ipairs(list or {}) do actors[#actors + 1] = a end
    end
    if #actors == 0 then return end
    while true do
        local pillars = {}
        for _, t in pairs(room.tiles) do
            if t.piece == "pillar" then pillars[#pillars + 1] = t end
        end
        if #pillars == 0 then return end
        local fail
        for mask = 0, 4 ^ #pillars - 1 do
            if comboIsolates(room, pillars, mask, actors) then fail = mask break end
        end
        if not fail then return end
        local removed = false
        for i = #pillars, 1, -1 do
            local sub = {}
            for j, p in ipairs(pillars) do if j ~= i then sub[#sub + 1] = p end end
            local subMask = fail % (4 ^ (i - 1)) + math.floor(fail / (4 ^ i)) * (4 ^ (i - 1))
            if not comboIsolates(room, sub, subMask, actors) then
                pillars[i].piece = nil; removed = true; break
            end
        end
        if not removed then pillars[#pillars].piece = nil end
    end
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
    if not practice and floorNumber >= 2 then
        local elite = eliteNode(nodes)
        if elite then elite.elite = true end
    end
    -- Floor 3 buries the 'deep' inscription in the boss arena or the secret
    -- room, picked deterministically by seed; it replaces that room's usual mark.
    local deepInBoss = rng:random() < .5
    rooms.floorNumber, rooms.regularCount = floorNumber, count
    rooms.floorTitle = not practice and themeFor(floorNumber).title or nil
    for i, node in ipairs(nodes) do
        local combat = node.kind == "start" or node.kind == "combat"
        local challenge = node.kind == "secret" and "combat" or node.kind == "supersecret" and "targets" or nil
        -- Each room draws its own stream: archetype, size, interior, name.
        local arng = love.math.newRandomGenerator(seed * 97 + floorNumber * 887 + node.id * 41)
        local archetype, archetypeId
        if combat and not practice then
            local pool = themeFor(floorNumber).pool
            local total = 0
            for _, id in ipairs(pool) do total = total + archetypes[id].weight end
            local pick, cursor = arng:random() * total, 0
            for _, id in ipairs(pool) do
                cursor = cursor + archetypes[id].weight
                if pick <= cursor then archetype, archetypeId = archetypes[id], id break end
            end
        end
        local size = archetype and archetype.sizes[arng:random(#archetype.sizes)]
        local room = {id = i, name = specialNames[node.kind] or "RUÍNAS DOS ECOS",
            kind = node.kind, mapX = node.mapX, mapY = node.mapY, distance = node.distance,
            w = practice and 17 or node.kind == "boss" and 15 or size and size[1] or 13,
            h = practice and 11 or node.kind == "boss" and 9 or size and size[2] or 9,
            tiles = {}, doors = {}, crystals = {}, challenge = challenge,
            revision = 0, cleared = not combat and node.kind ~= "boss" and not challenge,
            refuge = node.kind == "refuge", final = node.kind == "boss", visited = false,
            archetype = archetypeId}
        for y = 1, room.h do for x = 1, room.w do
            local boundary = x == 1 or y == 1 or x == room.w or y == room.h
            local passage = not boundary and (x == 2 or y == 2 or x == room.w - 1 or y == room.h - 1)
            room.tiles[Rooms.key(x, y)] = {x = x, y = y, ground = "floor", hits = 0,
                piece = boundary and "wall" or nil, protected = boundary or passage, passage = passage}
        end end
        local cx, cy = math.ceil(room.w / 2), math.ceil(room.h / 2)
        room.spawn = {x = 3, y = cy}
        Rooms.cell(room, room.spawn.x, room.spawn.y).passage = true
        Rooms.cell(room, room.spawn.x, room.spawn.y).protected = true
        if not practice then
            local drng = love.math.newRandomGenerator(seed * 31 + floorNumber * 131 + node.id * 577)
            room.doorSlots = {}
            for _, side in ipairs(sides) do
                local off = drng:random(-2, 2)
                if side == "east" or side == "west" then
                    room.doorSlots[side] = {x = side == "east" and room.w or 1,
                        y = math.max(3, math.min(room.h - 2, cy + off))}
                else
                    room.doorSlots[side] = {x = math.max(3, math.min(room.w - 2, cx + off)),
                        y = side == "south" and room.h or 1}
                end
            end
        end
        if archetype then
            buildInterior(room, arng, archetype.spec)
            room.name = archetype.names[arng:random(#archetype.names)]
            room.tactic = archetype.tactic
        end
        room.elite = node.elite == true
        room.enemies = {}
        if room.final then
            local kind = bossKind(floorNumber)
            room.bossKind = kind
            room.enemies = {{x = cx, y = cy, kind = kind}}
            bossArena(room, kind, arng)
        elseif challenge == "targets" then
            room.targets = targetSets[arng:random(#targetSets)]
        elseif challenge == "combat" then
            room.name = "COVIL DE ELITE"
            for _ = 1, arng:random(0, 2) do
                putPiece(room, arng:random(3, room.w - 2), arng:random(3, room.h - 2), "pillar")
            end
            room.enemies = eliteLair(room, node, map, seed, floorNumber)
        elseif combat and not practice then
            room.enemies = compose(room, node, map, seed, floorNumber)
        end
        if node.kind == "shop" then
            putPiece(room, cx - 1, cy - 1, "wall")
            putPiece(room, cx + 1, cy - 1, "wall")
            room.npcs = {{x = cx, y = cy - 2, kind = "merchant"}}
        elseif node.kind == "refuge" then
            for _, off in ipairs({-2, 2}) do
                putPiece(room, cx + off, cy - 1, "wall")
                putPiece(room, cx + off, cy, "wall")
            end
            room.npcs = {{x = cx - 1, y = cy - 2, kind = "keeper"}}
        elseif node.kind == "treasure" then
            putPiece(room, cx - 2, cy, "pillar")
            putPiece(room, cx + 2, cy, "pillar")
        end
        if practice then practiceLayout(room) end
        pruneUnsafePillars(room)
        local inscriptionId
        if node.kind == "start" and floorNumber == 1 then inscriptionId = "entrance"
        elseif node.kind == "refuge" then inscriptionId = "chapel"
        elseif node.kind == "treasure" then inscriptionId = "vault"
        elseif node.kind == "boss" then inscriptionId = "gate"
        elseif node.kind == "secret" then inscriptionId = floorNumber == 2 and "crypt" or "kiln"
        end
        if floorNumber >= 3 then
            if node.kind == "boss" and deepInBoss then inscriptionId = "deep"
            elseif node.kind == "secret" and not deepInBoss then inscriptionId = "deep" end
        end
        if inscriptionId then
            local spot = inscriptionSpot(room, node, map or {}, seed, floorNumber, Rooms.reachable(room))
            if spot then room.inscriptions = {{x = spot.x, y = spot.y, id = inscriptionId}} end
        end
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
        -- One leaf special is sealed per floor: a locked door that opens for
        -- gold or brute force, never standing on the boss route.
        local srng = love.math.newRandomGenerator(seed * 61 + floorNumber * 277)
        local targets = {}
        for _, id in ipairs({rooms.treasureId, rooms.refugeId}) do
            if id then targets[#targets + 1] = id end
        end
        local sealed = rooms[targets[srng:random(#targets)]]
        rooms.sealedId = sealed.id
        for _, door in ipairs(sealed.doors) do
            if door.to and not door.hidden then
                door.sealed, door.sealCost = true, 3
                for _, link in ipairs(rooms[door.to].doors) do
                    if link.to == sealed.id and link.side == door.arrival then
                        link.sealed, link.sealCost = true, 3
                    end
                end
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
