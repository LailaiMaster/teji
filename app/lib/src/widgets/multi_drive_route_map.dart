import 'dart:math' as math;

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';
import '../utils/geo_transform.dart';

class MultiDriveRouteMap extends StatefulWidget {
  const MultiDriveRouteMap({super.key, required this.routes});

  final List<List<JsonMap>> routes;

  @override
  State<MultiDriveRouteMap> createState() => _MultiDriveRouteMapState();
}

class _MultiDriveRouteMapState extends State<MultiDriveRouteMap> {
  AMapController? controller;
  String? approvalNumber;

  List<List<LatLng>> get routeCoords {
    return widget.routes
        .map((route) {
          return route
              .map((point) {
                final lat = asDouble(point['latitude']);
                final lon = asDouble(point['longitude']);
                if (lat == null || lon == null) return null;
                final coord = wgs84ToGcj02(lat, lon);
                return LatLng(coord.latitude, coord.longitude);
              })
              .whereType<LatLng>()
              .toList(growable: false);
        })
        .where((route) => route.length > 1)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final routes = routeCoords;
    if (routes.isEmpty) {
      return const Center(
        child: Text('暂无可用地图轨迹', style: TextStyle(color: muted)),
      );
    }

    final bounds = _bounds(routes);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AMapWidget(
            privacyStatement: const AMapPrivacyStatement(
              hasContains: true,
              hasShow: true,
              hasAgree: true,
            ),
            initialCameraPosition: CameraPosition(
              target: routes.first.first,
              zoom: _initialZoom(bounds),
            ),
            scaleEnabled: true,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            markers: _markers(routes.first),
            polylines: _polylines(routes),
            onMapCreated: (mapController) async {
              controller = mapController;
              await mapController.moveCamera(
                CameraUpdate.newLatLngBounds(bounds, 42),
                animated: false,
              );
              final number = await mapController.getMapContentApprovalNumber();
              if (mounted && textValue(number, fallback: '').isNotEmpty) {
                setState(() => approvalNumber = number);
              }
            },
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Row(
              children: [
                _MapBadge(color: cyan, text: '${routes.length} 条轨迹'),
                const Spacer(),
                if (approvalNumber != null)
                  Text(
                    approvalNumber!,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Set<Polyline> _polylines(List<List<LatLng>> routes) {
    const colors = [cyan, blue, green, amber, purple, red];
    return {
      for (var index = 0; index < routes.length; index++)
        Polyline(
          points: routes[index],
          width: index == 0 ? 5 : 3,
          alpha: index == 0 ? 0.9 : 0.42,
          color: colors[index % colors.length],
          capType: CapType.round,
          joinType: JoinType.round,
        ),
    };
  }

  Set<Marker> _markers(List<LatLng> route) {
    return {
      Marker(
        position: route.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '起点'),
      ),
      Marker(
        position: route.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: '终点'),
      ),
    };
  }

  LatLngBounds _bounds(List<List<LatLng>> routes) {
    final points = routes.expand((route) => route).toList(growable: false);
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }
    const minSpan = 0.002;
    final latPad = math.max((maxLat - minLat) * 0.18, minSpan);
    final lonPad = math.max((maxLon - minLon) * 0.18, minSpan);
    return LatLngBounds(
      southwest: LatLng(minLat - latPad, minLon - lonPad),
      northeast: LatLng(maxLat + latPad, maxLon + lonPad),
    );
  }

  double _initialZoom(LatLngBounds bounds) {
    final latSpan = (bounds.northeast.latitude - bounds.southwest.latitude)
        .abs();
    final lonSpan = (bounds.northeast.longitude - bounds.southwest.longitude)
        .abs();
    final span = math.max(latSpan, lonSpan);
    if (span < 0.01) return 15.5;
    if (span < 0.03) return 14;
    if (span < 0.08) return 12.5;
    return 11;
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
