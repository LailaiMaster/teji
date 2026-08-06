import 'package:flutter_test/flutter_test.dart';

import 'package:teji_app/src/api.dart';
import 'package:teji_app/src/utils/dashboard_metrics.dart';

void main() {
  group('monthly dashboard metrics', () {
    final rows = <JsonMap>[
      {'start_date': '2026-08-03T08:00:00', 'distance': 12.5},
      {'start_date': '2026-07-31T20:00:00', 'distance': 8.0},
      {'start_date': '2026-07-02T09:00:00', 'distance': 5.5},
      {'start_date': 'invalid', 'distance': 99.0},
    ];

    test('filters rows by the selected month', () {
      final july = rowsInMonth(rows, 'start_date', DateTime(2026, 7, 20));

      expect(july, hasLength(2));
      expect(sumDouble(july, 'distance'), 13.5);
    });

    test('returns unique data months in descending order', () {
      final months = dataMonths(
        rows,
        'start_date',
        include: DateTime(2026, 6, 15),
      );

      expect(months, [DateTime(2026, 8), DateTime(2026, 7), DateTime(2026, 6)]);
    });

    test('builds calendar data for the selected historical month', () {
      final drives = <JsonMap>[
        {'start_date': '2026-07-02T09:00:00', 'distance': 5.5},
        {'start_date': '2026-07-02T18:00:00', 'distance': 7.0},
        {'start_date': '2026-08-02T09:00:00', 'distance': 20.0},
      ];
      final charges = <JsonMap>[
        {'start_date': '2026-07-03T22:00:00'},
        {'start_date': '2026-08-03T22:00:00'},
      ];

      final july = monthCalendar(drives, charges, DateTime(2026, 7));

      expect(july, hasLength(31));
      expect(july[1].driveCount, 2);
      expect(july[1].distance, 12.5);
      expect(july[2].charged, isTrue);
      expect(july[2].driveCount, 0);
    });
  });
}
