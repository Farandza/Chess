import 'package:flutter/material.dart';
import 'chess_timer.dart';

class PlayerInfo extends StatelessWidget {
  const PlayerInfo(
      {super.key,
      required this.name,
      required this.rating,
      required this.seconds,
      this.active = false});
  final String name;
  final int rating, seconds;
  final bool active;
  @override
  Widget build(BuildContext c) => Row(children: [
        const CircleAvatar(child: Icon(Icons.person)),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$rating rating')
        ])),
        ChessTimer(seconds: seconds, active: active)
      ]);
}
