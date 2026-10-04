-- Região 3: Mercado das Escoras (docs/mapas/03_MERCADO.md)
-- Praça de feira coberta por estruturas baixas: beco de chegada ao sul,
-- praça central com as bancas, praça de avaliação (Rute), arquivo e depósito
-- ao norte, e o corredor sudeste onde o carro de peças trava a rota 5.
-- Lugares garantidos da ficha: entrada, balcão de Ema (placa coberta), antiga
-- banca do casal, arquivo de encomendas, depósito de grades abertas e a
-- praça de avaliação — tudo alcançável antes dos encontros.
return {
    id = 'mercado', uid = 4, name = 'MERCADO DAS ESCORAS', w = 30, h = 24,
    spawn = {x = 6, y = 21},
    arrivals = {
        hub = {x = 6, y = 21, dx = 0, dy = -1},
        saloes = {x = 26, y = 20, dx = 0, dy = -1},
    },
    carve = {
        {x = 3, y = 2, w = 10, h = 6},   -- praça de avaliação (Rute)
        {x = 15, y = 2, w = 7, h = 5},   -- arquivo de encomendas
        {x = 24, y = 2, w = 5, h = 5},   -- depósito (grades abertas)
        {x = 9, y = 8, w = 2, h = 1},    -- passagem avaliação–praça
        {x = 17, y = 7, w = 2, h = 2},   -- passagem arquivo–praça
        {x = 25, y = 7, w = 3, h = 3},   -- caminho do depósito (C03-02)
        {x = 8, y = 9, w = 20, h = 6},   -- praça central da feira
        {x = 7, y = 15, w = 3, h = 2},   -- corredor beco–praça
        {x = 3, y = 17, w = 6, h = 5},   -- beco de chegada (C03-01)
        {x = 24, y = 15, w = 5, h = 6},  -- corredor da rota dos Salões
    },
    pillars = {
        -- Escoras da praça de avaliação e o par que segura o toldo amarelo
        -- do campanário cortado (marco visual da ficha).
        {x = 4, y = 3}, {x = 10, y = 6},
        {x = 16, y = 10}, {x = 18, y = 10},
    },
    walls = {
        -- Bases de banca arruinada no meio da praça (estruturas baixas).
        {x = 22, y = 12}, {x = 23, y = 12},
    },
    props = {
        -- Balcão de Ema: balcão + a placa coberta com a marca do patrão.
        {id = 'balcao', kind = 'balcao', x = 9, y = 11, w = 2, solid = true},
        {id = 'placaEma', kind = 'placaEma', x = 9, y = 10},
        -- Antiga banca do casal e a banca do feirante figurante.
        {id = 'bancaCasal', kind = 'bancaCasal', x = 20, y = 10, w = 2, solid = true},
        {id = 'bancoCasalM', kind = 'banco', x = 22, y = 10, solid = true},
        {id = 'bancaFeirante', kind = 'bancaFeirante', x = 13, y = 12, w = 2, solid = true},
        {id = 'toldoFeirante', kind = 'toldoFeirante', x = 13, y = 11},
        -- Toldo amarelo preso no campanário cortado (entre as duas escoras).
        {id = 'toldo', kind = 'toldo', x = 17, y = 10},
        -- Barracas vazias: decoração que varia sem esconder recurso.
        {id = 'caixasPraca', kind = 'caixas', x = 24, y = 12},
        {id = 'bancoPraca', kind = 'banco', x = 12, y = 13, solid = true},
        -- Arquivo de encomendas: fichário + bancada de registro.
        {id = 'fichario', kind = 'fichario', x = 19, y = 3, solid = true},
        {id = 'bancadaArquivo', kind = 'bancada', x = 16, y = 3, w = 2, solid = true},
        {id = 'caixasArquivo', kind = 'caixas', x = 21, y = 5},
        -- Depósito: grade aberta visível (nunca baú indistinguível), o lote
        -- de peças do forno e a mesa com o recibo de Ema.
        {id = 'gradeDeposito', kind = 'grade', x = 25, y = 6, w = 3, state = 'open'},
        {id = 'lote', kind = 'caixas', x = 26, y = 3, w = 2, solid = true},
        {id = 'mesaRecibo', kind = 'mesa', x = 25, y = 4, solid = true},
        {id = 'caixasDeposito', kind = 'caixas', x = 28, y = 4},
        -- Beco de chegada: entulho de feira fechada.
        {id = 'caixasBeco', kind = 'caixas', x = 3, y = 18},
        -- O carro de peças tapa a boca do portal dos Salões: sólido até a
        -- opção MOVER O CARRO do hotspot 'carro' marcar 'carroMovido'; o use
        -- abaixo recolhe o prop na próxima inspeção (a flag abre o portal).
        {id = 'carroPecas', kind = 'carroPecas', x = 25, y = 20, solid = true},
        {id = 'caixasRota', kind = 'caixas', x = 24, y = 17},
    },
    npcs = {
        {id = 'rute', x = 7, y = 4, dx = 0, dy = 1},
        {id = 'ema', x = 10, y = 10, dx = 0, dy = 1, talkRange = 2.3},
        {id = 'guarda', x = 7, y = 18, dx = 0, dy = 1},
        {id = 'feirante', x = 14, y = 11, dx = 0, dy = 1},
    },
    hotspots = {
        {id = 'placaEma', x = 9, y = 10, label = 'EXAMINAR'},
        {id = 'toldo', x = 17, y = 10, label = 'EXAMINAR'},
        {id = 'bancaCasal', x = 20, y = 10, label = 'EXAMINAR'},
        {id = 'arquivo', x = 19, y = 3, label = 'EXAMINAR'},
        {id = 'recibo', x = 25, y = 4, label = 'EXAMINAR'},
        {id = 'pecas', x = 26, y = 3, label = 'PEGAR'},
        {id = 'carro', x = 25, y = 20, label = 'EXAMINAR',
            use = function(c)
                if c:flag('carroMovido') then
                    -- setProp limpa propCells já nesta sessão; syncExits abre
                    -- o portal dos Salões sem exigir reentrada na região.
                    c:setProp('carroPecas', 'taken')
                    c:syncExits()
                end
            end},
        -- Placa de rota: a passagem dos Salões diz o destino e por que está
        -- trancada; some quando o carro abre a rota (letreiro do portal).
        {id = 'portalSaloes', x = 26, y = 19, label = 'LER'},
        {id = 'placaSaloes', x = 24, y = 20, label = 'POR QUE FECHADA?',
            when = function(c) return not c:flag('passagemSaloes') end,
            use = function(c)
                c:notify('SALÕES DAS VITRINES — trancada. O carro de peças ainda bloqueia a rota.')
            end},
    },
    exits = {
        {x = 6, y = 22, side = 'south', to = 'hub', arrival = 'mercado', label = 'REFÚGIO'},
        {x = 25, y = 21, side = 'south', to = 'saloes', arrival = 'mercado',
            open = false, flag = 'passagemSaloes', label = 'SALÕES'},
    },
    encounters = {
        -- C03-01: par de sentinelas do beco; contato abre a talk do guarda —
        -- explicação ou arco guardado liberam ('guardaLiberada'), só
        -- 'guardaConfronto' derruba na arena.
        {id = 'C03-01', loot = {gold = 4, xp = 3},  x = 5, y = 18, kind = 'ranger', talk = 'guarda', ctx = 'guarda',
            confronto = 'guardaConfronto', quota = 2,
            beats = {{when = 'start', node = 'guardaAbertura'},
                {when = {hpBelow = .5}, node = 'rangerMetade', once = true},
                {when = 'mercy', node = 'rangerEntrega', once = true}},
            units = {{kind = 'watcher', x = 5, y = 5}, {kind = 'ranger', x = 9, y = 5, speaker = true}}},
        -- C03-02: rastejantes nas barracas do caminho do depósito —
        -- contornáveis pelas laterais do corredor largo (desvio da planta).
        {id = 'C03-02', loot = {gold = 2, xp = 2}, quota = 2, x = 26, y = 8, kind = 'crawler',
            units = {{kind = 'breaker', x = 4, y = 6}, {kind = 'crawler', x = 8, y = 5}}},
        -- C03-Q01 (opcional): cobrador bruto da placa de Ema. Sem talk
        -- dedicada na lore — posicionado contornável junto do balcão.
        {id = 'C03-Q01', loot = {gold = 4, xp = 3}, quota = 2, x = 11, y = 13, kind = 'dasher', ctx = 'cobrador',
            beats = {{when = 'start', node = 'entulhoAbertura'}},
            units = {{kind = 'dasher', x = 7, y = 5}}},
        -- B03-01: Rute na praça de avaliação, ao lado do NPC — recibo ou
        -- registros resolvem; 'ruteConfronto' abre a arena. `crates` são os
        -- caixotes sólidos que a vara de avaliação empurra (spec §12 Bigorna;
        -- coords no tabuleiro 11x5 da arena, linhas 5..9 x colunas 2..12).
        {id = 'B03-01', loot = {gold = 12, xp = 12, items = {provisao = 1}},  x = 8, y = 5, kind = 'rute', talk = 'rute',
            confronto = 'ruteConfronto', quota = 2,
            beats = {{when = 'start', node = 'ruteAbertura'},
                {when = {hpBelow = .5}, node = 'ruteMetade', once = true},
                {when = 'mercy', node = 'ruteEntrega', once = true}},
            units = {{kind = 'rute', x = 7, y = 5, speaker = true}},
            crates = {{x = 4, y = 6}, {x = 10, y = 6}, {x = 6, y = 7}, {x = 9, y = 7}}},
    },
}
