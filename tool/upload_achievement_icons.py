#!/usr/bin/env python3
"""Sobe os icones das conquistas (e do placar) para o Play Games Services.

Usa o endpoint de upload de imagem da Publishing API, com a mesma service
account da skill google-play. Idempotente na pratica: reenviar substitui o
icone anterior.

Uso:
  python3 tool/make_achievement_icons.py                 # gera os PNGs
  python3 tool/upload_achievement_icons.py               # sobe todos
  python3 tool/upload_achievement_icons.py --only fast_win
  python3 tool/upload_achievement_icons.py --leaderboard build/.../level.png
"""

import argparse
import json
import pathlib
import re
import sys
import urllib.error
import urllib.request

sys.path.insert(0, str(pathlib.Path.home() / '.claude/skills/google-play/scripts'))

REPO = pathlib.Path(__file__).resolve().parent.parent
IDS_DART = REPO / 'lib/services/play_games_ids.dart'
DEFAULT_ICONS = REPO / 'build' / 'achievement-icons'
UPLOAD = 'https://www.googleapis.com/upload/games/v1configuration/images'


def die(msg):
    print(f'ERRO: {msg}', file=sys.stderr)
    sys.exit(1)


def load_ids():
    """Le o mapa gerado: nosso id -> id do Play Games, e o id do placar."""
    if not IDS_DART.exists():
        die(f'nao achei {IDS_DART}; rode tool/play_games_setup.py antes')
    text = IDS_DART.read_text('utf-8')
    body = text.split('playGamesAchievementIds', 1)[-1].split('};', 1)[0]
    ids = dict(re.findall(r"'([a-z0-9_]+)':\s*'([^']+)'", body))
    lb = re.search(r"playGamesLevelLeaderboardId\s*=\s*'([^']*)'", text)
    return ids, (lb.group(1) if lb else '')


def upload(resource_id, image_type, path, token):
    data = path.read_bytes()
    url = f'{UPLOAD}/{resource_id}/{image_type}?uploadType=media'
    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Content-Type', 'image/png')
    req.add_header('Content-Length', str(len(data)))
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        die(f'POST {url}\nHTTP {exc.code}: {exc.read().decode()[:500]}')


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--icons', default=str(DEFAULT_ICONS),
                        help='pasta com <id>.png')
    parser.add_argument('--only', help='sobe so esta conquista')
    parser.add_argument('--leaderboard', help='PNG do icone do placar')
    args = parser.parse_args()

    icons_dir = pathlib.Path(args.icons)
    ids, leaderboard_id = load_ids()
    if not ids:
        die('mapa de ids vazio; rode tool/play_games_setup.py --write-dart antes')

    import gplay  # a skill resolve a service account
    token = gplay.access_token()

    targets = {args.only: ids[args.only]} if args.only else ids
    if args.only and args.only not in ids:
        die(f'"{args.only}" nao esta no mapa de ids')

    sent = 0
    for local_id, remote_id in targets.items():
        path = icons_dir / f'{local_id}.png'
        if not path.exists():
            print(f'  ! {local_id:18} sem PNG em {path}, pulando')
            continue
        result = upload(remote_id, 'ACHIEVEMENT_ICON', path, token)
        print(f'  + {local_id:18} enviado ({path.stat().st_size // 1024} KB)'
              f'{" -> " + result["url"][:48] if result.get("url") else ""}')
        sent += 1

    if args.leaderboard:
        if not leaderboard_id:
            die('nao ha id de placar em play_games_ids.dart')
        lb_path = pathlib.Path(args.leaderboard)
        if not lb_path.exists():
            die(f'nao achei {lb_path}')
        upload(leaderboard_id, 'LEADERBOARD_ICON', lb_path, token)
        print(f'  + placar de nivel        enviado')
        sent += 1

    print(f'\n{sent} imagem(ns) enviada(s).')


if __name__ == '__main__':
    main()
