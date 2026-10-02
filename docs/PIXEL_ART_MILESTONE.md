# Primeiro marco da pixel art

Este documento registra a entrega técnica. Após a avaliação do protótipo em 2×, o acabamento artístico entrou em revisão; o próximo trabalho está no [plano de refinamento](PLANO_REFINAMENTO_PIXEL_ART.md).

Escopo: etapas 1, 2 e 3 de `MEGAPLAN_PIXEL_ART.md`. A sala de prática é a
referência de acabamento; o restante do elenco mantém seu desenho funcional
até a etapa 4.

## Implementação

- Mundo em células artísticas de 32 × 32 pixels, desenhado numa Canvas com
  filtro nearest e ampliação inteira. Todas as janelas suportadas usam 2×, conforme o ajuste posterior do protótipo.
- Câmera imediata nos pés interpolados do viajante, com origem alinhada ao
  pixel, limites da sala e centralização de salas menores que a área visível.
  O cabeçalho reserva a altura real do HUD e do minimapa, evitando ocultar
  atores ou perigos quando o mapa cresce.
- Sala de referência com pedra azul escura, jade e ouro envelhecido: piso,
  paredes e encontros, pilares, segmentos caídos, buracos, cristais e portal.
- Spritesheets autorais geradas em memória para viajante e investidor de
  referência. Quatro direções próprias, ações acompanhando o estado e os
  tempos da simulação, reproduzidas por anim8 com estado individual por ator.
  Quadros de 40 × 48 reservam espaço para o arco nas poses laterais.
- Perigos desenhados sobre suas células anunciadas, símbolos por forma,
  progressão e indicadores para ameaças ativas fora da tela. Vida e escudo
  compactos, carga próxima ao viajante e mapa na posição anterior.
- Efeitos de pedra, metal e cristal usam fragmentos e padrões próprios.
  Ouro, ferramentas e efeitos das melhorias podem ser consultados no guia.

As coordenadas lógicas, colisões, avisos congelados, tempos, controles,
descoberta e progresso continuam pertencendo à simulação. Animações de atores
congelam na pausa, no guia e na recompensa; efeitos transitórios conservam o
comportamento anterior. Movimento reduzido conserva os avisos.

## Arquivos deste marco

| Arquivo | Responsabilidade |
| --- | --- |
| `src/render.lua` | Conversão, Canvas, câmera, HUD, perigos e integração |
| `src/pixel_world.lua` | Paleta e desenho do cenário de referência |
| `src/pixel_actors.lua` | Spritesheets geradas e animações por ator |
| `src/pixel_font.lua` | Fonte bitmap gerada por código para o mundo e HUD |
| `src/feedback.lua` | Fragmentos e impactos por material |
| `vendor/anim8.lua`, `vendor/anim8-LICENSE` | Reprodução de quadros e licença |
| `vendor/versions.json`, `docs/LIBRARIES.md` | Procedência da biblioteca |
| `main.lua` | Integração dos checks e cenas de referência |
| `tests/pixel.lua` | Câmera, coordenadas, animações e desenho em movimento |
| `docs/MEGAPLAN_PIXEL_ART.md` | Status do marco |
| `README.md`, `docs/DESIGN.md`, `docs/ROADMAP.md`, `tests/README.md` | Contrato visual, dependências e reprodução dos checks |

## Verificação

