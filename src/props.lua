-- Authored props for campaign regions. Every prop is pixel-painted in code,
-- one drawing per prop spanning its whole w×h area (no per-cell repeats).
-- Style: ink outline, two or three tones, light from the top-left — same
-- language as the baked room scene.
local P = require('src.pixel_world').palette
local Palettes = require('src.palettes')
local pixelLine = require('src.pixel_world').pixelLine
local PixelArt = require('src.pixel_art_v2')
local Props = {}
local G = love.graphics
local inscriptionFont

local function round(n) return math.floor(n + .5) end
local function rect(x, y, w, h, c, alpha)
    G.setColor(c[1], c[2], c[3], alpha or 1)
    G.rectangle('fill', math.floor(x + .5), math.floor(y + .5), math.floor(w + .5), math.floor(h + .5))
end

-- Ink outline + fill + top light edge: the shared silhouette of the set.
local function framed(x, y, w, h, fill, light)
    rect(x, y, w, h, P.ink)
    rect(x + 1, y + 1, w - 2, h - 2, fill)
    rect(x + 1, y + 1, w - 2, 1, light or fill)
end

-- Each painter receives the prop's full pixel area (w×h) and the region
-- palette, so wood and cloth follow the room's family.
local draw = {}

-- Colina
draw.sepultura = function(prop, px, py, w, h, pal)
    -- A cova aberta do protagonista (resíduo da fatia I): de longe a boca
    -- escura lia-se como poço d'água — aro claro fechado em volta de um
    -- vazio. Três assinaturas de cova recém-aberta resolvem a ambiguidade:
    -- a LAJE de cobertura retirada e escorada de viés na borda, o MONTE
    -- de terra nova ao lado da boca e a PÁ fincada no monte. A boca fica
    -- retangular: cova é reta, poço é redondo.
    -- Pedra de cabeceira atrás, ainda em pé.
    framed(px + 2, py + 1, 12, 13, pal.wall.face, pal.wall.cap)
    rect(px + 3, py + 1, 10, 2, pal.wall.cap)
    rect(px + 5, py + 5, 2, 6, pal.wall.mortar)
    rect(px + 3, py + 7, 6, 2, pal.wall.mortar)
    -- Terra remexida em lábios irregulares ao redor da boca reta.
    rect(px + 1, py + 15, 20, 13, P.ink)
    rect(px + 3, py + 16, 17, 11, pal.floor.shadow)
    rect(px + 2, py + 22, 19, 6, pal.floor.dark)
    -- Boca de cova + o aro claro só onde a laje assentava — o trecho que
    -- anos de vedação protegeram do vento; a marca partiu em duas metades
    -- na beirada (doc §55).
    rect(px + 4, py + 17, 14, 8, pal.floor.light)
    rect(px + 5, py + 18, 12, 6, P.abyss)
    rect(px + 5, py + 18, 12, 1, P.ink)
    rect(px + 5, py + 23, 12, 1, P.ink)
    -- Vedação partida: duas metades de selo jade na beirada norte do aro.
    rect(px + 6, py + 16, 4, 1, P.jadeLight)
    rect(px + 13, py + 16, 4, 1, P.jadeLight)
    rect(px + 11, py + 17, 2, 1, P.jadeDark)
    -- Monte de terra nova encostado na boca: cúpula escura com torrões
    -- claros por cima — terra mexida esta noite, mais funda que o piso.
    for j = 0, 9 do
        local half = round(math.sqrt(math.max(0, 30 - (j - 5) * (j - 5))) * 1.05)
        rect(px + 25 - half, py + 18 + j, half * 2, 1, pal.floor.shadow)
    end
    rect(px + 17, py + 28, 14, 2, P.ink, .26)
    rect(px + 21, py + 20, 3, 2, pal.floor.dark)
    rect(px + 27, py + 23, 3, 1, pal.floor.dark)
    rect(px + 22, py + 26, 5, 1, pal.floor.dark)
    -- Laje apoiada na borda: a tampa retirada escorada de viés — topo
    -- apoiado na beirada da cova, base cravada no monte. Retângulo de
    -- pedra clara tombado com filete na face e sombra de apoio.
    for j = 0, 13 do
        local sx = px + 14 + round(j * .55)
        rect(sx, py + 12 + j, 9, 1, P.ink)
        rect(sx + 1, py + 12 + j, 7, 1, pal.wall.cap)
    end
    for j = 2, 12 do
        rect(px + 16 + round(j * .55), py + 12 + j, 1, 1, pal.wall.rim)
    end
    rect(px + 14, py + 12, 9, 1, pal.wall.rim)
    -- Pá fincada no monte: ferro enterrado, cabo subindo de viés com grip.
    rect(px + 27, py + 20, 4, 4, pal.wall.mortar)
    rect(px + 28, py + 20, 3, 1, pal.wall.cap)
    pixelLine(px + 29, py + 22, px + 31, py + 6, pal.wood.dark)
    pixelLine(px + 30, py + 22, px + 32, py + 6, pal.wood.base)
    rect(px + 30, py + 4, 4, 2, pal.wood.dark)
    -- Terra solta caída na borda e musgo velho na base da cabeceira —
    -- terra nova não tem musgo; o verde fica só na pedra antiga.
    rect(px + 5, py + 26, 7, 2, pal.floor.shadow)
    rect(px + 7, py + 27, 3, 2, pal.moss); rect(px + 2, py + 13, 3, 2, pal.moss)
end

draw.tampa = function(prop, px, py, w, h, pal)
    -- Tampa de pedra escorada, vista de cima.
    framed(px + 4, py + 12, 24, 15, pal.wall.face, pal.wall.cap)
    rect(px + 4, py + 12, 24, 3, pal.wall.cap)
    pixelLine(px + 9, py + 15, px + 14, py + 23, P.ink)
    pixelLine(px + 14, py + 15, px + 19, py + 23, P.ink)
    rect(px + 13, py + 18, 5, 4, pal.wall.mortar)
    rect(px + 14, py + 19, 3, 2, P.ink)
end

draw.lapide = function(prop, px, py, w, h, pal)
    -- Lápide comum: pedra alta de topo arredondado, inscrição gasta com um
    -- trecho refeito a mão (o dourado do cuidado) e musgo na base. Filo de
    -- luz na face esquerda e salpicos de quartzo dão o granito; a junta da
    -- base afunda a pedra no solo.
    rect(px + 7, py + 29, 18, 2, P.ink, .22)
    rect(px + 10, py + 3, 12, 6, P.ink)
    rect(px + 11, py + 4, 10, 5, pal.wall.face)
    rect(px + 11, py + 4, 10, 1, pal.wall.cap)
    framed(px + 8, py + 8, 16, 22, pal.wall.face, pal.wall.cap)
    rect(px + 9, py + 9, 1, 19, pal.wall.cap, .6)
    rect(px + 9, py + 28, 14, 1, pal.wall.faceDark)
    -- Salpicos de granito + ranhura fina que a chuva abriu na face.
    rect(px + 13, py + 11, 1, 1, pal.wall.mortar, .7)
    rect(px + 20, py + 12, 1, 1, pal.wall.rim, .6)
    rect(px + 12, py + 24, 1, 1, pal.wall.mortar, .7)
    rect(px + 21, py + 24, 1, 1, pal.wall.faceDark, .6)
    pixelLine(px + 19, py + 10, px + 16, py + 14, pal.wall.mortar, .6)
    -- Letreiro em sulcos: o trecho refeito a mão (ouro do cuidado) e o
    -- nome comido pela chuva.
    rect(px + 11, py + 13, 10, 1, pal.wall.mortar)
    rect(px + 11, py + 17, 8, 1, pal.wall.mortar)
    rect(px + 11, py + 21, 6, 1, pal.wall.mortar)
    rect(px + 18, py + 20, 3, 3, pal.petal, .8)
    rect(px + 7, py + 27, 5, 2, pal.moss); rect(px + 20, py + 26, 4, 2, pal.moss)
    rect(px + 12, py + 28, 3, 1, pal.moss, .8)
end

