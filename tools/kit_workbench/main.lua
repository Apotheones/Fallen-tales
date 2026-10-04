-- kit_workbench — bancada de revisão W3 (docs/MEGAPLAN_KIT_PROCEDURAL_IA.md §8).
-- Controle por script/CLI, nada de clique. Saída previsível em screenshots/.
--
--   lovec tools/kit_workbench --asset=lampiao [opções]
--   tools/run_headless --tools/kit_workbench --asset=lampiao --views=grid,lit
--
-- Opções:
--   --asset=NOME|caminho.lua   def em src.sprites ou arquivo (obrigatório)
--   --vs=NOME|caminho.lua      segundo asset p/ views ab e diff
--   --frame=N|all              frame 1-based (default 1; 'all' = tira)
--   --zoom=N                   zoom inteiro 1..16 (default 4)
--   --bg=SPEC                  checker|neutral|dark|ambient:<regiao>|
--                            game[:<piso>]|shot:<arq.png>[@x,y]
--   --views=a,b,c              albedo normal emissive luminance silhouette
--                            channels grid crop swatches tile lit ab diff
--                            blink frames onion seq instances loop tracks dump
--                            (default: albedo,channels,grid,swatches)
--   --seq=i1,i2,nome           seleção animada: índices ou def.sequences
--                            (filtra frames/onion/seq/instances/loop/tracks/--play)
--   --instances=N --phase=K    N instâncias do ator com fase K (view instances)
--   --light=x,y[,z[,raio[,int]]]  luz na view lit, coord. do sprite (repetível)
--   --lcolor=r,g,b             cor aplicada à ÚLTIMA --light (default quente)
--   --ambient=REGIAO|r,g,b     ambiente da view lit (default 'neutro')
--   --crop=x,y,w,h             recorte 1-based (views crop/albedo/...)
--   --region=NOME              recorta via def.regions[NOME]
--   --mask=NOME                overlay de def.masks[NOME] na view grid
--   --mark=NOME@x,y            âncora proposta, marcada em laranja (repetível)
--   --tile=N                   repetição NxN na view tile (default 3)
--   --seed=N                   seed das variantes no tile (default 0)
--   --budget=N                 aviso se cores do frame > N
--   --strict                   warnings viram exit code 2
--   --out=PREFIXO              prefixo dos PNGs (default wb-<asset>)
--   --report=CAMINHO           relatório (default screenshots/<out>-report.txt)
--   --test                     self-check embutido (defs em memória) e sai
--   --play [--fps=N]           playback interativo (janela visível; espaço
--                              pausa, ←→ passo, ↑↓ fps, Esc sai)
--
-- Views animadas: frames (strip grade+bbox por quadro), onion (fantasma
-- do anterior em vermelho + próximo em azul, wrap de loop), blink (par
-- A/B com enquadramento idêntico p/ alternar entre arquivos), seq
-- (captura reproduzível com índice e tempo), instances (N cópias em
-- fase), loop (costura fLast→fFirst), tracks (rastros de âncora).
-- Metadados lidos (contrato W4/Cinzel): def.anchors por frame
-- {{x,y}...} ou estática {x,y}, def.markers={nome={f1,..}},
-- def.sequences={nome={first,last[,loop]}}, def.frameDuration.
--
-- Exit: 0 ok · 1 erro duro (carga/bake/view/args) · 2 warnings com --strict.
-- Erros vão para arquivo: o lovec headless não mostra console no Windows.

local playctl

