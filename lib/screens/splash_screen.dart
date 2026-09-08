import 'dart:async';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: 900),
      () {
        if (!mounted) return;
        final user = AuthService.instance.currentUser;
        Navigator.pushReplacementNamed(
            context,
            user == null
                ? '/login'
                : (user.emailVerified ? '/home' : '/verify-email'));
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => const Scaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(Icons.games, size: 96),
            SizedBox(height: 16),
            Text('CHESS',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Play. Compete. Conquer.'),
            SizedBox(height: 32),
            CircularProgressIndicator()
          ])));
}
