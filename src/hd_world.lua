-- src/hd_world.lua — render HD da exploração (Fase 2): o mesmo mundo do
-- drawCampaign, mas composto pelo pipeline G-buffer (albedo/normal/
-- emissivo) + Lighting + PostFX, em células artísticas de 64px (2× a
-- grade de simulação de 32). Simulação é só leitura: map.tiles/props/
-- campaign:entities()/Props.lightAnchor/shadowCaster alimentam a arte.
--
-- Contrato com render.lua: chamado DENTRO do translate da câmera com a
-- vista (Render.layout {cell=64,scale=1}) e o canvas de vista bound.
-- Desenha o frame inteiro nesse canvas; HUD/diálogo seguem legados.

local G = love.graphics
local Kit = require('src.hd_kit')
local Lighting = require('src.lighting')
local Fx = require('src.fx_play')
local PostFX = require('src.postfx')
local Props = require('src.props')
local Pal = require('src.palettes')
local PixelWorld = require('src.pixel_world')
local PixelArt = require('src.pixel_art_v2')
local PixelFont = require('src.pixel_font')
local PixelScene = require('src.pixel_scene')

local CELL = 64
local HDWorld = {}

-- kind/id de prop -> def DSL do Traço (src/sprites/NOME). A DSL cobre a
-- maior parte dos kinds de região; o que não casa recebe stub baixo.
local PROP_SPRITE = {
    marco = 'marco', braseiro = 'braseiro', poco = 'poco',
    cisterna = 'cisterna_rua', pocoRua = 'cisterna_rua',
    placa = 'placa', placaRotas = 'placa', placaEma = 'placa',
    cartaz = 'cartaz', banco = 'banco_madeira', bancada = 'bancada',
    mesa = 'mesa', cadeira = 'cadeira', estante = 'estante',
    prateleira = 'prateleira', arvore = 'arvore', cercado = 'cercado',
    lampiao = 'lampiao', posteLuz = 'lampiao', postoVigia = 'posto_vigia',
    bau = 'bau', altar = 'altar', bigorna = 'bigorna', cama = 'cama',
    caixas = 'caixas_antigas', carteiras = 'carteiras', cipo = 'cipo',
    cova = 'cova', divisoria = 'divisoria', entulho = 'entulho',
    espantalho = 'espantalho', fardos = 'fardos', flores = 'flores_adro',
    fogao = 'fogao', lapide = 'lapide_a', sepultura = 'lapide_b',
    mureta = 'mureta_adro', muro = 'muro_colina', parapeito = 'parapeito',
    pertences = 'pertences', lenha = 'pilha_lenha',
    pilhaLenha = 'pilha_lenha', portao = 'portao_adro', quadro = 'quadro',
    quadroAula = 'quadro_aula', ervasRack = 'rack_ervas',
    ferramentas = 'rack_ferramentas', recipientes = 'recipientes',
    remendoMuro = 'remendo_muro', rocha = 'rocha', serragem = 'serragem',
    tigela = 'tigela', toldo = 'toldo', toldoFeirante = 'toldo',
    varal = 'varal', varalTerraco = 'varal_terraco', vela = 'vela_votiva',
    velas = 'velas', oferenda = 'oferenda', brinquedo = 'brinquedo',
    marcaImpro = 'marca_impro', pecaInacabada = 'peca_inacabada',
    baldeTempera = 'balde_tempera', brasaForja = 'brasa_forja',
    canteiro = 'canteiro_a',
    -- Bancos por feitio (Botica pediu divergência):
    bancoCapela = 'banco_capela', bancoMadeira = 'banco_madeira',
    bancoPedra = 'banco_pedra', bancoSerra = 'banco_serra',
    bancoTerraco = 'banco_terraco',
    -- Vida/ambiente (Traço redesign):
    mesaLonga = 'mesa_longa', mesaOferenda = 'mesa_oferenda',
    varal = 'varal_vento', vela = 'vela_votiva_anim',
    tocha = 'tocha', chamine = 'fumaca_chamine',
    madeiraParede = 'madeira_encostada', cargas = 'fardos',
    cabra = 'cabra',
    ervasSecas = 'rack_ervas',
}

local function dirSuffix(f)
    if not f then return 's' end
    if math.abs(f.dy or 0) >= math.abs(f.dx or 0) then
        return (f.dy or 1) < 0 and 'n' or 's'
    end
    return (f.dx or 1) > 0 and 'e' or 'w'
end

local function visualPos(ent)
    local R = package.loaded['src.render']
    if R and R.visualPosition then return R.visualPosition(ent) end
    local g = ent.grid or {x = 0, y = 0}
    return (g.x - .5) * 32, (g.y - .5) * 32
end

-- Stub de prop genérico: caixa baixa de madeira — placeholder honesto.
local function propStub(x, y)
    if y >= 62 and x >= 8 and x <= 55 then
        local edge = y >= 88 or x <= 10 or x >= 53
        local v = Kit.hash(x, y, 11) * .04
        return edge and {.13, .10, .08, 1} or {.28 + v, .21 + v, .14, 1},
            edge and 6 or 9
    end
    return nil
end

-- Stub de ator genérico: capuz/figura escura (inimigos, NPCs sem def).
local function actorStub(x, y)
    if y >= 88 and x >= 22 and x <= 42 then return {.12, .10, .09, 1}, 4 end
    if y >= 26 and y <= 92 then
        local w2 = 13 + (y - 26) * .16
        if math.abs(x - 31.5) <= w2 then
            local v = Kit.hash(x, y, 12) * .03
            return {.22 + v, .20 + v, .24 + v, 1}, 7
        end
    end
    if y >= 10 and y <= 30 then
        local dx, dy = (x - 31.5) / 13, (y - 20) / 11
        if dx * dx + dy * dy <= 1 then return {.30, .26, .24, 1}, 10 end
    end
    return nil
end

local function sheetsFor(self)
    local s = self._sheets
    if s then return s end
    s = {}
    local function put(key, sheet) s[key] = sheet; s[key .. '_q'] = Kit.quads(sheet) end
    put('laje', Kit.sheet('piso_laje', 64, 64, nil))
    put('terra', Kit.sheet('piso_terra', 64, 64, nil))
    put('grama', Kit.sheet('piso_grama', 64, 64, nil))
    put('caminho', Kit.sheet('piso_caminho', 64, 64, nil))
    put('arena', Kit.sheet('piso_arena', 64, 64, nil))
    put('parede', Kit.sheet('parede', 64, 96, nil))
    put('porta', Kit.sheet('parede_porta', 64, 96, nil))
    put('pilar', Kit.sheet('pilar', 64, 96, nil))
    -- Borda de transição de terreno (W5): overlay direcional por vizinho;
    -- só existe se o def do Traço estiver assado (senão, sem overlay).
    local tb = Kit.bakeViaDSL('piso_terra_borda')
    if tb then s.trans_terra = tb; s.trans_terra_q = Kit.quads(tb) end
    -- Decal de uso do Traço (terra_mancha 128x128): textura por BLOCO,
    -- não por célula — posições seedadas por contexto do mapa.
    s.mancha = Kit.bakeViaDSL('terra_mancha')
    if s.mancha then s.mancha_q = Kit.quads(s.mancha) end
    put('propStub', Kit.stubSheet(64, 96, propStub))
    put('actorStub', Kit.stubSheet(64, 96, actorStub))
    for _, dir in ipairs({'s', 'n', 'e', 'w'}) do
        put('viajante_' .. dir, Kit.sheet(
            dir == 's' and 'viajante' or 'viajante_' .. dir, 64, 96, nil))
        put('walk_' .. dir, Kit.sheet('viajante_walk_' .. dir, 64, 96, nil))
        put('npc_' .. dir, Kit.sheet('npc_doro_' .. dir, 64, 96, actorStub))
        -- Pilotos de ação do Cinzel (W4): tiro direcional com âncoras.
        put('tiro_' .. dir, Kit.sheet('viajante_tiro_' .. dir, 64, 96, nil))
    end
    s.interacao = Kit.sheet('viajante_interacao', 64, 96, actorStub)
    s['interacao_q'] = Kit.quads(s.interacao)
    -- fx_* da Tinta: spawns via feedback.lua → Fx.draw por canal (já
    -- integrado abaixo no channel) — não bakear aqui também.
    s.propCache = {}
    s.qcache = setmetatable({}, {__mode = 'v'})
    self._sheets = s
    return s
end

-- Quads memoizados por sheet (I5): Kit.quads alocava a tabela por
-- entidade × canal × frame — um cache por sheet corta o churn.
local function quadsOf(s, sheet)
    local q = s.qcache[sheet]
    if not q then
        q = Kit.quads(sheet)
        s.qcache[sheet] = q
    end
    return q
end

-- Fachada dedicada por id de casa (ficha do Pátio × defs do Traço):
-- a def casa_<papel> cobre a face sul inteira da massa no passo dela.
local CASA_FACHADA = {
    camasCasa = 'casa_pensao', capelaCasa = 'casa_capela',
    cozinhaCasa = 'casa_cozinha', escolaCasa = 'casa_escola',
    forjaCasa = 'casa_forja',
}

-- Figurantes ambientes por mapa (apresentação só — sem colisão/sim;
-- a Botica pediu "+figurante" nas cenas de vida). Âncora em célula.
local FIGURANTES = {
    hub = {
        {sprite = 'npc_jardineiro_s', x = 8, y = 19, fps = 4},
        {sprite = 'npc_jardineiro_trabalho', x = 5, y = 23, fps = 4},
        {sprite = 'sit_contemplacao', x = 26, y = 34.8, fps = 3},
        {sprite = 'varanda_ocupada', x = 32, y = 18, fps = 3,
            topleft = true},
    },
}

-- Props com animação ambiental (loop, não variante por seed).
local ANIM_PROPS = {
    fumaca_chamine = 5, varal_vento = 4.5, vela_votiva_anim = 5,
    velas = 4, tocha = 6, brasa_forja = 5, braseiro = 5,
}

