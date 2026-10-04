-- Ferramentas de autoria: grades indexadas, coordenadas inteiras 1-based.
-- Não depende de love; a conversão para imagem pertence ao sprite_dsl.
local M = {}
local floor, abs, ceil, sqrt = math.floor, math.abs, math.ceil, math.sqrt
local byte = string.byte

local function integer(n)
    assert(type(n) == 'number' and n == floor(n) and abs(n) < math.huge,
        'pixel_kit: coordenada deve ser inteira finita')
    return n
end

local function symbol(c)
    assert(type(c) == 'string' and #c == 1 and not c:match('%s'),
        'pixel_kit: use um caractere de um byte; ponto = transparente')
end

function M.new(w, h)
    integer(w); integer(h)
    assert(w > 0 and h > 0, 'pixel_kit: tamanho deve ser positivo')
    local g = { w = w, h = h, rows = {} }
    for y = 1, h do
        g.rows[y] = {}
        for x = 1, w do g.rows[y][x] = '.' end
    end
    return g
end

function M.get(g, x, y)
    return g.rows[y] and g.rows[y][x] or '.'
end

function M.pixel(g, x, y, c, mask)
    integer(x); integer(y); symbol(c)
    if x >= 1 and x <= g.w and y >= 1 and y <= g.h
        and (not mask or M.get(mask, x, y) ~= '.') then
        g.rows[y][x] = c
    end
    return g
end

function M.rect(g, x, y, w, h, c, mask)
    integer(x); integer(y); integer(w); integer(h); symbol(c)
    assert(w >= 0 and h >= 0, 'pixel_kit: dimensao negativa')
    for py = math.max(1, y), math.min(g.h, y + h - 1) do
        for px = math.max(1, x), math.min(g.w, x + w - 1) do
            M.pixel(g, px, py, c, mask)
        end
    end
    return g
end

function M.line(g, x, y, tx, ty, c, mask)
    integer(x); integer(y); integer(tx); integer(ty); symbol(c)
    local dx, dy = abs(tx - x), -abs(ty - y)
    local sx, sy = x < tx and 1 or -1, y < ty and 1 or -1
    local err = dx + dy
    while true do
        M.pixel(g, x, y, c, mask)
        if x == tx and y == ty then break end
        local e = err * 2
        if e >= dy then err = err + dy; x = x + sx end
        if e <= dx then err = err + dx; y = y + sy end
    end
    return g
end

function M.ellipse(g, x, y, w, h, c, mask)
    integer(x); integer(y); integer(w); integer(h); symbol(c)
    assert(w > 0 and h > 0, 'pixel_kit: elipse precisa de tamanho positivo')
    local cx, cy = x + (w - 1) / 2, y + (h - 1) / 2
    for py = math.max(1, y), math.min(g.h, y + h - 1) do
        for px = math.max(1, x), math.min(g.w, x + w - 1) do
            if ((px - cx) / (w / 2)) ^ 2 + ((py - cy) / (h / 2)) ^ 2 <= 1 then
                M.pixel(g, px, py, c, mask)
            end
        end
    end
    return g
end

