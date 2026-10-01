# Arrowfallen — combate de tabuleiro em tempo real

Contrato atualizado em **01/10/2026**: apenas arco; SPACE carrega ao pressionar
e dispara ao soltar pronta. Iluminação dinâmica e fog of war foram removidos.

## Movimento e entrada

Blocos de **40 × 40**, deslocamentos exclusivamente cardinais. A posição lógica
muda no começo do salto; animação, sombra e afundamento do piso são apresentação.
Origem e destino ficam reservados durante movimento. A câmera acompanha o jogador.
WASD define direção de ataque/defesa e movimento; o último toque prevalece.

A célula autoritativa guarda solo (`floor`/`hole`) e peça
(`wall`/`pillar`/`fallen`/`portal`). Solo seguro, entrada física e bloqueio de
ataque têm consultas separadas. Paredes não têm piso acessível no topo.

## Arco, escudo e inimigos

O arco é a única arma, com **3 de dano** e **0,72s** de carga. Pressionar SPACE
começa a carga; mantê-la pronta não dispara. Soltar pronta cria exatamente uma
flecha, que segue até alvo, sólido ou borda. Soltar cedo cancela e não guarda
um disparo. Pressionar durante recuperação não cria fila. I e 1/2/3 fora da
recompensa não alteram combate ou equipamento.

Andar pode acompanhar a carga. Levantar guarda, iniciar mineração, abrir pausa
ou guia, perder foco, atravessar sala e encerrar combate cancelam o gesto. Uma
soltura pendente não dispara após retomada; precisa de novo pressionamento.
SHIFT bloqueia só pela frente e produz pulso nos blocos vizinhos. Energia finita
impede defesa permanente. Laterais e costas ficam expostas.

Brutos fixam o dash; atiradores fixam a direção de tiro. Avisos conservam área,
direção e comprimento mesmo após remover cobertura. Armadura frontal do bruto
e chefe bloqueia tiro alinhado pela frente; flancos são vulneráveis. A origem
reservada de um salto impede sobreposição, mas não recebe dano de dash quando
a posição lógica já saiu dali.

O Guardião tem **24 de vida**, cruz de quatro projéteis e dash de até quatro
blocos. Os avisos duram **1,15s**, ou **0,95s** na segunda metade da vida. A
armadura se rompe na segunda fase; recuperação oferece janela para carga.

## Mineração e consequências

Uma tentativa começa com **20 picaretas**. Cada toque de WASD contra a peça
cardinal adjacente dá um hit; hold e repetição não dão outros. Os hits 1/3 e
2/3 permanecem na peça. O terceiro gasta **uma picareta** e transforma a peça,
sem avançar; soltar e apertar novamente permite entrar. Chegar a uma parede
segurando a direção exige novo toque. Zero ferramentas impede progresso.
Moldura externa e estrutura de portais são protegidas; paredes internas são
mineráveis. Quebrar preserva o solo abaixo. Inimigos andando não mineram.

A pancada tem recuperação de **0,16s**. Há no máximo uma intenção pendente,
consumida uma vez. Ela espera ação do arco terminar e cancela carga ao começar;
guarda ativa impede mineração. Telas/foco/travessias descartam intenções.
Hits, peças removidas e estoque persistem ao revisitar; nova tentativa restaura.

Pilares exigem três hits, inclusive vindos de lados diferentes. O terceiro
lado define uma queda para longe dele. O aviso de **0,62s** congela direção e
até **cinco células** além da base. A base abre; os segmentos sólidos `fallen`
exigem três hits e uma nova picareta cada. Sólido, portal ou limite param a
queda. Buraco afunda o trecho terminal, sem ponte. Quedas simultâneas resolvem
por prazo/coordenada, podem encurtar por nova obstrução e nunca ampliar o aviso.

Esmagamento é fatal para ator na área, incluindo origem reservada do salto.
Não se desmancha a parede para salvar ocupação ou conectividade. Buraco aceita
entrada física, mas não caminho seguro: entrar compromete queda e bloqueia
novas ações. A morte ocorre no pouso antes de limpeza/recompensa/portal. Escudo,
armadura e invulnerabilidade comum não evitam morte por buraco/esmagamento.
IA evita buracos na navegação; dash comprometido pode entrar e morrer. Flechas
passam sobre buracos. Expansão de explosão pelo piso para na borda do vazio.

Cristais armados aguardam **0,62s** e dão **3 de dano** em até dois passos
cardinais. O aviso congela pisos e obstáculos terminais. Novos sólidos podem
encurtar; abrir cobertura não amplia dano. Dash/explosão usam as mesmas
transformações fortes, podem iniciar pilar e nunca gastam ferramentas do jogador.

## Leitura e salas

