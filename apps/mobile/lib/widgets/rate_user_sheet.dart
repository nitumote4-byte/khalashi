import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import 'star_rating.dart';

Future<bool> showRateUserSheet({
  required BuildContext context,
  required ApiClient api,
  required String bookingId,
  required String rateeLabel,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _RateUserSheet(
      api: api,
      bookingId: bookingId,
      rateeLabel: rateeLabel,
    ),
  );
  return result == true;
}

class _RateUserSheet extends StatefulWidget {
  const _RateUserSheet({
    required this.api,
    required this.bookingId,
    required this.rateeLabel,
  });

  final ApiClient api;
  final String bookingId;
  final String rateeLabel;

  @override
  State<_RateUserSheet> createState() => _RateUserSheetState();
}

class _RateUserSheetState extends State<_RateUserSheet> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_stars < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingPickStars)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.api.submitRating(
        bookingId: widget.bookingId,
        stars: _stars,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final submitted = l10n.ratingSubmitted;
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(submitted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ratingTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(l10n.ratingSubtitle(widget.rateeLabel)),
          const SizedBox(height: 12),
          StarRatingInput(
            value: _stars,
            onChanged: (v) => setState(() => _stars = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.ratingCommentOptional,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? l10n.ratingSubmitting : l10n.ratingSubmit),
          ),
        ],
      ),
    );
  }
}
