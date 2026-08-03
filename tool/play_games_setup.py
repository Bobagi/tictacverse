#!/usr/bin/env python3
"""Cria as conquistas do Tic Tac Verse no Play Games Services e gera o mapa de ids.

Por que existe: cadastrar 16 conquistas x 6 idiomas na mao no Play Console sao
192 campos digitados. A Publishing API do PGS faz isso, e os textos ja estao
traduzidos nas ARB do proprio app, entao da para gerar tudo de uma fonte so.

Pre-requisito (unico passo manual do operador):
  Play Console -> o app -> Crescer -> Servicos de jogos do Play -> Configuracao
  e gerenciamento -> Configuracao. Criar o jogo, vincular o app Android com o
  SHA-1 da chave de assinatura, e anotar o **ID do projeto** (um numero longo).

Uso:
  python3 tool/play_games_setup.py --app-id <ID_DO_PROJETO> [--dry-run]
  python3 tool/play_games_setup.py --app-id <ID> --write-dart

Autenticacao: reusa a service account da skill google-play
(~/.config/bobagi-google/play-service-account.json), com o mesmo escopo
androidpublisher. A service account precisa estar convidada no Play Console.

Idempotente: lista o que ja existe e cria so o que falta, casando pelo `token`
(que aqui e o nosso id estavel do catalogo).
"""

import argparse
import json
import pathlib
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, str(pathlib.Path.home() / '.claude/skills/google-play/scripts'))

REPO = pathlib.Path(__file__).resolve().parent.parent
ARB_DIR = REPO / 'lib/l10n'
CATALOG_DART = REPO / 'lib/models/achievement.dart'
IDS_DART = REPO / 'lib/services/play_games_ids.dart'
API = 'https://www.googleapis.com/games/v1configuration'

# Idioma da ARB -> locale que o Play Games espera.
LOCALES = {
    'en': 'en-US', 'pt': 'pt-BR', 'es': 'es-ES',
    'hi': 'hi-IN', 'bn': 'bn-BD', 'ne': 'ne-NP',
}

# Pontos do PGS por faixa. ATENCAO: o Play Games limita a soma de TODOS os
# achievements a 1000 pontos; esta divisao da 925, deixando folga para 1 ou 2
# conquistas novas antes de precisar rebalancear.
TIER_POINTS = {'bronze': 25, 'silver': 50, 'gold': 100}

# Espelho do catalogo em lib/models/achievement.dart. `desc_arg` e o numero que
# entra no placeholder {count}; None = descricao sem placeholder.
# A consistencia com o Dart e verificada em check_catalog_matches_dart().
CATALOG = [
    ('first_win',        'bronze', 'achFirstWinTitle',      'achFirstWinDesc',       None),
    ('wins_10',          'bronze', 'achWins10Title',        'achDescWins',           10),
    ('wins_50',          'silver', 'achWins50Title',        'achDescWins',           50),
    ('wins_200',         'gold',   'achWins200Title',       'achDescWins',           200),
    ('streak_3',         'bronze', 'achStreak3Title',       'achDescStreak',         3),
    ('streak_7',         'silver', 'achStreak7Title',       'achDescStreak',         7),
    ('streak_15',        'gold',   'achStreak15Title',      'achDescStreak',         15),
    ('hard_win',         'gold',   'achHardWinTitle',       'achHardWinDesc',        None),
    ('all_modes',        'silver', 'achAllModesTitle',      'achAllModesDesc',       None),
    ('ultimate_wins_10', 'silver', 'achUltimateWinsTitle',  'achDescUltimateWins',   10),
    ('daily_3',          'bronze', 'achDaily3Title',        'achDescDaily',          3),
    ('daily_7',          'silver', 'achDaily7Title',        'achDescDaily',          7),
    ('daily_30',         'gold',   'achDaily30Title',       'achDescDaily',          30),
    ('fast_win',         'silver', 'achFastWinTitle',       'achFastWinDesc',        None),
    ('matches_50',       'bronze', 'achMatches50Title',     'achDescMatches',        50),
    ('matches_250',      'gold',   'achMatches250Title',    'achDescMatches',        250),
]


def die(msg):
    print(f'ERRO: {msg}', file=sys.stderr)
    sys.exit(1)


def check_catalog_matches_dart():
    """Falha alto se o catalogo Dart e esta tabela sairem de sincronia."""
    if not CATALOG_DART.exists():
        die(f'nao achei {CATALOG_DART}')
    dart_ids = set(re.findall(r"id:\s*'([a-z0-9_]+)'", CATALOG_DART.read_text('utf-8')))
    here = {row[0] for row in CATALOG}
    if dart_ids != here:
        die('catalogo fora de sincronia com o Dart.\n'
            f'  so no Dart: {sorted(dart_ids - here)}\n'
            f'  so aqui:    {sorted(here - dart_ids)}\n'
            'Atualize CATALOG nesta ferramenta.')


