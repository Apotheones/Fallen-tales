# Mapa 10 — Túmulo Primeiro

Ficha de implementação futura. Proposta coordenada com a [base narrativa](../BASE_NARRATIVA.md), o [roteiro dos finais](../CENAS_REVELACAO_E_FINAIS.md) e o [combate](../BATALHA_ACT_MERCY.md). O acesso exige a resolução principal da fronteira, mapa 9. Não exige terminar quests, aprimorar todos os status ou reconciliar-se com o hub.

Civis do hub não são atacáveis. Falas para acompanhantes ausentes/mortos e para Aurel morto antes deste mapa são salvaguardas de futuras revisões narrativas; não pedem essas mortes como eventos novos. Na campanha proposta, Aurel está disponível para o confronto final, e sua derrota não significa morte automática.

## Função

O protagonista entra para decidir sobre a vida roubada, não para descobrir uma terceira regra. Aurel tenta impedir a restituição. Resolver esse confronto permite chegar ao ato; **não escolhe o final**. Até confirmar a decisão, o jogador pode retornar ao hub, consultar descobertas e resolver assuntos pendentes. Mortes anteriores continuam levando ao túmulo de chegada e não reiniciam a campanha.

## Visual e composição

**Paleta:** pedra `#303744`, chão `#656976`, madeira `#675046`, osso/papel `#D9CCB3`, metal interativo `#B59463`. Nada de verde/vermelho atribuindo julgamento moral às opções. Molduras, silhuetas e texto distinguem ações.

Materiais: alvenaria velha, madeira da execução, placas com inscrições e ferragens. Silhueta: vestíbulo estreito, recinto central amplo, túmulo baixo e duas saídas laterais identificáveis. Marcos: placa com o nome do protagonista, mesa do instrumento do rito e abertura para o retorno. A iluminação é estática. Não adicionar névoa, clarão divino ou câmera que trate a morte como coroação.

Reaproveitar pisos, paredes, portas, pilares e obstáculos existentes. Arte nova: túmulo original fechado/aberto, instrumento ritual sobre mesa, placa corrigível e sprites de Aurel/Teca/Doro se necessários. Usar a escala do tileset atual. Antes/depois: acesso permanece aberto após confronto; placa registra a escolha opcional de epitáfio; nenhuma mudança visual oculta uma conclusão diferente do texto.

O gerador varia aproximação e ramos vazios de exploração. Vestíbulo, encontro, túmulo e retorno precisam de conexão garantida. Não distribuir fatos indispensáveis em segredos. A região é curta; não acrescentar corredores de inimigos para alongar artificialmente o clímax.

Esta é a fonte subterrânea da sepultura visitada no mapa 1, não uma segunda sepultura original. Mostrar na laje a mesma marca partida, agora vista por baixo. O acesso antigo continua colapsado; chegar pela rota funerária de manutenção identificada através da Fundação e do marco restaurado em 9. Nenhum novo objeto raro ou subquest é necessário para atravessá-la.

## Personagens locais

**Aurel, Primeiro Zelador:** irmão de Teca, executor do rito e responsável pelo bloqueio da fuga. Esteve no hub desde o início e pode ter confessado antes. Deseja preservar a comunidade; teme perder a irmã e descobrir que seu zelo continua produzindo coerção. Não transfere sua culpa para Bento nem para uma entidade oculta. Voz firme, inicialmente coletiva: “Se você retomar, eles morrem.” Precisa responder sobre o que ele próprio fez.

**Doro:** beneficiário posterior, já vinculado. Quer devolver ao protagonista autoridade sobre sua vida, mesmo que isso encerre a sua. Pode oferecer companhia, nunca substituir o dono no rito. Fala curta, prática, com afeto; não pede sacrifício como pagamento pelos cuidados.

**Teca:** vinculada, opôs-se ao crime. Ama o irmão e pode responsabilizá-lo ao mesmo tempo. Deseja sobreviver sem exigir outra morte da vítima. Sua presença não transforma vínculo familiar em defesa da execução. Doro e Teca podem ficar no vestíbulo; não são companheiros obrigatórios da arena.

## Missão principal — Minha vida não é uma votação

### P10-E01 — Entrar sem encerrar a campanha

