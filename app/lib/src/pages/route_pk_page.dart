import 'package:flutter/material.dart';

import '../api.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/panels.dart';
import '../widgets/route_line.dart';
import '../widgets/shell.dart';
import 'route_overlay_page.dart';

class RoutePkPage extends StatelessWidget {
  const RoutePkPage({super.key, required this.api, required this.drives});

  final TejiApi api;
  final List<JsonMap> drives;

  @override
  Widget build(BuildContext context) {
    final routes = topRouteInsights(drives).take(8).toList();
    return PageShell(
      title: '路线 PK',
      subtitle: '按次数、均次里程、续航达成对比',
      children: [
        if (routes.length >= 2)
          RouteDuelPanel(
            left: routes[0],
            right: routes[1],
            onLeft: () => _open(context, routes[0]),
            onRight: () => _open(context, routes[1]),
          ),
        if (routes.length >= 2) const SizedBox(height: 14),
        if (routes.isEmpty)
          const Panel(
            child: Center(
              child: Text('暂无可对比路线', style: TextStyle(color: muted)),
            ),
          )
        else
          for (var index = 0; index < routes.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RoutePkCard(
                rank: index + 1,
                route: routes[index],
                onTap: () => _open(context, routes[index]),
              ),
            ),
      ],
    );
  }

  void _open(BuildContext context, RouteInsight route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteOverlayPage(api: api, route: route),
      ),
    );
  }
}

class RouteDuelPanel extends StatelessWidget {
  const RouteDuelPanel({
    super.key,
    required this.left,
    required this.right,
    required this.onLeft,
    required this.onRight,
  });

  final RouteInsight left;
  final RouteInsight right;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          blue.withValues(alpha: 0.14),
          panel,
          purple.withValues(alpha: 0.1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.ssid_chart,
            color: purple,
            title: '头名对决',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DuelSide(route: left, color: cyan, onTap: onLeft),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: DuelSide(route: right, color: amber, onTap: onRight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DuelSide extends StatelessWidget {
  const DuelSide({
    super.key,
    required this.route,
    required this.color,
    required this.onTap,
  });

  final RouteInsight route;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avg = route.distance / route.count;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panel2.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${route.start} → ${route.end}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${route.count} 次',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '均次 ${kmCompact(avg)} · 达成 ${route.achievement == null ? '--' : '${route.achievement!.toStringAsFixed(0)}%'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutePkCard extends StatelessWidget {
  const RoutePkCard({
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
    final avg = route.distance / route.count;
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
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: blue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${route.count} 次',
                    style: const TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
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
                MetricItem('均次', kmCompact(avg), text),
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
