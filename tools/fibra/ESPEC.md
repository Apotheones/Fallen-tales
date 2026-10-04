# LOTE FIBRA — Figurantes + Inimigos (handoff p/ Traço)

Refino por âncora de uso: 13 figurantes (5 novos do Refúgio + 8 de
região) e 12 inimigos (4 sentinelas, 5 devotos, crawler, husk, casulo).
Tudo pixel-a-código, 40×48, origem (20,44), mesmas assinaturas atuais.

## Entrega

- `tools/fibra/lote.lua` — painters candidatos prontos para colar em
  `src/pixel_actors.lua`. Todas as funções usam apenas helpers já locais
  do módulo (`painter`, `pose`, `mixc`, `faceNpc`, `faceNpcSide`,
  `faceRes`, `faceDraw`, `npcFeet`, `armsIdle`, `workArms`, `workBob`,
  `seatedResident`-sibling, `BAYER`, `P`).
- `tools/fibra/main.lua` + `tools/fibra/base.lua` — harness standalone
  de prancha (`lovec tools/fibra [figurantes|inimigos]`). `base.lua`
  traz cópias verbatim dos helpers como globais; se algum helper mudar,
  sincronizar. Nada disto é carregado pelo jogo.
- Pranchas de avaliação geradas:
  `screenshots/fibra-figurantes.png`, `screenshots/fibra-inimigos.png`
  (4 dirs idle + 2 frames de work/warn + warn + retrato).

## Wiring em `src/pixel_actors.lua`

1. `residents`: substituir as 13 entradas `npc_*` (traba…plateia,
   anciao…crianca) pelas de `Lote.residents`. `shape` preservado;
   `act`, `beard`, `headWrap`, `cape`, `pants` no mesmo contrato.
2. `coreBodies` += `Lote.bodies`; `coreTops` += `Lote.tops`
   (bodies novos: elder, washer, porter, logger, kid, braid, stocky,
   watch, vendor, voice, crew, usher, crowd).
3. `resident()`: na rota `action == 'work' and pal.act == 'sit'`,
   trocar `seatedResident` por `seatedElder` (mesma assinatura; cabeça
   de pele + cabelo branco ralo em vez de capuz de pano). Seguro: só o
   anciao usa `act='sit'` hoje.
4. `residentEmote()`:
   - `rests` += `{elder='worn', washer='kind', porter='worn',
     logger='stern', kid='joy', braid='kind', stocky='kind',
     watch='stern', vendor='kind', voice='worn', crew='worn',
     usher='soft', crowd='kind'}`
   - `bare` += `v == 'stocky'` (trabb é raspado)
   - antes do `else` final da cadeia de adornos:
     `if emoteAdorno(r, l, p, cx, v, pal, cloth, hair, accent, skin,
       skinHi) then` — a função `emoteAdorno` está no lote e já cuida
     dos 13 bodies; o `else` cobre qualquer body futuro.
   - overlays genéricos (`pal.beard`, `pal.headWrap`, `pal.chin`)
     continuam valendo — carregador usa `beard=P.ink`, feirante usa
     `headWrap=P.boneDark`.
5. Inimigos: trocar `sentinel`→`sentinelV2`, `zealot`→`zealotV2`,
   `crawler`→`crawlerV2`, `husk`→`huskV2`, `huskCocoon`→`huskCocoonV2`;
   `sentinelSkins`/`zealotSkins` pelas tabelas `Lote.*` (mesmos campos
   + `build`, `robeDeep`, `skin`, `expr`, `trimLight` — todas as
   chaves novas têm fallback no painter).
6. Emotes de inimigo (`sentinelEmote`, `crawlerEmote`, `huskEmote`):
   intactos — consomem `sk.eye`/`sk.shell`, que as skins mantêm.
7. `workArms`/`workBob`: sem mudança. Meus bodies chamam
   `workArms(r, l, p, cx, C.top, side, south, pal, frame)` igual aos
   core bodies; `fill`→wash e `help`→carry já mapeados.
8. `sheet()`/`sheetOf()`/`Actors.state`: intocados.

## Âncoras por kind (o que conferir na prancha pós-integração)

Figurantes do Refúgio:
- anciao: casaco areia ao joelho + bengala + cabelo branco ralo sobre
  pele escura; sentado (work) = pernas dobradas, bengala escorada.
- lavadeira: saia azul + avental claro + mangas dobradas (antebraço de
  pele) + rolo de cabelo na nuca; work 'wash' segura o pano torcido.
