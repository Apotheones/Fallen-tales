local Game = require("src.game")
local Input = require("src.input")
local Campaign = require("src.campaign")
local LoreC = require("src.campaign_lore")
local Save = require("src.save")
local Sfx = require("src.sfx")
local game, campaign, input, renderer, hdscene
local mode = "campaign"
local screen, helpReturn, accumulator = "title", "title", 0
local timestep = 1 / 120
local pending = {}
local selectedMode = true
local testing, uiTesting, showcase, screenshotPath, scene, sceneRegion, pose, reduced
local captureAfter, captureClock = 0, 0
local warpTo
local oframe
-- Menu do título e abertura: estado navegável + quadros da intro.
local menuIdx, menuMode = 1, 'root'
local Items = require("src.items")
local bagIdx = 1
-- Abertura e cutscenes de rota: fonte de verdade é campaign_lore (Pena).
-- openingList = lista ativa de quadros; openingKey = flag gravada ao fechar.
local openingIdx, openingT, openingKey = 0, 0, nil
local openingList = {}
local IntroFrames = LoreC.introCutscene or {}
local routeFlags = {'passagemOficinas', 'passagemMercado', 'passagemReservatorio',
    'passagemSaloes', 'passagemFundacao'}

local function clearControls()
    input:clear()
    if game then game:clearIntents() end
    if campaign then campaign:clearIntents() end
    pending, accumulator = {}, 0
end

-- Beat sonoro por quadro: um `mood` no frame (contrato do Pena, mesmo dos
-- nodes de diálogo) dispara o emote da batida junto com a revelação.
local function frameCue()
    local fr = openingList[openingIdx]
    if fr and fr.mood then Sfx.play("emote_" .. fr.mood) end
end

local function startCampaign(fresh)
    if fresh then Save.clear() end
    local data = not fresh and Save.read() or nil
    campaign = data and Campaign.restore(data) or Campaign.new()
    campaign.reducedMotion = renderer and renderer.reducedMotion or false
    mode, screen = "campaign", "campaign"
    -- Abertura: só campanha nova sem a marca — CONTINUAR nunca reabre.
    if not campaign.data.flags.introSeen and #IntroFrames > 0 then
        openingList, openingKey, openingIdx, openingT = IntroFrames, 'introSeen', 1, 0
        screen = "opening"
        if renderer then renderer.openingFrame = openingList[1] end
        Sfx.play("cutscene_open"); frameCue()
    end
    clearControls()
end

local function restart(practice, seed)
    if practice == nil then practice = game and game.practice or selectedMode end
    selectedMode = practice
    game = Game.new(seed or love.math.random(100000, 999999), practice)
    clearControls()
    pending, accumulator, screen = {}, 0, "playing"
end

local function openHelp()
    helpReturn, screen = screen, "help"
    if renderer then renderer.helpPage, renderer.helpCard = "guide", 1 end
    Sfx.play("help_open")
    clearControls()
end

-- Linhas do menu de opções: montadas a cada chamada para refletir valores
-- vivos — toggle MUDO, um slider por canal de áudio (master incluso) e
-- MOVIMENTO REDUZIDO por último. O Traço desenha `rows`; aqui só nasce o
-- contrato {id, label, kind, value} — value é 'NN%' ou LIGADO/DESLIGADO.
local OPTION_CHANNELS = {'master', 'music', 'ui', 'world', 'voice', 'ambience', 'scene'}
local function optionRows()
    local rows = {{id = 'muted', label = 'MUDO', kind = 'toggle',
        value = (renderer and renderer.muted) and 'SIM' or 'NÃO'}}
    for _, ch in ipairs(OPTION_CHANNELS) do
        rows[#rows + 1] = {id = ch, label = Sfx.CHANNEL_LABELS[ch],
            kind = 'volume',
            value = math.floor(Sfx.getVolume(ch) * 100 + .5) .. '%'}
    end
    rows[#rows + 1] = {id = 'reducedMotion', label = 'MOVIMENTO REDUZIDO',
        kind = 'toggle',
        value = (renderer and renderer.reducedMotion) and 'LIGADO' or 'DESLIGADO'}
    return rows
end

