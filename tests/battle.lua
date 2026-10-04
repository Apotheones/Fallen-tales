-- Real-time arena checks (COMBATE_MERGE passo 1): a única fase viva é
-- 'action' — o sub-mundo Concord roda o motor do protótipo dentro da
-- campanha. Cobertura: janela de graça, seek→warn→resolve real, desvio por
-- movimento, arco único, escudo frontal, freeze no mesmo quadro (projétil
-- em voo incluso), morte→die, poupo por proximidade, rendição não-letal e
-- a superfície social sobrevivente. O turno não existe mais — nenhum
-- relógio de resolução, nenhum endTurn, nenhum phase 'player'/'resolve'.
local Battle = require('src.battle')
local Campaign = require('src.campaign')
local Save = require('src.save')
local Rooms = require('src.rooms')
local Enemies = require('src.enemies')
local Talks = require('src.battle_talks')

local BattleTest = {}
local DT = 1 / 120

local function fresh(kind)
    Save.file = 'test_campaign_save.lua'
    Save.clear()
    local c = Campaign.new()
    c.dialogue = nil
    c.data.items.arco = 1
    c.battle = Battle.new(c, 'T01-01', kind or 'ranger')
    c.scene = 'battle'
    return c, c.battle
end

-- Um tick do loop real: main.lua produz {dx,dy,guard,events}; a campanha
-- repassa à batalha enquanto a cena for 'battle'.
local IDLE = {dx = 0, dy = 0, guard = false, events = {}}
local function frame(c, input) c:update(DT, input or IDLE) end
local function tick(c, seconds, input)
    for _ = 1, math.ceil(seconds / DT) do
        if c.scene ~= 'battle' then return end
        frame(c, input)
    end
end

-- Toque de direção: vira no primeiro evento e anda segurando o eixo —
-- exatamente o que o input real produz.
local function nudge(c, dx, dy, seconds)
    frame(c, {dx = dx, dy = dy, guard = false,
        events = {{kind = 'face', dx = dx, dy = dy}, {kind = 'step', dx = dx, dy = dy}}})
    tick(c, seconds or .4, {dx = dx, dy = dy, guard = false, events = {}})
end

-- O arco honesto: SPACE segura a carga .72s e a soltura dispara — nada de
-- atalho de turno.
local function fireAt(c, b, dx, dy)
    frame(c, {dx = 0, dy = 0, guard = false,
        events = {{kind = 'face', dx = dx, dy = dy}, {kind = 'charge'}}})
    tick(c, .8)
    frame(c, {dx = 0, dy = 0, guard = false, events = {{kind = 'fire'}}})
end

-- Espera o inimigo entrar num estado, com teto honesto de frames.
local function waitState(c, e, state, seconds)
    for _ = 1, math.ceil((seconds or 4) / DT) do
        if c.scene ~= 'battle' or e.enemy.state == state then return e.enemy.state end
        frame(c)
    end
    return e.enemy.state
end

-- FATIA 3 checks (def.loot + ACT item gates): endBattle é plumbing da
-- campanha, não do modelo — os asserts originais sobrevivem inteiros.
local function fatia3(check)
    local cL = Campaign.new()
    cL.dialogue = nil
    cL.map.encounters[#cL.map.encounters + 1] = {id = 'T-LOOT', x = 8, y = 20,
        kind = 'ranger', loot = {gold = 5, xp = 2, items = {provisao = 1}}}
    cL.battle = Battle.new(cL, 'T-LOOT', cL:encounterDef('T-LOOT'))
    cL.scene = 'battle'
    cL:endBattle('won')
    check(cL.gold == 5 and cL.xp == 2 and cL.data.items.provisao == 1,
        'A won encounter pays gold, xp and items into the campaign')
    check(cL.message:match('Saque') and cL.message:match('ouro'),
        'The loot notify lists what came in')
    table.remove(cL.map.encounters)

    local cL2 = Campaign.new()
    cL2.dialogue = nil
    cL2.map.encounters[#cL2.map.encounters + 1] = {id = 'T-LOOT2', x = 8, y = 20,
        kind = 'ranger', loot = {gold = 5, xp = 2, items = {provisao = 1}}}
    cL2.battle = Battle.new(cL2, 'T-LOOT2', cL2:encounterDef('T-LOOT2'))
    cL2.scene = 'battle'
    cL2:endBattle('negotiated')
    check(cL2.gold == 5 and cL2.xp == 2 and cL2.data.items.provisao == 1,
        'A peaceful withdrawal pays the full loot — talks are not punished')
    table.remove(cL2.map.encounters)

    local cL3 = Campaign.new()
    cL3.dialogue = nil
    cL3.map.encounters[#cL3.map.encounters + 1] = {id = 'T-LOOT3', x = 8, y = 20,
        kind = 'ranger', loot = {gold = 5, xp = 2},
        parleyLoot = {gold = 1, items = {provisao = 1}}}
    cL3.battle = Battle.new(cL3, 'T-LOOT3', cL3:encounterDef('T-LOOT3'))
    cL3.scene = 'battle'
    cL3:endBattle('negotiated')
    check(cL3.gold == 1 and cL3.xp == 0 and cL3.data.items.provisao == 1,
        'parleyLoot, not loot, is what a negotiated ending pays')
    table.remove(cL3.map.encounters)

    local cL4 = Campaign.new()
    cL4.dialogue = nil
    cL4.map.encounters[#cL4.map.encounters + 1] = {id = 'T-LOOT3', x = 8, y = 20,
        kind = 'ranger', loot = {gold = 5, xp = 2},
        parleyLoot = {gold = 1, items = {provisao = 1}}}
    cL4.battle = Battle.new(cL4, 'T-LOOT3', cL4:encounterDef('T-LOOT3'))
    cL4.scene = 'battle'
    cL4:endBattle('won')
    check(cL4.gold == 5 and cL4.xp == 2 and not cL4.data.items.provisao,
        'won pays loot even when parleyLoot exists')
    table.remove(cL4.map.encounters)

    local cL5 = Campaign.new()
    cL5.dialogue = nil
    cL5.map.encounters[#cL5.map.encounters + 1] = {id = 'T-LOOT4', x = 8, y = 20,
        kind = 'ranger'}
    cL5.battle = Battle.new(cL5, 'T-LOOT4', cL5:encounterDef('T-LOOT4'))
    cL5.scene = 'battle'
    cL5:endBattle('won')
    check(cL5.data.encounters['T-LOOT4'] == 'won'
        and not (cL5.message or ''):match('Saque'),
        'A lootless encounter resolves without a spoils notify')
    table.remove(cL5.map.encounters)

    local cL6 = Campaign.new()
    cL6.dialogue = nil
    cL6.map.encounters[#cL6.map.encounters + 1] = {id = 'T-LOOT5', x = 8, y = 20,
        kind = 'ranger', loot = {gold = 9, xp = 9}}
    cL6.battle = Battle.new(cL6, 'T-LOOT5', cL6:encounterDef('T-LOOT5'))
    cL6.scene = 'battle'
    cL6:endBattle('return')
    check(cL6.gold == 0 and cL6.xp == 0
        and cL6.data.encounters['T-LOOT5'] == nil,
        'A retreat pays nothing and the encounter stays pending')
    table.remove(cL6.map.encounters)

    local cL7 = Campaign.new()
    cL7.dialogue = nil
    cL7.map.encounters[#cL7.map.encounters + 1] = {id = 'T-LOOT6', x = 8, y = 20,
        kind = 'ranger', loot = {gold = 5}}
    cL7.battle = Battle.new(cL7, 'T-LOOT6', cL7:encounterDef('T-LOOT6'))
    cL7.scene = 'battle'
    cL7:endBattle('won')
    cL7.battle = Battle.new(cL7, 'T-LOOT6', cL7:encounterDef('T-LOOT6'))
    cL7:endBattle('won')
    check(cL7.gold == 5, 'A resolved encounter never pays the loot twice')
    table.remove(cL7.map.encounters)

    -- ACT item gates: the act shows up disabled with an honest reason.
    local cR2 = Campaign.new()
    cR2.dialogue = nil
    cR2.battle = Battle.new(cR2, 'B03-01', {kind = 'rute'})
    cR2.scene = 'battle'
    local eR2 = cR2.battle.enemies[1]
    local reciboR, treguaR2
    for _, a in ipairs(cR2.battle:actItems(eR2)) do
        if a.id == 'recibo' then reciboR = a
        elseif a.id == 'tregua' then treguaR2 = a end
    end
    check(reciboR and reciboR.disabled == 'Precisa de RECIBO DE EMA.',
        'Without the receipt the ACT explains the missing piece')
    check(treguaR2 and not treguaR2.disabled, 'An ungated ACT stays free')
    cR2:giveItem('reciboEma')
    for _, a in ipairs(cR2.battle:actItems(eR2)) do
        if a.id == 'recibo' then reciboR = a end
    end
    check(reciboR.disabled == nil, 'Holding the receipt unlocks the ACT')
end

