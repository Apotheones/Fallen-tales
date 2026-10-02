# Plano de refinamento da pixel art

Status: planejado. A base técnica do primeiro marco está implementada; o acabamento artístico precisa de uma nova passagem antes das etapas 4 e 5 do megaplan.

## Objetivo

Transformar a sala de prática em uma referência visual convincente em **2×**, preservando o funcionamento do protótipo. A prioridade é melhorar desenho, composição e animação; adicionar detalhes ao desenho atual não resolve suas limitações.

Referência para comparação: [captura atual em 2×](../screenshots/pixel-reference-2x.png). Comparações devem manter a mesma cena, posição dos atores e janela de 1120 × 800.

## Diagnóstico e direção

| Problema atual | Mudança proposta |
| --- | --- |
| Piso com bordas em todas as células parece uma grade e compete com os atores | Grandes superfícies tranquilas, juntas parciais e poucos motivos cerimoniais |
| Paredes parecem caixas idênticas enfileiradas | Massas contínuas de pedra, topo e frente distintos, cantos e arremates desenhados |
| Viajante pequeno e pouco reconhecível | Silhueta elegante, capuz com volume, arco separado do corpo e capa assimétrica |
| Investidor escuro e pouco distinto | Corpo pesado, ombros largos e postura inclinada; contraste suficiente para reconhecer a ameaça |
| Animações deslocam formas parecidas entre quadros | Poses próprias de preparação, esforço, impacto e recuperação |
| Objetos e HUD têm aparência genérica | Formas reconhecíveis e materiais que seguem a mesma linguagem do cenário |

Manter as ruínas cerimoniais de pedra azul escura, jade e ouro envelhecido. O ouro deve marcar pontos de interesse, não contornar tudo. Usar sombras amplas, luz do alto à esquerda e grupos de pixels bem definidos. Concentrar ornamentação em portais, bases de pilares e mecanismos. Viajante e perigos precisam dominar a leitura da sala.

## 1. Estudos pequenos para decidir o desenho

Produzir uma prancha autoral pelo código existente, com duas ou três silhuetas realmente diferentes do viajante, uma proposta do investidor e estudos de pedra, pilar, cristal e portal. Mostrar silhueta preta, valores de cinza e cor, em resolução nativa e em 2×.

Escolher a proposta que melhor separa capuz, corpo, capa e arco e contrasta com o investidor. Não produzir todas as animações de uma silhueta ainda fraca. A prancha serve para decidir formas, proporções e valores; não é uma nova ferramenta de produção.

**Entrega:** prancha em `screenshots/` e direção escolhida com justificativa curta.

## 2. Refazer os dois personagens de referência

Desenhar viajante e investidor nas quatro direções. Trabalhar primeiro contorno, proporção e espaços entre membros e equipamento; depois volumes, luz e pequenos detalhes.

- Viajante: cabeça moderada, postura reconhecível, capa alongada com recortes deliberados e arco legível em todas as direções.
- Investidor: massa e centro de gravidade diferentes, cabeça e ombros reconhecíveis, preparação de ataque visível sem depender do brilho.
- Preservar origem nos pés e espaço para armas; ajustar o enquadramento dos quadros somente se o desenho exigir.

**Aceite:** distinguir os personagens pela silhueta, reconhecer sua direção e enxergar o arco sem ampliação além de 2×. Sem cortes de armas ou separação acidental dos membros.

## 3. Reconstruir a composição da sala

Aplicar a direção escolhida à sala de prática, mantendo sua geometria de jogo.

- **Piso:** reduzir contraste e remover a moldura repetida de cada célula. Usar variações estáveis e poucos desenhos maiores alinhados à arquitetura.
- **Paredes:** conectar superfícies vizinhas, distinguir topo e face frontal e desenhar encontros e terminais. Distribuir ornamentos em trechos específicos.
- **Pilares e destroços:** desenhar base, fuste e capitel; nas partes quebradas, mostrar espessura e faces internas.
- **Buracos:** borda quebrada e interior profundo, com limite de perigo inequívoco.
- **Cristais:** faces assimétricas, pontos de luz controlados e encaixe físico na pedra.
- **Portal:** uma peça arquitetônica com identidade, distinguindo aberto e fechado por forma e estado.

