-- Evidencia para triage (Crivo/QA): replica tests/refugio.lua ate a linha 105
-- e imprime qual alvo o interact escolheu + o node aberto. Temporario.
local Campaign = require('src.campaign')
local Region = require('src.region')
local Rooms = require('src.rooms')
local Explore = require('src.explore')
local Refugio = require('src.refugio')
local Save = require('src.save')
local E = {}

local function finish(c)
    while c.dialogue do
        c.dialogue.reveal = math.huge
        c:advanceDialogue()
        if c.dialogue and c.dialogue.mode == 'options' then return end
    end
end

function E.run()
    Save.file = 'test_refugio_save.lua'
    Save.clear()
    local c = Campaign.new()
    c.data.flags.casaco = true
    c:completeStep('P01-E03')
    c:travel('cozinha', 'hub'); c:travel('hub', 'cozinha')
    c:travel('oficina', 'hub')
    c.player.grid.x, c.player.grid.y = 4, 4
    print('[ev-r] oficina interact=' .. tostring(c:interact()) .. ' preparo=' .. tostring(c:flag('preparoRefugio')))
    finish(c); c:closeDialogue()
    c:travel('hub', 'oficina')
    c.player.grid.x, c.player.grid.y = 26, 23
    print('[ev-r] cisterna interact=' .. tostring(c:interact()) .. ' agua=' .. tostring(c:flag('aguaRefugio')))
    finish(c); c:closeDialogue()
    print('[ev-r] ready=' .. tostring(Refugio.ready(c)) .. ' concluido=' .. tostring(c:flag('refugioConcluido')))
    print('[ev-r] facing=' .. c.player.facing.dx .. ',' .. c.player.facing.dy .. ' map=' .. c.map.id)
    c.player.grid.x, c.player.grid.y = 20, 19
    local t = c:interactTarget()
    print('[ev-r] target=' .. tostring(t and (t.kind .. ':' .. tostring(t.obj.id or (t.obj.npc and t.obj.npc.id) or '?'))))
    local ok = c:interact()
    print('[ev-r] interact=' .. tostring(ok)
        .. ' title=' .. tostring(c.dialogue and c.dialogue.title)
        .. ' mode=' .. tostring(c.dialogue and c.dialogue.mode)
        .. ' nlines=' .. tostring(c.dialogue and #c.dialogue.lines)
        .. ' options=' .. tostring(c.dialogue and c.dialogue.node.options and #c.dialogue.node.options)
        .. ' preview=' .. tostring(c.dialogue and c.dialogue.preview and c.dialogue.preview.id))
    finish(c)
    print('[ev-r] pos-finish dialogue=' .. tostring(c.dialogue ~= nil)
        .. ' mode=' .. tostring(c.dialogue and c.dialogue.mode))
end

return E
