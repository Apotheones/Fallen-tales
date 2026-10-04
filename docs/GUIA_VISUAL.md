# Guia visual

Direção e contrato técnico consolidados em 03/10/2026. O estado jogável está
no [README](../README.md); localização e composição do Refúgio seguem
[PLANO_REFUGIO_ANDLAR.md](PLANO_REFUGIO_ANDLAR.md). Redesenhos do elenco em
[PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md](PERSONAGENS_DIRECAO_VISUAL_E_NARRATIVA.md)
são propostas, não sprites entregues.

## Base existente

Arte autoral gerada por código; célula artística de 32×32, vista de cima
inclinada, filtro nearest, escalas inteiras e origem dos atores nos pés.
Ampliação preferida 2×; não esticar pixels para caber na janela. anim8 reproduz
quadros. Câmera respeita limites do mapa e apresenta o panorama do mirante.

- `pixel_art_v2.lua`: primitivas, dithering Bayer e variação determinística.
- `pixel_scene.lua`: composição e canvas assado do cenário estático.
- `pixel_world.lua`: cenário dinâmico; `pixel_actors.lua`: silhuetas e poses.
- `palettes.lua`: rampas compartilhadas por material; `props.lua`: objetos.
- `render.lua`: câmera, HUD, intenções, balões e efeitos; `pixel_font.lua`: texto.

Preservar a divisão entre estático e dinâmico, paletas existentes e precisão
da simulação. Arte não modifica alcance, colisões, vida, velocidade ou dano.
Hash por seed/posição conserva desgaste nas revisitas; não sortear decoração
por quadro nem criar novo editor ou dependência para uma passagem de arte.

## Leitura e acabamento

Piso de exploração deve recuar: superfícies tranquilas, poucas juntas e
ornamentação concentrada. A arena precisa de grade legível porque as células
informam decisões. Arquitetura mostra topo, frente, cantos e desníveis;
decoração não sugere colisões, caminhos ou perigos inexistentes.

Ruínas usam pedra azul escura, jade e ouro envelhecido; ouro destaca interesse
sem contornar tudo. Refúgio tem calor doméstico, lugares usados e manutenção,
sem parecer vazio ou próspero demais. Luz e sombra são desenhadas; iluminação
dinâmica e fog of war não são requisitos.

Silhueta, direção, equipamento e ameaça devem funcionar em cinza e em 2×.
Não distinguir moradores só pela cor. Poses mostram preparação, esforço,
impacto e recuperação; caminhar enquanto carrega/guarda precisa ler como
movimento, sem transportar uma pose rígida. Contornos seletivos, grupos de
pixels e detalhe concentrado prevalecem sobre ruído aleatório.

Perigos, facção, estado e seleção precisam de forma além da cor. A marca de
ataque deve corresponder exatamente à resolução. HUD não cobre cabeças;
texto, ícones e balões precisam caber também em janela menor. Movimento
reduzido preserva informação de ação e perigo; áudio desligado não impede
compreender resultado.

## Verificação

Para uma mudança, compare a mesma cena, posição e janela antes/depois.
Confira enquadramento em 900 e 1920 pixels de largura, silhuetas nas quatro
direções, quadros-chave e reprodução em velocidade normal. Testes técnicos
não aprovam qualidade artística. Uma referência visual escolhida orienta
expansão do acabamento; não produzir todo o elenco antes de validar formas.

Capturas e pranchas ficam somente em `screenshots/`, executadas da raiz:

```text
love . --scene=hub --size=1120x800 --capture-after=30 --screenshot=screenshots/hub-visual.png
```

Leia o PNG e refaça captura sob fade antes de diagnosticar imagem preta.
Mudanças de render usam também `--test` e `--ui-test`, conforme
[tests/README.md](../tests/README.md) e [QA_MUNDOS.md](QA_MUNDOS.md).
