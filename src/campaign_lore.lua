-- Campaign lore for "A Cidade Que Me Enterrou": cast names, voice pitches and
-- the dialogue nodes of the first recorte (Colina + first hub visit). Content
-- follows docs/GUIA_ESCRITA_DEVIN.md: one voice per person, PT-BR natural.
-- State lives in campaign.state; these builders only read it.
local Dialogue = require('src.dialogue')
local Lore = require('src.lore')
local LoreC = {}

LoreC.npcs = {
    doro = {name = 'DORO', home = 'colina'},
    runa = {name = 'RUNA', home = 'colina'},
    bento = {name = 'BENTO', home = 'hub'},
    teca = {name = 'TECA', home = 'hub'},
    sabela = {name = 'SABELA', home = 'hub'},
    nilo = {name = 'NILO', home = 'hub'},
    aurel = {name = 'AUREL', home = 'hub'},
}

LoreC.voices = {doro = .8, runa = 1.05, bento = .68, teca = 1.0,
    sabela = 1.22, nilo = 1.42, aurel = .5}
for id, pitch in pairs(LoreC.voices) do Lore.voices[id] = pitch end

LoreC.titles = {narration = ' ', sepultura = 'SUA SEPULTURA', pertences = 'SEUS PERTENCES'}

LoreC.intro = {
    title = LoreC.titles.narration, voice = 'inscription',
    lines = {
        'A tampa da sua sepultura cedeu por dentro. Sete anos de poeira — e um encaixe recém-trocado.',
        'Você saiu. A Colina dos Sepultados acordou junto.',
    },
}

LoreC.hubArrival = {
    title = LoreC.titles.narration, voice = 'inscription',
    lines = {
        'O refúgio: uma casa funerária que virou casa, capela que virou cozinha.',
        'Toda porta aqui tem nome. Toda luz tem dono. E todos conhecem a sua cova.',
    },
}

-- Hotspot narrations resolve through this table; effects read and write
-- campaign.state directly, once-flags included.
function LoreC.hotspot(campaign, spot)
    local id = spot.id
    if id == 'sepultura' then
        return {title = LoreC.titles.sepultura, voice = 'inscription', lines = {
            'Oitavo encaixe, lado de dentro: o único que estava rachado.',
            'Alguém o trocou esta noite. Foi assim que a tampa cedeu.',
        }}
    elseif id == 'pano' then
        return {title = 'PANO DE VELÓRIO', voice = 'inscription', lines = {
            'Estendido sobre o banco e esquecido. Ninguém recolheu o velório.',
            'Ninguém aqui esperava que o velório terminasse assim.',
        }}
    elseif id == 'pertences' then
        campaign:completeStep('P01-E02')
        campaign.data.flags.casaco = true
        campaign:setProp('bau', 'done')
        return {title = LoreC.titles.pertences, voice = 'inscription', lines = {
            'O casaco pesado, dobrado com cuidado. O remendo no cotovelo é ponto torto — Lia ria do próprio acabamento.',
            'Embaixo dele: o arco de viagem, a aljava e o resto do que era seu.',
        }}
    elseif id == 'altar' then
        return {title = 'ALTAR', voice = 'inscription', lines = {
            'Um altar sem santo. A casa funerária rezava para quem ficava, não para quem partia.',
        }}
    elseif id == 'cisterna' then
        return {title = 'CISTERNA', voice = 'inscription', lines = {
            'Água parada embaixo da casa. O refúgio vive do que a cidade afundada ainda devolve.',
        }}
    elseif id == 'bancada' then
        return {title = 'BANCADA', voice = 'inscription', lines = {
            'Ferramentas de carpintaria e alvenaria. Doro remenda o refúgio inteiro nesta bancada.',
        }}
    end
    return {title = ' ', voice = 'inscription', lines = {'...'}}
end

local function met(campaign, id) return (campaign.data.people[id] or {}).met == true end
local function mark(campaign, id)
    local person = campaign.data.people[id] or {}
    person.met = true
    campaign.data.people[id] = person
end
local function done(campaign, step) return campaign.data.steps[step] == true end

local function swap(campaign, node)
    Dialogue.open(campaign, node)
    return false
end

local talks = {}

talks.doro = function(campaign)
    mark(campaign, 'doro')
    if not campaign:flag('metDoroFirst') then
        campaign.data.flags.metDoroFirst = true
        return {title = 'DORO', voice = 'doro', lines = {
            'Você está de pé. A tampa cedeu e eu... pensei que fosse só a pedra cedendo.',
            'Eu troquei o encaixe rachado da sua cova hoje de manhã. Foi isso que abriu. Desculpa.',
            'Sou Doro. Cuido das sepulturas daqui — e dos reparos, quando deixam.',
        }, options = {
            {label = 'EU ESTAVA AÍ DENTRO?', lines = {
                'Sete anos. A casa inteira jurou que era pra sempre.',
                'Pega suas coisas no depósito antes de descer. É a porta do leste, depois do pátio.',
            }},
            {label = 'O QUE É ESTE LUGAR?', lines = {
                'Colina dos Sepultados. Em cima ficam os que a cidade guardou.',
                'Embaixo ficam os que ficaram. O refúgio é pela grade ao sul — Runa vigia.',
            }},
            {label = 'SAIR'},
        }}
    end
    return {title = 'DORO', voice = 'doro', lines = {
        'Seus pertences estão no depósito, no leste do pátio.',
        'Desce pela grade quando estiver pronto. Vou na frente avisar a casa.',
    }, options = {{label = 'SAIR'}}}
