-- MARCO — a pedra monumental do Refúgio, 64x96, origem topleft.
-- Monólito de pedra em coroa gasta, face com painel rebaixado e fileiras
-- de nomes gravados que ACENDEM em jade (emissivo ei 0.5-0.8). Relevo
-- alto na pedra, fio de luz na aresta esquerda, base em três degraus.
-- Peça-âncora da praça (docs/PLANO_REFUGIO_ANDLAR.md §1).

local W, H = 64, 96

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
local function lin(g, x, y, s)
    for i = 1, #s do set(g, x + i - 1, y, s:sub(i, i)) end
end
local function str(g)
    local t = {}
    for y = 1, H do t[y] = table.concat(g[y]) end
    return table.concat(t, '\n')
end

local g = nova('.')  -- albedo (fundo transparente)
local ge = nova('.') -- emissivo: só as runas

-- Coroa gasta (6-12): topo 'C' com entalhes e mancha lavada 'c'.
lin(g, 28, 6, 'k' .. ('C'):rep(9) .. 'k')
lin(g, 25, 7, 'k' .. ('C'):rep(14) .. 'k')
lin(g, 22, 8, 'k' .. ('C'):rep(6) .. 'c' .. ('C'):rep(12) .. 'k')
lin(g, 19, 9, 'k' .. ('C'):rep(23) .. 'k')
lin(g, 17, 10, 'k' .. ('C'):rep(27) .. 'k')
lin(g, 16, 11, 'k' .. ('C'):rep(29) .. 'k')
lin(g, 15, 12, 'k' .. ('C'):rep(31) .. 'k')
-- entalhes da coroa (silhueta gasta, não polida)
set(g, 40, 7, '.'); set(g, 41, 7, '.')
set(g, 19, 9, '.'); set(g, 43, 9, '.')
set(g, 20, 9, '.')
-- ombreira da coroa: filete de luz caindo para a face
lin(g, 14, 13, 'k' .. ('L'):rep(2) .. ('a'):rep(29) .. ('m'):rep(2) .. 'k')

-- Face (14-80): corpo x13-50 — contorno ink, fio 'LL' à esquerda,
-- sombra 'zz' à direita. Dentro: moldura 'F' e painel 'p' rebaixado
-- onde os nomes são gravados.
local function face(r)
    if (r >= 20 and r <= 21) or (r >= 78 and r <= 79) then
        return ('b'):rep(2) .. ('F'):rep(28) .. ('b'):rep(2)
    end
    if r >= 22 and r <= 77 then
        return ('b'):rep(2) .. 'F' .. ('p'):rep(26) .. 'F' .. ('b'):rep(2)
    end
    return ('b'):rep(32)
end
for r = 14, 80 do
    lin(g, 13, r, 'k' .. 'LL' .. face(r) .. 'zz' .. 'k')
end

-- Desgaste da face fora do painel (manchas claras, não pontilhado).
lin(g, 38, 15, 'aaa'); lin(g, 37, 16, 'aaaa'); lin(g, 38, 17, 'aaa')
lin(g, 16, 60, 'aa'); lin(g, 16, 61, 'aaa'); lin(g, 17, 62, 'a')
lin(g, 44, 55, 'aa'); lin(g, 45, 56, 'a')

-- Lascas na silhueta.
set(g, 13, 40, '.'); set(g, 13, 41, '.'); set(g, 14, 41, '.')
set(g, 50, 58, '.'); set(g, 50, 59, '.'); set(g, 49, 59, '.')

-- Trinca que desce da coroa e morre na moldura do painel.
local trinca = { { 33, 8 }, { 33, 9 }, { 34, 10 }, { 34, 11 }, { 34, 12 },
    { 35, 13 }, { 35, 14 }, { 35, 15 }, { 36, 16 }, { 36, 17 }, { 35, 18 } }
for _, p in ipairs(trinca) do set(g, p[1], p[2], 'k') end

-- Musgo abraçando o pé esquerdo da pedra.
for _, p in ipairs({ { 14, 75 }, { 14, 76 }, { 15, 76 }, { 14, 77 },
    { 15, 77 }, { 16, 77 }, { 15, 78 }, { 16, 78 } }) do
    set(g, p[1], p[2], 'g')
end

-- NOMES: fileiras de runas jade dentro do painel (x20-44, 25 col).
-- 'R' brilha mais (nome recente), 'r' é o coro das lembradas, 'f' é o
-- traço que o tempo já comeu. Estampadas no albedo e no emissivo.
local NOMES = {
    { 'R.RR.R..RR.RR..R.RR...R',   -- nome novo, aceso forte
      'RR.R.RR.R..R.R.R..R.R.RR.',
      'R.R.RR..RR.R.R..R..R.R..R' },
    { 'rr.r.rr..r.rrr..r.rr...r',
      '.r.r.r..r.r.r..r...r.rr.',
      'r.r.rr..r..r.r..rr..r..r' },
    { 'r.rr..r.rr..r.r..rrr..r.',
      'rr.r..r.r...r.r..r.r..r.',
      'r.rr..r.r...r.rr..r..rr.' },
    { 'rr..r.r..rrr..r..r.rr..r',
      'r...r.r..r.r..r..r.r...r',
      'r...rrr..r.r..rr..r.r..r' },
    { 'r.rrr..r..r.rr..r.r...r.',
      'r.r.r..r..r.r.r..r.r.rr.',
      'r.r.rrr...r.r..rr..r.r..' },
    { '.rr..r.rr..r..rr..r.rr.r',
      'r.r..r.r...r..r...r.r..r',
      'r.r..r.rr..rr..r..r.r.r.' },
    { 'r..r.rrr..r.r..r.rr..r.r',
      'r..r.r.r..r.r..r.r...r.r',
      'rr.r.r.rr..r.rr..r.r..r.' },
    { 'f.rf..f.rr..r..rf..f.r..',
      'f..f..f.r...r..r...f.r..',
      'f.rf..f.r...rr..rf..f.r.' },
    { 'f..f.rf..f..r.f..f..f...',
      '..f..f...f..r.f..f..f.r..',
      'f..f.rf..f..r.f..f..f...' },
    { 'f....f..f...f.....f..f..',
      '..f....f..f...f.....f..f.',
      'f....f..f...f.....f..f...' }, -- os apagados: quase só poeira
}
local y = 30
for i, nome in ipairs(NOMES) do
    for j, linha in ipairs(nome) do
        lin(g, 20, y + j - 1, linha)
        lin(ge, 20, y + j - 1, linha)
    end
    y = y + (i == 1 and 5 or 4) -- respiro maior depois do nome novo
