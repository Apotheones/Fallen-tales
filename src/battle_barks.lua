-- Falas de batalha (barks), CHECKs, ACTs e flavor de rodapé para a Fase B
-- do HUD tático (docs/BATALHA_ACT_MERCY.md §5-§7). Módulo de dados, no mesmo
-- padrão de src/lore.lua e src/campaign_lore.lua: o battle.lua consome por
-- lookup, este arquivo não chama nada.
--
-- Escrita segue docs/GUIA_ESCRITA_DEVIN.md: PT-BR natural, uma voz por kind,
-- balão sobre a cabeça (máx. ~6-8 palavras por fala). Toda string passa por
-- Font.clean — registrar este módulo no sweep de glifos de tests/pixel.lua
-- quando o Bigorna integrar (ver NOTA DE VERIFICAÇÃO no fim).
--
-- ESTRUTURA DE LOOKUP (chaves estáveis, nunca índice de frase):
--   Barks.names[kind]                          -> nome de exibição (caixa-alta)
--   Barks.kinds[kind].check                    -> {1-2 linhas} do CHECK
--   Barks.kinds[kind].acts                     -> {{id,label,desc}, ...} do menu ACT
--   Barks.kinds[kind].refuses                  -> {actId=true} ACTs recusados
--   Barks.kinds[kind].barks.<situação>         -> {variantes} ou nil
--   Barks.kinds[kind].barks.act.<actId>        -> {variantes} por ACT
--   Barks.kinds[kind].barks.refuse._           -> recusa genérica (qualquer ACT)
--   Barks.kinds[kind].barks.refuse.<actId>     -> recusa específica do ACT
--   Barks.kinds[kind].contexts.<ctx>.<campo>   -> overrides por encontro (abaixo)
--   Barks.flavor.<estado>                      -> rodapé; '%s' recebe o nome
--
-- CONTEXTS (PROPOSTA de estrutura para o Bigorna): um encontro comum pode
-- carregar um id de contexto (ex.: C03-01 'guarda', C04-02 'manutencao',
-- C03-Q01 'cobrador', C05-Q01 'duelo'). O lookup consulta
-- kinds[kind].contexts[ctx][situacao|check|acts] ANTES do conjunto do kind;
-- o que não é sobrescrito cai no conjunto base. contexts.duelo carrega
-- nonLethal=true: o encontro termina em rendição/desarme, nunca execução.
--
-- DECISÃO ABERTA registrada (tom): 'guarda' e 'manutencao' das fichas são
-- pessoas ou devotos-constructos da casa? Os textos abaixo seguem a versão
-- constructo (mantém o léxico ecos/âmbar já publicado). Se a resposta for
-- "pessoas", as mesmas chaves recebem variants humanas sem trocar estrutura.
--
-- SITUAÇÕES: 'announce' (intenção declarada), 'damage' (levou flecha),
-- 'act' (resposta a um ACT do jogador), 'convinced' (marcado para poupar),
-- 'spared' (saindo do grid), 'refuse' (kind ou ACT que não negocia).
--
-- CONVENÇÕES:
-- - Kinds com verbal=false não falam: seus barks são gesto/som entre
--   parênteses, ex. '(fareja o chão)'. O renderer pode estilizar; o texto já
--   sinaliza não-verbal. §6: nem toda fera negocia — crawler e husk não têm
--   'convinced'; 'refuse._' é a resposta a qualquer tentativa de conversa.
-- - Kinds com negotiates=false nunca entram em 'convinced' por conversa.
--
-- STATUS: textos = rascunho final revisável. Nomes = rótulos já publicados
-- em enemies.lua. Efeitos mecânicos dos ACTs (desc e 'proposal' nos ids) são
-- PROPOSTA: o Bigorna decide o que cada ACT faz; ACTs marcados
-- proposal=true dependem de mecânica que ainda não existe.
local Barks = {}

Barks.names = {
    ranger = 'SENTINELA',
    veteran = 'SENTINELA VETERANA',
    sower = 'SEMEADOR DE ÂMBAR',
    watcher = 'VIGIA DOS ECOS',
    dasher = 'BRUTO',
    breaker = 'BRUTO DEMOLIDOR',
    crawler = 'RASTEJANTE',
    husk = 'ECO NASCENTE',
    warden = 'GUARDIÃO DOS ECOS',
    demolisher = 'O DEMOLIDOR DA CÂMARA',
    regent = 'A REGENTE DE ÂMBAR',
    runa = 'RUNA',
    janda = 'JANDA',
    rute = 'RUTE',
    ivo = 'IVO',
    beltran = 'BELTRAN',
}

