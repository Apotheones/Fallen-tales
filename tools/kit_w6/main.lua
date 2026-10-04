-- kit_w6 — demo da API de authoring de VFX (W6, camada de authoring).
-- Uso, da raiz:  lovec tools/kit_w6          -> checks + evidência
--                lovec tools/kit_w6 --test   -> só checks
--
-- Consumidor concreto do módulo: define 3 efeitos reais via V.sheet,
-- assa pelo DSL normal e emite strip albedo+emissive + relatório V.check.
-- A sequência completa numa ação tática (fire→hit→result) espera W4.

local DSL, V
local testOnly

local function die(msg)
    local f = io.open('screenshots/kit_w6-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local function png(id, path)
    local f = assert(io.open(path, 'wb'))
    f:write(id:encode('png'):getString())
    f:close()
end

--------------------------------------------------------------------------------
-- Efeitos de demonstração — vocabulário que a arena vai consumir:
-- faísca de impacto (bloom), poeira de queda/arraste (sem bloom),
-- onda de choque jade (bloom fraco).
--------------------------------------------------------------------------------

local function defs()
    local faisca = V.sheet{
        name = 'fx_faisca_hit', w = 46, h = 42, frames = 6,
        margin = 1, seed = 11, kind = 'faisca', dir = 'e',
        legend = V.MAT.faisca.legend,
        emit = { only = { 'S', 'w' } }, -- só núcleo/cabeça floresce
        frame = function(f, N, ctx)
            V.sparks{ at = { ctx.w / 2, ctx.h / 2 }, dir = 'e',
                cone = .9, n = 14, len = { 2, 9 }, grav = .15,
                ch = 's', hot = 'S' }(f, N, ctx.albedo, ctx.rng)
            -- núcleo do impacto nos 2 primeiros frames (branco quente)
            if f <= 2 then
                local c = ctx.w / 2
                for dy = -2, 2 do for dx = -2, 2 do
                    if dx * dx + dy * dy <= 5 then
                        V.put(ctx.albedo, c + dx, ctx.h / 2 + dy, 'w')
                    end
                end end
            end
            V.dissipate(ctx.albedo, (f - 1) / N * .5, 'thin', { seed = 3 })
        end,
    }

    local poeira = V.sheet{
        name = 'fx_poeira_queda', w = 40, h = 26, frames = 7,
        margin = 1, seed = 7, kind = 'poeira', dir = 'e',
        legend = V.MAT.poeira.legend,
        frame = function(f, N, ctx)
            V.dust{ at = { ctx.w / 2, ctx.h - 8 }, dir = 'e',
                w = 12, n = 10, drift = 8, rise = 3,
                ch = 'D' }(f, N, ctx.albedo, ctx.rng)
            V.dissipate(ctx.albedo, (f - 1) / N * .6, 'thin', { seed = 5 })
        end,
    }

    local onda = V.sheet{
        name = 'fx_onda_jade', w = 48, h = 36, frames = 6,
        margin = 1, seed = 3, kind = 'onda',
        anchor = { 24, 24 }, -- a onda nasce no chão, não no centro
        legend = V.MAT.onda.legend,
        emit = true,
        frame = function(f, N, ctx)
            V.wave{ at = { 24, 24 }, r0 = 3, r1 = 20, width = 2,
                squash = .55, ch = 'o', edge = 'O' }(f, N, ctx.albedo,
                ctx.rng)
        end,
    }
    return { faisca = faisca, poeira = poeira, onda = onda }
end

local function check(fx)
    for nome, def in pairs(fx) do
        local sheet = DSL.bake(def)
        assert(sheet and sheet.frames >= 1, nome .. ': bake falhou')
        assert(sheet.origin == 'topleft', nome .. ': origin')
        local warns = V.check(def)
        for _, w in ipairs(warns) do print('  [' .. nome .. '] ' .. w) end
    end
    -- determinismo: mesmo seed -> mesmo def (strings idênticas)
    local a, b = defs(), defs()
    assert(a.faisca.layers[1].albedo[3] == b.faisca.layers[1].albedo[3],
        'determinismo: faisca f3 diverge entre builds')
    -- defs da sequência de combate (src/sprites/fx_*): assam + margem
    for _, nome in ipairs({ 'fx_tiro', 'fx_hit_jade', 'fx_bloco',
        'fx_morte' }) do
        local okd, def = pcall(require, 'src.sprites.' .. nome)
        assert(okd and def, nome .. ': require falhou: ' .. tostring(def))
        local sh = DSL.bake(def)
        assert(sh and sh.frames >= 4, nome .. ': bake')
        assert(def.vfx and def.vfx.anchor and def.vfx.fps,
            nome .. ': vfx.anchor/fps')
        for _, w in ipairs(V.check(def)) do
            print('  [' .. nome .. '] ' .. w)
        end
    end
    print('kit_w6: checks ok')
end

local function relato(defs)
    -- strip: uma linha por efeito; albedo a 2x + emissive a 2x ao lado
    local GAP, SC = 4, 2
    local W, H = 0, 0
    local sheets = {}
    for nome, def in pairs(defs) do sheets[nome] = DSL.bake(def) end
    for _, sh in pairs(sheets) do
        W = math.max(W, sh.w * sh.frames * SC * 2 + GAP * 3)
        H = H + sh.h * SC + GAP
    end
    local id = love.image.newImageData(W, H)
    local y = 0
    for _, nome in ipairs({ 'faisca', 'poeira', 'onda' }) do
        local sh = sheets[nome]
        for f = 1, sh.frames do
            for c, ch in ipairs({ 'albedo', 'emissive' }) do
                local src = sh.imageData[ch]
                local ox = (c - 1) * (sh.w * sh.frames * SC + GAP)
                for py = 0, sh.h - 1 do for px = 0, sh.w - 1 do
                    local r, g, b, a = src:getPixel(
                        (f - 1) * sh.w + px, py)
                    if a > 0 then
                        for dy = 0, SC - 1 do for dx = 0, SC - 1 do
                            id:setPixel(
                                ox + ((f - 1) * sh.w + px) * SC + dx,
                                y + py * SC + dy, r, g, b, 1)
                        end end
                    end
                end end
            end
        end
        y = y + sh.h * SC + GAP
    end
    png(id, 'screenshots/kit_w6_prancha.png')
    local f = assert(io.open('screenshots/kit_w6_relatorio.txt', 'w'))
    local out = { 'kit_w6 — demo da API de authoring VFX', '' }
    for nome, def in pairs(defs) do
        out[#out + 1] = '== ' .. nome .. ' =='
        for _, w in ipairs(V.check(def)) do out[#out + 1] = '  ' .. w end
        out[#out + 1] = ''
    end
    f:write(table.concat(out, '\n'))
    f:close()
    print('kit_w6: evidencia ok — prancha + relatorio em screenshots/')
end

--------------------------------------------------------------------------------
-- --seq: a sequência real no pipeline do jogo — Campaign + Battle +
-- Render de verdade, dirigida por battle:shoot (o mesmo caminho da
-- jogadora). Captura determinística dos momentos:
--   fogo -> voo -> hit/armor -> morte. Não é cena --scene (aquela
--   congela o mundo); aqui campaign:update ticka de verdade.
--------------------------------------------------------------------------------

local seq, seqT, seqShots, seqSteps, campaign, renderer, pinUntil
local simAcc, pinArmor, seqEnd, seqRM = 0

local function seqSetup()
    -- Ferramenta não tem assets/ na raiz do lovec: música vira stub
    -- (o --seq prova o caminho visual, não o áudio).
    package.loaded['src.music'] = { new = function()
        return { update = function() end }
    end }
    local Campaign = require('src.campaign')
    local Battle = require('src.battle')
    local Render = require('src.render')
    love.window.setMode(1280, 720, { resizable = false })
    campaign = Campaign.new({ legacy = false })
    campaign:travel('colina')
    campaign.battle = Battle.new(campaign, 'T-SEQ', { kind = 'dasher' })
    campaign.scene = 'battle'
    while campaign.dialogue do campaign:advanceDialogue() end
    renderer = Render.new()
    renderer.hdEnabled = true
    renderer.reducedMotion = seqRM == true
    -- Aquecimento CURTO: só consome o 'room' da entrada — a cortina
    -- zera na mão. Warmup longo deixava o dasher resolver e matar a
    -- jogadora (state='dead' congela o mundo p/ sempre).
    local zeros = { dx = 0, dy = 0, guard = false, events = {} }
    for _ = 1, 15 do
        while campaign.dialogue do campaign:advanceDialogue() end
        campaign.battle.phase = 'action'
        campaign:update(1 / 120, zeros)
        renderer:updateCampaign(1 / 60, campaign, 'campaign')
    end
    renderer.feedback.fade = 0
    campaign.battle.player.health.current = 10
    local b = campaign.battle
    seqSteps = {
        -- disparo da jogadora: flecha sobe do spawn (7,8) ao dasher (7,5)
        { at = 0.05, fn = function()
            -- fixture da captura: alvo recolocado na lane (o AI pode
            -- ter resolvido durante o warmup); o dano é o caminho real.
            local d = b.enemies[1]
            if d and d.enemy then
                d.grid.x, d.grid.y = 7, 5
                -- BRUTO em seek encara a jogadora — flecha frontal é
                -- sempre 'armor'. O fixture pinna o selo p/ produzir
                -- os outros caminhos: sem armadura a flecha acerta.
                pinArmor = false
                d.enemy.frontalArmor = false
            end
            pinUntil = seqT + .25
            b:shoot(b.player, 0, -1, 3, .035, nil, 'bow')
        end },
        -- flecha frontal no BRUTO (armor=true): 'armor' -> fx_bloco.
        { at = 0.55, fn = function()
            local d = b.enemies[1]
            if d and d.enemy then
                d.grid.x, d.grid.y = 7, 5
                pinArmor = true
                d.enemy.frontalArmor = true
            end
            pinUntil = seqT + .25
            b:shoot(b.player, 0, -1, 1, .035, nil, 'bow')
        end },
        -- resolução: golpe letal -> 'death'. O BRUTO rende (nonLethal
        -- social) — a fixture desarma para a morte real sair.
        { at = 1.1, fn = function()
            local d = b.enemies[1]
            if d and d.enemy then
                d.grid.x, d.grid.y = 7, 5
                pinArmor = false
                d.enemy.frontalArmor = false
                d.nonLethal = false
            end
            pinUntil = seqT + .25
            -- hp.current==0 é checagem exata: dano = hp atual pra
            -- resolver em 'death' de verdade, não overshoot mudo.
            b:shoot(b.player, 0, -1, d and d.health
                and d.health.current or 6, .035, nil, 'bow')
        end },
    }
    local p = seqRM and 'kit_w6_rm_' or 'kit_w6_seq_'
    seqShots = {
        { at = 0.10, path = 'screenshots/' .. p .. 'fogo.png' },
        { at = 0.18, path = 'screenshots/' .. p .. 'voo.png' },
        { at = 0.30, path = 'screenshots/' .. p .. 'hit.png' },
        { at = 0.75, path = 'screenshots/' .. p .. 'bloco.png' },
        { at = 1.30, path = 'screenshots/' .. p .. 'morte.png' },
    }
end

local seqI, seqS = 1, 1
local function seqShot()
    local shot = seqShots[seqS]
    if shot and seqT >= shot.at then
        seqS = seqS + 1
        love.graphics.captureScreenshot(function(data)
            local f = assert(io.open(shot.path, 'wb'))
            f:write(data:encode('png'):getString()); f:close()
            if seqS > #seqShots then
                print('kit_w6 --seq: capturas ok'); love.event.quit(0)
            end
        end)
    end
end

function love.update(dt)
    if not seq then return end
    while campaign.dialogue do campaign:advanceDialogue() end
    -- O menu de postura (phase='pause') congela o mundo — o driver do
    -- --seq mantém a arena em ação para a sequência correr de verdade.
    if campaign.battle then
        campaign.battle.phase = 'action'
        -- O dasher fica pinado durante toda a seq (seek + célula +
        -- facing do disparo): o AI real o moveria/reorientaria e a
        -- arena concluiria antes da captura terminar.
        local d = campaign.battle.enemies[1]
        if d and d.enemy and pinUntil then
            -- 'recover' = inerte: não anda, não resolve — a arena não
            -- conclui durante a captura. (O AI reorienta facing mesmo
            -- em recover — por isso a armadura é o toggle do fixture.
            -- E o pin limpa mercy/spared: um hit no BRUTO pode acalmar
            -- a unidade e encerrar a arena antes da hora.)
            d.enemy.state, d.enemy.timer = 'recover', 9
            d.mercy, d.calmed, d.spared = nil, nil, nil
            if d.grid then d.grid.x, d.grid.y = 7, 5 end
            if pinArmor ~= nil then d.enemy.frontalArmor = pinArmor end
        end
    end
    -- seqT conta TEMPO SIMULADO (1/120 por tick) e o dt é capado:
    -- o primeiro update chega com dt enorme (o warmup do load entra
    -- na medição) e pularia todos os passos de uma vez.
    simAcc = simAcc + math.min(dt, 1 / 30)
    while simAcc >= 1 / 120 do
        simAcc = simAcc - 1 / 120
        seqT = seqT + 1 / 120
        while seqSteps[seqI] and seqT >= seqSteps[seqI].at do
            seqSteps[seqI].fn(); seqI = seqI + 1
        end
        while campaign.dialogue do campaign:advanceDialogue() end
        if not campaign.battle then break end
        campaign.battle.phase = 'action'
        if pinUntil then
            local d = campaign.battle.enemies[1]
            if d and d.grid then d.grid.x, d.grid.y = 7, 5 end
            if d and d.enemy then
                d.enemy.state, d.enemy.timer = 'recover', 9
                d.mercy, d.calmed, d.spared = nil, nil, nil
                if pinArmor ~= nil then
                    d.enemy.frontalArmor = pinArmor
                end
            end
        end
        campaign:update(1 / 120, { dx = 0, dy = 0, guard = false,
            events = {} })
    end
    local b2 = campaign.battle
    if not b2 or b2.over or b2.state ~= 'playing' then
        -- A conclusão enfileira 'death'+'room' no mesmo tick: drena a
        -- fila e segue vivo ~1.2s p/ o FX da resolução tocar.
        for _, ev in ipairs(campaign.events or {}) do
            renderer.feedback:consume(ev, campaign)
        end
        campaign.events = {}
        renderer:updateCampaign(dt, campaign, 'campaign')
        seqEnd = seqEnd or seqT
        seqShot()
        if seqT - seqEnd > 1.2 then
            print('kit_w6 --seq: capturas ok'); love.event.quit(0)
        end
        return
    end
    renderer:updateCampaign(dt, campaign, 'campaign')
    seqShot()
end

function love.draw()
    if seq and campaign and renderer then
        renderer:drawCampaign(campaign, 'campaign', false)
    end
end

function love.load(args)
    package.path = package.path .. ';./?.lua;./?/init.lua'
    for _, a in ipairs(args or {}) do
        if a == '--test' then testOnly = true end
        if a == '--seq' then seq, seqT = true, 0 end
        if a == '--seq-rm' then seq, seqT, seqRM = true, 0, true end
    end
    if seq then seqSetup() return end
    DSL = require('src.sprite_dsl')
    V = require('src.kit_vfx')
    local fx = defs()
    check(fx)
    if testOnly then love.event.quit(0) return end
    relato(fx)
    love.event.quit(0)
end
