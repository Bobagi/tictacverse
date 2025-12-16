import '../localization/app_localizations.dart';
import 'player_marker.dart';

enum UltimateConditionType {
  avoidCenter,
  limitedMoves,
  cornersOnly,
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
      case UltimateConditionType.cornersOnly:
        return localization.ultimateCornersOnly;
    }
  }

  bool isMoveAllowed(int index) {
    if (type == UltimateConditionType.cornersOnly) {
      return <int>[0, 2, 6, 8].contains(index);
    }
    return true;
  }

  bool isBoardValid(List<PlayerMarker?> board) {
    if (type == UltimateConditionType.avoidCenter && board[4] != null) {
      return false;
    }
    if (type == UltimateConditionType.cornersOnly) {
      for (int i = 0; i < board.length; i++) {
        if (board[i] != null && !<int>[0, 2, 6, 8].contains(i)) {
          return false;
        }
      }
    }
    return true;
  }
}
