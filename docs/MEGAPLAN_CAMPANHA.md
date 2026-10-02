# Arrowfallen — Megaplan da campanha: A Cidade Que Me Enterrou

Status: planejado e aprovado pelo usuário em 02/10/2026. **Etapa 1 em
produção**: fundação implementada — `save.lua` (save versionado em disco),
`region.lua` + `regions/{colina,hub}.lua` (mapas autorais), `explore.lua`
(movimento contínuo), `campaign.lua` + `campaign_lore.lua` (sessão, NPCs,
diálogos, hotspots), `props.lua`, `battle.lua` (arena separada, só plumbing)
e a suíte `tests/explore_campaign.lua` (102 asserções). Resta da etapa 1: a
primeira Sentinela já entra/sai de arena; intenções e turnos são etapa 2.
As etapas 1–5 (o recorte Colina → hub → Oficinas → retorno)
estão detalhadas; as etapas 6–12 são macroetapas a detalhar ao abrir.

Objetivo: transformar o protótipo de três andares em tempo real na campanha
narrativa "A Cidade Que Me Enterrou" — hub recorrente, dez regiões,
exploração em movimento livre, arena de grid por turnos nos encontros e
estado de campanha persistente com save em disco.

Este documento consolida decisões de implementação aprovadas na conversa de
produção. Propostas coordenadas do pacote de lore (nomes, cronologia,
catástrofe) continuam revisáveis criativamente; o que está aqui é a versão
coerente usada para implementar. A distinção decisão/proposta dos demais
documentos é preservada.

## 1. Mapa dos documentos

Todo documento do pacote tem um papel na produção. Nada é decorativo.

| Documento | Papel na produção |
| --- | --- |
| [CONTEXTO_REIMAGINACAO.md](CONTEXTO_REIMAGINACAO.md) | Fonte das decisões do usuário; separa escolha aprovada de proposta revisável |
| [BASE_NARRATIVA.md](BASE_NARRATIVA.md) | Contrato de continuidade: elenco e responsabilidades, regra do selo, duas versões falsas, dependências entre mapas, ritmo de combate |
| [PLANO_CAMPANHA.md](PLANO_CAMPANHA.md) | Índice das dez regiões e do fio narrativo; base da ordem das macroetapas |
| [HUB_INICIAL.md](HUB_INICIAL.md) | Spec do refúgio: planta por zonas, primeira visita H-E01–E04, retornos H-R01–R04, evolução por marco, acolhimento e selos |
| [CENAS_REVELACAO_E_FINAIS.md](CENAS_REVELACAO_E_FINAIS.md) | Roteiro de R08, H08, R09, R10, a escolha explícita e os dois epílogos (F-C01–03, F-I01–03) |
| [COMBATE_PROPOSTA.md](COMBATE_PROPOSTA.md) | Spec da arena de turnos — aprovada como base do protótipo; valores seguem abertos |
| [GUIA_ESCRITA_DEVIN.md](GUIA_ESCRITA_DEVIN.md) | Obrigatório antes de escrever qualquer texto ao jogador; ficha de personagem de 12 campos e revisão em 6 passos |
| [GUIA_STORYTELLING_UNDERTALE.md](GUIA_STORYTELLING_UNDERTALE.md) | Princípios de distribuição da história entre canais e da lista do que não copiar |
| [A_CIDADE_QUE_ME_ENTERROU.md](A_CIDADE_QUE_ME_ENTERROU.md) | Tratamento literário e tom; nomes das fichas prevalecem sobre seus títulos de trabalho |
| [mapas/FICHA_MAPA.md](mapas/FICHA_MAPA.md) + fichas 01–10 | Contrato por região: identidade, etapas `P0X-EYY`, encontros `C0X`/`B0X`, duas subquests, paleta, checklist de revisão |
| [TERRAIN_PLAN.md](TERRAIN_PLAN.md) | Gramática de terreno preservada: paredes, pilares, buracos e rachaduras viram interação da arena e atalhos da exploração |
| [MEGAPLAN_PIXEL_ART.md](MEGAPLAN_PIXEL_ART.md), [PIXEL_ART_MILESTONE.md](PIXEL_ART_MILESTONE.md), [PLANO_REFINAMENTO_PIXEL_ART.md](PLANO_REFINAMENTO_PIXEL_ART.md) | Direção visual aprovada: 32 px/célula, sprites geradas por código, anim8; o refinamento segue como frente paralela |
| [DESIGN.md](DESIGN.md), [ROADMAP.md](ROADMAP.md), [LIBRARIES.md](LIBRARIES.md) | Contrato atual; atualizar quando o código mudar |
| [MEGAPLAN_LORE.md](MEGAPLAN_LORE.md), [HISTORIA_NOVA.md](HISTORIA_NOVA.md) | Material histórico/supersedido; lore das Ruínas dos Ecos permanece apenas no modo interno; Beltran e Nilo migraram da proposta anterior com papéis adaptados |
| [tests/README.md](../tests/README.md), [AGENTS.md](../AGENTS.md) | Convenções de checks e screenshots em `screenshots/` |

