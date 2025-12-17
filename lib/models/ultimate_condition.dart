import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'player_marker.dart';

enum UltimateConditionType {
  avoidCenter,
  limitedMoves,
}

class UltimateCondition {
  UltimateCondition({required this.type, this.allowedMoves});

  final UltimateConditionType type;
  final int? allowedMoves;

  String describe(AppLocalizations localization) {
    switch (type) {
      case UltimateConditionType.avoidCenter:
        return localization.ultimateNoCenter;
      case UltimateConditionType.limitedMoves:
        return localization.ultimateLimitedMoves;
    }
  }

  bool isBoardValid(List<PlayerMarker?> board) {
    if (type == UltimateConditionType.avoidCenter && board[4] != null) {
      return false;
    }
    return true;
  }
}
