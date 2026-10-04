-- FX_BLOCO — golpe negado por guarda/armadura (W6), 56x56.
-- Papel: NEGADO — arco de ferro/branco curto + faísca metálica voltando:
-- lê "bateu e não entrou", NUNCA confundir com acerto jade.
-- 5f @15fps ≈ .33s — faixa do ring 'block'/'armor'.

local V = require('src.kit_vfx')

return V.sheet{
    name = 'fx_bloco', w = 56, h = 56, frames = 5,
    margin = 1, seed = 17, kind = 'arco', dir = 'e',
    anchor = { 28, 28 },
    legend = {
        a = { ramp = 'iron', step = 4, e = 'iron.4', ei = .3 },
        A = { ramp = 'white', step = 1, e = 'white.1', ei = .75 },
        s = { ramp = 'iron', step = 6, e = 'white.1', ei = .5 },
        b = { ramp = 'iron', step = 2 },
    },
    emit = { only = { 'A', 's' } },
    vfx = { fps = 15 },
    frame = function(f, N, ctx)
        local c = ctx.w / 2
        -- arco frontal (o escudo/a frente blindada): setor curto,
        -- a direção chega na hora do consumo — aqui, leste canônico.
        V.arc{ at = { c, c }, dir = 'e', a0 = -.7, a1 = .7,
            r0 = 10, r1 = 16, ch = 'a', ch2 = 'b', edge = 'A',
            sweep = 'grow' }(f, N, ctx.albedo, ctx.rng)
        -- faísca metálica devolvida pelo bloqueio (rebate p/ trás)
        V.sparks{ at = { c + 12, c }, dir = 'w', cone = .8,
            n = 7, len = { 2, 6 }, speed = 20, grav = .3,
            ch = 'b', hot = 's' }(f, N, ctx.albedo, ctx.rng)
        V.dissipate(ctx.albedo, (f - 1) / N * .55, 'thin', { seed = 4 })
    end,
}
