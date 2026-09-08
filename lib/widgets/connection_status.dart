import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key, required this.connected});
  final bool connected;
  @override
  Widget build(BuildContext c) => Chip(
      avatar: Icon(Icons.circle,
          size: 10, color: connected ? Colors.green : Colors.red),
      label: Text(connected ? 'Connected' : 'Reconnecting'));
}
