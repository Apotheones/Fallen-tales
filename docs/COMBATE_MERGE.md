# Combate — merge arcade + conversa (modelo fásico)

Especificação de regras, 03/10/2026. **Substitui o combate por turnos** como
mecânica de encontro da campanha: a batalha alterna uma **fase de ação em
tempo real** (motor do protótipo, `src/game.lua` + `src/enemies.lua`) com
uma **fase de pausa** que abre o menu social ou um diálogo. A camada
ACT/MERCY de `docs/BATALHA_ACT_MERCY.md` permanece — ela é agnóstica ao
relógio. Base de design: `docs/COMBATE_PROPOSTA.md` §1 (arena separada,
exploração livre) e a conversa de design registrada nesta data.

Território desta especificação: `src/battle.lua` (reescrita), novo
`src/battle_talks.lua` ou extensão de `battle_barks.lua` (beats), e o fio
de input em `main.lua`/`src/campaign.lua`.

## 1. O ciclo

```
ABERTURA (toda batalha, sempre)
  contato → freeze → inimigo fala (bark ou diálogo de def.talk)
  → revela do tabuleiro → janela de graça → ação

FASE AÇÃO (tempo real)
  Jogador: anda, carrega arco, escuda, mina — mecânica do protótipo.
  Inimigos: máquina Enemies.step (seek → warn → resolve → recover).
  Fecha quando: todo inimigo vivo cumpriu a cota de golpes
  OU estoura o timeout OU não sobra ninguém ('won' na hora).

FASE PAUSA (tudo congelado)
  Beat curto → menu (CONTINUAR default · AGIR · USAR · POUPAR · FUGIR)
  ou diálogo de beat armado (§7). Escolha aplica → próxima fase.

LOOP até: inimigos mortos · rendidos/poupados · fuga · morte do jogador.
```

Não há cronômetro decidindo ação de menu: a pausa só termina por escolha
do jogador (ou fechamento de diálogo). Dentro da fase de ação, nada espera
o jogador — é o arcade.

## 2. Fase de ação

- **Mecânica do jogador**: igual ao protótipo. WASD vira/anda (toque vira,
  segurar anda), SPACE carrega 0,72s e solta dispara, SHIFT bloqueia
  frontal com energia finita, toque contra peça minera. Sem FERRAMENTA
  corpo-a-corpo — o arco é a única arma; armadura frontal se fura por
  flanco ou por queda de pilar (contrato original de `docs/DESIGN.md`).
- **Inimigos**: `Enemies.step` por entidade, sem alteração de timing.
  Kinds da campanha já existem no catálogo com os mesmos nomes.
- **Cota de golpes**: `Battle.phaseQuota = 2` por inimigo. "Agir" =
  executar o resolve de um warn — acertar ou errar conta igual (whiff
  gasta cota). Sobrescrita por def/unidade: `u.quota` > `def.quota` >
  global. Projéteis múltiplos de um resolve (veteran, cruz do vigia)
  contam como uma ação.
- **Timeout**: `Battle.phaseTimeout = 12`. Estourou, a fase fecha na
  próxima resolução — vide §2.1.
- **Anti-stall**: inimigo que passou `Battle.stallLimit = 4`s seguidos
  sem conseguir engajar (sem linha, sem alcance, sem caminho) conta como
  "agiu". Esconder atrás de parede não trava a rodada.
- **Cota é dos vivos**: inimigo morto sai do cálculo. Zerar a arena na
  fase de ação conclui 'won' imediatamente, sem passar pela pausa.

### 2.1 Fechamento da fase

A fase nunca corta um telegrafo: pedido de fechamento (cota cumprida ou
timeout) espera a arena ficar **quieta** — nenhum inimigo em
warn/dash/volley, nenhum projétil em voo, nenhum hazard armado, nenhum
pilar caindo. O que foi prometido, resolve. Depois:

- inimigos que cumpriram a cota entram em `wait`: recuam um passo
  (reusa `retreat` com 1 passo) e seguram — "os que já agiram respiram".
  É o indicador visual do fim de fase; sem contador na HUD.
- beat de ~0,4s (todos quietos) → abre a fase de pausa.
- carga do arco ao entrar na pausa: cancela (contrato já existente —
  diálogo e telas cancelam o gesto; retomar exige novo SPACE).

### 2.2 Morte durante a ação

Vida/i-frames do protótipo (`.36s`). Morte do jogador segue o fluxo da
campanha (túmulo); morte de inimigo por flecha/peça segue `Game:damage` —
com o guard `nonLethal` do §5.3.

## 3. Fase de pausa

Congela a simulação no mesmo quadro (`Battle:update` retorna cedo quando
`campaign.dialogue` ou `self.phase == 'pause'` — o contrato de freeze já
existe). Abre:

- **Menu de postura** quando não há beat armado. Itens:
  `CONTINUAR` (default — um toque de ENTER volta à luta),
  `AGIR` (submenu social por alvo, §5), `USAR` (consumíveis — itens só
  existem no menu, input da ação fica WASD/ESPAÇO/SHIFT/E),
  `POUPAR` (só com `spareable()` — §5.2), `FUGIR` (§6).
