# ARROWFALLEN — A Cidade Que Me Enterrou

Jogo em Lua para **LÖVE 11.5**, em desenvolvimento. A campanha começa na
Colina e leva ao Refúgio: explore, converse com os moradores e abra passagens.
O mundo usa pixel art gerada por código, fonte bitmap com acentos e câmera
com filtro nearest.

Este README descreve a entrega do commit `d5bcb84`. A campanha completa de
dez regiões está planejada; o recorte implementado reúne **Colina e Refúgio**.

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
| ESC | Pausar/retomar; na arena, voltar à exploração |
| ENTER, na pausa | Retomar |
| Q, na pausa | Salvar a posição e voltar ao título |
| TAB | Abrir/fechar o guia; ESC ou ENTER também fecham |
| F11 | Alternar tela cheia |
| F2 | Alternar efeitos de movimento reduzidos |
| M | Alternar áudio |

## O que está implementado

- Colina e Refúgio com mapas autorais, colisão, objetos interativos e passagens.
- Conversas com opções, introdução da campanha e chegada ao Refúgio.
- Estado persistente para etapas, decisões, objetos, localização dos personagens
  e encontros concluídos. A grade aberta e os objetos usados conservam seu estado
  ao revisitar uma região.
- Save versionado em `cidade_save.lua`, no diretório de dados do LÖVE. O jogo
  salva em checkpoints de progressão, interações e viagens; sair pela pausa
  também salva a posição atual.
- Entrada em uma arena separada ao tocar um encontro no mapa e retorno à
  exploração com ESC.
- Cenário e atores em pixel art, animações com anim8, fonte bitmap e efeitos
  de voz na datilografia dos diálogos.
- Oito faixas originais em WAV e efeitos sintetizados.

**O combate da campanha ainda é uma estrutura inicial:** a arena é carregada,
mas intenções, ações, resolução por turnos e negociação ainda não estão
implementadas. As demais regiões, chefes e finais constam nos planos de produção.

## Sistemas anteriores

O protótipo de ação em tempo real continua no código e nas cenas internas de
teste. Ele reúne prática, expedição procedural de três andares, arco carregado,
escudo, terreno minerável, pilares que tombam, buracos, inimigos e chefes,
loja, desafios secretos, XP, ecos e dezoito cartas.

Esses sistemas sustentam testes e componentes reutilizados pela campanha.
O fluxo normal do título já inicia a campanha; os controles de arco, mineração
e recompensas do protótipo não descrevem o combate atual da campanha.

## Documentação

- [Plano da campanha](docs/MEGAPLAN_CAMPANHA.md): etapas e decisões de implementação.
- [Base narrativa](docs/BASE_NARRATIVA.md) e [fichas das regiões](docs/PLANO_CAMPANHA.md).
- [Refúgio](docs/HUB_INICIAL.md) e [combate proposto](docs/COMBATE_PROPOSTA.md).
- [Guia de implementação](docs/GUIA_IMPLEMENTACAO_DEVIN.md) e
  [guia de escrita](docs/GUIA_ESCRITA_DEVIN.md).
- [Marco de pixel art](docs/PIXEL_ART_MILESTONE.md) e
  [plano de refinamento](docs/PLANO_REFINAMENTO_PIXEL_ART.md).
- [Design dos sistemas anteriores](docs/DESIGN.md).

Os documentos incluem propostas e trabalho futuro; o escopo jogável desta
entrega está descrito acima.

## Verificação e pacote

Execute os dois comandos na raiz:

```text
love . --test
love . --ui-test
```

A suíte principal cobre geração, terreno, inimigos, combate do protótipo,
diálogos, loja, exploração da campanha, persistência e pixel art. A suíte de
interface verifica callbacks, movimento, desenho e redimensionamento.
Ambas passaram na validação do commit `d5bcb84`.
Os resultados ficam em `test-results.txt` e `ui-test-results.txt`;
[tests/README.md](tests/README.md) detalha a cobertura.

Screenshots e PNGs de teste ficam em **`screenshots/`**, conforme
[AGENTS.md](AGENTS.md). Para capturar uma cena, execute da raiz:

```text
love . --scene=colina --screenshot=screenshots/colina.png
```

**Concord, Baton, anim8, Flux e Ripple** estão vendorizados. Versões e licenças
estão em [docs/LIBRARIES.md](docs/LIBRARIES.md).

O pacote anterior em `build/Windows` não foi atualizado nesta entrega.
`python tools/package.py` reconstrói o `.love` e, quando há runtime instalado,
a versão portátil de Windows com suas licenças.
