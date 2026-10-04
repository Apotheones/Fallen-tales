# ARROWFALLEN — bestiário, história e comportamento

Versão de trabalho: 04/10/2026. Entrega: especificação para autor, artista e IA implementadora. Este arquivo não modifica o jogo.

## 1. Escopo e precedência

O combate confirmado nesta revisão é **fásico**: ação em tempo real em arena separada, seguida de pausa social. Fontes mecânicas: `src/battle.lua`, `src/enemies.lua`, `src/systems.lua`, `src/environment.lua`, `src/battle_talks.lua` e [COMBATE_MERGE.md](COMBATE_MERGE.md). As descrições antigas de movimento limitado e resolução por turnos não definem este documento.

Fontes narrativas: [BASE_NARRATIVA.md](BASE_NARRATIVA.md), [GUIA_ESCRITA_DEVIN.md](GUIA_ESCRITA_DEVIN.md), `src/battle_barks.lua` e as fichas de campanha. Geografia: [PLANO_REFUGIO_ANDLAR.md](PLANO_REFUGIO_ANDLAR.md). Os mapas antigos não equivalem automaticamente a reinos.

**Separação obrigatória:**

- **ATUAL:** comportamento observado no código nesta data; não é aprovação definitiva do balanceamento.
- **PROPOSTA:** história ampliada, aparência, gestos e falas inéditas. Pode ser incorporada sem mudar ataques.
- **FUTURO:** regra nova explicitamente especificada, ainda sem implementação. Não apresentar como conteúdo entregue.

Objetivo: o jogador entende o adversário por aquilo que ele protege, pela forma de atacar e pelo que faz quando deixa de atacar. Os inimigos não recebem todos a mesma origem nem o mesmo motivo. Uma fera não é obrigada a conversar; um constructo não precisa ser um morador inocente aprisionado; uma pessoa não perde responsabilidade porque estava com medo.

Os onze tipos não humanos abaixo já existem mecanicamente. Algumas origens continuam indefinidas ou herdadas do protótipo; as histórias propostas os integram sem converter seus antigos rótulos em novo fato sobre o pacto. Os cinco chefes humanos implementados têm continuidade própria. Cinco adversários posteriores são tratados separadamente como trabalho futuro.

## 2. Contrato comum para a IA

### 2.1 Unidades e relógio

- Posição e alcance em **células**, não pixels. Tempo em **segundos de simulação**. Dano em pontos de vida.
- Distância normal: Manhattan, `abs(ax-bx) + abs(ay-by)`.
- Direções de ataque: quatro cardeais. Eixo dominante: horizontal se `abs(dx) >= abs(dy)`, vertical caso contrário. Empate horizontal.
- Simulação fixa em 1/120 s. Sprites, câmera, partículas e animações apresentam o resultado; não decidem colisão, dano ou duração de estados.
- `move` e intervalo de projétil são durações por célula. `think` é intervalo de decisão; não é velocidade de caminhada. Ausência de `move` usa a duração da entidade: 0,24 s na arena atual.
- O jogador anda, vira, carrega o arco e bloqueia frontalmente. Não pressupor esquiva com invulnerabilidade, arma corpo a corpo, mira livre em 360 graus ou stamina infinita.
- Referência atual: arco causa 3 de dano e carrega em 0,72 s; o jogador inicial tem 10 de vida, sujeito à campanha e melhorias. Não calcular dificuldade apenas por HP.

### 2.2 Ciclo da arena — ATUAL

1. Abordagem e abertura congelam hostilidade. Diálogo pode resolver o conflito antes da arena.
2. Unidades ativas começam com graça de 0,8 s, escalonada em 0,15 s por índice de spawn. Casulos têm relógio próprio.
3. A ação roda em tempo real. Cota padrão: dois ataques resolvidos por unidade principal. Erro conta; dois projéteis de uma rajada contam como um ataque.
4. Timeout de 12 s ou cumprimento da cota pede fechamento. Estagnação em busca por mais de 4 s também libera a unidade da obrigação de atacar.
5. Fechamento espera a arena quieta: avisos, investidas, rajadas, projéteis, marcas e quedas pendentes terminam. A pausa não corta um ataque já anunciado.
6. O respiro dura 0,4 s; abre menu ou beat de conversa. Pausa, diálogo e perda de foco congelam relógios e projéteis no mesmo quadro.
7. CONTINUAR retoma a ação. AGIR/USAR/POUPAR/FUGIR seguem o contrato existente. Fuga é uma travessia com último ataque dos hostis, não sorteio.

Quem cumpriu a cota pode respirar em `wait`; quem aceitou trégua permanece em `calmed`. Esses estados têm motivos distintos e não devem compartilhar uma transição automática para hostilidade.

### 2.3 Máquina de estados — ATUAL

| Estado | Entrada e atividade | Saída |
| --- | --- | --- |
| `seek` | Procura posição válida; só decide quando timer e movimento permitem | Ataque possível → `warn`; senão tenta um passo e reinicia decisão |
| `warn` | Guarda direção, células e referências do ataque; mostra preparação | Timer zera → resolve do tipo |
| `dash` | Avança na linha já armazenada, uma célula por passo | Fim, ocupante ou bloqueio → recuperação |
| `volley` | Aguarda segundo tiro já anunciado | Dispara sem mirar de novo → recuperação |
| `recover` | Não inicia outro ataque; mantém vulnerabilidades normais | Fim → busca, recuo ou segundo ataque previsto |
| `retreat` | Tenta passos de afastamento previstos pelo tipo | Passos concluídos ou bloqueados → busca |
| `exposed` | Vulnerabilidade extra do Rastejante que errou | Após 1,3 s → busca |
| `dormant` | Casulo aguarda eclosão; não ataca | Timer ou dano sobrevivido → substituição por Rastejante |
| `wait` | Respiro de fase ou de fuga, sem novos ataques | Retomada da arena libera busca |
| `calmed` | Trégua, sem perseguição nem novo ataque | POUPAR remove; golpe válido desfaz trégua |

Não adicionar `resolve` como novo estado: no catálogo atual é função disparada ao terminar `warn`. Morte, substituição e retirada usam os caminhos existentes da arena.

### 2.4 Regras de compromisso, dano e saída

