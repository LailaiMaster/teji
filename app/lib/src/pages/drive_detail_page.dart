import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../utils/drive_insights.dart';
import '../widgets/drive_route_map.dart';
import '../widgets/panels.dart';
import '../widgets/route_line.dart';
import '../widgets/shell.dart';

class DriveDetailPage extends StatefulWidget {
  const DriveDetailPage({super.key, required this.api, required this.driveId});

  final TejiApi api;
  final int driveId;

  @override
  State<DriveDetailPage> createState() => _DriveDetailPageState();
}

class _DriveDetailPageState extends State<DriveDetailPage> {
  late Future<JsonMap> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.driveDetail(widget.driveId);
  }

  @override
  Widget build(BuildContext context) {
    return FuturePane<JsonMap>(
      future: _future,
      builder: (context, data) {
        final drive = data['drive'] as JsonMap;
        final route = (data['route'] as List? ?? [])
            .whereType<JsonMap>()
            .toList();
        return DriveDetailContent(drive: drive, route: route);
      },
    );
  }
}

class DriveDetailContent extends StatefulWidget {
  const DriveDetailContent({
    super.key,
    required this.drive,
    required this.route,
  });

  final JsonMap drive;
  final List<JsonMap> route;

  @override
  State<DriveDetailContent> createState() => _DriveDetailContentState();
}

class _DriveDetailContentState extends State<DriveDetailContent> {
  int selectedIndex = 0;

