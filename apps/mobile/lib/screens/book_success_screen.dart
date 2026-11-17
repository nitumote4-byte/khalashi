import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../utils/format.dart';
import 'booking_detail_screen.dart';
import 'home_screen.dart';

class BookSuccessScreen extends StatelessWidget {
  const BookSuccessScreen({
    super.key,
    required this.sessionStore,
    required this.booking,
  });

  final SessionStore sessionStore;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = booking.trip;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingConfirmed)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.bookingConfirmed,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: KhalashiColors.deepTeal,
                  ),
            ),
            const SizedBox(height: 8),
            Text('${l10n.bookingRef}: ${booking.bookingRef}'),
            if (trip != null) ...[
              const SizedBox(height: 16),
              Text('${trip.origin} → ${trip.destination}'),
              Text(formatDateTime(trip.departAt)),
              Text(trip.vehicleSummary),
            ],
            Text('${booking.seats} ${l10n.seats} · ${l10n.preference}: ${booking.seatPreference}'),
            Text('${l10n.totalDue}: ${formatInr(booking.cashTotalInr)}'),
            const SizedBox(height: 12),
            Text(l10n.payCashWhenMeet),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => BookingDetailScreen(
                      sessionStore: sessionStore,
                      bookingId: booking.id,
                    ),
                  ),
                );
              },
              child: Text(l10n.viewBooking),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => HomeScreen(sessionStore: sessionStore),
                  ),
                  (_) => false,
                );
              },
              child: Text(l10n.home),
            ),
          ],
        ),
      ),
    );
  }
}
