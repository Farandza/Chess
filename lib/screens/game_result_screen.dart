import 'package:flutter/material.dart';

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({super.key, this.won = true});
  final bool won;
  @override
  Widget build(BuildContext c) => Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(won ? Icons.emoji_events : Icons.handshake,
            size: 100, color: Colors.amber),
        Text(won ? 'You Won!' : 'Draw',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(c, '/home', (r) => false),
            child: const Text('Back to Home'))
      ])));
}
