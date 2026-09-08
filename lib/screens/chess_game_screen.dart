import 'dart:async';

import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squares/squares.dart' show Squares;

import '../models/game.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/websocket_service.dart';
import '../services/settings_service.dart';
import '../widgets/chess_board.dart';
import '../widgets/move_history.dart';
import '../widgets/player_info.dart';

class ChessGameScreen extends StatefulWidget {
  const ChessGameScreen({super.key, this.gameData});
  final Game? gameData;
  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  final _api = GameService();
  final _socket = WebSocketService();
  Timer? _clock;
  StreamSubscription<dynamic>? _events;
  Game? _state;
  String? _error;
  String? _shownResult;

  @override
  void initState() {
    super.initState();
    _state = widget.gameData;
    _connect();
  }

  Future<void> _connect() async {
    final game = _state;
    final token = AuthService.instance.token;
    if (game == null || token == null) return;
    try {
      _apply(await _api.getGame(game.id));
      _events = _socket.connect(_api.baseUrl, game.id, token).listen((event) {
        if (event is Map && event['type'] == 'game_state') {
          _apply(
              Game.fromJson(Map<String, dynamic>.from(event['game'] as Map)));
        }
      },
          onError: (_) => setState(() =>
              _error = 'Connection lost. Reloading the latest game state…'));
      _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _apply(Game value) {
    if (mounted) {
      setState(() {
        _state = value;
        _error = null;
      });
      if ((value.result == 'white_checkmate' ||
              value.result == 'black_checkmate') &&
          _shownResult != value.result) {
        _shownResult = value.result;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showCheckmate(value.result!));
      }
    }
  }

  void _showCheckmate(String result) {
    if (!mounted) return;
    final winner = result == 'white_checkmate' ? 'White' : 'Black';
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
              icon:
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
              title: const Text('Checkmate!'),
              content: Text('$winner wins by checkmate.'),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (_) => false),
                    child: const Text('Back to lobby'))
              ],
            ));
  }

  void _tick() {
    final value = _state;
    if (value == null || value.status != 'active') return;
    _apply(Game(
        id: value.id,
        whiteId: value.whiteId,
        blackId: value.blackId,
        fen: value.fen,
        whiteUsername: value.whiteUsername,
        blackUsername: value.blackUsername,
        moves: value.moves,
        status: value.status,
        turn: value.turn,
        whiteSeconds: value.whiteSeconds - (value.turn == 'white' ? 1 : 0),
        blackSeconds: value.blackSeconds - (value.turn == 'black' ? 1 : 0),
        result: value.result));
  }

  Future<void> _move(String move) async {
    final value = _state;
    if (value == null) return;
    try {
      _apply(await _api.move(value.id, move));
      if (SettingsService.instance.moveSounds) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _restart() async {
    final value = _state;
    if (value == null) return;
    try {
      _apply(await _api.requestRestart(value.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _quit() async {
    final value = _state;
    if (value == null) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Quit game?'),
                content: const Text('Quitting gives the win to your opponent.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Quit'))
                ]));
    if (confirmed == true) _apply(await _api.quitGame(value.id));
  }

  @override
  void dispose() {
    _clock?.cancel();
    _events?.cancel();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _state;
    if (value == null) {
      return const Scaffold(
          body: Center(child: Text('Open a game from Active Games.')));
    }
    final mineWhite = value.whiteId == AuthService.instance.currentUser?.id;
    final myTurn = (mineWhite && value.turn == 'white') ||
        (!mineWhite && value.turn == 'black');
    final board =
        bishop.Game(variant: bishop.Variant.standard(), fen: value.fen);
    final opponent = mineWhite ? value.blackUsername : value.whiteUsername;
    final mine = mineWhite ? value.whiteUsername : value.blackUsername;
    return Scaffold(
        appBar: AppBar(title: const Text('Live Game')),
        body: SafeArea(
            child: Column(children: [
          if (_error != null)
            MaterialBanner(content: Text(_error!), actions: [
              TextButton(onPressed: _connect, child: const Text('Retry'))
            ]),
          Padding(
              padding: const EdgeInsets.all(12),
              child: PlayerInfo(
                  name: opponent ?? 'Opponent',
                  rating: 1200,
                  seconds: mineWhite ? value.blackSeconds : value.whiteSeconds,
                  active: !myTurn)),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IgnorePointer(
                      ignoring: !myTurn || value.status != 'active',
                      child: ChessBoard(
                          game: board,
                          player: mineWhite ? Squares.white : Squares.black,
                          onMove: _move)))),
          Padding(
              padding: const EdgeInsets.all(12),
              child: PlayerInfo(
                  name: mine ?? 'You',
                  rating: 1200,
                  seconds: mineWhite ? value.whiteSeconds : value.blackSeconds,
                  active: myTurn)),
          if (value.status == 'paused')
            const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                    'Opponent disconnected. Game pauses for up to 2 minutes.',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold))),
          if (value.status == 'restart_pending')
            const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Restart request pending (expires in 30 seconds).',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold))),
          TextButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart game')),
          TextButton.icon(
              onPressed: value.status == 'finished' ? null : _quit,
              icon: const Icon(Icons.flag, color: Colors.red),
              label: const Text('Quit game')),
          if (value.result != null) _resultBanner(value.result!, mineWhite),
          ExpansionTile(
              title: const Text('Move history'),
              children: [MoveHistory(moves: value.moves)]),
        ])));
  }

  Widget _resultBanner(String result, bool mineWhite) {
    String text;
    bool? whiteWon;
    switch (result) {
      case 'black_timeout':
        text = 'Black wins — White ran out of time.';
        whiteWon = false;
        break;
      case 'white_timeout':
        text = 'White wins — Black ran out of time.';
        whiteWon = true;
        break;
      case 'white_checkmate':
        text = 'White wins by checkmate.';
        whiteWon = true;
        break;
      case 'black_checkmate':
        text = 'Black wins by checkmate.';
        whiteWon = false;
        break;
      case 'white_resigned':
        text = 'Black wins — White quit the game.';
        whiteWon = false;
        break;
      case 'black_resigned':
        text = 'White wins — Black quit the game.';
        whiteWon = true;
        break;
      default:
        text = 'Draw.';
        whiteWon = null;
        break;
    }
    final won = whiteWon == null ? null : mineWhite == whiteWon;
    final color =
        won == null ? Colors.blueGrey : (won ? Colors.green : Colors.red);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.shade700, borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