  JsonMap? get selectedPoint {
    if (widget.route.isEmpty) return null;
    return widget.route[selectedIndex.clamp(0, widget.route.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final drive = widget.drive;
    final route = widget.route;
    final point = selectedPoint;

    return PageShell(
      title: '行程详情',
      subtitle: driveTimeRange(drive),
      children: [
        Panel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 250,
                child: DriveRouteMap(
                  points: route,
                  selectedIndex: selectedIndex,
                ),
              ),
              if (route.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '轨迹点 ${selectedIndex + 1}/${route.length}',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: cyan,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                    thumbColor: cyan,
                    overlayColor: cyan.withValues(alpha: 0.16),
                  ),
                  child: Slider(
                    min: 0,
                    max: (route.length - 1).toDouble(),
                    divisions: math.min(route.length - 1, 250),
                    value: selectedIndex.clamp(0, route.length - 1).toDouble(),
                    onChanged: (value) =>
                        setState(() => selectedIndex = value.round()),
                  ),
                ),
                SamplePointPanel(point: point),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        DriveScorePanel(drive: drive),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(
                icon: Icons.analytics,
                color: cyan,
                title: '行程数据统计',
              ),
              const SizedBox(height: 16),
              RouteLine(
                start: drivePointLabel(drive, 'start'),
                end: drivePointLabel(drive, 'end'),
              ),
              const SizedBox(height: 18),
              DetailMetricGrid(
                metrics: [
                  DetailMetric(
                    '行驶时间',
                    minutesShort(drive['duration_min']),
                    Icons.schedule,
                    blue,
                  ),
                  DetailMetric(
                    '行驶距离',
                    kmCompact(drive['distance']),
                    Icons.near_me,
                    green,
                  ),
                  DetailMetric('平均速度', averageSpeed(drive), Icons.speed, amber),
                  DetailMetric(
                    '最高速度',
                    speed(drive['speed_max']),
                    Icons.speed_outlined,
                    red,
                    onTap: () => selectMaxValue('speed'),
                  ),
                  DetailMetric(
                    '电池变化',
                    batteryChangeText(drive),
                    Icons.battery_5_bar,
                    purple,
                  ),
                  DetailMetric(
                    '表显续航变化',
                    rangeChange(drive),
                    Icons.route,
                    amber,
                  ),
                  DetailMetric(
                    '续航消耗',
                    rangeLossText(drive),
                    Icons.remove_circle_outline,
                    red,
                  ),
                  DetailMetric(
                    '续航达成率',
                    rangeAchievementText(drive),
                    Icons.percent,
                    amber,
                  ),
                  DetailMetric(
                    '最大功率',
                    power(drive['power_max']),
                    Icons.bolt,
                    purple,
                  ),
                  DetailMetric(
                    '最大回收',
                    power(drive['power_min']),
                    Icons.replay,
                    cyan,
                  ),
                  DetailMetric(
                    '海拔变化',
                    '↑${textValue(drive['ascent'])} ↓${textValue(drive['descent'])}',
                    Icons.terrain,
                    muted,
                  ),
                  DetailMetric(
                    '室外温度',
                    celsiusShort(drive['outside_temp_avg']),
                    Icons.thermostat,
                    cyan,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(
                icon: Icons.show_chart,
                color: green,
                title: '数据曲线',
              ),
              const SizedBox(height: 12),
              const ChartLegend(),
              const SizedBox(height: 10),
              SizedBox(
                height: 210,
                child: DriveTelemetryChart(
                  points: route,
                  selectedIndex: selectedIndex,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void selectMaxValue(String key) {
    var bestIndex = -1;
    double? bestValue;
    for (var index = 0; index < widget.route.length; index++) {
      final value = asDouble(widget.route[index][key]);
      if (value == null) continue;
      if (bestValue == null || value > bestValue) {
        bestValue = value;
        bestIndex = index;
      }
    }
    if (bestIndex < 0) return;
    setState(() => selectedIndex = bestIndex);
  }
}

class DriveScorePanel extends StatelessWidget {
  const DriveScorePanel({super.key, required this.drive});

  final JsonMap drive;

  @override
  Widget build(BuildContext context) {
    final score = drivingScore(drive);
    final explanation = explainEnergy(drive);
    final scoreColor = _scoreColor(score.score);
    final severityColor = _severityColor(explanation.severity);
    return Panel(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scoreColor.withValues(alpha: 0.12),
          panel,
          severityColor.withValues(alpha: 0.07),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.psychology_alt,
            color: purple,
            title: '驾驶评分',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.score}',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  score.label,
                  style: const TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.36),
                  ),
                ),
                child: Text(
                  explanation.title,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation.summary,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final reason in explanation.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, color: severityColor, size: 7),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SamplePointPanel extends StatelessWidget {
  const SamplePointPanel({super.key, required this.point});

  final JsonMap? point;

  @override
  Widget build(BuildContext context) {
    if (point == null) {
      return const Text('暂无轨迹采样', style: TextStyle(color: muted));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateTimeFull(point!['date']),
            style: const TextStyle(
              color: text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          MetricRow(
            items: [
              MetricItem('速度', speed(point!['speed']), cyan),
              MetricItem('功率', power(point!['power']), amber),
              MetricItem('电量', percent(point!['battery_level']), green),
            ],
          ),
          const SizedBox(height: 12),
          MetricRow(
            items: [
              MetricItem(
                '表显续航',
                kmCompact(point!['rated_battery_range_km']),
                blue,
              ),
              MetricItem(
                '海拔',
                point!['elevation'] == null
                    ? '--'
                    : '${textValue(point!['elevation'])} m',
                purple,
              ),
              MetricItem('外温', celsiusShort(point!['outside_temp']), text),
            ],
          ),
        ],
      ),
    );
  }
}

class DetailMetricGrid extends StatelessWidget {
  const DetailMetricGrid({super.key, required this.metrics});

  final List<DetailMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 330 ? 4 : 3;
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            mainAxisExtent: 70,
          ),
          itemBuilder: (context, index) =>
              DetailMetricTile(metric: metrics[index]),
        );
      },
    );
  }
}

class DetailMetric {
  const DetailMetric(
    this.label,
    this.value,
    this.icon,
    this.color, {
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class DetailMetricTile extends StatelessWidget {
  const DetailMetricTile({super.key, required this.metric});

  final DetailMetric metric;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: metric.onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: panel2,
            borderRadius: radius,
            border: Border.all(color: metric.color.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(metric.icon, color: metric.color, size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ),
                  if (metric.onTap != null)
                    Icon(
                      Icons.my_location,
                      color: metric.color.withValues(alpha: 0.9),
                      size: 11,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        LegendDot(color: cyan, label: '速度'),
        SizedBox(width: 14),
        LegendDot(color: green, label: '功率'),
        SizedBox(width: 14),
        LegendDot(color: amber, label: '电量'),
      ],
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

class DriveTelemetryChart extends StatelessWidget {
  const DriveTelemetryChart({
    super.key,
    required this.points,
    required this.selectedIndex,
  });

  final List<JsonMap> points;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Center(
        child: Text('暂无曲线数据', style: TextStyle(color: muted)),
      );
    }
    return CustomPaint(
      painter: DriveTelemetryChartPainter(
        points: points,
        selectedIndex: selectedIndex,
      ),
      child: const SizedBox.expand(),
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
  return green;
}

class DriveTelemetryChartPainter extends CustomPainter {
  DriveTelemetryChartPainter({
    required this.points,
    required this.selectedIndex,
  });

  final List<JsonMap> points;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()..color = panel2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      bgPaint,
    );

    final chart = rect.deflate(16);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    drawSeries(
      canvas,
      chart,
      points.map((p) => asDouble(p['speed'])).toList(),
      cyan,
    );
    drawSeries(
      canvas,
      chart,
      points.map((p) => asDouble(p['power'])?.abs()).toList(),
      green,
    );
    drawSeries(
      canvas,
      chart,
      points.map((p) => asDouble(p['battery_level'])).toList(),
      amber,
    );

    final idx = selectedIndex.clamp(0, points.length - 1);
    final x = chart.left + chart.width * idx / (points.length - 1);
    final marker = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), marker);
  }

  void drawSeries(
    Canvas canvas,
    Rect chart,
    List<double?> rawValues,
    Color color,
  ) {
    final values = rawValues.whereType<double>().toList();
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = math.max(maxValue - minValue, 0.0001);
    final path = Path();
    var started = false;
    for (var i = 0; i < rawValues.length; i++) {
      final value = rawValues[i];
      if (value == null) continue;
      final x = chart.left + chart.width * i / (rawValues.length - 1);
      final y = chart.bottom - chart.height * ((value - minValue) / span);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DriveTelemetryChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
