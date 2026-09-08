import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/websocket_service.dart';
import '../models/game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  Timer? _gameWatcher;
  Timer? _inviteWatcher;
  final _knownGameIds = <String>{};
  final _gameRevision = ValueNotifier<int>(0);
  final _presenceSocket = WebSocketService();
  StreamSubscription<dynamic>? _presenceEvents;
  String _gameListSignature = '';
  int _pendingInvites = 0;
  @override
  void initState() {
    super.initState();
    _connectPresence();
    _watchForNewGames(initial: true);
    _gameWatcher =
        Timer.periodic(const Duration(seconds: 3), (_) => _watchForNewGames());
    _watchForInvitations();
    _inviteWatcher = Timer.periodic(
        const Duration(seconds: 5), (_) => _watchForInvitations());
  }

  void _connectPresence() {
    final token = AuthService.instance.token;
    if (token == null) return;
    _presenceEvents = _presenceSocket
        .connectPresence(GameService().baseUrl, token)
        .listen((_) {}, onError: (_) {});
  }

  Future<void> _watchForNewGames({bool initial = false}) async {
    try {
      final games = await GameService().getGames();
      if (!mounted) return;
      final signature = games
          .map((game) => '${game.id}:${game.status}:${game.result ?? ''}')
          .join('|');
      if (signature != _gameListSignature) {
        _gameListSignature = signature;
        _gameRevision.value++;
      }
      final newGames =
          games.where((game) => !_knownGameIds.contains(game.id)).toList();
      _knownGameIds.addAll(games.map((game) => game.id));
      if (!initial &&
          newGames.isNotEmpty &&
          mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        await Navigator.pushNamed(context, '/game', arguments: newGames.first);
      }
    } catch (_) {}
  }

  Future<void> _watchForInvitations() async {
    try {
      final invitations = await GameService().getInvitations();
      if (mounted && invitations.length != _pendingInvites) {
        setState(() => _pendingInvites = invitations.length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _gameWatcher?.cancel();
    _inviteWatcher?.cancel();
    _presenceEvents?.cancel();
    _presenceSocket.dispose();
    _gameRevision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess'),
        actions: [
          IconButton(
            tooltip: 'Invitations',
            onPressed: () async {
              await Navigator.pushNamed(context, '/invitations');
              _watchForInvitations();
            },
            icon: Badge(
              isLabelVisible: _pendingInvites > 0,
              label: Text('$_pendingInvites'),
              child: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _HomeBody(revision: _gameRevision),
          _GamesList(revision: _gameRevision),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 2) {
            Navigator.pushNamed(context, '/profile');
            return;
          }
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.sports_esports), label: 'Games'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.revision});
  final ValueListenable<int> revision;
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late Future<List<Game>> _games;

  @override
  void initState() {
    super.initState();
    _games = GameService().getGames();
    widget.revision.addListener(_refreshGames);
  }

  @override
  void dispose() {
    widget.revision.removeListener(_refreshGames);
    super.dispose();
  }

  void _refreshGames() {
    if (!mounted) return;
    setState(() {
      _games = GameService().getGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Ready for your next move?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
        const SizedBox(height: 4),
        Text('Challenge a player, practise with the bot, or resume a match.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        const SizedBox(height: 24),
        Text('Quick actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _tile(context, Icons.search, 'Find Opponent', '/find'),
        _tile(context, Icons.smart_toy, 'Play vs Bot', '/bot'),
        _tile(context, Icons.mail, 'Invitations', '/invitations'),
        const SizedBox(height: 28),
        Text('Active games',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        FutureBuilder<List<Game>>(
          future: _games,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()));
            }
            final games = snapshot.data
                    ?.where((game) =>
                        game.status == 'active' ||
                        game.status == 'restart_pending')
                    .toList() ??
                [];
            if (games.isEmpty) {
              return _tile(context, Icons.add_circle_outline,
                  'Start a new game', '/new-game');
            }
            return Column(
                children: games
                    .map((game) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.grid_4x4_rounded),
                          ),
                          title: Text(
                              '${game.whiteUsername ?? 'White'} vs ${game.blackUsername ?? 'Black'}'),
                          subtitle: Text(game.status == 'active'
                              ? 'Tap to resume'
                              : 'Restart request pending'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 17),
                          onTap: () => Navigator.pushNamed(context, '/game',
                              arguments: game),
                        )))
                    .toList());
          },
        ),
      ],
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String title, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(icon,
              color: Theme.of(context).colorScheme.onSecondaryContainer),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

class _GamesList extends StatefulWidget {
  const _GamesList({required this.revision});
  final ValueListenable<int> revision;
  @override
  State<_GamesList> createState() => _GamesListState();
}

class _GamesListState extends State<_GamesList> {
  late Future<List<Game>> _games;
  @override
  void initState() {
    super.initState();
    _games = GameService().getGames();
    widget.revision.addListener(_refreshGames);
  }

  @override
  void dispose() {
    widget.revision.removeListener(_refreshGames);
    super.dispose();
  }

  void _refreshGames() {
    if (!mounted) return;
    setState(() {
      _games = GameService().getGames();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Game>>(
        future: _games,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Could not load games: ${snapshot.error}'));
          }
          final games = snapshot.data ?? [];
          if (games.isEmpty) return const Center(child: Text('No games yet'));
          return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _games = GameService().getGames();
                });
              },
              child: ListView(
                  children: games
                      .map((game) => ListTile(
                            leading: const Icon(Icons.games),
                            title: Text(
                                '${game.whiteUsername ?? 'White'} vs ${game.blackUsername ?? 'Black'}'),
                            subtitle: Text(game.status),
                            onTap: () => Navigator.pushNamed(context, '/game',
                                arguments: game),
                          ))
                      .toList()));
        },
      );
}
