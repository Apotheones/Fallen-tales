# ARROWFALLEN — A Câmara dos Ecos

Roguelike de ação em tempo real em Lua para **LÖVE 11.5**. Movimento cardinal,
um arco, escudo, cristais explosivos, paredes mineráveis e pilares que criam
cobertura. Leia o aviso, saia da linha e ataque pelo flanco.

## Jogar

O cenário é desenhado pelo próprio jogo: pisos, paredes, pilares, segmentos
caídos e buracos. Prática e expedição usam a mesma grade e as mesmas regras.

No Windows, abra **`Jogar.bat`** na raiz. Ele encontra o LÖVE em
`C:\Program Files\LOVE\love.exe` ou no PATH. Pelo terminal:

```text
love .
```

**ENTER** inicia a prática com arco. Ela continua explorável após limpar os
inimigos e termina ao entrar no portal leste. **N** inicia uma expedição gerada
por seed: vença os combates, escolha ecos e entre na saída após o chefe. **ENTER**
na conclusão desce ao próximo andar, conservando vida, ouro e melhorias. O refúgio
opcional recupera **4 de vida uma vez**; salas vencidas podem ser revisitadas.

## Controles

| Tecla | Ação |
| --- | --- |
| WASD | Mover um bloco; um toque contra peça adjacente dá uma pancada; última direção define ataque/defesa |
| SPACE, pressionar e segurar | Carregar o arco; mesmo pronta, a carga espera a soltura |
| SPACE, soltar | Disparar uma vez se pronta; soltar cedo cancela |
| SHIFT, segurado | Erguer escudo na direção em que olha; cancela a carga |
| 1 / 2 / 3 | Escolher um dos três ecos somente na recompensa |
| TAB | Abrir/fechar guia; ESC ou ENTER também fecham |
| ESC | Pausar/retomar; ENTER também retoma |
| R | Na pausa ou ao terminar: reiniciar com a mesma seed |
| N | No menu ou ao terminar: começar uma nova expedição |
| Q | Na pausa ou ao terminar: voltar ao menu |
| F11 | Alternar tela cheia |
| F2 | Alternar efeitos de movimento reduzidos |
| M | Alternar áudio |

O arco é a única arma. **I** e números fora da recompensa não alteram combate
ou equipamento. O arco causa **3 de dano**, carrega em **0,72s** e a flecha segue
até alvo, parede ou borda. Você pode andar carregando. Segurar SPACE não dispara
sozinho; recuperação exige um novo gesto. Guarda, mineração, pausa, guia e
perda de foco cancelam a carga; uma soltura antiga não dispara na retomada.

## Transforme o cenário

A tentativa começa com **20 picaretas**. Uma parede ou pilar adjacente exige
**três toques separados de WASD**: os dois primeiros deixam rachaduras; o
terceiro gasta **uma picareta**. Segurar a direção não repete hits. A quebra
mantém você no bloco original; solte e pressione de novo para entrar no vão.
Piso comum não recebe hits; moldura externa e portais são protegidos.

Um pilar tomba para longe do lado atingido no terceiro hit. Um aviso de
**0,62s** congela sua trajetória de até **cinco blocos**. A base abre e o corpo
vira segmentos sólidos. Cada segmento exige outros três hits e uma picareta
para abrir um vão. Sólidos e portais interrompem a queda. Quem ficar na área
anunciada morre por esmagamento, inclusive inimigos; escudo e imunidade comum
não impedem essa morte.

**Buracos** têm borda e profundidade próprias. Entrar compromete o salto e
causa morte no pouso; outro passo não pode salvar a queda. Flechas passam sobre
o vazio. A IA evita buracos ao navegar, mas uma investida comprometida pode
cair. O pilar afunda ao encontrar um buraco, sem criar uma ponte.

A pancada cancela a carga e espera a recuperação do arco; guarda ativa impede
mineração. Sem picaretas, o contato mostra **Sem picaretas** e preserva os hits.
Danos parciais, peças e estoque persistem nas revisitas; outra tentativa
restaura tudo. Explosões/dashes transformam peças sem gastar suas ferramentas
e nunca atingem além do aviso já emitido. Há desvios sem ferramentas.

