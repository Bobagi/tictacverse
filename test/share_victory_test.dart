import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/services/share_victory.dart';

void main() {
  testWidgets('a foto do compartilhar sai opaca, com margem, e o link leva o '
      'referrer de compartilhamento', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(Center(
      child: RepaintBoundary(
        key: key,
        child: const SizedBox(width: 100, height: 100),
      ),
    ));
    final Uint8List? png = await tester.runAsync<Uint8List?>(
        () => ShareVictory.capture(key, pixelRatio: 1));
    expect(png, isNotNull);
    final ui.Codec codec = (await tester.runAsync(
        () => ui.instantiateImageCodec(png!)))!;
    final ui.FrameInfo frame = (await tester.runAsync(codec.getNextFrame))!;
    expect(frame.image.width, 148, reason: '100 + 24 de margem de cada lado');
    final ByteData bytes = (await tester.runAsync<ByteData?>(() =>
        frame.image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
    // Canto (só fundo): alfa 255, nada de transparente.
    expect(bytes.getUint8(3), 255);
    expect(ShareVictory.storeLink, contains('id=com.bobagi.tictacverse'));
    expect(ShareVictory.storeLink, contains('utm_source%3Dshare'));
  });

  testWidgets('sem a moldura na árvore, não quebra e devolve nulo',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    expect(await ShareVictory.capture(GlobalKey()), isNull);
  });
}
