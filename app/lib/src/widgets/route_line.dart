import 'package:flutter/material.dart';

import '../formatters.dart';
import '../theme/app_style.dart';

class RouteLine extends StatelessWidget {
  const RouteLine({super.key, required this.start, required this.end});

  final Object? start;
  final Object? end;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Address(
            label: '起点',
            value: textValue(start, fallback: '未知地点'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward, color: blue, size: 22),
        ),
        Expanded(
          child: Address(
            label: '终点',
            value: textValue(end, fallback: '未知地点'),
          ),
        ),
      ],
    );
  }
}

class Address extends StatelessWidget {
  const Address({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