def load_arb():
    out = {}
    for lang in LOCALES:
        path = ARB_DIR / f'app_{lang}.arb'
        if not path.exists():
            die(f'nao achei {path}')
        out[lang] = json.loads(path.read_text('utf-8'))
    return out


def localized(arb, key, arg):
    """LocalizedStringBundle com as 6 linguas, resolvendo o placeholder."""
    strings = []
    for lang, locale in LOCALES.items():
        value = arb[lang].get(key)
        if value is None:
            die(f'chave {key} ausente em app_{lang}.arb')
        if arg is not None:
            value = value.replace('{count}', str(arg))
        # O Play Games corta nome em 100 e descricao em 370 caracteres.
        strings.append({
            'kind': 'gamesConfiguration#localizedString',
            'locale': locale,
            'value': value[:370],
        })
    return {
        'kind': 'gamesConfiguration#localizedStringBundle',
        'translations': strings,
    }


def request(method, url, token, body=None, tolerate=False):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header('Authorization', f'Bearer {token}')
    if data:
        req.add_header('Content-Type', 'application/json')
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode()
        if tolerate:
            return {'_error': detail, '_code': exc.code}
        die(f'{method} {url}\nHTTP {exc.code}: {detail[:600]}')


UNSUPPORTED_LOCALE = re.compile(r'locale ([\w-]+) in the \w+ field is not supported')


def insert_dropping_unsupported(url, token, body, locales, dropped):
    """Insere a conquista, tirando do corpo os idiomas que o projeto do PGS
    ainda nao habilitou.

    O projeto nasce so com en-US: os outros so passam a ser aceitos depois que
    o operador adiciona o idioma no Console. Em vez de falhar tudo, derrubamos
    o idioma recusado e tentamos de novo, registrando o que ficou de fora (nunca
    silenciosamente: quem le a saida precisa saber que faltou traducao).
    """
    for _ in range(len(locales) + 1):
        result = request('POST', url, token, body, tolerate=True)
        if '_error' not in result:
            return result
        match = UNSUPPORTED_LOCALE.search(result['_error'])
        if not match:
            die(f'POST {url}\nHTTP {result["_code"]}: {result["_error"][:600]}')
        bad = match.group(1)
        dropped.add(bad)
        for field in ('name', 'description'):
            body['draft'][field]['translations'] = [
                t for t in body['draft'][field]['translations']
                if t['locale'] != bad
            ]
        if not body['draft']['name']['translations']:
            die('nenhum idioma aceito pelo projeto do Play Games')
    die('nao consegui inserir mesmo depois de remover os idiomas recusados')


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--app-id', required=True,
                        help='ID do projeto de Servicos de jogos do Play')
    parser.add_argument('--dry-run', action='store_true',
                        help='so mostra o que criaria')
    parser.add_argument('--write-dart', action='store_true',
                        help='regrava lib/services/play_games_ids.dart')
    parser.add_argument('--leaderboard-id', default='',
                        help='id do placar de nivel, se ja existir')
    parser.add_argument('--sync-translations', action='store_true',
                        help='regrava os textos das conquistas que ja existem '
                             '(use depois de habilitar os idiomas no Console)')
    parser.add_argument('--create-leaderboard', action='store_true',
                        help='cria o placar de nivel se ainda nao existir')
    args = parser.parse_args()

    check_catalog_matches_dart()
    arb = load_arb()

    total_points = sum(TIER_POINTS[row[1]] for row in CATALOG)
    if total_points > 1000:
        die(f'a soma de pontos ({total_points}) passa do limite de 1000 do Play Games')

    import gplay  # noqa: E402  (a skill resolve a service account)
    token = gplay.access_token()

    base = f'{API}/applications/{urllib.parse.quote(args.app_id)}/achievements'
    listing = request('GET', f'{base}?maxResults=200', token)
    remote_items = listing.get('items', [])
    existing = match_existing(remote_items, arb)
    print(f'ja existem {len(remote_items)} conquistas no projeto '
          f'({len(existing)} reconhecidas como nossas)')

    if args.sync_translations:
        if args.dry_run:
            die('--sync-translations nao tem dry-run: rode sem --dry-run')
        sync_translations(base, token, arb, existing)
        return

    ids = {}
    dropped = set()
    for rank, (local_id, tier, title_key, desc_key, desc_arg) in enumerate(CATALOG, start=1):
        if local_id in existing:
            ids[local_id] = existing[local_id]
            print(f'  = {local_id:18} ja existe ({existing[local_id]})')
            continue
        body = {
            'kind': 'gamesConfiguration#achievementConfiguration',
            'achievementType': 'STANDARD',
            'initialState': 'REVEALED',
            'token': local_id,
            'draft': {
                'kind': 'gamesConfiguration#achievementConfigurationDetail',
                'name': localized(arb, title_key, None),
                'description': localized(arb, desc_key, desc_arg),
                'pointValue': TIER_POINTS[tier],
                'sortRank': rank,
            },
        }
        if args.dry_run:
            print(f'  + {local_id:18} criaria ({tier}, {TIER_POINTS[tier]} pts)')
            continue
        created = insert_dropping_unsupported(base, token, body,
                                              list(LOCALES.values()), dropped)
        ids[local_id] = created['id']
        print(f'  + {local_id:18} criada -> {created["id"]}')

    if args.dry_run:
        print(f'\ndry-run: nada foi criado. Total de pontos: {total_points}/1000')
        return

    if dropped:
        print('\nATENCAO: estes idiomas ainda NAO estao habilitados no projeto do '
              'Play Games, entao as conquistas foram criadas sem eles:')
        print('  ' + ', '.join(sorted(dropped)))
        print('  Habilite em: Play Console -> Servicos de jogos do Play -> '
              'Configuracao -> Idiomas (ou "Traducoes"), e rode este script de '
              'novo com --sync-translations para preencher os textos.')

    leaderboard_id = args.leaderboard_id
    if args.create_leaderboard:
        leaderboard_id = ensure_leaderboard(args.app_id, token, arb) or leaderboard_id

    if args.write_dart:
        write_dart(ids, leaderboard_id)
        print(f'\n{IDS_DART.relative_to(REPO)} regravado com {len(ids)} ids.')
    else:
        print('\nids (use --write-dart para gravar no Dart):')
        print(json.dumps(ids, indent=2))

    print('\nFALTA VOCE NO CONSOLE: subir o icone de cada conquista (512x512) e '
          'publicar as alteracoes dos Servicos de jogos. Ate publicar, elas so '
          'valem para contas de teste.')