local function propQuad(self, s, prop)
    -- Ordem: mapa explícito (id, kind) → tenta o próprio id/kind como def —
    -- o Traço nomeia a maioria das defs pelo kind da ficha.
    local defName = PROP_SPRITE[prop.id] or PROP_SPRITE[prop.kind]
    local c
    if defName then
        c = s.propCache[defName]
        if c == nil then
            c = Kit.bakeViaDSL(defName) or false
            s.propCache[defName] = c
        end
        -- Estado de gameplay (W5): <def>_<state> vence quando existe —
        -- braseiro_quiet/varal_vento_quiet cobrem 'quiet'; 'lit'/'done'
        -- sem def própria caem no def base (que já é o estado aceso).
        if prop.state then
            local sn = defName .. '_' .. prop.state
            local sc = s.propCache[sn]
            if sc == nil then
                sc = Kit.bakeViaDSL(sn) or false
                s.propCache[sn] = sc
            end
            if sc then c = sc end
        end
    else
        c = s.propCache[prop.id]
        if c == nil then
            -- snakeCase do id cobre ids de feitio: bancoSerra → banco_serra
            local snake = prop.id and prop.id:gsub('%u', function(c)
                return '_' .. c:lower() end)
            c = Kit.bakeViaDSL(prop.id)
                or (snake and Kit.bakeViaDSL(snake))
                or Kit.bakeViaDSL(prop.kind) or false
            s.propCache[prop.id] = c
        end
    end
    if not c then return s.propStub, s.propStub_q[1] end
    local qs = quadsOf(s, c)
    local fps = ANIM_PROPS[defName]
    if fps and #qs > 1 then
        local ph = (prop.x or 0) * .37 + (prop.y or 0) * .11
        return c, qs[1 + math.floor((self.time or 0) * fps + ph) % #qs]
    end
    return c, qs[1]
end

local function entityQuad(self, s, ent, t)
    if ent.enemy then return s.actorStub, s.actorStub_q[1] end
    local dir = dirSuffix(ent.facing)
    if ent.player then
        local moving = ent.motion and (ent.motion.remaining or 0) > 0
        -- Piloto de tiro do Cinzel: arco em 'charging'/'ready' troca para
        -- viajante_tiro_<dir> — fase prep(1)→saque(2)→contato(3).
        local wpn = ent.weapon
        if wpn and (wpn.state == 'charging' or wpn.state == 'ready')
            and not moving then
            local sh = s['tiro_' .. dir]
            if not sh.stub then
                local qs = s['tiro_' .. dir .. '_q']
                local fr = wpn.state == 'ready' and 3
                    or math.min(2, 1 + math.floor((wpn.charge or 0) * 2))
                return sh, qs[math.min(fr, #qs)]
            end
        end
        local key = moving and s['walk_' .. dir] and 'walk_' .. dir
            or 'viajante_' .. dir
        local sh, qs = s[key], s[key .. '_q']
        local n = #qs
        local f = moving and (1 + math.floor(t * 9) % n)
            or (n > 1 and 1 + math.floor(t * 2) % n or 1)
        return sh, qs[math.min(f, n)]
    end
    -- NPC real por id: 'npc_<id>_trabalho' (gesto de ofício do Traço) tem
    -- prioridade — a cena de vida pede o ator TRABALHANDO, não parado.
    -- Sem trabalho assado cai no idle direcional, depois doro, depois stub.
    local npcId = ent.npc and ent.npc.id
    local sh, qs
    if npcId then
        for _, key in ipairs({'npc_' .. npcId .. '_trabalho',
                              'npc_' .. npcId .. '_' .. dir}) do
            local c = s.propCache[key]
            if c == nil then
                c = Kit.bakeViaDSL(key) or false
                s.propCache[key] = c
            end
            if c then sh, qs = c, quadsOf(s, c); break end
        end
    end
    if not sh then
        -- Figurante: família de trabalho por hash do id — gestos variados
        -- (Aurel cuida, Doro martela, Sabela escreve, Bento mexe a panela)
        -- sem clonar o mesmo boneco. 'sit/play/watch' ficam no idle doro.
        local workActs = {hammer = 1, chop = 1, tend = 1, write = 1,
            stir = 1, wash = 1, weed = 1, fill = 1, carry = 1, help = 1,
            sweep = 1, tinker = 1, serve = 1}
        local act = ent.npc and ent.npc.act
        if act and workActs[act] then
            local fam = {'doro', 'aurel', 'sabela', 'bento', 'nilo', 'teca'}
            local who = fam[1 + math.floor(Kit.hash(
                #(npcId or 'f') * 7, 13, 31) * 5.99)]
            local key = 'npc_' .. who .. '_trabalho'
            local c = s.propCache[key]
            if c == nil then
                c = Kit.bakeViaDSL(key) or false
                s.propCache[key] = c
            end
            if c then sh, qs = c, quadsOf(s, c) end
        end
    end
    if not sh then
        sh, qs = s['npc_' .. dir], s['npc_' .. dir .. '_q']
    end
    if sh.stub then return s.actorStub, s.actorStub_q[1] end
    local n = #qs
    local f = n > 1 and 1 + math.floor(t * 5 + (ent.grid and ent.grid.x or 0)) % n or 1
    return sh, qs[math.min(f, n)]
end

local function ensureBuffers(self, w, h)
    local hd = self.hd
    if hd and hd.w == w and hd.h == h then return end
    hd = hd or {}
    self.hd = hd
    hd.w, hd.h = w, h
    for _, k in ipairs({'bufA', 'bufN', 'bufE'}) do
        if hd[k] then hd[k]:release() end
        hd[k] = G.newCanvas(w, h, {dpiscale = 1})
        hd[k]:setFilter('nearest', 'nearest')
    end
    hd.lighting = hd.lighting or Lighting.new(w, h)
    -- Mapa real tem ~100 occluders: 1.25× mantém borda macia dentro do
    -- orçamento de frame (as cenas técnicas ficam no adaptativo default).
    hd.lighting.lightScale = 1.25
    hd.lighting._lsFixed = true
    hd.lighting:resize(w, h)
    hd.postfx = hd.postfx or PostFX.new()
    hd.postfx:resize(w, h)
end

-- Chão: laje na praça do Refúgio com manchas de terra agrupadas (~3
-- células) — hash por célula lia como xadrez; hash por bloco agrupa.
-- Chão por região: praça de laje com terra no Refúgio, grama com terra
-- na Colina, laje em interiores, terra como default de mundo aberto.
-- Caminho pintado: map.paths = polilinhas em célula (Traço/Pátio) — a
-- rua pintada segue a rua carveada. Mesma regra do legado (pixel_scene):
-- distância ao segmento < w*16 px-32, principal +5.
-- Distância normalizada à rota mais próxima: 0 = eixo, ~1 = borda da
-- faixa pintada; nil fora de toda rota. Serve ao floorKind ('caminho')
-- e ao contexto de variante do Traço (trilha só na zona de uso).
local function pathFrac(map, x, y)
    local polys = map.paths
    if not polys then return nil end
    local px, py = (x - .5) * 32, (y - .5) * 32
    local best
    for _, poly in ipairs(polys) do
        local half = (poly.w or 2.6) * 16 + (poly.main and 5 or 0)
        for j = 2, #poly do
            local ax, ay = (poly[j-1][1] - .5) * 32, (poly[j-1][2] - .5) * 32
            local bx, by = (poly[j][1] - .5) * 32, (poly[j][2] - .5) * 32
            local vx, vy = bx - ax, by - ay
            local len2 = vx * vx + vy * vy
            if len2 > 0 then
                local f = math.max(0, math.min(1,
                    ((px - ax) * vx + (py - ay) * vy) / len2))
                local dx, dy = px - ax - vx * f, py - ay - vy * f
                local d2 = dx * dx + dy * dy
                if not best or d2 < best then best = d2 end
            end
        end
    end
    if not best then return nil end
    return math.sqrt(best) / 43 -- meia-largura média (2.7*16 px-32)
end

-- Roteamento do piso_caminho (9 frames do Traço): devolve o vetor do
-- segmento sob a célula + flags de forma — 'cap' perto de ponta da
-- polilinha, 'junction' onde duas rotas se cruzam, curva perto de vértice
-- interno (com quadrante NE/SE/SW/NW pelo balanço in+out).
local function pathInfo(map, x, y)
    local polys = map.paths
    if not polys then return nil end
    local px, py = (x - .5) * 32, (y - .5) * 32
    local best, seg
    local hits = 0
    for _, poly in ipairs(polys) do
        local half = (poly.w or 2.6) * 16 + (poly.main and 5 or 0)
        for j = 2, #poly do
            local ax, ay = (poly[j-1][1] - .5) * 32, (poly[j-1][2] - .5) * 32
            local bx, by = (poly[j][1] - .5) * 32, (poly[j][2] - .5) * 32
            local vx, vy = bx - ax, by - ay
            local len2 = vx * vx + vy * vy
            if len2 > 0 then
                local f = math.max(0, math.min(1,
                    ((px - ax) * vx + (py - ay) * vy) / len2))
                local dx, dy = px - ax - vx * f, py - ay - vy * f
                local d2 = dx * dx + dy * dy
                if d2 < half * half then
                    hits = hits + 1
                    if not best or d2 < best.d2 then
                        best = {d2 = d2, f = f, vx = vx, vy = vy,
                            j = j, n = #poly, jn = j}
                    end
                end
            end
        end
    end
    if not best then return nil end
    local info = {vx = best.vx, vy = best.vy, junction = hits > 1}
    -- ponta: extremo dos segmentos 1..2 ou n-1..n colados na célula
    if (best.j == 2 and best.f < .25) or (best.j == best.n and best.f > .75)
        then info.cap = true end
    -- vértice interno: junção entre segmentos j-1/j dentro de ~0.8 cél
    if best.f > .8 and best.j < best.n then info.turn = true
        info.qx, info.qy = best.vx, best.vy
    elseif best.f < .2 and best.j > 2 then info.turn = true
        info.qx, info.qy = best.vx, best.vy end
    return info
end

local function onPath(map, x, y)
    local f = pathFrac(map, x, y)
    return f ~= nil and f < 1
end

-- beirada (Traço f3): tufos junto a parede/sombra de fachada. Pré-
-- computado uma vez por mapa — tiles/props não mudam no draw.
local beiradaCache = setmetatable({}, {__mode = 'k'})
local function beiradaSet(map)
    local set = beiradaCache[map]
    if set then return set end
    set = {}
    for key, tile in pairs(map.tiles or {}) do
        if tile.piece then
            local x, y = key:match('(%-?%d+):(%-?%d+)')
            x, y = tonumber(x), tonumber(y)
            for _, o in ipairs({{0,-1},{1,0},{0,1},{-1,0}}) do
                set[(x + o[1]) .. ':' .. (y + o[2])] = true
            end
        end
    end
    for _, prop in ipairs(map.props or {}) do
        if (prop.w or 1) > 1 or prop.kind == 'casa' then
            local south = prop.y + (prop.h or 1) - 1
            for cx = prop.x - 1, prop.x + (prop.w or 1) do
                set[cx .. ':' .. south] = true
                set[cx .. ':' .. (south + 1)] = true
            end
        end
    end
    beiradaCache[map] = set
    return set
end

local floorKind -- forward: manchaOverlay classifica por piso.

-- Superfície de zona (ficha do Pátio) → sheet de piso. Só kinds com
-- sheet assada entram — superfície desconhecida cai no mix da região.
local ZONE_SURFACE = {stone = 'laje', grass = 'grama', gravel = 'terra',
    earth = 'terra'}

-- Decals de textura por região (Traço, terra_mancha): posições seedadas
-- — f1/f2 desgaste junto a exits/paths/polos (bancada, marco), f3 seixo
-- na beira de muro, f4 tufos sob fachada, f5 umidade junto a água, f6
-- faixa longa. Miolo quieto fica limpo. Topleft, px-64.
local POLOS = {bancada = 1, banco = 1, bancoMadeira = 1, bancoPedra = 1,
    bancoSerra = 1, mesa = 1, marco = 1, bigorna = 1}
local AGUA = {poco = 1, cisterna = 1, canaleta = 1}
local manchaCache = setmetatable({}, {__mode = 'k'})
local function manchaOverlay(map)
    local L = manchaCache[map]
    if L then return L end
    L = {}
    local set = beiradaSet(map)
    local exits = map.exits or {}
    -- polos de uso e pontos de água
    local polos, aguas = {}, {}
    for _, pr in ipairs(map.props or {}) do
        if POLOS[pr.kind] or POLOS[pr.id] then
            polos[#polos + 1] = {x = pr.x + (pr.w or 1) / 2,
                y = pr.y + (pr.h or 1)}
        elseif AGUA[pr.kind] then
            aguas[#aguas + 1] = {x = pr.x + (pr.w or 1) / 2,
                y = pr.y + (pr.h or 1)}
        end
    end
    local function near(list, x, y, d2)
        for _, p in ipairs(list) do
            local dx, dy = p.x - x, p.y - y
            if dx * dx + dy * dy < d2 then return true end
        end
    end
    -- candidatos: células de terra a cada 2 (o decal cobre 2×2)
    for key, tile in pairs(map.tiles or {}) do
        local x, y = key:match('(%-?%d+):(%-?%d+)')
        x, y = tonumber(x), tonumber(y)
        if tile.ground ~= 'hole' and not tile.piece
            and floorKind(map, x, y) == 'terra' and (x + y) % 2 == 0 then
            local pf = pathFrac(map, x, y)
            local h = Kit.hash(x, y, 61)
            local fr
            if near(exits, x, y, 6) or near(polos, x, y, 6)
                or (pf and pf < 1.4) then
                fr = h < .55 and 1 or 2              -- desgaste de uso
            elseif pf and pf < 2.1 then
                fr = h < .5 and 2 or 6               -- margem/faixa longa
            elseif set[x .. ':' .. y] then
                fr = h < .55 and 3 or 4              -- seixo/tufos no muro
            elseif near(aguas, x, y, 8) then
                fr = 5                               -- umidade
            end
            if fr and h > .18 then -- ~18% dos pontos ficam sem mancha
                L[#L + 1] = {frame = fr,
                    x = (x - 1) * CELL - 12, y = (y - 1) * CELL - 20}
            end
        end
    end
    manchaCache[map] = L
    return L
end

floorKind = function(map, x, y)
    local id = map.id
    if onPath(map, x, y) then return 'caminho' end
    -- Superfície autoral da zona (Pátio): stone/grass/gravel decidem o
    -- piso onde a ficha as declara; fora de zona, o mix por hash segue.
    for _, z in ipairs(map.zones or {}) do
        if x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h then
            local zk = ZONE_SURFACE[z.surface]
            if zk then return zk end
        end
    end
    if id == 'hub' then
        return Kit.hash(math.floor(x / 3), math.floor(y / 3), 21) < .30
            and 'terra' or 'laje'
    elseif id == 'colina' then
        return Kit.hash(x, y, 22) < .55 and 'grama' or 'terra'
    elseif id == 'oficinas' or id == 'mercado' or id == 'reservatorio'
        or id == 'saloes' or id == 'fundacao' then
        return 'laje'
    end
    return map.outdoor and 'terra' or 'laje'
end

-- Memoização por mapa: floorKind/pathFrac/pathInfo são puras de dados
-- estáticos (tiles/paths não mudam durante o draw). Sem isso cada célula
-- reavaliava ~35 segmentos de rota por canal — ~30k varreduras por frame.
-- Nil precisa de sentinela (false); pathInfo devolve tabela viva que os
-- consumidores só leem. Mesmo padrão de cache fraco de beirada/mancha.
local geoCache = setmetatable({}, {__mode = 'k'})
local function geoMemo(map)
    local c = geoCache[map]
    if not c then
        c = {frac = {}, info = {}, kind = {}}
        geoCache[map] = c
    end
    return c
end

local pathFracRaw, pathInfoRaw, floorKindRaw = pathFrac, pathInfo, floorKind
pathFrac = function(map, x, y)
    local c = geoMemo(map).frac
    local k = x .. ':' .. y
    local v = c[k]
    if v == nil then
        v = pathFracRaw(map, x, y) or false
        c[k] = v
    end
    return v or nil
end
pathInfo = function(map, x, y)
    local c = geoMemo(map).info
    local k = x .. ':' .. y
    local v = c[k]
    if v == nil then
        v = pathInfoRaw(map, x, y) or false
        c[k] = v
    end
    return v or nil
end
floorKind = function(map, x, y)
    local c = geoMemo(map).kind
    local k = x .. ':' .. y
    local v = c[k]
    if v == nil then
        v = floorKindRaw(map, x, y)
        c[k] = v
    end
    return v
end

-- Occluders derivados de tiles (muros em fileiras + pilares): geometria
-- estática do mapa — assada uma vez por mapa, reutilizada por frame.
local occCache = setmetatable({}, {__mode = 'k'})
local function tileOccluders(map)
    local o = occCache[map]
    if o then return o end
    o = {}
    local wallRuns = {}
    for _, tile in pairs(map.tiles or {}) do
        if tile.piece == 'wall' or tile.piece == 'portal' then
            wallRuns[#wallRuns + 1] = tile
        end
    end
    table.sort(wallRuns, function(a, b)
        return a.y < b.y or (a.y == b.y and a.x < b.x) end)
    local run = nil
    for _, tile in ipairs(wallRuns) do
        local px, py = (tile.x - 1) * CELL, (tile.y - 1) * CELL
        if run and py == run.y and px == run.x + run.w then
            run.w = run.w + CELL
        else
            if run then
                o[#o + 1] = {x = run.x, y = run.y - 20, w = run.w,
                    h = 60, height = 192}
            end
            run = {x = px, y = py, w = CELL}
        end
    end
    if run then
        o[#o + 1] = {x = run.x, y = run.y - 20, w = run.w,
            h = 60, height = 192}
    end
    for _, tile in pairs(map.tiles or {}) do
        if tile.piece == 'pillar' then
            o[#o + 1] = {x = (tile.x - 1) * CELL + 16,
                y = (tile.y - 1) * CELL + 44, w = 32, h = 16, height = 150}
        end
    end
    occCache[map] = o
    return o
end

-- Prop caster → occluder (mesma forma usada no passe por frame e no bake
-- da máscara do sol). cy de shadowCaster vem em px-32 → *2 = px-64.
local function propCasterOcc(prop)
    local cx, cy, w2, hgt = Props.shadowCaster(prop)
    if not cx then return nil end
    return {x = (prop.x - 1) * CELL, y = cy * 2 - 8,
        w = (prop.w or 1) * CELL, h = 16, height = hgt * 2}
end

-- Máscara de sombra da dominante (sol) por mapa — megaplan §3.3 "máscara
-- assada por fonte estática". Tiles + casters ativos entram no bake; se a
-- contagem de casters muda (prop 'taken'), re-assa uma vez. Retorna nil
-- sem GPU/shader — o sol cai no caminho vivo de shadow quads.
local sunMaskCache = setmetatable({}, {__mode = 'k'})
local function sunMaskFor(L, map)
    if not L.enabled then return nil end
    local m = sunMaskCache[map]
    local sig = 0
    for _, prop in ipairs(map.props or {}) do
        if Props.shadowCaster(prop) then sig = sig + 1 end
    end
    if m == false then return nil end -- bake falhou antes: fica na sombra viva
    if m and m.sig == sig then return m end
    if m and m.canvas then m.canvas:release() end
    local occ = {}
    for _, o in ipairs(tileOccluders(map)) do occ[#occ + 1] = o end
    for _, prop in ipairs(map.props or {}) do
        local po = propCasterOcc(prop)
        if po then occ[#occ + 1] = po end
    end
    local sunRef = {x = -640, y = map.h * CELL + 560, z = 460}
    local baked = L:bakeShadowMask(sunRef, occ,
        -2 * CELL, -2 * CELL, (map.w + 4) * CELL, (map.h + 4) * CELL, 0.5)
    if not baked then
        sunMaskCache[map] = false
        return nil
    end
    baked.sig = sig
    sunMaskCache[map] = baked
    return baked
end

function HDWorld.draw(renderer, campaign, v, map, shake)
    local tFrame = love.timer.getTime()
    shake = shake or {0, 0}
    ensureBuffers(renderer, v.w, v.h)
    local hd = renderer.hd
    local s = sheetsFor(renderer)
    local t = renderer.time or 0
    local region = map.id or 'neutro'
    local prevCanvas = G.getCanvas()

    -- Camada por profundidade: tiles com peça (muro/pilar/portal), props e
    -- entidades, mesma ordem de pintor do render legado.
    local tFill = love.timer.getTime()
    -- Células da vista + margem: peças altas (~96px sobre o pé) e decals
    -- encostam na borda sem piscar. A lista de células visíveis substitui
    -- a varredura do hash inteiro do mapa em cada um dos 3 canais.
    local PAD = 2
    local vL, vT = v.left, v.top
    local vR, vB = v.left + v.w, v.top + v.h
    local cx0 = math.max(1, math.floor(vL / CELL) + 1 - PAD)
    local cx1 = math.min(map.w or 1, math.ceil(vR / CELL) + PAD)
    local cy0 = math.max(1, math.floor(vT / CELL) + 1 - PAD)
    local cy1 = math.min(map.h or 1, math.ceil(vB / CELL) + PAD)
    local pieces = {}
    local tilesInView = {}
    if map.tiles then
        for y = cy0, cy1 do
            for x = cx0, cx1 do
                local tile = map.tiles[x .. ':' .. y]
                if tile then
                    tilesInView[#tilesInView + 1] = tile
                    if tile.piece then
                        pieces[#pieces + 1] = {kind = 'tile', t2 = tile,
                            depth = tile.y * CELL, sx = tile.x * CELL}
                    end
                end
            end
        end
    end
    for _, prop in ipairs(map.props or {}) do
        if prop.state ~= 'taken' and not Props.bakesToGround(prop) then
            -- AABB do footprint + 2 cél p/ cima: sprites de 96px ancorados
            -- no pé invadem a vista pela borda inferior.
            local px0 = (prop.x - 1) * CELL
            local px1 = (prop.x + (prop.w or 1) - 1) * CELL
            local py0 = (prop.y - 1) * CELL - 2 * CELL
            local py1 = (prop.y + (prop.h or 1) - 1) * CELL + CELL
            if px1 > vL and px0 < vR and py1 > vT and py0 < vB then
                pieces[#pieces + 1] = {kind = 'prop', p = prop,
                    depth = (prop.y + (prop.h or 1) - 1) * CELL,
                    sx = prop.x * CELL}
            end
        end
    end
    for i, fig in ipairs(FIGURANTES[map.id] or {}) do
        local fx, fy = fig.x * CELL, fig.y * CELL
        if fx + CELL > vL and fx - CELL < vR
            and fy + CELL > vT and fy - 2 * CELL < vB then
            pieces[#pieces + 1] = {kind = 'fig', fig = fig,
                depth = fig.y * CELL, sx = fig.x * CELL, i = i}
        end
    end
    for _, ent in ipairs(campaign:entities()) do
        local fx, fy = visualPos(ent)
        local px, py = fx * 2, fy * 2
        if px + 96 > vL and px - 96 < vR
            and py + CELL > vT and py - 2 * CELL < vB then
            pieces[#pieces + 1] = {kind = 'ent', e = ent,
                depth = py, sx = fx, fx = px, fy = py}
        end
    end
    table.sort(pieces, function(a, b)
        return a.depth < b.depth or (a.depth == b.depth and a.sx < b.sx)
    end)

    local CLEAR = {
        albedo = {.045, .055, .075, 1},
        normal = {.5, .5, 1, 1},
        emissive = {0, 0, 0, 0},
    }
    local function channel(ch)
        local buf = ch == 'albedo' and hd.bufA or ch == 'normal' and hd.bufN
            or hd.bufE
        G.setCanvas(buf); G.clear(unpack(CLEAR[ch])); G.setColor(1, 1, 1, 1)
        -- Céu dusk do Refúgio (Calina, padrão-ouro): faixa lavanda→creme
        -- cobrindo o void norte do mapa inteiro — pano de fundo, nunca
        -- disputa com info de gameplay. Duas camadas de skyline dentro:
        -- cordilheira distante (lavanda escura) e telhados/chaminés do
        -- povoado (tinta) — sem as silhuetas a banda lê como listra (Mira).
        -- Só albedo: o sol a tinge, a dominante não projeta sombra.
        if ch == 'albedo' and map.outdoor then
            -- Céu/silhuetas cobrem só a faixa da vista — mesmo desenho,
            -- sem rasterizar o mapa inteiro.
            local x0 = math.floor((vL - CELL) / CELL) * CELL
            local x1 = vR + CELL
            local horizon = 2.45 * CELL
            -- céu: lavanda alta → rosa → creme-areia no horizonte
            -- Gradiente mais alto (iteração Mira): 7 faixas, topo mais
            -- frio — o void norte inteiro é céu, não faixa fina.
            local bands = {
                {.44, .38, .58}, {.52, .45, .65}, {.60, .52, .71},
                {.70, .60, .75}, {.79, .68, .76}, {.86, .76, .74},
                {.93, .85, .72},
            }
            local top = -8 * CELL
            for i, c in ipairs(bands) do
                G.setColor(c[1], c[2], c[3], 1)
                local y = top + (i - 1) * (horizon - top) / #bands
                G.rectangle('fill', x0, y, x1 - x0,
                    (horizon - top) / #bands + 1)
            end
            -- Cordilheiras em duas profundidades: a mais longe, pálida e
            -- alta (nevoeiro do vale); a próxima, escura e baixa, colada
            -- no horizonte. Dá escala ao vale sem roubar a cena.
            G.setColor(.55, .50, .66, .9)
            for x = x0, x1, CELL do
                local h = (0.6 + Kit.hash(math.floor(x / CELL), 3, 17)
                    * 1.5) * CELL
                G.rectangle('fill', x, horizon - h, CELL + 1, h)
            end
            G.setColor(.42, .36, .55, 1)
            for x = x0, x1, CELL / 2 do
                local h = (0.10 + Kit.hash(math.floor(x / CELL), 3, 17)
                    * .45) * CELL
                G.rectangle('fill', x, horizon - h, CELL / 2 + 1, h)
            end
            -- Telhados/chaminés do povoado: silhueta em tinta SENTADA na
            -- linha do horizonte — casa = corpo baixo + cumeeira de duas
            -- águas; ritmo irregular, mais denso junto ao eixo do povoado.
            local ink = {.13, .11, .18}
            local x = x0 + CELL
            while x < x1 - CELL do
                local hh = (0.22 + Kit.hash(x, 7, 29) * .5) * CELL
                local bw = CELL * (0.7 + Kit.hash(x, 11, 31) * .8)
                G.setColor(ink[1], ink[2], ink[3], 1)
                G.rectangle('fill', x, horizon - hh, bw, hh)
                -- cumeeira em dois degraus (duas águas)
                G.rectangle('fill', x + bw * .25, horizon - hh - 6,
                    bw * .5, 6)
                if Kit.hash(x, 5, 41) < .3 then
                    G.rectangle('fill', x + bw * .2, horizon - hh - 16,
                        6, 16)
                end
                x = x + bw + CELL * (.4 + Kit.hash(x, 13, 37) * 1.1)
            end
            -- Fio de mar/vale: brilho fino logo acima do parapeito.
            G.setColor(.80, .88, .92, .8)
            G.rectangle('fill', x0, horizon, x1 - x0, 5)
            G.setColor(1, 1, 1, 1)
        end
        for _, tile in ipairs(tilesInView) do
            if tile.ground ~= 'hole' then
                local kind = floorKind(map, tile.x, tile.y)
                local sh = s[kind]
                local px, py = (tile.x - 1) * CELL, (tile.y - 1) * CELL
                local qi = Kit.variant(sh, tile.x, tile.y)
                -- Contexto do Traço (piso_terra v5):
                --   f4 trilha — zona de uso (perto de rota pintada/exit)
                --   f3 beirada — encosta de parede ou sombra de fachada
                --   f1/f2    — campo quieto
                if kind == 'terra' and sh.frames >= 4 then
                    local pf = pathFrac(map, tile.x, tile.y)
                    local used = pf ~= nil and pf < 1.9
                    if not used then
                        for _, ex in ipairs(map.exits or {}) do
                            local dx, dy = ex.x - tile.x, ex.y - tile.y
                            if dx * dx + dy * dy < 2.5 then
                                used = true break
                            end
                        end
                    end
                    if used then qi = 4
                    elseif beiradaSet(map)[tile.x .. ':' .. tile.y] then qi = 3
                    else qi = 1 + Kit.variant(sh, tile.x, tile.y) % 2 end
                elseif kind == 'caminho' and sh.frames >= 9 then
                    -- 9 frames direcionais (Traço): f1 h, f2 v,
                    -- f3-6 curvas NE/SE/SW/NW, f7 T, f8 cruzamento, f9 cap.
                    local info = pathInfo(map, tile.x, tile.y)
                    if info then
                        if info.junction then qi = 8
                        elseif info.cap then qi = 9
                        elseif info.turn then
                            local q = (info.qx > 0 and 'E' or 'W')
                                .. (info.qy > 0 and 'S' or 'N')
                            qi = ({ES = 4, EN = 3, WS = 5, WN = 6})[q] or 1
                        else
                            qi = math.abs(info.vx) > math.abs(info.vy)
                                and 1 or 2
                        end
                    end
                end
                G.draw(sh[ch], s[kind .. '_q'][qi], px, py)
                -- Transição de terreno (W5): vizinho com overlay invade a
                -- aresta — terra sobre laje, nunca o contrário. Cantos
                -- internos (2 vizinhos ortogonais iguais) usam frame de
                -- canto; arestas soltas usam frame direcional n/e/s/w.
                local dir = {}
                for d, o in ipairs({{0, -1}, {1, 0}, {0, 1}, {-1, 0}}) do
                    local nk = floorKind(map, tile.x + o[1], tile.y + o[2])
                    if nk ~= kind and s['trans_' .. nk]
                        and not s['trans_' .. kind] then
                        dir[d] = nk
                    end
                end
                local usado = {}
                for _, c in ipairs({{1, 2, 5}, {4, 1, 6}, {2, 3, 7}, {3, 4, 8}}) do
                    if dir[c[1]] and dir[c[1]] == dir[c[2]] then
                        G.draw(s['trans_' .. dir[c[1]]][ch],
                            s['trans_' .. dir[c[1]] .. '_q'][c[3]], px, py)
                        usado[c[1]], usado[c[2]] = true, true
                    end
                end
                for d, nk in pairs(dir) do
                    if not usado[d] then
                        G.draw(s['trans_' .. nk][ch],
                            s['trans_' .. nk .. '_q'][d], px, py)
                    end
                end
            end
        end
        -- Decals de uso: acima do piso, abaixo de props/pieces.
        if s.mancha then
            for _, d in ipairs(manchaOverlay(map)) do
                if d.x + 128 > vL and d.x < vR
                    and d.y + 128 > vT and d.y < vB then
                    G.draw(s.mancha[ch], s.mancha_q[d.frame], d.x, d.y)
                end
            end
        end
        for _, p in ipairs(pieces) do
            if p.kind == 'tile' then
                local tile = p.t2
                local key = tile.piece == 'pillar' and 'pilar'
                    or tile.piece == 'portal' and 'porta' or 'parede'
                local sh = s[key]
                G.draw(sh[ch],
                    s[key .. '_q'][Kit.variant(sh, tile.x, tile.y)],
                    (tile.x - 1) * CELL, (tile.y - 1) * CELL - (sh.h - CELL))
            elseif p.kind == 'prop' then
                local sh, q = propQuad(renderer, s, p.p)
                local prop = p.p
                if prop.kind == 'casa' then
                    -- Casa multi-tile (Traço): telhado cobre o miolo da
                    -- massa em faixas de 2 cél; fachada fecha a face sul —
                    -- nunca o stub por célula (grade de caixas, Mira r3).
                    local w, h = prop.w or 1, prop.h or 1
                    local px0 = (prop.x - 1) * CELL
                    local pyTop = (prop.y - 1) * CELL
                    local pyBot = (prop.y + h - 1) * CELL
                    -- Fachada dedicada por id (ficha do Pátio × Traço):
                    -- casa_<papel> quando a def existe; senão a faixa a/b
                    -- genérica. O passo vem da largura assada da def.
                    local fName = CASA_FACHADA[prop.id]
                    local fach
                    if fName then
                        fach = s.propCache[fName]
                        if fach == nil then
                            fach = Kit.bakeViaDSL(fName) or false
                            s.propCache[fName] = fach
                        end
                        if fach == false then fach = nil end
                    end
                    local step = fach and fach.w or 128
                    -- telhado: fileiras 64px da crista até a fresta da fachada
                    local fachH = 96
                    for _, k in ipairs({'casa_telhado', 'casa_fachada_a',
                        'casa_fachada_b'}) do
                        if s.propCache[k] == nil then
                            s.propCache[k] = Kit.bakeViaDSL(k) or false
                        end
                    end
                    local tel = s.propCache['casa_telhado']
                    if tel then
                        local tq = quadsOf(s, tel)[1]
                        for r = 0, h * CELL / 64 - 1 do
                            local ry = pyTop + r * 64
                            if ry + 64 > pyBot - fachH + 32 then break end
                            for cx = 0, math.ceil(w / 2) - 1 do
                                G.draw(tel[ch], tq, px0 + cx * 128, ry)
                            end
                        end
                    end
                    for cx = 0, math.ceil(w * CELL / step) - 1 do
                        local c = fach
                        if not c then
                            c = s.propCache[cx % 2 == 0
                                and 'casa_fachada_a' or 'casa_fachada_b']
                        end
                        if c then
                            G.draw(c[ch], quadsOf(s, c)[1],
                                px0 + cx * step, pyBot - c.h)
                        end
                    end
                elseif sh.stub and ((prop.w or 1) > 1 or (prop.h or 1) > 1) then
                    -- Massa real do placeholder: prop multi-célula sem def
                    -- repete por célula COM jitter por hash — a grade de
                    -- caixas 4×4 do quintal lia como tabuleiro (Mira r3);
                    -- o deslocamento quebra o alinhamento sem mover o sim.
                    for cx = 0, (prop.w or 1) - 1 do
                        for cy = 0, (prop.h or 1) - 1 do
                            local jx = (Kit.hash(prop.x + cx, prop.y + cy, 7)
                                - .5) * 14
                            local jy = (Kit.hash(prop.x + cx, prop.y + cy, 19)
                                - .5) * 10
                            Kit.drawFeet(sh, q, ch,
                                (prop.x + cx - 1) * CELL + CELL / 2 + jx,
                                (prop.y + cy) * CELL + jy)
                        end
                    end
                else
                    Kit.drawFeet(sh, q, ch,
                        (prop.x - 1) * CELL + (prop.w or 1) * CELL / 2,
                        (prop.y + (prop.h or 1) - 1) * CELL)
                end
            elseif p.kind == 'fig' then
                -- Figurante ambiente (apresentação só — Botica pediu
                -- "+figurante" nas cenas de vida): DSL por nome, gesto
                -- em loop na âncora da planta.
                local fig = p.fig
                local c = s.propCache[fig.sprite]
                if c == nil then
                    c = Kit.bakeViaDSL(fig.sprite) or false
                    s.propCache[fig.sprite] = c
                end
                if c then
                    local qs = quadsOf(s, c)
                    local fr = 1 + math.floor(t * (fig.fps or 4)
                        + fig.x * .7) % #qs
                    if fig.topleft then
                        G.draw(c[ch], qs[fr],
                            (fig.x - 1) * CELL, (fig.y - 1) * CELL)
                    else
                        Kit.drawFeet(c, qs[fr], ch,
                            fig.x * CELL - CELL / 2, fig.y * CELL)
                    end
                end
            else
                local sh, q = entityQuad(renderer, s, p.e, t)
                if ch == 'albedo' then
                    -- Sombra de contato: mancha estável sob os pés, segue
                    -- a posição visual — nunca re-projeta nem cintila.
                    G.setColor(.033, .046, .071, .34)
                    G.ellipse('fill', p.fx, p.fy - 2, 15, 5)
                    G.setColor(1, 1, 1, 1)
                end
                Kit.drawFeet(sh, q, ch, p.fx, p.fy)
            end
        end
    end
    channel('albedo'); channel('normal'); channel('emissive')
    G.setCanvas(prevCanvas)
    local fillMs = (love.timer.getTime() - tFill) * 1000

    -- Luzes: ambiente da região + sol (outdoor) + âncoras de fogo dos props.
    local L = hd.lighting
    L:beginFrame()
    if map.outdoor then
        L:setAmbient(Kit.ambient(region))
        -- Dominante por região (DIRECAO_AMBIENTAL): Refúgio pôr-do-sol
        -- âmbar do SO; Colina é crepúsculo — lume alto, pálido e frio.
        local sun = ({
            hub = {c = {1.0, .76, .44}, i = 6.5},
            refugio = {c = {1.0, .76, .44}, i = 6.5},
            colina = {c = {.62, .70, 1.0}, i = 3.2},
        })[region] or {c = {1.0, .76, .44}, i = 6.5}
        -- Sol projeta via máscara assada (§3.3): as sombras longas para NE
        -- da especificação ambiental sem custo de occluder por frame. Sem
        -- máscara (falha de bake/GPU) a mesma fonte projeta ao vivo.
        L:addLight({x = -640, y = map.h * CELL + 560, z = 460,
            color = sun.c, intensity = sun.i, radius = 8600,
            shadow = true, mask = sunMaskFor(L, map), prio = 0})
    else
        -- Interior sem dominante: o ambiente É a luz — frio-neutro legível
        -- (escuro legível != preto, Calina), os pools de brasa aquecem.
        L:setAmbient({.42, .41, .46})
    end
    -- Mapa de luzes do Pátio (layout-refugio-hd §6): vivas = fogo real e
    -- piscam suave (≤2 por tela); quietas = janela/lampião/jade, estáveis.
    -- Coordenadas em célula do mapa 54×40, z/raio já em px-64.
    local HUB_LIGHTS = map.id == 'hub' and {
        {x = 24, y = 6, c = {1.0, .55, .22}, i = 1.7, r = 260, z = 92,
            flicker = {amp = .05, speed = 4, phase = .3}},        -- braseiro
        {x = 22, y = 19, c = {1.0, .62, .30}, i = 1.2, r = 192, z = 110}, -- lampião
        {x = 21, y = 17.4, c = {.25, .85, .70}, i = .65, r = 173, z = 80}, -- jade
        {x = 28, y = 16, c = {1.0, .72, .38}, i = .8, r = 160, z = 120}, -- janela pensão
        {x = 31, y = 16, c = {1.0, .72, .38}, i = .7, r = 160, z = 120}, -- janela 2
        {x = 15, y = 25.5, c = {1.0, .72, .38}, i = .7, r = 160, z = 120}, -- varanda
        {x = 50, y = 25, c = {1.0, .50, .20}, i = 1.2, r = 192, z = 92,
            flicker = {amp = .05, speed = 5, phase = 2.4}},       -- brasa forja
    } or nil
    -- Cull de luz: fora da vista (margem de 1 raio) nem entra na lista.
    local vL, vT = v.left, v.top
    local vR, vB = v.left + v.w, v.top + v.h
    local function lightVisible(x, y, r)
        return x + r > vL and x - r < vR and y + r > vT and y - r < vB
    end
    if HUB_LIGHTS then
        for _, ls in ipairs(HUB_LIGHTS) do
            local lx, ly = ls.x * CELL - 32, ls.y * CELL - 32
            if lightVisible(lx, ly, ls.r) then
                -- Só as 2 vivas projetam (Mira perdeu o drama junto ao
                -- braseiro): drama curto perto do fogo, quietas ficam fora.
                L:addLight({x = lx, y = ly, z = ls.z,
                    color = ls.c, intensity = ls.i, radius = ls.r,
                    flicker = ls.flicker,
                    shadow = ls.flicker ~= nil})
            end
        end
    end
    for _, prop in ipairs(map.props or {}) do
        local ax, ay, tint, r = Props.lightAnchor(prop)
        if ax then
            -- Sem duplicar: âncoras próximas do mapa do Pátio já estão
            -- representadas (o braseiro do mirante é o mesmo (24,6)).
            local dup = false
            if HUB_LIGHTS then
                for _, ls in ipairs(HUB_LIGHTS) do
                    local dx = ax * 2 - (ls.x * CELL - 32)
                    local dy = ay * 2 - (ls.y * CELL - 32)
                    if dx * dx + dy * dy < 96 * 96 then dup = true break end
                end
            end
            if not dup and lightVisible(ax * 2, ay * 2,
                    math.max((r or 14) * 2, 140)) then
                -- Flicker suave: brasas respiram ~5% — ±12% a 6-7Hz lia
                -- como estroboscopia na praça (bug reportado).
                L:addLight({x = ax * 2, y = ay * 2, z = 92,
                    color = tint and {tint[1], tint[2], tint[3]}
                        or {1.0, .58, .24},
                    intensity = 1.6, radius = math.max((r or 14) * 2, 140),
                    flicker = {amp = .05, speed = 4, phase = prop.x * 1.7},
                    shadow = false, prio = 3})
            end
        end
    end
    -- Occluder só se coleta quando alguma luz projeta AO VIVO — a
    -- dominante carrega máscara assada (não precisa do passe) e as
    -- quietas têm shadow=false. Sobram os fogos com flicker.
    local wantsShadow = false
    for _, l in ipairs(L.lights) do
        if l.shadow ~= false and not l.mask then wantsShadow = true break end
    end
    -- Occluders: muros (merge em fileiras), pilares, props com altura.
    -- Só coleta quando alguma luz ainda projeta. A parte de tiles é
    -- estática do mapa — cacheada (o sort de ~200 muros saía por frame);
    -- props seguem por frame porque prop.state pode mudar ('taken').
    if wantsShadow then
    L:addOccluders(tileOccluders(map))
    for _, prop in ipairs(map.props or {}) do
        local cx, cy, w2, hgt = Props.shadowCaster(prop)
        if cx then
            L:addOccluder({x = (prop.x - 1) * CELL, y = cy * 2 - 8,
                w = (prop.w or 1) * CELL, h = 16, height = hgt * 2})
        end
    end
    end
    -- Atores NÃO lançam sombra projetada (política Vespa): a sombra do
    -- jogador re-projetava a cada frame de movimento e cintilava junto à
    -- luz. Todo ator recebe só a mancha de contato desenhada no albedo.
    L:update(t, renderer.reducedMotion)

    local P = hd.postfx
    P:setRegion(region)
    P:setVignette(.16)
    P:beginScene()
    L:compose(hd.bufA, hd.bufN, hd.bufE, v.left - (shake[1] or 0),
        v.top - (shake[2] or 0))
    P:endScene()
    P:setEmissive(hd.bufE)
    -- O translate da câmera segue ativo: present desenha em px de canvas.
    G.push('all'); G.origin()
    G.setCanvas(prevCanvas)
    P:present(0, 0, 1)
    G.pop()
    -- Mesma leitura de custo das cenas técnicas: passe de luz + bloom.
    -- fill= cobre o preenchimento do G-buffer (pieces + 3 canais); frame=
    -- é o draw inteiro — o log precisava ver o custo fora do compose.
    hd.fillMs = (hd.fillMs or 0) * .9 + fillMs * .1
    hd.frameMs = (hd.frameMs or 0) * .9
        + (love.timer.getTime() - tFrame) * 100 -- (x*1000)*.1
    hd.statsClock = (hd.statsClock or 0) + 1
    if hd.statsClock >= 90 then
        hd.statsClock = 0
        print(string.format('[hd_world] frame=%.1fms fill=%.1fms light=%.3fms bloom=%.3fms lights=%d occluders=%d shadowQuads=%d fmt=%s',
            hd.frameMs, hd.fillMs,
            (L.stats and L.stats.lightPassMs) or 0,
            (P.stats and P.stats.bloomMs) or 0,
            (L.stats and L.stats.lights) or 0,
            (L.stats and L.stats.occluders) or 0,
            (L.stats and L.stats.shadowQuads) or 0,
            (P.stats and P.stats.format) or '?'))
    end

    -- UI de mundo por cima da imagem composta: letreiros de destino,
    -- prompt de interação e clima de região — os três desenham em px-64
    -- (o translate da câmera ainda mapeia mundo→vista).
    HDWorld.overlay(renderer, campaign, v, map)
end

-- ── Overlay de mundo (doorTags, prompt E·, clima) — paridade com o fim
-- da worldCampaign legada, mas em células de 64px. Só leitura de estado.
local function color(c, a) G.setColor(c[1], c[2], c[3], a or c[4] or 1) end

local atmoTone = {
    oficinas = {deep = PixelWorld.palette.goldDeep, accent = Pal.ember},
    mercado = {deep = PixelWorld.palette.goldDark,
        accent = Pal.regions.mercado.wood.base},
    reservatorio = {deep = PixelWorld.palette.jadeDeep, accent = Pal.sky.mid},
    saloes = {deep = PixelWorld.palette.violetDark,
        accent = PixelWorld.palette.rust},
    hub = {deep = PixelWorld.palette.goldDeep, accent = Pal.gold.light},
    colina = {deep = PixelWorld.palette.violetDeep, accent = Pal.violet},
}

local INK = {.033, .046, .071}

-- Escreve texto 2× (a vista HD tem scale 1 — o tag de px-32 encolhia).
local function drawTag(renderer, x, y, tag, tint, sign, pal)
    local font = renderer.worldFonts.tiny
    local tw = font:getWidth(tag)
    -- Lookup de cores ANTES do push: qualquer indexação nula aqui não pode
    -- deixar push sem pop (desbalanceio já derrubou o draw inteiro).
    local wd, wb, wl = pal.wood.dark, pal.wood.base, pal.wood.light
    G.push('all')
    G.translate(math.floor(x - tw), math.floor(y))
    G.scale(2, 2)
    if sign then
        color(INK, .9); G.rectangle('fill', -4, -2, tw + 8, 11)
        color(wd); G.rectangle('fill', -3, -1, tw + 6, 9)
        color(wb); G.rectangle('fill', -3, -1, tw + 6, 1)
        color(wl); G.rectangle('fill', -3, 8, tw + 6, 1)
        color(INK); G.rectangle('fill', -2, 0, 1, 1)
        G.rectangle('fill', tw + 2, 0, 1, 1)
        G.setFont(font); color(Pal.emberLight)
        G.print(PixelFont.clean(tag), 0, 1)
    else
        color(INK, .8); G.rectangle('fill', -3, -1, tw + 6, 9)
        color(tint, .8); G.rectangle('fill', -3, -2, tw + 6, 1)
        G.setFont(font); color(tint)
        G.print(PixelFont.clean(tag), 0, 0)
    end
    G.pop()
end

local function drawPrompt(renderer, x, y, label)
    local font = renderer.worldFonts.tiny
    local fw = font:getWidth(label)
    G.push('all')
    G.translate(math.floor(x - fw - 3), math.floor(y - 54))
    G.scale(2, 2)
    color(INK, .9); G.rectangle('fill', 0, 0, fw + 6, 11)
    color(Pal.gold.light, .7)
    G.setLineWidth(1); G.rectangle('line', .5, .5, fw + 5, 10)
    G.setFont(font); color(Pal.gold.light)
    G.print(label, 3, 2)
    G.pop()
end

function HDWorld.overlay(renderer, campaign, v, map)
    local pal = PixelScene.palette(map)
    local tone = atmoTone[map.id]
        or {deep = PixelWorld.palette.stoneDeep, accent = Pal.stone.base}
    -- Vinheta de clima presa ao rect estrito do mapa (px-64).
    local x0 = math.max(v.left, 0)
    local y0 = math.max(v.top, 0)
    local x1 = math.min(v.left + v.w, map.w * CELL)
    local y1 = math.min(v.top + v.h, map.h * CELL)
    if x1 > x0 and y1 > y0 then
        local vw, vh = x1 - x0, y1 - y0
        color(tone.deep, .10); G.rectangle('fill', x0, y0, vw, 24)
        color(tone.deep, .07); G.rectangle('fill', x0, y0, 40, vh)
        color(tone.deep, .07); G.rectangle('fill', x1 - 40, y1 - 72, 40, 72)
        color(tone.accent, .06); G.rectangle('fill', x0, y0, vw, 12)
        local function contentAt(x, y)
            return map.tiles[(math.floor(x / CELL) + 1) .. ':'
                .. (math.floor(y / CELL) + 1)] ~= nil
        end
        if contentAt(x0 + 24, y0 + 24) then
            PixelArt.halo(x0, y0, 60, 44, tone.deep, .28) end
        if contentAt(x1 - 24, y0 + 24) then
            PixelArt.halo(x1, y0, 60, 44, tone.deep, .28) end
        if contentAt(x0 + 24, y1 - 24) then
            PixelArt.halo(x0, y1, 52, 40, tone.deep, .24) end
        if contentAt(x1 - 24, y1 - 24) then
            PixelArt.halo(x1, y1, 52, 40, tone.deep, .24) end
    end
    -- Poças de luz das âncoras não vêm: as âncoras JÁ são luzes reais
    -- do lightmap — desenhá-las de novo dobraria o brilho.

    -- Letreiros de portal (mesma regra de coleta do legado, px-64).
    if (v.scale or 1) >= 1 then
        for i, door in ipairs(map.doors or {}) do
            if door.label and (not door.hidden or door.revealed) then
                local tag = door.label
                local open = campaign:canLeave(door)
                if not open then tag = tag .. ' · FECHADA' end
                local sign
                for _, prop in ipairs(map.props or {}) do
                    local pw, ph = prop.w or 1, prop.h or 1
                    if prop.solid and door.x >= prop.x
                        and door.x < prop.x + pw
                        and door.y - 1 >= prop.y
                        and door.y - 1 < prop.y + ph then
                        sign = true; break
                    end
                end
                local tint = open
                    and (door.finish and Pal.gold.light or Pal.jade.base)
                    or Pal.gold.dark
                drawTag(renderer,
                    (door.x - .5) * CELL,
                    (door.y - 1) * CELL - 40 - (i % 3) * 18
                        - (sign and 8 or 0),
                    tag, tint, sign, pal)
            end
        end
    end

    -- Prompt E·FALAR/EXAMINAR — mesmo seletor do legado.
    if campaign.state == 'playing' and not campaign.dialogue
        and campaign.scene == 'explore' then
        local target = campaign:interactTarget()
        if target and (target.kind == 'npc' or target.kind == 'talker') then
            local npc = target.obj
            drawPrompt(renderer, (npc.grid.x - .5) * CELL,
                (npc.grid.y - .5) * CELL, 'E · FALAR')
        elseif target then
            local spot = target.obj
            drawPrompt(renderer, (spot.x - .5) * CELL,
                (spot.y - .5) * CELL, 'E · ' .. spot.label)
        end
    end
end

-- ── Batalha (Fase 4): a arena tática pelo mesmo G-buffer/luz/HDR. ────

-- kind de inimigo → def DSL do Traço ('foe_crawler', 'foe_dasher', ...).
local function foeQuad(self, s, ent, t)
    local kind = ent.enemy and ent.enemy.kind
    local dir = dirSuffix(ent.facing)
    -- Chefes têm sheets direcionais ('boss_runa_s'); comuns são 'foe_kind'.
    local key = kind and ('boss_' .. kind .. '_' .. dir)
    local c = key and s.propCache[key]
    if c == nil and key then
        c = Kit.bakeViaDSL(key) or false
        s.propCache[key] = c
    end
    if not c then
        key = 'foe_' .. (kind or '')
        c = s.propCache[key]
        if c == nil then
            c = kind and Kit.bakeViaDSL(key) or nil
            s.propCache[key] = c or false
        end
    end
    if not c then return s.actorStub, s.actorStub_q[1] end
    local qs = quadsOf(s, c)
    local n = #qs
    -- Estado 'warn'/'dash'/'volley' pina o último frame (postura de
    -- telegrafo do Traço); idle cicla os demais — o frame de warn não
    -- pisca no meio do repouso (B1).
    local a = ent.enemy
    local warned = a and (a.state == 'warn' or a.state == 'dash'
        or a.state == 'volley')
    if warned then return c, qs[n] end
    local idle = n > 1 and n - 1 or 1
    return c, qs[1 + math.floor(t * 2) % idle]
end

-- Chão da arena por região de origem: laje de refúgio, terra do resto —
-- a borda do tabuleiro delimita a área jogável (ground 'hole' = vazio).
local function battleFloor(region, x, y)
    -- piso_arena (Traço) dentro do tabuleiro, sempre — a arena é um lugar
    -- próprio, não o piso da região ao redor.
    return 'arena'
end

-- Offsets de apresentação da batalha, replicados do legado
-- (Render:actor): o poupado desliza e esmaece ~1.4s; o lunge empurra
-- na direção do golpe; o hit treme a vítima; jump sobe os pés.
-- Nunca lê regra — só apresentação, em px-64 (offsets legados ×2).
local function battleDrawPos(renderer, e)
    local R = package.loaded['src.render']
    local x, y, jump = R.visualPosition(e)
    local alpha
    if e.spared then
        if not e.spareT or e.spareT >= 1.4 then return nil end
        x = x + e.spareT * 40
        y = y - e.spareT * 10
        alpha = math.max(0, 1 - e.spareT / 1.4)
    end
    if not renderer.reducedMotion then
        if e.lunge and e.lunge.remaining > 0 then
            local lt = 1 - e.lunge.remaining / e.lunge.duration
            local push = math.sin(lt * math.pi) * 9
            x, y = x + e.lunge.dx * push, y + e.lunge.dy * push
        end
        if e.shake and e.shake.remaining > 0 then
            local st = e.shake.remaining / e.shake.duration
            x = x + math.sin((e.shake.duration - e.shake.remaining)
                * 95) * 3 * st
        end
    else jump = 0 end
    return x * 2, y * 2 - (jump or 0) * 2, alpha
end

function HDWorld.drawBattle(renderer, campaign, v, map, battle, shake)
    shake = shake or {0, 0}
    ensureBuffers(renderer, v.w, v.h)
    local hd = renderer.hd
    local s = sheetsFor(renderer)
    local t = renderer.time or 0
    local R = package.loaded['src.render']
    local BD = R.BattleDraw
    local prevCanvas = G.getCanvas()
    local region = (battle.snapshot and battle.snapshot.region) or 'neutro'
    local pulse = renderer.reducedMotion and 0 or math.sin(t * 5) * .05
    local C = {ink = {.033, .046, .071}, jade = Pal.jade.light,
        gold = Pal.gold.light, red = Pal.danger, white = {1, 1, 1},
        text = {.90, .92, .89}}

    -- Moldura do tabuleiro: mesmo cálculo de borda do legado, em px-32 —
    -- tudo do overlay corre em px-32 dentro de um scale(2).
    local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
    for _, tile in pairs(map.tiles or {}) do
        if tile.ground == 'floor' and not tile.protected then
            x1, y1 = math.min(x1, tile.x), math.min(y1, tile.y)
            x2, y2 = math.max(x2, tile.x), math.max(y2, tile.y)
        end
    end
    local f = {x = (x1 - 1) * 32, y = (y1 - 1) * 32,
        w = (x2 - x1 + 1) * 32, h = (y2 - y1 + 1) * 32}

    -- ── Camadas: decalques táticos (telegrafos/marcadores) em px-32 com
    -- scale(2) → a mesma leitura do legado, só maior. Emissivo recebe a
    -- mesma forma com tinta reduzida: o aviso brilha na sombra sem bloom.
    local function decals(tintMul)
        G.push('all')
        G.scale(2, 2)
        -- I4: no canal emissivo as tintas passam reduzidas — a forma brilha
        -- na sombra sem cruzar o threshold do bloom (~0.35).
        local function tc(c)
            if tintMul >= 1 then return c end
            return {c[1] * tintMul, c[2] * tintMul, c[3] * tintMul}
        end
        -- Anel de alvo dos modos sociais (act/actlist/mercy).
        if battle.mode == 'act' or battle.mode == 'actlist'
            or battle.mode == 'mercy' then
            local list = battle.mode == 'mercy' and battle:spareable()
                or battle:liveEnemies()
            local idx = battle.mode == 'mercy' and battle.mercyIndex
                or battle.actTarget
            local u = list and list[math.max(1, math.min(#list, idx or 1))]
            if u then
                local tin = battle.mode == 'mercy' and C.jade or C.gold
                local cx0, cy0 = (u.grid.x - 1) * 32, (u.grid.y - 1) * 32
                color(tin, (.18 + pulse * .1) * tintMul)
                G.rectangle('fill', cx0, cy0, 32, 32)
                color(tin, tintMul)
                G.rectangle('fill', cx0 - 1, cy0 - 1, 10, 2)
                G.rectangle('fill', cx0 - 1, cy0 - 1, 2, 10)
                G.rectangle('fill', cx0 + 23, cy0 - 1, 10, 2)
                G.rectangle('fill', cx0 + 31, cy0 - 1, 2, 10)
                G.rectangle('fill', cx0 - 1, cy0 + 31, 10, 2)
                G.rectangle('fill', cx0 - 1, cy0 + 23, 2, 10)
                G.rectangle('fill', cx0 + 23, cy0 + 31, 10, 2)
                G.rectangle('fill', cx0 + 31, cy0 + 23, 2, 10)
            end
        end
        -- Hazards + telegrafos real-time (o bloco canônico do legado).
        for _, e in ipairs(battle:entities()) do
            if e.hazard then
                local prog = 1 - e.hazard.timer / (e.hazard.duration or 1)
                for _, cell in ipairs(e.hazard.cells) do
                    BD.warningCell(cell, tc(C.gold), 0, 0, prog, false, 'blast')
                end
            end
        end
        for _, e in ipairs(battle.enemies or {}) do
            local a = e.enemy
            if e.health.current > 0 and a
                and (a.state == 'warn' or a.state == 'dash'
                    or a.state == 'volley') then
                local progress = a.state ~= 'warn' and 1
                    or 1 - a.timer / (a.warningDuration or 1)
                local tint2 = tc(BD.warnTint[a.mode] or C.red)
                for i, cell in ipairs(a.cells) do
                    if a.state ~= 'dash' or i >= (a.dashIndex or 1) then
                        local dx, dy, kind = BD.warnCellSpec(a, e, cell, i)
                        BD.warningCell(cell, tint2, dx, dy, progress,
                            false, kind)
                        for _, fc in ipairs(cell.fall or {}) do
                            BD.warningCell(fc, tc(C.jade), a.dx or 0, a.dy or 0,
                                progress, false, 'fall')
                        end
                    end
                end
                if a.state == 'warn' and a.mode == 'push' and a.crateX then
                    local cx0, cy0 = (a.crateX - 1) * 32, (a.crateY - 1) * 32
                    BD.border(cx0 + 2, cy0 + 2, 28, 28, tint2,
                        .5 + progress * .4)
                    BD.arrow(cx0 + 16 + (a.pushDx or 0) * 9,
                        cy0 + 16 + (a.pushDy or 0) * 9,
                        a.pushDx or 0, a.pushDy or 0, tint2, 3)
                end
                if a.state == 'warn' and a.mode == 'shove' and a.cells[1] then
                    local lastc = a.cells[#a.cells]
                    local lx, ly = (lastc.x - 1) * 32, (lastc.y - 1) * 32
                    color(tint2)
                    if (a.dx or 0) ~= 0 then
                        G.rectangle('fill',
                            lx + (a.dx > 0 and 25 or 4), ly + 6, 3, 20)
                    else
                        G.rectangle('fill', lx + 6,
                            ly + (a.dy > 0 and 25 or 4), 20, 3)
                    end
                end
            end
        end
        -- Marcadores sob os pés (glifo do estado) + saída de fuga + losango
        -- da jogadora — decalques de chão, leem na sombra via emissivo.
        for _, e in ipairs(battle.enemies or {}) do
            if e.health.current > 0 and e.enemy then
                local gx, gy = (e.grid.x - .5) * 32,
                    (e.grid.y - .5) * 32 + 13
                local a = e.enemy
                local kind, _, tint3 = BD.enemyReadout(e)
                tint3 = tc(tint3)
                if kind == 'dash' or kind == 'demolish' then
                    BD.chevron(gx + (a.dx or 0) * 3, gy + (a.dy or 0) * 3,
                        a.dx or 0, a.dy or 0, tint3)
                elseif kind == 'shoot' then
                    color(tint3)
                    BD.pixelLine(gx - 5, gy, gx - 2, gy)
                    BD.pixelLine(gx + 2, gy, gx + 5, gy)
                    BD.pixelLine(gx, gy - 5, gx, gy - 2)
                    BD.pixelLine(gx, gy + 2, gx, gy + 5)
                    G.rectangle('fill', gx, gy, 1, 1)
                elseif kind == 'move' then
                    color(tint3)
                    G.rectangle('fill', gx - 3, gy - 2, 2, 3)
                    G.rectangle('fill', gx + 1, gy, 2, 3)
                elseif kind == 'sow' then
                    BD.thornTip(gx, gy + 3, 4, tint3)
                elseif kind == 'ritual' or kind == 'burst' then
                    color(tint3)
                    if kind == 'burst' then
                        BD.pixelLine(gx - 3, gy - 3, gx + 3, gy + 3)
                        BD.pixelLine(gx + 3, gy - 3, gx - 3, gy + 3)
                    else
                        BD.pixelLine(gx - 3, gy, gx + 3, gy)
                        BD.pixelLine(gx, gy - 3, gx, gy + 3)
                    end
                elseif kind == 'hammer' or kind == 'push' or kind == 'jet'
                    or kind == 'shove' then
                    BD.intentGlyph(kind, gx - 3, gy - 3, tint3)
                else
                    BD.diamond(gx, gy, 3, tint3)
                end
            end
        end
        local exits = {}
        if battle.fleeing and battle.exitCell then
            exits[#exits + 1] = {cell = battle.exitCell,
                edge = battle.flee and battle.flee.edge}
        end
        for _, e in ipairs(battle.enemies or {}) do
            local a = e.enemy
            if a and a.state == 'flee' and a.exitCell then
                exits[#exits + 1] = {cell = a.exitCell, edge = a.exitEdge}
            end
        end
        for _, ex in ipairs(exits) do
            if tintMul >= 1 then BD.fleeExitMark(ex.cell, ex.edge, f, pulse) end
        end
        local pgm = (battle.player.grid.x - .5) * 32
        local pgmy = (battle.player.grid.y - .5) * 32 + 13
        BD.diamond(pgm, pgmy, 5, C.ink)
        BD.diamond(pgm, pgmy, 4, tc(C.jade))
        BD.diamond(pgm, pgmy - 1, 1, tc(C.white))
        G.pop()
    end

    -- ── G-buffer ──
    local pieces = {}
    for _, tile in pairs(map.tiles or {}) do
        if tile.piece == 'pillar' or tile.piece == 'crate' then
            pieces[#pieces + 1] = {kind = 'tile', t2 = tile,
                depth = tile.y * CELL, sx = tile.x * CELL}
        end
    end
    -- Posições de apresentação (lunge/shake/jump/poupado) — B2/I3.
    local pfx, pfy = battleDrawPos(renderer, battle.player)
    pieces[#pieces + 1] = {kind = 'ent', e = battle.player,
        depth = pfy, sx = pfx, fx = pfx, fy = pfy}
    for _, e in ipairs(battle.enemies or {}) do
        local fx, fy, alpha = battleDrawPos(renderer, e)
        if fx then
            pieces[#pieces + 1] = {kind = 'ent', e = e,
                depth = fy, sx = fx, fx = fx, fy = fy, alpha = alpha}
        end
    end
    table.sort(pieces, function(a, b)
        return a.depth < b.depth or (a.depth == b.depth and a.sx < b.sx)
    end)

    local CLEAR = {
        albedo = {.045, .055, .075, 1},
        normal = {.5, .5, 1, 1},
        emissive = {0, 0, 0, 0},
    }
    local function channel(ch)
        local buf = ch == 'albedo' and hd.bufA or ch == 'normal' and hd.bufN
            or hd.bufE
        G.setCanvas(buf); G.clear(unpack(CLEAR[ch])); G.setColor(1, 1, 1, 1)
        for _, tile in pairs(map.tiles or {}) do
            if tile.ground == 'floor' then
                local kind = battleFloor(region, tile.x, tile.y)
                local sh = s[kind]
                G.draw(sh[ch], s[kind .. '_q'][Kit.variant(sh, tile.x, tile.y)],
                    (tile.x - 1) * CELL, (tile.y - 1) * CELL)
            end
        end
        -- Meio-fio do tabuleiro: pedra simples lit, braseiros DSL nas bordas
        -- (a chama vem do emissivo do sprite — o bloom cuida do resto).
        if ch == 'albedo' then
            local st = Pal.stone
            color(st.dark); G.rectangle('fill',
                f.x * 2 - 16, f.y * 2 - 16, f.w * 2 + 32, f.h * 2 + 32)
            color(st.base); G.rectangle('fill',
                f.x * 2 - 14, f.y * 2 - 14, f.w * 2 + 28, f.h * 2 + 28)
            color(st.light); G.rectangle('fill',
                f.x * 2 - 14, f.y * 2 - 14, f.w * 2 + 28, 4)
            G.rectangle('fill', f.x * 2 - 14, f.y * 2 - 14, 4, f.h * 2 + 28)
            -- O tabuleiro é um lugar: laje mais escura e fechada dentro do
            -- meio-fio — separa "arena" do chão vivo em volta.
            color(C.ink, .34)
            G.rectangle('fill', f.x * 2, f.y * 2, f.w * 2, f.h * 2)
            color(C.ink, .5)
            G.rectangle('fill', f.x * 2 - 2, f.y * 2 - 2, f.w * 2 + 4, 4)
            G.rectangle('fill', f.x * 2 - 2, f.y * 2 - 2, 4, f.h * 2 + 4)
        end
        if not s.brazier then
            s.brazier = Kit.sheet('braseiro', 64, 96, nil)
            s.brazier_q = Kit.quads(s.brazier)
        end
        if not s.tocha then
            s.tocha = Kit.sheet('tocha', 64, 96, nil)
            s.tocha_q = Kit.quads(s.tocha)
        end
        for _, sgn in ipairs({-1, 1}) do
            local bx = sgn == -1 and f.x * 2 - 14 or (f.x + f.w) * 2 + 14
            local by = (f.y + f.h / 2) * 2
            Kit.drawFeet(s.brazier, s.brazier_q[1], ch, bx, by + 8)
            -- Tochas nos cantos superiores da moldura (loop de chama).
            local tq = s.tocha_q[1 + math.floor(
                (renderer.time or 0) * 6 + sgn) % #s.tocha_q]
            Kit.drawFeet(s.tocha, tq, ch,
                sgn == -1 and (f.x - 12) * 2 or (f.x + f.w + 12) * 2,
                (f.y + 2) * 2)
        end
        if ch ~= 'normal' then decals(ch == 'emissive' and .30 or 1) end
        for _, p in ipairs(pieces) do
            if p.kind == 'tile' then
                local tile = p.t2
                if tile.piece == 'pillar' then
                    local sh = s.pilar
                    G.draw(sh[ch], s.pilar_q[1], (tile.x - 1) * CELL,
                        (tile.y - 1) * CELL - (sh.h - CELL))
                else
                    local sh = s.propCache.caixas_antigas
                    if sh == nil then
                        sh = Kit.bakeViaDSL('caixas_antigas') or false
                        s.propCache.caixas_antigas = sh
                    end
                    local sheet = sh or s.propStub
                    local qs = sh and Kit.quads(sh) or s.propStub_q
                    G.draw(sheet[ch], qs[1], (tile.x - 1) * CELL,
                        (tile.y - 1) * CELL + CELL - sheet.h)
                end
            else
                local sh, q
                if p.e == battle.player then
                    local dir = dirSuffix(p.e.facing)
                    local moving = p.e.motion
                        and (p.e.motion.remaining or 0) > 0
                    local key = moving and s['walk_' .. dir] and 'walk_' .. dir
                        or 'viajante_' .. dir
                    sh = s[key]
                    local qs = s[key .. '_q']
                    local n = #qs
                    q = qs[moving and (1 + math.floor(t * 9) % n)
                        or (n > 1 and 1 + math.floor(t * 2) % n or 1)]
                else
                    sh, q = foeQuad(renderer, s, p.e, t)
                end
                if p.alpha then G.setColor(1, 1, 1, p.alpha) end
                if ch == 'albedo' then
                    color(C.ink, .34)
                    G.ellipse('fill', p.fx, p.fy - 2, 15, 5)
                    color({1, 1, 1})
                end
                Kit.drawFeet(sh, q, ch, p.fx, p.fy)
                if p.alpha then G.setColor(1, 1, 1, 1) end
            end
        end
        -- FX autorados (W6): sheets DSL sobre os atores, por canal — o
        -- emissivo entra no bufE e floresce no postfx junto com o resto.
        if renderer.feedback and renderer.feedback.fx then
            Fx.draw(renderer.feedback.fx, ch)
        end
    end
    channel('albedo'); channel('normal'); channel('emissive')
    G.setCanvas(prevCanvas)

    -- Luzes: ambiente da região + os dois braseiros da moldura.
    local L = hd.lighting
    L:beginFrame()
    -- Arena de tocha (refaço): o ambiente fica baixo e neutro — quem
    -- descreve o lugar são os pools de fogo. As unidades modelam por
    -- normal map; o tabuleiro não vira "xadrez azul".
    L:setAmbient({.17, .15, .19})
    local cx, cy = (f.x + f.w / 2) * 2, (f.y + f.h / 2) * 2
    -- Lume cerimonial alto sobre o tabuleiro — quente, modela as
    -- unidades de frente sem apagar os telegrafos de chão.
    L:addLight({x = cx, y = cy - 90, z = 240, color = {1.0, .74, .44},
        intensity = 3.4, radius = f.w * 2 + 300, shadow = false})
    -- Braseiros de flanco + tochas nos cantos da moldura: os pools de
    -- fogo desenham a arena como lugar, não como tabuleiro iluminado.
    for _, sgn in ipairs({-1, 1}) do
        local bx = sgn == -1 and f.x * 2 - 18 or (f.x + f.w) * 2 + 18
        local by = (f.y + f.h / 2) * 2
        L:addLight({x = bx, y = by - 20, z = 92, color = {1.0, .55, .22},
            intensity = 2.2, radius = 420,
            flicker = {amp = .06, speed = 4.5, phase = sgn * 2}})
        L:addLight({x = sgn == -1 and (f.x - 14) * 2 or (f.x + f.w + 14) * 2,
            y = (f.y - 10) * 2, z = 110, color = {1.0, .58, .25},
            intensity = 1.6, radius = 360,
            flicker = {amp = .05, speed = 4, phase = sgn * 3.1}})
    end
    -- Fill frontal frio e raso: separa unidade do fundo escuro — a face
    -- sul de cada peça lê sem perder o drama do fogo.
    L:addLight({x = cx, y = cy + f.h + 40, z = 130, color = {.55, .62, .82},
        intensity = 1.1, radius = f.w * 2 + 160, shadow = false})
    -- Occluders: pilares/caixotes + unidades.
    for _, tile in pairs(map.tiles or {}) do
        if tile.piece == 'pillar' then
            L:addOccluder({x = (tile.x - 1) * CELL + 16,
                y = (tile.y - 1) * CELL + 44, w = 32, h = 16, height = 150})
        elseif tile.piece == 'crate' then
            L:addOccluder({x = (tile.x - 1) * CELL + 8,
                y = (tile.y - 1) * CELL + 48, w = 48, h = 12, height = 56})
        end
    end
    -- Atores NÃO lançam sombra projetada (política Vespa): a sombra do
    -- jogador re-projetava a cada frame de movimento e cintilava junto à
    -- luz. Todo ator recebe só a mancha de contato desenhada no albedo.
    L:update(t, renderer.reducedMotion)

    local P = hd.postfx
    P:setRegion(region)
    P:setVignette(.16)
    P:beginScene()
    L:compose(hd.bufA, hd.bufN, hd.bufE, v.left - (shake[1] or 0),
        v.top - (shake[2] or 0))
    P:endScene()
    P:setEmissive(hd.bufE)
    G.push('all'); G.origin()
    G.setCanvas(renderer.canvas)
    P:present(0, 0, 1)
    G.pop()

    -- ── Pós-compose: o translate da câmera segue ativo e aplica DEPOIS
    -- do scale — desenhar em px-32 sob scale(2) cai exato no mundo de 64.
    -- Grade, mortes, efeitos, motes, balões, marcadores e projéteis ficam
    -- nítidos por cima da imagem iluminada (camada de informação).
    G.push('all')
    G.scale(2, 2)
    -- Grade do tabuleiro: informação tática mas sutil — o mandato pede
    -- "arena que lê como lugar", não xadrez.
    color(C.ink, .15)
    for _, tile in pairs(map.tiles or {}) do
        if tile.ground == 'floor' and not tile.protected then
            G.rectangle('line', (tile.x - 1) * 32 + .5, (tile.y - 1) * 32 + .5,
                31, 31)
        end
    end
    renderer.actors:drawDeaths(renderer, campaign)
    -- Projéteis do mundo (flechas/bolts) — mesmo painter do legado.
    for _, e in ipairs(battle:entities()) do
        if e.projectile then renderer:projectile(e) end
    end
    renderer:effects()
    -- Brasas à deriva sobre a arena (mesma fórmula do legado).
    if not renderer.reducedMotion then
        for i = 1, 14 do
            local bx = f.x + ((i * 53) % f.w)
            local by = f.y + ((i * 37) % f.h)
            local mx = bx + math.sin(t * .7 + i * 1.9) * 6
            local my = by + math.sin(t * .5 + i * 2.3) * 4
                - (t * 2.2 + i * 9) % 16
            local dc = math.sqrt((bx - (f.x + f.w / 2)) ^ 2
                + (by - (f.y + f.h / 2)) ^ 2)
            local a = math.max(0, .34 - dc / (f.w * .55))
                * (math.sin(t * 1.1 + i * 1.3) * .5 + .5)
            if a > .03 then
                color(i % 3 == 0 and Pal.gold.light or Pal.jade.light, a)
                G.rectangle('fill', BD.round(mx), BD.round(my),
                    i % 4 == 0 and 2 or 1, 1)
            end
        end
    end
    -- Balões de fala (barks): mesma placa do legado, sob scale(2).
    local font = renderer.worldFonts.tiny
    for _, e in ipairs(battle.enemies or {}) do
        if e.barkText and e.health.current > 0
            and (not e.spared or (e.spareT and e.spareT < 1.4)) then
            local tw = font:getWidth(e.barkText)
            local bw = math.min(88, tw + 10)
            local _, wrapped = font:getWrap(e.barkText, bw - 10)
            local lines = math.max(1, #wrapped)
            local bh = 8 + lines * 6
            local ux, uy = R.visualPosition(e)
            if e.spareT then ux = ux + e.spareT * 40 end
            local bx = math.max(f.x + 4,
                math.min(f.x + f.w - bw - 4, BD.round(ux - bw / 2)))
            local warned = e.enemy and (e.enemy.state == 'warn'
                or e.enemy.state == 'dash' or e.enemy.state == 'volley')
            local by = math.max(f.y + 4,
                BD.round(uy - (warned and 66 or 62) - (lines - 1) * 6))
            local a = e.barkT and math.min(1, e.barkT / .4) or 1
            local PW = PixelWorld.palette
            if e.barkVerbal == false then
                BD.border(bx, by, bw, bh, PW.bone, .9 * a)
                color(PW.bone, .9 * a)
                G.rectangle('fill', bx + 3, by + bh, 3, 1)
                G.rectangle('fill', bx + 5, by + bh + 1, 2, 1)
                BD.text(font, e.barkText, bx + 5, by + 3, PW.bone, bw - 10)
            else
                color(C.ink, .92 * a); G.rectangle('fill', bx, by, bw, bh)
                BD.border(bx, by, bw, bh, PW.boneDark, .9 * a)
                color(C.ink, .92 * a)
                G.rectangle('fill', bx + 5, by + bh, 3, 2)
                color(PW.boneDark, .9 * a)
                G.rectangle('fill', bx + 5, by + bh, 3, 1)
                BD.text(font, e.barkText, bx + 5, by + 3, C.text, bw - 10)
            end
        end
    end
    -- Selo 'zzz' de trégua e marca de fuga suspensos (mesmo bloco do legado
    -- — marcadores vivem acima do sprite, nunca sob).
    for _, e in ipairs(battle.enemies or {}) do
        local a = e.enemy
        if a and e.health.current > 0 and not e.spared then
            if a.state == 'calmed' then
                local ux, uy = R.visualPosition(e)
                local zz = (t * .6 + (e.seed or 0)) % 1
                color(Pal.sky.star, .9 - zz * .7)
                G.print('z', ux + 8, uy - 40 - zz * 14)
            end
        end
    end
    G.pop()

    hd.statsClock = (hd.statsClock or 0) + 1
    if hd.statsClock >= 90 then
        hd.statsClock = 0
        print(string.format('[hd_battle] light=%.3fms bloom=%.3fms lights=%d occluders=%d shadowQuads=%d',
            (L.stats and L.stats.lightPassMs) or 0,
            (P.stats and P.stats.bloomMs) or 0,
            (L.stats and L.stats.lights) or 0,
            (L.stats and L.stats.occluders) or 0,
            (L.stats and L.stats.shadowQuads) or 0))
    end
end

return HDWorld
