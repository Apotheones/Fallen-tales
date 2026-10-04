# Abertura HD — cripta, saída e chegada ao Refúgio

Doc de direção narrativa e experiência. Pena, 04/10/2026. Status: proposta
para revisão do time (Traço, Pátio, Prisma, Combate). Descreve o começo
jogável inteiro — da cova fechada à praça — pensado para o pipeline HD
(MEGAPLAN_VISUAL_HD) e a gramática de luz de DIRECAO_AMBIENTAL_HD.

**Substitui:** `LoreC.introCutscene` (slideshow de 7 quadros), `LoreC.intro`
e a inscrição de chegada embutida em `Campaign:enter('hub')`.

**Preserva:** etapas P01-E01..E05 da [ficha 01](mapas/01_COLINA.md), flags e
steps existentes, o duelo consensual C01-Q1 e o panorama do mirante
(`panoramaTime`, já implementado). Nada aqui muda fatos: toda informação
proposta vem da ficha 01, de BASE_NARRATIVA e de REFUGIO_HISTORIA §4–5.

## 0. Diagnóstico — por que a abertura atual falha

- **É um slideshow, não uma cena.** Sete quadros seguidos antes do primeiro
  input ensinam que o jogo é algo que se assiste apertando ENTER — a lição
  errada logo de cara.
- **A legenda carrega o que a imagem devia carregar.** "De pé sobre a
  própria sepultura. O mesmo arco, o mesmo corpo — sete anos mais tarde" é
  narração fazendo o trabalho da câmera. No HD, a câmera mostra isso de
  graça.
- **Informação errada na ordem errada.** Os quadros falam de "a marca que a
  casa prega nos que guarda" — lore que o jogador não tem como usar — e não
  respondem o que ele realmente pergunta: onde estou, por que voltei, para
  onde vou.
- **Gasta o melhor momento.** A descida cripta→refúgio é a transição
  frio→âmbar que DIRECAO_AMBIENTAL já nomeia como "a dramaturgia do
  despertar" — e hoje vira duas linhas de inscrição genéricas.

## 1. Tese

A abertura é **jogada, não lida**. O jogador desperta com controle quase
imediato; a informação essencial mora no mundo (tampa deslocada, velório
desmontado, marca partida, luz que esquenta na descida) e nas duas pessoas
que ele encontra (Doro, Runa). Texto só assina o que a imagem já disse.

Regras duras:

- **Controle ≥ 90% do tempo.** Trecho sem controle: no máximo 2 quadros, no
  máximo ~15 segundos, pulável com ESC sem perder nada.
- **Uma ideia por texto.** Caixas de 1–2 linhas; falas entre 8 e 25
  palavras; narração sempre na voz `inscription`, nunca fingindo onisciência
  sobre o que ele sente.
- **Nada relido.** Morte não repete abertura; revisita usa `colinaRevisit`.
- **A luz conta a história.** Violeta frio da Colina → âmbar do Refúgio é o
  arco visual inteiro: pedra que guarda mortos → fogo que guarda vivos.

## 2. Orçamento de texto

| Trecho | Teto | Forma |
| --- | --- | --- |
| Ato 0 (dentro do caixão) | 2 quadros, 1 linha cada | screen `opening`, pulável |
| Câmara e pátio (interações) | 1–2 linhas por hotspot | voz `inscription` |
| Conversa Doro | 3 linhas dele + 3 opções | diálogo normal |
| Pertences/casaco | 2 linhas | inscription |
| Runa | 3 linhas dela + 4 opções | diálogo normal |
| Mirante (revelação) | 3 inscrições, disparadas por distância | inscription |
| **Total até a praça** | **~30 linhas exibidas** (hoje ~60+ entre quadros e inscrições) | — |

## 3. Os beats

### ATO 0 — DENTRO (não jogável, ≤15s, ESC pula)

**O que comunica:** você estava enterrado; alguém abriu isso por fora, e
recentemente. Só isso — sem nomear nada.

| Quadro | Imagem | Texto |
| --- | --- | --- |
| A | Preto total. Som de terra e respiro curto. | `Escuro. Terra por cima.` |
| B | A frincha: a tampa entreaberta vista de baixo, luz fria entrando pela borda. | `A tampa cedeu. Do lado de fora, um encaixe recém-trocado.` |

