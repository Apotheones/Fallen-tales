-- src/hd_kit.lua — ferramenta compartilhada das cenas HD (prova-hd,
-- refugio-hd e as próximas): loader de sheets no contrato DSL
-- (contrato-fase0-hd) com stub procedural no mesmo formato, quads por
-- frame e âncoras de desenho.
--
-- Prioridade de carga: require('src.sprites.NOME') + SpriteDSL.bake quando
-- a def do Traço existe; senão o stub local (paint por pixel) assa albedo/
-- normal/emissivo equivalentes — troca é por nome, sem mudar a cena.

local G = love.graphics
local Kit = {}

function Kit.bakeViaDSL(name)
    local okDsl, DSL = pcall(require, 'src.sprite_dsl')
    local okDef, def = pcall(require, 'src.sprites.' .. name)
    if not (okDsl and okDef and DSL and DSL.bake and def) then return nil end
    local ok, sheet = pcall(DSL.bake, def)
    return ok and sheet and sheet.albedo and sheet or nil
end

-- Stub: paint(lx, ly) -> albedo{r,g,b,a}|nil, altura 0..15, emissivo{r,g,b}|nil.
-- Normal por diferenças centrais na convenção do contrato: +X direita,
-- +Y PARA CIMA na tela, +Z pra fora; alpha = cobertura.
function Kit.stubSheet(w, h, paint, strength)
    local alb = love.image.newImageData(w, h)
    local emi = love.image.newImageData(w, h)
    local hgt = {}
    for y = 0, h - 1 do for x = 0, w - 1 do
        local a, ht, e = paint(x, y)
        if a then alb:setPixel(x, y, a[1], a[2], a[3], a[4] or 1) end
        hgt[y * w + x] = ht or 0
        if e then emi:setPixel(x, y, e[1], e[2], e[3], 1) end
    end end
    local nrm = love.image.newImageData(w, h)
    local function hh(x, y)
        return hgt[math.max(0, math.min(h - 1, y)) * w + math.max(0, math.min(w - 1, x))] or 0
    end
    strength = strength or 2.2
    for y = 0, h - 1 do for x = 0, w - 1 do
        local gx = (hh(x + 1, y) - hh(x - 1, y)) / 15 * strength
        local gy = (hh(x, y + 1) - hh(x, y - 1)) / 15 * strength
        local nx, ny, nz = -gx, gy, 1
        local len = math.sqrt(nx * nx + ny * ny + nz * nz)
        local _, _, _, cov = alb:getPixel(x, y)
        nrm:setPixel(x, y, nx / len * .5 + .5, ny / len * .5 + .5, nz / len * .5 + .5,
            cov > 0 and 1 or 0)
    end end
    local function img(d) local i = G.newImage(d); i:setFilter('nearest', 'nearest'); return i end
    return {albedo = img(alb), normal = img(nrm), emissive = img(emi),
        w = w, h = h, frames = 1, origin = 'feet', stub = true,
        imageData = {albedo = alb, normal = nrm, emissive = emi}}
end

local function defaultPaint(x, y)
    return {.45, .12, .45, 1}, 4 -- magenta de placeholder: nunca fica invisível
end

function Kit.sheet(name, w, h, paint)
    return Kit.bakeViaDSL(name) or Kit.stubSheet(w, h, paint or defaultPaint)
end

-- Quads por frame (sheets enfileiram quadros na horizontal, sem padding).
function Kit.quads(sheet)
    local qs = {}
    for i = 1, (sheet.frames or 1) do
        qs[i] = G.newQuad((i - 1) * sheet.w, 0, sheet.w, sheet.h,
            sheet.albedo:getDimensions())
    end
    return qs
end

-- Variante estável por posição/semente (tiles 4f: cada frame é uma variante).
function Kit.variant(sheet, cx, cy, seed)
    local n = sheet.frames or 1
    if n <= 1 then return 1 end
    return 1 + ((cx * 31 + cy * 17 + (seed or 0) * 7) % n)
end

function Kit.drawFeet(sheet, quad, channel, x, y)
    G.draw(sheet[channel], quad, math.floor(x - sheet.w / 2),
        math.floor(y - sheet.h + 1))
end

function Kit.hash(x, y, s) return ((x * 73 + y * 151 + (s or 0) * 997) % 97) / 97 end

-- Ambiente por região (DIRECAO_AMBIENTAL): nível de preenchimento frio —
-- a dominante de cada região esquenta por cima. Valores calibrados na
-- praça: ~0.3 × nível 'amb' da nota, matiz do fill da região.
Kit.AMBIENT = {
    refugio = {.24, .26, .38},      -- sol SO âmbar + fill azul-violeta
    colina = {.22, .24, .34},       -- crepúsculo violeta, sem dominante
    necropole = {.16, .22, .19},    -- esverdeado úmido, ilhas de lamparina
    saloes = {.20, .18, .15},       -- dourado escuro de teatro
    oficinas = {.20, .21, .26},     -- cinza difuso + brasas
    reservatorio = {.20, .25, .22}, -- calcário + reflexo verde da água
    mercado = {.30, .26, .24},      -- ocre de toldo, mais claro
    fundacao = {.24, .25, .31},     -- cal azulada, dia cinza
    hub = {.24, .26, .38},
    neutro = {.18, .19, .26},
}

function Kit.ambient(region)
    return Kit.AMBIENT[region] or Kit.AMBIENT.neutro
end

return Kit
