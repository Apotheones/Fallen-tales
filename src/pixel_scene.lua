-- Cena de exploração assada em canvas (repaginada estilo Undertale): o
-- piso vira massa plana com manchas orgânicas, as paredes viram faixas
-- contínuas de alvenaria/painel com contorno de silhueta, e sombras de
-- contato ancoram os props. Tudo procedural; a camada estática assa uma
-- vez por sala e o renderer só desenha o canvas.
local Pal = require('src.palettes')
local PixelArt = require('src.pixel_art_v2')
local Props = require('src.props')
local G = love.graphics
local Scene = {}

local function round(n) return math.floor(n + .5) end
local function px(x, y, w, h, c, a)
    G.setColor(c[1], c[2], c[3], a or 1)
    G.rectangle('fill', round(x), round(y), round(w), round(h))
end
-- Variação estável por célula: a sala revisita as mesmas marcas.
local function hash(seed, x, y, salt)
    return ((seed or 0) * 17 + x * 37 + y * 101 + (x * y) * 7 + (salt or 0) * 13) % 97
end
Scene.hash = hash

local function isFloor(t) return t and t.ground == 'floor' and t.piece ~= 'wall' end
local function isWall(t) return t and t.piece == 'wall' end

-- Manchas orgânicas: âncoras raras geram aglomerados de elipses num tom
-- vizinho do piso. Só células a duas casas de qualquer borda viram âncora —
-- assim o alcance máximo do blob (~51 px) nunca sangra sobre muro ou vazio.
local function floorPatches(map, pal, seed, at)
    -- Âncora precisa só da vizinhança imediata livre; o alcance máximo do
    -- blob (raio ≤ 30 + jitter ≤ 8) cabe em 1 célula de margem.
    local function clear(t)
        for dy = -1, 1 do for dx = -1, 1 do
            if not isFloor(at(t.x + dx, t.y + dy)) then return false end
        end end
        return true
    end
    for _, t in pairs(map.tiles) do
        if isFloor(t) then
            local n = hash(seed, t.x, t.y, 1)
            if n % 16 == 0 and clear(t) then
                local cx, cy = (t.x - .5) * 32, (t.y - .5) * 32
                local tone = n % 32 == 0 and pal.floor.light or pal.floor.dark
                -- Padrão por âncora, não só tom: mancha orgânica, torrões
                -- quebrados ou trilha de arraste — o chão conta como foi
                -- usado, não apenas se está mais claro.
                local style = hash(seed, t.x, t.y, 60) % 3
                if style == 0 then
                    G.setColor(tone[1], tone[2], tone[3], 1)
                    for i = 0, 2 + n % 2 do
                        local bx = cx + (hash(seed, t.x, t.y, 10 + i) % 17) - 8
                        local by = cy + (hash(seed, t.x, t.y, 20 + i) % 13) - 6
                        local rx = 13 + hash(seed, t.x, t.y, 30 + i) % 17
                        local ry = 7 + hash(seed, t.x, t.y, 40 + i) % 8
                        G.ellipse('fill', round(bx), round(by), rx, ry)
                    end
                elseif style == 1 then
                    -- Torrões: grumos com fio de luz — quebrado, não mancha.
                    for i = 0, 3 do
                        local bx = cx + (hash(seed, t.x, t.y, 10 + i) % 19) - 9
                        local by = cy + (hash(seed, t.x, t.y, 20 + i) % 13) - 6
                        local bw = 4 + hash(seed, t.x, t.y, 30 + i) % 5
                        px(bx, by, bw, 3 + (i % 2), tone, 1)
                        px(bx, by, bw, 1, pal.floor.light, .6)
                    end
                else
                    -- Trilha de arraste: traços paralelos que marcam onde
                    -- algo pesado passou — direção, não só desgaste.
                    local dx = hash(seed, t.x, t.y, 70) % 5 - 2
                    for i = 0, 2 do
                        px(round(cx - 10 + i * 8), round(cy - 4 + i * (2 + dx)),
                            9, 2, tone, 1)
                    end
                    px(round(cx - 12), round(cy - 5), 4, 3, pal.floor.shadow, .5)
                end
            end
        end
    end
end

-- Tábuas de madeira (refúgio): fiadas horizontais com junta sutil, tom
-- alternando por fiada e emendas raras sempre nas mesmas posições. As
-- linhas seguem os runs contíguos de piso de cada linha.
local function floorPlanks(map, pal, seed)
    for y = 1, map.h do
        local x = 1
        while x <= map.w do
            local t = map.tiles[x .. ':' .. y]
            if isFloor(t) then
                local x0 = x
                while x <= map.w and isFloor(map.tiles[x .. ':' .. y]) do x = x + 1 end
                local x1 = x - 1
                local y0, y1 = (y - 1) * 32, y * 32
                for ly = math.floor(y0 / 8) * 8 + 8, y1 - 1, 8 do
                    local band = math.floor(ly / 8)
                    if band % 2 == 0 then px(x0 * 32 - 32, ly - 7, (x1 - x0 + 1) * 32, 7, pal.floor.light, .18) end
                    px(x0 * 32 - 32, ly, (x1 - x0 + 1) * 32, 1, pal.floor.shadow, .45)
                    for jx = x0 * 32 - 32 + (band % 3) * 17, x1 * 32, 47 do
                        if hash(seed, round(jx / 32), band, 5) % 6 == 0 then
                            px(jx, ly - 7, 1, 7, pal.floor.shadow, .35)
                        end
                    end
                end
            else x = x + 1 end
        end
    end
end

-- Sombra suave onde o piso encontra muro ou vazio: o pé da parede sempre
-- escurece o chão, como nas referências.
local function floorShadows(map, pal, at)
    for _, t in pairs(map.tiles) do
        if isFloor(t) then
            local px_, py_ = (t.x - 1) * 32, (t.y - 1) * 32
            if not isFloor(at(t.x, t.y - 1)) then
                px(px_, py_, 32, 4, pal.floor.shadow, .55)
                px(px_, py_ + 4, 32, 3, pal.floor.shadow, .3)
                px(px_, py_ + 7, 32, 2, pal.floor.shadow, .15)
            end
            if not isFloor(at(t.x - 1, t.y)) then px(px_, py_, 3, 32, pal.floor.shadow, .22) end
            if not isFloor(at(t.x + 1, t.y)) then px(px_ + 29, py_, 3, 32, pal.floor.shadow, .22) end
        end
    end