-- Lápide antiga sem cuidado (doc §53 — "as sepulturas antigas têm nomes
-- gastos"): silhueta lascada e levemente tombada, a letra comida pela
-- chuva — só os sulcos rasos restam sob o musgo que sobe pela face.
local function lapideGasta(prop, px, py, w, h, pal)
    rect(px + 10, py + 4, 12, 5, P.ink)
    rect(px + 11, py + 5, 10, 4, pal.wall.face)
    rect(px + 11, py + 5, 8, 1, pal.wall.cap)
    rect(px + 7, py + 29, 18, 2, P.ink, .22)
    rect(px + 8, py + 8, 16, 22, P.ink)
    rect(px + 9, py + 9, 14, 20, pal.wall.face)
    rect(px + 9, py + 9, 14, 1, pal.wall.cap)
    -- Quina lascada no alto direito: a falta escurece, não some. Da falta
    -- desce a trinca que a geada abriu.
    rect(px + 21, py + 8, 3, 4, P.ink)
    rect(px + 21, py + 11, 3, 2, pal.wall.faceDark)
    pixelLine(px + 20, py + 12, px + 18, py + 18, pal.wall.mortar, .7)
    rect(px + 9, py + 9, 1, 18, pal.wall.cap, .45)
    -- Nome apagado: sulcos rasos interrompidos por trechos lisos.
    rect(px + 11, py + 14, 9, 1, pal.wall.mortar, .7)
    rect(px + 11, py + 18, 5, 1, pal.wall.mortar, .5)
    rect(px + 14, py + 16, 8, 2, pal.wall.face)
    rect(px + 12, py + 21, 6, 1, pal.wall.faceDark, .5)
    -- Salpicos de granito + musgo de quem ninguém visita, que sobe pela
    -- face e afoga a base.
    rect(px + 13, py + 12, 1, 1, pal.wall.mortar, .6)
    rect(px + 20, py + 20, 1, 1, pal.wall.faceDark, .6)
    rect(px + 9, py + 23, 3, 6, pal.moss)
    rect(px + 7, py + 27, 6, 3, pal.moss)
    rect(px + 19, py + 28, 4, 2, pal.moss)
    rect(px + 13, py + 26, 2, 1, pal.moss, .8)
end
draw.lapideGasta = lapideGasta
-- As lápides do pátio são as antigas de nome gasto (def do Pátio); a do
-- protagonista guarda a letra protegida pela vedação — fica com o painter
-- comum, que ainda tem o trecho refeito a mão.
draw.lapide1 = lapideGasta; draw.lapide2 = lapideGasta
draw.lapide3 = lapideGasta; draw.lapide4 = lapideGasta

-- Marca improvisada de sepultura (doc §53 — "as recentes carregam sinais
-- menores, feitos com o que havia à mão"): estaca torta com um retalho
-- preso sob o peso de uma pedra, e uma flor deixada em cima.
draw.marcaImpro = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 3, py + 28, 26, 3, P.ink, .22)
    -- Estaca cravada torta com travessa curta — nó na fibra e ponta
    -- escurecida de terra molhada.
    pixelLine(px + 10, py + 27, px + 12, py + 6, pal.wood.dark)
    pixelLine(px + 9, py + 27, px + 11, py + 6, pal.wood.base)
    rect(px + 9, py + 14, 1, 2, pal.wood.dark)
    rect(px + 8, py + 24, 3, 3, pal.floor.shadow, .7)
    rect(px + 7, py + 10, 9, 2, pal.wood.base)
    rect(px + 7, py + 10, 9, 1, pal.wood.light)
    rect(px + 13, py + 10, 1, 1, pal.wood.dark)
    -- Retalho amarrado na estaca: pano claro que a brisa pende devagar,
    -- com a barra puída e o ponto da amarra.
    local sway = reduced and 0
        or round(math.sin(t * 1.5 + (prop.x or 0) * 1.7) * 1.3)
    rect(px + 12, py + 11, 5, 8, pal.cloth.light)
    rect(px + 12, py + 11, 5, 1, P.ink, .5)
    rect(px + 13, py + 13, 3, 1, pal.cloth.base, .6)
    rect(px + 12 + sway, py + 17, 4, 2, pal.cloth.base)
    rect(px + 12 + sway, py + 19, 4, 1, pal.cloth.dark, .7)
    -- Pedra fazendo peso sobre a ponta do retalho + a flor pousada em cima.
    framed(px + 19, py + 22, 8, 6, pal.wall.face, pal.wall.cap)
    rect(px + 20, py + 18, 1, 4, pal.moss)
    rect(px + 19, py + 16, 3, 3, P.ink)
    rect(px + 20, py + 16, 1, 2, pal.petal)
    -- Pedrinhas soltas ao redor: o chão da colina nunca está liso.
    rect(px + 5, py + 27, 2, 1, pal.wall.mortar, .8)
    rect(px + 14, py + 28, 2, 1, pal.wall.mortar, .6)
    rect(px + 24, py + 26, 1, 1, pal.wall.faceDark, .7)
end
-- A segunda marca improvisada do pátio chegou com kind='pano' de
-- placeholder e lia-se como a mesma caixa verde solta — o id pede a
-- estaca com retalho, como marcaImpro1 pede flores.
draw.marcaImpro2 = draw.marcaImpro

draw.caixao = function(prop, px, py, w, h, pal)
    -- Caixão comprido visto de cima: largo na cabeceira e afunilando aos
    -- pés, com a junta da tampa empenada abrindo uma fresta escura.
    local wood = pal.wood
    rect(px + 3, py + 28, w - 6, 3, P.ink, .22)
    rect(px + 3, py + 4, w - 14, 24, P.ink)
    rect(px + w - 11, py + 7, 8, 18, P.ink)
    rect(px + 4, py + 5, w - 16, 22, wood.base)
    rect(px + w - 10, py + 8, 6, 16, wood.base)
    rect(px + 4, py + 5, w - 16, 2, wood.light)
    rect(px + w - 10, py + 8, 6, 1, wood.light)
    rect(px + 6, py + 12, w - 20, 1, wood.dark)
    rect(px + 6, py + 20, w - 20, 1, wood.dark)
    -- Veios longos no tampo + alças de ferro na lateral — caixão se carrega.
    rect(px + 7, py + 8, w - 22, 1, wood.dark, .4)
    rect(px + 8, py + 24, w - 24, 1, wood.dark, .4)
    rect(px + 13, py + 15, 2, 2, wood.dark, .6)
    for _, hx in ipairs({8, math.floor(w / 2) - 3, w - 14}) do
        rect(px + hx, py + 25, 4, 1, pal.wall.mortar)
        rect(px + hx, py + 25, 1, 3, pal.wall.mortar)
        rect(px + hx + 3, py + 25, 1, 3, pal.wall.mortar)
    end
    rect(px + w - 12, py + 14, 2, 6, P.ink)
    rect(px + 10, py + 9, 9, 4, wood.dark)
    rect(px + 11, py + 10, 7, 2, pal.wall.cap)
end

-- Bancos divergentes por id: o feitio velho (tábua única irregular sobre
-- pernas de forquilha) fica com quem o lugar marcou — o banco da praça
-- está ali desde antes da pedra assentar.
local bancoVelho = {bancoVelho = true, bancoDivergente = true}

draw.banco = function(prop, px, py, w, h, pal)
    local wood = pal.wood
    if bancoVelho[prop.id] then
        -- Tábua irregular com a ponta comida e um remendo clareado; pernas
        -- de forquilha tortas — madeira de galho, não de serra. Os veios
        -- seguem tortos e o pé encosta musgo: o banco viveu chuva.
        rect(px + 3, py + 28, 25, 3, P.ink, .22)
        rect(px + 2, py + 13, 27, 7, P.ink)
        rect(px + 3, py + 14, 24, 5, wood.base)
        rect(px + 3, py + 14, 24, 1, wood.light)
        rect(px + 25, py + 13, 4, 3, P.ink)
        rect(px + 25, py + 15, 4, 1, wood.dark)
        rect(px + 26, py + 16, 3, 2, wood.dark, .7)
        -- Veio torto correndo a tábua + nó onde a fibra trançou.
        rect(px + 4, py + 16, 20, 1, wood.dark)
        rect(px + 6, py + 15, 6, 1, wood.dark, .5)
        rect(px + 16, py + 17, 7, 1, wood.dark, .45)
        rect(px + 10, py + 15, 2, 2, wood.dark)
        rect(px + 14, py + 14, 5, 3, wood.light)
        pixelLine(px + 7, py + 19, px + 4, py + 28, P.ink)
        pixelLine(px + 8, py + 19, px + 6, py + 28, wood.dark)
        pixelLine(px + 23, py + 19, px + 27, py + 28, P.ink)
        pixelLine(px + 22, py + 19, px + 25, py + 28, wood.dark)
        rect(px + 3, py + 27, 4, 1, P.ink); rect(px + 25, py + 28, 4, 1, P.ink)
        rect(px + 4, py + 26, 3, 2, pal.moss); rect(px + 26, py + 27, 2, 1, pal.moss)
        return
    end
    -- Banco comum de tábua dupla: junta de serra, veios curtos quebrando
    -- junto ao nó e o fio dianteiro clareado onde todos sentam — o feitio
    -- feito junto, repetido pela casa. O assento cobre a largura que o
    -- mapa bloqueia (prop.w células, w já em px): w=1 dá o banco curto de
    -- sempre; w≥2 estica a tábua com pernas a cada vão e travessa —
    -- banco corrido, não um banco curto seguido de vazio sólido.
    local seatW = math.max(14, w - 4)
    rect(px + 4, py + 28, seatW - 4, 3, P.ink, .22)
    framed(px + 2, py + 13, seatW, 7, wood.base, wood.light)
    rect(px + 2, py + 13, seatW, 1, wood.light)
    rect(px + 3, py + 16, seatW - 2, 1, wood.dark)
    -- Veios da primeira tábua; nos bancos corridos eles retomam a cada
    -- vão, quebrando junto às pernas como no feitio curto.
    rect(px + 6, py + 14, 7, 1, wood.dark, .55)
    rect(px + 19, py + 15, 8, 1, wood.dark, .5)
    rect(px + 13, py + 18, 6, 1, wood.dark, .45)
    rect(px + 15, py + 14, 2, 2, wood.dark)
    for vx = px + 34, px + seatW - 6, 16 do
        rect(vx, py + 15, 8, 1, wood.dark, .5)
        local tail = math.min(5, px + seatW - vx - 10)
        if tail > 0 then rect(vx + 9, py + 17, tail, 1, wood.dark, .45) end
    end
    rect(px + seatW - 4, py + 17, 2, 1, wood.dark)
    rect(px + 3, py + 19, seatW - 2, 1, wood.dark, .6)
    rect(px + 10, py + 19, math.max(0, seatW - 16), 1, wood.light, .5)
    -- Pernas de taco nas duas pontas sempre; uma por vão (~24 px) quando
    -- o assento passa de uma braçada. Nos corridos a travessa amarra os
    -- pés — a mesma leitura do bancoSerra, no feitio de tábua dupla.
    local legs = math.max(2, math.floor(seatW / 24) + 1)
    for i = 0, legs - 1 do
        local lx = round(px + 5 + i * (seatW - 10) / (legs - 1))
        rect(lx, py + 20, 4, 8, P.ink)
        rect(lx + 1, py + 20, 2, 7, wood.dark)
        rect(lx - 1, py + 28, 6, 1, P.ink)
    end
    if legs > 2 then
        rect(px + 9, py + 23, seatW - 18, 2, wood.dark)
        rect(px + 9, py + 23, seatW - 18, 1, wood.base)
    end
end

-- Bancos de feitios diferentes (doc §91 — "pelo acabamento, fica fácil
-- imaginar quais foram feitos juntos e quais chegaram depois"): o Pátio
-- planta os ids sobre kind='banco'; cada um carrega sua carpintaria.
draw.bancoSerra = function(prop, px, py, w, h, pal)
    local wood = pal.wood
    -- Banco de serra nova: tábua reta de cantos vivos, testadas escuras
    -- nas pontas, cavilhas à vista e travessa entre os pés esquadrejados
    -- — o feitio que chegou por último e ainda não pegou forma de corpo.
    rect(px + 4, py + 28, 24, 3, P.ink, .22)
    framed(px + 3, py + 14, 26, 6, wood.base, wood.light)
    rect(px + 3, py + 14, 2, 6, wood.dark)
    rect(px + 27, py + 14, 2, 6, wood.dark)
    rect(px + 8, py + 15, 1, 1, wood.dark); rect(px + 23, py + 15, 1, 1, wood.dark)
    rect(px + 4, py + 17, 24, 1, wood.dark, .5)
    rect(px + 5, py + 15, 9, 1, wood.dark, .35)
    rect(px + 3, py + 19, 26, 1, wood.dark)
    rect(px + 6, py + 20, 5, 8, P.ink); rect(px + 21, py + 20, 5, 8, P.ink)
    rect(px + 7, py + 20, 3, 7, wood.base); rect(px + 22, py + 20, 3, 7, wood.base)
    rect(px + 8, py + 22, 16, 2, wood.dark)
    rect(px + 8, py + 22, 16, 1, wood.base)
    rect(px + 5, py + 28, 7, 1, P.ink); rect(px + 20, py + 28, 7, 1, P.ink)
end

draw.bancoPedra = function(prop, px, py, w, h, pal)
    -- Banco de pedra: laje única sobre dois pés de bloco — o mais velho da
    -- praça, liso onde gerações sentaram, junta e musgo nos pés.
    rect(px + 4, py + 28, 24, 3, P.ink, .22)
    framed(px + 2, py + 13, 28, 7, pal.wall.face, pal.wall.cap)
    rect(px + 2, py + 13, 28, 2, pal.wall.cap)
    -- Quina lascada no canto direito e o polimento de uso no fio.
    rect(px + 26, py + 13, 4, 3, P.ink)
    rect(px + 26, py + 15, 4, 1, pal.wall.faceDark)
    rect(px + 3, py + 17, 24, 1, pal.wall.mortar, .6)
    rect(px + 8, py + 15, 9, 1, pal.wall.rim, .5)
    rect(px + 19, py + 16, 5, 1, pal.wall.mortar, .5)
    framed(px + 5, py + 20, 6, 8, pal.wall.faceDark, pal.wall.face)
    framed(px + 21, py + 20, 6, 8, pal.wall.faceDark, pal.wall.face)
    rect(px + 5, py + 20, 6, 1, pal.wall.cap)
    rect(px + 21, py + 20, 6, 1, pal.wall.cap)
    rect(px + 4, py + 27, 4, 2, pal.moss); rect(px + 24, py + 27, 4, 2, pal.moss)
    rect(px + 6, py + 19, 3, 1, pal.moss, .8)
end

-- PÁTIO — caixa de ferramentas de Doro (resíduo (b) da fatia I): o
-- retângulo de pano solto no pátio lia-se como armário verde sem dono.
-- Agora é caixa de madeira clara com o serviço saindo pela boca aberta —
-- cabo de pá, formão com ferro e metro dobrável aberto em dois vãos:
-- Doro conserta a casa funerária ("dos reparos, quando deixam").
local function caixaFerramentas(prop, px, py, w, h, pal)
    local wood = pal.wood
    rect(px + 3, py + 28, 26, 3, P.ink, .24)
    -- Ferramentas por cima da boca: o ferro e a articulação leem antes
    -- da caixa — é o conteúdo que dá identidade, não o recipiente.
    pixelLine(px + 8, py + 15, px + 5, py + 2, wood.dark)
    pixelLine(px + 9, py + 15, px + 6, py + 2, wood.base)
    rect(px + 3, py + 1, 6, 2, wood.dark)
    rect(px + 14, py + 5, 3, 10, wood.dark)
    rect(px + 13, py + 2, 5, 3, pal.wall.cap)
    rect(px + 14, py + 2, 3, 1, pal.wall.rim)
    pixelLine(px + 21, py + 14, px + 25, py + 4, wood.light)
    pixelLine(px + 25, py + 4, px + 29, py + 10, wood.base)
    rect(px + 24, py + 3, 2, 2, P.ink); rect(px + 28, py + 9, 2, 2, P.ink)
    -- Caixa aberta: boca escura no topo, corpo de tábua clara com juntas,
    -- cantoneiras de ferro e o fecho — caixa de obra, não de feira.
    rect(px + 4, py + 12, 24, 4, P.ink)
    rect(px + 5, py + 13, 22, 2, wood.dark)
    framed(px + 3, py + 15, 26, 14, wood.light, pal.wall.cap)
    rect(px + 3, py + 15, 26, 2, pal.wall.cap)
    rect(px + 4, py + 22, 24, 2, wood.base)
    rect(px + 4, py + 22, 24, 1, wood.dark, .4)
    rect(px + 5, py + 26, 9, 1, wood.dark, .5)
    rect(px + 17, py + 25, 8, 1, wood.dark, .45)
    rect(px + 14, py + 15, 4, 5, P.ink)
    rect(px + 14, py + 15, 4, 2, wood.dark)
    -- Cantoneiras + rebites: as quinas de ferro seguram a tábua no tranco.
    rect(px + 6, py + 17, 2, 2, pal.wall.cap); rect(px + 24, py + 17, 2, 2, pal.wall.cap)
    rect(px + 3, py + 15, 3, 3, pal.wall.mortar); rect(px + 26, py + 15, 3, 3, pal.wall.mortar)
    rect(px + 4, py + 16, 1, 1, P.ink); rect(px + 27, py + 16, 1, 1, P.ink)
    -- Serragem miúda sob a boca: a caixa abriu agora, em cima do trabalho.
    rect(px + 6, py + 29, 4, 1, pal.wood.light, .6)
    rect(px + 12, py + 30, 6, 1, pal.wood.light, .4)
    rect(px + 21, py + 29, 3, 1, pal.wood.light, .5)
end

draw.pano = function(prop, px, py, w, h, pal, t, reduced)
    -- Id vence kind: o 'pano' sólido do pátio é a caixa de ferramentas de
    -- Doro; os demais kind='pano' seguem pano de velório pendurado.
    if prop.id == 'pano' then
        return caixaFerramentas(prop, px, py, w, h, pal, t, reduced)
    end
    local cloth = pal.cloth
    rect(px + 2, py + 2, 28, 3, P.ink); rect(px + 3, py + 2, 26, 2, pal.wood.light)
    framed(px + 4, py + 4, 24, 25, cloth.base, cloth.light)
    rect(px + 4, py + 4, 24, 2, cloth.light)
    for i = 0, 3 do
        rect(px + 7 + i * 5, py + 9, 2, 17, cloth.dark, .7)
    end
    -- Barra assimétrica e fios soltos ondulam numa brisa lenta.
    local sway = reduced and 0 or round(math.sin(t * 1.4 + (prop.x or 0) * 1.9) * 1.4)
    rect(px + 4 + sway, py + 26, 24, 2, cloth.dark)
    rect(px + 6 + sway * 2, py + 29, 2, 2, cloth.base)
    rect(px + 14 + sway * 2, py + 29, 2, 2, cloth.base)
    rect(px + 22 + sway, py + 29, 2, 2, cloth.base)
    rect(px + 14, py + 12, 4, 5, pal.petal, .85)
    rect(px + 15, py + 13, 2, 3, pal.wood.light)
end

draw.bau = function(prop, px, py, w, h, pal)
    local open = prop and prop.state == 'done'
    local wood = pal.wood
    if open then
        framed(px + 5, py + 2, 22, 8, wood.base, wood.light)
        rect(px + 6, py + 4, 20, 3, P.ink)
    end
    framed(px + 3, py + 10, 26, 17, wood.base, wood.light)
    rect(px + 3, py + 10, 26, 2, wood.light)
    rect(px + 3, py + 16, 26, 2, wood.dark)
    -- Cintas de ferro com rebites + veios na tampa: baú de viagem, não baú
    -- de feira — guarda o que foi trazido de fora.
    rect(px + 7, py + 10, 3, 17, pal.wall.mortar, .8)
    rect(px + 22, py + 10, 3, 17, pal.wall.mortar, .8)
    rect(px + 7, py + 10, 3, 1, pal.wall.cap, .8); rect(px + 22, py + 10, 3, 1, pal.wall.cap, .8)
    rect(px + 8, py + 13, 1, 1, P.ink); rect(px + 23, py + 13, 1, 1, P.ink)
    rect(px + 8, py + 21, 1, 1, P.ink); rect(px + 23, py + 21, 1, 1, P.ink)
    rect(px + 12, py + 12, 8, 1, wood.dark, .45)
    rect(px + 11, py + 24, 10, 1, wood.dark, .4)
    if open then
        rect(px + 6, py + 12, 20, 6, P.ink)
        rect(px + 7, py + 13, 18, 1, pal.petal, .6)
    else
        rect(px + 14, py + 15, 4, 6, P.ink)
        rect(px + 15, py + 16, 2, 4, pal.petal)
        rect(px + 15, py + 18, 2, 1, pal.wall.mortar)
    end
end

draw.grade = function(prop, px, py, w, h, pal)
    if prop and prop.state == 'open' then
        -- Portão erguido: só os trilhos e a ponta das barras aparecem.
        framed(px, py, w, 5, pal.wall.face, pal.wall.cap)
        for i = 1, math.floor(w / 12) do
            rect(px + i * 12 - 6, py + 5, 3, 5, pal.wall.mortar)
        end
        return
    end
    framed(px, py, w, 4, pal.wall.face, pal.wall.cap)
    framed(px, py + 27, w, 4, pal.wall.face, pal.wall.cap)
    for i = 0, math.floor(w / 12) do
        local x = px + 5 + i * 12
        if x + 3 <= px + w - 3 then
            rect(x, py + 3, 3, 26, pal.wall.brick)
            rect(x, py + 3, 1, 26, pal.wall.rim)
        end
    end
    rect(px + 1, py + 14, w - 2, 2, pal.wood.dark)
end

draw.flores = function(prop, px, py, w, h, pal)
    -- Touceira miúda: terra revolvida por baixo, haste, pétala e o ponto
    -- claro do miolo — flor de caminho, não de jardim.
    rect(px + 5, py + 26, 7, 1, pal.floor.dark, .6)
    rect(px + 12, py + 28, 8, 1, pal.floor.dark, .5)
    rect(px + 20, py + 25, 7, 1, pal.floor.dark, .6)
    for _, f in ipairs({{7, 18}, {14, 21}, {21, 17}, {25, 23}, {11, 25}}) do
        rect(px + f[1], py + f[2] + 2, 1, 3, pal.moss)
        rect(px + f[1] - 1, py + f[2], 3, 3, P.ink)
        rect(px + f[1], py + f[2], 1, 2, pal.petal)
        rect(px + f[1] + 1, py + f[2] + 1, 1, 1, pal.cloth.light)
        rect(px + f[1] + 1, py + f[2] + 3, 1, 1, pal.moss, .8)
    end
    -- Folhinhas caídas: o vento já passou por aqui.
    rect(px + 9, py + 29, 2, 1, pal.moss, .7)
    rect(px + 23, py + 28, 1, 1, pal.petal, .5)
end

-- Refúgio
draw.altar = function(prop, px, py, w, h, pal, t, reduced)
    -- A mesa cobre a largura que o mapa bloqueia (prop.w células, w já
    -- em px): w=1 é o altar de sempre; w≥2 centraliza um altar largo na
    -- célula dupla — bloco, toalha e votivas distribuídos, nunca metade
    -- da área sólida deixada vazia (mesmo fix do banco).
    local aw = math.min(w - 8, 24 + math.floor((w - 32) * .8))
    local ax = px + math.floor((w - aw) / 2)
    rect(ax + 1, py + 28, aw - 2, 3, P.ink, .24)
    framed(ax, py + 12, aw, 16, pal.wall.face, pal.wall.cap)
    rect(ax, py + 12, aw, 3, pal.wall.cap)
    -- Bloco de pedra: junta baixa e o degrau gasto de quem se aproxima.
    rect(ax + 1, py + 23, aw - 2, 1, pal.wall.mortar, .6)
    rect(ax + 2, py + 26, aw - 4, 1, pal.wall.faceDark, .5)
    rect(ax + 6, py + 12, math.min(12, aw - 12), 1, pal.wall.rim, .8)
    rect(ax + 3, py + 15, aw - 6, 10, pal.cloth.dark, .85)
    rect(ax + 3, py + 15, aw - 6, 1, pal.cloth.base)
    -- Toalha do altar: barra bordada com pespontos claros no fio,
    -- repetindo o passo enquanto a barra corre a largura.
    for i = 0, math.floor((aw - 6) / 4) do
        rect(ax + 4 + i * 4, py + 23, 2, 1, pal.cloth.light, .8)
    end
    rect(ax + 3, py + 24, aw - 6, 1, pal.cloth.base, .6)
    if prop.state == 'cold' or prop.state == 'quiet' then return end
    -- Votivas acesas distribuídas pela mesa: cada chama treme na própria
    -- fase e lança brilho curto.
    local candles = aw > 40 and {6, math.floor(aw / 2) - 1, aw - 10} or {5, aw - 7}
    for _, cx in ipairs(candles) do
        local fl = reduced and .3 or .5 + .5 * math.sin(t * 9 + cx * 1.7 + (prop.x or 0) * 2.3)
        local fh = 2 + (fl > .62 and 1 or 0)
        rect(ax + cx, py + 5, 3, 8, P.ink)
        rect(ax + cx, py + 6, 3, 6, pal.wood.light)
        rect(ax + cx, py + 5 - fh, 3, fh + 1, P.ink)
        rect(ax + cx + 1, py + 6 - fh, 1, fh, pal.petal)
        rect(ax + cx + 1, py + 6 - fh, 1, 1, P.goldLight)
        rect(ax + cx - 1, py + 11, 5, 2, pal.petal, .12 + .18 * fl)
    end
end

draw.fogao = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 4, py + 29, 24, 2, P.ink, .22)
    framed(px + 3, py + 6, 26, 23, pal.wall.face, pal.wall.cap)
    rect(px + 3, py + 6, 26, 3, pal.wall.cap)
    -- Corpo de alvenaria: juntas quebrando a face e a crosta de fuligem
    -- escurecendo por cima da boca — fogão que trabalha mora na fuligem.
    rect(px + 5, py + 11, 6, 1, pal.wall.mortar, .7)
    rect(px + 21, py + 11, 5, 1, pal.wall.mortar, .7)
    rect(px + 4, py + 17, 3, 1, pal.wall.mortar, .6)
    rect(px + 26, py + 17, 2, 1, pal.wall.mortar, .6)
    rect(px + 5, py + 25, 8, 1, pal.wall.faceDark, .5)
    rect(px + 19, py + 26, 6, 1, pal.wall.faceDark, .5)
    PixelArt.dither(px + 9, py + 9, 14, 4, P.ink, .3)
    rect(px + 7, py + 13, 18, 11, P.ink)
    rect(px + 8, py + 14, 16, 9, pal.floor.shadow)
    -- Aro de ferro na boca + cinza assentada na soleira.
    rect(px + 7, py + 13, 18, 1, pal.wall.mortar)
    rect(px + 9, py + 23, 14, 2, pal.wall.mortar, .5)
    -- Brasa baixa na boca, respirando devagar.
    local glow = reduced and .75 or .55 + .45 * math.sin(t * 3.1 + (prop.x or 0) * 1.3)
    rect(px + 10, py + 18, 12, 4, pal.wood.dark)
    if prop.state == 'cold' or prop.state == 'quiet' then return end
    rect(px + 11, py + 19, 3, 2, P.danger, .55 + .45 * glow)
    rect(px + 16, py + 18, 4, 2, pal.petal, .45 + .55 * glow)
    rect(px + 22, py + 18, 2, 2, pal.petal, glow)
    if not reduced and math.sin(t * 6.7 + (prop.x or 0) * 3.1) > .86 then
        rect(px + 14, py + 16, 1, 1, P.goldLight)
    end
end

draw.mesa = function(prop, px, py, w, h, pal, t, reduced)
    local wood = pal.wood
    rect(px + 3, py + 29, w - 6, 2, P.ink, .22)
    framed(px + 1, py + 9, w - 2, 9, wood.base, wood.light)
    for i = 1, math.floor(w / 16) - 1 do
        rect(px + i * 16, py + 10, 1, 7, wood.dark, .6)
    end
    -- Tampo de uso: veios entre as juntas, corte antigo e a faixa limpa de
    -- esfregaço onde as mãos trabalham (doc §109).
    for i = 0, math.floor(w / 14) - 1 do
        rect(px + 4 + i * 14 + (i % 2) * 3, py + 12, 7, 1, wood.dark, .4)
    end
    rect(px + 6, py + 15, 5, 1, P.ink, .5)
    rect(px + w - 18, py + 11, 8, 2, wood.light, .4)
    rect(px + 2, py + 17, w - 4, 1, wood.dark, .55)
    rect(px + 4, py + 18, 3, 11, P.ink); rect(px + w - 7, py + 18, 3, 11, P.ink)
    rect(px + 5, py + 18, 1, 10, wood.dark, .8)
    rect(px + w - 6, py + 18, 1, 10, wood.dark, .8)
    rect(px + 6, py + 25, w - 12, 2, wood.dark)
    -- Miudezas de velório: tigela e vela de chama curta, tremulando —
    -- cada peça com sua sombra no tampo.
    rect(px + 10, py + 6, 8, 5, P.ink); rect(px + 11, py + 7, 6, 3, pal.wall.cap)
    rect(px + 11, py + 7, 6, 1, pal.wall.rim)
    rect(px + 10, py + 10, 8, 1, P.ink, .3)
    rect(px + w - 14, py + 3, 2, 8, P.ink); rect(px + w - 14, py + 4, 2, 6, pal.wood.light)
    rect(px + w - 15, py + 10, 4, 2, pal.wall.cap, .8)
    -- 'quiet'/'covered' deixa só o pavio frio — a mesa dorme junto da casa.
    if prop.state == 'quiet' or prop.state == 'covered' or prop.state == 'cold' then
        rect(px + w - 14, py + 2, 2, 1, P.ink)
        return
    end
    local fl = reduced and .4 or .5 + .5 * math.sin(t * 8.3 + (prop.x or 0))
    rect(px + w - 15, py + 1 + (fl > .7 and 0 or 1), 4, 2, pal.petal, .7 + .3 * fl)
    rect(px + w - 14, py + 1, 1, 1, P.goldLight, .5 + .5 * fl)
end

draw.cama = function(prop, px, py, w, h, pal)
    local cloth = pal.cloth
    -- Footprint fixo: w=1 hoje em todos os defs; se um def plantar w=2,
    -- estender como caixas/altar/banco (mesma falha de célula sólida vazia).
    -- Cama de verdade no chão: estrado baixo com sombra de contato,
    -- cabeceira de tábuas, colchão de pano cru, travesseiro e cobertor
    -- dobrado — não um quadro pendurado.
    rect(px + 3, py + 28, 27, 3, P.ink, .3)
    -- Cabeceira com pontas torneadas; 'named' grava o hóspede na madeira —
    -- a placa dos nomes do Refúgio. Veios verticais leem a tábua de pé.
    framed(px + 4, py + 1, 24, 8, pal.wood.dark, pal.wood.base)
    rect(px + 3, py, 4, 3, pal.wood.dark); rect(px + 25, py, 4, 3, pal.wood.dark)
    rect(px + 4, py + 1, 24, 1, pal.wood.base)
    for i = 0, 3 do rect(px + 8 + i * 5, py + 3, 1, 5, pal.wood.base, .4) end
    if prop.state == 'named' then
        rect(px + 10, py + 3, 12, 3, P.ink)
        rect(px + 12, py + 4, 2, 1, P.goldLight); rect(px + 16, py + 4, 4, 1, P.goldLight)
    end
    -- Estrado + colchão de pano cru assentado no chão: pés de taco nos
    -- cantos, vivos da costura do colchão e o caimento do lado mais usado.
    framed(px + 5, py + 9, 22, 19, pal.wood.base, pal.wood.light)
    rect(px + 7, py + 10, 18, 16, pal.wall.cap)
    rect(px + 7, py + 10, 1, 16, pal.wall.rim, .6)
    rect(px + 24, py + 10, 1, 16, pal.wall.face, .7)
    rect(px + 6, py + 27, 2, 2, pal.wood.dark)
    rect(px + 24, py + 27, 2, 2, pal.wood.dark)
    -- Travesseiro encostado na cabeceira, com o vinco do pescoço.
    rect(px + 8, py + 10, 16, 5, P.ink)
    rect(px + 9, py + 11, 14, 4, pal.wall.rim)
    rect(px + 9, py + 11, 14, 1, Palettes.white)
    rect(px + 11, py + 13, 10, 1, pal.wall.cap)
    rect(px + 9, py + 11, 2, 3, pal.wall.cap, .8)
    -- Cobertor sobre os pés: barra caída no estrado, pespontos na bainha
    -- e a sombra do volume por baixo do fio.
    rect(px + 7, py + 17, 18, 9, cloth.base)
    rect(px + 7, py + 17, 18, 1, cloth.light)
    for i = 0, 3 do rect(px + 9 + i * 4, py + 18, 1, 7, cloth.dark, .5) end
    for i = 0, 3 do rect(px + 8 + i * 4, py + 18, 1, 1, cloth.light, .8) end
    rect(px + 7, py + 24, 18, 2, cloth.dark)
    rect(px + 7, py + 26, 18, 1, P.ink, .3)
end

draw.cisterna = function(prop, px, py, w, h, pal, t, reduced)
    -- Boca do poço: anel de pedra sobre o abismo, desenhado na área toda.
    local cx, cy = px + w / 2, py + h / 2
    G.setColor(P.ink); G.ellipse('fill', round(cx), round(cy + 2), round(w * .40), round(h * .35))
    G.setColor(pal.wall.face[1], pal.wall.face[2], pal.wall.face[3], 1)
    G.ellipse('fill', round(cx), round(cy), round(w * .38), round(h * .34))
    G.setColor(pal.wall.cap[1], pal.wall.cap[2], pal.wall.cap[3], 1)
    G.ellipse('fill', round(cx), round(cy - 1), round(w * .38), round(h * .34) - 2)
    G.setColor(P.abyss[1], P.abyss[2], P.abyss[3], 1)
    G.ellipse('fill', round(cx), round(cy + 2), round(w * .26), round(h * .2))
    if prop.state == 'murky' or prop.state == 'quiet' then
        G.setColor(pal.moss); G.ellipse('fill', round(cx), round(cy + 5), round(w * .2), 4)
        rect(px + 7, py + h - 13, 9, 3, pal.moss)
        return
    end
    -- Lume da água: o reflexo desliza e respira; uma segunda mancha menor
    -- acompanha com atraso, como uma ondulação presa no poço.
    local shimmer = reduced and .5 or .55 + .3 * math.sin(t * 2.1 + (prop.x or 0))
    local slide = reduced and 0 or round(math.sin(t * 1.7) * 2)
    G.setColor(pal.cloth.base[1], pal.cloth.base[2], pal.cloth.base[3], .4 + .3 * shimmer)
    G.ellipse('fill', round(cx - 3 + slide), round(cy + 4), round(w * .12), 3)
    G.setColor(pal.cloth.light[1], pal.cloth.light[2], pal.cloth.light[3], .25 * shimmer)
    G.ellipse('fill', round(cx + 5 - slide), round(cy + 1), round(w * .07), 2)
end

draw.bancada = function(prop, px, py, w, h, pal)
    local wood = pal.wood
    rect(px + 2, py + 29, w - 4, 2, P.ink, .22)
    framed(px + 1, py + 7, w - 2, 10, wood.base, wood.light)
    rect(px + 1, py + 7, w - 2, 1, wood.light)
    -- Tampo de trabalho: juntas das tábuas, veios e a faixa gasta no fio
    -- onde as mãos trabalham (doc §121 — "parte da bancada está coberta").
    for i = 0, math.floor(w / 12) - 1 do
        rect(px + 3 + i * 12 + (i % 2) * 4, py + 11, 6, 1, wood.dark, .4)
        rect(px + 5 + i * 12, py + 14, 8, 1, wood.dark, .35)
    end
    rect(px + 2, py + 15, w - 4, 1, wood.dark, .5)
    rect(px + 4, py + 17, 3, 12, P.ink); rect(px + w - 7, py + 17, 3, 12, P.ink)
    rect(px + 5, py + 17, 1, 10, wood.dark, .8)
    rect(px + w - 6, py + 17, 1, 10, wood.dark, .8)
    -- Travessa baixa + aparas embaixo: o cepo trabalha todo dia.
    rect(px + 6, py + 24, w - 12, 2, wood.dark)
    rect(px + 3, py + 28, 5, 1, P.ink); rect(px + w - 8, py + 28, 5, 1, P.ink)
    rect(px + 8, py + 27, 4, 1, wood.light, .5)
    rect(px + w - 14, py + 28, 5, 1, wood.light, .4)
    if prop.state == 'covered' then
        rect(px, py + 6, w, 15, pal.cloth.dark)
        rect(px + 1, py + 6, w - 2, 3, pal.cloth.base)
        for sx = 8, w - 2, 13 do rect(px + sx, py + 10, 2, 10, pal.cloth.base) end
        -- Bainha do pano de cobrir: pespontos no fio.
        for sx = 4, w - 4, 6 do rect(px + sx, py + 19, 1, 1, pal.cloth.light, .7) end
        return
    end
    -- Ferramentas espalhadas na bancada — cada uma com sua sombra.
    rect(px + 8, py + 14, 8, 2, P.ink, .3)
    pixelLine(px + 9, py + 10, px + 15, py + 15, wood.light)
    pixelLine(px + 14, py + 10, px + 9, py + 15, pal.wall.cap)
    rect(px + w - 18, py + 8, 4, 8, P.ink); rect(px + w - 17, py + 9, 2, 6, wood.dark)
    rect(px + w - 18, py + 15, 5, 2, P.ink, .3)
    rect(px + w - 26, py + 10, 6, 5, pal.wall.mortar)
    rect(px + w - 26, py + 10, 6, 1, pal.wall.cap, .7)
    rect(px + w - 26, py + 15, 6, 1, P.ink, .3)
end

draw.ferramentas = function(prop, px, py, w, h, pal)
    framed(px + 5, py + 3, 22, 25, pal.wall.face, pal.wall.cap)
    rect(px + 5, py + 26, 22, 2, pal.wall.faceDark)
    -- Barra de pendurar com pitões: cada peça cai da própria presilha e
    -- deixa a sombra atrás — ferro lê contra pedra antes do cabo.
    rect(px + 7, py + 6, 18, 2, pal.wood.dark)
    rect(px + 7, py + 6, 18, 1, pal.wood.base)
    for _, hx in ipairs({10, 15, 21}) do
        rect(px + hx, py + 8, 2, 2, pal.wall.mortar)
        rect(px + hx, py + 9, 2, 1, P.ink)
    end
    -- Três peças penduradas: pá, picareta, serrote — sombra solta na
    -- chapa, veio nos cabos e o gume claro nos ferros.
    rect(px + 10, py + 9, 3, 15, pal.wall.faceDark, .5)
    rect(px + 9, py + 8, 2, 12, pal.wood.base)
    rect(px + 9, py + 8, 1, 12, pal.wood.light, .6)
    rect(px + 8, py + 20, 4, 5, pal.wall.cap)
    rect(px + 8, py + 24, 4, 1, pal.wall.mortar)
    rect(px + 16, py + 9, 2, 12, pal.wall.faceDark, .5)
    pixelLine(px + 15, py + 8, px + 15, py + 18, pal.wood.base)
    pixelLine(px + 12, py + 9, px + 18, py + 12, pal.wall.cap)
    pixelLine(px + 12, py + 10, px + 18, py + 13, pal.wall.mortar, .7)
    rect(px + 22, py + 10, 3, 14, pal.wall.faceDark, .5)
    rect(px + 21, py + 9, 3, 13, pal.wood.base)
    rect(px + 21, py + 9, 1, 13, pal.wood.light, .5)
    rect(px + 20, py + 10, 5, 3, pal.wall.cap)
    rect(px + 20, py + 10, 5, 1, pal.wall.rim, .7)
end

draw.carteiras = function(prop, px, py, w, h, pal)
    local wood = pal.wood
    rect(px + 2, py + 28, w - 4, 3, P.ink, .2)
    for i = 0, 1 do
        local dx = px + i * (w - 14)
        framed(dx + 1, py + 10, 12, 9, wood.base, wood.light)
        rect(dx + 2, py + 19, 2, 9, P.ink); rect(dx + 10, py + 19, 2, 9, P.ink)
        -- Tampo de aula: veio, a mancha de tinta velha e o fio gasto.
        rect(dx + 3, py + 12, 8, 1, wood.dark)
        rect(dx + 3, py + 15, 6, 1, wood.dark, .4)
        rect(dx + 4 + i * 4, py + 13, 2, 2, P.ink, .45)
        rect(dx + 1, py + 18, 12, 1, wood.dark, .5)
        rect(dx + 3, py + 19, 1, 8, wood.dark, .7)
        rect(dx + 10, py + 19, 1, 8, wood.dark, .7)
    end
end

-- Pilha de carga de uma célula (~26 px): caixa baixa com alça de corda
-- encostada na caixa alta cintada. 'espelhada' troca as posições para a
-- fila de w=2 não repetir a mesma silhueta.
local function pilhaCarga(sx, py, pal, espelhada)
    local wood = pal.wood
    rect(sx + 3, py + 28, 26, 3, P.ink, .22)
    local lx, hx = sx + 3, sx + 16
    if espelhada then lx, hx = sx + 15, sx + 3 end
    -- Caixa baixa: junta cruzada, alça de corda e quinas comidas.
    framed(lx, py + 14, 14, 14, wood.base, wood.light)
    rect(lx, py + 20, 14, 2, wood.dark)
    rect(lx, py + 26, 14, 2, wood.dark, .5)
    rect(lx + 6, py + 15, 1, 12, wood.dark, .5)
    rect(lx + 2, py + 17, 5, 1, wood.dark, .4)
    local ax = espelhada and lx + 9 or lx + 1
    pixelLine(ax, py + 15, ax + 4, py + 15, pal.wall.mortar)
    rect(ax, py + 27, 2, 1, wood.light, .7)
    -- Caixa alta: veios verticais, cinta e a tampa com junta aberta.
    framed(hx, py + 6, 13, 22, wood.dark, wood.base)
    rect(hx, py + 16, 13, 2, pal.wall.mortar)
    rect(hx + 1, py + 7, 11, 1, wood.light)
    for i = 0, 1 do rect(hx + 3 + i * 5, py + 8, 1, 7, wood.base, .45) end
    rect(hx, py + 22, 13, 1, pal.wall.mortar, .8)
    rect(hx + 1, py + 6, 11, 1, P.ink, .5)
    rect(hx + 8, py + 24, 2, 2, wood.base)
    rect(hx + 11, py + 27, 2, 1, pal.moss, .7)
end

draw.caixas = function(prop, px, py, w, h, pal)
    local wood = pal.wood
    -- As pilhas cobrem a largura que o mapa bloqueia (prop.w células, w
    -- já em px): w=1 é a pilha compacta de sempre; w=2 planta duas
    -- pilhas em fila com o feitio espelhado; w≥3 vira engradado corrido
    -- — a célula sólida nunca fica metade vazia (mesmo fix do banco).
    if w <= 48 then
        pilhaCarga(px, py, pal, false)
        return
    end
    if w <= 80 then
        pilhaCarga(px + 1, py, pal, false)
        pilhaCarga(px + w - 30, py, pal, true)
        -- Pedra solta no vão entre as pilhas: o lote veio do depósito.
        rect(round(px + w / 2) - 1, py + 28, 3, 1, pal.wall.mortar, .7)
        return
    end
    -- Corrido: engradado baixo correndo a largura com as caixas altas
    -- assentadas por cima — carga de armazém, não pilha solta.
    rect(px + 3, py + 28, w - 6, 3, P.ink, .22)
    framed(px + 2, py + 15, w - 4, 13, wood.base, wood.light)
    rect(px + 2, py + 21, w - 4, 2, wood.dark)
    rect(px + 3, py + 26, w - 6, 1, wood.dark, .5)
    -- Juntas a cada caixa da fila + alças de corda espaçadas.
    for sx = px + 17, px + w - 8, 15 do
        rect(sx, py + 16, 1, 12, wood.dark, .5)
    end
    for sx = px + 5, px + w - 14, 22 do
        pixelLine(sx, py + 16, sx + 4, py + 16, pal.wall.mortar)
    end
    -- Caixas altas distribuídas sobre o engradado, no mesmo feitio da
    -- pilha: cinta, veios verticais e a fenda da tampa.
    local slots = math.max(1, math.floor((w - 8) / 26))
    for i = 0, slots - 1 do
        local bx = px + 5 + round(i * (w - 23) / math.max(1, slots - 1))
        framed(bx, py + 5, 13, 11, wood.dark, wood.base)
        rect(bx + 1, py + 6, 11, 1, wood.light)
        rect(bx, py + 9, 13, 1, pal.wall.mortar)
        for v = 0, 1 do rect(bx + 3 + v * 5, py + 10, 1, 5, wood.base, .45) end
        rect(bx + 1, py + 5, 11, 1, P.ink, .5)
    end
    rect(px + 6, py + 27, 2, 1, pal.moss, .7)
end

-- Fontes de luz dos props: âncora da chama relativa à área e raio do halo.
-- O halo é desenhado ANTES do prop para a fonte ficar por cima do brilho.
local lightSources = {
    altar = {x = .5, y = .28, r = 15, tint = P.ember},
    fogao = {x = .5, y = .6, r = 14, tint = P.ember},
    mesa = {x = .78, y = .12, r = 10, tint = P.emberLight},
    cisterna = {x = .5, y = .5, r = 22, tint = P.jadeLight},
    lustre = {x = .5, y = .35, r = 12, tint = P.emberLight},
    canal = {x = .5, y = .5, r = 10, tint = P.jadeLight},
    filtroPedra = {x = .5, y = .5, r = 9, tint = P.jadeLight},
    -- Casas por id: o adro guarda um lume na porta; a forja respira mais
    -- forte pela boca de trabalho. Estados frios apagam — menos a brasa
    -- de ofício, que só cai de intensidade (ver emberKeeps).
    capelaCasa = {x = .5, y = .74, r = 13, tint = P.ember},
    forjaCasa = {x = .55, y = .7, r = 19, tint = P.emberLight},
    bigorna = {x = .6, y = .8, r = 10, tint = P.ember},
    braseiro = {x = .5, y = .35, r = 14, tint = P.ember},
    placaRotas = {x = .78, y = .5, r = 14, tint = P.emberLight},
    -- Marco aceso: o anel jade dos nomes vira fonte — 'quiet' apaga como
    -- nas outras, então a pedra só irradia depois de concluída.
    marco = {x = .5, y = .85, r = 18, tint = P.jadeLight},
}

-- Ofícios de fogo vivo: 'covered' (Morada T0) cobre a bancada de pano,
-- não a brasa — a âncora fica, só baixa de intensidade.
local emberKeeps = {forjaCasa = true, bigorna = true}

-- ── Fichas 02/03: objetos de ofício sobre placeholders ─────────────
-- OFICINAS — placa de turnos: quadro pendurado com marcas de serviço.
draw.placa = function(prop, px, py, w, h, pal)
    rect(px + 4, py + 2, w - 8, 16, P.ink)
    framed(px + 5, py + 3, w - 10, 14, pal.wood.base, pal.wood.light)
    for i = 0, math.floor((w - 16) / 6) - 1 do
        rect(px + 8 + i * 6, py + 6, 4, 1, P.ink)
        rect(px + 8 + i * 6, py + 10, i % 2 == 0 and 4 or 2, 1, i % 2 == 0 and P.ink or pal.moss)
    end
    rect(px + 6, py + 4, 2, 2, pal.petal)
end
-- OFICINAS — roda de trabalho: aro com raios sobre eixo, banquinho sob.
draw.roda = function(prop, px, py, w, h, pal)
    local cx, cy = px + w / 2, py + 12
    for j = -7, 7 do
        local half = math.floor(math.sqrt(math.max(0, 49 - j * j)))
        rect(math.floor(cx - half), cy + j, half * 2, 1, P.ink)
        if half > 1 then rect(math.floor(cx - half + 1), cy + j, half * 2 - 2, 1, pal.wood.dark) end
    end
    for i = 0, 3 do
        local a = i * math.pi / 4
        pixelLine(cx, cy, cx + math.cos(a) * 7, cy + math.sin(a) * 7, pal.wood.light)
    end
    rect(cx - 2, cy - 2, 4, 4, pal.wall.mortar); rect(cx - 1, cy - 1, 2, 2, P.ink)
    rect(px + 6, cy + 8, w - 12, 3, pal.wood.base)
    rect(px + 8, cy + 11, 2, 6, pal.wood.dark); rect(px + w - 10, cy + 11, 2, 6, pal.wood.dark)
end
-- OFICINAS — entulho com escora: pilha de pedra + tábua escorada.
local function entulho(prop, px, py, w, h, pal)
    PixelArt.ditherEllipse(px + w / 2, py + 25, w / 2 - 3, 5, P.ink, .7)
    rect(px + 4, py + 18, w - 8, 9, pal.wall.faceDark)
    rect(px + 6, py + 14, w - 14, 6, pal.wall.face)
    rect(px + 10, py + 11, w - 24, 4, pal.wall.brick)
    pixelLine(px + w - 9, py + 22, px + w - 14, py + 2, pal.wood.base)
    pixelLine(px + w - 7, py + 22, px + w - 12, py + 2, pal.wood.dark)
    rect(px + 4, py + 24, 3, 2, pal.moss)
end
draw.caixasEntulho = entulho; draw.caixasEntulho2 = entulho
-- MERCADO — toldo remendado: riscas de pano penduradas no alto da célula.
local function toldo(prop, px, py, w, h, pal, t, reduced)
    for i = 0, math.floor(w / 8) - 1 do
        -- Cada risca desce a beirada na própria fase — brisa lenta de feira.
        local sway = reduced and 0 or round(math.sin(t * 1.8 + (prop.x or 0) * 2.3 + i * 1.1) * 1.5)
        rect(px + i * 8, py + 1, 8, 9 + (i % 2) * 2, i % 2 == 0 and pal.cloth.base or pal.petal)
        rect(px + i * 8, py + 1, 8, 1, P.ink)
        rect(px + i * 8, py + 9 + (i % 2) * 2 + sway, 8, 2, i % 2 == 0 and pal.cloth.light or pal.cloth.dark)
    end
    -- Fio solto na ponta, treme mais rápido que o pano.
    local fx = reduced and 0 or round(math.sin(t * 3.1 + (prop.y or 0) * 1.7) * 1.4)
    rect(px + w - 4 + fx, py + 12, 1, 3, pal.cloth.light)
    rect(px + 1, py - 1, w - 2, 2, pal.wood.dark)
end
draw.toldo = toldo; draw.toldoFeirante = toldo; draw.placaEma = draw.placa
-- MERCADO — carro de peças: carroceria de madeira sobre duas rodas.
draw.carroPecas = function(prop, px, py, w, h, pal)
    rect(px + 2, py + 8, w - 4, 12, P.ink)
    rect(px + 3, py + 9, w - 6, 10, pal.wood.base)
    rect(px + 3, py + 9, w - 6, 2, pal.wood.light)
    for i = 0, math.floor(w / 14) - 1 do rect(px + 5 + i * 14, py + 9, 1, 10, pal.wood.dark) end
    rect(px + 5, py + 4, 8, 5, pal.cloth.dark); rect(px + w - 13, py + 5, 8, 4, pal.petal)
    for _, wx in ipairs({px + 6, px + w - 9}) do
        PixelArt.ditherEllipse(wx, py + 23, 4, 4, P.ink, .9)
        rect(wx - 2, py + 21, 5, 5, pal.wall.mortar); rect(wx - 1, py + 22, 2, 2, P.ink)
    end
    pixelLine(px + 3, py + 21, px + w - 3, py + 21, pal.wood.dark)
end
-- MERCADO — fichário: gavetas empilhadas com puxadores de pedra.
draw.fichario = function(prop, px, py, w, h, pal)
    rect(px + 6, py + 2, w - 12, 26, P.ink)
    rect(px + 7, py + 3, w - 14, 24, pal.wood.base)
    for i = 0, 3 do
        rect(px + 8, py + 4 + i * 6, w - 16, 4, pal.wood.dark)
        rect(px + 8, py + 4 + i * 6, w - 16, 1, pal.wood.light)
        rect(px + w / 2 - 2, py + 5 + i * 6, 4, 1, pal.wall.cap)
    end
    rect(px + 7, py + 3, w - 14, 2, pal.wood.light)
end
-- MERCADO — balcão: laje de madeira larga + frente com juntas.
draw.balcao = function(prop, px, py, w, h, pal)
    rect(px + 1, py + 10, w - 2, 8, P.ink)
    rect(px + 2, py + 11, w - 4, 6, pal.wood.base)
    rect(px + 2, py + 11, w - 4, 1, pal.wood.light)
    for i = 0, math.floor(w / 12) - 1 do rect(px + 4 + i * 12, py + 11, 1, 6, pal.wood.dark) end
    rect(px + 1, py + 18, w - 2, 8, pal.wood.dark)
    rect(px + 1, py + 18, w - 2, 1, pal.wood.base)
end
-- MERCADO — banca de feira: mesa de tábuas + mercadoria acima.
local function banca(prop, px, py, w, h, pal)
    rect(px + 2, py + 14, w - 4, 12, P.ink)
    rect(px + 3, py + 15, w - 6, 10, pal.wood.base)
    rect(px + 3, py + 15, w - 6, 1, pal.wood.light)
    rect(px + 5, py + 19, w - 10, 1, pal.wood.dark)
    rect(px + 6, py + 10, 7, 4, pal.petal)
    rect(px + w - 14, py + 9, 8, 5, pal.cloth.base)
    rect(px + 7, py + 9, 4, 1, P.ink)
end
draw.bancaCasal = banca; draw.bancaFeirante = banca
-- OFICINAS — marca de autoria: placa pequena pregada com selo costurado.
draw.marcaBrina = function(prop, px, py, w, h, pal)
    rect(px + 9, py + 8, 14, 12, P.ink)
    framed(px + 10, py + 9, 12, 10, pal.cloth.base, pal.cloth.light)
    pixelLine(px + 12, py + 12, px + 20, py + 16, P.ink)
    pixelLine(px + 20, py + 12, px + 12, py + 16, P.ink)
    rect(px + 15, py + 13, 2, 2, pal.petal)
end
-- RESERVATÓRIO/SALÕES (M4/M5 em produção): kinds genéricos já pintados —
-- quando os ids chegarem, o kind certo já resolve sem placeholder.
draw.volante = function(prop, px, py, w, h, pal)
    local cx, cy = px + w / 2, py + 14
    for j = -6, 6 do
        local half = math.floor(math.sqrt(math.max(0, 36 - j * j)))
        rect(math.floor(cx - half), cy + j, half * 2, 1, P.ink)
        if half > 1 then rect(math.floor(cx - half + 1), cy + j, half * 2 - 2, 1, pal.wall.brick) end
    end
    pixelLine(cx - 6, cy, cx + 6, cy, pal.wall.cap); pixelLine(cx, cy - 6, cx, cy + 6, pal.wall.cap)
    rect(cx - 1, cy - 1, 2, 2, pal.wall.rim)
    rect(cx - 2, cy + 7, 4, 8, pal.wall.faceDark)
end
draw.regua = function(prop, px, py, w, h, pal)
    local cx = px + math.floor(w / 2)
    rect(cx - 3, py + 2, 6, h - 6, P.ink)
    rect(cx - 2, py + 3, 4, h - 8, pal.wood.light)
    for i = 0, math.floor((h - 10) / 4) do
        rect(cx - 2, py + 4 + i * 4, i % 2 == 0 and 6 or 4, 1, P.ink)
    end
    rect(cx - 5, py + h - 6, 10, 3, pal.wall.faceDark)
end
draw.instrumento = function(prop, px, py, w, h, pal)
    PixelArt.ditherEllipse(px + w / 2, py + 25, w / 3, 4, P.ink, .7)
    for j = -4, 4 do
        local half = math.floor(math.sqrt(math.max(0, 16 - j * j)))
        rect(px + 15 - half, py + 17 + j, half * 2, 1, pal.wood.base)
    end
    rect(px + 14, py + 13, 3, 8, pal.wood.dark)
    pixelLine(px + 15, py + 12, px + 17, py - 6, pal.wood.base)
    rect(px + 16, py - 6, 3, 3, pal.wood.dark)
    pixelLine(px + 16, py + 8, px + 17, py - 4, P.ink)
end
draw.cortina = function(prop, px, py, w, h, pal, t, reduced)
    for i = 0, math.floor(w / 6) - 1 do
        -- Barras da cortina respiram devagar: cada coluna desce na sua fase.
        local sway = reduced and 0 or round(math.sin(t * 1.2 + (prop.x or 0) * 1.3 + i * 1.7) * 1.5)
        rect(px + i * 6, py - 2, 6, h - 2 - (i % 3) * 3 + sway,
            i % 2 == 0 and pal.cloth.base or pal.cloth.dark)
        rect(px + i * 6, py - 2, 6, 1, P.ink)
    end
    rect(px + w / 2 - 1, py + 8, 2, h - 12, pal.petal)
end
draw.lustre = function(prop, px, py, w, h, pal, t, reduced)
    pixelLine(px + w / 2, py, px + w / 2, py + 6, pal.wall.mortar)
    rect(px + w / 2 - 8, py + 6, 16, 2, pal.wall.mortar)
    for i = -1, 1 do
        -- Cada vela treme na própria fase: altura e calor da chama.
        local fl = reduced and .5 or .5 + .5 * math.sin(t * 8.9 + i * 2.4 + (prop.x or 0) * 1.7)
        local fh = 5 + (fl > .66 and 1 or 0)
        rect(px + w / 2 + i * 6 - 1, py + 13 - fh, 2, fh, P.emberLight, .75 + .25 * fl)
        rect(px + w / 2 + i * 6 - 1, py + 6, 2, 2, pal.petal)
        rect(px + w / 2 + i * 6, py + 14 - fh, 1, 1, P.goldLight, .5 + .5 * fl)
    end
    rect(px + w / 2 - 3, py + 13, 6, 2, pal.wood.dark)
end
draw.divisoria = function(prop, px, py, w, h, pal)
    -- Biombo entre as camas (doc §31 — "quartos recebem divisórias"):
    -- moldura de tábua com pano esticado, pespontos à vista e um remendo
    -- de outro pano — privacidade conquistada com o que havia.
    local wood, cloth = pal.wood, pal.cloth
    -- Pés e travessa da moldura.
    rect(px + 2, py, 3, h, wood.dark)
    rect(px + w - 5, py, 3, h, wood.dark)
    rect(px + 2, py, 3, 1, wood.light); rect(px + w - 5, py, 3, 1, wood.light)
    rect(px + 2, py + 2, w - 4, 2, wood.base)
    rect(px + 2, py + 2, w - 4, 1, wood.light)
    rect(px + 2, py + h - 4, w - 4, 3, wood.base)
    rect(px + 2, py + h - 4, w - 4, 1, wood.light, .6)
    -- Pano esticado: fio escuro na beirada direita dá o volume do tecido.
    rect(px + 5, py + 4, w - 10, h - 8, P.ink)
    rect(px + 5, py + 4, w - 11, h - 9, cloth.base)
    rect(px + 5, py + 4, w - 11, 1, cloth.light)
    -- Pespontos verticais e a barra de baixo mais pesada.
    for i = 0, math.floor((w - 12) / 7) - 1 do
        rect(px + 8 + i * 7, py + 6, 1, h - 13, cloth.dark, .6)
    end
    rect(px + 5, py + h - 8, w - 11, 2, cloth.dark)
    rect(px + 6, py + h - 7, w - 13, 1, cloth.light, .5)
    -- Remendo costurado: retalho claro com a borda de ponto marcada.
    rect(px + w - 13, py + 9, 7, 6, cloth.light)
    rect(px + w - 13, py + 9, 7, 1, P.ink, .5); rect(px + w - 13, py + 14, 7, 1, P.ink, .5)
    rect(px + w - 13, py + 9, 1, 6, P.ink, .5); rect(px + w - 7, py + 9, 1, 6, P.ink, .5)
end

-- Variante entreaberta (id próprio plantado pelo Pátio): o pano recolhido
-- contra a moldura direita deixa a fresta livre — a privacidade da pensão
-- também se abre, não é parede (doc §115 — "alguém pode conquistá-la").
draw.divisoriaAberta = function(prop, px, py, w, h, pal)
    local wood, cloth = pal.wood, pal.cloth
    rect(px + 2, py, 3, h, wood.dark)
    rect(px + w - 5, py, 3, h, wood.dark)
    rect(px + 2, py, 3, 1, wood.light); rect(px + w - 5, py, 3, 1, wood.light)
    rect(px + 2, py + 2, w - 4, 2, wood.base)
    rect(px + 2, py + 2, w - 4, 1, wood.light)
    rect(px + 2, py + h - 4, w - 4, 3, wood.base)
    rect(px + 2, py + h - 4, w - 4, 1, wood.light, .6)
    -- Vão aberto: a fresta mostra o piso e a sombra da cama vizinha.
    rect(px + 5, py + 4, w - 16, h - 8, P.ink)
    rect(px + 6, py + 4, w - 18, h - 9, pal.floor.shadow)
    rect(px + 6, py + h - 7, w - 18, 2, pal.floor.dark)
    -- Pano franzido contra a ombreira direita: dobras apertadas leem o
    -- recolhido; o fio da ponta balança livre.
    rect(px + w - 12, py + 4, 7, h - 8, P.ink)
    rect(px + w - 11, py + 4, 6, h - 9, cloth.base)
    rect(px + w - 11, py + 4, 6, 1, cloth.light)
    for i = 0, 1 do rect(px + w - 10 + i * 3, py + 6, 1, h - 13, cloth.dark, .7) end
    rect(px + w - 11, py + h - 8, 6, 2, cloth.dark)
    -- Atacador segurando o feixe no meio.
    rect(px + w - 12, py + 14, 8, 2, pal.petal)
    rect(px + w - 12, py + 14, 8, 1, P.ink, .5)
end
draw.canal = function(prop, px, py, w, h, pal, t, reduced)
    rect(px, py + 6, w, h - 10, P.ink)
    rect(px + 1, py + 7, w - 2, h - 12, pal.cloth.dark)
    rect(px + 1, py + 7, w - 2, 2, pal.cloth.base)
    -- Fitas de luz escorrem na correnteza — paradas com movimento reduzido.
    for i = 0, math.floor(w / 20) - 1 do
        local slide = reduced and i * 20
            or (i * 20 + t * 7 + (prop.x or 0) * 3) % math.max(6, w - 14)
        rect(px + 3 + slide, py + 13 + (i % 2) * 3, 9, 1, pal.cloth.light, .85)
    end
    rect(px, py + 5, w, 2, pal.moss)
end
draw.escora = entulho

-- ── Fichas 04/05: ids plantados pelo Pátio sobre kinds placeholder ──
-- RESERVATÓRIO — comporta: portão de tábuas com ferragem e dobradiça.
local function comporta(prop, px, py, w, h, pal, t, reduced)
    rect(px + 1, py, w - 2, h, P.ink)
    for i = 0, math.floor(w / 9) - 1 do
        rect(px + 2 + i * 9, py + 1, 8, h - 2, pal.wood.base)
        rect(px + 2 + i * 9, py + 1, 8, 1, pal.wood.light)
    end
    for i = 0, math.floor(h / 10) do
        rect(px + 1, py + 2 + i * 10, w - 2, 3, pal.wall.mortar)
        rect(px + 1, py + 2 + i * 10, w - 2, 1, pal.wall.cap)
    end
    for i = 0, math.floor(w / 9) - 1 do
        rect(px + 4 + i * 9, py + 3, 2, 2, P.ink)
        rect(px + 4 + i * 9, py + h - 8, 2, 2, P.ink)
    end
    rect(px + w / 2 - 1, py, 2, h, pal.wall.cap)
    -- Gotas escorrem da ferragem: duas trilhas curtas em fases próprias.
    for i = 0, 1 do
        local dx = px + 6 + i * math.max(6, math.floor(w / 2))
        local dy = reduced and py + 4 + i * 9
            or py + 3 + math.floor((t * 11 + i * 13 + (prop.x or 0) * 5) % math.max(6, h - 8))
        rect(dx, dy, 1, 2, pal.cloth.light, .7)
    end
end
draw.gradeComporta = comporta; draw.comportaPortao = comporta
-- RESERVATÓRIO — filtro de pedra: tambor poroso em base de ferragem.
draw.filtroPedra = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 5, py + 18, w - 10, 8, pal.wall.faceDark)
    rect(px + 5, py + 18, w - 10, 1, pal.wall.cap)
    for j = 0, h - 15 do
        local half = math.floor(math.sqrt(math.max(0, 64 - (j - 7) * (j - 7))))
        rect(px + w / 2 - math.min(half, 9), py + 2 + j, math.min(half, 9) * 2, 1, pal.wall.brick)
    end
    PixelArt.dither(px + w / 2 - 6, py + 6, 12, 10, pal.wall.mortar, .5)
    rect(px + w / 2 - 1, py, 2, 3, pal.wall.cap)
    -- Brilho de água desce pelo tambor poroso, uma gota de cada vez.
    local glisten = reduced and py + 12
        or py + 6 + math.floor((t * 5 + (prop.y or 0) * 7) % 9)
    rect(px + w / 2 - 5, py + 8, 2, 2, pal.cloth.light)
    rect(px + w / 2 + 4, glisten, 2, 1, pal.cloth.light, .8)
