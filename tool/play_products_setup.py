#!/usr/bin/env python3
"""Cria ou atualiza na Play Console os produtos de compra do Tic Tac Verse.

Por que existe: 4 produtos x 7 idiomas x ~170 países de preço são centenas de
campos na mão. A API nova de produtos de compra única (oneTimeProducts) faz
tudo, e o preço de cada país sai da conversão oficial da própria Play
(`pricing:convertRegionPrices`) a partir do preço base em dólar.

Os ids TÊM de bater com `lib/models/store_product.dart`.

Uso:
  python3 tool/play_products_setup.py --list
  python3 tool/play_products_setup.py --dry-run        # mostra o que mandaria
  python3 tool/play_products_setup.py                  # cria/atualiza e ativa

Autenticação: reusa a service account da skill google-play
(~/.config/bobagi-google/play-service-account.json).

Pré-requisito da Play: o app precisa ter um AAB com a permissão
com.android.vending.BILLING enviado (qualquer track serve, o interno basta) e a
conta de desenvolvedor precisa ter perfil de pagamentos.

Idempotente: PATCH com allowMissing cria o que falta e atualiza o resto.
"""

import argparse
import json
import pathlib
import sys
import urllib.parse

sys.path.insert(0, str(pathlib.Path.home() / '.claude/skills/google-play/scripts'))
import gplay  # noqa: E402

PKG = 'com.bobagi.tictacverse'
OPTION_ID = 'default'

# (id, preço base em US$ como (unidades, nanos), textos por idioma da ficha)
PRODUCTS = [
    ('starter_pack', (1, 990_000_000), {
        'pt-BR': ('Pacote de boas-vindas', 'Sem anúncios para sempre e o visual Aurora, o mais caprichado do jogo.'),
        'en-US': ('Welcome pack', 'No ads forever and the Aurora style, the most polished in the game.'),
        'es-419': ('Paquete de bienvenida', 'Sin anuncios para siempre y el estilo Aurora, el más cuidado del juego.'),
        'es-ES': ('Paquete de bienvenida', 'Sin anuncios para siempre y el estilo Aurora, el más cuidado del juego.'),
        'hi-IN': ('वेलकम पैक', 'हमेशा के लिए बिना विज्ञापन और ऑरोरा स्टाइल, खेल की सबसे शानदार।'),
        'bn-BD': ('ওয়েলকাম প্যাক', 'চিরতরে বিজ্ঞাপন ছাড়া আর অরোরা স্টাইল, খেলার সবচেয়ে সুন্দর।'),
        'ne-NP': ('स्वागत प्याक', 'सधैँका लागि विज्ञापन बिना र अरोरा स्टाइल, खेलको सबैभन्दा राम्रो।'),
    }),
    ('remove_ads', (0, 990_000_000), {
        'pt-BR': ('Sem anúncios', 'Tira os banners e os anúncios entre partidas, para sempre.'),
        'en-US': ('No ads', 'Removes banners and ads between matches, forever.'),
        'es-419': ('Sin anuncios', 'Quita los banners y los anuncios entre partidas, para siempre.'),
        'es-ES': ('Sin anuncios', 'Quita los banners y los anuncios entre partidas, para siempre.'),
        'hi-IN': ('बिना विज्ञापन', 'बैनर और मैचों के बीच के विज्ञापन हमेशा के लिए हट जाते हैं।'),
        'bn-BD': ('বিজ্ঞাপন ছাড়া', 'ব্যানার আর ম্যাচের মাঝের বিজ্ঞাপন চিরতরে সরে যায়।'),
        'ne-NP': ('विज्ञापन बिना', 'ब्यानर र खेलबीचका विज्ञापन सधैँका लागि हट्छन्।'),
    }),
    ('collection', (4, 990_000_000), {
        'pt-BR': ('Coleção completa', 'Todos os visuais e temas de tabuleiro, os de hoje e os que vierem, e sem anúncios.'),
        'en-US': ('Full collection', 'Every piece style and board theme, today\'s and future ones, and no ads.'),
        'es-419': ('Colección completa', 'Todos los estilos y temas de tablero, los de hoy y los que vengan, y sin anuncios.'),
        'es-ES': ('Colección completa', 'Todos los estilos y temas de tablero, los de hoy y los que vengan, y sin anuncios.'),
        'hi-IN': ('पूरा कलेक्शन', 'सारी मोहरा स्टाइल और बोर्ड थीम, आज की और आने वाली, और बिना विज्ञापन।'),
        'bn-BD': ('পুরো কালেকশন', 'সব ঘুঁটির স্টাইল ও বোর্ড থিম, এখনকার ও ভবিষ্যতের, আর বিজ্ঞাপন ছাড়া।'),
        'ne-NP': ('पूरा सङ्ग्रह', 'सबै गोटी स्टाइल र बोर्ड थिम, आजका र आउने, र विज्ञापन बिना।'),
    }),
]

