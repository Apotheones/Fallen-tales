# Mapa 3 — Mercado das Escoras

Proposta coordenada para desenvolvimento, 02/10/2026. Nomes novos **Rute** e **Ema**, aparência e falas são propostas. Contrato: [BASE_NARRATIVA.md](../BASE_NARRATIVA.md). Exploração livre; encontros em arena de grid separada; turnos ainda abertos. Esta ficha descreve trabalho futuro, não funcionalidades existentes.

## Função e acesso

Disponível após o mapa 1, antes ou depois das Oficinas. Bento precisa reparar o forno: a chapa atual já queima comida enquanto outra parte fica crua. O mercado tem peças de cozinha e moradores com necessidades próprias. O protagonista procura recursos, encontra uma lembrança de seu primeiro encontro com Lia e descobre quem negocia em nome de quem.

Conclusão principal: obter chapa e dobradiças garantidas, resolver sua retirada e tornar utilizável a rota dos Salões. Abre o mapa 5. Autoria de Brina e chegada de Ema são opcionais; nenhuma bloqueia progresso.

## Direção visual e geografia

**Paleta:** pedra `#514E46`, madeira `#876344`, tecido ocre `#C59A56`, ferrugem `#A45945`, luz clara `#E4D8B3`. Praça de feira coberta por estruturas baixas; distinguir dos grandes martelos das Oficinas e da verticalidade do Reservatório. Escoras inclinadas, toldos remendados e bancas sobre rodas dão silhueta estreita e ocupada.

Reaproveitar divisórias, becos, ruínas e corredores com pilares. Novos tiles/props: balcão com portinhola, toldo, placa de loja, louça, forno desmontado, fichário e carro de peças. Marco principal: toldo amarelo preso num campanário cortado; o balcão de Ema tem uma placa torta e uma panela azul. Depósitos usam grades abertas visíveis, não baús indistinguíveis da decoração.

Garantir entrada, balcão, antiga banca do casal, arquivo de encomendas, depósito e praça de avaliação. Bancas e arquivo são acessíveis antes do encontro. O gerador varia ligações, barracas vazias e segredos, sem esconder os recursos essenciais. A rota dos Salões existe atrás do carro de peças; movê-lo resolve um acesso real. Pilares de sustentação relevantes têm base marcada; paredes rompíveis apresentam rachaduras; objetos examináveis recebem contorno simples ao alcance. Nenhuma neblina dinâmica é necessária.

Depois: depósito aberto, placa escolhida na subquest, carro movido e balcão reocupado ou vazio. Não retornar toldos ou bens confiscados ao estado inicial após morte.

## Pessoas principais

**Rute, avaliadora e adversária.** Catalogou pertences de famílias que desapareceram. Usa etiquetas impecáveis numa feira quebrada e avalia até presentes. Deseja preservar acordos; teme que tudo volte a ser tomado pela força. Entretanto, declarou vários bens sem dono e vendeu trabalho alheio como próprio estoque. Seu problema é posse e responsabilização, não controlar comida. Não participou do assassinato e não sabe sua finalidade. Perguntas diretas recebem esse limite. Depois pode avaliar trocas sem mandar no mercado, abandonar o balcão ou morrer, se morte letal existir.

**Ema, comerciante.** Cozinha, negocia peças e lembra o primeiro encontro do casal numa banca próxima. Experimenta nomes absurdos para sua loja porque antes usava a marca de um patrão. Conhece Brina como fornecedora, ignora o rito e não tem notícias atuais de Lia. Quer manter autonomia, com ou sem um posto no hub.

**Bento, recorrente no retorno.** Alimenta os moradores e inicialmente decide sozinho a distribuição. Sua generosidade é real; não inocenta seu voto pelo sacrifício. Se confrontado diretamente com suspeitas, segue a confissão prevista na base; não inventar um bloqueio de diálogo até o mapa 8.

## Etapas implementáveis

### P03-E01 — Pedido no hub

**Início:** chegada concluída; cozinha ainda improvisada. **Lugar:** forno de Bento. **Ação:** examinar a chapa e ouvir alternativas de retirada: troca por um lote excedente ou recuperação do estoque abandonado. **Cena:** “O pão saiu cru?” / Bento: “Só por dentro. Por fora ele já morreu.” Se Bento estiver morto ou ausente, o esquema de montagem junto do forno identifica peças e origem; o protagonista pode assumir a tarefa sem interlocutor. **Estado:** missão oferecida, peças identificadas. Recusar mantém oferta sem marcar aceite; morte ou saída não altera nada. **Avança:** aceitar e selecionar Mercado, sem exigir concluir mapa 2.

