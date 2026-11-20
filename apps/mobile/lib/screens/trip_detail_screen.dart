import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../utils/format.dart';
import '../widgets/async_state.dart';
import '../widgets/star_rating.dart';
import 'book_seats_screen.dart';
import 'help_screen.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    super.key,
    required this.sessionStore,
    required this.tripId,
  });

  final SessionStore sessionStore;
  final String tripId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  late Future<Trip> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getTrip(widget.tripId);
  }

  void _reload() => setState(() => _future = _api.getTrip(widget.tripId));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripDetail)),
      body: FutureBuilder<Trip>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorState(error: snap.error!, onRetry: _reload);
          }
          final trip = snap.data!;
          final canBook = trip.canBook;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      '${trip.origin} → ${trip.destination}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(formatDateTime(trip.departAt)),
                    Text('${trip.seatsLeft} ${l10n.seatsLeft} · ${formatInr(trip.fareInr)}/${l10n.seat}'),
                    if (trip.driverDisplayName != null)
                      Text('${l10n.driver}: ${trip.driverDisplayName}'),
                    if (trip.hasDriverRating) ...[
                      const SizedBox(height: 4),
                      RatingBadge(
                        avg: trip.driverRatingAvg,
                        count: trip.driverRatingCount,
                      ),
                    ],
                    if (trip.hasMeetingPoints) ...[
                      const SizedBox(height: 12),
                      Text(l10n.meetingPoints, style: Theme.of(context).textTheme.titleSmall),
                      if (trip.pickupPoint != null)
                        Text('${l10n.pickupPoint}: ${trip.pickupPoint}'),
                      if (trip.dropoffPoint != null)
                        Text('${l10n.dropoffPoint}: ${trip.dropoffPoint}'),
                    ],
                    const SizedBox(height: 12),
                    Text(l10n.vehicleDetails, style: Theme.of(context).textTheme.titleSmall),
                    Text('${l10n.carModel}: ${trip.carModel}'),
                    Text('${l10n.numberPlate}: ${trip.numberPlate}'),
                    Text('${l10n.carColor}: ${trip.carColor}'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KhalashiColors.mist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.cashReminder),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.seatPreferenceNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HelpScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.safetyAndTerms),
                    ),
                    if (!canBook) ...[
                      const SizedBox(height: 16),
                      Text(
                        trip.isFull ? l10n.noSeatsLeft : l10n.tripUnavailable,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: FilledButton(
                    onPressed: !canBook
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BookSeatsScreen(
                                  sessionStore: widget.sessionStore,
                                  trip: trip,
                                ),
                              ),
                            );
                          },
                    child: Text(l10n.bookSeats),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
