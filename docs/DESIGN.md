# Design do protótipo interno — legado

Prática e expedição procedural em tempo real são usadas por testes e cenas
internas. Para controles e progressão da Nova Campanha, consulte o
[README](../README.md).


Contrato atualizado em **01/10/2026**: apenas arco; SPACE carrega ao pressionar
e dispara ao soltar pronta. Iluminação dinâmica e fog of war foram removidos.

## Movimento e entrada

Blocos lógicos de **40 × 40**, apresentação em **32 × 32 pixels**, deslocamentos exclusivamente cardinais. A posição lógica
muda no começo do salto; animação, sombra e afundamento do piso são apresentação.
Origem e destino ficam reservados durante movimento. A câmera acompanha imediatamente os pés interpolados, alinhada ao pixel e limitada pela sala.
WASD define direção de ataque/defesa e movimento; o último toque prevalece.
Um toque numa direção nova apenas vira o personagem; andar exige novo toque
na direção já encarada ou manter a tecla por um breve instante — segurar a
direção recém-virada destrava o passo após um pequeno atraso.

A célula autoritativa guarda solo (`floor`/`hole`) e peça
(`wall`/`pillar`/`fallen`/`portal`). Solo seguro, entrada física e bloqueio de
ataque têm consultas separadas. Paredes não têm piso acessível no topo.

## Arco, escudo e inimigos

O arco é a única arma, com **3 de dano** e **0,72s** de carga. Pressionar SPACE
começa a carga; mantê-la pronta não dispara. Soltar pronta cria exatamente uma
flecha, que segue até alvo, sólido ou borda. Soltar cedo cancela e não guarda
um disparo. Pressionar durante recuperação não cria fila. I e 1/2/3 fora da
recompensa não alteram combate ou equipamento.

Andar pode acompanhar a carga. Levantar guarda, iniciar mineração, abrir pausa
ou guia, perder foco, atravessar sala e encerrar combate cancelam o gesto. Uma
soltura pendente não dispara após retomada; precisa de novo pressionamento.
SHIFT bloqueia só pela frente e produz pulso nos blocos vizinhos. Energia finita
impede defesa permanente. Laterais e costas ficam expostas.

Brutos fixam o dash; atiradores fixam a direção de tiro. Avisos conservam área,
direção e comprimento mesmo após remover cobertura. Armadura frontal do bruto
e chefe bloqueia tiro alinhado pela frente; flancos são vulneráveis. A origem
reservada de um salto impede sobreposição, mas não recebe dano de dash quando
a posição lógica já saiu dali. O catálogo em `src/enemies.lua` descreve cada
tipo por atributos e comportamento; renderização e testes consomem os mesmos
avisos congelados.

## O elenco das Ruínas dos Ecos

Cinco inimigos comuns mudam a decisão de movimento, não só vida e dano:

- **Rastejante**: aproxima-se e anuncia uma mordida na célula vizinha ocupada.
  Mover-se anula o golpe e o deixa **exposto** (dano recebido +1) por 1,3s.
- **Sentinela**: fixa uma linha cardinal por 1,05s, dispara um virote e recua
  taticamente **no máximo dois passos**; a recuperação abre a aproximação.
- **Bruto**: armadura frontal, investida anunciada de até quatro blocos e
  recuperação longa. Investida comprometida pode cair em buraco.
- **Semeador de Âmbar**: marca uma faixa de três células sobre a posição
  confortável do jogador; só mantém **uma marca ativa**, que detona em 0,85s
  com 2 de dano. Marcas nunca criam buracos nem esmagamento.
- **Vigia dos Ecos**: permanece imóvel durante o aviso e dispara quatro
  virotes em cruz a partir de si. Antecipa a leitura da cruz do Guardião.

Elites aparecem no **covil secreto** e, a partir do segundo andar, em **uma
sala comum de ponta**. Cada um tem silhueta própria e recompensa maior:

- **Bruto Demolidor**: a investida atravessa peças mineráveis — quebra
  paredes e anuncia/derruba pilares, abrindo rotas e mudando cobertura.
- **Sentinela Veterana**: anuncia **dois tiros em direções distintas antes
  do primeiro disparo**; a segunda linha não persegue. Recuperação de 1,3s.

Um boss fecha cada andar e o mundo termina no terceiro; cada arena sorteia uma
de três variantes de pilares/paredes/buracos pela seed:

