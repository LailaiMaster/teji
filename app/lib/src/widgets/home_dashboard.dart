import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../utils/drive_insights.dart';
import 'panels.dart';
import 'route_line.dart';

class StatusHero extends StatelessWidget {
  const StatusHero({super.key, required this.car, required this.latestDrive});

  final JsonMap car;
  final JsonMap? latestDrive;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF102132), Color(0xFF15111F)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      textValue(car['name']),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${textValue(car['marketing_name'], fallback: textValue(car['model']))} · ${dateTimeShort(car['position_time'])}',
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              StatusBadge(state: textValue(car['state'])),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: HeroNumber(
                  label: '电量',
                  value: percent(car['battery_level']),
                  accent: green,
                ),
              ),
              Expanded(
                child: HeroNumber(
                  label: '续航',
                  value: kmCompact(car['rated_battery_range_km']),
                  accent: cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: ((asDouble(car['battery_level']) ?? 0) / 100).clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(green),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              MiniTelemetry(
                icon: Icons.thermostat,
                label: '车内',
                value: celsiusShort(car['inside_temp']),
              ),
              MiniTelemetry(
                icon: Icons.thermostat_outlined,
                label: '车外',
                value: celsiusShort(car['outside_temp']),
              ),
              MiniTelemetry(
                icon: Icons.route,
                label: '今日',
                value: kmCompact(car['distance_today_km']),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      'driving' => green,
      'charging' => amber,
      'online' => cyan,
      'asleep' => purple,
      _ => muted,
    };
    final label = switch (state) {
      'driving' => '行驶',
      'charging' => '充电',
      'online' => '在线',
      'asleep' => '休眠',
      'offline' => '离线',
      _ => state,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class HeroNumber extends StatelessWidget {
  const HeroNumber({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MiniTelemetry extends StatelessWidget {
  const MiniTelemetry({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: muted, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$label $value',
                maxLines: 1,
                style: const TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleGrid extends StatelessWidget {
  const ModuleGrid({
    super.key,
    required this.onDrive,
    required this.onCharge,
    required this.onHealth,
    required this.onCalendar,
  });

  final VoidCallback onDrive;
  final VoidCallback onCharge;
  final VoidCallback onHealth;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    final modules = [
      ModuleSpec('行程记录', Icons.route, cyan, onDrive),
      ModuleSpec('充电记录', Icons.bolt, amber, onCharge),
      ModuleSpec('电池健康', Icons.battery_charging_full, green, onHealth),
      ModuleSpec('行程日历', Icons.calendar_month, purple, onCalendar),
    ];
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisExtent: 78,
      ),
      itemBuilder: (context, index) => ModuleTile(module: modules[index]),
    );
  }
}

class ModuleSpec {
  const ModuleSpec(this.title, this.icon, this.color, this.onTap);

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class ModuleTile extends StatelessWidget {
  const ModuleTile({super.key, required this.module});

  final ModuleSpec module;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: panel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module.icon, color: module.color, size: 23),
            const SizedBox(height: 6),
            Text(
              module.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayPanel extends StatelessWidget {
  const TodayPanel({super.key, required this.car, required this.latestDrive});

  final JsonMap? car;
  final JsonMap? latestDrive;

  @override
  Widget build(BuildContext context) {
    final distance = asDouble(car?['distance_today_km']) ?? 0;
    final duration = asInt(car?['duration_today_min']) ?? 0;
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            icon: Icons.analytics_outlined,
            color: cyan,
            title: '今日看板',
            trailing: '驾驶 ${asInt(car?['drives_today']) ?? 0} 次',
          ),
          const SizedBox(height: 14),
          MetricRow(
            items: [
              MetricItem('里程', kmCompact(distance), cyan),
              MetricItem('时长', '$duration 分', text),
              MetricItem('续航消耗', rangeLossText(latestDrive), amber),
              MetricItem('达成率', rangeAchievementText(latestDrive), green),
            ],
          ),
        ],
      ),
    );
  }
}

class MonthlyMileagePanel extends StatelessWidget {
  const MonthlyMileagePanel({
    super.key,
    required this.drives,
    required this.onMonthTap,
  });

  final List<JsonMap> drives;
  final ValueChanged<MonthDistance> onMonthTap;

  @override
  Widget build(BuildContext context) {
    final months = lastMonthStats(drives).take(6).toList();
    final maxDistance = months.fold<double>(
      1,
      (max, item) => math.max(max, item.distance),
    );
    final total = months.fold<double>(0, (sum, item) => sum + item.distance);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            icon: Icons.bar_chart,
            color: blue,
            title: '月度里程',
            trailing: '最近 6 个月',
            onTap: months.isEmpty ? null : () => onMonthTap(months.first),
          ),
          const SizedBox(height: 16),
          ...months.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onMonthTap(item),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        item.label,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: (item.distance / maxDistance).clamp(0, 1),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation(blue),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 62,
                      child: Text(
                        kmCompact(item.distance),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: muted, size: 16),
                  ],
                ),
              ),
            ),
          ),
          Text(
            '半年累计 ${kmCompact(total)}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class InsightsPanel extends StatelessWidget {
  const InsightsPanel({
    super.key,
    required this.drives,
    required this.charges,
    required this.onAchievementTap,
    required this.onPeakTap,
    required this.onRouteTap,
    required this.onRoutePkTap,
    required this.onReportTap,
  });

  final List<JsonMap> drives;
  final List<JsonMap> charges;
  final VoidCallback onAchievementTap;
  final VoidCallback onPeakTap;
  final VoidCallback onRouteTap;
  final VoidCallback onRoutePkTap;
  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    final achievement = averageRangeAchievement(drives);
    final efficiency = chargeEfficiency(charges);
    final loss = chargeLoss(charges);
    final topSpeed = maxByDouble(drives, 'speed_max');
    final topPower = maxByDouble(drives, 'power_max');
    final topRegen = minByDouble(drives, 'power_min');
    final route = topRouteInsight(drives);
    final months = lastMonthAchievementStats(drives);
    final score = averageDrivingScore(drives);

    return Panel(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF101A27),
          panel,
          purple.withValues(alpha: 0.07),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.auto_graph,
            color: cyan,
            title: '数据洞察',
            trailing: '本地分析',
          ),
          const SizedBox(height: 12),
          GridView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 88,
            ),
            children: [
              InsightTile(
                icon: Icons.psychology_alt,
                color: purple,
                label: '驾驶评分',
                value: score == null ? '--' : score.toStringAsFixed(0),
                caption: '综合效率与驾驶强度',
              ),
              InsightTile(
                icon: Icons.percent,
                color: green,
                label: '续航达成',
                value: achievement == null
                    ? '--'
                    : '${achievement.toStringAsFixed(1)}%',
                caption: '${drives.length} 条行程均值',
                onTap: onAchievementTap,
              ),
              InsightTile(
                icon: Icons.bolt,
                color: amber,
                label: '充电效率',
                value: efficiency == null
                    ? '--'
                    : '${efficiency.toStringAsFixed(1)}%',
                caption: loss == null ? '暂无取电数据' : '损耗 ${kwh(loss)}',
              ),
              InsightTile(
                icon: Icons.speed,
                color: red,
                label: '驾驶峰值',
                value: speed(topSpeed?['speed_max']),
                caption:
                    '${powerCompact(topPower?['power_max'])} / 回收 ${powerCompact(topRegen?['power_min'])}',
                onTap: onPeakTap,
              ),
              InsightTile(
                icon: Icons.route,
                color: blue,
                label: '常跑路线',
                value: route == null ? '--' : '${route.count} 次',
                caption: route == null
                    ? '地点数据不足'
                    : '${route.start} → ${route.end}',
                onTap: onRouteTap,
              ),
              InsightTile(
                icon: Icons.ssid_chart,
                color: purple,
                label: '路线 PK',
                value: route == null
                    ? '--'
                    : '${topRouteInsights(drives).length} 组',
                caption: '常跑路线横向对比',
                onTap: onRoutePkTap,
              ),
              InsightTile(
                icon: Icons.summarize,
                color: cyan,
                label: '周/月报',
                value: '${currentMonthRows(drives, 'start_date').length} 次',
                caption: '周期驾驶总结',
                onTap: onReportTap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AchievementStrip(months: months),
        ],
      ),
    );
  }
}

