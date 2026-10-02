# Combate — proposta concreta para protótipo

Documento de design, 02/10/2026. O usuário escolheu exploração livre, mudança para arena no grid e ritmo equilibrado de 2–3 comuns mais um chefe nas regiões intermediárias. **O funcionamento por turnos abaixo é a proposta de protótipo apresentada na conversa; não uma implementação pronta nem uma aprovação definitiva de todos os valores.**

Este documento fornece uma base concreta ao Devin. Não desenvolver três sistemas de combate paralelos. Verificar esta versão num encontro comum e nas Oficinas antes de produzir todos os inimigos.

## 1. O jogador controla quem

Primeiro recorte: somente o protagonista. NPCs podem participar de cenas e de objetivos, mas não existe uma equipe de quatro personagens para equipar e controlar. Aliados jogáveis e suas regras ficam para uma decisão posterior.

A exploração usa movimento livre. Entrar num encontro visível captura o ponto e o estado do mapa, suspende a exploração e abre uma arena separada. Ao resolver, volta ao lugar correspondente com alterações reconhecidas. O grid da batalha continua reutilizando pisos, paredes, pilares e linguagem visual do jogo atual.

## 2. Uma rodada

1. **Intenções:** cada inimigo vivo anuncia sua próxima ação. Mostrar origem, área ou trajeto e ordem de resolução. A ordem permanece estável durante a rodada.
2. **Turno do jogador:** mover até duas células cardinais e escolher uma ação. Pode mover primeiro e agir, ou agir primeiro e mover. No primeiro recorte, não dividir o movimento entre antes e depois da ação. Girar e consultar informações não gastam ação.
3. **Encerrar:** o jogador confirma fim do turno. Pode abrir menus para pensar; inimigos não agem enquanto a escolha não for encerrada.
4. **Resolução:** inimigos executam os planos anunciados em sequência legível. Se a ação do jogador derrotou um deles, seu plano não é executado. Uma nova cobertura pode interromper um golpe; remover cobertura não amplia uma área já anunciada.
5. **Próxima rodada:** resolver efeitos pendentes, verificar conclusão e anunciar novas intenções considerando as posições atuais.

Não usar cronômetro para escolher. Esquivar é reposicionar-se antes da resolução, e não reagir em poucos milissegundos. O movimento disponível é mostrado antes de confirmar o destino; bloquear um movimento inválido não consome a ação.

## 3. Ações do primeiro recorte

| Ação | Resultado concreto | Custo e limite |
| --- | --- | --- |
| Disparar arco | Flecha em linha cardinal até alvo, sólido ou borda; mostra prévia do alcance e bloqueios | Uma ação. Sem carga em segundos ou teste aleatório de acerto; vida, dano e alcance precisam de balanceamento no protótipo |
| Defender | Orientar escudo para bloquear o primeiro ataque frontal da fase inimiga; ataques de outra direção e seguintes não são todos anulados | Uma ação; movimento continua disponível. Não acrescentar energia ou árvore de defesa neste recorte |
| Interagir com terreno | Golpear peça rompível, preparar queda ou operar objeto explicitamente utilizável | Uma ação por interação. Reutilizar rachaduras e indicações existentes; não permitir demolir qualquer objeto de decoração |
| Usar item | Consumir um item de efeito claro no protagonista ou num alvo previsto | Uma ação; prévia informa consumo. O primeiro protótipo precisa somente de uma cura simples, sem sistema de crafting |
| Conversar/propor acordo | Propor trégua, retirada, rendição ou cooperação contextual; aceitar pode modificar ou suspender intenções | Uma ação se a proposta avançar a disputa. Ler, escolher tópicos ou cancelar antes de assumir compromisso não dispara o turno inimigo |
| Esperar | Conservar posição e terminar a rodada | Não acumula ações extras para o futuro |

Cartas continuam consultáveis como coleção enquanto sua função definitiva é discutida. Não transformar automaticamente toda carta antiga numa habilidade ou custo de mana. A ação de interação já permite testar o uso original do terreno sem acrescentar uma segunda arma.

## 4. Terreno e consequências

Paredes bloqueiam movimento e flechas. Cobertura cria escolhas de flanco. Pilares usam direção definida pelo golpe; sua queda deve ser mostrada antes de resolver. Cristais possuem área anunciada. Usar as consultas de piso, ocupação e bloqueio existentes quando suas regras ainda forem compatíveis.

Proposta para protótipo: impactos de pilar ou queda provocada aplicam dano e reposicionamento para uma célula segura definida, em vez de copiar automaticamente toda morte instantânea da versão em tempo real. Se não há célula segura, a consequência é explicitada na prévia. Chefes humanos não morrem como efeito colateral invisível de uma queda.

Os avisos determinam o resultado previsto; animações não mudam a célula autoritativa no meio da resolução. Não permitir que um golpe atravesse cobertura que continua intacta ou que sua área aumente depois de o jogador já ter decidido.

Reparos narrativos e operações de comporta podem ocorrer na exploração. Sua representação na arena tem regras próprias, descritas na ficha: não construir simulação de água ou produção só para realizar uma interação de quest.

