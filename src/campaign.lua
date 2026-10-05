-- Campaign session for "A Cidade Que Me Enterrou". The campaign owns the
-- persistent state (flags, steps, people, per-region changes), the authored
-- map currently loaded, and the explore/battle scenes. It deliberately quacks
-- like Game where the presentation layer needs it — room, player, entities(),
-- dialogue, events — so the pixel renderer and dialogue box are reused.
local Region = require('src.region')
local Explore = require('src.explore')
local Dialogue = require('src.dialogue')
local LoreC = require('src.campaign_lore')
local Save = require('src.save')
local Items = require('src.items')
local Battle = require('src.battle')
local Sfx = require('src.sfx')
local Refugio = require('src.refugio')
local Props = require('src.props')
local Campaign = {}
-- Economia persistente (gold/pickaxes/xp): leitura e escrita passam para
-- self.data para sobreviver entre sessões; call sites antigos (a loja do
-- protótipo usa game.gold) continuam intactos. Auditoria Pátio.
local WALLET = {gold = true, pickaxes = true, xp = true}
function Campaign.__index(self, k)
    if WALLET[k] then
        local d = rawget(self, 'data')
        return d and d[k]
    end
    return Campaign[k]
end
function Campaign.__newindex(self, k, v)
    if WALLET[k] then self.data[k] = v else rawset(self, k, v) end
end

local function freshState()
    return {
        version = Save.VERSION,
        region = 'colina', x = nil, y = nil, arrival = 'sepultura',
        steps = {},          -- 'P01-E02' = true, in ficha notation
        flags = {},          -- casaco, metDoroFirst, gradeHow...
        regions = {},        -- [id] = {visited, props = {[id] = state}}
        people = {},         -- [id] = {met, location}
        encounters = {},     -- [id] = 'won' | 'negotiated'
        deaths = 0,
        gold = 0, pickaxes = 0, xp = 0,
        items = {},                              -- [id] = qty (src/items.lua)
        equipped = {arma = nil, ferramenta = nil},
    }
end

local function makePlayer()
    return {
        player = true, grid = {x = 1, y = 1},
        facing = {dx = 0, dy = 1},
        motion = {remaining = 0, duration = .16, fromX = 1, fromY = 1},
        health = {current = 10, max = 10},
        weapon = {state = 'empty', charge = 0, action = 0, mineTimer = 0},
        guard = {active = false, energy = Battle.staminaMax,
            max = Battle.staminaMax},
        moving = false,
    }
end

local function makeNpc(def)
    return {
        npc = {id = def.id}, grid = {x = def.x, y = def.y},
        facing = {dx = def.dx or 0, dy = def.dy or 1},
        motion = {remaining = 0, duration = .16, fromX = def.x, fromY = def.y},
        health = {current = 1, max = 1},
        talkRange = def.talkRange or 1.7,
        -- act: postura de trabalho lida pelo renderer (pixel_actors) quando a
        -- linha 'work' chegar; posts: postos por marco, resolvidos no enter.
        act = def.act,
    }
end

function Campaign.new(opts)
    local self = setmetatable({data = freshState(), state = 'playing', scene = 'explore',
        events = {}, message = '', messageTime = 0, roomTime = 0,
        level = 1, reward = nil,
        time = 0}, Campaign)
    self.data.flags.refugioNovo = not (opts and opts.legacy)
    for id, info in pairs(LoreC.npcs) do
        self.data.people[id] = {location = info.home or 'hub'}
    end
    if self:flag('refugioNovo') then
        self.data.people.bento.location = 'cozinha'
        self.data.people.teca.location = 'escola'
        -- Refúgio novo: Nilo mora na oficina (doc fixa oficina, não a rua).
        self.data.people.nilo.location = 'oficina'
    end
    self.player = makePlayer()
    self:enter(self.data.region, self.data.arrival)
    self:checkpoint()
    -- ABERTURA_HD: sem narração modal no despertar — controle imediato.
    -- A flag e o step "Despertar" ficam para compat de save.
    if not self.data.flags.intro then
        self.data.flags.intro = true
        self:completeStep('P01-E01')
    end
    return self
end

function Campaign.restore(data)
    for k, v in pairs({gold = 0, pickaxes = 0, xp = 0}) do
        if data[k] == nil then data[k] = v end
    end
    -- Backfill do inventário: saves anteriores à fatia 1 não carregam os campos.
    data.items = data.items or {}
    data.equipped = data.equipped or {arma = nil, ferramenta = nil}
    -- Save que já pegou os pertences antes da concessão de itens: a bolsa
    -- recebe o que a ficção dizia estar nela (once-hotspot não reemite).
    if data.flags and data.flags.casaco then
        for _, id in ipairs({'arco', 'picareta'}) do
            local def = Items.def(id)
            if def then
                data.items[id] = data.items[id] or 1
                if def.cat == 'equipavel' and def.slot and not data.equipped[def.slot] then
                    data.equipped[def.slot] = id
                end
            end
        end
    end
    local self = setmetatable({data = data, state = 'playing', scene = 'explore',
        events = {}, message = '', messageTime = 0,
        level = 1, reward = nil,
        time = 0}, Campaign)
    self.player = makePlayer()
    self:enter(data.region, nil, {x = data.x, y = data.y})
    return self
end

function Campaign:flag(name) return self.data.flags[name] == true end

