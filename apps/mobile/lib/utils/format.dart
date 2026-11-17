import 'package:intl/intl.dart';

final _dateFmt = DateFormat('dd MMM yyyy');
final _timeFmt = DateFormat('HH:mm');
final _dateTimeFmt = DateFormat('dd MMM yyyy · HH:mm');

String formatDate(DateTime dt) => _dateFmt.format(dt);
String formatTime(DateTime dt) => _timeFmt.format(dt);
String formatDateTime(DateTime dt) => _dateTimeFmt.format(dt);
String formatInr(int amount) => '₹$amount';

String ymd(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
