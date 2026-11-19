import 'package:flutter/material.dart';

import '../data/suggested_cities.dart';
import '../l10n/app_localizations.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';

/// From/To city field: recent cities first, then curated suggestions.
class CityField extends StatefulWidget {
  const CityField({
    super.key,
    required this.controller,
    required this.label,
    required this.sessionStore,
  });

  final TextEditingController controller;
  final String label;
  final SessionStore sessionStore;

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
      if (q.isNotEmpty && !city.toLowerCase().contains(q)) continue;
      final key = city.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      recentMatches.add(_CityOption(name: city, isRecent: true));
    }

    final suggestions = <_CityOption>[];
    for (final city in kSuggestedCities) {
      if (q.isNotEmpty && !city.toLowerCase().contains(q)) continue;
      final key = city.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      suggestions.add(_CityOption(name: city, isRecent: false));
    }

    // Empty query: show all recents, then a short slice of suggestions.
    if (q.isEmpty) {
      return [
        ...recentMatches,
        ...suggestions.take(12),
      ];
    }

    return [...recentMatches, ...suggestions.take(16)];
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
        widget.controller.selection = TextSelection.collapsed(offset: option.name.length);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: widget.label),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        if (list.isEmpty) {
          return const SizedBox.shrink();
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
                          option.isRecent ? Icons.history : Icons.location_city_outlined,
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
