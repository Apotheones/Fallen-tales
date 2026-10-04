-- RACK_FERRAMENTAS — painel de parede, 64x96, origem topleft.
-- Oficina do Refúgio (nota vida-refugio-props §10): placa de madeira
-- pregada com ferramentas penduradas LIMPAS e em ordem de ofício —
-- serrote, martelo, formão, metro dobrável. Silhuetas iron/wood
-- legíveis; pinos 'P' onde a ferramenta trava.
-- Relevo: placa 6-7, ferramentas 8-9, pinos 9.

local function L(s)
    assert(#s <= 64, 'linha de sprite > 64 colunas')
    return s .. string.rep('.', 64 - #s)
end
local function grid(rows) return table.concat(rows, '\n') end
local E = string.rep('.', 64)

return {
    name = 'rack_ferramentas',
    w = 64, h = 96,
    origin = 'topleft',

    legend = {
        k = { spec = 'ink', h = 6 },              -- furo/parafuso/sombra
        -- placa
        P = { ramp = 'wood', step = 5, h = 7 },   -- filete da placa
        p = { ramp = 'wood', step = 3, h = 6 },   -- corpo da placa
        v = { ramp = 'wood', step = 2, h = 6 },   -- veio/junta da placa
        o = { ramp = 'iron', step = 3, h = 9 },   -- pino
        -- ferramentas
        i = { ramp = 'iron', step = 4, h = 8 },   -- lâmina/cabeça
        I = { ramp = 'iron', step = 6, h = 8 },   -- fio da lâmina
        t = { ramp = 'iron', step = 2, h = 8 },   -- dentes do serrote
        m = { ramp = 'iron', step = 3, h = 8 },   -- cabeça do martelo
        M = { ramp = 'iron', step = 6, h = 8 },   -- face iluminada da cabeça
        T = { ramp = 'iron', step = 5, h = 8 },   -- gume do formão
        H = { ramp = 'wood', step = 2, h = 8 },   -- cabo escuro
        h = { ramp = 'wood', step = 4, h = 8 },   -- cabo claro
        R = { ramp = 'bone', step = 4, h = 8 },   -- metro dobrável
        r = { ramp = 'bone', step = 2, h = 8 },   -- traços do metro
    },

    layers = {
        {   -- PLACA + FERRAMENTAS numa camada: pregada na parede
            name = 'rack',
            h = 7,
            albedo = grid {
                E, E, E, E, E,                            -- 1-5
                -- placa de fundo com moldura
                L'......PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP', -- 6
                L'......PppppppppppppppppppppppppppppppppppppppppppppppP', -- 7
                L'......PpkppppvpppppppkpppppppvppppppkpppppvpppppppkppP', -- 8
                -- SERROTE pendurado na diagonal (lâmina pra baixo-esq.)
                L'......PpppppppppppppppHHHppppppppppppppppppppppppppppP', -- 9
                L'......PpppppppppppppHHkHHHpppppppppppppppppppppppppppP', -- 10
                L'......PppppppppppppHHHkHHpppppppppppppppppppppppppppP', -- 11
                L'......PpppppppppppiHHHHHipppppppppppppppppppppppppppP', -- 12
                L'......PppppppppppiiiIIiiiippppppppppppppppppppppppppP', -- 13
                L'......PpppppppppiiiIIIIiiiiippppppppppppppppppppppppP', -- 14
                L'......PppppppppiiiIIIIIIiiiiiippppppppppppppppppppppP', -- 15
                L'......PpppppppiiiIIIIIIIIiiiiiipppppppppppppppppppppP', -- 16
                L'......PppppppiiiIIIIIIIIIIiiiiiippppppppppppppppppppP', -- 17
                L'......PpppppiiiIIIIIIIIIIIIiiiiiipppppppppppppppppppP', -- 18
                L'......PpppppiiIIIIIIIIIIIIIIiiiiiippppppppppppppppppP', -- 19
                L'......PppppppttttttttttttttttttttppppppppppppppppppP', -- 20
                -- linha de pinos entre fileiras
                L'......PppkpppvppppppppokpppppppvpppkppppppvpppkppppP', -- 21
                -- MARTELO (cabo para baixo) e FORMAO
                L'......PppppppmmmmmmmmmmpppppppHHHppppppppppppppppppP', -- 22
                L'......PppppppmiMMMMMMimpppppppHkHppppppppppppppppppP', -- 23
                L'......PppppppmmmmmmmmmmpppppppHHHppppppppppppppppppP', -- 24
                L'......PppppppppphhhhpppppppppHhHpppppppppppppppppppP', -- 25
                L'......PppppppppphhhhpppppppppHhHpppppppppppppppppppP', -- 26
                L'......PppppppppphhhhpppppppppihhpppppppppppppppppppP', -- 27
                L'......PppppppppphhhhpppppppppiihpppppppppppppppppppP', -- 28
                L'......PppppppppphhhhpppppppppiiipppppppppppppppppppP', -- 29
                L'......PppppppppphhhhpppppppppIITpppppppppppppppppppP', -- 30
                L'......PppppppppphhhhpppppppppITTpppppppppppppppppppP', -- 31
                L'......PppppppppphhhhpppppppppIIipppppppppppppppppppP', -- 32
                L'......PppkppppphhhhppkpppppppiiipppkpppppppvppkppppP', -- 33
                L'......PppppppppphhhhppppppppppippppppppppppppppppppP', -- 34
                L'......PppppppppphhhhpppppppppppppppppppppppppppppppP', -- 35
                L'......PppppppppphhhhpppppppppppppppppppppppppppppppP', -- 36
                L'......PpppppppppphhhpppppppppppppppppppppppppppppppP', -- 37
                L'......PppppppppppphppppppppppppppppppppppppppppppppP', -- 38
                -- METRO dobrável em zigue-zague + plaina pequena
                L'......PpkppppvpppppppkpppppppvppppppkpppppvppppkpppP', -- 39
                L'......PpppppRRRppppppppppppppppppppHHHHHHHHHpppppppP', -- 40
                L'......PppppRRRrrrpppppppppppppppppHHhhhhhhhHHppppppP', -- 41
                L'......PppppRRRRRRRpppppppppppppppHHHHkHHHHHppppppppP', -- 42
                L'......PppppprrrRRRRpppppppppppppppHHHHHHHHHpppppppppP', -- 43
                L'......PpppppppRRRRrrrpppppppppppppIIIIIIIIIppppppppppP', -- 44
                L'......PppppppppRRRRRRRpppppppppppppppppppppppppppppP', -- 45
                L'......PppppppppprrrRRRpppppppppppppppppppppppppppppP', -- 46
                L'......PpppppppppppRRRrrrpppppppppppppppppppppppppppP', -- 47
                L'......PpppppppppppppRRRRRRpppppppppppppppppppppppppP', -- 48
                L'......PppppppppppppprrrRRRpppppppppppppppppppppppppP', -- 49
                L'......PppppppppppppppppRRRpppppppppppppppppppppppppP', -- 50
                L'......PppkpppvpppppppkpppRpppvppppppkpppppvppppkpppP', -- 51
                -- rodapé da placa
                L'......PppppppppppppppppppppppppppppppppppppppppppppppP', -- 52
                L'......PvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvP', -- 53
                L'......PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP', -- 54
                E, E, E, E, E, E, E, E, E, E,             -- 55-64
                E, E, E, E, E, E, E, E, E, E,             -- 65-74
                E, E, E, E, E, E, E, E, E, E,             -- 75-84
                E, E, E, E, E, E, E, E, E, E,             -- 85-94
                E, E,                                          -- 95-96
            },
        },
    },
}
