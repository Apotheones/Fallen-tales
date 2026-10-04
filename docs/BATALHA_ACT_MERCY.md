# Batalha — contrato atual de combate e inventário

Revisado em 03/10/2026. Regras em `src/battle.lua`, conteúdo em
`src/battle_barks.lua`, inventário em `src/items.lua`/`src/campaign.lua` e
apresentação em `src/render.lua`. As seções indicam o implementado e as
propostas adiadas; constantes do código definem os valores atuais.

## 1. Fronteira regra vs apresentação

| Peça | Tipo | Estado |
| --- | --- | --- |
| Item AGIR no menu + submenu por alvo | regra | implementado |
| Estado `e.convince` / `e.mercy` / `e.spared` / `e.provoked` | regra | implementado |
| POUPAR → `endBattle('negotiated')` | regra | implementado (plumbing já existia) |
| Resolução escalonada (um inimigo por batida, ordem estável) | apresentação autorizada | implementado |
| Barks no log/rodapé via `say()` | apresentação | implementado |
| Balões de fala sobre a unidade | apresentação | implementado em `render.lua` |
| Ícones dos slots `act`/`mercy` | apresentação | implementado em `render.lua` |
| Textos de rodapé dos modos `act`/`actlist`/`mercy` | apresentação | implementado em `render.lua` |
| Unidade poupada some da grade | apresentação | implementado: despedida e exclusão da ocupação |
| `u.mercy` na fila de turnos | — | **grátis**: renderer já lê (`frameC gold`) |

## 2. Novo estado na unidade

| Campo | Significado |
| --- | --- |
| `e.convince` | contador de ACTs sociais aceitos (0 até `Battle.convinceNeeded = 2`) |
| `e.mercy` | "baixou a guarda": elegível a POUPAR; a fila de turnos já doura a ficha |
| `e.spared` | retirada aceita: sai de `liveEnemies()`, não ocupa célula, não anuncia |
| `e.provoked` | próximo `announce()` produz ataque na direção dominante do jogador |

## 3. ACT — fluxo e custos

