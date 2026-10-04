"""Monta o video promocional 9:16 (1080x1920, H.264, 30 fps) com gameplay real.

Uso: python3 make_video.py <capDir> <outDir> [locale ...]
  capDir/<locale>/v1..v4/frames/*.jpg + index.tsv + marks.tsv (drive.mjs com record)

Cada clipe vira um segmento com legenda propria; a captura entra dentro do frame
real do Pixel 5. Pausas paradas maiores que MAX_GAP sao encurtadas (a maquina de
captura e lenta) e o resto acelera SPEED vezes. Fecha com cartao do icone.
"""
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFilter

import compose as C
from captions import VIDEO

FPS = 30
SPEED = 1.6
MAX_GAP = 450       # ms de tela parada mantidos (no tempo da captura)
FADE = 8            # quadros de transicao entre segmentos
NEED = 812          # px CSS visiveis (o modal de vitoria fica embaixo)
TARGET = {"v1": 9.5, "v2": 6.0, "v3": 5.5, "v4": 5.0}  # teto de segundos por segmento
HOLD = {"v1": 0.3, "v2": 0.3, "v3": 0.3, "v4": 2.2}  # segundos parados no ultimo quadro (o modal de vitoria)
END_SECONDS = 3.0
ICON = os.path.join(C.ROOT, "assets", "icon", "app_icon.png")


def load_clip(d):
    rows = [ln.split("\t") for ln in open(os.path.join(d, "index.tsv")).read().split("\n") if ln.strip()]
    marks = [ln.split("\t") for ln in open(os.path.join(d, "marks.tsv")).read().split("\n") if ln.strip()]
    frames = [(int(ms), os.path.join(d, "frames", f"f{int(i):05d}.jpg")) for i, ms in rows]
    start = max(0, int(marks[0][0]) - 500) if marks else 0
    frames = [f for f in frames if f[0] >= start] or frames[-1:]
    # remapeia o tempo encurtando pausas paradas
    out, t, prev = [], 0, None
    for ms, path in frames:
        if prev is not None:
            t += min(ms - prev, MAX_GAP)
        out.append((t, path))
        prev = ms
    out.append((t + 600, out[-1][1]))  # segura o ultimo quadro um pouco
    return out


def clip_frames(clip, key):
    total = clip[-1][0]
    speed = max(SPEED, total / 1000.0 / TARGET[key])
    n = int(total / speed / 1000.0 * FPS)
    j = 0
    for k in range(n):
        src = k * 1000.0 / FPS * speed
        while j + 1 < len(clip) and clip[j + 1][0] <= src:
            j += 1
        yield clip[j][1]
    for _ in range(int(HOLD[key] * FPS)):
        yield clip[-1][1]


