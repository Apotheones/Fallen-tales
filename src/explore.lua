-- Continuous exploration movement for the campaign. Positions live in cell
-- units (the same "grid" space the renderer converts to 32 px cells); the
-- player's feet carry a small box that slides axis-separated against solid
-- cells, solid props and npc bodies. Cells mark places; pixels mark the feet.
local Rooms = require('src.rooms')
local Explore = {}

Explore.speed = 4.4      -- cells per second
Explore.hx, Explore.hy = .26, .16   -- feet box half-extents, in cells

local function cellIndex(v) return math.floor(v + .5) end

-- A cell blocks feet when it is missing, is a hole, carries a mineable piece,
-- is a closed portal, or hosts a solid prop.
function Explore.solidCell(map, cx, cy)
    local cell = Rooms.cell(map, cx, cy)
    if not cell or cell.ground ~= 'floor' then return true end
    if cell.piece == 'portal' then return cell.exit ~= nil and cell.exit.open == false end
    if cell.piece then return true end
    local prop = map.propCells[Rooms.key(cx, cy)]
    return prop ~= nil and prop.solid == true
end

function Explore.solidAt(map, lx, ly)
    return Explore.solidCell(map, cellIndex(lx), cellIndex(ly))
end

function Explore.blocked(campaign, lx, ly)
    if Explore.solidAt(campaign.map, lx, ly) then return true end
    for _, npc in ipairs(campaign.npcs) do
        if math.abs(npc.grid.x - lx) < .32 + Explore.hx
            and math.abs(npc.grid.y - ly) < .30 + Explore.hy then
            return true
        end
    end
    return false
end

local function boxFree(campaign, x, y)
    local hx, hy = Explore.hx, Explore.hy
    return not (Explore.blocked(campaign, x - hx, y - hy)
        or Explore.blocked(campaign, x + hx, y - hy)
        or Explore.blocked(campaign, x - hx, y + hy)
        or Explore.blocked(campaign, x + hx, y + hy)
        or Explore.blocked(campaign, x, y))
end

-- Axis-separated slide: horizontal and vertical are tried independently so
-- brushing a wall never stops the perpendicular motion.
function Explore.move(campaign, dt, dx, dy)
    local p = campaign.player
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        dx, dy = dx / len, dy / len
        local step = Explore.speed * dt
        local x, y = p.grid.x, p.grid.y
        local nx = x + dx * step
        if boxFree(campaign, nx, y) then x = nx end
        local ny = y + dy * step
        if boxFree(campaign, x, ny) then y = ny end
        p.moving = x ~= p.grid.x or y ~= p.grid.y
        p.grid.x, p.grid.y = x, y
        if dx ~= 0 and dy == 0 then
            p.facing.dx, p.facing.dy = dx > 0 and 1 or -1, 0
        elseif dy ~= 0 and dx == 0 then
            p.facing.dx, p.facing.dy = 0, dy > 0 and 1 or -1
        end
    else
        p.moving = false
    end
    -- Standing on an open portal cell leaves the region.
    local cx, cy = cellIndex(p.grid.x), cellIndex(p.grid.y)
    local cell = Rooms.cell(campaign.map, cx, cy)
    if cell and cell.piece == 'portal' and cell.exit and cell.exit.open ~= false then
        campaign:travel(cell.exit.to, cell.exit.arrival)
    end
end

return Explore