-- Inventário (docs/BATALHA_ACT_MERCY.md §4): posse, concessão e
-- consumo passam por aqui para que grants futuros e a arena leiam o mesmo
-- estado persistente.
function Campaign:hasItem(id)
    if (self.data.items[id] or 0) > 0 then return true end
    -- Transição documentada: o hotspot de pertences já emite
    -- giveItem('arco') (campaign_lore.lua); o flag 'casaco' segue valendo
    -- como posse para saves gravados antes da emissão.
    if id == 'arco' then return self:flag('casaco') end
    return false
end

function Campaign:giveItem(id, n)
    local def = Items.def(id)
    if not def then return false end
    if def.stack then
        self.data.items[id] = (self.data.items[id] or 0) + (n or 1)
    else
        self.data.items[id] = 1     -- chave/equipável: posse é binária
    end
    -- Equipável ocupa seu slot se ele estiver livre — nunca desbanca o
    -- que já está na mão.
    if def.cat == 'equipavel' and def.slot and not self.data.equipped[def.slot] then
        self.data.equipped[def.slot] = id
    end
    return true
end

function Campaign:useItem(id)
    local def = Items.def(id)
    if not def or def.cat ~= 'consumivel' then return false end
    if (self.data.items[id] or 0) <= 0 then return false end
    self.data.items[id] = self.data.items[id] - 1
    return true
end

-- Efeito de consumível usado fora da arena (bolsa 'u'): o mesmo campo
-- battle.heal do def cura a personagem de exploração, que carrega vida entre
-- regiões. Na arena o submenu USAR já aplica o efeito em batalha.
function Campaign:applyItemEffect(id)
    local def = Items.def(id)
    local heal = def and def.battle and def.battle.heal
    -- MERGE-SHIM (COMBATE_MERGE §8): na arena a vida real mora na entidade
    -- de batalha — curar pela bolsa acerta quem está lutando, não o
    -- registro da exploração.
    local h = self.scene == 'battle' and self.battle and self.battle.player
        and self.battle.player.health or self.player.health
    if heal and h then
        h.current = math.min(h.max, h.current + heal)
    end
end

function Campaign:checkpoint()
    self.data.region, self.data.arrival = self.map.id, nil
    self.data.x, self.data.y = self.player.grid.x, self.player.grid.y
    Save.write(self.data)
end

