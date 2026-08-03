#!/usr/bin/env python3
"""Gera os 16 icones 512x512 das conquistas no estilo neon do Tic Tac Verse.

Cada icone desenha o SIMBOLO da conquista (nao um trofeu generico), sobre o
gradiente violeta do app, com o glow da cor da faixa (bronze/prata/ouro). O
desenho e SVG gerado por codigo e rasterizado com rsvg-convert, entao regerar e
deterministico e nao depende de nenhum asset externo.

Uso:
  python3 tool/make_achievement_icons.py [--out DIR]

A paleta espelha lib/ui/widgets/modern_background.dart (VerseColors) e as cores
de faixa de lib/ui/widgets/achievements_sheet.dart.
"""

import argparse
import pathlib
import subprocess
import sys

SIZE = 512
REPO = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_OUT = REPO / 'build' / 'achievement-icons'

# VerseColors (modern_background.dart)
BG_TOP = '#2D1152'
BG_BOTTOM = '#1A0B2E'
CROSS = '#35D6FF'
NOUGHT = '#FF4FD8'
ENERGY = '#FFB938'

# achievementTierColor (achievements_sheet.dart)
TIER = {
    'bronze': '#CD8A4B',
    'silver': '#C7D0E0',
    'gold': '#FFB938',
}


def board(cx, cy, r, color, width=9, opacity=1.0):
    """Grade 3x3 do jogo da velha, centrada em (cx, cy), meia-largura r."""
    step = 2 * r / 3
    parts = []
    for i in (1, 2):
        x = cx - r + step * i
        y = cy - r + step * i
        parts.append(f'<line x1="{x:.1f}" y1="{cy - r:.1f}" '
                     f'x2="{x:.1f}" y2="{cy + r:.1f}"/>')
        parts.append(f'<line x1="{cx - r:.1f}" y1="{y:.1f}" '
                     f'x2="{cx + r:.1f}" y2="{y:.1f}"/>')
    return (f'<g stroke="{color}" stroke-width="{width}" stroke-linecap="round" '
            f'opacity="{opacity}">' + ''.join(parts) + '</g>')


def cell_center(cx, cy, r, col, row):
    step = 2 * r / 3
    return cx - r + step * (col + 0.5), cy - r + step * (row + 0.5)


def mark_x(x, y, s, color, width=13):
    return (f'<g stroke="{color}" stroke-width="{width}" stroke-linecap="round">'
            f'<line x1="{x - s:.1f}" y1="{y - s:.1f}" x2="{x + s:.1f}" y2="{y + s:.1f}"/>'
            f'<line x1="{x + s:.1f}" y1="{y - s:.1f}" x2="{x - s:.1f}" y2="{y + s:.1f}"/>'
            f'</g>')


def mark_o(x, y, s, color, width=13):
    return (f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{s:.1f}" fill="none" '
            f'stroke="{color}" stroke-width="{width}"/>')


def star(cx, cy, r, color):
    import math
    pts = []
    for i in range(10):
        radius = r if i % 2 == 0 else r * 0.44
        angle = -math.pi / 2 + i * math.pi / 5
        pts.append(f'{cx + radius * math.cos(angle):.1f},'
                   f'{cy + radius * math.sin(angle):.1f}')
    return f'<polygon points="{" ".join(pts)}" fill="{color}"/>'


def flame(cx, cy, r, color):
    """Chama com ponta afiada e uma lingua interna clara.

    O contorno importa: um "ovo" arredondado nao le como fogo em 48 px, que e o
    tamanho real na lista de conquistas do Play Games.
    """
    outer = (f'<path d="M {cx:.0f} {cy - r:.0f} '
             f'C {cx + r * 0.22:.0f} {cy - r * 0.52:.0f}, {cx + r * 0.72:.0f} {cy - r * 0.42:.0f}, {cx + r * 0.66:.0f} {cy + r * 0.12:.0f} '
             f'C {cx + r * 0.62:.0f} {cy + r * 0.72:.0f}, {cx + r * 0.24:.0f} {cy + r:.0f}, {cx:.0f} {cy + r:.0f} '
             f'C {cx - r * 0.24:.0f} {cy + r:.0f}, {cx - r * 0.62:.0f} {cy + r * 0.72:.0f}, {cx - r * 0.66:.0f} {cy + r * 0.12:.0f} '
             f'C {cx - r * 0.7:.0f} {cy - r * 0.3:.0f}, {cx - r * 0.16:.0f} {cy - r * 0.38:.0f}, {cx:.0f} {cy - r:.0f} Z" '
             f'fill="{color}"/>')
    inner = (f'<path d="M {cx:.0f} {cy - r * 0.18:.0f} '
             f'C {cx + r * 0.34:.0f} {cy + r * 0.16:.0f}, {cx + r * 0.28:.0f} {cy + r * 0.72:.0f}, {cx:.0f} {cy + r * 0.74:.0f} '
             f'C {cx - r * 0.28:.0f} {cy + r * 0.72:.0f}, {cx - r * 0.34:.0f} {cy + r * 0.16:.0f}, {cx:.0f} {cy - r * 0.18:.0f} Z" '
             f'fill="#1A0B2E" opacity="0.55"/>')
    return outer + inner