- **Diálogo** quando um beat está armado (§7): o node substitui o menu
  naquela pausa. Opções escrevem estado social ou encerram o encontro.

Bark do inimigo "palco" (primeiro vivo) no topo do menu — a fala entre
rodadas que o design pede, custo zero via `sayBark`.

## 4. Abertura de batalha

Toda batalha tem introdução: contato congela → fala de abertura (bark
`announce` ou node `def.talk` quando o encontro é negociável — o gancho
`talk`/`confronto`/`greeted` de campaign.lua permanece) → revelação do
tabuleiro → janela de graça: inimigos nascem em `seek` com `think`
inicial ≥ `Battle.graceTime = .8`, escalonados para não engajar no mesmo
tick. A rampa já existe no catálogo; só garantir o piso.

## 5. Camada social em tempo real

Estado por unidade inalterado: `convince`, `mercy`, `spared`,
`provoked`, `convinceNeeded` (unidade → def → role → global),
`verbal=false`/`negotiates=false` (crawler, husk), `ctx`, `nonLethal`.

### 5.1 Efeitos imediatos (não esperam a pausa)

- **Convinced**: atingir o limiar durante a pausa marca `e.mercy` **e**
  o inimigo entra em `calmed` na hora — para de buscar/engajar, visível
  já na próxima fase de ação (ou imediato, se a convicção veio de diálogo
  de abertura).
- **Provoked**: o próximo `engage` é forçado (ignora alinhamento/alcance
  ideal) com warn ×`Battle.provokeWarnFactor = .8` — a isca tática.
- **Atacar convencido**: golpe válido (flecha que acerta, pilar que
  esmaga) desfaz `e.mercy`/`calmed` e zera `e.convince` — D08 portado.

### 5.2 POUPAR por proximidade

E na célula adjacente a um inimigo `calmed`/`mercy` confirma a retirada:
`e.spared`, bark `spared`, sai do mundo no mesmo tick. Em ambiguidade de
adjacência, o `calmed` mais próximo do centro da célula do jogador vence.
Poupar custa **posicionamento** — cruzar a arena até quem baixou a guarda
é risco real enquanto os hostis atacam. `POUPAR` no menu cobre o caso sem
aproximação (custa o pick do menu, como hoje).

### 5.3 Rendição não-letal

`ctx.nonLethal` arma o guard das rotas letais do jogador no shim de
`damage`/`killFatal`: golpe que zeraria a vida vira rendição —
`health = 1`, `e.spared`, bark `spared`, nunca `effect('death')`.
Portado do §13 do BATALHA_ACT_MERCY para o caminho de dano em tempo real.

### 5.4 O palco vira retrato da vida

A faixa do sprite grande (hoje cenografia) passa a mostrar o retrato
emocional do "palco" (primeiro vivo / falante do beat):
`renderer.actors.sheets[kind].portraits` já assa 9 emoções por kind.
Mapa inicial:

| Estado | Emoção |
| --- | --- |
| hostil, hp alto | `stern` (ou `neutral` por kind) |
| hp < 30% | `fear`/`sad` — o "perto da morte" |
| convince > 0 | `soft` — a guarda caindo na cara |
| calmed/mercy | `joy`/`soft` |
| provoked | `anger` |
| spared | `sad`/`awe` — despedida |
| refuse | `stern` |

Transições de estado ganham animação curta no retrato. A emoção é
telemetria social: o jogador lê o andamento da conversa na cara antes de
abrir o menu. Kinds não-verbais usam a convenção "gesto é a face".

## 6. Fuga — micro-fase de ação

Sem RNG. `FUGIR` no menu fecha a pausa e abre a fuga:

- uma célula de saída acende na borda oposta do tabuleiro;
- cada inimigo hostil vivo ganha **uma** investida final (warn→resolve
  normal — a volley de despedida);
- pisar na saída → `endBattle('return')` → `retreatFrom` no mapa;
- a volley fechar sem o jogador na saída → fuga falhou, ação continua,
  o pick do menu foi gasto;
- morrer na travessia → fluxo de morte normal.

Inimigos `calmed`/`spared` não participam da volley. O risco é corporal
e legível — o jogador vê por que falhou.

## 7. Beats de conversa

`def.beats` (encontro) ou `kind.beats` (role) — tabela de gatilhos
avaliada no fechamento de cada fase de ação:

```lua
{when = 'start',                   node = 'rangerAbertura'}
{when = {round = 2},               node = 'jandaRespira'}
{when = {hpBelow = .5},            node = 'jandaMetade', once = true}
{when = {passiveFor = 6},          node = 'rangerNaoRevida', once = true}
{when = 'mercy',                   node = 'rangerEntrega'}
```

- Beat armado substitui o menu naquela pausa; mais de um armado → fila
  por prioridade de escrita (ordem do def).
- `passiveFor` = segundos acumulados sem atacar — premia a rota
  "só desviar" do pacifista.
- `hpBelow` dispara quando a vida cruza o limiar — inclui o caso do
  golpe que passa o limiar no mesmo tick (avaliar após resolver dano).
- Nodes de beat vivem na namespace de batalha (`battle_barks`/
  `campaign_lore`), mesmas convenções de escrita do Pena.
