import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../theme/app_style.dart';

class CarSelector extends StatelessWidget {
  const CarSelector({
    super.key,
    required this.cars,
    required this.selectedId,
    required this.onSelected,
  });

  final List<JsonMap> cars;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (cars.isEmpty) {
      return const Text('暂无车辆', style: TextStyle(color: muted));
    }
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cars.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final car = cars[index];
          final id = asInt(car['id']);
          final selected = id == selectedId;
          return GestureDetector(
            onTap: id == null ? null : () => onSelected(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? blue : panel2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? blue : line),
              ),
              child: Text(
                textValue(car['name']),
                style: TextStyle(
                  color: selected ? Colors.white : muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
