import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../utils/format.dart';
import '../widgets/async_state.dart';
import 'post_trip_screen.dart';
import 'trip_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.sessionStore,
    required this.origin,
    required this.destination,
    required this.dateYmd,
  });

  final SessionStore sessionStore;
  final String origin;
  final String destination;
  final String dateYmd;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  late Future<List<Trip>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Trip>> _load() => _api.searchTrips(
        origin: widget.origin,
        destination: widget.destination,
        dateYmd: widget.dateYmd,
      );

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.origin} → ${widget.destination}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('${widget.origin} → ${widget.destination} · ${widget.dateYmd}'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Trip>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorState(error: snap.error!, onRetry: _reload);
                }
                final trips = snap.data ?? [];
                if (trips.isEmpty) {
                  return EmptyState(
                    message: l10n.noRidesFound,
                    icon: Icons.directions_car_outlined,
                    actionLabel: l10n.offerRide,
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PostTripScreen(
                            sessionStore: widget.sessionStore,
                          ),
                        ),
                      );
                    },
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = trips[i];
                      final full = t.isFull;
                      return ListTile(
                        enabled: !full,
                        title: Text(
                          '${formatTime(t.departAt)}  ·  '
                          '${full ? l10n.full : '${t.seatsLeft} ${l10n.seats}'}  ·  '
                          '${formatInr(t.fareInr)}',
                        ),
                        subtitle: Text(
                          '${l10n.cashOnTrip}'
                          '${t.driverDisplayName != null ? ' · ${t.driverDisplayName}' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: full
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => TripDetailScreen(
                                      sessionStore: widget.sessionStore,
                                      tripId: t.id,
                                    ),
                                  ),
                                );
                              },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
