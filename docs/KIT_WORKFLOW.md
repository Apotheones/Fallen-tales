# KIT_WORKFLOW — produção de pixel art procedural por agentes

Workflow oficial: **brief → receita Lua → pixels indexados → bake multicanal →
inspeção visual → correção localizada → comparação → validação in-game.**

Tudo aqui usa APIs que existem hoje (`src/pixel_kit.lua`, `src/sprite_dsl.lua`,
`src/kit_materials.lua`, `tools/kit_run`, `tools/kit_workbench`). Rodar sempre
da raiz do projeto. Receitas são código confiável do repositório — o runner
não é sandbox.

## Regras duras

- **1-based na autoria** (grade, def, anchors, regions, marks); **0-based só
  dentro de ImageData** — converter no limite (`x1 = ix + 1`).
- **`'.'` = transparente.** Espaço também é vazio em grade string.
- **Aleatoriedade só via `K.rng(brief.name, brief.seed)`** — nunca
  `math.random`/`love.math.random`. Mesma receita + seed = mesmos pixels.
- **Bake memoiza por identidade da def**: editou, crie tabela NOVA. Reusar a
  def retorna o sheet antigo silenciosamente.
- **PNGs e relatórios só em `screenshots/`**. Nada na raiz nem em `build/`.
- Simulação/gameplay não se toca; `src/` só muda se você for dono do pacote.

## 1. O brief

`K.brief` valida a forma mínima e deixa campos extras passarem intactos:

```lua
local brief = K.brief {
    name = 'bau_tampa_reforco', w = 64, h = 96, seed = 7,
    role = 'prop de chão', region = 'Refúgio', perspective = '3/4',
    regions   = { 'tampa', 'cintas', 'fechadura' },   -- regiões nomeadas do alvo
    protected = { 'cintas', 'fechadura', 'contorno' }, -- o que NÃO pode mudar
    anchors   = { pe = { 32, 96 } },
    identity  = 'baú madeira+ferro, fechadura dourada',
}
```

Convenções: `name` único (vira prefixo dos PNGs); `seed` sempre declarado
(`0` explícito se for o caso); parâmetros ajustáveis como constantes no topo
do arquivo; `protected` lista as regiões que a edição tem que provar intactas.

## 2. A receita (template mínimo que funciona)

Uma receita é um `.lua` que devolve a def do SpriteDSL ou executa edições
numa grade parseada e devolve uma def NOVA. Padrão canônico (ver
`tools/kit_run/pilot_bau.lua`):

```lua
-- receita: <nome> — <o que faz em uma linha>
local K   = require 'src.pixel_kit'
local DSL = require 'src.sprite_dsl'

local brief = K.brief { name = 'ex', w = 64, h = 96, seed = 7,
    protected = { 'fechadura' } }

local base = require 'src.sprites.bau'          -- asset existente
local g = K.parse(base.layers[1].albedo)        -- grade 1-based editável

local protegido = K.sel_rect(g, 28, 52, 9, 7)   -- região proibida
local alvo = K.mask_and(K.sel_rect(g, 10, 42, 45, 10),
                        K.mask_not(protegido))  -- edição só entra aqui
K.rect(g, 12, 44, 6, 2, 'v', alvo)              -- TODA primitiva leva a máscara

local cand = {
    name = 'ex_cand', w = base.w, h = base.h, origin = base.origin,
    legend = base.legend,
    layers = { K.layer('bau', g) },
    regions = { alvo = { x = 10, y = 42, w = 45, h = 10 } },
    masks   = { alvo = alvo, protegido = protegido },
}
return cand   -- def NOVA: garante bake novo
```

Para inspecionar/bakear dentro da própria receita (self-check local):
`local sheet = DSL.bake(cand)` → `sheet.imageData.albedo` é ImageData
0-based; `sheet.w/h/frames/origin`; `sheet.albedo/normal/emissive` são Images.

## 3. APIs reais (assinaturas verificadas)

### pixel_kit (`require 'src.pixel_kit'`)

