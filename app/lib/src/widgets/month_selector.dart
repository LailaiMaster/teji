import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_style.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.availableMonths,
    required this.onChanged,
    this.label = '统计月份',
  });

  final DateTime month;
  final List<DateTime> availableMonths;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = DateTime(month.year, month.month);
    final options = _normalizedOptions(selected);
    final earliest = options.last;
    final latest = DateTime.now();
    final previous = DateTime(selected.year, selected.month - 1);
    final next = DateTime(selected.year, selected.month + 1);
    final canGoPrevious = !previous.isBefore(earliest);
    final canGoNext = !next.isAfter(DateTime(latest.year, latest.month));

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '上个月',
            onPressed: canGoPrevious ? () => onChanged(previous) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: PopupMenuButton<DateTime>(
              tooltip: '选择月份',
              onSelected: onChanged,
              itemBuilder: (context) => options
                  .map(
                    (option) => PopupMenuItem<DateTime>(
                      value: option,
                      child: Row(
                        children: [
                          Icon(
                            _sameMonth(option, selected)
                                ? Icons.check_circle
                                : Icons.calendar_month,
                            color: _sameMonth(option, selected) ? cyan : muted,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(DateFormat('yyyy年MM月').format(option)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('yyyy年MM月').format(selected),
                        style: const TextStyle(
                          color: text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: cyan),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: '下个月',
            onPressed: canGoNext ? () => onChanged(next) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  List<DateTime> _normalizedOptions(DateTime selected) {
    final values = <int, DateTime>{};
    for (final value in availableMonths) {
      final month = DateTime(value.year, value.month);
      values[month.year * 100 + month.month] = month;
    }
    values[selected.year * 100 + selected.month] = selected;
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    values[current.year * 100 + current.month] = current;
    final options = values.values.toList()..sort((a, b) => b.compareTo(a));
    return options;
  }

  bool _sameMonth(DateTime left, DateTime right) =>
      left.year == right.year && left.month == right.month;
}
