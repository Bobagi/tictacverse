/// Um produto de compra dentro do app. Todos são de COMPRA ÚNICA: o jogador
/// passa a possuir aquilo, e a Play responde a qualquer momento se ele ainda
/// possui (compra reembolsada some da lista). É isso que deixa o jogo sem
/// servidor próprio: a Play é a fonte da verdade do que foi pago.
///
/// Não vendemos moedas: pacote de moedas é consumível, some da lista da Play
/// assim que é entregue, e aí um reembolso posterior fica invisível para o
/// aparelho (decisão do dono em 2026-10-05). Moedas só se ganham jogando.
///
/// O preço NÃO mora aqui: vem da Play já formatado na moeda do jogador. Os
/// ids precisam existir iguais na Play Console (`tool/play_products_setup.py`).
class StoreProduct {
  const StoreProduct({
    required this.id,
    this.removeAds = false,
    this.skins = const <String>{},
    this.themes = const <String>{},
    this.allCosmetics = false,
  });

  final String id;

  /// Tira os anúncios que o jogador não pediu (banner e intersticial).
  final bool removeAds;

  /// Visuais de peça e temas de tabuleiro que a compra libera.
  final Set<String> skins;
  final Set<String> themes;

  /// Libera TODOS os visuais e temas, inclusive os que vierem depois.
  final bool allCosmetics;
}

const String removeAdsProductId = 'remove_ads';
const String starterPackProductId = 'starter_pack';
const String collectionProductId = 'collection';

/// Catálogo na ordem da tela.
const List<StoreProduct> storeCatalog = <StoreProduct>[
  // Boas-vindas: sem anúncios + o visual mais caprichado (~US$1,99).
  StoreProduct(
    id: starterPackProductId,
    removeAds: true,
    skins: <String>{'aurora'},
  ),
  // Só tirar os anúncios (~US$0,99).
  StoreProduct(id: removeAdsProductId, removeAds: true),
  // Tudo (~US$4,99).
  StoreProduct(id: collectionProductId, removeAds: true, allCosmetics: true),
];

StoreProduct? storeProductById(String id) {
  for (final StoreProduct product in storeCatalog) {
    if (product.id == id) {
      return product;
    }
  }
  return null;
}
