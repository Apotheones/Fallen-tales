-- Região 1: Colina dos Sepultados (docs/mapas/01_COLINA.md)
-- Planta autoral por retângulos de piso; a casca de muros é gerada ao redor.
-- Lugares garantidos da ficha: sepultura original, pátio do velório,
-- depósito funerário, grade de Runa e a descida ao refúgio.
return {
    id = 'colina', uid = 1, name = 'COLINA DOS SEPULTADOS', w = 28, h = 24,
    spawn = {x = 6, y = 4},
    arrivals = {
        hub = {x = 7, y = 21, dx = 0, dy = -1},
        sepultura = {x = 6, y = 4, dx = 0, dy = 1},
    },
    carve = {
        {x = 4, y = 2, w = 6, h = 4},    -- câmara da sepultura
        {x = 6, y = 6, w = 2, h = 4},    -- corredor ao pátio
        {x = 4, y = 10, w = 14, h = 6},  -- pátio do velório
        {x = 18, y = 11, w = 3, h = 2},  -- corredor ao depósito
        {x = 21, y = 9, w = 6, h = 6},   -- depósito funerário
        {x = 5, y = 16, w = 2, h = 2},   -- corredor da grade
        {x = 4, y = 18, w = 8, h = 4},   -- salão da descida
    },
    holes = {
        {x = 17, y = 14}, {x = 17, y = 15}, {x = 16, y = 15},
    },
    pillars = {
        {x = 11, y = 10}, {x = 15, y = 10},
    },
    props = {
        {id = 'cova', kind = 'sepultura', x = 5, y = 3, solid = true},
        {id = 'tampa', kind = 'tampa', x = 8, y = 3},
        {id = 'banco1', kind = 'banco', x = 8, y = 12, solid = true},
        {id = 'banco2', kind = 'banco', x = 9, y = 12, solid = true},
        {id = 'pano', kind = 'pano', x = 13, y = 12, solid = true},
        {id = 'bau', kind = 'bau', x = 23, y = 10, solid = true},
        {id = 'grade', kind = 'grade', x = 5, y = 17, w = 2, solid = true},
        {id = 'flores', kind = 'flores', x = 14, y = 14},
    },
    npcs = {
        {id = 'doro', x = 8, y = 3, dx = -1, dy = 0},
        {id = 'runa', x = 6, y = 18, dx = 0, dy = -1, talkRange = 2.4},
    },
    hotspots = {
        {id = 'sepultura', x = 5, y = 3, label = 'EXAMINAR'},
        {id = 'pano', x = 13, y = 12, label = 'EXAMINAR'},
        {id = 'pertences', x = 23, y = 10, label = 'PEGAR', once = true, title = 'SEUS PERTENCES'},
    },
    exits = {
        {x = 7, y = 22, side = 'south', to = 'hub', arrival = 'hub'},
    },
    encounters = {
        -- Sentinela de teste do recorte: parada no salão da descida, visível e
        -- contornável; encostar abre a arena (plumbing da etapa 1).
        {id = 'T01-01', x = 9, y = 20, kind = 'dasher'},
    },
}
