-- src/postfx.lua — pipeline HDR de pós-processo (MEGAPLAN_VISUAL_HD §3.3.4).
--
-- Estágios: cena composta em canvas rgba16f (fallback rgba8) → bloom por
-- threshold alimentado EXCLUSIVAMENTE pelo canvas emissivo (fogo, runa,
-- marco — o piso nunca vaza porque o albedo nem entra no passe) → LUT de
-- color grading 16³ por região → vignette radial suave.
--
-- Arte 100% gerada por código: as LUTs nascem de ImageData em Lua, sem
-- nenhum asset importado. Os valores são tratados como lineares de ponta a
-- ponta — não fazemos conversão gama extra além do tonemap; o que importa
-- é o resultado visual coerente com a régua "pixel art lit moderna".

local G = love.graphics

local PostFX = {}
PostFX.__index = PostFX

local function clamp01(v)
    if v ~= v then return 0 end -- NaN de gamma em negativo não pode vazar
    return v < 0 and 0 or (v > 1 and 1 or v)
end

-- ── Shaders (GLSL ES via LÖVE) ────────────────────────────────────────

-- Bright pass: subtrai o threshold do emissivo. Como a fonte já é só o
-- canal emissivo, isto é segurança dupla — albedo nunca chega aqui.
local BRIGHT_SRC = [[
    uniform float threshold;
    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
        vec3 c = Texel(tex, uv).rgb;
        c = max(c - vec3(threshold), vec3(0.0));
        return vec4(c, 1.0) * color;
    }
]]

-- Blur gaussiano separável, 9 taps, sigma ~2.5 — pesos normalizados (soma 1).
-- `dir` recebe o passo em uv: {texelX, 0} horizontal, depois {0, texelY}.
local BLUR_SRC = [[
    uniform vec2 dir;
    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
        vec3 acc = Texel(tex, uv).rgb * 0.1716;
        acc += Texel(tex, uv + dir * 1.0).rgb * 0.1584;
        acc += Texel(tex, uv - dir * 1.0).rgb * 0.1584;
        acc += Texel(tex, uv + dir * 2.0).rgb * 0.1246;
        acc += Texel(tex, uv - dir * 2.0).rgb * 0.1246;
        acc += Texel(tex, uv + dir * 3.0).rgb * 0.0835;
        acc += Texel(tex, uv - dir * 3.0).rgb * 0.0835;
        acc += Texel(tex, uv + dir * 4.0).rgb * 0.0477;
        acc += Texel(tex, uv - dir * 4.0).rgb * 0.0477;
        return vec4(acc, 1.0) * color;
    }
]]

-- Composição final: +bloom (antes do tonemap, para o emissivo HDR empurrar
-- highlights de verdade) → exposição → ACES (fit de Narkowicz) → LUT 16³ →
-- vignette. A LUT é strip 256×16: fatia b*15 no eixo x de 16 em 16 texels;
-- interpolamos entre as duas fatias adjacentes de b para suavizar a grade.
local COMPOSITE_SRC = [[
    uniform Image bloomTex;
    uniform Image lutTex;
    uniform float exposure;
    uniform float bloomStrength;
    uniform float vignette;

    vec3 aces(vec3 x) {
        // Fit de Narkowicz da curva ACES: highlights macios, sem clip duro.
        return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14),
            0.0, 1.0);
    }

    vec3 lutLookup(vec3 c) {
        c = clamp(c, 0.0, 1.0);
        float bf = c.b * 15.0;
        float s0 = floor(bf);
        float s1 = min(s0 + 1.0, 15.0);
        float fr = bf - s0;
        float x0 = s0 * 16.0 + c.r * 15.0 + 0.5;
        float x1 = s1 * 16.0 + c.r * 15.0 + 0.5;
        float y = c.g * 15.0 + 0.5;
        vec3 c0 = Texel(lutTex, vec2(x0 / 256.0, y / 16.0)).rgb;
        vec3 c1 = Texel(lutTex, vec2(x1 / 256.0, y / 16.0)).rgb;
        return mix(c0, c1, fr);
    }

    float hash12(vec2 p) {
        vec3 p3 = fract(vec3(p.xyx) * 0.1031);
        p3 += dot(p3, p3.yzx + 33.33);
        return fract((p3.x + p3.y) * p3.z);
    }

    vec4 effect(vec4 color, Image sceneTex, vec2 uv, vec2 sc) {
        vec3 c = Texel(sceneTex, uv).rgb;
        c += Texel(bloomTex, uv).rgb * bloomStrength;
        c = aces(c * exposure);
        c = lutLookup(c);
        float d = distance(uv, vec2(0.5));
        c *= 1.0 - vignette * smoothstep(0.35, 0.72, d);
        // debanding: gradiente de luz em canvas 8-bit posteriza; um dither
        // de ±1.5/255 quebra o anel sem virar ruído visível.
        c += (hash12(sc) - 0.5) * (3.0 / 255.0);
        return vec4(c, 1.0) * color;
    }
]]

