# Mapa 5 — Salões da Vigília

Proposta coordenada para desenvolvimento, 02/10/2026. **Beltran** retoma um chefe proposto anteriormente; **Cira** é nome novo proposto. [Base comum](../BASE_NARRATIVA.md). Exploração livre e arena separada de grid; não fixar ainda turnos, dano ou cronômetros. Conteúdo ainda não implementado.

## Identidade e missão

Abre ao recuperar a rota do Mercado. Pode vir antes ou depois do Reservatório. Teca precisa de divisórias e ferragens para dar privacidade aos dormitórios; o complexo dos Salões guarda materiais reaproveitáveis e pessoas alojadas temporariamente.

Beltran anuncia uma apresentação mesmo com o salão ameaçado. Seu medo não é perder um estoque: acredita que, se a celebração acabar, ninguém terá motivo para ficar junto e ele deixará de ter lugar na comunidade. Ele esconde a extensão dos danos enquanto tenta tornar a noite perfeita. O protagonista resolve abrigo e segurança, reencontra traços de Lia e pode acompanhar arte, descanso e amizade.

Conclusão: materiais excedentes recuperados, saída dos moradores segura e manutenção superior dos alojamentos reforçada. Junto da drenagem do mapa 4, isso permite chegar ao mapa 6. Não exigir apresentação, recrutamento ou instrumento de Nilo.

## Visual e lugares garantidos

**Paleta:** pedra vinho `#52444A`, tecido vermelho `#A14E50`, madeira `#76523D`, ouro gasto `#C2A365`, luz de vela `#E9CF9B`. Criptas e capelas reaproveitadas como dormitórios e teatro. Silhuetas: arcos altos, cortinas verticais, camas baixas e palco raso. Evitar transformar tudo numa festa ameaçadora: há louça lavada, brinquedos improvisados e gente conversando.

Marco: lustre incompleto sobre palco; uma cadeira reservada recebe o mesmo tecido que a cortina remendada. Props novos: palco baixo, cortina, tapume, cabides, instrumentos, bancos e cartaz de programa. Tiles atuais: capela, cripta, divisórias, ruína de pilares. Cristais apenas nas fundações expostas. Fissuras perigosas têm bordas quebradas claras; ferragens essenciais ficam em armário técnico distinto dos enfeites.

Garantir chegada, cozinha auxiliar, palco, ala ocupada, depósito excedente e corredor superior. Cira, dormitório e laudo da estrutura são acessíveis antes do chefe. A apresentação principal não depende de sala secreta. O gerador varia camarins, pequenos corredores e galerias vazias. Depois, mostrar camas realocadas, escoras fixadas, cartaz atualizado e palco em uso ou abandonado. Prop interagível recebe contorno ao alcance; não depender de nova iluminação volumétrica.

## Pessoas e conhecimento

**Beltran, anfitrião e adversário.** Recebe gente pelo nome, lembra preferência de comida e insiste em elogiar uma roupa mal remendada. Foi útil acolhendo pessoas após a catástrofe; agora confunde ser necessário com ser amado. Reescreve o programa para ninguém aparecer “sem função”. Conheceu o casal em estadias temporárias, não conhece Lia hoje e não participou da execução. Ouviu versão oficial da partida do protagonista e admite essa fonte quando perguntado. Pode continuar organizando eventos com limites, abandonar função ou morrer.

**Cira, artista.** Antiga colega de Neco na oficina; trabalhou em peças de madeira, saiu e começou a tocar. Faz piadas secas quando está nervosa, desafina de propósito para descobrir se alguém está ouvindo. Quer apresentar trabalho sem precisar fingir felicidade. Permanece exterior por padrão. Conhece Neco e ofícios do protagonista; não sabe o rito nem é testemunha do crime.

**Nilo, recorrente.** Instrumento começou com a bancada das Oficinas; Cira pode ajudar a terminá-lo. Aparece no hub e numa visita eventual, sem nova IA obrigatória. Neco pode participar como convidado de seu arco anterior, sem se tornar um quarto protagonista local.

## Etapas implementáveis

### P05-E01 — Espaço para fechar a porta

**Início:** rota do Mercado aberta. **Lugar:** dormitórios do hub. **Ação:** ouvir Teca e examinar separação improvisada. **Cena, somente se viva e presente:** “Essa cortina não tem lado.” / Protagonista: “Tem dois.” / Teca: “E os dois estão olhando para a cama de alguém.” Sem ela, o protagonista identifica a necessidade pelo espaço e plano de montagem conservado junto das camas; origem do material aparece no plano. **Estado:** pedido de painéis e ferragens; ferramentas simples bastam mesmo sem melhorias opcionais. Recusa mantém missão disponível; retirada não cria compromisso. **Avança:** aceitar e selecionar Salões.

