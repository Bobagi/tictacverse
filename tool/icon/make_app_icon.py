"""Gera o ícone do app (X e O neon sobre grade) em SVG e PNG.

Saídas em assets/icon/:
  app_icon.png    1024 cheio (ícone legado, splash, logo da home, Play 512)
  icon_bg.png     camada de fundo do ícone adaptativo (degradê + grade)
  icon_fg.png     camada da frente (só as peças, fundo transparente)

Requer rsvg-convert. Uso: python3 tool/icon/make_app_icon.py
"""
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'assets', 'icon')

DEFS = '''<defs>
<radialGradient id="bg" cx="50%" cy="40%" r="75%"><stop offset="0" stop-color="#4a1a8a"/><stop offset="0.55" stop-color="#2a0f55"/><stop offset="1" stop-color="#120726"/></radialGradient>
<linearGradient id="xg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8ff0ff"/><stop offset="1" stop-color="#35d6ff"/></linearGradient>
<linearGradient id="og" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff9be8"/><stop offset="1" stop-color="#ff4fd8"/></linearGradient>
<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="16" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="glowS" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
</defs>'''


def piece_x(cx, cy, r, w):
    lines = (f'<line x1="{cx-r}" y1="{cy-r}" x2="{cx+r}" y2="{cy+r}"/>'
             f'<line x1="{cx+r}" y1="{cy-r}" x2="{cx-r}" y2="{cy+r}"/>')
    return (f'<g filter="url(#glow)" stroke="url(#xg)" stroke-width="{w}" stroke-linecap="round">{lines}</g>'
            f'<g stroke="#fff" stroke-opacity=".85" stroke-width="{w*0.3}" stroke-linecap="round">{lines}</g>')


def piece_o(cx, cy, r, w):
    return (f'<circle filter="url(#glow)" cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="url(#og)" stroke-width="{w}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="#fff" stroke-opacity=".85" stroke-width="{w*0.3}"/>')


def grid(half, w):
    x0, s = 512 - half, 2 * half
    c = s / 3
    out = f'<g filter="url(#glowS)" stroke="#9d7bff" stroke-opacity=".5" stroke-width="{w}" stroke-linecap="round">'
    for i in (1, 2):
        out += (f'<line x1="{x0+c*i}" y1="{x0}" x2="{x0+c*i}" y2="{x0+s}"/>'
                f'<line x1="{x0}" y1="{x0+c*i}" x2="{x0+s}" y2="{x0+c*i}"/>')
    return out + '</g>'


def pieces(s):
    return piece_x(512 - 150 * s, 512, 120 * s, 70 * s) + piece_o(512 + 160 * s, 512, 118 * s, 64 * s)


def svg(body, background=True):
    bg = '<rect width="1024" height="1024" fill="url(#bg)"/>' if background else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{DEFS}{bg}{body}</svg>'


# No adaptativo, a janela visível é o centro 2/3 da camada de fundo, e a da
# frente (com o inset de 16% do flutter_launcher_icons) ocupa essa janela
# inteira. Por isso a grade do fundo encolhe 2/3 e as peças não.
SCALE = 1.12
LAYERS = {
    'app_icon': svg(grid(330 * SCALE, 16 * SCALE) + pieces(SCALE)),
    'icon_bg': svg(grid(330 * SCALE * 2 / 3, 16 * SCALE * 2 / 3)),
    'icon_fg': svg(pieces(SCALE), background=False),
}

for name, content in LAYERS.items():
    src = os.path.join(OUT, f'{name}.svg')
    with open(src, 'w') as f:
        f.write(content)
    subprocess.run(['rsvg-convert', '-w', '1024', '-h', '1024', src, '-o',
                    os.path.join(OUT, f'{name}.png')], check=True)
    os.remove(src)
    print('ok', name)
