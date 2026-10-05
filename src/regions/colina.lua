-- Região 1: Colina dos Sepultados (docs/mapas/01_COLINA.md)
-- Planta autoral por retângulos de piso; a casca de muros é gerada ao redor.
-- Lugares garantidos da ficha: sepultura original, pátio do velório,
-- depósito funerário, grade de Runa e a descida ao refúgio.
--
-- Reformulação ouro (spec W01–W06): rotas legíveis entre as portas (paths),
-- clusters encostados, e o void da margem direita vira limite escrito —
-- rebordo rompido do pátio, galeria desabada ao sul do depósito e massa de
-- rocha junto ao salão (a passagem antiga é colapsada: nunca atalho).
-- Toda célula nova de carve fica sob prop sólido: pegada caminhável intacta.
return {
    id = 'colina', uid = 1, name = 'CRIPTA · COLINA DOS SEPULTADOS', realm = 'refugio', w = 28, h = 24,
    spawn = {x = 6, y = 4},
    arrivals = {
        hub = {x = 7, y = 21, dx = 0, dy = -1},
        sepultura = {x = 6, y = 4, dx = 0, dy = 1},
    },
    carve = {
        {x = 4, y = 2, w = 6, h = 4},    -- câmara da sepultura
        {x = 6, y = 6, w = 2, h = 4},    -- corredor ao pátio
        {x = 4, y = 10, w = 14, h = 6},  -- pátio do velório
        {x = 18, y = 11, w = 3, h = 2},  -- corredor ao depósito
        {x = 21, y = 9, w = 6, h = 6},   -- depósito funerário
        {x = 5, y = 16, w = 2, h = 2},   -- corredor da grade
        {x = 4, y = 18, w = 8, h = 4},   -- salão da descida
        -- Rebordos do desabamento (spec W02/W04 — borda autoral do void):
        -- cada célula abaixo recebe prop sólido; nada caminhável é criado.
        {x = 18, y = 13, w = 1, h = 3},  -- rim a leste do pátio, sob o corredor
        {x = 21, y = 15, w = 6, h = 1},  -- apron de escombro, face sul do depósito
        {x = 12, y = 18, w = 1, h = 4},  -- massa selada a leste do salão
    },
    -- Silhueta profunda no void (segundo anel): tocos de parede e rocha que
    -- o escuro ainda deixa ler — a "passagem antiga" que cedeu a leste.
    walls = {
        {x = 22, y = 16}, {x = 24, y = 16}, {x = 23, y = 17},
        {x = 13, y = 19}, {x = 14, y = 19}, {x = 13, y = 20},
        {x = 11, y = 3}, {x = 11, y = 5},
    },
    zones = {
        {name = 'CÂMARA', x = 4, y = 2, w = 6, h = 4, surface = 'stone'},
        {name = 'PÁTIO DO VELÓRIO', x = 4, y = 10, w = 14, h = 6, surface = 'grass'},
        {name = 'DEPÓSITO', x = 21, y = 9, w = 6, h = 6, surface = 'stone'},
        {name = 'SALÃO DA DESCIDA', x = 4, y = 18, w = 8, h = 4, surface = 'stone'},
    },
    -- Caminhos gastos da ficha W01: rotas mantidas entre a câmara, o pátio,
    -- o depósito e a descida — a terra pisada le onde se anda de verdade.
    paths = {
        {w = 2.2, {6.4, 4.5}, {6.6, 6.5}, {6.4, 9.2}, {6.2, 11}},
        {w = 2.4, {6.2, 11.4}, {9, 12}, {12.5, 11.9}, {16, 11.6},
            {18.5, 11.6}, {21.5, 11.5}},
        {w = 2.2, {6, 12.5}, {5.6, 15.5}, {5.6, 17.2}, {6.4, 19.2},
            {7, 21.4}},
    },
    holes = {
        {x = 17, y = 14}, {x = 17, y = 15}, {x = 16, y = 15},
    },
    pillars = {
        {x = 11, y = 10}, {x = 15, y = 10},
    },
    props = {
        {id = 'cova', kind = 'sepultura', x = 5, y = 3, solid = true},
        -- A lápide do protagonista: tamanho comum, junto da cova, sem
        -- bloquear a saída da câmara (ficha 01, direção visual).
        {id = 'lapideProt', kind = 'lapide', x = 4, y = 3, solid = true},
        {id = 'tampa', kind = 'tampa', x = 8, y = 3},
        -- Marca partida na parede norte da câmara, ao lado da tampa
        -- (ABERTURA_HD Ato 1: a vedação). Repintura HD — emissivo violeta
        -- ei~0.3 — fica com Traço/Prisma (doc §6); hoje herda a placa.
        {id = 'marcaPartida', kind = 'placa', x = 7, y = 2},
        -- W02: alvenaria nova sobre velha + pano guardado — o quarto foi
        -- preparado contra o retorno e alguém voltou a arrumá-lo.
        {id = 'panoCamara', kind = 'pano', x = 9, y = 4, solid = true},
        {id = 'entulhoCamara', kind = 'entulho', x = 9, y = 5, solid = true},
        {id = 'velaVigilia', kind = 'velas', x = 4, y = 4},
        -- Lápides em mancha irregular (doc mapa-lugares: 2 agrupamentos,
        -- distâncias variadas) + marcas improvisadas das sepulturas recentes.
        {id = 'lapide1', kind = 'lapide', x = 5, y = 10, solid = true},
        {id = 'lapide2', kind = 'lapide', x = 7, y = 12, solid = true},
        {id = 'lapide3', kind = 'lapide', x = 14, y = 9, solid = true},
        {id = 'lapide4', kind = 'lapide', x = 16, y = 11, solid = true},
        {id = 'lapide5', kind = 'lapide_b', x = 15, y = 13, solid = true},
        {id = 'marcaImpro1', kind = 'flores', x = 10, y = 11},
        {id = 'marcaImpro2', kind = 'pano', x = 17, y = 11},
        {id = 'marcaImpro3', kind = 'marcaImpro', x = 12, y = 14},
        {id = 'banco1', kind = 'banco', x = 8, y = 12, solid = true},
        {id = 'banco2', kind = 'banco', x = 9, y = 12, solid = true},
        {id = 'bancoPatio', kind = 'banco', x = 14, y = 15, solid = true},
        {id = 'velasVelorio', kind = 'velas', x = 10, y = 13},
        {id = 'pano', kind = 'pano', x = 13, y = 12, solid = true},
        {id = 'cipoBorda', kind = 'cipo', x = 16, y = 13},
        -- Depósito: loja funerária — caixão grande demais, pertences pequenos,
        -- estoque encostado no canto norte; face sul desabou pra dentro.
        {id = 'bau', kind = 'bau', x = 23, y = 10, solid = true},
        {id = 'panoDeposito', kind = 'pano', x = 25, y = 10, solid = true},
        {id = 'caixasDeposito', kind = 'caixas', x = 26, y = 9, w = 1, h = 2, solid = true},
        -- O caixão vazio que Doro guardou no depósito (subquest D01).
        {id = 'caixao', kind = 'caixao', x = 24, y = 13, w = 2, solid = true},
        {id = 'entulhoDepA', kind = 'entulho', x = 22, y = 14, solid = true},
        {id = 'entulhoDepB', kind = 'entulho', x = 24, y = 14, solid = true},
        {id = 'rochaDeposito', kind = 'rocha', x = 26, y = 14, solid = true},
        -- Galeria colapsada sob a face sul do depósito (apron 100% sólido).
        {id = 'escombroA', kind = 'entulho', x = 21, y = 15, solid = true},
        {id = 'escombroB', kind = 'rocha', x = 22, y = 15, solid = true},
        {id = 'escombroC', kind = 'entulho', x = 23, y = 15, solid = true},
        {id = 'escombroD', kind = 'rocha', x = 24, y = 15, solid = true},
        {id = 'escombroE', kind = 'entulho', x = 25, y = 15, solid = true},
        {id = 'escombroF', kind = 'cipo', x = 26, y = 15, solid = true},
        -- Rebordo rompido a leste do pátio: cerca de ferro partida + pedra —
        -- o fim da encosta, não um corredor.
        {id = 'cercaRimA', kind = 'cercado', x = 18, y = 13, solid = true},
        {id = 'lapideRim', kind = 'lapide_c', x = 18, y = 14, solid = true},
        {id = 'cercaRimB', kind = 'cercado', x = 18, y = 15, solid = true},
        -- Massa selada a leste do salão: onde a passagem antiga seguia.
        {id = 'rochaSalaoA', kind = 'rocha', x = 12, y = 18, solid = true},
        {id = 'entulhoSalao', kind = 'entulho', x = 12, y = 19, solid = true},
        {id = 'rochaSalaoB', kind = 'rocha', x = 12, y = 20, solid = true},
        {id = 'muroSalao', kind = 'muro', x = 12, y = 21, solid = true},
        {id = 'grade', kind = 'grade', x = 5, y = 17, w = 2, solid = true},
        {id = 'flores', kind = 'flores', x = 14, y = 14},
        -- Tocha na boca da descida: a única chama antes da grade.
        {id = 'tochaDescida', kind = 'tocha', x = 4, y = 15, solid = true},
        -- Salão da descida: banco de vigia + placa da cripta — a sala onde
        -- quem vem do Refúgio desembarca não fica nua.
        {id = 'bancoDescida', kind = 'banco', x = 4, y = 20, w = 2, solid = true},
        {id = 'placaDescida', kind = 'placa', x = 7, y = 15, solid = true},
        {id = 'mesaVelas', kind = 'mesa', x = 9, y = 19, solid = true},
        {id = 'pilarSalao', kind = 'pilar', x = 10, y = 18, solid = true},
    },
    npcs = {
        {id = 'doro', x = 8, y = 3, dx = -1, dy = 0},
        -- MERGE-SHIM (C01-Q1 · nota Pátio): o npc 'runa' saiu da lista — a
        -- criatura do encontro cobre o papel dela por inteiro (contato e
        -- interact à distância abrem o mesmo node 'runa'). Pós-grade,
        -- data.people.runa.location='hub' já faria ela sumir sozinha;
        -- a ficha social do encontro resolve o resto. REVISÃO PÁTIO.
    },
    hotspots = {
        {id = 'sepultura', x = 5, y = 3, label = 'EXAMINAR'},
        {id = 'lapideProt', x = 4, y = 3, label = 'EXAMINAR'},
        -- O prop da tampa divide (8,3) com Doro e a fala dele vencia o
        -- placar do interact — o spot desce uma célula pra inspeção abrir.
        {id = 'tampa', x = 8, y = 4, label = 'EXAMINAR'},
        {id = 'marcaPartida', x = 7, y = 2, label = 'EXAMINAR'},
        {id = 'pano', x = 13, y = 12, label = 'EXAMINAR'},
        {id = 'lapide', x = 5, y = 10, label = 'EXAMINAR'},
        {id = 'lapide', x = 7, y = 12, label = 'EXAMINAR'},
        {id = 'lapide', x = 14, y = 9, label = 'EXAMINAR'},
        {id = 'lapide', x = 16, y = 11, label = 'EXAMINAR'},
        {id = 'flores', x = 14, y = 14, label = 'EXAMINAR'},
        {id = 'pertences', x = 23, y = 10, label = 'PEGAR', once = true, title = 'SEUS PERTENCES'},
        {id = 'caixao', x = 24, y = 13, label = 'EXAMINAR'},
        -- Placa de rota: a descida sinaliza por que a grade segura e para
        -- onde leva depois de aberta (texto varia pelo estado da grade).
        {id = 'bancoVelorio', x = 8, y = 12, label = 'EXAMINAR'},
        {id = 'placaDescida', x = 7, y = 15, label = 'DESCIDA',
            use = function(c)
                -- gradeHow é string ('won'/'negotiated'/...) e c:flag só
                -- casa `== true` — o passo P01-E03 é o fato da grade aberta.
                if c:stepDone('P01-E03') then
                    c:notify('O refúgio fica pela descida.')
                else
                    c:notify('A grade de Runa segura a descida — fale com ela.')
                end
            end},
    },
    exits = {
        {x = 7, y = 22, side = 'south', to = 'hub', arrival = 'hub', localPath = true, label = 'MIRANTE DO REFÚGIO'},
    },
    -- Sem encontros fora da ficha: a ficha 01 só prevê o confronto da grade
    -- (P01-E03/E04), resolvido por diálogo ou arena armada. O bruto T01-01
    -- era plumbing de teste e colidia com os ids T01–T03 da subquest da Teca.
    encounters = {
        -- Demonstração consensual na grade (ficha 01 · P01-E04): Runa mede a
        -- capacidade da jogadora sob condições combinadas. O marcador fica na
        -- linha da grade, do lado do spawn — alcançável antes de abrir: o
        -- contato sem flag abre a fala dela (o aceite sobe 'runaConfronto' na
        -- opção) e o watcher trigger='flag' dispara a arena. `nonLethal` é o
        -- flag operante da rendição (§5.3, cadeia unidade > def > ctx —
        -- MERGE-SHIM: `kinds.runa` não tem `contexts`, então ctx 'duelo'
        -- sozinho não a armava; fica como etiqueta de contexto dos barks).
        -- `talkRange` cobre o interact à distância do npc removido — ela
        -- responde do posto, como respondia através da grade. A grade abre
        -- por acordo ou pelo resultado — batalha nunca é exigida para passar.
        {id = 'C01-Q1', kind = 'runa', talk = 'runa', ctx = 'duelo',
            talkRange = 2.4, nonLethal = true,
            confronto = 'runaConfronto', trigger = 'flag', quota = 2, x = 6, y = 16,
            beats = {{when = 'start', node = 'runaAbertura'},
                {when = {hpBelow = .5}, node = 'runaAcordo', once = true},
                {when = 'mercy', node = 'runaRendicao', once = true}},
            onResolve = function(c, result)
                if result == 'won' or result == 'negotiated' then
                    c:openGrade(result)
                end
            end,
            units = {{kind = 'runa', x = 7, y = 5, speaker = true}}},
    },
}
