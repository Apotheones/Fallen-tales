# Direção ambiental HD — composição e luz por região

Autora: Calina (direção ambiental). 04/10/2026. Status: direção para Fases 1–2.
Alimenta **Traço** (DSL 64px: tilesets, props, massas) e **Prisma** (render:
luz, G-buffer, LUT). Companheiro de [MEGAPLAN_VISUAL_HD.md](MEGAPLAN_VISUAL_HD.md)
— este doc diz *o que cada lugar deve contar e como a luz conta*; o megaplan diz
como a tecnologia funciona. Geografia segue [PLANO_REFUGIO_ANDLAR.md](PLANO_REFUGIO_ANDLAR.md)
e `build/planta-refugio-rev3.md`; vida do lugar segue `build/vida-refugio-rev2.md`.

## 0. Tese e gramática

**Tese do mundo:** um santuário funerário habitado. Toda região equilibra duas
forças — *a pedra que guarda os mortos* e *o fogo que guarda os vivos*. Onde a
pedra domina (Colina, Necrópole) o fogo é pequeno e precioso; onde o fogo
domina (Refúgio, Mercado) a pedra está sempre presente na base, no muro, no
marco. Referências: Firelink/Majula para o abrigo, Eastward para densidade e
luz de tela inteira.

**Gramática de composição (vale para todo tileset):**

- **Compressão → revelação.** Corredores estreitos desembocam em largos; a
  praça nunca se vê inteira de uma entrada. Ruas são linhas carved, não cunhas
  pintadas.
- **Oclusão como profundidade.** Fachadas, beirais e arrimos escondem parte do
  quadro; ver tudo de uma vez é o sintoma do mapa atual.
- **Vazio é decisão.** Espaço limpo só onde a cena precisa de respiro (a cova
  do protagonista, o eixo do palco, a bebida do terraço). Gramado vazio entre
  massas é o defeito a matar — preencher com uso, não com ruído.
- **A função mora na forma.** Massas distintas por função (capela alta c/
  frontão, pensão longa c/ varanda, forja baixa e larga). Cinco `casa`
  idênticas em pentágono é o contraexemplo aprovado pelo rev3.
- **Borda de lugar.** Toda sub-área tem borda legível: mureta, portão, canteiro,
  desnível, mudança de piso. Zona não é rótulo sobre o mesmo tapete.
- **Passagens desimpedidas.** Props nunca em soleira, boca de escada ou
  corredor de camas — regra de placement, não estética.

**Gramática de luz (vale para todo o render):**

- **Uma luz conta a hora.** Cada região tem *um* clima luminoso dominante (sol
  baixo, crepúsculo, vela, faixa de cobertura). As demais fontes são locais e
  pontuais — nunca competem com o clima.
- **Quente = presença, frio = ausência.** O ember marca onde a vida acontece
  (fogo, janela, lamparina); o frio marca pedra, água, distância. O contraste
  quente/frio *é* a narrativa do santuário habitado.
- **Sombra projetada conta a direção.** Sombras longas e coerentes com a fonte;
  nunca elipse embaixo do pé. Em exteriores a sombra é informação de hora do
  dia; em interiores, de janela/fresta.
- **Emissivo é acento, não enfeite.** Bloom só no emissivo (contrato fase0):
  glifo jade do Marco, chama, brasa, runa, cristal, pingente. Se algo brilha,
  tem motivo na ficção.
- **Escuro legível ≠ preto.** Ambiente nunca zera o albedo; a região mais
  escura (Necrópole) ainda deixa piso e paredes legíveis. A prova
  `prova-hd-8luzes-1920.png` escurece demais: corrigir com ambiente por região
  (tabela §3), não com mais luzes.

**Cores funcionais protegidas** (nunca tingidas por LUT nem por ambiente):
danger vermelho (telegraphs, vida), select/gold de foco, jade mágico. O grading
regional vale para material e atmosfera — nunca para informação.

## 1. Paleta emocional e clima por região

