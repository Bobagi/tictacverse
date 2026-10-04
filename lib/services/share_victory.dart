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

  /// Fundo da imagem: o mesmo degradê roxo do jogo.
  static const Color backgroundTop = Color(0xFF1A0B2E);
  static const Color backgroundBottom = Color(0xFF3A0F55);

  /// Gera o PNG do que está dentro do [RepaintBoundary] de [boundaryKey].
  static Future<Uint8List?> capture(GlobalKey boundaryKey,
      {double pixelRatio = 2}) async {
    final RenderObject? object = boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      return null;
    }
    final ui.Image board = await object.toImage(pixelRatio: pixelRatio);
    // O tabuleiro é desenhado sobre o fundo da tela, que fica de fora da
    // captura: sem pintar um fundo aqui, a foto sairia transparente (preta ou
    // branca, conforme o app que recebe).
    final double pad = 24 * pixelRatio;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Size size = Size(board.width + 2 * pad, board.height + 2 * pad);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height),
            const <Color>[backgroundTop, backgroundBottom]),
    );
    canvas.drawImage(board, Offset(pad, pad), Paint());
    final ui.Image framed = await recorder
        .endRecording()
        .toImage(size.width.round(), size.height.round());
    board.dispose();
    final ByteData? data =
        await framed.toByteData(format: ui.ImageByteFormat.png);
    framed.dispose();
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
