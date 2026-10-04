-- Região 5: Salões das Vitrines (docs/mapas/05_SALOES.md)
-- Planta autoral por retângulos de piso; a casca de muros é gerada ao redor.
-- Criptas e capelas reaproveitadas como dormitório e teatro: chegada ao sul,
-- galeria de serviço (canal rompido) e cozinha auxiliar a oeste, salão com
-- palco raso e plateia ao centro-norte, depósito excedente nos fundos do
-- palco, ala ocupada a leste e o corredor superior de manutenção ao norte —
-- travado por uma escora/grade até o reforço da P05-E04.
-- Lugares garantidos da ficha, todos alcançáveis sem sorteio nem segredo:
-- chegada, cozinha auxiliar (mesa de reparo/moldura), palco (Beltran, lustre
-- incompleto, cadeira reservada), ala ocupada, depósito excedente (armário
-- técnico de ferragens) e corredor superior. Cira, dormitório e laudo ficam
-- acessíveis antes do chefe; a apresentação não depende de sala secreta.
return {
    id = 'saloes', uid = 6, name = 'SALÕES DAS VITRINES', w = 30, h = 24,
    spawn = {x = 6, y = 22},
    arrivals = {
        -- Rota do Mercado: o carro de peças libera o portal ('passagemSaloes')
        -- e a chegada desembarca no saguão sul olhando para o salão.
        mercado = {x = 6, y = 22, dx = 0, dy = -1},
        -- Retorno da Fundação pelo corredor superior de manutenção.
        fundacao = {x = 5, y = 3, dx = 0, dy = 1},
        -- Compat com --scene=saloes (travel com arrival 'hub').
        hub = {x = 6, y = 22, dx = 0, dy = -1},
    },
    carve = {
        {x = 3, y = 3, w = 7, h = 3},    -- corredor superior (manutenção → Fundação)
        {x = 6, y = 6, w = 1, h = 1},    -- boca da descida (escoraTrava bloqueia)
        {x = 3, y = 7, w = 7, h = 6},    -- cozinha auxiliar
        {x = 10, y = 3, w = 2, h = 2},   -- camarim (nicho do palco)
        {x = 10, y = 9, w = 2, h = 1},   -- passagem cozinha–salão
        {x = 12, y = 2, w = 11, h = 12}, -- salão: palco raso ao norte + plateia
        {x = 23, y = 4, w = 1, h = 1},   -- passagem palco–depósito
        {x = 24, y = 2, w = 6, h = 4},   -- depósito excedente (ferragens)
        {x = 5, y = 13, w = 2, h = 1},   -- passagem cozinha–galeria
        {x = 4, y = 14, w = 4, h = 4},   -- galeria de serviço (C05-01)
        {x = 8, y = 15, w = 1, h = 2},   -- desvio da portinhola (evita o ninho)
        {x = 6, y = 18, w = 1, h = 1},   -- passagem galeria–chegada
        {x = 3, y = 19, w = 8, h = 4},   -- saguão de chegada
        {x = 11, y = 20, w = 3, h = 2},  -- antecâmara chegada–vestíbulo
        {x = 13, y = 16, w = 10, h = 6}, -- vestíbulo leste (fundos da plateia)
        {x = 15, y = 14, w = 2, h = 2},  -- passagem salão–vestíbulo
        {x = 13, y = 22, w = 15, h = 1}, -- corredor lateral (rota de ensaio)
        {x = 23, y = 16, w = 1, h = 1},  -- passagem vestíbulo–ala ocupada
        {x = 24, y = 14, w = 6, h = 7},  -- ala ocupada (dormitório)
        {x = 27, y = 21, w = 1, h = 1},  -- saída lateral do dormitório (ensaio)
    },
    holes = {
        -- Canal rompido da galeria (de onde vêm os rastejantes) e a fissura
        -- do canto do salão que o cenário esconde — bordas claras da ficha.
        {x = 4, y = 15}, {x = 4, y = 16},
        {x = 21, y = 11}, {x = 22, y = 11}, {x = 22, y = 12},
    },
    pillars = {
        -- Arcos altos do corredor superior e pilares do salão (proteção de
        -- cena para a arena de Beltran, §arena da ficha).
        {x = 4, y = 4}, {x = 8, y = 4},
        {x = 13, y = 7}, {x = 21, y = 7}, {x = 18, y = 12},
    },
    props = {
        -- Corredor superior: a trava da descida. Sólida até a opção REFORÇAR
        -- A ESCORA do hotspot 'escora' marcar 'escoraReforcada'; o use do
        -- mesmo hotspot recolhe a grade na próxima inspeção (padrão 'carro'
        -- do mercado) — e também funciona pelo lado de dentro, caso o
        -- jogador desembarque da Fundação com a trava ainda armada.
        {id = 'escoraTrava', kind = 'escora', x = 6, y = 6, solid = true},
        {id = 'caixasSup', kind = 'caixas', x = 9, y = 5, solid = true},
        -- Cozinha auxiliar: fogão, bancada de louça e a mesa de reparo onde
        -- a moldura torta do casal espera (P05-E03).
        {id = 'fogaoCoz', kind = 'fogao', x = 4, y = 8, solid = true},
        {id = 'bancadaCoz', kind = 'bancada', x = 8, y = 8, solid = true},
        {id = 'mesaReparo', kind = 'mesa', x = 5, y = 10, w = 2, solid = true},
        {id = 'caixasCoz', kind = 'caixas', x = 3, y = 11, solid = true},
        {id = 'bancoCoz', kind = 'banco', x = 8, y = 11, solid = true},
        -- Galeria de serviço: portinhola aberta do canal e o desvio lateral.
        {id = 'tampaCanal', kind = 'tampa', x = 4, y = 14},
        {id = 'gradePortinhola', kind = 'grade', x = 8, y = 15, state = 'open'},
        {id = 'caixasGaleria', kind = 'caixas', x = 7, y = 17, solid = true},
        -- Palco: cortinas remendadas contra a parede do fundo, a cadeira
        -- reservada com o mesmo tecido, o lustre incompleto (marco da ficha,
        -- placeholder 'altar' até o prop próprio) e a case do instrumento.
        {id = 'cortinaA', kind = 'cortina', x = 13, y = 2, solid = true},
        {id = 'cortinaB', kind = 'cortina', x = 16, y = 2, solid = true},
        {id = 'cortinaC', kind = 'cortina', x = 19, y = 2, solid = true},
        {id = 'cadeiraReservada', kind = 'banco', x = 14, y = 4, solid = true},
        {id = 'lustre', kind = 'lustre', x = 18, y = 3, solid = true},
        {id = 'instrumento', kind = 'instrumento', x = 21, y = 3, solid = true},
        {id = 'cartaz', kind = 'pano', x = 12, y = 6, solid = true},
        -- Vitrines do salão (nota Prisma: o hall lia "vazio"): mostruários
        -- de parede entre as cortinas. kind 'bau' até o Traço cadastrar
        -- draw.vitrine — trocar kind p/ 'vitrine' quando a arte chegar.
        {id = 'vitrineA', kind = 'bau', x = 14, y = 2, solid = true},
        {id = 'vitrineB', kind = 'bau', x = 17, y = 2, solid = true},
        -- Camarim: banco e varal de figurino (pano = cabides improvisados).
        {id = 'bancoCamarim', kind = 'banco', x = 10, y = 3, solid = true},
        {id = 'cabides', kind = 'pano', x = 10, y = 4, solid = true},
        -- Plateia: bancos em duas fileiras com corredores vivos.
        {id = 'bancoP1', kind = 'banco', x = 14, y = 8, solid = true},
        {id = 'bancoP2', kind = 'banco', x = 15, y = 8, solid = true},
        {id = 'bancoP3', kind = 'banco', x = 17, y = 8, solid = true},
        {id = 'bancoP4', kind = 'banco', x = 18, y = 8, solid = true},
        {id = 'bancoP5', kind = 'banco', x = 14, y = 10, solid = true},
        {id = 'bancoP6', kind = 'banco', x = 16, y = 10, solid = true},
        {id = 'bancoP7', kind = 'banco', x = 18, y = 10, solid = true},
        {id = 'bancoP8', kind = 'banco', x = 20, y = 10, solid = true},
        -- Chegada e vestíbulo: entulho de feira e material de mudança.
        {id = 'caixasEntrada', kind = 'caixas', x = 3, y = 20, solid = true},
        {id = 'bancoEntrada', kind = 'banco', x = 9, y = 20, solid = true},
        {id = 'caixasVest', kind = 'caixas', x = 14, y = 17, solid = true},
        {id = 'carteirasVest', kind = 'carteiras', x = 17, y = 19, w = 2, solid = true},
        {id = 'bancoVest', kind = 'banco', x = 20, y = 19, solid = true},
        -- Ala ocupada: camas baixas realocadas + pertences dos moradores.
        {id = 'camaAla1', kind = 'cama', x = 25, y = 14, solid = true},
        {id = 'camaAla2', kind = 'cama', x = 27, y = 14, solid = true},
        {id = 'camaAla3', kind = 'cama', x = 25, y = 18, solid = true},
        {id = 'caixasDorm', kind = 'caixas', x = 28, y = 19, solid = true},
        {id = 'bancoDorm', kind = 'banco', x = 24, y = 19, solid = true},
        -- Depósito excedente: divisórias de vitrine encostadas (grade =
        -- painéis até o prop próprio), o armário técnico de ferragens
        -- (indestrutível, recurso protegido da ficha) e a planta arquivada.
        {id = 'divisorias', kind = 'divisoria', x = 25, y = 3, w = 2, solid = true},
        {id = 'armarioTecnico', kind = 'bau', x = 28, y = 3, solid = true},
        {id = 'plantaSaloes', kind = 'mesa', x = 25, y = 5, solid = true},
        {id = 'ferramDep', kind = 'ferramentas', x = 26, y = 5, solid = true},
        {id = 'caixasDep', kind = 'caixas', x = 28, y = 5, solid = true},
    },
    npcs = {
        -- Beltran rege o palco; Cira ensaia junto do instrumento; o ajudante
        -- aguarda à lateral do palco para propor o duelo combinado; a
        -- plateia figura entre os bancos, fora da arena por design.
        {id = 'beltran', x = 15, y = 4, dx = 0, dy = 1},
        {id = 'cira', x = 20, y = 4, dx = 0, dy = 1},
        {id = 'ajudante', x = 19, y = 6, dx = 0, dy = -1},
        {id = 'plateia', x = 16, y = 9, dx = 0, dy = 1},
        -- Neco convidado: a talk do hub grava people.neco.location='saloes'
        -- (necoNoSalao, NE03) — a entrada só spawna quando a realocação
        -- acontece; até lá fica inerte. Lugar de honra junto da cadeira
        -- reservada, de frente para o palco.
        {id = 'neco', x = 14, y = 5, dx = 0, dy = -1},
    },
    hotspots = {
        {id = 'programa', x = 12, y = 6, label = 'EXAMINAR'},
        {id = 'cortina', x = 16, y = 2, label = 'EXAMINAR'},
        {id = 'moldura', x = 5, y = 10, label = 'EXAMINAR'},
        {id = 'laudo', x = 26, y = 15, label = 'EXAMINAR'},
        {id = 'armarioTecnico', x = 28, y = 3, label = 'EXAMINAR'},
        -- Divisórias excedentes do pedido de Teca: coleta única — o prop sai
        -- de cena na revisita (mesmo id prop/hotspot, padrão 'ferramentas').
        {id = 'divisorias', x = 25, y = 3, label = 'PEGAR', once = true},
        {id = 'fundacao', x = 25, y = 5, label = 'EXAMINAR'},
        -- A escora da descida: a opção REFORÇAR da lore seta 'escoraReforcada'
        -- e o use abaixo, na mesma inspeção seguinte, recolhe a trava e
        -- ressincroniza os exits. Lado da cozinha E lado do corredor alcançam
        -- o ponto (range 1.45 sobre a boca de 1 célula).
        {id = 'escora', x = 6, y = 6, label = 'EXAMINAR',
            use = function(c)
                if c:flag('escoraReforcada') then
                    -- setProp limpa propCells já nesta sessão; syncExits abre
                    -- o portal da Fundação se 'passagemFundacao' já estiver
                    -- alta (flag ainda sem emissor — gate composto M4+M5).
                    c:setProp('escoraTrava', 'taken')
                    c:syncExits()
                end
            end},
        {id = 'ensaio', x = 27, y = 21, label = 'EXAMINAR'},
        {id = 'instrumento', x = 21, y = 3, label = 'EXAMINAR'},
        {id = 'cartaz', x = 5, y = 16, label = 'LER'},
        {id = 'cadeira', x = 14, y = 4, label = 'EXAMINAR'},
        -- Placa de rota: o corredor superior diz o destino e por que está
        -- trancado; some quando 'passagemFundacao' abre o letreiro.
        -- Ao lado da boca, na cozinha: (7,7) não captura o exame da escora
        -- em (6,7) — o empate de distância resolve pelo spot anterior.
        {id = 'placaFundacao', x = 7, y = 7, label = 'POR QUE FECHADA?',
            when = function(c) return not c:flag('passagemFundacao') end,
            use = function(c)
                c:notify('QUARTOS DA FUNDAÇÃO — trancada. A subida pede a água drenada no reservatório e esta escora reforçada.')
            end},
    },
    exits = {
        {x = 6, y = 23, side = 'south', to = 'mercado', arrival = 'saloes', label = 'MERCADO'},
        -- Retorno direto ao refúgio (Codex D29): baía de passagens junto do
        -- portal do mercado; sempre aberto, como todo retorno.
        {x = 8, y = 23, side = 'south', to = 'hub', arrival = 'saloes', label = 'O REFÚGIO'},
        -- Corredor superior → Fundação. O portal só abre quando a flag
        -- composta 'passagemFundacao' existir (drenagem M4 + escora M5);
        -- a trava física é a 'escoraTrava' acima — as duas camadas são
        -- independentes, como no padrão mercado (carro + flag).
        {x = 5, y = 2, side = 'north', to = 'fundacao', arrival = 'saloes',
            open = false, flag = 'passagemFundacao', label = 'FUNDAÇÃO'},
    },
    encounters = {
        -- C05-01: rastejantes do canal rompido na galeria de serviço.
        -- Contornáveis pela faixa leste (x6-7) e pelo desvio da portinhola.
        {id = 'C05-01', loot = {gold = 2, xp = 2}, quota = 2, x = 5, y = 15, kind = 'crawler',
            units = {{kind = 'husk', x = 4, y = 5}, {kind = 'crawler', x = 8, y = 5}}},
        -- C05-02: sentinelas vigias do abrigo na ala ocupada. Não há talk
        -- dedicada em saloesTalks (pendência de integração) — posicionado
        -- contornável: o laudo e o fundo da ala alcançam sem contato.
        {id = 'C05-02', loot = {gold = 4, xp = 3},  x = 26, y = 17, kind = 'ranger', ctx = 'vigia',
            quota = 2,
            beats = {{when = 'start', node = 'vigiaAbertura'},
                {when = {hpBelow = .5}, node = 'rangerMetade', once = true},
                {when = 'mercy', node = 'rangerEntrega', once = true}},
            units = {{kind = 'veteran', x = 5, y = 5, speaker = true}, {kind = 'ranger', x = 9, y = 5}}},
        -- C05-Q1 (opcional): o duelo combinado do ajudante. 'dueloProposto'
        -- é o ACEITE do ensaio ("COMBINADO, ATÉ A RENDIÇÃO") — a arena só
        -- dispara depois da conversa; desfecho sempre não-letal.
        {id = 'C05-Q1', loot = {gold = 5, xp = 5},  x = 21, y = 6, kind = 'dasher', talk = 'ajudante', ctx = 'duelo',
            confronto = 'dueloProposto', quota = 2,
            beats = {{when = 'start', node = 'dueloAbertura'}},
            units = {{kind = 'dasher', x = 7, y = 5, speaker = true}}},
        -- B05-01: Beltran no palco. Tocar abre a talk primeiro; a arena só
        -- dispara com 'beltranConfronto' alto ("O SHOW ACABA AQUI") ou se a
        -- negociação grava encounters['B05-01']='negotiated'. Sem campos
        -- extras — empurrão via dash é automático (spec Bigorna).
        {id = 'B05-01', loot = {gold = 15, xp = 15, items = {provisao = 1}},  x = 16, y = 5, kind = 'beltran', talk = 'beltran',
            confronto = 'beltranConfronto', quota = 2,
            beats = {{when = 'start', node = 'beltranAbertura'},
                {when = {hpBelow = .5}, node = 'beltranMetade', once = true},
                {when = 'mercy', node = 'beltranEntrega', once = true}},
            units = {{kind = 'beltran', x = 7, y = 5, speaker = true}}},
    },
}
