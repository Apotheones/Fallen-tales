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
ferramentas, descoberta, remoção das compras de mapas e mineração de uma
entrada secreta. Desafios de combate/pontaria só recompensam ao concluir;
retorno não exige ferramentas, alvos acertados persistem e revisitas não
duplicam recompensas. Descida preserva a tentativa.
O catálogo continua oferecendo três escolhas após adquirir as melhorias únicas;
a recompensa de ferramentas devolve três picaretas.

Terreno verifica custo/adjacência/zero,
proteção, solo preservado, buracos, prioridade fatal, investidas, quatro lados
e hits mistos do pilar, segmentos independentes, esmagamento, avisos congelados,
quedas determinísticas, revisitas e reset. Busca cardinal em 100 seeds valida
TODAS as chegadas ligadas a TODAS as saídas e inimigos sem ferramentas nas
direções e combinações de queda. A faixa protegida permanece livre. Cristais,
impactos e linhas de tiro continuam limitados ao aviso.

Combate verifica apenas arco: carga, hold pronto sem tiro, soltura única,
cancelamento cedo/guarda/recuperação, alcance, paredes, reservas de movimento,
armadura, avisos, esquiva, escudo, recompensas, cristais, chefe e geração.
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
novo gesto após cancelamento. E não compra ou revela mapas; ENTER após vitória
desce e preserva a tentativa.
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
