import 'dart:math' as math;

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/dashboard_metrics.dart';
import '../utils/geo_transform.dart';
import '../widgets/panels.dart';
import '../widgets/shell.dart';

class MonthHeatMapPage extends StatelessWidget {
  const MonthHeatMapPage({
    super.key,
    required this.month,
    required this.drives,
  });

  final DateTime month;
  final List<JsonMap> drives;

  @override
  Widget build(BuildContext context) {
    final points = _heatPoints(drives);
    final hotspots = _hotspots(drives);
    return PageShell(
      title: '${DateFormat('yyyy-MM').format(month)} 热力',
      subtitle: '${drives.length} 条行程 · 起终点分布',
      children: [
        Panel(
          padding: const EdgeInsets.all(12),
          child: SizedBox(height: 360, child: MonthHeatMap(points: points)),
        ),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(
                icon: Icons.local_fire_department,
                color: amber,
                title: '热点位置',
              ),
              const SizedBox(height: 12),
              if (hotspots.isEmpty)
                const Text('暂无地点数据', style: TextStyle(color: muted))
              else
                for (final item in hotspots.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: text,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${item.count} 次',
                          style: const TextStyle(
                            color: cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class MonthHeatMap extends StatelessWidget {
  const MonthHeatMap({super.key, required this.points});

  final List<HeatPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('暂无可用地图点位', style: TextStyle(color: muted)),
      );
    }
    final bounds = _bounds(points);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AMapWidget(
        privacyStatement: const AMapPrivacyStatement(
          hasContains: true,
          hasShow: true,
          hasAgree: true,
        ),
        initialCameraPosition: CameraPosition(
          target: points.first.latLng,
          zoom: _initialZoom(bounds),
        ),
        scaleEnabled: true,
        compassEnabled: false,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: false,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
        markers: {
          for (final point in points)
            Marker(
              position: point.latLng,
              alpha: point.isStart ? 0.78 : 0.52,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                point.isStart
                    ? BitmapDescriptor.hueAzure
                    : BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: point.name,
                snippet: point.isStart ? '起点' : '终点',
              ),
            ),
        },
        onMapCreated: (controller) {
          controller.moveCamera(
            CameraUpdate.newLatLngBounds(bounds, 42),
            animated: false,
          );
        },
      ),
    );
  }

  LatLngBounds _bounds(List<HeatPoint> points) {
    var minLat = points.first.latLng.latitude;
    var maxLat = points.first.latLng.latitude;
    var minLon = points.first.latLng.longitude;
    var maxLon = points.first.latLng.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latLng.latitude);
      maxLat = math.max(maxLat, point.latLng.latitude);
      minLon = math.min(minLon, point.latLng.longitude);
      maxLon = math.max(maxLon, point.latLng.longitude);
    }
    const minSpan = 0.003;
    final latPad = math.max((maxLat - minLat) * 0.18, minSpan);
    final lonPad = math.max((maxLon - minLon) * 0.18, minSpan);
    return LatLngBounds(
      southwest: LatLng(minLat - latPad, minLon - lonPad),
      northeast: LatLng(maxLat + latPad, maxLon + lonPad),
    );
  }

  double _initialZoom(LatLngBounds bounds) {
    final span = math.max(
      (bounds.northeast.latitude - bounds.southwest.latitude).abs(),
      (bounds.northeast.longitude - bounds.southwest.longitude).abs(),
    );
    if (span < 0.01) return 15.5;
    if (span < 0.04) return 13.8;
    if (span < 0.1) return 12.5;
    return 11;
  }
}

class HeatPoint {
  const HeatPoint({
    required this.latLng,
    required this.name,
    required this.isStart,
  });

  final LatLng latLng;
  final String name;
  final bool isStart;
}

class Hotspot {
  const Hotspot(this.name, this.count);

  final String name;
  final int count;
}

List<HeatPoint> _heatPoints(List<JsonMap> drives) {
  final points = <HeatPoint>[];
  for (final drive in drives) {
    _addPoint(points, drive, side: 'start', isStart: true);
    _addPoint(points, drive, side: 'end', isStart: false);
  }
  return points;
}

void _addPoint(
  List<HeatPoint> points,
  JsonMap drive, {
  required String side,
  required bool isStart,
}) {
  final lat = asDouble(drive['${side}_latitude']);
  final lon = asDouble(drive['${side}_longitude']);
  if (lat == null || lon == null) return;
  final coord = wgs84ToGcj02(lat, lon);
  points.add(
    HeatPoint(
      latLng: LatLng(coord.latitude, coord.longitude),
      name: drivePointLabel(drive, side),
      isStart: isStart,
    ),
  );
}

List<Hotspot> _hotspots(List<JsonMap> drives) {
  final counts = <String, int>{};
  for (final drive in drives) {
    for (final side in ['start', 'end']) {
      final name = drivePointLabel(drive, side);
      if (name == '起点位置' || name == '终点位置') continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  final items =
      counts.entries.map((entry) => Hotspot(entry.key, entry.value)).toList()
        ..sort((a, b) => b.count.compareTo(a.count));
  return items;
}
