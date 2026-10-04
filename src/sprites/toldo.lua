-- TOLDO PATCHWORK de fachada — peça de parede, 64x96, origem topleft.
-- Refúgio/Mercado (docs/DIRECAO_AMBIENTAL_HD.md §4, toldo remendado):
-- lona esticada em vão de varanda — estreita na fixação, abrindo para
-- a rua, em retalhos de pano quente, jade e reboco com emendas cosidas
-- a mão. Armação de madeira no alto, vão 'a' projetando sombra por
-- baixo, barra irregular com pingentes de pano.
-- Relevo: viga 12, lona 10, orla/barra 8 — alto, sombra projetável.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local E = string.rep('.', 64)

-- hash determinístico para variação dentro dos retalhos
local function hsh(x, y) return (x * 31 + y * 17) % 11 end

-- constrói a lona: trapézio de linhas 9..58, retalhos 11x10 com
-- emendas 'x', barra escalopada 59..63
local function lona()
    local t = {}
    for y = 1, 96 do
        local row = {}
        for x = 1, 64 do row[x] = '.' end
        t[y] = row
    end
    for y = 9, 58 do
        local k = (y - 9) / 49
        local xl = math.floor(14 - 12 * k + 0.5)
        local xr = math.floor(52 + 11 * k + 0.5)
        for x = xl, xr do
            local px = math.floor((x - 2) / 11)
            local py = math.floor((y - 9) / 10)
            -- borda do retalho = emenda
            local seam = (x - 2) % 11 == 0 or (y - 9) % 10 == 0
            local fam = (px + py * 2) % 3 -- 0 quente, 1 jade, 2 reboco
            local ch
            if seam then ch = 'x'
            else
                local h = hsh(x, y)
                if fam == 0 then ch = h == 0 and 'A' or (h == 1 and 'c' or 'a')
                elseif fam == 1 then ch = h == 0 and 'J' or (h == 1 and 'c' or 'j')
                else ch = h == 0 and 'P' or (h == 1 and 'd' or 'p') end
            end
            t[y][x] = ch
        end
    end
    -- barra: tira escura + pingentes escalopados de comprimento variado
    for x = 3, 63 do
        local len = 1 + math.floor(2.5 + 2.5 * math.sin(x * 0.83))
        t[59][x] = 'h'
        if x % 9 == 4 then len = len + 2 end -- pingentes mais longos
        for y = 60, math.min(59 + len, 64) do t[y][x] = 'h' end
        -- ponta dos pingentes em pano claro (dobras enroladas)
        if x % 9 == 4 then
            t[math.min(59 + len, 64)][x] = 'a'
        end
    end
    -- recorte do escalopado: onde o pendente é curto, a tira de cima
    -- encolhe para ler a barba irregular
    for x = 3, 63 do
        if x % 9 ~= 4 and math.sin(x * 0.83) < -0.6 then
            t[59][x] = '.'
        end
    end
    local out = {}
    for y = 1, 96 do out[y] = table.concat(t[y]) end
    return table.concat(out, '\n')
end

local arma = {
    -- viga de fixação na fachada com fio claro e garras de ferro
    [2] = '...WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',
    [3] = '...wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
    [4] = '...wiwwwwwwwwwwwwwiwwwwwwwwwwwwwwiwwwwwwwwwwwwwwwiwwwwwwwwww',
    [5] = '...wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
    [6] = '...kik.................................................kik',
    [7] = '....kik...............................................kik',
    -- bainha onde a lona é enrolada na viga
    [8] = '..........RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR',
}

return {
    name = 'toldo',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 10},
        -- viga e garras
        W = {ramp = 'wood', step = 6, h = 12},
        w = {ramp = 'wood', step = 4, h = 11},
        i = {ramp = 'iron', step = 3, h = 12},
        R = {ramp = 'bone', step = 3, h = 10},
        -- retalhos: pano quente, jade, reboco + sombras de tecido
        a = {ramp = 'clothWarm', step = 4, h = 10},
        A = {ramp = 'clothWarm', step = 5, h = 10},
        c = {ramp = 'clothWarm', step = 2, h = 10},
        j = {ramp = 'cloth', step = 4, h = 10},
        J = {ramp = 'cloth', step = 5, h = 10},
        p = {ramp = 'plaster', step = 4, h = 10},
        P = {ramp = 'plaster', step = 5, h = 10},
        d = {ramp = 'plaster', step = 2, h = 10},
        -- emendas cosidas e barra em sombra
        x = {ramp = 'clothWarm', step = 1, h = 10},
        h = {ramp = 'clothWarm', step = 2, h = 8},
    },

    layers = {
        {name = 'arma', h = 11,
            albedo = (function()
                local t = {}
                for y = 1, 96 do t[y] = arma[y] and L(arma[y]) or E end
                return table.concat(t, '\n')
            end)()},
        {name = 'lona', h = 10, albedo = lona()},
    },
}
