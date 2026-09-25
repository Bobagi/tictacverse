import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../models/achievement.dart';
import '../../models/progress_state.dart';
import '../../services/game_services_bridge.dart';
import '../../services/progression_engine.dart';
import '../../services/progression_service.dart';
import 'fading_edge.dart';
import 'juice/pulse.dart';
import 'modern_background.dart';

/// Cor do selo por faixa.
Color achievementTierColor(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return const Color(0xFFCD8A4B);
    case AchievementTier.silver:
      return const Color(0xFFC7D0E0);
    case AchievementTier.gold:
      return VerseColors.energy;
  }
}

/// Painel de progressão: nível, barra de XP e a lista de conquistas.
///
/// A lista mostra primeiro o que já foi desbloqueado (recompensa visível) e
/// depois o que falta, ordenado pelo que está mais perto de fechar, para o
/// jogador sempre enxergar um próximo objetivo alcançável.
class AchievementsSheet extends StatelessWidget {
  const AchievementsSheet({super.key, required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: ProgressionService.instance.revision,
            builder: (BuildContext context, int _, Widget? __) =>
                _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ProgressionService progression = ProgressionService.instance;
    final ProgressState state = progression.state;
    final List<AchievementDefinition> ordered =
        _orderedCatalog(progression, state);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.emoji_events_rounded,
                    color: VerseColors.energy),
                const SizedBox(width: 8),
                Text(
                  localization.achievementsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LevelPanel(localization: localization),
        _PlayGamesRow(localization: localization),
        const SizedBox(height: 14),
        Text(
          localization.achievementsProgress(
              progression.unlockedCount, progression.catalog.length),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: VerseColors.mutedText),
        ),
        const SizedBox(height: 10),
        Flexible(
          child: FadingEdge(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: ordered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final AchievementDefinition achievement = ordered[index];
                return _AchievementTile(
                  achievement: achievement,
                  localization: localization,
                  state: state,
                  unlocked: progression.isUnlocked(achievement),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<AchievementDefinition> _orderedCatalog(
    ProgressionService progression,
    ProgressState state,
  ) {
    final List<AchievementDefinition> unlocked = <AchievementDefinition>[];
    final List<AchievementDefinition> locked = <AchievementDefinition>[];
    for (final AchievementDefinition achievement in progression.catalog) {
      if (progression.isUnlocked(achievement)) {
        unlocked.add(achievement);
      } else {
        locked.add(achievement);
      }
    }
    locked.sort((AchievementDefinition a, AchievementDefinition b) {
      final double ratioA = a.progress(state) / a.target;
      final double ratioB = b.progress(state) / b.target;
      return ratioB.compareTo(ratioA);
    });
    return <AchievementDefinition>[...unlocked, ...locked];
  }
}

/// Apelido e foto do Play Games, mais o atalho para a tela nativa.
///
/// Some por completo quando o jogador não está autenticado ou quando a
/// integração ainda não foi configurada, que é o estado de hoje. A progressão
/// mostrada acima é sempre a local, então esta linha é só um extra.
class _PlayGamesRow extends StatelessWidget {
  const _PlayGamesRow({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerIdentity?>(
      valueListenable: GameServicesBridge.instance.player,
      builder: (BuildContext context, PlayerIdentity? identity, Widget? _) {
        if (identity == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: <Widget>[
              _PlayerAvatar(identity: identity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  identity.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: VerseColors.mutedText),
                ),
              ),
              TextButton(
                onPressed: () =>
                    GameServicesBridge.instance.showAchievementsUi(),
                child: Text(localization.playGamesOpen),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.identity});

  final PlayerIdentity identity;

  @override
  Widget build(BuildContext context) {
    final String? encoded = identity.iconImageBase64;
    Uint8List? bytes;
    if (encoded != null && encoded.isNotEmpty) {
      try {
        bytes = base64Decode(encoded);
      } catch (_) {
        // Foto ilegível não pode derrubar o painel: cai no ícone genérico.
        bytes = null;
      }
    }
    return ClipOval(
      child: SizedBox(
        width: 24,
        height: 24,
        child: bytes == null
            ? const ColoredBox(
                color: VerseColors.surfaceDeep,
                child: Icon(Icons.person_rounded,
                    size: 16, color: VerseColors.mutedText),
              )
            : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}

/// Cartão de nível com a barra de XP. Reaproveitado na home.
class LevelPanel extends StatelessWidget {
  const LevelPanel({super.key, required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final ProgressionService progression = ProgressionService.instance;
    final (int into, int span) = progression.levelBar;
    final double fraction = span == 0 ? 0 : (into / span).clamp(0.0, 1.0);
    final int dailyStreak = ProgressionEngine.effectiveDailyStreak(
        progression.state, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: <Color>[
          VerseColors.energy.withOpacity(0.18),
          Colors.white.withOpacity(0.04),
        ]),
        border: Border.all(color: VerseColors.energy.withOpacity(0.45)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VerseColors.energy.withOpacity(0.18),
              border: Border.all(color: VerseColors.energy.withOpacity(0.7)),
            ),
            child: Text(
              '${progression.level}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: VerseColors.energy,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        localization.levelLabel(progression.level),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    // Dias seguidos: o gancho de "volta amanhã" fica visível
                    // já na home, com fogo, enquanto a sequência estiver viva.
                    if (dailyStreak >= 2)
                      Pulse(
                        maxScale: 1.06,
                        period: const Duration(milliseconds: 1200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: VerseColors.danger.withOpacity(0.18),
                            border: Border.all(
                                color: VerseColors.danger.withOpacity(0.7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.local_fire_department_rounded,
                                  size: 14, color: VerseColors.danger),
                              const SizedBox(width: 3),
                              Text(
                                '$dailyStreak',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // A barra ANIMA até o valor atual: ao voltar de uma partida o
                // jogador vê o ganho encher, não um número que já mudou.
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double value, Widget? _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.10),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            VerseColors.energy),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  localization.xpProgress(into, span),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: VerseColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.localization,
    required this.state,
    required this.unlocked,
  });

  final AchievementDefinition achievement;
  final AppLocalizations localization;
  final ProgressState state;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final Color tint = achievementTierColor(achievement.tier);
    final int progress = achievement.progress(state);
    final bool showBar = !unlocked && achievement.target > 1;

    return Semantics(
      label: '${achievement.title(localization)}. '
          '${achievement.description(localization)}',
      child: Opacity(
        opacity: unlocked ? 1 : 0.62,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(unlocked ? 0.07 : 0.03),
            border: Border.all(
              color: unlocked
                  ? tint.withOpacity(0.75)
                  : Colors.white.withOpacity(0.10),
              width: unlocked ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withOpacity(unlocked ? 0.22 : 0.10),
                  border: Border.all(color: tint.withOpacity(0.55)),
                ),
                child: Icon(
                  unlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
                  size: 20,
                  color: tint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      achievement.title(localization),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description(localization),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: VerseColors.mutedText),
                    ),
                    if (showBar) ...<Widget>[
                      const SizedBox(height: 7),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: progress / achievement.target,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.10),
                                valueColor: AlwaysStoppedAnimation<Color>(tint),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progress/${achievement.target}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: VerseColors.mutedText),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (unlocked)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child:
                      Icon(Icons.check_circle_rounded, size: 20, color: tint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
