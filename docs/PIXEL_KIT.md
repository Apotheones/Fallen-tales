# Pixel Kit — autoria procedural para Arrowfallen

Plano completo de evolução: [MEGAPLAN_KIT_PROCEDURAL_IA.md](MEGAPLAN_KIT_PROCEDURAL_IA.md).

`src/pixel_kit.lua` trabalha em Lua puro e entrega camadas para o
`src/sprite_dsl.lua`. O bake existente produz albedo, normal e emissivo
compatíveis com o render do jogo. Não altera os sprites carregados pelo jogo.

## Executar e verificar

Na raiz do projeto, em PowerShell:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' tools/pixel_kit --screenshot=screenshots/pixel-kit.png
```

Roda checks de geometria, máscaras, transformações, diagnósticos e bake;
exporta os três canais em `screenshots/pixel-kit-lantern_*.png` e captura
o painel com tamanho real, ampliação nearest, normal e emissão.
Sem `--screenshot`, o painel fica aberto; Escape fecha. `--test` verifica e sai.

## Runner scriptável (`tools/kit_run`, W0)

```powershell
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_run --check
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_run --verify
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_run --bake=bau
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_run --revise
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_run --baseline
```

- `--check`: checks executáveis compactos de todo o kit (W0/W1 + selfCheck do DSL).
- `--verify`: mesma receita+seed produz pixels idênticos em defs distintas;
  def nova = bake novo (cache por identidade, sem artefato obsoleto).
- `--bake=<nome>`: assa um asset de `src/sprites` e exporta
  `screenshots/<nome>_{albedo,normal,emissive}.png`.
- `--revise`: piloto W1 — revisa uma região do baú real com máscaras de
  proteção; exporta `screenshots/kit-pilot-bau_{orig,cand}_*.png` e
  `kit-pilot-bau_diff.png`.
- `--baseline`: tempo de bake, dimensões de sheet, memória retida e custo
  de render de todos os assets → `screenshots/kit-baseline.txt`, com avisos
  quando dimensões/frames/tamanho passam dos limites do lote.

Exit codes: `0` ok · `1` falha de check · `2` erro de autoria (def/brief/
argumento) · `3` erro de bake · `4` erro de export/render · `5` uso
inválido. Erros de runtime caem em `screenshots/kit-run-error.txt`.
Toda saída de arquivo fica em `screenshots/`. Receitas Lua são código
confiável do repositório — o runner não é sandbox de scripts de terceiros.

## Bancada de revisão (tools/kit_workbench)

Render estático de qualquer def para revisão por agente, sem abrir o jogo.
Controle só por CLI/script (tabela `job` em `workbench.lua`); saída
previsível em `screenshots/wb-<asset>-<view>-z<N>.png` + relatório
greppável `wb-<asset>-report.txt` (INFO/WARN/ERROR com frame, coordenada
1-based, região e motivo). Exit: 0 ok, 1 erro, 2 warnings com `--strict`.

```powershell
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_workbench --asset=lampiao --views=grid,channels,swatches,lit --light=16,20,48,140 --bg=game --ambient=refugio
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_workbench --asset=lampiao --vs=build/candidato.lua --views=ab,diff --crop=36,48,16,14
& 'C:\Program Files\LOVE\lovec.exe' tools/kit_workbench --test   # self-check
```

`--asset` aceita nome em `src.sprites` ou caminho `.lua` que devolve def.
Views: `albedo normal emissive luminance silhouette channels grid crop
swatches tile lit ab diff blink frames onion dump` (default
`albedo,channels,grid,swatches`). `--frame=N|all`, `--zoom` inteiro,
fundos `checker|neutral|dark|ambient:<região>|game[:<piso>]|
shot:<arq.png>[@x,y]` (`shot` usa uma captura de cena real como
backdrop); `--tile` repete NxN com variantes por seed; `lit` usa o
lighting real do jogo com `--light=x,y[,z[,raio[,int]]]` repetível;
`grid` desenha grade+régua+origem+âncoras (`def.anchors` ou
`--mark=nome@x,y`)+regiões (`def.regions`/`--region`)+máscara
(`def.masks`/`--mask`)+bbox. `blink` grava o par A/B com enquadramento
idêntico para alternar entre arquivos; `frames` é o strip com
grade+bbox por quadro; `onion` mostra o frame atual com fantasmas do
anterior (vermelho) e do próximo (azul), wrap de loop. `--play`
(`--fps=N`) abre playback interativo — pausa, passo e velocidade —
para revisão humana; as capturas continuam sendo a evidência para
agentes. A def comparada precisa ser tabela NOVA — o bake memoiza por
identidade.

Revisão animada (apoio W4): `seq` captura os frames de `--seq=i1,i2,nome`
(índices ou `def.sequences` nomeadas) com tempo acumulado; `instances`
(`--instances=N --phase=K`) repete o ator em fases para expor loops
idênticos; `loop` isola a costura último→primeiro; `tracks` desenha os
rastros de `def.anchors` por frame com marcas de `def.markers`
(prep/contact/react/recover/return). O relatório mede salto de âncora
(>4px), deriva em contato, flicker por transição e a % da costura do
loop. `def.frameDuration` (s, escalar ou array) alimenta `seq` e
`--play`.

## Contrato de desenho

- Coordenadas inteiras **1-based**; `.` significa transparente.
- Cada cor é um caractere de um byte, definido na `legend` do SpriteDSL.
- Desenho fora da grade é recortado; dimensões e coordenadas inválidas dão erro.
- Máscaras são grades: qualquer caractere diferente de `.` permite pintar.
- Operações de desenho modificam a grade; `clone` e `flip` retornam outra grade.
- `blit(destino, origem, dx, dy, mascara)` usa deslocamentos, não posição absoluta.
- `outline` acrescenta borda externa de um pixel, sem diagonais; reserve margem.
- `paint` recolore pixels existentes com callback `(x,y,cor)`; nil preserva a cor.
- `layer` devolve uma camada nova; após editar, crie uma definição nova antes do
  bake, porque o SpriteDSL usa cache por identidade da definição.

### Contratos do pipeline (W0)

- **Coordenadas**: autoria em inteiros 1-based em todas as grades do kit.
  O `ImageData`/`getPixel`/`setPixel` do bake é 0-based — a conversão vive
  só na fronteira do `sprite_dsl` (`px = x0 + x - 1`). Coordenada
  não-inteira ou `NaN` falha na hora.
- **Transparência**: `'.'` e `' '` são vazio em qualquer canal; em grades
  de autoria o canônico é `'.'`. Transparente na origem não apaga o destino
  em `blit`/`stamp`. Em `patch`, `' '` na row pula e `'.'` apaga.
- **Clipping**: escrita fora de `1..w,1..h` é descartada sem erro
  (`pixel`, `rect`, `line`, curvas, `fill`, `outline`…). Erro reservado a
  entrada degenerada: dimensão ≤0, coordenada não-inteira, cor inválida.
- **Máscaras**: grade de mesmas dimensões, `'x'` = ligado. `sel_*` produzem
  máscaras; `mask_*` combinam. Desenho com máscara só escreve onde ela está
  ligada. `mask_not` inverte só dentro da grade (ou de `bounds`). Fora da
  grade conta como fundo na erosão.
- **Canais**: albedo (cores da legend), altura `0..9..f` (0..15), emissivo
  (chars da legend; `.e`/`.ei` da entrada). Composição por camadas é por
  canal independente: o último valor não-vazio vence por canal — a camada
  de cima não apaga altura/emissivo da de baixo.
- **Frames**: canal em array = animação; nº de frames = maior array; todos
  os arrays com o mesmo N; string única replica. Sheet enfileira frames na
  horizontal, sem padding.
- **Origens**: `origin='feet'` (atores/props de chão, default) ou
  `'topleft'` (tiles/retratos); a origem é metadado do sheet — quem desenha
  posiciona. `stamp` recebe pivô explícito (`topleft|center|feet|{px,py}`).
- **Cache**: `DSL.bake` memoiza pela identidade da tabela def (chaves
  fracas). Mesma def = mesmo sheet; editar = montar def nova. Não existe
  invalidação silenciosa — receita modificada precisa de tabela nova.
- **Aleatoriedade**: `K.rng(nome, seed)` (Park-Miller, hash do nome + seed).
  Determinístico, independente de ordem de visita e sem tocar
  `math.random`/`love.math` — o RNG do gameplay fica intocável.
- **Brief**: `K.brief{name,w,h,...}` valida a forma mínima (name/w/h
  obrigatórios; `seed=0`, `regions/anchors/protected={}` defaults; campos
  livres como `role`, `region`, `perspective`, `proportions`, `identity`,
  `materials`, `states`, `timing`, `variation` passam intactos).

```lua
local K = require('src.pixel_kit')
local DSL = require('src.sprite_dsl')
local g = K.new(32,32)
K.ellipse(g,8,6,16,20,'b')
local mask = K.clone(g)
K.rect(g,8,6,5,20,'h',mask)
K.outline(g,'o')
local legend = {b='stone.3',h='stone.5',o='stone.1'}
assert(#K.inspect(g,legend).unknown == 0)
local def = {name='pedra',w=32,h=32,origin='topleft',legend=legend,
    layers={K.layer('pedra',g)}}
local sheet = DSL.bake(def)
-- sheet.albedo/normal/emissive: imagens LÖVE com filtro nearest.
```

Ferramentas: `new`, `get`, `pixel`, `rect`, `line` (Bresenham), `ellipse`,
`polygon` (lista plana x,y), `clone`, `flip`, `blit`, `outline`, `paint`,
`string`, `inspect`, `layer`. Altura usa os caracteres `0..9,a..f` do DSL;
emissivo usa a mesma legend do albedo. `layer(nome,albedo,altura,emissivo)`
aceita canais opcionais com as mesmas dimensões.

### Ferramentas W1 (rasterização e correção local)

Curvas e traçado:

- `qcurve(g,x1,y1,cx,cy,x2,y2,c[,mask])` / `ccurve(...)` — Bézier
  quadrática/cúbica de pixel; amostragem proporcional ao comprimento,
  segmentos ligados por Bresenham. `qpts/cpts(...)` devolvem a lista plana
  de pontos (servem de entrada para `stroke`).
- `path(g, pts, c[,mask][,closed])` — caminho aberto/fechado.
- `stroke(g, pts, w, c[,mask][,closed])` — carimbo quadrado `w×w` centrado
  em cada ponto: cobre os joins; pontas quadradas; largura par estende 1 px
  a mais para baixo/direita. `w=1` ≡ `path`.
- `fill(g,x,y,c[,{conn=4|8,mask=m}])` — flood fill da cor do semente;
  `conn=4` padrão, `8` atravessa diagonais; `mask` limita a região.

Polígono côncavo: `polygon` já aceita qualquer lista de vértices. Buracos
e recortes = desenhar pela máscara da forma menos o furo
(`mask_sub(sel_component(...), furo)`) ou `patch` com `'.'`.

Seleções (devolvem máscara): `sel_cover`, `sel_color(g,c)`, `sel_rect`,
`sel_component(g,x,y[,conn])`.
Ops de máscara (devolvem grade nova): `mask_or/and/sub`,
`mask_not(a[,bounds])`, `mask_dilate/mask_erode(a[,conn][,n])`.

Regiões nomeadas: `set_region(g,nome,mask)` guarda; `region(g,nome)` lê;
`clone`/`flip`/`crop`/`shift` preservam `g.regions`.

Transformações e patches:

- `crop(g,x,y,w,h)`, `shift(g,dx,dy)` (clip na borda), `flip` (mirror).
- `stamp(g,src,x,y[,pivot][,mask])` — blit com pivô explícito para
  carimbar clusters pequenos autorados.
- `patch(g,{pixels={{x,y,c}...}, rows={{x=,y=,text=}...}}[,mask])` —
  aplica na etapa da receita em que é chamado; `mask` confina a correção.
- `outline(g,c,opts)` — `mode='outer'` (default) | `'inner'` | `'lit'` |
  `'shadow'` (lado da luz via `opts.light={dx,dy}`, default topo-esquerda);
  `opts.colors={c=true}` torna seletivo; `opts.mask` limita a escrita.

Review aids (avisos técnicos com coordenadas, não nota de arte):
`inspect` (`colors`, `unknown`, `isolated`, `pixels`) e `review`, que
acrescenta `clusters` (componentes 4-dir por cor com bbox), `steps`
(saltos ≥2 no contorno superior entre colunas adjacentes), `thickness`
(extensão vertical por coluna + jumps ≥3), `corners` (exatos 2 vizinhos
4-dir perpendiculares) e `gaps` (`'.'` cercado nas 8 direções — pode ser
intencional).

## Atores, poses e animação (`src/actor_kit.lua`, W4)

Runner: `tools/kit_w4` — `--test`, `--emit=<nome>` (bake + dump +
`screenshots/w4-<nome>-report.txt`), `--playback=<nome>` (timeline de
`frameDuration` + marcadores), `--probe=<nome>` (sugere âncoras por frame).
Mesmos exit codes do `kit_run`.

```lua
local K = require('src.pixel_kit')
local AK = require('src.actor_kit')
local base = AK.compose(require('src.sprites.viajante_e'), 'albedo', 1)
-- base é grade editável: a última camada vence por pixel, como no bake
local g = K.clone(base)
AK.move(g, K.sel_rect(g, 46, 46, 12, 12), -8, 0)   -- rig: move região (rascunho)
local meta = AK.meta(def, {
    anchors = { pe = {34,94}, mao_arco = {{51,52},{36,50},{46,50},{51,52}} },
    markers = { prep = {1}, contact = {3}, recover = {4} },
    sequences = { tiro = {1,4,loop=false} },
    frameDuration = {0.16,0.18,0.07,0.20},
    regions = { arco = {x=45,y=5,w=11,h=78} },
})
local def2 = {name='x', w=64, h=96, origin='feet', legend=leg,
    anchors=meta.anchors, markers=meta.markers, sequences=meta.sequences,
    frameDuration=meta.frameDuration, regions=meta.regions,
    layers={AK.layer('tiro', {g1,g2,g3,g4}, {emissive={e1,e2,e3,e4}})}}
```

Contrato de metadados W4 (combinado na nota `kit-w-coordenacao`; o
workbench já consome `anchors`, `markers`, `sequences`, `frameDuration`,
`regions`, `masks`):

- `anchors`: `{nome={x,y}}` estático ou `{{x,y},...}` uma por frame
  (pés, mãos, cabeça, ferramenta, emissão). Âncora fora do quadro ou sobre
  pixel vazio gera aviso no diagnóstico.
- `markers`: `{nome={f1,f2,...}}` — nomes convencionais `prep`, `contact`,
  `react`, `recover`, `return`.
- `sequences`: `{nome={first,last[,loop=bool]}}` dentro do sheet horizontal.
- `frameDuration`: segundos, escalar ou array por frame.
- Diagnósticos (`AK.check`): foot drift (base/alcance dos pés), salto de
  silhueta (contagem e bbox), parte faltando (região de `def.regions` que
  zera), flicker de textura (pixel alternando na maioria das transições),
  emissivo flutuante (sem albedo por baixo), loop quebrado (costura
  último→primeiro vs mediana), âncora inválida, metadados malformados
  (ERROR). `AK.color_drift(a,b)` compara quotas de cor entre direções.

O `AK.move` é rig de rascunho: desloca a região e deixa buraco — a
correção de silhueta/cluster é etapa seguinte da receita, manual. Sem
interpolação/rotação de bitmap como produto final.

## Fluxo de trabalho para IAs

1. Fixar dimensões, origem, paleta, luz e proporções antes do detalhe.
2. Construir silhueta com massas grandes; guardar máscaras com `clone`.
3. Separar sombra, base e luz com formas recortadas pelas máscaras.
4. Acrescentar detalhes em grupos de pixels, com textura localizada.
5. Definir relevo e emissão apenas onde fizerem sentido no material.
6. Inspecionar `unknown` (cores sem legend) e `isolated` (pixels sem vizinhos
   nas oito direções). Pixels isolados são avisos para revisão, não erros.
7. Comparar o PNG em 1x e ampliado; corrigir legibilidade antes de integrar.

O kit fornece precisão e repetibilidade; não certifica qualidade artística.
O exemplo é um lampião técnico para validar o fluxo. Não há geração automática
de personagens, animação ou textura aleatória. Novos sprites podem retornar
uma definição DSL como os módulos existentes em `src/sprites/`.

## Direção de produção acordada

Objetivo: um Arrowfallen encantador em movimento, com o mesmo cuidado no
combate e na exploração. A versão acima é apenas a base implementada.
As fases abaixo descrevem trabalho futuro; não são capacidades entregues.
Não criar gerenciadores ou abstrações genéricas para antecipar essas fases.

### Fase 1 — formas e materiais com autoria

Adicionar curvas rasterizadas com controle de degraus e revisão de clusters,
rampas de material usando a paleta mestra e sombreamento recortado por máscaras.
Textura deve descrever volume e material; evitar ruído distribuído por padrão.
Produzir um prop e um ator reais, com silhueta e valores revisados em 1x.
Validar sob a iluminação do jogo, não apenas no painel do kit.

### Fase 2 — movimento e expressão

Acrescentar pivôs e composição de peças para poses autoradas, com origem dos
pés estável, exposição por frame e comparação entre frames. Separar movimento
principal e secundário: postura e gesto primeiro, tecido e acessórios depois.
Exportar animações pelo contrato existente do SpriteDSL/anim8.
Validar caminhada, repouso e uma ação completa sem deslizamento involuntário.

### Fase 3 — uma interação de combate acabada

A campanha atual é tática por turnos. Escolher uma ação real e trabalhar
preparação, contato, reação e recuperação, sincronizando animação, som e
efeitos nos eventos existentes. Diferenciar disparo, acerto, defesa e derrota.
Preservar leitura de intenção, mira e resultado; intensidade segue importância.
Avaliar pausas de impacto no fluxo existente antes de acrescentar hit-stop.
Respeitar movimento reduzido e não bloquear o registro de comandos.

### Fase 4 — um trecho de exploração acabado

Aplicar os mesmos materiais e animação a uma pequena área existente: ator,
vegetação ou tecido, fonte de luz e objeto interativo. Movimento ambiental
deve ter ritmos distintos e repouso; evitar sincronizar tudo na mesma senoide.
Interações devem apresentar preparação, resposta e retorno ao repouso.
Revisar luz e contraste para manter o personagem e pontos de interação claros.

### Fase 5 — bancada de revisão para IAs

Ampliar o painel com reprodução e passo a passo de frames, comparação de
versões, silhueta, valores e canais. Diagnósticos devem apontar coordenadas e
permitir revisão localizada; não substituir avaliação visual por uma nota
automática de qualidade. Medir custo de bake e render antes de ampliar o lote.

### Critério para expandir

Antes de gerar dezenas de assets, aprovar a interação de combate e o trecho
de exploração jogáveis. Conferir leitura em 1x, consistência de materiais,
pés e pivôs, sincronização de som/contato, retorno dos efeitos ao repouso,
movimento reduzido e desempenho. Capturas comprovam arte estática;
animação e game feel exigem observar sequências e jogar.
