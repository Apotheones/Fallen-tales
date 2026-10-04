# Contrato de QA — campanha e conteúdo legado

Revisado em 03/10/2026. Nova Campanha usa Refúgio/Colina e Andlar provisória;
M2–M5 são regiões legadas/cenas de teste. IDs abaixo preservam o contrato
narrativo e a cobertura de `tests/explore_campaign.lua`; não descrevem reinos
entregues em Andlar. A geografia atual prevalece em
[PLANO_REFUGIO_ANDLAR.md](PLANO_REFUGIO_ANDLAR.md).

## Verificação comum

- Percurso conecta chegada, lugares garantidos, recurso principal e saída.
  Pistas essenciais e recursos não dependem de subquest, sorteio ou NPC vivo.
- Diálogo/menu/foco congelam hostilidade; ler documento não abre arena.
- Gatilho declarado abre diálogo/arena; retirada conserva encontro pendente.
  Negociação/vitória persistem, removem encontro e não duplicam recompensa.
- Save/revisita/morte preservam etapas, flags, props, itens, encontros e
  localização de moradores. Morte reinicia só encontro não resolvido.
- Mudança após missão aparece no lugar e na relação; fonte alternativa
  garante entendimento se testemunha estiver ausente. Fala não ignora isso.
- Arte, retratos, fonte, colisão e avisos exigem leitura visual. Suíte verde
  não aprova qualidade de composição nem percurso humano.

## Nova Campanha — aceite atual

Cripta/pertences/grade → subida/mirante → cidade com cinco interiores e
retorno à mesma porta → preparo na oficina → cisterna → conclusão explícita
no Marco. Só então ANDLAR acende; nova interação permite viajar, caminhar no
chão provisório e retornar à mesma praça. Quests opcionais e M2–M5 não
bloqueiam essa partida. Descanso e refeição recuperam vida; morte preserva
progresso. Save antigo continua no percurso legado, sem migração silenciosa.

## Execução e evidência

Da raiz: `love . --test` e `love . --ui-test`; cobertura/comandos em
[tests/README.md](../tests/README.md). Para cada região afetada, evidencie
chegada, objetivo, encontro, mudança depois e retorno. Leia HUD e intenções
em 1120×800 e 900×680. Capturas ficam somente em `screenshots/`:

```text
love . --scene=hub --size=1120x800 --capture-after=30 --screenshot=screenshots/qa-hub.png
```

Captura preta sob fade precisa ser refeita após a transição. Cenas válidas
estão em `main.lua`; não presumir que todo ID de ficha tem cena pronta.
Para M2–M5, use as cenas genéricas `oficinas`, `mercado`, `reservatorio` e
`saloes`; chegada/batalha/depois são vistas desejadas, cujo estado precisa
ser preparado, não novos IDs aceitos por `--scene`.

## M1–M5 — requisitos das fichas e regressões legadas

Os gates seguintes pertencem à organização anterior. Preservam necessidades
narrativas e testes; a adaptação futura a Andlar deve revisar geografia sem
apagar recursos, pistas e alternativas de resolução.

## M1 — Colina dos Sepultados

Etapas `P01-E01`–`E06`; encontro `T01-01`; subquests Doro `D01`–`D03`, Teca
`T01`–`T03`. Lugares garantidos: sepultura, pátio do velório, depósito funerário,
grade de Runa, chegada ao refúgio.

**Contrato de progressão/persistência:** `P01-E05` (chegada reconhecida + baú acessível) e
`P01-E06` (escolha de expedição registra destino) na estrutura legada; flags das
etapas `D01–D03`/`T01–T03`; conversa pós-verdade de Runa não repete a versão
oficial sem condição.


## M2 — Oficinas de Dentro

Etapas `P02-E01`–`P02-E05` (chegada,
conflito, preparar saída, resolver Janda, retornar/bancada). Encontro principal
`B02-01` (Janda, oficina central); comuns `C02-01`, `C02-02` e `C02-03`. Lugares:
entrada (placa), bancada de Brina, alojamento (Neco), saída danificada, depósito
(conjunto de ferramentas), oficina central.

**Checks específicos:**
- Conjunto de ferramentas único no depósito garantido; obtível por acordo e por
  confronto; nunca consumido por subquest/compra opcional.
