-- Nodes de beat da arena (COMBATE_MERGE §7): a namespace que os gatilhos de
-- conversa consultam primeiro — ids daqui nunca disputam com os talks de
-- exploração. O fallback para ids fora da tabela é LoreC.talk (o roteador do
-- Pena), para reaproveitar nodes de encontro já escritos na mesma gramática.
--
-- Shape = o que Dialogue.open aceita: {title, lines, options?, voice?, mood?}.
-- Cada option é {label, lines} (fala e volta ao menu do node) ou
-- {label, action = campaign -> true/nil} (escreve estado e fecha — `true`
-- encerra o node, nil o mantém). Nos nodes de beat a option pode escrever
-- estado social da arena: campaign.battle.beatSpeaker é a unidade que fala
-- (convince/provoked/etc. vivem na entidade).
--
-- Convenção de voz: chefes usam o id do NPC (mesmo pitch dos diálogos de
-- exploração); encontros comuns usam o id do contexto quando ele tem voz
-- registrada em LoreC.voices ('guarda', 'equipe', 'ajudante'); ranger e
-- dasher herdam o pitch do kind. crawler/husk são non-verbal (verbal=false)
-- — nenhum beat fala por eles: sem falante vivo, o gatilho não arma.
local Talks = {nodes = {}}

