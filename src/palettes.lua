-- Paletas limitadas do projeto (Melhorando-tiles-com-código.md §D).
-- Cada material usa uma rampa de três tons: sombra, base e luz — valor
-- primeiro, saturacao controlada. A rampa 'board' é deliberadamente mais
-- clara que o piso de exploração: na arena a grade é informação de jogo.
-- A seção final do arquivo traz a paleta mestra indexada da repaginada HD
-- (MEGAPLAN_VISUAL_HD.md §3.2); tudo acima dela é o contrato legado,
-- preservado com os mesmos valores.
local Palettes = {}

-- Subconjunto inspirado em DawnBringer-16 adaptado às ruínas de pedra azul.
Palettes.ink = {.027, .043, .067}
Palettes.abyss = {.016, .024, .043}

-- Pedra de exploração (piso calmo, plano de refinamento: "o piso recua").
Palettes.floor = {
    seam = {.059, .090, .122},
    dark = {.075, .114, .149},
    base = {.090, .133, .169},
    light = {.106, .149, .184},
    edge = {.169, .235, .286},
}

-- Tabuleiro de batalha: grade legível, valor acima do piso de exploração.
Palettes.board = {
    seam = {.082, .118, .157},
    seamDeep = {.047, .075, .106},
    dark = {.118, .165, .208},
    base = {.141, .192, .239},
    light = {.165, .220, .271},
    -- Lajes lavadas pelo luar: o degrau acima de 'light' dá a rampa de valor
    -- do topo da colina para a sombra da base.
    worn = {.212, .271, .322},
    edge = {.282, .361, .396},
}

-- Pedra de parede/pilar.
Palettes.stone = {
    dark = {.090, .133, .176},
    base = {.169, .235, .286},
    light = {.282, .361, .396},
    edge = {.365, .455, .475},
}

-- Acentos cerimoniais.
Palettes.jade = {
    dark = {.055, .235, .220},
    base = {.235, .635, .529},
    light = {.529, .886, .702},
}
Palettes.gold = {
    dark = {.314, .235, .129},
    base = {.643, .490, .251},
    light = {.847, .702, .392},
}
Palettes.danger = {.941, .388, .302}
Palettes.violet = {.482, .318, .702}
Palettes.white = {.898, .941, .847}

-- Céu noturno da arena cerimonial: bandas de gradiente frio do zênite ao
-- horizonte, lua baixa e terra de sepultura ao redor do tabuleiro. Tons
-- próprios porque o vazio do tabuleiro não é tinta morta — é lugar.
Palettes.sky = {
    zenith = {.012, .018, .035},
    high = {.024, .035, .063},
    mid = {.045, .063, .106},
    low = {.078, .098, .145},
    horizon = {.114, .122, .173},
    star = {.561, .643, .749},
}
Palettes.moon = {
    disc = {.804, .835, .855},
    shade = {.553, .620, .686},
    halo = {.224, .290, .388},
}
Palettes.ridge = {
    far = {.055, .075, .114},
    near = {.031, .045, .071},
    lit = {.106, .133, .176},
}
Palettes.earth = {
    base = {.024, .033, .051},
    mound = {.039, .051, .075},
    rim = {.055, .071, .098},
}
Palettes.ember = {.976, .573, .216}
Palettes.emberLight = {1, .816, .494}

-- Coastal sanctuary: muted sage ground, sandstone and a lavender sea.
Palettes.refuge = {
    grass = {.259, .337, .263}, grassDark = {.204, .278, .224},
    grassLight = {.353, .435, .310}, path = {.424, .416, .345},
    pathLight = {.478, .467, .392}, roof = {.282, .345, .353},
    roofDark = {.184, .247, .271}, roofLight = {.408, .471, .463},
    -- Régua 256bits: rampas de 4 tons por material — a face cega da casa
    -- cai dois degraus (plasterDark/roofDeep) e o meio-degrau fecha a
    -- transição de beiral e encosta (plasterShade/roofShade).
    roofDeep = {.122, .169, .188}, roofShade = {.231, .296, .314},
    sky = {.310, .345, .447}, haze = {.529, .490, .510},
    sea = {.247, .329, .384}, seaLight = {.345, .420, .447},
    distant = {.353, .365, .416}, cliff = {.247, .278, .290},
    plaster = {.647, .612, .502}, plasterLight = {.769, .710, .580},
    plasterDark = {.455, .420, .337}, plasterShade = {.553, .518, .424},
}