- **Guardião dos Ecos** (andar 1): 24 de vida, cruz de quatro projéteis e
  dash de até quatro blocos. Avisos de **1,15s**, ou **0,95s** na segunda
  metade da vida; a armadura frontal se rompe nessa fase.
- **O Demolidor da Câmara** (andar 2): 30 de vida, investida destrutiva de
  até sete blocos com queda de pilar anunciada na promessa. Arena com poucos
  pilares e buracos longe da entrada; fúria encadeia **duas investidas**.
- **A Regente de Âmbar** (andar 3): 28 de vida, alterna tiro cardinal, marca
  de âmbar e invocação. O ritual cria um **eco nascente** atacável (3 de
  vida, eclode em rastejante após 3,5s) com **no máximo dois vivos**; destruir
  o eco alonga a recuperação da Regente. Fúria planta marcas em cruz.

Derrotar a Regente encerra a expedição: o portal final encerra o mundo em
vez de gerar um quarto andar.

## Mineração e consequências

Uma tentativa começa com **20 picaretas**. Cada toque de WASD contra a peça
cardinal adjacente dá um hit; hold e repetição não dão outros. Os hits 1/3 e
2/3 permanecem na peça. O terceiro gasta **uma picareta** e transforma a peça,
sem avançar; soltar e apertar novamente permite entrar. Chegar a uma parede
segurando a direção exige novo toque. Zero ferramentas impede progresso.
Moldura externa e estrutura de portais são protegidas; paredes internas são
mineráveis. Quebrar preserva o solo abaixo. Inimigos andando não mineram.

A pancada tem recuperação de **0,16s**. Há no máximo uma intenção pendente,
consumida uma vez. Ela espera ação do arco terminar e cancela carga ao começar;
guarda ativa impede mineração. Telas/foco/travessias descartam intenções.
Hits, peças removidas e estoque persistem ao revisitar; nova tentativa restaura.

Pilares exigem três hits, inclusive vindos de lados diferentes. O terceiro
lado define uma queda para longe dele. O aviso de **0,62s** congela direção e
até **cinco células** além da base. A base abre; os segmentos sólidos `fallen`
exigem três hits e uma nova picareta cada. Sólido, portal ou limite param a
queda. Buraco afunda o trecho terminal, sem ponte. Quedas simultâneas resolvem
por prazo/coordenada, podem encurtar por nova obstrução e nunca ampliar o aviso.

Esmagamento é fatal para ator na área, incluindo origem reservada do salto.
Não se desmancha a parede para salvar ocupação ou conectividade. Buraco aceita
entrada física, mas não caminho seguro: entrar compromete queda e bloqueia
novas ações. A morte ocorre no pouso antes de limpeza/recompensa/portal. Escudo,
armadura e invulnerabilidade comum não evitam morte por buraco/esmagamento.
IA evita buracos na navegação; dash comprometido pode entrar e morrer. Flechas
passam sobre buracos. Expansão de explosão pelo piso para na borda do vazio.

Cristais armados aguardam **0,62s** e dão **3 de dano** em até dois passos
cardinais. O aviso congela pisos e obstáculos terminais. Novos sólidos podem
encurtar; abrir cobertura não amplia dano. Dash/explosão usam as mesmas
transformações fortes, podem iniciar pilar e nunca gastam ferramentas do jogador.

## Leitura e salas

Não há iluminação dinâmica, ocultação por paredes nem fog of war. Todas as
células, atores e avisos são desenhados; sólidos continuam bloqueando flechas
e movimento. Buracos têm borda/profundidade própria. Paredes conectam topo,
faces e cantos; atores são ordenados pelos pés e peças pela base. Essa ordem
representa volume sem mudar colisão. F2 mantém avisos/rachaduras; M não impede
compreender o resultado. O minimapa guarda descoberta de salas; não há
ocultação dentro da sala nem coordenada Z.

A prática oferece câmara, divisória minerável com desvio, corredor de pilar,
segmento para reabrir e buraco com passagem lateral. Após limpar os inimigos
ela continua explorável; vencer exige entrar no portal leste. Outras salas
usam as mesmas peças. O layout garante rotas sem ferramentas após quedas,
em vez de desfazer consequências da armadilha. As salas são retângulos na
faixa do arquétipo (13×9 a 15×9 ou 13×11), com arena do chefe de 15×9 e
prática de 17×11. A câmera acompanha o viajante com ampliação inteira de 2×,
sem precisar enquadrar a sala inteira. A faixa protegida na borda interna une todas as chegadas e saídas;
prévia e queda de pilar param antes dela. A garantia é de chegada → chegada,
saída e posições de combate, inclusive após transformações e sem ferramentas.

