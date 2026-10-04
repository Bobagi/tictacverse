import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Compartilhar a vitória: a foto do tabuleiro + o link da loja, pelo menu de
/// compartilhar do próprio Android (WhatsApp, Instagram, etc.). Na Índia e em
/// Bangladesh é o canal de divulgação que não custa nada.
///
/// Nada passa pelo nosso servidor: a imagem vai direto do aparelho para o app
/// que a pessoa escolheu.
class ShareVictory {
  const ShareVictory._();

  /// Link da ficha com `referrer`, para a Play Console separar as instalações
  /// que vieram de compartilhamento.
  static const String storeLink =
      'https://play.google.com/store/apps/details?id=com.bobagi.tictacverse'
      '&referrer=utm_source%3Dshare%26utm_medium%3Dvictory';

  /// Gera o PNG do que está dentro do [RepaintBoundary] de [boundaryKey].
  static Future<Uint8List?> capture(GlobalKey boundaryKey,
      {double pixelRatio = 2}) async {
    final RenderObject? object =
        boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      return null;
    }
    final ui.Image image = await object.toImage(pixelRatio: pixelRatio);
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  static Future<void> share(GlobalKey boundaryKey,
      {required String message}) async {
    try {
      final Uint8List? png = await capture(boundaryKey);
      final String text = '$message\n$storeLink';
      await SharePlus.instance.share(ShareParams(
        text: text,
        files: png == null
            ? null
            : <XFile>[
                XFile.fromData(png,
                    mimeType: 'image/png', name: 'tictacverse.png'),
              ],
      ));
    } catch (_) {
      // Sem app de destino ou captura indisponível: não derruba o jogo.
    }
  }
}
