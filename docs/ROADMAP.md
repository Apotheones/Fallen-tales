# Arrowfallen — evolução para uma expedição completa

> **Revisão de 02/10/2026:** a direção do produto passou a ser a campanha
> narrativa "A Cidade Que Me Enterrou" — hub recorrente, dez regiões autorais,
> exploração livre e arena de turnos — conforme
> [MEGAPLAN_CAMPANHA.md](MEGAPLAN_CAMPANHA.md) e o pacote de design de
> `docs/`. O material abaixo descreve o modo de três andares existente, que
> permanece como material interno de teste e fonte de reaproveitamento; não é
> mais o destino do produto.

Revisão de **01/10/2026**. O código atual usa **somente arco**, SPACE por gesto de
pressionar/segurar/soltar e cenário interativo por WASD. Não há iluminação
dinâmica ou fog of war. Este contrato prevalece sobre descrições anteriores.

## Entregas atuais

- Células autoritativas, parede de três hits, 20 picaretas iniciais e custo por
  peça concluída; hold/repetição não mineram. Danos/estoque persistem na tentativa.
- Pilar de até cinco células com aviso fixo, esmagamento fatal e segmentos
  mineráveis. Buracos fatais no pouso; IA segura e dash comprometido com queda.
- Paredes conectadas, profundidade pela base, avisos/progresso legíveis com F2/M.
  Todas as células/atores/avisos ficam visíveis; sólidos bloqueiam tiro/movimento.
- Prática com câmara, divisória, desvio sem ferramentas, corredor de queda,
  segmento e buraco. Limpar inimigos permite continuar; portal explícito conclui.
- Apenas arco: SPACE começa carga, pronta espera soltura, soltar cedo cancela.
  Guarda/mineração/telas/foco cancelam gesto e exigem novo pressionamento.
- Planta por busca em largura: 7–8 salas no primeiro andar, +2–3 por andar,
  conexões regulares sem ciclos, chefe distante, loja/tesouro/refúgio nas pontas.
- Andares como regiões temáticas (Galerias da Superfície, Criptas dos
  Sacerdotes, Santuário Afundado) com pools próprios: salas retangulares
  variáveis por arquétipo (13×9 a 15×9/13×11; chefe 15×9; prática 17×11),
  nomes de ficção no cabeçalho, banner tático na primeira entrada, portas fora
  do centro e corredor protegido para progressão sem picaretas. A geração poda
  pilares que poderiam isolar atores em alguma combinação de queda.
- Portão selado violeta por andar numa folha especial: abre por 3 ouro ou 1
  picareta, fora da rota do chefe.
- Segredos opcionais de combate/pontaria, entradas mineráveis com brilho sutil
  a cada 4s, retorno gratuito e recompensa somente após concluir o desafio.
- Minimapa derivado das conexões reais, revelado apenas pela exploração.
- Descida entre andares preserva vida, ouro e melhorias; descoberta reinicia.
  Replays de prática/expedição e verificações de geração por seed.
- Cinco inimigos comuns (rastejante, sentinela com recuo, bruto, semeador de
  âmbar e vigia dos ecos) e dois elites (demolidor que atravessa peças e
  sentinela veterana de tiro duplo), organizados no catálogo `src/enemies.lua`.
- Marcas de âmbar como perigo de célula congelada com fusível, resolvidas pelo
  mesmo sistema dos cristais.
- Encontros procedurais por seed × andar × sala: um papel por vez no começo,
  até dois papéis no meio, até três no fim; covil de elite na sala secreta e
  em uma sala de ponta a partir do andar 2.
- Um boss por andar (Guardião → Demolidor → Regente), arenas próprias com
  poucos pilares, invocação com eco nascente atacável e limite de dois
  servos; a expedição termina ao vencer o andar 3.

Regras atuais estão em [DESIGN.md](DESIGN.md); critérios e escopo de cenário
em [TERRAIN_PLAN.md](TERRAIN_PLAN.md). Testes automatizados sustentam esses
contratos. O aceite com teclado humano continua pendente. O pacote portátil
anterior não foi atualizado; jogar esta revisão pela raiz do projeto.

## Próximas entregas

1. **Validar a sala de referência.** Observar a sequência parede → pilar →
   armadilha → segmento → buraco com teclado humano. Ajustar cadência, aviso,
   letalidade e câmera pela leitura de perigos. Manter desvios sem ferramentas
   e o gesto manual do arco. Produzir referência artística/sonora antes de
   multiplicar assets.