-- Preenchimento par-impar nos centros dos pixels, borda via Bresenham.
function M.polygon(g, points, c, mask)
    assert(#points >= 6 and #points % 2 == 0, 'pixel_kit: poligono precisa de 3 vertices')
    symbol(c)
    for _, n in ipairs(points) do integer(n) end
    for y = 1, g.h do
        for x = 1, g.w do
            local inside, j = false, #points - 1
            for i = 1, #points, 2 do
                local ax, ay, bx, by = points[i], points[i+1], points[j], points[j+1]
                if (ay > y) ~= (by > y) and x < (bx-ax)*(y-ay)/(by-ay)+ax then
                    inside = not inside
                end
                j = i
            end
            if inside then M.pixel(g, x, y, c, mask) end
        end
    end
    local j = #points - 1
    for i = 1, #points, 2 do
        M.line(g, points[j], points[j+1], points[i], points[i+1], c, mask)
        j = i
    end
    return g
end

function M.clone(g)
    local out = M.new(g.w, g.h)
    for y = 1, g.h do for x = 1, g.w do out.rows[y][x] = g.rows[y][x] end end
    if g.regions then
        out.regions = {}
        for k, m in pairs(g.regions) do out.regions[k] = M.clone(m) end
    end
    return out
end

function M.flip(g, horizontal, vertical)
    local out = M.new(g.w, g.h)
    for y = 1, g.h do for x = 1, g.w do
        out.rows[y][x] = M.get(g, horizontal and g.w-x+1 or x, vertical and g.h-y+1 or y)
    end end
    if g.regions then
        out.regions = {}
        for k, m in pairs(g.regions) do out.regions[k] = M.flip(m, horizontal, vertical) end
    end
    return out
end

-- Transparente na origem não apaga o destino. Snapshot permite blit em si.
function M.blit(g, source, dx, dy, mask)
    integer(dx); integer(dy)
    if source == g then source = M.clone(source) end
    for y = 1, source.h do for x = 1, source.w do
        local c = M.get(source, x, y)
        if c ~= '.' then M.pixel(g, x+dx, y+dy, c, mask) end
    end end
    return g
end

local function sig(v) return v > 0 and 1 or (v < 0 and -1 or 0) end

-- Contorno, vizinhanca de quatro direcoes. opts.mode:
-- 'outer'  (padrao): acrescenta borda externa de um pixel; reserve margem.
-- 'inner'  : recolore pixels da silhueta que tocam o transparente.
-- 'lit'    : borda externa so no lado voltado a luz (opts.light={dx,dy} e a
--            direcao de onde vem a luz; default {-1,-1} = topo-esquerda).
-- 'shadow' : borda externa so no lado oposto a luz.
-- opts.colors = {c=true,...}: contorno seletivo — so pixels dessas cores
-- participam (outer: como origem; inner: como alvo). opts.mask limita
-- onde o contorno pode ser escrito.
function M.outline(g, c, opts)
    symbol(c)
    opts = opts or {}
    local mode = opts.mode or 'outer'
    local source = M.clone(g)
    local lx, ly = -1, -1
    if opts.light then
        lx = opts.light[1] or opts.light.dx or lx
        ly = opts.light[2] or opts.light.dy or ly
    end
    local slx, sly = sig(lx), sig(ly)
    local function solid(x, y)
        local ch = M.get(source, x, y)
        if ch == '.' then return false end
        if opts.colors and not opts.colors[ch] then return false end
        return true
    end
    local function put(x, y)
        if not opts.mask or M.get(opts.mask, x, y) ~= '.' then
            g.rows[y][x] = c
        end
    end
    for y = 1, g.h do for x = 1, g.w do
        if mode == 'inner' then
            if M.get(source, x, y) ~= '.'
                and (not opts.colors or opts.colors[M.get(source, x, y)])
                and (not solid(x - 1, y) or not solid(x + 1, y)
                    or not solid(x, y - 1) or not solid(x, y + 1)) then
                put(x, y)
            end
        elseif M.get(source, x, y) == '.' then
            for _, d in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
                if solid(x + d[1], y + d[2]) then
                    -- direcao solido->vazio e (-d); acesa quando aponta p/ luz
                    local faces = (d[1] ~= 0 and sig(d[1]) == -slx)
                        or (d[2] ~= 0 and sig(d[2]) == -sly)
                    if mode == 'outer' or (mode == 'lit' and faces)
                        or (mode == 'shadow' and not faces) then
                        put(x, y)
                        break
                    end
                end
            end
        end
    end end
    return g
end

-- Recolore somente a silhueta existente. Callback recebe x,y,cor.
function M.paint(g, fn, mask)
    for y = 1, g.h do for x = 1, g.w do
        local c = M.get(g, x, y)
        if c ~= '.' and (not mask or M.get(mask,x,y) ~= '.') then
            local nextColor = fn(x, y, c)
            if nextColor then M.pixel(g, x, y, nextColor) end
        end
    end end
    return g
end

function M.string(g)
    local rows = {}
    for y = 1, g.h do rows[y] = table.concat(g.rows[y]) end
    return table.concat(rows, '\n')
end

-- Diagnosticos, nao julgamento artistico: pixels isolados podem ser intencionais.
function M.inspect(g, legend)
    local report = { colors = {}, unknown = {}, isolated = {}, pixels = 0 }
    for y = 1, g.h do for x = 1, g.w do
        local c = M.get(g,x,y)
        if c ~= '.' then
            report.pixels = report.pixels + 1
            report.colors[c] = (report.colors[c] or 0) + 1
            if legend and not legend[c] then report.unknown[#report.unknown+1] = {x=x,y=y,color=c} end
            local neighbor = false
            for dy = -1, 1 do for dx = -1, 1 do
                if (dx ~= 0 or dy ~= 0) and M.get(g,x+dx,y+dy) ~= '.' then neighbor = true end
            end end
            if not neighbor then report.isolated[#report.isolated+1] = {x=x,y=y,color=c} end
        end
    end end
    return report
end

-- Camada pronta para def.layers do sprite_dsl, incluindo canais opcionais.
function M.layer(name, albedo, height, emissive)
    for _, channel in pairs({height = height, emissive = emissive}) do
        assert(channel.w == albedo.w and channel.h == albedo.h, 'pixel_kit: canais com tamanhos diferentes')
    end
    return { name = name, albedo = M.string(albedo),
        height = height and M.string(height), emissive = emissive and M.string(emissive) }
end

--------------------------------------------------------------------------------
-- W1: rasterizacao avancada e correcao local
--------------------------------------------------------------------------------

-- Texto de grade -> grade; inverso de M.string. Mesmo contrato das
-- grades [[ ]] do sprite_dsl: linhas em branco nas bordas e indentacao
-- comum sao descontadas, larguras divergentes dao erro. ' ' vira '.'.
function M.parse(text)
    assert(type(text) == 'string', 'pixel_kit: parse espera string')
    text = text:gsub('\r\n', '\n'):gsub('\r', '\n')
    local rows = {}
    for line in (text .. '\n'):gmatch('(.-)\n') do rows[#rows + 1] = line end
    while #rows > 0 and rows[1]:match('^%s*$') do table.remove(rows, 1) end
    while #rows > 0 and rows[#rows]:match('^%s*$') do table.remove(rows) end
    assert(#rows > 0, 'pixel_kit: parse de grade vazia')
    local prefix
    for _, row in ipairs(rows) do
        if not row:match('^%s*$') then
            prefix = math.min(prefix or math.huge, #row:match('^%s*'))
        end
    end
    if prefix and prefix > 0 then
        for i, row in ipairs(rows) do rows[i] = row:sub(prefix + 1) end
    end
    local w = #rows[1]
    for i = 2, #rows do
        assert(#rows[i] == w, 'pixel_kit: parse ragged na linha ' .. i)
    end
    local g = M.new(w, #rows)
    for y = 1, g.h do
        for x = 1, w do
            local ch = rows[y]:sub(x, x)
            g.rows[y][x] = ch == ' ' and '.' or ch
        end
    end
    return g
end

-- Aleatoriedade deterministica por asset: gerador proprio (Park-Miller)
-- semeado por nome + seed. Nao toca math.random nem love.math: o RNG do
-- jogo fica intocavel e a sequencia independe da ordem dos assets.
function M.rng(name, seed)
    local h = 0
    name = tostring(name)
    for i = 1, #name do h = (h * 131 + byte(name, i)) % 2147483646 end
    local s = (h + (seed or 0) * 7919) % 2147483646 + 1
    local function step()
        s = s * 48271 % 2147483647
        return s / 2147483647
    end
    return {
        float = step,
        int = function(a, b)
            integer(a); integer(b)
            assert(a <= b, 'pixel_kit: rng int com intervalo vazio')
            return a + floor(step() * (b - a + 1))
        end,
        pick = function(t)
            assert(#t > 0, 'pixel_kit: rng pick em lista vazia')
            return t[floor(step() * #t) + 1]
        end,
        chance = function(p) return step() < p end,
    }
end

-- Brief de asset (W0): forma minima validada; campos extras passam
-- intactos. O runner e os pilotos consomem brief.seed/regions/protected.
function M.brief(t)
    assert(type(t) == 'table', 'pixel_kit: brief deve ser tabela')
    assert(type(t.name) == 'string' and #t.name > 0, 'brief: falta name')
    integer(t.w); integer(t.h)
    assert(t.w > 0 and t.h > 0, 'brief: dimensoes devem ser positivas')
    local b = {}
    for k, v in pairs(t) do b[k] = v end
    b.seed = t.seed or 0
    b.regions = t.regions or {}
    b.anchors = t.anchors or {}
    b.protected = t.protected or {}
    return b
end

local function round(v) return floor(v + 0.5) end

local function poly_len(p)
    local len = 0
    for i = 3, #p, 2 do
        len = len + sqrt((p[i] - p[i - 2]) ^ 2 + (p[i + 1] - p[i - 1]) ^ 2)
    end
    return len
end

local function curve_n(pts)
    return math.max(8, math.min(512, ceil(poly_len(pts) * 2)))
end

-- Pontos amostrados da curva quadratica, lista plana x,y,... para
-- M.path/M.stroke. Resolucao proporcional ao comprimento (8..512).
function M.qpts(x1, y1, cx, cy, x2, y2)
    for _, n in ipairs({ x1, y1, cx, cy, x2, y2 }) do integer(n) end
    local n = curve_n({ x1, y1, cx, cy, x2, y2 })
    local pts = {}
    for i = 0, n do
        local t, mt = i / n, 1 - i / n
        pts[#pts + 1] = round(mt * mt * x1 + 2 * mt * t * cx + t * t * x2)
        pts[#pts + 1] = round(mt * mt * y1 + 2 * mt * t * cy + t * t * y2)
    end
    return pts
end

-- Idem para a cubica.
function M.cpts(x1, y1, c1x, c1y, c2x, c2y, x2, y2)
    for _, n in ipairs({ x1, y1, c1x, c1y, c2x, c2y, x2, y2 }) do integer(n) end
    local n = curve_n({ x1, y1, c1x, c1y, c2x, c2y, x2, y2 })
    local pts = {}
    for i = 0, n do
        local t, mt = i / n, 1 - i / n
        local a, b, c3, d = mt * mt * mt, 3 * mt * mt * t, 3 * mt * t * t, t * t * t
        pts[#pts + 1] = round(a * x1 + b * c1x + c3 * c2x + d * x2)
        pts[#pts + 1] = round(a * y1 + b * c1y + c3 * c2y + d * y2)
    end
    return pts
end

-- Caminho aberto/fechado: segue a lista plana ligando pontos com line.
function M.path(g, pts, c, mask, closed)
    assert(#pts >= 4 and #pts % 2 == 0, 'pixel_kit: path precisa de 2 pontos')
    symbol(c)
    for _, n in ipairs(pts) do integer(n) end
    for i = 3, #pts, 2 do
        M.line(g, pts[i - 2], pts[i - 1], pts[i], pts[i + 1], c, mask)
    end
    if closed then
        M.line(g, pts[#pts - 1], pts[#pts], pts[1], pts[2], c, mask)
    end
    return g
end

function M.qcurve(g, x1, y1, cx, cy, x2, y2, c, mask)
    return M.path(g, M.qpts(x1, y1, cx, cy, x2, y2), c, mask)
end

function M.ccurve(g, x1, y1, c1x, c1y, c2x, c2y, x2, y2, c, mask)
    return M.path(g, M.cpts(x1, y1, c1x, c1y, c2x, c2y, x2, y2), c, mask)
end

local function linepts(x, y, tx, ty)
    local pts = {}
    local dx, dy = abs(tx - x), -abs(ty - y)
    local sx, sy = x < tx and 1 or -1, y < ty and 1 or -1
    local err = dx + dy
    while true do
        pts[#pts + 1] = x; pts[#pts + 1] = y
        if x == tx and y == ty then break end
        local e = err * 2
        if e >= dy then err = err + dy; x = x + sx end
        if e <= dx then err = err + dx; y = y + sy end
    end
    return pts
end

-- Traco com espessura: carimbo quadrado w×w centrado em cada ponto do
-- caminho, o que cobre os joins; pontas quadradas nas extremidades.
-- Largura par estende 1 px a mais para baixo/direita (previsivel).
function M.stroke(g, pts, w, c, mask, closed)
    integer(w); symbol(c)
    assert(w >= 1, 'pixel_kit: espessura deve ser positiva')
    assert(#pts >= 4 and #pts % 2 == 0, 'pixel_kit: stroke precisa de 2 pontos')
    if w == 1 then return M.path(g, pts, c, mask, closed) end
    local lo = floor((w - 1) / 2)
    local walk = {}
    for i = 3, #pts, 2 do
        local seg = linepts(pts[i - 2], pts[i - 1], pts[i], pts[i + 1])
        for j = 1, #seg - 2, 2 do
            walk[#walk + 1] = seg[j]; walk[#walk + 1] = seg[j + 1]
        end
    end
    walk[#walk + 1] = pts[#pts - 1]; walk[#walk + 1] = pts[#pts]
    if closed then
        local seg = linepts(pts[#pts - 1], pts[#pts], pts[1], pts[2])
        for j = 1, #seg - 2, 2 do
            walk[#walk + 1] = seg[j]; walk[#walk + 1] = seg[j + 1]
        end
    end
    for i = 1, #walk, 2 do
        M.rect(g, walk[i] - lo, walk[i + 1] - lo, w, w, c, mask)
    end
    return g
end

-- Flood fill: recolore o pixel-semente e os conectados a ele com a mesma
-- cor. opts.conn = 4 (padrao) ou 8; opts.mask limita a regiao.
function M.fill(g, x, y, c, opts)
    integer(x); integer(y); symbol(c)
    opts = opts or {}
    local conn = opts.conn or 4
    assert(conn == 4 or conn == 8, 'pixel_kit: fill conn deve ser 4 ou 8')
    if x < 1 or x > g.w or y < 1 or y > g.h then return g end
    if opts.mask and (opts.mask.w ~= g.w or opts.mask.h ~= g.h) then
        error('pixel_kit: mascara do fill com tamanho diferente')
    end
    local target = M.get(g, x, y)
    if target == c then return g end
    local dirs = conn == 4
        and { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }
        or { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 },
            { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }
    local seen = {}
    local stack = { x, y }
    while #stack > 0 do
        local cy = stack[#stack]; stack[#stack] = nil
        local cx = stack[#stack]; stack[#stack] = nil
        local k = (cy - 1) * g.w + cx
        if not seen[k] and M.get(g, cx, cy) == target
            and (not opts.mask or M.get(opts.mask, cx, cy) ~= '.') then
            seen[k] = true
            g.rows[cy][cx] = c
            for _, d in ipairs(dirs) do
                local nx, ny = cx + d[1], cy + d[2]
                if nx >= 1 and nx <= g.w and ny >= 1 and ny <= g.h then
                    stack[#stack + 1] = nx; stack[#stack + 1] = ny
                end
            end
        end
    end
    return g
end

local function sel(g, fn)
    local m = M.new(g.w, g.h)
    for y = 1, g.h do for x = 1, g.w do
        if fn(M.get(g, x, y), x, y) then m.rows[y][x] = 'x' end
    end end
    return m
end

-- Selecoes devolvem mascara ('x' = selecionado, '.' = fora).
function M.sel_cover(g)
    return sel(g, function(c) return c ~= '.' end)
end

function M.sel_color(g, color)
    symbol(color)
    return sel(g, function(c) return c == color end)
end

function M.sel_rect(g, x, y, w, h)
    integer(x); integer(y); integer(w); integer(h)
    return sel(g, function(_, px, py)
        return px >= x and px < x + w and py >= y and py < y + h
    end)
end

-- Componente conectado (conn 4 ou 8) da cor no ponto-semente.
function M.sel_component(g, x, y, conn)
    integer(x); integer(y)
    conn = conn or 4
    assert(conn == 4 or conn == 8, 'pixel_kit: sel_component conn 4 ou 8')
    local m = M.new(g.w, g.h)
    if x < 1 or x > g.w or y < 1 or y > g.h then return m end
    local target = M.get(g, x, y)
    local dirs = conn == 4
        and { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }
        or { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 },
            { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }
    local seen, stack = {}, { x, y }
    while #stack > 0 do
        local cy = stack[#stack]; stack[#stack] = nil
        local cx = stack[#stack]; stack[#stack] = nil
        local k = (cy - 1) * g.w + cx
        if not seen[k] and M.get(g, cx, cy) == target then
            seen[k] = true
            m.rows[cy][cx] = 'x'
            for _, d in ipairs(dirs) do
                local nx, ny = cx + d[1], cy + d[2]
                if nx >= 1 and nx <= g.w and ny >= 1 and ny <= g.h then
                    stack[#stack + 1] = nx; stack[#stack + 1] = ny
                end
            end
        end
    end
    return m
end

local function samemask(a, b)
    assert(a.w == b.w and a.h == b.h, 'pixel_kit: mascaras com tamanhos diferentes')
end

local function mask_bin(a, b, fn)
    samemask(a, b)
    local m = M.new(a.w, a.h)
    for y = 1, a.h do for x = 1, a.w do
        if fn(M.get(a, x, y) ~= '.', M.get(b, x, y) ~= '.') then
            m.rows[y][x] = 'x'
        end
    end end
    return m
end

-- Ops de mascara: devolvem grade nova, nao alteram as entradas.
function M.mask_or(a, b)
    return mask_bin(a, b, function(p, q) return p or q end)
end

function M.mask_and(a, b)
    return mask_bin(a, b, function(p, q) return p and q end)
end

function M.mask_sub(a, b)
    return mask_bin(a, b, function(p, q) return p and not q end)
end

-- Inversao limitada a grade (ou a `bounds`, se dada) — nunca cresce.
function M.mask_not(a, bounds)
    if bounds then samemask(a, bounds) end
    local m = M.new(a.w, a.h)
    for y = 1, a.h do for x = 1, a.w do
        if M.get(a, x, y) == '.'
            and (not bounds or M.get(bounds, x, y) ~= '.') then
            m.rows[y][x] = 'x'
        end
    end end
    return m
end

local function mask_step(a, conn, erode)
    local dirs = conn == 4
        and { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }
        or { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 },
            { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }
    local m = M.new(a.w, a.h)
    for y = 1, a.h do for x = 1, a.w do
        local keep = M.get(a, x, y) ~= '.'
        for _, d in ipairs(dirs) do
            local nx, ny = x + d[1], y + d[2]
            local nb = nx >= 1 and nx <= a.w and ny >= 1 and ny <= a.h
                and M.get(a, nx, ny) ~= '.'
            if erode then
                keep = keep and nb
            else
                keep = keep or nb
            end
        end
        if keep then m.rows[y][x] = 'x' end
    end end
    return m
end

-- Dilatacao: acende vizinhos (conn 4 ou 8) de pixels ligados, n vezes.
function M.mask_dilate(a, conn, n)
    conn = conn or 4
    assert(conn == 4 or conn == 8, 'pixel_kit: dilate conn 4 ou 8')
    for _ = 1, n or 1 do a = mask_step(a, conn, false) end
    return a
end

-- Erosao: apaga pixels ligados que tocam o fundo (conn 4 ou 8), n vezes.
-- Fora da grade conta como fundo: mascaras na borda tambem erodem.
function M.mask_erode(a, conn, n)
    conn = conn or 4
    assert(conn == 4 or conn == 8, 'pixel_kit: erode conn 4 ou 8')
    for _ = 1, n or 1 do a = mask_step(a, conn, true) end
    return a
end

-- Regioes nomeadas: mascaras guardadas na grade p/ correcao posterior.
-- clone/flip/crop/shift preservam g.regions.
function M.set_region(g, name, mask)
    assert(type(name) == 'string' and #name > 0, 'pixel_kit: regiao sem nome')
    assert(mask.w == g.w and mask.h == g.h,
        'pixel_kit: regiao com tamanho diferente da grade')
    g.regions = g.regions or {}
    g.regions[name] = M.clone(mask)
    return mask
end

function M.region(g, name)
    return g.regions and g.regions[name] or nil
end

-- Recorte: devolve grade nova w×h com o conteudo de (x,y) em diante;
-- fora da grade vira '.'. Regioes nomeadas sao recortadas junto.
function M.crop(g, x, y, w, h)
    integer(x); integer(y); integer(w); integer(h)
    assert(w > 0 and h > 0, 'pixel_kit: crop precisa de tamanho positivo')
    local out = M.new(w, h)
    for py = 1, h do for px = 1, w do
        out.rows[py][px] = M.get(g, x + px - 1, y + py - 1)
    end end
    if g.regions then
        out.regions = {}
        for k, m in pairs(g.regions) do out.regions[k] = M.crop(m, x, y, w, h) end
    end
    return out
end

-- Deslocamento com clipping: o que sai pela borda se perde.
function M.shift(g, dx, dy)
    integer(dx); integer(dy)
    local out = M.new(g.w, g.h)
    for y = 1, g.h do for x = 1, g.w do
        local sx, sy = x - dx, y - dy
        if sx >= 1 and sx <= g.w and sy >= 1 and sy <= g.h then
            out.rows[y][x] = g.rows[sy][sx]
        end
    end end
    if g.regions then
        out.regions = {}
        for k, m in pairs(g.regions) do out.regions[k] = M.shift(m, dx, dy) end
    end
    return out
end

local function pivot_xy(src, pivot)
    if pivot == nil or pivot == 'topleft' then return 1, 1 end
    if pivot == 'center' then return floor(src.w / 2) + 1, floor(src.h / 2) + 1 end
    if pivot == 'feet' then return floor(src.w / 2) + 1, src.h end
    if type(pivot) == 'table' then
        local px, py = pivot.px or pivot[1], pivot.py or pivot[2]
        integer(px); integer(py)
        return px, py
    end
    error('pixel_kit: pivot deve ser topleft|center|feet|{px,py}')
end

-- Carimbo: blit de modo que o pivo de src caia em (x,y) do destino.
function M.stamp(g, src, x, y, pivot, mask)
    integer(x); integer(y)
    local px, py = pivot_xy(src, pivot)
    return M.blit(g, src, x - px, y - py, mask)
end

-- Patch local aplicado na etapa da receita em que for chamado.
-- p.pixels = {{x,y,c},...}; p.rows = {{x=, y=, text=},...} escreve a
-- string a partir de (x,y) — ' ' pula o pixel, '.' apaga, demais pintam.
-- mask limita todas as escritas: correcao confinada a regiao.
function M.patch(g, p, mask)
    assert(type(p) == 'table', 'pixel_kit: patch deve ser tabela')
    for _, px in ipairs(p.pixels or {}) do
        M.pixel(g, px[1] or px.x, px[2] or px.y, px[3] or px.c, mask)
    end
    for _, row in ipairs(p.rows or {}) do
        local rx, ry, text = row[1] or row.x, row[2] or row.y, row[3] or row.text
        integer(rx); integer(ry)
        assert(type(text) == 'string', 'pixel_kit: patch row sem text')
        for i = 1, #text do
            local ch = text:sub(i, i)
            if ch ~= ' ' then M.pixel(g, rx + i - 1, ry, ch, mask) end
        end
    end
    return g
end

-- Review aids (W1): diagnostico tecnico com coordenadas — sao avisos
-- para revisao, nao julgamento artistico. Retorna o relatorio de
-- M.inspect mais:
--   clusters  = componentes 4-dir por cor {color,size,x,y,w,h} (maior 1o)
--   steps     = saltos >=2 do contorno superior entre colunas adjacentes
--   thickness = {min,max,jumps} extensao vertical por coluna; jump >=3
--   corners   = solidos com exatos 2 vizinhos 4-dir perpendiculares
--   gaps      = '.' cercado por solido nas 8 direcoes (pode ser intencional)
function M.review(g, legend)
    local r = M.inspect(g, legend)
    local seen = {}
    r.clusters = {}
    for y = 1, g.h do for x = 1, g.w do
        local ch = M.get(g, x, y)
        local k = (y - 1) * g.w + x
        if ch ~= '.' and not seen[k] then
            local comp = { color = ch, size = 0, x = x, y = y }
            local maxx, maxy = x, y
            local stack = { x, y }
            while #stack > 0 do
                local cy = stack[#stack]; stack[#stack] = nil
                local cx = stack[#stack]; stack[#stack] = nil
                local kk = (cy - 1) * g.w + cx
                if not seen[kk] and M.get(g, cx, cy) == ch then
                    seen[kk] = true
                    comp.size = comp.size + 1
                    if cx < comp.x then comp.x = cx end
                    if cy < comp.y then comp.y = cy end
                    if cx > maxx then maxx = cx end
                    if cy > maxy then maxy = cy end
                    for _, d in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
                        local nx, ny = cx + d[1], cy + d[2]
                        if nx >= 1 and nx <= g.w and ny >= 1 and ny <= g.h then
                            stack[#stack + 1] = nx; stack[#stack + 1] = ny
                        end
                    end
                end
            end
            comp.w = maxx - comp.x + 1
            comp.h = maxy - comp.y + 1
            r.clusters[#r.clusters + 1] = comp
        end
    end end
    table.sort(r.clusters, function(a, b)
        if a.size ~= b.size then return a.size > b.size end
        return a.color < b.color
    end)
    r.steps = {}
    r.thickness = { min = math.huge, max = 0, jumps = {} }
    r.corners = {}
    r.gaps = {}
    local prev_ty, prev_span
    for x = 1, g.w do
        local ty, by
        for y = 1, g.h do
            if M.get(g, x, y) ~= '.' then ty = y; break end
        end
        if ty then
            for y = g.h, 1, -1 do
                if M.get(g, x, y) ~= '.' then by = y; break end
            end
            local span = by - ty + 1
            if span < r.thickness.min then r.thickness.min = span end
            if span > r.thickness.max then r.thickness.max = span end
            if prev_ty and abs(ty - prev_ty) >= 2 then
                r.steps[#r.steps + 1] = { x = x, from = prev_ty, to = ty }
            end
            if prev_span and abs(span - prev_span) >= 3 then
                r.thickness.jumps[#r.thickness.jumps + 1] =
                    { x = x, from = prev_span, to = span }
            end
            prev_ty, prev_span = ty, span
        else
            prev_ty, prev_span = nil, nil
        end
    end
    if r.thickness.min == math.huge then r.thickness.min = 0 end
    local function solid(x, y) return M.get(g, x, y) ~= '.' end
    for y = 1, g.h do for x = 1, g.w do
        if solid(x, y) then
            local n = solid(x, y - 1) and 1 or 0
            local s = solid(x, y + 1) and 1 or 0
            local w = solid(x - 1, y) and 1 or 0
            local e = solid(x + 1, y) and 1 or 0
            if n + s + w + e == 2 and n + s == 1 then
                r.corners[#r.corners + 1] = { x = x, y = y }
            end
        else
            local hole = true
            for dy = -1, 1 do for dx = -1, 1 do
                if (dx ~= 0 or dy ~= 0) and not solid(x + dx, y + dy) then
                    hole = false
                end
            end end
            if hole then r.gaps[#r.gaps + 1] = { x = x, y = y } end
        end
    end end
    return r
end

return M