- **Mira travada:** ao entrar em `warn`, guardar a geometria. Sair dela é uma resposta válida. Não seguir o jogador com um ataque anunciado como fixo.
- **Cobertura:** tiros param nas peças e nos corpos. Aliados interceptam projéteis sem receber fogo amigo. Marcas, jatos e quedas têm suas próprias regras de área e podem atingir outras unidades.
- **Mudança do terreno:** obstáculos novos podem interromper um golpe. Não aumentar a área prometida porque uma parede desapareceu; revalidar sem escolher outro alvo.
- **Armadura frontal:** bloqueia flecha alinhada vindo pela frente. Flanco, costas e dano de área têm tratamento distinto. Recuperação não remove blindagem automaticamente.
- **Escudo do jogador:** frontal, com fôlego finito. Não bloqueia marca no chão nem jato de área. Atravessar a linha continua sendo opção quando faltar fôlego.
- **Queda ambiental não é martelo de Janda:** `Environment.impact` arma queda de pilar por 0,62 s, com faixa máxima de cinco células e esmagamento fatal no código atual. Pode verificar tanto destino quanto origem do corpo em movimento. Isso afeta impactos de Bruto/Bruto Demolidor/Demolidor e mineração; não substituí-lo pelo dano corporal 2. O martelo de Janda usa resolução própria de arena, dano 2 e reposicionamento. Buracos também seguem `killFatal`; `nonLethal` continua valendo para a rendição de unidades protegidas pelo encontro.
- **Dano durante preparação:** não cancela universalmente `warn`. Só criar interrupção onde especificada; não transformar animação de acerto em stun mecânico.
- **Trégua:** alcançar limiar social marca `mercy/calmed`. Estados ociosos param; ataque já comprometido não é apagado por uma nova regra inventada.
- **POUPAR:** permitido em quem está `mercy` ou `calmed`; menu ou E a distância euclidiana menor que 1,5 célula. A aproximação pode ocorrer enquanto outros atacam.
- **Trair trégua:** golpe efetivo, não tentativa cancelada nem flecha bloqueada, zera convicção e devolve hostilidade.
- **Não letal:** unidade → encontro → contexto social decide `nonLethal`. Quando ativo, golpe fatal vira rendição com HP 1 e retirada. Ser humano por si só não arma esse campo.
- **Persistência:** resultado resolve o encontro pelo ID existente. Morte do protagonista retorna à Colina sem repor decisões. Não criar respawn aleatório nem loot indispensável por sorte.
- **Invocados:** não são unidades principais de conclusão/cota. Uma eclosão de casulo principal continua contando como unidade principal; preservar `summoned` quando o casulo foi invocado.

### 2.5 Valores de referência — ATUAL

`HP arena` é o valor inicial de unidade autoral sem `u.hp`. `HP catálogo` é o valor do def em `Enemies`, usado em spawns que não passam por `ROLES`. Eles diferem hoje; não os unificar silenciosamente.

| kind | HP arena / catálogo | Dano principal | Aviso | Recuperação | Armadura frontal |
| --- | --- | --- | --- | --- | --- |
| `crawler` | 4 / 4 | 1 | 0,70 | 0,60; erro expõe 1,30 | não |
| `ranger` | 6 / 5 | 2 | 1,05 | 0,75 + recuo | não |
| `dasher` | 6 / 6 | 2 | 0,85 | 0,85 | sim |
| `sower` | 6 / 5 | 2 por explosão | 0,80 + fusível 0,85 | 1,20 | não |
| `watcher` | 5 / 6 | 2 | 0,95 | 0,90 | não |
| `breaker` | 10 / 10 | 2; ambiente separado | 0,90 | 1,00 | sim |
| `veteran` | 8 / 8 | 2 por tiro | 1,10; intervalo entre tiros 0,16 | 1,30 + recuo | não |
| `husk` | 3 / 3 | não ataca | eclosão em 3,50 | não se aplica | não |
| `warden` | 12 / 24 | 2 | 1,15; fase 2: 0,95 | 0,95; fase 2: 0,70 | sim; perde na fase 2 |
| `demolisher` | 8 / 30 | 2; ambiente separado | 1,00; fase 2: 0,85 | 1,10; fase 2: 0,80 | sim |
| `regent` | 10 / 28 | 2 | tiro 0,90; marca 0,80; invocação 1,10 | 0,90; fase 2: 0,70 | não |
| `runa` | 10 / 10 | 1 | 1,05 | 1,00 + recuo | não |
| `janda` | 14 / 14 | 2 | martelo 1,00/0,80; investida 0,85 | 1,00 | não |
| `rute` | 12 / 12 | empurrão 0; tiro 2 | caixa 0,90/0,75; tiro 1,05 | 0,90 + recuo | não |
| `ivo` | 14 / 14 | 2 | jato 1,00/0,80; tiro 1,05 | 0,90 + recuo | não |
| `beltran` | 12 / 12 | empurrão 0; prensa 1 | 0,90/0,75 | 0,90 | não |

Fase 2 dos chefes atuais: vida menor ou igual a 50% do máximo efetivo da entidade. A redução do aviso especial não implica reduzir todos os ataques herdados. Na Regente, avisos da fase 2 são multiplicados por 0,8 e fusível da marca cai para 0,70 s.

### 2.6 Decisão e locomoção — ATUAL

| kind | `think` | Movimento em busca | Intervalo entre recuperação e busca |
| --- | --- | --- | --- |
| `crawler` | 0,24 | 0,20/célula | 0,12; após exposição: 0,15 |
| `ranger` | 0,34 | 0,24/célula | recuo: início 0,10, passos 0,26, busca 0,15 |
| `dasher` | 0,28 | 0,24/célula | 0,12 |
| `sower` | 0,34 | 0,24/célula | 0,12 |
| `watcher` | 0,34 | 0,34/célula | 0,12 |
| `breaker` | 0,28 | 0,24/célula | 0,12 |
| `veteran` | 0,34 | 0,24/célula | recuo igual ao ranger, com um passo |
| `husk` | não decide em dormência | não anda | filho nasce com timer 0,50 |
| `warden` | 0,32; fase 2: 0,24 | 0,24/célula | 0,18 |
| `demolisher` | 0,30 | 0,24/célula | 0,15 quando não encadeia |
| `regent` | 0,30 | 0,24/célula | 0,15 |
| `runa` | 0,35 | 0,24/célula | recuo herdado do ranger |
| `janda` | 0,30 | 0,24/célula | 0,12 |
| `rute` | 0,34 | 0,24/célula | recuo herdado do ranger |
| `ivo` | 0,34 | 0,24/célula | recuo herdado do ranger |
| `beltran` | 0,28 | 0,24/célula | 0,12 |

