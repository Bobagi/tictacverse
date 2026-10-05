import 'board_theme.dart';
import 'piece_skin.dart';
import 'store_product.dart';

/// O que as compras da Play liberam, calculado a partir da lista de produtos
/// que a Play diz que o jogador POSSUI agora. Função pura: compra reembolsada
/// sai da lista e o direito some junto, sem nada a "desfazer" à mão.
class Entitlements {
  const Entitlements({
    this.adsRemoved = false,
    this.skins = const <String>{},
    this.themes = const <String>{},
  });

  factory Entitlements.fromOwned(Iterable<String> productIds) {
    bool ads = false;
    final Set<String> skins = <String>{};
    final Set<String> themes = <String>{};
    for (final String id in productIds) {
      final StoreProduct? product = storeProductById(id);
      if (product == null) {
        continue;
      }
      ads = ads || product.removeAds;
      skins.addAll(product.skins);
      themes.addAll(product.themes);
      if (product.allCosmetics) {
        skins.addAll(pieceSkinCatalog.map((PieceSkin s) => s.id));
        themes.addAll(boardThemeCatalog.map((BoardTheme t) => t.id));
      }
    }
    return Entitlements(adsRemoved: ads, skins: skins, themes: themes);
  }

  static const Entitlements none = Entitlements();

  final bool adsRemoved;
  final Set<String> skins;
  final Set<String> themes;
}
