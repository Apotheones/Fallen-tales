--====================================================================--
-- LOTE FIBRA — figurantes + inimigos. Painters candidatos, prontos para
-- o Traço integrar em src/pixel_actors.lua (mesmas assinaturas e mesmos
-- helpers locais: painter/pose/mixc/shade/faceNpc/faceNpcSide/faceRes/
-- faceDraw/npcFeet/garmentNpc/armsIdle/workArms/workBob/BAYER/P).
-- Regra aplicada: 3-4 tons por material, textura assada, sombra de
-- forma, costura; rosto de ficha aberto; âncoras do PERSONAGENS doc.
--====================================================================--

local Lote = {bodies = {}, tops = {}, residents = {}, enemies = {}}

--====================================================================--
-- FIGURANTES DO REFÚGIO — corpos canônicos (doc "Elenco secundário").
--====================================================================--

-- ANCIÃO: baixo, magro, pele escura, cabelo branco ralo; casaco areia
-- até o joelho e bengala comum. Âncoras: casaco longo, bengala, cabeça
-- clara. Corcova leve — o tronco tombado na direção encarada.
local function bodyElder(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair = C.hair
    local lean = south and 1 or side                        -- corcova p/ frente
    -- Pernas magras sob a barra longa do casaco.
    npcFeet(r, cx, 37, P.stoneDark, P.goldDeep, nil, P.ink)
    -- Casaco areia até o joelho: ombros à frente do quadril (corcova),
    -- fenda frontal com V escuro da abertura.
    p({cx - 6 + lean, top + 10, cx + 6 + lean, top + 10, cx + 7, 37,
        cx - 7, 37}, P.ink)
    p({cx - 5 + lean, top + 11, cx + 5 + lean, top + 11, cx + 6, 36,
        cx - 6, 36}, coat)
    p({cx - 5 + lean, top + 11, cx - 2 + lean, top + 11, cx - 3, 36,
        cx - 6, 36}, coatHi)
    p({cx + 3 + lean, top + 11, cx + 5 + lean, top + 11, cx + 6, 36,
        cx + 4, 36}, coatLo)
    d(cx - 4 + lean, top + 14, 8, 18, coatLo, .15)
    r(cx - 6, 35, 12, 1, coatLo)                              -- barra gasta
    if not north then
        -- Abertura frontal: filete escuro + botões puídos; gola fechada.
        l(cx + lean, top + 12, cx, 30, coatLo)
        r(cx - 1, top + 14, 1, 1, C.accent); r(cx - 1, top + 19, 1, 1, C.accent)
        r(cx - 1, top + 24, 1, 1, C.accent)
        r(cx - 3 + lean, top + 10, 6, 2, coatLo)              -- gola alta
    else
        l(cx - 1, top + 13, cx - 1, 34, coatLo)               -- costa da cauda
    end
    if C.act ~= 'work' then
        -- Braço livre descido; o outro segura a bengala.
        r(cx - 8 + lean, top + 13, 3, 10, P.ink)
        r(cx - 7 + lean, top + 14, 2, 7, coat)
        r(cx - 7 + lean, top + 21, 2, 2, skin)
    end
    -- Bengala comum (âncora): haste escura + mão de pele no topo.
    local sx = south and cx + 9 or cx + side * 8
    l(cx + (south and 4 or side * 4), top + 13, sx, top + 15, skin)
    l(sx, top + 11, sx, 42, P.goldDeep)
    r(sx - 1, top + 10, 3, 2, P.goldDark)                     -- pomo
    r(sx - 1, 41, 2, 1, P.ink)                                -- ponteira
    -- Cabeça: pele escura, cabelo branco RALO (filetes, não capacete),
    -- rosto atento e gasto — "cabeça clara" lê-se pela nuca/parte alta.
    r(cx - 5 + lean, top, 10, 12, P.ink)
    if north then
        r(cx - 4 + lean, top + 1, 8, 10, skin)
        r(cx - 4 + lean, top + 1, 8, 4, hair)                 -- alto branco
        r(cx - 4 + lean, top + 5, 2, 4, hair)                 -- tira rala
        r(cx + 2 + lean, top + 5, 1, 3, hair)
        l(cx - 4 + lean, top + 9, cx + 3 + lean, top + 9, skinLo)
    elseif side ~= 0 then
        local fx = cx + lean + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4 + lean, top, 8, 3, hair)                     -- topo ralo
        r(cx - side * 5 + lean, top + 2, 2, 6, hair)          -- nuca branca
        r(fx + (side == 1 and 3 or -4), top + 5, 1, 1, hair)  -- fio na têmpora
    else
        faceNpc(r, l, cx - 4 + lean, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        -- Cabelo branco ralo: aro alto e têmporas, testa de pele aberta.
        r(cx - 4 + lean, top, 8, 2, hair)
        r(cx - 5 + lean, top + 2, 1, 6, hair); r(cx + 4 + lean, top + 2, 1, 6, hair)
        r(cx - 3 + lean, top + 2, 2, 1, hair); r(cx + 2 + lean, top + 2, 1, 1, hair)
        -- Pálpebras pesadas + sulco de expressão serena.
        r(cx - 3 + lean, top + 5, 2, 1, skinLo); r(cx + 2 + lean, top + 5, 1, 1, skinLo)
        r(cx - 1 + lean, top + 10, 3, 1, skinLo)
    end
end

-- ANCIÃO SENTADO (act 'sit'): anatomia própria — pernas dobradas à
-- frente, casaco areia cobrindo os joelhos, bengala escorada na lateral.
-- Nunca capuz de pano: a cabeça é de pele escura com cabelo branco ralo.
local function seatedElder(r, l, p, cx, direction, pal, frame)
    local east, south, west, north = direction == 1, direction == 2,
        direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local top = 19 + ({0, -1, 0, 0})[frame]
    local skin = pal.skin or P.goldLight
    local skinHi = mixc(skin, .3, P.white)
    local skinLo = mixc(skin, .35)
    local coat = pal.cloth or P.boneDark
    local coatLo = mixc(coat, .42)
    local hair = pal.hair or P.bone
    -- Pernas dobradas adiante (joelho + canela baixa) + massa do casaco.
    r(cx - 4, 38, 12, 4, P.ink); r(cx - 3, 39, 10, 2, P.stoneDark)
    r(cx + 4, 40, 4, 3, P.ink); r(cx + 4, 41, 3, 2, P.goldDeep)
    p({cx - 7, top + 10, cx + 7, top + 9, cx + 9, 38, cx - 8, 38}, P.ink)
    p({cx - 6, top + 11, cx + 6, top + 10, cx + 8, 37, cx - 7, 37}, coat)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, 37, cx - 7, 37},
        mixc(coat, .25, P.white))
    r(cx - 6, top + 11, 12, 1, pal.accent or P.goldDark)      -- gola/faixa
    l(cx, top + 13, cx + 1, 34, coatLo)
    -- Mão livre apoiada no joelho.
    r(cx + 5, 33, 3, 3, skin)
    -- Cabeça de pele com cabelo branco ralo por cima e nas laterais.
    p({cx - 5, top, cx + 5, top - 1, cx + 6, top + 4, cx + 5, top + 12,
        cx - 5, top + 12, cx - 6, top + 4}, P.ink)
    local fx = cx + side * 2
    if north then
        r(cx - 4, top + 1, 9, 11, skin)
        r(cx - 4, top, 9, 4, hair); r(cx - 4, top + 4, 2, 5, hair)
        r(cx + 3, top + 4, 1, 3, hair)
    elseif south then
        faceNpc(r, l, fx - 3, top + 3, 7, 8, skin, skinHi, skinLo,
            pal.eye or P.jadeLight)
        r(cx - 4, top, 8, 2, hair)
        r(cx - 5, top + 1, 1, 5, hair); r(cx + 4, top + 1, 1, 5, hair)
        r(fx - 2, top + 7, 1, 1, skinLo); r(fx + 2, top + 7, 1, 1, skinLo)
    else
        faceNpcSide(r, l, fx - 3, top + 3, 7, 8, side, skin, skinHi,
            skinLo, pal.eye or P.jadeLight)
        r(cx - 4, top, 8, 3, hair); r(cx - side * 5, top + 1, 2, 5, hair)
    end
    -- Bengala escorada na lateral do banco.
    local sx = south and cx + 10 or cx + side * 9
    l(sx, top + 8, sx - (south and 2 or side), 42, P.goldDeep)
    r(sx - 1, top + 7, 3, 2, P.goldDark)
end

-- LAVADEIRA: robusta, pele cobre, cabelo num rolo preso atrás; manga
-- dobrada (antebraço de pele), saia azul, avental claro. Âncoras:
-- mangas claras/dobradas, rolo de cabelo, tecido horizontal.
local function bodyWash(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    local apron, apronHi, apronLo = C.accent, mixc(C.accent, .3, P.white),
        mixc(C.accent, .4)
    -- Saia azul larga até a canela sobre calça de trabalho.
    npcFeet(r, cx, 38, P.stoneDeep, P.goldDeep, nil, P.ink)
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 9, 39, cx - 9, 39}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 8, 38, cx - 8, 38}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 5, 38, cx - 8, 38}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 8, 38, cx + 6, 38}, clothLo)
    d(cx - 4, top + 15, 9, 20, clothLo, .15)
    r(cx - 8, 37, 16, 1, clothLo)                             -- barra úmida
    -- Avental claro (âncora): painel frontal estreito com alça na cintura.
    if not north then
        p({cx - 4, top + 17, cx + 4, top + 17, cx + 6, 35, cx - 6, 35}, P.ink)
        p({cx - 3, top + 18, cx + 3, top + 18, cx + 5, 34, cx - 5, 34}, apron)
        d(cx - 2, top + 20, 5, 12, apronLo, .12)
        l(cx - 4, top + 17, cx + 4, top + 17, apronLo)
        r(cx - 5, top + 16, 10, 1, apronLo)                   -- alça de cintura
        r(cx + 3, 33, 2, 2, apronLo)                          -- mancha de uso
    else
        l(cx - 4, top + 16, cx + 4, top + 16, apronLo)        -- laço nas costas
        r(cx - 1, top + 15, 3, 2, apron)
    end
    if C.act ~= 'work' then
        -- Manga dobrada (âncora): meia-manga do pano + dobra clara +
        -- antebraço de pele à mostra — braços de quem trabalha na água.
        r(cx - 9, top + 12, 3, 7, P.ink); r(cx - 8, top + 13, 2, 4, cloth)
        r(cx - 8, top + 17, 2, 2, apronHi)                    -- dobra dobrada
        r(cx - 8, top + 19, 2, 4, skin); r(cx - 8, top + 23, 2, 2, skin)
        r(cx + 6, top + 12, 3, 7, P.ink); r(cx + 7, top + 13, 2, 4, clothLo)
        r(cx + 7, top + 17, 2, 2, apronHi)
        r(cx + 7, top + 19, 2, 4, skin); r(cx + 7, top + 23, 2, 2, skin)
    end
    -- Cabeça: cabelo preso num ROLO atrás (âncora) — massa baixa na nuca,
    -- fios puxados da testa; de costas o rolo é a marca.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 6, hairLo, .3)
        r(cx - 2, top + 8, 5, 4, hair); r(cx - 1, top + 9, 3, 2, hairLo)
        r(cx - 1, top + 12, 3, 1, skinLo)                     -- nuca
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 4, top + 3, 1, 1, hair)
        r(cx + 3, top + 3, 1, 1, hair)
        -- O rolo espreita atrás da mandíbula.
        r(cx - side * 5 - (side == 1 and 1 or 0), top + 7, 3, 4, hair)
        r(cx - side * 5 - (side == 1 and 1 or 0), top + 8, 1, 2, hairLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 5, hair); r(cx + 4, top + 2, 1, 4, hair)
        -- Bochechas de quem ri dobrando pano + força no rosto.
        r(cx - 3, top + 7, 1, 1, skinLo); r(cx + 3, top + 7, 1, 1, skinLo)
    end
end

-- CARREGADOR: mediano, peito largo, pele clara oliva, barba negra curta;
-- proteção de lona num ombro. Âncoras: ombro quadrado, barba escura,
-- alça larga.
local function bodyPorter(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    local pad, padHi, padLo = P.goldDark, P.gold, P.goldDeep   -- lona do ombro
    npcFeet(r, cx, 34, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Peito largo (âncora): tronco quadrado de camisa puída.
    p({cx - 8, top + 10, cx + 8, top + 10, cx + 8, 35, cx - 8, 35}, P.ink)
    p({cx - 7, top + 11, cx + 7, top + 11, cx + 7, 34, cx - 7, 34}, cloth)
    p({cx - 7, top + 11, cx - 3, top + 11, cx - 4, 34, cx - 7, 34}, clothHi)
    p({cx + 4, top + 11, cx + 7, top + 11, cx + 7, 34, cx + 5, 34}, clothLo)
    d(cx - 5, top + 15, 10, 16, clothLo, .15)
    r(cx - 7, 32, 14, 2, clothLo)                             -- barra cintura
    if north then
        -- Alça larga cruzando o dorso + canto do fardo por cima.
        l(cx + 4, top + 11, cx - 4, 30, P.goldDeep)
        l(cx + 4, top + 12, cx - 4, 31, pad)
    else
        -- Alça larga diagonal (âncora): do ombro da lona ao quadril.
        l(cx - 5, top + 11, cx + 5, 33, P.goldDeep)
        l(cx - 5, top + 12, cx + 5, 34, pad)
        r(cx + 3, 28, 3, 2, P.goldDeep)                       -- fivela
    end
    -- Proteção de lona no ombro esquerdo (âncora): bloco quadrado que
    -- quebra a linha do ombro — a marca do carregador.
    p({cx - 10, top + 8, cx - 5, top + 7, cx - 4, top + 13, cx - 9, top + 15},
        P.ink)
    p({cx - 9, top + 9, cx - 5, top + 8, cx - 4, top + 12, cx - 8, top + 14},
        pad)
    l(cx - 9, top + 9, cx - 6, top + 8, padHi)
    l(cx - 8, top + 10, cx - 5, top + 12, padLo)
    if C.act ~= 'work' then
        -- Braços de carga: manga curta + antebraço de pele grosso.
        r(cx + 7, top + 12, 3, 8, P.ink); r(cx + 8, top + 13, 2, 4, clothLo)
        r(cx + 8, top + 17, 2, 4, skin); r(cx + 8, top + 21, 2, 2, skin)
        r(cx - 8, top + 15, 3, 8, skin)                       -- braço da lona
    end
    -- Cabeça: cabelo escuro curto + barba negra curta fechando o queixo.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 8, hairLo, .3)
        r(cx - 4, top + 9, 8, 2, skin)                        -- nuca de pele
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 4, hair)
        r(cx + 4, top + 2, 1, 3, hair)
        -- Barba curta no perfil: maxilar escuro à frente.
        r(fx + (side == 1 and 2 or -4), top + 8, 2, 3, hair)
        r(fx + (side == 1 and 1 or -3), top + 10, 3, 1, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hair); r(cx + 2, top + 3, 1, 1, hair)
        -- Barba negra curta (âncora): laterais do maxilar + queixo.
        r(cx - 4, top + 8, 1, 3, hair); r(cx + 4, top + 8, 1, 3, hair)
        r(cx - 3, top + 10, 6, 1, hair)
        r(cx - 1, top + 10, 2, 1, skinLo)                     -- boca na barba
    end
end

