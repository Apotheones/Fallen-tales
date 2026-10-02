-- Authored lore data: names, lines, dialogue topics, cards, intros. Data only.
local Lore = {}

Lore.npcs = {
    merchant = {name = "AMÂNCIO, O ANDARILHO"},
    keeper = {name = "ODETE, A ZELADORA"},
}

Lore.lines = {
    merchant = {
        first = {
            "Outro capuz nas Ruínas. Faz tempo que ninguém desce com um arco inteiro.",
            "Sou Amâncio. Também fui peregrino — parei no primeiro andar e a mochila virou balcão.",
            "O estoque ainda está no fundo da mochila, mas a conversa é de graça.",
        },
        floor = {
            [1] = {"Primeiro andar. O Guardião ainda cumpre a última ordem da Regente: ninguém passa."},
            [2] = {"Desceu de novo? O Demolidor quebrou esta casa tentando libertar os ecos na marra."},
            [3] = {"Último andar. A Regente de Âmbar ainda canta ecos novos dentro do selo."},
        },
        again = {"As Ruínas mudam de lugar, mas quem avisa o perigo nunca mente."},
    },
    keeper = {
        first = {
            "São e salvo no refúgio, viajante. Sente perto do fogo — o eco deste santuário ainda é gentil.",
            "Sou Odete, zeladora desde antes do selo. Quando a Regente descansar, desço também.",
        },
        again = {"O fogo continua aceso. Descanse o quanto precisar."},
    },
}

Lore.options = {
    merchant = {
        {label = "O QUE SÃO AS RUÍNAS?", lines = {
            "Um templo que guardava os mortos como ecos cantados em jade.",
            "A Regente não aceitou despedidas. Selou tudo em âmbar.",
            "Eco preso não vive: repete o último instante, para sempre."}},
        {label = "QUEM É A REGENTE?", lines = {
            "Uma governante que amou os mortos mais do que suportava perdê-los.",
            "Mandou trocar o jade pelo âmbar e chamou a prisão de eternidade.",
            "Está no fundo até hoje, contando ecos como quem conta filhos."}},
        {label = "QUEM GUARDA A DESCIDA?", lines = {
            "Três selos, três sentinelas. O Guardião cumpre a última ordem no primeiro andar.",
            "No segundo, o Demolidor quebrou-se tentando abrir os selos na marra.",
            "No fundo espera a própria Regente. Passar por ela encerra a expedição."}},
        {label = "POR QUE VOCÊ FICOU?", lines = {
            "Desci atrás da minha irmã. Ela virou eco no segundo andar.",
            "Eu a ouço nas paredes. Vender mapa é o meu jeito de visitá-la."}},
        {label = "QUEM DEIXOU ESSAS CARTAS?", lines = {
            "A primeira expedição e os sacerdotes de jade. Bilhetes que ninguém recolheu.",
            "Se achar uma, guarde. Os mortos desta casa gostam de quem lê."}},
        {label = "SAIR"},
    },
    keeper = {
        {label = "O QUE É ESTE LUGAR?", lines = {
            "O último santuário que o âmbar não alcançou.",
            "A cura não vem de mim — vem do eco que ainda lembra por que existia."}},
        {label = "O QUE SÃO OS ECOS?", lines = {
            "Despedidas que ficaram. As melhorias que você colhe são memórias que escolheram ajudar.",
            "Nas paredes eles repetem o instante da prisão. Por isso atacam."}},
        {label = "QUEM ERA A REGENTE?", lines = {
            "Cantava mais bonito que qualquer sacerdote. O luto estragou o canto.",
            "Trocou o jade pelo âmbar: bonito por fora, imóvel por dentro."}},
        {label = "O QUE VOCÊ FAZIA ANTES?", lines = {
            "Zelava os santuários deste andar. Cantava para os ecos novos aprenderem o caminho.",
            "Quando o selo desceu, só este fogo ficou de pé. Fiquei com ele."}},
        {label = "COMO SE LIBERTA UM ECO?", lines = {
            "Quebrando o selo que o prende. Cada guardião caído é uma porta aberta.",
            "E escutando. Um eco solto sem ouvido vira violeta de dor."}},
        {label = "SAIR"},
    },
}