## 2. Decisões aprovadas nesta sessão

| Elemento | Decisão |
| --- | --- |
| História | "A Cidade Que Me Enterrou" é a campanha; `HISTORIA_NOVA.md` está descartada |
| Exploração | Movimento **contínuo em pixels** com colisão por caixas, estilo Undertale; o passo por célula volta a existir somente dentro da arena |
| Combate | Turnos conforme `COMBATE_PROPOSTA.md`: intenções anunciadas em ordem estável, mover até 2 células + 1 ação, sem cronômetro; conversa é ação contextual |
| Modo atual | A campanha substitui a expedição no título; o código de prática/expedição permanece no repositório como material interno de teste, sem entrada no menu |
| Persistência | **Save em disco desde o primeiro recorte** (`love.filesystem`); morte devolve à sepultura/hub conservando o estado da campanha |
| Mapas | **Todos autorais.** As fichas dizem "o gerador varia os trechos intermediários"; esta decisão substitui isso — os trechos intermediários também são desenhados. O gerador atual fica restrito ao modo interno |
| Testes | Suítes separadas: combate (`tests/battle.lua`), exploração (`tests/explore.lua`) e outras conforme a necessidade (save, hub, diálogo de campanha); a suíte atual segue verde enquanto o modo interno existir |
| Nomes | Usar os nomes propostos nas fichas (Lia, Aurel, Doro, Runa, Janda, Brina, Neco, Rima, Edras, Lena, Calo, Rute, Ema, Ivo, Mara, Beltran, Cira, Dalva, Geraldo, Joana, Silvério...); revisão criativa continua aberta |
| Escrita | `GUIA_ESCRITA_DEVIN.md` obrigatório para todo texto ao jogador |
| Pontos abertos | Nome do protagonista e do hub, natureza final da catástrofe, função mecânica das cartas, valores de combate/economia — marcados como abertos onde aparecerem |

## 3. O que muda no jogo atual

| Hoje | Campanha |
| --- | --- |
| Três andares procedurais por tentativa | Dez regiões autorais + hub, persistentes |
| Movimento em saltos de célula | Exploração contínua em pixels; grid só na arena |
| Combate em tempo real com timers | Arena de turnos com intenções anunciadas |
| Morte reinicia a tentativa | Morte devolve à sepultura; campanha conserva tudo |
| Estado em `Game` por expedição | `Campaign` persistente serializada em disco |
| NPCs de loja/refúgio (Amâncio, Odete) | ~28 personagens com voz, desejo e conhecimento próprios |
| Lore das Ruínas dos Ecos | "A Cidade Que Me Enterrou"; lore antiga só no modo interno |
| Diálogo linear + loja | Diálogo condicionado por estado de campanha e memória por personagem |
| Chefes de andar com intro | Adversários com acordo, rendição e consequências distintas |

## 4. Arquitetura

### 4.1 Modos e cenas

`main.lua` passa a abrir na campanha. Três cenas compartilham um estado de
campanha único:

- **Explore** — mapa autoral, movimento contínuo, interações com E,
  diálogos, gatilhos visíveis de encontro. O hub é um mapa comum com a casa
  das passagens selecionando destinos.
- **Battle** — arena separada no grid; entrada captura ponto e estado do
  mapa; a saída devolve o protagonista ao lugar com o resultado persistido.
- **Título/pausa/guia/diálogo** — congelam ambas as cenas; nenhuma intenção
  ou resolução avança sob menu, e ações antigas não reaplicam ao fechar.

O `Game` atual continua instanciável para testes e cenas de screenshot, sem
entrada no título.

### 4.2 Módulos novos (nomes de trabalho)

