import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/trust.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../widgets/async_state.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late final ApiClient _api = ApiClient(sessionStore: widget.sessionStore);
  late Future<List<BlockedUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.myBlocks();
  }

  void _reload() => setState(() => _future = _api.myBlocks());

  Future<void> _unblock(BlockedUser u) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _api.unblockUser(u.blockedUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unblockUserDone)),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsersTitle)),
      body: FutureBuilder<List<BlockedUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorState(error: snap.error!, onRetry: _reload);
          }
          final blocks = snap.data ?? [];
          if (blocks.isEmpty) {
            return EmptyState(
              message: l10n.blockedUsersEmpty,
              icon: Icons.block,
            );
          }
          return ListView.separated(
            itemCount: blocks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = blocks[i];
              return ListTile(
                title: Text(u.label),
                subtitle: u.phone != null && u.displayName != null
                    ? Text(u.phone!)
                    : null,
                trailing: TextButton(
                  onPressed: () => _unblock(u),
                  child: Text(l10n.unblockUser),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
