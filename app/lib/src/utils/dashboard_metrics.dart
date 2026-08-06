import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../api.dart';
import '../formatters.dart';

class MonthDistance {
  const MonthDistance(this.label, this.distance, this.month);

  final String label;
  final double distance;
  final DateTime month;
}

class MonthValue {
  const MonthValue(this.label, this.value);

  final String label;
  final double? value;
}

class RouteInsight {
  const RouteInsight({
    required this.start,
    required this.end,
    required this.count,
    required this.distance,
    required this.achievement,
    required this.driveIds,
  });

  final String start;
  final String end;
  final int count;
  final double distance;
  final double? achievement;
  final List<int> driveIds;
}

class DayInfo {
  const DayInfo(this.day, this.distance, this.charged, this.driveCount);

  final int day;
  final double distance;
  final bool charged;
  final int driveCount;
}

List<JsonMap> rowsForCar(List<JsonMap> rows, int? carId) {
  if (carId == null) return rows;
  return rows.where((row) => asInt(row['car_id']) == carId).toList();
}

List<JsonMap> currentMonthRows(List<JsonMap> rows, String key) {
  return rowsInMonth(rows, key, DateTime.now());
}

DateTime monthOnly(DateTime date) => DateTime(date.year, date.month);

bool isSameMonth(DateTime left, DateTime right) =>
    left.year == right.year && left.month == right.month;

List<JsonMap> rowsInMonth(List<JsonMap> rows, String key, DateTime month) {
  return rows.where((row) {
    final date = DateTime.tryParse(textValue(row[key], fallback: ''));
    return date != null && isSameMonth(date, month);
  }).toList();
}

List<DateTime> dataMonths(List<JsonMap> rows, String key, {DateTime? include}) {
  final months = <int, DateTime>{};
  for (final row in rows) {
    final date = DateTime.tryParse(textValue(row[key], fallback: ''));
    if (date == null) continue;
    final month = monthOnly(date);
    months[month.year * 100 + month.month] = month;
  }
  if (include != null) {
    final month = monthOnly(include);
    months[month.year * 100 + month.month] = month;
  }
  final values = months.values.toList()..sort((a, b) => b.compareTo(a));
  return values;
}

List<MonthDistance> lastMonthStats(List<JsonMap> drives) {
  final now = DateTime.now();
  final byMonth = <String, double>{};
  for (final drive in drives) {
    final date = DateTime.tryParse(
      textValue(drive['start_date'], fallback: ''),
    );
    if (date == null) continue;
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    byMonth[key] = (byMonth[key] ?? 0) + (asDouble(drive['distance']) ?? 0);
  }
  return List.generate(6, (index) {
    final month = DateTime(now.year, now.month - index);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return MonthDistance(
      '${month.month.toString().padLeft(2, '0')}月',
      byMonth[key] ?? 0,
      month,
    );
  });
}

List<MonthValue> lastMonthAchievementStats(List<JsonMap> drives) {
  final now = DateTime.now();
  final valuesByMonth = <String, List<double>>{};
  for (final drive in drives) {
    final date = DateTime.tryParse(
      textValue(drive['start_date'], fallback: ''),
    );
    final value = rangeAchievement(drive);
    if (date == null || value == null || value <= 0) continue;
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    valuesByMonth.putIfAbsent(key, () => []).add(value);
  }
  return List.generate(6, (index) {
    final month = DateTime(now.year, now.month - index);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final values = valuesByMonth[key] ?? const <double>[];
    final average = values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
    return MonthValue('${month.month.toString().padLeft(2, '0')}月', average);
  });
}

List<DayInfo> monthCalendar(
  List<JsonMap> drives,
  List<JsonMap> charges,
  DateTime month,
) {
  final selectedMonth = monthOnly(month);
  final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
  final distanceByDay = <int, double>{};
  final drivesByDay = <int, int>{};
  final chargeDays = <int>{};
  for (final drive in drives) {
    final date = DateTime.tryParse(
      textValue(drive['start_date'], fallback: ''),
    );
    if (date == null || !isSameMonth(date, selectedMonth)) {
      continue;
    }
    distanceByDay[date.day] =
        (distanceByDay[date.day] ?? 0) + (asDouble(drive['distance']) ?? 0);
    drivesByDay[date.day] = (drivesByDay[date.day] ?? 0) + 1;
  }
  for (final charge in charges) {
    final date = DateTime.tryParse(
      textValue(charge['start_date'], fallback: ''),
    );
    if (date == null || !isSameMonth(date, selectedMonth)) {
      continue;
    }
    chargeDays.add(date.day);
  }
  return List.generate(lastDay, (index) {
    final day = index + 1;
    return DayInfo(
      day,
      distanceByDay[day] ?? 0,
      chargeDays.contains(day),
      drivesByDay[day] ?? 0,
    );
  });
}

double sumDouble(List<JsonMap> rows, String key) {
  return rows.fold(0, (sum, row) => sum + (asDouble(row[key]) ?? 0));
}

int sumInt(List<JsonMap> rows, String key) {
  return rows.fold(0, (sum, row) => sum + (asInt(row[key]) ?? 0));
}

