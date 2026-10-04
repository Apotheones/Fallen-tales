-- Região 6: Quartos da Fundação (docs/mapas/06_ALOJAMENTOS.md)
-- STUB de passagem: os corredores inferior (Reservatório) e superior (Salões)
-- convergem aqui quando 'passagemFundacao' estiver alta. Só a plataforma de
-- chegada e os dois retornos existem antes da planta completa (MARCO 3).
return {
    id = 'fundacao', uid = 7, name = 'QUARTOS DA FUNDAÇÃO', w = 15, h = 13,
    spawn = {x = 7, y = 6},
    arrivals = {
        reservatorio = {x = 7, y = 3, dx = 0, dy = 1},
        saloes = {x = 7, y = 10, dx = 0, dy = -1},
        hub = {x = 7, y = 6, dx = 0, dy = 1},
    },
    carve = {
        {x = 4, y = 3, w = 7, h = 8},    -- vestíbulo entre os dois acessos
    },
    hotspots = {
        -- Limite do recorte: quem entrar e examinar lê a mensagem de limite
        -- do mundo — LoreC.hotspot('fundacaoLimite') devolve o node do Pena.
        {id = 'fundacaoLimite', x = 6, y = 6, label = 'EXAMINAR'},
    },
    exits = {
        {x = 7, y = 2, side = 'north', to = 'reservatorio', arrival = 'fundacao', label = 'RESERVATÓRIO'},
        {x = 7, y = 11, side = 'south', to = 'saloes', arrival = 'fundacao', label = 'SALÕES'},
    },
}
