# Arrowfallen — Megaplan da repaginada visual HD

Status: planejado e aprovado em direção. Substitui a linha de trabalho dos
planos antigos de pixel art (32px), que foram arquivados no histórico do git.
Direção de elenco e materiais segue [GUIA_VISUAL.md](GUIA_VISUAL.md) e
[PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md](PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md);
este plano muda a *tecnologia e o orçamento* da arte, não a ficção.

Objetivo: sair do visual atual — plano, lavado e vazio — para **pixel art
lit moderno** (a linha aberta por Octopath/HD-2D, Sea of Stars, Dead Cells,
Songs of Conquest): arte pixelizada sobre um pipeline de render de 2026+ —
iluminação per-pixel por normal map, HDR, bloom, sombras projetadas, color
grading. Régua de acabamento: "parecer de 2028". Mantendo **toda a arte
gerada por código**, sem assets importados — e usando essa restrição a
favor: albedo, altura e emissivo nascem no mesmo bake.

## 1. Decisões aprovadas

| Elemento | Decisão |
| --- | --- |
| Pipeline | Procedural evoluído: sprites autorados como bitmaps-por-string em Lua, multi-canal (albedo + altura + emissivo), assados em spritesheet |
| Grade artística | 64 × 64 pixels por célula |
| Atores | ~64 × 96 pixels (chefes maiores); origem nos pés |
| Paleta | Mestra de ~96–128 cores; rampas de 6–10 tons por material com hue-shifting |
| Luz | Per-pixel direcional por normal map (gerado da altura no bake); HDR + bloom + sombras projetadas + grading por LUT |
| Migração | Big bang: congelar features de campanha e refazer a camada de render inteira antes de continuar conteúdo |
| Perspectiva | Vista de cima inclinada (topo + frente), inalterada |
| Reprodução | anim8, spritesheets geradas em memória |
| Filtro/escala | nearest, fatores inteiros, sem suavização |

## 2. Por que refazer o pipeline de desenho

O visual atual nasce de `px()`, `l()` e polígonos soltos em
`src/pixel_actors.lua` (~5.5k linhas) e `src/pixel_scene.lua`. Esse estilo
tem um teto: cada pixel é efeito colateral de geometria, não decisão. O
resultado é preenchimento plano, ruído como textura e personagens sem
anatomia.

A repaginada introduz um **mini-formato de sprite autorável**: cada quadro é
uma grade de caracteres onde cada caractere mapeia para um índice da paleta.
Pixels passam a ser posicionados à mão, revisáveis em diff e no olho, sem
importar nenhum arquivo. Camadas (corpo, roupa, equipamento, efeito)
compõem o quadro.

Cada sprite é **multi-canal**: além do albedo, o autor marca altura
(relevo) e emissivo por pixel — com os mesmos caracteres ou camadas
paralelas. Do heightmap o bake deriva o **normal map** automaticamente; do
emissivo, a máscara que alimenta o bloom. Saída: spritesheet de albedo +
spritesheet de normais + máscara emissiva, tudo ImageData gerado em memória.

```lua
-- formato alvo (esboço): char → índice da rampa
local traveler_idle_s = {
    palette = 'traveler',
    layers = { 'body', 'coat', 'bow' },
    frames = { [[
      .....#######......
      ...##bbbbbbb##....
      ...#bbhhhhhhbb#...
    ]] },
}
```

O formato exato (dimensões, separador de camadas, run-length opcional) é
definido na Fase 0 e documentado no próprio módulo.

## 3. Arquitetura nova

| Módulo novo/alterado | Função |
| --- | --- |
| `src/sprite_dsl.lua` (novo) | Parser do formato bitmap-por-string multi-canal; camadas; bake albedo+normais+emissivo; cache |
| `src/palettes.lua` | Reescrito: paleta mestra indexada, rampas longas, grading por região |
| `src/lighting.lua` (novo) | Buffers de luz/normais, shader direcional per-pixel, sombras projetadas, fontes dinâmicas, rim/tint |
| `src/postfx.lua` (novo) | Pipeline HDR: bloom por threshold no emissivo, LUT de grading, vignette |
| `src/pixel_scene.lua` | Tiles 64px: piso, parede oblíqua, props — redesenhados no formato novo |
| `src/pixel_actors.lua` | Atores 64×96 no formato novo; `pixel_world.lua` segue o mesmo |
| `src/render.lua` | Câmera e composição com lightmap; HUD na nova tipografia |
| `src/pixel_font.lua` | Fonte bitmap redesenhada para a nova escala |

Bakes acontecem uma vez (load ou primeira visita) e o resultado é canvas
reutilizado — sem custo por frame além do draw.

### 3.1 Resolução e câmera

- Célula artística 64px. A grade lógica de simulação (40 unidades) permanece;
  a conversão acontece só na apresentação.
