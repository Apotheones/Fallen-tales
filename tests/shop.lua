local Game = require("src.game")
local Shop = require("src.shop")
local Tests = {}

function Tests.run()
    local checks = 0
    local function check(v, m) checks = checks + 1; assert(v, m) end
    local function npcAt(g)
        for _, e in ipairs(g:entities()) do if e.npc then return e end end
    end

    -- The price table is the single source the stock rows are built from.
    check(Shop.prices.map == 6 and Shop.prices.pickaxes == 5 and Shop.prices.provision == 7,
        "tabela de preços fora do contrato")

    local g = Game.new(42042, false)
    g:enter(g.rooms.shopId)

    -- Stock shape: three fixed offers in counter order, nothing sold yet.
    local stock = Shop.stock(g)
    check(#stock == 3, "estoque não tem três ofertas")
    check(stock[1].id == "map" and stock[1].label == "MAPA DO ANDAR"
        and stock[1].price == Shop.prices.map, "oferta do mapa fora do contrato")
    check(stock[2].id == "pickaxes" and stock[2].label == "PICARETAS +4"
        and stock[2].price == Shop.prices.pickaxes, "oferta de picaretas fora do contrato")
    check(stock[3].id == "provision" and stock[3].label == "PROVISÃO +4 VIDA"
        and stock[3].price == Shop.prices.provision, "oferta de provisão fora do contrato")
    check(not stock[1].sold and not stock[2].sold and not stock[3].sold, "estoque nasceu vendido")

    -- Refusals charge nothing, mark nothing and explain themselves.
    g.gold = 3
    check(not Shop.buy(g, 2) and g.gold == 3 and not Shop.stock(g)[2].sold,
        "compra sem ouro cobrou")
    check(g.message == "Ouro insuficiente.", "falta de ouro não avisou")
    check(not Shop.buy(g, 0) and not Shop.buy(g, 4) and g.gold == 3, "índice inválido cobrou")

    -- The floor still hides common rooms, so the map has work to do.
    local hidden = 0
    for _, room in ipairs(g.rooms) do
        if room.kind ~= "secret" and room.kind ~= "supersecret" and not g:mapVisible(room) then
            hidden = hidden + 1
        end
    end
    check(hidden > 0, "nenhuma sala escondida antes do mapa")

    -- Buying the map pays its price, flags the sale and reveals common rooms only.
    g.gold = 18
    check(Shop.buy(g, 1) and g.gold == 12, "mapa não cobrou seis de ouro")
    check(g.mapReveal == true, "mapa não acendeu a revelação")
    check(g.room.sold and g.room.sold.map == true and Shop.stock(g)[1].sold == true,
        "venda do mapa não ficou marcada")
    for _, room in ipairs(g.rooms) do
        if room.kind == "secret" or room.kind == "supersecret" then
            check(not g:mapVisible(room), "mapa revelou sala secreta")
        else
            check(g:mapVisible(room), "mapa não revelou sala comum")
        end
    end

    -- Pickaxes and provision charge their prices and apply their effects.
    local tools = g.pickaxes
    check(Shop.buy(g, 2) and g.gold == 7 and g.pickaxes == tools + 4
        and g.room.sold.pickaxes == true, "picaretas não aplicaram o efeito")
    g.player.health.current = 4
    check(Shop.buy(g, 3) and g.gold == 0 and g.player.health.current == 8
        and g.room.sold.provision == true, "provisão não curou quatro de vida")

    -- A sold-out offer refuses a second purchase even with gold in hand.
    g.gold = 10
    check(not Shop.buy(g, 1) and g.gold == 10, "item vendido cobrou de novo")

    -- Leaving and returning keeps the counter memory; a new floor restocks.
    g:enter(1)
    g:enter(g.rooms.shopId)
    stock = Shop.stock(g)
    check(stock[1].sold and stock[2].sold and stock[3].sold, "vendido sumiu na revisita")
    g.state = "won"
    check(g:nextFloor() and g.floorNumber == 2, "andar não desceu")
    check(not g.mapReveal, "mapa do andar novo nasceu revelado")
    g:enter(g.rooms.shopId)
    stock = Shop.stock(g)
    check(not stock[1].sold and not stock[2].sold and not stock[3].sold,
        "vendido voltou no andar novo")

    -- Counter path: E opens the talk, COMPRAR is option 1, picks buy, E backs out.
    local g2 = Game.new(42042, false)
    g2:enter(g2.rooms.shopId)
    local merchant = npcAt(g2)
    check(merchant and merchant.npc.id == "merchant", "comerciante não apareceu na loja")
    g2.player.grid.x, g2.player.grid.y = merchant.grid.x, merchant.grid.y + 1
    g2.gold = 12
    g2.player.health.current = 9
    check(g2:interact() and g2.dialogue, "interação não abriu o diálogo")
    while g2.dialogue.mode == "lines" do
        g2.dialogue.reveal = math.huge
        g2:advanceDialogue()
    end
    check(g2.dialogue.mode == "options", "saudação não abriu as opções")
    local first = g2.dialogue.node.options[1]
    check(first and first.label == "COMPRAR" and first.shop == true, "COMPRAR não virou a opção 1")
    check(g2:chooseDialogue(1) and g2.dialogue.mode == "shop", "COMPRAR não abriu o balcão")
    check(#g2.dialogue.shop == 3 and g2.dialogue.shop[1].id == "map"
        and g2.dialogue.shop[2].id == "pickaxes" and g2.dialogue.shop[3].id == "provision",
        "balcão não recebeu o estoque")
    check(not g2:chooseDialogue(9) and g2.gold == 12, "escolha inválida no balcão cobrou")
    check(g2:chooseDialogue(3) and g2.gold == 5 and g2.player.health.current == 10,
        "provisão no balcão não curou até o teto")
    check(g2.dialogue.shop[3].sold == true, "balcão não atualizou o vendido")
    tools = g2.pickaxes
    check(g2:chooseDialogue(2) and g2.gold == 0 and g2.pickaxes == tools + 4,
        "compra pelo balcão não aplicou o efeito")
    g2:chooseDialogue(1)
    check(g2.gold == 0 and g2.message == "Ouro insuficiente.", "balcão vendeu sem ouro")
    check(g2.dialogue.mode == "shop", "compra recusada expulsou do balcão")
    g2:advanceDialogue()
    check(g2.dialogue.mode == "options", "E no balcão não voltou às opções")
    g2:closeDialogue()
    check(not g2.dialogue, "diálogo não fechou")

    print(string.format("shop.lua: %d checks", checks))
end

return Tests
