# Arrowfallen — cenário interativo por movimento

Plano original de **30/09/2026**, revisado em **01/10/2026** conforme prioridade
do jogador. As regras abaixo são o contrato atual: **somente arco**, SPACE
pressiona/segura para carregar e solta pronta para disparar; **sem iluminação
dinâmica ou fog of war**. Substituem propostas anteriores que dependiam de
ocultação geométrica ou de três armas. A implementação está no código; aceite
com teclado humano continua pendente.

## Experiência

WASD move e age sobre a peça imediatamente à frente. Três pancadas abrem uma
parede e gastam uma picareta. Um pilar tomba para longe do lado atingido e cria
uma parede comprida, que pode ser quebrada por segmentos. Buracos matam quem
salta para eles, inclusive inimigos durante investida. Mineração compete com
o tempo de carregar/disparar o arco ou esquivar em combate real.

## Contrato de cenário

| Regra | Comportamento |
| --- | --- |
| Alcance | Somente peça adjacente cardinal; sem diagonal ou mineração distante |
| Toques | Uma pancada por toque WASD; hold e repetição do teclado não repetem |
| Parede | Três hits; os dois primeiros mantêm estoque; o terceiro gasta uma picareta |
| Estoque | 20 no começo da tentativa; zero impede qualquer progresso parcial |
| Movimento após quebra | Terceiro hit não avança; solte e dê novo toque para entrar |
| Chegar segurando WASD | Movimento para na peça; novo toque é necessário para minerar |
| Persistência | Hits/peças/estoque permanecem nas revisitas; nova tentativa restaura |
| Recuperação | Pancada 0,16s; no máximo uma intenção pendente, consumida uma vez |
| Arco e guarda | Pancada espera ação do arco, cancela carga; guarda ativa impede mineração |
| Pilar | Três hits; o terceiro lado fixa queda oposta ao lado de onde veio o hit |
| Corpo caído | Até cinco células além da base; base abre; cada segmento é peça independente |
| Aviso | 0,62s, direção e células congeladas; custo único no terceiro hit |
| Segmento | Três hits e outra picareta para cada vão |
| Sólido/portal/limite | Queda para antes do primeiro obstáculo |
| Buraco na trajetória | Trecho terminal afunda; buraco permanece; sem ponte automática |
| Ator no aviso | Esmagamento fatal; não cancelar queda para salvar ocupação/conectividade |
| Entrada em buraco | Compromete queda e bloqueia novas ações; morte no pouso |
| Prioridade fatal | Morte vem antes de limpeza, recompensa, vitória ou travessia |
| Proteção | Moldura externa e estrutura dos portais; peças comuns internas mineráveis |
| Força externa | Dash/explosão completam transformações sem gastar picaretas |
| Tiro | Flechas comuns bloqueadas por sólidos e não mineram; passam sobre buracos |
| Navegação | Busca voluntária usa piso seguro; dash comprometido pode entrar no buraco |

Os números **20, 3, 5, 0,16s e 0,62s**, além da letalidade de esmagamento,
ficam em valores nomeados para ajuste. Escudo, armadura e imunidade de dano
não anulam morte por queda/esmagamento. Inimigos andando não usam ferramentas.

## Contrato do arco e entrada

O arco é a única arma e não existe seleção por 1/2/3. Pressionar SPACE inicia
carga; segurar até pronta mantém o estado sem disparar. Soltar pronta dispara
uma vez; soltar cedo cancela e descarta a carga. Pressionar durante ação não
enfileira outra carga. I não participa do combate. Os números escolhem os três
ecos somente quando a recompensa está aberta.

Guarda, mineração, pausa, guia, perda de foco e travessia cancelam gesto/carga.
Buffers e solturas pendentes são descartados; retomar exige novo SPACE. O
sistema operacional não duplica edges. Movimento a 120 Hz usa direção mantida
para andar e toque separado para minerar; não colocar mineração em `Game:move`,
que também atende inimigos.

## Células e transformações

```lua
room.tiles[key] = {x = x, y = y, ground = "floor", piece = "wall", hits = 0}
```

Solo distingue `floor`/`hole`; peça distingue `wall`/`pillar`/`fallen`/`portal`.
Células vazias guardam só solo. Estado/direção/timer/células de queda pertencem
ao pilar pendente. Não existem mapas mutáveis separados de walls/structures/
rubble. Remover peça preserva solo. Células são dados da sala, não entidades ECS.

`Rooms` oferece consultas distintas para piso seguro, entrada física e bloqueio
de ataque. `Environment` transforma peças; `Game` guarda estoque e resolve
movimento/morte; `Input`/`Systems.Player` separam toque/hold/soltura. Desenho
apenas apresenta estado. A revisão da sala muda com transformações.

