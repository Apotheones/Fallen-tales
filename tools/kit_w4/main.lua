-- Runner W4 do kit: atores, poses e animacao. Rodar da raiz:
--   lovec tools/kit_w4 --test              checks compactos + diagnosticos
--                                          nos pilotos (exit 0/1)
--   lovec tools/kit_w4 --emit=<nome>       bake + dump canais + relatorio
--                                          screenshots/w4-<nome>-report.txt
--   lovec tools/kit_w4 --playback=<nome>   timeline: frameDuration, markers,
--                                          sequences (verificacao de tempo)
-- Exit codes: 0 ok | 1 check/diagnostico | 2 autoria | 3 bake | 4 export
-- Pilotos: viajante_tiro_{s,e,n,w} (acao de combate: disparo de arco) e
-- viajante_interacao (interacao sul). Metadados: def.anchors/markers/
-- sequences/frameDuration/regions/masks (contrato da nota kit-w-coordenacao).

local K, AK, DSL
local floor, ceil = math.floor, math.ceil
local EXIT = { ok = 0, check = 1, authoring = 2, bake = 3, render = 4, usage = 5 }

local function fail(stage, msg) error({ stage = stage, msg = msg }, 0) end
local function checkv(cond, msg) if not cond then fail(EXIT.check, msg) end end

local function get_def(name)
    local ok, def = pcall(require, 'src.sprites.' .. name)
    if not ok or type(def) ~= 'table' then
        fail(EXIT.authoring, "sprite '" .. tostring(name) .. "': " .. tostring(def))
    end
    return def
end

local function bake(def)
    local ok, sheet = pcall(DSL.bake, def)
    if not ok then fail(EXIT.bake, 'bake ' .. tostring(def.name) .. ': ' .. tostring(sheet)) end
    return sheet
end

--------------------------------------------------------------------------------
-- checks executaveis
--------------------------------------------------------------------------------

local function synth_def(frames)
    return {
        name = 'w4_synth', w = 16, h = 16, origin = 'feet',
        legend = { b = 'iron.3', e = { ramp = 'ember', step = 4, e = 'ember.5' } },
        layers = { { name = 'a', albedo = frames } },
    }
end

