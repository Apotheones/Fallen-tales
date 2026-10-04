-- kit_w5 — checks e evidência do W5 (ambiente/piloto de exploração).
-- Uso, da raiz do projeto:
--   lovec tools/kit_w5            -> checks + evidência em screenshots/
--   lovec tools/kit_w5 --test     -> só os checks, sai com código de erro
--
-- Entregas cobertas: compatibilidade de borda de tiles (repetição 3x3+),
-- variantes estáticas por seed (piso_* 4f via Kit.variant), transições
-- controladas laje<->terra (overlay piso_terra_borda, mesma seleção do
-- hd_world), metadados frameUse (variant|anim|direction|state) e
-- estados de gameplay (braseiro_quiet, varal_vento_quiet).
--
-- Saídas (screenshots/):
--   kit_w5_rep_<piso>.png       repetição 3x3 com variantes por seed
--   kit_w5_trans_sem.png        mistura laje/terra SEM overlay
--   kit_w5_trans_com.png        mesma mistura COM overlay (a evidência)
--   kit_w5_borda_frames.png     os 8 frames direcionais do overlay
--   kit_w5_relatorio.txt        auditoria frameUse + avisos de borda

local DSL, Kit
local testOnly

local function die(msg)
    local f = io.open('screenshots/kit_w5-erro.txt', 'w')
    if f then f:write(tostring(msg) .. '\n' .. debug.traceback()); f:close() end
    love.event.quit(1)
end
function love.errhand(msg) die(msg) return function() return 1 end end

local function bake(nome)
    local okd, def = pcall(require, 'src.sprites.' .. nome)
    if not okd then die('require src.sprites.' .. nome .. ' falhou: ' .. tostring(def)) end
    local okb, sheet = pcall(DSL.bake, def)
    if not okb then die('bake ' .. nome .. ' falhou: ' .. tostring(sheet)) end
    return def, sheet
end

local function png(id, path)
    local f = assert(io.open(path, 'wb'))
    f:write(id:encode('png'):getString())
    f:close()
end

-- Copia frame `f` de um sheet p/ dentro do composite (alpha respeitado).
local function cola(dst, sheet, f, dx, dy)
    local src = sheet.imageData.albedo
    local x0 = (f - 1) * sheet.w
    for y = 0, sheet.h - 1 do for x = 0, sheet.w - 1 do
        local r, g, b, a = src:getPixel(x0 + x, y)
        if a > 0 then dst:setPixel(dx + x, dy + y, r, g, b, a) end
    end end
end

--------------------------------------------------------------------------------
-- floorKind + seleção de overlay — ESPELHO de src/hd_world.lua (W5):
-- qualquer mudança lá deve refletir aqui (o teste compara com a cena).
--------------------------------------------------------------------------------

local function floorKindHub(x, y)
    return Kit.hash(math.floor(x / 3), math.floor(y / 3), 21) < .30
        and 'terra' or 'laje'
end