- carregador: peito largo + lona no ombro + alça diagonal + barba
  escura; work 'carry' carrega o fardo (workArms atual).
- lenhador: alto, casaco cinza reto + faixa clara no punho + machado
  no ombro; work 'chop' levanta a lâmina (workArms atual).
- crianca: baixa, cabeça redonda + cachos + blusa ocre + calça azul de
  dobra larga; work 'play' joga bola (workArms atual).

Figurantes de região:
- traba: alta/magra, trança baixa, camisa barro + avental curto claro.
- trabb: baixo/robusto, raspado (retrato `bare`), colete verde quadrado
  sobre mangas escuras.
- guarda: alto, manto curto no ombro de trás, gola + cinto de posto.
- feirante: pano na cabeça + caracóis brancos + gola azul + saia-calça
  cinza + bolsa estreita no quadril.
- voz: fallback — capuz fundo, rosto em sombra (doc diz que a voz não
  precisa de corpo; se sair do elenco visual, ignorar o body 'voice').
- equipe: lenço de serviço + peitilho jade + faixas no punho + botas
  impermeabilizadas de cano alto.
- ajudante: camisa creme + faixa vinho curta + rabo baixo no ombro.
- plateia: relaxado, xale atravessado + mãos no colo; serve de molde
  para futuros corpos de assistência.

Inimigos:
- crawler: casco de 3 placas com fendas + reborde claro, 6 patas de 3
  segmentos com garra, abdômen segmentado atrás, cabeça projetada com
  mandíbula articulada e 3 olhos de brasa; de costas o casco e o cerco
  dominam; warn acende a crista.
- husk: mortalha em 3 painéis com fendas de tinta, barra desfiada em
  tiras, capuz pontudo com vinco, janela de rosto oco; nunca toca o
  chão (barra em y≈38 + tiras caídas).
- huskCocoon: fardo enrolado com 3 laços + nó lateral + núcleo âmbar
  que pulsa pelas emendas.
- dasher (brute): braços-pilar com punho no chão, tronco tombado, elmo
  baixo com fenda de olho dupla (ember + jade).
- breaker (bull): V de ombros + chifres com serra na base + braços de
  peso com juntas.
- demolisher (ruin): ombro-laje descomunal esquerdo + tronco inclinado
  sob a carga + braço até o chão.
- warden (tower): coluna com placas horizontais + mitra com degrau +
  selo frontal + bastão de selo na lateral.
- ranger (scout): talhe oblíquo, capuz baixo, besta nivelada ao peito
  (coronha + asas + corda de osso); de frente, besta curta no quadril;
  de costas, aljava com fletchas.
- sower (loader): barril de pano + cesto de vime em crosshatch com
  grãos + suspensório no peito.
- watcher (needle): coluna que afunila sem pés + tiras na barra +
  sombra de voo dithered + orifício de olho vivo; warn abre a fenda.
- veteran (block): coluna larga com remendo, bandoleira, atadura de
  joelho, aljava+fletchas atrás, arco erguido com corda inteira.
- regent (regal): manto de 2 patamares com filetes, estola no peito,
  coroa de 3 dentes com pedra, mão de comando com anel.

## Riscos / notas

- `lote.lua` assume os helpers locais atuais; se o Traço mudar
  `npcFeet`/`workArms`/etc., o paste segue a assinatura nova (são os
  mesmos pontos de contato dos core bodies).
- `seatedElder` usa `pal.skin/hair/cloth/accent` — se outro figurante
  ganhar `act='sit'` depois, o sentado herda a paleta dele.
- `emoteAdorno` precisa dos locais `r,l,p,cx,v,pal,cloth,hair,accent,
  skin,skinHi` do escopo de `residentEmote` — colar dentro da closure.
- Painters de inimigo não dependem de campos novos obrigatórios: tudo
  tem `or` de fallback igual ao código atual.
- Bordas: husks/crawler flutuam (barra acima de y=41); sentinelas pisam
  em y≤44; nada excede o frame 40×48 (conferido nas pranchas).

## Pós-integração (sugerido p/ Traço)

1. `lovec . --scene=prancha --region=figurantes` e `--region=inimigos`
   → comparar com `screenshots/fibra-*.png`.
2. `lovec . --scene=hub --screenshot=screenshots/hub-figurantes.png`
   → ver figurantes no contexto do Refúgio.
3. `lovec . --test` — gate obrigatório.