def bolt(cx, cy, r, color):
    return (f'<path d="M {cx + r * 0.25:.0f} {cy - r:.0f} L {cx - r * 0.55:.0f} {cy + r * 0.12:.0f} '
            f'L {cx - r * 0.02:.0f} {cy + r * 0.12:.0f} L {cx - r * 0.25:.0f} {cy + r:.0f} '
            f'L {cx + r * 0.6:.0f} {cy - r * 0.18:.0f} L {cx + r * 0.05:.0f} {cy - r * 0.18:.0f} Z" '
            f'fill="{color}"/>')


def calendar(cx, cy, r, color, filled_days):
    """Calendario com N quadradinhos marcados, para as conquistas de dias."""
    w = r * 1.7
    top = cy - r * 0.95
    parts = [f'<rect x="{cx - w / 2:.0f}" y="{top:.0f}" width="{w:.0f}" height="{r * 1.9:.0f}" '
             f'rx="{r * 0.18:.0f}" fill="none" stroke="{color}" stroke-width="11"/>',
             f'<line x1="{cx - w / 2:.0f}" y1="{top + r * 0.5:.0f}" x2="{cx + w / 2:.0f}" '
             f'y2="{top + r * 0.5:.0f}" stroke="{color}" stroke-width="11"/>']
    cell = w / 4.4
    for i in range(6):
        col, row = i % 3, i // 3
        x = cx - cell * 1.55 + col * cell * 1.5
        y = top + r * 0.85 + row * cell * 1.35
        opacity = 1.0 if i < filled_days else 0.28
        parts.append(f'<rect x="{x:.0f}" y="{y:.0f}" width="{cell * 0.9:.0f}" '
                     f'height="{cell * 0.9:.0f}" rx="{cell * 0.2:.0f}" fill="{color}" '
                     f'opacity="{opacity}"/>')
    return ''.join(parts)


def medal(cx, cy, r, color, rank_marks):
    parts = [f'<path d="M {cx - r * 0.55:.0f} {cy - r:.0f} L {cx - r * 0.2:.0f} {cy - r * 0.15:.0f} '
             f'L {cx + r * 0.2:.0f} {cy - r * 0.15:.0f} L {cx + r * 0.55:.0f} {cy - r:.0f}" '
             f'fill="none" stroke="{color}" stroke-width="13" stroke-linejoin="round"/>',
             f'<circle cx="{cx:.0f}" cy="{cy + r * 0.36:.0f}" r="{r * 0.56:.0f}" fill="none" '
             f'stroke="{color}" stroke-width="13"/>']
    for i in range(rank_marks):
        x = cx - (rank_marks - 1) * r * 0.17 + i * r * 0.34
        parts.append(f'<circle cx="{x:.0f}" cy="{cy + r * 0.36:.0f}" r="{r * 0.11:.0f}" fill="{color}"/>')
    return ''.join(parts)


def grid_of_modes(cx, cy, r, color):
    """5 blocos, um por modo de jogo."""
    parts = []
    positions = [(-1, -1), (0, -1), (1, -1), (-0.5, 0.35), (0.5, 0.35)]
    s = r * 0.5
    for col, row in positions:
        x = cx + col * r * 0.78 - s / 2
        y = cy + row * r * 0.85 - s / 2
        parts.append(f'<rect x="{x:.0f}" y="{y:.0f}" width="{s:.0f}" height="{s:.0f}" '
                     f'rx="{s * 0.22:.0f}" fill="{color}"/>')
    return ''.join(parts)


def big_board(cx, cy, r, color, accent):
    """Tabuleirao do Super Jogo da Velha com uma diagonal conquistada.

    A ideia obvia (desenhar 9 grades pequenas dentro da grande) vira borrao no
    tamanho real da lista. Casas CONQUISTADAS, preenchidas em bloco, mantem a
    leitura "venceu o tabuleirao" mesmo pequeno.
    """
    step = 2 * r / 3
    parts = [board(cx, cy, r, color, width=12)]
    for i in range(3):
        x, y = cell_center(cx, cy, r, i, i)
        half = step * 0.34
        parts.append(f'<rect x="{x - half:.0f}" y="{y - half:.0f}" '
                     f'width="{half * 2:.0f}" height="{half * 2:.0f}" '
                     f'rx="{half * 0.32:.0f}" fill="{accent}"/>')
    return ''.join(parts)


