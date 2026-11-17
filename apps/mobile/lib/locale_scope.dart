import 'package:flutter/widgets.dart';

/// App-level locale setter so Profile can toggle HI/EN without prop-drilling.
class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  final Locale locale;
  final ValueChanged<Locale> setLocale;

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!;
  }

  static LocaleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleScope>();
  }

  @override
  bool updateShouldNotify(LocaleScope oldWidget) => locale != oldWidget.locale;
}
