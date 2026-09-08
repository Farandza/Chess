import 'package:flutter/material.dart';
import '../widgets/move_history.dart';

class MoveHistoryScreen extends StatelessWidget {
  const MoveHistoryScreen({super.key, this.moves = const []});
  final List<String> moves;
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Moves')),
      body: MoveHistory(moves: moves));
}