-- ── LUTs de grading regional ──────────────────────────────────────────
-- Cada região é um lift/gamma/gain + matiz de sombra por luminância. O
-- grading é propositalmente SUTIL: a LUT gradeia a cena, não pinta por cima.

-- fábrica de curva de cor: lift/gamma/gain por canal, saturação em torno da
-- luminância e mistura de matiz que pesa mais quanto mais escuro o texel.
local function gradeLGG(o)
    o = o or {}
    local lift = o.lift or {0, 0, 0}
    local gamma = o.gamma or {1, 1, 1}
    local gain = o.gain or {1, 1, 1}
    local tint = o.shadowTint
    local mixS = o.shadowMix or 0
    local sat = o.sat or 1
    return function(r, g, b)
        local c = {r, g, b}
        for i = 1, 3 do
            local v = c[i] * gain[i] + lift[i]
            c[i] = v > 0 and v ^ (1 / gamma[i]) or 0
        end
        local l = 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3]
        if sat ~= 1 then
            for i = 1, 3 do c[i] = l + (c[i] - l) * sat end
        end
        if tint and mixS > 0 then
            local w = (1 - clamp01(l)) ^ 1.6 * mixS
            for i = 1, 3 do c[i] = c[i] + (tint[i] - c[i]) * w end
        end
        return clamp01(c[1]), clamp01(c[2]), clamp01(c[3])
    end
end

local LUT_FNS = {
    -- neutro: identidade EXATA — referência de calibração e fallback de
    -- qualquer região desconhecida.
    neutro = function(r, g, b) return r, g, b end,
    -- refúgio: quente doméstico — sombras sobem p/ âmbar, highlights dourados.
    refugio = gradeLGG{
        lift = {0.010, 0.004, -0.006},
        gain = {1.045, 1.005, 0.940},
        shadowTint = {0.30, 0.18, 0.09}, shadowMix = 0.22,
        sat = 1.05,
    },
    -- colina: frio lunar — sombras azul-violeta, highlights dessaturados.
    colina = gradeLGG{
        lift = {-0.004, 0.000, 0.012},
        gain = {0.955, 0.985, 1.045},
        shadowTint = {0.16, 0.17, 0.32}, shadowMix = 0.24,
        sat = 0.95,
    },
    -- necrópole: esverdeado — sombras teal/jade, médios frios.
    necropole = gradeLGG{
        lift = {-0.006, 0.004, 0.000},
        gain = {0.940, 1.020, 0.970},
        shadowTint = {0.10, 0.26, 0.22}, shadowMix = 0.26,
        sat = 0.92,
    },
    -- salões: dourado escuro — pretos esmagados quentes, highlights ouro velho.
    saloes = gradeLGG{
        lift = {-0.012, -0.016, -0.024},
        gain = {1.060, 0.980, 0.840},
        shadowTint = {0.24, 0.14, 0.07}, shadowMix = 0.18,
        sat = 1.02,
    },
}

-- LUT strip clássica 256×16 = 16³ cores: texel (x,y) recebe
-- fn(r=(x%16)/15, g=y/15, b=floor(x/16)/15). Sem assets, só ImageData.
local function buildLUT(fn)
    local data = love.image.newImageData(256, 16)
    for y = 0, 15 do
        for x = 0, 255 do
            local r, g, b = fn((x % 16) / 15, y / 15,
                math.floor(x / 16) / 15)
            data:setPixel(x, y, clamp01(r), clamp01(g), clamp01(b), 1)
        end
    end
    return data
end

local function newCanvas(w, h, fmt)
    local ok, c = pcall(G.newCanvas, w, h, {format = fmt})
    if ok then return c end
    return nil, c
end

-- ── Ciclo de vida ─────────────────────────────────────────────────────