| grupo | funções |
|---|---|
| grade | `new(w,h)` `get(g,x,y)` `pixel(g,x,y,c,mask)` `rect` `line` `ellipse` `polygon(g,pts,c,mask)` `clone` `flip(g,h,v)` `blit(g,src,dx,dy,mask)` `crop` `shift` `string(g)` `inspect(g,legend)` `parse(text)` |
| traço | `path(g,pts,c,mask,closed)` `qcurve(g,x1,y1,cx,cy,x2,y2,c,mask)` `ccurve(g,x1,y1,c1x,c1y,c2x,c2y,x2,y2,c,mask)` `stroke(g,pts,w,c,mask,closed)` `qpts/cpts` (lista de pontos) |
| fill/stamp | `fill(g,x,y,c,{conn,mask})` `stamp(g,src,x,y,pivot,mask)` `patch(g,{rows={{x=,y=,text=}}},mask)` (`' '` pula pixel) |
| contorno | `outline(g,c,{mode='outer'|'inner'|..,mask,colors={F=true}})` |
| máscara | `sel_cover` `sel_color(g,c)` `sel_rect` `sel_component(g,x,y,conn)` `mask_or/and/sub` `mask_not(a,bounds?)` `mask_dilate/erode(a,conn,n)` |
| região | `set_region(g,nome,mask)` `region(g,nome)` |
| util | `rng(nome,seed)` → `float/int(a,b)/pick/chance` `brief(t)` `review(g,legend)` |

Toda primitiva de desenho aceita `mask` como último argumento — **use-a
sempre** para confinar a edição à região do brief.

### sprite_dsl (`require 'src.sprite_dsl'`)

`SpriteDSL.bake(def)` → sheet; `SpriteDSL.dump(sheet,'screenshots/x')` →
`{albedo=,normal=,emissive=}` PNGs; `SpriteDSL.selfCheck()`.

Forma da def (campos de animação = contrato W4 congelado):

```lua
{ name, w, h, origin = 'feet'|'topleft',
  legend = { c = 'rampa.degrau'              -- spec curto
           | { ramp='r',step=n,h=0..15 }      -- albedo+altura
           | { spec='x', e='brasa.5', ei=.5 } -- albedo+emissivo
           | { spec='x', height=grade, emissive=grade } },
  layers = { { name='n', albedo=str|{str..frames}[,height=][,emissive=] } },
  -- opcionais (já lidos pelo workbench):
  regions = { nome = {x=,y=,w=,h=} }, masks = { nome = grid },
  anchors = { nome = {x,y} | {{x,y},..por frame} },
  markers = { contact={1,3}, prep={..} },
  sequences = { nome = {first,last[,loop=false]} },
  frameDuration = s | {s1,s2,..},
}
```

### kit_materials (`require 'src.kit_materials'`)

Rampas/região: `ramp(nome)` `regionStep(region,ramp,step)`
`remapSpec/remapLegend/remapDef(def,region)` — trocar material por região.
Métricas: `swatches(def,resolve)` `colorCount` `redundant(def,eps,resolve)`
`checkBudget(def,max,resolve)`.
Canais por grade: `hfield(w,h)` `hplane` `hband` `hgrad` `hvolume`
`hocclusion(albedo,hg,drop,dist,mask)` `emitRegion(eg,ch,mask)`
`applyLightField` `dither`.
Máscaras de char: `maskChars(albedo,chars)` `maskAnd` `maskRect` `gridOf`.
Imagens: `luminanceImage(id)` `silhouetteImage(id,cor)` `materials` `material(nome)`.

## 4. Comandos (da raiz do projeto)

```powershell
$LV = 'C:\Program Files\LOVE\lovec.exe'
& $LV tools/kit_run --check          # checks compactos do kit        (exit 0/1..5)
& $LV tools/kit_run --verify         # determinismo: receita+seed=mesmos pixels
& $LV tools/kit_run --bake=<nome>    # dump canais de src.sprites.<nome>
& $LV tools/kit_run --revise         # piloto W1 de revisão localizada (baú)
& $LV tools/kit_run --baseline       # perf de bake -> kit-baseline.txt
& $LV tools/kit_w2 --test            # checks de materiais/canais (Cinzel)
& $LV tools/kit_w4 --test            # checks de atores/animação (Cinzel)
& $LV tools/kit_w5 --test            # checks de ambiente (Cinzel)
& $LV tools/kit_w6 --test            # checks de VFX (Cinzel)
& $LV tools/kit_workbench --asset=<nome|arquivo.lua> ...   # bancada de revisão
& $LV tools/kit_workbench --test     # self-check da bancada
```

