"""Textos das screenshots e do video por idioma.

Cada tela: (titulo, subtitulo). No titulo, "\n" quebra a linha e *palavra*
fica amarela (#FFD21A). Nomes dos modos seguem os ARB do app.
"""

CAPTIONS = {
    "pt-BR": {
        "s1": ("O jogo da velha virou\n*BATALHA*!", "Super Jogo da Velha: 9 tabuleiros em 1"),
        "s2": ("Um *DESAFIO* novo\ntodo dia", "Vença em poucas jogadas e ganhe moedas"),
        "s3": ("*7 MODOS*\npara jogar", "Clássico, Super, 4x4, Cinco em linha e mais"),
        "s4": ("*CINCO* em linha\nno 10x10", "Modo novo: alinhe cinco antes do rival"),
        "s5": ("*VISUAIS* e temas\npara colecionar", "Ganhe moedas jogando e mude seu estilo"),
        "s6": ("Vença e\n*COMPARTILHE*", "Mostre suas vitórias para os amigos"),
    },
    "en-US": {
        "s1": ("Tic tac toe turned into\na *BATTLE*!", "Ultimate Tic Tac Toe: 9 boards in 1"),
        "s2": ("A new *CHALLENGE*\nevery day", "Win in few moves and earn coins"),
        "s3": ("*7 MODES*\nto play", "Classic, Ultimate, 4x4, Five in a Row and more"),
        "s4": ("*FIVE* in a row\non a 10x10 board", "New mode: line up five before your rival"),
        "s5": ("*STYLES* and boards\nto collect", "Earn coins as you play and change your look"),
        "s6": ("Win and\n*SHARE* it", "Show your victories to your friends"),
    },
    "es-ES": {
        "s1": ("¡El tres en raya se volvió\nuna *BATALLA*!", "Súper Tres en Raya: 9 tableros en 1"),
        "s2": ("Un *DESAFÍO* nuevo\ncada día", "Gana en pocas jugadas y consigue monedas"),
        "s3": ("*7 MODOS*\npara jugar", "Clásico, Súper, 4x4, Cinco en línea y más"),
        "s4": ("*CINCO* en línea\nen un tablero 10x10", "Modo nuevo: alinea cinco antes que tu rival"),
        "s5": ("*ESTILOS* y tableros\npara coleccionar", "Gana monedas jugando y cambia tu estilo"),
        "s6": ("Gana y\n*COMPÁRTELO*", "Presume tus victorias con tus amigos"),
    },
    "hi-IN": {
        "s1": ("टिक टैक टो बना\n*महायुद्ध*!", "अल्टीमेट टिक टैक टो: एक में 9 बोर्ड"),
        "s2": ("हर दिन नई\n*चुनौती*", "कम चालों में जीतें, सिक्के पाएं"),
        "s3": ("खेलने के लिए\n*7 मोड*", "क्लासिक, अल्टीमेट, 4x4, लगातार पाँच और भी"),
        "s4": ("10x10 बोर्ड पर\n*लगातार पाँच*", "नया मोड: विरोधी से पहले पाँच मिलाएं"),
        "s5": ("नई *स्टाइल* और\nबोर्ड जमा करें", "खेलकर सिक्के कमाएं, अपना लुक बदलें"),
        "s6": ("जीतें और\n*शेयर करें*", "दोस्तों को अपनी जीत दिखाएं"),
    },
    "bn-BD": {
        "s1": ("টিক ট্যাক টো এখন\n*মহাযুদ্ধ*!", "আলটিমেট টিক ট্যাক টো: এক খেলায় ৯টি বোর্ড"),
        "s2": ("প্রতিদিন নতুন\n*চ্যালেঞ্জ*", "কম চালে জিতুন, কয়েন নিন"),
        "s3": ("খেলার জন্য\n*৭টি মোড*", "ক্লাসিক, আলটিমেট, 4x4, টানা পাঁচ এবং আরও"),
        "s4": ("10x10 বোর্ডে\n*টানা পাঁচ*", "নতুন মোড: প্রতিপক্ষের আগে পাঁচটি মেলান"),
        "s5": ("নতুন *স্টাইল* আর\nবোর্ড সংগ্রহ করুন", "খেলে কয়েন জিতুন, নিজের লুক বদলান"),
        "s6": ("জিতুন আর\n*শেয়ার করুন*", "বন্ধুদের আপনার জয় দেখান"),
    },
    "ne-NP": {
        "s1": ("टिक ट्याक टो अब\n*महायुद्ध*!", "अल्टिमेट टिक ट्याक टो: एउटैमा ९ बोर्ड"),
        "s2": ("हरेक दिन नयाँ\n*चुनौती*", "थोरै चालमा जित्नुहोस्, सिक्का पाउनुहोस्"),
        "s3": ("खेल्नका लागि\n*७ मोड*", "क्लासिक, अल्टिमेट, 4x4, लगातार पाँच र अझै"),
        "s4": ("10x10 बोर्डमा\n*लगातार पाँच*", "नयाँ मोड: विपक्षीभन्दा पहिले पाँच मिलाउनुहोस्"),
        "s5": ("नयाँ *स्टाइल* र\nबोर्ड जम्मा गर्नुहोस्", "खेलेर सिक्का कमाउनुहोस्, आफ्नो लुक बदल्नुहोस्"),
        "s6": ("जित्नुहोस् र\n*सेयर गर्नुहोस्*", "साथीहरूलाई आफ्नो जित देखाउनुहोस्"),
    },
}

# Legendas do video (4 segmentos + cartao final): titulo curto e subtitulo.
VIDEO = {
    "pt-BR": {
        "v1": ("O jogo da velha\nvirou *BATALHA*!", "9 tabuleiros em 1"),
        "v2": ("Um *DESAFIO*\nnovo todo dia", "Vença em poucas jogadas"),
        "v3": ("*CINCO* em linha\nno 10x10", "7 modos para jogar"),
        "v4": ("Vença e\n*COMPARTILHE*", "Ganhe XP e moedas"),
        "end": ("Super Jogo da Velha", "Baixe grátis"),
    },
    "en-US": {
        "v1": ("Tic tac toe turned\ninto a *BATTLE*!", "9 boards in 1"),
        "v2": ("A new *CHALLENGE*\nevery day", "Win in few moves"),
        "v3": ("*FIVE* in a row\non 10x10", "7 modes to play"),
        "v4": ("Win and\n*SHARE* it", "Earn XP and coins"),
        "end": ("Ultimate Tic Tac Toe", "Download free"),
    },
    "hi-IN": {
        "v1": ("टिक टैक टो बना\n*महायुद्ध*!", "एक में 9 बोर्ड"),
        "v2": ("हर दिन नई\n*चुनौती*", "कम चालों में जीतें"),
        "v3": ("10x10 पर\n*लगातार पाँच*", "खेलने के लिए 7 मोड"),
        "v4": ("जीतें और\n*शेयर करें*", "XP और सिक्के कमाएं"),
        "end": ("अल्टीमेट टिक टैक टो", "मुफ़्त डाउनलोड करें"),
    },
}
