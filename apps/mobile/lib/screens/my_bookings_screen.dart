import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../utils/format.dart';
import 'booking_detail_screen.dart';
import 'search_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  late Future<List<Booking>> _future;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _future = _api.myBookings();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _api.myBookings());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBookings),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.upcoming),
            Tab(text: l10n.past),
          ],
        ),
      ),
      body: FutureBuilder<List<Booking>>(
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
          final all = snap.data ?? [];
          final now = DateTime.now();
          final upcoming = all
              .where((b) => b.trip != null && b.trip!.departAt.isAfter(now) && b.isConfirmed)
              .toList();
          final past = all
              .where((b) =>
                  b.trip == null ||
                  !b.trip!.departAt.isAfter(now) ||
                  !b.isConfirmed)
              .toList();

          Widget list(List<Booking> items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.noBookingsYet),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SearchScreen(sessionStore: widget.sessionStore),
                            ),
                          );
                        },
                        child: Text(l10n.findRide),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = items[i];
                  final t = b.trip;
                  return ListTile(
                    title: Text(
                      t != null ? '${t.origin} → ${t.destination}' : b.bookingRef,
                    ),
                    subtitle: Text(
                      '${t != null ? formatDateTime(t.departAt) : ''} · '
                      '${b.seats} ${l10n.seats} · ${formatInr(b.cashTotalInr)} · '
                      '${b.status} · ${b.seatPreference}',
                    ),
                    isThreeLine: true,
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
                  );
                },
              ),
            );
          }

          return TabBarView(
            controller: _tabs,
            children: [list(upcoming), list(past)],
          );
        },
      ),
    );
  }
}
