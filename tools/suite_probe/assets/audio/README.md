# Ruínas dos Ecos — trilha sonora

Áudios originais sintetizados, integrados ao jogo.
Baseados no plano `plan-cbc40b24135c4655.md` do elenco do Mundo 1.
Chefes e elites vivos ativam seu tema próprio; depois vêm os desafios e a exploração.
Transições de 1,25s, reprodução em loop por streaming e volume menor no menu/pausa/guia.
M silencia música e efeitos. Salas concluídas retornam à exploração.

| Arquivo | Tema | Uso previsto | Caráter |
| --- | --- | --- | --- |
| chamber_of_echoes.wav | A Câmara dos Ecos | Exploração | Ré menor, arpejos de harpa, melodia e acordes suaves; 80 BPM |
| warden.wav | O Selo do Guardião | Guardião dos Ecos, andar 1 | Motivo firme, timbre de metais sintetizados, pulsação em cruz; 120 BPM |
| demolisher.wav | A Câmara Desaba | Demolidor da Câmara, andar 2 | Registro grave, acordes tensos e pancadas assimétricas; 104 BPM |
| regent.wav | Coroa de Âmbar | Regente de Âmbar, andar 3 | Melodia aguda, sinos e respostas em eco evocando invocações; 96 BPM |
| breaker.wav | Marcha do Demolidor | Bruto Demolidor, elite | Ostinato grave, metais e pressão rítmica; 108 BPM |
| veteran.wav | Duas Linhas de Fogo | Sentinela Veterana, elite | Frases em pares e espaços entre ataques; 116 BPM |
| challenge_combat.wav | Prova de Ferro | Desafio de combate / covil | Melodia sincopada, baixo e percussão insistentes; 112 BPM |
| challenge_targets.wav | Mira dos Ecos | Desafio de pontaria | Sinos, arpejos agudos e pulso regular; 104 BPM |

As faixas têm seções e são preparadas para repetição. WAV PCM estéreo,
16 bits, 22050 Hz. Síntese instrumental; não são gravações de instrumentos acústicos.
O gerador verifica duração, canais, limites de amostra e bordas sem estalo digital;
o ajuste fino da mixagem ainda depende de escuta durante o jogo.

Recriar os arquivos, sem executar ou editar o jogo:

```powershell
python tools/compose_music.py
```
