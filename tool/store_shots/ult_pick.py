"""Le um screenshot 2x do Super Jogo da Velha e escolhe uma jogada legal.

Uso: python3 ult_pick.py <png> <top_css_da_primeira_linha_de_tabuleiros>
Saida: JSON {"tap":[x,y]} em px CSS, ou {"tap":null} se nao houver jogada.

Classifica cada uma das 81 celulas pela cor do centro:
- ocupada: algum pixel claro e saturado (peca neon X ciano ou O rosa);
- livre e jogavel: preenchimento ciano-petroleo do tabuleiro aceso;
- livre fora da vez: roxo escuro.
"""
import json
import sys

from PIL import Image

png, top0 = sys.argv[1], float(sys.argv[2])
im = Image.open(png).convert("RGB")
BX = [45, 162, 278.5]
BY = [top0 + 20, top0 + 136.5, top0 + 253]
PITCH = 33


def cell_xy(b, c):
    br, bc = divmod(b, 3)
    cr, cc = divmod(c, 3)
    return BX[bc] + PITCH * cc, BY[br] + PITCH * cr


def classify(x, y):
    bright = 0
    teal = 0
    for dx in range(-13, 14, 2):
        for dy in (-9, 0, 9):
            r, g, b = im.getpixel((int((x + dx) * 2), int((y + dy) * 2)))
            if max(r, g, b) > 205 and (r > 200 or g > 200):
                bright += 1
            if g > 95 and b > 115 and r < 110 and max(r, g, b) < 200:
                teal += 1
    if bright >= 3:
        return "occ"
    if teal >= 20:
        return "free"
    return "off"


pref = [4, 0, 2, 6, 8, 1, 3, 5, 7]
best = None
for b in range(9):
    for c in pref:
        x, y = cell_xy(b, c)
        if classify(x, y) == "free":
            # Prefere nao mandar o rival para um tabuleiro que ele quase fechou:
            # simples, so pega a primeira livre na ordem de preferencia.
            best = (x, y)
            break
    if best:
        break
print(json.dumps({"tap": [round(best[0]), round(best[1])] if best else None}))
