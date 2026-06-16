import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles the Google User Messaging Platform (UMP) consent flow.
///
/// AdMob requires a consent gathering step (GDPR / Google's EU consent)
/// before serving personalized ads to users in regulated regions such as
/// the European Economic Area and the UK. Without it, ad serving to those
/// users is throttled or blocked, which directly reduces revenue.
///
/// This is best-effort: any failure must not prevent the app from starting,
/// it simply falls back to whatever consent state is already stored.
class ConsentService {
  Future<void> gatherConsent() async {
    final Completer<void> completer = Completer<void>();

    final ConsentRequestParameters params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          final bool isFormAvailable =
              await ConsentInformation.instance.isConsentFormAvailable();
          if (!isFormAvailable) {
            _completeOnce(completer);
            return;
          }
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
            if (error != null) {
              debugPrint('Consent form error: ${error.message}');
            }
            _completeOnce(completer);
          });
        } catch (error) {
          debugPrint('Consent gathering failed: $error');
          _completeOnce(completer);
        }
      },
      (FormError error) {
        debugPrint('Consent info update failed: ${error.message}');
        _completeOnce(completer);
      },
    );

    return completer.future;
  }

  void _completeOnce(Completer<void> completer) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }
}