local function die(msg)
    local f = io.open('screenshots/kit-workbench-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    print(msg)
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end
function love.errorhandler(msg) die(msg) return function() return 1 end end

local function parseNums(s)
    local t = {}
    for n in tostring(s):gmatch('[^,;]+') do t[#t + 1] = tonumber(n) end
    return t
end

local function parse(args)
    local job = { light = {}, marks = {}, views = nil }
    local testOnly = false
    for _, a in ipairs(args) do
        local k, v = a:match('^%-%-([%w_]+)=?(.*)$')
        if a == '--test' then
            testOnly = true
        elseif k == 'asset' then job.asset = v
        elseif k == 'vs' then job.vs = v
        elseif k == 'frame' then job.frame = (v == 'all') and 'all' or tonumber(v)
        elseif k == 'zoom' then job.zoom = tonumber(v)
        elseif k == 'bg' then job.bg = v
        elseif k == 'views' then
            job.views = {}
            for name in v:gmatch('[^,]+') do job.views[#job.views + 1] = name end
        elseif k == 'light' then
            local n = parseNums(v)
            job.light[#job.light + 1] = { x = n[1], y = n[2], z = n[3],
                radius = n[4], intensity = n[5] }
        elseif k == 'lcolor' then
            local c = parseNums(v)
            if #job.light == 0 then job.light[1] = {} end
            job.light[#job.light].color = { c[1] or 1, c[2] or 1, c[3] or 1 }
        elseif k == 'ambient' then
            local c = parseNums(v)
            job.ambient = (#c == 3) and c or v
        elseif k == 'crop' then
            local n = parseNums(v)
            job.crop = { x = n[1], y = n[2], w = n[3], h = n[4] }
        elseif k == 'region' then job.region = v
        elseif k == 'mask' then job.mask = v
        elseif k == 'mark' then
            local nome, x, y = v:match('^([^@]+)@(%-?%d+),(%-?%d+)$')
            if not nome then die('mark inválido (use nome@x,y): ' .. v) end
            job.marks[#job.marks + 1] = { name = nome, x = tonumber(x), y = tonumber(y) }
        elseif k == 'tile' then job.tile = tonumber(v)
        elseif k == 'seed' then job.seed = tonumber(v)
        elseif k == 'seq' then
            job.seq = {}
            for it in v:gmatch('[^,]+') do job.seq[#job.seq + 1] = it end
        elseif k == 'instances' then job.instances = tonumber(v)
        elseif k == 'phase' then job.phase = tonumber(v)
        elseif k == 'budget' then job.budget = tonumber(v)
        elseif k == 'strict' then job.strict = true
        elseif k == 'play' then job.play = true
        elseif k == 'fps' then job.fps = tonumber(v)
        elseif k == 'out' then job.out = v
        elseif k == 'report' then job.report = v
        elseif k == 'help' or a == '-h' then
            print((arg[0] or '') .. ' — ver cabeçalho de tools/kit_workbench/main.lua')
            love.event.quit(0)
        else
            die('opção desconhecida: ' .. a)
        end
    end
    return job, testOnly
end

function love.load(args)
    package.path = package.path .. ';./?.lua;./?/init.lua'
    love.graphics.setDefaultFilter('nearest', 'nearest')
    local WB = require('tools.kit_workbench.workbench')
    local job, testOnly = parse(args)
    if testOnly then
        local r = WB.selfCheck()
        print('kit_workbench selfcheck ok: ' .. #r.paths .. ' arquivos, '
            .. r.warnings .. ' warnings, report ' .. r.report)
        love.event.quit(r.exit)
        return
    end
    if not job.asset then die('falta --asset=NOME|caminho.lua') return end
    if job.play then
        -- playback interativo: a janela só é visível com --play (conf.lua)
        playctl = WB.play(job.asset, { fps = job.fps, zoom = job.zoom,
            seq = job.seq })
        print(('kit_workbench play: %s (%d frames) — espaço=pausa ←→=passo')
            :format(playctl.A.name, playctl.A.sheet.frames))
        return -- fica no loop até Esc
    end
    local r = WB.run(job)
    for _, t in ipairs(r.findings) do
        local c = t.coord and (' @' .. t.coord[1] .. ',' .. t.coord[2]) or ''
        print(string.format('[%s] f%s%s %s', t.sev, tostring(t.frame or '-'), c,
            t.reason or '?'))
    end
    print(string.format('kit_workbench: %d arquivos, %d warnings, %d erros -> %s',
        #r.paths, r.warnings, r.errors, r.report))
    love.event.quit(r.exit)
end

function love.update(dt)
    if playctl then playctl.update(dt) end
end

function love.draw()
    if playctl then playctl.draw() end
end

function love.keypressed(k)
    if playctl then playctl.key(k) end
end
