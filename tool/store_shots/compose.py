"""Monta as screenshots da Play (1080x1920, RGB sem alfa) com o frame real do Pixel 5.

Uso: python3 compose.py <capDir> <outDir> [locale ...]
  capDir/<locale>/sN/sN.png  = captura 2x (780x1688) do app
  outDir/<locale>/0N.png     = imagem final

Tambem exporta helpers (background, headline, phone) usados por make_video.py.
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from captions import CAPTIONS

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FRAME = os.path.join(HERE, "assets", "pixel5.png")
FREDOKA = os.path.join(ROOT, "assets", "fonts", "Fredoka.ttf")
NOTO_DEVA = "/usr/share/fonts/truetype/noto/NotoSansDevanagari-Bold.ttf"
NOTO_BENG = "/usr/share/fonts/truetype/noto/NotoSansBengali-Bold.ttf"
NOTO_DEVA_R = "/usr/share/fonts/truetype/noto/NotoSansDevanagari-Regular.ttf"
NOTO_BENG_R = "/usr/share/fonts/truetype/noto/NotoSansBengali-Regular.ttf"

W, H = 1080, 1920
YELLOW = (255, 210, 26)
WHITE = (255, 255, 255)
SUB = (232, 222, 255)
SCREEN_OFF = 58          # tela do frame em +58+58
SCREEN_W, SCREEN_H = 1080, 2340
CSS_H = 844              # altura CSS da captura

# Ate onde (px CSS) cada tela precisa aparecer inteira; o resto pode sangrar.
NEED = {"s1": 690, "s2": 690, "s3": 805, "s4": 690, "s5": 720, "s6": 812}


def font(locale, size, bold=True):
    if locale in ("hi-IN", "ne-NP"):
        return ImageFont.truetype(NOTO_DEVA if bold else NOTO_DEVA_R, size)
    if locale == "bn-BD":
        return ImageFont.truetype(NOTO_BENG if bold else NOTO_BENG_R, size)
    f = ImageFont.truetype(FREDOKA, size)
    f.set_variation_by_name("Bold" if bold else "Medium")
    return f


def background():
    """Gradiente roxo da identidade do app + manchas de luz e glifos X/O apagados."""
    t = Image.linear_gradient("L").resize((W, H))
    top = Image.new("RGB", (W, H), (24, 14, 52))
    bot = Image.new("RGB", (W, H), (58, 20, 92))
    img = Image.composite(bot, top, t)
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse((-300, 900, 700, 1900), fill=(120, 40, 140))
    g.ellipse((500, -200, 1400, 700), fill=(40, 60, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    img = add(img, glow, 0.55)
    d = ImageDraw.Draw(img, "RGBA")
    d.line((-30, 760, 70, 860), fill=(150, 120, 230, 70), width=16)
    d.line((70, 760, -30, 860), fill=(150, 120, 230, 70), width=16)
    d.ellipse((960, 1180, 1160, 1380), outline=(150, 120, 230, 70), width=14)
    return img


def add(a, b, k):
    """Soma de luz (screen simples) de b sobre a com intensidade k."""
    from PIL import ImageChops
    return ImageChops.add(a, b.point(lambda v: int(v * k)))


def sparkle(img, cx, cy, r, color):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    pts = []
    for i in range(8):
        ang = math.pi / 4 * i - math.pi / 2
        rr = r if i % 2 == 0 else r * 0.22
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    d.polygon(pts, fill=color + (255,))
    halo = layer.filter(ImageFilter.GaussianBlur(r * 0.6))
    img.alpha_composite(halo)
    img.alpha_composite(layer)


INDIC = ("hi-IN", "ne-NP", "bn-BD")


def segments(text, locale, size, bold=True):
    """Divide o texto em trechos com a fonte certa. As fontes Noto Devanagari e
    Bengali nao tem letras latinas (o "x" de 10x10 vira caixa), entao letras e
    digitos ASCII caem para a Fredoka."""
    main = font(locale, size, bold)
    if locale not in INDIC:
        return [(text, main)]
    latin = font("en-US", size, bold)
    out = []
    for ch in text:
        f = latin if (ch.isascii() and ch.isalnum()) else main
        if out and out[-1][1] is f:
            out[-1] = (out[-1][0] + ch, f)
        else:
            out.append((ch, f))
    return out


def mix_len(text, locale, size, bold=True):
    return sum(f.getlength(t) for t, f in segments(text, locale, size, bold))


def mix_draw(draw, x, baseline, text, locale, size, fill, bold=True):
    """Desenha alinhando pela linha de base; devolve o x final."""
    for t, f in segments(text, locale, size, bold):
        draw.text((x, baseline), t, font=f, fill=fill, anchor="ls")
        x += f.getlength(t)
    return x


def parse_runs(line):
    """'texto *DESTAQUE* fim' -> [(texto, False), (DESTAQUE, True), ...]"""
    runs, hi, buf = [], False, ""
    for ch in line:
        if ch == "*":
            if buf:
                runs.append((buf, hi))
            buf, hi = "", not hi
        else:
            buf += ch
    if buf:
        runs.append((buf, hi))
    return runs


def draw_headline(img, locale, title, sub, top=78, max_w=990):
    """Desenha titulo (1 ou 2 linhas, palavra *destacada* em amarelo) e subtitulo.
    Devolve o y final do bloco."""
    lines = title.split("\n")
    size = 90 if locale not in INDIC else 78
    while True:
        widths = [sum(mix_len(t, locale, size) for t, _ in parse_runs(ln)) for ln in lines]
        if max(widths) <= max_w or size <= 50:
            break
        size -= 2
    f = font(locale, size)
    asc, desc = f.getmetrics()
    line_h = int((asc + desc) * (1.02 if locale in INDIC else 0.98))
    text_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    td, gd, sd = ImageDraw.Draw(text_layer), ImageDraw.Draw(glow_layer), ImageDraw.Draw(shadow)
    y = top
    for ln, wdt in zip(lines, widths):
        x = (W - wdt) / 2
        base = y + asc
        for t, hi in parse_runs(ln):
            color = YELLOW if hi else WHITE
            mix_draw(sd, x, base + 6, t, locale, size, (10, 0, 30, 200))
            mix_draw(gd, x, base, t, locale, size, (YELLOW if hi else (190, 160, 255)) + (255 if hi else 110,))
            x = mix_draw(td, x, base, t, locale, size, color)
        y += line_h
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(8)))
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(22)))
    img.alpha_composite(text_layer)
    # subtitulo
    ssize = 44 if locale not in INDIC else 42
    while mix_len(sub, locale, ssize, False) > max_w - 20 and ssize > 30:
        ssize -= 1
    sf = font(locale, ssize, bold=False)
    sl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sw = mix_len(sub, locale, ssize, False)
    y += 14
    sbase = y + sf.getmetrics()[0]
    mix_draw(ImageDraw.Draw(sl), (W - sw) / 2, sbase + 3, sub, locale, ssize, (10, 0, 30, 220), False)
    img.alpha_composite(sl.filter(ImageFilter.GaussianBlur(4)))
    mix_draw(ImageDraw.Draw(img), (W - sw) / 2, sbase, sub, locale, ssize, SUB, False)
    sa, sdsc = sf.getmetrics()
    return y + sa + sdsc


_frame = None


def frame_img():
    global _frame
    if _frame is None:
        _frame = Image.open(FRAME).convert("RGBA")
    return _frame


def screen_mask():
    m = Image.new("L", (SCREEN_W, SCREEN_H), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, SCREEN_W - 1, SCREEN_H - 1), radius=60, fill=255)
    return m


def framed_phone(capture):
    """Captura do app (qualquer tamanho 390x844 n x) dentro do frame real."""
    fr = frame_img()
    shot = capture.convert("RGBA").resize((SCREEN_W, SCREEN_H), Image.LANCZOS)
    phone = Image.new("RGBA", fr.size, (0, 0, 0, 0))
    phone.paste(shot, (SCREEN_OFF, SCREEN_OFF), screen_mask())
    phone.alpha_composite(fr)
    return phone


def phone_geometry(head_bottom, need_css):
    top = head_bottom + 34
    need_px = SCREEN_OFF + need_css / CSS_H * SCREEN_H
    s = (H - 14 - top) / need_px
    s = max(0.6, min(0.86, s))
    return top, s


def place_phone(img, phone, top, s):
    pw, ph = int(phone.width * s), int(phone.height * s)
    p = phone.resize((pw, ph), Image.LANCZOS)
    x = (W - pw) // 2
    # sombra/brilho atras do aparelho
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((x + 10, top + 30, x + pw - 10, top + ph), radius=int(110 * s), fill=(8, 0, 24, 170))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(30)))
    gl = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(gl).rounded_rectangle((x - 20, top - 10, x + pw + 20, top + ph), radius=int(130 * s), fill=(150, 90, 255, 70))
    img.alpha_composite(gl.filter(ImageFilter.GaussianBlur(60)))
    img.alpha_composite(p, (x, top))
    return x, pw


def compose_still(capture_path, locale, key, idx):
    title, sub = CAPTIONS[locale][key]
    img = background().convert("RGBA")
    head_bottom = draw_headline(img, locale, title, sub)
    top, s = phone_geometry(head_bottom, NEED[key])
    x, pw = place_phone(img, framed_phone(Image.open(capture_path)), top, s)
    rnd = random.Random(idx * 31 + 5)
    spots = [(max(40, x - 34), top + rnd.randint(140, 260)),
             (min(1040, x + pw + 30), top + rnd.randint(480, 640)),
             (max(40, x - 30), rnd.randint(1450, 1650)),
             (min(1040, x + pw + 26), rnd.randint(1700, 1860))]
    for i, (sx, sy) in enumerate(spots):
        sparkle(img, sx, sy, 26 if i % 2 else 34, YELLOW if i % 2 == 0 else (120, 220, 255))
    return img.convert("RGB")


def main():
    cap, out = sys.argv[1], sys.argv[2]
    locs = sys.argv[3:] or list(CAPTIONS.keys())
    for loc in locs:
        od = os.path.join(out, loc)
        os.makedirs(od, exist_ok=True)
        for i, key in enumerate(["s1", "s2", "s3", "s4", "s5", "s6"], start=1):
            p = os.path.join(cap, loc, key, f"{key}.png")
            if not os.path.exists(p):
                print("faltando", p)
                continue
            im = compose_still(p, loc, key, i)
            assert im.size == (W, H) and im.mode == "RGB"
            im.save(os.path.join(od, f"{i:02d}.png"), optimize=True)
        print("ok", loc)


if __name__ == "__main__":
    main()
