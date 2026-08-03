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

class DriveRouteMap extends StatefulWidget {
  const DriveRouteMap({
    super.key,
    required this.points,
    required this.selectedIndex,
  });

  final List<JsonMap> points;
  final int selectedIndex;

  @override
  State<DriveRouteMap> createState() => _DriveRouteMapState();
}

class _DriveRouteMapState extends State<DriveRouteMap> {
  AMapController? controller;
  String? approvalNumber;

  List<_RouteCoord> get coords {
    final result = <_RouteCoord>[];
    for (var index = 0; index < widget.points.length; index++) {
      final lat = asDouble(widget.points[index]['latitude']);
      final lon = asDouble(widget.points[index]['longitude']);
      if (lat == null || lon == null) continue;
      final coord = wgs84ToGcj02(lat, lon);
      result.add(_RouteCoord(index, LatLng(coord.latitude, coord.longitude)));
    }
    return result;
  }

  _RouteCoord? get selectedCoord {
    final all = coords;
    if (all.isEmpty) return null;
    final target = widget.selectedIndex.clamp(0, widget.points.length - 1);
    var nearest = all.first;
    var nearestDistance = (nearest.index - target).abs();
    for (final coord in all.skip(1)) {
      final distance = (coord.index - target).abs();
      if (distance < nearestDistance) {
        nearest = coord;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  @override
  void didUpdateWidget(covariant DriveRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      moveToSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = coords;
    if (all.length < 2) {
      return const Center(
        child: Text('暂无可用地图轨迹', style: TextStyle(color: muted)),
      );
    }

    final selected = selectedCoord ?? all.first;
    final bounds = _bounds(all);
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
              target: selected.latLng,
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
            markers: _markers(all, selected),
            polylines: {
              Polyline(
                points: all.map((coord) => coord.latLng).toList(),
                width: 5,
                color: cyan,
                capType: CapType.round,
                joinType: JoinType.round,
              ),
            },
            onMapCreated: (mapController) async {
              controller = mapController;
              await moveToBounds(bounds);
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
                _MapBadge(color: green, text: '起'),
                const SizedBox(width: 6),
                _MapBadge(color: red, text: '终'),
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

  Future<void> moveToSelected() async {
    final selected = selectedCoord;
    if (selected == null) return;
    await controller?.moveCamera(
      CameraUpdate.newLatLngZoom(selected.latLng, 16),
      animated: true,
      duration: 260,
    );
  }

  Future<void> moveToBounds(LatLngBounds bounds) async {
    await controller?.moveCamera(
      CameraUpdate.newLatLngBounds(bounds, 42),
      animated: false,
    );
  }

  LatLngBounds _bounds(List<_RouteCoord> all) {
    var minLat = all.first.latLng.latitude;
    var maxLat = all.first.latLng.latitude;
    var minLon = all.first.latLng.longitude;
    var maxLon = all.first.latLng.longitude;
    for (final coord in all.skip(1)) {
      minLat = math.min(minLat, coord.latLng.latitude);
      maxLat = math.max(maxLat, coord.latLng.latitude);
      minLon = math.min(minLon, coord.latLng.longitude);
      maxLon = math.max(maxLon, coord.latLng.longitude);
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

  Set<Marker> _markers(List<_RouteCoord> all, _RouteCoord selected) {
    return {
      Marker(
        position: all.first.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '起点'),
      ),
      Marker(
        position: all.last.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: '终点'),
      ),
      Marker(
        position: selected.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: '当前点',
          snippet: '轨迹点 ${selected.index + 1}',
        ),
        zIndex: 10,
      ),
    };
  }
}

class _RouteCoord {
  const _RouteCoord(this.index, this.latLng);

  final int index;
  final LatLng latLng;
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
