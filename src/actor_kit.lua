-- actor_kit (W4) — partes, poses e animacao de atores sobre o pixel_kit.
-- Lua puro, sem love: opera em grades 1-based e metadados de def do
-- sprite_dsl. A geracao de rascunho por rig e local (move/patch); frames
-- finais pedem correcao manual de silhueta/cluster — nada de interpolacao
-- automatica como produto final.
--
-- Metadados emitidos na def (contrato lido pelo workbench W3/kit_w4):
--   def.anchors  = { nome = {x,y} | {{x,y},...} }   -- por frame ou estatica
--   def.markers  = { nome = {f1,f2,...} }           -- prep/contact/react/
--                                                  -- recover/return
--   def.sequences= { nome = {first,last[,loop=bool]} }
--   def.frameDuration = segundos, escalar ou array por frame
--   def.regions  = { nome = {x=,y=,w=,h=} }  (caixas — workbench ja le)
--   def.masks    = { nome = grade-mascara }  (sobreposicao — idem)
--
-- Consumidores concretos: tools/kit_w4 (checks/emit/playback), o piloto
-- viajante_tiro_* e viajante_interacao em src/sprites/, e o workbench.

local K = require('src.pixel_kit')

local M = {}
local floor, abs = math.floor, math.abs

local function integer(n)
    assert(type(n) == 'number' and n == floor(n) and abs(n) < math.huge,
        'actor_kit: coordenada deve ser inteira finita')
    return n
end

--------------------------------------------------------------------------------
-- Grids por frame a partir de uma def
--------------------------------------------------------------------------------

-- Canal de uma camada no frame f (string replica para todos; array = 1 por
-- frame). Devolve nil se o canal nao existe na camada.
local function layerChannel(layer, channel, f)
    local v = layer[channel]
    if v == nil then return nil end
    if type(v) == 'string' then return v end
    return v[f]
end