String compactNumber(double value) {
  if (value >= 100) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String kmCompact(Object? value) {
  final number = asDouble(value);
  if (number == null) return '-- km';
  return '${compactNumber(number)} km';
}

String celsiusShort(Object? value) {
  final number = asDouble(value);
  if (number == null) return '--℃';
  return '${number.toStringAsFixed(0)}℃';
}

String powerCompact(Object? value) {
  final number = asDouble(value);
  if (number == null) return '--kW';
  return '${number.toStringAsFixed(0)}kW';
}

String minutesShort(Object? value) {
  final min = asInt(value);
  if (min == null) return '--';
  if (min < 60) return '$min 分';
  return '${min ~/ 60}h ${min % 60}m';
}

String driveTimeRange(JsonMap drive) {
  final start = DateTime.tryParse(textValue(drive['start_date'], fallback: ''));
  final end = DateTime.tryParse(textValue(drive['end_date'], fallback: ''));
  if (start == null || end == null) return '--';
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  final startText = DateFormat('MM-dd HH:mm').format(start);
  final endText = DateFormat(sameDay ? 'HH:mm' : 'MM-dd HH:mm').format(end);
  return '$startText 至 $endText';
}

String chargeTimeRange(JsonMap charge) {
  final start = DateTime.tryParse(
    textValue(charge['start_date'], fallback: ''),
  );
  final end = DateTime.tryParse(textValue(charge['end_date'], fallback: ''));
  if (start == null || end == null) return '--';
  return '${DateFormat('MM-dd HH:mm').format(start)} 至 ${DateFormat('MM-dd HH:mm').format(end)}';
}

String averageSpeed(JsonMap? drive) {
  final distance = asDouble(drive?['distance']);
  final duration = asInt(drive?['duration_min']);
  if (distance == null || duration == null || duration == 0) return '--';
  return '${(distance / (duration / 60)).toStringAsFixed(0)} km/h';
}

double? ratedRangeLoss(JsonMap? drive) {
  final start = asDouble(drive?['start_rated_range_km']);
  final end = asDouble(drive?['end_rated_range_km']);
  if (start == null || end == null) return null;
  return start - end;
}

double? rangeAchievement(JsonMap? drive) {
  final distance = asDouble(drive?['distance']);
  final loss = ratedRangeLoss(drive);
  if (distance == null || distance <= 0 || loss == null || loss <= 0) {
    return null;
  }
  return distance / loss * 100;
}

double? averageRangeAchievement(List<JsonMap> drives) {
  final values = drives
      .map(rangeAchievement)
      .whereType<double>()
      .where((value) => value > 0)
      .toList();
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

double? chargeEfficiency(List<JsonMap> charges) {
  final added = sumDouble(charges, 'charge_energy_added');
  final used = sumDouble(charges, 'charge_energy_used');
  if (added <= 0 || used <= 0) return null;
  return added / used * 100;
}

double? chargeLoss(List<JsonMap> charges) {
  final added = sumDouble(charges, 'charge_energy_added');
  final used = sumDouble(charges, 'charge_energy_used');
  if (added <= 0 || used <= 0) return null;
  return used - added;
}

JsonMap? maxByDouble(List<JsonMap> rows, String key) {
  JsonMap? best;
  double? bestValue;
  for (final row in rows) {
    final value = asDouble(row[key]);
    if (value == null) continue;
    if (bestValue == null || value > bestValue) {
      best = row;
      bestValue = value;
    }
  }
  return best;
}

JsonMap? minByDouble(List<JsonMap> rows, String key) {
  JsonMap? best;
  double? bestValue;
  for (final row in rows) {
    final value = asDouble(row[key]);
    if (value == null) continue;
    if (bestValue == null || value < bestValue) {
      best = row;
      bestValue = value;
    }
  }
  return best;
}

RouteInsight? topRouteInsight(List<JsonMap> drives) {
  final insights = topRouteInsights(drives);
  return insights.isEmpty ? null : insights.first;
}

List<RouteInsight> topRouteInsights(List<JsonMap> drives) {
  const endpointToleranceKm = 0.8;
  final buckets = <_RouteBucket>[];
  final exactBuckets = <String, _RouteBucket>{};
  for (final drive in drives) {
    final start = drivePointLabel(drive, 'start');
    final end = drivePointLabel(drive, 'end');
    if (start == '起点位置' || end == '终点位置') continue;

    final startLat = asDouble(drive['start_latitude']);
    final startLon = asDouble(drive['start_longitude']);
    final endLat = asDouble(drive['end_latitude']);
    final endLon = asDouble(drive['end_longitude']);
    _RouteBucket? bucket;

    if (startLat != null &&
        startLon != null &&
        endLat != null &&
        endLon != null) {
      for (final candidate in buckets) {
        if (candidate.matches(
          startLat: startLat,
          startLon: startLon,
          endLat: endLat,
          endLon: endLon,
          toleranceKm: endpointToleranceKm,
        )) {
          bucket = candidate;
          break;
        }
      }
      bucket ??= _RouteBucket(
        startLat: startLat,
        startLon: startLon,
        endLat: endLat,
        endLon: endLon,
      );
      if (!buckets.contains(bucket)) buckets.add(bucket);
    } else {
      final key = '$start->$end';
      bucket = exactBuckets.putIfAbsent(key, () {
        final created = _RouteBucket();
        buckets.add(created);
        return created;
      });
    }

    bucket.add(drive, start: start, end: end);
  }
  final insights = buckets.map((bucket) {
    return RouteInsight(
      start: bucket.displayStart,
      end: bucket.displayEnd,
      count: bucket.count,
      distance: bucket.distance,
      achievement: bucket.achievementCount == 0
          ? null
          : bucket.achievementSum / bucket.achievementCount,
      driveIds: List.unmodifiable(bucket.driveIds),
    );
  }).toList();
  insights.sort((a, b) {
    final count = b.count.compareTo(a.count);
    if (count != 0) return count;
    return b.distance.compareTo(a.distance);
  });
  return insights;
}

class _RouteBucket {
  _RouteBucket({this.startLat, this.startLon, this.endLat, this.endLon});

  final _startNames = <String, int>{};
  final _endNames = <String, int>{};
  final driveIds = <int>[];
  double? startLat;
  double? startLon;
  double? endLat;
  double? endLon;
  int count = 0;
  double distance = 0;
  double achievementSum = 0;
  int achievementCount = 0;

  String get displayStart => _topName(_startNames, '起点位置');

  String get displayEnd => _topName(_endNames, '终点位置');

  bool matches({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required double toleranceKm,
  }) {
    if (this.startLat == null ||
        this.startLon == null ||
        this.endLat == null ||
        this.endLon == null) {
      return false;
    }
    return _distanceKm(this.startLat!, this.startLon!, startLat, startLon) <=
            toleranceKm &&
        _distanceKm(this.endLat!, this.endLon!, endLat, endLon) <= toleranceKm;
  }

  void add(JsonMap drive, {required String start, required String end}) {
    _startNames[start] = (_startNames[start] ?? 0) + 1;
    _endNames[end] = (_endNames[end] ?? 0) + 1;
    final id = asInt(drive['id']);
    if (id != null) driveIds.add(id);

    final nextCount = count + 1;
    final driveStartLat = asDouble(drive['start_latitude']);
    final driveStartLon = asDouble(drive['start_longitude']);
    final driveEndLat = asDouble(drive['end_latitude']);
    final driveEndLon = asDouble(drive['end_longitude']);
    if (driveStartLat != null && driveStartLon != null) {
      startLat = _weightedAverage(startLat, driveStartLat, count, nextCount);
      startLon = _weightedAverage(startLon, driveStartLon, count, nextCount);
    }
    if (driveEndLat != null && driveEndLon != null) {
      endLat = _weightedAverage(endLat, driveEndLat, count, nextCount);
      endLon = _weightedAverage(endLon, driveEndLon, count, nextCount);
    }

    count = nextCount;
    distance += asDouble(drive['distance']) ?? 0;
    final achievement = rangeAchievement(drive);
    if (achievement != null && achievement > 0) {
      achievementSum += achievement;
      achievementCount++;
    }
  }
}

String _topName(Map<String, int> names, String fallback) {
  if (names.isEmpty) return fallback;
  final entries = names.entries.toList()
    ..sort((a, b) {
      final count = b.value.compareTo(a.value);
      if (count != 0) return count;
      return a.key.length.compareTo(b.key.length);
    });
  return entries.first.key;
}

double _weightedAverage(
  double? current,
  double value,
  int currentCount,
  int nextCount,
) {
  if (current == null || currentCount == 0) return value;
  return ((current * currentCount) + value) / nextCount;
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0088;
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degree) => degree * math.pi / 180;

String rangeChange(JsonMap drive) {
  final start = asDouble(drive['start_rated_range_km']);
  final end = asDouble(drive['end_rated_range_km']);
  if (start == null || end == null) return '--';
  return '${start.toStringAsFixed(0)}→${end.toStringAsFixed(0)} km';
}

String rangeLossText(JsonMap? drive) {
  final loss = ratedRangeLoss(drive);
  if (loss == null) return '--';
  return '${loss.toStringAsFixed(1)} km';
}

String rangeAchievementText(JsonMap? drive) {
  final value = rangeAchievement(drive);
  if (value == null) return '--';
  return '${value.toStringAsFixed(1)}%';
}

String batteryChangeText(JsonMap? drive) {
  final start =
      asDouble(drive?['start_battery_level']) ??
      asDouble(drive?['start_usable_battery_level']);
  final end =
      asDouble(drive?['end_battery_level']) ??
      asDouble(drive?['end_usable_battery_level']);
  if (start == null || end == null) return '--';
  return '${start.toStringAsFixed(0)}%→${end.toStringAsFixed(0)}%';
}

String drivePointLabel(JsonMap drive, String side) {
  final name = textValue(drive['${side}_name'], fallback: '');
  if (name.isNotEmpty) return name;
  return side == 'start' ? '起点位置' : '终点位置';
}
