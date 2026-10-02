# 07 — Armazéns da Partida

Proposta coordenada com [BASE_NARRATIVA](../BASE_NARRATIVA.md), [PLANO_CAMPANHA](../PLANO_CAMPANHA.md) e [FICHA_MAPA](FICHA_MAPA.md). Nomes novos: **Joana** e **Silvério**. Pode ocorrer antes ou depois de 8; não depende das subquests anteriores.

## 1. Função e acesso

Os registros encontrados em 6 identificam o depósito que recebeu a última encomenda do protagonista e a passagem usada nas viagens para o exterior. Doro precisa das peças que ficaram retidas e do traçado original para preparar essa estrutura. O protagonista quer verificar como sua partida foi interrompida.

O mapa mostra uma promessa comum: ele terminaria um serviço curto e voltaria para Lia. Não foi um juramento heroico nem consentimento para morrer. **Não há notícia recente de Lia aqui.** Isso pertence a 9. A testemunha conhece sua despedida de sete anos atrás.

## 2. Direção visual e lugares garantidos

**Paleta:** pedra fria `#56646C`, madeira salgada `#86705A`, ferro `#424951`, lona `#C7B896`, marca de circulação `#D89F48`. Silhuetas verticais de prateleiras e postes contrastam com longos corredores de carga. Cordas e lotes numerados mostram organização; reparos desiguais e bagagens empilhadas mostram como ela deixou de funcionar.

**Marcos:** doca seca, plataforma de espera com banco reparado, balcão de despacho, galpão de carga e passagem interrompida. Uma placa de destinos permite ler a orientação sem mapa externo. Evitar nevoeiro dinâmico ou água navegável como dependência. Som ambiente: vento, madeira rangendo e uma roldana distante; a cena de despedida não exige voz gravada.

Reaproveitar corredores de pilares, divisórias, ruínas, paredes mineráveis e fissuras. Cristais podem ocupar uma sala de carga danificada, sem virar combustível das passagens. Preservar apresentação atual de 32 pixels e escala lógica existente de 40. Assets novos: caixas identificadas, bancada de despacho, roldana, banco, bagagens e retratos. Placeholders precisam distinguir objeto interativo, cobertura e decoração. A ordem das cores não substitui sinais legíveis de perigo.

O gerador varia corredores e salas de carga secundárias. Doca, espera, despacho e conjunto principal são garantidos. O jogador chega à espera antes do confronto; a peça indispensável não pode ficar num segredo. Saídas curtas mineráveis são opcionais. Toda referência à passagem exterior existe na placa e no traçado preservado, mesmo sem testemunhas.

## 3. Missão principal executável

| ID | Início e lugar | Objetivo e ação | Evento, fala e conclusão | Resultado persistente; morte ou retorno temporário |
| --- | --- | --- | --- | --- |
| P07-E01 | 6 resolvido; hub | Conferir referência do depósito com Doro | Ele separa o que falta à passagem e pede peças, não outra melhoria obrigatória. Conclui ao registrar objetivo de expedição | 7 disponível independentemente de 8; retornar ao hub não reinicia preparação |
| P07-E02 | Entrada; doca seca | Ler os destinos e descobrir como os lotes são distribuídos | Joana aponta a área de espera. Sem ela, placa e marca no piso indicam o caminho. Conclui com a leitura do traçado | Destino exterior identificado como rota antiga, sem afirmar que está utilizável hoje |
| P07-E03 | Plataforma de espera | Examinar banco, recibo e ouvir Joana | Ela reconhece o protagonista pela peça que ele reparou e lembra Lia partindo enquanto ele ficou pelo serviço. Conclui ao inspecionar o recibo datado | Despedida registrada; ausência ou morte de Joana retira a conversa, não a cronologia |
| P07-E04 | Balcão e galpão | Localizar o conjunto original e conferir pedidos dos refugiados | Silvério colocou uma encomenda retida na fila geral. O jogador verifica que as peças da passagem são distintas das caixas de comida e abrigo | Posse anterior e necessidades atuais esclarecidas; não consumir recursos essenciais das outras pessoas por sorte |
| P07-E05 | Silvério questionado | Obter liberação com prioridades públicas ou contestar o despacho | Ele responde diante dos trabalhadores. Escolhas: exigir restituição do próprio conjunto; discutir a fila sem ceder o objetivo; confronto físico | Acordo ou encontro iniciado. Retirada preserva fila e escolhas, sem despachar a peça principal fora do mapa |
| P07-E06 | Arena ou despacho | Resolver obstrução e recuperar conjunto | Acordo muda a prioridade; derrota abre acesso; rendição permite conversa. Se Silvério morrer, estoque e documentação continuam no galpão | Peças recuperadas e resultado do chefe gravado; combate não seleciona final da campanha |
| P07-E07 | Passagem interrompida | Comparar traçado com estrutura e registrar local de instalação | O protagonista identifica onde as peças se encaixam. Conclui ao examinar a base, não ao completar uma subquest | Preparação de 7 resolvida. A estrutura permanece incompleta; restauração e demonstração do limite do vínculo acontecem em 9, sem partida antecipada por exploração |
| P07-E08 | Retorno ao hub | Entregar conjunto, falar de Lia ou guardar silêncio | Sem 8 concluído, Doro prepara material e aponta investigação pendente. Com 8 concluído, preparação e conhecimento permitem restaurar e interpretar 9 | 9 somente disponível com 7 e 8 resolvidos. Se 7 veio primeiro, concluir 8 mais tarde reconhece a preparação pronta, sem repetir esta missão |

