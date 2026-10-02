-- Amâncio's counter: one unit per item, per shop room; a new floor restocks.
local Shop = {}

Shop.prices = {map = 6, pickaxes = 5, provision = 7}
local items = {
    {id = 'map', label = 'MAPA DO ANDAR'},
    {id = 'pickaxes', label = 'PICARETAS +4'},
    {id = 'provision', label = 'PROVISÃO +4 VIDA'},
}

function Shop.stock(game)
    local stock = {}
    for i, item in ipairs(items) do
        stock[i] = {id = item.id, label = item.label, price = Shop.prices[item.id],
            sold = game.room.sold ~= nil and game.room.sold[item.id] == true}
    end
    return stock
end

function Shop.buy(game, index)
    local item = items[index]
    if not item then return false end
    game.room.sold = game.room.sold or {}
    if game.room.sold[item.id] then return false end
    if game.gold < Shop.prices[item.id] then
        game:notify('Ouro insuficiente.')
        return false
    end
    game.gold = game.gold - Shop.prices[item.id]
    game.room.sold[item.id] = true
    if item.id == 'map' then game.mapReveal = true
    elseif item.id == 'pickaxes' then game.pickaxes = game.pickaxes + 4
    elseif item.id == 'provision' then
        game.player.health.current = math.min(10, game.player.health.current + 4)
    end
    game:notify('Comprado: ' .. item.label .. '.')
    return true
end

-- The merchant's topic menu gains the counter as its first entry; SAIR stays last.
function Shop.inject(options)
    local list = {{label = 'COMPRAR', shop = true}}
    for i, option in ipairs(options) do list[i + 1] = option end
    return list
end

return Shop
