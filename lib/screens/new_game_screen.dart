import 'package:flutter/material.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});
  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  int minutes = 10;
  String color = 'Random';
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('New Game')),
      body: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Set up your match',
                style: Theme.of(c)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Choose the pace and your preferred side.',
                style:
                    TextStyle(color: Theme.of(c).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            Text('Time control',
                style: Theme.of(c)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 15]
                    .map((m) => ChoiceChip(
                        label: Text('$m minutes'),
                        selected: minutes == m,
                        onSelected: (_) => setState(() => minutes = m)))
                    .toList()),
            const SizedBox(height: 28),
            Text('Play as',
                style: Theme.of(c)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Random', 'White', 'Black']
                    .map((v) => ChoiceChip(
                        label: Text(v),
                        selected: color == v,
                        onSelected: (_) => setState(() => color = v)))
                    .toList()),
            const Spacer(),
            Text(
                'Your opponent will receive an invitation with these settings.',
                textAlign: TextAlign.center,
                style: Theme.of(c).textTheme.bodySmall?.copyWith(
                    color: Theme.of(c).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => Navigator.pushNamed(c, '/find', arguments: {
                      'minutes': minutes,
                      'color': color.toLowerCase()
                    }),
                child: const Text('Start Game'))
          ])));
}
