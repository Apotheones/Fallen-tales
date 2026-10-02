# Plano de campanha — A Cidade Que Me Enterrou

Índice do pacote de design, 02/10/2026. A premissa, dez destinos, exploração livre, arena separada, busca de recursos e dois finais vêm das escolhas do usuário. Nomes, cenas, profissão, regras detalhadas do pacto e combate por turnos são propostas coordenadas para revisão. Este pacote não implementa mudanças no jogo.

Leia primeiro o [contexto aprovado](CONTEXTO_REIMAGINACAO.md) e a [base comum](BASE_NARRATIVA.md). O [tratamento](A_CIDADE_QUE_ME_ENTERROU.md) apresenta a história; as fichas abaixo definem situações jogáveis. [Cenas de revelação e finais](CENAS_REVELACAO_E_FINAIS.md) foram escritas junto das expedições para preparar seus acontecimentos com antecedência. A [orientação para Devin](GUIA_IMPLEMENTACAO_DEVIN.md) liga o design ao projeto atual.

O [guia de escrita para Devin](GUIA_ESCRITA_DEVIN.md) orienta todos os textos exibidos: personalidade única por personagem, vozes próprias, português brasileiro, cenas, escolhas, descrições e revisão editorial.

## 1. O fio da campanha

Você quer voltar para alguém. O refúgio precisa de ferramentas, água, abrigo e mobiliário. Buscar esses recursos nas ruínas coloca você diante de pessoas que conheceram seu trabalho e seu amor; voltar transforma uma comunidade com a qual começa a conviver. As contradições sobre sua morte tornam a curiosidade pessoal uma investigação. A prova do assassinato muda suas relações; a notícia recente de Lia torna concreta a vida que ainda pode recuperar.

Ele não esqueceu a perseguição. O jogador aprende o passado por reconhecimentos, conversas e exploração. Aurel e Bento respondem a perguntas diretas antes da revelação completa. A última escolha preserva vidas por meio do sacrifício definitivo ou restitui sua vida, mata os vinculados e permite o reencontro real com Lia.

## 2. Dependências e liberdade

| Destino | Condição principal de acesso | O que viabiliza depois |
| --- | --- | --- |
| 1 | Nova campanha | Hub, equipamento e destinos 2/3 |
| 2 | Chegada ao hub | Ferramentas e traçado de manutenção para 4 |
| 3 | Chegada ao hub | Peças do forno e rota dos salões para 5 |
| 4 | Resolução principal de 2 | Drenagem do acesso inferior e identificação da Fundação |
| 5 | Resolução principal de 3 | Estruturas do acesso superior e confirmação do alojamento |
| 6 | Resoluções principais de 4 e 5 | Registro contraditório; abre 7/8 |
| 7 | Descoberta principal de 6 | Peças e localização da passagem exterior |
| 8 | Descoberta principal de 6 | Prova do crime, instrução do pacto e reação imediata do hub |
| 9 | Resoluções principais de 7 e 8 | Passagem restaurada, notícia de Lia e marco do rito identificado |
| 10 | Resolução principal de 9 | Acesso à decisão após resolver Aurel |

Assim, 2/3, 4/5 e 7/8 admitem ordens diferentes. Não exigir concluir 3 para ir a 4, nem 2 para ir a 5. Subquests, amizade, perdão e número de chefes mortos não são condições de progresso. Recusar uma reunião no hub não cancela fatos descobertos.

Destinos podem aparecer desde cedo no hub com a razão legível de sua indisponibilidade. Retornar sem concluir conserva progresso. Entrar no mapa 10 permite voltar; só confirmar o ato final encerra a campanha.

## 3. As dez fichas

Cada ficha inclui direção visual, materiais, paleta, marcos, arte existente/nova, montagem garantida, etapas jogáveis, personagens, diálogos, subquests, encontros e alterações no hub. A direção visual orienta desenhos futuros; não afirma que os novos sprites já existem.

| Ficha | Missão e descoberta | Personagens e encontro principal | Retorno ao hub |
| --- | --- | --- | --- |
| [1 — Colina dos Sepultados](mapas/01_COLINA.md) | Recuperar pertences; casaco lembra o cuidado de Lia; vedação partida explica o despertar | Doro, Runa, Teca; resolver receio da vigia | Baú, descanso e escolha das primeiras expedições |
| [2 — Oficinas de Dentro](mapas/02_OFICINAS.md) | Ferramentas e saída dos trabalhadores; Brina lembra a promessa de voltar | Brina, Neco, Janda; controle dos trabalhadores | Bancada, moradores conforme convite e manutenção do reservatório |
| [3 — Mercado das Escoras](mapas/03_MERCADO.md) | Peças do forno; primeiro trabalho e atrito do casal | Ema, Rute, Bento; reconhecimento de autoria e acesso ao estoque | Cozinha, refeição e rota dos salões |
| [4 — Jardins do Reservatório](mapas/04_RESERVATORIO.md) | Água e drenagem; hábitos e descanso do casal | Mara, Ivo, Sabela; autoridade sobre a comporta | Água limpa e acesso inferior à Fundação |
| [5 — Salões da Vigília](mapas/05_SALOES.md) | Abrigo e estrutura; briga, escuta e reconciliação | Cira, Beltran, Nilo; espetáculo versus segurança | Privacidade, ampliação e acesso superior à Fundação |
| [6 — Quartos da Fundação](mapas/06_ALOJAMENTOS.md) | Mobiliário escolar; casa planejada e partida falsificada | Dalva, Geraldo, Teca; controle de provas | Escola e perguntas concretas sobre o crime |
| [7 — Armazéns da Partida](mapas/07_ARMAZENS.md) | Peças da passagem; promessa e atraso na despedida | Joana, Silvério, Doro; prioridade de despacho | Preparação da saída e planos de futuro |
| [8 — Necrópole dos Nomes](mapas/08_NECROPOLE.md) | Provas, autoria e instrução do pacto; promessa interrompida | Rima, Edras, dirigentes no retorno; acesso aos registros | Verdade compartilhada e responsabilização conforme atos |
| [9 — Fronteira da Volta](mapas/09_FRONTEIRA.md) | Restaurar passagem; saber de Lia viva e testar o limite corporal | Lena, Calo; segurança e controle da operação | Preparativos e despedidas, sem novas tarefas de rotina |
| [10 — Túmulo Primeiro](mapas/10_TUMULO.md) | Recuperar autoridade sobre a própria vida | Aurel, Doro, Teca; remover a interdição do executor | Epílogo escolhido, respeitando vínculos e quests |