end
-- RESERVATÓRIO — canteiro: faixa de terra com mudas em fileiras.
local function canteiro(prop, px, py, w, h, pal)
    rect(px, py + 8, w, h - 10, P.ink)
    rect(px + 1, py + 9, w - 2, h - 12, pal.floor.shadow)
    rect(px + 1, py + 9, w - 2, 2, pal.floor.dark)
    for i = 0, math.floor(w / 16) - 1 do
        local sx = px + 7 + i * 16
        rect(sx, py + 13, 2, 5, pal.moss)
        rect(sx - 1, py + 14, 1, 2, pal.moss); rect(sx + 2, py + 14, 1, 2, pal.moss)
        if i % 3 == 1 then rect(sx, py + 12, 2, 2, pal.petal) end
    end
    for i = 0, math.floor(w / 10) - 1 do
        rect(px + 4 + i * 10, py + 22, 2, 2, pal.floor.dark)
    end
end
draw.canteiroA = canteiro; draw.canteiroB = canteiro
-- SALÕES — cadeira reservada: encosto alto + faixa de reserva.
draw.cadeiraReservada = function(prop, px, py, w, h, pal)
    rect(px + 11, py + 2, 10, 12, P.ink)
    framed(px + 12, py + 3, 8, 10, pal.wood.base, pal.wood.light)
    rect(px + 13, py + 5, 6, 2, pal.cloth.base)
    rect(px + 10, py + 14, 12, 6, pal.wood.dark)
    rect(px + 10, py + 14, 12, 2, pal.wood.base)
    rect(px + 11, py + 20, 2, 8, pal.wood.dark); rect(px + 19, py + 20, 2, 8, pal.wood.dark)
    pixelLine(px + 12, py + 24, px + 20, py + 24, pal.wood.dark)