- **Local/início:** vestíbulo, com destino 10 disponível.
- **Objetivo/ação:** identificar túmulo, acesso central e retorno; falar com acompanhantes se vivos.
- **Fala:** Doro: “A saída continua ali. Entrar não é prometer nada.”
- **Conclusão/estado:** região conhecida, opções de retorno preservadas.
- **Retirada/morte:** volta ao hub normalmente. **Hub:** ninguém interpreta visita como aceitação do sacrifício.

### P10-E02 — Ouvir Aurel sem perder a palavra

- **Local/início:** recinto central, Aurel bloqueando a passagem.
- **Objetivo/ação:** exigir acesso; perguntar sobre a execução; consultar provas já conhecidas.
- **Fala:** “Você decidiu por mim uma vez. Não vai decidir agora.”
- **Conclusão/estado:** posição de Aurel registrada, confronto ou negociação disponível.
- **Retirada/morte:** ele reconhece a discussão anterior. **Hub:** sua oposição não apaga reparações nem confissões.

### P10-E03 — Resolver o último bloqueio

- **Local/início:** arena separada, depois do conflito explícito.
- **Objetivo/ação:** fazê-lo retirar a restrição sem promessa de sacrifício ou vencê-lo fisicamente.
- **Fala:** Aurel: “Não posso entregar todos.” / “Você pode deixar de me manter preso.”
- **Conclusão/estado:** acesso permanentemente aberto; rendição, sobrevivência ou morte ficam distintos.
- **Retirada/morte:** vencer e sair não reinicia o chefe. **Hub:** o resultado é reconhecido, mas nenhum final acontece ainda.

### P10-E04 — Rever custos e pessoas

- **Local/início:** túmulo original aberto, depois do bloqueio.
- **Objetivo/ação:** consultar instrução, pessoas vinculadas e as duas possibilidades. Conversar ou permanecer em silêncio.
- **Fala:** Teca: “Posso querer viver sem dizer que você me deve isso.”
- **Conclusão/estado:** custos confirmados em linguagem direta; informação principal continua disponível se acompanhantes morreram.
- **Retirada/morte:** nenhuma leitura consome a decisão. **Hub:** visitas e quests permanecem possíveis.

### P10-E05 — Confirmar ou adiar

- **Local/início:** ponto de ação do rito, após revisão.
- **Objetivo/ação:** selecionar ceder, retomar ou não decidir agora; ler efeito e cancelar ou confirmar.
- **Fala:** “Eu sei o que acontece. Preciso escolher por mim.”
- **Conclusão/estado:** só confirmação explícita fixa o final. Dano, derrota ou matar Aurel nunca escolhem por engano.
- **Retirada/morte:** adiar devolve controle; morrer antes do ato mantém a campanha. **Hub:** último retorno livre até confirmação.

### P10-E06 — Ver a consequência escolhida

- **Local/início:** ato confirmado.
- **Objetivo/ação:** acompanhar entrega definitiva ou restituição; cenas reconhecem sobreviventes e acolhimentos reais.
- **Fala coletiva:** “Eu queria voltar para ela.” **Individual:** “Me devolve a vida que roubaram.”
- **Conclusão/estado:** coletivo: protagonista morre sem retorno; individual: vinculados vivos morrem, protagonista recupera corpo e vida. Visitantes sem selo não morrem.
- **Retirada/morte:** etapa encerra retornos; não há nova tentativa depois do ato. **Hub:** epílogo correspondente, sem ressuscitar NPCs mortos antes.

### P10-E07 — Encerrar com Lia e com os sobreviventes

- **Local/início:** consequência estabilizada.
- **Objetivo/ação:** acompanhar epílogo do hub e Ponta Clara. No individual, atravessar e reencontrar Lia de verdade; relatar o custo sem escondê-lo.
- **Fala:** Lia: “A gente vai precisar conversar. Mas entra.”
- **Conclusão/estado:** reencontro individual afetuoso e real, sem absolvição automática. No coletivo, Lia recebe a verdade depois; nunca autorizou a morte.
- **Retirada/morte:** não acrescentar combate ou punição surpresa. **Hub:** continuidade ou perda respeita quem possuía selo.

## Perfil de combate