| Região | Emoção-alvo | Clima de luz | Ambiente¹ | Grade (LUT) |
|---|---|---|---|---|
| Refúgio | abrigo em manutenção; fim de tarde que não acaba | sol baixo âmbar + céu lavanda | 0.55–0.65 | `refugio` (quente) — existe |
| Colina | peso contido; o lugar onde a própria morte começa | crepúsculo violeta, sem sol | 0.35–0.45 | `colina` (frio/violeta) — existe |
| Necrópole | arquivo da memória; quietude de escrivaninha | penumbra esverdeada, ilhas de luz | 0.28–0.35 | `necropole` (esverdeado) — existe |
| Salões | hospitalidade encenada; teatro virado moradia | luz de vela, palco > plateia | 0.30–0.40 | `saloes` (dourado escuro) — existe |
| Oficinas | trabalho que continua; brasa sob ferro | contraste brasa quente × cinza frio | 0.35–0.45 | **propor `oficinas`** (cinza quente) |
| Reservatório | máquina que virou jardim; paciência úmida | luz em faixas sob vigas + reflexo d'água | 0.40–0.50 | **propor `reservatorio`** (calcário) |
| Mercado | comércio de improviso; ocupado e morno | sol filtrado por toldos remendados | 0.50–0.60 | **propor `mercado`** (ocre morno) |
| Fundação | privacidade pequena conquistada | retângulos de janela + lâmpadas | 0.35–0.45 | **propor `fundacao`** (cal azulada) |

¹ Ambiente = piso do lightmap (fundo da `ambient` em lighting.lua). Valores de
direção; Prisma calibra. O `ambient` atual (0.08) serve cripta/prova — não
regiões externas nem interiores habitados.

**Nota de implementação:** `Palettes.grades` hoje cobre refugio/colina/
necropole/saloes. Faltam quatro linhas — direção de tinta abaixo (Prisma
refina na LUT; são multiplicadores por faixa tonal, não cores novas):

- `oficinas` = shadow {.45,.48,.60} mid {.92,.92,.95} light {1.05,.96,.80}
- `reservatorio` = shadow {.42,.55,.52} mid {.88,.97,.88} light {.95,1.05,.92}
- `mercado` = shadow {.55,.46,.38} mid {1.02,.94,.75} light {1.12,1.00,.72}
- `fundacao` = shadow {.48,.50,.62} mid {.92,.94,1.00} light {1.02,1.00,.95}

## 2. Região a região

### REFÚGIO — "o fogo que guarda gente" (a prova do padrão)

**Conta:** pedra que lembra nomes + vida doméstica que continua. O povoado já
sabia receber antes da catástrofe; a arte mostra uso e reparo, nunca abandono
nem prosperidade.

**Paleta emocional:** sálvia de relva gasta + reboco creme ao sol + madeira
âmbar + mar lavanda ao fundo. Grade `refugio` quente: sombra vinho, meio creme,
luz âmbar de vela. O azul-violeta mora só na sombra e no mar — o dia é quente.

**Fontes de luz:**
- *Dominante:* sol de fim de tarde vindo do SO (do vale/mar — inferior-esquerda
  na tela). Modelo atual: fonte pontual de raio > vista e z alto ≈ direcional.
  Cor ~ (1.0, .80, .55). Sombras longas projetadas para NE — casas, marco e
  atores.
- *Locais:* braseiro do posto de vigia no mirante (ember, r~4 cél, flicker);
  lampião de poste na praça; janelas mornas (emissivo ei~0.4–0.6, pequenos
  pools); **inscrições jade do Marco** (ei~0.8, bloom só nos glifos); velas da
  capela; brasa do quintal da forja; fogão da cozinha.
- *Céu:* faixa de horizonte lavanda→creme atrás do parapeito; o mar reflete o
  mesmo âmbar frio — contraste com o solo quente.

**Densidade:** alta nas bordas — a vida se encosta em fachadas, caminhos e
parapeitos (varal, cadeira de varanda, tigelas, recipientes no poço, lenha,
canteiros). Centro da praça respira em volta do Marco; fundos de cota e
toppings de relva ficam limpos por decisão.