end
-- SALÕES — cartaz de ensaio: papel pregado com título e pauta.
draw.cartaz = function(prop, px, py, w, h, pal)
    rect(px + 9, py + 3, 14, 20, P.ink)
    rect(px + 10, py + 4, 12, 18, pal.cloth.light)
    rect(px + 11, py + 6, 10, 3, pal.cloth.base)
    for i = 0, 3 do rect(px + 12, py + 12 + i * 3, 8, 1, P.ink) end
    rect(px + 15, py + 12, 1, 7, pal.petal)
    rect(px + 10, py + 4, 2, 2, pal.petal)
end
-- SALÕES — cabides: vara suspensa com ganchos e panos.
draw.cabides = function(prop, px, py, w, h, pal)
    pixelLine(px + 4, py + 6, px + w - 4, py + 6, pal.wood.base)
    rect(px + 2, py + 5, 2, 8, pal.wood.dark); rect(px + w - 4, py + 5, 2, 8, pal.wood.dark)
    for i = 0, 2 do
        local hx = px + 7 + i * 8
        pixelLine(hx, py + 6, hx + 2, py + 9, pal.wall.cap)
        pixelLine(hx + 2, py + 9, hx - 3, py + 13, pal.wall.cap)
        rect(hx - 4, py + 13, 8, 9 + (i % 2) * 3, i == 1 and pal.cloth.base or pal.cloth.dark)
    end
end
-- SALÕES — armário técnico: alto, portas com vãos de ventilação.
draw.armarioTecnico = function(prop, px, py, w, h, pal)
    rect(px + 5, py + 1, w - 10, 27, P.ink)
    rect(px + 6, py + 2, w - 12, 25, pal.wood.dark)
    rect(px + 6, py + 2, w - 12, 2, pal.wood.base)
    rect(px + w / 2 - 1, py + 4, 2, 21, P.ink)
    for i = 0, 2 do
        rect(px + 9, py + 6 + i * 6, 5, 1, pal.wood.light)
        rect(px + w - 14, py + 6 + i * 6, 5, 1, pal.wood.light)
    end
    rect(px + w / 2 - 4, py + 13, 2, 2, pal.wall.cap); rect(px + w / 2 + 2, py + 13, 2, 2, pal.wall.cap)
end
-- SALÕES — vitrine: a região se chama Salões das Vitrines — mostruário de
-- pedestal com vidro entelhado e o relíquio dentro, filete dourado.
local function vitrine(prop, px, py, w, h, pal)
    PixelArt.ditherEllipse(px + w / 2, py + 26, w / 2 - 2, 5, P.ink, .7)
    rect(px + 3, py + 20, w - 6, 8, pal.wall.faceDark)
    rect(px + 3, py + 20, w - 6, 2, pal.wall.rim)
    rect(px + 4, py + 2, w - 8, 18, P.ink)
    rect(px + 5, py + 3, w - 10, 16, pal.cloth.dark)
    rect(px + 5, py + 3, w - 10, 1, pal.petal)
    rect(px + 5, py + 3, 1, 16, pal.petal); rect(px + w - 6, py + 3, 1, 16, pal.petal)
    -- Relíquia no centro: cuia votiva sobre poeira de ouro.
    rect(px + w / 2 - 4, py + 12, 8, 5, pal.petal)
    rect(px + w / 2 - 3, py + 10, 6, 3, P.emberLight)
    rect(px + w / 2 - 1, py + 8, 2, 2, pal.cloth.light)
    PixelArt.dither(px + 6, py + 4, w - 12, 4, pal.cloth.light, .25)
    rect(px + 6, py + 5, 2, 10, pal.cloth.light, .5)
end
draw.vitrineA = vitrine; draw.vitrineB = vitrine
-- RESERVATÓRIO — bomba/tubo da comporta: junção com flange e juntas.
local function tubo(prop, px, py, w, h, pal)
    rect(px + 4, py + 10, w - 8, 10, P.ink)
    rect(px + 5, py + 11, w - 10, 8, pal.wall.brick)
    rect(px + 5, py + 11, w - 10, 1, pal.wall.cap)
    rect(px + 8, py + 8, 4, 14, pal.wall.mortar)
    rect(px + 8, py + 8, 4, 1, pal.wall.cap)
    rect(px + 7, py + 13, 6, 3, pal.wall.brickAlt)
    for i = 0, 2 do rect(px + 8 + i * 2, py + 14, 1, 1, P.ink) end
    PixelArt.dither(px + 12, py + 12, w - 16, 6, pal.cloth.dark, .3)
end
draw.tuboDeposito = tubo; draw.tuboCanal = tubo; draw.bombaComporta = tubo
-- SALÕES — tablado: plataforma de tábuas com saia ornamentada (opcional).
draw.palco = function(prop, px, py, w, h, pal)
    rect(px, py + 14, w, h - 14, P.ink)
    for i = 0, math.floor(w / 12) - 1 do
        rect(px + i * 12, py + 15, 11, h - 16, i % 2 == 0 and pal.floor.base or pal.floor.dark)
        rect(px + i * 12, py + 15, 11, 1, pal.floor.light)
    end
    for i = 0, math.floor(w / 14) - 1 do
        rect(px + 4 + i * 14, py + h - 6, 6, 3, pal.petal)
    end
end

-- Âncora de luz em coordenadas de mundo para quem precisa (motes, brilho).
-- Corpo compartilhado das casas do Refúgio: massa, telhado empena, porta e
-- janelas por esquema. As fichas de ofício só trocam material, esquema de
-- janelas e acrescentam o próprio sinal (cruz, chaminé, brasa, placa).
-- Opções em `o`: wall, wallLight, side (face leste cega), roof, roofLight,
-- roofDark, roofShade (encosta leste), roofDeep (verso do beiral),
-- roofFrac, doorFrac, eave (beiral além da parede), courses (passo das
-- fiadas do telhado — ardósia densa usa 6), annexW (ala de tábua na ponta
-- direita), windowsLayout (lista de {dx,dy,w,h} sob a parede),
-- doorGlow (brasa no vão), extras = fn(prop,x,y,w,h,pal,info).
local function casaBody(prop, x, y, w, h, pal, o)
    o = o or {}
    local c = Palettes.refuge
    local t, reduced = o.time or 0, o.reduced
    local wall, wallLight = o.wall or c.plaster, o.wallLight or c.plasterLight
    -- A luz regional vem do alto à esquerda: a face leste cai dois degraus
    -- no próprio material e a sombra deita a sueste no chão.
    local side = o.side or c.plasterDark
    local roof, roofLight = o.roof or c.roof, o.roofLight or c.roofLight
    local roofDark = o.roofDark or c.roofDark
    local roofDeep = o.roofDeep or c.roofDeep    -- verso do beiral, o mais fundo
    local roofShade = o.roofShade or c.roofShade -- encosta leste, meio-degrau
    local roofH = round(h * (o.roofFrac or .56))
    local eave = o.eave or 0
    local sideW = math.max(13, round(w * .16))

    -- Sombra projetada no chão: a massa alta corta a luz do alto-esquerda
    -- e a fachada deita seu perfil a sueste — banda inclinada saindo da
    -- base sul, alargando para o lado cego e afrouxando com a distância.
    for d = 0, 20 do
        rect(x + 8 + d, y + h - 3 + round(d * .55), w - 14 + round(d * 1.2), 3,
            Palettes.ink, math.max(.04, .21 - d * .0085))
    end
    rect(x + 8, y + h - 4, w - 4, 10, Palettes.ink, .23)

    -- Massa da parede: face sul tomando luz, face leste cega dois degraus
    -- abaixo, quina de tinta entre elas e saia encostada no chão.
    framed(x + 4, y + roofH, w - 8, h - roofH, wall, wallLight)
    rect(x + w - 4 - sideW, y + roofH + 1, sideW, h - roofH - 2, side)
    rect(x + w - 4 - sideW, y + roofH + 1, 2, h - roofH - 2, Palettes.ink, .5)
    rect(x + 5, y + roofH + 1, 1, h - roofH - 2, wallLight, .45)
    for jy = y + roofH + 15, y + h - 15, 14 do
        rect(x + 8, jy, w - 16 - sideW, 1, wallLight, .28)
    end
    rect(x + 5, y + h - 4, w - 10, 3, side, .4)

    -- Empena lida de cima: cumeeira com capitel, água norte em luz, água
    -- leste meio-degrau abaixo e verso do beiral projetando sombra no
    -- alto da fachada — o `eave` alarga a base além da parede.
    for sy = 0, roofH do
        local inset = round((roofH - sy) * .38) - eave
        rect(x + inset, y + sy, w - inset * 2, 1, sy < roofH / 2 and roofLight or roof)
    end
    for sy = 2, roofH - 1 do
        local inset = round((roofH - sy) * .38) - eave
        rect(x + w - inset - 9, y + sy, 9, 1, roofShade, .8)
        rect(x + w - inset - 11, y + sy, 2, 1, roofDeep, .75)
    end
    local step = o.courses or 10
    for sy = step, roofH - 2, step do
        local inset = round((roofH - sy) * .38) - eave
        rect(x + inset, y + sy, w - inset * 2 - 9, 1, roofDark, .6)
        for sx = inset + 11 + (sy % (step * 2)), w - inset - 5, 23 do
            rect(x + sx, y + sy - step + 2, 1, step - 3, roofDark, .35)
        end
    end
    -- Cumeeira: a dobra do telhado tem espessura própria — filete claro
    -- sobre linha de sombra, não uma aresta de cor só.
    local ridgeInset = round(roofH * .38) - eave
    rect(x + ridgeInset - 1, y - 2, w - ridgeInset * 2 + 2, 2, roofLight)
    rect(x + ridgeInset - 1, y, w - ridgeInset * 2 + 2, 1, roofDark, .4)
    -- Beiral: massa escura do verso além da parede + a sombra que ele
    -- deita no topo da fachada (dois fios: o duro junto e o esfumado abaixo).
    rect(x + 3 - eave, y + roofH - 1, w - 6 + eave * 2, 4, roofDeep)
    rect(x + 3 - eave, y + roofH - 1, w - 6 + eave * 2, 1, roofLight)
    rect(x + 5, y + roofH + 3, w - 10, 3, Palettes.ink, .24)
    rect(x + 5, y + roofH + 6, w - 10, 2, Palettes.ink, .12)
    -- Porta: vão escuro, folha de madeira e soleira de pedra. O lado vem
    -- de prop.doorSide ('south' default): 'north' abre para a rua de
    -- cima — lê-se o recesso alto no topo da parede, coberto por uma
    -- saia do telhado; 'west'/'east' põem o batente estreito na quina da
    -- lateral com um degrau saltando para a rua. Sem rotacionar a massa:
    -- o batente respeita o lado declarado, o resto da ficha fica.
    local doorX = x + round(w * (o.doorFrac or .5)) - 11
    local doorH = h - roofH - 10
    local dside = prop.doorSide or 'south'
    local function vaoGlow(gx, gy, gw, gh)
        -- Brasa escapando pelo vão: respira devagar, nunca apaga de vez.
        -- 'dim' cobre a casa dormida — a brasa fica em meio-tom, não some.
        if not o.doorGlow then return end
        local dim = o.doorGlow == 'dim' and .55 or 1
        local fl = reduced and .7 or .55 + .45 * math.sin(t * 6.1 + x * .13)
        rect(gx, gy, gw, gh, Palettes.ember, (.3 + .35 * fl) * dim)
        rect(gx + 3, gy + 5, math.max(3, gw - 6), 4, Palettes.emberLight,
            (.45 + .5 * fl) * dim)
    end
    if dside == 'north' then
        -- Recesso alto sob a coberta: a porta fica na rua de cima; da
        -- frente lê-se o vão escuro entalhado no alto da parede, com a
        -- saia do telhado descendo sobre ele e a pedra do peitoril.
        framed(doorX - 3, y + roofH + 4, 28, 21, pal.wood.base, pal.wood.light)
        rect(doorX, y + roofH + 5, 22, 18, Palettes.ink)
        rect(doorX + 4, y + roofH + 7, 13, 14, pal.wood.dark)
        vaoGlow(doorX + 5, y + roofH + 11, 12, 8)
        rect(doorX - 9, y + roofH - 5, 39, 4, roofDeep)
        rect(doorX - 9, y + roofH - 5, 39, 1, roofLight)
        rect(doorX - 5, y + roofH + 26, 31, 3, pal.wall.rim)
    elseif dside == 'west' or dside == 'east' then
        -- Batente lateral: vão estreito de folha única. A oeste fica de
        -- perfil na borda esquerda (a face oeste não se mostra); a leste
        -- abre dentro da faixa cega. O degrau salta para o lado da rua.
        local dh = math.max(6, h - roofH - 16)
        local fx = dside == 'west' and (x - 1) or (x + w - 4 - sideW + 3)
        framed(fx, y + roofH + 8, 15, dh + 4, pal.wood.base, pal.wood.light)
        rect(fx + 3, y + roofH + 9, 9, dh, Palettes.ink)
        rect(fx + 4, y + roofH + 11, 6, dh - 2, pal.wood.dark)
        vaoGlow(fx + 4, y + roofH + 15, 6, math.max(3, dh - 7))
        local stepX = dside == 'west' and (fx - 8) or (fx + 1)
        rect(stepX, y + h - 4, dside == 'west' and 11 or 19, 3, pal.wall.rim)
        rect(stepX, y + h - 1, dside == 'west' and 11 or 19, 2, side, .8)
    else
        framed(doorX - 3, y + roofH + 7, 28, doorH + 3, pal.wood.base, pal.wood.light)
        rect(doorX, y + roofH + 8, 22, doorH, Palettes.ink)
        rect(doorX + 4, y + roofH + 10, 13, doorH - 2, pal.wood.dark)
        vaoGlow(doorX + 5, y + roofH + 14, 12, doorH - 6)
        rect(doorX - 6, y + h - 3, 33, 3, pal.wall.rim)
    end
    -- Janelas: vidro quente quando a casa está acordada; 'quiet'/'covered'
    -- apaga os vidros MENOS um — uma janelinha fraca (a casa dorme, não
    -- morre): emberLight .3-.45 na primeira abertura da fachada.
    local lit = prop.state ~= 'quiet' and prop.state ~= 'covered'
    local function window(wx, wy, ww, wh, dim)
        framed(wx, wy, ww, wh, pal.wood.dark, pal.wood.light)
        if lit then
            rect(wx + 3, wy + 3, ww - 6, wh - 6, Palettes.emberLight, .72)
        elseif dim then
            rect(wx + 3, wy + 3, ww - 6, wh - 6, Palettes.emberLight, .4)
        else
            rect(wx + 3, wy + 3, ww - 6, wh - 6, pal.wood.dark)
        end
        rect(wx + round(ww / 2) - 1, wy + 2, 2, wh - 4, pal.wood.dark)
        rect(wx + 3, wy + round(wh / 2), ww - 6, 2, pal.wood.dark)
        rect(wx - 2, wy + wh, ww + 4, 3, pal.wall.cap)
    end
    for wi, win in ipairs(o.windowsLayout or {{18, 10, 25, 21}, {w - 46, 10, 25, 21}}) do
        window(x + win[1], y + roofH + win[2], win[3], win[4], not lit and wi == 1)
    end
    if o.extras then
        o.extras(prop, x, y, w, h, pal,
            {roofH = roofH, doorX = doorX, doorH = doorH, lit = lit,
                time = t, reduced = reduced})
    end
    if o.annexW then
        -- Ala de serviço em tábua na ponta direita: telhado baixo, veios
        -- verticais e portinhola — a massa anexa quebra o mesmo molde.
        local ax = x + w - o.annexW
        local atop = y + roofH - 5
        rect(ax, atop, o.annexW + 1, y + h - atop - 2, Palettes.ink)
        rect(ax + 1, atop + 1, o.annexW - 1, y + h - atop - 5, pal.wood.base)
        for j = ax + 5, ax + o.annexW - 4, 8 do
            rect(j, atop + 2, 1, y + h - atop - 8, pal.wood.dark)
        end
        rect(ax - 1, atop - 4, o.annexW + 2, 4, roofDark)
        rect(ax - 1, atop, o.annexW + 2, 1, roofLight, .6)
        rect(ax + 4, y + h - 25, 11, 19, Palettes.ink)
        rect(ax + 5, y + h - 24, 9, 17, pal.wood.dark)
        rect(ax + o.annexW - 18, atop + 12, 10, 10, Palettes.ink)
        rect(ax + o.annexW - 17, atop + 13, 8, 8, lit and Palettes.emberLight or pal.wood.dark)
    end
end

-- Casa genérica: ficha de fallback para kinds sem painter próprio.
draw.casa = function(prop, x, y, w, h, pal, time, reduced)
    casaBody(prop, x, y, w, h, pal, {time = time, reduced = reduced})
end
-- Apelidos de ficha: ids de planta que o Pátio pode replantar sobre a
-- mesma massa sem painter novo (id vence kind no dispatch de Props.draw).
draw.residencia = draw.casa
draw.casaMoradia = draw.casa

-- Capela: pedra da alvenaria da região, campanário com vão de sino e a
-- cruz — janelas estreitas de adro em vez das janelas domésticas.
draw.capelaCasa = function(prop, x, y, w, h, pal, t, reduced)
    casaBody(prop, x, y, w, h, pal, {
        wall = pal.wall.face, wallLight = pal.wall.cap,
        side = pal.wall.faceDark,
        -- Ardósia de pedra: a laje ganha cursos densos desencontrados.
        roof = pal.wall.face, roofLight = pal.wall.cap,
        roofDark = pal.wall.faceDark, roofDeep = pal.wall.mortar,
        courses = 6,
        windowsLayout = {{24, 12, 9, 26}, {w - 33, 12, 9, 26}},
        time = t, reduced = reduced,
        extras = function(_, x_, y_, w_, h_, pal_)
            local tx = x_ + round(w_ / 2)
            framed(tx - 8, y_ - 20, 16, 30, pal_.wall.face, pal_.wall.cap)
            rect(tx - 8, y_ - 20, 16, 2, pal_.wall.cap)
            -- Vão do sino: abertura escura com o bronze dentro.
            rect(tx - 4, y_ - 15, 8, 11, Palettes.ink)
            rect(tx - 2, y_ - 12, 4, 5, Palettes.gold.base)
            rect(tx - 1, y_ - 11, 2, 3, Palettes.gold.light)
            -- A cruz coroa a torre, filo de luz no alto.
            rect(tx - 2, y_ - 30, 3, 11, Palettes.gold.base)
            rect(tx - 6, y_ - 26, 11, 3, Palettes.gold.base)
            rect(tx - 1, y_ - 29, 1, 2, Palettes.gold.light)
        end,
    })
end

