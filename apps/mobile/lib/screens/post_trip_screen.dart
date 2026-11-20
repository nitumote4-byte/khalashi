import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../data/suggested_cities.dart';
import '../l10n/app_localizations.dart';
import '../models/meeting_point.dart';
import '../services/api_client.dart';
import '../services/routing_service.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import '../widgets/city_field.dart';
import '../widgets/route_preview_map.dart';
import 'map_pin_picker_screen.dart';
import 'trip_manage_screen.dart';

enum _OfferStep { leaving, heading, preview, details }

/// BlaBlaCar-style Offer Ride: leaving → heading → route preview → trip details.
class PostTripScreen extends StatefulWidget {
  const PostTripScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends State<PostTripScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  final _routing = RoutingService();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _fare = TextEditingController(text: '450');
  final _carModel = TextEditingController();
  final _numberPlate = TextEditingController();
  final _carColor = TextEditingController();

  MeetingPoint? _leaving;
  MeetingPoint? _heading;
  RouteResult? _route;
  bool _routingBusy = false;

  _OfferStep _step = _OfferStep.leaving;
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

  void _onCityPicked({required bool leaving, required String raw}) {
    final curated = lookupCuratedCity(raw);
    if (curated != null) {
      final point = MeetingPoint(
        lat: curated.lat,
        lng: curated.lng,
        label: curated.name,
      );
      setState(() {
        if (leaving) {
          _origin.text = curated.name;
          _leaving = point;
        } else {
          _destination.text = curated.name;
          _heading = point;
        }
        _error = null;
        _route = null;
      });
      return;
    }
    // GPS / free-form place: keep text; coords only after map pick or curated.
    final accepted = widget.sessionStore.resolveAcceptedCity(raw);
    if (accepted != null) {
      setState(() {
        if (leaving) {
          _origin.text = accepted;
        } else {
          _destination.text = accepted;
        }
      });
    }
  }