**Motivos recorrentes:** nomes gravados/letras; pano e varal (roupa = gente);
recipiente e tigela; canteiro preparado→florido; remendo com acabamento
diferente ("trabalho reconhecível"); caminho de terra batida sobre relva;
parapeito com vista.

**Ponto de identidade:** Marco dos Nomes (nomes que acendem) + panorama do
mirante sobre telhados.

**Anti-padrão:** gramado vazio, casas idênticas, brilho de lugar novo, névoa
no piso jogável.

### COLINA — "o peso contido" (cripta + sepultados)

**Conta:** a violência fundadora em escala doméstica — uma sepultura comum, não
um monumento. O cuidado (mato cortado, flor sob pedra) mostra que alguém volta.

**Paleta emocional:** ardósia violeta fria + relva cinzenta + tecido gasto +
ouro velho *só* no detalhe de cuidado (#D8BA78). Grade `colina`: a sombra
afunda em índigo-violeta; nada aquece além do fogo local.

**Fontes de luz:**
- *Dominante:* crepúsculo sem sol — luz rasante fria de zênite
  (violeta-azul ~ (.55,.50,.75)), ambiente médio-baixo. Sombras curtas e frias
  (fonte alta): é a ausência de sol que pesa.
- *Locais:* braseiro/velas do pátio de velório (ember pequeno, precioso — a
  única cor quente da região); a **saída** para o refúgio esquenta
  gradualmente (gradiente cripta→cripúsculo→âmbar da vila — a transição é a
  dramaturgia do despertar); marca partida da vedação com resíduo violeta
  (emissivo discreto, ei~0.3 — não é farol).
- *Cripta:* quase sem luz natural — claridade crescente na direção da saída;
  tocha/vela onde o jogador precisa ler espaço.

**Densidade:** média, em manchas — lápides em 2–3 agrupamentos irregulares
(antigas gastas × recentes improvisadas com pano/retalho), nunca em fila
militar. A cova do protagonista tem clearing próprio: o vazio ali é decisão.

**Motivos recorrentes:** lápide arredondada gasta × marca improvisada; pano
preso sob pedra; relva curta mantida; terra revolvida; tampa deslocada e borda
clara protegida; ferramenta deixada; a árvore com roupas secando na borda —
onde a colina toca o doméstico.

**Ponto de identidade:** sepultura com tampa deslocada + arco da casa
funerária (única vertical do mapa).

**Anti-padrão:** cemitério gótico, névoa que esconde leitura, lápides em
grade, ouro decorativo espalhado.

### NECRÓPOLE DOS NOMES — "a burocracia da memória" (futura, mapa 8)

**Conta:** os mortos viraram registro — gavetas, placas, atas. A prova do
assassinato mora num arquivo, não numa masmorra.

**Paleta emocional:** pedra ardo #333D49 + piso gasto #777F89 + papel #D6C9A7
+ cobre interativo #BC8053 (o cobre marca o que se pode tocar — ponte
cor↔função). Grade `necropole`: meio e sombra esverdeados, luz amarelada de
papel velho.

**Fontes de luz:**
- *Dominante:* penumbra verde-cinza de arquivo — sem luz do céu.
- *Locais:* lamparinas de leitura criando **ilhas de trabalho** (pools âmbar
  esverdeado r~3 cél) sobre mesa, gaveta e ata; frestas/claraboias com god
  rays discretos em poeira suspensa — a poeira é o único movimento do lugar;
  cobre dos interativos com emissivo leve ao alcance (ei~0.3).

**Densidade:** rítmica e alta nos corredores (fileiras de túmulos/gavetas criam
cadência visual), largos respirados nos três recintos — arquivo, mesa da ata,
recinto do rito.

**Motivos recorrentes:** fileira de gaveta/tumba; placa de nome (repetição);
gaveta aberta × fechada (estado); papel/pergaminho; cipreste partido na
entrada; armário inclinado; mesa circular de pedra.

**Ponto de identidade:** armário inclinado do arquivo / mesa circular do rito.

**Anti-padrão:** horror/assombração (é escrivaninha, não susto), névoa
dinâmica (a ficha veta), escuridão total.

