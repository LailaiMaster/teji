import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/panels.dart';
import '../widgets/route_line.dart';
import '../widgets/shell.dart';
import 'drive_detail_page.dart';
import 'route_overlay_page.dart';

enum InsightMode { achievement, peak, route }

class InsightsPage extends StatelessWidget {
  const InsightsPage({
    super.key,
    required this.api,
    required this.mode,
    required this.drives,
    required this.charges,
  });

  final TejiApi api;
  final InsightMode mode;
  final List<JsonMap> drives;
  final List<JsonMap> charges;

  @override
  Widget build(BuildContext context) {
    final title = switch (mode) {
      InsightMode.achievement => '续航达成排行',
      InsightMode.peak => '驾驶峰值排行',
      InsightMode.route => '常跑路线排行',
    };
    final subtitle = switch (mode) {
      InsightMode.achievement => '按续航达成率排序',
      InsightMode.peak => '最高速度、最大功率、最大回收',
      InsightMode.route => '按出现次数排序',
    };
    return PageShell(
      title: title,
      subtitle: subtitle,
      children: _children(context),
    );
  }

  List<Widget> _children(BuildContext context) {
    return switch (mode) {
      InsightMode.achievement => _achievementChildren(context),
      InsightMode.peak => _peakChildren(context),
      InsightMode.route => _routeChildren(context),
    };
  }

  List<Widget> _achievementChildren(BuildContext context) {
    final ranked =
        drives.where((drive) => rangeAchievement(drive) != null).toList()..sort(
          (a, b) => rangeAchievement(b)!.compareTo(rangeAchievement(a)!),
        );
    if (ranked.isEmpty) return [const EmptyInsight(text: '暂无续航达成数据')];
    return [
      for (var index = 0; index < ranked.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DriveRankCard(
            rank: index + 1,
            drive: ranked[index],
            accent: green,
            primary: rangeAchievementText(ranked[index]),
            secondary: '消耗 ${rangeLossText(ranked[index])}',
            onTap: () => _openDrive(context, ranked[index]),
          ),
        ),
    ];
  }

  List<Widget> _peakChildren(BuildContext context) {
    final ranked =
        drives.where((drive) => asDouble(drive['speed_max']) != null).toList()
          ..sort(
            (a, b) =>
                asDouble(b['speed_max'])!.compareTo(asDouble(a['speed_max'])!),
          );
    if (ranked.isEmpty) return [const EmptyInsight(text: '暂无驾驶峰值数据')];
    return [
      for (var index = 0; index < ranked.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DriveRankCard(
            rank: index + 1,
            drive: ranked[index],
            accent: red,
            primary: speed(ranked[index]['speed_max']),
            secondary:
                '${powerCompact(ranked[index]['power_max'])} / 回收 ${powerCompact(ranked[index]['power_min'])}',
            onTap: () => _openDrive(context, ranked[index]),
          ),
        ),
    ];
  }

  List<Widget> _routeChildren(BuildContext context) {
    final routes = topRouteInsights(drives);
    if (routes.isEmpty) return [const EmptyInsight(text: '暂无常跑路线数据')];
    return [
      for (var index = 0; index < routes.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RouteRankCard(
            rank: index + 1,
            route: routes[index],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    RouteOverlayPage(api: api, route: routes[index]),
              ),
            ),
          ),
        ),
    ];
  }

  void _openDrive(BuildContext context, JsonMap drive) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriveDetailPage(api: api, driveId: asInt(drive['id'])!),
      ),
    );
  }
}

class DriveRankCard extends StatelessWidget {
  const DriveRankCard({
    super.key,
    required this.rank,
    required this.drive,
    required this.accent,
    required this.primary,
    required this.secondary,
    required this.onTap,
  });

  final int rank;
  final JsonMap drive;
  final Color accent;
  final String primary;
  final String secondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RankBadge(rank: rank, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    driveTimeRange(drive),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  primary,
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Icon(Icons.chevron_right, color: muted, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            RouteLine(
              start: drivePointLabel(drive, 'start'),
              end: drivePointLabel(drive, 'end'),
            ),
            const SizedBox(height: 10),
            MetricRow(
              items: [
                MetricItem('里程', kmCompact(drive['distance']), cyan),
                MetricItem('时长', minutesShort(drive['duration_min']), text),
                MetricItem('附加', secondary, muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RouteRankCard extends StatelessWidget {
  const RouteRankCard({
    super.key,
    required this.rank,
    required this.route,
    required this.onTap,
  });

  final int rank;
  final RouteInsight route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final averageDistance = route.count == 0 ? 0 : route.distance / route.count;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RankBadge(rank: rank, color: blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${route.count} 次',
                    style: const TextStyle(
                      color: blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  route.achievement == null
                      ? '--'
                      : '${route.achievement!.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: green,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Icon(Icons.chevron_right, color: muted, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            RouteLine(start: route.start, end: route.end),
            const SizedBox(height: 10),
            MetricRow(
              items: [
                MetricItem('总里程', kmCompact(route.distance), cyan),
                MetricItem('均次', kmCompact(averageDistance), text),
                MetricItem(
                  '达成率',
                  route.achievement == null
                      ? '--'
                      : '${route.achievement!.toStringAsFixed(1)}%',
                  green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, required this.color});

  final int rank;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class EmptyInsight extends StatelessWidget {
  const EmptyInsight({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Center(
        child: Text(text, style: const TextStyle(color: muted)),
      ),
    );
  }
}