Quedas simultâneas têm ordem por prazo/coordenada. Nova obstrução pode encurtar
resultado; remover barreira durante aviso nunca amplia a área. Dash, explosão
e tiros inimigos também ficam limitados ao aviso emitido. Explosão se expande
pelo piso e para em buracos; paredes atingidas são terminais.

## Apresentação e referências

As seis imagens fornecidas orientaram arquitetura modular com topo/faces,
cantos, câmaras e corredores. Elas não demonstravam hits, estoque, hold,
letalidade ou direção de pilar; essas regras vêm do relato do jogador.

A prioridade revisada remove a iluminação dinâmica e o fog of war. Todas as
células, atores e avisos são desenhados, inclusive além das paredes. Paredes
continuam bloqueando colisão e flechas; quebrar abre passagem/linha de tiro.
Não manter infraestrutura de visibilidade para uma função removida.

Peças conectam desenho conforme vizinhos restantes; quebrar atualiza cantos e
terminações. Atores ancoram pelos pés e peças pela base; ordem de profundidade
representa volume, sem criar colisão no topo do sprite. Buraco conhecido tem
borda/profundidade; piso comum não parece vazio. Estoque, rachaduras 1/3 e 2/3,
golpe sem deslocamento, lascas/som e aviso congelado informam a interação.
F2 mantém progresso/perigos, e M permite compreender o resultado sem áudio.
Não há coordenada Z, piso no topo, subida automática ou memória de exploração.

## Sala de referência e liberdade

Prática compacta de 17×11, spawn (3,6), divisória em x=5 e desvio inferior.
O corredor a leste oferece inimigo, pilar (8,4) com queda leste de cinco células,
segmentos para reabrir e buraco (11,8) com passagem lateral. Limpar os inimigos
mantém a sala jogável; o portal leste (17,6) conclui explicitamente.

Salas comuns seguem a faixa do arquétipo (13×9 a 15×9 ou 13×11); chefe, 15×9.
A borda interna reserva um corredor seguro:
prévia e queda param antes dessa faixa. Todas as chegadas permanecem ligadas
a todas as saídas normais após quedas, sem ferramentas. Segredos são desvios
opcionais de combate/pontaria; o tijolo de entrada se mistura aos vizinhos e
brilha discretamente a cada 4s. Retorno e conexões internas são gratuitos.
Vendas de mapas ficam adiadas para os NPCs comerciantes.

Picaretas são finitas. As outras salas recebem peças, atalhos e armadilhas
com desvio que não exige ferramentas. Queda não é desfeita porque mudou o
melhor caminho. Spawn e chegadas/saídas não ficam em trajetórias fatais;
busca cardinal valida direções de pilares, combinações de quedas, inimigos e
rotas com zero ferramentas. Isso é garantia do layout — e a geração a reforça:
`pruneUnsafePillars` simula todas as combinações de queda dos pilares da sala
e remove qualquer um capaz de isolar um ator; o portão selado violeta é o único
custo de rota planejado (3 ouro ou 1 picareta) e nunca fica no caminho do chefe.

## Entregas e aceite

1. Células/pancadas/custo único e preservação do solo.
2. Pilar de cinco células, aviso, esmagamento e mineração por segmento.
3. Buracos, navegação segura, dash fatal e prioridade de pouso.
4. Estoque/rachaduras/feedback, paredes conectadas e profundidade; sem fog/luz.
5. Prática explorável e saída explícita; peças/desvios nas salas da expedição.
6. Testes e documentação para apenas arco com gesto SPACE.

`tests/terrain.lua` valida três hits, custo, adjacência, zero, proteção,
revisita/reset, quatro lados/hits mistos, segmento independente, quedas
simultâneas/fixas, obstáculos/portais/buracos, ataques e mortes fatais.
`tests/combat.lua` preserva combate/chefe/progressão e replays até a saída.
`tests/ui.lua` chama callbacks reais para hold/repetição/pending/telas/foco,
cancelamentos de SPACE e sequência parede → pilar → segmento → buraco sem
teleportar ou chamar mineração diretamente. Simulação e callbacks são
verificados em **30, 60 e 144 FPS**. Desenho não determina regras.

Rodar com teclado humano a sequência **parede → pilar → armadilha → segmento
→ buraco** e reconhecer as causas/avisos continua sendo o aceite principal.
A automação sustenta esse aceite, não o substitui. Sem atualização de pacote,
publicação, lore, loja, XP ou produção final de assets nesta revisão.