### P05-E02 — Um convite antes do perigo

**Início:** primeira visita. **Lugar:** cozinha e palco. **Ação:** Beltran oferece bebida, pergunta como apresentar o protagonista e mostra programa; Cira interrompe uma instrução exagerada. **Cena:** Beltran: “Convidado de honra.” / Cira: “Ele veio buscar dobradiça.” / Beltran: “Honra também abre portas.” **Estado:** anfitrião conhecido, programa e missão acessíveis. Retirada conserva convite; morte não torna apresentação inédita. **Avança:** explorar ala e depósito, em ordem livre.

### P05-E03 — Uma briga que terminou em trabalho

**Início:** cozinha auxiliar alcançada. **Ação:** examinar mesa de reparo e marcas diferentes numa moldura. **Cena:** Beltran: “Ela foi embora no meio do ensaio.” / Protagonista: “Voltou com uma escora.” / Beltran: “E pediu que você parasse de prometer serviço para a cidade inteira.” Lia tinha razão sobre ele adiar a viagem; ele recorda a reconciliação durante o conserto, com promessa de limitar trabalhos. Registro do serviço e reconhecimento da moldura preservam informação se Beltran morreu. **Estado:** memória e ficha de hospedagem temporária descobertas; localização da Fundação confirmada. **Avança:** examinar laudo e corredor de manutenção.

### P05-E04 — Ensaio de saída

**Início:** dano estrutural visto. **Lugar:** dormitórios e corredor. **Ação:** liberar rota lateral e separar painéis excedentes dos que abrigam pessoas. Cira pode mostrar caminho; instrução técnica garante alternativa se ausente. **Evento:** Beltran tenta tratar rachadura como defeito de decoração. **Cena:** Cira: “A cortina esconde, mas não segura.” **Estado:** plano de realocação e manutenção preparado. Retirada/morte conservam paredes abertas. **Avança:** exigir mudança no evento, conversar ou enfrentar; não remover teto habitado por engano.

### P05-E05 — Quem fica quando o palco apaga

**Início:** protagonista confronta ocultação dos riscos. **Lugar:** palco e arena separada. **Ação:** propor apresentação menor/realocada e tarefa concreta a Beltran ou interromper sua encenação pela força. **Evento:** resolução distingue acordo, rendição e morte. Moradores saem por rota lateral preparada ou corredor existente usado após vitória. **Estado:** encontro resolvido, excedentes disponíveis e corredor superior reforçado com escoras locais. Retirada pausa encontro; morte reinicia só luta pendente. **Avança:** recuperar conjunto e retornar, sem obrigar público a morar no hub.

### P05-E06 — Um abrigo e uma noite

**Início:** materiais depositados nos dormitórios. **Lugar:** dormitórios e área comum do hub. **Ação:** Teca monta divisórias; morta ou ausente, o protagonista instala os painéis conforme plano garantido, com ferramentas iniciais. Convite à apresentação só envolve personagens vivos e disponíveis. **Cena somente com Nilo e Teca presentes:** Nilo: “Agora dá pra ouvir menos.” / Teca: “Era a ideia.” / Nilo: “Do corredor. Da oficina não.” Morto Nilo, omitir fala e preservar instrumento já criado, sem concluir sua quest. **Estado:** privacidade ampliada, relações conforme destino de moradores. Se 4 concluído, acesso seguro a 6; caso contrário, corredor inferior ainda inundado. Retorno após verdade muda tom e permite recusar celebração. **Avança:** visitar Fundação quando ambas condições físicas existem.

## Arena: anfitrião e regente de cena

### Perfil de combate e gatilhos

**Frequência escolhida:** dois a três comuns, intercalados com história, e um chefe. Aqui dois encontros comuns mais uma disputa opcional de quest ocupam esse limite. As composições são propostas e não introduzem outro personagem principal.

| ID e momento | Lugar e composição | Gatilho e alternativas |
| --- | --- | --- |
| **C05-01**, depois da conversa de E02 e antes de E03 | Galeria de serviço; dois Rastejantes vindos de um canal rompido | Criaturas e entrada do canal são visíveis. Cruzar território depois de aviso ou atacar abre arena; fechar portinhola pelo lado seguro ou usar desvio evita encontro. Nenhum animal invade palco durante diálogo |
| **C05-02**, entre E03 e E04 | Corredor da ala ocupada; dois Sentinelas como vigias do abrigo | Avisam que desmontar paredes põe camas em risco. Conversar sobre excedentes e inspecionar laudo dá acesso; exigir passagem à força abre arena explícita. Retirar-se deixa negociação pendente; laudo e pista do casal continuam alcançáveis sem os derrotar |
| **C05-Q01**, preparação de Uma apresentação possível, terceiro comum opcional | Palco lateral; um Bruto, ajudante que propõe ensaio de luta para o programa | Desafio apresentado em conversa, só inicia arena se aceito. Recusar ou sugerir outra função mantém quest musical. Duelo combinado termina em rendição/desarme e não admite execução letal; desistir permite retomar apresentação sem vencer |
| **B05-01**, E05 | Palco principal; Beltran | Confrontar risco ocultado abre conversa. Negociação pode resolver sem arena; insistência reconhecida ou escolha de combate inicia encontro |