Esses valores descrevem a entidade de arena revisada. Duração de movimento autoral ou override posterior precisa ser lida na entidade efetiva. Não somar `think` a todos os avisos: ele só é reposto no caso de busca que não engajou. Caminho usa os helpers existentes e evita perigo ambiental conhecido; ordem cardeal de vizinhos é +x, -x, +y, -y, sem RNG novo.

## 3. Fichas de inimigos existentes

Cada ficha conserva o `kind`. A história e a direção visual são PROPOSTA; o algoritmo é ATUAL, salvo indicação contrária. Não transformar o texto literário em condição de código implícita.

### E01 — Rastejante | `crawler`

**História proposta.** Os Rastejantes descendem das bestas mantidas nas dependências da casa. Depois que as pessoas partiram, aprenderam o percurso dos restos de comida, dos canais quentes e dos canteiros. Sua agressividade varia com o lugar: um caça, outro protege alimento. Não conhece o assassinato nem odeia o protagonista por sua condição. O território permite sobreviver; um desconhecido entrando nele é um problema concreto.

**Aparência e gesto.** Corpo baixo, patas dianteiras largas, mandíbula curta e placas de terra nas costas. A garganta se expande antes da mordida. No canteiro, põe o corpo sobre os brotos; não inventar filhotes obrigatórios para explicar esse contexto. Não fala: chiado, farejo e postura.

**Algoritmo atual.** Busca célula com distância Manhattan 1 do jogador. Movimento de 0,20 s por célula; decisão a cada 0,24 s. Adjacente, guarda exatamente a célula atual do jogador e prepara `bite` por 0,70 s, sem avançar nem remarcar. Ao resolver, só fere jogador ou ressonador que ainda ocupa aquela célula. Acerto → recuperação 0,60 s. Erro → `exposed` por 1,30 s; dano recebido nesse estado ganha +1. Não recebe um salto ou investida só porque o nome sugere fera rápida.

**Resposta e social.** Sair da célula e responder com arco durante exposição. Não negocia verbalmente. OBSERVAR existe; DISTRAIR continua proposta desabilitada. No contexto `canteiro`, afastamento por corredor pode resolver na exploração conforme o diálogo existente.

**Verificar.** Alvo muda de célula durante aviso → nenhum dano na nova posição; erro produz exposição; OBSERVAR não cria trégua; pausa não consome o timer.

### E02 — Sentinela | `ranger`

**História proposta.** Uma devota conserva o posto que ninguém formalmente encerrou. Ainda distingue acesso técnico, passagem pública e equipamento de trabalho, mas os responsáveis por explicar as mudanças não voltaram. A competência sobreviveu melhor que a informação. Em diferentes encontros, seu erro pode ser interpretar uma aljava como saque ou repetir uma interdição já desnecessária. Não precisa ter recebido o selo do Refúgio.

**Aparência e gesto.** Capuz de tecido gasto, braço do arco descoberto, linhas de reparo concentradas nos punhos. Abre o cotovelo antes de apontar; durante o recuo, mantém atenção no viajante. O posto ou a placa identifica seu contexto, sem redesenhar a mecânica a cada região.

**Algoritmo atual.** Busca alinhamento cardeal visível entre 3 e 8 células. O gatilho real de tiro exige alinhamento e linha visível, sem limite adicional de 8 no `engage`. Guarda a linha até cobertura/borda; aviso 1,05 s. Dispara um virote de dano 2, intervalo 0,13 s por célula, alcance igual ao número de células guardadas. Recupera 0,75 s e tenta recuar dois passos. Recuo bloqueado não teleporta.

**Resposta e social.** Sair para outra linha, usar cobertura ou escudo frontal. FALAR BAIXO e TRÉGUA usam o limiar social atual, normalmente 2; contexto pode mudar texto e ACTs. A prova de acesso deve responder ao posto, não fingir que todo encontro exige elogio. Não adicionar PROVOCAR ao menu desse tipo apenas porque existe fallback técnico.

**Verificar.** Tiro não gira após aviso; aliado intercepta sem dano; corpo atrás de parede não é atingido; recuo sem célula livre termina com busca.

### E03 — Bruto | `dasher`

**História proposta.** Um constructo de choque foi feito para ocupar uma abertura enquanto pessoas passavam atrás dele. Restou-lhe a ideia de que deixar alguém cruzar seria abandonar o trabalho. Em entulho, conserva a obstrução; numa obra, conserva a interdição; como cobrador, pode repetir uma ordem injusta. Essas funções são contextos, não a memória literal de um humano morto.

**Aparência e gesto.** Placa larga de pedra à frente, juntas de argila nas laterais e braços curtos para o tamanho do torso. Antes de correr, inclina a placa e comprime as juntas. Ao parar, precisa recompor o peso. Três marcas legíveis: frente larga, flancos estreitos, corpo inclinado na preparação.

**Algoritmo atual.** Busca adjacência ou alinhamento visível a até 4 células. Alinhado a até 4, guarda investida de no máximo 4 células, aviso 0,85 s. A linha pode anunciar impacto na primeira peça minerável, mas não a atravessa como um Demolidor. Executa passos rápidos, intervalo padrão 0,065 s, até a primeira colisão ou fim. Dano corporal 2, recuperação 0,85 s. Armadura frontal permanece na recuperação.

**Resposta e social.** Atrair a linha, sair para o lado e mirar no flanco. PROVOCAR força eixo dominante no próximo engajar e encurta aviso por fator 0,8; não cria curva na investida. TRÉGUA responde à função de bloqueio; INTIMIDAR é recusado.

**Verificar.** Frente bloqueia flecha alinhada; lado recebe; investida não acompanha curva do jogador; queda de pilar usa regra ambiental, não dano corporal duplicado.

### E04 — Semeador de Âmbar | `sower`

