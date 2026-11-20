import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../locale_scope.dart';
import '../models/user_profile.dart';
import '../models/verification.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../widgets/star_rating.dart';
import '../widgets/verification_badge.dart';
import 'blocked_users_screen.dart';
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
  UserProfile? _profile;
  bool _loadingProfile = true;

  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  bool _savingContact = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _loadProfile();
  }

  @override
  void dispose() {
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
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

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final profile = await _api.getMe();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _contactNameCtrl.text = profile.emergencyContactName ?? '';
        final phone = profile.emergencyContactPhone ?? '';
        _contactPhoneCtrl.text = phone.startsWith('+91') && phone.length == 13
            ? phone.substring(3)
            : phone.replaceFirst(RegExp(r'^\+'), '');
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _saveEmergencyContact() async {
    final l10n = AppLocalizations.of(context);
    final name = _contactNameCtrl.text.trim();
    final phoneRaw = _contactPhoneCtrl.text.trim();

    if (name.isEmpty && phoneRaw.isEmpty) {
      // Clear
    } else if (name.isEmpty || phoneRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.emergencyContactNeedBoth)),
      );
      return;
    } else if (!RegExp(r'^\d{10}$').hasMatch(phoneRaw.replaceAll(RegExp(r'\D'), '')) &&
        !RegExp(r'^\+?\d{10,15}$').hasMatch(phoneRaw.replaceAll(RegExp(r'\s'), ''))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.emergencyContactInvalidPhone)),
      );
      return;
    }

    setState(() => _savingContact = true);
    try {
      final digits = phoneRaw.replaceAll(RegExp(r'\D'), '');
      final updated = await _api.updateEmergencyContact(
        name: name.isEmpty ? null : name,
        phone: phoneRaw.isEmpty
            ? null
            : (digits.length == 10 ? digits : phoneRaw),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.hasEmergencyContact
                ? l10n.emergencyContactSaved
                : l10n.emergencyContactCleared,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingContact = false);
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
          if (_profile?.hasRating == true) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(l10n.yourRating, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                RatingBadge(
                  avg: _profile!.ratingAvg,
                  count: _profile!.ratingCount,
                ),
              ],
            ),
          ],
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.block, color: KhalashiColors.deepTeal),
            title: Text(l10n.blockedUsersTitle),
            subtitle: Text(l10n.blockedUsersSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BlockedUsersScreen(sessionStore: widget.sessionStore),
                ),
              );
            },
          ),
          const Divider(),
          Text(l10n.emergencyContactTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.emergencyContactSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KhalashiColors.dusk.withOpacity(0.75),
                ),
          ),
          const SizedBox(height: 12),
          if (_loadingProfile)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            TextField(
              controller: _contactNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.emergencyContactName,
                hintText: l10n.emergencyContactNameHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.emergencyContactPhone,
                hintText: l10n.phoneHint,
                prefixText: '+91 ',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _savingContact ? null : _saveEmergencyContact,
              child: Text(
                _savingContact ? l10n.emergencyContactSaving : l10n.emergencyContactSave,
              ),
            ),
            if (_profile?.hasEmergencyContact == true)
              TextButton(
                onPressed: _savingContact
                    ? null
                    : () {
                        _contactNameCtrl.clear();
                        _contactPhoneCtrl.clear();
                        _saveEmergencyContact();
                      },
                child: Text(l10n.emergencyContactClear),
              ),
          ],
          const Divider(height: 32),
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
