/// Operator support stubs for soft launch (Nitin Mote Tours & Travel / Khalashi).
/// Replace with real WhatsApp Business + phone before Play publish.
/// See project docs/dispute-safety.md — exact numbers are an operator open item.
class SupportContacts {
  SupportContacts._();

  /// WhatsApp Business (primary mediation channel). Digits only after country code for wa.me.
  static const whatsappE164 = '+919999000001';
  static const whatsappDisplay = '+91 99990 00001';

  /// Secondary phone for booking help (not an emergency line).
  static const phoneE164 = '+919999000002';
  static const phoneDisplay = '+91 99990 00002';

  static const businessHoursNote = 'Business hours — booking help only';

  static Uri whatsappUri({String? bookingRef}) {
    final digits = whatsappE164.replaceAll(RegExp(r'\D'), '');
    final text = bookingRef == null || bookingRef.isEmpty
        ? 'Hello Khalashi support — I need help with a booking.'
        : 'Hello Khalashi support — booking ref $bookingRef';
    return Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(text)}',
    );
  }

  static Uri phoneUri() => Uri.parse('tel:$phoneE164');
}
