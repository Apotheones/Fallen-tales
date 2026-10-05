-- Refúgio: povoado de encosta em três cotas (planta rev3, Vão).
-- +2 MIRANTE (plataforma da chegada) · +1 VILA (praça, casas, becos) ·
-- 0 TERRAÇO (escola, contemplação). Os dois arrimos são faixas sem carve:
-- a shell desenha a face de rocha; escadaria e rampa são os vãos de passagem.
-- Ruas = carve orgânico 3-5 cél que dobra; map.paths pinta as mesmas ruas
-- (contrato renderer: polilinhas em células, nunca radiais). Massas distintas
-- por função — kind='casa' hoje; painters por id (capelaCasa, pensaoCasa, ...)
-- sobrescrevem quando o Traço entregar as variantes de silhueta.
return {
    id = 'hub', uid = 2, name = 'O REFÚGIO', realm = 'refugio', outdoor = true,
    w = 54, h = 40, spawn = {x = 9, y = 5},
    arrivals = {
        hub = {x = 7, y = 5, dx = 1, dy = 0},
        colina = {x = 7, y = 5, dx = 1, dy = 0},
        andlar = {x = 21, y = 20, dx = 0, dy = -1},
        capela = {x = 7, y = 18, dy = 1},
        cozinha = {x = 15, y = 24, dy = -1},
        pensao = {x = 29, y = 18, dy = 1},
        escola = {x = 36, y = 30, dy = -1},
        oficina = {x = 41, y = 24, dx = -1},
        oficinas = {x = 21, y = 20}, mercado = {x = 21, y = 20},
        reservatorio = {x = 21, y = 20}, saloes = {x = 21, y = 20},
    },
    carve = {
        -- Terreno único por cota — não ilhas: cada nível é uma massa
        -- contínua e as casas/becos/adro são bolsos DENTRO dela. O vazio só
        -- existe além dos parapeitos (vista) e nas faces dos dois arrimos.
        -- COTA +2 · MIRANTE — massa da chegada sob a cripta.
        {x = 4, y = 3, w = 34, h = 5},
        {x = 19, y = 8, w = 4, h = 2},    -- escadaria (vão do arrimo 1)
        -- COTA +1 · VILA — massa única x4-49, y10-28.
        {x = 4, y = 10, w = 46, h = 19},
        {x = 49, y = 24, w = 4, h = 5},   -- bolso do quintal da forja
        {x = 25, y = 29, w = 3, h = 1},   -- escada baixa (vão do arrimo 2)
        {x = 46, y = 29, w = 3, h = 1},   -- rampa de serviço (vão leste)
        -- COTA 0 · TERRAÇO — massa contemplativa sobre o vale.
        {x = 16, y = 30, w = 33, h = 7},
    },
    zones = {
        {name = 'MIRANTE', x = 4, y = 3, w = 34, h = 5, surface = 'stone'},
        {name = 'PRAÇA DOS NOMES', x = 18, y = 17, w = 14, h = 8, surface = 'stone'},
        {name = 'JARDIM DA CAPELA', x = 4, y = 12, w = 7, h = 9, surface = 'grass'},
        {name = 'QUINTAL DA FORJA', x = 49, y = 24, w = 4, h = 5, surface = 'gravel'},
        {name = 'BECO DA FORJA', x = 40, y = 20, w = 3, h = 8, surface = 'gravel'},
        {name = 'TERRAÇO BAIXO', x = 16, y = 30, w = 33, h = 7, surface = 'stone'},
    },
    -- Ruas pintadas: uma polilinha por rua, abraçando as massas. Distância ao
    -- segmento < w*16 px (renderer); default 2.6. Nada converge num ponto.
    -- TRAÇO provisional: vértices fracionários para a rua serpear dentro do
    -- corredor do carve em vez de correr a régua — o Pátio revê na ficha.
    paths = {
        -- chegada → escadaria: beirando o parapeito do mirante, descendo
        -- solta até a boca da escada.
        {w = 3.1, {5.2, 5.4}, {9, 5.2}, {13, 5.3}, {16.5, 5.6}, {19.3, 6.2},
            {20.4, 7.6}, {20.5, 8.8}},
        -- rua da descida: serpenteia dentro do corredor — a praça não se vê
        -- inteira de cima, revela-se dobrando a curva.
        {w = 3.0, {20.6, 10}, {21.2, 12.5}, {20.8, 14.8}, {20.3, 17},
            {20.2, 19.5}, {20.4, 21.4}},
        -- praça → adro: pelo portão leste da mureta e reta à porta sul da
        -- capela (7,17).
        {w = 2.7, {20.3, 19.3}, {17, 19.2}, {13.5, 19.1}, {11.2, 18.7},
            {10.4, 18.6}, {9.5, 18}, {7.9, 17.4}, {7.2, 17}},
        -- rua do poço → cozinha/horta: desce rente à cisterna e cerca a
        -- cozinha pela parede norte (a porta fica na rua).
        {w = 2.9, {19.8, 22.3}, {19, 23.8}, {17.5, 25}, {15, 25.2},
            {12, 25.2}, {9, 25.3}, {6.5, 25.4}, {5, 25.2}},
        -- praça → escada baixa: o segundo vão desce à beirada do terraço.
        {w = 2.8, {23, 22.2}, {24.8, 24.5}, {25.8, 26.8}, {26.2, 29},
            {26.3, 31.5}},
        -- rua leste → beco apertado atrás da forja → fundo → quintal de
        -- cascalho: a perna estreita do loop, nunca radial.
        {w = 2.6, {28.5, 20.4}, {31.5, 20.8}, {35, 21.2}, {38.5, 21.2},
            {40.6, 21.8}, {41.2, 24}, {41.3, 26.5}, {43.5, 27.6},
            {46.5, 28.2}, {48.5, 26.8}},
        -- rampa de serviço → terraço: volta por outra borda e fecha o loop.
        {w = 2.5, {50.2, 27.3}, {48.5, 29.2}, {47.2, 31}, {45, 32.5},
            {43.5, 33.5}},
        -- terraço: porta da escola → passeio do parapeito sobre o vale.
        {w = 2.7, {26.3, 31.5}, {29, 31.8}, {32.5, 31.4}, {35, 31.2},
            {37.5, 31.3}, {40.5, 32.2}, {42.5, 34}, {39, 35.2}, {32, 35.4},
            {25, 35.3}},
    },
    props = {
        -- Massas por função (tabela rev3): tamanhos e situações diferentes;
        -- ids próprios já servem de gancho p/ painters específicos.
        {id = 'capelaCasa', kind = 'casa', x = 5, y = 13, w = 5, h = 4, solid = true},
        {id = 'cozinhaCasa', kind = 'casa', x = 13, y = 26, w = 5, h = 4, solid = true, doorSide = 'north'},
        {id = 'camasCasa', kind = 'casa', x = 27, y = 12, w = 6, h = 5, solid = true},
        {id = 'escolaCasa', kind = 'casa', x = 33, y = 32, w = 6, h = 4, solid = true, doorSide = 'north'},
        {id = 'forjaCasa', kind = 'casa', x = 43, y = 23, w = 5, h = 4, solid = true, doorSide = 'west'},
        {id = 'marco', kind = 'marco', x = 20, y = 17, w = 2, h = 2, solid = true},
        {id = 'escadaMirante', kind = 'escadaria', x = 19, y = 8, w = 4, h = 2},
        {id = 'escadaBaixa', kind = 'escadaria', x = 25, y = 29, w = 3, h = 2},
        {id = 'rampaForja', kind = 'escadaria', x = 46, y = 29, w = 3, h = 2},
        {id = 'parapeito', kind = 'parapeito', x = 14, y = 7, w = 5, solid = true},
        {id = 'parapeitoB', kind = 'parapeito', x = 23, y = 7, w = 5, solid = true},
        {id = 'parapeitoTerraco', kind = 'parapeito', x = 16, y = 36, w = 32, solid = true},
        {id = 'mesa', kind = 'mesa', x = 24, y = 21, w = 2, solid = true},
        {id = 'cisterna', kind = 'cisterna', x = 26, y = 20, w = 2, h = 2, solid = true},
        {id = 'caixas', kind = 'caixas', x = 52, y = 25, solid = true},
        {id = 'bancoHub', kind = 'banco', x = 23, y = 19, w = 2, solid = true},
        {id = 'bancoMirante', kind = 'banco', x = 31, y = 5, w = 2, solid = true},
        {id = 'bancoTerraco', kind = 'banco', x = 26, y = 34, w = 2, solid = true},
        {id = 'floresCapela', kind = 'flores', x = 7, y = 18},
        {id = 'floresHorta', kind = 'flores', x = 7, y = 23},
        {id = 'floresTerraco', kind = 'flores', x = 22, y = 35},
        {id = 'arvoreAdro', kind = 'arvore', x = 6, y = 19, solid = true},
        {id = 'arvoreHorta', kind = 'arvore', x = 6, y = 26, solid = true},
        {id = 'arvoreTerraco', kind = 'arvore', x = 19, y = 33, solid = true},
        {id = 'rochaMirante', kind = 'rocha', x = 35, y = 4, solid = true},
        {id = 'placaMirante', kind = 'placa', x = 25, y = 5, solid = true},
        {id = 'placaRotas', kind = 'placa', x = 23, y = 17, solid = true},
        -- Vida do lugar (coordenação Morada): ids fixos, kinds próprios —
        -- painters do Traço ainda pendentes; sólidos onde a massa pede.
        {id = 'bigornaQuintal', kind = 'bigorna', x = 50, y = 25, solid = true},
        {id = 'lenhaQuintal', kind = 'lenha', x = 51, y = 24, solid = true},
        {id = 'madeiraParede', kind = 'madeiraParede', x = 52, y = 24,
            solid = true},
        {id = 'caixasCozinha', kind = 'caixas', x = 10, y = 27, solid = true},
        {id = 'espantalhoHorta', kind = 'espantalho', x = 5, y = 22, solid = true},
        {id = 'canteiroHortaA1', kind = 'canteiro', x = 4, y = 23, solid = true},
        {id = 'canteiroHortaA2', kind = 'canteiro', x = 4, y = 24, solid = true},
        {id = 'canteiroHortaB1', kind = 'canteiro_b', x = 6, y = 23, solid = true},
        {id = 'canteiroHortaB2', kind = 'canteiro_b', x = 6, y = 24, solid = true},
        {id = 'varalPensao', kind = 'varal', x = 33, y = 17, w = 1, h = 2},
        {id = 'cartazPraca', kind = 'cartaz', x = 17, y = 21, solid = true},
        -- Adro murado (o muro baixo que o galpão dava pela shell; dentro da
        -- massa única, a borda é prop): portão único a leste (10,18-19).
        {id = 'muretaAdroN', kind = 'mureta', x = 5, y = 12, w = 5, h = 1, solid = true},
        {id = 'muretaAdroS', kind = 'mureta', x = 5, y = 20, w = 5, h = 1, solid = true},
        {id = 'muretaAdroE', kind = 'mureta', x = 10, y = 12, w = 1, h = 6, solid = true},
        -- O portão do cortejo na passagem — raso, nunca bloqueia a entrada.
        {id = 'portaoAdro', kind = 'portao', x = 10, y = 18, w = 1, h = 2},
        -- Afloramento da encosta no canto NW — o morro em que o adro se apoia.
        {id = 'rochaColina', kind = 'rocha', x = 5, y = 10, w = 2, h = 2, solid = true},
        -- TRAÇO: ocupação do terraço (vida do lugar) — painter pronto,
        -- posição revisável pelo Pátio.
        {id = 'ervasRack', kind = 'ervasRack', x = 44, y = 30},
        {id = 'varalTerraco', kind = 'varalTerraco', x = 30, y = 33, w = 2},
        -- TRAÇO: posto de guarda do mirante — braseiro sempre aceso no
        -- flanco da escadaria + armaiote/escudo na ponta oeste da chegada.
        {id = 'braseiroMirante', kind = 'braseiro', x = 24, y = 6, solid = true},
        {id = 'postoVigia', kind = 'postoVigia', x = 12, y = 7, solid = true},
        -- TRAÇO: enche o terço sul — cargas do depósito junto à escola,
        -- cercado com a cabra no oeste e caixas sob a rampa de serviço.
        {id = 'cargasOeste', kind = 'cargas', x = 32, y = 34, solid = true},
        {id = 'fardosDeposito', kind = 'fardos', x = 39, y = 33, solid = true},
        {id = 'caixasRampa', kind = 'caixas', x = 48, y = 33, solid = true},
        -- Camada de memória (doc mapa-lugares + handoff Morada): kinds de
        -- placeholder onde o painter próprio ainda não existe; ids fixos
        -- servem de gancho p/ painters id-específicos do Traço.
        {id = 'pocoRua', kind = 'cisterna', x = 16, y = 23, solid = true},
        {id = 'recipientesPoco', kind = 'recipientes', x = 28, y = 22},
        {id = 'lampiaoPraca', kind = 'lampiao', x = 22, y = 19,
            solid = true},
        {id = 'bancoDivergente', kind = 'banco', x = 28, y = 19, solid = true},
        {id = 'bancoSerra', kind = 'bancoSerra', x = 19, y = 17, solid = true},
        {id = 'bancoPedra', kind = 'bancoPedra', x = 30, y = 19, solid = true},
        {id = 'canteiroAdro', kind = 'canteiro', x = 8, y = 19},
        {id = 'ervasSecas', kind = 'ervasRack', x = 30, y = 30},
        {id = 'cabra', kind = 'cabra', x = 19, y = 34, solid = true},
        -- Cercado da cabra por célula (def 64×64: run w5 desenharia uma
        -- tábua só). Abertura SE em (20–21,35) — o hotspot fica na boca.
        {id = 'cercadoT1', kind = 'cercado', x = 17, y = 32, solid = true},
        {id = 'cercadoT2', kind = 'cercado', x = 18, y = 32, solid = true},
        {id = 'cercadoT3', kind = 'cercado', x = 19, y = 32, solid = true},
        {id = 'cercadoT4', kind = 'cercado', x = 20, y = 32, solid = true},
        {id = 'cercadoT5', kind = 'cercado', x = 21, y = 32, solid = true},
        {id = 'cercadoO1', kind = 'cercado', x = 17, y = 33, solid = true},
        {id = 'cercadoO2', kind = 'cercado', x = 17, y = 34, solid = true},
        {id = 'cercadoO3', kind = 'cercado', x = 17, y = 35, solid = true},
        {id = 'cercadoL1', kind = 'cercado', x = 21, y = 33, solid = true},
        {id = 'cercadoL2', kind = 'cercado', x = 21, y = 34, solid = true},
        {id = 'cercadoS1', kind = 'cercado', x = 18, y = 35, solid = true},
        {id = 'cercadoS2', kind = 'cercado', x = 19, y = 35, solid = true},
        {id = 'baldeTempera', kind = 'baldeTempera', x = 49, y = 25, solid = true},
        {id = 'rodaRampa', kind = 'roda', x = 45, y = 27},
        {id = 'varandaPensao', kind = 'toldo', x = 28, y = 17, w = 4},
        {id = 'varandaCozinha', kind = 'toldo', x = 14, y = 25, w = 3},
        {id = 'cadeiraVaranda', kind = 'cadeira', x = 32, y = 18, solid = true},
        -- TRAÇO: restos da fatia I do Olhar sem lugar plantado ainda —
        -- posições provisórias; o Pátio revê/realoca na ficha.
        -- Oferenda sem nome junto à entrada da capela (Morada já espera
        -- o id 'oferenda' para o estado pós-rito).
        {id = 'oferenda', kind = 'oferenda', x = 8, y = 17},
        -- Marca improvisada na ponta do adro: estaca + retalho sob pedra.
        {id = 'marcaAdro', kind = 'marcaImpro', x = 5, y = 21},
        -- Remendo de alvenaria na face do arrimo sobre o terraço.
        {id = 'remendoArrimo', kind = 'remendoMuro', x = 29, y = 29},
        -- Remendos de fachada — ruína recuperada dentro de parede velha
        -- (spec: repairs retain different makers' finishes). Decais sobre a
        -- face das massas, sem colisão própria.
        {id = 'remendoCapela', kind = 'remendoMuro', x = 6, y = 16},
        {id = 'remendoCozinha', kind = 'remendoMuro', x = 16, y = 26},
        {id = 'remendoEscola', kind = 'remendoMuro', x = 34, y = 32},
        -- Chaminé da cozinha: fumaça sobe quando o forno tem uso real.
        {id = 'chamineCozinha', kind = 'chamine', x = 17, y = 26},
    },
    npcs = {
        {id = 'sabela', x = 24, y = 22, act = 'write'},
        {id = 'doro', x = 50, y = 26, act = 'hammer'},
        {id = 'aurel', x = 23, y = 20, act = 'tend'},
        {id = 'runa', x = 26, y = 6, act = 'watch'},
        -- Figurantes (Morada): chegam por marco real via people.location;
        -- posts por flag — último que casa vence, determinístico no enter.
        {id = 'anciao', x = 24, y = 20, dx = -1, act = 'sit'},
        {id = 'lavadeira', x = 33, y = 19, dy = -1, act = 'wash',
            posts = {{flag = 'aguaRefugio', x = 25, y = 22, act = 'fill'}}},
        {id = 'carregador', x = 24, y = 27, act = 'carry',
            posts = {{flag = 'aguaRefugio', x = 27, y = 23, act = 'help'}}},
        {id = 'lenhador', x = 49, y = 24, dy = -1, act = 'chop'},
        {id = 'crianca', x = 28, y = 32, act = 'play',
            posts = {{flag = 'refugioConcluido', x = 22, y = 23}}},
    },
    hotspots = {
        {id = 'marcoRefugio', x = 21, y = 19, range = 1.8, label = 'MARCO DOS NOMES'},
        {id = 'aguaRefugio', x = 26, y = 22, range = 1.9, label = 'CONFERIR ÁGUA'},
        {id = 'miranteRefugio', x = 21, y = 6, label = 'CONTEMPLAR'},
        {id = 'hortaRefugio', x = 5, y = 25, label = 'EXAMINAR'},
        {id = 'terracoRefugio', x = 26, y = 35, label = 'CONTEMPLAR'},
        {id = 'placaRotas', x = 23, y = 18, label = 'LER'},
        {id = 'cartazRefugio', x = 17, y = 20, label = 'LER'},
        {id = 'cabraRefugio', x = 21, y = 35, label = 'EXAMINAR'},
    },
    exits = {
        {x = 5, y = 5, side = 'west', to = 'colina', arrival = 'hub',
            localPath = true, label = 'CRIPTA · COLINA'},
        {x = 7, y = 17, to = 'capela', arrival = 'hub', localPath = true, label = 'CAPELA'},
        {x = 15, y = 25, to = 'cozinha', arrival = 'hub', localPath = true, label = 'COZINHA'},
        {x = 29, y = 17, to = 'pensao', arrival = 'hub', localPath = true, label = 'CASA DAS CAMAS'},
        {x = 36, y = 31, to = 'escola', arrival = 'hub', localPath = true, label = 'ESCOLA'},
        {x = 42, y = 24, to = 'oficina', arrival = 'hub', localPath = true, label = 'FORJA'},
    },
}