-- Loads the authored map and folds the persistent region state over it:
-- consumed props disappear, opened passages lose their solidity, npcs appear
-- only where their saved location says they are.
function Campaign:enter(id, arrival, exact, opts)
    local map = Region.load(id, not self:flag('refugioNovo'))
    local saved = self.data.regions[id] or {visited = false, props = {}}
    self.data.regions[id] = saved
    saved.visited = true
    for propId, propState in pairs(saved.props or {}) do
        for _, prop in ipairs(map.props) do
            if prop.id == propId then prop.state = propState end
        end
    end
    for cell, prop in pairs(map.propCells) do
        if prop.state == 'open' or prop.state == 'taken' then map.propCells[cell] = nil end
    end
    self.map, self.room = map, map
    self:syncExits()
    self:syncRefugio()
    self:applyRelocations(id)
    self.npcs = {}
    for _, def in ipairs(map.npcs) do
        local person = self.data.people[def.id]
        if person and person.location == id then
            local npc = makeNpc(def)
            for _, post in ipairs(def.posts or {}) do
                local hit = (post.flag and self:flag(post.flag)) or (post.step and self:stepDone(post.step)) or (not post.flag and not post.step)
                if hit then
                    npc.grid.x = post.x or npc.grid.x
                    npc.grid.y = post.y or npc.grid.y
                    if post.dx then npc.facing.dx = post.dx end
                    if post.dy then npc.facing.dy = post.dy end
                    npc.act = post.act or npc.act
                end
            end
            self.npcs[#self.npcs + 1] = npc
        end
    end
    self.enemies = {}
    for _, def in ipairs(map.encounters) do
        if not self.data.encounters[def.id] then
            self.enemies[#self.enemies + 1] = {
                enemy = {id = def.id, kind = def.kind, state = 'idle', timer = 0},
                grid = {x = def.x, y = def.y}, facing = {dx = 0, dy = 1},
                motion = {remaining = 0, duration = .16, fromX = def.x, fromY = def.y},
                health = {current = 1, max = 1},
            }
        end
    end
    local point = map.arrivals[arrival or ''] or map.spawn
    if exact and type(exact.x) == 'number' and type(exact.y) == 'number'
        and Explore.free(self, exact.x, exact.y) then
        self.player.grid.x, self.player.grid.y = exact.x, exact.y
    else
        self.player.grid.x, self.player.grid.y = point.x, point.y
        self.player.facing.dx, self.player.facing.dy = point.dx or 0, point.dy or 1
    end
    self.scene, self.battle, self.dialogue = 'explore', nil, nil
    self.roomName = map.name
    self.roomTime = 3
    self:effect('room', self.player.grid.x, self.player.grid.y)
    if id == 'hub' and not self:stepDone('P01-E04') then
        self:completeStep('P01-E04')
        -- Refúgio novo: sem inscrição de chegada — o mirante revela por
        -- gatilhos de chão no update e segura o panorama enquanto ela anda
        -- a cota (ABERTURA_HD, Ato 4). O mapa legado mantém a narração fixa.
        if not self:flag('refugioNovo') then
            Dialogue.open(self, LoreC.hubArrival)
        end
    end
    if id == 'colina' and self:stepDone('P01-E04') and not self:flag('colinaRevisit') then
        Dialogue.open(self, LoreC.colinaRevisit)
        self.data.flags.colinaRevisit = true
    end
    -- Chegada na região: sino de entrada, loop de ambiência da ficha e a
    -- ambiência sai do duck de combate (batalha abaixa ela no startBattle).
    -- opts.quiet suprime o sino quando outro cue já marcou a passagem —
    -- travel toca portal_travel e die toca death_return no mesmo tick.
    if not (opts and opts.quiet) then Sfx.play('region_arrive') end
    Sfx.setAmbience(self.map.id, self.map.realm)
    Sfx.setDucked(false)
end

-- Mudanças locais aparecem imediatamente e são recompostas pelas flags do save.
function Campaign:syncRefugio()
    if self.map.realm ~= 'refugio' or not self:flag('refugioNovo') then return end
    for _, prop in ipairs(self.map.props) do
        local state
        if prop.id == 'marco' then state = self:flag('refugioConcluido') and 'lit' or 'quiet'
        elseif prop.id == 'bancada' or prop.id == 'forjaCasa' then state = self:flag('preparoRefugio') and 'lit' or 'covered'
        elseif prop.id == 'cisterna' then state = self:flag('aguaRefugio') and 'done' or 'quiet'
        elseif prop.id == 'cozinhaCasa' or prop.id == 'fogao' then state = self:flag('aguaRefugio') and 'lit' or 'quiet'
        elseif prop.id == 'capelaCasa' or prop.id == 'altar' then state = self:stepDone('P01-E03') and 'lit' or 'quiet'
        elseif prop.id == 'cama1' or prop.id == 'cama2' or prop.id == 'cama3' then state = self:flag('refugioConcluido') and 'named' or 'quiet'
        elseif prop.id == 'varalPensao' or prop.id == 'lenhaQuintal' or prop.id == 'mesa' then state = self:flag('aguaRefugio') and 'lit' or 'quiet'
        elseif prop.id == 'bigornaQuintal' then state = self:flag('preparoRefugio') and 'lit' or 'covered'
        elseif prop.id == 'sulcosHorta' or prop.id == 'espantalhoHorta' or prop.id == 'camasCasa' or prop.id == 'escolaCasa' or prop.id == 'cartazPraca' then state = self:flag('refugioConcluido') and 'lit' or 'quiet'
        elseif prop.id == 'caixasCozinha' then state = self:flag('aguaRefugio') and 'done' or 'quiet'
        elseif prop.id == 'oferenda' or prop.id == 'braseiroMirante' then state = self:stepDone('P01-E03') and 'lit' or 'quiet'
        elseif prop.id == 'recipientesPoco' then state = self:flag('aguaRefugio') and 'lit' or 'quiet'
        elseif prop.id == 'canteiroJardim' or prop.id == 'ervasSecas' then state = self:flag('refugioConcluido') and 'lit' or 'quiet'
        end
        if state then prop.state = state end
    end
end

-- Exit defs may carry a `flag`: once that campaign flag is true the portal
-- (and its cell, which Explore.solidCell and canLeave read) stays open.
-- Runs on every enter so a freshly loaded map picks up flags set elsewhere.
function Campaign:syncExits()
    if self:flag('filtroMontado') and self:flag('escoraReforcada') then
        self.data.flags.passagemFundacao = true
    end
    for _, exit in ipairs(self.map.exits) do
        if exit.flag and self:flag(exit.flag) then
            local opening = exit.open == false
            exit.open = true
            for _, cell in pairs(self.map.tiles) do
                if cell.exit == exit then cell.exit.open = true end
            end
            -- Rota recém-aberta sinaliza: aviso + floreio no portal. O aviso
            -- é deduplicado por sessão (o mapa é reconstruído a cada enter).
            if opening then
                self._exitsAnnounced = self._exitsAnnounced or {}
                local key = self.map.id .. ':' .. exit.x .. ':' .. exit.y
                if not self._exitsAnnounced[key] then
                    self._exitsAnnounced[key] = true
                    self:notify('PASSAGEM ABERTA — ' .. (exit.label or 'caminho liberado.'))
                    self:effect('sealBreak', exit.x, exit.y, nil, true)
                    Sfx.play('portal_open')
                end
            end
        end
    end
end

-- Residents move between regions as the story advances; relocation runs
-- before the npc spawn loop so they are already standing inside on arrival.
-- Doro relocates after the first descent; if the runa negotiation is done
-- she moves to the passage house as well.
-- TODO: generalizar via tabela quando houver segunda região com NPC móvel.
function Campaign:applyRelocations(id)
    if id == 'hub' and not self:stepDone('P01-E04') then
        self.data.people.doro = self.data.people.doro or {}
        self.data.people.doro.location = 'hub'
        if self:stepDone('P01-E03') then
            self.data.people.runa = self.data.people.runa or {}
            self.data.people.runa.location = 'hub'
        end
    end
    -- Figurantes de base migram de saves antigos que ainda guardem 'fora'
    -- do gate por marco (rev1). Chegadas com arco futuro entram aqui com
    -- flag própria, mesmo padrão.
    if id == 'hub' and self:flag('refugioNovo') then
        for _, fid in ipairs({'anciao', 'lavadeira', 'carregador', 'lenhador', 'crianca'}) do
            local p = self.data.people[fid]
            if not p or p.location == 'fora' then
                self.data.people[fid] = p or {}
                self.data.people[fid].location = 'hub'
            end
        end
        -- Nilo migra de saves antigos que ainda o marquem na praça: o def
        -- dele mora na oficina interior e 'hub' o deixaria invisível.
        local np = self.data.people.nilo
        if np and np.location == 'hub' then np.location = 'oficina' end
    end
    -- Doro assume a capela depois da grade resolvida e do povoado já visto do
    -- mirante: quintal da forja na chegada (doc §3), capela nas voltas.
    if self:flag('refugioNovo') and self:stepDone('P01-E03') and self:stepDone('P01-E04') then
        self.data.people.doro = self.data.people.doro or {}
        self.data.people.doro.location = 'capela'
    end
end

function Campaign:stepDone(step) return self.data.steps[step] == true end

function Campaign:completeStep(step)
    if self.data.steps[step] then return end
    self.data.steps[step] = true
    self:checkpoint()
end

-- Prop states: 'open' and 'taken' stop blocking; 'done' keeps the body but
-- draws the used version. States persist in state.regions[id].props.
function Campaign:setProp(id, value)
    local saved = self.data.regions[self.map.id]
    saved.props = saved.props or {}
    saved.props[id] = value
    -- TRACO shadow: state novo de prop sólido muda a sombra assada no
    -- canvas da sala — marca o mapa para o renderer reassar uma vez.
    -- (Pátio revisa este fio; único hunk de campanha do fix de sombra.)
    for _, prop in ipairs(self.map.props) do
        if prop.id == id then
            local dirty = prop.solid and prop.state ~= value
            prop.state = value
            if dirty then require('src.pixel_scene').invalidate(self.map) end
        end
    end
    if value == 'open' or value == 'taken' then
        for cell, prop in pairs(self.map.propCells) do
            if prop.id == id then self.map.propCells[cell] = nil end
        end
    end
    self:checkpoint()
end

function Campaign:openGrade(how)
    -- MERGE-SHIM (C01-Q1): a primeira abertura é o fato — 'confessou'/'doro'
    -- não viram 'won' se a demonstração resolve depois da grade aberta.
    self.data.flags.gradeHow = self.data.flags.gradeHow or how
    self:setProp('grade', 'open')
    self:completeStep('P01-E03')
    self.data.people.runa.location = 'hub'
    self:notify('A grade sobe. O caminho para o refúgio está livre.')
    self:effect('sealBreak', 5.5, 17.5, nil, true)
    Sfx.play('portal_open')
end

function Campaign:travel(to, arrival)
    if to == 'andlar' and not self:flag('refugioConcluido') then
        self:notify('ANDLAR ainda está apagado. Conclua seu primeiro trabalho no Refúgio.')
        return false
    end
    local localPath = (self:flag('refugioNovo') and self.map.realm == 'refugio' and to ~= 'andlar')
        or (self.map.id == 'colina' and to == 'hub')
        or (self.map.id == 'hub' and to == 'colina')
    Sfx.play(localPath and 'region_arrive' or 'portal_travel')
    self:enter(to, arrival, nil, {quiet = true})
    self:checkpoint()
    return true
end

function Campaign:die(cause)
    self:syncStamina()      -- a arena fecha sem endBattle: o fôlego volta igual
    -- MERGE-SHIM (COMBATE_MERGE §2.2): quem acorda na cova acorda inteiro —
    -- a vida zerada da arena não escorre para a exploração.
    self.player.health.current = self.player.health.max
    self.data.deaths = (self.data.deaths or 0) + 1
    self:enter('colina', 'sepultura', nil, {quiet = true})
    Sfx.play('death_return')
    Dialogue.open(self, LoreC.deathReturn(self))
    self:notify('Você acorda de novo na cova. Nada foi desfeito.')
    self:checkpoint()
end

-- sfx=true marca eventos cujo áudio o Sfx já cobriu no call site: o consume
-- do feedback mantém o visual (anel/partículas) e pula o play duplicado.
function Campaign:effect(kind, x, y, value, sfx)
    self.events[#self.events + 1] = {kind = kind, x = x, y = y, value = value, sfx = sfx}
end

function Campaign:notify(text, duration)
    self.message, self.messageTime = text, duration or 2.8
end

function Campaign:entities()
    if self.scene == 'battle' and self.battle then
        local list = {self.battle.player}
        for _, e in ipairs(self.battle.enemies or {}) do list[#list + 1] = e end
        return list
    end
    local list = {self.player}
    for _, npc in ipairs(self.npcs) do list[#list + 1] = npc end
    for _, e in ipairs(self.enemies or {}) do list[#list + 1] = e end
    return list
end

function Campaign:canLeave(door) return door.open ~= false end
function Campaign:weaponStats() return {chargeTime = .72, damage = 3} end
function Campaign:clearIntents() self.player.moving = false end
function Campaign:advanceDialogue() Dialogue.advance(self) end
function Campaign:closeDialogue() Dialogue.close(self) end
function Campaign:chooseDialogue(index) return Dialogue.choose(self, index) end

function Campaign:nearNpc()
    local p = self.player.grid
    local best, bestDist = nil, math.huge
    for _, npc in ipairs(self.npcs) do
        local d = math.abs(npc.grid.x - p.x) + math.abs(npc.grid.y - p.y)
        if d < bestDist then best, bestDist = npc, d end
    end
    if best and bestDist <= (best.talkRange or 1.7) then return best end
end

function Campaign:nearHotspot()
    local p = self.player.grid
    local best, bestDist = nil, math.huge
    for _, spot in ipairs(self.map.hotspots) do
        local used = spot.once and self.data.regions[self.map.id].props[spot.id] == 'taken'
        local ok = not used and (not spot.when or spot.when(self))
        if ok then
            local dist = math.sqrt((spot.x - p.x) ^ 2 + (spot.y - p.y) ^ 2)
            if dist <= (spot.range or 1.45) and dist < bestDist then
                best, bestDist = spot, dist
            end
        end
    end
    return best
end

-- Seleção única de alvo de interação (§facing): npcs e hotspots disputam o
-- mesmo pool — o cosseno entre a orientação da jogadora e o alvo domina o
-- placar e a distância relativa desempata. Só tiles de parede vedam a
-- fala: grades e bases de props não são paredes opacas.
local function interactScore(px, py, fx, fy, tx, ty, range)
    local dx, dy = tx - px, ty - py
    local d = math.sqrt(dx * dx + dy * dy)
    if d > range then return nil end
    -- Proximidade é a base — o que está sob o nariz sempre conta. O facing
    -- decide quando é claro: alvo no eixo do olhar (cos ≥ .85) ganha bônus
    -- alto; o cosseno residual só desempata direções ambíguas, nunca pune
    -- o que está perto atrás das costas.
    local cos = d > .01 and (dx * fx + dy * fy) / d or 0
    return (1 - d / range) + (cos >= .85 and .5 or 0) + cos * .1
end

local function interactionWall(map, px, py, tx, ty, inspection)
    local dx, dy = tx - px, ty - py
    for y = math.floor(math.min(py, ty) + .5), math.floor(math.max(py, ty) + .5) do
        for x = math.floor(math.min(px, tx) + .5), math.floor(math.max(px, tx) + .5) do
            local cell = map.tiles[x .. ':' .. y]
            -- Uma inscrição pode estar na própria parede do tile final.
            -- Só hotspots têm essa exceção; paredes no caminho continuam opacas.
            local targetWall = inspection and x == math.floor(tx + .5) and y == math.floor(ty + .5)
            if cell and cell.piece == 'wall' and not targetWall then
                -- Interseção do segmento com o interior do tile; tocar a
                -- quina não veda uma fala. O alcance curto limita a busca.
                local lo, hi = 0, 1
                if dx == 0 then
                    if px <= x - .5 or px >= x + .5 then hi = -1 end
                else
                    local a, b = (x - .5 - px) / dx, (x + .5 - px) / dx
                    lo, hi = math.max(lo, math.min(a, b)), math.min(hi, math.max(a, b))
                end
                if dy == 0 then
                    if py <= y - .5 or py >= y + .5 then hi = -1 end
                else
                    local a, b = (y - .5 - py) / dy, (y + .5 - py) / dy
                    lo, hi = math.max(lo, math.min(a, b)), math.min(hi, math.max(a, b))
                end
                if lo < hi then return true end
            end
        end
    end
    return false
end

function Campaign:interactTarget()
    local p, f = self.player.grid, self.player.facing
    local fx, fy = f.dx or 0, f.dy or 1
    local best, bestScore
    local function pick(kind, obj, tx, ty, range)
        local s = interactScore(p.x, p.y, fx, fy, tx, ty, range)
        if s and (not bestScore or s > bestScore)
            and not interactionWall(self.map, p.x, p.y, tx, ty, kind == 'spot') then
            best, bestScore = {kind = kind, obj = obj}, s
        end
    end
    for _, npc in ipairs(self.npcs) do
        pick('npc', npc, npc.grid.x, npc.grid.y, npc.talkRange or 1.7)
    end
    -- MERGE-SHIM (C01-Q1): a criatura com def.talk entra no mesmo pool —
    -- a Runa responde do posto dela como o npc respondia através da grade
    -- (barras não selam interact, mesmo contrato §facing). A flag de
    -- confronto não entra aqui: ela só decide o contato e o watcher
    -- trigger='flag' — a conversa nunca fica trancada atrás da prova.
    for _, e in ipairs(self.enemies) do
        local def = self:encounterDef(e.enemy.id)
        if def and def.talk then
            pick('talker', e, e.grid.x, e.grid.y, def.talkRange or 1.7)
        end
    end
    for _, spot in ipairs(self.map.hotspots) do
        local used = spot.once and self.data.regions[self.map.id].props[spot.id] == 'taken'
        local ok = not used and (not spot.when or spot.when(self))
        if ok then pick('spot', spot, spot.x, spot.y, spot.range or 1.45) end
    end
    return best
end

function Campaign:interact()
    if self.dialogue or self.scene ~= 'explore' then return false end
    local target = self:interactTarget()
    if not target then return false end
    if target.kind == 'npc' then
        local npc = target.obj
        npc.facing.dx = self.player.grid.x > npc.grid.x and 1
            or self.player.grid.x < npc.grid.x and -1 or 0
        npc.facing.dy = npc.facing.dx == 0 and (self.player.grid.y > npc.grid.y and 1 or -1) or 0
        local node = self:flag('refugioNovo') and self.map.realm == 'refugio' and self.map.id ~= 'colina'
            and Refugio.talk(self, npc.npc.id) or LoreC.talk(self, npc.npc.id)
        if node then
            self.player.moving = false
            Dialogue.open(self, node)
            Sfx.play('npc_greet', {pitch = Sfx.voice(npc.npc.id)})
            self:effect('talk', npc.grid.x, npc.grid.y, nil, true)
            self:checkpoint()
            return true
        end
        return false
    end
    if target.kind == 'talker' then
        -- MERGE-SHIM (C01-Q1): a criatura falante usa o mesmo rito do npc —
        -- vira para a jogadora, congela o passo e grava a abordagem. O node
        -- vem de def.talk, exatamente como na saudação por contato.
        local foe = target.obj
        local def = self:encounterDef(foe.enemy.id)
        local node = def and def.talk and LoreC.talk(self, def.talk)
        if node then
            foe.greeted = true
            foe.facing.dx = self.player.grid.x > foe.grid.x and 1
                or self.player.grid.x < foe.grid.x and -1 or 0
            foe.facing.dy = foe.facing.dx == 0
                and (self.player.grid.y > foe.grid.y and 1 or -1) or 0
            self.player.moving = false
            Dialogue.open(self, node)
            Sfx.play('npc_greet', {pitch = Sfx.voice(node.voice or foe.enemy.kind)})
            self:effect('talk', foe.grid.x, foe.grid.y, nil, true)
            self:checkpoint()
            return true
        end
        return false
    end
    local spot = target.obj
    if spot then
        self.player.moving = false
        -- `use` is an authored side effect (region hotspot defs); it runs
        -- before the fala so flags it sets can shape the node, and a
        -- use-only spot without lines still counts as an interaction.
        if spot.use then spot.use(self) end
        local node = self:flag('refugioNovo') and Refugio.hotspot(self, spot)
            or LoreC.hotspot(self, spot)
        if node or spot.use then
            if node then
                -- Imagem contextual do diálogo: o node pode declarar icon
                -- próprio (autoria); na ausência, o hotspot mapeia o id.
                node.icon = node.icon or Props.dialogIcon(spot.id)
                Dialogue.open(self, node)
                -- Só apresentação: cópia do objeto depois da resolução local.
                -- Fica no diálogo, nunca no save nem no node compartilhado.
                if spot.id ~= 'miranteRefugio' and spot.id ~= 'terracoRefugio' then
                    local target = ({marcoRefugio = 'marco', retornoAndlar = 'marcoAndlar',
                        aguaRefugio = 'cisterna', preparoRefugio = 'bancada',
                        descansoRefugio = 'cama2', camasRefugio = 'cama3',
                        refeicaoRefugio = 'mesa', bauRefugio = 'bauPensao',
                        cabraRefugio = 'cabra', cartazRefugio = 'cartazPraca'})[spot.id] or spot.id
                    -- prop.id exato vence sempre; prop.kind é só fallback
                    -- quando nenhum id casa (genérico próprio do nó).
                    local subject, distance, fallback, fbDistance
                    for _, prop in ipairs(self.map.props) do
                        local dx = prop.x + ((prop.w or 1) - 1) / 2 - spot.x
                        local dy = prop.y + ((prop.h or 1) - 1) / 2 - spot.y
                        local d = dx * dx + dy * dy
                        if prop.id == target and (not distance or d < distance) then
                            subject, distance = prop, d
                        elseif prop.kind == node.icon and (not fbDistance or d < fbDistance) then
                            fallback, fbDistance = prop, d
                        end
                    end
                    subject = subject or fallback
                    if subject then
                        local snapshot = {}
                        for k, v in pairs(subject) do
                            if type(v) ~= 'table' and type(v) ~= 'function' then snapshot[k] = v end
                        end
                        -- Recolhido é estado de mundo, não apaga a imagem do achado.
                        if snapshot.state == 'taken' then snapshot.state = nil end
                        self.dialogue.preview = snapshot
                    end
                end
                Sfx.play('npc_greet', {pitch = Sfx.voice(node.voice or 'inscription')})
            end
            if spot.once then
                self.data.regions[self.map.id].props[spot.id] = 'taken'
            end
            self:effect('talk', spot.x, spot.y, nil, true)
            self:checkpoint()
            return true
        end
    end
    return false
end

function Campaign:encounterDef(id)
    for _, d in ipairs(self.map.encounters or {}) do
        if d.id == id then return d end
    end
end

function Campaign:startBattle(encounterId)
    -- The authored def travels with the battle so `units` can field more
    -- than one enemy; a bare world entity still yields its kind.
    local def = self:encounterDef(encounterId)
    if not def then
        for _, e in ipairs(self.enemies) do
            if e.enemy.id == encounterId then def = {kind = e.enemy.kind}; break end
        end
    end
    self.battle = Battle.new(self, encounterId, def)
    self.scene = 'battle'
    -- Chefes (roles com `boss`, §12) ganham a introdução própria; encontro
    -- comum soa o alarme de arena. A ambiência abaixa atrás do combate.
    local boss
    for _, u in ipairs(self.battle.enemies or {}) do
        if u.role and u.role.boss then boss = true; break end
    end
    Sfx.play(boss and 'boss_intro' or 'encounter_start')
    Sfx.setDucked(true)
    -- A entrada na arena ganha a mesma cortina de revelação das salas.
    self:effect('room', self.player.grid.x, self.player.grid.y)
end

-- O fôlego mora na personagem da exploração; a arena trabalha sobre uma
-- player própria. Na saída da batalha o valor volta para a campanha para
-- persistir entre encontros.
function Campaign:syncStamina()
    local bp = self.battle and self.battle.player
    local bg = bp and bp.guard
    if bg and self.player.guard and bg.energy then
        self.player.guard.energy = bg.energy
    end
    -- MERGE-SHIM (COMBATE_MERGE §8): a vida da arena também volta para a
    -- personagem — o hp do encontro é o hp real, não uma cópia descartável.
    local bh = bp and bp.health
    if bh and self.player.health then
        self.player.health.current = bh.current
    end
end

function Campaign:endBattle(result)
    local encounter = self.battle.encounterId
    self:syncStamina()
    self.scene, self.battle = 'explore', nil
    self:effect('room', self.player.grid.x, self.player.grid.y)
    Sfx.setDucked(false)
    Sfx.play(result == 'won' and 'battle_won'
        or result == 'negotiated' and 'battle_negotiated' or 'battle_flee')
    if result == 'won' or result == 'negotiated' then
        local unresolved = self.data.encounters[encounter] == nil
        self.data.encounters[encounter] = result
        for i, e in ipairs(self.enemies) do
            if e.enemy.id == encounter then table.remove(self.enemies, i); break end
        end
        -- Saque do encontro (BATALHA_ACT_MERCY §4, fatia 3): o def
        -- autoral pode pagar gold/xp/itens na resolução. `parleyLoot`, quando
        -- existe, substitui a recompensa da retirada pacífica; sem ele,
        -- 'negotiated' recebe `loot` integral — resolver pela conversa nunca
        -- rende menos que vencer na força. Fuga ('return') e derrota não
        -- pagam nada. `unresolved` trava a emissão: encontro já marcado
        -- nunca reemite o saque.
        local def = self:encounterDef(encounter)
        local bag = result == 'won' and def and def.loot
            or result == 'negotiated' and def and (def.parleyLoot or def.loot)
        self:grantLoot(bag, unresolved)
        -- MERGE-SHIM (C01-Q1): `def.onResolve` é o gancho autoral da
        -- resolução — o encontro decide o que a vitória ou a saída pacífica
        -- deixa no mundo (a Runa abre a grade). Só na primeira marcação:
        -- `unresolved` falso significa encontro já resolvido — o efeito
        -- nunca repete, como o saque.
        if unresolved and def and def.onResolve then
            def.onResolve(self, result)
        end
        self:checkpoint()
    elseif result == 'return' then
        self:retreatFrom(encounter)
    end
    self.player.moving = false
end

-- Emite o saque de um encontro uma única vez (chamado por endBattle e por
-- settleEncounter; `unresolved` falso quando encounters[id] já tinha valor).
function Campaign:grantLoot(bag, unresolved)
    if not (unresolved and bag) then return end
    local got = {}
    if (bag.gold or 0) > 0 then
        self.gold = self.gold + bag.gold
        got[#got + 1] = '+' .. bag.gold .. ' ouro'
    end
    if (bag.xp or 0) > 0 then
        self.xp = self.xp + bag.xp
        got[#got + 1] = '+' .. bag.xp .. ' xp'
    end
    for id, n in pairs(bag.items or {}) do
        if self:giveItem(id, type(n) == 'number' and n or 1) then
            local d = Items.def(id)
            got[#got + 1] = (d and d.label) or id
        end
    end
    if #got > 0 then
        self:notify('Saque: ' .. table.concat(got, ', ') .. '.')
    end
end

-- Resolução pacífica por diálogo (Pena escreve encounters[id] nos nodes):
-- registra o resultado e emite o mesmo saque do endBattle, então conversar
-- fora da arena nunca rende menos que lutar dentro dela.
function Campaign:settleEncounter(id, result)
    local unresolved = self.data.encounters[id] == nil
    self.data.encounters[id] = result
    if result == 'won' or result == 'negotiated' then
        local def = self:encounterDef(id)
        local bag = result == 'won' and def and def.loot
            or def and (def.parleyLoot or def.loot)
        self:grantLoot(bag, unresolved)
    end
    self:checkpoint()
end

-- Fleeing steps the player off the creature's reach so the pending encounter
-- doesn't reopen on the very next frame. Prefers the direction the player
-- came from, then slides along a side when the way back is blocked.
function Campaign:retreatFrom(encounterId)
    local foe
    for _, e in ipairs(self.enemies) do
        if e.enemy.id == encounterId then foe = e; break end
    end
    if not foe then return end
    local p = self.player.grid
    local dx, dy = p.x - foe.grid.x, p.y - foe.grid.y
    local primary = math.abs(dx) >= math.abs(dy)
        and {dx >= 0 and 1 or -1, 0} or {0, dy >= 0 and 1 or -1}
    local options = {primary,
        {primary[2], primary[1]}, {-primary[2], -primary[1]},
        {-primary[1], -primary[2]}}
    for _, d in ipairs(options) do
        local nx, ny = p.x + d[1] * 1.05, p.y + d[2] * 1.05
        if Explore.free(self, nx, ny) then
            p.x, p.y = nx, ny
            self.player.facing.dx, self.player.facing.dy = -d[1], -d[2]
            return
        end
    end
end

function Campaign:update(dt, input)
    if self.panoramaTime and not self.dialogue then self.panoramaTime = math.max(0, self.panoramaTime - dt) end
    if self.scene == 'battle' then
        self.battle:update(dt, self, input)
        return
    end
    if self.dialogue then return end
    self.time = self.time + dt
    self.messageTime = math.max(0, self.messageTime - dt)
    self.roomTime = math.max(0, self.roomTime - dt)
    Explore.move(self, dt, input.dx or 0, input.dy or 0)
    -- Visible encounters: touching the creature in the world opens its arena —
    -- or its conversation first, when the def carries a talk hook. The talk
    -- resolves peacefully by writing encounters[id] directly (Pena's nodes)
    -- or sets the <talk>Confronto flag, which makes contact fire the arena.
    if self.scene == 'explore' then
        -- Revelação do mirante (ABERTURA_HD, Ato 4 — contrato do Pena): na
        -- primeira descida do refúgio novo, as três inscrições disparam por
        -- distância no parapeito — gatilho de chão, não de tempo. Dois
        -- fatos separados: `miranteVisto` esgota os beats e `miranteDesceu`
        -- encerra o pin do panorama — a vista fica enquanto ela estiver na
        -- cota na primeira visita (y<=8 cobre o mirante e a boca da
        -- escadaria), mesmo depois do último beat. Descer com a revelação
        -- começada (miranteBeat) fecha os dois: os beats que faltarem se
        -- perdem e o pin não volta. Save restaurado já na vila sem
        -- miranteBeat mantém a cena pendente — subir ao parapeito reata
        -- beats e vista. O checkpoint na virada de miranteDesceu grava o
        -- índice: sair entre beats não re-toca inscrição lida (doc §1). O
        -- early-return de self.dialogue impede beat sobre diálogo aberto.
        if self.map.id == 'hub' and self:flag('refugioNovo') then
            if self.player.grid.y <= 8 then
                if not self:flag('miranteDesceu') then
                    self.panoramaTime = math.max(self.panoramaTime or 0, 1)
                end
                if not self:flag('miranteVisto') then
                    local idx = self.data.flags.miranteBeat or 1
                    local beat = LoreC.miranteReveal[idx]
                    if beat and self.player.grid.x >= beat.x then
                        Dialogue.open(self, {title = ' ', voice = 'inscription',
                            mood = 'soft', lines = beat.lines})
                        self.data.flags.miranteBeat = idx + 1
                        if not LoreC.miranteReveal[idx + 1] then
                            self.data.flags.miranteVisto = true
                        end
                    end
                end
            elseif self.data.flags.miranteBeat then
                -- Desceu depois de ver: os beats que faltarem se perdem e o
                -- pin do panorama não volta — a primeira visita acabou.
                self.data.flags.miranteVisto = true
                if not self.data.flags.miranteDesceu then
                    self.data.flags.miranteDesceu = true
                    self:checkpoint()
                end
            end
        end
        -- trigger='flag': a arena é armada pela fala, não por contato — a
        -- flag do confronto sobe na opção de diálogo e o próximo update
        -- dispara (C01-Q1: a demonstração na grade acontece atrás das
        -- barras). A flag é consumida no disparo — fuga devolve o impasse
        -- e pede nova aceitação.
        for _, def in ipairs(self.map.encounters or {}) do
            if def.trigger == 'flag' and def.confronto and self:flag(def.confronto)
                and self.data.encounters[def.id] == nil then
                self.data.flags[def.confronto] = nil
                self:startBattle(def.id)
                return
            end
        end
        -- Passos: batida seca a cada ~.28 s enquanto a personagem anda
        -- (moving é mantido por Explore.move; parar zera o relógio).
        if self.player.moving then
            self.stepT = (self.stepT or 0) - dt
            if self.stepT <= 0 then
                self.stepT = .28
                Sfx.play('step', {pitch = .9 + love.math.random() * .2})
            end
        else
            self.stepT = 0
        end
        -- A settled encounter leaves the field on sight, however it ended.
        for i = #self.enemies, 1, -1 do
            if self.data.encounters[self.enemies[i].enemy.id] then
                table.remove(self.enemies, i)
            end
        end
        local p = self.player.grid
        local nearest = math.huge
        for _, e in ipairs(self.enemies) do
            local dx, dy = e.grid.x - p.x, e.grid.y - p.y
            local dist = math.abs(dx) + math.abs(dy)
            if dist < nearest then nearest = dist end
            -- Stepping away re-arms the greeting; standing contact after a
            -- closed talk stays inert instead of reopening it every frame.
            if math.abs(dx) + math.abs(dy) > 1.5 then e.greeted = nil end
            if math.abs(dx) < .55 and math.abs(dy) < .55 then
                local def = self:encounterDef(e.enemy.id)
                local confronto = def and def.talk
                    and (def.confronto or (def.talk .. 'Confronto'))
                if confronto and not self:flag(confronto) then
                    if not e.greeted then
                        local node = LoreC.talk(self, def.talk)
                        if node then
                            e.greeted = true
                            e.facing.dx = p.x > e.grid.x and 1
                                or p.x < e.grid.x and -1 or 0
                            e.facing.dy = e.facing.dx == 0
                                and (p.y > e.grid.y and 1 or -1) or 0
                            self.player.moving = false
                            Dialogue.open(self, node)
                            Sfx.play('npc_greet', {pitch = Sfx.voice(node.voice or e.enemy.kind)})
                            self:effect('talk', e.grid.x, e.grid.y, nil, true)
                            self:checkpoint()
                        end
                        -- Sem node escrito: contato inerte — fala pendente na
                        -- ficha, não queda automática na arena.
                    end
                else
                    self:startBattle(e.enemy.id)
                end
                break
            end
        end
        -- Antecipação de perigo: encontro vivo a até 4 tiles soa um lub-dub
        -- grave espaçado (o gap de 1.4 s do cue segura a cadência sozinho).
        if nearest < 4 then Sfx.play('danger_near', {volume = .3}) end
    end
end

return Campaign
