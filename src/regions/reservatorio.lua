-- Região 4: Jardins do Reservatório (docs/mapas/04_RESERVATORIO.md)
-- Planta autoral: o canal principal corta o mapa em duas linhas de buracos
-- (cisternas/canais fundos, bordas claras da ficha). Ao sul, a plataforma de
-- chegada liga às Oficinas; a passarela (C04-01) e o caminho seco lateral
-- cruzam o canal para a galeria central — jardim sob as vigas da antiga
-- cobertura (canteiros em faixas, banco do casal, Mara), torre baixa com a
-- régua de nível como marco visual da chegada, ala leste interditada onde a
-- equipe de Ivo (C04-02) guarda o canal de teste. Ao norte: depósito técnico
-- (esquema + filtro de pedra), sala das comportas (Ivo, volante, B04-01) e o
-- corredor inferior drenável, cuja grade só cede depois da comporta aberta —
-- no fim dele o portal da Fundação espera 'passagemFundacao' (integração 4+5,
-- ainda sem emissor). Todos os lugares garantidos da ficha são alcançáveis a
-- pé sem sorteio nem segredo; a voz do canal grita de uma ilha inacessível
-- (a ponte apodreceu — fala por talkRange, nunca a pé).
local holes = {}
-- Canal principal: duas linhas de água funda de x=2 a x=31, abrindo só para
-- a passarela (x=10..11), o caminho seco (x=18) e a ilha da voz (x=3..4 em
-- y=17 — o resto da ilha é água, então ninguém chega a pé).
for y = 16, 17 do
    for x = 2, 31 do
        local seco = (x >= 10 and x <= 11) or x == 18 or (y == 17 and x <= 4)
        if not seco then holes[#holes + 1] = {x = x, y = y} end
    end
end
-- Ramo do canal de teste: canal estreito que desce pela ala leste e deságua
-- na margem norte do canal principal — o "desvio" que o esquema isola.
for y = 10, 15 do
    for x = 23, 24 do holes[#holes + 1] = {x = x, y = y} end
end
-- Nota Prisma: faixa d'água visível na sala dedicada ao canal — props
-- 'canal' sólidos sobre os holes do ramo (bloqueio idêntico, leitura de
-- água correndo dentro do leito em vez de buraco seco).
local aguaTeste = {}
for y = 10, 15 do
    for x = 23, 24 do
        aguaTeste[#aguaTeste + 1] = {id = 'canalAgua' .. x .. '_' .. y,
            kind = 'canal', x = x, y = y, solid = true}
    end
end

return {
    id = 'reservatorio', uid = 5, name = 'JARDINS DO RESERVATÓRIO', w = 32, h = 24,
    spawn = {x = 11, y = 21},
    arrivals = {
        -- Chegada das Oficinas: o portal fica na boca da passarela, então a
        -- chegada pisa já na plataforma olhando o canal (e a torre da régua).
        oficinas = {x = 11, y = 21, dx = 0, dy = -1},
        -- Retorno da Fundação: desce no corredor inferior já drenado.
        fundacao = {x = 7, y = 3, dx = 0, dy = 1},
        -- Compat com --scene=reservatorio (main.lua faz travel(..., 'hub')).
        hub = {x = 11, y = 21, dx = 0, dy = -1},
    },
    carve = {
        {x = 3, y = 3, w = 9, h = 3},    -- corredor inferior (drenável) → Fundação
        {x = 8, y = 6, w = 1, h = 3},    -- garganta da grade (porta fora do canto)
        {x = 9, y = 8, w = 1, h = 1},    -- patamar da placa dos alojamentos
        {x = 14, y = 2, w = 7, h = 5},   -- depósito técnico (esquema + filtros)
        {x = 16, y = 7, w = 1, h = 2},   -- corredor depósito–galeria
        {x = 24, y = 2, w = 6, h = 6},   -- sala das comportas (Ivo)
        {x = 26, y = 8, w = 1, h = 1},   -- corredor comportas–ala leste
        {x = 4, y = 9, w = 24, h = 7},   -- galeria: jardim (oeste) + ala leste
        {x = 10, y = 16, w = 2, h = 2},  -- passarela sobre o canal (C04-01)
        {x = 18, y = 16, w = 1, h = 2},  -- caminho seco lateral garantido
        {x = 3, y = 17, w = 2, h = 1},   -- ilha da voz (fora de alcance a pé)
        {x = 7, y = 18, w = 21, h = 4},  -- plataforma/posto de chegada
    },
    walls = {
        -- Anteparo que isola a ala leste interditada: coluna x=19 toda
        -- murada, com a única porta deslocada para y=13 — onde a equipe
        -- de manutenção monta guarda (C04-02).
        {x = 19, y = 9}, {x = 19, y = 10}, {x = 19, y = 11}, {x = 19, y = 12},
        {x = 19, y = 14}, {x = 19, y = 15},
    },
    pillars = {
        -- Vigas da antiga cobertura sobre o jardim: quatro pilares emolduram
        -- as faixas de canteiro sem fechar os corredores de rega.
        {x = 5, y = 10}, {x = 12, y = 10}, {x = 5, y = 15}, {x = 12, y = 15},
    },
    props = {
        -- Plataforma de chegada: entulho de manutenção e a tampa de pedra do
        -- caminho seco (marca visual do desvio garantido).
        {id = 'caixasChegada', kind = 'caixas', x = 8, y = 20, solid = true},
        {id = 'bancoPosto', kind = 'banco', x = 25, y = 20, solid = true},
        {id = 'tampaPosto', kind = 'tampa', x = 24, y = 18},
        {id = 'tampaSeca', kind = 'tampa', x = 18, y = 16},
        -- Grade do corredor inferior: sólida até a drenagem (ver hotspot
        -- 'interdicao'). A placa dos alojamentos fica pendurada na parede do
        -- patamar ao lado, apontando para as salas que viraram aquário.
        {id = 'gradeComporta', kind = 'grade', x = 8, y = 7, solid = true},
        {id = 'placaAloj', kind = 'placa', x = 9, y = 7},
        -- Depósito técnico: bancada com o esquema do traçado, a grade de
        -- filtro de pedra encostada na parede (reuso de 'grade' — pedido de
        -- prop novo: 'filtro') e peças de reserva.
        {id = 'bancadaEsquema', kind = 'bancada', x = 15, y = 3, w = 2, solid = true},
        {id = 'filtroPedra', kind = 'grade', x = 16, y = 2, solid = true},
        {id = 'caixasDeposito', kind = 'caixas', x = 19, y = 2, solid = true},
        {id = 'carteirasDep', kind = 'carteiras', x = 19, y = 5, w = 2, solid = true},
        {id = 'tuboDeposito', kind = 'canal', x = 14, y = 5, solid = true},
        -- Sala das comportas: a casa de bombas (cisterna), o portão da
        -- comporta na parede norte (reuso de 'grade' — pedido: 'comporta') e
        -- o volante de ferragem (reuso de 'ferramentas' — pedido: 'volante').
        {id = 'bombaComporta', kind = 'canal', x = 25, y = 2, w = 2, solid = true},
        {id = 'comportaPortao', kind = 'grade', x = 28, y = 2, w = 2, solid = true},
        {id = 'volanteProp', kind = 'volante', x = 29, y = 4, solid = true},
        {id = 'mesaIvo', kind = 'mesa', x = 24, y = 6, solid = true},
        -- Jardim: canteiros em faixas (reuso de 'flores' como canteiro —
        -- pedido: 'canteiro'), o banco do casal e a torre baixa da régua de
        -- nível (reuso de 'cisterna' — pedidos: 'torre'/'regua'), marco
        -- visual de quem cruza a passarela.
        {id = 'canteiroA', kind = 'flores', x = 5, y = 11, w = 6, solid = true},
        {id = 'canteiroB', kind = 'flores', x = 5, y = 13, w = 6, solid = true},
        {id = 'bancoCasalProp', kind = 'banco', x = 14, y = 12, solid = true},
        {id = 'torreRegua', kind = 'regua', x = 13, y = 14, w = 1, h = 2, solid = true},
        -- Ala leste interditada: tubulação do ramo de teste e estoque da
        -- equipe (pedido de prop novo: 'canal'/'comporta baixa').
        {id = 'tuboCanal', kind = 'canal', x = 27, y = 9, solid = true},
        {id = 'caixasCanal', kind = 'caixas', x = 20, y = 14, solid = true},
        -- Restos da ponte apodrecida na ilha da voz.
        {id = 'restoPonte', kind = 'escora', x = 3, y = 17},
        unpack(aguaTeste),
    },
    npcs = {
        {id = 'ivo', x = 27, y = 4, dx = 0, dy = 1},
        {id = 'mara', x = 11, y = 12, dx = -1, dy = 0},
        -- A gritante do outro lado do canal: ilha cercada de água, alcançável
        -- só por voz (a ponte apodreceu — inacessível a pé por design).
        {id = 'voz', x = 4, y = 17, dx = 0, dy = -1, talkRange = 2.4},
        {id = 'equipe', x = 21, y = 12, dx = -1, dy = 0},
    },
    hotspots = {
        {id = 'residuo', x = 8, y = 18, label = 'EXAMINAR'},
        {id = 'regua', x = 13, y = 14, label = 'EXAMINAR'},
        {id = 'esquema', x = 16, y = 3, label = 'EXAMINAR'},
        {id = 'canteiros', x = 7, y = 11, label = 'EXAMINAR'},
        {id = 'bancoCasal', x = 14, y = 12, label = 'EXAMINAR'},
        {id = 'placaAlojamentos', x = 9, y = 7, label = 'EXAMINAR'},
        -- Interdição de Ivo sobre a grade do corredor inferior: o exame sempre
        -- lê a placa (marca 'interdicaoVista', P04-E02); com 'comportaAberta'
        -- alta, o hook drena o corredor — setProp limpa propCells na hora e o
        -- estado 'taken' persiste na revisita (o portal da Fundação continua
        -- fechado até 'passagemFundacao', integração pendente).
        {id = 'interdicao', x = 8, y = 7, label = 'EXAMINAR',
            use = function(c)
                if c:flag('comportaAberta') then
                    c:setProp('gradeComporta', 'taken')
                    c:syncExits()
                    c:notify('A água baixou pelo ramo isolado. A grade cede.')
                end
            end},
        {id = 'canalTeste', x = 23, y = 11, label = 'EXAMINAR'},
        {id = 'volante', x = 29, y = 4, label = 'EXAMINAR'},
        -- Filtro de pedra: PEGAR recolhe a grade de filtro na primeira
        -- inspeção (o node marca 'filtroColetado'; 'once' impede repeteco).
        {id = 'filtro', x = 16, y = 2, label = 'PEGAR', once = true,
            use = function(c) c:setProp('filtroPedra', 'taken') end},
        -- Placa de rota: a descida à Fundação diz o destino e por que está
        -- trancada; some quando 'passagemFundacao' abre o letreiro.
        -- Na entrada da garganta, lado da galeria: (8,9) não captura o
        -- exame da interdição em (8,8) — empate de distância resolve pelo
        -- spot anterior na lista, e a placa rende para quem parar na boca.
        {id = 'musgo', x = 14, y = 15, label = 'EXAMINAR'},
        {id = 'placaFundacao', x = 8, y = 9, label = 'POR QUE FECHADA?',
            when = function(c) return not c:flag('passagemFundacao') end,
            use = function(c)
                c:notify('QUARTOS DA FUNDAÇÃO — trancada. A descida pede a água drenada e a escora reforçada.')
            end},
    },
    exits = {
        {x = 11, y = 22, side = 'south', to = 'oficinas', arrival = 'reservatorio', label = 'OFICINAS'},
        -- Retorno direto ao refúgio (Codex D29: o hub conecta todos os
        -- mundos — ida e volta). Baía de passagens junto do portal das
        -- oficinas; sempre aberto, como todo retorno.
        {x = 13, y = 22, side = 'south', to = 'hub', arrival = 'reservatorio', label = 'O REFÚGIO'},
        -- Gate composto 4+5→6: além da grade drenável, o portal só abre com
        -- 'passagemFundacao' (emissor ainda não existe — integração pendente).
        {x = 7, y = 2, side = 'north', to = 'fundacao', arrival = 'reservatorio',
            open = false, flag = 'passagemFundacao', label = 'FUNDAÇÃO'},
    },
    encounters = {
        -- C04-01: rastejantes de cisterna na passarela — dá para esgueirar
        -- pela mesma passarela, e o caminho seco lateral (x=18) é o desvio
        -- garantido da ficha, sem tocar os animais.
        {id = 'C04-01', loot = {gold = 2, xp = 2}, quota = 2, x = 10, y = 16, kind = 'crawler',
            units = {{kind = 'regent', x = 5, y = 5}, {kind = 'crawler', x = 9, y = 5}}},
        -- C04-02: sentinela + bruto da equipe de manutenção plantados na
        -- porta da ala leste — cruzar a porta toca a talk 'equipe'; só
        -- 'equipeConfronto' derruba na arena.
        {id = 'C04-02', loot = {gold = 5, xp = 4},  x = 19, y = 13, kind = 'ranger', talk = 'equipe', ctx = 'manutencao',
            confronto = 'equipeConfronto', quota = 2,
            beats = {{when = 'start', node = 'equipeAbertura'},
                {when = {hpBelow = .5}, node = 'rangerMetade', once = true},
                {when = 'mercy', node = 'rangerEntrega', once = true}},
            units = {
            {kind = 'warden', x = 6, y = 5, speaker = true}, {kind = 'dasher', x = 10, y = 5}}},
        -- C04-Q01 (opcional): rastejantes entre os canteiros — os corredores
        -- vazios das faixas (y=10, y=12, y=14) contornam sem luta; filtro e
        -- drenagem não passam por aqui.
        {id = 'C04-Q01', loot = {gold = 3, xp = 3}, quota = 2, x = 8, y = 12, kind = 'crawler', ctx = 'canteiro',
            units = {{kind = 'sower', x = 5, y = 6}, {kind = 'crawler', x = 8, y = 6}}},
        -- B04-01: Ivo junto da comporta; a talk resolve por 'canalTestado'/
        -- esquema e 'ivoConfronto' abre a arena. `channels` explícito ecoa a
        -- planta: rows {6,8} são as duas linhas de água do canal principal
        -- (pisos secos nas fileiras 5/7/9, como as margens); col {9} é o ramo
        -- vertical do canal de teste, que desce pelo lado leste da planta.
        {id = 'B04-01', loot = {gold = 12, xp = 12, items = {provisao = 1}},  x = 26, y = 5, kind = 'ivo', talk = 'ivo',
            confronto = 'ivoConfronto', quota = 2,
            beats = {{when = 'start', node = 'ivoAbertura'},
                {when = {hpBelow = .5}, node = 'ivoMetade', once = true},
                {when = 'mercy', node = 'ivoEntrega', once = true}},
            units = {{kind = 'ivo', x = 7, y = 5, speaker = true}},
            channels = {rows = {6, 8}, cols = {9}}},
    },
}