O recibo fixo registra a despedida e a encomenda; a identificação do serviço mostra por que ele demorou. Uma anotação do próprio protagonista confirma que esperava voltar naquele dia. Documentos são consultáveis no banco/despacho, não destruídos na arena. Não transformar decisão cotidiana de terminar um trabalho em culpa pelo assassinato.

## 4. Pessoas

**Joana, trabalhadora:** organiza bagagens sem declarar que tudo abandonado pertence ao armazém. Conheceu o casal como clientes e viu a última despedida. Gosta de conversar enquanto confere fechos; lembra detalhes práticos, não discursa sobre amor. Quer recuperar seus próprios pertences e trabalhar onde consiga encerrar o expediente. Vive fora, **sem selo**. Visitar o hub não vincula; residência permanente exige acolhimento registrado e explicação da origem depois da revelação.

**Silvério, responsável pelo despacho:** distribui cargas entre moradores, caravanas incompletas e refugiados. Tem pedidos legítimos demais e usa antigos cargos como desempate, favorecendo quem já era poderoso. Quer ser considerado indispensável e teme responder por uma fila que nunca termina. Já recebeu o selo. Conhece documentos de transporte; não conhece a vida atual de Lia nem todo o rito. Deve dizer o que sabe se perguntado, sem inventar ordens secretas para inocentar dirigentes.

**Doro, recorrente:** continua preparando a partida mesmo depois de saber a consequência para si. Não cobra serviço à cidade como preço de ajuda. Sua oficina futura aparece numa subquest; ele tem desejos que o protagonista poderá perder junto com o amigo.

## 5. Encontro: Quem passa primeiro?

Apresentar a fila e o comportamento de Silvério antes da arena. Ele não luta por achar que todos precisam ficar. O conflito é permitir que uma regra de precedência impessoal transforme a restituição do protagonista em espera eterna.

Na cena separada, refugiados permanecem fora do grid. Coberturas são caixas vazias e pilares. Silvério usa a movimentação das cargas para cortar linhas de tiro; áreas de queda são anunciadas. O jogador pode flanquear, impedir o acionamento ou forçar rendição. A rota de conversa durante o encontro permite suspender a disputa e retornar ao despacho; não exige repetir um elogio.

O acordo usa fatos: identificar a encomenda pessoal, separar comida e abrigo das peças de passagem e publicar uma fila que não privilegie patentes. O jogador também pode exigir apenas seus pertences; isso conclui a missão sem resolver a injustiça dos demais, que reaparece nas revisitas. Vitórias físicas não geram peças ilimitadas nem resolvem automaticamente todos os pedidos. Se o chefe morrer, Joana ou trabalhadores sem quest assumem a entrega; não reproduzem sua personalidade.

## 6. Duas subquests

### Q07-J — Joana: O que eu trouxe

Começa quando ela vê sua panela entre objetos marcados como provisão comum. A missão trata da diferença entre contribuir e perder o direito de escolher.

| ID e início/local | Objetivo, ação, cena e conclusão | Estado persistente e retirada/morte |
| --- | --- | --- |
| Q07-J01; pedido aceito, 7 | Conferir etiquetas e localizar a caixa no lote comum. Joana reconhece seus objetos; conclui com a caixa reservada, sem tomar pertences alheios | Caixa localizada; retirada não a converte em doação |
| Q07-J02; J01 resolvida, 5 | Conferir registro de bagagens do abrigo; Cira acrescenta conversa se viva. Conclui ao verificar a reserva original, sem repetir Beltran | Posse confirmada; documento permanece se Cira morrer e leitura não se repete |
| Q07-J03; confirmação obtida, hub ou 7 | Devolver caixa e ouvir o que Joana conserva, empresta ou doa. Conclui ao executar a escolha; Bento só usa a panela com autorização | Objetos mudam de lugar e acolhimento é registrado se escolhido. Se Joana morreu, não inventar autorização póstuma |