**História proposta.** O Semeador mantém uma paisagem imobilizada. Onde vê passos, entende desgaste; onde vê desgaste, deposita uma marca para impedir o próximo movimento. Antes da ruína, esse cuidado talvez preservasse trechos funerários frágeis. Agora impede também quem poderia repará-los. Seu conflito é conservar o chão sem perguntar a quem precisa usá-lo. A história não transforma âmbar em combustível capaz de substituir a vida roubada.

**Aparência e gesto.** Figura estreita sob tecido terroso, bolsa baixa de resina e dedos com crostas translúcidas. Ergue três dedos para marcar a faixa. O aviso visual começa no chão, não numa fala longa que o jogador precise ler enquanto corre.

**Algoritmo atual.** Busca distância 3–7. Pode marcar a 2–7, desde que não tenha hazard próprio ativo. Guarda três células em linha centrada na posição do jogador, orientada pelo eixo dominante semeador–alvo; inclui apenas piso válido. Aviso 0,80 s, depois cria hazard com fusível 0,85 s. Explosão única de dano 2 nas células guardadas; recuperação 1,20 s. Não é campo contínuo, veneno ou espinho persistente.

**Resposta e social.** Abandonar a faixa antes da explosão; escudo frontal não protege. Hazard pode atingir outras unidades, inclusive o autor. FALAR BAIXO e TRÉGUA negociam uso do terreno; provocações são recusadas pelo conteúdo atual.

**Verificar.** Marca fica na posição antiga; uma explosão só; não cria segunda marca própria enquanto a primeira está viva; pausa congela o fusível.

### E05 — Vigia dos Ecos | `watcher`

**História proposta.** Seu ofício era velar por cruzamentos, contando quem chegava e quem faltava. Acendeu a mesma chama tantas vezes que passou a considerar os quatro caminhos uma única responsabilidade. Não distingue uma passagem de uma despedida. Sua voz pergunta por direções, sua atenção segue a chama; deixá-lo descansar exige admitir que um cruzamento pode continuar existindo sem sua vigília.

**Aparência e gesto.** Corpo vertical, pequena chama no peito ou na mão, cabeça voltada mais que o torso. Quatro costuras claras percorrem o tecido. Antes do disparo, firma os pés e abre os braços; a silhueta prepara a cruz que aparece no chão.

**Algoritmo atual.** Busca distância 1–4. Pode iniciar a cruz a até 8 células, mesmo desalinhado. Guarda quatro raios cardeais até peça/borda. Aviso 0,95 s; dispara até quatro virotes simultâneos, dano 2, intervalo 0,11 s por célula, alcance individual guardado. Recuperação 0,90 s. Não é uma cruz curta de alcance fixo: a fala antiga que promete alcance curto precisa ser revisada se incorporada.

**Resposta e social.** Ocupar diagonal ou usar cobertura; não permanecer no eixo só porque está longe. APAGAR A VELA está implementado: marca `calmed` e permite retirada, sem exigir item de vela nem fingir apagar projéteis já lançados. TRÉGUA usa conversa normal.

**Verificar.** Braços limitados por cobertura; cruz conserva origem; `calmed` deixa de buscar; vela não remove disparos em voo por regra nova.

### E06 — Bruto Demolidor | `breaker`

**História proposta.** Este constructo executava abertura de caminhos. A placa frontal servia para suportar material que caía; o resultado esperado era uma passagem, não um inimigo esmagado. Sem alguém indicando o que deve permanecer, passou a contar tudo à frente como obstáculo. Sua presença lembra que destruir e reparar podem usar a mesma força com decisões diferentes.

**Aparência e gesto.** Placa estreita em cunha, juntas expostas na cintura e braços endurecidos por poeira. Arrasta um pé ao alinhar o corpo, raspa a frente no piso e corre. Fragmentos são efeito visual; não criam projéteis secundários.

**Algoritmo atual.** Alinhamento a até 6 células basta se existe linha atravessável; cobertura minerável pode estar no caminho. Guarda até 6 células via `throughLine`, aviso 0,90 s, passos de 0,075 s, dano corporal 2. Atravessa paredes que abrem imediatamente. Pilar é anunciado com faixa de queda e interrompe a linha; buraco também encerra o trajeto. Não atravessa peça protegida. Recupera 1,00 s, mantém frente blindada.

**Resposta e social.** Cobertura frágil não basta; sair lateralmente ou dirigir ataque para um pilar com espaço seguro. PROVOCAR ajuda a escolher eixo; TRÉGUA oferece parar o serviço, não promete reconstruir tudo.

**Verificar.** Parede minerável abre; peça protegida não; pilar para investida e anuncia queda; golpe não ganha alcance atrás do pilar depois que ele cai.

### E07 — Sentinela Veterana | `veteran`

**História proposta.** A Veterana passou tanto tempo corrigindo a mira de outros que aprendeu a prever o primeiro recuo de alguém sob ameaça. Tem orgulho real no ofício e dificuldade de aceitar que abandonar uma ronda possa ser uma decisão competente. Sua segunda linha não é sorte: é um hábito de cobrir o espaço onde imaginou que o alvo fugiria. Respeitar habilidade não exige aceitar sua ordem.

**Aparência e gesto.** Tecido curto no braço de disparo, arco reforçado e postura menos alta que a Sentinela comum. Preparação em dois gestos: mira principal, cotovelo que indica a perpendicular. Não ocultar a segunda linha para criar uma surpresa injusta.

**Algoritmo atual.** Busca alinhamento visível a 3–8 células. Guarda duas linhas: direção principal para jogador e perpendicular; em alinhamento exato, perpendicular aponta +y se tiro horizontal, +x se vertical. Aviso conjunto 1,10 s. Primeiro tiro de dano 2 e intervalo 0,13 s/célula; `volley` por 0,16 s; segundo tiro com direção já guardada. Recupera 1,30 s e recua um passo. Rajada é uma cota, não duas.

**Resposta e social.** Escolher célula fora de ambas as linhas; usar cobertura sem entrar na perpendicular depois do primeiro disparo. PROVOCAR e TRÉGUA existem; reconhecer ofício é tom de conversa, não item mágico.

**Verificar.** Mover após primeiro tiro não redireciona segundo; pause congela intervalo da rajada; ambos os raios aparecem na prévia.

### E08 — Eco Nascente | `husk`

