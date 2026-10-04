-- Campaign lore for "A Cidade Que Me Enterrou": cast names, voice pitches and
-- the dialogue nodes of the first recorte (Colina + first hub visit). Content
-- follows docs/GUIA_ESCRITA_DEVIN.md: one voice per person, PT-BR natural.
-- State lives in campaign.state; these builders only read it.
local Dialogue = require('src.dialogue')
local Lore = require('src.lore')
local LoreC = {}

LoreC.npcs = {
    doro = {name = 'DORO', home = 'colina'},
    runa = {name = 'RUNA', home = 'colina'},
    bento = {name = 'BENTO', home = 'hub'},
    teca = {name = 'TECA', home = 'hub'},
    sabela = {name = 'SABELA', home = 'hub'},
    nilo = {name = 'NILO', home = 'hub'},
    aurel = {name = 'AUREL', home = 'hub'},
    -- Figurantes de base do Refúgio (vida do lugar): residentes desde o T0 — os marcos mudam postos via def.posts, não existência. Chegadas com arco (brina/neco/ema futuras) é que usam home 'fora'.
    anciao = {name = 'ANCIÃO', home = 'hub'},
    lavadeira = {name = 'LAVADEIRA', home = 'hub'},
    carregador = {name = 'CARREGADOR', home = 'hub'},
    lenhador = {name = 'LENHADOR', home = 'hub'},
    crianca = {name = 'CRIANÇA', home = 'hub'},
    -- Mundo 2 (Oficinas de Dentro): janda é adversária, brina e neco são
    -- arcos próprios; traba/trabb são figurantes de alojamento em versão
    -- curta (um quer ficar, um quer partir — a ficha proíbe vontade única).
    janda = {name = 'JANDA', home = 'oficinas'},
    brina = {name = 'BRINA', home = 'oficinas'},
    neco = {name = 'NECO', home = 'oficinas'},
    traba = {name = 'TRABALHADORA', home = 'oficinas'},
    trabb = {name = 'TRABALHADOR', home = 'oficinas'},
    -- Mundo 3 (Mercado das Escoras): rute é adversária, ema tem arco
    -- próprio; 'guarda' é id compartilhado pelo par de sentinelas do C03-01
    -- (o mini-diálogo de abordagem é um só); feirante é figurante de banca.
    rute = {name = 'RUTE', home = 'mercado'},
    ema = {name = 'EMA', home = 'mercado'},
    guarda = {name = 'GUARDA DA FEIRA', home = 'mercado'},
    feirante = {name = 'FEIRANTE', home = 'mercado'},
    -- Mundo 4 (Reservatório de Baixo): ivo é adversário, mara tem arco
    -- próprio; 'equipe' é id compartilhado pela equipe C04-02; 'voz' é o
    -- gritante do outro lado do canal (figurante, só texto).
    ivo = {name = 'IVO', home = 'reservatorio'},
    mara = {name = 'MARA', home = 'reservatorio'},
    voz = {name = 'VOZ DO CANAL', home = 'reservatorio'},
    equipe = {name = 'MANUTENÇÃO', home = 'reservatorio'},
    -- Mundo 5 (Salões das Vitrines): beltran é adversário, cira é arco
    -- próprio; 'ajudante' propõe o duelo C05-Q1; 'plateia' é figurante do
    -- público (fica fora da arena por design).
    beltran = {name = 'BELTRAN', home = 'saloes'},
    cira = {name = 'CIRA', home = 'saloes'},
    ajudante = {name = 'AJUDANTE', home = 'saloes'},
    plateia = {name = 'PLATEIA', home = 'saloes'},
}

LoreC.voices = {doro = .8, runa = 1.05, bento = .68, teca = 1.0,
    sabela = 1.22, nilo = 1.42, aurel = .5,
    anciao = .72, lavadeira = 1.05, carregador = .82, lenhador = .6, crianca = 1.5,
    janda = .62, brina = 1.1, neco = .95, traba = 1.15, trabb = .88,
    rute = .9, ema = 1.18, guarda = .85, feirante = 1.3,
    ivo = .78, mara = .98, voz = 1.25, equipe = .9,
    beltran = 1.1, cira = 1.15, ajudante = .95, plateia = 1.3}
for id, pitch in pairs(LoreC.voices) do Lore.voices[id] = pitch end

LoreC.titles = {narration = ' ', sepultura = 'SUA SEPULTURA', pertences = 'SEUS PERTENCES'}

-- Helpers de estado (declarados antes de LoreC.hotspot: os nodes de
-- inspeção também usam flag/done/swap — locals só capturam o que já existe).
local function met(campaign, id) return (campaign.data.people[id] or {}).met == true end
local function mark(campaign, id)
    local person = campaign.data.people[id] or {}
    person.met = true
    campaign.data.people[id] = person
end
local function done(campaign, step) return campaign.data.steps[step] == true end

-- P01-E05 (entrar no hub) conclui quando Bento, Teca e Aurel foram
-- apresentados — o passo amarra a cena sem repetir a abertura na revisita.
local function maybeE05(campaign)
    if met(campaign, 'bento') and met(campaign, 'teca') and met(campaign, 'aurel') then
        campaign:completeStep('P01-E05')
    end
end

-- P02-E02 (conhecer o conflito): Brina distingue material excedente e Neco
-- mostra que os trabalhadores não podem partir — o passo conclui quando os
-- dois foram conhecidos, sem exigir acordo com nenhum.
local function maybeE02(campaign)
    if met(campaign, 'brina') and met(campaign, 'neco') then
        campaign:completeStep('P02-E02')
    end
end

-- Janda resolvida: 'negotiated'|'won' em encounters['B02-01'] ou letal.
local function jandaResolvida(campaign)
    local r = campaign.data.encounters['B02-01']
    return r == 'won' or r == 'negotiated' or campaign:flag('jandaMorta')
end

-- Rute resolvida: mesma convenção no encontro proposto 'B03-01'.
local function ruteResolvida(campaign)
    local r = campaign.data.encounters['B03-01']
    return r == 'won' or r == 'negotiated' or campaign:flag('ruteMorta')
end

-- Ivo resolvido: encontro proposto 'B04-01', letal, ou caminho de objeto
-- (comporta aberta pelo esquema+volante — QA exige fim sem ele vivo).
local function ivoResolvido(campaign)
    local r = campaign.data.encounters['B04-01']
    return r == 'won' or r == 'negotiated' or campaign:flag('ivoMorta')
        or campaign:flag('comportaAberta')
end

-- P04-E02: jardim conhecido (Mara) + interdição vista.
local function maybeM4E02(campaign)
    if met(campaign, 'mara') and campaign:flag('interdicaoVista') then
        campaign:completeStep('P04-E02')
    end
end

-- Beltran resolvido: encontro proposto 'B05-01' ou letal.
local function beltranResolvido(campaign)
    local r = campaign.data.encounters['B05-01']
    return r == 'won' or r == 'negotiated' or campaign:flag('beltranMorta')
end

local function swap(campaign, node)
    Dialogue.open(campaign, node)
    return false
end

LoreC.intro = {
    title = LoreC.titles.narration, voice = 'inscription',
    lines = {
        'A tampa da sua sepultura cedeu por dentro. Sete anos de poeira — e um encaixe recém-trocado.',
        'Você saiu. A Colina dos Sepultados acordou junto.',
    },
}

LoreC.hubArrival = {
    title = LoreC.titles.narration, voice = 'inscription',
    lines = {
        'O refúgio: uma casa funerária que virou casa, capela que virou cozinha.',
        'Toda porta aqui tem nome. Toda luz tem dono. E todos conhecem a sua cova.',
    },
}

