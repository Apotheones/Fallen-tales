-- Runner scriptavel do kit procedural (W0). Rodar da raiz do projeto:
--   lovec tools/kit_run --check        checks compactos do kit (exit 0/1)
--   lovec tools/kit_run --verify       determinismo: mesma receita+seed =
--                                      mesmos pixels; edicao = def nova = bake
--                                      novo, sem cache obsoleto
--   lovec tools/kit_run --bake=<nome>  assa asset de src/sprites e exporta
--                                      screenshots/<nome>_{albedo,normal,
--                                      emissive}.png
--   lovec tools/kit_run --revise       piloto W1: revisao local do bau
--                                      (tools/kit_run/pilot_bau.lua)
--   lovec tools/kit_run --baseline     perf: tempo de bake, dimensoes de
--                                      sheet, memoria retida, custo de
--                                      render -> screenshots/kit-baseline.txt
--
-- Exit codes: 0 ok | 1 falha de check | 2 autoria (def/brief/argumento)
--             | 3 bake | 4 export/render | 5 uso (modo desconhecido)
-- Saida previsivel: tudo que o runner grava fica em screenshots/.
-- Receitas Lua sao codigo confiavel do repositorio; o runner nao e
-- sandbox de scripts de terceiros.

local K, DSL
local report = {}
local renderMeasure = nil -- baseline agenda medicao de draw no love.draw

local EXIT = { ok = 0, check = 1, authoring = 2, bake = 3, render = 4, usage = 5 }