-- Direções n=1,e=2,s=3,w=4; cantos ne=5,nw=6,se=7,sw=8.
local function overlaysDe(kind, tx, ty, floorOf)
    local dir = {}
    for d, o in ipairs({ { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }) do
        local nk = floorOf(tx + o[1], ty + o[2])
        if nk ~= kind and nk == 'terra' then dir[d] = nk end
    end
    local frames, usado = {}, {}
    for _, c in ipairs({ { 1, 2, 5 }, { 4, 1, 6 }, { 2, 3, 7 }, { 3, 4, 8 } }) do
        if dir[c[1]] and dir[c[1]] == dir[c[2]] then
            frames[#frames + 1] = c[3]
            usado[c[1]], usado[c[2]] = true, true
        end
    end
    for d in pairs(dir) do
        if not usado[d] then frames[#frames + 1] = d end
    end
    return frames
end

local function mistura(sheets, borda, cols, rows, comOverlay)
    local id = love.image.newImageData(cols * 64, rows * 64)
    for ty = 1, rows do for tx = 1, cols do
        local kind = floorKindHub(tx, ty)
        local sh = sheets[kind]
        cola(id, sh, Kit.variant(sh, tx, ty), (tx - 1) * 64, (ty - 1) * 64)
        if comOverlay then
            for _, f in ipairs(overlaysDe(kind, tx, ty, floorKindHub)) do
                cola(id, borda, f, (tx - 1) * 64, (ty - 1) * 64)
            end
        end
    end end
    return id
end

--------------------------------------------------------------------------------

local function check()
    -- bake dos defs W5 e dos tiles-base do piloto
    local defB, shB = bake('piso_terra_borda')
    assert(shB.frames == 8 and shB.w == 64 and shB.h == 64,
        'piso_terra_borda devia ter 8 frames 64x64')
    assert(defB.frameUse == 'direction'
        and #defB.edgeOrder == 8, 'frameUse/edgeOrder do overlay')
    -- borda é overlay: transparente fora da banda; cada aresta cobre a
    -- faixa certa (n→topo, e→direita, s→fundo, w→esquerda)
    local id = shB.imageData.albedo
    local function opaco(f, x, y)
        local _, _, _, a = id:getPixel((f - 1) * 64 + x - 1, y - 1)
        return a > 0
    end
    assert(opaco(1, 32, 2) and not opaco(1, 32, 60), 'frame n: banda no topo')
    assert(opaco(2, 63, 32) and not opaco(2, 4, 32), 'frame e: banda na dir.')
    assert(opaco(3, 32, 63) and not opaco(3, 32, 4), 'frame s: banda no fundo')
    assert(opaco(4, 2, 32) and not opaco(4, 60, 32), 'frame w: banda na esq.')
    assert(opaco(5, 60, 6) and not opaco(5, 6, 60), 'frame ne: canto sup.dir.')
    -- seleção de overlay espelha o renderer: terra em L num mar de laje
    local function mapa(x, y)
        if (x == 3 and y == 3) or (x == 4 and y == 3) or (x == 3 and y == 4) then
            return 'terra'
        end
        return 'laje'
    end
    assert(#overlaysDe('laje', 2, 3, mapa) == 1
        and overlaysDe('laje', 2, 3, mapa)[1] == 2, 'laje a oeste: frame e')
    local canto = overlaysDe('laje', 4, 4, mapa)
    assert(#canto == 1 and canto[1] == 6, 'entorno concavo N+W: frame nw')
    assert(#overlaysDe('laje', 5, 3, mapa) == 1
        and overlaysDe('laje', 5, 3, mapa)[1] == 4, 'laje a leste: frame w')
    assert(#overlaysDe('terra', 3, 3, mapa) == 0, 'terra nunca ganha borda')

    -- estados de gameplay: defs quiet assam e resolvem
    local dq, sq = bake('braseiro_quiet')
    assert(dq.frameUse == 'state' and sq.frames == 1)
    local _, _, _, a0 = sq.imageData.emissive:getPixel(23, 37)
    assert(a0 == 0, 'braseiro_quiet nao deve emitir luz')
    local dv = bake('varal_vento_quiet')
    assert(dv.frameUse == 'state' and #dv.layers == 1)
    -- base animada segue intacta
    local db, sb = bake('braseiro')
    assert(db.frameUse == 'anim' and sb.frames == 4)

    print('kit_w5: checks ok')
    return {
        terra_borda = shB,
        laje = select(2, bake('piso_laje')),
        terra = select(2, bake('piso_terra')),
    }
end

--------------------------------------------------------------------------------

local function relato(sheets)
    local out = { 'kit_w5 — relatorio W5 (tiles/transicoes/estados)', '' }

    -- Repetição 3x3 com variantes por seed (o que o renderer desenha).
    for _, nome in ipairs({ 'laje', 'terra' }) do
        local sh = sheets[nome]
        local id = love.image.newImageData(3 * 64, 3 * 64)
        for ty = 1, 3 do for tx = 1, 3 do
            cola(id, sh, Kit.variant(sh, tx, ty), (tx - 1) * 64, (ty - 1) * 64)
        end end
        png(id, 'screenshots/kit_w5_rep_' .. nome .. '.png')
    end
    out[#out + 1] = 'repeticao 3x3: kit_w5_rep_laje.png / kit_w5_rep_terra.png'

    -- Mistura laje/terra do padrao REAL do hub (mesmo floorKind por
    -- bloco de 3 celulas): sem overlay vs com overlay — a transicao.
    local sheetsBase = { laje = sheets.laje, terra = sheets.terra }
    png(mistura(sheetsBase, sheets.terra_borda, 8, 6, false),
        'screenshots/kit_w5_trans_sem.png')
    png(mistura(sheetsBase, sheets.terra_borda, 8, 6, true),
        'screenshots/kit_w5_trans_com.png')
    out[#out + 1] = 'transicao: kit_w5_trans_sem.png (sem) x _com.png (com borda)'

    -- Os 8 frames direcionais lado a lado (ordem n,e,s,w,ne,nw,se,sw).
    local id = love.image.newImageData(8 * 64, 64)
    for f = 1, 8 do cola(id, sheets.terra_borda, f, (f - 1) * 64, 0) end
    png(id, 'screenshots/kit_w5_borda_frames.png')

    -- Auditoria frameUse: varre src/sprites; def sem frameUse com
    -- frames>1 vira aviso INFO (variante ou anim? — o leitor decide).
    out[#out + 1] = ''
    out[#out + 1] = '== auditoria frameUse =='
    -- registry oficial: src.sprites.init (def.name -> def). Multi-frame
    -- sem frameUse vira INFO (variante ou anim? — o leitor decide).
    local okS, sprs = pcall(require, 'src.sprites')
    local sem, com = {}, {}
    if okS then
        for nome, def in pairs(sprs) do
            local nfr = 1
            for _, l in ipairs(def.layers or {}) do
                for _, k in ipairs({ 'albedo', 'height', 'emissive' }) do
                    if type(l[k]) == 'table' and #l[k] > nfr then
                        nfr = #l[k]
                    end
                end
            end
            local e = ('%s (frames=%d, frameUse=%s)'):format(
                nome, nfr, tostring(def.frameUse))
            if def.frameUse then com[#com + 1] = e
            elseif nfr > 1 then sem[#sem + 1] = e end
        end
    else
        out[#out + 1] = 'AVISO: require src.sprites falhou: ' .. tostring(sprs)
    end
    table.sort(com); table.sort(sem)
    out[#out + 1] = 'com frameUse: ' .. #com
    for _, e in ipairs(com) do out[#out + 1] = '  ' .. e end
    out[#out + 1] = 'INFO — multi-frame sem frameUse (ambiguidade):'
    for _, e in ipairs(sem) do out[#out + 1] = '  ' .. e end
    return out
end

function love.load(args)
    package.path = package.path .. ';./?.lua;./?/init.lua'
    for _, arg in ipairs(args or {}) do
        if arg == '--test' then testOnly = true end
    end
    DSL = require('src.sprite_dsl')
    
    Kit = require('src.hd_kit')
    local sheets = check()
    if testOnly then love.event.quit(0) return end
    local out = relato(sheets)
    local f = assert(io.open('screenshots/kit_w5_relatorio.txt', 'w'))
    f:write(table.concat(out, '\n') .. '\n')
    f:close()
    print('kit_w5: evidencia ok — rep/transicao/frames/relatorio em screenshots/')
    love.event.quit(0)
end
