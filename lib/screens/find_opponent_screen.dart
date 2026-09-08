import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/websocket_service.dart';
import '../models/game.dart';

class FindOpponentScreen extends StatefulWidget {
  const FindOpponentScreen({super.key});

  @override
  State<FindOpponentScreen> createState() => _FindOpponentScreenState();
}

class _FindOpponentScreenState extends State<FindOpponentScreen> {
  final _gameService = GameService();
  final _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  String _query = '';
  Timer? _refreshTimer;
  Timer? _acceptanceWatcher;
  final _presenceSocket = WebSocketService();
  StreamSubscription<dynamic>? _presenceEvents;
  final _sendingTo = <String>{};
  final _invited = <String>{};
  final _knownGameIds = <String>{};
  String? _waitingForOpponentId;
  bool _openingAcceptedGame = false;

  @override
  void initState() {
    super.initState();
    _future = _gameService.searchUsers('');
    final token = AuthService.instance.token;
    if (token != null) {
      _presenceEvents = _presenceSocket
          .connectPresence(_gameService.baseUrl, token)
          .listen((_) {
        if (mounted) _onSearch(_query);
      }, onError: (_) {});
    }
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _onSearch(_query));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    _acceptanceWatcher?.cancel();
    _presenceEvents?.cancel();
    _presenceSocket.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _query = value.trim();
      _future = _gameService.searchUsers(_query);
    });
  }

  Future<void> _invite(String opponentId, String username) async {
    if (_sendingTo.contains(opponentId) || _invited.contains(opponentId)) {
      return;
    }
    setState(() => _sendingTo.add(opponentId));
    final settings =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            const {};
    try {
      final existingGames = await _gameService.getGames();
      _knownGameIds.addAll(existingGames.map((game) => game.id));
      await _gameService.createInvitation(
          opponentId,
          settings['minutes'] as int? ?? 10,
          settings['color'] as String? ?? 'random');
      if (!mounted) return;
      setState(() {
        _sendingTo.remove(opponentId);
        _invited.add(opponentId);
        _waitingForOpponentId = opponentId;
      });
      _acceptanceWatcher?.cancel();
      _acceptanceWatcher = Timer.periodic(
          const Duration(seconds: 2), (_) => _watchForAcceptedGame());
      _watchForAcceptedGame();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to $username')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingTo.remove(opponentId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _watchForAcceptedGame() async {
    final opponentId = _waitingForOpponentId;
    final currentUserId = AuthService.instance.currentUser?.id;
    if (opponentId == null || currentUserId == null || _openingAcceptedGame) {
      return;
    }
    try {
      final games = await _gameService.getGames();
      Game? acceptedGame;
      for (final game in games) {
        final isMatch =
            (game.whiteId == currentUserId && game.blackId == opponentId) ||
                (game.blackId == currentUserId && game.whiteId == opponentId);
        if (!_knownGameIds.contains(game.id) && isMatch) {
          acceptedGame = game;
          break;
        }
      }
      if (acceptedGame == null || !mounted || _openingAcceptedGame) return;
      _openingAcceptedGame = true;
      _acceptanceWatcher?.cancel();
      await Navigator.pushReplacementNamed(context, '/game',
          arguments: acceptedGame);
    } catch (_) {
      // Keep polling quietly while the invitation is awaiting a response.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Find Opponent')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Choose an opponent',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Search by player name or email to send an invitation.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              SearchBar(
                controller: _searchController,
                hintText: 'Search by username or email',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                side: const WidgetStatePropertyAll(
                    BorderSide(color: Color(0xffd7dfeb))),
                onChanged: _onSearch,
              ),
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final users = (snapshot.data ?? []).where((u) {
                  // Exclude yourself
                  return u['id']?.toString() != currentUserId;
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final id = user['id'].toString();
                    final name = user['username'] ?? user['email'] ?? 'Unknown';
                    final isOnline = user['is_online'] == true;
                    final isSending = _sendingTo.contains(id);
                    final wasInvited = _invited.contains(id);

                    return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          leading: CircleAvatar(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          trailing: OutlinedButton.icon(
                            onPressed: isSending || wasInvited
                                ? null
                                : () => _invite(id, name),
                            icon: isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(
                                    wasInvited
                                        ? Icons.check_circle_outline
                                        : Icons.send_outlined,
                                    size: 17),
                            label: Text(isSending
                                ? 'Sending…'
                                : wasInvited
                                    ? 'Sent'
                                    : 'Invite'),
                          ),
                        ));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
