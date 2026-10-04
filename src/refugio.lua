-- Interações do novo arco local; não substitui os diálogos da campanha legada.
-- Revisão Vigia: Refugio.hotspot constrói o node a cada interact — os side
-- effects dentro do build ficam limitados a efeitos binários/idempotentes
-- (flag alta, syncRefugio, cura cheia). Efeito que acumula ou consome NÃO
-- pode morar aqui: vai para spot.use no def da região (roda antes do node).
local LoreC = require('src.campaign_lore')
local Refugio = {}
local function node(title, lines, options)
    return {title = title, voice = 'inscription', lines = lines, options = options}
end

function Refugio.ready(c)
    return c:flag('casaco') and c:stepDone('P01-E03')
        and c:flag('preparoRefugio') and c:flag('aguaRefugio')
end

function Refugio.hotspot(c, spot)
    local id = spot.id
    if id == 'preparoRefugio' then
        if not c:flag('casaco') then
            return node('BANCADA', {'Sem o arco e a ferramenta, a bancada não tem o que segurar. Busque seus pertences no depósito da cripta antes.'})
        end
        c.data.flags.preparoRefugio = true
        c:syncRefugio()
        return node('PRONTO PARA CAMINHAR', {
            'Você aperta o cabo da picareta e revê a corda do arco. O casaco de Lia fica por cima da bolsa, onde sempre ficou.',
            c:flag('aguaRefugio') and 'Ferramenta firme, água correndo. O Marco espera na praça.'
                or 'A bancada volta ao uso. Agora a água: a cisterna fica na rua baixa, ao sul da praça.',
        })
    elseif id == 'aguaRefugio' then
        if not c:flag('preparoRefugio') then
            return node('CISTERNA', {'Folha e areia prenderam a saída. Sem a ferramenta pronta, o encaixe não sai — arrume o equipamento na forja, a leste.'})
        end
        local repaired = c:flag('aguaRefugio')
        c.data.flags.aguaRefugio = true
        c:syncRefugio()
        return node('ÁGUA PARA QUEM FICA', repaired and {
            'A água corre pelo encaixe limpo. Quem vier buscar nem vai saber que ela parou.',
        } or {
            'Você solta o encaixe, tira as folhas e assenta a pedra de volta. A primeira água vem escura — a segunda já dá pra ver o fundo.',
            'Água pra cozinha, pras camas, pra horta. Volta ao Marco na praça: o primeiro trabalho aqui tá feito.',
        })
    elseif id == 'marcoRefugio' then
        if c:flag('refugioConcluido') then
            return node('MARCO DOS NOMES', {'REFÚGIO e ANDLAR acesos na pedra. Os caminhos de dentro se fazem a pé; os de fora, por ela.'}, {
                {label = 'VIAJAR PARA ANDLAR', action = function(game) game:travel('andlar', 'hub'); return true end},
                {label = 'FICAR', action = function() return true end},
            })
        end
        if Refugio.ready(c) then
            return node('ANTES DA PARTIDA', {
                'A ferramenta tá pronta. A cisterna voltou. Pela primeira vez desde a cova, você deixa uma coisa funcionando atrás de você.',
                'Sob a poeira do nome, ANDLAR espera acender. O Refúgio fica aqui quando você voltar.',
            }, {
                {label = 'CONCLUIR E ME DESPEDIR', action = function(game)
                    game.data.flags.refugioConcluido = true
                    game:completeStep('REFUGIO-FIM')
                    game:syncRefugio()
                    game:effect('sealBreak', 20, 18, nil, true)
                    game:notify('ANDLAR acendeu no Marco. Sua primeira partida está pronta.', 5)
                    game:checkpoint()
                    return true
                end},
                {label = 'AINDA QUERO FICAR', action = function() return true end},
            })
        end
        local pending = {}
        if not c:flag('casaco') then pending[#pending + 1] = 'Busque seus pertences no depósito da cripta.' end
        if not c:stepDone('P01-E03') then pending[#pending + 1] = 'Acerte a passagem com Runa na grade da cripta.' end
        if not c:flag('preparoRefugio') then pending[#pending + 1] = 'Firme o equipamento na bancada da forja, a leste.' end
        if not c:flag('aguaRefugio') then pending[#pending + 1] = 'Solte o encaixe da cisterna na rua baixa, ao sul da praça.' end
        table.insert(pending, 1, 'ANDLAR ainda dorme na pedra. Antes de partir, deixe aqui um começo que consiga andar sem você.')
        return node('MARCO DOS NOMES', pending)
    elseif id == 'retornoAndlar' then
        return node('MARCO DE RETORNO', {'O nome do Refúgio segue aceso — a pedra sabe o caminho de volta.'}, {
            {label = 'VOLTAR AO REFÚGIO', action = function(game) game:travel('hub', 'andlar'); return true end},
            {label = 'FICAR', action = function() return true end},
        })
    elseif id == 'placaAndlar' then
        return node('ANDLAR', {'A beira de Andlar. A estrada some no mato — por ora, só este primeiro chão lembra o caminho do resto.'})
    elseif id == 'placaRotas' then
        return node('OS NOMES DA PEDRA', {
            'CRIPTA E COLINA — pela escadaria até o mirante, seguindo oeste. Esse caminho é do próprio Refúgio.',
            c:flag('refugioConcluido') and 'ANDLAR — nome aceso. Toca a pedra pra viajar.'
                or 'ANDLAR — nome apagado. Ferramenta na forja, cisterna livre, despedida no Marco.',
        })
    elseif id == 'miranteRefugio' then
        c.panoramaTime = 5
        return node('O REFÚGIO, VISTO DE CIMA', {'A pedra toma o centro da praça. Capela e cozinha à esquerda; camas, forja e escola à direita — duas ruas descem e voltam a se encontrar.', 'No fundo do vale, a cidade antiga mostra mais janelas do que luzes. Alguém sacode um pano numa varanda.'})
    elseif id == 'descansoRefugio' then
        c.player.health.current = c.player.health.max
        return node('CASA DAS CAMAS', {'Você descansa. O arco fica à mão; o casaco, dobrado junto à cama.', 'Quando acorda, as ruas seguem nos mesmos lugares — e ninguém bateu na porta.'})
    elseif id == 'hortaRefugio' then
        return node('HORTA DA ESCOLA', {'Mudas enfileiradas em caixotes de madeira, fileira de mão feita. As marcas de altura na parede ainda não chegam à janela.'})
    elseif id == 'terracoRefugio' then
        return node('TERRAÇO BAIXO', {'A praça chega aqui por duas ruas. Ouve-se a cozinha, a água e o trabalho — sem enxergar nenhum dos três. E o horizonte, que lá de baixo os telhados escondem.'})
    elseif id == 'refeicaoRefugio' then
        if not c:flag('aguaRefugio') then return node('MESA DA COZINHA', {'Bento guardou o que tinha — mas o almoço espera a água da cisterna.'}) end
        c.player.health.current = c.player.health.max
        return node('À MESA', {'Água limpa, pão quente. Bento larga o prato na mesa e volta pro fogão sem cobrar nada.', 'As forças voltam. O caminho agradece.'})
    elseif id == 'bauRefugio' then
        return node('SEU CANTO', {'Um baú junto às camas. Cabe o casaco, a bolsa e uma volta sem pressa.'})
    elseif id == 'escolaRefugio' then
        return node('ESCOLA DO REFÚGIO', {'Mesas de tamanhos diferentes na mesma sala. Teca deixou a parede mais clara pra quem tá aprendendo a ler.'})
    elseif id == 'cartazRefugio' then
        return node('QUADRO DA PRAÇA', c:flag('refugioConcluido')
            and {'ÁGUA CORRENDO — a cisterna cumpre a semana.',
                'ANDLAR ABERTO — quem for, anota a volta na lousa da praça.',
                'Em letra de criança: a pedra ganhou nome novo.'}
            or {'A CISTERNA PEDE MÃOS — o encaixe prendeu em folha e areia.',
                'A mesa é por ordem de chegada. A pedra mostra o que a casa lembra.'})
    elseif id == 'camasRefugio' then
        if c:flag('refugioConcluido') then
            return node('CAMAS NOMEADAS', {
                'CAMA DE TECA · CAMA DE NILO · CAMA DO VIAJANTE.',
                'A etiqueta da terceira já tem letra: a tua.',
            })
        end
        return node('CASA DAS CAMAS', {
            'Três camas, três cobertores, nenhum nome.',
            'A pensão espera quem fica.',
        })
    elseif id == 'oferendaRefugio' then
        return node('O BANCO DA ENTRADA', c:flag('refugioConcluido')
            and {'A coisa segue no banco. Agora ganhou um bilhete preso embaixo dela: "pra quem for e pra quem voltar".'}
            or {'Um retalho de pano dobrado, um copo de barro. Coisa de quem sentou e esqueceu — ou de quem deixou querendo.', 'A capela guarda o que ninguém pede de volta.'})
    elseif id == 'canteiroRefugio' then
        return node('JARDIM DA CAPELA', c:flag('refugioConcluido')
            and {'A terra preparada ganhou cor. A primeira flor abriu do lado que pega sol de manhã — quem plantou sabia o que fazia.'}
            or {'Terra virada, borda assentada à mão. Alguém preparou uma flor que ainda não pediu pra nascer.'})
    elseif id == 'cabraRefugio' then
        return node('CABRA', {'A cabra levanta a cabeça, mede você de cima a baixo e decide que as ervas da parede interessam mais.', 'Ela não é de ninguém. Chegou um dia e a cerca não convenceu.'})
    elseif id == 'prateleiraRefugio' then
        return node('PRATELEIRA', {'Panelas, potes e tigelas que nunca formaram conjunto. A tigela menor nunca tá no lugar — é a única que todo mundo usa.'})
    end
end

local greetings = {
    doro = {'Usa a bancada. Firma o que vai levar primeiro — a cisterna aguentou anos parada, aguenta mais uma tarde.', 'Quem vai embora e deixa uma coisa em pé volta com a consciência mais leve.'},
    bento = {'Senta que já trago. Tigela na mesa não pergunta nome de ninguém.', 'A água lá de baixo tá presa. Solta ela que eu paro de carregar balde — e você ganha almoço de graça.'},
    teca = {'Camas na rua de cima, escola aqui. Cuido das duas — até aparecer quem queira dividir.', 'Não promete volta pra me agradar. Volta quando puder; a cama não sai do lugar.'},
    sabela = {'As ruas desembocam aqui. A pedra no meio é o Marco — quem vai longe passa por ela.', 'Pra Andlar: ferramenta firme, cisterna livre, despedida no Marco. Nessa ordem, se quiser conselho.'},
    nilo = {'Daqui eu vejo quem desce do mirante antes da pessoa decidir onde vai sentar.', 'Dá a volta pela cozinha que você sai no mesmo lugar. Esse povoado gosta de círculo.'},
    aurel = {'O Marco lembra sozinho. Eu só mantenho os nomes legíveis — alguém precisa tirar o pó das letras.', 'Andlar tá na pedra. O caminho aparece quando a casa te reconhece, não quando eu permito.'},
    runa = {'Da grade eu via só quem passava. Daqui eu vejo onde cada um foi se arrumando.', 'A cripta fica nas suas costas. Não precisa esquecer o caminho — nem olhar pra trás toda hora.'},
    anciao = {'Sento aqui desde que a praça era descampado. O banco esquenta antes do sol — não é à toa.', 'Cada nome aceso é um caminho que voltou a lembrar. A pedra faz isso melhor que a gente.'},
    lavadeira = {'Estendo primeiro, converso depois — pano de quarto não espera ninguém.', 'Roupa no varal é a pensão falando sozinha: tem cama cheia essa semana.'},
    carregador = {'Essa escada ensina o jeito: o pé desce antes da caixa.', 'Já contei cada degrau carregando água. O terceiro range — cuida dele, que ele não cuida de você.'},
    lenhador = {'A lenha do quintal é da forja e do fogão — pega o que precisar, deixa o que puder.', 'Anos cortando e a pilha nunca fica cheia. É o jeito dela de pedir mais.'},
    crianca = {'A pedra tem nome de lugar que nem a Sabela pisou. Eu conto todos quando acabo a lição.', 'Você saiu da cripta? O Nilo diz que quem sai de lá vê o mundo de cima primeiro.'},
}
function Refugio.talk(c, id)
    local lines = greetings[id]
    -- Revisão Vigia: ausência aqui cai silenciosa no hubTalks legado — um
    -- morador do reino sem greeting é provável esquecimento. Warn de dev;
    -- o jogo não quebra (o fallback cobre).
    if not lines then
        print(('[Refugio] greeting ausente para npc "%s" (realm=refugio) — '
            .. 'fallback em LoreC.talk'):format(tostring(id)))
        return nil
    end
    if c:flag('aguaRefugio') and id == 'bento' then lines = {'Ouvi a água correr antes de ver você na rua. Notícia boa chega primeiro.', 'Come antes de sair. Andlar espera sentado.'}
    elseif c:flag('aguaRefugio') and id == 'doro' then lines = {'Água correndo, ferramenta firme. Não é pouca coisa pra um primeiro dia.', 'Quando for, passa na pedra. O caminho de volta fica aqui mesmo.'}
    elseif c:flag('refugioConcluido') and id == 'sabela' then lines = {'ANDLAR acendeu — a praça inteira viu.', 'Quem parte não tranca porta. Volta pela pedra quando precisar.'}
    end
    local person = c.data.people[id]
    if person then person.met = true end
    -- upper() é ASCII-only: figurantes com acento sairiam "ANCIAO"/"CRIANCA";
    -- o registro LoreC.npcs já guarda o nome de exibição correto.
    local display = (LoreC.npcs[id] or {}).name or string.upper(id)
    return {title = display, voice = id, lines = lines}
end

function Refugio.objective(c)
    if c.map.id == 'andlar' then return 'Andlar — explore este primeiro chão; o Marco guarda a volta ao Refúgio.' end
    if not c:flag('casaco') then return 'Cripta — busque seus pertences no depósito a leste do pátio.' end
    if not c:stepDone('P01-E03') then return 'Cripta — acerte a passagem com Runa na grade ao sul.' end
    if not c:stepDone('P01-E04') then return 'Cripta — atravesse a passagem e suba ao mirante do Refúgio.' end
    if not c:flag('preparoRefugio') then return 'Refúgio — firme seu equipamento na bancada da forja, a leste.' end
    if not c:flag('aguaRefugio') then return 'Refúgio — solte o encaixe da cisterna na rua baixa, ao sul da praça.' end
    if not c:flag('refugioConcluido') then return 'Refúgio — encerre o primeiro trabalho e se despeça no Marco da praça.' end
    return 'Refúgio — ANDLAR tá aceso no Marco. Parta quando quiser; você pode voltar.'
end

return Refugio
