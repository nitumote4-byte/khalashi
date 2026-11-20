import 'package:flutter/material.dart';

import '../theme/khalashi_theme.dart';

/// Compact average stars + optional count for trip cards / profile.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.avg,
    required this.count,
    this.compact = false,
  });

  final double avg;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = compact
        ? avg.toStringAsFixed(1)
        : '${avg.toStringAsFixed(1)} ($count)';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: compact ? 16 : 18,
          color: KhalashiColors.deepTeal,
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: KhalashiColors.dusk,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Interactive 1–5 star picker.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return IconButton(
          onPressed: () => onChanged(star),
          iconSize: 36,
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? KhalashiColors.deepTeal : KhalashiColors.dusk.withOpacity(0.4),
          ),
        );
      }),
    );
  }
}