-- Casa das Camas: pensão comprida em madeira — entrada deslocada, fileira
-- de três janelinhas dos quartos e vigas aparentes na fachada.
draw.camasCasa = function(prop, x, y, w, h, pal, t, reduced)
    casaBody(prop, x, y, w, h, pal, {
        wall = pal.wood.base, wallLight = pal.wood.light,
        side = pal.wood.dark,
        roofFrac = .5, doorFrac = .3, annexW = 46,
        windowsLayout = {{w - 112, 14, 17, 15}, {w - 88, 14, 17, 15},
            {w - 64, 14, 17, 15}},
        time = t, reduced = reduced,
        extras = function(_, x_, y_, w_, h_, pal_, info)
            -- Vigas horizontais: a fachada lê-se como estrutura de madeira.
            rect(x_ + 6, y_ + info.roofH + 1, w_ - 12, 2, pal_.wood.dark, .5)
            for by = y_ + info.roofH + 14, y_ + h_ - 12, 13 do
                rect(x_ + 6, by, w_ - 12, 1, pal_.wood.dark, .4)
            end
        end,
    })
end
-- A pensão é a mesma massa da Casa das Camas: o id alternativo resolve
-- o painter sem duplicar a ficha.
draw.pensaoCasa = draw.camasCasa

-- Escola: o reboco mais claro do povoado, quadro negro pregado junto à
-- porta e um banquinho de espera assado na fachada.
draw.escolaCasa = function(prop, x, y, w, h, pal, t, reduced)
    casaBody(prop, x, y, w, h, pal, {
        wall = Palettes.refuge.plasterLight, wallLight = Palettes.white,
        side = Palettes.refuge.plasterShade,
        roofFrac = .66,   -- empena mais empinada que as demais casas
        time = t, reduced = reduced,
        extras = function(_, x_, y_, w_, h_, pal_, info)
            local bx = info.doorX - 24
            framed(bx, y_ + info.roofH + 14, 17, 13, pal_.wood.dark, pal_.wood.light)
            rect(bx + 3, y_ + info.roofH + 17, 11, 7, pal_.cloth.dark)
            rect(bx + 4, y_ + info.roofH + 18, 7, 1, pal_.cloth.light, .8)
            rect(bx + 4, y_ + info.roofH + 20, 4, 1, pal_.cloth.light, .5)
            -- Banquinho sob o quadro: tábua clara sobre dois pés.
            rect(bx - 1, y_ + h_ - 14, 21, 4, pal_.wood.base)
            rect(bx - 1, y_ + h_ - 14, 21, 1, pal_.wood.light)
            rect(bx + 2, y_ + h_ - 10, 3, 6, pal_.wood.dark)
            rect(bx + 15, y_ + h_ - 10, 3, 6, pal_.wood.dark)
        end,
    })
end

-- Cozinha: chaminé com fumaça quando a água corre e caixilho de ervas
-- pendurado sob a janela — a casa que trabalha se vê pela saída de ar.
draw.cozinhaCasa = function(prop, x, y, w, h, pal, t, reduced)
    casaBody(prop, x, y, w, h, pal, {
        eave = 3,   -- beiral fundo: a cozinha sombreia a horta ao lado
        time = t, reduced = reduced,
        extras = function(prop_, x_, y_, w_, h_, pal_, info)
            local c = Palettes.refuge
            framed(x_ + w_ - 40, y_ - 9, 19, 31, pal_.wall.face, pal_.wall.rim)
            rect(x_ + w_ - 43, y_ - 11, 25, 5, pal_.wall.cap)
            -- A cozinha fumega sempre um fio (fogão de lenha nunca esfria);
            -- 'lit' abre o fumo cheio do preparo.
            local puffs = prop_.state == 'lit' and 4 or 2
            for i = 1, puffs do
                local rise = info.reduced and (i * 8)
                    or (info.time * (prop_.state == 'lit' and 9 or 5) + i * 9) % 38
                local sway = info.reduced and 0 or round(math.sin(info.time + i) * 4)
                rect(x_ + w_ - 34 + sway, y_ - 13 - rise, 5 + i, 4,
                    c.plasterLight, math.max(.04, (prop_.state == 'lit' and .24 or .12) * (1 - rise / 44)))
            end
            -- Caixilho de ervas: caixa suspensa com tufos verdes saindo.
            local bx = x_ + 18
            framed(bx - 1, y_ + info.roofH + 35, 27, 9, pal_.wood.dark, pal_.wood.base)
            for i = 0, 4 do
                rect(bx + 1 + i * 5, y_ + info.roofH + 31, 3, 6, pal_.moss)
                rect(bx + 2 + i * 5, y_ + info.roofH + 30, 1, 2, pal_.moss)
            end
        end,
    })
end

-- Forja: massa baixa e larga em fuligem — reboco queimado, chaminé larga
-- de ferraria e o brilho da brasa escapando pelo vão quando acesa.
draw.forjaCasa = function(prop, x, y, w, h, pal, t, reduced)
    casaBody(prop, x, y, w, h, pal, {
        wall = pal.wall.mortar, wallLight = pal.wall.face,
        side = pal.floor.shadow,
        roof = Palettes.refuge.roofDark, roofDark = Palettes.ink,
        roofShade = Palettes.refuge.roofDark, roofDeep = Palettes.ink,
        roofFrac = .42,
        windowsLayout = {{22, 16, 13, 10}},
        -- A brasa da forja arde desde sempre: 'covered' (Morada T0) deixa a
        -- luz em meio-tom, nunca apagada — a forja é ofício, não cômodo.
        doorGlow = prop.state == 'lit' and true or 'dim',
        time = t, reduced = reduced,
        extras = function(_, x_, y_, w_, h_, pal_, info)
            -- Chaminé larga + crosta de fuligem subindo pela empena.
            framed(x_ + w_ - 48, y_ - 11, 24, 33, pal_.wall.faceDark, pal_.wall.face)
            rect(x_ + w_ - 51, y_ - 13, 30, 5, pal_.wall.faceDark)
            rect(x_ + w_ - 47, y_ - 12, 22, 1, pal_.wall.face)
            PixelArt.dither(x_ + w_ - 46, y_ - 6, 22, 8, Palettes.ink, .3)
            rect(x_ + 8, y_ + info.roofH + 4, w_ - 16, 3, Palettes.ink, .2)
            -- Fumaça da chaminé: um fio sempre sobe — a luz narrativa mais
            -- óbvia do povoado; 'lit' engorda o fumo do dia de trabalho.
            local puffs = info.lit and 4 or 2
            local c_ = Palettes.refuge
            for i = 1, puffs do
                local rise = info.reduced and (i * 8)
                    or (info.time * (info.lit and 9 or 5) + i * 11) % 36
                local sway = info.reduced and 0 or round(math.sin(info.time * .9 + i * 1.7) * 4)
                rect(x_ + w_ - 42 + sway, y_ - 17 - rise, 4 + i, 3,
                    c_.plasterLight, math.max(.04, (info.lit and .24 or .13) * (1 - rise / 40)))
            end
            -- Rack de ferramenta na fachada: peças penduradas esperando uso.
            pixelLine(x_ + 15, y_ + info.roofH + 18, x_ + 15, y_ + info.roofH + 31,
                pal_.wood.base)
            rect(x_ + 13, y_ + info.roofH + 18, 5, 3, pal_.wall.cap)
            pixelLine(x_ + 22, y_ + info.roofH + 18, x_ + 25, y_ + info.roofH + 30,
                pal_.wood.base)
            rect(x_ + 23, y_ + info.roofH + 18, 4, 3, pal_.wall.cap)
        end,
    })
end

-- ── Vida do lugar (Morada): microambientes de ofício ─────────────
-- QUINTAL — bigorna: cepo de madeira sobre pedra, corpo de ferro com
-- bico à esquerda, e uma cama de brasa bancada ao lado — a forja trabalha
-- devagar mesmo entre uma encomenda e outra.
draw.bigorna = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 6, py + 28, 22, 3, P.ink, .25)
    -- base de pedra + cepo
    framed(px + 9, py + 22, 15, 8, pal.wall.face, pal.wall.cap)
    rect(px + 10, py + 23, 13, 2, pal.wood.dark)
    rect(px + 10, py + 25, 13, 1, pal.wood.base)
    -- corpo de ferro: fuste, mesa e bico afunilado
    rect(px + 11, py + 17, 11, 5, P.ink)
    rect(px + 12, py + 18, 9, 3, pal.wall.mortar)
    rect(px + 4, py + 11, 25, 6, P.ink)
    rect(px + 5, py + 12, 23, 4, pal.wall.face)
    rect(px + 5, py + 12, 23, 1, pal.wall.cap)
    rect(px + 3, py + 12, 4, 3, pal.wall.faceDark)
    rect(px + 26, py + 12, 3, 3, pal.wall.rim)
    -- cama de brasa ao lado: o leito nunca esfria de vez — 'covered' (T0)
    -- deixa brasa baixa e uma fagulha rara; 'lit' acende os pontos quentes
    -- e solta fagulhas pelo quintal.
    rect(px + w - 13, py + 26, 10, 3, pal.floor.shadow)
    local lit = prop.state == 'lit'
    local fl = reduced and .5 or .5 + .5 * math.sin(t * 5.7 + (prop.x or 0) * 1.9)
    rect(px + w - 11, py + 26, 2, 2, Palettes.ember,
        (lit and .35 or .16) + (lit and .4 or .25) * fl)
    rect(px + w - 6, py + 27, 2, 1, Palettes.emberLight,
        (lit and .4 or .18) + (lit and .5 or .3) * fl)
    if not reduced then
        for i = 1, lit and 2 or 1 do
            local ph = (t * 11 + i * 13 + (prop.x or 0) * 3) % 14
            rect(px + w - 10 + i * 3, py + 25 - ph, 1, 1, Palettes.emberLight,
                math.max(.06, (.7 - ph * .05) * (lit and 1 or .55)))
        end
    end
end

-- QUINTAL — pilha de lenha: cepos empilhados em pirâmide e uma tora caída
-- ao lado — trabalho interrompido a meio.
draw.lenha = function(prop, px, py, w, h, pal)
    rect(px + 4, py + 26, 26, 3, P.ink, .22)
    for i = 0, 4 do
        local lw = 22 - i * 3
        rect(px + 4 + i + (i % 2), py + 23 - i * 4, lw, 4,
            i % 2 == 0 and pal.wood.base or pal.wood.dark)
        rect(px + 4 + i + (i % 2), py + 23 - i * 4, 2, 4, pal.wood.light)
        rect(px + 4 + i + (i % 2), py + 23 - i * 4, lw, 1, P.ink, .4)
    end
    -- tora solta encostada na pilha
    rect(px + 22, py + 23, 9, 5, pal.wood.base)
    rect(px + 29, py + 23, 2, 5, pal.wood.light)
    rect(px + 22, py + 23, 9, 1, P.ink, .45)
end

-- HORTA — espantalho: poste e travessa erguidos acima da célula (a
-- silhueta precisa ler contra a grama escura), cabeça de pano claro com
-- chapéu e farrapos que a brisa mexe — guarda o canteiro, não o caminho.
draw.espantalho = function(prop, px, py, w, h, pal, t, reduced)
    local cx = px + round(w / 2)
    -- Estaca alta: fio de sombra a sueste + poça curta no pé.
    rect(cx + 4, py + 28, 14, 2, P.ink, .12)
    rect(cx - 5, py + 29, 12, 2, P.ink, .2)
    rect(cx - 2, py - 6, 4, 36, pal.wood.dark)
    rect(cx - 2, py - 6, 1, 36, pal.wood.base)
    rect(px + 3, py - 4, w - 6, 3, pal.wood.base)
    rect(cx - 5, py - 12, 10, 8, P.ink)
    rect(cx - 4, py - 11, 8, 6, pal.cloth.light)
    rect(cx - 2, py - 9, 1, 1, P.ink); rect(cx + 2, py - 9, 1, 1, P.ink)
    rect(cx - 7, py - 13, 14, 2, pal.wood.light)
    rect(cx - 4, py - 16, 8, 4, pal.wood.base)
    for i = -1, 1 do
        local sw = reduced and 0
            or round(math.sin(t * 1.6 + i * 1.9 + (prop.x or 0)) * 1.3)
        rect(px + 4 + (i + 1) * math.floor(w / 4) + sw, py - 1, 4, 10,
            i == 0 and pal.cloth.base or pal.cloth.dark)
    end
end

-- HORTA — sulcos: terra escura em fileiras paralelas com mudas verdes
-- espaçadas — o canteiro lê-se como trabalho, não jardim.
draw.sulcos = function(prop, px, py, w, h, pal)
    for row = 0, math.floor((h - 9) / 11) do
        local ry = py + 5 + row * 11
        rect(px + 2, ry, w - 4, 5, pal.floor.shadow, .8)
        rect(px + 2, ry, w - 4, 1, pal.floor.dark)
        for i = 0, math.floor(w / 14) - 1 do
            local sx = px + 6 + i * 14 + (row % 2) * 6
            if sx + 3 < px + w - 3 then
                rect(sx, ry - 3, 2, 4, pal.moss)
                rect(sx - 1, ry - 2, 1, 2, pal.moss)
                rect(sx + 2, ry - 2, 1, 2, pal.moss)
            end
        end
    end
end

-- VARAL — linha esticada entre dois postes, peças de pano penduradas que
-- a brisa atrasa uma a uma — a largura do prop dita o vão.
draw.varal = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 1, py + 5, 3, 25, pal.wood.dark)
    rect(px + 1, py + 5, 3, 1, pal.wood.light)
    rect(px + w - 4, py + 5, 3, 25, pal.wood.dark)
    rect(px + w - 4, py + 5, 3, 1, pal.wood.light)
    pixelLine(px + 4, py + 7, px + w - 4, py + 7, pal.wood.base)
    for i = 0, math.floor(w / 15) - 1 do
        local cx = px + 7 + i * 15
        local sway = reduced and 0
            or round(math.sin(t * 1.7 + i * 2.1 + (prop.x or 0) * 1.3) * 1.3)
        local ph = 9 + (i % 2) * 3
        rect(cx + sway, py + 8, 7, ph, i % 2 == 0 and pal.cloth.base or pal.cloth.light)
        rect(cx + sway, py + 8, 7, 1, P.ink, .5)
        rect(cx + 1 + sway, py + 8 + ph, 5, 1, pal.cloth.dark)
    end
end

-- TERRAÇO — rack de ervas: cavalete de duas pernas com molhos pendurados
-- a secar — a cozinha seca seu tempero ao vento do vale.
draw.ervasRack = function(prop, px, py, w, h, pal)
    pixelLine(px + 4, py + 28, px + 9, py + 6, pal.wood.dark)
    pixelLine(px + w - 4, py + 28, px + w - 8, py + 6, pal.wood.dark)
    pixelLine(px + 9, py + 6, px + w - 8, py + 6, pal.wood.base)
    for i = 0, math.floor(w / 16) - 1 do
        local hx = px + 11 + i * 16
        rect(hx, py + 7, 2, 3, pal.wood.light)
        rect(hx - 1, py + 10, 5, 8, pal.moss)
        rect(hx - 1, py + 16, 5, 2, pal.floor.shadow, .6)
        rect(hx, py + 10, 3, 1, pal.wood.base)
    end
    rect(px + 2, py + 28, 6, 2, pal.wood.dark)
    rect(px + w - 8, py + 28, 6, 2, pal.wood.dark)
end

-- PRAÇA — quadro de avisos: poste e tábua com papéis pregados — a
-- comunidade afixa seus recados junto ao marco.
draw.cartazPraca = function(prop, px, py, w, h, pal)
    rect(px + 14, py + 13, 4, 17, pal.wood.dark)
    rect(px + 11, py + 29, 10, 2, pal.wood.dark)
    framed(px + 4, py + 2, 24, 14, pal.wood.base, pal.wood.light)
    local c = Palettes.refuge
    rect(px + 6, py + 4, 6, 8, pal.cloth.light)
    rect(px + 14, py + 5, 5, 6, c.plaster)
    rect(px + 21, py + 4, 5, 9, pal.cloth.base)
    rect(px + 7, py + 6, 4, 1, P.ink); rect(px + 7, py + 8, 3, 1, P.ink)
    rect(px + 15, py + 7, 3, 1, P.ink)
    rect(px + 22, py + 6, 3, 1, P.ink); rect(px + 22, py + 10, 2, 1, P.ink)
    rect(px + 8, py + 4, 1, 1, pal.petal); rect(px + 16, py + 5, 1, 1, pal.petal)
    rect(px + 23, py + 4, 1, 1, pal.petal)
end

-- PRAÇA — placa de rotas com lanterna pendurada: o poste de caminhos
-- carrega a luz que a praça nunca deixa apagar (sem state — sempre acesa).
draw.placaRotas = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 14, py + 8, 4, 22, pal.wood.dark)
    rect(px + 12, py + 29, 8, 2, pal.wood.dark)
    framed(px + 4, py + 1, 15, 11, pal.wood.base, pal.wood.light)
    rect(px + 6, py + 4, 9, 1, P.ink); rect(px + 6, py + 7, 6, 1, P.ink)
    -- Braço + lanterna: vidro claro com a chama dentro, tremer devagar.
    rect(px + 17, py + 5, 10, 2, pal.wood.dark)
    rect(px + 24, py + 7, 1, 3, P.ink)
    local fl = reduced and .6 or .6 + .4 * math.sin(t * 7.1 + (prop.x or 0) * 1.3)
    rect(px + 21, py + 10, 7, 9, P.ink)
    rect(px + 22, py + 11, 5, 7, pal.cloth.light)
    rect(px + 23, py + 12, 3, 5, Palettes.emberLight, .5 + .4 * fl)
    rect(px + 23, py + 12, 3, 2, Palettes.ember, .6 + .3 * fl)
    rect(px + 21, py + 10, 7, 2, pal.wood.dark)
    rect(px + 21, py + 18, 7, 1, pal.wood.dark)
end

-- MIRANTE — braseiro do posto de guarda: tigela de ferro sobre tripé,
-- fogo baixo constante e fagulhas — a luz do vigia nunca apaga (sem state).
draw.braseiro = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 5, py + 29, 22, 2, P.ink, .28)
    -- Tripé de ferro: hastes grossas com contorno de tinta — a estrutura
    -- lê-se contra a grama antes do fogo.
    pixelLine(px + 8, py + 31, px + 13, py + 17, P.ink)
    pixelLine(px + 24, py + 31, px + 19, py + 17, P.ink)
    pixelLine(px + 9, py + 30, px + 14, py + 18, pal.wall.faceDark)
    pixelLine(px + 23, py + 30, px + 18, py + 18, pal.wall.faceDark)
    rect(px + 15, py + 18, 2, 13, P.ink); rect(px + 15, py + 18, 1, 12, pal.wall.mortar)
    -- Tigela de ferro: boca larga com lábio claro e barriga escura — corpo
    -- suficiente para segurar a luz própria.
    rect(px + 6, py + 8, 20, 10, P.ink)
    rect(px + 7, py + 9, 18, 7, pal.wall.mortar)
    rect(px + 6, py + 8, 20, 2, pal.wall.cap)
    rect(px + 7, py + 9, 18, 1, pal.wall.face)
    rect(px + 9, py + 16, 14, 2, pal.wall.faceDark)
    -- Fogo: leito de brasa, chama trêmula e fagulhas subindo — sempre aceso.
    local fl = reduced and .6 or .55 + .45 * math.sin(t * 7.7 + (prop.x or 0) * 1.9)
    rect(px + 9, py + 8, 14, 2, Palettes.ember, .55 + .3 * fl)
    rect(px + 12, py + 4 - (fl > .6 and 1 or 0), 4, 6, Palettes.emberLight, .7 + .3 * fl)
    rect(px + 18, py + 6, 3, 3, Palettes.ember, .55 + .3 * fl)
    rect(px + 15, py + 5, 2, 2, P.goldLight, .5 + .4 * fl)
    if not reduced then
        for i = 1, 2 do
            local ph = (t * 13 + i * 17 + (prop.x or 0) * 5) % 16
            rect(px + 12 + i * 5, py + 6 - ph, 1, 1, Palettes.emberLight,
                math.max(.05, .65 - ph * .045))
        end
    end
end

-- MIRANTE — posto de vigia: armaiote de tábuas com escudo pendurado e
-- lança de serviço fincada; bloco de parapeito de pedra ao lado — o lugar
-- lê 'guarda sobre o vale' antes do primeiro passo.
draw.postoVigia = function(prop, px, py, w, h, pal)
    -- Poste alto lança fio de sombra a sueste, além da poça de contato.
    rect(px + 16, py + 30, 14, 2, P.ink, .12)
    rect(px + 3, py + 29, 27, 2, P.ink, .22)
    -- Parapeito de pedra: bloco baixo arrematando a beira do mirante.
    framed(px + 16, py + 21, 14, 9, pal.wall.face, pal.wall.cap)
    rect(px + 16, py + 21, 14, 2, pal.wall.cap)
    rect(px + 20, py + 25, 8, 1, pal.wall.mortar)
    -- Armaiote: duas pernas e travessa alta de tábua.
    rect(px + 4, py + 5, 3, 25, pal.wood.dark)
    rect(px + 4, py + 5, 3, 1, pal.wood.light)
    rect(px + 11, py + 5, 3, 25, pal.wood.dark)
    rect(px + 3, py + 7, 13, 3, pal.wood.base)
    rect(px + 3, py + 7, 13, 1, pal.wood.light)
    -- Escudo pendurado na travessa: pano escuro com boss de ferro.
    rect(px + 5, py + 11, 9, 12, P.ink)
    rect(px + 6, py + 12, 7, 10, pal.cloth.dark)
    rect(px + 6, py + 12, 7, 2, pal.cloth.base)
    rect(px + 8, py + 15, 3, 3, pal.wall.cap)
    -- Lança apoiada de viés, ponta de pedra passando do quadro.
    pixelLine(px + 15, py + 30, px + 18, py + 2, pal.wood.base)
    rect(px + 17, py - 2, 3, 4, pal.wall.cap)
    rect(px + 18, py - 2, 1, 1, pal.wall.rim)
end

-- TERRAÇO — cercado do bicho: mourões com duas varas e uma cabra mansa
-- pastando dentro — corpinho claro de lado, cabeça baixa, barbicha e
-- cauda que mexe devagar.
draw.animal = function(prop, px, py, w, h, pal, t, reduced)
    -- Cerca de varas: mourões espaçados na largura do prop.
    for sx = 2, w - 4, math.max(10, math.floor(w / 2) - 3) do
        rect(px + sx, py + 11, 2, 17, pal.wood.dark)
        rect(px + sx, py + 11, 2, 1, pal.wood.light)
    end
    rect(px + 2, py + 14, w - 4, 2, pal.wood.base)
    rect(px + 2, py + 21, w - 4, 2, pal.wood.dark)
    -- Cabra: corpo claro de perfil, cabeça baixa rumo ao capim.
    local bob = reduced and 0 or round(math.sin(t * 1.8 + (prop.x or 0)) * 1)
    local bx = px + round(w / 2) - 4
    rect(bx - 6, py + 14 + bob, 13, 8, P.ink)
    rect(bx - 5, py + 15 + bob, 11, 6, pal.wall.cap)
    rect(bx - 4, py + 16 + bob, 3, 2, pal.wall.rim)
    -- Cabeça baixa à esquerda: chifre curto, olho, barbicha.
    rect(bx - 9, py + 17 + bob, 5, 6, P.ink)
    rect(bx - 8, py + 18 + bob, 4, 5, pal.wall.cap)
    rect(bx - 7, py + 16 + bob, 1, 2, pal.wood.dark)
    rect(bx - 7, py + 19 + bob, 1, 1, P.ink)
    rect(bx - 8, py + 22 + bob, 2, 2, pal.wall.face)
    -- Perninhas e a cauda que mexe.
    rect(bx - 4, py + 22 + bob, 2, 6, P.ink); rect(bx + 3, py + 22 + bob, 2, 6, P.ink)
    local wag = reduced and 0 or round(math.sin(t * 3.3 + (prop.x or 0)) * 1.5)
    rect(bx + 7 + wag, py + 15 + bob, 2, 3, pal.wall.cap)
    -- Tufos de capim dentro do cercado — o pasto lê-se no chão.
    for i = 0, math.floor(w / 14) - 1 do
        local gx = px + 4 + i * 14
        rect(gx, py + 28, 1, 3, pal.moss); rect(gx + 2, py + 29, 2, 2, pal.moss)
    end
