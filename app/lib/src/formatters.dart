import 'package:intl/intl.dart';

String textValue(Object? value, {String fallback = '--'}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double? asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String km(Object? value, {int decimals = 1}) {
  final number = asDouble(value);
  if (number == null) return '-- km';
  return '${number.toStringAsFixed(decimals)} km';
}

String kwh(Object? value) {
  final number = asDouble(value);
  if (number == null) return '-- kWh';
  return '${number.toStringAsFixed(1)} kWh';
}

String percent(Object? value) {
  final number = asDouble(value);
  if (number == null) return '--%';
  return '${number.toStringAsFixed(0)}%';
}

String celsius(Object? value) {
  final number = asDouble(value);
  if (number == null) return '-- degC';
  return '${number.toStringAsFixed(1)} degC';
}

String minutes(Object? value) {
  final min = asInt(value);
  if (min == null) return '--';
  final hours = min ~/ 60;
  final rest = min % 60;
  if (hours == 0) return '$rest min';
  return '${hours}h ${rest}m';
}

String speed(Object? value) {
  final number = asDouble(value);
  if (number == null) return '-- km/h';
  return '${number.toStringAsFixed(0)} km/h';
}

String power(Object? value) {
  final number = asDouble(value);
  if (number == null) return '-- kW';
  return '${number.toStringAsFixed(0)} kW';
}

String dateTimeShort(Object? value) {
  if (value == null) return '--';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return DateFormat('MM-dd HH:mm').format(parsed);
}

String dateTimeFull(Object? value) {
  if (value == null) return '--';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(parsed);
}

String dateOnly(Object? value) {
  if (value == null) return '--';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return DateFormat('yyyy-MM-dd').format(parsed);
}
