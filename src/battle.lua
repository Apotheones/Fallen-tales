-- Arena fásica da campanha (docs/COMBATE_MERGE.md): ação em tempo real ⇄
-- pausa social. O combate por turnos morreu de vez — a arena é um sub-mundo
-- Concord idêntico ao do protótipo (Movement, Player, Enemy, Boss,
-- Projectile, Environment e Damage rodam sobre a superfície `g` que
-- src/game.lua expõe) e as fases vivas são 'action' e 'pause'.
--
-- O ciclo (§2/§3): a fase de ação roda o motor; cada inimigo cumpre a cota
-- de resolves (whiff conta, summoned não entra) ou o relógio estoura — o
-- pedido de fechamento espera a arena quieta, quem cumpriu recua um passo e
-- respira em 'wait', o beat de .4s abre a pausa e o menu social decide a
-- próxima postura.
--
-- Contratos que a arena preserva:
--  - O que foi prometido, resolve: warn/dash/volley do catálogo Enemies
--    nunca amplia alcance depois do anúncio.
--  - Diálogo, pausa ou fase não-ação congelam a simulação no mesmo quadro —
--    projétil em voo inclusive.
--  - Zerar a arena na ação conclui na hora ('won' ou 'negotiated'); servos
--    invocados não entram na contagem das unidades do def.
--  - Derrota não é morte: hp 0 segue campaign:die — a Colina conserva tudo.
local Concord = require('src.components')
local Systems = require('src.systems')
local Environment = require('src.environment')
local Enemies = require('src.enemies')
local Boss = require('src.boss')
local Region = require('src.region')
local Rooms = require('src.rooms')
local Barks = require('src.battle_barks')
local Sfx = require('src.sfx')
local Items = require('src.items')
local Dialogue = require('src.dialogue')
local Talks = require('src.battle_talks')
local LoreC = require('src.campaign_lore')
local Battle = {}; Battle.__index = Battle

Battle.graceTime = .8          -- piso do think inicial de cada inimigo (§4)
Battle.phaseQuota = 2          -- cota de resolves por fase (§2)
Battle.phaseTimeout = 12       -- timeout da fase de ação (§2)
Battle.stallLimit = 4          -- anti-stall em segundos (§2)
Battle.beatTime = .4           -- respiro com todos quietos antes da pausa (§2.1)
Battle.provokeWarnFactor = .8  -- warn do provocado (§5.1)
Battle.bowDamage = 3           -- arco único — sem melee (decisão 9)
Battle.staminaMax = 1.6        -- fôlego cheio — makePlayer da campanha usa
Battle.convinceNeeded = 2      -- ACTs sociais aceitos antes do mercy
Battle.pillarDamage = 2        -- queda de pilar por golpe — martelo da Janda
Battle.arrowDamage = 2         -- jato de área do Ivo (hazard, ignora escudo)

-- kind -> dados sociais e de arena (era ROLES do modelo de turnos: agora é a
-- ponte kind->def de Enemies + nome/vida/limiar). Os chefes humanos têm defs
-- próprios no catálogo (Enemies.janda/rute/ivo/beltran, passo 12.5) — o
-- `boss` do role fica como marcador social: a música lê para o tema e o
-- confronto para a introdução. `plan` só escolhe a família real-time dos
-- kinds ainda sem entrada própria no catálogo.
local ROLES = {
    ranger = {name = 'SENTINELA', hp = 6, plan = 'sentinel'},
    dasher = {name = 'BRUTO', hp = 6, plan = 'brute', armor = true},
    crawler = {name = 'RASTEJANTE', hp = 4, plan = 'crawl'},
    -- Os chefes humanos: a mecânica real-time mora em Enemies[kind]
    -- (hammer/push/jet/shove) — ROLES guarda só a ponte social (hp/limiar).
    runa = {name = 'RUNA', hp = 10, plan = 'sentinel', convinceNeeded = 3},
    janda = {name = 'JANDA', hp = 14, plan = 'brute', convinceNeeded = 3},
    rute = {name = 'RUTE', hp = 12, plan = 'sentinel', convinceNeeded = 3},
    ivo = {name = 'IVO', hp = 14, plan = 'sentinel', convinceNeeded = 3},
    beltran = {name = 'BELTRAN', hp = 12, plan = 'brute', convinceNeeded = 3},
    demolisher = {name = 'O DEMOLIDOR DA CÂMARA', hp = 8, plan = 'demolish'},
    breaker = {name = 'BRUTO DEMOLIDOR', hp = 10, plan = 'demolish', armor = true},
    watcher = {name = 'VIGIA DOS ECOS', hp = 5, plan = 'watch'},
    regent = {name = 'A REGENTE DE ÂMBAR', hp = 10, plan = 'ritual'},
    warden = {name = 'GUARDIÃO DOS ECOS', hp = 12, plan = 'brute', armor = true,
        fury = true},
    sower = {name = 'SEMEADOR DE ÂMBAR', hp = 6, plan = 'sow'},
    husk = {name = 'ECO NASCENTE', hp = 3, plan = 'husk'},
    veteran = {name = 'SENTINELA VETERANA', hp = 8, plan = 'sentinel',
        double = true},
}

-- Tabuleiro horizontal estilo Fractured But Whole: 11x5, mais largo que alto.
-- A sala inteira cabe na tela; as fileiras de cima ficam para o palco do
-- inimigo (o sprite grande estilo Undertale desenhado pelo renderer).
-- A sala tem largura 13 para que o tabuleiro 11x5 (colunas 2..12) fique
-- centrado sob o palco: margem de uma célula de cada lado.
local arenaDef = {
    id = 'arena', uid = 90, name = 'ARENA', w = 13, h = 10,
    spawn = {x = 7, y = 8},
    carve = {{x = 2, y = 5, w = 11, h = 5}},
    pillars = {{x = 4, y = 7, hits = 2}, {x = 10, y = 7, hits = 2}},
}

-- plan do role -> kind do catálogo Enemies: a família real-time que um kind
-- sem def própria veste. Os chefes humanos já têm entrada no catálogo — o
-- plan deles sobrevive só como etiqueta social e ponte de música.
local FAMILY = {brute = 'dasher', sentinel = 'ranger', crawl = 'crawler',
    demolish = 'demolisher', watch = 'watcher', ritual = 'regent',
    sow = 'sower', husk = 'husk'}

-- Def real-time de um kind: o catálogo manda quando existe entrada própria;
-- para os chefes humanos (e qualquer kind ainda não migrado) deriva um def da
-- família do role — honrando a armadura autoral e a vida do role. A entrada
-- derivada é cacheada no catálogo: idempotente e compartilhada entre arenas.
local function rtDef(kind)
    local def = Enemies[kind]
    if def then return def end
    local role = ROLES[kind] or ROLES.ranger
    local base = Enemies[FAMILY[role.plan] or 'ranger'] or Enemies.ranger
    def = setmetatable({label = role.name, hp = role.hp,
        armor = role.armor == true, bridged = FAMILY[role.plan] or 'ranger'},
        {__index = base})
    Enemies[kind] = def
    return def
end

-- Gates de item nos ACTs dos chefes (BATALHA_ACT_MERCY §5): a prova narrativa
-- que a jogadora carrega habilita o gesto certo. O ACT aparece sempre na
-- lista — descoberta honesta — mas fica travado com o motivo até a peça
-- estar na bolsa.
local ACT_ITEM = {recibo = 'reciboEma', desvio = 'esquemaCanal',
    conjunto = 'esquemaCanal', rota = 'laudo', funcao = 'laudo'}

-- Proposals que já têm mecânica (§15 do doc antigo, mapeadas ao tempo real):
-- só esses gestos saem do cadeado; os demais `proposal=true` seguem
-- desabilitados com o motivo honesto de sempre.
local LIVE_ACT = {
    watcher = {vela = true},        -- sem vela, o vigia baixa a guarda
    husk = {embalar = true},        -- embalar recoloca a eclosão no teto
    regent = {despedida = true},    -- o canto pesa como gesto social
}

-- Construção ---------------------------------------------------------------

