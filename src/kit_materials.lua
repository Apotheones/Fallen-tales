-- kit_materials — W2 do docs/MEGAPLAN_KIT_PROCEDURAL_IA.md §7: paleta,
-- materiais e canais de luz para autoria de sprites DSL.
--
-- Três frentes, todas operando sobre os contratos existentes:
--
-- 1) PALETA: resolução de rampa por região, remapeamento de legend,
--    swatches, contagem de cores, avisos de redundância, vistas de
--    luminância/silhueta e budget de cor por asset. Tudo em cima de
--    src/palettes.lua (resolve) — este módulo não redefine cor nenhuma.
--
-- 2) CAMPOS DE LUZ EDITÁVEIS: espec de dados + aplicação sobre grades
--    de altura (chars '0'-'9','a'-'f' do DSL) e emissivo, recortados
--    por máscaras do pixel_kit. Um campo é uma tabela:
--      {kind='plane',    v=N}                       nível constante
--      {kind='band',     x,y,w,h, v=N}              faixa retangular
--      {kind='grad',     axis='x'|'y', v0,v1, steps} gradiente quantizado
--      {kind='volume',   cx,cy,rx,ry, base,peak}    domo elíptico
--      {kind='occlusion', drop=N, dist=D}           AO de contato/borda
--    M.applyLightField(albedo, hg, campo, mask) despacha por kind.
--    O relevo descreve FORMA, não cada mudança de cor (aceite W2).
--
-- 3) MATERIAIS: M.materials traz a tabela de controles do spec
--    (pedra/ferro/madeira/tecido/pele/cabelo/folhagem/vidro/agua/fogo)
--    como API de authoring: rampa mestra, parâmetros editáveis e a
--    principal preocupação de revisão de cada material.
--
-- Regiões nomeadas do W1 ainda não existem: "região" aqui é máscara do
-- pixel_kit (qualquer char ~= '.' permite). Quando o contrato de
-- máscara/região do W1 for publicado, estas funções passam a recebê-lo
-- como o mesmo argumento `mask`.
--
-- Não depende de love nas operações de grade; luminanceImage e
-- silhouetteImage pedem love.image (ImageData) e rodam só em ferramentas.

local K = require('src.pixel_kit')
local Pal = require('src.palettes')

local M = {}
local floor, sqrt, char = math.floor, math.sqrt, string.char

local function fail(fmt, ...)
    error('kit_materials: ' .. string.format(fmt, ...), 2)
end

--------------------------------------------------------------------------------
-- Paleta: luminância, rampas e resolução por região
--------------------------------------------------------------------------------

-- Rec.601: suficiente para ordenar swatches e comparar degraus.
function M.luminance(c)
    return 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]
end

-- Rampa mestra -> lista de cores {r,g,b} na ordem sombra->luz.
function M.ramp(name)
    local steps = Pal.ramps[name]
    if not steps then
        fail("rampa '%s' inexistente", tostring(name))
    end
    local out = {}
    for i = 1, #steps do out[i] = Pal.index[steps[i]] end
    return out
end

-- Rampa mestra -> família de material da tabela Palettes.regions.
-- Só materiais que as regiões realmente redefinem têm família; os
-- demais (iron, ember, skin...) continuam na rampa mestra — a região
-- muda o ambiente, não o ferro.
local FAMILIA = {
    wood = 'wood', cloth = 'cloth', clothWarm = 'cloth',
    moss = 'moss', earth = 'floor', stone = 'wall', plaster = 'wall',
}

-- Ordem sombra->luz dentro de cada família regional.
local FAMILIA_ORDEM = {
    floor = { 'shadow', 'dark', 'base', 'light' },
    wood = { 'dark', 'base', 'light' },
    cloth = { 'dark', 'base', 'light' },
    wall = { 'mortar', 'faceDark', 'face', 'brick', 'brickAlt', 'cap', 'rim' },
}