- `bossPhase` (enemies.lua) vira caso especial de beat: threshold de hp
  já existe; em vez de `notify`, pode abrir node.

## 8. Arquitetura — o shim `Battle→Game`

`Battle` continua o objeto de cena da campanha (encounterId, snapshot,
def, outcome, `endBattle`). Ganha um sub-mundo real-time:

```lua
self.world = Concord.world():setResource("game", self)
self.world:addSystems(Systems.Movement, Systems.Player, Systems.Enemy,
    Boss, Systems.Projectile, Environment, Systems.Damage)
```

`Battle` implementa a superfície que `enemies.lua`/`systems.lua`/
`environment.lua` esperam de `g`: `room`, `player`, `entities()`,
`walkable`, `occupant`, `move`, `damage`, `killFatal`, `shoot`,
`effect`, `notify`, `say`, `state`, `time`, `upgrades`, `world`,
`pickaxes` (mapeado a `data.items.picareta`), `dialogue` (espelhado de
`campaign.dialogue`).

- **Input**: `campaign:update` repassa o frame completo
  `{dx, dy, guard, events}` para `battle:update` na fase de ação
  (hoje descarta guard/events — `main.lua` já produz o frame).
  `battle:key` na fase de ação consome só E/ESC/Tab; WASD/ESPAÇO/SHIFT
  retornam `false` e fluem para `input:pressed`. Na pausa/menu/diálogo,
  consome como hoje.
- **Freeze**: `campaign.dialogue` ou `phase == 'pause'` →
  `Battle:update` retorna. Pausa da janela (foco perdido) já pausa a
  campanha inteira.
- **`battle.lua` morre**: `resolveQueue`, `phase 'player'/'resolve'`,
  `announce`/`intentCells`/`reach`/`moveRange`, `step`/`startStep`,
  plan-`X` por rodada, `endTurn`/`finishResolve`/`resolveStep`,
  `thornTick`, os modos `walk`/`aim`/`pillar`/`inspect` como turno.
- **Sobrevive/adapta**: `menuItems`/`choose`/`actItems`/`actOn`/`spare`/
  `nonLethal`/`outcome`/`conclude` (camada social), `say`/`sayBark`,
  `makeUnit` → mapeamento kind→`Enemies` def, `arenaDef`/`Region.build`,
  `crates`/`channels` (terreno), `snapshot`, itens (`useConsumable`),
  `ROLES` (vira ponte kind→def real-time + dados sociais).
- **Chefe humano** (`role.boss`): hammer/push/jet/shove viram entradas
  de catálogo `Enemies[janda]` etc. com warn→resolve em tempo real —
  mesma gramática (lane, banda, impacto), novos timers. O despacho
  "boss antes da família" vira prioridade de `engage` no def.
- **Testes**: `tests/battle.lua` é reescrito (fases, cota, freeze,
  spare por proximidade, fuga, outcomes). `tests/combat.lua` continua
  cobrindo o motor. Cenas `--scene=` ganham equivalentes de fase.

## 9. O que não muda

- `campaign:startBattle`/`endBattle`/`settleEncounter`/`retreatFrom`,
  persistência `data.encounters`, `loot`/`parleyLoot`, checkpoint.
- `def.talk`/`confronto`/`e.greeted` — negociação pré-arena.
- Arena como `Region.build` — `Rooms.floor/cell/line/path` compartilhado.
- `battle_barks` — conteúdo social (check/acts/refuses/barks/ctx).
- `dialogue.lua` — a máquina inteira.

## 10. Decisões do usuário (registro)

1. **Modelo**: fásico (ação real-time ⇄ pausa com menu/diálogo), não
   contínuo com gatilhos soltos.
2. **Fechamento de fase**: híbrido — cota de golpes por inimigo OU
   timeout; último telegrafo sempre resolve.
3. **Ação × menu**: o jogador ataca livremente na fase de ação **e**
   escolhe uma ação social na pausa — lutar é do corpo, conversar é da
   mente.
4. **Cota**: delegada — `phaseQuota = 2` default, por unidade/def.
   "Agir" conta whiffs.
5. **Turnos**: substituídos de vez — sem flag de fallback.
6. **Intro**: toda batalha tem fala + revelação + janela de graça.
7. **POUPAR**: proximidade + E no `calmed` (menu cobre o resto).
8. **FUGIR**: não garantida — micro-fase de fuga com volley final.
9. **Melee**: removido — só o arco (picareta = terreno).
10. **Palco**: retrato emocional da vida do inimigo (emotions × hp ×
    estado social), não decoração estática.
11. **Itens**: só no menu.
12. **Respiração**: quem cumpriu a cota entra em `wait` e respira.

## 11. Casos de borda

- Freeze com projétil no ar: tudo congela junto e retoma do mesmo
  quadro; a fase só fecha quando nada está pendente (§2.1).
- Diálogo de beat aberto com inimigo a meio de warn: o congelamento
  preserva o telegrafo — retoma exatamente onde parou.
- `calmed` entre hostis: poupar por E exige atravessar perigo vivo —
  custo intencional.
- Beat `hpBelow` armado no golpe que mata: avaliar depois da resolução —
  morto não fala; `won` vence a fila.