Inventário, programa, leitura e diálogos não disparam ataques; enquanto abertos, movimentos hostis e ataques ficam pausados. Combates interrompidos e resultados persistem. Não substituir personagem morto por cópia para manter contagem de encontros.

Beltran usa gestos de maestro para anunciar movimentos de cortina, golpes de bastão e deslocamento de bancos. Mantém reverências mesmo irritado. Pilares e divisórias dão linhas de proteção; quedas são anunciadas. Cenário de batalha conserva o salão, mas a plateia está fora da arena e não sofre dano por ataques normais.

Negociação reconhece sua contribuição sem aceitar o risco: demonstrar rota, oferecer função na realocação e permitir que moradores decidam se assistirão. Não obrigar elogio ou intimidade. Pode exigir que reconheça ocultação mesmo aceitando acordo. Vencer fisicamente permite desmontar encenação; derrota não mata automaticamente. Sem Beltran vivo, moradores usam programa e laudo para reorganizar abrigo. Ferragens ficam protegidas; combate não destrói recurso principal.

## Duas subquests

**Cira — Uma apresentação possível.** Inicia ao perguntar se deseja tocar ali. Etapa 1: escolher palco recuperado ou espaço comum do hub, com rota segura garantida pela missão. Etapa 2: conversar sobre repertório; ela recusa um programa que só permita músicas alegres e pode manter uma peça triste. Etapa 3: apresentação e reencontro. Neco, se vivo e acessível, recebe convite para assistir sem ajudar; isso completa sua etapa de folga iniciada no mapa 2. Se Neco recusou sair, pode fazer uma visita voluntária quando sua liberdade foi resolvida. Não transportá-lo contra vontade. Recusa mantém apresentação local pequena; prometer local e não preparar gera cancelamento reconhecido. Morta Cira, apresentação dela não acontece; Neco ainda pode escolher outro descanso. Neco morto deixa banco vazio e comentário, sem encerrar demais quests. Residente, visitante ou exterior depende da escolha de Cira e do acolhimento, não da localização do palco.

**Nilo — Barulho na oficina.** Oferta no hub depois da bancada do mapa 2; não bloqueia conclusão de Salões se ainda não começou. Etapa 1: Nilo demonstra instrumento que chia; protagonista escolhe ensinar ajuste ou buscar Cira. Etapa 2: no palco ou visita, ela ajusta afinação e pede que ele toque algo próprio. Se ausente/morta, instrução de ajuste junto do instrumento permite protagonista ensinar, preservando um reencontro diferente. Etapa 3: no hub, tocar junto ou escutar, sem julgar sucesso por perfeição. Depois do mapa 9, continuação obrigatoriamente opcional: Nilo decide repetir, mudar música ou esperar; Cira viva pode ouvir sem exigir festa. Recusar não apaga instrumento. Prometer presença e faltar muda sua fala; morrer Nilo encerra seu arco, deixando objeto. Nenhum inocente recebe culpa pelo crime dos dirigentes.

## Hub, finais e revisão

Teca e Nilo já têm selo. Beltran e Cira permanecem exteriores por padrão; só acolhimento permanente escolhido os vincula. Visitantes e apresentações não dão selo; depois de 8, origem é explicitada antes de residência. Conservar selo se alguém depois partir.

No sacrifício, instrumento, apresentação e abrigo expressam relações construídas; Cira pode manter arte crítica após a verdade. Na restituição, vinculados morrem, incluindo Nilo e Teca; Cira/Beltran exteriores vivem se não morreram antes. Uma pessoa pode preservar música sem declarar perdão pela vingança. Registros do casal não provam Lia viva: notícias recentes pertencem ao mapa 9.

Verificar 5 antes de 4, Nilo sem instrumento, Neco ausente/morto, Cira recusada, Beltran vencido/letal, saída durante preparação e revisita pós-revelação. Manter moldura, hospedagem temporária, ferragens e rota 6 em todos os caminhos. Persistência, transição à arena, encontro negociado e mudanças de NPC exigem implementação futura; tiles atuais dão base visual, não garantia dessas regras.