function PostFX.new()
    local self = setmetatable({}, PostFX)
    self.enabled = false
    self.stats = {bloomMs = 0, format = 'rgba8', hdr = false}
    self.w, self.h = 0, 0
    self.exposure = 1.0
    self.bloomThreshold = 0.35 -- só o que estoura de verdade vira bloom
    self.bloomStrength = 1.2
    self.vignette = 0.18
    self.region = 'neutro'
    self.emissive = nil

    -- rgba16f quando a GPU permite; rgba8 segura o pipeline no pior caso
    -- (o tonemap ainda roda — só perde a faixa acima de 1.0).
    local formats = (G.getCanvasFormats and G.getCanvasFormats()) or {}
    self.hdrFormat = formats.rgba16f and 'rgba16f' or 'rgba8'
    self.stats.format = self.hdrFormat
    self.stats.hdr = self.hdrFormat == 'rgba16f'

    -- LUTs em ImageData primeiro: selfCheck roda mesmo sem GPU.
    self.lutData = {}
    for name, fn in pairs(LUT_FNS) do
        self.lutData[name] = buildLUT(fn)
    end
    self.lutImg = {}

    if os.getenv('ARROWFALLEN_NO_SHADER') then
        print('[postfx] ARROWFALLEN_NO_SHADER=1 — pipeline desligado, ' ..
            'present() desenha a cena crua')
        return self
    end

    -- Mesmo padrão do glowShader em pixel_art_v2.lua: pcall + diagnóstico.
    local okB, shB = pcall(G.newShader, BRIGHT_SRC)
    local okL, shL = pcall(G.newShader, BLUR_SRC)
    local okC, shC = pcall(G.newShader, COMPOSITE_SRC)
    if not (okB and okL and okC and shB and shL and shC) then
        print('[postfx] shaders indisponíveis — fallback de cena crua: ' ..
            tostring(shB or shL or shC))
        return self
    end
    self.shBright, self.shBlur, self.shComposite = shB, shL, shC

    -- LUT como Image na GPU; nearest porque o lookup já interpola a fatia b
    -- na mão — filtro linear aqui vazaria entre fatias vizinhas da strip.
    for name, data in pairs(self.lutData) do
        local ok, img = pcall(G.newImage, data)
        if not ok then
            print('[postfx] LUT "' .. name .. '" não virou Image: ' ..
                tostring(img))
            return self
        end
        img:setFilter('nearest', 'nearest')
        self.lutImg[name] = img
    end
    self.enabled = true
    return self
end

function PostFX:resize(w, h)
    w = math.max(1, math.floor(w or 0))
    h = math.max(1, math.floor(h or 0))
    self.w, self.h = w, h
    local fmt = self.hdrFormat
    local scene, err = newCanvas(w, h, fmt)
    if not scene and fmt ~= 'rgba8' then
        fmt = 'rgba8' -- a GPU mentiu no getCanvasFormats: cai no seguro
        scene, err = newCanvas(w, h, fmt)
    end
    if not scene then
        print('[postfx] canvas de cena falhou (' .. fmt .. '): ' ..
            tostring(err))
        self.enabled = false
        return
    end
    self.scene = scene
    self.scene:setFilter('nearest', 'nearest') -- pixel art não se suaviza
    self.stats.format = fmt
    self.stats.hdr = fmt == 'rgba16f'
    -- ping-pong de bloom a METADE da resolução: blur largo e barato.
    local bw, bh = math.max(1, math.floor(w / 2)), math.max(1, math.floor(h / 2))
    local a = newCanvas(bw, bh, fmt) or newCanvas(bw, bh, 'rgba8')
    local b = newCanvas(bw, bh, fmt) or newCanvas(bw, bh, 'rgba8')
    self.bloomA, self.bloomB = a, b
    -- blur é linear por natureza — único lugar do pipeline sem nearest.
    self.bloomA:setFilter('linear', 'linear')
    self.bloomB:setFilter('linear', 'linear')
end

-- ── Contrato de uso ───────────────────────────────────────────────────

function PostFX:beginScene()
    if not self.scene then
        -- rede de segurança: consumidor esqueceu resize(); assume a tela.
        self:resize(G.getWidth(), G.getHeight())
    end
    if not self.scene then return end
    self._prevCanvas = G.getCanvas()
    G.setCanvas(self.scene)
    G.clear(0, 0, 0, 1) -- a cena nasce preta; o mundo redesenha tudo