def match_existing(remote_items, arb):
    """Casa as conquistas que ja estao no Play Games com os nossos ids.

    ARMADILHA: o campo `token` que mandamos no insert NAO volta na listagem, o
    Google o substitui por um opaco proprio. Entao a chave de idempotencia tem
    de ser outra. Usamos, em ordem: (1) o mapa que a propria ferramenta gerou em
    play_games_ids.dart, que e o registro de verdade; (2) o nome em en-US, que
    vem das nossas ARB. Sem isso, rodar a ferramenta duas vezes DUPLICA tudo.
    """
    by_id = {}
    if IDS_DART.exists():
        text = IDS_DART.read_text('utf-8')
        for local_id, remote in re.findall(r"'([a-z0-9_]+)':\s*'([^']+)'", text):
            by_id[remote] = local_id

    name_to_local = {}
    for local_id, _tier, title_key, _desc_key, _arg in CATALOG:
        english = arb['en'].get(title_key)
        if english:
            name_to_local[english.strip().lower()] = local_id

    existing = {}
    for item in remote_items:
        remote_id = item.get('id')
        local_id = by_id.get(remote_id)
        if local_id is None:
            for tr in item.get('draft', {}).get('name', {}).get('translations', []):
                if tr.get('locale') == 'en-US':
                    local_id = name_to_local.get((tr.get('value') or '').strip().lower())
                    break
        if local_id:
            existing[local_id] = remote_id
        else:
            print(f'  ? conquista {remote_id} nao casou com o catalogo '
                  '(criada fora desta ferramenta?)')
    return existing


def sync_translations(base, token, arb, existing):
    """Reenvia nome e descricao das conquistas que ja existem.

    Serve para depois de habilitar idiomas novos no Console: as conquistas
    criadas antes ficaram so com os idiomas aceitos na epoca.
    """
    if not existing:
        die('nenhuma conquista existe ainda; rode sem --sync-translations antes')
    dropped = set()
    for rank, (local_id, tier, title_key, desc_key, desc_arg) in enumerate(CATALOG, start=1):
        remote = existing.get(local_id)
        if not remote:
            print(f'  ! {local_id:18} nao existe no projeto, pulando')
            continue
        body = {
            'kind': 'gamesConfiguration#achievementConfiguration',
            'id': remote,  # o update exige o id tambem no corpo, nao so na URL
            'achievementType': 'STANDARD',
            'initialState': 'REVEALED',
            'token': local_id,
            'draft': {
                'kind': 'gamesConfiguration#achievementConfigurationDetail',
                'name': localized(arb, title_key, None),
                'description': localized(arb, desc_key, desc_arg),
                'pointValue': TIER_POINTS[tier],
                'sortRank': rank,
            },
        }
        # Update NAO e aninhado em applications/: PUT /achievements/{id}.
        url = f'{API}/achievements/{remote}'
        # O Google troca nosso token por um opaco; o update exige o vigente.
        body['token'] = request('GET', url, token).get('token', '')
        while True:
            result = request('PUT', url, token, body, tolerate=True)
            if '_error' not in result:
                print(f'  ~ {local_id:18} textos atualizados')
                break
            match = UNSUPPORTED_LOCALE.search(result['_error'])
            if not match:
                die(f'PUT {url}\nHTTP {result["_code"]}: {result["_error"][:400]}')
            bad = match.group(1)
            dropped.add(bad)
            for field in ('name', 'description'):
                body['draft'][field]['translations'] = [
                    t for t in body['draft'][field]['translations']
                    if t['locale'] != bad
                ]
    if dropped:
        print('\nAinda nao habilitados no Console: ' + ', '.join(sorted(dropped)))
    else:
        print('\nTodos os 6 idiomas foram aceitos.')


