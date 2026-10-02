# Arrowfallen — Megaplan da repaginada visual

Status: base técnica do primeiro marco implementada e verificada; acabamento artístico em revisão. Registro de arquivos, checks e imagens em [PIXEL_ART_MILESTONE.md](PIXEL_ART_MILESTONE.md). O próximo trabalho segue o [plano de refinamento](PLANO_REFINAMENTO_PIXEL_ART.md), antes de expandir para as etapas 4 e 5, que permanecem pendentes.

Objetivo: repaginar os gráficos com pixel art consistente, expressiva e legível, desenhando todos os elementos por código. Não importar sprites, texturas, fontes ou outros assets visuais prontos.

## 1. Decisões aprovadas

| Elemento | Decisão |
| --- | --- |
| Mundo | Ruínas cerimoniais: pedra azul escura, jade e ouro envelhecido |
| Grade artística | 32 × 32 pixels por célula |
| Personagens | Estilizados e elegantes, cabeça moderada, capa alongada e poses fortes |
| Área inicial do viajante | 32 × 48 pixels, ajustável se armas e poses exigirem mais espaço |
| Perspectiva | Vista de cima inclinada, mostrando topo e frente dos objetos |
| Câmera | Acompanha imediatamente o viajante, centralizando seus pés |
| Ampliação preferida | 2×: cada célula ocupa 64 × 64 pixels na área de renderização |
| Atmosfera | Sombria, mantendo combate e navegação claramente legíveis |
| Animações | Expressivas e elásticas, com deformações desenhadas em quadros próprios |
| Contornos | Seletivos: escuros na sombra e coloridos na luz |
| Cenário | Detalhe concentrado; piso tranquilo e arquitetura trabalhada |
| Magia | Presente no ambiente, com runas e mecanismos discretamente animados |
| Interface | Mínima; vida e escudo permanentes, carga próxima ao viajante |
| Minimapa | Mantido no canto superior direito, onde está atualmente |
| Perigos | Geométricos, precisos e legíveis por forma além de cor |
| Inimigos | Sentinelas e criaturas com uma origem mágica comum |
| Produção | Desenhos autorais em código; imagens e spritesheets geradas em memória |
| Reprodução das animações | anim8 |

## 2. Grade artística e renderização

A grade lógica atual de 40 unidades por célula pode permanecer. O renderizador converte as posições para a grade artística de 32 pixels, sem alterar colisões, alcance, movimentação ou regras do combate.

- Renderizar o mundo numa superfície interna com resolução inteira.
- Ampliar usando filtro nearest e fatores inteiros.
- Preferir 2×; usar outro fator inteiro adequado quando necessário para acomodar a janela.
- Ajustar o tamanho da superfície interna ao espaço disponível; não esticar o mundo com escala fracionária.
- Alinhar desenhos e câmera à grade artística na apresentação; preservar precisão na simulação.
- Evitar linhas fracionárias, suavização e rotação ou escala contínuas de sprites que produzam pixels irregulares.
- Estabelecer uma origem nos pés para posicionar personagens, sombras e peças altas.

A sala de prática de 17 × 11 células ocupa 544 × 352 pixels artísticos. Como a câmera acompanha o viajante, não é necessário mostrar a sala inteira simultaneamente.

## 3. Câmera

- Seguimento imediato, sem suavização nem zona morta.
- Centralizar os pés do viajante enquanto os limites da sala permitirem.
- Parar nos limites da sala; perto das bordas o viajante pode sair do centro.
- Centralizar salas menores que a área visível, sem limites invertidos ou deslocamentos instáveis.
- Não antecipar a direção do olhar: virar serve também para atacar e defender.
- Ajustar a posição final à grade de pixels.
- Aplicar tremor breve nos impactos relevantes, respeitando movimento reduzido.
- Indicar ameaças ativas fora da tela quando necessárias para reagir, sem expor inimigos inativos indiscriminadamente.

Validar em jogo se os tempos atuais de aviso permanecem suficientes com o enquadramento próximo. Indicadores de borda não substituem essa avaliação. Se houver necessidade de mudar regras ou tempos, registrar o problema antes de ampliar o escopo da repaginada.

## 4. Paleta, luz e materiais

Usar uma paleta compartilhada, organizada por material. Fechar cores exatas na sala de referência.

| Material | Tratamento |
| --- | --- |
| Pedra | Sombras azuladas, faces amplas, desgaste seletivo nas bordas |
| Tecido | Manchas contínuas, dobras seletivas e luz suave |
| Metal | Reflexos curtos, contraste forte e envelhecimento |
| Cristal | Faces angulares, centro luminoso e maior saturação |
| Magia | Jade como identidade principal, variações coerentes por função |

A luz principal vem de cima à esquerda e é desenhada nos elementos. Sombras de contato ancoram personagens e objetos no chão. Cristais e runas podem receber brilho localizado; iluminação dinâmica não faz parte da primeira implementação.