O quadro B já planta o fato material (reparo recente) que Doro vai confirmar
em voz — a informação chega duas vezes: primeiro pela imagem, depois pela
pessoa. Os quadros `marca`, `cova`, `viajante`, `colina`, `grade` e
`refugio` do slideshow atual saem daqui — viram uso possível em tela de
título/códice ou são cortados; o mundo jogável os substitui.

### ATO 1 — A CÂMARA (jogável, ~2 min)

**O que comunica:** você é um dos sepultados — sepultura comum, não
monumento. E algo prendia essa cova.

- O jogador acorda **de pé junto da cova**, câmera já solta. A câmara é
  quase escura: a única luz clara é a borda do corredor de saída. O vazio ao
  redor da cova é decisão (DIRECAO_AMBIENTAL: clearing próprio).
- Sem linha de objetivo nos primeiros ~20s: a sala ensina movimento porque a
  saída é o único lugar iluminado.
- Interações opcionais (todas já existem como hotspot ou são props novos
  baratos):

| Ponto | Texto (inscription) | O que planta |
| --- | --- | --- |
| `tampa`/cova | `Oitavo encaixe, lado de dentro: o único rachado. Alguém o trocou esta noite.` | reparo externo — a abertura não foi sua |
| `marcaPartida` *(prop novo)* | `A marca na pedra está partida ao meio. O traço ainda parece recente.` | a vedação — payoff visual no mapa 10 |
| `lapideProt` | `Tem o seu nome. A data de morte está certa. A de nascimento, errada.` *(proposta)* | o registro erra — fissura do encobrimento |
| `sepultura` | `Sua cova continua aberta. Do tamanho de qualquer outra.` | comum, não escolhido |

- Corredor ao pátio: estreito, e **som** de atividade crescendo — passos,
  ferro, fogo. Antes de ver qualquer pessoa, o jogador já sabe: há vivos
  aqui.

### ATO 2 — O PÁTIO DO VELÓRIO (jogável, ~5 min)

**O que comunica:** os vivos cuidam dos seus mortos — e o velório que ele
atravessa desmontado **era o dele**.

