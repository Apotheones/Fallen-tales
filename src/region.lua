-- Authored campaign regions. A region file is plain data: floor rectangles,
-- explicit terrain overrides, props, hotspots, npcs, exits and arrivals.
-- Region.build turns that into the same tile structure the pixel renderer
-- already knows (room.tiles keyed "x:y"), plus authored-content indexes the
-- campaign layer reads. Nothing here is generated at random.
local Rooms = require('src.rooms')
local Region = {}

local registry = {
    colina = 'src.regions.colina',
    hub = 'src.regions.hub',
    oficinas = 'src.regions.oficinas',
    mercado = 'src.regions.mercado',
    reservatorio = 'src.regions.reservatorio',
    saloes = 'src.regions.saloes',
    fundacao = 'src.regions.fundacao',
    andlar = 'src.regions.andlar',
    capela = 'src.regions.interiores_refugio', cozinha = 'src.regions.interiores_refugio',
    pensao = 'src.regions.interiores_refugio', oficina = 'src.regions.interiores_refugio',
    escola = 'src.regions.interiores_refugio',
}

local function key(x, y) return Rooms.key(x, y) end

local function tile(map, x, y)
    return map.tiles[key(x, y)]
end

function Region.load(id, legacy)
    local source = registry[id]
    assert(source, 'region: unknown map "' .. tostring(id) .. '"')
    if id == 'hub' and legacy then source = 'src.regions.hub_legacy' end
    local def = require(source)
    return Region.build(source == 'src.regions.interiores_refugio' and def[id] or def)
end

function Region.build(def)
    -- map.encounters gets its own array: the def is a require-cached module
    -- table, and appends to the shared list would leak into the next
    -- Region.load (injected/test encounters surviving a region revisit).
    local encounters = {}
    for _, e in ipairs(def.encounters or {}) do encounters[#encounters + 1] = e end
    local map = {
        id = def.id, uid = def.uid, name = def.name, w = def.w, h = def.h,
        tiles = {}, props = {}, propCells = {}, hotspots = {}, npcs = {},
        exits = {}, doors = {}, arrivals = def.arrivals or {},
        encounters = encounters,
        spawn = def.spawn, cleared = true, campaignRegion = true,
        realm = def.realm, outdoor = def.outdoor, zones = def.zones,
        paths = def.paths,
    }

    local function put(x, y, piece, ground)
        local cell = tile(map, x, y) or {x = x, y = y, hits = 0}
        if ground then cell.ground = ground end
        cell.piece = piece or cell.piece
        map.tiles[key(x, y)] = cell
        return cell
    end

    for _, r in ipairs(def.carve or {}) do
        for y = r.y, r.y + r.h - 1 do
            for x = r.x, r.x + r.w - 1 do
                local cell = tile(map, x, y) or {x = x, y = y, hits = 0}
                cell.ground = 'floor'
                map.tiles[key(x, y)] = cell
            end
        end
    end
    for _, c in ipairs(def.holes or {}) do
        local cell = put(c.x, c.y, nil, 'hole')
        cell.piece = nil
    end
    for _, c in ipairs(def.pillars or {}) do
        local cell = put(c.x, c.y, 'pillar', 'floor')
        cell.hits = c.hits or 3
    end
    for _, c in ipairs(def.walls or {}) do
        put(c.x, c.y, 'wall', 'floor')
    end

    -- Boundary shell: every floor cell needs solid neighbors; authored maps
    -- leave the outside void, so the shell turns the void into wall faces.
    local shell = {}
    for _, cell in pairs(map.tiles) do
        for dy = -1, 1 do
            for dx = -1, 1 do
                local nx, ny = cell.x + dx, cell.y + dy
                if not tile(map, nx, ny) then shell[key(nx, ny)] = {x = nx, y = ny} end
            end
        end
    end
    for _, cell in pairs(shell) do
        cell.ground, cell.piece, cell.hits, cell.protected = 'floor', 'wall', 0, true
        map.tiles[key(cell.x, cell.y)] = cell
    end

    for _, e in ipairs(def.exits or {}) do
        local cell = put(e.x, e.y, 'portal', 'floor')
        local exit = {x = e.x, y = e.y, side = e.side or 'south', to = e.to,
            arrival = e.arrival, open = e.open ~= false, label = e.label, id = e.id,
            flag = e.flag, localPath = e.localPath}
        cell.exit, cell.protected = exit, true
        map.exits[#map.exits + 1] = exit
        map.doors[#map.doors + 1] = exit
    end

    for _, p in ipairs(def.props or {}) do
        local prop = {id = p.id, x = p.x, y = p.y, w = p.w or 1, h = p.h or 1,
            kind = p.kind or p.id, solid = p.solid == true, state = p.state, doorSide = p.doorSide}
        map.props[#map.props + 1] = prop
        if prop.solid then
            for y = prop.y, prop.y + prop.h - 1 do
                for x = prop.x, prop.x + prop.w - 1 do
                    map.propCells[key(x, y)] = prop
                end
            end
        end
    end

    for _, n in ipairs(def.npcs or {}) do
        map.npcs[#map.npcs + 1] = {id = n.id, x = n.x, y = n.y,
            dx = n.dx or 0, dy = n.dy or 1, talkRange = n.talkRange,
            act = n.act, posts = n.posts}
    end
    for _, s in ipairs(def.hotspots or {}) do
        map.hotspots[#map.hotspots + 1] = {id = s.id, x = s.x, y = s.y,
            label = s.label or 'EXAMINAR', range = s.range or 1.45, once = s.once == true,
            when = s.when, use = s.use, title = s.title}
    end
    return map
end

-- Cardinal flood from a point over walkable cells; portal cells count only
-- while open and solid props block like walls. Used by tests and by the
-- campaign when validating arrivals.
function Region.reachable(map, sx, sy)
    local function open(x, y)
        local cell = tile(map, x, y)
        if not cell or cell.ground ~= 'floor' then return false end
        if cell.piece == 'portal' then return not (cell.exit and cell.exit.open == false) end
        if cell.piece then return false end
        local prop = map.propCells[key(x, y)]
        return not (prop and prop.solid)
    end
    local seen, queue, head = {}, {}, 1
    if open(sx, sy) then
        seen[key(sx, sy)] = true
        queue[1] = {x = sx, y = sy}
    end
    while head <= #queue do
        local node = queue[head]; head = head + 1
        for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
            local x, y = node.x + d[1], node.y + d[2]
            local k = key(x, y)
            if not seen[k] and open(x, y) then
                seen[k] = true
                queue[#queue + 1] = {x = x, y = y}
            end
        end
    end
    return seen
end

return Region