Hierarquia visual: perigo imediato, viajante e inimigos, objetos interativos, arquitetura e textura. Magia ambiente tem intensidade e frequência inferiores às dos avisos de combate.

## 5. Cenário

- Piso com juntas discretas, variações limitadas de lajes e áreas visualmente tranquilas.
- Rachaduras, poeira e desgaste distribuídos com intenção; evitar ruído aleatório por toda a superfície.
- Variações estáveis por posição e seed, preservadas nas revisitas.
- Paredes com topo, frente, cantos e encontros coerentes entre peças vizinhas.
- Pilares com base, corpo, ornamentos e estados claros de dano, queda e segmento caído.
- Buracos com bordas quebradas e faces internas que comuniquem profundidade.
- Portais reconhecíveis pela arquitetura e pelos estados aberto ou bloqueado.
- Decoração sem colisão visualmente distinta dos obstáculos sólidos.
- Estados de destruição alinhados às regras atuais, sem alterar áreas anunciadas.

Reutilizar a ordenação por profundidade e a lógica de vizinhança existentes quando adequadas.

## 6. Personagens e inimigos

O viajante define o padrão de acabamento: capuz com volume, capa assimétrica, mãos e pés legíveis, materiais distintos e arco reconhecível pela silhueta.

Desenhar quatro direções próprias. Virar muda cabeça, corpo, braços, capa e sobreposição da arma; não depender apenas de deslocar olhos ou girar o arco.

Sentinelas e criaturas compartilham símbolos, materiais e sinais da mesma magia. Diferenciar funções por silhueta e postura:

- Investidores: peso à frente e preparação agressiva.
- Atiradores: corpo estreito, arma clara e postura alerta.
- Conjuradores: figura vertical e gestos amplos.
- Rastejantes: corpo baixo e locomoção própria.
- Chefes: presença maior, equipamento específico e transformação legível entre fases.

Testar a identificação por silhueta antes de acrescentar detalhes pequenos.

## 7. Animações com anim8

Usar anim8 para controlar sequência de quadros, duração e repetição das animações. As spritesheets serão desenhadas por código e geradas em memória, sem importar imagens prontas.

- Verificar primeiro se anim8 já está disponível no projeto e reutilizá-lo.
- Se estiver ausente, integrar apenas a biblioteca necessária pelo padrão existente de dependências, sem instalar um framework adicional.
- Gerar spritesheets uma vez e reutilizar imagens e quadros.
- Instanciar estado de animação por ator quando necessário; não compartilhar relógios mutáveis inadvertidamente.
- A simulação continua sendo a autoridade sobre carga, dano, defesa, mineração e recuperação.
- A animação acompanha o estado e o tempo da ação; callbacks visuais não determinam dano ou conclusão do combate.
- Reiniciar uma animação ao entrar num estado, não a cada atualização.
- Definir comportamento consistente para pausa, guia, morte e transições.

Cada ação importante terá preparação, execução e recuperação. Começar com os estados existentes: espera, deslocamento, carga, prontidão, disparo, defesa, mineração, dano e morte; incluir estados próprios dos inimigos conforme suas mecânicas.

Expressividade por poses: compressão antes do salto, extensão no movimento, acomodação no pouso, capa atrasando e impactos rápidos. Quantidade de quadros deve atender ao gesto; não fixar um número universal antes de desenhar.

## 8. Efeitos e perigos

| Evento | Linguagem visual |
| --- | --- |
| Pedra quebrada | Lascas, poeira e fragmentos pesados |
| Metal atingido | Faíscas curtas e impacto direcional |
| Cristal ativado | Facetas luminosas e pulsação |
| Flecha acertando | Clarão curto e fragmentos na direção do golpe |
| Pilar caindo | Impactos distribuídos pela trajetória |
| Magia ambiente | Runas lentas e pontos luminosos discretos |

Perigos usam contornos pixelados nas células afetadas, símbolos de direção ou tipo e progressão clara até o ataque. A área visual corresponde exatamente à área anunciada pela simulação.

Garantir leitura com sobreposição de paredes, atores e efeitos. Usar forma e padrão além da cor. Movimento reduzido conserva todos os sinais necessários e reduz apenas movimento decorativo, partículas e tremor.

## 9. Interface e tipografia

| Informação | Comportamento |
| --- | --- |
| Vida e escudo | Sempre visíveis, num grupo compacto |
| Carga do arco | Próxima ao viajante durante carga e prontidão |
| Minimapa | Permanente na expedição, no canto superior direito como hoje |
| Ouro e picaretas | Visíveis quando mudam e durante consulta |
| Relíquias e explicações | Acessíveis no guia ou na consulta |
| Nome da sala | Breve apresentação ao entrar |
| Mensagens | Curtas e contextuais, sem cobrir perigos |

Manter as regras atuais de visibilidade do minimapa: não revelar segredos ou salas por causa da apresentação. O acabamento muda, a posição permanece.

