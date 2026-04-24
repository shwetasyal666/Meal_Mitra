import 'package:flutter/material.dart';
import 'package:mealmitra/app/theme/app_theme.dart';

class CircularCalorieIndicator extends StatelessWidget {
  final int consumed;
  final int target;

  const CircularCalorieIndicator({
    super.key,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = target - consumed;
    final progress = (consumed / target).clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 14,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primaryGreen,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ENERGY BALANCE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.grey.shade500,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      remaining.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},'),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 48,
                            height: 1,
                          ),
                    ),
                    Text(
                      ' / $target',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
                Text(
                  'kcal remaining',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
