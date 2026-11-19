import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../widgets/city_field.dart';
import 'trip_manage_screen.dart';

class PostTripScreen extends StatefulWidget {
  const PostTripScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends State<PostTripScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _fare = TextEditingController(text: '450');
  final _carModel = TextEditingController();
  final _numberPlate = TextEditingController();
  final _carColor = TextEditingController();
  DateTime _depart = DateTime.now().add(const Duration(days: 1, hours: 1)).copyWith(
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
  int _seats = 3;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _fare.dispose();
    _carModel.dispose();
    _numberPlate.dispose();
    _carColor.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _depart,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return;
    setState(() {
      _depart = DateTime(date.year, date.month, date.day, _depart.hour, _depart.minute);
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_depart),
    );
    if (time == null) return;
    setState(() {
      _depart = DateTime(_depart.year, _depart.month, _depart.day, time.hour, time.minute);
    });
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final origin = _origin.text.trim();
    final destination = _destination.text.trim();
    final fare = int.tryParse(_fare.text.trim());
    final carModel = _carModel.text.trim();
    final numberPlate = _numberPlate.text.trim();
    final carColor = _carColor.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
      setState(() => _error = l10n.errorCitiesRequired);
      return;
    }
    if (fare == null || fare < 0) {
      setState(() => _error = l10n.errorInvalidFare);
      return;
    }
    if (carModel.isEmpty || numberPlate.isEmpty || carColor.isEmpty) {
      setState(() => _error = l10n.errorVehicleRequired);
      return;
    }
    if (!_depart.isAfter(DateTime.now())) {
      setState(() => _error = l10n.errorPastDeparture);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.sessionStore.addRecentCities([origin, destination]);
      final trip = await _api.createTrip(
        origin: origin,
        destination: destination,
        departAt: _depart,
        seatsTotal: _seats,
        fareInr: fare,
        carModel: carModel,
        numberPlate: numberPlate,
        carColor: carColor,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TripManageScreen(
            sessionStore: widget.sessionStore,
            tripId: trip.id,
            justPublished: true,
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.offerRide)),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickDate,
                        child: Text(
                          '${_depart.day.toString().padLeft(2, '0')} '
                          '${_month(_depart.month)} ${_depart.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickTime,
                        child: Text(
                          '${_depart.hour.toString().padLeft(2, '0')}:'
                          '${_depart.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(l10n.seatsAvailable, style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    IconButton(
                      onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_seats', style: Theme.of(context).textTheme.headlineSmall),
                    IconButton(
                      onPressed: _seats < 8 ? () => setState(() => _seats++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fare,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.farePerSeat,
                    prefixText: '₹ ',
                    helperText: l10n.youSetFare,
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.vehicleDetails, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _carModel,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.carModel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _numberPlate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l10n.numberPlate),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _carColor,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.carColor),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.cashDriverNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: KhalashiColors.dusk.withOpacity(0.75),
                      ),
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
                onPressed: _loading ? null : _publish,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.publishTrip),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m - 1];
  }
}
