import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/verification.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../widgets/verification_badge.dart';
import 'my_bookings_screen.dart';
import 'my_trips_screen.dart';
import 'post_trip_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'verify_id_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  VerificationStatus _status = VerificationStatus.unverified;
  bool _statusLoaded = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _api.getVerificationStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _statusLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusLoaded = true);
    }
  }

  Future<void> _openOfferRide() async {
    final l10n = AppLocalizations.of(context);
    if (!_status.canOfferRide) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.verifyRequiredTitle),
          content: Text(l10n.verifyRequiredBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.verifyIdCta),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
      final result = await Navigator.of(context).push<VerificationInfo>(
        MaterialPageRoute<VerificationInfo>(
          builder: (_) => VerifyIdScreen(sessionStore: widget.sessionStore),
        ),
      );
      await _refreshStatus();
      if (!mounted) return;
      final next = result?.status ?? _status;
      if (!next.canOfferRide) return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostTripScreen(sessionStore: widget.sessionStore),
      ),
    );
    await _refreshStatus();
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
                    if (_statusLoaded)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: VerificationBadge(status: _status, compact: true),
                      ),
                    IconButton(
                      tooltip: l10n.profile,
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProfileScreen(sessionStore: widget.sessionStore),
                          ),
                        );
                        await _refreshStatus();
                      },
                      icon: const Icon(Icons.person_outline),
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SearchScreen(sessionStore: widget.sessionStore),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _HubAction(
                  title: l10n.offerRide,
                  subtitle: _status.canOfferRide
                      ? l10n.offerRideSubtitle
                      : l10n.offerRideNeedsVerify,
                  icon: Icons.directions_car_filled_outlined,
                  onTap: _openOfferRide,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                MyBookingsScreen(sessionStore: widget.sessionStore),
                          ),
                        );
                      },
                      child: Text(l10n.myBookings),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                MyTripsScreen(sessionStore: widget.sessionStore),
                          ),
                        );
                      },
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