-- LENHADOR: alto, corpo forte, pele marrom, cabelo crespo curto; casaco
-- cinza reto e calças escuras. Âncoras: altura, faixa clara no punho,
-- casaco reto; machado contextual.
local function bodyLogger(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local coat, coatHi, coatLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 33, P.stoneDeep, P.ink, nil, P.ink)        -- calças escuras
    -- Casaco cinza RETO (âncora): lados paralelos, barra firme na coxa.
    p({cx - 8, top + 10, cx + 8, top + 10, cx + 8, 36, cx - 8, 36}, P.ink)
    p({cx - 7, top + 11, cx + 7, top + 11, cx + 7, 35, cx - 7, 35}, coat)
    p({cx - 7, top + 11, cx - 3, top + 11, cx - 4, 35, cx - 7, 35}, coatHi)
    p({cx + 4, top + 11, cx + 7, top + 11, cx + 7, 35, cx + 5, 35}, coatLo)
    d(cx - 5, top + 14, 10, 18, coatLo, .15)
    if not north then
        -- Abertura frontal + cinto de trabalho com ponta pendente.
        l(cx, top + 12, cx, 30, coatLo)
        r(cx - 6, top + 22, 13, 2, P.goldDeep)
        r(cx + 1, top + 22, 2, 2, P.gold)
        r(cx + 2, top + 24, 1, 3, P.goldDeep)                 -- ponta do cinto
    else
        l(cx - 1, top + 12, cx - 1, 33, coatLo)
        r(cx - 6, top + 22, 13, 2, coatLo)
    end
    if C.act ~= 'work' then
        -- Braço da faixa: manga cinza até o cotovelo + FAIXA CLARA no
        -- punho (âncora) + mão. O outro braço segura o machado.
        r(cx - 10, top + 12, 3, 10, P.ink); r(cx - 9, top + 13, 2, 6, coat)
        r(cx - 9, top + 19, 2, 2, C.accent)                   -- faixa clara
        r(cx - 9, top + 21, 2, 3, skin)
        r(cx + 7, top + 12, 3, 10, P.ink); r(cx + 8, top + 13, 2, 6, coatLo)
        r(cx + 8, top + 19, 2, 2, C.accent)
        r(cx + 8, top + 21, 2, 3, skin)
        -- Machado contextual: cabo apoiado no ombro, lâmina para trás.
        local ax = south and cx + 11 or cx + side * 11
        l(cx + side * 4, top + 12, ax, top + 8, skin)
        l(ax, top - 3, ax, top + 9, P.goldDark)
        r(ax - 2, top - 4, 5, 4, P.stoneDark); r(ax - 2, top - 4, 5, 1, P.stoneLight)
        r(ax - 2, top - 1, 1, 1, P.stoneLight)
    end
    -- Cabeça: cabelo crespo curto — casquete texturizado, linha de
    -- plantio baixa; rosto largo e firme.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 4, top + 1, 8, 5, hairLo, .35)                 -- textura crespa
        r(cx - 4, top + 9, 8, 2, skin)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 2, 5, hair)
        r(cx + 4, top + 1, 1, 4, hair)
        r(cx - 4, top + 3, 1, 1, hairLo); r(cx + 2, top + 2, 1, 1, hairLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 4, hair)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hairLo); r(cx + 2, top + 3, 1, 1, hairLo)
        r(cx - 1, top + 3, 1, 1, hairLo)                      -- textura crespa
    end
end

-- CRIANÇA DO REFÚGIO: 7-10 anos, baixa, pele parda, cabelo encaracolado
-- curto; blusa ocre e calças azuis de dobra larga. Âncoras: cabeça
-- arredondada, dobra de calça, blusa ocre.
local function bodyKid(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    -- Calças azuis de DOBRA LARGA (âncora): herança grande demais — o
    -- punho dobrado lê no tornozelo.
    npcFeet(r, cx, 36, C.pal.pants or P.stone, P.goldDeep, nil, P.ink)
    r(cx - 4, 38, 3, 2, C.accent); r(cx + 3, 38, 3, 2, C.accent)
    r(cx - 4, 38, 3, 1, mixc(C.accent, .3, P.white))
    r(cx + 3, 38, 3, 1, mixc(C.accent, .3, P.white))
    -- Blusa ocre (âncora): túnica curta e fofa, gola simples.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 7, 36, cx - 7, 36}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 6, 35, cx - 6, 35}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 35, cx - 6, 35}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 6, 35, cx + 4, 35}, clothLo)
    r(cx - 5, 34, 11, 1, clothLo)                             -- barra da blusa
    if not north then
        r(cx - 2, top + 10, 5, 2, clothLo)                    -- gola
        r(cx - 1, top + 12, 1, 1, C.accent)                   -- botão
    end
    if C.act ~= 'work' then
        -- Manguinhas curtas + braços de pele — criança de correr.
        r(cx - 8, top + 12, 3, 6, P.ink); r(cx - 7, top + 13, 2, 3, cloth)
        r(cx - 7, top + 16, 2, 4, skin)
        r(cx + 5, top + 12, 3, 6, P.ink); r(cx + 6, top + 13, 2, 3, clothLo)
        r(cx + 6, top + 16, 2, 4, skin)
    end
    -- Cabeça ARREDONDADA (âncora) grande pro corpo + cachos curtos
    -- escapando nas bordas — a silhueta é quase um círculo sobre o
    -- pescocinho de pele que separa cabeça da blusa.
    r(cx - 3, top + 12, 6, 2, skin)                           -- pescoço
    p({cx - 5, top + 2, cx - 4, top, cx + 4, top - 1, cx + 5, top + 2,
        cx + 5, top + 10, cx + 4, top + 12, cx - 4, top + 12, cx - 5, top + 10},
        P.ink)
    if north then
        r(cx - 4, top + 1, 8, 11, hair)
        d(cx - 4, top + 1, 8, 9, hairLo, .4)                  -- caracol cerrado
        r(cx - 5, top + 4, 1, 3, hair); r(cx + 5, top + 3, 1, 3, hair)
        r(cx - 3, top, 2, 1, hair); r(cx + 2, top, 1, 1, hair)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 3, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        d(cx - 4, top, 8, 3, hairLo, .35)
        r(cx - side * 5, top + 2, 2, 6, hair)                 -- cachos atrás
        r(cx - 5, top + 1, 1, 2, hair); r(cx + 4, top + 1, 1, 2, hair)
        r(cx - side * 5 - 1, top + 5, 1, 2, hair)
    else
        faceNpc(r, l, cx - 4, top + 3, 8, 9, skin, skinHi, skinLo, eye)
        -- Encaracolado curto: massa no topo + pontas enroladas nas
        -- têmporas — nunca capacete liso.
        r(cx - 4, top, 8, 3, hair)
        d(cx - 4, top, 8, 3, hairLo, .35)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 5, top + 1, 1, 4, hair)
        r(cx - 6, top + 4, 1, 2, hair); r(cx + 5, top + 4, 1, 2, hair)
        r(cx - 3, top + 3, 1, 1, hair); r(cx + 2, top + 3, 1, 1, hair)
        -- Olhos grandes demais para o rosto + covinha de sorriso.
        r(cx - 3, top + 6, 2, 1, eye); r(cx + 2, top + 6, 2, 1, eye)
        r(cx - 3, top + 10, 1, 1, skinLo); r(cx + 3, top + 10, 1, 1, skinLo)
    end
end

--====================================================================--
-- FIGURANTES DE REGIÃO — fichas breves do doc, densidade de núcleo.
--====================================================================--

-- TRABALHADORA DAS OFICINAS (traba): alta, magra, cabelo liso trançado;
-- camisa barro e avental curto claro. Âncoras: trança baixa, camisa
-- barro, avental curto.
local function bodyBraid(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 33, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Figura alta e magra: camisa barro justa até o quadril.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 6, 35, cx - 6, 35}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 5, 34, cx - 5, 34}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 34, cx - 5, 34}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 5, 34, cx + 4, 34}, clothLo)
    d(cx - 3, top + 14, 6, 17, clothLo, .15)
    if not north then
        -- Avental curto claro (âncora): só até meio da coxa, alça V.
        p({cx - 4, top + 16, cx + 4, top + 16, cx + 5, 31, cx - 5, 31}, P.ink)
        p({cx - 3, top + 17, cx + 3, top + 17, cx + 4, 30, cx - 4, 30}, P.bone)
        l(cx - 3, top + 17, cx - 1, top + 11, P.boneDark)
        l(cx + 3, top + 17, cx + 1, top + 11, P.boneDark)
        d(cx - 2, top + 19, 4, 9, P.boneDark, .12)
        r(cx - 4, 29, 8, 1, P.boneDark)                       -- barra puída
        r(cx + 2, top + 22, 2, 3, P.boneDark)                 -- bolso
        r(cx + 2, top + 22, 2, 1, P.bone)
    else
        l(cx - 3, top + 16, cx + 3, top + 16, P.boneDark)     -- laço
    end
    if C.act ~= 'work' then
        r(cx - 8, top + 12, 3, 10, P.ink); r(cx - 7, top + 13, 2, 6, cloth)
        r(cx - 7, top + 19, 2, 3, skin)
        r(cx + 5, top + 12, 3, 10, P.ink); r(cx + 6, top + 13, 2, 6, clothLo)
        r(cx + 6, top + 19, 2, 3, skin)
    end
    -- Cabeça: cabelo liso puxado + TRANÇA BAIXA (âncora) caindo pelas
    -- costas/ombro — escama de três tons, ponta atada.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        -- A trança desce inteira pelas costas: elos alternados.
        for i = 0, 4 do
            r(cx - 1, top + 8 + i * 4, 3, 3, i % 2 == 0 and hair or hairLo)
        end
        r(cx - 1, top + 28, 3, 1, C.accent)                   -- atadura
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 5, hair)
        r(cx + 4, top + 2, 1, 4, hair)
        -- Trança atrás descendo junto à nuca.
        local bx = cx - side * 5
        for i = 0, 3 do
            r(bx - 1, top + 5 + i * 4, 3, 3, i % 2 == 0 and hair or hairLo)
        end
        r(bx - 1, top + 20, 3, 1, C.accent)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 5, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hair); r(cx + 1, top + 3, 2, 1, hair)
        -- Ponta da trança passando sobre o ombro direito.
        r(cx + 5, top + 9, 3, 8, hair); r(cx + 5, top + 9, 1, 7, hairLo)
        r(cx + 5, top + 16, 3, 1, C.accent)
    end
end

-- TRABALHADOR DAS OFICINAS (trabb): baixo, robusto, cabeça raspada;
-- colete verde e mangas escuras. Âncoras: cabeça lisa, colete quadrado,
-- altura baixa.
local function bodyStocky(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local vest, vestHi, vestLo = C.accent, mixc(C.accent, .25, P.white),
        mixc(C.accent, .45)
    local sleeve = C.cloth                                   -- mangas escuras
    npcFeet(r, cx, 36, C.pal.pants or P.stoneDeep, P.ink, nil, P.ink)
    -- Tronco quadrado baixo: mangas escuras nos ombros + COLETE VERDE
    -- quadrado (âncora) aberto na frente.
    p({cx - 9, top + 10, cx + 9, top + 10, cx + 9, 36, cx - 9, 36}, P.ink)
    p({cx - 8, top + 11, cx + 8, top + 11, cx + 8, 35, cx - 8, 35}, sleeve)
    p({cx - 8, top + 11, cx - 5, top + 11, cx - 6, 35, cx - 8, 35},
        mixc(sleeve, .25, P.white))
    if not north then
        p({cx - 6, top + 11, cx - 1, top + 13, cx - 2, 33, cx - 6, 33}, vest)
        p({cx + 6, top + 11, cx + 1, top + 13, cx + 2, 33, cx + 6, 33}, vestLo)
        l(cx - 6, top + 12, cx - 2, 32, vestHi)
        r(cx - 1, top + 13, 3, 14, P.bone)                    -- peito da camisa
        d(cx - 1, top + 14, 3, 12, P.boneDark, .15)
        r(cx - 6, 31, 12, 2, vestLo)                          -- barra do colete
        r(cx - 2, top + 21, 4, 1, P.goldDeep)                 -- cinto
    else
        p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, 33, cx - 6, 33}, vest)
        p({cx - 6, top + 11, cx - 2, top + 11, cx - 3, 33, cx - 6, 33}, vestHi)
        r(cx - 6, 31, 12, 2, vestLo)
    end
    if C.act ~= 'work' then
        -- Mangas escuras arregaçadas + antebraços de pele de quem forja.
        r(cx - 11, top + 12, 3, 9, P.ink); r(cx - 10, top + 13, 2, 5, sleeve)
        r(cx - 10, top + 18, 2, 1, mixc(sleeve, .35, P.white))
        r(cx - 10, top + 19, 2, 3, skin)
        r(cx + 8, top + 12, 3, 9, P.ink); r(cx + 9, top + 13, 2, 5, sleeve)
        r(cx + 9, top + 19, 2, 3, skin)
    end
    -- CABEÇA RASPADA (âncora): crânio de pele em rampa, brilho de lã
    -- recém-passada, sombra de barba por fazer na base.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, skin)
        r(cx - 4, top + 1, 8, 2, skinHi)
        d(cx - 4, top + 4, 8, 5, skinLo, .2)
        r(cx - 4, top + 9, 8, 2, skinLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - side * 5, top + 2, 2, 7, skin)
        r(cx - 4, top, 8, 1, skinHi)                          -- brilho do couro
        r(cx - side * 5, top + 8, 2, 2, skinLo)               -- sombra de barba
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top + 2, 8, 1, skinHi)                      -- brilho
        r(cx - 4, top + 8, 8, 1, skinLo)                      -- sombra de barba
        r(cx - 2, top + 9, 4, 1, skinLo)
    end
end

-- GUARDA DA FEIRA (guarda): alto, manto curto sobre túnica simples;
-- o par descrito no doc divide a mesma função — esta leitura serve ao
-- integrador como base dos dois corpos. Âncoras: altura, manto curto,
-- postura de posto.
local function bodyWatch(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local cape, capeHi, capeLo = C.pal.cape or P.stoneDark,
        mixc(C.pal.cape or P.stoneDark, .3, P.white),
        mixc(C.pal.cape or P.stoneDark, .45)
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 32, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Túnica de posto: reta, cinto com placa, barra sobre a canela.
    p({cx - 7, top + 10, cx + 7, top + 10, cx + 7, 34, cx - 7, 34}, P.ink)
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, 33, cx - 6, 33}, cloth)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, 33, cx - 6, 33}, clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, 33, cx + 4, 33}, clothLo)
    r(cx - 6, top + 24, 12, 2, P.goldDeep); r(cx - 1, top + 24, 2, 2, P.gold)
    -- Manto curto (âncora): capa de meio-braço caída do ombro de trás,
    -- borda com filete — abre o peito da túnica.
    if north then
        p({cx - 8, top + 9, cx + 8, top + 9, cx + 7, top + 24,
            cx - 7, top + 24}, P.ink)
        p({cx - 7, top + 10, cx + 7, top + 10, cx + 6, top + 23,
            cx - 6, top + 23}, cape)
        p({cx - 7, top + 10, cx - 4, top + 10, cx - 3, top + 23,
            cx - 6, top + 23}, capeHi)
        l(cx - 6, top + 22, cx + 6, top + 22, capeLo)
    else
        local back = -side                                   -- lado de trás
        p({cx + back * 3 - 5, top + 9, cx + back * 6 + 1, top + 10,
            cx + back * 7, top + 26, cx + back * 2 - 2, top + 25}, P.ink)
        p({cx + back * 3 - 4, top + 10, cx + back * 6, top + 11,
            cx + back * 6, top + 25, cx + back * 2 - 1, top + 24}, cape)
        l(cx + back * 3 - 4, top + 10, cx + back * 6 - 1, top + 11, capeHi)
        d(cx + back * 2 - 1, top + 13, 5, 10, capeLo, .2)
        -- Fecho do manto no ombro.
        r(cx + back * 3 - 1, top + 10, 3, 3, C.accent)
        r(cx + back * 3, top + 11, 1, 1, P.goldLight)
    end
    if C.act ~= 'work' then
        -- Braço da frente caído; mão aberta de posto (não de arma).
        r(cx - 9, top + 13, 3, 10, P.ink); r(cx - 8, top + 14, 2, 6, cloth)
        r(cx - 8, top + 20, 2, 3, skin)
        if south or side == 0 then
            r(cx + 6, top + 13, 3, 10, P.ink); r(cx + 7, top + 14, 2, 6, clothLo)
            r(cx + 7, top + 20, 2, 3, skin)
        end
    end
    -- Cabeça: cabelo curto de serviço, queixo firme — guarda, não
    -- soldado de guerra.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 7, hairLo, .25)
        r(cx - 4, top + 9, 8, 2, skin)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 2, 4, hair)
        r(cx + 4, top + 1, 1, 3, hair)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 4, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 10, 6, 1, skinLo)                     -- linha séria
    end