function love.load(args)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(false)
    input = Input.new()
    for _, arg in ipairs(args or {}) do
        if arg == "--test" then testing = true end
        if arg == "--ui-test" then uiTesting = true end
        if arg == "--showcase" then showcase = true end
        if arg == "--reduced-motion" then reduced = true end
        if arg:match("^%-%-pose=") then pose = arg:sub(8) end
        if arg:match("^%-%-capture%-after=") then captureAfter = math.max(0, tonumber(arg:sub(17)) or 0) end
        if arg:match("^%-%-screenshot=") then screenshotPath = arg:sub(14) end
        if arg:match("^%-%-scene=") then scene, showcase = arg:sub(9), true end
        if arg:match("^%-%-region=") then sceneRegion = arg:sub(10) end
        if arg:match("^%-%-oframe=") then oframe = tonumber(arg:sub(10)) or 0 end
        if arg == "--menuopt" then menuMode, menuIdx = 'options', 2 end
        local px, py = arg:match("^%-%-pos=(%d+%.?%d*),(%d+%.?%d*)$")
        if px then warpTo = {x = tonumber(px), y = tonumber(py)} end
        local width, height = arg:match("^%-%-size=(%d+)x(%d+)$")
        if width then love.window.setMode(tonumber(width), tonumber(height), {resizable = true, minwidth = 900, minheight = 680}) end
    end
    if testing then
        local ok, err = xpcall(function()
            assert(require("src.sfx").selfCheck())
            assert(require("src.render").selfCheck())
            assert(require("src.lighting").selfCheck())
            assert(require("src.postfx").selfCheck())
            require("tests.floor").run()
            require("tests.terrain").run()
            require("tests.enemies").run()
            require("tests.combat").run()
            require("tests.dialogue").run()
            require("tests.shop").run()
            require("tests.explore3").run()
            require("tests.explore_campaign").run()
            require("tests.refugio").run()
            require("tests.repro").run()
            require("tests.battle").run()
            require("tests.pixel").run()
            print("RENDER ISOLATION CHECKS PASSED")
        end, debug.traceback)
        print(ok and "ALL CHECKS PASSED" or err)
        -- Evidência de runtime: os testes exercitam caminhos reais (diálogo,
        -- entrada de região, interação) — cada play efetivo conta aqui.
        do
            local count = require("src.sfx").stats.count
            local line = {}
            for id, n in pairs(count) do line[#line + 1] = id .. '=' .. n end
            table.sort(line)
            print('SFX PLAYS: ' .. table.concat(line, ' '))
        end
        local f = io.open(love.filesystem.getSource() .. "/test-results.txt", "w")
        if f then f:write(ok and "ALL CHECKS PASSED\n" or err); f:close() end
        love.event.quit(ok and 0 or 1)
        return
    end
    renderer = require("src.render").new()
    -- The arcade/three-floor session only exists for internal scenes and tests;
    -- the campaign is the real title flow.
    game = (showcase or uiTesting) and Game.new(42042, true) or nil
    if uiTesting then mode = "internal" end
    if showcase then
        mode = "internal"
        screen = "playing"
        game.player.grid.x, game.player.grid.y = 7, 8
        game.player.weapon.state, game.player.weapon.charge = "ready", .72
        for _, e in ipairs(game:entities()) do
            if e.enemy and e.enemy.kind == "dasher" then
                e.grid.x, e.grid.y = 12, 8
                e.enemy.state, e.enemy.timer, e.enemy.warningDuration = "warn", .55, .85
                e.enemy.dx, e.enemy.dy = -1, 0
                e.enemy.cells = require("src.rooms").line(game.room, 12, 8, -1, 0, 4)
            end
        end
    end
    if scene == "opening" then
        -- Captura da abertura: segue o caminho real do NOVA CAMPANHA
        -- (startCampaign decide a intro pela flag introSeen).
        Save.file = 'scene_campaign_save.lua'
        Save.clear()
        startCampaign(true)
        -- --oframe=N pula direto a um quadro da abertura p/ evidência.
        if oframe and oframe > 1 and openingList[oframe] then
            openingIdx = oframe
            renderer.openingFrame = openingList[openingIdx]
        end
        return
    end
    if scene == "prova-hd" or scene == "refugio-hd" then
        -- Cenas técnicas do render HD (Fase 0/1): fora dos dois modos —
        -- update e draw despacham direto para o módulo da cena.
        local mod = scene == "refugio-hd" and "src.scene_refugio" or "src.scene_hd"
        hdscene = require(mod).new({renderer = renderer,
            reducedMotion = reduced and true or false})
        return
    end
    if scene == "colina" or scene == "hub" or scene == "hub-batalha" or scene == "colina-doro"
        or scene == "colina-batalha" or scene == "colina-menu" or scene == "colina-mira"
        or scene == "colina-flecha" or scene == "colina-elenco"
        or scene == "colina-act" or scene == "colina-actlist" or scene == "colina-mercy"
        or scene == "colina-gesto" or scene == "colina-palco" or scene == "palco-regiao"
        or scene == "oficinas" or scene == "mercado" or scene == "boss-visual"
        or scene == "reservatorio" or scene == "saloes" or scene == "andlar" or scene == "hub-final"
        or scene == "capela" or scene == "cozinha" or scene == "pensao" or scene == "oficina" or scene == "escola"
        or scene == "arq-ritual" or scene == "arq-espinho"
        or scene == "arq-fuga" or scene == "arq-chefes"
        or scene == "contexto" or scene == "contexto-marco"
        or scene == "colina-inspecao" or scene == "bolsa" then
        mode = "campaign"
        -- Scene captures must not overwrite the player's real save file.
        Save.file = 'scene_campaign_save.lua'
        Save.clear()
        campaign = Campaign.new({legacy = scene == 'oficinas' or scene == 'mercado'
            or scene == 'reservatorio' or scene == 'saloes'})
        if scene == "hub" or scene == "hub-batalha" or scene == "hub-final" then campaign:travel("hub", "colina") end
        if scene == "andlar" or scene == "hub-final" then
            for _, flag in ipairs({'casaco', 'preparoRefugio', 'aguaRefugio', 'refugioConcluido'}) do
                campaign.data.flags[flag] = true
            end
            -- Fixture concluída: reproduz pertences, grade e despedida completos.
            campaign:giveItem('arco'); campaign:giveItem('picareta')
            campaign.data.flags.gradeHow = 'negotiated'
            campaign.data.regions.colina.props.grade = 'open'
            for _, step in ipairs({'P01-E02', 'P01-E03', 'P01-E04', 'REFUGIO-FIM'}) do
                campaign:completeStep(step)
            end
            campaign:syncRefugio()
            if scene == "andlar" then campaign:travel('andlar', 'hub') end
        end
        if scene == 'capela' or scene == 'cozinha' or scene == 'pensao' or scene == 'oficina' or scene == 'escola' then
            campaign:travel(scene, 'hub')
        end
        -- Evidência de imagem contextual: encosta num hotspot real e abre o
        -- node pelo caminho de sempre (interact anexa node.icon pelo id).
        if scene == "contexto" or scene == "contexto-marco" then
            if scene == "contexto-marco" then
                campaign.data.flags.refugioNovo = true
                campaign:travel('hub', 'colina')
            else
                campaign:travel('colina', 'hub')
            end
            while campaign.dialogue do
                campaign.dialogue.reveal = math.huge
                campaign:advanceDialogue()
            end
            if scene == "contexto-marco" then
                -- (20,19): marcoRefugio a 1 célula vence cartazRefugio (1.4)
                -- e fica longe de aurel/ancião — o node é o MARCO.
                campaign.player.grid.x, campaign.player.grid.y = 20, 19
            else
                campaign.player.grid.x, campaign.player.grid.y = 23, 11
            end
            campaign:interact()
            -- Cena de diagnóstico: a panorâmica de chegada (panoramaTime)
            -- cobre a UI por 5s; nestes cortes o diálogo é o objeto.
            campaign.panoramaTime = nil
        end
        -- Cenas de registro das regiões novas: chegam pela arrival 'hub'
        -- (todas as fichas a declaram) sem depender de flags de passagem.
        if scene == "oficinas" or scene == "mercado"
            or scene == "reservatorio" or scene == "saloes" then
            campaign:travel(scene, "hub")
        end
        if warpTo then campaign.player.grid.x, campaign.player.grid.y = warpTo.x, warpTo.y end
        if scene == "colina-doro" then
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 7.5, 4
            campaign:interact()
        elseif scene == "colina-batalha" or scene == "colina-menu" or scene == "colina-mira"
            or scene == "colina-flecha" or scene == "colina-inspecao"
            or scene == "colina-act" or scene == "colina-actlist" or scene == "colina-mercy" then
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 19
            -- T01-01 saiu do mapa (colidia com os ids da subquest da Teca):
            -- o smoke arma o bruto direto na arena, sem encontro de mundo.
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'T-SMOKE', {kind = 'dasher'})
            campaign.scene = 'battle'
            if scene == "colina-inspecao" then
                campaign.battle.mode, campaign.battle.inspect = 'inspect', 2
            end
            -- O menu social vive na fase de pausa do modelo fásico: a cena
            -- entra pela porta real (enterPause), não por tecla forjada.
            if scene == "colina-menu" then campaign.battle:enterPause(campaign) end
            -- Mira do modelo fásico: o arco carrega em tempo real — a cena
            -- congela a carga a meio caminho (o medidor do gutter enche).
            if scene == "colina-mira" or scene == "colina-flecha" then
                local wpn = campaign.battle.player.weapon
                wpn.state, wpn.charge = 'charging', .45
            end
            -- A flecha é o projétil real do mundo Concord: a cena o congela
            -- a meio voo — love.update segura o vulto do disparo na meia-vida.
            if scene == "colina-flecha" then
                local b = campaign.battle
                local wpn = b.player.weapon
                wpn.state, wpn.charge, wpn.action = 'action', 0, .1
                local shot = b:shoot(b.player, 0, -1, b:weaponStats().damage,
                    b.weapons.bow.interval, nil, 'bow')
                b.world:emit('flush')
                if shot then shot.grid.y = shot.grid.y - 2 end
            end
            -- Evidências da Fase B: modos sociais armados por cena — todos
            -- são submenus da pausa real (a placa lê VAGA).
            if scene == "colina-act" then
                campaign.battle.phase = 'pause'
                campaign.battle.mode, campaign.battle.actTarget = 'act', 1
            elseif scene == "colina-actlist" then
                campaign.battle.phase = 'pause'
                campaign.battle.mode, campaign.battle.actTarget, campaign.battle.actIndex = 'actlist', 1, 1
            elseif scene == "colina-mercy" then
                campaign.battle.phase = 'pause'
                campaign.battle.mode = 'mercy'
                for _, e in ipairs(campaign.battle.enemies) do e.mercy = true end
                campaign.battle.mercyIndex = 1
            end
        elseif scene == "colina-gesto" or scene == "colina-palco" then
            -- Evidências da Fase B: gesto não-verbal (crawler) e palco
            -- vazio com todos poupados.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 19
            local Battle = require('src.battle')
            if scene == "colina-gesto" then
                campaign.battle = Battle.new(campaign, 'GESTO-SMOKE', {units = {
                    {kind = 'crawler', x = 6, y = 5}, {kind = 'husk', x = 10, y = 5}}})
                local e = campaign.battle.enemies[1]
                campaign.battle:sayBark(e, 'announce')
                e.barkT = 99
            else
                campaign.battle = Battle.new(campaign, 'PALCO-SMOKE', {units = {
                    {kind = 'dasher', x = 7, y = 5}, {kind = 'ranger', x = 9, y = 5}}})
                campaign.battle.phase = 'pause'
                campaign.battle.mode = 'mercy'
                for _, e in ipairs(campaign.battle.enemies) do
                    e.mercy, e.spared = true, true
                end
                campaign.battle.mercyIndex = 1
                -- Variante de registro: um poupado a meio da despedida com
                -- o balão de retirada ainda aberto.
                local e = campaign.battle.enemies[2]
                e.spareT = .5
                campaign.battle:sayBark(e, 'spared')
                e.barkT = 99
            end
            campaign.scene = 'battle'
        elseif scene == "boss-visual" then
            -- Smoke dos telegrafos de chefe (§12): crates da Rute no chão +
            -- warns REAIS do modelo fásico armados por Enemies.helpers — a
            -- investida da Janda na linha do pilar (o impacto na peça é parte
            -- da promessa), o virote da Rute sobre a jogadora e o virote do
            -- Ivo na banda leste. Enquanto os chefes humanos não ganham defs
            -- próprias (passo 5), cada um telegrafa pelo def da família.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 17
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'BOSS-VISUAL', {
                units = {{kind = 'janda', x = 6, y = 7}, {kind = 'rute', x = 7, y = 6},
                    {kind = 'ivo', x = 12, y = 5}},
                crates = {{x = 9, y = 5}}
            })
            local b = campaign.battle
            local H = require('src.enemies').helpers
            local function armWarn(e, warn, ...)
                warn(b, e, ...)
                local a = e.enemy
                -- O véu do aviso enche com o progresso: timer recuado deixa
                -- o telegrafo meio armado para a captura ler o preenchimento.
                a.timer = (a.warningDuration or 1) * .55
            end
            armWarn(b.enemies[1], H.warnDash, 1, 0, 4, .85)
            armWarn(b.enemies[2], H.warnLine, 0, 1, 1.05)
            armWarn(b.enemies[3], H.warnLine, 0, 1, 1.05)
            campaign.scene = 'battle'
        elseif scene == "palco-regiao" then
            -- Smoke do palco por região: batalha armada com snapshot de
            -- região forjado — a janela do palco deve ler o motivo local.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 19
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'REGIAO-SMOKE', {units = {
                {kind = 'dasher', x = 7, y = 5}, {kind = 'ranger', x = 9, y = 5}}})
            if campaign.battle.snapshot then
                campaign.battle.snapshot.region = sceneRegion or 'oficinas'
            end
            campaign.scene = 'battle'
        elseif scene == "arq-ritual" then
            -- Evidência §15 (Crivo): a REGENTE telegrafa de verdade no modelo
            -- fásico — o engage real do def arma o warn (state/cells/mode no
            -- componente enemy), nunca um intent forjado da era-turno.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 17
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'C04-01', {units = {
                {kind = 'regent', x = 7, y = 5}, {kind = 'crawler', x = 10, y = 5}}})
            local b = campaign.battle
            local regent = b.enemies[1]
            local Enemies = require('src.enemies')
            if Enemies.regent.engage(Enemies.helpers, b, regent, b.player.grid) then
                local a = regent.enemy
                -- Véu meio cheio para a captura ler o telegrafo armado.
                a.timer = (a.warningDuration or 1) * .55
            end
            campaign.scene = 'battle'
        elseif scene == "arq-espinho" then
            -- Evidência §15 (Crivo): SEMEADOR em tempo real — a marca cai na
            -- faixa da jogadora e vira hazard armado no mundo. A cena roda o
            -- motor até o fusível estar meio queimado: a captura congela o
            -- véu do blast já enchendo sobre a faixa prometida.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 17
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'C04-Q01', {units = {
                {kind = 'sower', x = 5, y = 5}, {kind = 'crawler', x = 9, y = 5}}})
            local b = campaign.battle
            campaign.scene = 'battle'
            local idle = {dx = 0, dy = 0, guard = false, events = {}}
            for _ = 1, 600 do
                b:update(1 / 30, campaign, idle)
                if b.phase ~= 'action' or b.over then break end
                local armed = false
                for _, ent in ipairs(b:entities()) do
                    if ent.hazard
                        and ent.hazard.timer < (ent.hazard.duration or 1) * .5 then
                        armed = true
                    end
                end
                if armed then break end
            end
        elseif scene == "arq-fuga" then
            -- Evidência §6 (Traço): micro-fase de fuga real — startFlee
            -- acende a saída na borda oposta e cada hostil vivo ganha a
            -- despedida. O laço roda o motor até o primeiro warn armar e
            -- devolve o timer recuado: a captura lê o portal aceso, o selo
            -- de fuga sobre a jogadora e a volley telegrafada no chão.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 18
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'FUGA-SMOKE', {units = {
                {kind = 'dasher', x = 7, y = 5}, {kind = 'ranger', x = 10, y = 5}}})
            local b = campaign.battle
            campaign.scene = 'battle'
            b:startFlee(campaign)
            local idle = {dx = 0, dy = 0, guard = false, events = {}}
            for _ = 1, 240 do
                b:update(1 / 30, campaign, idle)
                if not b.fleeing then break end
                local armed = false
                for _, e in ipairs(b.enemies) do
                    if e.enemy and e.enemy.state == 'warn' then armed = true end
                end
                if armed then break end
            end
            for _, e in ipairs(b.enemies) do
                local a = e.enemy
                if a and a.state == 'warn' then
                    a.timer = (a.warningDuration or 1) * .9
                end
            end
        elseif scene == "arq-chefes" then
            -- Smoke dos telegrafos autorais (COMBATE_MERGE §12): os quatro
            -- chefes humanos armam o warn REAL do próprio def no mesmo
            -- quadro — martelo da Janda sobre o pilar leste, vara da Rute
            -- no caixote ao norte, jato do Ivo na coluna da jogadora e a
            -- prensa do Beltran na lane oeste-leste.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            campaign.player.grid.x, campaign.player.grid.y = 8, 17
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'CHEFES-SMOKE', {
                units = {{kind = 'janda', x = 4, y = 6}, {kind = 'rute', x = 4, y = 9},
                    {kind = 'ivo', x = 11, y = 5}, {kind = 'beltran', x = 11, y = 8}},
                crates = {{x = 7, y = 5}},
                channels = {rows = {}, cols = {7}},
            })
            local b = campaign.battle
            campaign.scene = 'battle'
            b.player.grid.x, b.player.grid.y = 7, 8
            local Enemies = require('src.enemies')
            for _, e in ipairs(b.enemies) do
                local def = Enemies[e.enemy.kind]
                if def and def.engage(Enemies.helpers, b, e, b.player.grid) then
                    local a = e.enemy
                    -- Véu meio cheio para a captura ler o telegrafo armado.
                    a.timer = (a.warningDuration or 1) * .55
                end
            end
        elseif scene == "hub-batalha" then
            -- Smoke do fundo contextual: batalha armada no Refúgio — o vazio
            -- da arena deve ler como interior da casa funerária, não a colina.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'HUB-SMOKE', {units = {
                {kind = 'dasher', x = 7, y = 5}, {kind = 'ranger', x = 9, y = 5}}})
            campaign.scene = 'battle'
            campaign:effect('room', campaign.player.grid.x, campaign.player.grid.y)
        elseif scene == "colina-elenco" then
            -- Vitrine de sprites: arena povoada com todos os kinds que têm
            -- sheet gerada — cada silhueta deve ler à primeira vista.
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
            local Battle = require('src.battle')
            campaign.battle = Battle.new(campaign, 'ELENCO', {units = {
                {kind = 'ranger', x = 3, y = 5}, {kind = 'dasher', x = 5, y = 5},
                {kind = 'warden', x = 7, y = 5}, {kind = 'breaker', x = 9, y = 5},
                {kind = 'crawler', x = 11, y = 5}, {kind = 'husk', x = 3, y = 7},
                {kind = 'sower', x = 5, y = 7}, {kind = 'watcher', x = 7, y = 7},
                {kind = 'veteran', x = 9, y = 7}, {kind = 'regent', x = 11, y = 7},
                {kind = 'demolisher', x = 7, y = 9}}})
            campaign.scene = 'battle'
        -- As cenas contexto/contexto-marco abrem o diálogo DO OBJETO depois
        -- do dreno da chegada — não podem ser drenadas outra vez aqui.
        elseif scene ~= "contexto" and scene ~= "contexto-marco" then
            while campaign.dialogue do campaign.dialogue.reveal = math.huge; campaign:advanceDialogue() end
        end
        screen = "campaign"
        if scene == "bolsa" then
            campaign:giveItem('arco'); campaign:giveItem('picareta')
            campaign:giveItem('provisao', 3); campaign:giveItem('reciboEma')
            campaign:giveItem('laudo')
            screen = "bolsa"; bagIdx = 2
        end
    end
    if mode ~= "internal" then goto endScenes end
    if scene == "map" or scene == "map-wide" or scene == "shop" or scene == "secret" or scene == "targets" then
        game = Game.new(42042, false)
        if scene == "map-wide" then
            for _, room in ipairs(game.rooms) do room.visited, room.discovered = true, true end
        elseif scene ~= "map" then
            game:enter(scene == "shop" and game.rooms.shopId or scene == "targets" and game.rooms.superSecretId or game.rooms.secretId)
            game.player.grid.x, game.player.grid.y = math.ceil(game.room.w / 2), math.ceil(game.room.h / 2)
            if scene == "shop" then
                for _, e in ipairs(game:entities()) do
                    if e.npc then game.player.grid.x, game.player.grid.y = e.grid.x, e.grid.y + 1 end
                end
            end
        end
    elseif scene == "boss" or scene == "phase" then
        game = Game.new(42042, false)
        game:enter(game.rooms.bossId)
        game.player.grid.x, game.player.grid.y = 5, 6
        for _, e in ipairs(game:entities()) do
            if e.enemy and e.enemy.kind == "warden" then
                if scene == "phase" then
                    e.health.current, e.enemy.phase2, e.enemy.frontalArmor = 10, true, false
                    game:notify("O Guardião rompeu o selo. Avisos mais rápidos: procure os espaços vazios!")
                end
                require("src.enemies").helpers.warnCross(game, e, 1.15)
            end
        end
    elseif scene == "reward" then
        game = Game.new(42042, false)
        game.room.cleared = true
        require("src.progression").offer(game)
    elseif scene == "floor2" or scene == "floor3" then
        game = Game.new(42042, false)
        local depth = scene == "floor3" and 3 or 2
        while game.floorNumber < depth do game.state = "won"; game:nextFloor() end
    elseif scene == "seal" or scene == "sealopen" then
        game = Game.new(42042, false)
        game.gold = 9
        local leaf = game.rooms[game.rooms.sealedId]
        for _, room in ipairs(game.rooms) do
            for _, door in ipairs(room.doors) do
                if door.sealed and door.to == leaf.id then
                    game:enter(room.id)
                    local ax, ay = require("src.rooms").arrival(game.room, door.side)
                    game.player.grid.x, game.player.grid.y = ax, ay
                end
            end
        end
        if scene == "sealopen" then
            game:interact()
            while game.dialogue and game.dialogue.mode == "lines" do
                game.dialogue.reveal = math.huge
                game:advanceDialogue()
            end
        end
    elseif scene == "tactic" then
        game = Game.new(42042, false)
        game:enter(2); game:enter(1)
    elseif scene == "blast" then
        for _, e in ipairs(game:entities()) do
            if e.resonator then require("src.environment").prime(game, e); break end
        end
    elseif scene == "terrain" or scene == "terrain-after" then
        local Environment = require("src.environment")
        game.player.grid.x, game.player.grid.y = 7, 4
        game.player.facing.dx, game.player.facing.dy = 1, 0
        Environment.impact(game, 8, 4, 1, 0)
        for _, e in ipairs(game:entities()) do
            if e.resonator and e.grid.x == 7 then Environment.prime(game, e) end
        end
        if scene == "terrain-after" then
            game.world:getSystem(Environment):update(.63)
            game.world:emit("flush")
            game.player.grid.x, game.player.grid.y = 13, 3
        end
    elseif scene == "motion" then
        game.player.grid.x, game.player.grid.y = 7, 7
        game.player.weapon.state, game.player.weapon.charge, game.player.weapon.triggerHeld = "charging", 0, true
    elseif scene == "reference" then
        game.player.grid.x, game.player.grid.y = 12, 6
        game.player.weapon.state, game.player.weapon.charge = "ready", .72
    elseif scene == "help" then screen = "help"
    elseif scene == "cards" then
        for i, card in ipairs(require("src.lore").cards) do
            if i <= 6 then game.cards[card.id] = true end
        end
        renderer.helpPage, renderer.helpCard, screen = "cards", 2, "help"
    elseif scene == "inscription" then
        game = Game.new(42042, false)
        local mark = (game.room.inscriptions or {})[1]
        if mark then
            local Rooms = require("src.rooms")
            for _, d in ipairs({{0, 1}, {1, 0}, {0, -1}, {-1, 0}}) do
                local cell = Rooms.cell(game.room, mark.x + d[1], mark.y + d[2])
                if cell and cell.ground == "floor" and not cell.piece then
                    game.player.grid.x, game.player.grid.y = mark.x + d[1], mark.y + d[2]
                    break
                end
            end
        end
    elseif scene == "intro" then
        game = Game.new(42042, false)
        game:enter(game.rooms.bossId)
    elseif scene == "dead" then game.state = "dead"
    elseif scene == "won" then game.state = "won"
    elseif scene == "dialogue" or scene == "counter" then
        game = Game.new(42042, false)
        game:enter(game.rooms.shopId)
        game.gold = 14
        for _, e in ipairs(game:entities()) do
            if e.npc then
                game.player.grid.x, game.player.grid.y = e.grid.x, e.grid.y + 1
                game:interact()
                break
            end
        end
        if scene == "counter" and game.dialogue then
            while game.dialogue.mode == "lines" do
                game.dialogue.reveal = math.huge
                game:advanceDialogue()
            end
            game:chooseDialogue(1)
        end
    elseif scene == "paused" then screen = "paused" end
    ::endScenes::
    if reduced then renderer.reducedMotion = true end
    if showcase and pose then
        local actor, direction = pose:match('^(%a+)%-(%a+)$')
        local directions = {east = {1, 0}, south = {0, 1}, west = {-1, 0}, north = {0, -1}}
        local f = directions[direction or 'east'] or directions.east
        game.player.facing.dx, game.player.facing.dy = f[1], f[2]
        local p = game.player
        p.weapon.state, p.weapon.charge = 'empty', 0
        if actor == 'move' then
            p.motion.fromX, p.motion.fromY = p.grid.x - f[1], p.grid.y - f[2]
            p.motion.remaining = p.motion.duration / 2
        elseif actor == 'charge' then p.weapon.state, p.weapon.charge = 'charging', .36
        elseif actor == 'ready' then p.weapon.state, p.weapon.charge = 'ready', .72
        elseif actor == 'fire' then p.weapon.state, p.weapon.action = 'action', .1
        elseif actor == 'guard' then p.guard.active = true
        elseif actor == 'mine' then p.weapon.mineTimer, p.weapon.mineDx, p.weapon.mineDy = .04, f[1], f[2]
        elseif actor == 'hurt' then
            renderer.actors:update(0, game, screen, renderer.reducedMotion)
            p.health.current = 9
        elseif actor == 'death' then p.health.current, game.state = 0, 'dead' end
    end
    if uiTesting then
        local ok, err = xpcall(function()
            require("tests.ui").run(function() return game, screen, renderer end)
            require("tests.pixel").runUi(function() return game, screen, renderer end)
        end, debug.traceback)
        print(ok and "ALL UI CHECKS PASSED" or err)
        local file = io.open(love.filesystem.getSource() .. "/ui-test-results.txt", "w")
        if file then file:write(ok and "ALL UI CHECKS PASSED\n" or err); file:close() end
        love.event.quit(ok and 0 or 1)
    end
