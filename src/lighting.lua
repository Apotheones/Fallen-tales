-- src/lighting.lua — passe de luz dinâmica do pipeline §3.3 (MEGAPLAN_VISUAL_HD).
--
-- Três estágios por frame:
--   1. lightmap (canvas interno) = ambiente + Σ contribuição de cada fonte,
--      computada per-pixel contra o normal map da cena;
--   2. sombras projetadas por occluder×fonte, multiplicadas sobre a
--      contribuição isolada daquela fonte (canvas lightTmp) — assim a sombra
--      da luz A nunca apaga a luz B;
--   3. compose: albedo * lightmap + emissivo, desenhado no canvas que estiver
--      bound pelo chamador (o HDR fica a cargo do postfx).
--
-- Convenção de normal map (contrato-fase0-hd, bake do sprite_dsl):
--   normal.r = +x para a direita, normal.g = +y para CIMA na tela
--   (borda de cima de um relevo fica com G alto), normal.b = +z pra fora.
--   RGB 0..1 codifica XYZ -1..1: piso plano = (0.5,0.5,1). A = cobertura
--   (255 dentro do sprite, 0 fora). O shader trabalha em espaço de tela
--   (y para baixo), então decodifica e inverte o G: n.y = -n.y.
--
-- Sem shader (GLSL indisponível ou ARROWFALLEN_NO_SHADER=1) o módulo cai no
-- fallback: compose desenha albedo + emissivo direto e a cena continua
-- legível, apenas sem luz dinâmica.

local G = love.graphics

local Lighting = {}
Lighting.__index = Lighting

local MAX_LIGHTS = 12

-- ── Shaders ──────────────────────────────────────────────────────────
-- Dois shaders de luz: um com uniform array (fast-path, todas as fontes sem
-- oclusão num passe só) e um escalar (uma fonte por vez, quando há sombra a
-- multiplicar — sombra é por fonte, então a contribuição precisa vir isolada).

local SHADER_ALL = [[
#define MAXLIGHTS 12
uniform Image normalTex;
uniform vec3 lightPos[MAXLIGHTS];    // x,y em px de VISTA; z = altura
uniform vec3 lightColor[MAXLIGHTS];  // cor*intensity*flicker, resolvido na CPU
uniform float lightRadius[MAXLIGHTS];
uniform int lightCount;

vec3 contrib(vec3 n, vec2 sc, vec3 lp, vec3 lc, float lr) {
    vec3 L = vec3(lp.xy - sc, lp.z);
    float dist = length(L);
    float att = clamp(1.0 - dist / max(lr, 1.0), 0.0, 1.0);
    att *= att; // queda quadrática: borda morre suave, núcleo concentra
    vec3 Ln = L / max(dist, 0.0001);
    // wrap 0.85/0.15: normais quase verticais (frente de parede) ainda
    // recebem um piso de luz em vez de ficarem pretas.
    float diff = max(dot(n, Ln) * 0.85 + 0.15, 0.0);
    return lc * att * diff;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec3 n = Texel(normalTex, uv).rgb * 2.0 - 1.0;
    n.y = -n.y; // contrato: +Y para cima na tela; sc cresce para baixo
    n = normalize(n);
    vec3 acc = vec3(0.0);
    for (int i = 0; i < MAXLIGHTS; i++) {
        if (i >= lightCount) break;
        acc += contrib(n, sc, lightPos[i], lightColor[i], lightRadius[i]);
    }
    return vec4(acc, 1.0);
}
]]

local SHADER_SINGLE = [[
uniform Image normalTex;
uniform vec3 lightPos;
uniform vec3 lightColor;
uniform float lightRadius;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec3 n = Texel(normalTex, uv).rgb * 2.0 - 1.0;
    n.y = -n.y; // contrato: +Y para cima na tela
    n = normalize(n);
    vec3 L = vec3(lightPos.xy - sc, lightPos.z);
    float dist = length(L);
    float att = clamp(1.0 - dist / max(lightRadius, 1.0), 0.0, 1.0);
    att *= att;
    vec3 Ln = L / max(dist, 0.0001);
    float diff = max(dot(n, Ln) * 0.85 + 0.15, 0.0);
    return vec4(lightColor * att * diff, 1.0);
}
]]

