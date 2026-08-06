import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/drive_insights.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/month_selector.dart';
import '../widgets/panels.dart';
import '../widgets/route_line.dart';
import '../widgets/shell.dart';
import 'drive_detail_page.dart';

class DriveRecordsPage extends StatefulWidget {
  const DriveRecordsPage({super.key, required this.api, this.carId});

  final TejiApi api;
  final int? carId;

  @override
  State<DriveRecordsPage> createState() => _DriveRecordsPageState();
}

class _DriveRecordsPageState extends State<DriveRecordsPage> {
  late Future<List<JsonMap>> _future;
  DateTime _selectedMonth = monthOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _future = widget.api.drives(limit: 200, carId: widget.carId);
  }

  Future<void> refresh() async {
    setState(
      () => _future = widget.api.drives(limit: 200, carId: widget.carId),
    );
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FuturePane<List<JsonMap>>(
      future: _future,
      onRefresh: refresh,
      builder: (context, drives) {
        final monthDrives = rowsInMonth(drives, 'start_date', _selectedMonth);
        return PageShell(
          title: '行程记录',
          subtitle:
              '${DateFormat('yyyy-MM').format(_selectedMonth)} · ${monthDrives.length} 条行程',
          children: [
            MonthSelector(
              month: _selectedMonth,
              availableMonths: dataMonths(
                drives,
                'start_date',
                include: _selectedMonth,
              ),
              onChanged: (month) => setState(() => _selectedMonth = month),
            ),
            const SizedBox(height: 14),
            DriveSummary(drives: monthDrives),
            const SizedBox(height: 14),
            if (monthDrives.isEmpty)
              const Panel(
                child: Center(
                  child: Text('该月暂无行程', style: TextStyle(color: muted)),
                ),
              )
            else
              ...monthDrives.map(
                (drive) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DriveRecordCard(
                    drive: drive,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DriveDetailPage(
                          api: widget.api,
                          driveId: asInt(drive['id'])!,
                        ),
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

class DriveSummary extends StatelessWidget {
  const DriveSummary({super.key, required this.drives});

  final List<JsonMap> drives;

  @override
  Widget build(BuildContext context) {
    final distance = sumDouble(drives, 'distance');
    final duration = sumInt(drives, 'duration_min');
    final avg = duration == 0 ? 0 : distance / (duration / 60);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(icon: Icons.analytics, color: cyan, title: '月度驾驶'),
          const SizedBox(height: 16),
          MetricRow(
            items: [
              MetricItem('次数', '${drives.length}', cyan),
              MetricItem('里程', kmCompact(distance), blue),
              MetricItem('时长', minutesShort(duration), text),
              MetricItem('均速', '${avg.toStringAsFixed(0)} km/h', amber),
            ],
          ),
        ],
      ),
    );
  }
}

class DriveRecordCard extends StatelessWidget {
  const DriveRecordCard({super.key, required this.drive, required this.onTap});

  final JsonMap drive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = drivingScore(drive);
    final explanation = explainEnergy(drive);
    final scoreColor = _scoreColor(score.score);
    return GestureDetector(
      onTap: onTap,
      child: Panel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    driveTimeRange(drive),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DistancePill(text: kmCompact(drive['distance'])),
              ],
            ),
            const SizedBox(height: 12),
            RouteLine(
              start: drivePointLabel(drive, 'start'),
              end: drivePointLabel(drive, 'end'),
            ),
            const SizedBox(height: 14),
            MetricRow(
              items: [
                MetricItem('电池', batteryChangeText(drive), green),
                MetricItem('续航', rangeChange(drive), blue),
                MetricItem('达成率', rangeAchievementText(drive), amber),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: 0.36),
                    ),
                  ),
                  child: Text(
                    '评分 ${score.score} · ${score.label}',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    explanation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _severityColor(explanation.severity),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _scoreColor(int score) {
  if (score >= 85) return green;
  if (score >= 70) return amber;
  return red;
}

Color _severityColor(int severity) {
  if (severity >= 2) return red;
  if (severity == 1) return amber;
  return muted;
}
