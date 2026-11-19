import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/session_store.dart';
import '../utils/format.dart';
import '../widgets/city_field.dart';
import 'post_trip_screen.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _search() async {
    final l10n = AppLocalizations.of(context);
    final origin = _origin.text.trim();
    final destination = _destination.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
      setState(() => _error = l10n.errorCitiesRequired);
      return;
    }
    // Destination last so it stays newest when both are saved.
    await widget.sessionStore.addRecentCities([origin, destination]);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchResultsScreen(
          sessionStore: widget.sessionStore,
          origin: origin,
          destination: destination,
          dateYmd: ymd(_date),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.findRide)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                CityField(
                  controller: _origin,
                  label: l10n.origin,
                  sessionStore: widget.sessionStore,
                ),
                const SizedBox(height: 12),
                CityField(
                  controller: _destination,
                  label: l10n.destination,
                  sessionStore: widget.sessionStore,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(formatDate(_date)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PostTripScreen(sessionStore: widget.sessionStore),
                      ),
                    );
                  },
                  child: Text(l10n.offerRideInstead),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: FilledButton(
                onPressed: _search,
                child: Text(l10n.searchRides),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