| Módulo | Responsabilidade |
| --- | --- |
| `src/campaign.lua` | Estado persistente: etapas `P0X-EYY` por região, resultados de `C0X`/`B0X`, acessos e objetos alterados, conhecimento/compromissos/quests/localização/selo por personagem, melhorias do hub, flags do final |
| `src/save.lua` | Serialização versionada para o diretório de save; grava em pontos definidos (retorno ao hub, etapa concluída, antes do ato final); leitura falha não destrói save anterior |
| `src/region.lua` + `src/regions/*.lua` | Carregador e dados de mapas autorais: grade de células, props com caixas de colisão, pontos de interação, gatilhos de encontro, saídas, NPCs posicionados. Dados, não framework de quests |
| `src/explore.lua` | Movimento contínuo do protagonista: posição em unidades lógicas, velocidade, caixa de colisão contra células sólidas e props; `Input` já entrega `dx/dy` contínuos |
| `src/battle.lua` | Rodada da arena: intenções → turno do jogador (≤2 células + 1 ação) → resolução ordenada → próxima rodada; congelamento total em UI |

### 4.3 Reuso

- Consultas de célula (`Rooms.cell`, `floor`, `blocksAttack`, `line`) para a
  arena; gramática de terreno de `TERRAIN_PLAN.md` para interações
  (rachaduras, quedas anunciadas, atalhos mineráveis previstos nas fichas).
- Papéis de `enemies.lua` viram intenções por rodada, não timers:
  crawler → Rastejante, ranger → Sentinela, dasher → Bruto; Semeador e
  Vigia entram depois do recorte validar dois papéis.
- `dialogue.lua` como base da máquina, estendida com condições
  (`when(state)`), memória por personagem e variantes de continuidade; sem
  criar motor de roteiro nem framework de quests.
- `render.lua`, `pixel_world.lua`, `pixel_actors.lua`, `pixel_font.lua`,
  `feedback.lua`, `music.lua` para apresentação e transições; cenas de
  `main.lua` como padrão de verificação visual.

### 4.4 Estado persistente

Modelo de `GUIA_IMPLEMENTACAO_DEVIN.md` §4, expandido pelas fichas:

- **Região:** etapas concluídas, encontros resolvidos (vitória, acordo,
  rendição, letal), acessos e objetos alterados, retiradas pendentes.
- **Personagem:** o que sabe, o que prometeu/recebeu, estado da quest
  (aceita, recusada, etapas), localização, selo, vida.
- **Hub:** entregas únicas, instalações, moradores presentes, estado pós-
  revelação.
- **Final:** preparações concluídas; só confirmação explícita do ato
  encerra a campanha.

Regras invioláveis: recusa de quest permanece recusa; encontro concluído
nunca repete; arena pendente reinicia combatentes sem duplicar saque; morte
não apaga provas, reparos nem promessas; selo acompanha a pessoa, não a
coordenada; visitar o hub não concede selo.

### 4.5 Formato de mapa autoral

Cada região é um arquivo de dados com: grade de células (piso, paredes,
pilares, buracos conforme `TERRAIN_PLAN`), lista de props (colisão,
interação, estado), pontos de interação com E, NPCs posicionados, gatilhos
de encontro com arena associada, saídas/passagens e paleta da ficha. Os
"lugares garantidos" das fichas são âncoras obrigatórias; os trechos entre
eles são desenhados, não gerados. Placeholders identificados são aceitos
para props novos até a etapa de arte (ficha 06 o prevê).

### 4.6 Fora do recorte

Aliados jogáveis, crafting, fome, produção automática, iluminação dinâmica,
função mecânica das cartas, fogo amigo contra civis e mortes aleatórias de
NPCs. Nada disso entra nas etapas 1–5.

## 5. Regras invariantes consolidadas

Extraídas de todos os documentos; qualquer etapa que as viole está errada:

1. Informação essencial nunca depende de segredo, sorteio, subquest ou da
   sobrevivência de uma testemunha — toda pista crítica tem fonte garantida.
2. Sem pontuação universal de bondade/moral; consequências são concretas.
3. Derrota ≠ morte; rendição, acordo e letal são estados distintos.
4. Vencer Aurel não escolhe o final; só o ato confirmado decide.
5. Lia não aparece presencialmente nem ao vivo nos mapas 1–9; prova recente
   garantida no mapa 9.
6. Diálogo, inventário, pausa e perda de foco congelam a resolução; nada
   ataca por baixo de menu nem reaplica ação antiga ao fechar.
7. Sem terceiro final secreto; custos das duas escolhas exibidos antes de
   confirmar, com opção de cancelar.
8. Pares 2/3, 4/5 e 7/8 admitem qualquer ordem; retorno após 8 provoca
   responsabilização mesmo com 7 pendente.
9. Moradores não são igualmente culpados; NPCs mortos não ganham falas de
   substitutos; encontro concluído não vira gatilho novo para manter conta.
10. NPCs do hub não são atacáveis; civis nunca entram na arena.

