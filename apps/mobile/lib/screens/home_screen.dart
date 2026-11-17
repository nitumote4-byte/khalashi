import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import 'phone_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  Future<void> _logout(BuildContext context) async {
    await sessionStore.clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PhoneScreen(sessionStore: sessionStore),
      ),
      (_) => false,
    );
  }

  void _stub(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KhalashiColors.mist, KhalashiColors.sand],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.appName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: KhalashiColors.deepTeal,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.logout,
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.homeGreeting,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.cashReminder,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KhalashiColors.dusk.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 32),
                _HubAction(
                  title: l10n.findRide,
                  subtitle: l10n.findRideSubtitle,
                  icon: Icons.search,
                  onTap: () => _stub(context, l10n.comingSoonFind),
                ),
                const SizedBox(height: 16),
                _HubAction(
                  title: l10n.offerRide,
                  subtitle: l10n.offerRideSubtitle,
                  icon: Icons.directions_car_filled_outlined,
                  onTap: () => _stub(context, l10n.comingSoonOffer),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => _stub(context, l10n.stubComingSoon),
                      child: Text(l10n.myBookings),
                    ),
                    TextButton(
                      onPressed: () => _stub(context, l10n.stubComingSoon),
                      child: Text(l10n.myTrips),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubAction extends StatelessWidget {
  const _HubAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36, color: KhalashiColors.saffron),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: KhalashiColors.deepTeal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
