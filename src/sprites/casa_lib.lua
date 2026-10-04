-- CASA_LIB — construtor compartilhado das fachadas multi-tile (frente
-- CASAS F4/F5, docs/MEGAPLAN_VISUAL_HD.md). Uma casa = def única mais
-- larga que o tile de 64 (128/192x96), origem topleft: telhado de
-- ardósia com beiral no topo, face de dois pavimentos em reboco com
-- meio-madeira, sanca entre pisos, cunhais de pedra nas pontas e base
-- de alvenaria. As grades nascem para a largura inteira — nenhum
-- padrão reinicia em x=64/128, então a junção de célula não existe.
--
-- NÃO é um sprite: não entra em init.lua; os casa_*.lua montam sobre
-- Lib.fachada/Lib.telhado e devolvem a def.

local Lib = {}
local floor = math.floor

function Lib.canvas(w, h)
    local g = {}
    for y = 1, h do
        local r = {}
        for x = 1, w do r[x] = '.' end
        g[y] = r
    end
    local C = { w = w, h = h, g = g }
    function C.set(x, y, ch)
        if x >= 1 and x <= w and y >= 1 and y <= h then g[y][x] = ch end
    end
    function C.rect(x, y, rw, rh, ch)
        for yy = y, y + rh - 1 do
            for xx = x, x + rw - 1 do C.set(xx, yy, ch) end
        end
    end
    function C.out()
        local t = {}
        for y = 1, h do t[y] = table.concat(g[y]) end
        return table.concat(t, '\n')
    end
    return C
end

local function hsh(x, y) return (x * 31 + y * 17) % 13 end

-- Ardósia em fiadas desencontradas: 'T' borda iluminada da telha,
-- 't' corpo, 'r' junta vertical e sombra de sobreposição da fiada.
-- O deslocamento é calculado sobre a largura inteira — contínuo.
function Lib.telhado(C, y0, y1, o)
    o = o or {}
    local curso = o.curso or 5   -- altura de cada fiada
    local larg = o.telha or 8    -- largura da telha (junta inclusa)
    for y = y0, y1 do
        local cy = (y - y0) % curso
        local fiada = floor((y - y0) / curso)
        local off = (fiada % 2) * floor(larg / 2)
        for x = 1, C.w do
            local ch
            if cy == 0 then ch = 'T'
            elseif cy == curso - 1 then ch = 'r'
            else ch = 't' end
            if ch ~= 'r' and ((x + off) % larg) == 1 then ch = 'r' end
            C.set(x, y, ch)
        end
    end
end