end

-- FEIRANTE: corpo médio, cabelo branco crespo preso com pano; gola azul,
-- saia-calça cinza e bolsa estreita. Âncoras: pano na cabeça, gola azul,
-- bolsa estreita.
local function bodyVendor(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo                    -- branco crespo
    local wrap, wrapHi = C.pal.headWrap or P.bone,
        mixc(C.pal.headWrap or P.bone, .3, P.white)
    npcFeet(r, cx, 35, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Saia-calça cinza (âncora): barra ampla dividida ao meio.
    p({cx - 7, top + 20, cx + 7, top + 20, cx + 9, 39, cx - 9, 39}, P.ink)
    p({cx - 6, top + 21, cx + 6, top + 21, cx + 8, 38, cx - 8, 38}, P.stoneDark)
    p({cx - 6, top + 21, cx - 3, top + 21, cx - 5, 38, cx - 8, 38}, P.stone)
    l(cx, top + 22, cx, 37, P.ink)                            -- fenda da saia
    r(cx - 8, 37, 16, 1, P.ink)
    -- Blusa de manga ampla + GOLA AZUL (âncora) marcando o pescoço.
    p({cx - 7, top + 10, cx + 7, top + 10, cx + 7, top + 22, cx - 7, top + 22},
        P.ink)
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, top + 21, cx - 6, top + 21},
        cloth)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, top + 21, cx - 6, top + 21},
        clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, top + 21, cx + 4, top + 21},
        clothLo)
    d(cx - 4, top + 14, 8, 6, clothLo, .15)
    if not north then
        p({cx - 2, top + 10, cx + 2, top + 10, cx + 3, top + 13,
            cx - 3, top + 13}, C.accent)                      -- gola azul V
        r(cx - 3, top + 12, 6, 1, mixc(C.accent, .4))
        -- Bolsa estreita (âncora) pendurada no quadril direito.
        l(cx + 4, top + 13, cx + 7, top + 24, P.goldDeep)
        r(cx + 6, top + 24, 4, 7, P.ink); r(cx + 7, top + 25, 2, 5, P.goldDark)
        r(cx + 7, top + 25, 2, 1, P.gold)
    else
        l(cx - 3, top + 12, cx + 3, top + 12, C.accent)
        r(cx - 1, top + 11, 2, 2, C.accent)                   -- nó da gola
    end
    if C.act ~= 'work' then
        r(cx - 9, top + 13, 3, 9, P.ink); r(cx - 8, top + 14, 2, 5, cloth)
        r(cx - 8, top + 19, 2, 3, skin)
        r(cx + 6, top + 13, 3, 9, P.ink); r(cx + 7, top + 14, 2, 5, clothLo)
        r(cx + 7, top + 19, 2, 3, skin)
    end
    -- Cabeça: PANO enrolado (âncora) prendendo cabelo branco crespo —
    -- caracóis escapam sob a faixa.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top, 8, 5, wrap); r(cx - 4, top, 8, 1, wrapHi)
        r(cx - 3, top + 5, 6, 6, hair)                        -- massa crespa
        d(cx - 3, top + 5, 6, 5, hairLo, .3)
        r(cx + 3, top + 2, 3, 2, wrap)                        -- nó do pano
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 3, 7, 8, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 4, wrap); r(cx - 4, top, 8, 1, wrapHi)
        r(cx - side * 5, top + 2, 2, 5, hair)                 -- crespo atrás
        r(cx - side * 5, top + 3, 1, 1, hairLo)
        r(fx + (side == 1 and -4 or 3), top + 4, 1, 1, hair)  -- fio na testa
    else
        faceNpc(r, l, cx - 4, top + 3, 8, 8, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 4, wrap); r(cx - 4, top, 8, 1, wrapHi)
        r(cx - 5, top + 1, 1, 4, wrap)
        r(cx - 4, top + 4, 2, 1, hair); r(cx + 3, top + 4, 1, 1, hair)
        r(cx - 5, top + 4, 1, 2, hair); r(cx + 4, top + 3, 1, 2, hair)
        r(cx + 4, top, 2, 2, wrap)                            -- ponta do nó
    end
end

-- VOZ DO CANAL (voz): o doc diz que a voz não precisa de corpo — se a
-- sheet continuar sendo usada como presença (eco do canal), a leitura é
-- de capuz fundo e rosto em sombra, sem fantasma. Prioridade baixa.
local function bodyVoice(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    npcFeet(r, cx, 38, P.stoneDeep, P.ink, nil, P.ink)
    -- Túnica do canal: ombros caídos, pano pesado e sem brilho.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 8, 38, cx - 8, 38}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 7, 37, cx - 7, 37}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 4, 37, cx - 7, 37}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 7, 37, cx + 5, 37}, clothLo)
    d(cx - 4, top + 14, 8, 20, clothLo, .2)
    l(cx - 6, 36, cx + 6, 36, P.ink)
    -- Capuz baixo tombado — rosto quase inteiro em sombra.
    p({cx - 5, top + 4, cx - 2, top, cx + 3, top, cx + 6, top + 4,
        cx + 5, top + 12, cx - 4, top + 12}, P.ink)
    p({cx - 4, top + 4, cx - 2, top + 1, cx + 3, top + 1, cx + 5, top + 5,
        cx + 4, top + 11, cx - 3, top + 11}, cloth)
    l(cx - 4, top + 4, cx - 2, top + 1, clothHi)
    if north then
        l(cx - 2, top + 3, cx + 2, top + 3, clothLo)
        l(cx - 1, top + 6, cx + 1, top + 9, clothLo)
    elseif side ~= 0 then
        r(cx + side * 1, top + 5, 4, 5, P.ink)
        r(cx + side * 2, top + 6, 2, 3, skinLo)
        r(cx + side * 2 + (side == 1 and 1 or 0), top + 7, 1, 1, eye)
    else
        -- Fenda de rosto: só o necessário para ler pessoa dentro.
        r(cx - 3, top + 5, 6, 6, P.ink)
        r(cx - 2, top + 6, 4, 4, skinLo)
        r(cx - 2, top + 7, 1, 1, eye); r(cx + 1, top + 7, 1, 1, eye)
        r(cx - 1, top + 9, 2, 1, P.ink)
    end
    if C.act ~= 'work' then
        r(cx - 8, top + 13, 3, 11, P.ink); r(cx - 7, top + 14, 2, 8, clothLo)
        r(cx + 5, top + 13, 3, 11, P.ink); r(cx + 6, top + 14, 2, 8, clothLo)
    end
end

-- EQUIPE DE MANUTENÇÃO (equipe): base comum de punho preso e botas
-- impermeabilizadas — não é "outro Ivo". Âncoras: punho atado, bota
-- alta de cano, cinto de ferramenta.
local function bodyCrew(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    -- Botas impermeabilizadas (âncora): cano alto cobrindo a canela.
    npcFeet(r, cx, 34, P.stoneDeep, P.ink, nil, P.ink)
    r(cx - 5, 36, 4, 5, P.ink); r(cx + 2, 36, 4, 5, P.ink)
    r(cx - 4, 36, 3, 5, P.goldDeep); r(cx + 3, 36, 3, 5, P.goldDeep)
    r(cx - 4, 36, 3, 1, P.goldDark); r(cx + 3, 36, 3, 1, P.goldDark)
    r(cx - 4, 38, 3, 1, P.goldDark); r(cx + 3, 38, 3, 1, P.goldDark)
    -- Roupa de serviço: camisa resistente, peito coberto por peitilho.
    p({cx - 7, top + 10, cx + 7, top + 10, cx + 7, 35, cx - 7, 35}, P.ink)
    p({cx - 6, top + 11, cx + 6, top + 11, cx + 6, 34, cx - 6, 34}, cloth)
    p({cx - 6, top + 11, cx - 3, top + 11, cx - 4, 34, cx - 6, 34}, clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, 34, cx + 4, 34}, clothLo)
    if not north then
        p({cx - 4, top + 13, cx + 4, top + 13, cx + 5, 30, cx - 5, 30}, P.ink)
        p({cx - 3, top + 14, cx + 3, top + 14, cx + 4, 29, cx - 4, 29},
            C.accent)
        d(cx - 2, top + 16, 5, 10, mixc(C.accent, .4), .15)
        l(cx - 4, top + 14, cx - 4, 28, mixc(C.accent, .3, P.white))
    else
        l(cx - 4, top + 14, cx + 4, top + 14, C.accent)       -- tira do peitilho
    end
    -- Cinto de ferramenta: laço + presilha pendente.
    r(cx - 6, 31, 12, 2, P.goldDeep); r(cx + 4, 32, 2, 3, P.stoneDark)
    if C.act ~= 'work' then
        -- Punho atado (âncora): faixa de pano amarrada no antebraço.
        r(cx - 9, top + 12, 3, 10, P.ink); r(cx - 8, top + 13, 2, 6, cloth)
        r(cx - 8, top + 18, 2, 2, P.bone)                     -- faixa
        r(cx - 8, top + 20, 2, 3, skin)
        r(cx + 6, top + 12, 3, 10, P.ink); r(cx + 7, top + 13, 2, 6, clothLo)
        r(cx + 7, top + 18, 2, 2, P.bone)
        r(cx + 7, top + 20, 2, 3, skin)
    end
    -- Cabeça: lenço de serviço curto (não gorro do Ivo) + rosto comum.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top, 8, 4, C.accent)
        r(cx - 4, top + 4, 8, 7, hair)
        d(cx - 3, top + 5, 6, 5, hairLo, .25)
        r(cx + 3, top + 1, 2, 2, C.accent)                    -- nó do lenço
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, C.accent); r(cx - 4, top + 3, 8, 1, hair)
        r(cx - side * 5, top + 1, 2, 3, C.accent)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, C.accent); r(cx - 4, top + 2, 8, 1,
            mixc(C.accent, .3, P.white))
        r(cx + 4, top + 1, 2, 2, C.accent)                    -- nó lateral
        r(cx - 4, top + 3, 1, 2, hair); r(cx + 4, top + 3, 1, 2, hair)
    end
end

-- AJUDANTE DOS SALÕES (ajudante): médio, esguio, cabelo longo preso;
-- camisa creme e faixa de tecido vinho curta. Âncoras: rabo baixo,
-- faixa curta, manga creme.
local function bodyUsher(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local sash, sashLo = C.accent, mixc(C.accent, .4)
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 32, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Tronco esguio de camisa creme + FAIXA VINHO curta na cintura.
    p({cx - 6, top + 10, cx + 6, top + 10, cx + 6, 33, cx - 6, 33}, P.ink)
    p({cx - 5, top + 11, cx + 5, top + 11, cx + 5, 32, cx - 5, 32}, cloth)
    p({cx - 5, top + 11, cx - 2, top + 11, cx - 3, 32, cx - 5, 32}, clothHi)
    p({cx + 3, top + 11, cx + 5, top + 11, cx + 5, 32, cx + 4, 32}, clothLo)
    d(cx - 3, top + 14, 6, 15, clothLo, .12)
    if not north then
        l(cx - 3, top + 11, cx, top + 14, clothLo)            -- abertura da camisa
        -- Faixa curta (âncora): dois dedos de pano vinho + ponta solta.
        r(cx - 5, top + 22, 11, 2, sash); r(cx - 5, top + 22, 8, 1,
            mixc(sash, .3, P.white))
        r(cx + 3, top + 24, 2, 4, sash); r(cx + 3, top + 27, 2, 1, sashLo)
    else
        r(cx - 5, top + 22, 11, 2, sashLo)
        r(cx - 2, top + 21, 4, 3, sash)                       -- nó nas costas
    end
    if C.act ~= 'work' then
        -- Manga creme ampla no ombro, afinando no punho (âncora).
        r(cx - 8, top + 12, 4, 9, P.ink); r(cx - 7, top + 13, 2, 6, cloth)
        r(cx - 7, top + 19, 2, 1, clothLo)
        r(cx - 7, top + 20, 2, 3, skin)
        r(cx + 4, top + 12, 4, 9, P.ink); r(cx + 5, top + 13, 2, 6, clothLo)
        r(cx + 5, top + 20, 2, 3, skin)
    end
    -- Cabeça: cabelo longo preso em RABO BAIXO (âncora) atrás da nuca.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 6, hairLo, .25)
        r(cx - 1, top + 9, 3, 9, hair)                        -- rabo desce
        r(cx - 1, top + 9, 3, 1, C.accent)                    -- atadura
        r(cx - 1, top + 17, 3, 1, hairLo)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 2, 2, 5, hair)
        r(cx + 4, top + 2, 1, 3, hair)
        -- Rabo baixo atrás da nuca.
        local bx = cx - side * 5
        r(bx - 1, top + 6, 3, 8, hair); r(bx - 1, top + 6, 3, 1, C.accent)
        r(bx, top + 7, 1, 6, hairLo)
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 6, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 3, top + 3, 2, 1, hair); r(cx + 2, top + 3, 1, 1, hair)
        -- O rabo espreita sobre o ombro esquerdo.
        r(cx - 6, top + 8, 2, 7, hair); r(cx - 6, top + 8, 1, 6, hairLo)
    end
end