| Encontro | Local/etapa e gatilho | Composição e arena | Retirada e resultado |
| --- | --- | --- | --- |
| C10-01 — Primeiro Zelador | P10-E02/E03: bloqueio explícito não resolvido pela conversa | Somente Aurel; nenhum inimigo aleatório. Grid com pilares, duas passagens laterais e marcas de interdição | Negociar, vencer ou retirar-se. A morte do protagonista retorna ao hub. Resolver abre acesso, não fixa final |

Se Aurel morreu numa resolução anterior prevista, o bloqueio pode ser removido pelos dispositivos acessíveis e pela instrução conhecida. Não ressuscitá-lo ou inventar outro culpado como substituto. O acesso e a decisão não dependem de ouvir suas últimas palavras.

## Proposta para o confronto

Aurel marca linhas, fecha aproximações e faz ataques largos anunciados. Retirar coberturas ou atravessar aberturas permite contestar seu controle do campo. Sem moradores inocentes usados como escudos físicos e sem instrumento que consuma um NPC para fortalecer o chefe.

**Negociado:** exigir que reconheça o dono da vida e remova a interdição, aceitando que o protagonista poderá escolher restituição. Pode ouvir sobre Teca, mas afeto pela irmã não vira senha. Se exigir promessa de morte voluntária, o acordo ainda não existe. Enquanto texto, diálogo, inventário ou pausa estiverem abertos, ações hostis ficam suspensas. Depois de fechar a interface, a trégua na ficção depende do acordo; repetir uma fala não concede ações gratuitas na futura regra de combate.

**Físico:** vencer retira sua capacidade de bloquear. Se o combate admitir opção letal, ela é separada da rendição. Matar Aurel não paga o pacto, não pune apenas os culpados nem esconde os custos posteriores. Os dois finais continuam disponíveis.

## Duas subquests de encerramento

**Q10-A — O nome que eu deixo, Doro.** Estados: `examinar inscrição → escolher correção → gravar / deixar como está`. Corrigir o assentamento e decidir se quer uma frase pessoal no túmulo. Pode registrar apenas nome e crime, a promessa de voltar ou recusar qualquer monumento. Sem epitáfio obrigatório de salvador. Se Doro morreu, a correção pode ser feita pelo protagonista com ferramentas já recuperadas; não há reencontro substituto. No coletivo a placa conserva sua vontade. No individual permanece entre as perdas, sem impedir a partida.

**Q10-B — Meu irmão responde por si, Teca.** Estados: `ouvir pedido → conversa com Aurel → testemunho / recusa`. Ela deseja falar sobre a execução sem voltar ao hábito de explicar o irmão aos outros. O jogador pode assistir, exigir resposta direta ou não participar. Aurel precisa responder por seu ato, não conseguir perdão. Se morto, Teca decide registrar sua posição; não recebe uma confissão póstuma inventada. No coletivo mantém sua convivência e responsabilidade se ambos vivem. No individual, ambos vinculados morrem; a conversa ocorrida não os exclui do pacto.

## Quatro cenas de voz

**Vestíbulo:** “Você vai comigo?” / Doro: “Até onde você quiser. Não até onde eu acho que você deve ir.”

**Confronto:** Aurel: “Eu mantive essas portas abertas.” / “E fechou a minha rua.” A defesa de serviços úteis não apaga a execução.

**Depois da derrota:** “Vai tentar me impedir de novo?” / Aurel: “Não.” Se morto, silêncio e acesso aberto substituem a fala; outra pessoa não garante seu arrependimento.

**Antes do ato:** “Quero ver Lia.” / Teca: “Eu acredito.” / “Você está entre os que eu perderia.” / “Eu sei.” Não colocar a resposta apenas numa rota pacífica.

## Confirmação, epílogos e revisão

Mostrar os custos completos antes de confirmar: mortes coletivas incluem Doro, Nilo, demais centrais vinculados e moradores acolhidos depois, estejam onde estiverem. Ceder preserva os que ainda vivem, não ressuscita mortos e não absolve Bento/Aurel. Retomar oferece reencontro real com Lia; ela fica sabendo da verdade, tem reação própria e não é removida como punição romântica.

Não exigir desculpas, dar terceiro final secreto, premiar o sacrifício com retorno posterior ou contar uma morte comum como escolha. Revisar com Aurel vivo/morto, negociação/confronto, acompanhantes ausentes, subquests recusadas, retornos ao hub e diferentes acolhimentos. Só o ato final confirmado torna a decisão irreversível.