-- Passe de sombra: multiplica a contribuição da luz isolada. O fator
-- esmaece AO LONGO da projeção (smoothstep em t) — a sombra respira: densa
-- no pé do occluder, quase invisível na ponta. Dois desenhos por occluder
-- (anel dilatado translúcido + casco) dão a pena de borda de 1-2 degraus.
local SHADER_SHADOW = [[
uniform vec2 occC;   // centro do occluder, px do lightmap (escalado)
uniform vec2 sdir;   // direção da projeção, unitária
uniform float slen;  // comprimento total da projeção
uniform float core;  // multiplicador no pé da sombra

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    float t = clamp(dot(sc - occC, sdir) / max(slen, 1.0), 0.0, 1.0);
    t = t * t * (3.0 - 2.0 * t);
    float f = mix(core, 1.0, t);
    return vec4(f, f, f, 1.0) * color;
}
]]

local SHADER_COMPOSE = [[
uniform Image lightmapTex;
uniform Image emissiveTex;
uniform float debugLightmapOnly;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec4 a = Texel(tex, uv);
    vec3 lit = a.rgb * Texel(lightmapTex, uv).rgb
             + Texel(emissiveTex, uv).rgb; // emissivo passa direto, sem atenuação
    if (debugLightmapOnly > 0.5) return vec4(Texel(lightmapTex, uv).rgb, 1.0);
    return vec4(lit, a.a);
}
]]

local function compile(src, tag)
    if os.getenv('ARROWFALLEN_NO_SHADER') then return nil end
    local ok, sh = pcall(G.newShader, src)
    if ok and sh then return sh end
    print('[lighting] shader ' .. tag .. ' indisponível — fallback albedo+emissivo: '
        .. tostring(sh))
    return nil
end

-- ── Hull convexo (monotone chain) ────────────────────────────────────
-- A sombra projetada é o hull dos 4 cantos do footprint + os 4 cantos
-- transladados na direção oposta à luz: um hexágono único, sem quads
-- sobrepostos (overlap multiplicaria a sombra duas vezes e escureceria demais).

local function cross2(o, a, b)
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
end