- Encontro misto (verbal + não-verbal): beats pertencem à unidade
  `u.speaker` ou ao primeiro verbal vivo; sem falante, sem beat.
- `husk`/invocados: `summoned` não entra na cota e não recebe beat;
  invocado morto conta como queda comum — a regra 'negotiated' exige
  **as unidades do def** resolvidas sem letalidade; servos invocados não
  estão no def. *(proposta, revisável)*
- ESC: na fase de ação abre pausa da campanha; na pausa/menu volta um
  passo; na fase de fuga equivale a desistir da fuga (fica).
  *(proposta, revisável)*

## 12. Sequência de implementação

1. **Shim**: `Battle` com sub-mundo Concord + superfície `g`; fase de
   ação com uma sentinela; entrada/saída de cena, arco, escudo, warn,
   morte, 'won'.
2. **Fechamento**: cota/timeout/anti-stall/`wait`/beat de 0,4s → pausa
   com menu mínimo (CONTINUAR/USAR/FUGIR).
3. **Social na pausa**: AGIR completo (convince/provoked/calmed) +
   retrato emocional + POUPAR por E e por menu → 'negotiated'.
4. **Beats**: tabela de gatilhos + um encontro negociável completo.
5. **Fuga** + **chefes humanos** re-cronometrados + `nonLethal`.
6. Replicar nos mapas; reescrever `tests/battle.lua`; cenas de evidência.

Critérios: o jogador entende por que foi atingido, usa o tabuleiro para
desviar e contra-atacar, sente a respiração da fase, lê a conversa na
cara do inimigo e volta a um mundo que reconhece a escolha.

## Implementado (passo 12.1)

O shim `Battle→Game` está de pé — `src/battle.lua` foi reescrito em torno
de um sub-mundo Concord real e a fase viva é `action` desde o nascimento
da arena. O turno não existe mais em lugar nenhum do código: `endTurn`,
`resolveQueue`, `phase 'player'/'resolve'` e todo o plan-* por rodada
sumiram (o que resta deles é stub honesto para o renderer/cenas antigas).

Decisões registradas na implementação:

- **Sub-mundo**: `Battle` instancia `Concord.world():setResource('game', self)`
  com `Systems.Movement, Player, Enemy, Projectile, Environment, Damage, Boss`
  e implementa a superfície `g` completa (`entities`, `walkable`, `occupant`,
  `move`, `damage`, `killFatal`, `shoot`, `spawnEnemy`, `effect`, `notify`,
  `weaponStats`, `clearIntents`, `cancelCharge`, `interact`, `pickaxes`).
- **Unidades**: `spawnUnit` monta a entidade Concord (grid/motion/facing/
  health/team/enemy), carrega os dados sociais na própria entidade
  (`e.convince`, `e.mercy`, `e.calmed`, `e.spared`, `e.ctx`,
  `e.convinceNeeded` — unidade → def → role → global) e aplica a janela de
  graça (`Battle.graceTime = .8` no mínimo, escalonada .15s por unidade).
  Kinds sem def no catálogo (`janda`, `rute`, `ivo`, `beltran`) vestem a
  família do role via `FAMILY` + `rtDef` até o passo 5 escrever os defs.
- **Contagem**: `liveEnemies`/`outcome` excluem `enemy.summoned` e
  `replaced` — servo invocado não entra na cota nem no desfecho; casulo
  eclodido sai da contagem sem contar como queda.
- **Freeze**: `Battle:update` retorna cedo com `campaign.dialogue` ou
  `phase ~= 'action'` — projétil em voo congela no mesmo quadro. Morte do
  jogador (hp 0) resolve por `campaign:die` mesmo congelada.
- **Rendição**: `ctx.nonLethal` arma o guard em `damage`/`killFatal` —
  zerar a vida vira `hp = 1` + `spared` + retirada, nunca `effect('death')`.
- **POUPAR**: `battle:interact` (evento E do frame) confirma a retirada
  por proximidade em `calmed`/`mercy`; o menu `spare` cobre a distância.
- **Convencido**: atingir o limiar em `actOn` marca `mercy` + `calmed` e o
  inimigo para na hora — telegrafo já armado (`warn`/`dash`/`volley`)
  resolve antes de parar (a prévia nunca mente). Golpe válido desfaz a
  trégua na hora (D08 portado em `Battle:hurt`).
- **Picareta**: `self.pickaxes` espelha `data.items.picareta` a cada tick;
  a mineração da arena gasta a ferramenta real da bolsa.
- **Bolsa/morte**: `campaign:applyItemEffect` cura a entidade de batalha
  durante a arena; `die` restaura `health.max` depois do sync — a vida
  zerada da arena não escorre para a exploração (`-- MERGE-SHIM` nos três
  toques de `campaign.lua` e nos três de `main.lua`).

Fora do escopo deste passo (vem nos seguintes): fechamento de fase por
cota/timeout (`phaseQuota`, `phaseTimeout`, `stallLimit` já declarados),
`wait`/respiração, fase `pause` com o menu rodando, beats de conversa,
micro-fase de fuga e defs real-time próprias dos chefes humanos.

## Implementado (passo 12.2)