end

-- Marcas quietas no piso: musgo rente aos muros, pedrinhas e pétalas
-- raras. Nada disso sugere caminho, buraco ou colisão inexistente.
local function floorDecor(map, pal, seed, at)
    -- Dentro/fora muda o repertório: exterior guarda musgo e pétala;
    -- interior guarda pó na base do muro, lasca de pedra e fiapo/migalha
    -- — cada superfície fala a própria língua, não um speckle único.
    local indoor = not map.outdoor
    for _, t in pairs(map.tiles) do
        if isFloor(t) and t.piece ~= 'portal' then
            local px_, py_ = (t.x - 1) * 32, (t.y - 1) * 32
            local n = hash(seed, t.x, t.y, 7)
            if n % 17 == 0 and not isFloor(at(t.x, t.y - 1)) then
                if indoor then
                    -- Faixa de pó na base do muro: o cômodo que se vive
                    -- acumula onde a vassoura não alcança.
                    px(px_ + 4, py_ + 27, 14, 2, pal.floor.light, .3)
                    px(px_ + 8, py_ + 25, 5, 1, pal.floor.dark, .35)
                    px(px_ + 21, py_ + 28, 6, 1, pal.floor.dark, .3)
                else
                    for i = 0, 3 do
                        px(px_ + 5 + i * 6 + (n + i) % 3, py_ + 26 + (n + i * 3) % 4, 3, 2, pal.moss)
                        px(px_ + 6 + i * 6, py_ + 25 + (n + i) % 2, 1, 1, pal.moss)
                    end
                end
            elseif n % 29 == 3 then
                if indoor then
                    -- Lasca de pedra: corte claro na quina, sombra no verso.
                    px(px_ + 17, py_ + 18, 4, 2, pal.wall.face)
                    px(px_ + 17, py_ + 18, 4, 1, pal.wall.cap, .7)
                    px(px_ + 18, py_ + 20, 4, 1, pal.floor.shadow, .5)
                else
                    px(px_ + 8, py_ + 21, 2, 1, pal.floor.shadow, .5)
                    px(px_ + 19, py_ + 9, 3, 1, pal.floor.shadow, .4)
                    px(px_ + 9, py_ + 22, 1, 1, pal.floor.light)
                end
            elseif n % 41 == 7 then
                if indoor then
                    -- Fiapo e migalha: o interior guarda resto de uso.
                    px(px_ + 8 + (n % 12), py_ + 10 + (n % 14), 1, 2, pal.cloth.dark, .6)
                    px(px_ + 20 + (n % 7), py_ + 22, 2, 1, pal.floor.light, .5)
                else
                    for i = 0, 2 do
                        px(px_ + 6 + (n + i * 11) % 20, py_ + 6 + (n + i * 7) % 20, 2, 1, pal.petal, .8)
                    end
                end
            end
        end
    end
end

-- Desgaste de parada (resíduo (c) da fatia I): onde o lugar segura o
-- viajante — diante da cova, da grade e do altar — o piso lava mais
-- claro/descorado, como o eixo pisado da praça. Os tiles de espera são os
-- de piso colados ao prop, resolvidos por id (id vence kind, como no
-- painter) — nenhum dado novo no def.
local wearStops = {
    cova = {dirs = {1}},        -- a espera fica ao sul da boca
    grade = {dirs = {-1, 1}},   -- o posto segura dos dois lados da passagem
    mesaVelas = {dirs = {1}},   -- altar de velas: a fila fica à frente
    altar = {dirs = {1}},
}
local function floorWear(map, pal, seed, at)
    for _, prop in ipairs(map.props or {}) do
        local stop = wearStops[prop.id]
        if stop then
            local pw, ph = prop.w or 1, prop.h or 1
            for _, dy in ipairs(stop.dirs) do
                local ty = dy > 0 and prop.y + ph or prop.y - 1
                for dx = -1, pw do
                    if isFloor(at(prop.x + dx, ty)) then
                        local x, y = (prop.x + dx - 1) * 32, (ty - 1) * 32
                        local n = hash(seed, prop.x + dx, ty, 27)
                        -- Faixa lavada de tanto parar: lajes descoradas com
                        -- borda dithered — trânsito lê-se sem virar trilha.
                        px(x + 2 + (n % 5), y + 9 + (n % 4) * 3, 22 + n % 6, 3,
                            pal.floor.light, .5)
                        px(x + 6 + (n % 7), y + 20 + (n % 3) * 2, 13, 2,
                            pal.floor.light, .36)
                        px(x + 8 + (n % 4), y + 14 + (n % 2) * 3, 9, 1,
                            pal.wall.cap, .22)
                        PixelArt.dither(x + 3, y + 26, 26, 4, pal.floor.light, .18)
                        -- Segunda faixa de aproximação: mais fraca, um tile
                        -- além — o desgaste desce devagar, não para seco.
                        if isFloor(at(prop.x + dx, ty + dy)) then
                            local y2 = (ty + dy - 1) * 32
                            px(x + 4 + (n % 6), y2 + 11 + (n % 3) * 4, 17, 2,
                                pal.floor.light, .26)
                        end
                    end
                end
            end
        end
    end
end