local function say(msg)
    print('kit_run: ' .. msg)
    report[#report + 1] = msg
end

local function fail(stage, msg) error({ stage = stage, msg = msg }, 0) end

local function checkv(cond, msg) if not cond then fail(EXIT.check, msg) end end

--------------------------------------------------------------------------------
-- estagios com codigo proprio
--------------------------------------------------------------------------------

local function load_def(name) -- autoria: localizar e validar a def
    local ok, reg = pcall(require, 'src.sprites')
    checkv(ok and type(reg) == 'table', 'nao foi possivel carregar src/sprites')
    local def = reg[name]
    if not def then
        fail(EXIT.authoring, "asset '" .. tostring(name) .. "' nao existe em src/sprites")
    end
    if type(def) ~= 'table' or type(def.layers) ~= 'table' or #def.layers == 0 then
        fail(EXIT.authoring, "asset '" .. name .. "': def invalida (sem layers)")
    end
    return def
end

local function bake_def(def) -- bake: DSL.bake protegido
    local ok, sheet = pcall(DSL.bake, def)
    if not ok then
        fail(EXIT.bake, 'bake de ' .. tostring(def.name or '?') .. ': ' .. tostring(sheet))
    end
    return sheet
end

local function dump_sheet(sheet, base) -- export: escrita dos PNGs
    local ok, paths = pcall(DSL.dump, sheet, base)
    if not ok then fail(EXIT.render, 'export ' .. base .. ': ' .. tostring(paths)) end
    return paths
end

local function sprites_sorted()
    local reg = require('src.sprites')
    local names = {}
    for name in pairs(reg) do names[#names + 1] = name end
    table.sort(names)
    return reg, names
end

local function clone_def(def) -- mesma receita, identidade nova (sem cache)
    return {
        name = def.name, w = def.w, h = def.h, origin = def.origin,
        legend = def.legend, layers = def.layers,
    }
end

local function same_pixels(a, b)
    for _, ch in ipairs({ 'albedo', 'normal', 'emissive' }) do
        local ia, ib = a.imageData[ch], b.imageData[ch]
        if ia:getWidth() ~= ib:getWidth() or ia:getHeight() ~= ib:getHeight() then
            return false
        end
        if ia:getString() ~= ib:getString() then return false end
    end
    return true
end

--------------------------------------------------------------------------------
-- --check: checks executaveis compactos do kit (W1 + contratos)
--------------------------------------------------------------------------------

local function run_checks()
    checkv(DSL.selfCheck(), 'sprite_dsl.selfCheck falhou')

    -- parse/string ida-e-volta
    local g = K.new(9, 5)
    K.rect(g, 2, 2, 4, 3, 'a')
    checkv(K.string(K.parse(K.string(g))) == K.string(g), 'parse/string nao fecha')
    checkv(not pcall(K.parse, 'aa\na'), 'parse ragged devia falhar')

    -- rng deterministico por asset; nao depende de ordem nem de math.random
    local r1, r2, r3 = K.rng('bau', 7), K.rng('bau', 7), K.rng('bau', 8)
    for _ = 1, 16 do checkv(r1.float() == r2.float(), 'rng nao deterministica') end
    local diff = false
    for _ = 1, 8 do if r1.float() ~= r3.float() then diff = true end end
    checkv(diff, 'rng de seeds diferentes devia divergir')
    checkv(K.rng('bau', 7).float() ~= K.rng('outro', 7).float(),
        'rng de nomes diferentes devia divergir')
    local intok = true
    local ri = K.rng('bau', 3)
    for _ = 1, 50 do local v = ri.int(2, 5); if v < 2 or v > 5 then intok = false end end
    checkv(intok, 'rng int fora do intervalo')

    -- brief minimo
    local b = K.brief { name = 'p', w = 32, h = 32 }
    checkv(b.seed == 0 and type(b.regions) == 'table', 'brief nao normalizou')
    checkv(not pcall(K.brief, { w = 1, h = 1 }), 'brief sem name devia falhar')
    checkv(not pcall(K.brief, { name = 'x', w = 0, h = 1 }), 'brief w=0 devia falhar')

    -- curvas: extremidades exatas, rasterizacao conectada, degenerada ok
    local cg = K.new(21, 21)
    K.qcurve(cg, 2, 18, 10, 2, 18, 18, 'c')
    checkv(K.get(cg, 2, 18) == 'c' and K.get(cg, 18, 18) == 'c',
        'qcurve nao tocou as pontas')
    local rep = K.inspect(cg)
    checkv(rep.pixels >= 10, 'qcurve rasterizou pouco')
    K.ccurve(cg, 2, 10, 8, 20, 14, 2, 18, 10, 'd')
    checkv(K.get(cg, 2, 10) == 'd' and K.get(cg, 18, 10) == 'd',
        'ccurve nao tocou as pontas')
    local deg = K.new(4, 4)
    K.qcurve(deg, 2, 2, 2, 2, 2, 2, 'x')
    checkv(K.inspect(deg).pixels == 1, 'curva degenerada devia dar 1 pixel')

    -- path aberto/fechado
    local pg = K.new(9, 9)
    K.path(pg, { 2, 2, 8, 2, 8, 8 }, 'p')
    checkv(K.get(pg, 8, 2) == 'p' and K.get(pg, 4, 4) == '.', 'path aberto fechou')
    K.path(pg, { 2, 2, 8, 2, 8, 8 }, 'q', nil, true)
    checkv(K.get(pg, 4, 4) == 'q', 'path fechado nao fechou a diagonal')

    -- stroke: espessura 3 cobre joins; w=1 == path
    local sg = K.new(15, 15)
    K.stroke(sg, { 2, 2, 8, 8, 14, 2 }, 3, 's')
    checkv(K.get(sg, 8, 8) == 's' and K.get(sg, 8, 7) == 's', 'join do stroke vazio')
    checkv(K.get(sg, 2, 2) == 's' and K.get(sg, 14, 2) == 's', 'ponta do stroke')
    local sw = K.new(15, 15)
    K.stroke(sw, { 2, 2, 8, 8 }, 1, 's')
    local pw = K.new(15, 15)
    K.line(pw, 2, 2, 8, 8, 's')
    checkv(K.string(sw) == K.string(pw), 'stroke w=1 difere de line')

    -- fill: conectividade e limite por mascara
    local fg = K.new(9, 9)
    K.rect(fg, 2, 2, 5, 5, 'w')
    K.rect(fg, 3, 3, 3, 3, '.')
    K.fill(fg, 4, 4, 'f', { conn = 4 })
    checkv(K.get(fg, 4, 4) == 'f' and K.get(fg, 2, 2) == 'w', 'fill vazou')
    local dg = K.new(5, 5)
    dg.rows[1][1] = 'a'; dg.rows[2][2] = 'a' -- diagonal: 8 liga, 4 nao
    K.fill(dg, 1, 1, 'b', { conn = 8 })
    checkv(K.get(dg, 2, 2) == 'b', 'fill conn=8 nao seguiu diagonal')
    local dg2 = K.new(5, 5)
    dg2.rows[1][1] = 'a'; dg2.rows[2][2] = 'a'
    K.fill(dg2, 1, 1, 'b', { conn = 4 })
    checkv(K.get(dg2, 2, 2) == 'a', 'fill conn=4 seguiu diagonal')
    local bg = K.new(6, 6)
    K.fill(bg, 3, 3, 'z', { mask = K.sel_rect(bg, 3, 3, 2, 2) })
    checkv(K.inspect(bg).pixels == 4, 'fill ignorou a mascara')

    -- selecoes
    local sgl = K.new(8, 8)
    K.rect(sgl, 2, 2, 3, 3, 'a'); K.pixel(sgl, 6, 6, 'b')
    checkv(K.inspect(K.sel_color(sgl, 'a')).pixels == 9, 'sel_color errado')
    checkv(K.inspect(K.sel_cover(sgl)).pixels == 10, 'sel_cover errado')
    checkv(K.inspect(K.sel_rect(sgl, 2, 2, 2, 2)).pixels == 4, 'sel_rect errado')
    local comp = K.sel_component(sgl, 3, 3, 4)
    checkv(K.inspect(comp).pixels == 9, 'sel_component errado')

    -- ops de mascara
    local m1 = K.sel_rect(sgl, 1, 1, 4, 4)
    local m2 = K.sel_rect(sgl, 3, 3, 4, 4)
    checkv(K.inspect(K.mask_or(m1, m2)).pixels == 28, 'mask_or errado')
    checkv(K.inspect(K.mask_and(m1, m2)).pixels == 4, 'mask_and errado')
    checkv(K.inspect(K.mask_sub(m1, m2)).pixels == 12, 'mask_sub errado')
    checkv(K.inspect(K.mask_not(m1)).pixels == 64 - 16, 'mask_not errado')
    checkv(K.inspect(K.mask_not(m1, m2)).pixels == 12, 'mask_not bounds errado')
    checkv(K.inspect(K.mask_dilate(m2)).pixels == 32, 'mask_dilate errado')
    checkv(K.inspect(K.mask_erode(m2)).pixels == 4, 'mask_erode errado')
    checkv(not pcall(K.mask_or, m1, K.new(4, 4)), 'mask op com tamanho diverso')

    -- regioes nomeadas preservadas por clone/flip/crop/shift
    local rg = K.new(8, 8)
    K.rect(rg, 2, 2, 3, 3, 'a')
    K.set_region(rg, 'meio', K.sel_rect(rg, 2, 2, 3, 3))
    checkv(K.region(rg, 'meio') ~= nil, 'region nao guardou')
    checkv(K.region(K.clone(rg), 'meio') ~= nil, 'clone perdeu regiao')
    checkv(K.region(K.flip(rg, true), 'meio') ~= nil, 'flip perdeu regiao')
    checkv(K.region(K.shift(rg, 1, 0), 'meio') ~= nil, 'shift perdeu regiao')
    checkv(K.inspect(K.region(K.shift(rg, 1, 0), 'meio')).pixels == 9,
        'shift nao moveu a regiao junto')
    checkv(K.region(K.crop(rg, 2, 2, 3, 3), 'meio') ~= nil, 'crop perdeu regiao')

    -- crop/shift/stamp com pivo
    local cr = K.crop(sgl, 2, 2, 3, 3)
    checkv(cr.w == 3 and K.get(cr, 1, 1) == 'a', 'crop errado')
    local st = K.parse('bb\nbb')
    local dst = K.new(9, 9)
    K.stamp(dst, st, 5, 5, 'center')
    checkv(K.get(dst, 4, 4) == 'b' and K.get(dst, 5, 5) == 'b', 'stamp center')
    local dst2 = K.new(9, 9)
    K.stamp(dst2, st, 4, 4, 'feet')
    checkv(K.get(dst2, 4, 4) == 'b' and K.get(dst2, 4, 3) == 'b', 'stamp feet')

    -- patch: pixels, rows (' ' pula, '.' apaga), confinado por mascara
    local pg2 = K.new(8, 8)
    K.rect(pg2, 1, 1, 8, 8, 'a')
    K.patch(pg2, {
        pixels = { { 2, 2, 'z' } },
        rows = { { x = 3, y = 3, text = 'z z' } },
    })
    checkv(K.get(pg2, 2, 2) == 'z' and K.get(pg2, 3, 3) == 'z'
        and K.get(pg2, 4, 3) == 'a' and K.get(pg2, 5, 3) == 'z', 'patch rows')
    K.patch(pg2, { pixels = { { 2, 2, '.' } } })
    checkv(K.get(pg2, 2, 2) == '.', 'patch nao apagou')
    K.patch(pg2, { pixels = { { 1, 1, 'z' }, { 8, 8, 'z' } } },
        K.sel_rect(pg2, 5, 5, 4, 4))
    checkv(K.get(pg2, 1, 1) == 'a' and K.get(pg2, 8, 8) == 'z',
        'patch ignorou mascara')

    -- outlines: outer/inner/lit/shadow/selective
    local og = K.new(9, 9)
    K.rect(og, 4, 4, 3, 3, 'a')
    K.outline(og, 'o', { mode = 'inner' })
    checkv(K.get(og, 4, 4) == 'o' and K.get(og, 5, 5) == 'a', 'inner errado')
    local lg = K.new(9, 9)
    K.rect(lg, 4, 4, 3, 3, 'a')
    K.outline(lg, 'l', { mode = 'lit' })
    checkv(K.get(lg, 5, 3) == 'l' and K.get(lg, 3, 5) == 'l'
        and K.get(lg, 7, 5) == '.' and K.get(lg, 5, 7) == '.', 'lit errado')
    K.outline(lg, 's', { mode = 'shadow' })
    checkv(K.get(lg, 7, 5) == 's' and K.get(lg, 5, 7) == 's', 'shadow errado')
    local se = K.new(9, 9)
    K.rect(se, 3, 3, 2, 2, 'a'); K.rect(se, 6, 6, 2, 2, 'b')
    K.outline(se, 'o', { colors = { a = true } })
    checkv(K.get(se, 2, 3) == 'o' and K.get(se, 5, 6) == '.', 'selective errado')
    checkv(K.get(og, 4, 4) == 'o', 'sanidade pos-inner')

    -- poligono concavo + buraco via mascara (fill '.' confinado)
    local lg2 = K.new(9, 7)
    K.polygon(lg2, { 2, 2, 8, 2, 8, 6, 4, 6, 4, 4, 2, 4 }, 'l')
    checkv(K.get(lg2, 3, 5) == '.' and K.get(lg2, 6, 5) == 'l'
        and K.get(lg2, 3, 3) == 'l', 'poligono concavo falhou')
    K.fill(lg2, 6, 5, '.', { mask = K.sel_rect(lg2, 6, 4, 2, 2) })
    checkv(K.get(lg2, 6, 4) == '.' and K.get(lg2, 6, 5) == '.'
        and K.get(lg2, 5, 5) == 'l', 'buraco por mascara falhou')

    -- review aids
    local rv = K.new(11, 9)
    K.rect(rv, 2, 2, 4, 6, 'a')          -- coluna esquerda alta (x2..5,y2..7)
    K.rect(rv, 6, 5, 4, 3, 'a')          -- bloco baixo colado (x6..9,y5..7)
    rv.rows[3][3] = '.'                  -- furo cercado (x3,y3)
    rv.rows[6][3] = '.'                  -- segundo furo (x3,y6)
    local rep2 = K.review(rv, { a = 'x' })
    checkv(#rep2.clusters == 1 and rep2.clusters[1].size == 34,
        'clusters errados')
    checkv(#rep2.steps >= 1 and rep2.steps[1].x == 6, 'steps nao flagou salto')
    checkv(#rep2.thickness.jumps >= 1, 'thickness nao flagou mudanca')
    checkv(#rep2.corners >= 4, 'corners insuficientes')
    checkv(#rep2.gaps == 2, 'gaps nao detectados')

    -- clipping degenerado e mascara no desenho
    local ng = K.new(5, 5)
    K.qcurve(ng, -8, -8, 2, 2, 12, -8, 'c')
    K.stroke(ng, { -3, 3, 9, 3 }, 2, 'c')
    checkv(not pcall(K.qcurve, ng, 1, 1, 1.5, 2, 3, 3, 'c'),
        'coordenada nao-inteira devia falhar')
end

--------------------------------------------------------------------------------
-- --verify: determinismo e cache
--------------------------------------------------------------------------------

local function run_verify()
    local reg, names = sprites_sorted()
    local n = 0
    for _, name in ipairs(names) do
        local sa = bake_def(reg[name])
        local sb = bake_def(clone_def(reg[name]))
        checkv(sa ~= sb, name .. ': def clone devia gerar sheet novo')
        checkv(same_pixels(sa, sb), name .. ': mesma receita gerou pixels diferentes')
        n = n + 1
    end
    -- receita procedural com rng asset-local: duas execucoes identicas
    local function recipe()
        local gg = K.new(16, 16)
        local r = K.rng('verify', 42)
        for _ = 1, 6 do
            K.qcurve(gg, r.int(1, 8), r.int(1, 16), r.int(1, 16), r.int(1, 16),
                r.int(9, 16), r.int(1, 16), 'v')
        end
        return K.string(gg)
    end
    checkv(recipe() == recipe(), 'receita com rng nao e deterministica')
    say(string.format('verify: %d assets com bake identico; receita rng estavel', n))
end

--------------------------------------------------------------------------------
-- --bake=<nome>
--------------------------------------------------------------------------------

local function run_bake(name)
    local def = load_def(name)
    local sheet = bake_def(def)
    dump_sheet(sheet, 'screenshots/' .. name)
    say(string.format('bake %s: %dx%d, %d frame(s), origin=%s -> screenshots/%s_*.png',
        name, sheet.w, sheet.h, sheet.frames, sheet.origin, name))
end

--------------------------------------------------------------------------------
-- --revise: piloto W1 (tools/kit_run/pilot_bau.lua)
--------------------------------------------------------------------------------

local function run_revise()
    local ok, pilot = pcall(require, 'tools.kit_run.pilot_bau')
    if not ok or type(pilot) ~= 'table' or type(pilot.run) ~= 'function' then
        fail(EXIT.authoring, 'pilot_bau.run ausente: ' .. tostring(pilot))
    end
    local ok2, lines = pcall(pilot.run, K, DSL, dump_sheet, say)
    if not ok2 then
        local stage = type(lines) == 'table' and lines.stage or EXIT.check
        fail(stage, tostring(type(lines) == 'table' and lines.msg or lines))
    end
    for _, l in ipairs(lines or {}) do say(l) end
end

--------------------------------------------------------------------------------
-- --baseline: perf de bake + memoria + custo de render
--------------------------------------------------------------------------------

local BASE_LIMITS = { dim = 384, frames = 16, sheetMB = 8 }

local function run_baseline()
    collectgarbage('collect')
    local mem0 = collectgarbage('count')
    local reg, names = sprites_sorted()
    local rows, warns, biggest = {}, {}, nil
    local total, t0 = 0, love.timer.getTime()
    for _, name in ipairs(names) do
        local def = reg[name]
        local t = love.timer.getTime()
        local sheet = bake_def(def)
        local ms = (love.timer.getTime() - t) * 1000
        total = total + ms
        local bytes = sheet.w * sheet.frames * sheet.h * 4 * 3
        rows[#rows + 1] = string.format('%-28s %3dx%-3d f=%-2d %8.2fms %7.1fKB',
            name, sheet.w, sheet.h, sheet.frames, ms, bytes / 1024)
        if sheet.w > BASE_LIMITS.dim or sheet.h > BASE_LIMITS.dim then
            warns[#warns + 1] = string.format('WARN %s: dimensao %dx%d > %d',
                name, sheet.w, sheet.h, BASE_LIMITS.dim)
        end
        if sheet.frames > BASE_LIMITS.frames then
            warns[#warns + 1] = string.format('WARN %s: %d frames > %d',
                name, sheet.frames, BASE_LIMITS.frames)
        end
        if bytes > BASE_LIMITS.sheetMB * 1024 * 1024 then
            warns[#warns + 1] = string.format('WARN %s: sheet %.1fMB > %dMB',
                name, bytes / 1048576, BASE_LIMITS.sheetMB)
        end
        if not biggest or bytes > biggest.bytes then
            biggest = { sheet = sheet, name = name, bytes = bytes }
        end
    end
    collectgarbage('collect')
    local memRet = collectgarbage('count') - mem0
    local lines = {
        'kit-baseline — bake de src/sprites (W0)',
        'data: ' .. os.date('%Y-%m-%d %H:%M'),
        'config: bake headless, love.timer, memoria via collectgarbage',
        string.format('assets: %d | bake total: %.1fms | memoria retida: %.0fKB',
            #names, total, memRet),
        '',
    }
    for _, r in ipairs(rows) do lines[#lines + 1] = r end
    if #warns > 0 then
        lines[#lines + 1] = ''
        for _, w in ipairs(warns) do lines[#lines + 1] = w end
    end
    local path = 'screenshots/kit-baseline.txt'
    local f = io.open(path, 'w')
    if not f then fail(EXIT.render, 'nao abriu ' .. path) end
    f:write(table.concat(lines, '\n'), '\n')
    f:close()
    say(string.format('baseline: %d assets, %.1fms total, %d avisos -> %s',
        #names, total, #warns, path))
    -- custo de render fica para o primeiro love.draw (janela 960x540)
    renderMeasure = { sheet = biggest.sheet, name = biggest.name, acc = 0, n = 0 }
    love.window.setMode(960, 540)
end

local function measure_render()
    local s = renderMeasure
    renderMeasure = nil
    local draws, framesN = 300, 30
    for i = 1, framesN do
        local t = love.timer.getTime()
        for j = 1, draws do
            love.graphics.draw(s.sheet.albedo, (j % 30) * 32, math.floor(j / 30) * 32)
        end
        s.acc = s.acc + (love.timer.getTime() - t)
    end
    local ms = s.acc / framesN * 1000
    local f = assert(io.open('screenshots/kit-baseline.txt', 'a'))
    f:write(string.format('\nrender: %.2fms/frame (%d draws de %s, 960x540, nearest)\n',
        ms, draws, s.name))
    f:close()
    print(string.format('kit_run: render %.2fms/frame (%d draws de %s)',
        ms, draws, s.name))
    love.event.quit(0)
end

--------------------------------------------------------------------------------
-- boot
--------------------------------------------------------------------------------

local MODES = {
    check = function() run_checks(); say('check: ok') end,
    verify = run_verify,
    bake = run_bake,
    revise = run_revise,
    baseline = run_baseline,
}

function love.load(args)
    package.path = package.path .. ';./?.lua;./?/init.lua'
    K = require('src.pixel_kit')
    DSL = require('src.sprite_dsl')
    local mode, arg
    for _, a in ipairs(args) do
        local m, v = a:match('^%-%-([%w_]+)=?(.*)$')
        if m and (v == '' or v == nil) then v = true end
        if m and MODES[m] then mode, arg = m, v end
    end
    if not mode then
        print('kit_run: uso: --check | --verify | --bake=<nome> | --revise | --baseline')
        love.event.quit(EXIT.usage)
        return
    end
    if mode == 'bake' and (arg == true or arg == nil) then
        print('kit_run: --bake precisa de =<nome do asset>')
        love.event.quit(EXIT.usage)
        return
    end
    local ok, err = pcall(MODES[mode], arg)
    if ok then
        if not renderMeasure then love.event.quit(EXIT.ok) end
    elseif type(err) == 'table' and err.stage then
        print('kit_run[' .. mode .. '] falhou: ' .. tostring(err.msg))
        love.event.quit(err.stage)
    else
        print('kit_run[' .. mode .. '] erro: ' .. tostring(err))
        love.event.quit(EXIT.check)
    end
end

function love.draw()
    if renderMeasure then measure_render() end
end

function love.keypressed(key)
    if key == 'escape' then love.event.quit(0) end
end

function love.errorhandler(message)
    local f = io.open('screenshots/kit-run-error.txt', 'w')
    if f then f:write(tostring(message), '\n', debug.traceback()); f:close() end
    print(message)
    return function() return EXIT.render end
end