Prometer devolução e entregar tudo ao estoque coletivo quebra confiança; Bento pode devolver o que ainda existe. Recusar deixa Joana tentar recuperar seus bens. Se morrer, localizar a caixa não cria uma doação póstuma: conservá-la para familiares é outro resultado. No sacrifício, suas escolhas continuam respeitadas. Na vingança, o vínculo depende de residência com selo, não de trabalhar uma tarde com Bento.

### Q07-D — Doro: Depois desse serviço

Disponível na preparação ou ao retornar de 7. Doro desenhou uma fachada de oficina, mas deixou o letreiro em branco: nunca separa madeira boa para si.

| ID e início/local | Objetivo, ação, cena e conclusão | Estado persistente e retirada/morte |
| --- | --- | --- |
| Q07-D01; pedido aceito, 7 ou hub | Separar tábua e ferragens comuns, ou entregar equivalentes já obtidos. Conclui com material destinado ao letreiro; não gastar peças da passagem | Material reservado; morte não reabre coleta já feita |
| Q07-D02; D01 resolvida, 2 | Revisar desenho usando bancada e conversar com Brina se viva. Conclui ao registrar ajustes de trabalho; sua morte retira conversa, não a bancada | Desenho atualizado; revisita não reinicia encontro da oficina |
| Q07-D03; ajustes registrados, hub | Montar o letreiro com Doro e perguntar quais trabalhos deseja aceitar. Conclui quando ele escreve o nome e escolhe destino do projeto | Letreiro e rotina próprios; retirada conserva progresso. Se Doro morrer, não fabricar a cena de conclusão |

Recusar mantém a fachada desenhada, não destrói a amizade. Cumprir o pedido faz Doro reservar horários para projetos próprios. Depois de 8, ele reconhece o custo: não pede que o protagonista escolha o final para salvar sua oficina. Doro já tem selo; sair fisicamente não o livra do pacto. No sacrifício, a oficina pode abrir. Na vingança, o letreiro fica como plano interrompido; não escrever Doro vivo no exterior.

## 7. Diálogos condicionados

**Espera, apresentação de Joana:**

> **Joana:** “Você consertou esse banco.”  
> **Protagonista:** “Ainda está torto.”  
> **Joana:** “Você disse que voltava pra terminar.”

**Lembrança anterior ao ataque:**

> **Joana:** “Lia queria que você fosse com ela.”  
> **Protagonista:** “Eu ia depois do serviço.”  
> **Joana:** “Ela deixou lugar pras suas ferramentas. Mesmo reclamando do peso.”

Não inferir a espera atual a partir dessa cena. Escolhas: explicar o serviço, lembrar a despedida ou não comentar.

**Fila de despacho:**

> **Silvério:** “Eu tenho pedidos mais antigos.”  
> **Protagonista:** “O meu tem sete anos.”  
> **Silvério:** “Então vamos abrir esse registro.”

Ele verifica antes de ceder. O jogador pode exigir somente restituição, cobrar critérios públicos ou iniciar confronto; o objetivo não fica dependente da escolha mais generosa.

**Bagagem, subquest:**

> **Joana:** “Não é uma lembrança sagrada. É uma panela boa.”

**Retorno se 8 ainda não concluído:**

> **Doro:** “As peças estão aqui. Ainda falta conferir a instrução na necrópole.”

Se Aurel já explicou a regra antes de 8, Doro reconhece o custo conhecido e diz que falta a confirmação documental, não finge ignorância. Isso não substitui a resolução principal de 8 para acesso a 9.

**Retorno se 8 concluído:**

> **Doro:** “Eu sei o que preparar essa saída significa.”  
> **Protagonista:** “E vai continuar?”  
> **Doro:** “Vou.”

Nenhuma resposta solicita perdão ou confirma morte automática do amigo nesta etapa. É preparação para uma decisão futura.

## 8. Perfil de combate — três comuns disponíveis e um chefe

**Densidade escolhida pelo usuário:** dois encontros comuns no percurso principal, um terceiro num ramal opcional e o chefe. Composição e posição são propostas. Reaproveitar Rastejante (`crawler`), Sentinela (`ranger`) e Bruto (`dasher`); conservar avisos de mordida, linha e investida na futura versão por turnos. Não criar um inimigo novo para cada tipo de carga.