## 5. Papéis de inimigos

Reaproveitar os papéis atuais, substituindo temporizadores por rodadas e contextualizando arte e nomes nas ruínas:

- **Rastejante:** ocupa aproximações e ameaça uma célula próxima; o erro abre exposição. Ensina sair de uma área curta.
- **Sentinela:** anuncia linha de tiro e recua em situação previsível. Ensina quebrar linha de visão e escolher avanço.
- **Bruto:** prepara investida de trajetória fixa; armadura frontal exige flanco ou interação. Ensina espaço, compromisso e recuperação.
- **Semeador e vigia:** entram depois de o jogador compreender áreas simples; preservam faixa marcada e cruz, respectivamente.

Os comuns devem produzir decisões curtas. Não criar todos os papéis novos antes de testar dois existentes. Chefes adaptam essa gramática a suas relações e objetivos; não são só uma sentinela com mais vida.

## 6. Como conversar funciona

Conversa é uma ação contextual sobre o conflito, não dano aplicado a uma barra social. Janda teme uma saída insegura e controla os trabalhadores. Reparar a passagem permite oferecer uma inspeção. A inspeção altera o plano dela: suspende ataques para verificar a rota e ouvir a proposta.

O jogo mostra se a proposta suspendeu o confronto ou se o adversário recusou. Durante a seleção e as falas, ninguém causa dano. Se uma recusa conduz à resolução inimiga, essa consequência é anunciada antes de confirmar o compromisso, sem usar uma pergunta curiosa como armadilha de turno.

O jogador pode voltar à exploração para preparar uma alternativa quando a ficha prevê isso. No retorno à arena, o personagem reconhece o trabalho. Não reiniciar uma amizade ou exigir uma sequência secreta de três respostas.

Inimigos comuns sem linguagem podem ser afastados, evitados por rota prevista ou vencidos. Não obrigar todo predador a aceitar negociação humana. A fuga possível e o efeito na missão aparecem no perfil do encontro.

## 7. Derrota, morte e conclusão

Proposta padrão: chefes humanos ficam derrotados e o jogador decide aceitar rendição, continuar a conversa ou escolher uma consequência letal quando essa escolha existir. Zerá-los não executa automaticamente um final ou mata espectadores. Criaturas comuns seguem a resolução definida no encontro.

NPCs civis do hub não são alvos de ataque durante exploração. Ramos de NPC morto nos documentos cobrem mortes explícitas previstas ou futuras revisões; não exigem implementar friendly fire e exterminar comerciantes no primeiro recorte.

Vencer dá acesso e consequências; conversar também pode concluir o encontro. Recompensa de combate é entregue uma vez. Não recompensar mais a mesma missão só porque houve mortes.

Morte do protagonista devolve ao túmulo. Persistem mapa, portas alteradas, itens obtidos, decisões e encontros concluídos. Para o primeiro recorte, uma arena comum ainda pendente reinicia seus combatentes na retomada; um combate concluído nunca é repetido. Nenhuma retomada duplica saque. O posicionamento específico de arenas suspensas por negociação deve reconhecer reparos e compromissos já feitos.

## 8. Exemplo de rodada

Sentinela anuncia uma linha vertical pelo caminho de saída. Bruto anuncia investida horizontal pelo corredor. Há uma parede numa lateral e um pilar já rachado à frente, precisando de uma interação para cair. A prévia informa isso; um pilar intacto não deve cair com um golpe quando exige vários.

O jogador pode: mover para cobertura e disparar no flanco; defender o ataque frontal e ocupar uma posição para a próxima rodada; ou interagir com o pilar para interromper a investida. A prévia mostra quais ataques ainda alcançam sua posição final.

A mesma decisão muda se o objetivo é liberar uma testemunha ou impedir a destruição de um registro. O terreno é parte da disputa, não decoração atrás de uma lista de golpes.

## 9. Apresentação e entrada em batalha

Mostrar toda a arena quando possível, sem esconder intenção adversária fora da câmera. Manter pixels nítidos e a escala de leitura atual. Número de ordem, forma da área e direção acompanham a cor; não depender somente de vermelho e verde.

Passagem à arena: ameaça ou recusa explícita → transição curta → posição inicial segura e identidade do conflito → intenções → controle. Retorno: resultado → mudança no mapa → fala curta se cabível → exploração. Não reapresentar o diálogo de entrada ao morrer.

Diálogo, inventário, pausa e perda de foco congelam a resolução. Uma ação de ataque antiga não pode ser reaplicada ao voltar de uma tela.

## 10. Sequência de implementação proposta

1. Movimento de duas células e uma ação; uma sentinela; entrada e retorno à exploração.
2. Segundo papel, cobertura e aviso congelado; morte e retomada sem duplicação.
3. Uma interação de pilar, com prévia coerente e consequência legível.
4. Janda, inspeção negociada e resultado da missão no hub.
5. Validar ritmo e valores antes de replicar encontros nos dez mapas.

Critérios: o jogador prevê por que será atingido, consegue usar terreno, entende o efeito da conversa e volta a um mundo que reconhece sua escolha. Valores finais de vida, dano, economia e dificuldade continuam em revisão.
