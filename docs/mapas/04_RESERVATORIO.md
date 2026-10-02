# Mapa 4 — Jardins do Reservatório

Proposta coordenada para desenvolvimento, 02/10/2026. **Ivo** e **Mara** são nomes propostos. Referência: [base comum](../BASE_NARRATIVA.md). Exploração livre, arena de grid separada, sem fixar turnos ou balanceamento. Nenhuma regra desta ficha está implementada.

## Identidade, acesso e objetivo

Abre depois das Oficinas: conjunto de ferramentas e traçado de manutenção permitem alcançar e reparar o setor. Independe de concluir Mercado ou Salões. Sabela identifica água suja no hub; pede recuperar componentes de filtragem e verificar uma rota de distribuição abandonada.

O mapa mostra trabalho comunitário e apresenta o casal em situações cotidianas. Seu conflito é avaliar um risco real: abrir a comporta errada inunda os canteiros e um caminho habitado. Ivo interrompeu toda manutenção para evitar esse risco e agora trata qualquer iniciativa como ameaça.

Conclusão: componentes garantidos obtidos, água encaminhada com segurança e corredor inferior drenado. A drenagem, junto da rota estrutural liberada nos Salões, permite alcançar o mapa 6. Não há uma chave entregue por chefe.

## Direção visual e composição

**Paleta:** calcário `#687269`, água `#365B62`, musgo `#6C8054`, ferragem `#A67D4D`, flores e luz `#D6B66C`. Salas largas, degraus de pedra, canais retos e canteiros em faixas. Marcos: torre baixa com régua de nível na parede; jardim sob vigas de uma antiga cobertura. A régua mostra visualmente cheio/esvaziado, sem criar simulador de fluidos.

Reutilizar galerias, corredores de pilares e fissuras. Buracos são cisternas ou canais fundos, com bordas claras. Paredes quebráveis pertencem a canais de manutenção; abrir outra parede não obriga dano irreversível ao jardim. Novos assets: comporta, volante, grades de filtro, três variações de planta, banco e rega de Mara. Cristais atuais ficam em nichos minerais, nunca confundidos com componentes essenciais.

Garantir posto de chegada, jardim/banco, depósito técnico, canal de teste, sala das comportas e corredor inferior. Jardim e instrução técnica são alcançáveis antes da arena. O gerador varia desvios e ruínas adjacentes; drenagem não depende de sortear geometria correta. Volantes interagíveis possuem cor de ferragem e contorno ao alcance. Depois, canteiros escolhidos florescem, canais usam tiles de água baixa e o corredor permanece aberto.

## Três personagens principais

**Ivo, operador e adversário.** Conhece cada ruído das bombas e nomeia peças como colegas. Dorme perto da comporta porque perdeu confiança em delegar; deseja manter pessoas seguras, mas retirou delas a participação. Não é dirigente do pacto e desconhece o assassinato. Vive fora do núcleo protegido, sem selo por padrão. Sua habilidade deve continuar útil mesmo se perde o controle exclusivo.

**Mara, cuidadora.** Cultiva alimento, temperos e flores; recusa a ideia de que só coisas comestíveis merecem água. Conheceu protagonista e Lia em visitas curtas, antes do crime, e mostra marcas de trabalho deles. Deseja ampliar participação dos moradores, teme ver tudo reduzido a produção. Não sabe o presente de Lia nem detalhes do rito.

**Sabela, recorrente.** Participa de uma visita ou recebe a discussão no hub, conforme disponibilidade; não exigir acompanhante com IA. Quer resolver depressa e tende a concluir pelos outros. A quest confronta esse hábito, sem torná-la autora do crime. Sobre tentativa de fuga, responde conforme a base, inclusive antes do mapa 8.

## Etapas implementáveis

### P04-E01 — A água que chega

**Início:** ferramentas e rota do mapa 2 recuperadas. **Lugar:** ponto de água do hub. **Ação:** inspecionar resíduo e ouvir Sabela; registro técnico identifica filtros, vedação e origem. **Cena, se Sabela viva e presente:** “Não bebe.” / Protagonista: “Você podia ter dito antes de me dar o copo.” / Sabela: “Era para olhar.” Sem ela, resíduo e instrução permitem ao protagonista assumir a tarefa; não reproduzir sua fala. **Estado:** missão oferecida. Recusa não fecha região; retirada mantém pedido. **Avança:** aceitar e selecionar Reservatório, independentemente de mapa 5.

