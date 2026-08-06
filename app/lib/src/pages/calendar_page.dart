import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/month_selector.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';
import 'calendar_day_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.api,
    required this.drives,
    required this.charges,
  });

  final TejiApi api;
  final List<JsonMap> drives;
  final List<JsonMap> charges;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedMonth = monthOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final days = monthCalendar(widget.drives, widget.charges, _selectedMonth);
    final leadingEmptyDays =
        DateTime(_selectedMonth.year, _selectedMonth.month).weekday - 1;
    final rows = <JsonMap>[...widget.drives, ...widget.charges];
    return PageShell(
      title: '行程日历',
      subtitle: DateFormat('yyyy-MM').format(_selectedMonth),
      children: [
        MonthSelector(
          month: _selectedMonth,
          availableMonths: dataMonths(
            rows,
            'start_date',
            include: _selectedMonth,
          ),
          label: '日历月份',
          onChanged: (month) => setState(() => _selectedMonth = month),
        ),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: ['一', '二', '三', '四', '五', '六', '日']
                    .map(
                      (label) => Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leadingEmptyDays + days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingEmptyDays) return const SizedBox.shrink();
                  final day = days[index - leadingEmptyDays];
                  return DayCell(
                    day: day,
                    onTap: day.driveCount == 0
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) {
                                final date = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month,
                                  day.day,
                                );
                                return CalendarDayPage(
                                  api: widget.api,
                                  date: date,
                                  drives: _drivesOnDate(date),
                                );
                              },
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<JsonMap> _drivesOnDate(DateTime date) {
    final rows = widget.drives.where((drive) {
      final start = DateTime.tryParse(
        textValue(drive['start_date'], fallback: ''),
      );
      return start != null &&
          start.year == date.year &&
          start.month == date.month &&
          start.day == date.day;
    }).toList();
    rows.sort((a, b) {
      final at = DateTime.tryParse(textValue(a['start_date'], fallback: ''));
      final bt = DateTime.tryParse(textValue(b['start_date'], fallback: ''));
      return (bt ?? DateTime(1970)).compareTo(at ?? DateTime(1970));
    });
    return rows;
  }
}

class DayCell extends StatelessWidget {
  const DayCell({super.key, required this.day, this.onTap});

  final DayInfo day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = day.distance > 0 || day.charged;
    final radius = BorderRadius.circular(9);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active
                ? blue.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: radius,
            border: Border.all(
              color: active ? blue.withValues(alpha: 0.35) : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (day.charged)
                const Align(
                  alignment: Alignment.topRight,
                  child: Icon(Icons.bolt, color: green, size: 11),
                ),
              if (day.driveCount > 0)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: blue.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      '${day.driveCount}',
                      style: const TextStyle(
                        color: blue,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (day.distance > 0)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _calendarDistance(day.distance),
                        maxLines: 1,
                        style: const TextStyle(
                          color: cyan,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
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

  String _calendarDistance(double value) {
    if (value >= 100) return '${value.toStringAsFixed(0)}km';
    return '${value.toStringAsFixed(1)}km';
  }
}
