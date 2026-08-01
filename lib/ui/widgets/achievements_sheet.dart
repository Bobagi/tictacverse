import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../models/achievement.dart';
import '../../models/progress_state.dart';
import '../../services/progression_service.dart';
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
          child: _FadingEdge(
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

/// Esmaece a borda de baixo da lista, sinalizando que há mais conteúdo.
///
/// Sem isso o último item aparece fatiado no limite do painel e parece um bug
/// de layout, não um convite a rolar.
class _FadingEdge extends StatelessWidget {
  const _FadingEdge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.white, Colors.white, Colors.transparent],
          stops: <double>[0, 0.92, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
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
                Text(
                  localization.levelLabel(progression.level),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.10),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        VerseColors.energy),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(tint),
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
                  child: Icon(Icons.check_circle_rounded, size: 20, color: tint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