### P04-E02 — Plantas e gente

**Início:** primeira visita. **Lugar:** jardim e entrada. **Ação:** seguir canteiros até Mara, ver moradores regando e perguntar sobre a restrição. Ivo chama do outro lado do canal para ninguém tocar no volante. **Evento:** duas necessidades ficam claras: preservar jardim e recuperar passagem. **Estado:** conflito conhecido. Morte/retorno conserva descoberta e canteiros intactos. **Avança:** explorar banco e depósito técnico em ordem livre.

### P04-E03 — Uma pausa do casal

**Início:** banco alcançável. **Ação:** examinar seu encaixe, marca de conserto e cobertura improvisada. **Cena:** Mara: “Lia dizia que você só sentava se tivesse alguma coisa quebrada.” / Protagonista: “Esse banco estava.” / Mara: “Depois não. Você continuou vindo.” O protagonista recorda discutir sombra com Lia e terminar repartindo comida ali. Uma marca datada do serviço e reconhecimento do encaixe preservam lembrança se Mara estiver ausente. **Estado:** passado reconhecido; uma placa de manutenção identifica o setor dos alojamentos abaixo. **Avança:** consultar esquema do canal, sem quest de jardinagem obrigatória.

### P04-E04 — Demonstrar o caminho

**Início:** esquema examinado. **Lugar:** canal de teste. **Ação:** usar ferramentas para limpar desvio e isolar ramo baixo; testar pela régua, com aviso antes de qualquer fluxo. **Cena:** Ivo: “Esse traço não mostra as pessoas.” / Protagonista: “Então vem olhar comigo.” **Estado:** alternativa de drenagem verificada ou ainda pendente. Retirada preserva trabalho; morrer não repõe entulho. **Avança:** levar demonstração a Ivo ou exigir passagem pela força; arena não é disparada por experimentar o canal.

### P04-E05 — A comporta

**Início:** pedido explícito de acesso encontra resistência. **Lugar:** sala e arena separada. **Ação:** negociar inspeção conjunta ou confrontar, com opção de interromper para terminar preparo. **Evento:** derrota, rendição e morte são resultados diferentes. Se Ivo morrer, esquema e volante manual permitem concluir operação segura. **Estado:** controle resolvido; filtros excedentes retirados do depósito; corredor drenado pela rota preparada, inclusive após vitória física. Morte suspende só encontro não resolvido. **Avança:** voltar com componentes e identificação dos alojamentos.

### P04-E06 — Quem decide agora

**Início:** componentes depositados no ponto de água. **Lugar:** água e bancada do hub. **Ação:** Doro monta filtro; morto ou ausente, o protagonista segue instrução técnica garantida e instala componentes com o conjunto do mapa 2. Sabela viva pede relatos e participantes da discussão. **Cena somente se presente:** “Agora podemos abrir para todo mundo.” / Protagonista: “Você já perguntou o que vão precisar manter?” Sem Sabela, o serviço funciona e moradores vivos podem organizar distribuição; sua quest pessoal não se conclui por substituição. **Estado:** água limpa, visita/participação opcional dos cuidadores. Caso 5 concluído, percurso seguro para 6 disponível; caso contrário, o setor ainda necessita a escora dos Salões. Retorno tardio reconhece culpa e não exige gratidão. **Avança:** selecionar próximo destino ou revisitar jardim.

## Arena e duas resoluções

### Perfil de combate e gatilhos

**Frequência escolhida:** dois a três encontros comuns entre cenas e um chefe. Dois grupos comuns previstos; o terceiro, ligado ao jardim, é opcional e não se soma a três grupos prévios. Composições e interpretações dos arquétipos abaixo são propostas.

| ID e momento | Lugar e composição | Gatilho e alternativas |
| --- | --- | --- |
| **C04-01**, durante E02, antes do jardim | Passarela de chegada; dois Rastejantes de cisterna | Animais visíveis reagem com aviso ao cruzar território. Escolher avançar ou atacar inicia arena; caminho seco lateral garantido permite desvio. Não invadir conversa com Mara |
| **C04-02**, entre E03 e E04 | Entrada do canal de teste; um Sentinela e um Bruto como equipe de manutenção | Defendem interdição de Ivo. Abordagem abre conversa; mostrar esquema e combinar isolamento dá passagem. Insistir em romper bloqueio inicia arena explicitamente; é possível retirar-se e voltar. Não exigir convencer Ivo antes de alcançar a alternativa técnica |
| **C04-Q01**, em Um jardim útil, terceiro comum opcional | Canteiro lateral; dois Rastejantes defendem brotos | Interação começa com observar ninho. Espantar por um corredor vazio ou preservar aquele canteiro resolve sem combate; atacar abre arena. Materiais do filtro e drenagem principal não ficam nesse setor |
| **B04-01**, E05 | Sala das comportas; Ivo | Oposição ao pedido de acesso abre diálogo antes da arena. Preparação e alternativas descritas abaixo |

