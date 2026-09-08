import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Gameplay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
            child: AnimatedBuilder(
                animation: SettingsService.instance,
                builder: (context, _) => SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: const Text('Move sounds'),
                    subtitle: Text(SettingsService.instance.moveSounds
                        ? 'Play a sound after each move'
                        : 'Muted'),
                    value: SettingsService.instance.moveSounds,
                    onChanged: (value) async {
                      await SettingsService.instance.setMoveSounds(value);
                      if (value) SystemSound.play(SystemSoundType.click);
                    }))),
        const SizedBox(height: 20),
        const Text('Appearance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Card(
            child: ListTile(
                leading: Icon(Icons.grid_4x4_outlined),
                title: Text('Board theme'),
                subtitle: Text('Brown'))),
        const SizedBox(height: 20),
        const Text('Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Card(
            child: ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('Account security'),
                subtitle: Text(
                    'Use a strong password and keep your account verified'))),
      ]));
}
