--[==[
pixel_font — duas famílias de bitmap autorais rasterizadas em memória; nenhum
asset de fonte importado. Cada glifo é uma grade de strings ('0/1' na face
clássica, './#' na HD), queimada num love.graphics.ImageFont com colunas
magenta separando os glifos.

FAMÍLIAS
  Font.new(scale)              face clássica 5x7, SÓ MAIÚSCULAS; minúsculas
                               dobram para a maiúscula, acentos são compostos
                               por marca + base. Inalterada — quem já consome
                               Font.new vê exatamente os mesmos pixels.
  Font.newHD(scale)            face HD para o padrão 64px: maiúsculas,
                               MINÚSCULAS REAIS (corpo/ascendente/descendente),
                               dígitos, pontuação e acentos PT-BR completos.
  Font.new(scale, {hd=true})   atalho para Font.newHD(scale).

Ambas devolvem um ImageFont nearest; o contrato com o consumidor é o mesmo
(getWidth/getHeight/printf/print). Glifos têm largura variável — o avanço é
a largura do glifo + 1 coluna, exatamente como a face clássica já fazia.
Font.clean vale para as duas: caracteres fora do conjunto unido viram '?'.

MÉTRICAS HD (escala 1, fileiras 0-indexadas, altura de linha 14)
  fileiras 0-1   acentos das maiúsculas (marca composta, 2 fileiras)
  fileiras 2-9   cap height / ascendente / dígitos (corpo de 8 fileiras)
  fileiras 2-3   acentos das minúsculas
  fileiras 4-9   x-height: corpo das minúsculas (6 fileiras)
  fileiras 10-12 descendentes (g j p q y, cedilha)
  fileira  13    respiro

Nos bitmaps HD '#' é pixel e '.' é vazio. Acentos são compostos como na face
clássica: marca de 2 fileiras (na largura da base) sobre o glifo-base; 'í'
usa o 'i' sem título; 'ç'/'Ç' recebem cedilha nas fileiras 10-11.
]==]
local Font = {}

