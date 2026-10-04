-- Piloto W1 do kit procedural: revisao localizada da frente do bau.
-- Carrega src/sprites/bau.lua (64x96, origin 'feet'), monta a regiao
-- 'frente' por selecao+mascara sem tocar areas protegidas (cintas,
-- fechadura, tampa, pes, contorno), aplica edicoes confinadas (veios,
-- no de madeira, painel recuado, patch, sombreamento interno) e exporta
-- original e candidato com framing identico + mapa de diff.
-- Consumido por tools/kit_run/main.lua via --revise; so gera relatorio.
-- Rodar da raiz do projeto:
--   lovec tools/kit_run --revise

local M = {}

local function fail(stage, msg) error({ stage = stage, msg = msg }, 0) end

-- Erros ja marcados com estagio sobem intactos; o resto ganha o estagio local.
local function rethrow(stage, err)
    if type(err) == 'table' and err.stage then error(err, 0) end
    fail(stage, tostring(err))
end

local function pxeq(id1, id2, ix, iy)
    local r1, g1, b1, a1 = id1:getPixel(ix, iy)
    local r2, g2, b2, a2 = id2:getPixel(ix, iy)
    return r1 == r2 and g1 == g2 and b1 == b2 and a1 == a2
end

function M.run(K, DSL, dump, say)
    local lines = {}
    local function log(s) lines[#lines + 1] = s end

    --------------------------------------------------------------------
    -- 1. brief normalizado: metadados do alvo desta revisao
    --------------------------------------------------------------------
    local brief = K.brief {
        name = 'bau_frente_grain', w = 64, h = 96, seed = 7,
        role = 'prop de chao',
        region = 'casa das camas do Refugio',
        perspective = '3/4',
        regions = { 'frente', 'cintas', 'fechadura' },
        protected = { 'cintas', 'fechadura', 'contorno', 'pes', 'tampa' },
        identity = 'bau de viagem madeira+ferro com fechadura dourada',
    }

    --------------------------------------------------------------------
    -- 2. asset real + bake do original
    --------------------------------------------------------------------
    local okd, def = pcall(require, 'src.sprites.bau')
    if not okd or type(def) ~= 'table' then
        fail(2, 'src.sprites.bau: ' .. tostring(def))
    end
    local okb, orig = pcall(DSL.bake, def)
    if not okb then rethrow(3, orig) end
    say('bau: bake do original ok (64x96, origin feet)')

    --------------------------------------------------------------------
    -- 3. grade autoravel: prova de ida-e-volta parse/string
    --------------------------------------------------------------------
    local g = K.parse(def.layers[1].albedo)
    assert(K.string(g) == def.layers[1].albedo,
        'pilot_bau: parse/string nao fecha com o albedo do bau')
    local g0 = K.clone(g) -- snapshot pre-edicao para o review "antes"

    --------------------------------------------------------------------
    -- 4. regioes: protegido (uniao de seletores) e frente (retangulo do
    -- corpo menos protegido, erodido 1px p/ margem junto ao ferro)
    --------------------------------------------------------------------
    local protegido = K.sel_rect(g, 28, 52, 9, 7) -- fechadura inteira
    for _, ch in ipairs({ 'i', 'I', 'm', 'G', 'g', 'k', 'l', 'e', 'W', 'w' }) do
        protegido = K.mask_or(protegido, K.sel_color(g, ch))
    end
    local frente = K.mask_and(K.sel_rect(g, 10, 46, 45, 24),
        K.mask_not(protegido))
    frente = K.mask_erode(frente, 8, 1)
    K.set_region(g, 'frente', frente)
    K.set_region(g, 'protegido', protegido)
    local frentePx = K.inspect(frente).pixels
    if frentePx == 0 then fail(2, 'regiao frente vazia apos erosao') end
    log(string.format('regioes: frente=%d px editaveis, protegido=%d px',
        frentePx, K.inspect(protegido).pixels))

    --------------------------------------------------------------------
    -- 5. edicoes confinadas: TODAS passam `frente` como ultimo arg (mask)
    --------------------------------------------------------------------
    local rng = K.rng(brief.name, brief.seed)

    -- a) veios verticais levemente curvos entre as cintas
    for _, x in ipairs({ 14, 17, 26, 31, 36, 39 }) do
        K.qcurve(g, x, 48, x + rng.int(-1, 1), 57, x, 66, 'v', frente)
    end

    -- b) veio em S (cubica) no pano direito do corpo
    K.ccurve(g, 46, 49, 51, 53, 43, 60, 47, 66, 'v', frente)

    -- c) no de madeira: cluster autorado 5x4 (coracao 'k', brilho 'w',
    --    anel 'v'), 2 carimbos pivot center (o 2o espelhado). Spots sao
    --    bolsos de frente verificados: o carimbo inteiro cai na mascara.
    local knot = K.parse(' vvv \nvkkvw\nvvkvv\n vvv ')
    local s1 = rng.pick({ { 15, 55 }, { 38, 62 } })
    local s2 = rng.pick({ { 47, 55 }, { 49, 62 }, { 16, 62 } })
    K.stamp(g, knot, s1[1], s1[2], 'center', frente)
    K.stamp(g, K.flip(knot, true), s2[1], s2[2], 'center', frente)

    -- d) veio cruzado curto, espessura 2, canto inferior esquerdo
    K.stroke(g, { 14, 60, 17, 64 }, 2, 'v', frente)

    -- e) painel recuado: retangulo fechado 'v' + fill do interior 'F'
    --    (bordas nas colunas de veio existentes x=27,32; fill conn=4 nao
    --    vaza porque o perimetro inteiro cai dentro da mascara frente)
    K.path(g, { 27, 60, 32, 60, 32, 66, 27, 66 }, 'v', frente, true)
    K.fill(g, 29, 63, 'v', { conn = 4, mask = frente })
    assert(K.get(g, 24, 62) == 'F', 'pilot_bau: fill do painel vazou')

    -- f) reparo pontual por linha de patch (' ' pula o pixel): prego 'k'
    --    + lasco 'w' no pano direito
    K.patch(g, { rows = { { x = 49, y = 58, text = 'kw ' } } }, frente)

    -- g) sombreamento da borda interna: recolore so 'F' que toca nao-'F'
    K.outline(g, 'v', { mode = 'inner', mask = frente, colors = { F = true } })

    --------------------------------------------------------------------
    -- 6. def NOVA (bake memoiza por identidade) + bake do candidato
    --------------------------------------------------------------------
    local cand = {
        name = 'bau_frente_grain', w = 64, h = 96, origin = 'feet',
        legend = def.legend,
        layers = { K.layer('bau', g) },
        -- metadados lidos pelo workbench (Lupa/W3): caixa + mascara da regiao
        regions = { frente = { x = 10, y = 46, w = 45, h = 24 } },
        masks = { frente = frente, protegido = protegido },
    }
    local okc, candSheet = pcall(DSL.bake, cand)
    if not okc then rethrow(3, candSheet) end
    if candSheet == orig then fail(3, 'bake devolveu o sheet cacheado') end
    say('bau: bake do candidato ok (def nova, sem cache obsoleto)')

    --------------------------------------------------------------------
    -- 7. verificacao executavel: albedo 0-based vs grade 1-based
    --------------------------------------------------------------------
    local ia, ib = orig.imageData.albedo, candSheet.imageData.albedo
    assert(ia:getWidth() == 64 and ia:getHeight() == 96
        and ib:getWidth() == 64 and ib:getHeight() == 96,
        'pilot_bau: sheets com dimensoes divergentes')
    local changed, nrmChanged, emiChanged = {}, 0, 0
    for iy = 0, 95 do
        for ix = 0, 63 do
            if not pxeq(ia, ib, ix, iy) then changed[#changed + 1] = { ix, iy } end
            if not pxeq(orig.imageData.normal, candSheet.imageData.normal, ix, iy) then
                nrmChanged = nrmChanged + 1
            end
            if not pxeq(orig.imageData.emissive, candSheet.imageData.emissive, ix, iy) then
                emiChanged = emiChanged + 1
            end
        end
    end
    assert(#changed > 0, 'pilot_bau: nenhuma mudanca na regiao frente')
    for _, p in ipairs(changed) do
        local x1, y1 = p[1] + 1, p[2] + 1 -- ImageData 0-based -> grade 1-based
        assert(K.get(frente, x1, y1) ~= '.', string.format(
            'pilot_bau: mudanca fora da regiao frente em (%d,%d)', x1, y1))
    end
    -- pixels protegidos identicos nos tres canais
    local leaks = 0
    for iy = 0, 95 do
        for ix = 0, 63 do
            if K.get(protegido, ix + 1, iy + 1) == 'x' then
                for _, ch in ipairs({ 'albedo', 'normal', 'emissive' }) do
                    if not pxeq(orig.imageData[ch], candSheet.imageData[ch], ix, iy) then
                        leaks = leaks + 1
                        break
                    end
                end
            end
        end
    end
    assert(leaks == 0,
        'pilot_bau: ' .. leaks .. ' px protegidos alterados')
    say(string.format('bau: %d px mudados, 0 vazamentos em area protegida',
        #changed))

    --------------------------------------------------------------------
    -- 8. export: orig e cand no mesmo 64x96@feet + mapa de diff
    --------------------------------------------------------------------
    local oke1, e1 = pcall(dump, orig, 'screenshots/kit-pilot-bau_orig')
    if not oke1 then rethrow(4, e1) end
    local oke2, e2 = pcall(dump, candSheet, 'screenshots/kit-pilot-bau_cand')
    if not oke2 then rethrow(4, e2) end
    local did = love.image.newImageData(64, 96)
    for iy = 0, 95 do
        for ix = 0, 63 do
            if pxeq(ia, ib, ix, iy) then
                local r, gg, b, a = ia:getPixel(ix, iy)
                did:setPixel(ix, iy, r, gg, b, a * 0.25) -- contexto a 25%
            else
                did:setPixel(ix, iy, 0, 1, 0, 1) -- mudado: verde opaco
            end
        end
    end
    local diffPath = 'screenshots/kit-pilot-bau_diff.png'
    local f, ferr = io.open(diffPath, 'wb')
    if not f then fail(4, 'nao abriu ' .. diffPath .. ': ' .. tostring(ferr)) end
    f:write(did:encode('png'):getString())
    f:close()
    say('bau: PNGs do piloto exportados em screenshots/')

    --------------------------------------------------------------------
    -- 9. review aids antes/depois: avisos de revisao, nao erros
    --------------------------------------------------------------------
    local r0 = K.review(g0)
    local r1 = K.review(g)
    log(string.format('diff: %d px alterados no albedo, todos na frente', #changed))
    log(string.format('canais: normal=%d px, emissive=%d px alterados', nrmChanged,
        emiChanged))
    log("nota: 'v' e 'F' dividem o albedo wood.3 (h 8 vs 7) — os veios " ..
        'sao relevo; ver _normal.png e o bake sob luz do jogo')
    log('pngs: screenshots/kit-pilot-bau_{orig,cand}_{albedo,normal,emissive}.png')
    log('diff: ' .. diffPath .. ' (verde=mudou, resto=albedo original a 25%)')
    log(string.format('review antes : isolated=%d steps=%d gaps=%d clusters=%d',
        #r0.isolated, #r0.steps, #r0.gaps, #r0.clusters))
    log(string.format('review depois: isolated=%d steps=%d gaps=%d clusters=%d',
        #r1.isolated, #r1.steps, #r1.gaps, #r1.clusters))
    log('nota: contagens do review sao avisos para revisao humana, nao erros')
    return lines
end

return M