end

-- Emblema do Refúgio no topo do painel: o arco da porta que acolhe.
local EMBLEMA = {
    '..RRRRR..',
    '.RR...RR.',
    '.R.....R.',
    'RR.....RR',
    'RR.....RR',
}
for j, linha in ipairs(EMBLEMA) do
    lin(g, 28, 22 + j - 1, linha)
    lin(ge, 28, 22 + j - 1, linha)
end

-- Base em três degraus: topo lavado 's', frente 'b'/'m', sola 'd'.
lin(g, 14, 81, 'k' .. 'LL' .. ('s'):rep(34) .. 'k')
lin(g, 14, 82, 'k' .. 'LL' .. ('b'):rep(31) .. ('m'):rep(3) .. 'k')
lin(g, 14, 83, 'k' .. 'LL' .. ('b'):rep(31) .. ('m'):rep(3) .. 'k')
lin(g, 14, 84, 'k' .. 'LL' .. ('b'):rep(31) .. ('m'):rep(3) .. 'k')
lin(g, 10, 85, 'k' .. 'LL' .. ('s'):rep(42) .. 'k')
lin(g, 10, 86, 'k' .. 'LL' .. ('b'):rep(39) .. ('m'):rep(3) .. 'k')
lin(g, 10, 87, 'k' .. 'LL' .. ('b'):rep(39) .. ('m'):rep(3) .. 'k')
lin(g, 10, 88, 'k' .. 'LL' .. ('b'):rep(39) .. ('m'):rep(3) .. 'k')
lin(g, 7, 89, 'k' .. 'LL' .. ('s'):rep(48) .. 'k')
lin(g, 7, 90, 'k' .. 'LL' .. ('b'):rep(45) .. ('m'):rep(3) .. 'k')
lin(g, 7, 91, 'k' .. 'LL' .. ('b'):rep(45) .. ('m'):rep(3) .. 'k')
lin(g, 7, 92, 'k' .. 'LL' .. ('b'):rep(45) .. ('m'):rep(3) .. 'k')
lin(g, 7, 93, 'k' .. 'LL' .. ('b'):rep(45) .. ('m'):rep(3) .. 'k')
lin(g, 7, 94, 'k' .. 'LL' .. ('b'):rep(45) .. ('m'):rep(3) .. 'k')
lin(g, 7, 95, 'k' .. ('d'):rep(50) .. 'k')
lin(g, 7, 96, 'k' .. ('d'):rep(50) .. 'k')

-- Musgo sobre os degraus.
lin(g, 15, 82, 'gg'); lin(g, 15, 83, 'gg'); lin(g, 16, 84, 'g')
lin(g, 8, 90, 'gg'); lin(g, 8, 91, 'ggg'); lin(g, 9, 92, 'gg')

return {
    name = 'marco',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 10 },           -- contorno / trinca
        C = { ramp = 'stone', step = 7, h = 14 }, -- coroa
        c = { ramp = 'stone', step = 6, h = 14 }, -- mancha da coroa
        L = { ramp = 'stone', step = 6, h = 13 }, -- fio de luz esquerdo
        b = { ramp = 'stone', step = 4, h = 11 }, -- face
        a = { ramp = 'stone', step = 5, h = 11 }, -- mancha clara da face
        m = { ramp = 'stone', step = 3, h = 9 },  -- sombra de degrau
        z = { ramp = 'stone', step = 2, h = 10 }, -- aresta em sombra
        F = { ramp = 'stone', step = 6, h = 12 }, -- moldura do painel
        p = { ramp = 'stone', step = 3, h = 10 }, -- painel rebaixado
        s = { ramp = 'stone', step = 5, h = 8 },  -- topo dos degraus
        d = { ramp = 'stone', step = 1, h = 5 },  -- sola da base
        g = { ramp = 'moss', step = 3, h = 11 },
        -- runas que acendem
        r = { ramp = 'cloth', step = 4, h = 11, e = 'jade', ei = 0.6 },
        R = { ramp = 'cloth', step = 5, h = 12, e = 'jadeLight', ei = 0.8 },
        f = { ramp = 'cloth', step = 3, h = 10, e = 'cloth.3', ei = 0.5 },
    },

    layers = {
        {
            name = 'pedra',
            h = 11,
            albedo = str(g),
            emissive = str(ge),
        },
    },
}