-- Fachada inteira de dois pavimentos. Devolve albedo, emissive (strings
-- de grade). Opções em `o`:
--   w (128|192), roofH (14..20), curso/telha do telhado, cachorros
--   stringY (topo da sanca entre pisos), baseH (rodapé de pedra)
--   posts/postsLo: xs de montantes de meio-madeira (2px + sombra)
--   stains: {{x,y,w,h[,ch]}} manchas de reboco
--   up/lo: janelas {{x,top,w,h,kind}} kind='shut'|'open'|'lit'
--   door: {x,top,w,bot,steps}
--   remendo: {x,y,w,h} peça nova com junta de cal
--   varal: {x,y,w} corda + peças penduradas
--   sign: {cx,top} placa de hospedaria sobre a porta
function Lib.fachada(o)
    local W = o.w
    local H = 96
    local A = Lib.canvas(W, H)
    local E = Lib.canvas(W, H)
    local roofH = o.roofH or 16
    local sy = o.stringY or 50
    local baseH = o.baseH or 6
    local baseTop = H - baseH + 1

    ---------------- TELHADO + BEIRAL ----------------
    Lib.telhado(A, 1, roofH - 6, { curso = o.curso, telha = o.telha })
    A.rect(1, roofH - 5, W, 1, 'r')          -- sombra da última fiada
    A.rect(1, roofH - 4, W, 1, 'T')          -- lip iluminado do beiral
    A.rect(1, roofH - 3, W, 1, 'x')          -- fascia de madeira
    A.rect(1, roofH - 2, W, 2, 'R')          -- verso do beiral, o mais fundo
    if o.cachorros then
        -- caibros aparentes ritmados, recortando o verso do beiral
        for x = 5, W - 5, 9 do
            A.set(x, roofH - 2, 'v')
            A.set(x + 1, roofH - 2, 'k')
        end
    end
    -- verga: a encosta morre nos cantos, borda sempre em sombra
    for y = 1, roofH - 1 do
        A.set(1, y, 'r'); A.set(2, y, 'r')
        A.set(W, y, 'r'); A.set(W - 1, y, 'r')
    end

    ---------------- FACE DE REBOCO ----------------
    for y = roofH, H do for x = 1, W do A.set(x, y, 'p') end end
    -- a sombra que o beiral deita na face (dois fios: duro e esfumado)
    A.rect(1, roofH, W, 1, 'd')
    A.rect(1, roofH + 1, W, 1, 'q')
    for _, s in ipairs(o.stains or {}) do
        A.rect(s[1], s[2], s[3], s[4], s[5] or 'q')
    end
    -- canto implícito: fio de sombra + cunhais de pedra alternados
    for y = roofH, H do A.set(1, y, 'q'); A.set(W, y, 'q') end
    local qy = roofH + 2
    while qy < baseTop - 4 do
        local qb = math.min(qy + 6, baseTop - 4)
        for y = qy, qb do
            for x = 1, 3 do A.set(x, y, 'b') end
            for x = W - 2, W do A.set(x, y, 'b') end
        end
        for x = 1, 3 do A.set(x, qy, 'B') end         -- aresta iluminada
        for x = W - 2, W do A.set(x, qy, 'B') end
        for y = qy, qb do                              -- junta reboco/cunhal
            A.set(4, y, 'm'); A.set(W - 3, y, 'm')
        end
        qy = qb + 5
    end

    -- meio-madeira: montantes com 2px de madeira + 1px de sombra;
    -- onde caem em x=64/128 viram estrutura e escondem a emenda
    for _, px in ipairs(o.posts or {}) do
        for y = roofH + 2, sy - 1 do
            A.set(px, y, 'w'); A.set(px + 1, y, 'w'); A.set(px + 2, y, 'q')
        end
        A.rect(px - 1, sy - 2, 5, 2, 'x')              -- ombreira na sanca
    end
    for _, px in ipairs(o.postsLo or {}) do
        for y = sy + 4, baseTop - 1 do
            A.set(px, y, 'w'); A.set(px + 1, y, 'w'); A.set(px + 2, y, 'q')
        end
    end

    ---------------- SANCA ENTRE PAVIMENTOS ----------------
    A.rect(1, sy, W, 1, 'W')
    A.rect(1, sy + 1, W, 1, 'w')
    A.rect(1, sy + 2, W, 1, 'x')
    A.rect(1, sy + 3, W, 1, 'q')                        -- sombra da sanca

    ---------------- BASE DE PEDRA ----------------
    A.rect(1, baseTop, W, 1, 's')                       -- filete de topo
    for y = baseTop + 1, H - 1 do
        local off = (y % 2) * 6
        for x = 1, W do
            A.set(x, y, ((x + off) % 13 == 0) and 'm' or 'b')
        end
    end
    A.rect(1, H, W, 1, 'z')                             -- sola em contato

    ---------------- ABERTURAS ----------------
    local function janela(x, top, w, h, kind)
        -- lintel de pedra avançando 2px por lado + jambas + peitoril
        A.rect(x - 2, top - 2, w + 4, 1, 'S')
        A.rect(x - 2, top - 1, w + 4, 1, 's')
        A.rect(x - 2, top, 2, h, 's')
        A.rect(x + w, top, 2, h, 's')
        A.rect(x - 2, top + h, w + 4, 1, 'S')
        A.rect(x - 2, top + h + 1, w + 4, 1, 's')
        A.rect(x - 1, top + h + 2, w + 2, 1, 'm')       -- sombra do peitoril
        local mid = x + floor(w / 2) - 1
        if kind == 'shut' then
            -- veneziana fechada: réguas horizontais, montante central
            for y = top, top + h - 1 do
                for xx = x, x + w - 1 do
                    local ch = 'w'
                    if (y - top) % 3 == 2 then ch = 'v' end
                    if xx == mid or xx == mid + 1 then ch = 'x' end
                    A.set(xx, y, ch)
                end
            end
            A.rect(x, top, w, 1, 'x')                   -- régua de topo
        else
            A.rect(x, top, w, h, kind == 'lit' and 'n' or 'o')
            if kind == 'lit' then
                -- vidro quente com gradiente: acesa embaixo, já indo
                -- dormir em cima (lamparina baixa, não farol)
                A.rect(x, top, w, floor(h / 3) + 1, 'N')
            end
            A.rect(mid, top, 2, h, 'w')                 -- caixilho vertical
            A.rect(x, top + floor(h / 2), w, 2, 'w')    -- caixilho horizontal
            A.rect(x, top, w, 1, 'k')                   -- sombra sob o lintel
            if kind == 'lit' then
                -- brilho morno recortado pelo caixilho: mais forte na
                -- metade de baixo (lamparina), difuso em cima
                for y = top + 1, top + h - 1 do
                    for xx = x + 1, x + w - 2 do
                        local mullion = (xx == mid or xx == mid + 1)
                            or (y >= top + floor(h / 2)
                                and y <= top + floor(h / 2) + 1)
                        if not mullion then
                            E.set(xx, y,
                                y > top + floor(h / 2) and 'e' or 'O')
                        end
                    end
                end
            end
        end
    end
    for _, win in ipairs(o.up or {}) do
        janela(win[1], win[2], win[3], win[4], win[5] or 'shut')
    end
    for _, win in ipairs(o.lo or {}) do
        janela(win[1], win[2], win[3], win[4], win[5] or 'shut')
    end

    if o.door then
        local d = o.door
        local x, top, w, bot = d[1], d[2], d[3], d[4]
        A.rect(x - 3, top - 3, w + 6, 2, 'S')           -- lintel corrido
        A.rect(x - 3, top - 1, w + 6, 1, 's')
        A.rect(x - 2, top, 2, bot - top, 's')           -- jambas
        A.rect(x + w, top, 2, bot - top, 's')
        -- folha: tábuas verticais com juntas, sombra no alto do vão
        for y = top, bot - 1 do
            for xx = x, x + w - 1 do
                A.set(xx, y, (xx - x) % 4 == 3 and 'x' or 'w')
            end
        end
        A.rect(x, top, w, 1, 'v')
        A.rect(x, top + 5, w, 2, 'W')                   -- travessas
        A.rect(x, bot - 6, w, 2, 'W')
        A.rect(x, top + 5, 2, 2, 'i')                   -- dobradiças
        A.rect(x, bot - 6, 2, 2, 'i')
        local hy = top + floor((bot - top) / 2)
        A.set(x + w - 3, hy, 'i'); A.set(x + w - 2, hy, 'i') -- argola
        A.rect(x - 3, bot, w + 6, 1, 'S')               -- limiar
        A.rect(x - 3, bot + 1, w + 6, 1, 's')
        if d.steps then
            -- escadinha: dois degraus alargando para a rua
            A.rect(x - 5, bot + 2, w + 10, 1, 'S')
            A.rect(x - 5, bot + 3, w + 10, 1, 's')
            A.rect(x - 7, bot + 4, w + 14, 1, 'S')
            A.rect(x - 7, bot + 5, w + 14, 2, 's')
        end
    end

    ---------------- REMENDO DE MURO ----------------
    -- mesma ideia de remendo_muro.lua: peça NOVA clara embutida no
    -- reboco velho, junta de cal expremida e cantos comidos irregulares
    if o.remendo then
        local R = o.remendo
        for y = R[2], R[2] + R[4] - 1 do
            for x = R[1], R[1] + R[3] - 1 do
                local dx = math.min(x - R[1], R[1] + R[3] - 1 - x)
                local dy = math.min(y - R[2], R[2] + R[4] - 1 - y)
                local come = (dx + dy < 2) and (hsh(x, y) < 7)
                if not come then
                    if dx == 0 or dy == 0 then
                        A.set(x, y, 'c')                -- cal na junta
                    else
                        local junta = ((x - R[1]) % 9 == 0)
                            or ((y - R[2]) % 6 == 0)
                        -- peça nova em maioria 'b' — 'u' claro só em
                        -- lâmpadas esparsas, senão vira azulejo
                        A.set(x, y, junta and 'm'
                            or (hsh(x, y) < 3 and 'u' or 'b'))
                    end
                end
            end
        end
    end

    ---------------- VARAL SOB A JANELA ----------------
    -- corda de fibra em catenária rasa entre dois ganchos de ferro;
    -- peças penduradas estáticas (o vento, se vier, é trabalho do mundo)
    if o.varal then
        local V = o.varal
        local vx, vy, vw = V[1], V[2], V[3]
        local function sag(x)
            return floor(math.sin((x - vx) / vw * math.pi) * 3 + 0.5)
        end
        A.set(vx, vy, 'i'); A.set(vx + vw, vy, 'i')     -- ganchos
        for x = vx + 1, vx + vw - 1 do A.set(x, vy + sag(x), 'f') end
        for _, pc in ipairs(V.pecas or {
            { vx + 3, 6, 7, 'P', 'd' },
            { vx + 11, 5, 6, 'j', 'C' },
            { vx + 18, 4, 8, 'a', 'q' } }) do
            local px, pw, ph, ch, cd = pc[1], pc[2], pc[3], pc[4], pc[5]
            local top = vy + sag(px + floor(pw / 2)) + 1
            A.set(px + 1, top - 1, 'i')                 -- pregador
            for y = 0, ph - 1 do
                for xx = px, px + pw - 1 do
                    -- barra inferior levemente mastigada
                    if y < ph - 1 or hsh(xx, top + y) < 9 then
                        A.set(xx, top + y,
                            (xx - px) % 3 == 1 and cd or ch)
                    end
                end
            end
        end
    end

    ---------------- PLACA DE HOSPEDARIA ----------------
    -- varão de ferro preso na face + tabuleta pendurada com o crescente
    -- da casa que acolhe de noite (Refúgio: símbolo, não letramento)
    if o.sign then
        local cx, top = o.sign[1], o.sign[2]
        A.rect(cx - 8, top, 17, 1, 'i')                 -- varão
        A.set(cx - 7, top + 1, 'i'); A.set(cx + 6, top + 1, 'i')
        A.set(cx - 7, top + 2, 'i'); A.set(cx + 6, top + 2, 'i')
        A.rect(cx - 8, top + 3, 17, 1, 'v')             -- tabuleta
        A.rect(cx - 8, top + 4, 17, 6, 'w')
        A.rect(cx - 8, top + 10, 17, 1, 'v')
        for y = top + 3, top + 10 do
            A.set(cx - 8, y, 'v'); A.set(cx + 8, y, 'v')
        end
        -- crescente de traço duplo + ponto (noite = pouso)
        local sx, sy0 = cx - 2, top + 4
        A.set(sx + 1, sy0, 'G'); A.set(sx + 2, sy0, 'G')
        A.set(sx, sy0 + 1, 'G'); A.set(sx + 1, sy0 + 1, 'G')
        A.set(sx, sy0 + 2, 'G')
        A.set(sx, sy0 + 3, 'G'); A.set(sx + 1, sy0 + 3, 'G')
        A.set(sx + 1, sy0 + 4, 'G'); A.set(sx + 2, sy0 + 4, 'G')
        A.set(sx + 4, sy0 + 1, 'G')
    end

    return A:out(), E:out()
