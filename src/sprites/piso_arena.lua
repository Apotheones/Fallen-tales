-- PISO_ARENA — laje de arena ao relento, tile 64x64, origem topleft.
-- Cena arena-novo: dia cinza de campo aberto — pedra comum pisada, sem
-- o violeta funerário da colina. Mais gasta que piso_laje do refúgio:
-- juntas LARGAS (2-3px, stone.1-2) com sujeira earth.3 acumulada nas
-- bordas das células, lajes gastas no centro (stone.3-4) com desgaste
-- direcional (riscos alinhados na diagonal de tráfego), musgo SECO —
-- earth.5/moss.2 misturado, nunca o verde vivo — nas bordas e falhas,
-- lasca de borda e mancha escura rara. 4 frames = variantes por seed.
-- h: junta 0, laje 1, desgaste 2.

local W, H = 64, 64

local function nova(fill)
    local g = {}
    for y = 1, H do
        local r = {}
        for x = 1, W do r[x] = fill end
        g[y] = r
    end
    return g
end

local function set(g, x, y, ch)
    if x >= 1 and x <= W and y >= 1 and y <= H then g[y][x] = ch end
end

local function h2(x, y, s)
    return (x * 73 + y * 131 + s * 269) % 100
end

-- Traço por waypoints com elo de canto (4-conectado): marca a junta na
-- grade E no mask — o mask é a fronteira que veda o flood fill depois
-- da dilatação.
local function traco(g, mask, pts, ch)
    for i = 1, #pts - 2, 2 do
        local x0, y0, x1, y1 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
        local dx, dy = math.abs(x1 - x0), math.abs(y1 - y0)
        local sx = x0 <= x1 and 1 or -1
        local sy = y0 <= y1 and 1 or -1
        local x, y, err = x0, y0, dx - dy
        set(g, x, y, ch); mask[(y - 1) * W + x] = true
        while x ~= x1 or y ~= y1 do
            local e2 = 2 * err
            local nx, ny = x, y
            if e2 > -dy then err = err - dy; nx = nx + sx end
            if e2 < dx then err = err + dx; ny = ny + sy end
            set(g, nx, y, ch); mask[(y - 1) * W + nx] = true
            set(g, nx, ny, ch); mask[(ny - 1) * W + nx] = true
            x, y = nx, ny
        end
    end
end

