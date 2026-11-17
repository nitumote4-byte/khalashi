import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';
import 'home_screen.dart';
import 'language_screen.dart';
import 'phone_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onLocaleChanged,
    required this.sessionStore,
  });

  final ValueChanged<Locale> onLocaleChanged;
  final SessionStore sessionStore;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final lang = await widget.sessionStore.getLanguage();
    final token = await widget.sessionStore.getToken();

    if (!mounted) return;

    if (lang == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LanguageScreen(
            onLocaleChanged: widget.onLocaleChanged,
            sessionStore: widget.sessionStore,
          ),
        ),
      );
      return;
    }

    widget.onLocaleChanged(Locale(lang));

    if (token != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(sessionStore: widget.sessionStore),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PhoneScreen(sessionStore: widget.sessionStore),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KhalashiColors.deepTeal,
              Color(0xFF1A5A4A),
              KhalashiColors.saffron,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