Desenhar molduras e ícones coerentes com pedra, metal e símbolos do mundo. Produzir fonte bitmap por código, com acentos do português e caracteres usados pelo jogo. Priorizar leitura e contraste; títulos podem ter mais personalidade que indicadores pequenos.

Manter estados de menu, pausa, guia, recompensa, derrota e vitória, com controles claros. Não ocultar informações necessárias para decisões imediatas em nome do minimalismo.

## 10. Etapas de implementação

### Etapa 1 — Base de pixels e câmera

Conversão visual de coordenadas, superfície interna, escala inteira, câmera centralizada, limites da sala, redimensionamento e alinhamento dos pixels. Manter o desenho atual funcional durante a preparação.

### Etapa 2 — Sala de referência

Uma sala completa com viajante, um inimigo, piso, parede, pilar, cristal, buraco, portal, vida, escudo e minimapa. Fechar paleta, contornos, proporções e legibilidade. Essa sala é a referência antes de expandir o desenho ao restante do jogo.

### Etapa 3 — Movimento e combate

Integrar anim8 e as spritesheets geradas. Implementar direções e ações do viajante, animações do inimigo de referência, perigos, efeitos por material e indicadores de ameaças fora da tela.

### Etapa 4 — Elenco e ambientes

Expandir o padrão aos inimigos, chefes, salas especiais, objetos interativos e estados de destruição. Preservar identidade e legibilidade entre fases.

### Etapa 5 — Interface e acabamento

Concluir HUD mínimo, tipografia, menus, recompensas, guia e transições. Revisar resoluções, sobreposições, movimento reduzido e consistência visual em jogo.

## 11. Verificação e critérios de aprovação

- Pixels com tamanho consistente, inclusive durante deslocamento e tremor.
- Ausência de suavização ou escala fracionária no mundo.
- Personagens reconhecíveis pela silhueta e quatro direções próprias.
- Materiais distintos e luz coerente.
- Piso e magia ambiente sem disputar atenção com combate.
- Perigos precisos e legíveis com sobreposição de atores e efeitos.
- Câmera próxima permitindo reagir às ameaças.
- HUD e minimapa legíveis nas janelas suportadas.
- Fonte com português completo para os textos existentes.
- Pausa e mudanças de estado sem animações reiniciadas ou eventos de combate indevidos.
- Movimento reduzido preservando informação.
- Renderização sem mutar colisões, áreas de aviso ou timers da simulação.
- Checks existentes apropriados passando; acrescentar apenas verificações pequenas para nova lógica relevante.

Guardar todos os screenshots e PNGs de teste em `screenshots/`, na raiz. Ao executar o jogo para capturar uma tela, usar `--screenshot=screenshots/nome.png` com o diretório de trabalho na raiz, conforme AGENTS.md. Não guardar prints na raiz nem em `build/`.

## 12. Prompt para começar

```text
Implemente a repaginada visual do Arrowfallen seguindo docs/MEGAPLAN_PIXEL_ART.md.

Leia o plano completo, AGENTS.md e os arquivos relevantes antes de editar. As decisões do plano estão aprovadas. Comece pelas etapas 1, 2 e 3: base de pixels e câmera, uma sala de referência acabada e suas animações/combate. Termine esse primeiro marco funcionando e visualmente verificado antes de expandir para o restante do elenco.

Use grade artística de 32 × 32 pixels por célula, ampliação preferida 2× com fatores inteiros e câmera acompanhando imediatamente o viajante, centralizada nos pés e limitada pela sala. Preserve a lógica atual de combate e converta coordenadas apenas na apresentação.

Desenhe todos os elementos visuais por código. Gere imagens e spritesheets em memória; não importe assets visuais prontos. Use anim8 para reproduzir as animações, reutilizando a dependência se já existir ou integrando somente essa biblioteca se estiver ausente. A simulação controla os tempos e eventos do combate; anim8 acompanha os estados.

Siga a direção de ruínas cerimoniais, pedra azul escura, jade e ouro envelhecido; personagens elegantes com animações expressivas; contornos seletivos; detalhe concentrado e magia ambiente discreta. Mantenha perigos geométricos exatos, vida e escudo visíveis, carga próxima ao viajante e o minimapa no canto superior direito onde está hoje, preservando suas regras de descoberta.

Reutilize a estrutura existente e faça as mudanças necessárias para concluir esse marco, sem criar abstrações especulativas nem refatorar sistemas alheios à repaginada. Preserve controles, progresso, segredos, estados de terreno e movimento reduzido.

Execute os checks pertinentes e confira o resultado visual em movimento e nos tamanhos de janela suportados. Guarde todos os prints em screenshots/; use --screenshot=screenshots/nome.png com o diretório de trabalho na raiz. Corrija os problemas encontrados e entregue um resumo dos arquivos alterados, verificações feitas, imagens de referência e etapas restantes do plano.
```