class Stage:
    """Fundo + legenda + geometria do aparelho para um idioma."""

    def __init__(self, locale):
        self.locale = locale
        heads = {}
        bottoms = []
        for key in ("v1", "v2", "v3", "v4"):
            title, sub = VIDEO[locale][key]
            img = C.background().convert("RGBA")
            bottoms.append(C.draw_headline(img, locale, title, sub))
            heads[key] = img
        top, s = C.phone_geometry(max(bottoms), NEED)
        fr = C.frame_img()
        self.pw, self.ph = int(fr.width * s), int(fr.height * s)
        self.x, self.top = (C.W - self.pw) // 2, top
        self.frame = fr.resize((self.pw, self.ph), Image.LANCZOS)
        self.sx = self.sy = int(C.SCREEN_OFF * s)
        self.sw, self.sh = int(C.SCREEN_W * s), int(C.SCREEN_H * s)
        m = Image.new("L", (self.sw, self.sh), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, self.sw - 1, self.sh - 1), radius=int(60 * s), fill=255)
        self.mask = m
        self.bases = {}
        for key, img in heads.items():
            # sombra/brilho do aparelho desenhados uma vez no fundo
            dummy = Image.new("RGBA", fr.size, (0, 0, 0, 0))
            C.place_phone(img, dummy, top, s)
            for i, (sx, sy) in enumerate([(max(40, self.x - 34), top + 200), (min(1040, self.x + self.pw + 30), top + 560),
                                          (max(40, self.x - 30), 1560), (min(1040, self.x + self.pw + 26), 1780)]):
                C.sparkle(img, sx, sy, 26 if i % 2 else 34, C.YELLOW if i % 2 == 0 else (120, 220, 255))
            self.bases[key] = img
        self._cache = {}

    def render(self, key, shot_path):
        img = self.bases[key].copy()
        shot = Image.open(shot_path).convert("RGB").resize((self.sw, self.sh), Image.BILINEAR)
        img.paste(shot, (self.x + self.sx, self.top + self.sy), self.mask)
        img.alpha_composite(self.frame, (self.x, self.top))
        return img.convert("RGB")

    def _end_static(self):
        img = C.background().convert("RGBA")
        title, sub = VIDEO[self.locale]["end"]
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        C.draw_headline(layer, "en-US", "Tic Tac *Verse*", " ", top=1000)
        img.alpha_composite(layer)
        layer2 = Image.new("RGBA", img.size, (0, 0, 0, 0))
        C.draw_headline(layer2, self.locale, title, sub, top=1170)
        img.alpha_composite(layer2)
        C.sparkle(img, 200, 520, 34, C.YELLOW)
        C.sparkle(img, 890, 900, 28, (120, 220, 255))
        C.sparkle(img, 860, 420, 22, C.YELLOW)
        glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
        cx, cy, r = C.W // 2, 700, 240
        ImageDraw.Draw(glow).rounded_rectangle((cx - r, cy - r, cx + r, cy + r), radius=130, fill=(170, 90, 255, 160))
        self._end = (img, glow.filter(ImageFilter.GaussianBlur(50)), Image.open(ICON).convert("RGBA"))

    def end_card(self, t):
        """Cartao final: icone + nome do jogo; t de 0 a 1 anima a entrada."""
        if not hasattr(self, "_end"):
            self._end_static()
        base, glow, icon = self._end
        img = base.copy()
        ease = 1 - (1 - min(1.0, t * 2.2)) ** 3
        g = glow.copy()
        g.putalpha(g.getchannel("A").point(lambda v: int(v * ease)))
        img.alpha_composite(g)
        size = int(420 * (0.82 + 0.18 * ease))
        ic = icon.resize((size, size), Image.LANCZOS)
        m = Image.new("L", (size, size), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
        holder = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        holder.paste(ic, (0, 0), m)
        img.alpha_composite(holder, (C.W // 2 - size // 2, 700 - size // 2))
        return img.convert("RGB")


def build(cap, out, locale):
    st = Stage(locale)
    path = os.path.join(out, f"{locale}.mp4")
    ff = subprocess.Popen(["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
                           "-s", f"{C.W}x{C.H}", "-r", str(FPS), "-i", "-",
                           "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-pix_fmt", "yuv420p",
                           "-profile:v", "high", "-movflags", "+faststart", "-r", str(FPS), path],
                          stdin=subprocess.PIPE)
    last = None
    count = 0
    for key in ("v1", "v2", "v3", "v4"):
        clip = load_clip(os.path.join(cap, locale, key))
        k = 0
        for fp in clip_frames(clip, key):
            fr = st.render(key, fp)
            if last is not None and k < FADE:
                fr = Image.blend(last, fr, (k + 1) / (FADE + 1))
            ff.stdin.write(fr.tobytes())
            count += 1
            k += 1
            prev_frame = fr
        last = prev_frame
    n_end = int(END_SECONDS * FPS)
    for k in range(n_end):
        fr = st.end_card(k / n_end)
        if k < FADE:
            fr = Image.blend(last, fr, (k + 1) / (FADE + 1))
        ff.stdin.write(fr.tobytes())
        count += 1
    ff.stdin.close()
    ff.wait()
    print("ok", path, f"{count / FPS:.1f}s")


def main():
    cap, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    for loc in sys.argv[3:] or list(VIDEO.keys()):
        build(cap, out, loc)


if __name__ == "__main__":
    main()
