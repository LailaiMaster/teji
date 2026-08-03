import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../models/dashboard_data.dart';
import '../utils/dashboard_metrics.dart';
import '../widgets/home_dashboard.dart';
import '../widgets/shell.dart';
import 'battery_health_page.dart';
import 'calendar_page.dart';
import 'charge_records_page.dart';
import 'drive_records_page.dart';
import 'drive_detail_page.dart';
import 'insights_page.dart';
import 'month_drives_page.dart';
import 'reports_page.dart';
import 'route_pk_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.apiBaseUrl,
    required this.onSaveApiBaseUrl,
  });

  final String apiBaseUrl;
  final Future<void> Function(String value) onSaveApiBaseUrl;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardData> _future;
  int? _selectedCarId;
  int _loadToken = 0;
  List<JsonMap> _drives = const [];
  List<JsonMap> _charges = const [];

  TejiApi get api => TejiApi(widget.apiBaseUrl);

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiBaseUrl != widget.apiBaseUrl) {
      _startLoading();
    }
  }

  void _startLoading() {
    final token = ++_loadToken;
    _drives = const [];
    _charges = const [];
    _future = _loadOverview();
    _loadHistory(token);
  }

  Future<DashboardData> _loadOverview() async {
    final overview = await api.overview();
    return DashboardData(
      cars: (overview['cars'] as List? ?? []).whereType<JsonMap>().toList(),
      drives: const [],
      charges: const [],
    );
  }

  Future<void> _loadHistory(int token) async {
    try {
      final results = await Future.wait([
        api.drives(limit: 200),
        api.chargingProcesses(limit: 120),
      ]);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _drives = results[0];
        _charges = results[1];
      });
    } on Object {
      // Keep the overview usable even if the heavier history query is slow.
    }
  }

  Future<void> _refresh() async {
    final token = ++_loadToken;
    setState(() {
      _drives = const [];
      _charges = const [];
      _future = _loadOverview();
    });
    _loadHistory(token);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FuturePane<DashboardData>(
      future: _future,
      onRefresh: _refresh,
      errorAction: FilledButton.icon(
        onPressed: () => openSettings(const []),
        icon: const Icon(Icons.settings),
        label: const Text('配置数据服务'),
      ),
      builder: (context, data) {
        final car = selectedCar(data.cars);
        final carId = asInt(car?['id']);
        final drives = rowsForCar(_drives, carId);
        final charges = rowsForCar(_charges, carId);
        final latestDrive = drives.isEmpty
            ? overviewLatestDrive(car)
            : drives.first;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              SafeArea(
                bottom: false,
                child: TopBar(
                  title: '特迹',
                  subtitle:
                      '私有车辆数据台 · ${textValue(car?['name'], fallback: '车辆')}',
                  onSettings: () => openSettings(data.cars),
                ),
              ),
              const SizedBox(height: 14),
              if (car != null) StatusHero(car: car, latestDrive: latestDrive),
              const SizedBox(height: 8),
              ModuleGrid(
                onDrive: () => push(DriveRecordsPage(api: api, carId: carId)),
                onCharge: () => push(ChargeRecordsPage(api: api, carId: carId)),
                onHealth: () =>
                    push(BatteryHealthPage(car: car, drives: drives)),
                onCalendar: () => push(
                  CalendarPage(api: api, drives: drives, charges: charges),
                ),
              ),
              const SizedBox(height: 14),
              if (latestDrive != null)
                LatestDrivePanel(
                  drive: latestDrive,
                  onTap: () => push(
                    DriveDetailPage(
                      api: api,
                      driveId: asInt(latestDrive['id'])!,
                    ),
                  ),
                ),
              if (latestDrive != null) const SizedBox(height: 14),
              TodayPanel(car: car, latestDrive: latestDrive),
              const SizedBox(height: 14),
              InsightsPanel(
                drives: drives,
                charges: charges,
                onAchievementTap: () => push(
                  InsightsPage(
                    api: api,
                    mode: InsightMode.achievement,
                    drives: drives,
                    charges: charges,
                  ),
                ),
                onPeakTap: () => push(
                  InsightsPage(
                    api: api,
                    mode: InsightMode.peak,
                    drives: drives,
                    charges: charges,
                  ),
                ),
                onRouteTap: () => push(
                  InsightsPage(
                    api: api,
                    mode: InsightMode.route,
                    drives: drives,
                    charges: charges,
                  ),
                ),
                onRoutePkTap: () => push(RoutePkPage(api: api, drives: drives)),
                onReportTap: () => push(
                  ReportsPage(api: api, drives: drives, charges: charges),
                ),
              ),
              const SizedBox(height: 14),
              MonthlyMileagePanel(
                drives: drives,
                onMonthTap: (month) => push(
                  MonthDrivesPage(api: api, month: month.month, drives: drives),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  JsonMap? selectedCar(List<JsonMap> cars) {
    if (cars.isEmpty) return null;
    if (_selectedCarId != null) {
      for (final car in cars) {
        if (asInt(car['id']) == _selectedCarId) return car;
      }
    }
    final sorted = [...cars]
      ..sort((a, b) {
        final at = DateTime.tryParse(
          textValue(a['position_time'], fallback: ''),
        );
        final bt = DateTime.tryParse(
          textValue(b['position_time'], fallback: ''),
        );
        return (bt ?? DateTime(1970)).compareTo(at ?? DateTime(1970));
      });
    _selectedCarId = asInt(sorted.first['id']);
    return sorted.first;
  }

  void push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> openSettings(List<JsonMap> cars) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          apiBaseUrl: widget.apiBaseUrl,
          onSave: widget.onSaveApiBaseUrl,
          cars: cars,
          selectedCarId: _selectedCarId,
          onSelectCar: (id) => setState(() => _selectedCarId = id),
        ),
      ),
    );
    setState(() => _future = _loadOverview());
    _loadHistory(++_loadToken);
  }
}

JsonMap? overviewLatestDrive(JsonMap? car) {
  final id = asInt(car?['last_drive_id']);
  if (car == null || id == null) return null;
  return {
    'id': id,
    'car_id': asInt(car['id']),
    'start_date': car['last_drive_start'],
    'end_date': car['last_drive_end'],
    'distance': car['last_drive_distance_km'],
    'duration_min': car['last_drive_duration_min'],
    'speed_max': car['last_drive_speed_max'],
    'start_name': car['last_drive_start_name'],
    'end_name': car['last_drive_end_name'],
  };
}
