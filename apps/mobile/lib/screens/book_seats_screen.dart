import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../utils/format.dart';
import 'book_success_screen.dart';

class BookSeatsScreen extends StatefulWidget {
  const BookSeatsScreen({
    super.key,
    required this.sessionStore,
    required this.trip,
  });

  final SessionStore sessionStore;
  final Trip trip;

  @override
  State<BookSeatsScreen> createState() => _BookSeatsScreenState();
}

class _BookSeatsScreenState extends State<BookSeatsScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  int _seats = 1;
  String _preference = 'any';
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await _api.bookTrip(
        tripId: widget.trip.id,
        seats: _seats,
        seatPreference: _preference,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BookSuccessScreen(
            sessionStore: widget.sessionStore,
            booking: booking,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = widget.trip;
    final total = trip.fareInr * _seats;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookSeats)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('${trip.origin} → ${trip.destination}'),
                Text(formatDateTime(trip.departAt)),
                Text(trip.vehicleSummary),
                if (trip.pickupPoint != null)
                  Text('${l10n.pickupPoint}: ${trip.pickupPoint}'),
                if (trip.dropoffPoint != null)
                  Text('${l10n.dropoffPoint}: ${trip.dropoffPoint}'),
                const SizedBox(height: 20),
                Text(l10n.seats, style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    IconButton(
                      onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_seats', style: Theme.of(context).textTheme.headlineSmall),
                    IconButton(
                      onPressed: _seats < trip.seatsLeft
                          ? () => setState(() => _seats++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.preference, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in ['front', 'window', 'any'])
                      ChoiceChip(
                        label: Text(_prefLabel(l10n, p)),
                        selected: _preference == p,
                        onSelected: (_) => setState(() => _preference = p),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.seatPreferenceRequestOnly,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Text(
                  '${l10n.totalDue}: ${formatInr(total)} · ${l10n.cashOnTrip}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.bookMicroDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: FilledButton(
                onPressed: _loading ? null : _confirm,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.confirmBooking),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prefLabel(AppLocalizations l10n, String p) {
    switch (p) {
      case 'front':
        return l10n.prefFront;
      case 'window':
        return l10n.prefWindow;
      default:
        return l10n.prefAny;
    }
  }
}
