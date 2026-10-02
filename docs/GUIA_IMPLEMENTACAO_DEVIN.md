# Guia para Devin — campanha e combate

Entrega de design, 02/10/2026. Ler antes de alterar o jogo. Este arquivo organiza o trabalho futuro; não afirma que os sistemas propostos existem. Os nomes e detalhes narrativos continuam propostas revisáveis.

**Antes de escrever texto para o jogador:** ler o [guia de escrita](GUIA_ESCRITA_DEVIN.md). Ele exige personalidade e voz únicas para cada personagem, PT-BR natural, cenas com intenção, escolhas claras e revisão de continuidade. Vale para diálogos, quests, lojas, tutoriais, descrições e epílogos.

## 1. Ordem de leitura

O plano de produção aprovado está em [MEGAPLAN_CAMPANHA.md](MEGAPLAN_CAMPANHA.md): decisões de implementação, arquitetura e etapas. Consultar junto com a ordem abaixo.

1. [Contexto escolhido pelo usuário](CONTEXTO_REIMAGINACAO.md): objetivo e decisões estabelecidas.
2. [Base comum](BASE_NARRATIVA.md): passado, culpa, selos, despertar e dependências.
3. [Plano e índice dos dez mapas](PLANO_CAMPANHA.md): campanha e suas fichas.
4. [Hub](HUB_INICIAL.md) e [cenas de revelação/finais](CENAS_REVELACAO_E_FINAIS.md): chegada, retornos e o que preparar desde cedo.
5. [Combate proposto](COMBATE_PROPOSTA.md): rodada, ações, terreno, negociação e retomada.
6. Ficha da região em produção. Usar seus identificadores de etapas/encontros para acompanhar o trabalho, sem criar um framework de quests só para interpretá-los.

O [estudo de Undertale](GUIA_STORYTELLING_UNDERTALE.md) explica as referências de escrita. [HISTORIA_NOVA.md](HISTORIA_NOVA.md) é uma proposta anterior, fora desta direção. Documentos antigos dos três andares descrevem o jogo existente; não substituem a campanha. Em caso de conflito, preservar decisões explícitas do usuário e comparar a base com a ficha; resolver a contradição antes de inventar outro fato.

## 2. O que aproveitar e o que precisa mudar

| Área | Código atual para inspecionar | Uso no novo recorte |
| --- | --- | --- |
| Salas e navegação | [rooms.lua](../src/rooms.lua), [environment.lua](../src/environment.lua) | Reutilizar terreno, consultas e famílias de layouts; acrescentar locais essenciais garantidos e conservar o mapa da campanha |
| Mundo e atores | [pixel_world.lua](../src/pixel_world.lua), [pixel_actors.lua](../src/pixel_actors.lua), [render.lua](../src/render.lua) | Manter pixel art, escala e desenho por base; criar apenas objetos e silhuetas necessários à região |
| Controle e ciclo | [game.lua](../src/game.lua), [input.lua](../src/input.lua), [systems.lua](../src/systems.lua) | Separar exploração livre de arena e resolução por turnos; não aplicar temporizadores de ataque durante menus |
| Inimigos e chefe | [enemies.lua](../src/enemies.lua), [boss.lua](../src/boss.lua) | Aproveitar papéis, avisos e obstáculos; trocar compromisso em segundos por intenção/resolução de rodada onde necessário |
| Conversas e loja | [dialogue.lua](../src/dialogue.lua), [shop.lua](../src/shop.lua) | Reconhecer fatos, promessas, retornos e autoria; loja deixa de ser só uma oferta por andar |
| Progressão | [progression.lua](../src/progression.lua), estado em game.lua | Campanha persiste depois da morte; evitar resetar descobertas junto de uma tentativa |

O jogo atual tem combate em tempo real e três andares. Movimento livre, campanha de dez regiões, arenas separadas, turnos e a nova persistência exigem desenvolvimento. A arte descrita nas fichas é direção para produção, não inventário de assets prontos.

## 3. Primeiro recorte recomendado

