-- CASA_TELHADO — faixa isolada de telhado/beiral, 128x64, origem
-- topleft. Para cobrir fachadas compostas de peças menores quando o
-- layout pede topo extra: cumeeira no alto, ardósia em fiadas
-- desencontradas, telha falta (ripas à mostra), musgo nas baixadas,
-- fascia + verso do beiral e a beirada de sombra que se desfaz para
-- baixo — a última dezena de linhas é a sombra que o beiral deita no
-- que estiver embaixo, dissolvida em pontos até sumir.

local Lib = require('src.sprites.casa_lib')

local A = Lib.canvas(128, 64)
local function hsh(x, y) return (x * 31 + y * 17) % 13 end

-- Cumeeira: cap de telha corrida, juntas desencontradas das fiadas.
for x = 1, 128 do
    A.set(x, 1, x % 7 == 0 and 'r' or 'T')
    A.set(x, 2, (x + 3) % 7 == 0 and 'r' or 't')
end

-- Campo de ardósia: fiadas de 6px, telhas de 8px, deslocamento meia
-- telha por fiada — contínuo na largura inteira.
Lib.telhado(A, 3, 50, { curso = 6, telha = 8 })

-- Vergas: a encosta morre nas duas pontas em sombra.
for y = 1, 50 do
    A.set(1, y, 'r'); A.set(2, y, 'r')
    A.set(127, y, 'r'); A.set(128, y, 'r')
end

-- Telha falta: as ripas de madeira aparecem onde a ardósia caiu.
for y = 29, 33 do
    for x = 38, 44 do
        local dx = math.min(x - 38, 44 - x)
        local dy = math.min(y - 29, 33 - y)
        if dx + dy + (hsh(x, y) % 3) >= 2 then
            A.set(x, y, hsh(x, y) < 4 and 'k' or 'x')
        end
    end
end

-- Musgo criando nas baixadas entre as telhas.
for _, m in ipairs { { 10, 38, 9, 4 }, { 58, 18, 7, 3 }, { 104, 44, 8, 4 } } do
    for y = m[2], m[2] + m[4] - 1 do
        for x = m[1], m[1] + m[3] - 1 do
            if hsh(x, y) < 7 then A.set(x, y, 'g') end
        end
    end
end

-- Beiral: sombra da última fiada, lip iluminado, fascia, verso fundo.
A.rect(1, 51, 128, 1, 'r')
A.rect(1, 52, 128, 1, 'T')
A.rect(1, 53, 128, 1, 'x')
A.rect(1, 54, 128, 3, 'R')

-- Beirada de sombra: contato duro e dissolução em pontos — cai sobre o
-- que estiver embaixo sem virar tarja.
A.rect(1, 57, 128, 1, 'k')
for x = 1, 128 do
    if hsh(x, 58) < 9 then A.set(x, 58, 'k') end
    if hsh(x, 59) < 6 then A.set(x, 59, 'k') end
    if hsh(x, 60) < 4 then A.set(x, 60, 'k') end
    if hsh(x, 61) < 2 then A.set(x, 61, 'k') end
end

return {
    name = 'casa_telhado',
    w = 128, h = 64,
    origin = 'topleft',
    legend = Lib.legend(),
    layers = {
        { name = 'telhado', h = 12, albedo = A:out() },
    },
}
