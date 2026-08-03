import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';

class BatteryHealthPage extends StatelessWidget {
  const BatteryHealthPage({super.key, required this.car, required this.drives});

  final JsonMap? car;
  final List<JsonMap> drives;

  @override
  Widget build(BuildContext context) {
    final odometer = asDouble(car?['odometer']);
    final ratedRange = asDouble(car?['rated_battery_range_km']);
    final batteryLevel = asDouble(car?['battery_level']);
    final avgAchievement = averageRangeAchievement(drives);
    final finishedDriveCount = drives.length;

    return PageShell(
      title: '电池健康',
      subtitle: '仅展示 TeslaMate 当前可观测数据',
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(
                icon: Icons.battery_charging_full,
                color: green,
                title: '当前电池状态',
              ),
              const SizedBox(height: 18),
              MetricRow(
                items: [
                  MetricItem(
                    '当前电量',
                    batteryLevel == null
                        ? '--'
                        : '${batteryLevel.toStringAsFixed(0)}%',
                    green,
                  ),
                  MetricItem(
                    '表显续航',
                    ratedRange == null ? '--' : kmCompact(ratedRange),
                    cyan,
                  ),
                  MetricItem(
                    '总里程',
                    odometer == null ? '--' : kmCompact(odometer),
                    blue,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(
                icon: Icons.route,
                color: amber,
                title: '行驶效率观察',
              ),
              const SizedBox(height: 18),
              MetricRow(
                items: [
                  MetricItem('样本行程', '$finishedDriveCount 条', text),
                  MetricItem(
                    '平均达成率',
                    avgAchievement == null
                        ? '--'
                        : '${avgAchievement.toStringAsFixed(1)}%',
                    green,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'TeslaMate 当前数据没有电池可用容量、BMS 健康度等原始字段，因此这里不伪造健康分，只展示可由行程和续航字段直接计算的指标。',
                style: TextStyle(color: muted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
