-- Ponto de partida deliberadamente mínimo. Andlar será construído depois do Refúgio.
return {
    id = 'andlar', uid = 8, name = 'ANDLAR', realm = 'andlar', outdoor = true,
    w = 16, h = 13, spawn = {x = 8, y = 8},
    arrivals = {hub = {x = 8, y = 8, dx = 0, dy = -1}},
    carve = {{x = 3, y = 3, w = 11, h = 8}},
    props = {
        {id = 'marcoAndlar', kind = 'marco', x = 8, y = 5, w = 2, h = 2, solid = true, state = 'lit'},
        {id = 'placaAndlar', kind = 'placa', x = 12, y = 8, solid = true},
        -- Gramática mínima do cercado: fios de grama nas bordas, a marca do
        -- Marco gravada no chão aos pés dele, pedra solta na margem.
        {id = 'floresA1', kind = 'flores', x = 4, y = 4},
        {id = 'floresA2', kind = 'flores', x = 12, y = 4},
        {id = 'floresA3', kind = 'flores', x = 5, y = 9},
        {id = 'floresA4', kind = 'flores', x = 11, y = 9},
        {id = 'rochaAndlar', kind = 'rocha', x = 13, y = 5},
        {id = 'marcaMarco', kind = 'marcaChao', x = 8, y = 7},
    },
    hotspots = {
        {id = 'retornoAndlar', x = 8, y = 7, range = 1.7, label = 'VOLTAR AO REFÚGIO'},
        {id = 'placaAndlar', x = 12, y = 8, label = 'LER'},
    },
}
