# 06 — Quartos da Fundação

Proposta coordenada com [BASE_NARRATIVA](../BASE_NARRATIVA.md), [PLANO_CAMPANHA](../PLANO_CAMPANHA.md) e [FICHA_MAPA](FICHA_MAPA.md). Nomes novos: **Dalva** e **Geraldo**. Escrita para implementação futura; não descreve funcionalidades já prontas.

## 1. Função e acesso

As resoluções principais de 4 e 5 permitem alcançar o antigo complexo sem atravessar o setor inundado ou a ala desabada. Sabela pede mesas, encostos e painéis para preparar a escola. A identificação do alojamento encontrada nas duas regiões faz o protagonista reconhecer onde passou temporadas de trabalho com Lia.

O pedido cotidiano leva a uma descoberta: seu registro diz que partiu voluntariamente antes da violência que lembra ter sofrido. A região abre **7, Armazéns da Partida**, e **8, Necrópole Submersa**, sem exigir subquests, melhorias ou mortes de chefes.

## 2. Direção visual e lugares garantidos

**Paleta:** pedra `#575B60`, cal `#B6B2A7`, madeira `#78563F`, tecido azul `#657A86`, sinal de interação `#D7AC5D`. Materiais: reboco lascado, madeira encerada pelo uso, cobertores remendados e ferragens opacas. A silhueta predominante é horizontal: dormitórios baixos e pequenos quartos entre paredes longas. Evitar transformar todo o alojamento em cripta.

**Marcos:** pátio com varal; corredor de portas numeradas; quarto com janela empenada; depósito de mobiliário; arquivo com uma grande mesa atravessando o acesso. O quarto conserva uma mancha de sol na parede, sem exigir iluminação dinâmica. A diferença entre roupa esquecida e roupa em uso indica ocupação presente.

Reaproveitar divisórias, becos, corredores de pilares e ruínas. Manter a apresentação atual de 32 pixels por célula separada da escala lógica existente de 40; não alterar coordenadas para acomodar móveis. Novos assets: varal, camas, mesas escolares, janela, armário de arquivo e retratos dos dois NPCs. Formas simples e interação textual podem servir de placeholders identificados. Decoração não bloqueia passagem sem colisão explícita. Interações têm contorno ou prompt; dourado não identifica coletável escondido aleatório.

O gerador varia trajetos e salas secundárias. Pátio, quarto, depósito e arquivo são alcançáveis nessa ordem de descoberta, com ramificações livres. Um atalho minerável pode encurtar a volta; não substitui acesso garantido. Segredos contêm contexto e recursos comuns, nunca a única prova.

## 3. Missão principal executável

Cada etapa abaixo precisa de estado próprio. Retomar não repete cenas concluídas nem sorteia outro mapa.

| ID | Início e lugar | Objetivo e ação | Evento, fala e conclusão | Resultado persistente; morte ou retorno temporário |
| --- | --- | --- | --- | --- |
| P06-E01 | 4 e 5 resolvidos; hub | Ouvir Sabela e confirmar pedido de mobiliário | Ela mostra a identificação do alojamento. O protagonista reconhece o endereço. Conclui ao aceitar ou escolher investigar por conta própria | Destino 6 disponível e objetivo registrado. Recusar trabalho não bloqueia investigação |
| P06-E02 | Primeira entrada; pátio | Examinar distribuição dos quartos e conversar com Dalva | Dalva aponta o quarto antigo e avisa quais móveis continuam ocupados. Conclui ao ler a placa do corredor, mesmo sem diálogo | Quarto e depósito identificados; retorno mantém Dalva e móveis na situação encontrada |
| P06-E03 | Acesso ao quarto; janela | Examinar ferragem e desenho preso sob a mesa | O protagonista identifica as duas caligrafias e lembra que Lia corrigiu a abertura da janela. Conclui com a inspeção, não com item colecionável opcional | Descoberta pessoal registrada; desenho pode ser consultado na revisita e no inventário de descobertas |
| P06-E04 | Depósito alcançado | Marcar mesas livres e recuperar painéis sem retirar camas em uso | Etiquetas distinguem material desocupado. Se o jogador ameaçar uma cama ocupada, o prompt informa quem a usa antes da confirmação. Conclui ao separar o conjunto reservado | Mobiliário disponível para transferência ao hub. Mesmo sem ajudar Dalva, o conjunto principal existe |
| P06-E05 | Corredor do arquivo | Comparar sua saída registrada com a ordem de circulação | Um recibo de serviço posterior à suposta partida contradiz a data. Geraldo tenta recolher a cópia exposta. Conclui quando a contradição foi examinada | Cópia da descoberta registrada. Morte durante o confronto não apaga a leitura nem destrói o livro matriz |
| P06-E06 | Geraldo confrontado; arquivo ou arena separada | Obter acesso integral por acordo ou resolução física | Geraldo precisa admitir sua adulteração, entregar o arquivo ou perder o controle do acesso. O encontro pode ser interrompido para voltar ao hub | Livro matriz acessível e destino do encarregado gravado. Rendição não significa morte |
| P06-E07 | Arquivo acessível; depois hub | Ler referências aos armazéns e à necrópole; entregar o mobiliário ou apenas relatar a descoberta | Duas ordens de serviço identificam caminhos existentes para 7 e 8. Doro e Sabela respondem à suspeita | 6 resolvido, 7 e 8 disponíveis. Escola recebe o mobiliário recuperado; se recusado, a investigação avança sem fingir que a escola foi montada |