-- Quantos frames a def declara (maior array de canal entre camadas).
function M.frame_count(def)
    local n = 1
    for _, l in ipairs(def.layers or {}) do
        for _, ch in ipairs({ 'albedo', 'height', 'emissive' }) do
            if type(l[ch]) == 'table' then n = math.max(n, #l[ch]) end
        end
    end
    return n
end

-- Grade composta do canal no frame f: camadas empilhadas na ordem da def
-- (a ultima escreve por cima; '.' na origem nao apaga — mesmo contrato do
-- bake). channel: 'albedo' | 'height' | 'emissive'. Sem o canal -> nil.
function M.compose(def, channel, frame)
    local g, found
    for _, l in ipairs(def.layers or {}) do
        local src = layerChannel(l, channel, frame)
        if src then
            g = g or K.new(def.w, def.h)
            found = true
            K.blit(g, K.parse(src), 0, 0)
        end
    end
    return found and g or nil
end

-- Lista de grades compostas por frame: M.frames(def, 'albedo') -> {g1..gN}.
function M.frames(def, channel)
    local out = {}
    local n = M.frame_count(def)
    for f = 1, n do out[f] = M.compose(def, channel, f) end
    return out
end

-- Camada de animacao: arrays de grades viram arrays de strings da def.
-- M.layer('tiro', {g1,g2,g3}, {emissive = {e1,...}, height = {...}})
function M.layer(name, grids, extra)
    assert(#grids > 0, 'actor_kit: layer sem frames')
    local lay = { name = name, albedo = {} }
    for i, g in ipairs(grids) do lay.albedo[i] = K.string(g) end
    for _, ch in ipairs({ 'height', 'emissive' }) do
        local arr = extra and extra[ch]
        if arr then
            assert(#arr == #grids, 'actor_kit: canal ' .. ch ..
                ' com frames divergentes')
            lay[ch] = {}
            for i, g in ipairs(arr) do lay[ch][i] = K.string(g) end
        end
    end
    return lay
end

--------------------------------------------------------------------------------
-- Partes nomeadas e rig de rascunho
--------------------------------------------------------------------------------

-- Bandas de proporcao: t = { nome = {y1, y2} } em linhas da grade.
-- Grava cada banda como regiao (mask) na grade e devolve medidas
-- { nome = { y1,y2, pixels } } — guia de proporcao para revisao.
function M.bands(g, t)
    local out = {}
    for nome, r in pairs(t) do
        integer(r[1]); integer(r[2])
        assert(r[1] <= r[2], 'actor_kit: banda ' .. nome .. ' invertida')
        local mask = K.sel_rect(g, 1, r[1], g.w, r[2] - r[1] + 1)
        K.set_region(g, nome, mask)
        out[nome] = { y1 = r[1], y2 = r[2],
            pixels = K.inspect(K.mask_and(mask, K.sel_cover(g))).pixels }
    end
    return out
end

-- Caixa envolvente do conteudo nao-vazio: {x,y,w,h,pixels} ou nil vazio.
function M.bbox(g)
    local x1, y1, x2, y2, n = g.w, g.h, 0, 0, 0
    for y = 1, g.h do for x = 1, g.w do
        if g.rows[y][x] ~= '.' then
            if x < x1 then x1 = x end
            if x > x2 then x2 = x end
            if y < y1 then y1 = y end
            if y > y2 then y2 = y end
            n = n + 1
        end
    end end
    if n == 0 then return nil end
    return { x = x1, y = y1, w = x2 - x1 + 1, h = y2 - y1 + 1, pixels = n }
end

-- Rig de rascunho: move os pixels sob a mascara por (dx,dy) com clipping;
-- o resto da grade nao muda. Gera pose inicial — a forma movida deixa
-- buraco (sem autocompletar): a correcao de silhueta fica a cargo da
-- etapa seguinte da receita.
function M.move(g, mask, dx, dy)
    integer(dx); integer(dy)
    assert(mask.w == g.w and mask.h == g.h, 'actor_kit: mascara de move diverge')
    local moved = {}
    for y = 1, g.h do for x = 1, g.w do
        if mask.rows[y][x] ~= '.' and g.rows[y][x] ~= '.' then
            moved[#moved + 1] = { x, y, g.rows[y][x] }
        end
    end end
    for _, p in ipairs(moved) do g.rows[p[2]][p[1]] = '.' end
    for _, p in ipairs(moved) do
        K.pixel(g, p[1] + dx, p[2] + dy, p[3])
    end
    return g
end

--------------------------------------------------------------------------------
-- Metadados de animacao (emissao na def)
--------------------------------------------------------------------------------

-- Valida/normaliza os blocos de metadados W4 sobre uma def com N frames.
-- Devolve {anchors, markers, sequences, frameDuration} prontos p/ a def;
-- erros de forma sao falha de autoria (nao aviso).
function M.meta(def, t)
    local n = M.frame_count(def)
    local out = {}
    if t.anchors then
        out.anchors = {}
        for name, a in pairs(t.anchors) do
            if type(a[1]) == 'number' then
                integer(a[1]); integer(a[2])
                out.anchors[name] = { a[1], a[2] }
            else
                assert(#a == n, 'actor_kit: ancora ' .. name ..
                    ' tem ' .. #a .. ' posicoes para ' .. n .. ' frames')
                for _, p in ipairs(a) do integer(p[1]); integer(p[2]) end
                out.anchors[name] = a
            end
        end
    end
    if t.markers then
        out.markers = {}
        for name, fs in pairs(t.markers) do
            assert(type(fs) == 'table' and #fs > 0,
                'actor_kit: marker ' .. name .. ' sem frames')
            for _, f in ipairs(fs) do
                integer(f)
                assert(f >= 1 and f <= n, 'actor_kit: marker ' .. name ..
                    ' fora de 1..' .. n)
            end
            out.markers[name] = fs
        end
    end
    if t.sequences then
        out.sequences = {}
        for name, s in pairs(t.sequences) do
            integer(s[1]); integer(s[2])
            assert(s[1] >= 1 and s[2] >= s[1] and s[2] <= n,
                'actor_kit: sequencia ' .. name .. ' fora de 1..' .. n)
            out.sequences[name] = s
        end
    end
    if t.frameDuration then
        local d = t.frameDuration
        if type(d) == 'number' then
            assert(d > 0, 'actor_kit: frameDuration deve ser positiva')
        else
            assert(#d == n, 'actor_kit: frameDuration com ' .. #d ..
                ' entradas para ' .. n .. ' frames')
            for _, v in ipairs(d) do assert(v > 0, 'frameDuration <= 0') end
        end
        out.frameDuration = d
    end
    out.regions = t.regions
    out.masks = t.masks
    return out
end

--------------------------------------------------------------------------------
-- Diagnosticos (revisao tecnica com coordenadas — avisos, nao erros de arte)
--------------------------------------------------------------------------------

local function warn(list, frame, reason, x, y, region)
    list[#list + 1] = { severity = 'WARN', frame = frame, reason = reason,
        x = x, y = y, region = region }
end
local function err(list, reason)
    list[#list + 1] = { severity = 'ERROR', reason = reason }
end

-- Linha dos pes: menor e maior y ocupado por coluna e bbox do frame.
local function footline(g)
    local ys, xs = {}, {}
    for x = 1, g.w do
        for y = g.h, 1, -1 do
            if g.rows[y][x] ~= '.' then ys[#ys + 1] = y; xs[#xs + 1] = x break end
        end
    end
    if #ys == 0 then return nil end
    local ymin, ymax = math.huge, 0
    for _, y in ipairs(ys) do
        if y < ymin then ymin = y end
        if y > ymax then ymax = y end
    end
    return { xmin = xs[1], xmax = xs[#xs], ymin = ymin, ymax = ymax }
end

local function changed(a, b)
    local n = 0
    for y = 1, a.h do for x = 1, a.w do
        if a.rows[y][x] ~= b.rows[y][x] then n = n + 1 end
    end end
    return n
end

-- M.check(def) -> { frames=N, warnings={...} }. Diagnostico de ator:
-- foot drift, salto de silhueta, parte faltando, flicker de textura,
-- canal flutuante, descontinuidade de loop, metadados inconsistentes.
function M.check(def)
    local out = { warnings = {} }
    local w = out.warnings
    local n = M.frame_count(def)
    out.frames = n

    -- metadados: forma invalida e erro (contrato), nao aviso
    local okmeta, metaErr = pcall(M.meta, def, def)
    if not okmeta then err(w, 'metadata: ' .. tostring(metaErr)) end

    local albs = M.frames(def, 'albedo')
    if not albs[1] then
        err(w, 'def sem canal albedo')
        return out
    end
    local emis = M.frames(def, 'emissive')
    local boxes, feet, counts = {}, {}, {}
    for f = 1, n do
        boxes[f] = M.bbox(albs[f])
        feet[f] = footline(albs[f])
        counts[f] = boxes[f] and boxes[f].pixels or 0
    end

    -- foot drift: os pes ficam no chao — ymax e xmin/xmax estaveis
    local f0 = feet[1]
    for f = 2, n do
        local ft = feet[f]
        if f0 and ft then
            if abs(ft.ymax - f0.ymax) > 1 then
                warn(w, f, string.format(
                    'foot drift vertical: base y=%d vs frame 1 y=%d',
                    ft.ymax, f0.ymax), nil, ft.ymax, 'pes')
            end
            if abs(ft.xmin - f0.xmin) > 2 or abs(ft.xmax - f0.xmax) > 2 then
                warn(w, f, string.format(
                    'foot drift lateral: pes x[%d..%d] vs frame 1 [%d..%d]',
                    ft.xmin, ft.xmax, f0.xmin, f0.xmax), ft.xmin, ft.ymax, 'pes')
            end
        elseif f0 and not ft then
            err(w, 'frame ' .. f .. ' vazio')
        end
    end

    -- salto de silhueta: contagem de pixels e bbox entre frames vizinhos
    for f = 2, n do
        local a, b = counts[f - 1], counts[f]
        if a > 0 and abs(b - a) / a > 0.25 then
            warn(w, f, string.format(
                'salto de silhueta: %d -> %d px (%.0f%%)', a, b,
                (b - a) / a * 100), nil, nil, 'silhueta')
        end
        if boxes[f - 1] and boxes[f] and
            (abs(boxes[f].x - boxes[f - 1].x) > 3
                or abs(boxes[f].y - boxes[f - 1].y) > 3) then
            warn(w, f, string.format(
                'bbox saltou para (%d,%d)', boxes[f].x, boxes[f].y),
                boxes[f].x, boxes[f].y, 'silhueta')
        end
    end

    -- parte faltando: regiao nomeada (def.regions, caixas) com pixels no
    -- frame 1 e zero em algum frame
    if type(def.regions) == 'table' then
        for name, r in pairs(def.regions) do
            local function count(f)
                if not albs[f] then return 0 end
                local c = 0
                for y = r.y, math.min(albs[f].h, r.y + r.h - 1) do
                    for x = r.x, math.min(albs[f].w, r.x + r.w - 1) do
                        if albs[f].rows[y][x] ~= '.' then c = c + 1 end
                    end
                end
                return c
            end
            local c0 = count(1)
            for f = 2, n do
                if c0 > 0 and count(f) == 0 then
                    warn(w, f, 'parte faltando: ' .. name,
                        r.x, r.y, name)
                end
            end
        end
    end

    -- flicker de textura: celula que alterna de valor na maioria das
    -- transicoes (ruido temporal), contado por frame par
    local flips = {}
    for f = 2, n do
        local a, b = albs[f - 1], albs[f]
        for y = 1, a.h do for x = 1, a.w do
            if a.rows[y][x] ~= b.rows[y][x] then
                local k = (y - 1) * a.w + x
                flips[k] = (flips[k] or 0) + 1
            end
        end end
    end
    if n >= 3 then
        local lim = floor((n - 1) * 0.6 + 0.5)
        local listed = 0
        for k, c in pairs(flips) do
            if c >= lim and listed < 8 then
                local y = floor((k - 1) / def.w) + 1
                local x = (k - 1) % def.w + 1
                warn(w, nil, string.format(
                    'flicker: pixel alternou em %d/%d transicoes', c, n - 1),
                    x, y, 'textura')
                listed = listed + 1
            end
        end
    end

    -- canal flutuante: emissivo sem albedo por baixo no mesmo frame
    for f = 1, n do
        if emis[f] then
            local floats, firstx, firsty = 0, nil, nil
            for y = 1, emis[f].h do for x = 1, emis[f].w do
                if emis[f].rows[y][x] ~= '.' and albs[f].rows[y][x] == '.' then
                    floats = floats + 1
                    firstx, firsty = firstx or x, firsty or y
                end
            end end
            if floats > 0 then
                warn(w, f, string.format(
                    'emissivo flutuando: %d px sem albedo', floats),
                    firstx, firsty, 'emissivo')
            end
        end
    end

    -- descontinuidade de loop: ultimo->primeiro dispara mais que a mediana
    if type(def.sequences) == 'table' then
        local deltas = {}
        for f = 2, n do deltas[#deltas + 1] = changed(albs[f - 1], albs[f]) end
        for name, s in pairs(def.sequences) do
            if s.loop and s[2] - s[1] >= 2 then
                local d = changed(albs[s[2]], albs[s[1]])
                local med = {}
                for f = s[1] + 1, s[2] do med[#med + 1] = changed(albs[f - 1], albs[f]) end
                table.sort(med)
                local m = med[floor(#med / 2) + 1] or 0
                if d > math.max(m * 1.8, 3) then
                    warn(w, s[2], string.format(
                        "loop quebrado em '%s': f%d->f%d mudou %d px (mediana %d)",
                        name, s[2], s[1], d, m), nil, nil, name)
                end
            end
        end
    end

    -- ancoras dentro do quadro e sobre pixel solido no frame correspondente
    if type(def.anchors) == 'table' then
        for name, a in pairs(def.anchors) do
            local list = type(a[1]) == 'number' and { a } or a
            for f, p in ipairs(list) do
                local g = albs[math.min(f, n)]
                if g and (p[1] < 1 or p[1] > g.w or p[2] < 1 or p[2] > g.h) then
                    warn(w, f, 'ancora ' .. name .. ' fora do quadro',
                        p[1], p[2], name)
                elseif g and g.rows[p[2]] and g.rows[p[2]][p[1]] == '.' then
                    warn(w, f, 'ancora ' .. name .. ' sobre pixel vazio',
                        p[1], p[2], name)
                end
            end
        end
    end
    return out
end

-- Deriva de identidade entre duas defs (poses/direcoes): compara a quota
-- de cada cor do frame 1. Devolve avisos para cores que divergem >tol.
function M.color_drift(a, b, tol)
    tol = tol or 0.5
    local warns = {}
    local ga, gb = M.compose(a, 'albedo', 1), M.compose(b, 'albedo', 1)
    if not (ga and gb) then return warns end
    local ca, cb = K.inspect(ga).colors, K.inspect(gb).colors
    local ta = math.max(1, K.inspect(ga).pixels)
    local tb = math.max(1, K.inspect(gb).pixels)
    for c, v in pairs(ca) do
        local share = math.abs(v / ta - (cb[c] or 0) / tb)
        if share > tol then
            warns[#warns + 1] = { severity = 'WARN', reason = string.format(
                "identidade: cor '%s' %.1f%% -> %.1f%%", c,
                v / ta * 100, (cb[c] or 0) / tb * 100) }
        end
    end
    return warns
end

return M
