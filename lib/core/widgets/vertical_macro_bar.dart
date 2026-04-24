import 'package:flutter/material.dart';

class VerticalMacroBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const VerticalMacroBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          width: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FractionallySizedBox(
                heightFactor: progress,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${current}g',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'Goal: ${target}g',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
        ),
      ],
    );
  }
}
