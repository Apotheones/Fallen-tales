local baton = require("vendor.baton")
local Input = {}; Input.__index = Input
local dirs = {w = {0, -1}, a = {-1, 0}, s = {0, 1}, d = {1, 0}}

function Input.new()
    return setmetatable({order = {}, queue = {}, spaceHeld = false, device = baton.new({controls = {
        w = {"key:w"}, a = {"key:a"}, s = {"key:s"}, d = {"key:d"},
        guard = {"key:lshift", "key:rshift"}}})}, Input)
end
function Input:pressed(key)
    local d = dirs[key]
    if d then
        for _, held in ipairs(self.order) do if held == key then return end end
        self.order[#self.order + 1] = key
        self.queue[#self.queue + 1] = {kind = "face", dx = d[1], dy = d[2]}
        self.queue[#self.queue + 1] = {kind = "step", dx = d[1], dy = d[2]}
    elseif key == "space" and not self.spaceHeld then
        self.spaceHeld = true
        self.queue[#self.queue + 1] = {kind = "charge"}
    end
end
function Input:released(key)
    for i = #self.order, 1, -1 do if self.order[i] == key then table.remove(self.order, i) end end
    local d = dirs[key]
    if d then self.queue[#self.queue + 1] = {kind = "release", dx = d[1], dy = d[2]} end
    if key == "space" and self.spaceHeld then
        self.spaceHeld = false
        self.queue[#self.queue + 1] = {kind = "fire"}
    end
end
function Input:clear() self.order, self.queue, self.spaceHeld = {}, {}, false end
function Input:update()
    self.device:update()
    local dx, dy = 0, 0
    for i = #self.order, 1, -1 do
        local key = self.order[i]
        if self.device:down(key) then dx, dy = unpack(dirs[key]); break end
    end
    local events = self.queue; self.queue = {}
    return {dx = dx, dy = dy, guard = self.device:down("guard"), events = events}
end
return Input