| Encontro e momento | Gatilho visível e composição | Avisos, terreno e resolução | Saída e persistência |
| --- | --- | --- | --- |
| C07-01; entre P07-E02 e E03, acesso da plataforma | Dois Rastejantes circulam sob caixas vazias; o jogador vê os dois e a rota exposta antes de entrar no setor. Oferecer enfrentar ou recuar; nunca encontro aleatório por passos | Mordidas avisam células próximas. Caixas baixas e abertura lateral permitem flanquear; o banco e o recibo da despedida não entram como objetos destrutíveis na arena | Vitória devolve à plataforma liberada; recuo à doca; morte ao hub. Gravar resolução sem reativar ao ouvir Joana |
| C07-02; P07-E04, corredor de inspeção do galpão | Uma Sentinela hostil vigia o corredor e um Rastejante ocupa a passagem lateral. Ambos visíveis antes da transição anunciada | Linha de tiro e mordida exigem mudar posição. Pilares e caixas vazias são cobertura; conjunto principal e bagagens de refugiados ficam fora do grid | Vitória libera inspeção da carga; recuo retorna ao despacho. Morte não desfaz despedida ou documentos lidos. Resolvido permanece limpo mesmo antes da liberação por Silvério |
| C07-03; ramal do descarte, durante Q07-J01 ou exploração opcional após E04 | Um Bruto visível ocupa a entrada lateral dos lotes. Ação de atravessar esse acesso avisa o encontro; observar etiquetas à distância não inicia batalha | Investida anunciada atravessa corredor com escoras. Há recuo e uma passagem lateral. Vencer abre atalho até as caixas, sem fornecer peça indispensável | Vitória deixa ramal aberto; recuo volta ao galpão; morte ao hub. Joana pode recuperar a caixa pela circulação segura após resolver o despacho, sem exigir esta luta. Não gerar outro combate na mesma quest |
| B07-01; P07-E05–E06, disputa de despacho | Silvério é conhecido antes da arena. Iniciar somente se o conflito chega à via física; acordo público pode liberar acesso sem luta. Refugiados não são unidades de combate | Cargas vazias, pilares e áreas de queda anunciadas conforme seção 5; não acrescentar uma escolta de mobs à fila | Acordo, derrota ou rendição retorna ao despacho com liberação registrada. Recuo mantém obstrução sem enviar a peça para fora do mapa. Morte do chefe não impede coleta nem traçado |

O terceiro comum aumenta a exploração possível sem inflar a missão principal. Recusar a subquest não o torna obrigatório; concluir a subquest também não obriga enfrentá-lo. Diálogo na espera, reconhecimento da despedida, devolução da panela e montagem do letreiro permanecem cenas sem combate.

**Conversas seguras:** abrir diálogo congela imediatamente simulação e intenções hostis, inclusive no passo em que a conversa começou. Nenhum projétil, investida ou queda resolve sob menu de NPC; fechar a fala retoma o estado conforme a regra futura de turnos. Encontros concluídos permanecem resolvidos após morte, retorno ou visita posterior à revelação. Um perigo visível pode continuar num encontro ainda pendente, sem fazer NPCs reapresentarem sua história.

## 9. Hub, persistência e revisão

Peças ficam separadas junto da bancada de Doro; traçado da passagem fica consultável. O letreiro só aparece se sua quest avançou. Joana visitante conserva bagagem em espaço temporário; residente acolhida tem lugar próprio e estado de selo registrado. Silvério mantém fila revisada, posição contestada ou ausência conforme o resultado.

Se 7 veio antes de 8, a comunidade responde aos fatos efetivamente conhecidos: confissões antecipadas não voltam a ser apresentadas como suspeitas. Se veio depois, Bento não celebra a expedição como favor que quite seu crime; pode oferecer comida sem exigir reconciliação. Aurel não chama o reencontro com Lia de desejo egoísta para ocultar o assassinato. Lia permanece personagem do exterior, sem aparição presencial aqui.

Para Devin, verificar: conversa e confronto entregam o conjunto; retorno parcial mantém caixa localizada e peça reservada; morte não repõe cargas; Joana morta não apaga despedida; Silvério morto não apaga traçado; quests recusadas não fecham 9; 7 primeiro aguarda 8; 8 primeiro reconhece suas consequências antes desta missão. Não exigir consumíveis opcionais nem soluções sorteadas para o acesso principal.
