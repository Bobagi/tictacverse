"""Gera os roteiros (JSON) que o drive.mjs executa, por idioma.

Uso: python3 scenarios.py <outDir>
Coordenadas em px CSS num viewport 390x844, medidas de screenshots 2x da
build web (v1.14.0+28). Se o layout mudar, remeça e ajuste aqui.
"""
import json
import os
import sys

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

LOCALES = {"pt-BR": "pt", "en-US": "en", "es-ES": "es", "hi-IN": "hi", "bn-BD": "bn", "ne-NP": "ne"}
VIDEO_LOCALES = ["pt-BR", "en-US", "hi-IN"]

# Pontos de toque (CSS px)
HOME_CPU = [195, 316]
HOME_FRIEND = [195, 418]
HOME_SKINS = [287, 505]
HOME_CHALLENGE = [195, 578]
MODES_SUPER = [309, 140]
# O cartao do Super tem altura diferente por idioma (texto quebra em mais ou menos linhas).
MODES_CLASSIC = {"en": [316, 225], "hi": [320, 222]}
MODES_CLASSIC_DEFAULT = [311, 278]
MODES_SCROLL = [195, 700, 195, 300]
MODES_GOMOKU_AFTER_SCROLL = [311, 755]


def sup(b, c):
    """Celula c (0..8) do tabuleiro b (0..8) no Super, partida entre amigos."""
    br, bc = divmod(b, 3)
    cr, cc = divmod(c, 3)
    return [[45, 162, 278][bc] + 33 * cc, [327, 444, 560][br] + 33 * cr]


def classic(c, r):
    return [[81, 195, 308][c], [371, 485, 598][r]]


def gomoku(c, r):
    return [42 + 34 * c, 332 + 34 * r]


# Rota legal no Super: X fecha o tabuleiro do meio pela fileira de cima,
# O devolve sempre para ele, depois jogo espalhado ate o tabuleiro 3 ficar aceso.
SUPER_ROUTE = [(4, 0), (0, 4), (4, 1), (1, 4), (4, 2), (2, 4), (8, 8), (8, 0),
               (0, 8), (8, 4), (6, 2), (2, 6), (6, 4), (3, 3)]
GOMOKU_ROUTE = [(4, 4), (5, 5), (5, 4), (6, 4), (4, 5), (4, 6), (3, 4), (2, 4),
                (4, 3), (4, 2), (3, 5)]
CLASSIC_WIN = [(0, 0), (0, 1), (1, 0), (1, 1), (2, 0)]

PROGRESS = {"xp": 300, "matches": 12, "coins": 900, "ownedSkins": ["neon"],
            "equippedSkin": "neon", "lastDailyClaimDay": "2026-10-04", "catalogVersion": 3}


def base(lang, steps, record=False):
    return {"lang": lang, "progress": PROGRESS,
            "extra": {"flutter.tutorial.ultimate2.done": "true"},
            "record": record, "steps": steps}


def taps(points, wait):
    return [{"tap": p, "wait": wait} for p in points]


def super_steps(wait=1300):
    return [{"tap": HOME_FRIEND, "wait": 1800}, {"tap": MODES_SUPER, "wait": 2200}] + \
        taps([sup(b, c) for b, c in SUPER_ROUTE], wait)


def challenge_steps(n):
    return [{"tap": HOME_CHALLENGE, "wait": 2500}, {"auto": "ult", "top": 330, "n": n, "wait": 2600}]


def gomoku_steps(route, wait=1000):
    return [{"tap": HOME_FRIEND, "wait": 1800}, {"swipe": MODES_SCROLL, "wait": 1300},
            {"tap": MODES_GOMOKU_AFTER_SCROLL, "wait": 2200}] + \
        taps([gomoku(*m) for m in route], wait)


def classic_steps(lang, wait=1100):
    return [{"tap": HOME_FRIEND, "wait": 1800}, {"tap": MODES_CLASSIC.get(lang, MODES_CLASSIC_DEFAULT), "wait": 2200}] + \
        taps([classic(*m) for m in CLASSIC_WIN], wait)


for loc, lang in LOCALES.items():
    d = os.path.join(OUT, loc)
    os.makedirs(d, exist_ok=True)
    shots = {
        "s1": super_steps() + [{"wait": 1500}, {"shot": "s1"}],
        "s2": challenge_steps(6) + [{"wait": 600}, {"shot": "s2"}],
        "s3": [{"tap": HOME_FRIEND, "wait": 1800}, {"swipe": MODES_SCROLL, "wait": 1500}, {"shot": "s3"}],
        "s4": gomoku_steps(GOMOKU_ROUTE) + [{"wait": 1200}, {"shot": "s4"}],
        "s5": [{"tap": HOME_SKINS, "wait": 2500}, {"shot": "s5"}],
        "s6": classic_steps(lang) + [{"wait": 2600}, {"shot": "s6"}],
    }
    for name, steps in shots.items():
        with open(os.path.join(d, f"{name}.json"), "w") as f:
            json.dump(base(lang, steps), f)
    if loc in VIDEO_LOCALES:
        clips = {
            "v1": super_steps(1150) + [{"wait": 1500}],
            "v2": challenge_steps(4) + [{"wait": 800}],
            "v3": gomoku_steps(GOMOKU_ROUTE[:9], 850) + [{"wait": 900}],
            "v4": classic_steps(lang, 1000) + [{"wait": 3500}],
        }
        for name, steps in clips.items():
            with open(os.path.join(d, f"{name}.json"), "w") as f:
                json.dump(base(lang, steps, record=True), f)
print("ok")