### SALÕES DAS VITRINES — "a hospitalidade encenada"

**Conta:** um teatro que abrigou gente e aprendeu a dirigir a própria
plateia. Calor real com uma camada de controle — Beltran recebe, mas programa.

**Paleta emocional:** pedra vinho + vermelho de cortina remendada + ouro
gasto + vela #E9CF9B. Grade `saloes` dourado escuro: sombra vinho, luz âmbar
de cera.

**Fontes de luz:**
- *Dominante:* **lustre incompleto sobre o palco** — a fonte central da
  região, ember/âmbar, r~5–6 cél, cristais emissivos individuais (ei~0.7) no
  módulo emissivo. O palco fica mais claro que a plateia: a inversão teatral é
  a direção.
- *Locais:* pools de vela (r~2–3 cél) em mesas, criados, pontos de convivência;
  brasas da cozinha auxiliar; frestas frias do corredor de manutenção — o
  contraste quente/cena × frio/bastidores conta os dois mundos do lugar.

**Densidade:** alta e *doméstica* — camas baixas, cabides, louça lavada,
brinquedos improvisados dentro de arquitetura cerimonial (arcos altos). A
densidade mostra apropriação: cada objeto nobre tem uso comum em cima.

**Motivos recorrentes:** cortina vertical remendada; palco raso; cadeira
reservada com o mesmo tecido da cortina; instrumento; cartaz de programa;
cama baixa entre arcos; tapume/escora em parede nobre.

**Ponto de identidade:** lustre incompleto sobre palco raso.

**Anti-padrão:** festa ameaçadora, tudo monocromático vinho, igreja genérica.

### OFICINAS DE DENTRO — "o trabalho que continua"

**Conta:** produção sob escassez — ferramenta, ferrugem e a autoridade de quem
mantém o lugar funcionando.

**Paleta emocional:** ferro cinza-azul + ferrugem #A26045 + tecido de trabalho
#9F9475 + detalhe de autoria #D1BC7E. Grade proposta `oficinas`: sombra fria
de metal, luz morna de brasa — o hue-shift quente/frio aqui é por *zona*, não
global.

**Fontes de luz:**
- *Dominante:* cinza difuso de claraboias sujas/portas — luz alta, apagada,
  azul-acinzentada.
- *Locais (a assinatura):* **brasas e forja** — pools ember intensos e
  *pequenos* (r~3–4 cél, flicker) dentro de um ambiente frio. A brasa é o coração
  da sala; o resto é metal esperando. Metal polido de ferramenta utilizável =
  highlight físico (rampa `iron` degraus altos), não emissivo.

**Densidade:** alta nos pátios de trabalho (bancadas, lingotes, roda, peças);
corredores estreitos e depósito atrás de grade mantêm passagem limpa — o lugar
trabalha, não se enfeita.

**Motivos recorrentes:** escora vertical/inclinada; bancada baixa retangular;
roda de trabalho (parada → movida por marco); grade de depósito; mancha de
trabalho no piso; escora torta sustentando a saída.

**Ponto de identidade:** roda de trabalho parada na entrada / conjunto de
ferramentas visível atrás da grade.

**Anti-padrão:** fogo uniforme em tudo (apaga a hierarquia brasa×metal), fábrica
industrial limpa.

### RESERVATÓRIO (JARDINS) — "a máquina que virou jardim"

**Conta:** infraestrutura abandonada que a paciência transformou em canteiro.
A água manda no desenho; as pessoas negociam com ela.

**Paleta emocional:** calcário #687269 + água funda #365B62 + musgo #6C8054 +
ferragem #A67D4D + flor/luz #D6B66C. Grade proposta `reservatorio`: sombra
verde-água, luz calcário amarelada.

**Fontes de luz:**
- *Dominante (a assinatura):* **luz em faixas** — sol entrando pelas vigas da
  cobertura arruinada sobre o jardim: listras paralelas de luz quente
  projetadas (sombras de viga em série), com motes/poeira nos feixes. É a única
  região onde a sombra projetada faz *padrão*, não só direção.
