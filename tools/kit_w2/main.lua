-- kit_w2 — checks e pilotos do W2 (paleta/materiais/canais de luz).
-- Uso, da raiz do projeto:
--   lovec tools/kit_w2            -> checks + pilotos + dumps em screenshots/
--   lovec tools/kit_w2 --test     -> só os checks, sai com código de erro
--
-- Pilotos em assets REAIS existentes (megaplan §7):
--   pedra  -> src/sprites/marco.lua       (monólito, rampa stone)
--   ferro  -> src/sprites/bigorna.lua     (bigorna, rampa iron)
--   tecido -> src/sprites/varal_vento.lua (varal, ramps cloth/clothWarm)
--
-- Saídas (todas em screenshots/):
--   kit_w2_<nome>_{albedo,normal,emissive}.png  bake original
--   kit_w2_<nome>_{luminancia,silhueta}.png     vistas de revisão
--   kit_w2_<nome>_<variante>_albedo.png         variante corrigida
--   kit_w2_prancha.png                          prancha 2x de comparação
--   kit_w2_relatorio.txt                        swatches/budget/avisos

local MAT, DSL, K, Pal
local testOnly

-- Erros vão para arquivo: o lovec headless não mostra console no Windows.
local function die(msg)
    local f = io.open('screenshots/kit_w2-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

--------------------------------------------------------------------------------
-- Checks executáveis (sem depender dos pilotos)
--------------------------------------------------------------------------------

local function perto(a, b, eps)
    return math.abs(a - b) <= (eps or 1e-6)
end

local function check()
    local function stub(spec) -- resolve independente de palettes
        return ({ ['x.1'] = { .1, .2, .3 }, ['x.2'] = { .2, .3, .4 },
            ink = { 0, 0, 0 } })[spec]
    end

    -- luminância monotônica na rampa de pedra (sombra -> luz)
    local ramp = MAT.ramp('stone')
    assert(#ramp == 8, 'rampa stone devia ter 8 degraus')
    for i = 2, #ramp do
        assert(MAT.luminance(ramp[i]) > MAT.luminance(ramp[i - 1]),
            'rampa stone não é monotônica em luminância no degrau ' .. i)
    end

    -- resolução por região: wood.5 (meio da rampa de 7) -> base regional
    local c = MAT.regionStep('mercado', 'wood', 5)
    assert(c == Pal.regions.mercado.wood.base,
        'wood.5 em mercado devia resolver p/ regions.mercado.wood.base')
    assert(MAT.regionStep('mercado', 'wood', 1) == Pal.regions.mercado.wood.dark)
    assert(MAT.regionStep('mercado', 'wood', 7) == Pal.regions.mercado.wood.light)
    -- sem família regional -> cor da rampa mestra, intocada
    assert(MAT.regionStep('mercado', 'iron', 4) == Pal.resolve('iron.4'))
    -- remapSpec: funcional protegido passa intacto
    assert(MAT.remapSpec('danger', 'mercado') == 'danger')
    assert(MAT.remapSpec('wood.5', 'mercado') == Pal.regions.mercado.wood.base)

    -- remapLegend: spec de rampa vira {r,g,b}; funcional e h/ei preservados
    local leg = MAT.remapLegend({
        w = { ramp = 'wood', step = 5, h = 7 },
        k = { spec = 'ink', h = 4 },
    }, 'mercado')
    assert(type(leg.w.spec) == 'table' and leg.w.spec == Pal.regions.mercado.wood.base)
    assert(leg.w.h == 7 and leg.k.spec == 'ink')

    -- swatches/contagem numa def mínima
    local def = {
        legend = { a = 'x.1', b = 'x.1', c = 'x.2' },
        layers = { { name = 'l', albedo = 'ab.\nacc' } },
    }
    local sw = MAT.swatches(def, stub)
    assert(#sw == 3 and sw[1].count == 2, 'swatches: contagens erradas')
    local cc = MAT.colorCount(def, stub)
    assert(cc.chars == 3 and cc.colors == 2,
        'colorCount devia ver 3 chars em 2 cores, viu ' ..
        cc.chars .. '/' .. cc.colors)
    -- redundância: 'a' e 'b' dividem a mesma cor
    local red = MAT.redundant(def, nil, stub)
    assert(#red == 1 and red[1].chars[1] .. red[1].chars[2] == 'ab')
    -- budget: 2 cores com teto 1 estoura (aviso), com teto 2 passa
    assert(MAT.checkBudget(def, 1, stub).ok == false)
    assert(MAT.checkBudget(def, 2, stub).ok == true)

    -- campos de luz: plano, banda, gradiente quantizado, volume, oclusão
    local hg = MAT.hfield(9, 5)
    MAT.applyLightField(nil, hg, { kind = 'plane', v = 4 })
    assert(MAT.hchar(4) == '4' and K.get(hg, 1, 1) == '4')
    MAT.hband(hg, 3, 2, 3, 2, 9)
    assert(K.get(hg, 4, 3) == '9' and K.get(hg, 1, 1) == '4')

    local gg = MAT.hfield(9, 1)
    MAT.hgrad(gg, 'x', 2, 10, 3)
    assert(K.get(gg, 1, 1) == '2' and K.get(gg, 5, 1) == '6'
        and K.get(gg, 9, 1) == 'a', 'hgrad: quantização errada')

    local vv = MAT.hfield(9, 9)
    MAT.hvolume(vv, 5, 5, 4, 4, 3, 12)
    assert(K.get(vv, 5, 5) == 'c' and K.get(vv, 1, 1) == '.',
        'hvolume: pico central ou fora-do-elipse errados')

    local alb = K.new(5, 5)
    K.rect(alb, 2, 2, 3, 3, 's')
    local oh = MAT.hfield(5, 5)
    MAT.hplane(oh, 8)
    MAT.applyLightField(alb, oh, { kind = 'occlusion', drop = 3 })
    assert(K.get(oh, 2, 2) == '5' and K.get(oh, 3, 3) == '8',
        'hocclusion: borda devia cair 3, centro ficar')

    -- emissivo por região + máscara por chars + dither opt-in
    local eg = MAT.hfield(6, 2)
    local m = MAT.maskRect(6, 2, 2, 1, 3, 2)
    MAT.emitRegion(eg, 'e', m)
    assert(K.get(eg, 2, 1) == 'e' and K.get(eg, 1, 1) == '.')
    local ma = MAT.maskChars(alb, 's')
    assert(K.get(ma, 3, 3) ~= '.' and K.get(ma, 1, 1) == '.')
    local dg = K.new(4, 4)
    MAT.dither(dg, 'd')
    local cnt = 0
    for y = 1, 4 do for x = 1, 4 do
        if K.get(dg, x, y) == 'd' then cnt = cnt + 1 end
    end end
    assert(cnt == 8, 'dither devia estampar metade dos pixels')

    -- gridOf: string DSL -> grade, espaço normaliza p/ '.'
    local g2 = MAT.gridOf('ab c\n.d..', 4, 2)
    assert(K.get(g2, 3, 1) == '.' and K.get(g2, 2, 2) == 'd')

    -- tabela de materiais: entradas do spec + detecção por legend
    assert(MAT.material('iron').ramp == 'iron'
        and MAT.material('metal') == MAT.material('iron'))
    local mats = MAT.materialsOf(def)
    assert(next(mats) == nil, 'def de teste não devia ter material')
    local mats2 = MAT.materialsOf({ legend = { i = 'iron.4', e = 'ember.5' } })
    assert(mats2.iron and mats2.fire, 'materialsOf falhou em iron+ember')

    print('kit_w2: checks ok')
end

--------------------------------------------------------------------------------
-- Pilotos em assets reais
--------------------------------------------------------------------------------

-- Budget por asset (autoral, configurável — não universal):
local BUDGET = { lapide_a = 12, bigorna = 14, varal_vento = 18 }

local function png(id, path)
    local f = assert(io.open(path, 'wb'))
    f:write(id:encode('png'):getString())
    f:close()
end

local function carrega(nome)
    local ok, def = pcall(require, 'src.sprites.' .. nome)
    if not ok then die('require src.sprites.' .. nome .. ' falhou: ' .. tostring(def)) end
    local okb, sheet = pcall(DSL.bake, def)
    if not okb then die('bake ' .. nome .. ' falhou: ' .. tostring(sheet)) end
    return def, sheet
end

-- Extrai o frame 1 de um ImageData de sheet (frames lado a lado).
local function frame1(id, w, h)
    local out = love.image.newImageData(w, h)
    for y = 0, h - 1 do for x = 0, w - 1 do
        out:setPixel(x, y, id:getPixel(x, y))
    end end
    return out
end

local function cola(dst, src, dx, dy, esc)
    for y = 0, src:getHeight() - 1 do for x = 0, src:getWidth() - 1 do
        local r, g, b, a = src:getPixel(x, y)
        for sy = 0, esc - 1 do for sx = 0, esc - 1 do
            dst:setPixel(dx + x * esc + sx, dy + y * esc + sy, r, g, b, a)
        end end
    end end
end

local function relato(out, fmt, ...)
    out[#out + 1] = string.format(fmt, ...)
end

-- Comparação a 1x: frame 1 original | variante, lado a lado nativo —
-- a leitura em 1x é o critério do spec, não o zoom.
local function compara1x(nome, sheetA, sheetB, w, h)
    local id = love.image.newImageData(w * 2 + 2, h)
    local a = frame1(sheetA.imageData.albedo, w, h)
    local b = frame1(sheetB.imageData.albedo, w, h)
    cola(id, a, 0, 0, 1)
    cola(id, b, w + 2, 0, 1)
    png(id, 'screenshots/kit_w2_' .. nome .. '_compara1x.png')
end

-- Revisão W1 da camada editada: contagens de aviso técnico
-- (clusters/steps/gaps/isolados) — avisos, não defeitos automáticos.
local function revisao(out, vdef, camada)
    local alb = vdef.layers[camada].albedo
    if type(alb) == 'table' then alb = alb[1] end
    local r = K.review(MAT.gridOf(alb), vdef.legend)
    relato(out, '  review W1: %d clusters, %d steps, %d gaps, %d isolados',
        #r.clusters, #r.steps, #r.gaps, #r.isolated)
end

local function piloto(out, nome)
    local def, sheet = carrega(nome)
    local base = 'screenshots/kit_w2_' .. nome
    DSL.dump(sheet, base)

    local w, h = sheet.w, sheet.h
    local alb1 = frame1(sheet.imageData.albedo, w, h)
    png(MAT.luminanceImage(alb1), base .. '_luminancia.png')
    png(MAT.silhouetteImage(alb1), base .. '_silhueta.png')

    -- Relatório: cores, budget, redundância, materiais do spec.
    local cc = MAT.colorCount(def)
    local budget = MAT.checkBudget(def, BUDGET[nome])
    relato(out, '== %s (%s) — %dx%d, %d frame(s) ==',
        nome, def.name or '?', w, h, sheet.frames)
    relato(out, 'cores: %d resolvidas / %d chars / %d specs   budget %d: %s',
        cc.colors, cc.chars, cc.specs, budget.max,
        budget.ok and 'OK' or 'ESTOURADO (aviso de revisao)')
    for _, r in ipairs(MAT.redundant(def)) do
        relato(out, '  redundancia: chars "%s"/"%s" mesma cor (h=%s/%s) — %s',
            r.chars[1], r.chars[2], tostring(r.ha), tostring(r.hb), r.reason)
    end
    for nome2, m in pairs(MAT.materialsOf(def)) do
        relato(out, '  material %s (%s): controles=%s | revisar: %s',
            nome2, m.ramp, table.concat(m.controls, ','), m.review)
    end
    for _, s in ipairs(MAT.swatches(def)) do
        relato(out, '  swatch %-2s x%-4d %-12s lum=%.3f',
            s.char, s.count, tostring(s.spec), s.lum)
    end

    return def, sheet, alb1
end

function love.load(args)
    package.path = package.path .. ';./?.lua;./?/init.lua'
    for _, arg in ipairs(args or {}) do
        if arg == '--test' then testOnly = true end
    end
    MAT = require('src.kit_materials')
    K = require('src.pixel_kit')
    DSL = require('src.sprite_dsl')
    Pal = require('src.palettes')
    check()
    if testOnly then love.event.quit(0) return end

    local out = { 'kit_w2 — relatorio de paleta/materiais (megaplan W2)',
        ('gerado por tools/kit_w2 em %s'):format(os.date('%Y-%m-%d %H:%M')), '' }

    -- Prancha 2x: 6 colunas (albedo|luminancia|silhueta|normal|emissive|variante)
    -- x 3 linhas (marco|bigorna|varal_vento). Frame 1 de cada canal.
    local W, H, ESC = 64, 96, 2
    local prancha = love.image.newImageData(6 * W * ESC, 3 * H * ESC)
    local function linha(row, alb, lum, sil, nrm, emi, var)
        local dy = row * H * ESC
        cola(prancha, alb, 0, dy, ESC); cola(prancha, lum, W * ESC, dy, ESC)
        cola(prancha, sil, 2 * W * ESC, dy, ESC)
        cola(prancha, nrm, 3 * W * ESC, dy, ESC)
        cola(prancha, emi, 4 * W * ESC, dy, ESC)
        cola(prancha, var, 5 * W * ESC, dy, ESC)
    end

    -- PILOTO PEDRA: lapide_a — material stone: planes, joints, chips,
    -- contact. A face plana 'a' ganha plano de ombro iluminado, junta
    -- horizontal 'q', lascas nas quinas e relevo por campo de luz.
    local function mat_pedra()
        local def = require('src.sprites.lapide_a')
        local g = MAT.gridOf(def.layers[1].albedo)
        -- Regiões nomeadas (contrato W1): ficam na grade p/ correções
        -- posteriores e alimentam def.regions do workbench.
        K.set_region(g, 'face', MAT.maskChars(g, 'a'))
        K.set_region(g, 'capa', MAT.maskAnd(
            K.sel_rect(g, 24, 46, 17, 3), K.sel_cover(g)))
        K.set_region(g, 'base', K.sel_rect(g, 1, 84, W, 13))
        local face = K.region(g, 'face')
        -- joints: junta gasta horizontal atravessando a face (só em 'a')
        K.line(g, 27, 73, 37, 73, 'q', face)
        -- planes + chips: patch localizado — plano iluminado sob a capa
        -- e lascas nas quinas (canto sup. esq. e base dir.)
        K.patch(g, { pixels = {
            { 26, 49, 'l' }, { 27, 49, 'l' },           -- ombro iluminado
            { 26, 50, 'q' }, { 26, 51, 'q' },           -- lasca canto
            { 37, 80, 'q' }, { 37, 81, 'q' }, { 36, 81, 'q' },
        } }, face)
        -- campos de luz: capa mais alta, fresta/junta afundam, bordas
        -- e base perdem relevo por oclusão de contato
        local hg = MAT.hfield(W, H)
        local pedra = MAT.maskChars(g, 'Sladq')
        MAT.hband(hg, 24, 46, 17, 3, 7, K.region(g, 'capa'))
        MAT.hplane(hg, 3, MAT.maskChars(g, 'q'))   -- frestas afundam
        MAT.applyLightField(g, hg,
            { kind = 'occlusion', drop = 1, dist = 1 }, pedra)
        MAT.applyLightField(g, hg,
            { kind = 'occlusion', drop = 2, dist = 1 }, K.region(g, 'base'))
        return {
            name = 'lapide_a_mat', w = W, h = H, origin = 'feet',
            legend = def.legend,
            regions = {
                face = { x = 25, y = 49, w = 14, h = 35 },
                capa = { x = 24, y = 46, w = 17, h = 3 },
                base = { x = 15, y = 84, w = 40, h = 13 },
            },
            layers = { { name = 'lapide', h = 5, albedo = K.string(g),
                height = K.string(hg) } },
        }
    end
    do
        local def, sheet, alb1 = piloto(out, 'lapide_a')
        local vdef = mat_pedra()
        local vsheet = DSL.bake(vdef)
        DSL.dump(vsheet, 'screenshots/kit_w2_lapide_a_mat')
        compara1x('lapide_a', sheet, vsheet, W, H)
        local cc = MAT.colorCount(vdef)
        revisao(out, vdef, 1)
        relato(out, '  variante lapide_a_mat: planes+joints+chips+contact;')
        relato(out, '    cores %d (antes %d)', cc.colors,
            MAT.colorCount(def).colors)
        relato(out, '')
        linha(0, alb1, MAT.luminanceImage(alb1), MAT.silhouetteImage(alb1),
            frame1(sheet.imageData.normal, W, H),
            frame1(sheet.imageData.emissive, W, H),
            frame1(vsheet.imageData.albedo, W, H))
    end

    -- PILOTO FERRO: bigorna — material iron: narrow_highlights, faces,
    -- worn_edges. Fio de desgaste no bico e no calcanhar, domo na face
    -- (luz estreita) e pé afundando por oclusão de contato.
    local function mat_ferro()
        local def = require('src.sprites.bigorna')
        local g = MAT.gridOf(def.layers[2].albedo) -- camada bigorna
        K.set_region(g, 'ferro', MAT.maskChars(g, 'inIE'))
        local ferro = K.region(g, 'ferro')
        -- worn_edges: ponta do bico e topo do calcanhar gastam para 'E'
        K.patch(g, { pixels = {
            { 5, 33, 'E' }, { 6, 34, 'E' },
            { 48, 33, 'E' }, { 53, 34, 'E' },
        } }, ferro)
        local hg = MAT.hfield(W, H)
        K.set_region(g, 'face', MAT.maskAnd(ferro,
            MAT.maskRect(W, H, 20, 30, 31, 10)))
        K.set_region(g, 'pe', MAT.maskAnd(ferro,
            MAT.maskRect(W, H, 1, 48, W, 11)))
        -- faces: domo na face (luz estreita, não plástica)
        MAT.applyLightField(g, hg, { kind = 'volume',
            cx = 35, cy = 34, rx = 15, ry = 5, base = 11, peak = 15 },
            K.region(g, 'face'))
        -- contact: borda do pé afunda junto ao cepo
        MAT.applyLightField(g, hg, { kind = 'occlusion', drop = 2 },
            K.region(g, 'pe'))
        return {
            name = 'bigorna_mat', w = W, h = H, origin = 'feet',
            legend = def.legend,
            regions = {
                face = { x = 20, y = 30, w = 31, h = 10 },
                pe = { x = 22, y = 48, w = 24, h = 11 },
            },
            layers = {
                def.layers[1], -- cepo intacto
                { name = 'bigorna', h = 11, albedo = K.string(g),
                    height = K.string(hg), emissive = def.layers[2].emissive },
                def.layers[3], -- chão intacto
            },
        }
    end
    do
        local def, sheet, alb1 = piloto(out, 'bigorna')
        local vdef = mat_ferro()
        local vsheet = DSL.bake(vdef)
        DSL.dump(vsheet, 'screenshots/kit_w2_bigorna_mat')
        compara1x('bigorna', sheet, vsheet, W, H)
        revisao(out, vdef, 2)
        relato(out, '  variante bigorna_mat: worn_edges+domo+contato')
        relato(out, '')
        linha(1, alb1, MAT.luminanceImage(alb1), MAT.silhouetteImage(alb1),
            frame1(sheet.imageData.normal, W, H),
            frame1(sheet.imageData.emissive, W, H),
            frame1(vsheet.imageData.albedo, W, H))
    end

    -- PILOTO TECIDO: varal_vento — material cloth: tension, major_folds,
    -- hems. As dobras 'c' soltas (listras sem pose — a preocupação do
    -- spec) viram dobras estruturais descendo dos prendedores + barra
    -- em sombra. Mesma edição nos 4 frames do loop de vento.
    local function mat_tecido()
        local def = require('src.sprites.varal_vento')
        local function dobras(src)
            local g = MAT.gridOf(src)
            -- regiões das três peças (contrato W1): chars ∩ retângulo
            K.set_region(g, 'camisa', MAT.maskAnd(MAT.maskChars(g, 'jc'),
                MAT.maskRect(W, H, 15, 40, 19, 24)))
            K.set_region(g, 'pano', MAT.maskAnd(MAT.maskChars(g, 'a'),
                MAT.maskRect(W, H, 30, 44, 13, 16)))
            K.set_region(g, 'reboco', MAT.maskAnd(MAT.maskChars(g, 'pd'),
                MAT.maskRect(W, H, 42, 42, 8, 14)))
            local camisa, pano, reboco = K.region(g, 'camisa'),
                K.region(g, 'pano'), K.region(g, 'reboco')
            -- camisa jade: limpa salpico de 'c' e redesenha dobras dos
            -- pinos (cols 19-20 e 29) descendo pela peça
            K.paint(g, function(_, _, c) return c == 'c' and 'j' or nil end,
                camisa)
            K.line(g, 20, 42, 23, 60, 'c', camisa)
            K.line(g, 29, 42, 26, 60, 'c', camisa)
            -- pano quente: idem, sombra 'x' (clothWarm.2, char novo)
            K.line(g, 33, 45, 36, 57, 'x', pano)
            -- reboco: dobra central + barra
            K.line(g, 45, 43, 44, 53, 'd', reboco)
            -- hems: último pixel de pano de cada coluna vira sombra
            local hch = { j = 'c', c = 'c', a = 'x', p = 'd' }
            for x = 15, 50 do
                for y = 62, 40, -1 do
                    local c = K.get(g, x, y)
                    if c ~= '.' then
                        if hch[c] then g.rows[y][x] = hch[c] end
                        break
                    end
                end
            end
            return K.string(g)
        end
        local legend = {}
        for ch, e in pairs(def.legend) do legend[ch] = e end
        legend.x = { ramp = 'clothWarm', step = 2, h = 6 } -- sombra do pano
        local frames = {}
        for f = 1, #def.layers[2].albedo do
            frames[f] = dobras(def.layers[2].albedo[f])
        end
        return {
            name = 'varal_vento_mat', w = W, h = H, origin = 'feet',
            legend = legend,
            regions = {
                camisa = { x = 15, y = 40, w = 19, h = 24 },
                pano = { x = 30, y = 44, w = 13, h = 16 },
                reboco = { x = 42, y = 42, w = 8, h = 14 },
            },
            layers = { def.layers[1],
                { name = 'roupas', h = 6, albedo = frames } },
        }
    end
    do
        local def, sheet, alb1 = piloto(out, 'varal_vento')
        local vdef = mat_tecido()
        local vsheet = DSL.bake(vdef)
        DSL.dump(vsheet, 'screenshots/kit_w2_varal_vento_mat')
        compara1x('varal_vento', sheet, vsheet, W, H)
        -- remap regional do material revisado: mercado (tecido/wood ocre)
        local rdef = MAT.remapDef(vdef, 'mercado')
        DSL.dump(DSL.bake(rdef), 'screenshots/kit_w2_varal_vento_mat_mercado')
        revisao(out, vdef, 2)
        relato(out, '  variante varal_vento_mat: tension+folds+hems (+char x);')
        relato(out, '    + remap regional mercado (kit_w2_varal_vento_mat_mercado_*)')
        linha(2, alb1, MAT.luminanceImage(alb1), MAT.silhouetteImage(alb1),
            frame1(sheet.imageData.normal, W, H),
            frame1(sheet.imageData.emissive, W, H),
            frame1(vsheet.imageData.albedo, W, H))
    end

    png(prancha, 'screenshots/kit_w2_prancha.png')
    local f = assert(io.open('screenshots/kit_w2_relatorio.txt', 'w'))
    f:write(table.concat(out, '\n') .. '\n')
    f:close()
    print(('kit_w2: pilotos ok — dumps + prancha + relatorio em screenshots/'))
    love.event.quit(0)
end
