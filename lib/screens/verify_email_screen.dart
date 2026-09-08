import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool loading = false;
  Future<void> _check() async {
    setState(() => loading = true);
    try {
      final verified = await AuthService.instance.refreshVerification();
      if (!mounted) return;
      if (verified) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        _message(
            'Your email is not verified yet. Open the link we sent, then try again.');
      }
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await AuthService.instance.sendVerificationEmail();
      if (mounted) {
        _message('Verification email sent.');
      }
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? 'your email';
    return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.mark_email_read, size: 88),
                  const SizedBox(height: 18),
                  const Text('Verify Your Email',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('We sent a verification link to $email.'),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: loading ? null : _check,
                      child:
                          Text(loading ? 'Checking…' : 'I verified my email')),
                  TextButton(
                      onPressed: _resend,
                      child: const Text('Resend verification email')),
                ]))));
  }
}