2. **Sustentar escolhas na expedição.** Validar os desvios e custos da planta
   procedural; ampliar os interiores para salas 2×2/em L e suas saídas.
   Ajustar ritmo e leitura do elenco já implementado
   (perseguição/recuo/controle de área) com teste humano. Ampliar builds do
   arco e escudo por decisões concretas; não oferecer ecos sem efeito possível.
3. **Integrar progressão e mundo.** Implementar NPCs comerciantes antes das
   vendas de mapas e outras compras compatíveis, XP da tentativa, cartas, NPCs,
   diálogos e lore. A recompensa por sala deve integrar o fluxo de níveis sem
   duplicar escolhas. Visitas não duplicam recompensas, cura ou estoque de loja.
   Lore, decisões e etapas em [MEGAPLAN_LORE.md](MEGAPLAN_LORE.md); as etapas
   1–5 (interação E, Amâncio na loja, Odete no refúgio, máquina de diálogo,
   o balcão com mapa/picaretas/provisão, XP da tentativa com níveis que
   enfileiram a oferta de ecos, 18 cartas colecionáveis com página própria no
   guia, intros de chefe e inscrições examináveis) já estão implementadas.
   Resta o aceite humano de leitura e ritmo.
4. **Completar o ciclo e persistência.** Preparação de equipamento, perfil,
   checkpoints seguros, começo/meio/encerramento e consulta da build. Saves
   preservam arco, economia e progresso; falhas não destroem dados anteriores.
5. **Produzir e validar a apresentação final.** Assets e música originais,
   menus/HUD, transições, opções/remapeamento e resoluções reais. Observar
   compreensão, decisões e vontade de repetir. Empacotar somente uma versão
   cujo conteúdo e qualidade já foram aprovados.

## Direção de design

O arco permanece a única arma desta entrega. Não há seletor durante combate,
pausa, cartas ou finais. Retomar um gesto cancelado exige novo SPACE; nenhuma
transição solta um ataque pendente. Avisos fixam direção/área e animação não
altera colisão, dano ou tempo de simulação.

O Guardião, o Demolidor e a Regente fecham os três andares do mundo: a segunda
fase de cada um muda a sequência (armadura rompida, investida dupla, marcas em
cruz), não só acelera atributos. O sentinela já recua com janela real de
aproximação. Refúgio e bifurcações devem ter custos e recompensas que evitem
uma rota sempre superior.

XP e Gold são uma proposta para a tentativa. Perfil pode guardar desbloqueios,
descobertas e conquistas sem exigir dano/vida permanente para vencer. Compras
precisam ser claras, compatíveis e não cobrar entradas inválidas. Texto deve
ser curto e pulável na repetição.

Preservar jade, âmbar e violeta, viajante de capuz e ecos. Materiais e objetos
sugerem função/história das salas. Jogador, ameaças e avisos recebem o maior
contraste. Sem fog/iluminação dinâmica nesta versão; atmosfera deve vir de
arte e áudio mantendo todo o tabuleiro compreensível.

## Base técnica

Concord atende atores; células, catálogo, perfil e geração continuam dados
simples. Baton cuida do input, o renderizador em pixels do enquadramento, anim8 das
spritesheets autorais, Flux dos efeitos e Ripple do áudio. Diálogos usam a
máquina própria em `src/dialogue.lua`; Talkies não entra nesta revisão.
Busca cardinal atende navegação.
Bibliotecas adicionais vêm de upstreams com licença registrada em
[LIBRARIES.md](LIBRARIES.md); a pasta de estudo não fornece código ou assets.

A planta procedural segue a separação entre grafo, salas especiais e interiores
descrita em [Dungeon Generation in Binding of Isaac](https://www.boristhebrave.com/2020/09/12/dungeon-generation-in-binding-of-isaac/).
O supersegredo com múltiplas conexões e as entradas por mineração são adaptações
para Arrowfallen.

O aceite final exige jogador novo compreender movimento, mineração, gesto do
arco, escudo e causa das mortes; rotas e chefe precisam permitir esquiva justa,
sem vitória imóvel ou bloqueio permanente. Save/retomada, hardware e sensação
são verificações manuais complementares aos callbacks a 30/60/144 FPS.