Implementar **Colina → hub → Oficinas → retorno**, com objetos provisórios legíveis. Testar uma sentinela antes de Janda. Não produzir todos os chefes antes de validar a rodada.

- Exploração livre com colisão, interação e local de retorno conhecido.
- Arena com um protagonista, intenções anunciadas, até duas células de movimento e uma ação; arco, defesa, uma cura e uma interação de pilar.
- Janda reconhece a preparação da saída. Negociação e derrota abrem a mesma missão principal, com relações diferentes.
- Ferramentas são entregues uma vez, bancada muda e destino 4 fica disponível.
- Morte retorna à Colina e conserva decisões, pertences, portas e encontros concluídos. Arena comum pendente pode reiniciar sem duplicar saque.

Só depois expandir mercado e suas conexões. Números de vida, alcance, dano e custo devem ser ajustados nesse recorte. Cartas podem continuar consultáveis; sua função mecânica ainda não foi escolhida. Aliados controláveis, crafting, fome, produção automática e iluminação dinâmica não são requisitos.

## 4. Estado que o jogo precisa lembrar

Usar estruturas simples de dados compatíveis com o projeto. Para cada região: seed/layout conservado, acessos e objetos alterados, etapas principais concluídas e resultados dos encontros. Para cada personagem: conhecimento compartilhado, compromissos, quest aceita/recusada, localização e selo. Para o hub: entregas únicas, instalações e personagens presentes. Para o final: ato explicitamente confirmado.

Não usar uma pontuação universal de bondade. Ser derrotado não significa morrer; visitar não significa receber selo; concluir uma conversa não significa perdoar; vencer Aurel não significa escolher um final.

Pistas essenciais ficam fora de sorteio, segredo ou perda de uma testemunha. Recursos principais não podem ser gastos por uma compra opcional. Cada ficha define alternativas e efeitos; não inventar recrutamento obrigatório para aumentar o custo final.

## 5. Verificação do recorte e da campanha

Checar o que pode quebrar a experiência:

- Abrir conversa, inventário, pausa ou perder foco congela a resolução, inclusive no mesmo quadro da interação. Fechar a tela não reaplica um ataque antigo.
- Prévia e resultado concordam sobre célula, cobertura, ordem e área; ataque não amplia alcance após a decisão.
- Morrer antes/depois de obter ferramentas e antes/depois de resolver Janda conserva o estado correto, sem recompensa repetida.
- Retirada permite voltar à negociação reconhecendo reparos. Recusa de quest não vira aceitação.
- Lugares e pistas principais continuam alcançáveis nas seeds verificadas; corredores variam sem apagar cenas.
- Ordem 2/3, 4/5 e 7/8 funciona. Visitar 8 antes de 7 muda o hub imediatamente; 9 ainda espera as peças de 7.
- Lia viva é informação principal de 9. Nenhum NPC opcional ou apresentação musical compra essa notícia.
- Final 10 pode ser adiado. Confirmação informa protagonista, moradores vinculados, visitantes e custo antes de encerrar. Não há terceiro final oculto.

Os comandos existentes estão em [tests/README.md](../tests/README.md). Parte dos testes verifica regras dos três andares e do combate em tempo real; revisar as expectativas quando essas regras mudarem. Manter checks úteis de geometria, avisos e persistência, sem tratar um teste antigo como definição da campanha nova. Esta entrega de documentação não executou o jogo nem valida um combate implementado.

Screenshots e PNGs de teste ficam **somente em `screenshots/` na raiz**, conforme [AGENTS.md](../AGENTS.md). Para captura pelo jogo, executar da raiz com `--screenshot=screenshots/nome.png`.

## 6. Decisões ainda revisáveis

Nome do protagonista e hub, nomes novos, sete anos de ausência, aparência/natureza definitiva da catástrofe, função das cartas e balanceamento. A campanha já tem uma versão coerente desses pontos quando necessários à escrita; não confundir proposta coordenada com aprovação criativa final.

A direção visual e a descrição de etapas das dez fichas são suficientes para começar os desenhos e discutir o recorte. Não exigem desenhar dez mapas completos antes de experimentar exploração, negociação e arena.