-- Hotspot narrations resolve through this table; effects read and write
-- campaign.state directly, once-flags included.
function LoreC.hotspot(campaign, spot)
    local id = spot.id
    if id == 'sepultura' then
        return {title = LoreC.titles.sepultura, voice = 'inscription', lines = {
            'Oitavo encaixe, lado de dentro: o único que estava rachado.',
            'Alguém o trocou esta noite. Foi assim que a tampa cedeu.',
        }}
    elseif id == 'pano' then
        return {title = 'CAIXA DE FERRAMENTAS', voice = 'inscription', lines = {
            'Martelo, nível, um metro dobrado — ferramentas de quem cuida das sepulturas.',
            'O dono trabalha devagar e não costuma levar tudo de volta.',
        }}
    elseif id == 'pertences' then
        campaign:completeStep('P01-E02')
        campaign.data.flags.casaco = true
        campaign:giveItem('arco')
        campaign:giveItem('picareta')
        campaign:setProp('bau', 'done')
        return {title = LoreC.titles.pertences, voice = 'inscription', lines = {
            'O casaco pesado, dobrado com cuidado. O remendo no cotovelo é ponto torto — Lia ria do próprio acabamento.',
            'Embaixo dele: o arco de viagem, a aljava e o resto do que era seu.',
        }}
    elseif id == 'altar' then
        return {title = 'ALTAR', voice = 'inscription', lines = {
            'Um altar sem santo. A casa funerária rezava para quem ficava, não para quem partia.',
        }}
    elseif id == 'cisterna' then
        return {title = 'CISTERNA', voice = 'inscription', lines = {
            'Água parada embaixo da casa. O refúgio vive do que a cidade afundada ainda devolve.',
        }}
    elseif id == 'bancada' then
        return {title = 'BANCADA', voice = 'inscription', lines = {
            'Ferramentas de carpintaria e alvenaria. Doro remenda o refúgio inteiro nesta bancada.',
        }}
    -- Hotspots propostos para a Colina (level-design ainda não posicionou os
    -- props; os ids abaixo já resolvem texto se o ponto existir no mapa):
    elseif id == 'tampa' then
        return {title = 'TAMPA DA COVA', voice = 'inscription', lines = {
            'A tampa recém-trocada, virada ao lado da cova.',
            'A marca partida fica do lado de dentro — como se algo tivesse empurrado.',
        }}
    elseif id == 'flores' then
        return {title = 'FLORES DO VELÓRIO', voice = 'inscription', lines = {
            'Murchas na borda, firmes no caule. Alguém ainda troca a água.',
            'Os vivos daqui cuidam até do que já murchou.',
        }}
    elseif id == 'lapide' then
        return {title = 'LÁPIDE', voice = 'inscription', lines = {
            'O nome gastou com a chuva. Alguém refez a letra a mão — e errou a data.',
        }}
    elseif id == 'lapideProt' then
        if campaign:flag('pactoRevelado') then
            return {title = 'SUA LÁPIDE', voice = 'inscription', lines = {
                'A inscrição antiga está coberta por um pano.',
                'A casa ainda decide o que escrever no lugar da história oficial.',
            }}
        end
        return {title = 'SUA LÁPIDE', voice = 'inscription', lines = {
            'AQUI JAZ O FORASTEIRO — O QUE SE OFERECEU PELA CASA.',
            'A letra é caprichada. A versão, conveniente demais.',
        }}
    elseif id == 'caixao' then
        return {title = 'CAIXÃO VAZIO', voice = 'inscription', lines = {
            'Forrado, fechado e sem ocupante. A casa preparou até caixa.',
            'A tampa empenou. Doro deve ter um uso pra ela — e pra caixa.',
        }}
    -- Hotspots propostos das Oficinas (ids prontos para o level-design):
    elseif id == 'placaOficina' then
        return {title = 'PLACA DE TURNOS', voice = 'inscription', lines = {
            'O TRABALHO CONTINUA ATÉ O SINO.',
            'O sino enferrujou faz sete anos. O trabalho não percebeu.',
        }}
    elseif id == 'bancadaBrina' then
        return {title = 'BANCADA DE BRINA', voice = 'inscription', lines = {
            'Cada ferramenta tem acabamento próprio — e cada uma foi testada até reclamar.',
            'Uma fivela tem o mesmo desenho da sua: abertura de uma mão só.',
        }}
    elseif id == 'alojamento' then
        return {title = 'ALOJAMENTO', voice = 'inscription', lines = {
            'Camas junto de caixas e ferramentas. Descanso e serviço dividem a mesma parede.',
            'Em uma das camas, um caderno de pagamentos em vez de travesseiro.',
        }}
    elseif id == 'saidaDanificada' then
        if campaign:flag('saidaReforcada') then
            return {title = 'SAÍDA DA OFICINA', voice = 'inscription', lines = {
                'A saída agora aguenta passagem: escoras novas sobre as velhas.',
                'O caminho de manutenção até o reservatório existe de novo.',
            }}
        end
        return {title = 'SAÍDA DANIFICADA', voice = 'inscription', lines = {
            'A saída se mantém por escoras e teimosia.',
            'Dá para reforçar o que existe — ou abrir caminho novo ao lado.',
        }}
    elseif id == 'ferramentas' then
        -- Recolher o conjunto marca a posse; a entrega efetiva a Doro no hub
        -- consolida 'ferramentasEntregues' e conclui P02-E05.
        campaign.data.flags.conjuntoFerramentas = true
        return {title = 'CONJUNTO DE FERRAMENTAS', voice = 'inscription', lines = {
            'Excedente de boa qualidade: não sustenta o abrigo, sustenta o refúgio.',
            'O conjunto que Doro pediu. Cada peça responde a um trabalho real.',
        }}
    elseif id == 'registroOficina' then
        return {title = 'REGISTRO DE TRABALHO', voice = 'inscription', lines = {
            'Encomendas antigas, nomes riscados, pagamentos em crédito.',
            'Uma anotação sem data: "fivela que abre com uma mão — L."',
        }}
    elseif id == 'oficinaCentral' then
        return {title = 'OFICINA CENTRAL', voice = 'inscription', lines = {
            'O pátio do trabalho. Toda peça, ferramenta e passagem passa por aqui.',
            'E por Janda — ela fez questão que fosse assim.',
        }}
    -- Hotspots propostos do Mercado (ids prontos para o level-design):
    elseif id == 'recibo' then
        -- Inspeção pura: examinar nunca abre confronto (QA_MUNDOS).
        campaign.data.flags.reciboEma = true
        campaign:giveItem('reciboEma')
        return {title = 'RECIBO DE PEÇAS', voice = 'inscription', lines = {
            'Chapa e dobradiças, pagas por Ema. Assinatura e data legíveis.',
            'Por cima, a etiqueta de Rute: "LOTE SOB AVALIAÇÃO".',
        }}
    elseif id == 'bancaCasal' then
        campaign.data.flags.lembrancaPlaca = true
        if campaign:flag('encomendaBrina') then campaign:completeStep('P03-E03') end
        return {title = 'BANCA ANTIGA', voice = 'inscription', lines = {
            'O encaixe da placa é seu trabalho. Você lembra da discussão — e de quem vencia.',
            'A placa está torta na terceira posição. A discussão virou trabalho conjunto.',
        }}
    elseif id == 'arquivo' then
        campaign.data.flags.encomendaBrina = true
        if done(campaign, 'BR01') then campaign:completeStep('BR02') end
        if campaign:flag('lembrancaPlaca') then campaign:completeStep('P03-E03') end
        return {title = 'ARQUIVO DE ENCOMENDAS', voice = 'inscription', lines = {
            'Fichário de pedidos da feira boa. O cheiro é de papel e ferrugem.',
            'Uma folha com a assinatura original de Brina — autoria em papel.',
        }}
    elseif id == 'placaEma' then
        return {title = 'PLACA COBERTA', voice = 'inscription', lines = {
            'O nome do patrão por baixo do pano. Nenhum nome por cima. Ainda.',
            'O bruto cobrador da esquina já cobrou essa placa duas vezes.',
        }}
    elseif id == 'pecas' then
        campaign.data.flags.conjuntoCozinha = true
        if campaign:flag('carroMovido') then campaign:completeStep('P03-E05') end
        return {title = 'PEÇAS DO FORNO', voice = 'inscription', lines = {
            'Chapa e dobradiças: o forno volta a ser justo com o pão.',
            'O conjunto que Bento precisa — e que Rute avaliou sem perguntar.',
        }}
    elseif id == 'carro' then
        if campaign:flag('carroMovido') then
            return {title = 'CARRO DE PEÇAS', voice = 'inscription', lines = {
                'O carro ficou no canto. A rota dos Salões segue aberta atrás dele.',
            }}
        end
        return {title = 'CARRO DE PEÇAS', voice = 'inscription', lines = {
            'Atravessado na rota dos Salões. Pesado, mas move.',
        }, options = {
            {label = 'MOVER O CARRO', action = function(c)
                c.data.flags.carroMovido = true
                c.data.flags.passagemSaloes = true
                if c:flag('conjuntoCozinha') then c:completeStep('P03-E05') end
                return swap(c, {title = 'CARRO DE PEÇAS', voice = 'inscription', lines = {
                    'O carro cede um palmo de cada vez. A rota dos Salões existe atrás dele.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'DEIXAR'},
        }}
    -- Hotspots propostos do Reservatório (ids prontos para o level-design):
    elseif id == 'residuo' then
        return {title = 'RESÍDUO DE RITO', voice = 'inscription', lines = {
            'Marcas antigas nas pedras do canal. A água passou por aqui durante o rito.',
            'Ela ainda corre — e carrega gosto de cerimônia até o filtro.',
        }}
    elseif id == 'regua' then
        campaign.data.flags.reguaLida = true
        return {title = 'RÉGUA DE NÍVEL', voice = 'inscription', lines = {
            'Marcas de nível escavadas na parede. A mais alta tem nome: IVO.',
            'Ele confia mais nela que em gente. Talvez com razão.',
        }}
    elseif id == 'esquema' then
        campaign.data.flags.esquemaLido = true
        campaign:giveItem('esquemaCanal')
        return {title = 'ESQUEMA DO TRAÇADO', voice = 'inscription', lines = {
            'O canal principal deságua na câmara; o ramo de teste isola antes.',
            'Anotação na margem: "provar antes de abrir — sempre".',
        }}
    elseif id == 'canteiros' then
        return {title = 'CANTEIROS', voice = 'inscription', lines = {
            'Comida crescendo na beira da água. Mara rega o que a interdição permite.',
        }}
    elseif id == 'bancoCasal' then
        campaign.data.flags.lembrancaBanco = true
        if campaign:flag('placaLida') then campaign:completeStep('P04-E03') end
        return {title = 'BANCO DO CASAL', voice = 'inscription', lines = {
            'Aqui eles mediam a água e discutiam preço. O banco lembra dos dois.',
            'Lia sempre ganhava a discussão — e vocês sentavam pra ver o canal.',
        }}
    elseif id == 'placaAlojamentos' then
        campaign.data.flags.placaLida = true
        if campaign:flag('lembrancaBanco') then campaign:completeStep('P04-E03') end
        return {title = 'PLACA DOS ALOJAMENTOS', voice = 'inscription', lines = {
            'ALOJAMENTOS DO TURNO — a seta aponta para salas que viraram aquário.',
            'Onde morou gente que só queria ficar viva até a próxima maré.',
        }}
    elseif id == 'interdicao' then
        campaign.data.flags.interdicaoVista = true
        maybeM4E02(campaign)
        return {title = 'INTERDIÇÃO', voice = 'inscription', lines = {
            'INTERDITADO — RISCO DE INUNDAÇÃO REAL. Assinado: IVO.',
            'A letra é firme, o aviso é sério — e a data é da semana passada.',
        }}
    elseif id == 'canalTeste' then
        if campaign:flag('canalTestado') then
            return {title = 'CANAL DE TESTE', voice = 'inscription', lines = {
                'O ramo isolado segura. O desvio funciona — com gente olhando.',
            }}
        end
        return {title = 'CANAL DE TESTE', voice = 'inscription', lines = {
            'O ramo que o esquema isola antes da câmara. Testar não abre a comporta.',
        }, options = {
            {label = 'TESTAR O DESVIO', action = function(c)
                c.data.flags.canalTestado = true
                c:completeStep('P04-E04')
                return swap(c, {title = 'CANAL DE TESTE', voice = 'inscription', lines = {
                    'A água corre pelo ramo e para onde devia. O desvio funciona.',
                    'A prova que Ivo pede existe — e não foi promessa.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'DEIXAR'},
        }}
    elseif id == 'volante' then
        if ivoResolvido(campaign) then
            return {title = 'VOLANTE DA COMPORTA', voice = 'inscription', lines = {
                'A comporta aberta deixa a água seguir pro filtro.',
            }}
        end
        if campaign:flag('esquemaLido') then
            return {title = 'VOLANTE DA COMPORTA', voice = 'inscription', lines = {
                'Travado pela interdição. O esquema mostra qual ramo abre a câmara isolada.',
            }, options = {
                {label = 'ABRIR COM O ESQUEMA', action = function(c)
                    c.data.flags.comportaAberta = true
                    c:completeStep('P04-E05')
                    return swap(c, {title = 'VOLANTE DA COMPORTA', voice = 'inscription', lines = {
                        'O volante cede devagar. A câmara enche pelo ramo isolado.',
                        'Sem ninguém pra operar junto — o esquema operou por ele.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'DEIXAR'},
            }}
        end
        return {title = 'VOLANTE DA COMPORTA', voice = 'inscription', lines = {
            'Travado pela interdição. Sem o traçado, girar aqui é girar no escuro.',
        }}
    elseif id == 'filtro' then
        campaign.data.flags.filtroColetado = true
        return {title = 'FILTRO DE PEDRA', voice = 'inscription', lines = {
            'Pedra porosa e carvão — o que a cisterna do refúgio precisa.',
            'O pedido de Sabela, inteiro e pesado como deveria.',
        }}
    -- Hotspots propostos dos Salões (ids prontos para o level-design):
    elseif id == 'programa' then
        return {title = 'PROGRAMA', voice = 'inscription', lines = {
            'A ÚLTIMA NOITE PERFEITA — data de abertura: há sete anos.',
            'O cartaz promete bis. Ninguém perguntou se havia primeiro ato.',
        }}
    elseif id == 'laudo' then
        campaign.data.flags.laudoLido = true
        campaign:giveItem('laudo')
        return {title = 'LAUDO ESTRUTURAL', voice = 'inscription', lines = {
            'Trinca no arco principal, classificada "aceitável". Assinatura: B.',
            'A margem tem a letra de outra pessoa: "aceitável para quem?".',
        }}
    elseif id == 'cortina' then
        campaign.data.flags.danoVisto = true
        return {title = 'ATRÁS DA CORTINA', voice = 'inscription', lines = {
            'O dano que o programa omite: viga lascada, escoras remendadas.',
            'Beltran escondeu com teatro o que esconderia com parede.',
        }}
    elseif id == 'armarioTecnico' then
        campaign.data.flags.ferragensVistas = true
        return {title = 'ARMÁRIO TÉCNICO', voice = 'inscription', lines = {
            'Ferragens, contrapesos e talhas — pesadas demais pra quebrar em briga.',
            'Útil pra obra, inútil pra arena. Como deveria ser.',
        }}
    elseif id == 'moldura' then
        campaign.data.flags.lembrancaMoldura = true
        if campaign:flag('fundacaoLocalizada') then campaign:completeStep('P05-E03') end
        return {title = 'MOLDURA TORTA', voice = 'inscription', lines = {
            'A moldura que o casal brigou pra pendurar — torta até hoje.',
            'Vocês fizeram as pazes embaixo dela. Ninguém mais endireitou.',
        }}
    elseif id == 'fundacao' then
        campaign.data.flags.fundacaoLocalizada = true
        if campaign:flag('lembrancaMoldura') then campaign:completeStep('P05-E03') end
        return {title = 'PLANTA DOS SALÕES', voice = 'inscription', lines = {
            'Sob o palco, o alicerce. Uma marca antiga: a Fundação, a Primeira Tumba.',
            'A casa de vocês está por cima dela — literalmente.',
        }}
    elseif id == 'escora' then
        if campaign:flag('escoraReforcada') then
            return {title = 'ESCORA DA FUNDAÇÃO', voice = 'inscription', lines = {
                'Reforçada: a descida pra Fundação aguenta passagem.',
            }}
        end
        return {title = 'ESCORA DA FUNDAÇÃO', voice = 'inscription', lines = {
            'A escora que trava a descida. Com ferramenta boa, reforça.',
        }, options = {
            {label = 'REFORÇAR A ESCORA', action = function(c)
                c.data.flags.escoraReforcada = true
                return swap(c, {title = 'ESCORA DA FUNDAÇÃO', voice = 'inscription', lines = {
                    'Madeira nova sobre a velha. A descida aguenta gente agora.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'DEIXAR'},
        }}
    elseif id == 'ensaio' then
        if campaign:flag('ensaioFeito') then
            return {title = 'SAÍDA DE ENSAIO', voice = 'inscription', lines = {
                'A rota de saída ensaiada aguenta plateia inteira.',
            }}
        end
        return {title = 'SAÍDA DE ENSAIO', voice = 'inscription', lines = {
            'A saída lateral existe — sem plateia pra ensaiar a fuga.',
        }, options = {
            {label = 'CORRER O ENSAIO', action = function(c)
                c.data.flags.ensaioFeito = true
                c.data.flags.rotaPreparada = true
                c:completeStep('P05-E04')
                return swap(c, {title = 'SAÍDA DE ENSAIO', voice = 'inscription', lines = {
                    'Você corre o caminho inteiro: porta, escada, corredor. Aguenta.',
                    'A prova que Beltran precisa — uma saída que existe de verdade.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'DEIXAR'},
        }}
    elseif id == 'divisorias' then
        campaign.data.flags.divisoriasColetadas = true
        return {title = 'DIVISÓRIAS DE VITRINE', voice = 'inscription', lines = {
            'Vidro fosco e madeira boa: luxo que vira parede de dormitório.',
            'O pedido de Teca — e um plano de instalação fácil de levar.',
        }}
    elseif id == 'instrumento' then
        campaign.data.flags.instrumentoVisto = true
        return {title = 'INSTRUMENTO DE PALCO', voice = 'inscription', lines = {
            'Cordas oxidadas, corpo inteiro. Alguém afinava isso pra plateia.',
            'Nilo ia babar nessa caixa de som.',
        }}
    elseif id == 'fundacaoLimite' then
        return LoreC.fundacaoLimite
    elseif id == 'placaFundacao' then
        -- Placa de rota nos dois acessos: o texto é o use->notify do
        -- próprio spot (região); devolver nil evita o diálogo '...' após
        -- o aviso. Some quando 'passagemFundacao' abre.
        return nil
    -- Ambientação do hub: as passagens falam quem são; a placa central dá
    -- a identidade da casa. Ids propostos para o Pátio posicionar junto
    -- aos portais e ao hall.
    elseif id == 'placaHub' then
        return {title = 'PLACA DO REFÚGIO', voice = 'inscription', lines = {
            'A CASA ACOLHE QUEM A TERRA DEVOLVEU.',
            'Em letra menor, de outra mão: — e quem ela segurou.',
        }}
    elseif id == 'portalOficinas' then
        return {title = 'PASSAGEM LESTE', voice = 'inscription', lines = {
            'OFICINAS DE DENTRO. Cheiro de serragem e turno que não termina.',
            'A casa conhece quem passa — e aponta pra onde.',
        }}
    elseif id == 'portalMercado' then
        return {title = 'PASSAGEM OESTE', voice = 'inscription', lines = {
            'MERCADO DAS ESCORAS. Eco de feira que não fechou.',
        }}
    elseif id == 'portalReservatorio' then
        return {title = 'PASSAGEM ÚMIDA', voice = 'inscription', lines = {
            'RESERVATÓRIO DE BAIXO. A água corre lá embaixo — e lembra do rito.',
        }}
    elseif id == 'portalSaloes' then
        return {title = 'PASSAGEM DAS VITRINES', voice = 'inscription', lines = {
            'SALÕES DAS VITRINES. A última noite ainda espera plateia.',
        }}
    elseif id == 'hallPassagens' then
        return {title = 'SALA DAS PASSAGENS', voice = 'inscription', lines = {
            'A sala respira. Cada porta tem nome — e a casa conhece quem passa.',
        }}
    -- Detalhes por região (lore existente, nada novo): recompensam olhar.
    elseif id == 'bancoVelorio' then
        return {title = 'BANCO DO VELÓRIO', voice = 'inscription', lines = {
            'Depois do seu enterro, virou banco de quem descansa.',
        }}
    elseif id == 'jornalTurno' then
        return {title = 'QUADRO DE PRODUÇÃO', voice = 'inscription', lines = {
            'A semana que não chegou. O giz parou no meio da soma.',
        }}
    elseif id == 'torno' then
        return {title = 'TORNO', voice = 'inscription', lines = {
            'A peça pela metade. Alguém vai terminar — ou ninguém vai.',
        }}
    elseif id == 'toldo' then
        return {title = 'TOLDO REMENDADO', voice = 'inscription', lines = {
            'Três remendos. Cada um é uma discussão que o casal teve.',
        }}
    elseif id == 'musgo' then
        return {title = 'MUSGO NAS JUNÇÕES', voice = 'inscription', lines = {
            'A água insiste em lembrar o caminho que tomou durante o rito.',
        }}
    elseif id == 'cartaz' then
        return {title = 'CARTAZ', voice = 'inscription', lines = {
            'NOITE DE REABERTURA — EM BREVE. A tinta já é nostálgica.',
        }}
    elseif id == 'cadeira' then
        return {title = 'CADEIRA DE PALCO', voice = 'inscription', lines = {
            'O assento gasto de quem esperava a cortina subir.',
        }}
    end
    return {title = ' ', voice = 'inscription', lines = {'...'}}
end

-- Narração de revisita à Colina (P01-E04 concluído): substitui a abertura
-- sem repetir a cena. Gancho proposto: Campaign:enter('colina') com E04
-- feita e flag 'colinaRevisit' ausente — marcar a flag ao exibir.
LoreC.colinaRevisit = {
    title = LoreC.titles.narration, voice = 'inscription', mood = 'soft',
    lines = {
        'A Colina segue quieta. O banco do velório virou banco de quem descansa.',
        'Sua cova continua aberta — agora é só uma cova.',
    },
}

-- Comentário de morte/retorno (P01-E04). Se Doro ainda estiver na Colina,
-- a fala é dele; depois da mudança para o hub, vira narração. Gancho
-- proposto: chamar em Campaign:die ao reaparecer na sepultura.
function LoreC.deathReturn(campaign)
    local doro = campaign.data.people.doro or {}
    if doro.location == 'colina' then
        return {title = 'DORO', voice = 'doro', mood = 'soft', lines = {
            'Você caiu lá embaixo e voltou andando. A casa devolve.',
            'Da próxima vez, tenta não precisar. A sopa esfria.',
        }}
    end
    return {title = LoreC.titles.narration, voice = 'inscription', mood = 'dark', lines = {
        'A cova recebe você de novo — e devolve de novo.',
        'Nada foi desfeito. Só você precisou se juntar de volta.',
    }}
end

-- Limite do recorte: o vestíbulo da Fundação é onde os cinco mundos
-- terminam — a Primeira Tumba fica além do que esta entrega alcança.
-- Fecha a região stub sem fingir conteúdo: promessa de continuação,
-- não conteúdo jogável. O Pátio liga como hotspot 'fundacaoLimite' (ou
-- enter da região 'fundacao' — mesma narração).
LoreC.fundacaoLimite = {
    title = LoreC.titles.narration, voice = 'inscription', mood = 'dark',
    lines = {
        'Os degraus descem além do que a vista alcança.',
        'O ar que sobe é antigo — e sabe o seu nome.',
        'A marca na parede é a mesma da sua lápide.',
        'Esta é a borda do que a casa deixa você ver.',
        'O resto é outra história — e ainda não é a hora dela.',
        'Você volta. O que ficou por resolver continua lá em cima.',
    },
}

-- INTRO EM QUADROS (PROPOSTA para o Traço): cutscene de abertura, seis
-- quadros até o objetivo acionável. `art` é chave de cena sugerida para o
-- renderer/pixel_scene; `lines` roda na voz 'inscription'. O node LoreC.intro
-- existente continua como fallback textual se a cutscene não entrar.
LoreC.introCutscene = {
    {art = 'caixao', lines = {'Escuro. Terra. A tampa por cima de você.'}},
    {art = 'marca', lines = {'Na parede, a marca que a casa prega nos que guarda.'}},
    {art = 'cova', lines = {'A tampa cedeu por dentro. Você saiu — sete anos depois.'}},
    {art = 'viajante', lines = {'De pé sobre a própria sepultura. O mesmo arco, o mesmo corpo — sete anos mais tarde.'}},
    {art = 'colina', lines = {'A Colina dos Sepultados: fileiras de lápides sobre a cidade que te enterrou.'}},
    {art = 'grade', lines = {'A grade ao sul desce para o Refúgio — a casa dos que ficaram.'}},
    {art = 'refugio', lines = {'Desça. Diga seu nome. Decida o que fazer com os sete anos.'}},
}

-- CUTSCENES CURTAS por evento (PROPOSTA): beats que merecem pausa sem
-- virarem diálogo. Os mapa Talks resolvem o resto — primeira fala da Runa,
-- das juntas e dos chefes continuam como diálogo normal.
LoreC.cutscenes = {
    passagemOficinas = {lines = {
        'A passagem leste responde. Cheiro de serragem e turno parado.',
        'As Oficinas de Dentro ficam por aqui — o conjunto que Doro pediu, também.',
    }},
    passagemMercado = {lines = {
        'A passagem oeste responde. Eco de feira que não fechou.',
        'O Mercado das Escoras fica por aqui — as peças do forno, também.',
    }},
    passagemReservatorio = {lines = {
        'A passagem úmida responde. A água ainda corre lá embaixo.',
        'O Reservatório de Baixo fica por aqui — o filtro da cisterna, também.',
    }},
    passagemSaloes = {lines = {
        'A rota dos Salões abriu. A última noite ainda espera plateia.',
        'As vitrines que Teca precisa ficam por aqui — e o resto da casa, embaixo.',
    }},
    passagemFundacao = {lines = {
        'A escora aguenta. A água deixa passar. Os degraus da Fundação existem.',
        'A Primeira Tumba espera no fim deles — quando a hora chegar.',
    }},
}

-- MAPA EMOÇÃO×KIND (contrato do Traço — elenco expressivo): vocabulário de
-- retrato por personagem. Base do faceDraw: neutral/joy/fear/anger;
-- propostas extras caem em fallback 'neutral' até implementadas.
--   Vocabulário: neutral, joy, sad, stern, soft, fear, anger, shame, awe.
--   Campo de diálogo: node.expr — aplica ao falante do node (o renderer
--   lê node.expr ou cai em 'neutral'); options podem carregar expr no node
--   de resposta (swap). Linhas são strings — a emoção muda por node, não
--   por linha.
LoreC.exprDefault = 'neutral'
LoreC.expr = {
    -- hub
    aurel  = {'neutral', 'stern', 'sad'},          -- anfitrião: firme, pesa a casa
    doro   = {'neutral', 'joy', 'stern'},          -- ferreiro: grosso por fora
    teca   = {'neutral', 'joy', 'soft'},           -- alojamento: acolhe
    bento  = {'neutral', 'joy', 'shame', 'fear'},  -- cozinha: a confissão mora aqui
    sabela = {'neutral', 'sad', 'soft'},           -- capela: culpa antiga
    nilo   = {'neutral', 'joy', 'awe'},            -- menino dos atalhos
    runa   = {'neutral', 'stern', 'sad'},          -- vigia: a grade dela furou
    -- oficinas
    brina  = {'neutral', 'stern', 'joy'},          -- qualidade antes de simpatia
    neco   = {'neutral', 'soft', 'sad'},           -- cansado, ainda acredita
    janda  = {'neutral', 'stern', 'fear'},         -- a rota que ela não confere
    traba  = {'neutral', 'sad'}, trabb = {'neutral', 'sad'}, -- alojamento
    -- mercado
    ema    = {'neutral', 'joy', 'sad'},            -- comerciante que conhece o casal
    rute   = {'neutral', 'stern', 'shame'},        -- avaliadora: o recibo a desarma
    guarda = {'neutral', 'stern'}, feirante = {'neutral', 'joy'},
    -- reservatório
    mara   = {'neutral', 'soft', 'sad'},           -- jardim: conheceu o casal
    ivo    = {'neutral', 'stern', 'fear'},         -- operador assombrado pela água
    voz    = {'fear', 'sad'},                      -- o outro lado do canal
    equipe = {'neutral', 'stern'},                 -- manutenção na interdição
    -- salões
    beltran= {'neutral', 'stern', 'shame', 'fear'},-- anfitrião do dano ocultado
    cira   = {'neutral', 'joy', 'sad'},            -- artista, colega de Neco
    ajudante = {'neutral', 'joy'},                 -- propõe o duelo de ensaio
    plateia  = {'neutral', 'joy', 'awe'},          -- fora da arena, sempre
}

-- TABELA DE OBJETIVOS (contrato do Traço): uma linha por estado, no formato
-- lugar/pessoa + ação. if-chain por step/flag — segue o estado, nunca a
-- ordem: as missões aceitas podem avançar em qualquer sequência; cada ramo
-- mostra o próximo passo da própria linha. Opcionais ficam no fim, depois
-- da cadeia principal; linha fallback quando nada está aberto.
function LoreC.objective(campaign)
    if campaign:flag('refugioNovo') then return require('src.refugio').objective(campaign) end
    -- Mundo 1: Colina -> Refúgio
    if not done(campaign, 'P01-E02') then
        return 'Colina — pegue seus pertences no depósito a leste do pátio.'
    end
    if not done(campaign, 'P01-E03') then
        return 'Colina — fale com Runa na grade ao sul.'
    end
    if not done(campaign, 'P01-E04') then
        return 'Colina — desça pela grade ao sul até o Refúgio.'
    end
    -- P01-E05: quem falta conhecer, por nome e lugar.
    if not done(campaign, 'P01-E05') then
        if not met(campaign, 'bento') then
            return 'Refúgio — conheça Bento, junto ao depósito.'
        end
        if not met(campaign, 'teca') then
            return 'Refúgio — conheça Teca, junto à bancada.'
        end
        return 'Refúgio — conheça Aurel, na sala das passagens.'
    end
    if not done(campaign, 'P01-E06') then
        return 'Refúgio — Doro e Bento têm pedidos: Oficinas ou Mercado.'
    end
    -- Missões aceitas avançam em qualquer ordem; cada ramo dá o próximo
    -- passo do próprio mundo (primeiro ramo aberto ganha a linha).
    if done(campaign, 'P02-E01') and not campaign:flag('ferramentasEntregues') then
        if not done(campaign, 'P02-E02') then
            return 'Oficinas — conheça Brina e Neco no pátio de trabalho.'
        end
        if not campaign:flag('saidaReforcada') then
            return 'Oficinas — prepare a saída danificada no fundo da oficina.'
        end
        if not done(campaign, 'P02-E04') then
            return 'Oficinas — resolva a questão de Janda na oficina central.'
        end
        if not campaign:flag('conjuntoFerramentas') then
            return 'Oficinas — recolha o conjunto de ferramentas no depósito.'
        end
        return 'Refúgio — entregue o conjunto a Doro na bancada.'
    end
    if done(campaign, 'P03-E01') and not campaign:flag('fornoReparado') then
        if not done(campaign, 'P03-E02') then
            return 'Mercado — fale com Ema no balcão da praça.'
        end
        if not done(campaign, 'P03-E03') then
            return 'Mercado — a banca antiga e o arquivo guardam o que o casal deixou.'
        end
        if not done(campaign, 'P03-E04') then
            return 'Mercado — resolva a disputa com Rute na praça de avaliação.'
        end
        if not campaign:flag('conjuntoCozinha') then
            return 'Mercado — pegue as peças do forno no depósito.'
        end
        if not campaign:flag('carroMovido') then
            return 'Mercado — mova o carro de peças; a rota dos Salões fica atrás.'
        end
        return 'Refúgio — entregue as peças a Bento na cozinha.'
    end
    if done(campaign, 'P04-E01') and not campaign:flag('filtroMontado') then
        if not done(campaign, 'P04-E02') then
            return 'Reservatório — fale com Mara nos canteiros; veja a interdição.'
        end
        if not done(campaign, 'P04-E03') then
            return 'Reservatório — o banco do casal e a placa dos alojamentos contam o resto.'
        end
        if not campaign:flag('canalTestado') then
            return 'Reservatório — teste o desvio no canal de teste.'
        end
        if not done(campaign, 'P04-E05') then
            return 'Reservatório — resolva a interdição com Ivo na sala das comportas.'
        end
        if not campaign:flag('filtroColetado') then
            return 'Reservatório — recolha o filtro de pedra.'
        end
        return 'Refúgio — leve o filtro a Doro; ele monta na cisterna.'
    end
    if done(campaign, 'P05-E01') and not campaign:flag('divisoriasMontadas') then
        if not met(campaign, 'beltran') then
            return 'Salões — fale com Beltran no palco principal.'
        end
        if not done(campaign, 'P05-E03') then
            return 'Salões — a moldura torta e a planta apontam para a Fundação.'
        end
        if not campaign:flag('ensaioFeito') then
            return 'Salões — corra o ensaio na saída lateral do palco.'
        end
        if not done(campaign, 'P05-E05') then
            return 'Salões — resolva o programa de Beltran.'
        end
        if not campaign:flag('divisoriasColetadas') then
            return 'Salões — recolha as divisórias de vitrine.'
        end
        return 'Refúgio — entregue as divisórias à Teca na bancada.'
    end
    -- Opcionais (um de cada vez, depois da cadeia principal).
    if met(campaign, 'doro') and not done(campaign, 'D02') then
        return 'Refúgio — Doro espera uma decisão sobre o caixão-baú.'
    end
    if met(campaign, 'teca') and not done(campaign, 'T01') then
        return 'Refúgio — Teca explica como funciona o alojamento.'
    end
    if done(campaign, 'NE01') and not done(campaign, 'NE03')
        and campaign:flag('necoNoHub') then
        return 'Refúgio — Neco ainda não viu o palco dos Salões.'
    end
    return 'Refúgio — a casa está quieta. Ande, fale, volte.'
end

-- Flags e steps ainda sem emissor (integração pendente nos outros mundos):
--   flag 'pactoRevelado'         -> variante pós-verdade (revelação do mapa 8)
--   flag 'ferramentasEntregues'  -> conjunto do mapa 2 entregue a Doro (D03)
--   flag 'passagemOficinas'      -> saída do hub para Oficinas liberada
--   flag 'passagemMercado'       -> saída do hub para Mercado liberada
--   flag 'fornoReparado'         -> peças do mapa 3 instaladas no forno
--   steps 'D01'..'D03', 'T01'..'T03', 'P02-E01', 'P03-E01', 'P05-E06'
-- Itens emitidos pela lore (catálogo em src/items.lua): 'arco' e
--   'picareta' no hotspot 'pertences' ("o resto do que era seu" — o flag
--   'casaco' permanece, ponte de hasItem documentada em campaign.lua),
--   'reciboEma' em 'recibo', 'esquemaCanal' em 'esquema', 'laudo' em
--   'laudo', 'fivela' na fala da Brina (lembrancaFivela). Cargas de missão
--   seguem flag-only por não constarem no catálogo: conjuntoFerramentas,
--   conjuntoCozinha, filtroColetado, divisoriasColetadas. 'provisao' só
--   sai de loot de encontro — sem emissor de exploração ainda.
-- Os exits oficinas/mercado em hub.lua estão open=false; a integração faz
-- canLeave consultar essas flags (gancho proposto, não implementado aqui).
--
-- MUNDO 2 (Oficinas de Dentro) — steps na notação da ficha, mapeados por
-- analogia a P03/P04/P05 (a ficha 02 não numera etapas):
--   P02-E01 pedido no hub      -> Doro oferece (escrito no bloco A)
--   P02-E02 conhecer conflito  -> maybeE02(): metBrina + metNeco
--   P02-E03 preparar solução   -> flag 'saidaReforcada' (interação no mapa)
--   P02-E04 resolver Janda     -> encounters['B02-01'] = 'won'|'negotiated'
--                                 ou flag 'jandaMorta' (resolução letal)
--   P02-E05 retorno+entrega    -> flag 'conjuntoFerramentas' no depósito;
--                                 Doro no hub consolida 'ferramentasEntregues'
-- Flags novas do mundo 2: conjuntoFerramentas, saidaReforcada,
--   jandaConversa, jandaConfronto, jandaMorta, lembrancaFivela,
--   encomendaBrina (documento do mapa 3), brinaNoHub, necoNoHub,
--   metDoroHub, metBrina, metNeco, metJanda, metTraba, metTrabb,
--   metBrinaHub, niloBancada.
-- Steps de quest: BR01..BR03 (Brina), NE01..NE03 (Neco); BR02 e NE03 cruzam
-- para os mundos 3 e 5 — ganchos documentados nos nodes correspondentes.
--
-- MUNDO 3 (Mercado das Escoras) — steps pela ficha:
--   P03-E01 pedido no hub      -> Bento oferece (bloco A)
--   P03-E02 chegada+direitos   -> primeira conversa de Ema (disputaLote)
--   P03-E03 casal+assinatura   -> flags lembrancaPlaca + encomendaBrina
--   P03-E04 avaliar quem toma  -> encounters['B03-01'] ou flag 'ruteMorta'
--   P03-E05 peças+caminho      -> flags conjuntoCozinha + carroMovido
--   P03-E06 primeira mesa      -> flag fornoReparado (entrega no hub)
-- Constraints QA respeitados: 'recibo' é inspeção pura (nunca abre luta);
-- 'arquivo' dá o doc de Brina sem depender de Ema viva; 'carro' persiste
-- via flag carroMovido e marca 'passagemSaloes'.
-- Flags novas do mundo 3: disputaLote, reciboEma, lembrancaPlaca,
--   conjuntoCozinha, carroMovido, passagemSaloes, guardaLiberada,
--   guardaConfronto, ruteConfronto, ruteRegistros, ruteMorta, emaMorta,
--   mesaConvidados, emaAcolhida, metRute, metEma, metGuarda, metFeirante,
--   metEmaHub.
-- Steps de quest: EM01..EM03 (Ema, Nome na fachada), BM01..BM03 (Bento,
-- Mesa para todos — BM03 pede confissão pública, gated em pactoRevelado).
--
-- MUNDO 4 (Reservatório de Baixo) — steps pela ficha:
--   P04-E01 pedido no hub      -> Sabela oferece; gate exige
--                                ferramentasEntregues + saidaReforcada
--                                (ferramenta + traçado, não "visitou M2")
--   P04-E02 jardim+interdição  -> metMara + flag interdicaoVista
--   P04-E03 banco+placa        -> flags lembrancaBanco + placaLida
--   P04-E04 canal de teste     -> flag canalTestado (testar nunca abre luta)
--   P04-E05 comporta/Ivo       -> encounters['B04-01'], flag ivoMorta,
--                                ou objeto: comportaAberta via esquema
--   P04-E06 filtro no hub      -> flag filtroMontado (Doro monta na cisterna)
-- Constraints QA: C04-02 passa por esquema sem arena; Ivo morto garante
-- fim por esquema+volante; C04-Q01 (rastejantes nos canteiros) é aviso
-- opcional da Mara, documentado como flag maraAviso.
-- Flags novas do mundo 4: passagemReservatorio, interdicaoVista,
--   lembrancaBanco, placaLida, reguaLida, esquemaLido, canalTestado,
--   comportaAberta, filtroColetado, filtroMontado, equipeLiberada,
--   equipeConfronto, ivoConversa, ivoConfronto, ivoMorta, maraAviso,
--   metIvo, metMara, metVoz, metEquipe, niloFiltro.
-- Steps de quest: SB01..SB03 (Sabela, Fora do comando; SB03 cruza p/ o
-- mundo 6 — gancho documentado), NL01..NL03 (Nilo, Barulho na oficina;
-- NL01 = niloBancada do mundo 2, NL02 = filtro, NL03 = instrumento próprio).
--
-- MUNDO 5 (Salões das Vitrines) — steps pela ficha:
--   P05-E01 pedido no hub      -> Teca oferece (divisórias do alojamento)
--   P05-E02 convite Beltran    -> metBeltran
--   P05-E03 moldura+Fundação   -> flags lembrancaMoldura + fundacaoLocalizada
--   P05-E04 ensaio de saída    -> flag ensaioFeito (dano ocultado visto)
--   P05-E05 Beltran            -> encounters['B05-01'] ou flag beltranMorta
--   P05-E06 divisórias+noite   -> flag divisoriasMontadas (entrega à Teca)
-- Constraints QA: 'ajudante' propõe o duelo C05-Q1 SEM desfecho letal
-- (contexto 'duelo' nonLethal nos barks); plateia é só diálogo (fora da
-- arena); 'armarioTecnico' marca ferragens indestrutíveis por combate;
-- Teca ausente: hotspot 'divisorias' já resolve o plano de instalação.
-- Flags novas do mundo 5: lembrancaMoldura, fundacaoLocalizada, laudoLido,
--   danoVisto, ferragensVistas, ensaioFeito, rotaPreparada, escoraReforcada,
--   divisoriasColetadas, divisoriasMontadas, beltranConversa, beltranConfronto,
--   beltranMorta, dueloProposto, necoNoSalao, instrumentoVisto, metBeltran,
--   metCira, metAjudante, metPlateia.
-- Gate do mundo 6 (proposta): passagem p/ a Fundação exige conjunto —
--   filtroMontado (drenagem M4) + escoraReforcada (escora M5). A flag
--   'passagemFundacao' fica para a integração sequenciada.
-- NE03 fecha o arco do Neco do mundo 2 (visita ao palco de Cira); T03 se
-- completa na entrega das divisórias (o gancho já existe em hubTalks.teca).

local talks = {}

talks.doro = function(campaign)
    mark(campaign, 'doro')
    if not campaign:flag('metDoroFirst') then
        campaign.data.flags.metDoroFirst = true
        return {title = 'DORO', voice = 'doro', lines = {
            'Você está de pé. A tampa cedeu e eu... pensei que fosse só a pedra cedendo.',
            'Eu troquei o encaixe rachado da sua cova hoje de manhã. Foi isso que abriu. Desculpa.',
            'Sou Doro. Cuido das sepulturas daqui — e dos reparos, quando deixam.',
        }, options = {
            {label = 'EU ESTAVA AÍ DENTRO?', lines = {
                'Sete anos. A casa inteira jurou que era pra sempre.',
                'Pega suas coisas no depósito antes de descer. É a porta do leste, depois do pátio.',
            }},
            {label = 'O QUE É ESTE LUGAR?', lines = {
                'Colina dos Sepultados. Em cima ficam os que a cidade guardou.',
                'Embaixo ficam os que ficaram. O refúgio é pela grade ao sul — Runa vigia.',
            }},
            {label = 'SAIR'},
        }}
    end
    -- Comentário único de retorno da morte (ficha P01-E04); a versão de
    -- narração para quando ele já está no hub vive em LoreC.deathReturn.
    if (campaign.data.deaths or 0) > 0 and not campaign:flag('doroDeathSeen') then
        campaign.data.flags.doroDeathSeen = true
        return {title = 'DORO', voice = 'doro', mood = 'soft', lines = {
            'Você caiu lá embaixo e voltou andando. A casa devolve.',
            'Da próxima vez, tenta não precisar. A sopa esfria.',
        }, options = {{label = 'SAIR'}}}
    end
    if not done(campaign, 'P01-E02') then
        return {title = 'DORO', voice = 'doro', lines = {
            'Seus pertences estão no depósito, no leste do pátio.',
            'Desce pela grade quando estiver pronto. Vou na frente avisar a casa.',
        }, options = {{label = 'SAIR'}}}
    end
    if not done(campaign, 'P01-E03') then
        return {title = 'DORO', voice = 'doro', lines = {
            'A grade é da Runa. Ela vigia a descida — e nunca viu um morto voltar.',
            'Responde o que ela perguntar. Ela cobra resposta, não obediência.',
        }, options = {
            {label = 'E O CAIXÃO QUE SOBROU?', action = function(c)
                c:completeStep('D01')
                return swap(c, {title = 'DORO', voice = 'doro', lines = {
                    'Seu baú. Você resolveu mudar o serviço.',
                    'A tampa empenou, mas a caixa tá inteira. Guardo no depósito até decidirmos onde ela mora.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    return {title = 'DORO', voice = 'doro', lines = {
        'Grade aberta. O refúgio é embaixo — vou descer na frente avisar a casa.',
    }, options = {{label = 'SAIR'}}}
end

talks.runa = function(campaign)
    mark(campaign, 'runa')
    if done(campaign, 'P01-E03') then
        return {title = 'RUNA', voice = 'runa', lines = {
            'A grade fica erguida. Desce. Doro já deve ter espalhado a novidade.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'RUNA', voice = 'runa', mood = 'tense', lines = {
        'Alto. Minha grade, minhas regras.',
        'A vedação dessa cova era serviço meu — e alguém a rompeu essa noite.',
        'Me diz quem rompeu, e aí eu decido se um morto acordado passa.',
    }, options = {
        {label = 'FUI EU. SAÍ DA MINHA COVA.', action = function(c)
            c:openGrade('confessou')
            return swap(c, {title = 'RUNA', voice = 'runa', lines = {
                'Da própria cova. Diz isso olhando nos meus olhos.',
                'Tá. A casa deixou você sair — a casa responde por você. Passa.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'DORO ROMPEU, NUM REPARO', action = function(c)
            c:openGrade('doro')
            return swap(c, {title = 'RUNA', voice = 'runa', lines = {
                'O pedreiro. Sempre remendando pedra que não devia.',
                'Se a vedação cedeu sozinha, o morto não tem culpa. Passa.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'AINDA NÃO', lines = {
            'Então fica aí do outro lado até lembrar. A grade não tem pressa.',
        }},
        {label = 'DEMONSTRAR CAPACIDADE.', action = function(c)
            c.data.flags.runaConfronto = true
            return swap(c, {title = 'RUNA', voice = 'runa', lines = {
                'Prova é resposta legítima. Aceito.',
                'Me mostra do que teu arco é capaz — a grade decide depois.',
            }, options = {{label = 'SAIR'}}})
        end},
    }}
end

local hubTalks = {
    bento = function(campaign)
        mark(campaign, 'bento')
        maybeE05(campaign)
        if not campaign:flag('metBento') then
            campaign.data.flags.metBento = true
            return {title = 'BENTO', voice = 'bento', lines = {
                'Ah. Você acordou. Que... bom. É. Bom.',
                'Bento. Eu cuido do depósito — e da escola, quando o Nilo deixa.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('bentoPosVerdade') then
            campaign.data.flags.bentoPosVerdade = true
            return {title = 'BENTO', voice = 'bento', lines = {
                'O que eu disse continua de pé. A mesa também — você decide o que faz com as duas.',
            }, options = {{label = 'SAIR'}}}
        end
        -- P03-E06: a entrega das peças conserta o forno; a mesa oferece
        -- lugar sem exigir permanência nem perdão.
        if campaign:flag('conjuntoCozinha') and not campaign:flag('fornoReparado') then
            campaign.data.flags.fornoReparado = true
            campaign:completeStep('P03-E06')
            return {title = 'BENTO', voice = 'bento', lines = {
                'Chapa nova. O forno volta a ser justo com o pão.',
                'Guardei um lugar.',
            }, options = {
                {label = 'EU NÃO DISSE QUE FICAVA.', lines = {
                    'A cadeira aguenta uma refeição só. Depois você decide.',
                }},
                {label = 'SAIR'}}}
        end
        -- BM (Mesa para todos): de decidir sozinho a prestar contas. BM03
        -- pede confissão pública e entrega efetiva dos estoques — gated na
        -- revelação; cozinhar nunca completa reparação.
        if done(campaign, 'BM02') and campaign:flag('pactoRevelado') and not done(campaign, 'BM03') then
            return {title = 'BENTO', voice = 'bento', expr = 'fear', mood = 'tense', lines = {
                'A mesa divide pão. A confissão divide a verdade.',
            }, options = {
                {label = 'CONTA EM PÚBLICO O QUE VOCÊ FEZ.', action = function(c)
                    c:completeStep('BM03')
                    return swap(c, {title = 'BENTO', voice = 'bento', expr = 'shame', mood = 'soft', lines = {
                        'Eu disse pra você. Vou dizer de novo — na frente de todos.',
                        'E os estoques deixam de ser meus. A mesa continua; a chave não.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'DEPOIS'},
            }}
        end
        if done(campaign, 'BM01') and campaign:flag('mesaConvidados') and not done(campaign, 'BM02') then
            campaign:completeStep('BM02')
            return {title = 'BENTO', voice = 'bento', lines = {
                'A Ema aceitou a mesa. A fila de porções virou conversa, não ordem.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('fornoReparado') and not done(campaign, 'BM01') then
            return {title = 'BENTO', voice = 'bento', lines = {
                'A mesa encheu de novo. Cada cadeira com um nome.',
            }, options = {
                {label = 'QUEM DECIDE AS PORÇÕES?', action = function(c)
                    c:completeStep('BM01')
                    return swap(c, {title = 'BENTO', voice = 'bento', lines = {
                        'Eu decido. Sempre decidi — e ouvindo assim, soa estranho.',
                        'Tem gente do mercado que podia sentar aqui também. Se alguém convidar.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'},
            }}
        end
        -- P01-E06 / P03-E01: o pedido do forno oferece o destino Mercado.
        if done(campaign, 'P01-E05') and not done(campaign, 'P03-E01') then
            return {title = 'BENTO', voice = 'bento', lines = {
                'O forno cozinha o pão e o cozinheiro junto. A chapa queimou de um lado só.',
                'O Mercado das Escoras tem chapa e dobradiça boas — se a Rute deixar sair.',
            }, options = {
                {label = 'O PÃO SAIU CRU?', lines = {
                    'Só por dentro. Por fora ele já morreu.',
                }},
                {label = 'VOU AO MERCADO', action = function(c)
                    c:completeStep('P03-E01')
                    c:completeStep('P01-E06')
                    c.data.flags.passagemMercado = true
                    c:syncExits()
                    return swap(c, {title = 'BENTO', voice = 'bento', lines = {
                        'Cuidado com a avaliadora: ela chama de acervo o que é dos outros.',
                        'Se a Ema estiver no balcão dela, cumprimenta por mim.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'},
            }}
        end
        if done(campaign, 'P03-E01') and not campaign:flag('fornoReparado') then
            return {title = 'BENTO', voice = 'bento', lines = {
                'A chapa ainda esquenta torto. O mercado fica pela outra passagem.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'BENTO', voice = 'bento', lines = {'Precisa de algo? O depósito está arrumado.'},
            options = {{label = 'SAIR'}}}
    end,
    teca = function(campaign)
        mark(campaign, 'teca')
        maybeE05(campaign)
        if not campaign:flag('metTeca') then
            campaign.data.flags.metTeca = true
            return {title = 'TECA', voice = 'teca', lines = {
                'Morto levantado. Já vi coisa pior nesta casa.',
                'Teca. Ferramenta boa não cai de mão vazia — traz material que a gente conversa.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('tecaPosVerdade') then
            campaign.data.flags.tecaPosVerdade = true
            return {title = 'TECA', voice = 'teca', lines = {
                'Eu tentei impedir aquela noite. Não vou pedir que baste.',
                'Quer saber de alguma coisa, pergunta. Eu estava na casa.',
            }, options = {{label = 'SAIR'}}}
        end
        -- P05-E06: as divisórias chegam e a Teca instala o que o plano
        -- trouxe (ela ausente: o plano do hotspot basta — QA).
        if campaign:flag('divisoriasColetadas') and not campaign:flag('divisoriasMontadas') then
            campaign.data.flags.divisoriasMontadas = true
            campaign:completeStep('P05-E06')
            return {title = 'TECA', voice = 'teca', lines = {
                'Vidro fosco e madeira boa. Vitrine de luxo virando parede de dormitório.',
                'O plano é simples: uma noite de serviço e o alojamento ganha portas.',
            }, options = {{label = 'SAIR'}}}
        end
        -- P05-E01: o pedido das divisórias (rota aberta pelo carro do M3).
        if campaign:flag('passagemSaloes') and not done(campaign, 'P05-E01') then
            return {title = 'TECA', voice = 'teca', lines = {
                'O alojamento tem três camas e zero paredes. Isso precisa mudar.',
                'As vitrines dos Salões eram divisórias de luxo. O carro que abriu a rota passa por lá.',
            }, options = {
                {label = 'EU TRAGO AS DIVISÓRIAS.', action = function(c)
                    c:completeStep('P05-E01')
                    return swap(c, {title = 'TECA', voice = 'teca', lines = {
                        'Traz o que der e o plano de instalação junto. Medida é metade do corte.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'},
            }}
        end
        -- T03 (gancho do mapa 5): com os Salões concluídos, o espaço muda.
        if done(campaign, 'P05-E06') and not done(campaign, 'T03') then
            campaign:completeStep('T03')
            return {title = 'TECA', voice = 'teca', lines = {
                'Você viu o que eles fizeram com o espaço de lá. O daqui ficou melhor: teve ajuda.',
                'A cama tem nome agora. O seu.',
            }, options = {{label = 'SAIR'}}}
        end
        if not done(campaign, 'T01') then
            return {title = 'TECA', voice = 'teca', lines = {
                'Alojamento é o que sobrou do velório coletivo. Três camas, zero paredes.',
            }, options = {
                {label = 'COMO FUNCIONA AQUI?', action = function(c)
                    c:completeStep('T01')
                    return swap(c, {title = 'TECA', voice = 'teca', lines = {
                        'Quem dorme aqui divide mais que cobertor. Respeito é a parede.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'},
            }}
        end
        if not done(campaign, 'T02') then
            return {title = 'TECA', voice = 'teca', lines = {
                'Seus pertences chegaram. A gente decide onde sem expulsar ninguém.',
            }, options = {
                {label = 'DIVIDO PROVISORIAMENTE', action = function(c)
                    c:completeStep('T02')
                    return swap(c, {title = 'TECA', voice = 'teca', lines = {
                        'Justo. A cortina do meio fica pra você.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'QUERO PRIVACIDADE', action = function(c)
                    c:completeStep('T02')
                    return swap(c, {title = 'TECA', voice = 'teca', lines = {
                        'O canto leste tem sombra até de manhã. Eu invento uma parede.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'PREFIRO DISTÂNCIA', action = function(c)
                    c:completeStep('T02')
                    return swap(c, {title = 'TECA', voice = 'teca', lines = {
                        'O remendo é seu. Não é contrato.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'DEPOIS'},
            }}
        end
        return {title = 'TECA', voice = 'teca', lines = {'A bancada não se conserta olhando.'},
            options = {{label = 'SAIR'}}}
    end,
    sabela = function(campaign)
        mark(campaign, 'sabela')
        if not campaign:flag('metSabela') then
            campaign.data.flags.metSabela = true
            return {title = 'SABELA', voice = 'sabela', lines = {
                'Então é verdade. Você voltou.',
                'Sou Sabela. Cuido da capela — e dos que precisam ficar em paz aqui dentro.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('sabelaPosVerdade') then
            campaign.data.flags.sabelaPosVerdade = true
            return {title = 'SABELA', voice = 'sabela', lines = {
                'Tentei abrir uma fuga naquela noite. Falhei — e não vou esconder de novo.',
            }, options = {{label = 'SAIR'}}}
        end
        -- SB (Fora do comando): cuidar por escolha, não por lealdade. SB02
        -- pede contar a tentativa de fuga em público; SB03 cruza p/ mundo 6.
        if done(campaign, 'SB01') and campaign:flag('pactoRevelado') and not done(campaign, 'SB02') then
            return {title = 'SABELA', voice = 'sabela', lines = {
                'A casa sabe o que tentaram fazer com você. Sabe o que EU tentei fazer?',
            }, options = {
                {label = 'CONTA PRA TODOS.', action = function(c)
                    c:completeStep('SB02')
                    return swap(c, {title = 'SABELA', voice = 'sabela', lines = {
                        'Vou contar. A fuga que não abri — e os sete anos cozinhando no lugar de falar.',
                        'Cuidar da cozinha continua sendo escolha. Só que agora, sabida.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'DEPOIS'},
            }}
        end
        if campaign:flag('filtroMontado') and not done(campaign, 'SB01') then
            campaign:completeStep('SB01')
            return {title = 'SABELA', voice = 'sabela', lines = {
                'A água voltou a correr. Você resolveu o que eu não soube resolver naquela noite.',
            }, options = {
                {label = 'O QUE VOCÊ FEZ NAQUELA NOITE?', lines = {
                    'Tentei abrir uma fuga. Falhei — e passei sete anos cozinhando no lugar de falar.',
                }},
                {label = 'SAIR'},
            }}
        end
        -- P04-E01: o pedido da água só abre com ferramenta E traçado (QA:
        -- a rota 4 não é "visitou o mundo 2" — é prova de caminho seguro).
        if done(campaign, 'P02-E05') and campaign:flag('saidaReforcada')
            and not done(campaign, 'P04-E01') then
            return {title = 'SABELA', voice = 'sabela', lines = {
                'A cozinha anda na água da cisterna. Pouca, e apodrece parada.',
                'O reservatório tem filtro de pedra — se a água lá ainda corre segura.',
            }, options = {
                {label = 'EU TRAGO O FILTRO.', action = function(c)
                    c:completeStep('P04-E01')
                    c.data.flags.passagemReservatorio = true
                    c:syncExits()
                    return swap(c, {title = 'SABELA', voice = 'sabela', lines = {
                        'Vai com cuidado. Água parada guarda o que a terra não quis.',
                        'A rota passa pelo caminho que vocês destravaram nas Oficinas.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'},
            }}
        end
        if campaign:flag('filtroMontado') then
            return {title = 'SABELA', voice = 'sabela', lines = {
                'A cisterna corre agora. A cozinha respira — e eu também.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'SABELA', voice = 'sabela', lines = {'A capela está aberta. Sente, se precisar.'},
            options = {{label = 'SAIR'}}}
    end,
    nilo = function(campaign)
        mark(campaign, 'nilo')
        if not campaign:flag('metNilo') then
            campaign.data.flags.metNilo = true
            return {title = 'NILO', voice = 'nilo', lines = {
                'Você é o da cova? Todo mundo falando.',
                'Sou Nilo. Eu sei onde fica cada coisa da casa. Sério. Pergunta.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('niloPosVerdade') then
            campaign.data.flags.niloPosVerdade = true
            return {title = 'NILO', voice = 'nilo', lines = {
                'O pessoal grande fez... aquilo? Eu era criança.',
                'Mas a casa sou eu também. Me deixa ajudar a consertar.',
            }, options = {{label = 'SAIR'}}}
        end
        -- NL03: o instrumento de palco inspira a peça própria dele.
        if campaign:flag('instrumentoVisto') and not done(campaign, 'NL03') then
            campaign:completeStep('NL03')
            return {title = 'NILO', voice = 'nilo', lines = {
                'Você viu um instrumento de PALCO?! O meu vai ser melhor.',
                'Doro disse que eu disse isso em voz alta. É porque é verdade.',
            }, options = {{label = 'SAIR'}}}
        end
        -- NL02 (Barulho na oficina): o filtro cura a água e ensina a peça.
        if campaign:flag('filtroMontado') and not done(campaign, 'NL02') then
            campaign:completeStep('NL02')
            return {title = 'NILO', voice = 'nilo', lines = {
                'Eu segurei o filtro! Segurei. Principalmente olhei.',
                'Madeira curada na água faz som melhor. Já escolhi a minha peça.',
            }, options = {{label = 'SAIR'}}}
        end
        -- NL01: a bancada montada é o começo do arco dele.
        if campaign:flag('ferramentasEntregues') and not campaign:flag('niloBancada') then
            campaign.data.flags.niloBancada = true
            campaign:completeStep('NL01')
            return {title = 'NILO', voice = 'nilo', lines = {
                'A bancada agora é de verdade! Doro deixou eu apertar um parafuso. UM.',
                'Meu instrumento sai daqui. Já escolhi a madeira.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'NILO', voice = 'nilo', lines = {'A casa é grande mas eu sei os atalhos.'},
            options = {
                {label = 'E AS PASSAGENS?', action = function(c)
                    c.data.flags.niloPassagens = true
                    return swap(c, {title = 'NILO', voice = 'nilo', lines = {
                        'Sala do fundo! Cada porta tem nome.',
                        'A leste cheira a serragem. A outra, a feira. A úmida é água. A das vitrines tem plateia.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'}}}
    end,
    aurel = function(campaign)
        mark(campaign, 'aurel')
        maybeE05(campaign)
        if not campaign:flag('metAurel') then
            campaign.data.flags.metAurel = true
            return {title = 'AUREL', voice = 'aurel', expr = 'stern', mood = 'dark', lines = {
                'Você voltou. Eu imaginei este dia por sete anos.',
                'O rito fui eu que fiz. Não vou fingir que não.',
                'O porquê é outra conversa — e não é curta.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('aurelPosVerdade') then
            campaign.data.flags.aurelPosVerdade = true
            return {title = 'AUREL', voice = 'aurel', lines = {
                'A prova saiu dos registros. Minha parte já estava admitida — e continua.',
            }, options = {{label = 'SAIR'}}}
        end
        if done(campaign, 'P01-E05') and not campaign:flag('aurelPassagens') then
            campaign.data.flags.aurelPassagens = true
            return {title = 'AUREL', voice = 'aurel', lines = {
                'As passagens respondem a quem a casa conhece.',
                'Oficinas e Mercado estão identificadas. O resto precisa de caminho — e de motivo.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'AUREL', voice = 'aurel', lines = {'Eu disse o que fiz. O resto tem hora.'},
            options = {{label = 'SAIR'}}}
    end,
    runa = function(campaign)
        mark(campaign, 'runa')
        if (campaign.data.deaths or 0) > 0 and not campaign:flag('runaDeathSeen') then
            campaign.data.flags.runaDeathSeen = true
            return {title = 'RUNA', voice = 'runa', lines = {
                'Soube que você caiu na descida. E voltou.',
                'Isso responde mais que a minha pergunta.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('runaPosVerdade') then
            campaign.data.flags.runaPosVerdade = true
            return {title = 'RUNA', voice = 'runa', lines = {
                'Eu repeti a história que me deram. Incluindo na sua lápide.',
                'Quando a casa decidir a letra certa, eu ajudo a escrever.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'RUNA', voice = 'runa', lines = {
            'Agora vigio as passagens. Porta nova, mesma regra: quem passa me responde.',
        }, options = {{label = 'SAIR'}}}
    end,
    doro = function(campaign)
        mark(campaign, 'doro')
        if campaign:flag('pactoRevelado') and not campaign:flag('doroPosVerdade') then
            campaign.data.flags.doroPosVerdade = true
            return {title = 'DORO', voice = 'doro', lines = {
                'Você já me contou. Quer conferir o registro junto ou quer ir sozinho?',
                'Eu troquei o encaixe sem saber. Agora sei o que a casa guardava — e o que devo.',
            }, options = {{label = 'SAIR'}}}
        end
        -- P02-E05: a entrega do conjunto consolida a bancada (a posse veio do
        -- hotspot 'ferramentas'; aqui ela vira trabalho e agradece sem selo).
        if campaign:flag('conjuntoFerramentas') and not campaign:flag('ferramentasEntregues') then
            campaign.data.flags.ferramentasEntregues = true
            campaign:completeStep('P02-E05')
            return {title = 'DORO', voice = 'doro', lines = {
                'Ferramenta boa, inteira e com cheiro de oficina de verdade.',
                'Senta que a bancada engorda hoje. Você carregou isso até aqui — agora ela te carrega.',
            }, options = {{label = 'SAIR'}}}
        end
        -- P04-E06: Doro monta o filtro na cisterna; a água do refúgio deixa
        -- de apodrecer parada (pedido de Sabela, não selo).
        if campaign:flag('filtroColetado') and not campaign:flag('filtroMontado') then
            campaign.data.flags.filtroMontado = true
            campaign:completeStep('P04-E06')
            return {title = 'DORO', voice = 'doro', lines = {
                'Filtro de pedra e carvão. Vai na cisterna da Sabela.',
                'Água que corre não apodrece ninguém. A casa agradece em silêncio — o meu jeito.',
            }, options = {{label = 'SAIR'}}}
        end
        -- D03 (gancho do mapa 2): ferramentas entregues engordam a bancada.
        if campaign:flag('ferramentasEntregues') and not done(campaign, 'D03') then
            campaign:completeStep('D03')
            return {title = 'DORO', voice = 'doro', lines = {
                'Com ferramenta de verdade, a bancada segura o refúgio inteiro.',
                'E seu baú finalmente tem onde morar — do lado do serviço, como manda.',
            }, options = {{label = 'SAIR'}}}
        end
        -- D02 (auto-cura D01): o caixão-baú ficou na Colina para quem nunca
        -- perguntou — o emissor mora aqui, sempre acessível; a escolha do
        -- lugar resolve os dois passos sem exigir a conversa anterior.
        if not done(campaign, 'D02') then
            local intro = done(campaign, 'D01')
                and 'O caixão-baú desceu comigo. Falta só escolher o lugar dele.'
                or 'Seu caixão desceu comigo — empenado, mas inteiro. Vira baú quando você escolher o lugar.'
            local function place(c, reply)
                c:completeStep('D01')
                c:completeStep('D02')
                return swap(c, {title = 'DORO', voice = 'doro', lines = {reply},
                    options = {{label = 'SAIR'}}})
            end
            return {title = 'DORO', voice = 'doro', lines = {intro}, options = {
                {label = 'PERTO DAS CAMAS', action = function(c)
                    return place(c, 'No dormitório, então. Mão perto, coração longe da porta.')
                end},
                {label = 'JUNTO DA BANCADA', action = function(c)
                    return place(c, 'Do lado do serviço. Ferramenta perto de ferramenta — faz sentido.')
                end},
                {label = 'DEPOIS EU DECIDO'},
            }}
        end
        -- P01-E06 / P02-E01: o pedido da bancada oferece o destino Oficinas.
        if done(campaign, 'P01-E05') and not done(campaign, 'P02-E01') then
            return {title = 'DORO', voice = 'doro', lines = {
                'A casa das passagens já responde. Oficinas de Dentro fica pela passagem leste.',
                'A bancada daqui aguenta remendo; pro que vem depois, preciso de ferramenta boa.',
            }, options = {
                {label = 'ESSA NÃO SERVE?', lines = {
                    'Serve pra eu me machucar de um jeito novo.',
                }},
                {label = 'VOU BUSCAR O CONJUNTO', action = function(c)
                    c:completeStep('P02-E01')
                    c:completeStep('P01-E06')
                    c.data.flags.passagemOficinas = true
                    c:syncExits()
                    return swap(c, {title = 'DORO', voice = 'doro', lines = {
                        'As Oficinas tinham um conjunto inteiro — antes do turno não terminar.',
                        'Se tiver gente lá, ouve primeiro. Nem todo mundo que ficou é pedra.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'},
            }}
        end
        if done(campaign, 'P02-E01') and not campaign:flag('ferramentasEntregues') then
            return {title = 'DORO', voice = 'doro', lines = {
                'O conjunto continua nas Oficinas. A passagem leste te deixa na porta.',
            }, options = {{label = 'SAIR'}}}
        end
        if not campaign:flag('metDoroHub') then
            campaign.data.flags.metDoroHub = true
            return {title = 'DORO', voice = 'doro', lines = {
                'Então. Essa é a casa. Bancada comigo e com a Teca, cozinha com a Sabela.',
                'O resto você conhece andando. As passagens ficam na sala do fundo.',
            }, options = {{label = 'SAIR'}}}
        end
        -- Rota alternativa do D01: quem não perguntou pelo caixão na Colina
        -- ainda o alcança aqui (o prop 'caixao' fica na Colina como exame).
        local options = {{label = 'SAIR'}}
        if not done(campaign, 'D01') then
            table.insert(options, 1, {label = 'E O CAIXÃO QUE SOBROU?', action = function(c)
                c:completeStep('D01')
                return swap(c, {title = 'DORO', voice = 'doro', lines = {
                    'Seu baú. Você resolveu mudar o serviço.',
                    'Desci ele comigo — a tampa empenou, a caixa tá inteira. Escolhe o lugar quando quiser.',
                }, options = {{label = 'SAIR'}}})
            end})
        end
        return {title = 'DORO', voice = 'doro', lines = {'A bancada não pergunta. Só aguenta.'},
            options = options}
    end,
    -- Arcos do mundo 2 quando os moradores migram para o hub.
    brina = function(campaign)
        mark(campaign, 'brina')
        if not campaign:flag('metBrinaHub') then
            campaign.data.flags.metBrinaHub = true
            return {title = 'BRINA', voice = 'brina', lines = {
                'A bancada tem nome agora. O meu — e o de cada peça que sair dela.',
                'A Doro testa a ferramenta antes de agradecer. A gente se entende.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('brinaPosVerdade') then
            campaign.data.flags.brinaPosVerdade = true
            return {title = 'BRINA', voice = 'brina', lines = {
                'Soube o que fizeram com você. Não vou fingir que uma bancada ajuda a perdoar.',
                'O que eu sei fazer é peça: bancada aberta, sem cobrar silêncio.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'BRINA', voice = 'brina', lines = {'Peça boa não se apressa. Nem a conversa boa.'},
            options = {
                {label = 'E A LIA?', lines = {
                    'Opiniosa, impaciente e certeira. O tipo de cliente que estraga cliente.',
                    'Quando achar ela, traz aqui. Preciso cobrar a outra metade — em opinião.',
                }},
                {label = 'SAIR'}}}
    end,
    neco = function(campaign)
        mark(campaign, 'neco')
        -- NE02: instalar-se no hub sem virar funcionário da gratidão.
        if campaign:flag('necoNoHub') and not done(campaign, 'NE02') then
            campaign:completeStep('NE02')
            return {title = 'NECO', voice = 'neco', lines = {
                'Primeiro dia. Olhei a porta umas doze vezes antes de sair.',
                'Reparei a dobradiça, o banco e o depósito. Amanhã descubro o que é descanso.',
            }, options = {{label = 'SAIR'}}}
        end
        -- NE03: o convite ao palco de Cira fecha o arco começado no M2
        -- (o encontro acontece nos Salões; ele volta com a história).
        if campaign:flag('necoNoHub') and campaign:flag('passagemSaloes')
            and not done(campaign, 'NE03') and not campaign:flag('necoNoSalao') then
            return {title = 'NECO', voice = 'neco', lines = {
                'A Cira tá nos Salões, né? Eu consertava o palco dela sem nunca ter visto.',
            }, options = {
                {label = 'VEM VER O PALCO.', action = function(c)
                    c.data.flags.necoNoSalao = true
                    c.data.people.neco.location = 'saloes'
                    return swap(c, {title = 'NECO', voice = 'neco', lines = {
                        'Palco com plateia... eu vou. Se me chamarem pra cenário, finjo que desmaiei.',
                    }, options = {{label = 'SAIR'}}})
                end},
                {label = 'SAIR'},
            }}
        end
        return {title = 'NECO', voice = 'neco', lines = {'Reparei a dobradiça. E a do depósito. E a... você entendeu.'},
            options = {
                {label = 'DESCANSA, NECO.', lines = {
                    'Descanso é serviço que ainda não inventaram nome.',
                }},
                {label = 'SAIR'}}}
    end,
    ema = function(campaign)
        mark(campaign, 'ema')
        if not campaign:flag('metEmaHub') then
            campaign.data.flags.metEmaHub = true
            return {title = 'EMA', voice = 'ema', lines = {
                'Balcão novo, mesma panela azul. A placa do mercado continua minha — a daqui ainda não decidi.',
            }, options = {{label = 'SAIR'}}}
        end
        if campaign:flag('pactoRevelado') and not campaign:flag('emaPosVerdade') then
            campaign.data.flags.emaPosVerdade = true
            return {title = 'EMA', voice = 'ema', lines = {
                'Me contaram o que essa casa fez. O preço da proteção era você.',
                'Eu vendo coisas, não pessoas. Decide o que quer de mim sabendo disso.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'EMA', voice = 'ema', lines = {'O balcão do refúgio tem menos poeira que o da feira. E mais gente.'},
            options = {{label = 'SAIR'}}}
    end,
}

function talks.hub(campaign, id) return hubTalks[id](campaign) end

-- MUNDO 2 — Oficinas de Dentro (docs/mapas/02_OFICINAS.md)
-- Conflito: quem controla ferramentas e rotas decide quem pode partir.
-- Janda é adversária, não autora do crime; a negociação pede prova física
-- (rota segura / decisão dos trabalhadores), nunca elogio. 'B02-01' é o id
-- de encontro proposto para a arena dela — startBattle fica com a
-- integração; os nodes abaixo registram acordo direto quando a rota já foi
-- verificada, conforme a ficha.
local oficinasTalks = {}

oficinasTalks.janda = function(campaign)
    mark(campaign, 'janda')
    if not campaign:flag('metJanda') then
        campaign.data.flags.metJanda = true
        return {title = 'JANDA', voice = 'janda', lines = {
            'Forasteiro de arco. Aqui dentro o arco não decide nada.',
            'Sou Janda. A oficina é minha — e o que sai dela passa por mim primeiro.',
        }, options = {
            {label = 'VIM PELAS FERRAMENTAS.', lines = {
                'Ferramenta minha não sai de graça. O que você oferece?',
                'Trabalho, prova ou conversa boa — nessa ordem.',
            }},
            {label = 'SAIR'},
        }}
    end
    -- Acordo por inspeção: a rota segura precisa existir de verdade antes
    -- da promessa — a ficha exige alteração real do mapa, não persuasão.
    if not jandaResolvida(campaign) then
        local options = {}
        if campaign:flag('saidaReforcada') then
            options[#options + 1] = {label = 'A PASSAGEM ESTÁ ABERTA. PODE OLHAR.', action = function(c)
                c.data.flags.jandaConversa = true
                c:settleEncounter('B02-01', 'negotiated')
                c:completeStep('P02-E04')
                return swap(c, {title = 'JANDA', voice = 'janda', lines = {
                    'Se a saída ceder, quem busca os corpos?',
                    '...Eu vou olhar. E se a régua discordar de você, a conversa acaba.',
                    'Aguenta. A rota existe. Retire o conjunto — e os acordos se escrevem em duas mãos agora.',
                }, options = {{label = 'SAIR'}}})
            end}
        end
        options[#options + 1] = {label = 'OS TRABALHADORES DECIDEM.', action = function(c)
            c.data.flags.jandaConversa = true
            return swap(c, {title = 'JANDA', voice = 'janda', lines = {
                'Pergunta pra eles, então. Mas pergunta direito: quem fica e quem vai.',
                'Se todos responderem a mesma coisa, você nem voltou aqui de verdade.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'ENTÃO VEM BUSCAR.', action = function(c)
            c.data.flags.jandaConfronto = true
            return swap(c, {title = 'JANDA', voice = 'janda', lines = {
                'Finalmente alguém honesto. O martelo decide mais rápido que a conversa.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'SAIR'}
        return {title = 'JANDA', voice = 'janda', lines = {
            'De volta. Trouxe prova ou veio só gastar meu turno?',
        }, options = options}
    end
    if campaign:flag('jandaMorta') then return nil end
    if campaign.data.encounters['B02-01'] == 'negotiated' then
        return {title = 'JANDA', voice = 'janda', lines = {
            'A rota existe. Eu vi com os meus olhos, não com os seus.',
            'Os acordos agora se escrevem em duas mãos. Ainda dói escrever.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'JANDA', voice = 'janda', lines = {
        'Você provou mais forte. O abrigo continua precisando de parede — e eu continuo sabendo levantar.',
    }, options = {{label = 'SAIR'}}}
end

oficinasTalks.brina = function(campaign)
    mark(campaign, 'brina')
    maybeE02(campaign)
    if not campaign:flag('metBrina') then
        campaign.data.flags.metBrina = true
        return {title = 'BRINA', voice = 'brina', lines = {
            'Compra? Não. Primeiro olha. Depois pega. Aí a gente fala de preço.',
            'Sou Brina. Cada peça aqui foi testada até reclamar — inclusive as que vendo mal.',
        }, options = {
            {label = 'ESSA FIVELA É SUA?', action = function(c)
                c.data.flags.lembrancaFivela = true
                c:giveItem('fivela')
                return swap(c, {title = 'BRINA', voice = 'brina', lines = {
                    'Essa é sua. Lia pagou metade adiantado e ficou opinando como se tivesse comprado a oficina.',
                    'Ela pediu que a fivela abrisse com uma mão.',
                }, options = {
                    {label = 'POR CAUSA DO ARCO.', lines = {
                        'Não. Disse que você sempre chegava carregando coisa demais.',
                        'Ela chamava de ajudar. Me ajudou três dias — e cobrou em opinião.',
                    }},
                    {label = 'SAIR'},
                }})
            end},
            {label = 'SAIR'},
        }}
    end
    -- BR01: a quest começa pela pergunta dos nomes (autoria), não por Lia.
    if not done(campaign, 'BR01') then
        return {title = 'BRINA', voice = 'brina', lines = {
            'Ainda de olho nas peças? Bom sinal. Péssimo cliente, bom sinal.',
        }, options = {
            {label = 'POR QUE NOMES DIFERENTES?', action = function(c)
                c:completeStep('BR01')
                return swap(c, {title = 'BRINA', voice = 'brina', lines = {
                    'Mesmo acabamento, nomes diferentes. A Janda vende "estoque". Eu faço peça.',
                    'Quero o meu nome no meu trabalho — e decidir para onde ele vai.',
                    'A encomenda que prova isso tá no arquivo do Mercado das Escoras. Traz ela, ou eu mesma vou um dia.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    -- BR03 (gancho do Mercado): a encomenda encontrada decide o futuro dela.
    if campaign:flag('encomendaBrina') and not done(campaign, 'BR03') then
        return {title = 'BRINA', voice = 'brina', lines = {
            'Você achou. Com assinatura original e tudo — a papelada nunca esteve do lado dela.',
            'Agora eu decido: continuar aqui com autoria, ou levar a bancada pra esse refúgio seu.',
        }, options = {
            {label = 'VEM COMIGO PRO REFÚGIO.', action = function(c)
                c:completeStep('BR03')
                c.data.flags.brinaNoHub = true
                c.data.people.brina.location = 'hub'
                return swap(c, {title = 'BRINA', voice = 'brina', lines = {
                    'Bancada com vista pra comunidade. Aceito — mas as peças continuam sendo minhas.',
                    'Vou na frente. Se a Doro for quem eu imagino, a gente se entende.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'FICA COM AUTORIA AQUI.', action = function(c)
                c:completeStep('BR03')
                return swap(c, {title = 'BRINA', voice = 'brina', lines = {
                    'Aqui, então. Com nome na fachada e condições públicas — escrevo eu mesma os termos.',
                    'Passa quando quiser peça boa. O refúgio continua ganhando desconto de conhecido.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'NÃO É DECISÃO MINHA.', action = function(c)
                c:completeStep('BR03')
                return swap(c, {title = 'BRINA', voice = 'brina', lines = {
                    'Justo. A pergunta continua minha — e a resposta também.',
                }, options = {{label = 'SAIR'}}})
            end},
        }}
    end
    if jandaResolvida(campaign) then
        return {title = 'BRINA', voice = 'brina', lines = {
            'A oficina respira diferente. A Janda ainda conta as ferramentas — só que agora em voz alta.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'BRINA', voice = 'brina', lines = {
        'A encomenda continua no arquivo do mercado. Autoria se prova em papel, infelizmente.',
    }, options = {{label = 'SAIR'}}}
end

oficinasTalks.neco = function(campaign)
    mark(campaign, 'neco')
    maybeE02(campaign)
    if not campaign:flag('metNeco') then
        campaign.data.flags.metNeco = true
        return {title = 'NECO', voice = 'neco', lines = {
            'Você é o que veio buscar ferramenta? Eu queria ir junto — na caixa, se precisar.',
            'Sou Neco. Gosto da turma daqui. O problema é o contrato.',
        }, options = {
            {label = 'QUE CONTRATO?', lines = {
                'Meu salário tá naquela gaveta.',
            }},
            {label = 'SAIR'},
        }}
    end
    -- NE01: o registro de pagamento é a prova do acordo que o prende.
    if not done(campaign, 'NE01') then
        return {title = 'NECO', voice = 'neco', lines = {
            'Ainda aqui. Sempre aqui — esse é o problema.',
        }, options = {
            {label = 'POR QUE NÃO PEGA O SALÁRIO?', lines = {
                'Porque é um caderno dizendo quanto eles me devem.',
                'Pagamento em comida e crédito que só vale aqui. Se eu sair, morro rico em cupom.',
            }},
            {label = 'COMO EU AJUDO?', action = function(c)
                if jandaResolvida(c) then
                    c:completeStep('NE01')
                    return swap(c, {title = 'NECO', voice = 'neco', lines = {
                        'O registro tá aberto agora. Minha dívida vira conta — não coleira.',
                        'Quando eu juntar coragem, levo a caixa de ferramentas até seu refúgio.',
                    }, options = {{label = 'SAIR'}}})
                end
                return swap(c, {title = 'NECO', voice = 'neco', lines = {
                    'Resolve primeiro quem segura o caderno. A Janda decide a folha de todo mundo.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    if jandaResolvida(campaign) and not campaign:flag('necoNoHub') then
        return {title = 'NECO', voice = 'neco', lines = {
            'A passagem abriu. Meu primeiro passo foi respirar fundo.',
        }, options = {
            {label = 'VEM PRO REFÚGIO.', action = function(c)
                c.data.flags.necoNoHub = true
                c.data.people.neco.location = 'hub'
                return swap(c, {title = 'NECO', voice = 'neco', lines = {
                    'Vou. Mas aviso: eu compenso toda ajuda com mais trabalho. É vício.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    return {title = 'NECO', voice = 'neco', lines = {
        'Um dia eu saio sem pedir licença pra um caderno.',
    }, options = {{label = 'SAIR'}}}
end

-- Figurantes de alojamento: um quer ficar, um quer partir. Pós-resolução,
-- cada um reconhece o resultado sem agradecer automaticamente.
oficinasTalks.traba = function(campaign)
    mark(campaign, 'traba')
    if jandaResolvida(campaign) then
        return {title = 'TRABALHADORA', voice = 'traba', lines = {
            'Eu fiquei. E agora a escolha é minha, não do caderno.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'TRABALHADORA', voice = 'traba', lines = {
        'Eu fico. A parede que eu levantei não é "qualquer parede" pra eu abandonar.',
    }, options = {{label = 'SAIR'}}}
end

oficinasTalks.trabb = function(campaign)
    mark(campaign, 'trabb')
    if jandaResolvida(campaign) then
        return {title = 'TRABALHADOR', voice = 'trabb', lines = {
            'A passagem abriu. Ainda não parti — mas agora partir é opção, não sonho.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'TRABALHADOR', voice = 'trabb', lines = {
        'Meu contrato é um caderno e uma promessa. Promessa não cobre cama.',
    }, options = {{label = 'SAIR'}}}
end

-- MUNDO 3 — Mercado das Escoras (docs/mapas/03_MERCADO.md)
-- Conflito: posse e responsabilização — Rute declarou bens alheios como
-- estoque próprio. O acordo pede prova documental (recibo/registros),
-- não carisma. 'B03-01' e 'C03-01' são ids de encontro propostos;
-- startBattle fica com a integração.
local mercadoTalks = {}

mercadoTalks.rute = function(campaign)
    mark(campaign, 'rute')
    if not campaign:flag('metRute') then
        campaign.data.flags.metRute = true
        return {title = 'RUTE', voice = 'rute', lines = {
            'Avalio, catalogo e devolvo ao mundo o que ficou sem dono.',
            'Sou Rute. Tudo aqui tem etiqueta — inclusive você, se ficar parado.',
        }, options = {
            {label = 'ESSE LOTE É DA EMA.', lines = {
                'O lote está sob avaliação. Dono é quem prova — não quem paga.',
            }},
            {label = 'SAIR'},
        }}
    end
    if not ruteResolvida(campaign) then
        local options = {}
        if campaign:flag('reciboEma') then
            options[#options + 1] = {label = 'APRESENTAR O RECIBO.', action = function(c)
                c:settleEncounter('B03-01', 'negotiated')
                c:completeStep('P03-E04')
                return swap(c, {title = 'RUTE', voice = 'rute', lines = {
                    'Se todo mundo levar o que diz que é seu...',
                    'Recibo autêntico. Assinatura, data, valor. Item reclassificado.',
                    'A etiqueta estava errada. Eu corrijo o registro — não a memória.',
                }, options = {{label = 'SAIR'}}})
            end}
        end
        options[#options + 1] = {label = 'ABRE OS REGISTROS.', action = function(c)
            c.data.flags.ruteRegistros = true
            if campaign:flag('reciboEma') then
                c:settleEncounter('B03-01', 'negotiated')
                c:completeStep('P03-E04')
            end
            return swap(c, {title = 'RUTE', voice = 'rute', lines = {
                'Abrir os livros em público? A proposta é... correta. E incomoda.',
                'Venha ler comigo. O que cada lote diz vai decidir o que cada um vale.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'ENTÃO ENFRENTAMOS.', action = function(c)
            c.data.flags.ruteConfronto = true
            return swap(c, {title = 'RUTE', voice = 'rute', lines = {
                'Disputa registrada. A vara de avaliação não é só para etiquetar.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'SAIR'}
        return {title = 'RUTE', voice = 'rute', lines = {
            'Voltou com argumentos ou só com o arco?',
        }, options = options}
    end
    if campaign:flag('ruteMorta') then return nil end
    if campaign.data.encounters['B03-01'] == 'negotiated' then
        return {title = 'RUTE', voice = 'rute', lines = {
            'A etiqueta agora responde a alguém além de mim.',
            'Avaliar continua sendo meu ofício. A diferença é que agora conferem.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'RUTE', voice = 'rute', lines = {
        'A praça decide sem vara agora. Barulhento, mas mais barato que erro de registro.',
    }, options = {{label = 'SAIR'}}}
end

mercadoTalks.ema = function(campaign)
    mark(campaign, 'ema')
    if not campaign:flag('metEma') then
        campaign.data.flags.metEma = true
        campaign.data.flags.disputaLote = true
        campaign:completeStep('P03-E02')
        return {title = 'EMA', voice = 'ema', lines = {
            'Peças de cozinha, ferragens e um lote que a Rute jura ser dela.',
            'Sou Ema. "Está no meu depósito", ela diz. Também estão meus impostos — quer ficar com a minha dívida?',
        }, options = {
            {label = 'E A PLACA COBERTA?', action = function(c)
                c:completeStep('EM01')
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    'A placa era do patrão. A loja era dele. O nome era dele.',
                    'Agora é meu problema — e minha chance. Ainda não decidi o que escrever ali.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    -- E03 no balcão: a lembrança do casal tem fonte viva aqui; o encaixe
    -- ('bancaCasal') preserva a informação se Ema estiver ausente/morta.
    if not campaign:flag('lembrancaPlaca') then
        return {title = 'EMA', voice = 'ema', lines = {
            'Aquela banca no fundo era de um casal. Lia reclamava que a placa dele tapava o sol da banca dela.',
        }, options = {
            {label = 'ENTÃO EU MUDEI A PLACA.', action = function(c)
                c.data.flags.lembrancaPlaca = true
                if c:flag('encomendaBrina') then c:completeStep('P03-E03') end
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    'Três vezes. Vocês discutiram as três.',
                    'Era o barulho favorito da feira: dois cabeça-dura fazendo uma placa.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    -- EM02/EM03: o nome na fachada e o lugar dela no mundo (sem selo
    -- automático: visita e comércio exterior não vinculam).
    if done(campaign, 'EM01') and not done(campaign, 'EM02') then
        return {title = 'EMA', voice = 'ema', lines = {
            'Ainda penso no que escrever na placa. Nome meu? Marca coletiva dos fornecedores?',
        }, options = {
            {label = 'SEU NOME.', action = function(c)
                c:completeStep('EM02')
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    '"EMA". Curto, torto e meu. Combina com a placa.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'MARCA DOS FORNECEDORES.', action = function(c)
                c:completeStep('EM02')
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    'Uma marca que a Brina possa assinar junto. Autoria em conjunto — combina com a feira.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    if done(campaign, 'EM02') and not done(campaign, 'EM03') then
        return {title = 'EMA', voice = 'ema', lines = {
            'E o refúgio de vocês: tem balcão sobrando ou só visita?',
        }, options = {
            {label = 'POSTO DE VISITA.', action = function(c)
                c:completeStep('EM03')
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    'Posto de visita resolve: vendo aqui e vendo lá, sem me mudar.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'VEM MORAR LÁ.', action = function(c)
                c:completeStep('EM03')
                c.data.flags.emaAcolhida = true
                c.data.people.ema.location = 'hub'
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    'Morar lá é decisão grande. Aceito — mas a placa daqui continua minha.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'FIQUE AQUI. É SEU LUGAR.', action = function(c)
                c:completeStep('EM03')
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    'É o que eu queria ouvir de um cliente honesto: a feira continua tendo balcão.',
                }, options = {{label = 'SAIR'}}})
            end},
        }}
    end
    -- Mesa para todos (gancho do arco de Bento, BM02): convite é visita,
    -- não recrutamento nem selo.
    if done(campaign, 'BM01') and not campaign:flag('mesaConvidados') then
        return {title = 'EMA', voice = 'ema', lines = {
            'Ouvi que a cozinha de vocês voltou. Verdade?',
        }, options = {
            {label = 'TEM LUGAR NA MESA.', action = function(c)
                c.data.flags.mesaConvidados = true
                return swap(c, {title = 'EMA', voice = 'ema', lines = {
                    'Dia de feira boa eu levo a panela azul. Diz pro cozinheiro.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    if ruteResolvida(campaign) then
        return {title = 'EMA', voice = 'ema', lines = {
            'O depósito ficou com quem pagou por ele. A Rute ainda avalia — agora conferem antes.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'EMA', voice = 'ema', lines = {
        'O lote continua "sob avaliação". A etiqueta dela é mais forte que verdade, aparentemente.',
    }, options = {{label = 'SAIR'}}}
end

-- C03-01: par de sentinelas guardando a feira. O mini-diálogo de abordagem
-- resolve sem arena por explicação ou arma guardada; só 'PASSO ARMADO'
-- vira confronto (QA_MUNDOS: o encontro é transponível sem batalha).
mercadoTalks.guarda = function(campaign)
    mark(campaign, 'guarda')
    if campaign:flag('guardaLiberada') then
        return {title = 'GUARDA DA FEIRA', voice = 'guarda', lines = {
            'Passagem liberada. O posto continua de olho.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'GUARDA DA FEIRA', voice = 'guarda', lines = {
        'Para. Equipamento marcado — a feira teve saque demais.',
    }, options = {
        {label = 'VIM BUSCAR PEÇAS PRO FORNO.', action = function(c)
            c.data.flags.guardaLiberada = true
            return swap(c, {title = 'GUARDA DA FEIRA', voice = 'guarda', lines = {
                'Peças pro forno. Nome disso é encomenda, não saque. Passa.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'GUARDO O ARCO.', action = function(c)
            c.data.flags.guardaLiberada = true
            return swap(c, {title = 'GUARDA DA FEIRA', voice = 'guarda', lines = {
                'Assim melhor. Mão longe da corda.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'PASSO ARMADO MESMO.', action = function(c)
            c.data.flags.guardaConfronto = true
            return swap(c, {title = 'GUARDA DA FEIRA', voice = 'guarda', lines = {
                'Então o posto responde como posto.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'SAIR'},
    }}
end

mercadoTalks.feirante = function(campaign)
    mark(campaign, 'feirante')
    if ruteResolvida(campaign) then
        return {title = 'FEIRANTE', voice = 'feirante', lines = {
            'A feira respira diferente quando ninguém te etiqueta no susto.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'FEIRANTE', voice = 'feirante', lines = {
        'A feira fechou faz anos. A gente continua abrindo banca — hábito também é uma loja.',
    }, options = {{label = 'SAIR'}}}
end

-- MUNDO 4 — Reservatório de Baixo (docs/mapas/04_RESERVATORIO.md)
-- Conflito: água segura vs. medo legítimo — Ivo parou toda manutenção pra
-- ninguém se afogar. A negociação pede demonstração real (desvio testado),
-- não promessa. 'B04-01' e 'C04-02' são ids de encontro propostos;
-- C04-Q01 é o aviso opcional da Mara (rastejantes nos canteiros).
local reservatorioTalks = {}

reservatorioTalks.ivo = function(campaign)
    mark(campaign, 'ivo')
    if not campaign:flag('metIvo') then
        campaign.data.flags.metIvo = true
        campaign.data.flags.interdicaoVista = true
        maybeM4E02(campaign)
        return {title = 'IVO', voice = 'ivo', lines = {
            'Operador Ivo. A régua não mente — gente, às vezes.',
            'Trecho interditado. Ordem de quem sabe o número.',
        }, options = {
            {label = 'VIM PELA ÁGUA DO REFÚGIO.', lines = {
                'Água com filtro, sim. Água solta, só com prova.',
                'A última prova afogou um trecho inteiro. Daí a régua.',
            }},
            {label = 'SAIR'},
        }}
    end
    if not ivoResolvido(campaign) then
        local options = {}
        if campaign:flag('canalTestado') then
            options[#options + 1] = {label = 'O DESVIO SEGURA. EU TESTEI.', action = function(c)
                c:settleEncounter('B04-01', 'negotiated')
                c.data.flags.comportaAberta = true
                c:completeStep('P04-E05')
                return swap(c, {title = 'IVO', voice = 'ivo', lines = {
                    'Você... testou. No ramo isolado.',
                    'A régua concorda com você. Incomodo admitir: o desvio funciona.',
                    'Abro a comporta — com gente olhando junto dessa vez.',
                }, options = {{label = 'SAIR'}}})
            end}
        end
        if campaign:flag('esquemaLido') then
            options[#options + 1] = {label = 'INSPEÇÃO CONJUNTA, ENTÃO.', action = function(c)
                c.data.flags.ivoConversa = true
                return swap(c, {title = 'IVO', voice = 'ivo', lines = {
                    'Você leu o esquema. Então lê junto: se a régua discordar, você para.',
                }, options = {{label = 'SAIR'}}})
            end}
        end
        options[#options + 1] = {label = 'ENTÃO MEDE ISSO.', action = function(c)
            c.data.flags.ivoConfronto = true
            return swap(c, {title = 'IVO', voice = 'ivo', lines = {
                'A régua mede água. Eu meço gente. Vem.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'SAIR'}
        return {title = 'IVO', voice = 'ivo', lines = {
            'Voltou com prova ou só com teimosia?',
        }, options = options}
    end
    if campaign:flag('ivoMorta') then return nil end
    if campaign.data.encounters['B04-01'] == 'negotiated' then
        return {title = 'IVO', voice = 'ivo', lines = {
            'A água passa com gente olhando junto. Nome disso é manutenção.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'IVO', voice = 'ivo', lines = {
        'O reservatório segue. As peças continuam com nome — só que contam pra você também.',
    }, options = {{label = 'SAIR'}}}
end

reservatorioTalks.mara = function(campaign)
    mark(campaign, 'mara')
    maybeM4E02(campaign)
    if not campaign:flag('metMara') then
        campaign.data.flags.metMara = true
        return {title = 'MARA', voice = 'mara', lines = {
            'Cheiro de forasteiro — mas de antes. Você é do tempo da feira?',
            'Sou Mara. Cuido dos canteiros que a água permite.',
        }, options = {
            {label = 'O BANCO ALI ERA DE UM CASAL?', action = function(c)
                c.data.flags.lembrancaBanco = true
                if c:flag('placaLida') then c:completeStep('P04-E03') end
                return swap(c, {title = 'MARA', voice = 'mara', lines = {
                    'Deles e de metade da comunidade. Ela falava do arco; ele, do preço das ripas.',
                    'Lia sempre ganhava a discussão. Ele sentava pra ver o canal — igual você agora.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    -- C04-Q01 (proposta): aviso opcional dos rastejantes nos canteiros;
    -- a integração decide o encontro — o flag só registra que ela avisou.
    if not campaign:flag('maraAviso') then
        return {title = 'MARA', voice = 'mara', lines = {
            'À noite tem coisa rastejando entre os canteiros. Coisa antiga, da água.',
        }, options = {
            {label = 'EU VEJO ISSO.', action = function(c)
                c.data.flags.maraAviso = true
                return swap(c, {title = 'MARA', voice = 'mara', lines = {
                    'Vê direito — elas não gostam de quem pisa na raiz. Vai de botas.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    if ivoResolvido(campaign) then
        return {title = 'MARA', voice = 'mara', lines = {
            'A água corre limpa agora. Os canteiros agradecem em verde.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'MARA', voice = 'mara', lines = {
        'Canteiro não escolhe política. Escolhe água — e a água tá travada.',
    }, options = {{label = 'SAIR'}}}
end

-- O gritante do outro lado do canal: texto curto, sem corpo visível ainda.
reservatorioTalks.voz = function(campaign)
    mark(campaign, 'voz')
    if ivoResolvido(campaign) then
        return {title = 'VOZ DO CANAL', voice = 'voz', lines = {
            'A água subiu certinho! Primeira vez em anos!',
            'Daí a gente vê se essa margem volta a ter gente!',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'VOZ DO CANAL', voice = 'voz', lines = {
        'Ei! Você é do lado de cima?! A comporta ainda tá fechada?',
        'O operador trancou tudo! A gente fica gritando porque a ponte apodreceu!',
    }, options = {{label = 'SAIR'}}}
end

-- C04-02: a equipe de manutenção defendendo a interdição do operador.
-- Passa por esquema sem arena (QA); só insistência armada vira confronto.
reservatorioTalks.equipe = function(campaign)
    mark(campaign, 'equipe')
    if campaign:flag('equipeLiberada') or ivoResolvido(campaign) then
        return {title = 'MANUTENÇÃO', voice = 'equipe', lines = {
            'Passagem confirmada. O desvio segurou — a interdição vira projeto, não medo.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'MANUTENÇÃO', voice = 'equipe', lines = {
        'Trecho interditado. Ordem do operador — ninguém cruza a linha do canal.',
    }, options = {
        {label = 'O ESQUEMA MOSTRA O RAMO.', action = function(c)
            c.data.flags.equipeLiberada = true
            return swap(c, {title = 'MANUTENÇÃO', voice = 'equipe', lines = {
                'Confere com o traçado. Passa pelo ramo — devagar e na linha.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'SIGO EM FRENTE.', action = function(c)
            c.data.flags.equipeConfronto = true
            return swap(c, {title = 'MANUTENÇÃO', voice = 'equipe', lines = {
                'Então a linha te segura. Ordem é ordem.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'SAIR'},
    }}
end

-- MUNDO 5 — Salões das Vitrines (docs/mapas/05_SALOES.md)
-- Conflito: hospitalidade como controle — Beltran esconde o dano para a
-- noite ser perfeita. O acordo precisa de rota real + função pra ele;
-- plateia fica fora da arena por design. 'B05-01' e 'C05-Q1' são ids de
-- encontro propostos; C05-Q1 nunca tem desfecho letal (duelo combinado).
local saloesTalks = {}

saloesTalks.beltran = function(campaign)
    mark(campaign, 'beltran')
    if not campaign:flag('metBeltran') then
        campaign.data.flags.metBeltran = true
        campaign:completeStep('P05-E02')
        return {title = 'BELTRAN', voice = 'beltran', lines = {
            'Bem-vindo à última noite perfeita. Beltran — anfitrião, maestro e prefeito de uma praça.',
            'O programa está fechado. As vagas de plateia, não.',
        }, options = {
            {label = 'VIM PELAS DIVISÓRIAS.', lines = {
                'Vitrines são cenário. Cenário é patrimônio — e patrimônio se negocia.',
            }},
            {label = 'SAIR'},
        }}
    end
    if not beltranResolvido(campaign) then
        local options = {}
        if campaign:flag('rotaPreparada') then
            options[#options + 1] = {label = 'A SAÍDA EXISTE. EU ENSAIEI.', action = function(c)
                c:settleEncounter('B05-01', 'negotiated')
                c:completeStep('P05-E05')
                return swap(c, {title = 'BELTRAN', voice = 'beltran', lines = {
                    'Uma saída com cadeiras a caminho... aceitável.',
                    'A cortina fecha pra reabrir noutra sala. Nome disso é turnê.',
                    'Aceito — se eu escrever o programa da mudança.',
                }, options = {{label = 'SAIR'}}})
            end}
        end
        options[#options + 1] = {label = 'OFERECER FUNÇÃO.', action = function(c)
            c.data.flags.beltranConversa = true
            return swap(c, {title = 'BELTRAN', voice = 'beltran', lines = {
                'Mestre de cerimônia da mudança? Tem estilo.',
                'Mas função sem rota é só cargo. Mostra a saída primeiro.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'DEIXAR A PLATEIA DECIDIR.', action = function(c)
            c.data.flags.beltranConversa = true
            return swap(c, {title = 'BELTRAN', voice = 'beltran', lines = {
                'A plateia decide? Que modernidade.',
                'A plateia decide o aplauso. A saída continua sendo minha.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'O SHOW ACABA AQUI.', action = function(c)
            c.data.flags.beltranConfronto = true
            return swap(c, {title = 'BELTRAN', voice = 'beltran', mood = 'dark', lines = {
                'Então que seja um final à altura. Maestro, cortina, e silêncio.',
            }, options = {{label = 'SAIR'}}})
        end}
        options[#options + 1] = {label = 'SAIR'}
        return {title = 'BELTRAN', voice = 'beltran', lines = {
            'Voltou. Com proposta ou só com o arco?',
        }, options = options}
    end
    if campaign:flag('beltranMorta') then return nil end
    if campaign.data.encounters['B05-01'] == 'negotiated' then
        return {title = 'BELTRAN', voice = 'beltran', lines = {
            'A cortina fecha pra reabrir noutra sala. O programa da mudança é meu.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'BELTRAN', voice = 'beltran', lines = {
        'O programa continuou sem maestro. A plateia agradeceu em silêncio.',
    }, options = {{label = 'SAIR'}}}
end

saloesTalks.cira = function(campaign)
    mark(campaign, 'cira')
    if not campaign:flag('metCira') then
        campaign.data.flags.metCira = true
        return {title = 'CIRA', voice = 'cira', lines = {
            'Artista sem plateia é só decoração de palco. Ainda assim, ensaio.',
            'Sou Cira. Pinto os cenários — e conheço o que fica atrás deles.',
        }, options = {
            {label = 'CONHECEU O CASAL DA BANCA?', action = function(c)
                c.data.flags.lembrancaMoldura = true
                if c:flag('fundacaoLocalizada') then c:completeStep('P05-E03') end
                return swap(c, {title = 'CIRA', voice = 'cira', lines = {
                    'Eles brigaram por uma moldura — e se reconciliaram bem ali.',
                    'Lia ganhou a moldura. Ele ganhou a discussão. Ou o contrário.',
                }, options = {{label = 'SAIR'}}})
            end},
            {label = 'SAIR'},
        }}
    end
    -- NE03: se Neco veio ver o palco, a reconciliação deles fecha o arco.
    if campaign:flag('necoNoSalao') then
        return {title = 'CIRA', voice = 'cira', mood = 'warm', lines = {
            'Neco! O cara que consertava palco sem nunca ver um.',
        }, options = {{label = 'SAIR'}}}
    end
    if beltranResolvido(campaign) then
        return {title = 'CIRA', voice = 'cira', lines = {
            'O palco sobreviveu ao maestro. As cenas novas são minhas agora.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'CIRA', voice = 'cira', lines = {
        'O cenário esconde a rachadura melhor que o programa. Beltran sabe.',
    }, options = {{label = 'SAIR'}}}
end

-- C05-Q1: o ajudante propõe ensaio de luta combinado — desfecho sempre
-- não-letal (rendição/desarme); o contexto 'duelo' nos barks carrega isso.
saloesTalks.ajudante = function(campaign)
    mark(campaign, 'ajudante')
    if campaign:flag('dueloProposto') then
        return {title = 'AJUDANTE', voice = 'ajudante', lines = {
            'O ensaio fica pra quando a plateia voltar. Marca o passo.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'AJUDANTE', voice = 'ajudante', lines = {
        'Você luta de verdade? No programa tem uma cena de duelo ensaiado.',
    }, options = {
        {label = 'COMBINADO, ATÉ A RENDIÇÃO.', action = function(c)
            c.data.flags.dueloProposto = true
            return swap(c, {title = 'AJUDANTE', voice = 'ajudante', lines = {
                'Combinado. Até a rendição — nunca até o fim. É pra plateia.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'SAIR'},
    }}
end

-- Figurantes da plateia: público presente, fora da arena por design.
saloesTalks.plateia = function(campaign)
    mark(campaign, 'plateia')
    if beltranResolvido(campaign) then
        return {title = 'PLATEIA', voice = 'plateia', lines = {
            'O show acabou e ninguém morreu. Melhor temporada em anos.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'PLATEIA', voice = 'plateia', lines = {
        'A gente aplaude no escuro. É o que tem pra hoje — literalmente.',
    }, options = {{label = 'SAIR'}}}
end

-- NE03: Neco visita o palco de Cira (o convite é dado no hub; aqui ele
-- fecha o arco começado no mundo 2 — e volta pro hub depois).
saloesTalks.neco = function(campaign)
    mark(campaign, 'neco')
    if campaign:flag('necoNoSalao') and not done(campaign, 'NE03') then
        campaign:completeStep('NE03')
        return {title = 'NECO', voice = 'neco', mood = 'warm', lines = {
            'Palco de verdade. Luz de verdade. Eu consertava isso de olho fechado.',
            'Cira disse que a próxima temporada é nossa. Eu disse que ia dormir antes.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'NECO', voice = 'neco', lines = {
        'O palco merecia um técnico. Agora tem.',
    }, options = {{label = 'SAIR'}}}
end

-- Roteamento por mapa: declarado por último — todas as tabelas de talk
-- precisam existir como locals no momento do lookup.
function LoreC.talk(campaign, id)
    if campaign.map.id == 'colina' then
        local build = talks[id]
        return build and build(campaign)
    end
    if campaign.map.id == 'oficinas' then
        local build = oficinasTalks[id]
        return build and build(campaign)
    end
    if campaign.map.id == 'mercado' then
        local build = mercadoTalks[id]
        return build and build(campaign)
    end
    if campaign.map.id == 'reservatorio' then
        local build = reservatorioTalks[id]
        return build and build(campaign)
    end
    if campaign.map.id == 'saloes' then
        local build = saloesTalks[id]
        return build and build(campaign)
    end
    local build = hubTalks[id]
    if build then return build(campaign) end
    return nil
end

return LoreC
