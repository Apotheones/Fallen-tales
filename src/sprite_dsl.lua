--[==[
sprite_dsl — mini-formato de sprite autorável "bitmap por string" (Fase 0,
docs/MEGAPLAN_VISUAL_HD.md §2-3). Toda arte do jogo nasce aqui: cada frame é
uma grade de caracteres e cada caractere aponta para a paleta mestra. O
sprite é MULTI-CANAL — albedo (cor), altura (relevo 0..15) e emissivo
(brilho) por pixel — e o bake deriva o normal map da altura
automaticamente. Saída: três spritesheets lado a lado (albedo, normal,
emissivo) prontos para anim8.newGrid(w, h, ...) e para o G-buffer do
lighting.lua.

Definição:

    def = {
        name   = 'viajante_idle_sul',   -- só para mensagens de erro
        w = 64, h = 96,                 -- opcional: inferido das grades
        origin = 'feet',                -- 'feet' (atores) | 'topleft' (tiles);
                                        -- default 'feet'
        legend = {                      -- char -> spec de cor
            ['#'] = 'stone.3',          -- string 'rampa.step' (step 1-based)
            s = { ramp = 'skin', step = 2, h = 6 },
            -- h = altura default do pixel (0..15)
            f = { ramp = 'ember', step = 5, e = 'ember.6', ei = 1 },
            -- e = spec de cor emissiva (string da paleta ou {r,g,b} 0..1);
            -- ei = intensidade 0..1 (default 1). Sem e: o emissivo usa a
            -- cor de albedo do próprio char com ei=1.
        },
        layers = {                      -- ordem = empilhamento; a ÚLTIMA
            {                           -- camada desenha por cima
                name = 'body',
                h = 4,                  -- altura default da camada (0..15)
                albedo = [[...grade...]]          -- canal obrigatório
                    or { [[f1]], [[f2]], ... },   -- array = animação
                height = ...,                     -- opcional, mesma forma
                emissive = ...,                   -- opcional, mesma forma
            }, ...
        },
    }

Regras das grades:
- Linhas vazias/só-espaço nas BORDAS são ignoradas; no miolo contam como
  linha (uma linha só de espaços com a largura certa é uma linha vazia
  válida; linha de largura 0 no meio dá erro 'ragged' com o nº da linha).
- A indentação comum das linhas é descontada: grade escrita alinhada ao
  código tem largura só do desenho.
- Todas as linhas de um frame têm a mesma largura; todos os frames têm o
  mesmo w×h. Se def.w/def.h forem dados, precisam bater com o inferido.
- '.' e ' ' = pixel vazio em qualquer canal. Chars de um byte só.
- O nº de frames é o maior array entre todos os canais; todo canal em
  array precisa ter esse mesmo N, e em string única aplica a todos.
- Char da grade de altura: '.'/' ' herda; '0'-'9' e 'a'-'f' valem 0..15;
  qualquer outro é erro.
- Char da grade emissiva precisa existir na legend (usa .e/.ei; sem .e a
  cor de albedo com ei=1); char fora da legend é erro com coordenada.
- Char da grade de albedo precisa existir na legend (erro com coordenada).
- Altura do pixel: grade de altura > legend[char].h > layer.h > 0. Uma
  camada só contribui altura onde tem marca de altura OU pixel de albedo —
  relevo sem pintura é permitido (grade de altura em pixel vazio).
- Composição por canal INDEPENDENTE: por pixel, o último valor não-vazio
  de cada canal vence, sem a camada de cima apagar a altura/emissivo da
  de baixo.

Saída (contrato com src/lighting.lua):

    sheet = SpriteDSL.bake(def [, opts])
    -- sheet.albedo/normal/emissive : Image nearest (nil sem love.graphics)
    -- sheet.imageData.{albedo,normal,emissive} : ImageData, sempre presentes
    -- sheet.w, sheet.h : tamanho do frame; sheet.frames : nº de frames
    -- sheet.origin : 'feet' | 'topleft'
- albedo   : RGBA LDR; alpha 0 fora do sprite.
- normal   : tangent-space; RGB = n*0.5+0.5. +X para a direita, +Y para
             CIMA na tela (topo de relevo G>128, base G<128, esquerda
             R<128, direita R>128), +Z para fora. Alpha = cobertura
             (255 onde o sprite tem pixel de albedo, 0 fora); fora
             RGB = 128,128,255.
- emissive : RGB = cor_emitida * ei (0..1); A = 255 onde emite, 0 fora.
- Frames enfileirados na horizontal, sem padding nem margem.

Opções de bake:
- opts.strength : ganho relevo->normal (default 2.0).
- opts.resolve(charSpec) -> {r,g,b} : transforma o spec da legend em cor
  0..1 (tabela 0..255 também é aceita e normalizada). Default tardio:
  require('src.palettes').resolve — palettes.lua é reescrito em paralelo,
  então o require acontece dentro do bake; em testes passe o stub.

Cache: bake é memoizado pela IDENTIDADE da tabela def (tabela de chaves
fracas — def coletável limpa a entrada). Chamar de novo com a mesma def
devolve o mesmo sheet e ignora opts; def nova = bake novo.

SpriteDSL.dump(sheet, 'screenshots/nome') grava nome_albedo.png,
nome_normal.png e nome_emissive.png e devolve {albedo=..., normal=...,
emissive=...} com os caminhos.
SpriteDSL.selfCheck() valida o módulo com resolve stub, sem depender de
palettes.lua: devolve true ou levanta erro.
]==]

