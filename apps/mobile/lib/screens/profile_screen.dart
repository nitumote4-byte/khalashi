import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../locale_scope.dart';
import '../models/verification.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../widgets/verification_badge.dart';
import 'help_screen.dart';
import 'phone_screen.dart';
import 'verify_id_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  VerificationStatus _status = VerificationStatus.unverified;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _api.getVerificationStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (_) {
      /* keep last */
    }
  }

  Future<void> _setLanguage(BuildContext context, String code) async {
    await widget.sessionStore.saveLanguage(code);
    LocaleScope.of(context).setLocale(Locale(code));
  }

  Future<void> _logout(BuildContext context) async {
    await widget.sessionStore.clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PhoneScreen(sessionStore: widget.sessionStore),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          FutureBuilder<String?>(
            future: widget.sessionStore.getPhone(),
            builder: (context, snap) {
              final phone = snap.data;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.phoneTitle),
                subtitle: Text(
                  phone == null || phone.isEmpty
                      ? '—'
                      : phone.startsWith('+')
                          ? phone
                          : '+91 $phone',
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_outlined, color: KhalashiColors.deepTeal),
            title: Text(l10n.verifyIdTitle),
            subtitle: VerificationBadge(status: _status),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      VerifyIdScreen(sessionStore: widget.sessionStore),
                ),
              );
              await _refreshStatus();
            },
          ),
          const Divider(),
          Text(l10n.languageTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'hi', label: Text(l10n.languageHindi)),
              ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
            ],
            selected: {locale == 'hi' ? 'hi' : 'en'},
            onSelectionChanged: (set) {
              final code = set.first;
              _setLanguage(context, code);
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.cashReminder,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KhalashiColors.dusk.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline, color: KhalashiColors.deepTeal),
            title: Text(l10n.helpTitle),
            subtitle: Text(l10n.helpSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => _logout(context),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
