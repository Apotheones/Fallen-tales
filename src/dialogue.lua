local utf8 = require('utf8')
local Lore = require('src.lore')
local Shop = require('src.shop')
local Dialogue = {}

-- game.dialogue = {node, title, lines, index, mode, reveal}
-- node owns the conversation; lines/index track the current speech, which may
-- come from the node itself or from a chosen option. Options loop back to the
-- node menu until SAIR/close. `reveal` is a presentation field: the renderer
-- types it over time, E completes it and then advances.
function Dialogue.open(game, node)
    game.dialogue = {node = node, title = node.title, lines = node.lines,
        index = 1, mode = 'lines', reveal = 0, voice = node.voice}
end

function Dialogue.npc(game, id)
    local last = game.met[id]
    local lines
    if not last then
        lines = Lore.lines[id].first
    elseif id == 'merchant' and last ~= game.floorNumber then
        lines = Lore.lines.merchant.floor[game.floorNumber] or Lore.lines.merchant.again
    else
        lines = Lore.lines[id].again
    end
    game.met[id] = game.floorNumber
    local options = Lore.options[id]
    if id == 'merchant' then options = Shop.inject(options) end
    Dialogue.open(game, {title = Lore.npcs[id].name, lines = lines, options = options, voice = id})
end

function Dialogue.advance(game)
    local d = game.dialogue
    if not d then return end
    if d.mode == 'shop' then d.mode, d.shop = 'options', nil; return end
    if d.mode ~= 'lines' then return end
    local line = d.lines[d.index]
    local len = utf8.len(line) or #line
    if d.reveal ~= nil and d.reveal < len then d.reveal = len; return end
    if d.index < #d.lines then
        d.index, d.reveal = d.index + 1, 0
    elseif d.node.options then
        d.mode = 'options'
    else
        game.dialogue = nil
    end
end

function Dialogue.choose(game, index)
    local d = game.dialogue
    if not d then return false end
    if d.mode == 'shop' then
        local bought = Shop.buy(game, index)
        d.shop = Shop.stock(game)
        return bought
    end
    if d.mode ~= 'options' then return false end
    local option = d.node.options[index]
    if not option then return false end
    if option.shop then
        d.mode, d.shop = 'shop', Shop.stock(game)
    elseif option.lines then
        d.lines, d.index, d.mode, d.reveal = option.lines, 1, 'lines', 0
    elseif not option.action or option.action(game) then
        game.dialogue = nil
    end
    return true
end

function Dialogue.close(game)
    game.dialogue = nil
end

-- Run in LÖVE: require("src.dialogue").selfCheck()
function Dialogue.selfCheck()
    local game = {met = {}, floorNumber = 1, room = {}, gold = 20}
    Dialogue.npc(game, 'merchant')
    local d = game.dialogue
    assert(d and d.index == 1 and d.lines == Lore.lines.merchant.first, 'First meeting uses intro lines')
    Dialogue.advance(game); Dialogue.advance(game)
    assert(d.index == 2 and d.reveal == 0, 'Advance completes the typewriter before moving on')
    d.reveal = math.huge; Dialogue.advance(game)
    d.reveal = math.huge; Dialogue.advance(game)
    assert(d.mode == 'options', 'Exhausted lines open the topic menu')
    Dialogue.advance(game); assert(d.mode == 'options' and game.dialogue, 'E does not pick topics')
    assert(not Dialogue.choose(game, 9), 'Invalid topic charged')
    assert(Dialogue.choose(game, 1) and d.mode == 'shop', 'COMPRAR did not open the counter')
    Dialogue.advance(game); assert(d.mode == 'options' and not d.shop, 'E did not leave the counter')
    assert(Dialogue.choose(game, 2) and d.mode == 'lines' and d.lines == Lore.options.merchant[1].lines,
        'Topic did not open its lines')
    while game.dialogue and game.dialogue.mode == 'lines' do
        game.dialogue.reveal = math.huge; Dialogue.advance(game)
    end
    assert(Dialogue.choose(game, #d.node.options) and not game.dialogue, 'SAIR did not close')
    Dialogue.npc(game, 'merchant')
    assert(game.dialogue.lines == Lore.lines.merchant.again, 'Same-floor revisit repeats the short greeting')
    Dialogue.close(game)
    game.floorNumber = 2
    Dialogue.npc(game, 'merchant')
    assert(game.dialogue.lines == Lore.lines.merchant.floor[2], 'New floor lost its greeting')
    Dialogue.close(game)
    Dialogue.npc(game, 'keeper')
    assert(game.dialogue.lines == Lore.lines.keeper.first, 'Keeper lost her introduction')
    return true
end

return Dialogue