**História proposta.** Um casulo reúne uma despedida que ainda não encontrou forma. Não contém um bebê humano nem alguém necessário para resolver o pacto. Dentro dele há repetição de som e movimento, sem interlocutor capaz de consentir. Dar-lhe essa indefinição conserva o desconforto sem obrigar o jogo a tratar todo combate como assassinato de um antigo morador.

**Aparência e gesto.** Bolsa de resina ligada a fibras secas, luz interna com pulso irregular. Uma fissura desloca o brilho antes da eclosão. Não acrescentar contador falante nem ataque de explosão: o perigo é aquilo em que se transforma.

**Algoritmo atual.** `dormant`, HP 3, timer 3,50 s. Timer termina → cria `crawler` na mesma posição e remove casulo. Na campanha, dano que o casulo sobrevive também chama eclosão; dano que o elimina não deve criar um Rastejante sobrevivente. A criatura recém-criada mantém o estado `summoned` do casulo e tem graça de 0,50 s. Casulo principal adormecido não prende a cota, mas ainda é unidade viva do encontro.

**Resposta e social.** Resolver antes da eclosão ou lidar com a fera depois. EMBALAR reinicia o timer apenas enquanto `dormant`; não concede `mercy`, não é POUPAR automático. Recusa conversa normal e não ganha fala humana por ter retrato.

**Verificar.** Um único filho; nenhuma recompensa duplicada; status invocado preservado; EMBALAR não funciona no Rastejante já nascido.

### E09 — Guardião dos Ecos | `warden`

**História proposta.** É o porteiro de uma instituição funerária mais antiga que o crime do protagonista. Reconhece uma passagem pelo dever de conservá-la fechada. Sua blindagem não é o selo pessoal de acolhimento do Refúgio: é proteção física do constructo. A narrativa pode conservar memória de ordens antigas sem declarar quem realizou todos os ritos do mundo. Aurel continua responsável pelo assassinato específico.

**Aparência e gesto.** Torso de pedra alta, encaixe frontal de metal e haste de trabalho. Para a cruz, abre a haste; para a investida, recolhe-a e baixa o torso. Ao meio da vida, a placa frontal se parte visualmente junto da perda real de armadura.

**Algoritmo atual.** Alterna `cross → dash → cross`; começa com cruz. Precisa linha visível; investida exige distância até 4. Cruz lança quatro tiros como Vigia; dash usa quatro células. Fase 1: aviso 1,15 s, recuperação 0,95 s. A 50% de HP, remove blindagem frontal, aviso passa a 0,95 s, recuperação 0,70 s. A troca ocorre pelo máximo efetivo da arena, não pelo HP do protótipo. Dano 2.

**Resposta e social.** Flanquear antes da quebra; ler cruz e corredor por gestos distintos. TRÉGUA funciona pelo limiar normal. CITAR A ORDEM continua gesto de cena desabilitado; não inventar chave obrigatória para poupar.

**Verificar.** Alternância estável; quebra uma vez; frente recebe flecha após quebra; limite de dash permanece 4 na fase 2.

### E10 — Demolidor da Câmara | `demolisher`

**História proposta.** Tentou abrir à força uma casa que mantinha seus ecos encerrados. A abertura virou hábito e o hábito perdeu medida. Diferente do Bruto Demolidor, não se limita a cumprir serviço: insiste que nada pode estar preso se todas as paredes forem ao chão. Essa intenção explica a violência, mas não torna seguras as pessoas sob as estruturas. Sua história local não oferece saída alternativa para o pacto.

**Aparência e gesto.** Constructo assimétrico com ferramenta pesada incorporada ao braço, pedra rachada no ombro e frente reforçada. Preparação mais funda que a do Bruto; na fase 2, mantém o corpo baixo depois da primeira corrida para anunciar que pode insistir. Cada nova corrida ainda precisa de aviso.

**Algoritmo atual.** Alinhamento a até 7 células, linha atravessável. Dash de até 7, atravessa peças mineráveis nas mesmas condições do `breaker`, passo 0,075 s. Aviso 1,00 s, recuperação 1,10 s. A 50% de HP: aviso 0,85 s, recuperação 0,80 s e pode encadear uma segunda investida após recuperar, se novo gatilho for válido. A segunda mira é nova apenas porque inicia novo aviso. Armadura permanece. Dano corporal 2; queda de peça é perigo separado.

**Resposta e social.** Induzir impacto em estrutura anunciada e ocupar célula fora da queda. PROVOCAR existe. TRÉGUA é recusada; FALAR DE SAÍDA ainda é proposta desabilitada. Não afirmar que todo inimigo já possui rota pacífica implementada.

**Verificar.** Cada investida tem aviso; corrente não excede segunda investida por regra própria; cota de fase pode impedir novo ataque; cobertura protegida permanece.

### E11 — Regente de Âmbar | `regent`

**História proposta.** Regente é função de um canto, não aprovação de uma monarquia nova. Ela conserva cerimônias que não aceita terminar: onde deveria haver despedida, exige mais uma repetição. Seus nascentes parecem companhia, mas também prolongam o controle sobre a sala. Pode temer o silêncio sem que esse medo a torne inocente de impedir saídas. Seu âmbar não ressuscita Lia nem permite escolher outro sacrifício.

**Aparência e gesto.** Figura alongada sob tecido translúcido resinoso, dedos unidos por fios de cera, cabeça cercada de hastes que lembram suporte de instrumento. Tiro: braço apontado. Marca: dedos sobre o chão. Invocação: mãos em torno de uma célula vazia. As três preparações precisam de silhuetas diferentes.

**Algoritmo atual.** Ciclo determinístico `shot → mark → shot → summon`. Tiro pede linha visível, dano 2, aviso 0,90 s e projétil a 0,12 s/célula. Marca exige distância 2–8, três células centradas no alvo; aviso 0,80 s e fusível 0,85 s. Invocação escolhe célula adjacente livre na ordem de `summonSpot`, aviso 1,10 s e cria `husk` invocado. Limite: dois servos invocados vivos; sem célula ou no limite, pula etapa sem travar ciclo. Recuperação 0,90 s. Fase 2: avisos ×0,8, marca em cruz de até cinco células únicas, fusível 0,70 s, recuperação 0,70 s.

