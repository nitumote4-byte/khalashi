import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/verification.dart';
import '../theme/khalashi_theme.dart';

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final VerificationStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color, icon) = switch (status) {
      VerificationStatus.verified => (
          l10n.verifyBadgeVerified,
          const Color(0xFF1B7A4E),
          Icons.verified,
        ),
      VerificationStatus.pendingReview => (
          l10n.verifyBadgePending,
          KhalashiColors.saffron,
          Icons.hourglass_top,
        ),
      VerificationStatus.rejected => (
          l10n.verifyBadgeRejected,
          const Color(0xFFB3261E),
          Icons.cancel_outlined,
        ),
      VerificationStatus.unverified => (
          l10n.verifyBadgeUnverified,
          KhalashiColors.dusk.withOpacity(0.7),
          Icons.badge_outlined,
        ),
    };

    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, size: 22, color: color),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
