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
        'pt-BR': ('Pacote de boas-vindas', 'Sem anúncios para sempre e 1000 moedas, numa compra só.'),
        'en-US': ('Welcome pack', 'No ads forever and 1000 coins, in one purchase.'),
        'es-419': ('Paquete de bienvenida', 'Sin anuncios para siempre y 1000 monedas, en una sola compra.'),
        'es-ES': ('Paquete de bienvenida', 'Sin anuncios para siempre y 1000 monedas, en una sola compra.'),
        'hi-IN': ('वेलकम पैक', 'हमेशा के लिए बिना विज्ञापन और 1000 सिक्के, एक ही खरीद में।'),
        'bn-BD': ('ওয়েলকাম প্যাক', 'চিরতরে বিজ্ঞাপন ছাড়া আর ১০০০ কয়েন, এক কেনাতেই।'),
        'ne-NP': ('स्वागत प्याक', 'सधैँका लागि विज्ञापन बिना र 1000 सिक्का, एउटै किनमेलमा।'),
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
    ('coins_300', (0, 990_000_000), None),
    ('coins_1000', (2, 490_000_000), None),
    ('coins_3000', (4, 990_000_000), None),
]

# Preço regional do público real (Índia, Bangladesh e Nepal lideram as
# instalações). A conversão pura da Play põe US$ 0,99 em INR 110, acima do que
# o casual tier-3 paga (Ludo King vende a partir de INR 9; GDD prevê INR 49 a 99
# para "sem anúncios"). Valores em unidades da moeda que a Play usa no país.
REGIONAL = {
    'IN': {'starter_pack': 89, 'remove_ads': 49, 'coins_300': 39, 'coins_1000': 99, 'coins_3000': 199},
    'BD': {'starter_pack': 110, 'remove_ads': 60, 'coins_300': 50, 'coins_1000': 120, 'coins_3000': 240},
    # O Nepal é cobrado em dólar pela Play.
    'NP': {'starter_pack': 0.99, 'remove_ads': 0.49, 'coins_300': 0.49, 'coins_1000': 0.99, 'coins_3000': 1.99},
}

COIN_WORD = {
    'pt-BR': ('{n} moedas', 'Pacote de {n} moedas para trocar por visuais das peças.'),
    'en-US': ('{n} coins', 'A pack of {n} coins to spend on piece styles.'),
    'es-419': ('{n} monedas', 'Paquete de {n} monedas para cambiar por estilos de fichas.'),
    'es-ES': ('{n} monedas', 'Paquete de {n} monedas para cambiar por estilos de fichas.'),
    'hi-IN': ('{n} सिक्के', 'मोहरों की स्टाइल के लिए {n} सिक्कों का पैक।'),
    'bn-BD': ('{n} কয়েন', 'ঘুঁটির স্টাইলের জন্য {n} কয়েনের প্যাক।'),
    'ne-NP': ('{n} सिक्का', 'गोटीका स्टाइलका लागि {n} सिक्काको प्याक।'),
}


def listings_for(product_id, texts):
    if texts is None:
        n = product_id.split('_')[1]
        texts = {lang: (t.format(n=n), d.format(n=n)) for lang, (t, d) in COIN_WORD.items()}
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


if __name__ == '__main__':
    main()