-- Resolve 'rampa.degrau' no tom da família regional. A posição do
-- degrau dentro da rampa mestra é preservada proporcionalmente: a
-- sombra continua sombra, a luz continua luz — o que muda é a tinta.
-- Sem família regional, devolve a cor da rampa mestra (sem remap).
function M.regionStep(region, rampName, step)
    local cor = Pal.resolve(rampName .. '.' .. step) -- valida degrau
    local fam = FAMILIA[rampName]
    local R = region and Pal.regions[region]
    if not fam or not R or not R[fam] then return cor end
    if type(R[fam][1]) == 'number' then
        return R[fam] -- família de tom único (moss, petal): todos os degraus
    end
    local t = {}
    for _, key in ipairs(FAMILIA_ORDEM[fam] or { fam }) do
        if R[fam][key] then t[#t + 1] = R[fam][key] end
    end
    if #t == 0 then return cor end
    local n = #Pal.ramps[rampName]
    local i = n <= 1 and 1 or floor(1 + (step - 1) / (n - 1) * (#t - 1) + 0.5)
    return t[i]
end

-- 'rampa.degrau' -> cor regional; nome funcional passa intacto (cor
-- protegida — telegraph e runa não seguem grading regional).
function M.remapSpec(spec, region)
    if type(spec) ~= 'string' then return spec end
    local name, step = spec:match('^([%a_][%w_]*)%.(%d+)$')
    if not name then return spec end
    return M.regionStep(region, name, tonumber(step))
end

local function specDe(e)
    if type(e) == 'string' then return e end
    if type(e) == 'table' and not e.spec and e.ramp then
        return tostring(e.ramp) .. '.' .. tostring(e.step or 1)
    end
    return e and e.spec or nil
end

-- Legend nova com specs de rampa trocadas pela cor regional {r,g,b}.
-- Retorna tabela nova (a original fica intacta p/ bake comparável).
function M.remapLegend(legend, region)
    local out = {}
    for ch, e in pairs(legend) do
        if type(e) == 'string' then
            out[ch] = M.remapSpec(e, region)
        else
            local n = { spec = e.spec, h = e.h, e = e.e, ei = e.ei }
            if not n.spec and e.ramp then
                n.spec = e.ramp .. '.' .. (e.step or 1)
            end
            n.spec = M.remapSpec(n.spec, region)
            n.e = M.remapSpec(n.e, region)
            out[ch] = n
        end
    end
    return out
end

-- Def nova (cache de bake é por identidade — def nova = bake novo) com
-- a legend remapeada para a região. Consumo: variantes de revisão.
function M.remapDef(def, region)
    local out = {}
    for k, v in pairs(def) do out[k] = v end
    out.name = (def.name or 'def') .. '@' .. tostring(region)
    out.legend = M.remapLegend(def.legend, region)
    return out
end

--------------------------------------------------------------------------------
-- Inventário: swatches, contagem, redundância, budget
--------------------------------------------------------------------------------

local function corDe(spec, resolve)
    if type(spec) == 'table' then return spec end
    return resolve(spec)
end

-- fn(char) para cada pixel de albedo de todas as camadas/frames.
local function cadaPixel(def, fn)
    for li, layer in ipairs(def.layers or {}) do
        local alb = layer.albedo
        local frames = type(alb) == 'table' and alb or { alb }
        for fi, g in ipairs(frames) do
            assert(type(g) == 'string',
                ('camada %s frame %d: albedo deve ser string'):format(
                    layer.name or li, fi))
            for c in g:gmatch('[^\n\r]') do
                if c ~= '.' and c ~= ' ' then fn(c) end
            end
        end
    end
end

-- Lista de swatches por char usado: {char, count, spec, color, lum},
-- ordenada por contagem desc. resolve opcional p/ testes.
function M.swatches(def, resolve)
    resolve = resolve or Pal.resolve
    local uso = {}
    cadaPixel(def, function(c) uso[c] = (uso[c] or 0) + 1 end)
    local out = {}
    for ch, n in pairs(uso) do
        local spec = specDe(def.legend[ch])
        local cor = spec and corDe(spec, resolve) or nil
        out[#out + 1] = {
            char = ch, count = n, spec = spec, color = cor,
            lum = cor and M.luminance(cor) or 0,
        }
    end
    table.sort(out, function(a, b) return a.count > b.count end)
    return out
end

-- Contagem: chars usados, specs distintas e cores resolvidas distintas
-- (duas specs podem cair na mesma cor — o budget é sobre cor final).
function M.colorCount(def, resolve)
    resolve = resolve or Pal.resolve
    local chars, specs, cores = {}, {}, {}
    for _, s in ipairs(M.swatches(def, resolve)) do
        chars[s.char] = true
        if s.spec then specs[tostring(s.spec)] = true end
        if s.color then
            cores[('%0.3f,%0.3f,%0.3f')
                :format(s.color[1], s.color[2], s.color[3])] = true
        end
    end
    local function n(t) local k = 0 for _ in pairs(t) do k = k + 1 end return k end
    return { chars = n(chars), specs = n(specs), colors = n(cores) }
end

-- Avisos de redundância: chars diferentes que resolvem na MESMA cor
-- (eps em distância euclidiana; default ~1/255 — quase exato). Se os
-- chars têm h/e diferentes a redundância pode ser intencional: o aviso
-- carrega os campos p/ quem revisa decidir.
function M.redundant(def, eps, resolve)
    eps = eps == nil and 0.002 or eps
    local sw = M.swatches(def, resolve)
    local out = {}
    for i = 1, #sw do
        for j = i + 1, #sw do
            local a, b = sw[i], sw[j]
            if a.color and b.color then
                local d = sqrt((a.color[1] - b.color[1]) ^ 2 +
                    (a.color[2] - b.color[2]) ^ 2 + (a.color[3] - b.color[3]) ^ 2)
                if d <= eps then
                    local ea, eb = def.legend[a.char], def.legend[b.char]
                    out[#out + 1] = {
                        chars = { a.char, b.char },
                        color = a.color, delta = d,
                        ha = type(ea) == 'table' and ea.h or nil,
                        hb = type(eb) == 'table' and eb.h or nil,
                        reason = ('chars resolvem na mesma cor (delta=%.4f)')
                            :format(d),
                    }
                end
            end
        end
    end
    return out
end

-- Budget de cor por asset: número máximo de cores resolvidas.
-- Estourar é AVISO de revisão, não erro duro — a decisão é do autor.
-- Retorna {colors, max, ok, swatches} p/ o relatório apontar o excesso.
function M.checkBudget(def, max, resolve)
    assert(type(max) == 'number' and max > 0, 'budget deve ser inteiro > 0')
    local sw = M.swatches(def, resolve)
    local seen, colors = {}, 0
    for _, s in ipairs(sw) do
        if s.color then
            local k = ('%0.3f,%0.3f,%0.3f')
                :format(s.color[1], s.color[2], s.color[3])
            if not seen[k] then seen[k] = true colors = colors + 1 end
        end
    end
    return { colors = colors, max = max, ok = colors <= max, swatches = sw }
end

--------------------------------------------------------------------------------
-- Campos de luz editáveis (canal de altura + emissivo)
--------------------------------------------------------------------------------

-- 0..15 -> char de altura do DSL; clampa com aviso implícito do spec.
local function hch(v)
    v = floor(v + 0.5)
    if v < 0 then v = 0 elseif v > 15 then v = 15 end
    return char(v < 10 and 48 + v or 87 + v)
end
M.hchar = hch

local function hval(c)
    local b = c and c:byte() or 0
    if b >= 48 and b <= 57 then return b - 48 end
    if b >= 97 and b <= 102 then return b - 87 end
    return 0
end

local function perm(mask, x, y)
    return not mask or K.get(mask, x, y) ~= '.'
end

local function bbox(mask, w, h)
    if not mask then return 1, 1, w, h end
    local x0, y0, x1, y1 = w, h, 1, 1
    local vazio = true
    for y = 1, h do for x = 1, w do
        if K.get(mask, x, y) ~= '.' then
            vazio = false
            if x < x0 then x0 = x end if x > x1 then x1 = x end
            if y < y0 then y0 = y end if y > y1 then y1 = y end
        end
    end end
    if vazio then return nil end
    return x0, y0, x1, y1
end

function M.hfield(w, h) return K.new(w, h) end

function M.hplane(hg, v, mask)
    for y = 1, hg.h do for x = 1, hg.w do
        if perm(mask, x, y) then hg.rows[y][x] = hch(v) end
    end end
    return hg
end

function M.hband(hg, x, y, w, h, v, mask)
    return K.rect(hg, x, y, w, h, hch(v), mask)
end

-- Gradiente quantizado: `steps` níveis discretos de v0 a v1 varrendo o
-- bbox da máscara no eixo dado — faixas de luz, não rampa suave.
function M.hgrad(hg, axis, v0, v1, steps, mask)
    assert(axis == 'x' or axis == 'y', "hgrad: axis deve ser 'x' ou 'y'")
    steps = math.max(1, floor(steps or 2))
    local x0, y0, x1, y1 = bbox(mask, hg.w, hg.h)
    if not x0 then return hg end
    local span = axis == 'x' and math.max(1, x1 - x0) or math.max(1, y1 - y0)
    for y = y0, y1 do for x = x0, x1 do
        if perm(mask, x, y) then
            local t = axis == 'x' and (x - x0) / span or (y - y0) / span
            local q = steps <= 1 and 0
                or floor(t * steps + 1e-9) / (steps - 1)
            if q > 1 then q = 1 end
            hg.rows[y][x] = hch(v0 + (v1 - v0) * q)
        end
    end end
    return hg
end

-- Domo elíptico aproximado: peak no centro, base na borda. Relevo de
-- pança de tigela, bossa de escudo, volume de tecido estufado.
function M.hvolume(hg, cx, cy, rx, ry, base, peak, mask)
    assert(rx > 0 and ry > 0, 'hvolume: raios positivos')
    for y = math.max(1, floor(cy - ry)), math.min(hg.h, floor(cy + ry + 1)) do
        for x = math.max(1, floor(cx - rx)), math.min(hg.w, floor(cx + rx + 1)) do
            if perm(mask, x, y) then
                local d = sqrt(((x - cx) / rx) ^ 2 + ((y - cy) / ry) ^ 2)
                if d <= 1 then
                    hg.rows[y][x] = hch(base + (peak - base) * (1 - d))
                end
            end
        end
    end
    return hg
end

-- Oclusão de contato: pixels de albedo opacos a até `dist` anéis de um
-- vizinho transparente perdem `drop` de altura — a borda encosta no chão.
function M.hocclusion(albedo, hg, drop, dist, mask)
    drop = drop or 2 dist = dist or 1
    local alvo = {}
    for y = 1, albedo.h do for x = 1, albedo.w do
        if K.get(albedo, x, y) ~= '.' then
            local perto = false
            for d = 1, dist do
                for _, o in ipairs({ { d, 0 }, { -d, 0 }, { 0, d }, { 0, -d } }) do
                    if K.get(albedo, x + o[1], y + o[2]) == '.' then perto = true end
                end
            end
            if perto and perm(mask, x, y) then alvo[(y - 1) * albedo.w + x] = true end
        end
    end end
    for idx in pairs(alvo) do
        local x = (idx - 1) % albedo.w + 1
        local y = floor((idx - 1) / albedo.w) + 1
        hg.rows[y][x] = hch(hval(hg.rows[y][x]) - drop)
    end
    return hg
end

-- Emissivo por região: estampa char da legend onde a máscara permite.
-- O char define cor e intensidade (.e/.ei) — emissão é escolha autoral.
function M.emitRegion(eg, ch, mask)
    for y = 1, eg.h do for x = 1, eg.w do
        if perm(mask, x, y) then eg.rows[y][x] = ch end
    end end
    return eg
end

-- Despacha a espec do campo para o helper correspondente.
function M.applyLightField(albedo, hg, campo, mask)
    local k = campo.kind
    if k == 'plane' then return M.hplane(hg, campo.v, mask) end
    if k == 'band' then
        return M.hband(hg, campo.x, campo.y, campo.w, campo.h, campo.v, mask)
    end
    if k == 'grad' then
        return M.hgrad(hg, campo.axis, campo.v0, campo.v1, campo.steps, mask)
    end
    if k == 'volume' then
        return M.hvolume(hg, campo.cx, campo.cy, campo.rx, campo.ry,
            campo.base, campo.peak, mask)
    end
    if k == 'occlusion' then
        return M.hocclusion(albedo, hg, campo.drop, campo.dist, mask)
    end
    fail("campo de luz kind='%s' desconhecido", tostring(k))
end

-- Dither localizado OPT-IN (desligado por padrão no spec): estampa `ch`
-- em pixels alternados dentro da máscara, paridade reversível.
function M.dither(g, ch, mask, par)
    par = par or 0
    for y = 1, g.h do for x = 1, g.w do
        if (x + y) % 2 == par and perm(mask, x, y) then g.rows[y][x] = ch end
    end end
    return g
end

--------------------------------------------------------------------------------
-- Máscaras/regiões — delegam aos contratos W1 do pixel_kit (sel_*,
-- mask_*, set_region/region, parse). Máscara é grade com 'x'/'#' e '.';
-- qualquer char ~= '.' permite — helpers de campo aceitam as duas formas.
--------------------------------------------------------------------------------

-- Máscara onde o albedo usa um dos chars dados — seleção por material
-- para correção local sem tocar área protegida (união de sel_color).
function M.maskChars(albedo, chars)
    local m
    for c in chars:gmatch('.') do
        local s = K.sel_color(albedo, c)
        m = m and K.mask_or(m, s) or s
    end
    return m or K.new(albedo.w, albedo.h)
end

-- Interseção de máscaras (contrato W1 mask_and, grade nova).
function M.maskAnd(a, b) return K.mask_and(a, b) end

function M.maskRect(w, h, x, y, rw, rh)
    return K.sel_rect(K.new(w, h), x, y, rw, rh)
end

-- String [[...]] -> grade pixel_kit (contrato W1 parse; espaço vira
-- '.'). w/h opcionais só validam o resultado contra a def de origem.
function M.gridOf(src, w, h)
    local g = K.parse(src)
    if w and (g.w ~= w or g.h ~= h) then
        fail('gridOf: grade %dx%d difere da def (%dx%d)', g.w, g.h, w, h)
    end
    return g
end

--------------------------------------------------------------------------------
-- Vistas de revisão sobre ImageData de bake (precisa de love.image)
--------------------------------------------------------------------------------

local function novaImageData(w, h)
    assert(love and love.image, 'kit_materials: vistas pedem love.image')
    return love.image.newImageData(w, h)
end

-- Albedo -> luminância em cinza (alpha preservado): leitura de valor.
function M.luminanceImage(id)
    local w, h = id:getDimensions()
    local out = novaImageData(w, h)
    for y = 0, h - 1 do for x = 0, w - 1 do
        local r, g, b, a = id:getPixel(x, y)
        if a > 0 then
            local v = M.luminance({ r, g, b })
            out:setPixel(x, y, v, v, v, a)
        else
            out:setPixel(x, y, 0, 0, 0, 0)
        end
    end end
    return out
end

-- Albedo -> silhueta chapada: leitura de contorno sem ruído de valor.
-- Default escuro (tinta): visível em fundo claro e no xadrez do editor.
function M.silhouetteImage(id, cor)
    cor = cor or { .05, .06, .09 }
    local w, h = id:getDimensions()
    local out = novaImageData(w, h)
    for y = 0, h - 1 do for x = 0, w - 1 do
        local _, _, _, a = id:getPixel(x, y)
        if a > 0 then out:setPixel(x, y, cor[1], cor[2], cor[3], a) end
    end end
    return out
end

--------------------------------------------------------------------------------
-- Tabela de materiais do spec (megaplan §7) como API de authoring
--------------------------------------------------------------------------------

-- Cada entrada: rampa mestra do material, os controles que uma receita
-- expõe para aquele material e a preocupação principal de revisão.
-- 'metal' usa a rampa 'iron' (o nome do controle do spec é genérico).
M.materials = {
    stone = { ramp = 'stone', nome = 'pedra',
        controls = { 'planes', 'joints', 'chips', 'contact' },
        review = 'salpico uniforme ou relevo inflado' },
    iron = { ramp = 'iron', nome = 'ferro/metal',
        controls = { 'narrow_highlights', 'faces', 'worn_edges' },
        review = 'aparencia plastica ou brilho excessivo' },
    wood = { ramp = 'wood', nome = 'madeira',
        controls = { 'grain_flow', 'cut_surfaces', 'cracks' },
        review = 'textura sem direcao' },
    cloth = { ramp = 'cloth', nome = 'tecido',
        controls = { 'tension', 'major_folds', 'hems' },
        review = 'listras sem relacao com a pose' },
    skin = { ramp = 'skin', nome = 'pele/rosto',
        controls = { 'broad_planes', 'eyes', 'expression' },
        review = 'detalhe destruindo a leitura em 1x' },
    hair = { ramp = 'hair', nome = 'cabelo',
        controls = { 'masses', 'grouped_strands' },
        review = 'fios soltos de um pixel' },
    foliage = { ramp = 'moss', nome = 'folhagem',
        controls = { 'branches', 'leaf_clusters', 'gaps' },
        review = 'confete ou massa unica sem diferenciacao' },
    glass = { ramp = nil, nome = 'vidro',
        controls = { 'frame', 'suggested_transparency', 'reflections' },
        review = 'corpo opaco ou brilho sem apoio' },
    water = { ramp = 'sea', nome = 'agua',
        controls = { 'flow', 'banks', 'reflections', 'cycles' },
        review = 'textura a deriva incoerente' },
    fire = { ramp = 'ember', nome = 'fogo/fumaca',
        controls = { 'changing_silhouette', 'core', 'dissipation' },
        review = 'loop mecanico escondido pelo bloom' },
}
M.materials.metal = M.materials.iron -- alias do nome genérico do spec

function M.material(name)
    local m = M.materials[name]
    if not m then fail("material '%s' desconhecido", tostring(name)) end
    return m
end

-- Materiais presentes na legend de uma def (pela rampa do spec) —
-- consumo: o relatório do piloto lista controles e revisão por material.
function M.materialsOf(def)
    local ramps, out = {}, {}
    for _, e in pairs(def.legend or {}) do
        local spec = specDe(e)
        local ramp = type(spec) == 'string' and spec:match('^([%a_][%w_]*)%.') or nil
        if ramp == 'jade' then ramp = 'cloth' end -- jade é alias de cloth
        if ramp then ramps[ramp] = true end
    end
    for nome, m in pairs(M.materials) do
        if nome ~= 'metal' and m.ramp and ramps[m.ramp] then out[nome] = m end
    end
    return out
end

return M