end

-- Legend da família casa_*: ardósia (sea), reboco (plaster), madeira,
-- pedra e os emissivos de janela. `ei` ajusta o brilho da janela acesa
-- por def (casa viva, nunca vitrine).
function Lib.legend(ei)
    ei = ei or 0.35
    return {
        k = { spec = 'ink', h = 5 },
        -- ardósia do telhado (mar lavanda do Refúgio)
        T = { ramp = 'sea', step = 4, h = 14 },
        t = { ramp = 'sea', step = 3, h = 13 },
        r = { ramp = 'sea', step = 2, h = 12 },
        R = { ramp = 'sea', step = 1, h = 11 },
        -- reboco
        P = { ramp = 'plaster', step = 5, h = 6 },
        p = { ramp = 'plaster', step = 4, h = 6 },
        q = { ramp = 'plaster', step = 3, h = 6 },
        d = { ramp = 'plaster', step = 2, h = 5 },
        -- madeira
        W = { ramp = 'wood', step = 5, h = 8 },
        w = { ramp = 'wood', step = 4, h = 7 },
        x = { ramp = 'wood', step = 3, h = 7 },
        v = { ramp = 'wood', step = 2, h = 7 },
        -- pedra (cunhais, vergas, peitoris, base)
        s = { ramp = 'stone', step = 3, h = 8 },
        S = { ramp = 'stone', step = 5, h = 9 },
        b = { ramp = 'stone', step = 4, h = 7 },
        B = { ramp = 'stone', step = 5, h = 7 },
        m = { ramp = 'stone', step = 2, h = 6 },
        z = { ramp = 'stone', step = 1, h = 4 },
        -- aberturas e ferragem
        o = { spec = 'abyss', h = 3 },
        n = { ramp = 'ember', step = 2, h = 4 },        -- vidro quente
        N = { ramp = 'ember', step = 1, h = 4 },        -- vidro apagando
        i = { ramp = 'iron', step = 3, h = 8 },
        -- remendo, varal, placa
        c = { ramp = 'plaster', step = 5, h = 7 },      -- cal da junta
        u = { ramp = 'stone', step = 6, h = 8 },        -- pedra nova
        f = { ramp = 'bone', step = 4, h = 7 },         -- corda de fibra
        j = { ramp = 'cloth', step = 4, h = 6 },
        C = { ramp = 'cloth', step = 2, h = 6 },
        a = { ramp = 'clothWarm', step = 4, h = 6 },
        G = { ramp = 'gold', step = 5, h = 8 },
        g = { ramp = 'moss', step = 3, h = 6 },
        -- emissivo (só aparece no canal emissivo)
        e = { ramp = 'ember', step = 4, h = 4, e = 'ember.4', ei = ei },
        O = { ramp = 'ember', step = 3, h = 4, e = 'ember.3', ei = ei * 0.6 },
    }
end

return Lib