- *Locais:* reflexo frio esverdeado subindo dos canais para as bordas (luz
  ambiente local tingida, r~2–3 cél sobre a água); lamparinas quentes na sala
  das comportas e no posto de Ivo; ala leste interditada mais escura.

**Densidade:** média-alta, *ordenada em faixas* — canteiros em linhas, canais
retos, passarela e caminho seco como eixos. O desenho é agronômico, não
acumulado.

**Motivos recorrentes:** canal reto com borda clara (água ≠ buraco: leito
visível); canteiro em faixa; régua de nível na parede; comporta/volante de
ferragem; musgo nas juntas; vigas mortas da cobertura.

**Ponto de identidade:** torre baixa com régua de nível / jardim sob as vigas.

**Anti-padrão:** água como vazio preto, cristal decorativo solto, umidade =
escuridão.

### MERCADO DAS ESCORAS — "o comércio de improviso"

**Conta:** a feira que sobreviveu remendando a si mesma — cada banca é um
ofício, cada toldo é uma mão diferente.

**Paleta emocional:** pedra morna #514E46 + madeira #876344 + **ocre de tecido
#C59A56** + ferrugem + luz clara #E4D8B3. Grade proposta `mercado`: o mais
quente e claro dos interiores — meio-dia filtrado.

**Fontes de luz:**
- *Dominante:* **sol através dos toldos** — manchas de luz quente tingida pela
  cor de cada lona sobre sombra morna (god rays discretos nas bordas das
  lonas). O toldo amarelo do campanário cortado projeta a maior mancha: é o
  farol da região e lê de longe.
- *Locais:* lampiões de banca (ember pequenos) nos cantos de negócio; brasa do
  forno desmontado se reacendido por marco.

**Densidade:** **a maior do jogo** — a feira é acúmulo organizado: bancas,
balcões, grades abertas de depósito, louça, carro de peças travando a rota.
Mas cada acúmulo tem ofício legível; bugiganga aleatória é ruído, não mercado.

**Motivos recorrentes:** escora inclinada; toldo remendado em patchwork (cada
toldo uma "mão"); banca sobre rodas; balcão com portinhola; grade aberta (não
baú); placa de loja torta; roda.

**Ponto de identidade:** toldo amarelo preso no campanário cortado; balcão de
Ema com placa torta + panela azul.

**Anti-padrão:** barracas em fila militar, mercado sem gente nem mercadoria
específica, simetria.

### FUNDAÇÃO (QUARTOS) — "a privacidade pequena conquistada"

**Conta:** dormitórios improvisados sobre as fundações antigas — portas
numeradas, varal no pátio, uma janela empenada que ainda deixa entrar o sol.

**Paleta emocional:** pedra neutra #575B60 + cal lascada #B6B2A7 + madeira
encerada #78563F + tecido azul #657A86 + interação #D7AC5D. Grade proposta
`fundacao`: cal frio azulado — o interior mais "dia cinza" do jogo.

**Fontes de luz:**
- *Dominante:* **retângulos de janela** — manchas geométricas de luz solar nas
  paredes/piso (a "mancha de sol" da ficha, agora dinâmica de verdade):
  projeção dura, âmbar-fria, formando os únicos pools grandes do mapa.
- *Locais:* lâmpadas pequenas de quarto (pools individuais fracos — cada cama
  sua luz); claridade de porta aberta no corredor.

**Densidade:** média, horizontal — fileiras baixas de camas/divisórias, paredes
longas; o pátio com varal é o pulmão. Diferenciar roupa esquecida × em uso
(estado, não rótulo).

**Motivos recorrentes:** porta numerada (repetição com variação); varal;
divisória; cobertore remendado; janela (e a empenada); mobiliário estocado;
mesa do arquivo atravessando o acesso.

**Ponto de identidade:** corredor de portas numeradas / pátio com varal.

**Anti-padrão:** virar cripta (a ficha avisa), quartos idênticos em precisão
militar, mobília de mostruário.

## 3. Tabela de luz para o Prisma (modelo atual: pontual + z, ≤8/fonte)