# Produtos que deixaram de ser vendidos (pacotes de moedas, 2026-10-05: sem
# servidor, reembolso de consumível é invisível ao app). Ficam DESATIVADOS na
# Play (não aparecem para compra); nunca chegaram à produção.
RETIRED = ['coins_300', 'coins_1000', 'coins_3000']

# Preço regional do público real (Índia, Bangladesh e Nepal lideram as
# instalações). A conversão pura da Play põe US$ 0,99 em INR 110, acima do que
# o casual tier-3 paga. Valores em unidades da moeda que a Play usa no país.
REGIONAL = {
    'IN': {'starter_pack': 89, 'remove_ads': 49, 'collection': 199},
    'BD': {'starter_pack': 110, 'remove_ads': 60, 'collection': 240},
    # O Nepal é cobrado em dólar pela Play.
    'NP': {'starter_pack': 0.99, 'remove_ads': 0.49, 'collection': 1.99},
}



def listings_for(product_id, texts):
    return [
        {'languageCode': lang, 'title': title, 'description': desc}
        for lang, (title, desc) in texts.items()
    ]


def money(currency, units, nanos):
    return {'currencyCode': currency, 'units': str(units), 'nanos': nanos}


def convert(token, units, nanos):
    """Preço base em US$ -> preço de cada país pela conversão oficial da Play."""
    body = {'price': money('USD', units, nanos)}
    res = gplay.api('POST', f'/{PKG}/pricing:convertRegionPrices', token, body)
    regions = []
    for code, conv in sorted(res.get('convertedRegionPrices', {}).items()):
        regions.append({
            'regionCode': code,
            'price': conv['price'],
            'availability': 'AVAILABLE',
        })
    other = res.get('convertedOtherRegionsPrice', {})
    return regions, other, res.get('regionVersion', {}).get('version')


def apply_regional(product_id, regions):
    for region in regions:
        local = REGIONAL.get(region['regionCode'], {}).get(product_id)
        if local is None:
            continue
        units = int(local)
        nanos = int(round((local - units) * 1_000_000_000))
        region['price'] = money(region['price']['currencyCode'], units, nanos)


def build(token, product_id, base, texts):
    regions, other, version = convert(token, *base)
    apply_regional(product_id, regions)
    option = {
        'purchaseOptionId': OPTION_ID,
        # Compatível com o fluxo "legado" (um produto = um preço), que é o que o
        # plugin in_app_purchase consulta.
        'buyOption': {'legacyCompatible': True, 'multiQuantityEnabled': False},
        'regionalPricingAndAvailabilityConfigs': regions,
    }
    if other:
        option['newRegionsConfig'] = {
            'usdPrice': other.get('usdPrice'),
            'eurPrice': other.get('eurPrice'),
            'availability': 'AVAILABLE',
        }
    product = {
        'packageName': PKG,
        'productId': product_id,
        'listings': listings_for(product_id, texts),
        'purchaseOptions': [option],
    }
    return product, version


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--list', action='store_true')
    args = ap.parse_args()
    token = gplay.access_token()

    if args.list:
        res = gplay.api('GET', f'/{PKG}/oneTimeProducts', token)
        for p in res.get('oneTimeProducts', []):
            states = [o.get('state') for o in p.get('purchaseOptions', [])]
            print(p['productId'], states)
        return

    for product_id, base, texts in PRODUCTS:
        product, version = build(token, product_id, base, texts)
        n = len(product['purchaseOptions'][0]['regionalPricingAndAvailabilityConfigs'])
        print(f'{product_id}: {n} países, regionsVersion {version}')
        if args.dry_run:
            sample = product['purchaseOptions'][0]['regionalPricingAndAvailabilityConfigs']
            for r in sample:
                if r['regionCode'] in ('BR', 'IN', 'BD', 'NP', 'US'):
                    print('   ', r['regionCode'], r['price'])
            continue
        query = urllib.parse.urlencode({
            'allowMissing': 'true',
            'updateMask': 'listings,purchaseOptions',
            'regionsVersion.version': version,
        })
        # Rota de PATCH em minúsculas (assim no discovery da API; as outras são camelCase).
        gplay.api('PATCH', f'/{PKG}/onetimeproducts/{product_id}?{query}', token, product)
        gplay.api('POST', f'/{PKG}/oneTimeProducts/{product_id}/purchaseOptions:batchUpdateStates',
                  token, {'requests': [{'activatePurchaseOptionRequest': {
                      'packageName': PKG, 'productId': product_id,
                      'purchaseOptionId': OPTION_ID}}]})
        print('   criado/atualizado e ativo')

    if not args.dry_run:
        for product_id in RETIRED:
            res = gplay.api('GET', f'/{PKG}/oneTimeProducts/{product_id}', token, ok404=True)
            if res is None:
                continue
            gplay.api('POST', f'/{PKG}/oneTimeProducts/{product_id}/purchaseOptions:batchUpdateStates',
                      token, {'requests': [{'deactivatePurchaseOptionRequest': {
                          'packageName': PKG, 'productId': product_id,
                          'purchaseOptionId': OPTION_ID}}]})
            print(f'{product_id}: desativado')


if __name__ == '__main__':
    main()