Lore.bossIntros = {
    warden = {"GUARDIÃO DOS ECOS", "A ordem é antiga e eu ainda a cumpro: nenhum capuz desce."},
    demolisher = {"O DEMOLIDOR DA CÂMARA", "Quebrei esta casa procurando a saída deles. Você não vai me impedir."},
    regent = {"A REGENTE DE ÂMBAR", "Nenhuma despedida escapa do meu selo. Nem a sua."},
}

-- Collectible letters of the first expedition and the temple priests.
Lore.cards = {
    {id = 'carta_cartografo_i', title = 'CARTA DO CARTÓGRAFO I', lines = {
        'Mãe: cheguei às Ruínas dos Ecos. O templo afundou, mas as portas respondem.',
        'Desenhei o primeiro andar. Os guardas repetem rondas de séculos atrás.',
        'Se o mapa voltar sem mim, dê meu nome ao eco mais gentil que encontrar.'}},
    {id = 'registro_porteiro', title = 'REGISTRO DO PORTEIRO', lines = {
        'A ordem da Regente é uma só: nenhum capuz desce, nenhum eco sobe.',
        'Cumpri trezentos invernos nesta porta. Cumprirei os que faltarem.'}},
    {id = 'relato_primeira_descida_i', title = 'RELATO DA PRIMEIRA DESCIDA I', lines = {
        'Primeira noite. As paredes repetem palavras que não são para nós.',
        'Um eco não sabe fazer outra coisa. Os avisos deles nunca mentem.'}},
    {id = 'lista_provisoes', title = 'LISTA DE PROVISÕES', lines = {
        'Vinte picaretas, corda, pão escuro, óleo para três luas.',
        'O ouro de oferenda fica por último. Não se gasta o que é dos mortos.'}},
    {id = 'aviso_peregrinos', title = 'AVISO AOS PEREGRINOS', lines = {
        'Peregrino: os ecos desta casa são despedidas guardadas, não tesouro.',
        'Ouça com respeito. Quem rouba memória acorda o que dormia.'}},
    {id = 'diario_pedreiro', title = 'DIÁRIO DO PEDREIRO', lines = {
        'Dia doze. Rebati cada parede que o cartógrafo marcou no mapa.',
        'O terceiro golpe sempre abre. O templo obedece até morto.'}},
    {id = 'carta_cartografo_ii', title = 'CARTA DO CARTÓGRAFO II', lines = {
        'O segundo andar não obedece ao desenho do primeiro. Salas mudam de lugar.',
        'Parei de contar portas. Contei os avisos violeta: eles não erram.'}},
    {id = 'relato_primeira_descida_ii', title = 'RELATO DA PRIMEIRA DESCIDA II', lines = {
        'Perdemos dois no covil do elite. O eco dele repetiu a caça até o fim.',
        'Achamos um santuário vivo. A zeladora cantou e o fogo respondeu.'}},
    {id = 'oracao_jade', title = 'ORAÇÃO DE JADE', lines = {
        'Jade guarda a voz que a boca não pôde dizer.',
        'Que todo adeus seja canto, e todo canto encontre quem partiu.'}},
    {id = 'memorando_ambar', title = 'MEMORANDO DE ÂMBAR', lines = {
        'Por ordem da Regente: os ecos não serão mais libertados.',
        'Âmbar sela onde jade cantava. Assinado: o conselho, sob protesto.'}},
    {id = 'anotacoes_sacerdote', title = 'ANOTAÇÕES DO SACERDOTE', lines = {
        'Um eco preso não vive: repete. A Regente chama repetição de eternidade.',
        'Rezei por ela. Rezei mais pelos que ela guarda.'}},
    {id = 'notas_demolidor', title = 'NOTAS DO DEMOLIDOR', lines = {
        'Se a porta não abre na palavra, abre na marra. Trago o martelo maior.',
        'Quebrei o selo da câmara leste. Não era saída — era mais casa.'}},
    {id = 'bilhete_acampamento', title = 'BILHETE DO ACAMPAMENTO', lines = {
        'Quem achar isto: descemos mais um nível. O fogo da zeladora ainda arde.',
        'Se não voltarmos, digam que os ecos cantaram. Não digam que sofremos.'}},
    {id = 'ultima_ordem_regente', title = 'ÚLTIMA ORDEM DA REGENTE', lines = {
        'Nenhum eco deixa esta casa. Nenhuma despedida será a última.',
        'Selai tudo em âmbar. O que não parte não pode morrer.'}},
    {id = 'sinal_violeta', title = 'O SINAL VIOLETA', lines = {
        'Violeta é a cor do eco que apodreceu na prisão.',
        'Não é maldade: é dor que esqueceu o resto da oração.'}},
    {id = 'testamento_ambar', title = 'TESTAMENTO DE ÂMBAR', lines = {
        'Eu, que retenho todos, não sei reter a mim mesma.',
        'Quando o último eco se libertar, que alguém cante o meu nome e solte.'}},
    {id = 'promessa_viajante', title = 'A PROMESSA DO VIAJANTE', lines = {
        'Juro pelo capuz e pelo arco: desço até o fundo desta casa.',
        'Se o selo me tomar, outro toma a flecha. Os ecos vão sair.'}},
    {id = 'ultima_pagina', title = 'A ÚLTIMA PÁGINA', lines = {
        'Não achamos saída nem culpados. Só despedidas engarrafadas.',
        'Capuz que lê isto: termine por nós. Cante os ecos para fora.'}},
}

