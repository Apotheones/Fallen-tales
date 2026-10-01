local Progression = {}
local colors = {bow = {.96, .73, .32},
    guard = {.42, .76, 1}, universal = {.97, .57, .48}, heal = {.59, .94, .55}}

Progression.catalog = {
    {id = "bowPierce", weapon = "bow", title = "AGULHA DO SOL", color = colors.bow,
        description = "ARCO: flechas atravessam inimigos. Custo: -1 dano por flecha."},
    {id = "bowQuick", weapon = "bow", title = "CORDA VIVA", color = colors.bow,
        description = "ARCO: +35% velocidade de carga. Exige novos disparos manuais."},
    {id = "guardPulse", title = "MARÉ DE FERRO", color = colors.guard,
        description = "ESCUDO: +1 dano no pulso. Precisa bloquear pela frente; consome energia."},
    {id = "damage", repeatable = true, title = "AÇO DESPERTO", color = colors.universal,
        description = "+1 dano no arco. A carga e a defesa não mudam."},
    {id = "heal", repeatable = true, title = "FÔLEGO VERDE", color = colors.heal,
        description = "Recupera 3 de vida agora. Nenhum bônus permanente de dano."},
    {id = "pickaxes", repeatable = true, title = "FERRO DE RESERVA", color = colors.universal,
        description = "+3 picaretas para paredes, pilares e entradas secretas."}
}

function Progression.start(game)
    game.upgrades, game.rewardChoices = {}, nil
end

function Progression.offer(game)
    local rng = love.math.newRandomGenerator(game.seed + game.roomId * 7919 + ((game.floorNumber or 1) - 1) * 104729)
    local pool, matching, choices = {}, {}, {}
    for _, choice in ipairs(Progression.catalog) do
        if choice.repeatable or not game.upgrades[choice.id] then
            pool[#pool + 1] = choice
            if choice.weapon == game.player.weapon.name then matching[#matching + 1] = choice end
        end
    end
    if #matching > 0 then
        choices[1] = matching[rng:random(#matching)]
        for i, choice in ipairs(pool) do
            if choice == choices[1] then table.remove(pool, i); break end
        end
    end
    while #choices < 3 and #pool > 0 do
        choices[#choices + 1] = table.remove(pool, rng:random(#pool))
    end
    game.rewardChoices, game.reward = choices, true
    return choices
end

function Progression.choose(game, index)
    local choice = game.reward and game.rewardChoices and game.rewardChoices[index]
    if not choice then return false end
    if choice.id == "heal" then
        local hp = game.player.health
        hp.current = math.min(hp.max, hp.current + 3)
    elseif choice.id == "damage" then game.damageBonus = game.damageBonus + 1
    elseif choice.id == "pickaxes" then game.pickaxes = game.pickaxes + 3
    else game.upgrades[choice.id] = true end
    game.reward, game.rewardChoices, game.room.rewardTaken = false, nil, true
    game:notify(choice.title .. ": " .. choice.description)
    game:effect("reward", game.player.grid.x, game.player.grid.y, choice.id)
    return true
end

-- Run in LÖVE: require("src.progression").selfCheck(). No framework or assets needed.
function Progression.selfCheck()
    local g = {seed = 123, roomId = 1, damageBonus = 0, room = {},
        player = {weapon = {name = "bow"}, health = {current = 8, max = 10}, grid = {x = 4, y = 5}},
        notify = function() end, effect = function() end}
    Progression.start(g)
    local first = Progression.offer(g)
    assert(#first == 3 and first[1].weapon == "bow", "Three choices, one for current weapon")
    assert(first[1] ~= first[2] and first[1] ~= first[3] and first[2] ~= first[3], "Unique choices")
    assert(not Progression.choose(g, 0), "Invalid input must not consume reward")
    assert(Progression.choose(g, 1) and g.upgrades[first[1].id], "Choice grants upgrade")
    assert(not Progression.choose(g, 1) and g.room.rewardTaken, "Reward cannot be taken twice")
    for _, choice in ipairs(Progression.offer(g)) do assert(choice.id ~= first[1].id, "No duplicate upgrade") end
    g.rewardChoices = {Progression.catalog[5]}
    assert(Progression.choose(g, 1) and g.player.health.current == 10, "Healing respects max HP")
    g.reward, g.rewardChoices = true, {Progression.catalog[4]}
    assert(Progression.choose(g, 1) and g.damageBonus == 1, "Universal damage upgrade")
    return true
end

return Progression