- Zoom preferido 1× nativo da arte 64px (o detalhe já está no desenho); em
  janelas pequenas, inteiro menor conforme necessário. Nunca fracionário.
- Com células maiores, menos células visíveis: câmera mais próxima,
  centralizada nos pés, limites de sala — reavaliar legibilidade dos avisos
  de combate nesse enquadramento antes de fixar.
- Atores 64×96 cabem ~1.5 célula de altura: peças altas (portais, fachadas,
  monumentos) passam a ocupar 2+ células verticais desenhadas.

### 3.2 Paleta mestra

- ~96–128 cores indexadas. Organização por material em rampas de 6–10 tons.
- Hue-shifting obrigatório: sombra esfria/roxeia, luz aquece — fim do azul
  acinzentado único.
- Grading por região: cada mundo tinge a rampa (Refúgio quente, Colina fria,
  Necrópole esverdeada, Salões dourado escuro). Uma linha por região, não um
  conjunto de cores novo.
- Cores funcionais (perigo, seleção, jade mágico) protegidas: sempre fora da
  rampa ambiente.

### 3.3 Pipeline de luz e pós-processo (o coração do "2028")

O que separa pixel art moderna de retrô não é o desenho — é o render. O
pipeline novo tem quatro estágios:

1. **G-buffer da cena**: o bake do cenário e dos sprites emite três
   canvases/canais — albedo, normal map (derivado da altura) e emissivo.
   Atores dinâmicos desenham seus mapas no mesmo passe.
2. **Passe de luz (shader)**: N fontes por cena, cada uma com posição,
   cor, raio, atenuação e flicker. O shader calcula luz direcional
   per-pixel: `dot(normal, dir_luz)` + ambiente. Tocha ilumina a frente da
   parede e deixa o topo frio; luar vem de uma direção só; runa emite jade.
   Normais chatos (piso plano) recebem luz ambiente sem drama.
3. **Sombras projetadas**: occluders (paredes, fachadas, peças altas,
   atores) lançam sombra sobre o chão na direção oposta à fonte —
   shadow quads por occluder×fonte, ou máscara assada por fonte estática.
   Não é elipse embaixo do pé: é projeção coerente com a direção da luz.
4. **Pós em HDR**: cena composta em canvas `rgba16f` → bloom por threshold
   (só o emissivo estoura: fogo, runa, marco, magia — o piso não vaza) →
   LUT de color grading por região/hora → vignette suave.

Em cima disso, atmosfera: névoa baixa dithered, poeira em feixe de luz,
god rays discretos em janelas/frestas — tudo desenhado, tudo respeitando
movimento reduzido (flicker e drift zeram; informação luminosa fica).

**Orçamento de performance**: luz estática é assada no bake do cenário
(direção do sol/luar + sombras fixas entram no canvas, custo zero por
frame). Luz dinâmica é reservada ao que se move ou reage: limite de ~8
fontes ativas por tela, passadas ao shader por uniform array. Atores usam
o mesmo normal map por frame, sem recomputar.

Decisão técnica a validar na Fase 0: formato exato do G-buffer (três
canvases vs. canal alpha/carregamento em texturas auxiliares) e custo do
passe de sombras — medir antes de propagar.

## 4. Direção visual (o que muda na tela)

Do diagnóstico das capturas atuais, os cinco defeitos a eliminar:

| Defeito atual | Correção no padrão novo |
| --- | --- |
| Chão = retângulo + pontinhos de ruído | Superfícies com textura desenhada (lajes, terra, grama com touceiras), variação por seed estável, ornamento concentrado |
| Áreas enormes vazias | Composição com densidade: props, desnível, caminho, sombra de fachada; espaço vazio só onde é decisão |
| Personagem ~30px ilegível | ~90px com mãos, roupa, equipamento e expressão desenhados — as "três âncoras" do doc de personagens |
| Sem luz; sombra só embaixo dos pés | Luz direcional por normal map, fontes coloridas, sombras projetadas, bloom no emissivo |
| Paleta lavada uniforme | Rampas longas com hue-shift + grading regional |

Hierarquia inalterada: perigo imediato > viajante/inimigos > interativos >
arquitetura > textura. Piso de exploração recua; grade da arena é legível
porque é informação.

## 5. Fases

### Fase 0 — Fundação técnica

- `sprite_dsl`: formato multi-canal (albedo + altura + emissivo), parser,
  camadas, bake triplo (albedo/normais/emissivo), cache; sprite de amostra.
- Paleta mestra + sistema de rampas + grading regional (LUT).
- `lighting` + `postfx`: G-buffer, shader de luz direcional per-pixel,
  sombras projetadas, canvas HDR, bloom por threshold, LUT, vignette.
  Prova numa cena escura com braseiro.