-- Carved wall texts readable with E; keyed by room inscription id.
Lore.inscriptions = {
    entrance = {title = 'INSCRIÇÃO', lines = {
        'Aqui os mortos viraram canto, e o canto virou casa.',
        'Pise leve: cada pedra ainda lembra um nome.'}},
    chapel = {title = 'INSCRIÇÃO', lines = {
        'Neste altar, jade recebia a última palavra de cada boca.'}},
    vault = {title = 'INSCRIÇÃO', lines = {
        'O que o âmbar guarda, nem o tempo leva.'}},
    gate = {title = 'INSCRIÇÃO', lines = {
        'Pela última ordem, esta porta não conhece retorno.'}},
    kiln = {title = 'INSCRIÇÃO', lines = {
        'Aqui o âmbar foi vertido sobre as vozes. O fogo pedia perdão.'}},
    crypt = {title = 'INSCRIÇÃO', lines = {
        'Os que cantam embaixo não são mortos. São despedidas adiadas.'}},
    deep = {title = 'INSCRIÇÃO', lines = {
        'No fundo, a Regente ainda conta seus ecos como quem conta filhos.'}},
}

-- Only these inscriptions award a card when read; the rest are pure lore.
Lore.inscriptionCard = {entrance = true, crypt = true, deep = true}

-- One door per floor is sealed: violet work of the Regente. It opens for the
-- offering (gold) or to the pickaxe — the only route cost in the ruins.
Lore.seal = {
    title = "PORTA SELADA",
    lines = {"Um selo de violeta trava a passagem.",
        "O metal responde à oferenda — ou cede à força bruta."},
}
function Lore.sealOptions(game)
    local options = {}
    if (game.gold or 0) >= 3 then
        options[#options + 1] = {label = "PAGAR 3 OURO", action = function(g)
            g.gold = g.gold - 3
            g:unsealDoor()
            return true
        end}
    end
    if (game.pickaxes or 0) > 0 then
        options[#options + 1] = {label = "FORÇAR (1 PICARETA)", action = function(g)
            g.pickaxes = g.pickaxes - 1
            g:unsealDoor()
            return true
        end}
    end
    options[#options + 1] = {label = "SAIR"}
    return options
end

-- Voice-blip pitch per speaker: Amâncio is worn and low, Odete sings high,
-- bosses rumble below the choir and carved stone stays neutral.
Lore.voices = {merchant = .72, keeper = 1.32, boss = .5, inscription = .95}

return Lore