-- Legenda dos ids de ACT usados abaixo (estável para lookup):
--   observar   = olhar sem intervir; devolve fala de leitura do kind
--   intimidar  = pressão frontal; constructos recusam (pedra não teme)
--   provocar   = atrair a investida/raiva; útil para guiar linhas retas
--   tregua     = propor trégua/retirada; canal normal de poupar
--   acalmar    = voz baixa / canto; canal dos devotos
--   distrair   = desviar a atenção da fera (PROPOSTA de mecânica)
--   embalar    = adiar a eclosão do casulo (PROPOSTA de mecânica)
--   vela       = soprar a vela do vigia (PROPOSTA de mecânica)
--   ordem      = citar a última ordem ao Guardião (PROPOSTA de cena)
--   saida      = falar de outra saída ao Demolidor (PROPOSTA de cena)
--   despedida  = cantar a despedida à Regente (PROPOSTA de cena)
-- ACTs dos chefes humanos (fichas 01-05; cada um responde ao conflito real
-- do adversário, não é elogio genérico):
--   guardar      = Runa: baixar o arco / afastar a arma (P01-E04)
--   inspecao     = permitir inspeção (Runa: ver de perto; Janda: olhar a rota)
--   versao       = Runa: corrigir a versão oficial — ninguém se ofereceu
--   trabalhadores= Janda: perguntar em voz alta quem decide ficar ou ir
--   suspender    = pausar o confronto para terminar o preparo (PROPOSTA)
--   recibo       = Rute: apresentar o recibo de Ema
--   registros    = Rute: propor abrir os livros em público
--   desvio       = Ivo: demonstrar o ramo isolado na régua do canal
--   conjunto     = Ivo: inspeção conjunta do traçado
--   rota         = Beltran: apresentar a saída lateral preparada e o laudo
--   funcao       = Beltran: oferecer papel na mudança, não na plateia
--   plateia      = Beltran: deixar os moradores decidirem se assistem

Barks.kinds = {}

-- Devotos encapuzados: ainda cumprem o ofício da casa. Negociam.

Barks.kinds.ranger = {
    verbal = true, negotiates = true,
    check = {
        'SENTINELA. Devota que ainda cumpre a ronda de séculos atrás.',
        'Anuncia uma linha e atira reto. Saia da linha de tiro.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Ver como a devota segura o posto.'},
        {id = 'acalmar', label = 'FALAR BAIXO', desc = 'Uma voz baixa, sem ameaça. Ela escuta entre rondas.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Oferecer que a guarda descanse desta passagem.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'A linha está marcada.', 'Posto firme. Flecha pronta.',
            'Nenhum passo sem aviso.'},
        damage = {'A linha permanece.', 'Flecha por flecha.'},
        act = {
            observar = {'Os olhos dela não saem da linha.'},
            acalmar = {'Baixo. A guarda quase escuta.'},
            tregua = {'Descansar o posto? Isso existe?'},
        },
        convinced = {'A ronda... pode esperar.', 'Guarde a flecha. Eu também.'},
        spared = {'Recuo ao posto. Em paz.'},
        refuse = {
            _ = {'A ordem não conversa.'},
            intimidar = {'Guarda não recua por grito.'},
        },
    },
    contexts = {
        -- C02-01: sentinela antiga que ainda protege o acesso técnico.
        acesso = {
            check = {'SENTINELA ANTIGA. O último posto que não recebeu a notícia.',
                'Cruzar o aviso ou atacar abre confronto. Aviso ainda é aviso.'},
            announce = {'Acesso técnico. Fora do turno não passa.', 'Posto antigo. Aviso mantido.'},
            convinced = {'O posto... aposentou. Prossiga.'},
        },
        -- C02-03: o cobrador que reivindica os pertences de Neco.
        cobrador = {
            check = {'SENTINELA COBRADORA. Veio buscar o que não é dela.',
                'A disputa é da caixa de Neco — conversa e acordo vêm antes.'},
            announce = {'A caixa tem dono. Não é você.', 'Cobrança marcada. Apresenta.'},
            damage = {'A dívida não cobre isto.'},
            convinced = {'A caixa fica. O registro fecha.'},
        },
        -- C03-01: guardas que confundem o equipamento do retornado com saque.
        guarda = {
            check = {'SENTINELA DE POSTO. Guarda a feira como quem guarda cofre.',
                'Confundiu sua aljava com saque. Explicar também resolve.'},
            announce = {'Saque não passa do posto.', 'Equipamento marcado. Identifica.'},
            convinced = {'Patrimônio conferido. Pode passar.'},
        },
        -- C04-02: equipe de manutenção defendendo a interdição de Ivo.
        manutencao = {
            check = {'SENTINELA DE OBRA. Cumpre a interdição do operador.',
                'Mostrar o esquema vale mais que atravessar a linha.'},
            announce = {'Trecho interditado. Ordem do operador.', 'Obra viva. Sem passagem.'},
            convinced = {'Interdição revista. Prossiga.'},
        },
        -- C05-02: vigias do abrigo — defendem as camas, não o corredor.
        vigia = {
            check = {'SENTINELA VIGIA. Guarda camas, não portas.',
                'Desmontar parede põe cama em risco. O laudo decide o excedente.'},
            announce = {'Parede que segura cama não é cenário.', 'Excedente sim. Abrigo não.'},
            convinced = {'Laudo conferido. O trecho libera.'},
        },
    },
}