-- Buracos: poço escuro com borda quebrada nas faces expostas ao piso.
local function holes(map, pal, at)
    for _, t in pairs(map.tiles) do
        if t.ground == 'hole' then
            local px_, py_ = (t.x - 1) * 32, (t.y - 1) * 32
            px(px_, py_, 32, 32, Pal.abyss)
            local function exposed(x, y) return isFloor(at(x, y)) end
            if exposed(t.x, t.y - 1) then
                px(px_, py_, 32, 3, pal.wall.face)
                px(px_ + 2, py_ + 3, 28, 4, pal.wall.faceDark)
                px(px_ + 3, py_ + 1, 8, 1, pal.wall.rim); px(px_ + 18, py_ + 1, 11, 1, pal.wall.rim)
            end
            if exposed(t.x, t.y + 1) then
                px(px_, py_ + 29, 32, 3, pal.wall.face)
                px(px_ + 3, py_ + 29, 9, 1, pal.wall.rim); px(px_ + 20, py_ + 28, 7, 1, pal.wall.cap)
            end
            if exposed(t.x - 1, t.y) then
                px(px_, py_ + 3, 3, 26, pal.wall.face)
                px(px_ + 3, py_ + 7, 2, 20, pal.wall.faceDark)
            end
            if exposed(t.x + 1, t.y) then
                px(px_ + 29, py_ + 3, 3, 26, pal.wall.face)
                px(px_ + 27, py_ + 6, 2, 20, pal.floor.shadow)
            end
        end
    end
end

-- Desenha a faixa de textura do capitel de um muro de fundo recortada à
-- célula: tijolos/painéis usam coordenadas absolutas, então fiadas e
-- pranchas atravessam as células vizinhas sem costura.
local function capTexture(map, pal, seed, t, capTop, capH)
    local px_, py_ = (t.x - 1) * 32, (t.y - 1) * 32
    local function clip(x, y, w, h, c, a)
        local x0, y0 = math.max(x, px_), math.max(y, capTop)
        local x1, y1 = math.min(x + w, px_ + 32), math.min(y + h, capTop + capH)
        if x0 < x1 and y0 < y1 then px(x0, y0, x1 - x0, y1 - y0, c, a) end
    end
    if pal.wallStyle == 'panel' then
        for x = math.floor(px_ / 10) * 10 - 10, px_ + 32, 10 do
            local column = round(x / 10)
            clip(x, capTop, 9, capH, column % 2 == 0 and pal.wall.brick or pal.wall.brickAlt)
            clip(x + 9, capTop, 1, capH, pal.wall.mortar)
        end
    else
        local ROW, BW = 8, 15
        for ry = math.floor(capTop / ROW) * ROW, capTop + capH, ROW do
            local row = round(ry / ROW)
            local off = row % 2 == 0 and 0 or round(BW / 2)
            for x = math.floor((px_ - off) / BW) * BW + off, px_ + 32, BW do
                local tone = hash(seed, round(x / BW), row, 3) % 5 == 0
                    and pal.wall.brickAlt or pal.wall.brick
                clip(x, ry, BW - 1, ROW - 1, tone)
                clip(x, ry, BW - 1, 1, pal.wall.cap, .35)
            end
        end
    end
end

