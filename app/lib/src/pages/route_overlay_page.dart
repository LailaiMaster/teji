import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/multi_drive_route_map.dart';
import '../widgets/panels.dart';
import '../widgets/route_line.dart';
import '../widgets/shell.dart';
import 'drive_detail_page.dart';

class RouteOverlayPage extends StatefulWidget {
  const RouteOverlayPage({super.key, required this.api, required this.route});

  final TejiApi api;
  final RouteInsight route;

  @override
  State<RouteOverlayPage> createState() => _RouteOverlayPageState();
}

class _RouteOverlayPageState extends State<RouteOverlayPage> {
  late Future<List<RouteDriveDetail>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RouteDriveDetail>> _load() async {
    final ids = widget.route.driveIds.take(24).toList(growable: false);
    final details = await Future.wait(ids.map(widget.api.driveDetail));
    return details
        .map((data) {
          return RouteDriveDetail(
            drive: data['drive'] as JsonMap,
            route: (data['route'] as List? ?? []).whereType<JsonMap>().toList(),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final limited = widget.route.driveIds.length > 24;
    return FuturePane<List<RouteDriveDetail>>(
      future: _future,
      builder: (context, details) {
        return PageShell(
          title: '路线叠加',
          subtitle: limited
              ? '展示前 24/${widget.route.count} 次 · 起终点 800m 内合并'
              : '${widget.route.count} 次 · 起终点 800m 内合并',
          children: [
            Panel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 330,
                    child: MultiDriveRouteMap(
                      routes: details.map((detail) => detail.route).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RouteLine(start: widget.route.start, end: widget.route.end),
                  const SizedBox(height: 14),
                  MetricRow(
                    items: [
                      MetricItem('次数', '${widget.route.count} 次', blue),
                      MetricItem('总里程', kmCompact(widget.route.distance), cyan),
                      MetricItem(
                        '均次',
                        kmCompact(widget.route.distance / widget.route.count),
                        text,
                      ),
                      MetricItem(
                        '达成率',
                        widget.route.achievement == null
                            ? '--'
                            : '${widget.route.achievement!.toStringAsFixed(1)}%',
                        green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < details.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RouteDriveCard(
                  index: index + 1,
                  detail: details[index],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DriveDetailPage(
                        api: widget.api,
                        driveId: asInt(details[index].drive['id'])!,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class RouteDriveDetail {
  const RouteDriveDetail({required this.drive, required this.route});

  final JsonMap drive;
  final List<JsonMap> route;
}

class RouteDriveCard extends StatelessWidget {
  const RouteDriveCard({
    super.key,
    required this.index,
    required this.detail,
    required this.onTap,
  });

  final int index;
  final RouteDriveDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final drive = detail.drive;
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
                RankBadgeLite(rank: index),
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
                  kmCompact(drive['distance']),
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Icon(Icons.chevron_right, color: muted, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            MetricRow(
              items: [
                MetricItem('时长', minutesShort(drive['duration_min']), text),
                MetricItem('最高', speed(drive['speed_max']), red),
                MetricItem('达成率', rangeAchievementText(drive), green),
                MetricItem('轨迹点', '${detail.route.length}', muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RankBadgeLite extends StatelessWidget {
  const RankBadgeLite({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: blue.withValues(alpha: 0.38)),
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          color: blue,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