LEADERBOARD_NAMES = {
    'en': 'Level', 'pt': 'Nível', 'es': 'Nivel',
    'hi': 'लेवल', 'bn': 'লেভেল', 'ne': 'लेभल',
}


def ensure_leaderboard(app_id, token, arb):
    """Cria o placar de nivel se ainda nao existir. Idempotente pelo nome en-US."""
    base = f'{API}/applications/{urllib.parse.quote(app_id)}/leaderboards'
    listing = request('GET', f'{base}?maxResults=200', token)
    wanted = LEADERBOARD_NAMES['en'].strip().lower()
    for item in listing.get('items', []):
        for tr in item.get('draft', {}).get('name', {}).get('translations', []):
            if tr.get('locale') == 'en-US' and (tr.get('value') or '').strip().lower() == wanted:
                print(f'  = placar "{LEADERBOARD_NAMES["en"]}" ja existe ({item["id"]})')
                return item['id']

    translations = [
        {'kind': 'gamesConfiguration#localizedString',
         'locale': LOCALES[lang], 'value': value}
        for lang, value in LEADERBOARD_NAMES.items()
    ]
    body = {
        'kind': 'gamesConfiguration#leaderboardConfiguration',
        'scoreOrder': 'LARGER_IS_BETTER',
        'draft': {
            'kind': 'gamesConfiguration#leaderboardConfigurationDetail',
            'name': {'kind': 'gamesConfiguration#localizedStringBundle',
                     'translations': translations},
            'sortRank': 1,
            'scoreFormat': {
                'kind': 'gamesConfiguration#gamesNumberFormatConfiguration',
                'numberFormatType': 'NUMERIC',
                'numDecimalPlaces': 0,
            },
        },
    }
    dropped = set()
    while True:
        result = request('POST', base, token, body, tolerate=True)
        if '_error' not in result:
            if dropped:
                print('  placar criado sem os idiomas: ' + ', '.join(sorted(dropped)))
            print(f'  + placar de nivel criado -> {result["id"]}')
            return result['id']
        match = UNSUPPORTED_LOCALE.search(result['_error'])
        if not match:
            die(f'POST {base}\nHTTP {result["_code"]}: {result["_error"][:400]}')
        bad = match.group(1)
        dropped.add(bad)
        body['draft']['name']['translations'] = [
            t for t in body['draft']['name']['translations'] if t['locale'] != bad
        ]
        if not body['draft']['name']['translations']:
            die('nenhum idioma aceito para o placar')


def write_dart(ids, leaderboard_id):
    lines = [
        '/// Ids do Play Games Services.',
        '///',
        '/// GERADO por `tool/play_games_setup.py` a partir do catalogo em',
        '/// `lib/models/achievement.dart` e das traducoes das ARB. Nao editar a mao:',
        '/// rode a ferramenta de novo depois de acrescentar uma conquista.',
        '///',
        '/// Com os mapas vazios a integracao inteira vira no-op e o app se comporta',
        '/// como se o Play Games nao existisse, o que torna seguro publicar antes de',
        '/// o projeto do PGS estar pronto.',
        'library;',
        '',
        '/// Nosso id do catalogo -> id no Play Games.',
        'const Map<String, String> playGamesAchievementIds = <String, String>{',
    ]
    for local_id, remote in ids.items():
        lines.append(f"  '{local_id}': '{remote}',")
    lines += [
        '};',
        '',
        '/// Placar de nivel. Vazio = nao envia pontuacao.',
        f"const String playGamesLevelLeaderboardId = '{leaderboard_id}';",
        '',
        '/// A integracao so liga quando existe pelo menos uma conquista mapeada.',
        'bool get playGamesConfigured => playGamesAchievementIds.isNotEmpty;',
        '',
    ]
    IDS_DART.write_text('\n'.join(lines), encoding='utf-8')


if __name__ == '__main__':
    main()