Barks.kinds.veteran = {
    verbal = true, negotiates = true,
    check = {
        'SENTINELA VETERANA. Conta os invernos em linhas de tiro.',
        'Dispara duas linhas em sequência. Conte os avisos.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Medir a postura de quem nunca errou a mão.'},
        {id = 'provocar', label = 'PROVOCAR', desc = 'Questionar a mira dela. Ela responde com o arco.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Oferecer encerrar a ronda sem mais flechas.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'Duas linhas. Honre o ofício.', 'A primeira avisa. A segunda não.'},
        damage = {'Boa flecha. A minha é melhor.'},
        act = {
            observar = {'Ela corrige sua postura com o olhar.'},
            provocar = {'Amador. Segura isto.'},
            tregua = {'Trégua é para quem erra.'},
        },
        convinced = {'O ofício reconhece o ofício.'},
        spared = {'A ronda continua. Sem você nela.'},
        refuse = {
            _ = {'Conversa não derruba flecha.'},
            intimidar = {'Já vi medo maior.'},
        },
    },
}

Barks.kinds.sower = {
    verbal = true, negotiates = true,
    check = {
        'SEMEADOR DE ÂMBAR. Planta marcas onde passos devem morrer.',
        'A faixa anunciada vira espinho. Mude de rota antes.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Acompanhar o gesto de quem planta devagar.'},
        {id = 'acalmar', label = 'FALAR BAIXO', desc = 'Falar do plantio como quem fala de chuva.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Propor que esta terra não receba mais semente.'},
    },
    refuses = {intimidar = true, provocar = true},
    barks = {
        announce = {'Toda marca é uma semente.', 'Esta faixa fica comigo.'},
        damage = {'A semente bebe o golpe.'},
        act = {
            observar = {'Ele planta devagar, como quem reza.'},
            acalmar = {'O semeador para. A terra respira.'},
            tregua = {'Semeia-se onde há passos?'},
        },
        convinced = {'Esta terra já está cheia.'},
        spared = {'Semeio onde ninguém passa.'},
        refuse = {_ = {'A semente não ouve.'}},
    },
}

Barks.kinds.watcher = {
    verbal = true, negotiates = true,
    check = {
        'VIGIA DOS ECOS. Acende uma cruz sob quem se aproxima.',
        'Os braços da cruz têm alcance curto. Fique na diagonal.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Ver a chama reagir a cada passo seu.'},
        {id = 'vela', label = 'APAGAR A VELA', desc = 'Soprar a vela do vigia. Sem vela, sem cruz.',
            proposal = true},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Pedir que a encruzilhada durma esta noite.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'As quatro direções me ouvem.', 'Velo pelo cruzamento.'},
        damage = {'O vigia sangra em cruz.'},
        act = {
            observar = {'A chama treme quando você se move.'},
            vela = {'A vela apaga. A cruz esquece.'},
            tregua = {'A encruzilhada... pode descansar?'},
        },
        convinced = {'A encruzilhada pode dormir.'},
        spared = {'Apago a vela. Passe em silêncio.'},
        refuse = {_ = {'O vigia só vela.'}},
    },
}

-- Constructos de pedra: poucas palavras, verbo pesado. Intimidar não cola.