O livro matriz fica no arquivo, fora da arena, e não é um objeto destrutível de combate. Ele preserva data, autoria da alteração e referências dos dois destinos. Seu cadastro de acolhimento identifica Geraldo como alguém que recebeu selo e depois voltou a trabalhar fora; esse registro é consultado em P06-E05, sem depender de subquest. A instrução de 8 explica o significado completo do vínculo. Se Geraldo morrer ou remover a cópia exposta, o original continua legível. Se Dalva estiver ausente, placa do quarto, ferragem e desenho conservam a descoberta pessoal.

## 4. Pessoas e descoberta

**Dalva, moradora do alojamento:** arruma o varal, mantém quartos utilizáveis e quer espaço próprio sem virar administradora de todos. Conheceu o casal nas temporadas anteriores ao ataque. Recorda hábitos e discussões, não sabe onde Lia está hoje. Vive fora e **não recebeu selo**. Pode visitar o hub sem vínculo; mudança permanente exige acolhimento registrado. Depois da revelação, a origem da proteção deve ser explicada antes da escolha.

**Geraldo, encarregado da Fundação:** substituiu a circulação real por uma partida fictícia. Não executou o assassinato; ajudou a apagá-lo. Já recebeu o selo e permanece vinculado mesmo trabalhando fora. Quer conservar o cargo e a versão de que manteve tudo organizado. Perguntado diretamente, admite a alteração e identifica a autorização dos dirigentes e a assinatura de Aurel na ordem de interdição; não a atribui a Sabela. Não apresenta sua vergonha como reparação nem sabe notícias atuais de Lia.

**Sabela, recorrente no retorno:** tentou impedir o crime. Não ordenou fechar a rua. O registro pode mostrar sua tentativa de autorizar outra saída, mas não transforma sua oposição numa fuga bem-sucedida. Ela não exige que o protagonista termine a escola para conseguir explicações.

O plano da casa tem correções práticas: a primeira janela abriria contra o armário. Lia mudou a posição; o protagonista escreveu medidas novas por cima. A intimidade aparece no trabalho compartilhado, não numa revelação de que ela era perfeita. A inspeção não provoca amnésia recuperada: ele conhecia o episódio e o apresenta ao jogador.

## 5. Conflito e arena

Geraldo começa tentando encerrar a consulta e recolher documentos. O jogador pode seguir conversando ou contestar fisicamente sua interferência. A arena usa arquivos como cobertura e divisórias que ele tenta fechar; os setores de fechamento são anunciados. O objetivo narrativo é impedir a retirada do material e alcançar a mesa, não matar um bibliotecário por recursos. A aplicação por turnos fica sujeita ao combate escolhido.

O acordo exige acesso integral, identificação pública da alteração e possibilidade de consulta independente. Oferecer privacidade para conversar não permite esconder depois o crime. Prometer imunidade não é necessário. Na resolução física, derrota, rendição e morte têm estados distintos. A morte elimina seu depoimento e futuras respostas; não elimina autoria nem provas. Não acrescentar uma conspiração que inocente Bento ou Aurel.

## 6. Duas subquests

### Q06-D — Dalva: Um quarto por dentro

Disponível ao perguntar por que ela dorme junto do varal. Ela aceita cuidar do alojamento, mas está cansada de nunca ter uma porta que possa fechar.