| Região | Dominante (aproximação) | Cor dominante | Fontes locais | Atmosfera |
|---|---|---|---|---|
| Refúgio | pontual z~4 cél, raio > vista, SO | âmbar (1.0,.80,.55) | braseiro, lampião, janelas, jade Marco, velas | motes nos feixes, fumaça chaminé, névoa zero no piso |
| Colina | pontual z~6, raio > vista, zenite N | violeta (.55,.50,.75) | velas velório, gradiente à saída, resíduo vedação | nenhuma (ar parado é a textura) |
| Necrópole | ambiente só — sem dominante | verde-cinza (.75,.85,.75) | lamparinas r~3, god rays frestas | poeira suspensa nos raios |
| Salões | lustre pontual z~2.5, r~6 sobre palco | cera (1.0,.82,.55) | velas r~2-3, brasa cozinha, frestas frias | poeira/incenso leve sobre plateia |
| Oficinas | difusa alta fria (z~6, fraca) | cinza (.75,.80,.85) | brasas r~3-4 flicker, forja | brasas sobem fagulha (emissivo animado) |
| Reservatório | sol raso + **sombras em faixa de vigas** | quente (.95,.85,.6) | reflexo água (ambiente tingido local), lamparinas | motes nos feixes, vapor d'água leve |
| Mercado | sol filtrado toldos (mesma dominante + patches) | claro (1.0,.9,.7) | lampiões de banca | poeira em manchas de luz |
| Fundação | retângulos de janela (projeção dura) | âmbar-frio (.9,.85,.7) | lâmpadas de quarto fracas | mínima — o lugar é seco |

- Sol/fresta como **pontual de raio > vista e z alto** aproxima direcional com
  o modelo existente; se a atenuação ainda marcar gradiente, é caso real de um
  modo `directional` — sinalizar antes de hack.
- Emissivos guiam o bloom: chama ei=1.0, glifo jade ei~0.8, janela ei~0.5,
  lamparina ei~0.6, resíduo/cobre interativo ei~0.3. Abaixo de .35 não estoura.
- Sombras projetadas: occluders com `height` — casas/marco no Refúgio (longas,
  NE), vigas no Reservatório (padrão em faixas), janelas na Fundação (retângulos).
- Flicker só em fogo real (braseiro, vela, brasa); lampião/janela/jade estáveis.
- `--reduced-motion`: flicker e drift zeram, informação luminosa permanece.

### 3.1 Luz que vive × luz quieta (adendo vida)

O mundo respira por **dois mecanismos distintos** — não confundir:

- **Flicker** (tempo real): só fogo aberto. Amplitude por material: chama de
  braseiro ±12–15% (2 senoides, contrato fase0); vela ±20% mais rápida e de
  raio menor; brasa ±8% lenta; lampião a óleo ±4% quase imperceptível.
- **Estado** (marco/escolha): janela que acende quando a casa habita, nome do
  Marco que acende, brasa da forja que pega, vela do velório que apaga. Não
  existe ciclo dia/noite — luz viva muda por progresso, nunca por relógio.
  Transição com fade 1–2s; nada dá pop.

| Fonte | Tipo | Comportamento |
|---|---|---|
| Braseiro/fogueira | viva | flicker real; fagulha ocasional no emissivo |
| Vela (capela, velório, salões) | viva | flicker rápido fraco; pode apagar por estado |
| Brasa forja/fogão | viva | flicker lento + fagulha; acende por marco |
| Lampião poste/banca | quase-viva | flicker mínimo; acende por estado |
| Janela | viva por estado | acende conforme a casa habita; nunca pisca |
| Jade (Marco, runa, selo) | quieta | emissivo constante; muda só por marco — é lei, não fogo |
| Lamparina de trabalho | quieta | escrivaninha não performa |
| Resíduo vedação/cristal/cobre | quieta | ei baixo constante, abaixo do bloom |
| Sol/fresta/faixa de viga | quieta | assada no bake; move só se houver hora |
| God rays/motes/fumaça | atmosfera viva | drift lento *dentro* do feixe — matéria, não fonte |
| Reflexo d'água (Reservatório) | viva lenta | shimmer ±3% ~0.1Hz; some no reduced |