-- Famílias por região (repaginada estilo Undertale): mesmo tratamento —
-- piso em massas planas com manchas orgânicas, parede como faixa contínua —
-- com tons próprios de cada ambiente. `floorStyle` escolhe o piso
-- ('stone' = lajes calmas, 'planks' = tábuas) e `wallStyle` a textura do
-- topo ('masonry' = tijolos, 'panel' = painéis verticais).
Palettes.regions = {
    -- Pedra azul das ruínas: fallback para mapas sem família própria.
    default = {
        floorStyle = 'stone', wallStyle = 'masonry',
        floor = {dark = {.075, .114, .149}, base = {.090, .133, .169},
            light = {.106, .149, .184}, shadow = {.027, .043, .067}},
        wall = {cap = {.282, .361, .396}, brick = {.169, .235, .286},
            brickAlt = {.196, .263, .314}, mortar = {.090, .133, .176},
            face = {.118, .169, .208}, faceDark = {.075, .110, .145},
            rim = {.365, .455, .475}},
        wood = {dark = {.314, .235, .129}, base = {.643, .490, .251}, light = {.847, .702, .392}},
        cloth = {dark = {.055, .235, .220}, base = {.235, .635, .529}, light = {.529, .886, .702}},
        moss = {.133, .310, .251}, petal = {.643, .490, .251},
    },
    -- Colina dos Sepultados: crepúsculo funerário — ardósia violeta fria,
    -- musgo jade apagado e ouro velho nos detalhes cerimoniais.
    colina = {
        floorStyle = 'stone', wallStyle = 'masonry',
        floor = {dark = {.208, .188, .259}, base = {.255, .231, .310},
            light = {.290, .263, .353}, shadow = {.133, .118, .176}},
        wall = {cap = {.373, .337, .435}, brick = {.302, .271, .380},
            brickAlt = {.325, .294, .404}, mortar = {.184, .165, .231},
            face = {.243, .220, .302}, faceDark = {.192, .173, .243},
            rim = {.459, .420, .522}},
        wood = {dark = {.286, .224, .145}, base = {.506, .396, .243}, light = {.678, .553, .361}},
        cloth = {dark = {.110, .278, .267}, base = {.196, .451, .412}, light = {.353, .667, .580}},
        moss = {.169, .384, .310}, petal = {.573, .447, .294},
    },
    -- O Refúgio: casa funerária quente — tábuas de madeira envelhecida e
    -- paredes de reboco claro com painéis, acentos jade.
    hub = {
        floorStyle = 'planks', wallStyle = 'panel',
        floor = {dark = {.447, .325, .208}, base = {.514, .376, .243},
            light = {.573, .427, .282}, shadow = {.278, .196, .118}},
        wall = {cap = {.741, .612, .427}, brick = {.627, .498, .325},
            brickAlt = {.655, .525, .353}, mortar = {.408, .302, .184},
            face = {.522, .396, .255}, faceDark = {.412, .302, .184},
            rim = {.812, .694, .510}},
        wood = {dark = {.384, .271, .153}, base = {.596, .451, .278}, light = {.769, .620, .412}},
        cloth = {dark = {.161, .361, .302}, base = {.290, .553, .443}, light = {.463, .769, .631}},
        moss = {.302, .443, .220}, petal = {.761, .561, .302},
    },
    -- Oficinas de Dentro (mapa 2): ferro e ferrugem sob brasas — o cinza
    -- de ferramenta, a mancha escura de trabalho, ouro velho só no detalhe.
    oficinas = {
        floorStyle = 'stone', wallStyle = 'masonry',
        floor = {dark = {.141, .165, .188}, base = {.180, .212, .235},
            light = {.212, .247, .271}, shadow = {.059, .075, .086}},
        wall = {cap = {.353, .396, .427}, brick = {.224, .263, .290},
            brickAlt = {.255, .294, .322}, mortar = {.118, .141, .157},
            face = {.196, .235, .259}, faceDark = {.153, .184, .204},
            rim = {.427, .482, .518}},
        wood = {dark = {.290, .212, .129}, base = {.463, .333, .251}, light = {.608, .451, .345}},
        cloth = {dark = {.361, .322, .220}, base = {.624, .580, .459}, light = {.769, .729, .612}},
        moss = {.282, .290, .208}, petal = {.635, .376, .271},
    },
    -- Praça de Feira (mapa 3): toldos ocre e pedra morna — luz de mercado
    -- aberta, quente e ocupada.
    mercado = {
        floorStyle = 'stone', wallStyle = 'masonry',
        floor = {dark = {.196, .188, .165}, base = {.255, .243, .216},
            light = {.294, .282, .251}, shadow = {.098, .090, .078}},
        wall = {cap = {.478, .463, .416}, brick = {.318, .306, .275},
            brickAlt = {.353, .341, .310}, mortar = {.165, .157, .137},
            face = {.278, .267, .239}, faceDark = {.216, .208, .184},
            rim = {.573, .557, .506}},
        wood = {dark = {.329, .243, .157}, base = {.529, .388, .267}, light = {.678, .533, .376}},
        cloth = {dark = {.537, .400, .216}, base = {.773, .604, .337}, light = {.894, .776, .518}},
        moss = {.353, .361, .255}, petal = {.643, .349, .271},
    },
    -- Reservatório (mapa 4): calcário esverdeado e água parada — úmido,
    -- frio, com musgo nas faixas.
    reservatorio = {
        floorStyle = 'stone', wallStyle = 'masonry',
        floor = {dark = {.220, .251, .227}, base = {.278, .314, .290},
            light = {.322, .361, .333}, shadow = {.110, .129, .114}},
        wall = {cap = {.518, .565, .522}, brick = {.408, .447, .412},
            brickAlt = {.443, .482, .447}, mortar = {.204, .235, .212},
            face = {.345, .384, .353}, faceDark = {.271, .306, .278},
            rim = {.612, .663, .616}},
        wood = {dark = {.329, .251, .145}, base = {.651, .490, .302}, light = {.792, .639, .427}},
        cloth = {dark = {.145, .251, .271}, base = {.212, .357, .384}, light = {.357, .510, .537}},
        moss = {.424, .502, .329}, petal = {.839, .714, .424},
    },
    -- Salões da Cripta Viva (mapa 5): pedra vinho e teatro — cortina
    -- vermelha, ouro gasto, luz de vela.
    saloes = {
        floorStyle = 'planks', wallStyle = 'masonry',
        floor = {dark = {.243, .184, .145}, base = {.322, .267, .290},
            light = {.376, .322, .345}, shadow = {.133, .098, .098}},
        wall = {cap = {.478, .400, .427}, brick = {.322, .267, .290},
            brickAlt = {.357, .298, .322}, mortar = {.165, .133, .145},
            face = {.282, .231, .251}, faceDark = {.220, .180, .196},
            rim = {.580, .494, .522}},
        wood = {dark = {.290, .200, .141}, base = {.463, .322, .239}, light = {.612, .443, .345}},
        cloth = {dark = {.380, .184, .188}, base = {.631, .306, .314}, light = {.769, .427, .431}},
        moss = {.255, .239, .282}, petal = {.761, .639, .396},
    },
}

