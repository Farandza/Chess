import 'dart:async';

import 'package:flutter/material.dart';

import '../models/invitation.dart';
import '../services/game_service.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final _gameService = GameService();
  final _actingOn = <String>{};
  List<Invitation> _invitations = const [];
  Timer? _refreshTimer;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(showSpinner: true);
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner && mounted) setState(() => _loading = true);
    try {
      final invitations = await _gameService.getInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = invitations;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _decline(Invitation invite) async {
    if (_actingOn.contains(invite.id)) return;
    _actingOn.add(invite.id);
    try {
      await _gameService.declineInvite(invite.id);
      await _load();
    } catch (error) {
      _showError(error);
    } finally {
      _actingOn.remove(invite.id);
    }
  }

  Future<void> _accept(Invitation invite) async {
    if (_actingOn.contains(invite.id)) return;
    _actingOn.add(invite.id);
    try {
      final game = await _gameService.acceptInvite(invite.id);
      if (!mounted) return;
      await Navigator.pushNamed(context, '/game', arguments: game);
      await _load();
    } catch (error) {
      _showError(error);
    } finally {
      _actingOn.remove(invite.id);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Invitations')),
        body: RefreshIndicator(onRefresh: _load, child: _content(context)),
      );

  Widget _content(BuildContext context) {
    if (_loading && _invitations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _invitations.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 130),
        Center(
            child: Text('Could not load invitations\n$_error',
                textAlign: TextAlign.center)),
      ]);
    }
    if (_invitations.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.mail_outline_rounded,
            size: 54, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 14),
        Center(
          child: Text('No pending invitations',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('New invitations will appear here automatically.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _invitations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final invite = _invitations[index];
        final acting = _actingOn.contains(invite.id);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(invite.fromUser.isEmpty
                      ? '?'
                      : invite.fromUser[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${invite.fromUser} invited you to play',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 12),
              Text('${invite.minutes}-minute chess game',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton.icon(
                  onPressed: acting ? null : () => _decline(invite),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: acting ? null : () => _accept(invite),
                  icon: acting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(acting ? 'Please wait…' : 'Accept'),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
