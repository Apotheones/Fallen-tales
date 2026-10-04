local E = require('tests.evidence_vespa')
local Campaign = require('src.campaign')
local Save = require('src.save')
return {run = function()
    Save.file = 'test_campaign_save.lua'; Save.clear()
    local cR = Campaign.new()
    cR.dialogue = nil
    cR.data.flags.runaConfronto = true
    cR:update(1 / 120, {dx = 0, dy = 0, guard = false, events = {}})
    print('[ev-r] scene=' .. tostring(cR.scene)
        .. ' unit=' .. tostring(cR.battle and cR.battle.enemies[1] and cR.battle.enemies[1].name))
    local rb, ru = cR.battle, cR.battle.enemies[1]
    ru.health.current = 3
    rb:damage(ru, 3, ru.grid.x + 1, ru.grid.y)
    print('[ev-r] spared=' .. tostring(ru.spared) .. ' hp=' .. ru.health.current)
    -- o teste espera so 4 ticks; medindo quanto realmente leva:
    for i = 1, 600 do
        cR:update(1 / 120, {dx = 0, dy = 0, guard = false, events = {}})
        if cR.dialogue then
            cR.dialogue.reveal = math.huge; cR:advanceDialogue()
            if cR.dialogue and cR.dialogue.mode == 'options' then
                cR:chooseDialogue(#cR.dialogue.node.options)
            end
        end
        if cR.scene == 'explore' then print('[ev-r] settled apos ' .. i .. ' ticks') break end
    end
    print('[ev-r] scene=' .. tostring(cR.scene)
        .. ' encounter=' .. tostring(cR.data.encounters['C01-Q1'])
        .. ' gradeHow=' .. tostring(cR.data.flags.gradeHow)
        .. ' grade=' .. tostring(cR.data.regions.colina.props.grade)
        .. ' runa=' .. tostring(cR.data.people.runa and cR.data.people.runa.location))
end}
