# ARROWFALLEN — A Cidade Que Me Enterrou

Jogo em Lua para **LÖVE 11.5**, em desenvolvimento. A campanha começa na
cripta da Colina e leva ao Refúgio: explore a cidade, cuide da água e prepare a partida.
O mundo usa pixel art gerada por código, fonte bitmap com acentos e câmera
com filtro nearest.

**Nova Campanha** abre o novo Refúgio: cidade-santuário ao ar livre, mirante,
praça do Marco e cinco casas com interiores acessíveis. Colina/cripta são
locais desse reino. Andlar tem apenas um chão provisório com ida e volta;
sua cidade será construída depois. A direção atual está em
[PLANO_REFUGIO_ANDLAR.md](docs/PLANO_REFUGIO_ANDLAR.md).

Saves anteriores continuam no percurso e na geografia antigos, com suas
quests e distritos preservados. Para conhecer o Refúgio novo, inicie **Nova
Campanha**; essa opção substitui o save existente.

## Jogar

Instale o LÖVE 11.5. No Windows, abra **`Jogar.bat`** na raiz; ele procura
`C:\Program Files\LOVE\love.exe` ou o executável no PATH. Pelo terminal,
com o diretório de trabalho na raiz do projeto:

```text
love .
```

No título, **ENTER** começa a campanha ou continua o save existente.
**N**, quando há um save, inicia uma campanha nova e apaga o progresso salvo.

## Controles da campanha

| Tecla | Ação |
| --- | --- |
| WASD | Mover pela região |
| E | Conversar ou interagir com um objeto próximo |
| E / ENTER, no diálogo | Completar o texto e avançar |
| Números, no diálogo | Escolher uma opção |
| ESC / Q, no diálogo | Fechar a conversa |
| ESC | Pausar/retomar; na arena, abre as ações |
| WASD, na arena | Andar livre pelas células azuis — nada é gasto até confirmar |
| ESPAÇO / ENTER, na arena | Abrir ações (ATACAR · FERRAMENTA · AGIR · DEFENDER · USAR · POUPAR · ESPERAR · FUGIR); encerrar um turno já usado |
| I, na arena | Inspecionar unidades — papel, vida e intenção anunciada (sem custo) |
| A / D, no menu | Navegar as ações |
| ENTER, no menu | Confirmar a opção — golpes pedem mira antes |
| WASD, na mira | Escolher a direção do arco ou do escudo |
| ESC, na arena | Voltar um passo; no campo aberto, abre as ações em FUGIR |
| ENTER, na pausa | Retomar |
| B, na pausa | Abrir a bolsa — equipar peças e usar consumíveis; provisão cura na estrada também |
| Q, na pausa | Salvar a posição e voltar ao título |
| TAB | Abrir/fechar o guia; ESC ou ENTER também fecham |
| F11 | Alternar tela cheia |
| F2 | Alternar efeitos de movimento reduzidos |
| M | Alternar áudio |

## O que está implementado

- Refúgio novo com praça, pedra monumental, escadaria/mirante, jardins,
  ruas em circuito e terraço; capela, cozinha, pensão, oficina e escola têm
  entradas locais e interiores utilizáveis. Camas e refeição recuperam vida.
- Arco inicial: recuperar pertences e resolver a grade na cripta, preparar o
  equipamento na oficina a leste, desobstruir a cisterna ao sul da praça e
  escolher concluir/despedir-se no Marco. A pedra acende ANDLAR; interaja
  novamente para viajar. Não exige quests opcionais nem os distritos antigos.
- Andlar provisório com piso explorável, placa e pedra de retorno ao mesmo
  Marco do Refúgio. Sem cidade, distritos ou campanha nova implementados ali.
- Conteúdo legado preservado para saves anteriores e cenas de teste:
  Oficinas, Mercado, Reservatório, Salões e vestíbulo da Fundação.
- Conversas com opções, cenas de chegada por região, subquests dos moradores
  do Refúgio e lembranças do casal em cada mundo. Revisitas não repetem
  a abertura; mortes devolvem o jogador à sepultura sem desfazer escolhas.
- Estado persistente para etapas, decisões, objetos, localização dos
  personagens e encontros concluídos. A grade aberta e os objetos usados
  conservam seu estado ao revisitar uma região.
- Save versionado em `cidade_save.lua`, no diretório de dados do LÖVE. O jogo
  salva em checkpoints de progressão, interações e viagens; sair pela pausa
  também salva a posição atual.