- Migração de resolução: célula 64, frame 64×96, câmera, limites, janelas
  900/1120/1920 de largura.
- Medição de custo do passe de luz/sombra antes de propagar (ver §3.3).
- Entrega: cena técnica feia mas correta — paleta viva, luz direcional
  modelando o ator e a parede, sombra projetada, bloom no braseiro,
  ator 96px parado na sala.

### Fase 1 — Vertical slice (a prova)

- Uma sala do Refúgio completa no padrão: viajante, 1 NPC, braseiro aceso,
  fachada oblíqua, caminho, props.
- Iterar desenho até aprovação visual do usuário — **padrão-ouro**. Nada
  expande antes disso.
- Comparar antes/depois na mesma cena, mesma posição, mesma janela.

### Fase 2 — Kit de mundo

- Tilesets por região (piso, parede oblíqua com topo+frente+cantos,
  desnível/escadaria, caminhos orgânicos).
- Biblioteca de props 64px com variações estáveis por seed.
- Portas/marcos como peças arquitetônicas com estados.
- Migração das regiões existentes, uma a uma, com captura antes/depois.

### Fase 3 — Elenco

- Viajante: 4 direções × estados (espera, andar, carregar, disparar, mineração,
  dano, morte, sentado/interação), andar-enquanto-carrega incluído.
- NPCs do Refúgio pelas "três âncoras" de cada ficha do doc de personagens.
- Inimigos e chefes com silhuetas por função (investidor, atirador,
  conjurador, rastejante), transformação de fases legível.
- anim8 nas sequências; simulação continua dona dos tempos.

### Fase 4 — Combate e efeitos

- Arena 64px: grade legível, telegraphs exatos da simulação.
- Efeitos por material (pedra/metal/cristal/magia), impactos direcionais.
- UI de batalha, ACT/MERCY, balões — na nova escala e tipografia.

### Fase 5 — Interface e polimento

- HUD mínimo: vida/escudo sempre visíveis, carga perto do viajante, minimapa
  no canto superior direito (posição e regras de descoberta preservadas).
- Fonte bitmap nova com português completo; retratos de diálogo aproveitando
  a escala maior.
- Menus, recompensa, derrota/vitória, transições, telas de loja.
- Revisão final: movimento reduzido, janelas suportadas, consistência.

## 6. Regras invariantes

- Arte 100% gerada por código; nenhum PNG/PNG-like importado. Bakes podem
  ser cacheados em disco se gerados pelo próprio pipeline.
- Simulação intacta: colisão, alcance, dano, timers, descoberta de mapa,
  controles, saves. Arte só apresenta.
- nearest + escala inteira; pixels uniformes inclusive em tremor.
- Movimento reduzido preserva toda informação (luz, perigo, ação).
- Screenshots e pranchas só em `screenshots/`, capturados da raiz com
  `--screenshot=screenshots/nome.png`.
- Mudança de lógica → `--test` e `--ui-test` conforme tests/README.md.

## 7. Verificação e aceite

- Consistência de pixel em todas as janelas suportadas; nada esticado.
- Silhueta identifica personagem, direção e ameaça em cinza e em 1×.
- Luz: fontes coloridas reconhecíveis, sombras projetadas coerentes,
  normais modelando volume, bloom só no emissivo; cena escura ainda
  legível.
- Piso recua; perigos dominam a leitura; nada decorativo sugere colisão.
- Big bang significa: nenhuma tela do jogo sai com arte legada ao final —
  a slice aprova o padrão, as fases propagam, o legado some.
- GIFs/sequências em velocidade normal: poses mudam, não só posição.
- Testes técnicos não aprovam qualidade artística: cada fase termina com
  revisão visual pelo usuário.

## 8. Prompt para começar

```text
Execute a Fase 0 de docs/MEGAPLAN_VISUAL_HD.md: a fundação técnica da
repaginada. Leia o megaplan, AGENTS.md, GUIA_VISUAL.md e os módulos de
render antes de editar.

Entregue nesta ordem: (1) src/sprite_dsl.lua com o formato bitmap-por-
string multi-canal (albedo+altura+emissivo), camadas e bake para
spritesheets albedo/normal/emissivo; (2) paleta mestra em src/palettes.lua
com rampas longas e grading por região; (3) src/lighting.lua + src/postfx.lua
com o pipeline de §3.3 — G-buffer, shader direcional per-pixel, sombras
projetadas, HDR+bloom+LUT; (4) migração para célula 64px e atores 64×96
com câmera ajustada.

Prove a fundação numa cena técnica escura com um braseiro e um ator parado:
capturas em screenshots/ mostrando luz direcional modelando volume, sombra
projetada, bloom só no fogo e LUT aplicada. Simulação e controles intactos;
rode --test e --ui-test. Não comece a vertical slice (Fase 1) neste passo.
```
