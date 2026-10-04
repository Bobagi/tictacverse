/// Um produto de compra dentro do app. O preço NÃO mora aqui: vem da Play já
/// convertido e formatado na moeda do jogador (`ProductDetails.price`).
///
/// O que a compra entrega quem decide é o servidor (`tictacverse-api`, mesmo
/// catálogo em `src/catalog.js`); os campos aqui servem para a tela descrever
/// o produto e para o app saber se consome ou só confirma a compra.
///
/// Os ids precisam existir iguais na Play Console (produtos de compra única),
/// criados por `tool/play_products_setup.py`.
class StoreProduct {
  const StoreProduct({
    required this.id,
    this.coins = 0,
    this.removeAds = false,
    required this.isConsumable,
  });

  final String id;

  /// Moedas creditadas por compra.
  final int coins;

  /// Tira os anúncios que o jogador não pediu (banner e intersticial).
  final bool removeAds;

  /// Pacote de moedas é consumível (compra quantas vezes quiser); "sem
  /// anúncios" e o pacote de boas-vindas são comprados uma vez e voltam
  /// sozinhos ao reinstalar (só o direito volta; as moedas não se repetem).
  final bool isConsumable;

  bool get isCoinPack => isConsumable && coins > 0;
}

const String removeAdsProductId = 'remove_ads';
const String starterPackProductId = 'starter_pack';

/// Catálogo na ordem da tela. Os pacotes maiores rendem mais moeda por real
/// (300, 1000 e 3000 para preços de ~US$0,99, 2,49 e 4,99). O pacote de
/// boas-vindas junta "sem anúncios" e 1000 moedas por ~US$1,99.
const List<StoreProduct> storeCatalog = <StoreProduct>[
  StoreProduct(
      id: starterPackProductId,
      coins: 1000,
      removeAds: true,
      isConsumable: false),
  StoreProduct(id: removeAdsProductId, removeAds: true, isConsumable: false),
  StoreProduct(id: 'coins_300', coins: 300, isConsumable: true),
  StoreProduct(id: 'coins_1000', coins: 1000, isConsumable: true),
  StoreProduct(id: 'coins_3000', coins: 3000, isConsumable: true),
];

StoreProduct? storeProductById(String id) {
  for (final StoreProduct product in storeCatalog) {
    if (product.id == id) {
      return product;
    }
  }
  return null;
}