local function convexHull(pts)
    table.sort(pts, function(a, b)
        return a.x < b.x or (a.x == b.x and a.y < b.y)
    end)
    local n = #pts
    if n <= 2 then return pts end
    local lower = {}
    for i = 1, n do
        local p = pts[i]
        while #lower >= 2 and cross2(lower[#lower - 1], lower[#lower], p) <= 0 do
            lower[#lower] = nil
        end
        lower[#lower + 1] = p
    end
    local upper = {}
    for i = n, 1, -1 do
        local p = pts[i]
        while #upper >= 2 and cross2(upper[#upper - 1], upper[#upper], p) <= 0 do
            upper[#upper] = nil
        end
        upper[#upper + 1] = p
    end
    lower[#lower] = nil -- último de cada cadeia repete o início da outra
    upper[#upper] = nil
    local h = {}
    for i = 1, #lower do h[#h + 1] = lower[i] end
    for i = 1, #upper do h[#h + 1] = upper[i] end
    return h
end

-- Polígono de sombra de um occluder para uma luz, já em espaço de vista.
-- Retorna vértices achatados + centro, direção e comprimento (o shader usa
-- direção/comprimento para o esmaecimento longitudinal).
local function shadowPoly(o, l, camX, camY, capAbs, capRel)
    local cx, cy = o.x + o.w / 2, o.y + o.h / 2
    local dx, dy = cx - l.x, cy - l.y
    local dl = math.sqrt(dx * dx + dy * dy)
    if dl < 0.001 then dx, dy, dl = 0, 1, 1 end -- luz exatamente acima: direção arbitrária estável
    dx, dy = dx / dl, dy / dl
    local H = o.height or 32
    -- Comprimento físico h × distância-chão/z, dupla trava: ~capRel× a
    -- altura do occluder E teto absoluto capAbs (default 192px = 3 cél) —
    -- parede de 340px não vira faixa de 680px atravessando a praça; a
    -- sombra de pontual fica próxima do pé (drama, não listra). O sol de
    -- fim de tarde pede capas mais longas: o caller de bake passa mais.
    local len = H * dl / math.max(l.z, 20)
    len = math.max(H * 0.5,
        math.min(len, H * (capRel or 2), capAbs or 192))
    local sx, sy = dx * len, dy * len
    local pts = {
        { x = o.x,         y = o.y },
        { x = o.x + o.w,   y = o.y },
        { x = o.x + o.w,   y = o.y + o.h },
        { x = o.x,         y = o.y + o.h },
        { x = o.x + sx,        y = o.y + sy },
        { x = o.x + o.w + sx,  y = o.y + sy },
        { x = o.x + o.w + sx,  y = o.y + o.h + sy },
        { x = o.x + sx,        y = o.y + o.h + sy },
    }
    local h = convexHull(pts)
    if #h < 3 then return nil end
    local verts, ccx, ccy = {}, 0, 0
    for i = 1, #h do
        local vx, vy = h[i].x - camX, h[i].y - camY
        verts[#verts + 1] = vx
        verts[#verts + 1] = vy
        ccx, ccy = ccx + vx, ccy + vy
    end
    -- centro do OCCLUDER (não do casco) como origem de t no shader
    return verts, ccx / #h, ccy / #h, cx - camX, cy - camY, dx, dy, len
end

-- AABB do casco toca a vista? Occluder fora da tela (ou cuja sombra cai
-- fora) não precisa rasterizar nada — no mapa real são ~100 occluders e
-- só ~15 pousam na vista (corte de custo dominante do gameplay).
-- Margem de cull (Vespa): ~2 células do lightmap além da borda — o
-- conjunto de polígonos soma/subtrai longe da tela, nunca num passo
-- de 1px da câmera. Também cobre o anel de penumbra além do casco.
local CULL_MARGIN = 160
local function hullVisible(verts, w, h)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for i = 1, #verts, 2 do
        local x, y = verts[i], verts[i + 1]
        if x < minX then minX = x end
        if x > maxX then maxX = x end
        if y < minY then minY = y end
        if y > maxY then maxY = y end
    end
    return maxX >= -CULL_MARGIN and minX <= w + CULL_MARGIN
        and maxY >= -CULL_MARGIN and minY <= h + CULL_MARGIN
end

-- Scratch reutilizado por occluder×luz×frame (M10): sem isso cada sombra
-- alocava duas tabelas novas por frame — churn de GC no passe quente.
local svScratch, dvScratch = {}, {}

-- Cópia dilatada do polígono em torno do centróide — anel externo da sombra.
-- Escreve em `out` (pool), devolve a própria tabela.
local function dilate(verts, cx, cy, s, out)
    for i = 1, #verts, 2 do
        out[i]     = cx + (verts[i] - cx) * s
        out[i + 1] = cy + (verts[i + 1] - cy) * s
    end
    for i = #verts + 1, #out do out[i] = nil end
    return out
end

-- ── Instância ────────────────────────────────────────────────────────

function Lighting.new(viewW, viewH)
    local self = setmetatable({}, Lighting)
    self.enabled = true
    -- Supersample do lightmap: 1.5× lisa o gradiente e as sombras sem o
    -- custo 4× do 2× — o debanding pesado fica na LUT linear + dither.
    -- Adapta por área da vista em resize(): >~1.4Mpx cai pra 1.25× (1920
    -- é onde o passe de sol dominava o frame).
    -- Padrão-ouro: pin em 1.25 — 1.5 mordia no light pass (Vespa/Mira).
    self.lightScale = tonumber(os.getenv('ARROWFALLEN_LIGHTSCALE')) or 1.25
    self._lsFixed = os.getenv('ARROWFALLEN_LIGHTSCALE') ~= nil
    self.w, self.h = 0, 0
    self.lights = {}
    self.occluders = {}
    self.ambient = { 0.08, 0.08, 0.10 } -- baixo: cena escura ainda legível
    self.stats = { lights = 0, occluders = 0, lightPassMs = 0, shadowQuads = 0 }

    self.shaderAll = compile(SHADER_ALL, 'multi')
    self.shaderSingle = compile(SHADER_SINGLE, 'single')
    self.shaderCompose = compile(SHADER_COMPOSE, 'compose')
    self.shaderShadow = compile(SHADER_SHADOW, 'shadow')
    -- Envs de depuração içadas no ctor: os.getenv por frame é syscall por
    -- chamada (M5) — o processo não troca env a meio da execução.
    self._dbgLightmapOnly = os.getenv('ARROWFALLEN_SHOW_LIGHTMAP2') and 1 or 0
    if not (self.shaderAll and self.shaderSingle and self.shaderCompose) then
        self.enabled = false
    end

    -- Texturas dummy 1×1 para normal/emissivo ausentes: normal plano e
    -- emissivo zero, assim o contrato aceita nil sem bifurcar o shader.
    local idN = love.image.newImageData(1, 1)
    idN:setPixel(0, 0, 0.5, 0.5, 1, 1)
    self.dummyNormal = G.newImage(idN)
    local idE = love.image.newImageData(1, 1)
    idE:setPixel(0, 0, 0, 0, 0, 1)
    self.dummyEmissive = G.newImage(idE)

    self:resize(viewW, viewH)
    if not self.lightmap then self.enabled = false end
    return self
end

function Lighting:resize(w, h)
    w, h = math.max(1, math.floor(w or 1)), math.max(1, math.floor(h or 1))
    if w == self.w and h == self.h and self.lightmap then return end
    self.w, self.h = w, h
    if not self._lsFixed then
        self.lightScale = (w * h > 1400000) and 1.25 or 1.5
    end
    -- Lightmap a lightScale× a vista (supersample): o gradiente de luz é
    -- contínuo por natureza — renderizar gordo e descer com filtro linear
    -- mata o banding de anéis que o texel 1:1 quantiza. Posições/raios e
    -- sombras chegam ao passe já multiplicados por `ls`.
    local ls = self.lightScale or 2
    self.lw, self.lh = w * ls, h * ls
    -- rgba16f quando há suporte: luz HDR (>1) não pode clampar antes do bloom.
    local fmt = 'rgba8'
    local okF, formats = pcall(G.getCanvasFormats)
    if okF and formats and formats['rgba16f'] then fmt = 'rgba16f' end
    local ok1, lm = pcall(G.newCanvas, self.lw, self.lh, { format = fmt })
    local ok2, lt = pcall(G.newCanvas, self.lw, self.lh, { format = fmt })
    if ok1 and lm and ok2 and lt then
        self.lightmap, self.lightTmp = lm, lt
        -- linear no lightmap: é o downsample suave na amostragem do compose.
        self.lightmap:setFilter('linear', 'linear')
        self.lightTmp:setFilter('linear', 'linear')
    else
        self.lightmap, self.lightTmp = nil, nil
        self.enabled = false
        print('[lighting] canvas de luz falhou (' .. fmt .. ') — fallback ativo')
    end
end

function Lighting:beginFrame()
    self.lights = {}
    self.occluders = {}
end

function Lighting:addLight(l)
    if #self.lights >= MAX_LIGHTS then return end -- orçamento §3.3
    local c = l.color or { 1, 1, 1 }
    local inten = l.intensity or 1
    self.lights[#self.lights + 1] = {
        x = l.x or 0, y = l.y or 0, z = l.z or 30,
        color = c, radius = l.radius or 220, intensity = inten,
        flicker = l.flicker, shadow = l.shadow,
        -- mask = máscara de sombra assada (§3.3, fonte estática tipo sol):
        -- substitui os shadow quads por 1 multiply de textura por frame.
        mask = l.mask,
        -- prio desempata o corte no MAX_LIGHTS: 0 máscara/dominante,
        -- 1 flicker (drama), 2 compostas, 3 âncoras genéricas de prop.
        prio = l.prio or (l.mask and 0 or (l.flicker and 1 or 2)),
        _seq = #self.lights + 1,
        -- valores resolvidos em update(); defaults aqui caso update não rode.
        _f = 1, _r = c[1] * inten, _g = c[2] * inten, _b = c[3] * inten,
    }
end

function Lighting:addOccluder(o)
    self.occluders[#self.occluders + 1] = {
        x = o.x or 0, y = o.y or 0,
        w = o.w or 8, h = o.h or 8, height = o.height or 32,
    }
end

-- Caminho em massa para geometria estática cacheada pelo chamador:
-- os itens vão por referência (compose só lê) — sem realocar por frame.
function Lighting:addOccluders(list)
    local occ = self.occluders
    for i = 1, #list do occ[#occ + 1] = list[i] end
end

function Lighting:setAmbient(c)
    self.ambient = { c[1] or 0, c[2] or 0, c[3] or 0 }
end

-- Flicker: duas senoides dessincronizadas (2.37 ≈ irracional relativo) dão
-- tremulação de chama sem padrão óbvio. Movimento reduzido zera a amplitude
-- mas mantém a luz média — a informação luminosa não pode piscar nem sumir.
function Lighting:update(t, reducedMotion)
    for i = 1, #self.lights do
        local l = self.lights[i]
        local f = 1
        if l.flicker and not reducedMotion then
            local amp = l.flicker.amp or 0
            local sp = l.flicker.speed or 6
            local ph = l.flicker.phase or 0
            f = 1 + amp * (0.6 * math.sin(t * sp + ph)
                         + 0.4 * math.sin(t * sp * 2.37 + ph * 1.7))
        end
        l._f = f
        l._r = l.color[1] * l.intensity * f
        l._g = l.color[2] * l.intensity * f
        l._b = l.color[3] * l.intensity * f
    end
end

function Lighting:lightCount()
    return #self.lights
end

-- Assa a máscara de sombra de UMA fonte estática contra a lista completa
-- de occluders (§3.3 "máscara assada por fonte estática"). O canvas cobre
-- o retângulo mundo (x,y,w,h) a `scale`× — sombras longas do sol nascem
-- prontas; por frame resta 1 multiply de textura sobre a contribuição
-- isolada da fonte, que ainda passa pelo normal map (atores inclusos).
-- Retorna {canvas, x, y, scale} ou nil (sem shader/GPU → caller decide
-- se cai no caminho vivo de shadow quads).
function Lighting:bakeShadowMask(light, occluders, x, y, w, h, scale, cap)
    scale = scale or 0.5
    if not self.shaderShadow then return nil end
    local mw = math.max(1, math.floor(w * scale))
    local mh = math.max(1, math.floor(h * scale))
    local ok, canvas = pcall(G.newCanvas, mw, mh, {format = 'rgba8'})
    if not (ok and canvas) then return nil end
    canvas:setFilter('linear', 'linear')

    local prevCanvas = G.getCanvas()
    local prevShader = G.getShader()
    local prevBM, prevAM = G.getBlendMode()
    local pr, pg, pb, pa = G.getColor()
    G.push('all')
    G.origin()
    G.setCanvas(canvas)
    G.clear(1, 1, 1, 1) -- 1 = sem sombra; o min escurece onde projeta
    -- 'darken' (min) em vez de multiply: sombra é visibilidade, não
    -- absorção — duas projeções cruzadas ficam na mais escura das duas,
    -- nunca somam até o preto (faixas de 0.17*0.17=0.03 no pátio).
    G.setBlendMode('darken', 'premultiplied')
    local sh = self.shaderShadow
    G.setShader(sh)
    local sv, dv = {}, {}
    for _, o in ipairs(occluders) do
        local verts, ccx, ccy, ocx, ocy, dx, dy, len =
            shadowPoly(o, light, x, y,
                cap and cap.abs, cap and cap.rel) -- cam=origem da máscara
        if verts then
            for k = 1, #verts do sv[k] = verts[k] * scale end
            for k = #verts + 1, #sv do sv[k] = nil end
            local cx2, cy2 = ccx * scale, ccy * scale
            sh:send('occC', {ocx * scale, ocy * scale})
            sh:send('sdir', {dx, dy})
            sh:send('slen', math.max(len * scale, 1))
            -- cap.pen/core: fonte pode pedir sombra mais funda (sol de
            -- fim de tarde) que o default das pontuais (.70/.24).
            sh:send('core', cap and cap.pen or 0.70)
            G.polygon('fill', dilate(sv, cx2, cy2, 1.24, dv))
            sh:send('core', cap and cap.core or 0.24)
            G.polygon('fill', sv)
        end
    end
    G.pop()
    G.setCanvas(prevCanvas)
    G.setShader(prevShader)
    G.setBlendMode(prevBM, prevAM)
    G.setColor(pr, pg, pb, pa)
    return {canvas = canvas, x = x, y = y, scale = scale}
end

-- Ordem de trabalho por frame: sort estável por prio (0 máscara, 1 flicker,
-- 2 composta, 3 âncora) com _seq de desempate — luz igual não troca de
-- lugar quando o array lota, senão âncoras piscariam ao mover a câmera.
local ordScratch = {}
local function sortedLights(self)
    local n = #self.lights
    for i = 1, n do ordScratch[i] = self.lights[i] end
    for i = n + 1, #ordScratch do ordScratch[i] = nil end
    if n > 1 then
        table.sort(ordScratch, function(a, b)
            if a.prio ~= b.prio then return a.prio < b.prio end
            return a._seq < b._seq
        end)
    end
    return ordScratch
end

-- Desenha uma fonte isolada no canvas atual (já bound pelo compose).
local function drawSingle(self, l, camX, camY, blendMode)
    local ls = self.lightScale or 1
    local sh = self.shaderSingle
    sh:send('lightPos', { (l.x - camX) * ls, (l.y - camY) * ls, l.z * ls })
    sh:send('lightColor', { l._r, l._g, l._b })
    sh:send('lightRadius', l.radius * ls)
    sh:send('normalTex', self._normal)
    G.setShader(sh)
    G.setBlendMode(blendMode)
    G.setColor(1, 1, 1, 1)
    -- quad só sobre o alcance da luz: fora do raio a atenuação já é zero.
    local lx, ly = (l.x - camX) * ls, (l.y - camY) * ls
    local x0 = math.max(0, lx - l.radius * ls)
    local y0 = math.max(0, ly - l.radius * ls)
    local x1 = math.min(self.lw, lx + l.radius * ls)
    local y1 = math.min(self.lh, ly + l.radius * ls)
    if x1 > x0 and y1 > y0 then
        G.rectangle('fill', x0, y0, x1 - x0, y1 - y0)
    end
end

-- Compõe a cena iluminada DENTRO do canvas atualmente bound.
-- camX,camY: offset mundo→vista (frag mundo = sc + cam; luz vem em mundo).
function Lighting:compose(albedoCanvas, normalCanvas, emissiveCanvas, camX, camY)
    local t0 = love.timer.getTime()
    camX, camY = camX or 0, camY or 0
    emissiveCanvas = emissiveCanvas or self.dummyEmissive

    local prevCanvas = G.getCanvas()
    local prevShader = G.getShader()
    local prevBM, prevAM = G.getBlendMode()
    local pr, pg, pb, pa = G.getColor()

    if not self.enabled then
        -- Fallback: a cena aparece mesmo sem GPU shader — só perde a luz.
        G.setShader()
        G.setBlendMode('alpha', 'alphamultiply')
        G.setColor(1, 1, 1, 1)
        G.draw(albedoCanvas, 0, 0)
        G.setBlendMode('add', 'alphamultiply')
        G.draw(emissiveCanvas, 0, 0)
        self:_finish(t0, prevCanvas, prevShader, prevBM, prevAM, pr, pg, pb, pa, 0)
        return
    end

    self._normal = normalCanvas or self.dummyNormal
    local ord = sortedLights(self)
    local nLights = math.min(#ord, MAX_LIGHTS)
    local shadowQuads = 0

    -- Occluders relevantes por luz: só projetam sombra se a luz está acima
    -- do chão e o occluder está dentro do alcance (com folga para a sombra
    -- alongada ainda cair dentro do raio).
    local occSets, anyShadow = {}, false
    for i = 1, nLights do
        local l = ord[i]
        local set = {}
        -- shadow=false: a fonte dominante (sol/céu) modela por normal
        -- map + ambiente, sem sombra geométrica — drama é das pontuais.
        -- l.mask: fonte com máscara assada não coleta occluder por frame.
        if l.z > 4 and l.shadow ~= false and not l.mask then
            local rr = l.radius * 1.3
            for j = 1, #self.occluders do
                local o = self.occluders[j]
                local dx = (o.x + o.w / 2) - l.x
                local dy = (o.y + o.h / 2) - l.y
                if dx * dx + dy * dy <= rr * rr then set[#set + 1] = o end
            end
        end
        occSets[i] = set
        if #set > 0 or l.mask then anyShadow = true end
    end

    -- Polígonos de sombra visíveis por luz: hull e AABB computados uma
    -- vez aqui — luz cuja sombra toda cai fora da vista entra no batch
    -- grátis (sem lightTmp), e o loop de desenho não repete matemática.
    local polys = {}
    if anyShadow then
        for i = 1, nLights do
            local list = {}
            for j = 1, #occSets[i] do
                local verts, ccx, ccy, ocx, ocy, dx, dy, len =
                    shadowPoly(occSets[i][j], ord[i], camX, camY)
                if verts and hullVisible(verts, self.w, self.h) then
                    list[#list + 1] = {verts = verts, cx = ccx, cy = ccy,
                        ocx = ocx, ocy = ocy, dx = dx, dy = dy, len = len}
                end
            end
            polys[i] = list
        end
    end

    G.push()
    G.origin()

    -- ── Estágio 1: lightmap = ambiente + luzes ──
    G.setCanvas(self.lightmap)
    G.clear(self.ambient[1], self.ambient[2], self.ambient[3], 1)

    local ls = self.lightScale or 1
    if not anyShadow then
        -- Fast-path: todas as fontes num passe só via uniform array.
        if nLights > 0 then
            local pos, col, rad = {}, {}, {}
            for i = 1, nLights do
                local l = ord[i]
                pos[i] = { (l.x - camX) * ls, (l.y - camY) * ls, l.z * ls }
                col[i] = { l._r, l._g, l._b }
                rad[i] = l.radius * ls
            end
            local sh = self.shaderAll
            sh:send('lightPos', unpack(pos))
            sh:send('lightColor', unpack(col))
            sh:send('lightRadius', unpack(rad))
            sh:send('lightCount', nLights)
            sh:send('normalTex', self._normal)
            G.setShader(sh)
            G.setBlendMode('add', 'alphamultiply')
            G.setColor(1, 1, 1, 1)
            G.rectangle('fill', 0, 0, self.lw, self.lh)
        end
    else
        -- Luzes sem sombra VISÍVEL (sem occluder ou sombra toda fora da
        -- vista) vão juntas no passe de array; só quem realmente sombreia
        -- paga o lightTmp isolado.
        local free = {}
        for i = 1, nLights do
            if #polys[i] == 0 and not ord[i].mask then
                free[#free + 1] = i
            end
        end
        if #free > 0 then
            local pos, col, rad = {}, {}, {}
            for k = 1, #free do
                local l = ord[free[k]]
                pos[k] = { (l.x - camX) * ls, (l.y - camY) * ls, l.z * ls }
                col[k] = { l._r, l._g, l._b }
                rad[k] = l.radius * ls
            end
            local sh = self.shaderAll
            sh:send('lightPos', unpack(pos))
            sh:send('lightColor', unpack(col))
            sh:send('lightRadius', unpack(rad))
            sh:send('lightCount', #free)
            sh:send('normalTex', self._normal)
            G.setShader(sh)
            G.setBlendMode('add', 'alphamultiply')
            G.setColor(1, 1, 1, 1)
            G.rectangle('fill', 0, 0, self.lw, self.lh)
        end
        for i = 1, nLights do
            local l = ord[i]
            local set = polys[i]
            if l.mask or (set and #set > 0) then
                -- Contribuição isolada em lightTmp → sombra multiplica →
                -- soma no lightmap. Sombra da luz A não toca a luz B.
                G.setCanvas(self.lightTmp)
                G.clear(0, 0, 0, 1)
                drawSingle(self, l, camX, camY, 'replace')
                G.setShader()
                G.setBlendMode('multiply', 'premultiplied')
                if l.mask then
                    -- Máscara assada (§3.3): 1 multiply de textura cobre
                    -- todos os occluders estáticos da fonte — o N·L do
                    -- pixel segue vivo no drawSingle acima.
                    local m = l.mask
                    local ms = ls / m.scale
                    G.setColor(1, 1, 1, 1)
                    G.draw(m.canvas, (m.x - camX) * ls,
                        (m.y - camY) * ls, 0, ms, ms)
                else
                for j = 1, #set do
                    local p = set[j]
                    local verts = p.verts
                    -- Dois desenhos com o shader de sombra (fator esmaece
                    -- ao longo da projeção): anel dilatado translúcido =
                    -- pena de 1-2 degraus; casco com núcleo ~0.27.
                    -- 0.80 × 0.275 ≈ 0.22 no pé — sombra, não viga.
                    local sv = svScratch
                    for k = 1, #verts do sv[k] = verts[k] * ls end
                    for k = #verts + 1, #sv do sv[k] = nil end
                    local ccx, ccy = p.cx * ls, p.cy * ls
                    local sh = self.shaderShadow
                    if sh then
                        sh:send('occC', { p.ocx * ls, p.ocy * ls })
                        sh:send('sdir', { p.dx, p.dy })
                        sh:send('slen', math.max(p.len * ls, 1))
                        G.setShader(sh)
                        -- Penumbra mais larga (dilate 1.24) + núcleos
                        -- suavizados: a transição na face do muro esmaece
                        -- em vez de cortar (crítica Mira/Calina r3).
                        sh:send('core', 0.70)
                        G.polygon('fill', dilate(sv, ccx, ccy, 1.24,
                            dvScratch))
                        sh:send('core', 0.24)
                        G.polygon('fill', sv)
                        G.setShader()
                    else
                        G.setColor(0.75, 0.75, 0.75, 1)
                        G.polygon('fill', dilate(sv, ccx, ccy, 1.10,
                            dvScratch))
                        G.setColor(0.28, 0.28, 0.28, 1)
                        G.polygon('fill', sv)
                    end
                    shadowQuads = shadowQuads + 1
                end
                end
                G.setCanvas(self.lightmap)
                G.setShader()
                G.setBlendMode('add', 'alphamultiply')
                G.setColor(1, 1, 1, 1)
                G.draw(self.lightTmp, 0, 0)
            end
        end
    end

    -- ── Estágio 2: compõe no canvas do chamador ──
    if prevCanvas then G.setCanvas(prevCanvas) else G.setCanvas() end
    local sh = self.shaderCompose
    sh:send('lightmapTex', self.lightmap)
    sh:send('emissiveTex', emissiveCanvas)
    sh:send('debugLightmapOnly', self._dbgLightmapOnly or 0)
    G.setShader(sh)
    G.setBlendMode('alpha', 'alphamultiply')
    G.setColor(1, 1, 1, 1)
    G.draw(albedoCanvas, 0, 0)

    G.pop()
    self:_finish(t0, prevCanvas, prevShader, prevBM, prevAM, pr, pg, pb, pa, shadowQuads)
end

function Lighting:_finish(t0, prevCanvas, prevShader, prevBM, prevAM, pr, pg, pb, pa, shadowQuads)
    -- restaura o estado gráfico do chamador: compose não pode vazar
    -- canvas/shader/blend para quem desenha depois.
    if prevCanvas then G.setCanvas(prevCanvas) else G.setCanvas() end
    G.setShader(prevShader)
    G.setBlendMode(prevBM, prevAM)
    G.setColor(pr, pg, pb, pa)
    local ms = (love.timer.getTime() - t0) * 1000
    local st = self.stats
    st.lights = math.min(#self.lights, MAX_LIGHTS)
    st.occluders = #self.occluders
    st.shadowQuads = shadowQuads
    st.lightPassMs = st.lightPassMs * 0.9 + ms * 0.1 -- média móvel: 1 frame não mente
end

-- Depuração mínima: posição das fontes em espaço de vista.
function Lighting:debugDraw(camX, camY)
    camX, camY = camX or 0, camY or 0
    for i = 1, #self.lights do
        local l = self.lights[i]
        G.setColor(l._r, l._g, l._b, 1)
        G.circle('line', l.x - camX, l.y - camY, 3)
    end
end

-- ── Self-check ───────────────────────────────────────────────────────
-- Prova os dois caminhos (com e sem shader) em canvases dummy; usado pelo
-- smoke test de tools/ e por qualquer boot diagnóstico.
function Lighting.selfCheck()
    local L = Lighting.new(64, 64)
    assert(L, 'lighting: instância não criada')
    assert(L.lightCount and L.lightCount(L) == 0, 'lighting: lightCount quebrado')
    L:setAmbient({ 0.1, 0.1, 0.12 })
    L:beginFrame()
    L:addLight({
        x = 32, y = 32, z = 30,
        color = { 1, 0.8, 0.5 }, radius = 100, intensity = 1,
        flicker = { amp = 0.2, speed = 5, phase = 0 },
    })
    L:addOccluder({ x = 20, y = 20, w = 10, h = 10, height = 40 })
    assert(L:lightCount() == 1, 'lighting: addLight falhou')
    L:update(0.5, false)
    L:update(0.5, true)
    assert(L.lights[1]._f == 1, 'lighting: reduced-motion não zerou flicker')

    local out = G.newCanvas(64, 64)
    local alb = G.newCanvas(64, 64)
    local nrm = G.newCanvas(64, 64)
    local emi = G.newCanvas(64, 64)
    G.setCanvas(nrm) G.clear(0.5, 0.5, 1, 1)
    G.setCanvas(alb) G.clear(0.4, 0.4, 0.4, 1)
    G.setCanvas(out) G.clear(0, 0, 0, 1)
    L:compose(alb, nrm, emi, 0, 0)
    L:compose(alb, nil, nil, 16, 16) -- normal/emissivo nil + câmera deslocada
    G.setCanvas()

    L:resize(32, 32)
    assert(L.w == 32 and L.h == 32, 'lighting: resize falhou')
    assert(L.stats.lights == 1 and L.stats.occluders == 1, 'lighting: stats errados')

    out:release() alb:release() nrm:release() emi:release()
    return true
end

return Lighting