def infinity_sign(cx, cy, r, color):
    return (f'<path d="M {cx:.0f} {cy:.0f} '
            f'C {cx - r * 0.35:.0f} {cy - r * 0.75:.0f}, {cx - r:.0f} {cy - r * 0.62:.0f}, {cx - r:.0f} {cy:.0f} '
            f'C {cx - r:.0f} {cy + r * 0.62:.0f}, {cx - r * 0.35:.0f} {cy + r * 0.75:.0f}, {cx:.0f} {cy:.0f} '
            f'C {cx + r * 0.35:.0f} {cy - r * 0.75:.0f}, {cx + r:.0f} {cy - r * 0.62:.0f}, {cx + r:.0f} {cy:.0f} '
            f'C {cx + r:.0f} {cy + r * 0.62:.0f}, {cx + r * 0.35:.0f} {cy + r * 0.75:.0f}, {cx:.0f} {cy:.0f} Z" '
            f'fill="none" stroke="{color}" stroke-width="15" stroke-linecap="round"/>')


def crown(cx, cy, r, color):
    return (f'<path d="M {cx - r:.0f} {cy + r * 0.55:.0f} L {cx - r * 0.82:.0f} {cy - r * 0.6:.0f} '
            f'L {cx - r * 0.36:.0f} {cy + r * 0.05:.0f} L {cx:.0f} {cy - r * 0.85:.0f} '
            f'L {cx + r * 0.36:.0f} {cy + r * 0.05:.0f} L {cx + r * 0.82:.0f} {cy - r * 0.6:.0f} '
            f'L {cx + r:.0f} {cy + r * 0.55:.0f} Z" fill="{color}"/>'
            f'<rect x="{cx - r:.0f}" y="{cy + r * 0.62:.0f}" width="{2 * r:.0f}" '
            f'height="{r * 0.3:.0f}" rx="{r * 0.1:.0f}" fill="{color}"/>')


def winning_line_board(cx, cy, r, color, accent):
    """Tres X em linha com o risco da vitoria.

    A GRADE FOI REMOVIDA de proposito: no tamanho real da lista do Play Games
    (~48 px) as linhas do tabuleiro viram ruido e engolem as marcas. Sem ela, a
    leitura "linha de tres" sobrevive ao downscale.
    """
    step = r * 0.72
    parts = []
    for i in (-1, 0, 1):
        parts.append(mark_x(cx + i * step, cy, r * 0.28, accent, width=20))
    parts.append(f'<line x1="{cx - step - r * 0.46:.0f}" y1="{cy:.0f}" '
                 f'x2="{cx + step + r * 0.46:.0f}" y2="{cy:.0f}" '
                 f'stroke="#FFFFFF" stroke-width="13" stroke-linecap="round" '
                 f'opacity="0.92"/>')
    return ''.join(parts)


def robot(cx, cy, r, color):
    return (f'<rect x="{cx - r * 0.8:.0f}" y="{cy - r * 0.55:.0f}" width="{r * 1.6:.0f}" '
            f'height="{r * 1.3:.0f}" rx="{r * 0.28:.0f}" fill="none" stroke="{color}" stroke-width="13"/>'
            f'<circle cx="{cx - r * 0.32:.0f}" cy="{cy:.0f}" r="{r * 0.15:.0f}" fill="{color}"/>'
            f'<circle cx="{cx + r * 0.32:.0f}" cy="{cy:.0f}" r="{r * 0.15:.0f}" fill="{color}"/>'
            f'<line x1="{cx:.0f}" y1="{cy - r * 0.55:.0f}" x2="{cx:.0f}" y2="{cy - r * 0.95:.0f}" '
            f'stroke="{color}" stroke-width="11" stroke-linecap="round"/>'
            f'<circle cx="{cx:.0f}" cy="{cy - r:.0f}" r="{r * 0.13:.0f}" fill="{color}"/>')