| ID e início/local | Objetivo, ação, cena e conclusão | Estado persistente e retirada/morte |
| --- | --- | --- |
| Q06-D01; quest aceita, 6 | Examinar quartos livres e separar uma divisória fora do conjunto principal. Dalva diz se quer ficar ou visitar o hub. Conclui ao escolher o destino com ela | Destino e material reservado; retorno não transfere Dalva automaticamente |
| Q06-D02; D01 resolvida, 5 | Consultar distribuição dos dormitórios e recuperar seu biombo. Registro e objeto existem sem Beltran ou Cira vivos; conclui ao obter o biombo | Objeto recuperado; morte não repõe a coleta nem exige repetir o chefe |
| Q06-D03; biombo obtido, hub ou 6 | Instalar no lugar escolhido e perguntar quais visitas aceita. Conclui quando Dalva fecha a porta e responde | Quarto alterado e decisão de acolhimento registrada; cena não ocorre se Dalva morreu |

**Escolhas:** apoiar mudança, melhorar o quarto exterior ou recusar. Não prometer um quarto ocupado por outra pessoa. Se visitante, Dalva não recebe selo; se aceita residência permanente, registrar vínculo e informação disponível. Se morrer, sua quest acaba; devolver pertences aos moradores é uma ação distinta. No sacrifício, a privacidade conquistada permanece. Na vingança, o destino depende do acolhimento efetivo, não do simples fato de ter visitado a escola.

### Q06-T — Teca: Roupa que não dá ordens

Teca pede tecido dos uniformes abandonados, sem querer vestir alunos como soldados. É irmã de Aurel e se opôs ao crime; esse vínculo pode ser discutido antes de 8.

| ID e início/local | Objetivo, ação, cena e conclusão | Estado persistente e retirada/morte |
| --- | --- | --- |
| Q06-T01; pedido aceito, 6 | Abrir armário, conferir etiquetas e separar uniformes sem dono atual. Conclui com tecido reservado; não recortar provas nem vestir alunos automaticamente | Tecido separado; retorno conserva reserva e evidências |
| Q06-T02; T01 resolvida, 2 | Buscar agulhas e fechos na bancada ou estoque comum. Brina conversa se viva; conclui ao obter material de costura | Materiais obtidos; ausência de Brina elimina conversa, sem bloquear etapa |
| Q06-T03; materiais obtidos, hub | Escolher com Teca casacos ou mantas. Conclui ao entregar materiais e confirmar projeto, sem consumir mobiliário principal | Roupas mudam na escola; retirada mantém projeto. Se Teca morreu, colegas concluem trabalho iniciado sem encenar seu reencontro |

Recusar deixa alunos com suas roupas existentes. Prometer casacos e entregar mantas sem consultar Teca provoca reclamação e chance de corrigir, não trava campanha. Se Teca morrer, não encenar seu reencontro; colegas podem concluir peças já iniciadas. No sacrifício, os remendos continuam visíveis. Na vingança, Teca morre pelo vínculo; a roupa não é usada para absolver Aurel.

## 7. Diálogos essenciais e escolhas

**Quarto, antes da descoberta:**

> **Dalva:** “Não levem a mesa antes de abrir a gaveta.”  
> **Protagonista:** “Tem alguma coisa importante?”  
> **Dalva:** “Pra quem deixou meias ali, deve ter.”

**Janela, inspeção garantida:**

> **Protagonista:** “Eu desenhei o armário primeiro. Lia disse que a janela precisava abrir, não ganhar de mim.”

Escolhas: comentar a teimosia, explicar a correção ou guardar silêncio. Todas registram a descoberta.

**Arquivo, pergunta direta:**

> **Protagonista:** “Você escreveu que eu fui embora.”  
> **Geraldo:** “Eu escrevi.”  
> **Protagonista:** “Eu ainda estava aqui.”  
> **Geraldo:** “Eu sabia.”

Escolhas: exigir o original, perguntar quem ordenou ou interromper a conversa. Geraldo informa sua própria autoria e o que realmente sabe; não concede sozinho prova completa do rito.

**Hub, depois da contradição:**

> **Sabela:** “Tentei abrir outra saída. Não cheguei a você.”  
> **Protagonista:** “Então não me diga que eu parti.”  
> **Sabela:** “Não vou dizer.”

**Dalva, subquest concluída:**