-- PLATEIA (plateia): corpo comum de assistência — ombros relaxados,
-- roupa simples em valor fora do palco, mãos juntas no colo da pose.
-- Âncoras: postura relaxada, pano simples, nada de palco.
local function bodyCrowd(C)
    local r, l, p, d, cx, top = C.r, C.l, C.p, C.d, C.cx, C.top
    local side, south, north = C.side, C.south, C.north
    local skin, skinHi, skinLo, eye = C.skin, C.skinHi, C.skinLo, C.eye
    local cloth, clothHi, clothLo = C.cloth, C.clothHi, C.clothLo
    local hair, hairLo = C.hair, C.hairLo
    npcFeet(r, cx, 35, P.stoneDeep, P.goldDeep, nil, P.ink)
    -- Túnica simples relaxada: ombros em níveis levemente diferentes.
    p({cx - 7, top + 11, cx + 7, top + 10, cx + 7, 35, cx - 7, 35}, P.ink)
    p({cx - 6, top + 12, cx + 6, top + 11, cx + 6, 34, cx - 6, 34}, cloth)
    p({cx - 6, top + 12, cx - 3, top + 12, cx - 4, 34, cx - 6, 34}, clothHi)
    p({cx + 3, top + 11, cx + 6, top + 11, cx + 6, 34, cx + 4, 34}, clothLo)
    d(cx - 4, top + 14, 9, 17, clothLo, .15)
    r(cx - 6, 33, 12, 1, clothLo)
    if not north then
        -- Xale de ombro atravessado + mãos juntas no colo.
        l(cx - 6, top + 11, cx + 5, top + 20, C.accent)
        r(cx - 1, top + 24, 4, 3, skin)
        l(cx - 4, top + 15, cx - 1, top + 24, clothLo)
        l(cx + 4, top + 15, cx + 2, top + 24, clothLo)
    else
        l(cx - 4, top + 13, cx + 4, top + 13, clothLo)
    end
    if C.act ~= 'work' and (north or side ~= 0) then
        r(cx + side * 6 - 1, top + 13, 3, 9, P.ink)
        r(cx + side * 6, top + 14, 2, 6, clothLo)
    end
    -- Cabeça comum: cabelo curto despenteio leve, expressão de espera.
    r(cx - 5, top, 10, 12, P.ink)
    if north then
        r(cx - 4, top + 1, 8, 10, hair)
        d(cx - 3, top + 2, 6, 7, hairLo, .25)
        r(cx - 4, top + 9, 8, 2, skin)
    elseif side ~= 0 then
        local fx = cx + side * 2
        faceNpcSide(r, l, fx - 3, top + 2, 7, 9, side, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair); r(cx - 5, top + 1, 2, 5, hair)
        r(cx - 5, top + 6, 1, 2, hairLo)                      -- fio solto
    else
        faceNpc(r, l, cx - 4, top + 2, 8, 9, skin, skinHi, skinLo, eye)
        r(cx - 4, top, 8, 3, hair)
        r(cx - 5, top + 2, 1, 5, hair); r(cx + 4, top + 2, 1, 4, hair)
        r(cx - 2, top + 3, 1, 1, hairLo); r(cx + 3, top + 3, 1, 1, hair)
        -- Bocejo contido: boca pequena, olho sonolento.
        r(cx, top + 9, 1, 1, skinLo)
    end
end

--====================================================================--
-- MAPA DO LOTE — bodies/tops/residents prontos p/ mesclar.
--====================================================================--

Lote.bodies = {
    elder = bodyElder, washer = bodyWash, porter = bodyPorter,
    logger = bodyLogger, kid = bodyKid, braid = bodyBraid,
    stocky = bodyStocky, watch = bodyWatch, vendor = bodyVendor,
    voice = bodyVoice, crew = bodyCrew, usher = bodyUsher, crowd = bodyCrowd,
}
Lote.tops = {
    elder = 13, washer = 10, porter = 11, logger = 6, kid = 17,
    braid = 8, stocky = 13, watch = 7, vendor = 10, voice = 10,
    crew = 10, usher = 10, crowd = 11,
}
Lote.seatedResident = seatedElder

-- Figurantes: paletas canônicas (pele/cabelo/roupa do doc) + body novo;
-- `shape` preserva a ossatura da ficha que o Traço já registrou.
Lote.residents = {
    npc_anciao = {cloth = P.boneDark, hair = P.bone, skin = P.rust,
        accent = P.goldDark, body = 'elder', eye = P.jadeLight, act = 'sit',
        shape = 'long'},
    npc_lavadeira = {cloth = P.stone, hair = P.ink, skin = P.gold,
        accent = P.bone, body = 'washer', eye = P.jadeLight, act = 'wash',
        shape = 'round'},
    npc_carregador = {cloth = P.rust, hair = P.ink, skin = P.bone,
        accent = P.goldDeep, body = 'porter', eye = P.jadeLight,
        act = 'carry', beard = P.ink, shape = 'rect'},
    npc_lenhador = {cloth = P.stone, hair = P.ink, skin = P.goldDark,
        accent = P.bone, body = 'logger', eye = P.jadeLight, act = 'chop',
        pants = P.stoneDeep, shape = 'square'},
    npc_crianca = {cloth = P.gold, hair = P.ink, skin = P.rust,
        accent = P.jade, body = 'kid', eye = P.jadeLight, act = 'play',
        pants = P.stone, shape = 'round'},
    npc_traba = {cloth = P.rust, hair = P.goldDark, skin = P.goldLight,
        accent = P.bone, body = 'braid', eye = P.jadeLight, shape = 'long'},
    npc_trabb = {cloth = P.stoneDark, hair = P.ink, skin = P.gold,
        accent = P.jadeDark, body = 'stocky', eye = P.jadeLight,
        pants = P.stone, shape = 'rect'},
    npc_guarda = {cloth = P.stone, hair = P.stoneDark, skin = P.goldLight,
        accent = P.gold, body = 'watch', eye = P.jadeLight,
        cape = P.stoneDark, shape = 'square'},
    npc_feirante = {cloth = P.goldDark, hair = P.bone, skin = P.gold,
        accent = P.jade, body = 'vendor', eye = P.jadeLight,
        headWrap = P.boneDark, shape = 'round'},
    npc_voz = {cloth = P.stoneDeep, hair = P.ink, skin = P.goldDark,
        accent = P.stone, body = 'voice', eye = P.jadeLight, shape = 'long'},
    npc_equipe = {cloth = P.stoneDeep, hair = P.stoneDark, skin = P.gold,
        accent = P.jade, body = 'crew', eye = P.jadeLight, shape = 'rect'},
    npc_ajudante = {cloth = P.bone, hair = P.goldDark, skin = P.goldLight,
        accent = P.rust, body = 'usher', eye = P.jadeLight, shape = 'long'},
    npc_plateia = {cloth = P.stoneDark, hair = P.boneDark, skin = P.gold,
        accent = P.violet, body = 'crowd', eye = P.jadeLight, shape = 'round'},
}

--====================================================================--
-- INIMIGOS — densidade por família, não recolor.
--====================================================================--