end

function love.update(dt)
    if testing then return end
    dt = math.min(dt, .1)
    captureClock = captureClock + dt
    if hdscene then hdscene:update(dt); return end
    Sfx.update(dt)
    if renderer then Sfx.setMuted(renderer.muted) end
    -- Pausa, ajuda e cutscene congelam a simulação (a música já cai para .16
    -- nelas): a ambiência abaixa junto para a mistura não abrir discrepante.
    Sfx.setPaused(screen == "paused" or screen == "help" or screen == "opening")
    local frame = input:update()
    if scene == "motion" then frame.dx, frame.dy = 1, 0 end
    for _, event in ipairs(frame.events) do pending[#pending + 1] = event end
    if mode == "campaign" then
        if screen == "campaign" and (not showcase or scene == "colina" or scene == "hub" or scene == "hub-final") then
            accumulator = accumulator + dt
            while accumulator >= timestep do
                local sceneBefore = campaign.scene
                -- MERGE-SHIM (COMBATE_MERGE §8): o frame completo chega à
                -- batalha fásica — guard e events alimentam a fase de ação.
                campaign:update(timestep, {dx = frame.dx, dy = frame.dy,
                    guard = frame.guard, events = pending})
                pending = {}
                accumulator = accumulator - timestep
                -- Entering or leaving a battle drops held keys and queued
                -- commands so nothing leaks across the transition.
                if campaign.dialogue or campaign.scene ~= sceneBefore then clearControls(); break end
            end
        else pending = {} end
        -- Rotas recém-abertas pausam uma vez em beat curto do Pena
        -- (LoreC.cutscenes[flag]) — primeira vez por flag, depois nunca.
        if screen == "campaign" and not campaign.dialogue then
            for _, f in ipairs(routeFlags) do
                if campaign:flag(f) and not campaign:flag('cut_' .. f)
                    and LoreC.cutscenes[f] then
                    openingList = {{art = 'portas', lines = LoreC.cutscenes[f].lines,
                        mood = LoreC.cutscenes[f].mood}}
                    openingKey, openingIdx, openingT = 'cut_' .. f, 1, 0
                    screen = "opening"
                    renderer.openingFrame = openingList[1]
                    Sfx.play("cutscene_open"); frameCue()
                    break
                end
            end
        end
        -- Menu do título + abertura: estado navegável exposto ao renderer;
        -- openingT alimenta o fade curto entre quadros (reduced-motion ignora).
        if screen == "opening" then openingT = openingT + dt end
        -- Cursor nunca descansa sobre item morto: sem save ele estaciona
        -- em NOVA CAMPANHA.
        if screen == "title" and menuMode == 'root'
            and menuIdx == 1 and not Save.exists() then menuIdx = 2 end
        -- `rows` alimenta o desenho do menu de opções (Traço consome o
        -- contrato {id,label,kind,value}); fora de 'options' fica só como
        -- dado extra barato, sempre coerente com o estado vivo.
        renderer.titleMenu = {idx = menuIdx, mode = menuMode, rows = optionRows()}
        renderer.bagState = {idx = bagIdx}
        renderer.openingT = openingT
        renderer:updateCampaign(dt, campaign, screen)
        -- O vulto do disparo vive .16s e sumiria antes da captura; a cena o
        -- segura a meio voo (a linha do tiro já está congelada no setup).
        if scene == "colina-flecha" then
            for _, b in ipairs(renderer.feedback.bolts) do b.life = b.max * .5 end
        end
        return
    end
    if screen == "playing" and (not showcase or scene == "motion") then
        accumulator = accumulator + dt
        while accumulator >= timestep do
            game:update(timestep, {dx = frame.dx, dy = frame.dy, guard = frame.guard, events = pending})
            pending = {}
            accumulator = accumulator - timestep
            if game.reward or game.dialogue or game.state ~= "playing" then clearControls(); break end
        end
    else pending = {} end
    renderer:update(dt, game, screen)
end

-- Prancha de silhuetas: todo kind em PRETO PURO sobre fundo claro e, logo
-- abaixo, o sprite colorido — a figura deve ser reconhecível pela sombra
-- E pelo rosto. Escala do jogo (x2).
local function drawSilhouettes()
    local G = love.graphics
    local Pal = require("src.palettes")
    local PixelFont = require("src.pixel_font")
    local P = require("src.pixel_world").palette
    G.clear(Pal.moon.disc)
    local actors = renderer.actors
    local kinds = {"player", "dasher", "breaker", "demolisher", "warden", "crawler",
        "husk", "ranger", "sower", "watcher", "veteran", "regent",
        "npc_merchant", "npc_keeper", "npc_doro", "npc_runa", "npc_bento",
        "npc_teca", "npc_sabela", "npc_nilo", "npc_aurel",
        "npc_janda", "npc_brina", "npc_neco", "npc_rute", "npc_ema",
        "npc_ivo", "npc_mara", "npc_beltran", "npc_cira",
        "npc_traba", "npc_trabb", "npc_guarda", "npc_feirante",
        "npc_voz", "npc_equipe", "npc_ajudante", "npc_plateia"}
    local cols = 7
    for i, kind in ipairs(kinds) do
        local sheet = actors.sheets[kind]
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local px, py = 56 + col * 152, 86 + row * 236
        if sheet and sheet.animations.idle then
            G.setColor(P.ink)
            sheet.animations.idle[2]:draw(sheet.image, px, py, 0, 2, 2, 20, 44)
            G.setColor(1, 1, 1)
            sheet.animations.idle[2]:draw(sheet.image, px, py + 96, 0, 2, 2, 20, 44)
            -- Retrato ampliado ao lado do sprite colorido, não flutuando.
            if sheet.portrait then
                local quad = sheet.animations.idle[2].frames[1]
                local qx, qy = quad:getViewport()
                local pc = sheet.portrait
                local sub = G.newQuad(qx + pc[1], qy + pc[2], pc[3], pc[4],
                    sheet.image:getDimensions())
                G.draw(sheet.image, sub, px + 46, py + 100, 0, 2, 2)
            end
        end
        -- Label dentro da célula, direto sob o sprite colorido — nada de
        -- faixa solta onde a sombra da fileira seguinte o engole.
        local label = PixelFont.clean(kind:gsub('^npc_', ''))
        G.setFont(renderer.hudFont); G.setColor(P.ink)
        G.print(label, math.floor(px - renderer.hudFont:getWidth(label) / 2), py + 116)
    end
end

-- Matriz de cobertura: para cada kind, o idle das quatro direções, um
-- quadro de ação (warn/move) e o retrato — as quatro direções têm que
-- ser desenhos distintos, não o mesmo sprite girado.
-- Comparativo D15: a Transeunte do HEAD (iter7, capa longa) ao lado da
-- variante nova (manto curto assimétrico + aljava de quadril) — mesmo
-- tamanho real, 4 direções e retrato.
local function drawPlayerDiff()
    local G = love.graphics
    local Pal = require("src.palettes")
    local PixelFont = require("src.pixel_font")
    local P = require("src.pixel_world").palette
    G.clear(Pal.moon.disc)
    local oldActors = dofile('tools/_player_prev.lua').new()
    local pair = {{sheet = oldActors.sheets.player, tag = 'ANTIGO ITER7'},
        {sheet = renderer.actors.sheets.player, tag = 'NOVO D15'}}
    for i, row in ipairs(pair) do
        local py = 120 + (i - 1) * 300
        local tag = PixelFont.clean(row.tag)
        G.setFont(renderer.hudFont); G.setColor(P.ink)
        G.print(tag, 60, py - 46)
        if row.sheet and row.sheet.animations.idle then
            for d = 1, 4 do
                local px = 80 + (d - 1) * 130
                G.setColor(P.ink)
                row.sheet.animations.idle[d]:draw(row.sheet.image, px, py, 0, 2, 2, 20, 44)
                G.setColor(1, 1, 1)
                row.sheet.animations.idle[d]:draw(row.sheet.image, px, py + 100, 0, 2, 2, 20, 44)
            end
            if row.sheet.portrait then
                local quad = row.sheet.animations.idle[2].frames[1]
                local qx, qy = quad:getViewport()
                local pc = row.sheet.portrait
                local sub = G.newQuad(qx + pc[1], qy + pc[2], pc[3], pc[4],
                    row.sheet.image:getDimensions())
                G.draw(row.sheet.image, sub, 620, py + 20, 0, 4, 4)
            end
        end
    end
end

local function drawDirections()
    local G = love.graphics
    local Pal = require("src.palettes")
    local PixelFont = require("src.pixel_font")
    local P = require("src.pixel_world").palette
    G.clear(Pal.moon.disc)
    local actors = renderer.actors
    local kinds = {"player", "dasher", "breaker", "demolisher", "warden", "crawler",
        "husk", "ranger", "sower", "watcher", "veteran", "regent",
        "npc_merchant", "npc_keeper", "npc_doro", "npc_runa", "npc_bento",
        "npc_teca", "npc_sabela", "npc_nilo", "npc_aurel",
        "npc_janda", "npc_brina", "npc_neco", "npc_rute", "npc_ema",
        "npc_ivo", "npc_mara", "npc_beltran", "npc_cira",
        "npc_traba", "npc_trabb", "npc_guarda", "npc_feirante",
        "npc_voz", "npc_equipe", "npc_ajudante", "npc_plateia"}
    for i, kind in ipairs(kinds) do
        local sheet = actors.sheets[kind]
        local y = 40 + (i - 1) * 54
        if sheet and sheet.animations.idle then
            for d = 1, 4 do
                local anim = sheet.animations.idle[d]
                if anim then
                    G.setColor(1, 1, 1)
                    anim:draw(sheet.image, 70 + (d - 1) * 56, y, 0, 1, 1, 20, 44)
                end
            end
            local act = sheet.animations.warn and sheet.animations.warn[2]
                or sheet.animations.move and sheet.animations.move[2]
            if act then act:draw(sheet.image, 300, y, 0, 1, 1, 20, 44) end
            if sheet.portrait then
                local quad = sheet.animations.idle[2].frames[1]
                local qx, qy = quad:getViewport()
                local pc = sheet.portrait
                local sub = G.newQuad(qx + pc[1], qy + pc[2], pc[3], pc[4],
                    sheet.image:getDimensions())
                G.draw(sheet.image, sub, 356, y - 36, 0, 3, 3)
            end
        end
        local label = PixelFont.clean(kind:gsub('^npc_', ''))
        G.setFont(renderer.hudFont); G.setColor(P.ink)
        G.print(label, 420, y - 10)
    end
end

-- Prancha de elenco: matriz FORA de tela em 3x — cada kind lê as quatro
-- direções de idle, um quadro de ofício/aviso e o retrato neutro; grava
-- o PNG direto em screenshots/prancha-<grupo>.png. --region= escolhe o
-- lote (hub, regioes, figurantes, inimigos, fera); sem ele, 'all'.
local function prancha()
    local G = love.graphics
    local Pal = require("src.palettes")
    local PixelFont = require("src.pixel_font")
    local P = require("src.pixel_world").palette
    local grupos = {
        hub = {"npc_doro", "npc_runa", "npc_bento", "npc_teca", "npc_sabela",
            "npc_nilo", "npc_aurel", "npc_merchant", "npc_keeper"},
        regioes = {"npc_janda", "npc_brina", "npc_neco", "npc_ema", "npc_rute",
            "npc_mara", "npc_ivo", "npc_beltran", "npc_cira"},
        figurantes = {"npc_traba", "npc_trabb", "npc_guarda", "npc_feirante",
            "npc_voz", "npc_equipe", "npc_ajudante", "npc_plateia",
            "npc_anciao", "npc_lavadeira", "npc_carregador", "npc_lenhador",
            "npc_crianca"},
        inimigos = {"dasher", "breaker", "demolisher", "warden", "ranger",
            "sower", "watcher", "veteran", "regent", "crawler", "husk"},
    }
    if sceneRegion == 'retratos' then
        -- As 9 emoções de cada ficha: mesma anatomia, expressão trocando.
        local kinds = {"npc_doro", "npc_runa", "npc_bento", "npc_teca",
            "npc_sabela", "npc_nilo", "npc_aurel", "npc_merchant", "npc_keeper"}
        local scale, rowH, labelW, colW = 4, 120, 132, 20 * 4 + 8
        local canvas = G.newCanvas(labelW + 9 * colW + 20, #kinds * rowH + 20)
        canvas:setFilter('nearest', 'nearest')
        G.setCanvas(canvas); G.clear(Pal.moon.disc); G.setFont(renderer.hudFont)
        local emotions = {'neutral', 'joy', 'sad', 'stern', 'soft',
            'fear', 'anger', 'shame', 'awe'}
        for i, kind in ipairs(kinds) do
            local sheet = renderer.actors.sheets[kind]
            local y = 12 + (i - 1) * rowH
            G.setColor(P.ink)
            G.print(PixelFont.clean(kind:gsub('^npc_', ''):upper()), 10, y + 30)
            if sheet and sheet.portraits then
                for j, emo in ipairs(emotions) do
                    local pc = sheet.portraits[emo]
                    if pc then
                        local sub = G.newQuad(pc[1], pc[2], pc[3], pc[4],
                            sheet.image:getDimensions())
                        G.setColor(1, 1, 1)
                        G.draw(sheet.image, sub, labelW + (j - 1) * colW, y + 4, 0, scale, scale)
                    end
                end
            end
        end
        G.setCanvas()
        local f = assert(io.open('screenshots/prancha-retratos.png', 'wb'))
        f:write(canvas:newImageData():encode('png'):getString()); f:close()
        print('prancha: screenshots/prancha-retratos.png')
        love.event.quit(0)
        return
    end
    local kinds
    if grupos[sceneRegion or ''] then kinds = grupos[sceneRegion]
    else
        kinds = {"player"}
        for _, g in ipairs({'hub', 'regioes', 'figurantes', 'inimigos'}) do
            for _, k in ipairs(grupos[g]) do kinds[#kinds + 1] = k end
        end
    end
    local scale, rowH, labelW, colW = 3, 176, 132, 40 * 3 + 8
    local canvas = G.newCanvas(labelW + 5 * colW + 120, #kinds * rowH + 30)
    canvas:setFilter('nearest', 'nearest')
    G.setCanvas(canvas); G.clear(Pal.moon.disc); G.setFont(renderer.hudFont)
    for i, kind in ipairs(kinds) do
        local sheet = renderer.actors.sheets[kind]
        local y, feetY = 16 + (i - 1) * rowH, 16 + (i - 1) * rowH + 150
        G.setColor(P.ink)
        G.print(PixelFont.clean(kind:gsub('^npc_', ''):upper()), 10, y + 62)
        if sheet and sheet.animations.idle then
            for d = 1, 4 do
                G.setColor(1, 1, 1)
                sheet.animations.idle[d]:draw(sheet.image,
                    labelW + (d - 1) * colW + 62, feetY, 0, scale, scale, 20, 44)
            end
            local act = sheet.animations.work or sheet.animations.warn or sheet.animations.move
            if act and act[2] then
                G.setColor(1, 1, 1)
                act[2]:draw(sheet.image, labelW + 4 * colW + 62, feetY,
                    0, scale, scale, 20, 44)
            end
            local pc = sheet.portraits and sheet.portraits.neutral
            if pc then
                local sub = G.newQuad(pc[1], pc[2], pc[3], pc[4],
                    sheet.image:getDimensions())
                G.setColor(1, 1, 1)
                G.draw(sheet.image, sub, labelW + 5 * colW + 14, y + 34, 0, 4, 4)
            end
        end
    end
    G.setCanvas()
    local path = 'screenshots/prancha-' .. (sceneRegion or 'all') .. '.png'
    local f = assert(io.open(path, 'wb'))
    f:write(canvas:newImageData():encode('png'):getString()); f:close()
    print('prancha: ' .. path)
    love.event.quit(0)
end

-- Matriz de emoções: kinds com linha emocional assada × 9 estados —
-- evidência do elenco expressivo p/ o Prisma.
local function drawEmocoes()
    local G = love.graphics
    local Pal = require("src.palettes")
    local PixelFont = require("src.pixel_font")
    local P = require("src.pixel_world").palette
    G.clear(Pal.moon.disc)
    local emotions = {'neutral', 'joy', 'sad', 'stern', 'soft',
        'fear', 'anger', 'shame', 'awe'}
    local kinds = {"player", "dasher", "breaker", "demolisher", "warden",
        "crawler", "husk", "ranger", "sower", "watcher", "veteran", "regent",
        "npc_merchant", "npc_keeper", "npc_doro", "npc_runa", "npc_bento",
        "npc_teca", "npc_sabela", "npc_nilo", "npc_aurel",
        "npc_janda", "npc_brina", "npc_neco", "npc_rute", "npc_ema",
        "npc_ivo", "npc_mara", "npc_beltran", "npc_cira",
        "npc_traba", "npc_trabb", "npc_guarda", "npc_feirante",
        "npc_voz", "npc_equipe", "npc_ajudante", "npc_plateia"}
    for i, emo in ipairs(emotions) do
        G.setFont(renderer.hudFont); G.setColor(P.ink)
        G.print(PixelFont.clean(emo:upper()), 60 + (i - 1) * 60, 30)
    end
    for i, kind in ipairs(kinds) do
        local sheet = renderer.actors.sheets[kind]
        local y = 60 + (i - 1) * 62
        G.setFont(renderer.hudFont); G.setColor(P.ink)
        G.print(PixelFont.clean(kind:upper()), 8, y + 16)
        if sheet and sheet.portraits then
            for j, emo in ipairs(emotions) do
                local pc = sheet.portraits[emo]
                if pc then
                    local sub = G.newQuad(pc[1], pc[2], pc[3], pc[4],
                        sheet.image:getDimensions())
                    G.setColor(1, 1, 1)
                    G.draw(sheet.image, sub, 60 + (j - 1) * 60, y, 0, 2, 2)
                end
            end
        else
            -- Crawler/husk por decisão do Pena: o gesto é a face — a linha
            -- diz isso em vez de deixar células mortas.
            G.setFont(renderer.hudFont); G.setColor(P.stoneDark)
            G.print('(GESTO E A FACE)', 60, y + 16)
        end
        -- Sprite de cena ao lado p/ leitura de escala.
        if sheet then
            G.setColor(1, 1, 1)
            sheet.animations.idle[2]:draw(sheet.image, 620, y, 0, 1, 1, 20, 44)
        end
    end
end

function love.draw()
    if testing then return end
    if hdscene then hdscene:draw()
    elseif scene == "silhuetas" then drawSilhouettes()
    elseif scene == "emocoes" then drawEmocoes()
    elseif scene == "player-diff" then drawPlayerDiff()
    elseif scene == "direcoes" then drawDirections()
    elseif scene == "prancha" then prancha()
    elseif mode == "campaign" then renderer:drawCampaign(campaign, screen, Save.exists())
    else renderer:draw(game, screen) end
    -- A captura espera a cortina de entrada zerar: --screenshot sem
    -- --capture-after nunca sai preto de novo.
    if screenshotPath and captureClock >= captureAfter
        and (renderer.feedback.fade or 0) <= 0.02 and captureClock >= .1 then
        local path = screenshotPath; screenshotPath = nil
        love.graphics.captureScreenshot(function(data)
            local bytes = data:encode("png")
            local file = assert(io.open(path, "wb")); file:write(bytes:getString()); file:close()
            love.event.quit()
        end)
    end
end

function love.keypressed(key, _, repeated)
    if testing or repeated then return end
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen()); return end
    if key == "f2" and renderer then
        renderer.reducedMotion = not renderer.reducedMotion
        if campaign then campaign.reducedMotion = renderer.reducedMotion end
        return
    end
    if key == "m" and renderer then
        renderer.muted = not renderer.muted
        -- Sincroniza já: o guarda do play leria o mute velho e engoliria o
        -- cue de desmute (setMuted de love.update só chega no frame seguinte).
        Sfx.setMuted(renderer.muted)
        if not renderer.muted then Sfx.play("ui_confirm") end
        return
    end
    if mode == "campaign" then
        if screen == "title" then
            if menuMode == 'confirm' then
                if key == "return" then menuMode = 'root'; startCampaign(true)
                    Sfx.play("ui_confirm")
                elseif key == "escape" then menuMode = 'root'; Sfx.play("ui_cancel") end
                return
            end
            if menuMode == 'options' then
                -- N linhas vivas (optionRows): W/S circula com wrap, A/D
                -- anda em décimos nas linhas 'volume', ENTER cicla +0.1
                -- (1.0 volta a 0) nelas e alterna os toggles.
                local rows = optionRows()
                local row = rows[menuIdx]
                if key == "escape" then
                    menuMode, menuIdx = 'root', 3; Sfx.play("ui_cancel")
                elseif key == "w" or key == "s" or key == "up" or key == "down" then
                    local step = (key == "w" or key == "up") and -1 or 1
                    menuIdx = menuIdx + step
                    if menuIdx < 1 then menuIdx = #rows
                    elseif menuIdx > #rows then menuIdx = 1 end
                    Sfx.play("ui_move")
                elseif (key == "a" or key == "d" or key == "left" or key == "right")
                    and row and row.kind == 'volume' then
                    local steps = math.floor(Sfx.getVolume(row.id) * 10 + .5)
                    steps = steps + ((key == "d" or key == "right") and 1 or -1)
                    Sfx.setVolume(row.id, steps / 10)
                    Sfx.play("ui_move")
                elseif key == "return" and renderer and row then
                    if row.kind == 'volume' then
                        local steps = math.floor(Sfx.getVolume(row.id) * 10 + .5)
                        Sfx.setVolume(row.id, ((steps + 1) % 11) / 10)
                        Sfx.play("ui_move")
                    elseif row.id == 'muted' then
                        renderer.muted = not renderer.muted
                        Sfx.setMuted(renderer.muted)
                        if not renderer.muted then Sfx.play("ui_toggle") end
                    else
                        renderer.reducedMotion = not renderer.reducedMotion
                        if campaign then
                            campaign.reducedMotion = renderer.reducedMotion
                        end
                        Sfx.play("ui_toggle")
                    end
                end
                return
            end
            local function enabled(i) return i ~= 1 or Save.exists() end
            if key == "w" or key == "up" or key == "s" or key == "down" then
                local step = (key == "w" or key == "up") and -1 or 1
                repeat menuIdx = menuIdx + step
                    if menuIdx < 1 then menuIdx = 4 elseif menuIdx > 4 then menuIdx = 1 end
                until enabled(menuIdx)
                Sfx.play("ui_move")
            elseif key == "tab" then openHelp()
            elseif key == "return" then
                if menuIdx == 1 then
                    if Save.exists() then startCampaign(false); Sfx.play("ui_confirm")
                    else Sfx.play("ui_deny") end
                elseif menuIdx == 2 then
                    if Save.exists() then menuMode = 'confirm' else startCampaign(true) end
                    Sfx.play("ui_confirm")
                elseif menuIdx == 3 then menuMode, menuIdx = 'options', 1; Sfx.play("ui_confirm")
                else love.event.quit(); Sfx.play("ui_cancel") end
            elseif key == "n" then
                if Save.exists() then menuMode = 'confirm'; Sfx.play("ui_confirm")
                else Sfx.play("ui_deny") end
            end
            return
        end
        if screen == "opening" then
            -- A cena consome as teclas — nada vaza para a campanha.
            if key == "escape" or key == "return" or key == "e" then
                if key == "escape" then
                    openingIdx = #openingList
                    Sfx.stopCategory("scene"); Sfx.play("cutscene_skip")
                else
                    openingIdx = openingIdx + 1; openingT = 0
                    Sfx.play("cutscene_advance")
                end
                if openingIdx >= #openingList then
                    screen = "campaign"
                    if openingKey then
                        campaign.data.flags[openingKey] = true
                        campaign:checkpoint()
                    end
                    openingKey, renderer.openingFrame = nil, nil
                else
                    renderer.openingFrame = openingList[openingIdx]
                    frameCue()
                end
            end
            return
        end
        if screen == "help" then
            if key == "tab" or key == "escape" or key == "return" then
                screen = helpReturn; clearControls(); Sfx.play("ui_cancel")
            elseif key == "c" and renderer then
                renderer.helpPage = renderer.helpPage == "cards" and "guide" or "cards"
                Sfx.play("ui_toggle")
            elseif renderer and renderer.helpPage == "cards" then
                local delta = (key == "w" or key == "up") and -1
                    or (key == "s" or key == "down") and 1 or 0
                if delta ~= 0 then
                    local total = #require("src.lore").cards
                    renderer.helpCard = math.max(1, math.min(total, (renderer.helpCard or 1) + delta))
                    Sfx.play("ui_move")
                end
            end
            return
        end
        if campaign.dialogue then
            if key == "e" or key == "return" then campaign:advanceDialogue()
            elseif key == "escape" or key == "q" then campaign:closeDialogue()
            elseif key:match("^%d$") then campaign:chooseDialogue(tonumber(key)) end
            clearControls()
            return
        end
        if campaign.scene == "battle" and campaign.battle then
            if campaign.battle:key(key, campaign) then
                if campaign.scene ~= "battle" then clearControls() end
                return
            end
        end
        if key == "escape" then
            -- MERGE-SHIM (COMBATE_MERGE §11): na fase de ação o ESC abre a
            -- pausa da campanha — nunca a retirada direta. A rota antiga
            -- `endBattle('return')` fica como legado morto: só dispara se
            -- uma fase de turno reaparecer ('resolve'/'player' não existem
            -- mais no modelo fásico).
            local battlePhase = campaign.scene == "battle" and campaign.battle
                and campaign.battle.phase or nil
            if campaign.scene == "battle" and battlePhase ~= "action"
                and screen ~= "paused" then
                campaign:endBattle("return")
            else
                screen = screen == "paused" and "campaign" or "paused"
                Sfx.play(screen == "paused" and "ui_pause" or "ui_resume")
            end
            clearControls()
            return
        end
        if screen == "paused" then
            if key == "return" then screen = "campaign"; clearControls(); Sfx.play("ui_resume")
            elseif key == "tab" then openHelp()
            elseif key == "b" then screen = "bolsa"; bagIdx = 1; Sfx.play("ui_confirm")
            elseif key == "q" then
                campaign:checkpoint(); campaign = nil; screen = "title"
                Sfx.setDucked(false); Sfx.setAmbience(nil); Sfx.play("ui_cancel")
            end
            return
        end
        if screen == "bolsa" then
            local list = Items.list(campaign.data.items)
            local n = math.max(1, #list)
            bagIdx = math.max(1, math.min(bagIdx or 1, n))
            local it = list[bagIdx]
            if key == "w" or key == "up" then bagIdx = bagIdx - 1 < 1 and n or bagIdx - 1; Sfx.play("ui_move")
            elseif key == "s" or key == "down" then bagIdx = bagIdx + 1 > n and 1 or bagIdx + 1; Sfx.play("ui_move")
            elseif key == "e" or key == "return" then
                if it and it.def.cat == 'equipavel' and it.def.slot then
                    if campaign.scene == 'battle' then
                        Sfx.play("ui_deny")   -- trocar só fora de luta
                    else
                        -- Equipar/desequipar no slot — nunca desbanca em
                        -- silêncio: trocar devolve o que estava na mão.
                        local eq = campaign.data.equipped
                        eq[it.def.slot] = eq[it.def.slot] == it.id and nil or it.id
                        Sfx.play("ui_confirm")
                    end
                end
            elseif key == "u" and it and it.def.cat == 'consumivel' then
                -- Honestidade: curar com vida cheia queima o item à toa —
                -- nega com aviso em vez de consumir em silêncio.
                local hp = campaign.player.health
                local heals = it.def.battle and it.def.battle.heal
                if heals and hp and hp.current >= hp.max then
                    Sfx.play("ui_deny")
                elseif campaign:useItem(it.id) then
                    campaign:applyItemEffect(it.id)
                    Sfx.play("ui_confirm")
                end
            elseif key == "escape" then screen = "paused"; clearControls(); Sfx.play("ui_cancel")
            end
            return
        end
        if key == "tab" then openHelp(); return end
        -- MERGE-SHIM (COMBATE_MERGE §8): dentro da arena o E é evento do
        -- frame (poupar por proximidade), não o interact da exploração.
        if key == "e" and campaign.scene ~= "battle" then campaign:interact(); return end
        input:pressed(key)
        return
    end
    if screen == "title" then
        if key == "return" then restart(true); Sfx.play("ui_confirm")
        elseif key == "n" then restart(false); Sfx.play("ui_confirm")
        elseif key == "tab" then openHelp() end
        return
    end
    if screen == "help" then
        if key == "tab" or key == "escape" or key == "return" then
            screen = helpReturn; clearControls(); Sfx.play("ui_cancel")
        elseif key == "c" and renderer then
            renderer.helpPage = renderer.helpPage == "cards" and "guide" or "cards"
            Sfx.play("ui_toggle")
        elseif renderer and renderer.helpPage == "cards" then
            local delta = (key == "w" or key == "up") and -1 or (key == "s" or key == "down") and 1 or 0
            if delta ~= 0 then
                local total = #require("src.lore").cards
                renderer.helpCard = math.max(1, math.min(total, (renderer.helpCard or 1) + delta))
                Sfx.play("ui_move")
            end
        end
        return
    end
    if game.dialogue then
        if key == "e" or key == "return" then game:advanceDialogue()
        elseif key == "escape" or key == "q" then game:closeDialogue()
        elseif key:match("^%d$") then game:chooseDialogue(tonumber(key)) end
        clearControls()
        return
    end
    if key == "escape" then
        screen = screen == "paused" and "playing" or "paused"
        Sfx.play(screen == "paused" and "ui_pause" or "ui_resume")
        clearControls()
        return
    end
    if screen == "paused" then
        if key == "return" then screen = "playing"; clearControls(); Sfx.play("ui_resume")
        elseif key == "tab" then openHelp()
        elseif key == "q" then screen = "title"; Sfx.setDucked(false); Sfx.setAmbience(nil); Sfx.play("ui_cancel")
        elseif key == "r" then restart(nil, game.seed); Sfx.play("ui_confirm") end
        return
    end
    if key == "tab" then openHelp(); return end
    if game.state ~= "playing" then
        if key == "return" and game.state == "won" and not game.practice and not game.worldComplete then
            game:nextFloor(); clearControls(); Sfx.play("ui_confirm")
        elseif key == "r" then restart(nil, game.seed); Sfx.play("ui_confirm")
        elseif key == "n" then restart(false); Sfx.play("ui_confirm")
        elseif key == "return" or key == "q" then screen = "title"; Sfx.setDucked(false); Sfx.setAmbience(nil); Sfx.play("ui_cancel")
        end
        return
    end
    if game.reward and (key == "1" or key == "2" or key == "3") then
        game:chooseReward(tonumber(key)); clearControls(); Sfx.play("ui_confirm"); return
    end
    if game.reward then return end
    input:pressed(key)
end

function love.keyreleased(key) if input then input:released(key) end end
function love.focus(focused)
    if not focused and (screen == "playing" or screen == "campaign") and not showcase and not testing then
        screen = "paused"; clearControls()
    end
end
