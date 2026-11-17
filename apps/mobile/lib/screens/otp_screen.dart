import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/session_store.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.sessionStore,
    this.debugCode,
  });

  final String phone;
  final SessionStore sessionStore;
  final String? debugCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  final _api = AuthApi();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.verifyOtp(widget.phone, _controller.text.trim());
      final token = result['token'] as String;
      await widget.sessionStore.saveSession(token: token, phone: widget.phone);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(sessionStore: widget.sessionStore),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await _api.requestOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).resendOtp)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('+91 ${widget.phone}'),
            if (widget.debugCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dev OTP: ${widget.debugCode}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: l10n.otpHint,
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            TextButton(
              onPressed: _loading ? null : _resend,
              child: Text(l10n.resendOtp),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.verifyOtp),
            ),
          ],
        ),
      ),
    );
  }
}
