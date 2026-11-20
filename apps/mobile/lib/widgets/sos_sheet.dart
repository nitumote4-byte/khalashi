import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../theme/khalashi_theme.dart';
import '../utils/format.dart';

/// Soft-launch SOS: call contact, share trip summary, optional 112.
Future<void> showSosSheet({
  required BuildContext context,
  required ApiClient api,
  required String tripId,
  String? bookingId,
  required String origin,
  required String destination,
  required DateTime departAt,
  String? pickupPoint,
  String? dropoffPoint,
  String? counterpartPhone,
  String? counterpartLabel,
  UserProfile? profile,
}) async {
  final l10n = AppLocalizations.of(context);

  Future<void> audit(String action) async {
    try {
      await api.logSos(tripId: tripId, bookingId: bookingId, action: action);
    } catch (_) {
      /* audit best-effort */
    }
  }

  // Fire-and-forget open audit; UI still works offline.
  // ignore: unawaited_futures
  audit('pressed');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sosTitle,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sosSubtitle,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: KhalashiColors.dusk.withOpacity(0.85),
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () async {
                  final phone = profile?.emergencyContactPhone;
                  if (phone == null || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.sosNoContact)),
                    );
                    return;
                  }
                  // ignore: unawaited_futures
                  audit('call_contact');
                  await _dial(context, phone, l10n);
                },
                icon: const Icon(Icons.phone),
                label: Text(
                  profile?.hasEmergencyContact == true
                      ? l10n.sosCallContactNamed(profile!.emergencyContactName!)
                      : l10n.sosCallContact,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  // ignore: unawaited_futures
                  audit('share');
                  final text = _buildShareText(
                    l10n: l10n,
                    origin: origin,
                    destination: destination,
                    departAt: departAt,
                    pickupPoint: pickupPoint,
                    dropoffPoint: dropoffPoint,
                    counterpartPhone: counterpartPhone,
                    counterpartLabel: counterpartLabel,
                    tripId: tripId,
                  );
                  await Share.share(text, subject: l10n.sosShareSubject);
                },
                icon: const Icon(Icons.share),
                label: Text(l10n.sosShareTrip),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  // ignore: unawaited_futures
                  audit('call_112');
                  await _dial(context, '112', l10n);
                },
                icon: Icon(Icons.emergency, color: Colors.red.shade700),
                label: Text(l10n.sosCall112),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sosDisclaimer,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: KhalashiColors.dusk.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _buildShareText({
  required AppLocalizations l10n,
  required String origin,
  required String destination,
  required DateTime departAt,
  String? pickupPoint,
  String? dropoffPoint,
  String? counterpartPhone,
  String? counterpartLabel,
  required String tripId,
}) {
  final buf = StringBuffer()
    ..writeln(l10n.sosShareHeadline)
    ..writeln('$origin → $destination')
    ..writeln(formatDateTime(departAt));
  if (pickupPoint != null && pickupPoint.isNotEmpty) {
    buf.writeln('${l10n.pickupPoint}: $pickupPoint');
  }
  if (dropoffPoint != null && dropoffPoint.isNotEmpty) {
    buf.writeln('${l10n.dropoffPoint}: $dropoffPoint');
  }
  if (counterpartPhone != null && counterpartPhone.isNotEmpty) {
    final label = counterpartLabel ?? l10n.phoneTitle;
    buf.writeln('$label: $counterpartPhone');
  }
  buf
    ..writeln()
    ..writeln('${ApiConfig.baseUrl}/public/trips/$tripId')
    ..writeln(l10n.sosShareFooter);
  return buf.toString();
}

Future<void> _dial(BuildContext context, String phone, AppLocalizations l10n) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final uri = Uri(scheme: 'tel', path: digits);
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.supportOpenFailed)),
    );
  }
}

/// Prominent SOS control for active trip / booking screens.
class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.emergency),
      label: Text(l10n.sosButton),
    );
  }
}
