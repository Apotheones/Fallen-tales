# Ficha de design de mapa

Modelo para as regiões de A Cidade Que Me Enterrou. Preencher com cenas e acontecimentos concretos. Nomes e regras não decididos devem ser marcados como propostas.

## 1. Identidade e função

- Nome e número do destino.
- Estado inicial e condições de acesso.
- O que o jogador deseja ao entrar.
- Descoberta pessoal ou relacional que modifica esse desejo.
- O que ficará diferente ao sair.

## 2. Missão principal

- Quem pede, de que precisa e por que a necessidade surgiu agora.
- Recurso ou pessoa procurada; função concreta na melhoria do hub.
- Etapas: chegada → exploração → mudança de situação → encontro → resolução → retorno.
- Condição de conclusão e alternativas de obtenção.
- O que acontece se o jogador voltar antes de terminar.
- Qual acontecimento conduz ao próximo destino.

## 3. Lugares e exploração

Descrever entrada, lugares garantidos, ramificações opcionais, segredos e saída. Para cada interação: objeto ou pessoa, ação possível, resposta e consequência.

Marcar a sequência indispensável de acontecimentos e o que o gerador pode variar. Pistas essenciais precisam de fonte garantida e acessível em cada resolução prevista.

> **Decisão de 02/10/2026:** os mapas da campanha são **autorais** — os "trechos que o gerador pode variar" mencionados nas fichas passam a ser seções desenhadas à mão. O gerador procedural permanece apenas no modo interno de três andares. Ver [MEGAPLAN_CAMPANHA.md](../MEGAPLAN_CAMPANHA.md).

## 4. NPCs

Para cada personagem importante:

- Rotina, desejo, medo, contradição e relações com outros personagens.
- Conhecimento sobre protagonista, amor e pacto: sabe, ignora, suspeita ou esconde.
- Voz e hábitos, com exemplos curtos.
- Local antes e depois da missão.
- Respostas a perguntas diretas e a acontecimentos de outros mapas.
- Subquest ou função dramática que justifique sua presença.

## 5. Subquests

Para cada arco:

| Campo | Conteúdo |
| --- | --- |
| Personagem e título | Quem deseja algo e como reconhecer a quest |
| Disponibilidade | Encontro e condições para começar |
| Etapas | Ações e conversas, incluindo continuações em outros destinos |
| Escolhas | Compromissos que o jogador pode assumir ou recusar |
| Reencontro | Como o personagem reconhece o resultado |
| Consequências | Mudança na região, no hub, em serviços ou em relações |
| Interrupção | Recusa, retirada, morte, quebra de promessa ou avanço da campanha |
| Epílogos | O que esse arco deixa nos dois finais |

Uma quest local pode continuar no hub e em outro mapa. Não colocar fatos indispensáveis ao entendimento dos finais exclusivamente dentro dela.

## 6. Encontro principal

- Por que o oponente confronta o protagonista agora.
- Como é apresentado antes da arena.
- Terreno, intenções e possibilidades de interação.
- Resolução física e consequências.
- Proposta de negociação e ações que tornam o acordo viável.
- Definir separadamente derrota, rendição e morte, conforme o combate escolhido.
- Resultado no mapa de exploração e acesso aos recursos e pistas.

## 7. Diálogos por acontecimento

Escrever abertura, interação cotidiana, pergunta pessoal, descoberta, confronto, resolução e retorno. Incluir variações para informação já conhecida, quest recusada, promessa cumprida e ruptura de confiança.

Registrar a condição de cada fala. Não depender de uma ordem de mapas que o jogador não é obrigado a seguir.

## 8. Hub e continuidade

- Mudança visual e quem trabalha nela.
- Serviço ou interação disponível depois.
- Moradores que chegam, saem ou mudam de rotina.
- Conversas e conflitos que aparecem.
- Novo destino sugerido e motivo de acesso.
- O que permanece depois de morte e revisita.

## 9. Arte e implementação futura

Separar o que reaproveita salas, terreno, atores e áudio atuais do que exige novos objetos, personagens ou regras. Não assumir que o gerador atual já garante ordem de cenas ou campanha persistente.

### Direção visual obrigatória

- Impressão inicial e sentimento que o lugar precisa produzir.
- Paleta de referência com quatro ou cinco cores em hexadecimal; reservar a sinalização de perigo e interação usada no jogo.
- Materiais, formas arquitetônicas, distribuição de altura e silhuetas de referência.
- Marcos visuais para entrada, personagem central, descoberta e saída.
- Objetos de interação, decoração sem interação e suas diferenças visuais.
- Aparência antes e depois da missão; mudanças de revisita e de revelação.
- O que reaproveita a arte pixelada atual e quais novos objetos, retratos ou animações precisam ser produzidos.
- Leitura funcional em exploração livre e na arena separada. Névoa e iluminação dinâmica não são dependências de compreensão.

### Descrição executável de cada etapa

Dar um identificador estável a cada etapa, como `P02-E01`. Para cada uma, registrar lugar garantido, condição de início, objetivo mostrado, ação disponível, fala ou evento, condição de conclusão, resultado persistente e resposta a morte ou retirada temporária.

As etapas das subquests precisam do mesmo cuidado: o Devin deve conseguir saber quando uma fala aparece, quando um recurso é entregue e o que muda depois. Identificadores de conteúdo não obrigam criar um motor de roteiro ou um novo framework.

O material garante sequência e condições; o gerador continua podendo variar os trechos indicados na ficha. Quantidades, coordenadas ou resultados deixados abertos precisam de uma proposta padrão ou de uma indicação explícita de que não devem ser implementados ainda.

## 10. Revisão

Percorrer a ficha com cooperação, confronto, retirada temporária e retorno tardio. Verificar conclusão possível, compreensão da história, reação do hub e continuidade das subquests em cada caminho.