**Regras anti-discoteca:**

- ≤2 fontes com flicker real por tela; vivas agrupam-se no eixo quente
  (fogo que guarda gente), nunca espalhadas competindo por atenção.
- O que é lei/informação não pulsa: jade, selo, telegraph, cobre interativo.
- O que é trabalho não performa: lamparina, lâmpada de quarto.
- Em movimento reduzido: flicker/drift zeram e a fonte assume cor e raio
  médios; mudanças de estado aplicam instantâneo — a informação não morre.

## 4. Notas para o Traço (DSL 64px)

- **Rampas por papel, não por região.** A rampa já carrega hue-shift; o que
  muda por região é *qual* rampa domina: Refúgio = plaster/wood/earth/sea;
  Colina = stone(fria)/moss/bone; Necrópole = stone/bone/paper(cloth? usar
  bone+earth para papel); Salões = clothWarm/wood/gold; Oficinas = iron/rust/
  wood; Reservatório = stone+moss+sea(água)/rust(ferragem); Mercado = clothWarm
  /wood/earth; Fundação = plaster/wood/cloth(azul via grade).
- **Altura é leitura de material:** juntas de laje -1, topo de muro +2–4,
  relevo de glifo +1, lápide +2. Normal chato no piso de exploração — relevo
  pertence a borda, ornamento e vertical.
- **Piso recua:** textura desenhada mas calma (lajes, terra, tábuas); variação
  por seed estável; ornamento concentrado em borda e junção de materiais.
- **Fachadas 64px:** topo+frente+cantos com o oblíquo real — frente sul
  clara/quente, face cega dois degraus abaixo, beiral projeta sombra própria.
- **Emissivo se autora junto:** glifo jade, chama, brasa, janela — marcado no
  canal e do sprite, nunca pintado depois.
- Props novos pedidos pela direção (a Botica detalha a lista): braseiro com
  cinza, varal + peças, lampião/poste, canteiro 2–3 variações, balde de
  têmpera, oferenda, placa torta, toldo patchwork, gaveta tumba aberta/fechada,
  régua de nível, comporta/volante, lustre incompleto, cortina remendada,
  porta numerada, janela empenada.

## 5. Cena-alvo `--scene=refugio-hd` (Fase 1, combinado com Prisma)

Slice = canto norte da **Praça dos Nomes** (~18×12 cél): fachada sul da pensão
fechando o terço superior (beiral + quina com face cega), Marco à esquerda do
centro com uma inscrição jade acesa, lampião/braseiro à direita do Marco,
caminho de terra entrando pelo canto inferior-esquerdo, viajante no centro,
Aurel junto ao Marco, banco+mesa no canto inferior-direito. Sol baixo do SO,
sombras longas para NE, janela acesa como terceiro ponto quente. O que ela
deve contar: *a pedra que guarda nomes e o fogo que guarda gente — numa tela
só, sem nenhum gramado vazio.*

## 6. Verificação visual (o que a Calina julga nas capturas)

- A cena conta a emoção da linha da região em cinza? (silhueta + valor)
- Uma luz domina e as outras são locais? Há cor quente onde há vida?
- Sombra projetada coerente e longa onde o sol existe; padrão de faixas no
  Reservatório; retângulos na Fundação?
- Vazio = decisão? Densidade junto a fachadas/caminhos/bordas?
- Bloom só no emissivo; funcionais intocados pelo grading; piso recuado.
- Ambiente não zera albedo; sem banding de falloff (lightScale já ajuda).
- Antes/depois na mesma posição e janela; 900/1120/1920.

## 7. Aberto

- Hora do dia canônica do Refúgio (fim de tarde proposto aqui) — confirmar com
  narrativa; se houver variação por estado da campanha, LUT por hora vira Fase 5.
- Necrópole, Fundação e grades novas: aprovar tintas na primeira captura LUT.
- Andlar (região futura): direção própria quando a cidade for desenhada —
  hoje é chão de chegada; mantém grade neutra.
