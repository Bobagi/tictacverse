import '../../models/online_match.dart';

/// Rosto do jogador online: um bicho e um número sorteados pelo servidor
/// (o índice cobre 0..23, igual a AVATARS em tictacverse-api). Ninguém digita
/// nome, então não há texto de gente para moderar.
const List<String> onlineAvatars = <String>[
  '🐯',
  '🦊',
  '🐼',
  '🐸',
  '🐵',
  '🦁',
  '🐨',
  '🐙',
  '🦉',
  '🐧',
  '🐢',
  '🦄',
  '🐝',
  '🐬',
  '🦖',
  '🐲',
  '🐱',
  '🐶',
  '🐰',
  '🦋',
  '🐞',
  '🦀',
  '🐳',
  '🦩',
];

String avatarEmoji(int index) =>
    onlineAvatars[index.clamp(0, onlineAvatars.length - 1)];

/// "🐯 42": como o jogador aparece para o outro.
String onlineHandle(int avatar, int tag) => '${avatarEmoji(avatar)} $tag';

String opponentHandle(OnlineOpponent? o) =>
    o == null ? '⏳' : onlineHandle(o.avatar, o.tag);