- Compressão→revelação: o corredor abre no pátio. Primeiro calor da paleta:
  braseiro/velas do velório (#D8BA78 — ouro só no detalhe de cuidado).
  Banco, pano dobrado, flores meio murchas. Nenhuma linha explica "velório":
  os props dizem.
- **Doro** está trabalhando, não esperando de postura de NPC. Ao interagir
  (P01-E01):

> **Doro:** "Você está de pé. A tampa cedeu e eu... pensei que fosse só a pedra cedendo."
> **Doro:** "Eu troquei o encaixe rachado da sua cova hoje de manhã. Foi isso que abriu. Desculpa."
> **Doro:** "Sou Doro. Cuido das sepulturas daqui — e dos reparos, quando deixam."
> **Opções:** `EU ESTAVA AÍ DENTRO?` / `O QUE É ESTE LUGAR?` / `EU PRECISO VOLTAR PRA CASA.` *(nova)* / `SAIR`

Respostas (mantém o material atual; a terceira opção é proposta nova):

- `EU ESTAVA AÍ DENTRO?` → "Sete anos. A casa inteira jurou que era pra
  sempre." + indicação do depósito.
- `O QUE É ESTE LUGAR?` → "Colina dos Sepultados. Em cima ficam os que a
  cidade guardou. Embaixo ficam os que ficaram — o refúgio é pela grade ao
  sul."
- `EU PRECISO VOLTAR PRA CASA.` *(nova)* → Doro: "Entendo. Casa fica pra
  fora daqui — e a saída da Colina passa pela grade da Runa primeiro." —
  planta o desejo (Lia, sem nomeá-la) como motivo do jogador, não como
  exposição. **Continuidade:** Doro não conhecia Lia; a resposta dele é
  sobre caminho, não sobre ela.

- Pertences no depósito (P01-E02): manter as duas linhas atuais do casaco —
  "O remendo no cotovelo é ponto torto — Lia ria do próprio acabamento." —
  que já entregam Lia em uma imagem concreta, sem flashback.

### ATO 3 — A GRADE (jogável, ~3–5 min)

**O que comunica:** a versão oficial existe — e já pode ser contestada aqui,
na primeira hora de jogo.

Runa segura a descida. Fala seca, distância física real (ela do posto, ele
do lado de fora). Proposta: inserir na conversa atual a linha que planta a
mentira oficial, hoje ausente:

> **Runa:** "A vedação dessa cova era serviço meu — e alguém a rompeu essa noite."
> **Runa:** "Todo mundo diz que você se ofereceu. Foi o que eu ouvi a vida inteira." *(linha nova proposta)*
> **Opções:** `FUI EU. SAÍ DA MINHA COVA.` / `DORO ROMPEU, NUM REPARO.` / `EU NÃO ME OFERECI. EU CORRI.` *(nova)* / `DEMONSTRAR CAPACIDADE.`

- `EU NÃO ME OFERECI. EU CORRI.` → Runa: "...Eu não estava lá. Repito o que
  me contaram." — abre a suspeita **sem** revelar participantes; consistente
  com a ficha (ela não estava na decisão) e com a base (versão oficial =
  sacrifício voluntário). Abre a grade por acordo, como as outras opções
  honestas — ou deixa ela pedir a demonstração, a critério do Combate.
- `DEMONSTRAR CAPACIDADE.` → duelo consensual C01-Q1 (inalterado).

**Continuidade:** nenhuma resposta aqui decide final nem apressa a
revelação; é a primeira fissura, não a explicação.

### ATO 4 — A DESCIDA E O MIRANTE (semi-jogável, ~1 min) — o momento-chave

**O que comunica:** a casa dos que ficaram — inteira, de uma vez, antes de
qualquer nome.

- Cruzada a grade, a escadaria desce: a **luz transiciona** violeta→âmbar
  célula a célula (gradiente já previsto como dramaturgia). Som antes de
  imagem: panela, voz chamando pra comer, pano batendo na janela.
- No mirante, o jogador **mantém controle**, mas o enquadramento abre para o
  panorama do Refúgio (reuso do `panoramaTime`, estendido: a vista fica
  enquanto o jogador andar pelo parapeito). Três inscrições disparam por
  **distância percorrida** no parapeito, não por ENTER — o texto acompanha o
  corpo andando:

> 1. `O cheiro de lenha chegou antes das casas.`
> 2. `Os caminhos desciam entre telhados e terminavam na praça.`
> 3. `Você procurou Lia entre aqueles sons — antes de lembrar que ela nunca morara ali.`

(Trecho do texto de chegada de REFUGIO_HISTORIA §5, adaptado. A última
linha é o payload emocional: estabelece Lia **e** a distância dela sem uma
cena de flashback.)

- **Continuidade:** nada aqui promete que Lia está no Refúgio — a linha diz
  exatamente o contrário. Não mostrar placa, nome ou lore do marco ainda: a
  pedra de nomes se lê de perto, na praça.

### ATO 5 — A PRAÇA (jogável; P01-E05, inalterado em estrutura)

**O que comunica:** você é esperado — e ainda assim é estranho.

- Bento oferece comida **antes** de perguntar nome ("comida antes da
  pergunta" — tradição do §4 em gesto, não em explicação).
- Teca mostra o espaço; Aurel se apresenta curto, sem história. O marco de
  nomes fica para o jogador ler por conta própria.
- Nada de selo, acolhimento formal ou explicação do pacto na chegada:
  visitar não é receber selo — regra da base, regra da cena.

## 4. O que cada imagem comunica (e o que não deve)

| Imagem | Leitura pretendida | Não comunicar |
| --- | --- | --- |
| Preto + fresta na tampa | estava enterrado; abriram por fora | quem, por quê, ritual |
| Câmara escura, clearing da cova | um morto a mais entre muitos | eleição, profecia, monumento |
| Marca partida na pedra | algo prendia; alguém quebrou | pacto, selo, mecânica da proteção |
| Pátio: braseiro + flores murchas | velório recente; cuidado dos vivos | religião, regras da casa |
| Grade + Runa de longe | controle de passagem; medo sem crueldade | a verdade do crime |
| Escadaria esquentando | saída; o mundo voltou a ter cor | — |
| Panorama do mirante | comunidade inteira e viva; seu lugar possível | nomes, mapa, quest markers |
| Praça: comida antes de nome | eles recebem gente; você ainda é estranho | pertencimento, perdão, selo |

## 5. Informação garantida vs. proibida

O jogador deve sair da praça sabendo:

1. Morreu, foi enterrado e voltou — sete anos depois.
2. A abertura foi acidente de reparo (Doro, em voz própria).
3. Tem um destino pessoal: voltar pra casa / Lia existe e não está aqui.
4. O Refúgio é a casa dos que ficaram — e a versão oficial ("se ofereceu")
   já tem uma rachadura.
5. Próxima ação concreta: onde dormir, o que pegou de volta, pra onde ir
   (oficinas ou mercado, P01-E06).

Proibido antes do mapa 8 (conforme base): mecânica do pacto e do selo, lista
de participantes, finalidade do rito, catástrofe nomeada, qualquer fala de
Aurel ou Bento que confesse sem ser perguntado.

## 6. Contrato com o time

**Traço/Prisma (arte e luz):**

- Prop novo `marcaPartida` na câmara da cova: traço partido, emissivo
  violeta discreto (ei~0.3 — resíduo, não farol; DIRECAO_AMBIENTAL §Colina).
  A mesma marca reaparece vista por baixo no mapa 10 — desenhar pensando nos
  dois ângulos.
- Gradiente de luz na escadaria da descida (violeta→âmbar por célula) e o
  panorama do mirante com enquadramento aberto — substitui os quadros
  `grade`/`refugio`/`colina` do slideshow.
- Quadros do Ato 0: apenas `caixao` (preto) e `tampa` (frincha) — os demais
  painéis de `introPanels` saem da abertura (reuso em título/códice é
  decisão do Traço, fora deste doc).

**Pátio (mapa/colina.lua):**

- Posicionar `marcaPartida` na parede da câmara, legível da cova; hotspot
  `marcaPartida` já resolve texto via `LoreC.hotspot` (id novo, texto §3).
- Três pontos de inscrição por distância no parapeito do mirante (gatilhos
  de chão, não de tempo): as linhas do Ato 4.
- O resto da planta (cova, pátio, depósito, grade) já está montado conforme
  a ficha — este doc não pede geometria nova.

**Narrativa→código (Pena):**

- `LoreC.introCutscene` encolhe para 2 quadros (`caixao`, `tampa`); os
  `lines` acima substituem os atuais.
- `LoreC.intro` some (o ato 0 o cobre). A inscrição de chegada em
  `Campaign:enter('hub')` é substituída pelos gatilhos do mirante.
- Acrescentar ao talk de Doro a opção `EU PRECISO VOLTAR PRA CASA.` e ao de
  Runa a linha "se ofereceu" + opção `EU NÃO ME OFERECI. EU CORRI.` —
  ambas marcadas como proposta neste doc.
- `panoramaTime` passa a vigorar enquanto o jogador estiver no parapeito do
  mirante na primeira visita (em vez de 5s fixos) — ajuste de gatilho, não
  de render.

**Combate:** nenhum pedido novo — C01-Q1 já cobre o duelo consensual.

## 7. Morte, revisita e acessibilidade

- Morrer na grade devolve à sepultura com a fala curta de retorno
  (`LoreC.deathReturn`, já existe). Ato 0 e inscrições de primeira visita
  **não** repetem.
- Revisita à Colina usa `colinaRevisit` (já existe) — o texto reconhece o
  estado, não reencena.
- ESC pula o Ato 0 por inteiro; reduced-motion corta fades entre quadros
  (já implementado no renderer).
- Datilografia a 55 car/s com blip por falante: todas as falas deste doc
  foram contadas para ritmo falado (8–25 palavras); strings usam só o
  conjunto de glifos da fonte (regra `Font.clean`).

## 8. Checklist de continuidade

- [x] Doro quebrou a vedação sem saber — acidente de reparo, não rito.
- [x] Runa repete a versão oficial e admite não ter estado na decisão;
      nenhum participante é nomeado.
- [x] Casaco/remendo entregam Lia por objeto; a linha do mirante entrega a
      ausência dela — nada de flashback, aparição ou notícia recente.
- [x] Comida antes da pergunta aparece como gesto de Bento, não explicação.
- [x] Chegar ao Refúgio não concede selo, perdão nem pertencimento.
- [x] A marca partida plantada aqui paga no mapa 10 (vista por baixo).
- [x] Derrota não é morte; a grade abre por diálogo ou duelo consensual.