--------------------------------------------------------------------------------
-- Paleta mestra indexada — repaginada HD (MEGAPLAN_VISUAL_HD.md §3.2).
--
-- Esta seção é o contrato novo: `sprite_dsl` referencia cores como
-- 'rampa.degrau' e o lighting/postfx consome `functional` e `grades`. O
-- sistema legado acima segue intacto e com os mesmos valores.
--
-- Rampas: cada material é uma fileira de índices em `Palettes.index`,
-- ordenada sombra -> luz, 6-8 degraus. O hue-shift é desenhado, não
-- desaturação: os degraus de sombra esfriam e roxeiam (puxam índigo/
-- violeta) e os de luz aquecem (puxam âmbar, creme ou verde-dourado,
-- conforme o material). Os degraus centrais calibram nas cores legadas —
-- stone.base, jade.base, ember, plaster e cia. aparecem dentro das rampas
-- com o mesmo tom, agora com amplitude de verdade acima e abaixo.
--------------------------------------------------------------------------------
Palettes.index = {}
Palettes.ramps = {}

local function ramp(name, colors)
    local steps = {}
    for i = 1, #colors do
        Palettes.index[#Palettes.index + 1] = colors[i]
        steps[i] = #Palettes.index
    end
    Palettes.ramps[name] = steps
end

-- Pedra azul das ruínas: sombra afunda em índigo, topo deslava para um
-- cinza-pálido quente — a mesma ideia do stoneDeep manual do mundo.
ramp('stone', {
    {.043, .051, .102},  -- índigo fundo
    {.055, .082, .114},  -- = stoneDeep do mundo
    {.090, .133, .176},  -- = Pal.stone.dark
    {.169, .235, .286},  -- = Pal.stone.base
    {.220, .286, .337},
    {.282, .361, .396},  -- = Pal.stone.light
    {.365, .455, .475},  -- = Pal.stone.edge
    {.537, .580, .541},  -- luz neutra aquecida
})

-- Madeira envelhecida: sombra umber violácea, luz âmbar pálido.
ramp('wood', {
    {.106, .075, .118},
    {.227, .157, .137},
    {.384, .271, .153},  -- ~ regions.hub.wood.dark
    {.490, .361, .212},
    {.596, .451, .278},  -- = regions.hub.wood.base
    {.769, .620, .412},  -- = regions.hub.wood.light
    {.894, .773, .541},
})

-- Reboco do Refúgio: sombra malva fria, luz creme de muro ao sol.
ramp('plaster', {
    {.255, .220, .263},
    {.455, .420, .337},  -- = refuge.plasterDark
    {.553, .518, .424},  -- = refuge.plasterShade
    {.647, .612, .502},  -- = refuge.plaster
    {.769, .710, .580},  -- = refuge.plasterLight
    {.886, .827, .667},
})

-- Ferro de ferramenta: sombra azul-violeta, luz prata morna.
ramp('iron', {
    {.071, .075, .122},
    {.145, .153, .208},
    {.243, .259, .302},
    {.373, .396, .427},
    {.463, .486, .510},
    {.584, .612, .620},
    {.769, .784, .753},  -- r > b: a luz entorta para o quente
})

-- Ferrugem: sombra marrom-vinho, luz laranja queimado.
ramp('rust', {
    {.133, .078, .110},
    {.247, .122, .118},
    {.435, .204, .153},  -- = P.rust do mundo
    {.576, .298, .184},
    {.722, .416, .224},
    {.859, .573, .302},
})

-- Ouro velho: sombra umber profunda, luz ouro pálido de filete.
ramp('gold', {
    {.114, .082, .090},
    {.192, .141, .067},  -- = goldDeep do mundo
    {.314, .235, .129},  -- = Pal.gold.dark
    {.478, .361, .184},
    {.643, .490, .251},  -- = Pal.gold.base
    {.847, .702, .392},  -- = Pal.gold.light
    {.969, .867, .596},
})

-- Osso e pergaminho: sombra cinza-violeta, luz marfim quente.
ramp('bone', {
    {.169, .149, .204},
    {.337, .306, .322},
    {.557, .478, .345},  -- = boneDark do mundo
    {.686, .624, .463},
    {.812, .749, .592},  -- = bone do mundo
    {.925, .878, .718},
})

-- Pele: sombra malva fechada, luz pêssego. Nenhum tom acinzenta de vez —
-- gente morta-viva é do elenco, não da rampa.
ramp('skin', {
    {.220, .129, .153},
    {.376, .220, .212},
    {.533, .325, .271},
    {.690, .459, .353},
    {.827, .612, .463},
    {.929, .769, .604},
})

-- Cabelo escuro: sombra azul-preta, reflexo marrom quente.
ramp('hair', {
    {.043, .035, .063},
    {.110, .082, .106},
    {.196, .137, .133},
    {.306, .212, .165},
    {.455, .325, .220},
    {.635, .478, .322},
})

-- Pano jade neutro (capa do viajante, toldos frios): a rampa carrega os
-- três degraus do jade legado — jade.base é o degrau 4.
ramp('cloth', {
    {.039, .141, .157},  -- = jadeDeep do mundo
    {.055, .235, .220},  -- = Pal.jade.dark
    {.133, .412, .376},  -- = jadeMid do mundo
    {.235, .635, .529},  -- = Pal.jade.base
    {.529, .886, .702},  -- = Pal.jade.light
    {.812, .937, .733},  -- luz esverdeada quente
})

-- Pano quente (toldos de feira, estofado dos salões): sombra ameixa,
-- luz ocre.
ramp('clothWarm', {
    {.145, .082, .102},
    {.282, .161, .141},
    {.471, .263, .173},
    {.627, .400, .220},
    {.773, .604, .337},  -- = regions.mercado.cloth.base
    {.910, .773, .478},
})

-- Musgo: sombra teal funda, luz verde-dourada — o único material cuja luz
-- puxa para o amarelo em vez do âmbar.
ramp('moss', {
    {.051, .098, .110},
    {.110, .192, .149},
    {.188, .302, .192},
    {.290, .435, .235},
    {.431, .588, .286},
    {.608, .741, .373},
})

-- Terra e caminho batido: sombra quase-abismo, luz barro seco.
ramp('earth', {
    {.039, .051, .078},  -- ~ Pal.earth.mound
    {.118, .110, .129},
    {.220, .204, .184},
    {.353, .325, .263},
    {.424, .416, .345},  -- = refuge.path
    {.478, .467, .392},  -- = refuge.pathLight
    {.600, .580, .478},
})

-- Brasa e chama: emissor — o degrau 5 é o ember legado, os degraus finais
-- estouram para o bloom por threshold.
ramp('ember', {
    {.271, .075, .086},
    {.494, .141, .094},
    {.647, .204, .110},
    {.784, .325, .133},
    {.976, .573, .216},  -- = Pal.ember
    {1, .816, .494},     -- = Pal.emberLight
    {1, .937, .725},
})

-- Mar lavanda do Refúgio: sombra índigo, espuma pálida morna.
ramp('sea', {
    {.067, .086, .157},
    {.145, .192, .278},
    {.247, .329, .384},  -- = refuge.sea
    {.345, .420, .447},  -- = refuge.seaLight
    {.447, .525, .541},
    {.573, .659, .663},
    {.702, .780, .749},
})

-- Magia violeta (selos, rituais): sombra índigo profunda, luz lavanda
-- rosada — o hue-shift roxeia nas duas pontas.
ramp('violet', {
    {.106, .071, .204},
    {.169, .118, .286},  -- = violetDeep do mundo
    {.278, .192, .412},  -- = violetDark do mundo
    {.376, .255, .545},  -- = violetMid do mundo
    {.482, .318, .702},  -- = Pal.violet
    {.690, .529, .878},  -- = violetLight do mundo
    {.851, .749, .949},
})

-- Atalho interno: degrau de rampa como tabela de cor.
local function at(name, step)
    return Palettes.index[Palettes.ramps[name][step]]
end

-- Cores funcionais: informação de jogo, protegidas fora das rampas de
-- material — o grading regional nunca pode apagar um telegraph de ataque,
-- a alma-cursor ou a luz de uma runa. As que já existem dentro de rampas
-- apontam para a mesma tabela do índice; as três ausentes entram no fim.
Palettes.index[#Palettes.index + 1] = Palettes.danger
Palettes.index[#Palettes.index + 1] = Palettes.white
Palettes.index[#Palettes.index + 1] = Palettes.ink

Palettes.functional = {
    ink = Palettes.ink, abyss = Palettes.abyss,
    white = Palettes.white,
    danger = Palettes.danger,        -- ataque, vida, alma-cursor
    select = at('gold', 6),          -- filete dourado do foco (= Pal.gold.light)
    gold = at('gold', 5),            -- = Pal.gold.base
    jade = at('cloth', 4),           -- magia jade = Pal.jade.base
    jadeLight = at('cloth', 5),      -- = Pal.jade.light (POUPAR, luz jade)
    ember = at('ember', 5),          -- = Pal.ember (chama, braseiro)
    emberLight = at('ember', 6),     -- = Pal.emberLight
    violet = at('violet', 5),        -- selo = Pal.violet
    violetLight = at('violet', 6),
}

-- Atalhos de autor: cores funcionais também resolvem como rampa de 1
-- degrau ('ink.1', 'danger.1') — quem desenha não precisa saber quais
-- nomes são rampa e quais são funcionais. 'jade' é alias da rampa cloth
-- inteira: 'jade.2' = jade.dark, 'jade.4' = jade.base.
Palettes.ramps.danger = { #Palettes.index - 2 }
Palettes.ramps.white = { #Palettes.index - 1 }
Palettes.ramps.ink = { #Palettes.index }
Palettes.ramps.jade = Palettes.ramps.cloth

-- Grading por região: tintas por faixa tonal (sombra, meio-tom, luz) para a
-- LUT do postfx — uma linha por região, a paleta não muda. `default` é a
-- identidade neutra. `hub` aponta para o Refúgio: no legado o nome de
-- família e o de realm divergem.
Palettes.grades = {
    refugio = {   -- quente doméstico: sombra vinho, luz âmbar de vela
        shadow = {.58, .47, .55}, mid = {1.00, .93, .80}, light = {1.08, .99, .80}},
    colina = {    -- frio/violeta crepuscular
        shadow = {.48, .44, .72}, mid = {.86, .82, 1.02}, light = {.95, .90, 1.08}},
    necropole = { -- esverdeado úmido
        shadow = {.42, .58, .50}, mid = {.85, .96, .82}, light = {.92, 1.05, .88}},
    saloes = {    -- dourado escuro de teatro
        shadow = {.50, .36, .38}, mid = {.98, .82, .58}, light = {1.10, .92, .55}},
    default = {
        shadow = {1, 1, 1}, mid = {1, 1, 1}, light = {1, 1, 1}},
}
Palettes.grades.hub = Palettes.grades.refugio
Palettes.grades.neutro = Palettes.grades.default

-- Resolve uma espec de cor para a tabela {r, g, b} correspondente:
--   'rampa.degrau' -> degrau 1-based da rampa ('stone.4', 'ember.7')
--   nome funcional -> Palettes.functional[spec] ('danger', 'jadeLight')
--   escalar legado -> Palettes[spec] quando é {r,g,b} ('abyss', 'violet')
-- Erros são explícitos: sprite autoral erra degrau o tempo todo, e a
-- mensagem precisa dizer o que existe.
local resolved = {}
function Palettes.resolve(spec)
    if type(spec) ~= 'string' then
        error(("Palettes.resolve: espec precisa ser string, recebeu %s")
            :format(type(spec)), 2)
    end
    local hit = resolved[spec]
    if hit then return hit end
    local c
    local name, step = spec:match('^([%a_][%w_]*)%.(%d+)$')
    if name then
        local steps = Palettes.ramps[name]
        if not steps then
            error(("Palettes.resolve: rampa '%s' inexistente"):format(name), 2)
        end
        local i = steps[tonumber(step)]
        if not i then
            error(("Palettes.resolve: degrau %s fora da rampa '%s' (1..%d)")
                :format(step, name, #steps), 2)
        end
        c = Palettes.index[i]
    else
        c = Palettes.functional[spec]
        if not c then
            local legacy = Palettes[spec]
            if type(legacy) == 'table' and type(legacy[1]) == 'number' then
                c = legacy
            end
        end
        if not c then
            local hint = Palettes.ramps[spec]
                and (" (é rampa: use '%s.1'..'%s.%d')")
                    :format(spec, spec, #Palettes.ramps[spec]) or ''
            error(("Palettes.resolve: espec '%s' desconhecida%s")
                :format(spec, hint), 2)
        end
    end
    resolved[spec] = c
    return c
end

return Palettes
