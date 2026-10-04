-- fx_play.lua — runtime mínimo de playback de sheets FX (W6).
-- A camada de authoring (src/kit_vfx.lua) produz defs DSL em
-- src/sprites/fx_*; este módulo só dispara, avança e desenha — bake
-- acontece UMA vez por def, no spawn (update), nunca no draw.
--
-- Posições: unidades-40 do feedback (consume já converte célula→40px);
-- o draw no mundo HD multiplica ×1.6 p/ cair no buffer de 64px
-- (CELL_HD). Anchor: def.vfx.anchor (origem do efeito no frame) —
-- lido do próprio def, default = centro.
--
-- Reduced-motion: o evento continua lido — o playback congela no
-- frame mediano (marcador estático) e sai no fim da duração normal.

local Kit = require('src.hd_kit')
local G = love.graphics

local Fx = {}

function Fx.new()
    return { list = {}, sheets = {} }
end

local function defOf(name)
    local ok, def = pcall(require, 'src.sprites.' .. name)
    return ok and def or nil
end

local function entry(self, name)
    local e = self.sheets[name]
    if e == nil then
        local sh = Kit.bakeViaDSL(name) -- bake fora do draw (spawn=update)
        if not sh then
            e = false
        else
            local def = defOf(name)
            local a = def and def.vfx and def.vfx.anchor
            e = { sheet = sh, quads = Kit.quads(sh),
                ax = a and a[1] or math.floor(sh.w / 2),
                ay = a and a[2] or math.floor(sh.h / 2),
                fps = def and def.vfx and def.vfx.fps or 14 }
        end
        self.sheets[name] = e
    end
    return e or nil
end

-- Dispara um efeito. wx,wy em unidades-40 (espaço do feedback);
-- dir reservado p/ defs direcionais futuras; reduced = marcador.
function Fx.spawn(self, name, wx, wy, opts)
    local e = entry(self, name)
    if not e then return end
    opts = opts or {}
    self.list[#self.list + 1] = {
        e = e, wx = wx, wy = wy,
        dur = #e.quads / e.fps,
        t = 0, reduced = opts.reduced,
        born = opts.born,
    }
end

function Fx.update(self, dt)
    for i = #self.list, 1, -1 do
        local p = self.list[i]
        p.t = p.t + dt
        if p.t >= p.dur then table.remove(self.list, i) end
    end
end

-- Desenha por canal no espaço do buffer HD (x1.6 das unidades-40).
-- Chamado dentro do channel() da batalha para albedo/normal/emissive —
-- o emissivo entra no bufE e floresce pelo postfx normal.
function Fx.draw(self, ch)
    for _, p in ipairs(self.list) do
        local n = #p.e.quads
        -- reduced-motion: frame mediano parado (a informação fica,
        -- o floreio sai).
        local f = p.reduced and math.max(1, math.ceil(n / 2))
            or math.min(n, 1 + math.floor(p.t / p.dur * n))
        G.draw(p.e.sheet[ch], p.e.quads[f],
            math.floor(p.wx * 1.6 - p.e.ax + .5),
            math.floor(p.wy * 1.6 - p.e.ay + .5))
    end
end

return Fx