**Resposta e social.** Ler o tipo, sair da marca e controlar nascentes; não ganhar combate apenas por matar filhos. CANTAR DESPEDIDA soma convicção; TRÉGUA segue limiar atual. Canto não muda imediatamente todas as unidades hostis. Invocados não geram um ritual substituto do pacto.

**Verificar.** Limite de servos; salto de etapa sem espaço; geometria única da cruz; ciclo não reinicia a cada pausa; vitória depende das unidades principais.

## 4. Chefes humanos implementados

História e aparência detalhadas permanecem em [PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md](PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md). Aqui a intenção narrativa se traduz em regras observáveis. Não transformar medo, culpa ou arrependimento em buff automático.

### H01 — Runa | `runa`

**História.** Vigia vinculada ao Refúgio, repetiu a versão de sacrifício voluntário. Receia quem saiu da sepultura, sem ter decidido o assassinato. Seu confronto inicial atual é uma prova explícita de capacidade, não uma emboscada.

**Comportamento atual.** Família Sentinela: aviso 1,05 s, tiro de dano 1, HP 10, recuperação 1,00 s e recuo de dois passos. Não usa armadura, magia de selo ou projétil mortal instantâneo. No encontro `C01-Q1`, `nonLethal=true` converte queda em rendição. Limiar social 3. A prova nasce da aceitação do desafio e da flag declarada, não de ler o cenário.

**Gesto proposto.** Antes de atirar, tenta confirmar uma resposta com o rosto; depois firma o braço. Na pausa, dúvidas tornam a distância menor. A animação não aumenta o tempo real de aviso.

**Negociação.** Guardar arco, permitir inspeção, corrigir história e trégua. Vitória abre continuidade sem condenar Runa à morte. **Verificar:** dano fatal → HP 1/retirada sem efeito de morte; sua derrota não escolhe final; grade e conversa persistem.

### H02 — Janda | `janda`

**História.** Mestra das Oficinas, perdeu pessoas numa evacuação e usa segurança para conservar comando sobre ferramentas, pagamento e saída. Não participou do assassinato do protagonista. O jogador disputa o direito dos trabalhadores decidirem, não a existência da oficina.

**Comportamento atual.** Primeiro procura pilar a até 4 células dela. Escolhe o mais próximo do jogador; empate por varredura `(y,x)`. Guarda pilar e queda no eixo dominante pilar–jogador. Aviso 1,00 s, depois derruba com dano de arena 2 e reposicionamento das unidades atingidas, inclusive ela. Se pilar já caiu, golpeia vazio. Sem candidato, usa investida do Bruto até 4, aviso 0,85 s. HP 14, sem blindagem, recuperação 1,00 s. A 50% de HP, aviso do martelo cai a 0,80 s; não encurtar automaticamente investida herdada.

**Negociação e gesto.** Inspeção e voz dos trabalhadores respondem ao conflito; PROPOR PAUSA ainda está desabilitado como mecânica específica. Ergue ferramenta para o pilar escolhido, sem fingir mirar outro. **Verificar:** alvo eliminado não é substituído no resolve; queda não cresce; recursos principais da campanha não são pilares destrutíveis.

### H03 — Rute | `rute`

**História.** Conservou bens desaparecidos e tratou catalogação como propriedade. Sua avaliação tem utilidade real; seu abuso é decidir unilateralmente quem pode recuperar o que era seu.

**Comportamento atual.** Prioriza primeiro caixote válido na ordem autoral alinhado com jogador a distância 1–4 do caixote, não de Rute. Guarda célula destino um passo adiante. Aviso 0,90 s; tenta deslizar caixa. Jogador na célula cede mais um passo se livre; bloqueado, nada é movido. Empurrão não causa dano. Sem candidato, usa tiro de Sentinela, dano 2, aviso 1,05 s. HP 12, recuperação 0,90 s + recuo; fase 2 reduz aviso da caixa a 0,75 s.

**Negociação e gesto.** Recibo e abertura de registros questionam propriedade; recibo usa o item existente, não uma nova chave. Aponta para etiqueta/caixa antes do empurrão. **Verificar:** caixa desaparecida produz erro; parede atrás impede deslocamento sem dano inventado; tiro e empurrão têm leitura distinta.

### H04 — Ivo | `ivo`

**História.** Operador que reconhece riscos reais e não consegue delegar. Mantém interdição, mas confunde evitar erro com impedir que outra pessoa aprenda. Conhecimento técnico não o transforma em dirigente do pacto.

**Comportamento atual.** Se jogador ocupa canal configurado, prioriza linhas de `rows` e depois `cols`. Guarda banda de piso, aviso 1,00 s, jato de dano 2 em todas as unidades na linha/coluna, exceto Ivo. É área: ignora escudo frontal e pode ferir aliados. Sem banda válida, usa tiro de Sentinela. HP 14, recuperação 0,90 s + recuo; fase 2 reduz aviso do jato a 0,80 s. O jato não empurra, alaga permanentemente nem conecta novas salas.

**Negociação e gesto.** Esquema do canal habilita desvio e inspeção conjunta. Mão na válvula e pressão sonora anunciam a banda; água decorativa não amplia colisão. **Verificar:** banda não troca quando jogador muda de canal; Ivo imune ao próprio jato, aliado não; canais vêm do encontro ou default explícito.

### H05 — Beltran | `beltran`

**História.** Anfitrião que sabe acolher e tenta impedir que alguém saia do papel que distribuiu. Ocultou riscos para preservar apresentações. A disputa é circulação segura e liberdade de participação, não provar que arte ou festa são ruins.

**Comportamento atual.** Alinhamento e linha livre a até 4 células; investida fixa `shove`. Aviso 0,90 s, HP 12, recuperação 0,90 s. Contato empurra jogador até duas células livres. Zero células livres → prensa causa 1 de dano. Escudo frontal bloqueia empurrão e cobra energia pelo caminho próprio existente. Sem contato, não produz dano radial. Fase 2 reduz aviso a 0,75 s.

**Negociação e gesto.** Laudo/rota e função na realocação já têm gates próprios; plateia pode decidir. Preparação com braço aberto indica direção da imposição. **Verificar:** deslocamento para no primeiro bloqueio; um passo livre não recebe dano de prensa; vitória não cria elogio obrigatório nem mata automaticamente por ser chefe humano.

## 5. Adversários posteriores — FUTURO

