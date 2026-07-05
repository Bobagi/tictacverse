import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../models/game_mode.dart';
import '../../services/storage_service.dart';
import 'modern_background.dart';

class StatsSheet extends StatelessWidget {
  const StatsSheet({super.key, required this.localization});

  final AppLocalizations localization;

  static const Color _crossColor = Color(0xFF6BE0FF);
  static const Color _noughtColor = Color(0xFFFF6BD9);

  @override
  Widget build(BuildContext context) {
    final StorageService storage = StorageService.instance;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final List<GameModeDefinition> modes = createGameModes();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.bar_chart_rounded,
                          color: Colors.lightBlueAccent),
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
              if (storage.totalMatches == 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 2, 16),
                  child: Text(
                    localization.statsEmpty,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 4),
                        _buildTotalHero(context, storage),
                        const SizedBox(height: 16),
                        _buildSectionLabel(context, localization.statsVsCpu),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            _buildStatTile(context,
                                value: storage.cpuWins,
                                label: localization.statsWins,
                                accent: _crossColor),
                            const SizedBox(width: 8),
                            _buildStatTile(context,
                                value: storage.cpuLosses,
                                label: localization.statsLosses,
                                accent: _noughtColor),
                            const SizedBox(width: 8),
                            _buildStatTile(context,
                                value: storage.cpuDraws,
                                label: localization.statsDraws,
                                accent: Colors.white70),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            _buildStatTile(context,
                                value: storage.winStreak,
                                label: localization.statsStreak,
                                accent: Colors.amberAccent,
                                icon: Icons.local_fire_department_rounded),
                            const SizedBox(width: 8),
                            _buildStatTile(context,
                                value: storage.bestWinStreak,
                                label: localization.statsBestStreak,
                                accent: Colors.amberAccent,
                                icon: Icons.emoji_events_rounded),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildSectionLabel(context, localization.statsByMode),
                        const SizedBox(height: 6),
                        _buildModeTable(context, storage, modes),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalHero(BuildContext context, StorageService storage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          '${storage.totalMatches}',
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(fontWeight: FontWeight.w800, height: 1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            localization.statsTotalMatches,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required int value,
    required String label,
    required Color accent,
    IconData? icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                        height: 1.1,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white60, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTable(
    BuildContext context,
    StorageService storage,
    List<GameModeDefinition> modes,
  ) {
    const double numColWidth = 44;
    final TextStyle? headStyle = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.w800);
    final TextStyle? cellStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        );

    Widget numCell(Widget child) =>
        SizedBox(width: numColWidth, child: Center(child: child));

    final List<Widget> rows = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            const Expanded(child: SizedBox()),
            numCell(Text('X',
                style: headStyle?.copyWith(color: _crossColor))),
            numCell(Text('O',
                style: headStyle?.copyWith(color: _noughtColor))),
            numCell(Icon(Icons.handshake_outlined,
                size: 16, color: Colors.white60)),
          ],
        ),
      ),
    ];

    for (final GameModeDefinition mode in modes) {
      final ModeStats stats = storage.statsByMode[mode.type]!;
      if (stats.matches == 0) {
        continue;
      }
      rows.add(Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                mode.title(localization),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white.withOpacity(0.9)),
              ),
            ),
            numCell(Text('${stats.xWins}', style: cellStyle)),
            numCell(Text('${stats.oWins}', style: cellStyle)),
            numCell(Text('${stats.draws}',
                style: cellStyle?.copyWith(color: Colors.white70))),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}
