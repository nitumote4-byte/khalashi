import 'package:flutter/material.dart';

import '../models/meeting_point.dart';
import '../theme/khalashi_theme.dart';

/// Tappable row that opens the map pin picker (not a free-text field).
class MeetingPointField extends StatelessWidget {
  const MeetingPointField({
    super.key,
    required this.label,
    required this.helperText,
    required this.emptyHint,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String helperText;
  final String emptyHint;
  final MeetingPoint? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                helperText: helperText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: hasValue && onClear != null
                    ? IconButton(
                        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                      )
                    : const Icon(Icons.map_outlined),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place,
                    size: 20,
                    color: hasValue
                        ? KhalashiColors.saffron
                        : KhalashiColors.dusk.withOpacity(0.45),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasValue ? value!.label : emptyHint,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: hasValue
                                ? KhalashiColors.dusk
                                : KhalashiColors.dusk.withOpacity(0.5),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