## 6. Etapas do recorte (detalhadas)

### Etapa 1 — Fundação da campanha

`Campaign` + `Save` (gravar, carregar, estado após morte), `Explore` com
movimento contínuo e colisão por caixas, carregador de mapa autoral, mapa da
Colina navegável (sepultura, pátio, depósito funerário, grade, chegada),
hub navegável com as sete zonas de `HUB_INICIAL.md`, transição
exploração ↔ arena vazia, morte devolvendo à sepultura. Sem combate ainda.

**Checks:** movimento livre e colisão; save/load sobrevive a fechar o jogo;
morte conserva estado; cada lugar garantido da ficha 01 existe.

### Etapa 2 — Arena de turnos

`Battle` num grid reutilizando sala: intenções anunciadas com ordem estável,
mover ≤2 células + uma ação (arco, defender, item de cura, esperar),
resolução em sequência legível, uma Sentinela como encontro de apresentação,
saída por vitória ou retirada, congelamento total em diálogo/menus/pausa/
foco. Segue a sequência de `COMBATE_PROPOSTA.md` §10, passos 1–3 (inclui
uma interação de pilar com prévia coerente).

**Checks:** `tests/battle.lua` — intenções visíveis e estáveis, prévia de
alcance, resolução ordenada, retirada persistente, nenhum timer, freeze
absoluto.

### Etapa 3 — Colina completa

P01-E01–E06 da ficha 01: despertar com Doro, pertences e casaco com remendo
de Lia, Runa com resolução negociada ou física (C01-01), entrada no hub com
H-E01–E04 (comida de Bento, espaço de Teca, desejos no pátio, Aurel e
destinos 2/3), baú e descanso, morte → sepultura com comentário curto de
Doro. Retrato/sprite de Doro e Runa funcionais.

**Checks:** `tests/explore.lua` — etapas na ordem, revisita sem repetição,
pertences não recolhem duas vezes, destinos 2 e 3 disponíveis após P01-E05.

### Etapa 4 — Oficinas

Ficha 02: mapa autoral completo (entrada, bancada de Brina, alojamento,
saída danificada, depósito, oficina central), lembrança da fivela de uma
mão, preparação da saída, Janda na arena (B02-01) com negociação por
inspeção real do reparo, dois encontros comuns (C02-01/02) reaproveitando papéis,
entrega das ferramentas → bancada funcional no hub e rota do mapa 4
indicada. Início das subquests de Brina e Neco.

**Checks:** acordo e vitória liberam o conjunto; retirada preserva reparos;
Janda reconhece inspeção; entrega única sem duplicar recompensa.

### Etapa 5 — Consistência e escrita do recorte

Revisão editorial por `GUIA_ESCRITA_DEVIN.md` — fichas de voz de Doro, Runa,
Teca, Bento, Aurel, Brina, Neco e Janda; variantes de confissão antecipada;
PT-BR natural e caixa de texto. Suítes `tests/explore.lua` +
`tests/battle.lua` + save/persistência consolidadas. Checklist de
`GUIA_IMPLEMENTACAO_DEVIN.md` §5 item a item. Screenshots em
`screenshots/`. Atualização de README, DESIGN e ROADMAP.

## 7. Macroetapas seguintes

Detalhadas ao abrir, seguindo a ordem de dependências da `BASE_NARRATIVA`:

| Etapa | Região | Conteúdo-chave | Abre |
| --- | --- | --- | --- |
| 6 | Mercado das Escoras (3) | Rute/Ema, peças do forno → cozinha do hub; encomenda de Brina (etapa 2 da subquest) | 5 |
| 7 | Reservatório (4) + Salões (5) | Ivo/Mara e água; Beltran/Cira, divisórias e apresentação; arcos de Sabela, Teca, Nilo | 6 (4+5) |
| 8 | Quartos da Fundação (6) | Dalva/Geraldo, quarto do casal, contradição da partida falsificada, escola no hub | 7 e 8 |
| 9 | Armazéns (7) + Necrópole (8) | Joana/Silvério e a despedida; Rima/Edras, R08 prova do crime, H08 responsabilização nas duas ordens | 9 (7+8) |
| 10 | Fronteira da Volta (9) | Lena/Calo, prova recente de Lia em Ponta Clara, montagem da passagem, teste do limite | 10 |
| 11 | Túmulo Primeiro (10) | Aurel (C10-01), revisão de custos, escolha explícita, epílogos F-C/F-I completos | fim |
| 12 | Arte e polimento | Etapas 4–5 de `MEGAPLAN_PIXEL_ART` + `PLANO_REFINAMENTO` aplicados ao elenco e às regiões; cartas (função a definir); balanceamento; áudio; empacotamento | — |