local SpriteDSL = {}

local floor, sqrt, byte = math.floor, math.sqrt, string.byte

local function fail(fmt, ...)
    error('sprite_dsl: ' .. string.format(fmt, ...), 2)
end

local function vazio(c) return c == '.' or c == ' ' end

-- '0'-'9' -> 0..9, 'a'-'f' -> 10..15, resto nil.
local function hchar(c)
    local b = byte(c)
    if b >= 48 and b <= 57 then return b - 48 end
    if b >= 97 and b <= 102 then return b - 87 end
    return nil
end

-- Grade [[...]] -> lista de linhas + w/h. Linhas em branco só nas bordas.
local function parseGrid(src, where)
    if type(src) ~= 'string' then
        fail('%s: grade deve ser string [[...]], recebeu %s', where, type(src))
    end
    src = src:gsub('\r\n', '\n'):gsub('\r', '\n')
    local rows = {}
    for line in (src .. '\n'):gmatch('(.-)\n') do
        rows[#rows + 1] = line
    end
    local top = 0
    while #rows > 0 and rows[1]:match('^%s*$') do
        table.remove(rows, 1); top = top + 1
    end
    while #rows > 0 and rows[#rows]:match('^%s*$') do
        table.remove(rows)
    end
    if #rows == 0 then fail('%s: grade vazia', where) end
    -- A indentação do código não é pixel: desconta o prefixo de whitespace
    -- comum das linhas não-vazias (linha sem indentação zera o desconto).
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
        if #rows[i] ~= w then
            fail('%s ragged: linha %d tem largura %d (esperada %d)',
                where, i + top, #rows[i], w)
        end
    end
    return rows, w, #rows
end

-- Canal -> array de N grades parseadas. String única replica p/ todos os
-- frames. Devolve também w/h para conferência global.
local function canal(v, n, where, obrigatorio)
    if v == nil then
        if obrigatorio then fail('%s: canal ausente', where) end
        return nil
    end
    if type(v) == 'string' then
        local rows, gw, gh = parseGrid(v, where)
        local t = {}
        for i = 1, n do t[i] = rows end
        return t, gw, gh
    end
    if type(v) == 'table' then
        if #v == 0 then fail('%s: canal sem frames', where) end
        if #v ~= n then
            fail('%s: %d frames, esperado %d', where, #v, n)
        end
        local t, gw, gh = {}, nil, nil
        for i, s in ipairs(v) do
            local rows, w2, h2 = parseGrid(s, where .. ' frame ' .. i)
            if not gw then
                gw, gh = w2, h2
            elseif w2 ~= gw or h2 ~= gh then
                fail('%s frame %d: %dx%d difere do frame 1 (%dx%d)',
                    where, i, w2, h2, gw, gh)
            end
            t[i] = rows
        end
        return t, gw, gh
    end
    fail('%s: canal deve ser string ou array de strings', where)
end

local function normLegend(def, name)
    if type(def.legend) ~= 'table' then
        fail("%s: falta a tabela 'legend'", name)
    end
    local leg = {}
    for ch, e in pairs(def.legend) do
        if type(ch) ~= 'string' or #ch ~= 1 then
            fail("%s: chave da legend deve ser um caractere único", name)
        end
        local en
        if type(e) == 'string' then
            en = { spec = e }
        elseif type(e) == 'table' then
            local spec = e.spec
            if not spec and e.ramp then
                spec = tostring(e.ramp) .. '.' .. tostring(e.step or 1)
            end
            en = { spec = spec, h = e.h, e = e.e, ei = e.ei }
        else
            fail("%s: legend['%s'] deve ser string ou tabela", name, ch)
        end
        if en.h ~= nil and (type(en.h) ~= 'number' or en.h < 0 or en.h > 15) then
            fail("%s: legend['%s'].h fora de 0..15", name, ch)
        end
        if en.ei ~= nil and (type(en.ei) ~= 'number' or en.ei < 0 or en.ei > 1) then
            fail("%s: legend['%s'].ei fora de 0..1", name, ch)
        end
        leg[ch] = en
    end
    return leg
end

-- Spec -> {r,g,b} em 0..1. Aceita tabela direta (legend .e={r,g,b}) e
-- resolve devolvendo bytes 0..255.
local function rgb(spec, resolve, name)
    local c = type(spec) == 'table' and spec or resolve(spec)
    if type(c) ~= 'table' then
        fail("%s: resolve('%s') não devolveu cor", name, tostring(spec))
    end
    local r, g, b = c[1] or c.r, c[2] or c.g, c[3] or c.b
    if not (r and g and b) then
        fail("%s: cor de '%s' incompleta", name, tostring(spec))
    end
    if r > 1 or g > 1 or b > 1 then
        r, g, b = r / 255, g / 255, b / 255
    end
    return { r, g, b }
end

local function imagem(id)
    local lg = love.graphics
    if lg and lg.newImage then
        local ok, img = pcall(lg.newImage, id)
        if ok and img then
            img:setFilter('nearest', 'nearest')
            return img
        end
    end
    return nil
end

-- Memoização por identidade da def; chaves fracas deixam a def morrer.
local bakeCache = setmetatable({}, { __mode = 'k' })

function SpriteDSL.bake(def, opts)
    if type(def) ~= 'table' then fail('bake espera uma tabela def') end
    local cached = bakeCache[def]
    if cached then return cached end
    opts = opts or {}
    local name = def.name or '(sem nome)'

    local resolve = opts.resolve
    if not resolve then
        -- Require tardio: palettes.lua é reescrito em paralelo e resolve()
        -- pode não existir ainda; quem testa passa opts.resolve.
        local ok, pal = pcall(require, 'src.palettes')
        resolve = ok and type(pal) == 'table' and pal.resolve or nil
    end
    if type(resolve) ~= 'function' then
        fail('sem resolve(): passe opts.resolve ou exporte src/palettes.resolve')
    end
    local strength = opts.strength or 2.0

    if def.origin ~= nil and def.origin ~= 'feet' and def.origin ~= 'topleft' then
        fail("%s: origin deve ser 'feet' ou 'topleft'", name)
    end
    if type(def.layers) ~= 'table' or #def.layers == 0 then
        fail("%s: 'layers' precisa de ao menos uma camada", name)
    end
    local legend = normLegend(def, name)

    -- Nº de frames = maior array de qualquer canal; arrays divergentes dão erro.
    local nframes = 1
    for _, l in ipairs(def.layers) do
        for _, k in ipairs({ 'albedo', 'height', 'emissive' }) do
            local v = l[k]
            if type(v) == 'table' then
                if #v == 0 then fail('%s: canal %s sem frames', name, k) end
                if nframes ~= 1 and #v ~= nframes then
                    fail('%s: canais com nº de frames divergentes (%d x %d)',
                        name, #v, nframes)
                end
                if #v > nframes then nframes = #v end
            end
        end
    end

    -- Parse dos canais de todas as camadas + conferência de dimensões.
    local W, H
    local layers = {}
    for li, l in ipairs(def.layers) do
        local ln = string.format('%s camada %s', name, l.name or li)
        if l.h ~= nil and (type(l.h) ~= 'number' or l.h < 0 or l.h > 15) then
            fail('%s: layer.h fora de 0..15', ln)
        end
        local lay = { h = l.h }
        local dims = {}
        lay.albedo, dims[1], dims[2] = canal(l.albedo, nframes, ln .. '.albedo', true)
        lay.height, dims[3], dims[4] = canal(l.height, nframes, ln .. '.height', false)
        lay.emissive, dims[5], dims[6] = canal(l.emissive, nframes, ln .. '.emissive', false)
        for i = 1, 5, 2 do
            if dims[i] then
                if not W then
                    W, H = dims[i], dims[i + 1]
                elseif dims[i] ~= W or dims[i + 1] ~= H then
                    fail('%s: grade %dx%d difere do restante (%dx%d)',
                        ln, dims[i], dims[i + 1], W, H)
                end
            end
        end
        layers[li] = lay
    end
    if def.w and def.w ~= W then
        fail('%s: def.w=%d difere da grade (%d)', name, def.w, W)
    end
    if def.h and def.h ~= H then
        fail('%s: def.h=%d difere da grade (%d)', name, def.h, H)
    end

    local corCache = {}
    local function corDe(spec)
        local c = corCache[spec]
        if not c then
            c = rgb(spec, resolve, name)
            corCache[spec] = c
        end
        return c
    end

    local aid = love.image.newImageData(W * nframes, H)
    local nid = love.image.newImageData(W * nframes, H)
    local eid = love.image.newImageData(W * nframes, H)

    for f = 1, nframes do
        -- Composição do frame: três canais independentes por pixel.
        local alb, hgt, emi = {}, {}, {}
        for li, lay in ipairs(layers) do
            local ag = lay.albedo[f]
            local hg = lay.height and lay.height[f]
            local eg = lay.emissive and lay.emissive[f]
            local onde = string.format('%s camada %s frame %d',
                name, def.layers[li].name or li, f)
            for y = 1, H do
                local arow = ag[y]
                local hrow = hg and hg[y]
                local erow = eg and eg[y]
                for x = 1, W do
                    local idx = (y - 1) * W + x
                    local ac = arow:sub(x, x)
                    local temA = not vazio(ac)
                    if temA then
                        if not legend[ac] then
                            fail("%s (%d,%d): char '%s' não está na legend",
                                onde, x, y, ac)
                        end
                        alb[idx] = ac
                    end
                    -- altura: grade > legend.h > layer.h > 0; só onde a
                    -- camada tem marca de altura ou pixel de albedo.
                    local hc = hrow and hrow:sub(x, x)
                    if hc and not vazio(hc) then
                        local hv = hchar(hc)
                        if not hv then
                            fail("%s (%d,%d): char de altura inválido '%s'",
                                onde, x, y, hc)
                        end
                        hgt[idx] = hv
                    elseif temA then
                        hgt[idx] = legend[ac].h or lay.h or 0
                    end
                    -- emissivo: char precisa estar na legend.
                    local ec = erow and erow:sub(x, x)
                    if ec and not vazio(ec) then
                        local en = legend[ec]
                        if not en then
                            fail("%s (%d,%d): char emissivo '%s' não está na legend",
                                onde, x, y, ec)
                        end
                        local cor
                        if en.e then
                            cor = rgb(en.e, resolve, name)
                        elseif en.spec then
                            cor = corDe(en.spec)
                        else
                            fail("%s: legend['%s'] sem cor (falta spec e e)",
                                name, ec)
                        end
                        emi[idx] = { cor[1], cor[2], cor[3], en.ei or 1 }
                    end
                end
            end
        end

        -- Escrita dos três mapas do frame.
        local x0 = (f - 1) * W
        local function hh(xx, yy) return hgt[(yy - 1) * W + xx] or 0 end
        for y = 1, H do
            for x = 1, W do
                local idx = (y - 1) * W + x
                local px, py = x0 + x - 1, y - 1
                local ac = alb[idx]
                if ac then
                    local en = legend[ac]
                    if not en.spec then
                        fail("%s: legend['%s'] sem spec de cor", name, ac)
                    end
                    local c = corDe(en.spec)
                    aid:setPixel(px, py, c[1], c[2], c[3], 1)
                else
                    aid:setPixel(px, py, 0, 0, 0, 0)
                end
                local ev = emi[idx]
                if ev then
                    eid:setPixel(px, py,
                        ev[1] * ev[4], ev[2] * ev[4], ev[3] * ev[4], 1)
                else
                    eid:setPixel(px, py, 0, 0, 0, 0)
                end
                if ac then
                    -- Diferenças centrais no heightmap 0..15 com vizinho
                    -- espelhado na borda (índice refletido: -1->1, W->W-1).
                    local xl = x > 1 and x - 1 or math.min(2, W)
                    local xr = x < W and x + 1 or math.max(1, W - 1)
                    local yu = y > 1 and y - 1 or math.min(2, H)
                    local yd = y < H and y + 1 or math.max(1, H - 1)
                    local gx = (hh(xr, y) - hh(xl, y)) * strength
                    -- +Y do normal aponta para CIMA na tela; y da imagem
                    -- cresce para baixo, então n_y = +dH/dy da imagem.
                    local gy = (hh(x, yd) - hh(x, yu)) * strength
                    local nx, ny, nz = -gx, gy, 1
                    local len = sqrt(nx * nx + ny * ny + nz * nz)
                    local function enc(v)
                        return floor((v / len * 0.5 + 0.5) * 255 + 0.5) / 255
                    end
                    nid:setPixel(px, py, enc(nx), enc(ny), enc(nz), 1)
                else
                    nid:setPixel(px, py, 128 / 255, 128 / 255, 1, 0)
                end
            end
        end
    end

    local sheet = {
        albedo = imagem(aid),
        normal = imagem(nid),
        emissive = imagem(eid),
        w = W, h = H,
        frames = nframes,
        origin = def.origin or 'feet',
        imageData = { albedo = aid, normal = nid, emissive = eid },
    }
    bakeCache[def] = sheet
    return sheet
end

function SpriteDSL.dump(sheet, base)
    if type(sheet) ~= 'table' or not sheet.imageData then
        fail('dump espera um sheet de bake()')
    end
    local paths = {}
    for _, c in ipairs({ 'albedo', 'normal', 'emissive' }) do
        local p = base .. '_' .. c .. '.png'
        local f = assert(io.open(p, 'wb'))
        f:write(sheet.imageData[c]:encode('png'):getString())
        f:close()
        paths[c] = p
    end
    return paths
end

function SpriteDSL.selfCheck()
    -- resolve stub: não dependemos de palettes.lua (reescrita paralela).
    local function resolve(spec)
        return ({ ['pele.2'] = { .8, .6, .4 }, ['brasa.5'] = { 1, .5, .2 } })[spec]
    end

    assert(hchar('f') == 15 and hchar('9') == 9 and hchar('a') == 10,
        "decode de altura: 'f' devia ser 15")

    local def = {
        name = 'selftest',
        legend = {
            s = { ramp = 'pele', step = 2 },
            f = { ramp = 'brasa', step = 5 }, -- sem .e: emissivo = cor do albedo
        },
        layers = { {
            name = 'corpo', h = 1,
            albedo = [[
                sssss
                sssss
                ssfss
                sssss
                sssss]],
            height = [[
                .....
                .777.
                .7f7.
                .777.
                .....]],
            emissive = [[
                .....
                .....
                ..f..
                .....
                .....]],
        } },
    }
    local sheet = SpriteDSL.bake(def, { resolve = resolve })
    assert(sheet.w == 5 and sheet.h == 5 and sheet.frames == 1, 'dimensões erradas')
    assert(sheet.origin == 'feet', "origin default devia ser 'feet'")

    -- Bossa central: topo com G>127, base com G<127.
    local nid = sheet.imageData.normal
    local function gbyte(x, y)
        local _, g = nid:getPixel(x, y)
        return floor(g * 255 + 0.5)
    end
    assert(gbyte(2, 1) > 127, 'topo da bossa devia ter G>127')
    assert(gbyte(2, 3) < 127, 'base da bossa devia ter G<127')

    -- Emissivo sem .e: cor de albedo do char, ei=1, alpha 255.
    local er, eg, eb, ea = sheet.imageData.emissive:getPixel(2, 2)
    assert(ea == 1 and er == 1 and math.abs(eg - .5) < .01 and math.abs(eb - .2) < .01,
        'emissivo devia usar a cor de albedo com ei=1')
    local ar = sheet.imageData.albedo:getPixel(2, 2)
    assert(ar == 1, 'albedo do centro devia ser a cor de brasa.5')

    -- Grade ragged: erro.
    local ok = pcall(SpriteDSL.bake, {
        name = 'rag', legend = { s = 'pele.2' },
        layers = { { name = 'c', albedo = 'sss\nss' } },
    }, { resolve = resolve })
    assert(not ok, 'grade ragged devia falhar')

    -- Cache por identidade.
    assert(SpriteDSL.bake(def, { resolve = resolve }) == sheet,
        'cache devia devolver o mesmo sheet')

    -- Multi-frame: string aplica a todos, array define N.
    local anim = SpriteDSL.bake({
        name = 'anim', legend = { s = 'pele.2' },
        layers = { { name = 'c', albedo = { 'sss', 's.s' } } },
    }, { resolve = resolve })
    assert(anim.frames == 2 and anim.w == 3 and anim.imageData.albedo:getWidth() == 6,
        'frames enfileirados na horizontal')

    return true
end

return SpriteDSL
