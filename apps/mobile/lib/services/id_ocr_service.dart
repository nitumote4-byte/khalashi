import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/verification.dart';

/// Lightweight on-device OCR hints for gov ID front photos.
/// Free ML Kit path — best-effort; user always edits fields before submit.
class IdOcrHints {
  const IdOcrHints({this.fullName, this.idNumber});

  final String? fullName;
  final String? idNumber;
}

class IdOcrService {
  TextRecognizer? _recognizer;

  TextRecognizer get _engine {
    return _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<IdOcrHints> extractHints({
    required String imagePath,
    required IdType idType,
  }) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await _engine.processImage(input);
      final text = result.text;
      if (text.trim().isEmpty) return const IdOcrHints();
      return IdOcrHints(
        fullName: _guessName(text),
        idNumber: _guessIdNumber(text, idType),
      );
    } catch (_) {
      // OCR is optional for soft launch — capture + manual fields still work.
      return const IdOcrHints();
    }
  }

  String? _guessIdNumber(String text, IdType idType) {
    final compact = text.replaceAll('\n', ' ');
    switch (idType) {
      case IdType.aadhaar:
        final m = RegExp(r'\b(\d{4}\s?\d{4}\s?\d{4})\b').firstMatch(compact);
        if (m != null) {
          final digits = m.group(1)!.replaceAll(RegExp(r'\s'), '');
          return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
        }
        break;
      case IdType.dl:
        final m = RegExp(
          r'\b([A-Z]{2}[-\s]?\d{2}[-\s]?\d{4}[-\s]?\d{7})\b',
          caseSensitive: false,
        ).firstMatch(compact);
        if (m != null) return m.group(1)!.toUpperCase().replaceAll(RegExp(r'\s+'), '');
        final loose = RegExp(r'\b([A-Z]{2}\d{2}\d{11,13})\b', caseSensitive: false)
            .firstMatch(compact.replaceAll(RegExp(r'[\s-]'), ''));
        if (loose != null) return loose.group(1)!.toUpperCase();
        break;
      case IdType.voter:
        final m = RegExp(r'\b([A-Z]{3}\d{7})\b', caseSensitive: false).firstMatch(compact);
        if (m != null) return m.group(1)!.toUpperCase();
        break;
    }
    return null;
  }

  String? _guessName(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.length >= 3)
        .toList();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('name') || lower.contains('naam')) {
        final afterColon = RegExp(r'[:：]\s*(.+)$').firstMatch(line)?.group(1);
        if (afterColon != null && _looksLikePersonName(afterColon)) {
          return _cleanName(afterColon);
        }
        if (i + 1 < lines.length && _looksLikePersonName(lines[i + 1])) {
          return _cleanName(lines[i + 1]);
        }
      }
    }

    for (final line in lines) {
      if (_looksLikePersonName(line) &&
          !RegExp(r'\d').hasMatch(line) &&
          line.length <= 60) {
        final skip = RegExp(
          r'(government|india|aadhaar|uidai|election|driving|licence|license|authority|dob|male|female)',
          caseSensitive: false,
        );
        if (skip.hasMatch(line)) continue;
        return _cleanName(line);
      }
    }
    return null;
  }

  bool _looksLikePersonName(String s) {
    final t = s.trim();
    if (t.length < 3 || t.length > 60) return false;
    if (!RegExp(r"^[A-Za-z][A-Za-z .']+$").hasMatch(t)) return false;
    final parts = t.split(RegExp(r'\s+'));
    return parts.length >= 2 || t.length >= 5;
  }

  String _cleanName(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

/// True when running where file-based ML Kit input is available.
bool get idOcrSupported => !Platform.isWindows && !Platform.isLinux;