local function walls(map, pal, seed, at)
    local backWalls = {}
    for _, t in pairs(map.tiles) do
        if isWall(t) then
            local px_, py_ = (t.x - 1) * 32, (t.y - 1) * 32
            local s = isFloor(at(t.x, t.y + 1))
            local n = isFloor(at(t.x, t.y - 1))
            local w_ = isFloor(at(t.x - 1, t.y))
            local e = isFloor(at(t.x + 1, t.y))
            if s then
                -- Muro de fundo: faixa de textura em cima, face plana embaixo.
                backWalls[#backWalls + 1] = t
                -- Se a célula acima também é piso (parede entre pisos), o
                -- capitel não invade o chão dela.
                local capTop = n and py_ or py_ - 13
                local capH = py_ + 11 - capTop
                px(px_, capTop, 32, capH, pal.wall.mortar)
                capTexture(map, pal, seed, t, capTop, capH)
                px(px_, py_ + 11, 32, 21, pal.wall.face)
                px(px_, py_ + 28, 32, 4, pal.floor.shadow, .8)
                px(px_, capTop + capH - 1, 32, 2, pal.wall.cap)
                if not at(t.x, t.y - 1) then px(px_, py_ - 14, 32, 2, pal.wall.rim) end
                if w_ then px(px_, capTop, 2, py_ + 32 - capTop, pal.wall.rim, .7) end
                if e then px(px_ + 30, capTop, 2, py_ + 32 - capTop, pal.wall.rim, .7) end
            elseif n or w_ or e then
                -- Muro de frente/lateral: face plana e rim no lado do piso.
                px(px_, py_, 32, 32, pal.wall.face)
                px(px_, py_ + 27, 32, 5, pal.wall.faceDark)
                if n then px(px_, py_, 32, 2, pal.wall.rim) end
                if w_ then px(px_, py_, 2, 32, pal.wall.rim, .7) end
                if e then px(px_ + 30, py_, 2, 32, pal.wall.rim, .7) end
            else
                -- Casca profunda: massa escura, quase indistinguível do vazio.
                px(px_, py_, 32, 32, pal.wall.faceDark)
            end
            -- Silhueta externa: tinta na aresta exposta ao vazio.
            if not at(t.x, t.y - 1) then px(px_, py_ - 14, 32, 1, Pal.ink) end
            if not at(t.x - 1, t.y) then px(px_ - 1, py_, 1, 32, Pal.ink) end
            if not at(t.x + 1, t.y) then px(px_ + 32, py_, 1, 32, Pal.ink) end
        end
    end
end

-- The sanctuary sits on a coastal shelf, rather than inside a rectangular room.
local function refugeLandscape(map, pal, seed, at)
    local c, width, height = Pal.refuge, map.w * 32, map.h * 32
    -- O void vira vale: bandas de mar/névoa em degradação descendente, com
    -- juntas esfumaçadas — o entorno lê como distância, não tinta de editor.
    local bands = {c.sea, c.sea, c.seaLight, c.seaLight, c.haze, c.haze}
    local bandH = math.ceil((height + 128) / #bands)
    for i, tone in ipairs(bands) do
        px(-64, -64 + (i - 1) * bandH, width + 128, bandH + 1, tone)
        if i > 1 then
            PixelArt.dither(-64, -64 + (i - 1) * bandH - 4, width + 128, 8, tone, .35)
        end
    end
    -- Bruma corrente no chão do vale: veios horizontais esfumaçados que
    -- quebram o campo plano entre as bandas.
    for i = 0, 9 do
        local my = 150 + hash(seed, i, 4, 11) % (height - 60)
        PixelArt.dither(-64, my, width + 128, 7, c.haze, .14)
    end
    px(-64, -64, width + 128, 142, c.sky)
    -- Fio de poente na linha do céu: o vale guarda o resto de luz do dia —
    -- o povoado lê-se ao anoitecer, não em meio-dia nublado. Um degrau a
    -- mais de quente/frio: o núcleo brasa recorta a névoa fria.
    px(-64, 60, width + 128, 18, Pal.gold.light, .18)
    px(-64, 68, width + 128, 10, Pal.ember, .1)
    px(-64, 5, width + 128, 27, c.haze)
    -- Cristas atrás do vale: duas camadas de serra que só o void revela —
    -- os muros do mapa cobrem o traçado onde há terreno, e as margens
    -- mostram a encosta continuar.
    for x = -64, width + 64, 11 do
        local rh = 10 + hash(seed, math.floor(x / 8), 5, 13) % 26
        px(x, 286 - rh, 11, rh, c.distant)
    end
    for x = -64, width + 64, 19 do
        local rh = 8 + hash(seed, math.floor(x / 8), 9, 7) % 20
        px(x, 520 - rh, 19, rh, Pal.ridge.far)
    end
    -- Pontos de lume distantes: outras moradias fumegando na encosta —
    -- núcleo incandescente + fio de fumaça por lar; o quente estoura um
    -- degrau acima da bruma fria do vale.
    for i = 0, 3 do
        local ex = i % 2 == 0 and (-56 + hash(seed, i, 7) % 40)
            or (width + 18 + hash(seed, i, 3) % 38)
        local ey = 240 + hash(seed, i, 11, 5) % 480
        px(ex, ey, 2, 2, Pal.ember, .75)
        px(ex, ey - 1, 1, 1, Pal.emberLight, .65)
        PixelArt.dither(ex - 2, ey - 10, 5, 9, c.haze, .28)
    end
    px(math.floor(width * .34), height + 38, 2, 2, Pal.ember, .65)
    px(math.floor(width * .57), height + 50, 2, 2, Pal.ember, .55)
    -- Broken silhouettes of distant Andlar, with air between three depth layers.
    for i = 0, math.floor(width / 47) do
        local x, bh = i * 47 - 28, 7 + hash(seed, i, 1, 9) % 17
        px(x, 29 - bh, 24 + i % 17, bh, c.distant)
        if i % 4 == 0 then px(x + 7, 20 - bh, 8, 10, c.distant) end
    end
    -- The upper lookout is above the village on a rock slope, not an island.
    px(6 * 32, 8 * 32, 32 * 32, 4 * 32, c.grassDark)
    for i = 0, 28 do
        local x, y = 7 * 32 + i * 37, 8 * 32 + hash(seed, i, 2, 7) % 88
        px(x, y, 21 + i % 13, 3, c.cliff, .5)
        px(x + 3, y - 1, 13, 1, c.grassLight, .25)
    end
    for i = 0, math.floor(height / 20) do
        local y = 90 + i * 20
        px(-50 + hash(seed, i, 3) % 24, y, 55 + i % 40, 1, c.seaLight, .32)
        px(width - 35 + hash(seed, i, 7) % 37, y + 8, 82, 1, c.seaLight, .27)
    end
    -- Bolsões internos de void: o entre-ruas é massa de encosta, não vale.
    -- Célula sem tile cercada de muro/piso (amarrada em coluna ou linha)
    -- ganha rocha solta contínua com a face — nunca o azul do mar.
    for cy = 1, map.h do
        for cx = 1, map.w do
            if not at(cx, cy) then
                local up, down, left, right
                for y2 = cy - 1, 1, -1 do if at(cx, y2) then up = true break end end
                for y2 = cy + 1, map.h do if at(cx, y2) then down = true break end end
                for x2 = cx - 1, 1, -1 do if at(x2, cy) then left = true break end end
                for x2 = cx + 1, map.w do if at(x2, cy) then right = true break end end
                if (up and down) or (left and right) then
                    local x, y = (cx - 1) * 32, (cy - 1) * 32
                    local n = hash(seed, cx, cy, 41)
                    px(x, y, 32, 32, c.cliff)
                    px(x + (n % 13), y + 7 + n % 15, 9 + n % 8, 1, pal.wall.faceDark, .5)
                    if n % 3 == 0 then px(x + 4, y + 4 + n % 20, 7, 5, pal.wall.faceDark, .35) end
                    if n % 5 == 0 then px(x + n % 20, y + 24, 6, 2, c.grassDark, .5) end
                end
            end
        end
    end
    -- Faces de rocha: o muro lê como massa cortada — fiadas desencontradas,
    -- veios e luz de topo. A última fileira antes do void desce ao vale em
    -- rocha e terra indo embora, com soto de névoa na base (duas cores +
    -- dither, nunca ripas fechando cada bolso).
    for _, tile in pairs(map.tiles) do
        if isWall(tile) then
            local x, y = (tile.x - 1) * 32, (tile.y - 1) * 32
            local n = hash(seed, tile.x, tile.y, 21)
            px(x, y, 32, 40, c.cliff)
            for ry = y + 9, y + 33, 11 do
                px(x, ry, 32, 1, pal.wall.faceDark, .5)
                px(x + (n + ry) % 19, ry - 6, 1, 6, pal.wall.faceDark, .4)
            end
            px(x + 6, y + 5, 3, 30, pal.wall.faceDark, .4)
            px(x + 23, y + 11, 2, 24, pal.wall.faceDark, .5)
            px(x + 9, y + 3, 13, 1, pal.wall.cap, .3)
            if isFloor(at(tile.x, tile.y - 1)) then
                px(x, y, 32, 3, pal.wall.rim)
                px(x + 1, y + 4, 29, 4, pal.wall.cap)
            elseif isFloor(at(tile.x, tile.y + 1)) then
                px(x, y + 25, 32, 7, c.grassDark)
                px(x, y + 24, 32, 2, c.grassLight)
            end
            -- Perímetro: onde o muro toca o void a borda nunca é régua —
            -- a face desce desencontrada, com rocha desabando além da linha
            -- e talude dithered afundando na bruma do vale.
            local n2 = hash(seed, tile.x, tile.y, 33)
            if not at(tile.x, tile.y + 1) then
                local fh = 13 + n2 % 10
                px(x, y + 40, 32, fh, pal.wall.faceDark)
                if n2 % 3 == 0 then
                    px(x + 3 + n2 % 13, y + 40 + fh, 9 + n2 % 8, 6, pal.wall.faceDark)
                    px(x + 5 + n2 % 13, y + 41 + fh, 5 + n2 % 5, 3, c.cliff)
                end
                PixelArt.dither(x + 2, y + 42, 28, math.min(10, math.max(2, fh - 2)),
                    pal.floor.shadow, .5)
                PixelArt.dither(x + 3, y + 38 + fh, 26, 9, c.cliff, .35)
                px(x - 2, y + 46 + fh, 36, 4, c.haze, .45)
                PixelArt.dither(x - 3, y + 44 + fh, 38, 9, c.haze, .22)
            end
            if not at(tile.x - 1, tile.y) then
                px(x - 6 - n2 % 4, y + 5, 6 + n2 % 4, 31, pal.wall.faceDark)
                PixelArt.dither(x - 10, y + 10, 9, 20, c.cliff, .4)
                px(x - 9, y + 33, 9, 4, c.haze, .4)
            end
            if not at(tile.x + 1, tile.y) then
                px(x + 32, y + 5, 6 + n2 % 4, 31, pal.wall.faceDark)
                PixelArt.dither(x + 33, y + 10, 9, 20, c.cliff, .4)
                px(x + 33, y + 33, 9, 4, c.haze, .4)
            end
        end
    end
    -- Vista de horizonte no vão sul do terraço: a faixa de céu e crista da
    -- colina replicada além da bebida — o parapeito olha o vale continuar.
    local vx0, vx1 = 15 * 32, 49 * 32
    local vy = 39 * 32 + 10
    px(vx0, vy, vx1 - vx0, 5, Pal.sky.horizon)
    px(vx0, vy + 5, vx1 - vx0, 7, Pal.sky.low)
    for i = 0, 12 do
        px(vx0 + (i * 37) % (vx1 - vx0), vy - 4 - (i % 3), 1, 1, Pal.sky.star, .5)
    end
    for x = vx0, vx1, 6 do
        local rh = 4 + (x * 7) % 6
        px(x, vy + 12 - rh, 6, rh, Pal.ridge.far)
    end
    for i = 0, 5 do
        local gx = vx0 + 24 + (i * 173) % (vx1 - vx0 - 48)
        px(gx, vy + 5, 3, 7, Pal.ridge.near)
        px(gx, vy + 5, 3, 1, Pal.ridge.lit, .7)
    end
end

local function refugeGround(map, pal, seed, at)
    local c = Pal.refuge
    -- As ruas pintadas vêm do def: map.paths é uma lista de polilinhas em
    -- células ({x1,y1},{x2,y2},... w=largura em células). Nada é hardcoded —
    -- a rua pintada segue a rua carveada, nunca o contrário.
    -- Hierarquia: a trilha principal (chegada→escadaria→praça) pinta mais
    -- clara e larga que os bolsos de terra. O def pode marcar
    -- path.main = true; sem a marca, inferimos pela polilinha que encosta
    -- no vão da primeira escadaria.
    local polys = map.paths or {}
    local gate
    for _, prop in ipairs(map.props) do
        if prop.kind == 'escadaria' then
            gate = {x = prop.x + (prop.w or 1) / 2, y = prop.y + (prop.h or 1) / 2}
            break
        end
    end
    local mains = {}
    for i, poly in ipairs(polys) do
        if poly.main then
            mains[i] = true
        elseif gate then
            for _, v in ipairs(poly) do
                local dx, dy = v[1] - gate.x, v[2] - gate.y
                if dx * dx + dy * dy < 3.5 then mains[i] = true break end
            end
        end
    end
    -- Retorna o tipo da trilha ('main'/'side'), a distância normalizada ao
    -- centro do segmento (0 = eixo, 1 = borda da rua) e a direção do trecho
    -- — o desgaste do piso clareia o eixo pisado, suja os cantos e alinha
    -- as marcas de passo no sentido do tráfego, não só no tom.
    local function pathAt(x, y)
        local bd2, best
        for i, poly in ipairs(polys) do
            local half = (poly.w or 2.6) * 16 + (mains[i] and 5 or -4)
            for j = 2, #poly do
                local ax, ay = (poly[j - 1][1] - .5) * 32, (poly[j - 1][2] - .5) * 32
                local bx, by = (poly[j][1] - .5) * 32, (poly[j][2] - .5) * 32
                local vx, vy = bx - ax, by - ay
                local f = math.max(0, math.min(1, ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy)))
                local ex, ey = x - ax - vx * f, y - ay - vy * f
                local d2 = ex * ex + ey * ey
                if d2 < half * half and (not bd2 or d2 < bd2) then
                    bd2, best = d2, {mains[i] and 'main' or 'side',
                        math.sqrt(d2) / half, vx / math.sqrt(vx * vx + vy * vy),
                        vy / math.sqrt(vx * vx + vy * vy)}
                end
            end
        end
        if best then return best[1], best[2], best[3], best[4] end
    end
    -- Material efetivo por célula (para a borda real entre superfícies):
    -- a zona manda; a rua pintada fica por cima da grama sem mudar o chão.
    -- roadNotches: torrões cuspidos 1-2px na grama em volta da picada —
    -- guardados para a segunda passagem, senão a célula vizinha pinta a
    -- base por cima e a margem fica à sorte da ordem de varredura.
    local surf, roadNotches = {}, {}
    for _, tile in pairs(map.tiles) do
        if isFloor(tile) then
            local x, y, n = (tile.x - 1) * 32, (tile.y - 1) * 32, hash(seed, tile.x, tile.y, 12)
            local grass, surface = true, 'dirt'
            for _, zone in ipairs(map.zones or {}) do
                if zone.surface ~= 'grass'
                    and tile.x >= zone.x and tile.x < zone.x + zone.w
                    and tile.y >= zone.y and tile.y < zone.y + zone.h then
                    grass, surface = false, zone.surface or 'dirt'
                end
            end
            surf[tile.x .. ':' .. tile.y] = grass and 'grass' or surface
            px(x, y, 32, 32, grass and c.grass or c.path)
            if grass then
                for by = 0, 28, 4 do for bx = 0, 28, 4 do
                    local road = pathAt(x + bx + 2, y + by + 2)
                    if road == 'main' then
                        px(x + bx, y + by, 4, 4, c.path)
                        -- Solo pisado da rua: marca de passo ou torrão miúdo
                        -- quebram a faixa — tráfego lê por padrão, não tom.
                        local rn = hash(seed, tile.x * 8 + bx, tile.y * 8 + by, 55)
                        if rn % 9 == 0 then
                            px(x + bx + 1, y + by + 1, 2, 2, pal.floor.dark, .5)
                        elseif rn % 9 == 4 then
                            px(x + bx, y + by + 2, 3, 1, c.pathLight, .55)
                        end
                        -- Margem mastigada: a picada cospe torrão de 1-2px
                        -- na grama ao redor — a fronteira terra/grama lê
                        -- encaixe, nunca o recorte quadrado do subbloco.
                        if rn % 5 == 0 then
                            if not pathAt(x + bx + 2, y + by - 2) then
                                roadNotches[#roadNotches + 1] = {x + bx + 1, y + by - 1, 2, 1} end
                            if not pathAt(x + bx + 2, y + by + 6) then
                                roadNotches[#roadNotches + 1] = {x + bx + 1, y + by + 4, 2, 1} end
                            if not pathAt(x + bx - 2, y + by + 2) then
                                roadNotches[#roadNotches + 1] = {x + bx - 1, y + by + 1, 1, 2} end
                            if not pathAt(x + bx + 6, y + by + 2) then
                                roadNotches[#roadNotches + 1] = {x + bx + 4, y + by + 1, 1, 2} end
                        end
                    elseif road == 'side' then
                        -- bolso de terra: trilha secundária mais fina e
                        -- escura que a rua principal, com torrão claro
                        -- aflorando na picada.
                        px(x + bx, y + by, 4, 4, pal.floor.shadow)
                        local rn = hash(seed, tile.x * 8 + bx, tile.y * 8 + by, 57)
                        if rn % 6 == 0 then px(x + bx + 1, y + by, 2, 1, c.path, .7) end
                    end
                end end
                if pathAt(x + 16, y + 16) then grass = false end
            end
            if grass then
                -- Grama por padrão, não por speckle: tufo reto, tufo
                -- dobrado de vento, terra nua entre tufos e trevo miúdo —
                -- cada célula assina um feitio.
                local style = n % 4
                for i = 1, 3 do
                    local bx, by = x + (n + i * 11) % 30, y + (n + i * 7) % 27
                    if style == 0 then
                        px(bx, by, 1, 3, i == 1 and c.grassLight or c.grassDark)
                        px(bx + 1, by + 2, 2, 1, c.grassDark)
                    elseif style == 1 then
                        px(bx, by + 1, 1, 2, c.grassDark)
                        px(bx + 1, by, 2, 1, c.grassLight)
                        px(bx + 2, by + 1, 1, 1, c.grassDark)
                    elseif style == 2 then
                        px(bx, by + 2, 4, 2, c.grassDark, .7)
                        px(bx + 1, by + 1, 2, 1, pal.floor.dark, .5)
                    else
                        px(bx, by, 2, 2, c.grassLight, .8)
                        px(bx + 3, by + 1, 1, 1, c.grassDark)
                    end
                end
            else
                -- TERRA como material (Olhar): cada superfície tem padrão
                -- próprio, não só tom — o eixo pisado lê pegada no sentido
                -- do tráfego, a beirada desfaz em torrão, cascalho ferve
                -- pedrinha e a laje guarda junta; terra acumulada segue
                -- junto dos muros onde ninguém pisa.
                local road, wear, rdx, rdy = pathAt(x + 16, y + 16)
                if road and wear < .5 then
                    local horiz = math.abs(rdx or 1) >= math.abs(rdy or 0)
                    -- Polimento corrido no sentido do passo.
                    if horiz then
                        px(x, y + 10 + (n % 3), 32, 2, c.pathLight, .5)
                        px(x, y + 21 + (n % 2), 32, 1, c.pathLight, .35)
                    else
                        px(x + 10 + (n % 3), y, 2, 32, c.pathLight, .5)
                        px(x + 21 + (n % 2), y, 1, 32, c.pathLight, .35)
                    end
                    -- Pegadas: marcas curtas através do passo alternando o
                    -- lado — tráfego de pé, não faixa lisa.
                    for k = 0, 2 do
                        local off = (k * 11 + n % 5) % 26
                        if horiz then
                            px(x + 3 + off, y + (k % 2 == 0 and 13 or 23) + (n % 3),
                                4, 2, pal.floor.dark, .5)
                        else
                            px(x + (k % 2 == 0 and 13 or 23) + (n % 3), y + 3 + off,
                                2, 4, pal.floor.dark, .5)
                        end
                    end
                    -- Pedra assentada aflorando no miolo gasto (raro).
                    if n % 6 == 0 then
                        px(x + 6 + (n % 9), y + 6 + (n % 7), 6, 3, pal.wall.face)
                        px(x + 6 + (n % 9), y + 6 + (n % 7), 6, 1, pal.wall.cap, .8)
                    end
                elseif road then
                    -- Beirada da rua: torrões tombando para fora da picada.
                    for k = 0, 1 do
                        local bx = x + 5 + (n + k * 13) % 22
                        local by = y + 6 + (n + k * 9) % 20
                        px(bx, by, 3, 2, pal.floor.dark, .6)
                        px(bx, by, 3, 1, pal.floor.light, .4)
                    end
                else
                    -- Fora do tráfego, junto de muro e canto, a praça
                    -- devolve terra acumulada — mais pesada onde duas
                    -- faces se encontram.
                    local wallsNear = 0
                    if not isFloor(at(tile.x, tile.y - 1)) then wallsNear = wallsNear + 1 end
                    if not isFloor(at(tile.x, tile.y + 1)) then wallsNear = wallsNear + 1 end
                    if not isFloor(at(tile.x - 1, tile.y)) then wallsNear = wallsNear + 1 end
                    if not isFloor(at(tile.x + 1, tile.y)) then wallsNear = wallsNear + 1 end
                    if wallsNear > 0 then
                        local a = .3 + wallsNear * .12
                        px(x + 2 + (n % 11), y + 2 + (n % 5), 10 + wallsNear * 5, 3,
                            pal.floor.dark, a)
                        px(x + 4 + (n % 9), y + 25 - (n % 4), 8 + wallsNear * 4, 2,
                            pal.floor.shadow, a)
                    end
                    if surface == 'gravel' then
                        -- Quintal de cascalho: pedrinhas miúdas em dois
                        -- tons e uma lasca maior — ruído seco, não poeira.
                        for k = 0, 5 do
                            px(x + 2 + (n + k * 13) % 29, y + 2 + (n + k * 7) % 29,
                                2, 1, k % 2 == 0 and pal.wall.face or pal.wall.mortar, .8)
                        end
                        if n % 4 == 0 then px(x + 8, y + 14, 4, 3, pal.wall.faceDark, .6) end
                    elseif surface == 'stone' then
                        -- Laje da praça/terraço: junta gasta lendo a
                        -- modulação + lasca solta no encontro.
                        if n % 3 == 0 then
                            px(x + 2, y + 15 + (n % 5), 16 + (n % 8), 1, pal.floor.dark, .3)
                            px(x + 9 + (n % 11), y + 5, 1, 9, pal.floor.dark, .25)
                        end
                        if n % 7 == 2 then
                            px(x + 18 + (n % 5), y + 19 + (n % 6), 4, 2, pal.wall.faceDark, .4)
                        end
                    end
                end
                if n % 4 == 0 then
                    px(x + 5, y + 22, 16, 1, c.pathLight, .55)
                    px(x + 5, y + 17, 1, 5, pal.wall.faceDark, .2)
                    px(x + 3, y + 9, 22, 1, pal.wall.faceDark, .15)
                end
            end
            -- Sombra de queda do arrimo: piso com muro a norte recebe uma
            -- faixa mais dura no topo — o desnível lê-se como muro de
            -- contenção antes de a planta mudar.
            if isWall(at(tile.x, tile.y - 1)) then
                px(x, y, 32, 4, Pal.ink, .28)
                px(x, y + 4, 32, 2, Pal.ink, .15)
            end
        end
    end
    -- Bordas reais entre materiais (régua 256bits (c)): onde a superfície
    -- muda — laje pisada → terra, terra → grama, cascalho → laje — o
    -- encontro ganha filete de junção de 1-2px + encaixe irregular dos
    -- dois lados, nunca a banda reta de cor.
    for _, nt in ipairs(roadNotches) do px(nt[1], nt[2], nt[3], nt[4], c.path) end
    local creep = {
        grass = {line = c.grassDark, notch = c.grassDark, fleck = c.grassLight},
        dirt = {line = pal.floor.dark, notch = pal.floor.dark, fleck = c.pathLight},
        gravel = {line = pal.floor.dark, notch = pal.wall.mortar, fleck = pal.wall.face},
        stone = {line = pal.wall.faceDark, notch = pal.wall.faceDark, fleck = pal.wall.face},
    }
    for _, tile in pairs(map.tiles) do
        if isFloor(tile) then
            local x, y = (tile.x - 1) * 32, (tile.y - 1) * 32
            local nn = hash(seed, tile.x, tile.y, 19)
            for di, d in ipairs({{0, -1}, {0, 1}, {-1, 0}, {1, 0}}) do
                local ns = surf[(tile.x + d[1]) .. ':' .. (tile.y + d[2])]
                if ns and ns ~= surf[tile.x .. ':' .. tile.y] then
                    local other = creep[ns] or creep.dirt
                    local en = nn + di * 7
                    if d[2] ~= 0 then
                        local ey = d[2] == -1 and y or y + 31
                        local inside = d[2] == -1 and 1 or -1
                        px(x, ey, 32, 1, other.line, .55)
                        for k = 0, 3 do
                            px(x + (en + k * 9) % 27, ey + inside,
                                3 + (en + k) % 4, 1 + (en + k * 3) % 2, other.notch, .8)
                        end
                        px(x + 4 + en % 22, ey + inside * 4, 2, 1, other.fleck, .7)
                        px(x + 11 + (en * 3) % 17, ey + inside * 5, 3, 1, other.notch, .35)
                    else
                        local ex = d[1] == -1 and x or x + 31
                        local inside = d[1] == -1 and 1 or -1
                        px(ex, y, 1, 32, other.line, .55)
                        for k = 0, 3 do
                            px(ex + inside, y + (en + k * 9) % 27,
                                1 + (en + k * 3) % 2, 3 + (en + k) % 4, other.notch, .8)
                        end
                        px(ex + inside * 4, y + 4 + en % 22, 1, 2, other.fleck, .7)
                        px(ex + inside * 5, y + 11 + (en * 3) % 17, 1, 3, other.notch, .35)
                    end
                end
            end
        end
    end
end

-- Assa a camada estática inteira da sala. Terreno, muros e decorações são
-- fixos na campanha; quem muda de estado (portais, pilares, props) é
-- desenhado por cima todo frame. Se o mapa passar a alterar tiles, o cache
-- do renderer precisa ser invalidado nesse ponto.
function Scene.bake(map, seed)
    local pal = Scene.palette(map)
    local w, h = map.w * 32 + 128, map.h * 32 + 128
    local canvas = G.newCanvas(w, h, {dpiscale = 1})
    canvas:setFilter('nearest', 'nearest')
    local prev = G.getCanvas()
    G.setCanvas(canvas)
    G.clear(Pal.ink[1], Pal.ink[2], Pal.ink[3], 1)
    -- O bake pode rodar dentro do canvas da câmera: zera a transformação.
    -- push() ANTES de origin() — salvar a câmera antes de zerá-la, senão o
    -- pop() restaura a identidade e o restante do frame sai deslocado.
    G.push(); G.origin(); G.translate(64, 64)
    local function at(x, y) return map.tiles[x .. ':' .. y] end

    if map.outdoor then refugeLandscape(map, pal, seed, at) end

    for _, t in pairs(map.tiles) do
        if isFloor(t) then px((t.x - 1) * 32, (t.y - 1) * 32, 32, 32, pal.floor.base) end
    end
    if map.outdoor then refugeGround(map, pal, seed, at)
    elseif pal.floorStyle == 'planks' then floorPlanks(map, pal, seed)
    else floorPatches(map, pal, seed, at) end
    floorShadows(map, pal, at)
    floorDecor(map, pal, seed, at)
    floorWear(map, pal, seed, at)
    -- Escadaria transitável é chão (Props.bakesToGround): assa junto do
    -- piso, por cima de sombra/decor/desgaste — nunca entra na fila de
    -- depth do render, senão o degrau pinta por cima de quem sobe.
    for _, prop in ipairs(map.props or {}) do
        if Props.bakesToGround(prop) then
            Props.draw(prop, (prop.x - 1) * 32, (prop.y - 1) * 32,
                (prop.w or 1) * 32, (prop.h or 1) * 32, pal, 0, true)
        end
    end
    -- Sombras de contato sob props sólidos ficam assadas no piso — mas só
    -- enquanto o corpo ainda ocupa o lugar. 'taken'/'removed' não projetam
    -- nada; 'open' (grade erguida) deixa só o fio da verga alta, nunca a
    -- poça de um corpo fechado. A direção segue o guia: luz do alto à
    -- esquerda, então a elipse desliza para sudeste e ganha uma saia de
    -- queda fraca além do contato.
    local sun = map.lightFrom or {x = -1, y = -1}
    local sx, sy = -sun.x, -sun.y             -- a sombra cai ao contrário da fonte
    for _, prop in ipairs(map.props or {}) do
        if prop.solid then
            local pw, ph = (prop.w or 1) * 32, (prop.h or 1) * 32
            if prop.state == 'taken' or prop.state == 'removed' then
                -- Corpo recolhido: o piso fica limpo.
            elseif prop.state == 'open' then
                -- Erguida: o trilho alto ainda fatia a luz — fio fino sob a
                -- verga, deslocado no sentido da queda, sem sombra de corpo.
                G.setColor(Pal.ink[1], Pal.ink[2], Pal.ink[3], .18)
                G.ellipse('fill', round((prop.x - 1) * 32 + pw / 2 + sx * 2),
                    round((prop.y - 1) * 32 + 7 + sy), round(pw * .3), 2)
            else
                local cx = round((prop.x - 1) * 32 + pw / 2 + sx * 2)
                local cy = round((prop.y - 1) * 32 + ph - 3 + sy * 2)
                G.setColor(Pal.ink[1], Pal.ink[2], Pal.ink[3], .35)
                G.ellipse('fill', cx, cy, round(pw * .42), 4)
                -- Saia de queda: a mesma mancha alongada e mais fraca um
                -- passo além, lendo direção em vez de só contato.
                G.setColor(Pal.ink[1], Pal.ink[2], Pal.ink[3], .14)
                G.ellipse('fill', round(cx + sx * 7), round(cy + sy * 3),
                    round(pw * .32), 3)
            end
        end
    end
    holes(map, pal, at)
    if not map.outdoor then walls(map, pal, seed, at) end
    -- Marca de chegada: runa quieta no spawn da sala.
    if map.spawn then
        local sx, sy = round((map.spawn.x - .5) * 32), round((map.spawn.y - .5) * 32)
        local c = pal.petal
        px(sx - 10, sy - 7, 21, 1, c, .4); px(sx - 10, sy + 6, 21, 1, c, .4)
        px(sx - 10, sy - 6, 1, 12, c, .4); px(sx + 10, sy - 6, 1, 12, c, .4)
        px(sx, sy - 3, 1, 7, c, .55); px(sx - 3, sy, 7, 1, c, .55)
    end
    G.pop()
    G.setCanvas(prev)
    return canvas
end

-- Canvas sujo por sala: quem troca o estado de um prop sólido em jogo (a
-- grade que sobe, o filtro recolhido) marca o mapa aqui. O renderer
-- consulta uma vez por frame e reassa só quando a marca existe — nunca
-- reassa por frame.
local dirty = {}
function Scene.invalidate(map) if map then dirty[map] = true end end
function Scene.isDirty(map)
    if map and dirty[map] then
        dirty[map] = nil
        return true
    end
    return false
end

function Scene.palette(map)
    if map.realm == 'refugio' and map.id ~= 'colina' then return Pal.regions.hub end
    return Pal.regions[map.id] or Pal.regions.default
end

function Scene.selfCheck()
    assert(hash(1, 3, 4, 0) == hash(1, 3, 4, 0), 'Scene variation is stable')
    assert(hash(1, 3, 4, 0) ~= hash(2, 3, 4, 0), 'Seed changes scene variation')
    local m = {}
    assert(not Scene.isDirty(m), 'Unmarked map is clean')
    Scene.invalidate(m); assert(Scene.isDirty(m), 'Marked map asks for rebake')
    assert(not Scene.isDirty(m), 'isDirty consumes the mark once')
    return true
end

return Scene