-- Auditoria de colisão pós-COMBATE_MERGE: D12 (corpo na lane), hazard sem
-- escudo, fuga × morte no mesmo quadro, i-frames, mineração, cobertura e
-- retirados fora de colisão. Função própria — run() está no teto de locais.
local function mergeCollisionChecks(check)
    -- (43) D12 — corpo na lane: o virote morre no aliado, sem fogo amigo ---
    -- A trajetória para na primeira unidade viva ocupante (BATALHA_ACT_MERCY
    -- §8-D12). Aliado parado entre a sentinela e a jogadora intercepta a
    -- flecha: sem dano nele, sem dano nela — bloqueio honesto.
    do
        local c43 = Campaign.new()
        c43.dialogue = nil
        c43.battle = Battle.new(c43, 'T-D12', {units = {
            {kind = 'ranger', x = 7, y = 5}, {kind = 'husk', x = 7, y = 6}}})
        c43.scene = 'battle'
        local b43, r43, h43 = c43.battle, c43.battle.enemies[1], c43.battle.enemies[2]
        check(waitState(c43, r43, 'warn') == 'warn',
            'D12 setup: a sentinela telegrafa a linha sobre o aliado')
        local hpP43, hpH43 = b43.player.health.current, h43.health.current
        tick(c43, 1.6)
        check(h43.health.current == hpH43 and not h43.replaced,
            'D12: o aliado na lane intercepta sem fogo amigo')
        check(b43.player.health.current == hpP43,
            'D12: a trajetória morre no corpo — não atravessa até a jogadora')
        local log43 = ''
        for _, l in ipairs(b43.log) do log43 = log43 .. ' ' .. l end
        check(log43:match('corta a linha'),
            'D12: o log nomeia a interceptação')
    end

    -- (44) Hazard sem escudo: a marca do semeador ignora o escudo frontal --
    -- Hazard de área não se bloqueia (contrato §12): a jogadora sai do centro
    -- para a ponta da faixa e levanta o escudo DE FRENTE para a marca — a
    -- detonação cobra igual.
    do
        local c44 = Campaign.new()
        c44.dialogue = nil
        c44.battle = Battle.new(c44, 'T-HAZ', {units = {{kind = 'sower', x = 7, y = 5}}})
        c44.scene = 'battle'
        local b44, e44 = c44.battle, c44.battle.enemies[1]
        check(waitState(c44, e44, 'warn') == 'warn',
            'Setup do hazard: o semeador telegrafa a faixa')
        local haz44
        for _ = 1, math.ceil(2 / DT) do
            frame(c44)
            for _, ent in ipairs(b44:entities()) do
                if ent.hazard then haz44 = ent break end
            end
            if haz44 then break end
        end
        check(haz44 ~= nil, 'A marca vira hazard armado no chão')
        -- ponta da faixa (7,7), encarando o centro (7,8), escudo levantado
        frame(c44, {dx = 0, dy = -1, guard = false,
            events = {{kind = 'step', dx = 0, dy = -1}}})
        tick(c44, .18)
        check(b44.player.grid.x == 7 and b44.player.grid.y == 7,
            'A jogadora ocupa a ponta da faixa marcada')
        frame(c44, {dx = 0, dy = 0, guard = false,
            events = {{kind = 'face', dx = 0, dy = 1}}})
        local hp44 = b44.player.health.current
        tick(c44, 1.1, {dx = 0, dy = 0, guard = true, events = {}})
        check(b44.player.health.current == hp44 - 2,
            'Hazard de área não usa escudo — a marca cobra de frente também')
    end

    -- (45) Hazard sem escudo 2: a laje da Janda é queda de arena -----------
    -- Pedra que cai não se bloqueia de frente — a faixa cobra pillarDamage e
    -- reposiciona como qualquer queda, escudo ou não.
    do
        local c45 = Campaign.new()
        c45.dialogue = nil
        c45.battle = Battle.new(c45, 'B02-01z', {units = {{kind = 'janda', x = 6, y = 5}}})
        c45.scene = 'battle'
        local b45, e45 = c45.battle, c45.battle.enemies[1]
        b45.player.grid.x, b45.player.grid.y = 7, 7
        check(waitState(c45, e45, 'warn') == 'warn' and e45.enemy.mode == 'hammer',
            'Setup da laje: martelo armado no pilar')
        frame(c45, {dx = 0, dy = 0, guard = false,
            events = {{kind = 'face', dx = -1, dy = 0}}})
        local hp45 = b45.player.health.current
        tick(c45, 1.3, {dx = 0, dy = 0, guard = true, events = {}})
        check(b45.player.health.current == hp45 - Battle.pillarDamage,
            'A laje é queda de arena — o escudo frontal não segura pedra')
    end

    -- (46) Fuga: a morte vence a saída no mesmo quadro ----------------------
    -- Virote letal chega à célula de saída no tick em que a jogadora pisa
    -- nela: a arena resolve die(), não 'return'.
    do
        local c46, b46 = fresh('ranger')
        b46:startFlee(c46)
        check(b46.exitCell ~= nil, 'Setup da fuga: a saída acendeu')
        local ex46, ey46 = b46.exitCell.x, b46.exitCell.y
        b46.player.grid.x, b46.player.grid.y = ex46, ey46
        local bolt46 = b46:shoot(b46.enemies[1], -1, 0, 99, .13, nil, 'bolt')
        bolt46.projectile.clock = bolt46.projectile.interval
        tick(c46, .2)
        check(c46.scene == 'explore' and c46.data.deaths == 1,
            'Virote + saída no mesmo quadro: a morte vence — die, não return')
    end

    -- (47) i-frames da jogadora e escudo só pela frente ---------------------
    do
        local c47, b47 = fresh('ranger')
        local hp47 = b47.player.health.current
        check(b47:damage(b47.player, 2, 7, 9), 'O primeiro golpe aplica')
        check(not b47:damage(b47.player, 2, 7, 9),
            'O segundo golpe no mesmo quadro cai nos i-frames')
        check(b47.player.health.current == hp47 - 2,
            '.36s de imunidade — dois golpes, um dano')
        b47.player.health.immune = 0
        b47.player.guard.active = true
        b47.player.facing.dx, b47.player.facing.dy = 0, -1
        check(b47:damage(b47.player, 2, 7, 9), 'Pelas costas o escudo não segura')
        b47.player.health.immune = 0
        check(b47:damage(b47.player, 2, 8, 8), 'De flanco o escudo não segura')
        local e47 = b47.enemies[1]
        local eh47 = e47.health.current
        b47:damage(e47, 1, 7, 6)
        check(b47:damage(e47, 1, 7, 6),
            'Inimigo não ganha i-frames — mesma regra do protótipo')
        check(e47.health.current == eh47 - 2,
            'Dois golpes no mesmo quadro tiram 2x do inimigo')
    end

    -- (48) Sem picareta, o toque na peça não mina ---------------------------
    do
        local c48, b48 = fresh('crawler')
        b48.enemies[1].grid.x, b48.enemies[1].grid.y = 9, 5
        b48.player.grid.x, b48.player.grid.y = 3, 7          -- pilar em (4,7)
        nudge(c48, 1, 0, .2)                                  -- encara a peça
        frame(c48, {dx = 1, dy = 0, guard = false,
            events = {{kind = 'step', dx = 1, dy = 0}}})      -- o golpe
        tick(c48, .2)
        local cell48 = Rooms.cell(b48.room, 4, 7)
        check(cell48.piece == 'pillar' and cell48.state ~= 'falling'
            and (cell48.hits or 0) == 2 and not c48.data.items.picareta,
            'Sem picareta a peça não recebe golpe e nada é gasto')
    end

    -- (49) A flecha morre no caixote — cobertura real ------------------------
    do
        local c49 = Campaign.new()
        c49.dialogue = nil
        c49.battle = Battle.new(c49, 'T-CRATE', {units = {{kind = 'husk', x = 7, y = 5}},
            crates = {{x = 7, y = 6}}})
        c49.scene = 'battle'
        local b49, h49 = c49.battle, c49.battle.enemies[1]
        check(Rooms.cell(b49.room, 7, 6).piece == 'crate', 'Setup: caixote plantado')
        fireAt(c49, b49, 0, -1)
        tick(c49, .4)
        check(Rooms.cell(b49.room, 7, 6).piece == 'crate',
            'A flecha morre no caixote — a peça segura o tiro')
        check(h49.health.current == h49.health.max and not h49.replaced,
            'Quem se cobre atrás do caixote não é ferido')
    end

    -- (50) Poupado e cadáver fora de colisão ---------------------------------
    do
        local c50, b50 = fresh('ranger')
        local e50 = b50.enemies[1]
        e50.mercy, e50.calmed = true, true
        b50:spare(e50, c50)
        check(not e50:inWorld(), 'O poupado some do mundo no mesmo tick')
        check(not b50:damage(e50, 5, 7, 7), 'Golpe direto no poupado é inerte')
    end
end