O ciclo fásico fecha: ação ⇄ pausa roda inteira. Decisões registradas:

- **Cota**: `quotaFor` resolve `u.quota` → `def.quota` (encontro) →
  `Enemies[kind].quota` → `Battle.phaseQuota`. "Agiu" é a saída de `warn`
  lida por `a.wasState` na varredura pós-emit — whiff conta, `volley` do
  veterano é continuação do mesmo resolve (1 ação), `summoned` não entra.
- **Anti-stall**: `stallClock` acumula em `seek` parada ou andando; ao
  passar de `stallLimit` a unidade ganha `e.stalled` e conta como cumprida
  (não `quota++` literal — quem provou não achar passo não segura a rodada)
  com o say honesto "não encontra passo".
- **Quieto**: `arenaQuiet()` exige fora {warn,dash,volley}, sem projétil,
  sem hazard armado, sem `motion.falling` e sem tile `falling` (pilar).
- **Respiro**: `enterBeat` recua um passo (`retreatStep` determinístico —
  eixo dominante, depois o outro, flancos em ordem fixa) e trava
  `state='wait'` + `e.resting`. O ramo `wait` de `Enemies.step` segura
  enquanto `resting`; `resumeAction` derruba a marca e a máquina devolve
  `seek`. `calmed`/`dormant` não respiram nem seguram a cota.
- **Pausa**: `beat = .4` → `enterPause` cancela a carga do arco, bark
  `announce` do palco, `mode='menu'` em CONTINUAR. `key()` consome tudo na
  pausa: WASD cicla, ENTER/E confirma, ESC desce um nível (no menu =
  CONTINUAR). Pick custoso (ACT real, USAR com efeito, POUPAR, FUGIR)
  encerra a pausa via `resumeAction`; OBSERVAR/recusas/travados ficam no
  submenu. `round++` por fase mantém barks variando sem RNG.
- **FUGIR**: retirada direta por `endBattle('return')` — a micro-fase do
  §6 é passo 5.
- **Renderer**: `phase='pause'` já lê 'VAGA' na placa e no rodapé; o corpo
  do menu/submenus é passo do Traço — contrato: `mode` ∈
  {menu,act,actlist,use,mercy} + `menuIndex/actTarget/actIndex/useIndex/
  mercyIndex` + `menuItems()/actItems(e)/useItems()/spareable()`; novos
  estados de unidade: `wait`/`resting` (respiro) e `closing`/`beat` na
  batalha.

Fora do escopo deste passo (vem nos seguintes): beats de conversa (§7),
provoked forçando engage com warn fatorado (§5.1), micro-fase de fuga
(§6), `bossPhase` como beat e defs real-time dos chefes humanos.

## Implementado (passo 12.3)

A camada social de §5.1–§5.4 fecha: calmed é um estado de máquina real,
provoked vira mecânica de engajar, o palco ganha emoção legível e D08 está
verificada. Decisões registradas:

- **`calmed` na step machine** (`enemies.lua`): ramo explícito que não
  busca, não engaja, não resolve — o corpo parado respira e a máquina
  nunca sai daí por conta própria. A única porta é a arena: `Battle:hurt`
  repõe `seek` quando um golpe válido trai a trégua. `applyCalm` cobre
  `wait` também — convencer durante a pausa não reanima a caça na
  retomada (`resumeAction` manda `wait`+`calmed` direto para `calmed`).
  O telegrafo em curso continua sagrado: warn/dash/volley prometidos
  resolvem antes da unidade parar. Convicção externa (diálogo de
  abertura) segue o mesmo caminho: `u.mercy`/`u.calmed` no def de
  unidade faz a entidade nascer em trégua.
- **`provoked` força o engajar**: no ramo `seek` da step machine, a
  unidade com `e.provoked` tenta o engage natural e, se falhar, cai no
  `def.provokedEngage` — a saída honesta por kind, que ignora
  alinhamento/alcance ideal no primeiro gatilho disponível. O warn sai
  ×`Battle.provokeWarnFactor = .8` (`timer` e `warningDuration`
  fatorados no anúncio — dano igual, telegrafo mais curto) e a flag se
  consome ali. Saídas honestas por família: atiradores de linha na
  cardeal da jogadora (`Rooms.line` corta a prévia na parede e o virote
  para junto — whiff honesto), dashers no eixo dominante (a peça para o
  corpo como qualquer investida), cruz do vigia/warden a qualquer
  distância, marca do semeador sem alcance mínimo (marca já armada
  segura o gatilho), regente atira na cardeal. **Corpo a corpo**
  (crawler) não tem golpe honesto fora do adjacente: o provocado avança
  e o primeiro gatilho real sai encurtado — a isca espera sem forçar um
  ataque impossível. Defs derivados de família (chefes humanos) herdam a
  saída da família via `__index`. No protótipo nada muda: `e.provoked`
  nunca é marcado e `g.provokeWarnFactor` cai no default .8.
