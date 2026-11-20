import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../utils/format.dart';
import '../widgets/async_state.dart';
import '../widgets/sos_sheet.dart';
import 'help_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.sessionStore,
    required this.bookingId,
  });

  final SessionStore sessionStore;
  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  late Future<Booking> _future;
  bool _cancelling = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _future = _api.getBooking(widget.bookingId);
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

  void _reload() => setState(() => _future = _api.getBooking(widget.bookingId));

  Future<void> _openSos(Booking b) async {
    final trip = b.trip;
    if (trip == null) return;
    await showSosSheet(
      context: context,
      api: _api,
      tripId: trip.id,
      bookingId: b.id,
      origin: trip.origin,
      destination: trip.destination,
      departAt: trip.departAt,
      pickupPoint: trip.pickupPoint,
      dropoffPoint: trip.dropoffPoint,
      counterpartPhone: trip.driverPhone,
      counterpartLabel: AppLocalizations.of(context).driver,
      profile: _profile,
    );
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelBooking),
        content: Text(l10n.cancelBookingConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.keep)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirmCancel)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      await _api.cancelBooking(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingCancelled)),
      );
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
      appBar: AppBar(title: Text(l10n.bookingDetail)),
      body: FutureBuilder<Booking>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorState(error: snap.error!, onRetry: _reload);
          }
          final b = snap.data!;
          final trip = b.trip;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Chip(
                label: Text(b.status == 'confirmed' ? l10n.statusConfirmed : l10n.statusCancelled),
                backgroundColor: b.status == 'confirmed'
                    ? KhalashiColors.mist
                    : Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text('${l10n.bookingRef}: ${b.bookingRef}'),
              if (trip != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${trip.origin} → ${trip.destination}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(formatDateTime(trip.departAt)),
                Text('${formatInr(trip.fareInr)}/${l10n.seat}'),
                if (trip.hasMeetingPoints) ...[
                  const SizedBox(height: 8),
                  Text(l10n.meetingPoints, style: Theme.of(context).textTheme.titleSmall),
                  if (trip.pickupPoint != null)
                    Text('${l10n.pickupPoint}: ${trip.pickupPoint}'),
                  if (trip.dropoffPoint != null)
                    Text('${l10n.dropoffPoint}: ${trip.dropoffPoint}'),
                ],
                const SizedBox(height: 8),
                Text(l10n.vehicleDetails, style: Theme.of(context).textTheme.titleSmall),
                Text('${l10n.carModel}: ${trip.carModel}'),
                Text('${l10n.numberPlate}: ${trip.numberPlate}'),
                Text('${l10n.carColor}: ${trip.carColor}'),
              ],
              const SizedBox(height: 8),
              Text('${b.seats} ${l10n.seats} · ${l10n.preference}: ${b.seatPreference}'),
              Text('${l10n.totalDue}: ${formatInr(b.cashTotalInr)}'),
              if (b.travellerPhone != null) ...[
                const SizedBox(height: 8),
                Text('${l10n.traveller}: ${b.travellerDisplayName ?? b.travellerPhone}'),
              ],
              const SizedBox(height: 16),
              Text(l10n.cashReminder, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                l10n.bookMicroDisclaimer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KhalashiColors.dusk.withOpacity(0.75),
                    ),
              ),
              const SizedBox(height: 24),
              if (b.isConfirmed && trip != null) ...[
                SosButton(onPressed: () => _openSos(b)),
                const SizedBox(height: 12),
              ],
              if (b.canCancel)
                OutlinedButton(
                  onPressed: _cancelling ? null : _cancel,
                  child: Text(l10n.cancelBooking),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HelpScreen(bookingRef: b.bookingRef),
                    ),
                  );
                },
                child: Text(l10n.needHelpBooking),
              ),
            ],
          );
        },
      ),
    );
  }
}