A prática de **17×11** oferece câmara, divisória minerável, corredor de queda, segmento
para reabrir e buraco com passagem lateral. As paredes têm topo/faces/cantos
e profundidade pela base. **Não há iluminação dinâmica ou fog of war**:
células, atores e avisos permanecem visíveis. Paredes continuam bloqueando
movimento e flechas. F2 e M mantêm progresso e perigos legíveis.

## Combate e ecos

Cada andar começa no centro de uma grade. Uma busca em largura cria **7 ou 8
salas comuns/especiais no primeiro andar**, aumentando **2 ou 3** por andar.
Essas salas formam uma árvore, sem ciclos. O chefe ocupa a ponta mais distante;
loja, tesouro e refúgio ficam em outras pontas. O minimapa acompanha as portas
reais e mostra salas visitadas e seus vizinhos conhecidos. As salas comuns têm
**13×9 blocos**, e a arena do chefe **15×9**. A câmera mostra o retângulo inteiro.
Um corredor na borda interna conecta todas as entradas e saídas; pilares param
antes dessa faixa. **Chegar ao chefe nunca exige picaretas**, mesmo após quedas.

Existem mais duas salas ocultas: **secreta** e **supersecreta**, adjacentes a
várias salas, sem tocar o chefe ou uma à outra. As entradas parecem paredes:
três pancadas gastam uma picareta e abrem uma conexão nos dois lados. O tijolo
tem a mesma aparência da parede e um brilho suave a cada **4 segundos**.
São desvios opcionais: a secreta propõe vencer dois guardas; a supersecreta
propõe acertar **três alvos com o arco**. A recompensa só vem ao concluir:
um eco e **4 ouro**, ou um eco, **6 ouro e 2 vida**, respectivamente. O progresso
dos alvos persiste em revisitas. Entrar abre as saídas por dentro, sem gasto
extra; é possível desistir do desafio e voltar. Cada combate comum vencido
rende **2 ouro**, uma vez.

O tesouro oferece um eco uma vez. A compra de mapas foi retirada; a sala da
loja está vazia. Vendas só entrarão junto dos NPCs comerciantes. O minimapa
atual registra apenas descobertas durante a exploração.
Os interiores continuam retangulares; salas 2×2 e em L são uma etapa futura.

Bruto e chefe possuem armadura frontal. Avisos congelam direção e área; use
esse tempo para esquivar e flanquear. O escudo bloqueia apenas pela frente e
produz um pulso nos blocos vizinhos. A energia acaba se mantiver a guarda.

Cristais âmbar armados pelo arco, projétil ou dash explodem após **0,62s**, por
**3 de dano**, em até dois passos cardinais pelo piso. Paredes e buracos limitam
a expansão; você também pode ser atingido. Há reações em cadeia.

As recompensas mostram três escolhas entre **perfuração do arco**, **carga
mais rápida**, **pulso de escudo**, **dano**, **cura** e **três picaretas**. Perfuração custa um de
dano por flecha. Escolher pausa a simulação; nenhum eco dispara automaticamente.
O Guardião tem **24 de vida**, alterna cruz de flechas e dash. Avisos duram
**1,15s**; com metade da vida ou menos, **0,95s**, e a armadura se rompe.

## Projeto e verificação

Gameplay e sons sintetizados são originais. **Concord, Baton,
hump.camera, Flux e Ripple** estão vendorizados; versões e licenças em
[docs/LIBRARIES.md](docs/LIBRARIES.md). Células são dados da sala; Concord
mantém atores. A simulação usa passos de **1/120s**; animações não decidem regras.

Execute `Testar.bat` ou:

```text
love . --test
love . --ui-test
```

Os resultados ficam em `test-results.txt` e `ui-test-results.txt`.
[tests/README.md](tests/README.md) descreve a cobertura;
[docs/DESIGN.md](docs/DESIGN.md) registra o contrato atual.

O pacote em `build/Windows` pertence à entrega anterior; esta revisão não o
atualiza. `python tools/package.py` reconstrói `.love` e, quando houver runtime
instalado, a versão portátil com suas licenças.
