import 'dart:async';
import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squares/squares.dart' show Squares;
import '../widgets/chess_board.dart';
import '../services/settings_service.dart';

class PlayBotScreen extends StatefulWidget {
  const PlayBotScreen({super.key});
  @override
  State<PlayBotScreen> createState() => _PlayBotScreenState();
}

class _PlayBotScreenState extends State<PlayBotScreen> {
  late bishop.Game game;
  bool _resultShown = false;
  @override
  void initState() {
    super.initState();
    game = bishop.Game();
  }

  void move(String text) {
    final m = game.getMove(text);
    if (m != null && game.makeMove(m)) {
      setState(() {});
      if (SettingsService.instance.moveSounds) {
        SystemSound.play(SystemSoundType.click);
      }
      _showResultIfNeeded();
      Timer(const Duration(milliseconds: 400), () {
        if (!game.gameOver) {
          game.makeRandomMove();
          if (mounted) setState(() {});
          if (SettingsService.instance.moveSounds) {
            SystemSound.play(SystemSoundType.click);
          }
          _showResultIfNeeded();
        }
      });
    }
  }

  void _showResultIfNeeded() {
    if (!game.gameOver || _resultShown || !mounted) return;
    _resultShown = true;
    final won = game.winner == bishop.Bishop.white;
    final draw = game.drawn;
    final title = draw ? 'Draw' : (won ? 'You win!' : 'Bot wins');
    final message = draw
        ? 'The game ended in a draw.'
        : (won ? 'You defeated the bot.' : 'The bot won this game.');
    WidgetsBinding.instance.addPostFrameCallback((_) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
              icon: Icon(draw ? Icons.handshake : Icons.emoji_events,
                  color: draw
                      ? Colors.blueGrey
                      : (won ? Colors.green : Colors.red),
                  size: 48),
              title: Text(title),
              content: Text(message),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (_) => false),
                    child: const Text('Back to lobby'))
              ],
            )));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Play vs Bot')),
      body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            ChessBoard(game: game, player: Squares.white, onMove: move),
            if (game.gameOver)
              Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  color: game.drawn
                      ? Colors.blueGrey
                      : (game.winner == bishop.Bishop.white
                          ? Colors.green
                          : Colors.red),
                  child: Text(
                      game.drawn
                          ? 'Draw'
                          : (game.winner == bishop.Bishop.white
                              ? 'You win!'
                              : 'Bot wins'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
          ])));
}