Exit codes `kit_run`: 0 ok · 1 check · 2 autoria · 3 bake · 4 render · 5 uso.
Exit codes `kit_workbench`: 0 ok · 1 erro · 2 warnings com `--strict`.

Workbench — flags que você vai usar:

```
--views=albedo,channels,grid,swatches,frames,onion,loop,tracks,seq,
        instances,ab,diff,blink,crop,tile,lit,luminance,silhouette,normal,emissive,dump
--frame=N|all  --zoom=N  --seq=i1,i2,nome  --crop=x,y,w,h
--bg=checker|neutral|dark|ambient:<regiao>|game[:<piso>]|shot:<png>[@x,y]
--light=x,y[,z,raio,int]  --ambient=regiao  --instances=N --phase=K
--mark=nome@x,y  --region=nome  --mask=nome  --tile=N --seed=N
--strict  --out=prefixo  --report=caminho
```

## 5. Evidência de revisão (checklist obrigatório)

Para aprovar uma edição, o relatório do agente tem que conter:

1. **Comandos exatos** rodados (copiáveis).
2. **PNGs gerados** em `screenshots/` — mínimo: `grid` (ou `albedo` com
   região) + `channels` + `ab`/`diff` quando houver comparação. Animado:
   + `frames`/`onion`/`loop`/`tracks` conforme o caso.
3. **Relatório** `screenshots/wb-*-report.txt` com INFO/WARN/ERROR lidos
   (não só o número de warnings).
4. **Prova de proteção**: a mudança ficou dentro da região (assert da
   receita ou `diff`+`--crop`/`--mask` mostrando pixels protegidos cinza).
5. **Exit code** observado.
6. Observações separadas de hipóteses — "vi X" vs "acho que X".

## 6. Revisão localizada e rollback

- Construa a máscara da região (`sel_rect`/`sel_color`/`sel_component` +
  `mask_*`), cruze com `K.sel_cover(g)` se a edição não deve expandir a
  silhueta (região retangular inclui células transparentes!), eroda 1px
  se a edição não pode encostar na borda (`mask_erode(m,8,1)`), e
  registre-a em `def.masks` para o workbench exibir.
- Compare: `--vs=<defB>` + `views=ab,diff,blink` — o mapa codifica
  verde=novo / vermelho=removido / amarelo=mudado / cinza=intocado.
- Rollback = manter a def original intocada e comparar sempre contra ela;
  o git segura a receita. Não edite `src/sprites/*.lua` sem ser dono —
  candidatos vivem em `build/` ou `tools/kit_run/pilot_*.lua`.

## 7. Conjunto de referência aprovado

- `bau` (64×96 feet) — piloto de revisão localizada aprovado: prova região
  `frente` com máscara de proteção, carimbos, painel recuado, assert de
  confinamento. Ver `tools/kit_run/pilot_bau.lua` + `kit-bau-report.txt`.
- `lampiao` (64×96, 4f) — referência de emissivo (chama+vidro) e animação
  leve; usado nos checks de `lit` e A/B.
- `viajante_walk_s` (64×96, 4f) — referência de ator; costura de loop medida
  ≈23% (limpa) no relatório da bancada.
- `build/wb-anim-demo.lua` — fixture de metadados W4 (anchors/markers/
  sequences/frameDuration) — prova do contrato, não arte final.

Razões de aprovação: todos assam determinístico, passam `--verify`, têm
evidência de revisão em `screenshots/` e o relatório não acusa erros.

## 8. Limitações conhecidas

- `lit` exige shader; sem GL de shader cai no fallback albedo+emissivo.
- Warnings da bancada são prompts de revisão, não veredito artístico.
- `def.masks` usa grade pixel_kit ou string; `def.regions` é caixa 1-based.
- `kit_run --bake` só resolve nomes de `src.sprites`; arquivo solto vai no
  workbench (`--asset=build/x.lua`).
- `lovec tools/kit_workbench` é CLI headless (janela offscreen) — `--play`
  é o único modo que abre janela visível.
- Report do workbench é texto greppável, não JSON.
