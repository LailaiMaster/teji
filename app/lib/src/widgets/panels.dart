import 'package:flutter/material.dart';

import '../theme/app_style.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: panel,
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PanelTitle extends StatelessWidget {
  const PanelTitle({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(color: muted, fontSize: 12)),
        if (onTap != null)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.chevron_right, color: muted, size: 16),
          ),
      ],
    );
    return onTap == null
        ? row
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: row,
          );
  }
}

class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.items});

  final List<MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == items.length - 1 ? 0 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        items[index].value,
                        maxLines: 1,
                        style: TextStyle(
                          color: items[index].color,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class MetricItem {
  const MetricItem(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class DistancePill extends StatelessWidget {
  const DistancePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: blue.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
