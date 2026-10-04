/// O que um produto da Play entrega.
enum StoreProductKind { coins, removeAds }

/// Um produto de compra dentro do app. O preço NÃO mora aqui: vem da Play já
/// convertido e formatado na moeda do jogador (`ProductDetails.price`).
///
/// Os ids precisam existir iguais na Play Console (produtos de compra única),
/// criados por `tool/play_products_setup.py`.
class StoreProduct {
  const StoreProduct.coins(this.id, this.coins) : kind = StoreProductKind.coins;

  const StoreProduct.removeAds(this.id)
      : kind = StoreProductKind.removeAds,
        coins = 0;

  final String id;
  final StoreProductKind kind;

  /// Moedas creditadas por compra (só pacotes de moedas).
  final int coins;

  /// Pacote de moedas é consumível (compra quantas vezes quiser); "sem
  /// anúncios" é comprado uma vez e volta sozinho ao reinstalar.
  bool get isConsumable => kind == StoreProductKind.coins;
}

const String removeAdsProductId = 'remove_ads';

/// Catálogo na ordem da tela. Os pacotes maiores rendem mais moeda por real
/// (300, 1000 e 3000 para preços de ~US$0,99, 2,49 e 4,99).
const List<StoreProduct> storeCatalog = <StoreProduct>[
  StoreProduct.removeAds(removeAdsProductId),
  StoreProduct.coins('coins_300', 300),
  StoreProduct.coins('coins_1000', 1000),
  StoreProduct.coins('coins_3000', 3000),
];

StoreProduct? storeProductById(String id) {
  for (final StoreProduct product in storeCatalog) {
    if (product.id == id) {
      return product;
    }
  }
  return null;
}
