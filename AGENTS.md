# Prints de teste

Guarde todos os screenshots e PNGs de teste em `screenshots/`, na raiz do projeto.
Ao executar o jogo para capturar uma tela, use `--screenshot=screenshots/nome.png`
com o diretório de trabalho na raiz. Use essa mesma pasta para prints feitos por
outras ferramentas. Não salve prints na raiz nem em `build/`.

# Runner padrao (testes e capturas sem janela)

Nunca rode `lovec .` direto para testes ou capturas — use
`bash tools/run_headless` (lock serializado, timeout com kill, cleanup de
orfaos, janela offscreen via ARROWFALLEN_HEADLESS). Exemplos:
`bash tools/run_headless --test`, `--suite [modulo]`,
`-- --screenshot=screenshots/x.png --scene=map`.
Qualquer flag nao-interativa ja deixa a janela invisivel via conf.lua.
Orfaos: `bash tools/run_headless --cleanup`. Guia completo: nota "runner-padrao" no canvas.
