-- FX_TIRO — disparo do arco (W6), 56x56, âncora no centro.
-- Papel: FOGO — a jogadora leu a ação; jade = agência da viajante.
-- Estrela radial curta + faíscas: a liberação, não o voo (o voo é o
-- projétil real). 4f @18fps ≈ .22s — faixa do ring 'fire' do feedback.

local V = require('src.kit_vfx')

return V.sheet{
    name = 'fx_tiro', w = 56, h = 56, frames = 4,
    margin = 1, seed = 7, kind = 'faisca', dir = 'e',
    anchor = { 28, 28 },
    legend = {
        s = { ramp = 'jade', step = 4, e = 'jade.4', ei = .4 },
        S = { ramp = 'jade', step = 6, e = 'jade.6', ei = .75 },
        w = { ramp = 'white', step = 1, e = 'white.1', ei = .85 },
    },
    emit = { only = { 'S', 'w' } },
    vfx = { fps = 18 },
    frame = function(f, N, ctx)
        local c = ctx.w / 2
        -- estrela da liberação: núcleo branco f1, jade f2, some
        if f <= 2 then
            local r = f == 1 and 3 or 2
            local ch = f == 1 and 'w' or 'S'
            for dy = -r, r do for dx = -r, r do
                if math.abs(dx) + math.abs(dy) <= r + 1 then
                    V.put(ctx.albedo, c + dx, c + dy, ch)
                end
            end end
        end
        -- faíscas radiais da corda largando
        V.sparks{ at = { c, c }, dir = 'e', cone = math.pi,
            n = 10, len = { 2, 7 }, speed = 22,
            ch = 's', hot = 'S' }(f, N, ctx.albedo, ctx.rng)
        V.dissipate(ctx.albedo, (f - 1) / N * .45, 'thin', { seed = 5 })
    end,
}