Avisos são visíveis durante exploração; combates não surgem porque o jogador leu um registro. Diálogos e menus pausam ataques e movimento hostil. Encontros resolvidos, desviados ou suspensos deixam estados reconhecidos na revisita; só um impasse não resolvido pode reabrir arena após novo gatilho.

Ivo usa haste longa, fecha grades e anuncia jatos pelas linhas dos canais. Há pisos secos e proteção de pilares; perigos têm aviso de origem e faixa. Não inundar permanentemente mapa de exploração por um ataque comum da arena.

A negociação pede demonstrar desvio seguro e permitir acompanhamento de moradores, não elogiar Ivo até ceder. Na arena, fechar um ramo antes de ouvir mostra preparo; insistir em abrir sem isolar permite a ele apontar risco verdadeiro. Pode sair para reparar. Resolução física retira sua exclusividade, não elimina necessidade de operar com cuidado. Instruções garantidas bastam sem NPC vivo; vazamento eventual usa reparo previsto, não apaga componentes ou bloqueia campanha.

## Duas subquests

**Mara — Um jardim útil.** Começa ao criticar ou perguntar pelos canteiros de flores. Primeira etapa: conhecer usos diferentes, incluindo alimento e descanso. Segunda: escolher junto dos moradores recuperar canteiros mistos ou ampliar horta preservando uma área de flores; ambas usam plantas existentes, sem coletáveis aleatórios. Terceira: levar um vaso ao hub ou manter visitas ao jardim. Reencontro mostra morador regando e banco em uso, não só produção. Mara pode aceitar residência, permanecer exterior ou visitar. Recusa mantém cultivo próprio; quebrar a promessa de manter espaço de descanso deixa o banco vazio. Se morrer, habitantes podem conservar plano já combinado, sem escolher por ela. No sacrifício, jardim continua conforme cuidado; na restituição, sobrevivem cuidadores sem vínculo e morrem residentes selados.

**Sabela — Fora do comando.** Disponível após conhecer desacordo. Primeira etapa: ouvir Mara e Ivo separadamente, sem exigir acordo principal pacífico. Segunda: reunir suas posições no hub ou no posto de água; Sabela propõe sozinha uma escala e pode ser confrontada por isso. Terceira, mapa 6: conversar na preparação da escola sobre uma rotina decidida também pelas crianças e responsáveis. Negociar não significa apagar a autoridade técnica de Ivo. Reencontro: Sabela apresenta opções em vez de dar ordem. Recusa deixa padrão anterior; descumprir compromisso de ouvir produz retirada de Mara da discussão. Se Ivo morreu, sua posição permanece em registros, mas ninguém finge seu consentimento. Se Sabela morreu, organização comunitária prossegue sem sua mudança pessoal. Ela já é selada; nenhuma quest retira sua condição. Revelação diferencia sua oposição ao crime de seus hábitos autoritários atuais.

## Continuidade, selo e verificação

Mara e Ivo só passam ao vínculo mediante residência permanente com acolhimento; visitas, colaboração e vaso não dão selo. Pós-revelação, aceitar residência requer explicar consequência. A saída física posterior não remove um selo já recebido.

Persistem água, corredor, canteiros, recusas e destino de Ivo. Visita após 8 permite perguntar a Sabela viva o que tentou fazer; morta, sua oposição permanece nas provas da campanha, sem fala atribuída a outro morador. Moradores exteriores não subitamente conhecem segredo. Filtros não são moeda consumível de quests opcionais.

Verificar chegada antes/depois de Salões, acordo sem subquests, vitória letal, canal preparado antes da arena, retirada parcial e revelação antecipada. Em todos: água do hub, identificação do alojamento e drenagem necessárias ao mapa 6 permanecem possíveis. Novas regras futuras: interação de reparo, estado visual da água, escolhas persistentes e arena separada; reaproveitamento de tiles não significa que já existam.
