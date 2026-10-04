-- Região 2: Oficinas de Dentro (docs/mapas/02_OFICINAS.md)
-- Planta autoral por retângulos de piso; a casca de muros é gerada ao redor.
-- Lugares garantidos da ficha, todos alcançáveis sem sorteio nem segredo:
-- entrada da oficina (placa de turnos + roda de trabalho parada), bancada
-- de Brina, alojamento dos trabalhadores, depósito (conjunto de ferramentas
-- atrás de grade + registro + encomenda de Lia), saída danificada reparável
-- (rota de manutenção para o reservatório) e oficina central (Janda).
-- Circuito: entrada -> corredor com divisória -> pátio central; o pátio liga
-- alojamento, depósito e entulho; um corredor secundário liga a bancada de
-- volta ao corredor da divisória (anel, não beco único).
return {
    id = 'oficinas', uid = 3, name = 'OFICINAS DE DENTRO', w = 30, h = 24,
    spawn = {x = 15, y = 21},
    arrivals = {
        hub = {x = 16, y = 22, dx = 0, dy = -1},
        reservatorio = {x = 27, y = 9, dx = 0, dy = 1},
    },
    carve = {
        {x = 12, y = 18, w = 8, h = 5},  -- entrada da oficina
        {x = 14, y = 11, w = 4, h = 7},  -- corredor com divisória (C02-01)
        {x = 9, y = 3, w = 13, h = 8},   -- oficina central (pátio do trabalho)
        {x = 3, y = 3, w = 5, h = 6},    -- alojamento dos trabalhadores
        {x = 8, y = 6, w = 1, h = 2},    -- corredor central–alojamento
        {x = 3, y = 11, w = 6, h = 5},   -- bancada de Brina
        {x = 6, y = 9, w = 1, h = 2},    -- corredor alojamento–bancada
        {x = 9, y = 13, w = 5, h = 1},   -- corredor bancada–divisória
        {x = 23, y = 3, w = 6, h = 5},   -- depósito (nicho atrás da grade)
        {x = 22, y = 6, w = 1, h = 2},   -- corredor central–depósito
        {x = 24, y = 9, w = 5, h = 5},   -- entulho / saída danificada (C02-02)
        {x = 22, y = 9, w = 2, h = 1},   -- corredor central–entulho
        {x = 25, y = 8, w = 1, h = 1},   -- corredor depósito–entulho (atalho)
    },
    walls = {
        -- Estreitamento de portas (fora dos cantos, deslocamento variado):
        {x = 14, y = 10}, {x = 15, y = 10}, {x = 17, y = 10}, -- porta p/ o pátio em x=16
        {x = 15, y = 18}, {x = 16, y = 18}, {x = 17, y = 18}, -- porta da entrada em x=14
        -- Divisória do corredor: reparte a passagem em duas (oeste 1, leste 2).
        {x = 15, y = 13}, {x = 15, y = 14}, {x = 15, y = 15},
        -- Antepara do depósito: muros flanqueiam a grade; o nicho ao norte
        -- (linha y=3) guarda o conjunto de ferramentas, visível e inacessível
        -- a pé — alcançável por interação através das barras.
        {x = 23, y = 4}, {x = 24, y = 4}, {x = 27, y = 4}, {x = 28, y = 4},
    },
    holes = {
        {x = 24, y = 13}, {x = 25, y = 13}, -- piso cedido no entulho
    },
    pillars = {
        {x = 11, y = 8}, {x = 19, y = 8}, -- pilares do pátio
        -- Escoras da saída danificada: sustentam o vão do portal fechado.
        {x = 26, y = 9}, {x = 28, y = 9},
    },
    props = {
        -- Entrada: placa de turnos (pano improvisado) + roda de trabalho
        -- parada (cisterna como suporte visual — pedido de prop novo: 'roda').
        {id = 'placa', kind = 'placa', x = 12, y = 19, solid = true},
        {id = 'roda', kind = 'roda', x = 18, y = 19, w = 2, h = 2, solid = true},
        {id = 'caixasEntrada', kind = 'caixas', x = 13, y = 21, solid = true},
        -- Oficina central: forja do pátio + bancada da mestra.
        {id = 'forja', kind = 'fogao', x = 12, y = 4, solid = true},
        {id = 'bancadaJanda', kind = 'bancada', x = 18, y = 4, w = 2, solid = true},
        {id = 'caixasCentral', kind = 'caixas', x = 20, y = 3, solid = true},
        -- Alojamento: camas junto de caixas; descanso e serviço na mesma parede.
        {id = 'cama1', kind = 'cama', x = 4, y = 4, solid = true},
        {id = 'cama2', kind = 'cama', x = 6, y = 4, solid = true},
        {id = 'cama3', kind = 'cama', x = 4, y = 7, solid = true},
        {id = 'caixasAloj', kind = 'caixas', x = 7, y = 3, solid = true},
        -- Bancada de Brina: bancada assinada + pano com a marca (pedido de
        -- prop novo: 'marca'/placa de autoria).
        {id = 'bancadaBrina', kind = 'bancada', x = 4, y = 12, w = 2, solid = true},
        {id = 'marcaBrina', kind = 'marcaBrina', x = 7, y = 11},
        {id = 'torno', kind = 'bancada', x = 21, y = 4, solid = true},
        {id = 'mesaBancada', kind = 'mesa', x = 6, y = 14, w = 2, solid = true},
        {id = 'caixasBancada', kind = 'caixas', x = 3, y = 14, solid = true},
        -- Depósito: grade + conjunto de ferramentas no nicho, registro e
        -- encomendas na área principal.
        {id = 'gradeDeposito', kind = 'grade', x = 25, y = 4, w = 2, solid = true},
        {id = 'ferramentas', kind = 'ferramentas', x = 26, y = 3, solid = true},
        {id = 'bauDeposito', kind = 'caixas', x = 24, y = 3, solid = true},
        {id = 'mesaRegistro', kind = 'mesa', x = 24, y = 6, w = 2, solid = true},
        {id = 'carteirasDep', kind = 'carteiras', x = 27, y = 6, w = 2, solid = true},
        {id = 'caixasDep', kind = 'caixas', x = 23, y = 5, solid = true},
        -- Entulho: restos de obra e peças rompidas antes da saída (pedido de
        -- prop novo: 'entulho'/'escora').
        {id = 'caixasEntulho', kind = 'caixas', x = 24, y = 11, solid = true},
        {id = 'caixasEntulho2', kind = 'caixas', x = 28, y = 12, solid = true},
        {id = 'tampaEntulho', kind = 'escora', x = 25, y = 12},
        {id = 'bancoEntulho', kind = 'banco', x = 27, y = 13},
    },
    npcs = {
        {id = 'janda', x = 17, y = 5, dx = 0, dy = 1},
        {id = 'brina', x = 5, y = 13, dx = 0, dy = -1},
        {id = 'neco', x = 5, y = 6, dx = 0, dy = 1},
        {id = 'traba', x = 3, y = 5, dx = 1, dy = 0},
        {id = 'trabb', x = 7, y = 5, dx = -1, dy = 0},
    },
    hotspots = {
        {id = 'placaOficina', x = 12, y = 19, label = 'EXAMINAR'},
        {id = 'bancadaBrina', x = 4, y = 12, label = 'EXAMINAR'},
        {id = 'alojamento', x = 4, y = 7, label = 'EXAMINAR'},
        {id = 'ferramentas', x = 26, y = 3, label = 'PEGAR', range = 2.4, once = true},
        {id = 'registroOficina', x = 24, y = 6, label = 'EXAMINAR'},
        -- saidaDanificada: a lore não tem emissor da flag 'saidaReforcada';
        -- o hook `use` faz a interação em dois tempos — a primeira leitura
        -- mostra o texto "danificada" e marca 'saidaInspecionada'; a segunda
        -- vira o reparo ('saidaReforcada') e o node já retorna a variante
        -- reforçada (P02-E03 da ficha).
        {id = 'saidaDanificada', x = 27, y = 10, label = 'REFORÇAR',
            use = function(c)
                if c:flag('saidaInspecionada') then
                    c.data.flags.saidaReforcada = true
                    c:completeStep('P02-E03')
                else
                    c.data.flags.saidaInspecionada = true
                end
            end},
        {id = 'oficinaCentral', x = 12, y = 4, label = 'EXAMINAR'},
        -- Detalhes de ambiente (Pena): o quadro de turnos na parede e
        -- o torno com a peça pela metade junto da bancada de Janda.
        {id = 'jornalTurno', x = 15, y = 4, label = 'EXAMINAR'},
        {id = 'torno', x = 21, y = 4, label = 'EXAMINAR'},
        -- Placa de rota: o portal do reservatório diz o destino e por que
        -- está trancado; some quando 'passagemReservatorio' abre o letreiro.
        {id = 'portalReservatorio', x = 26, y = 8, label = 'LER'},
        {id = 'placaReservatorio', x = 27, y = 9, label = 'POR QUE FECHADA?',
            when = function(c) return not c:flag('passagemReservatorio') end,
            use = function(c)
                c:notify('RESERVATÓRIO DE BAIXO — trancada. A rota de manutenção precisa da saída reforçada e do aval de Sabela.')
            end},
    },
    exits = {
        {x = 16, y = 23, side = 'south', to = 'hub', arrival = 'oficinas', label = 'REFÚGIO'},
        -- Rota de manutenção junto da saída danificada: abre quando Sabela
        -- emite 'passagemReservatorio' no hub (campaign_lore.lua ~933).
        {x = 27, y = 8, side = 'north', to = 'reservatorio', arrival = 'oficinas',
            open = false, flag = 'passagemReservatorio', label = 'RESERVATÓRIO'},
    },
    encounters = {
        -- Corredor com divisória: sentinela + rastejante entre as passagens.
        {id = 'C02-01', loot = {gold = 3, xp = 2}, quota = 2, x = 15, y = 12, kind = 'ranger', ctx = 'acesso',
            beats = {{when = 'start', node = 'acessoAbertura'}},
            units = {{kind = 'ranger', x = 6, y = 5, speaker = true}, {kind = 'crawler', x = 10, y = 5}}},
        -- Entulho antes da saída: bruto + rastejante, contornável pelas bordas.
        {id = 'C02-02', loot = {gold = 3, xp = 2}, quota = 2, x = 26, y = 11, kind = 'dasher', ctx = 'entulho',
            beats = {{when = 'start', node = 'entulhoAbertura'}},
            units = {{kind = 'demolisher', x = 7, y = 5, speaker = true}, {kind = 'crawler', x = 10, y = 5}}},
        -- Sentinela solta no pátio (nenhuma talk de 'cobrador' existe em
        -- oficinasTalks — encontro comum, posicionado de modo contornável).
        {id = 'C02-03', loot = {gold = 4, xp = 3}, quota = 2, x = 12, y = 6, kind = 'ranger', ctx = 'cobrador',
            beats = {{when = 'start', node = 'cobradorAbertura'}}},
        -- Janda no pátio, junto (sem sobrepor) ao NPC: tocar abre a talk
        -- primeiro; a arena só dispara com 'jandaConfronto' alta ("ENTÃO VEM
        -- BUSCAR") — a negociação grava encounters['B02-01']='negotiated'.
        {id = 'B02-01', loot = {gold = 10, xp = 10, items = {provisao = 1}}, quota = 2, x = 16, y = 6, kind = 'janda', talk = 'janda',
            confronto = 'jandaConfronto',
            beats = {{when = 'start', node = 'jandaAbertura'},
                {when = {hpBelow = .5}, node = 'jandaMetade', once = true},
                {when = 'mercy', node = 'jandaEntrega', once = true}},
            units = {{kind = 'janda', x = 8, y = 5, speaker = true}}},
    },
}