Não há defs específicos desses cinco nomes em `Enemies`/`ROLES` na revisão acima. Os parâmetros abaixo são propostas implementáveis por etapa; não inserir todos agora nem usar fallback de Sentinela para simular que estão prontos. Preservar continuidade das fichas, adaptando sua geografia a reinos.

### F01 — Geraldo, controle do arquivo | kind proposto `geraldo`

**História.** Adulterou circulação para registrar uma partida inexistente. Conserva documentos e tenta controlar quem consegue lê-los. Não transferir sua autoria para Sabela.

**Proposta mecânica.** HP 12, sem armadura, recuperação 1,10 s. Ataque distintivo: fechar uma divisória física autoral; aviso 1,20 s nas células de fechamento, dano 1 e um passo de reposição quando alguém permanece ali. Só iniciar se a rota restante entre jogador e mesa continuar navegável; sem candidato, usar tiro simples da família Sentinela. Escolher divisória em ordem do encontro, não randomizar. Fixar destino no aviso, abortar se peça foi removida. Documentos essenciais ficam fora da área destrutível.

**Acordo.** Entregar acesso e reconhecer alteração. **Aceite:** prova continua acessível sem chefe; divisória nunca fecha única passagem; sem página física de arena, não implementar telecinese documental.

### F02 — Silvério, disputa de despacho | kind proposto `silverio`

**História.** Decide precedências para continuar indispensável. Prioriza cargos antigos sobre pedidos atuais; não é guardião de todas as saídas.

**Proposta mecânica.** HP 14, recuperação 1,10 s, sem armadura. Soltar carga vazia: seleciona plataforma autoral livre mais próxima do jogador, desempate `(y,x)`; aviso 1,20 s, duas células consecutivas da queda, dano de área 2 uma única vez, depois entulho não bloqueante. Distância de ativação até 6. Sem plataforma válida, tiro simples. No máximo uma carga pendente própria; guarda geometria, não rastreia alvo. Não usar refugiados como munição ou unidades hostis.

**Acordo.** Publicar critérios e liberar peças. **Aceite:** carga não destrói recurso único; alvo abandona faixa sem receber dano; sem plataforma autoral, fallback basta até entrega da arena.

### F03 — Edras, custódia da falsificação | kind proposto `edras`

**História.** Escreveu causa falsa de acidente sabendo do assassinato. Seu cuidado com o papel é verdadeiro e não diminui essa responsabilidade.

**Proposta mecânica.** HP 10, recuperação 1,20 s. Primeiro ataque: obstruir consulta empurrando estante pequena, usando a mesma regra de caixa de Rute, aviso 1,00 s e zero dano. Fallback de tiro deve ser apresentado como tentativa física de afastar, sem magia inédita. Uma única peça móvel por vez; sem estante física, não inventar selos mágicos que alterem o pacto. Não tornar arquivos inteiros destrutíveis para vencer.

**Acordo.** Reconhecer autoria, liberar leitura e correção. **Aceite:** perder o controle não apaga registros; interrogatório pode resolver antes da arena; não exige obter perdão para liberar prova.

### F04 — Lena, segurança da travessia | kind proposto `lena`

**História.** Trabalhou recentemente com Lia. Entrega essa informação antes de qualquer disputa; o combate não é taxa para saber que Lia vive.

**Proposta mecânica.** HP 14, recuperação 1,00 s. Alterna tiro de linha e empurrão de controle de Beltran, com aviso 1,00 s e alcance de empurrão 3. Usa mecanismos físicos do posto, sem virar arqueira por acidente no texto. Sem projétil ou dispositivo presente, entregar só empurrão como primeira etapa. Nada de esquiva obrigatória, golpe inevitável ou saída que desapareça na pausa. Geometria de cada ataque permanece fixa.

**Acordo.** Demonstração e divisão de operação segura. **Aceite:** notícia não depende de vitória; fonte documental estável; travessia preservada em derrota/rendição conforme continuidade.

### F05 — Aurel, o Primeiro Zelador | kind proposto `aurel`

**História.** Executou o rito que roubou a vida do protagonista. Mantém o povoado e resiste a reconhecer o direito dessa pessoa de retomá-la. Não está possuído; não vira culpado único nem vítima substituta.

**Proposta mecânica.** Confronto humano final com HP 20, sem blindagem sobrenatural. Ciclo inicial: tiro de linha → bloqueio corporal com investida de até 3 células → tiro. Avisos 1,10 s, dano 2, recuperação 1,10 s. Reusar tiros e linha de investida; gesto/aparência precisam corresponder à ferramenta ou arma escolhida para a cena, ainda a definir. A 50% de HP, recuperação vai a 0,90 s; avisos continuam 1,10 s e áreas não crescem. Não criar quebra de selo que restitui vida no meio da luta. Primeira entrega pode usar somente linha/posicionamento e uma pausa de reivindicação, sem nova máquina de chefe.

**Acordo.** Remover interdição e reconhecer que a escolha pertence ao protagonista; exigir promessa de sacrifício não é acordo. **Aceite:** vencer abre acesso, não escolhe final; negociar não equivale a perdoar; não permitir final secreto por HP, mortes ou soma de ACTs. Definir não letalidade do confronto separadamente antes de implementação: não presumir que matar Aurel seja necessário ou impossível.

## 6. Composição de encontros e identidade

### 6.1 Gramática de grupos — PROPOSTA

Usar grupos autorais pequenos; observar o orçamento narrativo existente de 2–3 comuns e um chefe nas regiões intermediárias, sem transformar cada antigo mapa em novo reino.

| Grupo | Tensão desejada | Condição de arena |
| --- | --- | --- |
| Sentinela + Rastejante | Sair da linha sem abandonar leitura do adjacente | Cobertura e pelo menos duas rotas locais |
| Bruto + Sentinela | Flanquear blindagem sem entrar no tiro | Evitar corredor único sem espaço lateral |
| Semeador + Rastejante | Marca força movimento, mordida pune parada tardia | Faixa não ocupa todo piso útil |
| Vigia + Sentinela | Ler cruz e linha sem confundir origens | Diagonais utilizáveis, cobertura parcial |
| Veterana + Sentinela | Duas sequências de tiro legíveis | Escalonar primeira preparação; verificar sobreposição |
| Regente + Rastejante | Administrar pressão e nascentes | Pelo menos um contorno seguro para cada marca |

