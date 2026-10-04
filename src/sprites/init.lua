-- Sprites amostra do formato DSL (Fase 0, docs/MEGAPLAN_VISUAL_HD.md).
-- Cada módulo retorna uma `def` completa; a ordem aqui é a ordem da
-- prancha de bake em tools/bake_sprites.
return {
    viajante = require('src.sprites.viajante'),
    braseiro = require('src.sprites.braseiro'),
    parede = require('src.sprites.parede'),
}