Barks.kinds.dasher = {
    verbal = true, negotiates = true,
    check = {
        'BRUTO. Constructo de choque ajoelhado em forma de muro.',
        'A frente é muro; os lados, argila. Flanqueie.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Procurar a junta fraca na placa de pedra.'},
        {id = 'provocar', label = 'PROVOCAR', desc = 'Chamar a investida. Ela vem reta: planeje o lado.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Propor que o muro volte a ser parede.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'A parede anda.', 'Reto. Nada desvia.'},
        damage = {'A pedra racha por dentro.', 'O flanco sente.'},
        act = {
            observar = {'Músculo de pedra. Fôlego de rijo.'},
            provocar = {'O muro responde com o corpo inteiro.'},
            tregua = {'Parar também é forma de muro.'},
        },
        convinced = {'Muros também param.'},
        spared = {'Volto a ser pedra.'},
        refuse = {
            _ = {'Pedra não conversa.'},
            intimidar = {'Pedra não teme.'},
        },
    },
    contexts = {
        -- C02-02: bruto no entulho da saída — a pilha de destroços é o muro.
        entulho = {
            check = {'BRUTO DO ENTULHO. A pilha de destroços é o muro dele.',
                'Frente blindada; a saída atrás é o que ele defende.'},
            announce = {'Entulho é muro. Muro não anda.', 'A saída fica. Você não.'},
            convinced = {'O muro... desiste de ser muro.'},
        },
        -- C04-02: bruto da equipe de manutenção.
        manutencao = {
            check = {'BRUTO DE OBRA. Bloqueio vivo da interdição.',
                'A frente é muro; o esquema na mão é atalho.'},
            announce = {'Bloqueio da obra. Contorna.', 'Interditado. Sem negocio.'},
            convinced = {'Ordem revista. Saio da linha.'},
        },
        -- C03-Q01: bruto cobrador que reivindica a placa de Ema.
        cobrador = {
            check = {'BRUTO COBRADOR. Veio buscar a placa da fachada.',
                'A disputa é da placa; a linha dele, reta como sempre.'},
            announce = {'A placa tem dono. Não é você.', 'Cobrança reta. Sem desvio.'},
            damage = {'A dívida não cobre isto.'},
            convinced = {'A placa fica. A conta encerra.'},
        },
        -- C05-Q01: ajudante que propõe ensaio de luta; duelo combinado
        -- termina em rendição/desarme — nunca execução (nonLethal=true).
        duelo = {
            nonLethal = true,
            check = {'BRUTO AJUDANTE. Topou um ensaio de luta para o programa.',
                'Duelo combinado: vai até a rendição, não até o fim.'},
            announce = {'Ensaio combinado. Até a rendição.', 'Cena de luta. Marca o passo.'},
            damage = {'Boa cena. Continua.'},
            convinced = {'Marca a rendição. Corta.'},
            spared = {'Rendido. Palco livre.'},
        },
    },
}

Barks.kinds.breaker = {
    verbal = true, negotiates = true,
    check = {
        'BRUTO DEMOLIDOR. Atravessa bloqueios em vez de parar neles.',
        'Não confie na cobertura. Use a linha dele contra os pilares.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Ver o que ele conta: obstáculos, não inimigos.'},
        {id = 'provocar', label = 'PROVOCAR', desc = 'Fazer ele escolher a linha reta até você.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Oferecer que nada precise cair hoje.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'O que está na frente cai.', 'Derrubo tudo. Até parede.'},
        damage = {'A placa racha. O passo não.'},
        act = {
            observar = {'Ele conta obstáculos. Não inimigos.'},
            provocar = {'Ele escolhe a linha mais reta.'},
            tregua = {'Nada para derrubar? Estranho.'},
        },
        convinced = {'Nem toda parede precisa cair.'},
        spared = {'A ruína fica. Eu vou.'},
        refuse = {
            _ = {'Conversa não derruba.'},
            intimidar = {'Medo não derruba pedra.'},
        },
    },
}

-- Fera e casulo: sem linguagem (§6). Barks são gesto/som; conversa vira
-- recusa por natureza. DISTRAIR/EMBALAR são propostas de mecânica.

Barks.kinds.crawler = {
    verbal = false, negotiates = false,
    check = {
        'RASTEJANTE. A caça que sobrou de uma besta da casa.',
        'Ameaça a célula vizinha e erra feio. O erro o deixa aberto.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Ler o ritmo da caça antes de se mover.'},
        {id = 'distrair', label = 'DISTRAIR', desc = 'Jogar o foco dela para outra célula.',
            proposal = true},
    },
    refuses = {intimidar = true, provocar = true, tregua = true, acalmar = true},
    barks = {
        announce = {'(fareja o chão, ereta)', '(baixo. quase um rosar)'},
        damage = {'(chiado curto; recua e volta)'},
        act = {
            observar = {'(ela repete a mesma volta. sempre)'},
            distrair = {'(a cabeça gira para o outro lado)'},
        },
        spared = {'(aceita a retirada e some)'},
        refuse = {_ = {'(não entende palavras. só a caça)'}},
    },
    contexts = {
        -- C04-Q01: rastejantes defendendo brotos nos canteiros da Mara.
        canteiro = {
            check = {'RASTEJANTE DE CANTEIRO. Defende brotos, não um ninho.',
                'Espantar por corredor vazio resolve sem combate.'},
            announce = {'(rasteja entre os brotos)', '(rosna para a raiz, não para você)'},
            damage = {'(chiado; cobre os brotos com o corpo)'},
            spared = {'(recua para o canteiro e some)'},
        },
    },
}

