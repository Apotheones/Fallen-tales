-- kit_workbench — bancada de revisão W3 (docs/MEGAPLAN_KIT_PROCEDURAL_IA.md §8).
--
-- Render estático de assets DSL para revisão por agentes, sem abrir o jogo.
-- Superfície de controle = tabela job (scripts/CLI), nunca clique:
--
--   local WB = require('tools.kit_workbench.workbench')
--   local r = WB.run{
--       asset  = 'lampiao',            -- nome em src.sprites OU caminho .lua
--       vs     = 'candidatos/lampiao2.lua', -- segundo asset p/ ab|diff
--       frame  = 1,                    -- ou 'all' (albedo/diff tiram tiras)
--       zoom   = 4,                    -- inteiro >= 1
--       bg     = 'checker',            -- checker|neutral|dark|ambient:<regiao>
--                                    -- |game[:<piso>]
--       views  = { 'albedo', 'grid', 'swatches', 'lit' },
--       light  = { {x=40,y=20,z=48,radius=120,intensity=1,color={1,.8,.5}} },
--       ambient= 'neutro',             -- regiao do hd_kit.AMBIENT ou {r,g,b}
--       crop   = {x=1,y=1,w=64,h=96},  -- recorte 1-based (crop/ab/diff)
--       region = 'corpo',              -- recorta via def.regions[nome]
--       mask   = 'chama',              -- def.masks[nome] vira overlay no grid
--       marks  = { {name='pe',x=32,y=96} }, -- âncoras propostas (laranja)
--       tile   = 3,                    -- repetição NxN na view tile
--       seed   = 0,                    -- seed das variantes (hd_kit.variant)
--       budget = 12,                   -- aviso se cores do frame > N
--       strict = false,                -- warnings viram exit 2
--       out    = 'wb-lampiao',         -- prefixo previsível dos PNGs
--       report = 'screenshots/wb-lampiao-report.txt',
--   }
--   -- r = {paths={...}, findings={...}, warnings=n, errors=n, exit=n}
--
-- Contratos consumidos (só APIs públicas, src/ intocável):
--   sprite_dsl.bake/.imageData  ·  palettes.resolve  ·  hd_kit.variant/.AMBIENT
--   lighting.new/:compose (preview com luz móvel real do jogo)
--
-- Coordenadas de autoria são 1-based em TUDO que o agente vê (relatório,
-- régua, âncoras); ImageData 0-based só dentro deste módulo.
--
-- Campos opcionais lidos da def (forward-compat W1/W4):
--   def.anchors = {nome={x,y}} ou {{name=,x=,y=}}      -- cruzes no grid
--   def.regions = {nome={x=,y=,w=,h=}}                 -- caixas no grid / --region
--   def.masks   = {nome='<grade>'}                     -- overlay violeta / --mask

local M = {}

local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local fmt = string.format
local G = love.graphics
local IMG = love.image

local function fail(m) error('kit_workbench: ' .. m, 2) end

local function tryRequire(mod)
    local ok, v = pcall(require, mod)
    if ok then return v end
    return nil, v
end

local DSL = function() return require('src.sprite_dsl') end
local HD = function() return require('src.hd_kit') end
local PAL = function() return require('src.palettes') end

--------------------------------------------------------------------------------
-- ImageData helpers (0-based aqui dentro)
--------------------------------------------------------------------------------

local function dims(id) return id:getWidth(), id:getHeight() end

local function setp(id, x, y, r, g, b, a)
    if x >= 0 and y >= 0 and x < id:getWidth() and y < id:getHeight() then
        id:setPixel(x, y, r, g, b, a)
    end
end

local function fillRect(id, x, y, w, h, r, g, b, a)
    for yy = y, y + h - 1 do for xx = x, x + w - 1 do
        setp(id, xx, yy, r, g, b, a or 1)
    end end
end

local function mixp(id, x, y, r, g, b, t)
    if x < 0 or y < 0 or x >= id:getWidth() or y >= id:getHeight() then return end
    local pr, pg, pb, pa = id:getPixel(x, y)
    id:setPixel(x, y, pr + (r - pr) * t, pg + (g - pg) * t, pb + (b - pb) * t, pa)
end

local function frameID(sheet, channel, f)
    local src = sheet.imageData[channel]
    local id = IMG.newImageData(sheet.w, sheet.h)
    id:paste(src, 0, 0, (f - 1) * sheet.w, 0, sheet.w, sheet.h)
    return id
end

-- Recorte 1-based aplicado a um frame ImageData; nil = frame inteiro.
local function cropID(id, crop)
    if not crop then return id end
    local cx, cy = max(1, crop.x), max(1, crop.y)
    local w = min(crop.w - (cx - crop.x), dims(id) - cx + 1)
    local h = min(crop.h - (cy - crop.y), select(2, dims(id)) - cy + 1)
    w, h = max(1, w), max(1, h)
    local out = IMG.newImageData(w, h)
    out:paste(id, 0, 0, cx - 1, cy - 1, w, h)
    return out
end

-- Alpha-over de src (ImageData) em dst já opaco, em coordenada 0-based.
local function blitOver(dst, src, dx, dy)
    local sw, sh = dims(src)
    for y = 0, sh - 1 do for x = 0, sw - 1 do
        local r, g, b, a = src:getPixel(x, y)
        if a > 0 then
            local px, py = dx + x, dy + y
            if px >= 0 and py >= 0 and px < dst:getWidth() and py < dst:getHeight() then
                local dr, dg, db = dst:getPixel(px, py)
                dst:setPixel(px, py,
                    r * a + dr * (1 - a), g * a + dg * (1 - a), b * a + db * (1 - a), 1)
            end
        end
    end end
end

-- Blit com zoom inteiro (nearest) sobre plate já preenchido com fundo.
local function blitZoom(dst, src, dx, dy, z)
    local sw, sh = dims(src)
    for y = 0, sh - 1 do for x = 0, sw - 1 do
        local r, g, b, a = src:getPixel(x, y)
        if a > 0 then
            for yy = 0, z - 1 do for xx = 0, z - 1 do
                local px, py = dx + x * z + xx, dy + y * z + yy
                if px >= 0 and py >= 0
                    and px < dst:getWidth() and py < dst:getHeight() then
                    local dr, dg, db = dst:getPixel(px, py)
                    dst:setPixel(px, py,
                        r * a + dr * (1 - a), g * a + dg * (1 - a), b * a + db * (1 - a), 1)
                end
            end end
        end
    end end
end