Cada macroetapa recebe sua própria subdivisão quando aberta, seguindo a
ficha correspondente — nunca produzir dez mapas antes de validar o recorte.

## 8. Arte e apresentação

A direção visual já está aprovada em `MEGAPLAN_PIXEL_ART.md` e refinada por
`PLANO_REFINAMENTO_PIXEL_ART.md`: 32 px/célula, ampliação inteira, sprites
desenhados por código e gerados em memória, anim8 para reprodução.

- **No recorte (etapas 1–5):** sprites funcionais e identificáveis de Doro,
  Runa, Teca, Bento, Sabela, Nilo, Aurel, Janda, Brina e Neco; props novos
  das fichas 01–02 com forma própria ou placeholder identificado; paletas
  das fichas; indicação contextual de interação.
- **Na arena:** intenções usam a linguagem de perigos existente (contornos
  por célula, forma além de cor, ordem de resolução numerada), conforme
  `COMBATE_PROPOSTA.md` §9.
- **Macroetapa 12:** o acabamento completo (etapas 4–5 do megaplan de pixel
  art e o refinamento aprovado) expande o padrão ao elenco e aos dez mapas.

Nenhuma etapa de gameplay espera a arte final; nenhuma arte decide regra.

## 9. Verificação

- `& 'C:\Program Files\LOVE\lovec.exe' . --test` e `--ui-test` verdes; a
  suíte existente continua cobrindo o modo interno; as suítes novas
  (`battle`, `explore`, save) cobrem a campanha.
- Checklist de `GUIA_IMPLEMENTACAO_DEVIN.md` §5 executado ao fim do
  recorte: movimento/colisão, interação, transição de arena, prévia de
  intenções, negociação, retorno, persistência, sem duplicar recompensa,
  morte correta, ordens 2/3 e 4/5 e 7/8, custos do final.
- Capturas sempre em `screenshots/` com `--screenshot=screenshots/nome.png`
  a partir da raiz (AGENTS.md); cenas `--scene=` novas para Colina, hub,
  arena e Oficinas.
- Revisão narrativa por ficha: ordens livres, confissão antecipada, NPC
  ausente/morto, recusa de quests, retirada e revisita pós-revelação.

## 10. Riscos

- **Movimento contínuo** é a maior mudança técnica. A etapa 1 decide a
  colisão (caixas de ator contra células/props); se a leitura ficar ruim no
  protótipo, o fallback documentado é passo por célula na exploração —
  decisão a revisar com o usuário, não silenciosa.
- **Escopo de escrita:** ~28 vozes únicas é o trabalho mais pesado. A
  escrita acompanha a etapa de cada região, nunca um bloco separado no fim.
- **Save cedo:** formato versionado desde o primeiro write; campos novos
  têm default para não invalidar saves entre etapas.
- **Dois jogos no mesmo código:** o modo interno existe para testes; nenhum
  ajuste de campanha deve exigir mudar suas regras, e vice-versa.
- **Drift narrativo:** propostas coordenadas não são aprovação criativa
  final; revisões do usuário continuam possíveis a cada etapa.

## 11. Prompt para continuar

```text
Implemente a próxima etapa de docs/MEGAPLAN_CAMPANHA.md no Arrowfallen.

Leia o megaplan inteiro, AGENTS.md, GUIA_IMPLEMENTACAO_DEVIN.md,
BASE_NARRATIVA.md, COMBATE_PROPOSTA.md, a ficha da região em produção e
GUIA_ESCRITA_DEVIN.md antes de qualquer texto ao jogador. As decisões do
megaplan estão aprovadas; nomes e lore seguem as fichas.

Comece pela etapa 1: fundação da campanha — estado persistente, save em
disco, exploração com movimento contínuo e mapas autorais da Colina e do
hub. Depois a arena de turnos com uma Sentinela, e só então Janda. Não
produza os dez mapas nem todos os inimigos antes de validar o recorte.

A simulação e o save são autoridade; a apresentação converte. Diálogo,
menus e pausa congelam tudo; nenhuma recompensa duplica; morte devolve à
sepultura conservando a campanha. Não crie framework de quests nem medidor
moral. Texto em PT-BR natural com voz única por personagem.

Execute os checks (--test, --ui-test) e as suítes novas da etapa, registre
capturas em screenshots/ com --screenshot=screenshots/nome.png a partir da
raiz e entregue resumo de arquivos, verificações e etapas restantes.
```