end

-- DEPÓSITO — fardos de grão: trouxas de pano empilhadas com nó no topo —
-- a carga da casa comprida enche o vão morto do terraço.
draw.fardos = function(prop, px, py, w, h, pal)
    rect(px + 3, py + 28, 26, 3, P.ink, .22)
    for _, s in ipairs({{4, 19, 12}, {17, 19, 12}, {10, 10, 12}}) do
        local sx, sy, sw = s[1], s[2], s[3]
        rect(px + sx, py + sy, sw, 10, P.ink)
        rect(px + sx + 1, py + sy + 1, sw - 2, 8, pal.cloth.light)
        rect(px + sx + 1, py + sy + 1, sw - 2, 2, pal.cloth.base)
        rect(px + sx + math.floor(sw / 2) - 1, py + sy - 1, 3, 3, pal.cloth.dark)
        rect(px + sx + 2, py + sy + 5, sw - 4, 1, pal.cloth.dark, .5)
    end
end

-- ── Fatia I do Olhar: a alma do lugar ────────────────────────────
-- RUA — poço: boca de pedra baixa com forquilhas segurando a roldana e o
-- balde meio içado, fora do prumo — o apoio está comido na direção em que
-- todos puxam a corda (doc §139).
draw.poco = function(prop, px, py, w, h, pal)
    rect(px + 2, py + 28, 28, 3, P.ink, .25)
    -- Forquilhas e travessa do eixo — veios nos postes e o ferro do eixo.
    rect(px + 6, py + 1, 3, 14, pal.wood.dark)
    rect(px + 6, py + 1, 3, 1, pal.wood.light)
    rect(px + 7, py + 4, 1, 10, pal.wood.base, .5)
    rect(px + 23, py + 1, 3, 14, pal.wood.dark)
    rect(px + 23, py + 1, 3, 1, pal.wood.light)
    rect(px + 24, py + 4, 1, 10, pal.wood.base, .5)
    rect(px + 6, py + 3, 20, 2, pal.wood.base)
    rect(px + 6, py + 3, 20, 1, pal.wood.light)
    rect(px + 6, py + 4, 2, 1, pal.wall.mortar); rect(px + 24, py + 4, 2, 1, pal.wall.mortar)
    -- Roldana no eixo com a corda descendo de viés: voltas na polia e a
    -- trama escura na descida.
    rect(px + 14, py + 2, 5, 6, P.ink)
    rect(px + 15, py + 3, 3, 4, pal.wall.mortar)
    rect(px + 15, py + 3, 3, 1, pal.wall.cap)
    rect(px + 15, py + 5, 3, 1, P.ink, .6)
    rect(px + 16, py + 3, 1, 1, pal.wall.rim, .8)
    pixelLine(px + 17, py + 7, px + 19, py + 17, pal.wood.light)
    rect(px + 18, py + 9, 1, 1, pal.wood.dark)
    rect(px + 19, py + 13, 1, 1, pal.wood.dark)
    -- Balde meio içado: aro de ferro, alça erguida e água no fundo.
    rect(px + 17, py + 16, 7, 7, P.ink)
    rect(px + 18, py + 17, 5, 5, pal.wood.base)
    rect(px + 18, py + 17, 5, 1, pal.wall.mortar)
    rect(px + 19, py + 18, 3, 1, pal.wood.dark, .5)
    rect(px + 19, py + 21, 3, 1, pal.cloth.dark)
    -- Boca: anel de pedra oval com lábio e o escuro da água embaixo.
    local cx, cy = px + 14, py + 23
    G.setColor(P.ink[1], P.ink[2], P.ink[3], 1)
    G.ellipse('fill', cx, cy + 1, 13, 8)
    G.setColor(pal.wall.face[1], pal.wall.face[2], pal.wall.face[3], 1)
    G.ellipse('fill', cx, cy, 12, 7)
    G.setColor(pal.wall.cap[1], pal.wall.cap[2], pal.wall.cap[3], 1)
    G.ellipse('fill', cx, cy - 1, 12, 6)
    G.setColor(P.abyss[1], P.abyss[2], P.abyss[3], 1)
    G.ellipse('fill', cx, cy + 1, 8, 4)
    -- Juntas do brocal: as pedras do anel leem-se em corte.
    rect(px + 5, py + 21, 2, 3, pal.wall.mortar)
    rect(px + 11, py + 19, 1, 2, pal.wall.mortar)
    rect(px + 23, py + 21, 2, 3, pal.wall.mortar)
    rect(px + 8, py + 26, 3, 1, pal.wall.faceDark, .7)
    -- Lume na água lá embaixo + musgo rente ao brocal.
    rect(px + 12, py + 24, 3, 1, pal.cloth.light, .5)
    rect(px + 6, py + 27, 3, 2, pal.moss, .8)
    -- Apoio gasto: aro clareado e comido onde a corda esfrega ao puxar —
    -- o sulco fundo no fio denuncia a direção de todas as mãos.
    rect(px + 22, py + 18, 5, 2, pal.wall.cap)
    rect(px + 23, py + 19, 3, 1, pal.wall.rim)
    rect(px + 24, py + 20, 2, 1, pal.wall.faceDark, .8)
end
-- O Pátio plantou o poço da rua como 'pocoRua' (kind 'cisterna' de
-- placeholder): o id resolve o painter próprio.
draw.pocoRua = draw.poco

-- POÇO — potaria de estimação: vasilhas esperando a vez junto à boca —
-- a água turva deixa contorno escuro dentro delas (doc §139). 'lit' (água
-- correndo pela cisterna) enche os potes e deixa um fio escorrendo.
draw.recipientesPoco = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 3, py + 27, 26, 3, P.ink, .22)
    -- Pote alto de ombro com a boca manchada de turvo.
    rect(px + 6, py + 14, 10, 14, P.ink)
    rect(px + 7, py + 15, 8, 12, pal.wall.cap)
    rect(px + 7, py + 15, 8, 1, pal.wall.rim)
    rect(px + 8, py + 11, 6, 4, P.ink)
    rect(px + 9, py + 12, 4, 3, pal.wall.cap)
    rect(px + 9, py + 12, 4, 1, pal.cloth.dark)
    -- Cumbuca rasa e jarro deitado de lado.
    rect(px + 18, py + 20, 10, 8, P.ink)
    rect(px + 19, py + 21, 8, 6, pal.wood.base)
    rect(px + 19, py + 21, 8, 1, pal.wall.rim)
    rect(px + 19, py + 22, 8, 2, pal.cloth.dark, .6)
    rect(px + 3, py + 23, 6, 5, P.ink)
    rect(px + 4, py + 23, 5, 4, pal.cloth.light)
    if prop.state == 'lit' then
        local drip = reduced and 3 or math.floor((t * 9 + (prop.x or 0)) % 8)
        rect(px + 15, py + 12, 1, 3, pal.cloth.light, .8)
        rect(px + 20, py + 21 + drip, 1, 2, pal.cloth.light, .5)
    end
end

-- ADRO — canteiros baixos do jardim da capela: bordas de pedra solta,
-- terra molhada escura e flores nos restos do terreno (doc §99). 'lit'
-- (depois do rito) é a terra preparada ganhando cor — a cama enche.
draw.canteiroJardim = function(prop, px, py, w, h, pal)
    local lit = prop.state == 'lit'
    rect(px + 1, py + 9, w - 2, h - 13, P.ink)
    rect(px + 2, py + 10, w - 4, h - 15, pal.wall.face)
    rect(px + 2, py + 10, w - 4, 1, pal.wall.cap)
    -- Terra molhada: cama escura com veios de umidade.
    rect(px + 3, py + 12, w - 6, h - 19, pal.floor.shadow)
    for i = 0, math.floor(w / 18) - 1 do
        rect(px + 5 + i * 18, py + 14 + (i % 2) * 3, 12, 1, pal.floor.dark, .7)
    end
    -- Flores em fileira frouxa — algumas mudas só têm caule.
    local count = lit and 7 or 4
    for i = 0, count - 1 do
        local fx = px + 6 + i * math.floor((w - 14) / math.max(1, count))
        local fy = py + 16 + (i % 2) * 4
        rect(fx, fy + 2, 1, 4, pal.moss)
        if lit or i % 2 == 0 then
            rect(fx - 1, fy, 3, 3, P.ink)
            rect(fx, fy, 1, 2, lit and pal.petal or pal.cloth.light)
        end
    end
    -- Uma flor se inclina sobre a borda: quem passa desvia dela.
    pixelLine(px + w - 7, py + 16, px + w - 4, py + 11, pal.moss)
    rect(px + w - 5, py + 9, 3, 3, P.ink)
    rect(px + w - 4, py + 9, 1, 2, pal.petal)
end
-- O canteiro do adro chegou pelo Pátio como 'canteiroAdro' (kind 'sulcos'
-- de placeholder); 'canteiroJardim' segue reservado ao estado de campanha.
draw.canteiroAdro = draw.canteiroJardim

-- ADRO — oferenda: coisa pequena deixada sem nome junto à entrada — uma
-- tigela rasa e uma flor sobre a pedra baixa (doc: "o banco da entrada").
-- 'lit' (depois do rito) guarda uma brasa curta dentro da tigela.
draw.oferenda = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 7, py + 25, 18, 4, P.ink, .22)
    framed(px + 8, py + 19, 16, 7, pal.wall.face, pal.wall.cap)
    rect(px + 8, py + 19, 16, 1, pal.wall.cap)
    -- Tigela rasa com o resto dentro.
    rect(px + 10, py + 14, 9, 6, P.ink)
    rect(px + 11, py + 15, 7, 4, pal.wall.cap)
    rect(px + 11, py + 15, 7, 1, pal.wall.rim)
    rect(px + 12, py + 16, 5, 2, pal.floor.shadow)
    -- Flor deixada ao lado, haste curta.
    rect(px + 21, py + 17, 1, 4, pal.moss)
    rect(px + 20, py + 15, 3, 3, P.ink)
    rect(px + 21, py + 15, 1, 2, pal.petal)
    if prop.state == 'lit' then
        local fl = reduced and .5 or .5 + .5 * math.sin(t * 7.9 + (prop.x or 0))
        rect(px + 13, py + 15, 3, 2, Palettes.emberLight, .5 + .4 * fl)
        rect(px + 14, py + 14, 1, 1, P.goldLight, .6 + .4 * fl)
    end
end

-- VARANDA — cadeira sob o beiral: encosto reparado com uma tábua de outro
-- tom, perna curta calçada e a sombra do toldo cortando o alto da célula
-- (doc §145 — estar na varanda não obriga conversa).
draw.varanda = function(prop, px, py, w, h, pal)
    -- Sombra do beiral caindo por cima — a varanda lê-se antes da cadeira.
    rect(px, py, w, 9, pal.floor.shadow, .4)
    rect(px + 1, py + 9, w - 2, 2, pal.floor.shadow, .2)
    rect(px + 4, py + 28, 24, 3, P.ink, .22)
    -- Encosto alto com a tábua do reparo mais clara no meio — pregos nos
    -- cantos e veio diferente denunciam a peça trocada (doc §145).
    rect(px + 10, py + 5, 13, 12, P.ink)
    rect(px + 11, py + 6, 11, 10, pal.wood.base)
    rect(px + 11, py + 6, 11, 1, pal.wood.light)
    rect(px + 11, py + 9, 11, 3, pal.wood.light)
    rect(px + 12, py + 10, 9, 1, pal.wood.base, .6)
    rect(px + 11, py + 13, 11, 1, pal.wood.dark)
    rect(px + 12, py + 6, 1, 1, P.ink); rect(px + 20, py + 6, 1, 1, P.ink)
    rect(px + 12, py + 15, 1, 1, P.ink); rect(px + 20, py + 15, 1, 1, P.ink)
    -- Assento e pernas desiguais — a dianteira direita encurtou e ganhou
    -- calço de cunha clara; o traveiro frontal liga as duas.
    rect(px + 9, py + 16, 15, 5, pal.wood.dark)
    rect(px + 9, py + 16, 15, 1, pal.wood.base)
    rect(px + 9, py + 20, 15, 1, P.ink, .5)
    rect(px + 10, py + 21, 2, 8, P.ink)
    rect(px + 10, py + 21, 1, 7, pal.wood.dark)
    rect(px + 21, py + 21, 2, 6, P.ink)
    rect(px + 21, py + 27, 3, 2, pal.wood.dark)
    rect(px + 21, py + 27, 3, 1, pal.wood.light, .8)
    rect(px + 11, py + 24, 11, 1, pal.wood.dark, .7)
end
draw.cadeiraVaranda = draw.varanda

-- ARRIMO — remendo de alvenaria: junta de pedra mais nova e mais clara
-- que a face em volta — o conserto recente lê-se na massa velha (doc §204:
-- "havia remendos nas paredes").
draw.remendoMuro = function(prop, px, py, w, h, pal)
    rect(px + 1, py + 2, w - 2, h - 4, pal.wall.mortar)
    -- Blocos maiores e mais regulares que a fiada do arrimo: a massa do
    -- conserto tem ritmo próprio.
    for j = 0, math.floor(h / 9) - 1 do
        local ry = py + 3 + j * 9
        for i = 0, math.floor(w / 16) do
            local bx = px + 2 + i * 16 + (j % 2) * 8
            if bx + 15 <= px + w - 2 then
                rect(bx, ry, 15, 8, pal.wall.face)
                rect(bx, ry, 15, 1, pal.wall.cap)
            end
        end
    end
    rect(px + 1, py + 2, w - 2, 1, pal.wall.cap)
    -- Bordas do remendo: o contorno de argamassa delimita o trecho refeito.
    rect(px + 1, py + 2, 1, h - 4, pal.wall.rim, .6)
    rect(px + w - 2, py + 2, 1, h - 4, pal.wall.rim, .6)
end

-- MORADA — ervas secando: corda entre pitões com molhos cabeça-abaixo —
-- a cozinha pendura o tempero do lado de fora quando a semana pede.
-- 'lit' é a colheita nova: molhos cheios; quieta, sobram os pés.
draw.ervasSecas = function(prop, px, py, w, h, pal, t, reduced)
    rect(px + 3, py + 28, w - 6, 3, P.ink, .2)
    -- Corda esticada entre dois pitões de parede.
    rect(px + 2, py + 5, 3, 4, pal.wall.mortar)
    rect(px + w - 5, py + 5, 3, 4, pal.wall.mortar)
    pixelLine(px + 5, py + 7, px + w - 5, py + 7, pal.wood.base)
    local count = prop.state == 'lit' and math.floor(w / 9)
        or math.max(2, math.floor(w / 16))
    for i = 0, count - 1 do
        local hx = px + 7 + i * math.floor((w - 14) / math.max(1, count - 1))
        local sway = reduced and 0
            or round(math.sin(t * 1.3 + i * 2.3 + (prop.x or 0)) * 1)
        rect(hx, py + 7, 1, 3, pal.wood.light)
        -- Molho cabeça-abaixo: atadura clara, corpo escurecendo na ponta.
        rect(hx - 2 + sway, py + 10, 6, 8, pal.moss)
        rect(hx - 2 + sway, py + 15, 6, 3, pal.floor.shadow, .55)
        rect(hx - 1 + sway, py + 10, 4, 2, pal.wood.base)
    end
end

-- INTERIOR — prateleira da cozinha: tábuas com recipientes que nunca
-- formaram conjunto; a tigela pequena fica fora do lugar porque circula
-- pela casa (doc §109).
draw.prateleira = function(prop, px, py, w, h, pal)
    -- Tábuas de parede com escoras de ferro, veios e a sombra de carga de
    -- cada recipiente — prateleira de trabalho, não mostruário.
    rect(px + 3, py + 9, w - 6, 2, pal.wood.base)
    rect(px + 3, py + 9, w - 6, 1, pal.wood.light)
    rect(px + 3, py + 11, w - 6, 1, pal.wood.dark)
    rect(px + 4, py + 12, 2, 2, pal.wall.mortar)
    rect(px + w - 7, py + 12, 2, 2, pal.wall.mortar)
    rect(px + 8, py + 9, 9, 1, pal.wood.dark, .4)
    rect(px + 3, py + 20, w - 6, 2, pal.wood.base)
    rect(px + 3, py + 20, w - 6, 1, pal.wood.light)
    rect(px + 3, py + 22, w - 6, 1, pal.wood.dark)
    rect(px + 4, py + 23, 2, 2, pal.wall.mortar)
    rect(px + w - 7, py + 23, 2, 2, pal.wall.mortar)
    rect(px + 12, py + 20, 10, 1, pal.wood.dark, .4)
    -- Tábua de cima: pote alto, cumbuca e vidrinho — cada um de uma
    -- família, cada um com sua sombra na tábua.
    rect(px + 6, py + 3, 5, 6, pal.wall.cap)
    rect(px + 6, py + 3, 5, 1, P.ink, .4)
    rect(px + 6, py + 4, 5, 1, pal.wall.rim, .8)
    rect(px + 6, py + 8, 5, 1, pal.wood.dark, .4)
    rect(px + 13, py + 5, 7, 4, pal.cloth.light)
    rect(px + 13, py + 5, 7, 1, P.ink, .4)
    rect(px + 14, py + 6, 5, 1, pal.cloth.base, .7)
    rect(px + 13, py + 8, 7, 1, pal.wood.dark, .4)
    rect(px + 22, py + 4, 4, 5, pal.wood.dark)
    rect(px + 22, py + 4, 4, 1, pal.wall.cap)
    rect(px + 22, py + 8, 4, 1, pal.wood.dark, .4)
    -- De baixo: potes menores e a tigela pequena tombada na ponta — a que
    -- cabe na mão e continua em circulação (doc §109).
    rect(px + 5, py + 15, 6, 5, pal.cloth.base)
    rect(px + 5, py + 15, 6, 1, P.ink, .4)
    rect(px + 5, py + 19, 6, 1, pal.wood.dark, .4)
    rect(px + 13, py + 14, 5, 6, pal.wall.face)
    rect(px + 13, py + 14, 5, 1, pal.wall.rim)
    rect(px + 13, py + 19, 5, 1, pal.wood.dark, .4)
    rect(px + w - 10, py + 17, 7, 5, P.ink)
    rect(px + w - 9, py + 18, 5, 3, pal.wall.rim)
    rect(px + w - 9, py + 18, 5, 1, Palettes.white)
    -- Concha pendurada num pitão sob a tábua: serviço ao alcance da mão.
    rect(px + w - 6, py + 23, 1, 4, pal.wall.mortar)
    rect(px + w - 8, py + 26, 4, 3, pal.wall.mortar)
    rect(px + w - 7, py + 26, 2, 1, pal.wall.faceDark)
end

-- INTERIOR — quadro de parede: moldura de madeira com filete e a cena
-- miúda dentro — morro, casinha e o céu do vale. Prego torto em cima e a
-- sombra da moldura pendurada: quadro de casa, não de capela.
draw.quadro = function(prop, px, py, w, h, pal)
    rect(px + 15, py + 2, 2, 2, pal.wall.mortar)
    rect(px + 8, py + 4, 17, 14, P.ink)
    framed(px + 9, py + 5, 15, 12, pal.wood.dark, pal.wood.base)
    rect(px + 9, py + 5, 15, 1, pal.wood.base)
    -- Cena em três planos e três tons: céu, morro e a casa com a
    -- janelinha acesa — lembrança de um lugar que se olha de longe.
    rect(px + 11, py + 7, 11, 8, pal.cloth.dark)
    rect(px + 12, py + 8, 9, 3, pal.cloth.base)
    rect(px + 13, py + 8, 1, 1, pal.wall.cap, .9)
    rect(px + 12, py + 11, 9, 3, pal.moss)
    rect(px + 12, py + 11, 9, 1, pal.cloth.dark, .5)
    rect(px + 16, py + 9, 4, 3, pal.wall.face)
    rect(px + 16, py + 9, 4, 1, pal.wall.cap)
    rect(px + 17, py + 11, 1, 1, P.emberLight, .85)
    rect(px + 9, py + 17, 15, 2, P.ink, .25)
end

-- INTERIOR — brinquedo: cavalinho de rodas com corda de arrasto caída —
-- peça de ofício feita às pressas que denuncia a mão (doc §123), mas que
-- alguém quis que existisse. Sinal de criança no quarto comum.
draw.brinquedo = function(prop, px, py, w, h, pal)
    local wood = pal.wood
    rect(px + 7, py + 27, 18, 3, P.ink, .22)
    -- Corpo de tábua bruta: lombo reto, pescoço e focinho para a frente.
    rect(px + 9, py + 15, 12, 7, P.ink)
    rect(px + 10, py + 16, 10, 5, wood.base)
    rect(px + 10, py + 16, 10, 1, wood.light)
    rect(px + 12, py + 19, 6, 1, wood.dark, .6)
    rect(px + 8, py + 9, 6, 7, P.ink)
    rect(px + 9, py + 10, 4, 5, wood.base)
    rect(px + 9, py + 10, 4, 1, wood.light)
    -- Crina tosquia aparada e o olho de prego.
    rect(px + 8, py + 9, 2, 5, wood.dark)
    rect(px + 11, py + 11, 1, 1, P.ink)
    -- Perninhas de taco sobre rodas de tronco.
    rect(px + 10, py + 22, 2, 4, wood.dark)
    rect(px + 17, py + 22, 2, 4, wood.dark)
    for _, wx in ipairs({px + 9, px + 17}) do
        rect(wx, py + 25, 5, 5, P.ink)
        rect(wx + 1, py + 26, 3, 3, pal.wall.mortar)
        rect(wx + 2, py + 27, 1, 1, pal.wall.cap)
    end
    -- Corda de arrasto solta no chão.
    pixelLine(px + 8, py + 19, px + 3, py + 27, wood.light)
    rect(px + 2, py + 26, 3, 2, wood.light)
    rect(px + 2, py + 27, 3, 1, wood.dark, .6)
end

