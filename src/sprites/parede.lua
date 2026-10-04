-- PAREDE OBLÍQUA — tile 64x96, origem no canto superior esquerdo.
-- Amostra do formato DSL (Fase 0, docs/MEGAPLAN_VISUAL_HD.md §1-2).
-- Topo (cap) em pedra clara com borda iluminada e mancha de musgo;
-- face frontal com tijolos em running bond e juntas de mortar.
-- Relevo: cap h=15 (topo), bevel/lip h=13, tijolo h=7, mortar h=6
-- (rebaixado), base h=4 — o normal modela topo contra frente.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end

-- Fiadas de tijolo (running bond): A alinhada, B deslocada meia peça.
local A   = 'bbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local Aa  = 'bbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local A1a = 'aaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm'
local B   = 'bbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbb'
local Ba  = 'bbbbbbbbmbbbbbbbbbbbbbbbmaaaaaaaaaaaaaaambbbbbbbbbbbbbbbmbbbbbbb'
local Db  = 'ddddddddmdddddddddddddddmdddddddddddddddmdddddddddddddddmddddddd'
local M   = 'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'

return {
    name = 'parede',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = {spec = 'ink', h = 6},             -- trinca
        -- cap: topo iluminado, borda clara, variação e musgo
        c = {ramp = 'stone', step = 6, h = 15},
        C = {ramp = 'stone', step = 7, h = 15},
        v = {ramp = 'stone', step = 5, h = 15},
        l = {ramp = 'stone', step = 3, h = 13}, -- lip frontal do cap
        g = {ramp = 'moss', step = 3, h = 15},
        -- face: tijolo, tijolo claro alternado, mortar rebaixado, base
        b = {ramp = 'stone', step = 4, h = 7},
        a = {ramp = 'stone', step = 5, h = 7},
        m = {ramp = 'stone', step = 2, h = 6},
        d = {ramp = 'stone', step = 1, h = 4},
    },

    layers = {
        {
            name = 'wall',
            h = 7,
            albedo = grid {
                -- cap: borda superior clara
                L'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
                L'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                -- mancha desgastada no topo
                L'CcccccccccvvvvvcccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccvvvvvcccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                -- musgo crescendo no canto do topo
                L'CcccccccccccccccccccccccccccccccccccccccccccccccggggggggcccccccC',
                L'CccccccccccccccccccccccccccccccccccccccccccccccgggggggggcccccccC',
                L'CccccccccccccccccccccccccccccccccccccccccccccccgggggggggcccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccgggggggcccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccgggggcccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                L'CcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccC',
                -- bevel iluminado e lip frontal do cap
                L'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
                L'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll',
                L'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll',
                L'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll',
                L'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll',
                -- face: fiadas A/B com tijolos alternados, trinca e base
                L(A),
                L(Aa),
                L(Aa),
                L(A),
                L(A),
                L(A),
                L(A),
                L(M),
                L(B),
                L(B),
                L(Ba),
                L(Ba),
                L(B),
                L(B),
                L(B),
                L(M),
                L(A),
                L(A),
                L'bbbbbbbbbbbbbbbmbbbbkkbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm',
                L'bbbbbbbbbbbbbbbmbbbbbkkbbbbbbbbmbbbbbbbbbbbbbbbmbbbbbbbbbbbbbbbm',
                L(A),
                L(A),
                L(A),
                L(M),
                L(B),
                L(B),
                L(Ba),
                L(Ba),
                L(B),
                L(B),
                L(B),
                L(M),
                L(A1a),
                L(A1a),
                L(A),
                L(A),
                L(A),
                L(A),
                L(A),
                L(M),
                L(B),
                L(B),
                L(B),
                L(B),
                L(B),
                L(B),
                L(B),
                L(M),
                L(A),
                L(A),
                L(A),
                L(A),
                L(A),
                L(A),
                L(A),
                L(M),
                L(Db),
                L(Db),
                L(Db),
                L(Db),
                L(Db),
                L(Db),
                L(M),
                L(M),
            },
        },
    },
}
