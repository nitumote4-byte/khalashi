import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/support_contacts.dart';
import '../l10n/app_localizations.dart';
import '../theme/khalashi_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, this.bookingRef});

  final String? bookingRef;

  Future<void> _copy(BuildContext context, String value, String snack) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final waHint = bookingRef == null || bookingRef!.isEmpty
        ? SupportContacts.whatsappDisplay
        : '${SupportContacts.whatsappDisplay} · ref $bookingRef';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(l10n.cashHowTitle, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.cashHowBody),
          const SizedBox(height: 20),
          Text(l10n.seatPrefHelpTitle, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.seatPrefHelpBody),
          const SizedBox(height: 20),
          Text(l10n.cancelHelpTitle, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.cancelHelpBody),
          const SizedBox(height: 24),
          Text(l10n.safetyTipsTitle, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.safetyTip1),
          Text(l10n.safetyTip2),
          Text(l10n.safetyTip3),
          Text(l10n.safetyTip4),
          Text(l10n.safetyTip5),
          Text(l10n.safetyTip6),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KhalashiColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(l10n.emergencyLine),
          ),
          const SizedBox(height: 24),
          Text(l10n.disclaimerTitle, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.disclaimerBody),
          const SizedBox(height: 8),
          Text(
            l10n.operatorLine,
            style: textTheme.bodySmall?.copyWith(
              color: KhalashiColors.dusk.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.supportTitle, style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.supportHours,
            style: textTheme.bodySmall?.copyWith(
              color: KhalashiColors.dusk.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.chat_outlined, color: KhalashiColors.deepTeal),
            title: Text(l10n.supportWhatsApp),
            subtitle: Text(waHint),
            trailing: IconButton(
              tooltip: l10n.copyWhatsApp,
              icon: const Icon(Icons.copy),
              onPressed: () => _copy(
                context,
                SupportContacts.whatsappDisplay,
                l10n.copied,
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_outlined, color: KhalashiColors.deepTeal),
            title: Text(l10n.supportPhone),
            subtitle: Text(SupportContacts.phoneDisplay),
            trailing: IconButton(
              tooltip: l10n.copyPhone,
              icon: const Icon(Icons.copy),
              onPressed: () => _copy(
                context,
                SupportContacts.phoneDisplay,
                l10n.copied,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supportStubNote,
            style: textTheme.bodySmall?.copyWith(
              color: KhalashiColors.dusk.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
