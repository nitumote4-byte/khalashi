import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../utils/format.dart';
import '../widgets/async_state.dart';
import 'post_trip_screen.dart';
import 'trip_manage_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  late Future<List<Trip>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.myTrips();
  }

  void _reload() {
    setState(() => _future = _api.myTrips());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTrips)),
      body: FutureBuilder<List<Trip>>(
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
              message: l10n.noTripsYet,
              icon: Icons.route_outlined,
              actionLabel: l10n.offerRide,
              onAction: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PostTripScreen(sessionStore: widget.sessionStore),
                  ),
                );
                _reload();
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = trips[i];
                final booked = t.seatsTotal - t.seatsLeft;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  title: Text('${t.origin} → ${t.destination}'),
                  subtitle: Text(
                    '${formatDateTime(t.departAt)}\n'
                    '$booked booked · ${t.seatsLeft} left · ${formatInr(t.fareInr)}/seat · ${t.status}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TripManageScreen(
                          sessionStore: widget.sessionStore,
                          tripId: t.id,
                        ),
                      ),
                    );
                    _reload();
                  },
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: FilledButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PostTripScreen(sessionStore: widget.sessionStore),
                ),
              );
              _reload();
            },
            child: Text(l10n.offerRide),
          ),
        ),
      ),
    );
  }
}