## Expedição e arquitetura

Busca em largura gera uma árvore de salas cardinais, com início em (0,0).
O primeiro andar tem **7 ou 8 salas regulares**, crescendo **2 ou 3** por andar.
O chefe ocupa uma folha à maior distância do início; tesouro, loja e refúgio
ocupam outras pontas. O conteúdo de cada sala é escolhido depois da planta.
O refúgio recupera **4 vida uma vez**.

Cada andar é uma região com título e pool de arquétipos próprios
(`floorThemes`): **Galerias da Superfície**, **Criptas dos Sacerdotes** e
**Santuário Afundado**. O arquétipo sorteado por sala (`archetypes`) define o
nome de ficção exibido no cabeçalho, o retângulo dentro da faixa do catálogo e
a spec declarativa — linhas de parede com vãos, clusters, filas, pares e anéis
de pilares, faixas/dispersão de buracos, campos de cristal e cicatrizes. Um
aviso de quatro segundos (`room.tactic`) descreve a tática na primeira entrada;
a descida anuncia o título da região. Nenhuma peça toca a faixa protegida nem
a vizinhança do spawn (`buildable`); inimigos, cristais e inscrições só nascem
em células alcançáveis pelo anel (`Rooms.reachable`). As portas sorteiam uma
posição fora do centro por lado (`doorSlots`, centro ±2, nunca nos cantos) e
as chegadas recaem sobre a faixa. Ao final, `pruneUnsafePillars` simula todas
as combinações de queda e remove qualquer pilar capaz de isolar um ator sem
ferramentas.

Uma folha especial por andar — tesouro ou refúgio — recebe um **portão selado**:
os registros das duas pontas marcam `sealed`, o portal desenha violeta e E ao
lado abre o diálogo `PORTA SELADA` com pagar **3 ouro**, forçar com **1
picareta** ou sair. `Game:unsealDoor` abre as duas pontas juntas; o selo nunca
está na rota do chefe.

A composição dos encontros é **procedural e determinística por seed**, eixo
por sala (seed × andar × sala). A sala inicial traz um rastejante; salas
próximas apresentam um papel por vez; o meio do andar combina até dois papéis;
salas distantes do terceiro andar combinam até três, com dois a quatro
inimigos. O repertório cresce por andar: **1.** rastejante, sentinela e bruto;
**2.** soma semeador e vigia; **3.** combina o elenco completo. As posições
evitam entradas e a faixa protegida, preferem linhas de tiro úteis e mantêm
separação mínima entre atores.

Secreta e supersecreta são duas salas adicionais em células vazias adjacentes
a várias regulares, sem tocar o chefe ou uma à outra. Portas ocultas nos dois
lados são paredes mineráveis; quebrar abre o par recíproco e revela a conexão.
As conexões extras podem produzir ciclos; a árvore regular permanece intacta.
O tijolo secreto usa a aparência dos vizinhos; um brilho suave de 0,30s a cada
4 segundos sugere a entrada, sem descobrir a sala nem iluminar o tabuleiro.
A secreta guarda o covil de um elite; a supersecreta contém três alvos que só aceitam
flechas do jogador. Alvos acertados persistem em revisitas. Desafios dão um
eco e ouro uma vez (4/6), e a supersecreta recupera 2 de vida ao concluir.
Não há recompensa apenas por entrar. Dentro de um segredo, todas as passagens
abrem sem ferramentas e permitem sair antes de vencer o desafio.

Combates rendem **2 ouro uma vez** (**4** em salas de elite). Na loja,
**Amâncio, o Andarilho** vende uma unidade de cada item por andar, pela
opção `COMPRAR` do diálogo: MAPA DO ANDAR (6 ouro, revela as salas não
secretas do andar no minimapa), PICARETAS +4 (5) e PROVISÃO +4 VIDA (7).
Compra inválida ou sem ouro não cobra; `VENDIDO` não volta na revisita e
o andar novo repõe o estoque e exige novo mapa.
O minimapa mostra descobertas, vizinhos por portas abertas e — só com o
mapa comprado — as salas comuns do andar. Segredos nunca aparecem por compra.
Vida, ouro, ferramentas e melhorias persistem na descida;
descobertas e conteúdo são novos a cada andar. ENTER após o portal do
chefe inicia o próximo andar, e o mundo se encerra ao vencer a Regente no
**andar 3**. Salas 2×2/L não fazem parte desta primeira etapa.