-- Une ImageDatas na horizontal com gap de fundo transparente.
local function hjoin(ids, gap)
    gap = gap or 0
    local w, h = gap * (#ids - 1), 0
    for _, id in ipairs(ids) do w = w + dims(id); h = max(h, select(2, dims(id))) end
    local out = IMG.newImageData(max(w, 1), max(h, 1))
    local x = 0
    for _, id in ipairs(ids) do
        out:paste(id, x, 0, 0, 0, dims(id))
        x = x + dims(id) + gap
    end
    return out
end

--------------------------------------------------------------------------------
-- Fundos
--------------------------------------------------------------------------------

local BG_COLORS = {
    checker = { a = { .19, .19, .22 }, b = { .09, .09, .11 }, size = 8 },
    neutral = { .42, .42, .46 },
    dark    = { .055, .065, .09 },
}

-- spec -> {kind=...}; 'game' assa um piso real e repete com variantes.
local function bgFor(spec, job)
    spec = spec or 'checker'
    local kind, arg = spec:match('^(%w+):?(.*)$')
    if kind == 'checker' then
        return { kind = 'checker', a = BG_COLORS.checker.a, b = BG_COLORS.checker.b,
            size = BG_COLORS.checker.size }
    elseif kind == 'neutral' then
        return { kind = 'solid', rgb = BG_COLORS.neutral }
    elseif kind == 'dark' then
        return { kind = 'solid', rgb = BG_COLORS.dark }
    elseif kind == 'ambient' then
        local c = HD().ambient(arg ~= '' and arg or 'neutro')
        return { kind = 'solid', rgb = { c[1], c[2], c[3] } }
    elseif kind == 'game' then
        local piso = arg ~= '' and arg or 'piso_terra'
        local def = tryRequire('src.sprites.' .. piso)
        if not def then fail("bg game: piso '" .. piso .. "' não existe em src.sprites") end
        local sheet = DSL().bake(def)
        local frames = {}
        for f = 1, sheet.frames do frames[f] = frameID(sheet, 'albedo', f) end
        return { kind = 'tiles', frames = frames, sheet = sheet,
            cw = sheet.w, ch = sheet.h, seed = job.seed or 0 }
    elseif kind == 'shot' then
        -- captura de cena real como backdrop: shot:<arquivo>[@x,y] —
        -- amostra a partir de (x,y) e repete se a captura for menor.
        local path, ox, oy = arg:match('^([^@]+)@?(%-?%d*),?(%-?%d*)$')
        if not path or path == '' then
            fail("bg shot: use shot:<arquivo.png>[@x,y]")
        end
        -- path é OS (cwd = raiz do repo); LÖVE resolveria pela source dir
        local fh = io.open(path, 'rb')
        if not fh then fail("bg shot: não acha '" .. path .. "'") end
        local bytes = fh:read('*a')
        fh:close()
        local okid, id = pcall(IMG.newImageData,
            love.filesystem.newFileData(bytes, path))
        if not okid then fail("bg shot: '" .. path .. "' não é imagem válida") end
        return { kind = 'shot', id = id,
            ox = tonumber(ox) or 0, oy = tonumber(oy) or 0 }
    end
    fail("bg desconhecido '" .. spec ..
        "' (checker|neutral|dark|ambient:<regiao>|game[:<piso>]|shot:<arq>[@x,y])")
end

local function paintBG(dst, bg, x, y, w, h)
    if bg.kind == 'tiles' then
        local HDK = HD()
        for yy = 0, h - 1 do for xx = 0, w - 1 do
            local cx, cy = floor((x + xx) / bg.cw), floor((y + yy) / bg.ch)
            local f = HDK.variant(bg.sheet, cx, cy, bg.seed)
            local r, g, b = bg.frames[f]:getPixel((x + xx) % bg.cw, (y + yy) % bg.ch)
            dst:setPixel(x + xx, y + yy, r, g, b, 1)
        end end
        return
    end
    if bg.kind == 'shot' then
        local sw, sh = dims(bg.id)
        for yy = 0, h - 1 do for xx = 0, w - 1 do
            local r, g, b = bg.id:getPixel((x + xx + bg.ox) % sw,
                (y + yy + bg.oy) % sh)
            dst:setPixel(x + xx, y + yy, r, g, b, 1)
        end end
        return
    end
    for yy = 0, h - 1 do for xx = 0, w - 1 do
        local r, g, b
        if bg.kind == 'solid' then
            r, g, b = bg.rgb[1], bg.rgb[2], bg.rgb[3]
        else -- checker
            local c = (floor((x + xx) / bg.size) + floor((y + yy) / bg.size)) % 2 == 0
                and bg.a or bg.b
            r, g, b = c[1], c[2], c[3]
        end
        dst:setPixel(x + xx, y + yy, r, g, b, 1)
    end end
end

--------------------------------------------------------------------------------
-- Texto: labels acumulados durante a montagem, rasterizados num passe de
-- canvas (fonte default 9). Único uso de GPU fora da view 'lit'.
--------------------------------------------------------------------------------

local font9
local function renderText(id, labels)
    if #labels == 0 then return id end
    font9 = font9 or G.newFont(9)
    local w, h = dims(id)
    local img = G.newImage(id)
    img:setFilter('nearest', 'nearest')
    local c = G.newCanvas(w, h)
    G.setCanvas(c)
    G.clear(0, 0, 0, 0)
    G.setColor(1, 1, 1)
    G.draw(img, 0, 0)
    G.setFont(font9)
    for _, l in ipairs(labels) do
        G.setColor(l[4] or { .82, .84, .90 })
        G.print(l[3], l[1], l[2])
    end
    G.setCanvas()
    local out = c:newImageData()
    c:release()
    img:release()
    return out
end

-- Faixa de cabeçalho com proveniência + labels em cima do corpo.
-- footH reserva faixa escura no rodapé p/ labels que apontam abaixo da
-- imagem (tiras de frames, A/B, contagens do diff).
local function chrome(body, title, labels, footH)
    local w, h = dims(body)
    footH = footH or 0
    local out = IMG.newImageData(w, h + 13 + footH)
    fillRect(out, 0, 0, w, 13, .07, .075, .10)
    if footH > 0 then fillRect(out, 0, h + 13, w, footH, .07, .075, .10) end
    out:paste(body, 0, 13, 0, 0, w, h)
    local ls = { { 4, 2, title, { .75, .78, .86 } } }
    for _, l in ipairs(labels or {}) do
        ls[#ls + 1] = { l[1], l[2] + 13, l[3], l[4] }
    end
    return renderText(out, ls)
end

--------------------------------------------------------------------------------
-- Asset
--------------------------------------------------------------------------------

local function isPath(ref) return ref:match('%.lua$') or ref:find('[/\\]') end

function M.loadAsset(ref)
    local def, source
    if type(ref) == 'table' then
        def, source = ref, '(def em memória)'
    elseif isPath(ref) then
        local chunk, e = loadfile(ref)
        if not chunk then fail('arquivo não carrega: ' .. ref .. ' (' .. tostring(e) .. ')') end
        local ok, v = pcall(chunk)
        if not ok then fail('executando ' .. ref .. ': ' .. tostring(v)) end
        if type(v) ~= 'table' then fail(ref .. ' não devolveu uma def (tabela)') end
        def, source = v, ref
    else
        local d, e = tryRequire('src.sprites.' .. ref)
        if not d then fail("asset '" .. ref .. "' não existe em src.sprites (" .. tostring(e) .. ')') end
        def, source = d, 'src.sprites.' .. ref
    end
    if type(def.legend) ~= 'table' or type(def.layers) ~= 'table' then
        fail('def inválida em ' .. source .. ' (falta legend/layers)')
    end
    local ok, sheet = pcall(DSL().bake, def)
    if not ok then fail('bake falhou em ' .. source .. ': ' .. tostring(sheet)) end
    local name = def.name or (type(ref) == 'string' and ref:gsub('%.lua$', ''):match('[^/\\]+$'))
        or 'asset'
    return { ref = ref, name = name, def = def, sheet = sheet, source = source }
end

--------------------------------------------------------------------------------
-- Overlays de revisão (no plate zoomado)
--------------------------------------------------------------------------------

local function gridLines(id, ox, oy, sw, sh, z)
    -- sw,sh = pixels-fonte; linhas nas fronteiras (0..sw)*z
    for c = 0, sw do
        local x = ox + c * z
        local t = (c % 8 == 0) and .30 or ((z >= 3) and .10 or 0)
        if t > 0 then for y = oy, oy + sh * z - 1 do mixp(id, x, y, 1, 1, 1, t) end end
    end
    for r = 0, sh do
        local y = oy + r * z
        local t = (r % 8 == 0) and .30 or ((z >= 3) and .10 or 0)
        if t > 0 then for x = ox, ox + sw * z - 1 do mixp(id, x, y, 1, 1, 1, t) end end
    end
end

-- Caixa em coordenadas de fronteira (0-based, já no plate).
local function boxBound(id, x0, y0, x1, y1, r, g, b)
    for x = x0, x1 do mixp(id, x, y0, r, g, b, .95); mixp(id, x, y1, r, g, b, .95) end
    for y = y0, y1 do mixp(id, x0, y, r, g, b, .95); mixp(id, x1, y, r, g, b, .95) end
end

local function cross(id, x, y, r, g, b, rad)
    rad = rad or 5
    for d = -rad, rad do
        mixp(id, x + d, y, r, g, b, .9)
        mixp(id, x, y + d, r, g, b, .9)
    end
end

local function bboxOf(id)
    local w, h = dims(id)
    local x0, y0, x1, y1
    for y = 0, h - 1 do for x = 0, w - 1 do
        local _, _, _, a = id:getPixel(x, y)
        if a > 0 then
            x0 = x0 and min(x0, x) or x
            y0 = y0 and min(y0, y) or y
            x1 = x1 and max(x1, x) or x
            y1 = y1 and max(y1, y) or y
        end
    end end
    if not x0 then return nil end
    -- devolve em coordenadas de autoria 1-based
    return { x = x0 + 1, y = y0 + 1, w = x1 - x0 + 1, h = y1 - y0 + 1 }
end

-- Normaliza def.anchors + job.marks numa lista {name,x,y,proposta?}.
local function anchorList(def, marks, f)
    local out = {}
    if type(def.anchors) == 'table' then
        if def.anchors[1] then
            for _, a in ipairs(def.anchors) do
                out[#out + 1] = { name = a.name or '?', x = a.x, y = a.y }
            end
        else
            for nome, p in pairs(def.anchors) do
                if type(p[1]) == 'table' or type(p.x) == 'table' then
                    -- âncora por frame: {pe = {{x,y},{x,y},...}}
                    local seq = p[1] and p or p.x
                    local q = f and seq[f] or seq[1]
                    if q then
                        out[#out + 1] = { name = nome, x = q[1] or q.x,
                            y = q[2] or q.y, porFrame = true }
                    end
                else
                    out[#out + 1] = { name = nome, x = p[1] or p.x,
                        y = p[2] or p.y }
                end
            end
        end
    end
    for _, a in ipairs(marks or {}) do
        out[#out + 1] = { name = a.name or '?', x = a.x, y = a.y, proposta = true }
    end
    return out
end

-- Tracks completas: {nome -> {{x,y},...}} com estática replicada por frame.
local function anchorTracks(def, nframes)
    local tracks = {}
    for nome, p in pairs(type(def.anchors) == 'table' and def.anchors or {}) do
        if type(p) == 'table' then
            local t = {}
            if type(p[1]) == 'table' or type(p.x) == 'table' then
                local seq = p[1] and p or p.x
                for f = 1, nframes do
                    local q = seq[f] or seq[#seq]
                    t[f] = q and { q[1] or q.x, q[2] or q.y } or nil
                end
            else
                local q = { p[1] or p.x, p[2] or p.y }
                for f = 1, nframes do t[f] = q end
            end
            tracks[nome] = t
        end
    end
    -- forma de lista também vale: {{name=, x=, y=}} estática
    if type(def.anchors) == 'table' and def.anchors[1] then
        for _, a in ipairs(def.anchors) do
            local q = { a.x, a.y }
            local t = {}
            for f = 1, nframes do t[f] = q end
            tracks[a.name or '?'] = t
        end
    end
    return tracks
end

-- Marcas de animação (contrato W4/Cinzel): def.markers = {nome={f1,f2,..}}
-- com nomes convencionais prep/contact/react/recover/return.
local function markerSets(def)
    local out = {}
    if type(def.markers) == 'table' then
        for nome, fs in pairs(def.markers) do out[nome] = fs end
    end
    if type(def.contacts) == 'table' then out.contact = def.contacts end
    return out
end

-- Sequências nomeadas (contrato W4/Cinzel):
-- def.sequences = { nome = {first, last [, loop=bool]} } dentro do sheet.
local function seqSets(def)
    local out = {}
    if type(def.sequences) ~= 'table' then return out end
    for nome, s in pairs(def.sequences) do
        if type(s) == 'table' then
            out[nome] = { first = s[1] or s.first, last = s[2] or s.last,
                loop = s.loop }
        end
    end
    return out
end

-- Resolve itens de --seq: número = índice de frame; string = sequência
-- nomeada (first..last). Devolve lista de índices de frame.
local function resolveSeq(def, items, N)
    local seqs = seqSets(def)
    local out = {}
    for _, it in ipairs(items or {}) do
        local n = tonumber(it)
        if n then
            n = floor(n)
            if n < 1 or n > N then
                fail(fmt('seq: índice %d fora de 1..%d', n, N))
            end
            out[#out + 1] = n
        elseif seqs[it] then
            local s = seqs[it]
            if not (s.first and s.last) then
                fail(fmt("sequência '%s' malformada (falta first/last)", it))
            end
            for f = s.first, s.last do out[#out + 1] = f end
        else
            fail(fmt("seq '%s' não é índice nem sequência (válidas: %s)",
                tostring(it), table.concat((function()
                    local q = {}
                    for k in pairs(seqs) do q[#q + 1] = k end
                    table.sort(q)
                    return q end)(), ',') or 'nenhuma'))
        end
    end
    return out
end

local function inSet(set, f)
    for _, v in ipairs(set) do if v == f then return true end end
    return false
end

local function regionList(def)
    local out = {}
    if type(def.regions) == 'table' then
        if def.regions[1] then
            for _, r in ipairs(def.regions) do out[#out + 1] = r end
        else
            for nome, r in pairs(def.regions) do
                out[#out + 1] = { name = nome, x = r.x, y = r.y, w = r.w, h = r.h }
            end
        end
    end
    return out
end

local REGION_CORES = {
    { .95, .55, .25 }, { .35, .75, 1 }, { .75, .95, .35 }, { .95, .4, .6 },
    { .6, .9, .8 }, { .85, .7, 1 },
}

-- Região nomeada que contém a coordenada 1-based (ou nil).
local function regionAt(def, x, y)
    for _, r in ipairs(regionList(def)) do
        if r.x and r.y and r.w and r.h
            and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then
            return r.name
        end
    end
    return nil
end

-- Grade+réguas+origem+âncoras+regiões em cima de um plate zoomado cuja
-- imagem-fonte sw×sh está desenhada em (ox,oy) com escala z. ctx.off =
-- {x,y} = coordenada de autoria do canto (1,1) do recorte — overlays e
-- réguas falam sempre em coordenadas de autoria do sheet inteiro.
local function overlayGrid(id, ox, oy, sw, sh, z, ctx)
    local labels = {}
    local off = ctx.off or { x = 0, y = 0 } -- crop.x-1, crop.y-1
    gridLines(id, ox, oy, sw, sh, z)
    -- réguas: número a cada 8 px (absoluto), margens de 15px
    for c = 1, sw do
        local ab = off.x + c
        if ab % 8 == 0 then
            labels[#labels + 1] = { ox + c * z - 6, 2, tostring(ab) }
        end
    end
    for r = 1, sh do
        local ab = off.y + r
        if ab % 8 == 0 then
            labels[#labels + 1] = { 1, oy + r * z - 5, tostring(ab) }
        end
    end
    -- caixa de cobertura (albedo alpha>0)
    if ctx.bbox then
        local b = ctx.bbox
        boxBound(id, ox + (b.x - 1 - off.x) * z, oy + (b.y - 1 - off.y) * z,
            ox + (b.x + b.w - 1 - off.x) * z, oy + (b.y + b.h - 1 - off.y) * z,
            1, .62, .2)
        labels[#labels + 1] = { ox + (b.x - 1 - off.x) * z,
            oy + (b.y + b.h - 1 - off.y) * z + 2,
            fmt('bbox %d,%d %dx%d', b.x, b.y, b.w, b.h), { 1, .7, .35 } }
    end
    -- origem (em coords de autoria: feet = centro-x na base, topleft = 1,1)
    if ctx.origin == 'feet' then
        local ax = ox + (floor(ctx.fullW / 2) - off.x) * z
        local ay = oy + (ctx.fullH - off.y) * z
        cross(id, ax, ay, .35, .95, .6)
        labels[#labels + 1] = { ax + 6, ay - 10, 'origem feet', { .35, .95, .6 } }
    elseif ctx.origin == 'topleft' then
        local ax, ay = ox - off.x * z, oy - off.y * z
        cross(id, ax, ay, .35, .95, .6)
        labels[#labels + 1] = { ax + 6, ay + 2, 'origem topleft', { .35, .95, .6 } }
    end
    -- máscara nomeada (def.masks[job.mask]) — tinta violeta por cima
    if ctx.maskGrid then
        local mg = ctx.maskGrid
        for y = 1, min(sh + off.y, mg.h) do for x = 1, min(sw + off.x, mg.w) do
            local lx, ly = x - off.x, y - off.y
            if lx >= 1 and ly >= 1
                and (mg.rows[y] and mg.rows[y][x] or '.') ~= '.' then
                for yy = 0, z - 1 do for xx = 0, z - 1 do
                    mixp(id, ox + (lx - 1) * z + xx, oy + (ly - 1) * z + yy,
                        .6, .3, .95, .38)
                end end
            end
        end end
        labels[#labels + 1] = { ox + 2, oy + sh * z - 11,
            'mask ' .. ctx.maskName, { .7, .45, 1 } }
    end
    -- regiões nomeadas
    for i, r in ipairs(ctx.regions or {}) do
        if r.x and r.y and r.w and r.h then
            local c = REGION_CORES[(i - 1) % #REGION_CORES + 1]
            boxBound(id, ox + (r.x - 1 - off.x) * z, oy + (r.y - 1 - off.y) * z,
                ox + (r.x + r.w - 1 - off.x) * z, oy + (r.y + r.h - 1 - off.y) * z,
                c[1], c[2], c[3])
            labels[#labels + 1] = { ox + (r.x - 1 - off.x) * z + 2,
                oy + (r.y - 1 - off.y) * z + 2, r.name or ('regiao' .. i), c }
        end
    end
    -- âncoras (def + propostas)
    for _, a in ipairs(ctx.anchors or {}) do
        if a.x and a.y then
            local c = a.proposta and { 1, .55, .15 } or { .35, .7, 1 }
            cross(id, ox + (a.x - 1 - off.x) * z + floor(z / 2),
                oy + (a.y - 1 - off.y) * z + floor(z / 2), c[1], c[2], c[3], 6)
            labels[#labels + 1] = { ox + (a.x - 1 - off.x) * z + 6,
                oy + (a.y - 1 - off.y) * z - 2,
                (a.proposta and '?' or '') .. tostring(a.name), c }
        end
    end
    return labels
end

--------------------------------------------------------------------------------
-- Views — cada uma devolve ImageData pronto p/ PNG
--------------------------------------------------------------------------------

local views = {}

local BG_PRETO = { kind = 'solid', rgb = { 0, 0, 0 } }

local function plateFor(w, h, job, bg)
    local plate = IMG.newImageData(w, h)
    paintBG(plate, bg or job._bg, 0, 0, w, h)
    return plate
end

-- plate base: frame recortado (crop) sobre fundo, zoom z, offset ox,oy.
local function basePlate(asset, f, job, marginX, marginY, channel, bg)
    local src = asset._channels[channel or 'albedo'][f]
    local crop = job._crop or { x = 1, y = 1, w = asset.sheet.w, h = asset.sheet.h }
    -- clamp ao tamanho do asset (ab/diff compartilham o mesmo --crop)
    local cx, cy = max(1, crop.x), max(1, crop.y)
    local sw = min(crop.w - (cx - crop.x), asset.sheet.w - cx + 1)
    local sh = min(crop.h - (cy - crop.y), asset.sheet.h - cy + 1)
    sw, sh = max(1, sw), max(1, sh)
    local sub = IMG.newImageData(sw, sh)
    sub:paste(src, 0, 0, cx - 1, cy - 1, sw, sh)
    local z = job.zoom
    local plate = plateFor(sw * z + 2 * marginX, sh * z + 2 * marginY, job, bg)
    blitZoom(plate, sub, marginX, marginY, z)
    return plate, sub, sw, sh, marginX, marginY
end

local function title(asset, view, f, job)
    return fmt('%s · %s · f%s/%d · z%d', asset.name, view,
        tostring(f), asset.sheet.frames, job.zoom)
end

local function simpleView(asset, job, f, channel, label, bg)
    local sub = cropID(asset._channels[channel][f], job._crop)
    local sw, sh = dims(sub)
    local z = job.zoom
    local plate = plateFor(sw * z, sh * z, job, bg)
    blitZoom(plate, sub, 0, 0, z)
    return chrome(plate, title(asset, label or channel, f, job))
end

function views.albedo(asset, job)
    if job.frame == 'all' then
        local ids, labels = {}, {}
        local x = 0
        for f = 1, asset.sheet.frames do
            local p = select(1, basePlate(asset, f, job, 0, 0))
            ids[f] = p
            labels[#labels + 1] = { x + 2, select(2, dims(p)) + 2,
                'f' .. f, { .75, .78, .86 } }
            x = x + dims(p) + 4
        end
        local strip = hjoin(ids, 4)
        return chrome(strip, title(asset, 'albedo', 'all', job), labels, 12)
    end
    return simpleView(asset, job, job.frame, 'albedo')
end

function views.normal(asset, job)
    return simpleView(asset, job, job.frame, 'normal')
end

function views.emissive(asset, job)
    -- emissivo sempre sobre preto (é luz, não tinta)
    return simpleView(asset, job, job.frame, 'emissive', nil, BG_PRETO)
end

function views.luminance(asset, job)
    local src = cropID(asset._channels.albedo[job.frame], job._crop)
    local sw, sh = dims(src)
    local id = IMG.newImageData(sw, sh)
    for y = 0, sh - 1 do for x = 0, sw - 1 do
        local r, g, b, a = src:getPixel(x, y)
        local l = .299 * r + .587 * g + .114 * b
        id:setPixel(x, y, l, l, l, a)
    end end
    local z = job.zoom
    local plate = plateFor(sw * z, sh * z, job)
    blitZoom(plate, id, 0, 0, z)
    return chrome(plate, title(asset, 'luminance', job.frame, job))
end

function views.silhouette(asset, job)
    local src = cropID(asset._channels.albedo[job.frame], job._crop)
    local sw, sh = dims(src)
    local id = IMG.newImageData(sw, sh)
    for y = 0, sh - 1 do for x = 0, sw - 1 do
        local _, _, _, a = src:getPixel(x, y)
        id:setPixel(x, y, .08, .09, .12, a)
    end end
    local z = job.zoom
    local plate = IMG.newImageData(sw * z, sh * z)
    fillRect(plate, 0, 0, dims(plate), .78, .78, .72, 1)
    blitZoom(plate, id, 0, 0, z)
    return chrome(plate, title(asset, 'silhouette', job.frame, job))
end

function views.channels(asset, job)
    local f = job.frame == 'all' and 1 or job.frame
    local names = { 'albedo', 'normal', 'emissive' }
    local parts, labels = {}, {}
    local x = 0
    for i, ch in ipairs(names) do
        local p = select(1, basePlate(asset, f, job, 0, 0, ch,
            ch == 'emissive' and BG_PRETO or nil))
        parts[i] = p
        labels[#labels + 1] = { x + 2, select(2, dims(p)) + 2, ch, { .75, .78, .86 } }
        x = x + dims(p) + 4
    end
    return chrome(hjoin(parts, 4), title(asset, 'channels', f, job), labels, 12)
end

-- ctx de overlay para views grid/crop: tudo em coords de autoria.
local function gridCtx(asset, job, f, full)
    local c = job._crop or { x = 1, y = 1, w = asset.sheet.w, h = asset.sheet.h }
    local cx, cy = max(1, c.x), max(1, c.y)
    return {
        off = { x = cx - 1, y = cy - 1 },
        fullW = asset.sheet.w, fullH = asset.sheet.h,
        origin = asset.sheet.origin,
        bbox = asset._bbox[f],
        anchors = full and anchorList(asset.def, job.marks, f) or nil,
        regions = full and regionList(asset.def) or nil,
        maskGrid = full and job._maskGrid or nil, maskName = job.mask,
    }
end

function views.grid(asset, job)
    local f = job.frame == 'all' and 1 or job.frame
    local ML, MT = 15, 15
    local plate, sub, sw, sh = basePlate(asset, f, job, ML, MT)
    local labels = overlayGrid(plate, ML, MT, sw, sh, job.zoom,
        gridCtx(asset, job, f, true))
    return chrome(plate, title(asset, 'grid', f, job), labels)
end

function views.crop(asset, job)
    if not job._cropExplicit then
        fail("view 'crop' precisa de --crop=x,y,w,h ou --region=nome")
    end
    local f = job.frame == 'all' and 1 or job.frame
    local ML, MT = 15, 15
    local plate, sub, sw, sh = basePlate(asset, f, job, ML, MT)
    local labels = overlayGrid(plate, ML, MT, sw, sh, job.zoom,
        gridCtx(asset, job, f, true))
    labels[#labels + 1] = { 2, select(2, dims(plate)) - 11,
        fmt('crop %d,%d %dx%d', job._crop.x, job._crop.y, sw, sh), { 1, .7, .35 } }
    return chrome(plate, title(asset, 'crop', f, job), labels)
end

function views.tile(asset, job)
    local n = job.tile or 3
    local f = job.frame
    local sw, sh = asset.sheet.w, asset.sheet.h
    local z = job.zoom
    local plate = IMG.newImageData(sw * n * z, sh * n * z)
    paintBG(plate, job._bg, 0, 0, sw * n * z, sh * n * z)
    local HDK = HD()
    for cy = 0, n - 1 do for cx = 0, n - 1 do
        local vf = (f == 'all')
            and HDK.variant(asset.sheet, cx, cy, job.seed or 0) or f
        blitZoom(plate, asset._channels.albedo[vf], cx * sw * z, cy * sh * z, z)
    end end
    -- linhas de junção entre células
    for c = 0, n do for y = 0, sh * n * z - 1 do
        mixp(plate, c * sw * z, y, 1, .3, .3, .8)
    end end
    for r = 0, n do for x = 0, sw * n * z - 1 do
        mixp(plate, x, r * sh * z, 1, .3, .3, .8)
    end end
    return chrome(plate, fmt('%s · tile %dx%d · %s seed=%d',
        asset.name, n, n,
        (f == 'all') and 'variant' or ('f' .. f), job.seed or 0))
end

--------------------------------------------------------------------------------
-- Revisão animada básica (W3 estendido; rig/diagnósticos completos = W4)
--------------------------------------------------------------------------------

-- Conjunto de frames efetivo: --seq resolvido ou todos.
local function frameSet(job, N)
    if job._frameSet then return job._frameSet end
    local t = {}
    for i = 1, N do t[i] = i end
    return t
end

-- Strip de todos os frames com grade + bbox + origem por célula: expõe
-- saltos de silhueta e deriva de conteúdo entre quadros.
function views.frames(asset, job)
    local N = asset.sheet.frames
    local parts, labels, x = {}, {}, 0
    for _, f in ipairs(frameSet(job, N)) do
        local p, _, sw, sh = basePlate(asset, f, job, 0, 0)
        gridLines(p, 0, 0, sw, sh, job.zoom)
        local b = asset._bbox[f]
        if b then
            local c = job._crop or { x = 1, y = 1 }
            boxBound(p, (b.x - c.x) * job.zoom, (b.y - c.y) * job.zoom,
                (b.x + b.w - c.x) * job.zoom, (b.y + b.h - c.y) * job.zoom,
                1, .62, .2)
        end
        parts[#parts + 1] = p
        labels[#labels + 1] = { x + 2, select(2, dims(p)) + 2,
            'f' .. f, { .75, .78, .86 } }
        x = x + dims(p) + 4
    end
    return chrome(hjoin(parts, 4), title(asset, 'frames', 'all', job), labels, 12)
end

-- Cópia do frame com alpha reduzido e cor puxada para a tinta (fantasma).
local function ghostOf(id, tr, tg, tb, amul, cmul)
    local w, h = dims(id)
    local g = IMG.newImageData(w, h)
    for y = 0, h - 1 do for x = 0, w - 1 do
        local r, gg, b, a = id:getPixel(x, y)
        if a > 0 then
            g:setPixel(x, y, r + (tr - r) * cmul, gg + (tg - gg) * cmul,
                b + (tb - b) * cmul, a * amul)
        end
    end end
    return g
end

-- Onion skin: frame atual opaco, anterior em vermelho-fantasma, próximo
-- em azul — wrap de loop. --frame=N dá célula única; 'all' tira o ciclo.
function views.onion(asset, job)
    local N = asset.sheet.frames
    local frames = {}
    if job.frame == 'all' then
        frames = frameSet(job, N)
    else frames = { job.frame } end
    local parts, labels, x = {}, {}, 0
    for i, f in ipairs(frames) do
        -- fantasmas seguem a ORDEM da seleção (sequência), wrap no ciclo
        local prev = frames[i - 1] or frames[#frames]
        local prox = frames[i + 1] or frames[1]
        local cur = cropID(asset._channels.albedo[f], job._crop)
        local gw = max(dims(cur), dims(cropID(asset._channels.albedo[prev], job._crop)),
            dims(cropID(asset._channels.albedo[prox], job._crop)))
        local gh = max(select(2, dims(cur)),
            select(2, dims(cropID(asset._channels.albedo[prev], job._crop))),
            select(2, dims(cropID(asset._channels.albedo[prox], job._crop))))
        local z = job.zoom
        local cell = plateFor(gw * z, gh * z, job)
        -- fantasmas e frame alinhados pela base-central (pés)
        local gA = ghostOf(cropID(asset._channels.albedo[prev], job._crop),
            1, .3, .3, .5, .5)
        local gB = ghostOf(cropID(asset._channels.albedo[prox], job._crop),
            .3, .5, 1, .5, .5)
        local cw, chh = dims(cur)
        local paw, pah = dims(gA)
        local pbw, pbh = dims(gB)
        blitZoom(cell, gA, floor((gw - paw) / 2) * z, (gh - pah) * z, z)
        blitZoom(cell, gB, floor((gw - pbw) / 2) * z, (gh - pbh) * z, z)
        blitZoom(cell, cur, floor((gw - cw) / 2) * z, (gh - chh) * z, z)
        parts[#parts + 1] = cell
        labels[#labels + 1] = { x + 2, select(2, dims(cell)) + 2,
            fmt('f%d (<f%d >f%d)', f, prev, prox), { .9, .7, .5 } }
        x = x + dims(cell) + 4
    end
    return chrome(hjoin(parts, 4),
        fmt('%s · onion · f%s · z%d', asset.name, tostring(job.frame), job.zoom),
        labels, 12)
end

-- Duração por frame: def.frameDuration (escalar|array, segundos) ou 1/8s.
local function frameDur(asset, f)
    local d = asset.def.frameDuration or asset.def.durations
    if type(d) == 'number' then return d end
    if type(d) == 'table' then return d[f] or d[1] or .125 end
    return .125
end

-- Captura reproduzível de sequência: frames nos índices de --seq
-- (default todos) com índice e tempo acumulado sob cada célula.
function views.seq(asset, job)
    local N = asset.sheet.frames
    local idxs = frameSet(job, N)
    local tacc = { 0 }
    for f = 2, N + 1 do tacc[f] = tacc[f - 1] + frameDur(asset, f - 1) end
    local parts, labels, x = {}, {}, 0
    for _, f in ipairs(idxs) do
        local p = select(1, basePlate(asset, f, job, 0, 0))
        parts[#parts + 1] = p
        labels[#labels + 1] = { x + 2, select(2, dims(p)) + 2,
            fmt('i%d t=%.3fs', f, tacc[f]), { .75, .78, .86 } }
        x = x + dims(p) + 4
    end
    return chrome(hjoin(parts, 4),
        fmt('%s · seq · z%d', asset.name, job.zoom), labels, 12)
end

-- Várias instâncias do mesmo ator: --instances=N células, cada uma no
-- frame ((f-1 + i*K) mod N)+1 com --phase=K (0 = todas idênticas —
-- prova de que o loop se repete igual; K>0 = fases dessincronizadas).
function views.instances(asset, job)
    local N = asset.sheet.frames
    local pool = frameSet(job, N)
    local n = max(2, floor(job.instances or 4))
    local step = floor(job.phase or 0)
    local base = (job.frame == 'all') and 1 or job.frame
    local bpos = 1
    for i, f in ipairs(pool) do if f == base then bpos = i end end
    local parts, labels, x = {}, {}, 0
    for i = 0, n - 1 do
        local f = pool[((bpos - 1 + i * step) % #pool) + 1]
        local p = select(1, basePlate(asset, f, job, 0, 0))
        parts[#parts + 1] = p
        labels[#labels + 1] = { x + 2, select(2, dims(p)) + 2,
            fmt('inst%d f%d', i + 1, f), { .75, .78, .86 } }
        x = x + dims(p) + 4
    end
    return chrome(hjoin(parts, 4),
        fmt('%s · %d instâncias · base f%d step %d · z%d',
            asset.name, n, base, step, job.zoom), labels, 12)
end

-- Revisão de loop: fN e f1 lado a lado com a transição marcada —
-- a costura do ciclo é o que mais entrega animação quebrada.
function views.loop(asset, job)
    local N = asset.sheet.frames
    if N < 2 then fail('view loop: asset de 1 frame só não tem transição') end
    local set = frameSet(job, N)
    local fLast, fFirst = set[#set], set[1]
    local pa = select(1, basePlate(asset, fLast, job, 0, 0))
    local pb = select(1, basePlate(asset, fFirst, job, 0, 0))
    local strip = hjoin({ pa, pb }, 8)
    -- seta fLast->fFirst entre as células
    local wA, hA = dims(pa)
    local mx = wA + 2
    for d = 0, 4 do
        mixp(strip, mx + d, floor(hA / 2) + (d - 2), 1, .85, .25, .9)
        mixp(strip, mx + d, floor(hA / 2) - (d - 2), 1, .85, .25, .9)
    end
    return chrome(strip, fmt('%s · loop f%d→f%d · z%d',
        asset.name, fLast, fFirst, job.zoom), {
        { 2, hA + 2, fmt('f%d (último)', fLast), { .75, .78, .86 } },
        { wA + 10, hA + 2, fmt('f%d (reinício)', fFirst), { .75, .78, .86 } },
    }, 12)
end

-- Rastros de âncora por frame: trajetória completa desenhada em cada
-- célula + ponto do frame corrente destacado; marcas de contato no rodapé.
function views.tracks(asset, job)
    local N = asset.sheet.frames
    local tracks = anchorTracks(asset.def, N)
    local tem = false
    for _ in pairs(tracks) do tem = true end
    if not tem then fail('view tracks: def sem def.anchors') end
    local marks = markerSets(asset.def)
    local parts, labels, x = {}, {}, 0
    local nomes = {}
    for n in pairs(tracks) do nomes[#nomes + 1] = n end
    table.sort(nomes)
    for _, f in ipairs(frameSet(job, N)) do
        local p, _, sw, sh = basePlate(asset, f, job, 0, 0)
        local z = job.zoom
        gridLines(p, 0, 0, sw, sh, z)
        local off = (job._crop and { x = job._crop.x - 1, y = job._crop.y - 1 })
            or { x = 0, y = 0 }
        for i, nome in ipairs(nomes) do
            local t = tracks[nome]
            local c = REGION_CORES[(i - 1) % #REGION_CORES + 1]
            -- trajetória: polilinha de todos os pontos em coords desta célula
            for g = 1, N - 1 do
                local a, b = t[g], t[g + 1]
                if a and b then
                    local x0 = (a[1] - 1 - off.x) * z + floor(z / 2)
                    local y0 = (a[2] - 1 - off.y) * z + floor(z / 2)
                    local x1 = (b[1] - 1 - off.x) * z + floor(z / 2)
                    local y1 = (b[2] - 1 - off.y) * z + floor(z / 2)
                    local steps = max(abs(x1 - x0), abs(y1 - y0), 1)
                    for s = 0, steps do
                        mixp(p, x0 + (x1 - x0) * s / steps,
                            y0 + (y1 - y0) * s / steps, c[1], c[2], c[3], .55)
                    end
                end
            end
            -- ponto do frame corrente
            local q = t[f]
            if q then
                cross(p, (q[1] - 1 - off.x) * z + floor(z / 2),
                    (q[2] - 1 - off.y) * z + floor(z / 2), c[1], c[2], c[3], 5)
            end
        end
        parts[#parts + 1] = p
        local tag = 'f' .. f
        for nome, set in pairs(marks) do
            if inSet(set, f) then tag = tag .. ' [' .. nome .. ']' end
        end
        labels[#labels + 1] = { x + 2, select(2, dims(p)) + 2, tag, { .9, .7, .5 } }
        x = x + dims(p) + 4
    end
    return chrome(hjoin(parts, 4),
        fmt('%s · tracks · %s · z%d', asset.name,
            table.concat(nomes, ','), job.zoom), labels, 12)
end

function views.swatches(asset, job)
    local sw = job._swatches -- {char,spec,rgb,count,dup?}
    local rowh, w = 15, 300
    local h = max(4 + #sw * rowh, rowh + 4)
    local id = IMG.newImageData(w, h)
    fillRect(id, 0, 0, w, h, .09, .09, .12)
    local labels = {}
    for i, s in ipairs(sw) do
        local y = 3 + (i - 1) * rowh
        fillRect(id, 4, y, 12, 12, s.rgb[1], s.rgb[2], s.rgb[3])
        boxBound(id, 4, y, 15, y + 11, 0, 0, 0)
        local alerta = s.dup and '  !dup' or (s.count == 0 and '  (sem uso)' or '')
        labels[#labels + 1] = { 22, y + 2,
            fmt('%s  %-14s uso=%d%s', s.char == ' ' and '_' or s.char,
                s.spec, s.count, alerta),
            s.dup and { 1, .6, .3 } or { .82, .84, .9 } }
    end
    return chrome(id, title(asset, 'swatches', job.frame, job), labels)
end

-- Preview com a luz real do jogo: albedo/normal/emissivo em canvases de
-- cena (sprite + margem), Lighting.compose com ambiente de região + luzes
-- posicionadas em coordenadas do sprite.
function views.lit(asset, job)
    local f = job.frame == 'all' and 1 or job.frame
    local Lighting = tryRequire('src.lighting')
    if not Lighting then fail('src.lighting indisponível p/ view lit') end
    local pad = 24
    local sw, sh = asset.sheet.w, asset.sheet.h
    local W, H = sw + 2 * pad, sh + 2 * pad
    local alb = IMG.newImageData(W, H)
    paintBG(alb, job._bgLit, 0, 0, W, H)
    blitOver(alb, asset._channels.albedo[f], pad, pad)
    local nrm = IMG.newImageData(W, H)
    fillRect(nrm, 0, 0, W, H, .5, .5, 1, 1)
    blitOver(nrm, asset._channels.normal[f], pad, pad)
    local emi = IMG.newImageData(W, H)
    blitOver(emi, asset._channels.emissive[f], pad, pad)

    local L = Lighting.new(W, H)
    L:setAmbient(job._ambientRgb)
    L:beginFrame()
    for _, l in ipairs(job._lights) do
        L:addLight({ x = l.x + pad, y = l.y + pad, z = l.z, color = l.color,
            radius = l.radius, intensity = l.intensity, shadow = false })
    end
    L:update(0, false)
    local iA, iN, iE = G.newImage(alb), G.newImage(nrm), G.newImage(emi)
    local out = G.newCanvas(W, H)
    G.setCanvas(out)
    L:compose(iA, iN, iE, 0, 0)
    G.setCanvas()
    local scene = out:newImageData()
    out:release(); iA:release(); iN:release(); iE:release()

    local z = job.zoom
    local plate = IMG.newImageData(W * z, H * z)
    blitZoom(plate, scene, 0, 0, z)
    local labels = {}
    for i, l in ipairs(job._lights) do
        cross(plate, (l.x + pad) * z, (l.y + pad) * z, 1, .85, .3, 4)
        labels[#labels + 1] = { (l.x + pad) * z + 5, (l.y + pad) * z - 4,
            fmt('L%d', i), { 1, .85, .3 } }
    end
    local nota = L.enabled and '' or ' (sem shader: albedo+emissivo)'
    return chrome(plate, fmt('%s · lit · f%d/%d · amb=%s%s',
        asset.name, f, asset.sheet.frames, tostring(job.ambient), nota), labels)
end

--------------------------------------------------------------------------------
-- A/B e diff
--------------------------------------------------------------------------------

local function colorEq(a, b)
    return abs(a[1] - b[1]) < .004 and abs(a[2] - b[2]) < .004
        and abs(a[3] - b[3]) < .004 and abs(a[4] - b[4]) < .004
end

-- Mapa de pixels mudados A->B num frame: vermelho=removido, verde=
-- adicionado, amarelo=cor mudou, fantasma cinza=inalterado.
local function diffFrame(ida, idb)
    local w, h = max(dims(ida), dims(idb)), max(select(2, dims(ida)), select(2, dims(idb)))
    local out = IMG.newImageData(w, h)
    local wa, ha = dims(ida)
    local wb, hb = dims(idb)
    local st = { added = 0, removed = 0, changed = 0, same = 0,
        x0 = math.huge, y0 = math.huge, x1 = -1, y1 = -1, blocks = {} }
    for y = 0, h - 1 do for x = 0, w - 1 do
        local ca = { 0, 0, 0, 0 }
        if x < wa and y < ha then ca = { ida:getPixel(x, y) } end
        local cb = { 0, 0, 0, 0 }
        if x < wb and y < hb then cb = { idb:getPixel(x, y) } end
        local oa, ob = ca[4] > 0, cb[4] > 0
        if oa and ob and colorEq(ca, cb) then
            st.same = st.same + 1
            local l = (.299 * ca[1] + .587 * ca[2] + .114 * ca[3])
            out:setPixel(x, y, l * .4, l * .4, l * .44, .55)
        elseif oa and ob then
            st.changed = st.changed + 1
            out:setPixel(x, y, 1, .82, .15, 1)
        elseif ob then
            st.added = st.added + 1
            out:setPixel(x, y, .2, 1, .35, 1)
        elseif oa then
            st.removed = st.removed + 1
            out:setPixel(x, y, 1, .22, .22, 1)
        end
        if oa ~= ob or (oa and ob and not colorEq(ca, cb)) then
            st.x0, st.y0 = min(st.x0, x), min(st.y0, y)
            st.x1, st.y1 = max(st.x1, x), max(st.y1, y)
            local bk = fmt('%d,%d', floor(x / 8), floor(y / 8))
            st.blocks[bk] = (st.blocks[bk] or 0) + 1
        end
    end end
    if st.x1 < 0 then st.x0, st.y0, st.x1, st.y1 = 0, 0, -1, -1 end
    return out, st
end

function views.diff(asset, job)
    local B = job._B
    local frames = {}
    if job.frame == 'all' then
        for f = 1, max(asset.sheet.frames, B.sheet.frames) do frames[#frames + 1] = f end
    else frames = { job.frame } end
    local parts, labels, x = {}, {}, 0
    job._diffStats = {}
    for _, f in ipairs(frames) do
        local ida = cropID(asset._channels.albedo[min(f, asset.sheet.frames)],
            job._crop)
        local idb = cropID(B._channels.albedo[min(f, B.sheet.frames)],
            job._crop)
        local map, st = diffFrame(ida, idb)
        job._diffStats[f] = st
        local mw, mh = dims(map)
        local plate = plateFor(mw * job.zoom, mh * job.zoom, job)
        blitZoom(plate, map, 0, 0, job.zoom)
        parts[#parts + 1] = plate
        labels[#labels + 1] = { x + 2, select(2, dims(plate)) + 2,
            fmt('f%d +%d -%d ~%d', f, st.added, st.removed, st.changed), { .9, .85, .4 } }
        x = x + dims(plate) + 4
    end
    return chrome(hjoin(parts, 4), fmt('%s vs %s · diff · z%d',
        asset.name, B.name, job.zoom), labels, 12)
end

-- Par A/B com enquadramento IDÊNTICO (mesma união de dims, mesma âncora)
-- para alternar entre arquivos. Devolve {ida, idb} prontos p/ PNG.
local function blinkPlates(A, B, job)
    local f = job.frame == 'all' and 1 or job.frame
    local fb = min(f, B.sheet.frames)
    local sa = cropID(A._channels.albedo[f], job._crop)
    local sb = cropID(B._channels.albedo[fb], job._crop)
    local wa, ha = dims(sa)
    local wb, hb = dims(sb)
    local W, H = max(wa, wb), max(ha, hb)
    local z = job.zoom
    local function plate(asset, sub, sw, sh)
        local p = plateFor(W * z, H * z, job)
        local dx, dy = 0, 0
        if asset.sheet.origin == 'feet' then
            dx, dy = floor((W - sw) / 2) * z, (H - sh) * z
        end
        blitZoom(p, sub, dx, dy, z)
        return p
    end
    return plate(A, sa, wa, ha), plate(B, sb, wb, hb)
end

function views.ab(asset, job)
    local B = job._B
    local f = job.frame == 'all' and 1 or job.frame
    local pa = select(1, basePlate(asset, f, job, 0, 0))
    local pb = select(1, basePlate(B, min(f, B.sheet.frames), job, 0, 0))
    local strip = hjoin({ pa, pb }, 8)
    local wA = dims(pa)
    local id = strip
    -- contador Δ no rodapé vem do diff do mesmo frame
    local _, st = diffFrame(
        cropID(asset._channels.albedo[f], job._crop),
        cropID(B._channels.albedo[min(f, B.sheet.frames)], job._crop))
    local delta = st.added + st.removed + st.changed
    return chrome(id, fmt('A:%s | B:%s · f%d · z%d · Δ=%dpx',
        asset.name, B.name, f, job.zoom, delta), {
        { 2, select(2, dims(id)) + 2, 'A ' .. asset.name, { .6, .85, 1 } },
        { wA + 10, select(2, dims(id)) + 2, 'B ' .. B.name, { 1, .8, .5 } },
    }, 12)
end

--------------------------------------------------------------------------------
-- Diagnósticos (avisos de arte separados de erros duros)
--------------------------------------------------------------------------------

local function inspectFrames(asset, job, note)
    local w, h = asset.sheet.w, asset.sheet.h
    for f = 1, asset.sheet.frames do
        local id = asset._channels.albedo[f]
        local nid = asset._channels.normal[f]
        local eid = asset._channels.emissive[f]
        local iso = 0
        local ncores, emis, steep = {}, 0, 0
        local opacos = 0
        for y = 0, h - 1 do for x = 0, w - 1 do
            local r, g, b, a = id:getPixel(x, y)
            if a > 0 then
                opacos = opacos + 1
                ncores[fmt('%.3f,%.3f,%.3f', r, g, b)] = true
                local vizinho, interior = false, true
                for dy = -1, 1 do for dx = -1, 1 do
                    if (dx ~= 0 or dy ~= 0) then
                        local nx, ny = x + dx, y + dy
                        if nx >= 0 and ny >= 0 and nx < w and ny < h then
                            local _, _, _, na = id:getPixel(nx, ny)
                            if na > 0 then vizinho = true
                            elseif abs(dx) + abs(dy) == 1 then interior = false end
                        elseif abs(dx) + abs(dy) == 1 then interior = false end
                    end
                end end
                if not vizinho then
                    iso = iso + 1
                    if iso <= 30 then
                        note('WARN', { frame = f, coord = { x + 1, y + 1 },
                            region = regionAt(asset.def, x + 1, y + 1),
                            reason = 'pixel isolado' })
                    end
                end
                local _, _, _, ea = eid:getPixel(x, y)
                if ea > 0 then emis = emis + 1 end
                -- normal decodificado: nz<0.15 ≈ degrau de altura >=4 num
                -- pixel só (strength 2.0). Só conta em pixel INTERIOR — na
                -- borda da silhueta o degrau pro vazio é do contrato.
                if interior then
                    local _, _, nb, na = nid:getPixel(x, y)
                    if na > 0 and nb * 2 - 1 < .15 then steep = steep + 1 end
                end
            end
        end end
        if iso > 30 then
            note('WARN', { frame = f, reason = fmt('mais %d pixels isolados', iso - 30) })
        end
        local nc = 0
        for _ in pairs(ncores) do nc = nc + 1 end
        local b = asset._bbox[f]
        if b then
            note('INFO', { frame = f, reason = fmt('bbox=%d,%d %dx%d opacos=%d cores=%d',
                b.x, b.y, b.w, b.h, opacos, nc) })
        end
        if asset.sheet.origin == 'feet' and b
            and (b.x == 1 or b.y == 1 or b.x + b.w - 1 == w or b.y + b.h - 1 == h) then
            note('WARN', { frame = f, coord = { b.x, b.y },
                reason = 'silhueta toca a borda do frame' })
        end
        if opacos > 0 and emis / opacos > .25 then
            note('WARN', { frame = f, reason = fmt(
                'cobertura emissiva alta (%.0f%% dos opacos)', emis / opacos * 100) })
        end
        if steep > 0 then
            note('WARN', { frame = f, reason = fmt(
                '%d normais interiores exageradas (nz<0.15)', steep) })
        end
        if job.budget and nc > job.budget then
            note('WARN', { frame = f, reason = fmt(
                'orçamento de cores estourado: %d > %d', nc, job.budget) })
        end
    end
end

-- Diagnósticos de movimento (apoio W4): rastros de âncora, drift em
-- frames de contato, costura do loop e flicker por transição.
local function motionDiagnostics(asset, job, note)
    local N = asset.sheet.frames
    if N < 2 then return end
    local def = asset.def
    local tracks = anchorTracks(def, N)
    local marks = markerSets(def)
    local set = frameSet(job, N)

    -- sanidade dos metadados
    for nome, fs in pairs(marks) do
        for _, f in ipairs(fs) do
            if f < 1 or f > N then
                note('WARN', { reason = fmt("marker '%s' aponta frame %d fora de 1..%d",
                    nome, f, N) })
            end
        end
    end
    for nome, s in pairs(seqSets(def)) do
        if not (s.first and s.last) or s.first < 1 or s.last > N or s.first > s.last then
            note('WARN', { reason = fmt("sequência '%s' inválida (%s..%s de 1..%d)",
                nome, tostring(s.first), tostring(s.last), N) })
        else
            note('INFO', { reason = fmt('seq %s f%d..f%d loop=%s',
                nome, s.first, s.last, tostring(s.loop ~= false)) })
        end
    end

    -- rastros: salto entre frames e deriva dentro de contato
    for nome, t in pairs(tracks) do
        local caminho = 0
        for i = 2, N do
            local a, b = t[i - 1], t[i]
            if a and b then
                local d = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
                caminho = caminho + d
                if d > 4 then
                    note('WARN', { frame = i, coord = { b[1], b[2] },
                        reason = fmt("âncora '%s' salta %.1fpx f%d→f%d",
                            nome, d, i - 1, i) })
                end
            end
        end
        for f = 1, N do
            local q = t[f]
            if q and (q[1] < 1 or q[2] < 1
                or q[1] > asset.sheet.w or q[2] > asset.sheet.h) then
                note('WARN', { frame = f, coord = { q[1], q[2] },
                    reason = fmt("âncora '%s' fora do frame", nome) })
            end
        end
        note('INFO', { reason = fmt(
            "âncora '%s': trajetória %.1fpx em %d frames", nome, caminho, N) })
        -- drift em frames de contato consecutivos: o pé não escorrega?
        local contato = marks.contact
        if contato then
            for i = 2, #contato do
                local fa, fb = contato[i - 1], contato[i]
                if t[fa] and t[fb] then
                    local d = math.sqrt((t[fb][1] - t[fa][1]) ^ 2
                        + (t[fb][2] - t[fa][2]) ^ 2)
                    if d > 1 then
                        note('WARN', { frame = fb, coord = { t[fb][1], t[fb][2] },
                            reason = fmt("âncora '%s' deriva %.1fpx entre contatos f%d→f%d",
                                nome, d, fa, fb) })
                    end
                end
            end
        end
    end

    -- flicker por transição + costura do loop (delta percentual de pixels)
    local opacos = 0
    for y = 0, asset.sheet.h - 1 do for x = 0, asset.sheet.w - 1 do
        local _, _, _, a = asset._channels.albedo[1]:getPixel(x, y)
        if a > 0 then opacos = opacos + 1 end
    end end
    local trans = {}
    for i = 2, #set do
        local fa, fb = set[i - 1], set[i]
        local _, st = diffFrame(asset._channels.albedo[fa],
            asset._channels.albedo[fb])
        trans[#trans + 1] = { fa = fa, fb = fb, n = st.added + st.removed + st.changed }
    end
    -- costura: último -> primeiro da seleção
    do
        local fa, fb = set[#set], set[1]
        if fa ~= fb then
            local _, st = diffFrame(asset._channels.albedo[fa],
                asset._channels.albedo[fb])
            local n = st.added + st.removed + st.changed
            trans[#trans + 1] = { fa = fa, fb = fb, n = n, costura = true }
        end
    end
    table.sort(trans, function(a, b) return a.n > b.n end)
    for i = 1, min(4, #trans) do
        local t = trans[i]
        local pct = opacos > 0 and (t.n / opacos * 100) or 0
        local sev = (t.costura and pct > 40) and 'WARN' or 'INFO'
        note(sev, { reason = fmt('%stransição f%d→f%d: %d px mudados (%.0f%% dos opacos)%s',
            t.costura and 'costura ' or '', t.fa, t.fb, t.n, pct,
            t.costura and pct > 40 and ' — loop brusco' or '') })
    end
end

-- Conta chars por canal de grade (string ou array) — parse mínimo:
-- ignora whitespace e '.', que nunca são pixel.
local function countChars(channel)
    local per = {}
    if type(channel) == 'string' then channel = { channel } end
    for f, s in ipairs(channel or {}) do
        local t = {}
        for c in s:gmatch('.') do
            if c ~= '.' and not c:match('%s') then t[c] = (t[c] or 0) + 1 end
        end
        per[f] = t
    end
    return per
end

local function swatchTable(asset, job, note)
    local P = PAL()
    -- uso por char em todos os canais de todos os layers/frames
    local uso = {}
    for _, l in ipairs(asset.def.layers) do
        for _, canal in ipairs({ 'albedo', 'emissive' }) do
            for _, t in pairs(countChars(l[canal])) do
                for c, n in pairs(t) do uso[c] = (uso[c] or 0) + n end
            end
        end
    end
    local porCor, porSpec = {}, {}
    local sw = {}
    for ch, e in pairs(asset.def.legend) do
        local spec, h, es, ei
        if type(e) == 'string' then spec = e
        elseif type(e) == 'table' then
            spec = e.spec or (e.ramp and (tostring(e.ramp) .. '.' .. tostring(e.step or 1)))
            h, es, ei = e.h, e.e, e.ei
        end
        local rgb
        if spec then
            local ok, c = pcall(P.resolve, spec)
            if ok then rgb = { c[1], c[2], c[3] }
            else note('ERROR', { reason = fmt("legend['%s']: %s", ch, tostring(c)) }) end
        end
        local row = { char = ch, spec = spec or '?', rgb = rgb or { .5, 0, .5 },
            count = uso[ch] or 0 }
        if rgb then
            local ck = fmt('%.4f,%.4f,%.4f', rgb[1], rgb[2], rgb[3])
            -- "redundante" de verdade = mesma cor E mesmos canais (h/e/ei);
            -- mesma cor com canal diferente é ferramenta de autoria.
            local fk = ck .. '|' .. tostring(h) .. '|' .. tostring(es)
                .. '|' .. tostring(ei)
            porCor[ck] = porCor[ck] or {}
            table.insert(porCor[ck], ch)
            porSpec[fk] = porSpec[fk] or {}
            table.insert(porSpec[fk], ch)
            row._corKey = fk
        end
        if (uso[ch] or 0) == 0 then
            note('INFO', { reason = fmt("char '%s' da legend sem uso", ch) })
        end
        sw[#sw + 1] = row
    end
    local function charsDe(lista)
        local q = {}
        for _, c in ipairs(lista) do q[#q + 1] = "'" .. c .. "'" end
        return table.concat(q, ',')
    end
    for k, chars in pairs(porSpec) do
        if #chars > 1 then
            for _, s in ipairs(sw) do
                if s._corKey == k then s.dup = true end
            end
            note('WARN', { reason = fmt('cores redundantes: chars %s idênticos (%s)',
                charsDe(chars), k) })
        end
    end
    for k, chars in pairs(porCor) do
        if #chars > 1 then
            local identicos = false
            for fk, l in pairs(porSpec) do
                if fk:sub(1, #k) == k and #l == #chars then identicos = true end
            end
            if not identicos then
                note('INFO', { reason = fmt(
                    'chars %s dividem a cor %s com canais distintos (h/e)',
                    charsDe(chars), k) })
            end
        end
    end
    table.sort(sw, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.char < b.char
    end)
    return sw
end

--------------------------------------------------------------------------------
-- Job
--------------------------------------------------------------------------------

local VIEW_NAMES = {
    'albedo', 'normal', 'emissive', 'luminance', 'silhouette', 'channels',
    'grid', 'crop', 'swatches', 'tile', 'lit', 'ab', 'diff', 'blink',
    'frames', 'onion', 'seq', 'instances', 'loop', 'tracks', 'dump',
}
local VIEW_SET = {}
for _, v in ipairs(VIEW_NAMES) do VIEW_SET[v] = true end

local function normJob(job)
    job = job or {}
    job.frame = job.frame or 1
    job.zoom = max(1, floor(job.zoom or 4))
    assert(job.zoom <= 16, 'zoom máximo 16')
    job.views = job.views or { 'albedo', 'channels', 'grid', 'swatches' }
    job.tile = max(2, floor(job.tile or 3))
    job.seed = job.seed or 0
    job.bg = job.bg or 'checker'
    job.ambient = job.ambient or 'neutro'
    return job
end

local function parseMask(def, name)
    local g = type(def.masks) == 'table' and def.masks[name]
    if not g then return nil end
    if type(g) == 'table' and g.rows then return g end -- grade do pixel_kit
    if type(g) ~= 'string' then return nil end
    -- grade em string: linhas separadas por \n
    local rows, w = {}, 0
    for line in (g .. '\n'):gmatch('(.-)\n') do
        if line:match('%S') then
            rows[#rows + 1] = {}
            for x = 1, #line do rows[#rows][x] = line:sub(x, x) end
            w = max(w, #line)
        end
    end
    return { w = w, h = #rows, rows = rows }
end

-- Executa o job inteiro; devolve {paths, findings, warnings, errors, exit}.
function M.run(job)
    job = normJob(job)
    local findings, paths = {}, {}
    local nWarn, nErr = 0, 0
    local function note(sev, t)
        if sev == 'WARN' then nWarn = nWarn + 1
        elseif sev == 'ERROR' then nErr = nErr + 1 end
        t.sev = sev
        findings[#findings + 1] = t
    end
    local reportPath = job.report
    local function finish(outName)
        reportPath = reportPath or fmt('screenshots/%s-report.txt', outName or 'wb-erro')
        local f = io.open(reportPath, 'w')
        if f then
            f:write(M.formatReport(job, findings, paths, reportPath))
            f:close()
        end
        local exit = (nErr > 0) and 1 or (job.strict and nWarn > 0) and 2 or 0
        return { paths = paths, findings = findings, warnings = nWarn,
            errors = nErr, exit = exit, report = reportPath }
    end

    -- asset A
    local okA, A = pcall(M.loadAsset, job.asset)
    if not okA then
        note('ERROR', { reason = tostring(A) })
        local seguro = (type(job.out) == 'string'
            and job.out:match('^[%w_%-]+$')) and job.out or 'wb-erro'
        return finish(seguro)
    end
    job._out = job.out or ('wb-' .. A.name)
    if not job._out:match('^[%w_%-]+$') then
        note('ERROR', { reason = "--out precisa ser [%w_-]+: '" .. tostring(job._out) .. "'" })
        return finish('wb-erro')
    end
    if job.report and not job.report:match('^screenshots/[%w_%.%-]+$') then
        note('ERROR', { reason = "--report precisa ficar em screenshots/: '" .. tostring(job.report) .. "'" })
        return finish('wb-erro')
    end
    local okBg, bgOrErr = pcall(bgFor, job.bg, job)
    if not okBg then
        note('ERROR', { reason = tostring(bgOrErr) })
        return finish(job._out)
    end
    job._bg = bgOrErr
    job._bgLit = (job.bg and job.bg ~= 'checker')
        and job._bg or { kind = 'solid', rgb = { .09, .09, .12 } }
    -- ambient da view lit
    if type(job.ambient) == 'table' then
        job._ambientRgb = job.ambient
    else
        job._ambientRgb = HD().ambient(job.ambient)
    end
    job._lights = {}
    for i, l in ipairs(job.light or {}) do
        job._lights[i] = {
            x = l.x or A.sheet.w / 2, y = l.y or A.sheet.h / 4, z = l.z or 48,
            radius = l.radius or max(A.sheet.w, A.sheet.h) * 1.2,
            intensity = l.intensity or 1,
            color = l.color or { 1, .78, .5 } }
    end
    if #job._lights == 0 then
        job._lights[1] = { x = A.sheet.w * .2, y = A.sheet.h * .05, z = 56,
            radius = max(A.sheet.w, A.sheet.h) * 1.4, intensity = 1,
            color = { 1, .78, .5 }, _default = true }
    end
    -- canais por frame
    A._channels = { albedo = {}, normal = {}, emissive = {} }
    A._bbox = {}
    for f = 1, A.sheet.frames do
        A._channels.albedo[f] = frameID(A.sheet, 'albedo', f)
        A._channels.normal[f] = frameID(A.sheet, 'normal', f)
        A._channels.emissive[f] = frameID(A.sheet, 'emissive', f)
        A._bbox[f] = bboxOf(A._channels.albedo[f])
    end
    -- recorte
    if job.region then
        local r
        for _, rr in ipairs(regionList(A.def)) do
            if rr.name == job.region then r = rr end
        end
        if not r then
            note('ERROR', { reason = fmt("região '%s' não existe em def.regions", job.region) })
            return finish(job._out)
        end
        job._crop = { x = r.x, y = r.y, w = r.w, h = r.h }
        job._cropExplicit = true
    elseif job.crop then
        job._crop = { x = job.crop.x, y = job.crop.y, w = job.crop.w, h = job.crop.h }
        job._cropExplicit = true
    end
    if job._crop then
        local c = job._crop
        c.x = max(1, c.x); c.y = max(1, c.y)
        c.w = min(c.w, A.sheet.w - c.x + 1)
        c.h = min(c.h, A.sheet.h - c.y + 1)
        if c.w < 1 or c.h < 1 then
            note('ERROR', { reason = 'crop fora do frame' })
            return finish(job._out)
        end
    end
    if job.mask then
        job._maskGrid = parseMask(A.def, job.mask)
        if not job._maskGrid then
            note('WARN', { reason = fmt("mask '%s' não existe em def.masks", job.mask) })
        end
    end
    -- frame alvo
    if job.frame ~= 'all' then
        job.frame = floor(job.frame)
        if job.frame < 1 or job.frame > A.sheet.frames then
            note('ERROR', { reason = fmt('frame %s fora de 1..%d',
                tostring(job.frame), A.sheet.frames) })
            return finish(job._out)
        end
    end
    note('INFO', { reason = fmt('asset=%s source=%s w=%d h=%d frames=%d origin=%s',
        A.name, A.source, A.sheet.w, A.sheet.h, A.sheet.frames, A.sheet.origin) })

    -- asset B (ab/diff)
    if job.vs then
        local okB, B = pcall(M.loadAsset, job.vs)
        if not okB then
            note('ERROR', { reason = tostring(B) })
            return finish(job._out)
        end
        B._channels = { albedo = {} }
        for f = 1, B.sheet.frames do
            B._channels.albedo[f] = frameID(B.sheet, 'albedo', f)
        end
        job._B = B
        note('INFO', { reason = fmt('vs=%s source=%s w=%d h=%d frames=%d',
            B.name, B.source, B.sheet.w, B.sheet.h, B.sheet.frames) })
        if B.sheet.w ~= A.sheet.w or B.sheet.h ~= A.sheet.h then
            note('WARN', { reason = fmt('dimensões divergentes: A=%dx%d B=%dx%d',
                A.sheet.w, A.sheet.h, B.sheet.w, B.sheet.h) })
        end
    end

    -- conjunto de frames da seleção animada (--seq de índices/sequências)
    if job.seq then
        local okS, setOrErr = pcall(resolveSeq, A.def, job.seq, A.sheet.frames)
        if not okS then
            note('ERROR', { reason = tostring(setOrErr) })
            return finish(job._out)
        end
        job._frameSet = setOrErr
    end

    -- diagnósticos de arte (avisos) antes das views
    job._swatches = swatchTable(A, job, note)
    inspectFrames(A, job, note)
    motionDiagnostics(A, job, note)

    -- views
    for _, v in ipairs(job.views) do
        if not VIEW_SET[v] then
            note('ERROR', { reason = fmt("view desconhecida '%s' (válidas: %s)",
                v, table.concat(VIEW_NAMES, ',')) })
        elseif (v == 'ab' or v == 'diff' or v == 'blink') and not job._B then
            note('ERROR', { reason = fmt("view '%s' precisa de vs=", v) })
        elseif v == 'blink' then
            -- par A/B com enquadramento idêntico p/ alternar entre arquivos
            local f = job.frame == 'all' and 1 or job.frame
            local pa, pb = blinkPlates(A, job._B, job)
            pa = chrome(pa, fmt('A:%s · f%d · blink · z%d',
                A.name, f, job.zoom))
            pb = chrome(pb, fmt('B:%s · f%d · blink · z%d',
                job._B.name, min(f, job._B.sheet.frames), job.zoom))
            for _, t in ipairs({ { pa, 'A' }, { pb, 'B' } }) do
                local p = fmt('screenshots/%s-blink-%s-z%d.png',
                    job._out, t[2], job.zoom)
                local fh = assert(io.open(p, 'wb'))
                fh:write(t[1]:encode('png'):getString())
                fh:close()
                paths[#paths + 1] = p
                note('INFO', { reason = fmt('view=blink path=%s', p) })
            end
        elseif v == 'dump' then
            for _, ch in ipairs({ 'albedo', 'normal', 'emissive' }) do
                local p = fmt('screenshots/%s-%s.png', job._out, ch)
                local f = assert(io.open(p, 'wb'))
                f:write(A.sheet.imageData[ch]:encode('png'):getString())
                f:close()
                paths[#paths + 1] = p
                note('INFO', { reason = fmt('dump %s', p) })
            end
        else
            local okv, id = pcall(views[v], A, job)
            if not okv then
                -- view que morreu no meio pode deixar canvas/shader bound
                G.setCanvas()
                G.setShader()
                note('ERROR', { reason = fmt("view %s falhou: %s", v, tostring(id)) })
            else
                local suf = fmt('%s-%s-z%d', job._out, v, job.zoom)
                local p = fmt('screenshots/%s.png', suf)
                local f = assert(io.open(p, 'wb'))
                f:write(id:encode('png'):getString())
                f:close()
                paths[#paths + 1] = p
                note('INFO', { reason = fmt('view=%s path=%s', v, p) })
            end
        end
    end
    -- achados do diff vão para o relatório
    if job._diffStats then
        for f, st in pairs(job._diffStats) do
            local total = st.added + st.removed + st.changed
            note('INFO', { frame = f, reason = fmt(
                'diff: +%d adicionados -%d removidos ~%d mudados (=%d)',
                st.added, st.removed, st.changed, total) })
            if st.x1 >= 0 then
                note('INFO', { frame = f, reason = fmt(
                    'diff bbox=%d,%d..%d,%d (autoria 1-based)',
                    st.x0 + 1, st.y0 + 1, st.x1 + 1, st.y1 + 1) })
            end
            local bl = {}
            for k, n in pairs(st.blocks) do bl[#bl + 1] = { k = k, n = n } end
            table.sort(bl, function(a, b) return a.n > b.n end)
            for i = 1, min(5, #bl) do
                local bx, by = bl[i].k:match('(%-?%d+),(%-?%d+)')
                local cx, cy = tonumber(bx) * 8 + 1, tonumber(by) * 8 + 1
                note('INFO', { frame = f,
                    coord = { cx, cy },
                    region = regionAt(A.def, cx, cy),
                    reason = fmt('bloco quente do diff (%d px mudados no bloco 8x8)', bl[i].n) })
            end
        end
    end
    return finish(job._out)
end

-- Relatório compacto: um fato por linha, greppável. SEV = INFO|WARN|ERROR.
function M.formatReport(job, findings, paths, reportPath)
    local L = { '# kit_workbench report' }
    for _, t in ipairs(findings) do
        local parts = { t.sev }
        if t.frame then parts[#parts + 1] = 'frame=' .. t.frame end
        if t.coord then parts[#parts + 1] = fmt('coord=%d,%d', t.coord[1], t.coord[2]) end
        if t.region then parts[#parts + 1] = 'region=' .. t.region end
        if t.layer then parts[#parts + 1] = 'layer=' .. t.layer end
        parts[#parts + 1] = 'reason="' .. (t.reason or '?') .. '"'
        L[#L + 1] = table.concat(parts, ' ')
    end
    local w, e = 0, 0
    for _, t in ipairs(findings) do
        if t.sev == 'WARN' then w = w + 1 elseif t.sev == 'ERROR' then e = e + 1 end
    end
    L[#L + 1] = fmt('SUMMARY views=%d warnings=%d errors=%d report=%s',
        #paths, w, e, reportPath or '?')
    return table.concat(L, '\n') .. '\n'
end

-- Playback interativo básico (humano; agentes usam as capturas). Devolve
-- um controlador com update/draw/key. Duração por frame: def.frameDuration
-- (segundos, escalar ou array) ou 1/fps. Teclas: espaço=pausa, ←/→=passo,
-- ↑/↓=fps, esc=sai.
function M.play(ref, opts)
    opts = opts or {}
    local A = M.loadAsset(ref)
    A._channels = { albedo = {} }
    local imgs = {}
    for f = 1, A.sheet.frames do
        A._channels.albedo[f] = frameID(A.sheet, 'albedo', f)
        local img = G.newImage(A._channels.albedo[f])
        img:setFilter('nearest', 'nearest')
        imgs[f] = img
    end
    -- fila de frames: --seq (índices/sequências nomeadas) ou o ciclo todo
    local frames = opts.seq and resolveSeq(A.def, opts.seq, A.sheet.frames)
        or nil
    if not frames then
        frames = {}
        for f = 1, A.sheet.frames do frames[f] = f end
    end
    local dur = A.def.frameDuration or A.def.durations
    local ctrl = {
        A = A, imgs = imgs, frames = frames, pos = 1, t = 0, playing = true,
        fps = opts.fps or 8, zoom = opts.zoom or 4,
    }
    function ctrl.frame() return ctrl.frames[ctrl.pos] end
    local function durOf(f)
        if type(dur) == 'number' then return dur end
        if type(dur) == 'table' then return dur[f] or dur[1] or 1 / ctrl.fps end
        return 1 / ctrl.fps
    end
    function ctrl.update(dt)
        if not ctrl.playing then return end
        ctrl.t = ctrl.t + dt
        local d = durOf(ctrl.frame())
        while ctrl.t >= d do
            ctrl.t = ctrl.t - d
            ctrl.pos = ctrl.pos % #ctrl.frames + 1
            d = durOf(ctrl.frame())
        end
    end
    function ctrl.draw()
        local ww, wh = G.getDimensions()
        -- xadrez de fundo
        for y = 0, wh - 1, 24 do for x = 0, ww - 1, 24 do
            local v = ((x / 24) + (y / 24)) % 2 == 0 and .16 or .10
            G.setColor(v, v, v * 1.1)
            G.rectangle('fill', x, y, 24, 24)
        end end
        local img = imgs[ctrl.frame()]
        local z = ctrl.zoom
        G.setColor(1, 1, 1)
        G.draw(img, floor((ww - A.sheet.w * z) / 2),
            floor((wh - A.sheet.h * z) / 2), 0, z, z)
        G.setColor(.8, .82, .9)
        G.print(fmt('%s · f%d/%d · %.1ffps%s · espaço=pausa ←→=passo ↑↓=fps',
            A.name, ctrl.frame(), A.sheet.frames, ctrl.fps,
            ctrl.playing and '' or ' [PAUSA]'), 10, wh - 20)
    end
    function ctrl.key(k)
        if k == 'escape' then love.event.quit(0)
        elseif k == 'space' then ctrl.playing = not ctrl.playing
        elseif k == 'right' then ctrl.pos = ctrl.pos % #ctrl.frames + 1; ctrl.t = 0
        elseif k == 'left' then ctrl.pos = (ctrl.pos - 2) % #ctrl.frames + 1; ctrl.t = 0
        elseif k == 'up' then ctrl.fps = min(60, ctrl.fps * 2)
        elseif k == 'down' then ctrl.fps = max(.5, ctrl.fps / 2)
        end
    end
    return ctrl
end

-- Check compacto executável: duas defs em memória (A e B com 3 pixels
-- mudados), roda views puras + diff e confere contagens e arquivos.
function M.selfCheck()
    local K = require('src.pixel_kit')
    local function mkdef(nome, extra)
        local g = K.new(16, 16)
        K.rect(g, 4, 4, 9, 9, 'a')
        K.rect(g, 6, 6, 3, 3, 'b')
        if extra then extra(g) end
        return { name = nome, w = 16, h = 16, origin = 'topleft',
            legend = { a = 'stone.3', b = 'stone.6' },
            layers = { K.layer('l', g) } }
    end
    local defA = mkdef('wbself_a')
    local defB = mkdef('wbself_b', function(g)
        K.pixel(g, 4, 4, 'b')  -- mudado
        K.pixel(g, 15, 15, 'b') -- adicionado (era '.')
        g.rows[5][5] = '.'     -- removido
    end)
    -- def animada de 3 frames p/ frames+onion+tracks+loop: âncora 'pe'
    -- desliza 1px/quadro (deriva 2px entre contatos f1 e f3 -> WARN)
    local g1, g2, g3 = K.new(8, 8), K.new(8, 8), K.new(8, 8)
    K.rect(g1, 2, 2, 4, 4, 'a'); K.rect(g2, 3, 2, 4, 4, 'a'); K.rect(g3, 4, 2, 4, 4, 'a')
    local defAnim = { name = 'wbself_anim', w = 8, h = 8, origin = 'topleft',
        legend = { a = 'stone.3' },
        anchors = { pe = { { 3, 6 }, { 4, 6 }, { 5, 6 } } },
        markers = { contact = { 1, 3 } },
        sequences = { ciclo = { 1, 3 } },
        layers = { { name = 'l', albedo = { K.string(g1), K.string(g2), K.string(g3) } } } }
    local r = M.run{
        asset = defA, vs = defB, zoom = 3, frame = 1,
        views = { 'albedo', 'grid', 'swatches', 'diff', 'ab', 'blink',
            'luminance', 'silhouette', 'channels', 'tile', 'dump' },
        out = 'wb-selftest', tile = 2, seed = 1,
        report = 'screenshots/wb-selftest-report.txt',
    }
    assert(r.errors == 0, 'selfcheck: erros no job')
    local diffLine
    for _, t in ipairs(r.findings) do
        if t.reason and t.reason:match('^diff:') then diffLine = t.reason end
    end
    assert(diffLine and diffLine:match('%+1 adicionados %-1 removidos ~1 mudados'),
        'selfcheck: contagens do diff erradas: ' .. tostring(diffLine))
    for _, p in ipairs(r.paths) do
        local f = io.open(p, 'rb')
        assert(f, 'selfcheck: faltou ' .. p)
        assert(f:read(4) == '\137PNG', 'selfcheck: ' .. p .. ' não é PNG')
        f:close()
    end
    local rep = assert(io.open(r.report, 'r'))
    assert(rep:read('*a'):match('SUMMARY'), 'selfcheck: relatório sem SUMMARY')
    rep:close()

    -- views animadas na def de 3 frames + par blink existente
    local r2 = M.run{
        asset = defAnim, zoom = 4, frame = 'all', seq = { 'ciclo' },
        views = { 'frames', 'onion', 'seq', 'instances', 'loop', 'tracks' },
        instances = 3, phase = 1,
        out = 'wb-selftest-anim',
        report = 'screenshots/wb-selftest-anim-report.txt',
    }
    assert(r2.errors == 0, 'selfcheck: views animadas falharam')
    local temDrift, temSeq, temCostura = false, false, false
    for _, t in ipairs(r2.findings) do
        if t.reason and t.reason:match("deriva") then temDrift = true end
        if t.reason and t.reason:match('^seq ciclo') then temSeq = true end
        if t.reason and t.reason:match('^costura') then temCostura = true end
    end
    assert(temDrift, 'selfcheck: drift de âncora não reportado')
    assert(temSeq, 'selfcheck: sequência não reportada')
    assert(temCostura, 'selfcheck: costura de loop não medida')
    for _, p in ipairs(r2.paths) do
        local f = assert(io.open(p, 'rb'))
        assert(f:read(4) == '\137PNG', 'selfcheck: ' .. p .. ' não é PNG')
        f:close()
    end
    for _, p in ipairs(r2.paths) do r.paths[#r.paths + 1] = p end
    return r
end

return M
