import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Center(
              child: CircleAvatar(
                  radius: 42,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text((user?.username ?? 'P')[0].toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w800)))),
          const SizedBox(height: 12),
          Center(
              child: Text(user?.username ?? 'Player',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold))),
          Center(
              child: Text(user?.email ?? '',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(height: 24),
          Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Player name'),
                    trailing: Text(user?.username ?? 'Player')),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text('Email status'),
                    trailing: Text(
                        user?.emailVerified == true ? 'Verified' : 'Unverified',
                        style: TextStyle(
                            color: user?.emailVerified == true
                                ? Colors.green
                                : Colors.orange))),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rating'),
                    trailing: Text('${user?.rating ?? 1200}')),
              ])),
          const SizedBox(height: 20),
          Text('Preferences',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(context, '/settings'))),
          const SizedBox(height: 12),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (_) => false);
                    }
                  })),
        ]));
  }
}
