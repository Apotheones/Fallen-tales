-- Evidencia para o Crivo (Vespa): replica os fluxos que falham na suite
-- nova e imprime cada sub-condicao. Temporario — apagar depois do triage.
local Campaign = require('src.campaign')
local Save = require('src.save')
local E = {}

-- battle.lua:503 — com a contaminacao real dos cQ2/3/4 (T-GRADE injetado em
-- map.encounters, que Region.build compartilha com def.encounters cacheado)
function E.run()
    Save.file = 'test_campaign_save.lua'; Save.clear()
    for _ = 1, 3 do
        local cQ = Campaign.new()
        cQ.map.encounters[#cQ.map.encounters + 1] = {id = 'T-GRADE', kind = 'runa',
            x = 6, y = 18, nonLethal = true}
    end
    local cR = Campaign.new()
    cR.dialogue = nil
    print('[ev] enemies pos-injecao=' .. #cR.enemies)
    cR.player.grid.x, cR.player.grid.y = 6, 15
    cR.player.facing.dx, cR.player.facing.dy = 0, 1
    cR:interact()
    while cR.dialogue and cR.dialogue.mode ~= 'options' do
        cR.dialogue.reveal = math.huge; cR:advanceDialogue()
    end
    local offer
    for i, o in ipairs(cR.dialogue and cR.dialogue.node.options or {}) do
        if (o.label or ''):find('CAPACIDADE') then offer = i end
    end
    cR:chooseDialogue(offer)
    for _ = 1, 20 do
        if not cR.dialogue then break end
        if cR.dialogue.mode == 'options' then
            cR:chooseDialogue(#cR.dialogue.node.options)
        else
            cR.dialogue.reveal = math.huge; cR:advanceDialogue()
        end
    end
    cR:update(1 / 120, {})
    cR:endBattle('won')
    print('[ev] encounter=' .. tostring(cR.data.encounters['C01-Q1'])
        .. ' gradeHow=' .. tostring(cR.data.flags.gradeHow)
        .. ' grade=' .. tostring(cR.data.regions.colina.props.grade)
        .. ' runa=' .. tostring(cR.data.people.runa and cR.data.people.runa.location))
    print('[ev] #enemies=' .. #cR.enemies .. '  <-- sub-condicao que falha (esperado 0)')
end

-- explore_campaign.lua mercadoLeg:1208 — interact do carro sem facing south
function E.mercado()
    Save.file = 'test_campaign_save.lua'; Save.clear()
    local c = Campaign.new()
    c.dialogue = nil
    c.data.flags.conjuntoCozinha = true
    c:enter('mercado', 'hub')
    c.player.grid.x, c.player.grid.y = 25, 19
    print('[ev-m] facing apos enter=' .. c.player.facing.dx .. ',' .. c.player.facing.dy)
    local ok = c:interact()
    print('[ev-m] interact sem facing=' .. tostring(ok)
        .. ' node=' .. tostring(c.dialogue and c.dialogue.node and c.dialogue.node.title))
    c.dialogue = nil
    c.player.facing.dx, c.player.facing.dy = 0, 1
    ok = c:interact()
    print('[ev-m] interact facing S=' .. tostring(ok)
        .. ' node=' .. tostring(c.dialogue and c.dialogue.node and c.dialogue.node.title))
end

return E
