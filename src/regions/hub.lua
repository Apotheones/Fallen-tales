-- O Refúgio: casa funerária, capela e pátio (docs/HUB_INICIAL.md)
-- Sete zonas navegáveis: capela/cozinha, alojamento, pátio central, cisterna,
-- bancada, depósito/escola e a casa das passagens com os portais das regiões.
return {
    id = 'hub', uid = 2, name = 'O REFÚGIO', w = 32, h = 23,
    spawn = {x = 26, y = 20},
    arrivals = {
        colina = {x = 26, y = 20, dx = 0, dy = -1},
    },
    carve = {
        {x = 4, y = 2, w = 8, h = 5},    -- capela + cozinha
        {x = 8, y = 7, w = 2, h = 1},    -- corredor capela–pátio
        {x = 18, y = 2, w = 9, h = 5},   -- alojamento
        {x = 20, y = 7, w = 2, h = 1},   -- corredor alojamento–pátio
        {x = 6, y = 8, w = 18, h = 7},   -- pátio central
        {x = 6, y = 15, w = 2, h = 1},   -- corredor pátio–cisterna
        {x = 12, y = 15, w = 2, h = 1},  -- corredor pátio–bancada
        {x = 19, y = 15, w = 2, h = 1},  -- corredor pátio–escola
        {x = 23, y = 15, w = 4, h = 1},  -- corredor pátio–passagens
        {x = 3, y = 16, w = 7, h = 5},   -- cisterna
        {x = 11, y = 16, w = 6, h = 5},  -- bancada
        {x = 18, y = 16, w = 6, h = 5},  -- depósito/escola
        {x = 25, y = 16, w = 6, h = 5},  -- casa das passagens
    },
    props = {
        {id = 'altar', kind = 'altar', x = 5, y = 3, solid = true},
        {id = 'fogao', kind = 'fogao', x = 10, y = 3, solid = true},
        {id = 'mesa', kind = 'mesa', x = 7, y = 5, w = 2, solid = true},
        {id = 'cama1', kind = 'cama', x = 19, y = 3, solid = true},
        {id = 'cama2', kind = 'cama', x = 21, y = 3, solid = true},
        {id = 'cama3', kind = 'cama', x = 24, y = 3, solid = true},
        {id = 'cisterna', kind = 'cisterna', x = 4, y = 17, w = 2, h = 2, solid = true},
        {id = 'bancada', kind = 'bancada', x = 11, y = 17, w = 2, solid = true},
        {id = 'ferramentas', kind = 'ferramentas', x = 16, y = 17, solid = true},
        {id = 'carteiras', kind = 'carteiras', x = 19, y = 17, w = 2, solid = true},
        {id = 'caixas', kind = 'caixas', x = 23, y = 17, solid = true},
        {id = 'bancoHub', kind = 'banco', x = 14, y = 10, solid = true},
    },
    npcs = {
        {id = 'sabela', x = 7, y = 4, dx = 0, dy = 1},
        {id = 'doro', x = 13, y = 18, dx = -1, dy = 0},
        {id = 'teca', x = 15, y = 19, dx = 0, dy = -1},
        {id = 'bento', x = 20, y = 18, dx = 0, dy = -1},
        {id = 'nilo', x = 12, y = 11, dx = 1, dy = 0},
        {id = 'aurel', x = 28, y = 17, dx = 0, dy = 1},
        {id = 'runa', x = 30, y = 18, dx = -1, dy = 0},
    },
    hotspots = {
        {id = 'altar', x = 5, y = 3, label = 'EXAMINAR'},
        {id = 'cisterna', x = 4, y = 17, label = 'EXAMINAR', range = 1.9},
        {id = 'bancada', x = 11, y = 17, label = 'EXAMINAR', range = 1.7},
    },
    exits = {
        {x = 26, y = 21, side = 'south', to = 'colina', arrival = 'hub', label = 'COLINA'},
        {x = 28, y = 21, side = 'south', to = 'oficinas', arrival = 'hub', open = false, label = 'OFICINAS'},
        {x = 29, y = 21, side = 'south', to = 'mercado', arrival = 'hub', open = false, label = 'MERCADO'},
    },
}