Barks.kinds.husk = {
    verbal = false, negotiates = false,
    check = {
        'ECO NASCENTE. Uma despedida que ainda não acabou de nascer.',
        'Dorme e pulsa. Se eclodir, vira caça. Resolva antes — ou não toque.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Ouvir o que pulsa dentro do casulo.'},
        {id = 'embalar', label = 'EMBALAR', desc = 'Embalar o casulo. A eclosão espera mais um pouco.',
            proposal = true},
    },
    refuses = {intimidar = true, provocar = true, tregua = true, acalmar = true,
        distrair = true},
    barks = {
        announce = {'(pulsa no escuro. quase canto)'},
        damage = {'(o casulo estala)'},
        act = {
            observar = {'(dentro, algo ensaia um nome)'},
            embalar = {'(o pulso desacelera. dorme)'},
        },
        spared = {'(adormece de vez)'},
        refuse = {_ = {'(não nasceu. não há quem responda)'}},
    },
}

-- Chefes das arenas antigas: mantêm os rótulos e a voz das intros de
-- lore.lua. ACTs de cena são proposta de conversa por personagem, não
-- botão de pular a luta.

Barks.kinds.warden = {
    verbal = true, negotiates = true, boss = true,
    check = {
        'GUARDIÃO DOS ECOS. O porteiro que ainda cumpre a última ordem.',
        'Selo frontal: ataque pelos flancos. Sob fúria, os avisos aceleram.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Ver o peso de trezentos invernos de ordem.'},
        {id = 'ordem', label = 'CITAR A ORDEM', desc = 'Repetir a ordem em voz alta. Quem obedece pode ouvir.',
            proposal = true},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Propor que a porta cuide de si esta noite.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'A ordem não envelheceu.', 'Nenhum capuz desce.'},
        damage = {'O selo estala. A ordem segue.'},
        act = {
            observar = {'Ele pesa a lança como quem reza.'},
            ordem = {'A ordem... não dizia seu nome.'},
            tregua = {'Portas também cansam.'},
        },
        convinced = {'A ordem era para os ecos. Não para você.'},
        spared = {'Cumpro o resto em silêncio.'},
        refuse = {
            _ = {'A ordem não negocia.'},
            intimidar = {'Trezentos invernos. Sem medo.'},
        },
    },
}

Barks.kinds.demolisher = {
    verbal = true, negotiates = true, boss = true,
    check = {
        'O DEMOLIDOR DA CÂMARA. Quebrou-se tentando libertar os ecos na marra.',
        'A investida atravessa tudo. Ponha um pilar na linha dele.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Medir o martelo que já derrubou uma casa.'},
        {id = 'saida', label = 'FALAR DE SAÍDA', desc = 'Dizer que existe outra saída para os ecos.',
            proposal = true},
        {id = 'provocar', label = 'PROVOCAR', desc = 'Puxar a investida para onde você quer o golpe.'},
    },
    refuses = {intimidar = true, tregua = true},
    barks = {
        announce = {'Na marra se abre.', 'Porta ou parede: vai ao chão.'},
        damage = {'Já quebrei coisa maior.'},
        act = {
            observar = {'O martelo pesa mais que a paciência.'},
            saida = {'Outra saída...? Repete. Devagar.'},
            provocar = {'Vem. A casa aguenta. Você não.'},
        },
        convinced = {'Se a palavra abre... fala.'},
        spared = {'O martelo desce. Só desta vez.'},
        refuse = {
            _ = {'Só a marra responde.'},
            intimidar = {'Intimido eu.'},
            tregua = {'Trégua é porta. E porta eu derrubo.'},
        },
    },
}

Barks.kinds.regent = {
    verbal = true, negotiates = true, boss = true,
    check = {
        'A REGENTE DE ÂMBAR. Conjura ecos nascentes entre tiros e marcas.',
        'Destrua os nascentes antes da eclosão — ou poupe o que não nasceu.',
    },
    acts = {
        {id = 'observar', label = 'OBSERVAR', desc = 'Ver o luto por baixo do trono.'},
        {id = 'despedida', label = 'CANTAR DESPEDIDA', desc = 'Cantar a despedida que ela nunca deixou terminar.',
            proposal = true},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Propor que nenhuma despedida precise ser agora.'},
    },
    refuses = {intimidar = true, provocar = true},
    barks = {
        announce = {'Nenhuma despedida será a última.', 'O âmbar guarda. Eu decido.'},
        damage = {'Você risca a prisão. Não o luto.'},
        act = {
            observar = {'Ela conta os ecos como quem conta filhos.'},
            despedida = {'O canto para. Ela quase lembra.'},
            tregua = {'Agora ou depois: tudo fica comigo.'},
        },
        convinced = {'Quando eu soltar... cante meu nome.'},
        spared = {'Os ecos ficam. Vá lembrando.'},
        refuse = {
            _ = {'A Regente não recebe súplicas.'},
            intimidar = {'O trono não teme flechas.'},
        },
    },
}

