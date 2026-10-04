-- REMENDO DE MURO — peça de parede, 64x96, origem topleft.
-- Refúgio (docs/DIRECAO_AMBIENTAL_HD.md §REFÚGIO, "remendo com
-- acabamento diferente — trabalho reconhecível"): alvenaria NOVA de
-- pedra clara embutida na parede VELHA escura. A junta entre os dois
-- trabalhos é desenhada irregular — uma linha de cal expremida que
-- contorna a peça nova, com fiadas desencontradas nos bordos.
-- Relevo: peça nova 7-8 (ligeiramente orgulhosa), parede velha 5-6,
-- juntas 4-5, junta de cal 6.

local function hsh(x, y) return (x * 31 + y * 17) % 13 end

-- contorno irregular da peça nova: escada pelas juntas, nunca reta
local function nova(x, y)
    if y < 26 or y > 74 then return false end
    local l = 14 + (y % 11 < 5 and -4 or 0) + (y % 17 < 8 and 3 or 0)
    local r = 50 + (y % 13 < 6 and 4 or 0) - (y % 19 < 9 and 3 or 0)
    local t = 26 + (x % 15 < 7 and 4 or 0) - (x % 23 < 10 and 3 or 0)
    local b = 74 - (x % 13 < 6 and 5 or 0) + (x % 21 < 9 and 3 or 0)
    return x >= l and x <= r and y >= t and y <= b
end

local function muro()
    local t = {}
    for y = 1, 96 do
        local row = {}
        for x = 1, 64 do
            local inN = nova(x, y)
            local mortar = y % 7 == 0
            local off = (math.floor(y / 7) % 2) * 8
            local junta = (x + off) % 16 == 0
            local ch
            if inN then
                -- junta de cal no contorno da peça nova
                local borda = not nova(x - 1, y) or not nova(x + 1, y)
                    or not nova(x, y - 1) or not nova(x, y + 1)
                if borda then ch = 'L'
                elseif mortar then ch = 'M'
                elseif junta then ch = 'M'
                else
                    local h = hsh(x, y)
                    ch = h == 0 and 'N' or (h == 1 and 'm' or 'n')
                end
            else
                if mortar then ch = 'm'
                elseif junta then ch = 'm'
                else
                    local h = hsh(x + 7, y + 3)
                    ch = h == 0 and 'B' or (h <= 2 and 'v' or 'b')
                end
            end
            row[x] = ch
        end
        t[y] = table.concat(row)
    end
    -- filete de topo e sombra de base para leitura standalone
    return table.concat(t, '\n')
end

return {
    name = 'remendo_muro',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        -- parede velha: tijolo escuro, claro raro, junta funda
        b = {ramp = 'stone', step = 3, h = 6},
        B = {ramp = 'stone', step = 4, h = 6},
        v = {ramp = 'stone', step = 2, h = 5},
        m = {ramp = 'stone', step = 1, h = 4},
        -- peça nova: tijolo claro, alternado, junta de cal
        n = {ramp = 'stone', step = 5, h = 8},
        N = {ramp = 'stone', step = 6, h = 8},
        M = {ramp = 'stone', step = 2, h = 6},
        L = {ramp = 'plaster', step = 5, h = 6},
    },

    layers = {
        {name = 'muro', h = 6, albedo = muro()},
    },
}
