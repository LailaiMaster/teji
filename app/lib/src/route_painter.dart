import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'api.dart';
import 'formatters.dart';

class RouteSketch extends StatelessWidget {
  const RouteSketch({
    super.key,
    required this.points,
    this.selectedIndex = 0,
    this.aspectRatio = 16 / 9,
  });

  final List<JsonMap> points;
  final int selectedIndex;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomPaint(
        painter: RouteSketchPainter(
          points: points,
          color: color,
          selectedIndex: selectedIndex,
        ),
        child: points.length < 2
            ? const Center(child: Text('暂无路线点'))
            : const SizedBox.expand(),
      ),
    );
  }
}

class RouteSketchPainter extends CustomPainter {
  RouteSketchPainter({
    required this.points,
    required this.color,
    required this.selectedIndex,
  });

  final List<JsonMap> points;
  final Color color;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final coords = <({int index, double lat, double lon})>[];
    for (var index = 0; index < points.length; index++) {
      final lat = asDouble(points[index]['latitude']);
      final lon = asDouble(points[index]['longitude']);
      if (lat == null || lon == null) continue;
      coords.add((index: index, lat: lat, lon: lon));
    }

    final background = Paint()..color = const Color(0xFF101722);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      background,
    );

    if (coords.length < 2) return;

    final minLat = coords.map((point) => point.lat).reduce(math.min);
    final maxLat = coords.map((point) => point.lat).reduce(math.max);
    final minLon = coords.map((point) => point.lon).reduce(math.min);
    final maxLon = coords.map((point) => point.lon).reduce(math.max);
    final latSpan = math.max(maxLat - minLat, 0.00001);
    final lonSpan = math.max(maxLon - minLon, 0.00001);
    final padding = math.min(size.width, size.height) * 0.1;
    final drawSize = Size(size.width - padding * 2, size.height - padding * 2);

    Offset project(({int index, double lat, double lon}) point) {
      final x = padding + ((point.lon - minLon) / lonSpan) * drawSize.width;
      final y =
          padding + (1 - ((point.lat - minLat) / latSpan)) * drawSize.height;
      return Offset(x, y);
    }

    final path = Path()
      ..moveTo(project(coords.first).dx, project(coords.first).dy);
    for (final point in coords.skip(1)) {
      path.lineTo(project(point).dx, project(point).dy);
    }

    final grid = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final shadow = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, line);

    final start = project(coords.first);
    final end = project(coords.last);
    canvas.drawCircle(start, 5, Paint()..color = const Color(0xFF1B7F5A));
    canvas.drawCircle(end, 5, Paint()..color = const Color(0xFFC4472D));

    final current = _nearestSelectedCoord(coords);
    if (current != null) {
      final currentOffset = project(current);
      canvas.drawCircle(
        currentOffset,
        22,
        Paint()..color = color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        currentOffset,
        15,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92),
      );
      canvas.drawCircle(
        currentOffset,
        10,
        Paint()..color = const Color(0xFF111722),
      );
      canvas.drawCircle(currentOffset, 6, Paint()..color = color);

      final pointer = Path()
        ..moveTo(currentOffset.dx, currentOffset.dy - 25)
        ..lineTo(currentOffset.dx - 7, currentOffset.dy - 11)
        ..lineTo(currentOffset.dx + 7, currentOffset.dy - 11)
        ..close();
      canvas.drawPath(pointer, Paint()..color = const Color(0xFF111722));
      canvas.drawPath(pointer, Paint()..color = color);
    }
  }

  ({int index, double lat, double lon})? _nearestSelectedCoord(
    List<({int index, double lat, double lon})> coords,
  ) {
    if (coords.isEmpty) return null;
    final target = selectedIndex.clamp(0, points.length - 1);
    var nearest = coords.first;
    var nearestDistance = (nearest.index - target).abs();
    for (final coord in coords.skip(1)) {
      final distance = (coord.index - target).abs();
      if (distance < nearestDistance) {
        nearest = coord;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  @override
  bool shouldRepaint(covariant RouteSketchPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