### P03-E02 — Chegada e direitos

**Início:** primeira entrada. **Lugar:** entrada e balcão de Ema. **Ação:** explorar, conversar e examinar um recibo de peças. Rute chama de seu um lote que Ema já pagou. **Cena:** Rute: “Está no meu depósito.” / Ema: “Também estão meus impostos. Quer ficar com a minha dívida?” **Estado:** disputa conhecida; surgem troca e retirada física. Retirada mantém recibo examinado; morte não reinicia encontro. **Avança:** alcançar antiga banca e depósito, em qualquer ordem.

### P03-E03 — O casal e a assinatura

**Início:** banca acessível, mesmo se personagens ausentes. **Ação:** examinar encaixe que o protagonista fabricou e encomenda de Brina no arquivo. **Cena:** Ema: “Lia reclamou que sua placa tapava o sol da banca dela.” / Protagonista: “Então eu mudei a placa.” / Ema: “Três vezes. Vocês discutiram as três.” O encaixe e a anotação antiga preservam a lembrança essencial sem Ema; o protagonista reconhece que a discussão virou trabalho conjunto. **Estado:** lembrança descoberta, prova de autoria disponível. Retorno não consome documentos. **Avança:** selecionar uma proposta para o lote principal.

### P03-E04 — Avaliar quem pode tomar

**Início:** jogador solicita retirada; Rute resiste ao questionamento de sua posse. **Lugar:** praça e arena separada. **Ação:** apresentar recibo, propor abrir os registros ou enfrentar. **Cena:** Rute: “Se todo mundo levar o que diz que é seu...” / Protagonista: “Então vamos descobrir de quem é.” **Estado:** encontro ativo. Retirada suspende discussão; morte preserva provas e preparação, reiniciando apenas confronto não resolvido. **Avança:** acordo, rendição ou derrota; morte do oponente é estado separado.

### P03-E05 — Peças e caminho

**Início:** retirada resolvida. **Lugar:** depósito e carro. **Ação:** recolher conjunto único e deslocar carro pela passagem estabilizada. Se Rute morreu, seus registros e Ema ou o protagonista organizam a retirada; não fabricar agradecimento. **Evento:** mapa do corredor no arquivo identifica Salões. **Estado:** conjunto obtido, rota 5 utilizável. Abandonar agora conserva ambos, com retorno ainda pendente. **Avança:** voltar ao hub; subquests podem continuar depois.

### P03-E06 — Primeira mesa

**Início:** conjunto depositado no forno. **Lugar:** cozinha. **Ação:** acompanhar reparo e escolher participar ou apenas deixar peças. **Cena, somente com Bento vivo e presente:** “Guardei um lugar.” / Protagonista: “Eu não disse que ficava.” / Bento: “A cadeira aguenta uma refeição só.” **Estado:** forno funcional; moradores vivos reconhecem método de retirada. Doro usa ferramentas manuais se mapa 2 não foi feito; se estiver morto ou ausente, o protagonista segue o esquema e instala as peças com ferramentas iniciais. Falas de mortos são omitidas; não inventar refeição coletiva sem participantes. **Avança:** mapa 5 selecionável. Entrada tardia após revelação permite silêncio ou cobrança; não impõe jantar afetuoso.

## Encontro físico e acordo

### Perfil de combate e gatilhos

**Frequência escolhida pelo usuário:** dois a três encontros comuns intercalados com história e um chefe principal. Aqui há dois encontros comuns e um terceiro opcional de quest, sem adicionar outro grupo para completar contagem. Composições são propostas; arena, turnos e atributos ainda serão implementados.

| ID e momento | Lugar e composição proposta | Gatilho e alternativas |
| --- | --- | --- |
| **C03-01**, durante E02, antes do balcão | Beco de chegada; dois Sentinelas, guardas que confundem o equipamento do retornado com saque | Guardas visíveis avisam antes de bloquear. Aproximar-se abre diálogo; insistir em passar armado inicia arena após confirmação. Explicar destino ou guardar arco permite passar; retirar-se mantém aviso sem perseguição no diálogo |
| **C03-02**, entre E03 e E04 | Caminho do depósito; dois Rastejantes alojados nas barracas vazias | Criaturas visíveis defendem ninho. Aproximação após aviso, ou ação de atacar, abre arena; usar desvio garantido ou afastá-las com comida local evita luta. Não colocar sobre documento de Brina ou encaixe do casal |
| **C03-Q01**, durante Nome na fachada, terceiro comum opcional | Barraca lateral; um Bruto como cobrador que reivindica a antiga placa de Ema | Examinar a placa abre disputa, sem ataque automático. Acordo de propriedade, criar placa nova com Ema ou desistir dispensam arena; desafiar inicia combate explícito. Documento essencial e missão do forno não passam por esta disputa |
| **B03-01**, E04 | Praça de avaliação; Rute | Pedido de retirada seguido de oposição. Diálogo, interrupção, rendição e confronto conforme esta ficha; examinar recibo não inicia batalha |