## Personagens e diálogo

A tecla **E** fala com personagens na célula cardinal adjacente; longe de
alvo, não faz nada nem cancela a carga. Na conversa, E completa a linha
datilografada e depois avança; opções numeradas seguem a convenção das
recompensas, `SAIR` encerra e ESC fecha. Falar congela a simulação como uma
recompensa e cancela o gesto do arco — retomar exige novo SPACE. NPCs
bloqueiam a própria célula, são imunes a dano (flechas param neles) e vivem
só em salas sem combate.

**Amâncio, o Andarilho** ocupa a loja em todos os andares e lembra do
viajante entre eles — a primeira conversa é longa, a revisita no mesmo andar
é curta e cada andar tem saudação própria. A primeira opção do Amâncio,
`COMPRAR`, abre a vitrine dentro do próprio diálogo: números compram, E
volta aos tópicos. **Odete, a Zeladora** mora no refúgio e entrega uma
carta na primeira conversa. Falas, tópicos e nomes são dados em
`src/lore.lua`; a máquina de diálogo está em `src/dialogue.lua` e o balcão
em `src/shop.lua`. A lore das Ruínas dos Ecos está em
este documento e `src/lore.lua`.

A tecla **E** também lê **inscrições**: marcas de laje no piso de salas
especiais, segredos e da sala inicial do andar 1. O prompt `E · LER` cede a
`E · FALAR` quando um NPC divide a adjacência, e o portão selado mostra
`E · SELO` quando nenhum dos dois disputa a célula vizinha. A leitura abre o diálogo
`INSCRIÇÃO`, escurece a runa desenhada e não se repete — três inscrições
(`entrance`, `crypt`, `deep`) ainda entregam uma carta na primeira leitura.

Entrar na arena do chefe pela primeira vez na tentativa abre uma intro de
uma linha com o nome dele (`game.seenIntro`), congelando a simulação até
fechar. Dezoito **cartas** — bilhetes da primeira expedição e dos
sacerdotes de jade — saem de chefes, desafios, tesouro, Odete e inscrições
por `Game:collectCard`, que embaralha os ids em `game.cardQueue` pela seed.
O guia ganha a página **CARTAS** (C alterna, W/S navega), mostrando as
coletadas por título e o resto como `???`; a prática não coleta e nova
tentativa zera o baralho.

Combates anteriores ao chefe oferecem três ecos; a escolha congela simulação.
Ecos disponíveis: `bowPierce`, `bowQuick`, `guardPulse`, `damage`, `heal`,
`pickaxes` (+3 ferramentas). Dano, cura e ferramentas podem repetir para
manter três escolhas após obter as melhorias únicas.
Perfuração custa um dano por flecha; nenhum eco cria disparo automático.
Seed fixa determina ofertas; melhorias únicas não reaparecem. O XP da
tentativa (comum 1, elite 3, chefe 5, desafio 2; servos invocados não valem)
cruza `Progression.xpSteps` e enfileira a mesma oferta em `pendingOffer`
quando outra tela está aberta — a HUD mostra `NV n · XP x/limite` e a
prática não rende XP. Após o chefe,
a saída abre diretamente. O tesouro também oferece um eco, sem permitir
recompensa duplicada em revisitas. Limpeza remove projéteis inimigos e cristais armados.

Concord mantém atores, projéteis, cristais e marcas de âmbar. O componente
`hazard` guarda células congeladas, fusível e dano; a detonação resolve em
`Environment` e some ao limpar a sala. `Game` guarda estoque/sala e resolve
movimento, dano e morte fatal; `Rooms` contém células e busca cardinal;
`Enemies` cataloga comportamentos por tipo; `Environment` transforma peças;
`Input` distingue toque/hold/soltura. Desenho e
feedback consomem estado sem determinar regras. Bibliotecas vêm de upstreams;
código/assets da pasta de estudo não são fontes do jogo.

## Validação

