import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (name.text.trim().isEmpty || password.text != confirm.text) {
      _message(password.text != confirm.text
          ? 'Passwords do not match.'
          : 'Enter your player name.');
      return;
    }
    final passwordError = _passwordError(password.text);
    if (passwordError != null) {
      _message(passwordError);
      return;
    }
    setState(() => loading = true);
    try {
      await AuthService.instance.register(
          name: name.text, email: email.text, password: password.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/verify-email');
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String? _passwordError(String value) {
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password needs a lowercase letter.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password needs an uppercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(value)) return 'Password needs a digit.';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Password needs a special character.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create your account',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Join the club and start playing online.',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 28),
                    TextField(
                        controller: name,
                        decoration: const InputDecoration(
                            labelText: 'Player name',
                            prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 14),
                    TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 14),
                    TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            helperText:
                                '8+ characters, uppercase, lowercase, digit, special character')),
                    const SizedBox(height: 14),
                    TextField(
                        controller: confirm,
                        obscureText: true,
                        onSubmitted: (_) => _register(),
                        decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_outline))),
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: loading ? null : _register,
                        child:
                            Text(loading ? 'Creating account…' : 'Register')),
                  ]),
            ),
          ),
        ),
      ));
}