end

function PostFX:endScene()
    if self._prevCanvas then
        G.setCanvas(self._prevCanvas)
    else
        G.setCanvas()
    end
    self._prevCanvas = nil
end

function PostFX:setEmissive(canvas)
    self.emissive = canvas -- fonte EXCLUSIVA do bloom, em espaço de vista
end

function PostFX:setRegion(name)
    -- região desconhecida cai na identidade — nunca gradeia errado.
    self.region = LUT_FNS[name] and name or 'neutro'
end

function PostFX:setVignette(strength)
    self.vignette = clamp01(tonumber(strength) or 0.18)
end

function PostFX:present(x, y, scale)
    x, y, scale = x or 0, y or 0, scale or 1
    if not self.scene then return end
    if not self.enabled then
        -- sem shaders (ou sem GPU): entrega a cena crua — nunca tela preta.
        G.draw(self.scene, x, y, 0, scale, scale)
        return
    end

    -- o pipeline toca canvas/shader/cor; devolve tudo como encontrou.
    local target = G.getCanvas()
    local prevShader = G.getShader()
    local pr, pg, pb, pa = G.getColor()
    G.setColor(1, 1, 1, 1)

    -- Medição do custo do bloco de bloom (MEGAPLAN pede número real).
    local t0 = love.timer.getTime()
    local A, B = self.bloomA, self.bloomB
    local bw, bh = A:getWidth(), A:getHeight()
    G.setCanvas(A)
    G.clear(0, 0, 0, 1)
    if self.emissive then
        local emis = self.emissive
        -- downsample 2:1 do emissivo: linear temporário para não rasgar
        -- texels na queda — restauramos o filtro original na saída.
        local ef1, ef2 = emis:getFilter()
        emis:setFilter('linear', 'linear')
        G.setShader(self.shBright)
        self.shBright:send('threshold', self.bloomThreshold)
        G.draw(emis, 0, 0, 0, bw / self.w, bh / self.h)
        emis:setFilter(ef1, ef2)
        -- H→V duas vezes: cauda larga sem estourar custo.
        G.setShader(self.shBlur)
        for _ = 1, 2 do
            self.shBlur:send('dir', {1 / bw, 0})
            G.setCanvas(B)
            G.draw(A)
            self.shBlur:send('dir', {0, 1 / bh})
            G.setCanvas(A)
            G.draw(B)
        end
        G.setShader()
    end
    self.stats.bloomMs = (love.timer.getTime() - t0) * 1000

    -- Composição na tela (ou no canvas que estava ativo ao entrar).
    G.setCanvas(target)
    G.setShader(self.shComposite)
    -- Image uniforms vão a cada present: send é barato e evita conflito de
    -- nome entre shaders do repo.
    self.shComposite:send('bloomTex', A)
    self.shComposite:send('lutTex',
        self.lutImg[self.region] or self.lutImg.neutro)
    self.shComposite:send('exposure', self.exposure)
    self.shComposite:send('bloomStrength', self.bloomStrength)
    self.shComposite:send('vignette', self.vignette)
    G.draw(self.scene, x, y, 0, scale, scale)
    G.setShader(prevShader)
    G.setColor(pr, pg, pb, pa)
end

-- Instancia, gera as LUTs e confere a identidade — headless-safe porque
-- ImageData existe mesmo onde a GPU não compila shader.
function PostFX.selfCheck()
    local p = PostFX.new()
    local d = assert(p.lutData and p.lutData.neutro,
        '[postfx] selfCheck: LUT neutro ausente')
    local r, g, b = d:getPixel(0, 0)
    assert(r == 0 and g == 0 and b == 0,
        '[postfx] selfCheck: LUT neutro não é identidade no preto')
    r, g, b = d:getPixel(255, 15)
    assert(r == 1 and g == 1 and b == 1,
        '[postfx] selfCheck: LUT neutro não é identidade no branco')
    for _, name in ipairs({'refugio', 'colina', 'necropole', 'saloes'}) do
        assert(p.lutData[name],
            '[postfx] selfCheck: LUT "' .. name .. '" ausente')
    end
    print(string.format(
        '[postfx] selfCheck ok — format=%s hdr=%s enabled=%s',
        tostring(p.stats.format), tostring(p.stats.hdr),
        tostring(p.enabled)))
    return p
end

return PostFX