O [hub inicial](HUB_INICIAL.md) descreve planta, primeira chegada, moradores, serviços e evolução. O [modelo de ficha](mapas/FICHA_MAPA.md) permite manter o mesmo contrato nas revisões.

## 4. Onde e como entra combate

Exploração livre até uma ameaça visível ou disputa explícita. A transição abre uma arena separada; resolver devolve ao lugar com consequências. Não há encontros aleatórios por passos.

A [proposta de combate](COMBATE_PROPOSTA.md) usa intenções anunciadas, movimento de até duas células e uma ação por turno. Arco, defesa, terreno, item ou acordo produzem escolhas de posição e compromisso. Sem cronômetro. Conversa não é uma barra social: muda o conflito quando responde à necessidade real do adversário. Preparar uma saída segura pode suspender ataques para inspeção.

| Trecho | Perfil proposto |
| --- | --- |
| 1 | Runa como único encontro de apresentação; pode ser resolvido conversando |
| 2–7 | 2–3 encontros comuns mais um chefe, intercalados com exploração e diálogos; um terceiro comum pode pertencer a ramal opcional |
| 8–9 | Até dois comuns mais um chefe; menor pressão para dar espaço às descobertas |
| 10 | Somente Aurel; vencer não escolhe o final |

O ritmo intermediário foi escolhido pelo usuário. A redução no começo/final é proposta. Cada ficha associa gatilho, composição, terreno, retirada e persistência às suas etapas. Um encontro previsto pode ser evitado pela alternativa descrita. Subquests não acrescentam sistematicamente mais duas lutas ao orçamento.

## 5. Quests e continuidade

As fichas desenvolvem dois arcos opcionais por região, incluindo continuações de personagens do hub. Brina busca autoria; Neco quer partir; Ema recupera identidade comercial; Bento aprende a entregar poder e confessar; Mara negocia o jardim; Sabela aprende a decidir com moradores; Cira/Nilo constroem uma apresentação; Dalva reorganiza um quarto; Teca reaproveita uniformes; Joana devolve bagagem; Doro planeja trabalho fora; Rima recupera nomes; Edras responde pela própria escrita; Calo preserva autoria; Doro/Teca encerram seus vínculos na região final.

Recusar uma quest não significa aceitá-la silenciosamente. O reencontro reconhece trabalho feito, confronto, ausência e compromisso quebrado. Reparação exige atos: descobrir a prova não faz Bento entregar estoques automaticamente. Informação principal não depende de aceitar um NPC no hub ou terminar um arco opcional.

Moradia permanente inclui acolhimento com selo. Visitas não vinculam automaticamente uma pessoa. Sair fisicamente não apaga o selo. Os custos finais abrangem todos os vinculados vivos, inclusive inocentes; preservar vidas não ressuscita mortes anteriores. A base e as cenas explicam essa regra antes da confirmação.

## 6. Desenho e geração

Garantir entrada, descoberta essencial, interação principal, confronto e retorno. Variar corredores, obstáculos, ramos opcionais e conexões secundárias entre esses lugares. Conservar a região gerada durante a campanha. Não sortear a existência do registro que explica o final.

A arena preserva a identidade do local, sem copiar todas as coordenadas da exploração: escoras, divisórias, canais e armários sustentam decisões próprias. Mudanças relevantes retornam ao cenário. Diálogo, inventário e pausa suspendem hostilidade.

## 7. Próximo trabalho

O pacote está completo como design de campanha para revisão. O primeiro recorte jogável recomendado é chegada → hub → Oficinas → retorno, com uma arena comum e Janda. Antes de produzir dez regiões, verificar movimento, previsibilidade das intenções, negociação, retomada sem duplicação e reação do hub. A sequência e os limites estão no [guia para Devin](GUIA_IMPLEMENTACAO_DEVIN.md); as etapas de produção aprovadas, incluindo combate por turnos, save em disco e mapas autorais, estão em [MEGAPLAN_CAMPANHA.md](MEGAPLAN_CAMPANHA.md).

Nome do protagonista/hub, natureza final da catástrofe, aprovação dos nomes propostos, função mecânica das cartas e valores de combate/economia continuam decisões criativas abertas. Elas não impedem avaliar o fluxo e o conflito já descritos.