-- Chefes humanos das fichas 01-05: pessoas, não ecos. `human = true` marca
-- para o renderer/sistema tratar 'spared' como rendição/acordo — derrota
-- não é morte (BATALHA_ACT_MERCY §7). ACTs respondem ao conflito da ficha.

Barks.kinds.runa = {
    verbal = true, negotiates = true, boss = true, human = true,
    -- P01-E04: a vigia da grade; a conversa pode resolver sem luta.
    check = {
        'RUNA. A vigia da grade: jovem, armada e com medo do que levantou.',
        'Ela anuncia antes de agir. A resposta certa abre a grade sem sangue.',
    },
    acts = {
        {id = 'guardar', label = 'GUARDAR O ARCO', desc = 'Baixar a arma de viagem. Ela decide se a conversa basta.'},
        {id = 'inspecao', label = 'PERMITIR INSPEÇÃO', desc = 'Deixar ela ver de perto o que levantou da cova.'},
        {id = 'versao', label = 'CORRIGIR A HISTÓRIA', desc = 'Dizer o que você lembra: ninguém se ofereceu.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Pedir que a grade decida depois da conversa.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'Para aí. Responde primeiro.', 'Eu aviso antes de bater.',
            'Minha grade. Minhas regras.'},
        damage = {'Isso não prova nada.', 'De novo não.'},
        act = {
            guardar = {'Arco no chão. Continua assim.'},
            inspecao = {'Deixa eu ver... você tem sombra de gente.'},
            versao = {'Se ofereceu? Você lembra de tentar fugir.'},
            tregua = {'Trégua até eu decidir. Não mais.'},
        },
        convinced = {'A casa deixou você sair. Passa — eu respondo junto.'},
        spared = {'Vou abrir a grade. Sem mentira dessa vez.'},
        refuse = {
            _ = {'Pergunta primeiro. Luta depois.'},
            intimidar = {'Vigia não recua por grito.'},
        },
    },
}

Barks.kinds.janda = {
    verbal = true, negotiates = true, boss = true, human = true,
    -- B02: perdeu gente numa evacuação; trata partir como irresponsabilidade.
    check = {
        'JANDA. Mestra da oficina; nunca mais soltou as chaves depois da evacuação.',
        'Martelo largo anuncia áreas. A prova abre mais que o golpe.',
    },
    acts = {
        {id = 'inspecao', label = 'OFERECER INSPEÇÃO', desc = 'A passagem está aberta: convidar Janda a olhar.'},
        {id = 'trabalhadores', label = 'DEIXAR ELES DECIDIREM', desc = 'Perguntar em voz alta quem quer ficar e quem quer ir.'},
        {id = 'suspender', label = 'PROPOR PAUSA', desc = 'Suspender o confronto para terminar o reparo da saída.',
            proposal = true},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Propor discutir a retirada sem martelo na mão.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'Ninguém sai com a estrutura caindo.', 'A saída cede por baixo, não por ordem.'},
        damage = {'O martelo pesa mais que a flecha.'},
        act = {
            inspecao = {'...Eu vou olhar.'},
            trabalhadores = {'Eles trabalham melhor aqui. Deviam.'},
            suspender = {'Pausa. Se a saída ceder, você responde.'},
            tregua = {'Trégua não paga ferramenta.'},
        },
        convinced = {'Se a saída segura existe, mostra o registro.'},
        spared = {'O abrigo fica. O comando não precisa ficar.'},
        refuse = {
            _ = {'Ordem não é conversa.'},
            intimidar = {'Ameaça não segura teto.'},
        },
    },
}

Barks.kinds.rute = {
    verbal = true, negotiates = true, boss = true, human = true,
    -- B03-01: avaliadora que declarou bens alheios como próprio estoque.
    check = {
        'RUTE. Avaliadora de pertences sem dono; etiqueta impecável, posse discutível.',
        'Anuncia o valor do que vai quebrar. Ouça o material.',
    },
    acts = {
        {id = 'recibo', label = 'APRESENTAR RECIBO', desc = 'O recibo de Ema pesa mais que a etiqueta dela.'},
        {id = 'registros', label = 'ABRIR OS REGISTROS', desc = 'Propor conferir, em voz alta, de quem é cada lote.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Suspender a disputa até o registro falar.'},
    },
    refuses = {intimidar = true, provocar = true},
    barks = {
        announce = {'Valor de madeira.', 'Valor de ferro.', 'Avaliando a cena.'},
        damage = {'Isso vai para o preço final.'},
        act = {
            recibo = {'Recibo autêntico. Item reclassificado.'},
            registros = {'Abrir os livros... em público?'},
            tregua = {'A avaliação continua. A disputa, talvez não.'},
        },
        convinced = {'A etiqueta estava errada. Corrijo o registro.'},
        spared = {'Retiro a avaliação. Não a mercadoria.'},
        refuse = {
            _ = {'Sem registro, sem conversa.'},
            intimidar = {'Ameaça não altera avaliação.'},
        },
    },
}