end

talks.runa = function(campaign)
    mark(campaign, 'runa')
    if done(campaign, 'P01-E03') then
        return {title = 'RUNA', voice = 'runa', lines = {
            'A grade fica erguida. Desce. Doro já deve ter espalhado a novidade.',
        }, options = {{label = 'SAIR'}}}
    end
    return {title = 'RUNA', voice = 'runa', lines = {
        'Alto. Minha grade, minhas regras.',
        'A vedação dessa cova era serviço meu — e alguém a rompeu essa noite.',
        'Me diz quem rompeu, e aí eu decido se um morto acordado passa.',
    }, options = {
        {label = 'FUI EU. SAÍ DA MINHA COVA.', action = function(c)
            c:openGrade('confessou')
            return swap(c, {title = 'RUNA', voice = 'runa', lines = {
                'Da própria cova. Diz isso olhando nos meus olhos.',
                'Tá. A casa deixou você sair — a casa responde por você. Passa.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'DORO ROMPEU, NUM REPARO', action = function(c)
            c:openGrade('doro')
            return swap(c, {title = 'RUNA', voice = 'runa', lines = {
                'O pedreiro. Sempre remendando pedra que não devia.',
                'Se a vedação cedeu sozinha, o morto não tem culpa. Passa.',
            }, options = {{label = 'SAIR'}}})
        end},
        {label = 'AINDA NÃO', lines = {
            'Então fica aí do outro lado até lembrar. A grade não tem pressa.',
        }},
    }}
end

local hubTalks = {
    bento = function(campaign)
        mark(campaign, 'bento')
        if not campaign:flag('metBento') then
            campaign.data.flags.metBento = true
            return {title = 'BENTO', voice = 'bento', lines = {
                'Ah. Você acordou. Que... bom. É. Bom.',
                'Bento. Eu cuido do depósito — e da escola, quando o Nilo deixa.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'BENTO', voice = 'bento', lines = {'Precisa de algo? O depósito está arrumado.'},
            options = {{label = 'SAIR'}}}
    end,
    teca = function(campaign)
        mark(campaign, 'teca')
        if not campaign:flag('metTeca') then
            campaign.data.flags.metTeca = true
            return {title = 'TECA', voice = 'teca', lines = {
                'Morto levantado. Já vi coisa pior nesta casa.',
                'Teca. Ferramenta boa não cai de mão vazia — traz material que a gente conversa.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'TECA', voice = 'teca', lines = {'A bancada não se conserta olhando.'},
            options = {{label = 'SAIR'}}}
    end,
    sabela = function(campaign)
        mark(campaign, 'sabela')
        if not campaign:flag('metSabela') then
            campaign.data.flags.metSabela = true
            return {title = 'SABELA', voice = 'sabela', lines = {
                'Então é verdade. Você voltou.',
                'Sou Sabela. Cuido da capela — e dos que precisam ficar em paz aqui dentro.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'SABELA', voice = 'sabela', lines = {'A capela está aberta. Sente, se precisar.'},
            options = {{label = 'SAIR'}}}
    end,
    nilo = function(campaign)
        mark(campaign, 'nilo')
        if not campaign:flag('metNilo') then
            campaign.data.flags.metNilo = true
            return {title = 'NILO', voice = 'nilo', lines = {
                'Você é o da cova? Todo mundo falando.',
                'Sou Nilo. Eu sei onde fica cada coisa da casa. Sério. Pergunta.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'NILO', voice = 'nilo', lines = {'A casa é grande mas eu sei os atalhos.'},
            options = {{label = 'SAIR'}}}
    end,
    aurel = function(campaign)
        mark(campaign, 'aurel')
        if not campaign:flag('metAurel') then
            campaign.data.flags.metAurel = true
            return {title = 'AUREL', voice = 'aurel', lines = {
                'Você voltou. Eu imaginei este dia por sete anos.',
                'O rito fui eu que fiz. Não vou fingir que não.',
                'O porquê é outra conversa — e não é curta.',
            }, options = {{label = 'SAIR'}}}
        end
        return {title = 'AUREL', voice = 'aurel', lines = {'Eu disse o que fiz. O resto tem hora.'},
            options = {{label = 'SAIR'}}}
    end,
    runa = function(campaign)
        mark(campaign, 'runa')
        return {title = 'RUNA', voice = 'runa', lines = {
            'Agora vigio as passagens. Porta nova, mesma regra: quem passa me responde.',
        }, options = {{label = 'SAIR'}}}
    end,
    doro = function(campaign)
        mark(campaign, 'doro')
        return {title = 'DORO', voice = 'doro', lines = {
            'Então. Essa é a casa. Bancada comigo e com a Teca, cozinha com a Sabela.',
            'O resto você conhece andando. As passagens ficam na sala do fundo.',
        }, options = {{label = 'SAIR'}}}
    end,
}

function talks.hub(campaign, id) return hubTalks[id](campaign) end

function LoreC.talk(campaign, id)
    if campaign.map.id == 'colina' then
        local build = talks[id]
        return build and build(campaign)
    end
    local build = hubTalks[id]
    if build then return build(campaign) end
    return nil
end

return LoreC