Evitar ruído aleatório como substituto de desenho. Marcas decorativas não podem sugerir colisões, caminhos ou buracos inexistentes.

**Aceite:** na imagem completa em 2×, o piso recua visualmente; personagens, objetos importantes e perigos aparecem primeiro. A navegação continua clara, inclusive em cinza.

## 4. Dar intenção às animações e aos efeitos

Reusar anim8 e os tempos da simulação. Desenhar quadros-chave que mudem a pose, não apenas a posição do sprite.

- Caminhada: apoio dos pés, transferência de peso e atraso da capa.
- Carga e disparo: braço e tronco tensionados, soltura, recuo e recuperação.
- Guarda e mineração: postura firme; preparação e golpe com direção clara.
- Investidor: compressão antes do avanço, extensão no ataque e recuperação pesada.
- Dano e morte: reação reconhecível e perda de sustentação.

O seletor atual prioriza carga e guarda sobre caminhada. Tratar as combinações que o jogo permite, especialmente andar enquanto carrega ou guarda, com poucas variantes explícitas; uma pose estática transportada pelo mapa não deve parecer caminhada.

Refinar os efeitos existentes: pedra em fragmentos, metal em faíscas e cristal em facetas, acompanhando a direção do impacto. Preservar o desenho exato das células de perigo e sua leitura sobre o cenário. Movimento reduzido deve manter toda a informação necessária.

**Aceite:** comparar GIF em velocidade normal e quadros isolados. Pés e equipamento continuam conectados, o movimento não parece um boneco rígido pulando e as ações seguem os mesmos momentos do combate.

## 5. Fechar a cena e revisar antes de expandir

Refinar apenas o HUD necessário à cena: ícones claros de vida e escudo, molduras discretas e cores coerentes com o mundo. Manter minimapa no canto superior direito, carga perto do viajante e legibilidade do texto. Menus completos e restante do elenco continuam para as etapas seguintes.

Entregar comparação antes/depois da sala em 2×, prancha dos quatro sentidos e sequência animada de caminhada, carga em movimento e ataque. Conferir também janelas de 900 e 1920 pixels de largura e movimento reduzido.

**Ponto de revisão:** apresentar a sala funcionando e as comparações ao usuário. Só expandir o novo acabamento para outros inimigos, salas e menus após a aprovação visual dessa referência. Testes técnicos não substituem essa avaliação.

## Limites e implementação

- Manter células artísticas de 32 × 32, ampliação 2×, filtro nearest, câmera e origem nos pés.
- Preservar colisões, alcance, dano, velocidade, mineração, descoberta do mapa e controles.
- Continuar com arte autoral por código e imagens geradas em memória, sem assets visuais importados.
- Trabalhar nos módulos existentes: `src/pixel_world.lua` para cenário; `src/pixel_actors.lua` para sprites e poses; `src/render.lua` para HUD, perigos e efeitos. Tocar `src/feedback.lua` somente quando necessário aos efeitos.
- Não criar editor de sprites, sistema genérico de materiais, animação em camadas ou novas dependências para esta passagem.
- Salvar todas as pranchas, capturas e GIFs em `screenshots/`. Capturas pelo jogo usam `--screenshot=screenshots/nome.png`, executadas da raiz.
- Quando houver mudança de lógica, executar os checks existentes `--test` e `--ui-test` e acrescentar somente uma verificação relevante se a mudança exigir cobertura nova.

## Prompt para execução

> Execute este plano de refinamento, começando pelos estudos e chegando a uma sala de prática completa e jogável. Mantenha zoom 2× e as regras atuais. Reuse os módulos e ferramentas existentes, com Ponytail ativo; concentre o esforço no desenho autoral e nos quadros-chave. Não expanda o elenco ou os menus antes de apresentar a referência ao usuário. Compare com `screenshots/pixel-reference-2x.png` na mesma cena e janela. Entregue capturas e animações em `screenshots/`, valide a lógica alterada e descreva com honestidade o que melhorou e o que ainda precisa de trabalho.