Barks.kinds.ivo = {
    verbal = true, negotiates = true, boss = true, human = true,
    -- B04-01: operador que parou toda manutenção para ninguém se afogar.
    check = {
        'IVO. Operador que nomeia as peças; trata qualquer iniciativa como ameaça.',
        'Jatos anunciados pelas linhas do canal. A demonstração convence.',
    },
    acts = {
        {id = 'desvio', label = 'DEMONSTRAR O DESVIO', desc = 'Mostrar na régua o ramo isolado do canal de teste.'},
        {id = 'conjunto', label = 'INSPEÇÃO CONJUNTA', desc = 'Chamar Ivo para olhar o traçado junto com você.'},
        {id = 'suspender', label = 'PROPOR PAUSA', desc = 'Parar o confronto para terminar a preparação do canal.',
            proposal = true},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Discutir a comporta sem jato correndo.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'Jato pela linha três.', 'A régua não mente.'},
        damage = {'Peça nove aguentou pior.'},
        act = {
            desvio = {'Esse ramo... segura. O traço não mostra as pessoas.'},
            conjunto = {'Eu vou olhar. Se a régua discordar, você para.'},
            suspender = {'Pausa registrada. O canal espera.'},
            tregua = {'Trégua não liga bomba.'},
        },
        convinced = {'A água pode passar. Com gente olhando junto.'},
        spared = {'As comportas ficam. Com testemunha desta vez.'},
        refuse = {
            _ = {'Ruído não é argumento.'},
            intimidar = {'Ameaça não abre comporta.'},
        },
    },
}

Barks.kinds.beltran = {
    verbal = true, negotiates = true, boss = true, human = true,
    -- B05-01: anfitrião que esconde o dano para a noite ser perfeita.
    check = {
        'BELTRAN. Anfitrião que reescreve o programa para ninguém ficar sem função.',
        'Gestos de maestro anunciam cortina e bastão. A plateia está fora da arena.',
    },
    acts = {
        {id = 'rota', label = 'MOSTRAR A ROTA', desc = 'Apresentar a saída lateral preparada e o laudo.'},
        {id = 'funcao', label = 'OFERECER FUNÇÃO', desc = 'Dar a Beltran um papel na mudança, não na plateia.'},
        {id = 'plateia', label = 'DEIXAR A PLATEIA DECIDIR', desc = 'Perguntar aos moradores se querem assistir.'},
        {id = 'tregua', label = 'PROPOR TRÉGUA', desc = 'Intervalo no espetáculo para falar do teto.'},
    },
    refuses = {intimidar = true},
    barks = {
        announce = {'O espetáculo continua.', 'Aplausos. Da esquerda para a direita.'},
        damage = {'Flecha na plateia. Indelicado.'},
        act = {
            rota = {'Uma saída com cadeiras a caminho... aceitável.'},
            funcao = {'Mestre de cerimônia da mudança. Tem estilo.'},
            plateia = {'A plateia decide? Que modernidade.'},
            tregua = {'Intervalo. Dez minutos de bastidores.'},
        },
        convinced = {'A cortina fecha, mas ninguém sai de cena.'},
        spared = {'Guardo a reverência para a reabertura.'},
        refuse = {
            _ = {'O programa está fechado.'},
            intimidar = {'Ameaças não vendem ingresso.'},
        },
    },
}

-- Rodapé de estado: substitui o log técnico. '%s' recebe o nome de
-- exibição da unidade (Barks.names). Linhas sem '%s' funcionam na arena
-- inteira, sem alvo.
Barks.flavor = {
    roundStart = {
        'As intenções estão na mesa. Você age.',
        'A arena prende a respiração.',
        'A poeira espera seu passo.',
    },
    hesitates = {
        '%s hesita entre ordens.',
        '%s procura a linha e não acha.',
    },
    almostConvinced = {
        '%s baixa a guarda.',
        'Algo em %s quase escuta.',
    },
    quiet = {
        'A arena silencia.',
        'Só resta a poeira caindo.',
    },
    fled = {
        'Você se retira. A arena deixa.',
    },
    resolved = {
        'O encontro termina. As pedras guardam o resto.',
    },
}

