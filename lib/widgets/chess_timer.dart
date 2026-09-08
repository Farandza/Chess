import 'dart:async';
import 'package:flutter/material.dart';

class ChessTimer extends StatefulWidget {
  const ChessTimer({super.key, required this.seconds, this.active = false});
  final int seconds;
  final bool active;
  @override
  State<ChessTimer> createState() => _ChessTimerState();
}

class _ChessTimerState extends State<ChessTimer> {
  late int value;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    value = widget.seconds;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.active && value > 0) setState(() => value--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Text(
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
}