Os comandos em [tests/README.md](../tests/README.md) verificam terreno, arco,
escudo, chefe, progressão e geração. Replays vencem prática/expedição por saída
explícita sem alterar atores, vida ou temporizadores; reprodução usa 30/60/144
FPS e simulação a 120 Hz. Callbacks reais cobrem gesto SPACE/cancelamento,
mineração/hold/repetição/telas/foco/zero e parede → pilar → segmento → buraco.
Busca cardinal valida desvios sem ferramentas em 100 seeds e direções de queda.

`test-results.txt` e `ui-test-results.txt` guardam a execução atual. Nenhum pacote
portátil foi atualizado. Teclado humano, leitura durante combate e sensação de
jogo continuam como aceite manual; automação não substitui essa sessão.


## Terreno do protótipo — contrato preservado

Estas regras pertencem ao modo interno em tempo real. Para a arena atual,
consulte [BATALHA_ACT_MERCY.md](BATALHA_ACT_MERCY.md).

### Interações

| Regra | Comportamento |
| --- | --- |
| Alcance | Somente peça adjacente cardinal; sem diagonal ou mineração distante |
| Toques | Uma pancada por toque WASD; hold e repetição do teclado não repetem |
| Parede | Três hits; os dois primeiros mantêm estoque; o terceiro gasta uma picareta |
| Estoque | 20 no começo da tentativa; zero impede qualquer progresso parcial |
| Movimento após quebra | Terceiro hit não avança; solte e dê novo toque para entrar |
| Chegar segurando WASD | Movimento para na peça; novo toque é necessário para minerar |
| Persistência | Hits/peças/estoque permanecem nas revisitas; nova tentativa restaura |
| Recuperação | Pancada 0,16s; no máximo uma intenção pendente, consumida uma vez |
| Arco e guarda | Pancada espera ação do arco, cancela carga; guarda ativa impede mineração |
| Pilar | Três hits; o terceiro lado fixa queda oposta ao lado de onde veio o hit |
| Corpo caído | Até cinco células além da base; base abre; cada segmento é peça independente |
| Aviso | 0,62s, direção e células congeladas; custo único no terceiro hit |
| Segmento | Três hits e outra picareta para cada vão |
| Sólido/portal/limite | Queda para antes do primeiro obstáculo |
| Buraco na trajetória | Trecho terminal afunda; buraco permanece; sem ponte automática |
| Ator no aviso | Esmagamento fatal; não cancelar queda para salvar ocupação/conectividade |
| Entrada em buraco | Compromete queda e bloqueia novas ações; morte no pouso |
| Prioridade fatal | Morte vem antes de limpeza, recompensa, vitória ou travessia |
| Proteção | Moldura externa e estrutura dos portais; peças comuns internas mineráveis |
| Força externa | Dash/explosão completam transformações sem gastar picaretas |
| Tiro | Flechas comuns bloqueadas por sólidos e não mineram; passam sobre buracos |
| Navegação | Busca voluntária usa piso seguro; dash comprometido pode entrar no buraco |

Os números **20, 3, 5, 0,16s e 0,62s**, além da letalidade de esmagamento,
ficam em valores nomeados para ajuste. Escudo, armadura e imunidade de dano
não anulam morte por queda/esmagamento. Inimigos andando não usam ferramentas.


### Células e transformações

```lua
room.tiles[key] = {x = x, y = y, ground = "floor", piece = "wall", hits = 0}
```

Solo distingue `floor`/`hole`; peça distingue `wall`/`pillar`/`fallen`/`portal`.
Células vazias guardam só solo. Estado/direção/timer/células de queda pertencem
ao pilar pendente. Não existem mapas mutáveis separados de walls/structures/
rubble. Remover peça preserva solo. Células são dados da sala, não entidades ECS.

`Rooms` oferece consultas distintas para piso seguro, entrada física e bloqueio
de ataque. `Environment` transforma peças; `Game` guarda estoque e resolve
movimento/morte; `Input`/`Systems.Player` separam toque/hold/soltura. Desenho
apenas apresenta estado. A revisão da sala muda com transformações.

Quedas simultâneas têm ordem por prazo/coordenada. Nova obstrução pode encurtar
resultado; remover barreira durante aviso nunca amplia a área. Dash, explosão
e tiros inimigos também ficam limitados ao aviso emitido. Explosão se expande
pelo piso e para em buracos; paredes atingidas são terminais.
