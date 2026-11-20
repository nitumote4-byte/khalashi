import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trust.dart';
import '../services/api_client.dart';

Future<void> showReportBlockSheet({
  required BuildContext context,
  required ApiClient api,
  required String userId,
  required String userLabel,
  String? tripId,
  String? bookingId,
  VoidCallback? onBlocked,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(AppLocalizations.of(ctx).reportUser),
            onTap: () async {
              Navigator.pop(ctx);
              await showReportUserSheet(
                context: context,
                api: api,
                reportedUserId: userId,
                userLabel: userLabel,
                tripId: tripId,
                bookingId: bookingId,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: Text(AppLocalizations.of(ctx).blockUser),
            subtitle: Text(AppLocalizations.of(ctx).blockUserHint),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await showDialog<bool>(
                context: context,
                builder: (dCtx) {
                  final l10n = AppLocalizations.of(dCtx);
                  return AlertDialog(
                    title: Text(l10n.blockUser),
                    content: Text(l10n.blockUserConfirm(userLabel)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: Text(l10n.keep),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: Text(l10n.blockUser),
                      ),
                    ],
                  );
                },
              );
              if (ok != true || !context.mounted) return;
              try {
                await api.blockUser(userId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).blockUserDone)),
                );
                onBlocked?.call();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showReportUserSheet({
  required BuildContext context,
  required ApiClient api,
  required String reportedUserId,
  required String userLabel,
  String? tripId,
  String? bookingId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ReportUserSheet(
      api: api,
      reportedUserId: reportedUserId,
      userLabel: userLabel,
      tripId: tripId,
      bookingId: bookingId,
    ),
  );
}

class _ReportUserSheet extends StatefulWidget {
  const _ReportUserSheet({
    required this.api,
    required this.reportedUserId,
    required this.userLabel,
    this.tripId,
    this.bookingId,
  });

  final ApiClient api;
  final String reportedUserId;
  final String userLabel;
  final String? tripId;
  final String? bookingId;

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  ReportReason? _reason;
  final _detailsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, ReportReason r) => switch (r) {
        ReportReason.harassment => l10n.reportReasonHarassment,
        ReportReason.unsafeDriving => l10n.reportReasonUnsafe,
        ReportReason.noShow => l10n.reportReasonNoShow,
        ReportReason.spam => l10n.reportReasonSpam,
        ReportReason.fraud => l10n.reportReasonFraud,
        ReportReason.other => l10n.reportReasonOther,
      };

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportPickReason)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.api.reportUser(
        reportedUserId: widget.reportedUserId,
        reason: _reason!,
        details: _detailsCtrl.text.trim().isEmpty ? null : _detailsCtrl.text.trim(),
        tripId: widget.tripId,
        bookingId: widget.bookingId,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final submitted = l10n.reportSubmitted;
      Navigator.pop(context);
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
          Text(l10n.reportUser, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l10n.reportUserSubtitle(widget.userLabel)),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReportReason>(
            value: _reason,
            decoration: InputDecoration(labelText: l10n.reportReason),
            items: ReportReason.values
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(_reasonLabel(l10n, r)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _reason = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsCtrl,
            maxLength: 1000,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.reportDetailsOptional,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? l10n.reportSubmitting : l10n.reportSubmit),
          ),
        ],
      ),
    );
  }
}
