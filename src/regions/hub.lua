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
    -- Superfície por distrito, nunca por hash: zones decididas na ordem
    -- (a primeira que contém a célula vence) e 'caminho' pinta por cima.
    -- Laje = mundo construído (mirante, praça, ruas); terra = quintais,
    -- serviço e contemplação; grama = o adro guardado. A última zona cobre
    -- o mapa inteiro — nenhuma célula cai no mix laje/terra do renderer.
    zones = {
        -- Esqueleto de laje: praça fechada + faixas de rua, todas contíguas.
        {name = 'PRAÇA DOS NOMES', x = 13, y = 17, w = 19, h = 9, surface = 'stone'},
        {name = 'RUA DA DESCIDA', x = 19, y = 8, w = 4, h = 10, surface = 'stone'},
        {name = 'RUA DO ADRO', x = 10, y = 17, w = 4, h = 3, surface = 'stone'},
        {name = 'RUA DO POÇO', x = 4, y = 24, w = 15, h = 2, surface = 'stone'},
        {name = 'RUA LESTE', x = 31, y = 19, w = 9, h = 3, surface = 'stone'},
        {name = 'BECO', x = 39, y = 21, w = 4, h = 8, surface = 'stone'},
        {name = 'APRON DA FORJA', x = 42, y = 27, w = 7, h = 2, surface = 'stone'},
        {name = 'ESCADA BAIXA', x = 24, y = 26, w = 5, h = 3, surface = 'stone'},
        {name = 'PASSEIO DO TERRAÇO', x = 24, y = 29, w = 25, h = 3, surface = 'stone'},
        {name = 'MIRANTE', x = 4, y = 3, w = 34, h = 5, surface = 'stone'},
        -- Massas de terra/grama — os bolsos escuros entre as ruas claras.
        {name = 'JARDIM DA CAPELA', x = 4, y = 12, w = 7, h = 9, surface = 'grass'},
        {name = 'HORTA', x = 4, y = 21, w = 9, h = 3, surface = 'earth'},
        {name = 'BECO DA FORJA', x = 38, y = 19, w = 15, h = 10, surface = 'gravel'},
        {name = 'TERRAÇO BAIXO', x = 16, y = 30, w = 33, h = 7, surface = 'earth'},
        {name = 'VILA', x = 0, y = 0, w = 54, h = 40, surface = 'earth'},
    },
    -- Ruas: a faixa de laje da zona é a rua carveada e a polilinha corre
    -- centrada nela — rua pintada = rua carveada, sem divergência. A tinta
    -- 'caminho' é desgaste sobre a banda, não a rua em si. main=true marca
    -- a espinha chegada→Marco (meia-largura +5px no renderer).
    paths = {
        -- chegada → escadaria: a volta do mirante até a boca da escada.
        {w = 3.1, main = true, {5.2, 5.3}, {9, 5.1}, {13, 5.2}, {16.5, 5.5},
            {19.5, 6.4}, {20.5, 7.8}, {20.6, 9}},
        -- rua da descida: reta dentro da faixa x19-22, encontra o Marco no
        -- eixo ao entrar na praça.
        {w = 3.0, main = true, {20.6, 9.5}, {21, 12}, {20.6, 15},
            {20.5, 18}, {20.7, 20.5}},
        -- praça → adro: pelo portão da mureta (10,18-19) à porta da capela.
        {w = 2.7, {19, 19.4}, {15, 19.2}, {11.5, 18.8}, {9, 18}, {7.3, 17.3}},
        -- rua do poço → cozinha/horta: faixa horizontal na frente das casas.
        {w = 2.9, {18, 23.5}, {16, 24.6}, {12, 25}, {8, 25.1}, {5, 25.2}},
        -- praça → escada baixa: a lingueta sul da praça leva ao vão.
        {w = 2.8, {24.5, 22}, {25.5, 24.5}, {26, 27}, {26.2, 29.5},
            {26.3, 31.5}},
        -- rua leste → beco → quintal de cascalho: a perna de serviço do loop.
        {w = 2.6, {27, 20.5}, {31, 20.6}, {35, 20.8}, {39, 21.2},
            {40.3, 22.5}, {40.5, 24.5}, {40.8, 26.8}, {43, 27.7}, {47, 27.8}},
        -- rampa de serviço → passeio do terraço → escola → escada baixa:
        -- uma faixa só na cabeceira do terraço.
        {w = 2.7, {48.5, 27.8}, {48, 30}, {46.5, 31.3}, {42, 31.4},
            {37, 31.3}, {32, 31.4}, {26.5, 31.4}},
        -- beirada sul do terraço: trilha de contemplação junto ao parapeito.
        {w = 2.5, {42, 32.5}, {39, 34}, {34, 35.2}, {28, 35.3}, {23, 35},
            {20, 34.8}},
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
        {id = 'canteiroHortaA1', kind = 'canteiro', x = 4, y = 22, solid = true},
        {id = 'canteiroHortaA2', kind = 'canteiro', x = 4, y = 23, solid = true},
        {id = 'canteiroHortaB1', kind = 'canteiro_b', x = 6, y = 22, solid = true},
        {id = 'canteiroHortaB2', kind = 'canteiro_b', x = 6, y = 23, solid = true},
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
