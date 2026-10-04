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

local MAX_LIGHTS = 8

-- ── Shaders ──────────────────────────────────────────────────────────
-- Dois shaders de luz: um com uniform array (fast-path, todas as fontes sem
-- oclusão num passe só) e um escalar (uma fonte por vez, quando há sombra a
-- multiplicar — sombra é por fonte, então a contribuição precisa vir isolada).

local SHADER_ALL = [[
#define MAXLIGHTS 8
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

local SHADER_COMPOSE = [[
uniform Image lightmapTex;
uniform Image emissiveTex;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec4 a = Texel(tex, uv);
    vec3 lit = a.rgb * Texel(lightmapTex, uv).rgb
             + Texel(emissiveTex, uv).rgb; // emissivo passa direto, sem atenuação
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
-- Retorna vértices achatados + centro (para a cópia dilatada da borda).
local function shadowPoly(o, l, camX, camY)
    local cx, cy = o.x + o.w / 2, o.y + o.h / 2
    local dx, dy = cx - l.x, cy - l.y
    local dl = math.sqrt(dx * dx + dy * dy)
    if dl < 0.001 then dx, dy, dl = 0, 1, 1 end -- luz exatamente acima: direção arbitrária estável
    dx, dy = dx / dl, dy / dl
    local H = o.height or 32
    -- Sombra alonga com luz baixa/próxima e encurta com luz alta;
    -- o clamp evita sombra infinita com lz perto do chão e sombra nula no zenite.
    local len = H * (l.radius * 0.6) / math.max(l.z, 8)
    len = math.max(H * 0.5, math.min(len, H * 3))
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
    return verts, ccx / #h, ccy / #h
end

-- Cópia dilatada do polígono em torno do centróide — anel externo da sombra.
local function dilate(verts, cx, cy, s)
    local out = {}
    for i = 1, #verts, 2 do
        out[i]     = cx + (verts[i] - cx) * s
        out[i + 1] = cy + (verts[i + 1] - cy) * s
    end
    return out
end

-- ── Instância ────────────────────────────────────────────────────────

function Lighting.new(viewW, viewH)
    local self = setmetatable({}, Lighting)
    self.enabled = true
    self.lightScale = 2 -- supersample do lightmap (anti-banding, §refugio-hd)
    self.w, self.h = 0, 0
    self.lights = {}
    self.occluders = {}
    self.ambient = { 0.08, 0.08, 0.10 } -- baixo: cena escura ainda legível
    self.stats = { lights = 0, occluders = 0, lightPassMs = 0, shadowQuads = 0 }

    self.shaderAll = compile(SHADER_ALL, 'multi')
    self.shaderSingle = compile(SHADER_SINGLE, 'single')
    self.shaderCompose = compile(SHADER_COMPOSE, 'compose')
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
    if #self.lights >= MAX_LIGHTS then return end -- orçamento §3.3: ~8 fontes
    local c = l.color or { 1, 1, 1 }
    local inten = l.intensity or 1
    self.lights[#self.lights + 1] = {
        x = l.x or 0, y = l.y or 0, z = l.z or 30,
        color = c, radius = l.radius or 220, intensity = inten,
        flicker = l.flicker,
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
    local nLights = math.min(#self.lights, MAX_LIGHTS)
    local shadowQuads = 0

    -- Occluders relevantes por luz: só projetam sombra se a luz está acima
    -- do chão e o occluder está dentro do alcance (com folga para a sombra
    -- alongada ainda cair dentro do raio).
    local occSets, anyShadow = {}, false
    for i = 1, nLights do
        local l = self.lights[i]
        local set = {}
        if l.z > 4 then
            local rr = l.radius * 1.3
            for j = 1, #self.occluders do
                local o = self.occluders[j]
                local dx = (o.x + o.w / 2) - l.x
                local dy = (o.y + o.h / 2) - l.y
                if dx * dx + dy * dy <= rr * rr then set[#set + 1] = o end
            end
        end
        occSets[i] = set
        if #set > 0 then anyShadow = true end
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
                local l = self.lights[i]
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
        -- Luzes sem oclusão ainda vão juntas num passe de array; só as
        -- ocluídas pagam o custo do lightTmp por fonte.
        local free = {}
        for i = 1, nLights do
            if #occSets[i] == 0 then free[#free + 1] = i end
        end
        if #free > 0 then
            local pos, col, rad = {}, {}, {}
            for k = 1, #free do
                local l = self.lights[free[k]]
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
            local set = occSets[i]
            if #set > 0 then
                local l = self.lights[i]
                -- Contribuição isolada em lightTmp → sombra multiplica →
                -- soma no lightmap. Sombra da luz A não toca a luz B.
                G.setCanvas(self.lightTmp)
                G.clear(0, 0, 0, 1)
                drawSingle(self, l, camX, camY, 'replace')
                G.setShader()
                G.setBlendMode('multiply', 'premultiplied')
                for j = 1, #set do
                    local verts, ccx, ccy = shadowPoly(set[j], l, camX, camY)
                    if verts then
                        -- dois tons: anel dilatado mais claro + núcleo denso,
                        -- borda suave sem custo de blur. ×ls: os polígonos
                        -- nascem em espaço de vista e o lightTmp é 2×.
                        local sv = {}
                        for k = 1, #verts do sv[k] = verts[k] * ls end
                        ccx, ccy = ccx * ls, ccy * ls
                        G.setColor(0.55, 0.55, 0.55, 1)
                        G.polygon('fill', dilate(sv, ccx, ccy, 1.15))
                        G.setColor(0.35, 0.35, 0.35, 1)
                        G.polygon('fill', sv)
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