-- Pitch de blip por chefe humano (PROPOSTA para o Traço): mesma convenção
-- de Lore.voices; runa reusa o pitch dela no diálogo normal.
Barks.voices = {runa = 1.05, janda = .62, rute = .9, ivo = .78, beltran = 1.1}

-- Lookup estável: kind desconhecido cai na sentinela (mesmo fallback dos
-- ROLES em battle.lua); situação ausente cai no gesto neutro. `ctx`
-- (opcional) consulta kinds[kind].contexts[ctx] antes do conjunto base.
function Barks.name(kind)
    return Barks.names[kind] or Barks.names.ranger
end

function Barks.kind(kind)
    return Barks.kinds[kind] or Barks.kinds.ranger
end

function Barks.context(kind, ctx)
    local k = Barks.kind(kind)
    return ctx and k.contexts and k.contexts[ctx] or nil
end

function Barks.check(kind, ctx)
    local c = Barks.context(kind, ctx)
    return (c and c.check) or Barks.kind(kind).check
end

function Barks.acts(kind, ctx)
    local c = Barks.context(kind, ctx)
    return (c and c.acts) or Barks.kind(kind).acts
end

function Barks.bark(kind, situation, ctx)
    local c = Barks.context(kind, ctx)
    return (c and c[situation]) or Barks.kind(kind).barks[situation]
end

function Barks.actBark(kind, actId, ctx)
    local acts = Barks.kind(kind).barks.act
    local c = Barks.context(kind, ctx)
    local lines = c and c.act and c.act[actId]
    return lines or (acts and acts[actId])
end

function Barks.refusal(kind, actId, ctx)
    local c = Barks.context(kind, ctx)
    local refuse = (c and c.refuse) or Barks.kind(kind).barks.refuse
    if not refuse then return nil end
    return refuse[actId] or refuse._
end

-- ESTADO -> EMOÇÃO NA ARENA (contrato do Traço, elenco expressivo):
-- cada situação de bark tem retrato sugerido; kind sobrescreve onde a ficha
-- pede. Vocabulário compartilhado com LoreC.expr (neutral/joy/sad/stern/
-- soft/fear/anger/shame/awe). Situação sem entrada -> 'neutral'.
-- Constructos (ranger/dasher/...) usam stern->soft; crawler/husk, sem
-- linguagem, têm o gesto mínimo abaixo — retrato só se a anatomia couber.
Barks.exprSit = {
    announce = 'stern',
    damage   = 'fear',
    act      = 'neutral',
    convinced= 'soft',
    spared   = 'soft',
    refuse   = 'stern',
    death    = 'sad',
}
Barks.exprKind = {
    runa    = {convinced = 'sad'},
    janda   = {convinced = 'soft'},
    rute    = {convinced = 'shame'},   -- o recibo a desarma
    ivo     = {convinced = 'sad'},     -- a água que ele não conteve
    beltran = {damage = 'shame', convinced = 'sad'}, -- o dano exposto o envergonha
    crawler = {damage = 'anger'},      -- fera: dor vira caça
    husk    = {damage = 'sad', spared = 'soft'},
}

-- Retrato sugerido para a situação: override de kind, senão a situação.
function Barks.exprFor(kind, situation)
    local over = Barks.exprKind[kind]
    if over and over[situation] then return over[situation] end
    return Barks.exprSit[situation] or 'neutral'
end

-- MAPA ENCONTRO -> CONTEXTO (auditoria vs. fichas 02-05):
--   C02-01 acesso técnico     -> ranger.acesso      (+ crawler base)
--   C02-02 entulho da saída   -> dasher.entulho     (+ crawler base)
--   C02-03 cobrador de Neco   -> ranger.cobrador    (NÃO o ctx dasher:
--                                disputa diferente — caixa, não placa)
--   C03-01 guardas da feira   -> ranger.guarda
--   C03-02 rastejantes        -> crawler base
--   C03-Q01 cobrador da placa -> dasher.cobrador
--   C04-01 rastejantes        -> crawler base
--   C04-02 equipe manutenção  -> ranger.manutencao + dasher.manutencao
--   C04-Q01 canteiros         -> crawler.canteiro
--   C05-01 rastejantes canal  -> crawler base
--   C05-02 vigias do abrigo   -> ranger.vigia
--   C05-Q01 duelo combinado   -> dasher.duelo (nonLethal=true)
--   B01..B05 chefes           -> kinds próprios (runa/janda/rute/ivo/beltran)
-- Encontros sem ctx: a ficha só dá posição+composição genérica — o
-- conjunto base do kind cobre o tom.

-- NOTA DE VERIFICAÇÃO para o Bigorna: todas as strings acima usam só o
-- repertório da fonte bitmap (PT-BR + pontuação). Ao integrar, adicionar
-- este módulo ao sweep de Font.clean em tests/pixel.lua.
return Barks