`menuItems()` ganha `act` ("AGIR") logo após ATACAR. Sempre habilitado —
navegar pelos submenus é consulta, não ação (contrato: "Ler, escolher
tópicos ou cancelar antes de assumir compromisso não dispara o turno").

- Modo `act`: WASD cicla os alvos vivos (`liveEnemies()`), ENTER fixa o alvo,
  ESC volta ao menu.
- Modo `actlist`: WASD cicla `Barks.kind(e.enemy.kind).acts`, ENTER confirma,
  ESC volta à seleção de alvo.

Custos por tipo de ACT:

| Caso | Custo | Resultado |
| --- | --- | --- |
| `observar` | **grátis** | escreve `check` (1-2 linhas) + bark `act.observar` no log; fica no submenu |
| recusado (`kind.refuses[id]`, ou qualquer social em `negotiates=false`) | **grátis** | bark `refuse.<id>` ou `refuse._`; fica no submenu. §6: uma tentativa recusada não pode virar armadilha de turno |
| `proposal=true` fora de `LIVE_ACT` | desabilitado | `disabled` no item com motivo; mecânica não existe ainda (ver §8/§15) |
| `provocar` | uma ação | `e.provoked = true`; ver §5 |
| demais (`tregua`, `acalmar`, …) | uma ação | `e.convince + 1`; ao atingir o limiar → `e.mercy` |

Como `acted` já encerra a fase, um ACT custoso segue o mesmo caminho de
ATACAR: `afterAction()` → `endTurn()` → resolução.

## 4. MERCY / POUPAR

`menuItems()` ganha `mercy` ("POUPAR") antes de ESPERAR, `disabled` quando
`self.acted` ou quando `spareable()` está vazio ("Ninguém baixou a guarda
ainda.") — o menu continua honesto sobre opções indisponíveis.

- `spareable()` = vivos, não poupados, `e.mercy`.
- Modo `mercy`: WASD cicla os poupadíveis, ENTER confirma.
- Poupar **custa a ação** (modelo Undertale): `e.spared = true`,
  `e.intent = nil`, bark `spared`, depois `afterAction()` → resolução roda
  para quem sobrou.
- Fim: `finishResolve()` conta mortos. **Nenhum morto e ao menos um poupado
  → `endBattle('negotiated')`**; mistura (matou um, poupou outro) → `'won'`.
  `campaign:endBattle` já trata 'negotiated' igual a 'won' (marca encontro,
  tira a criatura do mundo, checkpoint).
- Poupar a última unidade encerra o combate na própria resolução — não cria
  rodada vazia.

## 5. Efeitos de ACT sobre `e.intent`

- **Convinção** (`convince >= 2`): `e.mercy = true` **e a intenção anunciada
  é suspensa na hora** (`{kind='hold'}`) — o acordo pode: "aceitar pode
  modificar ou suspender intenções". Nas rodadas seguintes `announce()`
  emite `hold` para unidades `mercy`, então a telegrafia fica honesta.
- **Provocação**: consome na próxima `announce()`. Se desalinhado, o plano
  normal viraria `move`; provocado, a unidade anuncia `shoot`/`dash` no eixo
  dominante em direção ao jogador — a linha é honesta e vai errar quem se
  moveu, que é o uso tático do ACT (isca). Alinhado, comportamento idêntico
  ao plano normal.
- `announce()` ignora `e.spared` (`intent = nil`) e `e.mercy` (`hold`).

## 6. Resolução escalonada (autorizada D02)

`endTurn()` não resolve mais no mesmo passo: monta `resolveQueue` (um passo
por inimigo, na ordem estável por ID — a mesma de sempre) e `phase =
'resolve'`. `Battle:update` drena a fila: uma batida de
`Battle.resolveIntro` (.3s) antes do primeiro, `Battle.resolvePace` (.55s)
entre passos. Cada passo chama `resolveStep(e, i)` — o mesmo corpo do laço
antigo: morto descarta, `shoot`/`dash`/`move`/`hold`. Quando a fila esvazia,
`finishResolve()` executa a cauda do `endTurn` original (guarda cai, morte
do jogador, conclusão, `round++`, `announce()`).

**Resultados idênticos ao bloco síncrono**: mesma ordem, mesmas funções,
mesma evolução de estado — só espaçada no tempo. "Sequência legível" do §2
deixa de ser log instantâneo e vira execução visível, um número de ordem por
vez (o pip da fila de turnos acompanha de graça).

Contratos preservados:

- **Pausa/foco**: `campaign:update` só roda com `screen == 'campaign'`;
  pausado, a fila congela naturalmente.
- **Diálogo**: `battle:update` retorna cedo se `campaign.dialogue` — congela
  fila **e** o step-clock no mesmo quadro (regra "inclusive no mesmo quadro
  da interação").
- **Teclas durante `resolve`**: `battle:key` engole tudo **menos ESC**, que
  sobe ao dispatcher e vira pausa, não fuga (D06 — main.lua trata
  `phase == 'resolve'` como exceção ao atalho de retirada). A fila congela
  naturalmente: `campaign:update` só roda com `screen == 'campaign'`.
- **Reduced-motion**: canal `campaign.reducedMotion` espelhado do renderer
  (startCampaign + toggle F2); `Battle.resolveCalm` (.45) multiplica o
  intro e o pace — a ordem e os resultados não mudam, só o compasso.
- **Morte do jogador** continua verificada no fim da fila — um passo letal
  não interrompe os seguintes, igual ao bloco antigo.

## 7. Barks → canal atual

Toda fala passa por `say()` (log de 4 linhas → rodapé). Variantes escolhidas
deterministicamente por `(round % #lista)` — sem RNG novo, testável.

| Gatilho | Origem | Situação Barks |
| --- | --- | --- |
| `announce()` — **uma voz por rodada**, a do primeiro vivo (palco) | `barks.announce` | por rodada |
| flecha acerta e o alvo sobrevive | `barks.damage` | |
| ACT aceito | `barks.act.<id>` | |
| ACT recusado | `barks.refuse.<id>` / `refuse._` | |
| `e.mercy` marcado | `barks.convinced` | |
| `e.spared` | `barks.spared` | |
| `convince == 1` | `flavor.almostConvinced` (`%s`→nome) | |

Não ligado: `flavor.roundStart/hesitates/quiet/fled/resolved` — o log de 4
linhas já carrega resolução + bark + linha de rodada; ligar flavor extra
afogaria as linhas de ordem. Reavaliar quando o rodapé ganhar área própria.

Balões sobre a unidade e gestos estão implementados em `render.lua`.

## 8. Decisões — Codex

1. **`proposal=true`**: propostas fora de `LIVE_ACT` seguem desabilitadas
   com motivo. Estão implementados `watcher.vela`, `husk.embalar` e
   `regent.despedida`; ver §15. As demais aguardam sua mecânica.
2. **`convinceNeeded` por encontro**: **D09 — implementado.** Campo
   `convinceNeeded` no def da unidade ou do encontro; default global 2.
   Chefes podem exigir 3+ ou condição narrativa.
3. **Poupar por dano**: **D07 — adiado.** `e.mercy` só vem de conversa.
4. **Atacar unidade convencida**: **D08 — implementado.** Golpe VÁLIDO
   (flecha que acerta, queda de pilar que esmaga) desfaz `e.mercy` e zera
   `e.convince`; ação inválida/cancelada não altera. Sem contra-ataque.
5. **Pausa durante `resolve`**: **D06 — implementado.** `battle:key` devolve
   `false` só para ESC em `resolve`; o dispatcher de main.lua vira pausa
   (não fuga) e a fila congela naturalmente (update só roda em
   `screen == 'campaign'`).
6. **Reduced-motion → pace**: **D06 — implementado.** Canal
   `campaign.reducedMotion`, espelhado do renderer em startCampaign e no
   toggle F2; `resolveCalm = .45` multiplica intro e pace.
7. **Mover 3 células e ação-encerra-fase**: **D10 — canônico.** A
   implementação está certa e fica: `moveRange = 3` e confirmar ação encerra
   a fase. A ação confirmada encerra a fase; não há movimento depois dela.
8. **`negotiated` misto**: **D11 — canônico.** `negotiated` exige TODAS as
   unidades resolvidas sem letalidade; matou um e poupou outro → `'won'`.
9. **Poupado fora de tudo**: **D11 — implementado.** `e.spared` não é alvo,
   não bloqueia ray/`free()`, não entra em IA/inspeção/resolução; some do
   mundo no mesmo tick e nunca retorna.
10. **Aliados bloqueiam tiro**: **D12 — implementado.** A trajetória morre
    na primeira unidade viva ocupante (aliado ou jogadora) — sem fogo
    amigo; a telegrafia termina onde o golpe para de fato e o log nomeia a
    interceptação ("X corta a linha").

## 9. Gancho pré-combate: diálogo na abordagem (implementado em campaign.lua)

Encontros negociáveis abrem com conversa, não com contato→arena:

- O def do encontro ganha `talk` (id roteado por `LoreC.talk`, mesma
  namespace dos npcs) e `confronto` opcional — default `<talk>Confronto`,
  que é a convenção que o Pena já escreve (`jandaConfronto`, `ivoConfronto`,
  `guardaConfronto`…).
- Contato com `def.talk` e flag ainda baixa abre o node em vez de
  `startBattle`. A criatura vira para a jogadora, `player.moving` cai e
  `checkpoint` grava a abordagem — mesmo rito do `interact` de NPC.
- Dentro da conversa, as opções do node fazem o resto com o vocabulário já
  existente: `encounters[id]='negotiated'` resolve pacificamente (a
  criatura some do mundo no tick seguinte — purge de `self.enemies` por
  flag), `<talk>Confronto = true` faz o **próximo contato disparar a arena
  na sequência** — normalmente no quadro em que a caixa fecha, pois a
  jogadora ainda está ao lado.
- `e.greeted` (sessão, por criatura): SAIR sem flag deixa o contato inerte
  — não reabre a caixa a cada frame nem cai em batalha. Afastar mais de
  1,5 célula rearma a conversa.
- `def.talk` sem node escrito → contato inerte (a ficha deve parear talk
  com um node real; nunca queda silenciosa na arena).
- Encontro já resolvido nunca reaparece a conversa nem a batalha —
  `enter` já filtra e o purge cobre o mesmo tick.

| Regra nova | Fronteira |
| --- | --- |
| contato→diálogo quando `def.talk` | regra (contrato: "ameaça ou recusa explícita → transição") |
| `<talk>Confronto` dispara arena | regra — convenção de flag já escrita |
| purge de resolvido na exploração | regra — fecha o ciclo que o write direto de Pena abria |
| `e.greeted` por proximidade | mecânica de apresentação do gancho |

## 10. Checklist de verificação (tests/battle.lua)

- fila escalonada: `endTurn` arma `phase='resolve'`; uma batida resolve um
  inimigo; `drain()` fecha a rodada com resultados idênticos.
- freeze: `campaign.dialogue` truthy congela `resolveQueue` e step-clock.
- `battle:key` engole teclas durante `resolve` (ESC não foge).
- AGIR no menu; submenu por alvo; OBSERVAR grátis; recusa grátis com bark;
  TRÉGUA cobra ação e convence no limiar; convencido suspende `intent`.
- PROVOCAR em alvo desalinhado → próximo `announce` vira `dash`/`shoot` no
  eixo dominante.
- POUPAR custa ação, `e.spared`, último poupado → `'negotiated'` persiste e
  a criatura sai do mundo.

## 11. Roles de arena (crawler + chefes)

Novas entradas em `ROLES` (src/battle.lua) e o despacho de `Battle:plan`:

- **`crawler` — plan `crawl` (RASTEJANTE, hp 4).** A fera não mira linhas:
  adjacente ortogonal (manhattan 1) anuncia `{kind='dash', range=1}` — a
  mordida telegrafada marca a célula vizinha ("mordidas marcam células
  adjacentes" das fichas). `intentCells` respeita `intent.range`, então
  prévia e resolução concordam em exatamente uma célula: quem sai da marca
  vê o rastejante cair na célula vazada — "erra feio; o erro o deixa
  aberto" (CHECK). Fora do alcance anda 1 célula por rodada no eixo
  dominante (`self:free`, uma tentativa); bloqueado, `hold`. Recusa
  `provocar` nos barks — o ramo de `provokedPlan` que devolve `'dash'`
  para o plan `crawl` é apenas preventivo.
- **Chefes humanos** herdam a família mecânica e ganham uma mecânica
  própria via `role.boss` (ver §12): `janda`/`beltran` = `brute`
  (investida — "martelo largo" B02-01, "cortina e bastão" B05-01),
  `rute`/`ivo` = `sentinel` (avaliação à distância B03-01, "jatos pelas
  linhas do canal" B04-01).
  HP é placeholder (14/12) até o balanceamento. `convinceNeeded = 3` vem
  do role; a precedência do limiar fica: unidade → def do encontro →
  role → global (`Battle.convinceNeeded = 2`).
- **Pendência de ids:** o encontro de teste `T01-01` em
  `src/regions/colina.lua` colide com a convenção de etapas T01–T03 da
  Teca. Proposta: renomear para `TEST-01` — sinalizado ao Pátio (dono do
  arquivo). Convenção adotada: encontros comuns `C0X-YY`, chefes `B0X-01`.

## 12. Mecânicas de chefe por role

Cada chefe humano carrega `role.boss` — uma mecânica extra avaliada em
`Battle:plan` **antes** do despacho de família (`crawl`/`brute`/`sentinel`).
Se o gatilho não dispara, a família cuida do turno (o chefe nunca fica sem
plano). Todas as intents entram na mesma `resolveQueue` — ordem estável
preservada — e telegrafam por `intentCells`: prévia e resultado concordam
sobre célula, cobertura, ordem e área, sem timers de decisão.

| Boss | `role.boss` | Gatilho | Intent | Resolução |
| --- | --- | --- | --- | --- |
| JANDA | `hammer` | existe pilar em pé a ≤ `Battle.hammerReach` (4) manhattan; escolhe o pilar mais próximo da **jogadora** (a cobertura que vale), desempate por varredura (y,x) | `{kind='hammer', x, y, dx, dy}` — x,y do pilar; dx,dy = queda no eixo dominante pilar→jogadora | `resolveHammer` → `topplePillar` (mesma queda do PILAR da jogadora): `pillarDamage` + reposition em TODA unidade na banda, **inclusive a jogadora** — o martelo não perdoa. Pilar já caído → "golpeia o vazio" |
| RUTE | `push` | primeira crate (ordem de `self.crates`) alinhada com a jogadora a ≤ `Battle.pushReach` (4), cujo destino seja `free()` ou a célula dela | `{kind='push', x, y, dx, dy}` — telegrafo = a célula-destino | `resolvePush`: destino==jogadora → ela cede 1 célula além se livre (bloqueada: "a vara empurra, você não cede", crate fica); destino livre → crate desliza; bloqueado → "o caixote não cede". **Sem dano — controle posicional** |
| IVO | `jet` | jogadora numa banda de `channels` (rows checadas primeiro, determinístico) | `{kind='jet', row=r}` ou `{kind='jet', col=c}` — telegrafo = toda célula floor da banda | `resolveJet`: `arrowDamage` em toda unidade na banda — jogadora e aliados, **exceto o próprio Ivo** (controla as válvulas). Hazard de área, não ataque direcionado: **o escudo frontal não se aplica**. Pode matar — jogadora → `die()` normal via `finishResolve`; aliado cai sem bark extra |
| BELTRAN | `shove` | idêntico ao gatilho da investida do bruto (alinhado + dist ≤ `dashRange` + `rayClear`) | `{kind='dash', dx, dy, shove=true}` — mesma lane, mesmo telegrafo do dash | `resolveDash`, branch `shove` no hit: bloqueio frontal idêntico ("BLOQUEADO pelo escudo"); senão empurra a jogadora até 2 células na direção, parando no primeiro não-free; zero células livres → 1 de dano ("prensa contra a cortina"). Beltran anda a lane normalmente, terminando onde a jogadora estava |

Contratos novos:

- **`role.boss`** — string da mecânica; `Battle:bossPlan(e)` despacha e
  devolver `nil` cai no plano da família.
- **`def.crates = {{x,y},...}`** — `Battle.new` planta `piece='crate'`,
  `cell.crate=true`, `cell.hits=0` em células floor livres e guarda refs
  em `self.crates` (ordem do def, atualizada quando a crate desliza).
  Crates bloqueiam `free()`, raios e a BFS como qualquer peça;
  `adjacentPillar` segue filtrando `piece=='pillar'` — crates nunca abrem
  a opção PILAR nem viram alvo do martelo.
- **`def.channels = {rows={...}, cols={...}}`** — redesenha as bandas do
  jato por encontro; default `Battle.channels = {rows={7}, cols={4,10}}`
  (a arena padrão tem floor em x=2..12, y=5..9).
- **`Battle.hammerReach = 4`, `Battle.pushReach = 4`** — alcances do
  martelo e da vara, tuneáveis como as demais constantes.
- **`Battle:topplePillar(px,py,dx,dy,campaign)`** — a queda extraída de
  `interact()`: remove a peça, `effect('pillarFall')` com a banda, dano
  `pillarDamage` + reposition em toda unidade na banda (poupados
  excluídos). `interact()` delega com direção = pilar−jogadora.
- **`announce()`** — intents de área (`jet`) não carregam `dx`/`x`: guard
  evita `sign(nil)` e não toca `e.facing`.

Apresentação de caixotes, bandas e intenções está em `render.lua`;
qualidade e legibilidade devem ser conferidas na captura da arena.

Ressalva de escopo: mecânicas vivem no **role**, independentes de
região — os defs B0X-01 do Pátio só precisam declarar `kind` + `units` +
`talk` e, opcionalmente, `crates`/`channels`.

## 13. Contexto de encontro (`def.ctx` / `u.ctx`) e rendição não-letal

O def do encontro aceita `ctx` — o id de contexto de bark que o Pena já
escreveu em `battle_barks.lua` (`guarda`, `manutencao`, `cobrador`,
`duelo`, `canteiro`…). Cada unidade pode sobrescrever com `u.ctx`:
precedência **unidade → def → nenhum**, mesmo desenho do
`convinceNeeded` (D09). `Battle.new` copia para `e.ctx` e todo lookup de
fala passa por `Barks.*(kind, …, e.ctx)` — o contexto sobrepõe
`check`/`acts`/`announce`/`damage`/`convinced`/`spared`/`refuse` quando
define; o que não é sobrescrito cai no conjunto base do kind. A tabela
ctx→encontro mantida no rodapé de `src/battle_barks.lua` é a fonte de
verdade do mapeamento — referenciar, não duplicar.

`contexts[ctx].nonLethal = true` (hoje só `dasher.duelo`, C05-Q01) arma
`Battle:nonLethal(e)`, o guard das rotas letais da jogadora: `shoot()` e
`topplePillar()` (PILAR dela e martelo da Janda). O golpe que zeraria a
vida vira rendição: `health = 1`, `e.spared = true`, `e.intent = nil`,
`e.spareT = 0`, bark `spared` — **nunca** `effect('death')`. Rendido sai
de toda interação como poupado (D11) e o desfecho compartilhado
`Battle:outcome()` — usado por `conclude` e `finishResolve` — só conta
queda de quem não se rendeu nem foi poupado: arena todo-rendida fecha
`'negotiated'`, qualquer queda letal puxa `'won'`.

Rendição usa a despedida visual dos poupados em `render.lua`.

## 14. Ferramenta × armadura frontal (contrato — revisão Vigia)

`Battle:swing` (FERRAMENTA) acerta a célula adjacente mirada com
`toolDamage` integral **sem consultar `role.armor`** — a armadura frontal
do bruto bloqueia a flecha (`shoot` aplica o chip de 1 na face), não o
golpe corpo-a-corpo. É o counter de proximidade pensado para a família
`brute`: a flecha ensina flanco, a ferramenta paga fôlego para furar a
face blindada. Decisão intencional — fica contrato.

## 15. Arquétipos C02–C05: plans reais por kind (implementado)

Oito kinds das fichas ganham `plan` e flags próprios em `ROLES`
(src/battle.lua). Todos passam pelo mesmo ciclo: `announce()` congela a
intenção, `endTurn()` monta `resolveQueue` na ordem estável, `resolveStep`
despacha por `intent.kind`, `intentCells` telegrafa exatamente o que a
resolução toca. Unidade `mercy` anuncia `hold` antes de qualquer plan;
`spared` está fora de tudo — nenhum arquétipo duplica esses guards.

| Kind | Role | Intent | Whiff / contrajogo | ACT |
| --- | --- | --- | --- | --- |
| `demolisher` C02-02 | `plan='demolish'` hp 8 | `dash` com `breaks=true` — gatilho do bruto, mas `rayClear`/`ray` atravessam peça **comestível** (pillar/crate); parede e portal seguem barrando | quem sai da lane vê a carga passar; a cobertura na rota cai junto ("rompe a cobertura", uma vez por resolução) | social normal (`saida` segue proposal travada) |
| `breaker` C03-02 | `demolish` + `armor` hp 10 | idem — variante pesada: mais vida, face blindada (chip 1 frontal) | flanqueie; o escudo frontal dela não impede a própria investida | idem |
| `watcher` C03-01 | `plan='watch'` hp 5 | `e.candle` → planSentinel; sem vela → `hold` eterno | matar a vela anula a sentinela inteira | `vela` (LIVE): apaga a vela + suspende o intent na hora; custa ação; negocia depois (`negotiates`) |
| `regent` C04-01 | `plan='ritual'` hp 10 | `e.ritual` +1 por anúncio: 1-2 → `ritual{row,col}` ("reza — a área se fecha"), 3 → `burst{row,col}` | `burst` = `Battle.burstDamage` (3) em TODA unidade na cruz exceto ela; hazard sem escudo; `e.ritual=0` ao estourar, ao levar dano (`hurt`) e ao canto | `despedida` (LIVE): `ritual=0` + `convince+1` normal; `tregua` segue o fluxo |
| `warden` C04-02 | `brute` + `armor` + `fury` hp 12 | dash/move/hold do bruto | cada dano recebido (`hurt`) soma `e.fury`; `endTurn` enfileira `1+fury` steps **da mesma intent** na posição dele — avisos aceleram = mais execuções. **Teto `Battle.furyMax = 3`** (Vigia): sem cap, golpes tardios travariam a fila; 4 execuções no máximo por rodada | `ordem` segue proposal travada |
| `sower` C04-Q01 | `plan='sow'` hp 6 | `sow{row}` ou `sow{col}`: a banda da jogadora (prefere row), nunca a dele, nunca faixa cheia; senão move/hold | ao resolver, células floor da banda viram `self.hazards['x:y']` persistentes; `thornTick` no `finishResolve` cobra `Battle.thornDamage` (1) de quem TERMINA na faixa — jogadora e aliados, sem escudo; ele não se exime | social normal |
| `husk` C05-01 | `plan='husk'` hp 3 | `e.hatch` -1 por anúncio (nasce 3); ≤0 → eclode e despacha planCrawler na mesma chamada; senão `hold` | qualquer dano sobrevivido (`hurt`) eclode na hora — hp vira 4/4 crawler; golpe letal mata o casulo sem eclodir | `embalar` (LIVE): `hatch=min(3,hatch+1)`; funciona apesar de `negotiates=false` — gesto, não conversa |
| `veteran` C05-02 | `sentinel` + `double` hp 8 | `shoot`/`move`/`hold` da sentinela | `role.double` + intent `shoot` → 2 steps na fila: a 1ª flecha gasta o escudo, a 2ª acerta | social normal |

Contratos novos:

- **`self.hazards`** — mapa `'x:y'→true` criado em `Battle.new`; o renderer
  lê para tingir as células de espinho. Espinho não bloqueia `free()` nem
  raios: é pedágio de posição, não obstáculo.
- **`intent.breaks`** — dash que atravessa peça comestível. `ray` e
  `rayClear` ganharam parâmetro `throughPieces` (atravessa só
  `piece=='pillar'|'crate'`); `resolveDash` remove `piece`/`crate` das
  células percorridas e só para em unidade ocupada — telegrafo e
  resultado concordam célula a célula. Demolidor provocado também
  carrega `breaks` (`provokedPlan`).
- **`role.fury` / `e.fury`** — dano recebido acumula, **limitado por
  `Battle.furyMax = 3`**: `endTurn` enfileira no máximo `1+furyMax`
  execuções consecutivas da mesma intent, mesmo `i` de ordem. O teto é
  decisão de legibilidade, não desvio de ficha — "avisos aceleram" não
  significa "avisos ocupam o turno".
- **`role.double`** — `shoot` anunciado enfileira 2 execuções; o gasto do
  escudo na 1ª é o desenho da veterana.
- **`Battle:hurt(e)`** — ponto único de efeitos colaterais de dano a
  unidade (chamado depois da subtração, antes dos desfechos): zera
  `e.ritual`, soma `e.fury`, eclode husk sobrevivente. Ligado em `shoot`,
  `swing`, `topplePillar`, `resolveJet`, `resolveBurst` e `thornTick`.
- **`Battle:hatch(e)`** — transformação única casulo→crawler (kind, role,
  nome, hp 4/4) usada pela contagem e pelo golpe.
- **`e.candle` / `e.hatch` / `e.ritual`** — nascem em `makeUnit`
  (watcher→vela acesa, husk→contagem 3) e sobem como estado de unidade.
- **`LIVE_ACT`** — `{kind={actId=true}}`: só essas proposals saem do
  cadeado em `actItems`; `actOn` trata o ramo ANTES de recusa/negotiates
  (gesto mecânico, não fala) e custa a ação. Demais `proposal=true`
  seguem desabilitadas, inclusive em chamada direta.
- **`Battle.burstDamage = 3`, `Battle.thornDamage = 1`** — tuneáveis como
  as demais constantes.
- Intents de faixa (`sow`) e de cruz (`ritual`/`burst`) não carregam
  `dx`/`x`: o guard de facing do `announce` já as cobre; bark de
  announce segue a voz padrão do kind.

Apresentação de caixotes, bandas e intenções está em `render.lua`;
qualidade e legibilidade devem ser conferidas na captura da arena.

Ressalva de design: o gatilho do `planDemolish` difere do bruto num ponto
— o `rayClear` ignora peças comestíveis, porque "atravessar a cobertura"
é a identidade do arquétipo (sem isso, `breaks` seria código morto: a
peça bloquearia o anúncio). A lane telegrafada mostra a rota inteira,
peças inclusas — fogo honesto mantido.

Na mesma revisão:

- `Battle:interact` (rota legada de pilar, alcançável por ganchos) passou
  a cobrar `Battle.staminaTool` como o swing e grava
  `lastAction = 'tool'` — golpe físico nunca sai de graça e a rodada é
  lida como física (sem beat de regen no `endTurn`).
- `Battle.staminaMax` (1.6) é a constante única do fôlego cheio — lida
  por `makePlayer` da campanha e pela entrada da arena (`Battle.new`).
  O clamp de regen segue `guard.max`.


## 16. Inventário, equipamento, fôlego e recompensas — implementado

- `data.items` guarda quantidades; `data.equipped` guarda slots. O catálogo
  distingue consumíveis, equipamento e chaves. A bolsa abre pela pausa;
  provisão cura em exploração ou em batalha. Posse e equipamento persistem.
- ATACAR exige arco; `casaco` cobre saves anteriores à concessão do item.
  FERRAMENTA exige equipamento e fôlego, mira célula adjacente, causa dano,
  interage com pilar e empurra caixote se o destino está livre. Errar também
  consome a ação e o fôlego. DEFENDER cobra fôlego; ações não físicas
  regeneram conforme constantes. Fôlego persiste entre encontros.
- USAR apresenta consumíveis disponíveis e custa uma ação confirmada. Itens
  de missão não são descartados nem dependem de o dono continuar vivo.
- ACTs de recibo, desvio/conjunto e rota/função consultam respectivamente
  `reciboEma`, `esquemaCanal` e `laudo`; falta de item aparece com motivo e
  não gasta ação. Os emissores são interações, conversas, pickups e encontros.
- `def.loot`/`def.parleyLoot` concedem ouro, XP e itens uma vez na resolução.
  Sem `parleyLoot`, negociação recebe `loot` integral; fuga/derrota não pagam.
  Resultado e recompensa entram no mesmo checkpoint.

## 17. Limites e pendências

Munição limitada só é candidata se os encontros mostrarem necessidade; flechas
continuam livres. Não há mana nova, crafting ou loja dentro da arena. Cartas
não viram habilidades sem decisão sobre sua função. ACTs com `proposal=true` fora de `LIVE_ACT`
continuam desabilitados até sua mecânica existir; poupar por dano segue adiado.
Equipamento e recompensas precisam de emissores coerentes por região, sem
transformar o inventário numa nova condição oculta para concluir a história.

## 18. Verificação comum

Prévia e resultado concordam sobre célula, cobertura, ordem e área; aviso não
amplia após a decisão. Pausa, diálogo, inventário e perda de foco congelam
resolução. Retomar não reaplica ataque. Negociação, vitória, retirada e morte
têm resultados próprios; recompensa nunca duplica. Use `--test` e `--ui-test`
conforme [tests/README.md](../tests/README.md); leitura visual continua manual.
