import 'package:flutter/material.dart';

import '../data/suggested_cities.dart';
import '../l10n/app_localizations.dart';
import '../services/city_location_service.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';

/// From/To city field: recent (curated) first, fuzzy suggestions, optional GPS fill.
class CityField extends StatefulWidget {
  const CityField({
    super.key,
    required this.controller,
    required this.label,
    required this.sessionStore,
    this.showUseLocation = true,
    this.onCitySelected,
  });

  final TextEditingController controller;
  final String label;
  final SessionStore sessionStore;

  /// GPS affordance — useful on From; also fine on To.
  final bool showUseLocation;

  /// Called when the user picks a suggestion, submits, or fills via GPS.
  final ValueChanged<String>? onCitySelected;

  @override
  State<CityField> createState() => _CityFieldState();
}

class _CityOption {
  const _CityOption({required this.name, required this.isRecent});

  final String name;
  final bool isRecent;
}

class _CityFieldState extends State<CityField> {
  List<String> _recents = const [];
  final FocusNode _focusNode = FocusNode();
  bool _locating = false;
  final _location = CityLocationService();

  @override
  void initState() {
    super.initState();
    _loadRecents();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _loadRecents();
    }
  }

  Future<void> _loadRecents() async {
    final cities = await widget.sessionStore.getRecentCities();
    if (!mounted) return;
    setState(() => _recents = cities);
    // Refresh open overlay after async load (RawAutocomplete caches options).
    if (_focusNode.hasFocus) {
      widget.controller.notifyListeners();
    }
  }

  List<_CityOption> _optionsFor(String query) {
    final q = query.trim().toLowerCase();
    final recentMatches = <_CityOption>[];
    final seen = <String>{};

    for (final city in _recents) {
      final canonical = resolveCuratedCity(city) ?? city;
      if (q.isNotEmpty) {
        final fuzzy = fuzzySuggestCities(q, limit: 32);
        final hit = fuzzy.any((f) => f.toLowerCase() == canonical.toLowerCase()) ||
            canonical.toLowerCase().contains(q);
        if (!hit) continue;
      }
      final key = canonical.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      recentMatches.add(_CityOption(name: canonical, isRecent: true));
    }

    final suggestions = <_CityOption>[];
    final ranked = q.isEmpty
        ? kSuggestedCities.take(12).toList()
        : fuzzySuggestCities(query, limit: 16);
    for (final city in ranked) {
      final key = city.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      suggestions.add(_CityOption(name: city, isRecent: false));
    }

    return [...recentMatches, ...suggestions];
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      final result = await _location.resolveCurrentCity();
      if (!mounted) return;
      final city = result.name;
      // GPS-derived names (incl. non-curated reverse-geocode) are accepted on submit.
      widget.sessionStore.acceptGpsCity(city);
      widget.controller.text = city;
      widget.controller.selection = TextSelection.collapsed(offset: city.length);
      widget.controller.notifyListeners();
      widget.onCitySelected?.call(city);
      messenger.showSnackBar(SnackBar(content: Text(l10n.locationFilled(city))));
    } on CityLocationException catch (e) {
      if (!mounted) return;
      final message = switch (e.failure) {
        CityLocationFailure.serviceDisabled => l10n.locationServiceDisabled,
        CityLocationFailure.permissionDenied => l10n.locationPermissionDenied,
        CityLocationFailure.permissionDeniedForever =>
          l10n.locationPermissionDeniedForever,
        CityLocationFailure.unavailable => l10n.locationUnavailable,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.locationUnavailable)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RawAutocomplete<_CityOption>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.name,
      optionsBuilder: (TextEditingValue value) {
        return _optionsFor(value.text);
      },
      onSelected: (option) {
        widget.controller.text = option.name;
        widget.controller.selection =
            TextSelection.collapsed(offset: option.name.length);
        widget.onCitySelected?.call(option.name);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: l10n.cityPickHint,
            suffixIcon: widget.showUseLocation
                ? IconButton(
                    tooltip: l10n.useCurrentLocation,
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_outlined),
                  )
                : null,
          ),
          onSubmitted: (_) {
            onFieldSubmitted();
            final text = controller.text.trim();
            if (text.isNotEmpty) widget.onCitySelected?.call(text);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        if (list.isEmpty) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.cityNoMatchHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KhalashiColors.dusk.withOpacity(0.8),
                      ),
                ),
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, minWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final option = list[index];
                  final showRecentHeader =
                      option.isRecent && (index == 0 || !list[index - 1].isRecent);
                  final showSuggestionsHeader = !option.isRecent &&
                      (index == 0 || list[index - 1].isRecent);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showRecentHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            l10n.recentCities,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: KhalashiColors.dusk.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      if (showSuggestionsHeader && list.any((o) => o.isRecent))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            l10n.suggestedCities,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: KhalashiColors.dusk.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          option.isRecent
                              ? Icons.history
                              : Icons.location_city_outlined,
                          size: 20,
                          color: KhalashiColors.deepTeal,
                        ),
                        title: Text(option.name),
                        onTap: () => onSelected(option),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
