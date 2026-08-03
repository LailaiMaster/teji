import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../utils/drive_insights.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';
import 'drive_detail_page.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    required this.api,
    required this.drives,
    required this.charges,
  });

  final TejiApi api;
  final List<JsonMap> drives;
  final List<JsonMap> charges;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final monthStart = DateTime(now.year, now.month);
    final weekly = _periodReport(
      '本周',
      weekStart,
      weekStart.add(const Duration(days: 7)),
    );
    final monthly = _periodReport(
      '本月',
      monthStart,
      DateTime(now.year, now.month + 1),
    );

    return PageShell(
      title: '周报月报',
      subtitle: '基于本地 TeslaMate 数据生成',
      children: [
        ReportPanel(
          report: weekly,
          onOpenDrive: (drive) => _openDrive(context, drive),
        ),
        const SizedBox(height: 14),
        ReportPanel(
          report: monthly,
          onOpenDrive: (drive) => _openDrive(context, drive),
        ),
      ],
    );
  }

  PeriodReport _periodReport(String title, DateTime start, DateTime end) {
    final periodDrives = drives.where((drive) {
      final date = DateTime.tryParse(
        textValue(drive['start_date'], fallback: ''),
      );
      return date != null && !date.isBefore(start) && date.isBefore(end);
    }).toList();
    final periodCharges = charges.where((charge) {
      final date = DateTime.tryParse(
        textValue(charge['start_date'], fallback: ''),
      );
      return date != null && !date.isBefore(start) && date.isBefore(end);
    }).toList();
    final scored =
        periodDrives
            .map((drive) => MapEntry(drive, drivingScore(drive)))
            .toList()
          ..sort((a, b) => b.value.score.compareTo(a.value.score));
    final anomalies = periodDrives
        .where((drive) => explainEnergy(drive).severity > 0)
        .length;
    final routes = topRouteInsights(periodDrives);
    return PeriodReport(
      title: title,
      range:
          '${DateFormat('MM-dd').format(start)} ~ ${DateFormat('MM-dd').format(end.subtract(const Duration(days: 1)))}',
      drives: periodDrives,
      charges: periodCharges,
      averageScore: scored.isEmpty
          ? null
          : scored.map((item) => item.value.score).reduce((a, b) => a + b) /
                scored.length,
      bestDrive: scored.isEmpty ? null : scored.first.key,
      weakDrive: scored.isEmpty ? null : scored.last.key,
      anomalyCount: anomalies,
      topRoute: routes.isEmpty ? null : routes.first,
    );
  }

  void _openDrive(BuildContext context, JsonMap drive) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriveDetailPage(api: api, driveId: asInt(drive['id'])!),
      ),
    );
  }
}

class PeriodReport {
  const PeriodReport({
    required this.title,
    required this.range,
    required this.drives,
    required this.charges,
    required this.averageScore,
    required this.bestDrive,
    required this.weakDrive,
    required this.anomalyCount,
    required this.topRoute,
  });

  final String title;
  final String range;
  final List<JsonMap> drives;
  final List<JsonMap> charges;
  final double? averageScore;
  final JsonMap? bestDrive;
  final JsonMap? weakDrive;
  final int anomalyCount;
  final RouteInsight? topRoute;
}

class ReportPanel extends StatelessWidget {
  const ReportPanel({
    super.key,
    required this.report,
    required this.onOpenDrive,
  });

  final PeriodReport report;
  final ValueChanged<JsonMap> onOpenDrive;

  @override
  Widget build(BuildContext context) {
    final distance = sumDouble(report.drives, 'distance');
    final duration = sumInt(report.drives, 'duration_min');
    final charged = sumDouble(report.charges, 'charge_energy_added');
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            icon: Icons.summarize,
            color: cyan,
            title: report.title,
            trailing: report.range,
          ),
          const SizedBox(height: 14),
          MetricRow(
            items: [
              MetricItem('里程', kmCompact(distance), cyan),
              MetricItem('时长', minutesShort(duration), text),
              MetricItem('充电', kwh(charged), amber),
              MetricItem(
                '评分',
                report.averageScore == null
                    ? '--'
                    : report.averageScore!.toStringAsFixed(0),
                green,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ReportLine(
            icon: Icons.warning_amber,
            color: report.anomalyCount > 0 ? amber : green,
            content: report.anomalyCount > 0
                ? '${report.anomalyCount} 次能耗偏高行程'
                : '本周期没有明显能耗异常',
          ),
          if (report.topRoute != null)
            ReportLine(
              icon: Icons.route,
              color: blue,
              content:
                  '高频路线 ${report.topRoute!.count} 次：${report.topRoute!.start} → ${report.topRoute!.end}',
            ),
          if (report.bestDrive != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOpenDrive(report.bestDrive!),
              child: ReportLine(
                icon: Icons.emoji_events,
                color: green,
                content:
                    '最佳行程 ${drivingScore(report.bestDrive!).score} 分 · ${driveTimeRange(report.bestDrive!)}',
              ),
            ),
          if (report.weakDrive != null && report.weakDrive != report.bestDrive)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOpenDrive(report.weakDrive!),
              child: ReportLine(
                icon: Icons.manage_search,
                color: red,
                content:
                    '需关注 ${drivingScore(report.weakDrive!).score} 分 · ${driveTimeRange(report.weakDrive!)}',
              ),
            ),
        ],
      ),
    );
  }
}

class ReportLine extends StatelessWidget {
  const ReportLine({
    super.key,
    required this.icon,
    required this.color,
    required this.content,
  });

  final IconData icon;
  final Color color;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _startOfWeek(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - 1));
}
