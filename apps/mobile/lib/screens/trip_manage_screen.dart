import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../utils/format.dart';
import '../widgets/sos_sheet.dart';
import 'booking_detail_screen.dart';

class TripManageScreen extends StatefulWidget {
  const TripManageScreen({
    super.key,
    required this.sessionStore,
    required this.tripId,
    this.justPublished = false,
  });

  final SessionStore sessionStore;
  final String tripId;
  final bool justPublished;

  @override
  State<TripManageScreen> createState() => _TripManageScreenState();
}

class _TripManageScreenState extends State<TripManageScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  late Future<({Trip trip, List<Booking> bookings})> _future;
  bool _cancelling = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _future = _api.tripBookings(widget.tripId);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.getMe();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      /* SOS still works without contact */
    }
  }

  void _reload() {
    setState(() => _future = _api.tripBookings(widget.tripId));
  }

  Future<void> _openSos(Trip trip, List<Booking> bookings) async {
    final confirmed = bookings.where((b) => b.isConfirmed).toList();
    final phones = confirmed
        .map((b) => b.travellerPhone)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toList();
    await showSosSheet(
      context: context,
      api: _api,
      tripId: trip.id,
      origin: trip.origin,
      destination: trip.destination,
      departAt: trip.departAt,
      pickupPoint: trip.pickupPoint,
      dropoffPoint: trip.dropoffPoint,
      counterpartPhone: phones.isEmpty ? null : phones.join(', '),
      counterpartLabel: AppLocalizations.of(context).traveller,
      profile: _profile,
    );
  }

  Future<void> _cancelTrip(Trip trip) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelTrip),
        content: Text(l10n.cancelTripConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.keep)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirmCancel)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      await _api.cancelTrip(trip.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tripCancelled)));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.justPublished ? l10n.postSuccessTitle : l10n.tripManage),
      ),
      body: FutureBuilder<({Trip trip, List<Booking> bookings})>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snap.error.toString()),
                  OutlinedButton(onPressed: _reload, child: Text(l10n.retry)),
                ],
              ),
            );
          }
          final trip = snap.data!.trip;
          final bookings = snap.data!.bookings;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.justPublished) ...[
                Text(
                  l10n.postSuccessTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: KhalashiColors.deepTeal,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                '${trip.origin} → ${trip.destination}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(formatDateTime(trip.departAt)),
              Text(
                '${formatInr(trip.fareInr)}/seat · ${trip.seatsLeft}/${trip.seatsTotal} left · ${trip.status}',
              ),
              Text(trip.vehicleSummary),
              if (trip.pickupPoint != null)
                Text('${l10n.pickupPoint}: ${trip.pickupPoint}'),
              if (trip.dropoffPoint != null)
                Text('${l10n.dropoffPoint}: ${trip.dropoffPoint}'),
              const SizedBox(height: 8),
              Text(
                l10n.cashCollectNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              if (trip.isOpen) ...[
                SosButton(onPressed: () => _openSos(trip, bookings)),
                const SizedBox(height: 12),
              ],
              if (trip.canCancel)
                OutlinedButton(
                  onPressed: _cancelling ? null : () => _cancelTrip(trip),
                  child: Text(l10n.cancelTrip),
                ),
              const SizedBox(height: 24),
              Text(l10n.bookingsOnTrip, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (bookings.isEmpty)
                Text(l10n.noBookingsOnTrip)
              else
                ...bookings.map(
                  (b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(b.travellerDisplayName?.isNotEmpty == true
                        ? b.travellerDisplayName!
                        : (b.travellerPhone ?? l10n.traveller)),
                    subtitle: Text(
                      '${b.seats} ${l10n.seats} · ${l10n.preference}: ${b.seatPreference} · ${b.status}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BookingDetailScreen(
                            sessionStore: widget.sessionStore,
                            bookingId: b.id,
                          ),
                        ),
                      );
                      _reload();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