class InsightTile extends StatelessWidget {
  const InsightTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: panel2.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: muted, size: 15),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementStrip extends StatelessWidget {
  const AchievementStrip({super.key, required this.months});

  final List<MonthValue> months;

  @override
  Widget build(BuildContext context) {
    final ordered = months.reversed.toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: green, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '续航达成率趋势',
                  style: TextStyle(
                    color: text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (ordered.isNotEmpty)
                Text(
                  ordered.last.value == null
                      ? '--'
                      : '${ordered.last.value!.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...ordered.map((month) {
            final value = month.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      month.label.replaceAll('月', ''),
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: ((value ?? 0) / 100).clamp(0, 1),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          value == null ? muted : green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Text(
                      value == null ? '--' : '${value.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class LatestDrivePanel extends StatelessWidget {
  const LatestDrivePanel({super.key, required this.drive, required this.onTap});

  final JsonMap drive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Panel(
        padding: const EdgeInsets.all(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyan.withValues(alpha: 0.12),
            panel,
            blue.withValues(alpha: 0.08),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cyan.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cyan.withValues(alpha: 0.42)),
                  ),
                  child: const Icon(Icons.near_me, color: cyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '最近行程',
                        style: TextStyle(
                          color: text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateTimeShort(drive['end_date']),
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  kmCompact(drive['distance']),
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: muted, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            RouteLine(
              start: drivePointLabel(drive, 'start'),
              end: drivePointLabel(drive, 'end'),
            ),
            const SizedBox(height: 14),
            MetricRow(
              items: [
                MetricItem('时长', minutesShort(drive['duration_min']), text),
                MetricItem('均速', averageSpeed(drive), amber),
                MetricItem('最高', speed(drive['speed_max']), red),
                MetricItem('达成率', rangeAchievementText(drive), green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
