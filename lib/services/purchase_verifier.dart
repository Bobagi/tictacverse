import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Chave pública de licenciamento do app (Play Console → Monetização →
/// Configuração da monetização → "Licenciamento"). É PÚBLICA: pode ficar no
/// código. Vazia = verificação desligada (a compra é aceita como a Play
/// entregou), o que só deve acontecer até o dono colar a chave aqui.
const String playLicenseKey = '';

/// Confere a assinatura que a Play põe em cada compra (`originalJson` +
/// `signature`, RSA com SHA-1). Barra compra forjada por programa que finge
/// ser a Play no aparelho, sem precisar de servidor.
class PurchaseVerifier {
  PurchaseVerifier(String base64Key) : _key = _parse(base64Key);

  final RSAPublicKey? _key;

  /// Sem chave configurada não há o que conferir.
  bool get enabled => _key != null;

  bool verify(String signedData, String? signatureBase64) {
    final RSAPublicKey? key = _key;
    if (key == null) {
      return true;
    }
    if (signatureBase64 == null || signatureBase64.isEmpty) {
      return false;
    }
    try {
      final RSASigner signer = RSASigner(SHA1Digest(), '06052b0e03021a')
        ..init(false, PublicKeyParameter<RSAPublicKey>(key));
      return signer.verifySignature(
        Uint8List.fromList(utf8.encode(signedData)),
        RSASignature(base64.decode(signatureBase64)),
      );
    } catch (_) {
      return false;
    }
  }

  /// Lê a chave no formato da Play Console: base64 de um
  /// SubjectPublicKeyInfo (X.509) com uma RSAPublicKey dentro.
  static RSAPublicKey? _parse(String base64Key) {
    final String clean = base64Key.replaceAll(RegExp(r'\s'), '');
    if (clean.isEmpty) {
      return null;
    }
    try {
      final ASN1Parser outer = ASN1Parser(base64.decode(clean));
      final ASN1Sequence spki = outer.nextObject() as ASN1Sequence;
      final ASN1BitString bits = spki.elements![1] as ASN1BitString;
      final ASN1Sequence rsa =
          ASN1Parser(Uint8List.fromList(bits.stringValues!)).nextObject()
              as ASN1Sequence;
      final BigInt modulus = (rsa.elements![0] as ASN1Integer).integer!;
      final BigInt exponent = (rsa.elements![1] as ASN1Integer).integer!;
      return RSAPublicKey(modulus, exponent);
    } catch (_) {
      return null;
    }
  }
}