-- PENSÃO — sinais de vida junto à cama (doc §115): um objeto perto do
-- travesseiro, uma peça dobrada e o calçado rente, fora da passagem —
-- "algo que a pessoa quer conseguir encontrar amanhã". Três feitios por
-- célula para as camas não repetirem a mesma história.
draw.pertencesCama = function(prop, px, py, w, h, pal)
    -- O dígito do id escolhe a lembrança (pertencesCama1/2/3); sem dígito,
    -- a posição da célula sorteia — as camas não repetem a mesma história.
    local v = tonumber((prop.id or ''):match('(%d+)$'))
        or math.floor((prop.x or 0) + (prop.y or 0))
    v = math.floor(v) % 3
    rect(px + 5, py + 27, 22, 3, P.ink, .2)
    -- Peça dobrada: pilha baixa com vinco e barra de costura no fio.
    rect(px + 6, py + 19, 11, 8, P.ink)
    rect(px + 7, py + 20, 9, 6, v == 1 and pal.cloth.dark or pal.cloth.base)
    rect(px + 7, py + 20, 9, 1, pal.cloth.light)
    rect(px + 7, py + 23, 9, 1, pal.cloth.dark, .6)
    rect(px + 8, py + 21, 2, 1, pal.cloth.light, .7)
    -- Objeto de estimação junto ao travesseiro — cada cama guarda um.
    if v == 0 then
        -- Livrinho gasto com o marcador de pano saindo.
        rect(px + 19, py + 21, 8, 5, P.ink)
        rect(px + 20, py + 22, 6, 3, pal.wood.dark)
        rect(px + 21, py + 22, 4, 1, pal.cloth.light)
        rect(px + 24, py + 22, 1, 4, pal.petal)
    elseif v == 1 then
        -- Cuieta de estimação: vasilha pequena de borda clara.
        rect(px + 20, py + 21, 7, 6, P.ink)
        rect(px + 21, py + 22, 5, 4, pal.wall.cap)
        rect(px + 21, py + 22, 5, 1, pal.wall.rim)
        rect(px + 22, py + 23, 3, 1, pal.wall.faceDark)
    else
        -- Passarinho talhado: corpo, bico e o lombo claro da oficina.
        rect(px + 20, py + 20, 8, 6, P.ink)
        rect(px + 21, py + 21, 6, 4, pal.wood.base)
        rect(px + 26, py + 22, 2, 1, pal.wood.light)
        rect(px + 22, py + 22, 1, 1, P.ink)
        rect(px + 21, py + 21, 6, 1, pal.wood.light)
        rect(px + 21, py + 24, 3, 1, pal.wood.dark, .6)
    end
    -- Calçado rente à cama (doc §115 — disciplina de convivência: ninguém
    -- larga o sapato onde outro precisa andar no escuro).
    rect(px + 8, py + 27, 5, 3, P.ink)
    rect(px + 9, py + 27, 4, 2, pal.wood.dark)
    rect(px + 9, py + 27, 2, 1, pal.wood.base, .7)
    rect(px + 15, py + 27, 5, 3, P.ink)
    rect(px + 16, py + 27, 4, 2, pal.wood.dark)
    rect(px + 16, py + 27, 2, 1, pal.wood.base, .7)
end
-- O Pátio planta as três lembranças como kind 'pertences'
-- (pertencesCama1/2/3): o kind resolve no painter da família.
draw.pertences = draw.pertencesCama

-- OFICINA — serragem no chão: monte de pó de serra dithered com aparas
-- em cacho e uma ripa cortada ao lado — o trabalho que nunca se varre de
-- uma vez (doc §121). Sombreado no verso, claro no fio.
draw.serragem = function(prop, px, py, w, h, pal)
    local wood = pal.wood
    PixelArt.ditherEllipse(px + 15, py + 24, 13, 5, wood.light, .8)
    PixelArt.ditherEllipse(px + 13, py + 25, 8, 3, wood.base, .7)
    -- Aparas: cavacos curvos de plaina sobre o monte.
    rect(px + 8, py + 20, 4, 1, wood.light); rect(px + 11, py + 19, 1, 1, wood.light)
    rect(px + 15, py + 22, 5, 1, wood.light); rect(px + 19, py + 21, 1, 1, wood.base)
    rect(px + 11, py + 24, 3, 1, wood.base, .8)
    -- Ripa caída e a serra encostada: ferro no fio, cabo escuro.
    rect(px + 20, py + 26, 8, 2, wood.dark)
    rect(px + 20, py + 26, 8, 1, wood.base)
    pixelLine(px + 23, py + 13, px + 28, py + 20, pal.wall.cap)
    pixelLine(px + 22, py + 14, px + 27, py + 21, P.ink)
    rect(px + 21, py + 11, 3, 3, wood.dark)
end

-- RUA — balde de tempera: a água escurecida deixa contorno turvo no
-- recipiente (doc §139); alça de ferro e pano escorrido na borda.
draw.baldeTempera = function(prop, px, py, w, h, pal)
    rect(px + 8, py + 27, 16, 3, P.ink, .22)
    rect(px + 9, py + 12, 14, 16, P.ink)
    rect(px + 10, py + 13, 12, 14, pal.wood.base)
    rect(px + 10, py + 19, 12, 2, pal.wall.mortar)
    rect(px + 10, py + 26, 12, 1, pal.wall.mortar)
    -- Água escurecida: superfície turva com um fio de luz.
    rect(px + 10, py + 13, 12, 4, pal.cloth.dark)
    rect(px + 11, py + 14, 6, 1, pal.cloth.base, .55)
    -- Alça erguida e pano deixado escorrendo na borda.
    pixelLine(px + 10, py + 13, px + 16, py + 8, pal.wall.mortar)
    pixelLine(px + 22, py + 13, px + 16, py + 8, pal.wall.mortar)
    rect(px + 21, py + 11, 4, 10, pal.cloth.light)
    rect(px + 21, py + 11, 4, 1, P.ink, .5)
end

-- 'cabra' é o bicho do cercado — o painter 'animal' já a cobre; o alias
-- deixa o id semântico resolver sem depender do kind genérico.
draw.cabra = draw.animal

draw.marco = function(prop, x, y, w, h, pal, time, reduced)
    local cx, foot = x + round(w / 2), y + h - 3
    local top = foot - 220
    local lit = prop.state == 'lit'
    -- Sombra longa e base em três degraus: a pedra cresceu — anuncia-se na
    -- praça muito acima dos telhados das casas.
    rect(cx + 14, foot - 13, 48, 12, Palettes.ink, .2)
    framed(x - 16, foot - 8, w + 32, 12, pal.wall.faceDark, pal.wall.rim)
    framed(x - 8, foot - 15, w + 16, 9, pal.wall.cap, pal.wall.rim)
    framed(x - 2, foot - 20, w + 4, 7, pal.wall.brick, pal.wall.cap)
    -- Haste alta: contorno de tinta, filo de luz a oeste e fiadas de junção
    -- quebrando a subida — monólito trabalhado, não pilastra lisa.
    for sy = top, foot - 20 do
        local inset = sy < top + 18 and round((top + 18 - sy) * .55) or 0
        rect(cx - 23 + inset, sy, 47 - inset * 2, 1, Palettes.ink)
        rect(cx - 21 + inset, sy, 42 - inset * 2, 1, pal.wall.faceDark)
        rect(cx - 19 + inset, sy, 10, 1, pal.wall.cap)
        rect(cx - 9 + inset, sy, 22 - inset, 1, pal.wall.face)
        if (sy - top) % 44 == 32 then
            rect(cx - 21 + inset, sy, 42 - inset * 2, 1, pal.wall.mortar)
        end
    end
    -- Capitel e pedra de coroamento.
    rect(cx - 12, top + 2, 24, 3, pal.wall.cap)
    rect(cx - 2, top - 3, 4, 4, pal.wall.cap)
    rect(cx - 15, top + 24, 2, 60, pal.wall.rim, .35)
    -- Inscrições no terço superior da haste: glifos e os dois nomes.
    for row = 1, 5 do
        local tint = (lit and row == 2) and Palettes.jade.light or pal.wall.brick
        if row == 1 then tint = Palettes.gold.light end
        for glyph = 1, 5 do
            local gx, gy = cx - 13 + glyph * 4, top + 92 + row * 11
            rect(gx, gy, 1, 5, tint)
            rect(gx - 1, gy + (glyph + row) % 3, 3, 1, tint)
        end
    end
    inscriptionFont = inscriptionFont or require('src.pixel_font').new(1)
    local previousFont = G.getFont()
    G.setFont(inscriptionFont)
    for row, name in ipairs({'REFUGIO', 'ANDLAR'}) do
        G.setColor(row == 1 and Palettes.gold.light or (lit and Palettes.jade.light or pal.wall.brick))
        G.print(name, cx - round(inscriptionFont:getWidth(name) / 2), top + 66 + (row - 1) * 13)
    end
    G.setFont(previousFont)
    -- Anel de velas na base: pedestais de pedra com chamas votivas sempre
    -- acesas — a praça cuida da pedra mesmo quando ela ainda dorme.
    for i, dx in ipairs({-34, -17, 17, 34}) do
        local vx, vy = cx + dx, foot - 7 + (i % 2)
        rect(vx - 2, vy - 3, 5, 7, pal.wall.faceDark)
        rect(vx - 2, vy - 3, 5, 1, pal.wall.cap)
        local fl = reduced and .5 or .5 + .5 * math.sin(time * 8.7 + i * 2.2 + x * .1)
        local fh = 3 + (fl > .6 and 1 or 0)
        rect(vx - 1, vy - 4 - fh, 3, fh + 1, Palettes.emberLight, .75 + .25 * fl)
        rect(vx, vy - 3 - fh, 1, 1, P.goldLight, .6 + .4 * fl)
        rect(vx - 3, vy + 3, 7, 2, Palettes.ember, .10 + .14 * fl)
    end
    PixelArt.halo(cx, foot - 12, 40, 14, Palettes.ember, .12)
    if lit then
        PixelArt.halo(cx, top + 110, 34, 52, Palettes.jade.light, .15)
        PixelArt.halo(cx, top + 12, 22, 14, Palettes.jade.light, .18)
    end
end

-- Escadaria transitável é CHÃO, não prop: os vãos do arrimo (escadaMirante,
-- escadaBaixa, rampaForja) são piso caminhável, então assam no canvas do
-- piso (pixel_scene.bake) e saem da ordenação por pés (render) — se ficassem
-- na fila de depth, o retângulo dos degraus pintaria por cima de quem sobe.
-- Sólida continua prop: degrau de decoração/fachada ainda ordena por altura.
local groundKinds = {escadaria = true}
function Props.bakesToGround(prop)
    return groundKinds[prop.kind] == true and not prop.solid
end

draw.escadaria = function(prop, x, y, w, h, pal)
    rect(x, y, w, h, pal.wall.faceDark)
    for sy = 0, h - 1, 10 do
        rect(x + 7, y + sy, w - 14, 7, Palettes.refuge.pathLight)
        rect(x + 7, y + sy, w - 14, 1, pal.wall.rim)
    end
    rect(x, y, 6, h, pal.wall.cap); rect(x + w - 6, y, 6, h, pal.wall.face)
end

draw.parapeito = function(prop, x, y, w, h, pal)
    rect(x, y + h - 13, w, 12, pal.wall.faceDark)
    rect(x, y + h - 17, w, 5, pal.wall.cap)
    rect(x, y + h - 17, w, 1, pal.wall.rim)
    for sx = 0, w - 1, 25 do
        framed(x + sx, y + h - 23, 9, 19, pal.wall.face, pal.wall.rim)
    end
end

draw.arvore = function(prop, x, y, w, h, pal)
    local c, cx, foot = Palettes.refuge, x + round(w / 2), y + h - 4
    -- Copa lançada a sueste no chão: o dossel deita seu perfil como as
    -- casas — três degraus de sombra escorrendo para o lado cego.
    rect(cx + 6, foot - 13, 32, 4, Palettes.ink, .16)
    rect(cx + 16, foot - 9, 22, 3, Palettes.ink, .10)
    rect(cx + 26, foot - 6, 12, 2, Palettes.ink, .07)
    rect(cx - 12, foot - 3, 30, 5, Palettes.ink, .22)
    framed(cx - 4, foot - 36, 9, 36, pal.wood.dark, pal.wood.base)
    pixelLine(cx, foot - 28, cx - 16, foot - 44, pal.wood.base)
    pixelLine(cx, foot - 23, cx + 19, foot - 40, pal.wood.dark)
    -- Broad hand-shaped foliage clusters rather than per-pixel noise.
    for _, cluster in ipairs({{-17,-49,19,13},{12,-45,21,16},{-2,-66,22,17},{0,-44,25,16}}) do
        G.setColor(c.grassDark); G.ellipse('fill', cx + cluster[1], foot + cluster[2], cluster[3], cluster[4])
        G.setColor(c.grass); G.ellipse('fill', cx + cluster[1] - 3, foot + cluster[2] - 4, cluster[3] - 3, cluster[4] - 4)
        rect(cx + cluster[1] - 8, foot + cluster[2] - 8, 10, 2, c.grassLight, .6)
    end
end

-- A marca do Marco no chão: anel de pedrinhas + flecha gravada apontando
-- para o monumento — o cercado ganha um assunto no piso, não só borda.
draw.marcaChao = function(prop, x, y, w, h, pal)
    local cx, cy = x + round(w / 2), y + round(h / 2)
    for a = 0, 7 do
        local sx = cx + round(math.cos(a / 8 * 6.283) * (w * .36))
        local sy = cy + round(math.sin(a / 8 * 6.283) * (h * .30))
        rect(sx, sy, 2, 1, pal.wall.cap)
    end
    -- Flecha gravada apontando ao marco (norte do prop).
    rect(cx - 1, cy - 4, 2, 5, pal.wall.faceDark)
    rect(cx - 2, cy - 5, 4, 2, pal.wall.faceDark)
    rect(cx - 1, cy - 4, 2, 1, Palettes.gold.dark)
end

draw.rocha = function(prop, x, y, w, h, pal)
    for sy = 4, h - 4 do
        local inset = round(math.abs(sy - h * .55) * .42)
        rect(x + inset + 2, y + sy, w - inset * 2 - 4, 1,
            sy < h * .5 and pal.wall.cap or pal.wall.faceDark)
    end
    rect(x + 12, y + round(h * .45), w - 24, 2, pal.wall.rim)
    rect(x + 8, y + h - 6, w - 16, 4, Palettes.refuge.grassDark)
end

-- Fumaça de cenário: âncora da coluna relativa à área do prop e volume
-- relativo (forja tosse muito, braseiro fumega, vela não fuma). O painter
-- já solta fios na chaminé; a coluna ambiente (render) dá corpo ao volume.
-- Frações medidas na chaminé pintada: forja ~x+w-36, cozinha ~x+w-30.
local smokeSources = {
    forjaCasa = {x = .77, y = -.14, vol = 3},
    cozinhaCasa = {x = .81, y = -.11, vol = 1.8},
    fogao = {x = .5, y = .18, vol = 1.3},
    braseiro = {x = .5, y = .3, vol = .9},
    bigorna = {x = .72, y = .74, vol = .7},
    capelaCasa = {x = .5, y = .68, vol = .5},
    altar = {x = .5, y = .26, vol = .5},
    lustre = {x = .5, y = .33, vol = .5},
    mesaVelas = {x = .78, y = .1, vol = .4},
    mesa = {x = .78, y = .1, vol = .4},
}
function Props.smokeAnchor(prop)
    if prop.state == 'taken' or prop.state == 'removed' or prop.state == 'cold' or prop.state == 'murky' or prop.state == 'quiet'
        then return nil end
    local src = smokeSources[prop.id] or smokeSources[prop.kind]
    if not src then return nil end
    local dim = prop.state == 'covered' and .6 or 1
    local vol = src.vol * dim * (prop.state == 'lit' and 1.5 or 1)
    -- Fração da ÁREA do prop (como nos painters: px + w * frac), não do
    -- tile — a chaminé da forja fica perto da ponta direita da casa.
    return (prop.x - 1) * 32 + src.x * (prop.w or 1) * 32,
        (prop.y - 1) * 32 + src.y * (prop.h or 1) * 32, vol
end

-- Objetos altos que lançam sombra de viés contra a luz: valor = altura
-- visual estimada em px (a sombra deita proporcional a ela). O retorno é
-- centro-x da base, pé-y, largura da base e a altura — a câmera decide o
-- lado oposto à fonte mais próxima.
local shadowCasters = {
    casa = 56, capelaCasa = 56, camasCasa = 56, escolaCasa = 56,
    cozinhaCasa = 56, forjaCasa = 56,
    marco = 190, arvore = 62, postoVigia = 74, espantalho = 30,
    armarioTecnico = 38, divisoria = 32, divisoriaAberta = 32,
    prateleira = 34, balcao = 24, bancada = 22,
    sepultura = 14, cova = 14, lapide = 18, caixao = 16,
    poco = 26, pocoRua = 26, grade = 26, comportaPortao = 26,
    volante = 30, placa = 20, cartaz = 20,
}
function Props.shadowCaster(prop)
    local hgt = shadowCasters[prop.id] or shadowCasters[prop.kind]
    if not hgt or prop.state == 'taken' then return nil end
    local w, h = (prop.w or 1) * 32, (prop.h or 1) * 32
    return (prop.x - 1) * 32 + w / 2, (prop.y - 1) * 32 + h - 3, w, hgt
end

-- ── Ícones contextuais do diálogo ────────────────────────────────────
-- Miniaturas do objeto/lugar que o node cita ('casaco', 'marco', 'cova')
-- — mesmas rampas dos painters grandes, desenhadas num quadrado de
-- 16·u px (u=1 → 16×16, u=2 → 32×32) para acompanhar a escala inteira.
local icons = {}
local function i(x, y, u, dx, dy, w, h, c, a)
    rect(x + dx * u, y + dy * u, w * u, h * u, c, a)
end

icons.sepultura = function(x, y, u, pal)
    i(x, y, u, 2, 6, 12, 7, P.ink); i(x, y, u, 3, 7, 10, 5, P.abyss)
    i(x, y, u, 3, 7, 10, 1, P.stoneDark); i(x, y, u, 3, 11, 10, 1, P.stoneDark)
    i(x, y, u, 1, 4, 14, 2, pal.wall.cap); i(x, y, u, 1, 4, 14, 1, pal.wall.rim)
    i(x, y, u, 6, 1, 4, 3, pal.wall.brick); i(x, y, u, 6, 1, 4, 1, pal.wall.cap)
end
icons.lapide = function(x, y, u, pal)
    i(x, y, u, 4, 2, 8, 12, P.ink)
    i(x, y, u, 5, 3, 6, 10, pal.wall.brick); i(x, y, u, 5, 3, 6, 2, pal.wall.cap)
    i(x, y, u, 6, 7, 4, 1, pal.wall.mortar); i(x, y, u, 7, 9, 2, 1, pal.wall.mortar)
    i(x, y, u, 3, 14, 10, 1, pal.wall.faceDark)
end
icons.tampa = function(x, y, u, pal)
    i(x, y, u, 2, 8, 12, 5, P.ink); i(x, y, u, 3, 9, 10, 3, pal.wall.brick)
    i(x, y, u, 3, 9, 10, 1, pal.wall.cap)
    i(x, y, u, 7, 4, 3, 5, pal.wall.brick); i(x, y, u, 7, 4, 3, 1, pal.wall.cap)
    i(x, y, u, 4, 10, 3, 1, P.ink, .7); i(x, y, u, 10, 11, 3, 1, P.ink, .7)
end
icons.caixao = function(x, y, u, pal)
    i(x, y, u, 5, 2, 6, 2, P.ink); i(x, y, u, 3, 4, 10, 8, P.ink); i(x, y, u, 4, 12, 8, 2, P.ink)
    i(x, y, u, 6, 3, 4, 1, pal.wood.base); i(x, y, u, 4, 5, 8, 6, pal.wood.base)
    i(x, y, u, 5, 12, 6, 1, pal.wood.dark); i(x, y, u, 5, 6, 6, 1, pal.wood.dark)
    i(x, y, u, 7, 8, 2, 2, pal.wall.cap)
end
icons.flores = function(x, y, u, pal)
    for f = 0, 2 do
        local fx = 4 + f * 4
        i(x, y, u, fx, 8, 1, 5, pal.moss)
        i(x, y, u, fx - 1, 6, 3, 2, pal.petal)
        i(x, y, u, fx, 6, 1, 1, P.emberLight)
    end
    i(x, y, u, 3, 13, 10, 1, pal.wall.faceDark)
end
icons.horta = function(x, y, u, pal)
    i(x, y, u, 2, 6, 12, 8, pal.wood.dark); i(x, y, u, 3, 7, 10, 6, pal.floor.dark)
    for r = 0, 1 do for f = 0, 3 do
        i(x, y, u, 4 + f * 2, 8 + r * 4, 1, 2, pal.moss)
        i(x, y, u, 4 + f * 2, 7 + r * 4, 1, 1, pal.moss)
    end end
end
icons.casaco = function(x, y, u, pal)
    i(x, y, u, 3, 5, 10, 8, P.ink); i(x, y, u, 4, 6, 8, 6, pal.cloth.dark)
    i(x, y, u, 4, 6, 8, 1, pal.cloth.base); i(x, y, u, 6, 4, 4, 2, pal.cloth.dark)
    i(x, y, u, 4, 9, 3, 3, pal.cloth.base); i(x, y, u, 5, 10, 1, 1, pal.petal)
    i(x, y, u, 10, 8, 2, 1, pal.cloth.light, .8)
end
icons.ferramenta = function(x, y, u, pal)
    i(x, y, u, 4, 11, 2, 3, pal.wood.dark); i(x, y, u, 10, 2, 2, 8, pal.wood.dark)
    i(x, y, u, 3, 3, 6, 3, pal.wall.cap); i(x, y, u, 3, 3, 2, 3, pal.wall.rim)
    i(x, y, u, 9, 9, 5, 2, pal.wall.brick); i(x, y, u, 12, 9, 2, 5, pal.wall.faceDark)
end
icons.bancada = function(x, y, u, pal)
    i(x, y, u, 2, 8, 12, 3, pal.wood.base); i(x, y, u, 2, 8, 12, 1, pal.wood.light)
    i(x, y, u, 3, 11, 2, 4, P.ink); i(x, y, u, 11, 11, 2, 4, P.ink)
    i(x, y, u, 5, 5, 3, 2, pal.wall.cap); i(x, y, u, 10, 4, 2, 4, pal.wall.brick)
end
icons.altar = function(x, y, u, pal)
    i(x, y, u, 4, 8, 8, 6, P.ink); i(x, y, u, 5, 9, 6, 5, pal.wall.brick)
    i(x, y, u, 4, 8, 8, 1, pal.wall.cap)
    i(x, y, u, 5, 4, 1, 4, pal.wood.dark); i(x, y, u, 10, 4, 1, 4, pal.wood.dark)
    i(x, y, u, 5, 2, 1, 2, P.emberLight); i(x, y, u, 10, 2, 1, 2, P.emberLight)
    i(x, y, u, 5, 3, 1, 1, P.white); i(x, y, u, 10, 3, 1, 1, P.white)
end
icons.cisterna = function(x, y, u, pal)
    i(x, y, u, 2, 5, 12, 9, P.ink); i(x, y, u, 3, 6, 10, 7, pal.wall.brick)
    i(x, y, u, 3, 6, 10, 2, pal.wall.cap)
    i(x, y, u, 4, 8, 8, 4, P.abyss); i(x, y, u, 5, 9, 6, 1, P.jadeLight)
    i(x, y, u, 6, 10, 3, 1, P.jade)
end
icons.canal = function(x, y, u, pal)
    i(x, y, u, 1, 5, 14, 8, P.ink)
    i(x, y, u, 2, 6, 12, 6, pal.wall.brick); i(x, y, u, 2, 6, 12, 1, pal.wall.cap)
    i(x, y, u, 3, 8, 10, 3, P.jadeDark); i(x, y, u, 4, 9, 6, 1, P.jadeLight)
end
icons.poco = function(x, y, u, pal)
    i(x, y, u, 4, 6, 8, 8, P.ink); i(x, y, u, 5, 7, 6, 6, pal.wall.brick)
    i(x, y, u, 5, 7, 6, 1, pal.wall.cap); i(x, y, u, 6, 8, 4, 3, P.abyss)
    i(x, y, u, 4, 2, 1, 4, pal.wood.dark); i(x, y, u, 11, 2, 1, 4, pal.wood.dark)
    i(x, y, u, 3, 2, 10, 1, pal.wood.base)