Nenhum combate começa ao abrir inventário, registro ou diálogo. Menus de conversa congelam ataques e deslocamentos hostis; criar arena exige o gatilho declarado. Resolvido ou evitado um encontro, seu estado persiste; morte do protagonista não repõe automaticamente grupos vencidos.

Rute usa uma vara de avaliação para empurrar o personagem e deslocar caixotes. Anuncia “valor de madeira”, “valor de ferro” antes de atingir coberturas correspondentes. Ataques deixam corredores visíveis; derrubar a própria etiqueta a faz hesitar, sem virar piada repetida a cada golpe.

Acordo exige verificar uma reivindicação e retirar sua autoridade unilateral sobre bens. Recibo principal basta; concluir autoria de Brina é desnecessário. É possível iniciar combate, parar e apresentar prova. Vitória concede acesso, mas registrar tomada unilateral, devolução ou posse reconhecida produz comentários distintos. Se tudo foi quebrado, chapa essencial permanece num nicho protegido; danos afetam comércio e confiança, não destroem progresso.

## Duas subquests

**Ema — Nome na fachada.** Começa ao perguntar pela placa coberta. Primeiro, abrir o arquivo garante o contato de Brina e documento com assinatura original, mesmo se Oficinas vier depois. Isso conclui a etapa comercial da quest de Brina quando ativa; caso contrário, a informação fica registrada. Depois, Ema decide usar seu nome ou criar marca coletiva com fornecedores. Por fim, escolher com ela permanecer, abrir posto visitante ou aceitar residência permanente. Reencontro mostra preços assinados por quem fabrica e placa nova. Recusa mantém seu plano independente; atribuir novamente trabalho a Rute quebra promessa. Se Ema morrer, a placa pode ser preservada, sem simular sua decisão de morar. Se Brina morrer, colegas preservam sua assinatura e Ema lamenta, sem recrutá-la.

**Bento — Mesa para todos.** Começa no retorno. Etapa inicial: ajudar a arrumar lugares ou perguntar quem decide porções. Segunda: incluir interlocutores do mercado na organização, também por visita, sem exigir recrutamento. Terceira: quando sua responsabilidade for conhecida, cobrar confissão pública, estoques compartilhados e proteção de testemunhas; as provas do mapa 8 permitem uma prestação documentada, mas não são requisito para começar uma cobrança após confissão antecipada. Publicar a prova, retirar-se da conversa e reparar o forno não transferem automaticamente estoques. Registrar separadamente exigência, compromisso aceito e entrega efetiva de controle; só a última altera responsáveis e acesso ao estoque. Cozinhar não completa reparação. Recusa deixa rotina centralizada até responsabilização escolhida; compromisso quebrado gera ausência na refeição. Se Bento morrer, organização coletiva pode continuar, mas sua confissão pessoal nunca ocorre. Continuar a quest não exige perdoá-lo.

## Hub, selos, epílogos e revisão

Ema só recebe selo se aceitar acolhimento permanente; visita e comércio exterior não vinculam. Depois da revelação, a origem e custo precisam ser explicados antes dessa escolha. Rute permanece exterior por padrão; personagens mortos não retornam como residentes. Bento já é vinculado.

No sacrifício final, o mercado conserva ou perde sua rede conforme relações e mortes; Bento só aparece reparando se suas ações ocorreram. Na restituição, Bento e demais vinculados morrem; Ema visitante/exterior e Rute exterior sobrevivem se vivos. A reforma do forno permanece nas ruínas.

Validar ordem 3→2, autoria recusada, confronto letal, retorno sem peças e revisita pós-revelação. Recursos, encaixe do casal, documento de Brina e rota 5 continuam acessíveis. Rute não reaparece como chefe vencida; a praça mostra quem passou a decidir.