- **§5.4 — emoção do palco**: `Battle:emotionFor(e)` lê o estado social
  na precedência spared→'sad', provoked→'anger', calmed/mercy→'joy',
  convince>0→'soft', hp<30%→'fear', senão 'stern' — e 'neutral' para
  kinds `verbal=false` (o gesto é a face; quem não fala não franze a
  testa — vocabulário compartilhado com `Barks.expr`). O campo cacheado
  `self.stageEmotion` acompanha quem fala: atualizado em `sayBark` (o
  falante é o palco) e relido a cada `enterPause` mesmo sem linha.
  Contrato do Traço: função `battle:emotionFor(e)` + campo
  `battle.stageEmotion`.
- **D08 verificado**: o golpe válido em `mercy`/`calmed` — já portado em
  `Battle:hurt` dentro de `damage()` — desfaz a trégua, zera `convince`
  e repõe `seek`; teste cobre o estado de máquina, não só as flags.
- **spareable/spare/outcome/'negotiated'**: conferidos — nada mudou
  (`spared` sai da contagem, poupo conclui 'negotiated' sem queda).

Fora do escopo deste passo (vem nos seguintes): beats de conversa (§7),
micro-fase de fuga (§6), `bossPhase` como beat, defs real-time próprias
dos chefes humanos e a leitura visual do retrato no renderer.

## Implementado (passo 12.4)

Os beats de conversa do §7 fecham: gatilhos declarados armam, a fila dispara
na pausa quiet (ou na abertura, no caso do 'start') e o menu de postura
assume quando ela esvazia. Decisões registradas:

- **Namespace**: os nodes moram em `src/battle_talks.lua` (`Talks.nodes`),
  arquivo novo que não disputa ids com os talks de exploração.
  `Battle:beatNode(id)` consulta a tabela primeiro e cai em
  `LoreC.talk(campaign, id)` como fallback — os nodes que o Pena escrever
  nos encontros servem direto, mesma gramática de `Dialogue.open`. Node
  sem id declarado em lugar nenhum é descartado em silêncio: o beat cai
  e o menu assume.
- **Fontes e ordem**: `def.beats` (encontro) avalia primeiro — a linha
  autoral tem prioridade — depois `u.beats` da entrada de unidade e os
  beats do kind (`ROLES[kind].beats` e `rawget(Enemies[kind],'beats')` —
  rawget para o def derivado dos chefes não herdar falas da família que
  veste). `self.beats` é a lista normalizada; `once` marca
  `e.beatFired[i]` nas de unidade e `self.beatFired[i]` nas do encontro,
  no índice dessa lista — e a marca acontece no disparo, não no armar:
  falante que cai entre armar e falar libera o gatilho para outro.
- **Escopos de avaliação**: 'start' no construtor (fala antes do primeiro
  tick — o freeze de `campaign.dialogue` já segura a arena), 'pause' em
  `enterPause` depois de decidir a pausa e antes de montar o menu
  (round/hpBelow/passiveFor caem aqui por segurança), 'tick' a cada
  quadro da ação (hpBelow arma no mesmo tick do dano — a exigência de
  viva impede o morto de falar — e passiveFor lê o relógio contínuo),
  'mercy' e 'bossPhase' no evento, com `owner` = a unidade que baixou a
  guarda ou rompeu o selo.
- **Disparo**: `beatQueue` guarda `{unit, node, ref, now}` — `now` só nos
  de 'start', que abrem a qualquer momento; os demais esperam
  `phase == 'pause'`, então um beat nunca corta telegrafo. `pumpBeats`
  drena na ordem: falante morto/poupado entre armar e falar é pulado;
  `mode = 'beat'` durante a fala e volta a 'menu' esvaziada a fila;
  `self.beatSpeaker` + `stageEmotion` apontam quem fala (contrato do
  Traço para o retrato). `beatOpen` + o relógio de `update` detectam o
  fechamento e abrem o próximo — ou o menu.
- **Falante** (§11): `beat.speaker` (índice na lista de unidades, kind ou
  entidade) > `u.speaker` no def > a unidade dona do gatilho quando
  verbal > primeiro verbal vivo na ordem do def. Encontro sem falante
  vivo: sem beat — o gesto é a face.
- **passiveFor**: `self.passiveClock` acumula na fase de ação com o arco
  em 'empty'; charging/ready/action e os eventos charge/fire zeram.
  Acumula entre fases — a rota "só desviar" é recompensada no agregado.
- **'won' vence a fila**: `update` sai em `self.over` antes de bombear e
  `pumpBeats` recusa arena vazia — nem 'won' nem 'negotiated' deixam um
  diálogo de beat pendurado depois do `endBattle`.
- **bossPhase**: `enemies.lua` mantém notify/effect e, quando `g` é a
  arena (`g.evalBeats` existe), arma `{when='bossPhase'}` se declarado —
  no protótipo a guarda falha e nada muda.
- **Convicção de nascença**: `u.mercy`/`u.calmed` no def não dispara o
  gatilho 'mercy' — ele escuta a transição, não o estado inicial.

Fora do escopo deste passo: micro-fase de fuga (§6), defs real-time
próprias dos chefes humanos e a leitura do `beatSpeaker`/retrato no
renderer (Traço).

## Implementado (passo 12.5)

