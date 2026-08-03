import '../api.dart';

class DashboardData {
  const DashboardData({
    required this.cars,
    required this.drives,
    required this.charges,
  });

  final List<JsonMap> cars;
  final List<JsonMap> drives;
  final List<JsonMap> charges;
}