-- CRAWLER: massa horizontal de seis patas de TRÊS segmentos (fêmur,
-- tíbia, garra), carapaça em três placas com reborde de luz e saia
-- ventral, cabeça projetada com mandíbulas articuladas e abdômen
-- segmentado atrás. Bicho de casco, não robe.
local function crawlerV2(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local bob, leg, cape, lean, squat = pose(action, frame)
    local east, south, west, north = direction == 1, direction == 2,
        direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local cx, top = 16 + side * lean, 19 + bob + squat
    if action == 'death' and frame >= 3 then
        -- Casco tombado de lado: ventre claro à mostra, patas curvadas
        -- para cima — a derrota do inseto lê na barriga exposta.
        p({cx - 12, 41, cx - 8, 34, cx + 8, 34, cx + 12, 41}, P.ink)
        p({cx - 11, 40, cx - 7, 35, cx + 7, 35, cx + 11, 40}, P.jadeDeep)
        p({cx - 10, 39, cx - 6, 35, cx - 1, 35, cx - 4, 39}, P.jadeDark)
        l(cx - 8, 37, cx + 6, 37, P.jadeMid)                    -- filete ventral
        r(cx - 8, 38, 3, 1, P.jade); r(cx + 4, 37, 4, 1, P.jade)
        for _, s in ipairs({-1, 1}) do for i = 0, 2 do
            l(cx + s * (5 + i * 4), 34, cx + s * (6 + i * 4), 30 - i, P.ink)
        end end
        return
    end
    -- Seis patas de três segmentos: coxa subindo do casco, tíbia caindo,
    -- tarso fino com garra de pedra. Passo alterna os trípodes.
    for _, s in ipairs({-1, 1}) do
        local lift = (s == -1) == (leg >= 0) and math.min(2, math.abs(leg)) or 0
        for i, dx in ipairs({6, 10, 14}) do
            local liftI = math.floor(lift + (i - 1) * .5)
            local kneeX = cx + s * (dx - 1)
            l(cx + s * (dx - 5), top + 8, kneeX, top + 6 - liftI, P.ink)
            l(kneeX, top + 6 - liftI, cx + s * dx, top + 15 - liftI, P.ink)
            l(cx + s * dx, top + 15 - liftI, cx + s * dx + s, top + 20 - liftI,
                P.ink)
            r(cx + s * dx + (s == 1 and 0 or -1), top + 19 - liftI, 2, 1,
                P.stoneDark)
        end
    end
    -- Sombra de corrida sob o casco: o bicho flutua baixo, não cola.
    d(cx - 10, top + 17, 20, 3, P.jadeDeep, .5)
    -- Abdômen segmentado atrás: três gomos menores + cerco na ponta —
    -- de norte é o que se vê primeiro.
    local rear = -side
    if north then rear = 0 end
    p({cx + rear * 8 - 3, top + 4, cx + rear * 13 - 1, top + 7,
        cx + rear * 13, top + 12, cx + rear * 7, top + 13}, P.ink)
    p({cx + rear * 8 - 2, top + 5, cx + rear * 12 - 1, top + 8,
        cx + rear * 12, top + 11, cx + rear * 7, top + 12}, P.jadeDark)
    l(cx + rear * 9, top + 6, cx + rear * 9, top + 12, P.jadeDeep)
    l(cx + rear * 11, top + 7, cx + rear * 11, top + 12, P.jadeDeep)
    if north then
        r(cx - 2, top + 1, 4, 3, P.ink); r(cx - 1, top + 2, 2, 1, P.jadeMid)
    end
    -- Carapaça: domo de três placas — luz de loma à esquerda, saia
    -- ventral em escama, fendas de placa no lombo.
    p({cx - 13, top + 9, cx - 8, top + 2, cx + 7, top + 2, cx + 13, top + 8,
        cx + 12, top + 16, cx - 12, top + 16}, P.ink)
    p({cx - 12, top + 9, cx - 7, top + 3, cx + 7, top + 3, cx + 12, top + 8,
        cx + 11, top + 15, cx - 11, top + 15}, P.jadeDark)
    p({cx - 11, top + 9, cx - 7, top + 4, cx - 2, top + 4, cx - 5, top + 13,
        cx - 11, top + 13}, P.jadeMid)
    p({cx - 6, top + 3, cx - 2, top + 3, cx - 3, top + 13, cx - 6, top + 13},
        P.jade)
    p({cx + 5, top + 4, cx + 10, top + 8, cx + 10, top + 14, cx + 4, top + 14},
        P.jadeDeep)
    l(cx - 10, top + 9, cx - 7, top + 4, P.jadeLight)
    l(cx - 6, top + 3, cx - 2, top + 3, P.jadeLight)            -- reborde do lombo
    l(cx - 1, top + 3, cx - 2, top + 14, P.ink)                 -- fenda de placa
    l(cx + 5, top + 3, cx + 4, top + 14, P.ink)
    d(cx - 4, top + 5, 4, 8, P.jadeMid, .35)
    d(cx - 10, top + 11, 21, 4, P.jadeDeep, .4)
    l(cx - 11, top + 14, cx + 11, top + 14, P.stoneDeep)        -- saia ventral
    -- Escamas da saia: três dentes baixos sob a linha ventral.
    r(cx - 8, top + 15, 2, 1, P.jadeMid); r(cx - 1, top + 15, 2, 1, P.jadeMid)
    r(cx + 6, top + 15, 2, 1, P.jadeMid)
    -- Espinhos da crista: três pontas de casco no dorso.
    l(cx - 6, top + 3, cx - 6, top, P.jadeLight); l(cx, top + 3, cx, top, P.jadeLight)
    l(cx + 6, top + 3, cx + 6, top, P.jadeLight)
    -- Trincas de casco trabalhado.
    l(cx - 8, top + 6, cx - 6, top + 11, P.ink)
    l(cx + 2, top + 5, cx + 3, top + 10, P.jadeMid)
    l(cx - 2, top + 7, cx - 3, top + 11, P.jadeDeep)
    -- Cabeça: projetada para a direção encarada — mandíbula de dois
    -- segmentos, cluster de três olhos de brasa, palpos curtos.
    local hx = side ~= 0 and cx + side * 13 or cx
    local hy = north and top + 1 or south and top + 14 or top + 8
    if not north then
        p({hx - 4, hy - 4, hx + 3, hy - 4, hx + 5 + side, hy, hx + 3, hy + 6,
            hx - 4, hy + 6, hx - 5 + side, hy}, P.ink)
        p({hx - 3, hy - 3, hx + 2, hy - 3, hx + 4 + side, hy, hx + 2, hy + 5,
            hx - 3, hy + 5, hx - 4 + side, hy}, P.jadeDark)
        l(hx - 3, hy - 3, hx + 1, hy - 3, P.jadeMid)            -- testa lavada
        -- Palpos curtos à frente do focinho.
        l(hx + side * 4, hy - 2, hx + side * 6, hy - 4, P.ink)
        l(hx + side * 5, hy + 1, hx + side * 7, hy, P.ink)
        -- Mandíbula articulada: articulação + ponta afastada.
        l(hx + side * 3, hy + 5, hx + side * 5, hy + 7, P.ink)
        l(hx + side * 5, hy + 7, hx + side * 7, hy + 6, P.stoneDark)
        l(hx - 1 + side * 3, hy + 5, hx - 2 + side * 4, hy + 7, P.ink)
        local eyH = action == 'warn' and 3 or action == 'hurt' and 1 or 2
        r(hx - 2 + side * 2, hy - 2, 2, eyH, P.ember)
        r(hx + 1 + side * 2, hy - 2, 1, eyH, P.ember)
        r(hx - 2 + side * 2, hy - 2, 1, 1, P.emberLight)
        r(hx + 1 + side * 2, hy - 2, 1, 1, P.emberLight)
        r(hx - 1 + side * 1, hy + 1, 1, 1, P.ember)             -- terceiro olho
        if action == 'hurt' then
            l(hx - 2 + side * 2, hy - 3, hx + 1 + side * 2, hy - 3, P.ink)
        end
        if action == 'warn' then
            l(hx - 1 + side * 4, hy + 4, hx + side * 7, hy + 8, P.white)
        end
    else
        -- De costas a cabeça some sob o casco — ficam os cercos.
        r(cx - 5, top, 10, 4, P.ink); r(cx - 4, top + 1, 8, 2, P.jadeDark)
        r(cx - 4, top, 2, 1, P.jade); r(cx + 2, top, 2, 1, P.jade)
    end
    if action == 'warn' then r(cx - 3, top + 1, 6, 2, P.danger) end
end

-- HUSK: mortalha flutuante em CAMADAS de trapos — três painéis de pano
-- com fendas de tinta entre eles, barra desfiada em tiras, capuz
-- pontudo tombado e janela de rosto oco. Nunca toca o chão.
local function huskV2(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local drift = frame % 2 == 0 and -1 or 0
    local side = direction == 1 and 1 or direction == 3 and -1 or 0
    local south, north = direction == 2, direction == 4
    local cx = 16
    if action == 'death' and frame >= 3 then
        -- A mortalha esvazia no chão: pano aberto, trapos espalhados.
        p({cx - 10, 40, cx - 6, 35, cx + 6, 35, cx + 10, 40}, P.ink)
        p({cx - 9, 40, cx - 5, 36, cx + 5, 36, cx + 9, 40}, P.goldDark)
        p({cx - 4, 39, cx + 3, 37, cx + 7, 41, cx - 6, 41}, P.rust)
        l(cx - 7, 38, cx - 2, 40, P.goldDeep)
        l(cx + 1, 37, cx + 5, 41, P.ink)
        r(cx - 1, 36, 3, 2, P.jade); return
    end
    local top = 8 + drift
    local hem = 38 + drift
    -- Três painéis de pano: esquerdo lavado pela lua, direito em
    -- ferrugem funda — as fendas de tinta entre eles dão a camada.
    p({cx - 5, top + 13, cx + 5, top + 13, cx + 7, 24, cx + 4, hem,
        cx - 4, hem, cx - 7, 24}, P.ink)
    p({cx - 4, top + 14, cx + 4, top + 14, cx + 6, 24, cx + 3, hem - 1,
        cx - 3, hem - 1, cx - 6, 24}, P.goldDark)
    p({cx - 4, top + 14, cx, top + 14, cx - 2, 25, cx - 4, hem - 1,
        cx - 6, 24}, P.gold)
    p({cx + 1, top + 14, cx + 4, top + 14, cx + 5, 25, cx + 3, hem - 1,
        cx + 1, hem - 1}, P.rust)
    -- Fendas entre painéis: o pano é feito de tiras costuradas.
    l(cx - 1, top + 15, cx - 2, hem - 4, P.ink)
    l(cx + 2, top + 16, cx + 2, hem - 6, P.goldDeep)
    l(cx - 4, top + 18, cx - 5, hem - 5, P.goldDeep)
    -- Trama da mortalha + prega central.
    d(cx - 4, 26, 8, 10, P.goldDeep, .25)
    l(cx - 3, 24, cx - 4, hem - 2, P.goldDeep)
    -- Barra desfiada: tiras individuais tombando contra o encarado.
    local sway = -side * 2 - drift
    l(cx - 4, hem - 2, cx - 6 + sway, hem + 2, P.ink)
    l(cx - 1, hem - 1, cx - 1 + sway, hem + 3, P.ink)
    l(cx + 3, hem - 2, cx + 5 + sway, hem + 2, P.ink)
    l(cx - 4, hem - 2, cx - 5 + sway, hem + 1, P.goldDark)
    l(cx - 1, hem - 1, cx - 1 + sway, hem + 2, P.gold)
    l(cx + 3, hem - 2, cx + 4 + sway, hem + 1, P.rust)
    l(cx + 1, hem - 3, cx + 2 + sway, hem, P.goldDeep)
    -- Capuz pontudo tombado na direção encarada, com vinco de dobra.
    local tip = side * 4
    p({cx - 5, top + 9, cx - 2, top - 1, cx + 3 + tip, top - 5,
        cx + 6 + tip, top + 4, cx + 5, top + 13, cx - 4, top + 13}, P.ink)
    p({cx - 4, top + 9, cx - 2, top + 1, cx + 3 + tip, top - 4,
        cx + 5 + tip, top + 4, cx + 4, top + 12, cx - 3, top + 12}, P.goldDark)
    p({cx - 4, top + 9, cx - 2, top + 1, cx + 1 + tip, top - 3, cx + 1,
        top + 12}, P.gold)
    l(cx - 2, top + 2, cx + 2 + tip, top + 5, P.goldDeep)       -- vinco do capuz
    if north then
        l(cx - 3, top + 4, cx + 3, top + 4, P.goldDeep)
        l(cx - 2, top + 8, cx + 2, top + 8, P.goldDeep)
        d(cx - 3, top + 3, 6, 8, P.ink, .25)
        l(cx, top + 5, cx - 1, top + 11, P.rust)                -- prega traseira
    elseif side ~= 0 then
        local jx = side == 1 and cx + 1 or cx - 5
        r(jx, top + 5, 5, 6, P.ink)
        r(jx + 1, top + 6, 3, 4, P.goldDeep)
        r(jx + (side == 1 and 2 or 0), top + 6, 1, 2, P.emberLight)
        r(jx + (side == 1 and 2 or 0), top + 9, 2, 1, P.goldDeep)
        r(jx + 1, top + 6, 3, 1, P.rust)                        -- aro da janela
    else
        r(cx - 2, top + 6, 4, 6, P.ink)
        local tall = action == 'warn' and 3 or action == 'hurt' and 1 or 2
        r(cx - 2, top + 7, 1, tall, P.emberLight)
        r(cx + 1, top + 7, 1, tall, P.ember)
        if action == 'hurt' then
            r(cx - 1, top + 10, 2, 2, P.goldDeep)
        else
            r(cx - 1, top + 10, 2, 1, P.goldDeep)
        end
    end
    -- Faixa de pano voando atrás + fiapo desfeito pendurado.
    l(cx - 5, top + 15, cx - 9 + sway, top + 19, P.ink)
    l(cx - 5, top + 15, cx - 8 + sway, top + 18, P.goldDark)
    l(cx + 5, top + 17, cx + 7 + sway, top + 22, P.rust)
    if frame % 4 == 3 then
        l(cx - 1, top + 16, cx - 2, 25, P.emberLight)
        l(cx + 2, top + 18, cx + 1, 28, P.ember)
        r(cx + 3, 23, 1, 1, P.goldLight)
    end
    if action == 'warn' then
        l(cx - 3 + tip, top - 5, cx + 3 + tip, top - 5, P.emberLight)
        r(cx - 1 + tip, top - 7, 2, 1, P.white)
    end
end

-- CASULO do husk (e.hatch > 0): fardo de pano com laços cruzados, nó
-- lateral e núcleo âmbar pulsando pelas emendas — dorme e conta.
local function huskCocoonV2(data, ox, oy, direction, action, frame)
    local r, l, p, d = painter(data, ox, oy)
    local cx = 16
    if action == 'death' and frame >= 3 then
        p({cx - 10, 40, cx - 6, 35, cx + 6, 35, cx + 10, 40}, P.ink)
        p({cx - 9, 40, cx - 5, 36, cx + 5, 36, cx + 9, 40}, P.goldDark)
        l(cx - 6, 38, cx + 5, 37, P.rust)
        l(cx - 2, 39, cx + 2, 36, P.goldDeep)
        return
    end
    local bob = action == 'move' and (({1, -1, -2, -2, -1, 1})[frame] or 0)
        or (frame % 3 == 0 and -1 or 0)
    local top = 9 + bob
    p({cx - 2, top, cx + 2, top, cx + 5, top + 5, cx + 6, 22,
        cx + 4, 37, cx - 4, 37, cx - 6, 22, cx - 5, top + 5}, P.ink)
    p({cx - 1, top + 1, cx + 1, top + 1, cx + 4, top + 5, cx + 5, 22,
        cx + 3, 36, cx - 3, 36, cx - 5, 22, cx - 4, top + 5}, P.goldDark)
    p({cx - 1, top + 1, cx, top + 1, cx - 3, top + 5, cx - 4, 22,
        cx - 2, 35, cx - 4, 35, cx - 6, 22, cx - 4, top + 5}, P.gold)
    p({cx + 1, top + 2, cx + 3, top + 5, cx + 4, 22, cx + 2, 35, cx + 1, 35},
        P.rust)
    -- Costuras verticais do enrolado: o fardo é pano em volta de algo.
    l(cx - 3, top + 6, cx - 4, 30, P.goldDeep)
    l(cx + 3, top + 7, cx + 3, 32, P.goldDeep)
    d(cx - 4, top + 8, 4, 20, P.goldDeep, .2)
    -- Núcleo âmbar sob os laços: pulsa devagar — a eclosão dormindo.
    local glow = action == 'warn' and .8 or frame % 2 == 0 and .65 or .35
    d(cx - 2, 20, 5, 4, P.ember, glow * .5)
    r(cx - 1, 21, 3, 2, P.ember)
    r(cx, 21, 1, 1, glow > .5 and P.white or P.emberLight)
    -- Laços de pano: três faixas cruzando o ventre + nó lateral; a
    -- luz vaza nas bordas da faixa do meio.
    l(cx - 5, top + 9, cx + 5, top + 9, P.ink)
    l(cx - 4, top + 10, cx + 4, top + 10, P.rust)
    l(cx - 6, 26, cx + 6, 26, P.ink)
    l(cx - 5, 27, cx + 5, 27, P.rust)
    l(cx - 5, 27, cx - 4, 27, P.emberLight)
    l(cx - 5, 32, cx + 5, 32, P.ink)
    l(cx - 4, 33, cx + 4, 33, P.rust)
    r(cx + 5, 25, 2, 2, P.goldDark)
    r(cx + 5, 26, 2, 1, P.gold)                               -- nó lateral
    if action == 'hurt' then
        l(cx - 2, 14, cx + 2, 18, P.emberLight)
        l(cx - 3, 15, cx - 1, 17, P.ember)
    end
end

-- BRUTOS DE PEDRA — passe de densidade: placas com rebordes, trincas,
-- musgo nas juntas, polimento do olho e flare de warn legível.
local function sentinelV2(data, ox, oy, direction, action, frame, sk)
    sk = sk or {}
    local cape = sk.cape or P.jadeDark
    local capeLine = sk.capeLine or P.jade
    local shell = sk.shell or P.stoneLight
    local shellHi = sk.shellHi or P.stoneEdge
    local shellDeep = sk.shellDeep or P.stoneDeep
    local body = sk.body or P.stone
    local bodyDark = sk.bodyDark or P.stoneDark
    local trim = sk.trim or P.gold
    local trimDark = sk.trimDark or P.goldDark
    local trimLight = sk.trimLight or P.goldLight
    local eye = sk.eye or P.ember
    local eyeLow = sk.eyeLow or P.jade
    local r, l, p, d = painter(data, ox, oy)
    local bob, leg, capeSway, lean, squat = pose(action, frame)
    local side = direction == 1 and 1 or direction == 3 and -1 or 0
    local south, north = direction == 2, direction == 4
    local cx = 16 + side * lean
    local war = action == 'warn'
    if action == 'death' and frame >= 4 then
        p({3, 41, 9, 34, 23, 36, 29, 44, 7, 45}, bodyDark)
        r(8, 36, 13, 4, shell); r(8, 36, 13, 1, shellHi)
        r(12, 39, 5, 2, capeLine)
        l(15, 37, 18, 39, P.ink)                              -- trinca na queda
        return
    end
    local v = sk.build or 'brute'

    if v == 'brute' then
        local top = 14 + bob + squat
        r(cx - 8, 36 + math.min(2, leg), 5, 8, P.ink)
        r(cx - 8, 37 + math.min(2, leg), 3, 6, bodyDark)
        r(cx + 4, 35 - math.min(2, leg), 5, 9, P.ink)
        r(cx + 4, 36 - math.min(2, leg), 3, 7, body)
        r(cx + 4, 36 - math.min(2, leg), 3, 1, shellHi)
        -- Braços-pilar até o chão: antebraço largo + punho de bloco,
        -- juntas de dedo no apoio.
        r(cx - 13, top + 16, 6, 22, P.ink); r(cx + 8, top + 16, 6, 22, P.ink)
        r(cx - 12, top + 17, 4, 19, shell); r(cx + 9, top + 17, 4, 19, bodyDark)
        l(cx - 12, top + 18, cx - 12, top + 30, shellHi)      -- rim do braço
        r(cx - 13, top + 34, 6, 6, P.ink); r(cx + 8, top + 34, 6, 6, P.ink)
        r(cx - 12, top + 35, 4, 4, bodyDark); r(cx + 9, top + 35, 4, 4, bodyDark)
        l(cx - 12, top + 37, cx - 9, top + 37, P.ink)         -- juntas do punho
        l(cx + 9, top + 37, cx + 12, top + 37, P.ink)
        -- Tronco tombado: ombros altos atrás, barriga baixa à frente.
        p({cx - 11, top + 6, cx + 9, top + 9, cx + 12, top + 18,
            cx + 10, top + 26, cx - 9, top + 26, cx - 12, top + 12}, P.ink)
        p({cx - 10, top + 7, cx + 8, top + 10, cx + 11, top + 18,
            cx + 9, top + 25, cx - 8, top + 25, cx - 11, top + 12}, body)
        p({cx - 10, top + 7, cx - 2, top + 8, cx - 6, top + 22,
            cx - 10, top + 18}, shell)
        p({cx + 6, top + 11, cx + 10, top + 18, cx + 8, top + 24,
            cx + 4, top + 24}, shellDeep)
        l(cx - 10, top + 7, cx - 2, top + 8, shellHi)
        l(cx - 10, top + 12, cx - 8, top + 20, shellHi)       -- rim esquerdo
        d(cx + 4, top + 12, 3, 12, shellDeep, .4)
        -- Junções de placa + musgo nas fendas (pedra que dormiu fora).
        l(cx - 2, top + 10, cx, top + 20, P.ink)
        r(cx - 1, top + 14, 1, 1, P.jadeDark); r(cx + 3, top + 17, 1, 1, P.jadeDark)
        l(cx - 6, top + 15, cx - 4, top + 21, shellDeep)      -- trinca
        -- Cabeça de elmo baixa e à frente — fenda de olho + queixo.
        p({cx - 6, top + 4, cx - 1, top, cx + 5, top + 4, cx + 6, top + 11,
            cx - 4, top + 12}, P.ink)
        p({cx - 5, top + 5, cx - 1, top + 1, cx + 4, top + 5, cx + 5, top + 10,
            cx - 4, top + 11}, shell)
        l(cx - 5, top + 5, cx - 1, top + 1, shellHi)
        if south then
            r(cx - 4, top + 6, 9, 3, P.ink)
            r(cx - 4, top + 7, 3, 2, eye); r(cx + 1, top + 7, 3, 2, eyeLow)
            r(cx - 4, top + 7, 1, 1, P.white); r(cx + 1, top + 7, 1, 1, P.white)
            r(cx - 4, top + 10, 7, 2, bodyDark)
            l(cx - 3, top + 11, cx + 2, top + 11, P.ink)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 2 or cx - 6
            r(ex, top + 5, 3, 5, P.ink); r(ex, top + 6, 3, 3, eye)
            r(ex, top + 6, 1, 1, P.white)
            r(side == 1 and cx + 4 or cx - 5, top + 9, 2, 3, bodyDark)
        else
            l(cx - 3, top + 5, cx + 3, top + 5, bodyDark)
            l(cx - 2, top + 7, cx + 2, top + 8, shellDeep)    -- suture do elmo
        end
        l(cx - 8, top + 5, cx + 4, top + 5, trimDark)
        if war then
            r(cx - 1, top - 2, 3, 2, trimLight)
            l(cx - 3, top - 1, cx + 4, top - 1, trimLight)
        end
    elseif v == 'bull' then
        local top = 7 + bob + squat
        r(cx - 13 - math.min(2, leg), 34 + math.min(2, leg), 6, 10, P.ink)
        r(cx - 12 - math.min(2, leg), 35 + math.min(2, leg), 4, 8, body)
        r(cx + 7 + math.min(2, leg), 34 - math.min(2, leg), 6, 10, P.ink)
        r(cx + 8 + math.min(2, leg), 35 - math.min(2, leg), 4, 8, bodyDark)
        l(cx - 12 - math.min(2, leg), 35 + math.min(2, leg), cx - 12 -
            math.min(2, leg), 41, shellHi)
        p({cx - 6, 32, cx + 6, 32, cx + 8, 26, cx - 8, 26}, P.ink)
        p({cx - 5, 32, cx + 5, 32, cx + 7, 27, cx - 7, 27}, bodyDark)
        p({cx - 13, top + 4, cx + 13, top + 4, cx + 11, top + 22, cx + 6, 28,
            cx - 6, 28, cx - 11, top + 22}, P.ink)
        p({cx - 12, top + 5, cx + 12, top + 5, cx + 10, top + 21, cx + 5, 27,
            cx - 5, 27, cx - 10, top + 21}, body)
        p({cx - 12, top + 5, cx - 4, top + 5, cx - 7, top + 20,
            cx - 10, top + 20}, shell)
        p({cx + 6, top + 5, cx + 12, top + 5, cx + 10, top + 21,
            cx + 7, top + 21}, shellDeep)
        l(cx - 12, top + 5, cx - 4, top + 5, shellHi)
        l(cx - 10, top + 9, cx - 8, top + 18, shellHi)
        d(cx + 6, top + 8, 4, 12, shellDeep, .35)
        -- Fenda central do peito + laje pectoral + musgo na axila.
        l(cx - 1, top + 8, cx - 2, top + 19, P.ink)
        r(cx - 4, top + 6, 8, 3, shell)
        r(cx - 4, top + 6, 8, 1, shellHi)
        r(cx + 2, top + 16, 1, 1, P.jadeDark); r(cx + 4, top + 19, 1, 1, P.jadeDark)
        r(cx - 7, 24, 14, 3, trimDark); r(cx - 7, 24, 11, 1, trim)
        r(cx - 7, 24, 2, 3, trim)                             -- fivela do peitoral
        -- Braços de peso pendendo ao longo do V + juntas.
        r(cx - 15, top + 10, 5, 16, P.ink); r(cx + 10, top + 10, 5, 16, P.ink)
        r(cx - 14, top + 11, 3, 13, bodyDark); r(cx + 11, top + 11, 3, 13, bodyDark)
        l(cx - 14, top + 18, cx - 12, top + 18, P.ink)
        l(cx + 11, top + 18, cx + 13, top + 18, P.ink)
        r(cx - 14, top + 23, 3, 2, body)                      -- nós do punho
        r(cx + 11, top + 23, 3, 2, body)
        -- Cabeça afundada no V: elmo baixo, fenda de olhos, queixo.
        p({cx - 6, top + 3, cx - 3, top, cx + 3, top, cx + 6, top + 3,
            cx + 5, top + 10, cx - 5, top + 10}, P.ink)
        p({cx - 5, top + 3, cx - 3, top + 1, cx + 3, top + 1, cx + 5, top + 4,
            cx + 4, top + 9, cx - 4, top + 9}, shell)
        l(cx - 5, top + 3, cx - 3, top + 1, shellHi)
        if south then
            r(cx - 4, top + 4, 8, 3, P.ink)
            r(cx - 4, top + 5, 3, 2, eye); r(cx + 1, top + 5, 3, 2, eyeLow)
            r(cx - 4, top + 5, 1, 1, P.white); r(cx + 1, top + 5, 1, 1, P.white)
            r(cx - 4, top + 8, 8, 2, bodyDark)
            l(cx - 3, top + 9, cx + 3, top + 9, P.ink)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 5
            r(ex, top + 4, 3, 4, P.ink); r(ex, top + 5, 3, 2, eye)
            r(ex, top + 5, 1, 1, P.white)
        else l(cx, top + 3, cx + 1, top + 8, bodyDark) end
        -- Chifres longos de carga — dentro do frame, com serra na base.
        local hx = 12
        l(cx - 7, top + 1, cx - hx, top - 4, P.ink)
        l(cx + 7, top + 1, cx + hx, top - 4, P.ink)
        l(cx - 7, top + 1, cx - hx + 1, top - 3, trimLight)
        l(cx + 7, top + 1, cx + hx - 1, top - 3, trimLight)
        l(cx - hx + 1, top - 3, cx - hx + 3, top - 6, trim)
        l(cx + hx - 1, top - 3, cx + hx - 3, top - 6, trim)
        r(cx - 8, top + 1, 2, 2, trimDark); r(cx + 6, top + 1, 2, 2, trimDark)
        if war then l(cx - 4, top - 1, cx + 4, top - 1, trimLight) end
    elseif v == 'ruin' then
        local top = 8 + bob + squat
        r(cx - 9, 37 + math.min(2, leg), 6, 7, P.ink)
        r(cx + 3, 36 - math.min(2, leg), 6, 8, P.ink)
        r(cx - 8, 38 + math.min(2, leg), 4, 5, body)
        r(cx + 4, 37 - math.min(2, leg), 4, 6, bodyDark)
        -- Braço descomunal: ombro-laje + antebraço + punho no chão.
        p({cx - 16, top + 2, cx - 7, top + 2, cx - 9, 40, cx - 14, 40}, P.ink)
        p({cx - 15, top + 3, cx - 8, top + 3, cx - 9, 39, cx - 13, 39}, shell)
        p({cx - 15, top + 3, cx - 12, top + 3, cx - 13, 39, cx - 14, 39}, shellDeep)
        l(cx - 15, top + 4, cx - 10, top + 4, shellHi)
        l(cx - 12, top + 8, cx - 10, 30, P.ink)               -- fenda do braço
        r(cx - 12, top + 12, 1, 1, P.jadeDark); r(cx - 11, top + 20, 1, 1, P.jadeDark)
        r(cx - 15, 38, 6, 6, P.ink); r(cx - 14, 39, 4, 4, bodyDark)
        l(cx - 14, 41, cx - 11, 41, P.ink)                    -- nós dos dedos
        r(cx - 17, top - 2, 9, 6, P.ink); r(cx - 16, top - 1, 7, 4, shell)
        r(cx - 16, top - 1, 7, 1, shellHi)
        -- Tronco inclinado à esquerda sob a carga.
        p({cx - 8, top + 6, cx + 8, top + 4, cx + 10, 34, cx - 7, 36}, P.ink)
        p({cx - 7, top + 7, cx + 7, top + 5, cx + 9, 33, cx - 6, 35}, body)
        p({cx - 7, top + 7, cx - 1, top + 6, cx - 3, 34, cx - 6, 34}, shell)
        p({cx + 4, top + 5, cx + 7, top + 5, cx + 9, 33, cx + 6, 33}, shellDeep)
        l(cx - 7, top + 7, cx - 1, top + 6, shellHi)
        l(cx + 1, top + 9, cx + 2, top + 26, P.ink)           -- trinca do flanco
        r(cx + 4, top + 12, 1, 1, P.jadeDark)
        r(cx - 6, 30, 14, 3, trimDark); r(cx - 6, 30, 11, 1, trim)
        r(cx + 8, top + 8, 5, 14, P.ink); r(cx + 9, top + 9, 3, 12, bodyDark)
        l(cx + 9, top + 14, cx + 11, top + 14, P.ink)
        p({cx - 5, top + 2, cx - 2, top - 1, cx + 5, top + 2, cx + 6, top + 9,
            cx - 4, top + 11}, P.ink)
        p({cx - 4, top + 3, cx - 2, top, cx + 4, top + 3, cx + 5, top + 8,
            cx - 3, top + 10}, shell)
        l(cx - 4, top + 3, cx - 2, top, shellHi)
        if south then
            r(cx - 3, top + 5, 8, 3, P.ink)
            r(cx - 3, top + 6, 3, 2, eye); r(cx + 1, top + 6, 3, 2, eyeLow)
            r(cx - 3, top + 6, 1, 1, P.white)
            r(cx - 3, top + 9, 7, 2, bodyDark)
            l(cx - 2, top + 10, cx + 3, top + 10, P.ink)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 4
            r(ex, top + 5, 3, 4, P.ink); r(ex, top + 6, 3, 2, eye)
            r(ex, top + 6, 1, 1, P.white)
        else l(cx, top + 3, cx + 1, top + 8, bodyDark) end
        if war then
            r(cx - 1, top - 2, 3, 2, trimLight)
            l(cx - 3, top - 1, cx + 4, top - 1, trimLight)
        end
    else
        -- WARDEN (tower): coluna cerimonial — mesma torre + veios de
        -- selo descendo a face do escudo e degraus na mitra.
        local top = 8 + bob + squat
        r(cx - 6, 39 + math.min(2, leg), 6, 5, P.ink)
        r(cx + 1, 39 - math.min(2, leg), 6, 5, P.ink)
        r(cx - 5, 40 + math.min(2, leg), 4, 2, body)
        r(cx + 2, 40 - math.min(2, leg), 4, 2, bodyDark)
        p({cx - 8, top + 10, cx + 8, top + 10, cx + 9, 39, cx - 9, 39}, P.ink)
        p({cx - 7, top + 11, cx + 7, top + 11, cx + 8, 38, cx - 8, 38}, body)
        p({cx - 7, top + 11, cx - 2, top + 11, cx - 4, 38, cx - 8, 38}, shell)
        p({cx + 4, top + 11, cx + 7, top + 11, cx + 8, 38, cx + 5, 38}, shellDeep)
        l(cx - 7, top + 11, cx - 8, 37, shellHi)
        -- Placas da coluna: dois filetes horizontais + emenda central.
        l(cx - 6, top + 18, cx + 6, top + 18, P.ink)
        l(cx - 6, top + 26, cx + 6, top + 26, bodyDark)
        l(cx - 1, top + 14, cx - 2, top + 32, shellDeep)
        r(cx + 3, top + 20, 1, 1, P.jadeDark)
        r(cx - 8, 36, 16, 2, bodyDark); l(cx - 7, 36, cx + 7, 36, trim)
        r(cx - 7, top + 9, 14, 2, trimDark); r(cx - 7, top + 9, 11, 1, trim)
        if north then
            l(cx, top + 12, cx, 34, trimDark)
            l(cx - 3, top + 16, cx - 3, 30, trimDark)
        else
            p({cx - 2, top + 15, cx + 2, top + 15, cx + 3, top + 24,
                cx - 3, top + 24}, trimDark)
            p({cx - 1, top + 16, cx + 1, top + 16, cx + 2, top + 23,
                cx - 2, top + 23}, trim)
        end
        p({cx - 6, top + 2, cx - 2, top - 1, cx + 3, top - 1, cx + 6, top + 3,
            cx + 5, top + 9, cx - 5, top + 9}, P.ink)
        p({cx - 5, top + 2, cx - 2, top, cx + 3, top, cx + 5, top + 3,
            cx + 4, top + 8, cx - 4, top + 8}, shell)
        l(cx - 5, top + 2, cx - 2, top, shellHi)
        if south then
            r(cx - 4, top + 4, 8, 3, P.ink)
            r(cx - 3, top + 5, 2, 2, eye); r(cx + 1, top + 5, 2, 2, eyeLow)
            r(cx - 3, top + 5, 1, 1, P.white); r(cx + 1, top + 5, 1, 1, P.white)
            r(cx - 3, top + 8, 6, 2, bodyDark)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 4
            r(ex, top + 4, 3, 4, P.ink); r(ex, top + 5, 3, 2, eye)
            r(ex, top + 5, 1, 1, P.white)
        else l(cx, top + 2, cx + 1, top + 7, bodyDark) end
        p({cx - 5, top - 1, cx - 2, top - 8, cx + 2, top - 8, cx + 5, top - 1},
            P.ink)
        p({cx - 4, top - 1, cx - 2, top - 7, cx + 2, top - 7, cx + 4, top - 1},
            trimDark)
        p({cx - 4, top - 1, cx - 2, top - 7, cx, top - 7, cx - 2, top - 1}, trim)
        r(cx, top - 8, 1, 1, trimLight)
        l(cx - 3, top - 4, cx + 3, top - 4, P.ink)              -- degrau da mitra
        if south then
            r(cx + 7, top + 12, 4, 18, P.ink); r(cx + 8, top + 13, 2, 16, shell)
            r(cx + 8, top + 13, 2, 2, trimLight)
            l(cx + 8, top + 26, cx + 9, top + 26, trim)
            l(cx + 9, top + 15, cx + 9, top + 27, shellDeep)  -- veio do selo
        elseif side ~= 0 then
            r(cx + side * 9 - 1, top + 12, 4, 18, P.ink)
            r(cx + side * 9, top + 13, 2, 16, shell)
            r(cx + side * 9, top + 13, 2, 2, trimLight)
            l(cx + side * 9 + (side == 1 and 0 or -1), top + 15,
                cx + side * 9 + (side == 1 and 0 or -1), top + 27, shellDeep)
        end
        if war then l(cx - 4, top - 1, cx + 4, top - 1, trimLight) end
    end
    if v ~= 'brute' then
        l(cx - 8, 37, cx - 9, 41, cape); l(cx + 8, 37, cx + 9, 41, capeLine)
    end
    -- Fuligem de guerra nas juntas: trincas estáveis no dorso e sombra
    -- de solda entre placas.
    l(cx - 2, 32, cx - 4, 36, shellDeep)
    l(cx + 3, 35, cx + 5, 39, P.ink)
    r(cx - 1, 30, 1, 2, P.ink)
    l(cx - 3, 38, cx + 3, 38, P.ink)
end

-- DEVOTOS — passe de densidade por ofício: scout lê a besta, loader lê
-- o cesto, needle lê a flutuação, block lê a veterania, regal lê a coroa.
local function zealotV2(data, ox, oy, direction, action, frame, cfg)
    local r, l, p, d = painter(data, ox, oy)
    local bob, leg, cape, lean, squat = pose(action, frame)
    local east, south, west, north = direction == 1, direction == 2,
        direction == 3, direction == 4
    local side = east and 1 or west and -1 or 0
    local aim = action == 'warn' or action == 'dash'
    local robe, robeDark, robeLight = cfg.robe, cfg.robeDark, cfg.robeLight
    local robeDeep = cfg.robeDeep or P.violetDeep
    local hood = cfg.hood or robe
    local trim = cfg.trim or P.gold
    local trimDark = cfg.trimDark or P.goldDark
    local trimLight = cfg.trimLight or P.goldLight
    local eye = cfg.eye or P.goldLight
    local skin = cfg.skin or P.bone
    local cx = 16 + side * lean
    local build = cfg.build or 'block'
    if action == 'death' and frame >= 4 then
        p({5, 41, 11, 34, 22, 38, 27, 44, 8, 45}, robeDark)
        r(10, 38, 9, 3, robe); r(14, 37, 4, 1, trim)
        l(9, 40, 13, 42, P.ink); return
    end
    local stL = leg > 0 and math.min(3, leg) or 0
    local stR = leg < 0 and math.min(3, -leg) or 0

    if build == 'scout' then
        -- RANGER: talhe oblíquo — pernas finas abertas, torso curto,
        -- capuz baixo, besta atravessando o corpo na diagonal.
        local top = 7 + bob + squat
        r(cx - 5 - stL, 34 + stL, 3, 10 - stL, P.ink)
        r(cx - 4 - stL, 34 + stL, 2, 8 - stL, robeDark)
        r(cx + 3 + stR, 36 + stR, 3, 8 - stR, P.ink)
        r(cx + 3 + stR, 36 + stR, 2, 6 - stR, robeDeep)
        r(cx - 6 - stL, 40 + stL, 5, 3, P.ink); r(cx + 3 + stR, 41 + stR, 5, 3, P.ink)
        r(cx - 6 - stL, 40 + stL, 2, 1, robeDark)             -- biqueira
        -- Faixa de canela (caneleira de pano) + joelho marcado.
        r(cx - 4 - stL, 37 + stL, 2, 1, trimDark)
        r(cx + 3 + stR, 38 + stR, 2, 1, trimDark)
        -- Torso curto tombado + manto curto aberto nas laterais.
        p({cx - 5, top + 12, cx + 7, top + 10, cx + 8, 34, cx - 6, 35}, P.ink)
        p({cx - 4, top + 13, cx + 6, top + 11, cx + 7, 33, cx - 5, 34}, robe)
        p({cx + 3, top + 11, cx + 6, top + 11, cx + 7, 33, cx + 4, 33}, robeDeep)
        l(cx - 4, top + 13, cx - 5, 33, robeLight)
        l(cx - 3, top + 14, cx - 4, 30, robeLight)            -- vinco do manto
        r(cx - 5, top + 24, 11, 2, trimDark); r(cx - 5, top + 24, 8, 1, trim)
        r(cx + 3, top + 24, 2, 2, trim)                       -- fivela
        -- Peitilho de couro com talabarte: duas faixas cruzadas.
        l(cx - 3, top + 14, cx + 4, top + 24, trimDark)
        l(cx - 2, top + 14, cx + 5, top + 24, P.goldDeep)
        -- Besta de caça (âncora): coronha curta nivelada na frente do
        -- peito, arco em asa na ponta e corda esticada — lê o ofício
        -- sem sair do frame.
        local fs = side ~= 0 and side or 1
        if side ~= 0 or north then
            -- De lado/costas a besta vai nivelada ao peito apontando
            -- para a frente; a mão da corda trava no gatilho.
            local bx, by = cx + fs * 4, top + 15
            l(cx - fs * 2, by + 3, bx + fs * 6, by, trimDark) -- coronha
            l(cx - fs * 2, by + 3, bx + fs * 4, by + 1, trim)
            l(bx + fs * 5, by - 4, bx + fs * 6, by, trim)     -- asa de cima
            l(bx + fs * 5, by + 5, bx + fs * 6, by, trim)     -- asa de baixo
            l(bx + fs * 5, by - 4, bx + fs * 2, by, P.bone)   -- corda
            l(bx + fs * 5, by + 5, bx + fs * 2, by, P.bone)
            r(cx - fs * 1, by + 2, 2, 3, skin)                -- mão no gatilho
            r(cx - fs * 3, by + 3, 2, 8, robeDark)            -- braço sob a coronha
        else
            -- De frente a besta descansa no quadril: coronha curta na
            -- vertical, asa e corda cruzando a saia.
            local bx = cx + 8
            l(bx, top + 18, bx, top + 30, trimDark)
            l(bx - 4, top + 17, bx, top + 19, trim)
            l(bx + 4, top + 17, bx, top + 19, trim)
            l(bx - 4, top + 17, bx, top + 26, P.bone)
            l(bx + 4, top + 17, bx, top + 26, P.bone)
            r(cx + 5, top + 20, 3, 8, robeDark)               -- braço na coronha
            r(cx + 5, top + 27, 3, 2, skin)
        end
        if north then
            -- Aljava abaixo do capuz: fletchas de osso no dorso.
            r(cx - 10, top + 8, 4, 10, P.ink)
            r(cx - 9, top + 9, 2, 8, trimDark)
            l(cx - 10, top + 4, cx - 9, top + 9, P.bone)
            l(cx - 8, top + 3, cx - 8, top + 8, P.bone)
            l(cx - 10, top + 4, cx - 9, top + 3, P.white)
        end
        -- Cabeça: capuz baixo inclinado, rosto aberto.
        if north then
            p({cx - 5, top + 3, cx - 2, top - 1, cx + 4, top - 1, cx + 7,
                top + 4, cx + 6, top + 12, cx - 4, top + 13}, P.ink)
            p({cx - 4, top + 3, cx - 2, top, cx + 4, top, cx + 6, top + 4,
                cx + 5, top + 11, cx - 3, top + 12}, hood)
            p({cx - 4, top + 3, cx - 2, top, cx, top + 1, cx - 2, top + 8,
                cx - 3, top + 11}, robeLight)
            l(cx - 2, top + 6, cx - 3, top + 10, robeDeep)    -- vinco do capuz
        elseif side ~= 0 then
            p({cx - 5, top + 3, cx - 2, top - 1, cx + side * 3 + 2, top,
                cx + side * 6 + 1, top + 6, cx + side * 3, top + 11,
                cx - 5, top + 12}, P.ink)
            p({cx - 4, top + 3, cx - 2, top, cx + side * 3 + 1, top + 1,
                cx + side * 5, top + 6, cx + side * 2, top + 10,
                cx - 4, top + 11}, hood)
            l(cx - 3, top + 4, cx - 4, top + 9, robeLight)
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 5, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 6, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 7, 1, 2, eye)
            r(fx + (side == 1 and 1 or 0), top + 6, 3, 1, P.bone) -- testa
        else
            p({cx - 5, top + 3, cx - 2, top - 1, cx + 4, top - 1, cx + 7,
                top + 4, cx + 6, top + 12, cx - 4, top + 13}, P.ink)
            p({cx - 4, top + 3, cx - 2, top, cx + 4, top, cx + 6, top + 4,
                cx + 5, top + 11, cx - 3, top + 12}, hood)
            p({cx + 2, top, cx + 5, top + 3, cx + 5, top + 10, cx + 2,
                top + 11}, robeDeep)
            l(cx - 3, top + 4, cx - 4, top + 10, robeLight)
            faceDraw(r, l, cx - 3, top + 4, 7, 7, eye, cfg.expr)
        end
        if aim then
            local ax = cx + (side ~= 0 and side or 1) * 9
            l(ax, top + 4, ax + (side ~= 0 and side or 1) * 3, top + 12, trim)
            l(ax + (side ~= 0 and side or 1) * 3, top + 12, ax, top + 22, trim)
            r(ax - 1, top + 21, 2, 2, P.ink)                  -- coronha
        end
    elseif build == 'loader' then
        -- SOWER: barril baixo de pano + cesto de vime fundido à barra —
        -- trama do cesto lê em crosshatch, sementes na borda.
        local top = 12 + bob + squat
        r(cx - 6 - stL, 38 + stL, 4, 6 - stL, P.ink)
        r(cx + 3 + stR, 38 + stR, 4, 6 - stR, P.ink)
        r(cx - 5 - stL, 38 + stL, 3, 4 - stL, robeDark)
        r(cx + 3 + stR, 38 + stR, 3, 4 - stR, robeDeep)
        p({cx - 9, top + 8, cx + 9, top + 8, cx + 11, 39, cx - 11, 39}, P.ink)
        p({cx - 8, top + 9, cx + 8, top + 9, cx + 10, 38, cx - 10, 38}, robe)
        p({cx - 8, top + 9, cx - 3, top + 9, cx - 6, 38, cx - 10, 38}, robeLight)
        p({cx + 4, top + 9, cx + 8, top + 9, cx + 10, 38, cx + 6, 38}, robeDeep)
        l(cx - 7, top + 12, cx - 8, 34, robeLight)            -- prega do pano
        r(cx - 9, 36, 18, 2, robeDark)
        r(cx - 4, top + 20, 9, 1, trimDark); r(cx, top + 20, 2, 1, trim)
        -- Suspensório do cesto cruzando o peito.
        l(cx - 4, top + 10, cx + 5, top + 24, trimDark)
        -- Cesto na frente-abaixo: crosshatch de vime + borda enrolada +
        -- grãos dourados derramando.
        local bs = side ~= 0 and side or (south and 1 or -1)
        local kx = cx + bs * 11
        p({kx - 5, 27, kx + 5, 27, kx + 7, 33, kx + 6, 42, kx - 6, 42,
            kx - 7, 33}, P.ink)
        p({kx - 4, 28, kx + 4, 28, kx + 6, 33, kx + 5, 41, kx - 5, 41,
            kx - 6, 33}, P.rust)
        p({kx - 3, 29, kx + 1, 29, kx + 3, 33, kx - 1, 33, kx - 5, 31}, P.goldDark)
        -- Trama do vime: diagonais cruzadas sobre o fundo.
        l(kx - 4, 30, kx + 4, 38, P.goldDeep); l(kx - 2, 28, kx + 5, 35, P.goldDeep)
        l(kx + 4, 30, kx - 4, 38, P.goldDeep); l(kx + 5, 33, kx - 1, 40, P.goldDeep)
        l(kx - 5, 33, kx + 5, 33, P.ink); l(kx - 5, 37, kx + 5, 37, P.ink)
        l(kx - 4, 28, kx + bs * -6, top + 14, P.goldDark)     -- alça ao ombro
        r(kx + 1, 25, 2, 2, P.goldLight); r(kx - 2, 26, 1, 1, P.goldLight)
        r(kx + 3, 24, 1, 1, P.gold)                           -- grão solto
        -- Cabeça baixa sob capuz amplo.
        p({cx - 7, top + 4, cx - 3, top - 1, cx + 4, top - 1, cx + 8, top + 5,
            cx + 6, top + 12, cx - 6, top + 12}, P.ink)
        p({cx - 6, top + 4, cx - 3, top, cx + 4, top, cx + 7, top + 5,
            cx + 5, top + 11, cx - 5, top + 11}, hood)
        p({cx - 6, top + 4, cx - 3, top, cx - 1, top + 1, cx - 3, top + 8,
            cx - 5, top + 11}, robeLight)
        l(cx + 2, top + 1, cx + 5, top + 6, robeDeep)         -- sombra do aro
        if north then
            p({cx - 6, top + 4, cx - 3, top, cx + 4, top, cx + 7, top + 5,
                cx + 5, top + 11, cx - 5, top + 11}, hood)
            l(cx - 4, top + 2, cx + 2, top + 2, robeDeep)
        elseif side ~= 0 then
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 5, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 6, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 7, 1, 2, eye)
            r(fx + (side == 1 and 1 or 0), top + 9, 3, 1, P.bone) -- sorriso
        else
            faceDraw(r, l, cx - 3, top + 4, 7, 7, eye, cfg.expr)
        end
        if aim then r(cx + 7, top + 14, 3, 6, robeDark)
            r(cx + 7, top + 14, 3, 1, trim)
            r(cx + 8, top + 19, 1, 2, P.goldLight)            -- punhado de grão
        end
    elseif build == 'needle' then
        -- WATCHER: agulha espectral — coluna que afunila, barra
        -- desfiada em tiras, sombra de voo dithered no chão.
        local top = 6 + bob + squat
        p({cx - 6, top + 12, cx + 5, top + 12, cx + 7, 30, cx + 2, 43,
            cx - 4, 43, cx - 8, 30}, P.ink)
        p({cx - 5, top + 13, cx + 4, top + 13, cx + 6, 30, cx + 1, 42,
            cx - 3, 42, cx - 7, 30}, robe)
        p({cx - 5, top + 13, cx - 1, top + 13, cx - 4, 40, cx - 6, 30}, robeLight)
        p({cx + 1, top + 13, cx + 4, top + 13, cx + 6, 30, cx + 2, 40}, robeDeep)
        l(cx - 1, top + 16, cx - 2, 40, robeDark)
        -- Tiras da barra: dois fiapos pendendo do ponto de flutuação.
        l(cx - 5, 36, cx - 6 + cape, 42, robeDark)
        l(cx + 4, 34, cx + 5 + cape, 40, robeDeep)
        r(cx - 2, 41, 3, 1, robeDark)
        -- Sombra de voo: o corpo não toca — lê-se pelo buraco de luz.
        d(cx - 5, 44, 10, 2, P.ink, .35)
        -- Capuz-agulha: pico alto, costura do vértice, orifício estreito.
        p({cx - 5, top + 5, cx - 1, top - 1, cx + 1, top - 6, cx + 4, top - 1,
            cx + 6, top + 6, cx + 4, top + 13, cx - 4, top + 13}, P.ink)
        p({cx - 4, top + 5, cx - 1, top, cx + 1, top - 5, cx + 3, top,
            cx + 5, top + 6, cx + 3, top + 12, cx - 3, top + 12}, hood)
        l(cx - 4, top + 5, cx - 1, top, robeLight)
        l(cx + 1, top - 4, cx + 2, top + 3, robeDeep)          -- costura do pico
        if north then
            p({cx - 4, top + 5, cx - 1, top, cx + 1, top - 5, cx + 3, top,
                cx + 5, top + 6, cx + 3, top + 12, cx - 3, top + 12}, hood)
            l(cx, top - 1, cx + 1, top + 8, robeDeep)
        elseif side ~= 0 then
            local ex = side == 1 and cx + 1 or cx - 4
            r(ex, top + 5, 4, 5, P.ink); r(ex + (side == 1 and 1 or 0),
                top + 6, 3, 3, eye)
            r(ex + (side == 1 and 1 or 0), top + 6, 1, 1, P.ink)
        else
            local wide = aim and 1 or 0
            r(cx - 3, top + 6, 7, 5 + wide, P.ink)
            r(cx - 2, top + 7, 5, 3 + wide, eye)
            r(cx, top + 7, 1, 3 + wide, P.ink)
            r(cx - 1, top + 7, 1, 1, P.white)
            r(cx - 2, top + 8, 1, 1, P.white)                  -- brilho duplo
        end
        if aim then l(cx - 3, top + 1, cx + 4, top + 1, eye) end
    elseif build == 'regal' then
        -- REGENT: manto de patamares + coroa de três dentes + mão de
        -- comando com anel — o mais largo do elenco.
        local top = 6 + bob + squat
        r(cx - 7 - stL, 38 + stL, 5, 6 - stL, P.ink)
        r(cx + 4 + stR, 38 + stR, 5, 6 - stR, P.ink)
        r(cx - 6 - stL, 38 + stL, 3, 4 - stL, robeDark)
        r(cx + 5 + stR, 38 + stR, 3, 4 - stL, robeDeep)
        p({cx - 13, top + 10, cx + 13, top + 10, cx + 14, 39, cx - 14, 39},
            P.ink)
        p({cx - 12, top + 11, cx + 12, top + 11, cx + 13, 38, cx - 13, 38}, robe)
        p({cx - 12, top + 11, cx - 5, top + 11, cx - 9, 38, cx - 13, 38}, robeLight)
        p({cx + 6, top + 11, cx + 12, top + 11, cx + 13, 38, cx + 8, 38}, robeDeep)
        l(cx - 12, top + 11, cx + 12, top + 11, trim)
        l(cx - 8, top + 16, cx - 10, 37, robeDark)
        l(cx + 2, top + 15, cx + 3, 36, robeDark)
        -- Segundo patamar: degrau do manto com filete próprio.
        p({cx - 10, top + 20, cx + 10, top + 20, cx + 11, 34, cx - 11, 34}, P.ink)
        p({cx - 9, top + 21, cx + 9, top + 21, cx + 10, 33, cx - 10, 33}, robeDark)
        l(cx - 9, top + 21, cx + 9, top + 21, robeDeep)
        r(cx - 12, 36, 24, 2, robeDark)
        l(cx - 12, 36, cx + 12, 36, trimDark)
        -- Estola cerimonial descendo o peito em dois filetes.
        if not north then
            p({cx - 4, top + 11, cx - 1, top + 11, cx - 2, 35, cx - 5, 35}, trim)
            p({cx + 1, top + 11, cx + 4, top + 11, cx + 5, 35, cx + 2, 35}, trimDark)
            r(cx - 4, 33, 3, 2, trimDark); r(cx + 2, 33, 3, 2, trim)
        end
        -- Mão aberta em gesto de comando + ANEL na falange.
        local gs = side ~= 0 and side or (south and 1 or -1)
        local gx = cx + gs * 14
        r(gx - 1, top + 14, 3, 8, robeDark)
        l(gx, top + 15, gx, top + 20, robeDeep)                -- vinco da manga
        r(gx - 2, top + (aim and 8 or 12), 4, 4, skin)
        l(gx - 1, top + (aim and 8 or 12), gx - 2, top + (aim and 5 or 10), P.bone)
        l(gx + 1, top + (aim and 8 or 12), gx + 2, top + (aim and 6 or 10), P.bone)
        r(gx, top + (aim and 10 or 14), 1, 1, trimLight)       -- anel
        p({cx - 6, top + 3, cx - 2, top - 1, cx + 3, top - 1, cx + 7, top + 4,
            cx + 5, top + 12, cx - 5, top + 12}, P.ink)
        p({cx - 5, top + 3, cx - 2, top, cx + 3, top, cx + 6, top + 4,
            cx + 4, top + 11, cx - 4, top + 11}, hood)
        l(cx - 4, top + 4, cx - 5, top + 10, robeLight)
        if north then
            p({cx - 5, top + 3, cx - 2, top, cx + 3, top, cx + 6, top + 4,
                cx + 4, top + 11, cx - 4, top + 11}, hood)
            l(cx - 3, top + 2, cx + 3, top + 2, robeDeep)
        elseif side ~= 0 then
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 4, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 5, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 6, 1, 2, eye)
        else
            faceDraw(r, l, cx - 3, top + 3, 7, 7, eye, cfg.expr)
        end
        -- Coroa: três dentes sobre o capuz, pedra central.
        for _, dx in ipairs({-4, 0, 4}) do
            l(cx + dx, top - 1, cx + dx, top - 4, trim)
            r(cx + dx - 1, top - 5, 2, 2, trimDark)
        end
        l(cx - 4, top - 1, cx + 4, top - 1, trimDark)
        r(cx, top - 3, 1, 1, eye)
        if aim then r(gx - 1, top + (aim and 6 or 10), 1, 1, eye) end
    else
        -- VETERAN (block): coluna larga — costuras de campanha, atadura
        -- de joelho, aljava atrás do ombro e arco erguido com corda.
        local top = 7 + bob + squat
        r(cx - 6 - stL, 37 + stL, 4, 7 - stL, P.ink)
        r(cx + 3 + stR, 37 + stR, 4, 7 - stR, P.ink)
        r(cx - 5 - stL, 37 + stL, 3, 5 - stL, robeDark)
        r(cx + 3 + stR, 37 + stR, 3, 5 - stL, robeDeep)
        r(cx - 5 - stL, 39 + stL, 3, 1, trimDark)              -- atadura
        r(cx + 3 + stR, 39 + stR, 3, 1, trimDark)
        p({cx - 10, top + 8, cx + 10, top + 8, cx + 10, 38, cx - 10, 38}, P.ink)
        p({cx - 9, top + 9, cx + 9, top + 9, cx + 9, 37, cx - 9, 37}, robe)
        p({cx - 9, top + 9, cx - 3, top + 9, cx - 6, 37, cx - 9, 37}, robeLight)
        p({cx + 5, top + 9, cx + 9, top + 9, cx + 9, 37, cx + 6, 37}, robeDeep)
        l(cx - 8, top + 12, cx - 9, 33, robeLight)             -- vinco do ombro
        r(cx - 9, 35, 18, 2, robeDark)
        -- Costuras de reparo da campanha + remendo de pano cru.
        l(cx - 4, top + 16, cx - 2, top + 26, robeDeep)
        r(cx + 2, top + 14, 3, 3, P.boneDark); r(cx + 2, top + 14, 3, 1, P.bone)
        r(cx - 8, top + 22, 16, 2, trimDark); r(cx - 8, top + 22, 12, 1, trim)
        r(cx + 6, top + 22, 2, 2, trim)                        -- fivela
        -- Bandoleira na diagonal + cartucheira de virotes.
        l(cx - 7, top + 10, cx + 6, top + 32, trimDark)
        r(cx + 3, top + 26, 4, 4, P.ink); r(cx + 4, top + 27, 2, 2, P.bone)
        -- Aljava atrás do ombro esquerdo + arco vertical à direita.
        if not north then
            r(cx - 11, top + 6, 4, 12, P.ink); r(cx - 10, top + 7, 2, 10, trimDark)
            l(cx - 12, top + 2, cx - 11, top + 7, P.bone)
            l(cx - 10, top + 1, cx - 10, top + 6, P.bone)
            l(cx - 12, top + 2, cx - 11, top + 1, P.white)
            l(cx - 10, top + 1, cx - 9, top, P.white)
            l(cx - 9, top + 8, cx - 9, top + 12, P.bone)       -- empunhadura
        else
            r(cx - 11, top + 6, 4, 12, P.ink); r(cx - 10, top + 7, 2, 10, trimDark)
            l(cx - 12, top + 2, cx - 11, top + 7, P.bone)
        end
        local bx = cx + 11
        l(bx - 1, top - 1, bx + 1, top + 8, trimDark)
        l(bx + 1, top + 8, bx + 2, top + 22, trim)
        l(bx + 2, top + 22, bx, top + 34, trimDark)
        l(bx - 1, top - 1, bx - 2, top + 16, P.bone)
        l(bx - 2, top + 16, bx - 1, top + 34, P.bone)          -- corda inteira
        r(bx - 1, top + 20, 3, 2, skin)
        r(bx - 1, top + 19, 3, 1, P.bone)                      -- dedos da corda
        -- Cabeça: capuz quadrado, rosto aberto gasto, cicatriz de ficha.
        p({cx - 6, top + 3, cx - 2, top - 1, cx + 3, top - 1, cx + 6, top + 3,
            cx + 5, top + 12, cx - 5, top + 12}, P.ink)
        p({cx - 5, top + 3, cx - 2, top, cx + 3, top, cx + 5, top + 4,
            cx + 4, top + 11, cx - 4, top + 11}, hood)
        p({cx + 2, top, cx + 5, top + 4, cx + 4, top + 10, cx + 2, top + 10},
            robeDeep)
        l(cx - 4, top + 4, cx - 5, top + 10, robeLight)
        if north then
            l(cx - 3, top + 2, cx + 2, top + 2, robeDeep)
            l(cx - 1, top + 4, cx - 2, top + 9, robeDeep)
        elseif side ~= 0 then
            local fx = side == 1 and cx or cx - 4
            r(fx, top + 4, 4, 5, P.ink)
            r(fx + (side == 1 and 1 or 0), top + 5, 3, 4, P.boneDark)
            r(fx + (side == 1 and 2 or 1), top + 6, 1, 2, eye)
            l(fx + (side == 1 and 1 or 0), top + 5, fx + (side == 1 and 3 or -1),
                top + 7, P.ink)                                -- cicatriz
        else
            faceDraw(r, l, cx - 3, top + 3, 7, 7, eye, cfg.expr)
            l(cx + 2, top + 4, cx + 3, top + 6, P.ink)         -- cicatriz
        end
    end
    -- Trama do hábito: urdume escuro no pano e sombra de barra sobre
    -- as pernas.
    if build ~= 'wisp' and action ~= 'death' then
        l(cx - 5, 37, cx + 5, 37, robeDeep)
        l(cx - 4, 39, cx + 4, 39, P.ink)
    end
