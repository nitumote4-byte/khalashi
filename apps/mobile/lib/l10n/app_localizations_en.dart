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
  String get leavingFromQuestion => 'Where are you leaving from?';
  @override
  String get headingToQuestion => 'Where are you heading?';
  @override
  String get cityOrMapHint => 'Search a city or choose an exact spot on the map';
  @override
  String get chooseOnMap => 'Choose on map';
  @override
  String get confirmLeaving => 'Confirm leaving point';
  @override
  String get confirmHeading => 'Confirm destination';
  @override
  String get leavingPoint => 'Leaving from';
  @override
  String get headingPoint => 'Heading to';
  @override
  String get routePreviewTitle => 'Your route';
  @override
  String get routeDistance => 'Distance';
  @override
  String get routeDuration => 'Travel time';
  @override
  String get routeEstimateFallback =>
      'Approximate — road routing unavailable, showing estimated distance.';
  @override
  String get continueToTripDetails => 'Continue to trip details';
  @override
  String get editRoutePoints => 'Edit locations';
  @override
  String get tripDetailsTitle => 'Trip details';
  @override
  String distanceKm(String km) => '$km km';
  @override
  String durationMinutesOnly(int minutes) => '$minutes min';
  @override
  String durationHoursOnly(int hours) => '$hours h';
  @override
  String durationHoursMinutes(int hours, int minutes) =>
      '$hours h $minutes min';
  @override
  String get errorPointsRequired => 'Set both leaving and heading points';
  @override
  String get errorSamePoint =>
      'Leaving and heading points must be farther apart';
  @override
  String get mapPinHint => 'Move the map so the pin sits on the exact spot';
  @override
  String get mapPinMoving => 'Release to set location…';
  @override
  String get mapPinLookingUp => 'Looking up address…';

  @override
  String get mapTilesUnavailable =>
      'Map couldn’t load. Check your connection and try again.';

  @override
  String get mapTilesRetry => 'Retry';
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
  @override
  String get verifyIdTitle => 'ID verification';
  @override
  String get verifyIdCta => 'Verify ID';
  @override
  String get verifyIdIntro =>
      'Photograph the front of your Aadhaar, driving licence, or voter ID, then take a clear selfie. We match them manually — no DigiLocker or paid face API. Find a ride stays open; Offer a ride needs a submitted ID.';
  @override
  String get verifyIdType => 'ID type';
  @override
  String get idTypeAadhaar => 'Aadhaar';
  @override
  String get idTypeDl => 'DL';
  @override
  String get idTypeVoter => 'Voter';
  @override
  String get verifyPhotoHint => 'Capture the front of your government ID';
  @override
  String get verifyCapture => 'Camera';
  @override
  String get verifyGallery => 'Gallery';
  @override
  String get verifyFullName => 'Name on ID';
  @override
  String get verifyIdNumber => 'ID number';
  @override
  String get verifyManualEditHint =>
      'OCR may autofill — please check and edit before submit.';
  @override
  String get verifySelfieTitle => 'Take a selfie';
  @override
  String get verifySelfieGuidance =>
      'Look straight at the front camera. Face fully visible, good light, no sunglasses or mask — so we can match you to your ID photo.';
  @override
  String get verifySelfieHint => 'Front-camera selfie required';
  @override
  String get verifyTakeSelfie => 'Take selfie';
  @override
  String get verifyRetakeSelfie => 'Retake selfie';
  @override
  String get verifyNeedSelfie =>
      'Take a clear front-camera selfie before submit';
  @override
  String get verifySubmit => 'Submit for review';
  @override
  String get verifySubmitted => 'Submitted — pending review';
  @override
  String get verifyNeedPhoto => 'Capture or choose an ID photo first';
  @override
  String get verifyNeedFields => 'Enter name and ID number';
  @override
  String get verifyBadgeUnverified => 'Unverified';
  @override
  String get verifyBadgePending => 'Pending review';
  @override
  String get verifyBadgeVerified => 'Verified';
  @override
  String get verifyBadgeRejected => 'Rejected';
  @override
  String get verifyRequiredTitle => 'Verify your ID first';
  @override
  String get verifyRequiredBody =>
      'To offer a ride, submit a government ID photo and selfie for manual review. You can still find and book rides without it.';
  @override
  String get offerRideNeedsVerify => 'Submit ID first — then post a trip';
  @override
  String get cameraPermissionDenied =>
      'Camera permission needed for ID photo and selfie';
  @override
  String get ocrFilledHint =>
      'OCR filled what it could — please confirm the fields.';
  @override
  String get ocrNoTextHint =>
      'Couldn’t read text — enter name and ID number manually.';
  @override
  String get ocrUnavailable =>
      'On-device OCR isn’t available here — enter fields manually.';
  @override
  String get notNow => 'Not now';
  @override
  String get emergencyContactTitle => 'Emergency contact';
  @override
  String get emergencyContactSubtitle =>
      'Saved for SOS — call this person and share your trip in one tap.';
  @override
  String get emergencyContactName => 'Contact name';
  @override
  String get emergencyContactNameHint => 'Family or friend';
  @override
  String get emergencyContactPhone => 'Contact phone';
  @override
  String get emergencyContactSave => 'Save emergency contact';
  @override
  String get emergencyContactSaving => 'Saving…';
  @override
  String get emergencyContactSaved => 'Emergency contact saved';
  @override
  String get emergencyContactCleared => 'Emergency contact cleared';
  @override
  String get emergencyContactClear => 'Clear contact';
  @override
  String get emergencyContactNeedBoth =>
      'Enter both name and phone, or clear both.';
  @override
  String get emergencyContactInvalidPhone =>
      'Enter a valid 10-digit Indian mobile number.';
  @override
  String get sosButton => 'SOS';
  @override
  String get sosTitle => 'Need help now?';
  @override
  String get sosSubtitle =>
      'Call your emergency contact, share this trip, or dial India emergency 112. Khalashi is not an emergency response service.';
  @override
  String get sosCallContact => 'Call emergency contact';
  @override
  String sosCallContactNamed(String name) => 'Call $name';
  @override
  String get sosNoContact => 'Add an emergency contact in Profile first.';
  @override
  String get sosShareTrip => 'Share trip summary';
  @override
  String get sosShareSubject => 'Khalashi trip';
  @override
  String get sosShareHeadline => "Khalashi trip — I'm on this ride:";
  @override
  String get sosShareFooter =>
      'In danger, call 112. This is a status share, not live tracking.';
  @override
  String get sosCall112 => 'Call 112 (India emergency)';
  @override
  String get sosDisclaimer =>
      'Free soft-launch SOS — no paid SMS. Share uses your phone’s share sheet (WhatsApp, Messages, etc.).';
}
