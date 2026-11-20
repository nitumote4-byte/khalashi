import 'app_localizations.dart';

class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'खलाशी';
  @override
  String get tagline => 'ट्रिप पोस्ट करें · सीट बुक करें · यात्रा पर नकद भुगतान';
  @override
  String get languageTitle => 'भाषा चुनें';
  @override
  String get languageHindi => 'हिंदी';
  @override
  String get languageEnglish => 'English';
  @override
  String get continueLabel => 'आगे बढ़ें';
  @override
  String get phoneTitle => 'आपका मोबाइल नंबर';
  @override
  String get phoneHint => '10 अंकों का मोबाइल';
  @override
  String get phonePrefix => '+91';
  @override
  String get sendOtp => 'OTP भेजें';
  @override
  String get otpTitle => 'OTP दर्ज करें';
  @override
  String get otpHint => '6 अंकों का कोड';
  @override
  String get verifyOtp => 'सत्यापित करें';
  @override
  String get resendOtp => 'OTP फिर भेजें';
  @override
  String get homeGreeting => 'आज कहाँ जाना है?';
  @override
  String get findRide => 'सवारी खोजें';
  @override
  String get offerRide => 'सवारी दें';
  @override
  String get findRideSubtitle => 'ट्रिप खोजें और सीट बुक करें';
  @override
  String get offerRideSubtitle => 'सीट और किराये के साथ ट्रिप पोस्ट करें';
  @override
  String get cashReminder =>
      'भुगतान यात्रा पर ड्राइवर को नकद — खलाशी पैसे नहीं लेता।';
  @override
  String get myBookings => 'मेरी बुकिंग';
  @override
  String get myTrips => 'मेरी ट्रिप';
  @override
  String get profile => 'प्रोफ़ाइल';
  @override
  String get logout => 'लॉग आउट';
  @override
  String get retry => 'फिर कोशिश करें';
  @override
  String get home => 'होम';
  @override
  String get origin => 'कहाँ से (शहर)';
  @override
  String get destination => 'कहाँ तक (शहर)';
  @override
  String get pickupPoint => 'पिकअप बिंदु';
  @override
  String get dropoffPoint => 'ड्रॉप-ऑफ़ बिंदु';
  @override
  String get pickupPointHelper => 'वैकल्पिक — मैप पर चिह्नित करें';
  @override
  String get dropoffPointHelper => 'वैकल्पिक — मैप पर चिह्नित करें';
  @override
  String get tapToMarkOnMap => 'मैप पर चिह्नित करने के लिए टैप करें';
  @override
  String get confirmPickup => 'पिकअप की पुष्टि करें';
  @override
  String get confirmDropoff => 'ड्रॉप-ऑफ़ की पुष्टि करें';
  @override
  String get leavingFromQuestion => 'आप कहाँ से निकल रहे हैं?';
  @override
  String get headingToQuestion => 'आप कहाँ जा रहे हैं?';
  @override
  String get cityOrMapHint => 'शहर खोजें या मैप पर सटीक जगह चुनें';
  @override
  String get chooseOnMap => 'मैप पर चुनें';
  @override
  String get confirmLeaving => 'प्रस्थान बिंदु की पुष्टि करें';
  @override
  String get confirmHeading => 'गंतव्य की पुष्टि करें';
  @override
  String get leavingPoint => 'प्रस्थान';
  @override
  String get headingPoint => 'गंतव्य';
  @override
  String get routePreviewTitle => 'आपका रूट';
  @override
  String get routeDistance => 'दूरी';
  @override
  String get routeDuration => 'यात्रा समय';
  @override
  String get routeEstimateFallback =>
      'अनुमानित — सड़क रूटिंग उपलब्ध नहीं, अनुमानित दूरी दिख रही है।';
  @override
  String get continueToTripDetails => 'ट्रिप विवरण पर जाएँ';
  @override
  String get editRoutePoints => 'स्थान संपादित करें';
  @override
  String get tripDetailsTitle => 'ट्रिप विवरण';
  @override
  String distanceKm(String km) => '$km किमी';
  @override
  String durationMinutesOnly(int minutes) => '$minutes मिनट';
  @override
  String durationHoursOnly(int hours) => '$hours घं';
  @override
  String durationHoursMinutes(int hours, int minutes) =>
      '$hours घं $minutes मिनट';
  @override
  String get errorPointsRequired => 'प्रस्थान और गंतव्य दोनों सेट करें';
  @override
  String get errorSamePoint => 'प्रस्थान और गंतव्य अलग-अलग होने चाहिए';
  @override
  String get mapPinHint => 'मैप घुमाएँ ताकि पिन सही जगह पर हो';
  @override
  String get mapPinMoving => 'जगह सेट करने के लिए छोड़ें…';
  @override
  String get mapPinLookingUp => 'पता खोज रहे हैं…';

  @override
  String get mapTilesUnavailable =>
      'मैप लोड नहीं हो सका। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get mapTilesRetry => 'फिर कोशिश करें';
  @override
  String get meetingPoints => 'मिलने के स्थान';
  @override
  String get recentCities => 'हाल ही में';
  @override
  String get suggestedCities => 'सुझाव';
  @override
  String get cityPickHint => 'सूची से शहर चुनें';
  @override
  String get cityNoMatchHint => 'कोई शहर नहीं मिला — दूसरी वर्तनी आज़माएँ';
  @override
  String get useCurrentLocation => 'वर्तमान स्थान उपयोग करें';
  @override
  String locationFilled(String city) => '$city सेट किया';
  @override
  String get locationServiceDisabled =>
      'लोकेशन सेवा चालू करें और फिर कोशिश करें';
  @override
  String get locationPermissionDenied => 'लोकेशन अनुमति अस्वीकृत';
  @override
  String get locationPermissionDeniedForever =>
      'इसके लिए सेटिंग्स में लोकेशन चालू करें';
  @override
  String get locationUnavailable => 'आपका स्थान नहीं मिल सका';
  @override
  String get errorCityNotInList =>
      'सूची से शहर चुनें (जैसे Patna, patn नहीं)';
  @override
  String get searchRides => 'सवारी खोजें';
  @override
  String get offerRideInstead => 'या सवारी दें';
  @override
  String get noRidesFound =>
      'इस तारीख पर कोई सवारी नहीं। दूसरी तारीख चुनें या सवारी दें।';
  @override
  String get changeDate => 'तारीख बदलें';
  @override
  String get full => 'भरी';
  @override
  String get seats => 'सीटें';
  @override
  String get seat => 'सीट';
  @override
  String get seatsLeft => 'सीटें बची';
  @override
  String get cashOnTrip => 'यात्रा पर नकद';
  @override
  String get tripDetail => 'ट्रिप';
  @override
  String get driver => 'ड्राइवर';
  @override
  String get seatPreferenceNote =>
      'अगले चरण में सीट पसंद चुनें — केवल अनुरोध, सीट मैप नहीं।';
  @override
  String get noSeatsLeft => 'कोई सीट नहीं बची';
  @override
  String get tripUnavailable => 'ट्रिप उपलब्ध नहीं';
  @override
  String get bookSeats => 'सीट बुक करें';
  @override
  String get preference => 'पसंद';
  @override
  String get prefFront => 'आगे';
  @override
  String get prefWindow => 'खिड़की';
  @override
  String get prefAny => 'कोई भी';
  @override
  String get seatPreferenceRequestOnly => 'सीट पसंद केवल अनुरोध है।';
  @override
  String get totalDue => 'कुल देय';
  @override
  String get confirmBooking => 'बुकिंग पुष्टि करें';
  @override
  String get bookingConfirmed => 'बुकिंग पुष्ट';
  @override
  String get bookingRef => 'बुकिंग संदर्भ';
  @override
  String get payCashWhenMeet => 'मिलने पर ड्राइवर को नकद दें।';
  @override
  String get viewBooking => 'बुकिंग देखें';
  @override
  String get upcoming => 'आगामी';
  @override
  String get past => 'पिछली';
  @override
  String get noBookingsYet => 'अभी कोई बुकिंग नहीं';
  @override
  String get bookingDetail => 'बुकिंग';
  @override
  String get statusConfirmed => 'पुष्ट';
  @override
  String get statusCancelled => 'रद्द';
  @override
  String get cancelBooking => 'बुकिंग रद्द करें';
  @override
  String get cancelBookingConfirm =>
      'ट्रिप शुरू होने तक मुफ़्त रद्दीकरण। सीटें वापस मिलेंगी।';
  @override
  String get bookingCancelled => 'बुकिंग रद्द हो गई';
  @override
  String get keep => 'रखें';
  @override
  String get confirmCancel => 'रद्द की पुष्टि';
  @override
  String get traveller => 'यात्री';
  @override
  String get seatsAvailable => 'उपलब्ध सीटें';
  @override
  String get farePerSeat => 'प्रति सीट किराया';
  @override
  String get youSetFare => 'किराया आप तय करते हैं';
  @override
  String get vehicleDetails => 'वाहन';
  @override
  String get carModel => 'कार मॉडल';
  @override
  String get numberPlate => 'नंबर प्लेट';
  @override
  String get carColor => 'रंग';
  @override
  String get cashDriverNote => 'यात्री यात्रा पर आपको नकद देंगे।';
  @override
  String get publishTrip => 'ट्रिप प्रकाशित करें';
  @override
  String get postSuccessTitle => 'ट्रिप प्रकाशित';
  @override
  String get tripManage => 'ट्रिप प्रबंधन';
  @override
  String get cashCollectNote => 'यात्रा पर नकद ऑफलाइन लें।';
  @override
  String get cancelTrip => 'ट्रिप रद्द करें';
  @override
  String get cancelTripConfirm =>
      'ट्रिप और सभी खुली बुकिंग रद्द होंगी। शुरू होने तक मुफ़्त।';
  @override
  String get tripCancelled => 'ट्रिप रद्द हो गई';
  @override
  String get bookingsOnTrip => 'बुकिंग';
  @override
  String get noBookingsOnTrip =>
      'अभी कोई बुकिंग नहीं — चाहें तो ऑफ़लाइन साझा करें।';
  @override
  String get noTripsYet => 'अभी कोई ट्रिप नहीं';
  @override
  String get errorCitiesRequired => 'शहर भरें';
  @override
  String get errorInvalidFare => 'मान्य किराया दर्ज करें';
  @override
  String get errorVehicleRequired => 'कार मॉडल, नंबर प्लेट और रंग भरें';
  @override
  String get errorPastDeparture => 'प्रस्थान भविष्य में होना चाहिए';
  @override
  String get helpTitle => 'मदद और सुरक्षा';
  @override
  String get helpSubtitle => 'नकद, रद्द नियम, सहायता';
  @override
  String get cashHowTitle => 'नकद कैसे काम करता है';
  @override
  String get cashHowBody =>
      'किराया यात्रा पर ड्राइवर को नकद दें। खलाशी पैसे नहीं लेता, रखता या लौटाता।';
  @override
  String get seatPrefHelpTitle => 'सीट पसंद';
  @override
  String get seatPrefHelpBody =>
      'आगे / खिड़की / कोई भी केवल अनुरोध है — गारंटीड सीट मैप नहीं।';
  @override
  String get cancelHelpTitle => 'शुरू होने तक मुफ़्त रद्द';
  @override
  String get cancelHelpBody =>
      'ड्राइवर या यात्री यात्रा शुरू होने तक मुफ़्त रद्द कर सकते हैं। शुरू के बाद ऐप में रद्द नहीं। ऐप में कोई नकद जुर्माना नहीं।';
  @override
  String get safetyTipsTitle => 'सुरक्षा सुझाव';
  @override
  String get safetyTip1 =>
      '1. रूट, समय और दूसरे पक्ष का फ़ोन परिवार/मित्र से साझा करें।';
  @override
  String get safetyTip2 => '2. जहाँ संभव हो, सार्वजनिक और रोशन जगह पर मिलें।';
  @override
  String get safetyTip3 => '3. चढ़ने से पहले ऐप में बुकिंग विवरण जाँचें।';
  @override
  String get safetyTip4 =>
      '4. सूचीबद्ध नकद किराया दें; रवाना होने से पहले साफ़ सहमति लें।';
  @override
  String get safetyTip5 =>
      '5. असहज लगने पर यात्रा शुरू होने तक मुफ़्त रद्द करें।';
  @override
  String get safetyTip6 =>
      '6. असुरक्षित लगने पर स्थिति छोड़ें और आपातकालीन सेवाएँ कॉल करें।';
  @override
  String get emergencyLine =>
      'तुरंत खतरे में हों तो पुलिस / 112 कॉल करें। खलाशी सहायता बुकिंग के लिए है — आपातकालीन सेवा नहीं।';
  @override
  String get disclaimerTitle => 'ज़रूरी';
  @override
  String get disclaimerBody =>
      'खलाशी कारपूल बाज़ार है, टैक्सी नहीं। उपयोगकर्ता पहचान-सत्यापित नहीं (केवल फ़ोन OTP)। खलाशी लाइसेंस/वाहन जाँच या देयता बीमा नहीं देता। सीट पसंद अनुरोध है। नकद विवाद यात्रा पर लोगों के बीच हैं।';
  @override
  String get operatorLine => 'Nitin Mote Tours & Travel के साथ संचालित।';
  @override
  String get supportTitle => 'खलाशी सहायता';
  @override
  String get supportHours => 'कार्य समय — बुकिंग मदद के लिए';
  @override
  String get supportWhatsApp => 'व्हाट्सऐप';
  @override
  String get supportPhone => 'फ़ोन';
  @override
  String get copyWhatsApp => 'व्हाट्सऐप नंबर कॉपी करें';
  @override
  String get copyPhone => 'फ़ोन नंबर कॉपी करें';
  @override
  String get copied => 'कॉपी हो गया';
  @override
  String get supportStubNote =>
      'लॉन्च से पहले स्टब नंबर को असली ऑप्स व्हाट्सऐप/फ़ोन से बदलें।';
  @override
  String get supportOpenFailed => 'खोल नहीं सके। नंबर कॉपी करें।';
  @override
  String get needHelpBooking => 'इस बुकिंग में मदद चाहिए?';
  @override
  String get safetyAndTerms => 'सुरक्षा और शर्तें';
  @override
  String get bookMicroDisclaimer =>
      'यात्रा पर नकद · KYC नहीं · खलाशी बीमा नहीं';
  @override
  String get errorGeneric => 'कुछ गलत हुआ';
  @override
  String get errorNetworkHint => 'कनेक्शन जाँचें और फिर कोशिश करें।';
  @override
  String get errorRateLimited => 'बहुत अनुरोध। थोड़ी देर बाद कोशिश करें।';
  @override
  String get errorUnauthorized => 'फिर साइन इन करें।';
  @override
  String get verifyIdTitle => 'पहचान सत्यापन';
  @override
  String get verifyIdCta => 'आईडी सत्यापित करें';
  @override
  String get verifyIdIntro =>
      'आधार, ड्राइविंग लाइसेंस या वोटर आईडी का सामने वाला फ़ोटो लें, फिर साफ़ सेल्फ़ी लें। हम मैन्युअल मिलाते हैं — DigiLocker या पेड फेस API नहीं। सवारी ढूँढना खुला रहता है; सवारी ऑफ़र करने के लिए आईडी जमा करनी होगी।';
  @override
  String get verifyIdType => 'आईडी प्रकार';
  @override
  String get idTypeAadhaar => 'आधार';
  @override
  String get idTypeDl => 'डीएल';
  @override
  String get idTypeVoter => 'वोटर';
  @override
  String get verifyPhotoHint => 'सरकारी आईडी का सामने वाला फ़ोटो लें';
  @override
  String get verifyCapture => 'कैमरा';
  @override
  String get verifyGallery => 'गैलरी';
  @override
  String get verifyFullName => 'आईडी पर नाम';
  @override
  String get verifyIdNumber => 'आईडी नंबर';
  @override
  String get verifyManualEditHint =>
      'OCR भर सकता है — जमा करने से पहले जाँचें और सुधारें।';
  @override
  String get verifySelfieTitle => 'सेल्फ़ी लें';
  @override
  String get verifySelfieGuidance =>
      'सामने वाले कैमरे की ओर सीधा देखें। चेहरा पूरा दिखे, अच्छी रोशनी हो, धूप का चश्मा या मास्क न हो — ताकि हम आपकी आईडी फ़ोटो से मिला सकें।';
  @override
  String get verifySelfieHint => 'सामने वाले कैमरे से सेल्फ़ी ज़रूरी है';
  @override
  String get verifyTakeSelfie => 'सेल्फ़ी लें';
  @override
  String get verifyRetakeSelfie => 'सेल्फ़ी फिर लें';
  @override
  String get verifyNeedSelfie =>
      'जमा करने से पहले साफ़ फ्रंट-कैमरा सेल्फ़ी लें';
  @override
  String get verifySubmit => 'समीक्षा के लिए जमा करें';
  @override
  String get verifySubmitted => 'जमा हो गया — समीक्षा लंबित';
  @override
  String get verifyNeedPhoto => 'पहले आईडी फ़ोटो लें या चुनें';
  @override
  String get verifyNeedFields => 'नाम और आईडी नंबर भरें';
  @override
  String get verifyBadgeUnverified => 'असत्यापित';
  @override
  String get verifyBadgePending => 'समीक्षा लंबित';
  @override
  String get verifyBadgeVerified => 'सत्यापित';
  @override
  String get verifyBadgeRejected => 'अस्वीकृत';
  @override
  String get verifyRequiredTitle => 'पहले आईडी सत्यापित करें';
  @override
  String get verifyRequiredBody =>
      'सवारी ऑफ़र करने के लिए सरकारी आईडी फ़ोटो और सेल्फ़ी जमा करें। बिना इसके सवारी ढूँढना और बुक करना चलता रहेगा।';
  @override
  String get offerRideNeedsVerify =>
      'पहले आईडी जमा करें — फिर ट्रिप पोस्ट करें';
  @override
  String get cameraPermissionDenied =>
      'आईडी फ़ोटो और सेल्फ़ी के लिए कैमरा अनुमति चाहिए';
  @override
  String get ocrFilledHint => 'OCR ने जो पढ़ा भर दिया — कृपया जाँच लें।';
  @override
  String get ocrNoTextHint =>
      'टेक्स्ट नहीं पढ़ा — नाम और आईडी नंबर खुद भरें।';
  @override
  String get ocrUnavailable =>
      'यहाँ ऑन-डिवाइस OCR उपलब्ध नहीं — फ़ील्ड खुद भरें।';
  @override
  String get notNow => 'अभी नहीं';
  @override
  String get emergencyContactTitle => 'आपातकालीन संपर्क';
  @override
  String get emergencyContactSubtitle =>
      'SOS के लिए सेव — एक टैप में कॉल करें और यात्रा साझा करें।';
  @override
  String get emergencyContactName => 'संपर्क का नाम';
  @override
  String get emergencyContactNameHint => 'परिवार या मित्र';
  @override
  String get emergencyContactPhone => 'संपर्क फ़ोन';
  @override
  String get emergencyContactSave => 'आपातकालीन संपर्क सेव करें';
  @override
  String get emergencyContactSaving => 'सेव हो रहा है…';
  @override
  String get emergencyContactSaved => 'आपातकालीन संपर्क सेव हो गया';
  @override
  String get emergencyContactCleared => 'आपातकालीन संपर्क हटा दिया';
  @override
  String get emergencyContactClear => 'संपर्क हटाएँ';
  @override
  String get emergencyContactNeedBoth =>
      'नाम और फ़ोन दोनों भरें, या दोनों खाली छोड़ें।';
  @override
  String get emergencyContactInvalidPhone =>
      'मान्य 10 अंकों का भारतीय मोबाइल नंबर दर्ज करें।';
  @override
  String get sosButton => 'SOS';
  @override
  String get sosTitle => 'अभी मदद चाहिए?';
  @override
  String get sosSubtitle =>
      'अपने आपातकालीन संपर्क को कॉल करें, यह यात्रा साझा करें, या भारत आपातकाल 112 डायल करें। खलाशी आपातकालीन प्रतिक्रिया सेवा नहीं है।';
  @override
  String get sosCallContact => 'आपातकालीन संपर्क कॉल करें';
  @override
  String sosCallContactNamed(String name) => '$name को कॉल करें';
  @override
  String get sosNoContact => 'पहले प्रोफ़ाइल में आपातकालीन संपर्क जोड़ें।';
  @override
  String get sosShareTrip => 'यात्रा सारांश साझा करें';
  @override
  String get sosShareSubject => 'खलाशी यात्रा';
  @override
  String get sosShareHeadline => 'खलाशी यात्रा — मैं इस सवारी पर हूँ:';
  @override
  String get sosShareFooter =>
      'खतरे में हों तो 112 कॉल करें। यह स्थिति साझा है, लाइव ट्रैकिंग नहीं।';
  @override
  String get sosCall112 => '112 कॉल करें (भारत आपातकाल)';
  @override
  String get sosDisclaimer =>
      'मुफ़्त सॉफ्ट-लॉन्च SOS — कोई पेड SMS नहीं। शेयर आपके फ़ोन की शेयर शीट इस्तेमाल करता है (व्हाट्सऐप, संदेश आदि)।';
  @override
  String get yourRating => 'आपकी रेटिंग';
  @override
  String get ratingCta => 'इस उपयोगकर्ता को रेट करें';
  @override
  String get ratingTitle => 'रेटिंग दें';
  @override
  String ratingSubtitle(String name) => '$name के साथ आपकी यात्रा कैसी रही?';
  @override
  String get ratingCommentOptional => 'टिप्पणी (वैकल्पिक)';
  @override
  String get ratingSubmit => 'रेटिंग भेजें';
  @override
  String get ratingSubmitting => 'भेज रहा है…';
  @override
  String get ratingSubmitted => 'धन्यवाद — रेटिंग सेव हो गई';
  @override
  String get ratingPickStars => '1 से 5 स्टार चुनें';
  @override
  String ratingYourStars(int stars) => 'आपने $stars★ दिए';
  @override
  String get reportOrBlock => 'रिपोर्ट या ब्लॉक';
  @override
  String get reportUser => 'उपयोगकर्ता रिपोर्ट करें';
  @override
  String reportUserSubtitle(String name) =>
      '$name के साथ क्या गलत हुआ, बताएँ';
  @override
  String get reportReason => 'कारण';
  @override
  String get reportReasonHarassment => 'उत्पीड़न / गाली-गलौज';
  @override
  String get reportReasonUnsafe => 'असुरक्षित ड्राइविंग';
  @override
  String get reportReasonNoShow => 'नहीं आए';
  @override
  String get reportReasonSpam => 'स्पैम / नकली यात्रा';
  @override
  String get reportReasonFraud => 'धोखा / भुगतान समस्या';
  @override
  String get reportReasonOther => 'अन्य';
  @override
  String get reportDetailsOptional => 'विवरण (वैकल्पिक)';
  @override
  String get reportSubmit => 'रिपोर्ट भेजें';
  @override
  String get reportSubmitting => 'भेज रहा है…';
  @override
  String get reportSubmitted => 'रिपोर्ट समीक्षा के लिए भेज दी गई';
  @override
  String get reportPickReason => 'कारण चुनें';
  @override
  String get blockUser => 'ब्लॉक करें';
  @override
  String get blockUserHint =>
      'वे आपकी यात्राएँ नहीं देखेंगे और आपके साथ बुक नहीं कर सकेंगे';
  @override
  String blockUserConfirm(String name) =>
      '$name को ब्लॉक करें? आप एक-दूसरे की यात्राएँ या बुकिंग नहीं देखेंगे।';
  @override
  String get blockUserDone => 'उपयोगकर्ता ब्लॉक हो गया';
  @override
  String get unblockUser => 'अनब्लॉक';
  @override
  String get unblockUserDone => 'उपयोगकर्ता अनब्लॉक हो गया';
  @override
  String get blockedUsersTitle => 'ब्लॉक किए गए उपयोगकर्ता';
  @override
  String get blockedUsersSubtitle =>
      'जिन्हें आपने ब्लॉक किया है, प्रबंधित करें';
  @override
  String get blockedUsersEmpty => 'आपने अभी तक किसी को ब्लॉक नहीं किया';
}
