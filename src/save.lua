-- Campaign persistence: a versioned Lua-table save written through
-- love.filesystem. Only plain simulation data may reach this module —
-- entities, functions and presentation state never serialize.
local Save = {}
Save.VERSION = 1
Save.file = 'cidade_save.lua'

local function serialize(value, out)
    local kind = type(value)
    if kind == 'number' or kind == 'boolean' then
        out[#out + 1] = tostring(value)
    elseif kind == 'string' then
        out[#out + 1] = string.format('%q', value)
    elseif kind == 'table' then
        out[#out + 1] = '{'
        local n = #value
        for i = 1, n do serialize(value[i], out); out[#out + 1] = ',' end
        for key, item in pairs(value) do
            local indexed = type(key) == 'number' and key % 1 == 0 and key >= 1 and key <= n
            if not indexed then
                if type(key) == 'string' and key:match('^[%a_][%w_]*$') then
                    out[#out + 1] = key .. '='
                else
                    out[#out + 1] = '['; serialize(key, out); out[#out + 1] = ']='
                end
                serialize(item, out); out[#out + 1] = ','
            end
        end
        out[#out + 1] = '}'
    else
        error('save: cannot persist ' .. kind, 3)
    end
end

function Save.pack(state)
    local out = {'return '}
    serialize(state, out)
    return table.concat(out)
end

function Save.unpack(text)
    local chunk, err = load(text, 'save', 't', {})
    if not chunk then return nil, err end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= 'table' then return nil, data end
    if (data.version or 0) > Save.VERSION then return nil, 'save from a newer version' end
    data.version = Save.VERSION
    return data
end

function Save.write(state)
    return love.filesystem.write(Save.file, Save.pack(state))
end

function Save.read()
    if not Save.exists() then return nil end
    local text = love.filesystem.read(Save.file)
    if not text then return nil end
    return Save.unpack(text)
end

function Save.exists()
    return love.filesystem.getInfo(Save.file, 'file') ~= nil
end

function Save.clear()
    if Save.exists() then return love.filesystem.remove(Save.file) end
    return true
end

function Save.selfCheck()
    local round = Save.unpack(Save.pack({
        version = 1, region = 'colina', x = 6.5, y = 4.25,
        steps = {['P01-E01'] = true}, flags = {casaco = true},
        regions = {colina = {visited = true, props = {bau = 'taken'}}},
        people = {doro = {met = true, location = 'colina'}},
        deaths = 0,
    }))
    assert(round.region == 'colina' and round.x == 6.5 and round.steps['P01-E01'] == true,
        'Save round-trip preserves region, position and steps')
    assert(round.regions.colina.props.bau == 'taken' and round.people.doro.location == 'colina',
        'Nested region and people tables survive serialization')
    assert(Save.unpack('return {version = ' .. (Save.VERSION + 1) .. '}') == nil,
        'Saves from a newer version are refused')
    assert(Save.unpack('garbage {') == nil, 'Corrupt saves fail cleanly')
    return true
end

return Save