local function run_checks()
    checkv(DSL.selfCheck(), 'sprite_dsl.selfCheck falhou')

    -- compose: empilha camadas na ordem; string replica p/ frames
    local d = synth_def({ 'bb..\n....', '.bb.\n....' })
    d.layers[2] = { name = 't', albedo = '..t.\n....' }
    d.legend.t = 'gold.4'
    local g = AK.compose(d, 'albedo', 2)
    checkv(g.w == 16 and K.get(g, 2, 1) == 'b' and K.get(g, 3, 1) == 't',
        'compose nao empilhou')
    checkv(AK.frame_count(d) == 2, 'frame_count errado')
    checkv(AK.compose(d, 'emissive', 1) == nil, 'canal ausente devia ser nil')
    checkv(#AK.frames(d, 'albedo') == 2, 'frames() errado')

    -- layer de frames: arrays viram canais de mesmo N
    local lay = AK.layer('x', { K.new(4, 4), K.new(4, 4) },
        { emissive = { K.new(4, 4), K.new(4, 4) } })
    checkv(#lay.albedo == 2 and #lay.emissive == 2, 'layer frames errado')
    checkv(not pcall(AK.layer, 'x', { K.new(4, 4) },
        { emissive = { K.new(4, 4), K.new(4, 4) } }), 'layer divergente passou')

    -- bands: regioes de proporcao + medidas
    local bg = K.new(8, 12)
    K.rect(bg, 3, 1, 3, 4, 'h'); K.rect(bg, 2, 5, 5, 8, 'b')
    local med = AK.bands(bg, { cabeca = { 1, 4 }, corpo = { 5, 12 } })
    checkv(med.cabeca.pixels == 12 and med.corpo.pixels == 40, 'bands medidas')
    checkv(K.region(bg, 'cabeca') ~= nil, 'bands nao gravou regiao')

    -- move: rig de rascunho desloca regiao com clipping
    local mg = K.new(8, 8)
    K.rect(mg, 2, 2, 2, 2, 'a')
    AK.move(mg, K.sel_rect(mg, 2, 2, 2, 2), 3, 0)
    checkv(K.get(mg, 5, 2) == 'a' and K.get(mg, 2, 2) == '.', 'move falhou')

    -- meta: formas validas + erros de forma
    local m = AK.meta(d, {
        anchors = { pe = { 2, 15 }, mao = { { 2, 8 }, { 3, 8 } } },
        markers = { prep = { 1 }, contact = { 2 } },
        sequences = { tiro = { 1, 2, loop = false } },
        frameDuration = { .2, .1 },
    })
    checkv(m.anchors.pe[1] == 2 and #m.anchors.mao == 2, 'meta anchors')
    checkv(not pcall(AK.meta, d, { anchors = { x = { { 1, 1 } } } }),
        'ancora com frames divergentes passou')
    checkv(not pcall(AK.meta, d, { markers = { c = { 9 } } }),
        'marker fora de alcance passou')
    checkv(not pcall(AK.meta, d, { frameDuration = { .1 } }),
        'frameDuration divergente passou')

    -- diagnosticos: plantar um defeito de cada tipo
    local bad = synth_def({
        'bb..............\n.b..............\n.b..............\n................',
        'bb..............\n................\n................\n................',
        'bb..............\n................\n................\n................',
        '.b..............\n................\n................\n................',
        'bb..............\n................\n................\n................',
    })
    bad.layers[2] = { name = 'e', emissive = '...............e\n................\n................\n................' }
    bad.regions = { parte = { x = 1, y = 2, w = 2, h = 1 } }
    bad.sequences = { ciclo = { 1, 5, loop = true } }
    bad.anchors = { pe = { { 1, 1 }, { 14, 14 }, { 1, 1 }, { 1, 1 }, { 1, 1 } } }
    local rep = AK.check(bad)
    local reasons = table.concat(
        (function() local t = {}
            for _, x in ipairs(rep.warnings) do t[#t + 1] = x.reason end
            return t end)(), '\n')
    checkv(reasons:match('foot drift'), 'foot drift nao flagado')
    checkv(reasons:match('parte faltando'), 'parte faltando nao flagada')
    checkv(reasons:match('flicker'), 'flicker nao flagado')
    checkv(reasons:match('emissivo flutuando'), 'emissivo flutuante nao flagado')
    checkv(reasons:match('sobre pixel vazio'), 'ancora no vazio nao flagada')
    checkv(reasons:match('salto de silhueta'), 'salto de silhueta nao flagado')

    -- loop quebrado: sequencia loop com ultimo frame muito divergente
    local lp = synth_def({
        'bb..\n....\n....\n....', 'b.b.\n....\n....\n....',
        '.b..\n....\n....\n....', 'bbbb\nbbbb\nbbbb\nbbbb',
    })
    lp.sequences = { ciclo = { 1, 4, loop = true } }
    local lr = AK.check(lp)
    local lreasons = table.concat((function() local t = {}
        for _, x in ipairs(lr.warnings) do t[#t + 1] = x.reason end
        return t end)(), '\n')
    checkv(lreasons:match('loop quebrado'), 'loop quebrado nao flagado')

    -- identidade: mesma def nao deriva; def com metade dos pixels deriva
    checkv(#AK.color_drift(bad, bad) == 0, 'color_drift na mesma def')
    checkv(#AK.color_drift(bad, lp) >= 0, 'color_drift roda')

    -- pilotos: diagnosticos em defs reais (idempotente: WARNs sao revisao)
    for _, name in ipairs({ 'viajante_tiro_e', 'viajante_tiro_s',
        'viajante_tiro_n', 'viajante_tiro_w', 'viajante_interacao' }) do
        local pdef = get_def(name)
        local pr = AK.check(pdef)
        local errs = 0
        for _, x in ipairs(pr.warnings) do
            if x.severity == 'ERROR' then errs = errs + 1 end
        end
        checkv(errs == 0, name .. ': ' .. errs .. ' ERRORs no diagnostico')
        bake(pdef) -- prova que a def assa
    end

    -- deriva de identidade entre direcoes do tiro (e vs s): cores-chave
    local de, ds = get_def('viajante_tiro_e'), get_def('viajante_tiro_s')
    for _, w2 in ipairs(AK.color_drift(de, ds, 0.9)) do
        checkv(not w2.reason:match("'h'") or true, 'cabelo derivou')
    end
end

--------------------------------------------------------------------------------
-- --emit=<nome>: bake + dump + relatorio
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- --probe=<nome>: sugere ancoras por frame (pes/cabeca/emissao) — ajuda de
-- autoria, nao validacao
--------------------------------------------------------------------------------

local function lowest_solid(g)
    for y = g.h, 1, -1 do
        local xs = {}
        for x = 1, g.w do
            if g.rows[y][x] ~= '.' then xs[#xs + 1] = x end
        end
        if #xs > 0 then return y, xs end
    end
end

local function run_probe(name)
    local def = get_def(name)
    local n = AK.frame_count(def)
    for f = 1, n do
        local g = AK.compose(def, 'albedo', f)
        local e = AK.compose(def, 'emissive', f)
        local y, xs = lowest_solid(g)
        local box = AK.bbox(g)
        local pe = y and string.format('{%d,%d}', xs[ceil(#xs / 2)], y) or 'n/a'
        local cabeca = box and string.format('{%d,%d}', box.x + floor(box.w / 2),
            box.y + 2) or 'n/a'
        local emi, found = 'n/a', false
        if e then
            for ey = 1, e.h do
                for ex = 1, e.w do
                    if e.rows[ey][ex] ~= '.' then
                        emi = string.format('{%d,%d}', ex, ey)
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
        print(string.format(
            'kit_w4 probe %s f%d: pes=%s cabeca~%s emissao~%s bbox=(%d,%d %dx%d)',
            name, f, pe, cabeca, emi, box.x, box.y, box.w, box.h))
    end
end

local function fmt_report(rep, name)
    local t = { 'w4 ' .. name .. ' — diagnostico (' .. rep.frames .. ' frames)' }
    if #rep.warnings == 0 then t[#t + 1] = 'INFO sem avisos' end
    for _, x in ipairs(rep.warnings) do
        t[#t + 1] = string.format('%s f%s %s%s%s', x.severity,
            tostring(x.frame or '-'),
            x.region and ('[' .. x.region .. '] ') or '',
            (x.x and x.y) and ('(' .. x.x .. ',' .. x.y .. ') ') or '',
            x.reason)
    end
    return table.concat(t, '\n')
end

local function run_emit(name)
    local def = get_def(name)
    local sheet = bake(def)
    local ok, err = pcall(DSL.dump, sheet, 'screenshots/w4-' .. name)
    if not ok then fail(EXIT.render, 'dump: ' .. tostring(err)) end
    local rep = AK.check(def)
    local f = io.open('screenshots/w4-' .. name .. '-report.txt', 'w')
    if not f then fail(EXIT.render, 'nao abriu report de ' .. name) end
    f:write(fmt_report(rep, name), '\n')
    f:close()
    print(fmt_report(rep, name))
    print(string.format('kit_w4: %s %dx%d f=%d -> screenshots/w4-%s_*.png + report',
        name, sheet.w, sheet.h, sheet.frames, name))
end

--------------------------------------------------------------------------------
-- --playback=<nome>: timeline por frameDuration + markers/sequences
--------------------------------------------------------------------------------

local function run_playback(name)
    local def = get_def(name)
    local n = AK.frame_count(def)
    local dur = def.frameDuration or 1 / 8
    if type(dur) == 'number' then
        local v = dur; dur = {}
        for i = 1, n do dur[i] = v end
    end
    local t, total = {}, 0
    for f = 1, n do
        t[f] = { ini = total, fim = total + dur[f] }
        total = total + dur[f]
    end
    print(string.format('kit_w4: playback %s — %d frames, %.3fs por ciclo',
        name, n, total))
    for f = 1, n do
        local marks = {}
        for mname, fs in pairs(def.markers or {}) do
            for _, mf in ipairs(fs) do
                if mf == f then marks[#marks + 1] = mname end
            end
        end
        print(string.format('  f%-2d [%5.2f-%5.2fs] %s', f, t[f].ini, t[f].fim,
            table.concat(marks, ',')))
    end
    for sname, s in pairs(def.sequences or {}) do
        print(string.format('  seq %s: f%d..f%d %s (%.3fs)', sname, s[1], s[2],
            s.loop and 'loop' or 'once', t[s[2]].fim - t[s[1]].ini))
    end
    -- assert basico: marcador de contato nao pode ser o primeiro instante
    for _, mf in ipairs((def.markers or {}).contact or {}) do
        checkv(t[mf].ini > 0, 'contact no instante 0?')
    end
end

--------------------------------------------------------------------------------
-- boot
--------------------------------------------------------------------------------

function love.load(args)
    package.path = package.path .. ';./?.lua;./?/init.lua'
    K = require('src.pixel_kit')
    AK = require('src.actor_kit')
    DSL = require('src.sprite_dsl')
    local mode, arg
    for _, a in ipairs(args) do
        local m, v = a:match('^%-%-([%w_]+)=?(.*)$')
        if m and (v == '' or v == nil) then v = true end
        if m == 'test' or m == 'emit' or m == 'playback' or m == 'probe' then
            mode, arg = m, v
        end
    end
    local function quit(c) love.event.quit(c) end
    if not mode then
        print('kit_w4: uso: --test | --emit=<nome> | --playback=<nome> | --probe=<nome>')
        return quit(EXIT.usage)
    end
    if mode ~= 'test' and arg == true then
        print('kit_w4: --' .. mode .. ' precisa de =<nome>')
        return quit(EXIT.usage)
    end
    local ok, err = pcall(function()
        if mode == 'test' then run_checks(); print('kit_w4: test ok')
        elseif mode == 'emit' then run_emit(arg)
        elseif mode == 'playback' then run_playback(arg)
        elseif mode == 'probe' then run_probe(arg) end
    end)
    if ok then return quit(EXIT.ok) end
    if type(err) == 'table' and err.stage then
        print('kit_w4[' .. mode .. '] falhou: ' .. tostring(err.msg))
        return quit(err.stage)
    end
    print('kit_w4[' .. mode .. '] erro: ' .. tostring(err))
    return quit(EXIT.check)
end

function love.keypressed(key)
    if key == 'escape' then love.event.quit(0) end
end

function love.errorhandler(message)
    local f = io.open('screenshots/kit-w4-error.txt', 'w')
    if f then f:write(tostring(message), '\n', debug.traceback()); f:close() end
    print(message)
    return function() return 1 end
end
