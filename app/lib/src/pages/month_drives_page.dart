import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/month_selector.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';
import 'drive_detail_page.dart';
import 'drive_records_page.dart';
import 'month_heat_map_page.dart';

class MonthDrivesPage extends StatefulWidget {
  const MonthDrivesPage({
    super.key,
    required this.api,
    required this.month,
    required this.drives,
  });

  final TejiApi api;
  final DateTime month;
  final List<JsonMap> drives;

  @override
  State<MonthDrivesPage> createState() => _MonthDrivesPageState();
}

class _MonthDrivesPageState extends State<MonthDrivesPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = monthOnly(widget.month);
  }

  @override
  Widget build(BuildContext context) {
    final monthDrives = rowsInMonth(
      widget.drives,
      'start_date',
      _selectedMonth,
    );
    final distance = sumDouble(monthDrives, 'distance');
    final duration = sumInt(monthDrives, 'duration_min');
    return PageShell(
      title: '月度行程',
      subtitle: '${monthDrives.length} 条记录',
      children: [
        MonthSelector(
          month: _selectedMonth,
          availableMonths: dataMonths(
            widget.drives,
            'start_date',
            include: _selectedMonth,
          ),
          onChanged: (month) => setState(() => _selectedMonth = month),
        ),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(14),
          child: MetricRow(
            items: [
              MetricItem('里程', kmCompact(distance), cyan),
              MetricItem('时长', minutesShort(duration), text),
              MetricItem(
                '达成率',
                averageRangeAchievement(monthDrives) == null
                    ? '--'
                    : '${averageRangeAchievement(monthDrives)!.toStringAsFixed(1)}%',
                green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (monthDrives.isNotEmpty) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MonthHeatMapPage(
                  month: _selectedMonth,
                  drives: widget.drives,
                ),
              ),
            ),
            child: Panel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle(
                    icon: Icons.map,
                    color: amber,
                    title: '月度驾驶热力',
                    trailing: '起终点分布',
                  ),
                  const SizedBox(height: 10),
                  MetricRow(
                    items: [
                      MetricItem('行程', '${monthDrives.length}', cyan),
                      MetricItem('地点', '${_placeCount(monthDrives)}', amber),
                      MetricItem('点击', '查看地图', blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (monthDrives.isEmpty)
          const Panel(
            child: Center(
              child: Text('本月暂无行程', style: TextStyle(color: muted)),
            ),
          )
        else
          ...monthDrives.map(
            (drive) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
  }
}

int _placeCount(List<JsonMap> drives) {
  final names = <String>{};
  for (final drive in drives) {
    for (final side in ['start', 'end']) {
      final name = drivePointLabel(drive, side);
      if (name != '起点位置' && name != '终点位置') names.add(name);
    }
  }
  return names.length;
}
