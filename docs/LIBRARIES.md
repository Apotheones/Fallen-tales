# Bibliotecas e procedência

Esta é a lista das dependências vendorizadas neste jogo. Elas foram
obtidas de seus upstreams, sem copiar dependências, código ou assets da pasta
de estudo. As revisões estão fixadas em `vendor/versions.json`.

| Biblioteca | Tarefa | Upstream | Revisão |
| --- | --- | --- | --- |
| Concord | Entidades, componentes, pools e systems ECS | [Concord Studio](https://github.com/Concord-Studio/Concord) | `ee3587abc13cc39cd028d806924524be3bcee966` |
| Baton | Estado de teclas e escudo | [tesselode/baton](https://github.com/tesselode/baton) | `6723dd9f99ce8a20e553a7b818a1ebcd32cacbaf` |
| hump.camera | Câmera da apresentação anterior; retida no vendor | [vrld/hump](https://github.com/vrld/hump) | `08937cc0ecf72d1a964a8de6cd552c5e136bf0d4` |
| Flux | Tweens do piso, popups e efeitos visuais | [rxi/flux](https://github.com/rxi/flux) | `bb330231b87eabf84fbd68322f13a6320db30a41` |
| Ripple | Vozes simultâneas e categoria de áudio | [tesselode/ripple](https://github.com/tesselode/ripple) | `e18db79b98546a12f560b817bfbc218d08b0fb13` |
| anim8 2.3.1 | Sequência e duração das animações autorais geradas em memória | [kikito/anim8](https://github.com/kikito/anim8) | `bd38defa844ab2dfa3bf416a10c45ce376ba4c50` |

As licenças de Concord, Baton, Flux, Ripple e anim8 estão nos arquivos
`vendor/*-LICENSE`. O aviso de licença do hump.camera está preservado no início
de `vendor/camera.lua`. Mantenha esses avisos ao redistribuir o jogo.

Concord organiza os atores e sistemas de combate, incluindo chefe e cristais.
Baton lê as teclas mantidas; o jogo conserva a prioridade cardinal da última
direção pressionada. A câmera em pixels, anim8, Flux e Ripple pertencem à apresentação. Seus
resultados não alteram alcance, dano, invulnerabilidade ou avisos inimigos.

A navegação usa busca em largura sobre os blocos transitáveis; o mapa possui
40 × 40 unidades por bloco. A apresentação converte para 32 × 32 pixels por bloco;
as spritesheets do viajante e do investidor são rasterizadas por código uma vez,
em memória, e reproduzidas pelo anim8. Seus relógios não disparam eventos de combate.
Não há física contínua ou editor de mapas. O desenho é autoral e os sons são sintetizados no LÖVE.
