import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';
import 'drive_detail_page.dart';
import 'drive_records_page.dart';

class CalendarDayPage extends StatelessWidget {
  const CalendarDayPage({
    super.key,
    required this.api,
    required this.date,
    required this.drives,
  });

  final TejiApi api;
  final DateTime date;
  final List<JsonMap> drives;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: DateFormat('M月d日行程').format(date),
      subtitle: '${drives.length} 条行程',
      children: [
        DayDriveSummary(drives: drives),
        const SizedBox(height: 14),
        if (drives.isEmpty)
          const EmptyDayPanel()
        else
          ...drives.map(
            (drive) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DriveRecordCard(
                drive: drive,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        DriveDetailPage(api: api, driveId: asInt(drive['id'])!),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DayDriveSummary extends StatelessWidget {
  const DayDriveSummary({super.key, required this.drives});

  final List<JsonMap> drives;

  @override
  Widget build(BuildContext context) {
    final distance = sumDouble(drives, 'distance');
    final duration = sumInt(drives, 'duration_min');
    final avgSpeed = duration == 0 ? null : distance / (duration / 60);
    final achievement = averageRangeAchievement(drives);

    return Panel(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF121A33), Color(0xFF0B1020)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(icon: Icons.route, color: cyan, title: '当天驾驶统计'),
          const SizedBox(height: 16),
          MetricRow(
            items: [
              MetricItem('次数', '${drives.length}', cyan),
              MetricItem('里程', kmCompact(distance), blue),
              MetricItem('时长', minutesShort(duration), text),
              MetricItem(
                '均速',
                avgSpeed == null ? '--' : '${avgSpeed.toStringAsFixed(0)} km/h',
                amber,
              ),
            ],
          ),
          const SizedBox(height: 14),
          MetricRow(
            items: [
              MetricItem('电池', _batteryDayChange(drives), green),
              MetricItem(
                '达成率',
                achievement == null
                    ? '--'
                    : '${achievement.toStringAsFixed(1)}%',
                amber,
              ),
              MetricItem('续航消耗', _rangeLossSum(drives), red),
            ],
          ),
        ],
      ),
    );
  }

  String _batteryDayChange(List<JsonMap> rows) {
    if (rows.isEmpty) return '--';
    final chronological = [...rows]
      ..sort((a, b) {
        final at = DateTime.tryParse(textValue(a['start_date'], fallback: ''));
        final bt = DateTime.tryParse(textValue(b['start_date'], fallback: ''));
        return (at ?? DateTime(1970)).compareTo(bt ?? DateTime(1970));
      });
    final first = chronological.first;
    final last = chronological.last;
    final start =
        asDouble(first['start_battery_level']) ??
        asDouble(first['start_usable_battery_level']);
    final end =
        asDouble(last['end_battery_level']) ??
        asDouble(last['end_usable_battery_level']);
    if (start == null || end == null) return '--';
    return '${start.toStringAsFixed(0)}%→${end.toStringAsFixed(0)}%';
  }

  String _rangeLossSum(List<JsonMap> rows) {
    final losses = rows.map(ratedRangeLoss).whereType<double>().toList();
    if (losses.isEmpty) return '--';
    final total = losses.reduce((a, b) => a + b);
    return '${total.toStringAsFixed(1)} km';
  }
}

class EmptyDayPanel extends StatelessWidget {
  const EmptyDayPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Panel(
      child: Column(
        children: [
          Icon(Icons.route_outlined, color: muted, size: 34),
          SizedBox(height: 10),
          Text(
            '这天没有行程',
            style: TextStyle(
              color: text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