local function runaGradeChecks(check)
    -- (43) RUNA na grade (P01-E04): ficha, rendição e fio para a arena ----
    -- O def injetado espelha o formato que o Pátio planta no mapa — id de
    -- teste para não colidir com o encontro real que a colina já declara:
    -- a talk resolve a grade pela conversa; a arena só abre pelo confronto
    -- declarado (opção no node → flag <confronto>).
    local cQ = Campaign.new()
    cQ.dialogue = nil
    cQ.battle = Battle.new(cQ, 'T-GRADE', {id = 'T-GRADE', kind = 'runa',
        nonLethal = true})
    cQ.scene = 'battle'
    local bQ, eQ = cQ.battle, cQ.battle.enemies[1]
    check(eQ.name == 'RUNA' and eQ.convinceNeeded == 3
        and eQ.enemy.boss == true and eQ.enemy.kind == 'runa',
        'A Runa veste a ficha social: nome, limiar de chefe leve, fluxo boss')
    check(Enemies.runa ~= nil and Enemies.runa.boss == true
        and Enemies.runa.bridged == nil
        and rawget(Enemies.runa, 'beats') == nil,
        'O catálogo tem o def próprio da Runa — chefe, não derivado')
    local runaActs = {}
    for _, a in ipairs(bQ:actItems(eQ)) do runaActs[a.id] = true end
    check(runaActs.guardar and runaActs.inspecao
        and runaActs.versao and runaActs.tregua,
        'Os ACTs da Runa listam guardar/inspecao/versao/tregua')
    check(bQ:nonLethal(eQ) == true,
        'O nonLethal do def arma a rendição — sem ctx de bark')
    -- A cadeia: unidade > def > ctx
    local cQb = Campaign.new()
    cQb.dialogue = nil
    cQb.battle = Battle.new(cQb, 'T-NL', {units = {
        {kind = 'dasher', x = 7, y = 5, nonLethal = true}}})
    cQb.scene = 'battle'
    check(cQb.battle:nonLethal(cQb.battle.enemies[1]) == true,
        'A unidade também arma a rendição — o canal é declarativo')
    local cQc, bQc = fresh('dasher')
    check(bQc:nonLethal(bQc.enemies[1]) == false,
        'Sem flag em lugar nenhum, a queda executa normal')
    -- Flecha letal vira rendição: hp 1 + spared + retirada → negotiated
    eQ.health.current = 3
    bQ:damage(eQ, 3, eQ.grid.x + 1, eQ.grid.y)
    check(eQ.spared and eQ.health.current == 1,
        'O golpe que zeraria a vida rende a Runa — hp 1, nunca execução')
    tick(cQ, .1)
    check(cQ.scene == 'explore' and cQ.data.encounters['T-GRADE'] == 'negotiated',
        'A rendição da única unidade conclui negotiated')

    -- O def da grade: onResolve é o gancho que a ficha autoral usa para
    -- abrir a grade — a mesma forma que o Pátio planta em regions/colina
    -- (id de teste: o C01-Q1 real já mora na lista e sombrearia o injetado).
    local function gradeDef()
        return {id = 'T-GRADE', kind = 'runa', x = 6, y = 18,
            nonLethal = true,
            onResolve = function(c, r)
                if r == 'won' or r == 'negotiated' then c:openGrade(r) end
            end}
    end
    local cQ2 = Campaign.new()
    cQ2.dialogue = nil
    cQ2.map.encounters[#cQ2.map.encounters + 1] = gradeDef()
    cQ2.battle = Battle.new(cQ2, 'T-GRADE', cQ2:encounterDef('T-GRADE'))
    cQ2.scene = 'battle'
    cQ2:endBattle('won')
    check(cQ2.data.encounters['T-GRADE'] == 'won'
        and cQ2.data.flags.gradeHow == 'won'
        and cQ2.data.regions.colina.props.grade == 'open',
        "endBattle 'won' dispara onResolve — a grade abre marcada 'won'")
    check(cQ2.data.people.runa.location == 'hub'
        and cQ2:stepDone('P01-E03'),
        'A resolução migra a Runa para o hub e fecha o passo da grade')
    -- Re-resolve: encontro já marcado nunca repete o efeito
    cQ2.battle = Battle.new(cQ2, 'T-GRADE', cQ2:encounterDef('T-GRADE'))
    cQ2:endBattle('negotiated')
    check(cQ2.data.flags.gradeHow == 'won',
        'Resolver de novo não dobra o efeito — o primeiro resultado fica')
    local cQ3 = Campaign.new()
    cQ3.dialogue = nil
    cQ3.map.encounters[#cQ3.map.encounters + 1] = gradeDef()
    cQ3.battle = Battle.new(cQ3, 'T-GRADE', cQ3:encounterDef('T-GRADE'))
    cQ3.scene = 'battle'
    cQ3:endBattle('negotiated')
    check(cQ3.data.flags.gradeHow == 'negotiated',
        "endBattle 'negotiated' abre a grade pela conversa")
    -- 'return': impasse — nada marcado, a criatura fica no mundo
    local cQ4 = Campaign.new()
    cQ4.dialogue = nil
    cQ4.map.encounters[#cQ4.map.encounters + 1] = gradeDef()
    cQ4.enemies[#cQ4.enemies + 1] = {
        enemy = {id = 'T-GRADE', kind = 'runa', state = 'idle', timer = 0},
        grid = {x = 6, y = 18}, facing = {dx = 0, dy = 1},
        motion = {remaining = 0, duration = .16, fromX = 6, fromY = 18},
        health = {current = 1, max = 1}}
    cQ4.battle = Battle.new(cQ4, 'T-GRADE', cQ4:encounterDef('T-GRADE'))
    cQ4.scene = 'battle'
    cQ4:endBattle('return')
    local stillThere = false
    for _, e in ipairs(cQ4.enemies) do
        if e.enemy.id == 'T-GRADE' then stillThere = true end
    end
    check(cQ4.data.encounters['T-GRADE'] == nil
        and cQ4.data.flags.gradeHow == nil
        and cQ4.data.regions.colina.props.grade == nil
        and stillThere,
        "A retirada não resolve nada — a criatura fica e o talk rearma")

    -- O def REAL da colina (o que o Pátio planta no mapa, não o injetado):
    -- a ficha dirige a ponta inteira — fala à distância, opção, flag,
    -- watcher trigger='flag' e resolução com a grade abrindo.
    local cR = Campaign.new()
    cR.dialogue = nil
    local defR = cR:encounterDef('C01-Q1')
    check(defR ~= nil and defR.talk == 'runa'
        and defR.confronto == 'runaConfronto'
        and defR.nonLethal == true and type(defR.onResolve) == 'function',
        'O def real da grade declara talk, confronto, rendição e onResolve')
    check(defR.units and defR.units[1].kind == 'runa'
        and defR.units[1].speaker == true,
        'A ficha real posiciona a Runa como falante da arena')
    -- Ela cobre a fala do npc removido: criatura com def.talk entra no
    -- pool de interação e responde do posto (talkRange da ficha).
    cR.player.grid.x, cR.player.grid.y = 6, 15
    cR.player.facing.dx, cR.player.facing.dy = 0, 1
    check(cR:interact() and cR.dialogue,
        'A criatura responde ao interact — cobre a fala da grade')
    while cR.dialogue and cR.dialogue.mode ~= 'options' do
        cR.dialogue.reveal = math.huge; cR:advanceDialogue()
    end
    local offer
    for i, o in ipairs(cR.dialogue and cR.dialogue.node.options or {}) do
        if (o.label or ''):find('CAPACIDADE') then offer = i end
    end
    check(offer ~= nil, 'A fala real oferece a prova (DEMONSTRAR CAPACIDADE)')
    cR:chooseDialogue(offer)
    for _ = 1, 20 do
        if not cR.dialogue then break end
        if cR.dialogue.mode == 'options' then
            cR:chooseDialogue(#cR.dialogue.node.options)
        else
            cR.dialogue.reveal = math.huge; cR:advanceDialogue()
        end
    end
    check(cR.dialogue == nil and cR:flag('runaConfronto'),
        'O aceite fecha a caixa com a flag de confronto armada')
    -- O watcher trigger='flag' dispara a arena no update seguinte — a
    -- prova acontece atrás das barras, sem contato adicional.
    cR:update(DT, IDLE)
    check(cR.scene == 'battle'
        and cR.battle.enemies[1].enemy.kind == 'runa'
        and cR.battle.enemies[1].name == 'RUNA',
        'A flag armada abre a arena real — unidade Runa nomeada')
    check(cR.battle:nonLethal(cR.battle.enemies[1]) == true,
        'O def real rende a Runa — nonLethal na ficha, não no ctx')
    cR:endBattle('won')
    check(cR.data.encounters['C01-Q1'] == 'won'
        and cR.data.flags.gradeHow == 'won'
        and cR.data.regions.colina.props.grade == 'open'
        and cR.data.people.runa.location == 'hub'
        and #cR.enemies == 0,
        'Vencer a prova real marca, abre a grade e migra a Runa')
end

function BattleTest.run()
    local checks = 0
    local function check(value, message) checks = checks + 1; assert(value, message) end

local function acaoChecks(check)
    -- (1) A arena nasce na fase de ação — o turno não existe -------------
    local c0, b0 = fresh('ranger')
    check(b0.phase == 'action' and b0.state == 'playing' and b0.mode == 'action',
        'A arena abre na fase de ação em tempo real')
    check(b0.world ~= nil and b0.world:getResource('game') == b0,
        'O sub-mundo Concord roda com a batalha como recurso game')
    local e0 = b0.enemies[1]
    check(#b0.enemies == 1 and e0:inWorld() and e0.enemy.kind == 'ranger',
        'A unidade é uma entidade Concord viva do mundo')
    check(e0.enemy.state == 'seek' and e0.enemy.timer >= Battle.graceTime,
        'Janela de graça: o think inicial respeita o piso de ' .. Battle.graceTime)
    check(e0.name == 'SENTINELA' and e0.role ~= nil and e0.convinceNeeded == 2,
        'Os dados sociais vivem na entidade (nome, role, limiar)')
    check(b0.player.player ~= nil and b0.player.weapon ~= nil
        and b0.player.guard ~= nil and b0.player.health.current == 10,
        'A jogadora é a entidade real com vida e componentes')
    check(b0.player.guard.energy == Battle.staminaMax
        and b0.player.guard.max == Battle.staminaMax,
        'O fôlego nasce no máximo compartilhado')
    check(b0.turnStart ~= nil and b0.hazards ~= nil and b0.log[1] ~= nil,
        'A superfície de compatibilidade do renderer segue preenchida')

    -- Graça escalonada: unidades não engajam no mesmo tick -----------------
    local cM = Campaign.new()
    cM.dialogue = nil
    cM.battle = Battle.new(cM, 'T-MULTI', {units = {
        {kind = 'ranger', x = 6, y = 5}, {kind = 'crawler', x = 9, y = 5}}})
    cM.scene = 'battle'
    local g1, g2 = cM.battle.enemies[1].enemy.timer, cM.battle.enemies[2].enemy.timer
    check(cM.battle.enemies[1].enemy.id == 'T-MULTI#1'
        and g1 >= Battle.graceTime and g2 > g1,
        'Ordem estável e graça escalonada entre unidades')

    -- (2) Seek → warn → resolve real: o telegrafo nasce e resolve --------
    tick(c0, .5)
    check(e0.enemy.state == 'seek' and e0.grid.x == 7 and e0.grid.y == 5,
        'Durante a graça o inimigo fica parado')
    check(waitState(c0, e0, 'warn') == 'warn',
        'Alinhada na linha de tiro, a sentinela telegrafa')
    check(e0.enemy.mode == 'shot' and #e0.enemy.cells > 0,
        'O warn promete a linha — células já armadas')
    local frozenCells = {}
    for _, cl in ipairs(e0.enemy.cells) do frozenCells[#frozenCells + 1] = cl.x .. ',' .. cl.y end
    tick(c0, .4)
    local sameCells = true
    for i, cl in ipairs(e0.enemy.cells) do
        if cl.x .. ',' .. cl.y ~= frozenCells[i] then sameCells = false end
    end
    check(sameCells, 'A prévia não se move com a jogadora — prometido é prometido')
    local hp0 = b0.player.health.current
    for _ = 1, math.ceil(2.5 / DT) do
        if e0.enemy.state == 'recover' then break end
        frame(c0)
    end
    tick(c0, .8)
    check(b0.player.health.current == hp0 - 2,
        'O resolve do warn solta o virote — parada na linha, a jogadora toma')

    -- (3) A jogadora sai da linha antes do resolve -------------------------
    local c1, b1 = fresh('ranger')
    local e1 = b1.enemies[1]
    check(waitState(c1, e1, 'warn') == 'warn', 'Setup do desvio: warn armado')
    nudge(c1, 1, 0, .45)
    check(b1.player.grid.x > 7, 'O movimento em tempo real sai da linha')
    for _ = 1, math.ceil(2 / DT) do
        if e1.enemy.state == 'recover' then break end
        frame(c1)
    end
    tick(c1, .7)
    check(b1.player.health.current == b1.player.health.max,
        'Fora da linha anunciada, o virote passa — whiff honesto')

    -- (4) O arco é a única arma: carga, soltura e queda concluem 'won' ---
    local c2, b2 = fresh('ranger')
    local e2 = b2.enemies[1]
    frame(c2, {dx = 0, dy = 0, guard = false, events = {{kind = 'fire'}}})
    tick(c2, .1)
    local noArrow = true
    for _, ent in ipairs(b2:entities()) do
        if ent.projectile and ent.team.value == 'player' then noArrow = false end
    end
    check(noArrow, 'Soltar sem carregar não dispara — o arco exige o gesto')
    frame(c2, {dx = 0, dy = 0, guard = false, events = {{kind = 'charge'}}})
    tick(c2, .8)
    check(b2.player.weapon.state == 'ready',
        'A carga de .72s leva o arco ao pronto')
    check(b2.player.weapon.state ~= 'action', 'Sem soltar, nada sai')
    e2.health.current = 3
    frame(c2, {dx = 0, dy = 0, guard = false, events = {{kind = 'fire'}}})
    tick(c2, .5)
    check(c2.scene == 'explore' and c2.data.encounters['T01-01'] == 'won',
        'A flecha que acerta zera a arena — won na hora, sem pausa')
    check(not e2:inWorld(), 'A unidade morta sai do mundo no mesmo tick')

    -- Vida e fôlego voltam para a personagem no endBattle ------------------
    local c2b, b2b = fresh('ranger')
    local e2b = b2b.enemies[1]
    b2b:damage(b2b.player, 5, 7, 7)
    b2b.player.guard.energy = .4
    e2b.health.current = 3
    fireAt(c2b, b2b, 0, -1)
    tick(c2b, .5)
    check(c2b.scene == 'explore' and c2b.player.health.current == 5
        and c2b.player.guard.energy == b2b.player.guard.energy,
        'Vida e fôlego da arena voltam para a personagem')

    -- (5) Escudo frontal segura o virote anunciado -------------------------
    local c3, b3 = fresh('ranger')
    local e3 = b3.enemies[1]
    e3.enemy.state, e3.enemy.timer = 'warn', .15
    e3.enemy.mode, e3.enemy.dx, e3.enemy.dy = 'shot', 0, 1
    e3.enemy.cells = Rooms.line(b3.room, 7, 5, 0, 1, 9)
    e3.enemy.warningDuration = 1.05
    tick(c3, 1.2, {dx = 0, dy = 0, guard = true, events = {}})
    check(b3.player.health.current == b3.player.health.max,
        'SHIFT frontal segura o primeiro virote')
    check(b3.player.guard.energy < Battle.staminaMax - .25,
        'O bloqueio cobra a energia do escudo')

    -- (6) Freeze no mesmo quadro — projétil em voo incluso ----------------
    local c4, b4 = fresh('ranger')
    local e4 = b4.enemies[1]
    fireAt(c4, b4, 0, -1)
    local proj4
    for _, ent in ipairs(b4:entities()) do
        if ent.projectile then proj4 = ent end
    end
    check(proj4 ~= nil, 'O tiro sai como entidade projétil do mundo')
    c4.dialogue = {mode = 'lines', lines = {'...'}}
    local fx, fclock = proj4.grid.x, proj4.projectile.clock
    tick(c4, .4)
    check(proj4.grid.x == fx and proj4.projectile.clock == fclock,
        'Diálogo aberto congela a flecha no mesmo quadro')
    c4.dialogue = nil
    tick(c4, .4)
    check(e4.health.current <= 3 or c4.scene ~= 'battle',
        'Descongelada, a flecha termina o percurso e acerta')

    -- Warn congelado no mesmo quadro: o timer não desce ---------------------
    local c4b, b4b = fresh('ranger')
    local e4b = b4b.enemies[1]
    waitState(c4b, e4b, 'warn')
    c4b.dialogue = {mode = 'lines', lines = {'...'}}
    local wt = e4b.enemy.timer
    tick(c4b, .5)
    check(e4b.enemy.state == 'warn' and e4b.enemy.timer == wt,
        'O telegrafo sob diálogo preserva o tempo exato')

    -- (7) Morte não é morrer: hp 0 segue campaign:die -----------------------
    local c5, b5 = fresh('ranger')
    b5:damage(b5.player, 99, 7, 7)
    check(b5.player.health.current == 0 and b5.state == 'dead',
        'O golpe letal derruba a jogadora na arena')
    tick(c5, .2)
    check(c5.scene == 'explore' and c5.map.id == 'colina'
        and c5.data.deaths == 1 and c5.battle == nil
        and c5.player.health.current == c5.player.health.max,
        'A derrota acorda na cova — inteira, com tudo conservado')

    -- (8) POUPAR por proximidade: E no adjacente calmed ---------------------
    local c6, b6 = fresh('ranger')
    local e6 = b6.enemies[1]
    e6.mercy, e6.calmed = true, true
    b6.player.grid.x, b6.player.grid.y = 7, 6
    check(b6:interact() == true, 'O E adjacente confirma a retirada')
    check(e6.spared and not e6:inWorld(), 'O poupado sai do mundo no mesmo tick')
    tick(c6, .1)
    check(c6.scene == 'explore' and c6.data.encounters['T01-01'] == 'negotiated',
        'Arena sem quedas conclui negotiated')

    -- Sem trégua, o mesmo E é inerte -----------------------------------------
    local c6b, b6b = fresh('ranger')
    b6b.player.grid.x, b6b.player.grid.y = 7, 6
    check(b6b:interact() == false, 'E sem calmed/mercy não faz nada')

    -- (9) Rendição não-letal: o duelo combinado nunca executa ----------------
    -- O guard mora no shim damage/killFatal (§5.3): um golpe válido de
    -- flanco que zeraria a vida rende em vez de executar.
    local c7 = Campaign.new()
    c7.dialogue = nil
    c7.battle = Battle.new(c7, 'T-DUELO', {kind = 'dasher', ctx = 'duelo'})
    c7.scene = 'battle'
    local b7, e7 = c7.battle, c7.battle.enemies[1]
    check(b7:nonLethal(e7) == true, 'O ctx duelo arma o guard não-letal')
    e7.facing.dx, e7.facing.dy = 0, 1      -- de frente para o sul
    e7.health.current = 3
    b7:damage(e7, 3, e7.grid.x + 1, e7.grid.y)   -- golpe válido de flanco
    check(e7.spared and e7.health.current == 1,
        'O golpe que zeraria a vida rende — hp 1, nunca execução')
    tick(c7, .1)
    check(c7.scene == 'explore' and c7.data.encounters['T-DUELO'] == 'negotiated',
        'A rendição da única unidade conclui negotiated')

    -- (10) Conversa imediata: convencer baixa a guarda na hora ----------------
    local c8, b8 = fresh('ranger')
    local e8 = b8.enemies[1]
    local acalmar, observar
    for _, a in ipairs(b8:actItems(e8)) do
        if a.id == 'acalmar' then acalmar = a
        elseif a.id == 'observar' then observar = a end
    end
    check(acalmar and not acalmar.disabled and observar and not observar.disabled,
        'Os ACTs sociais aparecem livres para a sentinela')
    b8:actOn(e8, acalmar, c8)
    check(e8.convince == 1 and not e8.mercy, 'Primeiro gesto pesa sem baixar a guarda')
    b8:actOn(e8, acalmar, c8)
    check(e8.mercy and e8.calmed and e8.enemy.state == 'calmed',
        'No limiar, a trégua para o inimigo na hora')
    tick(c8, 2)
    check(e8.enemy.state == 'calmed',
        'O convencido não reengaja — a calmaria segura o tick inteiro')
    check(b8:spare(e8, c8) == true, 'O menu de poupo cobre quem baixou a guarda')
    tick(c8, .1)
    check(c8.scene == 'explore' and c8.data.encounters['T01-01'] == 'negotiated',
        'Poupo na única unidade conclui negotiated')

    -- Golpe válido desfaz a trégua (D08) ---------------------------------------
    local c8b, b8b = fresh('ranger')
    local e8b = b8b.enemies[1]
    e8b.mercy, e8b.calmed = true, true
    b8b:applyCalm(e8b)
    b8b:damage(e8b, 1, 7, 8)
    check(not e8b.mercy and not e8b.calmed and e8b.convince == 0,
        'Atacar o convencido desfaz mercy e calmed')
    check(e8b.enemy.state ~= 'calmed', 'O inimigo traído volta à máquina de caça')

    -- (11) Chefes humanos têm defs próprios no catálogo (passo 12.5) --------
    local c9 = Campaign.new()
    c9.dialogue = nil
    c9.battle = Battle.new(c9, 'B02-01', {kind = 'janda'})
    c9.scene = 'battle'
    local e9 = c9.battle.enemies[1]
    check(e9.enemy.kind == 'janda' and e9.name == 'JANDA'
        and e9.health.max == 14 and e9.enemy.frontalArmor == false,
        'Janda luta pelo def próprio — a armadura segue sendo do role')
    check(Enemies.janda ~= nil and Enemies.janda.boss == true
        and Enemies.janda.bridged == nil,
        'O catálogo tem a def própria da Janda — chefe, não derivado')
    check(e9.enemy.boss == true,
        'Boss de verdade: a máquina roda pelo sistema Boss, não pelo comum')
    for _, k in ipairs({'janda', 'rute', 'ivo', 'beltran'}) do
        check(Enemies[k] ~= nil and Enemies[k].boss == true
            and rawget(Enemies[k], 'beats') == nil,
            'O def do chefe existe e não herda falas da família: ' .. k)
    end

    -- (12) Casulo dormente eclode — a substituição não conta -------------------
    local c10 = Campaign.new()
    c10.dialogue = nil
    c10.battle = Battle.new(c10, 'T-HUSK', {units = {
        {kind = 'husk', x = 7, y = 6}, {kind = 'ranger', x = 6, y = 5}}})
    c10.scene = 'battle'
    local b10, husk = c10.battle, c10.battle.enemies[1]
    check(husk.enemy.state == 'dormant', 'O casulo nasce dormente')
    tick(c10, 4)
    check(husk.replaced and not husk:inWorld(), 'A eclosão tira o casulo do mundo')
    check(#c10.battle.enemies == 3 and #b10:liveEnemies() == 2,
        'O rastejante entra na contagem; o casulo sai — arena segue viva')

    -- (13) Mineração em tempo real gasta a picareta da bolsa --------------------
    -- Input real: o primeiro toque só vira; o segundo (já de frente para a
    -- peça) é o golpe que mina — segurar a tecla nunca mina.
    local c11, b11 = fresh('crawler')
    b11.enemies[1].grid.x, b11.enemies[1].grid.y = 9, 5   -- longe da queda
    c11.data.items.picareta = 1
    b11.player.grid.x, b11.player.grid.y = 3, 7          -- pilar em (4,7)
    nudge(c11, 1, 0, .2)                                  -- encara a peça
    frame(c11, {dx = 1, dy = 0, guard = false,
        events = {{kind = 'step', dx = 1, dy = 0}}})      -- o golpe
    tick(c11, .2)
    local cell11 = Rooms.cell(b11.room, 4, 7)
    check(cell11.state == 'falling' and c11.data.items.picareta == nil,
        'Um golpe de picareta derruba o pilar fino e gasta a ferramenta')
    tick(c11, .8)
    check(cell11.piece == nil, 'O pilar cai de verdade no warning')

end

local function socialChecks(check)
    -- (14) Entrada: menu social e teclas não roubam a ação ----------------------
    local c12, b12 = fresh('ranger')
    local ids = {}
    for _, it in ipairs(b12:menuItems()) do ids[it.id] = true end
    check(ids.continue and ids.act and ids.use and ids.mercy and ids.flee,
        'O menu da pausa já declara a postura do modelo fásico')
    check(b12:key('w', c12) == false and b12:key('escape', c12) == false
        and b12:key('e', c12) == false and b12:key('space', c12) == false,
        'Na fase de ação nenhuma tecla é consumida — tudo flui para o frame')

    -- Movimento livre não gasta recurso -----------------------------------------
    local c13, b13 = fresh('crawler')
    local energy13 = b13.player.guard.energy
    nudge(c13, -1, 0, .5)
    check(b13.player.grid.x < 7 and b13.player.guard.energy == energy13,
        'Andar pela arena não gasta fôlego')

    -- liveEnemies respeita morte, poupo e invocação --------------------------------
    local c14, b14 = fresh('ranger')
    local e14 = b14.enemies[1]
    e14.enemy.summoned = true
    check(#b14:liveEnemies() == 0, 'Servo invocado não conta na contagem do def')
    e14.enemy.summoned = false
    e14.spared = true
    check(#b14:liveEnemies() == 0 and b14:outcome() == 'negotiated',
        'Poupado sai da contagem e o desfecho lê a retirada')

    -- (15) Fechamento de fase: cota → closing → quiet → respiro → pausa -------
    local c15, b15 = fresh('ranger')
    local e15 = b15.enemies[1]
    e15.quotaLimit = 1
    check(b15:quotaFor(e15) == 1, 'A cota da unidade sobrescreve o global')
    check(waitState(c15, e15, 'warn') == 'warn', 'Cota: warn armado para o resolve')
    for _ = 1, math.ceil(2 / DT) do
        if (e15.quotaCount or 0) > 0 then break end
        frame(c15)
    end
    check(e15.quotaCount == 1, 'O resolve do warn conta um golpe da cota')
    check(b15.closing, 'Cota cumprida pede o fechamento da fase')
    tick(c15, 2.5)
    check(b15.phase == 'pause' and b15.mode == 'menu' and b15.menuIndex == 1,
        'Respiro + beat abrem a pausa no menu de postura')
    check(e15.enemy.state == 'wait' and e15.resting == true,
        'Quem cumpriu a cota respira em wait')
    check(e15.grid.x == 8 and e15.grid.y == 5,
        'O recuo de um passo aplicou — lateral quando atrás é parede')

    -- (16) Rota de input do menu social --------------------------------------
    b15:key('s', c15)
    check(b15.menuIndex == 2, 'WASD cicla os itens da pausa')
    b15:key('w', c15)
    check(b15.menuIndex == 1, 'O cursor volta ao default CONTINUAR')
    b15:key('s', c15)
    b15:key('return', c15)
    check(b15.mode == 'act', 'AGIR abre a seleção de alvo')
    b15:key('return', c15)
    check(b15.mode == 'actlist', 'ENTER no alvo abre a lista de atos')
    local obsIdx
    for i, a in ipairs(b15:actItems(e15)) do
        if a.id == 'observar' then obsIdx = i end
    end
    b15.actIndex = obsIdx
    b15:key('return', c15)
    check(b15.phase == 'pause' and b15.mode == 'actlist',
        'OBSERVAR é grátis — a consulta não fecha a pausa')
    b15:key('escape', c15)
    check(b15.mode == 'act', 'ESC desce um nível: atos → alvo')
    b15:key('escape', c15)
    check(b15.mode == 'menu', 'ESC desce outro nível: alvo → postura')
    b15:key('escape', c15)
    check(b15.phase == 'action' and b15.mode == 'action'
        and e15.quotaCount == 0 and not e15.resting and e15.enemy.state == 'seek',
        'ESC no menu é CONTINUAR — ação limpa, cota zerada, wait solto')
    check(b15.phaseClock == 0, 'O relógio da fase zera na retomada')

    -- (17) ACT custoso: aplica o gesto e fecha a pausa -------------------------
    local c17, b17 = fresh('ranger')
    local e17 = b17.enemies[1]
    b17:enterPause(c17)
    b17.menuIndex = 2
    b17:key('return', c17)
    b17:key('return', c17)
    local acalmarIdx
    for i, a in ipairs(b17:actItems(e17)) do
        if a.id == 'acalmar' then acalmarIdx = i end
    end
    check(acalmarIdx ~= nil, 'O ACT de convencer aparece na lista')
    b17.actIndex = acalmarIdx
    b17:key('return', c17)
    check(e17.convince == 1 and b17.phase == 'action',
        'O gesto custoso aplica e fecha a pausa — o pick é o custo')

    -- (18) USAR: a provisão cura de verdade e fecha a pausa ---------------------
    local c18, b18 = fresh('ranger')
    c18.data.items.provisao = 1
    b18.player.health.current = 5
    b18:enterPause(c18)
    b18.menuIndex = 3
    b18:key('return', c18)
    check(b18.mode == 'use', 'USAR abre os consumíveis da bolsa')
    b18:key('return', c18)
    check(b18.player.health.current == 9 and (c18.data.items.provisao or 0) == 0
        and b18.phase == 'action', 'Usar a provisão cura e fecha a pausa')

    -- (19) POUPAR pelo menu: a retirada conclui negotiated ----------------------
    local c19, b19 = fresh('ranger')
    local e19 = b19.enemies[1]
    e19.mercy, e19.calmed = true, true
    b19:enterPause(c19)
    b19.menuIndex = 4
    b19:key('return', c19)
    check(b19.mode == 'mercy', 'POUPAR abre quem baixou a guarda')
    b19:key('return', c19)
    check(c19.scene == 'explore' and c19.data.encounters['T01-01'] == 'negotiated',
        'O poupo no último vivo conclui negotiated na hora')

end

local function faseChecks(check)
    -- (20) §6 FUGIR: micro-fase — saída na borda oposta + volley final ----
    -- Jogadora no spawn (7,8): a borda mais próxima é a sul → a saída abre
    -- na fileira norte, na célula livre mais próxima da coluna dela — a
    -- sentinela em (7,5) empurra a saída para (6,5).
    local c20, b20 = fresh('ranger')
    local e20 = b20.enemies[1]
    b20:enterPause(c20)
    b20.menuIndex = 5
    b20:key('return', c20)
    check(b20.phase == 'action' and b20.fleeing == true
        and c20.scene == 'battle',
        'FUGIR não encerra: abre a travessia na fase de ação')
    check(b20.exitCell and b20.flee and b20.flee.edge == 'north'
        and b20.exitCell.x == 6 and b20.exitCell.y == 5,
        'A saída acende na borda oposta — norte, célula livre mais próxima')
    check(e20.volleyPending == true and b20.flee.participants == 1,
        'O hostil vivo deve uma investida final')
    -- calmed/spared não participam da volley
    local c20b, b20b = fresh('ranger')
    local e20b = b20b.enemies[1]
    e20b.mercy, e20b.calmed = true, true
    b20b:enterPause(c20b)
    b20b:choose(b20b:menuItems()[5], c20b)
    check(b20b.fleeing and not e20b.volleyPending
        and b20b.flee.participants == 0,
        'O convencido não participa da despedida — a saída fica aberta')
    -- Pisar na saída: 'return' + encontro pendente
    b20.player.grid.x, b20.player.grid.y = b20.exitCell.x, b20.exitCell.y
    frame(c20)
    check(c20.scene == 'explore' and c20.data.encounters['T01-01'] == nil,
        'Pisar na saída retira — o encontro fica pendente')
    -- A volley arma um warn de verdade e resolve — travessia falhou fecha
    local c20c, b20c = fresh('ranger')
    local e20c = b20c.enemies[1]
    b20c:startFlee(c20c)
    b20c.player.grid.x = 8        -- sai da linha de tiro: whiff honesto
    check(waitState(c20c, e20c, 'warn') == 'warn',
        'A despedida arma o telegrafo na direção da jogadora')
    tick(c20c, 2.5)
    check(not b20c.fleeing and b20c.exitCell == nil,
        'Volley fechada sem a jogadora na saída → a fuga falhou')
    check(b20c.phase == 'action' or b20c.phase == 'pause',
        'Ação continua depois da falha — o pick do menu foi gasto')
    check((b20c.log[#b20c.log] or ''):match('saída')
        or (b20c.log[#b20c.log - 1] or ''):match('saída')
        or (b20c.log[#b20c.log - 2] or ''):match('saída'),
        "O fechamento lê 'A saída fecha.'")
    -- ESC durante a fuga = desistir: fica, ação normal
    local c20d, b20d = fresh('ranger')
    b20d:startFlee(c20d)
    check(b20d:key('escape', c20d) == true
        and not b20d.fleeing and b20d.exitCell == nil
        and not b20d.enemies[1].volleyPending,
        'ESC na fase de fuga desiste — a jogadora fica')
    check(b20d.phase == 'action' and c20d.scene == 'battle',
        'Desistir não pausa — a ação segue')

    -- (21) A arena quieta atrasa o fechamento: telegrafo e projétil resolvem ---
    local c21, b21 = fresh('ranger')
    local e21 = b21.enemies[1]
    e21.quotaCount = 2
    e21.enemy.state, e21.enemy.timer = 'warn', .5
    e21.enemy.mode, e21.enemy.dx, e21.enemy.dy = 'shot', 0, 1
    e21.enemy.cells = Rooms.line(b21.room, 7, 5, 0, 1, 9)
    e21.enemy.warningDuration = 1.05
    frame(c21)
    check(b21.closing and not b21.beat and b21.phase == 'action',
        'O telegrafo armado segura o respiro — prometido resolve')
    tick(c21, .65)
    check(b21.phase == 'action' and not b21.beat,
        'O virote em voo segura o fechamento — a fase espera o quieto')
    tick(c21, 2.5)
    check(b21.phase == 'pause', 'Resolvido o warn e o virote, a pausa abre')

    -- (22) Timeout: 12s pedem o fechamento mesmo sem cota -----------------------
    local c22, b22 = fresh('ranger')
    b22.phaseClock = Battle.phaseTimeout - .02
    tick(c22, .05)
    check(b22.closing, 'O timeout de ' .. Battle.phaseTimeout .. 's pede o fechamento')
    tick(c22, 1)
    check(b22.phase == 'pause', 'Timeout + arena quieta abrem a pausa')

    -- (23) Anti-stall: 4s em seek sem engajar contam como agiu ------------------
    local c23, b23 = fresh('ranger')
    local e23 = b23.enemies[1]
    e23.enemy.state, e23.enemy.timer = 'seek', 5
    e23.stallClock = Battle.stallLimit - .05
    tick(c23, .1)
    check(e23.stalled and (b23.log[#b23.log] or ''):match('não encontra passo'),
        'Quatro segundos sem engajar contam como agiu — anti-stall')

    -- (24) Freeze: diálogo congela closing/beat; a pausa congela o mundo --------
    local c24, b24 = fresh('ranger')
    local e24 = b24.enemies[1]
    e24.quotaCount = 2
    frame(c24)
    check(b24.beat ~= nil, 'Cumprida e quieta, a arena entra no respiro')
    local beatLeft = b24.beat
    c24.dialogue = {mode = 'lines', lines = {'...'}}
    tick(c24, .5)
    check(b24.phase == 'action' and b24.beat == beatLeft,
        'Diálogo congela o beat no mesmo quadro')
    c24.dialogue = nil
    tick(c24, .5)
    check(b24.phase == 'pause', 'Descongelado, o beat abre a pausa')
    local mark = e24.grid.x + e24.grid.y
    tick(c24, .3)
    check(e24.grid.x + e24.grid.y == mark,
        'Na pausa o mundo inteiro segue congelado')
    b24:key('return', c24)
    check(b24.phase == 'action' and b24.phaseClock == 0,
        'ENTER em CONTINUAR reabre a ação limpa')
    -- O 'wait' também cai pela máquina: resting armado segura, caiu, volta.
    e24.enemy.state, e24.resting = 'wait', true
    frame(c24)
    check(e24.enemy.state == 'wait', 'Com resting armado, o respiro segura')
    e24.resting = nil
    frame(c24)
    check(e24.enemy.state == 'seek', 'Resting caiu — a máquina volta a caçar')

end

local function treguaChecks(check)
    -- (25) Convencida a meio do warn: o prometido resolve, depois a trégua --
    local c25, b25 = fresh('ranger')
    local e25 = b25.enemies[1]
    check(waitState(c25, e25, 'warn') == 'warn',
        'Setup: telegrafo armado antes do convencimento')
    e25.convince = 1
    local acalmar25
    for _, a in ipairs(b25:actItems(e25)) do
        if a.id == 'acalmar' then acalmar25 = a end
    end
    b25:actOn(e25, acalmar25, c25)
    check(e25.mercy and e25.calmed and e25.enemy.state == 'warn',
        'A trégua não corta o telegrafo em curso — a prévia nunca mente')
    local hp25 = b25.player.health.current
    for _ = 1, math.ceil(3 / DT) do
        -- 'calmed' chega no tick do resolve; o virote ainda está em voo —
        -- esperar os dois garante que o prometido resolveu por inteiro.
        if e25.enemy.state == 'calmed'
            and b25.player.health.current < hp25 then break end
        frame(c25)
    end
    check(b25.player.health.current == hp25 - 2,
        'O warn prometido resolve — parada na linha, a jogadora toma')
    check(e25.enemy.state == 'calmed' and e25.mercy,
        'Resolvido o prometido, a unidade para de vez')

    -- (26) Provocado: engajar forçado no primeiro gatilho, warn encurtado ---
    local c26, b26 = fresh('dasher')
    local e26 = b26.enemies[1]
    e26.provoked = true
    b26.player.grid.x = 8        -- desalinhada: o engage natural falharia
    check(waitState(c26, e26, 'warn') == 'warn',
        'O provocado engaja no primeiro gatilho, sem alinhamento')
    check(math.abs(e26.enemy.warningDuration - .85 * Battle.provokeWarnFactor) < .01,
        'O warn do provocado sai x' .. Battle.provokeWarnFactor)
    check(not e26.provoked, 'A isca se consome no anúncio do warn')

    -- O ACT provocar arma a flag na unidade ----------------------------------
    local c26b, b26b = fresh('dasher')
    local e26b = b26b.enemies[1]
    local prov26
    for _, a in ipairs(b26b:actItems(e26b)) do
        if a.id == 'provocar' then prov26 = a end
    end
    check(prov26 and not prov26.disabled, 'PROVOCAR aparece livre no bruto')
    b26b:actOn(e26b, prov26, c26b)
    check(e26b.provoked == true, 'O ACT provocar arma a isca na unidade')

    -- (27) D08: golpe válido no calmed desfaz tudo e devolve a caça ---------
    local c27, b27 = fresh('ranger')
    local e27 = b27.enemies[1]
    e27.mercy, e27.calmed, e27.convince = true, true, 2
    b27:applyCalm(e27)
    check(e27.enemy.state == 'calmed', 'Setup: unidade em trégua parada')
    b27:damage(e27, 1, 7, 8)
    check(not e27.mercy and not e27.calmed and e27.convince == 0
        and e27.enemy.state == 'seek',
        'O golpe no convencido zera a conversa e repõe seek')

end

local function beatsChecks(check)
    -- (28) §5.4 — a emoção do palco: função e campo cacheado ----------------
    local c28, b28 = fresh('ranger')
    local e28 = b28.enemies[1]
    check(b28:emotionFor(e28) == 'stern', 'Hostil e inteira: repouso stern')
    check(b28.stageEmotion == 'stern', 'O palco cacheia a cara da abertura')
    e28.convince = 1
    check(b28:emotionFor(e28) == 'soft', 'Conversa aberta amacia a cara')
    e28.convince = 0
    e28.health.current = 1                     -- 20% do máximo
    check(b28:emotionFor(e28) == 'fear', 'Perto da morte: fear')
    e28.health.current = e28.health.max
    e28.calmed = true
    check(b28:emotionFor(e28) == 'joy', 'Trégua aceita: joy')
    e28.calmed = nil
    e28.provoked = true
    check(b28:emotionFor(e28) == 'anger', 'Provocada: anger')
    e28.provoked = nil
    e28.spared = true
    check(b28:emotionFor(e28) == 'sad', 'Despedida: sad')
    e28.spared = nil
    local c28b, b28b = fresh('crawler')
    check(b28b:emotionFor(b28b.enemies[1]) == 'neutral',
        'Kind não-verbal descansa em neutral — o gesto é a face')
    b28:enterPause(c28)
    check(b28.stageEmotion == b28:emotionFor(b28:liveEnemies()[1]),
        'enterPause recacheia a emoção do palco')

    -- (29) Calmed é auto-cumprida: fora da cota, não segura a rodada --------
    local c29, b29 = fresh('ranger')
    local e29 = b29.enemies[1]
    e29.mercy, e29.calmed = true, true
    check(b29:quotaMet(e29) and b29:phaseFulfilled(),
        'O calmed cumpre a cota sem agir — a fase pode fechar')
    frame(c29)
    check(b29.closing, 'Arena só de calmed pede o fechamento na hora')
    tick(c29, 1)
    check(b29.phase == 'pause', 'Fechada a fase, a pausa abre com o calmed vivo')

    -- (30) §7 Beats: gatilho 'start' fala na abertura e congela a arena ----
    local c30 = Campaign.new()
    c30.dialogue = nil
    c30.data.items.arco = 1
    c30.battle = Battle.new(c30, 'T-BEAT0', {units = {{kind = 'ranger', x = 7, y = 5}},
        beats = {{when = 'start', node = 'rangerAbertura'}}})
    c30.scene = 'battle'
    local b30 = c30.battle
    check(c30.dialogue ~= nil and c30.dialogue.node == Talks.nodes.rangerAbertura,
        'O beat de abertura fala antes do primeiro tick de ação')
    check(b30.beatSpeaker == b30.enemies[1],
        'O falante do beat é a unidade do encontro')
    local g30 = b30.enemies[1].enemy.timer
    tick(c30, .3)
    check(b30.enemies[1].enemy.timer == g30,
        'O diálogo de beat congela a arena no mesmo quadro')
    c30:closeDialogue()
    frame(c30)
    check(b30.phase == 'action' and b30.mode == 'action' and c30.dialogue == nil,
        'Fechado o beat de abertura, a ação começa limpa')

    -- (31) §7 — round=N arma na pausa N e substitui o menu ------------------
    local c31 = Campaign.new()
    c31.dialogue = nil
    c31.data.items.arco = 1
    c31.battle = Battle.new(c31, 'T-BEAT1', {units = {{kind = 'ranger', x = 7, y = 5}},
        beats = {{when = {round = 2}, node = 'rangerMetade'}}})
    c31.scene = 'battle'
    local b31 = c31.battle
    b31:enterPause(c31)
    check(b31.round == 2 and b31.mode == 'beat' and c31.dialogue ~= nil
        and c31.dialogue.node == Talks.nodes.rangerMetade,
        'O beat da rodada 2 arma na primeira pausa e substitui o menu')
    c31:closeDialogue()
    frame(c31)
    check(b31.mode == 'menu' and c31.dialogue == nil,
        'Fechada a fala do beat, a pausa mostra o menu normal')

    -- (32) §7 — dois armados seguem a ordem de escrita ----------------------
    local c32 = Campaign.new()
    c32.dialogue = nil
    c32.data.items.arco = 1
    c32.battle = Battle.new(c32, 'T-BEAT2', {units = {{kind = 'ranger', x = 7, y = 5}},
        beats = {{when = {round = 2}, node = 'rangerAbertura'},
                 {when = {round = 2}, node = 'rangerMetade'}}})
    c32.scene = 'battle'
    local b32 = c32.battle
    b32:enterPause(c32)
    check(c32.dialogue and c32.dialogue.node == Talks.nodes.rangerAbertura,
        'Com dois beats armados, a ordem do def manda')
    c32:closeDialogue(); frame(c32)
    check(c32.dialogue and c32.dialogue.node == Talks.nodes.rangerMetade,
        'O segundo da fila fala em seguida')
    c32:closeDialogue(); frame(c32)
    check(b32.mode == 'menu' and c32.dialogue == nil,
        'Esvaziada a fila, a pausa cai no menu de postura')

    -- (33) §7 — hpBelow dispara ao cruzar o limiar e once não repete --------
    local c33 = Campaign.new()
    c33.dialogue = nil
    c33.data.items.arco = 1
    c33.battle = Battle.new(c33, 'T-BEAT3', {units = {{kind = 'ranger', x = 7, y = 5}},
        beats = {{when = {hpBelow = .5}, node = 'rangerMetade', once = true}}})
    c33.scene = 'battle'
    local b33, e33 = c33.battle, c33.battle.enemies[1]
    e33.health.current = 3                     -- 50% do máximo
    frame(c33)
    check(#b33.beatQueue == 1, 'Cruzar o limiar de vida arma o beat')
    frame(c33); frame(c33)
    check(#b33.beatQueue == 1, 'O beat armado não duplica na fila')
    b33:enterPause(c33)
    check(c33.dialogue and c33.dialogue.node == Talks.nodes.rangerMetade,
        'Na pausa, o falante ferido abre o diálogo')
    check(b33.beatFired[1] == true, 'O once marca o gatilho como disparado')
    c33:closeDialogue(); frame(c33)
    b33:resumeAction(); frame(c33)
    check(#b33.beatQueue == 0,
        'O once não rearma — a vida segue abaixo do limiar')
    b33:enterPause(c33)
    check(c33.dialogue == nil and b33.mode == 'menu',
        'A pausa seguinte cai no menu de postura')

    -- (34) §7 — passiveFor acumula segundos sem atacar e dispara ------------
    local c34 = Campaign.new()
    c34.dialogue = nil
    c34.data.items.arco = 1
    c34.battle = Battle.new(c34, 'T-BEAT4', {units = {{kind = 'ranger', x = 7, y = 5}},
        beats = {{when = {passiveFor = .5}, node = 'rangerAbertura', once = true}}})
    c34.scene = 'battle'
    local b34 = c34.battle
    tick(c34, .6)
    check(#b34.beatQueue == 1,
        'Meio segundo sem empunhar o arco arma o gatilho de passividade')
    local c34b, b34b = fresh('ranger')
    tick(c34b, .3)
    check((b34b.passiveClock or 0) > .2,
        'O relógio de passividade acumula parada')
    frame(c34b, {dx = 0, dy = 0, guard = false, events = {{kind = 'charge'}}})
    check(b34b.passiveClock == 0, 'Empunhar o arco zera o relógio de passividade')

    -- (35) §7 — mercy arma na hora e fala na pausa seguinte -----------------
    local c35 = Campaign.new()
    c35.dialogue = nil
    c35.data.items.arco = 1
    c35.battle = Battle.new(c35, 'T-BEAT5', {units = {{kind = 'ranger', x = 7, y = 5}},
        beats = {{when = 'mercy', node = 'rangerEntrega', once = true}}})
    c35.scene = 'battle'
    local b35, e35 = c35.battle, c35.battle.enemies[1]
    local acalmar35
    for _, a in ipairs(b35:actItems(e35)) do
        if a.id == 'acalmar' then acalmar35 = a end
    end
    b35:actOn(e35, acalmar35, c35)
    b35:actOn(e35, acalmar35, c35)
    check(e35.mercy and e35.calmed and #b35.beatQueue == 1,
        'A unidade que baixa a guarda arma o beat de entrega na hora')
    b35:enterPause(c35)
    check(c35.dialogue and c35.dialogue.node == Talks.nodes.rangerEntrega
        and b35.beatSpeaker == e35,
        'O beat de entrega fala na pausa seguinte, na voz de quem se rendeu')

    -- (36) §7 — morto não fala; misto sem falante não dispara ---------------
    local c36 = Campaign.new()
    c36.dialogue = nil
    c36.data.items.arco = 1
    c36.battle = Battle.new(c36, 'T-BEAT6', {units = {
        {kind = 'ranger', x = 6, y = 5,
            beats = {{when = {hpBelow = .5}, node = 'rangerMetade', once = true}}},
        {kind = 'ranger', x = 9, y = 5}}})
    c36.scene = 'battle'
    local b36, e36 = c36.battle, c36.battle.enemies[1]
    b36:damage(e36, 99, e36.grid.x, e36.grid.y)
    frame(c36)
    check(e36.health.current == 0 and #b36.beatQueue == 0 and c36.dialogue == nil,
        'Morto não fala — o beat da unidade caída não arma')
    local c37 = Campaign.new()
    c37.dialogue = nil
    c37.battle = Battle.new(c37, 'T-BEAT7', {units = {{kind = 'crawler', x = 7, y = 5}},
        beats = {{when = {hpBelow = .5}, node = 'rangerMetade'}}})
    c37.scene = 'battle'
    local b37 = c37.battle
    b37.enemies[1].health.current = 2
    frame(c37)
    check(#b37.beatQueue == 0 and c37.dialogue == nil,
        'Encontro sem falante vivo não dispara beat — o gesto é a face')

    -- (37b) §7 — u.speaker declarado fala no lugar do primeiro vivo ---------
    local c37b = Campaign.new()
    c37b.dialogue = nil
    c37b.battle = Battle.new(c37b, 'T-BEAT7b', {units = {
        {kind = 'ranger', x = 6, y = 5}, {kind = 'ranger', x = 9, y = 5, speaker = true}},
        beats = {{when = 'start', node = 'rangerAbertura'}}})
    c37b.scene = 'battle'
    check(c37b.battle.beatSpeaker == c37b.battle.enemies[2],
        'O u.speaker do def assume a voz do beat do encontro')

    -- (38) §7 — 'won' vence a fila de beats ---------------------------------
    local c38 = Campaign.new()
    c38.dialogue = nil
    c38.data.items.arco = 1
    c38.battle = Battle.new(c38, 'T-BEAT8', {units = {{kind = 'ranger', x = 7, y = 5}},
        beats = {{when = {hpBelow = .6}, node = 'rangerMetade'}}})
    c38.scene = 'battle'
    local b38, e38 = c38.battle, c38.battle.enemies[1]
    e38.health.current = 3
    frame(c38)
    check(#b38.beatQueue == 1, 'O beat arma com a vida abaixo do limiar')
    e38.health.current = 1
    b38:damage(e38, 5, e38.grid.x, e38.grid.y)
    tick(c38, .2)
    check(c38.scene == 'explore' and c38.dialogue == nil,
        "A queda do último vivo conclui 'won' — a fila de beats morre junto")

end

local function chefesChecks(check)
    -- (39) §12.5 — JANDA martelo: pilar próximo, faixa anunciada, queda -----
    -- Janda em (6,5): pilar (4,7) a 4 manhattan dispara; (10,7) fica a 6.
    -- A jogadora em (7,7) entra na faixa de queda leste do pilar.
    local c39 = Campaign.new()
    c39.dialogue = nil
    c39.battle = Battle.new(c39, 'B02-01', {units = {{kind = 'janda', x = 6, y = 5}}})
    c39.scene = 'battle'
    local b39, e39 = c39.battle, c39.battle.enemies[1]
    b39.player.grid.x, b39.player.grid.y = 7, 7
    check(waitState(c39, e39, 'warn') == 'warn' and e39.enemy.mode == 'hammer',
        'Janda martela o pilar no alcance — o gatilho precede a família')
    check(e39.enemy.cells[1].x == 4 and e39.enemy.cells[1].y == 7
        and #e39.enemy.cells > 1,
        'O warn marca a célula do pilar e a faixa de queda')
    local hp39 = b39.player.health.current
    tick(c39, 1.3)
    check(b39.player.health.current == hp39 - Battle.pillarDamage,
        'A laje cobra pillarDamage de quem está na banda')
    check(b39.player.grid.x ~= 7 or b39.player.grid.y ~= 7,
        'A queda reposiciona a jogadora para uma célula segura')
    check(Rooms.cell(b39.room, 4, 7).piece == nil
        and Rooms.cell(b39.room, 4, 7).state == 'fallen'
        and Rooms.cell(b39.room, 5, 7).piece == 'fallen',
        'O pilar cai na direção anunciada — a faixa vira entulho')
    -- Whiff honesto: o pilar já caiu entre anúncio e golpe
    local c39b = Campaign.new()
    c39b.dialogue = nil
    c39b.battle = Battle.new(c39b, 'B02-01b', {units = {{kind = 'janda', x = 6, y = 5}}})
    c39b.scene = 'battle'
    local b39b, e39b = c39b.battle, c39b.battle.enemies[1]
    b39b.player.grid.x, b39b.player.grid.y = 7, 7
    check(waitState(c39b, e39b, 'warn') == 'warn' and e39b.enemy.mode == 'hammer',
        'Setup do whiff: martelo armado')
    Rooms.cell(b39b.room, 4, 7).piece = nil
    local hp39b = b39b.player.health.current
    tick(c39b, 1.3)
    check(b39b.player.health.current == hp39b
        and Rooms.cell(b39b.room, 5, 7).piece == nil,
        'Pilar já caído → Janda golpeia o vazio, sem dano nem entulho')
    -- Sem pilar no alcance, a família cobre o plano (dash do bruto)
    local c39c = Campaign.new()
    c39c.dialogue = nil
    c39c.battle = Battle.new(c39c, 'B02-01c', {kind = 'janda'})
    c39c.scene = 'battle'
    local e39c = c39c.battle.enemies[1]
    Rooms.cell(c39c.battle.room, 4, 7).piece = nil
    Rooms.cell(c39c.battle.room, 10, 7).piece = nil
    check(waitState(c39c, e39c, 'warn') == 'warn'
        and e39c.enemy.mode == 'dash',
        'Sem pilar no alcance, a Janda cai na investida da família')

    -- (40) §12.5 — RUTE vara: caixote desliza, destino = jogadora empurra --
    local c40 = Campaign.new()
    c40.dialogue = nil
    c40.battle = Battle.new(c40, 'B03-01', {units = {{kind = 'rute', x = 7, y = 5}},
        crates = {{x = 4, y = 6}}})
    c40.scene = 'battle'
    local b40, e40 = c40.battle, c40.battle.enemies[1]
    check(Rooms.cell(b40.room, 4, 6).piece == 'crate' and b40.crates[1]
        == Rooms.cell(b40.room, 4, 6),
        'O caixote do encontro está plantado e referenciado')
    b40.player.grid.x, b40.player.grid.y = 6, 6   -- alinhada, dist 2, destino (5,6)
    check(waitState(c40, e40, 'warn') == 'warn' and e40.enemy.mode == 'push'
        and e40.enemy.cells[1].x == 5 and e40.enemy.cells[1].y == 6,
        'A vara telegrafa só a célula-destino do caixote')
    tick(c40, 1.3)
    check(Rooms.cell(b40.room, 4, 6).piece == nil
        and Rooms.cell(b40.room, 5, 6).piece == 'crate'
        and b40.crates[1] == Rooms.cell(b40.room, 5, 6),
        'O caixote desliza para o destino e a lista acompanha')
    -- Jogadora no destino: cede uma célula além e o caixote ocupa a dela
    local c40b = Campaign.new()
    c40b.dialogue = nil
    c40b.battle = Battle.new(c40b, 'B03-01b', {units = {{kind = 'rute', x = 7, y = 5}},
        crates = {{x = 4, y = 6}}})
    c40b.scene = 'battle'
    local b40b, e40b = c40b.battle, c40b.battle.enemies[1]
    b40b.player.grid.x, b40b.player.grid.y = 5, 6   -- destino é a célula dela
    waitState(c40b, e40b, 'warn')
    tick(c40b, 1.3)
    check(b40b.player.grid.x == 6 and b40b.player.grid.y == 6
        and Rooms.cell(b40b.room, 5, 6).piece == 'crate'
        and b40b.player.health.current == b40b.player.health.max,
        'No destino, a jogadora cede um passo — sem dano, controle puro')
    -- Sem célula além, a jogadora não cede e o caixote fica
    local c40c = Campaign.new()
    c40c.dialogue = nil
    c40c.battle = Battle.new(c40c, 'B03-01c', {units = {{kind = 'rute', x = 7, y = 5}},
        crates = {{x = 4, y = 6}}})
    c40c.scene = 'battle'
    local b40c, e40c = c40c.battle, c40c.battle.enemies[1]
    Rooms.cell(b40c.room, 6, 6).piece = 'wall'
    b40c.player.grid.x, b40c.player.grid.y = 5, 6
    waitState(c40c, e40c, 'warn')
    tick(c40c, 1.3)
    check(b40c.player.grid.x == 5 and Rooms.cell(b40c.room, 4, 6).piece == 'crate',
        'Sem célula livre além, a vara empurra e a jogadora não cede')

    -- (41) §12.5 — IVO jato: a banda inteira, escudo não protege ----------
    local c41 = Campaign.new()
    c41.dialogue = nil
    c41.battle = Battle.new(c41, 'B04-01', {units = {
        {kind = 'ivo', x = 7, y = 5}, {kind = 'husk', x = 5, y = 7}}})
    c41.scene = 'battle'
    local b41, e41, h41 = c41.battle, c41.battle.enemies[1], c41.battle.enemies[2]
    b41.player.grid.x, b41.player.grid.y = 7, 7    -- fileira 7 é banda default
    check(waitState(c41, e41, 'warn') == 'warn' and e41.enemy.mode == 'jet',
        'A jogadora na banda arma o jato')
    check(#e41.enemy.cells == 9,
        'O warn marca TODAS as células floor da fileira (11 - 2 pilares)')
    local hp41 = b41.player.health.current
    tick(c41, 1.3, {dx = 0, dy = 0, guard = true, events = {}})
    check(b41.player.health.current == hp41 - Battle.arrowDamage,
        'O jato cobra arrowDamage mesmo com o escudo armado — é hazard de área')
    check(h41.replaced == true,
        'O jato acerta aliado na banda — a eclosão do casulo prova o golpe')
    check(e41.health.current == e41.health.max,
        'Ivo controla as válvulas — o próprio jato não o fere')

    -- (42) §12.5 — BELTRAN bastão: empurrão, escudo, prensa ----------------
    local c42 = Campaign.new()
    c42.dialogue = nil
    c42.battle = Battle.new(c42, 'B05-01', {units = {{kind = 'beltran', x = 7, y = 5}}})
    c42.scene = 'battle'
    local b42, e42 = c42.battle, c42.battle.enemies[1]
    b42.player.grid.x, b42.player.grid.y = 7, 7
    check(waitState(c42, e42, 'warn') == 'warn' and e42.enemy.mode == 'shove',
        'O gatilho é o do bruto, o selo é do bastão — lane igual')
    tick(c42, 1.3)
    check(b42.player.grid.x == 7 and b42.player.grid.y == 9
        and b42.player.health.current == b42.player.health.max
        and b42.player.shoveT ~= nil,
        'O bastão desliza a jogadora até 2 células — sem dano')
    check(e42.grid.x == 7 and e42.grid.y == 7,
        'Beltran termina onde a jogadora estava')
    -- Escudo frontal bloqueia o empurrão inteiro
    local c42b = Campaign.new()
    c42b.dialogue = nil
    c42b.battle = Battle.new(c42b, 'B05-01b', {units = {{kind = 'beltran', x = 7, y = 5}}})
    c42b.scene = 'battle'
    local b42b, e42b = c42b.battle, c42b.battle.enemies[1]
    b42b.player.grid.x, b42b.player.grid.y = 7, 7
    waitState(c42b, e42b, 'warn')
    tick(c42b, 1.3, {dx = 0, dy = 0, guard = true, events = {}})
    check(b42b.player.grid.x == 7 and b42b.player.grid.y == 7
        and b42b.player.health.current == b42b.player.health.max,
        'Escudo frontal: BLOQUEADO — sem empurrão nem dano')
    check(e42b.grid.y == 6, 'Bloqueado, Beltran não avança sobre ela')
    -- Prensa: parede nas costas cobra 1 de vida
    local c42c = Campaign.new()
    c42c.dialogue = nil
    c42c.battle = Battle.new(c42c, 'B05-01c', {units = {{kind = 'beltran', x = 7, y = 5}}})
    c42c.scene = 'battle'
    local b42c, e42c = c42c.battle, c42c.battle.enemies[1]
    b42c.player.grid.x, b42c.player.grid.y = 7, 9   -- costas na borda sul
    waitState(c42c, e42c, 'warn')
    tick(c42c, 1.4)
    check(b42c.player.grid.y == 9
        and b42c.player.health.current == b42c.player.health.max - 1,
        'Zero células livres: a prensa cobra 1 de vida')

end

    acaoChecks(check)
    socialChecks(check)
    faseChecks(check)
    treguaChecks(check)
    beatsChecks(check)
    chefesChecks(check)
    runaGradeChecks(check)

    mergeCollisionChecks(check)
    fatia3(check)

    print(string.format('%d BATTLE ASSERTIONS PASSED', checks))
end

return BattleTest