A micro-fase de fuga (§6) e os chefes humanos real-time (§12 do legado)
fecham. `FUGIR` deixou de ser retirada instantânea e os quatro chefes do
ato social ganharam defs próprios no catálogo Enemies — ROLES segue com
`boss='hammer'/'push'/'jet'/'shove'` só como marcador social (música e
introdução leem `u.role.boss`); a mecânica mora na def. Decisões:

- **Saída determinística**: `Battle:fleeExit()` mede a distância da
  jogadora a cada borda do tabuleiro (células floor); a mais próxima
  define "o lado" e a saída abre na oposta — empate prefere a horizontal
  (o tabuleiro é largo), depois norte sobre sul. Na borda escolhida vence
  a célula `free()` mais próxima da linha/coluna dela, desempate pelo
  índice menor; borda inteira vedada recua coluna a coluna para dentro.
  Sem piso livre em lugar nenhum, `exitCell` nasce nil e a fuga só pode
  falhar — documentado, sem RNG.
- **Volley de despedida**: cada hostil vivo (a contagem exclui
  spared/summoned e o filtro exclui calmed/dormant) deve UMA investida.
  Quem já tinha telegrafo armado (warn/dash/volley) tem o prometido como
  despedida (`volleyDone`); quem estava ocioso ganha `e.volleyPending`,
  que o ramo `seek` da máquina dispara como engajar imediato — natural
  primeiro, `provokedEngage` (a saída honesta por kind) quando o gatilho
  falha; corpo a corpo sem saída avança e a investida fica pendente até o
  primeiro warn real. A flag quita no RESOLVE (transição warn→estado), não
  no anúncio — a despedida prometida sempre fecha, whiff incluso. Quem
  estagnou (`stalled`) tem a despedida prescrita.
- **Quem despediu, segura**: unidade com `volleyDone` entra em `wait` +
  `resting` ao sair de warn/dash/volley — é o que torna "a volley fechar"
  alcançável numa arena viva sem reescrever a máquina. Falha ou desistência
  limpa pending/done/resting e a máquina devolve a caça.
- **Fechamento da fuga**: pisar na `exitCell` (parada, `motion` zerada) →
  `endBattle('return')` → `retreatFrom` normal. Volley fechada (nenhum
  pending + `arenaQuiet`) sem ela na saída → 'A saída fecha.', ação segue,
  o pick foi gasto. Zero participantes (todos calmed) → a saída fica aberta
  — ninguém se opõe. ESC na fuga = desistir (§11): consome a tecla, fica.
  A cota de fase não pede fechamento durante a travessia — a fuga é a sua
  própria regra de encerrar; morrer na travessia segue `campaign:die`.
- **Chefes humanos**: `Enemies.janda/rute/ivo/beltran` — `boss=true`,
  `armor=false` (a armadura frontal é do role, não da família emprestada),
  metatable na família (janda/beltran=dasher, rute/ivo=ranger) herda
  seekGoal/think/recover/provokedEngage. `engage` avalia o gatilho autoral
  primeiro e cai na família — o chefe nunca fica sem plano. `pre` roda o
  `bossPhase` existente (hp<50% → fala+effect+beat armado) e a fase 2 só
  encurta os warns (×~.8) — simples como pedido.
- **Janda 'hammer'**: pilar em pé a ≤4 manhattan dela, o mais próximo da
  JOGADORA (desempate por varredura y,x). Warn marca a célula do pilar +
  `Environment.fallCells` no eixo dominante pilar→jogadora. Resolve: queda
  de arena — `Battle.pillarDamage` (2) + reposição (flanco, flanco, à
  frente, atrás — ordem fixa) em TODA unidade na banda, e a faixa vira
  `piece='fallen'`; o recheque só encurta o prometido. Pilar já caído →
  'golpeia o vazio'. Não é o crushFatal do ambiente — chefe humano não
  executa por queda (spec antigo).
- **Rute 'push'**: primeira crate na ordem de `g.crates` alinhada com a
  jogadora a ≤4, destino livre ou a célula dela. Warn = só a célula-
  destino. Resolve: o caixote desliza (atualiza `cell.piece` e a ref em
  `g.crates`); jogadora no destino cede 1 célula além se livre, senão 'a
  vara empurra — você não cede' e o caixote fica. Sem dano.
- **Ivo 'jet'**: jogadora numa banda de `g.channels` (encontro) ou
  `def.channels` (default `{rows={7},cols={4,10}}`), rows primeiro. Warn =
  TODA célula floor da banda; resolve cobra `Battle.arrowDamage` (2) de
  toda unidade na faixa exceto ele — fonte co-local ao alvo, então nem
  escudo frontal nem armadura de face se aplicam: hazard de área, i-frames
  e rendição normais. Pode matar.