-- The third argument may be a bare kind or the encounter def; a def can carry
-- `units = {{kind, x, y}, ...}` for multi-enemy fights.
function Battle.new(campaign, encounterId, kind)
    local self = setmetatable({}, Battle)
    self.campaign = campaign
    self.encounterId = encounterId
    self.def = type(kind) == 'table' and kind or nil
    self.ctx = self.def and self.def.ctx
    self.snapshot = {region = campaign.map.id,
        x = campaign.player.grid.x, y = campaign.player.grid.y}
    self.room = Region.build(arenaDef)
    -- O sub-mundo: mesmo contrato do game.lua — 'game' aponta para o próprio
    -- Battle, que implementa a superfície g que os sistemas esperam.
    self.world = Concord.world():setResource('game', self)
    self.world:addSystems(Systems.Movement, Systems.Player, Systems.Enemy,
        Systems.Projectile, Environment, Systems.Damage, Boss)
    -- A jogadora: entidade real do mundo — vida e fôlego vêm da campanha e
    -- voltam para ela no endBattle/die (Campaign:syncStamina).
    local pg = campaign.player.guard or {}
    local chp = campaign.player.health or {current = 10, max = 10}
    self.player = Concord.entity(self.world)
        :give('grid', self.room.spawn.x, self.room.spawn.y)
        :give('motion', .16)
        :give('facing', 0, -1)
        :give('health', chp.max or 10)
        :give('team', 'player')
        :give('player'):give('weapon'):give('guard')
    self.player.health.current = chp.current or chp.max or 10
    self.player.guard.energy = pg.energy or Battle.staminaMax
    self.player.guard.max = pg.max or Battle.staminaMax
    -- Unidades do def em ordem estável (#1, #2...): a lista `enemies` é a
    -- ordem canônica de leitura — spawn, log e renderer concordam sobre ela.
    local units = self.def and self.def.units
        or {{kind = self.def and self.def.kind or kind, x = 7, y = 5}}
    self.enemies = {}
    self.spawned = 0
    for i, u in ipairs(units) do
        local id = #units > 1 and (encounterId .. '#' .. i) or encounterId
        self:spawnUnit(id, u)
    end
    self.world:emit('flush')
    -- §7: tabela de gatilhos de conversa normalizada (def + unidade + kind).
    self:buildBeats(units)
    -- def.crates (RUTE): caixotes do encontro — peças-cobertura plantadas
    -- antes do primeiro tick, como no modelo antigo.
    self.crates = {}
    for _, pos in ipairs(self.def and self.def.crates or {}) do
        local cell = Rooms.cell(self.room, pos.x, pos.y)
        if cell and cell.ground == 'floor' and not cell.piece
            and self:free(pos.x, pos.y) then
            cell.piece, cell.crate, cell.hits = 'crate', true, 0
            self.crates[#self.crates + 1] = cell
        end
    end
    self.channels = self.def and self.def.channels or nil
    -- Inventário real da campanha: a arena lê e consome o mesmo data.items
    -- que persiste no save. render.lua ainda consulta items.cura (HUD
    -- legado): o __index responde a contagem de consumíveis usáveis.
    self.items = campaign.data.items
    if not getmetatable(self.items) then
        local inv = self.items
        setmetatable(inv, {__index = function(_, k)
            if k ~= 'cura' then return nil end
            local n = 0
            for id, qty in pairs(inv) do
                if Items.usableInBattle(id) then n = n + qty end
            end
            return n
        end})
    end
    -- Superfície g ---------------------------------------------------------
    self.weapons = {bow = {label = 'ARCO', damage = Battle.bowDamage,
        chargeTime = .72, chargeSpeed = 1, interval = .035,
        color = {.96, .73, .32}}}
    self.damageBonus, self.upgrades = 0, {}
    self.pickaxes = campaign.data.items.picareta or 0
    self.reward = false
    self.state, self.phase, self.mode = 'playing', 'action', 'action'
    self.time, self.message, self.messageTime = 0, '', 0
    self.input = {dx = 0, dy = 0, guard = false, events = {}}
    self.dialogue = campaign.dialogue
    self.over = false
    -- Relógios da fase (§2/§2.1): a cota cumprida ou o timeout pedem o
    -- fechamento; o beat é a respiração coletiva que antecede a pausa.
    self.phaseClock, self.closing, self.beat = 0, false, nil
    -- Superfície de compatibilidade do renderer (o palco do Traço migra no
    -- próprio passo; os campos seguem existindo e honestos).
    self.round = 1
    self.turnStart = {x = self.room.spawn.x, y = self.room.spawn.y}
    self.hazards = {}
    self.menuIndex, self.actIndex, self.actTarget = 1, 1, 1
    self.mercyIndex, self.useIndex = 1, 1
    self.aim, self.inspect = nil, nil
    self.acted = false
    -- §6 — micro-fase de fuga (contrato do Traço): `fleeing` marca a
    -- travessia, `exitCell` é a célula acesa na borda oposta, `flee.edge`
    -- nomeia a borda. Nil fora da fuga.
    self.fleeing, self.exitCell, self.flee = nil, nil, nil
    self.log = {}
    local opener = self:liveEnemies()[1]
    -- Fala de abertura (§4): bark 'announce' do primeiro vivo antes da ação.
    if opener then self:sayBark(opener, 'announce') end
    -- §5.4: o palco nasce com a cara certa mesmo sem linha de abertura.
    self.stageEmotion = opener and self:emotionFor(opener) or nil
    self:say((opener and opener.name or 'A ARENA') .. ' — a arena fecha.')
    -- §7: gatilhos 'start' falam na abertura — o diálogo congela a arena
    -- antes do primeiro tick de ação (o contrato de freeze já segura o resto).
    self:evalBeats('start')
    self:pumpBeats(campaign)
    return self
end

-- Spawning de unidades ------------------------------------------------------

-- Unidade do def: entidade Concord com vida do role, social na entidade e
-- janela de graça escalonada — ninguém engaja no mesmo tick (§4).
function Battle:spawnUnit(id, u)
    local kind = u.kind or 'ranger'
    local role = ROLES[kind] or ROLES.ranger
    local def = rtDef(kind)
    local e = Concord.entity(self.world)
        :give('grid', u.x or 7, u.y or 5)
        :give('motion', .24)
        :give('facing', 0, 1)
        :give('health', u.hp or role.hp or def.hp or 5)
        :give('team', 'enemy')
        :give('enemy', kind)
    local a = e.enemy
    a.id = id
    a.frontalArmor = def.armor == true
    a.elite = def.elite == true
    a.boss = def.boss == true
    a.summoned = false
    a.timer = Battle.graceTime + self.spawned * .15
    if def.dormant then
        a.state, a.timer = 'dormant', def.hatchTime or 3
        a.hatch, a.hatchTime = def.hatch, def.hatchTime or 3
    end
    a.wasState = a.state          -- varredura pós-emit detecta o resolve pela transição
    self.spawned = self.spawned + 1
    -- Social na entidade (§5): nome/ctx/limiar via unidade → def → role →
    -- global; `role`/`name` são o que o cartão de inspeção lê.
    e.role, e.name = role, u.name or Barks.name(kind)
    e.ctx = u.ctx or self.ctx
    e.nonLethal = u.nonLethal   -- §5.3: a unidade arma (ou desarma) a rendição
    e.convinceNeeded = u.convinceNeeded or (self.def and self.def.convinceNeeded)
        or role.convinceNeeded or Battle.convinceNeeded
    e.quotaLimit = u.quota        -- cota por unidade (§2); quotaFor resolve a cadeia
    e.quotaCount, e.stallClock = 0, 0
    e.speaker = u.speaker == true -- §7: falante declarado dos beats do encontro
    -- Convicção vinda de fora (diálogo de abertura, §5.1 — o caminho é o
    -- mesmo do ACT no limiar): a unidade nasce em trégua e applyCalm a
    -- estaciona no primeiro tick de ação.
    if u.mercy or u.calmed then e.mercy, e.calmed = true, true end
    self.enemies[#self.enemies + 1] = e
    return e
end

-- g:spawnEnemy — eclosão do casulo e servos invocados usam a mesma porta do
-- protótipo. `summoned` sai da contagem do encontro nos filtros; quem entra
-- no lugar de outra unidade (casulo → rastejante) continua contando.
function Battle:spawnEnemy(x, y, kind, summoned)
    local def = rtDef(kind)
    local e = Concord.entity(self.world)
        :give('grid', x, y):give('motion', .24):give('facing', -1, 0)
        :give('health', def.hp or 5):give('team', 'enemy'):give('enemy', kind)
    local a = e.enemy
    a.id = self.encounterId .. '+' .. self.spawned
    a.frontalArmor = def.armor == true
    a.elite = def.elite == true
    a.boss = def.boss == true
    a.summoned = summoned == true
    if def.dormant then
        a.state, a.timer = 'dormant', def.hatchTime or 3
        a.hatch, a.hatchTime = def.hatch, def.hatchTime or 3
    end
    a.wasState = a.state
    self.spawned = self.spawned + 1
    e.role, e.name = ROLES[kind] or ROLES.ranger, Barks.name(kind)
    e.ctx = self.ctx
    e.convinceNeeded = Battle.convinceNeeded
    e.quotaCount, e.stallClock = 0, 0
    self.enemies[#self.enemies + 1] = e
    return e
end

-- Queries ------------------------------------------------------------------

function Battle:entities() return self.world:getEntities() end

-- A def-unit morreu e saiu do mundo com a vida intacta (casulo eclodido,
-- rendido removido por outra rota): `replaced` tira ela de todas as
-- contagens sem confundir com queda ou poupo.
local function counted(e)
    return e.health.current > 0 and not e.spared and not e.replaced
        and not (e.enemy and e.enemy.summoned)
end

function Battle:free(x, y, ignorePlayer)
    if not Rooms.floor(self.room, x, y) then return false end
    if not ignorePlayer then
        local p = self.player.grid
        if p.x == x and p.y == y then return false end
    end
    for _, e in ipairs(self.enemies) do
        if counted(e) and e.grid.x == x and e.grid.y == y then return false end
    end
    return true
end

function Battle:liveEnemies()
    local list = {}
    for _, e in ipairs(self.enemies) do
        if counted(e) then list[#list + 1] = e end
    end
    return list
end

-- Enemies que aceitaram trégua e ainda podem receber a retirada.
function Battle:spareable()
    local list = {}
    for _, e in ipairs(self.enemies) do
        if counted(e) and (e.mercy or e.calmed) then list[#list + 1] = e end
    end
    return list
end

-- Rendição não-letal (C05-Q01 duelo combinado, C01-Q1 grade da Runa):
-- a cadeia declarativa decide se zerar a vida executa ou rende
-- (COMBATE_MERGE §5.3) — unidade > def do encontro > contexto de bark.
-- Um booleano declarado num elo superior decide sozinho: `false` desarma
-- os inferiores, não só `true` arma. O kind nunca decide por conta
-- própria: é sempre a ficha do encontro falando.
function Battle:nonLethal(e)
    if e.nonLethal ~= nil then return e.nonLethal == true end
    if self.def and self.def.nonLethal ~= nil then
        return self.def.nonLethal == true
    end
    local c = e.enemy and Barks.context(e.enemy.kind, e.ctx) or nil
    return c ~= nil and c.nonLethal == true
end

-- Desfecho único: 'negotiated' só quando nenhuma unidade do def caiu de
-- fato — rendição e poupo contam como resolução pacífica; servos invocados
-- e unidades substituídas ficam fora da contagem (§11, D11).
function Battle:outcome()
    for _, e in ipairs(self.enemies) do
        if not e.spared and not e.replaced
            and not (e.enemy and e.enemy.summoned)
            and e.health.current <= 0 then return 'won' end
    end
    return 'negotiated'
end

-- §5.4 — o retrato do palco: a emoção é telemetria social lida do estado da
-- unidade, não do sprite. O Traço consome a função ou o campo cacheado
-- `stageEmotion` (atualizado quando o palco fala em sayBark e a cada
-- enterPause). Precedência da ficha social: a despedida e a raiva pesam
-- mais que a trégua, que pesa mais que a guarda caindo, que pesa mais que
-- o medo de quase cair — e quem não tem fala não franze a testa.
function Battle:emotionFor(e)
    if not e then return 'neutral' end
    if e.spared then return 'sad' end
    if e.provoked then return 'anger' end
    if e.calmed or e.mercy then return 'joy' end
    if (e.convince or 0) > 0 then return 'soft' end
    if e.health and e.health.current < e.health.max * .3 then return 'fear' end
    -- Kinds não-verbais não têm expressão de guarda: o gesto é a face —
    -- o repouso deles lê 'neutral', não 'stern'.
    if e.enemy and Barks.kind(e.enemy.kind).verbal == false then return 'neutral' end
    return 'stern'
end

-- First def-unit that actually fell (dead, not spared) — for the victory
-- notice when the opener was the one shown mercy instead.
function Battle:firstFallenName()
    for _, e in ipairs(self.enemies) do
        if not e.spared and not e.replaced and e.health.current <= 0
            and not (e.enemy and e.enemy.summoned) then return e.name end
    end
end

-- Superfície g (o que systems/enemies/environment esperam do mundo) ---------

function Battle:weaponStats()
    local stats = {}
    for k, v in pairs(self.weapons.bow) do stats[k] = v end
    stats.damage = stats.damage + self.damageBonus
    if self.upgrades.bowPierce then stats.damage = math.max(1, stats.damage - 1) end
    if self.upgrades.bowQuick then stats.chargeSpeed = stats.chargeSpeed * 1.35 end
    return stats
end

function Battle:notify(text, duration)
    self.message, self.messageTime = text, duration or 2.5
    self.campaign:notify(text, duration)
end

function Battle:effect(kind, x, y, value)
    self.campaign:effect(kind, x, y, value)
end

function Battle:say(text)
    self.log[#self.log + 1] = text
    if #self.log > 4 then table.remove(self.log, 1) end
end

function Battle:occupant(x, y, except)
    for _, e in ipairs(self:entities()) do
        if e ~= except and e.health and e.health.current > 0 and
            ((e.grid.x == x and e.grid.y == y)
                or (e.motion.remaining > 0 and e.motion.fromX == x and e.motion.fromY == y)) then
            return e
        end
    end
end

function Battle:canLeave(door) return door.open ~= false end

function Battle:walkable(x, y, entity, allowHole)
    if not (allowHole and Rooms.enterable(self.room, x, y) or Rooms.floor(self.room, x, y))
        or self:occupant(x, y, entity) then return false end
    for _, door in ipairs(self.room.doors or {}) do
        if door.x == x and door.y == y then
            return entity == self.player and self:canLeave(door)
        end
    end
    return true
end

function Battle:move(entity, dx, dy, duration, committed)
    if entity.health.current <= 0 or entity.motion.falling
        or math.abs(dx) + math.abs(dy) ~= 1 or (dx ~= 0 and dy ~= 0)
        or entity.motion.remaining > 0 then return false end
    local p, m = entity.grid, entity.motion
    if not self:walkable(p.x + dx, p.y + dy, entity, entity.player or committed) then
        return false
    end
    m.fromX, m.fromY = p.x, p.y
    m.duration = duration or (entity.player and .16 or .24)
    m.remaining = m.duration
    p.x, p.y = p.x + dx, p.y + dy
    m.falling = Rooms.cell(self.room, p.x, p.y).ground == 'hole'
    self:effect('hop', p.x, p.y)
    return true
end

function Battle:cancelCharge()
    local w = self.player.weapon
    w.triggerHeld = false
    if w.state == 'charging' or w.state == 'ready' then
        self:effect('chargeCancel', self.player.grid.x, self.player.grid.y)
        w.state, w.charge = 'empty', 0
    end
end

function Battle:clearIntents()
    local m = self.player.motion
    m.bufferTime, m.blocked = 0, {}
    self:cancelCharge()
    self.player.guard.active = false
end

function Battle:openSecretDoor() return nil end  -- a arena não tem portas

-- O projétil do sistema Projectile — mesma assinatura do game.lua.
-- A guarda de assinatura segue por defesa: quem chama sem entidade real
-- (`shoot(campaign)` da era-turno) morre em silêncio — a flecha nasce do
-- carregamento do arco, nunca de tecla.
function Battle:shoot(entity, dx, dy, damage, interval, range, kind)
    if type(entity) ~= 'table' or not entity.grid or not entity.team then
        return nil
    end
    local e = Concord.entity(self.world):give('grid', entity.grid.x, entity.grid.y)
        :give('team', entity.team.value):give('projectile', dx, dy, damage, interval, range, kind)
    self:effect('fire', e.grid.x, e.grid.y, kind)
    return e
end

-- Dano e morte --------------------------------------------------------------

-- Golpe válido que acerta: efeitos sociais imediatos (§5.1, D08) — desfaz a
-- trégua e zera a conversa — mais a eclosão do casulo que sobrevive (regra
-- portada do modelo de turnos: o golpe é o que acorda o eco).
function Battle:hurt(e)
    if e.mercy or e.calmed then
        e.mercy, e.calmed, e.convince = nil, nil, 0
        self:say('A trégua de ' .. (e.name or 'o encontro') .. ' se desfaz no golpe.')
        if e.enemy.state == 'calmed' then e.enemy.state, e.enemy.timer = 'seek', .3 end
    end
    if e.enemy.kind == 'husk' and e.health.current > 0 then
        local def = Enemies.husk
        if def.hatchFn then
            def.hatchFn(Enemies.helpers, self, e)
            e.replaced = true
        end
    end
end

-- Unidade morta de verdade: sai do mundo, o corpo fica na lista de arena —
-- o renderer lê o estado final; as contagens já não a veem.
function Battle:onEnemyDown(e)
    self:effect('death', e.grid.x, e.grid.y)
    self:say((e.name or 'O encontro') .. ' cai.')
end

-- Rotas letais da jogadora honram o nonLethal do ctx (§5.3): zerar a vida em
-- duelo combinado rende — nunca executa.
function Battle:surrender(e)
    e.health.current = 1
    e.spared, e.spareT = true, 0
    self:say((e.name or 'O encontro') .. ' se rende — duelo encerrado.')
    self:sayBark(e, 'spared')
    e:destroy()
    self.world:emit('flush')
end

function Battle:damage(target, amount, sx, sy, attackKind)
    if self.state ~= 'playing' or not target.health
        or target.health.current <= 0
        or (target.motion and target.motion.falling) then return false end
    if target.npc or target.spared then return false end
    if target.resonator then return Environment.prime(self, target) end
    local hp = target.health
    if target.enemy and target.enemy.frontalArmor then
        local f, p = target.facing, target.grid
        local front = (sx - p.x) * f.dx + (sy - p.y) * f.dy > 0
        local side = (sx - p.x) * f.dy - (sy - p.y) * f.dx
        if front and side == 0 then self:effect('armor', p.x, p.y); return false end
    end
    if target.guard and target.guard.active then
        local g, f, p = target.guard, target.facing, target.grid
        local front = (sx - p.x) * f.dx + (sy - p.y) * f.dy > 0
        local side = (sx - p.x) * f.dy - (sy - p.y) * f.dx
        if front and side == 0 then
            g.energy = math.max(0, g.energy - .3)
            self:effect('block', p.x, p.y)
            if g.pulseCooldown <= 0 then
                g.pulseCooldown = .8
                self:effect('pulse', p.x, p.y)
                for _, e in ipairs(self:entities()) do
                    if e.enemy and e.health.current > 0
                        and math.max(math.abs(e.grid.x - p.x), math.abs(e.grid.y - p.y)) <= 1 then
                        self:damage(e, self.upgrades.guardPulse and 3 or 2, p.x, p.y)
                    end
                end
            end
            if g.energy <= 0 then g.exhausted, g.active = true, false end
            return false
        end
    end
    if hp.immune > 0 then return false end
    if target.enemy and target.enemy.state == 'exposed' then amount = amount + 1 end
    hp.current = math.max(0, hp.current - amount)
    if target.player then hp.immune = .36 end
    self:effect('hit', target.grid.x, target.grid.y, amount)
    if target.enemy then
        self:hurt(target)
        target.shake = {remaining = .22, duration = .22}
    end
    if hp.current == 0 then
        if target.player then
            self.state, self.deathCause = 'dead', 'combat'
            self:clearIntents()
        elseif target.enemy then
            if self:nonLethal(target) then
                self:surrender(target)
            else
                self:onEnemyDown(target)
                target:destroy()
            end
        else
            target:destroy()
        end
    elseif target.enemy then
        self:sayBark(target, 'damage')
    end
    return true
end

function Battle:killFatal(entity, cause)
    if not entity.health or entity.health.current <= 0 then return false end
    entity.health.current, entity.health.cause = 0, cause
    entity.motion.remaining, entity.motion.falling = 0, false
    if entity.player then
        self.deathCause, self.state, self.reward = cause, 'dead', false
        self:clearIntents()
        self:effect('death', entity.grid.x, entity.grid.y, cause)
    elseif entity.enemy then
        if self:nonLethal(entity) then
            self:surrender(entity)
        else
            self:onEnemyDown(entity)
            entity:destroy()
        end
    else
        entity:destroy()
    end
    return true
end

-- E na arena (§5.2): poupar por proximidade. Adjacente a quem baixou a
-- guarda, confirma a retirada — sai do mundo no mesmo tick. Em ambiguidade
-- de adjacência, o calmed mais próximo do centro da jogadora vence.
function Battle:interact()
    if self.dialogue or self.state ~= 'playing' then return false end
    local p = self.player.grid
    local best, bestD
    for _, e in ipairs(self.enemies) do
        if e.health.current > 0 and not e.spared and not e.replaced
            and (e.mercy or e.calmed) then
            local d = math.sqrt((e.grid.x - p.x) ^ 2 + (e.grid.y - p.y) ^ 2)
            if d < 1.5 and (not bestD or d < bestD) then best, bestD = e, d end
        end
    end
    if not best then return false end
    best.spared, best.spareT = true, 0
    best:destroy()
    self.world:emit('flush')   -- sai do mundo no mesmo tick, não no próximo
    self:sayBark(best, 'spared')
    self:effect('talk', best.grid.x, best.grid.y)
    self:checkConclusion(self.campaign)
    return true
end

-- O convencido para na hora — mas o que já foi prometido (warn/dash/volley)
-- resolve: a prévia nunca mente, calmar não cancela o telegrafo em curso.
function Battle:applyCalm(e)
    local a = e.enemy
    if a.state == 'seek' or a.state == 'recover' or a.state == 'retreat'
        or a.state == 'exposed' or a.state == 'dormant' or a.state == 'wait' then
        a.state, a.cells = 'calmed', {}
    end
end

-- Fechamento de fase (COMBATE_MERGE §2.1) -------------------------------------
-- A fase nunca corta um telegrafo: cota cumprida ou timeout apenas PEDEM o
-- fecho; a arena quieta o libera, o respiro sinaliza e o beat abre a pausa.

-- Cota da unidade: a entrada do def sobrescreve a cota do encontro e a do
-- catálogo — "agir" é executar o resolve de um warn, acertando ou não.
function Battle:quotaFor(e)
    return e.quotaLimit or (self.def and self.def.quota)
        or (e.enemy and Enemies[e.enemy.kind] and Enemies[e.enemy.kind].quota)
        or Battle.phaseQuota
end

-- A unidade "já agiu" nesta fase? Cumprir a cota, estagnar sem engajar e
-- estar fora da luta (trégua aceita, sono de casulo) valem igual — quem não
-- vai atacar não pode segurar a rodada.
function Battle:quotaMet(e)
    local a = e.enemy
    if e.stalled or (e.quotaCount or 0) >= self:quotaFor(e) then return true end
    return e.mercy or e.calmed or a.state == 'calmed' or a.state == 'dormant'
end

function Battle:phaseFulfilled()
    for _, e in ipairs(self.enemies) do
        if counted(e) and not self:quotaMet(e) then return false end
    end
    return true
end

-- Arena quieta: nada prometido fica pendurado — sem telegrafo armado, sem
-- projétil em voo, sem marca armada, sem peça caindo, sem corpo no ar.
function Battle:arenaQuiet()
    for _, e in ipairs(self.enemies) do
        local st = e.enemy and e.enemy.state
        if counted(e) and (st == 'warn' or st == 'dash' or st == 'volley') then
            return false
        end
    end
    for _, ent in ipairs(self:entities()) do
        if ent.projectile or ent.hazard or (ent.motion and ent.motion.falling) then
            return false
        end
    end
    for _, tile in pairs(self.room.tiles) do
        if tile.state == 'falling' then return false end
    end
    return true
end

-- Recuo de um passo: longe da jogadora no eixo dominante, depois no outro;
-- com a borda ou peça fechando atrás, cai no primeiro flanco livre — ordem
-- fixa, sem RNG. Depois do passo a unidade encara de novo: respirar não é
-- virar as costas.
function Battle:retreatStep(e)
    local p, t = e.grid, self.player.grid
    local away = {
        {p.x ~= t.x and (p.x > t.x and 1 or -1) or 0, 0},
        {0, p.y ~= t.y and (p.y > t.y and 1 or -1) or 0},
        {1, 0}, {-1, 0}, {0, 1}, {0, -1},
    }
    for _, d in ipairs(away) do
        if (d[1] ~= 0 or d[2] ~= 0) and self:walkable(p.x + d[1], p.y + d[2], e) then
            self:move(e, d[1], d[2], .22)
            local dx, dy = t.x - e.grid.x, t.y - e.grid.y
            if math.abs(dx) >= math.abs(dy) then
                e.facing.dx, e.facing.dy = dx >= 0 and 1 or -1, 0
            else
                e.facing.dx, e.facing.dy = 0, dy >= 0 and 1 or -1
            end
            return true
        end
    end
    return false
end

-- Quiet + pedido = respiro: quem cumpriu recua um passo e segura em 'wait'
-- (o indicador visual do fim de fase); quem ficou devendo — timeout, fase
-- estourada — segue na máquina normal.
function Battle:enterBeat()
    for _, e in ipairs(self.enemies) do
        local a = e.enemy
        if a and counted(e) and self:quotaMet(e)
            and not (e.mercy or e.calmed or a.state == 'calmed' or a.state == 'dormant') then
            self:retreatStep(e)
            a.state, a.timer, a.cells = 'wait', 0, {}
            e.resting = true
        end
    end
    self.beat = Battle.beatTime
end

-- A pausa abre (§3): a carga do arco cancela — o gesto não atravessa o
-- congelamento — o palco fala e o menu de postura nasce em CONTINUAR. Um
-- beat armado (§7) substitui o menu pelo diálogo do falante: a avaliação
-- dos gatilhos acontece depois de decidir a pausa e antes de montar o menu.
function Battle:enterPause(campaign)
    self.phase, self.closing, self.beat = 'pause', false, nil
    self.phaseClock = 0
    self.round = self.round + 1       -- semente nova para os barks entre rodadas
    self:cancelCharge()
    self.mode, self.menuIndex = 'menu', 1
    self.actIndex, self.actTarget, self.useIndex, self.mercyIndex = 1, 1, 1, 1
    self:evalBeats('pause')
    if self.beatQueue[1] then
        self:pumpBeats(campaign)
        if self.beatOpen then return end
    end
    local stage = self:liveEnemies()[1]
    if stage then self:sayBark(stage, 'announce') end
    -- §5.4: a cara do palco acompanha a fala de abertura da rodada — mesmo
    -- quando o bark não tem linha, o retrato relê o estado social.
    self.stageEmotion = stage and self:emotionFor(stage) or nil
end

-- A escolha da jogadora fecha a pausa (§3): relógio e cotas zeram, quem
-- respirava solta o 'wait' e volta à caça — a ação recomeça limpa.
function Battle:resumeAction()
    self.phase, self.mode = 'action', 'action'
    self.phaseClock, self.closing, self.beat = 0, false, nil
    self.menuIndex, self.actIndex, self.actTarget = 1, 1, 1
    self.useIndex, self.mercyIndex = 1, 1
    for _, e in ipairs(self.enemies) do
        e.quotaCount, e.stallClock, e.stalled, e.resting = 0, 0, nil, nil
        local a = e.enemy
        -- O convencido não acorda para caçar: quem baixou a guarda durante a
        -- pausa sai do respiro direto para 'calmed', nunca para 'seek'.
        if a and a.state == 'wait' then
            if e.calmed then a.state, a.cells = 'calmed', {}
            else a.state, a.timer = 'seek', .15 end
        end
    end
end

-- Fuga — a micro-fase de ação (COMBATE_MERGE §6) --------------------------
-- FUGIR não é botão de saída: abre uma travessia corporal sob a volley de
-- despedida. Sem RNG: a borda é determinística, a falha é legível.

-- A saída acende na borda oposta à metade onde a jogadora está. Regra
-- determinística: a borda mais próxima dela define "o lado" — a saída abre
-- na oposta; desempate de distância igual prefere a horizontal (o
-- tabuleiro é largo), depois norte sobre sul. Na borda escolhida vence a
-- célula livre mais próxima da linha/coluna da jogadora — desempate para o
-- índice menor (norte/oeste primeiro); borda inteira vedada recua coluna
-- a coluna (fileira a fileira) para dentro até achar uma livre.
function Battle:fleeExit()
    local minX, maxX, minY, maxY
    for _, cell in pairs(self.room.tiles) do
        if cell.ground == 'floor' then
            minX = math.min(minX or cell.x, cell.x)
            maxX = math.max(maxX or cell.x, cell.x)
            minY = math.min(minY or cell.y, cell.y)
            maxY = math.max(maxY or cell.y, cell.y)
        end
    end
    if not minX then return nil, nil end
    local p = self.player.grid
    local dw, de = p.x - minX, maxX - p.x
    local dn, ds = p.y - minY, maxY - p.y
    local dmin = math.min(dw, de, dn, ds)
    -- o lado é onde ela está mais perto; a saída é o lado oposto
    local edge = (dmin == dw or dmin == de)
        and (dmin == dw and 'east' or 'west')
        or (dmin == dn and 'south' or 'north')
    if edge == 'east' or edge == 'west' then
        local step = edge == 'east' and -1 or 1
        for x = (edge == 'east' and maxX or minX),
            (edge == 'east' and minX or maxX), step do
            local best, bd
            for y = minY, maxY do
                if self:free(x, y) then
                    local d = math.abs(y - p.y)
                    if not bd or d < bd then best, bd = {x = x, y = y}, d end
                end
            end
            if best then return edge, best end
        end
    else
        local step = edge == 'south' and -1 or 1
        for y = (edge == 'south' and maxY or minY),
            (edge == 'south' and minY or maxY), step do
            local best, bd
            for x = minX, maxX do
                if self:free(x, y) then
                    local d = math.abs(x - p.x)
                    if not bd or d < bd then best, bd = {x = x, y = y}, d end
                end
            end
            if best then return edge, best end
        end
    end
    return edge, nil
end

-- A unidade deve a despedida? Hostil viva que ainda não telegrafou: o
-- telegrafo já armado (warn/dash/volley) É a investida final dela — a
-- promessa resolve normal, sem segunda rodada de cortesia.
local function owesVolley(e)
    local a = e.enemy
    return a ~= nil and counted(e) and not (e.mercy or e.calmed)
        and a.state ~= 'calmed' and a.state ~= 'dormant'
end

function Battle:startFlee(campaign)
    -- Solta o respiro e zera as cotas — a travessia é fase de ação com a
    -- regra própria de fechamento, não a saída instantânea de antes.
    self:resumeAction()
    local edge, cell = self:fleeExit()
    self.fleeing = true
    self.flee = {edge = edge, participants = 0}
    self.exitCell = cell
    for _, e in ipairs(self.enemies) do
        if e.enemy and owesVolley(e) then
            self.flee.participants = self.flee.participants + 1
            local st = e.enemy.state
            if st == 'warn' or st == 'dash' or st == 'volley' then
                -- Telegrafo já armado É a despedida — resolve normal e a
                -- unidade segura depois, como quem acabou de quitar.
                e.volleyDone = true
            else
                -- A máquina dispara a despedida como engajar imediato: a
                -- saída honesta por kind (provokedEngage) quando o gatilho
                -- natural falha; corpo a corpo sem saída avança e a
                -- investida fica pendente até o primeiro warn real.
                e.volleyPending = true
            end
        end
    end
    if cell then
        self:say('Uma saída acende na borda oposta — a arena revida uma última vez.')
        self:effect('warn', cell.x, cell.y)
    else
        self:say('Nenhuma saída se abre — a arena revida uma última vez.')
    end
    self:blip(campaign, 1.0)
end

-- Beats de conversa (COMBATE_MERGE §7) ---------------------------------------
-- def.beats (encontro) ou kind.beats (role) declaram gatilhos; cada entrada
-- armada entra em beatQueue na ordem de escrita e substitui o menu da pausa
-- pelo diálogo do falante. Os gatilhos avaliam em três momentos: 'start' na
-- abertura, 'pause' no fechamento de cada fase de ação (round/hpBelow/
-- passiveFor caem aqui por segurança) e 'tick' a cada quadro da ação
-- (hpBelow cruza no mesmo tick do dano; passiveFor lê o relógio contínuo).
-- 'mercy' e 'bossPhase' armam no evento, com `owner` = a unidade que baixou
-- a guarda ou rompeu o selo.

-- Normaliza os gatilhos: entradas do def primeiro (a linha autoral do
-- encontro tem prioridade), depois u.beats da entrada de unidade e os beats
-- do kind — ROLES antes, catálogo Enemies via rawget (o def derivado não
-- herda as falas da família que veste). `once` marca e.beatFired[i] nas de
-- unidade e self.beatFired[i] nas do encontro — o índice é o da lista
-- normalizada, estável como a ordem de escrita.
function Battle:buildBeats(units)
    self.beats, self.beatQueue, self.beatFired = {}, {}, {}
    self.passiveClock = 0
    local function add(list, unit, mark)
        for _, b in ipairs(list or {}) do
            self.beats[#self.beats + 1] =
                {beat = b, unit = unit, mark = mark, key = #self.beats + 1}
        end
    end
    add(self.def and self.def.beats, nil, self.beatFired)
    for i, e in ipairs(self.enemies) do
        e.beatFired = {}
        local u = units[i] or {}
        local role = ROLES[e.enemy.kind] or {}
        local cat = e.enemy.kind and Enemies[e.enemy.kind]
        add(u.beats, e, e.beatFired)
        add(role.beats, e, e.beatFired)
        if cat then add(rawget(cat, 'beats'), e, e.beatFired) end
    end
end

function Battle:verbal(e)
    return e.enemy and Barks.kind(e.enemy.kind).verbal ~= false
end

-- O falante de um beat (§11): `beat.speaker` declarado (índice da lista de
-- unidades, kind ou entidade) > unidade marcada `u.speaker` no def > a
-- unidade dona do gatilho quando ela fala > o primeiro verbal vivo na
-- ordem do def. Encontro misto sem falante vivo: sem beat.
function Battle:speakerFor(beat, owner)
    local function live(e) return e and counted(e) end
    local s = beat.speaker
    if type(s) == 'number' and live(self.enemies[s]) then return self.enemies[s] end
    if type(s) == 'string' then
        for _, e in ipairs(self.enemies) do
            if live(e) and e.enemy.kind == s then return e end
        end
    end
    if type(s) == 'table' and live(s) then return s end
    for _, e in ipairs(self.enemies) do
        if live(e) and e.speaker then return e end
    end
    if owner and live(owner) and self:verbal(owner) then return owner end
    for _, e in ipairs(self.enemies) do
        if live(e) and self:verbal(e) then return e end
    end
    return nil
end

-- Avalia os gatilhos do escopo e enfileira os que disparam, na ordem de
-- escrita. `owner` delimita os gatilhos de unidade ('mercy'/'bossPhase'): só
-- os beats daquela unidade — ou os de encontro — podem armar. hpBelow pesa
-- sobre a dona do gatilho (ou sobre o falante resolvido, nos de encontro) e
-- exige viva: morto não fala nem no tick da queda.
function Battle:evalBeats(scope, owner)
    if self.over or not self.beats then return end
    for i, entry in ipairs(self.beats) do
        if not entry.armed and not entry.mark[entry.key] then
            local w, hit = entry.beat.when, false
            if w == 'start' then
                hit = scope == 'start'
            elseif w == 'mercy' or w == 'bossPhase' then
                hit = scope == w and owner ~= nil
                    and (entry.unit == nil or entry.unit == owner)
            elseif type(w) == 'table' then
                if w.round then
                    hit = scope == 'pause' and self.round == w.round
                elseif w.hpBelow then
                    hit = scope == 'tick' or scope == 'pause'
                    local subj = entry.unit
                    if hit and subj then
                        hit = subj.health.current > 0
                            and subj.health.current <= subj.health.max * w.hpBelow
                    end
                elseif w.passiveFor then
                    hit = (scope == 'tick' or scope == 'pause')
                        and (self.passiveClock or 0) >= w.passiveFor
                end
            end
            if hit then
                local speaker = self:speakerFor(entry.beat, owner or entry.unit)
                if speaker and type(w) == 'table' and w.hpBelow
                    and not entry.unit then
                    hit = speaker.health.current > 0
                        and speaker.health.current <= speaker.health.max * w.hpBelow
                end
                if hit and speaker then
                    entry.armed = true
                    self.beatQueue[#self.beatQueue + 1] = {unit = speaker,
                        node = entry.beat.node, ref = i, now = scope == 'start'}
                end
            end
        end
    end
end

-- O node de um beat: a namespace de batalha (src/battle_talks) manda; ids que
-- o Pena já publicou nos talks de encontro servem de fallback — mesma
-- gramática de escrita, mesmo Dialogue.open.
function Battle:beatNode(id)
    local node = Talks.nodes and Talks.nodes[id]
    if node then return node end
    if LoreC.talk then return LoreC.talk(self.campaign, id) end
end

-- Drena a fila: o próximo falante vivo com node válido abre o diálogo (uma
-- fala por vez — campaign.dialogue já congela o resto). Beats de 'start'
-- abrem a qualquer momento; os demais esperam a pausa quiet — nunca cortam
-- telegrafo. Fila esvaziada na pausa devolve o menu de postura.
function Battle:pumpBeats(campaign)
    if self.over or self.state ~= 'playing' then return end
    if campaign.dialogue or #self:liveEnemies() == 0 then return end
    while self.beatQueue[1] do
        local q = self.beatQueue[1]
        if not q.now and self.phase ~= 'pause' then break end
        table.remove(self.beatQueue, 1)
        local entry = self.beats[q.ref]
        if entry then entry.armed = nil end
        local e = q.unit
        if e and counted(e) then
            local node = self:beatNode(q.node)
            if node then
                if entry and entry.beat.once then entry.mark[entry.key] = true end
                self.beatSpeaker, self.beatOpen = e, true
                self.stageEmotion = self:emotionFor(e)
                if self.phase == 'pause' then self.mode = 'beat' end
                Dialogue.open(campaign, node)
                return
            end
        end
    end
    self.beatSpeaker = nil
    -- Esvaziou → menu da pausa normal (§3), com a emoção do palco relida.
    if self.phase == 'pause' and self.mode == 'beat' then
        self.mode, self.menuIndex = 'menu', 1
        self.actIndex, self.actTarget, self.useIndex, self.mercyIndex = 1, 1, 1, 1
        local stage = self:liveEnemies()[1]
        self.stageEmotion = stage and self:emotionFor(stage) or nil
    end
end

-- Conclusão ----------------------------------------------------------------

-- Avalia os fechos imediatos: jogadora a zero segue a morte da campanha;
-- arena vazia conclui 'won' ou 'negotiated' sem passar por fase alguma.
function Battle:checkConclusion(campaign)
    campaign = campaign or self.campaign
    if self.over then return true end
    if self.player.health.current <= 0 then
        self.over = true
        self.state = 'dead'
        self:clearIntents()
        campaign:die('batalha')
        return true
    end
    if #self:liveEnemies() == 0 then
        self.over = true
        self.phase = 'done'
        local negotiated = self:outcome() == 'negotiated'
        campaign:endBattle(negotiated and 'negotiated' or 'won')
        campaign:notify(negotiated
            and 'O confronto se encerra sem quedas. O caminho está livre.'
            or ((self:firstFallenName() or 'O confronto')
                .. ' cai. O caminho está livre.'))
        return true
    end
    return false
end

-- Nome legado do mesmo fecho — sobrevive para os call sites antigos.
function Battle:conclude(campaign)
    return self:checkConclusion(campaign)
end

-- Social (sobreviventes do modelo de turnos — COMBATE_MERGE §8) --------------

-- Consumíveis que entram no submenu USAR: em estoque, declarados utilizáveis
-- em batalha pelo catálogo. Ordenados por id — a lista é estável como o
-- resto da arena.
function Battle:useItems()
    local list = {}
    for id, qty in pairs(self.items) do
        local def = Items.def(id)
        if def and def.cat == 'consumivel' and qty > 0
            and Items.usableInBattle(id) then
            list[#list + 1] = {id = id, label = def.label, qty = qty,
                desc = def.desc}
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- O menu da pausa (§3): postura e conversa — atacar é do corpo e fica fora
-- daqui. CONTINUAR é o default honesto: um toque de ENTER volta à luta.
function Battle:menuItems()
    local items = {
        {id = 'continue', label = 'CONTINUAR', desc = 'Volta à luta.'},
        {id = 'act', label = 'AGIR', desc = 'Ler, propor ou provocar — escolha o alvo.',
            disabled = #self:liveEnemies() == 0 and 'Ninguém resta para agir.'},
        {id = 'use', label = 'USAR', desc = 'Consome um item da bolsa.',
            disabled = #self:useItems() == 0 and 'Nada para usar.'},
        {id = 'mercy', label = 'POUPAR',
            desc = 'Aceita a retirada de quem baixou a guarda.',
            disabled = not self:spareable()[1] and 'Ninguém baixou a guarda ainda.'},
        {id = 'flee', label = 'FUGIR', desc = 'Retira-se. O encontro fica pendente.'},
    }
    return items
end

function Battle:blip(campaign, pitch)
    -- Um canal por cue: o blip de menu sai só pelo Sfx (Contraponto F2).
    Sfx.play('ui_move', {pitch = pitch or 1, volume = .4})
end

function Battle:choose(item, campaign)
    if not item then return true end
    if item.disabled then
        self:say(item.disabled)
        self:blip(campaign, .7)
        return true
    end
    if item.id == 'continue' then
        self:resumeAction()
        self:blip(campaign, 1.1)
        return true
    end
    if item.id == 'act' then
        if #self:liveEnemies() == 0 then
            self:say('Ninguém resta para agir.')
            return true
        end
        self.mode, self.actTarget = 'act', 1
        self:blip(campaign, 1.2)
        return true
    end
    if item.id == 'use' then
        if #self:useItems() == 0 then
            self:say('Nada para usar.')
            return true
        end
        self.mode, self.useIndex = 'use', 1
        self:blip(campaign, 1.2)
        return true
    end
    if item.id == 'mercy' then
        if #self:spareable() == 0 then
            self:say('Ninguém baixou a guarda ainda.')
            return true
        end
        self.mode, self.mercyIndex = 'mercy', 1
        self:blip(campaign, 1.2)
        return true
    end
    if item.id == 'flee' then
        -- §6: FUGIR abre a micro-fase — a saída acende na borda oposta e a
        -- volley de despedida arma; o pick do menu já foi gasto.
        self:startFlee(campaign)
        return true
    end
    return true
end

-- USAR: consome um item da campanha. Uma provisão com a vida cheia recusa
-- sem gastar nada — o item só sai da bolsa quando faz efeito.
function Battle:useConsumable(id, campaign)
    if self.player.health.current <= 0 then return false end
    local def = Items.def(id)
    if not def or not Items.usableInBattle(id)
        or (self.items[id] or 0) <= 0 then return false end
    local h = self.player.health
    if def.battle and def.battle.heal and h.current >= h.max then
        self:say('A vida já está cheia — a provisão fica na bolsa.')
        self:blip(campaign, .7)
        return false
    end
    if not campaign:useItem(id) then return false end
    if def.battle and def.battle.heal then
        h.current = math.min(h.max, h.current + def.battle.heal)
        campaign:effect('reward', self.player.grid.x, self.player.grid.y)
        self:say(def.label .. ': +' .. def.battle.heal .. ' de vida.')
    end
    return true
end

function Battle:actItems(e)
    local kdef = Barks.kind(e.enemy.kind)
    local items = {}
    for _, a in ipairs(Barks.acts(e.enemy.kind, e.ctx) or {}) do
        local refused = (kdef.refuses and kdef.refuses[a.id])
            or (a.id ~= 'observar' and not kdef.negotiates) or nil
        local need = ACT_ITEM[a.id]
        local missing = need and not self.campaign:hasItem(need) and need or nil
        local live = LIVE_ACT[e.enemy.kind] and LIVE_ACT[e.enemy.kind][a.id]
        local disabled
        if a.proposal and not live then
            disabled = 'O gesto ainda não pega — a mecânica dele não existe.'
        elseif missing then
            local d = Items.def(missing)
            disabled = 'Precisa de ' .. ((d and d.label) or 'item') .. '.'
        end
        items[#items + 1] = {id = a.id, label = a.label, desc = a.desc,
            proposal = a.proposal or nil, refused = refused,
            disabled = disabled}
    end
    return items
end

-- Confirma um ACT sobre o alvo. Sem fase de turno: o efeito é imediato —
-- convencer no limiar baixa a guarda na hora (§5.1); gestos recusados e o
-- OBSERVAR só gastam o tempo de quem lê.
function Battle:actOn(e, item, campaign)
    if not item then return true end
    if not e or e.health.current <= 0 or e.spared or e.replaced then
        self.mode = 'action'
        return true
    end
    if item.disabled then
        self:say(item.disabled)
        self:blip(campaign, .7)
        return true
    end
    local kind = e.enemy.kind
    local kdef = Barks.kind(kind)
    local live = LIVE_ACT[kind] and LIVE_ACT[kind][item.id]
    -- Proposal sem mecânica própria: mesmo chamada direta não pega —
    -- o submenu é a porta, mas a regra não depende dele.
    if item.proposal and not live then
        self:say('O gesto ainda não pega — a mecânica dele não existe.')
        self:blip(campaign, .7)
        return true
    end
    if live then
        -- Gestos com mecânica real-time: a vela apagada baixa a guarda do
        -- vigia, o embalo recoloca a eclosão no teto, a despedida pesa como
        -- convencimento — mesmo caminho dos demais ACTs.
        self:sayActBark(e, item.id)
        if item.id == 'vela' then
            e.candle = nil
            e.calmed = true
            self:applyCalm(e)
            self:evalBeats('mercy', e)
        elseif item.id == 'embalar' then
            local a = e.enemy
            if a.state == 'dormant' then a.timer = a.hatchTime or 3.5 end
        elseif item.id == 'despedida' then
            e.convince = (e.convince or 0) + 1
            if not e.mercy and e.convince
                >= (e.convinceNeeded or Battle.convinceNeeded) then
                e.mercy, e.calmed = true, true
                self:applyCalm(e)
                self:sayBark(e, 'convinced')
                self:evalBeats('mercy', e)
            elseif not e.mercy then
                self:sayFlavor('almostConvinced', e)
            end
        end
        self:blip(campaign, 1.25)
        return self:conclude(campaign)
    end
    local refused = (kdef.refuses and kdef.refuses[item.id])
        or (item.id ~= 'observar' and not kdef.negotiates)
    if refused then
        self:sayRefusal(e, item.id)
        self:blip(campaign, .7)
        return true
    end
    if item.id == 'observar' then
        for _, line in ipairs(Barks.check(kind, e.ctx) or {}) do self:say(line) end
        self:sayActBark(e, item.id)
        self:blip(campaign, 1.1)
        return true
    end
    self:sayActBark(e, item.id)
    if item.id == 'provocar' then
        -- A isca fica armada na unidade (§5.1): a máquina Enemies força o
        -- próximo engajar no primeiro gatilho disponível, com warn ×
        -- Battle.provokeWarnFactor, e consome a flag no anúncio.
        e.provoked = true
    elseif kdef.negotiates then
        e.convince = (e.convince or 0) + 1
        if not e.mercy and e.convince >= (e.convinceNeeded or Battle.convinceNeeded) then
            e.mercy, e.calmed = true, true
            self:applyCalm(e)
            self:sayBark(e, 'convinced')
            self:evalBeats('mercy', e)
        elseif not e.mercy then
            self:sayFlavor('almostConvinced', e)
        end
    end
    self:blip(campaign, 1.25)
    return self:conclude(campaign)
end

-- Mercy pela distância do menu: cobre quem baixou a guarda sem exigir a
-- travessia — a rota corporal é o E por proximidade (§5.2).
function Battle:spare(e, campaign)
    if not e or e.spared or e.health.current <= 0 or e.replaced
        or not (e.mercy or e.calmed) then return false end
    e.spared, e.spareT = true, 0
    e:destroy()
    self.world:emit('flush')
    self:sayBark(e, 'spared')
    self:checkConclusion(campaign)
    return true
end

-- Barks: deterministic variant per round — readable in tests, no new RNG.
local function pick(list, seed)
    if not list or #list == 0 then return nil end
    return list[((seed - 1) % #list) + 1]
end

function Battle:sayBark(e, situation)
    local line = pick(Barks.bark(e.enemy.kind, situation, e.ctx or self.ctx),
        self.round)
    if line then
        self:say(line)
        -- Balão de fala: dado de apresentação — verbal=false vira gesto
        -- entre parênteses no renderer, sem mudar a fala.
        e.barkText, e.barkT = line, 2.8
        e.barkVerbal = Barks.kind(e.enemy.kind).verbal ~= false
        -- §5.4: quem fala é o palco — o retrato emocional acompanha a voz.
        self.stageEmotion = self:emotionFor(e)
        if e.barkVerbal then
            Sfx.play('bark', {pitch = Sfx.voice(e.enemy.kind), volume = .45})
        else
            Sfx.play('gesture', {volume = .35})
        end
    end
end

function Battle:sayActBark(e, actId)
    local line = pick(Barks.actBark(e.enemy.kind, actId, e.ctx or self.ctx),
        self.round)
    if line then
        self:say(line)
        e.barkText, e.barkT = line, 2.8
        e.barkVerbal = Barks.kind(e.enemy.kind).verbal ~= false
        if e.barkVerbal then
            Sfx.play('bark', {pitch = Sfx.voice(e.enemy.kind), volume = .45})
        else
            Sfx.play('gesture', {volume = .35})
        end
    end
end

function Battle:sayRefusal(e, actId)
    local line = pick(Barks.refusal(e.enemy.kind, actId, e.ctx or self.ctx),
        self.round)
    if line then
        self:say(line)
        e.barkText, e.barkT = line, 2.8
        e.barkVerbal = Barks.kind(e.enemy.kind).verbal ~= false
        if e.barkVerbal then
            Sfx.play('bark', {pitch = Sfx.voice(e.enemy.kind), volume = .45})
        else
            Sfx.play('gesture', {volume = .35})
        end
    end
end

function Battle:sayFlavor(situation, e)
    local line = pick(Barks.flavor[situation], self.round)
    if not line then return end
    if e then line = (line:gsub('%%s', e.name)) end
    self:say(line)
end

-- Input ---------------------------------------------------------------------

-- Rota de input da pausa (§3): a navegação era-turno inteira — WASD cicla,
-- ENTER/E confirma, ESC desce um nível. No menu raiz, ESC é CONTINUAR: o
-- mesmo custo de um toque para voltar à luta.
function Battle:key(key, campaign)
    -- Fase de ação: NENHUMA tecla é consumida — WASD/ESPAÇO/SHIFT fluem
    -- para input:pressed e viram eventos do frame; ESC sobe ao dispatcher
    -- e abre a pausa da campanha (COMBATE_MERGE §8/§11). Exceção da
    -- micro-fase de fuga: ESC é desistir — a jogadora fica, a ação segue.
    if self.phase == 'action' then
        if self.fleeing and key == 'escape' then
            self.fleeing, self.exitCell, self.flee = nil, nil, nil
            for _, e in ipairs(self.enemies) do
                e.volleyPending, e.volleyDone, e.resting = nil, nil, nil
            end
            self:say('Você fica — a saída se apaga.')
            self:blip(campaign, .9)
            return true
        end
        return false
    end
    if self.phase ~= 'pause' or self.over then return true end
    -- Fora da ação, TUDO é engolido: uma tecla de menu nunca vaza para o
    -- frame da simulação congelada.
    local NAV = {w = -1, a = -1, s = 1, d = 1}
    local function cycle(idx, n) return ((idx - 1 + NAV[key]) % n) + 1 end
    if key == 'escape' then
        if self.mode == 'actlist' then self.mode, self.actIndex = 'act', 1
        elseif self.mode == 'act' or self.mode == 'use' or self.mode == 'mercy' then
            self.mode = 'menu'
        else
            self:resumeAction()
            self:blip(campaign, 1.1)
            return true
        end
        self:blip(campaign, .9)
        return true
    end
    local confirm = key == 'return' or key == 'e'
    if self.mode == 'menu' then
        local items = self:menuItems()
        if NAV[key] then
            self.menuIndex = cycle(self.menuIndex, #items)
            self:blip(campaign)
        elseif confirm then
            self:choose(items[self.menuIndex], campaign)
        end
    elseif self.mode == 'act' then
        local targets = self:liveEnemies()
        if #targets == 0 then self.mode = 'menu'
        elseif NAV[key] then
            self.actTarget = cycle(self.actTarget, #targets)
            self:blip(campaign)
        elseif confirm then
            self.mode, self.actIndex = 'actlist', 1
            self:blip(campaign, 1.15)
        end
    elseif self.mode == 'actlist' then
        local target = self:liveEnemies()[self.actTarget]
        if not target then self.mode = 'act'
        else
            local items = self:actItems(target)
            if NAV[key] then
                self.actIndex = cycle(self.actIndex, #items)
                self:blip(campaign)
            elseif confirm then
                local item = items[self.actIndex]
                -- OBSERVAR, recusas e gestos travados são consulta grátis —
                -- a pausa só fecha quando um gesto real é aplicado (§3).
                local free = not item or item.disabled or item.refused
                    or item.id == 'observar'
                self:actOn(target, item, campaign)
                if not free and not self.over and self.phase == 'pause' then
                    self:resumeAction()
                end
            end
        end
    elseif self.mode == 'use' then
        local items = self:useItems()
        if #items == 0 then self.mode = 'menu'
        elseif NAV[key] then
            self.useIndex = cycle(self.useIndex, #items)
            self:blip(campaign)
        elseif confirm then
            if self:useConsumable(items[self.useIndex].id, campaign)
                and not self.over then
                self:resumeAction()
            end
        end
    elseif self.mode == 'mercy' then
        local list = self:spareable()
        if #list == 0 then self.mode = 'menu'
        elseif NAV[key] then
            self.mercyIndex = cycle(self.mercyIndex, #list)
            self:blip(campaign)
        elseif confirm then
            if self:spare(list[self.mercyIndex], campaign) and not self.over then
                self:resumeAction()
            end
        end
    end
    return true
end

-- Update -------------------------------------------------------------------

-- A fase de ação é o protótipo dentro da campanha: o mundo Concord emite
-- update e os sistemas decidem tudo. Qualquer congelamento sai no primeiro
-- teste — diálogo, pausa ou fase não-ação seguram o quadro inteiro
-- (COMBATE_MERGE §3/§11), inclusive o projétil já em voo.
function Battle:update(dt, campaign, input)
    self.dialogue = campaign.dialogue
    if self.over then return end
    -- §7: a fala de um beat fechou (ou esperava diálogo livre) — a fila abre
    -- a próxima na mesma ordem; esvaziada, a pausa cai no menu de postura.
    if not self.dialogue and self.beatQueue
        and (self.beatOpen or (self.beatQueue[1]
            and (self.phase == 'pause' or self.beatQueue[1].now))) then
        self.beatOpen = nil
        self:pumpBeats(campaign)
        self.dialogue = campaign.dialogue
    end
    -- A morte da jogadora resolve pelo fluxo da campanha mesmo com a arena
    -- congelada — hp 0 nunca fica pendurado esperando o diálogo fechar.
    if self.state == 'dead' or self.player.health.current <= 0 then
        self:checkConclusion(campaign)
        return
    end
    if self.dialogue or self.phase ~= 'action' then return end
    self.time = self.time + dt
    self.phaseClock = self.phaseClock + dt
    self.messageTime = math.max(0, self.messageTime - dt)
    self.input = input or {dx = 0, dy = 0, guard = false, events = {}}
    -- pickaxes espelha a picareta real da bolsa (§8): a mineração da arena
    -- gasta o item da campanha e o gasto volta para o save.
    self.pickaxes = campaign.data.items.picareta or 0
    self.world:emit('update', dt)
    if (campaign.data.items.picareta or 0) ~= self.pickaxes then
        campaign.data.items.picareta = self.pickaxes > 0 and self.pickaxes or nil
    end
    -- Relógios de apresentação + marcação de substituídos (casulo eclodido
    -- sai do mundo com a vida intacta — nunca conta como queda nem poupo).
    for _, e in ipairs(self.enemies) do
        if e.health.current > 0 and not e.spared and not e.replaced
            and not e:inWorld() then
            e.replaced = true
        end
        local a = e.enemy
        if a then
            -- Cota (§2): a saída de 'warn' é o resolve executado — whiff
            -- conta igual, e a rajada dupla do veterano segue UM golpe
            -- ('volley' é continuação do mesmo resolve, não um novo warn).
            local prev = a.wasState
            a.wasState = a.state
            if counted(e) then
                if prev == 'warn' and a.state ~= 'warn' then
                    e.quotaCount = (e.quotaCount or 0) + 1
                    -- §6: o warn que resolve quita a despedida — a rajada
                    -- do veterano ('volley' é continuação) segue normal.
                    if e.volleyPending then e.volleyPending, e.volleyDone = nil, true end
                end
                -- Anti-stall (§2): tempo em 'seek' sem conseguir engajar
                -- acumula; quem não encontra passo conta como agiu.
                if a.state == 'seek' then
                    e.stallClock = (e.stallClock or 0) + dt
                    if not e.stalled and e.stallClock > Battle.stallLimit then
                        e.stalled = true
                        -- §6: quem nunca achou passo não desfere a
                        -- despedida — a investida pendente prescreve.
                        e.volleyPending = nil
                        self:say((e.name or 'O encontro') .. ' não encontra passo.')
                    end
                else
                    e.stallClock = 0
                end
            end
        end
        -- O convencido continua parado — e um telegrafo já armado segue a
        -- própria máquina até o fim (o calmed só trava estados ociosos).
        if e.calmed then self:applyCalm(e) end
        -- §6: quem já despediu segura em 'wait' enquanto a travessia
        -- decide — a investida final é o último gesto; a fuga morrendo,
        -- o resting cai e a máquina devolve a caça.
        if self.fleeing and e.volleyDone and counted(e) and a
            and (a.state == 'seek' or a.state == 'recover'
                or a.state == 'retreat' or a.state == 'exposed') then
            a.state, a.cells = 'wait', {}
            e.resting = true
        end
        if e.shake then e.shake.remaining = math.max(0, e.shake.remaining - dt) end
        if e.lunge then e.lunge.remaining = math.max(0, e.lunge.remaining - dt) end
        if e.barkT then
            e.barkT = math.max(0, e.barkT - dt)
            if e.barkT == 0 then e.barkText = nil end
        end
        if e.spareT then e.spareT = math.min(1.4, e.spareT + dt) end
        if e.shoveT then e.shoveT = math.max(0, e.shoveT - dt) end
    end
    local p = self.player
    if p.shake then p.shake.remaining = math.max(0, p.shake.remaining - dt) end
    if p.lunge then p.lunge.remaining = math.max(0, p.lunge.remaining - dt) end
    -- §7: passiveFor — segundos acumulados sem a jogadora atacar. Empunhar
    -- (charge/ready), o recuo pós-disparo e os eventos charge/fire zeram o
    -- relógio: a rota "só desviar" é a que o gatilho premia.
    local attacked = p.weapon and p.weapon.state ~= 'empty'
    if not attacked then
        for _, ev in ipairs(self.input.events or {}) do
            if ev.kind == 'charge' or ev.kind == 'fire' then attacked = true break end
        end
    end
    self.passiveClock = attacked and 0 or (self.passiveClock or 0) + dt
    -- §7: hpBelow cruza no mesmo tick do dano — a varredura roda depois dos
    -- sistemas, e quem caiu neste quadro já não satisfaz a exigência de viva.
    self:evalBeats('tick')
    -- §6 — micro-fase de fuga: pisar na saída encerra a arena em 'return';
    -- a volley fechar sem ela na saída falha a fuga e a ação segue (o pick
    -- do menu foi gasto — a próxima pausa vem da cota normal). Enquanto a
    -- travessia corre, a cota de fase não pede fechamento: a fuga é a sua
    -- própria regra de encerrar.
    if self.fleeing and self.state == 'playing' then
        -- A morte ganha da saída no mesmo quadro — a travessia só fecha se
        -- a jogadora chegar viva.
        local exit = self.exitCell
        if exit and p.grid.x == exit.x and p.grid.y == exit.y
            and p.motion.remaining == 0 then
            self.over = true
            self:say('Você cruza a saída — a arena fica para trás.')
            campaign:endBattle('return')
            return
        end
        local owed = false
        for _, e in ipairs(self.enemies) do
            if e.volleyPending and e.enemy and owesVolley(e) then
                owed = true break
            end
        end
        -- Sem participantes a fuga não tem réu: fica aberta até a saída
        -- ou até o ESC — ninguém se opõe à retirada de quem acalmou todos.
        if not owed and self.flee.participants > 0 and self:arenaQuiet() then
            self.fleeing, self.exitCell = nil, nil
            for _, e in ipairs(self.enemies) do
                -- Quem segurou a despedida volta à caça — resting solta o
                -- 'wait' pela própria máquina no próximo tick.
                e.volleyPending, e.volleyDone, e.resting = nil, nil, nil
            end
            self:say('A saída fecha.')
        end
    end
    -- Fechamento da fase (§2.1): cota cumprida em todas as unidades vivas do
    -- def ou o timeout pedem o fecho. A arena quieta libera o respiro; o beat
    -- de ~.4s com todos segurando abre a pausa — e um diálogo congela cada
    -- um desses relógios junto com o mundo (retorno cedo, acima).
    if not self.closing and not self.fleeing then
        if self.phaseClock > Battle.phaseTimeout or self:phaseFulfilled() then
            self.closing = true
        end
    end
    if self.closing and not self.beat and self:arenaQuiet() then
        self:enterBeat()
    end
    if self.beat then
        self.beat = self.beat - dt
        if self.beat <= 0 then self:enterPause(campaign) end
    end
    self:checkConclusion(campaign)
end

return Battle