-- Genéricos de sentinela (ranger): cobrem qualquer encontro cujo def ainda
-- não declare beats próprios — ids preservados dos fixtures de teste.
Talks.nodes.rangerAbertura = {
    title = 'SENTINELA', voice = 'ranger', lines = {
        'Para onde você vai com esse arco, sepultada?',
        'O fundo não é lugar de gente viva. Volta enquanto eu deixo.',
    }, options = {
        {label = 'EU SÓ QUERO PASSAR', action = function(c)
            local e = c.battle and (c.battle.beatSpeaker or c.battle.enemies[1])
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}

Talks.nodes.rangerMetade = {
    title = 'SENTINELA', voice = 'ranger', lines = {
        'Você atira como quem já fez isso antes.',
        'Não precisa terminar assim. Nenhuma de nós duas quer isso de verdade.',
    },
}

Talks.nodes.rangerEntrega = {
    title = 'SENTINELA', voice = 'ranger', lines = {
        'Tá bom. Você venceu a parte que importa.',
        'Chega perto e me solta — eu sei o caminho de saída daqui.',
    },
}

-- C02-01 — acesso técnico: a sentinela do posto esquecido.
Talks.nodes.acessoAbertura = {
    title = 'SENTINELA', voice = 'ranger', lines = {
        'O posto não recebe visita faz tempo. A ordem continua em pé.',
        'Quem passa aqui é equipe. Você não é equipe.',
    },
}

-- C02-02 — entulho: o bruto na passagem obstruída.
Talks.nodes.entulhoAbertura = {
    title = 'BRUTO', voice = 'dasher', lines = {
        'Entulho é muro. Muro não anda.',
        'Você anda, ele não. A conta fecha assim.',
    },
}

-- C02-03 — cobrador de pertences (ranger com cargo de cobrança).
Talks.nodes.cobradorAbertura = {
    title = 'COBRADOR', voice = 'ranger', lines = {
        'Tudo que ficou pra trás passa pela cobrança.',
        'Pertence tem dono registrado. O seu nome não tá na lista.',
    }, options = {
        {label = 'ESSA CAIXA É DO NECO.', lines = {
            'Nome dele no meu papel, dívida no dele. A caixa fica.',
        }},
        {label = 'SAIR'},
    },
}

-- C03-01 — guardas da feira: abordagem de rua.
Talks.nodes.guardaAbertura = {
    title = 'GUARDA', voice = 'guarda', lines = {
        'A feira tá fechada pra quem não tem placa.',
        'Banca, licença ou distância — escolhe a que cabe.',
    }, options = {
        {label = 'EU TRAGO UM RECIBO.', action = function(c)
            local e = c.battle and c.battle.beatSpeaker
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}

-- C04-02 — equipe de manutenção na interdição.
Talks.nodes.equipeAbertura = {
    title = 'EQUIPE', voice = 'equipe', lines = {
        'A interdição cobre essa ala. Água parada é mais segura que água solta.',
        'Não é pessoal. É o laudo.',
    }, options = {
        {label = 'EU LI O ESQUEMA DO CANAL.', action = function(c)
            local e = c.battle and c.battle.beatSpeaker
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}

-- C05-02 — vigias do abrigo: guardam camas, não portas.
Talks.nodes.vigiaAbertura = {
    title = 'VIGIA', voice = 'ranger', lines = {
        'Aqui guardo camas, não portas.',
        'Tem gente dormindo de verdade atrás de mim. Conta com isso.',
    }, options = {
        {label = 'EU NÃO VIM PELAS CAMAS.', action = function(c)
            local e = c.battle and c.battle.beatSpeaker
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}

-- C05-Q1 — o ajudante no duelo combinado: não-letal por definição.
Talks.nodes.dueloAbertura = {
    title = 'AJUDANTE', voice = 'ajudante', lines = {
        'Duelo é com regra: para quando o primeiro cair, sem segunda parte.',
        'O anfitrião assiste. Eu cumpro o papel — você cumpre o seu.',
    },
}

-- B02-01 — Janda: a parede que testa a rota dela.
Talks.nodes.jandaAbertura = {
    title = 'JANDA', voice = 'janda', mood = 'tense', lines = {
        'Mais um estrangeiro na rota. Você não é da equipe.',
        'A saída aqui não abre pra promessa — abre pra prova.',
    }, options = {
        {label = 'EU CONFERI A SAÍDA. ELA CAI.', action = function(c)
            local e = c.battle and c.battle.beatSpeaker
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}
Talks.nodes.jandaMetade = {
    title = 'JANDA', voice = 'janda', lines = {
        'A escora que você descreveu não cede tão fácil. Nem eu.',
        'Se a rota é segura de verdade, mostra. Palavra não sustenta teto.',
    },
}
Talks.nodes.jandaEntrega = {
    title = 'JANDA', voice = 'janda', mood = 'soft', lines = {
        'Pra onde você tá olhando ainda tá de pé. Isso é raro.',
        'Mostra o traçado — se ele segura o teto, eu abro a passagem.',
    },
}

-- B03-01 — Rute: a etiqueta antes da pergunta.
Talks.nodes.ruteAbertura = {
    title = 'RUTE', voice = 'rute', mood = 'tense', lines = {
        'Tudo aqui tem registro. Inclusive sua presença.',
        'O que você carrega e de quem era — a avaliação decide.',
    }, options = {
        {label = 'TENHO O RECIBO.', action = function(c)
            local e = c.battle and c.battle.beatSpeaker
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}
Talks.nodes.ruteMetade = {
    title = 'RUTE', voice = 'rute', lines = {
        'Avaliada a situação: piorando.',
        'Recibo, testemunha, etiqueta — me dá um papel que encerre isso.',
    },
}
Talks.nodes.ruteEntrega = {
    title = 'RUTE', voice = 'rute', mood = 'soft', lines = {
        'O recibo fecha a conta. O resto a gente discute.',
        'Confere a etiqueta direito — a disputa encerra aqui.',
    },
}

-- B04-01 — Ivo: o ruído que ele não entrega.
Talks.nodes.ivoAbertura = {
    title = 'IVO', voice = 'ivo', mood = 'tense', lines = {
        'Você ouviu esse ruído? Ninguém escuta as comportas como eu.',
        'A água não fica de um lado porque alguém pediu — fica porque eu mantenho.',
    }, options = {
        {label = 'EU OUVI. MOSTRA ONDE.', action = function(c)
            local e = c.battle and c.battle.beatSpeaker
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}
Talks.nodes.ivoMetade = {
    title = 'IVO', voice = 'ivo', lines = {
        'O ruído não para. Não consigo te entregar isso.',
        'Quem opera errado afoga mais do que quem não opera.',
    },
}
Talks.nodes.ivoEntrega = {
    title = 'IVO', voice = 'ivo', mood = 'soft', lines = {
        'Você ouviu o estalo do mesmo jeito. Isso ninguém falsifica.',
        'O esquema tá na sua mão. Opera direito.',
    },
}

-- P01-E04 — Runa na grade: o confronto opcional. A prova é consensual —
-- ela a aceita como resposta legítima, não como agressão. Entrada
-- reconhecível (nunca emboscada), desfecho sempre não-letal.
Talks.nodes.runaDesafio = {
    title = 'RUNA', voice = 'runa', mood = 'tense', lines = {
        'Você quer provar que pode passar. Então prova — com regra.',
        'A grade abre pra quem vence a prova. Ou pra quem entende que não precisa dela.',
    }, options = {
        {label = 'ACEITO O DESAFIO.', action = function(c)
            c.data.flags.runaConfronto = true
            return true
        end},
        {label = 'PASSAR — SEM LUTA', lines = {
            'Então a gente conversa. A grade decide depois da resposta.',
        }},
        {label = 'SAIR'},
    },
}
-- Rendição: ela perde a prova e reconhece.
Talks.nodes.runaRendicao = {
    title = 'RUNA', voice = 'runa', mood = 'soft', lines = {
        'Pronto. A prova era minha — você já passou dela.',
        'A grade se rende a quem luta direito. Abre.',
    },
}
-- Acordo: a prova bastou antes do fim.
Talks.nodes.runaAcordo = {
    title = 'RUNA', voice = 'runa', mood = 'soft', lines = {
        'Prova suficiente. Passa — a resposta certa não precisa de mais golpe.',
    },
}
-- Derrota: a grade fica fechada, sem enterro.
Talks.nodes.runaDerrota = {
    title = 'RUNA', voice = 'runa', lines = {
        'Foi prova, não enterro. A grade fica fechada até a resposta certa.',
        'Volta quando souber por que levantou o arco.',
    },
}
-- Beat de abertura da arena: ela viu você chegar — mãos primeiro.
Talks.nodes.runaAbertura = {
    title = 'RUNA', voice = 'runa', mood = 'tense', lines = {
        'As mãos primeiro. Depois a pergunta.',
        'Se é prova, prova direito.',
    },
}
Talks.nodes.runaMetade = {
    title = 'RUNA', voice = 'runa', lines = {
        'Você luta de verdade. Isso não é resposta — mas conta.',
    },
}
Talks.nodes.runaEntrega = {
    title = 'RUNA', voice = 'runa', mood = 'soft', lines = {
        'Chega. Você venceu a parte que importa.',
        'A grade abre pra quem podia matar e não quis.',
    },
}

-- B05-01 — Beltran: o anfitrião que não sai do centro.
Talks.nodes.beltranAbertura = {
    title = 'BELTRAN', voice = 'beltran', mood = 'dark', lines = {
        'A plateia já teve um morto essa semana. Um duelo é mais barato.',
        'Bem-vinda aos Salões. Escolha o papel — convidada ou cenário.',
    }, options = {
        {label = 'O SHOW ACABA AQUI.', action = function(c)
            local e = c.battle and c.battle.beatSpeaker
            if e then e.convince = (e.convince or 0) + 1 end
            return true
        end},
        {label = 'SAIR'},
    },
}
Talks.nodes.beltranMetade = {
    title = 'BELTRAN', voice = 'beltran', lines = {
        'A cortina não desce no meio do ato. Nem pra você.',
        'O dano continua ocultado? Continua. Mas você já viu a cortina por dentro.',
    },
}
Talks.nodes.beltranEntrega = {
    title = 'BELTRAN', voice = 'beltran', mood = 'dark', lines = {
        'Que seja um final à altura. Maestro, cortina.',
        '...e silêncio.',
    },
}

-- MAPA ENCONTRO → NODE (proposta de wiring — def.beats nos defs, §7):
--
-- Encontro    Abertura              Rachadura            Entrega (mercy)
-- C02-01      acessoAbertura        —                    —
-- C02-02      entulhoAbertura       —                    —
-- C02-03      cobradorAbertura      —                    —
-- C03-01      guardaAbertura        rangerMetade         rangerEntrega
-- C03-02      (sem falante)         —                    —
-- C03-Q01     entulhoAbertura       —                    —
-- C04-01      (sem falante)         —                    —
-- C04-02      equipeAbertura        rangerMetade         rangerEntrega
-- C04-Q01     (sem falante)         —                    —
-- C05-01      (sem falante)         —                    —
-- C05-02      vigiaAbertura         rangerMetade         rangerEntrega
-- C05-Q1      dueloAbertura         —                    —
-- B02-01      jandaAbertura         jandaMetade          jandaEntrega
-- B03-01      ruteAbertura          ruteMetade           ruteEntrega
-- B04-01      ivoAbertura           ivoMetade            ivoEntrega
-- B05-01      beltranAbertura       beltranMetade        beltranEntrega
--
-- Gatilhos sugeridos: abertura={when='start'}, metade={when={hpBelow=.5},
-- once=true}, entrega={when='mercy', once=true}. 'cobradorAbertura' cobre
-- o ranger de C02-03; o dasher cobrador de C03-Q01 fica sem beat próprio
-- (a cobrança é do ranger). Crawler/husk sem nodes: verbal=false.

return Talks