- **Beltran 'shove'**: gatilho = gate do dash bruto; o selo é 'shove' e a
  batida vai por `def.dashHit` — gancho novo no `dashStep` (sem def → dano
  padrão, protótipo intacto). Escudo frontal bloqueia inteiro ('BLOQUEADO
  pelo escudo'); senão a jogadora desliza até 2 células (`shoveT/shoveDx/
  shoveDy` já desenhados pelo renderer); zero livres → 1 de 'prensa'.
  Beltran termina onde ela estava.
- **Contrato do Traço**: `battle.fleeing`, `battle.exitCell={x,y}`,
  `battle.flee.edge`; warns dos chefes expõem `a.mode` ∈
  {'hammer','push','jet','shove'} + `a.cells` (glifos já existem no
  intentGlyph). Unidades na fuga: `e.volleyPending`/`e.volleyDone`.

## Implementado — C01-Q1 / grade Runa

O confronto opcional da grade (P01-E04) fecha a ponta de arena: a Runa é o
primeiro chefe humano da campanha e o encontro inteiro é um canal
declarativo — sem mecânica autoral nova. Decisões registradas:

- **Ficha**: `ROLES.runa` (`hp=10`, `plan='sentinel'`, `convinceNeeded=3`) é
  só a ponte social; `Enemies.runa` é def derivado de `Enemies.ranger`
  (`boss=true`, `armor=false`, `think=.35`, `damage=1`, `recover=1.0`,
  metatable `__index`) — anuncia avanços com o virote de linha e nunca
  traz golpe de morte instantânea. A identidade dela mora na conversa e na
  rendição, não num gatilho próprio.
- **nonLethal em cadeia** (§5.3 ampliado): `Battle:nonLethal(e)` resolve
  `e.nonLethal` (unidade, via `u.nonLethal` no def) → `self.def.nonLethal`
  (encontro) → `Barks.context(kind, ctx).nonLethal` (o caminho antigo do
  C05-Q01, intocado). Booleano declarado num elo superior decide sozinho:
  `false` desarma os inferiores, não só `true` arma. O kind nunca decide
  por conta própria: é sempre a ficha do encontro falando. Para a Runa
  isso é essencial — `kinds.runa` não tem `contexts`, então `ctx='duelo'`
  não a cobre; o flag do def é o canal honesto (e está no def real). Precedência estrita: um booleano declarado num elo superior
  decide sozinho — `nonLethal=false` na unidade desarma o `true` do def,
  e o lookup sempre devolve booleano (nunca nil).
- **`damage` declarativo do virote**: `Enemies.ranger.resolve` passa a ler
  `Enemies[kind].damage or 2` no `g:shoot` — mesma convenção do
  `def.damage or 2` do dashStep. É o que torna o `damage=1` da Runa real:
  o virote dela mede, não executa; ranger/rute/ivo declaram 2 e nada muda.
- **`def.onResolve`**: `Campaign:endBattle` chama `def.onResolve(self,
  result)` dentro do bloco won/negotiated, depois do saque e antes do
  checkpoint — e só na primeira marcação (`unresolved`), como o loot: um
  encontro já resolvido nunca repete o efeito. A demonstração pós-grade é
  o MESMO encontro, sem re-emissão.
- **A ponte talk→confronto→arena→openGrade**: contato com a criatura abre
  a talk 'runa' enquanto a flag `<confronto>` está baixa; a opção do node
  (o desafio) sobe a flag e o contato seguinte dispara `startBattle`. Na
  resolução, `onResolve` chama `openGrade(result)` — `gradeHow` registra
  'won'/'negotiated', a grade abre e a Runa migra para o hub.
  `'return'` (fuga) não toca nada: impasse honesto, a criatura fica e o
  talk rearma pelo `greeted`.
- O conteúdo social já existia (`Barks.kinds.runa`, voz 1.05, retrato e os
  ACTs guardar/inspecao/versao/tregua); os nodes `runaDesafio/
  runaRendicao/runaAcordo/runaDerrota` moram em `battle_talks.lua`.

Fechamento da ponta (integração mapa ↔ arena):

- **Marcador no lado norte** (6,16 — boca do corredor da grade): alcançável
  do spawn antes da grade abrir; qualquer posição dentro do salão ficava
  atrás das barras lacradas e o contato nunca acontecia.
- **`trigger='flag'`**: watcher em `Campaign:update` — encontro com o campo
  dispara `startBattle` no update seguinte à flag `<confronto>` subir
  (`'runaConfronto'`, escrita pela opção DEMONSTRAR CAPACIDADE do node
  `talks.runa`). A prova acontece sem exigir contato; a flag é consumida
  no disparo, então fuga devolve o impasse e pede nova aceitação.
- **Criatura falante**: o npc `runa` saiu de `colina.npcs` — a criatura do
  encontro cobre o papel por inteiro. `def.talkRange` alimenta o pool de
  `interactTarget` (kind 'talker'): interact à distância abre o mesmo node
  do contato — ela responde do posto como respondia através da grade. A
  flag não fecha a conversa: só decide o contato e o watcher — negociar
  nunca fica trancado atrás da própria prova.
- **`nonLethal` na ficha**: o def declara `nonLethal = true` — `ctx='duelo'`
  fica como etiqueta de contexto dos barks (a tabela `kinds.runa` não tem
  `contexts`, então o ctx sozinho não armava nada; o flag do def é o canal
  da cadeia unidade > def > ctx).
- **`gradeHow` preserva a primeira abertura**: `openGrade` não sobrescreve
  'confessou'/'doro' quando a demonstração resolve depois da grade aberta.
- Beats da ficha: `runaAbertura` ('start'), `runaAcordo` ({hpBelow=.5},
  once), `runaRendicao` ('mercy', once) — fala dela, unidade `speaker`.