end
icons.placa = function(x, y, u, pal)
    i(x, y, u, 7, 9, 2, 5, pal.wood.dark)
    i(x, y, u, 3, 2, 10, 7, P.ink); i(x, y, u, 4, 3, 8, 5, pal.wood.base)
    i(x, y, u, 4, 3, 8, 1, pal.wood.light)
    i(x, y, u, 5, 5, 5, 1, P.ink); i(x, y, u, 5, 6, 3, 1, P.ink)
end
icons.cartaz = function(x, y, u, pal)
    i(x, y, u, 4, 3, 8, 11, P.ink); i(x, y, u, 5, 4, 6, 9, pal.cloth.light)
    i(x, y, u, 5, 4, 6, 1, pal.cloth.base)
    i(x, y, u, 6, 6, 4, 1, P.ink, .8); i(x, y, u, 6, 8, 3, 1, P.ink, .8)
    i(x, y, u, 6, 10, 4, 1, P.ink, .8); i(x, y, u, 7, 2, 2, 1, pal.wall.cap)
end
icons.livro = function(x, y, u, pal)
    i(x, y, u, 2, 5, 12, 8, P.ink)
    i(x, y, u, 3, 6, 5, 6, pal.cloth.light); i(x, y, u, 8, 6, 5, 6, pal.cloth.light)
    i(x, y, u, 3, 6, 10, 1, pal.cloth.base); i(x, y, u, 7, 6, 1, 7, P.ink, .6)
    i(x, y, u, 4, 8, 3, 1, P.ink, .7); i(x, y, u, 9, 8, 3, 1, P.ink, .7)
    i(x, y, u, 4, 10, 4, 1, P.ink, .7); i(x, y, u, 9, 10, 3, 1, P.ink, .7)
end
icons.mapa = function(x, y, u, pal)
    i(x, y, u, 3, 4, 10, 9, P.ink); i(x, y, u, 4, 5, 8, 7, pal.cloth.light)
    i(x, y, u, 3, 4, 2, 9, pal.wood.dark); i(x, y, u, 11, 4, 2, 9, pal.wood.dark)
    i(x, y, u, 6, 7, 1, 1, pal.moss); i(x, y, u, 8, 9, 2, 1, pal.moss)
    i(x, y, u, 9, 6, 1, 1, P.danger)
end
icons.casa = function(x, y, u, pal)
    i(x, y, u, 4, 8, 8, 6, pal.wall.face); i(x, y, u, 4, 8, 8, 1, pal.wall.cap)
    i(x, y, u, 3, 3, 10, 5, P.ink)
    for r = 0, 4 do
        i(x, y, u, 3 + r, 3 + r, 10 - r * 2, 1, r < 2 and pal.wall.cap or pal.wall.brick)
    end
    i(x, y, u, 7, 10, 2, 4, pal.wood.dark)
end
icons.porta = function(x, y, u, pal)
    i(x, y, u, 4, 3, 8, 11, P.ink); i(x, y, u, 5, 4, 6, 10, P.abyss)
    i(x, y, u, 4, 3, 8, 1, pal.wall.cap); i(x, y, u, 4, 3, 1, 11, pal.wall.brick)
    i(x, y, u, 11, 3, 1, 11, pal.wall.brick); i(x, y, u, 6, 5, 4, 8, pal.wood.dark)
    i(x, y, u, 9, 9, 1, 1, P.goldLight)
end
icons.forja = function(x, y, u, pal)
    i(x, y, u, 3, 11, 10, 3, pal.wall.faceDark); i(x, y, u, 4, 8, 8, 3, pal.wall.brick)
    i(x, y, u, 3, 8, 10, 1, pal.wall.cap)
    i(x, y, u, 5, 5, 6, 3, P.ink); i(x, y, u, 6, 6, 4, 1, P.ember)
    i(x, y, u, 7, 5, 2, 1, P.emberLight); i(x, y, u, 8, 5, 1, 1, P.white)
end
icons.engrenagem = function(x, y, u, pal)
    i(x, y, u, 7, 3, 2, 10, pal.wall.brick); i(x, y, u, 3, 7, 10, 2, pal.wall.brick)
    i(x, y, u, 5, 5, 6, 6, pal.wall.brick); i(x, y, u, 6, 6, 4, 4, P.ink)
    i(x, y, u, 4, 4, 2, 2, pal.wall.brick); i(x, y, u, 10, 4, 2, 2, pal.wall.brick)
    i(x, y, u, 4, 10, 2, 2, pal.wall.brick); i(x, y, u, 10, 10, 2, 2, pal.wall.brick)
end
icons.carro = function(x, y, u, pal)
    i(x, y, u, 3, 6, 9, 5, P.ink); i(x, y, u, 4, 7, 7, 3, pal.wood.base)
    i(x, y, u, 4, 7, 7, 1, pal.wood.light); i(x, y, u, 12, 7, 3, 1, pal.wood.dark)
    i(x, y, u, 4, 12, 3, 3, P.ink); i(x, y, u, 5, 12, 1, 1, pal.wall.mortar)
    i(x, y, u, 9, 12, 3, 3, P.ink); i(x, y, u, 10, 12, 1, 1, pal.wall.mortar)
end
icons.banca = function(x, y, u, pal)
    i(x, y, u, 2, 5, 12, 3, pal.cloth.base); i(x, y, u, 2, 5, 12, 1, pal.cloth.light)
    i(x, y, u, 2, 7, 1, 3, pal.wood.dark); i(x, y, u, 13, 7, 1, 3, pal.wood.dark)
    i(x, y, u, 3, 10, 10, 4, pal.wood.base); i(x, y, u, 3, 10, 10, 1, pal.wood.light)
    i(x, y, u, 5, 12, 2, 1, pal.petal); i(x, y, u, 9, 12, 3, 1, pal.moss)
end
icons.frasco = function(x, y, u, pal)
    i(x, y, u, 7, 3, 2, 3, P.ink); i(x, y, u, 7, 3, 2, 1, pal.wall.cap)
    i(x, y, u, 5, 6, 6, 7, P.ink); i(x, y, u, 6, 7, 4, 5, P.violetDark)
    i(x, y, u, 6, 9, 4, 3, P.violet); i(x, y, u, 6, 7, 1, 2, P.violetLight, .8)
end
icons.regua = function(x, y, u, pal)
    i(x, y, u, 3, 4, 2, 10, P.ink); i(x, y, u, 3, 4, 1, 10, pal.wood.base)
    for r = 0, 3 do i(x, y, u, 4, 5 + r * 2, 2, 1, pal.wood.light) end
    i(x, y, u, 9, 11, 4, 2, pal.wall.brick); i(x, y, u, 9, 11, 4, 1, pal.wall.cap)
end
icons.volante = function(x, y, u, pal)
    i(x, y, u, 7, 3, 2, 10, pal.wall.mortar); i(x, y, u, 3, 7, 10, 2, pal.wall.mortar)
    i(x, y, u, 5, 5, 6, 6, P.ink); i(x, y, u, 6, 6, 4, 4, pal.wall.brick)
    i(x, y, u, 7, 7, 2, 2, pal.wall.rim)
    i(x, y, u, 6, 13, 4, 1, pal.wall.faceDark)
end
icons.filtro = function(x, y, u, pal)
    i(x, y, u, 3, 3, 10, 10, P.ink); i(x, y, u, 4, 4, 8, 8, pal.wall.brick)
    i(x, y, u, 5, 5, 6, 6, P.abyss); i(x, y, u, 6, 7, 4, 3, P.jadeDark)
    i(x, y, u, 7, 8, 2, 1, P.jadeLight)
end
icons.cortina = function(x, y, u, pal)
    i(x, y, u, 3, 2, 10, 2, pal.wood.dark)
    i(x, y, u, 3, 4, 4, 10, pal.cloth.base); i(x, y, u, 9, 4, 4, 10, pal.cloth.base)
    i(x, y, u, 4, 4, 2, 10, pal.cloth.dark); i(x, y, u, 10, 4, 2, 10, pal.cloth.dark)
    i(x, y, u, 3, 13, 4, 1, pal.cloth.light); i(x, y, u, 9, 13, 4, 1, pal.cloth.light)
    i(x, y, u, 7, 4, 2, 10, P.ink)
end
icons.armario = function(x, y, u, pal)
    i(x, y, u, 4, 3, 8, 11, P.ink); i(x, y, u, 5, 4, 6, 9, pal.wood.base)
    i(x, y, u, 5, 4, 6, 1, pal.wood.light); i(x, y, u, 8, 4, 1, 9, pal.wood.dark)
    i(x, y, u, 6, 8, 1, 1, P.goldLight); i(x, y, u, 9, 8, 1, 1, P.goldLight)
end
icons.quadro = function(x, y, u, pal)
    i(x, y, u, 3, 4, 10, 8, P.ink); i(x, y, u, 4, 5, 8, 6, pal.wood.base)
    i(x, y, u, 5, 6, 6, 4, pal.wall.faceDark)
    i(x, y, u, 5, 6, 6, 1, pal.wall.cap, .8)
    i(x, y, u, 7, 7, 3, 2, pal.petal); i(x, y, u, 8, 7, 1, 1, P.emberLight)
end
icons.escora = function(x, y, u, pal)
    i(x, y, u, 3, 12, 10, 2, pal.wall.faceDark); i(x, y, u, 3, 12, 10, 1, pal.wall.brick)
    pixelLine(x + 6 * u, y + 12 * u, x + 10 * u, y + 3 * u, pal.wood.base)
    pixelLine(x + 7 * u, y + 12 * u, x + 11 * u, y + 3 * u, pal.wood.dark)
    i(x, y, u, 10, 10, 4, 3, pal.wall.brick); i(x, y, u, 10, 10, 4, 1, pal.wall.cap)
end
icons.vitrine = function(x, y, u, pal)
    i(x, y, u, 3, 4, 10, 10, P.ink); i(x, y, u, 4, 5, 8, 8, P.abyss)
    i(x, y, u, 4, 5, 8, 1, pal.wall.cap); i(x, y, u, 5, 6, 1, 6, P.jadeLight, .5)
    i(x, y, u, 7, 9, 3, 3, pal.petal); i(x, y, u, 8, 9, 1, 1, P.emberLight)
end
icons.instrumento = function(x, y, u, pal)
    i(x, y, u, 5, 8, 6, 5, P.ink); i(x, y, u, 6, 9, 4, 3, pal.wood.base)
    i(x, y, u, 7, 9, 2, 2, P.ink)
    pixelLine(x + 9 * u, y + 9 * u, x + 12 * u, y + 3 * u, pal.wood.dark)
    i(x, y, u, 11, 2, 2, 2, pal.wood.dark); i(x, y, u, 10, 7, 1, 4, pal.wall.cap, .7)
end
icons.toldo = function(x, y, u, pal)
    for s = 0, 4 do
        i(x, y, u, 2 + s * 2 + 1, 4, 2, 4, s % 2 == 0 and pal.cloth.base or pal.cloth.light)
    end
    i(x, y, u, 2, 4, 12, 1, pal.cloth.dark); i(x, y, u, 2, 8, 12, 1, pal.wood.dark)
    i(x, y, u, 3, 9, 1, 4, pal.wood.dark); i(x, y, u, 12, 9, 1, 4, pal.wood.dark)
end
icons.musgo = function(x, y, u, pal)
    i(x, y, u, 3, 9, 10, 4, pal.wall.brick); i(x, y, u, 3, 9, 10, 1, pal.wall.cap)
    for f = 0, 5 do
        i(x, y, u, 4 + f * 2, 7 + (f % 2), 1, 2, pal.moss)
    end
    i(x, y, u, 5, 8, 2, 1, pal.moss); i(x, y, u, 9, 8, 2, 1, pal.moss)
end
icons.cadeira = function(x, y, u, pal)
    i(x, y, u, 5, 3, 2, 8, pal.wood.dark); i(x, y, u, 4, 4, 2, 1, pal.wood.light)
    i(x, y, u, 5, 9, 6, 2, pal.wood.base); i(x, y, u, 5, 9, 6, 1, pal.wood.light)
    i(x, y, u, 5, 11, 1, 3, P.ink); i(x, y, u, 10, 11, 1, 3, P.ink)
end
icons.banco = function(x, y, u, pal)
    i(x, y, u, 3, 8, 10, 2, pal.wood.base); i(x, y, u, 3, 8, 10, 1, pal.wood.light)
    i(x, y, u, 4, 10, 2, 4, P.ink); i(x, y, u, 10, 10, 2, 4, P.ink)
    i(x, y, u, 6, 11, 4, 1, pal.wood.dark)
end
icons.marco = function(x, y, u, pal)
    i(x, y, u, 5, 1, 6, 12, P.ink); i(x, y, u, 6, 2, 4, 10, pal.wall.brick)
    i(x, y, u, 6, 2, 1, 10, pal.wall.cap); i(x, y, u, 6, 1, 4, 1, pal.wall.cap)
    i(x, y, u, 7, 5, 2, 1, P.goldLight); i(x, y, u, 7, 8, 2, 1, P.jadeLight)
    i(x, y, u, 4, 13, 8, 2, pal.wall.faceDark); i(x, y, u, 3, 14, 10, 1, pal.wall.brick)
end
icons.vista = function(x, y, u, pal)
    i(x, y, u, 2, 3, 3, 3, P.emberLight); i(x, y, u, 2, 3, 2, 2, P.white)
    i(x, y, u, 1, 9, 14, 5, pal.wall.faceDark)
    for m = 0, 3 do
        i(x, y, u, 1 + m * 4, 7 + m % 2, 4, 3, m % 2 == 0 and pal.wall.brick or pal.wall.mortar)
    end
    i(x, y, u, 1, 9, 14, 1, pal.wall.cap)
end
icons.cama = function(x, y, u, pal)
    i(x, y, u, 3, 6, 10, 8, P.ink); i(x, y, u, 4, 7, 8, 6, pal.cloth.dark)
    i(x, y, u, 4, 7, 8, 2, pal.cloth.light); i(x, y, u, 4, 7, 3, 2, P.white)
    i(x, y, u, 4, 10, 8, 1, pal.cloth.base); i(x, y, u, 7, 11, 5, 2, pal.cloth.base)
end
icons.mesa = function(x, y, u, pal)
    i(x, y, u, 2, 7, 12, 3, pal.wood.base); i(x, y, u, 2, 7, 12, 1, pal.wood.light)
    i(x, y, u, 3, 10, 2, 4, P.ink); i(x, y, u, 11, 10, 2, 4, P.ink)
    i(x, y, u, 6, 4, 1, 3, pal.wood.dark); i(x, y, u, 6, 3, 1, 1, P.emberLight)
end
icons.bau = function(x, y, u, pal)
    i(x, y, u, 3, 6, 10, 8, P.ink); i(x, y, u, 4, 7, 8, 6, pal.wood.base)
    i(x, y, u, 4, 7, 8, 2, pal.wood.dark); i(x, y, u, 7, 8, 2, 3, P.goldLight)
    i(x, y, u, 4, 13, 8, 1, pal.wood.dark)
end
icons.cabra = function(x, y, u, pal)
    i(x, y, u, 5, 6, 7, 6, P.ink); i(x, y, u, 6, 7, 5, 5, pal.wall.face)
    i(x, y, u, 6, 7, 5, 1, pal.wall.cap)
    pixelLine(x + 6 * u, y + 6 * u, x + 4 * u, y + 3 * u, pal.wood.dark)
    pixelLine(x + 10 * u, y + 6 * u, x + 12 * u, y + 3 * u, pal.wood.dark)
    i(x, y, u, 7, 9, 1, 1, P.ink); i(x, y, u, 10, 9, 1, 1, P.ink)
    i(x, y, u, 8, 11, 2, 1, pal.wall.cap)
end
icons.prateleira = function(x, y, u, pal)
    i(x, y, u, 3, 4, 10, 1, pal.wood.base); i(x, y, u, 3, 9, 10, 1, pal.wood.base)
    i(x, y, u, 4, 2, 2, 2, pal.cloth.base); i(x, y, u, 8, 2, 3, 2, pal.wall.cap)
    i(x, y, u, 5, 6, 3, 3, pal.petal); i(x, y, u, 9, 7, 2, 2, pal.cloth.dark)
    i(x, y, u, 4, 12, 8, 1, pal.wood.dark)
end
icons.vela = function(x, y, u, pal)
    i(x, y, u, 7, 7, 2, 6, P.white); i(x, y, u, 7, 7, 2, 1, pal.cloth.light)
    i(x, y, u, 7, 4, 2, 3, P.emberLight); i(x, y, u, 7, 4, 1, 1, P.white)
    i(x, y, u, 5, 13, 6, 1, pal.wall.faceDark); i(x, y, u, 6, 12, 4, 1, pal.wood.dark)
end
icons.braseiro = function(x, y, u, pal)
    i(x, y, u, 4, 7, 8, 4, P.ink); i(x, y, u, 5, 8, 6, 2, pal.wall.faceDark)
    i(x, y, u, 5, 5, 6, 3, P.ember); i(x, y, u, 6, 5, 3, 2, P.emberLight)
    i(x, y, u, 7, 5, 1, 1, P.white)
    pixelLine(x + 6 * u, y + 11 * u, x + 4 * u, y + 14 * u, P.ink)
    pixelLine(x + 10 * u, y + 11 * u, x + 12 * u, y + 14 * u, P.ink)
end
icons.rocha = function(x, y, u, pal)
    for sy = 4, 12 do
        local inset = round(math.abs(sy - 8) * .7)
        i(x, y, u, 3 + inset, sy, 10 - inset * 2, 1,
            sy < 8 and pal.wall.cap or pal.wall.faceDark)
    end
    i(x, y, u, 5, 7, 5, 1, pal.wall.rim)
end

-- Spot de hotspot → ícone: cobre LoreC.hotspot (campanha legada) e
-- Refugio.hotspot (arco novo). Ausência de entrada = sem imagem, nada quebra.
local dialogIcons = {
    sepultura = 'sepultura', tampa = 'tampa', lapide = 'lapide',
    lapideProt = 'lapide', caixao = 'caixao', flores = 'flores',
    canteiros = 'flores', hortaRefugio = 'horta', canteiroRefugio = 'horta',
    pano = 'ferramenta', ferramentas = 'ferramenta', torno = 'ferramenta',
    preparoRefugio = 'ferramenta', pertences = 'casaco',
    bancada = 'bancada', bancadaBrina = 'bancada',
    altar = 'altar', mesaVelas = 'vela', cisterna = 'cisterna',
    aguaRefugio = 'cisterna', pocoRua = 'poco', canalTeste = 'canal',
    filtro = 'filtro', volante = 'volante',
    placaOficina = 'placa', placaEma = 'placa', placaAlojamentos = 'placa',
    interdicao = 'placa', placaFundacao = 'placa', placaHub = 'placa',
    placaAndlar = 'placa', placaRotas = 'placa', placaDescida = 'placa',
    placaReservatorio = 'placa', placaSaloes = 'placa', placaMirante = 'placa',
    jornalTurno = 'livro', registroOficina = 'livro', arquivo = 'livro',
    programa = 'livro', laudo = 'livro', recibo = 'livro',
    escolaRefugio = 'livro', esquema = 'mapa', plantaSaloes = 'mapa',
    alojamento = 'casa', saidaDanificada = 'porta', saidaOficina = 'porta',
    portalOficinas = 'porta', portalMercado = 'porta',
    portalReservatorio = 'porta', portalSaloes = 'porta',
    hallPassagens = 'porta', ensaio = 'porta', fundacaoLimite = 'porta',
    oficinaCentral = 'forja', forja = 'forja', pecas = 'engrenagem',
    carro = 'carro', bancaCasal = 'banca', residuo = 'frasco',
    regua = 'regua', cortina = 'cortina', armarioTecnico = 'armario',
    moldura = 'quadro', escora = 'escora', fundacao = 'escora',
    divisorias = 'vitrine', instrumento = 'instrumento', toldo = 'toldo',
    musgo = 'musgo', cadeira = 'cadeira', bancoCasal = 'banco',
    bancoVelorio = 'banco', bancoDescida = 'banco', oferendaRefugio = 'banco',
    marcoRefugio = 'marco', retornoAndlar = 'marco', marco = 'marco',
    marcoAndlar = 'marco', miranteRefugio = 'vista', terracoRefugio = 'vista',
    descansoRefugio = 'cama', camasRefugio = 'cama', refeicaoRefugio = 'mesa',
    bauRefugio = 'bau', cabraRefugio = 'cabra', prateleiraRefugio = 'prateleira',
    cartaz = 'cartaz', cartazRefugio = 'cartaz', rochaMirante = 'rocha',
    rochaAndlar = 'rocha',
}
function Props.dialogIcon(id) return dialogIcons[id] end

-- Desenha o ícone `name` num quadrado de 16·u px em (x, y). Falso quando o
-- nome não tem painter — o diálogo segue sem imagem.
function Props.icon(name, x, y, u, pal)
    local painter = icons[name]
    if not painter then return false end
    painter(round(x), round(y), u or 1, pal or Palettes.regions.default)
    return true
end

function Props.lightAnchor(prop, w, h)
    if prop.state == 'taken' or prop.state == 'removed' or prop.state == 'cold' or prop.state == 'murky' or prop.state == 'quiet'
        then return nil end
    -- Id vence kind, como no painter: 'filtroPedra' (kind 'grade') ancora luz.
    local src = lightSources[prop.id] or lightSources[prop.kind]
    if not src then return nil end
    local dim = 1
    if prop.state == 'covered' then
        if not (emberKeeps[prop.id] or emberKeeps[prop.kind]) then return nil end
        dim = .55
    end
    -- Fração da área do prop (como nos painters: px + w * frac) — em prop
    -- multi-tile a âncora aterrissa na boca da fonte, não na 1ª célula.
    return (prop.x - 1) * 32 + src.x * (prop.w or 1) * 32,
        (prop.y - 1) * 32 + src.y * (prop.h or 1) * 32, src.tint, src.r * dim
end

function Props.draw(prop, px, py, w, h, pal, time, reducedMotion)
    if prop.state == 'taken' then return end
    -- Id vence kind: o Pátio apoia ids de ficha sobre kinds genéricos
    -- ('roda' sobre 'cisterna', 'toldoFeirante' sobre 'pano') — o objeto
    -- desenha pelo papel que ele cumpre no mapa, não pelo placeholder.
    local painter = draw[prop.id] or draw[prop.kind]
    if painter then
        local src = lightSources[prop.id] or lightSources[prop.kind]
        local dim = 1
        if prop.state == 'covered' then
            -- Brasa de ofício não apaga em 'covered': halo menor e mais
            -- fraco, mas presente — a forja fumega mesmo dormida.
            if not (src and (emberKeeps[prop.id] or emberKeeps[prop.kind])) then src = nil end
            dim = .55
        end
        if src and prop.state ~= 'cold' and prop.state ~= 'murky' and prop.state ~= 'quiet' then
            local fl = reducedMotion and .85
                or .78 + .22 * math.sin((time or 0) * 7.3 + (prop.x or 0) * 1.7)
            -- Rampa por fonte: núcleo claro → anel médio → borda dithered.
            local core = src.tint == P.ember and P.emberLight or P.white
            PixelArt.lightPool(px + (w or 32) * src.x, py + (h or 32) * src.y,
                math.floor(src.r * dim), math.floor(src.r * .7 * dim), src.tint,
                .42 * fl * dim, core)
        end
        painter(prop, px, py, w or 32, h or 32, pal or Palettes.regions.default,
            time or 0, reducedMotion or false)
    end
end

function Props.selfCheck()
    for kind, painter in pairs(draw) do
        assert(type(painter) == 'function', 'prop painter: ' .. kind)
        painter({kind = kind}, 0, 0, 64, 32, Palettes.regions.default, 0, false)
    end
    return true
end

return Props