  Future<void> _chooseOnMap({required bool leaving}) async {
    final l10n = AppLocalizations.of(context);
    final hint = leaving ? _origin.text.trim() : _destination.text.trim();
    final existing = leaving ? _leaving : _heading;
    final result = await Navigator.of(context).push<MeetingPoint>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapPinPickerScreen(
          title: leaving ? l10n.leavingFromQuestion : l10n.headingToQuestion,
          confirmLabel: leaving ? l10n.confirmLeaving : l10n.confirmHeading,
          initial: existing,
          hintCity: hint.isEmpty ? null : hint,
        ),
      ),
    );
    if (result == null || !mounted) return;

    // Prefer curated city from the pin label; else nearest curated for API city.
    final fromLabel = matchPlaceToCuratedCity([result.label]);
    final cityName = fromLabel ?? nearestCuratedCity(result.lat, result.lng).name;
    if (fromLabel == null) {
      widget.sessionStore.acceptGpsCity(cityName);
    }

    setState(() {
      if (leaving) {
        _leaving = result;
        _origin.text = cityName;
      } else {
        _heading = result;
        _destination.text = cityName;
      }
      _error = null;
      _route = null;
    });
  }

  Future<void> _goToPreview() async {
    final l10n = AppLocalizations.of(context);
    final leaving = _leaving;
    final heading = _heading;
    if (leaving == null || heading == null) {
      setState(() => _error = l10n.errorPointsRequired);
      return;
    }
    if (RoutingService.haversineMeters(
          leaving.lat,
          leaving.lng,
          heading.lat,
          heading.lng,
        ) <
        500) {
      setState(() => _error = l10n.errorSamePoint);
      return;
    }

    setState(() {
      _routingBusy = true;
      _error = null;
      _step = _OfferStep.preview;
    });
    final route = await _routing.route(
      fromLat: leaving.lat,
      fromLng: leaving.lng,
      toLat: heading.lat,
      toLng: heading.lng,
    );
    if (!mounted) return;
    setState(() {
      _route = route;
      _routingBusy = false;
    });
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
    final leaving = _leaving;
    final heading = _heading;
    if (leaving == null || heading == null) {
      setState(() => _error = l10n.errorPointsRequired);
      return;
    }

    final originRaw = _origin.text.trim();
    final destinationRaw = _destination.text.trim();
    final fare = int.tryParse(_fare.text.trim());
    final carModel = _carModel.text.trim();
    final numberPlate = _numberPlate.text.trim();
    final carColor = _carColor.text.trim();
    if (originRaw.isEmpty || destinationRaw.isEmpty) {
      setState(() => _error = l10n.errorCitiesRequired);
      return;
    }
    final origin = widget.sessionStore.resolveAcceptedCity(originRaw);
    final destination = widget.sessionStore.resolveAcceptedCity(destinationRaw);
    if (origin == null || destination == null) {
      setState(() => _error = l10n.errorCityNotInList);
      return;
    }
    _origin.text = origin;
    _destination.text = destination;
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
        pickupPoint: leaving.label,
        dropoffPoint: heading.label,
        pickupLat: leaving.lat,
        pickupLng: leaving.lng,
        dropoffLat: heading.lat,
        dropoffLng: heading.lng,
        distanceMeters: _route?.distanceMeters.round(),
        durationSeconds: _route?.durationSeconds,
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

  bool get _canContinueLeaving =>
      _leaving != null || lookupCuratedCity(_origin.text.trim()) != null;
  bool get _canContinueHeading =>
      _heading != null || lookupCuratedCity(_destination.text.trim()) != null;

  /// Ensure meeting point exists from curated city text when user typed only.
  bool _ensurePointFromCityField({required bool leaving}) {
    final existing = leaving ? _leaving : _heading;
    if (existing != null) return true;
    final raw = leaving ? _origin.text.trim() : _destination.text.trim();
    final curated = lookupCuratedCity(raw);
    if (curated == null) return false;
    final point = MeetingPoint(
      lat: curated.lat,
      lng: curated.lng,
      label: curated.name,
    );
    setState(() {
      if (leaving) {
        _origin.text = curated.name;
        _leaving = point;
      } else {
        _destination.text = curated.name;
        _heading = point;
      }
    });
    return true;
  }

  void _onBack() {
    setState(() {
      _error = null;
      switch (_step) {
        case _OfferStep.leaving:
          Navigator.of(context).maybePop();
          break;
        case _OfferStep.heading:
          _step = _OfferStep.leaving;
          break;
        case _OfferStep.preview:
          _step = _OfferStep.heading;
          break;
        case _OfferStep.details:
          _step = _OfferStep.preview;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offerRide),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
      ),
      body: Column(
        children: [
          _StepDots(step: _step),
          Expanded(
            child: switch (_step) {
              _OfferStep.leaving => _buildPointStep(
                    question: l10n.leavingFromQuestion,
                    controller: _origin,
                    point: _leaving,
                    leaving: true,
                    showUseLocation: true,
                  ),
              _OfferStep.heading => _buildPointStep(
                    question: l10n.headingToQuestion,
                    controller: _destination,
                    point: _heading,
                    leaving: false,
                    showUseLocation: false,
                  ),
              _OfferStep.preview => _buildPreviewStep(l10n),
              _OfferStep.details => _buildDetailsStep(l10n),
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: _buildBottomButton(l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(AppLocalizations l10n) {
    switch (_step) {
      case _OfferStep.leaving:
        return FilledButton(
          onPressed: _canContinueLeaving
              ? () {
                  if (!_ensurePointFromCityField(leaving: true)) {
                    setState(() => _error = l10n.errorCityNotInList);
                    return;
                  }
                  setState(() {
                    _step = _OfferStep.heading;
                    _error = null;
                  });
                }
              : null,
          child: Text(l10n.continueLabel),
        );
      case _OfferStep.heading:
        return FilledButton(
          onPressed: _canContinueHeading && !_routingBusy
              ? () {
                  if (!_ensurePointFromCityField(leaving: false)) {
                    setState(() => _error = l10n.errorCityNotInList);
                    return;
                  }
                  _goToPreview();
                }
              : null,
          child: Text(l10n.continueLabel),
        );
      case _OfferStep.preview:
        return FilledButton(
          onPressed: _routingBusy || _route == null
              ? null
              : () => setState(() {
                    _step = _OfferStep.details;
                    _error = null;
                  }),
          child: Text(l10n.continueToTripDetails),
        );
      case _OfferStep.details:
        return FilledButton(
          onPressed: _loading ? null : _publish,
          child: _loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.publishTrip),
        );
    }
  }

  Widget _buildPointStep({
    required String question,
    required TextEditingController controller,
    required MeetingPoint? point,
    required bool leaving,
    required bool showUseLocation,
  }) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: KhalashiColors.dusk,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.cityOrMapHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KhalashiColors.dusk.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 20),
        CityField(
          controller: controller,
          label: leaving ? l10n.origin : l10n.destination,
          sessionStore: widget.sessionStore,
          showUseLocation: showUseLocation,
          onCitySelected: (city) => _onCityPicked(leaving: leaving, raw: city),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _chooseOnMap(leaving: leaving),
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.chooseOnMap),
        ),
        if (point != null) ...[
          const SizedBox(height: 20),
          _SelectedPointCard(
            title: leaving ? l10n.leavingPoint : l10n.headingPoint,
            point: point,
            onClear: () => setState(() {
              if (leaving) {
                _leaving = null;
              } else {
                _heading = null;
              }
              _route = null;
            }),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _buildPreviewStep(AppLocalizations l10n) {
    final leaving = _leaving!;
    final heading = _heading!;
    final route = _route;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          l10n.routePreviewTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: KhalashiColors.dusk,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${leaving.label} → ${heading.label}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KhalashiColors.dusk.withOpacity(0.75),
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: _routingBusy || route == null
              ? const Center(child: CircularProgressIndicator())
              : RoutePreviewMap(
                  route: route,
                  origin: LatLng(leaving.lat, leaving.lng),
                  destination: LatLng(heading.lat, heading.lng),
                ),
        ),
        if (route != null && !_routingBusy) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.straighten,
                  label: l10n.routeDistance,
                  value: _formatDistance(l10n, route.distanceKm),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.schedule,
                  label: l10n.routeDuration,
                  value: _formatDuration(l10n, route.durationSeconds),
                ),
              ),
            ],
          ),
          if (!route.fromOsrm) ...[
            const SizedBox(height: 10),
            Text(
              l10n.routeEstimateFallback,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KhalashiColors.dusk.withOpacity(0.65),
                  ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _step = _OfferStep.leaving;
            _error = null;
          }),
          child: Text(l10n.editRoutePoints),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _buildDetailsStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text(
          l10n.tripDetailsTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: KhalashiColors.dusk,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (_route != null) ...[
          const SizedBox(height: 8),
          Text(
            '${_formatDistance(l10n, _route!.distanceKm)} · '
            '${_formatDuration(l10n, _route!.durationSeconds)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: KhalashiColors.dusk.withOpacity(0.7),
                ),
          ),
        ],
        const SizedBox(height: 20),
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
    );
  }

  String _formatDistance(AppLocalizations l10n, double km) {
    if (km < 10) {
      return l10n.distanceKm(km.toStringAsFixed(1));
    }
    return l10n.distanceKm(km.round().toString());
  }

  String _formatDuration(AppLocalizations l10n, int seconds) {
    final totalMin = (seconds / 60).round().clamp(1, 99999);
    final hours = totalMin ~/ 60;
    final minutes = totalMin % 60;
    if (hours <= 0) return l10n.durationMinutesOnly(minutes);
    if (minutes == 0) return l10n.durationHoursOnly(hours);
    return l10n.durationHoursMinutes(hours, minutes);
  }

  String _month(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m - 1];
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final _OfferStep step;

  @override
  Widget build(BuildContext context) {
    final index = step.index;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= index;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? KhalashiColors.deepTeal
                    : KhalashiColors.dusk.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SelectedPointCard extends StatelessWidget {
  const _SelectedPointCard({
    required this.title,
    required this.point,
    required this.onClear,
  });

  final String title;
  final MeetingPoint point;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            const Icon(Icons.place, color: KhalashiColors.saffron),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: KhalashiColors.dusk.withOpacity(0.65),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    point.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: KhalashiColors.dusk,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KhalashiColors.mist),
      ),
      child: Row(
        children: [
          Icon(icon, color: KhalashiColors.deepTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: KhalashiColors.dusk.withOpacity(0.6),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: KhalashiColors.dusk,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
