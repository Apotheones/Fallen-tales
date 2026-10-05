-- mapshot — visão-de-deus dos mapas (docs/KIT_WORKFLOW.md §9).
-- Diagnóstico para quem edita src/regions/*.lua às cegas: o mapa inteiro
-- em PNG, esquemático ou com a arte real, fora da câmera de 1120x800.
--
-- Uso (da raiz do projeto):
--   lovec tools/mapshot --map=hub [--mode=scheme|albedo|all]
--   lovec tools/mapshot --map=hub --stamp=screenshots/captura.png
--       [--pos=x,y | --cam=wx,wy]
--
-- Opções:
--   --map=ID|--region=ID   região em src/regions (obrigatório nos modos
--                          de mapa; no stamp só p/ deduzir câmera via --pos)
--   --legacy               hub carrega src.regions.hub_legacy
--   --mode=MODO            scheme | albedo | all (default all)
--   --cellpx=N             px por célula no scheme (default 18)
--   --stamp=ARQ.png        carimba captura existente com grade 64px+coords
--   --pos=x,y              célula do jogador → câmera deduzida (clamp do jogo)
--   --cam=wx,wy            canto sup-esq da vista em px de mundo (direto)
--   --out=PREFIXO          prefixo de saída (default mapshot-<map|base>)
--
-- Saídas em screenshots/:
--   mapshot-<id>-scheme.png   diagrama top-down (~16-24px/cél)
--   mapshot-<id>-albedo.png   mapa composto com as sheets reais
--   mapshot-<base>-stamped.png captura + grade de células + coords
--
-- Exit: 0 ok · 1 erro (vai p/ screenshots/mapshot-erro.txt — headless no
-- Windows não mostra console).

local function die(msg)
    local f = io.open('screenshots/mapshot-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    print(msg)
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end
function love.errorhandler(msg) die(msg) return function() return 1 end end

local G = love.graphics
local Region, HDWorld

local function saveCanvas(canvas, path)
    local fd = canvas:newImageData():encode('png')
    local f = assert(io.open(path, 'wb'))
    f:write(fd:getString()); f:close()
    print('[mapshot] ok ' .. path)
end

-- ── scheme ───────────────────────────────────────────────────────────
-- Top-down por célula: piso por floorKind (mesma classificação do
-- render), peças como massa, props como glyph+rótulo, paths/zones/
-- spawn/arrivals/exits marcados, grade com coordenadas nos eixos.

local FLOOR_COLOR = {
    laje = {.46, .47, .53}, terra = {.58, .44, .28},
    grama = {.32, .50, .27}, caminho = {.76, .58, .34},
    arena = {.44, .40, .36}, horta = {.36, .54, .30},
    tabua = {.58, .45, .30}, colina_grama = {.33, .42, .32},
    colina_laje = {.38, .38, .50},
}
local PROP_FOGO = {braseiro = 1, tocha = 1, lampiao = 1, vela = 1,
    velas = 1, fogao = 1, chamine = 1, brasaForja = 1, bigorna = 1,
    marco = 1, postoVigia = 1}
local PROP_AGUA = {poco = 1, cisterna = 1, pocoRua = 1}
local ZONE_LINE = {stone = {.8, .8, .9}, grass = {.4, .8, .4},
    gravel = {.8, .6, .3}, earth = {.8, .6, .3}}

local function scheme(map, o)
    local cp = o.cellpx
    local MX, MY = 42, 36
    local W = MX + map.w * cp + 14
    local H = MY + map.h * cp + 58
    local cv = G.newCanvas(W, H)
    local fS = G.newFont(8)   -- rótulos de prop/npc
    local fM = G.newFont(10)  -- eixos, exits, zones
    local fT = G.newFont(13)  -- título
    G.setCanvas(cv)
    G.clear(.06, .065, .09, 1)
    local function cell(x) return MX + (x - 1) * cp end
    local function celly(y) return MY + (y - 1) * cp end
    local function text(s, x, y, c)
        G.setColor(0, 0, 0, .8); G.print(s, x + 1, y + 1)
        G.setColor(c or {1, 1, 1, 1}); G.print(s, x, y)
    end

    -- células: peça > buraco > piso > vazio
    for y = 1, map.h do
        for x = 1, map.w do
            local t = map.tiles[x .. ':' .. y]
            local c
            if t then
                if t.piece == 'wall' then c = {.17, .18, .24}
                elseif t.piece == 'pillar' then c = {.52, .48, .58}
                elseif t.piece == 'portal' then c = {.88, .55, .20}
                elseif t.ground == 'hole' then c = {0, 0, 0}
                else c = FLOOR_COLOR[HDWorld.floorKind(map, x, y)]
                    or {.40, .40, .44} end
            else c = {.05, .05, .08} end
            G.setColor(c[1], c[2], c[3], 1)
            G.rectangle('fill', cell(x), celly(y), cp, cp)
        end
    end

    -- grade de célula + coordenadas nos eixos (1-based, como o def)
    for x = 1, map.w do
        local a = x % 5 == 1 and .28 or .08
        G.setColor(1, 1, 1, a); G.line(cell(x), MY, cell(x), celly(map.h) + cp)
    end
    G.setColor(1, 1, 1, .28); G.line(cell(map.w) + cp, MY, cell(map.w) + cp, celly(map.h) + cp)
    for y = 1, map.h do
        local a = y % 5 == 1 and .28 or .08
        G.setColor(1, 1, 1, a); G.line(MX, celly(y), cell(map.w) + cp, celly(y))
    end
    G.setColor(1, 1, 1, .28); G.line(MX, celly(map.h) + cp, cell(map.w) + cp, celly(map.h) + cp)
    G.setFont(fM)
    for x = 1, map.w do
        if x % 5 == 1 or x == map.w then
            text(tostring(x), cell(x) + 1, MY - 12, {.8, .8, .85})
        end
    end
    for y = 1, map.h do
        if y % 5 == 1 or y == map.h then
            text(tostring(y), MX - 26, celly(y) + cp / 2 - 5, {.8, .8, .85})
        end
    end

    -- ruas pintadas (mesma convenção do render: vértice em célula,
    -- centro = coord - .5)
    G.setLineWidth(2)
    for _, poly in ipairs(map.paths or {}) do
        G.setColor(.95, .72, .30, .9)
        for j = 2, #poly do
            G.line(MX + (poly[j-1][1] - .5) * cp, MY + (poly[j-1][2] - .5) * cp,
                MX + (poly[j][1] - .5) * cp, MY + (poly[j][2] - .5) * cp)
        end
    end
    G.setLineWidth(1)

    -- zones: contorno por superfície + rótulo
    G.setFont(fM)
    for _, z in ipairs(map.zones or {}) do
        local c = ZONE_LINE[z.surface] or {.9, .9, .4}
        G.setColor(c[1], c[2], c[3], .9)
        G.rectangle('line', cell(z.x) + .5, celly(z.y) + .5,
            z.w * cp - 1, z.h * cp - 1)
        text(z.name or z.surface or '?', cell(z.x) + 2,
            celly(z.y) + 2, {c[1], c[2], c[3]})
    end

    -- props: footprint colorido por categoria + rótulo curto
    G.setFont(fS)
    for _, p in ipairs(map.props or {}) do
        local c
        if p.kind == 'casa' then c = {.55, .38, .26}
        elseif PROP_FOGO[p.kind] or PROP_FOGO[p.id] then c = {.90, .45, .15}
        elseif PROP_AGUA[p.kind] or PROP_AGUA[p.id] then c = {.20, .55, .75}
        else c = {.42, .42, .50} end
        local pw, ph = (p.w or 1) * cp, (p.h or 1) * cp
        G.setColor(c[1], c[2], c[3], .85)
        G.rectangle('fill', cell(p.x) + 1, celly(p.y) + 1, pw - 2, ph - 2)
        if p.solid then
            G.setColor(1, 1, 1, .5)
            G.rectangle('line', cell(p.x) + .5, celly(p.y) + .5, pw - 1, ph - 1)
        end
        text(p.id or p.kind, cell(p.x) + 1, celly(p.y) + ph + 1,
            {.85, .85, .9})
    end

    -- npcs e hotspots: ponto + id/label
    for _, n in ipairs(map.npcs or {}) do
        G.setColor(.75, .45, .85, 1)
        G.circle('fill', cell(n.x) + cp / 2, celly(n.y) + cp / 2, 3)
        text(n.id, cell(n.x) + cp / 2 + 4, celly(n.y) - 2, {.80, .60, .90})
    end
    for _, s in ipairs(map.hotspots or {}) do
        G.setColor(1, 1, 1, .9)
        local hx, hy = cell(s.x) + cp / 2, celly(s.y) + cp / 2
        G.polygon('fill', hx, hy - 3, hx + 3, hy, hx, hy + 3, hx - 3, hy)
        text(s.id, hx + 4, hy - 4, {.9, .9, .9})
    end

    -- exits, arrivals, spawn
    G.setFont(fM)
    for _, e in ipairs(map.exits or {}) do
        G.setColor(1, .62, .15, 1)
        G.rectangle('fill', cell(e.x) + 2, celly(e.y) + 2, cp - 4, cp - 4)
        text('▸ ' .. (e.label or e.to or '?'), cell(e.x) + cp,
            celly(e.y), {1, .72, .30})
    end
    for name, a in pairs(map.arrivals or {}) do
        G.setColor(.35, .85, .95, 1)
        G.circle('fill', cell(a.x) + cp / 2, celly(a.y) + cp / 2, 4)
        text('A:' .. name, cell(a.x) + cp / 2 + 5,
            celly(a.y) - 4, {.50, .90, 1})
    end
    if map.spawn then
        G.setColor(.25, .95, .45, 1)
        G.circle('fill', cell(map.spawn.x) + cp / 2,
            celly(map.spawn.y) + cp / 2, 5)
        text('SPAWN', cell(map.spawn.x) + cp / 2 + 6,
            celly(map.spawn.y) - 5, {.4, 1, .55})
    end

    -- título + legenda
    G.setFont(fT)
    text(string.format('MAPSHOT %s — %s (%dx%d cél)',
        map.id or '?', map.name or '?', map.w, map.h), MX, 8, {1, .9, .55})
    G.setFont(fM)
    local lx = MX
    local seen = {}
    for x = 1, map.w do for y = 1, map.h do
        local t = map.tiles[x .. ':' .. y]
        if t and t.ground == 'floor' and not t.piece then
            seen[HDWorld.floorKind(map, x, y)] = true
        end
    end end
    local function swatch(name, c)
        G.setColor(c[1], c[2], c[3], 1)
        G.rectangle('fill', lx, H - 30, 10, 10)
        text(name, lx + 13, H - 30, {.8, .8, .85})
        lx = lx + 13 + fM:getWidth(name) + 12
    end
    for name, c in pairs(FLOOR_COLOR) do
        if seen[name] then swatch(name, c) end
    end
    swatch('muro', {.17, .18, .24}); swatch('portal', {.88, .55, .20})
    swatch('fogo', {.90, .45, .15}); swatch('água', {.20, .55, .75})
    swatch('prop', {.42, .42, .50})
    G.setCanvas()
    return cv
end

-- ── albedo ───────────────────────────────────────────────────────────
-- O mapa inteiro composto com as sheets reais: mesmo fill do G-buffer
-- de hd_world (HDWorld.fillView), vista = retângulo do mapa, escala
-- reduzida p/ caber em 2048px no lado maior.

local function albedo(map)
    local renderer = {time = 0, reducedMotion = true}
    local hd = HDWorld.fillView(renderer, map)
    local pw, ph = map.w * HDWorld.CELL, map.h * HDWorld.CELL
    local sc = 1
    for _, s in ipairs({1, .5, .25, .125}) do
        if math.max(pw, ph) * s <= 2048 then sc = s break end
        sc = s
    end
    local out = G.newCanvas(math.max(1, math.floor(pw * sc)),
        math.max(1, math.floor(ph * sc)))
    hd.bufA:setFilter('linear', 'linear')
    G.setCanvas(out); G.clear(0, 0, 0, 1)
    G.draw(hd.bufA, 0, 0, 0, sc, sc)
    G.setCanvas()
    hd.bufA:setFilter('nearest', 'nearest')
    return out, sc
end

-- ── stamp ────────────────────────────────────────────────────────────
-- Carimba uma captura existente: grade de células 64px + coordenadas
-- nos eixos. Câmera explícita (--cam px-mundo) ou deduzida de --pos
-- (mesma fórmula de clamp do Render.layout: centrada no pé, travada
-- no retângulo do mapa).

local function stamp(path, o)
    local fh = assert(io.open(path, 'rb'),
        'stamp: não abre ' .. tostring(path))
    local bytes = fh:read('*a'); fh:close()
    local idata = love.image.newImageData(
        love.filesystem.newFileData(bytes, path))
    local img = G.newImage(idata)
    local iw, ih = img:getDimensions()
    local camX, camY = 0, 0
    if o.cam then
        camX, camY = o.cam.x, o.cam.y
    elseif o.pos and o.map then
        local map = Region.load(o.map, o.legacy)
        local CELL = HDWorld.CELL
        camX = math.max(0, math.min(map.w * CELL - iw,
            (o.pos.x - .5) * CELL - iw / 2))
        camY = math.max(0, math.min(map.h * CELL - ih,
            (o.pos.y - .5) * CELL - ih / 2))
    end
    local out = G.newCanvas(iw, ih)
    local fM = G.newFont(11)
    G.setCanvas(out); G.draw(img, 0, 0)
    G.setFont(fM)
    local CELL = HDWorld.CELL
    G.setLineWidth(1)
    local function text(s, x, y)
        G.setColor(0, 0, 0, .85); G.print(s, x + 1, y + 1)
        G.setColor(1, .95, .35, 1); G.print(s, x, y)
    end
    local wx = math.ceil(camX / CELL) * CELL
    while wx < camX + iw do
        local sx = wx - camX
        G.setColor(1, 1, .4, .30); G.line(sx, 0, sx, ih)
        text(tostring(math.floor(wx / CELL) + 1), sx + 2, 2)
        wx = wx + CELL
    end
    local wy = math.ceil(camY / CELL) * CELL
    while wy < camY + ih do
        local sy = wy - camY
        G.setColor(1, 1, .4, .30); G.line(0, sy, iw, sy)
        text(tostring(math.floor(wy / CELL) + 1), 2, sy + 1)
        wy = wy + CELL
    end
    text(string.format('cam %d,%d · cél %dpx', camX, camY, CELL),
        iw - 190, ih - 16)
    G.setCanvas()
    return out
end

-- ── CLI ──────────────────────────────────────────────────────────────

local function parsePair(s)
    local a, b = s:match('^(%-?%d+%.?%d*)[,%s](%-?%d+%.?%d*)$')
    return a and {x = tonumber(a), y = tonumber(b)} or nil
end

function love.load()
    package.path = package.path .. ';./?.lua;./?/init.lua'
    -- components antes de tudo: pixel_world→environment filtra 'hazard'
    -- e falha se a classe Concord ainda não foi registrada.
    require('src.components')
    Region = require('src.region')
    HDWorld = require('src.hd_world')

    local o = {mode = 'all', cellpx = 18}
    for _, a in ipairs(arg or {}) do
        local k, v = a:match('^%-%-([%w_%-]+)=(.*)$')
        if k == 'map' or k == 'region' then o.map = v
        elseif k == 'mode' then o.mode = v
        elseif k == 'cellpx' then o.cellpx = tonumber(v) or 18
        elseif k == 'stamp' then o.stamp = v
        elseif k == 'pos' then o.pos = parsePair(v)
        elseif k == 'cam' then o.cam = parsePair(v)
        elseif k == 'out' then o.out = v
        elseif a == '--legacy' then o.legacy = true
        end
    end
    if not o.map and not o.stamp then
        die('mapshot: precisa de --map=<id> ou --stamp=<arquivo.png>')
    end

    if o.stamp then
        local base = (o.out or ('mapshot-'
            .. o.stamp:gsub('.*[/\\]', ''):gsub('%.png$', '')))
        saveCanvas(stamp(o.stamp, o),
            'screenshots/' .. base .. '-stamped.png')
    end
    if o.map then
        local map = Region.load(o.map, o.legacy)
        if o.mode == 'scheme' or o.mode == 'all' then
            saveCanvas(scheme(map, o), 'screenshots/'
                .. (o.out or 'mapshot-' .. o.map) .. '-scheme.png')
        end
        if o.mode == 'albedo' or o.mode == 'all' then
            local cv, sc = albedo(map)
            saveCanvas(cv, 'screenshots/'
                .. (o.out or 'mapshot-' .. o.map) .. '-albedo.png')
            print(string.format('[mapshot] albedo %s %dx%d@%.3f',
                o.map, map.w, map.h, sc))
        end
    end
    love.event.quit(0)
end