Não há iluminação dinâmica, ocultação por paredes nem fog of war. Todas as
células, atores e avisos são desenhados; sólidos continuam bloqueando flechas
e movimento. Buracos têm borda/profundidade própria. Paredes conectam topo,
faces e cantos; atores são ordenados pelos pés e peças pela base. Essa ordem
representa volume sem mudar colisão. F2 mantém avisos/rachaduras; M não impede
compreender o resultado. O minimapa guarda descoberta de salas; não há
ocultação dentro da sala nem coordenada Z.

A prática oferece câmara, divisória minerável com desvio, corredor de pilar,
segmento para reabrir e buraco com passagem lateral. Após limpar os inimigos
ela continua explorável; vencer exige entrar no portal leste. Outras salas
usam as mesmas peças. O layout garante rotas sem ferramentas após quedas,
em vez de desfazer consequências da armadilha. As salas são retângulos de
13×9, com arena do chefe de 15×9 e prática de 17×11. A câmera enquadra a sala
inteira. A faixa protegida na borda interna une todas as chegadas e saídas;
prévia e queda de pilar param antes dela. A garantia é de chegada → chegada,
saída e posições de combate, inclusive após transformações e sem ferramentas.

## Expedição e arquitetura

Busca em largura gera uma árvore de salas cardinais, com início em (0,0).
O primeiro andar tem **7 ou 8 salas regulares**, crescendo **2 ou 3** por andar.
O chefe ocupa uma folha à maior distância do início; tesouro, loja e refúgio
ocupam outras pontas. O conteúdo de cada sala é escolhido depois da planta.
O refúgio recupera **4 vida uma vez**.

Secreta e supersecreta são duas salas adicionais em células vazias adjacentes
a várias regulares, sem tocar o chefe ou uma à outra. Portas ocultas nos dois
lados são paredes mineráveis; quebrar abre o par recíproco e revela a conexão.
As conexões extras podem produzir ciclos; a árvore regular permanece intacta.
O tijolo secreto usa a aparência dos vizinhos; um brilho suave de 0,30s a cada
4 segundos sugere a entrada, sem descobrir a sala nem iluminar o tabuleiro.
A secreta contém dois guardas; a supersecreta contém três alvos que só aceitam
flechas do jogador. Alvos acertados persistem em revisitas. Desafios dão um
eco e ouro uma vez (4/6), e a supersecreta recupera 2 de vida ao concluir.
Não há recompensa apenas por entrar. Dentro de um segredo, todas as passagens
abrem sem ferramentas e permitem sair antes de vencer o desafio.

Combates rendem **2 ouro uma vez**. A compra de mapas foi retirada até haver
NPCs comerciantes; a sala da loja permanece vazia, sem balcão funcional.
O minimapa mostra apenas descobertas e vizinhos ligados por portas abertas.
Vida, ouro, ferramentas e melhorias persistem na descida;
descobertas e conteúdo são novos a cada andar. ENTER após o portal do
chefe inicia o próximo andar. Salas 2×2/L não fazem parte desta primeira etapa.

Combates anteriores ao chefe oferecem três ecos; a escolha congela simulação.
Ecos disponíveis: `bowPierce`, `bowQuick`, `guardPulse`, `damage`, `heal`,
`pickaxes` (+3 ferramentas). Dano, cura e ferramentas podem repetir para
manter três escolhas após obter as melhorias únicas.
Perfuração custa um dano por flecha; nenhum eco cria disparo automático.
Seed fixa determina ofertas; melhorias únicas não reaparecem. Após o chefe,
a saída abre diretamente. O tesouro também oferece um eco, sem permitir
recompensa duplicada em revisitas. Limpeza remove projéteis inimigos e cristais armados.

Concord mantém atores, projéteis e cristais. `Game` guarda estoque/sala e resolve
movimento, dano e morte fatal; `Rooms` contém células e busca cardinal;
`Environment` transforma peças; `Input` distingue toque/hold/soltura. Desenho e
feedback consomem estado sem determinar regras. Bibliotecas vêm de upstreams;
código/assets da pasta de estudo não são fontes do jogo.

## Validação

Os comandos em [tests/README.md](../tests/README.md) verificam terreno, arco,
escudo, chefe, progressão e geração. Replays vencem prática/expedição por saída
explícita sem alterar atores, vida ou temporizadores; reprodução usa 30/60/144
FPS e simulação a 120 Hz. Callbacks reais cobrem gesto SPACE/cancelamento,
mineração/hold/repetição/telas/foco/zero e parede → pilar → segmento → buraco.
Busca cardinal valida desvios sem ferramentas em 100 seeds e direções de queda.

`test-results.txt` e `ui-test-results.txt` guardam a execução atual. Nenhum pacote
portátil foi atualizado. Teclado humano, leitura durante combate e sensação de
jogo continuam como aceite manual; automação não substitui essa sessão.