# id -> (faixa, funcao de desenho). O desenho recebe (cx, cy, r, tint).
ICONS = {
    'first_win':        ('bronze', lambda c, y, r, t: winning_line_board(c, y, r, '#7A5FA8', t)),
    'wins_10':          ('bronze', lambda c, y, r, t: medal(c, y, r, t, 1)),
    'wins_50':          ('silver', lambda c, y, r, t: medal(c, y, r, t, 2)),
    'wins_200':         ('gold',   lambda c, y, r, t: crown(c, y, r, t)),
    'streak_3':         ('bronze', lambda c, y, r, t: flame(c, y, r * 0.95, t)),
    'streak_7':         ('silver', lambda c, y, r, t: ''.join([
        flame(c - r * 0.62, y + r * 0.2, r * 0.6, t),
        flame(c + r * 0.62, y + r * 0.2, r * 0.6, t),
        flame(c, y - r * 0.05, r * 0.88, t),
    ])),
    'streak_15':        ('gold',   lambda c, y, r, t: infinity_sign(c, y, r * 0.9, t)),
    'hard_win':         ('gold',   lambda c, y, r, t: robot(c, y, r * 0.9, t)),
    'all_modes':        ('silver', lambda c, y, r, t: grid_of_modes(c, y, r, t)),
    'ultimate_wins_10': ('silver', lambda c, y, r, t: big_board(c, y, r, t, CROSS)),
    'daily_3':          ('bronze', lambda c, y, r, t: calendar(c, y, r, t, 3)),
    'daily_7':          ('silver', lambda c, y, r, t: calendar(c, y, r, t, 5)),
    'daily_30':         ('gold',   lambda c, y, r, t: calendar(c, y, r, t, 6)),
    'fast_win':         ('silver', lambda c, y, r, t: bolt(c, y, r, t)),
    'matches_50':       ('bronze', lambda c, y, r, t: ''.join([
        mark_x(c - r * 0.42, y - r * 0.42, r * 0.3, t),
        mark_o(c + r * 0.42, y - r * 0.42, r * 0.3, t),
        mark_o(c - r * 0.42, y + r * 0.42, r * 0.3, t),
        mark_x(c + r * 0.42, y + r * 0.42, r * 0.3, t),
    ])),
    'matches_250':      ('gold',   lambda c, y, r, t: ''.join([
        star(c, y - r * 0.34, r * 0.52, t),
        star(c - r * 0.6, y + r * 0.46, r * 0.38, t),
        star(c + r * 0.6, y + r * 0.46, r * 0.38, t),
    ])),
}


def svg_for(local_id):
    tier, draw = ICONS[local_id]
    tint = TIER[tier]
    c = SIZE / 2
    r = SIZE * 0.27
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{BG_TOP}"/>
      <stop offset="1" stop-color="{BG_BOTTOM}"/>
    </linearGradient>
    <radialGradient id="halo" cx="50%" cy="46%" r="52%">
      <stop offset="0" stop-color="{tint}" stop-opacity="0.34"/>
      <stop offset="1" stop-color="{tint}" stop-opacity="0"/>
    </radialGradient>
    <filter id="glow" x="-45%" y="-45%" width="190%" height="190%">
      <feGaussianBlur stdDeviation="11" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <rect width="{SIZE}" height="{SIZE}" fill="url(#bg)"/>
  <circle cx="{c}" cy="{c}" r="{SIZE * 0.42:.0f}" fill="url(#halo)"/>
  <circle cx="{c}" cy="{c}" r="{SIZE * 0.40:.0f}" fill="none" stroke="{tint}"
          stroke-width="7" opacity="0.55"/>
  <g filter="url(#glow)">{draw(c, c, r, tint)}</g>
</svg>'''


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--out', default=str(DEFAULT_OUT))
    args = parser.parse_args()

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    # A ordem do catalogo importa so para o log; o conjunto tem de bater.
    catalog_ids = _catalog_ids()
    missing = catalog_ids - set(ICONS)
    extra = set(ICONS) - catalog_ids
    if missing or extra:
        print(f'ERRO: icones fora de sincronia com o catalogo.\n'
              f'  sem icone: {sorted(missing)}\n'
              f'  sobrando:  {sorted(extra)}', file=sys.stderr)
        return 1

    for local_id in sorted(ICONS):
        svg_path = out / f'{local_id}.svg'
        png_path = out / f'{local_id}.png'
        svg_path.write_text(svg_for(local_id), encoding='utf-8')
        subprocess.run(
            ['rsvg-convert', '-w', str(SIZE), '-h', str(SIZE),
             '-o', str(png_path), str(svg_path)],
            check=True, capture_output=True)
        svg_path.unlink()
        print(f'  {local_id:18} -> {png_path.name} ({png_path.stat().st_size // 1024} KB)')

    print(f'\n{len(ICONS)} icones em {out}')
    return 0


def _catalog_ids():
    import re
    dart = (REPO / 'lib/models/achievement.dart').read_text('utf-8')
    return set(re.findall(r"id:\s*'([a-z0-9_]+)'", dart))


if __name__ == '__main__':
    sys.exit(main())