- Arena tática por turnos ao tocar um encontro no mapa: inimigos anunciam
  intenções com ordem estável, o jogador se reposiciona livre nas células
  azuis e confirma uma ação por um menu de comandos — arco com mira, golpe
  de ferramenta corpo a corpo, AGIR (interações por inimigo), defesa
  frontal, itens da bolsa, poupar, espera ou retirada. Derrotar não é
  matar: a maioria dos encontros aceita acordo.
- Cenário e atores em pixel art, animações com anim8, fonte bitmap e efeitos
  de voz na datilografia dos diálogos.
- Faixas originais em WAV e efeitos sintetizados.

As regiões seguintes, chefes finais e finais constam nos planos de produção.

## Sistemas anteriores

O protótipo de ação em tempo real continua no código e nas cenas internas de
teste. Ele reúne prática, expedição procedural de três andares, arco carregado,
escudo, terreno minerável, pilares que tombam, buracos, inimigos e chefes,
loja, desafios secretos, XP, ecos e dezoito cartas.

Esses sistemas sustentam testes e componentes reutilizados pela campanha.
O fluxo normal do título já inicia a campanha; os controles de arco, mineração
e recompensas do protótipo não descrevem o combate atual da campanha.

## Documentação

Comece por este README para saber o que é jogável. Depois consulte só a frente
de trabalho necessária; documentos de design não são comprovação de entrega.

| Fonte | Uso e estado |
| --- | --- |
| [Refúgio e Andlar](docs/PLANO_REFUGIO_ANDLAR.md) | Direção espacial atual, recorte implementado e Andlar futura |
| [Base narrativa](docs/BASE_NARRATIVA.md) | Premissa, responsabilidades, pacto e limites criativos |
| [Campanha e fichas](docs/PLANO_CAMPANHA.md) | Arcos preservados; geografia anterior a adaptar aos reinos |
| [Combate e inventário](docs/BATALHA_ACT_MERCY.md) | Regras atuais e mecânicas explicitamente adiadas |
| [Guia de escrita](docs/GUIA_ESCRITA_DEVIN.md) / [guia visual](docs/GUIA_VISUAL.md) | Critérios para texto e arte |
| [QA da campanha](docs/QA_MUNDOS.md) / [testes](tests/README.md) | Percurso, persistência, evidência e execução |

Lore adicional: [tratamento](docs/A_CIDADE_QUE_ME_ENTERROU.md),
[história e lugares do Refúgio](docs/REFUGIO_HISTORIA_E_LUGARES.md),
[personagens](docs/PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md),
[cenas finais](docs/CENAS_REVELACAO_E_FINAIS.md) e
[referência de storytelling](docs/GUIA_STORYTELLING_UNDERTALE.md).
Personagens redesenhados e finais permanecem propostas/futuro.

[DESIGN](docs/DESIGN.md) descreve o protótipo interno em tempo real.
O estudo em `docs/historico/` registra uma planta anterior; ambos são legado.
Em conflito espacial, prevalece Refúgio/Andlar; para comportamento entregue,
compare `src/campaign.lua`, `src/refugio.lua`, `src/regions/`, `src/battle.lua`
e testes. Dez fichas não equivalem a dez reinos ou dez destinos de teleporte.

## Verificação e pacote

Execute os dois comandos na raiz:

```text
love . --test
love . --ui-test
```

A suíte principal cobre geração, terreno, inimigos, combate do protótipo,
diálogos, loja, exploração da campanha (incluindo as regiões novas), batalha
tática, persistência e pixel art. A suíte de interface verifica callbacks,
movimento, desenho e redimensionamento.
Os resultados ficam em `test-results.txt` e `ui-test-results.txt`;
[tests/README.md](tests/README.md) detalha a cobertura.

Screenshots e PNGs de teste ficam em **`screenshots/`**, conforme
[AGENTS.md](AGENTS.md). Para capturar uma cena, execute da raiz:

```text
love . --scene=colina --screenshot=screenshots/colina.png
```

**Concord, Baton, anim8, Flux e Ripple** estão vendorizados. Versões e licenças
estão em [docs/LIBRARIES.md](docs/LIBRARIES.md).

O pacote em `build/Windows` pode estar desatualizado.
`python tools/package.py` reconstrói o `.love` e, quando há runtime instalado,
a versão portátil de Windows com suas licenças.
