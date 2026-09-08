import 'package:flutter/material.dart';

class MoveHistory extends StatelessWidget {
  const MoveHistory({super.key, required this.moves});
  final List<String> moves;
  @override
  Widget build(BuildContext c) => ListView.builder(
      shrinkWrap: true,
      itemCount: moves.length,
      itemBuilder: (_, i) => ListTile(
          dense: true, leading: Text('${i + 1}.'), title: Text(moves[i])));
}
