-- Item catalog for the campaign (docs/BATALHA_ACT_MERCY.md §4).
-- The persistent inventory lives in campaign.data.items as {[id] = qty};
-- this module only describes what each id is and does. Three categories:
--   equipavel  — fills a data.equipped slot; unlocks a battle command
--   consumivel — stacks; using one in battle costs the action
--   chave      — indescartável, uso narrativo (gates de ACT/fala)
local Items = {}

Items.catalog = {
    arco = {label = 'ARCO DE VIAGEM', cat = 'equipavel', slot = 'arma',
        desc = 'O arco dos anos de estrada — voltou debaixo da terra contigo. A aljava veio junto.'},
    picareta = {label = 'PICARETA DE MÃO', cat = 'equipavel', slot = 'ferramenta',
        desc = 'Corte e impacto de perto — golpeia o que a flecha não alcança.'},
    provisao = {label = 'PROVISÃO', cat = 'consumivel', stack = true,
        battle = {heal = 4},
        desc = 'Comida de caminhada. +4 de vida — na arena ou na estrada.'},
    reciboEma = {label = 'RECIBO DE EMA', cat = 'chave', chave = true,
        desc = 'O papel que prova a placa. Tinta antiga, assinatura legível — Ema não discute com o que assinou.'},
    esquemaCanal = {label = 'ESQUEMA DO CANAL', cat = 'chave', chave = true,
        desc = 'Traçado do ramo isolado. A régua de Ivo reconhece a linha — "provar antes de abrir".'},
    laudo = {label = 'LAUDO DE ESTRUTURA', cat = 'chave', chave = true,
        desc = 'Parede que segura cama não é cenário. O número que a vigia pede.'},
    fivela = {label = 'FIVELA DE UMA MÃO', cat = 'chave', chave = true,
        desc = 'Abre com uma mão só. Lia pagou metade adiantado — e cobrou em opinião.'},
}

function Items.def(id) return Items.catalog[id] end

-- A consumable can only enter the USAR submenu when it declares a battle
-- effect — chave items never fight, equipáveis habilitam comandos.
function Items.usableInBattle(id)
    local d = Items.catalog[id]
    return d and d.battle ~= nil
end

-- Ordena o inventário por categoria (equipável → consumível → chave) e
-- rótulo — fonte única para a tela da bolsa e o índice de seleção.
function Items.list(items)
    local order = {equipavel = 1, consumivel = 2, chave = 3}
    local out = {}
    for id, qty in pairs(items or {}) do
        local def = Items.catalog[id]
        if def and qty > 0 then out[#out + 1] = {id = id, qty = qty, def = def} end
    end
    table.sort(out, function(a, b)
        local oa, ob = order[a.def.cat] or 9, order[b.def.cat] or 9
        return oa == ob and a.def.label < b.def.label or oa < ob
    end)
    return out
end

return Items
