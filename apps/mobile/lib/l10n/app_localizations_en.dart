import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Khalashi';
  @override
  String get tagline => 'Post trips · book seats · pay cash on trip';
  @override
  String get languageTitle => 'Choose language';
  @override
  String get languageHindi => 'हिंदी';
  @override
  String get languageEnglish => 'English';
  @override
  String get continueLabel => 'Continue';
  @override
  String get phoneTitle => 'Your mobile number';
  @override
  String get phoneHint => '10-digit mobile';
  @override
  String get phonePrefix => '+91';
  @override
  String get sendOtp => 'Send OTP';
  @override
  String get otpTitle => 'Enter OTP';
  @override
  String get otpHint => '6-digit code';
  @override
  String get verifyOtp => 'Verify';
  @override
  String get resendOtp => 'Resend OTP';
  @override
  String get homeGreeting => 'Where to today?';
  @override
  String get findRide => 'Find a ride';
  @override
  String get offerRide => 'Offer a ride';
  @override
  String get findRideSubtitle => 'Search trips and book seats';
  @override
  String get offerRideSubtitle => 'Post a trip with seats and fare';
  @override
  String get cashReminder =>
      'Payment is cash to the driver on the trip — Khalashi never takes money.';
  @override
  String get myBookings => 'My bookings';
  @override
  String get myTrips => 'My trips';
  @override
  String get profile => 'Profile';
  @override
  String get logout => 'Log out';
  @override
  String get retry => 'Retry';
  @override
  String get home => 'Home';
  @override
  String get origin => 'From (city)';
  @override
  String get destination => 'To (city)';
  @override
  String get pickupPoint => 'Pickup point';
  @override
  String get dropoffPoint => 'Drop-off point';
  @override
  String get pickupPointHelper => 'Optional — tap to mark on the map';
  @override
  String get dropoffPointHelper => 'Optional — tap to mark on the map';
  @override
  String get tapToMarkOnMap => 'Tap to mark on map';
  @override
  String get confirmPickup => 'Confirm pickup';
  @override
  String get confirmDropoff => 'Confirm drop-off';
  @override
  String get mapPinHint => 'Move the map so the pin sits on the exact spot';
  @override
  String get mapPinMoving => 'Release to set location…';
  @override
  String get mapPinLookingUp => 'Looking up address…';
  @override
  String get meetingPoints => 'Meeting points';
  @override
  String get recentCities => 'Recent';
  @override
  String get suggestedCities => 'Suggested';
  @override
  String get cityPickHint => 'Pick a city from the list';
  @override
  String get cityNoMatchHint => 'No matching city — try another spelling';
  @override
  String get useCurrentLocation => 'Use current location';
  @override
  String locationFilled(String city) => 'Set to $city';
  @override
  String get locationServiceDisabled =>
      'Turn on location services and try again';
  @override
  String get locationPermissionDenied => 'Location permission denied';
  @override
  String get locationPermissionDeniedForever =>
      'Enable location in Settings to use this';
  @override
  String get locationUnavailable => 'Could not get your location';
  @override
  String get errorCityNotInList =>
      'Choose a city from the list (e.g. Patna, not patn)';
  @override
  String get searchRides => 'Search rides';
  @override
  String get offerRideInstead => 'Or offer a ride';
  @override
  String get noRidesFound =>
      'No rides for this date. Try another date or offer a ride.';
  @override
  String get changeDate => 'Change date';
  @override
  String get full => 'Full';
  @override
  String get seats => 'seats';
  @override
  String get seat => 'seat';
  @override
  String get seatsLeft => 'seats left';
  @override
  String get cashOnTrip => 'Cash on trip';
  @override
  String get tripDetail => 'Trip';
  @override
  String get driver => 'Driver';
  @override
  String get seatPreferenceNote =>
      "You'll choose seat preference next — request only, not a seat map.";
  @override
  String get noSeatsLeft => 'No seats left';
  @override
  String get tripUnavailable => 'Trip unavailable';
  @override
  String get bookSeats => 'Book seats';
  @override
  String get preference => 'Preference';
  @override
  String get prefFront => 'Front';
  @override
  String get prefWindow => 'Window';
  @override
  String get prefAny => 'Any';
  @override
  String get seatPreferenceRequestOnly => 'Seat preference is a request only.';
  @override
  String get totalDue => 'Total due';
  @override
  String get confirmBooking => 'Confirm booking';
  @override
  String get bookingConfirmed => 'Booking confirmed';
  @override
  String get bookingRef => 'Booking ref';
  @override
  String get payCashWhenMeet => 'Pay the driver in cash when you meet.';
  @override
  String get viewBooking => 'View booking';
  @override
  String get upcoming => 'Upcoming';
  @override
  String get past => 'Past';
  @override
  String get noBookingsYet => 'No bookings yet';
  @override
  String get bookingDetail => 'Booking';
  @override
  String get statusConfirmed => 'Confirmed';
  @override
  String get statusCancelled => 'Cancelled';
  @override
  String get cancelBooking => 'Cancel booking';
  @override
  String get cancelBookingConfirm =>
      'Free cancel until trip start. Seats go back on the trip.';
  @override
  String get bookingCancelled => 'Booking cancelled';
  @override
  String get keep => 'Keep';
  @override
  String get confirmCancel => 'Confirm cancel';
  @override
  String get traveller => 'Traveller';
  @override
  String get seatsAvailable => 'Seats available';
  @override
  String get farePerSeat => 'Fare per seat';
  @override
  String get youSetFare => 'You set the fare';
  @override
  String get vehicleDetails => 'Vehicle';
  @override
  String get carModel => 'Car model';
  @override
  String get numberPlate => 'Number plate';
  @override
  String get carColor => 'Color';
  @override
  String get cashDriverNote => 'Travellers pay you in cash on the trip.';
  @override
  String get publishTrip => 'Publish trip';
  @override
  String get postSuccessTitle => 'Trip published';
  @override
  String get tripManage => 'Manage trip';
  @override
  String get cashCollectNote => 'Collect cash offline on the trip.';
  @override
  String get cancelTrip => 'Cancel trip';
  @override
  String get cancelTripConfirm =>
      'This cancels the trip and all open bookings. Free until trip start.';
  @override
  String get tripCancelled => 'Trip cancelled';
  @override
  String get bookingsOnTrip => 'Bookings';
  @override
  String get noBookingsOnTrip =>
      'No bookings yet — share your trip offline if you like.';
  @override
  String get noTripsYet => 'No trips posted yet';
  @override
  String get errorCitiesRequired => 'Enter origin and destination';
  @override
  String get errorInvalidFare => 'Enter a valid fare';
  @override
  String get errorVehicleRequired => 'Enter car model, number plate, and color';
  @override
  String get errorPastDeparture => 'Departure must be in the future';
  @override
  String get helpTitle => 'Help & safety';
  @override
  String get helpSubtitle => 'Cash, cancel rules, support';
  @override
  String get cashHowTitle => 'How cash works';
  @override
  String get cashHowBody =>
      'You pay the driver in cash on the trip. Khalashi never takes, holds, or refunds money.';
  @override
  String get seatPrefHelpTitle => 'Seat preference';
  @override
  String get seatPrefHelpBody =>
      'Front / Window / Any is a request only — not a guaranteed seat map.';
  @override
  String get cancelHelpTitle => 'Free cancel until start';
  @override
  String get cancelHelpBody =>
      'Driver or traveller can cancel free until the trip starts. After start, cancel is not available in-app. No cash penalty in the app.';
  @override
  String get safetyTipsTitle => 'Safety tips';
  @override
  String get safetyTip1 =>
      "1. Share route, time, and the other person's phone with family or a friend.";
  @override
  String get safetyTip2 => '2. Meet in a public, well-lit place when you can.';
  @override
  String get safetyTip3 =>
      '3. Confirm booking details in the app before you get in.';
  @override
  String get safetyTip4 =>
      '4. Pay the listed cash fare; agree clearly before departure.';
  @override
  String get safetyTip5 =>
      '5. Cancel free until the trip starts if you feel uncomfortable.';
  @override
  String get safetyTip6 =>
      '6. If you feel unsafe, leave and call emergency services.';
  @override
  String get emergencyLine =>
      'If you are in immediate danger, call police / 112. Khalashi support helps with bookings — it is not an emergency response service.';
  @override
  String get disclaimerTitle => 'Important';
  @override
  String get disclaimerBody =>
      'Khalashi is a carpool marketplace, not a taxi. Users are not identity-verified (phone OTP only). Khalashi does not verify licences or vehicles and does not provide liability insurance. Seat preference is a request. Cash disputes are between the people on the trip.';
  @override
  String get operatorLine => 'Operated with Nitin Mote Tours & Travel.';
  @override
  String get supportTitle => 'Khalashi support';
  @override
  String get supportHours => 'Business hours — for booking help';
  @override
  String get supportWhatsApp => 'WhatsApp';
  @override
  String get supportPhone => 'Phone';
  @override
  String get copyWhatsApp => 'Copy WhatsApp number';
  @override
  String get copyPhone => 'Copy phone number';
  @override
  String get copied => 'Copied';
  @override
  String get supportStubNote =>
      'Replace stub numbers with your live ops WhatsApp/phone before launch.';
  @override
  String get supportOpenFailed => 'Could not open. Copy the number instead.';
  @override
  String get needHelpBooking => 'Need help with this booking?';
  @override
  String get safetyAndTerms => 'Safety & terms';
  @override
  String get bookMicroDisclaimer =>
      'Cash on trip · users not KYC-verified · not insured by Khalashi';
  @override
  String get errorGeneric => 'Something went wrong';
  @override
  String get errorNetworkHint => 'Check your connection and try again.';
  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';
  @override
  String get errorUnauthorized => 'Please sign in again.';
}