Não declarar uma arena justa só por contar células livres: testar se o jogador consegue chegar a uma delas no tempo do aviso usando seus controles reais, inclusive custo de virar. Não adicionar coordenador global de ataques para resolver uma combinação mal posicionada; começar ajustando spawn, quantidade e terreno.

### 6.2 Contextos não são novos inimigos

`ctx` distingue acesso, cobrança, manutenção, canteiro, vigia e duelo. O mesmo `kind` pode ter história local e fala diferente sem ganhar novos ataques. Definir o contexto do **tipo real de cada unidade**, não apenas do `kind` externo do encontro.

Há combinações atuais em que o rótulo externo e o primeiro `units[].kind` diferem, por exemplo Bruto no entulho representado mecanicamente por Demolidor. Antes de aplicar voz, retrato ou história, conferir o `kind` da entidade. Não corrigir isso silenciosamente neste documento: decidir depois se a identidade visual muda ou se o encontro deve trocar sua unidade.

Nem todos os contexts possuem override para todos os kinds. Sem entrada, cai na fala base atual; criar texto específico como etapa de conteúdo, não anunciar que o contexto já cobre todo o elenco.

### 6.3 Falas novas de exemplo — PROPOSTA

Usar nas pausas ou como balão breve; nenhuma fala substitui a marca visual do ataque.

| Tipo | Abertura | Ao aceitar retirada |
| --- | --- | --- |
| Sentinela | "O posto continua fechado. Quem autorizou sua entrada?" | "Vou conferir a ordem. Pode passar." |
| Bruto | "A passagem termina aqui." | "Fico de lado. A passagem é sua." |
| Semeador | "Essa terra não aguenta mais passos." | "Escolho outro canteiro." |
| Vigia | "Eu conto quem atravessa. Ainda falta gente." | "Apague. Eu preciso descansar." |
| Veterana | "Olhe as duas linhas antes de correr." | "Eu vi. Você sabe atravessar." |
| Demolidor | "Se fechou, eu abro." | "Mostre outra saída." — somente quando rota for implementada |
| Regente | "Ainda não terminei a despedida." | "Eu posso parar de repetir." |

Rastejante e Casulo recebem gestos. Chefes humanos mantêm as vozes individuais das fichas; não converter uma fala de rendição em confissão que a pessoa ainda não teve.

## 7. Sequência de produção para uma IA

### P1 — identidade dos inimigos atuais

Aplicar história, inspeção, retrato, barks e gestos aos tipos existentes, sem mudar valores do catálogo. Conferir fonte bitmap antes de inserir strings. Resolver explicitamente falas antigas que prometem regra diferente, como cruz curta do Vigia. Essas alterações não precisam de novo sistema de combate.

### P2 — balanceamento observado

Testar um grupo de cada vez, com vida/carga/fôlego reais. Se houver ajuste autorizado, alterar constantes ou campos do def específico. Registrar delta e razão: "aviso de X passou de A para B para permitir um passo lateral após virar". Não elevar todo HP nem acelerar tudo por um rótulo de dificuldade. Preservar separação `ROLES`/catálogo até existir decisão de unificar.

### P3 — chefes posteriores, um por entrega

Construir o adversário e sua arena física somente quando a região correspondente estiver em produção. Reusar funções existentes. Novo ataque precisa de gatilho, geometria travada, resolução, recuperação, negociação, resultado persistente e pelo menos um teste do caso-limite específico. Não criar agora infraestrutura para todos os cinco.

### Prompt de execução

> Leia AGENTS.md, este bestiário, COMBATE_MERGE.md e os módulos citados. Trabalhe apenas na ficha e na etapa solicitadas. Antes de editar, identifique as regras já implementadas e os dados de encontro que as usam. Preserve a arena fásica, pausa congelada, geometria anunciada e persistência. Não use as regras antigas de turnos. Não invente novos ACTs, itens, armas, espécies ou poderes para preencher ambiguidades. Para qualquer regra FUTURO, implemente somente quando sua etapa for pedida; história PROPOSTA não altera lógica implicitamente. Use o módulo Enemies e os sistemas Concord existentes, com constantes locais ou no def, sem manager, registry, factory ou camada de IA genérica. Valide o fluxo do encontro e reporte o que foi alterado e o que continua proposta.

Esse prompt não é autorização para editar código durante a criação deste documento.

## 8. Critérios de aceite

### Para todos os tipos

1. Durante aviso, mover o jogador não altera alvo, direção nem área armazenada.
2. Desenho e acerto concordam sobre cobertura, linhas, faixa, limite e sequência.
3. Pausa/dialogue/foco congelam preparação, eclosão, projéteis, hazards e recuperação no mesmo tick.
4. Aviso comprometido termina antes da pausa normal; nenhum ataque surge por navegação de menu.
5. Whiff conta cota; Veterana conta rajada uma vez; invocados não prolongam vitória indevidamente.
6. `calmed` não persegue; POUPAR remove ocupação; golpe válido desfaz trégua; golpe bloqueado não a desfaz.
7. Rendição não produz morte; derrota não escolhe final; decisão e encontro resolvido persistem após retorno à Colina.
8. Arte maior não aumenta hitbox; animação não dirige dano; sem novo fogo amigo para projéteis.

### Para cada ficha

Acrescentar os casos específicos listados nela. Verificação futura de código: executar `--test` e `--ui-test` conforme projeto, ler resultados, e inspecionar uma evidência visual quando houver mudança de telegrafia. Screenshots e PNGs de teste ficam em `screenshots/`, nunca na raiz ou em `build/`.

Para alteração somente narrativa, revisar fonte de informação, personalidade, coerência e cobertura de glifos quando texto for integrado. Este documento não exige rodar o jogo só para comprovar que foi escrito.

## 9. Precedente mecânico consultado

[Furi — explicação do diretor criativo](https://www.thegamebakers.com/try-again/) descreve uma estrutura de aviso, reação e exploração da abertura, com poucos comandos e diferenças entre chefes. Aqui a referência sustenta a legibilidade de preparação e recuperação; não importa sua esquiva, parry ou combate corpo a corpo para ARROWFALLEN. A negociação e o ciclo fásico vêm deste projeto. Os números deste documento vêm do código local ou estão marcados como proposta, não foram atribuídos a Furi.
