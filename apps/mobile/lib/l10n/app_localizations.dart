import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

/// Hand-maintained Phase 0 shell. Prefer `flutter gen-l10n` once Flutter SDK is available.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  String get appName;
  String get tagline;
  String get languageTitle;
  String get languageHindi;
  String get languageEnglish;
  String get continueLabel;
  String get phoneTitle;
  String get phoneHint;
  String get phonePrefix;
  String get sendOtp;
  String get otpTitle;
  String get otpHint;
  String get verifyOtp;
  String get resendOtp;
  String get homeGreeting;
  String get findRide;
  String get offerRide;
  String get findRideSubtitle;
  String get offerRideSubtitle;
  String get cashReminder;
  String get myBookings;
  String get myTrips;
  String get profile;
  String get logout;
  String get stubComingSoon;
  String get comingSoonFind;
  String get comingSoonOffer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'hi':
      return AppLocalizationsHi();
    case 'en':
    default:
      return AppLocalizationsEn();
  }
}