> **Dalva:** “Você pode bater.”  
> **Protagonista:** “Na porta?”  
> **Dalva:** “É. Essa é a novidade.”

**Teca, uniformes:**

> **Teca:** “O tecido ainda serve. A patente, não.”

## 8. Perfil de combate — dois encontros comuns e um chefe

**Densidade escolhida pelo usuário:** dois comuns e o encontro principal nesta região intermediária. Composição e localização abaixo são propostas. Reaproveitar `crawler` (Rastejante), `ranger` (Sentinela) e `dasher` (Bruto), preservando mordida próxima, linha de tiro anunciada e investida anunciada. A migração para turnos precisa conservar esses avisos, sem simplesmente transportar seus temporizadores atuais em segundos.

| Encontro e momento | Gatilho visível e composição | Avisos, terreno e resolução | Saída e persistência |
| --- | --- | --- | --- |
| C06-01; entre P06-E02 e E03, corredor dos dormitórios vazios | Dois Rastejantes visíveis entre camas quebradas, antes da porta do quarto. Aproximar-se do setor anunciado permite escolher enfrentar ou recuar; não sortear ataque por passos | Mordidas marcam células adjacentes. Camas e uma divisória criam dois caminhos, sem aprisionar o jogador. Ameaças das ruínas; Dalva não vira inimiga ao conversar | Vitória volta ao corredor liberado. Recuo volta ao pátio; morte ao hub. Resolvido não reaparece em revisitas |
| C06-02; P06-E04, acesso ao depósito escolar | Uma Sentinela hostil aparece mirando pela abertura e um Bruto permanece atrás de uma escora. Ver os atores e sua área antes de confirmar avanço para a arena | Linha de tiro e trajeto de investida são distintos. Pilares oferecem cobertura; um Bruto pode abrir linha ao romper obstáculo. Mobiliário reservado da missão fica fora da arena e não é destruído por azar | Vitória libera acesso ao depósito; recuo retorna ao corredor anterior, sem retirar mobiliário. Morte mantém etapas já realizadas. Gravar encontro resolvido independentemente da coleta posterior |
| B06-01; P06-E06, confronto do arquivo | Geraldo é apresentado em E05; arena somente após disputa explícita ou escolha física. Negociação pode resolver sem iniciar luta; não adicionar comuns a este encontro | Geraldo usa divisórias e fechamento anunciado de setores conforme seção 5. Documento original fica fora do grid. Alcançar o acesso e obter rendição não exige execução | Acordo ou derrota volta ao arquivo acessível; recuo mantém disputa pendente. Estado do chefe e abertura persistem; morte dele não apaga provas |

Não adicionar combate ao varal, à inspeção da janela, à entrega dos uniformes ou à instalação do quarto. Esses espaços permitem convívio. Subquests não geram ondas extra. NPCs locais não são automaticamente os atores hostis dos setores abandonados; a caracterização visual destes últimos ainda precisa de arte e texto próprios.

**Conversas seguras:** abertura de diálogo suspende a simulação hostil imediatamente, incluindo o mesmo passo de atualização. Nenhum ataque resolve sob menu, fala ou escolha; avisos não avançam escondidos. Encerrar fala retoma a situação registrada conforme a futura regra de turnos. Vitória ou acordo retornam à exploração livre; retirada deixa apenas o encontro não resolvido disponível, sem regenerar o mapa inteiro.

## 9. Hub, persistência e revisão

Mesas e painéis aparecem no espaço escolar; Sabela reorganiza as aulas e permite visitas. O desenho fica consultável sem consumir a lembrança. Doro pergunta se o protagonista quer companhia para investigar; aceita silêncio e não presume perdão. Aurel, perguntado diretamente, responde sobre sua participação conforme a base; não usa o mapa 8 como desculpa para calar.

Registrar mobiliário entregue, arquivo lido, resultado de Geraldo, escolhas das quests, vínculo de Dalva e conversas já ocorridas. Entrada tardia após 8 reconhece os fatos: o arquivo confirma detalhes, não reapresenta suspeita como descoberta nova.

Revisão para Devin: acordo e confronto liberam o livro; retirada mantém documentos; morte comum não repõe mesas; mortes de NPCs não apagam destinos; recusa das duas quests mantém 7/8 acessíveis. Nenhuma decoração procedural pode cortar o caminho para quarto, depósito ou arquivo.
