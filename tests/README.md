# Verificação de combate e cenário

No diretório do jogo:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test
& 'C:\Program Files\LOVE\lovec.exe' . --ui-test
```

`--test` usa LÖVE/Concord reais. `tests/floor.lua` cobre 128 seeds em quatro
andares: determinismo, crescimento de 2/3 salas, árvore cardinal, distâncias,
pontas especiais, chefe mais distante, entradas recíprocas, segredos com
múltiplos vizinhos e restrições de posição. Verifica rotas normais sem
ferramentas, descoberta, presença do comerciante na loja e mineração de uma
entrada secreta. Regiões e arquétipos: tamanho dentro da faixa do catálogo,
portas fora dos cantos com deslocamento variado, cobertura de todo o pool de
cada andar nas seeds e máscara de alcançabilidade (`Rooms.reachable`)
cobrindo spawn, saídas, inimigos e cristais. O portão selado marca as duas
pontas da folha especial, bloqueia a travessia até o diálogo e abre por ouro
ou picareta — `SAIR` não rompe nada. Desafios de combate/pontaria só recompensam ao concluir;
retorno não exige ferramentas, alvos acertados persistem e revisitas não
duplicam recompensas. Descida preserva a tentativa.
O catálogo continua oferecendo três escolhas após adquirir as melhorias únicas;
a recompensa de ferramentas devolve três picaretas.

`tests/enemies.lua` cobre o elenco: aviso/mordida/erro/exposição do
rastejante, recuo tático limitado do sentinela, marca congelada/única/detonada
do semeador, cruz imóvel do vigia, investida destrutiva do bruto demolidor
(parede e pilar) e do Demolidor, compromisso dos dois tiros da veterana,
compatibilidade do Guardião, eco nascente interrompível e teto de dois servos
da Regente. Composição procedural valida repertório por andar, orçamento de
papéis, salas de elite e boss correto por andar; a vitória no andar 3 encerra
o mundo sem gerar o quarto.

Terreno verifica custo/adjacência/zero,
proteção, solo preservado, buracos, prioridade fatal, investidas, quatro lados
e hits mistos do pilar, segmentos independentes, esmagamento, avisos congelados,
quedas determinísticas, revisitas e reset. Busca cardinal em 100 seeds valida
TODAS as chegadas ligadas a TODAS as saídas e inimigos sem ferramentas nas
direções e combinações de queda. A faixa protegida permanece livre. Cristais,
impactos e linhas de tiro continuam limitados ao aviso.

Combate verifica apenas arco: carga, hold pronto sem tiro, soltura única,
cancelamento cedo/guarda/recuperação, alcance, paredes, reservas de movimento,
virar-antes-de-andar, armadura, avisos, esquiva, escudo, recompensas, cristais, chefe e geração.
Fixtures isolam essas regras com células/piso seguro. Replays usam os layouts
reais e comandos cardinais de carga/soltura: não alteram posições, vida ou
temporizadores. O replay usa metadata e busca no grafo para visitar o refúgio
quando existente e chegar ao chefe, sem depender de índices fixos de sala.
Prática/primeiro andar vencem pelo portal explícito, com zero picaretas no
replay da expedição; o replay para
callbacks pode parar no clear de combate. Reprodução cobre 30/60/144 FPS.

`--ui-test` chama teclado/update/desenho reais. Verifica menus, retry, telas,
recompensas por 1/2/3, arco único, SPACE press/hold/release, repetição/duplicação,
cancelamento cedo/guarda/mineração/pausa/guia/foco, ausência de fila na ação e
novo gesto após cancelamento. `tests/dialogue.lua` cobre o spawn dos dois
NPCs, o bloqueio da célula, a imunidade a dano, E junto/longe do personagem,
datilografia e avanço, opções numeradas, congelamento da simulação, memória
entre andares e revisita curta. Cobre ainda as cartas: deck `cardQueue`
determinístico e zerado entre tentativas, coleta por fonte (chefe, desafio,
tesouro, primeira conversa com Odete, inscrições com `inscriptionCard`),
unicidade e notificação por título, releitura sem duplicar e prática sem
coleta; a intro de chefe na primeira entrada (`seenIntro`), congelando a
simulação e não repetindo; e as inscrições em células de piso válidas, com
prompt `E · LER` cedendo a `E · FALAR` quando um NPC divide a adjacência.
Cobre também o XP da tentativa: valores por
fonte, `xpSteps`, a fila `pendingOffer` esperando recompensa ou diálogo fechar,
servos invocados sem XP, desafio rendendo 2 e a prática fora da economia. `tests/shop.lua` cobre o balcão do Amâncio:
estoque e preços, efeito das três ofertas, recusas que não cobram, `VENDIDO`
na revisita e estoque novo por andar, mapa que revela só salas comuns e o
caminho inteiro pelo diálogo. `tests/explore3.lua` atravessa o andar 3 em três
seeds: desenha **toda** sala no renderizador real (pega falhas de sprite que o
resto da suíte não alcança), atravessa portas de verdade, conversa e compra no
andar profundo e encerra o mundo pela Regente. ENTER após vitória desce e
preserva a tentativa.
Mineração cobre taps/hold, uma intenção pendente,
zero e descarte em telas. Reproduz combate por callbacks e navega parede →
pilar → segmento → buraco sem teleportar ou chamar mineração diretamente.
Gesto SPACE, mineração e pouso são repetidos em 30/60/144 FPS. Render.selfCheck
verifica desenho completo sem fog/iluminação, cadência do brilho discreto de
quatro segundos e ausência de mutação de gameplay.

Resultados em `test-results.txt` e `ui-test-results.txt`.

```lua
local game, report = require("tests.combat").replay("bow", 42042, 240, false)
-- report.trace: comandos por passo da simulação a 120 Hz.
-- report.dodges, report.fires, report.seconds: resumo.
```

O último `false` pede o primeiro andar; omitir pede prática. Automação valida regras
e integração; teclado humano e leitura/sensação de combate são aceite manual.

`tests/pixel.lua` cobre câmera/escala inteira, spritesheets anim8 geradas em memória,
fonte bitmap com acentos e renderização sem mutação. A fonte bitmap autoral
(`src/pixel_font.lua`) atende toda a UI em escalas inteiras (1×, 2×, 3×, 6×); os
checks garantem glifos para acentos e travessões, altura/largura proporcionais à
escala, dobra de caracteres desconhecidos em `?` via `Font.clean` e cobertura de
toda string de lore (falas, cartas, inscrições, intros, ecos). A datilografia do
diálogo avança a 55 caracteres/s no `Render:update` e cada caractere revelado
dispara um blip de voz (`Feedback` som `voice`) com tom por falante — Amâncio
grave, Odete aguda, chefes profundos, inscrição neutra — pulos de linha e
movimento reduzido viram um blip único, e M silencia tudo. O UI check desenha 120 quadros
de movimento real, pausa/guia/página CARTAS/recompensa/morte e redimensiona entre
900×680, 1120×800 e 1920×1080, incluindo filtro nearest e movimento reduzido.
Referências visuais e reprodução: [primeiro marco](../docs/PIXEL_ART_MILESTONE.md).