-- Junta larga: engorda o traço de 1px num passo ortogonal -> faixa de
-- ~3px que continua vedando cada célula de laje.
local function dilata(g, mask)
    local orig = {}
    for idx in pairs(mask) do orig[#orig + 1] = idx end
    for _, idx in ipairs(orig) do
        local y = math.floor((idx - 1) / W) + 1
        local x = idx - (y - 1) * W
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local nx, ny = x + d[1], y + d[2]
            local nidx = (ny - 1) * W + nx
            if nx >= 1 and nx <= W and ny >= 1 and ny <= H
                and not mask[nidx] then
                mask[nidx] = true
                g[ny][nx] = 'j'
            end
        end
    end
end

-- Flood fill limitado pelo mask: pinta o tom da laje que contém (x,y).
local function pinta(g, mask, x, y, ch)
    local alvo = g[y][x]
    if alvo == ch or mask[(y - 1) * W + x] then return end
    local stack = { { x, y } }
    while #stack > 0 do
        local p = table.remove(stack)
        local px, py = p[1], p[2]
        local idx = (py - 1) * W + px
        if px >= 1 and px <= W and py >= 1 and py <= H
            and g[py][px] == alvo and not mask[idx] then
            g[py][px] = ch
            stack[#stack + 1] = { px + 1, py }
            stack[#stack + 1] = { px - 1, py }
            stack[#stack + 1] = { px, py + 1 }
            stack[#stack + 1] = { px, py - 1 }
        end
    end
end

-- Carimbo de risco/lasca/musgo/mancha: '.' é transparente.
local function carimbo(g, x, y, forma)
    for j = 1, #forma do
        local linha = forma[j]
        for i = 1, #linha do
            local c = linha:sub(i, i)
            if c ~= '.' then set(g, x + i - 1, y + j - 1, c) end
        end
    end
end

local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

-- Textura da faixa de junta: borda da faixa recebe sujeira 'u'
-- acumulada, miolo alterna 'j'/'J' com veios de terra.
local function junta(g, mask, seed)
    for idx in pairs(mask) do
        local y = math.floor((idx - 1) / W) + 1
        local x = idx - (y - 1) * W
        local borda_faixa = false
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local nx, ny = x + d[1], y + d[2]
            if nx >= 1 and nx <= W and ny >= 1 and ny <= H
                and not mask[(ny - 1) * W + nx] then
                borda_faixa = true
            end
        end
        local h = h2(x, y, seed)
        if borda_faixa then
            if h < 30 then g[y][x] = 'u'
            elseif h < 44 then g[y][x] = 'J'
            end
        else
            if h < 18 then g[y][x] = 'J'
            elseif h < 25 then g[y][x] = 'u'
            end
        end
    end
end

-- Rebordo do lado da laje: sujeira e musgo seco encostados na junta —
-- mais densos perto da borda do tile (o centro é pisado, a orla apodrece).
local function borda(g, mask, seed)
    for y = 1, H do
        for x = 1, W do
            if not mask[(y - 1) * W + x] then
                local cola = false
                for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                    local nx, ny = x + d[1], y + d[2]
                    if nx >= 1 and nx <= W and ny >= 1 and ny <= H
                        and mask[(ny - 1) * W + nx] then
                        cola = true
                    end
                end
                if cola then
                    local orla = x < 10 or x > 54 or y < 10 or y > 54
                    local h = h2(x, y, seed + 7)
                    local du, dm = 15, 24
                    if orla then du, dm = 23, 34 end
                    if h < du then
                        g[y][x] = 'u'
                    elseif h < dm then
                        g[y][x] = (h % 2 == 0) and 'm' or 'M'
                    end
                end
            end
        end
    end
end

-- Carimbos -------------------------------------------------------------
-- Lasca de borda (entalhe escuro + filete claro), mesma família do
-- piso_laje — aqui caem cavalgando a junta larga.
local LASCA_A = { 'ddd.', 'dd..', 'd.S.', '.SS.' }
local LASCA_B = { '.ddd', '..dd', '.Sd.', '.SS.' }
local LASCA_C = { 'Sdd.', 'ddd.', 'dd..', 'd...' }
local LASCA_D = { '..dd.', '.ddd.', 'ddSS.', 'dS...' }
-- Riscos de uso: todos puxam a mesma diagonal (tráfego do tabuleiro),
-- com um filete horizontal raro quebrando o ritmo.
local RISCO_A = { 'ss..', '.sss' }
local RISCO_B = { 's..', '.s.', '.ss' }
local RISCO_C = { 'sss', '.s.' }
local RISCO_D = { 'ss.', '.ss' }
-- Tufo de musgo seco: earth.5 'm' com moss.2 'M' no miolo — palha, não
-- verde vivo.
local TUFO_A = { 'mM.', 'Mmm', '.mM' }
local TUFO_B = { '.Mm', 'mMM', 'mM.' }
local TUFO_C = { 'Mm.', '.mM' }
-- Falha: fio de terra 'u' rachando a laje, musgo seco pegando carona.
local FALHA_A = { 'u..', '.um', '.u.', 'mu.', 'u..' }
local FALHA_B = { '.u.', 'mu.', 'u.m', '.u.' }
-- Mancha escura rara: grude de terra queimada/pisada.
local MANCHA = {
    '.qqd.',
    'qqddq',
    'qdddq',
    '.qd..',
}

local function laje(spec)
    local g, mask = nova('a'), {}
    for _, j in ipairs(spec.j) do traco(g, mask, j, 'j') end
    dilata(g, mask)
    for _, t in ipairs(spec.tons) do pinta(g, mask, t[1], t[2], t[3]) end
    junta(g, mask, spec.seed)
    borda(g, mask, spec.seed)
    for _, c in ipairs(spec.carimbos) do carimbo(g, c[1], c[2], c[3]) end
    return str(g)
end

-- Variantes: j = polilinhas de junta, tons = sementes de flood fill por
-- laje ('a' implícita — sementes só para 'l' gasto e 'd' sombreado),
-- carimbos = riscos/lascas/tufos/falhas/mancha, seed = ruído da junta.
local V1 = {
    seed = 3,
    j = {
        { 1, 12, 11, 12, 22, 11, 33, 13, 46, 12, 63, 13 },
        { 1, 30, 12, 29, 25, 31, 37, 30, 50, 32, 63, 31 },
        { 1, 47, 10, 46, 25, 48, 36, 47, 49, 45, 63, 46 },
        { 24, 1, 24, 11 }, { 45, 1, 44, 12 },
        { 15, 12, 16, 29 }, { 37, 13, 36, 30 }, { 55, 13, 54, 31 },
        { 9, 30, 9, 46 }, { 30, 31, 30, 47 }, { 50, 32, 50, 45 },
        { 18, 48, 18, 63 }, { 39, 47, 38, 63 }, { 56, 46, 56, 63 },
    },
    tons = {
        { 11, 6, 'l' }, { 34, 6, 'a' }, { 54, 6, 'd' },
        { 7, 21, 'a' }, { 26, 21, 'l' }, { 46, 21, 'a' }, { 59, 21, 'a' },
        { 5, 38, 'd' }, { 19, 38, 'l' }, { 40, 38, 'a' }, { 57, 38, 'a' },
        { 9, 55, 'a' }, { 29, 55, 'l' }, { 48, 55, 'a' }, { 60, 55, 'a' },
    },
    carimbos = {
        { 19, 20, RISCO_A }, { 30, 24, RISCO_D }, { 24, 35, RISCO_A },
        { 41, 39, RISCO_D }, { 33, 41, RISCO_C }, { 45, 22, RISCO_A },
        { 20, 52, RISCO_B }, { 50, 56, RISCO_D },
        { 14, 12, LASCA_A }, { 52, 28, LASCA_B }, { 35, 45, LASCA_C },
        { 4, 57, TUFO_A }, { 58, 6, TUFO_B }, { 60, 40, TUFO_C },
        { 26, 15, FALHA_A }, { 43, 52, MANCHA },
    },
}

local V2 = {
    seed = 11,
    j = {
        { 1, 10, 16, 10, 28, 12, 42, 11, 55, 13, 63, 12 },
        { 1, 27, 13, 28, 26, 26, 40, 28, 52, 27, 63, 29 },
        { 1, 44, 15, 45, 27, 43, 41, 45, 54, 44, 63, 45 },
        { 1, 57, 20, 56, 36, 58, 50, 57, 63, 58 },
        { 30, 1, 30, 11 }, { 52, 1, 51, 12 },
        { 10, 10, 11, 27 }, { 44, 12, 43, 27 }, { 57, 13, 58, 28 },
        { 22, 28, 22, 44 }, { 47, 29, 46, 44 },
        { 12, 45, 13, 56 }, { 33, 45, 33, 57 }, { 50, 45, 49, 56 },
    },
    tons = {
        { 15, 5, 'a' }, { 40, 5, 'l' }, { 58, 5, 'd' },
        { 6, 19, 'a' }, { 27, 19, 'l' }, { 50, 19, 'a' }, { 61, 19, 'a' },
        { 11, 36, 'd' }, { 34, 36, 'l' }, { 55, 36, 'a' },
        { 7, 51, 'a' }, { 23, 51, 'a' }, { 41, 51, 'd' }, { 56, 51, 'a' },
        { 10, 61, 'a' }, { 28, 61, 'a' }, { 45, 61, 'l' }, { 58, 61, 'a' },
    },
    carimbos = {
        { 22, 15, RISCO_D }, { 33, 21, RISCO_A }, { 28, 33, RISCO_A },
        { 38, 38, RISCO_D }, { 30, 47, RISCO_A }, { 44, 32, RISCO_C },
        { 18, 50, RISCO_B }, { 52, 22, RISCO_D },
        { 36, 11, LASCA_B }, { 10, 43, LASCA_C }, { 56, 54, LASCA_D },
        { 3, 32, TUFO_C }, { 60, 8, TUFO_A }, { 8, 60, TUFO_B },
        { 47, 47, FALHA_B }, { 25, 36, FALHA_A },
    },
}

local V3 = {
    seed = 19,
    j = {
        { 1, 15, 10, 14, 22, 16, 34, 14, 48, 16, 63, 15 },
        { 1, 34, 12, 33, 24, 35, 37, 34, 49, 36, 63, 35 },
        { 1, 51, 14, 52, 28, 50, 42, 52, 55, 51, 63, 52 },
        { 18, 1, 17, 14 }, { 41, 1, 42, 14 },
        { 8, 15, 8, 33 }, { 28, 16, 29, 34 }, { 51, 16, 50, 35 },
        { 18, 35, 18, 51 }, { 38, 35, 39, 51 }, { 56, 36, 55, 51 },
        { 10, 52, 11, 63 }, { 30, 51, 30, 63 }, { 47, 52, 48, 63 },
    },
    tons = {
        { 9, 7, 'a' }, { 30, 7, 'd' }, { 53, 7, 'a' },
        { 4, 24, 'a' }, { 18, 24, 'l' }, { 40, 24, 'a' }, { 57, 24, 'l' },
        { 9, 43, 'a' }, { 28, 43, 'l' }, { 48, 43, 'a' }, { 60, 43, 'd' },
        { 6, 57, 'd' }, { 21, 57, 'a' }, { 39, 57, 'a' }, { 56, 57, 'a' },
    },
    carimbos = {
        { 20, 24, RISCO_A }, { 35, 28, RISCO_D }, { 25, 42, RISCO_A },
        { 40, 45, RISCO_D }, { 30, 38, RISCO_A }, { 46, 20, RISCO_B },
        { 22, 56, RISCO_D }, { 36, 55, RISCO_C },
        { 24, 24, LASCA_C }, { 58, 40, LASCA_A }, { 12, 54, LASCA_B },
        { 44, 30, LASCA_D },
        { 2, 18, TUFO_B }, { 57, 3, TUFO_C }, { 52, 60, TUFO_A },
        { 10, 40, FALHA_B },
    },
}

local V4 = {
    seed = 27,
    j = {
        { 1, 9, 14, 10, 27, 8, 40, 10, 54, 9, 63, 10 },
        { 1, 25, 15, 26, 29, 24, 43, 26, 56, 25, 63, 26 },
        { 1, 40, 12, 41, 26, 39, 40, 41, 53, 40, 63, 41 },
        { 1, 55, 16, 54, 30, 56, 44, 55, 57, 56, 63, 55 },
        { 20, 1, 21, 9 }, { 45, 1, 44, 9 },
        { 12, 10, 13, 25 }, { 34, 10, 33, 25 }, { 55, 10, 54, 25 },
        { 8, 26, 8, 40 }, { 27, 26, 28, 40 }, { 46, 26, 45, 40 }, { 60, 26, 60, 40 },
        { 18, 41, 19, 54 }, { 36, 41, 35, 55 }, { 52, 41, 53, 55 },
    },
    tons = {
        { 10, 4, 'd' }, { 32, 4, 'a' }, { 55, 4, 'a' },
        { 6, 17, 'a' }, { 24, 17, 'l' }, { 44, 17, 'a' }, { 59, 17, 'd' },
        { 4, 33, 'a' }, { 18, 33, 'l' }, { 37, 33, 'a' }, { 53, 33, 'a' }, { 62, 33, 'a' },
        { 9, 48, 'a' }, { 28, 48, 'a' }, { 44, 48, 'l' }, { 58, 48, 'a' },
        { 8, 60, 'a' }, { 27, 60, 'a' }, { 44, 60, 'a' }, { 58, 60, 'l' },
    },
    carimbos = {
        { 24, 22, RISCO_D }, { 38, 30, RISCO_A }, { 27, 34, RISCO_A },
        { 42, 44, RISCO_D }, { 30, 46, RISCO_A }, { 48, 36, RISCO_C },
        { 16, 44, RISCO_B }, { 34, 58, RISCO_D },
        { 47, 9, LASCA_A }, { 22, 25, LASCA_B }, { 6, 40, LASCA_C },
        { 38, 54, LASCA_D },
        { 60, 12, TUFO_A }, { 4, 58, TUFO_C }, { 14, 3, TUFO_B },
        { 55, 44, FALHA_A }, { 20, 20, MANCHA },
    },
}

return {
    name = 'piso_arena',
    w = 64, h = 64,
    origin = 'topleft',

    legend = {
        j = { ramp = 'stone', step = 1, h = 0 }, -- junta funda
        J = { ramp = 'stone', step = 2, h = 0 }, -- junta gasta
        u = { ramp = 'earth', step = 3, h = 0 }, -- sujeira nas bordas/falhas
        a = { ramp = 'stone', step = 3, h = 1 }, -- laje base
        l = { ramp = 'stone', step = 4, h = 1 }, -- laje gasta (centro pisado)
        d = { ramp = 'stone', step = 2, h = 1 }, -- laje sombreada / lasca
        q = { ramp = 'earth', step = 2, h = 1 }, -- mancha escura rara
        m = { ramp = 'earth', step = 5, h = 1 }, -- musgo seco claro
        M = { ramp = 'moss',  step = 2, h = 1 }, -- musgo seco fundo
        s = { ramp = 'stone', step = 5, h = 2 }, -- fio de desgaste
        S = { ramp = 'stone', step = 6, h = 2 }, -- filete claro da lasca
    },

    layers = {
        {
            name = 'piso',
            h = 1,
            albedo = { laje(V1), laje(V2), laje(V3), laje(V4) },
        },
    },
}
