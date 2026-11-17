import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import 'phone_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({
    super.key,
    required this.onLocaleChanged,
    required this.sessionStore,
  });

  final ValueChanged<Locale> onLocaleChanged;
  final SessionStore sessionStore;

  Future<void> _pick(BuildContext context, String code) async {
    await sessionStore.saveLanguage(code);
    onLocaleChanged(Locale(code));
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PhoneScreen(sessionStore: sessionStore),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KhalashiColors.mist, KhalashiColors.sand],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: KhalashiColors.deepTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tagline,
                  style: const TextStyle(color: KhalashiColors.dusk),
                ),
                const Spacer(),
                Text(
                  l10n.languageTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _pick(context, 'hi'),
                  child: Text(l10n.languageHindi),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _pick(context, 'en'),
                  child: Text(l10n.languageEnglish),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
