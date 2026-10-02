# Arrowfallen — contexto da reimaginação

Atualizado em 02/10/2026. Este documento registra decisões do usuário para o planejamento. Não descreve mudanças já implementadas.

## Direção estabelecida

- Criar uma campanha com início, meio e fim, saindo da estrutura arcade de três fases e três chefes.
- Mundo: um último refúgio depois de uma catástrofe, com inspiração no clima de Dark Souls e na apresentação de personagens, relações e escolhas de Undertale.
- Um hub recorrente permite cuidar do personagem, melhorar status e consultar inventário, itens e cartas coletadas.
- O jogador retorna ao hub ao morrer ou terminar uma região.
- O hub oferece acesso por teleporte a dez regiões. Cada região pode ter chefe, NPCs, quests, escolhas e acontecimentos próprios; a décima conduz ao chefe final.
- A decisão final desejada é salvar todos ou apenas a si mesmo. O significado e o custo dessas alternativas dependem da história que o usuário escolher.
- Reaproveitar o tileset, a apresentação e o trabalho existente de geração de mapas. Atalhos físicos entre todas as regiões não são um requisito.
- NPCs e chefes precisam de relações, cotidiano e conflitos desenvolvidos. A história deve aparecer durante a gameplay.
- Cartas não tornam o protagonista um carteiro nem definem sua missão central.

## Exploração e encontros — esclarecimento mais recente

**A exploração usa movimento livre.** O personagem anda pelo mapa, visita NPCs, lojas e pontos de interesse sem obedecer aos passos do grid de combate. A referência de experiência é a exploração de Undertale. Movimento livre não elimina paredes, colisões ou limites do cenário.

**Ao iniciar um encontro, o jogo muda para uma cena de batalha separada, usando o grid que já temos.** A exploração e a batalha possuem regras de movimento diferentes.

O combate pode ser reinventado, incluindo a possibilidade de turnos com posicionamento tático, tendo South Park: The Fractured But Whole como referência. A troca para turnos é uma possibilidade autorizada, ainda não uma decisão definitiva de implementação.

Enfrentar fisicamente ou conversar com o personagem são possibilidades desejadas. Número de aliados, ordem de turnos, alcance, economia de ações, resolução não letal e papel das cartas permanecem em discussão.

**Ritmo escolhido pelo usuário:** nas regiões intermediárias, 2–3 encontros comuns e um chefe, intercalados com exploração e diálogos. A [proposta concreta de combate](COMBATE_PROPOSTA.md) apresenta um personagem controlável, intenções anunciadas, movimento de até duas células e uma ação por turno, sem cronômetro. Essas regras dão uma base para protótipo e continuam sujeitas à revisão; o ritmo e a separação entre exploração e arena já foram escolhidos.

## Controle criativo e estado das propostas

O usuário escolheu aprofundar **A Cidade Que Me Enterrou**. O protagonista tem passado próprio e um grande amor esperando por ele fora do refúgio. A direção dos finais também foi escolhida: sacrificar a própria vida para salvar os habitantes e preservar o futuro de sua redenção, ou encerrar a maldição, vingar-se e recuperar a vida junto de seu amor.

**Prioridade narrativa mais recente:** conhecer o passado do protagonista e seu grande amor através dos dez mapas, interações com NPCs e exploração. Essa descoberta pessoal organiza a campanha. O pacto acompanha esse fio; não deve ocupar toda a história. O reencontro presencial durante a campanha, sugerido antes, deixa de ser a abordagem principal.

**Estrutura de expedições escolhida:** o assassinato ritual preservou o refúgio enquanto as regiões ao redor foram devastadas. Os moradores pedem recursos para melhorar a base. O jogador visita essas ruínas, encontra personagens e enfrenta os conflitos de cada área; durante a exploração descobre o mundo, seu passado e seu amor. Os recursos voltam ao hub e produzem melhorias, serviços e novas interações. O hub não foi inteiramente destruído pela catástrofe: seus problemas atuais são escassez, manutenção e acolhimento.

Melhorar a comunidade cria vínculos antes da descoberta do assassinato. Alguns moradores foram responsáveis por ele; outros se opuseram, chegaram depois ou eram crianças. O refúgio não constitui um bloco de pessoas com a mesma culpa.

O usuário quer participar das decisões antes de consolidar todos os detalhes. Nomes, cronologia, cenas, chefes e regras específicas do pacto ainda são propostas. O interesse por alguns chefes anteriores não constitui aprovação integral de suas histórias.

O estudo em [GUIA_STORYTELLING_UNDERTALE.md](GUIA_STORYTELLING_UNDERTALE.md) continua como material de referência. [A_CIDADE_QUE_ME_ENTERROU.md](A_CIDADE_QUE_ME_ENTERROU.md) aprofunda a direção escolhida. [HISTORIA_NOVA.md](HISTORIA_NOVA.md) guarda a proposta anterior, que não é a direção atual. A escolha da história não constitui pedido para implementar alterações no jogo nesta etapa.

**Planejamento por mapa solicitado:** conectar a campanha por missões, NPCs, diálogos, lugares, interações, subquests e consequências no hub. [PLANO_CAMPANHA.md](PLANO_CAMPANHA.md) reúne os dez destinos e suas conexões. [mapas/FICHA_MAPA.md](mapas/FICHA_MAPA.md) padroniza o detalhamento; [mapas/02_OFICINAS.md](mapas/02_OFICINAS.md) é a primeira ficha preenchida. Esses documentos são propostas de design para revisão, não implementação nem aprovação automática de todos os detalhes.

**Pacote atual:** as dez fichas estão completas e indexadas no plano. Cada uma descreve direção visual, lugares garantidos, etapas jogáveis, diálogos, dois arcos opcionais, encontros e mudanças no hub. [BASE_NARRATIVA.md](BASE_NARRATIVA.md) coordena responsabilidades e regras; [HUB_INICIAL.md](HUB_INICIAL.md) detalha chegada e retornos; [CENAS_REVELACAO_E_FINAIS.md](CENAS_REVELACAO_E_FINAIS.md) prepara revelações e encerramentos. [GUIA_IMPLEMENTACAO_DEVIN.md](GUIA_IMPLEMENTACAO_DEVIN.md) orienta a futura produção com o projeto existente. O usuário pediu esse detalhamento para depois o Devin desenvolver o jogo; esta etapa permanece documentação.

## Uso do trabalho existente

As salas e seus arquétipos podem apoiar a exploração e a composição de arenas. Paredes, pilares, buracos, cobertura e avisos de ataque podem inspirar regras táticas. Isso exige adaptação: movimento livre, transição de cena e turnos ainda não estão implementados.

Para permitir narrativa consistente com geração procedural, locais e acontecimentos essenciais devem ter posições ou regras de montagem garantidas. O gerador pode variar trechos e encontros entre esses pontos; não deve sortear a existência de cenas necessárias para compreender a campanha.