Com o diretório de trabalho na raiz:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test
& 'C:\Program Files\LOVE\lovec.exe' . --ui-test
```

O check de pixels verifica escala e origens inteiras, limites nos quatro
lados, salas menores, interpolação sem mutação, animações e relógios
individuais. A integração exercita teclado, atualização e desenho reais em
120 quadros de movimento, carga, pausa, guia e recompensa; compara o conteúdo
da Canvas e valida redimensionamento em 900 × 680, 1120 × 800 e 1920 × 1080.
Também verifica filtro nearest e preservação de terreno, timers e descoberta
durante desenho, tremor e movimento reduzido.

Execução verificada em 1 de outubro de 2026: `--test` retornou
`ALL CHECKS PASSED`; `--ui-test` retornou `ALL UI CHECKS PASSED`. Passaram
os checks existentes de geração, terreno, elenco e combate, 28 asserts de
pixels/câmera/animação/fonte/indicadores, 136 asserts de callbacks e 268 asserts da
integração de movimento/redimensionamento. Os replays existentes continuam
cobrindo 30/60/144 FPS.

As capturas foram inspecionadas: pixels uniformes em 2× e 3×, viajante e
investidor reconhecíveis, perigos legíveis sobre segmentos caídos, paredes e
pilares com faces distintas, vida/escudo/rodapé legíveis e sinais preservados
com movimento reduzido. O check de movimento desenha os quadros reais durante
a atualização; os PNGs registram poses e estados específicos.

| Referência | Imagem |
| --- | --- |
| Janela padrão, 3× | [1120 × 800](../screenshots/pixel-reference-1120.png) |
| Janela mínima, 2× | [900 × 680](../screenshots/pixel-reference-900.png) |
| Janela grande, 3× | [1920 × 1080](../screenshots/pixel-reference-1920.png) |
| Pilar, direção e área anunciada | [Terreno](../screenshots/pixel-terrain.png) |
| Expedição e descoberta | [Mapa](../screenshots/pixel-map.png) |
| Mapa com mais salas e símbolos legíveis | [Mapa amplo](../screenshots/pixel-map-wide.png) |
| Sinais com movimento reduzido | [Movimento reduzido](../screenshots/pixel-reduced.png) |
| Pose durante deslocamento | [Movimento](../screenshots/pixel-move-west.png) |
| Movimento real em seis instantes | [Animação](../screenshots/pixel-live-motion.gif), [0,08 s](../screenshots/pixel-live-01.png), [0,48 s](../screenshots/pixel-live-06.png) |
| Direções próprias | [Leste](../screenshots/pixel-ready-east.png), [Sul](../screenshots/pixel-ready-south.png), [Oeste](../screenshots/pixel-ready-west.png), [Norte](../screenshots/pixel-ready-north.png) |
| Ações e estados | [Carga](../screenshots/pixel-charge-south.png), [Defesa](../screenshots/pixel-guard-east.png), [Mineração](../screenshots/pixel-mine-east.png), [Dano](../screenshots/pixel-hurt-east.png), [Morte](../screenshots/pixel-death-south.png) |

Para reproduzir a referência, com o diretório de trabalho na raiz:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --scene=reference --size=1120x800 --screenshot=screenshots/pixel-reference-1120.png
& 'C:\Program Files\LOVE\lovec.exe' . --scene=reference --pose=ready-north --screenshot=screenshots/pixel-ready-north.png
```

Todos os PNGs de teste ficam em `screenshots/`.

Os indicadores de borda foram verificados: ameaça ativa recebe indicador,
inimigo inativo fica oculto e coordenadas/timer permanecem iguais. O layout
também verifica a reserva de espaço para a altura máxima do minimapa.

## Próximas etapas

Etapa 4: expandir direções, poses, materiais e animações ao elenco completo,
chefes, ambientes especiais e estados de destruição.

Etapa 5: aplicar a tipografia bitmap aos menus, guia e recompensas, concluir
transições e revisar toda a interface e o acabamento nas resoluções suportadas.
Avisos e indicadores precisam continuar sendo avaliados em combate; eventual
mudança de regras ou tempos exige registrar o problema antes de ampliar o
escopo visual.

## Ajuste de enquadramento

Após o primeiro marco, a ampliação do mundo passou a 2× nas janelas suportadas.
As capturas anteriores em 3× registram a entrega original; o enquadramento atual
está em [referência 2×](../screenshots/pixel-reference-2x.png).