end

Lote.enemies = {crawler = crawlerV2, husk = huskV2, huskCocoon = huskCocoonV2}
Lote.sentinel = sentinelV2
Lote.zealot = zealotV2
Lote.sentinelSkins = {
    dasher = {build = 'brute'},
    breaker = {cape = P.violetDark, capeLine = P.violet, shell = P.stone,
        shellHi = P.stoneLight, body = P.stoneDark, bodyDark = P.stoneDark,
        trim = P.rust, trimDark = P.stoneDark, trimLight = P.gold,
        eye = P.danger, eyeLow = P.rust, build = 'bull'},
    demolisher = {cape = P.violetDark, capeLine = P.stoneDark,
        shell = P.stoneDark, shellHi = P.stone, body = P.stone, bodyDark = P.ink,
        trim = P.goldDark, trimDark = P.ink, trimLight = P.gold,
        eye = P.danger, eyeLow = P.rust, build = 'ruin'},
    warden = {cape = P.violetDark, capeLine = P.violet, shell = P.stoneLight,
        shellHi = P.stoneEdge, body = P.stone, bodyDark = P.stoneDark,
        trim = P.gold, trimDark = P.goldDark, trimLight = P.goldLight,
        eye = P.violetLight, eyeLow = P.violet, build = 'tower'},
}
Lote.zealotSkins = {
    ranger = {robe = P.violetDark, robeLight = P.violet, robeDark = P.stoneDark,
        robeDeep = P.violetDeep, hood = P.violetDark, eye = P.goldLight,
        trim = P.gold, trimDark = P.goldDark, build = 'scout',
        skin = P.bone, expr = 'stern'},
    veteran = {robe = P.violet, robeLight = P.violetLight, robeDark = P.violetDark,
        robeDeep = P.violetDeep, hood = P.violetDark, eye = P.jadeLight,
        trim = P.jade, trimDark = P.jadeDark, build = 'block',
        skin = P.bone, expr = 'worn'},
    sower = {robe = P.goldDark, robeLight = P.gold, robeDark = P.rust,
        robeDeep = P.goldDeep, hood = P.rust, eye = P.emberLight,
        trim = P.goldLight, trimDark = P.goldDark, build = 'loader',
        skin = P.bone, expr = 'kind'},
    watcher = {robe = P.violetDark, robeLight = P.violet, robeDark = P.stoneDark,
        robeDeep = P.violetDeep, hood = P.violetDark, eye = P.violetLight,
        trim = P.violet, trimDark = P.violetDark, build = 'needle'},
    regent = {robe = P.rust, robeLight = P.goldDark, robeDark = P.ink,
        robeDeep = P.goldDeep, hood = P.goldDark, eye = P.danger,
        trim = P.goldLight, trimDark = P.gold, build = 'regal',
        skin = P.bone, expr = 'stern'},
}