- Gate: rota do mapa 4 abre com ferramentas + traçado identificado,
  **independente** do estado do Mercado e das subquests.
- Retorno antecipado: diálogo de Doro reconhece progresso, não repete o pedido.
- Saída danificada reparada persiste entre visitas e após morte.
- `B02-01`: resultados acordo/rendição/morte gravam flags distintas;
  ferramentas acessíveis em todos; promessa quebrada (estrutura destruída após
  compromisso) muda reação de Janda.
- Fonte da lembrança de Lia: encomenda no depósito legível sem Brina viva.


## M3 — Mercado das Escoras

Etapas `P03-E01`–`E06`. Encontros `C03-01` (2 sentinelas), `C03-02`
(2 rastejantes), `C03-Q01` (bruto, opcional), `B03-01` (Rute). Lugares: entrada,
balcão de Ema, antiga banca do casal, arquivo de encomendas, depósito
(chapa+dobradiças), praça de avaliação, carro de peças → rota 5.

**Checks específicos:**
- Conjunto chapa+dobradiças garantido e protegido (nicho) mesmo com tudo
  quebrado; obtido por troca ou retirada.
- `C03-01` transponível por explicação/arcar guardado **sem** arena; insistir
  armado abre arena só após confirmação.
- `C03-02` evitável por desvio garantido ou comida; nunca sobre o documento de
  Brina nem o encaixe do casal.
- `B03-01`: recibo apresentado resolve por acordo; examinar recibo **não**
  inicia batalha; acordo/rendição/vitória/morte produzem registros distintos.
- Carro movido persiste e torna rota 5 utilizável; `P03-E05`/`E06` registram
  conjunto depositado e forno funcional.
- Documento de autoria de Brina acessível sem Ema e sem repetir o chefe.


## M4 — Jardins do Reservatório

Etapas `P04-E01`–`E06`. Encontros `C04-01` (2 rastejantes), `C04-02`
(sentinela+bruto), `C04-Q01` (opcional), `B04-01` (Ivo). Lugares: posto de
chegada, jardim/banco, depósito técnico (filtros), canal de teste, sala das
comportas, corredor inferior.

**Checks específicos:**
- Gate de entrada: exige conjunto de ferramentas (M2) + rota de manutenção —
  não basta flag de mapa 2 "visitado"; independente de M3/M5.
- `C04-02`: mostrar esquema e combinar isolamento dá passagem sem arena; romper
  bloqueio à força abre arena explícita; retirada mantém pendente.
- Experimentar o canal de teste **não** dispara arena (E04 é preparação).
- `B04-01`: derrota/rendição/morte distintos; Ivo morto → esquema + volante
  manual garantem conclusão segura.
- Drenagem persiste: corredor inferior aberto na revisita e após morte;
  canteiros não resetam.
- Gate do mapa 6: drenagem de M4 **e** escora de M5 — cada um sozinho não abre.
- Fonte sem Mara: marca datada de serviço preserva a lembrança do banco.


## M5 — Salões da Vigília

Etapas `P05-E01`–`E06`. Encontros `C05-01` (2 rastejantes), `C05-02`
(2 sentinelas), `C05-Q01` (bruto, duelo de quest), `B05-01` (Beltran). Lugares:
chegada, cozinha auxiliar, palco, ala ocupada, depósito excedente (ferragens),
corredor superior.

**Checks específicos:**
- Gate de entrada: rota aberta pelo Mercado (M3); independente de M4.
- `C05-02`: conversar sobre excedentes + inspecionar laudo dá acesso sem arena;
  laudo e pista do casal alcançáveis sem derrotar os vigias.
- `C05-Q01`: **não admite resultado letal** — termina em rendição/desarme;
  check explícito de que `endBattle` letal não é caminho válido.
- `B05-01`: confronto abre conversa antes de arena; plateia fora da arena não
  sofre dano; Beltran morto → programa + laudo preservam reorganização.
- Ferragens protegidas: combate nunca destrói o recurso principal.
- Corredor superior reforçado + realocação persistem na revisita.
- Teca ausente: plano garantido permite instalar divisórias sem ela.
