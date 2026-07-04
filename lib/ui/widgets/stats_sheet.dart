import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../models/game_mode.dart';
import '../../services/storage_service.dart';
import 'modern_background.dart';

class StatsSheet extends StatelessWidget {
  const StatsSheet({super.key, required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final StorageService storage = StorageService.instance;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final List<GameModeDefinition> modes = createGameModes();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.bar_chart_rounded, color: Colors.lightBlueAccent),
                    const SizedBox(width: 8),
                    Text(
                      localization.statsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (storage.totalMatches == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  localization.statsEmpty,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
              )
            else ...<Widget>[
              _buildSummaryRow(
                context,
                localization.statsTotalMatches,
                storage.totalMatches.toString(),
              ),
              const SizedBox(height: 12),
              Text(
                localization.statsVsCpu,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _buildChip(context, localization.statsWins, storage.cpuWins),
                  _buildChip(context, localization.statsLosses, storage.cpuLosses),
                  _buildChip(context, localization.statsDraws, storage.cpuDraws),
                  _buildChip(context, localization.statsStreak, storage.winStreak),
                  _buildChip(context, localization.statsBestStreak, storage.bestWinStreak),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                localization.statsByMode,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final GameModeDefinition mode in modes)
                if (storage.statsByMode[mode.type]!.matches > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${mode.title(localization)} — '
                      '${storage.statsByMode[mode.type]!.matches} · '
                      'X ${storage.statsByMode[mode.type]!.xWins} · '
                      'O ${storage.statsByMode[mode.type]!.oWins} · '
                      '= ${storage.statsByMode[mode.type]!.draws}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}
