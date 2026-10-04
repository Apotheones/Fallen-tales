-- FX_MORTE — unidade caiu de verdade (W6), 64x64, âncora no centro.
-- Papel: RESOLUÇÃO — fragmentos de pedra balísticos + fumaça subindo:
-- o corpo ficou na arena; leitura pesada, quase sem emissivo (o que
-- resolveu não brilha). 7f @12fps ≈ .58s — faixa do ring 'death' .34s+
-- trauma, sem copiar timing de action game.

local V = require('src.kit_vfx')

return V.sheet{
    name = 'fx_morte', w = 64, h = 64, frames = 7,
    margin = 1, seed = 23, kind = 'fragmento',
    anchor = { 32, 36 },
    legend = {
        q = { ramp = 'stone', step = 5 },
        Q = { ramp = 'stone', step = 3 },
        m = { ramp = 'plaster', step = 2 },
        M = { ramp = 'plaster', step = 3 },
        s = { ramp = 'ember', step = 4, e = 'ember.4', ei = .35 },
    },
    -- emissivo só nas fagulhas 's' — morte não floresce em tela cheia
    emit = { only = { 's' } },
    vfx = { fps = 12 },
    frame = function(f, N, ctx)
        local c, base = ctx.w / 2, 36
        -- cacos do corpo/cenário voando em parábola
        if f <= 5 then
            V.fragments{ at = { c, base - 6 }, dir = 'e',
                n = 8, speed = { 9, 18 }, grav = .5, size = { 1, 2 },
                ch = 'q', ch2 = 'Q' }(f, N, ctx.albedo, ctx.rng)
        end
        -- fumaça que sobe e esgarça depois da queda
        if f >= 3 then
            V.smoke{ at = { c, base - 4 }, n = 4, rise = 12,
                grow = 5, w = 8, ch = 'm', ch2 = 'M' }(f - 2, N - 2,
                ctx.albedo, ctx.rng)
        end
        -- fagulhas finais dos cacos (2 frames, fracas)
        if f >= 2 and f <= 3 then
            V.sparks{ at = { c, base - 8 }, dir = 'e', cone = math.pi,
                n = 5, len = { 1, 4 }, speed = 14,
                ch = 's', hot = 's' }(f - 1, 4, ctx.albedo, ctx.rng)
        end
        V.dissipate(ctx.albedo, (f - 1) / N * .4, 'thin', { seed = 8 })
    end,
}
