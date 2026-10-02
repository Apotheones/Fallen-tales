local Progression = {}
local colors = {bow = {.96, .73, .32},
    guard = {.42, .76, 1}, universal = {.97, .57, .48}, heal = {.59, .94, .55}}

Progression.catalog = {
    {id = "bowPierce", weapon = "bow", title = "AGULHA DO SOL", color = colors.bow,
        description = "Eco do arqueiro que nunca parou no primeiro alvo. ARCO: flechas atravessam inimigos. Custo: -1 dano por flecha."},
    {id = "bowQuick", weapon = "bow", title = "CORDA VIVA", color = colors.bow,
        description = "Memória de dedos que cantavam antes da flecha. ARCO: +35% velocidade de carga. Exige novos disparos manuais."},
    {id = "guardPulse", title = "MARÉ DE FERRO", color = colors.guard,
        description = "Eco da muralha que devolvia o golpe ao mar. ESCUDO: +1 dano no pulso. Precisa bloquear pela frente; consome energia."},
    {id = "damage", repeatable = true, title = "AÇO DESPERTO", color = colors.universal,
        description = "Uma memória afiada empresta o fio. +1 dano no arco. A carga e a defesa não mudam."},
    {id = "heal", repeatable = true, title = "FÔLEGO VERDE", color = colors.heal,
        description = "Um eco gentil respira por você. Recupera 3 de vida agora. Nenhum bônus permanente de dano."},
    {id = "pickaxes", repeatable = true, title = "FERRO DE RESERVA", color = colors.universal,
        description = "Memória do pedreiro que abria a pedra na terceira pancada. +3 picaretas para paredes, pilares e entradas secretas."}
}

Progression.xpSteps = {4, 10, 18, 28, 40}

function Progression.start(game)
    game.upgrades, game.rewardChoices = {}, nil
end

function Progression.gainXp(game, amount)
    if game.practice then return end
    game.xp = game.xp + amount
    while game.level <= #Progression.xpSteps and game.xp >= Progression.xpSteps[game.level] do
        game.level = game.level + 1
        game.pendingOffer = game.pendingOffer + 1
    end
end

function Progression.xpLimit(game) return Progression.xpSteps[game.level or 1] end

function Progression.offer(game)
    local prior = (game.room and game.room.offers) or 0
    if game.room then game.room.offers = prior + 1 end
    local rng = love.math.newRandomGenerator(game.seed + game.roomId * 7919
        + ((game.floorNumber or 1) - 1) * 104729 + prior * 31)
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
    local g = {seed = 123, roomId = 1, damageBonus = 0, room = {}, xp = 0, level = 1, pendingOffer = 0,
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
    Progression.gainXp(g, Progression.xpSteps[1] - 1)
    assert(g.xp == Progression.xpSteps[1] - 1 and g.level == 1 and g.pendingOffer == 0, "XP below the step does not level")
    Progression.gainXp(g, Progression.xpSteps[2] + 1)
    assert(g.level == 3 and g.pendingOffer == 2, "A burst of XP queues one offer per level")
    assert(Progression.xpLimit(g) == Progression.xpSteps[3], "XP limit follows the current level")
    g.level = #Progression.xpSteps + 1
    assert(not Progression.xpLimit(g), "Max level has no next step")
    g.practice = true; local xp = g.xp
    Progression.gainXp(g, 99)
    assert(g.xp == xp, "Practice never gains XP")
    return true
end

return Progression
