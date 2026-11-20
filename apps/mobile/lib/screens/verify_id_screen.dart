import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/verification.dart';
import '../services/api_client.dart';
import '../services/id_ocr_service.dart';
import '../services/session_store.dart';
import '../theme/khalashi_theme.dart';

class VerifyIdScreen extends StatefulWidget {
  const VerifyIdScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<VerifyIdScreen> createState() => _VerifyIdScreenState();
}

class _VerifyIdScreenState extends State<VerifyIdScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  final _ocr = IdOcrService();
  final _name = TextEditingController();
  final _idNumber = TextEditingController();
  final _picker = ImagePicker();

  IdType _idType = IdType.aadhaar;
  String? _imagePath;
  String? _selfiePath;
  VerificationInfo? _current;
  bool _loading = true;
  bool _submitting = false;
  bool _ocrBusy = false;
  String? _error;
  String? _ocrNote;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _idNumber.dispose();
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _api.getVerification();
      if (!mounted) return;
      setState(() {
        _current = info;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : AppLocalizations.of(context).errorGeneric;
      });
    }
  }

  Future<void> _capture() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _ocrNote = null;
    });
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      setState(() {
        _imagePath = file.path;
      });
      await _runOcr(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.cameraPermissionDenied);
    }
  }

  Future<void> _pickGallery() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _ocrNote = null;
    });
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (file == null) return;
      setState(() => _imagePath = file.path);
      await _runOcr(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.errorGeneric);
    }
  }

  Future<void> _captureSelfie() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return;
      setState(() => _selfiePath = file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.cameraPermissionDenied);
    }
  }

  Future<void> _runOcr(String path) async {
    if (!idOcrSupported) {
      setState(() => _ocrNote = AppLocalizations.of(context).ocrUnavailable);
      return;
    }
    setState(() => _ocrBusy = true);
    final hints = await _ocr.extractHints(imagePath: path, idType: _idType);
    if (!mounted) return;
    setState(() {
      _ocrBusy = false;
      if (hints.fullName != null && _name.text.trim().isEmpty) {
        _name.text = hints.fullName!;
      }
      if (hints.idNumber != null && _idNumber.text.trim().isEmpty) {
        _idNumber.text = hints.idNumber!;
      }
      _ocrNote = (hints.fullName != null || hints.idNumber != null)
          ? AppLocalizations.of(context).ocrFilledHint
          : AppLocalizations.of(context).ocrNoTextHint;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final path = _imagePath;
    final selfie = _selfiePath;
    if (path == null) {
      setState(() => _error = l10n.verifyNeedPhoto);
      return;
    }
    if (_name.text.trim().length < 2 || _idNumber.text.trim().length < 4) {
      setState(() => _error = l10n.verifyNeedFields);
      return;
    }
    if (selfie == null) {
      setState(() => _error = l10n.verifyNeedSelfie);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final idBytes = await File(path).readAsBytes();
      final selfieBytes = await File(selfie).readAsBytes();
      final info = await _api.submitVerification(
        idType: _idType,
        fullName: _name.text.trim(),
        idNumber: _idNumber.text.trim(),
        imageBase64: base64Encode(idBytes),
        selfieBase64: base64Encode(selfieBytes),
      );
      if (!mounted) return;
      setState(() {
        _current = info;
        _submitting = false;
        _imagePath = null;
        _selfiePath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verifySubmitted)),
      );
      Navigator.of(context).pop(info);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e is ApiException ? e.message : l10n.errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _current?.status ?? VerificationStatus.unverified;
    final canSubmit = status == VerificationStatus.unverified ||
        status == VerificationStatus.rejected;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyIdTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                _StatusBanner(status: status, note: _current?.reviewNote),
                const SizedBox(height: 16),
                Text(
                  l10n.verifyIdIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KhalashiColors.dusk.withOpacity(0.85),
                      ),
                ),
                if (!canSubmit) ...[
                  const SizedBox(height: 24),
                  if (_current?.fullName != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.verifyFullName),
                      subtitle: Text(_current!.fullName!),
                    ),
                  if (_current?.idNumberMasked != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.verifyIdNumber),
                      subtitle: Text(_current!.idNumberMasked!),
                    ),
                ] else ...[
                  const SizedBox(height: 20),
                  Text(l10n.verifyIdType, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<IdType>(
                    segments: [
                      ButtonSegment(value: IdType.aadhaar, label: Text(l10n.idTypeAadhaar)),
                      ButtonSegment(value: IdType.dl, label: Text(l10n.idTypeDl)),
                      ButtonSegment(value: IdType.voter, label: Text(l10n.idTypeVoter)),
                    ],
                    selected: {_idType},
                    onSelectionChanged: (set) {
                      setState(() => _idType = set.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_imagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 160,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KhalashiColors.deepTeal.withOpacity(0.2)),
                      ),
                      child: Text(
                        l10n.verifyPhotoHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: KhalashiColors.dusk.withOpacity(0.7)),
                      ),
                    ),
                  if (_ocrBusy)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_ocrNote != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _ocrNote!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: KhalashiColors.dusk.withOpacity(0.75),
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _capture,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l10n.verifyCapture),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l10n.verifyGallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.verifyFullName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _idNumber,
                    decoration: InputDecoration(
                      labelText: l10n.verifyIdNumber,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.verifyManualEditHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KhalashiColors.dusk.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.verifySelfieTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.verifySelfieGuidance,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KhalashiColors.dusk.withOpacity(0.85),
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_selfiePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selfiePath!),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 160,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KhalashiColors.deepTeal.withOpacity(0.2)),
                      ),
                      child: Text(
                        l10n.verifySelfieHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: KhalashiColors.dusk.withOpacity(0.7)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _captureSelfie,
                    icon: const Icon(Icons.camera_front_outlined),
                    label: Text(
                      _selfiePath == null
                          ? l10n.verifyTakeSelfie
                          : l10n.verifyRetakeSelfie,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.verifySubmit),
                  ),
                ],
                if (_error != null && !canSubmit) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, this.note});

  final VerificationStatus status;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color, icon) = switch (status) {
      VerificationStatus.verified => (
          l10n.verifyBadgeVerified,
          const Color(0xFF1B7A4E),
          Icons.verified_outlined,
        ),
      VerificationStatus.pendingReview => (
          l10n.verifyBadgePending,
          KhalashiColors.saffron,
          Icons.hourglass_top_outlined,
        ),
      VerificationStatus.rejected => (
          l10n.verifyBadgeRejected,
          const Color(0xFFB3261E),
          Icons.cancel_outlined,
        ),
      VerificationStatus.unverified => (
          l10n.verifyBadgeUnverified,
          KhalashiColors.dusk.withOpacity(0.65),
          Icons.badge_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
