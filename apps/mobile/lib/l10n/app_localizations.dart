import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

/// Hand-maintained HI/EN strings. Prefer `flutter gen-l10n` once Flutter SDK is available.
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
  String get retry;
  String get home;
  String get origin;
  String get destination;
  String get searchRides;
  String get offerRideInstead;
  String get noRidesFound;
  String get changeDate;
  String get full;
  String get seats;
  String get seat;
  String get seatsLeft;
  String get cashOnTrip;
  String get tripDetail;
  String get driver;
  String get seatPreferenceNote;
  String get noSeatsLeft;
  String get tripUnavailable;
  String get bookSeats;
  String get preference;
  String get prefFront;
  String get prefWindow;
  String get prefAny;
  String get seatPreferenceRequestOnly;
  String get totalDue;
  String get confirmBooking;
  String get bookingConfirmed;
  String get bookingRef;
  String get payCashWhenMeet;
  String get viewBooking;
  String get upcoming;
  String get past;
  String get noBookingsYet;
  String get bookingDetail;
  String get statusConfirmed;
  String get statusCancelled;
  String get cancelBooking;
  String get cancelBookingConfirm;
  String get bookingCancelled;
  String get keep;
  String get confirmCancel;
  String get traveller;
  String get seatsAvailable;
  String get farePerSeat;
  String get youSetFare;
  String get cashDriverNote;
  String get publishTrip;
  String get postSuccessTitle;
  String get tripManage;
  String get cashCollectNote;
  String get cancelTrip;
  String get cancelTripConfirm;
  String get tripCancelled;
  String get bookingsOnTrip;
  String get noBookingsOnTrip;
  String get noTripsYet;
  String get errorCitiesRequired;
  String get errorInvalidFare;
  String get errorPastDeparture;
  String get helpTitle;
  String get helpSubtitle;
  String get cashHowTitle;
  String get cashHowBody;
  String get seatPrefHelpTitle;
  String get seatPrefHelpBody;
  String get cancelHelpTitle;
  String get cancelHelpBody;
  String get safetyTipsTitle;
  String get safetyTip1;
  String get safetyTip2;
  String get safetyTip3;
  String get safetyTip4;
  String get safetyTip5;
  String get safetyTip6;
  String get emergencyLine;
  String get disclaimerTitle;
  String get disclaimerBody;
  String get operatorLine;
  String get supportTitle;
  String get supportHours;
  String get supportWhatsApp;
  String get supportPhone;
  String get copyWhatsApp;
  String get copyPhone;
  String get copied;
  String get supportStubNote;
  String get supportOpenFailed;
  String get needHelpBooking;
  String get safetyAndTerms;
  String get bookMicroDisclaimer;
  String get errorGeneric;
  String get errorNetworkHint;
  String get errorRateLimited;
  String get errorUnauthorized;
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