--====================================================================--
-- RETRATOS (residentEmote) — bloco paste-ready.
-- Em pixel_actors.lua:
--   rests[v] += {elder='worn', washer='kind', porter='worn',
--     logger='stern', kid='joy', braid='kind', stocky='kind',
--     watch='stern', vendor='kind', voice='worn', crew='worn',
--     usher='soft', crowd='kind'}
--   faceDraw(..., {skinLo=..., hair=..., bare = v == 'wright' or
--     v == 'bald' or v == 'stocky'})
--   Na cadeia de adornos, antes do `else` final:
--     if fibraEmoteAdorno(r, l, p, cx, v, pal, cloth, hair, accent,
--         skin, skinHi) then
--         -- adorno aplicado
--     else ... (else final existente)
--====================================================================--
local function emoteAdorno(r, l, p, cx, v, pal, cloth, hair, accent,
    skin, skinHi)
    if v == 'elder' then
        -- Ancião: cabelo branco ralo alto e nas têmporas, testa nua.
        r(cx - 8, 3, 16, 3, hair); r(cx - 8, 3, 16, 1,
            mixc(hair, .3, P.white))
        r(cx - 9, 5, 2, 5, hair); r(cx + 8, 5, 2, 5, hair)
        r(cx - 6, 6, 3, 1, hair); r(cx + 3, 6, 3, 1, hair)
        r(cx - 12, 34, 24, 3, cloth)                          -- gola areia
        return true
    elseif v == 'washer' then
        -- Lavadeira: cabelo puxado + rolo baixo na nuca à direita;
        -- alça do avental claro cruzando o busto.
        r(cx - 8, 4, 16, 4, hair)
        r(cx - 9, 6, 2, 7, hair); r(cx + 8, 6, 2, 6, hair)
        r(cx + 8, 14, 4, 6, hair); r(cx + 9, 15, 2, 4, mixc(hair, .4))
        l(cx + 10, 35, cx - 3, 46, pal.accent or P.bone)      -- alça do avental
        return true
    elseif v == 'porter' then
        -- Carregador: cabelo escuro curto, ombreira de lona no busto.
        r(cx - 8, 3, 16, 4, hair); r(cx - 9, 5, 3, 6, hair)
        r(cx + 8, 5, 2, 5, hair)
        r(cx - 13, 34, 5, 13, P.goldDark)                     -- lona do ombro
        l(cx - 13, 35, cx - 9, 35, P.gold)
        l(cx - 8, 36, cx + 8, 46, P.goldDeep)                 -- alça larga
        return true
    elseif v == 'logger' then
        -- Lenhador: crespo curto cerrado + faixa clara de punho
        -- despontando na borda do busto.
        r(cx - 8, 3, 16, 5, hair)
        r(cx - 9, 6, 3, 7, hair); r(cx + 8, 6, 3, 7, hair)
        r(cx - 9, 8, 2, 2, mixc(hair, .35)); r(cx + 6, 4, 2, 1,
            mixc(hair, .35))
        r(cx + 10, 40, 4, 2, pal.accent or P.bone)            -- faixa no punho
        return true
    elseif v == 'kid' then
        -- Criança: massa de cachos grandes + fios enrolados nas têmporas.
        r(cx - 8, 3, 16, 5, hair)
        r(cx - 10, 5, 3, 7, hair); r(cx + 8, 5, 3, 7, hair)
        r(cx - 11, 9, 2, 3, hair); r(cx + 10, 8, 2, 3, hair)
        r(cx - 4, 2, 2, 1, mixc(hair, .4)); r(cx + 3, 1, 2, 2, hair)
        return true
    elseif v == 'braid' then
        -- Traba: cabelo liso puxado + trança baixa escamada tombando
        -- para a direita.
        r(cx - 8, 3, 16, 5, hair); r(cx - 9, 7, 2, 9, hair)
        r(cx + 8, 8, 4, 20, hair)
        r(cx + 8, 12, 4, 3, mixc(hair, .4)); r(cx + 8, 18, 4, 3,
            mixc(hair, .4))
        r(cx + 8, 28, 4, 2, accent)                           -- atadura
        return true
    elseif v == 'stocky' then
        -- Trabb: crânio raspado (bare) + sombra de barba na base +
        -- faixa de suor na testa.
        r(cx - 8, 6, 16, 1, accent)
        return true
    elseif v == 'watch' then
        -- Guarda: cabelo curto de serviço + colarinho do manto subindo.
        r(cx - 8, 3, 16, 4, hair)
        r(cx - 9, 5, 2, 6, hair); r(cx + 8, 5, 2, 6, hair)
        r(cx - 11, 30, 3, 10, pal.cape or P.stoneDark)
        r(cx + 9, 30, 3, 10, pal.cape or P.stoneDark)
        r(cx - 11, 30, 3, 1, mixc(pal.cape or P.stoneDark, .3, P.white))
        return true
    elseif v == 'vendor' then
        -- Feirante: o pano na cabeça sai pelo overlay headWrap — aqui
        -- ficam os caracóis brancos escapando sob a faixa + gola azul.
        r(cx - 9, 7, 3, 6, hair); r(cx + 7, 7, 3, 6, hair)
        r(cx - 10, 10, 2, 3, hair); r(cx + 9, 10, 2, 3, hair)
        r(cx - 10, 34, 20, 3, accent)                         -- gola azul
        return true
    elseif v == 'voice' then
        -- Voz do canal: capuz fundo — o rosto mora dentro da sombra.
        r(cx - 11, 3, 22, 4, cloth)
        r(cx - 11, 4, 3, 30, cloth); r(cx + 9, 4, 3, 30, cloth)
        r(cx - 8, 4, 16, 3, cloth)
        return true
    elseif v == 'crew' then
        -- Equipe: lenço de serviço na testa + nó lateral + cabelo sob.
        r(cx - 8, 4, 16, 3, accent); r(cx - 8, 3, 16, 1,
            mixc(accent, .3, P.white))
        r(cx + 7, 2, 3, 3, accent)                            -- nó
        r(cx - 8, 7, 16, 2, hair)
        r(cx - 9, 8, 2, 6, hair); r(cx + 8, 8, 2, 5, hair)
        return true
    elseif v == 'usher' then
        -- Ajudante: cabelo longo preso + rabo baixo sobre o ombro
        -- esquerdo + ponta da faixa vinho na borda do busto.
        r(cx - 8, 3, 16, 5, hair); r(cx - 9, 7, 2, 10, hair)
        r(cx + 8, 7, 2, 7, hair)
        r(cx - 11, 16, 4, 12, hair); r(cx - 11, 16, 4, 1, accent)
        r(cx + 10, 34, 4, 8, accent)                          -- ponta da faixa
        return true
    elseif v == 'crowd' then
        -- Plateia: cabelo comum despenteio + xale curto no colo.
        r(cx - 8, 3, 16, 5, hair)
        r(cx - 9, 5, 2, 6, hair); r(cx + 8, 5, 2, 5, hair)
        r(cx - 3, 2, 2, 1, hair); r(cx + 5, 1, 1, 2, hair)
        r(cx - 12, 33, 24, 3, accent)
        return true
    end
    return false
end
Lote.emoteAdorno = emoteAdorno

return Lote
