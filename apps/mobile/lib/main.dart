import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'locale_scope.dart';
import 'screens/splash_screen.dart';
import 'services/session_store.dart';
import 'theme/khalashi_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KhalashiApp());
}

class KhalashiApp extends StatefulWidget {
  const KhalashiApp({super.key});

  @override
  State<KhalashiApp> createState() => _KhalashiAppState();
}

class _KhalashiAppState extends State<KhalashiApp> {
  final SessionStore _sessionStore = SessionStore();
  Locale _locale = const Locale('en');

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      locale: _locale,
      setLocale: _setLocale,
      child: MaterialApp(
        title: 'Khalashi',
        debugShowCheckedModeBanner: false,
        theme: buildKhalashiTheme(),
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: SplashScreen(
          onLocaleChanged: _setLocale,
          sessionStore: _sessionStore,
        ),
      ),
    );
  }
}
