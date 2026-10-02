# Arrowfallen — Megaplan de lore, NPCs e mundo

> Documento histórico da implementação atual. Para a nova direção de história, hub, dez regiões e batalhas separadas, consultar [HISTORIA_NOVA.md](HISTORIA_NOVA.md) e [GUIA_STORYTELLING_UNDERTALE.md](GUIA_STORYTELLING_UNDERTALE.md). A nova direção ainda não foi implementada.

Status: etapas 1–5 implementadas; aceite humano de leitura/ritmo pendente.

Objetivo: dar às Ruínas dos Ecos um motivo para existir — personagens que
conversam, um comerciante que vende de verdade, XP que amarra a tentativa,
cartas colecionáveis que contam a história e sinais de lore dentro das salas.
Este documento cobre a Entrega 3 inteira do roadmap ("Integrar progressão e
mundo").

## 1. Decisões aprovadas

| Elemento | Decisão |
| --- | --- |
| Interação | Tecla **E** junto a um NPC ou inscrição (E era o controle de compra removido) |
| Diálogo | Caixa própria desenhada no estilo pixel; sem Talkies ou nova dependência |
| Comerciante | **Amâncio, o Andarilho** — recorrente, lembra do jogador entre andares |
| Segundo NPC | **Odete, a Zeladora** — mora no refúgio |
| Estoque da loja | Mapa do andar, pacote de picaretas, provisão de cura; uma unidade cada |
| XP | Da tentativa; níveis abrem a oferta de ecos já existente |
| Cartas | Colecionáveis de lore (~18), página própria no guia |
| Lore em | Diálogos, cartas, descrições de ecos, intros de chefe e inscrições |
| Protagonista | Não fala; o mundo fala por ele |
| Arte | NPCs ganham sprites pixel geradas em memória já na etapa 1 |

## 2. Lore do mundo

As Ruínas dos Ecos eram um templo que preservava os mortos como **ecos**:
memórias cantadas em pedra de jade, guardadas em câmaras para que nenhuma
despedida fosse a última. A **Regente de Âmbar**, incapaz de aceitar a
partida, ordenou que os ecos fossem selados em âmbar em vez de libertados.

Um eco preso não vive: repete. Séculos depois, os ecos das ruínas só lembram
seus últimos instantes — guardas repetem a guarda, bestas repetem a caça. É
por isso que tudo ataca, e é por isso que os avisos nunca mentem: um eco não
sabe fazer outra coisa.

**Os três selos são os três andares:**

- **O Guardião dos Ecos** (andar 1) é o porteiro que ainda cumpre a última
  ordem. Quando sua armadura se rompe, o próprio selo se parte.
- **O Demolidor da Câmara** (andar 2) tentou quebrar os selos à força e se
  destruiu junto; sua investida ainda derruba a casa que ele queria libertar.
- **A Regente de Âmbar** (andar 3) continua no fundo, conjurando ecos
  nascentes — os husks que eclodem são despedidas que ela não deixa terminar.
  Vencê-la devolve os ecos e encerra a expedição.

**O viajante** é um *desfazedor*: um peregrino de capuz que desce para
libertar os ecos. Cada melhoria de eco é uma memória que escolheu emprestar
força. As **cartas** são cartas literais — bilhetes e registros deixados pela
primeira expedição e pelos sacerdotes do templo.

**Materiais com significado:** jade = eco livre/benigno; âmbar = selo e
prisão; violeta = eco corrompido e alerta; ouro envelhecido = oferenda;
pedra azul escura = o templo morto.

## 3. Elenco de NPCs

### Amâncio, o Andarilho — comerciante (loja, todos os andares)

Ex-peregrino que parou no primeiro andar depois de perder a irmã para os
ecos; a mochila virou balcão. Vende os mapas que ele mesmo desenhou,
ferramentas e provisões. Lembra do jogador entre andares e comenta o
progresso — cada andar tem uma saudação própria, e revisitar no mesmo andar
usa a saudação curta.

### Odete, a Zeladora — refúgio (por andar, quando existir)

Cuida do último santuário não selado desde antes da queda da Regente. A cura
automática do refúgio é "o eco gentil" dela. Falas curtas sobre os ecos,
descanso e a história do lugar.

Novos NPCs exigem: entrada em `Lore.npcs` e `Lore.lines`, posição em
`room.npcs` na geração e uma sheet `npc_<id>` em `pixel_actors.lua`.

## 4. Interação e diálogo

- **E** junto a um NPC (célula cardinal adjacente) ou a uma inscrição abre o
  diálogo. Longe de alvo, E não faz nada e **não** cancela carga.
- O diálogo congela a simulação (`game.dialogue`, mesmo padrão de
  `game.reward`) e limpa gestos — abrir diálogo cancela carga pronta, como
  qualquer tela. Retomar exige novo SPACE.
- Caixa inferior em pixels: nome do falante, texto com datilografia
  (movimento reduzido mostra a linha inteira), `E ▸` completa a linha e
  avança; ESC fecha. Ao fim das falas, opções numeradas `1/2/3` seguem a
  mesma convenção das recompensas.
- Falas são curtas e puláveis; a primeira conversa não se repete na revisita
  nem na descida.
- NPCs bloqueiam a própria célula, são imunes a dano (flechas param neles
  sem efeito) e não são alvo da IA. Durante o diálogo o NPC encara o jogador.
- NPCs só vivem em salas sem combate (loja, refúgio); diálogo nunca começa
  sob fogo.

## 5. Loja e economia

Ouro hoje não tem uso: combates rendem 2 (4 em elite), desafios 4/6. A loja
vira o destino desse ouro.

- Estoque determinístico por seed × andar, uma unidade por item:
  | Item | Preço inicial | Efeito |
  | --- | --- | --- |
  | MAPA DO ANDAR | 6 ouro | Revela salas **não secretas** e suas conexões no minimapa |
  | PICARETAS | 5 ouro | +4 ferramentas |
  | PROVISÃO | 7 ouro | +4 de vida (respeita o máximo) |
- Fluxo: E no comerciante → saudação → opção `COMPRAR` abre a vitrine dentro
  do próprio diálogo, numerada; `VENDIDO` marca o item; sair fecha.
- Compra inválida ou sem ouro não cobra nem consome; item vendido não volta
  na revisita; estoque novo a cada andar.
- O mapa reintroduz `game.mapReveal` (maquinário removido) como efeito de
  item comprado: marca `discovered` das salas regulares; segredos continuam
  exigindo mineração — o minimapa nunca revela o que a exploração não achou.
- A renda por andar (≈14–18 ouro) deve permitir ~2 itens; preços ficam em
  tabela nomeada para ajuste.

## 6. XP e níveis

XP é da tentativa e zera em nova expedição.

| Fonte | XP |
| --- | --- |
| Inimigo comum | 1 |
| Elite | 3 |
| Chefe | 5 |
| Desafio secreto/supersecreto concluído | 2 |

- Níveis em `Progression.xpSteps = {4, 10, 18, 28, 40}` (ajustável). Subir
  de nível abre `Progression.offer` — a mesma oferta de três ecos,
  integrando recompensa ao fluxo de níveis sem duplicar escolhas.
- Se já houver recompensa ou diálogo aberto, a oferta fica em
  `game.pendingOffer` e dispara ao fechar.
- HUD mostra `NV n · XP x/limite` junto a ouro e picaretas; o guia detalha.

## 7. Cartas colecionáveis (~18)

Colecionáveis por tentativa em `game.cards`; o guia (TAB) ganha a página
**CARTAS**, alternada com a tecla C. Cada carta tem título e 2–3 linhas.

Distribuição (≈6 por andar): 1 por desafio secreto e supersecreto concluído,
1 por chefe, 1 por refúgio na primeira conversa, 1 por sala do tesouro, 1 na
sala inicial do andar 1 e as restantes em inscrições.

Títulos de rascunho: CARTA DO CARTÓGRAFO I/II, REGISTRO DO PORTEIRO, DIÁRIO
DO PEDREIRO, ÚLTIMA ORDEM DA REGENTE, ORAÇÃO DE JADE, MEMORANDO DE ÂMBAR,
RELATO DA PRIMEIRA DESCIDA I/II, LISTA DE PROVISÕES, AVISO AOS PEREGRINOS,
TESTAMENTO DE ÂMBAR, A PROMESSA DO VIAJANTE — escritos na perspectiva da
primeira expedição e dos sacerdotes do templo.

## 8. Intros de chefe e inscrições

- A primeira entrada na arena (por tentativa, `game.seenIntro`) abre um
  diálogo de uma linha com o nome do chefe; pulável; a simulação congela até
  fechar, então nenhum inimigo age enquanto a intro está aberta.
- Inscrições são marcas examináveis (`room.inscriptions = {{x, y, id}}`) em
  salas especiais e segredos; E adjacente lê com o título "INSCRIÇÃO" e um
  brilho discreto no padrão `secretHint` sugere a placa.

## 9. Arquitetura

| Arquivo | Responsabilidade |
| --- | --- |
| `src/lore.lua` | Dados: nomes, falas, árvores, cartas, intros, inscrições |
| `src/dialogue.lua` | Máquina de estado do diálogo: open/advance/choose/close |
| `src/components.lua` | Componente `npc` |
| `src/input.lua` | Evento `interact` na tecla E |
| `src/rooms.lua` | `room.npcs` e `room.inscriptions` na geração |
| `src/game.lua` | Spawn de NPC, `interact()`, estados `dialogue/met/cards/xp/level/mapReveal/pendingOffer` |
| `src/systems.lua` | `Systems.Player` consome o evento interact |
| `src/pixel_actors.lua` | Sheets `npc_merchant`/`npc_keeper` geradas em memória |
| `src/render.lua` | Caixa de diálogo, prompt `E · FALAR`, página de cartas no guia |
| `src/shop.lua` | Etapa 2: estoque, preços e compra |
| `main.lua` | Teclas do diálogo e cenas de screenshot |
| `tests/dialogue.lua` | Checks de interação, congelamento e memória |

## 10. Etapas de implementação

### Etapa 1 — Interação, NPCs e diálogo (implementada)

E como evento de toque; componente `npc`; spawn do comerciante e da
zeladora; máquina de diálogo com falas sequenciais e opções numeradas; caixa
pixel com datilografia; prompt `E · FALAR`; sprites pixel dos dois NPCs;
congelamento e cancelamento de gesto; memória `met` por andar; testes.

### Etapa 2 — Loja do Andarilho (implementada)

`src/shop.lua` com estoque fixo por sala de loja, vitrine numerada dentro do
diálogo (modo `shop`: números compram, E volta aos tópicos), compra de
mapa/picaretas/cura, persistência de `VENDIDO` em `room.sold` e estoque novo
por andar. `mapReveal` reintroduzido só via compra; segredos nunca revelados.
Dados de cartas e inscrições já autorais em `src/lore.lua` — a coleta e a
página do guia ficam para a etapa 4.

### Etapa 3 — XP e níveis (implementada)

`Progression.xpSteps = {4, 10, 18, 28, 40}`; inimigo comum 1, elite 3, chefe 5,
desafio concluído 2; servos invocados não rendem XP. Subir de nível enfileira
`game.pendingOffer` e a oferta dispara ao fechar recompensa ou diálogo, sem
duplicar escolhas; ofertas repetidas numa mesma sala variam a seed sem mudar a
primeira oferta. HUD mostra `NV n · XP x/limite` junto a ouro e picaretas; o
guia detalha fontes e fila. A prática não rende XP.

### Etapa 4 — Conteúdo completo de lore (implementada)

Árvores de Amâncio e Odete com cinco tópicos cada (`COMPRAR` continua
injetado na posição 1 do balcão). 18 cartas em `Lore.cards`; `game.cardQueue`
embaralha os ids pela seed e `Game:collectCard` tira a próxima ainda não
coletada. Fontes de carta: chefe, desafio secreto/supersecreto, tesouro,
primeira conversa com Odete e inscrições marcadas em
`Lore.inscriptionCard` (entrance/crypt/deep). Releitura não duplica carta;
a prática não coleta. Página **CARTAS** no guia (tecla C, W/S navega) lista
coletadas por título e o resto como `???`. Intro de uma linha por chefe na
primeira entrada da arena (`game.seenIntro`), congelando a simulação.
Inscrições (`room.inscriptions`) nas salas inicial, refúgio, tesouro, chefe
e segredos — o andar 3 enterra a inscrição `deep` na arena ou no segredo —
lidas com E (prompt `E · LER`), marca de laje no piso com brilho na cadência
do `secretHint`, escurecendo após a leitura. Descrições dos ecos revisadas
em prosa de memória/eco sem alterar efeitos.

### Etapa 5 — Consistência (implementada)

DESIGN/README/ROADMAP atualizados para loja, XP, cartas, inscrições e intros;
cenas `--scene=cards` e `--scene=inscription` para prints; suíte cobre
intro de chefe, deck determinístico, unicidade de cartas, marcas em piso
válidas, prioridade NPC > inscrição, página CARTAS e fechamento do guia;
replays a 30/60/144 FPS passam com as intros. O aceite humano de
leitura/ritmo continua manual.

## 11. Verificação e critérios de aprovação

- E junto ao NPC abre, congela a simulação e cancela gesto; E sem alvo não
  faz nada nem cancela carga.
- Falas não repetem intro em revisita; `met` sobrevive à descida; nova
  tentativa reinicia memória, XP e cartas.
- Compra inválida/sem ouro não cobra; vendido não volta; mapa comprado nunca
  revela segredos.
- Subir de nível oferece ecos sem duplicar escolhas ou pular fila.
- Diálogo, loja e guia funcionam em 900 × 680, 1120 × 800 e 1920 × 1080, com
  movimento reduzido preservando toda a informação.
- Nenhuma mecânica existente muda: combate, mineração, recompensas,
  descoberta e replays seguem os contratos atuais.
- Texto curto, em português, com acentos cobertos pela fonte bitmap.
- Checks existentes ajustados passam; `tests/dialogue.lua` cobre o novo
  fluxo. Prints sempre em `screenshots/` com `--screenshot`.

## 12. Prompt para continuar

```text
Implemente a próxima etapa de docs/MEGAPLAN_LORE.md no Arrowfallen.

Leia o megaplan, AGENTS.md, DESIGN.md e os arquivos citados antes de editar.
As decisões estão aprovadas. A etapa 1 já entregou E como interação, o
componente npc, a máquina de diálogo e os dois NPCs desenhados. Siga a etapa
indicada sem criar abstrações especulativas nem refatorar sistemas alheios.

A simulação continua autoridade: diálogo congela como reward; nenhuma compra
cobra entrada inválida; revisita não duplica recompensa, cura ou estoque; o
minimapa nunca revela segredos por compra ou apresentação. Texto em
português, curto e pulável; sprites desenhadas por código em 32×32 com
filtro nearest.

Execute os checks (--test, --ui-test) e registre prints em screenshots/ com
--screenshot=screenshots/nome.png a partir da raiz. Entregue resumo de
arquivos alterados, verificações feitas e etapas restantes.
```