-- ==================== face clássica 5x7 (inalterada) ====================
local glyphs = {
    A={'01110','10001','10001','11111','10001','10001','10001'}, B={'11110','10001','10001','11110','10001','10001','11110'},
    C={'01111','10000','10000','10000','10000','10000','01111'}, D={'11110','10001','10001','10001','10001','10001','11110'},
    E={'11111','10000','10000','11110','10000','10000','11111'}, F={'11111','10000','10000','11110','10000','10000','10000'},
    G={'01111','10000','10000','10111','10001','10001','01111'}, H={'10001','10001','10001','11111','10001','10001','10001'},
    I={'111','010','010','010','010','010','111'}, J={'00111','00010','00010','00010','10010','10010','01100'},
    K={'10001','10010','10100','11000','10100','10010','10001'}, L={'10000','10000','10000','10000','10000','10000','11111'},
    M={'10001','11011','10101','10101','10001','10001','10001'}, N={'10001','11001','10101','10011','10001','10001','10001'},
    O={'01110','10001','10001','10001','10001','10001','01110'}, P={'11110','10001','10001','11110','10000','10000','10000'},
    Q={'01110','10001','10001','10001','10101','10010','01101'}, R={'11110','10001','10001','11110','10100','10010','10001'},
    S={'01111','10000','10000','01110','00001','00001','11110'}, T={'11111','00100','00100','00100','00100','00100','00100'},
    U={'10001','10001','10001','10001','10001','10001','01110'}, V={'10001','10001','10001','10001','10001','01010','00100'},
    W={'10001','10001','10001','10101','10101','11011','10001'}, X={'10001','10001','01010','00100','01010','10001','10001'},
    Y={'10001','10001','01010','00100','00100','00100','00100'}, Z={'11111','00001','00010','00100','01000','10000','11111'},
    ['0']={'01110','10001','10011','10101','11001','10001','01110'}, ['1']={'010','110','010','010','010','010','111'},
    ['2']={'01110','10001','00001','00010','00100','01000','11111'}, ['3']={'11110','00001','00001','01110','00001','00001','11110'},
    ['4']={'00010','00110','01010','10010','11111','00010','00010'}, ['5']={'11111','10000','10000','11110','00001','00001','11110'},
    ['6']={'01110','10000','10000','11110','10001','10001','01110'}, ['7']={'11111','00001','00010','00100','01000','01000','01000'},
    ['8']={'01110','10001','10001','01110','10001','10001','01110'}, ['9']={'01110','10001','10001','01111','00001','00001','01110'},
    [' ']={'000'}, ['!']={'1','1','1','1','1','0','1'}, ['?']={'1110','0001','0001','0010','0100','0000','0100'},
    ['.']={'0','0','0','0','0','0','1'}, [',']={'00','00','00','00','00','01','10'}, [':']={'0','1','0','0','1','0','0'},
    [';']={'00','01','00','00','01','01','10'}, ['-']={'000','000','000','111'}, ['/']={'00001','00001','00010','00100','01000','10000','10000'},
    ['+']={'000','010','010','111','010','010'}, ['=']={'000','000','111','000','111'}, ['|']={'1','1','1','1','1','1','1'},
    ['(']={'01','10','10','10','10','10','01'}, [')']={'10','01','01','01','01','01','10'},
    ['$']={'00100','01111','10100','01110','00101','11110','00100'}, ['·']={'0','0','0','1'},
    ['–']={'00000','00000','00000','11111'}, ['—']={'0000000','0000000','0000000','1111111'},
    ['%']={'11001','11010','00100','01000','10110','00110','00000'}, ['>']={'100','010','001','010','100'}, ['<']={'001','010','100','010','001'},
    ["'"]={'1','1'}, ['"']={'101','101'}, ['[']={'11','10','10','10','10','10','11'}, [']']={'11','01','01','01','01','01','11'},
}
local accents = {
    ['Á']={'A','00100','01000'}, ['À']={'A','01000','00100'}, ['Â']={'A','00100','01010'}, ['Ã']={'A','01010','10100'},
    ['É']={'E','00100','01000'}, ['Ê']={'E','00100','01010'}, ['Í']={'I','001','010'},
    ['Ó']={'O','00100','01000'}, ['Ô']={'O','00100','01010'}, ['Õ']={'O','01010','10100'},
    ['Ú']={'U','00100','01000'}, ['Ü']={'U','01010','00000'}, ['Ç']={'C'},
}
for char, a in pairs(accents) do
    local rows = {}
    if char ~= 'Ç' then rows[1], rows[2] = a[2], a[3] end
    for _, row in ipairs(glyphs[a[1]]) do rows[#rows+1] = row end
    if char == 'Ç' then rows[#rows+1], rows[#rows+2] = '00100','01000' end
    glyphs[char] = rows
end
local utf8 = require('utf8')
for _, code in utf8.codes('abcdefghijklmnopqrstuvwxyzáàâãéêíóôõúüç') do
    local c = utf8.char(code)
    local upper = code >= 97 and code <= 122 and string.char(code-32) or utf8.char(code-32)
    glyphs[c] = glyphs[upper]
    if accents[upper] then accents[c] = accents[upper] end
end

-- Aliases na face clássica para caracteres que só a HD desenha de verdade:
-- antes imprimiam '?', agora rendem um equivalente próximo. Nenhum glifo
-- existente foi alterado, então a aparência de quem usa Font.new não muda.
glyphs['&'] = {'01100','10010','01000','10101','10010','01101'}
glyphs['“'], glyphs['”'] = glyphs['"'], glyphs['"']
glyphs['‘'], glyphs['’'] = glyphs["'"], glyphs["'"]

local function bakeClassic(scale)
    scale = math.max(1, math.floor(scale or 1))
    local keys, width = {}, 1
    for c in pairs(glyphs) do keys[#keys+1] = c end
    table.sort(keys)
    for _, c in ipairs(keys) do width = width + (#glyphs[c][1] + 2) * scale end
    local data = love.image.newImageData(width, 11 * scale)
    for y=0,11*scale-1 do for x=0,width-1 do data:setPixel(x,y,1,0,1,1) end end
    local x = 1
    for _, c in ipairs(keys) do
        local rows, gw = glyphs[c], #glyphs[c][1]
        local offset = accents[c] and c ~= 'Ç' and c ~= 'ç' and 0 or 2
        if c:match('[a-z]') then offset = 2 end
        for py=0,11*scale-1 do for px=0,(gw+1)*scale-1 do data:setPixel(x+px,py,1,1,1,0) end end
        for ry, row in ipairs(rows) do for rx=1,#row do
            if row:sub(rx,rx)=='1' then
                for sy=0,scale-1 do for sx=0,scale-1 do
                    data:setPixel(x+(rx-1)*scale+sx, (offset+ry-1)*scale+sy, 1,1,1,1)
                end end
            end
        end end
        x = x + (gw + 2) * scale
    end
    local font = love.graphics.newImageFont(data, table.concat(keys), 0)
    font:setFilter('nearest','nearest')
    return font
end

-- ==================== face HD (~9x13, minúsculas reais) ====================
-- Glifo = {top=<fileira>, 'linha','linha',...} com '#' = pixel, '.' = vazio.
-- top é a fileira absoluta do primeiro pixel (ver métricas no header).
-- w opcional força largura para glifos sem linhas (espaço).
local HD_HEIGHT = 14
local hd = {}

-- Maiúsculas: 7 colunas de corpo (estreitas 5-6, M/W 9), fileiras 2-9.
hd.A = {top=2, '...#...', '..#.#..', '.#...#.', '#.....#', '#.....#', '#######', '#.....#', '#.....#'}
hd.B = {top=2, '######.', '#.....#', '#.....#', '######.', '#.....#', '#.....#', '#.....#', '######.'}
hd.C = {top=2, '..####.', '.#....#', '#......', '#......', '#......', '#......', '.#....#', '..####.'}
hd.D = {top=2, '#####..', '#....#.', '#.....#', '#.....#', '#.....#', '#.....#', '#....#.', '#####..'}
hd.E = {top=2, '#######', '#......', '#......', '#####..', '#......', '#......', '#......', '#######'}
hd.F = {top=2, '#######', '#......', '#......', '#####..', '#......', '#......', '#......', '#......'}
hd.G = {top=2, '.#####.', '#.....#', '#......', '#......', '#...###', '#.....#', '#.....#', '.#####.'}
hd.H = {top=2, '#.....#', '#.....#', '#.....#', '#######', '#.....#', '#.....#', '#.....#', '#.....#'}
hd.I = {top=2, '#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..', '#####'}
hd.J = {top=2, '..####', '...#..', '...#..', '...#..', '...#..', '#..#..', '#..#..', '.##...'}
hd.K = {top=2, '#...#.', '#..#..', '#.#...', '##....', '#.#...', '#..#..', '#...#.', '#....#'}
hd.L = {top=2, '#.....', '#.....', '#.....', '#.....', '#.....', '#.....', '#.....', '######'}
hd.M = {top=2, '#.......#', '##.....##', '##.....##', '#.#...#.#', '#.#...#.#', '#..#.#..#', '#..#.#..#', '#.......#'}
hd.N = {top=2, '#.....#', '##....#', '#.#...#', '#..#..#', '#...#.#', '#....##', '#.....#', '#.....#'}
hd.O = {top=2, '.#####.', '#.....#', '#.....#', '#.....#', '#.....#', '#.....#', '#.....#', '.#####.'}
hd.P = {top=2, '######.', '#.....#', '#.....#', '#.....#', '######.', '#......', '#......', '#......'}
hd.Q = {top=2, '.#####.', '#.....#', '#.....#', '#.....#', '#.....#', '#..#..#', '#...#.#', '.#####.', '.....##'}
hd.R = {top=2, '######.', '#.....#', '#.....#', '######.', '#..#...', '#...#..', '#....#.', '#.....#'}
hd.S = {top=2, '.#####.', '#.....#', '#......', '.#####.', '......#', '......#', '#.....#', '.#####.'}
hd.T = {top=2, '#######', '...#...', '...#...', '...#...', '...#...', '...#...', '...#...', '...#...'}
hd.U = {top=2, '#.....#', '#.....#', '#.....#', '#.....#', '#.....#', '#.....#', '#.....#', '.#####.'}
hd.V = {top=2, '#.....#', '#.....#', '#.....#', '.#...#.', '.#...#.', '..#.#..', '..#.#..', '...#...'}
hd.W = {top=2, '#.......#', '#.......#', '#...#...#', '#...#...#', '#..#.#..#', '#..#.#..#', '.#.#.#.#.', '.##...##.'}
hd.X = {top=2, '#.....#', '.#...#.', '..#.#..', '...#...', '...#...', '..#.#..', '.#...#.', '#.....#'}
hd.Y = {top=2, '#.....#', '.#...#.', '..#.#..', '...#...', '...#...', '...#...', '...#...', '...#...'}
hd.Z = {top=2, '#######', '.....#.', '....#..', '...#...', '..#....', '.#.....', '#......', '#######'}

-- Minúsculas reais: x-height fileiras 4-9; ascendentes fileiras 2-9;
-- descendentes fileiras 10-12.
hd.a = {top=4, '.###.', '....#', '.####', '#...#', '#..##', '.##.#'}
hd.b = {top=2, '#....', '#....', '####.', '#...#', '#...#', '#...#', '#...#', '####.'}
hd.c = {top=4, '.####', '#....', '#....', '#....', '#....', '.####'}
hd.d = {top=2, '....#', '....#', '.####', '#...#', '#...#', '#...#', '#...#', '.####'}
hd.e = {top=4, '.###.', '#...#', '#####', '#....', '#...#', '.###.'}
hd.f = {top=2, '..##', '.#..', '###.', '.#..', '.#..', '.#..', '.#..', '.#..'}
hd.g = {top=4, '.###.', '#...#', '#...#', '#...#', '#...#', '.####', '....#', '#...#', '.###.'}
hd.h = {top=2, '#....', '#....', '####.', '#...#', '#...#', '#...#', '#...#', '#...#'}
hd.i = {top=2, '.#.', '...', '##.', '.#.', '.#.', '.#.', '.#.'}
hd.j = {top=2, '..#.', '....', '..#.', '..#.', '..#.', '..#.', '..#.', '..#.', '..#.', '#.#.', '.##.'}
hd.k = {top=2, '#....', '#....', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'}
hd.l = {top=2, '##.', '.#.', '.#.', '.#.', '.#.', '.#.', '.#.', '.##'}
hd.m = {top=4, '.##.##.', '#..#..#', '#..#..#', '#..#..#', '#..#..#', '#..#..#'}
hd.n = {top=4, '####.', '#...#', '#...#', '#...#', '#...#', '#...#'}
hd.o = {top=4, '.###.', '#...#', '#...#', '#...#', '#...#', '.###.'}
hd.p = {top=4, '####.', '#...#', '#...#', '#...#', '####.', '#....', '#....'}
hd.q = {top=4, '.####', '#...#', '#...#', '#...#', '.####', '....#', '....#'}
hd.r = {top=4, '#.##', '##..', '#...', '#...', '#...', '#...'}
hd.s = {top=4, '.####', '#....', '.###.', '....#', '#...#', '.###.'}
hd.t = {top=2, '.#..', '.#..', '####', '.#..', '.#..', '.#..', '.#.#', '..##'}
hd.u = {top=4, '#...#', '#...#', '#...#', '#...#', '#..##', '.##.#'}
hd.v = {top=4, '#...#', '#...#', '#...#', '.#.#.', '.#.#.', '..#..'}
hd.w = {top=4, '#..#..#', '#..#..#', '#..#..#', '#.#.#.#', '#.#.#.#', '.##.##.'}
hd.x = {top=4, '#...#', '.#.#.', '..#..', '..#..', '.#.#.', '#...#'}
hd.y = {top=4, '#...#', '#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..', '##...'}
hd.z = {top=4, '#####', '...#.', '..#..', '.#...', '#....', '#####'}

-- Dígitos: corpo de 8 fileiras (2-9), quase todos em 6 colunas.
hd['0'] = {top=2, '.####.', '#....#', '#...##', '#..#.#', '#.#..#', '##...#', '#....#', '.####.'}
hd['1'] = {top=2, '..#.', '.##.', '..#.', '..#.', '..#.', '..#.', '..#.', '.###'}
hd['2'] = {top=2, '.####.', '#....#', '.....#', '....#.', '...#..', '..#...', '.#....', '######'}
hd['3'] = {top=2, '.####.', '#....#', '.....#', '..###.', '.....#', '.....#', '#....#', '.####.'}
hd['4'] = {top=2, '....#.', '...##.', '..#.#.', '.#..#.', '#...#.', '######', '....#.', '....#.'}
hd['5'] = {top=2, '######', '#.....', '#.....', '#####.', '.....#', '.....#', '#....#', '.####.'}
hd['6'] = {top=2, '..###.', '.#....', '#.....', '#####.', '#....#', '#....#', '#....#', '.####.'}
hd['7'] = {top=2, '######', '.....#', '....#.', '....#.', '...#..', '...#..', '..#...', '..#...'}
hd['8'] = {top=2, '.####.', '#....#', '#....#', '.####.', '#....#', '#....#', '#....#', '.####.'}
hd['9'] = {top=2, '.####.', '#....#', '#....#', '#....#', '.#####', '.....#', '....#.', '.###..'}

-- Pontuação.
hd[' '] = {top=2, w=4}
hd['!'] = {top=2, '##', '##', '##', '#.', '#.', '..', '##', '##'}
hd['?'] = {top=2, '.####.', '#....#', '.....#', '....#.', '...#..', '......', '..##..', '..##..'}
hd['.'] = {top=8, '##', '##'}
hd[','] = {top=8, '.##', '.##', '.#.', '#..'}
hd[':'] = {top=4, '##', '##', '..', '..', '##', '##'}
hd[';'] = {top=4, '.##', '.##', '...', '...', '.##', '.##', '.#.', '#..'}
hd['-'] = {top=6, '#####'}
hd['/'] = {top=2, '....#', '...#.', '...#.', '..#..', '..#..', '.#...', '.#...', '#....'}
hd['+'] = {top=4, '..#..', '..#..', '#####', '..#..', '..#..'}
hd['='] = {top=5, '#####', '.....', '#####'}
hd['|'] = {top=2, '#.', '#.', '#.', '#.', '#.', '#.', '#.', '#.', '#.', '#.'}
hd['('] = {top=2, '..#', '.#.', '#..', '#..', '#..', '#..', '#..', '#..', '.#.', '..#'}
hd[')'] = {top=2, '#..', '.#.', '..#', '..#', '..#', '..#', '..#', '..#', '.#.', '#..'}
hd['$'] = {top=2, '...#...', '.#####.', '#..#..#', '#..#...', '.#####.', '...#..#', '#..#..#', '.#####.', '...#...'}
hd['·'] = {top=6, '##', '##'}
hd['–'] = {top=6, '######'}
hd['—'] = {top=6, '#########'}
hd['%'] = {top=2, '##....#.', '##...#..', '....#...', '...#....', '..#.....', '.#......', '#.....##', '......##'}
hd['>'] = {top=3, '#...', '.#..', '..#.', '...#', '..#.', '.#..', '#...'}
hd['<'] = {top=3, '...#', '..#.', '.#..', '#...', '.#..', '..#.', '...#'}
hd["'"] = {top=2, '##', '##'}
hd['"'] = {top=2, '##.##', '##.##'}
hd['['] = {top=2, '###', '#..', '#..', '#..', '#..', '#..', '#..', '#..', '#..', '###'}
hd[']'] = {top=2, '###', '..#', '..#', '..#', '..#', '..#', '..#', '..#', '..#', '###'}
hd['&'] = {top=2, '..##..', '.#..#.', '.#..#.', '..##..', '.##..#', '#..#.#', '#..##.', '.###.#'}
-- Aspas tipográficas (par na mesma posição; abre/fecha espelhados).
hd['“'] = {top=2, '##.##', '##.##', '.#..#'}
hd['”'] = {top=2, '.#..#', '##.##', '##.##'}
hd['‘'] = {top=2, '##', '##', '.#'}
hd['’'] = {top=2, '.#', '##', '##'}

-- Marcas de acento: 2 fileiras, na largura da base. Agudo '/' (topo à
-- direita), grave '\', circunflexo '^', til '~' em zigue-zague, trema '¨'.
local acute7 = {'...##..', '..##...'}
local grave7 = {'..##...', '...##..'}
local circ7  = {'...#...', '..#.#..'}
local tilde7 = {'.##..##', '#..##..'}
local dia7   = {'..#.#..', '.......'}
local acute5 = {'..##.', '.##..'}
local grave5 = {'.##..', '..##.'}
local circ5  = {'..#..', '.#.#.'}
local tilde5 = {'.##.#', '#..#.'}
local dia5   = {'.#.#.', '.....'}
local acute3 = {'..#', '.#.'}
local ced7   = {'...#...', '..##...'}
local ced5   = {'..#..', '.##..'}

-- i sem título: base da forma 'í' (a marca substitui o pingo).
local dotlessI = {top=4, '##.', '.#.', '.#.', '.#.', '.#.', '.#.'}

local function hdCompose(base, mark, tail)
    local b = type(base) == 'string' and hd[base] or base
    local out = {top = b.top, w = b.w or (b[1] and #b[1]) or 0}
    if mark then out.top = b.top - 2; out[1], out[2] = mark[1], mark[2] end
    for _, row in ipairs(b) do out[#out + 1] = row end
    if tail then for _, row in ipairs(tail) do out[#out + 1] = row end end
    return out
end

hd['Á'] = hdCompose('A', acute7) hd['À'] = hdCompose('A', grave7)
hd['Â'] = hdCompose('A', circ7)  hd['Ã'] = hdCompose('A', tilde7)
hd['É'] = hdCompose('E', acute7) hd['Ê'] = hdCompose('E', circ7)
hd['Í'] = hdCompose('I', acute5)
hd['Ó'] = hdCompose('O', acute7) hd['Ô'] = hdCompose('O', circ7)
hd['Õ'] = hdCompose('O', tilde7)
hd['Ú'] = hdCompose('U', acute7) hd['Ü'] = hdCompose('U', dia7)
hd['Ç'] = hdCompose('C', nil, ced7)

hd['á'] = hdCompose('a', acute5) hd['à'] = hdCompose('a', grave5)
hd['â'] = hdCompose('a', circ5)  hd['ã'] = hdCompose('a', tilde5)
hd['é'] = hdCompose('e', acute5) hd['ê'] = hdCompose('e', circ5)
hd['í'] = hdCompose(dotlessI, acute3)
hd['ó'] = hdCompose('o', acute5) hd['ô'] = hdCompose('o', circ5)
hd['õ'] = hdCompose('o', tilde5)
hd['ú'] = hdCompose('u', acute5) hd['ü'] = hdCompose('u', dia5)
hd['ç'] = hdCompose('c', nil, ced5)

local function bakeHD(scale)
    scale = math.max(1, math.floor(scale or 1))
    local keys, width = {}, 1
    for c in pairs(hd) do keys[#keys + 1] = c end
    table.sort(keys)
    for _, c in ipairs(keys) do
        local g = hd[c]
        g.w = g.w or #g[1]
        width = width + (g.w + 2) * scale
    end
    local data = love.image.newImageData(width, HD_HEIGHT * scale)
    for y = 0, HD_HEIGHT * scale - 1 do
        for x = 0, width - 1 do data:setPixel(x, y, 1, 0, 1, 1) end
    end
    local x = 1
    for _, c in ipairs(keys) do
        local g = hd[c]
        for py = 0, HD_HEIGHT * scale - 1 do
            for px = 0, (g.w + 1) * scale - 1 do
                data:setPixel(x + px, py, 1, 1, 1, 0)
            end
        end
        for ry, row in ipairs(g) do
            for rx = 1, #row do
                if row:sub(rx, rx) == '#' then
                    for sy = 0, scale - 1 do
                        for sx = 0, scale - 1 do
                            data:setPixel(x + (rx - 1) * scale + sx,
                                (g.top + ry - 1) * scale + sy, 1, 1, 1, 1)
                        end
                    end
                end
            end
        end
        x = x + (g.w + 2) * scale
    end
    local font = love.graphics.newImageFont(data, table.concat(keys), 0)
    font:setFilter('nearest', 'nearest')
    return font
end

function Font.new(scale, opts)
    if opts and opts.hd then return Font.newHD(scale) end
    return bakeClassic(scale)
end

function Font.newHD(scale)
    return bakeHD(scale)
end

Font.HD_HEIGHT = HD_HEIGHT

-- Chars without a glyph fold to '?' so authored strings can never crash the font.
local known = {}
for c in pairs(glyphs) do known[c] = true end
for c in pairs(hd) do known[c] = true end
local cleaned = {}
function Font.clean(value)
    if type(value) ~= 'string' then return value end
    if cleaned[value] == nil then
        local out = value:gsub('([%z\1-\127\194-\244][\128-\191]*)',
            function(c) return known[c] and c or '?' end)
        cleaned[value] = out
    end
    return cleaned[value]
end
return Font
