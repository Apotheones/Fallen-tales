-- FX_HIT_JADE — impacto que acertou (W6), 64x64, âncora no centro.
-- Papel: ACERTO — jade no corpo atingido + anel de choque + faíscas:
-- o golpe contou. 6f @15fps ≈ .4s — faixa do ring 'hit' + shake .22s.

local V = require('src.kit_vfx')

return V.sheet{
    name = 'fx_hit_jade', w = 64, h = 64, frames = 6,
    margin = 1, seed = 13, kind = 'onda',
    anchor = { 32, 32 },
    legend = {
        o = { ramp = 'jade', step = 3, e = 'jade.3', ei = .45 },
        O = { ramp = 'jade', step = 5, e = 'jade.5', ei = .7 },
        s = { ramp = 'jade', step = 4, e = 'jade.4', ei = .5 },
        S = { ramp = 'jade', step = 6, e = 'jade.6', ei = .8 },
        w = { ramp = 'white', step = 1, e = 'white.1', ei = .9 },
    },
    emit = { only = { 'O', 'S', 'w' } },
    vfx = { fps = 15 },
    frame = function(f, N, ctx)
        local c = ctx.w / 2
        -- anel de choque no ponto do impacto
        V.wave{ at = { c, c }, r0 = 4, r1 = 24, width = 2,
            squash = .8, ch = 'o', edge = 'O', seed = 13 }(f, N,
            ctx.albedo, ctx.rng)
        -- núcleo de contato nos 2 primeiros frames
        if f <= 2 then
            local r = f == 1 and 4 or 2
            for dy = -r, r do for dx = -r, r do
                if dx * dx + dy * dy <= r * r then
                    V.put(ctx.albedo, c + dx, c + dy, 'w')
                end
            end end
        end
        -- faíscas radiais do impacto
        V.sparks{ at = { c, c }, dir = 'e', cone = math.pi,
            n = 12, len = { 2, 8 }, speed = 26,
            ch = 's', hot = 'S' }(f, N, ctx.albedo, ctx.rng)
        V.dissipate(ctx.albedo, (f - 1) / N * .5, 'thin', { seed = 9 })
    end,
}
